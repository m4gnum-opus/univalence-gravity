/**
 * Typed fetch wrappers for all 7 Haskell backend REST API endpoints.
 *
 * Every function in this module performs a single `fetch()` call to the
 * backend, validates the HTTP response status, and returns the parsed
 * JSON body typed against the interfaces from `src/types/index.ts`.
 *
 * The base URL is read from the `VITE_API_URL` environment variable
 * (set in `.env` or `.env.local`). In development, this defaults to
 * `http://localhost:8080` — the Haskell backend's default listen address.
 *
 * All data served by the backend is static, pre-computed, and Agda-verified.
 * These functions never mutate data; they only read.
 *
 * Each endpoint function accepts an optional `AbortSignal` parameter so
 * that callers (typically React hooks) can cancel in-flight requests on
 * component unmount or dependency change. When a request is aborted, the
 * underlying `fetch()` rejects with a `DOMException` (`name === "AbortError"`)
 * which the calling hook should catch and silently ignore.
 *
 * Reference:
 *   - docs/engineering/backend-spec-haskell.md §5 (API Endpoints)
 *   - docs/engineering/frontend-spec-webgl.md §3.1 (API Client)
 *   - backend/src/Api.hs (Servant API type definition)
 */

import type {
  CurvatureSummary,
  Health,
  Meta,
  Patch,
  PatchSummary,
  Theorem,
  TowerLevel,
} from "../types";

// ════════════════════════════════════════════════════════════════
//  Base URL
// ════════════════════════════════════════════════════════════════

/**
 * The backend API base URL, without a trailing slash.
 *
 * Read from the `VITE_API_URL` environment variable at build time
 * (Vite statically replaces `import.meta.env.VITE_API_URL` during
 * bundling). Falls back to `http://localhost:8080` for local
 * development when no `.env` file is present.
 */
const BASE_URL: string =
  import.meta.env.VITE_API_URL ?? "http://localhost:8080";

// ════════════════════════════════════════════════════════════════
//  Error class
// ════════════════════════════════════════════════════════════════

/**
 * Error thrown when an API request fails (non-2xx HTTP status).
 *
 * Carries the HTTP status code and the response status text so
 * that consumers (hooks, components) can distinguish between
 * different failure modes (e.g. 404 Not Found vs 500 Server Error).
 */
export class ApiError extends Error {
  public readonly status: number;
  public readonly statusText: string;

  constructor(status: number, statusText: string, url: string) {
    super(`API request failed: ${status} ${statusText} (${url})`);
    this.name = "ApiError";
    this.status = status;
    this.statusText = statusText;
  }
}

// ════════════════════════════════════════════════════════════════
//  Internal helper
// ════════════════════════════════════════════════════════════════

/**
 * Perform a GET request to the given path, validate the response
 * status, and return the parsed JSON body.
 *
 * @param path - The URL path relative to `BASE_URL` (must start
 *   with `/`, e.g. `/patches` or `/patches/dense-100`).
 * @param signal - Optional `AbortSignal` from an `AbortController`.
 *   When the signal is aborted, the underlying `fetch()` rejects
 *   with a `DOMException` (`name === "AbortError"`). Callers should
 *   catch this and treat it as a silent cancellation (not a
 *   user-visible error). This is the recommended pattern for
 *   cancelling in-flight requests on React component unmount or
 *   dependency change, and is especially valuable for large payloads
 *   like Dense-1000 (~2.9 MB).
 * @returns The parsed JSON response body, typed as `T`.
 * @throws {ApiError} On any non-2xx HTTP response.
 * @throws {DOMException} With `name === "AbortError"` when the
 *   signal is aborted before the request completes.
 * @throws {TypeError} On network failures (DNS, connection refused,
 *   CORS blocked, etc.) — propagated from the underlying `fetch()`.
 */
async function fetchJson<T>(path: string, signal?: AbortSignal): Promise<T> {
  const url = `${BASE_URL}${path}`;
  const response = await fetch(url, signal ? { signal } : undefined);

  if (!response.ok) {
    throw new ApiError(response.status, response.statusText, url);
  }

  const data: T = await response.json() as T;
  return data;
}

// ════════════════════════════════════════════════════════════════
//  Public API — one function per endpoint
// ════════════════════════════════════════════════════════════════

/**
 * Fetch the lightweight listing of all patch instances.
 *
 * `GET /patches` → `PatchSummary[]`
 *
 * Returns an array of summaries (name, tiling, cells, regions,
 * maxCut, strategy) without the full region data. Use this for
 * the `/patches` card grid page.
 *
 * The response is immutable (Cache-Control: max-age=86400) — the
 * data changes only when the Agda code is re-verified and the
 * export script is re-run.
 *
 * @param signal - Optional `AbortSignal` for request cancellation.
 */
export async function fetchPatches(signal?: AbortSignal): Promise<PatchSummary[]> {
  return fetchJson<PatchSummary[]>("/patches", signal);
}

/**
 * Fetch the full data for a single patch instance by name.
 *
 * `GET /patches/:name` → `Patch`
 *
 * Returns the complete patch including all region data, curvature,
 * and half-bound statistics. This is the heavy payload — defer
 * loading until the user navigates to `/patches/:name`.
 *
 * @param name - The patch name as it appears in the URL, e.g.
 *   `"dense-100"`, `"layer-54-d7"`, `"star"`.
 * @param signal - Optional `AbortSignal` for request cancellation.
 * @throws {ApiError} With `status === 404` if the patch name does
 *   not match any loaded patch on the backend.
 */
export async function fetchPatch(name: string, signal?: AbortSignal): Promise<Patch> {
  return fetchJson<Patch>(`/patches/${encodeURIComponent(name)}`, signal);
}

/**
 * Fetch the resolution tower levels with monotonicity witnesses.
 *
 * `GET /tower` → `TowerLevel[]`
 *
 * Returns all tower levels ordered from coarsest resolution
 * (Dense-50) to finest (Dense-200), followed by the {5,4} layer
 * levels (depths 2–7). Each level carries a monotonicity witness
 * `(k, "refl")` linking it to its predecessor, or `null` for
 * the first level of a sub-tower.
 *
 * @param signal - Optional `AbortSignal` for request cancellation.
 */
export async function fetchTower(signal?: AbortSignal): Promise<TowerLevel[]> {
  return fetchJson<TowerLevel[]>("/tower", signal);
}

/**
 * Fetch the theorem registry.
 *
 * `GET /theorems` → `Theorem[]`
 *
 * Returns all 10 machine-checked theorems from the canonical
 * registry (`docs/formal/01-theorems.md`) with their status,
 * module path, informal statement, and proof method.
 *
 * @param signal - Optional `AbortSignal` for request cancellation.
 */
export async function fetchTheorems(signal?: AbortSignal): Promise<Theorem[]> {
  return fetchJson<Theorem[]>("/theorems", signal);
}

/**
 * Fetch Gauss–Bonnet curvature summaries across all patches.
 *
 * `GET /curvature` → `CurvatureSummary[]`
 *
 * Returns one entry per patch that has curvature data (filled,
 * desitter, dense-50, dense-100, dense-200, honeycomb-3d).
 * Patches without curvature (tree, star, layer-54) are absent.
 *
 * @param signal - Optional `AbortSignal` for request cancellation.
 */
export async function fetchCurvature(signal?: AbortSignal): Promise<CurvatureSummary[]> {
  return fetchJson<CurvatureSummary[]>("/curvature", signal);
}

/**
 * Fetch server and data metadata.
 *
 * `GET /meta` → `Meta`
 *
 * Returns the repository version, build timestamp, Agda compiler
 * version, and a truncated SHA-256 hash of the exported data
 * (usable as an ETag for cache-busting).
 *
 * @param signal - Optional `AbortSignal` for request cancellation.
 */
export async function fetchMeta(signal?: AbortSignal): Promise<Meta> {
  return fetchJson<Meta>("/meta", signal);
}

/**
 * Fetch server health status.
 *
 * `GET /health` → `Health`
 *
 * Returns the number of loaded patches, total region count, and
 * an "ok" status string. This endpoint is NOT cached by the
 * backend (exempt from Cache-Control middleware) so monitoring
 * tools always receive a fresh response.
 *
 * @param signal - Optional `AbortSignal` for request cancellation.
 */
export async function fetchHealth(signal?: AbortSignal): Promise<Health> {
  return fetchJson<Health>("/health", signal);
}