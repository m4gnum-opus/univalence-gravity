/**
 * Global test setup for Vitest.
 *
 * Registered via `setupFiles: ["./tests/setup.ts"]` in vite.config.ts.
 * This file runs once before each test file, making its side-effects
 * (extended matchers, global mocks, etc.) available to every test
 * without per-file imports.
 *
 * Currently provides:
 *   - @testing-library/jest-dom matchers (toBeInTheDocument,
 *     toHaveAttribute, toHaveTextContent, toContainElement, etc.)
 *     extended onto Vitest's `expect`.
 *
 * Reference:
 *   - https://github.com/testing-library/jest-dom#with-vitest
 *   - docs/engineering/frontend-spec-webgl.md §11 (Testing)
 */

import "@testing-library/jest-dom/vitest";