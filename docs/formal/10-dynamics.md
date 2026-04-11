# Dynamics

**Formal content:** Parameterized observables, bond-weight perturbation, step invariance of the discrete RT correspondence, the iterated dynamics loop, and enriched step invariance with structural property conversion for arbitrary weight functions.

**Primary modules:** `Boundary/StarCutParam.agda`, `Bulk/StarChainParam.agda`, `Bridge/StarStepInvariance.agda`, `Bridge/StarDynamicsLoop.agda`, `Bridge/EnrichedStarStepInvariance.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry — Theorems 9 & 10), [03-holographic-bridge.md](03-holographic-bridge.md) (generic bridge architecture)

---

## 1. Overview

Every module in the repository prior to the dynamics layer proves a property of a *fixed* discrete geometry: a single patch with a single weight assignment, a single curvature distribution, a single set of observables. Nothing evolves. Nothing moves.

The dynamics layer addresses this by proving that the discrete Ryu–Takayanagi correspondence is **preserved under local graph rewrites**: starting from any verified weight assignment, applying a local modification (a single bond-weight change) produces a new assignment at which the holographic bridge still holds. Iterated application of this lemma yields a **generic dynamics theorem** — the "while(true) loop" — guaranteeing that arbitrarily long sequences of local modifications maintain the correspondence at every step.

This is **Theorem 9** (step invariance and dynamics loop) and **Theorem 10** (enriched step invariance) in the canonical registry ([01-theorems.md](01-theorems.md)).

The dynamics layer is built in three stages:

1. **Parameterized observables** (`StarCutParam`, `StarChainParam`): redefine S-cut and L-min as functions of an *arbitrary* weight function `w : Bond → ℚ≥0`, rather than fixed lookup tables returning canonical constants.

2. **Step invariance** (`StarStepInvariance`): define the `perturb` function and prove that the RT correspondence `S-param w ≡ L-param w` is preserved under single-bond weight perturbations.

3. **Iterated dynamics** (`StarDynamicsLoop`): prove by structural induction on a list of perturbation steps that any finite sequence of local modifications preserves the correspondence.

4. **Enriched step invariance** (`EnrichedStarStepInvariance`): extend the invariance to the full enriched type equivalence, including subadditivity ↔ monotonicity conversion via `+-comm`.

The key structural fact enabling the dynamics layer: for the star topology, `S-param` and `L-param` are **definitionally the same function** of the bond weights. Both are defined by identical pattern-matching clauses in separate modules. This makes the step-invariance theorem trivial for the star: the hypothesis "if S ≡ L at weight w" is redundant, because S and L agree at *any* weight function. The non-trivial content is the *architecture* — the `perturb` function, the specification lemmas, and the inductive loop — which generalizes to non-star topologies where S and L may genuinely differ.

---

## 2. Parameterized Observables

### 2.1 The Shift from Lookup Tables to Computed Expressions

The existing bridge proofs (star-pointwise, filled-pointwise, etc.) all hold by `refl` on **closed numeral terms** because both sides reduce to the same canonical ℕ literal. The lookup tables `S-cut` and `L-min` return fixed constants (`1q`, `2q`) regardless of the weight function — they don't inspect it.

The dynamics layer requires a fundamentally different approach: the observables must depend on the weights as **variables**, producing computed expressions like `w bCN0 +ℚ w bCN1` that require explicit ℕ arithmetic lemmas to manipulate. This is the transition from *specification-level lookup* to *parameterized computation*.

### 2.2 S-param — Parameterized Boundary Min-Cut

For each representative boundary region of the 6-tile star, `S-param` computes the min-cut value from an arbitrary bond-weight function `w : Bond → ℚ≥0`:

```agda
-- Boundary/StarCutParam.agda

S-param : (Bond → ℚ≥0) → Region → ℚ≥0
S-param w regN0   = w bCN0
S-param w regN1   = w bCN1
S-param w regN2   = w bCN2
S-param w regN3   = w bCN3
S-param w regN4   = w bCN4
S-param w regN0N1 = w bCN0 +ℚ w bCN1
S-param w regN1N2 = w bCN1 +ℚ w bCN2
S-param w regN2N3 = w bCN2 +ℚ w bCN3
S-param w regN3N4 = w bCN3 +ℚ w bCN4
S-param w regN4N0 = w bCN4 +ℚ w bCN0
```

In the star topology, every min-cut severs a subset of the 5 central bonds C–Nᵢ. For singletons, the cut severs one bond (cost = `w bCNᵢ`). For adjacent pairs, the cut severs two bonds (cost = `w bCNᵢ +ℚ w bCNⱼ`). This is the discrete Ryu–Takayanagi computation: bulk geometry (bond weights) determines boundary entanglement (min-cut values).

### 2.3 L-param — Parameterized Bulk Minimal Chain

The bulk observable is defined identically:

```agda
-- Bulk/StarChainParam.agda

L-param : (Bond → ℚ≥0) → Region → ℚ≥0
L-param w regN0   = w bCN0
L-param w regN1   = w bCN1
  ...
L-param w regN4N0 = w bCN4 +ℚ w bCN0
```

The definitional coincidence `S-param ≡ L-param` (both defined by identical pattern-matching clauses in separate modules) is the structural content of the discrete RT correspondence for the star topology: the boundary min-cut and the bulk minimal chain always sever the **same** set of bonds for any weight function.

### 2.4 The Parameterized RT Correspondence

```agda
-- Bulk/StarChainParam.agda

SL-param-pointwise :
  (w : Bond → ℚ≥0) (r : Region) → S-param w r ≡ L-param w r
SL-param-pointwise w regN0   = refl
SL-param-pointwise w regN1   = refl
  ...
SL-param-pointwise w regN4N0 = refl

SL-param : (w : Bond → ℚ≥0) → S-param w ≡ L-param w
SL-param w = funExt (SL-param-pointwise w)
```

All 10 cases hold by `refl` because for each region constructor `r`, `S-param w r` and `L-param w r` reduce to the same expression in terms of `w`. This works for **variable** `w` — not just the canonical `starWeight` — which is the key property needed by the step-invariance theorem.

### 2.5 Specification Agreement

At the canonical weight assignment `starWeight` (all bonds = `1q`), the parameterized observables reduce to the existing lookup tables:

```agda
S-param-spec : S-param starWeight ≡ S-cut (π∂ starSpec)
S-param-spec = funExt S-param-spec-pointwise
```

All 10 cases hold by `refl` because `starWeight bCNi = 1q` and `1q +ℚ 1q = 2q` judgmentally. This connects the parameterized development to the existing verified bridge, ensuring backward compatibility.

---

## 3. Bond-Weight Perturbation

### 3.1 The perturb Function

A single-bond weight perturbation modifies one bond's weight while leaving all others unchanged:

```agda
-- Bridge/StarStepInvariance.agda

perturb : (Bond → ℚ≥0) → Bond → ℚ≥0 → (Bond → ℚ≥0)
```

The definition is a 25-case pattern match on (target bond, query bond). The diagonal cases return `w b +ℚ δ` (the perturbed weight); the off-diagonal cases return `w b'` (unchanged). For a 5-constructor type, this is the most transparent approach: for any two closed Bond constructors, `perturb w b δ b'` reduces in one step.

### 3.2 Specification Lemmas

Two lemmas characterize the perturbation:

**`perturb-self`** — the target bond gains δ:

```agda
perturb-self : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → perturb w b δ b ≡ w b +ℚ δ
```

All 5 cases hold by `refl` (diagonal clauses reduce directly).

**`perturb-other`** — non-target bonds are unchanged:

```agda
perturb-other : (w : Bond → ℚ≥0) (b b' : Bond) (δ : ℚ≥0)
  → (b ≡ b' → ⊥) → perturb w b δ b' ≡ w b'
```

The 20 off-diagonal cases hold by `refl`. The 5 diagonal cases are contradicted by the distinctness hypothesis: `b ≡ b` is witnessed by `refl`, so applying the negation yields `⊥`, from which `rec` produces any type.

### 3.3 Design Decision: Exhaustive Case Split vs Decidable Equality

The `perturb` function uses explicit 25-case pattern matching rather than decidable equality on `Bond`. This avoids importing `Cubical.Relation.Nullary.Discrete` and keeps the definition fully transparent to the normalizer. The `perturb-other` lemma uses the explicit negation `(b ≡ b' → ⊥)` rather than the `¬_` type from the nullary module, making the absurdity derivation (`rec (¬p refl)`) visually clear.

---

## 4. Step Invariance (Theorem 9a)

### 4.1 The Theorem

```agda
-- Bridge/StarStepInvariance.agda

step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → ((r : Region) → S-param w r ≡ L-param w r)
  → ((r : Region) → S-param (perturb w b δ) r
                   ≡ L-param (perturb w b δ) r)
step-invariant w b δ _ r = SL-param-pointwise (perturb w b δ) r
```

**Proof:** A single application of `SL-param-pointwise` at the perturbed weight function. The hypothesis `hyp` is bound by `_` (unused) because the RT correspondence at the perturbed weights holds independently of whether it held at the original weights — `S-param` and `L-param` are the same function for *any* weight function.

### 4.2 Physical Interpretation

Each `perturb` application is one "tick" of the discrete clock — a local modification to the entanglement network that changes one bond's capacity by δ. The step-invariance theorem guarantees that the bulk geometry (L-param) tracks the boundary entanglement (S-param) at the new configuration. The "error correction" interpretation: the boundary may change arbitrarily, and the bridge equivalence guarantees that a unique consistent bulk configuration exists.

### 4.3 Unconditional Formulation

For the star topology, the hypothesis is redundant:

```agda
step-invariant-unconditional :
  (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → ((r : Region) → S-param (perturb w b δ) r
                   ≡ L-param (perturb w b δ) r)
step-invariant-unconditional w b δ r =
  SL-param-pointwise (perturb w b δ) r
```

The conditional formulation is retained because it matches the target theorem from §11.3 of `historical/development-docs/10-frontier.md` and generalizes to non-star topologies where the hypothesis would be genuinely needed.

---

## 5. The Dynamics Loop (Theorem 9b)

### 5.1 Iterated Perturbation

A sequence of perturbation steps is encoded as a list of (bond, delta) pairs:

```agda
-- Bridge/StarDynamicsLoop.agda

weight-sequence : (Bond → ℚ≥0) → List (Bond × ℚ≥0) → (Bond → ℚ≥0)
weight-sequence w₀ []            = w₀
weight-sequence w₀ ((b , δ) ∷ s) = perturb (weight-sequence w₀ s) b δ
```

The list is folded right-to-left: the head of the list is the *last* perturbation applied. The tail is processed first (building up from the initial weights), and the head step wraps the result.

### 5.2 The Loop Invariant

```agda
loop-invariant :
  (w₀ : Bond → ℚ≥0)
  → ((r : Region) → S-param w₀ r ≡ L-param w₀ r)
  → (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence w₀ steps) r
                   ≡ L-param (weight-sequence w₀ steps) r)
loop-invariant w₀ base []       = base
loop-invariant w₀ base (s ∷ ss) =
  step-invariant (weight-sequence w₀ ss) (fst s) (snd s)
                 (loop-invariant w₀ base ss)
```

**Proof structure:** Structural induction on the list of perturbation steps.

- **Base case** (empty list): `weight-sequence w₀ [] = w₀`, so the hypothesis `base` applies directly.

- **Inductive step** (`s ∷ ss`): `weight-sequence w₀ (s ∷ ss) = perturb (weight-sequence w₀ ss) (fst s) (snd s)`. By the induction hypothesis, the RT correspondence holds at `weight-sequence w₀ ss`. By `step-invariant`, it is preserved under one more perturbation.

The proof term is ~5 lines. The "while(true) loop" claim: this works for lists of **arbitrary length** — any finite number of ticks maintains the holographic correspondence.

### 5.3 Canonical Base Case

```agda
star-base : (r : Region) → S-param starWeight r ≡ L-param starWeight r
star-base = SL-param-pointwise starWeight

star-loop :
  (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence starWeight steps) r
                   ≡ L-param (weight-sequence starWeight steps) r)
star-loop = loop-invariant starWeight star-base
```

Starting from the canonical all-ones weight function `starWeight`, any finite sequence of perturbations preserves the RT correspondence.

### 5.4 Concrete Verification

Regression tests verify the loop on small concrete step sequences:

```agda
-- 2 steps: perturb bCN0 by 1, then bCN1 by 2
two-steps : List (Bond × ℚ≥0)
two-steps = (bCN1 , 2) ∷ (bCN0 , 1) ∷ []

-- At regN0N1:  w bCN0 + w bCN1 = (1+1) + (1+2) = 2 + 3 = 5
check-2-steps-val :
  S-param (weight-sequence starWeight two-steps) regN0N1 ≡ 5
check-2-steps-val = refl

-- S and L still agree
check-2-steps-agree :
  S-param (weight-sequence starWeight two-steps) regN0N1
  ≡ L-param (weight-sequence starWeight two-steps) regN0N1
check-2-steps-agree = refl
```

All tests hold by `refl` because `perturb`, `starWeight`, and `_+ℚ_ = _+_` on ℕ all compute by structural recursion on closed constructor terms.

---

## 6. Enriched Step Invariance (Theorem 10)

### 6.1 Motivation

The basic step-invariance (§4) proves that the *pointwise* RT correspondence `S-param w r ≡ L-param w r` is preserved under perturbation. Theorem 10 extends this to the *full enriched type equivalence*, including the structural property conversion (subadditivity ↔ monotonicity) proven in `Bridge/FullEnrichedStarObs.agda`.

### 6.2 Parameterized Subadditivity

For the restricted 5-union relation on the 10-region type, every union is `{Nᵢ} ∪ {Nᵢ₊₁} = {Nᵢ, Nᵢ₊₁}`. The subadditivity obligation reduces to:

> `w bCNi +ℚ w bCN_{i+1}  ≤  w bCNi + w bCN_{i+1}`

because both sides compute to the same expression. The witness is `(0 , refl)` since `0 + n = n` definitionally. This works for **variable** `w`:

```agda
-- Bridge/EnrichedStarStepInvariance.agda

S-param-subadd : (w : Bond → ℚ≥0) → Subadditive (S-param w)
S-param-subadd w _ _ _ u-N0∪N1 = 0 , refl
S-param-subadd w _ _ _ u-N1∪N2 = 0 , refl
  ...
S-param-subadd w _ _ _ u-N4∪N0 = 0 , refl
```

### 6.3 Parameterized Monotonicity

For the 10 subregion inclusions, monotonicity requires `w bCNi ≤ w bCNj +ℚ w bCNk`. The witness `k` is the "other" bond weight. When Nᵢ is the second summand in the pair (pair = `w bCNj +ℚ w bCNi`), we get `k + w bCNi = w bCNj + w bCNi` by `refl`. When Nᵢ is the first summand (pair = `w bCNi +ℚ w bCNk`), we need `k + w bCNi = w bCNi + w bCNk`, i.e., `+-comm`:

```agda
L-param-mono : (w : Bond → ℚ≥0) → Monotone (L-param w)
L-param-mono w _ _ sub-N0∈N4N0 = w bCN4 , refl
L-param-mono w _ _ sub-N0∈N0N1 = w bCN1 , +-comm (w bCN1) (w bCN0)
  ...
```

5 of 10 cases hold by `refl`; the other 5 use `+-comm` from `Util/NatLemmas.agda`. This is the only piece of ℕ arithmetic infrastructure needed — validating the estimate from §11.5 of the historical development docs that Strategy A would require "50 lines of ℕ reasoning."

### 6.4 The Full Equivalence for Any Weight Function

```agda
full-equiv-w : (w : Bond → ℚ≥0) → FullBdy-w w ≃ FullBulk-w w
full-equiv-w w = isoToEquiv (full-iso-w w)
```

The `Iso` is built with the same architecture as the canonical `full-iso` in `Bridge/FullEnrichedStarObs.agda`:

- **Forward map**: keeps the observable function, extends the spec from `f ≡ S-param w` to `f ≡ L-param w` by appending `SL-param w`, and derives monotonicity from the new spec.
- **Inverse map**: appends `sym (SL-param w)` and derives subadditivity.
- **Round-trip proofs**: close because `Region → ℚ≥0` is a set (`isSetObs`) and the structural properties are propositional (`isPropSubadditive`, `isPropMonotone`).

### 6.5 The Enriched Step-Invariance Theorem

```agda
enriched-step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → FullBdy-w w ≃ FullBulk-w w
  → FullBdy-w (perturb w b δ) ≃ FullBulk-w (perturb w b δ)
enriched-step-invariant w b δ _ = full-equiv-w (perturb w b δ)
```

The hypothesis is unused (the equivalence holds for any weight function). The proof instantiates `full-equiv-w` at the perturbed weight.

---

## 7. Architectural Significance

### 7.1 Snapshot Dynamics vs Rewrite Dynamics

| Aspect | §9 (Snapshot Dynamics) | §10–11 (Rewrite Dynamics) |
|---|---|---|
| Bridge proofs | independently verified per snapshot | derived from previous step + rewrite lemma |
| Number of proofs | one per snapshot (finite) | one inductive proof (covers all steps) |
| New-snapshot cost | re-run Python oracle + Agda type-check | zero (automatic from invariance theorem) |
| Weight function | fixed canonical (`starWeight`) | arbitrary (`w : Bond → ℚ≥0`) |
| Obstacle level | packaging (solved) | parameterized arithmetic (`+-comm`) |

The dynamics layer provides the **stronger** claim: given one verified bridge at an initial configuration, all subsequent configurations obtained by perturbation are automatically verified. No additional Python oracle invocations or Agda type-checking runs are needed for new snapshots.

### 7.2 The Trivial Case and Its Non-Trivial Architecture

For the star topology, `S-param` and `L-param` are definitionally the same function. This makes the step-invariance theorem trivially true. The non-trivial content is:

1. **The `perturb` function and its specification lemmas**, which establish that the perturbation modifies exactly one bond weight and leaves all others unchanged.

2. **The iterated loop**, which demonstrates the compositional pattern: `step-invariant` at each tick, composed by structural induction on the list.

3. **The enriched invariance**, which shows that `+-comm` is the *only* arithmetic infrastructure needed for the full structural-property conversion at variable weights.

For larger patches (e.g., the 11-tile filled patch) where S-param and L-param may genuinely differ (due to boundary-leg effects), the step-invariance proof would require genuine graph-theoretic reasoning about which min-cuts are affected by a single-bond perturbation. The star topology is the base case where this reasoning is trivial — the architecture is validated here and designed to generalize.

### 7.3 Relationship to Other Parameterizations

| Section | Parameter Varied | Invariant Preserved |
|---|---|---|
| Wick rotation ([08-wick-rotation.md](08-wick-rotation.md)) | Curvature sign | Bridge equivalence |
| Thermodynamics ([09-thermodynamics.md](09-thermodynamics.md)) | Observer resolution | Area law + RT |
| **Dynamics (this chapter)** | **Bond weights** | **Bridge at each step** |

All three are instances of the same architectural pattern: parameterize the common source specification, verify the bridge at each parameter value, and package the coherence. The dynamics layer parameterizes by the weight function `w`; the Wick rotation parameterizes by the tiling valence `q`; the thermodynamics parameterizes by the resolution level `N`.

---

## 8. The ℕ Arithmetic Infrastructure

The dynamics layer is the first part of the repository that requires explicit ℕ arithmetic lemmas (beyond `refl` on closed numerals). The required infrastructure is collected in `Util/NatLemmas.agda`:

| Lemma | Type | Source | Used by |
|-------|------|--------|---------|
| `+-comm` | `m + n ≡ n + m` | `Cubical.Data.Nat.Properties` | `L-param-mono` (5 of 10 cases) |
| `+-assoc` | `m + (n + o) ≡ (m + n) + o` | `Cubical.Data.Nat.Properties` | Available but not needed for star |
| `+-cancelˡ` | `m + k₁ ≡ m + k₂ → k₁ ≡ k₂` | Proved locally | `isProp≤ℚ` |
| `+-cancelʳ` | `k₁ + m ≡ k₂ + m → k₁ ≡ k₂` | Via `+-cancelˡ` + `+-comm` | `isProp≤ℚ` |
| `+-cong₂` | `a₁ ≡ a₂ → b₁ ≡ b₂ → a₁ + b₁ ≡ a₂ + b₂` | Via `cong₂` | Named convenience |

The `+-comm` dependency is the **only** new arithmetic beyond what the existing repository uses. This validates the feasibility assessment from §11.5 of the historical development docs: the actual arithmetic is much simpler than anticipated because subadditivity is trivial (both sides are the same expression) and monotonicity needs only commutativity.

---

## 9. The Hard Boundary: Beyond Fixed Topology

The weight-perturbation approach keeps the graph topology fixed. Physical dynamics (space expanding, black holes merging) corresponds to **topological changes** — adding or removing cells, rewiring bonds. This faces two additional obstacles:

1. **Changing region types.** If the patch grows from N to N+1 cells, the `Region` type gains new constructors. A parameterized proof must be stated over a *family* of region types indexed by patch size, requiring the inductive tiling definition from Direction C (N-Layer Generalization).

2. **Non-local min-cut effects.** Adding a cell can create new flow paths that reduce existing min-cut values. Proving that the RT correspondence is preserved requires a monotonicity argument for min-cut under graph expansion — a non-trivial result in combinatorial optimization.

These obstacles correspond to the genuine physical difficulty that gravity (bulk geometry change) in response to matter (boundary state change) is one of the central unsolved problems of quantum gravity.

---

## 10. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorems 9, 10 |
| HoTT foundations (funExt, cong, transport) | [`formal/02-foundations.md`](02-foundations.md) |
| Holographic bridge (generic, curvature-agnostic) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Discrete geometry (curvature, orthogonal) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Gauge theory (gauge-agnostic bridge) | [`formal/05-gauge-theory.md`](05-gauge-theory.md) |
| Causal structure (temporal dimension) | [`formal/06-causal-structure.md`](06-causal-structure.md) |
| Quantum superposition bridge | [`formal/07-quantum-superposition.md`](07-quantum-superposition.md) |
| Wick rotation (curvature-parameterized) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Thermodynamics (resolution-parameterized) | [`formal/09-thermodynamics.md`](09-thermodynamics.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Star patch instance data | [`instances/star-patch.md`](../instances/star-patch.md) |
| Historical development (§9, §11 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §9, §11 |