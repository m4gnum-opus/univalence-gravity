{-# OPTIONS --cubical --safe --guardedness #-}

module Quantum.Superposition where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc)
  renaming (_+_ to _+ℕ_ ; _·_ to _·ℕ_)
open import Cubical.Data.List  using (List ; [] ; _∷_)
open import Cubical.Data.Sigma using (_×_)
open import Cubical.Data.Int   using (pos)

open import Quantum.AmplitudeAlg


-- ════════════════════════════════════════════════════════════════════
--  §1.  Superposition — A finite weighted list of configurations
-- ════════════════════════════════════════════════════════════════════
--
--  A quantum state (superposition) is a finite list of pairs
--  (configuration, amplitude), where:
--
--    • Config is the configuration type (e.g., GaugeConnection G Bond
--      from Gauge/Connection.agda, or any other type representing a
--      "microstate" of the discrete holographic network).
--
--    • A = AmplitudeAlg.A alg  is the amplitude type from the
--      supplied AmplitudeAlg (ℕ for classical counting, ℤ[i] for
--      quantum interference, etc.).
--
--  The "path integral" over this superposition is computed by the
--  𝔼 functional (§2).  For the 6-tile star with Q₈ (|G|=8, |B|=5),
--  the full configuration space has 8⁵ = 32,768 entries — each a
--  term in the finite sum.
--
--  The type is parametric in Config: the Superposition type does not
--  know or care what the configurations are.  It could be gauge
--  connections, spin labels, bond weights, or any other Type₀ value.
--  The quantum bridge theorem (Quantum/QuantumBridge.agda) exploits
--  this parametricity: it proves 𝔼[ψ,S] ≡ 𝔼[ψ,L] for ANY
--  superposition, ANY config type, and ANY amplitude algebra.
--
--  Reference:
--    docs/10-frontier.md §14.4  (Superposition as a List)
--    docs/10-frontier.md §14.9  (module plan)
-- ════════════════════════════════════════════════════════════════════

Superposition : Type₀ → AmplitudeAlg → Type₀
Superposition Config alg = List (Config × AmplitudeAlg.A alg)


-- ════════════════════════════════════════════════════════════════════
--  §2.  𝔼 — The Expected-Value Functional (Finite Path Integral)
-- ════════════════════════════════════════════════════════════════════
--
--  The expected value of a ℕ-valued observable O under a
--  superposition ψ is the finite sum:
--
--    𝔼[ψ, O] = foldr (λ (ω, α) acc → α ·A embedℕ(O(ω)) +A acc) 0A ψ
--
--  Implemented as structural recursion on the list:
--
--    𝔼 alg []              O  =  0A
--    𝔼 alg ((ω , α) ∷ ψ)  O  =  (α ·A embedℕ (O ω)) +A (𝔼 alg ψ O)
--
--  Critical property for the quantum bridge:
--
--    The RHS of the cons case unfolds JUDGMENTALLY to
--    _+A_ (α ·A embedℕ (O ω)) (𝔼 alg ψ O) .  This means
--    cong₂ _+A_  can decompose the inductive step of the quantum
--    bridge proof without needing any ring axiom or reduction lemma.
--
--    The base case (empty list) returns  0A  on both sides, so
--    the proof is  refl .
--
--  In the physics interpretation:
--
--    • O is an observable (e.g., S-cut or L-min from the holographic
--      bridge, mapping a gauge connection to a min-cut value).
--
--    • embedℕ lifts the ℕ-valued observable into the amplitude ring.
--
--    • α ·A embedℕ(O(ω))  is the Boltzmann-weighted contribution of
--      configuration ω:  the amplitude α times the embedded
--      observable value.
--
--    • The fold accumulates these contributions left-to-right into
--      a single amplitude-ring element: the path integral.
--
--  Reference:
--    docs/10-frontier.md §14.4  (Expected Value as List Fold)
--    docs/10-frontier.md §14.5  (Quantum Bridge Theorem — uses 𝔼)
-- ════════════════════════════════════════════════════════════════════

𝔼 : (alg : AmplitudeAlg) {Config : Type₀}
   → Superposition Config alg
   → (Config → ℕ)
   → AmplitudeAlg.A alg
𝔼 alg []              O = AmplitudeAlg.0A alg
𝔼 alg ((ω , α) ∷ ψ)  O =
  AmplitudeAlg._+A_ alg
    (AmplitudeAlg._·A_ alg α (AmplitudeAlg.embedℕ alg (O ω)))
    (𝔼 alg ψ O)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Z — The Partition Function
-- ════════════════════════════════════════════════════════════════════
--
--  The normalization constant (partition function) is the expected
--  value of the constant observable  λ ω → 1 :
--
--    Z = 𝔼[ψ, λ ω. 1] = Σᵢ αᵢ · embedℕ(1)
--
--  For A = ℕ (classical counting), Z is the sum of all weights.
--  For A = ℤ[i] (quantum interference), Z may exhibit cancellation
--  (destructive interference between amplitudes of opposite sign).
--
--  The quantum bridge theorem does NOT require Z ≠ 0 — it proves
--  the numerator equality  𝔼[ψ,S] ≡ 𝔼[ψ,L]  without dividing.
--  The physical "expected value" ⟨O⟩ = 𝔼[ψ,O] / Z is not
--  formalized here because constructive division in a general
--  amplitude ring is not available.
--
--  Reference:
--    docs/10-frontier.md §14.4  (Partition Function definition)
-- ════════════════════════════════════════════════════════════════════

Z : (alg : AmplitudeAlg) {Config : Type₀}
  → Superposition Config alg
  → AmplitudeAlg.A alg
Z alg ψ = 𝔼 alg ψ (λ _ → 1)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Regression Tests — ℕ Amplitude (Classical Counting)
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that 𝔼 and Z compute correctly on concrete
--  superpositions with ℕ amplitudes (classical statistical mechanics,
--  no interference).
--
--  Config type:  ℕ  (a trivial placeholder — the quantum bridge
--  theorem is parametric in Config, so any type works for testing).
--
--  Observable:  O(n) = suc n  (i.e., n + 1)
--
--  All tests hold by  refl  because ℕ addition and multiplication
--  compute by structural recursion on closed numerals.
-- ════════════════════════════════════════════════════════════════════

private

  -- Trivial observable for testing:  O(n) = n + 1
  O-test : ℕ → ℕ
  O-test n = suc n

  -- ── Empty superposition ──────────────────────────────────────
  --
  --  𝔼[[], O] = 0   (the zero of ℕ)

  check-empty : 𝔼 ℕAmplitude {ℕ} [] O-test ≡ 0
  check-empty = refl

  -- ── Single-element superposition ─────────────────────────────
  --
  --  ψ = [(0 , 3)]
  --  𝔼[ψ, O] = 3 · O(0) + 0
  --           = 3 · suc 0 + 0
  --           = 3 · 1 + 0
  --           = 3

  ψ₁ : Superposition ℕ ℕAmplitude
  ψ₁ = (0 , 3) ∷ []

  check-single : 𝔼 ℕAmplitude ψ₁ O-test ≡ 3
  check-single = refl

  -- ── Two-element superposition ────────────────────────────────
  --
  --  ψ = [(0 , 3) , (1 , 5)]
  --  𝔼[ψ, O] = 3 · O(0) + (5 · O(1) + 0)
  --           = 3 · 1 + (5 · 2 + 0)
  --           = 3 + 10
  --           = 13

  ψ₂ : Superposition ℕ ℕAmplitude
  ψ₂ = (0 , 3) ∷ (1 , 5) ∷ []

  check-two : 𝔼 ℕAmplitude ψ₂ O-test ≡ 13
  check-two = refl

  -- ── Three-element superposition ──────────────────────────────
  --
  --  ψ = [(0 , 2) , (1 , 3) , (2 , 1)]
  --  𝔼[ψ, O] = 2 · O(0) + (3 · O(1) + (1 · O(2) + 0))
  --           = 2 · 1 + (3 · 2 + (1 · 3 + 0))
  --           = 2 + (6 + 3)
  --           = 2 + 9
  --           = 11

  ψ₃ : Superposition ℕ ℕAmplitude
  ψ₃ = (0 , 2) ∷ (1 , 3) ∷ (2 , 1) ∷ []

  check-three : 𝔼 ℕAmplitude ψ₃ O-test ≡ 11
  check-three = refl

  -- ── Partition function test ──────────────────────────────────
  --
  --  Z[ψ₂] = 𝔼[ψ₂, λ _ → 1]
  --         = 3 · 1 + (5 · 1 + 0)
  --         = 3 + 5
  --         = 8

  check-Z : Z ℕAmplitude ψ₂ ≡ 8
  check-Z = refl

  -- ── Identity observable ──────────────────────────────────────
  --
  --  With O(n) = n  (identity, no shift):
  --  ψ₂ = [(0 , 3) , (1 , 5)]
  --  𝔼[ψ₂, id] = 3 · 0 + (5 · 1 + 0) = 0 + 5 = 5

  check-id-obs : 𝔼 ℕAmplitude ψ₂ (λ n → n) ≡ 5
  check-id-obs = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Regression Tests — ℤ[i] Amplitude (Quantum Interference)
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that 𝔼 computes correctly with Gaussian
--  integer amplitudes, including the interference pattern that
--  arises when amplitudes have complex phases.
--
--  Config type:  ℕ  (trivial placeholder for testing)
--  Observable:   O(n) = suc n  (i.e., n + 1)
--
--  All tests hold by  refl  because Gaussian integer arithmetic
--  (_+ℤi_, _·ℤi_, embedℕ-ℤi) reduces judgmentally on closed
--  ℤ terms — the same property verified in the AmplitudeAlg
--  regression tests (i² = −1, (1+i)(1−i) = 2, etc.).
-- ════════════════════════════════════════════════════════════════════

private

  -- ── Single-element ℤ[i] superposition ────────────────────────
  --
  --  ψ = [(0 , i)]
  --  𝔼[ψ, O] = i · embedℕ(O(0)) + 0
  --           = i · embedℕ(1) + 0
  --           = i · (1 + 0i) + (0 + 0i)
  --           = (0 + 1i) + (0 + 0i)
  --           = (0 + 1i)               = i

  ψ-i : Superposition ℕ ℤiAmplitude
  ψ-i = (0 , iℤi) ∷ []

  check-ℤi-single : 𝔼 ℤiAmplitude ψ-i O-test ≡ iℤi
  check-ℤi-single = refl

  -- ── Two-element ℤ[i] superposition ───────────────────────────
  --
  --  ψ = [(0 , 1+0i) , (1 , 0+1i)]
  --  𝔼[ψ, O] = (1+0i) · embedℕ(1) + ((0+1i) · embedℕ(2) + (0+0i))
  --           = (1+0i) · (1+0i) + ((0+1i) · (2+0i) + (0+0i))
  --           = (1+0i) + ((0+2i) + (0+0i))
  --           = (1+0i) + (0+2i)
  --           = (1+2i)
  --
  --  This is a genuine superposition with both real and imaginary
  --  amplitudes contributing — the type-theoretic content of
  --  quantum interference in the finite path integral.

  ψ-ℤi₂ : Superposition ℕ ℤiAmplitude
  ψ-ℤi₂ = (0 , 1ℤi) ∷ (1 , iℤi) ∷ []

  check-ℤi-two : 𝔼 ℤiAmplitude ψ-ℤi₂ O-test ≡ mkℤi (pos 1) (pos 2)
  check-ℤi-two = refl

  -- ── Destructive interference ─────────────────────────────────
  --
  --  ψ = [(0 , 1+0i) , (0 , −1+0i)]
  --
  --  Two configurations at the SAME point (config = 0) with
  --  opposite amplitudes:  1 and −1.
  --
  --  𝔼[ψ, O] = (1+0i) · embedℕ(1) + ((−1+0i) · embedℕ(1) + (0+0i))
  --           = (1+0i) + ((−1+0i) + (0+0i))
  --           = (1+0i) + (−1+0i)
  --           = (0+0i)                   = 0  ← CANCELLED!
  --
  --  This demonstrates destructive interference:  two terms with
  --  equal magnitudes but opposite signs cancel to zero in the
  --  path integral.  This is impossible with ℕ amplitudes (where
  --  all weights are non-negative) and is the fundamental reason
  --  quantum mechanics requires complex amplitudes.

  ψ-cancel : Superposition ℕ ℤiAmplitude
  ψ-cancel = (0 , 1ℤi) ∷ (0 , neg1ℤi) ∷ []

  check-cancel : 𝔼 ℤiAmplitude ψ-cancel O-test ≡ 0ℤi
  check-cancel = refl

  -- ── Partition function with ℤ[i] ─────────────────────────────
  --
  --  Z[ψ-ℤi₂] = 𝔼[ψ-ℤi₂, λ _ → 1]
  --            = (1+0i) · (1+0i) + ((0+1i) · (1+0i) + (0+0i))
  --            = (1+0i) + ((0+1i) + (0+0i))
  --            = (1+0i) + (0+1i)
  --            = (1+1i)

  check-Z-ℤi : Z ℤiAmplitude ψ-ℤi₂ ≡ mkℤi (pos 1) (pos 1)
  check-Z-ℤi = refl

  -- ── Partition function: destructive interference ─────────────
  --
  --  Z[ψ-cancel] = 𝔼[ψ-cancel, λ _ → 1]
  --              = (1+0i) · (1+0i) + ((−1+0i) · (1+0i) + (0+0i))
  --              = (1+0i) + (−1+0i)
  --              = (0+0i)                = 0  ← Total cancellation!
  --
  --  The partition function itself can be zero when amplitudes
  --  cancel completely.  This is the quantum-mechanical case where
  --  the normalization breaks down — the expected value ⟨O⟩ = 𝔼/Z
  --  is undefined.  The quantum bridge theorem does NOT divide by Z,
  --  so it remains valid even in this case.

  check-Z-cancel : Z ℤiAmplitude ψ-cancel ≡ 0ℤi
  check-Z-cancel = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  𝔼 with Constant Observable
-- ════════════════════════════════════════════════════════════════════
--
--  A useful property: when the observable is constant (O(ω) = k
--  for all ω), the expected value factors as  Z · embedℕ(k) .
--  This is NOT proven here (it would require ring axioms on A,
--  which the AmplitudeAlg record deliberately omits), but it is
--  verified on concrete examples by refl.
-- ════════════════════════════════════════════════════════════════════

private

  -- Constant observable O(ω) = 2 on a ℕ superposition:
  --  ψ₂ = [(0, 3), (1, 5)]
  --  𝔼[ψ₂, λ _ → 2] = 3 · 2 + (5 · 2 + 0) = 6 + 10 = 16
  --  Z · embedℕ(2) = 8 · 2 = 16  ✓

  check-const-obs : 𝔼 ℕAmplitude ψ₂ (λ _ → 2) ≡ 16
  check-const-obs = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    Superposition : Type₀ → AmplitudeAlg → Type₀
--                    (type alias for  List (Config × A) )
--
--    𝔼             : (alg : AmplitudeAlg) {Config : Type₀}
--                    → Superposition Config alg
--                    → (Config → ℕ)
--                    → AmplitudeAlg.A alg
--                    (expected-value functional — the finite path integral)
--
--    Z              : (alg : AmplitudeAlg) {Config : Type₀}
--                    → Superposition Config alg
--                    → AmplitudeAlg.A alg
--                    (partition function — 𝔼 with constant observable 1)
--
--  Design decisions:
--
--    1.  𝔼 is defined by structural recursion on the List, not by
--        Cubical.Data.List.foldr.  This ensures that the definitional
--        unfolding in the cons case is exactly the expression:
--
--          _+A_ (_·A_ α (embedℕ (O ω))) (𝔼 alg ψ O)
--
--        which the quantum bridge proof decomposes via  cong₂ _+A_ .
--        Using the library's foldr would require an eta-expansion
--        step that might not reduce judgmentally.
--
--    2.  The Config type is an implicit (curly-brace) parameter of 𝔼,
--        inferred from the superposition ψ.  This avoids verbose type
--        annotations at every call site.  The quantum bridge theorem
--        explicitly binds Config as a function argument for clarity.
--
--    3.  The observable O : Config → ℕ is ℕ-valued (not A-valued)
--        because the physical observables (min-cut entropy, chain
--        length) in this repository are ℕ-valued lookup functions.
--        The  embedℕ  field of AmplitudeAlg lifts these into the
--        amplitude ring.  A future extension could generalize to
--        A-valued observables, but the quantum bridge theorem does
--        not require this.
--
--    4.  The fold direction (right fold, accumulating from the
--        empty list) matches §14.4 of docs/10-frontier.md.  The
--        choice is cosmetic because the quantum bridge proof uses
--        structural induction on the list, not fold laws.
--
--    5.  No ring axioms are assumed.  The destructive-interference
--        test (check-cancel) demonstrates that 𝔼 can produce zero
--        even on a non-empty superposition — this is correct
--        quantum-mechanical behavior and does not violate any
--        property used by the quantum bridge theorem.
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Cubical.Foundations.Prelude  — paths, ≡, refl
--      • Cubical.Data.Nat            — ℕ, suc
--      • Cubical.Data.List           — List, [], _∷_
--      • Cubical.Data.Sigma          — _×_
--      • Cubical.Data.Int            — pos  (for ℤ[i] test values)
--      • Quantum/AmplitudeAlg.agda   — AmplitudeAlg, ℤiAmplitude,
--                                      ℕAmplitude, ℤ[i], mkℤi,
--                                      1ℤi, iℤi, neg1ℤi, 0ℤi
--
--    The quantum layer is purely additive — it enriches the
--    repository with amplitude-polymorphic superposition
--    infrastructure without modifying any existing module.
--
--  Downstream modules:
--
--    src/Quantum/QuantumBridge.agda      — quantum-bridge theorem
--                                          (5 lines, uses 𝔼)
--    src/Quantum/StarQuantumBridge.agda  — instantiation for the
--                                          6-tile star + Q₈
--
--  Exit criterion contribution (§14.10 of docs/10-frontier.md):
--
--    This module provides the Superposition type and the 𝔼
--    functional needed by exit criterion items 2–4.  The type
--    𝔼[ψ, S] ≡ 𝔼[ψ, L]  is the statement of the quantum bridge
--    theorem, proven in QuantumBridge.agda using the definitions
--    from this module.
--
--    The regression tests verify that 𝔼 reduces by  refl  on
--    closed ℤ[i] superpositions (partial exit criterion item 4).
-- ════════════════════════════════════════════════════════════════════