/**
 * Smoke tests for PatchScene (src/components/patches/PatchScene.tsx).
 *
 * PatchScene renders a Three.js Canvas via @react-three/fiber, which
 * requires a WebGL context unavailable in the jsdom test environment.
 * The R3F Canvas and drei OrbitControls are mocked to plain DOM
 * elements so the component can mount without WebGL.
 *
 * What IS tested (component logic executes fully):
 *   - Force-directed layout computation (d3-force-3d or fallback)
 *   - Bond extraction from patchGraph.pgEdges (all physical bonds)
 *   - Color mapping across all four color modes
 *   - Cell-to-region mapping and selection logic
 *   - Accessible aria-label construction (with bulk/boundary breakdown)
 *   - Camera distance auto-computation from bounding box
 *   - Instancing threshold evaluation (shouldUseInstancing)
 *   - Interior vs boundary cell classification
 *   - Visibility toggles for bonds, boundary wireframe, and boundary shell
 *
 * What is NOT tested (requires real WebGL):
 *   - Actual Three.js mesh rendering and material application
 *   - OrbitControls interaction (rotate, zoom, pan)
 *   - Click raycasting on 3D meshes
 *   - InstancedMesh GPU buffer uploads
 *
 * The Canvas mock does NOT render its children into the DOM, because
 * R3F reconciler elements (<mesh>, <ambientLight>, etc.) are not
 * standard HTML elements and would produce spurious React prop
 * warnings. The JSX tree for children is still constructed by
 * PatchScene's render function (React.createElement calls execute),
 * so all props and callbacks in the JSX are evaluated.
 *
 * **Phase 1 updates (patchGraph):**
 *   All mock Patch objects now include the `patchGraph` field with
 *   `pgNodes` (all cell IDs, boundary + interior) and `pgEdges`
 *   (all physical bonds). The aria-label assertions are updated to
 *   match the new format which reports boundary/interior cell counts
 *   and physical bond counts from the bulk graph.
 *
 * **Phase 2 updates (showShell):**
 *   PatchSceneProps now requires a `showShell: boolean` prop controlling
 *   the semi-transparent boundary shell overlay (src/components/patches/
 *   BoundaryShell.tsx).  The `defaultProps` factory includes
 *   `showShell: false` so existing tests compile unchanged, and new
 *   smoke tests in the "visibility toggles" describe block exercise
 *   `showShell={true}` — both alone and in combination with the other
 *   toggles — across 2D and 3D patches.
 * 
 * **Poincaré-projection updates (post-Fix C):**
 *   The `Patch` type's `patchGraph` field tightened its wire schema:
 *     - `pgNodes` is now `GraphNode[]` (objects carrying per-cell
 *       Poincaré position, quaternion, and conformal scale)
 *     - `pgEdges` is now `Edge[]` (`{source, target}` objects)
 *   All mock fixtures below construct these via the `mkNode` / `mkEdge`
 *   helpers so the suite compiles under `strict: true` and matches the
 *   actual JSON emitted by `18_export_json.py`.
 *
 * Reference:
 *   - src/components/patches/PatchScene.tsx (component under test)
 *   - src/components/patches/BoundaryShell.tsx (rendered when showShell=true)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.1 (Scene Structure)
 *   - docs/engineering/frontend-spec-webgl.md §6.3 (Performance)
 *   - Rules §11 (Testing: smoke test with mock patch data, no crash)
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";

// ════════════════════════════════════════════════════════════════
//  R3F / drei Mocks
// ════════════════════════════════════════════════════════════════

/**
 * Mock @react-three/fiber.
 *
 * Canvas is replaced with a plain `<div>` that does NOT render
 * children. This avoids DOM reconciliation of R3F-specific elements
 * (<mesh>, <ambientLight>, <instancedMesh>, etc.) which are not
 * valid HTML elements.
 *
 * PatchScene's outer wrapper `<div role="img" aria-label="...">` is
 * a standard DOM element and renders normally in jsdom — it is NOT
 * affected by this mock.
 */
vi.mock("@react-three/fiber", () => ({
  Canvas: () => <div data-testid="r3f-canvas" />,
}));

/**
 * Mock @react-three/drei.
 *
 * OrbitControls requires R3F's internal store context which does
 * not exist in the mocked environment. Replaced with a no-op.
 */
vi.mock("@react-three/drei", () => ({
  OrbitControls: () => null,
}));

// ════════════════════════════════════════════════════════════════
//  Imports (after mocks — vi.mock is hoisted by Vitest)
// ════════════════════════════════════════════════════════════════

import { PatchScene } from "../../src/components/patches/PatchScene";
import type { Patch, Region, ColorMode, GraphNode, Edge } from "../../src/types";

// ════════════════════════════════════════════════════════════════
//  Test Setup
// ════════════════════════════════════════════════════════════════

/**
 * Clear the sessionStorage layout cache between tests.
 *
 * computePatchLayout (src/utils/layout.ts) caches force-directed
 * positions in sessionStorage keyed by patch name + node count.
 * Clearing between tests ensures each test exercises the full
 * layout pipeline rather than reading a stale cache from a prior
 * test.
 */
beforeEach(() => {
  try {
    sessionStorage.clear();
  } catch {
    // sessionStorage may not be available in all environments
  }
});

// ════════════════════════════════════════════════════════════════
//  Mock Data Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Create a minimal valid Region object.
 *
 * @param id - Unique region ID
 * @param cells - Cell IDs in this region
 * @param minCut - Min-cut entropy S(A)
 * @param area - Boundary surface area
 */
function mockRegion(
  id: number,
  cells: number[],
  minCut: number,
  area: number,
): Region {
  return {
    regionId: id,
    regionCells: cells,
    regionSize: cells.length,
    regionMinCut: minCut,
    regionArea: area,
    regionOrbit: `mc${minCut}`,
    regionHalfSlack: area - 2 * minCut,
    regionRatio: area > 0 ? Math.round((minCut / area) * 10000) / 10000 : 0,
    regionCurvature: null,
  };
}

/**
 * Build a structurally valid {@link GraphNode} fixture.
 *
 * Defaults place the node at the Poincaré origin with the identity
 * quaternion and the central conformal scale `s(0) = 0.5`. Tests that
 * care about specific geometry override the relevant fields; smoke
 * tests that only care about the schema can pass just the id.
 *
 * Mirrors the fixture factory used by `types.test.ts` so both suites
 * exercise the same wire shape.
 */
function mkNode(
  id: number,
  overrides: Partial<{
    x: number; y: number; z: number;
    qx: number; qy: number; qz: number; qw: number;
    scale: number;
  }> = {},
): GraphNode {
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
 * Build a structurally valid {@link Edge} fixture — `{source, target}`
 * per the wire format emitted by `18_export_json.py::_make_patch_graph`.
 */
function mkEdge(source: number, target: number): Edge {
  return { source, target };
}

// ════════════════════════════════════════════════════════════════
//  Mock Patch Data
// ════════════════════════════════════════════════════════════════

/**
 * Star-like 2D pentagonal patch (5 singletons + 5 pairs).
 *
 * Topology: 6 cells — N0=0, N1=1, N2=2, N3=3, N4=4, C=5.
 * C is interior (all 5 faces shared, 0 boundary legs, appears
 * in no singleton region). N0–N4 are boundary.
 *
 * patchGraph.pgNodes: all 6 cells (including interior C=5).
 * patchGraph.pgEdges: 5 physical bonds (C–N0, C–N1, ..., C–N4).
 *
 * Exercises: 2D layout, Tiling54 geometry, min-cut range [1, 2],
 * interior vs boundary cell distinction, and basic color mapping.
 */
const STAR_PATCH: Patch = {
  patchName: "test-star",
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
  patchRegionData: [
    // 5 singletons (S=1) — boundary cells 0–4
    mockRegion(0, [0], 1, 5),
    mockRegion(1, [1], 1, 5),
    mockRegion(2, [2], 1, 5),
    mockRegion(3, [3], 1, 5),
    mockRegion(4, [4], 1, 5),
    // 5 adjacent pairs (S=2)
    mockRegion(5, [0, 1], 2, 10),
    mockRegion(6, [1, 2], 2, 10),
    mockRegion(7, [2, 3], 2, 10),
    mockRegion(8, [3, 4], 2, 10),
    mockRegion(9, [4, 0], 2, 10),
  ],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: [
      mkNode(0), mkNode(1), mkNode(2),
      mkNode(3), mkNode(4), mkNode(5),
    ],
    pgEdges: [
      mkEdge(0, 5), mkEdge(1, 5), mkEdge(2, 5),
      mkEdge(3, 5), mkEdge(4, 5),
    ],
  },
};

/**
 * 3D cubic honeycomb patch with curvature data.
 *
 * Topology: 10 cells (0–9). Regions reference cells {0,1,2},
 * so 3 boundary cells and 7 interior cells.
 *
 * Exercises: 3D layout, Tiling435 geometry, non-null curvature,
 * non-null half-bound, orbit reduction (psOrbits > 0), interior
 * cell rendering, and the "curvature" color mode path.
 */
const CUBIC_PATCH: Patch = {
  patchName: "test-cubic",
  patchTiling: "Tiling435",
  patchDimension: 3,
  patchCells: 10,
  patchRegions: 6,
  patchOrbits: 2,
  patchMaxCut: 3,
  patchBonds: 12,
  patchBoundary: 36,
  patchDensity: 2.4,
  patchStrategy: "Dense",
  patchRegionData: [
    mockRegion(0, [0], 1, 6),
    mockRegion(1, [1], 2, 6),
    mockRegion(2, [2], 3, 6),
    mockRegion(3, [0, 1], 2, 10),
    mockRegion(4, [1, 2], 3, 10),
    mockRegion(5, [0, 2], 2, 10),
  ],
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
    hbRegionCount: 6,
    hbViolations: 0,
    hbAchieverCount: 1,
    hbAchieverSizes: [[1, 1]],
    hbSlackRange: [0, 4],
    hbMeanSlack: 2.0,
  },
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: Array.from({ length: 10 }, (_, i) => mkNode(i)),
    pgEdges: [
      mkEdge(0, 1), mkEdge(0, 2), mkEdge(0, 3),
      mkEdge(1, 2), mkEdge(1, 4), mkEdge(2, 5),
      mkEdge(3, 4), mkEdge(3, 6), mkEdge(4, 5),
      mkEdge(5, 7), mkEdge(6, 8), mkEdge(7, 9),
    ],
  },
};

/**
 * Minimal patch with zero regions.
 *
 * Exercises: empty-regions edge case. One cell exists in the graph
 * but no regions reference it, so it is fully interior. No bonds.
 * The layout returns a Map with one entry. The scene should contain
 * only lights and controls (all mocked).
 */
const EMPTY_PATCH: Patch = {
  patchName: "test-empty",
  patchTiling: "Tree",
  patchDimension: 1,
  patchCells: 1,
  patchRegions: 0,
  patchOrbits: 0,
  patchMaxCut: 0,
  patchBonds: 0,
  patchBoundary: 0,
  patchDensity: 0,
  patchStrategy: "BFS",
  patchRegionData: [],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: [mkNode(0)],
    pgEdges: [],
  },
};

/**
 * Single-cell {5,3} patch.
 *
 * Exercises: single-cell edge case (one singleton region, no bonds).
 * The single cell IS a boundary cell (appears in the region).
 * Camera distance computation with minimal bounding box.
 * Tiling53 pentagonal geometry.
 */
const SINGLE_CELL_PATCH: Patch = {
  patchName: "test-single",
  patchTiling: "Tiling53",
  patchDimension: 2,
  patchCells: 1,
  patchRegions: 1,
  patchOrbits: 0,
  patchMaxCut: 1,
  patchBonds: 0,
  patchBoundary: 5,
  patchDensity: 0,
  patchStrategy: "BFS",
  patchRegionData: [mockRegion(0, [0], 1, 5)],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: [mkNode(0)],
    pgEdges: [],
  },
};

/**
 * {4,4} Euclidean square patch.
 *
 * Topology: 4 cells (0–3). Regions reference cells {0,1,2},
 * so cell 3 is interior.
 *
 * Exercises: Tiling44 geometry (PlaneGeometry), which is not
 * present in the real data but must be handled by the component
 * since it is a valid Tiling enum value.
 */
const SQUARE_PATCH: Patch = {
  patchName: "test-square",
  patchTiling: "Tiling44",
  patchDimension: 2,
  patchCells: 4,
  patchRegions: 4,
  patchOrbits: 0,
  patchMaxCut: 2,
  patchBonds: 4,
  patchBoundary: 8,
  patchDensity: 2.0,
  patchStrategy: "BFS",
  patchRegionData: [
    mockRegion(0, [0], 1, 4),
    mockRegion(1, [1], 1, 4),
    mockRegion(2, [2], 2, 4),
    mockRegion(3, [0, 1], 2, 6),
  ],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: [mkNode(0), mkNode(1), mkNode(2), mkNode(3)],
    pgEdges: [
      mkEdge(0, 1), mkEdge(0, 3), mkEdge(1, 2), mkEdge(2, 3),
    ],
  },
};

/**
 * Tree (1D) patch with a few regions.
 *
 * Topology: 7 cells (0–6). Regions reference cells {0,1,2},
 * so cells 3–6 are interior.
 *
 * Exercises: Tree tiling type (SphereGeometry for nodes), 2D layout
 * (trees are embedded in 2D despite being 1-dimensional structures),
 * and a significant interior cell count.
 */
const TREE_PATCH: Patch = {
  patchName: "test-tree",
  patchTiling: "Tree",
  patchDimension: 1,
  patchCells: 7,
  patchRegions: 4,
  patchOrbits: 0,
  patchMaxCut: 2,
  patchBonds: 6,
  patchBoundary: 4,
  patchDensity: 1.71,
  patchStrategy: "BFS",
  patchRegionData: [
    mockRegion(0, [0], 1, 5),
    mockRegion(1, [1], 1, 5),
    mockRegion(2, [0, 1], 2, 10),
    mockRegion(3, [2], 1, 5),
  ],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: Array.from({ length: 7 }, (_, i) => mkNode(i)),
    pgEdges: [
      mkEdge(0, 4), mkEdge(1, 4), mkEdge(2, 5),
      mkEdge(3, 5), mkEdge(4, 6), mkEdge(5, 6),
    ],
  },
};

// ════════════════════════════════════════════════════════════════
//  Default Props Factory
// ════════════════════════════════════════════════════════════════

/**
 * Build a complete PatchSceneProps object with sensible defaults.
 *
 * All callback props are vi.fn() mocks so call assertions are
 * available if needed. Override specific props via the spread
 * operator: `{ ...defaultProps(patch), colorMode: "ratio" }`.
 *
 * **Phase 2 update (showShell):**
 *   PatchSceneProps now requires a `showShell: boolean` prop
 *   controlling the semi-transparent boundary shell overlay.
 *   Defaulting to `false` keeps existing tests' behavior unchanged
 *   (the shell is off unless a test explicitly enables it) and
 *   satisfies the type requirement for compilation under
 *   `strict: true`.
 */
function defaultProps(patch: Patch) {
  return {
    patch,
    colorMode: "mincut" as ColorMode,
    selectedRegion: null as Region | null,
    onCellClick: vi.fn(),
    showBonds: true,
    showBoundary: false,
    showShell: false,
    onBackgroundClick: vi.fn(),
  };
}

// ════════════════════════════════════════════════════════════════
//  Tests
// ════════════════════════════════════════════════════════════════

describe("PatchScene", () => {
  // ──────────────────────────────────────────────────────────────
  //  Basic rendering — no crash
  // ──────────────────────────────────────────────────────────────

  describe("basic rendering — no crash", () => {
    it("renders without crashing for a 2D {5,4} pentagonal patch", () => {
      expect(() =>
        render(<PatchScene {...defaultProps(STAR_PATCH)} />),
      ).not.toThrow();
    });

    it("renders without crashing for a 3D {4,3,5} cubic patch", () => {
      expect(() =>
        render(<PatchScene {...defaultProps(CUBIC_PATCH)} />),
      ).not.toThrow();
    });

    it("renders without crashing for an empty patch (zero regions)", () => {
      expect(() =>
        render(<PatchScene {...defaultProps(EMPTY_PATCH)} />),
      ).not.toThrow();
    });

    it("renders without crashing for a single-cell patch", () => {
      expect(() =>
        render(<PatchScene {...defaultProps(SINGLE_CELL_PATCH)} />),
      ).not.toThrow();
    });

    it("renders without crashing for a {4,4} square patch", () => {
      expect(() =>
        render(<PatchScene {...defaultProps(SQUARE_PATCH)} />),
      ).not.toThrow();
    });

    it("renders without crashing for a Tree patch", () => {
      expect(() =>
        render(<PatchScene {...defaultProps(TREE_PATCH)} />),
      ).not.toThrow();
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Accessible wrapper element
  // ──────────────────────────────────────────────────────────────

  describe("accessible wrapper", () => {
    it("renders a wrapper div with role='img'", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const wrapper = screen.getByRole("img");
      expect(wrapper).toBeInTheDocument();
    });

    it("includes the patch name in the aria-label", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("test-star");
    });

    it("includes the cell count in the aria-label", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("6 cells");
    });

    it("includes the region count in the aria-label", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("10 regions");
    });

    it("includes the max min-cut in the aria-label", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("S=2");
    });

    it("includes the tiling type in the aria-label", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("Tiling54");
    });

    it("includes 'No region selected' when selectedRegion is null", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("No region selected");
    });

    it("includes selected region info when a region is selected", () => {
      const selected = STAR_PATCH.patchRegionData[0]!;
      render(
        <PatchScene
          {...defaultProps(STAR_PATCH)}
          selectedRegion={selected}
        />,
      );

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain(`Region ${selected.regionId} selected`);
      expect(label).toContain(`S=${selected.regionMinCut}`);
      expect(label).toContain(`area=${selected.regionArea}`);
    });

    it("updates aria-label for 3D patch with different stats", () => {
      render(<PatchScene {...defaultProps(CUBIC_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("test-cubic");
      expect(label).toContain("10 cells");
      expect(label).toContain("S=3");
      expect(label).toContain("Tiling435");
    });

    it("includes physical bond count in the aria-label", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("5 physical bonds");
    });

    it("reports 12 physical bonds for cubic patch", () => {
      render(<PatchScene {...defaultProps(CUBIC_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("12 physical bonds");
    });

    it("reports 0 physical bonds for empty patch", () => {
      render(<PatchScene {...defaultProps(EMPTY_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(label).toContain("0 physical bonds");
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Canvas container
  // ──────────────────────────────────────────────────────────────

  describe("canvas container", () => {
    it("renders the mocked R3F Canvas element", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      expect(screen.getByTestId("r3f-canvas")).toBeInTheDocument();
    });

    it("Canvas mock is a child of the accessible wrapper", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const wrapper = screen.getByRole("img");
      const canvas = screen.getByTestId("r3f-canvas");
      expect(wrapper).toContainElement(canvas);
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Color modes — all four modes render without error
  // ──────────────────────────────────────────────────────────────

  describe("color modes", () => {
    const modes: ColorMode[] = ["mincut", "regionSize", "ratio", "curvature"];

    it.each(modes)(
      "renders a 2D patch without crashing in '%s' color mode",
      (mode) => {
        expect(() =>
          render(
            <PatchScene {...defaultProps(STAR_PATCH)} colorMode={mode} />,
          ),
        ).not.toThrow();
      },
    );

    it.each(modes)(
      "renders a 3D patch without crashing in '%s' color mode",
      (mode) => {
        expect(() =>
          render(
            <PatchScene {...defaultProps(CUBIC_PATCH)} colorMode={mode} />,
          ),
        ).not.toThrow();
      },
    );

    it.each(modes)(
      "renders an empty patch without crashing in '%s' color mode",
      (mode) => {
        expect(() =>
          render(
            <PatchScene {...defaultProps(EMPTY_PATCH)} colorMode={mode} />,
          ),
        ).not.toThrow();
      },
    );
  });

  // ──────────────────────────────────────────────────────────────
  //  Visibility toggles
  // ──────────────────────────────────────────────────────────────

  describe("visibility toggles", () => {
    it("renders without crashing with showBonds=false", () => {
      expect(() =>
        render(
          <PatchScene {...defaultProps(STAR_PATCH)} showBonds={false} />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showBoundary=true", () => {
      expect(() =>
        render(
          <PatchScene {...defaultProps(STAR_PATCH)} showBoundary={true} />,
        ),
      ).not.toThrow();
    });

    // ── showShell toggle (Phase 2, item 16) ──────────────────────
    //
    //  BoundaryShell attempts a lazy dynamic import of ConvexGeometry
    //  from three/examples/jsm.  In the jsdom test environment the
    //  module may or may not resolve; either path is acceptable —
    //  the component falls back to a fitted SphereGeometry when
    //  ConvexGeometry is unavailable.  These tests verify that
    //  PatchScene mounts without crashing in both cases.

    it("renders without crashing with showShell=true on a 2D patch", () => {
      expect(() =>
        render(
          <PatchScene {...defaultProps(STAR_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showShell=true on a 3D patch", () => {
      expect(() =>
        render(
          <PatchScene {...defaultProps(CUBIC_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showShell=true on an empty patch", () => {
      // BoundaryShell bails out (renders null) when fewer than 3
      // boundary cells are provided.  PatchScene must still mount.
      expect(() =>
        render(
          <PatchScene {...defaultProps(EMPTY_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showShell=true on a single-cell patch", () => {
      // Single-cell patch has 1 boundary cell < MIN_CELLS (3);
      // BoundaryShell returns null but PatchScene mounts cleanly.
      expect(() =>
        render(
          <PatchScene {...defaultProps(SINGLE_CELL_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showShell=true on a Tree patch", () => {
      expect(() =>
        render(
          <PatchScene {...defaultProps(TREE_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showShell=true on a {4,4} square patch", () => {
      expect(() =>
        render(
          <PatchScene {...defaultProps(SQUARE_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("handles toggling showShell from false to true without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} showShell={false} />,
      );

      expect(() =>
        rerender(
          <PatchScene {...defaultProps(STAR_PATCH)} showShell={true} />,
        ),
      ).not.toThrow();
    });

    it("handles toggling showShell from true to false without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} showShell={true} />,
      );

      expect(() =>
        rerender(
          <PatchScene {...defaultProps(STAR_PATCH)} showShell={false} />,
        ),
      ).not.toThrow();
    });

    // ── Combinations ─────────────────────────────────────────────

    it("renders without crashing with all three toggles off", () => {
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            showBonds={false}
            showBoundary={false}
            showShell={false}
          />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with all three toggles on", () => {
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            showBonds={true}
            showBoundary={true}
            showShell={true}
          />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with only showShell enabled", () => {
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(CUBIC_PATCH)}
            showBonds={false}
            showBoundary={false}
            showShell={true}
          />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with showShell + showBoundary but no bonds", () => {
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(CUBIC_PATCH)}
            showBonds={false}
            showBoundary={true}
            showShell={true}
          />,
        ),
      ).not.toThrow();
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Region selection
  // ──────────────────────────────────────────────────────────────

  describe("region selection", () => {
    it("renders without crashing with a selected singleton region", () => {
      const selected = STAR_PATCH.patchRegionData[0]!;
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            selectedRegion={selected}
          />,
        ),
      ).not.toThrow();
    });

    it("renders without crashing with a selected multi-cell region", () => {
      const selected = STAR_PATCH.patchRegionData[5]!; // size-2 region [0, 1]
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            selectedRegion={selected}
          />,
        ),
      ).not.toThrow();
    });

    it("handles transition from selected to null without crashing", () => {
      const selected = STAR_PATCH.patchRegionData[0]!;
      const { rerender } = render(
        <PatchScene
          {...defaultProps(STAR_PATCH)}
          selectedRegion={selected}
        />,
      );

      expect(() =>
        rerender(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            selectedRegion={null}
          />,
        ),
      ).not.toThrow();
    });

    it("handles transition from null to selected without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} selectedRegion={null} />,
      );

      const selected = STAR_PATCH.patchRegionData[2]!;
      expect(() =>
        rerender(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            selectedRegion={selected}
          />,
        ),
      ).not.toThrow();
    });

    it("handles changing to a different selected region without crashing", () => {
      const first = STAR_PATCH.patchRegionData[0]!;
      const { rerender } = render(
        <PatchScene
          {...defaultProps(STAR_PATCH)}
          selectedRegion={first}
        />,
      );

      const second = STAR_PATCH.patchRegionData[3]!;
      expect(() =>
        rerender(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            selectedRegion={second}
          />,
        ),
      ).not.toThrow();
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  All five tiling types
  // ──────────────────────────────────────────────────────────────

  describe("tiling types", () => {
    const tilingPatches: [string, Patch][] = [
      ["Tiling54", STAR_PATCH],
      ["Tiling435", CUBIC_PATCH],
      ["Tiling53", SINGLE_CELL_PATCH],
      ["Tiling44", SQUARE_PATCH],
      ["Tree", TREE_PATCH],
    ];

    it.each(tilingPatches)(
      "renders without crashing for tiling type %s",
      (_tilingName, patch) => {
        expect(() =>
          render(<PatchScene {...defaultProps(patch)} />),
        ).not.toThrow();
      },
    );
  });

  // ──────────────────────────────────────────────────────────────
  //  Callback props
  // ──────────────────────────────────────────────────────────────

  describe("callback props", () => {
    it("accepts onCellClick callback without errors", () => {
      const onCellClick = vi.fn();
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            onCellClick={onCellClick}
          />,
        ),
      ).not.toThrow();
    });

    it("accepts onBackgroundClick callback without errors", () => {
      const onBackgroundClick = vi.fn();
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            onBackgroundClick={onBackgroundClick}
          />,
        ),
      ).not.toThrow();
    });

    it("accepts undefined onBackgroundClick without errors", () => {
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            onBackgroundClick={undefined}
          />,
        ),
      ).not.toThrow();
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Re-render with different patch data
  // ──────────────────────────────────────────────────────────────

  describe("re-render with different patch data", () => {
    it("handles patch change from 2D to 3D without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} />,
      );

      expect(() =>
        rerender(<PatchScene {...defaultProps(CUBIC_PATCH)} />),
      ).not.toThrow();
    });

    it("handles patch change from populated to empty without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} />,
      );

      expect(() =>
        rerender(<PatchScene {...defaultProps(EMPTY_PATCH)} />),
      ).not.toThrow();
    });

    it("handles patch change from empty to populated without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(EMPTY_PATCH)} />,
      );

      expect(() =>
        rerender(<PatchScene {...defaultProps(CUBIC_PATCH)} />),
      ).not.toThrow();
    });

    it("handles rapid tiling type change without crashing", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} />,
      );

      // Cycle through several tiling types in quick succession
      rerender(<PatchScene {...defaultProps(CUBIC_PATCH)} />);
      rerender(<PatchScene {...defaultProps(TREE_PATCH)} />);
      rerender(<PatchScene {...defaultProps(SINGLE_CELL_PATCH)} />);
      rerender(<PatchScene {...defaultProps(SQUARE_PATCH)} />);

      // If we reach here, no crash occurred
      expect(screen.getByRole("img")).toBeInTheDocument();
    });

    it("updates aria-label when patch changes", () => {
      const { rerender } = render(
        <PatchScene {...defaultProps(STAR_PATCH)} />,
      );

      const labelBefore =
        screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(labelBefore).toContain("test-star");

      rerender(<PatchScene {...defaultProps(CUBIC_PATCH)} />);

      const labelAfter =
        screen.getByRole("img").getAttribute("aria-label") ?? "";
      expect(labelAfter).toContain("test-cubic");
      expect(labelAfter).not.toContain("test-star");
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Combined state — color mode + selection + toggles
  // ──────────────────────────────────────────────────────────────

  describe("combined visualization state", () => {
    it("renders with all options simultaneously without crashing", () => {
      const selected = CUBIC_PATCH.patchRegionData[2]!; // S=3 region

      expect(() =>
        render(
          <PatchScene
            patch={CUBIC_PATCH}
            colorMode="ratio"
            selectedRegion={selected}
            onCellClick={vi.fn()}
            showBonds={true}
            showBoundary={true}
            showShell={true}
            onBackgroundClick={vi.fn()}
          />,
        ),
      ).not.toThrow();
    });

    it("renders curvature mode with a patch that has curvature data", () => {
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(CUBIC_PATCH)}
            colorMode="curvature"
          />,
        ),
      ).not.toThrow();
    });

    it("renders curvature mode with a patch that lacks curvature data", () => {
      // STAR_PATCH has patchCurvature: null. The curvature color
      // mode should still work (using kappa=0 fallback for all cells).
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(STAR_PATCH)}
            colorMode="curvature"
          />,
        ),
      ).not.toThrow();
    });

    it("renders curvature mode with showShell enabled", () => {
      // Combine curvature color mode with the boundary shell overlay
      // — exercises both the curvature lookup path and the shell
      // geometry construction in a single mount.
      expect(() =>
        render(
          <PatchScene
            {...defaultProps(CUBIC_PATCH)}
            colorMode="curvature"
            showShell={true}
          />,
        ),
      ).not.toThrow();
    });

    it("renders with selected region and showShell enabled", () => {
      const selected = CUBIC_PATCH.patchRegionData[1]!; // S=2 singleton region

      expect(() =>
        render(
          <PatchScene
            {...defaultProps(CUBIC_PATCH)}
            selectedRegion={selected}
            showShell={true}
          />,
        ),
      ).not.toThrow();
    });
  });

  // ──────────────────────────────────────────────────────────────
  //  Boundary / interior cell breakdown in aria-label
  // ──────────────────────────────────────────────────────────────

  describe("boundary / interior cell breakdown in aria-label", () => {
    it("reports boundary and interior counts for star patch (5 boundary, 1 interior)", () => {
      render(<PatchScene {...defaultProps(STAR_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      // Star: cells 0–4 are boundary (in regions), cell 5 (C) is interior
      expect(label).toContain("5 boundary");
      expect(label).toContain("1 interior");
    });

    it("reports all-interior for empty patch (0 boundary, 1 interior)", () => {
      render(<PatchScene {...defaultProps(EMPTY_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      // Empty: 1 cell in pgNodes, 0 regions → 0 boundary, 1 interior
      expect(label).toContain("0 boundary");
      expect(label).toContain("1 interior");
    });

    it("reports boundary and interior counts for cubic patch (3 boundary, 7 interior)", () => {
      render(<PatchScene {...defaultProps(CUBIC_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      // Cubic: regions reference cells {0,1,2} → 3 boundary, 7 interior
      expect(label).toContain("3 boundary");
      expect(label).toContain("7 interior");
    });

    it("reports 'all boundary' for single-cell patch (1 boundary, 0 interior)", () => {
      render(<PatchScene {...defaultProps(SINGLE_CELL_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      // Single cell: appears in a region → boundary. 0 interior → "all boundary"
      expect(label).toContain("all boundary");
    });

    it("reports boundary and interior counts for tree patch (3 boundary, 4 interior)", () => {
      render(<PatchScene {...defaultProps(TREE_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      // Tree: regions reference cells {0,1,2} → 3 boundary, cells 3–6 interior
      expect(label).toContain("3 boundary");
      expect(label).toContain("4 interior");
    });

    it("reports boundary and interior counts for square patch (3 boundary, 1 interior)", () => {
      render(<PatchScene {...defaultProps(SQUARE_PATCH)} />);

      const label = screen.getByRole("img").getAttribute("aria-label") ?? "";
      // Square: regions reference cells {0,1,2} → 3 boundary, cell 3 interior
      expect(label).toContain("3 boundary");
      expect(label).toContain("1 interior");
    });
  });
});