// frontend/src/components/patches/BoundaryShell.tsx
/**
 * BoundaryShell — Semi-transparent fitted sphere around boundary cell
 * positions, visualizing the holographic boundary surface.
 *
 * This component renders a translucent spherical shell enclosing all
 * **boundary cells** of a holographic patch — the cells that appear in
 * at least one boundary region's `regionCells` array.  Interior cells
 * (those with all faces shared, appearing in no region) are NOT included
 * in the shell computation, because they are part of the bulk, not the
 * boundary.
 *
 * The shell provides a direct visualization of the holographic
 * principle: "the 2D boundary encodes the 3D bulk."  The semi-
 * transparent surface shows *where* the boundary is in 3D space,
 * while the cells and bonds visible through it show the bulk
 * structure that the boundary encodes.
 *
 * **Centring fix (Fix B of the post-Poincaré review):**
 *
 *   The previous implementation centred the shell sphere at the
 *   arithmetic centroid of the boundary cell positions.  After the
 *   Lorentz-boost centring applied by `18_export_json.py`
 *   (Roadmap Step 1), the fundamental cell (g = I) projects to the
 *   origin `(0, 0, 0)` of the Poincaré ball, so `utils/layout.ts`
 *   passes position `(0, 0, 0)` to the fundamental cell's mesh.
 *
 *   For a perfectly symmetric patch (e.g. {5,4} depth-N BFS star)
 *   the centroid of the boundary cells coincides with the origin,
 *   but for asymmetric patches (Dense-growth patches, layer-54-dX)
 *   the boundary-cell centroid drifts away from the origin.  That
 *   drift caused the shell to appear off-centre relative to the
 *   patch — only one edge of the boundary touched the shell — even
 *   though the fundamental cell was correctly at the scene origin.
 *
 *   The fix is to centre the shell at `(0, 0, 0)` unconditionally
 *   and size it by the maximum distance of any boundary cell from
 *   the origin (plus `SHELL_PADDING`).  This anchors the shell to
 *   the same reference point as the Lorentz boost and guarantees
 *   that every boundary cell sits exactly on or inside the shell
 *   surface, with the shell visually enclosing the patch as a
 *   single coherent envelope.
 *
 * **Geometry strategy (simplified from the original plan):**
 *
 *   Earlier versions of this component attempted to use a 3D convex
 *   hull (`ConvexGeometry` from `three/examples/jsm/geometries/`)
 *   for 3D patches and fall back to a fitted sphere otherwise.  That
 *   approach was repeatedly brittle under Vite 6's dev server, which
 *   could not reliably resolve the `three/examples/jsm/` subpath in
 *   `three@0.170`'s `package.json` `exports` field.  Both static and
 *   `/* @vite-ignore * /`-annotated dynamic imports caused
 *   module-evaluation failures that crashed the entire import chain
 *   (`BoundaryShell → PatchScene → PatchView → white screen`) even
 *   when `showShell` was `false`, because dev-server transform errors
 *   surface synchronously before `try/catch` can intervene.
 *
 *   The current implementation uses a **fitted sphere in all cases**,
 *   eliminating any dependency on Three.js example modules.  The
 *   sphere is centred at the scene origin with radius equal to the
 *   maximum cell distance from the origin plus a small padding factor
 *   (`SHELL_PADDING`) so the shell does not intersect the cell meshes.
 *
 *   For 3D patches this produces a bounding sphere rather than a
 *   tight hull, but at the component's very low opacity (0.12) the
 *   visual difference is negligible — the shell reads as a ghostly
 *   "celestial sphere" enveloping the holographic bulk, which
 *   matches the physics-visualization convention where the boundary
 *   of a hyperbolic ball is conformally a sphere.
 *
 *   For 2D patches (which are laid out in the XY plane with z = 0)
 *   the sphere naturally encloses the flat arrangement from all
 *   sides, providing a 3D envelope that reads correctly from any
 *   camera angle.
 *
 * **Visual properties:**
 *
 *   | Property        | Value                                             |
 *   |-----------------|---------------------------------------------------|
 *   | Color           | #93c5fd (Tailwind blue-300, matching wireframe) |
 *   | Opacity         | 0.12 (very translucent — bulk remains visible)    |
 *   | Side            | DoubleSide (visible from inside and outside)      |
 *   | depthWrite      | false (doesn't occlude interior cells/bonds)      |
 *   | Metalness       | 0.0 (fully diffuse)                               |
 *   | Roughness       | 1.0 (no specular highlights)                      |
 *
 *   The very low opacity (0.12) is deliberate: the shell is a
 *   structural indicator, not a data surface.  It should be
 *   *barely perceptible* at rest — a ghostly membrane enclosing
 *   the bulk graph.  The `BoundaryWireframe` (at 0.6 opacity)
 *   provides the stronger boundary indicator; the shell provides
 *   the enclosing surface that completes the holographic picture.
 *
 * **Lifecycle:**
 *
 *   The `SphereGeometry` is created inside a `useMemo` and recreated
 *   only when the `cells` array or `tiling` type changes (i.e. on
 *   patch navigation).  A `useEffect` disposal hook ensures that the
 *   previous geometry's GPU resources are freed when a new geometry
 *   is created or when the component unmounts.  This mirrors the
 *   disposal pattern in `BoundaryWireframe.tsx`.
 *
 * **Toggle:**
 *
 *   Visibility is controlled by the parent component (PatchView) via
 *   conditional rendering: `{showShell && <BoundaryShell ... />}`.
 *   The toggle is provided by `ColorControls` alongside the existing
 *   "Internal bonds" and "Boundary wireframe" checkboxes.
 *
 *   Because this component is only mounted when `showShell` is true,
 *   it imports nothing that could fail at module-evaluation time even
 *   if it were mounted unconditionally — every import is a bare
 *   specifier from `three` or `react` that Vite pre-bundles
 *   successfully.  Swapping the toggle on/off has no module-loading
 *   overhead; the component simply mounts/unmounts.
 *
 * @see BoundaryWireframe — Edge outlines for boundary cells (complements this)
 * @see PatchScene — The parent Three.js canvas managing all 3D elements
 * @see ColorControls — UI toggle controlling this component's visibility
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Scene Structure)
 *   - docs/physics/holographic-dictionary.md (boundary encodes bulk)
 *   - Phase 2, item 15 of the concrete fix plan
 *   - Post-Poincaré review, Fix B (centre shell at origin)
 */

import { useMemo, useRef, useEffect } from "react";
import { SphereGeometry, DoubleSide } from "three";
import type { BufferGeometry as BufferGeometryType } from "three";

import type { Tiling } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/**
 * Shell surface color — calm blue matching the BoundaryWireframe.
 *
 * Tailwind blue-300 (#93c5fd) is used for visual consistency with
 * the wireframe overlay.  At the shell's very low opacity (0.12),
 * this reads as a faint blue tint rather than a solid surface.
 */
const SHELL_COLOR = "#93c5fd";

/**
 * Shell surface opacity — very translucent.
 *
 * 0.12 is deliberately much lower than the wireframe's 0.6:
 *   - The wireframe is a structural *indicator* (needs to be seen)
 *   - The shell is a structural *envelope* (needs to be subtle)
 *
 * At 0.12, the shell is barely visible when the camera is far away
 * but becomes a perceptible translucent membrane when the camera is
 * close enough to see the curvature of the surface.  This matches
 * the academic credibility principle: understated, not flashy.
 */
const SHELL_OPACITY = 0.12;

/**
 * Expansion padding beyond the outermost boundary cell (world units).
 *
 * The shell sphere radius equals the maximum cell distance from the
 * origin plus this padding value.  This prevents the shell from
 * intersecting the cell meshes (which have a radius of ~0.5 world
 * units per `CELL_RADIUS` in `tiling.ts`) and creates a visible gap
 * between the cells and the enclosing membrane.
 *
 * 0.6 units = slightly larger than a cell radius, producing a shell
 * that visibly wraps around the outermost boundary cells.
 */
const SHELL_PADDING = 0.6;

/**
 * Number of width/height segments for the SphereGeometry.
 *
 * 32 segments produce a smooth sphere at typical camera distances.
 * Higher values (64+) would increase triangle count without visible
 * improvement given the very low opacity.  Lower values (16) would
 * produce a visibly faceted sphere on close inspection.
 */
const SPHERE_SEGMENTS = 32;

/**
 * Minimum number of boundary cells required to render a shell.
 *
 * With fewer than 3 cells, a meaningful enclosing sphere centred
 * at the origin would still be computable (the radius is just
 * max|position|), but the visual result is degenerate for
 * single-cell or two-cell patches.  We keep the guard at 3 for
 * parity with the previous implementation.
 */
const MIN_CELLS = 3;

/**
 * The scene origin — the Lorentz-boost-centred fundamental cell
 * position that anchors the entire Poincaré-projected patch.
 *
 * After Roadmap Step 1, `18_export_json.py` applies a hyperbolic
 * isometry that maps the fundamental cell centre to the hyperboloid
 * apex, so the identity cell projects to `(0, 0, 0)` in the Poincaré
 * ball.  Every other cell's position is measured relative to this
 * origin — and the shell should be too.
 */
const ORIGIN: [number, number, number] = [0, 0, 0];

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link BoundaryShell} component. */
export interface BoundaryShellProps {
  /**
   * Boundary cell IDs paired with their 3D positions.
   *
   * **Only boundary cells are included** — cells appearing in at
   * least one region's `regionCells` array.  Interior cells (all
   * faces shared, appearing in no region) are excluded by the
   * parent component (PatchScene) before passing this prop.
   *
   * The shell encloses these positions, providing a visual
   * representation of the holographic boundary surface.
   *
   * Same data structure as `BoundaryWireframe`'s `cells` prop,
   * allowing both components to share the same pre-filtered
   * boundary cell list from `PatchScene`.
   */
  cells: Array<{
    cellId: number;
    position: [number, number, number];
  }>;

  /**
   * Tiling type — accepted for API compatibility with
   * `BoundaryWireframe` and potential future tiling-specific
   * rendering logic, but not currently used (the fitted-sphere
   * strategy works uniformly across all tilings).
   */
  tiling: Tiling;
}

// ════════════════════════════════════════════════════════════════
//  Geometry Computation Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Computed shell geometry with its mesh position.
 *
 * Under the origin-centred scheme, `position` is always the scene
 * origin `[0, 0, 0]`, but we retain the field so that the rendered
 * `<mesh position={...}>` stays a direct function of the computed
 * data rather than a hard-coded constant.
 */
interface ShellData {
  /** The SphereGeometry for the shell surface. */
  geometry: BufferGeometryType;
  /** The mesh position in world coordinates (always `ORIGIN`). */
  position: [number, number, number];
}

/**
 * Compute the maximum Euclidean distance from the scene origin to
 * any position in the array.
 *
 * This is the bounding radius: a sphere of this radius (plus
 * padding) centred at the origin encloses all boundary cells.
 *
 * Unlike the previous `computeMaxRadius(positions, centroid)`
 * helper, this function takes the origin as its reference point
 * unconditionally.  Post-Lorentz-boost, this is the physically
 * correct reference because the fundamental cell — the anchor of
 * the entire Poincaré projection — is at the origin.
 */
function computeMaxRadiusFromOrigin(
  positions: [number, number, number][],
): number {
  let maxR2 = 0;
  for (const [x, y, z] of positions) {
    const r2 = x * x + y * y + z * z;
    if (r2 > maxR2) maxR2 = r2;
  }
  return Math.sqrt(maxR2);
}

/**
 * Create the shell's SphereGeometry anchored at the scene origin.
 *
 * After the Lorentz-boost centring applied by the Python exporter
 * (Roadmap Step 1), the fundamental cell sits at `(0, 0, 0)`.
 * Anchoring the shell at the origin — rather than at the
 * arithmetic centroid of the boundary cells — guarantees that the
 * shell's centre coincides with the visual centre of the patch
 * regardless of whether the boundary is symmetric about the
 * fundamental cell.
 *
 * The radius is `max|cell_position| + SHELL_PADDING`, producing
 * the tightest origin-centred sphere that contains every boundary
 * cell plus a small visible gap.
 *
 * @param positions - Boundary cell positions in world coordinates.
 * @returns A ShellData object, or `null` if the shell cannot be
 *   computed (too few cells, zero bounding radius, etc.).
 */
function createShellDataAtOrigin(
  positions: [number, number, number][],
): ShellData | null {
  if (positions.length < MIN_CELLS) return null;

  const maxRadius = computeMaxRadiusFromOrigin(positions);

  // Degenerate case: all boundary cells are (numerically) at the
  // origin.  A sphere with near-zero radius would be invisible
  // anyway, so we skip rendering entirely.
  if (maxRadius < 0.001) return null;

  const radius = maxRadius + SHELL_PADDING;
  const sphereGeo = new SphereGeometry(
    radius,
    SPHERE_SEGMENTS,
    SPHERE_SEGMENTS,
  );

  // SphereGeometry is centred at its local origin; positioning the
  // mesh at ORIGIN (the scene origin) places the sphere around the
  // boundary cells.
  return { geometry: sphereGeo, position: ORIGIN };
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Renders a semi-transparent spherical shell enclosing all boundary
 * cells, visualizing the holographic boundary surface.
 *
 * The shell is anchored at the scene origin `(0, 0, 0)` — the
 * Lorentz-boost-centred position of the fundamental cell — with
 * radius sized to enclose every boundary cell plus a small padding
 * gap.  This centring is what makes the shell visually "wrap"
 * the patch as a whole rather than drifting toward the mean
 * boundary-cell position on asymmetric patches.
 *
 * The shell is a direct visualization of the holographic principle:
 * the semi-transparent surface represents the 2D boundary that
 * encodes the 3D bulk visible through it.  Interior cells, bond
 * connectors, and boundary wireframe edges are all visible through
 * the translucent membrane.
 *
 * Renders nothing when:
 *   - Fewer than 3 boundary cells are provided
 *   - All boundary cells are at (or very near) the origin
 *
 * @example
 * ```tsx
 * // Inside a React Three Fiber <Canvas> (from PatchScene):
 * {showShell && (
 *   <BoundaryShell
 *     cells={boundaryCellList}
 *     tiling={patch.patchTiling}
 *   />
 * )}
 * ```
 */
export function BoundaryShell({ cells }: BoundaryShellProps) {
  // Track the current geometry for disposal on change/unmount.
  const prevGeoRef = useRef<BufferGeometryType | null>(null);

  // ── Compute the shell geometry ────────────────────────────────
  //
  // Recomputed when the cells array changes (patch navigation).
  // Within a single patch view, the geometry is computed once and
  // reused for every frame.  The tiling prop is accepted but not
  // used — the origin-centred fitted-sphere strategy is uniform
  // across tilings.
  const shellData = useMemo<ShellData | null>(() => {
    if (cells.length < MIN_CELLS) return null;
    const positions = cells.map((c) => c.position);
    return createShellDataAtOrigin(positions);
  }, [cells]);

  // ── Dispose the previous geometry on change / unmount ─────────
  //
  // Each shell geometry is a unique GPU buffer created per patch
  // navigation.  We dispose the previous one when a new one is
  // created (patch change) or when the component unmounts (toggle
  // off, user navigates away).
  //
  // This mirrors the disposal pattern in BoundaryWireframe.tsx.
  useEffect(() => {
    if (prevGeoRef.current && prevGeoRef.current !== shellData?.geometry) {
      prevGeoRef.current.dispose();
    }
    prevGeoRef.current = shellData?.geometry ?? null;

    return () => {
      if (prevGeoRef.current) {
        prevGeoRef.current.dispose();
        prevGeoRef.current = null;
      }
    };
  }, [shellData]);

  // Render nothing when the shell geometry cannot be computed.
  if (!shellData) {
    return null;
  }

  return (
    <mesh
      geometry={shellData.geometry}
      position={shellData.position}
    >
      <meshStandardMaterial
        color={SHELL_COLOR}
        transparent
        opacity={SHELL_OPACITY}
        side={DoubleSide}
        depthWrite={false}
        metalness={0.0}
        roughness={1.0}
      />
    </mesh>
  );
}