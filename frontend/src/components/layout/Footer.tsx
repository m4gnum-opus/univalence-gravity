/**
 * Persistent footer displaying project metadata from the backend.
 *
 * Fetches server/data metadata via the `useMeta` hook and renders
 * the repository version, Agda compiler version, build date, and
 * truncated data hash. Degrades gracefully during loading (shows
 * a skeleton line) and on error (shows a static fallback).
 *
 * The footer is part of the persistent layout chrome rendered by
 * `Layout.tsx` on every route. It should feel like the colophon
 * of an academic paper — understated, informative, and typeset
 * with care.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.1 (Home / footer area)
 *   - docs/engineering/frontend-spec-webgl.md §4.1 (Academic credibility)
 */

import { useMeta } from "../../hooks/useMeta";

/**
 * Site-wide footer with version info, Agda version, and data hash.
 *
 * Provides a clean academic colophon anchored to the bottom of
 * the layout. Metadata is fetched once on mount via `useMeta`;
 * subsequent renders use the cached result.
 */
export function Footer() {
  const { data, loading, error } = useMeta();

  return (
    <footer
      className="border-t border-gray-200 bg-white"
      role="contentinfo"
      aria-label="Site footer with project metadata"
    >
      <div className="mx-auto max-w-8xl px-4 py-4 sm:px-6 lg:px-8">
        {loading ? (
          /* ── Loading skeleton ─────────────────────────────────
           *  A single pulsing line placeholder that matches the
           *  approximate width and position of the metadata text.
           *  Uses motion-reduce to respect prefers-reduced-motion
           *  (frontend-spec §10).
           */
          <div className="flex justify-center">
            <div
              className="h-4 w-80 animate-pulse-slow rounded bg-gray-200 motion-reduce:animate-none"
              aria-label="Loading metadata…"
            />
          </div>
        ) : error || !data ? (
          /* ── Error / fallback ─────────────────────────────────
           *  If the metadata endpoint is unreachable, show a
           *  static fallback. The footer should never be blank —
           *  it is persistent chrome visible on every route.
           */
          <p className="text-center text-sm text-gray-400">
            Univalence Gravity • Cubical Agda • MIT License
          </p>
        ) : (
          /* ── Metadata display ─────────────────────────────────
           *  Two rows on mobile (stacked), one row on desktop.
           *
           *  Row 1: project identity + version + Agda version
           *  Row 2: data hash + build date
           *
           *  Typography follows the academic credibility principle:
           *  - Serif for the project name
           *  - Monospace for the data hash (it is a computed value)
           *  - Muted gray for supporting details
           */
          <div className="flex flex-col items-center gap-1 text-sm text-gray-500">
            {/* Primary line: project identity */}
            <p>
              <span className="font-serif font-medium text-gray-700">
                Univalence Gravity
              </span>
              {" "}
              <span className="text-gray-400">•</span>
              {" "}
              <span>
                v{data.version}
              </span>
              {" "}
              <span className="text-gray-400">•</span>
              {" "}
              <span>
                Agda {data.agdaVersion}
              </span>
              {" "}
              <span className="text-gray-400">•</span>
              {" "}
              <span>
                agda/cubical
              </span>
              {" "}
              <span className="text-gray-400">•</span>
              {" "}
              <span>
                MIT License
              </span>
            </p>

            {/* Secondary line: data hash + build date */}
            <p className="text-xs text-gray-400">
              Data hash:{" "}
              <code className="font-mono text-gray-500">
                {data.dataHash}
              </code>
              {" "}
              <span className="text-gray-300">•</span>
              {" "}
              Built:{" "}
              <time dateTime={data.buildDate}>
                {formatBuildDate(data.buildDate)}
              </time>
            </p>
          </div>
        )}
      </div>
    </footer>
  );
}

// ════════════════════════════════════════════════════════════════
//  Internal helpers
// ════════════════════════════════════════════════════════════════

/**
 * Format an ISO 8601 UTC timestamp into a human-readable date string.
 *
 * Input:  "2026-04-13T21:04:23Z"
 * Output: "2026-04-13"
 *
 * Falls back to the raw string if parsing fails (defensive against
 * unexpected date formats from the backend).
 */
function formatBuildDate(isoString: string): string {
  try {
    const date = new Date(isoString);
    // Check for invalid date (NaN timestamp)
    if (isNaN(date.getTime())) {
      return isoString;
    }
    // Return YYYY-MM-DD in UTC to match the build timestamp's timezone
    return date.toISOString().slice(0, 10);
  } catch {
    return isoString;
  }
}