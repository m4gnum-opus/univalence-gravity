/**
 * Side-panel component displaying curvature class data and the
 * Gauss–Bonnet verification badge for a holographic patch.
 *
 * Renders a table of curvature classes (vertex classes for 2D,
 * edge classes for 3D) with their counts, valences, and κ values,
 * followed by the total curvature sum, Euler characteristic, and
 * a Gauss–Bonnet verification badge.
 *
 * All curvature values are integer numerators. The `curvDenominator`
 * field (10 for 2D vertex curvature, 20 for 3D edge curvature)
 * disambiguates the rational unit. For example, `ccKappa = -5` with
 * `curvDenominator = 20` means κ = −5/20 = −0.25.
 *
 * When `data` is `null` (patches without curvature, e.g. tree,
 * star, layer-54), renders a muted "No curvature data" message.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3 (Patch Viewer)
 *   - docs/formal/04-discrete-geometry.md (Curvature formalization)
 *   - backend/src/Types.hs CurvatureData, CurvatureClass
 */

import type { CurvatureData, CurvatureClass } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

interface CurvaturePanelProps {
  /** Curvature data from the patch, or `null` if unavailable. */
  data: CurvatureData | null;
}

// ════════════════════════════════════════════════════════════════
//  Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Format an integer numerator as a rational string using the
 * given denominator.
 *
 * Examples:
 *   formatRational(-5, 20)  → "−0.25"
 *   formatRational(10, 10)  → "1"
 *   formatRational(-2, 10)  → "−0.2"
 *   formatRational(0, 10)   → "0"
 */
function formatRational(numerator: number, denominator: number): string {
  if (denominator === 0) return String(numerator);
  const value = numerator / denominator;
  // Use a Unicode minus sign for negative values (academic typography)
  if (value < 0) {
    return `−${Math.abs(value)}`;
  }
  // Remove trailing zeros but keep at least one decimal for non-integers
  return String(value);
}

/**
 * Format a curvature numerator with its denominator subscript.
 *
 * Examples:
 *   formatKappaSubscript(-5, 20)  → "κ₂₀ = −5"
 *   formatKappaSubscript(-2, 10)  → "κ₁₀ = −2"
 */
function formatKappaSubscript(kappa: number, denominator: number): string {
  const subscript = denominator === 10 ? "₁₀" : denominator === 20 ? "₂₀" : `_${denominator}`;
  const kappaStr = kappa < 0 ? `−${Math.abs(kappa)}` : String(kappa);
  return `κ${subscript} = ${kappaStr}`;
}

/**
 * Determine the dimension label based on the denominator.
 *
 * 2D patches ({5,4}, {5,3}) use denominator 10 (vertex curvature).
 * 3D patches ({4,3,5}) use denominator 20 (edge curvature).
 */
function dimensionLabel(denominator: number): string {
  if (denominator === 10) return "Vertex";
  if (denominator === 20) return "Edge";
  return "Element";
}

/**
 * Return a CSS text-color class for a curvature value.
 *
 * Negative (hyperbolic) → blue, zero (flat) → neutral, positive (spherical) → red.
 * Matches the curvature diverging color mode from frontend-spec §4.4.
 */
function kappaColorClass(kappa: number): string {
  if (kappa < 0) return "text-blue-600";
  if (kappa > 0) return "text-red-600";
  return "text-gray-600";
}

// ════════════════════════════════════════════════════════════════
//  Curvature class row
// ════════════════════════════════════════════════════════════════

interface ClassRowProps {
  cls: CurvatureClass;
}

/**
 * A single row in the curvature class table.
 */
function ClassRow({ cls }: ClassRowProps) {
  const contribution = cls.ccCount * cls.ccKappa;
  const contributionStr = contribution < 0 ? `−${Math.abs(contribution)}` : String(contribution);

  return (
    <tr className="border-b border-gray-100 last:border-b-0">
      <td className="py-1.5 pr-3">
        <span className="font-mono text-xs">{cls.ccName}</span>
      </td>
      <td className="py-1.5 pr-3 text-right tabular-nums text-sm">
        {cls.ccCount}
      </td>
      <td className="py-1.5 pr-3 text-right tabular-nums text-sm">
        {cls.ccValence}
      </td>
      <td className={`py-1.5 pr-3 text-right tabular-nums text-sm font-mono ${kappaColorClass(cls.ccKappa)}`}>
        {cls.ccKappa < 0 ? `−${Math.abs(cls.ccKappa)}` : String(cls.ccKappa)}
      </td>
      <td className="py-1.5 pr-3 text-right tabular-nums text-sm text-gray-500">
        {contributionStr}
      </td>
      <td className="py-1.5 text-xs text-gray-400">
        {cls.ccLocation}
      </td>
    </tr>
  );
}

// ════════════════════════════════════════════════════════════════
//  Main component
// ════════════════════════════════════════════════════════════════

/**
 * Curvature panel for the Patch Viewer side panel.
 *
 * Displays a curvature class table, total curvature, Euler
 * characteristic, and a Gauss–Bonnet verification badge.
 *
 * @param data - The patch's CurvatureData, or `null` if the patch
 *   has no curvature information (e.g. tree, star, layer-54 patches).
 */
export function CurvaturePanel({ data }: CurvaturePanelProps) {
  if (!data) {
    return (
      <section
        className="rounded-lg border border-gray-200 bg-white p-4"
        aria-label="Curvature data"
      >
        <h3 className="font-serif text-base font-semibold text-gray-700 mb-2">
          Curvature
        </h3>
        <p className="text-sm text-gray-400 italic">
          No curvature data available for this patch.
        </p>
      </section>
    );
  }

  const dimLabel = dimensionLabel(data.curvDenominator);
  const totalRational = formatRational(data.curvTotal, data.curvDenominator);
  const eulerRational = formatRational(data.curvEuler, data.curvDenominator);

  return (
    <section
      className="rounded-lg border border-gray-200 bg-white p-4"
      aria-label="Curvature data"
    >
      {/* ── Header ──────────────────────────────────────────── */}
      <h3 className="font-serif text-base font-semibold text-gray-700 mb-3">
        Curvature
      </h3>

      {/* ── Denomination context ────────────────────────────── */}
      <p className="text-xs text-gray-400 mb-3">
        {dimLabel} curvature in {data.curvDenominator === 10 ? "tenths" : "twentieths"}
        {" "}(denominator = {data.curvDenominator})
      </p>

      {/* ── Class table ─────────────────────────────────────── */}
      {data.curvClasses.length > 0 && (
        <div className="overflow-x-auto mb-3">
          <table className="w-full text-left" aria-label="Curvature classes">
            <thead>
              <tr className="border-b border-gray-200 text-xs text-gray-500 uppercase tracking-wider">
                <th className="py-1.5 pr-3 font-medium">Class</th>
                <th className="py-1.5 pr-3 font-medium text-right">Count</th>
                <th className="py-1.5 pr-3 font-medium text-right">Val.</th>
                <th className="py-1.5 pr-3 font-medium text-right">κ</th>
                <th className="py-1.5 pr-3 font-medium text-right">Σ</th>
                <th className="py-1.5 font-medium">Loc.</th>
              </tr>
            </thead>
            <tbody>
              {data.curvClasses.map((cls) => (
                <ClassRow
                  key={cls.ccName}
                  cls={cls}
                />
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* ── Summary values ──────────────────────────────────── */}
      <div className="space-y-1.5 border-t border-gray-100 pt-3">
        {/* Total curvature */}
        <div className="flex items-baseline justify-between text-sm">
          <span className="text-gray-600">
            Total Σκ
          </span>
          <span className="font-mono tabular-nums text-gray-800">
            {data.curvTotal < 0 ? `−${Math.abs(data.curvTotal)}` : String(data.curvTotal)}
            <span className="text-gray-400 ml-1">
              ({totalRational})
            </span>
          </span>
        </div>

        {/* Euler characteristic */}
        <div className="flex items-baseline justify-between text-sm">
          <span className="text-gray-600">
            Euler χ
          </span>
          <span className="font-mono tabular-nums text-gray-800">
            {data.curvEuler < 0 ? `−${Math.abs(data.curvEuler)}` : String(data.curvEuler)}
            <span className="text-gray-400 ml-1">
              ({eulerRational})
            </span>
          </span>
        </div>

        {/* Gauss–Bonnet badge */}
        <div className="flex items-center justify-between text-sm pt-1">
          <span className="text-gray-600">
            Gauss–Bonnet
          </span>
          {data.curvGaussBonnet ? (
            <span
              className="inline-flex items-center gap-1 rounded-full bg-green-50 px-2.5 py-0.5 text-xs font-medium text-green-700 ring-1 ring-inset ring-green-600/20"
              role="status"
              aria-label="Gauss–Bonnet verified"
            >
              <span aria-hidden="true">✓</span>
              <span className="font-mono">refl</span>
            </span>
          ) : (
            <span
              className="inline-flex items-center gap-1 rounded-full bg-red-50 px-2.5 py-0.5 text-xs font-medium text-red-700 ring-1 ring-inset ring-red-600/20"
              role="status"
              aria-label="Gauss–Bonnet not verified"
            >
              <span aria-hidden="true">✗</span>
              <span>failed</span>
            </span>
          )}
        </div>
      </div>

      {/* ── Per-class detail lines (expanded view) ──────────── */}
      {data.curvClasses.length > 0 && (
        <div className="mt-3 border-t border-gray-100 pt-3 space-y-1">
          {data.curvClasses.map((cls) => {
            const contribution = cls.ccCount * cls.ccKappa;
            const contribStr = contribution < 0
              ? `−${Math.abs(contribution)}`
              : String(contribution);
            return (
              <p
                key={`detail-${cls.ccName}`}
                className="text-xs text-gray-500 font-mono"
              >
                {cls.ccName}:{" "}
                {cls.ccCount} × ({cls.ccKappa < 0 ? `−${Math.abs(cls.ccKappa)}` : cls.ccKappa})
                {" "}= {contribStr}
                <span className="ml-2 text-gray-400">
                  [{formatKappaSubscript(cls.ccKappa, data.curvDenominator)}]
                </span>
              </p>
            );
          })}
        </div>
      )}
    </section>
  );
}