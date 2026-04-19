/**
 * Persistent navigation header for the Univalence Gravity frontend.
 *
 * Provides the project title (linking to the home page) and navigation
 * links to the four main routes: Home, Patches, Tower, and Theorems.
 *
 * Design principles (frontend-spec §4.1):
 *   - Serif heading for academic credibility
 *   - Muted Viridis-inspired palette (viridis-500 brand color)
 *   - Clean whitespace, no gratuitous animation
 *   - Keyboard navigable, ARIA-labeled
 *   - Responsive: full nav on desktop/tablet, hamburger on mobile
 *
 * Reference: docs/engineering/frontend-spec-webgl.md §5
 */

import { useState, useCallback } from "react";
import { NavLink } from "react-router-dom";

/**
 * Navigation route descriptor for building the nav link list.
 * Kept as a plain array rather than fetched data — these are
 * structural routes, not API-driven content.
 */
interface NavRoute {
  /** URL path */
  to: string;
  /** Display label */
  label: string;
  /** Accessible description for screen readers */
  ariaLabel: string;
}

const NAV_ROUTES: readonly NavRoute[] = [
  { to: "/", label: "Home", ariaLabel: "Navigate to project overview" },
  { to: "/patches", label: "Patches", ariaLabel: "Browse verified patch instances" },
  { to: "/tower", label: "Tower", ariaLabel: "View resolution tower timeline" },
  { to: "/theorems", label: "Theorems", ariaLabel: "View theorem dashboard" },
] as const;

/**
 * Returns Tailwind class names for a NavLink based on its active state.
 *
 * Active links receive an underline and stronger text color (viridis-950
 * on light background). Inactive links use a muted gray that brightens
 * on hover. The transition is subtle — no bouncing or color explosions.
 *
 * @param isActive - Whether the link matches the current route.
 */
function navLinkClasses(isActive: boolean): string {
  const base =
    "px-3 py-2 text-sm font-medium transition-colors duration-150 rounded-md focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2";

  if (isActive) {
    return `${base} text-viridis-500 underline underline-offset-4 decoration-2 decoration-viridis-600`;
  }

  return `${base} text-gray-600 hover:text-gray-900 hover:bg-gray-100`;
}

/**
 * Mobile nav link classes — larger touch targets, full-width items.
 */
function mobileNavLinkClasses(isActive: boolean): string {
  const base =
    "block px-4 py-3 text-base font-medium transition-colors duration-150 rounded-md focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2";

  if (isActive) {
    return `${base} text-viridis-500 bg-viridis-50 underline underline-offset-4 decoration-2 decoration-viridis-600`;
  }

  return `${base} text-gray-600 hover:text-gray-900 hover:bg-gray-100`;
}

/**
 * Persistent site-wide navigation header.
 *
 * Renders:
 *   - A serif project title linking to `/` (the brand anchor)
 *   - Horizontal navigation links on md+ screens
 *   - A hamburger toggle for mobile screens (<768px) that expands
 *     to a vertical nav menu
 *
 * The component is stateless except for the mobile menu toggle.
 * No data fetching — the header is structural chrome, not content.
 */
export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const toggleMobileMenu = useCallback(() => {
    setMobileMenuOpen((prev) => !prev);
  }, []);

  const closeMobileMenu = useCallback(() => {
    setMobileMenuOpen(false);
  }, []);

  return (
    <header className="sticky top-0 z-50 border-b border-gray-200 bg-white/95 backdrop-blur-sm">
      <div className="mx-auto max-w-8xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* ── Brand / Title ──────────────────────────────────── */}
          <NavLink
            to="/"
            className="flex items-baseline gap-2 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2 rounded-md px-1"
            aria-label="Navigate to home page"
            onClick={closeMobileMenu}
          >
            <span className="font-serif text-lg font-bold text-gray-900 tracking-tight">
              Univalence Gravity
            </span>
            <span className="hidden sm:inline text-xs text-gray-400 font-mono">
              v0.5
            </span>
          </NavLink>

          {/* ── Desktop Navigation (md+) ──────────────────────── */}
          <nav
            className="hidden md:flex md:items-center md:gap-1"
            aria-label="Main navigation"
          >
            {NAV_ROUTES.map((route) => (
              <NavLink
                key={route.to}
                to={route.to}
                end={route.to === "/"}
                className={({ isActive }) => navLinkClasses(isActive)}
                aria-label={route.ariaLabel}
              >
                {route.label}
              </NavLink>
            ))}
          </nav>

          {/* ── Mobile Menu Button (<md) ──────────────────────── */}
          <button
            type="button"
            className="inline-flex items-center justify-center rounded-md p-2 text-gray-500 hover:bg-gray-100 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2 md:hidden"
            aria-label={mobileMenuOpen ? "Close navigation menu" : "Open navigation menu"}
            aria-expanded={mobileMenuOpen}
            aria-controls="mobile-nav-menu"
            onClick={toggleMobileMenu}
          >
            {mobileMenuOpen ? (
              /* X icon (close) */
              <svg
                className="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            ) : (
              /* Hamburger icon (open) */
              <svg
                className="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={1.5}
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* ── Mobile Navigation Menu ──────────────────────────────── */}
      {mobileMenuOpen && (
        <nav
          id="mobile-nav-menu"
          className="border-t border-gray-200 bg-white px-4 pb-4 pt-2 md:hidden"
          aria-label="Mobile navigation"
        >
          <div className="flex flex-col gap-1">
            {NAV_ROUTES.map((route) => (
              <NavLink
                key={route.to}
                to={route.to}
                end={route.to === "/"}
                className={({ isActive }) => mobileNavLinkClasses(isActive)}
                aria-label={route.ariaLabel}
                onClick={closeMobileMenu}
              >
                {route.label}
              </NavLink>
            ))}
          </div>
        </nav>
      )}
    </header>
  );
}