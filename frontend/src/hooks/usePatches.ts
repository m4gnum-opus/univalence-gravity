/**
 * Custom React hook for fetching the patch summary listing.
 *
 * Wraps the `GET /patches` endpoint with loading/error state management.
 * Returns lightweight `PatchSummary[]` (no region data) — full patch data
 * is deferred to `usePatch(name)` when the user navigates to
 * `/patches/:name`.
 *
 * This hook fetches once on mount. The patch listing is static — it
 * changes only when new patch instances are added to the Agda
 * formalization and `18_export_json.py` is re-run.
 *
 * The returned `refetch` callback can be wired to an `<ErrorMessage>`
 * retry button to re-trigger the fetch without a full page reload.
 *
 * First consumer: PatchList (`/patches`).
 *
 * @example
 * ```tsx
 * const { data, loading, error, refetch } = usePatches();
 * if (loading) return <Loading />;
 * if (error) return <ErrorMessage message={error} onRetry={refetch} />;
 * return <PatchGrid patches={data} />;
 * ```
 */

import { useState, useEffect, useCallback } from "react";

import { fetchPatches } from "../api/client";
import type { PatchSummary } from "../types";

/** Return type of the {@link usePatches} hook. */
export interface UsePatchesResult {
  /** The parsed PatchSummary array, or `null` while loading or on error. */
  data: PatchSummary[] | null;
  /** `true` while the fetch is in flight. */
  loading: boolean;
  /** A human-readable error message, or `null` on success. */
  error: string | null;
  /**
   * Re-trigger the fetch.
   *
   * Useful as the `onRetry` callback for `<ErrorMessage>` so the
   * user can retry a failed request without a full page reload.
   * Internally increments a fetch counter that is included in the
   * effect's dependency array, causing the effect to re-run.
   */
  refetch: () => void;
}

/**
 * Fetch the patch summary listing from `GET /patches`.
 *
 * Returns `{ data, loading, error, refetch }` following the standard
 * hook pattern used by all data hooks in this project.
 *
 * - `loading` starts as `true` and becomes `false` after the fetch
 *   completes (whether successfully or with an error).
 * - `data` is `null` until a successful response is received.
 * - `error` is `null` on success, or a descriptive string on failure.
 * - `refetch` re-triggers the fetch (useful for wiring to an
 *   `<ErrorMessage onRetry={refetch} />`).
 *
 * The effect cleanup aborts in-flight fetches via `AbortController`
 * when the component unmounts or `refetch` is called. This both
 * prevents React state updates on unmounted components and cancels
 * the underlying HTTP request.
 */
export function usePatches(): UsePatchesResult {
  const [data, setData] = useState<PatchSummary[] | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // A counter that, when incremented, causes the effect to re-run.
  // This is the mechanism behind `refetch()`: the counter is included
  // in the effect's dependency array, so bumping it triggers a fresh
  // fetch.
  const [fetchCount, setFetchCount] = useState<number>(0);

  useEffect(() => {
    const controller = new AbortController();

    async function load(): Promise<void> {
      try {
        setLoading(true);
        setError(null);

        const patches = await fetchPatches(controller.signal);

        setData(patches);
      } catch (err: unknown) {
        // AbortError is expected on unmount or refetch — the
        // controller was aborted in the cleanup function. Don't
        // treat this as a user-visible error.
        if (err instanceof DOMException && err.name === "AbortError") {
          return;
        }

        setError(
          err instanceof Error ? err.message : "Failed to fetch patches"
        );
      } finally {
        // Only update loading state if the request was NOT aborted.
        // When aborted due to refetch, a new effect iteration is
        // about to start and will set loading=true itself. When
        // aborted due to unmount, state updates on unmounted
        // components are discarded by React 18 but are best avoided
        // for clarity.
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      controller.abort();
    };
  }, [fetchCount]);

  /**
   * Re-trigger the fetch by incrementing the fetch counter.
   *
   * The counter is in the effect's dependency array, so incrementing
   * it causes the effect to re-run: the old request is aborted (via
   * the cleanup function), and a fresh request is started.
   *
   * Wrapped in `useCallback` with no dependencies because the
   * `setFetchCount` setter is stable across renders (React guarantee).
   */
  const refetch = useCallback(() => {
    setFetchCount((c) => c + 1);
  }, []);

  return { data, loading, error, refetch };
}