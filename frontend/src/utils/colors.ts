/**
 * Color scale utilities for the Patch Viewer's four visualization modes.
 *
 * All public functions return CSS hex color strings (`#rrggbb`), which
 * are accepted directly by Three.js `Color` constructors and by
 * Tailwind/CSS `style` properties.
 *
 * Four color modes are supported (matching the spec §5.3.3):
 *
 *  1. **Min-Cut value** (default): sequential Viridis (blue→yellow)
 *  2. **Region size**: sequential green→purple
 *  3. **S/area ratio**: diverging blue→white→red, anchored at 0.5
 *  4. **Curvature**: diverging blue→white→red (negative=blue, positive=red)
 *
 * The Viridis palette is the default because it is:
 *  - Perceptually uniform (equal data steps → equal visual steps)
 *  - Colorblind-safe (safe for deuteranopia and protanopia)
 *  - Print-friendly (readable in grayscale)
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4.4 (Color Scale)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.3 (Color Modes)
 *
 * @module
 */

import type { ColorMode } from "../types";

// ════════════════════════════════════════════════════════════════
//  Viridis Lookup Table
// ════════════════════════════════════════════════════════════════

/**
 * 16 evenly-spaced control points from the canonical matplotlib
 * Viridis colormap (Stéfan van der Walt & Nathaniel Smith, 2015).
 *
 * Each entry is [R, G, B] with values in [0, 255].
 * Indices map to t = i / 15 where t ∈ [0, 1].
 *
 * Linear interpolation between these 16 points produces ~255
 * visually distinct output colors — more than sufficient for
 * integer min-cut values in the range [1, 9].
 */
const VIRIDIS: readonly [number, number, number][] = [
  [68, 1, 84],       // t = 0.000 — deep purple
  [72, 24, 106],     // t = 0.067
  [71, 41, 120],     // t = 0.133
  [63, 71, 136],     // t = 0.200
  [53, 95, 141],     // t = 0.267
  [42, 113, 142],    // t = 0.333
  [33, 131, 141],    // t = 0.400
  [27, 148, 138],    // t = 0.467
  [34, 163, 130],    // t = 0.533
  [60, 177, 118],    // t = 0.600
  [96, 188, 101],    // t = 0.667
  [139, 197, 77],    // t = 0.733
  [181, 206, 46],    // t = 0.800
  [220, 211, 26],    // t = 0.867
  [252, 209, 27],    // t = 0.933
  [253, 231, 37],    // t = 1.000 — bright yellow
];

// ════════════════════════════════════════════════════════════════
//  Green → Purple Sequential Scale
// ════════════════════════════════════════════════════════════════

/**
 * Control points for the green→purple sequential scale used by
 * the "Region size" color mode.
 *
 * Start: Viridis-green (#35b779) for small regions.
 * Mid:   Transitional blue-purple for medium regions.
 * End:   Deep purple (#7e3fbb) for large (5-cell) regions.
 */
const GREEN_PURPLE: readonly [number, number, number][] = [
  [53, 183, 121],    // t = 0.0 — green (#35B779)
  [80, 145, 145],    // t = 0.25 — teal transition
  [108, 110, 160],   // t = 0.50 — blue-purple
  [126, 80, 160],    // t = 0.75 — medium purple
  [126, 63, 187],    // t = 1.0 — deep purple (#7E3FBB)
];

// ════════════════════════════════════════════════════════════════
//  Diverging Blue → White → Red Scale
// ════════════════════════════════════════════════════════════════

/**
 * Control points for the diverging blue→white→red scale used by
 * the "S/area ratio" and "Curvature" color modes.
 *
 * Based on ColorBrewer RdBu endpoints — a well-tested colorblind-
 * accessible diverging palette.
 *
 * t = 0.0 → deep blue (negative / low)
 * t = 0.5 → white (zero / neutral)
 * t = 1.0 → deep red (positive / high)
 */
const DIVERGING_BWR: readonly [number, number, number][] = [
  [33, 102, 172],    // t = 0.00 — deep blue (#2166AC)
  [103, 169, 207],   // t = 0.25 — light blue (#67A9CF)
  [255, 255, 255],   // t = 0.50 — white (#FFFFFF)
  [239, 138, 98],    // t = 0.75 — light red (#EF8A62)
  [178, 24, 43],     // t = 1.00 — deep red (#B2182B)
];

// ════════════════════════════════════════════════════════════════
//  Internal Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Clamp a value to the [0, 1] range, handling NaN by mapping to 0.
 */
function clamp01(value: number): number {
  if (Number.isNaN(value) || !Number.isFinite(value)) return 0;
  if (value <= 0) return 0;
  if (value >= 1) return 1;
  return value;
}

/**
 * Linear interpolation between two numbers.
 */
function lerp(a: number, b: number, t: number): number {
  return a + (b - a) * t;
}

/**
 * Convert an [R, G, B] tuple (values in [0, 255]) to a CSS hex
 * string `#rrggbb`.
 *
 * Values are clamped to [0, 255] and rounded to the nearest integer.
 */
function rgbToHex(r: number, g: number, b: number): string {
  const clamp = (v: number) => Math.max(0, Math.min(255, Math.round(v)));
  const rr = clamp(r).toString(16).padStart(2, "0");
  const gg = clamp(g).toString(16).padStart(2, "0");
  const bb = clamp(b).toString(16).padStart(2, "0");
  return `#${rr}${gg}${bb}`;
}

/**
 * Sample a color from a palette of evenly-spaced control points
 * using linear interpolation.
 *
 * @param palette - Array of [R, G, B] control points, evenly
 *   distributed over [0, 1]. Must have at least 2 entries.
 * @param t - Normalized parameter in [0, 1]. Clamped internally.
 * @returns CSS hex color string `#rrggbb`.
 */
function samplePalette(
  palette: readonly [number, number, number][],
  t: number,
): string {
  const tc = clamp01(t);

  const n = palette.length;
  if (n === 0) return "#000000";
  if (n === 1) return rgbToHex(palette[0]![0], palette[0]![1], palette[0]![2]);

  // Map t ∈ [0,1] to a floating-point index into the palette.
  const indexFloat = tc * (n - 1);
  const lo = Math.floor(indexFloat);
  const hi = Math.min(lo + 1, n - 1);
  const frac = indexFloat - lo;

  const cLo = palette[lo]!;
  const cHi = palette[hi]!;

  return rgbToHex(
    lerp(cLo[0], cHi[0], frac),
    lerp(cLo[1], cHi[1], frac),
    lerp(cLo[2], cHi[2], frac),
  );
}

/**
 * Normalize a value from the domain [lo, hi] to [0, 1].
 *
 * If lo === hi (degenerate range), returns `fallback` (default 0.5)
 * to place the single value at the midpoint of the scale.
 */
function normalize(
  value: number,
  lo: number,
  hi: number,
  fallback: number = 0.5,
): number {
  if (hi <= lo) return fallback;
  return clamp01((value - lo) / (hi - lo));
}

// ════════════════════════════════════════════════════════════════
//  Public API — Scale Samplers
// ════════════════════════════════════════════════════════════════

/**
 * Sample the Viridis colormap at a normalized parameter.
 *
 * @param t - Normalized parameter in [0, 1]. Clamped internally.
 *   0 = deep purple (low values), 1 = bright yellow (high values).
 * @returns CSS hex color string, e.g. `"#440154"`.
 */
export function viridis(t: number): string {
  return samplePalette(VIRIDIS, t);
}

/**
 * Sample the green→purple sequential scale at a normalized parameter.
 *
 * @param t - Normalized parameter in [0, 1]. Clamped internally.
 *   0 = green (small), 1 = purple (large).
 * @returns CSS hex color string.
 */
export function greenPurple(t: number): string {
  return samplePalette(GREEN_PURPLE, t);
}

/**
 * Sample the blue→white→red diverging scale at a normalized parameter.
 *
 * @param t - Normalized parameter in [0, 1]. Clamped internally.
 *   0 = blue (negative/low), 0.5 = white (zero/neutral),
 *   1 = red (positive/high).
 * @returns CSS hex color string.
 */
export function diverging(t: number): string {
  return samplePalette(DIVERGING_BWR, t);
}

// ════════════════════════════════════════════════════════════════
//  Public API — Per-Mode Color Functions
// ════════════════════════════════════════════════════════════════

/**
 * Map a min-cut value to a Viridis color.
 *
 * This is the primary color function for the default "Min-Cut"
 * visualization mode. Higher min-cut values (deeper holographic
 * surfaces) map to warmer (yellow) colors.
 *
 * @param minCut - The min-cut value S(A) for a region. Domain: [1, maxCut].
 * @param maxCut - The maximum min-cut value across the patch.
 * @returns CSS hex color string from the Viridis palette.
 *
 * @example
 * ```ts
 * colorFromMinCut(1, 8)  // → "#440154" (deep purple — lowest cut)
 * colorFromMinCut(8, 8)  // → "#fde725" (bright yellow — highest cut)
 * colorFromMinCut(4, 8)  // → Viridis midpoint (teal/green)
 * colorFromMinCut(1, 1)  // → Viridis midpoint (single-value patch)
 * ```
 */
export function colorFromMinCut(minCut: number, maxCut: number): string {
  // Domain [1, maxCut] → [0, 1]
  // When maxCut === 1, all regions have the same min-cut;
  // normalize returns 0.5, placing them at the Viridis midpoint.
  const t = normalize(minCut, 1, maxCut);
  return viridis(t);
}

/**
 * Map a region size (cell count) to a green→purple color.
 *
 * Used by the "Region size" visualization mode. Larger regions
 * (more cells) map to darker purple colors.
 *
 * @param size - Number of cells in the region. Domain: [1, maxSize].
 * @param maxSize - Maximum region size across the patch.
 * @returns CSS hex color string from the green→purple scale.
 */
export function colorFromRegionSize(size: number, maxSize: number): string {
  const t = normalize(size, 1, maxSize);
  return greenPurple(t);
}

/**
 * Map an S/area ratio to a blue→white→red diverging color,
 * anchored at 0.5 (the Bekenstein–Hawking bound).
 *
 * Used by the "S/area ratio" visualization mode. The scale is:
 *   - 0.0 → deep blue (low ratio, far from bound)
 *   - 0.5 → deep red (at the half-bound: 2·S = area)
 *   - Values above 0.5 are physically impossible (they would
 *     violate the half-bound), so the domain is [0, 0.5].
 *
 * Implementation: maps [0, 0.5] → [0, 1] on the diverging scale.
 * Ratios at exactly 0.5 appear deep red (tight achievers).
 * Ratios near 0 appear deep blue.
 *
 * @param ratio - The S/area ratio. Domain: [0, 0.5].
 * @returns CSS hex color string from the diverging scale.
 */
export function colorFromRatio(ratio: number): string {
  // Map [0, 0.5] → [0, 1] linearly.
  // Ratios at 0.5 (the bound) → t=1.0 → deep red.
  // Ratios at 0 → t=0.0 → deep blue.
  const t = normalize(ratio, 0, 0.5);
  return diverging(t);
}

/**
 * Map a curvature value to a blue→white→red diverging color.
 *
 * Used by the "Curvature" visualization mode. The scale is:
 *   - Negative curvature (hyperbolic) → blue
 *   - Zero curvature (flat) → white
 *   - Positive curvature (spherical) → red
 *
 * The domain is centered at zero and extends symmetrically to
 * ±max(|minKappa|, |maxKappa|), ensuring that zero always maps
 * to white regardless of the data range.
 *
 * @param kappa - The curvature value (integer numerator; divide by
 *   curvDenominator for the true rational).
 * @param minKappa - Minimum curvature value across the patch.
 * @param maxKappa - Maximum curvature value across the patch.
 * @returns CSS hex color string from the diverging scale.
 */
export function colorFromCurvature(
  kappa: number,
  minKappa: number,
  maxKappa: number,
): string {
  // Create a symmetric domain centered at zero.
  // This ensures that kappa=0 always maps to white (t=0.5).
  const absMax = Math.max(Math.abs(minKappa), Math.abs(maxKappa), 1);
  const t = normalize(kappa, -absMax, absMax);
  return diverging(t);
}

// ════════════════════════════════════════════════════════════════
//  Public API — Unified Dispatcher
// ════════════════════════════════════════════════════════════════

/**
 * Context required by the unified color dispatcher to map a region
 * to a color under any of the four visualization modes.
 */
export interface ColorContext {
  /** Maximum min-cut value across the patch (for "mincut" mode). */
  maxCut: number;
  /** Maximum region size in cells across the patch (for "regionSize" mode). */
  maxRegionSize: number;
  /** Minimum curvature value across the patch (for "curvature" mode). */
  minKappa: number;
  /** Maximum curvature value across the patch (for "curvature" mode). */
  maxKappa: number;
}

/**
 * Map a region to a color based on the currently selected
 * visualization mode.
 *
 * This is the main entry point used by cell mesh components to
 * determine their display color. It dispatches to the appropriate
 * per-mode function based on the `mode` parameter.
 *
 * @param mode - The active color mode.
 * @param minCut - Region's min-cut value S(A).
 * @param regionSize - Number of cells in the region.
 * @param ratio - Region's S/area ratio.
 * @param kappa - Region's curvature value (0 if curvature is unavailable).
 * @param ctx - Patch-level context providing domain bounds.
 * @returns CSS hex color string.
 */
export function colorForRegion(
  mode: ColorMode,
  minCut: number,
  regionSize: number,
  ratio: number,
  kappa: number,
  ctx: ColorContext,
): string {
  switch (mode) {
    case "mincut":
      return colorFromMinCut(minCut, ctx.maxCut);
    case "regionSize":
      return colorFromRegionSize(regionSize, ctx.maxRegionSize);
    case "ratio":
      return colorFromRatio(ratio);
    case "curvature":
      return colorFromCurvature(kappa, ctx.minKappa, ctx.maxKappa);
  }
}

// ════════════════════════════════════════════════════════════════
//  Public API — Validation Helpers
// ════════════════════════════════════════════════════════════════

/** Regular expression matching a valid CSS hex color `#rrggbb`. */
const HEX_RE = /^#[0-9a-f]{6}$/;

/**
 * Check whether a string is a valid 6-digit CSS hex color.
 *
 * Useful in tests to validate that color functions produce
 * well-formed output.
 *
 * @param color - The string to check.
 * @returns `true` if the string matches `#rrggbb` (lowercase).
 */
export function isValidHexColor(color: string): boolean {
  return HEX_RE.test(color);
}

// ════════════════════════════════════════════════════════════════
//  Public API — Three.js Numeric Color
// ════════════════════════════════════════════════════════════════

/**
 * Convert a CSS hex color string `#rrggbb` to a numeric value
 * suitable for Three.js `Color` constructor or `InstancedMesh`
 * color attributes.
 *
 * @param hex - A 6-digit hex color string, e.g. `"#440154"`.
 * @returns A 24-bit integer encoding the color (e.g. `0x440154`).
 *
 * @example
 * ```ts
 * hexToNumeric("#ff0000") // → 0xff0000 (= 16711680)
 * ```
 */
export function hexToNumeric(hex: string): number {
  // Strip the leading '#' and parse as hexadecimal.
  return parseInt(hex.slice(1), 16);
}