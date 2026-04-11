# Quantum Superposition

**Formal content:** Amplitude-polymorphic algebra, finite quantum superpositions, the expected-value functional, the quantum bridge theorem (⟨S⟩ = ⟨L⟩), and the concrete instantiation for the 6-tile star patch with Q₈ gauge group.

**Primary modules:** `Quantum/AmplitudeAlg.agda`, `Quantum/Superposition.agda`, `Quantum/QuantumBridge.agda`, `Quantum/StarQuantumBridge.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry), [03-holographic-bridge.md](03-holographic-bridge.md) (generic bridge architecture), [05-gauge-theory.md](05-gauge-theory.md) (Q₈ gauge group, connections, holonomy)

---

## 1. Overview

Every module in the repository prior to the quantum layer evaluates one specific, classical graph configuration at a time. The compiler loads a single `PatchData` — one weight assignment, one gauge connection, one curvature distribution — and proves the Ryu–Takayanagi correspondence S = L for that frozen snapshot. Quantum mechanics demands more: reality is not one definite graph but a probability distribution of all possible configurations existing simultaneously.

The quantum layer resolves this by proving that the holographic bridge lifts from individual microstates to **any finite superposition** of configurations, weighted by amplitudes in **any** algebraic type. This is **Theorem 7** in the canonical registry ([01-theorems.md](01-theorems.md)): for any superposition ψ and any amplitude algebra A, if S(ω) = L(ω) for every microstate ω, then ⟨S⟩ = ⟨L⟩.

The proof is 5 lines of Cubical Agda — a structural induction on a list, using only `refl`, `cong`, and `cong₂`. No ring axioms are required. The proof is amplitude-polymorphic, topology-agnostic, and gauge-group-agnostic by construction.

The quantum layer is **purely additive**: it does not modify any existing Bridge, Boundary, Bulk, Gauge, or Causal module. It adds a single thin inductive lemma on top of the full existing infrastructure:

```
Gauge/ (Q₈, Connection, Holonomy)
     │
Gauge/RepCapacity (dim functor → starQ8Capacity)
     │
SL-param-pointwise (RT for any weight function w)
     │
quantum-bridge (linearity over finite list — 5 lines)
     │
⟨S⟩ ≡ ⟨L⟩  for any superposition ψ, any amplitude algebra
```

---

## 2. The Amplitude-Polymorphic Interface

### 2.1 The Key Insight

The quantum bridge theorem does **not** require complex numbers, Hilbert spaces, or any specific algebraic structure on the amplitudes. It requires only the following:

> If f(ω) = g(ω) for every ω in a finite list [(ω₁, α₁), …, (ωₙ, αₙ)], then Σᵢ αᵢ · f(ωᵢ) = Σᵢ αᵢ · g(ωᵢ) for **any** type A of coefficients αᵢ, provided A admits scaling (α · n) and accumulation (a + b).

This is the linearity of finite sums — a triviality in any algebraic setting. But in Cubical Agda, it is even simpler: the proof uses only `cong` and `cong₂`, which are **automatic congruence properties of functions**. No commutativity, associativity, or distributivity is needed.

### 2.2 The AmplitudeAlg Record

The minimal interface capturing the four operations needed by the quantum bridge:

```agda
-- Quantum/AmplitudeAlg.agda

record AmplitudeAlg : Type₁ where
  field
    A       : Type₀
    _+A_    : A → A → A
    _·A_    : A → A → A
    0A      : A
    embedℕ  : ℕ → A
```

The fields are:

| Field | Role | Used by |
|-------|------|---------|
| `A` | The amplitude type | Everything |
| `_+A_` | Accumulation (fold step) | `cong₂ _+A_` in inductive step |
| `_·A_` | Scaling (amplitude · observable) | `cong (_·A_ α)` in inductive step |
| `0A` | Zero (base case of empty fold) | `refl` in base case |
| `embedℕ` | Lifts ℕ-valued observables into A | `cong embedℕ` in inductive step |

The record contains **zero axioms**. The proof requires only that these are functions — which is automatic in Cubical Agda.

### 2.3 Concrete Instances

Two instances are provided:

**ℕAmplitude** — classical counting (no interference):

```agda
ℕAmplitude : AmplitudeAlg
ℕAmplitude .A       = ℕ
ℕAmplitude ._+A_    = _+ℕ_
ℕAmplitude ._·A_    = _·ℕ_
ℕAmplitude .0A      = 0
ℕAmplitude .embedℕ  = λ n → n
```

When A = ℕ, all amplitudes are non-negative, so no cancellation can occur — this is the classical partition function from statistical mechanics.

**ℤiAmplitude** — Gaussian integers (quantum interference):

```agda
ℤiAmplitude : AmplitudeAlg
ℤiAmplitude .A       = ℤ[i]
ℤiAmplitude ._+A_    = _+ℤi_
ℤiAmplitude ._·A_    = _·ℤi_
ℤiAmplitude .0A      = 0ℤi
ℤiAmplitude .embedℕ  = embedℕ-ℤi
```

When A = ℤ[i], amplitudes with opposite signs can cancel (destructive interference) — the fundamental quantum-mechanical phenomenon impossible with non-negative weights.

---

## 3. The Gaussian Integers ℤ[i]

### 3.1 Representation

The Gaussian integers ℤ[i] = { a + bi | a, b ∈ ℤ } are the simplest number system supporting quantum interference. They are represented as a record over the cubical library's ℤ:

```agda
-- Quantum/AmplitudeAlg.agda

record ℤ[i] : Type₀ where
  constructor mkℤi
  field
    re : ℤ
    im : ℤ
```

### 3.2 Ring Operations

Addition and multiplication follow the standard complex arithmetic rules:

```
(a + bi) + (c + di) = (a + c) + (b + d)i
(a + bi) · (c + di) = (ac − bd) + (ad + bc)i
```

All operations compute by structural recursion on closed ℤ terms, preserving the judgmental-computation property that powers the `refl`-based proof architecture. The key verification:

```agda
-- i² = −1
check-i-squared : iℤi ·ℤi iℤi ≡ neg1ℤi
check-i-squared = refl
```

This holds by `refl` because the entire computation chain — ℤ multiplication, negation, addition — reduces judgmentally on closed constructor terms.

### 3.3 Why Not Full ℂ?

Constructive complex analysis in Cubical Agda is an active, largely unsolved area. The Gaussian integers ℤ[i] ⊂ ℂ are a discrete subring that captures the essential interference phenomenon (destructive cancellation of amplitudes with opposite signs) without requiring constructive reals, completeness, or continuous fields.

For gauge groups requiring higher roots of unity (e.g., ℤ/nℤ with n > 4), ℤ[i] would be replaced by the cyclotomic integers ℤ[ζₙ], represented as a polynomial ring ℤ[x] / Φₙ(x). The quantum bridge theorem is indifferent to this choice — it works for **any** AmplitudeAlg instance.

---

## 4. The Superposition Type and Expected Value

### 4.1 Superposition — A Finite Weighted List

A quantum state (superposition) is a finite list of pairs (configuration, amplitude):

```agda
-- Quantum/Superposition.agda

Superposition : Type₀ → AmplitudeAlg → Type₀
Superposition Config alg = List (Config × AmplitudeAlg.A alg)
```

The `Config` parameter is completely abstract — it could be `GaugeConnection Q₈ Bond` (gauge configurations on the star patch), bond-weight assignments, spin labels, or any other `Type₀` value. The quantum bridge theorem exploits this parametricity.

For the 6-tile star with Q₈ (|G| = 8, |B| = 5), the full configuration space has 8⁵ = 32,768 entries — each a term in the finite sum.

### 4.2 The 𝔼 Functional — The Finite Path Integral

The expected value of a ℕ-valued observable O under a superposition ψ is the finite sum:

```agda
-- Quantum/Superposition.agda

𝔼 : (alg : AmplitudeAlg) {Config : Type₀}
   → Superposition Config alg
   → (Config → ℕ)
   → AmplitudeAlg.A alg
𝔼 alg []              O = AmplitudeAlg.0A alg
𝔼 alg ((ω , α) ∷ ψ)  O =
  AmplitudeAlg._+A_ alg
    (AmplitudeAlg._·A_ alg α (AmplitudeAlg.embedℕ alg (O ω)))
    (𝔼 alg ψ O)
```

This is a right fold starting from `0A`. Each term contributes `α ·A embedℕ(O(ω))` — the amplitude-weighted embedded observable value. The fold accumulates these contributions into a single amplitude-ring element: the **path integral**.

**Critical property:** The cons case unfolds **judgmentally** to `_+A_ (α ·A embedℕ (O ω)) (𝔼 alg ψ O)`. This means `cong₂ _+A_` can decompose the inductive step of the quantum bridge proof without needing any ring axiom or reduction lemma.

### 4.3 The Partition Function

The normalization constant Z is the expected value of the constant observable λ ω → 1:

```agda
Z : (alg : AmplitudeAlg) {Config : Type₀}
  → Superposition Config alg
  → AmplitudeAlg.A alg
Z alg ψ = 𝔼 alg ψ (λ _ → 1)
```

The quantum bridge theorem does **not** require Z ≠ 0 — it proves the numerator equality ⟨S⟩ = ⟨L⟩ without dividing.

---

## 5. The Quantum Bridge Theorem (Theorem 7)

### 5.1 Statement

```agda
-- Quantum/QuantumBridge.agda

quantum-bridge :
  (alg : AmplitudeAlg) {Config : Type₀}
  → (ψ : Superposition Config alg)
  → (S L : Config → ℕ)
  → ((ω : Config) → S ω ≡ L ω)
  → 𝔼 alg ψ S ≡ 𝔼 alg ψ L
```

**Informal:** For any finite superposition ψ of configurations with amplitudes in any algebra A, if the boundary observable S and bulk observable L agree at every microstate, then their expected values agree across the superposition.

### 5.2 Proof — 5 Lines

```agda
quantum-bridge alg []             S L eq = refl
quantum-bridge alg ((ω , α) ∷ ψ) S L eq =
  cong₂ _+A_
    (cong (_·A_ α) (cong embedℕ (eq ω)))
    (quantum-bridge alg ψ S L eq)
  where open AmplitudeAlg alg
```

**Base case** (empty list): `𝔼 alg [] S = 0A = 𝔼 alg [] L`. The proof is `refl`.

**Inductive step** ((ω, α) ∷ ψ): Both sides unfold to `(α ·A embedℕ (O ω)) +A (𝔼 alg ψ O)` for O = S and O = L respectively. We use `cong₂ _+A_` to decompose:

1. **Left argument:** `cong (_·A_ α) (cong embedℕ (eq ω))` pushes the pointwise equality `S ω ≡ L ω` through `embedℕ` (lifting to A) and then through `α ·A_` (scaling by the amplitude).

2. **Right argument:** `quantum-bridge alg ψ S L eq` is the inductive hypothesis on the tail of the list.

### 5.3 What the Proof Uses

Exactly three Cubical Agda primitives:

- **`refl`** — base case (empty sum = `0A`)
- **`cong`** — push equality through `embedℕ` and `(α ·A_)`
- **`cong₂`** — push equalities through `_+A_`

No ring axioms (commutativity, associativity, distributivity) are used. The proof is pure structural induction on the list. This is the type-theoretic content of the statement that linearity of finite sums is **algebraically trivial**.

### 5.4 Region-Fixed Variant

In the holographic application, the observables take a configuration ω AND a boundary region r. The following variant makes the pattern explicit:

```agda
quantum-bridge-region :
  (alg : AmplitudeAlg) {Config RegionTy : Type₀}
  → (ψ : Superposition Config alg)
  → (S L : Config → RegionTy → ℕ)
  → ((ω : Config) (r : RegionTy) → S ω r ≡ L ω r)
  → (r : RegionTy)
  → 𝔼 alg ψ (λ ω → S ω r) ≡ 𝔼 alg ψ (λ ω → L ω r)
quantum-bridge-region alg ψ S L eq r =
  quantum-bridge alg ψ (λ ω → S ω r) (λ ω → L ω r) (λ ω → eq ω r)
```

For a fixed region r, the per-microstate bridge gives pointwise equality of the ℕ-valued observables `(λ ω → S ω r)` and `(λ ω → L ω r)`, which is exactly what `quantum-bridge` consumes.

---

## 6. The Star Quantum Bridge — Concrete Instantiation

### 6.1 Setup

The concrete instantiation consumes the per-microstate bridge `SL-param-pointwise` from `Bulk/StarChainParam.agda`, which establishes that `S-param w r ≡ L-param w r` for **any** weight function w and **any** region r. Since the spin label is fixed (all bonds carry the Q₈ fundamental representation with dim = 2), the capacity `starQ8Capacity : Bond → ℚ≥0` is independent of the gauge connection.

### 6.2 The Star Quantum Bridge Theorem

```agda
-- Quantum/StarQuantumBridge.agda

star-quantum-bridge :
  (alg : AmplitudeAlg)
  → (ψ : Superposition (GaugeConnection Q₈ Bond) alg)
  → (r : Region)
  → 𝔼 alg ψ (λ ω → S-param starQ8Capacity r)
  ≡ 𝔼 alg ψ (λ ω → L-param starQ8Capacity r)
star-quantum-bridge alg ψ r =
  quantum-bridge alg ψ
    (λ _ → S-param starQ8Capacity r)
    (λ _ → L-param starQ8Capacity r)
    (λ _ → SL-param-pointwise starQ8Capacity r)
```

This is a single application of `quantum-bridge` — the general theorem does all the work.

### 6.3 Concrete Superpositions with Interference

**Two-configuration superposition:**

```agda
ψ₂ : Superposition (GaugeConnection Q₈ Bond) ℤiAmplitude
ψ₂ = (starQ8-i , 1ℤi) ∷ (starQ8-ij , iℤi) ∷ []
```

Configuration `starQ8-i` (bCN0 = i, rest = 1) has amplitude 1+0i. Configuration `starQ8-ij` (bCN0 = i, bCN1 = j, rest = 1) has amplitude 0+1i. At region regN0 (singleton, observable = 2), the expected value is:

```
𝔼[ψ₂, λ _ → 2] = (1+0i)·2 + (0+1i)·2 = (2+0i) + (0+2i) = (2+2i)
```

Both S and L produce (2+2i), verified by `refl`:

```agda
bridge-regN0-is-refl : star-quantum-bridge ℤiAmplitude ψ₂ regN0 ≡ refl
bridge-regN0-is-refl = refl
```

**Three-configuration superposition with destructive interference:**

```agda
ψ₃ : Superposition (GaugeConnection Q₈ Bond) ℤiAmplitude
ψ₃ = (starQ8-i , 1ℤi) ∷ (starQ8-ij , iℤi) ∷ (starQ8-ji , neg1ℤi) ∷ []
```

The third configuration `starQ8-ji` (bCN0 = j, bCN1 = i) is physically distinct from `starQ8-ij` — it produces a different holonomy (−k instead of +k, by non-commutativity of Q₈). But its amplitude −1 partially cancels the first configuration's amplitude +1.

At regN0 (observable = 2):

```
𝔼[ψ₃, λ _ → 2] = (+1)·2 + (+i)·2 + (−1)·2
                 = (2+0i) + (0+2i) + (−2+0i)
                 = (0+2i)
```

The real parts cancel: (+1)·2 + (−1)·2 = 0. Only the imaginary contribution from the second configuration survives. This is **destructive interference** — the discrete-holographic analogue of quantum-mechanical path cancellation.

Yet ⟨S⟩ = ⟨L⟩ = (0+2i) — the holographic bridge holds **through** the interference:

```agda
bridge-ψ₃-regN0-is-refl :
  star-quantum-bridge ℤiAmplitude ψ₃ regN0 ≡ refl
bridge-ψ₃-regN0-is-refl = refl
```

The bridge proof reduces to `refl` on the closed normal forms because all ingredients — ℤ arithmetic, list recursion, the per-microstate bridge — compute judgmentally on concrete terms.

---

## 7. The Partition Function and Cancellation

The partition function Z = 𝔼[ψ, λ _ → 1] can itself exhibit cancellation:

```agda
check-partition-ψ₃ :
  Z ℤiAmplitude ψ₃ ≡ mkℤi (pos 0) (pos 1)
check-partition-ψ₃ = refl
```

For ψ₃: Z = (+1)·1 + (+i)·1 + (−1)·1 = (1+0i) + (0+1i) + (−1+0i) = (0+1i). The partition function is purely imaginary — a genuine quantum-mechanical phenomenon impossible with ℕ amplitudes.

The quantum bridge theorem is **independent of Z**: it proves the numerator equality 𝔼[ψ,S] ≡ 𝔼[ψ,L] directly, without dividing. The physical "expected value" ⟨O⟩ = 𝔼[ψ,O] / Z is not formalized because constructive division in a general amplitude ring is not available. The theorem remains valid even when Z = 0 (total destructive interference).

---

## 8. Architectural Significance

### 8.1 Orthogonality

The quantum layer is orthogonal to and independent of all other enrichment layers:

- **The holographic bridge** ([03-holographic-bridge.md](03-holographic-bridge.md)): The bridge operates per-microstate (for a fixed weight function); the quantum layer lifts it across superpositions.
- **Curvature** ([04-discrete-geometry.md](04-discrete-geometry.md)): Curvature enriches individual spatial slices; the quantum layer sums over configuration space.
- **Gauge matter** ([05-gauge-theory.md](05-gauge-theory.md)): The gauge infrastructure provides concrete configurations (Q₈ connections); the quantum layer superimposes them.
- **Causal structure** ([06-causal-structure.md](06-causal-structure.md)): The causal poset sequences spatial slices in time; the quantum layer operates within a single time slice's configuration space.

### 8.2 The Bridge Is Consumed, Not Modified

The quantum bridge consumes `SL-param-pointwise` (the per-microstate RT correspondence from `Bulk/StarChainParam.agda`) as a hypothesis. It does not modify, extend, or depend on the internal structure of this proof — only on its type signature `(w : Bond → ℚ≥0) (r : Region) → S-param w r ≡ L-param w r`.

This means any improvement to the per-microstate bridge (e.g., extending to larger patches, different tilings, or non-unit capacities) automatically lifts to the superposition level without touching the quantum layer.

### 8.3 The Proof Is Algebraically Trivial

The quantum structure of the discrete holographic correspondence is a consequence of the **linearity of finite sums**, composed with the per-microstate bridge. The 5-line proof term adds no mathematical complexity to the formalization — it is a thin inductive wrapper over existing infrastructure. The physics of superposition adds no proof-theoretic cost.

---

## 9. What This Does and Does Not Prove

### Proven (constructive, machine-checked)

- For **any** finite superposition of configurations, weighted by **any** amplitude algebra, ⟨S⟩ = ⟨L⟩ — the expected boundary entropy equals the expected bulk chain length.
- The proof works for ℕ (classical counting), ℤ[i] (quantum interference), or any future amplitude type (cyclotomic integers, constructive ℂ, etc.).
- Concrete 2- and 3-configuration Q₈ superpositions with ℤ[i] amplitudes are verified, including destructive interference (partial amplitude cancellation).
- The proof holds even when the partition function Z = 0 (total cancellation).
- The bridge proof reduces to `refl` on all tested closed normal forms.

### NOT proven

- **No infinite-dimensional path integrals.** The configuration space is finite (|G|^|B| for finite G and finite B). The passage to continuous gauge groups and infinite lattices requires constructive measure theory.
- **No entanglement entropy from reduced density matrices.** The min-cut entropy S_cut is a combinatorial proxy for von Neumann entropy S_vN = −Tr(ρ_A log ρ_A). Deriving S_cut = S_vN for perfect-tensor states requires formalizing tensor contraction, partial trace, and the spectral theorem.
- **No Hamiltonian dynamics on the superposition.** The superposition ψ is a static list. Evolving it by a unitary U = e^{−iHt} requires constructive complex exponentials and self-adjoint operators on finite-dimensional spaces.

These obstacles delimit the boundary between the *combinatorial core* of the holographic correspondence (which is fully formalizable) and the *analytic superstructure* of quantum mechanics (which requires infrastructure beyond the current state of constructive proof assistants).

---

## 10. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorem 7 |
| HoTT foundations (cong, cong₂, funExt) | [`formal/02-foundations.md`](02-foundations.md) |
| Holographic bridge (per-microstate S = L) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Gauge theory (Q₈, connections, holonomy) | [`formal/05-gauge-theory.md`](05-gauge-theory.md) |
| Causal structure (orthogonal enrichment) | [`formal/06-causal-structure.md`](06-causal-structure.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Dynamics (parameterized step invariance) | [`formal/10-dynamics.md`](10-dynamics.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Physics dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Translation problem (five walls) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Historical development (§14 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §14 |