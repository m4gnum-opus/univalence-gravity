/**
 * BondConnector — Translucent cylinder between two cell positions.
 *
 * Renders a physical bond (shared face/edge between adjacent cells)
 * as a thin translucent gray cylinder connecting two 3D positions in
 * the React Three Fiber scene.
 *
 * **Updated (Phase 1, item 10):** Now renders bonds sourced from
 * `patchGraph.pgEdges` — the TRUE physical bonds between adjacent
 * cells (shared cube faces in 3D, shared pentagon edges in 2D,
 * weighted tree edges for Tree).  The parent component (PatchScene)
 * extracts bonds via `extractGraphBonds(patch)` from `layout.ts`,
 * which returns `patch.patchGraph.pgEdges` directly.
 *
 * Previously, bonds were inferred from size-2 boundary regions, which
 * represented boundary adjacency (two boundary cells forming a
 * connected subset), NOT physical bonds.  This missed all:
 *   - Interior-to-boundary bonds (e.g. C–N0 in the star patch)
 *   - Interior-to-interior bonds (deep in the bulk of Dense patches)
 * causing the "galaxy" / "universe" appearance of fragmented dots.
 *
 * **Performance optimization — shared geometry:**
 *
 *   Instead of creating a unique `CylinderGeometry` per bond (each
 *   with a different height parameter), this component uses a single
 *   **module-level shared unit-height cylinder** and scales the mesh's
 *   local Y axis to the correct bond length via `scale={[1, length, 1]}`.
 *
 *   This reduces GPU geometry objects from O(bonds) to O(1):
 *     - Dense-50:   68 bonds  → 1 shared geometry (was 68)
 *     - Dense-100:  150 bonds → 1 shared geometry (was 150)
 *     - Dense-200:  308 bonds → 1 shared geometry (was 308)
 *     - Dense-1000: 1597 bonds → 1 shared geometry (was 1597)
 *
 *   The shared geometry persists for the module lifetime and is never
 *   disposed — it is reused across all patches and all bond instances.
 *   Browser GC handles cleanup on page unload.
 *
 * Material properties (frontend-spec §6.2):
 *   - Color: #888888 (neutral gray)
 *   - Transparent: true
 *   - Opacity: 0.3 (translucent — bonds should be visible but not
 *     visually dominant; the cells are the primary visual elements)
 *   - Metalness: 0.1, Roughness: 0.7 (matching CellMesh for
 *     consistent lighting across the scene)
 *
 * Geometry:
 *   - Shared CylinderGeometry with unit height (1.0), small radius
 *     (0.06), and 8 radial segments
 *   - Per-bond length achieved via mesh scale, NOT per-bond geometry
 *   - The radius (X/Z axes) is unscaled, so bond thickness is uniform
 *     regardless of bond length
 *
 * Positioning strategy:
 *   Three.js CylinderGeometry is axis-aligned along Y by default.
 *   To orient the cylinder from `from` to `to`:
 *     1. Place the mesh at the midpoint of the two positions
 *     2. Compute the direction vector (to − from)
 *     3. Use a quaternion to rotate the cylinder's local Y axis
 *        to align with the direction vector
 *     4. Scale the local Y axis to the bond length
 *
 *   This is computed in a `useMemo` to avoid recalculating on every
 *   frame. The positions are static (computed once by the force-
 *   directed layout and cached in sessionStorage).
 *
 * @see CellMesh — The cell geometry component that bonds connect
 * @see PatchScene — The parent component managing all 3D elements
 * @see BoundaryWireframe — Wireframe overlay for exposed boundary faces
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4.3 (3D Viewport)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Scene Structure)
 *   - docs/engineering/frontend-spec-webgl.md §6.2 (Materials)
 */

import { useMemo } from "react";
import { Vector3, Quaternion, CylinderGeometry } from "three";

// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/**
 * Bond cylinder radius in world units.
 *
 * 0.06 is thin enough to avoid obscuring the cells (which are ~1
 * unit in diameter) but thick enough to be clearly visible as
 * structural connectors. At typical camera distances (z ≈ 50),
 * this renders as a visually subtle line.
 */
const BOND_RADIUS = 0.1;

/**
 * Number of radial segments for the cylinder geometry.
 *
 * 8 segments produce a smooth-enough cylinder at the small radius.
 * More segments (e.g. 16, 32) would increase triangle count without
 * perceptible visual improvement at the bond's thin scale. Fewer
 * segments (e.g. 4) would produce a visibly faceted tube.
 */
const RADIAL_SEGMENTS = 8;

/**
 * Bond material color — neutral gray (frontend-spec §6.2).
 *
 * Hex integer for Three.js color constructor: 0x888888.
 */
const BOND_COLOR = 0x888888;

/**
 * Bond material opacity — translucent (frontend-spec §6.2).
 *
 * 0.3 keeps bonds visible as structural context without
 * dominating the scene. Cells at 0.85 opacity are clearly
 * the primary visual element.
 */
const BOND_OPACITY = 0.3;

/** Material metalness — matches CellMesh for consistent lighting. */
const METALNESS = 0.1;

/** Material roughness — matches CellMesh for consistent lighting. */
const ROUGHNESS = 0.7;

/**
 * Reusable Vector3 aligned with the Y axis.
 *
 * CylinderGeometry is created along Y by default. We rotate
 * from this axis to the bond direction using a quaternion.
 * Module-level constant avoids allocating a new Vector3 per bond.
 */
const Y_AXIS = new Vector3(0, 1, 0);

// ════════════════════════════════════════════════════════════════
//  Shared Geometry (Module-Level Singleton)
// ════════════════════════════════════════════════════════════════

/**
 * A single unit-height CylinderGeometry shared by ALL BondConnector
 * instances in the application.
 *
 * Height = 1.0 (unit). Each bond achieves its correct length by
 * scaling the mesh's local Y axis: `scale={[1, bondLength, 1]}`.
 * The radius (X/Z axes) stays at BOND_RADIUS regardless of scale,
 * so all bonds have uniform thickness.
 *
 * This singleton eliminates O(bonds) geometry allocations:
 *   - Dense-1000: 1 geometry instead of 1,597
 *   - Dense-200:  1 geometry instead of 308
 *   - Dense-100:  1 geometry instead of 150
 *
 * The geometry persists for the module lifetime (i.e. the page).
 * It is NOT disposed on component unmount because it is shared
 * across all bond instances and all patch views. Browser garbage
 * collection handles cleanup on page unload (the WebGL context
 * is destroyed).
 */
const SHARED_CYLINDER_GEOMETRY = new CylinderGeometry(
  BOND_RADIUS,     // radiusTop
  BOND_RADIUS,     // radiusBottom
  1,               // height (unit — scaled per-bond via mesh.scale.y)
  RADIAL_SEGMENTS, // radialSegments
  1,               // heightSegments
);

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link BondConnector} component. */
export interface BondConnectorProps {
  /**
   * Start position of the bond (cell center A).
   *
   * Computed by the force-directed layout in `utils/layout.ts`
   * from the full bulk graph (`patchGraph.pgNodes` + `pgEdges`).
   */
  from: [number, number, number];

  /**
   * End position of the bond (cell center B).
   *
   * Computed by the force-directed layout in `utils/layout.ts`
   * from the full bulk graph (`patchGraph.pgNodes` + `pgEdges`).
   */
  to: [number, number, number];
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Renders a translucent gray cylinder connecting two cell positions.
 *
 * The cylinder uses the shared unit-height geometry, positioned at
 * the midpoint, rotated to align with the bond direction, and
 * scaled along local Y to the correct length.
 *
 * The bond data (which cells are connected) is determined by the
 * parent component (PatchScene) from `patchGraph.pgEdges` — the
 * true physical bonds exported by `18_export_json.py`. This
 * component is a pure presentational renderer; it does not decide
 * which cells to connect.
 *
 * @example
 * ```tsx
 * // Inside a React Three Fiber <Canvas>:
 * // bonds are from patchGraph.pgEdges (physical bonds)
 * {bonds.map(([c1, c2]) => {
 *   const p1 = positions.get(c1);
 *   const p2 = positions.get(c2);
 *   if (!p1 || !p2) return null;
 *   return (
 *     <BondConnector
 *       key={`b-${c1}-${c2}`}
 *       from={p1}
 *       to={p2}
 *     />
 *   );
 * })}
 * ```
 */
export function BondConnector({ from, to }: BondConnectorProps) {
  // ── Compute transform (position, rotation, scale) ─────────────
  //
  // All transform calculations are memoized on the `from` and `to`
  // arrays. Since positions come from the force-directed layout and
  // are cached in sessionStorage, they change only when the user
  // navigates to a different patch.
  //
  // Unlike the previous implementation, NO per-bond geometry is
  // created here. The shared SHARED_CYLINDER_GEOMETRY is reused
  // by every bond instance; only the transform differs.
  const { midpoint, quaternion, length } = useMemo(() => {
    const vFrom = new Vector3(from[0], from[1], from[2]);
    const vTo = new Vector3(to[0], to[1], to[2]);

    // Midpoint — the mesh is centered here.
    const mid: [number, number, number] = [
      (vFrom.x + vTo.x) / 2,
      (vFrom.y + vTo.y) / 2,
      (vFrom.z + vTo.z) / 2,
    ];

    // Length — the Euclidean distance between endpoints.
    // Used as the Y-axis scale factor on the unit-height cylinder.
    const len = vFrom.distanceTo(vTo);

    // Direction — the unit vector from `from` to `to`.
    const direction = new Vector3()
      .subVectors(vTo, vFrom)
      .normalize();

    // Quaternion rotation from the default Y axis to the bond direction.
    //
    // setFromUnitVectors(a, b) computes the shortest rotation that
    // maps unit vector `a` onto unit vector `b`. Since
    // CylinderGeometry is aligned along Y, we rotate Y → direction.
    const quat = new Quaternion().setFromUnitVectors(Y_AXIS, direction);

    return {
      midpoint: mid,
      quaternion: [quat.x, quat.y, quat.z, quat.w] as [
        number,
        number,
        number,
        number,
      ],
      length: len,
    };
  }, [from, to]);

  // ── Render ────────────────────────────────────────────────────
  //
  // The mesh uses the shared geometry (no per-bond allocation) and
  // achieves the correct bond length by scaling the local Y axis.
  //
  // scale={[1, length, 1]} stretches the unit-height cylinder to
  // `length` along local Y (which, after the quaternion rotation,
  // is aligned with the bond direction). The X and Z axes (the
  // cylinder radius) remain at scale 1.0, so BOND_RADIUS is the
  // visual radius regardless of bond length.
  //
  // depthWrite is disabled so that translucent bonds blend correctly
  // with cells behind them (standard practice for transparent objects
  // in Three.js — avoids z-fighting artifacts where the bond's depth
  // buffer entry prevents cells from rendering through it).
  //
  // renderOrder is not set — the default (0) places bonds in the
  // same render pass as cells. Three.js sorts transparent objects
  // by camera distance automatically.
  return (
    <mesh
      position={midpoint}
      quaternion={quaternion}
      scale={[1, length, 1]}
      geometry={SHARED_CYLINDER_GEOMETRY}
    >
      <meshStandardMaterial
        color={BOND_COLOR}
        transparent
        opacity={BOND_OPACITY}
        depthWrite={false}
        metalness={METALNESS}
        roughness={ROUGHNESS}
      />
    </mesh>
  );
}