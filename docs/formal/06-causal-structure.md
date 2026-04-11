# Causal Structure

**Formal content:** Events as spacetime atoms, causal links and chains, causal diamonds with maximin entropy, proper time, structural acyclicity (no closed timelike curves), future light cones, and spacelike separation.

**Primary modules:** `Causal/Event.agda`, `Causal/CausalDiamond.agda`, `Causal/NoCTC.agda`, `Causal/LightCone.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry), [03-holographic-bridge.md](03-holographic-bridge.md) (SchematicTower architecture)

---

## 1. Overview

The causal layer adds a temporal dimension to the repository's spatial holographic formalization. It reinterprets the existing `SchematicTower` of verified spatial slices — each carrying an `OrbitReducedPatch` and a `BridgeWitness` — as a **discrete causal spacetime**: a partially ordered set of events connected by future-directed causal links, equipped with a discrete light cone, a computable maximin entropy functional, and a structural guarantee that no closed timelike curves (CTCs) exist.

This is **Theorem 5** in the canonical registry ([01-theorems.md](01-theorems.md)): CTC-freedom as a structural consequence of ℕ well-foundedness, enforced by the type signature of `CausalLink` rather than by a separate axiom.

The causal layer is **purely additive**: it does not modify any existing Bridge, Boundary, Bulk, Gauge, or Quantum module. It is a new wrapper layer that reinterprets the tower data through a Lorentzian lens:

| Tower Concept | Causal Interpretation |
|---|---|
| `TowerLevel` | Spatial slice (antichain in the causal poset) |
| `LayerStep` | Future-directed causal extension (Pachner move) |
| Tower index *n* | Time coordinate |
| `OrbitReducedPatch.RegionTy` at depth *n* | `CellAt n` (spatial cells at time *n*) |
| `maxCut` | Holographic depth of the spatial slice |

The causal structure is **orthogonal** to the other enrichment layers (Gauge, Quantum): it enriches the network with temporal directionality without depending on or modifying the gauge field, quantum superposition, or curvature.

---

## 2. Events — Spacetime Atoms

### 2.1 The Event Type

An event is a pair of a time index and a spatial cell within the slice at that time. Because the spatial cell type varies with the time index (as the patch grows through the tower), `Event` is a dependent type:

```agda
-- Causal/Event.agda
record Event (CellAt : ℕ → Type₀) : Type₀ where
  field
    time : ℕ
    cell : CellAt time
```

The family `CellAt : ℕ → Type₀` assigns a spatial-cell type to each time step. In the `SchematicTower` architecture (`Bridge/SchematicTower.agda`), each `TowerLevel` at depth *n* carries an `OrbitReducedPatch` whose `RegionTy` serves as `CellAt n`. The tower index IS the time coordinate; each `TowerLevel` IS an antichain (spatial slice) in the discrete causal poset.

### 2.2 Strict Ordering on ℕ

The strict ordering on natural numbers is the foundational acyclicity guarantee:

```agda
_<ℕ_ : ℕ → ℕ → Type₀
m <ℕ n = Σ[ k ∈ ℕ ] (suc k + m ≡ n)
```

The witness `(k , p)` with `p : suc k + m ≡ n` certifies that `n ≥ m + k + 1`, i.e., `n` is strictly after `m`. The `suc` in the first position (rather than just `k`) forces `n ≥ m + 1`, ensuring strict inequality. This is consistent with the non-strict ordering `_≤ℚ_` from `Util/Scalars.agda` (`m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)`), with `suc k` replacing `k`.

Concrete witnesses like `(0 , refl)` for `m <ℕ suc m` type-check because `suc 0 + m = suc m` judgmentally.

---

## 3. Causal Links — Future-Directed Steps

### 3.1 The CausalLink Record

A causal link connects two events separated by exactly one time step:

```agda
-- Causal/Event.agda
record CausalLink
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  (e₁ e₂ : Event CellAt) : Type₀ where
  field
    time-suc : suc (Event.time e₁) ≡ Event.time e₂
    adjacent : Adj (Event.time e₁)
                   (Event.cell e₁)
                   (subst CellAt (sym time-suc) (Event.cell e₂))
```

**Key design decisions:**

1. **Single time-step constraint.** The `time-suc` field requires `suc (time e₁) ≡ time e₂` rather than a general strict ordering `time e₁ <ℕ time e₂`. This makes the `adjacent` field well-typed (it connects cells at consecutive times) and matches the tower architecture where each `LayerStep` goes from level *n* to level *n+1*.

2. **Spatial adjacency.** The `Adj` parameter encodes which spatial cells at time *n* are "connected to" cells at time *suc n* through the BFS expansion. In concrete tower instances, this adjacency data would be computed by the Python oracle.

3. **Transport vanishes at refl.** When `time-suc = refl` (the common case for concrete tower-based instantiation), `subst CellAt (sym refl) = id`, so the transport vanishes and the `adjacent` field reduces directly to `Adj n c₁ c₂`.

### 3.2 Links Imply Strict Time Ordering

Every `CausalLink` strictly increases the time index:

```agda
causal-link-< :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂ : Event CellAt}
  → CausalLink CellAt Adj e₁ e₂
  → Event.time e₁ <ℕ Event.time e₂
causal-link-< cl = 0 , CausalLink.time-suc cl
```

The witness `(0 , time-suc)` certifies `suc 0 + time(e₁) = suc(time(e₁)) = time(e₂)`. This is the single-step strict ordering from which multi-step ordering is derived via transitivity.

---

## 4. Causal Chains — Composable Directed Paths

A `CausalChain` from `e₁` to `e₂` is a finite sequence of `CausalLink`s composing to a directed path in the causal poset:

```agda
-- Causal/Event.agda
data CausalChain
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  : Event CellAt → Event CellAt → Type₀ where

  done : (e : Event CellAt)
    → CausalChain CellAt Adj e e

  step : {e₁ e₂ e₃ : Event CellAt}
    → CausalChain CellAt Adj e₁ e₂
    → CausalLink CellAt Adj e₂ e₃
    → CausalChain CellAt Adj e₁ e₃
```

- **`done e`** is the trivial chain from an event to itself (length 0). This represents zero proper time and is needed for reflexive light-cone membership.
- **`step ch link`** extends a chain by one `CausalLink` at the end (snoc-style), matching "extending a causal history by one more tick."

The **chain length** (proper time between endpoints) is computed by structural recursion:

```agda
chain-length : CausalChain CellAt Adj e₁ e₂ → ℕ
chain-length (done _)    = 0
chain-length (step ch _) = suc (chain-length ch)
```

In the stratified tower, all maximal chains between levels *n* and *m* have the same length *m − n*.

---

## 5. No Closed Timelike Curves (Theorem 5)

### 5.1 The Core Arithmetic Lemmas

The NoCTC proof decomposes into three independent arithmetic facts about ℕ:

**Irreflexivity** — there is no *k* such that `suc k + n ≡ n`:

```agda
-- Causal/NoCTC.agda
<ℕ-irrefl : (n : ℕ) → n <ℕ n → ⊥
<ℕ-irrefl n (k , p) = suc+n≢n k n p
```

The helper `suc+n≢n` is proven by induction on *n*: the base case `suc k + 0 ≡ 0` is refuted by `snotz` (suc is never zero); the inductive step uses `injSuc` (suc is injective) and `+-suc` (to rearrange `k + suc n'` into `suc k + n'`).

**Transitivity** — if `a <ℕ b` and `b <ℕ c`, then `a <ℕ c`:

```agda
<ℕ-trans : {a b c : ℕ} → a <ℕ b → b <ℕ c → a <ℕ c
<ℕ-trans {a} (j , p) (k , q) =
  k + suc j ,
  cong suc (sym (+-assoc k (suc j) a) ∙ cong (k +_) p) ∙ q
```

The composed witness `k + suc j` satisfies `suc (k + suc j) + a ≡ c` via `+-assoc` and path composition.

**Chain-step ordering** — a positive-length chain implies strict ordering:

```agda
chain-step-< :
  CausalChain CellAt Adj e₁ e₂
  → CausalLink CellAt Adj e₂ e₃
  → Event.time e₁ <ℕ Event.time e₃
chain-step-< (done _)        link = causal-link-< link
chain-step-< (step ch link₁) link₂ =
  <ℕ-trans (chain-step-< ch link₁) (causal-link-< link₂)
```

Structural induction on the chain: the base case uses `causal-link-<`; the inductive step composes via `<ℕ-trans`.

### 5.2 The Theorem

```agda
-- Causal/NoCTC.agda
no-ctc :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e e'   : Event CellAt}
  → CausalChain CellAt Adj e e'
  → CausalLink CellAt Adj e' e
  → ⊥
no-ctc {e = e} ch link =
  <ℕ-irrefl (Event.time e) (chain-step-< ch link)
```

**Proof outline:**

1. `chain-step-<` gives `time(e) <ℕ time(e)` (from the chain + closing link).
2. `<ℕ-irrefl` gives `⊥` (no natural number is strictly less than itself).

This is a one-line composition — the "one-line appeal to well-foundedness of (ℕ, <)" described in §12.12 of the historical development docs.

### 5.3 Parametricity

The theorem is **fully parametric** in `CellAt` and `Adj`. It works for ANY cell family and ANY adjacency relation — not just the {5,4} tower or the Dense resolution tower. The acyclicity is a structural property of time-stratified causality, not of the spatial geometry. The type system prevents time travel by construction.

### 5.4 Named Theorem Alias

```agda
NoCTCs : (CellAt : ℕ → Type₀)
         (Adj : ∀ n → CellAt n → CellAt (suc n) → Type₀)
         → Type₀
NoCTCs CellAt Adj =
  {e e' : Event CellAt}
  → CausalChain CellAt Adj e e'
  → CausalLink CellAt Adj e' e
  → ⊥

no-ctcs : {CellAt : ℕ → Type₀}
          {Adj : ∀ n → CellAt n → CellAt (suc n) → Type₀}
          → NoCTCs CellAt Adj
no-ctcs = no-ctc
```

---

## 6. Causal Diamonds — Finite Causal Intervals

### 6.1 The CausalDiamond Data Type

A `CausalDiamond` packages a non-empty sequence of verified spatial slices (`TowerLevel` records from `Bridge/SchematicTower.agda`) connected by future-directed causal extensions (`LayerStep` monotonicity witnesses):

```agda
-- Causal/CausalDiamond.agda
data CausalDiamond : Type₁

diamond-top : CausalDiamond → TowerLevel

data CausalDiamond where
  base   : TowerLevel → CausalDiamond
  extend : (d : CausalDiamond) (hi : TowerLevel)
         → LayerStep (diamond-top d) hi → CausalDiamond

diamond-top (base t)        = t
diamond-top (extend _ hi _) = hi
```

The mutual recursion between `CausalDiamond` and `diamond-top` ensures that each `extend` step is type-correct: the `LayerStep` must connect the current top to the new level. This is the type-level enforcement of the causal arrow of time.

### 6.2 Operations on Diamonds

```agda
diamond-base : CausalDiamond → TowerLevel    -- earliest slice
n-slices     : CausalDiamond → ℕ             -- number of slices
proper-time  : CausalDiamond → ℕ             -- = n-slices − 1
```

Proper time counts the number of `extend` constructors — the total elapsed time from the earliest to the latest spatial slice.

### 6.3 Concrete Instantiations

Two concrete diamonds are defined from existing tower data:

**{5,4} Layer Tower Diamond** — 6 slices at BFS depths 2 through 7:

```agda
layer54-diamond : CausalDiamond
-- 6 slices, 5 extensions, all maxCut = 2

proper-time-layer54 : proper-time layer54-diamond ≡ 5
proper-time-layer54 = refl
```

Each extension is one Pachner move (one BFS expansion layer), producing a new verified spatial slice from 21 tiles (depth 2) to 3046 tiles (depth 7).

**Dense Resolution Tower Diamond** — 2 slices (Dense-100 → Dense-200):

```agda
dense-diamond : CausalDiamond
-- 2 slices, 1 extension, maxCut grows 8 → 9

proper-time-dense : proper-time dense-diamond ≡ 1
proper-time-dense = refl
```

---

## 7. Maximin — Covariant Holographic Entanglement Entropy

The maximin construction (Wall 2012, discrete version) computes the covariant holographic entanglement entropy by maximizing the min-cut over all spatial slices:

> S_cov(A) = max_Σ MinCut_Σ(A, Ā)

In the monotone tower, the `LayerStep.monotone` witnesses guarantee that `maxCut` is non-decreasing, so the maximum is always realized at the deepest (topmost) slice.

```agda
-- Causal/CausalDiamond.agda
maximin : CausalDiamond → ℚ≥0
maximin (base t)        = TowerLevel.maxCut t
maximin (extend d hi _) = max-ℕ (maximin d) (TowerLevel.maxCut hi)
```

Verification on the concrete diamonds:

```agda
maximin-layer54 : maximin layer54-diamond ≡ 2
maximin-layer54 = refl     -- all {5,4} layers have maxCut = 2

maximin-dense : maximin dense-diamond ≡ 9
maximin-dense = refl       -- max-ℕ 8 9 = 9
```

Both proofs are `refl` because `max-ℕ` computes by structural recursion on closed ℕ terms.

### 7.1 Maximin Equals Top

For monot one diamonds, the maximin equals the `maxCut` at the topmost slice:

```agda
maximin-equals-top-layer54 :
  maximin layer54-diamond ≡ TowerLevel.maxCut (diamond-top layer54-diamond)
maximin-equals-top-layer54 = refl

maximin-equals-top-dense :
  maximin dense-diamond ≡ TowerLevel.maxCut (diamond-top dense-diamond)
maximin-equals-top-dense = refl
```

This is the discrete analogue of the statement that the covariant holographic entropy selects the deepest available spatial slice.

---

## 8. The Discrete Light Cone

### 8.1 Future Cone

Given an event `e`, its future light cone is the set of events reachable from `e` via some `CausalChain`:

```agda
-- Causal/LightCone.agda
record FutureCone
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  (e      : Event CellAt)
  : Type₀ where
  field
    target : Event CellAt
    chain  : CausalChain CellAt Adj e target
```

Every event is in its own future cone (via the zero-length chain `done e`):

```agda
self-in-cone : (e : Event CellAt) → FutureCone CellAt Adj e
self-in-cone e .FutureCone.target = e
self-in-cone e .FutureCone.chain  = done e
```

One causal step extends the cone:

```agda
extend-cone :
  (fc : FutureCone CellAt Adj e)
  → CausalLink CellAt Adj (FutureCone.target fc) e'
  → FutureCone CellAt Adj e
```

### 8.2 Causal Relatedness

Two events are **causally related** if there exists a positive-length causal chain (at least one `CausalLink`) connecting them:

```agda
CausallyRelated :
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  → Event CellAt → Event CellAt → Type₀
CausallyRelated CellAt Adj e₁ e₂ =
  Σ[ e' ∈ Event CellAt ]
    (CausalChain CellAt Adj e₁ e' × CausalLink CellAt Adj e' e₂)
```

This decomposition matches the pattern consumed by `chain-step-<`, which extracts the strict time ordering `time e₁ <ℕ time e₂` from exactly this data:

```agda
related→time-< :
  CausallyRelated CellAt Adj e₁ e₂
  → Event.time e₁ <ℕ Event.time e₂
related→time-< (e' , ch , link) = chain-step-< ch link
```

### 8.3 Spacelike Separation

Two events are **spacelike-separated** if there is no positive-length causal chain connecting them in either direction:

```agda
Spacelike :
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  → Event CellAt → Event CellAt → Type₀
Spacelike CellAt Adj e₁ e₂ =
    (CausallyRelated CellAt Adj e₁ e₂ → ⊥)
  × (CausallyRelated CellAt Adj e₂ e₁ → ⊥)
```

### 8.4 Same-Time Events Are Spacelike

The deepest structural result of the causal layer:

```agda
-- Causal/LightCone.agda
same-time-spacelike :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂  : Event CellAt}
  → Event.time e₁ ≡ Event.time e₂
  → Spacelike CellAt Adj e₁ e₂
same-time-spacelike p =
  same-time→¬related p , same-time→¬related (sym p)
```

where `same-time→¬related` proves that same-time events cannot be causally related:

```agda
same-time→¬related :
  Event.time e₁ ≡ Event.time e₂
  → CausallyRelated CellAt Adj e₁ e₂ → ⊥
same-time→¬related {e₁ = e₁} p rel =
  <ℕ-irrefl (Event.time e₁)
    (subst (Event.time e₁ <ℕ_) (sym p) (related→time-< rel))
```

**Proof:** A positive-length chain from `e₁` to `e₂` implies `time(e₁) <ℕ time(e₂)` via `related→time-<`. Substituting `time(e₂) = time(e₁)` via `sym p` yields `time(e₁) <ℕ time(e₁)`, contradicting `<ℕ-irrefl`.

This is the discrete analogue of the statement that the causal poset restricted to a single time slice is an **antichain** (a set of pairwise incomparable elements). The type system enforces both CTC-freedom and spatial simultaneity → causal independence through the single constraint that `CausalLink.time-suc` strictly advances the time index.

---

## 9. Relationship to Other Layers

### 9.1 Orthogonality

The causal layer is orthogonal to and independent of:

- **The holographic bridge** ([03-holographic-bridge.md](03-holographic-bridge.md)): The bridge operates within each spatial slice (min-cut on the flow graph); the causal structure operates between slices.
- **Curvature** ([04-discrete-geometry.md](04-discrete-geometry.md)): Spatial curvature enriches each slice independently; the causal arrow of time is a separate temporal structure.
- **Gauge matter** ([05-gauge-theory.md](05-gauge-theory.md)): The gauge field lives on bonds within each slice; the causal structure connects slices.
- **Quantum superposition** ([07-quantum-superposition.md](07-quantum-superposition.md)): The quantum bridge operates on configuration spaces at fixed topology; the causal structure sequences topologies.

| Section | Parameter Varied | Invariant Preserved | Causal Interpretation |
|---|---|---|---|
| Wick rotation ([08-wick-rotation.md](08-wick-rotation.md)) | Curvature sign | Bridge equivalence | Spatial curvature is independent of causal structure |
| Thermodynamics ([09-thermodynamics.md](09-thermodynamics.md)) | Observer resolution | Area law + RT | Coarse-graining within a single spatial slice |
| Dynamics ([10-dynamics.md](10-dynamics.md)) | Specification index | Bridge at each step | Each "tick" is one CausalExtension |
| **Causal structure (this chapter)** | **Time index** | **Maximin + acyclicity** | **The temporal axis itself** |

### 9.2 The Tower IS the Spacetime

The existing `SchematicTower` already encodes a sequence of verified spatial slices connected by monotonicity witnesses. The causal layer adds no new data — it provides a **reinterpretation** of existing tower data through a Lorentzian lens, plus the NoCTC theorem and light-cone infrastructure as new standalone proofs.

---

## 10. Bypassing Smooth Geometry

The entire causal construction avoids:

- **No ℂ:** Quantum amplitudes are not needed. The causal structure is purely combinatorial.
- **No smooth manifolds:** The causal poset IS the discrete spacetime. "Smoothness" would be a continuum limit — the same obstacle documented in the constructive-reals wall.
- **No Lorentzian metric:** The partial order `_<ℕ_` replaces the metric signature.
  - "Timelike" = causally related (`CausallyRelated`).
  - "Spacelike" = incomparable in the poset (`Spacelike`).
  - "Null" = adjacent in the causal graph with zero spatial separation (single-step links to the same spatial cell at the next time) — not formalized here.
- **No Hamiltonian / e^{−iHt}:** Time evolution is a sequence of Pachner moves (BFS expansions) or bond-weight perturbations, not an operator exponential.

---

## 11. The Hard Boundary: Beyond Stratified Causality

The stratified tower is a **globally hyperbolic** causal spacetime: it admits a global time function (the level index *n*), and every causal diamond is compact (finite). The following aspects represent genuine hard boundaries beyond the current scope:

**Non-stratified causal sets.** A causal set without a global time function (where the partial order does not embed into ℕ) would require a more general acyclicity proof — not just well-foundedness of ℕ but a constructive proof that the poset is well-founded. This is formalizable in principle (Agda supports well-founded recursion via `Cubical.Induction.WellFounded`) but would require a non-trivial termination argument for the longest-path computation.

**Causal dynamical triangulations (CDT).** A full CDT model sums over all valid causal triangulations weighted by the discrete Einstein–Hilbert action. This requires a notion of "all valid triangulations" (a finite type of combinatorial manifolds) and a sum over them — a constructive analogue of the gravitational path integral.

**Black hole interiors and horizons.** The maximin construction breaks down inside a black hole (where no Cauchy surface penetrates the interior). Formalizing this requires defining a notion of "trapped region" in the discrete causal set — an active research topic with no known type-theoretic formalization.

---

## 12. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorem 5 |
| HoTT foundations (refl, funExt, subst, transport) | [`formal/02-foundations.md`](02-foundations.md) |
| Holographic bridge (generic architecture) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Discrete geometry (curvature, Gauss–Bonnet) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Gauge theory (Q₈, connections, holonomy) | [`formal/05-gauge-theory.md`](05-gauge-theory.md) |
| Quantum superposition bridge | [`formal/07-quantum-superposition.md`](07-quantum-superposition.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Thermodynamics (area law, coarse-graining, towers) | [`formal/09-thermodynamics.md`](09-thermodynamics.md) |
| Dynamics (step invariance, dynamics loop) | [`formal/10-dynamics.md`](10-dynamics.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](11-generic-bridge.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md) |
| Holographic dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Translation problem (honest assessment) | [`physics/translation-problem.md`](../physics/translation-problem.md) |
| Five walls (hard boundaries — Lorentzian signature) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Three hypotheses (emergent / phase transition / discrete) | [`physics/three-hypotheses.md`](../physics/three-hypotheses.md) |
| Layer-54 tower instance (CausalDiamond source) | [`instances/layer-54-tower.md`](../instances/layer-54-tower.md) |
| Dense-100 instance (Dense diamond source) | [`instances/dense-100.md`](../instances/dense-100.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Building & type-checking | [`getting-started/building.md`](../getting-started/building.md) |
| Module index (all src/ modules) | [`reference/module-index.md`](../reference/module-index.md) |
| Historical development (§12 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §12 |