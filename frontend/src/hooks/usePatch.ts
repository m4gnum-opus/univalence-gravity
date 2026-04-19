/**
 * Custom React hook for fetching a single patch instance by name.
 *
 * Wraps the `GET /patches/:name` endpoint with loading/error state
 * management. Returns the full Patch data including all region data,
 * curvature, and half-bound statistics — the heavy payload that is
 * deferred until the user navigates to `/patches/:name`.
 *
 * This hook fetches whenever the `name` parameter changes. If the
 * component unmounts or `name` changes before the request completes,
 * the in-flight fetch is cancelled via `AbortController` to prevent
 * stale state updates and to abort the underlying HTTP request
 * (especially valuable for large payloads like Dense-1000 at ~2.9 MB).
 *
 * A 404 response (nonexistent patch name) is surfaced as a
 * descriptive error string — the consumer can check for it and
 * render a NotFound component.
 *
 * The returned `refetch` callback can be wired to an `<ErrorMessage>`
 * retry button to re-trigger the fetch without a full page reload.
 *
 * First consumer: PatchView (`/patches/:name`).
 *
 * @example
 * ```tsx
 * const { name } = useParams<{ name: string }>();
 * const { data, loading, error, refetch } = usePatch(name ?? "");
 * if (loading) return <Loading />;
 * if (error) return <ErrorMessage message={error} onRetry={refetch} />;
 * if (!data) return <NotFound />;
 * return <PatchScene patch={data} />;
 * ```
 */

import { useEffect, useState, useCallback } from "react";

import { ApiError, fetchPatch } from "../api/client";
import type { Patch } from "../types";

/** Return type of the {@link usePatch} hook. */
export interface UsePatchResult {
  /** The parsed Patch response, or `null` while loading or on error. */
  data: Patch | null;
  /** `true` while the fetch is in flight. */
  loading: boolean;
  /** A human-readable error message, or `null` on success. */
  error: string | null;
  /**
   * Re-trigger the fetch for the current patch name.
   *
   * Useful as the `onRetry` callback for `<ErrorMessage>` so the
   * user can retry a failed request without a full page reload.
   * Internally increments a fetch counter that is included in the
   * effect's dependency array, causing the effect to re-run.
   */
  refetch: () => void;
}

/**
 * Fetch full patch data from `GET /patches/:name`.
 *
 * @param name - The patch name as it appears in the URL, e.g.
 *   `"dense-100"`, `"layer-54-d7"`, `"star"`. An empty string
 *   skips the fetch entirely (loading remains `true`, data stays
 *   `null`) — this handles the case where `useParams` returns
 *   `undefined` before the route is resolved.
 *
 * Returns `{ data, loading, error, refetch }` following the
 * standard hook pattern used by all data hooks in this project.
 *
 * - `loading` starts as `true` and becomes `false` after the fetch
 *   completes (whether successfully or with an error).
 * - `data` is `null` until a successful response is received.
 *   It is also reset to `null` when `name` changes (before the
 *   new fetch completes).
 * - `error` is `null` on success, or a descriptive string on failure.
 *   A 404 response produces `"Patch not found: <name>"`.
 * - `refetch` re-triggers the fetch for the current name (useful for
 *   wiring to an `<ErrorMessage onRetry={refetch} />`).
 *
 * The effect cleanup aborts in-flight fetches via `AbortController`
 * when `name` changes or the component unmounts. This both prevents
 * React state updates on unmounted components and cancels the
 * underlying HTTP request, saving bandwidth on large payloads
 * (e.g. Dense-1000 at ~2.9 MB).
 */
export function usePatch(name: string): UsePatchResult {
  const [data, setData] = useState<Patch | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // A counter that, when incremented, causes the effect to re-run.
  // This is the mechanism behind `refetch()`: the counter is included
  // in the effect's dependency array, so bumping it triggers a fresh
  // fetch without changing the `name` parameter.
  const [fetchCount, setFetchCount] = useState<number>(0);

  useEffect(() => {
    // Skip fetch for empty name (e.g. useParams returning undefined
    // before the route is resolved).
    if (!name) {
      setData(null);
      setLoading(false);
      setError("No patch name provided");
      return;
    }

    const controller = new AbortController();

    async function load(): Promise<void> {
      try {
        setLoading(true);
        setError(null);
        setData(null);

        const patch = await fetchPatch(name, controller.signal);

        setData(patch);
      } catch (err: unknown) {
        // AbortError is expected on unmount or name change — the
        // controller was aborted in the cleanup function. Don't
        // treat this as a user-visible error; a new fetch is either
        // about to start (name change / refetch) or the component
        // has unmounted (navigation away).
        if (err instanceof DOMException && err.name === "AbortError") {
          return;
        }

        // Provide a specific message for 404 (nonexistent patch).
        if (err instanceof ApiError && err.status === 404) {
          setError(`Patch not found: ${name}`);
          return;
        }

        const message =
          err instanceof Error
            ? err.message
            : "Failed to fetch patch";

        setError(message);
      } finally {
        // Only update loading state if the request was NOT aborted.
        // When aborted due to name change or refetch, a new effect
        // iteration is about to start and will set loading=true
        // itself. When aborted due to unmount, state updates on
        // unmounted components are discarded by React 18 but are
        // best avoided for clarity.
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }

    void load();

    return () => {
      controller.abort();
    };
  }, [name, fetchCount]);

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