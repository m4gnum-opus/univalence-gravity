/// <reference types="vite/client" />

/**
 * Vite client type declarations.
 *
 * This file augments the global `ImportMeta` interface with Vite's
 * `env` property (exposing `VITE_*` environment variables) and
 * other Vite-specific APIs (`import.meta.hot`, `import.meta.glob`).
 *
 * The triple-slash reference directive imports Vite's built-in
 * type declarations from `node_modules/vite/client.d.ts`, which
 * declare:
 *
 *   interface ImportMetaEnv {
 *     readonly VITE_API_URL: string;
 *     // ... other VITE_* variables
 *   }
 *
 *   interface ImportMeta {
 *     readonly env: ImportMetaEnv;
 *     readonly hot: ...;
 *     readonly glob: ...;
 *   }
 *
 * Without this file, TypeScript reports:
 *   "Property 'env' does not exist on type 'ImportMeta'"
 *
 * Reference: https://vitejs.dev/guide/env-and-mode.html#intellisense-for-typescript
 */

/**
 * Augment Vite's ImportMetaEnv with the project's specific
 * environment variables for full IntelliSense support.
 *
 * Only variables prefixed with `VITE_` are exposed to client-side
 * code by Vite's build pipeline. This interface declaration gives
 * TypeScript knowledge of their types.
 */
interface ImportMetaEnv {
  /** Backend API base URL (default: "http://localhost:8080"). */
  readonly VITE_API_URL?: string;
}