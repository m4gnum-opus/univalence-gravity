/** @type {import('tailwindcss').Config} */
export default {
  // ── Content Paths ──────────────────────────────────────────────
  //
  //  Tailwind scans these files for utility class names during the
  //  purge step.  Every .tsx component, .ts utility, and the root
  //  HTML entry point must be included to avoid stripping used
  //  classes from the production build.
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],

  theme: {
    extend: {
      // ── Typography ───────────────────────────────────────────
      //
      //  Academic credibility principle (frontend-spec §4.1):
      //
      //  - font-serif:  Headings — Georgia stack for a paper-like
      //    feel on all platforms.
      //  - font-sans:   Body text — Tailwind's default Inter /
      //    system-ui stack.  We don't override it; extending with
      //    an explicit list ensures "Inter" is first when installed
      //    (common on developer machines) without breaking the
      //    system fallback chain.
      //  - font-mono:   Agda type signatures and module paths —
      //    "JetBrains Mono" and "Fira Code" are the most legible
      //    programming fonts; the stack falls back to the system
      //    monospace font on machines without either.
      fontFamily: {
        serif: [
          "Georgia",
          "Cambria",
          "\"Times New Roman\"",
          "Times",
          "serif",
        ],
        mono: [
          "\"JetBrains Mono\"",
          "\"Fira Code\"",
          "\"Cascadia Code\"",
          "Menlo",
          "Consolas",
          "\"Liberation Mono\"",
          "\"Courier New\"",
          "monospace",
        ],
      },

      // ── Colors ───────────────────────────────────────────────
      //
      //  Muted, professional palette anchored on the Viridis
      //  colormap endpoints.  The full continuous Viridis scale
      //  for data visualization lives in src/utils/colors.ts;
      //  these are discrete semantic tokens for UI chrome.
      //
      //  Viridis reference points (from matplotlib):
      //    0.0 → #440154 (deep purple)
      //    0.25 → #31688e (teal-blue)
      //    0.5 → #35b779 (green)
      //    0.75 → #fde725 (yellow)
      //    1.0 → #fde725 (same yellow at the top)
      //
      //  Theorem status colors (frontend-spec §5.5):
      //    Verified  → green badge
      //    Dead      → gray badge
      //    Numerical → orange badge
      colors: {
        // Viridis-inspired semantic tokens for general UI.
        // These are NOT the full data colormap — just anchor
        // colors for backgrounds, borders, and accents.
        viridis: {
          50:  "#f3f0ff",
          100: "#e0d4f7",
          200: "#b794d6",
          300: "#7e57a0",
          400: "#553772",
          500: "#440154",  // Viridis 0.0 — deep purple (brand)
          600: "#31688e",  // Viridis ~0.25 — teal-blue
          700: "#21918c",  // Viridis ~0.4 — teal
          800: "#35b779",  // Viridis ~0.5 — green
          900: "#90d743",  // Viridis ~0.75 — yellow-green
          950: "#fde725",  // Viridis 1.0 — bright yellow
        },

        // Theorem status badge colors.
        status: {
          verified:  "#16a34a",  // green-600 — machine-checked ✓
          dead:      "#9ca3af",  // gray-400  — superseded / dead code
          numerical: "#ea580c",  // orange-600 — Python oracle only
        },

        // Selection / interaction highlight.
        // Used for emissive glow on selected cells in the 3D
        // viewport (frontend-spec §4.3: orange, intensity 0.5).
        selection: "#ffaa00",
      },

      // ── Spacing & Layout ─────────────────────────────────────
      //
      //  Tailwind's default breakpoints already match the spec:
      //    md: 768px   (tablet lower bound)
      //    xl: 1280px  (desktop lower bound)
      //
      //  No custom breakpoints needed.  We add a few utility
      //  max-width values for the content container widths
      //  specified in the responsive layout table.
      maxWidth: {
        "8xl": "88rem",  // 1408px — generous content max-width
      },

      // ── Opacity ──────────────────────────────────────────────
      //
      //  Bond connectors use 0.3 opacity; unselected cells use
      //  0.85 (frontend-spec §6.2).
      opacity: {
        "30": "0.30",
        "85": "0.85",
      },

      // ── Animation ────────────────────────────────────────────
      //
      //  A subtle pulse for loading states.  Respects
      //  prefers-reduced-motion via Tailwind's built-in
      //  motion-reduce: variant (frontend-spec §10).
      animation: {
        "pulse-slow": "pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite",
      },
    },
  },

  plugins: [],
};