import js from "@eslint/js";
import globals from "globals";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import tseslint from "typescript-eslint";

export default tseslint.config(
  // ── Global ignores ───────────────────────────────────────────
  //
  //  Exclude build output, dependency cache, and Vite internals
  //  from linting.  These paths are not source code and would
  //  either fail to parse or produce irrelevant warnings.
  { ignores: ["dist", "node_modules", "*.config.js", "*.config.ts"] },

  // ── Base: ESLint recommended rules ───────────────────────────
  //
  //  The standard set of JavaScript best-practice rules.  These
  //  are overridden / extended by the TypeScript-aware rules below
  //  where the TS compiler provides stricter guarantees (e.g.
  //  no-unused-vars is replaced by @typescript-eslint/no-unused-vars).
  js.configs.recommended,

  // ── TypeScript: strict type-checked rules ────────────────────
  //
  //  typescript-eslint's "strict" preset enables rules that ban
  //  unsafe `any` usage, enforce explicit return types on exported
  //  functions, and catch common TS pitfalls.  This aligns with
  //  the project rule: "No `any` types — if a type is unclear,
  //  define it explicitly."
  //
  //  The "stylistic" preset adds consistent formatting preferences
  //  for TypeScript-specific syntax (type assertions, interface vs
  //  type, etc.).
  ...tseslint.configs.strict,
  ...tseslint.configs.stylistic,

  // ── Source files: React + TypeScript ──────────────────────────
  {
    files: ["src/**/*.{ts,tsx}", "tests/**/*.{ts,tsx}"],

    plugins: {
      "react-hooks": reactHooks,
      "react-refresh": reactRefresh,
    },

    languageOptions: {
      ecmaVersion: 2022,
      globals: {
        ...globals.browser,
      },
    },

    rules: {
      // ── React Hooks ──────────────────────────────────────────
      //
      //  Enforce the Rules of Hooks (no conditional hook calls,
      //  correct dependency arrays).  These are critical for the
      //  custom data-fetching hooks (usePatch, usePatches, etc.).
      ...reactHooks.configs.recommended.rules,

      // ── React Refresh ────────────────────────────────────────
      //
      //  Warn when a module exports something that would break
      //  Vite's Fast Refresh (HMR).  Named exports from component
      //  files are allowed (the project convention — Rule §12:
      //  "Named exports, not default exports, for all components").
      "react-refresh/only-export-components": [
        "warn",
        { allowConstantExport: true },
      ],

      // ── TypeScript strictness ────────────────────────────────
      //
      //  Ban explicit `any`.  The project rules (§12) state:
      //  "No `any` types — if a type is unclear, define it
      //  explicitly."  This rule enforces that at lint time,
      //  complementing tsconfig's `strict: true`.
      "@typescript-eslint/no-explicit-any": "error",

      //  Allow unused variables when prefixed with underscore.
      //  This is the standard convention for intentionally unused
      //  parameters (e.g. `_event` in click handlers, `_index` in
      //  map callbacks).  Matches tsconfig's noUnusedLocals /
      //  noUnusedParameters behavior.
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],

      // ── General quality ──────────────────────────────────────
      //
      //  Prefer `const` over `let` when the variable is never
      //  reassigned.  All API response data is read-only; this
      //  rule reinforces that discipline at the variable level.
      "prefer-const": "error",

      //  Ban `console.log` in production code (warn, not error,
      //  so it doesn't block development).  console.error and
      //  console.warn are allowed for genuine error reporting.
      "no-console": ["warn", { allow: ["warn", "error"] }],

      // ── Relaxations for practical React/Three.js patterns ────
      //
      //  Allow empty interfaces — used for component prop types
      //  that intentionally take no props (e.g. `interface
      //  LoadingProps {}`).  The strict preset bans these by
      //  default but they are idiomatic in React.
      "@typescript-eslint/no-empty-interface": "off",

      //  Allow non-null assertions (the `!` postfix operator).
      //  Three.js refs and useRef<T>() often require `ref.current!`
      //  when the ref is guaranteed to be populated after mount.
      //  Prefer explicit null checks where possible, but don't
      //  block legitimate Three.js patterns.
      "@typescript-eslint/no-non-null-assertion": "warn",
    },
  },

  // ── Test files: relaxed rules ────────────────────────────────
  //
  //  Test files use Vitest globals (describe, it, expect, vi)
  //  and frequently create mock objects with partial shapes.
  //  Relax rules that would create unnecessary friction in tests.
  {
    files: ["tests/**/*.{ts,tsx}"],
    rules: {
      //  Tests frequently use `as` casts for mock data that
      //  intentionally omits optional fields.
      "@typescript-eslint/consistent-type-assertions": "off",

      //  Test mock factories may use empty functions as stubs.
      "@typescript-eslint/no-empty-function": "off",

      //  Console output in tests is fine for debugging.
      "no-console": "off",
    },
  },
);