/**
 * Error display component used across all pages.
 *
 * Renders a visually distinct but academically restrained error
 * message with an optional retry action. Designed to be composed
 * inside any page or panel that surfaces fetch errors from the
 * data hooks (usePatch, usePatches, useTower, useTheorems, etc.).
 *
 * Accessibility:
 *   - Uses `role="alert"` so screen readers announce the error
 *     immediately when it appears in the DOM.
 *   - The retry button (when present) is keyboard-focusable and
 *     has a descriptive aria-label.
 *
 * Reference:
 *   - docs/engineering/frontend-spec-webgl.md §4.1 (Academic credibility)
 *   - docs/engineering/frontend-spec-webgl.md §10 (Accessibility)
 */

/** Props for the {@link ErrorMessage} component. */
interface ErrorMessageProps {
  /** The human-readable error message to display. */
  message: string;
  /**
   * Optional callback invoked when the user clicks the "Retry"
   * button. When omitted, no retry button is rendered.
   */
  onRetry?: () => void;
  /**
   * Optional title displayed above the error message.
   * Defaults to "Error" when not provided.
   */
  title?: string;
}

/**
 * Stateless error message component with optional retry action.
 *
 * @example
 * ```tsx
 * // Basic usage (no retry)
 * <ErrorMessage message="Failed to fetch patch data" />
 *
 * // With retry action
 * <ErrorMessage
 *   message={error}
 *   onRetry={() => window.location.reload()}
 * />
 *
 * // With custom title
 * <ErrorMessage
 *   title="Patch Not Found"
 *   message="The requested patch does not exist."
 * />
 * ```
 */
export function ErrorMessage({
  message,
  onRetry,
  title = "Error",
}: ErrorMessageProps) {
  return (
    <div
      role="alert"
      className="mx-auto my-8 max-w-lg rounded-md border border-red-200 bg-red-50 p-6"
    >
      {/* Title */}
      <h2 className="mb-2 font-serif text-lg font-semibold text-red-800">
        {title}
      </h2>

      {/* Error message — monospace for technical messages (API errors,
          stack traces) to maintain the academic/engineering aesthetic. */}
      <p className="font-mono text-sm leading-relaxed text-red-700">
        {message}
      </p>

      {/* Retry button — only rendered when an onRetry handler is provided. */}
      {onRetry != null && (
        <button
          type="button"
          onClick={onRetry}
          aria-label="Retry the failed operation"
          className={
            "mt-4 rounded border border-red-300 bg-white px-4 py-2 "
            + "text-sm font-medium text-red-700 "
            + "transition-colors duration-150 "
            + "hover:bg-red-100 focus:outline-none focus:ring-2 focus:ring-red-400 focus:ring-offset-2"
          }
        >
          Retry
        </button>
      )}
    </div>
  );
}