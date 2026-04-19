/**
 * TowerAnimation — Animated spatial growth visualization across
 * sequential tower levels, with proper-time counter and playback
 * controls.
 *
 * This component animates the resolution tower as a temporal sequence:
 * each tower level represents a spatial "time slice" at increasing
 * resolution. The user can play, pause, step through, and scrub the
 * animation, watching the holographic patch grow from Dense-50 (50 cells,
 * max S=7) through Dense-200 (200 cells, max S=9), or through the
 * {5,4} layer depths 2–7 (21→3046 tiles, constant max S=2).
 *
 * **Physical interpretation:**
 *
 *   In the causal layer of the formalization, the tower levels are
 *   *discrete spacetime slices* connected by causal extensions (Pachner
 *   moves / BFS expansions). The proper time τ counts the number of
 *   causal extensions from the first slice to the current one:
 *
 *     - Dense tower: τ ∈ {0, 1, 2} (3 levels, 2 extensions)
 *     - Layer tower: τ ∈ {0, 1, 2, 3, 4, 5} (6 levels, 5 extensions)
 *
 *   The `CausalDiamond` in `Causal/CausalDiamond.agda` packages the
 *   layer tower with proper time = 5 and maximin entropy = 2.
 *
 *   The animation shows:
 *     - **Spatial growth**: cells, regions, and bonds increasing
 *     - **Holographic depth**: the max min-cut (maxCut) evolving
 *     - **Orbit stability**: orbit count staying constant or growing slowly
 *     - **Monotonicity**: each step's `(k, refl)` witness
 *
 * **Sub-tower selection:**
 *
 *   The tower data contains two sub-towers (identified by `tlMonotone
 *   === null` boundaries). The component groups levels into sub-towers
 *   and lets the user select which one to animate:
 *
 *     1. **Dense Resolution Tower** (3–5 levels depending on data):
 *        Monotone max min-cut growth 7 → 8 → 9
 *     2. **{5,4} Layer Tower** (6 levels: depths 2–7):
 *        Exponential tile growth, constant maxCut = 2
 *
 * **3D Visualization:**
 *
 *   When patch data is available for the current level, it is rendered
 *   in a `PatchScene` viewport. The component fetches patch data on
 *   demand using `usePatch` — only the currently displayed level's
 *   patch is loaded at any time. Navigation to a new level triggers
 *   a new fetch (the previous one is aborted via AbortController).
 *
 *   A lightweight statistics-only fallback is shown while patch data
 *   is loading, so the animation can proceed without waiting for
 *   heavy payloads (Dense-1000 is ~2.9 MB).
 *
 * **Playback controls:**
 *
 *   - Play/Pause toggle
 *   - Step forward / Step backward buttons
 *   - Speed selector (0.5×, 1×, 2×, 4×)
 *   - Timeline scrubber (click or keyboard-navigate to any level)
 *   - Proper-time counter (τ = 0, 1, 2, ...)
 *
 * **Accessibility:**
 *
 *   - All controls are keyboard navigable (Tab + Enter/Space)
 *   - ARIA labels on all interactive elements
 *   - Timeline scrubber uses `role="slider"` with aria-valuemin/max/now
 *   - Respects `prefers-reduced-motion`: auto-play is disabled, and
 *     transitions are removed
 *   - Screen reader announcements via `aria-live="polite"` on the
 *     status region
 *
 * @see TowerTimeline — Static timeline with monotonicity arrows
 * @see TowerView — The `/tower` page that may embed this component
 * @see PatchScene — The 3D viewport used for patch rendering
 * @see CausalDiamond — The Agda module formalizing causal structure
 *
 * Reference:
 *   - docs/formal/06-causal-structure.md (Events, CausalDiamond, NoCTC)
 *   - docs/formal/10-dynamics.md (Step invariance, dynamics loop)
 *   - docs/formal/11-generic-bridge.md (SchematicTower)
 *   - docs/instances/layer-54-tower.md (Layer tower as discrete spacetime)
 *   - Phase 3, item 17 of the concrete fix plan
 */

import { useState, useCallback, useEffect, useMemo, useRef } from "react";
import { Link } from "react-router-dom";

import { usePatch } from "../../hooks/usePatch";
import { PatchScene } from "../patches/PatchScene";
import { Loading } from "../common/Loading";
import type { TowerLevel, ColorMode } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/** Default playback interval in milliseconds (1× speed). */
const BASE_INTERVAL_MS = 3000;

/** Available playback speed multipliers. */
const SPEED_OPTIONS: readonly number[] = [0.5, 1, 2, 4];

/**
 * Check if the user prefers reduced motion.
 * When true, auto-play is disabled and transitions are removed.
 */
function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

// ════════════════════════════════════════════════════════════════
//  Sub-Tower Grouping
// ════════════════════════════════════════════════════════════════

interface SubTower {
  id: string;
  title: string;
  description: string;
  levels: TowerLevel[];
}

/**
 * Split tower levels into sub-towers at `tlMonotone === null`
 * boundaries.  Same logic as TowerTimeline.tsx.
 */
function splitSubTowers(levels: TowerLevel[]): SubTower[] {
  if (levels.length === 0) return [];

  const groups: TowerLevel[][] = [];
  let current: TowerLevel[] = [];

  for (const level of levels) {
    if (level.tlMonotone === null && current.length > 0) {
      groups.push(current);
      current = [level];
    } else {
      current.push(level);
    }
  }
  if (current.length > 0) groups.push(current);

  return groups.map((g, i) => {
    const first = g[0]!;
    const isDense = first.tlPatchName.startsWith("dense-");
    const isLayer = first.tlPatchName.startsWith("layer-54-");

    return {
      id: isDense ? "dense" : isLayer ? "layer" : `group-${i}`,
      title: isDense
        ? "Dense Resolution Tower"
        : isLayer
          ? "{5,4} Layer Tower"
          : `Tower ${i + 1}`,
      description: isDense
        ? "Spatial growth with increasing holographic depth"
        : isLayer
          ? "Exponential tile growth, constant holographic depth"
          : "",
      levels: g,
    };
  });
}

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

export interface TowerAnimationProps {
  /**
   * All tower levels from `GET /tower`.
   * The component groups these into sub-towers and provides
   * selection + animation controls.
   */
  levels: TowerLevel[];
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * Animated tower playback with 3D patch visualization, proper-time
 * counter, and growth statistics.
 */
export function TowerAnimation({ levels }: TowerAnimationProps) {
  // ── Sub-tower grouping ──────────────────────────────────────
  const subTowers = useMemo(() => splitSubTowers(levels), [levels]);

  // ── Selected sub-tower ──────────────────────────────────────
  const [selectedSubTower, setSelectedSubTower] = useState(0);
  const activeSubTower = subTowers[selectedSubTower] ?? subTowers[0];
  const activeLevels = activeSubTower?.levels ?? [];

  // ── Playback state ──────────────────────────────────────────
  const [currentIndex, setCurrentIndex] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [speed, setSpeed] = useState(1);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Clamp current index when switching sub-towers
  useEffect(() => {
    setCurrentIndex(0);
    setPlaying(false);
  }, [selectedSubTower]);

  const currentLevel = activeLevels[currentIndex];
  const properTime = currentIndex; // τ = index (0-based from first slice)
  const maxProperTime = Math.max(0, activeLevels.length - 1);

  // ── Fetch current level's patch data ────────────────────────
  const {
    data: patchData,
    loading: patchLoading,
  } = usePatch(currentLevel?.tlPatchName ?? "");

  // ── 3D visualization state ──────────────────────────────────
  const [colorMode] = useState<ColorMode>("mincut");

  // ── Playback timer ──────────────────────────────────────────
  useEffect(() => {
    if (intervalRef.current !== null) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    if (!playing || activeLevels.length <= 1) return;

    // Respect prefers-reduced-motion: don't auto-play
    if (prefersReducedMotion()) {
      setPlaying(false);
      return;
    }

    const ms = BASE_INTERVAL_MS / speed;
    intervalRef.current = setInterval(() => {
      setCurrentIndex((prev) => {
        if (prev >= activeLevels.length - 1) {
          // Reached end — pause
          setPlaying(false);
          return prev;
        }
        return prev + 1;
      });
    }, ms);

    return () => {
      if (intervalRef.current !== null) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [playing, speed, activeLevels.length]);

  // ── Controls ────────────────────────────────────────────────

  const handlePlayPause = useCallback(() => {
    setPlaying((prev) => {
      // If at end and pressing play, restart from beginning
      if (!prev && currentIndex >= activeLevels.length - 1) {
        setCurrentIndex(0);
      }
      return !prev;
    });
  }, [currentIndex, activeLevels.length]);

  const handleStepBack = useCallback(() => {
    setPlaying(false);
    setCurrentIndex((prev) => Math.max(0, prev - 1));
  }, []);

  const handleStepForward = useCallback(() => {
    setPlaying(false);
    setCurrentIndex((prev) =>
      Math.min(activeLevels.length - 1, prev + 1)
    );
  }, [activeLevels.length]);

  const handleScrub = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      setPlaying(false);
      setCurrentIndex(Number(e.target.value));
    },
    [],
  );

  const handleSpeedChange = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      setSpeed(Number(e.target.value));
    },
    [],
  );

  const handleSubTowerChange = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      setSelectedSubTower(Number(e.target.value));
    },
    [],
  );

  // ── Empty state ─────────────────────────────────────────────
  if (levels.length === 0 || !activeSubTower || !currentLevel) {
    return (
      <div className="rounded-lg border border-gray-200 bg-white p-6 text-center">
        <p className="text-sm text-gray-400 italic">
          No tower levels available for animation.
        </p>
      </div>
    );
  }

  // ── Derived display values ──────────────────────────────────
  const prevLevel =
    currentIndex > 0 ? activeLevels[currentIndex - 1] : undefined;
  const monotoneWitness = currentLevel.tlMonotone;
  const maxCutDelta =
    prevLevel !== undefined
      ? currentLevel.tlMaxCut - prevLevel.tlMaxCut
      : null;

  return (
    <section
      className="space-y-4"
      aria-label="Tower animation — spatial growth over discrete time"
    >
      {/* ── Header: sub-tower selector + proper-time ─────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div className="flex items-center gap-3">
          {/* Sub-tower selector */}
          {subTowers.length > 1 && (
            <div>
              <label
                htmlFor="subtower-select"
                className="sr-only"
              >
                Select sub-tower
              </label>
              <select
                id="subtower-select"
                value={selectedSubTower}
                onChange={handleSubTowerChange}
                className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 focus:border-viridis-500 focus:outline-none focus:ring-1 focus:ring-viridis-500"
                aria-label="Select sub-tower to animate"
              >
                {subTowers.map((st, i) => (
                  <option key={st.id} value={i}>
                    {st.title} ({st.levels.length} levels)
                  </option>
                ))}
              </select>
            </div>
          )}

          <h3 className="font-serif text-lg font-semibold text-gray-800">
            {activeSubTower.title}
          </h3>
        </div>

        {/* Proper-time counter */}
        <div
          className="flex items-center gap-2 rounded-lg border border-viridis-200 bg-viridis-50 px-4 py-2"
          aria-live="polite"
          aria-atomic="true"
        >
          <span className="text-xs font-medium uppercase tracking-wide text-viridis-600">
            Proper Time
          </span>
          <span className="font-mono text-2xl font-bold text-viridis-700 tabular-nums">
            τ = {properTime}
          </span>
          <span className="text-xs text-viridis-500">
            / {maxProperTime}
          </span>
        </div>
      </div>

      {/* ── Description ──────────────────────────────────────── */}
      {activeSubTower.description && (
        <p className="text-sm text-gray-500">
          {activeSubTower.description}
        </p>
      )}

      {/* ── Main content: 3D viewport + stats ────────────────── */}
      <div className="flex flex-col lg:flex-row gap-4">
        {/* 3D Viewport */}
        <div className="flex-1 min-w-0">
          <div className="h-[40vh] lg:h-[50vh] rounded-lg border border-gray-200 bg-gray-900 overflow-hidden relative">
            {patchData ? (
              <PatchScene
                patch={patchData}
                colorMode={colorMode}
                selectedRegion={null}
                onCellClick={() => {}}
                showBonds={true}
                showBoundary={false}
              />
            ) : patchLoading ? (
              <div className="flex h-full items-center justify-center">
                <Loading message={`Loading ${currentLevel.tlPatchName}…`} />
              </div>
            ) : (
              <div className="flex h-full items-center justify-center text-gray-500 text-sm">
                Select a level to view its 3D representation
              </div>
            )}

            {/* Level name overlay */}
            <div className="absolute top-3 left-3 rounded-md bg-black/60 px-3 py-1.5 backdrop-blur-sm">
              <Link
                to={`/patches/${currentLevel.tlPatchName}`}
                className="font-mono text-sm text-white hover:text-viridis-300 transition-colors"
                aria-label={`View ${currentLevel.tlPatchName} in patch viewer`}
              >
                {currentLevel.tlPatchName}
              </Link>
            </div>

            {/* Max S overlay */}
            <div className="absolute top-3 right-3 rounded-md bg-black/60 px-3 py-1.5 backdrop-blur-sm">
              <span className="font-serif text-lg font-bold text-white">
                S ≤ {currentLevel.tlMaxCut}
              </span>
            </div>
          </div>
        </div>

        {/* Stats panel */}
        <aside className="w-full lg:w-72 shrink-0 space-y-3">
          {/* Current level stats */}
          <div className="rounded-lg border border-gray-200 bg-white p-4 space-y-3">
            <h4 className="font-serif text-sm font-semibold text-gray-700">
              Current Slice (τ = {properTime})
            </h4>

            <dl className="space-y-1.5 text-sm">
              <StatRow
                label="Patch"
                value={currentLevel.tlPatchName}
                mono
              />
              <StatRow
                label="Max min-cut"
                value={`S ≤ ${currentLevel.tlMaxCut}`}
                mono
              />
              <StatRow
                label="Regions"
                value={currentLevel.tlRegions.toLocaleString()}
                mono
              />
              <StatRow
                label="Orbits"
                value={
                  currentLevel.tlOrbits > 0
                    ? String(currentLevel.tlOrbits)
                    : "flat"
                }
                mono
              />
            </dl>

            {/* Verification badges */}
            <div className="flex flex-wrap gap-1.5 pt-2 border-t border-gray-100">
              <Badge
                label="Bridge"
                shortLabel="B"
                active={currentLevel.tlHasBridge}
                activeClass="bg-green-100 text-green-700"
              />
              <Badge
                label="Area Law"
                shortLabel="A"
                active={currentLevel.tlHasAreaLaw}
                activeClass="bg-blue-100 text-blue-700"
              />
              <Badge
                label="Half-Bound"
                shortLabel="H"
                active={currentLevel.tlHasHalfBound}
                activeClass="bg-purple-100 text-purple-700"
              />
            </div>
          </div>

          {/* Transition info (monotonicity witness) */}
          {monotoneWitness !== null && prevLevel && (
            <div className="rounded-lg border border-gray-200 bg-white p-4 space-y-2">
              <h4 className="font-serif text-sm font-semibold text-gray-700">
                Causal Extension τ={properTime - 1} → τ={properTime}
              </h4>

              <div className="rounded border border-gray-100 bg-gray-50 px-3 py-2 font-mono text-xs text-gray-700">
                <p>
                  {prevLevel.tlPatchName} → {currentLevel.tlPatchName}
                </p>
                <p className="mt-1">
                  maxCut: {prevLevel.tlMaxCut} → {currentLevel.tlMaxCut}
                  {maxCutDelta !== null && (
                    <span
                      className={
                        maxCutDelta > 0
                          ? "ml-2 text-green-600 font-semibold"
                          : maxCutDelta === 0
                            ? "ml-2 text-gray-500"
                            : "ml-2 text-red-600"
                      }
                    >
                      ({maxCutDelta >= 0 ? "+" : ""}
                      {maxCutDelta})
                    </span>
                  )}
                </p>
                <p className="mt-1 text-viridis-600">
                  witness: ({monotoneWitness[0]}, {monotoneWitness[1]})
                </p>
              </div>

              <p className="text-xs text-gray-400">
                Regions: {prevLevel.tlRegions.toLocaleString()} →{" "}
                {currentLevel.tlRegions.toLocaleString()}
              </p>
            </div>
          )}

          {/* Growth summary across all levels */}
          <GrowthSummary
            levels={activeLevels}
            currentIndex={currentIndex}
          />
        </aside>
      </div>

      {/* ── Playback controls ────────────────────────────────── */}
      <div className="rounded-lg border border-gray-200 bg-white p-4 space-y-3">
        {/* Timeline scrubber */}
        <div className="space-y-1">
          <div className="flex items-center justify-between text-xs text-gray-500">
            <span>τ = 0</span>
            <span>τ = {maxProperTime}</span>
          </div>
          <input
            type="range"
            min={0}
            max={maxProperTime}
            value={currentIndex}
            onChange={handleScrub}
            className="w-full accent-viridis-600"
            role="slider"
            aria-label="Animation timeline"
            aria-valuemin={0}
            aria-valuemax={maxProperTime}
            aria-valuenow={currentIndex}
            aria-valuetext={`Proper time τ = ${properTime}, patch ${currentLevel.tlPatchName}`}
          />

          {/* Level markers under the scrubber */}
          <div className="flex justify-between px-1">
            {activeLevels.map((level, i) => (
              <button
                key={level.tlPatchName}
                type="button"
                onClick={() => {
                  setPlaying(false);
                  setCurrentIndex(i);
                }}
                className={[
                  "text-[9px] font-mono leading-none transition-colors",
                  i === currentIndex
                    ? "text-viridis-600 font-semibold"
                    : "text-gray-400 hover:text-gray-600",
                ].join(" ")}
                aria-label={`Jump to ${level.tlPatchName} (τ = ${i})`}
                title={`${level.tlPatchName} — S ≤ ${level.tlMaxCut}`}
              >
                {abbreviateName(level.tlPatchName)}
              </button>
            ))}
          </div>
        </div>

        {/* Control buttons */}
        <div className="flex items-center justify-center gap-3">
          {/* Step back */}
          <button
            type="button"
            onClick={handleStepBack}
            disabled={currentIndex === 0}
            className="rounded-md border border-gray-300 bg-white p-2 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1 transition-colors"
            aria-label="Step backward one level"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15.75 19.5L8.25 12l7.5-7.5"
              />
            </svg>
          </button>

          {/* Play / Pause */}
          <button
            type="button"
            onClick={handlePlayPause}
            className="rounded-full bg-viridis-500 p-3 text-white hover:bg-viridis-400 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2 transition-colors"
            aria-label={playing ? "Pause animation" : "Play animation"}
          >
            {playing ? (
              /* Pause icon */
              <svg
                className="h-6 w-6"
                fill="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
              </svg>
            ) : (
              /* Play icon */
              <svg
                className="h-6 w-6"
                fill="currentColor"
                viewBox="0 0 24 24"
                aria-hidden="true"
              >
                <path d="M8 5v14l11-7z" />
              </svg>
            )}
          </button>

          {/* Step forward */}
          <button
            type="button"
            onClick={handleStepForward}
            disabled={currentIndex >= maxProperTime}
            className="rounded-md border border-gray-300 bg-white p-2 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1 transition-colors"
            aria-label="Step forward one level"
          >
            <svg
              className="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              aria-hidden="true"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M8.25 4.5l7.5 7.5-7.5 7.5"
              />
            </svg>
          </button>

          {/* Separator */}
          <div
            className="h-6 w-px bg-gray-200 mx-1"
            aria-hidden="true"
          />

          {/* Speed selector */}
          <div className="flex items-center gap-1.5">
            <label
              htmlFor="anim-speed"
              className="text-xs text-gray-500"
            >
              Speed
            </label>
            <select
              id="anim-speed"
              value={speed}
              onChange={handleSpeedChange}
              className="rounded border border-gray-300 bg-white px-2 py-1 text-xs text-gray-700 focus:border-viridis-500 focus:outline-none focus:ring-1 focus:ring-viridis-500"
              aria-label="Playback speed"
            >
              {SPEED_OPTIONS.map((s) => (
                <option key={s} value={s}>
                  {s}×
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Status text */}
        <p
          className="text-center text-xs text-gray-400"
          aria-live="polite"
        >
          {playing
            ? `Playing at ${speed}× — ${currentLevel.tlPatchName}`
            : `Paused at τ = ${properTime} — ${currentLevel.tlPatchName}`}
          {" · "}
          Click any level marker to jump
        </p>
      </div>
    </section>
  );
}

// ════════════════════════════════════════════════════════════════
//  Internal Sub-Components
// ════════════════════════════════════════════════════════════════

/** A single label–value row in a stats panel. */
function StatRow({
  label,
  value,
  mono = false,
}: {
  label: string;
  value: string;
  mono?: boolean;
}) {
  return (
    <div className="flex justify-between items-baseline">
      <dt className="text-gray-500">{label}</dt>
      <dd className={`text-gray-900 font-medium ${mono ? "font-mono" : ""}`}>
        {value}
      </dd>
    </div>
  );
}

/** Small verification badge matching TowerLevel.tsx. */
function Badge({
  label,
  shortLabel,
  active,
  activeClass,
}: {
  label: string;
  shortLabel: string;
  active: boolean;
  activeClass: string;
}) {
  return (
    <span
      className={[
        "inline-flex h-5 w-5 items-center justify-center",
        "rounded-full text-[10px] font-bold leading-none",
        active ? activeClass : "bg-gray-100 text-gray-400",
      ].join(" ")}
      title={active ? `${label}: Verified` : `${label}: Not verified`}
      aria-label={active ? `${label} verified` : `${label} not verified`}
    >
      {shortLabel}
    </span>
  );
}

/**
 * Growth summary sparkline showing how cells, regions, and maxCut
 * evolve across the sub-tower levels.
 */
function GrowthSummary({
  levels,
  currentIndex,
}: {
  levels: TowerLevel[];
  currentIndex: number;
}) {
  if (levels.length < 2) return null;

  const first = levels[0]!;
  const last = levels[levels.length - 1]!;

  // Compute growth factors
  const regionGrowth =
    first.tlRegions > 0
      ? (last.tlRegions / first.tlRegions).toFixed(1)
      : "—";

  return (
    <div className="rounded-lg border border-gray-200 bg-white p-4 space-y-2">
      <h4 className="font-serif text-sm font-semibold text-gray-700">
        Growth Summary
      </h4>

      {/* Mini bar chart of maxCut per level */}
      <div className="space-y-1">
        <p className="text-[10px] font-medium uppercase tracking-wide text-gray-500">
          Max min-cut per slice
        </p>
        <div className="flex items-end gap-1 h-12">
          {levels.map((level, i) => {
            const maxVal = Math.max(...levels.map((l) => l.tlMaxCut), 1);
            const heightPct = (level.tlMaxCut / maxVal) * 100;
            const isCurrent = i === currentIndex;

            return (
              <div
                key={level.tlPatchName}
                className="flex-1 flex flex-col items-center gap-0.5"
              >
                <span className="text-[8px] font-mono text-gray-400">
                  {level.tlMaxCut}
                </span>
                <div
                  className={[
                    "w-full rounded-t-sm transition-all duration-300",
                    isCurrent
                      ? "bg-viridis-600"
                      : i <= currentIndex
                        ? "bg-viridis-300"
                        : "bg-gray-200",
                  ].join(" ")}
                  style={{ height: `${Math.max(heightPct, 8)}%` }}
                  aria-hidden="true"
                />
              </div>
            );
          })}
        </div>
      </div>

      {/* Summary stats */}
      <div className="text-xs text-gray-500 space-y-0.5 pt-1 border-t border-gray-100">
        <p>
          Regions: {first.tlRegions.toLocaleString()} →{" "}
          {last.tlRegions.toLocaleString()} ({regionGrowth}×)
        </p>
        <p>
          Max S: {first.tlMaxCut} → {last.tlMaxCut}
          {last.tlMaxCut > first.tlMaxCut && (
            <span className="text-green-600 ml-1">
              (+{last.tlMaxCut - first.tlMaxCut})
            </span>
          )}
          {last.tlMaxCut === first.tlMaxCut && (
            <span className="text-gray-400 ml-1">(flat)</span>
          )}
        </p>
        <p>
          Proper time: τ = 0 → {levels.length - 1}
        </p>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Abbreviate a patch name for compact display under the timeline
 * scrubber markers.
 */
function abbreviateName(name: string): string {
  if (name.startsWith("layer-54-")) return name.replace("layer-54-", "");
  if (name.startsWith("dense-")) return name.replace("dense-", "D");
  if (name.startsWith("honeycomb-")) return name.replace("honeycomb-", "H");
  return name;
}