{-# OPTIONS --cubical --safe --guardedness #-}

module Quantum.QuantumBridge where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc)
  renaming (_+_ to _+ℕ_ ; _·_ to _·ℕ_)
open import Cubical.Data.List  using (List ; [] ; _∷_)
open import Cubical.Data.Sigma using (_×_)
open import Cubical.Data.Int   using (pos)

open import Quantum.AmplitudeAlg
open import Quantum.Superposition


-- ════════════════════════════════════════════════════════════════════
--  §1.  The Quantum Bridge Theorem
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Quantum Holographic Bridge).
--
--  Let  ψ  be any finite superposition of configurations with
--  amplitudes in a type  A  equipped with addition, scaling, zero,
--  and an embedding  ι : ℕ → A  (an AmplitudeAlg instance).
--
--  If the discrete Ryu–Takayanagi correspondence holds at every
--  microstate — i.e., for every configuration  ω :
--
--      S(ω) ≡ L(ω)    (as ℕ values)
--
--  then the expected values match across the superposition:
--
--      𝔼[ψ, S] ≡ 𝔼[ψ, L]    (as A values)
--
--  The proof is structural induction on the list  ψ :
--
--    Base case (empty list):
--      𝔼 alg [] S  =  0A  =  𝔼 alg [] L
--      Proof:  refl
--
--    Inductive step ((ω , α) ∷ ψ):
--      𝔼 alg ((ω,α) ∷ ψ) S
--        = (α ·A embedℕ (S ω)) +A (𝔼 alg ψ S)
--
--      𝔼 alg ((ω,α) ∷ ψ) L
--        = (α ·A embedℕ (L ω)) +A (𝔼 alg ψ L)
--
--      We use  cong₂ _+A_  with:
--        (a) cong (α ·A_) (cong embedℕ (eq ω))
--            pushes  S ω ≡ L ω  through  embedℕ  then  α ·A_
--        (b) quantum-bridge alg ψ S L eq
--            is the inductive hypothesis on the tail
--
--  The proof is 5 lines.  It requires NO ring axioms on A —
--  only the automatic congruence properties (cong, cong₂) of
--  functions in Cubical Agda.  It is:
--
--    • Amplitude-polymorphic:  works for ℕ, ℤ[i], ℚ, ℤ[ζₙ], or any A
--    • Topology-agnostic:     works for any Config type
--    • Gauge-group-agnostic:  works for any per-microstate bridge
--
--  This is **Theorem 7** (Quantum Superposition Bridge) in the
--  canonical theorem registry (docs/formal/01-theorems.md).
--
--  Architectural role:
--    This is a Tier 2 module in the Quantum layer.  The quantum
--    layer is purely additive — it adds a single thin inductive
--    lemma on top of the full existing infrastructure without
--    modifying any existing module.  The quantum bridge consumes
--    per-microstate agreement (e.g., SL-param-pointwise from
--    Bulk/StarChainParam.agda) as a hypothesis and lifts it across
--    any finite superposition.
--    See docs/getting-started/architecture.md for the module
--    dependency DAG.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §5
--                              (Quantum Bridge Theorem — statement,
--                               proof, and what it uses)
--    docs/formal/07-quantum-superposition.md §2
--                              (Amplitude Polymorphism — why no
--                               ring axioms are needed)
--    docs/formal/07-quantum-superposition.md §8
--                              (Architectural Significance —
--                               orthogonality with other layers)
--    docs/formal/01-theorems.md §Thm 7
--                              (Quantum Superposition Bridge —
--                               theorem registry entry)
--    docs/formal/02-foundations.md §2.4
--                              (cong and cong₂ in Cubical Agda)
--    docs/getting-started/architecture.md
--                              (module dependency DAG)
--    docs/reference/module-index.md
--                              (module description)
--    docs/historical/development-docs/10-frontier.md §14
--                              (original development plan for
--                               the quantum layer)
-- ════════════════════════════════════════════════════════════════════

quantum-bridge :
  (alg : AmplitudeAlg) {Config : Type₀}
  → (ψ : Superposition Config alg)
  → (S L : Config → ℕ)
  → ((ω : Config) → S ω ≡ L ω)
  → 𝔼 alg ψ S ≡ 𝔼 alg ψ L
quantum-bridge alg []             S L eq = refl
quantum-bridge alg ((ω , α) ∷ ψ) S L eq =
  cong₂ _+A_
    (cong (_·A_ α) (cong embedℕ (eq ω)))
    (quantum-bridge alg ψ S L eq)
  where open AmplitudeAlg alg


-- ════════════════════════════════════════════════════════════════════
--  §2.  Region-Fixed Variant
-- ════════════════════════════════════════════════════════════════════
--
--  In the holographic application, the observables take a
--  configuration ω AND a boundary region r:
--
--    S(cap(ω), r)  and  L(cap(ω), r)
--
--  The per-microstate bridge is:
--
--    ∀ ω r → S(cap(ω), r) ≡ L(cap(ω), r)
--
--  For a FIXED region r, this gives pointwise equality of the
--  ℕ-valued observables  (λ ω → S(cap(ω), r))  and
--  (λ ω → L(cap(ω), r)) , which is exactly what quantum-bridge
--  consumes.
--
--  The following variant makes this pattern explicit: given a
--  region type and per-microstate pointwise bridge for all regions,
--  produce the superposition-level bridge for each region.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §5.4
--                              (Region-Fixed Variant)
-- ════════════════════════════════════════════════════════════════════

quantum-bridge-region :
  (alg : AmplitudeAlg) {Config RegionTy : Type₀}
  → (ψ : Superposition Config alg)
  → (S L : Config → RegionTy → ℕ)
  → ((ω : Config) (r : RegionTy) → S ω r ≡ L ω r)
  → (r : RegionTy)
  → 𝔼 alg ψ (λ ω → S ω r) ≡ 𝔼 alg ψ (λ ω → L ω r)
quantum-bridge-region alg ψ S L eq r =
  quantum-bridge alg ψ (λ ω → S ω r) (λ ω → L ω r) (λ ω → eq ω r)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Regression Tests — ℕ Amplitude (Classical Counting)
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that quantum-bridge produces the expected
--  results on concrete superpositions with ℕ amplitudes (the
--  "no interference" classical case).
--
--  The pointwise bridge  eq  is  λ _ → refl  (both observables
--  are the same function), so the quantum bridge should also
--  produce  refl  after normalization.
-- ════════════════════════════════════════════════════════════════════

private

  -- Trivial observable:  O(n) = suc n
  O-test : ℕ → ℕ
  O-test n = suc n

  -- ── Empty superposition ──────────────────────────────────────
  --
  --  𝔼[[], S] = 0 = 𝔼[[], L]
  --  The bridge is  refl  (base case).

  check-empty : quantum-bridge ℕAmplitude {ℕ} [] O-test O-test (λ _ → refl)
                ≡ refl
  check-empty = refl

  -- ── Single-element superposition ─────────────────────────────
  --
  --  ψ = [(0 , 3)]
  --  𝔼[ψ, O] = 3 · 1 + 0 = 3  for both S and L.
  --  The bridge should reduce to  refl .

  ψ₁ : Superposition ℕ ℕAmplitude
  ψ₁ = (0 , 3) ∷ []

  check-single : 𝔼 ℕAmplitude ψ₁ O-test ≡ 3
  check-single = refl

  check-bridge-single :
    quantum-bridge ℕAmplitude ψ₁ O-test O-test (λ _ → refl) ≡ refl
  check-bridge-single = refl

  -- ── Two-element superposition ────────────────────────────────
  --
  --  ψ = [(0 , 3) , (1 , 5)]
  --  𝔼[ψ, O] = 3 · 1 + (5 · 2 + 0) = 3 + 10 = 13

  ψ₂ : Superposition ℕ ℕAmplitude
  ψ₂ = (0 , 3) ∷ (1 , 5) ∷ []

  check-two : 𝔼 ℕAmplitude ψ₂ O-test ≡ 13
  check-two = refl

  check-bridge-two :
    quantum-bridge ℕAmplitude ψ₂ O-test O-test (λ _ → refl) ≡ refl
  check-bridge-two = refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  Regression Tests — ℤ[i] Amplitude (Quantum Interference)
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that quantum-bridge works correctly with
--  Gaussian integer amplitudes, including the interference case
--  where amplitudes cancel.
-- ════════════════════════════════════════════════════════════════════

private

  -- Observable for testing:  O(n) = suc n
  O-ℤi : ℕ → ℕ
  O-ℤi n = suc n

  -- ── Single-element ℤ[i] superposition ────────────────────────
  --
  --  ψ = [(0 , i)]
  --  𝔼[ψ, O] = i · embedℕ(1) + 0 = i · (1+0i) + (0+0i) = (0+1i) = i

  ψ-i : Superposition ℕ ℤiAmplitude
  ψ-i = (0 , iℤi) ∷ []

  check-ℤi-single : 𝔼 ℤiAmplitude ψ-i O-ℤi ≡ iℤi
  check-ℤi-single = refl

  check-bridge-ℤi :
    quantum-bridge ℤiAmplitude ψ-i O-ℤi O-ℤi (λ _ → refl) ≡ refl
  check-bridge-ℤi = refl

  -- ── Destructive interference ─────────────────────────────────
  --
  --  ψ = [(0 , 1+0i) , (0 , −1+0i)]
  --  𝔼[ψ, O] = (1+0i)·(1+0i) + ((−1+0i)·(1+0i) + (0+0i))
  --           = (1+0i) + (−1+0i) = (0+0i)
  --
  --  The quantum bridge holds even when the expected value is zero
  --  (total destructive interference).

  ψ-cancel : Superposition ℕ ℤiAmplitude
  ψ-cancel = (0 , 1ℤi) ∷ (0 , neg1ℤi) ∷ []

  check-cancel : 𝔼 ℤiAmplitude ψ-cancel O-ℤi ≡ 0ℤi
  check-cancel = refl

  check-bridge-cancel :
    quantum-bridge ℤiAmplitude ψ-cancel O-ℤi O-ℤi (λ _ → refl) ≡ refl
  check-bridge-cancel = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Regression Tests — Distinct Observables
-- ════════════════════════════════════════════════════════════════════
--
--  The most interesting case: S and L are DEFINITIONALLY DISTINCT
--  functions that agree pointwise (propositionally).  This mirrors
--  the actual holographic application where S-param and L-param
--  are defined in separate modules by identical pattern-matching
--  clauses.
-- ════════════════════════════════════════════════════════════════════

private

  -- Two distinct observable functions on a 2-element type
  data TwoConfig : Type₀ where
    cfg0 cfg1 : TwoConfig

  S-obs : TwoConfig → ℕ
  S-obs cfg0 = 1
  S-obs cfg1 = 2

  L-obs : TwoConfig → ℕ
  L-obs cfg0 = 1
  L-obs cfg1 = 2

  -- Pointwise agreement (both return the same values, but are
  -- definitionally distinct functions)
  SL-agree : (ω : TwoConfig) → S-obs ω ≡ L-obs ω
  SL-agree cfg0 = refl
  SL-agree cfg1 = refl

  -- Superposition over TwoConfig with ℕ amplitudes
  ψ-two : Superposition TwoConfig ℕAmplitude
  ψ-two = (cfg0 , 3) ∷ (cfg1 , 5) ∷ []

  -- 𝔼[ψ, S] = 3 · 1 + (5 · 2 + 0) = 3 + 10 = 13
  check-S : 𝔼 ℕAmplitude ψ-two S-obs ≡ 13
  check-S = refl

  -- 𝔼[ψ, L] = 3 · 1 + (5 · 2 + 0) = 3 + 10 = 13
  check-L : 𝔼 ℕAmplitude ψ-two L-obs ≡ 13
  check-L = refl

  -- The quantum bridge theorem connects them
  the-bridge : 𝔼 ℕAmplitude ψ-two S-obs ≡ 𝔼 ℕAmplitude ψ-two L-obs
  the-bridge = quantum-bridge ℕAmplitude ψ-two S-obs L-obs SL-agree


-- ════════════════════════════════════════════════════════════════════
--  §6.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    quantum-bridge :
--      (alg : AmplitudeAlg) {Config : Type₀}
--      → (ψ : Superposition Config alg)
--      → (S L : Config → ℕ)
--      → ((ω : Config) → S ω ≡ L ω)
--      → 𝔼 alg ψ S ≡ 𝔼 alg ψ L
--
--    quantum-bridge-region :
--      (alg : AmplitudeAlg) {Config RegionTy : Type₀}
--      → (ψ : Superposition Config alg)
--      → (S L : Config → RegionTy → ℕ)
--      → ((ω : Config) (r : RegionTy) → S ω r ≡ L ω r)
--      → (r : RegionTy)
--      → 𝔼 alg ψ (λ ω → S ω r) ≡ 𝔼 alg ψ (λ ω → L ω r)
--
--  Proof architecture:
--
--    The proof uses exactly three Cubical Agda primitives:
--      • refl            — base case (empty list)
--      • cong            — push equality through embedℕ and (α ·A_)
--      • cong₂           — push equalities through _+A_
--
--    NO ring axioms (associativity, commutativity, distributivity)
--    are used.  The proof is pure structural induction on the list.
--
--    The where-clause  `open AmplitudeAlg alg`  brings the record
--    fields (_+A_, _·A_, embedℕ) into scope for the inductive case,
--    making the proof term match the pseudocode from
--    docs/formal/07-quantum-superposition.md §5.2 almost verbatim.
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Cubical.Foundations.Prelude  — refl, cong, cong₂, ≡
--      • Cubical.Data.List           — List, [], _∷_
--      • Cubical.Data.Sigma          — _×_
--      • Quantum/AmplitudeAlg.agda   — AmplitudeAlg, ℕAmplitude,
--                                      ℤiAmplitude, ℤ[i] constants
--      • Quantum/Superposition.agda  — Superposition, 𝔼
--
--    The quantum layer is purely additive — it adds a single thin
--    inductive lemma on top of the full existing infrastructure
--    without modifying any existing module.
--
--  Downstream modules:
--
--    src/Quantum/StarQuantumBridge.agda
--      — Instantiation for the 6-tile star + Q₈:
--        consumes  SL-param-pointwise  from  Bulk/StarChainParam.agda
--        as the per-microstate bridge, and applies quantum-bridge
--        to a concrete superposition of Q₈ gauge connections.
--        Verified with 2- and 3-configuration superpositions
--        exhibiting destructive interference (ℤ[i] amplitudes).
--
--  Theorem registry (docs/formal/01-theorems.md §Thm 7):
--
--    ✓  quantum-bridge type-checks, proving
--       𝔼[ψ, S] ≡ 𝔼[ψ, L]  for any superposition  ψ
--       and any amplitude algebra, given the pointwise
--       bridge as a hypothesis.
--
--  Research significance (docs/formal/07-quantum-superposition.md §8):
--
--    1. First machine-checked proof that a holographic correspondence
--       lifts from individual microstates to quantum superpositions.
--
--    2. The "quantum path integral" for a finite lattice gauge theory
--       on a holographic network reduces to a 5-line structural
--       induction on a list, parametric in the amplitude type.
--
--    3. The constructive complex-number obstacle is irrelevant:
--       the proof is amplitude-polymorphic by construction.
--
--    The quantum structure of the discrete holographic correspondence
--    is algebraically trivial: it is a consequence of the linearity
--    of finite sums (cong₂ on _+A_), composed with the per-microstate
--    bridge that the repository already proves.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md
--                        (quantum superposition — full formal treatment)
--    docs/formal/01-theorems.md §Thm 7
--                        (Quantum Superposition Bridge — theorem registry)
--    docs/formal/02-foundations.md §2.4
--                        (cong and cong₂ in Cubical Agda)
--    docs/getting-started/architecture.md
--                        (module dependency DAG — Quantum layer)
--    docs/reference/module-index.md
--                        (module description)
--    docs/physics/holographic-dictionary.md §6
--                        (quantum superposition Agda ↔ physics table)
--    docs/historical/development-docs/10-frontier.md §14
--                        (original development plan for the quantum layer)
-- ════════════════════════════════════════════════════════════════════