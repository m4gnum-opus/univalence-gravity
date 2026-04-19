// src/components/patches/BoundaryWireframe.tsx
/**
 * BoundaryWireframe — Wireframe outline of exposed boundary faces.
 *
 * Renders thin wireframe outlines around all **boundary** cells in the
 * patch, providing a visual cue that distinguishes boundary cells
 * (with exposed faces/legs) from fully interior cells (all faces
 * shared, appearing in no boundary region). This overlay is toggled
 * by the "Boundary wireframe" checkbox in {@link ColorControls}.
 *
 * **Boundary cell definition (Phase 1, item 11):**
 *
 *   A cell is a "boundary cell" if and only if it appears in at least
 *   one boundary region's `regionCells` array. Equivalently, it has
 *   at least one exposed face/leg (not shared with another cell in
 *   the patch). Interior cells — those with ALL faces shared, appearing
 *   in zero regions — are excluded from the wireframe.
 *
 *   The parent component (PatchScene) computes the boundary cell set
 *   as the union of all `regionCells` across all regions, then filters
 *   the full cell list (`patchGraph.pgNodes`) to produce the `cells`
 *   prop passed to this component. This means:
 *
 *     - Star patch (6 cells): C is interior (0 boundary legs, appears
 *       in no region) → no wireframe. N0–N4 are boundary → wireframed.
 *     - Dense-100 (100 cells): ~86 boundary cells → wireframed.
 *       ~14 interior cells → no wireframe.
 *     - Dense-1000 (1000 cells): ~833 boundary cells → wireframed.
 *       ~167 interior cells → no wireframe.
 *
 *   This correctly visualises the holographic principle: the wireframe
 *   is the 2D boundary surface encoding the 3D bulk.
 *
 * **Per-cell conformal scale (roadmap Step 2 — BoundaryWireframe):**
 *
 *   The `cells` prop now carries an optional `scale` per cell,
 *   corresponding to the Poincaré conformal factor
 *   `s(u) = (1 − |u|²) / 2` at the cell's projected position.
 *   The merge loop multiplies every template vertex by the cell's
 *   scale BEFORE translating, so the wireframe outline of each
 *   boundary cell exactly matches the size of the scaled
 *   `CellMesh` / `InstancedMesh` it encloses.
 *
 *   Without this rescaling, cells near the Poincaré boundary
 *   shrink (via the per-cell scale applied in PatchScene) while
 *   their wireframe outlines stayed at the unscaled template size,
 *   producing a visible "floating cage" around small cells. The
 *   fix brings the wireframe in line with the roadmap's
 *   "Centre Patches in Poincaré Projection" centring and per-cell
 *   scaling.
 *
 *   For backward compatibility with any caller that has not yet
 *   been updated to thread the scale through, the field is
 *   optional and defaults to `1` — which reproduces the previous
 *   unscaled behaviour exactly.
 *
 * **Implementation approach:**
 *
 *   Three.js `EdgesGeometry` extracts the hard edges of the cell
 *   geometry (only edges shared by faces whose normals differ by
 *   more than a threshold angle — defaulting to 1° — are included).
 *   This produces clean outlines of pentagons, cubes, and squares
 *   without the internal diagonal lines that `wireframe: true` on
 *   a MeshBasicMaterial would produce.
 *
 *   All boundary cells' edge segments are **merged into a single
 *   BufferGeometry** by scaling the template edge vertices by each
 *   cell's conformal factor, translating them by the cell's layout
 *   position, and concatenating everything into one Float32Array.
 *   This produces exactly **1 draw call** regardless of boundary
 *   cell count — critical for large patches like layer-54-d7 (1885
 *   boundary cells) and dense-1000 (833+ boundary cells).
 *
 *   The template EdgesGeometry is shared across all cells of the
 *   same tiling type via a module-level cache (at most 5 entries,
 *   one per Tiling variant).
 *
 * **Visual properties (academic aesthetic, frontend-spec §4.1):**
 *
 *   - Color: #93c5fd (Tailwind blue-300) — a calm, non-competing
 *     blue that contrasts with the Viridis data colors without
 *     visually dominating the scene. Boundary outlines should be
 *     structural context, not the focus.
 *   - Opacity: 0.6 — slightly translucent to avoid hard visual
 *     edges occluding cell data colors.
 *   - depthTest: true — outlines respect scene depth so they don't
 *     appear on top of cells that are closer to the camera.
 *
 * **Performance:**
 *
 *   All boundary cells are batched into a single `<lineSegments>`
 *   draw call via a merged BufferGeometry. The merge runs once
 *   per cell-list/tiling change (i.e. on patch navigation) inside
 *   a `useMemo`. For the largest patch (dense-1000 with 833+
 *   boundary cells), this produces 1 draw call instead of 833+.
 *   For layer-54-d7 (1885 boundary cells), 1 instead of 1885.
 *
 * @see CellMesh — The solid cell geometry that this wireframe overlays
 * @see ColorControls — The UI toggle controlling this overlay's visibility
 * @see PatchScene — The parent component managing all 3D elements and
 *   computing the boundary cell set from `patchGraph.pgNodes` filtered
 *   against the union of all `regionCells`.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Scene Structure)
 *   - docs/engineering/frontend-spec-webgl.md §6.1 (Cell Geometry)
 *   - docs Roadmap "Centre Patches in Poincaré Projection" §2
 *     (per-cell conformal scale)
 */

import { useMemo, useEffect, useRef } from "react";
import {
  EdgesGeometry,
  BufferGeometry,
  Float32BufferAttribute,
} from "three";
import type { BufferGeometry as BufferGeometryType } from "three";

import type { Tiling } from "../../types";
import { getCellGeometry } from "../../utils/tiling";

// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/**
 * Wireframe outline color — a calm blue that contrasts with Viridis
 * data colors without competing visually.
 *
 * Tailwind blue-300 (#93c5fd) is used because:
 *   - It is clearly distinguishable from the Viridis palette range
 *     (deep purple → teal → green → yellow)
 *   - It is muted enough not to dominate the scene
 *   - It reads as "structural indicator" rather than "data value"
 *   - It evokes the holographic boundary / AdS boundary convention
 *     in physics visualisations (blue = boundary, warm = bulk)
 */
const WIREFRAME_COLOR = "#93c5fd";

/**
 * Wireframe outline opacity.
 *
 * 0.6 keeps the outlines visible as a structural overlay while
 * allowing the underlying cell colors to remain the visual focus.
 * Lower values (e.g. 0.3) would make the wireframe too faint on
 * light backgrounds; higher values (e.g. 1.0) would visually
 * compete with the data-colored cells.
 */
const WIREFRAME_OPACITY = 0.6;

/**
 * Threshold angle (in degrees) for EdgesGeometry edge extraction.
 *
 * EdgesGeometry includes only edges shared by faces whose normals
 * differ by more than this angle. A value of 1 effectively includes
 * all edges of the geometry (since adjacent faces of a pentagon,
 * cube, or square meet at angles well above 1°), giving clean
 * silhouette outlines of the cell shape.
 *
 * For extruded pentagons (used by {5,4} and {5,3}), this captures
 * both the pentagonal face edges and the extrusion side edges,
 * producing a complete wireframe outline.
 */
const EDGE_THRESHOLD_ANGLE = 1;

/**
 * Default per-cell scale when a caller has not supplied one.
 *
 * `1.0` reproduces the pre-roadmap rendering (unscaled template
 * edges translated to each cell's position).  Any caller that is
 * aware of the Poincaré conformal factor should pass the actual
 * `NodeTransform.scale` value from `layout.ts` instead; the
 * default here exists purely to keep older call sites compiling
 * while the roadmap rolls out.
 */
const DEFAULT_CELL_SCALE = 1;

// ════════════════════════════════════════════════════════════════
//  Edge geometry cache
// ════════════════════════════════════════════════════════════════

/**
 * Module-level cache of EdgesGeometry instances — one per tiling type.
 *
 * EdgesGeometry wraps an existing BufferGeometry and extracts just
 * the hard edges, producing a line-segment geometry suitable for
 * `<lineSegments>`. Since all cells of the same tiling share the
 * same base geometry, the extracted edges are identical — so we
 * cache and reuse the EdgesGeometry as a **template** for the
 * merged geometry construction.
 *
 * At most 5 entries exist (one per {@link Tiling} variant).
 * The cache persists for the lifetime of the module (the page).
 */
const edgesCache = new Map<Tiling, BufferGeometryType>();

/**
 * Base cell geometry cache — mirrors the cache in CellMesh.tsx.
 *
 * We maintain a separate cache here rather than importing from
 * CellMesh to avoid coupling between the two components and to
 * ensure the base geometry used for edge extraction stays alive
 * as long as the edges geometry needs it.
 */
const baseGeometryCache = new Map<Tiling, BufferGeometryType>();

/**
 * Retrieve the cached EdgesGeometry for a tiling type, creating
 * and caching it on first access.
 *
 * @param tiling - The tiling type determining the cell shape.
 * @returns A shared EdgesGeometry (BufferGeometry of line segments)
 *   for the given tiling — used as a template, NOT attached to any
 *   `<lineSegments>` directly.
 */
function getOrCreateEdgesGeometry(tiling: Tiling): BufferGeometryType {
  let edges = edgesCache.get(tiling);
  if (!edges) {
    // Get or create the base cell geometry
    let baseGeo = baseGeometryCache.get(tiling);
    if (!baseGeo) {
      baseGeo = getCellGeometry(tiling);
      baseGeometryCache.set(tiling, baseGeo);
    }

    // Extract edges from the base geometry
    edges = new EdgesGeometry(baseGeo, EDGE_THRESHOLD_ANGLE);
    edgesCache.set(tiling, edges);
  }
  return edges;
}

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/**
 * A single boundary cell entry accepted by {@link BoundaryWireframe}.
 *
 *   - **`cellId`** — the numeric cell identifier (used for debugging
 *     and memoization keys, not for rendering).
 *
 *   - **`position`** — the cell centre in scene coordinates, as
 *     produced by `computePatchLayout` from `utils/layout.ts`
 *     (specifically `NodeTransform.pos`).
 *
 *   - **`scale`** — OPTIONAL conformal scale factor
 *     `s(u) = (1 − |u|²) / 2` at the cell's Poincaré position.
 *     Template edge vertices are multiplied by this factor before
 *     being translated to `position`, so the wireframe size
 *     matches the scaled `CellMesh` / `InstancedMesh` enclosing it.
 *     Defaults to `1.0` when omitted, which reproduces the
 *     pre-roadmap unscaled rendering exactly — useful for any
 *     consumer that has not yet been migrated to the roadmap's
 *     per-cell-scale pipeline.
 */
export interface BoundaryWireframeCell {
  cellId: number;
  position: [number, number, number];
  scale?: number;
}

/** Props for the {@link BoundaryWireframe} component. */
export interface BoundaryWireframeProps {
  /**
   * Boundary cells paired with their 3D positions and conformal
   * scales.
   *
   * **Only boundary cells should be included.** A cell is
   * "boundary" if it appears in at least one region's `regionCells`
   * array (i.e. it has at least one exposed face/leg). Interior
   * cells — those with ALL faces shared, appearing in zero regions
   * — should be excluded by the parent component (PatchScene)
   * before passing this prop.
   *
   * The parent computes this from:
   *   1. `patchGraph.pgNodes` — ALL cell IDs (boundary + interior)
   *   2. `boundaryCellSet` — union of all `regionCells` across regions
   *   3. Filtering: only cells in `boundaryCellSet` are included
   *   4. For each included cell, the corresponding
   *      `NodeTransform` from `computePatchLayout` is consulted
   *      and its `pos` / `scale` are forwarded here.
   *
   * This prop is an array of objects rather than a Map to allow
   * React to perform efficient shallow comparisons on the array
   * reference for memoization. The parent component (PatchScene)
   * constructs this array once from the layout data and the
   * boundary cell set.
   */
  cells: BoundaryWireframeCell[];

  /**
   * Tiling type — determines the wireframe shape.
   * All cells in a patch share the same tiling type.
   */
  tiling: Tiling;
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Renders wireframe outlines around all boundary cells in the patch
 * as a **single merged draw call**.
 *
 * The template EdgesGeometry for the tiling type is scaled by each
 * cell's conformal factor, translated by each cell's layout
 * position, and all segments are concatenated into one
 * BufferGeometry. This produces exactly 1 `<lineSegments>`
 * element regardless of cell count, eliminating the N-draw-call
 * scaling problem, while still giving every outline the correct
 * Escher-style size matching the enclosed cell mesh.
 *
 * The merge runs inside a `useMemo` and recomputes only when the
 * `cells` array or `tiling` type changes — i.e. on patch navigation,
 * not on every frame or interaction.
 *
 * The component renders nothing when `cells` is empty, avoiding
 * unnecessary Three.js group creation. This naturally handles
 * patches where all cells are boundary cells (no interior cells)
 * as well as the degenerate case of an empty patch.
 *
 * **Holographic interpretation:** The wireframe visualises the 2D
 * boundary surface that, according to the holographic principle,
 * encodes the 3D bulk interior. Boundary cells carry boundary
 * entanglement entropy S(A); interior cells are part of the bulk
 * minimal surface. The wireframe makes this distinction visible.
 *
 * @example
 * ```tsx
 * // Inside a React Three Fiber <Canvas>:
 * {showBoundary && (
 *   <BoundaryWireframe
 *     cells={boundaryCellList}
 *     tiling={patch.patchTiling}
 *   />
 * )}
 * ```
 */
export function BoundaryWireframe({ cells, tiling }: BoundaryWireframeProps) {
  // Track the merged geometry for disposal on change/unmount.
  const prevGeoRef = useRef<BufferGeometryType | null>(null);

  // ── Build a single merged BufferGeometry from all cells ────────
  //
  // Strategy:
  //   1. Get the template EdgesGeometry for this tiling (cached).
  //   2. Read its position attribute (the edge-segment vertices
  //      in local/cell-centered coordinates).
  //   3. For each boundary cell:
  //        a. Multiply every template vertex by the cell's
  //           conformal scale factor (roadmap Step 2).
  //        b. Translate the scaled vertex by the cell's world
  //           position.
  //        c. Write the result into the merged Float32Array.
  //   4. Wrap in a new BufferGeometry with a single "position"
  //      attribute → 1 draw call.
  //
  // The merged geometry is recreated only when `cells` or `tiling`
  // changes (patch navigation). Within a single patch view, it is
  // computed once and reused for every frame.
  const mergedGeometry = useMemo(() => {
    if (cells.length === 0) return null;

    const templateGeo = getOrCreateEdgesGeometry(tiling);
    const templatePositions = templateGeo.getAttribute("position");
    if (!templatePositions) return null;

    const verticesPerCell = templatePositions.count;
    const totalVertices = verticesPerCell * cells.length;
    const merged = new Float32Array(totalVertices * 3);

    for (let cellIdx = 0; cellIdx < cells.length; cellIdx++) {
      const cell = cells[cellIdx];
      if (!cell) continue;

      const [ox, oy, oz] = cell.position;
      // Per-cell conformal scale — defaults to 1 for any caller
      // that has not yet been migrated to pass the scale through.
      // A non-finite or non-positive value falls back to the
      // default, keeping the wireframe visible in edge cases
      // (e.g. NaN / 0 at the Poincaré boundary before the exporter's
      // 1e-6 clamp kicks in).
      const rawScale = cell.scale;
      const s =
        typeof rawScale === "number" &&
        Number.isFinite(rawScale) &&
        rawScale > 0
          ? rawScale
          : DEFAULT_CELL_SCALE;

      const baseOffset = cellIdx * verticesPerCell * 3;

      for (let v = 0; v < verticesPerCell; v++) {
        const vi = baseOffset + v * 3;
        merged[vi]     = templatePositions.getX(v) * s + ox;
        merged[vi + 1] = templatePositions.getY(v) * s + oy;
        merged[vi + 2] = templatePositions.getZ(v) * s + oz;
      }
    }

    const geo = new BufferGeometry();
    geo.setAttribute("position", new Float32BufferAttribute(merged, 3));
    return geo;
  }, [cells, tiling]);

  // ── Dispose the previous merged geometry on change/unmount ─────
  //
  // Each merged geometry is a unique GPU buffer created per patch
  // navigation. We dispose the previous one when a new one is
  // created (patch change) or when the component unmounts (user
  // navigates away from the patch viewer).
  //
  // The template EdgesGeometry in the module-level cache is NOT
  // disposed — it persists for the module lifetime and is shared
  // across patch views of the same tiling type.
  useEffect(() => {
    // Dispose the previous geometry if it differs from the current.
    if (prevGeoRef.current && prevGeoRef.current !== mergedGeometry) {
      prevGeoRef.current.dispose();
    }
    prevGeoRef.current = mergedGeometry;

    // Cleanup on unmount: dispose the current geometry.
    return () => {
      if (prevGeoRef.current) {
        prevGeoRef.current.dispose();
        prevGeoRef.current = null;
      }
    };
  }, [mergedGeometry]);

  // Render nothing when there are no boundary cells to outline.
  if (!mergedGeometry) {
    return null;
  }

  return (
    <lineSegments geometry={mergedGeometry}>
      <lineBasicMaterial
        color={WIREFRAME_COLOR}
        transparent
        opacity={WIREFRAME_OPACITY}
        depthTest
      />
    </lineSegments>
  );
}