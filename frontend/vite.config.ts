/// <reference types="vitest" />

import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig({
  // ── Plugins ────────────────────────────────────────────────────
  plugins: [react()],

  // ── Path Resolution ────────────────────────────────────────────
  //
  //  Absolute imports from `src/` are resolved via the `@/` alias,
  //  e.g. `import { Patch } from "@/types"`.  This keeps imports
  //  clean across deeply nested component directories without
  //  fragile relative paths like `../../../types/index`.
  resolve: {
    alias: {
      "@": resolve(__dirname, "src"),
    },
  },

  // ── Development Server ─────────────────────────────────────────
  //
  //  The dev server runs at localhost:5173 (Vite default).
  server: {
    port: 5173,
  },

  // ── Production Build ───────────────────────────────────────────
  //
  //  Output to `frontend/dist/`.  The build produces static
  //  HTML/JS/CSS suitable for any static file server (nginx,
  //  Caddy, Netlify, Vercel, GitHub Pages).
  build: {
    outDir: "dist",
    sourcemap: true,
  },

  // ── Vitest Configuration ───────────────────────────────────────
  //
  //  Vitest is configured inline (rather than in a separate
  //  `vitest.config.ts`) because it shares the same Vite plugin
  //  pipeline and path aliases.  The `/// <reference types="vitest" />`
  //  triple-slash directive at the top of this file provides the
  //  `test` property type on the config object.
  //
  //  - environment: jsdom — provides a browser-like DOM for React
  //    Testing Library component tests and hook tests.
  //  - globals: true — exposes `describe`, `it`, `expect`, `vi`
  //    globally without explicit imports in every test file.
  //  - setupFiles: none required at this stage; add
  //    `tests/setup.ts` later if global test setup is needed
  //    (e.g. MSW server start/stop, custom matchers).
  //  - include: matches `tests/**/*.test.{ts,tsx}` — all test
  //    files live under the `tests/` directory (not co-located
  //    with source).
  //  - css: false — skip CSS processing in tests for speed.
  //    Components under test receive no styles, which is correct
  //    for logic/rendering tests (Tailwind utility classes are
  //    not relevant to component behavior).
  test: {
    environment: "jsdom",
    globals: true,
    include: ["tests/**/*.test.{ts,tsx}"],
    css: false,
    setupFiles: ["./tests/setup.ts"],
  },
});