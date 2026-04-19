/**
 * Compact theorem status card for the home page theorem grid.
 *
 * Displays a theorem's number, name, verification status badge,
 * and Agda module path in a small clickable card. Clicking
 * navigates to the `/theorems` dashboard page.
 *
 * This is a compact summary card for the home page grid layout
 * (frontend-spec §5.1). It is distinct from {@link TheoremRow},
 * which is an expandable row with full details used in the
 * TheoremDashboard (`/theorems`).
 *
 * Visual design:
 *   - Left border colored by verification status (green / gray / orange)
 *   - Serif heading for the theorem name (academic credibility)
 *   - Monospace module path (Agda module reference)
 *   - Viridis-accent focus ring for keyboard navigation
 *
 * Accessibility:
 *   - Keyboard navigable (Tab to focus, Enter/Space to activate)
 *   - ARIA label describes theorem number, name, and status
 *   - Respects `prefers-reduced-motion` (disables hover transition)
 *
 * @see TheoremRow — The detailed expandable row counterpart.
 * @see HomePage — The parent page consuming this component.
 *
 * Reference: docs/engineering/frontend-spec-webgl.md §5.1
 */

import { Link } from "react-router-dom";

import type { Theorem, TheoremStatus } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link TheoremCard} component. */
interface TheoremCardProps {
  /** The theorem to display. */
  theorem: Theorem;
}

// ════════════════════════════════════════════════════════════════
//  Status display mapping
// ════════════════════════════════════════════════════════════════

/**
 * Visual configuration for a theorem's verification status.
 *
 * Maps each {@link TheoremStatus} variant to its icon character,
 * accessible label, and Tailwind utility classes for consistent
 * badge and accent rendering.
 */
interface StatusDisplay {
  /** Single character shown in the status badge */
  icon: string;
  /** Accessible status description */
  label: string;
  /** Tailwind text color class for the status icon */
  textClass: string;
  /** Tailwind background class for the badge circle */
  badgeBg: string;
  /** Tailwind border-left color class for the card accent stripe */
  borderClass: string;
}

/**
 * Map a {@link TheoremStatus} to its visual display properties.
 *
 * Color mapping follows the frontend-spec §5.5:
 *   - Verified  → green (status-verified = #16a34a)
 *   - Dead      → gray  (status-dead = #9ca3af)
 *   - Numerical → orange (status-numerical = #ea580c)
 */
function getStatusDisplay(status: TheoremStatus): StatusDisplay {
  switch (status) {
    case "Verified":
      return {
        icon: "✓",
        label: "Verified",
        textClass: "text-status-verified",
        badgeBg: "bg-green-50",
        borderClass: "border-l-status-verified",
      };
    case "Dead":
      return {
        icon: "—",
        label: "Dead code",
        textClass: "text-status-dead",
        badgeBg: "bg-gray-100",
        borderClass: "border-l-status-dead",
      };
    case "Numerical":
      return {
        icon: "~",
        label: "Numerical only",
        textClass: "text-status-numerical",
        badgeBg: "bg-orange-50",
        borderClass: "border-l-status-numerical",
      };
  }
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Compact theorem status card for the home page.
 *
 * Renders as a clickable card navigating to `/theorems`. The card
 * shows the theorem number, name, a color-coded status badge, and
 * the Agda module path in monospace.
 *
 * The left border stripe is colored by the verification status,
 * providing an at-a-glance visual indicator when scanning the
 * theorem grid.
 *
 * @example
 * ```tsx
 * {theorems.map(thm => (
 *   <TheoremCard key={thm.thmNumber} theorem={thm} />
 * ))}
 * ```
 */
export function TheoremCard({ theorem }: TheoremCardProps) {
  const display = getStatusDisplay(theorem.thmStatus);

  return (
    <Link
      to="/theorems"
      state={{ highlightTheorem: theorem.thmNumber }}
      className={[
        // Layout & shape
        "block rounded-lg border border-gray-200 border-l-4 p-4",
        // Left accent stripe colored by status
        display.borderClass,
        // Background & shadow
        "bg-white shadow-sm",
        // Hover: lift shadow (disabled with reduced motion)
        "transition-shadow duration-150 hover:shadow-md",
        "motion-reduce:transition-none",
        // Focus: Viridis-accent ring for keyboard navigation
        "focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2",
      ].join(" ")}
      aria-label={`Theorem ${theorem.thmNumber}: ${theorem.thmName} — ${display.label}`}
    >
      {/* ── Header row: theorem number + status badge ────────── */}
      <div className="flex items-center justify-between gap-2">
        <span className="font-serif text-sm font-medium text-gray-500">
          Theorem {theorem.thmNumber}
        </span>

        {/* Status badge — small circle with icon */}
        <span
          className={[
            "inline-flex h-6 w-6 items-center justify-center",
            "rounded-full text-xs font-bold",
            display.badgeBg,
            display.textClass,
          ].join(" ")}
          title={display.label}
          aria-hidden="true"
        >
          {display.icon}
        </span>
      </div>

      {/* ── Theorem name ─────────────────────────────────────── */}
      <h3 className="mt-1.5 font-serif text-base font-semibold leading-tight text-gray-900">
        {theorem.thmName}
      </h3>

      {/* ── Agda module path ─────────────────────────────────── */}
      <p className="mt-2 truncate font-mono text-xs text-gray-400">
        {theorem.thmModule}
      </p>
    </Link>
  );
}