/**
 * Loading indicator displayed while data is being fetched from
 * the Haskell backend.
 *
 * Renders a subtle animated spinner with an optional descriptive
 * message. Designed for academic credibility — minimal, muted,
 * and unobtrusive.
 *
 * Accessibility:
 *   - Uses `role="status"` so screen readers announce the loading
 *     state without requiring a live region.
 *   - Includes a visually-hidden text fallback ("Loading…") for
 *     screen readers when no explicit message is provided.
 *   - Respects `prefers-reduced-motion` via Tailwind's
 *     `motion-reduce:` variant — the spinner animation is
 *     replaced with a static opacity pulse when the user has
 *     requested reduced motion.
 *
 * @example
 * ```tsx
 * // Default: spinner + "Loading…"
 * <Loading />
 *
 * // Custom message
 * <Loading message="Fetching patch data…" />
 * ```
 */

/** Props for the {@link Loading} component. */
interface LoadingProps {
  /**
   * Optional message displayed below the spinner.
   * When omitted, a screen-reader-only "Loading…" text is rendered.
   */
  message?: string;
}

/**
 * A full-width centered loading indicator with an animated spinner.
 *
 * Used across all pages whenever a data hook is in its `loading`
 * state. Zero internal dependencies — safe to import from any
 * component in the tree.
 */
export function Loading({ message }: LoadingProps) {
  return (
    <div
      role="status"
      aria-label={message ?? "Loading"}
      className="flex flex-col items-center justify-center gap-4 py-16"
    >
      {/* Spinner ring
       *
       * A 32×32px ring with a colored arc that rotates continuously.
       * On `prefers-reduced-motion`, the spin animation is removed
       * and replaced with a gentle opacity pulse so the user still
       * sees a "something is happening" indicator without rotational
       * motion.
       *
       * The border colors use the Viridis brand purple (viridis-500)
       * for the visible arc and a light gray for the track.
       */}
      <div
        className={[
          "h-8 w-8 rounded-full",
          "border-4 border-gray-200 border-t-viridis-500",
          "animate-spin",
          "motion-reduce:animate-pulse-slow motion-reduce:border-t-viridis-400",
        ].join(" ")}
        aria-hidden="true"
      />

      {/* Message text or screen-reader fallback */}
      {message ? (
        <p className="text-sm text-gray-500 font-serif">{message}</p>
      ) : (
        <span className="sr-only">Loading…</span>
      )}
    </div>
  );
}