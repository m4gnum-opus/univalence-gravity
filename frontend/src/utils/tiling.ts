/**
 * Pentagon/cube/square geometry helpers for cell meshes in the 3D viewport.
 *
 * Provides Three.js BufferGeometry instances and tiling metadata for
 * each of the five tiling types in the project. Geometries are created
 * lazily and cached — call {@link getCellGeometry} to obtain a shared
 * BufferGeometry instance suitable for use with `<mesh>` elements or
 * `InstancedMesh` (required for patches with >500 cells).
 *
 * This module has no React dependencies and is consumed by the 3D
 * components (CellMesh, BondConnector, BoundaryWireframe) and by
 * the layout utility (src/utils/layout.ts).
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §6.1 (Cell Geometry)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Three.js Scene)
 *   - backend/src/Types.hs (Tiling enum)
 */

import {
  BoxGeometry,
  BufferGeometry,
  ExtrudeGeometry,
  PlaneGeometry,
  Shape,
  SphereGeometry,
} from "three";

import type { Tiling } from "../types";

// ════════════════════════════════════════════════════════════════
//  Constants — Faces Per Cell
// ════════════════════════════════════════════════════════════════

/**
 * Number of faces (edges in 2D) per cell for each tiling type.
 *
 * Matches the boundary area decomposition formula used by the
 * Python oracle and the Haskell backend:
 *
 *   area(A) = facesPerCell · |A| − 2 · |internal links within A|
 *
 * Tree uses 0 as a sentinel — it has no face-count area model
 * (the tree pilot uses a simplified `2k` proxy).
 */
export const FACES_PER_CELL: Readonly<Record<Tiling, number>> = {
  Tiling435: 6, // cube: 6 square faces
  Tiling54: 5, // pentagon: 5 edges
  Tiling53: 5, // pentagon: 5 edges
  Tiling44: 4, // square: 4 edges
  Tree: 0, // 1D tree: no face-count model
};

// ════════════════════════════════════════════════════════════════
//  Constants — Cell Sizing
// ════════════════════════════════════════════════════════════════

/**
 * Default cell radius/scale for each tiling type (in world units).
 *
 * The force-directed layout ({@link ../utils/layout.ts}) uses a
 * spring distance of ~2 units between adjacent cells, so a
 * radius of ~0.5 avoids overlap while leaving visible gaps for
 * bond connectors.
 *
 * - Tiling435: half-width of the cube
 * - Tiling54/53: circumradius of the regular pentagon
 * - Tiling44: half-width of the square
 * - Tree: sphere radius (smaller for graph nodes)
 */
export const CELL_RADIUS: Readonly<Record<Tiling, number>> = {
  Tiling435: 0.5,
  Tiling54: 0.5,
  Tiling53: 0.5,
  Tiling44: 0.5,
  Tree: 0.3,
};

/**
 * Extrusion depth for 2D tilings (pentagons, squares).
 *
 * A small depth gives the cells visual presence in the 3D
 * viewport without obscuring the planarity of 2D patches.
 */
const EXTRUDE_DEPTH = 0.1;

// ════════════════════════════════════════════════════════════════
//  Constants — Display Labels
// ════════════════════════════════════════════════════════════════

/**
 * Human-readable display name for each tiling type.
 * Used in page headings, cards, tooltips, and the region inspector.
 */
export const TILING_DISPLAY_NAME: Readonly<Record<Tiling, string>> = {
  Tiling54: "{5,4} Hyperbolic Pentagonal",
  Tiling435: "{4,3,5} Hyperbolic Cubic",
  Tiling53: "{5,3} Spherical Dodecahedral",
  Tiling44: "{4,4} Euclidean Square",
  Tree: "Binary Tree",
};

/**
 * Short Schläfli symbol for each tiling type.
 * Used where horizontal space is limited (patch cards, badges,
 * table cells).
 */
export const TILING_SYMBOL: Readonly<Record<Tiling, string>> = {
  Tiling54: "{5,4}",
  Tiling435: "{4,3,5}",
  Tiling53: "{5,3}",
  Tiling44: "{4,4}",
  Tree: "Tree",
};

// ════════════════════════════════════════════════════════════════
//  Constants — Dimensional Classification
// ════════════════════════════════════════════════════════════════

/**
 * Whether a tiling should be laid out in 2D (XY plane, z=0).
 *
 * 2D patches ({5,4}, {5,3}, {4,4}, Tree) use a 2-dimensional
 * force-directed simulation. 3D patches ({4,3,5}) use a full
 * 3-dimensional simulation.
 *
 * This flag is consumed by:
 * - `src/utils/layout.ts` to choose the simulation dimension
 * - `PatchScene.tsx` to orient the camera
 */
export const TILING_IS_2D: Readonly<Record<Tiling, boolean>> = {
  Tiling54: true,
  Tiling435: false,
  Tiling53: true,
  Tiling44: true,
  Tree: true,
};

// ════════════════════════════════════════════════════════════════
//  Pentagon Shape
// ════════════════════════════════════════════════════════════════

/**
 * Create a regular pentagon {@link Shape} for use with
 * {@link ExtrudeGeometry}.
 *
 * The pentagon is inscribed in a circle of the given radius,
 * centered at the origin, with the first vertex pointing upward
 * (+Y direction). Vertices proceed counter-clockwise as required
 * by Three.js for correct face winding.
 *
 * @param radius - Circumradius of the pentagon (distance from
 *   center to any vertex)
 * @returns A Three.js Shape tracing the pentagon outline
 */
export function createPentagonShape(radius: number): Shape {
  const shape = new Shape();
  const sides = 5;
  // Start at the top (−π/2 = 12 o'clock position)
  const startAngle = -Math.PI / 2;

  for (let i = 0; i < sides; i++) {
    const angle = startAngle + (2 * Math.PI * i) / sides;
    const x = radius * Math.cos(angle);
    const y = radius * Math.sin(angle);
    if (i === 0) {
      shape.moveTo(x, y);
    } else {
      shape.lineTo(x, y);
    }
  }
  shape.closePath();
  return shape;
}

/**
 * Compute the vertices of a regular pentagon in the XY plane.
 *
 * Returns an array of 5 `[x, y]` coordinate pairs. Useful for
 * rendering wireframe outlines or computing edge midpoints for
 * boundary face indicators.
 *
 * @param radius - Circumradius of the pentagon
 * @returns Array of 5 vertex positions as [x, y] tuples
 */
export function pentagonVertices(
  radius: number
): [number, number][] {
  const sides = 5;
  const startAngle = -Math.PI / 2;
  const vertices: [number, number][] = [];

  for (let i = 0; i < sides; i++) {
    const angle = startAngle + (2 * Math.PI * i) / sides;
    vertices.push([
      radius * Math.cos(angle),
      radius * Math.sin(angle),
    ]);
  }
  return vertices;
}

// ════════════════════════════════════════════════════════════════
//  Geometry Cache
// ════════════════════════════════════════════════════════════════

/**
 * Cached geometry instances, keyed by tiling type.
 *
 * Geometries are created on first access via {@link getCellGeometry}
 * and reused thereafter. This avoids creating duplicate GPU buffers
 * when many cells share the same base geometry (which they always
 * do within a single patch visualization).
 *
 * For InstancedMesh (>500 cells), sharing a single geometry is
 * mandatory for the performance benefit.
 */
const geometryCache = new Map<Tiling, BufferGeometry>();

/**
 * Create the cell geometry for a given tiling type.
 *
 * Internal factory function — consumers should use
 * {@link getCellGeometry} which adds caching.
 */
function createCellGeometry(tiling: Tiling): BufferGeometry {
  switch (tiling) {
    case "Tiling435": {
      // Cube: standard unit cube scaled by CELL_RADIUS
      const size = CELL_RADIUS.Tiling435 * 2;
      return new BoxGeometry(size, size, size);
    }

    case "Tiling54":
    case "Tiling53": {
      // Pentagon: extruded regular pentagon in the XY plane.
      // ExtrudeGeometry extrudes along +Z from z=0 to z=depth.
      const shape = createPentagonShape(CELL_RADIUS[tiling]);
      return new ExtrudeGeometry(shape, {
        depth: EXTRUDE_DEPTH,
        bevelEnabled: false,
        steps: 1,
      });
    }

    case "Tiling44": {
      // Square: flat plane with small extrusion for visibility.
      // Using PlaneGeometry for true 2D flatness.
      const size = CELL_RADIUS.Tiling44 * 2;
      return new PlaneGeometry(size, size);
    }

    case "Tree": {
      // Tree nodes: small spheres (graph nodes, not tiles).
      // 16 width segments, 12 height segments — sufficient for
      // the small radius without excessive triangle count.
      return new SphereGeometry(CELL_RADIUS.Tree, 16, 12);
    }
  }
}

/**
 * Get (or create and cache) the cell geometry for a tiling type.
 *
 * Returns a shared {@link BufferGeometry} instance. The caller
 * must **not** dispose this geometry — it is shared across all
 * cells of the same tiling type within the application lifetime.
 *
 * For patches with >500 cells, pass this geometry to
 * `InstancedMesh` for optimal draw-call performance (one draw
 * call for all cells instead of one per cell).
 *
 * @param tiling - The tiling type to get geometry for
 * @returns A shared BufferGeometry instance
 *
 * @example
 * ```tsx
 * // In a React Three Fiber component:
 * const geometry = getCellGeometry(patch.patchTiling);
 * return <mesh geometry={geometry} />;
 * ```
 */
export function getCellGeometry(tiling: Tiling): BufferGeometry {
  const cached = geometryCache.get(tiling);
  if (cached) return cached;

  const geometry = createCellGeometry(tiling);
  geometryCache.set(tiling, geometry);
  return geometry;
}

/**
 * Dispose all cached geometries and clear the cache.
 *
 * Call this during application teardown or when fundamentally
 * switching visualization modes. In normal operation (navigating
 * between patches), the cache should persist — different patches
 * of the same tiling type share the same geometry.
 */
export function disposeCachedGeometries(): void {
  for (const geometry of geometryCache.values()) {
    geometry.dispose();
  }
  geometryCache.clear();
}

// ════════════════════════════════════════════════════════════════
//  Geometry Positioning Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Z-axis offset needed to center a cell geometry at the origin.
 *
 * {@link ExtrudeGeometry} extrudes along +Z starting at z=0, so
 * pentagonal cell geometry has its center at z=EXTRUDE_DEPTH/2
 * rather than z=0. This function returns the offset to apply so
 * the visual center of the cell aligns with the layout position.
 *
 * BoxGeometry, SphereGeometry, and PlaneGeometry are already
 * centered at the origin and return 0.
 *
 * @param tiling - The tiling type
 * @returns Z-offset to add to the mesh position (negative for
 *   pentagon tilings, 0 for others)
 */
export function getCellZOffset(tiling: Tiling): number {
  switch (tiling) {
    case "Tiling54":
    case "Tiling53":
      return -EXTRUDE_DEPTH / 2;
    case "Tiling435":
    case "Tiling44":
    case "Tree":
      return 0;
  }
}

/**
 * Bounding radius of a cell for a given tiling type.
 *
 * This is the maximum distance from the cell center to any vertex
 * of the cell geometry (in world units). Used for:
 *
 * - Hit testing / click detection radius
 * - Bond connector endpoint placement (stop the cylinder short
 *   of the cell surface)
 * - Camera distance calculations for auto-framing
 *
 * @param tiling - The tiling type
 * @returns The bounding radius in world units
 */
export function getCellBoundingRadius(tiling: Tiling): number {
  switch (tiling) {
    case "Tiling435": {
      // Cube: center to corner = halfSize × √3
      const halfSize = CELL_RADIUS.Tiling435;
      return halfSize * Math.sqrt(3);
    }
    case "Tiling54":
    case "Tiling53":
      // Pentagon: circumradius IS the definition of CELL_RADIUS
      return CELL_RADIUS[tiling];
    case "Tiling44":
      // Square: center to corner = halfSize × √2
      return CELL_RADIUS.Tiling44 * Math.SQRT2;
    case "Tree":
      // Sphere: radius
      return CELL_RADIUS.Tree;
  }
}

/**
 * Whether to use InstancedMesh for a given cell count.
 *
 * The frontend spec (§6.3) mandates InstancedMesh for patches
 * with >500 boundary cells. Below that threshold, individual
 * `<mesh>` elements are acceptable and simpler to work with
 * (especially for click interaction and selection glow).
 *
 * @param cellCount - Number of cells to render
 * @returns `true` if InstancedMesh should be used
 */
export function shouldUseInstancing(cellCount: number): boolean {
  return cellCount > 500;
}