/**
 * Color mode radio buttons and visibility toggles for the Patch Viewer.
 *
 * This component renders the left-hand control panel of the 3-panel
 * Patch Viewer layout (frontend-spec §5.3). It provides:
 *
 *   1. **Color mode selection** — four radio buttons controlling how
 *      cells are colored in the 3D viewport:
 *        - Min-Cut value (default): Viridis sequential
 *        - Region size: green→purple sequential
 *        - S/area ratio: blue→white→red diverging at 0.5
 *        - Curvature: blue→white→red diverging at 0
 *
 *   2. **Visibility toggles** — checkboxes controlling which
 *      structural overlays are shown in the 3D viewport:
 *        - Internal bonds (translucent gray cylinders)
 *        - Boundary wireframe (exposed boundary faces)
 *        - Boundary shell (semi-transparent convex hull around
 *          boundary cells — Phase 2, item 16)
 *
 * All state is controlled by the parent component (PatchView);
 * this component is a pure presentational shell that calls the
 * provided callbacks on user interaction.
 *
 * The curvature color mode is disabled when the patch has no
 * curvature data (patchCurvature === null), preventing the user
 * from selecting a mode that would produce no meaningful coloring.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §5.3 (Patch Viewer layout)
 *   - docs/engineering/frontend-spec-webgl.md §5.3.3 (Color Scales)
 *   - src/types/index.ts (ColorMode type)
 */

import type { ColorMode } from "../../types";

// ════════════════════════════════════════════════════════════════
//  Color mode descriptors
// ════════════════════════════════════════════════════════════════

/**
 * Metadata for each color mode option. Defines the radio button
 * label and a brief description shown as secondary text.
 */
interface ColorModeOption {
  /** The ColorMode enum value */
  value: ColorMode;
  /** Human-readable label for the radio button */
  label: string;
  /** Brief description of the color scale */
  description: string;
}

/**
 * All available color modes in display order.
 *
 * The order follows the spec (frontend-spec §5.3.3):
 *   1. Min-Cut value (default)
 *   2. Region size
 *   3. S/area ratio
 *   4. Curvature
 */
const COLOR_MODE_OPTIONS: readonly ColorModeOption[] = [
  {
    value: "mincut",
    label: "Min-Cut value",
    description: "Sequential Viridis — higher S = warmer color",
  },
  {
    value: "regionSize",
    label: "Region size",
    description: "Sequential green → purple by cell count",
  },
  {
    value: "ratio",
    label: "S / area ratio",
    description: "Diverging at 0.5 — the Bekenstein–Hawking bound",
  },
  {
    value: "curvature",
    label: "Curvature",
    description: "Diverging — negative (blue) to positive (red)",
  },
] as const;

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

/** Props for the {@link ColorControls} component. */
export interface ColorControlsProps {
  /** The currently active color mode. */
  colorMode: ColorMode;
  /** Callback invoked when the user selects a different color mode. */
  onColorModeChange: (mode: ColorMode) => void;

  /** Whether internal bond connectors are visible. */
  showBonds: boolean;
  /** Callback invoked when the user toggles bond visibility. */
  onShowBondsChange: (show: boolean) => void;

  /** Whether the boundary wireframe overlay is visible. */
  showBoundary: boolean;
  /** Callback invoked when the user toggles boundary visibility. */
  onShowBoundaryChange: (show: boolean) => void;

  /**
   * Whether the semi-transparent boundary shell (convex hull or
   * fitted sphere around boundary cell positions) is visible.
   *
   * The shell visualizes the holographic boundary surface — "the
   * 2D boundary encodes the 3D bulk."  Toggled via the "Boundary
   * shell" checkbox alongside the existing bonds and wireframe
   * toggles.
   *
   * Phase 2, item 16 of the concrete fix plan.
   */
  showShell: boolean;
  /** Callback invoked when the user toggles boundary shell visibility. */
  onShowShellChange: (show: boolean) => void;

  /**
   * Whether the patch has curvature data. When `false`, the
   * curvature color mode radio button is disabled with a tooltip
   * explaining why.
   */
  hasCurvature: boolean;
}

// ════════════════════════════════════════════════════════════════
//  Component
// ════════════════════════════════════════════════════════════════

/**
 * Color mode radio buttons and visibility toggles for the Patch Viewer.
 *
 * Renders as a compact sidebar panel with two sections: "Color by"
 * (radio group) and "Show" (checkbox group). Uses Tailwind utilities
 * for styling. All interactive elements have ARIA labels for
 * accessibility (frontend-spec §10).
 */
export function ColorControls({
  colorMode,
  onColorModeChange,
  showBonds,
  onShowBondsChange,
  showBoundary,
  onShowBoundaryChange,
  showShell,
  onShowShellChange,
  hasCurvature,
}: ColorControlsProps) {
  return (
    <div className="space-y-5">
      {/* ── Color mode radio group ────────────────────────────── */}
      <fieldset>
        <legend className="font-serif text-sm font-semibold text-gray-700 mb-2">
          Color by
        </legend>
        <div
          className="space-y-1.5"
          role="radiogroup"
          aria-label="Cell color mode"
        >
          {COLOR_MODE_OPTIONS.map((option) => {
            const isDisabled = option.value === "curvature" && !hasCurvature;
            const isSelected = colorMode === option.value;
            const inputId = `color-mode-${option.value}`;

            return (
              <label
                key={option.value}
                htmlFor={inputId}
                className={`
                  flex items-start gap-2.5 rounded-md px-2.5 py-1.5
                  transition-colors duration-150
                  ${isDisabled
                    ? "cursor-not-allowed opacity-50"
                    : "cursor-pointer hover:bg-gray-100"
                  }
                  ${isSelected && !isDisabled ? "bg-viridis-50" : ""}
                `}
                title={
                  isDisabled
                    ? "No curvature data available for this patch"
                    : option.description
                }
              >
                <input
                  type="radio"
                  id={inputId}
                  name="colorMode"
                  value={option.value}
                  checked={isSelected}
                  disabled={isDisabled}
                  onChange={() => {
                    onColorModeChange(option.value);
                  }}
                  className="mt-0.5 h-4 w-4 text-viridis-600 focus:ring-viridis-500 border-gray-300"
                  aria-label={`Color cells by ${option.label}`}
                />
                <div className="min-w-0">
                  <span className="block text-sm font-medium text-gray-800 leading-tight">
                    {option.label}
                  </span>
                  <span className="block text-xs text-gray-500 leading-snug mt-0.5">
                    {option.description}
                  </span>
                </div>
              </label>
            );
          })}
        </div>
      </fieldset>

      {/* ── Divider ───────────────────────────────────────────── */}
      <hr className="border-gray-200" />

      {/* ── Visibility toggle checkboxes ──────────────────────── */}
      <fieldset>
        <legend className="font-serif text-sm font-semibold text-gray-700 mb-2">
          Show
        </legend>
        <div className="space-y-1.5">
          {/* Internal bonds toggle */}
          <label
            htmlFor="toggle-bonds"
            className="flex items-center gap-2.5 cursor-pointer rounded-md px-2.5 py-1.5 hover:bg-gray-100 transition-colors duration-150"
          >
            <input
              type="checkbox"
              id="toggle-bonds"
              checked={showBonds}
              onChange={(e) => {
                onShowBondsChange(e.target.checked);
              }}
              className="h-4 w-4 rounded text-viridis-600 focus:ring-viridis-500 border-gray-300"
              aria-label="Toggle internal bond connectors"
            />
            <span className="text-sm text-gray-800">Internal bonds</span>
          </label>

          {/* Boundary wireframe toggle */}
          <label
            htmlFor="toggle-boundary"
            className="flex items-center gap-2.5 cursor-pointer rounded-md px-2.5 py-1.5 hover:bg-gray-100 transition-colors duration-150"
          >
            <input
              type="checkbox"
              id="toggle-boundary"
              checked={showBoundary}
              onChange={(e) => {
                onShowBoundaryChange(e.target.checked);
              }}
              className="h-4 w-4 rounded text-viridis-600 focus:ring-viridis-500 border-gray-300"
              aria-label="Toggle boundary wireframe overlay"
            />
            <span className="text-sm text-gray-800">Boundary wireframe</span>
          </label>

          {/* Boundary shell toggle */}
          <label
            htmlFor="toggle-shell"
            className="flex items-center gap-2.5 cursor-pointer rounded-md px-2.5 py-1.5 hover:bg-gray-100 transition-colors duration-150"
          >
            <input
              type="checkbox"
              id="toggle-shell"
              checked={showShell}
              onChange={(e) => {
                onShowShellChange(e.target.checked);
              }}
              className="h-4 w-4 rounded text-viridis-600 focus:ring-viridis-500 border-gray-300"
              aria-label="Toggle boundary shell overlay"
            />
            <span className="text-sm text-gray-800">Boundary shell</span>
          </label>
        </div>
      </fieldset>
    </div>
  );
}