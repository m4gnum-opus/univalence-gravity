/**
 * DynamicsView — Animated bond-weight perturbation on the star patch,
 * demonstrating that the discrete RT correspondence S=L is preserved
 * at every step of a dynamics loop.
 *
 * This component visualizes **Theorem 9** (Step Invariance & Dynamics
 * Loop) from `Bridge/StarStepInvariance.agda` and
 * `Bridge/StarDynamicsLoop.agda`.  The key insight: for the star
 * topology, the boundary min-cut `S_param(w, r)` and the bulk
 * minimal chain `L_param(w, r)` are **definitionally the same
 * function** of the bond weights `w`.  Perturbing any single bond
 * by any amount δ produces new weights under which S=L still holds —
 * and this extends by structural induction to any finite sequence of
 * perturbations (the dynamics loop).
 *
 * **What the user sees:**
 *
 *   A 2D schematic of the 6-tile star patch (C + N0–N4) with:
 *
 *   - **Bond lines** whose thickness and color encode the current
 *     weight w(bCNi).  Heavier bonds are thicker and more saturated.
 *
 *   - **Cell nodes** at the 5 boundary positions (N0–N4) and the
 *     central position (C).  Boundary cells are colored by their
 *     singleton min-cut value S(Ni) = w(bCNi).
 *
 *   - **Region table** showing all 10 representative regions with
 *     their current S and L values (always equal) and the S=L
 *     verification status (always ✓ by construction).
 *
 *   - **Perturbation log** listing the steps already applied, with
 *     the current step highlighted.
 *
 *   - **Playback controls**: play, pause, step forward/back, speed,
 *     and reset to initial weights.
 *
 *   - **"S = L at every step" badge** — a prominent green indicator
 *     confirming that the RT correspondence is preserved throughout
 *     the dynamics sequence.  This is the visual punchline: the
 *     badge never turns red.
 *
 * **Star patch min-cut formulas:**
 *
 *   For the star topology with weight function `w : Bond → ℚ≥0`:
 *
 *   ```
 *   S_param(w, Ni)       = w(bCNi)                    (singleton)
 *   S_param(w, NiN(i+1)) = w(bCNi) + w(bCN(i+1 mod 5))  (pair)
 *   ```
 *
 *   And `L_param` is defined by identical clauses — they are the
 *   same function.  This is proven in Agda via `SL-param-pointwise`
 *   where every case is `refl` for **variable** `w`.
 *
 * **Predefined perturbation sequence:**
 *
 *   The component ships with a curated 8-step perturbation sequence
 *   that exercises all 5 bonds with both increases and decreases,
 *   demonstrating that S=L holds regardless of the perturbation
 *   direction or magnitude.  The steps are:
 *
 *     1. bCN0 += 2  (increase bond 0 from 1 to 3)
 *     2. bCN2 += 1  (increase bond 2 from 1 to 2)
 *     3. bCN4 += 3  (increase bond 4 from 1 to 4)
 *     4. bCN1 -= 0.5 (decrease bond 1 from 1 to 0.5)
 *     5. bCN3 += 1.5 (increase bond 3 from 1 to 2.5)
 *     6. bCN0 -= 1  (decrease bond 0 from 3 to 2)
 *     7. bCN2 += 2  (increase bond 2 from 2 to 4)
 *     8. bCN4 -= 2  (decrease bond 4 from 4 to 2)
 *
 * **Agda correspondence:**
 *
 *   ```agda
 *   -- Bridge/StarStepInvariance.agda
 *   step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
 *     → ((r : Region) → S-param w r ≡ L-param w r)
 *     → ((r : Region) → S-param (perturb w b δ) r
 *                      ≡ L-param (perturb w b δ) r)
 *
 *   -- Bridge/StarDynamicsLoop.agda
 *   loop-invariant : (w₀ : Bond → ℚ≥0)
 *     → ((r : Region) → S-param w₀ r ≡ L-param w₀ r)
 *     → (steps : List (Bond × ℚ≥0))
 *     → ((r : Region) → S-param (weight-sequence w₀ steps) r
 *                      ≡ L-param (weight-sequence w₀ steps) r)
 *   ```
 *
 *   The proof is trivial for the star topology: `S-param` and
 *   `L-param` are definitionally identical, so the hypothesis is
 *   redundant and the step preserves the (trivially satisfied)
 *   invariant.  The deeper significance is that the *architecture*
 *   of the proof — parameterized observables + step invariance +
 *   list induction — generalizes to any patch where S-param and
 *   L-param agree pointwise.
 *
 * @see PatchView — The parent page that may embed this component
 * @see CellMesh — Cell rendering used in PatchScene
 * @see colorFromMinCut — Viridis coloring for min-cut values
 *
 * Reference:
 *   - docs/formal/10-dynamics.md (Step invariance, dynamics loop)
 *   - docs/instances/star-patch.md §7 (Dynamics)
 *   - Bridge/StarStepInvariance.agda (Theorem 9)
 *   - Bridge/StarDynamicsLoop.agda (Theorem 9)
 *   - Bridge/EnrichedStarStepInvariance.agda (Theorem 10)
 *   - Phase 3, item 18 of the concrete fix plan
 */

import { useState, useCallback, useEffect, useRef, useMemo } from "react";

import { viridis } from "../../utils/colors";

// ════════════════════════════════════════════════════════════════
//  Star Patch Model
// ════════════════════════════════════════════════════════════════

/** Bond identifier matching Common/StarSpec.agda. */
type BondId = "bCN0" | "bCN1" | "bCN2" | "bCN3" | "bCN4";

/** Region identifier matching Common/StarSpec.agda (10 representatives). */
interface StarRegion {
  id: string;
  label: string;
  /** Cells in the region (indices into NEIGHBOR_NAMES). */
  cells: number[];
  /** Bonds whose weights sum to the min-cut. */
  bonds: BondId[];
}

/** The 5 bond IDs in cyclic order. */
const BOND_IDS: readonly BondId[] = [
  "bCN0", "bCN1", "bCN2", "bCN3", "bCN4",
];

/** Human-readable names for the neighbor cells. */
const NEIGHBOR_NAMES = ["N₀", "N₁", "N₂", "N₃", "N₄"] as const;

/** Display labels for bonds. */
const BOND_LABELS: Readonly<Record<BondId, string>> = {
  bCN0: "C–N₀",
  bCN1: "C–N₁",
  bCN2: "C–N₂",
  bCN3: "C–N₃",
  bCN4: "C–N₄",
};

/**
 * All 10 representative boundary regions of the star patch.
 *
 * 5 singletons: {Ni} with min-cut = w(bCNi)
 * 5 adjacent pairs: {Ni, N(i+1 mod 5)} with min-cut = w(bCNi) + w(bCN(i+1))
 */
const STAR_REGIONS: readonly StarRegion[] = [
  { id: "N0",    label: "{N₀}",      cells: [0],    bonds: ["bCN0"] },
  { id: "N1",    label: "{N₁}",      cells: [1],    bonds: ["bCN1"] },
  { id: "N2",    label: "{N₂}",      cells: [2],    bonds: ["bCN2"] },
  { id: "N3",    label: "{N₃}",      cells: [3],    bonds: ["bCN3"] },
  { id: "N4",    label: "{N₄}",      cells: [4],    bonds: ["bCN4"] },
  { id: "N0N1",  label: "{N₀, N₁}",  cells: [0, 1], bonds: ["bCN0", "bCN1"] },
  { id: "N1N2",  label: "{N₁, N₂}",  cells: [1, 2], bonds: ["bCN1", "bCN2"] },
  { id: "N2N3",  label: "{N₂, N₃}",  cells: [2, 3], bonds: ["bCN2", "bCN3"] },
  { id: "N3N4",  label: "{N₃, N₄}",  cells: [3, 4], bonds: ["bCN3", "bCN4"] },
  { id: "N4N0",  label: "{N₄, N₀}",  cells: [4, 0], bonds: ["bCN4", "bCN0"] },
];

/** Bond weight state: one numeric weight per bond. */
type BondWeights = Record<BondId, number>;

/** Initial bond weights: all 1 (uniform, matching the Agda spec). */
const INITIAL_WEIGHTS: BondWeights = {
  bCN0: 1, bCN1: 1, bCN2: 1, bCN3: 1, bCN4: 1,
};

/**
 * Compute the min-cut S(region) for the star topology under weights w.
 *
 * For the star patch, S(A) = sum of w(b) for all bonds b in the
 * region's cut set.  Singletons cut 1 bond; pairs cut 2 bonds.
 *
 * L(A) is defined by identical clauses → S(A) === L(A) always.
 */
function computeMinCut(weights: BondWeights, region: StarRegion): number {
  let total = 0;
  for (const bondId of region.bonds) {
    total += weights[bondId];
  }
  return total;
}

// ════════════════════════════════════════════════════════════════
//  Perturbation Sequence
// ════════════════════════════════════════════════════════════════

/** A single perturbation: change bond `bond` by `delta`. */
interface PerturbationStep {
  bond: BondId;
  delta: number;
  /** Human-readable description. */
  description: string;
}

/**
 * A curated 8-step perturbation sequence exercising all 5 bonds
 * with both increases and decreases.
 *
 * Chosen to produce visually interesting weight configurations
 * while keeping all weights positive (the Agda type ℚ≥0 = ℕ
 * requires non-negative values; we relax to allow fractional
 * positive values for visual interest).
 */
const PERTURBATION_STEPS: readonly PerturbationStep[] = [
  { bond: "bCN0", delta: +2,   description: "Strengthen C–N₀ by 2" },
  { bond: "bCN2", delta: +1,   description: "Strengthen C–N₂ by 1" },
  { bond: "bCN4", delta: +3,   description: "Strengthen C–N₄ by 3" },
  { bond: "bCN1", delta: -0.5, description: "Weaken C–N₁ by 0.5" },
  { bond: "bCN3", delta: +1.5, description: "Strengthen C–N₃ by 1.5" },
  { bond: "bCN0", delta: -1,   description: "Weaken C–N₀ by 1" },
  { bond: "bCN2", delta: +2,   description: "Strengthen C–N₂ by 2" },
  { bond: "bCN4", delta: -2,   description: "Weaken C–N₄ by 2" },
];

/**
 * Apply a perturbation to a weight state.
 *
 * Corresponds to:
 *   perturb w b δ = λ b'. if b == b' then w(b) + δ else w(b')
 */
function applyPerturbation(
  weights: BondWeights,
  step: PerturbationStep,
): BondWeights {
  return {
    ...weights,
    [step.bond]: Math.max(0, weights[step.bond] + step.delta),
  };
}

/**
 * Compute the weight state after applying `stepCount` perturbations
 * from the beginning of the sequence.
 */
function computeWeightsAtStep(stepCount: number): BondWeights {
  let w = { ...INITIAL_WEIGHTS };
  for (let i = 0; i < stepCount && i < PERTURBATION_STEPS.length; i++) {
    const step = PERTURBATION_STEPS[i]!;
    w = applyPerturbation(w, step);
  }
  return w;
}

// ════════════════════════════════════════════════════════════════
//  Star Patch SVG Layout
// ════════════════════════════════════════════════════════════════

const SVG_SIZE = 360;
const CENTER_X = SVG_SIZE / 2;
const CENTER_Y = SVG_SIZE / 2;
const ORBIT_RADIUS = 120;
const NODE_RADIUS = 24;
const CENTER_NODE_RADIUS = 28;

/**
 * Compute the (x, y) position of neighbor Ni in the SVG coordinate
 * system.  Arranged in a regular pentagon with N0 at the top.
 */
function neighborPosition(index: number): { x: number; y: number } {
  const angle = -Math.PI / 2 + (2 * Math.PI * index) / 5;
  return {
    x: CENTER_X + ORBIT_RADIUS * Math.cos(angle),
    y: CENTER_Y + ORBIT_RADIUS * Math.sin(angle),
  };
}

// ════════════════════════════════════════════════════════════════
//  Playback Constants
// ════════════════════════════════════════════════════════════════

const BASE_INTERVAL_MS = 2000;
const SPEED_OPTIONS: readonly number[] = [0.5, 1, 2, 4];

function prefersReducedMotion(): boolean {
  if (typeof window === "undefined" || !window.matchMedia) return false;
  return window.matchMedia("(prefers-reduced-motion: reduce)").matches;
}

// ════════════════════════════════════════════════════════════════
//  Props
// ════════════════════════════════════════════════════════════════

// eslint-disable-next-line @typescript-eslint/no-empty-interface
export interface DynamicsViewProps {
  // Currently takes no props — self-contained star-patch demo.
  // Future: accept a patchName to show dynamics on other patches.
}

// ════════════════════════════════════════════════════════════════
//  Main Component
// ════════════════════════════════════════════════════════════════

/**
 * Animated dynamics visualization for the star patch, demonstrating
 * that S=L is preserved under arbitrary bond-weight perturbations.
 */
export function DynamicsView(_props: DynamicsViewProps) {
  // ── Playback state ──────────────────────────────────────────
  const [currentStep, setCurrentStep] = useState(0); // 0 = initial, 1..N = after step i
  const [playing, setPlaying] = useState(false);
  const [speed, setSpeed] = useState(1);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const maxStep = PERTURBATION_STEPS.length;

  // ── Derived weights and min-cuts ────────────────────────────
  const weights = useMemo(
    () => computeWeightsAtStep(currentStep),
    [currentStep],
  );

  const regionData = useMemo(
    () =>
      STAR_REGIONS.map((region) => {
        const s = computeMinCut(weights, region);
        return { ...region, sCut: s, lMin: s }; // S === L always
      }),
    [weights],
  );

  // Max weight for color/thickness scaling
  const maxWeight = useMemo(() => {
    let m = 1;
    for (const bondId of BOND_IDS) {
      m = Math.max(m, weights[bondId]);
    }
    return m;
  }, [weights]);

  // Max min-cut for color scaling
  const maxMinCut = useMemo(() => {
    let m = 1;
    for (const rd of regionData) {
      m = Math.max(m, rd.sCut);
    }
    return m;
  }, [regionData]);

  // Current perturbation step info (null if at initial state)
  const currentPerturbation =
    currentStep > 0 ? PERTURBATION_STEPS[currentStep - 1] ?? null : null;

  // ── Playback timer ──────────────────────────────────────────
  useEffect(() => {
    if (intervalRef.current !== null) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    if (!playing) return;
    if (prefersReducedMotion()) {
      setPlaying(false);
      return;
    }

    const ms = BASE_INTERVAL_MS / speed;
    intervalRef.current = setInterval(() => {
      setCurrentStep((prev) => {
        if (prev >= maxStep) {
          setPlaying(false);
          return prev;
        }
        return prev + 1;
      });
    }, ms);

    return () => {
      if (intervalRef.current !== null) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [playing, speed, maxStep]);

  // ── Controls ────────────────────────────────────────────────

  const handlePlayPause = useCallback(() => {
    setPlaying((prev) => {
      if (!prev && currentStep >= maxStep) {
        setCurrentStep(0);
      }
      return !prev;
    });
  }, [currentStep, maxStep]);

  const handleStepBack = useCallback(() => {
    setPlaying(false);
    setCurrentStep((prev) => Math.max(0, prev - 1));
  }, []);

  const handleStepForward = useCallback(() => {
    setPlaying(false);
    setCurrentStep((prev) => Math.min(maxStep, prev + 1));
  }, [maxStep]);

  const handleReset = useCallback(() => {
    setPlaying(false);
    setCurrentStep(0);
  }, []);

  const handleSpeedChange = useCallback(
    (e: React.ChangeEvent<HTMLSelectElement>) => {
      setSpeed(Number(e.target.value));
    },
    [],
  );

  // ── Render ──────────────────────────────────────────────────
  return (
    <section
      className="space-y-5"
      aria-label="Bond-weight dynamics visualization — star patch"
    >
      {/* ── Header ──────────────────────────────────────────── */}
      <div>
        <h3 className="font-serif text-lg font-semibold text-gray-800">
          Dynamics: Bond-Weight Perturbation
        </h3>
        <p className="text-sm text-gray-500 mt-1">
          Star patch (6 tiles, 5 bonds) — Theorem 9: the RT correspondence
          {" "}
          <span className="font-mono text-xs bg-gray-100 px-1 py-0.5 rounded">
            S = L
          </span>
          {" "}
          is preserved under arbitrary bond-weight perturbations.
        </p>
      </div>

      {/* ── S = L invariant badge ───────────────────────────── */}
      <div
        className="flex items-center justify-center gap-2 rounded-lg border border-green-200 bg-green-50 px-4 py-3"
        role="status"
        aria-live="polite"
      >
        <span className="text-green-700 text-lg font-bold" aria-hidden="true">
          ✓
        </span>
        <span className="font-mono text-sm text-green-800">
          S(A) = L(A) for all 10 regions
        </span>
        <span className="text-xs text-green-600 ml-2">
          — step {currentStep} / {maxStep}
        </span>
      </div>

      {/* ── Main content: diagram + table ───────────────────── */}
      <div className="flex flex-col lg:flex-row gap-5">
        {/* ── Star patch SVG diagram ────────────────────────── */}
        <div className="flex-1 min-w-0">
          <div className="rounded-lg border border-gray-200 bg-white p-4">
            <svg
              viewBox={`0 0 ${SVG_SIZE} ${SVG_SIZE}`}
              className="w-full max-w-[360px] mx-auto"
              role="img"
              aria-label="Star patch diagram with current bond weights"
            >
              {/* ── Bonds (lines from C to each Ni) ───────── */}
              {BOND_IDS.map((bondId, i) => {
                const pos = neighborPosition(i);
                const w = weights[bondId];
                const t = maxWeight > 0 ? w / maxWeight : 0.5;
                const thickness = 2 + t * 6;
                const opacity = 0.3 + t * 0.7;
                const isPerturbed =
                  currentPerturbation?.bond === bondId;

                return (
                  <g key={bondId}>
                    <line
                      x1={CENTER_X}
                      y1={CENTER_Y}
                      x2={pos.x}
                      y2={pos.y}
                      stroke={isPerturbed ? "#f59e0b" : "#6b7280"}
                      strokeWidth={thickness}
                      opacity={opacity}
                      strokeLinecap="round"
                      className="transition-all duration-500"
                    />
                    {/* Weight label on the bond midpoint */}
                    <text
                      x={(CENTER_X + pos.x) / 2 + (i < 3 ? 12 : -12)}
                      y={(CENTER_Y + pos.y) / 2 + (i === 0 ? -8 : i < 3 ? 4 : -4)}
                      textAnchor="middle"
                      className="fill-gray-600 text-[11px] font-mono font-semibold select-none"
                    >
                      {w.toFixed(1)}
                    </text>
                  </g>
                );
              })}

              {/* ── Neighbor nodes (N0-N4) ─────────────────── */}
              {NEIGHBOR_NAMES.map((name, i) => {
                const pos = neighborPosition(i);
                const w = weights[BOND_IDS[i]!];
                const t = maxMinCut > 0 ? w / maxMinCut : 0.5;
                const color = viridis(Math.min(1, t));

                return (
                  <g key={name}>
                    <circle
                      cx={pos.x}
                      cy={pos.y}
                      r={NODE_RADIUS}
                      fill={color}
                      stroke="#374151"
                      strokeWidth={1.5}
                      className="transition-all duration-500"
                    />
                    <text
                      x={pos.x}
                      y={pos.y - 4}
                      textAnchor="middle"
                      className="fill-white text-[11px] font-semibold select-none"
                      style={{ textShadow: "0 1px 2px rgba(0,0,0,0.5)" }}
                    >
                      {name}
                    </text>
                    <text
                      x={pos.x}
                      y={pos.y + 10}
                      textAnchor="middle"
                      className="fill-white text-[9px] font-mono select-none"
                      style={{ textShadow: "0 1px 2px rgba(0,0,0,0.5)" }}
                    >
                      S={w.toFixed(1)}
                    </text>
                  </g>
                );
              })}

              {/* ── Central node (C) ───────────────────────── */}
              <circle
                cx={CENTER_X}
                cy={CENTER_Y}
                r={CENTER_NODE_RADIUS}
                fill="#374151"
                stroke="#1f2937"
                strokeWidth={2}
              />
              <text
                x={CENTER_X}
                y={CENTER_Y + 5}
                textAnchor="middle"
                className="fill-white text-sm font-bold select-none"
              >
                C
              </text>
            </svg>

            {/* Bond legend */}
            <div className="mt-3 flex flex-wrap justify-center gap-3 text-[10px] text-gray-500">
              {BOND_IDS.map((bondId) => (
                <span key={bondId} className="font-mono">
                  {BOND_LABELS[bondId]}={weights[bondId].toFixed(1)}
                </span>
              ))}
            </div>
          </div>
        </div>

        {/* ── Right panel: region table + perturbation log ── */}
        <div className="w-full lg:w-80 shrink-0 space-y-4">
          {/* Region verification table */}
          <div className="rounded-lg border border-gray-200 bg-white p-3">
            <h4 className="font-serif text-sm font-semibold text-gray-700 mb-2">
              Region Observables
            </h4>
            <div className="overflow-x-auto">
              <table
                className="w-full text-xs"
                aria-label="Min-cut and chain values for all 10 star regions"
              >
                <thead>
                  <tr className="border-b border-gray-200 text-gray-500 uppercase tracking-wider">
                    <th className="py-1 pr-2 text-left font-medium">Region</th>
                    <th className="py-1 px-2 text-right font-medium">S</th>
                    <th className="py-1 px-2 text-right font-medium">L</th>
                    <th className="py-1 pl-2 text-center font-medium">S=L</th>
                  </tr>
                </thead>
                <tbody>
                  {regionData.map((rd) => (
                    <tr
                      key={rd.id}
                      className="border-b border-gray-50 last:border-b-0"
                    >
                      <td className="py-1 pr-2 font-mono text-gray-700">
                        {rd.label}
                      </td>
                      <td className="py-1 px-2 text-right font-mono tabular-nums text-gray-900">
                        {rd.sCut.toFixed(1)}
                      </td>
                      <td className="py-1 px-2 text-right font-mono tabular-nums text-gray-900">
                        {rd.lMin.toFixed(1)}
                      </td>
                      <td className="py-1 pl-2 text-center text-green-600 font-bold">
                        ✓
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Perturbation log */}
          <div className="rounded-lg border border-gray-200 bg-white p-3">
            <h4 className="font-serif text-sm font-semibold text-gray-700 mb-2">
              Perturbation Sequence
            </h4>
            <div className="space-y-1 max-h-48 overflow-y-auto scrollbar-thin">
              {/* Initial state */}
              <div
                className={[
                  "flex items-center gap-2 rounded px-2 py-1 text-xs",
                  currentStep === 0
                    ? "bg-viridis-50 border border-viridis-200"
                    : "text-gray-500",
                ].join(" ")}
              >
                <span className="font-mono w-6 text-right shrink-0">
                  w₀
                </span>
                <span>Initial: all weights = 1</span>
              </div>

              {/* Perturbation steps */}
              {PERTURBATION_STEPS.map((step, i) => {
                const stepNum = i + 1;
                const isActive = currentStep === stepNum;
                const isPast = currentStep > stepNum;

                return (
                  <div
                    key={i}
                    className={[
                      "flex items-center gap-2 rounded px-2 py-1 text-xs transition-colors duration-300",
                      isActive
                        ? "bg-amber-50 border border-amber-200 font-medium"
                        : isPast
                          ? "text-gray-600"
                          : "text-gray-400",
                    ].join(" ")}
                  >
                    <span className="font-mono w-6 text-right shrink-0">
                      {stepNum}
                    </span>
                    <span
                      className={[
                        "font-mono",
                        isActive ? "text-amber-800" : "",
                      ].join(" ")}
                    >
                      {BOND_LABELS[step.bond]}
                      {step.delta >= 0 ? " +" : " "}
                      {step.delta}
                    </span>
                    {isPast && (
                      <span className="text-green-500 ml-auto" aria-hidden="true">
                        ✓
                      </span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* ── Playback controls ──────────────────────────────── */}
      <div className="rounded-lg border border-gray-200 bg-white p-4 space-y-3">
        <div className="flex items-center justify-center gap-3">
          {/* Reset */}
          <button
            type="button"
            onClick={handleReset}
            className="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-xs font-medium text-gray-600 hover:bg-gray-50 disabled:opacity-40 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1 transition-colors"
            aria-label="Reset to initial weights"
          >
            Reset
          </button>

          {/* Step back */}
          <button
            type="button"
            onClick={handleStepBack}
            disabled={currentStep === 0}
            className="rounded-md border border-gray-300 bg-white p-2 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1 transition-colors"
            aria-label="Step backward"
          >
            <svg
              className="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              aria-hidden="true"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
            </svg>
          </button>

          {/* Play / Pause */}
          <button
            type="button"
            onClick={handlePlayPause}
            className="rounded-full bg-viridis-500 p-2.5 text-white hover:bg-viridis-400 focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-2 transition-colors"
            aria-label={playing ? "Pause" : "Play"}
          >
            {playing ? (
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
              </svg>
            ) : (
              <svg className="h-5 w-5" fill="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path d="M8 5v14l11-7z" />
              </svg>
            )}
          </button>

          {/* Step forward */}
          <button
            type="button"
            onClick={handleStepForward}
            disabled={currentStep >= maxStep}
            className="rounded-md border border-gray-300 bg-white p-2 text-gray-600 hover:bg-gray-50 disabled:opacity-40 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-viridis-600 focus:ring-offset-1 transition-colors"
            aria-label="Step forward"
          >
            <svg
              className="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2}
              stroke="currentColor"
              aria-hidden="true"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
            </svg>
          </button>

          {/* Separator */}
          <div className="h-5 w-px bg-gray-200 mx-1" aria-hidden="true" />

          {/* Speed */}
          <div className="flex items-center gap-1.5">
            <label htmlFor="dynamics-speed" className="text-xs text-gray-500">
              Speed
            </label>
            <select
              id="dynamics-speed"
              value={speed}
              onChange={handleSpeedChange}
              className="rounded border border-gray-300 bg-white px-2 py-1 text-xs text-gray-700 focus:border-viridis-500 focus:outline-none focus:ring-1 focus:ring-viridis-500"
              aria-label="Playback speed"
            >
              {SPEED_OPTIONS.map((s) => (
                <option key={s} value={s}>{s}×</option>
              ))}
            </select>
          </div>
        </div>

        {/* Step indicator */}
        <div className="flex items-center justify-center gap-2">
          {Array.from({ length: maxStep + 1 }, (_, i) => (
            <button
              key={i}
              type="button"
              onClick={() => {
                setPlaying(false);
                setCurrentStep(i);
              }}
              className={[
                "h-2.5 rounded-full transition-all duration-300",
                i === currentStep
                  ? "w-6 bg-viridis-500"
                  : i < currentStep
                    ? "w-2.5 bg-viridis-300"
                    : "w-2.5 bg-gray-200 hover:bg-gray-300",
              ].join(" ")}
              aria-label={
                i === 0
                  ? "Initial state"
                  : `Step ${i}: ${PERTURBATION_STEPS[i - 1]?.description ?? ""}`
              }
              title={
                i === 0
                  ? "w₀: all weights = 1"
                  : `Step ${i}: ${PERTURBATION_STEPS[i - 1]?.description ?? ""}`
              }
            />
          ))}
        </div>

        {/* Status */}
        <p className="text-center text-xs text-gray-400" aria-live="polite">
          {currentStep === 0
            ? "Initial weights: w₀ = (1, 1, 1, 1, 1)"
            : `After step ${currentStep}: ${currentPerturbation?.description ?? ""}`}
          {" · "}
          S = L on all 10 regions ✓
        </p>
      </div>

      {/* ── Explanatory note ───────────────────────────────── */}
      <div className="rounded-lg border border-gray-200 bg-gray-50 p-4 text-xs text-gray-600 space-y-2">
        <p className="font-medium text-gray-700">
          What this demonstrates
        </p>
        <p>
          For the star topology, the boundary min-cut{" "}
          <span className="font-mono bg-white px-1 rounded">S_param(w, r)</span>
          {" "} and the bulk minimal chain{" "}
          <span className="font-mono bg-white px-1 rounded">L_param(w, r)</span>
          {" "} are <em>definitionally the same function</em> of the bond
          weights — they are defined by identical pattern-matching clauses
          in Agda.  Perturbing any bond by any amount δ produces new weights
          under which S=L still holds, because the two functions remain
          identical.  The dynamics loop (Theorem 9) extends this to any
          finite sequence of perturbations via structural induction on the
          step list.
        </p>
        <p className="font-mono text-[10px] text-gray-500">
          Source: Bridge/StarStepInvariance.agda · Bridge/StarDynamicsLoop.agda
        </p>
      </div>
    </section>
  );
}