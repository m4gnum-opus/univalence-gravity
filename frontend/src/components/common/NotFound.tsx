/**
 * 404 Not Found page.
 *
 * Displayed for any route that does not match a defined path in the
 * application router (the `*` catch-all route in App.tsx). Also
 * usable as a fallback when a specific resource (e.g. a patch name)
 * is not found.
 *
 * Design follows the academic credibility principle from
 * frontend-spec §4.1: serif headings, muted palette, clean
 * whitespace. Provides clear navigation back to the home page
 * and other primary routes.
 *
 * Accessibility: all interactive elements are keyboard-navigable
 * via standard anchor/link semantics. The page title is an h1
 * for correct document outline.
 */

import { Link } from "react-router-dom";

/**
 * A static 404 page with navigation links to primary routes.
 *
 * Takes no props — the component renders the same content
 * regardless of which non-existent path was requested.
 *
 * @example
 * ```tsx
 * // In App.tsx route table:
 * <Route path="*" element={<NotFound />} />
 *
 * // Or inline when a resource is missing:
 * if (!data) return <NotFound />;
 * ```
 */
export function NotFound() {
  return (
    <div
      className="flex min-h-[60vh] flex-col items-center justify-center px-4 text-center"
      role="main"
      aria-label="Page not found"
    >
      {/* ── Status Code ─────────────────────────────────────── */}
      <p className="text-7xl font-bold text-viridis-500 sm:text-9xl">
        404
      </p>

      {/* ── Heading ─────────────────────────────────────────── */}
      <h1 className="mt-4 font-serif text-2xl font-semibold text-gray-800 sm:text-3xl">
        Page Not Found
      </h1>

      {/* ── Description ─────────────────────────────────────── */}
      <p className="mt-3 max-w-md text-gray-500">
        The requested path does not correspond to any verified
        patch, theorem, or visualization in this repository.
      </p>

      {/* ── Navigation ──────────────────────────────────────── */}
      <nav
        className="mt-8 flex flex-wrap items-center justify-center gap-4"
        aria-label="Recovery navigation"
      >
        <Link
          to="/"
          className="rounded-md bg-viridis-500 px-5 py-2.5 text-sm font-medium text-white transition-colors hover:bg-viridis-400 focus:outline-none focus:ring-2 focus:ring-viridis-500 focus:ring-offset-2"
        >
          Return Home
        </Link>

        <Link
          to="/patches"
          className="rounded-md border border-gray-300 bg-white px-5 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-viridis-500 focus:ring-offset-2"
        >
          Explore Patches
        </Link>

        <Link
          to="/theorems"
          className="rounded-md border border-gray-300 bg-white px-5 py-2.5 text-sm font-medium text-gray-700 transition-colors hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-viridis-500 focus:ring-offset-2"
        >
          View Theorems
        </Link>
      </nav>
    </div>
  );
}