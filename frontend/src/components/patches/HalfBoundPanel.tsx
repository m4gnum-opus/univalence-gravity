/**
 * Side-panel display for the discrete Bekenstein–Hawking half-bound data.
 *
 * Displays the sharp bound S(A) ≤ area(A)/2 statistics for a patch:
 * total regions verified, violation count (always 0 for valid data),
 * tight achiever count and sizes, slack range, mean slack, and the
 * identification of the discrete Newton's constant 1/(4G) = 1/2.
 *
 * The component distinguishes between Agda-verified half-bounds
 * (dense-100, dense-200) and Python-side numerical checks (all other
 * patches). Agda-verified patches display a green "Machine-Checked"
 * badge; others display an orange "Numerical" badge.
 *
 * Reference:
 *   - docs/formal/12-bekenstein-hawking.md (Theorem 3)
 *   - docs/physics/discrete-bekenstein-hawking.md
 *   - docs/engineering/frontend-spec-webgl.md §5.3 (Patch Viewer layout)
 *   - Bridge/HalfBound.agda (from-two-cuts, HalfBoundWitness)
 */

import type { HalfBoundData } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

export interface HalfBoundPanelProps {
  /** Half-bound summary data from the patch. */
  halfBound: HalfBoundData;
  /**
   * Whether the half-bound has been Agda-verified via a corresponding
   * Boundary/*HalfBound.agda module with `abstract (k, refl)` witnesses.
   * Currently `true` only for dense-100 and dense-200.
   */
  verified: boolean;
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Renders the discrete Bekenstein–Hawking half-bound statistics
 * in a compact side-panel section.
 *
 * Layout:
 * ```
 * ── Half-Bound ──────────────────────
 * S(A) ≤ area(A)/2    [Machine-Checked ✓]
 * 1/(4G) = 1/2
 *
 * Regions:    717        Violations: 0
 * Achievers:  40         Mean slack: 6.0
 * Slack range: [0, 14]
 *
 * Achiever sizes:
 *   k=1: 40 regions
 * ```
 */
export function HalfBoundPanel({ halfBound, verified }: HalfBoundPanelProps) {
  const {
    hbRegionCount,
    hbViolations,
    hbAchieverCount,
    hbAchieverSizes,
    hbSlackRange,
    hbMeanSlack,
  } = halfBound;

  const [minSlack, maxSlack] = hbSlackRange;
  const hasTightAchievers = hbAchieverCount > 0;

  return (
    <section
      aria-label="Bekenstein–Hawking half-bound statistics"
      className="space-y-3"
    >
      {/* ── Header ──────────────────────────────────────────── */}
      <div className="flex items-center justify-between gap-2">
        <h3 className="font-serif text-sm font-semibold text-gray-800">
          Half-Bound
        </h3>
        <VerificationBadge verified={verified} />
      </div>

      {/* ── Key identity ────────────────────────────────────── */}
      <div className="rounded border border-gray-200 bg-gray-50 px-3 py-2">
        <p className="font-mono text-xs text-gray-700">
          S(A) ≤ area(A)/2
        </p>
        <p className="mt-1 flex items-center gap-1.5 text-xs text-gray-600">
          <span className="font-mono">1/(4G) = 1/2</span>
          {hasTightAchievers && (
            <span
              className="inline-flex items-center rounded-full bg-green-100 px-1.5 py-0.5 text-[10px] font-medium text-green-800"
              title={`${hbAchieverCount} region${hbAchieverCount !== 1 ? "s" : ""} achieve equality 2·S = area`}
            >
              tight ✓
            </span>
          )}
        </p>
      </div>

      {/* ── Statistics grid ─────────────────────────────────── */}
      <dl className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
        <StatRow label="Regions" value={hbRegionCount.toLocaleString()} />
        <StatRow
          label="Violations"
          value={String(hbViolations)}
          className={hbViolations === 0 ? "text-green-700" : "text-red-700 font-semibold"}
        />
        <StatRow
          label="Achievers"
          value={String(hbAchieverCount)}
          title="Regions where 2·S(A) = area(A) — the bound is tight"
        />
        <StatRow
          label="Mean slack"
          value={hbMeanSlack.toFixed(1)}
          title="Average value of area − 2·S across all regions"
        />
        <div className="col-span-2">
          <StatRow
            label="Slack range"
            value={`[${minSlack}, ${maxSlack}]`}
            title="(min, max) of area − 2·S across all regions"
          />
        </div>
      </dl>

      {/* ── Achiever size breakdown ─────────────────────────── */}
      {hbAchieverSizes.length > 0 && (
        <div className="space-y-1">
          <p className="text-[10px] font-medium uppercase tracking-wide text-gray-500">
            Achiever sizes
          </p>
          <ul className="space-y-0.5">
            {hbAchieverSizes.map(([regionSize, count]) => (
              <li
                key={regionSize}
                className="flex items-center justify-between rounded bg-amber-50 px-2 py-0.5 text-xs"
              >
                <span className="font-mono text-gray-600">
                  k={regionSize}
                </span>
                <span className="text-gray-700">
                  {count} region{count !== 1 ? "s" : ""}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}

// ════════════════════════════════════════════════════════════════
//  Internal sub-components
// ════════════════════════════════════════════════════════════════

/**
 * Compact badge indicating whether the half-bound is Agda-verified
 * or a Python-side numerical check only.
 *
 * - Agda-verified: green badge with "Machine-Checked ✓"
 * - Numerical only: orange badge with "Numerical"
 *
 * Maps to the `patchHalfBoundVerified` boolean from the Patch type,
 * which is `true` only when a corresponding Boundary/*HalfBound.agda
 * module exists (currently: dense-100, dense-200).
 */
function VerificationBadge({ verified }: { verified: boolean }) {
  if (verified) {
    return (
      <span
        className="inline-flex items-center rounded-full bg-green-100 px-2 py-0.5 text-[10px] font-medium text-green-800"
        title="Verified by Cubical Agda 2.8.0 via abstract (k, refl) witnesses in Boundary/*HalfBound.agda"
      >
        Machine-Checked ✓
      </span>
    );
  }

  return (
    <span
      className="inline-flex items-center rounded-full bg-orange-100 px-2 py-0.5 text-[10px] font-medium text-orange-800"
      title="Half-bound verified numerically by the Python oracle only — no corresponding Boundary/*HalfBound.agda module exists"
    >
      Numerical
    </span>
  );
}

/**
 * A single label–value row in the statistics grid.
 *
 * Renders as a `<dt>` / `<dd>` pair inside the parent `<dl>`.
 * The `className` prop applies to the `<dd>` element only, allowing
 * conditional coloring (e.g. green for zero violations, red otherwise).
 */
function StatRow({
  label,
  value,
  className = "text-gray-900",
  title,
}: {
  label: string;
  value: string;
  className?: string;
  title?: string;
}) {
  return (
    <div className="flex items-baseline justify-between" title={title}>
      <dt className="text-gray-500">{label}</dt>
      <dd className={`font-mono ${className}`}>{value}</dd>
    </div>
  );
}