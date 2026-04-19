/**
 * Home page — project overview with theorem status cards.
 *
 * The landing page communicates what the project proves and provides
 * navigation CTAs into the three main feature pages. It displays:
 *
 *   - Project title, subtitle, and version
 *   - A responsive grid of the 7 core theorem status cards
 *   - Navigation CTAs to /patches, /tower, and /theorems
 *   - A brief project overview (what is proven, what is not)
 *   - The data pipeline diagram
 *   - Metadata footer (Agda version, data hash, build date)
 *
 * Data sources:
 *   - GET /meta     → version, Agda version, build date, data hash
 *   - GET /theorems → all 10 theorems (filtered to 7 core for the grid)
 *
 * Interactions:
 *   - Click a theorem card → navigate to /theorems (handled by TheoremCard's
 *     own <Link>, which passes state={{ highlightTheorem }} for auto-expand)
 *   - Click "Explore Patches" → navigate to /patches
 *   - Click "View Resolution Tower" → navigate to /tower
 *
 * Fixes applied (review issues #1, #9):
 *   - #1: Removed outer <Link> wrapper around TheoremCard. TheoremCard is
 *     itself a <Link to="/theorems" state={{ highlightTheorem }}>, so wrapping
 *     it in another <Link> produced invalid nested <a> elements and lost the
 *     highlightTheorem navigation state.
 *   - #9: Wired onRetry to ErrorMessage, combining refetch from both useMeta
 *     and useTheorems so the user can retry failed requests without a full
 *     page reload.
 *
 * Reference: docs/engineering/frontend-spec-webgl.md §5.1
 */

import { useCallback } from "react";
import { Link } from "react-router-dom";

import { Loading } from "../common/Loading";
import { ErrorMessage } from "../common/ErrorMessage";
import { TheoremCard } from "./TheoremCard";
import { useMeta } from "../../hooks/useMeta";
import { useTheorems } from "../../hooks/useTheorems";

/**
 * The 7 core theorems displayed prominently on the home page grid.
 *
 * These correspond to the primary machine-checked results from
 * docs/formal/01-theorems.md (Theorems 1–7). The remaining 3
 * (Theorems 8–10: subadditivity, step invariance, enriched step
 * invariance) are structural properties shown on the full
 * /theorems dashboard but omitted from the landing page to avoid
 * overwhelming the visitor.
 */
const CORE_THEOREM_NUMBERS: ReadonlySet<number> = new Set([1, 2, 3, 4, 5, 6, 7]);

/**
 * Landing page component for the Univalence Gravity frontend.
 *
 * Fetches metadata and theorem data on mount, renders loading/error
 * states, then displays the full landing page layout with theorem
 * cards, navigation CTAs, and project overview.
 */
export function HomePage() {
  const {
    data: meta,
    loading: metaLoading,
    error: metaError,
    refetch: metaRefetch,
  } = useMeta();
  const {
    data: theorems,
    loading: theoremsLoading,
    error: theoremsError,
    refetch: theoremsRefetch,
  } = useTheorems();

  const loading = metaLoading || theoremsLoading;
  const error = metaError ?? theoremsError;

  /**
   * Combined refetch callback that re-triggers both the meta and
   * theorems fetches. Wired to the ErrorMessage's onRetry prop so
   * the user can retry failed requests without a full page reload.
   *
   * Both refetch calls are fired unconditionally — even if only one
   * endpoint failed, re-fetching both is cheap (the backend sets
   * Cache-Control: max-age=86400, immutable on these endpoints) and
   * avoids the complexity of tracking which specific fetch failed.
   */
  const handleRetry = useCallback(() => {
    metaRefetch();
    theoremsRefetch();
  }, [metaRefetch, theoremsRefetch]);

  if (loading) {
    return <Loading />;
  }

  if (error) {
    return <ErrorMessage message={error} onRetry={handleRetry} />;
  }

  // Filter to the 7 core theorems for the landing page grid.
  // Preserve the original order (by thmNumber) from the API.
  const coreTheorems =
    theorems?.filter((t) => CORE_THEOREM_NUMBERS.has(t.thmNumber)) ?? [];

  return (
    <div className="max-w-5xl mx-auto px-4 py-8 sm:py-12">
      {/* ── Hero Section ─────────────────────────────────────── */}
      <header className="text-center mb-12">
        <h1 className="font-serif text-3xl sm:text-4xl lg:text-5xl font-bold text-gray-900 mb-3">
          Univalence Gravity
        </h1>
        <p className="font-serif text-lg sm:text-xl text-viridis-600 mb-2">
          The Spacetime Compiler
          {meta ? (
            <span className="text-gray-400 text-base ml-2">v{meta.version}</span>
          ) : null}
        </p>
        <p className="text-gray-600 max-w-2xl mx-auto text-sm sm:text-base leading-relaxed">
          A constructive formalization of discrete entanglement-geometry
          duality in Cubical Agda. Every result below is machine-checked
          by the Agda type-checker — no axioms postulated, all transport
          computes.
        </p>
      </header>

      {/* ── Theorem Card Grid ────────────────────────────────── */}
      {/*
       * Fix for review issue #1 (nested <Link>):
       *
       * TheoremCard is itself a <Link to="/theorems" state={{ highlightTheorem }}>
       * so we must NOT wrap it in another <Link>. The previous code wrapped
       * each TheoremCard in an outer <Link to="/theorems">, producing invalid
       * nested <a> elements and losing the highlightTheorem navigation state
       * (since the outer Link didn't pass it).
       *
       * Now each TheoremCard renders directly in the grid. TheoremCard's own
       * <Link> handles navigation, focus ring, hover transitions, and the
       * state={{ highlightTheorem }} payload consumed by TheoremDashboard.
       */}
      <section className="mb-12" aria-label="Core verified theorems">
        <h2 className="font-serif text-xl sm:text-2xl font-semibold text-gray-800 mb-6 text-center">
          Machine-Checked Results
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {coreTheorems.map((theorem) => (
            <TheoremCard key={theorem.thmNumber} theorem={theorem} />
          ))}
        </div>

        <p className="text-center text-sm text-gray-500 mt-4">
          Click any card to see full details, type signatures, and proof
          methods →
        </p>
      </section>

      {/* ── Navigation CTAs ──────────────────────────────────── */}
      <section className="mb-12" aria-label="Explore the project">
        <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            to="/patches"
            className="inline-flex items-center gap-2 px-6 py-3 bg-viridis-500 text-white font-medium rounded-lg hover:bg-viridis-400 transition-colors focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2"
          >
            Explore Patches
            <span aria-hidden="true">→</span>
          </Link>
          <Link
            to="/tower"
            className="inline-flex items-center gap-2 px-6 py-3 border-2 border-viridis-600 text-viridis-600 font-medium rounded-lg hover:bg-viridis-50 transition-colors focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2"
          >
            View Resolution Tower
            <span aria-hidden="true">→</span>
          </Link>
          <Link
            to="/theorems"
            className="inline-flex items-center gap-2 px-6 py-3 border-2 border-gray-300 text-gray-700 font-medium rounded-lg hover:bg-gray-50 transition-colors focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2"
          >
            All 10 Theorems
            <span aria-hidden="true">→</span>
          </Link>
        </div>
      </section>

      {/* ── Project Overview ─────────────────────────────────── */}
      <section className="mb-12 max-w-3xl mx-auto" aria-label="Project overview">
        <h2 className="font-serif text-xl font-semibold text-gray-800 mb-4">
          What This Proves
        </h2>
        <div className="text-sm sm:text-base text-gray-600 space-y-3 leading-relaxed">
          <p>
            This project machine-checks that five pillars of a holographic
            universe — <em>geometry</em>, <em>causality</em>,{" "}
            <em>gauge matter</em>, <em>curvature</em>, and{" "}
            <em>quantum superposition</em> — coexist in a single formal
            artifact, connected by computational transport along Univalence
            paths.
          </p>
          <p>
            The central result: boundary entanglement entropy{" "}
            <em>exactly</em> equals bulk minimal surface area (the discrete
            Ryu–Takayanagi correspondence) on every boundary region, for any
            patch satisfying an abstract{" "}
            <span className="font-mono text-xs bg-gray-100 px-1.5 py-0.5 rounded">
              PatchData
            </span>{" "}
            interface. The proof is generic — written once, instantiated on
            12 patches spanning 1D trees, 2D pentagonal tilings, and 3D
            cubic honeycombs.
          </p>
          <p>
            The sharp bound{" "}
            <span className="font-mono text-xs bg-gray-100 px-1.5 py-0.5 rounded">
              S(A) ≤ area(A)/2
            </span>{" "}
            identifies the discrete Newton&apos;s constant as{" "}
            <span className="font-mono text-xs bg-gray-100 px-1.5 py-0.5 rounded">
              1/(4G) = 1/2
            </span>{" "}
            in bond-dimension-1 units — an exact rational verified by{" "}
            <span className="font-mono text-xs bg-gray-100 px-1.5 py-0.5 rounded">
              refl
            </span>
            , eliminating the constructive-reals obstacle for the
            entropy-area relationship.
          </p>
        </div>
      </section>

      {/* ── Data Pipeline ────────────────────────────────────── */}
      <section
        className="mb-12 max-w-3xl mx-auto"
        aria-label="Data pipeline architecture"
      >
        <h2 className="font-serif text-xl font-semibold text-gray-800 mb-4">
          The Data Pipeline
        </h2>
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 font-mono text-xs sm:text-sm text-gray-700 overflow-x-auto">
          <div className="space-y-1 whitespace-nowrap">
            <div>
              <span className="text-viridis-700 font-semibold">Agda</span>
              <span className="text-gray-400">
                {"    "}(src/){"         "}
              </span>
              <span className="text-gray-500">→ type-checks theorems</span>
              <span className="text-gray-400 ml-6">VERIFICATION</span>
            </div>
            <div>
              <span className="text-viridis-700 font-semibold">Python</span>
              <span className="text-gray-400">
                {"  "}(sim/){"         "}
              </span>
              <span className="text-gray-500">→ computes patches, emits JSON</span>
              <span className="text-gray-400 ml-6">COMPUTATION</span>
            </div>
            <div>
              <span className="text-viridis-700 font-semibold">Haskell</span>
              <span className="text-gray-400">
                {" "}(backend/){"     "}
              </span>
              <span className="text-gray-500">→ serves JSON via REST API</span>
              <span className="text-gray-400 ml-6">SERVING</span>
            </div>
            <div>
              <span className="text-selection font-semibold">Browser</span>
              <span className="text-gray-400">
                {" "}(frontend/){"    "}
              </span>
              <span className="text-gray-500">→ renders interactive 3D views</span>
              <span className="text-gray-400 ml-6">
                VISUALIZATION ← You are here
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* ── Honest Limitations ───────────────────────────────── */}
      <section
        className="mb-12 max-w-3xl mx-auto"
        aria-label="Limitations"
      >
        <h2 className="font-serif text-xl font-semibold text-gray-800 mb-4">
          What This Does <em>Not</em> Prove
        </h2>
        <ul className="text-sm text-gray-500 space-y-1.5 list-disc list-inside">
          <li>That discrete structures converge to smooth geometry as N → ∞</li>
          <li>That finite gauge groups relate to continuous Lie groups</li>
          <li>That the causal poset approximates a Lorentzian metric</li>
          <li>
            That &ldquo;transport along a Univalence path&rdquo; has physical
            meaning
          </li>
        </ul>
      </section>

      {/* ── Metadata Footer ──────────────────────────────────── */}
      {meta ? (
        <footer className="text-center text-xs text-gray-400 border-t border-gray-200 pt-6">
          <p>
            Built with{" "}
            <span className="font-mono">Agda {meta.agdaVersion}</span>
            {" • "}
            <span className="font-mono">agda/cubical</span>
            {" • "}
            MIT License
          </p>
          <p className="mt-1">
            Data hash:{" "}
            <span className="font-mono">{meta.dataHash}</span>
            {" • "}
            Build:{" "}
            <span className="font-mono">{meta.buildDate.split("T")[0]}</span>
          </p>
        </footer>
      ) : null}
    </div>
  );
}