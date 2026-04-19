/**
 * Root layout shell wrapping every route in the application.
 *
 * Renders the persistent Header (navigation) at the top, the
 * matched route content via React Router's `<Outlet />` in the
 * main area, and the Footer (metadata) at the bottom.
 *
 * The layout uses a min-h-screen flex column so that the Footer
 * is pushed to the bottom of the viewport even when page content
 * is short (sticky footer pattern via flexbox).
 *
 * This component is consumed by App.tsx as the element of the
 * root `<Route>`, with all page routes as nested children:
 *
 * ```tsx
 * <Route element={<Layout />}>
 *   <Route path="/" element={<HomePage />} />
 *   <Route path="/patches" element={<PatchList />} />
 *   ...
 * </Route>
 * ```
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4 (Application Routes)
 *   - docs/engineering/frontend-spec-webgl.md §10 (Responsive Design)
 */

import { Outlet } from "react-router-dom";

import { Header } from "./Header";
import { Footer } from "./Footer";

/**
 * Persistent layout shell: Header + routed content + Footer.
 *
 * The `<main>` element carries `flex-1` so it expands to fill all
 * available vertical space between the header and footer, ensuring
 * the footer stays at the bottom of the viewport regardless of
 * content height.
 *
 * A max-width container (`max-w-8xl`) with horizontal auto-margin
 * centers the content on wide screens while the header and footer
 * span the full viewport width (their internal content handles
 * their own max-width constraints).
 */
export function Layout() {
  return (
    <div className="flex min-h-screen flex-col bg-gray-50 text-gray-900">
      <Header />

      <main className="mx-auto w-full max-w-8xl flex-1 px-4 py-6 sm:px-6 lg:px-8">
        <Outlet />
      </main>

      <Footer />
    </div>
  );
}