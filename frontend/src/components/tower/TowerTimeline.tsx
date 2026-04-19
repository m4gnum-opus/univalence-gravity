/**
 * TowerTimeline — Horizontal/vertical timeline with monotonicity arrows.
 *
 * Arranges {@link TowerLevel} cards into sub-tower groups with connecting
 * monotonicity arrows. The tower data from `GET /tower` contains two
 * sub-towers:
 *
 *   1. **Dense Resolution Tower** (3 levels: Dense-50, Dense-100, Dense-200)
 *      — monotone growth of max min-cut: 7 → 8 → 9
 *
 *   2. **{5,4} Layer Tower** (6 levels: depths 2–7)
 *      — exponential tile growth with constant maxCut = 2
 *
 * Sub-towers are identified by `tlMonotone === null` boundaries in the
 * tower data: each null-monotone level starts a new sub-tower (it has
 * no predecessor within its group).
 *
 * Features:
 *   - Monotonicity arrows between consecutive levels showing `(k, refl)` witnesses
 *   - Hover on arrows highlights the two adjacent levels
 *   - Responsive: horizontal timeline on md+ screens, vertical on mobile
 *   - Legend explaining the verification badges (B = Bridge, A = Area Law, H = Half-Bound)
 *   - Click any level card → navigates to `/patches/:name` (handled by TowerLevel)
 *
 * Accessibility:
 *   - Arrows are focusable with descriptive ARIA labels
 *   - Focus on an arrow highlights the adjacent levels (same as hover)
 *   - The timeline uses semantic section elements with aria-labels
 *   - Respects `prefers-reduced-motion` via Tailwind's motion-reduce variant
 *
 * @see TowerLevel — The individual level card component.
 * @see TowerView — The parent `/tower` page consuming this component.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.4 (Tower Timeline)
 *   - data/tower.json (the 9 tower levels)
 */

import { useMemo, useState, useCallback, Fragment } from "react";

import type { TowerLevel as TowerLevelType } from "../../types";
import { TowerLevel } from "./TowerLevel";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link TowerTimeline} component. */
export interface TowerTimelineProps {
  /** All tower levels from `GET /tower`, in order. */
  levels: TowerLevelType[];
}

// ════════════════════════════════════════════════════════════════
//  Sub-Tower Data Structure
// ════════════════════════════════════════════════════════════════

/**
 * A group of consecutive tower levels forming a sub-tower.
 *
 * Each sub-tower has a descriptive title, contains one or more
 * levels, and specifies the visual variant for its level cards.
 */
interface SubTowerData {
  /** Unique identifier for React keying. */
  id: string;
  /** Display title for the sub-tower section heading. */
  title: string;
  /** One-line description shown below the title. */
  description: string;
  /** The levels in this sub-tower, in order. */
  levels: TowerLevelType[];
  /**
   * Visual variant for TowerLevel cards.
   *   - `"default"` — Standard card size (Dense tower, 3 levels)
   *   - `"compact"` — Smaller card for the {5,4} layer tower (6 levels)
   */
  variant: "default" | "compact";
}

// ════════════════════════════════════════════════════════════════
//  Sub-Tower Splitting Logic
// ════════════════════════════════════════════════════════════════

/**
 * Split a flat array of tower levels into distinct sub-towers.
 *
 * Sub-tower boundaries are identified by `tlMonotone === null`:
 * each level with a null monotonicity witness starts a new
 * sub-tower (it has no predecessor within its group, i.e. it is
 * the baseline level of that resolution sequence).
 *
 * In the current data this produces:
 *   - Dense sub-tower: [dense-50 (null), dense-100, dense-200]
 *   - Layer sub-tower: [layer-54-d2 (null), d3, d4, d5, d6, d7]
 *
 * @param levels - All tower levels from the API.
 * @returns Array of classified sub-tower groups.
 */
function splitIntoSubTowers(levels: TowerLevelType[]): SubTowerData[] {
  if (levels.length === 0) return [];

  const subTowers: SubTowerData[] = [];
  let currentGroup: TowerLevelType[] = [];

  for (const level of levels) {
    if (level.tlMonotone === null && currentGroup.length > 0) {
      // The previous group is complete — classify and push it.
      subTowers.push(classifySubTower(currentGroup));
      currentGroup = [level];
    } else {
      currentGroup.push(level);
    }
  }

  // Don't forget the last group.
  if (currentGroup.length > 0) {
    subTowers.push(classifySubTower(currentGroup));
  }

  return subTowers;
}

/**
 * Classify a group of levels as a named sub-tower with a display
 * variant and description.
 *
 * Uses the first level's patch name prefix to determine the tower type:
 *   - `"dense-*"` → Dense Resolution Tower (`"default"` variant)
 *   - `"layer-54-*"` → {5,4} Layer Tower (`"compact"` variant)
 *   - Other → Generic fallback (`"default"` variant)
 * 
 * NOTE: honeycomb-145 groups into the Dense tower because it has a
 * non-null tlMonotone witness (relative to dense-200) and the first
 * level of this sub-tower starts with "dense-". Visually this is
 * technically correct (honeycomb-145 participates in the monotone
 * Dense resolution sequence), though users may find it surprising.
 * To separate it, add a `null` tlMonotone sentinel before
 * honeycomb-145 in tower.json. This is a data-design decision,
 * not a frontend bug.
 *
 * @param levels - The consecutive levels forming this sub-tower.
 * @returns Classified sub-tower with metadata for rendering.
 */
function classifySubTower(levels: TowerLevelType[]): SubTowerData {
  const first = levels[0];
  const last = levels[levels.length - 1];
  const firstName = first?.tlPatchName ?? "";

  if (firstName.startsWith("dense-")) {
    const firstMaxCut = first?.tlMaxCut ?? 0;
    const lastMaxCut = last?.tlMaxCut ?? 0;
    return {
      id: "dense",
      title: "Dense Resolution Tower",
      description:
        firstMaxCut === lastMaxCut
          ? `Monotone convergence — all maxCut = ${firstMaxCut}`
          : `Monotone convergence certificate — max S grows ${firstMaxCut} → ${lastMaxCut}`,
      levels,
      variant: "default",
    };
  }

  if (firstName.startsWith("layer-54-")) {
    const maxCut = first?.tlMaxCut ?? 0;
    const firstDepth = extractDepth(firstName);
    const lastDepth = extractDepth(last?.tlPatchName ?? "");
    return {
      id: "layer-54",
      title: "{5,4} Layer Tower",
      description:
        `BFS depths ${firstDepth}–${lastDepth} — exponential tile growth, ` +
        `constant maxCut = ${maxCut}`,
      levels,
      variant: "compact",
    };
  }

  // Generic fallback for unknown tower types
  return {
    id: `tower-${firstName}`,
    title: "Resolution Tower",
    description: "",
    levels,
    variant: "default",
  };
}

/**
 * Extract the BFS depth number from a layer patch name.
 *
 * @example
 * extractDepth("layer-54-d3") // → "3"
 * extractDepth("layer-54-d7") // → "7"
 * extractDepth("unknown")     // → "?"
 */
function extractDepth(name: string): string {
  const match = name.match(/layer-54-d(\d+)/);
  return match?.[1] ?? "?";
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * Horizontal (desktop) / vertical (mobile) timeline showing
 * the resolution tower's monotone convergence structure.
 *
 * Renders sub-tower sections with level cards connected by
 * monotonicity arrows. Each arrow shows the `(k, refl)` witness
 * and highlights its adjacent levels on hover/focus.
 *
 * @example
 * ```tsx
 * const { data } = useTower();
 * if (data) return <TowerTimeline levels={data} />;
 * ```
 */
export function TowerTimeline({ levels }: TowerTimelineProps) {
  const subTowers = useMemo(() => splitIntoSubTowers(levels), [levels]);

  if (levels.length === 0) {
    return (
      <p className="text-sm text-gray-400 italic text-center py-8">
        No tower data available.
      </p>
    );
  }

  return (
    <div className="space-y-10">
      {subTowers.map((subTower) => (
        <SubTowerSection key={subTower.id} subTower={subTower} />
      ))}

      {/* Legend */}
      <TimelineLegend />
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Sub-Tower Section
// ════════════════════════════════════════════════════════════════

/**
 * A single sub-tower rendered as a titled section with a horizontal
 * (desktop) or vertical (mobile) timeline of level cards and arrows.
 *
 * Manages a `hoveredArrow` state for the highlight interaction:
 * when a monotonicity arrow is hovered or focused, the two adjacent
 * tower-level cards receive a `highlighted` prop that triggers their
 * visual emphasis (border glow + shadow lift).
 */
function SubTowerSection({ subTower }: { subTower: SubTowerData }) {
  const [hoveredArrow, setHoveredArrow] = useState<number | null>(null);

  const handleArrowHover = useCallback((index: number | null) => {
    setHoveredArrow(index);
  }, []);

  return (
    <section aria-label={subTower.title}>
      {/* Sub-tower header */}
      <h3 className="font-serif text-lg font-semibold text-gray-800 mb-1">
        {subTower.title}
      </h3>
      {subTower.description && (
        <p className="text-sm text-gray-500 mb-4">
          {subTower.description}
        </p>
      )}

      {/* Timeline: levels interleaved with arrows.
       *
       * On mobile (<md): vertical stack with downward arrows.
       * On desktop (md+): horizontal row with rightward arrows.
       *
       * overflow-x-auto on the md+ horizontal layout prevents
       * clipping if the timeline is wider than the container
       * (defensive — the current data fits on all md+ screens).
       */}
      <div className="md:overflow-x-auto">
        <div
          className={[
            "flex flex-col items-center gap-1",
            "md:flex-row md:items-center md:gap-0",
          ].join(" ")}
          role="list"
          aria-label={`${subTower.title} levels`}
        >
          {subTower.levels.map((level, i) => {
            // ── Highlight logic ─────────────────────────────────
            //
            // Arrow at position `j` connects level[j] and level[j+1].
            // A level at index `i` should be highlighted when:
            //   - the arrow to its RIGHT (index i) is hovered, OR
            //   - the arrow to its LEFT (index i-1) is hovered.
            const isHighlighted =
              hoveredArrow === i || hoveredArrow === i - 1;

            // Determine if there's an arrow after this level.
            const isLast = i === subTower.levels.length - 1;
            const nextLevel = isLast ? undefined : subTower.levels[i + 1];
            const nextMonotone = nextLevel?.tlMonotone ?? null;

            return (
              <Fragment key={level.tlPatchName}>
                {/* Level card */}
                <div role="listitem">
                  <TowerLevel
                    level={level}
                    variant={subTower.variant}
                    highlighted={isHighlighted}
                  />
                </div>

                {/* Monotonicity arrow to next level.
                 *  Rendered only when:
                 *    - This is not the last level
                 *    - The next level has a monotonicity witness
                 */}
                {!isLast && nextMonotone !== null && (
                  <MonotonicityArrow
                    witness={nextMonotone}
                    arrowIndex={i}
                    onHover={handleArrowHover}
                  />
                )}

                {/* Spacer when there's no monotone witness but more
                 *  levels follow (shouldn't happen within a sub-tower,
                 *  but defensive). */}
                {!isLast && nextMonotone === null && (
                  <div
                    className="w-2 h-2 md:w-4 md:h-0 shrink-0"
                    aria-hidden="true"
                  />
                )}
              </Fragment>
            );
          })}
        </div>
      </div>
    </section>
  );
}

// ════════════════════════════════════════════════════════════════
//  Monotonicity Arrow
// ════════════════════════════════════════════════════════════════

/** Props for the internal {@link MonotonicityArrow} component. */
interface MonotonicityArrowProps {
  /** The monotonicity witness tuple `[k, "refl"]`. */
  witness: [number, string];
  /**
   * Index of this arrow in the sub-tower's level sequence.
   * An arrow at index `j` connects level[j] and level[j+1].
   */
  arrowIndex: number;
  /**
   * Callback to signal hover state changes.
   * Pass `arrowIndex` on enter/focus, `null` on leave/blur.
   */
  onHover: (index: number | null) => void;
}

/**
 * A connecting arrow between two consecutive tower levels,
 * displaying the monotonicity witness `(k, refl)`.
 *
 * Renders differently based on screen size:
 *   - Desktop (md+): horizontal dashed line with `▶` arrowhead,
 *     witness text above the line.
 *   - Mobile (<md): vertical dashed line with `▼` arrowhead,
 *     witness text to the right.
 *
 * On hover/focus, signals the parent `SubTowerSection` to
 * highlight the adjacent level cards via `onHover`.
 *
 * The arrow is keyboard-focusable (`tabIndex={0}`) with a
 * visible focus ring, satisfying the accessibility requirement
 * (frontend-spec §10: keyboard navigation).
 */
function MonotonicityArrow({
  witness,
  arrowIndex,
  onHover,
}: MonotonicityArrowProps) {
  const [k, proof] = witness;
  const label = `(${k}, ${proof})`;

  const handleMouseEnter = useCallback(() => {
    onHover(arrowIndex);
  }, [onHover, arrowIndex]);

  const handleMouseLeave = useCallback(() => {
    onHover(null);
  }, [onHover]);

  const handleFocus = useCallback(() => {
    onHover(arrowIndex);
  }, [onHover, arrowIndex]);

  const handleBlur = useCallback(() => {
    onHover(null);
  }, [onHover]);

  return (
    <div
      className={[
        "flex shrink-0 items-center justify-center",
        "rounded-md",
        "focus:outline-none focus-visible:ring-2",
        "focus-visible:ring-viridis-600 focus-visible:ring-offset-2",
      ].join(" ")}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      onFocus={handleFocus}
      onBlur={handleBlur}
      title={`Monotonicity witness: ${label} — maxCut grows by ${k}`}
      role="separator"
      aria-label={`Monotonicity: +${k} by ${proof}`}
      tabIndex={0}
    >
      {/* ── Desktop: horizontal arrow (md+) ────────────────── */}
      <div className="hidden md:flex flex-col items-center gap-0.5 px-1.5 lg:px-3">
        <span className="font-mono text-[10px] leading-tight text-gray-500 whitespace-nowrap">
          {label}
        </span>
        <div className="flex items-center">
          <div className="w-6 lg:w-10 border-t border-dashed border-gray-400" />
          <span
            className="text-gray-400 text-xs -ml-0.5"
            aria-hidden="true"
          >
            ▶
          </span>
        </div>
      </div>

      {/* ── Mobile: vertical arrow (<md) ───────────────────── */}
      <div className="flex md:hidden items-center gap-1.5 py-1">
        <div className="flex flex-col items-center">
          <div className="h-3 border-l border-dashed border-gray-400" />
          <span
            className="text-gray-400 text-xs -mt-0.5"
            aria-hidden="true"
          >
            ▼
          </span>
        </div>
        <span className="font-mono text-[10px] text-gray-500 whitespace-nowrap">
          {label}
        </span>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Legend
// ════════════════════════════════════════════════════════════════

/**
 * Compact legend explaining the tower timeline visual conventions.
 *
 * Describes:
 *   - `r` = regions, `o` = orbits, `—` = flat enumeration
 *   - Badge meanings: B = Bridge, A = Area Law, H = Half-Bound
 *   - Arrow semantics: `(k, refl)` is a monotonicity witness
 *   - Interaction hint: click a level to view the patch
 */
function TimelineLegend() {
  return (
    <div
      className="rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-xs text-gray-500"
      role="note"
      aria-label="Tower timeline legend"
    >
      <p className="font-medium text-gray-600 mb-1.5">Legend</p>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-x-6 gap-y-1.5">
        {/* Statistics abbreviations */}
        <div>
          <span className="font-mono text-gray-600">r</span> = regions
          <span className="mx-1.5 text-gray-300">·</span>
          <span className="font-mono text-gray-600">o</span> = orbits
          <span className="mx-1.5 text-gray-300">·</span>
          <span className="font-mono text-gray-600">—</span> = flat
          enumeration
        </div>

        {/* Verification badges */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <span className="inline-flex items-center gap-1">
            <span className="inline-flex h-4 w-4 items-center justify-center rounded-full bg-green-100 text-[9px] font-bold text-green-700">
              B
            </span>
            <span>Bridge</span>
          </span>
          <span className="inline-flex items-center gap-1">
            <span className="inline-flex h-4 w-4 items-center justify-center rounded-full bg-blue-100 text-[9px] font-bold text-blue-700">
              A
            </span>
            <span>Area Law</span>
          </span>
          <span className="inline-flex items-center gap-1">
            <span className="inline-flex h-4 w-4 items-center justify-center rounded-full bg-purple-100 text-[9px] font-bold text-purple-700">
              H
            </span>
            <span>Half-Bound</span>
          </span>
        </div>

        {/* Arrow semantics */}
        <div>
          <span className="font-mono text-gray-600">(k, refl)</span>{" "}
          = monotonicity witness: maxCut grows by k
        </div>

        {/* Interaction hint */}
        <div>Click any level → view patch in 3D</div>
      </div>
    </div>
  );
}