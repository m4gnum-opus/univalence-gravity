/**
 * Cell-position & per-cell-transform computation for holographic
 * patch visualization.
 *
 * **UPDATED (Roadmap Steps 2–3 — centred Poincaré projection):**
 * 
 * **UPDATED (post-Poincaré review, Fix C — quaternion wiring):**
 *
 *   `NodeTransform` now carries the per-cell rotation quaternion
 *   emitted by the Python exporter (`GraphNode.qx/qy/qz/qw`) in
 *   addition to the position and conformal scale.  Downstream
 *   components (`PatchScene` → `<group>` wrappers / `InstancedMesh`
 *   `dummy.quaternion`) can now apply the correct Shepperd–Shuster
 *   rotation extracted from the boosted Jacobian of the Poincaré
 *   projection, fixing the "squished on one side" artefact on
 *   asymmetric patches (layer-54-dX Dense-growth patches).
 *
 *   Two changes relative to the previous revision:
 *
 *   1. **Per-cell scale is now carried alongside position.**  The
 *      new `NodeTransform` type bundles `{pos, scale}` — the
 *      Poincaré position in scene units AND the conformal scale
 *      factor  s(u) = (1 − |u|²) / 2  that the Python oracle
 *      attaches to every `GraphNode`.  `computePatchLayout` and
 *      `readExportedPositions` now return `Map<number, NodeTransform>`
 *      so downstream components (PatchScene → CellMesh /
 *      InstancedMesh → BoundaryWireframe) can apply the correct
 *      per-cell rescaling for an Escher-style Poincaré disc/ball
 *      rendering.
 *
 *   2. **Destructive uniform rescaling removed.**  The old
 *      scale  `targetExtent / maxRaw`  stretched the outermost cell
 *      to a fixed scene extent regardless of what else was happening
 *      in the patch, distorting the conformal geometry produced by
 *      the centring Lorentz boost in `18_export_json.py`.  It is
 *      replaced by a scene-wide scale that depends only on cell
 *      count:
 *
 *        scale = max(5, √(cellCount) × 1.5)
 *
 *      This leaves the relative geometry of the projected coordinates
 *      untouched (cells near the centre still sit at |u| ≈ 0, cells
 *      near the boundary still sit at |u| → 1) and merely chooses a
 *      viewport-appropriate global magnification.  Combined with the
 *      Lorentz boost that places the fundamental cell at the apex,
 *      this makes the identity cell land at the origin of the
 *      rendered scene (verified: g = I → u = 0 → pos = (0, 0, 0)).
 *
 * **The visual fix (unchanged from previous revision):**
 *
 *   The Python oracle (`18_export_json.py`) computes Poincaré
 *   projections of the Coxeter cell/tile centres for all patches
 *   (3D ball for {4,3,5}, 2D disk for {5,4}, manual 2D layouts for
 *   tree/star/filled/desitter).  `computePatchLayout` reads these
 *   coordinates directly and skips the force simulation entirely
 *   — force-directed layouts cannot embed exponentially growing
 *   hyperbolic graphs in Euclidean space without crumpling them
 *   into hairballs.
 *
 *   The force-directed simulation is retained only as a fallback
 *   for the (unusual) case where the exported JSON has all-zero
 *   coordinates.
 *
 * **Caching (fallback path only):**
 *
 *   The sessionStorage cache key has been bumped from `v4` → `v5`
 *   because the cached payload now stores `NodeTransform` objects
 *   carrying a rotation quaternion alongside position and scale.
 *   Any v3/v4 caches left behind by earlier builds are effectively
 *   invalidated and will be repopulated from scratch.
 *
 * @module
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §9 (Layout Algorithm)
 *   - docs Roadmap "Centre Patches in Poincaré Projection" §§1–3
 *   - Rules §5 (Cell Layout Strategy)
 */

import type { Patch, Region, Tiling } from "../types";

// d3-force-3d provides the Barnes-Hut force simulation (O(n log n))
// needed as a fallback when no geometric coordinates are available.
//
// @ts-expect-error d3-force-3d ships no TypeScript type declarations
import { forceSimulation, forceLink, forceManyBody, forceCenter } from "d3-force-3d";


// ════════════════════════════════════════════════════════════════
//  Public Types
// ════════════════════════════════════════════════════════════════

/**
 * Per-cell transform emitted by {@link computePatchLayout} and
 * consumed by the 3D rendering components.
 *
 * Fields:
 *
 *   - **`pos`** — the cell centre in scene coordinates, ready to
 *     be passed straight to a Three.js mesh's `.position`.  Derived
 *     from the Poincaré-projected coordinate (or a fallback force
 *     layout) scaled by a viewport-appropriate global factor.
 *
 *   - **`scale`** — the conformal scale factor
 *     `s(u) = (1 − |u|²) / 2` at the cell's Poincaré position,
 *     clamped to 1e-6 near the boundary to avoid zero-scale
 *     degeneracy.  Per roadmap Step 2, this is the correct
 *     per-cell magnification for an Escher-style Poincaré
 *     rendering: cells at the centre have `scale ≈ 0.5`, cells
 *     near the boundary have `scale → 0`.
 *
 *     In the force-directed fallback path (when the exporter
 *     emitted all-zero coordinates) there is no meaningful
 *     conformal structure, so `scale` defaults to 1.0 and the
 *     quaternion defaults to the identity (no rotation).
 *
 *   - **`quat`** — the unit quaternion `(qx, qy, qz, qw)` encoding
 *     the cell's rotation relative to the fundamental cell.  For
 *     2D patches this is a z-axis rotation (only `qz` and `qw`
 *     are non-zero); for 3D patches it is the Shepperd–Shuster
 *     conversion of the rotation extracted from the boosted
 *     Jacobian of the Poincaré projection by `18_export_json.py`.
 *
 *     Without this data in the transform, PatchScene has no way
 *     to align cells to the hyperbolic geodesics of the tiling
 *     and asymmetric patches (layer-54-dX) render with a visible
 *     "squish" because each cell faces the reference direction
 *     regardless of where it sits in the Poincaré ball/disk.
 *
 *     In the force-directed fallback path the quaternion defaults
 *     to the identity `[0, 0, 0, 1]` since there is no hyperbolic
 *     structure to align to.
 */
export interface NodeTransform {
  /** Scene-space position (ready for THREE.Object3D.position). */
  pos: [number, number, number];
  /** Conformal scale factor at this cell's Poincaré position. */
  scale: number;
  /**
   * Unit rotation quaternion `(qx, qy, qz, qw)` for this cell,
   * ready to be passed to `THREE.Object3D.quaternion.set(...)`.
   */
  quat: [number, number, number, number];
}


// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/** Spring rest-length between connected cells (fallback path, in scene units). */
const LINK_DISTANCE = 2;

/** Hooke's law spring constant for link force (fallback path). */
const LINK_STRENGTH = 1;

/**
 * Coulomb repulsion strength (fallback path).  Negative = repulsive.
 */
const CHARGE_STRENGTH = -30;

/** Number of synchronous simulation ticks (fallback path only). */
const ITERATIONS = 300;

/**
 * sessionStorage key prefix for cached fallback layouts.
 *
 * Bumped from `v4` → `v5` because the cached payload schema now
 * stores `NodeTransform` objects carrying a rotation quaternion
 * in addition to position and conformal scale.  Older `v3`/`v4`
 * entries are orphaned but harmless — sessionStorage is cleared
 * on browser restart.
 */
const CACHE_PREFIX = "ugrav-layout-v5-";

/**
 * Default conformal scale used on the force-layout fallback path.
 *
 * The force simulation produces Euclidean positions with no
 * hyperbolic structure, so there is no meaningful `(1 − |u|²) / 2`
 * to read off.  1.0 renders cells at their natural geometry size
 * (matching the pre-Poincaré behaviour of older builds).
 */
const FALLBACK_SCALE = 1.0;

/**
 * Identity quaternion used on the force-layout fallback path.
 *
 * `(qx, qy, qz, qw) = (0, 0, 0, 1)` represents "no rotation".  The
 * force simulation produces Euclidean positions with no hyperbolic
 * orientation structure, so every cell faces the reference
 * direction.
 */
const IDENTITY_QUAT: [number, number, number, number] = [0, 0, 0, 1];


// ════════════════════════════════════════════════════════════════
//  Graph-Based Extraction
// ════════════════════════════════════════════════════════════════

/**
 * Extract ALL physical bonds from the patch's bulk graph.
 *
 * Returns `patchGraph.pgEdges` directly — these are the true physical
 * bonds (shared faces in 3D, shared edges in 2D) between adjacent
 * cells, including interior-to-interior and interior-to-boundary bonds.
 *
 * @param patch - The full Patch object from `GET /patches/:name`.
 * @returns Array of `[cellA, cellB]` bond pairs (cellA < cellB).
 */
export function extractGraphBonds(patch: Patch): [number, number][] {
  return patch.patchGraph.pgEdges.map(
    (e): [number, number] => [e.source, e.target],
  );
}

/**
 * Extract ALL cell IDs from the patch's bulk graph.
 *
 * Returns the sorted list of ALL cell IDs including both boundary
 * cells (those appearing in regions) and interior cells (those with
 * all faces shared, appearing in no region).
 *
 * @param patch - The full Patch object from `GET /patches/:name`.
 * @returns Sorted array of ALL cell IDs in the patch.
 */
export function extractGraphCellIds(patch: Patch): number[] {
  return patch.patchGraph.pgNodes.map(n => n.id);
}


// ════════════════════════════════════════════════════════════════
//  Legacy Region-Based Extraction (kept for backward compat)
// ════════════════════════════════════════════════════════════════

/**
 * Extract unique cell IDs from a patch's boundary region data.
 *
 * **NOTE:** This function returns ONLY boundary cells — cells that
 * appear in at least one boundary region.  Interior cells (with all
 * faces shared) are NOT included.  For the full cell set, use
 * {@link extractGraphCellIds} instead.
 *
 * Kept for backward compatibility with components that still operate
 * on boundary-only data (e.g. singleton region filtering in PatchScene).
 *
 * @param regions - The patch's `patchRegionData` array.
 * @returns Sorted array of unique boundary cell IDs.
 */
export function extractCellIds(regions: Region[]): number[] {
  const cellSet = new Set<number>();
  for (const region of regions) {
    for (const cellId of region.regionCells) {
      cellSet.add(cellId);
    }
  }
  return Array.from(cellSet).sort((a, b) => a - b);
}

/**
 * Extract adjacency bonds from size-2 boundary regions.
 *
 * **NOTE:** This function returns ONLY boundary-to-boundary adjacency
 * inferred from size-2 regions.  It misses interior bonds entirely.
 * For the full physical bond set, use {@link extractGraphBonds} instead.
 *
 * Kept for backward compatibility.
 *
 * @param regions - The patch's `patchRegionData` array.
 * @returns Array of `[cellA, cellB]` adjacency pairs (cellA < cellB).
 */
export function extractBonds(regions: Region[]): [number, number][] {
  const seen = new Set<string>();
  const bonds: [number, number][] = [];

  for (const region of regions) {
    if (region.regionSize !== 2 || region.regionCells.length !== 2) {
      continue;
    }

    const first = region.regionCells[0];
    const second = region.regionCells[1];
    if (first === undefined || second === undefined) continue;

    const lo = Math.min(first, second);
    const hi = Math.max(first, second);
    const key = `${lo}-${hi}`;

    if (!seen.has(key)) {
      seen.add(key);
      bonds.push([lo, hi]);
    }
  }

  return bonds;
}


// ════════════════════════════════════════════════════════════════
//  Dimension Determination
// ════════════════════════════════════════════════════════════════

/**
 * Determine the force-simulation dimensionality from the tiling type.
 *
 * Used only in the force-layout fallback path.
 *
 * @param tiling - The patch's `patchTiling` value.
 * @returns `2` or `3` — the number of spatial dimensions for the simulation.
 */
export function getSimulationDimensions(tiling: Tiling): 2 | 3 {
  return tiling === "Tiling435" ? 3 : 2;
}


// ════════════════════════════════════════════════════════════════
//  Coordinate Detection and Scaling
// ════════════════════════════════════════════════════════════════

/**
 * Determine whether the exported node coordinates contain real
 * geometric data (Poincaré projections or manual layouts) or are
 * all zeros (the fallback when no geometry was computed).
 *
 * @param patch - The full Patch object.
 * @returns `true` if at least one node has a non-zero coordinate.
 */
function hasExportedCoordinates(patch: Patch): boolean {
  for (const node of patch.patchGraph.pgNodes) {
    if (node.x !== 0 || node.y !== 0 || node.z !== 0) {
      return true;
    }
  }
  return false;
}

/**
 * Read positions and per-cell scales directly from the exported
 * `patchGraph.pgNodes` and bundle them into `NodeTransform` entries.
 *
 * **Roadmap Step 3 — conformal-preserving global scale.**
 *
 *   The previous revision chose the global scene magnification as
 *   `targetExtent / maxRaw` — i.e. it stretched the outermost cell
 *   to a fixed scene extent.  With the centring Lorentz boost from
 *   Step 1 (which places the fundamental cell at the origin), this
 *   stretching destroys the conformal structure: the visible
 *   "Escher effect" disappears because the outermost cell is forced
 *   to the same apparent size no matter how many cells are between
 *   it and the centre.
 *
 *   The new scale depends only on cell count:
 *
 *     scale = max(5, √(cellCount) × 1.5)
 *
 *   This leaves the relative geometry of the Poincaré coordinates
 *   untouched — the origin stays at the origin, the boundary stays
 *   near `|u| = 1`, and the conformal compression near the boundary
 *   is preserved.  It just picks a viewport-appropriate overall
 *   magnification:
 *
 *     -   6 cells →   scale ≈ 5.0  (small manual layouts)
 *     - 100 cells →   scale = 15.0
 *     - 1000 cells →  scale ≈ 47.4
 *
 *   With the roadmap's Lorentz-boost centring in place, the identity
 *   cell projects to `(0, 0, 0)` in the Poincaré ball → scene
 *   position `scale × 0 = (0, 0, 0)`, so OrbitControls orbits the
 *   correct point and the patch is visually centred without any
 *   post-hoc translation.
 *
 * **Roadmap Step 2 — per-cell conformal scale.**
 *
 *   The exporter computes  s(u) = max((1 − |u|²) / 2, 1e-6)  per
 *   cell and stores it in `GraphNode.scale`.  We forward it
 *   unchanged in `NodeTransform.scale` so `CellMesh` /
 *   `InstancedMesh` can multiply their template geometry by it,
 *   giving the correct per-cell magnification for an Escher-style
 *   Poincaré rendering.
 * 
 * **Fix C — per-cell rotation quaternion.**
 *
 *   The exporter runs a Shepperd–Shuster conversion on the spatial
 *   block of each cell's boosted Lorentz matrix and stores the
 *   result in `GraphNode.qx/qy/qz/qw`.  We forward it unchanged in
 *   `NodeTransform.quat` so PatchScene can apply the rotation via
 *   `<group quaternion={...}>` (non-instanced path) or
 *   `dummy.quaternion.set(...)` (instanced path).
 *
 * @param patch - The full Patch object with non-zero coordinates.
 * @returns Map from cell ID to `NodeTransform`.
 */
function readExportedPositions(
  patch: Patch,
): Map<number, NodeTransform> {
  const nodes = patch.patchGraph.pgNodes;

  // Scene-appropriate global scale that grows gently with patch
  // size but does NOT depend on the raw coordinate extent — the
  // conformal geometry of the Poincaré projection is preserved.
  const scale = Math.max(5, Math.sqrt(nodes.length) * 2);

  const transforms = new Map<number, NodeTransform>();
  for (const node of nodes) {
    transforms.set(node.id, {
      pos: [
        node.x * scale,
        node.y * scale,
        node.z * scale,
      ],
      // Per-cell conformal scale factor (Roadmap Step 2).
      scale: node.scale,
      // Per-cell rotation quaternion (Fix C — Shepperd–Shuster).
      quat: [node.qx, node.qy, node.qz, node.qw],
    });
  }

  return transforms;
}


// ════════════════════════════════════════════════════════════════
//  Force-Directed Layout (Fallback)
// ════════════════════════════════════════════════════════════════

/**
 * Compute cell positions using a force-directed simulation.
 *
 * This is the FALLBACK path, used only when the exported JSON has
 * all-zero coordinates (i.e. no geometric data was available during
 * export).  In normal operation with the updated `18_export_json.py`,
 * this function is never called — positions are read directly from
 * the Poincaré-projected coordinates.
 *
 * The returned map is `Map<number, [x, y, z]>` (bare position triples),
 * preserving the pre-NodeTransform signature.  `computePatchLayout`
 * wraps the result in `NodeTransform` objects with `scale = 1.0`
 * before returning to the caller.
 *
 * Uses d3-force-3d with:
 *   - **Link force:** spring attraction along ALL physical bonds
 *   - **Charge force:** Barnes-Hut repulsion (O(n log n))
 *   - **Center force:** drift correction anchored at the origin
 *   - **300 synchronous iterations** (no animation — runs to completion)
 *
 * @param cellIds - Sorted array of ALL cell IDs to position.
 * @param bonds - Array of ALL `[cellA, cellB]` physical bonds.
 * @param numDimensions - `2` for 2D patches, `3` for 3D patches.
 * @returns Map from cell ID to `[x, y, z]` position in scene coordinates.
 */
export function computeCellPositions(
  cellIds: number[],
  bonds: [number, number][],
  numDimensions: 2 | 3,
): Map<number, [number, number, number]> {
  // Edge case: no cells.
  if (cellIds.length === 0) {
    return new Map();
  }

  // Edge case: single cell at the origin.
  if (cellIds.length === 1) {
    const singleId = cellIds[0];
    if (singleId !== undefined) {
      return new Map([[singleId, [0, 0, 0]]]);
    }
    return new Map();
  }

  // Build cell ID → array index mapping for link resolution.
  const idToIndex = new Map<number, number>();
  cellIds.forEach((id, i) => {
    idToIndex.set(id, i);
  });

  // Create node array with deterministic initial positions.
  const nodes = cellIds.map((id) => ({
    x: Math.sin(id * 127.1 + 0.5) * 0.5,
    y: Math.cos(id * 311.7 + 0.5) * 0.5,
    z: numDimensions === 3 ? Math.sin(id * 269.5 + 0.5) * 0.5 : 0,
  }));

  // Create link array referencing nodes by array index.
  const links: Array<{ source: number; target: number }> = [];
  for (const [a, b] of bonds) {
    const srcIdx = idToIndex.get(a);
    const tgtIdx = idToIndex.get(b);
    if (srcIdx !== undefined && tgtIdx !== undefined) {
      links.push({ source: srcIdx, target: tgtIdx });
    }
  }

  // Run the force-directed simulation synchronously.
  try {
    const sim = forceSimulation(nodes, numDimensions)
      .force(
        "link",
        forceLink(links).distance(LINK_DISTANCE).strength(LINK_STRENGTH),
      )
      .force("charge", forceManyBody().strength(CHARGE_STRENGTH))
      .force("center", forceCenter(0, 0, 0))
      .stop();

    for (let i = 0; i < ITERATIONS; i++) {
      sim.tick();
    }
  } catch (_err) {
    // If d3-force-3d fails at runtime, fall back to a circular/spherical layout.
    return fallbackLayout(cellIds, numDimensions);
  }

  // Read back mutated positions from the node array.
  const positions = new Map<number, [number, number, number]>();
  for (let i = 0; i < cellIds.length; i++) {
    const id = cellIds[i];
    const node = nodes[i];
    if (id === undefined || node === undefined) continue;

    const x = isFinite(node.x) ? node.x : 0;
    const y = isFinite(node.y) ? node.y : 0;
    const z = numDimensions === 3 && isFinite(node.z) ? node.z : 0;

    positions.set(id, [x, y, z]);
  }

  return positions;
}


// ════════════════════════════════════════════════════════════════
//  Fallback Layout
// ════════════════════════════════════════════════════════════════

/**
 * Produce a deterministic fallback layout when d3-force-3d is
 * unavailable or fails.
 *
 * - **2D:** Distributes cells evenly around a circle
 * - **3D:** Distributes cells on a Fibonacci sphere
 *
 * @param cellIds - Sorted array of unique cell IDs.
 * @param numDimensions - `2` or `3`.
 * @returns Map from cell ID to `[x, y, z]` position.
 */
function fallbackLayout(
  cellIds: number[],
  numDimensions: 2 | 3,
): Map<number, [number, number, number]> {
  const positions = new Map<number, [number, number, number]>();
  const n = cellIds.length;

  if (n === 0) return positions;

  const radius = Math.max(1, n * LINK_DISTANCE / (2 * Math.PI));
  const goldenAngle = Math.PI * (3 - Math.sqrt(5));

  for (let i = 0; i < n; i++) {
    const id = cellIds[i];
    if (id === undefined) continue;

    if (numDimensions === 2) {
      const angle = (2 * Math.PI * i) / n;
      positions.set(id, [
        radius * Math.cos(angle),
        radius * Math.sin(angle),
        0,
      ]);
    } else {
      const cosTheta = 1 - (2 * (i + 0.5)) / n;
      const sinTheta = Math.sqrt(1 - cosTheta * cosTheta);
      const phi = goldenAngle * i;

      positions.set(id, [
        radius * sinTheta * Math.cos(phi),
        radius * sinTheta * Math.sin(phi),
        radius * cosTheta,
      ]);
    }
  }

  return positions;
}


// ════════════════════════════════════════════════════════════════
//  Position → NodeTransform wrapper
// ════════════════════════════════════════════════════════════════

/**
 * Wrap a bare-position map into a `NodeTransform` map with the
 * fallback default scale.
 *
 * Used on the force-layout code path — those paths produce
 * Euclidean positions with no conformal structure AND no
 * hyperbolic orientation, so every cell gets
 * `scale = FALLBACK_SCALE` and the identity quaternion
 * (`quat = [0, 0, 0, 1]`).  PatchScene will then render each
 * cell at its template size facing the reference direction —
 * the best approximation available when the exporter could not
 * provide geometric data.
 */
function positionsToTransforms(
  positions: Map<number, [number, number, number]>,
): Map<number, NodeTransform> {
  const transforms = new Map<number, NodeTransform>();
  for (const [id, pos] of positions) {
    transforms.set(id, { pos, scale: FALLBACK_SCALE, quat: IDENTITY_QUAT });
  }
  return transforms;
}


// ════════════════════════════════════════════════════════════════
//  sessionStorage Cache (for force-layout fallback path)
// ════════════════════════════════════════════════════════════════

/**
 * Serializable cache format stored in sessionStorage under the
 * current (v5) prefix.
 *
 * Stores the full `NodeTransform` per cell — position, scale, AND
 * rotation quaternion.  The force-layout fallback emits
 * `scale = FALLBACK_SCALE` for every cell, but we still round-trip
 * all three fields so the cache's on-disk schema matches the
 * in-memory type and any future code that populates the fallback
 * with non-trivial rotations/scales will cache correctly without
 * another key bump.
 */
interface CachedLayoutV5 {
  transforms: Record<string, NodeTransform>;
}

/**
 * Attempt to load a cached layout from sessionStorage.
 *
 * Used only in the force-layout fallback path.
 *
 * @param patchName - The patch name.
 * @param expectedNodeCount - The number of nodes expected.
 * @returns The cached transform map, or `null` on cache miss.
 */
function getCachedLayout(
  patchName: string,
  expectedNodeCount: number,
): Map<number, NodeTransform> | null {
  try {
    const key = CACHE_PREFIX + patchName + "-" + expectedNodeCount;
    const raw = sessionStorage.getItem(key);
    if (raw === null) return null;

    const cached: CachedLayoutV5 = JSON.parse(raw) as CachedLayoutV5;
    if (
      typeof cached !== "object" ||
      cached === null ||
      typeof cached.transforms !== "object" ||
      cached.transforms === null
    ) {
      return null;
    }

    const map = new Map<number, NodeTransform>();
    for (const [idStr, value] of Object.entries(cached.transforms)) {
      const id = Number(idStr);
      if (isNaN(id) || typeof value !== "object" || value === null) continue;

      const pos = value.pos;
      const scale = value.scale;
      const quat = value.quat;
      if (
        Array.isArray(pos) &&
        pos.length === 3 &&
        pos.every((v) => typeof v === "number" && isFinite(v)) &&
        typeof scale === "number" &&
        isFinite(scale) &&
        Array.isArray(quat) &&
        quat.length === 4 &&
        quat.every((v) => typeof v === "number" && isFinite(v))
      ) {
        map.set(id, {
          pos: pos as [number, number, number],
          scale,
          quat: quat as [number, number, number, number],
        });
      }
    }

    if (map.size !== expectedNodeCount) {
      return null;
    }

    return map;
  } catch {
    return null;
  }
}

/**
 * Store a computed layout in sessionStorage for later reuse.
 *
 * Used only in the force-layout fallback path.
 */
function setCachedLayout(
  patchName: string,
  nodeCount: number,
  transforms: Map<number, NodeTransform>,
): void {
  try {
    const obj: Record<string, NodeTransform> = {};
    for (const [id, t] of transforms) {
      obj[String(id)] = t;
    }
    const payload: CachedLayoutV5 = { transforms: obj };
    const key = CACHE_PREFIX + patchName + "-" + nodeCount;
    sessionStorage.setItem(key, JSON.stringify(payload));
  } catch {
    // sessionStorage full or unavailable — silently ignore.
  }
}

/**
 * Clear the cached layout for a specific patch, or all cached
 * layouts if no name is given.
 *
 * Matches any historical cache prefix (`ugrav-layout-...`) so that
 * users migrating from older builds don't get stuck with orphaned
 * pre-v4 entries.
 *
 * @param patchName - If provided, clear all caches for this patch.
 *   If omitted, clear all layout caches.
 */
export function clearLayoutCache(patchName?: string): void {
  try {
    const keysToRemove: string[] = [];
    for (let i = 0; i < sessionStorage.length; i++) {
      const key = sessionStorage.key(i);
      if (key === null) continue;

      if (patchName !== undefined) {
        // Match any historical version of the cache for this patch.
        if (
          key.startsWith(CACHE_PREFIX + patchName + "-") ||
          key.startsWith("ugrav-layout-v4-" + patchName + "-") ||
          key.startsWith("ugrav-layout-v3-" + patchName + "-") ||
          key.startsWith("ugrav-layout-" + patchName)
        ) {
          keysToRemove.push(key);
        }
      } else {
        if (key.startsWith("ugrav-layout-")) {
          keysToRemove.push(key);
        }
      }
    }
    for (const key of keysToRemove) {
      sessionStorage.removeItem(key);
    }
  } catch {
    // sessionStorage unavailable — nothing to clear.
  }
}


// ════════════════════════════════════════════════════════════════
//  High-Level API
// ════════════════════════════════════════════════════════════════

/**
 * Compute (or read from exported data) per-cell transforms for a patch.
 *
 * **This is the primary entry point for the PatchScene component.**
 *
 * Pipeline:
 *
 * 1. Check if the patch's `patchGraph.pgNodes` contain real geometric
 *    coordinates (at least one non-zero x/y/z value).
 * 2. If YES (normal case): read coordinates directly from the exported
 *    Poincaré projections, apply a conformal-preserving global scale
 *    (Roadmap Step 3), and return per-cell `NodeTransform` objects
 *    carrying both the scaled position and the exporter-computed
 *    conformal factor (Roadmap Step 2).  **No force simulation is run.**
 * 3. If NO (fallback — all coordinates are zero): extract cell IDs and
 *    bonds, determine 2D/3D, run the force-directed simulation, wrap
 *    the resulting positions in `NodeTransform` objects with
 *    `scale = FALLBACK_SCALE`, cache the result, and return.
 *
 * The returned map contains one entry per cell in the patch — both
 * boundary cells (rendered with data-driven colors) AND interior cells
 * (rendered with neutral gray).
 *
 * @param patch - The full `Patch` object from `GET /patches/:name`.
 * @returns Map from cell ID to `NodeTransform` in scene units.
 *
 * @example
 * ```tsx
 * const transforms = computePatchLayout(patch);
 * // transforms.size === patch.patchCells (ALL cells)
 * const t = transforms.get(cellId);
 * if (t) {
 *   mesh.position.set(...t.pos);
 *   mesh.scale.setScalar(t.scale);
 *   mesh.quaternion.set(...t.quat);
 * }
 * ```
 */
export function computePatchLayout(
  patch: Patch,
): Map<number, NodeTransform> {
  // ── Primary path: use exported geometric coordinates ──────────
  //
  // The Python export (18_export_json.py) computes Poincaré
  // ball/disk projections for all Coxeter-grown patches, and
  // manual 2D layouts for hand-built patches (tree, star, filled,
  // desitter).  Combined with the centring Lorentz boost (Roadmap
  // Step 1) this produces geometrically accurate visualisations
  // that respect the hyperbolic/spherical structure of the tilings
  // and correctly place the fundamental cell at the scene origin.
  if (hasExportedCoordinates(patch)) {
    return readExportedPositions(patch);
  }

  // ── Fallback path: force-directed layout ──────────────────────
  //
  // Used only when the exported JSON has all-zero coordinates,
  // which indicates that no geometric data was available during
  // export.  In normal operation with the updated
  // 18_export_json.py this path is never reached, but it provides
  // a safe degradation mode.

  const cellIds = patch.patchGraph.pgNodes.map(n => n.id);
  const bonds = extractGraphBonds(patch);
  const nodeCount = cellIds.length;

  // Check sessionStorage cache (force-layout results are expensive).
  const cached = getCachedLayout(patch.patchName, nodeCount);
  if (cached !== null) {
    return cached;
  }

  // Determine simulation dimensionality from tiling type.
  const numDimensions = getSimulationDimensions(patch.patchTiling);

  // Run force-directed layout on the full bulk graph, then wrap
  // each position in a NodeTransform with the fallback scale.
  const positions = computeCellPositions(cellIds, bonds, numDimensions);
  const transforms = positionsToTransforms(positions);

  // Cache for subsequent visits.
  setCachedLayout(patch.patchName, nodeCount, transforms);

  return transforms;
}