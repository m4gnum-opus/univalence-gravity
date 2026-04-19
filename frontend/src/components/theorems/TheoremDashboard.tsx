/**
 * Theorem Dashboard page component (`/theorems`).
 *
 * Displays all 10 machine-checked theorems from the canonical registry
 * (`docs/formal/01-theorems.md`) with status badges, module paths, and
 * expandable detail rows. Each row is rendered by {@link TheoremRow},
 * which handles its own expand/collapse state and detail display.
 *
 * Data source: `GET /theorems` via the `useTheorems` hook.
 *
 * **highlightTheorem navigation state (review issue #2):**
 *   When the user clicks a TheoremCard on the HomePage, the card's
 *   `<Link>` passes `state={{ highlightTheorem: theorem.thmNumber }}`
 *   via React Router's location state. This component reads that state
 *   via `useLocation()` and passes `defaultExpanded={true}` to the
 *   matching TheoremRow, so the user lands on the dashboard with the
 *   clicked theorem already expanded. If no highlightTheorem state is
 *   present (e.g. direct navigation to `/theorems`), all rows start
 *   collapsed.
 *
 * **Retry wiring (review issue #9):**
 *   The `useTheorems` hook exposes a `refetch` callback that is wired
 *   to the `<ErrorMessage onRetry={refetch}>` so the user can retry
 *   a failed fetch without a full page reload.
 *
 * Layout follows the spec's accordion design:
 * ```
 * ┌─────────────────────────────────────────────────────────┐
 * │  Theorem Dashboard — All Machine-Checked Results        │
 * │  #  │ Name                      │ Module        │ ✓/✗  │
 * │  ───┼───────────────────────────┼───────────────┼────── │
 * │  1  │ Discrete Ryu–Takayanagi   │ GenericBridge │  ✓    │
 * │  ...                                                    │
 * │  Click row → expand to show statement, proof method     │
 * └─────────────────────────────────────────────────────────┘
 * ```
 *
 * ARIA semantics: The theorem list uses `role="list"` with
 * `role="listitem"` on each TheoremRow, following the WAI-ARIA
 * accordion pattern. The visual column header row is presentational
 * (`aria-hidden="true"`) — it provides alignment cues but is not a
 * semantic table header, since the rows are expandable accordion
 * items with interactive buttons, not tabular data cells.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.5 (Theorem Dashboard)
 *   - docs/formal/01-theorems.md (Canonical theorem registry)
 *   - https://www.w3.org/WAI/ARIA/apg/patterns/accordion/
 */

import { useLocation } from "react-router-dom";

import { useTheorems } from "../../hooks/useTheorems";
import { Loading } from "../common/Loading";
import { ErrorMessage } from "../common/ErrorMessage";
import { TheoremRow } from "./TheoremRow";

/**
 * Full `/theorems` page — fetches and displays all machine-checked
 * theorems with expandable detail rows.
 *
 * Renders:
 * - A page header with title, description, and status summary badges
 * - A list container with a presentational header and one TheoremRow
 *   per theorem (each is a `role="listitem"`)
 * - A footer note citing the source module and verification command
 *
 * Handles loading and error states via the common Loading and
 * ErrorMessage components. The ErrorMessage is wired to `refetch`
 * so the user can retry failed requests without a full page reload.
 *
 * Reads `location.state?.highlightTheorem` to auto-expand the
 * theorem row that was clicked on the HomePage's TheoremCard grid.
 */
export function TheoremDashboard() {
  const { data, loading, error, refetch } = useTheorems();

  // Read the highlightTheorem navigation state passed by TheoremCard
  // on the HomePage. When present, the matching TheoremRow starts
  // expanded so the user sees the detail panel immediately.
  //
  // The state is typed as `{ highlightTheorem?: number } | null`
  // because React Router's location.state is `unknown` by default.
  // We defensively extract the value with optional chaining and a
  // typeof guard.
  const location = useLocation();
  const locationState = location.state as { highlightTheorem?: number } | null;
  const highlightTheorem =
    typeof locationState?.highlightTheorem === "number"
      ? locationState.highlightTheorem
      : undefined;

  if (loading) {
    return <Loading />;
  }

  if (error) {
    return <ErrorMessage message={error} onRetry={refetch} />;
  }

  if (!data || data.length === 0) {
    return (
      <div className="max-w-5xl mx-auto px-4 py-8">
        <h1 className="font-serif text-3xl font-bold text-gray-900 mb-4">
          Theorem Dashboard
        </h1>
        <p className="text-gray-500">No theorems available.</p>
      </div>
    );
  }

  // Count theorems by status for the summary badges
  const verifiedCount = data.filter(
    (t) => t.thmStatus === "Verified"
  ).length;
  const deadCount = data.filter(
    (t) => t.thmStatus === "Dead"
  ).length;
  const numericalCount = data.filter(
    (t) => t.thmStatus === "Numerical"
  ).length;
  const totalCount = data.length;

  return (
    <div className="max-w-5xl mx-auto px-4 py-8">
      {/* ── Page Header ─────────────────────────────────────── */}
      <header className="mb-8">
        <h1 className="font-serif text-3xl font-bold text-gray-900 mb-2">
          Theorem Dashboard
        </h1>
        <p className="text-gray-600 text-lg">
          All Machine-Checked Results
        </p>
        <p className="mt-2 text-sm text-gray-500">
          {verifiedCount} of {totalCount} theorems verified by the
          Cubical Agda 2.8.0 type-checker. No axioms postulated; all
          transport computes.
        </p>
      </header>

      {/* ── Status Summary Badges ───────────────────────────── */}
      <div
        className="mb-6 flex flex-wrap gap-3"
        role="list"
        aria-label="Theorem status summary"
      >
        {verifiedCount > 0 && (
          <div
            className="inline-flex items-center gap-1.5 rounded-full border border-green-200 bg-green-50 px-3 py-1 text-sm text-green-800"
            role="listitem"
          >
            <span
              className="inline-block h-2 w-2 rounded-full bg-status-verified"
              aria-hidden="true"
            />
            <span>
              {verifiedCount} Verified
            </span>
          </div>
        )}
        {deadCount > 0 && (
          <div
            className="inline-flex items-center gap-1.5 rounded-full border border-gray-200 bg-gray-50 px-3 py-1 text-sm text-gray-600"
            role="listitem"
          >
            <span
              className="inline-block h-2 w-2 rounded-full bg-status-dead"
              aria-hidden="true"
            />
            <span>
              {deadCount} Dead
            </span>
          </div>
        )}
        {numericalCount > 0 && (
          <div
            className="inline-flex items-center gap-1.5 rounded-full border border-orange-200 bg-orange-50 px-3 py-1 text-sm text-orange-700"
            role="listitem"
          >
            <span
              className="inline-block h-2 w-2 rounded-full bg-status-numerical"
              aria-hidden="true"
            />
            <span>
              {numericalCount} Numerical
            </span>
          </div>
        )}
      </div>

      {/* ── Theorem Accordion ───────────────────────────────── */}
      {/*
       * ARIA pattern: list + listitem (accordion).
       *
       * This is NOT a data table — each "row" is an interactive
       * accordion trigger (<button>) with an expandable detail
       * panel. The WAI-ARIA table pattern (role="table" +
       * role="row" + role="cell") requires non-interactive cell
       * content and a strict grid structure, which conflicts with
       * the accordion's button-driven expand/collapse behavior.
       *
       * The visual column header row is marked aria-hidden="true"
       * because it serves only as a presentational alignment guide
       * for sighted users — it is not a semantic table header.
       * Screen readers navigate the list items directly, each of
       * which has a descriptive aria-label on its trigger button.
       *
       * Reference: https://www.w3.org/WAI/ARIA/apg/patterns/accordion/
       */}
      <div
        className="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm"
      >
        {/* Visual column alignment header — presentational only.
         *  Provides sighted users with column labels that visually
         *  align with the content in each TheoremRow's summary button.
         *  Hidden from the accessibility tree because the accordion
         *  list items carry their own descriptive labels. */}
        <div
          className="grid grid-cols-[3rem_1fr_4rem] gap-2 border-b border-gray-200 bg-gray-50 px-4 py-3 text-xs font-medium uppercase tracking-wider text-gray-500 sm:grid-cols-[3rem_1fr_12rem_4rem]"
          aria-hidden="true"
        >
          <span>#</span>
          <span>Theorem</span>
          <span className="hidden sm:block">
            Module
          </span>
          <span className="text-right">
            Status
          </span>
        </div>

        {/* Theorem rows — accordion list.
         *
         * When highlightTheorem is set (navigated from a HomePage
         * TheoremCard), the matching row starts expanded via
         * defaultExpanded={true}. All other rows start collapsed.
         */}
        <div
          role="list"
          aria-label="Machine-checked theorem registry"
        >
          {data.map((theorem) => (
            <TheoremRow
              key={theorem.thmNumber}
              theorem={theorem}
              defaultExpanded={theorem.thmNumber === highlightTheorem}
            />
          ))}
        </div>
      </div>

      {/* ── Footer Note ─────────────────────────────────────── */}
      <p className="mt-6 text-center text-xs text-gray-400">
        Source:{" "}
        <span className="font-mono">docs/formal/01-theorems.md</span>
        {" · "}
        Full verification:{" "}
        <span className="font-mono">
          agda src/Bridge/SchematicTower.agda
        </span>
      </p>
    </div>
  );
}