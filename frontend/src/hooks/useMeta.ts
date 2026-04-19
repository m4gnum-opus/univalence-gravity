/**
 * Custom React hook for fetching server and data metadata.
 *
 * Wraps the `GET /meta` endpoint with loading/error state management.
 * The metadata includes the repository version, Agda compiler version,
 * build timestamp, and a truncated SHA-256 data hash (usable as an
 * ETag for cache-busting).
 *
 * This hook fetches once on mount. The metadata is static — it changes
 * only when the Agda code is re-verified and `18_export_json.py` is
 * re-run.
 *
 * The returned `refetch` callback can be wired to an `<ErrorMessage>`
 * retry button to re-trigger the fetch without a full page reload.
 *
 * First consumers: Footer (version, Agda version, data hash), HomePage.
 *
 * @example
 * ```tsx
 * const { data, loading, error, refetch } = useMeta();
 * if (loading) return <Loading />;
 * if (error) return <ErrorMessage message={error} onRetry={refetch} />;
 * return <span>v{data.version}</span>;
 * ```
 */

import { useEffect, useState, useCallback } from "react";

import { fetchMeta } from "../api/client";
import type { Meta } from "../types";

/** Return type of the {@link useMeta} hook. */
export interface UseMetaResult {
  /** The parsed Meta response, or `null` while loading or on error. */
  data: Meta | null;
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
 * Fetch server and data metadata from `GET /meta`.
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
export function useMeta(): UseMetaResult {
  const [data, setData] = useState<Meta | null>(null);
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

        const meta = await fetchMeta(controller.signal);

        setData(meta);
      } catch (err: unknown) {
        // AbortError is expected on unmount or refetch — the
        // controller was aborted in the cleanup function. Don't
        // treat this as a user-visible error.
        if (err instanceof DOMException && err.name === "AbortError") {
          return;
        }

        setError(
          err instanceof Error
            ? err.message
            : "Failed to fetch metadata"
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