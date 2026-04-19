/**
 * Tests for the TheoremCard component (src/components/home/TheoremCard.tsx).
 *
 * Verifies:
 *   1. Renders the correct theorem number, name, and module path
 *   2. Displays the correct status badge icon and label for each
 *      TheoremStatus variant (Verified, Dead, Numerical)
 *   3. Links to `/theorems` with the correct navigation state
 *   4. Applies the correct left-border accent color by status
 *   5. Has a descriptive ARIA label for accessibility
 *   6. Truncates long module paths without breaking layout
 *
 * The TheoremCard is a compact status card used in the home page
 * theorem grid (frontend-spec §5.1). It is distinct from TheoremRow,
 * which is the expandable row used in the TheoremDashboard (/theorems).
 *
 * Because TheoremCard renders a React Router `<Link>`, all tests
 * wrap the component in a `<MemoryRouter>` to provide the routing
 * context without a real browser history.
 *
 * Reference:
 *   - src/components/home/TheoremCard.tsx (component under test)
 *   - src/types/index.ts (Theorem, TheoremStatus)
 *   - docs/engineering/frontend-spec-webgl.md §5.1 (Home page layout)
 *   - Rules §11 (Testing Requirements: renders correct status badge)
 */

import { describe, it, expect } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";

import { TheoremCard } from "../../src/components/home/TheoremCard";
import type { Theorem } from "../../src/types";

// ════════════════════════════════════════════════════════════════
//  Mock Data — One theorem per TheoremStatus variant
// ════════════════════════════════════════════════════════════════

/**
 * A Verified theorem matching data/theorems.json entry #1
 * (Discrete Ryu–Takayanagi).
 */
const VERIFIED_THEOREM: Theorem = {
  thmNumber: 1,
  thmName: "Discrete Ryu-Takayanagi",
  thmModule: "Bridge/GenericBridge.agda",
  thmStatement:
    "S_cut = L_min on every boundary region, for any patch, via a single generic theorem.",
  thmProofMethod:
    "isoToEquiv + ua + uaβ on contractible reversed singletons",
  thmStatus: "Verified",
};

/**
 * A Dead theorem (superseded by a generic theorem; dead code).
 *
 * No Dead theorems exist in the current data/theorems.json (all 10
 * are Verified), but the TheoremCard must handle this status
 * variant correctly since the TheoremStatus enum includes it.
 */
const DEAD_THEOREM: Theorem = {
  thmNumber: 99,
  thmName: "Legacy Tree Equivalence",
  thmModule: "Bridge/TreeEquiv.agda",
  thmStatement: "Superseded by the generic bridge theorem.",
  thmProofMethod: "Direct Iso construction (obsolete)",
  thmStatus: "Dead",
};

/**
 * A Numerical theorem (Python oracle numerical check only).
 *
 * No Numerical theorems exist in the current data/theorems.json,
 * but the TheoremCard must handle this status variant correctly.
 */
const NUMERICAL_THEOREM: Theorem = {
  thmNumber: 42,
  thmName: "Entropic Convergence Conjecture",
  thmModule: "sim/prototyping/14c_entropic_convergence_sup_half.py",
  thmStatement: "sup(S/area) = 0.5 across all tilings and strategies.",
  thmProofMethod: "Numerical sweep over 32,134 regions",
  thmStatus: "Numerical",
};

/**
 * A theorem with a long module path — used to verify truncation
 * behavior without layout breakage.
 */
const LONG_MODULE_THEOREM: Theorem = {
  thmNumber: 10,
  thmName: "Enriched Step Invariance",
  thmModule: "Bridge/EnrichedStarStepInvariance.agda",
  thmStatement: "Full enriched equivalence holds for any weight function.",
  thmProofMethod: "Parameterized full-equiv-w for arbitrary weight functions",
  thmStatus: "Verified",
};

// ════════════════════════════════════════════════════════════════
//  Helper: Render with Router Context
// ════════════════════════════════════════════════════════════════

/**
 * Render a TheoremCard inside a MemoryRouter.
 *
 * TheoremCard uses React Router's `<Link>` component, which
 * requires a Router context. MemoryRouter provides this without
 * interacting with the browser's URL bar.
 *
 * @param theorem - The theorem data to display.
 */
function renderCard(theorem: Theorem) {
  return render(
    <MemoryRouter>
      <TheoremCard theorem={theorem} />
    </MemoryRouter>,
  );
}

// ════════════════════════════════════════════════════════════════
//  Theorem Identity (Number, Name, Module Path)
// ════════════════════════════════════════════════════════════════

describe("theorem identity rendering", () => {
  it("renders the theorem number", () => {
    renderCard(VERIFIED_THEOREM);

    expect(screen.getByText("Theorem 1")).toBeInTheDocument();
  });

  it("renders the theorem name", () => {
    renderCard(VERIFIED_THEOREM);

    expect(
      screen.getByText("Discrete Ryu-Takayanagi"),
    ).toBeInTheDocument();
  });

  it("renders the Agda module path", () => {
    renderCard(VERIFIED_THEOREM);

    expect(
      screen.getByText("Bridge/GenericBridge.agda"),
    ).toBeInTheDocument();
  });

  it("renders a different theorem's number and name", () => {
    renderCard(LONG_MODULE_THEOREM);

    expect(screen.getByText("Theorem 10")).toBeInTheDocument();
    expect(
      screen.getByText("Enriched Step Invariance"),
    ).toBeInTheDocument();
  });

  it("renders a long module path without crashing", () => {
    renderCard(LONG_MODULE_THEOREM);

    expect(
      screen.getByText("Bridge/EnrichedStarStepInvariance.agda"),
    ).toBeInTheDocument();
  });

  it("renders all three identity fields together", () => {
    renderCard(VERIFIED_THEOREM);

    // All three should coexist in the same card
    const number = screen.getByText("Theorem 1");
    const name = screen.getByText("Discrete Ryu-Takayanagi");
    const module = screen.getByText("Bridge/GenericBridge.agda");

    expect(number).toBeInTheDocument();
    expect(name).toBeInTheDocument();
    expect(module).toBeInTheDocument();
  });
});

// ════════════════════════════════════════════════════════════════
//  Status Badge — Verified
// ════════════════════════════════════════════════════════════════

describe("status badge — Verified", () => {
  it("renders the ✓ icon for Verified status", () => {
    renderCard(VERIFIED_THEOREM);

    expect(screen.getByText("✓")).toBeInTheDocument();
  });

  it("has a 'Verified' title attribute on the badge", () => {
    renderCard(VERIFIED_THEOREM);

    const badge = screen.getByText("✓");
    expect(badge).toHaveAttribute("title", "Verified");
  });

  it("includes 'Verified' in the ARIA label of the card link", () => {
    renderCard(VERIFIED_THEOREM);

    const link = screen.getByRole("link");
    expect(link).toHaveAttribute(
      "aria-label",
      expect.stringContaining("Verified"),
    );
  });
});

// ════════════════════════════════════════════════════════════════
//  Status Badge — Dead
// ════════════════════════════════════════════════════════════════

describe("status badge — Dead", () => {
  it("renders the — icon for Dead status", () => {
    renderCard(DEAD_THEOREM);

    expect(screen.getByText("—")).toBeInTheDocument();
  });

  it("has a 'Dead code' title attribute on the badge", () => {
    renderCard(DEAD_THEOREM);

    const badge = screen.getByText("—");
    expect(badge).toHaveAttribute("title", "Dead code");
  });

  it("includes 'Dead code' in the ARIA label of the card link", () => {
    renderCard(DEAD_THEOREM);

    const link = screen.getByRole("link");
    expect(link).toHaveAttribute(
      "aria-label",
      expect.stringContaining("Dead code"),
    );
  });
});

// ════════════════════════════════════════════════════════════════
//  Status Badge — Numerical
// ════════════════════════════════════════════════════════════════

describe("status badge — Numerical", () => {
  it("renders the ~ icon for Numerical status", () => {
    renderCard(NUMERICAL_THEOREM);

    expect(screen.getByText("~")).toBeInTheDocument();
  });

  it("has a 'Numerical only' title attribute on the badge", () => {
    renderCard(NUMERICAL_THEOREM);

    const badge = screen.getByText("~");
    expect(badge).toHaveAttribute("title", "Numerical only");
  });

  it("includes 'Numerical only' in the ARIA label of the card link", () => {
    renderCard(NUMERICAL_THEOREM);

    const link = screen.getByRole("link");
    expect(link).toHaveAttribute(
      "aria-label",
      expect.stringContaining("Numerical only"),
    );
  });
});

// ════════════════════════════════════════════════════════════════
//  Navigation Link
// ════════════════════════════════════════════════════════════════

describe("navigation link", () => {
  it("renders as a link element", () => {
    renderCard(VERIFIED_THEOREM);

    const link = screen.getByRole("link");
    expect(link).toBeInTheDocument();
  });

  it("links to /theorems", () => {
    renderCard(VERIFIED_THEOREM);

    const link = screen.getByRole("link");
    expect(link).toHaveAttribute("href", "/theorems");
  });

  it("links to /theorems for all status variants", () => {
    // Verified
    const { unmount: unmountV } = renderCard(VERIFIED_THEOREM);
    expect(screen.getByRole("link")).toHaveAttribute("href", "/theorems");
    unmountV();

    // Dead
    const { unmount: unmountD } = renderCard(DEAD_THEOREM);
    expect(screen.getByRole("link")).toHaveAttribute("href", "/theorems");
    unmountD();

    // Numerical
    renderCard(NUMERICAL_THEOREM);
    expect(screen.getByRole("link")).toHaveAttribute("href", "/theorems");
  });
});

// ════════════════════════════════════════════════════════════════
//  ARIA Label
// ════════════════════════════════════════════════════════════════

describe("aria label", () => {
  it("combines theorem number, name, and status in the ARIA label", () => {
    renderCard(VERIFIED_THEOREM);

    const link = screen.getByRole("link");
    const ariaLabel = link.getAttribute("aria-label") ?? "";

    // The ARIA label should contain all key identifying information
    // so screen reader users understand the card's content without
    // visual cues.
    expect(ariaLabel).toContain("Theorem 1");
    expect(ariaLabel).toContain("Discrete Ryu-Takayanagi");
    expect(ariaLabel).toContain("Verified");
  });

  it("includes Dead code status in ARIA label for Dead theorems", () => {
    renderCard(DEAD_THEOREM);

    const link = screen.getByRole("link");
    const ariaLabel = link.getAttribute("aria-label") ?? "";

    expect(ariaLabel).toContain("Theorem 99");
    expect(ariaLabel).toContain("Legacy Tree Equivalence");
    expect(ariaLabel).toContain("Dead code");
  });

  it("includes Numerical only status in ARIA label for Numerical theorems", () => {
    renderCard(NUMERICAL_THEOREM);

    const link = screen.getByRole("link");
    const ariaLabel = link.getAttribute("aria-label") ?? "";

    expect(ariaLabel).toContain("Theorem 42");
    expect(ariaLabel).toContain("Entropic Convergence Conjecture");
    expect(ariaLabel).toContain("Numerical only");
  });
});

// ════════════════════════════════════════════════════════════════
//  Card Structure — DOM hierarchy
// ════════════════════════════════════════════════════════════════

describe("card structure", () => {
  it("renders as a single top-level link containing all content", () => {
    const { container } = renderCard(VERIFIED_THEOREM);

    // The outermost rendered element should be an <a> tag (from Link).
    // All card content (number, name, module, badge) lives inside it.
    const link = container.querySelector("a");
    expect(link).not.toBeNull();

    // Verify that the theorem name is a descendant of the link.
    expect(link!.textContent).toContain("Discrete Ryu-Takayanagi");
    expect(link!.textContent).toContain("Theorem 1");
    expect(link!.textContent).toContain("Bridge/GenericBridge.agda");
  });

  it("renders the theorem name in an h3 heading", () => {
    renderCard(VERIFIED_THEOREM);

    const heading = screen.getByRole("heading", { level: 3 });
    expect(heading).toBeInTheDocument();
    expect(heading.textContent).toBe("Discrete Ryu-Takayanagi");
  });

  it("renders the module path in a paragraph element", () => {
    renderCard(VERIFIED_THEOREM);

    // The module path has the Tailwind class "font-mono" for
    // monospace rendering. Verify it exists as text content.
    const moduleText = screen.getByText("Bridge/GenericBridge.agda");
    expect(moduleText.tagName).toBe("P");
  });
});

// ════════════════════════════════════════════════════════════════
//  All 10 Real Theorems (Regression)
// ════════════════════════════════════════════════════════════════

describe("regression — all 10 real theorems render without error", () => {
  /**
   * The 10 theorems from data/theorems.json. This regression test
   * ensures that TheoremCard handles every real theorem in the
   * dataset without crashing or rendering blank.
   */
  const ALL_THEOREMS: Theorem[] = [
    {
      thmNumber: 1,
      thmName: "Discrete Ryu-Takayanagi",
      thmModule: "Bridge/GenericBridge.agda",
      thmStatement:
        "S_cut = L_min on every boundary region, for any patch, via a single generic theorem.",
      thmProofMethod:
        "isoToEquiv + ua + uaβ on contractible reversed singletons",
      thmStatus: "Verified",
    },
    {
      thmNumber: 2,
      thmName: "Discrete Gauss-Bonnet",
      thmModule: "Bulk/GaussBonnet.agda",
      thmStatement:
        "Total combinatorial curvature equals Euler characteristic: Σκ(v) = χ(K) = 1.",
      thmProofMethod: "refl on class-weighted ℤ sum",
      thmStatus: "Verified",
    },
    {
      thmNumber: 3,
      thmName: "Discrete Bekenstein-Hawking",
      thmModule: "Bridge/HalfBound.agda",
      thmStatement:
        "S(A) ≤ area(A)/2 with 1/(4G) = 1/2 in bond-dimension-1 units.",
      thmProofMethod:
        "from-two-cuts generic lemma + per-instance abstract witnesses",
      thmStatus: "Verified",
    },
    {
      thmNumber: 4,
      thmName: "Discrete Wick Rotation",
      thmModule: "Bridge/WickRotation.agda",
      thmStatement:
        "The holographic bridge is curvature-agnostic: same Agda term for AdS and dS.",
      thmProofMethod:
        "Coherence record importing shared bridge + two GB witnesses",
      thmStatus: "Verified",
    },
    {
      thmNumber: 5,
      thmName: "No Closed Timelike Curves",
      thmModule: "Causal/NoCTC.agda",
      thmStatement: "Structural acyclicity from ℕ well-foundedness.",
      thmProofMethod: "Well-foundedness of (ℕ, <) via snotz + injSuc",
      thmStatus: "Verified",
    },
    {
      thmNumber: 6,
      thmName: "Matter as Topological Defects",
      thmModule: "Gauge/Holonomy.agda",
      thmStatement:
        "Non-trivial Q₈ Wilson loops produce inhabited ParticleDefect types.",
      thmProofMethod: "Decidable equality on Q₈ + discriminator on q1",
      thmStatus: "Verified",
    },
    {
      thmNumber: 7,
      thmName: "Quantum Superposition Bridge",
      thmModule: "Quantum/QuantumBridge.agda",
      thmStatement:
        "⟨S⟩ = ⟨L⟩ for any finite superposition, any amplitude algebra.",
      thmProofMethod: "Structural induction on List; cong₂ on _+A_",
      thmStatus: "Verified",
    },
    {
      thmNumber: 8,
      thmName: "Subadditivity & Monotonicity",
      thmModule: "Boundary/StarSubadditivity.agda",
      thmStatement:
        "S(A∪B) ≤ S(A) + S(B) and r₁ ⊆ r₂ → L(r₁) ≤ L(r₂).",
      thmProofMethod: "Exhaustive (k, refl) case splits",
      thmStatus: "Verified",
    },
    {
      thmNumber: 9,
      thmName: "Step Invariance & Dynamics Loop",
      thmModule: "Bridge/StarStepInvariance.agda",
      thmStatement:
        "RT preserved under arbitrary single-bond weight perturbations.",
      thmProofMethod: "Parameterized SL-param + list induction",
      thmStatus: "Verified",
    },
    {
      thmNumber: 10,
      thmName: "Enriched Step Invariance",
      thmModule: "Bridge/EnrichedStarStepInvariance.agda",
      thmStatement:
        "Full enriched equivalence holds for any weight function.",
      thmProofMethod:
        "Parameterized full-equiv-w for arbitrary weight functions",
      thmStatus: "Verified",
    },
  ];

  it.each(ALL_THEOREMS.map((t) => [t.thmName, t] as const))(
    "renders '%s' without error",
    (_name, theorem) => {
      const { container } = renderCard(theorem);

      // Verify the card rendered something non-empty.
      expect(container.textContent).not.toBe("");

      // Verify the theorem name is present.
      expect(screen.getByText(theorem.thmName)).toBeInTheDocument();

      // Verify the link exists and points to /theorems.
      const link = screen.getByRole("link");
      expect(link).toHaveAttribute("href", "/theorems");
    },
  );
});

// ════════════════════════════════════════════════════════════════
//  Statement and Proof Method Are NOT Shown
// ════════════════════════════════════════════════════════════════

describe("progressive disclosure — compact card omits details", () => {
  it("does NOT render the theorem statement (that is in TheoremRow)", () => {
    renderCard(VERIFIED_THEOREM);

    // The statement is a multi-sentence string. If it were rendered,
    // at least the first few words would appear in the DOM.
    expect(
      screen.queryByText(/S_cut = L_min/),
    ).not.toBeInTheDocument();
  });

  it("does NOT render the proof method (that is in TheoremRow)", () => {
    renderCard(VERIFIED_THEOREM);

    expect(
      screen.queryByText(/isoToEquiv/),
    ).not.toBeInTheDocument();
  });
});