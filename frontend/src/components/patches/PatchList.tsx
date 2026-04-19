/**
 * PatchList — Browsable card grid of all 14 verified patch instances.
 *
 * Renders the `/patches` page: fetches the lightweight patch summary
 * listing from `GET /patches` via the `usePatches` hook, then displays
 * the results in a responsive card grid with sorting and filtering
 * controls.
 *
 * Features:
 *   - **Sorting** by name, cells, regions, max min-cut, or tiling type
 *   - **Filtering** by tiling type, spatial dimension, or growth strategy
 *   - **Responsive layout**: 3 columns on desktop (≥1280px), 2 on tablet
 *     (768–1279px), 1 on mobile (<768px) — matching frontend-spec §9
 *   - **Progressive disclosure**: cards show high-level stats; clicking
 *     through to `/patches/:name` loads the full patch data with 3D
 *     viewport (frontend-spec §4.2)
 *
 * This page uses `PatchSummary[]` from `GET /patches` (no region data).
 * Full region data is deferred to the patch viewer (`PatchView`) when
 * the user navigates to an individual patch.
 *
 * Fixes applied (review issue #9):
 *   The `usePatches` hook exposes a `refetch` callback that is wired
 *   to the `<ErrorMessage onRetry={refetch}>` so the user can retry
 *   a failed fetch without a full page reload.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.2 (Patch List)
 *   - docs/engineering/frontend-spec-webgl.md §4.2 (Progressive Disclosure)
 *   - docs/engineering/frontend-spec-webgl.md §9 (Responsive Breakpoints)
 */

import { useState, useMemo, useCallback } from "react";

import { usePatches } from "../../hooks/usePatches";
import { Loading } from "../common/Loading";
import { ErrorMessage } from "../common/ErrorMessage";
import { PatchCard } from "./PatchCard";
import type { GrowthStrategy, PatchSummary, Tiling } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Sort configuration
// ════════════════════════════════════════════════════════════════

/**
 * Sortable fields for the patch listing.
 *
 * Each value corresponds to a field on PatchSummary (with the "ps"
 * prefix stripped for readability in the UI).
 */
type SortField = "name" | "cells" | "regions" | "maxCut" | "tiling";

/** Sort direction. */
type SortDirection = "asc" | "desc";

/** Combined sort state. */
interface SortState {
  field: SortField;
  direction: SortDirection;
}

/** Display labels for sort fields. */
const SORT_FIELD_LABELS: Readonly<Record<SortField, string>> = {
  name: "Name",
  cells: "Cells",
  regions: "Regions",
  maxCut: "Max S",
  tiling: "Tiling",
};

/**
 * Compare two PatchSummary values by the given sort field.
 *
 * String fields (name, tiling) use locale-aware comparison.
 * Numeric fields use arithmetic comparison.
 *
 * @returns Negative if a < b, 0 if equal, positive if a > b.
 */
function comparePatchSummaries(
  a: PatchSummary,
  b: PatchSummary,
  field: SortField,
): number {
  switch (field) {
    case "name":
      return a.psName.localeCompare(b.psName);
    case "cells":
      return a.psCells - b.psCells;
    case "regions":
      return a.psRegions - b.psRegions;
    case "maxCut":
      return a.psMaxCut - b.psMaxCut;
    case "tiling":
      return a.psTiling.localeCompare(b.psTiling);
  }
}

// ════════════════════════════════════════════════════════════════
//  Filter configuration
// ════════════════════════════════════════════════════════════════

/** Filter state for the patch listing. */
interface FilterState {
  /** Filter by tiling type. `null` = show all tilings. */
  tiling: Tiling | null;
  /** Filter by spatial dimension. `null` = show all dimensions. */
  dimension: number | null;
  /** Filter by growth strategy. `null` = show all strategies. */
  strategy: GrowthStrategy | null;
}

/** Initial filter state: no filters applied. */
const INITIAL_FILTERS: FilterState = {
  tiling: null,
  dimension: null,
  strategy: null,
};

/**
 * Human-readable display name for a Tiling enum value.
 *
 * Used in the filter dropdown. Matches the display names in PatchCard
 * but reproduced here to keep PatchList self-contained.
 */
function tilingLabel(tiling: Tiling): string {
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
 * Human-readable dimension label.
 */
function dimensionLabel(dim: number): string {
  return `${dim}D`;
}

/**
 * Apply the filter state to a PatchSummary, returning `true` if
 * the patch passes all active filters.
 */
function matchesFilters(patch: PatchSummary, filters: FilterState): boolean {
  if (filters.tiling !== null && patch.psTiling !== filters.tiling) {
    return false;
  }
  if (filters.dimension !== null && patch.psDimension !== filters.dimension) {
    return false;
  }
  if (filters.strategy !== null && patch.psStrategy !== filters.strategy) {
    return false;
  }
  return true;
}

// ════════════════════════════════════════════════════════════════
//  Unique value extraction for filter dropdowns
// ════════════════════════════════════════════════════════════════

/**
 * Extract the set of unique tiling types present in the data.
 * Returns a sorted array for deterministic dropdown ordering.
 */
function uniqueTilings(patches: PatchSummary[]): Tiling[] {
  const set = new Set<Tiling>();
  for (const p of patches) {
    set.add(p.psTiling);
  }
  return Array.from(set).sort();
}

/**
 * Extract the set of unique dimensions present in the data.
 * Returns a numerically sorted array.
 */
function uniqueDimensions(patches: PatchSummary[]): number[] {
  const set = new Set<number>();
  for (const p of patches) {
    set.add(p.psDimension);
  }
  return Array.from(set).sort((a, b) => a - b);
}

/**
 * Extract the set of unique growth strategies present in the data.
 * Returns a sorted array.
 */
function uniqueStrategies(patches: PatchSummary[]): GrowthStrategy[] {
  const set = new Set<GrowthStrategy>();
  for (const p of patches) {
    set.add(p.psStrategy);
  }
  return Array.from(set).sort();
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * The `/patches` page — browsable card grid of all verified patch
 * instances with sorting and filtering controls.
 *
 * Fetches `PatchSummary[]` on mount via `usePatches`, renders
 * loading/error states, then displays the filtered and sorted
 * results in a responsive card grid.
 *
 * Each card is rendered by {@link PatchCard} and links to the full
 * patch viewer at `/patches/:name`.
 */
export function PatchList() {
  const { data, loading, error, refetch } = usePatches();

  // ── Sort state ────────────────────────────────────────────────
  const [sort, setSort] = useState<SortState>({
    field: "name",
    direction: "asc",
  });

  // ── Filter state ──────────────────────────────────────────────
  const [filters, setFilters] = useState<FilterState>(INITIAL_FILTERS);

  // ── Derived unique values for filter dropdowns ────────────────
  const tilingOptions = useMemo(
    () => (data ? uniqueTilings(data) : []),
    [data],
  );
  const dimensionOptions = useMemo(
    () => (data ? uniqueDimensions(data) : []),
    [data],
  );
  const strategyOptions = useMemo(
    () => (data ? uniqueStrategies(data) : []),
    [data],
  );

  // ── Filtered + sorted patch list ──────────────────────────────
  const processedPatches = useMemo(() => {
    if (!data) return [];

    // 1. Filter
    const filtered = data.filter((p) => matchesFilters(p, filters));

    // 2. Sort
    const sorted = [...filtered].sort((a, b) => {
      const cmp = comparePatchSummaries(a, b, sort.field);
      return sort.direction === "asc" ? cmp : -cmp;
    });

    return sorted;
  }, [data, filters, sort]);

  // ── Whether any filter is active (to show "clear" button) ────
  const hasActiveFilters =
    filters.tiling !== null ||
    filters.dimension !== null ||
    filters.strategy !== null;

  // ── Event handlers ────────────────────────────────────────────

  /**
   * Toggle sort: if clicking the same field, flip direction;
   * if clicking a new field, sort ascending by that field.
   */
  const handleSortChange = useCallback(
    (field: SortField) => {
      setSort((prev) => {
        if (prev.field === field) {
          return {
            field,
            direction: prev.direction === "asc" ? "desc" : "asc",
          };
        }
        return { field, direction: "asc" };
      });
    },
    [],
  );

  const handleTilingFilter = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      const value = e.target.value;
      setFilters((prev) => ({
        ...prev,
        tiling: value === "" ? null : (value as Tiling),
      }));
    },
    [],
  );

  const handleDimensionFilter = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      const value = e.target.value;
      setFilters((prev) => ({
        ...prev,
        dimension: value === "" ? null : Number(value),
      }));
    },
    [],
  );

  const handleStrategyFilter = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      const value = e.target.value;
      setFilters((prev) => ({
        ...prev,
        strategy: value === "" ? null : (value as GrowthStrategy),
      }));
    },
    [],
  );

  const handleClearFilters = useCallback(() => {
    setFilters(INITIAL_FILTERS);
  }, []);

  // ── Loading state ─────────────────────────────────────────────
  if (loading) {
    return <Loading />;
  }

  // ── Error state ───────────────────────────────────────────────
  if (error) {
    return <ErrorMessage message={error} onRetry={refetch} />;
  }

  // ── Empty data state ──────────────────────────────────────────
  if (!data || data.length === 0) {
    return (
      <div className="max-w-6xl mx-auto px-4 py-8">
        <h1 className="font-serif text-3xl font-bold text-gray-900 mb-4">
          Verified Patch Instances
        </h1>
        <p className="text-gray-500">No patches available.</p>
      </div>
    );
  }

  // ── Sort direction indicator ──────────────────────────────────
  const sortIndicator = (field: SortField) => {
    if (sort.field !== field) return null;
    return (
      <span className="ml-1 text-viridis-600" aria-hidden="true">
        {sort.direction === "asc" ? "↑" : "↓"}
      </span>
    );
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-8">
      {/* ── Page Header ─────────────────────────────────────── */}
      <header className="mb-8">
        <h1 className="font-serif text-3xl font-bold text-gray-900 mb-2">
          Verified Patch Instances
        </h1>
        <p className="text-gray-600">
          {data.length} holographic patches verified by the Cubical Agda
          type-checker. Click any card to explore the full 3D visualization
          with region inspection, curvature data, and entropy-area statistics.
        </p>
      </header>

      {/* ── Controls Bar: Sort + Filter ─────────────────────── */}
      <div
        className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"
        role="toolbar"
        aria-label="Patch list sorting and filtering controls"
      >
        {/* ── Sort Buttons ──────────────────────────────────── */}
        <div>
          <label className="block text-xs font-medium uppercase tracking-wide text-gray-500 mb-1.5">
            Sort by
          </label>
          <div className="flex flex-wrap gap-1.5" role="group" aria-label="Sort field selection">
            {(Object.keys(SORT_FIELD_LABELS) as SortField[]).map((field) => (
              <button
                key={field}
                type="button"
                onClick={() => handleSortChange(field)}
                className={[
                  "rounded-md px-3 py-1.5 text-sm font-medium transition-colors duration-150",
                  "focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1",
                  sort.field === field
                    ? "bg-viridis-500 text-white"
                    : "bg-gray-100 text-gray-700 hover:bg-gray-200",
                ].join(" ")}
                aria-label={`Sort by ${SORT_FIELD_LABELS[field]}${
                  sort.field === field
                    ? `, currently ${sort.direction === "asc" ? "ascending" : "descending"}`
                    : ""
                }`}
                aria-pressed={sort.field === field}
              >
                {SORT_FIELD_LABELS[field]}
                {sortIndicator(field)}
              </button>
            ))}
          </div>
        </div>

        {/* ── Filter Dropdowns ──────────────────────────────── */}
        <div className="flex flex-wrap items-end gap-3">
          {/* Tiling filter */}
          <div>
            <label
              htmlFor="filter-tiling"
              className="block text-xs font-medium uppercase tracking-wide text-gray-500 mb-1"
            >
              Tiling
            </label>
            <select
              id="filter-tiling"
              value={filters.tiling ?? ""}
              onChange={handleTilingFilter}
              className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 focus:border-viridis-500 focus:outline-none focus:ring-1 focus:ring-viridis-500"
              aria-label="Filter by tiling type"
            >
              <option value="">All</option>
              {tilingOptions.map((t) => (
                <option key={t} value={t}>
                  {tilingLabel(t)}
                </option>
              ))}
            </select>
          </div>

          {/* Dimension filter */}
          <div>
            <label
              htmlFor="filter-dimension"
              className="block text-xs font-medium uppercase tracking-wide text-gray-500 mb-1"
            >
              Dimension
            </label>
            <select
              id="filter-dimension"
              value={filters.dimension ?? ""}
              onChange={handleDimensionFilter}
              className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 focus:border-viridis-500 focus:outline-none focus:ring-1 focus:ring-viridis-500"
              aria-label="Filter by spatial dimension"
            >
              <option value="">All</option>
              {dimensionOptions.map((d) => (
                <option key={d} value={d}>
                  {dimensionLabel(d)}
                </option>
              ))}
            </select>
          </div>

          {/* Strategy filter */}
          <div>
            <label
              htmlFor="filter-strategy"
              className="block text-xs font-medium uppercase tracking-wide text-gray-500 mb-1"
            >
              Strategy
            </label>
            <select
              id="filter-strategy"
              value={filters.strategy ?? ""}
              onChange={handleStrategyFilter}
              className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm text-gray-700 focus:border-viridis-500 focus:outline-none focus:ring-1 focus:ring-viridis-500"
              aria-label="Filter by growth strategy"
            >
              <option value="">All</option>
              {strategyOptions.map((s) => (
                <option key={s} value={s}>
                  {s}
                </option>
              ))}
            </select>
          </div>

          {/* Clear filters */}
          {hasActiveFilters && (
            <button
              type="button"
              onClick={handleClearFilters}
              className="rounded-md px-3 py-1.5 text-sm font-medium text-gray-500 hover:text-gray-700 hover:bg-gray-100 transition-colors duration-150 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1"
              aria-label="Clear all filters"
            >
              Clear filters
            </button>
          )}
        </div>
      </div>

      {/* ── Results Count ───────────────────────────────────── */}
      <p className="mb-4 text-sm text-gray-500" aria-live="polite">
        {processedPatches.length === data.length
          ? `Showing all ${data.length} patches`
          : `Showing ${processedPatches.length} of ${data.length} patches`}
        {sort.field !== "name" &&
          ` · sorted by ${SORT_FIELD_LABELS[sort.field]} (${sort.direction === "asc" ? "ascending" : "descending"})`}
      </p>

      {/* ── Card Grid ───────────────────────────────────────── */}
      {processedPatches.length > 0 ? (
        <div
          className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3"
          role="list"
          aria-label="Patch instance cards"
        >
          {processedPatches.map((patch) => (
            <div key={patch.psName} role="listitem">
              <PatchCard patch={patch} />
            </div>
          ))}
        </div>
      ) : (
        /* ── No results after filtering ─────────────────────── */
        <div className="rounded-lg border border-gray-200 bg-white p-8 text-center">
          <p className="text-gray-500">
            No patches match the current filters.
          </p>
          <button
            type="button"
            onClick={handleClearFilters}
            className="mt-3 text-sm font-medium text-viridis-600 hover:text-viridis-700 transition-colors"
            aria-label="Clear all filters to show all patches"
          >
            Clear filters to show all patches
          </button>
        </div>
      )}

      {/* ── Footer Note ─────────────────────────────────────── */}
      <p className="mt-8 text-center text-xs text-gray-400">
        Data served by the Haskell backend from pre-computed JSON
        produced by{" "}
        <span className="font-mono">18_export_json.py</span>
        {" · "}
        All region data is Agda-verified
      </p>
    </div>
  );
}