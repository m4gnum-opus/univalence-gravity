/**
 * TypeScript interfaces mirroring the Haskell backend's Types.hs
 * and the JSON schema produced by 18_export_json.py.
 *
 * IMPORTANT: Field names must match the exact JSON keys from the API.
 * Do not rename fields — the Haskell backend uses Aeson's generic
 * derivation (with prefix stripping for GraphNode, CurvatureSummary
 * and Meta), and these interfaces must decode the JSON responses as-is.
 *
 * Reference:
 *   - backend/src/Types.hs (Haskell domain model)
 *   - sim/prototyping/18_export_json.py (JSON export)
 *   - docs/engineering/backend-spec-haskell.md §3 (Data Model)
 *   - docs/engineering/frontend-spec-webgl.md §3.2 (TypeScript Types)
 */

// ════════════════════════════════════════════════════════════════
//  Enumerations
// ════════════════════════════════════════════════════════════════

/**
 * Tiling type (Schläfli symbol or structural label).
 *
 * Encoded as a plain JSON string by Haskell's generic nullary-
 * constructor encoding (allNullaryToStringTag = True).
 *
 * - Tiling54  — {5,4} hyperbolic pentagonal (2D)
 * - Tiling435 — {4,3,5} hyperbolic cubic honeycomb (3D)
 * - Tiling53  — {5,3} spherical dodecahedral (2D)
 * - Tiling44  — {4,4} Euclidean square grid (2D, numerical only)
 * - Tree      — 1D weighted binary tree (pilot instance)
 */
export type Tiling = "Tiling54" | "Tiling435" | "Tiling53" | "Tiling44" | "Tree";

/**
 * Patch growth strategy used by the Python oracle.
 *
 * - BFS        — Concentric BFS shells from the central cell
 * - Dense      — Greedy: add the frontier cell with most neighbours
 * - Geodesic   — Tube along a geodesic spine + 1-shell fattening
 * - Hemisphere — Half-space BFS (3 of 6 face crossings)
 */
export type GrowthStrategy = "BFS" | "Dense" | "Geodesic" | "Hemisphere";

/**
 * Verification status of a theorem in the canonical registry.
 *
 * - Verified  — Type-checked by Cubical Agda 2.8.0
 * - Dead      — Superseded by a generic theorem; dead code
 * - Numerical — Numerically confirmed by the Python oracle only
 */
export type TheoremStatus = "Verified" | "Dead" | "Numerical";

/**
 * Color mode for the Patch Viewer's cell coloring.
 *
 * This is a frontend-only type (not present in the backend schema).
 * See docs/engineering/frontend-spec-webgl.md §5.3.3.
 */
export type ColorMode = "mincut" | "regionSize" | "ratio" | "curvature";

// ════════════════════════════════════════════════════════════════
//  Region
// ════════════════════════════════════════════════════════════════

/**
 * A single cell-aligned boundary region within a patch.
 *
 * JSON keys match the Haskell field names verbatim.
 * Mirrors: Types.hs Region
 */
export interface Region {
  /** Unique index within the patch */
  regionId: number;
  /** Sorted cell IDs in this region */
  regionCells: number[];
  /** Number of cells (= regionCells.length) */
  regionSize: number;
  /** S(A) — boundary min-cut entropy */
  regionMinCut: number;
  /** Boundary surface area (face-count) */
  regionArea: number;
  /** Orbit representative label, e.g. "mc3" */
  regionOrbit: string;
  /** area − 2·S; null if not computed */
  regionHalfSlack: number | null;
  /** S / area */
  regionRatio: number;
  /**
   * Average curvature of adjacent vertices (2D) or edges (3D).
   *
   * Computed by 18_export_json.py as a per-cell aggregation:
   *   - 3D ({4,3,5}): mean of 12 edge-curvature values (κ₂₀/20)
   *     for each cell, then averaged across the region's cells.
   *   - 2D (filled, desitter): hardcoded per-tile average from
   *     known vertex-class curvatures.
   *
   * null when curvature data is unavailable for the patch
   * (e.g. tree, star, layer-54 patches).
   */
  regionCurvature: number | null;
}

// ════════════════════════════════════════════════════════════════
//  GraphNode
// ════════════════════════════════════════════════════════════════

/**
 * A single node in the bulk graph, carrying its cell ID,
 * Poincaré-projected spatial coordinates, a rotation quaternion,
 * and a conformal scale factor.
 *
 * The coordinates are computed by 18_export_json.py via
 * hyperboloid → Poincaré ball/disk projection of the Coxeter
 * cell/tile centers. The projection applies a Lorentz boost
 * (`_lorentz_boost_to_apex`) so the fundamental cell lands at
 * the origin of the ball — with this centring, `g = I` projects
 * to `(0, 0, 0)` and the patch is visually centred on the
 * viewport without relying on post-hoc rescaling.
 *
 * **Field schema (uniform across all patches):**
 *
 *   - **id**: Cell or tile identifier (matches entries in `pgEdges`).
 *   - **x, y, z**: Coordinates in the Poincaré ball (3D) or disk
 *     embedded as `z = 0` (2D). Always in the open unit ball:
 *     `x² + y² + z² < 1`.
 *   - **qx, qy, qz, qw**: Unit quaternion for the cell's rotation
 *     relative to the fundamental cell. For 2D patches this is a
 *     z-axis rotation (only `qz` and `qw` are non-zero); for 3D
 *     patches it is the full Shepperd–Shuster conversion of the
 *     rotation extracted from the (boosted) Jacobian of the
 *     projection. Hand-written 2D layouts (tree, star, filled,
 *     desitter) use the identity quaternion `(0, 0, 0, 1)`.
 *   - **scale**: Conformal scale factor `s(u) = (1 − |u|²) / 2`
 *     where `u = (x, y, z)`. This is the correct per-cell scaling
 *     for an Escher-style Poincaré rendering: cells at the centre
 *     have `s ≈ 0.5`, cells near the boundary have `s → 0`.
 *     Clamped to `1e-6` to avoid zero-scale degeneracy at the
 *     boundary.
 *
 * For hand-built patches (tree, star, filled, desitter) the
 * coordinates are manually assigned 2D layouts. For patches where
 * no geometric data is available, all coordinates default to
 * (0, 0, 0), the quaternion defaults to the identity, and the
 * scale is derived from the conformal formula (or clamped).
 *
 * The JSON keys are "id", "x", "y", "z", "qx", "qy", "qz", "qw",
 * "scale" — the Haskell field prefix "gn" is stripped by a custom
 * Aeson Options using dropFieldPrefix.
 *
 * Mirrors: Types.hs GraphNode (with gn prefix stripped)
 */
export interface GraphNode {
  /** Cell ID (matches entries in pgEdges) */
  id: number;
  /** Poincaré x-coordinate */
  x: number;
  /** Poincaré y-coordinate */
  y: number;
  /** Poincaré z-coordinate (0.0 for 2D patches) */
  z: number;
  /** Rotation quaternion — x component */
  qx: number;
  /** Rotation quaternion — y component */
  qy: number;
  /** Rotation quaternion — z component */
  qz: number;
  /** Rotation quaternion — w (real) component */
  qw: number;
  /** Conformal scale factor s(u) = (1 − |u|²) / 2 */
  scale: number;
}

// ════════════════════════════════════════════════════════════════
//  Edge
// ════════════════════════════════════════════════════════════════

/**
 * A single undirected bond in a {@link PatchGraph}, serialised on
 * the wire as `{"source": <id>, "target": <id>}`.
 *
 * Mirrors the Haskell `Edge` record in `backend/src/Types.hs`, which
 * strips the `"edge"` field prefix via Aeson so the JSON keys match
 * here verbatim. The exporter guarantees `source <= target`.
 */
export interface Edge {
  source: number;
  target: number;
}

// ════════════════════════════════════════════════════════════════
//  PatchGraph (Bulk Graph)
// ════════════════════════════════════════════════════════════════

/**
 * The full bulk graph of a patch: all cells as nodes (with
 * projected spatial coordinates, quaternions, and conformal
 * scales) and all physical bonds (shared faces in 3D, shared
 * edges in 2D) as edges.
 *
 * This is the data the frontend needs to render the 3D holographic
 * representation correctly. Without it, the frontend can only
 * infer nodes and edges from the boundary region data, which
 * misses interior cells (cells with zero boundary legs that
 * appear in no region) and misinterprets boundary adjacency as
 * physical bonds.
 *
 * **pgNodes:** Sorted list of {@link GraphNode} objects, each
 * carrying a cell ID, Poincaré-projected (x, y, z) coordinates,
 * a rotation quaternion (qx, qy, qz, qw), and a conformal scale.
 * For a Dense-100 patch this contains 100 nodes. Includes both
 * boundary cells (those appearing in at least one region's
 * regionCells) and interior cells (those with all faces shared,
 * appearing in no region).
 *
 * **pgEdges:** Sorted list of physical bonds, each serialised as
 * `{ source, target }` with `source <= target`. For 3D patches,
 * each edge corresponds to a shared cube face; for 2D patches,
 * a shared pentagon edge; for the tree, a
 * weighted tree edge.
 *
 * **Relationship to regions:** The set of boundary cells is
 * the union of all regionCells across all regions. The set
 * of interior cells is pgNodes \\ boundary_cells (by id). The
 * frontend uses this distinction to render boundary cells with
 * data-driven colors (from region data) and interior cells with
 * a neutral default.
 *
 * **Invariant:** Every endpoint of every edge in pgEdges
 * appears as an id in pgNodes. The number of nodes equals
 * patchCells. These are checked by Invariants.validateAll on
 * the backend.
 *
 * Produced by _make_patch_graph in 18_export_json.py.
 * Mirrors: Types.hs PatchGraph
 */
export interface PatchGraph {
  /** All cells with spatial coordinates (sorted by id) */
  pgNodes: GraphNode[];
  /** All physical bonds as `{source, target}` objects (source <= target) */
  pgEdges: Edge[];
}

// ════════════════════════════════════════════════════════════════
//  Curvature
// ════════════════════════════════════════════════════════════════

/**
 * A single vertex (2D) or edge (3D) curvature class.
 *
 * The ccKappa value is an integer numerator. The actual rational
 * curvature is ccKappa / curvDenominator where the denominator
 * comes from the enclosing CurvatureData.
 *
 * Mirrors: Types.hs CurvatureClass
 */
export interface CurvatureClass {
  /** Class label, e.g. "vTiling", "ev5" */
  ccName: string;
  /** Number of vertices/edges in this class */
  ccCount: number;
  /** Edge degree (2D) or face valence (3D) */
  ccValence: number;
  /** Curvature as integer numerator */
  ccKappa: number;
  /** "interior" or "boundary" */
  ccLocation: string;
}

/**
 * Full curvature data embedded inside a Patch.
 *
 * All curvature values are stored as integer numerators. The
 * curvDenominator field specifies the rational denominator:
 *   - 10 for 2D patches ({5,4}, {5,3}) — matching ℚ₁₀ = ℤ
 *   - 20 for 3D patches ({4,3,5})      — matching twentieths
 *
 * Mirrors: Types.hs CurvatureData
 */
export interface CurvatureData {
  curvClasses: CurvatureClass[];
  /** Σ κ as integer numerator */
  curvTotal: number;
  /** χ as integer numerator */
  curvEuler: number;
  /** curvTotal ≡ curvEuler (always true for valid data) */
  curvGaussBonnet: boolean;
  /** Rational denominator: 10 for 2D, 20 for 3D */
  curvDenominator: number;
}

// ════════════════════════════════════════════════════════════════
//  Half-Bound (Discrete Bekenstein–Hawking)
// ════════════════════════════════════════════════════════════════

/**
 * Discrete Bekenstein–Hawking half-bound summary for a patch.
 *
 * The bound 2·S(A) ≤ area(A) is verified for every region;
 * hbViolations is always 0 in valid data.
 *
 * Mirrors: Types.hs HalfBoundData
 */
export interface HalfBoundData {
  /** Total regions verified */
  hbRegionCount: number;
  /** Always 0 for valid data */
  hbViolations: number;
  /** Regions where 2·S = area (tight achievers) */
  hbAchieverCount: number;
  /** [(region_size, count)] — sizes of tight achievers */
  hbAchieverSizes: [number, number][];
  /** (min_slack, max_slack) where slack = area − 2·S */
  hbSlackRange: [number, number];
  /** Mean slack across all regions */
  hbMeanSlack: number;
}

// ════════════════════════════════════════════════════════════════
//  Patch (full)
// ════════════════════════════════════════════════════════════════

/**
 * A verified holographic patch instance with full region data.
 *
 * Loaded from GET /patches/:name. Corresponds to the Agda types
 * PatchData and OrbitReducedPatch in Bridge/GenericBridge.agda,
 * but carries only the numeric data — no proof content.
 *
 * patchOrbits semantics: 0 indicates flat enumeration (no orbit
 * reduction). A positive value is the number of distinct orbit
 * representatives.
 *
 * patchHalfBoundVerified: true when a corresponding
 * Boundary/*HalfBound.agda module exists. Currently true only
 * for dense-100, dense-200 and dense-1000.
 *
 * patchGraph: The full bulk graph containing ALL cells (including
 * interior cells invisible to boundary regions) and ALL physical
 * bonds (shared faces/edges between adjacent cells), with
 * Poincaré-projected spatial coordinates, per-cell rotation
 * quaternions, and conformal scale factors for each cell.
 * See PatchGraph and GraphNode for details.
 *
 * Mirrors: Types.hs Patch
 */
export interface Patch {
  patchName: string;
  patchTiling: Tiling;
  /** 1, 2, or 3 */
  patchDimension: number;
  /** Number of tiles / cubes */
  patchCells: number;
  /** Number of boundary regions */
  patchRegions: number;
  /** Orbit representatives (0 = flat enumeration) */
  patchOrbits: number;
  /** Maximum min-cut value */
  patchMaxCut: number;
  /** Internal shared faces / edges */
  patchBonds: number;
  /** Boundary legs / faces */
  patchBoundary: number;
  /** 2 · bonds / cells */
  patchDensity: number;
  patchStrategy: GrowthStrategy;
  patchRegionData: Region[];
  patchCurvature: CurvatureData | null;
  patchHalfBound: HalfBoundData | null;
  /** Agda-verified half-bound exists */
  patchHalfBoundVerified: boolean;
  /** Full bulk graph (all cells with coordinates + all physical bonds) */
  patchGraph: PatchGraph;
}

// ════════════════════════════════════════════════════════════════
//  PatchSummary (lightweight listing)
// ════════════════════════════════════════════════════════════════

/**
 * Lightweight summary for the GET /patches listing endpoint.
 *
 * Constructed server-side from Patch; does not include region
 * data, curvature, or half-bound statistics.
 *
 * NOTE: Fields use the "ps" prefix (NOT the "patch" prefix).
 *
 * Mirrors: Types.hs PatchSummary
 */
export interface PatchSummary {
  psName: string;
  psTiling: Tiling;
  psDimension: number;
  psCells: number;
  psRegions: number;
  psOrbits: number;
  psMaxCut: number;
  psStrategy: GrowthStrategy;
}

// ════════════════════════════════════════════════════════════════
//  Tower
// ════════════════════════════════════════════════════════════════

/**
 * A single level of the resolution tower.
 *
 * Loaded from GET /tower. The tlMonotone field carries a
 * monotonicity witness as a [k, "refl"] tuple, or null for the
 * first level of a sub-tower (where there is no predecessor).
 *
 * Mirrors: Types.hs TowerLevel
 */
export interface TowerLevel {
  tlPatchName: string;
  tlRegions: number;
  tlOrbits: number;
  tlMaxCut: number;
  /** (witness_k, "refl") or null for first level of a sub-tower */
  tlMonotone: [number, string] | null;
  /** BridgeWitness exists for this level */
  tlHasBridge: boolean;
  /** Area law (S ≤ area) verified */
  tlHasAreaLaw: boolean;
  /** Half-bound (2·S ≤ area) verified */
  tlHasHalfBound: boolean;
}

// ════════════════════════════════════════════════════════════════
//  Theorems
// ════════════════════════════════════════════════════════════════

/**
 * A machine-checked theorem from the canonical registry.
 *
 * Loaded from GET /theorems. Mirrors the table in
 * docs/formal/01-theorems.md.
 *
 * Mirrors: Types.hs Theorem
 */
export interface Theorem {
  thmNumber: number;
  thmName: string;
  /** e.g. "Bridge/GenericBridge.agda" */
  thmModule: string;
  /** Informal one-line statement */
  thmStatement: string;
  thmProofMethod: string;
  thmStatus: TheoremStatus;
}

// ════════════════════════════════════════════════════════════════
//  Curvature Summary
// ════════════════════════════════════════════════════════════════

/**
 * Top-level curvature summary entry from GET /curvature.
 *
 * Derived from per-patch curvature data by 18_export_json.py.
 *
 * IMPORTANT: The Haskell type CurvatureSummary uses a "cs" prefix
 * on field names (e.g. csPatchName), but Aeson strips the prefix
 * for JSON serialization. The JSON keys therefore lack the "cs"
 * prefix — e.g. "patchName", "tiling", "curvTotal".
 *
 * Mirrors: Types.hs CurvatureSummary (with cs prefix stripped)
 */
export interface CurvatureSummary {
  patchName: string;
  /** Tiling name as raw text (e.g. "Tiling435") */
  tiling: string;
  /** Σ κ as integer numerator */
  curvTotal: number;
  /** χ as integer numerator */
  curvEuler: number;
  gaussBonnet: boolean;
  /** Rational denominator: 10 for 2D, 20 for 3D */
  curvDenominator: number;
}

// ════════════════════════════════════════════════════════════════
//  Server Metadata and Health
// ════════════════════════════════════════════════════════════════

/**
 * Server and data metadata from GET /meta.
 *
 * IMPORTANT: The Haskell type Meta uses a "meta" prefix on field
 * names (e.g. metaVersion), but Aeson strips the 4-character prefix
 * for JSON serialization. The JSON keys therefore lack the "meta"
 * prefix — e.g. "version", "buildDate", "agdaVersion", "dataHash".
 *
 * Mirrors: Types.hs Meta (with meta prefix stripped)
 */
export interface Meta {
  /** Repository version, e.g. "0.5.0" */
  version: string;
  /** ISO 8601 UTC timestamp */
  buildDate: string;
  /** Agda compiler version, e.g. "2.8.0" */
  agdaVersion: string;
  /** SHA-256 prefix of the exported data */
  dataHash: string;
}

/**
 * Response for the GET /health endpoint.
 *
 * Constructed at runtime by the backend; not read from any file.
 *
 * Mirrors: Types.hs Health
 */
export interface Health {
  /** "ok" when all data loaded successfully */
  status: string;
  /** Number of loaded patches */
  patchCount: number;
  /** Total regions across all patches */
  regionCount: number;
}

// ════════════════════════════════════════════════════════════════
//  Type Guards
// ════════════════════════════════════════════════════════════════

/** All valid Tiling string literals. */
const VALID_TILINGS: ReadonlySet<string> = new Set([
  "Tiling54", "Tiling435", "Tiling53", "Tiling44", "Tree",
]);

/** All valid GrowthStrategy string literals. */
const VALID_STRATEGIES: ReadonlySet<string> = new Set([
  "BFS", "Dense", "Geodesic", "Hemisphere",
]);

/** All valid TheoremStatus string literals. */
const VALID_STATUSES: ReadonlySet<string> = new Set([
  "Verified", "Dead", "Numerical",
]);

/** Runtime check that a value is a valid Tiling string. */
export function isTiling(value: unknown): value is Tiling {
  return typeof value === "string" && VALID_TILINGS.has(value);
}

/** Runtime check that a value is a valid GrowthStrategy string. */
export function isGrowthStrategy(value: unknown): value is GrowthStrategy {
  return typeof value === "string" && VALID_STRATEGIES.has(value);
}

/** Runtime check that a value is a valid TheoremStatus string. */
export function isTheoremStatus(value: unknown): value is TheoremStatus {
  return typeof value === "string" && VALID_STATUSES.has(value);
}

/**
 * Runtime check that a value has the shape of an {@link Edge}.
 */
export function isEdge(value: unknown): value is Edge {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return typeof v["source"] === "number" && typeof v["target"] === "number";
}

/**
 * Runtime check that a value has the shape of a Region.
 *
 * Validates the presence and types of all required fields.
 * Does NOT validate semantic constraints (e.g. regionMinCut ≤ regionArea).
 */
export function isRegion(value: unknown): value is Region {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["regionId"] === "number" &&
    Array.isArray(v["regionCells"]) &&
    (v["regionCells"] as unknown[]).every((c) => typeof c === "number") &&
    typeof v["regionSize"] === "number" &&
    typeof v["regionMinCut"] === "number" &&
    typeof v["regionArea"] === "number" &&
    typeof v["regionOrbit"] === "string" &&
    (v["regionHalfSlack"] === null || typeof v["regionHalfSlack"] === "number") &&
    typeof v["regionRatio"] === "number" &&
    (v["regionCurvature"] === null || typeof v["regionCurvature"] === "number")
  );
}

/**
 * Runtime check that a value has the shape of a GraphNode.
 *
 * Validates that id, x, y, z, qx, qy, qz, qw, and scale are all
 * present and numeric. This matches the wire format emitted by
 * 18_export_json.py (Python) and decoded by Types.hs (Haskell)
 * with the "gn" field prefix stripped by Aeson.
 */
export function isGraphNode(value: unknown): value is GraphNode {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["id"] === "number" &&
    typeof v["x"] === "number" &&
    typeof v["y"] === "number" &&
    typeof v["z"] === "number" &&
    typeof v["qx"] === "number" &&
    typeof v["qy"] === "number" &&
    typeof v["qz"] === "number" &&
    typeof v["qw"] === "number" &&
    typeof v["scale"] === "number"
  );
}

/**
 * Runtime check that a value has the shape of a PatchGraph.
 *
 * Validates:
 *   - pgNodes is an array of GraphNode objects (each with id, x,
 *     y, z, qx, qy, qz, qw, scale)
 *   - pgEdges is an array of 2-element number arrays
 */
export function isPatchGraph(value: unknown): value is PatchGraph {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;

  if (!Array.isArray(v["pgNodes"])) return false;
  if (!(v["pgNodes"] as unknown[]).every((n) => isGraphNode(n))) return false;

  if (!Array.isArray(v["pgEdges"])) return false;
  if (!(v["pgEdges"] as unknown[]).every((e) => isEdge(e))) return false;

  return true;
}

/**
 * Runtime check that a value has the shape of a PatchSummary.
 *
 * Validates the presence and types of all required fields,
 * including that psTiling and psStrategy are valid enum values.
 */
export function isPatchSummary(value: unknown): value is PatchSummary {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["psName"] === "string" &&
    isTiling(v["psTiling"]) &&
    typeof v["psDimension"] === "number" &&
    typeof v["psCells"] === "number" &&
    typeof v["psRegions"] === "number" &&
    typeof v["psOrbits"] === "number" &&
    typeof v["psMaxCut"] === "number" &&
    isGrowthStrategy(v["psStrategy"])
  );
}

/**
 * Runtime check that a value has the shape of a Patch.
 *
 * Validates the presence and types of top-level fields. Region
 * data is checked for array type but individual regions are not
 * deeply validated (use isRegion for per-element checks).
 *
 * The patchGraph field is validated via isPatchGraph to ensure
 * the bulk graph data is present and well-formed (including that
 * pgNodes contains GraphNode objects with coordinates, rotation
 * quaternions, and conformal scale factors).
 */
export function isPatch(value: unknown): value is Patch {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["patchName"] === "string" &&
    isTiling(v["patchTiling"]) &&
    typeof v["patchDimension"] === "number" &&
    typeof v["patchCells"] === "number" &&
    typeof v["patchRegions"] === "number" &&
    typeof v["patchOrbits"] === "number" &&
    typeof v["patchMaxCut"] === "number" &&
    typeof v["patchBonds"] === "number" &&
    typeof v["patchBoundary"] === "number" &&
    typeof v["patchDensity"] === "number" &&
    isGrowthStrategy(v["patchStrategy"]) &&
    Array.isArray(v["patchRegionData"]) &&
    (v["patchCurvature"] === null || typeof v["patchCurvature"] === "object") &&
    (v["patchHalfBound"] === null || typeof v["patchHalfBound"] === "object") &&
    typeof v["patchHalfBoundVerified"] === "boolean" &&
    isPatchGraph(v["patchGraph"])
  );
}

/**
 * Runtime check that a value has the shape of a TowerLevel.
 */
export function isTowerLevel(value: unknown): value is TowerLevel {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;

  // Validate tlMonotone: null or [number, string]
  let monotoneOk = false;
  if (v["tlMonotone"] === null) {
    monotoneOk = true;
  } else if (Array.isArray(v["tlMonotone"]) && (v["tlMonotone"] as unknown[]).length === 2) {
    const arr = v["tlMonotone"] as unknown[];
    monotoneOk = typeof arr[0] === "number" && typeof arr[1] === "string";
  }

  return (
    typeof v["tlPatchName"] === "string" &&
    typeof v["tlRegions"] === "number" &&
    typeof v["tlOrbits"] === "number" &&
    typeof v["tlMaxCut"] === "number" &&
    monotoneOk &&
    typeof v["tlHasBridge"] === "boolean" &&
    typeof v["tlHasAreaLaw"] === "boolean" &&
    typeof v["tlHasHalfBound"] === "boolean"
  );
}

/**
 * Runtime check that a value has the shape of a Theorem.
 */
export function isTheorem(value: unknown): value is Theorem {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["thmNumber"] === "number" &&
    typeof v["thmName"] === "string" &&
    typeof v["thmModule"] === "string" &&
    typeof v["thmStatement"] === "string" &&
    typeof v["thmProofMethod"] === "string" &&
    isTheoremStatus(v["thmStatus"])
  );
}

/**
 * Runtime check that a value has the shape of a Meta response.
 */
export function isMeta(value: unknown): value is Meta {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["version"] === "string" &&
    typeof v["buildDate"] === "string" &&
    typeof v["agdaVersion"] === "string" &&
    typeof v["dataHash"] === "string"
  );
}

/**
 * Runtime check that a value has the shape of a Health response.
 */
export function isHealth(value: unknown): value is Health {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["status"] === "string" &&
    typeof v["patchCount"] === "number" &&
    typeof v["regionCount"] === "number"
  );
}

/**
 * Runtime check that a value has the shape of a CurvatureSummary.
 */
export function isCurvatureSummary(value: unknown): value is CurvatureSummary {
  if (typeof value !== "object" || value === null) return false;
  const v = value as Record<string, unknown>;
  return (
    typeof v["patchName"] === "string" &&
    typeof v["tiling"] === "string" &&
    typeof v["curvTotal"] === "number" &&
    typeof v["curvEuler"] === "number" &&
    typeof v["gaussBonnet"] === "boolean" &&
    typeof v["curvDenominator"] === "number"
  );
}