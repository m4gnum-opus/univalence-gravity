/**
 * PatchView — The full `/patches/:name` 3-panel page.
 *
 * This is the heaviest component in the application: it composes the
 * 3D viewport (PatchScene), the region inspector, curvature and
 * half-bound panels, distribution charts, and color/visibility
 * controls into a responsive multi-panel layout.
 *
 * **Data flow:**
 *   1. Extracts the `name` route parameter via React Router's `useParams`
 *   2. Fetches the full Patch data (including all regions, curvature,
 *      and half-bound statistics) via the `usePatch` hook
 *   3. Manages visualization state (color mode, selected region,
 *      bond/boundary/shell visibility) in local React state
 *   4. Passes state + callbacks down to child components
 *
 * **Layout (responsive):**
 *
 *   Desktop/Tablet (lg+):
 *   ```
 *   ┌─────────────────────────────────┬─────────────────────┐
 *   │                                 │  Region Inspector   │
 *   │         3D Viewport             │  Curvature Panel    │
 *   │                                 │  Half-Bound Panel   │
 *   ├─────────────────────────────────┤  Distribution Chart │
 *   │   Color Controls + Toggles      │                     │
 *   └─────────────────────────────────┴─────────────────────┘
 *   ```
 *
 *   Mobile (<lg):
 *   ```
 *   ┌─────────────────────────────────┐
 *   │         3D Viewport (50vh)      │
 *   ├─────────────────────────────────┤
 *   │   Color Controls + Toggles      │
 *   ├─────────────────────────────────┤
 *   │   Region Inspector              │
 *   │   Curvature Panel               │
 *   │   Half-Bound Panel              │
 *   │   Distribution Chart            │
 *   └─────────────────────────────────┘
 *   ```
 *
 * **Interactions:**
 *   - Click a cell in the 3D viewport → selects its singleton region,
 *     populating the RegionInspector with that cell's stats
 *   - Click the viewport background → deselects the current region
 *   - Change color mode → all cells update their colors
 *   - Toggle bonds/boundary/shell → PatchScene shows/hides overlays
 *
 * **Phase 2 — Boundary Shell (item 16):**
 *   PatchView now manages a `showShell` boolean state (default: false)
 *   and passes it to both PatchScene (which renders the BoundaryShell
 *   component when true) and ColorControls (which renders the toggle
 *   checkbox alongside the existing bonds and wireframe toggles).
 *   The boundary shell is a semi-transparent convex hull or fitted
 *   sphere around boundary cell positions, visualizing the holographic
 *   boundary surface — "the 2D boundary encodes the 3D bulk."
 *
 * **Performance:**
 *   The full Patch (with all region data) is fetched only when the
 *   user navigates to this page — the `/patches` listing uses the
 *   lightweight PatchSummary type. PatchScene internally handles
 *   InstancedMesh for patches with >500 boundary cells.
 *
 * Fixes applied (review issue #9):
 *   The `usePatch` hook exposes a `refetch` callback that is wired
 *   to the `<ErrorMessage onRetry={refetch}>` on the non-404 error
 *   branch, so the user can retry a failed request (e.g. network
 *   error, server down) without a full page reload. 404 errors
 *   (nonexistent patch name) still render the NotFound component
 *   since retrying would produce the same result.
 *
 * @see PatchScene — The Three.js Canvas with OrbitControls and all 3D meshes
 * @see RegionInspector — Side panel detail view for a selected region
 * @see CurvaturePanel — Curvature class table + Gauss–Bonnet badge
 * @see HalfBoundPanel — Bekenstein–Hawking half-bound statistics
 * @see DistributionChart — Histograms of min-cut and S/area distributions
 * @see ColorControls — Radio buttons for color mode + visibility toggles
 * @see BoundaryShell — Semi-transparent convex hull around boundary cells
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3 (Patch Viewer)
 *   - docs/engineering/frontend-spec-webgl.md §4.2 (Progressive Disclosure)
 *   - docs/engineering/frontend-spec-webgl.md §9 (Responsive Breakpoints)
 */

import { useState, useCallback, useMemo, useEffect } from "react";
import { useParams, Link } from "react-router-dom";

import { usePatch } from "../../hooks/usePatch";
import { Loading } from "../common/Loading";
import { ErrorMessage } from "../common/ErrorMessage";
import { NotFound } from "../common/NotFound";
import { PatchScene } from "./PatchScene";
import { RegionInspector } from "./RegionInspector";
import { CurvaturePanel } from "./CurvaturePanel";
import { HalfBoundPanel } from "./HalfBoundPanel";
import { DistributionChart } from "./DistributionChart";
import { ColorControls } from "./ColorControls";
import { TILING_SYMBOL } from "../../utils/tiling";
import type { ColorMode, Region } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Display Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Format the orbit info for display.
 *
 * - patchOrbits > 0: "717 → 8 orbits" (orbit reduction active)
 * - patchOrbits === 0: "139" (flat enumeration, no orbits to show)
 */
function formatOrbitDisplay(regions: number, orbits: number): string {
  if (orbits > 0) {
    return `${regions.toLocaleString()} → ${orbits} orbits`;
  }
  return regions.toLocaleString();
}

/**
 * Format a dimension number as a human-readable label.
 */
function dimensionLabel(dim: number): string {
  return `${dim}D`;
}

// ════════════════════════════════════════════════════════════════
//  Stat Item Sub-Component
// ════════════════════════════════════════════════════════════════

/**
 * A single statistic in the patch header's stat bar.
 */
function StatItem({
  label,
  value,
}: {
  label: string;
  value: string | number;
}) {
  return (
    <div className="flex flex-col items-center px-3 py-1.5">
      <span className="font-mono text-sm font-semibold text-gray-900">
        {value}
      </span>
      <span className="text-[10px] font-medium uppercase tracking-wide text-gray-500">
        {label}
      </span>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * The full `/patches/:name` page — interactive 3D patch viewer
 * with region selection, color modes, and data panels.
 *
 * Route: `/patches/:name` (e.g. `/patches/dense-100`)
 */
export function PatchView() {
  // ── Route parameter ────────────────────────────────────────────
  const { name } = useParams<{ name: string }>();

  // ── Data fetching ──────────────────────────────────────────────
  const { data, loading, error, refetch } = usePatch(name ?? "");

  // ── Visualization state ────────────────────────────────────────
  const [colorMode, setColorMode] = useState<ColorMode>("mincut");
  const [selectedRegion, setSelectedRegion] = useState<Region | null>(null);
  const [showBonds, setShowBonds] = useState<boolean>(true);
  const [showBoundary, setShowBoundary] = useState<boolean>(false);
  const [showShell, setShowShell] = useState<boolean>(false);

  // ── Reset selection and shell on patch navigation ──────────────
  //
  // When the user navigates from one patch to another (e.g.
  // /patches/dense-100 → /patches/dense-200), the selected region
  // from the previous patch must be cleared. Without this, the
  // RegionInspector would briefly show stale data from the old
  // patch when the new data arrives.  The shell toggle is also
  // reset to off — different patches have very different boundary
  // structures, and the shell from a previous patch would be
  // misleading during the loading transition.
  useEffect(() => {
    setSelectedRegion(null);
    setShowShell(false);
  }, [name]);

  // ── Cell ID → singleton Region mapping ─────────────────────────
  //
  // Each boundary cell has exactly one singleton region (size-1) in
  // the region data. This map is used to resolve cell clicks in the
  // 3D viewport to a displayable region in the RegionInspector.
  const cellToSingletonRegion = useMemo(() => {
    if (!data) return new Map<number, Region>();
    const map = new Map<number, Region>();
    for (const r of data.patchRegionData) {
      if (r.regionSize === 1 && r.regionCells.length === 1) {
        const cellId = r.regionCells[0];
        if (cellId !== undefined) {
          map.set(cellId, r);
        }
      }
    }
    return map;
  }, [data]);

  // ── Event handlers ─────────────────────────────────────────────

  /**
   * Handle a cell click in the 3D viewport.
   *
   * Resolves the clicked cell ID to its singleton region and
   * selects it for inspection. If the cell has no singleton region
   * (shouldn't happen with valid data, but defensive), deselects.
   */
  const handleCellClick = useCallback(
    (cellId: number) => {
      const region = cellToSingletonRegion.get(cellId) ?? null;
      setSelectedRegion(region);
    },
    [cellToSingletonRegion],
  );

  /**
   * Handle clicking the viewport background (not on any cell).
   * Deselects the current region.
   */
  const handleBackgroundClick = useCallback(() => {
    setSelectedRegion(null);
  }, []);

  /**
   * Handle the "Clear" button in the RegionInspector.
   * Deselects the current region.
   */
  const handleDeselect = useCallback(() => {
    setSelectedRegion(null);
  }, []);

  // ── Loading state ──────────────────────────────────────────────
  if (loading) {
    return <Loading message={`Loading ${name ?? "patch"} data…`} />;
  }

  // ── Error: 404 → NotFound ──────────────────────────────────────
  //
  // usePatch produces "Patch not found: <name>" for 404 responses.
  // Retrying a 404 would produce the same result, so we render the
  // NotFound component without a retry button.
  if (error && error.startsWith("Patch not found")) {
    return <NotFound />;
  }

  // ── Other errors → ErrorMessage with retry (review issue #9) ───
  //
  // For non-404 errors (network failure, server down, 500, etc.),
  // display the error message with a retry button wired to the
  // usePatch hook's refetch callback. This lets the user recover
  // from transient failures without a full page reload.
  if (error) {
    return <ErrorMessage message={error} onRetry={refetch} />;
  }

  // ── No data (defensive — shouldn't happen after loading) ───────
  if (!data) {
    return <NotFound />;
  }

  // ── Derived display values ─────────────────────────────────────
  const tilingSymbol = TILING_SYMBOL[data.patchTiling];
  const hasCurvature = data.patchCurvature !== null;

  // ── Render ─────────────────────────────────────────────────────
  return (
    <div className="space-y-4">
      {/* ── Breadcrumb Navigation ─────────────────────────────── */}
      <nav aria-label="Breadcrumb">
        <Link
          to="/patches"
          className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-viridis-600 transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2 rounded"
        >
          <span aria-hidden="true">←</span>
          All Patches
        </Link>
      </nav>

      {/* ── Patch Header ──────────────────────────────────────── */}
      <header>
        {/* Title row */}
        <div className="flex flex-wrap items-baseline gap-x-3 gap-y-1">
          <h1 className="font-serif text-2xl font-bold text-gray-900 sm:text-3xl">
            {data.patchName}
          </h1>
          <p className="text-sm text-gray-500">
            <span>{tilingSymbol}</span>
            <span className="mx-1.5" aria-hidden="true">•</span>
            <span>{dimensionLabel(data.patchDimension)}</span>
            <span className="mx-1.5" aria-hidden="true">•</span>
            <span>{data.patchStrategy}</span>
          </p>
        </div>

        {/* Stats bar */}
        <div className="mt-3 flex flex-wrap items-center gap-1 rounded-lg border border-gray-200 bg-white px-2 py-1">
          <StatItem label="Cells" value={data.patchCells} />
          <Divider />
          <StatItem
            label="Regions"
            value={formatOrbitDisplay(data.patchRegions, data.patchOrbits)}
          />
          <Divider />
          <StatItem label="Max S" value={data.patchMaxCut} />
          <Divider />
          <StatItem label="Bonds" value={data.patchBonds} />
          <Divider />
          <StatItem label="Boundary" value={data.patchBoundary} />
          <Divider />
          <StatItem label="Density" value={data.patchDensity.toFixed(2)} />

          {/* Half-bound verification badge */}
          {data.patchHalfBoundVerified && (
            <>
              <Divider />
              <span
                className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2.5 py-0.5 text-[10px] font-medium text-green-800"
                title="Half-bound 2·S ≤ area verified by Cubical Agda"
              >
                <span aria-hidden="true">✓</span>
                BH Verified
              </span>
            </>
          )}
        </div>
      </header>

      {/* ── Main Content: 2-Column Layout ─────────────────────── */}
      {/*
       * lg+ (≥1024px): side-by-side layout
       *   Left: viewport (flex-1) + controls below
       *   Right: info panel (fixed width, scrollable)
       *
       * <lg: stacked layout
       *   viewport → controls → info panels
       */}
      <div className="flex flex-col lg:flex-row gap-4">
        {/* ── Left Column: Viewport + Controls ──────────────── */}
        <div className="flex-1 min-w-0 space-y-4">
          {/* 3D Viewport */}
          <div
            className="h-[50vh] md:h-[55vh] lg:h-[60vh] xl:h-[70vh] rounded-lg border border-gray-200 bg-gray-900 overflow-hidden"
            aria-label={`3D visualization of patch ${data.patchName}`}
          >
            <PatchScene
              patch={data}
              colorMode={colorMode}
              selectedRegion={selectedRegion}
              onCellClick={handleCellClick}
              showBonds={showBonds}
              showBoundary={showBoundary}
              showShell={showShell}
              onBackgroundClick={handleBackgroundClick}
            />
          </div>

          {/* Color Controls + Visibility Toggles */}
          <div className="rounded-lg border border-gray-200 bg-white p-4">
            <ColorControls
              colorMode={colorMode}
              onColorModeChange={setColorMode}
              showBonds={showBonds}
              onShowBondsChange={setShowBonds}
              showBoundary={showBoundary}
              onShowBoundaryChange={setShowBoundary}
              showShell={showShell}
              onShowShellChange={setShowShell}
              hasCurvature={hasCurvature}
            />
          </div>
        </div>

        {/* ── Right Column: Info Panel ───────────────────────── */}
        <aside
          className="w-full lg:w-80 xl:w-[22rem] shrink-0 space-y-4 lg:max-h-[calc(70vh+4rem)] lg:overflow-y-auto scrollbar-thin"
          aria-label="Patch data panels"
        >
          {/* Region Inspector */}
          <RegionInspector
            region={selectedRegion}
            patchName={data.patchName}
            patchMaxCut={data.patchMaxCut}
            patchTiling={data.patchTiling}
            onDeselect={handleDeselect}
          />

          {/* Curvature Panel */}
          <CurvaturePanel data={data.patchCurvature} />

          {/* Half-Bound Panel (only if half-bound data exists) */}
          {data.patchHalfBound !== null && (
            <div className="rounded-lg border border-gray-200 bg-white p-4">
              <HalfBoundPanel
                halfBound={data.patchHalfBound}
                verified={data.patchHalfBoundVerified}
              />
            </div>
          )}

          {/* Distribution Charts */}
          <DistributionChart
            regions={data.patchRegionData}
            maxCut={data.patchMaxCut}
          />
        </aside>
      </div>

      {/* ── Footer Note ───────────────────────────────────────── */}
      <footer className="text-center text-xs text-gray-400 border-t border-gray-200 pt-4">
        <p>
          Patch data verified by Cubical Agda 2.8.0
          {" · "}
          <span className="font-mono">{data.patchRegions}</span> regions
          {data.patchOrbits > 0 && (
            <>
              {" → "}
              <span className="font-mono">{data.patchOrbits}</span> orbit representatives
            </>
          )}
          {" · "}
          Served from{" "}
          <span className="font-mono">
            data/patches/{data.patchName}.json
          </span>
        </p>
      </footer>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Internal Sub-Components
// ════════════════════════════════════════════════════════════════

/**
 * A thin vertical divider between stat items.
 *
 * Renders as a 1px gray line, 20px tall. Hidden on very narrow
 * screens where the stat items wrap to multiple lines (the flex
 * wrap handles spacing).
 */
function Divider() {
  return (
    <div
      className="hidden sm:block h-5 w-px bg-gray-200 mx-1"
      aria-hidden="true"
    />
  );
}