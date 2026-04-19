/**
 * Tests for TypeScript type guards in src/types/index.ts.
 *
 * Validates that every type guard:
 *   1. Accepts well-formed objects matching the actual JSON shapes
 *      produced by 18_export_json.py and served by the Haskell backend
 *   2. Rejects null, undefined, primitives, and empty objects
 *   3. Rejects objects with missing required fields
 *   4. Rejects objects with fields of the wrong type
 *   5. Accepts objects with extra (unknown) fields (forward-compatible)
 *
 * Mock data in this file is derived from the actual data/*.json files
 * in the repository so that the guards are tested against realistic
 * API response shapes — not synthetic toy data.
 *
 * Reference:
 *   - src/types/index.ts (type guards under test)
 *   - backend/src/Types.hs (Haskell source-of-truth for JSON shapes)
 *   - data/*.json (actual JSON produced by 18_export_json.py)
 */

import { describe, it, expect } from "vitest";

import {
  isTiling,
  isGrowthStrategy,
  isTheoremStatus,
  isRegion,
  isEdge,
  isGraphNode,
  isPatchGraph,
  isPatchSummary,
  isPatch,
  isTowerLevel,
  isTheorem,
  isMeta,
  isHealth,
  isCurvatureSummary,
} from "../src/types";

//  Schema Helpers — GraphNode / Edge fixtures
// ════════════════════════════════════════════════════════════════

/**
 * Build a structurally valid GraphNode fixture.
 *
 * Defaults place the node at the Poincaré origin with the identity
 * quaternion and the central conformal scale s(0) = 0.5. Tests that
 * care about specific geometry override the relevant fields; tests
 * that only care about the schema can pass just the id.
 */
function mkNode(
  id: number,
  overrides: Partial<{
    x: number; y: number; z: number;
    qx: number; qy: number; qz: number; qw: number;
    scale: number;
  }> = {},
): unknown {
  return {
    id,
    x:     overrides.x     ?? 0,
    y:     overrides.y     ?? 0,
    z:     overrides.z     ?? 0,
    qx:    overrides.qx    ?? 0,
    qy:    overrides.qy    ?? 0,
    qz:    overrides.qz    ?? 0,
    qw:    overrides.qw    ?? 1,
    scale: overrides.scale ?? 0.5,
  };
}

/**
 * Build a structurally valid Edge fixture — `{source, target}`
 * per the wire format emitted by `18_export_json.py::_make_patch_graph`.
 */
function mkEdge(source: number, target: number): unknown {
  return { source, target };
}

/** Convenience: generate N mkNode fixtures with consecutive ids 0..N-1. */
function mkNodes(n: number): unknown[] {
  return Array.from({ length: n }, (_, i) => mkNode(i));
}

// ════════════════════════════════════════════════════════════════
//  Mock Data — derived from actual data/*.json files
// ════════════════════════════════════════════════════════════════

/**
 * A valid Region object matching data/patches/dense-50.json region 0.
 */
const VALID_REGION = {
  regionId: 0,
  regionCells: [8],
  regionSize: 1,
  regionMinCut: 2,
  regionArea: 6,
  regionOrbit: "mc2",
  regionHalfSlack: 2,
  regionRatio: 0.3333,
  regionCurvature: null,
};

/**
 * A valid Region with null regionHalfSlack (the tree patch
 * has null half-bound data, and some regions may have null slack).
 */
const VALID_REGION_NULL_SLACK = {
  regionId: 3,
  regionCells: [3],
  regionSize: 1,
  regionMinCut: 1,
  regionArea: 5,
  regionOrbit: "mc1",
  regionHalfSlack: null,
  regionRatio: 0.2,
  regionCurvature: null,
};

/**
 * A valid PatchGraph matching data/patches/star.json patchGraph.
 *
 * Star patch: 6 GraphNode objects (cells 0–5) and 5 Edge records
 * (each Ni connected to the central tile C = 5).
 */
const VALID_PATCH_GRAPH = {
  pgNodes: [
    mkNode(0), mkNode(1), mkNode(2),
    mkNode(3), mkNode(4), mkNode(5),
  ],
  pgEdges: [mkEdge(0, 5), mkEdge(1, 5), mkEdge(2, 5), mkEdge(3, 5), mkEdge(4, 5)],
};

/**
 * A valid PatchGraph for the tree patch: 7 GraphNode objects, 6 Edges.
 */
const VALID_TREE_GRAPH = {
  pgNodes: mkNodes(7),
  pgEdges: [
    mkEdge(0, 4), mkEdge(1, 4), mkEdge(2, 5),
    mkEdge(3, 5), mkEdge(4, 6), mkEdge(5, 6),
  ],
};

/**
 * A valid PatchGraph for a single-cell patch — one node, zero edges.
 */
const VALID_SINGLE_CELL_GRAPH = {
  pgNodes: [mkNode(0)],
  pgEdges: [],
};

/**
 * A valid PatchSummary matching the shape returned by GET /patches
 * for the dense-100 patch.
 *
 * Note: uses "ps" prefix (NOT "patch" prefix) per Types.hs PatchSummary.
 */
const VALID_PATCH_SUMMARY = {
  psName: "dense-100",
  psTiling: "Tiling435",
  psDimension: 3,
  psCells: 100,
  psRegions: 717,
  psOrbits: 8,
  psMaxCut: 8,
  psStrategy: "Dense",
};

/**
 * A valid Patch matching the shape returned by GET /patches/star.
 *
 * Uses a minimal but complete set of fields. The patchRegionData
 * contains only one region for brevity (the guard checks that
 * patchRegionData is an array, not that every element is a Region —
 * per-element validation is the responsibility of isRegion).
 *
 * Includes the patchGraph field (Phase 1, item 7) with the star
 * patch's bulk graph: 6 nodes (N0-N4 + C) and 5 bonds (C–Ni).
 */
const VALID_PATCH = {
  patchName: "star",
  patchTiling: "Tiling54",
  patchDimension: 2,
  patchCells: 6,
  patchRegions: 10,
  patchOrbits: 0,
  patchMaxCut: 2,
  patchBonds: 5,
  patchBoundary: 20,
  patchDensity: 1.67,
  patchStrategy: "BFS",
  patchRegionData: [VALID_REGION],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: VALID_PATCH_GRAPH,
};

/**
 * A valid Patch with non-null curvature and half-bound data
 * (matching the dense-100 patch shape).
 *
 * Includes a patchGraph with 100 nodes (0-99) and 150 edges
 * (only a representative subset is included for brevity — the
 * type guard checks structural shape, not semantic content).
 */
const VALID_PATCH_WITH_DATA = {
  patchName: "dense-100",
  patchTiling: "Tiling435",
  patchDimension: 3,
  patchCells: 100,
  patchRegions: 717,
  patchOrbits: 8,
  patchMaxCut: 8,
  patchBonds: 150,
  patchBoundary: 300,
  patchDensity: 3.0,
  patchStrategy: "Dense",
  patchRegionData: [],
  patchCurvature: {
    curvClasses: [
      {
        ccName: "ev5",
        ccCount: 12,
        ccValence: 5,
        ccKappa: -5,
        ccLocation: "interior",
      },
    ],
    curvTotal: -60,
    curvEuler: -60,
    curvGaussBonnet: true,
    curvDenominator: 20,
  },
  patchHalfBound: {
    hbRegionCount: 717,
    hbViolations: 0,
    hbAchieverCount: 40,
    hbAchieverSizes: [[1, 40]],
    hbSlackRange: [0, 14],
    hbMeanSlack: 6.0,
  },
  patchHalfBoundVerified: true,
  patchGraph: {
    pgNodes: mkNodes(100),
    pgEdges: [
      mkEdge(0, 1), mkEdge(1, 2), mkEdge(2, 3),
      mkEdge(3, 4), mkEdge(4, 5),
    ],
  },
};

/**
 * A valid TowerLevel matching data/tower.json entry for dense-100.
 */
const VALID_TOWER_LEVEL_WITH_MONOTONE = {
  tlPatchName: "dense-100",
  tlRegions: 717,
  tlOrbits: 8,
  tlMaxCut: 8,
  tlMonotone: [1, "refl"],
  tlHasBridge: true,
  tlHasAreaLaw: true,
  tlHasHalfBound: true,
};

/**
 * A valid TowerLevel with null monotone (first level of a sub-tower).
 * Matches data/tower.json entry for dense-50.
 */
const VALID_TOWER_LEVEL_NULL_MONOTONE = {
  tlPatchName: "dense-50",
  tlRegions: 139,
  tlOrbits: 0,
  tlMaxCut: 7,
  tlMonotone: null,
  tlHasBridge: true,
  tlHasAreaLaw: false,
  tlHasHalfBound: false,
};

/**
 * A valid Theorem matching data/theorems.json entry #1.
 */
const VALID_THEOREM = {
  thmNumber: 1,
  thmName: "Discrete Ryu-Takayanagi",
  thmModule: "Bridge/GenericBridge.agda",
  thmStatement:
    "S_cut = L_min on every boundary region, for any patch, via a single generic theorem.",
  thmProofMethod:
    "isoToEquiv + ua + uaβ on contractible reversed singletons",
  thmStatus: "Verified",
};

/**
 * A valid Meta matching data/meta.json.
 *
 * Note: JSON keys lack the "meta" prefix (Haskell strips it via Aeson options).
 */
const VALID_META = {
  version: "0.6.0",
  buildDate: "2026-04-13T21:04:23Z",
  agdaVersion: "2.8.0",
  dataHash: "f8fcfb4dc6d9be08",
};

/**
 * A valid Health response (constructed at runtime by the backend).
 */
const VALID_HEALTH = {
  status: "ok",
  patchCount: 14,
  regionCount: 5405,
};

/**
 * A valid CurvatureSummary matching data/curvature.json entry for dense-100.
 *
 * Note: JSON keys lack the "cs" prefix (Haskell strips it via Aeson options).
 */
const VALID_CURVATURE_SUMMARY = {
  patchName: "dense-100",
  tiling: "Tiling435",
  curvTotal: -60,
  curvEuler: -60,
  gaussBonnet: true,
  curvDenominator: 20,
};

// ════════════════════════════════════════════════════════════════
//  Common rejection inputs
// ════════════════════════════════════════════════════════════════

/**
 * A battery of values that every type guard should reject.
 *
 * Used across all guard test suites to ensure consistent rejection
 * of null, undefined, primitives, arrays, and empty objects.
 */
const COMMON_REJECTS: readonly [string, unknown][] = [
  ["null", null],
  ["undefined", undefined],
  ["number", 42],
  ["string", "hello"],
  ["boolean", true],
  ["empty array", []],
  ["empty object", {}],
  ["array of numbers", [1, 2, 3]],
];

// ════════════════════════════════════════════════════════════════
//  Enum Type Guards
// ════════════════════════════════════════════════════════════════

describe("isTiling", () => {
  it.each([
    "Tiling54",
    "Tiling435",
    "Tiling53",
    "Tiling44",
    "Tree",
  ])("accepts valid tiling string: %s", (value) => {
    expect(isTiling(value)).toBe(true);
  });

  it.each([
    ["null", null],
    ["undefined", undefined],
    ["number", 0],
    ["boolean", false],
    ["empty string", ""],
    ["lowercase variant", "tiling54"],
    ["snake_case variant", "tiling_54"],
    ["unknown tiling", "Tiling66"],
    ["partial string", "Tiling"],
    ["object", { type: "Tiling54" }],
  ])("rejects invalid value: %s", (_label, value) => {
    expect(isTiling(value)).toBe(false);
  });
});

describe("isGrowthStrategy", () => {
  it.each(["BFS", "Dense", "Geodesic", "Hemisphere"])(
    "accepts valid strategy: %s",
    (value) => {
      expect(isGrowthStrategy(value)).toBe(true);
    },
  );

  it.each([
    ["null", null],
    ["undefined", undefined],
    ["number", 1],
    ["empty string", ""],
    ["lowercase", "bfs"],
    ["unknown strategy", "Greedy"],
    ["partial string", "Den"],
  ])("rejects invalid value: %s", (_label, value) => {
    expect(isGrowthStrategy(value)).toBe(false);
  });
});

describe("isTheoremStatus", () => {
  it.each(["Verified", "Dead", "Numerical"])(
    "accepts valid status: %s",
    (value) => {
      expect(isTheoremStatus(value)).toBe(true);
    },
  );

  it.each([
    ["null", null],
    ["undefined", undefined],
    ["number", 0],
    ["empty string", ""],
    ["lowercase", "verified"],
    ["unknown status", "Pending"],
    ["boolean", true],
  ])("rejects invalid value: %s", (_label, value) => {
    expect(isTheoremStatus(value)).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isRegion
// ════════════════════════════════════════════════════════════════

describe("isRegion", () => {
  it("accepts a valid region with integer half-slack", () => {
    expect(isRegion(VALID_REGION)).toBe(true);
  });

  it("accepts a valid region with null half-slack", () => {
    expect(isRegion(VALID_REGION_NULL_SLACK)).toBe(true);
  });

  it("accepts a region with multi-cell regionCells", () => {
    const multiCell = {
      ...VALID_REGION,
      regionId: 5,
      regionCells: [0, 1],
      regionSize: 2,
    };
    expect(isRegion(multiCell)).toBe(true);
  });

  it("accepts a region with empty regionCells (edge case)", () => {
    // While semantically invalid, the type guard checks structure, not semantics
    const emptyRegion = {
      ...VALID_REGION,
      regionCells: [],
      regionSize: 0,
    };
    expect(isRegion(emptyRegion)).toBe(true);
  });

  it("accepts a region with extra unknown fields (forward-compatible)", () => {
    const withExtra = {
      ...VALID_REGION,
      unknownField: "should be ignored",
      extraNumber: 999,
    };
    expect(isRegion(withExtra)).toBe(true);
  });

  it("accepts a region with a numeric regionCurvature", () => {
    const withCurvature = {
      ...VALID_REGION,
      regionCurvature: -0.25,
    };
    expect(isRegion(withCurvature)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isRegion(value)).toBe(false);
  });

  it("rejects when regionId is missing", () => {
    const { regionId: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionCells is missing", () => {
    const { regionCells: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionSize is missing", () => {
    const { regionSize: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionMinCut is missing", () => {
    const { regionMinCut: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionArea is missing", () => {
    const { regionArea: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionOrbit is missing", () => {
    const { regionOrbit: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionRatio is missing", () => {
    const { regionRatio: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionCurvature is missing (undefined fails the guard)", () => {
    const { regionCurvature: _removed, ...rest } = VALID_REGION;
    expect(isRegion(rest)).toBe(false);
  });

  it("rejects when regionId is a string", () => {
    expect(isRegion({ ...VALID_REGION, regionId: "zero" })).toBe(false);
  });

  it("rejects when regionCells is not an array", () => {
    expect(isRegion({ ...VALID_REGION, regionCells: "8" })).toBe(false);
  });

  it("rejects when regionCells contains non-numbers", () => {
    expect(isRegion({ ...VALID_REGION, regionCells: ["a", "b"] })).toBe(
      false,
    );
  });

  it("rejects when regionMinCut is a string", () => {
    expect(isRegion({ ...VALID_REGION, regionMinCut: "2" })).toBe(false);
  });

  it("rejects when regionOrbit is a number", () => {
    expect(isRegion({ ...VALID_REGION, regionOrbit: 2 })).toBe(false);
  });

  it("rejects when regionHalfSlack is a string (must be number or null)", () => {
    expect(isRegion({ ...VALID_REGION, regionHalfSlack: "2" })).toBe(false);
  });

  it("rejects when regionRatio is a string", () => {
    expect(isRegion({ ...VALID_REGION, regionRatio: "0.33" })).toBe(false);
  });

  it("rejects when regionCurvature is a string (must be number or null)", () => {
    expect(isRegion({ ...VALID_REGION, regionCurvature: "-0.25" })).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isGraphNode
// ════════════════════════════════════════════════════════════════

describe("isGraphNode", () => {
  it("accepts a default GraphNode fixture (identity quat, centre scale)", () => {
    expect(isGraphNode(mkNode(0))).toBe(true);
  });

  it("accepts a GraphNode with non-trivial coordinates + rotation + scale", () => {
    expect(isGraphNode(mkNode(42, {
      x: 0.1, y: -0.2, z: 0.3,
      qx: 0.0, qy: 0.0, qz: 0.38, qw: 0.92,
      scale: 0.24,
    }))).toBe(true);
  });

  it("accepts a 2D-style node with z = 0 and only qz/qw non-zero", () => {
    expect(isGraphNode({
      id: 3, x: 0.5, y: 0.25, z: 0.0,
      qx: 0, qy: 0, qz: 0.707, qw: 0.707,
      scale: 0.4,
    })).toBe(true);
  });

  it("accepts a GraphNode with extra unknown fields (forward-compatible)", () => {
    expect(isGraphNode({ ...(mkNode(1) as object), debug: "ignored" })).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isGraphNode(value)).toBe(false);
  });

  it("rejects plain numbers (the old pgNodes wire format)", () => {
    // Pre-Poincaré pgNodes were bare cell ids (number[]). The new
    // schema requires GraphNode objects, so plain numbers must fail.
    expect(isGraphNode(0)).toBe(false);
    expect(isGraphNode(42)).toBe(false);
  });

  it("rejects when id is missing", () => {
    const { id: _removed, ...rest } = mkNode(0) as Record<string, unknown>;
    expect(isGraphNode(rest)).toBe(false);
  });

  it("rejects when id is a string", () => {
    expect(isGraphNode({ ...(mkNode(0) as object), id: "0" })).toBe(false);
  });

  it.each(["x", "y", "z", "qx", "qy", "qz", "qw", "scale"])(
    "rejects when %s is missing",
    (field) => {
      const node = mkNode(0) as Record<string, unknown>;
      const { [field]: _removed, ...rest } = node;
      expect(isGraphNode(rest)).toBe(false);
    },
  );

  it.each(["x", "y", "z", "qx", "qy", "qz", "qw", "scale"])(
    "rejects when %s is a string",
    (field) => {
      expect(isGraphNode({ ...(mkNode(0) as object), [field]: "0" })).toBe(false);
    },
  );

  it("rejects when scale is null (must be a number — no null sentinel)", () => {
    expect(isGraphNode({ ...(mkNode(0) as object), scale: null })).toBe(false);
  });

  it("rejects when qw is a boolean", () => {
    expect(isGraphNode({ ...(mkNode(0) as object), qw: true })).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isEdge
// ════════════════════════════════════════════════════════════════

describe("isEdge", () => {
  it("accepts a valid edge with source < target", () => {
    expect(isEdge(mkEdge(0, 5))).toBe(true);
  });

  it("accepts a valid edge with source == target (self-loop — structurally valid)", () => {
    // The guard checks only that both endpoints are numbers; ordering
    // is a semantic invariant enforced by the exporter, not the type.
    expect(isEdge(mkEdge(3, 3))).toBe(true);
  });

  it("accepts an edge with extra unknown fields", () => {
    expect(isEdge({ source: 1, target: 2, weight: 0.5 })).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isEdge(value)).toBe(false);
  });

  it("rejects 2-element number arrays (the old pgEdges wire format)", () => {
    // Pre-Poincaré pgEdges were [lo, hi] tuples.  The new schema
    // serialises as {source, target} objects.  Arrays must fail.
    expect(isEdge([0, 1])).toBe(false);
    expect(isEdge([5, 10])).toBe(false);
  });

  it("rejects edges missing source", () => {
    expect(isEdge({ target: 1 })).toBe(false);
  });

  it("rejects edges missing target", () => {
    expect(isEdge({ source: 0 })).toBe(false);
  });

  it("rejects edges with string source", () => {
    expect(isEdge({ source: "0", target: 1 })).toBe(false);
  });

  it("rejects edges with string target", () => {
    expect(isEdge({ source: 0, target: "1" })).toBe(false);
  });

  it("rejects edges with null source", () => {
    expect(isEdge({ source: null, target: 1 })).toBe(false);
  });

  it("rejects an object using array-destructured keys like {0:..., 1:...}", () => {
    expect(isEdge({ 0: 1, 1: 2 })).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isPatchGraph
// ════════════════════════════════════════════════════════════════

describe("isPatchGraph", () => {
  it("accepts a valid patch graph (star patch shape)", () => {
    expect(isPatchGraph(VALID_PATCH_GRAPH)).toBe(true);
  });

  it("accepts a valid patch graph (tree patch shape)", () => {
    expect(isPatchGraph(VALID_TREE_GRAPH)).toBe(true);
  });

  it("accepts a valid patch graph with a single node and no edges", () => {
    expect(isPatchGraph(VALID_SINGLE_CELL_GRAPH)).toBe(true);
  });

  it("accepts a patch graph with both empty nodes AND empty edges", () => {
    expect(isPatchGraph({ pgNodes: [], pgEdges: [] })).toBe(true);
  });

  it("accepts a patch graph with extra unknown fields (forward-compatible)", () => {
    const withExtra = {
      ...VALID_PATCH_GRAPH,
      unknownField: "ignored",
    };
    expect(isPatchGraph(withExtra)).toBe(true);
  });

  it("accepts a large patch graph (100 GraphNode objects)", () => {
    const largeGraph = {
      pgNodes: mkNodes(100),
      pgEdges: [mkEdge(0, 1), mkEdge(1, 2), mkEdge(2, 3)],
    };
    expect(isPatchGraph(largeGraph)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isPatchGraph(value)).toBe(false);
  });

  it("rejects when pgNodes is missing", () => {
    expect(isPatchGraph({ pgEdges: [] })).toBe(false);
  });

  it("rejects when pgEdges is missing", () => {
    expect(isPatchGraph({ pgNodes: mkNodes(2) })).toBe(false);
  });

  it("rejects when pgNodes is not an array", () => {
    expect(isPatchGraph({ pgNodes: "0,1,2", pgEdges: [] })).toBe(false);
  });

  it("rejects when pgEdges is not an array", () => {
    expect(isPatchGraph({ pgNodes: mkNodes(2), pgEdges: "edges" })).toBe(false);
  });

  it("rejects when pgNodes contains plain numbers (the old schema)", () => {
    // Pre-Poincaré the wire format was a bare id list; now rejected.
    expect(isPatchGraph({ pgNodes: [0, 1, 2], pgEdges: [] })).toBe(false);
  });

  it("rejects when pgNodes contains strings", () => {
    expect(isPatchGraph({ pgNodes: ["a", "b"], pgEdges: [] })).toBe(false);
  });

  it("rejects when pgNodes mixes valid GraphNodes and plain numbers", () => {
    expect(isPatchGraph({
      pgNodes: [mkNode(0), 1, mkNode(2)],
      pgEdges: [],
    })).toBe(false);
  });

  it("rejects when any GraphNode in pgNodes is missing required fields", () => {
    const bad = { id: 1, x: 0, y: 0, z: 0, qx: 0, qy: 0, qz: 0, qw: 1 };
    // missing `scale`
    expect(isPatchGraph({
      pgNodes: [mkNode(0), bad],
      pgEdges: [],
    })).toBe(false);
  });

  it("rejects when pgEdges uses the old 2-element array format", () => {
    // Pre-Poincaré pgEdges were `[lo, hi]` tuples.  Must now be
    // `{source, target}` objects.
    expect(isPatchGraph({
      pgNodes: mkNodes(2),
      pgEdges: [[0, 1]],
    })).toBe(false);
  });

  it("rejects when an edge is not an array", () => {
    expect(isPatchGraph({ pgNodes: mkNodes(2), pgEdges: ["0-1"] })).toBe(false);
  });

  it("rejects when an edge is missing `source`", () => {
    expect(isPatchGraph({
      pgNodes: mkNodes(2),
      pgEdges: [{ target: 1 }],
    })).toBe(false);
  });

  it("rejects when an edge is missing `target`", () => {
    expect(isPatchGraph({
      pgNodes: mkNodes(2),
      pgEdges: [{ source: 0 }],
    })).toBe(false);
  });

  it("rejects when an edge endpoint is a string", () => {
    expect(isPatchGraph({
      pgNodes: mkNodes(2),
      pgEdges: [{ source: "0", target: "1" }],
    })).toBe(false);
  });

  it("rejects when an edge endpoint is null", () => {
    expect(isPatchGraph({
      pgNodes: mkNodes(2),
      pgEdges: [{ source: null, target: 1 }],
    })).toBe(false);
  });

  it("accepts a non-trivial graph where every edge is a {source,target} object", () => {
    const graph = {
      pgNodes: mkNodes(4),
      pgEdges: [mkEdge(0, 1), mkEdge(1, 2), mkEdge(2, 3), mkEdge(0, 3)],
    };
    expect(isPatchGraph(graph)).toBe(true);
  });
});

// ════════════════════════════════════════════════════════════════
//  isPatchSummary
// ════════════════════════════════════════════════════════════════

describe("isPatchSummary", () => {
  it("accepts a valid patch summary (dense-100 shape)", () => {
    expect(isPatchSummary(VALID_PATCH_SUMMARY)).toBe(true);
  });

  it("accepts every valid tiling + strategy combination", () => {
    const tilings = ["Tiling54", "Tiling435", "Tiling53", "Tiling44", "Tree"];
    const strategies = ["BFS", "Dense", "Geodesic", "Hemisphere"];

    for (const tiling of tilings) {
      for (const strategy of strategies) {
        const summary = {
          ...VALID_PATCH_SUMMARY,
          psTiling: tiling,
          psStrategy: strategy,
        };
        expect(isPatchSummary(summary)).toBe(true);
      }
    }
  });

  it("accepts a summary with extra fields (forward-compatible)", () => {
    const withExtra = {
      ...VALID_PATCH_SUMMARY,
      newField: true,
    };
    expect(isPatchSummary(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isPatchSummary(value)).toBe(false);
  });

  it("rejects when psName is missing", () => {
    const { psName: _removed, ...rest } = VALID_PATCH_SUMMARY;
    expect(isPatchSummary(rest)).toBe(false);
  });

  it("rejects when psTiling has an invalid value", () => {
    expect(
      isPatchSummary({ ...VALID_PATCH_SUMMARY, psTiling: "InvalidTiling" }),
    ).toBe(false);
  });

  it("rejects when psStrategy has an invalid value", () => {
    expect(
      isPatchSummary({ ...VALID_PATCH_SUMMARY, psStrategy: "Random" }),
    ).toBe(false);
  });

  it("rejects when psDimension is a string", () => {
    expect(
      isPatchSummary({ ...VALID_PATCH_SUMMARY, psDimension: "3" }),
    ).toBe(false);
  });

  it("rejects when psCells is missing", () => {
    const { psCells: _removed, ...rest } = VALID_PATCH_SUMMARY;
    expect(isPatchSummary(rest)).toBe(false);
  });

  it("rejects when psRegions is missing", () => {
    const { psRegions: _removed, ...rest } = VALID_PATCH_SUMMARY;
    expect(isPatchSummary(rest)).toBe(false);
  });

  it("rejects when psOrbits is missing", () => {
    const { psOrbits: _removed, ...rest } = VALID_PATCH_SUMMARY;
    expect(isPatchSummary(rest)).toBe(false);
  });

  it("rejects when psMaxCut is missing", () => {
    const { psMaxCut: _removed, ...rest } = VALID_PATCH_SUMMARY;
    expect(isPatchSummary(rest)).toBe(false);
  });

  it("rejects an object using 'patch' prefix instead of 'ps' prefix", () => {
    // Common mistake: using the Patch field names instead of PatchSummary names
    const wrongPrefix = {
      patchName: "dense-100",
      patchTiling: "Tiling435",
      patchDimension: 3,
      patchCells: 100,
      patchRegions: 717,
      patchOrbits: 8,
      patchMaxCut: 8,
      patchStrategy: "Dense",
    };
    expect(isPatchSummary(wrongPrefix)).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isPatch
// ════════════════════════════════════════════════════════════════

describe("isPatch", () => {
  it("accepts a valid patch with null curvature and half-bound (star shape)", () => {
    expect(isPatch(VALID_PATCH)).toBe(true);
  });

  it("accepts a valid patch with non-null curvature and half-bound (dense-100 shape)", () => {
    expect(isPatch(VALID_PATCH_WITH_DATA)).toBe(true);
  });

  it("accepts a patch with empty patchRegionData array", () => {
    const emptyRegions = { ...VALID_PATCH, patchRegionData: [] };
    expect(isPatch(emptyRegions)).toBe(true);
  });

  it("accepts a patch with extra fields (forward-compatible)", () => {
    const withExtra = { ...VALID_PATCH, futureField: [1, 2, 3] };
    expect(isPatch(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isPatch(value)).toBe(false);
  });

  it("rejects when patchName is missing", () => {
    const { patchName: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchTiling is invalid", () => {
    expect(isPatch({ ...VALID_PATCH, patchTiling: "BadTiling" })).toBe(false);
  });

  it("rejects when patchStrategy is invalid", () => {
    expect(isPatch({ ...VALID_PATCH, patchStrategy: "BadStrategy" })).toBe(
      false,
    );
  });

  it("rejects when patchRegionData is not an array", () => {
    expect(
      isPatch({ ...VALID_PATCH, patchRegionData: "regions" }),
    ).toBe(false);
  });

  it("rejects when patchCurvature is not null or object", () => {
    expect(isPatch({ ...VALID_PATCH, patchCurvature: 42 })).toBe(false);
  });

  it("rejects when patchHalfBound is not null or object", () => {
    expect(isPatch({ ...VALID_PATCH, patchHalfBound: "none" })).toBe(false);
  });

  it("rejects when patchHalfBoundVerified is missing", () => {
    const { patchHalfBoundVerified: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchHalfBoundVerified is a string", () => {
    expect(
      isPatch({ ...VALID_PATCH, patchHalfBoundVerified: "true" }),
    ).toBe(false);
  });

  it("rejects when patchDimension is missing", () => {
    const { patchDimension: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchBonds is missing", () => {
    const { patchBonds: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchBoundary is missing", () => {
    const { patchBoundary: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchDensity is missing", () => {
    const { patchDensity: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchGraph is missing", () => {
    const { patchGraph: _removed, ...rest } = VALID_PATCH;
    expect(isPatch(rest)).toBe(false);
  });

  it("rejects when patchGraph is null", () => {
    expect(isPatch({ ...VALID_PATCH, patchGraph: null })).toBe(false);
  });

  it("rejects when patchGraph is a string", () => {
    expect(isPatch({ ...VALID_PATCH, patchGraph: "graph" })).toBe(false);
  });

  it("rejects when patchGraph is a number", () => {
    expect(isPatch({ ...VALID_PATCH, patchGraph: 42 })).toBe(false);
  });

  it("rejects when patchGraph has invalid structure (missing pgNodes)", () => {
    expect(isPatch({ ...VALID_PATCH, patchGraph: { pgEdges: [] } })).toBe(false);
  });

  it("rejects when patchGraph has invalid structure (missing pgEdges)", () => {
    expect(isPatch({ ...VALID_PATCH, patchGraph: { pgNodes: [0, 1] } })).toBe(false);
  });

  it("rejects when patchGraph has invalid pgNodes (non-number elements)", () => {
    // pgNodes must be GraphNode objects; strings are rejected.
    expect(isPatch({
      ...VALID_PATCH,
      patchGraph: { pgNodes: ["a", "b"], pgEdges: [] },
    })).toBe(false);
  });

  it("rejects when patchGraph uses the old pgEdges array format", () => {
    // Pre-Poincaré `[lo, hi]` tuples are no longer accepted — the
    // wire format is now `{source, target}` objects.
    expect(isPatch({
      ...VALID_PATCH,
      patchGraph: { pgNodes: mkNodes(3), pgEdges: [[0, 1]] },
    })).toBe(false);
  });

  it("accepts a patch with empty patchGraph (no nodes, no edges)", () => {
    expect(isPatch({
      ...VALID_PATCH,
      patchGraph: { pgNodes: [], pgEdges: [] },
    })).toBe(true);
  });

  it("rejects an object using 'ps' prefix instead of 'patch' prefix", () => {
    // Reverse of the PatchSummary mistake: using summary names for full patch
    expect(isPatch(VALID_PATCH_SUMMARY)).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isTowerLevel
// ════════════════════════════════════════════════════════════════

describe("isTowerLevel", () => {
  it("accepts a tower level with monotonicity witness [k, 'refl']", () => {
    expect(isTowerLevel(VALID_TOWER_LEVEL_WITH_MONOTONE)).toBe(true);
  });

  it("accepts a tower level with null monotone (first level of sub-tower)", () => {
    expect(isTowerLevel(VALID_TOWER_LEVEL_NULL_MONOTONE)).toBe(true);
  });

  it("accepts a tower level with monotone [0, 'refl'] (flat tower)", () => {
    const flat = {
      ...VALID_TOWER_LEVEL_WITH_MONOTONE,
      tlPatchName: "layer-54-d3",
      tlMonotone: [0, "refl"],
    };
    expect(isTowerLevel(flat)).toBe(true);
  });

  it("accepts a tower level with extra fields (forward-compatible)", () => {
    const withExtra = {
      ...VALID_TOWER_LEVEL_WITH_MONOTONE,
      extraField: "ignored",
    };
    expect(isTowerLevel(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isTowerLevel(value)).toBe(false);
  });

  it("rejects when tlPatchName is missing", () => {
    const { tlPatchName: _removed, ...rest } = VALID_TOWER_LEVEL_WITH_MONOTONE;
    expect(isTowerLevel(rest)).toBe(false);
  });

  it("rejects when tlRegions is missing", () => {
    const { tlRegions: _removed, ...rest } = VALID_TOWER_LEVEL_WITH_MONOTONE;
    expect(isTowerLevel(rest)).toBe(false);
  });

  it("rejects when tlMaxCut is missing", () => {
    const { tlMaxCut: _removed, ...rest } = VALID_TOWER_LEVEL_WITH_MONOTONE;
    expect(isTowerLevel(rest)).toBe(false);
  });

  it("rejects when tlHasBridge is missing", () => {
    const { tlHasBridge: _removed, ...rest } = VALID_TOWER_LEVEL_WITH_MONOTONE;
    expect(isTowerLevel(rest)).toBe(false);
  });

  it("rejects when tlHasAreaLaw is missing", () => {
    const { tlHasAreaLaw: _removed, ...rest } = VALID_TOWER_LEVEL_WITH_MONOTONE;
    expect(isTowerLevel(rest)).toBe(false);
  });

  it("rejects when tlHasHalfBound is missing", () => {
    const { tlHasHalfBound: _removed, ...rest } =
      VALID_TOWER_LEVEL_WITH_MONOTONE;
    expect(isTowerLevel(rest)).toBe(false);
  });

  it("rejects when tlMonotone is a plain number (not a tuple or null)", () => {
    expect(
      isTowerLevel({
        ...VALID_TOWER_LEVEL_WITH_MONOTONE,
        tlMonotone: 1,
      }),
    ).toBe(false);
  });

  it("rejects when tlMonotone is a single-element array", () => {
    expect(
      isTowerLevel({
        ...VALID_TOWER_LEVEL_WITH_MONOTONE,
        tlMonotone: [1],
      }),
    ).toBe(false);
  });

  it("rejects when tlMonotone is a three-element array", () => {
    expect(
      isTowerLevel({
        ...VALID_TOWER_LEVEL_WITH_MONOTONE,
        tlMonotone: [1, "refl", "extra"],
      }),
    ).toBe(false);
  });

  it("rejects when tlMonotone tuple has wrong element types [string, number]", () => {
    expect(
      isTowerLevel({
        ...VALID_TOWER_LEVEL_WITH_MONOTONE,
        tlMonotone: ["refl", 1],
      }),
    ).toBe(false);
  });

  it("rejects when tlMonotone tuple has two numbers [1, 2]", () => {
    expect(
      isTowerLevel({
        ...VALID_TOWER_LEVEL_WITH_MONOTONE,
        tlMonotone: [1, 2],
      }),
    ).toBe(false);
  });

  it("rejects when tlHasBridge is a string instead of boolean", () => {
    expect(
      isTowerLevel({
        ...VALID_TOWER_LEVEL_WITH_MONOTONE,
        tlHasBridge: "true",
      }),
    ).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isTheorem
// ════════════════════════════════════════════════════════════════

describe("isTheorem", () => {
  it("accepts a valid Verified theorem", () => {
    expect(isTheorem(VALID_THEOREM)).toBe(true);
  });

  it("accepts a theorem with Dead status", () => {
    const dead = { ...VALID_THEOREM, thmStatus: "Dead" };
    expect(isTheorem(dead)).toBe(true);
  });

  it("accepts a theorem with Numerical status", () => {
    const numerical = { ...VALID_THEOREM, thmStatus: "Numerical" };
    expect(isTheorem(numerical)).toBe(true);
  });

  it("accepts a theorem with extra fields (forward-compatible)", () => {
    const withExtra = { ...VALID_THEOREM, thmSignature: "foo : Bar" };
    expect(isTheorem(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isTheorem(value)).toBe(false);
  });

  it("rejects when thmNumber is missing", () => {
    const { thmNumber: _removed, ...rest } = VALID_THEOREM;
    expect(isTheorem(rest)).toBe(false);
  });

  it("rejects when thmName is missing", () => {
    const { thmName: _removed, ...rest } = VALID_THEOREM;
    expect(isTheorem(rest)).toBe(false);
  });

  it("rejects when thmModule is missing", () => {
    const { thmModule: _removed, ...rest } = VALID_THEOREM;
    expect(isTheorem(rest)).toBe(false);
  });

  it("rejects when thmStatement is missing", () => {
    const { thmStatement: _removed, ...rest } = VALID_THEOREM;
    expect(isTheorem(rest)).toBe(false);
  });

  it("rejects when thmProofMethod is missing", () => {
    const { thmProofMethod: _removed, ...rest } = VALID_THEOREM;
    expect(isTheorem(rest)).toBe(false);
  });

  it("rejects when thmStatus is invalid", () => {
    expect(isTheorem({ ...VALID_THEOREM, thmStatus: "Pending" })).toBe(false);
  });

  it("rejects when thmStatus is lowercase", () => {
    expect(isTheorem({ ...VALID_THEOREM, thmStatus: "verified" })).toBe(false);
  });

  it("rejects when thmNumber is a string", () => {
    expect(isTheorem({ ...VALID_THEOREM, thmNumber: "1" })).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isMeta
// ════════════════════════════════════════════════════════════════

describe("isMeta", () => {
  it("accepts a valid meta response", () => {
    expect(isMeta(VALID_META)).toBe(true);
  });

  it("accepts meta with extra fields (forward-compatible)", () => {
    const withExtra = { ...VALID_META, newField: 42 };
    expect(isMeta(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isMeta(value)).toBe(false);
  });

  it("rejects when version is missing", () => {
    const { version: _removed, ...rest } = VALID_META;
    expect(isMeta(rest)).toBe(false);
  });

  it("rejects when buildDate is missing", () => {
    const { buildDate: _removed, ...rest } = VALID_META;
    expect(isMeta(rest)).toBe(false);
  });

  it("rejects when agdaVersion is missing", () => {
    const { agdaVersion: _removed, ...rest } = VALID_META;
    expect(isMeta(rest)).toBe(false);
  });

  it("rejects when dataHash is missing", () => {
    const { dataHash: _removed, ...rest } = VALID_META;
    expect(isMeta(rest)).toBe(false);
  });

  it("rejects when version is a number", () => {
    expect(isMeta({ ...VALID_META, version: 0.6 })).toBe(false);
  });

  it("rejects when agdaVersion is a number", () => {
    expect(isMeta({ ...VALID_META, agdaVersion: 2.8 })).toBe(false);
  });

  it("rejects an object using 'meta' prefix (Haskell field names instead of JSON keys)", () => {
    // The Haskell type uses metaVersion, metaBuildDate, etc., but
    // Aeson strips the 4-character "meta" prefix for JSON serialization.
    const haskellFieldNames = {
      metaVersion: "0.6.0",
      metaBuildDate: "2026-04-13T21:04:23Z",
      metaAgdaVersion: "2.8.0",
      metaDataHash: "f8fcfb4dc6d9be08",
    };
    expect(isMeta(haskellFieldNames)).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isHealth
// ════════════════════════════════════════════════════════════════

describe("isHealth", () => {
  it("accepts a valid health response", () => {
    expect(isHealth(VALID_HEALTH)).toBe(true);
  });

  it("accepts health with extra fields (forward-compatible)", () => {
    const withExtra = { ...VALID_HEALTH, uptime: 12345 };
    expect(isHealth(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isHealth(value)).toBe(false);
  });

  it("rejects when status is missing", () => {
    const { status: _removed, ...rest } = VALID_HEALTH;
    expect(isHealth(rest)).toBe(false);
  });

  it("rejects when patchCount is missing", () => {
    const { patchCount: _removed, ...rest } = VALID_HEALTH;
    expect(isHealth(rest)).toBe(false);
  });

  it("rejects when regionCount is missing", () => {
    const { regionCount: _removed, ...rest } = VALID_HEALTH;
    expect(isHealth(rest)).toBe(false);
  });

  it("rejects when status is a number", () => {
    expect(isHealth({ ...VALID_HEALTH, status: 200 })).toBe(false);
  });

  it("rejects when patchCount is a string", () => {
    expect(isHealth({ ...VALID_HEALTH, patchCount: "14" })).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  isCurvatureSummary
// ════════════════════════════════════════════════════════════════

describe("isCurvatureSummary", () => {
  it("accepts a valid curvature summary (dense-100 shape)", () => {
    expect(isCurvatureSummary(VALID_CURVATURE_SUMMARY)).toBe(true);
  });

  it("accepts curvature summary for a 2D patch (filled shape)", () => {
    const filled = {
      patchName: "filled",
      tiling: "Tiling54",
      curvTotal: 10,
      curvEuler: 10,
      gaussBonnet: true,
      curvDenominator: 10,
    };
    expect(isCurvatureSummary(filled)).toBe(true);
  });

  it("accepts curvature summary with extra fields (forward-compatible)", () => {
    const withExtra = { ...VALID_CURVATURE_SUMMARY, extraField: "test" };
    expect(isCurvatureSummary(withExtra)).toBe(true);
  });

  it.each(COMMON_REJECTS)("rejects %s", (_label, value) => {
    expect(isCurvatureSummary(value)).toBe(false);
  });

  it("rejects when patchName is missing", () => {
    const { patchName: _removed, ...rest } = VALID_CURVATURE_SUMMARY;
    expect(isCurvatureSummary(rest)).toBe(false);
  });

  it("rejects when tiling is missing", () => {
    const { tiling: _removed, ...rest } = VALID_CURVATURE_SUMMARY;
    expect(isCurvatureSummary(rest)).toBe(false);
  });

  it("rejects when curvTotal is missing", () => {
    const { curvTotal: _removed, ...rest } = VALID_CURVATURE_SUMMARY;
    expect(isCurvatureSummary(rest)).toBe(false);
  });

  it("rejects when curvEuler is missing", () => {
    const { curvEuler: _removed, ...rest } = VALID_CURVATURE_SUMMARY;
    expect(isCurvatureSummary(rest)).toBe(false);
  });

  it("rejects when gaussBonnet is missing", () => {
    const { gaussBonnet: _removed, ...rest } = VALID_CURVATURE_SUMMARY;
    expect(isCurvatureSummary(rest)).toBe(false);
  });

  it("rejects when curvDenominator is missing", () => {
    const { curvDenominator: _removed, ...rest } = VALID_CURVATURE_SUMMARY;
    expect(isCurvatureSummary(rest)).toBe(false);
  });

  it("rejects when gaussBonnet is a string", () => {
    expect(
      isCurvatureSummary({
        ...VALID_CURVATURE_SUMMARY,
        gaussBonnet: "true",
      }),
    ).toBe(false);
  });

  it("rejects when curvDenominator is a string", () => {
    expect(
      isCurvatureSummary({
        ...VALID_CURVATURE_SUMMARY,
        curvDenominator: "20",
      }),
    ).toBe(false);
  });

  it("rejects when tiling is a number (it's raw text in CurvatureSummary)", () => {
    expect(
      isCurvatureSummary({
        ...VALID_CURVATURE_SUMMARY,
        tiling: 435,
      }),
    ).toBe(false);
  });

  it("rejects an object using 'cs' prefix (Haskell field names instead of JSON keys)", () => {
    // The Haskell type uses csPatchName, csTiling, etc., but
    // Aeson strips the 2-character "cs" prefix for JSON serialization.
    const haskellFieldNames = {
      csPatchName: "dense-100",
      csTiling: "Tiling435",
      csCurvTotal: -60,
      csCurvEuler: -60,
      csGaussBonnet: true,
      csCurvDenominator: 20,
    };
    expect(isCurvatureSummary(haskellFieldNames)).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  JSON Shape Assertions — Full API Response Shapes
// ════════════════════════════════════════════════════════════════

describe("JSON shape assertions — full response shapes from actual data files", () => {
  /**
   * These tests verify that objects mimicking the exact shapes found
   * in the actual data/*.json files pass the corresponding guards.
   * This catches regressions where a type guard drifts from the real
   * API response format.
   */

  it("tower.json entry for layer-54-d3 passes isTowerLevel", () => {
    // Exact shape from data/tower.json
    const entry = {
      tlHasAreaLaw: false,
      tlHasBridge: true,
      tlHasHalfBound: false,
      tlMaxCut: 2,
      tlMonotone: [0, "refl"],
      tlOrbits: 2,
      tlPatchName: "layer-54-d3",
      tlRegions: 40,
    };
    expect(isTowerLevel(entry)).toBe(true);
  });

  it("theorems.json entry for Theorem 5 passes isTheorem", () => {
    // Exact shape from data/theorems.json
    const entry = {
      thmModule: "Causal/NoCTC.agda",
      thmName: "No Closed Timelike Curves",
      thmNumber: 5,
      thmProofMethod: "Well-foundedness of (ℕ, <) via snotz + injSuc",
      thmStatement: "Structural acyclicity from ℕ well-foundedness.",
      thmStatus: "Verified",
    };
    expect(isTheorem(entry)).toBe(true);
  });

  it("meta.json passes isMeta", () => {
    // Exact shape from data/meta.json
    const entry = {
      agdaVersion: "2.8.0",
      buildDate: "2026-04-13T21:04:23Z",
      dataHash: "f8fcfb4dc6d9be08",
      version: "0.6.0",
    };
    expect(isMeta(entry)).toBe(true);
  });

  it("curvature.json entry for desitter passes isCurvatureSummary", () => {
    // Exact shape from data/curvature.json
    const entry = {
      curvDenominator: 10,
      curvEuler: 10,
      curvTotal: 10,
      gaussBonnet: true,
      patchName: "desitter",
      tiling: "Tiling53",
    };
    expect(isCurvatureSummary(entry)).toBe(true);
  });

  it("star.json region 5 passes isRegion", () => {
    // Exact shape from data/patches/star.json (after regionCurvature addition)
    const entry = {
      regionArea: 10,
      regionCells: [0, 1],
      regionCurvature: null,
      regionHalfSlack: 6,
      regionId: 5,
      regionMinCut: 2,
      regionOrbit: "mc2",
      regionRatio: 0.2,
      regionSize: 2,
    };
    expect(isRegion(entry)).toBe(true);
  });

  it("tree.json region 0 passes isRegion", () => {
    // Exact shape from data/patches/tree.json — note regionHalfSlack is 3 (integer)
    const entry = {
      regionArea: 5,
      regionCells: [0],
      regionCurvature: null,
      regionHalfSlack: 3,
      regionId: 0,
      regionMinCut: 1,
      regionOrbit: "mc1",
      regionRatio: 0.2,
      regionSize: 1,
    };
    expect(isRegion(entry)).toBe(true);
  });

  it("layer-54-d2.json region with minCut=2 passes isRegion", () => {
    // Exact shape from data/patches/layer-54-d2.json
    const entry = {
      regionArea: 5,
      regionCells: [6],
      regionCurvature: null,
      regionHalfSlack: 1,
      regionId: 0,
      regionMinCut: 2,
      regionOrbit: "mc2",
      regionRatio: 0.4,
      regionSize: 1,
    };
    expect(isRegion(entry)).toBe(true);
  });

  it("dense-100 region with numeric regionCurvature passes isRegion", () => {
    // A region from a patch where per-cell curvature is computed.
    // 3D ({4,3,5}) patches have regionCurvature as a double.
    const entry = {
      regionArea: 6,
      regionCells: [14],
      regionCurvature: -0.25,
      regionHalfSlack: 4,
      regionId: 0,
      regionMinCut: 1,
      regionOrbit: "mc1",
      regionRatio: 0.1667,
      regionSize: 1,
    };
    expect(isRegion(entry)).toBe(true);
  });

  it("star.json patchGraph passes isPatchGraph", () => {
    // Exact shape from data/patches/star.json
    const entry = {
      pgEdges: [mkEdge(0, 5), mkEdge(1, 5), mkEdge(2, 5), mkEdge(3, 5), mkEdge(4, 5)],
      pgNodes: mkNodes(6),
    };
    expect(isPatchGraph(entry)).toBe(true);
  });

  it("tree.json patchGraph passes isPatchGraph", () => {
    // Exact shape from data/patches/tree.json
    const entry = {
      pgEdges: [
        mkEdge(0, 4), mkEdge(1, 4), mkEdge(2, 5),
        mkEdge(3, 5), mkEdge(4, 6), mkEdge(5, 6),
      ],
      pgNodes: mkNodes(7),
    };
    expect(isPatchGraph(entry)).toBe(true);
  });

  it("honeycomb-3d.json patchGraph passes isPatchGraph", () => {
    // Subset of the actual shape from data/patches/honeycomb-3d.json
    // (32 nodes, 39 edges — only first few edges shown for brevity)
    const entry = {
      pgNodes: mkNodes(32),
      pgEdges: [
        mkEdge(0, 1), mkEdge(0, 2), mkEdge(0, 3),
        mkEdge(0, 4), mkEdge(0, 5), mkEdge(0, 6),
      ],
    };
    expect(isPatchGraph(entry)).toBe(true);
  });

  it("full star.json patch shape (with patchGraph) passes isPatch", () => {
    // Exact shape from data/patches/star.json (abridged regionData)
    const entry = {
      patchBonds: 5,
      patchBoundary: 20,
      patchCells: 6,
      patchCurvature: null,
      patchDensity: 1.67,
      patchDimension: 2,
      patchGraph: {
        pgEdges: [
          mkEdge(0, 5), mkEdge(1, 5), mkEdge(2, 5),
          mkEdge(3, 5), mkEdge(4, 5),
        ],
        pgNodes: mkNodes(6),
      },
      patchHalfBound: {
        hbAchieverCount: 0,
        hbAchieverSizes: [],
        hbMeanSlack: 4.5,
        hbRegionCount: 10,
        hbSlackRange: [3, 6],
        hbViolations: 0,
      },
      patchHalfBoundVerified: false,
      patchMaxCut: 2,
      patchName: "star",
      patchOrbits: 0,
      patchRegionData: [
        {
          regionArea: 5,
          regionCells: [0],
          regionCurvature: null,
          regionHalfSlack: 3,
          regionId: 0,
          regionMinCut: 1,
          regionOrbit: "mc1",
          regionRatio: 0.2,
          regionSize: 1,
        },
      ],
      patchRegions: 10,
      patchStrategy: "BFS",
      patchTiling: "Tiling54",
    };
    expect(isPatch(entry)).toBe(true);
  });
});