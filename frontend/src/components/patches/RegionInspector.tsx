// src/components/patches/RegionInspector.tsx
/**
 * RegionInspector — side-panel detail view for a selected boundary region.
 *
 * Displays all fields of a single {@link Region} in a clean, academic-style
 * table layout. When no region is selected, shows a prompt instructing the
 * user to click a cell in the 3D viewport.
 *
 * **Area-model awareness (v0.6.0):**
 *   The ratio bar, half-slack row, and Bekenstein–Hawking achiever badge
 *   are suppressed when the patch tiling has no face-count area model
 *   (currently: Tree).  For such patches, the "area" field in the region
 *   data is a simplified proxy (`5 * |cells|`) that does not correspond
 *   to boundary surface area.  Displaying S/area ratios, half-slack
 *   values, and BH-bound references would be physically misleading.
 *
 *   The Area row itself is still shown (with a "(proxy)" annotation)
 *   because the numeric value is present in the data and may be useful
 *   for debugging, even though it lacks physical significance.
 *
 * This is a stateless presentational component — it receives data via props
 * and renders it without side effects or API calls.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3 (Region Inspector panel)
 *   - backend/src/Types.hs Region (field semantics)
 *   - backend/src/Invariants.hs facesPerCell (Tree → Nothing)
 */

import type { CSSProperties } from "react";

import { colorFromMinCut } from "../../utils/colors";
import type { Region, Tiling } from "../../types";

/** Props for the {@link RegionInspector} component. */
export interface RegionInspectorProps {
  /** The currently selected region, or `null` if no region is selected. */
  region: Region | null;
  /** The patch name, used for display context (e.g. "dense-100"). */
  patchName: string;
  /** The maximum min-cut value across all regions in this patch. */
  patchMaxCut: number;
  /**
   * The patch's tiling type.  Used to determine whether area-based
   * metrics (half-slack, S/area ratio bar, BH achiever badge) are
   * physically meaningful.  For `"Tree"` patches, these are
   * suppressed because the area value is a proxy, not a face-count
   * boundary surface area.
   */
  patchTiling?: Tiling;
  /** Callback to deselect the current region. */
  onDeselect?: () => void;
}

// ════════════════════════════════════════════════════════════════
//  Area-model detection
// ════════════════════════════════════════════════════════════════

/**
 * Whether a tiling type has a face-count boundary area model.
 *
 * Mirrors `facesPerCell` in `backend/src/Invariants.hs`:
 *   {4,3,5} → 6, {5,4} → 5, {5,3} → 5, {4,4} → 4, Tree → Nothing
 *
 * When `false`, the region's `regionArea` is a simplified proxy
 * and area-derived metrics (half-slack, S/area, BH achiever) should
 * not be displayed with their usual physical interpretation.
 */
function hasAreaModel(tiling: Tiling | undefined): boolean {
  if (tiling === undefined) return true; // conservative default
  return tiling !== "Tree";
}

// ════════════════════════════════════════════════════════════════
//  Display helpers
// ════════════════════════════════════════════════════════════════

/**
 * Format a list of cell IDs as a brace-enclosed set string.
 *
 * @example
 * formatCellSet([14, 93, 95, 97, 98]) // → "{c14, c93, c95, c97, c98}"
 * formatCellSet([3])                   // → "{c3}"
 */
function formatCellSet(cellIds: number[]): string {
  if (cellIds.length === 0) return "∅";
  return `{${cellIds.map((id) => `c${id}`).join(", ")}}`;
}

/**
 * A single row in the region detail table.
 *
 * Renders a label–value pair with consistent typography:
 * - Label: muted gray, regular weight
 * - Value: dark text, medium weight, monospace for numeric/code values
 */
function DetailRow({
  label,
  value,
  mono = false,
  suffix,
}: {
  label: string;
  value: string | number;
  mono?: boolean;
  /** Optional muted suffix shown after the value (e.g. "(proxy)"). */
  suffix?: string;
}) {
  return (
    <div className="flex justify-between items-baseline py-1.5 border-b border-gray-100 last:border-b-0">
      <span className="text-sm text-gray-500 shrink-0 mr-3">{label}</span>
      <span
        className={`text-sm text-gray-900 font-medium text-right ${
          mono ? "font-mono" : ""
        }`}
      >
        {value}
        {suffix && (
          <span className="ml-1 text-xs text-gray-400 font-normal">
            {suffix}
          </span>
        )}
      </span>
    </div>
  );
}

/**
 * Side-panel detail view for a selected boundary region.
 *
 * When `region` is `null`, displays a placeholder prompt. When a
 * region is provided, renders all of its fields in a labeled table
 * with a color swatch showing the min-cut color and a deselect button.
 *
 * The component uses the following visual conventions from the spec:
 * - Monospace (`font-mono`) for cell IDs, orbit labels, and numeric values
 * - A small color swatch next to the min-cut value showing the Viridis color
 * - The S/area ratio is displayed with 4 decimal places (matching `regionRatio`)
 * - Half-slack shows "—" when null (not computed)
 *
 * **Area-model gating:**
 *   When `patchTiling` is `"Tree"` (or any future tiling without a
 *   face-count area model), the following elements are suppressed:
 *     - "S / area" detail row
 *     - "Half-slack" detail row
 *     - BH tight achiever badge
 *     - Ratio bar visualization (with its "½ (BH bound)" label)
 *   The "Area" row remains but is annotated with "(proxy)" to signal
 *   that the value is a simplified stand-in, not a true boundary
 *   surface area.
 */
export function RegionInspector({
  region,
  patchName,
  patchMaxCut,
  patchTiling,
  onDeselect,
}: RegionInspectorProps) {
  // ── No selection state ─────────────────────────────────────────
  if (!region) {
    return (
      <section
        className="rounded-lg border border-gray-200 bg-white p-4"
        aria-label="Region inspector — no region selected"
      >
        <h3 className="text-sm font-serif font-semibold text-gray-700 mb-3">
          Region Inspector
        </h3>
        <p className="text-sm text-gray-400 italic">
          Click a cell in the 3D viewport to inspect its region.
        </p>
      </section>
    );
  }

  // ── Selected region display ────────────────────────────────────

  // Determine whether area-derived metrics are physically meaningful.
  const showAreaMetrics = hasAreaModel(patchTiling);

  // Compute the Viridis color for this region's min-cut value.
  const minCutColor = colorFromMinCut(region.regionMinCut, patchMaxCut);

  // Format the S/area ratio to 4 decimal places, matching regionRatio precision.
  const ratioDisplay = region.regionRatio.toFixed(4);

  // Half-slack: display as integer or "—" if not computed.
  const halfSlackDisplay =
    region.regionHalfSlack !== null
      ? region.regionHalfSlack.toString()
      : "—";

  // Determine whether S/area is at or near the Bekenstein–Hawking bound (0.5).
  // Only meaningful when the patch has a real area model.
  const isAtBound = showAreaMetrics && region.regionHalfSlack === 0;

  // ── Data-driven CSS custom properties for the ratio bar ────────
  //
  // Rule §12 says "No inline style={} except for dynamic Three.js-
  // related values."  The ratio bar's width and color are genuinely
  // data-driven (continuous percentage from regionRatio, runtime-
  // computed Viridis hex color) and cannot be expressed as static
  // Tailwind utilities.  We isolate the dynamic values as CSS custom
  // properties and reference them via Tailwind's arbitrary-value
  // syntax (w-[--var] / bg-[--var]), keeping all visual property
  // declarations inside Tailwind class lists.
  const ratioBarVars = {
    "--ratio-pct": `${Math.min(region.regionRatio / 0.5, 1.0) * 100}%`,
    "--ratio-color": minCutColor,
  } as CSSProperties;

  return (
    <section
      className="rounded-lg border border-gray-200 bg-white p-4"
      aria-label={`Region inspector — region ${region.regionId} of ${patchName}`}
    >
      {/* ── Header ──────────────────────────────────────────────── */}
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-sm font-serif font-semibold text-gray-700">
          Region Inspector
        </h3>
        {onDeselect && (
          <button
            onClick={onDeselect}
            className="text-xs text-gray-400 hover:text-gray-600 transition-colors"
            aria-label="Deselect region"
          >
            ✕ Clear
          </button>
        )}
      </div>

      {/* ── Region identity ─────────────────────────────────────── */}
      <div className="mb-3 pb-3 border-b border-gray-200">
        <div className="flex items-center gap-2">
          {/* Color swatch showing the min-cut Viridis color */}
          <span
            className="inline-block w-3 h-3 rounded-sm border border-gray-300 shrink-0"
            style={{ backgroundColor: minCutColor }}
            aria-hidden="true"
          />
          <span className="font-mono text-sm font-semibold text-gray-900">
            {patchName}:r{region.regionId}
          </span>
        </div>
      </div>

      {/* ── Detail rows ─────────────────────────────────────────── */}
      <div className="space-y-0">
        <DetailRow
          label="Cells"
          value={formatCellSet(region.regionCells)}
          mono
        />
        <DetailRow label="Size" value={region.regionSize} mono />
        <DetailRow label="Min-cut S" value={region.regionMinCut} mono />
        <DetailRow
          label="Area"
          value={region.regionArea}
          mono
          suffix={showAreaMetrics ? undefined : "(proxy)"}
        />
        {/* S/area and Half-slack are only meaningful with a real area model */}
        {showAreaMetrics && (
          <>
            <DetailRow label="S / area" value={ratioDisplay} mono />
            <DetailRow label="Half-slack" value={halfSlackDisplay} mono />
          </>
        )}
        <DetailRow label="Orbit" value={region.regionOrbit} mono />
      </div>

      {/* ── Bekenstein–Hawking bound badge ──────────────────────── */}
      {/* Only displayed when the area model is meaningful AND the
          bound is exactly saturated (2·S = area). */}
      {isAtBound && (
        <div className="mt-3 pt-3 border-t border-gray-200">
          <span className="inline-flex items-center gap-1.5 text-xs font-medium text-green-700 bg-green-50 border border-green-200 rounded-full px-2.5 py-0.5">
            <span aria-hidden="true">★</span>
            BH tight achiever: 2·S = area
          </span>
        </div>
      )}

      {/* ── Ratio bar visualization ─────────────────────────────── */}
      {/* Suppressed for tilings without a face-count area model —
          the "½ (BH bound)" reference would be misleading when the
          area is a simplified proxy. */}
      {showAreaMetrics && (
        <div className="mt-3 pt-3 border-t border-gray-200">
          <div className="flex items-center justify-between text-xs text-gray-500 mb-1">
            <span>S / area</span>
            <span>{ratioDisplay}</span>
          </div>
          <div className="relative h-2 bg-gray-100 rounded-full overflow-hidden">
            {/* Fill bar — width and color are data-driven, injected via
                CSS custom properties (see ratioBarVars above).  This is
                a justified deviation from Rule §12: continuous-domain
                data-visualization values cannot be Tailwind utilities. */}
            <div
              className="absolute left-0 top-0 h-full rounded-full transition-all duration-300 w-[var(--ratio-pct)] bg-[var(--ratio-color)]"
              style={ratioBarVars}
              role="progressbar"
              aria-valuenow={region.regionRatio}
              aria-valuemin={0}
              aria-valuemax={0.5}
              aria-label={`S/area ratio: ${ratioDisplay} out of 0.5 maximum`}
            />
            {/* 0.5 bound marker */}
            <div
              className="absolute top-0 h-full w-px bg-red-400 left-full"
              aria-hidden="true"
            />
          </div>
          <div className="flex justify-between text-[10px] text-gray-400 mt-0.5">
            <span>0</span>
            <span>½ (BH bound)</span>
          </div>
        </div>
      )}
    </section>
  );
}