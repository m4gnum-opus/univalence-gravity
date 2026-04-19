/**
 * Top-level route table for the Univalence Gravity frontend.
 *
 * Composes all five page views and the 404 fallback inside the
 * persistent {@link Layout} shell (Header + Outlet + Footer).
 * React Router's `<Outlet />` in Layout.tsx renders the matched
 * child route's element.
 *
 * Route structure:
 *
 *   /                → HomePage       (project overview + theorem cards)
 *   /patches         → PatchList      (browsable card grid of 14 patches)
 *   /patches/:name   → PatchView      (3D interactive patch viewer)
 *   /tower           → TowerView      (resolution tower timeline)
 *   /theorems        → TheoremDashboard (all 10 theorems, expandable)
 *   *                → NotFound       (404 catch-all)
 *
 * All routes are nested under the Layout route (no `path` prop),
 * which renders the persistent Header and Footer chrome on every
 * page. The `<Outlet />` inside Layout receives the matched child
 * route's element.
 *
 * This component does NOT include `<BrowserRouter>` — that is
 * provided by `src/main.tsx` so that App can be rendered inside
 * test harnesses with `<MemoryRouter>` without conflicting routers.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4 (Application Routes)
 *   - Rules §8 (Routing)
 */

import { Routes, Route } from "react-router-dom";

import { Layout } from "./components/layout/Layout";
import { HomePage } from "./components/home/HomePage";
import { PatchList } from "./components/patches/PatchList";
import { PatchView } from "./components/patches/PatchView";
import { TowerView } from "./components/tower/TowerView";
import { TheoremDashboard } from "./components/theorems/TheoremDashboard";
import { NotFound } from "./components/common/NotFound";

/**
 * Application root component — defines the client-side route table.
 *
 * All routes are wrapped in the {@link Layout} shell, which provides
 * the persistent Header (navigation) and Footer (metadata) chrome.
 * The Layout component renders `<Outlet />` for the matched child
 * route's element.
 *
 * Route matching notes:
 *   - The `/` route uses no `index` prop because it is the only
 *     child with `path="/"`. React Router v6 matches this as the
 *     index route of the layout.
 *   - The `/patches/:name` route uses a URL parameter (`:name`)
 *     that PatchView extracts via `useParams<{ name: string }>()`.
 *   - The `*` wildcard catches all unmatched paths and renders
 *     the NotFound component (404 page).
 */
export function App() {
  return (
    <Routes>
      <Route element={<Layout />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/patches" element={<PatchList />} />
        <Route path="/patches/:name" element={<PatchView />} />
        <Route path="/tower" element={<TowerView />} />
        <Route path="/theorems" element={<TheoremDashboard />} />
        <Route path="*" element={<NotFound />} />
      </Route>
    </Routes>
  );
}