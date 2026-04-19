/**
 * CellMesh — Single cell geometry with material and selection glow.
 *
 * Renders a single holographic patch cell as a Three.js mesh inside
 * a React Three Fiber `<Canvas>`. The geometry shape is determined
 * by the tiling type (via `getCellGeometry` from `utils/tiling.ts`):
 *
 *   | Tiling   | Shape    | Three.js Geometry            |
 *   |----------|----------|------------------------------|
 *   | {4,3,5}  | Cube     | BoxGeometry(1, 1, 1)         |
 *   | {5,4}    | Pentagon | ExtrudeGeometry (pentagonal)  |
 *   | {5,3}    | Pentagon | Same as {5,4}                |
 *   | {4,4}    | Square   | PlaneGeometry(1, 1)          |
 *   | Tree     | Sphere   | SphereGeometry(0.4)          |
 *
 * **Phase 1, item 12 update:** CellMesh now distinguishes between
 * **boundary cells** and **interior cells** via the `isInterior` prop.
 *
 *   - **Boundary cells** (`isInterior=false`, the default): rendered
 *     with the data-driven color from the active color mode (min-cut,
 *     region size, S/area ratio, or curvature), standard opacity
 *     (0.85 unselected, 1.0 selected), and emissive orange glow when
 *     selected. These are the primary data-bearing visual elements.
 *
 *   - **Interior cells** (`isInterior=true`): rendered with a neutral
 *     color (passed via the `color` prop from PatchScene, typically
 *     gray #6b7280), lower opacity (0.45), no emissive glow, and no
 *     selection highlight. Interior cells serve as **structural context**
 *     — they show the bulk graph topology without competing visually
 *     with the data-colored boundary cells. They represent the "bulk"
 *     in the holographic principle: the 3D interior encoded by the 2D
 *     boundary.
 *
 * **Roadmap Step 2 — per-cell conformal scale (`scale` prop):**
 *
 *   CellMesh accepts an optional `scale` prop that is applied
 *   directly to the rendered `<mesh>`'s `scale` attribute as a
 *   uniform multiplier (`mesh.scale.setScalar(scale)` via the
 *   single-number R3F convention). This is the correct per-cell
 *   magnification for an Escher-style Poincaré rendering:
 *
 *     s(u) = (1 − |u|²) / 2
 *
 *   where `u = (x, y, z)` is the cell's position in the Poincaré
 *   ball. Cells near the origin render at `scale ≈ 0.5`, cells
 *   near the disk/ball boundary shrink toward zero. The exporter
 *   clamps the scale at `1e-6` so rendering never degenerates
 *   even for cells exponentially close to the boundary (e.g.
 *   layer-54-d7).
 *
 *   Defaults to `1` so the existing PatchScene usage — which
 *   passes `position={[0, 0, 0]}` and relies on a parent `<group>`
 *   to carry both position and scale — continues to work without
 *   modification. Callers wishing to place a single CellMesh at
 *   its scene-space position with its conformal scale can now
 *   pass both props directly:
 *
 *     <CellMesh
 *       position={transform.pos}
 *       scale={transform.scale}
 *       ...
 *     />
 *
 * **Fix D — bond visibility via `depthWrite={false}`:**
 *
 *   The material has `transparent={true}` to support opacity-based
 *   translucency for unselected cells (0.85) and the reduced
 *   opacity of interior cells (0.45). By default, Three.js writes
 *   transparent fragments to the depth buffer — which occludes
 *   bonds passing through or near cell geometry, even though the
 *   cells are visually translucent.
 *
 *   With the Lorentz-boost centring packing cells tighter in the
 *   Poincaré disk/ball AND per-cell scale shrinking cells near the
 *   boundary, bond endpoints (fixed at cell centres) now often fall
 *   inside the cells' visual volume. Without `depthWrite={false}`,
 *   these bond segments become invisible.
 *
 *   Setting `depthWrite={false}` on all cell materials lets bonds
 *   render correctly through translucent cells while still allowing
 *   standard depth-sorted transparency via `transparent={true}`.
 *   Cells still write to the depth buffer for opaque pixels (their
 *   outlines remain sharp against the background), but their
 *   translucent regions no longer occlude the bonds behind them.
 *
 *   This is the standard Three.js pattern for translucent geometry
 *   that must not hide other translucent geometry behind it.
 *
 * Material properties (frontend-spec §6.2, updated for bulk/boundary):
 *
 *   | Property       | Boundary (default)  | Interior              |
 *   |----------------|---------------------|-----------------------|
 *   | Color          | data-driven hex     | neutral gray (#6b7280)|
 *   | Metalness      | 0.1                 | 0.05                  |
 *   | Roughness      | 0.7                 | 0.85                  |
 *   | Opacity (norm)  | 0.85               | 0.45                  |
 *   | Opacity (sel)   | 1.0                | 0.45 (no selection)   |
 *   | Emissive (sel)  | orange #ffaa00 0.5 | none (black, 0)       |
 *   | Emissive (norm) | black, 0           | none (black, 0)       |
 *   | depthWrite      | false (both)       | false (both)          |
 *
 *   The lower metalness and higher roughness on interior cells make
 *   them appear more matte and recessive, reinforcing the visual
 *   hierarchy: boundary = foreground data, interior = background
 *   structure.
 *
 * Performance: This component renders a single `<mesh>`. For patches
 * with >500 total cells, the parent PatchScene uses `InstancedMesh`
 * with per-instance colors AND per-instance scales (applied via
 * `dummy.scale.setScalar(transform.scale)` in the matrix computation)
 * instead of individual CellMesh components (frontend-spec §6.3).
 * The instanced path handles the interior/boundary distinction via
 * opacity in the shared material and color overrides for selected
 * cells. The instanced material also sets `depthWrite={false}` for
 * consistent bond visibility across both rendering paths.
 *
 * Geometry caching: A module-level `Map<Tiling, BufferGeometry>`
 * ensures that all CellMesh instances sharing the same tiling type
 * reuse a single geometry object on the GPU. At most 5 geometry
 * objects are ever created (one per tiling variant).
 *
 * Interaction:
 *   - Click: invokes `onClick` prop (typically selects this cell's region)
 *   - Pointer over/out: changes cursor to "pointer" / "auto"
 *   - `stopPropagation()` on all events to prevent OrbitControls
 *     from consuming cell-level interactions
 *   - Interior cells still fire onClick (PatchScene handles the case
 *     where the clicked cell has no singleton region → deselects)
 *
 * Cursor cleanup (review issue #4):
 *   If the component unmounts while the pointer is over it (e.g. the
 *   user navigates away, toggles bond visibility, or the instancing
 *   threshold changes), `onPointerOut` never fires and the cursor
 *   would be stuck on "pointer". A `useEffect` cleanup resets the
 *   cursor to "auto" on unmount to prevent this leak.
 *
 * Accessibility:
 *   - `userData.cellId` is attached to the mesh for debugging and
 *     for higher-level event handlers to identify the clicked cell
 *   - `userData.isInterior` is attached for debugging
 *
 * @see PatchScene — The parent component that creates CellMesh instances
 * @see BondConnector — Translucent cylinders between adjacent cells
 * @see ColorControls — UI for selecting the active color mode
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4.3 (3D Viewport)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Scene Structure)
 *   - docs/engineering/frontend-spec-webgl.md §6.1 (Cell Geometry)
 *   - docs/engineering/frontend-spec-webgl.md §6.2 (Materials)
 *   - docs/engineering/frontend-spec-webgl.md §6.3 (Performance)
 *   - docs Roadmap "Centre Patches in Poincaré Projection" §2 (per-cell scale)
 *   - Post-Poincaré review, Fix D (bond visibility via depthWrite={false})
 */

import { useEffect, useMemo, useRef, useCallback } from "react";
import { Color } from "three";
import type { Mesh as ThreeMesh, BufferGeometry } from "three";
import type { ThreeEvent } from "@react-three/fiber";

import type { Tiling } from "../../types";
import { getCellGeometry } from "../../utils/tiling";

// ════════════════════════════════════════════════════════════════
//  Constants — Boundary Cells (default)
// ════════════════════════════════════════════════════════════════

/**
 * Emissive glow color for selected boundary cells.
 *
 * Orange (#ffaa00) per frontend-spec §4.3:
 * "Selected cell: emissive glow (orange, intensity 0.5)"
 *
 * Stored as a module-level THREE.Color to avoid allocating a new
 * object on every render of every selected cell.
 */
const EMISSIVE_SELECTED = new Color(0xffaa00);

/**
 * Emissive color for unselected cells and all interior cells — black (no glow).
 *
 * MeshStandardMaterial defaults to black emissive with intensity 0,
 * but we set it explicitly so R3F doesn't detect a prop change when
 * toggling between selected and unselected states.
 */
const EMISSIVE_OFF = new Color(0x000000);

/** Emissive intensity when a boundary cell is selected (frontend-spec §4.3). */
const EMISSIVE_INTENSITY_SELECTED = 0.5;

/** Emissive intensity when unselected or interior — no glow. */
const EMISSIVE_INTENSITY_OFF = 0;

/** Material metalness for boundary cells — low for a matte academic aesthetic (frontend-spec §6.2). */
const METALNESS_BOUNDARY = 0.1;

/** Material roughness for boundary cells — high for diffuse, non-glossy appearance (frontend-spec §6.2). */
const ROUGHNESS_BOUNDARY = 0.7;

/**
 * Boundary cell opacity when unselected (frontend-spec §6.2).
 *
 * Slight transparency (0.85) aids depth perception — cells behind
 * other cells show through subtly, helping the viewer understand
 * the 3D structure of the patch without explicit depth-cue overlays.
 */
const OPACITY_BOUNDARY_DEFAULT = 0.85;

/** Boundary cell opacity when selected — fully opaque to emphasize focus (frontend-spec §6.2). */
const OPACITY_BOUNDARY_SELECTED = 1.0;

// ════════════════════════════════════════════════════════════════
//  Constants — Interior Cells
// ════════════════════════════════════════════════════════════════

/**
 * Material metalness for interior cells — very low, making them
 * appear flat and recessive compared to boundary cells.
 */
const METALNESS_INTERIOR = 0.05;

/**
 * Material roughness for interior cells — very high for maximum
 * diffuse scattering. Combined with lower opacity, this makes
 * interior cells read as translucent structural context rather
 * than data-bearing surfaces.
 */
const ROUGHNESS_INTERIOR = 0.85;

/**
 * Interior cell opacity — significantly lower than boundary cells.
 *
 * 0.45 is low enough that interior cells are clearly "background"
 * rather than "foreground" data, but high enough to remain visible
 * as structural elements showing the bulk graph topology. At this
 * opacity, the bond connectors (0.3 opacity) passing through
 * interior cells are still discernible.
 *
 * The value is constant regardless of selection state — interior
 * cells cannot be meaningfully "selected" since they appear in
 * no boundary region and carry no per-region data.
 */
const OPACITY_INTERIOR = 0.45;

// ════════════════════════════════════════════════════════════════
//  Constants — Scale Default
// ════════════════════════════════════════════════════════════════

/**
 * Default scale factor applied to the mesh when the `scale` prop
 * is omitted.
 *
 * 1.0 is the identity scale — the cell renders at the natural size
 * of its template geometry (`CELL_RADIUS` from `utils/tiling.ts`).
 *
 * This default preserves backward compatibility with the existing
 * PatchScene usage, which wraps CellMesh in a `<group>` carrying
 * both the scene-space position AND the conformal scale, and
 * passes `position={[0, 0, 0]}` (no explicit scale) to CellMesh
 * itself. Existing call sites continue to work unchanged; the
 * `scale` prop is opt-in for callers that want to bypass the
 * group wrapper.
 */
const DEFAULT_SCALE = 1;

// ════════════════════════════════════════════════════════════════
//  Geometry cache
// ════════════════════════════════════════════════════════════════

/**
 * Module-level geometry cache — one BufferGeometry per tiling type,
 * shared across all CellMesh instances in the application.
 *
 * This avoids creating duplicate GPU-side geometry buffers when
 * rendering 200+ cells of the same tiling type. At most 5 entries
 * exist (one per {@link Tiling} variant), so memory overhead is
 * negligible.
 *
 * The cache persists for the lifetime of the module (i.e. the page).
 * Geometry objects are NOT disposed on component unmount because
 * they may be reused when navigating between patches of the same
 * tiling type. Browser garbage collection handles cleanup on page
 * unload (the WebGL context is destroyed).
 */
const geometryCache = new Map<Tiling, BufferGeometry>();

/**
 * Retrieve the cached BufferGeometry for a tiling type, creating
 * and caching it on first access.
 *
 * @param tiling - The tiling type determining the cell shape.
 * @returns A shared BufferGeometry instance for the given tiling.
 */
function getOrCreateGeometry(tiling: Tiling): BufferGeometry {
  let geo = geometryCache.get(tiling);
  if (!geo) {
    geo = getCellGeometry(tiling);
    geometryCache.set(tiling, geo);
  }
  return geo;
}

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link CellMesh} component. */
export interface CellMeshProps {
  /**
   * 3D position of the cell center.
   *
   * When CellMesh is used stand-alone (not wrapped in a parent
   * `<group>`), this should be the full scene-space position
   * computed by the layout algorithm in `utils/layout.ts`
   * (`NodeTransform.pos`).
   *
   * When wrapped in a parent `<group>` that carries the position
   * (the current PatchScene pattern), pass `[0, 0, 0]` here and
   * let the group's transform place the mesh.
   *
   * For 2D patches ({5,4}, {5,3}, {4,4}): z is always 0.
   * For 3D patches ({4,3,5}): all three coordinates are used.
   */
  position: [number, number, number];

  /**
   * Hex color string for this cell, pre-computed by the parent
   * component based on the active color mode (min-cut, region size,
   * S/area ratio, or curvature) for boundary cells, or the neutral
   * interior color (#6b7280) for interior cells.
   *
   * Examples: "#440154" (Viridis deep purple), "#6b7280" (interior gray)
   */
  color: string;

  /**
   * Whether this cell is currently selected (part of the focused
   * region). Selected **boundary** cells receive:
   *   - Full opacity (1.0 instead of 0.85)
   *   - Orange emissive glow (intensity 0.5)
   *
   * For **interior** cells, this prop is ignored — interior cells
   * are never visually highlighted because they belong to no
   * boundary region and carry no per-region data. PatchScene
   * should never pass `selected=true` for interior cells, but
   * CellMesh handles it gracefully by ignoring selection state
   * when `isInterior=true`.
   */
  selected: boolean;

  /**
   * Tiling type — determines the geometry shape of the cell.
   * All cells in a patch share the same tiling type.
   */
  tiling: Tiling;

  /**
   * Click handler, invoked when the user clicks this cell.
   *
   * For boundary cells: typically selects the region containing
   * this cell: `onClick={() => onCellClick(cellId)}`
   *
   * For interior cells: PatchScene receives the click and finds
   * no singleton region for this cell → deselects the current
   * region. Interior cells are still clickable (they don't swallow
   * clicks silently) to maintain consistent interaction behavior.
   */
  onClick?: () => void;

  /**
   * Cell ID for identification and debugging.
   *
   * Attached to the mesh's `userData` object so that higher-level
   * event handlers (e.g. tooltip system) can identify which cell
   * was interacted with.
   */
  cellId?: number;

  /**
   * Whether this cell is an interior cell (all faces shared, appears
   * in no boundary region).
   *
   * Interior cells are rendered with:
   *   - Lower opacity (0.45 vs 0.85)
   *   - No emissive selection glow
   *   - More matte material (lower metalness, higher roughness)
   *
   * This provides a clear visual hierarchy: boundary cells are the
   * primary data-bearing elements (foreground), while interior cells
   * are structural context showing the bulk graph topology (background).
   *
   * Defaults to `false` (boundary cell) for backward compatibility.
   */
  isInterior?: boolean;

  /**
   * Uniform scale factor applied to the mesh.
   *
   * Corresponds to the per-cell conformal factor
   * `s(u) = (1 − |u|²) / 2` at the cell's Poincaré position
   * (`NodeTransform.scale` from `utils/layout.ts`). Cells near
   * the origin of the Poincaré ball/disk render at
   * `scale ≈ 0.5`; cells near the boundary shrink toward zero.
   *
   * Applied as a single number to the R3F `<mesh scale={...}>`
   * attribute, which is the standard Three.js convention for
   * uniform scaling (equivalent to `mesh.scale.setScalar(scale)`).
   *
   * Defaults to `1` so that:
   *   - Existing PatchScene usage (which wraps CellMesh in a
   *     `<group>` carrying both position and scale) continues
   *     to work unchanged.
   *   - Consumer code that omits the prop gets the natural
   *     template geometry size.
   *
   * Callers wishing to use CellMesh stand-alone with the full
   * Poincaré transform can pass both `position` and `scale`
   * directly:
   *
   * ```tsx
   * <CellMesh
   *   position={transform.pos}
   *   scale={transform.scale}
   *   color={getCellColor(cellId)}
   *   selected={selectedCellSet.has(cellId)}
   *   tiling={patch.patchTiling}
   *   onClick={() => onCellClick(cellId)}
   *   cellId={cellId}
   * />
   * ```
   */
  scale?: number;
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Renders a single holographic patch cell as a Three.js mesh.
 *
 * The mesh receives a cached geometry (determined by tiling type),
 * a MeshStandardMaterial with the specified color and selection
 * state, a uniform scale factor (from the Poincaré conformal
 * factor or the default `1`), and event handlers for click and
 * pointer interactions.
 *
 * Material properties vary based on `isInterior`:
 *   - Boundary cells (default): standard material with selection glow
 *   - Interior cells: lower opacity, no glow, more matte finish
 *
 * Both paths set `depthWrite={false}` so that translucent cells
 * do not occlude the bonds that pass through or near them
 * (Fix D of the post-Poincaré review).
 *
 * @example
 * ```tsx
 * // Boundary cell wrapped in a parent <group> (current PatchScene pattern):
 * <group position={transform.pos} scale={transform.scale}>
 *   <CellMesh
 *     position={[0, 0, 0]}
 *     color={colorFromMinCut(region.regionMinCut, patch.patchMaxCut)}
 *     selected={selectedRegion?.regionId === region.regionId}
 *     tiling={patch.patchTiling}
 *     onClick={() => onCellClick(cellId)}
 *     cellId={42}
 *   />
 * </group>
 *
 * // Stand-alone usage with the scale prop (no group wrapper):
 * <CellMesh
 *   position={transform.pos}
 *   scale={transform.scale}
 *   color={colorFromMinCut(region.regionMinCut, patch.patchMaxCut)}
 *   selected={selectedRegion?.regionId === region.regionId}
 *   tiling={patch.patchTiling}
 *   onClick={() => onCellClick(cellId)}
 *   cellId={42}
 * />
 *
 * // Interior cell (neutral gray, structural context):
 * <CellMesh
 *   position={[0.5, -1.2, 3.1]}
 *   scale={0.38}
 *   color="#6b7280"
 *   selected={false}
 *   tiling={patch.patchTiling}
 *   onClick={() => onCellClick(cellId)}
 *   cellId={7}
 *   isInterior
 * />
 * ```
 */
export function CellMesh({
  position,
  color,
  selected,
  tiling,
  onClick,
  cellId,
  isInterior = false,
  scale = DEFAULT_SCALE,
}: CellMeshProps) {
  const meshRef = useRef<ThreeMesh>(null);

  // ── Geometry ──────────────────────────────────────────────────
  // Retrieved from the module-level cache. All cells with the same
  // tiling share a single BufferGeometry on the GPU.
  const geometry = useMemo(() => getOrCreateGeometry(tiling), [tiling]);

  // ── Color ─────────────────────────────────────────────────────
  // Memoize the THREE.Color to avoid allocating a new object on
  // every render. R3F compares material props by reference; a new
  // Color instance would trigger an unnecessary material update.
  const meshColor = useMemo(() => new Color(color), [color]);

  // ── Material properties (interior vs boundary) ────────────────
  //
  // Interior cells: always low opacity, no glow, matte material.
  // Boundary cells: standard opacity (higher when selected), glow
  // when selected, standard material properties.
  const emissive = !isInterior && selected ? EMISSIVE_SELECTED : EMISSIVE_OFF;
  const emissiveIntensity = !isInterior && selected
    ? EMISSIVE_INTENSITY_SELECTED
    : EMISSIVE_INTENSITY_OFF;

  const opacity = isInterior
    ? OPACITY_INTERIOR
    : selected
      ? OPACITY_BOUNDARY_SELECTED
      : OPACITY_BOUNDARY_DEFAULT;

  const metalness = isInterior ? METALNESS_INTERIOR : METALNESS_BOUNDARY;
  const roughness = isInterior ? ROUGHNESS_INTERIOR : ROUGHNESS_BOUNDARY;

  // ── Cursor cleanup on unmount (review issue #4) ───────────────
  //
  // If the mesh is removed from the scene while the pointer is
  // hovering over it (e.g. user navigates away, toggles bond
  // visibility, or the instancing threshold changes mid-hover),
  // the onPointerOut handler never fires and the cursor stays
  // stuck on "pointer". This effect resets the cursor to "auto"
  // on unmount, preventing the leak.
  useEffect(() => {
    return () => {
      document.body.style.cursor = "auto";
    };
  }, []);

  // ── Event handlers ────────────────────────────────────────────
  // All handlers call stopPropagation() to prevent the event from
  // reaching OrbitControls (which would interpret a cell click as
  // a drag-to-rotate gesture).

  /**
   * Handle click on this cell — delegates to the parent's onClick.
   */
  const handleClick = useCallback(
    (e: ThreeEvent<MouseEvent>) => {
      e.stopPropagation();
      onClick?.();
    },
    [onClick],
  );

  /**
   * Handle pointer entering this cell — change cursor to "pointer"
   * to signal interactivity.
   *
   * No visual hover effect (scale, color change) is applied to
   * maintain the "interactive paper" aesthetic (frontend-spec §4.1:
   * "no gratuitous animation").
   */
  const handlePointerOver = useCallback(
    (e: ThreeEvent<PointerEvent>) => {
      e.stopPropagation();
      document.body.style.cursor = "pointer";
    },
    [],
  );

  /**
   * Handle pointer leaving this cell — restore default cursor.
   */
  const handlePointerOut = useCallback(
    (e: ThreeEvent<PointerEvent>) => {
      e.stopPropagation();
      document.body.style.cursor = "auto";
    },
    [],
  );

  // ── Render ────────────────────────────────────────────────────
  //
  // The `scale` prop is applied as a single number to R3F's
  // `<mesh scale={...}>` attribute, which Three.js interprets as
  // a uniform scale factor (equivalent to
  // `mesh.scale.setScalar(scale)`). This gives the cell its
  // correct conformal size near the Poincaré boundary without
  // requiring a parent `<group>` wrapper.
  //
  // When the prop is omitted, `scale` defaults to `1` (via the
  // destructuring default above), preserving the rendering
  // behaviour of callers that handle scale externally via a
  // parent `<group>`.
  //
  // Fix D — depthWrite={false}:
  //   Both boundary and interior cells are rendered with
  //   `transparent={true}` (opacity 0.85/1.0 for boundary,
  //   0.45 for interior).  Three.js's default behaviour is to
  //   still write transparent fragments to the depth buffer,
  //   which causes bonds passing through or near the cell's
  //   visual volume to be occluded — even though the cell is
  //   translucent.  With the Lorentz-boost centring packing
  //   the patch tighter in the Poincaré disk/ball and per-cell
  //   scale shrinking cells near the boundary, bond endpoints
  //   (fixed at cell centres) now regularly fall inside the
  //   cells' visual volume, making the bonds disappear entirely.
  //
  //   Setting `depthWrite={false}` disables the depth-buffer
  //   write for translucent fragments, allowing bonds to render
  //   correctly through cells while still respecting depth
  //   sorting via `transparent={true}`.  This is the standard
  //   Three.js pattern for translucent geometry that must not
  //   hide other translucent geometry behind it.
  return (
    <mesh
      ref={meshRef}
      position={position}
      scale={scale}
      geometry={geometry}
      onClick={handleClick}
      onPointerOver={handlePointerOver}
      onPointerOut={handlePointerOut}
      userData={{ cellId, isInterior }}
    >
      <meshStandardMaterial
        color={meshColor}
        metalness={metalness}
        roughness={roughness}
        transparent
        opacity={opacity}
        depthWrite={false}
        emissive={emissive}
        emissiveIntensity={emissiveIntensity}
      />
    </mesh>
  );
}