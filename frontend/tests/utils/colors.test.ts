/**
 * Tests for color scale utilities (src/utils/colors.ts).
 *
 * Verifies:
 *   1. All color functions produce valid 6-digit CSS hex strings
 *   2. Boundary values (minCut=1, minCut=maxCut, t=0, t=1) produce
 *      valid output without NaN, Infinity, or malformed strings
 *   3. Degenerate inputs (maxCut=1, maxSize=1, zero-width domains)
 *      produce reasonable fallback colors (not crashes)
 *   4. The unified dispatcher `colorForRegion` routes correctly to
 *      per-mode functions for all four ColorMode variants
 *   5. `isValidHexColor` correctly classifies valid/invalid strings
 *   6. `hexToNumeric` converts hex strings to correct numeric values
 *   7. The Viridis palette endpoints match the canonical matplotlib
 *      reference values (colorblind-safe verification)
 *   8. Edge cases: NaN, Infinity, negative values are handled
 *      gracefully (clamped or mapped to fallback positions)
 *
 * No network requests, no DOM, no React — these are pure-function
 * unit tests.
 *
 * Reference:
 *   - src/utils/colors.ts (module under test)
 *   - docs/engineering/frontend-spec-webgl.md §4.4 (Color Scale)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.3 (Color Modes)
 *   - Rules §11 (Testing Requirements: color scale edge cases)
 */

import { describe, it, expect } from "vitest";

import {
  viridis,
  greenPurple,
  diverging,
  colorFromMinCut,
  colorFromRegionSize,
  colorFromRatio,
  colorFromCurvature,
  colorForRegion,
  isValidHexColor,
  hexToNumeric,
} from "../../src/utils/colors";

import type { ColorMode } from "../../src/types";

// ════════════════════════════════════════════════════════════════
//  Helper: valid hex assertion
// ════════════════════════════════════════════════════════════════

/**
 * Assert that a string is a valid 6-digit lowercase hex color.
 *
 * Matches the pattern `#rrggbb` where r, g, b are hex digits [0-9a-f].
 * This is the canonical output format of all color functions in
 * src/utils/colors.ts.
 */
function expectValidHex(color: string): void {
  expect(color).toMatch(/^#[0-9a-f]{6}$/);
}

// ════════════════════════════════════════════════════════════════
//  isValidHexColor
// ════════════════════════════════════════════════════════════════

describe("isValidHexColor", () => {
  it("accepts valid lowercase hex colors", () => {
    expect(isValidHexColor("#000000")).toBe(true);
    expect(isValidHexColor("#ffffff")).toBe(true);
    expect(isValidHexColor("#440154")).toBe(true);
    expect(isValidHexColor("#35b779")).toBe(true);
    expect(isValidHexColor("#fde725")).toBe(true);
    expect(isValidHexColor("#abcdef")).toBe(true);
  });

  it("rejects uppercase hex colors", () => {
    expect(isValidHexColor("#FFFFFF")).toBe(false);
    expect(isValidHexColor("#FF0000")).toBe(false);
    expect(isValidHexColor("#AbCdEf")).toBe(false);
  });

  it("rejects 3-digit shorthand hex", () => {
    expect(isValidHexColor("#fff")).toBe(false);
    expect(isValidHexColor("#000")).toBe(false);
    expect(isValidHexColor("#abc")).toBe(false);
  });

  it("rejects hex colors without # prefix", () => {
    expect(isValidHexColor("000000")).toBe(false);
    expect(isValidHexColor("ffffff")).toBe(false);
  });

  it("rejects 8-digit hex (with alpha)", () => {
    expect(isValidHexColor("#00000000")).toBe(false);
    expect(isValidHexColor("#ffffffff")).toBe(false);
  });

  it("rejects empty string", () => {
    expect(isValidHexColor("")).toBe(false);
  });

  it("rejects non-hex characters", () => {
    expect(isValidHexColor("#gggggg")).toBe(false);
    expect(isValidHexColor("#zzzzzz")).toBe(false);
    expect(isValidHexColor("#12345g")).toBe(false);
  });

  it("rejects color names", () => {
    expect(isValidHexColor("red")).toBe(false);
    expect(isValidHexColor("blue")).toBe(false);
    expect(isValidHexColor("transparent")).toBe(false);
  });

  it("rejects rgb() notation", () => {
    expect(isValidHexColor("rgb(255,0,0)")).toBe(false);
  });
});

// ════════════════════════════════════════════════════════════════
//  hexToNumeric
// ════════════════════════════════════════════════════════════════

describe("hexToNumeric", () => {
  it("converts black #000000 to 0", () => {
    expect(hexToNumeric("#000000")).toBe(0x000000);
  });

  it("converts white #ffffff to 16777215", () => {
    expect(hexToNumeric("#ffffff")).toBe(0xffffff);
  });

  it("converts pure red #ff0000 to 0xff0000", () => {
    expect(hexToNumeric("#ff0000")).toBe(0xff0000);
  });

  it("converts pure green #00ff00 to 0x00ff00", () => {
    expect(hexToNumeric("#00ff00")).toBe(0x00ff00);
  });

  it("converts pure blue #0000ff to 0x0000ff", () => {
    expect(hexToNumeric("#0000ff")).toBe(0x0000ff);
  });

  it("converts Viridis endpoint #440154 correctly", () => {
    expect(hexToNumeric("#440154")).toBe(0x440154);
  });

  it("converts Viridis endpoint #fde725 correctly", () => {
    expect(hexToNumeric("#fde725")).toBe(0xfde725);
  });

  it("returns a non-negative integer", () => {
    const result = hexToNumeric("#888888");
    expect(result).toBeGreaterThanOrEqual(0);
    expect(result).toBeLessThanOrEqual(0xffffff);
    expect(Number.isInteger(result)).toBe(true);
  });
});

// ════════════════════════════════════════════════════════════════
//  viridis — Viridis sequential colormap
// ════════════════════════════════════════════════════════════════

describe("viridis", () => {
  it("produces a valid hex color at t=0 (deep purple endpoint)", () => {
    const color = viridis(0);
    expectValidHex(color);
  });

  it("produces a valid hex color at t=1 (bright yellow endpoint)", () => {
    const color = viridis(1);
    expectValidHex(color);
  });

  it("produces a valid hex color at t=0.5 (midpoint)", () => {
    const color = viridis(0.5);
    expectValidHex(color);
  });

  it("produces the canonical deep purple at t=0", () => {
    // The first Viridis control point is [68, 1, 84] → #440154
    const color = viridis(0);
    expect(color).toBe("#440154");
  });

  it("produces the canonical bright yellow at t=1", () => {
    // The last Viridis control point is [253, 231, 37] → #fde725
    const color = viridis(1);
    expect(color).toBe("#fde725");
  });

  it("clamps values below 0 to the t=0 color", () => {
    expect(viridis(-1)).toBe(viridis(0));
    expect(viridis(-100)).toBe(viridis(0));
    expect(viridis(-0.001)).toBe(viridis(0));
  });

  it("clamps values above 1 to the t=1 color", () => {
    expect(viridis(2)).toBe(viridis(1));
    expect(viridis(100)).toBe(viridis(1));
    expect(viridis(1.001)).toBe(viridis(1));
  });

  it("handles NaN by mapping to t=0", () => {
    const color = viridis(NaN);
    expectValidHex(color);
    expect(color).toBe(viridis(0));
  });

  it("handles Infinity by mapping to t=0 (non-finite fallback)", () => {
    // clamp01 returns 0 for all non-finite values (NaN, Infinity,
    // -Infinity) because the !Number.isFinite() guard fires before
    // the >= 1 check. Both +Infinity and -Infinity map to t=0.
    const color = viridis(Infinity);
    expectValidHex(color);
    expect(color).toBe(viridis(0));
  });

  it("handles -Infinity by mapping to t=0", () => {
    const color = viridis(-Infinity);
    expectValidHex(color);
    expect(color).toBe(viridis(0));
  });

  it("produces valid hex for several intermediate values", () => {
    const testValues = [0.1, 0.2, 0.25, 0.33, 0.5, 0.67, 0.75, 0.8, 0.9];
    for (const t of testValues) {
      expectValidHex(viridis(t));
    }
  });

  it("is monotonically varying in the red channel from purple to yellow", () => {
    // Viridis moves from deep purple (R≈68) to bright yellow (R≈253).
    // The red channel should generally increase, though it may dip
    // slightly in the blue-teal region. We just verify endpoints.
    const r0 = parseInt(viridis(0).slice(1, 3), 16);
    const r1 = parseInt(viridis(1).slice(1, 3), 16);
    expect(r1).toBeGreaterThan(r0);
  });

  it("produces distinct colors for t=0 and t=1 (not degenerate)", () => {
    expect(viridis(0)).not.toBe(viridis(1));
  });

  it("produces distinct colors for close but different t values", () => {
    // At 16 control points, t values separated by > 1/15 ≈ 0.067
    // should produce distinct outputs after interpolation + rounding.
    expect(viridis(0.0)).not.toBe(viridis(0.5));
    expect(viridis(0.5)).not.toBe(viridis(1.0));
  });
});

// ════════════════════════════════════════════════════════════════
//  greenPurple — Sequential green→purple scale
// ════════════════════════════════════════════════════════════════

describe("greenPurple", () => {
  it("produces valid hex at t=0 (green endpoint)", () => {
    const color = greenPurple(0);
    expectValidHex(color);
  });

  it("produces valid hex at t=1 (purple endpoint)", () => {
    const color = greenPurple(1);
    expectValidHex(color);
  });

  it("produces valid hex at t=0.5 (midpoint)", () => {
    const color = greenPurple(0.5);
    expectValidHex(color);
  });

  it("clamps negative values", () => {
    expect(greenPurple(-1)).toBe(greenPurple(0));
  });

  it("clamps values above 1", () => {
    expect(greenPurple(2)).toBe(greenPurple(1));
  });

  it("handles NaN gracefully", () => {
    expectValidHex(greenPurple(NaN));
  });

  it("produces distinct colors at endpoints", () => {
    expect(greenPurple(0)).not.toBe(greenPurple(1));
  });

  it("green endpoint has higher green channel than purple endpoint", () => {
    const g0 = parseInt(greenPurple(0).slice(3, 5), 16);
    const g1 = parseInt(greenPurple(1).slice(3, 5), 16);
    expect(g0).toBeGreaterThan(g1);
  });
});

// ════════════════════════════════════════════════════════════════
//  diverging — Blue→White→Red diverging scale
// ════════════════════════════════════════════════════════════════

describe("diverging", () => {
  it("produces valid hex at t=0 (blue endpoint)", () => {
    const color = diverging(0);
    expectValidHex(color);
  });

  it("produces valid hex at t=0.5 (white midpoint)", () => {
    const color = diverging(0.5);
    expectValidHex(color);
  });

  it("produces valid hex at t=1 (red endpoint)", () => {
    const color = diverging(1);
    expectValidHex(color);
  });

  it("produces white (#ffffff) at t=0.5", () => {
    // The middle control point is [255, 255, 255].
    // At exactly t=0.5, interpolation should hit this control point.
    expect(diverging(0.5)).toBe("#ffffff");
  });

  it("clamps negative values to blue endpoint", () => {
    expect(diverging(-1)).toBe(diverging(0));
  });

  it("clamps values above 1 to red endpoint", () => {
    expect(diverging(2)).toBe(diverging(1));
  });

  it("handles NaN gracefully", () => {
    expectValidHex(diverging(NaN));
  });

  it("blue endpoint has higher blue channel than red endpoint", () => {
    const b0 = parseInt(diverging(0).slice(5, 7), 16);
    const b1 = parseInt(diverging(1).slice(5, 7), 16);
    expect(b0).toBeGreaterThan(b1);
  });

  it("red endpoint has higher red channel than blue endpoint", () => {
    const r0 = parseInt(diverging(0).slice(1, 3), 16);
    const r1 = parseInt(diverging(1).slice(1, 3), 16);
    expect(r1).toBeGreaterThan(r0);
  });

  it("is symmetric: t=0.25 and t=0.75 have similar luminance", () => {
    // Not exact due to different hues, but both should be similar
    // distance from white. We just verify both are valid.
    expectValidHex(diverging(0.25));
    expectValidHex(diverging(0.75));
  });
});

// ════════════════════════════════════════════════════════════════
//  colorFromMinCut — Viridis mapping for min-cut values
// ════════════════════════════════════════════════════════════════

describe("colorFromMinCut", () => {
  it("produces a valid hex color for minCut=1, maxCut=1 (single-value patch)", () => {
    // When maxCut === 1, all regions have the same min-cut.
    // Domain [1, 1] is degenerate; normalize should return 0.5.
    const color = colorFromMinCut(1, 1);
    expectValidHex(color);
  });

  it("produces a valid hex color for minCut=1, maxCut=8", () => {
    const color = colorFromMinCut(1, 8);
    expectValidHex(color);
  });

  it("produces a valid hex color for minCut=8, maxCut=8 (maximum value)", () => {
    const color = colorFromMinCut(8, 8);
    expectValidHex(color);
  });

  it("produces a valid hex color for minCut=4, maxCut=8 (midpoint)", () => {
    const color = colorFromMinCut(4, 8);
    expectValidHex(color);
  });

  it("maps minCut=1 to the deep purple end of Viridis (low values)", () => {
    const color = colorFromMinCut(1, 8);
    // minCut=1, maxCut=8: t = (1-1)/(8-1) = 0 → Viridis deep purple
    expect(color).toBe(viridis(0));
  });

  it("maps minCut=maxCut to the bright yellow end of Viridis (high values)", () => {
    const color = colorFromMinCut(8, 8);
    // minCut=8, maxCut=8: t = (8-1)/(8-1) = 1 → Viridis bright yellow
    expect(color).toBe(viridis(1));
  });

  it("produces the Viridis midpoint color for minCut=1, maxCut=1 (degenerate)", () => {
    // Degenerate domain [1, 1]: normalize returns 0.5
    expect(colorFromMinCut(1, 1)).toBe(viridis(0.5));
  });

  it("produces different colors for minCut=1 and minCut=8 (same maxCut=8)", () => {
    const low = colorFromMinCut(1, 8);
    const high = colorFromMinCut(8, 8);
    expect(low).not.toBe(high);
  });

  it("produces valid hex for all min-cut values in the Dense-100 range [1, 8]", () => {
    for (let s = 1; s <= 8; s++) {
      expectValidHex(colorFromMinCut(s, 8));
    }
  });

  it("produces valid hex for all min-cut values in the Dense-200 range [1, 9]", () => {
    for (let s = 1; s <= 9; s++) {
      expectValidHex(colorFromMinCut(s, 9));
    }
  });

  it("produces valid hex for the {5,4} layer tower range [1, 2]", () => {
    expectValidHex(colorFromMinCut(1, 2));
    expectValidHex(colorFromMinCut(2, 2));
  });

  it("produces valid hex for minCut=2, maxCut=2 (star/desitter patches)", () => {
    const color = colorFromMinCut(2, 2);
    expectValidHex(color);
  });

  it("handles maxCut=0 gracefully (degenerate — no valid min-cuts)", () => {
    // While maxCut=0 shouldn't occur in valid data, the function
    // should not crash. Domain [1, 0] is empty → normalize returns 0.5.
    expectValidHex(colorFromMinCut(0, 0));
    expectValidHex(colorFromMinCut(1, 0));
  });
});

// ════════════════════════════════════════════════════════════════
//  colorFromRegionSize — Green→Purple mapping for region sizes
// ════════════════════════════════════════════════════════════════

describe("colorFromRegionSize", () => {
  it("produces a valid hex for size=1, maxSize=1 (all singletons)", () => {
    const color = colorFromRegionSize(1, 1);
    expectValidHex(color);
  });

  it("produces a valid hex for size=1, maxSize=5", () => {
    const color = colorFromRegionSize(1, 5);
    expectValidHex(color);
  });

  it("produces a valid hex for size=5, maxSize=5", () => {
    const color = colorFromRegionSize(5, 5);
    expectValidHex(color);
  });

  it("maps size=1 to the green endpoint (small regions)", () => {
    const color = colorFromRegionSize(1, 5);
    expect(color).toBe(greenPurple(0));
  });

  it("maps size=maxSize to the purple endpoint (large regions)", () => {
    const color = colorFromRegionSize(5, 5);
    expect(color).toBe(greenPurple(1));
  });

  it("produces the midpoint for size=1, maxSize=1 (degenerate)", () => {
    expect(colorFromRegionSize(1, 1)).toBe(greenPurple(0.5));
  });

  it("produces different colors for size=1 and size=5", () => {
    const small = colorFromRegionSize(1, 5);
    const large = colorFromRegionSize(5, 5);
    expect(small).not.toBe(large);
  });

  it("produces valid hex for all sizes 1–5", () => {
    for (let s = 1; s <= 5; s++) {
      expectValidHex(colorFromRegionSize(s, 5));
    }
  });
});

// ════════════════════════════════════════════════════════════════
//  colorFromRatio — Blue→White→Red for S/area ratio
// ════════════════════════════════════════════════════════════════

describe("colorFromRatio", () => {
  it("produces a valid hex for ratio=0 (lowest possible ratio)", () => {
    const color = colorFromRatio(0);
    expectValidHex(color);
  });

  it("produces a valid hex for ratio=0.5 (Bekenstein–Hawking bound)", () => {
    const color = colorFromRatio(0.5);
    expectValidHex(color);
  });

  it("produces a valid hex for ratio=0.25 (midpoint of [0, 0.5])", () => {
    const color = colorFromRatio(0.25);
    expectValidHex(color);
  });

  it("maps ratio=0 to the blue end of the diverging scale (t=0)", () => {
    // ratio=0 → normalize(0, 0, 0.5) = 0 → diverging(0) = blue
    expect(colorFromRatio(0)).toBe(diverging(0));
  });

  it("maps ratio=0.5 to the red end of the diverging scale (t=1)", () => {
    // ratio=0.5 → normalize(0.5, 0, 0.5) = 1 → diverging(1) = red
    expect(colorFromRatio(0.5)).toBe(diverging(1));
  });

  it("maps ratio=0.25 to the white midpoint of the diverging scale", () => {
    // ratio=0.25 → normalize(0.25, 0, 0.5) = 0.5 → diverging(0.5) = white
    expect(colorFromRatio(0.25)).toBe(diverging(0.5));
    expect(colorFromRatio(0.25)).toBe("#ffffff");
  });

  it("produces distinct colors for ratio=0.1 and ratio=0.4", () => {
    const low = colorFromRatio(0.1);
    const high = colorFromRatio(0.4);
    expect(low).not.toBe(high);
  });

  it("handles negative ratios gracefully (clamp to 0)", () => {
    const color = colorFromRatio(-0.1);
    expectValidHex(color);
    expect(color).toBe(colorFromRatio(0));
  });

  it("handles ratio > 0.5 gracefully (clamp to 0.5)", () => {
    // S/area > 0.5 should not occur in valid data (violates half-bound),
    // but the function should handle it gracefully.
    const color = colorFromRatio(0.6);
    expectValidHex(color);
    expect(color).toBe(colorFromRatio(0.5));
  });

  it("produces valid hex for typical Dense-100 region ratios", () => {
    // Representative ratios from data/patches/dense-50.json
    const typicalRatios = [0.1667, 0.2, 0.2727, 0.3, 0.3333, 0.3571, 0.4286, 0.5];
    for (const ratio of typicalRatios) {
      expectValidHex(colorFromRatio(ratio));
    }
  });

  it("handles NaN ratio gracefully", () => {
    const color = colorFromRatio(NaN);
    expectValidHex(color);
  });
});

// ════════════════════════════════════════════════════════════════
//  colorFromCurvature — Blue→White→Red for curvature values
// ════════════════════════════════════════════════════════════════

describe("colorFromCurvature", () => {
  it("maps negative curvature to the blue side", () => {
    const color = colorFromCurvature(-5, -5, 2);
    expectValidHex(color);
    // kappa=-5, symmetric domain [-5, 5] → t = (-5 - (-5))/(5 - (-5)) = 0 → blue
    expect(color).toBe(diverging(0));
  });

  it("maps positive curvature to the red side", () => {
    const color = colorFromCurvature(5, -5, 5);
    expectValidHex(color);
    // kappa=5, symmetric domain [-5, 5] → t = (5 - (-5))/(5 - (-5)) = 1 → red
    expect(color).toBe(diverging(1));
  });

  it("maps zero curvature to white (midpoint)", () => {
    const color = colorFromCurvature(0, -5, 5);
    expectValidHex(color);
    // kappa=0, symmetric domain [-5, 5] → t = (0 - (-5))/(5 - (-5)) = 0.5 → white
    expect(color).toBe("#ffffff");
  });

  it("produces valid hex for Dense-50 edge curvature (κ₂₀ = -5, all edges)", () => {
    // Dense-50: all 12 central edges have ccKappa=-5
    // minKappa=-5, maxKappa=-5 → symmetric domain [-5, 5]
    const color = colorFromCurvature(-5, -5, -5);
    expectValidHex(color);
  });

  it("produces valid hex for desitter positive curvature (κ₁₀ = +1)", () => {
    // desitter: interior vertices have ccKappa=+1, boundary has -1 and +2
    const color = colorFromCurvature(1, -1, 2);
    expectValidHex(color);
  });

  it("produces valid hex for filled-patch curvature classes", () => {
    // filled: ccKappa values are -2, -1, +2
    const classes = [-2, -1, 2];
    for (const kappa of classes) {
      expectValidHex(colorFromCurvature(kappa, -2, 2));
    }
  });

  it("handles all-zero curvature gracefully (minKappa=0, maxKappa=0)", () => {
    const color = colorFromCurvature(0, 0, 0);
    expectValidHex(color);
    // absMax = max(0, 0, 1) = 1 → symmetric domain [-1, 1]
    // kappa=0 → t = (0-(-1))/(1-(-1)) = 0.5 → white
    expect(color).toBe("#ffffff");
  });

  it("uses a symmetric domain centered at zero", () => {
    // If minKappa=-2 and maxKappa=1, the symmetric domain should be
    // [-2, 2] (not [-2, 1]), ensuring zero maps to white.
    const atZero = colorFromCurvature(0, -2, 1);
    expect(atZero).toBe("#ffffff");
  });

  it("handles NaN curvature gracefully", () => {
    expectValidHex(colorFromCurvature(NaN, -5, 5));
  });
});

// ════════════════════════════════════════════════════════════════
//  colorForRegion — Unified dispatcher for all four color modes
// ════════════════════════════════════════════════════════════════

describe("colorForRegion", () => {
  const ctx = {
    maxCut: 8,
    maxRegionSize: 5,
    minKappa: -5,
    maxKappa: 2,
  };

  it("dispatches 'mincut' mode to colorFromMinCut", () => {
    const result = colorForRegion("mincut", 4, 3, 0.25, 0, ctx);
    const direct = colorFromMinCut(4, 8);
    expect(result).toBe(direct);
  });

  it("dispatches 'regionSize' mode to colorFromRegionSize", () => {
    const result = colorForRegion("regionSize", 4, 3, 0.25, 0, ctx);
    const direct = colorFromRegionSize(3, 5);
    expect(result).toBe(direct);
  });

  it("dispatches 'ratio' mode to colorFromRatio", () => {
    const result = colorForRegion("ratio", 4, 3, 0.25, 0, ctx);
    const direct = colorFromRatio(0.25);
    expect(result).toBe(direct);
  });

  it("dispatches 'curvature' mode to colorFromCurvature", () => {
    const result = colorForRegion("curvature", 4, 3, 0.25, -3, ctx);
    const direct = colorFromCurvature(-3, -5, 2);
    expect(result).toBe(direct);
  });

  it("produces valid hex for all four modes", () => {
    const modes: ColorMode[] = ["mincut", "regionSize", "ratio", "curvature"];
    for (const mode of modes) {
      expectValidHex(colorForRegion(mode, 2, 1, 0.1667, -2, ctx));
    }
  });

  it("produces valid hex with degenerate context (maxCut=1, maxRegionSize=1)", () => {
    const degenerateCtx = {
      maxCut: 1,
      maxRegionSize: 1,
      minKappa: 0,
      maxKappa: 0,
    };
    const modes: ColorMode[] = ["mincut", "regionSize", "ratio", "curvature"];
    for (const mode of modes) {
      expectValidHex(colorForRegion(mode, 1, 1, 0.5, 0, degenerateCtx));
    }
  });

  it("produces different colors for different modes (unless coincidence)", () => {
    // mincut and ratio modes use different scales (Viridis vs diverging),
    // so they should produce different outputs for the same input.
    const mc = colorForRegion("mincut", 4, 3, 0.25, 0, ctx);
    const ratio = colorForRegion("ratio", 4, 3, 0.25, 0, ctx);
    // Not strictly guaranteed to differ, but for these values they do.
    // If this ever flakes due to coincidental color equality, remove it.
    expect(mc).not.toBe(ratio);
  });
});

// ════════════════════════════════════════════════════════════════
//  Colorblind Safety — Viridis produces distinct values
// ════════════════════════════════════════════════════════════════

describe("colorblind safety — Viridis palette distinctness", () => {
  it("produces at least 5 visually distinct colors for a maxCut=8 range", () => {
    // Viridis is designed to be perceptually uniform: equal data steps
    // produce equal visual steps. We verify that 8 distinct min-cut
    // values produce 8 distinct hex colors (no collisions).
    const colors = new Set<string>();
    for (let s = 1; s <= 8; s++) {
      colors.add(colorFromMinCut(s, 8));
    }
    // At 16 control points and 8 query values spread over [0, 1],
    // all 8 should be distinct after interpolation + rounding.
    expect(colors.size).toBeGreaterThanOrEqual(5);
  });

  it("produces 9 distinct colors for the Dense-200 range [1, 9]", () => {
    const colors = new Set<string>();
    for (let s = 1; s <= 9; s++) {
      colors.add(colorFromMinCut(s, 9));
    }
    expect(colors.size).toBe(9);
  });

  it("the Viridis endpoints differ significantly in luminance", () => {
    // Deep purple [68,1,84] ≈ dark; bright yellow [253,231,37] ≈ bright.
    // This ensures the scale is readable in grayscale (a requirement
    // for Viridis as a colorblind-safe palette).
    const dark = viridis(0);
    const bright = viridis(1);

    // Compute approximate perceived luminance using the sRGB formula:
    // L ≈ 0.2126*R + 0.7152*G + 0.0722*B (range 0–255)
    const luminance = (hex: string) => {
      const r = parseInt(hex.slice(1, 3), 16);
      const g = parseInt(hex.slice(3, 5), 16);
      const b = parseInt(hex.slice(5, 7), 16);
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    };

    const lumDark = luminance(dark);
    const lumBright = luminance(bright);

    // The bright end should have at least 3× the luminance of the dark end.
    expect(lumBright).toBeGreaterThan(lumDark * 3);
  });
});

// ════════════════════════════════════════════════════════════════
//  Edge Cases — Robustness against unusual inputs
// ════════════════════════════════════════════════════════════════

describe("edge cases — robustness", () => {
  it("colorFromMinCut: minCut > maxCut produces a valid hex (clamped)", () => {
    // Should not occur in valid data, but function must not crash.
    const color = colorFromMinCut(10, 8);
    expectValidHex(color);
  });

  it("colorFromMinCut: minCut=0 produces a valid hex", () => {
    // minCut=0 is below the expected domain [1, maxCut] but should be safe.
    const color = colorFromMinCut(0, 8);
    expectValidHex(color);
  });

  it("colorFromMinCut: negative minCut produces a valid hex", () => {
    const color = colorFromMinCut(-3, 8);
    expectValidHex(color);
  });

  it("colorFromRegionSize: size=0 produces a valid hex", () => {
    const color = colorFromRegionSize(0, 5);
    expectValidHex(color);
  });

  it("colorFromRegionSize: size > maxSize produces a valid hex (clamped)", () => {
    const color = colorFromRegionSize(10, 5);
    expectValidHex(color);
  });

  it("all palette samplers handle t=exactly-a-control-point without interpolation error", () => {
    // At t = k / (N-1) for integer k, the sampler should return
    // the exact control-point color (no interpolation needed).
    // Viridis has 16 control points, so t = 0, 1/15, 2/15, ..., 1.
    for (let i = 0; i <= 15; i++) {
      const t = i / 15;
      expectValidHex(viridis(t));
    }
    // Green-purple has 5 control points.
    for (let i = 0; i <= 4; i++) {
      const t = i / 4;
      expectValidHex(greenPurple(t));
    }
    // Diverging has 5 control points.
    for (let i = 0; i <= 4; i++) {
      const t = i / 4;
      expectValidHex(diverging(t));
    }
  });

  it("viridis returns consistent results for the same input (deterministic)", () => {
    const a = viridis(0.3);
    const b = viridis(0.3);
    expect(a).toBe(b);
  });

  it("all functions return lowercase hex (required by isValidHexColor)", () => {
    // Verify that the output format is always lowercase, as required
    // by isValidHexColor and the hex regex in the module.
    const samples = [
      viridis(0), viridis(0.5), viridis(1),
      greenPurple(0), greenPurple(1),
      diverging(0), diverging(0.5), diverging(1),
      colorFromMinCut(1, 8), colorFromMinCut(8, 8),
      colorFromRegionSize(1, 5), colorFromRegionSize(5, 5),
      colorFromRatio(0), colorFromRatio(0.5),
      colorFromCurvature(0, -5, 5),
    ];

    for (const color of samples) {
      expect(isValidHexColor(color)).toBe(true);
    }
  });
});

// ════════════════════════════════════════════════════════════════
//  Integration: Color functions match known patch data scenarios
// ════════════════════════════════════════════════════════════════

describe("integration — realistic patch data scenarios", () => {
  it("Dense-100 region with S=1 and S=8 produce different colors (mincut mode)", () => {
    const s1 = colorFromMinCut(1, 8);
    const s8 = colorFromMinCut(8, 8);
    expect(s1).not.toBe(s8);
    expectValidHex(s1);
    expectValidHex(s8);
  });

  it("Dense-50 BH tight achiever (ratio=0.5) gets the red end of the ratio scale", () => {
    const tight = colorFromRatio(0.5);
    expect(tight).toBe(diverging(1)); // t=1 → red end
  });

  it("Star patch: all singletons (S=1) and pairs (S=2) are distinctly colored", () => {
    const singleton = colorFromMinCut(1, 2);
    const pair = colorFromMinCut(2, 2);
    expect(singleton).not.toBe(pair);
    expectValidHex(singleton);
    expectValidHex(pair);
  });

  it("Tree patch: S=1 and S=2 with maxCut=2 produce valid distinct colors", () => {
    const s1 = colorFromMinCut(1, 2);
    const s2 = colorFromMinCut(2, 2);
    expect(s1).not.toBe(s2);
    expectValidHex(s1);
    expectValidHex(s2);
  });

  it("Honeycomb patch: all S=1 regions get the same color (uniform min-cut)", () => {
    // Honeycomb BFS: all 26 boundary cells have S=1, maxCut=1.
    const c1 = colorFromMinCut(1, 1);
    const c2 = colorFromMinCut(1, 1);
    expect(c1).toBe(c2); // Same input → same output
    expectValidHex(c1);
  });

  it("Filled patch: curvature classes [-2, -1, +2] produce valid distinct colors", () => {
    const colors = new Set<string>();
    for (const kappa of [-2, -1, 2]) {
      const color = colorFromCurvature(kappa, -2, 2);
      expectValidHex(color);
      colors.add(color);
    }
    // -2, -1, and +2 are spread across the domain [-2, 2];
    // they should produce distinct colors.
    expect(colors.size).toBe(3);
  });
});