/**
 * Distribution charts for the Patch Viewer side panel.
 *
 * Renders two Recharts visualizations of the region data:
 *
 *   1. **Min-cut histogram** — one bar per distinct S value, height = region count.
 *      Bars are colored using the Viridis color scale (matching the 3D viewport).
 *
 *   2. **S/area ratio histogram** — region ratios binned into 10 equal-width buckets
 *      over [0, 0.5], with a vertical red reference line at 0.5 marking the
 *      discrete Bekenstein–Hawking bound S(A) ≤ area(A)/2.
 *
 * Both charts use Recharts' `ResponsiveContainer` for fluid width and respect
 * the academic design principle (muted colors, clean axes, no gratuitous animation).
 * Chart animations are disabled when `prefers-reduced-motion` is active
 * (frontend-spec §10).
 *
 * This is a stateless presentational component — it receives the full region
 * array and the patch's maxCut value via props and computes the histogram
 * buckets client-side.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3.5 (Distribution Charts)
 *   - docs/formal/12-bekenstein-hawking.md (the 0.5 bound)
 *   - src/utils/colors.ts (Viridis color scale)
 */

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  ReferenceLine,
  Cell,
} from "recharts";

import { colorFromMinCut } from "../../utils/colors";
import type { Region } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link DistributionChart} component. */
export interface DistributionChartProps {
  /** All regions in the patch. */
  regions: Region[];
  /** Maximum min-cut value across all regions (for the color scale domain). */
  maxCut: number;
}

// ════════════════════════════════════════════════════════════════
//  Data transformation helpers
// ════════════════════════════════════════════════════════════════

/** A single bar in the min-cut histogram. */
interface MinCutBucket {
  /** The min-cut value (S). */
  minCut: number;
  /** Number of regions with this min-cut value. */
  count: number;
}

/**
 * Group regions by min-cut value and count occurrences.
 *
 * Returns an array sorted by ascending min-cut value, one entry
 * per distinct S value present in the data. Empty min-cut values
 * (gaps in the range) are omitted — the chart shows only values
 * that actually appear.
 */
function computeMinCutHistogram(regions: Region[]): MinCutBucket[] {
  const counts = new Map<number, number>();

  for (const r of regions) {
    const prev = counts.get(r.regionMinCut) ?? 0;
    counts.set(r.regionMinCut, prev + 1);
  }

  const buckets: MinCutBucket[] = [];
  for (const [minCut, count] of counts.entries()) {
    buckets.push({ minCut, count });
  }

  buckets.sort((a, b) => a.minCut - b.minCut);
  return buckets;
}

/** A single bar in the S/area ratio histogram. */
interface RatioBucket {
  /** The bin label (e.g. "0.00–0.05"). */
  label: string;
  /** The bin midpoint (for tooltip display). */
  midpoint: number;
  /** Number of regions whose S/area ratio falls in this bin. */
  count: number;
}

/**
 * Bin region S/area ratios into equal-width buckets over [0, 0.5].
 *
 * Uses 10 bins of width 0.05 each: [0, 0.05), [0.05, 0.10), ...,
 * [0.45, 0.50]. Regions with ratio exactly 0.5 are placed in the
 * last bin. Regions with ratio > 0.5 (should not occur given the
 * half-bound, but defensive) are also placed in the last bin.
 *
 * Returns all 10 bins including those with count 0, so the chart
 * maintains a consistent x-axis even when some bins are empty.
 */
function computeRatioHistogram(regions: Region[]): RatioBucket[] {
  const NUM_BINS = 10;
  const BIN_WIDTH = 0.05;
  const counts = new Array<number>(NUM_BINS).fill(0);

  for (const r of regions) {
    // Clamp ratio to [0, 0.5] and compute bin index
    const ratio = Math.max(0, Math.min(r.regionRatio, 0.5));
    let binIdx = Math.floor(ratio / BIN_WIDTH);
    // Edge case: ratio exactly 0.5 → last bin
    if (binIdx >= NUM_BINS) {
      binIdx = NUM_BINS - 1;
    }
    // Safe increment: noUncheckedIndexedAccess means counts[binIdx]
    // is typed as `number | undefined` even though we know binIdx
    // is always in [0, NUM_BINS-1]. The nullish coalescing handles
    // the type-checker's concern without a non-null assertion.
    counts[binIdx] = (counts[binIdx] ?? 0) + 1;
  }

  const buckets: RatioBucket[] = [];
  for (let i = 0; i < NUM_BINS; i++) {
    const lo = (i * BIN_WIDTH).toFixed(2);
    const hi = ((i + 1) * BIN_WIDTH).toFixed(2);
    buckets.push({
      label: `${lo}–${hi}`,
      midpoint: (i + 0.5) * BIN_WIDTH,
      count: counts[i] ?? 0,
    });
  }

  return buckets;
}

// ════════════════════════════════════════════════════════════════
//  Reduced motion detection
// ════════════════════════════════════════════════════════════════

/**
 * Check if the user prefers reduced motion.
 *
 * When true, chart animations are disabled (frontend-spec §10).
 * Falls back to `false` in environments without `matchMedia`
 * (e.g. SSR, some test runners).
 */
function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) {
    return false;
  }
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

// ════════════════════════════════════════════════════════════════
//  Custom tooltip components
// ════════════════════════════════════════════════════════════════

/** Tooltip payload shape from Recharts. */
interface TooltipPayloadItem {
  value?: number;
  payload?: Record<string, unknown>;
}

interface CustomTooltipProps {
  active?: boolean;
  payload?: TooltipPayloadItem[];
  label?: string | number;
}

/**
 * Custom tooltip for the min-cut histogram.
 *
 * Shows "S = {value}: {count} regions".
 */
function MinCutTooltip({ active, payload }: CustomTooltipProps) {
  if (!active || !payload || payload.length === 0) return null;

  const item = payload[0];
  const minCut = item?.payload?.["minCut"] as number | undefined;
  const count = item?.value;

  if (minCut === undefined || count === undefined) return null;

  return (
    <div className="rounded border border-gray-200 bg-white px-3 py-2 text-xs shadow-sm">
      <p className="font-mono text-gray-700">
        S = {minCut}: <span className="font-semibold">{count}</span>{" "}
        region{count !== 1 ? "s" : ""}
      </p>
    </div>
  );
}

/**
 * Custom tooltip for the S/area ratio histogram.
 *
 * Shows the bin range and count.
 */
function RatioTooltip({ active, payload }: CustomTooltipProps) {
  if (!active || !payload || payload.length === 0) return null;

  const item = payload[0];
  const label = item?.payload?.["label"] as string | undefined;
  const count = item?.value;

  if (label === undefined || count === undefined) return null;

  return (
    <div className="rounded border border-gray-200 bg-white px-3 py-2 text-xs shadow-sm">
      <p className="font-mono text-gray-700">
        S/area ∈ [{label}]: <span className="font-semibold">{count}</span>{" "}
        region{count !== 1 ? "s" : ""}
      </p>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════
//  Main component
// ════════════════════════════════════════════════════════════════

/**
 * Distribution charts for the Patch Viewer side panel.
 *
 * Renders two stacked chart sections:
 *   1. Min-cut value histogram (Viridis-colored bars)
 *   2. S/area ratio histogram (muted blue bars with 0.5 reference line)
 *
 * When the region array is empty, renders a "No region data" message.
 *
 * @param regions - All regions in the patch (from patchRegionData).
 * @param maxCut  - The maximum min-cut value (from patchMaxCut).
 *
 * @example
 * ```tsx
 * <DistributionChart
 *   regions={patch.patchRegionData}
 *   maxCut={patch.patchMaxCut}
 * />
 * ```
 */
export function DistributionChart({ regions, maxCut }: DistributionChartProps) {
  if (regions.length === 0) {
    return (
      <section
        className="rounded-lg border border-gray-200 bg-white p-4"
        aria-label="Distribution charts"
      >
        <h3 className="font-serif text-base font-semibold text-gray-700 mb-2">
          Distribution
        </h3>
        <p className="text-sm text-gray-400 italic">
          No region data available.
        </p>
      </section>
    );
  }

  const minCutData = computeMinCutHistogram(regions);
  const ratioData = computeRatioHistogram(regions);
  const noAnimation = prefersReducedMotion();

  return (
    <section
      className="rounded-lg border border-gray-200 bg-white p-4 space-y-6"
      aria-label="Distribution charts"
    >
      {/* ── Min-cut histogram ─────────────────────────────────── */}
      <div>
        <h3 className="font-serif text-sm font-semibold text-gray-700 mb-1">
          Min-Cut Distribution
        </h3>
        <p className="text-xs text-gray-400 mb-3">
          Regions by min-cut value S
        </p>

        <div className="h-40 w-full" aria-label="Histogram of min-cut values">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={minCutData}
              margin={{ top: 4, right: 4, bottom: 4, left: -12 }}
            >
              <XAxis
                dataKey="minCut"
                tick={{ fontSize: 10, fill: "#9ca3af" }}
                axisLine={{ stroke: "#e5e7eb" }}
                tickLine={{ stroke: "#e5e7eb" }}
                label={{
                  value: "S",
                  position: "insideBottomRight",
                  offset: -2,
                  fontSize: 10,
                  fill: "#9ca3af",
                }}
              />
              <YAxis
                tick={{ fontSize: 10, fill: "#9ca3af" }}
                axisLine={{ stroke: "#e5e7eb" }}
                tickLine={{ stroke: "#e5e7eb" }}
                allowDecimals={false}
              />
              <Tooltip content={<MinCutTooltip />} />
              <Bar
                dataKey="count"
                radius={[2, 2, 0, 0]}
                isAnimationActive={!noAnimation}
                animationDuration={300}
              >
                {minCutData.map((entry) => (
                  <Cell
                    key={`mc-${entry.minCut}`}
                    fill={colorFromMinCut(entry.minCut, maxCut)}
                  />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* ── Divider ───────────────────────────────────────────── */}
      <hr className="border-gray-100" />

      {/* ── S/area ratio histogram ────────────────────────────── */}
      <div>
        <h3 className="font-serif text-sm font-semibold text-gray-700 mb-1">
          S / area Ratio
        </h3>
        <p className="text-xs text-gray-400 mb-3">
          Distribution with Bekenstein–Hawking bound at 0.5
        </p>

        <div className="h-40 w-full" aria-label="Histogram of S/area ratios with 0.5 bound">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={ratioData}
              margin={{ top: 4, right: 4, bottom: 4, left: -12 }}
            >
              <XAxis
                dataKey="label"
                tick={{ fontSize: 8, fill: "#9ca3af" }}
                axisLine={{ stroke: "#e5e7eb" }}
                tickLine={{ stroke: "#e5e7eb" }}
                interval={0}
                angle={-30}
                textAnchor="end"
                height={36}
              />
              <YAxis
                tick={{ fontSize: 10, fill: "#9ca3af" }}
                axisLine={{ stroke: "#e5e7eb" }}
                tickLine={{ stroke: "#e5e7eb" }}
                allowDecimals={false}
              />
              <Tooltip content={<RatioTooltip />} />
              {/* Reference line at x-position corresponding to the 0.5 bin.
                  Since the x-axis uses categorical labels, we place the line
                  at the label of the last bin (0.45–0.50) which represents
                  the BH bound region. */}
              <ReferenceLine
                x="0.45–0.50"
                stroke="#ef4444"
                strokeDasharray="4 3"
                strokeWidth={1.5}
                label={{
                  value: "½",
                  position: "top",
                  fontSize: 11,
                  fill: "#ef4444",
                  fontWeight: 600,
                }}
              />
              <Bar
                dataKey="count"
                fill="#31688e"
                radius={[2, 2, 0, 0]}
                isAnimationActive={!noAnimation}
                animationDuration={300}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* ── Legend ───────────────────────────────────────────── */}
        <div className="flex items-center justify-center gap-4 mt-2 text-[10px] text-gray-400">
          <span className="flex items-center gap-1">
            <span
              className="inline-block h-2 w-4 rounded-sm"
              style={{ backgroundColor: "#31688e" }}
              aria-hidden="true"
            />
            Region count
          </span>
          <span className="flex items-center gap-1">
            <span
              className="inline-block h-px w-4 border-t-2 border-dashed border-red-400"
              aria-hidden="true"
            />
            BH bound (S/area = ½)
          </span>
        </div>
      </div>
    </section>
  );
}