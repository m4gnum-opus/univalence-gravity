/**
 * PatchScene — The Three.js `<Canvas>` with OrbitControls, lighting,
 * cell meshes, bond connectors, boundary wireframe, and boundary shell.
 *
 * **UPDATED (Phase 1, item 9):** Now renders ALL cells from
 * `patchGraph.pgNodes` (both boundary and interior) and uses ALL
 * physical bonds from `patchGraph.pgEdges` instead of inferring
 * from boundary region data.
 *
 * **UPDATED (Phase 2, item 15–16):** Now accepts a `showShell` prop
 * and renders a semi-transparent `<BoundaryShell>` around boundary
 * cell positions when enabled, visualizing the holographic boundary
 * surface — "the 2D boundary encodes the 3D bulk."
 *
 * **UPDATED (Poincaré projection fix):** pgNodes now carry {id,x,y,z}
 * GraphNode objects with Poincaré-projected coordinates.  Cell IDs
 * are extracted via `.map(n => n.id)`.
 *
 * **UPDATED (Roadmap Step 2 — per-cell conformal scale):**
 *
 *   `computePatchLayout` now returns `Map<number, NodeTransform>`
 *   where each `NodeTransform` bundles both the scene-space
 *   position (`.pos`) AND the conformal scale factor
 *   `s(u) = (1 − |u|²) / 2` (`.scale`) for the corresponding cell.
 *
 *   PatchScene threads this scale through to the rendered cells so
 *   that cells near the centre of the Poincaré ball/disc render
 *   at `~0.5×` their template size while cells near the boundary
 *   shrink toward zero — the hallmark Escher "Circle Limit" effect.
 *   Before this fix, all cells rendered at a uniform size
 *   regardless of their distance from the centre, producing the
 *   "ring of uniform beads" appearance that was the visible bug
 *   report.
 *
 *   Implementation strategy:
 *
 *     - **Non-instanced path (≤500 cells):** Each `CellMesh` is
 *       wrapped in a `<group>` carrying the cell's world position
 *       AND the uniform conformal scale.  The `CellMesh` itself
 *       renders at `[0, 0, 0]` inside the group, so the group's
 *       scale multiplies the mesh geometry without ever touching
 *       `CellMesh`'s prop surface.  This keeps the
 *       `scale`-integration for `CellMesh` as a separate roadmap
 *       item (item 13 in the roadmap checklist) — PatchScene's
 *       changes compile and run independently.
 *
 *     - **Instanced path (>500 cells):** The per-instance scale
 *       is applied to the `Object3D` dummy alongside the position:
 *
 *         dummy.position.set(...transform.pos);
 *         dummy.scale.setScalar(transform.scale);
 *         dummy.updateMatrix();
 *         mesh.setMatrixAt(i, dummy.matrix);
 *
 *       This is the standard Three.js pattern for per-instance
 *       transforms and costs no extra draw calls.
 *
 *     - **Selection overlay:** Mirrors the non-instanced path — it
 *       emits individual `CellMesh` components for the (<=5) cells
 *       of the selected region, each wrapped in a scaled `<group>`,
 *       so the emissive glow still tracks the cell's conformal size.
 *
 *   Bonds and boundary overlays are NOT scaled here.  Bonds connect
 *   fixed cell centres and should retain uniform thickness; the
 *   boundary wireframe/shell will be updated in their own roadmap
 *   items to apply the per-cell scale to their template edges.
 *
 * **What changed and why (historical — Phase 1):**
 *
 *   The previous implementation rendered only cells extracted from
 *   singleton (size-1) boundary regions and inferred adjacency from
 *   size-2 boundary regions.  This caused two critical visual bugs:
 *
 *   1. **Missing interior cells:** Cells with ALL faces shared
 *      (0 boundary legs) appeared in zero regions and were invisible.
 *      For the star patch, the central cell C had 5 bonds but 0
 *      boundary legs → invisible → the star looked like a circle
 *      (5 nodes in a ring with small indentations).
 *
 *   2. **Missing bonds:** Size-2 regions represent boundary adjacency
 *      (two boundary cells forming a connected subset), NOT physical
 *      bonds.  Interior-to-boundary and interior-to-interior bonds
 *      were entirely absent, causing the "galaxy" / "universe"
 *      appearance of fragmented, locally-connected dots.
 *
 *   Now the component reads from `patchGraph`:
 *     - `pgNodes` → ALL cell IDs (boundary + interior)
 *     - `pgEdges` → ALL physical bonds (shared faces/edges)
 *
 *   Interior cells are rendered with a neutral gray color at slightly
 *   lower opacity, serving as structural context.  Boundary cells
 *   retain full data-driven coloring from the active color mode.
 *
 * This is the primary 3D visualization component for the Patch Viewer
 * page (`/patches/:name`). It receives a full `Patch` object and the
 * current visualization state (color mode, selected region, visibility
 * toggles) from the parent `PatchView`, and renders an interactive
 * Three.js scene with:
 *
 *   - **Cell meshes**: One per cell (boundary + interior), colored
 *     by the active color mode (boundary) or neutral gray (interior).
 *     Selected cells receive an emissive orange glow.  Each cell is
 *     uniformly scaled by its conformal factor `s(u) = (1 − |u|²)/2`.
 *
 *   - **Bond connectors**: Translucent gray cylinders along ALL
 *     physical bonds from `patchGraph.pgEdges` (toggle-able via
 *     `showBonds`).  Thickness is uniform (not scaled per cell).
 *
 *   - **Boundary wireframe**: Edge outlines around boundary cells
 *     only (toggle-able via `showBoundary`).
 *
 *   - **Boundary shell**: Semi-transparent convex hull or fitted
 *     sphere around boundary cell positions (toggle-able via
 *     `showShell`).  Visualizes the holographic boundary surface.
 *
 *   - **Lighting**: Ambient light (intensity 0.5) + directional light
 *     from `[10, 10, 10]` (frontend-spec §4.3).
 *
 *   - **Controls**: OrbitControls with damping for smooth interaction.
 *
 * **Performance strategy** (frontend-spec §6.3):
 *   - Patches with ≤500 total cells: individual `<CellMesh>` components
 *     wrapped in scaled `<group>`s, with full emissive selection glow.
 *   - Patches with >500 total cells: `InstancedMesh` with per-instance
 *     colors AND per-instance scales for O(1) draw calls. Selected
 *     cells (max 5) are rendered as additional individual meshes for
 *     emissive glow.
 *
 * **Cell positions + scales** are computed client-side by
 * `utils/layout.ts`, which reads the Poincaré-projected coordinates
 * and conformal scales directly from the exported bulk graph (or
 * falls back to a force-directed layout with `scale = 1.0` when no
 * geometric data is available).
 *
 * **Adjacency** is read directly from `patchGraph.pgEdges` — the true
 * physical bonds (shared cube faces in 3D, shared pentagon edges in 2D).
 *
 * @see PatchView — The parent page component managing visualization state.
 * @see CellMesh — Individual cell geometry with selection glow.
 * @see BondConnector — Translucent cylinder between adjacent cells.
 * @see BoundaryWireframe — Edge outlines for boundary cells.
 * @see BoundaryShell — Semi-transparent convex hull around boundary cells.
 * @see ColorControls — UI for selecting the active color mode.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4.3 (3D Viewport)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Scene Structure)
 *   - docs/engineering/frontend-spec-webgl.md §6 (Rendering Details)
 *   - docs/engineering/frontend-spec-webgl.md §9 (Layout Algorithm)
 *   - docs Roadmap "Centre Patches in Poincaré Projection" §§1–3
 */

import { useMemo, useCallback, useRef, useEffect } from "react";
import { Canvas } from "@react-three/fiber";
import { OrbitControls } from "@react-three/drei";
import {
  Object3D,
  Color,
  InstancedMesh as ThreeInstancedMesh,
} from "three";
import type { ThreeEvent } from "@react-three/fiber";

import { CellMesh } from "./CellMesh";
import { BondConnector } from "./BondConnector";
import { BoundaryWireframe } from "./BoundaryWireframe";
import { BoundaryShell } from "./BoundaryShell";
import {
  computePatchLayout,
  extractGraphBonds,
} from "../../utils/layout";
import type { NodeTransform } from "../../utils/layout";
import { colorForRegion } from "../../utils/colors";
import type { ColorContext } from "../../utils/colors";
import { getCellGeometry, shouldUseInstancing } from "../../utils/tiling";
import type { Patch, Region, ColorMode, Tiling } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/** Default field of view for the perspective camera (degrees). */
const CAMERA_FOV = 60;

/** Ambient light intensity (frontend-spec §4.3). */
const AMBIENT_INTENSITY = 0.5;

/** Directional light position (frontend-spec §4.3). */
const DIRECTIONAL_POSITION: [number, number, number] = [10, 10, 10];

/** Directional light intensity. */
const DIRECTIONAL_INTENSITY = 1;

/** OrbitControls damping factor for smooth deceleration. */
const DAMPING_FACTOR = 0.1;

/**
 * Selection highlight color for instanced cells.
 *
 * When using InstancedMesh (>500 cells), selected cells receive this
 * orange color instead of an emissive glow. Orange (#ffaa00) matches
 * the CellMesh emissive color (frontend-spec §4.3).
 */
const INSTANCED_SELECTION_COLOR = new Color(0xffaa00);

/**
 * InstancedMesh material base metalness (matches CellMesh).
 */
const MATERIAL_METALNESS = 0.1;

/**
 * InstancedMesh material base roughness (matches CellMesh).
 */
const MATERIAL_ROUGHNESS = 0.7;

/**
 * InstancedMesh material opacity for unselected cells.
 */
const MATERIAL_OPACITY = 0.85;

/**
 * Neutral color for interior cells (cells with no boundary legs).
 *
 * Interior cells appear in no boundary region, so they carry no
 * data-driven color.  This neutral gray–blue provides structural
 * context (showing the bulk graph topology) without competing
 * visually with the data-colored boundary cells.
 *
 * Tailwind gray-500 (#6b7280) — a well-established neutral in
 * the design system that reads as "structural, not data" against
 * both the dark viewport background and the Viridis palette.
 */
const INTERIOR_CELL_COLOR = "#6b7280";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link PatchScene} component. */
export interface PatchSceneProps {
  /** The full patch data from `GET /patches/:name`. */
  patch: Patch;

  /** The currently active cell color mode. */
  colorMode: ColorMode;

  /**
   * The currently selected boundary region, or `null` if no region
   * is selected. Cells belonging to this region receive selection
   * highlighting (emissive glow or color override).
   */
  selectedRegion: Region | null;

  /**
   * Callback invoked when the user clicks a cell in the 3D viewport.
   * The parent component (PatchView) uses this to update the selected
   * region in the RegionInspector.
   *
   * For boundary cells, PatchView resolves the cell ID to its
   * singleton region.  For interior cells, PatchView receives a cell
   * ID with no corresponding region and sets selection to null
   * (deselecting).
   *
   * @param cellId - The ID of the clicked cell.
   */
  onCellClick: (cellId: number) => void;

  /** Whether to show internal bond connectors. */
  showBonds: boolean;

  /** Whether to show the boundary wireframe overlay. */
  showBoundary: boolean;

  /**
   * Whether to show the semi-transparent boundary shell (convex hull
   * or fitted sphere around boundary cell positions).
   *
   * The shell visualizes the holographic boundary surface — "the 2D
   * boundary encodes the 3D bulk."  It is toggled via the "Boundary
   * shell" checkbox in ColorControls.
   */
  showShell: boolean;

  /**
   * Optional callback invoked when the user clicks the scene background
   * (not on any cell). Typically used by PatchView to deselect the
   * current region.
   */
  onBackgroundClick?: () => void;
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * Three.js Canvas rendering a holographic patch with interactive
 * OrbitControls, cell meshes, bond connectors, boundary wireframe,
 * and boundary shell.
 *
 * All expensive computations (layout, bonds, color mapping) are
 * memoized on the patch data and visualization state. The
 * force-directed layout (fallback path only) is cached in
 * `sessionStorage` across page revisits.
 *
 * @example
 * ```tsx
 * <PatchScene
 *   patch={patchData}
 *   colorMode="mincut"
 *   selectedRegion={selected}
 *   onCellClick={(id) => selectRegionForCell(id)}
 *   showBonds={true}
 *   showBoundary={false}
 *   showShell={false}
 *   onBackgroundClick={() => setSelected(null)}
 * />
 * ```
 */
export function PatchScene({
  patch,
  colorMode,
  selectedRegion,
  onCellClick,
  showBonds,
  showBoundary,
  showShell,
  onBackgroundClick,
}: PatchSceneProps) {
  // ── 1. Compute per-cell transforms (position + conformal scale) ─
  //
  // computePatchLayout reads Poincaré-projected coordinates from
  // patchGraph.pgNodes (ALL cells) together with the per-cell
  // conformal scale factor s(u) = (1 − |u|²) / 2 that the Python
  // oracle attaches to every node.  The result is deterministic for
  // a given patch (and cached in sessionStorage on the force-layout
  // fallback path).
  //
  // Each entry is a NodeTransform { pos: [x,y,z], scale: number }.
  const transforms: Map<number, NodeTransform> = useMemo(
    () => computePatchLayout(patch),
    [patch],
  );

  // ── 2. ALL cell IDs from the bulk graph ───────────────────────
  //
  // pgNodes is GraphNode[] (objects with {id, x, y, z, ...}).
  // Extract the numeric IDs so downstream code operates on number[].
  //
  // This includes both boundary cells (those appearing in at least
  // one region's regionCells) and interior cells (those with all
  // faces shared, appearing in no region).
  const allCellIds = useMemo(
    () => patch.patchGraph.pgNodes.map(n => n.id),
    [patch.patchGraph.pgNodes],
  );

  // ── 3. Extract ALL physical bonds from the bulk graph ─────────
  //
  // Uses patchGraph.pgEdges — the TRUE physical bonds (shared cube
  // faces in 3D, shared pentagon edges in 2D, tree edges for Tree).
  // This replaces the old approach of inferring bonds from size-2
  // boundary regions, which missed interior-to-boundary and
  // interior-to-interior bonds entirely.
  const bonds = useMemo(
    () => extractGraphBonds(patch),
    [patch],
  );

  // ── 4. Boundary cell set ──────────────────────────────────────
  //
  // The set of cell IDs that appear in at least one boundary region.
  // These are "boundary cells" — cells with ≥1 exposed face/leg.
  // Interior cells (all faces shared) are NOT in this set.
  //
  // Used to distinguish boundary cells (data-driven colors) from
  // interior cells (neutral gray) in the color function.
  const boundaryCellSet = useMemo(() => {
    const set = new Set<number>();
    for (const r of patch.patchRegionData) {
      for (const cellId of r.regionCells) {
        set.add(cellId);
      }
    }
    return set;
  }, [patch.patchRegionData]);

  // ── 5. Get singleton regions (one per boundary cell) ──────────
  //
  // Each boundary cell has exactly one singleton (size-1) region in
  // the data. These carry the per-cell min-cut, area, ratio, and
  // curvature values used for data-driven coloring.
  //
  // Interior cells have no singleton region and receive neutral
  // coloring instead.
  const singletonRegions = useMemo(
    () =>
      patch.patchRegionData.filter(
        (r) => r.regionSize === 1 && r.regionCells.length === 1,
      ),
    [patch.patchRegionData],
  );

  // ── 6. Build cellId → singleton Region mapping ────────────────
  //
  // Used for color computation and click handling. Each boundary
  // cell maps to its singleton region's min-cut, area, ratio, etc.
  // Interior cells are absent from this map.
  const cellToSingletonRegion = useMemo(() => {
    const map = new Map<number, Region>();
    for (const r of singletonRegions) {
      const cellId = r.regionCells[0];
      if (cellId !== undefined) {
        map.set(cellId, r);
      }
    }
    return map;
  }, [singletonRegions]);

  // ── 7. Build cellId → max region size ─────────────────────────
  //
  // For the "Region size" color mode: color each boundary cell by
  // the size of the largest region it participates in. Interior
  // cells are not in any region and get neutral color before this
  // map is consulted.
  const cellMaxRegionSize = useMemo(() => {
    const map = new Map<number, number>();
    for (const r of patch.patchRegionData) {
      for (const cellId of r.regionCells) {
        const current = map.get(cellId) ?? 0;
        map.set(cellId, Math.max(current, r.regionSize));
      }
    }
    return map;
  }, [patch.patchRegionData]);

  // ── 8. Build color context with domain bounds ─────────────────
  //
  // Domain bounds are derived from boundary region data only (since
  // interior cells carry no data-driven values).
  const colorCtx = useMemo<ColorContext>(() => {
    let maxRegionSize = 1;
    for (const r of patch.patchRegionData) {
      maxRegionSize = Math.max(maxRegionSize, r.regionSize);
    }

    let minKappa = 0;
    let maxKappa = 0;
    for (const r of patch.patchRegionData) {
      if (r.regionCurvature !== null) {
        minKappa = Math.min(minKappa, r.regionCurvature);
        maxKappa = Math.max(maxKappa, r.regionCurvature);
      }
    }

    return {
      maxCut: patch.patchMaxCut,
      maxRegionSize,
      minKappa,
      maxKappa,
    };
  }, [patch]);

  // ── 9. Build selected cell set ────────────────────────────────
  const selectedCellSet = useMemo(() => {
    if (!selectedRegion) return new Set<number>();
    return new Set(selectedRegion.regionCells);
  }, [selectedRegion]);

  // ── 10. Compute camera distance from bounding box ─────────────
  //
  // Auto-frame the layout so all cells fit in the initial view.
  // Now includes interior cells, which may extend the bounding box
  // beyond what boundary-only cells would produce.
  //
  // The bounding box is computed from transform.pos (the scene-
  // space position), NOT the per-cell scale — cells themselves are
  // small relative to the patch extent so their scale does not
  // meaningfully affect framing.
  const cameraZ = useMemo(() => {
    let maxExtent = 1;
    for (const [, transform] of transforms) {
      const [x, y, z] = transform.pos;
      maxExtent = Math.max(
        maxExtent,
        Math.abs(x),
        Math.abs(y),
        Math.abs(z),
      );
    }
    const halfAngle = (CAMERA_FOV / 2) * (Math.PI / 180);
    return Math.max(5, (maxExtent * 1.8) / Math.tan(halfAngle));
  }, [transforms]);

  // ── 11. Determine if instancing is needed ─────────────────────
  //
  // Now based on TOTAL cell count (boundary + interior), not just
  // boundary cells. Dense-1000 has 1000 cells → instancing.
  const useInstancing = shouldUseInstancing(allCellIds.length);

  // ── 12. Cell color computation function ───────────────────────
  //
  // Interior cells: neutral gray (INTERIOR_CELL_COLOR).
  // Boundary cells: data-driven color from the active color mode.
  const getCellColor = useCallback(
    (cellId: number): string => {
      // Interior cells get a neutral color — they carry no
      // boundary-region data (no min-cut, area, ratio, or
      // per-region curvature).
      if (!boundaryCellSet.has(cellId)) {
        return INTERIOR_CELL_COLOR;
      }

      const region = cellToSingletonRegion.get(cellId);
      if (!region) return INTERIOR_CELL_COLOR;

      const sizeForColor =
        cellMaxRegionSize.get(cellId) ?? region.regionSize;

      return colorForRegion(
        colorMode,
        region.regionMinCut,
        sizeForColor,
        region.regionRatio,
        region.regionCurvature ?? 0,
        colorCtx,
      );
    },
    [colorMode, cellToSingletonRegion, cellMaxRegionSize, colorCtx, boundaryCellSet],
  );

  // ── 13. Boundary cell list for wireframe overlay + shell ──────
  //
  // Only boundary cells get wireframe outlines and are included in
  // the shell computation — interior cells are part of the bulk and
  // should not have boundary indicators.
  //
  // The per-cell scale is NOT passed here: BoundaryWireframe and
  // BoundaryShell have their own roadmap items to integrate the
  // conformal scale into their template-edge rendering.  For now
  // they render at unit scale, so a small wireframe/shell vs.
  // scaled-cell mismatch will exist until those items land.
  const boundaryCellList = useMemo(() => {
    const list: Array<{
      cellId: number;
      position: [number, number, number];
    }> = [];
    for (const cellId of allCellIds) {
      if (!boundaryCellSet.has(cellId)) continue;
      const transform = transforms.get(cellId);
      if (!transform) continue;
      list.push({ cellId, position: transform.pos });
    }
    return list;
  }, [allCellIds, boundaryCellSet, transforms]);

  // ── 14. Handle background click (deselect region) ─────────────
  const handlePointerMissed = useCallback(() => {
    onBackgroundClick?.();
  }, [onBackgroundClick]);

  // ── 15. Accessible description ────────────────────────────────
  const interiorCount = allCellIds.length - boundaryCellSet.size;
  const ariaLabel = [
    `3D visualization of patch ${patch.patchName}:`,
    `${patch.patchCells} cells`,
    interiorCount > 0
      ? `(${boundaryCellSet.size} boundary, ${interiorCount} interior),`
      : `(all boundary),`,
    `${bonds.length} physical bonds,`,
    `${patch.patchRegions} regions,`,
    `max min-cut S=${patch.patchMaxCut},`,
    `tiling ${patch.patchTiling}.`,
    selectedRegion
      ? `Region ${selectedRegion.regionId} selected (S=${selectedRegion.regionMinCut}, area=${selectedRegion.regionArea}).`
      : "No region selected. Click a cell to inspect.",
  ].join(" ");

  // ── Render ────────────────────────────────────────────────────
  return (
    <div
      className="canvas-container w-full h-full min-h-[300px]"
      role="img"
      aria-label={ariaLabel}
    >
      <Canvas
        camera={{
          position: [0, 0, cameraZ],
          fov: CAMERA_FOV,
          near: 0.1,
          far: cameraZ * 10,
        }}
        onPointerMissed={handlePointerMissed}
      >
        {/* ── Lighting ─────────────────────────────────────── */}
        <ambientLight intensity={AMBIENT_INTENSITY} />
        <directionalLight
          position={DIRECTIONAL_POSITION}
          intensity={DIRECTIONAL_INTENSITY}
        />

        {/* ── Controls ─────────────────────────────────────── */}
        <OrbitControls
          enableDamping
          dampingFactor={DAMPING_FACTOR}
        />

        {/* ── Cells (ALL — boundary + interior) ────────────── */}
        {useInstancing ? (
          <>
            <InstancedCells
              cellIds={allCellIds}
              transforms={transforms}
              getCellColor={getCellColor}
              selectedCellSet={selectedCellSet}
              tiling={patch.patchTiling}
              onCellClick={onCellClick}
            />
            {/* Selection overlay: individual meshes with emissive glow
                for the selected cells (max 5). Rendered on top of the
                InstancedMesh to provide the orange emissive highlight
                that InstancedMesh cannot support per-instance. */}
            <SelectionOverlay
              selectedRegion={selectedRegion}
              transforms={transforms}
              tiling={patch.patchTiling}
              getCellColor={getCellColor}
              onCellClick={onCellClick}
            />
          </>
        ) : (
          <group name="cells">
            {allCellIds.map((cellId) => {
              const transform = transforms.get(cellId);
              if (!transform) return null;
              // Wrap each CellMesh in a <group> carrying the cell's
              // world position, per-cell conformal scale AND rotation
              // quaternion (Fix C — roadmap Step 3).  CellMesh renders
              // at the group's local origin, so the group's transform
              // uniformly places, rotates and scales the cell geometry
              // without touching CellMesh's prop surface.  This keeps
              // the scale-integration for CellMesh as a separate
              // roadmap item.
              return (
                <group
                  key={cellId}
                  position={transform.pos}
                  scale={transform.scale}
                  quaternion={transform.quat}
                >
                  <CellMesh
                    position={[0, 0, 0]}
                    color={getCellColor(cellId)}
                    selected={selectedCellSet.has(cellId)}
                    tiling={patch.patchTiling}
                    onClick={() => onCellClick(cellId)}
                    cellId={cellId}
                  />
                </group>
              );
            })}
          </group>
        )}

        {/* ── Bond Connectors (ALL physical bonds) ─────────── */}
        {/* Bonds connect fixed cell centres — their endpoints come
            directly from transform.pos (no per-cell scale applied).
            Bond thickness is uniform across the patch. */}
        {showBonds && (
          <group name="bonds">
            {bonds.map(([c1, c2]) => {
              const t1 = transforms.get(c1);
              const t2 = transforms.get(c2);
              if (!t1 || !t2) return null;
              return (
                <BondConnector
                  key={`b-${c1}-${c2}`}
                  from={t1.pos}
                  to={t2.pos}
                />
              );
            })}
          </group>
        )}

        {/* ── Boundary Wireframe (boundary cells only) ─────── */}
        {showBoundary && (
          <BoundaryWireframe
            cells={boundaryCellList}
            tiling={patch.patchTiling}
          />
        )}

        {/* ── Boundary Shell (semi-transparent envelope) ───── */}
        {showShell && (
          <BoundaryShell
            cells={boundaryCellList}
            tiling={patch.patchTiling}
          />
        )}
      </Canvas>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  InstancedCells — Internal component for >500 total cells
// ════════════════════════════════════════════════════════════════

/**
 * Props for the internal {@link InstancedCells} component.
 */
interface InstancedCellsProps {
  /** ALL cell IDs to render (boundary + interior). */
  cellIds: number[];
  /** Cell ID → NodeTransform (pos + conformal scale) from the layout. */
  transforms: Map<number, NodeTransform>;
  /** Function returning the CSS hex color for a cell. */
  getCellColor: (cellId: number) => string;
  /** Set of cell IDs belonging to the selected region. */
  selectedCellSet: Set<number>;
  /** Tiling type — determines the cell geometry shape. */
  tiling: Tiling;
  /** Callback when a cell instance is clicked. */
  onCellClick: (cellId: number) => void;
}

/**
 * Renders all cells (boundary + interior) as a single `InstancedMesh`
 * for optimal draw-call performance on large patches (>500 cells).
 *
 * Per-instance transforms include BOTH position and uniform scale:
 *
 *   dummy.position.set(...transform.pos);
 *   dummy.scale.setScalar(transform.scale);
 *   dummy.updateMatrix();
 *   mesh.setMatrixAt(i, dummy.matrix);
 *
 * This gives every cell its correct conformal size (cells near the
 * centre of the Poincaré ball ≈ 0.5× template, cells near the
 * boundary → 0) while keeping the entire patch in a single draw
 * call.
 *
 * Per-instance colors are set via `InstancedMesh.setColorAt()`.
 * Interior cells receive the neutral INTERIOR_CELL_COLOR.
 * Selected cells receive the orange selection color instead of
 * their data-driven color. Emissive glow is not supported per-instance
 * with the standard material; the parent renders a separate
 * `SelectionOverlay` for the selected cells' emissive highlight.
 *
 * Cursor cleanup (review issue #4):
 *   If the InstancedMesh is removed from the scene while the pointer
 *   is over it, `onPointerOut` never fires and the cursor stays stuck
 *   on "pointer". A `useEffect` cleanup resets the cursor on unmount.
 */
function InstancedCells({
  cellIds,
  transforms,
  getCellColor,
  selectedCellSet,
  tiling,
  onCellClick,
}: InstancedCellsProps) {
  const meshRef = useRef<ThreeInstancedMesh>(null);
  const geometry = useMemo(() => getCellGeometry(tiling), [tiling]);

  // Ordered list of cell IDs matching instance indices.
  // Only includes cells with valid transforms.
  const cellOrder = useMemo(() => {
    const order: number[] = [];
    for (const cellId of cellIds) {
      if (transforms.has(cellId)) {
        order.push(cellId);
      }
    }
    return order;
  }, [cellIds, transforms]);

  const count = cellOrder.length;

  // ── Cursor cleanup on unmount (review issue #4) ───────────────
  useEffect(() => {
    return () => {
      document.body.style.cursor = "auto";
    };
  }, []);

  // ── Update instance transforms (position + rotation + scale) ──
  //
  // Roadmap Step 2 + Fix C: each instance's local matrix encodes
  // the cell's scene position, its per-cell rotation quaternion
  // (fixing the layer-54-dX "squished on one side" artefact),
  // AND its conformal scale factor.  The dummy Object3D is reused
  // across instances to avoid allocation.
  useEffect(() => {
    const mesh = meshRef.current;
    if (!mesh || count === 0) return;

    const dummy = new Object3D();

    for (let i = 0; i < count; i++) {
      const cellId = cellOrder[i];
      if (cellId === undefined) continue;
      const transform = transforms.get(cellId);
      if (!transform) continue;

      dummy.position.set(
        transform.pos[0],
        transform.pos[1],
        transform.pos[2],
      );
      dummy.quaternion.set(
        transform.quat[0],
        transform.quat[1],
        transform.quat[2],
        transform.quat[3],
      );
      dummy.scale.setScalar(transform.scale);
      dummy.updateMatrix();
      mesh.setMatrixAt(i, dummy.matrix);
    }

    mesh.instanceMatrix.needsUpdate = true;
  }, [cellOrder, transforms, count]);

  // ── Update instance colors ────────────────────────────────────
  useEffect(() => {
    const mesh = meshRef.current;
    if (!mesh || count === 0) return;

    const tempColor = new Color();

    for (let i = 0; i < count; i++) {
      const cellId = cellOrder[i];
      if (cellId === undefined) continue;

      if (selectedCellSet.has(cellId)) {
        mesh.setColorAt(i, INSTANCED_SELECTION_COLOR);
      } else {
        tempColor.set(getCellColor(cellId));
        mesh.setColorAt(i, tempColor);
      }
    }

    if (mesh.instanceColor) {
      mesh.instanceColor.needsUpdate = true;
    }
  }, [cellOrder, getCellColor, selectedCellSet, count]);

  // ── Click handler for instance picking ────────────────────────
  const handleClick = useCallback(
    (e: ThreeEvent<MouseEvent>) => {
      e.stopPropagation();
      if (e.instanceId !== undefined && e.instanceId < count) {
        const cellId = cellOrder[e.instanceId];
        if (cellId !== undefined) {
          onCellClick(cellId);
        }
      }
    },
    [cellOrder, count, onCellClick],
  );

  // ── Pointer cursor feedback ───────────────────────────────────
  const handlePointerOver = useCallback(
    (e: ThreeEvent<PointerEvent>) => {
      e.stopPropagation();
      document.body.style.cursor = "pointer";
    },
    [],
  );

  const handlePointerOut = useCallback(
    (e: ThreeEvent<PointerEvent>) => {
      e.stopPropagation();
      document.body.style.cursor = "auto";
    },
    [],
  );

  if (count === 0) return null;

  return (
    <instancedMesh
      ref={meshRef}
      args={[geometry, undefined, count]}
      onClick={handleClick}
      onPointerOver={handlePointerOver}
      onPointerOut={handlePointerOut}
    >
      <meshStandardMaterial
        metalness={MATERIAL_METALNESS}
        roughness={MATERIAL_ROUGHNESS}
        transparent
        opacity={MATERIAL_OPACITY}
        depthWrite={false}
      />
    </instancedMesh>
  );
}

// ════════════════════════════════════════════════════════════════
//  SelectionOverlay — Emissive glow for selected cells (instanced path)
// ════════════════════════════════════════════════════════════════

/**
 * Props for the internal {@link SelectionOverlay} component.
 */
interface SelectionOverlayProps {
  /** The currently selected region, or `null` if none. */
  selectedRegion: Region | null;
  /** Cell ID → NodeTransform (pos + conformal scale) from the layout. */
  transforms: Map<number, NodeTransform>;
  /** Tiling type — determines the cell geometry shape. */
  tiling: Tiling;
  /** Function returning the CSS hex color for a cell. */
  getCellColor: (cellId: number) => string;
  /** Callback when a cell is clicked. */
  onCellClick: (cellId: number) => void;
}

/**
 * Renders individual CellMesh components for the selected region's
 * cells, providing the orange emissive glow that InstancedMesh
 * cannot support per-instance.
 *
 * This overlay is only used in the instanced rendering path (>500
 * cells). For the non-instanced path (≤500 cells), CellMesh
 * components handle their own selection highlighting directly.
 *
 * Selected region cells are always boundary cells (regions only
 * contain boundary cells), so they always have valid transforms.
 *
 * Each overlay cell is wrapped in a `<group>` carrying its world
 * position AND conformal scale — matching the non-instanced path so
 * the glow tracks the cell's actual on-screen size near the Poincaré
 * boundary.
 * 
 * Per Fix C, the group now also carries the per-cell rotation
 * quaternion so the emissive highlight aligns with the cell's
 * actual boosted orientation on asymmetric (layer-54-dX) patches.
 *
 * At most 5 cells are rendered (the maximum region size in the
 * oracle data is 5–6 cells), so this adds at most 6 draw calls.
 */
function SelectionOverlay({
  selectedRegion,
  transforms,
  tiling,
  getCellColor,
  onCellClick,
}: SelectionOverlayProps) {
  if (!selectedRegion) return null;

  return (
    <group name="selection-overlay">
      {selectedRegion.regionCells.map((cellId) => {
        const transform = transforms.get(cellId);
        if (!transform) return null;
        return (
          <group
            key={`sel-${cellId}`}
            position={transform.pos}
            scale={transform.scale}
            quaternion={transform.quat}
          >
            <CellMesh
              position={[0, 0, 0]}
              color={getCellColor(cellId)}
              selected={true}
              tiling={tiling}
              onClick={() => onCellClick(cellId)}
              cellId={cellId}
            />
          </group>
        );
      })}
    </group>
  );
}