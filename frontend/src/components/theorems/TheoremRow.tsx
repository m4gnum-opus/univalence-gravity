/**
 * TheoremRow — A single expandable row in the Theorem Dashboard.
 *
 * Displays a theorem's number, name, module path, and verification
 * status in a compact summary row. Click (or Enter/Space) to expand
 * an accordion panel showing the informal statement, proof method,
 * and a verification command.
 *
 * Design references:
 *   - docs/engineering/frontend-spec-webgl.md §5.5 (Theorem Dashboard)
 *   - docs/engineering/frontend-spec-webgl.md §4.1 (Academic Credibility)
 *   - docs/engineering/frontend-spec-webgl.md §4.2 (Progressive Disclosure)
 *
 * Accessibility:
 *   - Rendered as a `role="listitem"` inside the parent's `role="list"`
 *     container, following the WAI-ARIA accordion pattern
 *   - Uses a <button> for the summary row (keyboard-focusable by default)
 *   - aria-expanded tracks open/closed state
 *   - aria-controls links the button to the detail panel
 *   - The detail panel uses role="region" with aria-labelledby
 *   - Respects prefers-reduced-motion for expand/collapse transitions
 *
 * @example
 * ```tsx
 * <TheoremRow theorem={theorem} defaultExpanded={false} />
 * ```
 */

import { useState, useId } from "react";

import type { Theorem, TheoremStatus } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

export interface TheoremRowProps {
  /** The theorem data to display. */
  theorem: Theorem;
  /** Whether the row starts expanded. Defaults to `false`. */
  defaultExpanded?: boolean;
}

// ════════════════════════════════════════════════════════════════
//  Status badge helpers
// ════════════════════════════════════════════════════════════════

/**
 * Map a TheoremStatus to its display label.
 *
 * Uses the exact status strings from the backend; no renaming.
 */
function statusLabel(status: TheoremStatus): string {
  switch (status) {
    case "Verified":
      return "✓ Verified";
    case "Dead":
      return "Dead";
    case "Numerical":
      return "Numerical";
  }
}

/**
 * Map a TheoremStatus to Tailwind CSS classes for the badge.
 *
 * Colors from tailwind.config.js → colors.status:
 *   - Verified:  green (status-verified / #16a34a)
 *   - Dead:      gray  (status-dead / #9ca3af)
 *   - Numerical: orange (status-numerical / #ea580c)
 *
 * We use Tailwind's built-in color utilities that approximate
 * these values rather than arbitrary values, for consistency
 * with the utility-first approach. The exact brand colors from
 * the config are available via `bg-status-verified` etc.
 */
function statusBadgeClasses(status: TheoremStatus): string {
  const base = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium";
  switch (status) {
    case "Verified":
      return `${base} bg-green-100 text-green-800`;
    case "Dead":
      return `${base} bg-gray-100 text-gray-600`;
    case "Numerical":
      return `${base} bg-orange-100 text-orange-800`;
  }
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * A single expandable theorem row.
 *
 * The summary row is a full-width button showing:
 *   - Theorem number (e.g. "#1")
 *   - Theorem name (serif font)
 *   - Module path (monospace)
 *   - Status badge (colored pill)
 *
 * The expanded detail panel shows:
 *   - Informal statement
 *   - Proof method (monospace, since it references Agda constructs)
 *   - Verification command (monospace code block)
 */
export function TheoremRow({
  theorem,
  defaultExpanded = false,
}: TheoremRowProps) {
  const [expanded, setExpanded] = useState(defaultExpanded);

  // Generate unique IDs for ARIA linking between the trigger
  // button and the expandable region.
  const reactId = useId();
  const buttonId = `theorem-row-btn-${reactId}`;
  const panelId = `theorem-row-panel-${reactId}`;

  /** Derive the `agda` verification command from the module path. */
  const verifyCommand = `agda src/${theorem.thmModule}`;

  return (
    <div role="listitem" className="border-b border-gray-200 last:border-b-0">
      {/* ── Summary Row (clickable trigger) ─────────────────── */}
      <button
        id={buttonId}
        type="button"
        className={
          "w-full text-left px-4 py-3 flex items-center gap-4 " +
          "hover:bg-gray-50 focus:outline-none focus-visible:ring-2 " +
          "focus-visible:ring-viridis-600 focus-visible:ring-inset " +
          "transition-colors duration-150 " +
          "motion-reduce:transition-none"
        }
        aria-expanded={expanded}
        aria-controls={panelId}
        onClick={() => setExpanded((prev) => !prev)}
      >
        {/* Theorem number */}
        <span
          className="flex-shrink-0 w-8 text-right font-mono text-sm text-gray-500"
          aria-label={`Theorem number ${theorem.thmNumber}`}
        >
          #{theorem.thmNumber}
        </span>

        {/* Theorem name — serif for academic credibility */}
        <span className="flex-1 min-w-0 font-serif text-base font-medium text-gray-900 truncate">
          {theorem.thmName}
        </span>

        {/* Module path — monospace for Agda module references */}
        <span
          className="hidden md:inline-block flex-shrink-0 font-mono text-xs text-gray-500 truncate max-w-[16rem]"
          title={theorem.thmModule}
        >
          {theorem.thmModule}
        </span>

        {/* Status badge */}
        <span className={statusBadgeClasses(theorem.thmStatus)}>
          {statusLabel(theorem.thmStatus)}
        </span>

        {/* Expand/collapse chevron */}
        <svg
          className={
            "flex-shrink-0 w-4 h-4 text-gray-400 transform transition-transform duration-200 " +
            "motion-reduce:transition-none " +
            (expanded ? "rotate-180" : "rotate-0")
          }
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          aria-hidden="true"
        >
          <path
            fillRule="evenodd"
            d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
            clipRule="evenodd"
          />
        </svg>
      </button>

      {/* ── Expanded Detail Panel ───────────────────────────── */}
      {expanded && (
        <div
          id={panelId}
          role="region"
          aria-labelledby={buttonId}
          className="px-4 pb-4 pt-1 ml-12 space-y-3 text-sm"
        >
          {/* Informal statement */}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1">
              Statement
            </h4>
            <p className="text-gray-700 leading-relaxed">
              {theorem.thmStatement}
            </p>
          </div>

          {/* Proof method — monospace since it references Agda constructs */}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1">
              Proof Method
            </h4>
            <p className="font-mono text-xs text-gray-700 leading-relaxed">
              {theorem.thmProofMethod}
            </p>
          </div>

          {/* Module path (visible on mobile where it's hidden in the summary) */}
          <div className="md:hidden">
            <h4 className="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1">
              Module
            </h4>
            <p className="font-mono text-xs text-gray-700">
              {theorem.thmModule}
            </p>
          </div>

          {/* Verification command */}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wide text-gray-500 mb-1">
              Verify
            </h4>
            <pre
              className={
                "bg-gray-100 rounded px-3 py-2 font-mono text-xs text-gray-800 " +
                "overflow-x-auto select-all"
              }
            >
              <code>{verifyCommand}</code>
            </pre>
          </div>
        </div>
      )}
    </div>
  );
}