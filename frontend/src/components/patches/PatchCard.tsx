/**
 * Card component for displaying a patch instance summary in the
 * `/patches` listing grid.
 *
 * Renders key statistics from a PatchSummary (name, tiling, dimension,
 * cells, regions, orbits, max min-cut, strategy) in a compact card
 * format with a navigation link to the full patch viewer at
 * `/patches/:name`.
 *
 * This component receives PatchSummary data (the lightweight listing
 * type from GET /patches), NOT the full Patch with region data. Full
 * data loading is deferred until the user navigates to the patch viewer.
 *
 * Design: Academic credibility (frontend-spec §4.1) — serif heading,
 * muted colors, clean whitespace. Progressive disclosure (§4.2) —
 * shows high-level stats on the card, details on click-through.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.2 (Patch List)
 *   - backend/src/Types.hs PatchSummary
 */

import { Link } from "react-router-dom";

import type { GrowthStrategy, PatchSummary, Tiling } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Display name helpers
// ════════════════════════════════════════════════════════════════

/**
 * Human-readable display name for a Tiling enum value.
 *
 * Converts the Haskell-derived JSON string (e.g. "Tiling54") to
 * the Schläfli symbol notation used in the documentation and the
 * physics literature (e.g. "{5,4}").
 */
function tilingDisplayName(tiling: Tiling): string {
  switch (tiling) {
    case "Tiling54":
      return "{5,4}";
    case "Tiling435":
      return "{4,3,5}";
    case "Tiling53":
      return "{5,3}";
    case "Tiling44":
      return "{4,4}";
    case "Tree":
      return "Tree";
  }
}

/**
 * Human-readable display name for a GrowthStrategy enum value.
 *
 * These are already readable as-is (BFS, Dense, Geodesic, Hemisphere),
 * but this function provides a central point for future formatting.
 */
function strategyDisplayName(strategy: GrowthStrategy): string {
  return strategy;
}

/**
 * Human-readable dimension label.
 *
 * Converts the numeric dimension (1, 2, 3) to a display string.
 */
function dimensionLabel(dim: number): string {
  return `${dim}D`;
}

// ════════════════════════════════════════════════════════════════
//  Component props
// ════════════════════════════════════════════════════════════════

/** Props for {@link PatchCard}. */
export interface PatchCardProps {
  /** The patch summary data from GET /patches. */
  patch: PatchSummary;
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * A card displaying summary statistics for a single patch instance.
 *
 * Used in the `/patches` card grid (PatchList). Clicking the card
 * navigates to the full patch viewer at `/patches/:name`.
 *
 * Layout:
 * ```
 * ┌───────────────────────────┐
 * │  dense-100                │  ← serif heading
 * │  {4,3,5} • 3D • Dense     │  ← tiling • dimension • strategy
 * │                           │
 * │  Cells     100            │  ← key stats
 * │  Regions   717 → 8 orbits │
 * │  Max S     8              │
 * │                           │
 * │  View Details →           │  ← navigation link
 * └───────────────────────────┘
 * ```
 */
export function PatchCard({ patch }: PatchCardProps) {
  const {
    psName,
    psTiling,
    psDimension,
    psCells,
    psRegions,
    psOrbits,
    psMaxCut,
    psStrategy,
  } = patch;

  // Format the orbit info: "717 → 8 orbits" or just "10"
  const regionDisplay =
    psOrbits > 0
      ? `${psRegions} → ${psOrbits} orbits`
      : `${psRegions}`;

  return (
    <article
      className="group rounded-lg border border-gray-200 bg-white p-5 shadow-sm
                 transition-shadow duration-200 hover:shadow-md"
      aria-label={`Patch instance: ${psName}`}
    >
      {/* ── Header: name + subtitle ─────────────────────────── */}
      <h3 className="font-serif text-lg font-semibold text-gray-900">
        {psName}
      </h3>
      <p className="mt-1 text-sm text-gray-500">
        <span>{tilingDisplayName(psTiling)}</span>
        <span className="mx-1.5" aria-hidden="true">•</span>
        <span>{dimensionLabel(psDimension)}</span>
        <span className="mx-1.5" aria-hidden="true">•</span>
        <span>{strategyDisplayName(psStrategy)}</span>
      </p>

      {/* ── Stats grid ──────────────────────────────────────── */}
      <dl className="mt-4 space-y-1.5 text-sm" aria-label="Patch statistics">
        <div className="flex justify-between">
          <dt className="text-gray-500">Cells</dt>
          <dd className="font-mono text-gray-900">{psCells}</dd>
        </div>
        <div className="flex justify-between">
          <dt className="text-gray-500">Regions</dt>
          <dd className="font-mono text-gray-900">{regionDisplay}</dd>
        </div>
        <div className="flex justify-between">
          <dt className="text-gray-500">Max S</dt>
          <dd className="font-mono text-gray-900">{psMaxCut}</dd>
        </div>
      </dl>

      {/* ── Navigation link ─────────────────────────────────── */}
      <div className="mt-4 border-t border-gray-100 pt-3">
        <Link
          to={`/patches/${psName}`}
          className="inline-flex items-center text-sm font-medium text-viridis-600
                     transition-colors duration-150 hover:text-viridis-700"
          aria-label={`View details for ${psName}`}
        >
          View Details
          <span className="ml-1" aria-hidden="true">→</span>
        </Link>
      </div>
    </article>
  );
}