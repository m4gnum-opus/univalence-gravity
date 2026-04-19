/**
 * Application entry point — React DOM root + BrowserRouter setup.
 *
 * This file is referenced by `index.html` via:
 *   <script type="module" src="/src/main.tsx"></script>
 *
 * It performs three responsibilities:
 *
 *   1. Imports the global CSS (Tailwind directives + project resets)
 *      so that all utility classes and base styles are available
 *      throughout the component tree.
 *
 *   2. Creates the React 18 concurrent root via `createRoot` and
 *      mounts the application into the `#root` DOM element defined
 *      in `index.html`.
 *
 *   3. Wraps the `<App />` component in `<BrowserRouter>` (providing
 *      client-side routing) and `<StrictMode>` (enabling development-
 *      time checks for deprecated APIs, unsafe lifecycle methods,
 *      and impure render detection via double-invocation).
 *
 * The `<BrowserRouter>` lives here — NOT inside `App.tsx` — so that
 * `App` can be rendered inside `<MemoryRouter>` in test harnesses
 * without conflicting routers.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §7 (Project Structure)
 *   - Rules §8 (Routing)
 *   - Rules §14 (Build and Dev Commands)
 */

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter } from "react-router-dom";

import { App } from "./App";
import "./styles/globals.css";

// ════════════════════════════════════════════════════════════════
//  Mount Point
// ════════════════════════════════════════════════════════════════

/**
 * Locate the mount point defined in index.html:
 *   <div id="root"></div>
 *
 * The non-null assertion is safe here because:
 *   1. index.html always contains <div id="root"></div>
 *   2. The <script> tag importing this module appears AFTER the
 *      #root div in the document, so the element exists by the
 *      time this code executes
 *   3. If somehow missing, createRoot throws a descriptive error
 *      ("Target container is not a DOM element") which is more
 *      actionable than a silent null
 *
 * We use getElementById + a runtime guard rather than a bare `!`
 * assertion to satisfy the project's strict TypeScript configuration
 * (noUncheckedIndexedAccess) and provide a clear error message.
 */
const rootElement = document.getElementById("root");

if (!rootElement) {
  throw new Error(
    "Fatal: Could not find #root element in the document. " +
    "Ensure index.html contains <div id=\"root\"></div> before " +
    "the <script> tag that loads this module."
  );
}

// ════════════════════════════════════════════════════════════════
//  React Root
// ════════════════════════════════════════════════════════════════

/**
 * Create the React 18 concurrent root and render the application.
 *
 * Component hierarchy at the root:
 *
 *   <StrictMode>              — Dev-time checks (double render, etc.)
 *     <BrowserRouter>         — HTML5 History API routing
 *       <App />               — Route table (Routes + Layout shell)
 *     </BrowserRouter>
 *   </StrictMode>
 *
 * StrictMode is a development-only wrapper that:
 *   - Double-invokes render functions and effects to surface impure
 *     computations (helps catch bugs in the data-fetching hooks)
 *   - Warns about deprecated React APIs
 *   - Has zero production overhead (stripped by the build)
 *
 * BrowserRouter uses the HTML5 History API (pushState / popState)
 * for clean URLs without hash fragments. This requires the
 * production static file server to be configured with a fallback
 * to index.html for all routes (standard SPA deployment pattern).
 */
createRoot(rootElement).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
);