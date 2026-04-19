/**
 * TowerView — Full `/tower` page displaying the resolution tower
 * timeline with monotone convergence certificates.
 *
 * This is the top-level page component for the `/tower` route. It
 * fetches the tower level data from `GET /tower` via the `useTower`
 * hook, handles loading and error states, and renders the full page
 * layout including:
 *
 *   - A page header with title and description
 *   - Summary statistics (total levels, sub-towers, max min-cut range)
 *   - The interactive {@link TowerTimeline} component showing all
 *     sub-towers with monotonicity arrows
 *   - An explanatory section on what the tower represents
 *   - A footer note citing the source module
 *
 * The tower data contains two sub-towers (identified by `tlMonotone`
 * boundaries in the TowerTimeline component):
 *
 *   1. **Dense Resolution Tower** (3 levels: Dense-50 → Dense-100 →
 *      Dense-200) with monotone max min-cut growth: 7 → 8 → 9.
 *      This sub-tower carries three levels of entropy-area constraint
 *      (RT correspondence, area law, and the sharp Bekenstein–Hawking
 *      half-bound) and forms the `DiscreteBekensteinHawking` capstone
 *      type in `Bridge/SchematicTower.agda`.
 *
 *   2. **{5,4} Layer Tower** (6 levels: depths 2–7) with exponential
 *      tile growth (21 → 3046 tiles) but constant maxCut = 2. This
 *      sub-tower demonstrates that the proof architecture scales to
 *      exponentially growing hyperbolic patches without increasing
 *      proof complexity (orbit count stays at 2 regardless of depth).
 *
 * Interactions:
 *   - Click any tower level card → navigates to `/patches/:name`
 *     for the full 3D patch viewer (handled by TowerLevel)
 *   - Hover/focus a monotonicity arrow → highlights the two adjacent
 *     level cards (handled by TowerTimeline)
 *
 * Fixes applied (review issue #9):
 *   The `useTower` hook exposes a `refetch` callback that is wired
 *   to the `<ErrorMessage onRetry={refetch}>` so the user can retry
 *   a failed fetch without a full page reload.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.4 (Tower Timeline)
 *   - docs/formal/11-generic-bridge.md (SchematicTower)
 *   - docs/formal/12-bekenstein-hawking.md (ConvergenceCertificate)
 *   - docs/instances/layer-54-tower.md (Layer tower instance)
 *   - docs/instances/dense-100.md (Dense tower, Level 1)
 *   - data/tower.json (the 9 tower levels)
 */

import { useMemo } from "react";

import { useTower } from "../../hooks/useTower";
import { Loading } from "../common/Loading";
import { ErrorMessage } from "../common/ErrorMessage";
import { TowerTimeline } from "./TowerTimeline";

// ════════════════════════════════════════════════════════════════
//  Summary Statistics
// ════════════════════════════════════════════════════════════════

/**
 * Computed summary statistics for the tower data, displayed in
 * the page header as compact stat cards.
 */
interface TowerSummary {
  /** Total number of tower levels across all sub-towers. */
  totalLevels: number;
  /** Number of distinct sub-towers (identified by null-monotone boundaries). */
  subTowerCount: number;
  /** Minimum maxCut value across all levels. */
  minMaxCut: number;
  /** Maximum maxCut value across all levels. */
  maxMaxCut: number;
  /** Total number of regions across all levels. */
  totalRegions: number;
  /** Number of levels with a verified BridgeWitness. */
  bridgeCount: number;
  /** Number of levels with a verified half-bound. */
  halfBoundCount: number;
}

/**
 * Compute summary statistics from the tower level data.
 *
 * @param levels - All tower levels from `GET /tower`.
 * @returns Aggregated statistics for the page header.
 */
function computeSummary(
  levels: Array<{
    tlMaxCut: number;
    tlRegions: number;
    tlMonotone: [number, string] | null;
    tlHasBridge: boolean;
    tlHasHalfBound: boolean;
  }>,
): TowerSummary {
  if (levels.length === 0) {
    return {
      totalLevels: 0,
      subTowerCount: 0,
      minMaxCut: 0,
      maxMaxCut: 0,
      totalRegions: 0,
      bridgeCount: 0,
      halfBoundCount: 0,
    };
  }

  let subTowerCount = 0;
  let minMaxCut = Infinity;
  let maxMaxCut = -Infinity;
  let totalRegions = 0;
  let bridgeCount = 0;
  let halfBoundCount = 0;

  for (const level of levels) {
    // A null monotone witness marks the start of a new sub-tower.
    if (level.tlMonotone === null) {
      subTowerCount++;
    }

    minMaxCut = Math.min(minMaxCut, level.tlMaxCut);
    maxMaxCut = Math.max(maxMaxCut, level.tlMaxCut);
    totalRegions += level.tlRegions;

    if (level.tlHasBridge) bridgeCount++;
    if (level.tlHasHalfBound) halfBoundCount++;
  }

  return {
    totalLevels: levels.length,
    subTowerCount,
    minMaxCut: minMaxCut === Infinity ? 0 : minMaxCut,
    maxMaxCut: maxMaxCut === -Infinity ? 0 : maxMaxCut,
    totalRegions,
    bridgeCount,
    halfBoundCount,
  };
}

// ════════════════════════════════════════════════════════════════
//  Stat Card Sub-Component
// ════════════════════════════════════════════════════════════════

/**
 * A small informational card displaying a single statistic with
 * a label. Used in the page header's summary grid.
 */
function StatCard({
  label,
  value,
  detail,
}: {
  /** Short label describing the statistic. */
  label: string;
  /** The primary value (displayed large). */
  value: string | number;
  /** Optional secondary detail text. */
  detail?: string;
}) {
  return (
    <div className="rounded-lg border border-gray-200 bg-white px-4 py-3 text-center shadow-sm">
      <p className="font-mono text-xl font-bold text-gray-900 leading-tight">
        {value}
      </p>
      <p className="mt-1 text-xs font-medium text-gray-500 uppercase tracking-wide">
        {label}
      </p>
      {detail && (
        <p className="mt-0.5 text-[10px] text-gray-400">{detail}</p>
      )}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * The `/tower` page — resolution tower visualization showing
 * monotone convergence across patch resolutions.
 *
 * Fetches tower data on mount via `useTower`, renders loading/error
 * states, then displays the full page with summary statistics, the
 * interactive timeline, and explanatory context.
 *
 * The `refetch` callback from `useTower` is wired to the ErrorMessage
 * component's `onRetry` prop (review issue #9), so the user can retry
 * a failed tower data fetch without a full page reload.
 */
export function TowerView() {
  const { data, loading, error, refetch } = useTower();

  // Compute summary stats from the loaded data.
  const summary = useMemo(
    () => (data ? computeSummary(data) : null),
    [data],
  );

  // ── Loading state ─────────────────────────────────────────────
  if (loading) {
    return <Loading message="Loading resolution tower…" />;
  }

  // ── Error state (review issue #9: wire onRetry to refetch) ────
  if (error) {
    return <ErrorMessage message={error} onRetry={refetch} />;
  }

  // ── Empty data state ──────────────────────────────────────────
  if (!data || data.length === 0) {
    return (
      <div className="max-w-5xl mx-auto px-4 py-8">
        <h1 className="font-serif text-3xl font-bold text-gray-900 mb-4">
          Resolution Tower
        </h1>
        <p className="text-gray-500">No tower data available.</p>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      {/* ── Page Header ─────────────────────────────────────── */}
      <header className="mb-8">
        <h1 className="font-serif text-3xl font-bold text-gray-900 mb-2">
          Resolution Tower
        </h1>
        <p className="text-lg text-gray-600">
          Monotone Convergence Certificate
        </p>
        <p className="mt-2 text-sm text-gray-500 max-w-3xl">
          The resolution tower assembles verified patches into a sequence
          of increasing resolution, with monotonicity witnesses proving
          that the holographic depth (max min-cut) is non-decreasing.
          Each level carries a full{" "}
          <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
            BridgeWitness
          </span>{" "}
          — the enriched type equivalence, Univalence path, and verified
          transport produced by the generic bridge theorem.
        </p>
      </header>

      {/* ── Summary Statistics ───────────────────────────────── */}
      {summary && (
        <section
          className="mb-10"
          aria-label="Tower summary statistics"
        >
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
            <StatCard
              label="Levels"
              value={summary.totalLevels}
              detail={`${summary.subTowerCount} sub-tower${summary.subTowerCount !== 1 ? "s" : ""}`}
            />
            <StatCard
              label="Max S Range"
              value={
                summary.minMaxCut === summary.maxMaxCut
                  ? String(summary.minMaxCut)
                  : `${summary.minMaxCut}–${summary.maxMaxCut}`
              }
              detail="min-cut spectrum"
            />
            <StatCard
              label="Total Regions"
              value={summary.totalRegions.toLocaleString()}
              detail="across all levels"
            />
            <StatCard
              label="Bridges"
              value={`${summary.bridgeCount}/${summary.totalLevels}`}
              detail="verified S = L"
            />
            <StatCard
              label="Half-Bounds"
              value={`${summary.halfBoundCount}/${summary.totalLevels}`}
              detail="2·S ≤ area verified"
            />
            <StatCard
              label="1/(4G)"
              value="1/2"
              detail="discrete Newton's constant"
            />
          </div>
        </section>
      )}

      {/* ── Tower Timeline ──────────────────────────────────── */}
      <section
        className="mb-10"
        aria-label="Resolution tower timeline"
      >
        <TowerTimeline levels={data} />
      </section>

      {/* ── Explanatory Context ─────────────────────────────── */}
      <section
        className="mb-10 max-w-3xl mx-auto"
        aria-label="About the resolution tower"
      >
        <h2 className="font-serif text-xl font-semibold text-gray-800 mb-4">
          What the Tower Proves
        </h2>
        <div className="text-sm text-gray-600 space-y-3 leading-relaxed">
          <p>
            The <strong>Dense Resolution Tower</strong> demonstrates that the
            holographic depth (maximum min-cut value) grows monotonically
            with patch size: 7 → 8 → 9 across 50, 100, and 200 cells.
            Each step is witnessed by a{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              (k, refl)
            </span>{" "}
            proof that the new max min-cut exceeds the previous by exactly{" "}
            <em>k</em>. The Dense-100 and Dense-200 levels additionally
            carry the sharp Bekenstein–Hawking half-bound{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              2·S(A) ≤ area(A)
            </span>
            , identifying the discrete Newton&apos;s constant as 1/(4G) = 1/2.
          </p>
          <p>
            The <strong>{"{5,4}"} Layer Tower</strong> demonstrates that the
            proof architecture scales to exponentially growing hyperbolic
            patches without increasing proof complexity. From 21 tiles
            (depth 2) to 3,046 tiles (depth 7), the boundary region count
            grows from 15 to 1,885 — but the orbit count stays constant at
            2, meaning every bridge proof has exactly 2{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              refl
            </span>{" "}
            cases regardless of patch size. This is the discrete analogue of
            the statement that holographic complexity is O(1) in the
            boundary size.
          </p>
          <p>
            Together, the two sub-towers form the{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              DiscreteBekensteinHawking
            </span>{" "}
            capstone type in{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              Bridge/SchematicTower.agda
            </span>
            , the strongest entropy-area statement in the repository.
          </p>
        </div>
      </section>

      {/* ── The Causal Interpretation ───────────────────────── */}
      <section
        className="mb-10 max-w-3xl mx-auto"
        aria-label="Causal interpretation"
      >
        <h2 className="font-serif text-xl font-semibold text-gray-800 mb-4">
          Causal Interpretation
        </h2>
        <div className="text-sm text-gray-600 space-y-3 leading-relaxed">
          <p>
            In the causal layer, the layer tower is a{" "}
            <em>discrete spacetime</em>: 6 verified spatial slices connected
            by 5 future-directed causal extensions, each a BFS expansion
            adding a new ring of pentagonal tiles. The{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              CausalDiamond
            </span>{" "}
            packages the tower with proper time = 5 and maximin entropy = 2.
          </p>
          <p>
            The{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              NoCTC
            </span>{" "}
            theorem (Theorem 5) ensures that no closed timelike curve can
            exist within this causal structure — the type signature of{" "}
            <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
              CausalLink
            </span>{" "}
            prevents time travel by construction.
          </p>
        </div>
      </section>

      {/* ── Footer Note ─────────────────────────────────────── */}
      <footer className="text-center text-xs text-gray-400 border-t border-gray-200 pt-6">
        <p>
          Source:{" "}
          <span className="font-mono">
            Bridge/SchematicTower.agda
          </span>
          {" · "}
          Verify:{" "}
          <span className="font-mono">
            agda src/Bridge/SchematicTower.agda
          </span>
        </p>
        <p className="mt-1">
          Causal diamond:{" "}
          <span className="font-mono">
            Causal/CausalDiamond.agda
          </span>
          {" · "}
          Tower data:{" "}
          <span className="font-mono">
            data/tower.json
          </span>
        </p>
      </footer>
    </div>
  );
}