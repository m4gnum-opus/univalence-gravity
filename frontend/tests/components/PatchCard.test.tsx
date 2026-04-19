/**
 * Tests for the PatchCard component (src/components/patches/PatchCard.tsx).
 *
 * Verifies:
 *   1. Renders the patch name as a heading
 *   2. Displays the tiling type as a Schläfli symbol ("{5,4}", "{4,3,5}", etc.)
 *   3. Displays the spatial dimension label ("1D", "2D", "3D")
 *   4. Displays the growth strategy ("BFS", "Dense", etc.)
 *   5. Renders the cell count, region count, and max min-cut value
 *   6. Formats orbit info correctly:
 *      - "717 → 8 orbits" when psOrbits > 0 (orbit reduction active)
 *      - "139" when psOrbits === 0 (flat enumeration, no orbit display)
 *   7. Links to `/patches/:psName` with correct href
 *   8. Has a descriptive ARIA label for accessibility
 *   9. Handles all five tiling types without crashing
 *  10. Handles all four growth strategies without crashing
 *
 * The PatchCard receives PatchSummary data (the lightweight listing
 * type from GET /patches with "ps" prefix fields), NOT the full Patch.
 *
 * Because PatchCard renders a React Router `<Link>`, all tests wrap
 * the component in a `<MemoryRouter>` to provide the routing context
 * without a real browser history.
 *
 * Fix applied (review issue #8):
 *   Dense-50 uses flat enumeration in the Agda formalization (no orbit
 *   reduction — see docs/engineering/scaling-report.md §2, Orbits = "—").
 *   Per backend/src/Types.hs, `patchOrbits = 0` indicates flat
 *   enumeration. The mock data for Dense-50 is corrected from
 *   `psOrbits: 7` (the number of distinct min-cut values, which is
 *   a mathematical property of the data but NOT the value exported
 *   by 18_export_json.py since orbit reduction was not applied) to
 *   `psOrbits: 0` (matching the actual JSON).
 *
 * Reference:
 *   - src/components/patches/PatchCard.tsx (component under test)
 *   - src/types/index.ts (PatchSummary)
 *   - docs/engineering/frontend-spec-webgl.md §5.2 (Patch List)
 *   - docs/engineering/scaling-report.md §2 (Dense-50: Orbits = "—")
 *   - docs/engineering/orbit-reduction.md §8 (Dense-50 uses flat enumeration)
 *   - Rules §11 (Testing Requirements: renders tiling, cell count, orbit info)
 */

import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";

import { PatchCard } from "../../src/components/patches/PatchCard";
import type { PatchSummary } from "../../src/types";

// ════════════════════════════════════════════════════════════════
//  Mock Data — Representative PatchSummary objects
// ════════════════════════════════════════════════════════════════

/**
 * Dense-100: orbit-reduced 3D patch (the most feature-rich card).
 *
 * psOrbits > 0 → region display should be "717 → 8 orbits".
 */
const DENSE_100: PatchSummary = {
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
 * Star: 2D pentagonal patch with flat enumeration (no orbits).
 *
 * psOrbits === 0 → region display should be "10" (no orbit arrow).
 */
const STAR: PatchSummary = {
  psName: "star",
  psTiling: "Tiling54",
  psDimension: 2,
  psCells: 6,
  psRegions: 10,
  psOrbits: 0,
  psMaxCut: 2,
  psStrategy: "BFS",
};

/**
 * Tree: 1D pilot instance — the simplest patch.
 */
const TREE: PatchSummary = {
  psName: "tree",
  psTiling: "Tree",
  psDimension: 1,
  psCells: 7,
  psRegions: 8,
  psOrbits: 0,
  psMaxCut: 2,
  psStrategy: "BFS",
};

/**
 * De Sitter: 2D spherical {5,3} patch.
 */
const DESITTER: PatchSummary = {
  psName: "desitter",
  psTiling: "Tiling53",
  psDimension: 2,
  psCells: 6,
  psRegions: 10,
  psOrbits: 0,
  psMaxCut: 2,
  psStrategy: "BFS",
};

/**
 * Dense-200: third tower level with 9 orbits.
 * Tests large region counts with locale formatting.
 */
const DENSE_200: PatchSummary = {
  psName: "dense-200",
  psTiling: "Tiling435",
  psDimension: 3,
  psCells: 200,
  psRegions: 1246,
  psOrbits: 9,
  psMaxCut: 9,
  psStrategy: "Dense",
};

/**
 * Layer-54-d7: largest patch (1885 regions, 2 orbits).
 * Tests the extreme end of the data range.
 */
const LAYER_54_D7: PatchSummary = {
  psName: "layer-54-d7",
  psTiling: "Tiling54",
  psDimension: 2,
  psCells: 3046,
  psRegions: 1885,
  psOrbits: 2,
  psMaxCut: 2,
  psStrategy: "BFS",
};

/**
 * Honeycomb: 3D BFS patch with all S=1 (uniform min-cut).
 */
const HONEYCOMB: PatchSummary = {
  psName: "honeycomb-3d",
  psTiling: "Tiling435",
  psDimension: 3,
  psCells: 32,
  psRegions: 34,
  psOrbits: 0,
  psMaxCut: 1,
  psStrategy: "BFS",
};

/**
 * A hypothetical {4,4} Euclidean patch — tests the Tiling44 variant.
 *
 * No {4,4} patches exist in the current data, but the PatchCard
 * must handle all Tiling enum values.
 */
const EUCLIDEAN: PatchSummary = {
  psName: "euclidean-test",
  psTiling: "Tiling44",
  psDimension: 2,
  psCells: 25,
  psRegions: 50,
  psOrbits: 0,
  psMaxCut: 3,
  psStrategy: "Geodesic",
};

/**
 * A hypothetical patch using the Hemisphere strategy — tests that
 * the strategy string renders correctly.
 */
const HEMISPHERE: PatchSummary = {
  psName: "hemisphere-test",
  psTiling: "Tiling435",
  psDimension: 3,
  psCells: 20,
  psRegions: 30,
  psOrbits: 0,
  psMaxCut: 2,
  psStrategy: "Hemisphere",
};

// ════════════════════════════════════════════════════════════════
//  Helper: Render with Router Context
// ════════════════════════════════════════════════════════════════

/**
 * Render a PatchCard inside a MemoryRouter.
 *
 * PatchCard uses React Router's `<Link>` component, which requires
 * a Router context. MemoryRouter provides this without interacting
 * with the browser's URL bar.
 *
 * @param patch - The PatchSummary data to display.
 */
function renderCard(patch: PatchSummary) {
  return render(
    <MemoryRouter>
      <PatchCard patch={patch} />
    </MemoryRouter>,
  );
}

// ════════════════════════════════════════════════════════════════
//  Patch Name Rendering
// ════════════════════════════════════════════════════════════════

describe("patch name rendering", () => {
  it("renders the patch name as a heading", () => {
    renderCard(DENSE_100);

    const heading = screen.getByRole("heading", { level: 3 });
    expect(heading).toBeInTheDocument();
    expect(heading).toHaveTextContent("dense-100");
  });

  it("renders 'star' as the heading for the star patch", () => {
    renderCard(STAR);

    expect(
      screen.getByRole("heading", { level: 3 }),
    ).toHaveTextContent("star");
  });

  it("renders 'tree' as the heading for the tree patch", () => {
    renderCard(TREE);

    expect(
      screen.getByRole("heading", { level: 3 }),
    ).toHaveTextContent("tree");
  });

  it("renders hyphenated names correctly", () => {
    renderCard(LAYER_54_D7);

    expect(
      screen.getByRole("heading", { level: 3 }),
    ).toHaveTextContent("layer-54-d7");
  });
});

// ════════════════════════════════════════════════════════════════
//  Tiling Display — Schläfli Symbols
// ════════════════════════════════════════════════════════════════

describe("tiling display", () => {
  it("renders {4,3,5} for Tiling435", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("{4,3,5}")).toBeInTheDocument();
  });

  it("renders {5,4} for Tiling54", () => {
    renderCard(STAR);

    expect(screen.getByText("{5,4}")).toBeInTheDocument();
  });

  it("renders {5,3} for Tiling53", () => {
    renderCard(DESITTER);

    expect(screen.getByText("{5,3}")).toBeInTheDocument();
  });

  it("renders {4,4} for Tiling44", () => {
    renderCard(EUCLIDEAN);

    expect(screen.getByText("{4,4}")).toBeInTheDocument();
  });

  it("renders Tree for Tree tiling", () => {
    renderCard(TREE);

    expect(screen.getByText("Tree")).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  Dimension Label
// ════════════════════════════════════════════════════════════════

describe("dimension label", () => {
  it("renders '3D' for dimension 3", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("3D")).toBeInTheDocument();
  });

  it("renders '2D' for dimension 2", () => {
    renderCard(STAR);

    expect(screen.getByText("2D")).toBeInTheDocument();
  });

  it("renders '1D' for dimension 1", () => {
    renderCard(TREE);

    expect(screen.getByText("1D")).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  Growth Strategy
// ════════════════════════════════════════════════════════════════

describe("growth strategy", () => {
  it("renders 'Dense' strategy", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("Dense")).toBeInTheDocument();
  });

  it("renders 'BFS' strategy", () => {
    renderCard(STAR);

    expect(screen.getByText("BFS")).toBeInTheDocument();
  });

  it("renders 'Geodesic' strategy", () => {
    renderCard(EUCLIDEAN);

    expect(screen.getByText("Geodesic")).toBeInTheDocument();
  });

  it("renders 'Hemisphere' strategy", () => {
    renderCard(HEMISPHERE);

    expect(screen.getByText("Hemisphere")).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  Cell Count
// ════════════════════════════════════════════════════════════════

describe("cell count", () => {
  it("renders the cell count for dense-100 (100)", () => {
    renderCard(DENSE_100);

    // The stats area has a "Cells" label and a "100" value
    expect(screen.getByText("Cells")).toBeInTheDocument();
    expect(screen.getByText("100")).toBeInTheDocument();
  });

  it("renders the cell count for star (6)", () => {
    renderCard(STAR);

    expect(screen.getByText("6")).toBeInTheDocument();
  });

  it("renders the cell count for tree (7)", () => {
    renderCard(TREE);

    expect(screen.getByText("7")).toBeInTheDocument();
  });

  it("renders a large cell count for layer-54-d7 (3046)", () => {
    renderCard(LAYER_54_D7);

    expect(screen.getByText("3046")).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  Region Display — Orbit Formatting
// ════════════════════════════════════════════════════════════════

describe("region and orbit display", () => {
  it("shows 'Regions' label", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("Regions")).toBeInTheDocument();
  });

  it("formats regions with orbit arrow when psOrbits > 0", () => {
    renderCard(DENSE_100);

    // psRegions=717, psOrbits=8 → "717 → 8 orbits"
    expect(screen.getByText("717 → 8 orbits")).toBeInTheDocument();
  });

  it("formats regions without orbit arrow when psOrbits === 0", () => {
    renderCard(STAR);

    // psRegions=10, psOrbits=0 → "10"
    expect(screen.getByText("10")).toBeInTheDocument();

    // Ensure no orbit arrow is present
    const regionsDd = screen.getByText("10");
    expect(regionsDd.textContent).not.toContain("→");
    expect(regionsDd.textContent).not.toContain("orbits");
  });

  it("formats dense-200 regions with orbit arrow (1246 → 9 orbits)", () => {
    renderCard(DENSE_200);

    expect(screen.getByText("1246 → 9 orbits")).toBeInTheDocument();
  });

  it("formats layer-54-d7 regions with orbit arrow (1885 → 2 orbits)", () => {
    renderCard(LAYER_54_D7);

    expect(screen.getByText("1885 → 2 orbits")).toBeInTheDocument();
  });

  it("formats tree regions without orbits (8)", () => {
    renderCard(TREE);

    expect(screen.getByText("8")).toBeInTheDocument();
  });

  it("formats honeycomb regions without orbits (34)", () => {
    renderCard(HONEYCOMB);

    expect(screen.getByText("34")).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  Max Min-Cut Value
// ════════════════════════════════════════════════════════════════

describe("max min-cut value", () => {
  it("shows 'Max S' label", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("Max S")).toBeInTheDocument();
  });

  it("renders maxCut=8 for dense-100", () => {
    renderCard(DENSE_100);

    // The "8" appears as both psCells and psMaxCut for dense-100
    // but under different labels. We verify the Max S label exists.
    const maxSLabel = screen.getByText("Max S");
    expect(maxSLabel).toBeInTheDocument();

    // Find the dd element in the same row as "Max S"
    // The component uses a flex row with dt/dd siblings
    const maxSRow = maxSLabel.closest("div");
    expect(maxSRow).not.toBeNull();
    expect(maxSRow!.textContent).toContain("8");
  });

  it("renders maxCut=2 for star", () => {
    renderCard(STAR);

    const maxSLabel = screen.getByText("Max S");
    const maxSRow = maxSLabel.closest("div");
    expect(maxSRow).not.toBeNull();
    expect(maxSRow!.textContent).toContain("2");
  });

  it("renders maxCut=9 for dense-200", () => {
    renderCard(DENSE_200);

    const maxSLabel = screen.getByText("Max S");
    const maxSRow = maxSLabel.closest("div");
    expect(maxSRow).not.toBeNull();
    expect(maxSRow!.textContent).toContain("9");
  });

  it("renders maxCut=1 for honeycomb (all singletons S=1)", () => {
    renderCard(HONEYCOMB);

    const maxSLabel = screen.getByText("Max S");
    const maxSRow = maxSLabel.closest("div");
    expect(maxSRow).not.toBeNull();
    expect(maxSRow!.textContent).toContain("1");
  });
});

// ════════════════════════════════════════════════════════════════
//  Navigation Link
// ════════════════════════════════════════════════════════════════

describe("navigation link", () => {
  it("renders a 'View Details' link", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("View Details")).toBeInTheDocument();
  });

  it("links to /patches/dense-100 for the dense-100 card", () => {
    renderCard(DENSE_100);

    const link = screen.getByRole("link", { name: /view details for dense-100/i });
    expect(link).toHaveAttribute("href", "/patches/dense-100");
  });

  it("links to /patches/star for the star card", () => {
    renderCard(STAR);

    const link = screen.getByRole("link", { name: /view details for star/i });
    expect(link).toHaveAttribute("href", "/patches/star");
  });

  it("links to /patches/tree for the tree card", () => {
    renderCard(TREE);

    const link = screen.getByRole("link", { name: /view details for tree/i });
    expect(link).toHaveAttribute("href", "/patches/tree");
  });

  it("links to /patches/layer-54-d7 for the layer card", () => {
    renderCard(LAYER_54_D7);

    const link = screen.getByRole("link", { name: /view details for layer-54-d7/i });
    expect(link).toHaveAttribute("href", "/patches/layer-54-d7");
  });

  it("links to /patches/desitter for the desitter card", () => {
    renderCard(DESITTER);

    const link = screen.getByRole("link", { name: /view details for desitter/i });
    expect(link).toHaveAttribute("href", "/patches/desitter");
  });

  it("links to /patches/honeycomb-3d for the honeycomb card", () => {
    renderCard(HONEYCOMB);

    const link = screen.getByRole("link", { name: /view details for honeycomb-3d/i });
    expect(link).toHaveAttribute("href", "/patches/honeycomb-3d");
  });
});

// ════════════════════════════════════════════════════════════════
//  ARIA Label
// ════════════════════════════════════════════════════════════════

describe("aria label", () => {
  it("has an aria-label containing the patch name on the article element", () => {
    renderCard(DENSE_100);

    const article = screen.getByRole("article");
    expect(article).toHaveAttribute(
      "aria-label",
      expect.stringContaining("dense-100"),
    );
  });

  it("has an aria-label containing 'star' for the star card", () => {
    renderCard(STAR);

    const article = screen.getByRole("article");
    expect(article).toHaveAttribute(
      "aria-label",
      expect.stringContaining("star"),
    );
  });

  it("has an aria-label containing 'Patch instance'", () => {
    renderCard(DENSE_100);

    const article = screen.getByRole("article");
    expect(article).toHaveAttribute(
      "aria-label",
      expect.stringContaining("Patch instance"),
    );
  });
});

// ════════════════════════════════════════════════════════════════
//  Card Structure — DOM Hierarchy
// ════════════════════════════════════════════════════════════════

describe("card structure", () => {
  it("renders as an article element", () => {
    renderCard(DENSE_100);

    expect(screen.getByRole("article")).toBeInTheDocument();
  });

  it("renders the patch name in an h3 heading", () => {
    renderCard(DENSE_100);

    const heading = screen.getByRole("heading", { level: 3 });
    expect(heading).toBeInTheDocument();
    expect(heading).toHaveTextContent("dense-100");
  });

  it("contains a stats description list", () => {
    renderCard(DENSE_100);

    // The stats section has aria-label="Patch statistics"
    const statsDl = screen.getByLabelText("Patch statistics");
    expect(statsDl).toBeInTheDocument();
  });

  it("contains all three stat labels: Cells, Regions, Max S", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("Cells")).toBeInTheDocument();
    expect(screen.getByText("Regions")).toBeInTheDocument();
    expect(screen.getByText("Max S")).toBeInTheDocument();
  });

  it("renders the subtitle with tiling, dimension, and strategy", () => {
    renderCard(DENSE_100);

    // All three should appear in the subtitle area
    expect(screen.getByText("{4,3,5}")).toBeInTheDocument();
    expect(screen.getByText("3D")).toBeInTheDocument();
    expect(screen.getByText("Dense")).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  All Real Patches — Regression
// ════════════════════════════════════════════════════════════════

describe("regression — all 14 real patch summaries render without error", () => {
  /**
   * All 14 patches from the actual data, represented as PatchSummary
   * objects matching the GET /patches response shape.
   *
   * Fix (review issue #8): Dense-50 uses flat enumeration in the
   * Agda formalization (docs/engineering/scaling-report.md §2 shows
   * Orbits = "—" and Strategy = "PatchData"). Per backend/src/Types.hs,
   * patchOrbits = 0 indicates flat enumeration. Changed from the
   * incorrect psOrbits: 7 (the number of distinct min-cut values)
   * to psOrbits: 0 (matching the actual JSON export).
   */
  const ALL_PATCHES: PatchSummary[] = [
    {
      psName: "tree",
      psTiling: "Tree",
      psDimension: 1,
      psCells: 7,
      psRegions: 8,
      psOrbits: 0,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "star",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 6,
      psRegions: 10,
      psOrbits: 0,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "filled",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 11,
      psRegions: 90,
      psOrbits: 0,
      psMaxCut: 4,
      psStrategy: "BFS",
    },
    {
      psName: "desitter",
      psTiling: "Tiling53",
      psDimension: 2,
      psCells: 6,
      psRegions: 10,
      psOrbits: 0,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "honeycomb-3d",
      psTiling: "Tiling435",
      psDimension: 3,
      psCells: 32,
      psRegions: 34,
      psOrbits: 0,
      psMaxCut: 1,
      psStrategy: "BFS",
    },
    {
      psName: "dense-50",
      psTiling: "Tiling435",
      psDimension: 3,
      psCells: 50,
      psRegions: 139,
      psOrbits: 0,      // ← Fix: flat enumeration (no orbit reduction)
      psMaxCut: 7,
      psStrategy: "Dense",
    },
    {
      psName: "dense-100",
      psTiling: "Tiling435",
      psDimension: 3,
      psCells: 100,
      psRegions: 717,
      psOrbits: 8,
      psMaxCut: 8,
      psStrategy: "Dense",
    },
    {
      psName: "dense-200",
      psTiling: "Tiling435",
      psDimension: 3,
      psCells: 200,
      psRegions: 1246,
      psOrbits: 9,
      psMaxCut: 9,
      psStrategy: "Dense",
    },
    {
      psName: "layer-54-d2",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 21,
      psRegions: 15,
      psOrbits: 2,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "layer-54-d3",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 61,
      psRegions: 40,
      psOrbits: 2,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "layer-54-d4",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 166,
      psRegions: 105,
      psOrbits: 2,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "layer-54-d5",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 441,
      psRegions: 275,
      psOrbits: 2,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "layer-54-d6",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 1161,
      psRegions: 720,
      psOrbits: 2,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
    {
      psName: "layer-54-d7",
      psTiling: "Tiling54",
      psDimension: 2,
      psCells: 3046,
      psRegions: 1885,
      psOrbits: 2,
      psMaxCut: 2,
      psStrategy: "BFS",
    },
  ];

  it.each(ALL_PATCHES.map((p) => [p.psName, p] as const))(
    "renders '%s' without error",
    (_name, patch) => {
      const { container } = renderCard(patch);

      // Card rendered something non-empty
      expect(container.textContent).not.toBe("");

      // Patch name is present as a heading
      expect(
        screen.getByRole("heading", { level: 3 }),
      ).toHaveTextContent(patch.psName);

      // The "View Details" link exists and points to the correct path
      const link = screen.getByRole("link", {
        name: new RegExp(`view details for ${patch.psName}`, "i"),
      });
      expect(link).toHaveAttribute("href", `/patches/${patch.psName}`);
    },
  );
});

// ════════════════════════════════════════════════════════════════
//  Edge Cases
// ════════════════════════════════════════════════════════════════

describe("edge cases", () => {
  it("handles psOrbits=0 without showing orbit arrow", () => {
    renderCard(STAR);

    // The text content of the Regions value should be just "10"
    // without any "→" or "orbits" substring
    const regionsLabel = screen.getByText("Regions");
    const regionsRow = regionsLabel.closest("div");
    expect(regionsRow).not.toBeNull();
    expect(regionsRow!.textContent).toContain("10");
    expect(regionsRow!.textContent).not.toContain("→");
    expect(regionsRow!.textContent).not.toContain("orbit");
  });

  it("handles psOrbits > 0 with orbit arrow display", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("717 → 8 orbits")).toBeInTheDocument();
  });

  it("handles maxCut=1 without display issues", () => {
    renderCard(HONEYCOMB);

    const maxSLabel = screen.getByText("Max S");
    const maxSRow = maxSLabel.closest("div");
    expect(maxSRow).not.toBeNull();
    expect(maxSRow!.textContent).toContain("1");
  });

  /**
   * Dense-50 uses flat enumeration (psOrbits=0) despite having 7
   * distinct min-cut values. The card should display the region
   * count without an orbit arrow, matching the actual JSON export.
   *
   * Fix (review issue #8): Changed from psOrbits: 7 to psOrbits: 0.
   * Dense-50 uses flat enumeration in Agda (docs/engineering/
   * orbit-reduction.md §8: "Dense-50 uses flat enumeration (no
   * orbit reduction) because 139 regions are manageable without
   * it"). The patchOrbits field is 0 for flat enumeration per
   * backend/src/Types.hs semantics.
   */
  it("renders dense-50 with psOrbits=0 correctly (flat enumeration)", () => {
    const dense50: PatchSummary = {
      psName: "dense-50",
      psTiling: "Tiling435",
      psDimension: 3,
      psCells: 50,
      psRegions: 139,
      psOrbits: 0,
      psMaxCut: 7,
      psStrategy: "Dense",
    };
    renderCard(dense50);

    // With psOrbits=0, region display is just "139" (no orbit arrow)
    const regionsLabel = screen.getByText("Regions");
    const regionsRow = regionsLabel.closest("div");
    expect(regionsRow).not.toBeNull();
    expect(regionsRow!.textContent).toContain("139");
    expect(regionsRow!.textContent).not.toContain("→");
    expect(regionsRow!.textContent).not.toContain("orbit");

    expect(
      screen.getByRole("heading", { level: 3 }),
    ).toHaveTextContent("dense-50");
  });
});

// ════════════════════════════════════════════════════════════════
//  Subtitle Composition — All Three Pieces Together
// ════════════════════════════════════════════════════════════════

describe("subtitle composition", () => {
  it("dense-100 subtitle contains {4,3,5}, 3D, and Dense", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("{4,3,5}")).toBeInTheDocument();
    expect(screen.getByText("3D")).toBeInTheDocument();
    expect(screen.getByText("Dense")).toBeInTheDocument();
  });

  it("star subtitle contains {5,4}, 2D, and BFS", () => {
    renderCard(STAR);

    expect(screen.getByText("{5,4}")).toBeInTheDocument();
    expect(screen.getByText("2D")).toBeInTheDocument();
    expect(screen.getByText("BFS")).toBeInTheDocument();
  });

  it("tree subtitle contains Tree, 1D, and BFS", () => {
    renderCard(TREE);

    expect(screen.getByText("Tree")).toBeInTheDocument();
    expect(screen.getByText("1D")).toBeInTheDocument();
    expect(screen.getByText("BFS")).toBeInTheDocument();
  });

  it("desitter subtitle contains {5,3}, 2D, and BFS", () => {
    renderCard(DESITTER);

    expect(screen.getByText("{5,3}")).toBeInTheDocument();
    expect(screen.getByText("2D")).toBeInTheDocument();
    // BFS also appears — check it's in the document
    const bfsElements = screen.getAllByText("BFS");
    expect(bfsElements.length).toBeGreaterThanOrEqual(1);
  });
});

// ════════════════════════════════════════════════════════════════
//  View Details Arrow
// ════════════════════════════════════════════════════════════════

describe("view details navigation", () => {
  it("contains a → arrow character as decorative text", () => {
    renderCard(DENSE_100);

    // The arrow is rendered with aria-hidden="true" as a decorative element
    expect(screen.getByText("→")).toBeInTheDocument();
  });

  it("'View Details' text is present as link text", () => {
    renderCard(DENSE_100);

    expect(screen.getByText("View Details")).toBeInTheDocument();
  });
});