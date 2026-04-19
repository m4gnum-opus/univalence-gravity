/**
 * TowerLevel — Single level box in the resolution tower timeline.
 *
 * Renders a compact card for one level of the resolution tower, showing:
 *   - Patch name (as a link to `/patches/:name`)
 *   - Maximum min-cut value (S ≤ N)
 *   - Region count and orbit count
 *   - Verification badges: Bridge (✓), Area Law (✓), Half-Bound (✓)
 *
 * This is a stateless presentational component consumed by
 * {@link TowerTimeline}, which arranges multiple TowerLevel boxes
 * into a horizontal or vertical timeline with monotonicity arrows.
 *
 * The component is clickable — it navigates to the full patch viewer
 * at `/patches/:name` (frontend-spec §5.4: "Click any level → opens
 * that patch in /patches/:name").
 *
 * Visual design:
 *   - Card surface with subtle border and shadow (academic credibility)
 *   - Serif heading for the max-cut value (the primary datum)
 *   - Monospace for numeric statistics (regions, orbits)
 *   - Small colored badges for verification status:
 *       • Green "B" = Bridge verified (BridgeWitness exists)
 *       • Blue "A" = Area law verified (S ≤ area)
 *       • Purple "H" = Half-bound verified (2·S ≤ area, Agda-checked)
 *   - Muted gray for orbits = 0 (flat enumeration, no orbit reduction)
 *
 * Accessibility:
 *   - Wrapped in a `<Link>` for keyboard navigation (Tab + Enter)
 *   - ARIA label describes all key statistics for screen readers
 *   - Badge tooltips provide full descriptions on hover/focus
 *   - Respects `prefers-reduced-motion` for hover transitions
 *
 * @see TowerTimeline — The parent component arranging levels + arrows.
 * @see TowerView — The full `/tower` page.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.4 (Tower Timeline)
 *   - backend/src/Types.hs TowerLevel (field semantics)
 *   - data/tower.json (the 9 tower levels)
 */

import { Link } from "react-router-dom";

import type { TowerLevel as TowerLevelType } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link TowerLevel} component. */
export interface TowerLevelProps {
  /** The tower level data from `GET /tower`. */
  level: TowerLevelType;

  /**
   * Whether this level is visually highlighted (e.g. on hover
   * over the corresponding monotonicity arrow in the timeline).
   * Defaults to `false`.
   */
  highlighted?: boolean;

  /**
   * Visual size variant. The timeline may render Dense tower
   * levels larger than layer tower levels for visual hierarchy.
   *
   * - `"default"` — Standard card size
   * - `"compact"` — Smaller card for the {5,4} layer tower
   *   (which has 6 levels with constant maxCut=2, less interesting
   *   individually)
   */
  variant?: "default" | "compact";
}

// ════════════════════════════════════════════════════════════════
//  Display Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Format the orbit display string.
 *
 * - `0` (flat enumeration) → "—" (em dash, indicating no orbit reduction)
 * - Positive value → the orbit count as a string
 */
function formatOrbits(orbits: number): string {
  return orbits > 0 ? String(orbits) : "—";
}

/**
 * Format a region count with locale-appropriate thousand separators.
 *
 * @example
 * formatRegions(1246) // → "1,246"
 * formatRegions(15)   // → "15"
 */
function formatRegions(regions: number): string {
  return regions.toLocaleString();
}

// ════════════════════════════════════════════════════════════════
//  Badge Sub-Component
// ════════════════════════════════════════════════════════════════

/**
 * A small verification status badge.
 *
 * Renders a single-character badge with a colored background
 * indicating whether a particular verification property holds
 * for this tower level.
 *
 * When `active` is `false`, the badge is rendered in a muted
 * gray to indicate the property has not been verified (rather
 * than hiding the badge entirely — this preserves layout
 * consistency across tower levels).
 */
function VerificationBadge({
  label,
  shortLabel,
  active,
  activeClasses,
}: {
  /** Full descriptive label for tooltip and screen readers. */
  label: string;
  /** Single character displayed in the badge circle. */
  shortLabel: string;
  /** Whether this verification property holds. */
  active: boolean;
  /** Tailwind classes for the active (verified) state. */
  activeClasses: string;
}) {
  return (
    <span
      className={[
        "inline-flex h-5 w-5 items-center justify-center",
        "rounded-full text-[10px] font-bold leading-none",
        active ? activeClasses : "bg-gray-100 text-gray-400",
      ].join(" ")}
      title={active ? `${label}: Verified` : `${label}: Not verified`}
      aria-label={active ? `${label} verified` : `${label} not verified`}
    >
      {shortLabel}
    </span>
  );
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * A single tower level rendered as a compact card.
 *
 * Clicking the card navigates to the full patch viewer for this
 * level's patch. The card displays the max min-cut value as the
 * primary visual element, with region/orbit counts and verification
 * badges as supporting details.
 *
 * Layout (default variant):
 * ```
 * ┌─────────────────────┐
 * │  dense-100           │  ← patch name
 * │                      │
 * │       S ≤ 8          │  ← max min-cut (primary datum)
 * │                      │
 * │  717 r    8 o        │  ← regions + orbits
 * │  [B] [A] [H]         │  ← verification badges
 * └─────────────────────┘
 * ```
 *
 * Layout (compact variant — for {5,4} layer levels):
 * ```
 * ┌──────────┐
 * │ d3  S≤2  │
 * │ 40r  2o  │
 * │ [B]      │
 * └──────────┘
 * ```
 *
 * @example
 * ```tsx
 * <TowerLevel
 *   level={towerLevels[1]}
 *   variant="default"
 * />
 * ```
 */
export function TowerLevel({
  level,
  highlighted = false,
  variant = "default",
}: TowerLevelProps) {
  const {
    tlPatchName,
    tlRegions,
    tlOrbits,
    tlMaxCut,
    tlHasBridge,
    tlHasAreaLaw,
    tlHasHalfBound,
  } = level;

  // Build a descriptive ARIA label for screen readers.
  const ariaLabel = [
    `Tower level: ${tlPatchName}.`,
    `Max min-cut S = ${tlMaxCut}.`,
    `${tlRegions} regions.`,
    tlOrbits > 0 ? `${tlOrbits} orbits.` : "Flat enumeration.",
    tlHasBridge ? "Bridge verified." : "",
    tlHasAreaLaw ? "Area law verified." : "",
    tlHasHalfBound ? "Half-bound verified." : "",
    "Click to view patch details.",
  ]
    .filter(Boolean)
    .join(" ");

  // Determine card sizing based on variant.
  const isCompact = variant === "compact";

  return (
    <Link
      to={`/patches/${tlPatchName}`}
      className={[
        // Base card styles
        "block rounded-lg border bg-white shadow-sm",
        "transition-all duration-150",
        "motion-reduce:transition-none",
        // Focus ring for keyboard navigation
        "focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2",
        // Hover effect
        "hover:shadow-md hover:border-viridis-300",
        // Highlighted state (from timeline arrow hover)
        highlighted
          ? "border-viridis-400 ring-1 ring-viridis-400 shadow-md"
          : "border-gray-200",
        // Sizing by variant
        isCompact ? "px-3 py-2 min-w-[5.5rem]" : "px-4 py-3 min-w-[9rem]",
      ].join(" ")}
      aria-label={ariaLabel}
    >
      {isCompact ? (
        /* ── Compact Layout (layer levels) ─────────────────── */
        <div className="text-center">
          {/* Abbreviated patch name */}
          <p className="text-[10px] font-medium text-gray-500 truncate mb-0.5">
            {abbreviatePatchName(tlPatchName)}
          </p>

          {/* Max min-cut — the primary datum */}
          <p className="font-serif text-sm font-bold text-gray-900">
            S≤{tlMaxCut}
          </p>

          {/* Stats row */}
          <p className="mt-0.5 font-mono text-[10px] text-gray-500">
            {formatRegions(tlRegions)}r
            <span className="mx-0.5 text-gray-300">·</span>
            {formatOrbits(tlOrbits)}o
          </p>

          {/* Badges row */}
          <div className="mt-1 flex items-center justify-center gap-0.5">
            <VerificationBadge
              label="Bridge"
              shortLabel="B"
              active={tlHasBridge}
              activeClasses="bg-green-100 text-green-700"
            />
            {(tlHasAreaLaw || tlHasHalfBound) && (
              <>
                <VerificationBadge
                  label="Area Law"
                  shortLabel="A"
                  active={tlHasAreaLaw}
                  activeClasses="bg-blue-100 text-blue-700"
                />
                <VerificationBadge
                  label="Half-Bound"
                  shortLabel="H"
                  active={tlHasHalfBound}
                  activeClasses="bg-purple-100 text-purple-700"
                />
              </>
            )}
          </div>
        </div>
      ) : (
        /* ── Default Layout (Dense levels) ─────────────────── */
        <div className="text-center">
          {/* Patch name */}
          <p className="text-xs font-medium text-gray-500 truncate mb-1">
            {tlPatchName}
          </p>

          {/* Max min-cut — the primary datum, large and centered */}
          <p className="font-serif text-xl font-bold text-gray-900 leading-tight">
            S ≤ {tlMaxCut}
          </p>

          {/* Region and orbit counts */}
          <div className="mt-2 flex items-center justify-center gap-3 text-xs text-gray-600">
            <span className="font-mono" title={`${tlRegions} boundary regions`}>
              {formatRegions(tlRegions)}
              <span className="ml-0.5 text-gray-400">r</span>
            </span>
            <span className="font-mono" title={
              tlOrbits > 0
                ? `${tlOrbits} orbit representatives`
                : "Flat enumeration (no orbit reduction)"
            }>
              {formatOrbits(tlOrbits)}
              <span className="ml-0.5 text-gray-400">o</span>
            </span>
          </div>

          {/* Verification badges */}
          <div
            className="mt-2 flex items-center justify-center gap-1"
            aria-label="Verification status"
          >
            <VerificationBadge
              label="Bridge"
              shortLabel="B"
              active={tlHasBridge}
              activeClasses="bg-green-100 text-green-700"
            />
            <VerificationBadge
              label="Area Law"
              shortLabel="A"
              active={tlHasAreaLaw}
              activeClasses="bg-blue-100 text-blue-700"
            />
            <VerificationBadge
              label="Half-Bound"
              shortLabel="H"
              active={tlHasHalfBound}
              activeClasses="bg-purple-100 text-purple-700"
            />
          </div>
        </div>
      )}
    </Link>
  );
}

// ════════════════════════════════════════════════════════════════
//  Internal Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Abbreviate a patch name for the compact layout variant.
 *
 * Strips common prefixes to save horizontal space in the compact
 * {5,4} layer tower where 6 levels are shown side by side.
 *
 * @example
 * abbreviatePatchName("layer-54-d3") // → "d3"
 * abbreviatePatchName("dense-100")   // → "dense-100" (unchanged)
 * abbreviatePatchName("dense-50")    // → "dense-50" (unchanged)
 */
function abbreviatePatchName(name: string): string {
  // Strip the "layer-54-" prefix for layer tower levels.
  if (name.startsWith("layer-54-")) {
    return name.replace("layer-54-", "");
  }
  return name;
}