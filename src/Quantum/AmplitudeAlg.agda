{-# OPTIONS --cubical --safe --guardedness #-}

module Quantum.AmplitudeAlg where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc)
  renaming (_+_ to _+ℕ_ ; _·_ to _·ℕ_)
open import Cubical.Data.Int
  using (ℤ ; pos ; negsuc ; isSetℤ)
  renaming (_+_ to _+ℤ_ ; -_ to -ℤ_)


-- ════════════════════════════════════════════════════════════════════
--  §1.  AmplitudeAlg — The Amplitude-Polymorphic Interface
-- ════════════════════════════════════════════════════════════════════
--
--  A minimal record capturing the operations needed by the quantum
--  bridge theorem (Theorem 7 in docs/formal/01-theorems.md):
--
--    _+A_    : accumulation  (fold step of the expected value)
--    _·A_    : scaling       (α · ι(O(ω)) in the Boltzmann weight)
--    0A      : zero          (base case of the empty fold)
--    embedℕ  : ℕ → A         (lifts observable values into amplitudes)
--
--  NO ring axioms are required.  The quantum bridge proof uses only
--  cong₂ _+A_ ,  cong (α ·A_) ,  cong embedℕ  — all of which are
--  automatic congruence properties in Cubical Agda for any function.
--  The proof is therefore parametric in A for ANY type admitting
--  these four operations.
--
--  Concrete instances:
--    A = ℕ        :  classical counting (trivial interference)
--    A = ℤ[i]     :  Gaussian integers (quantum interference)
--    A = ℚ        :  statistical mechanics (Boltzmann weights)
--    A = ℤ[ζₙ]    :  cyclotomic integers (general finite QFT)
--
--  The record lives in Type₁ because it stores A : Type₀ as a field.
--
--  Architectural role:
--    This is a Tier 1 (Specification Layer) standalone module with
--    no internal dependencies beyond the cubical library.  It defines
--    the amplitude-polymorphic interface consumed by
--    Quantum/Superposition.agda (the 𝔼 functional) and
--    Quantum/QuantumBridge.agda (the 5-line proof).  It is orthogonal
--    to and independent of all Bridge, Boundary, Bulk, Gauge, and
--    Causal modules.
--    See docs/getting-started/architecture.md for the module
--    dependency DAG.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §2
--                                (amplitude polymorphism — the key insight)
--    docs/formal/07-quantum-superposition.md §4
--                                (expected value as list fold — uses embedℕ)
--    docs/formal/07-quantum-superposition.md §5
--                                (quantum bridge theorem — consumes AmplitudeAlg)
--    docs/formal/01-theorems.md §Thm 7
--                                (Quantum Superposition Bridge — theorem registry)
--    docs/reference/module-index.md
--                                (module description)
--    docs/getting-started/architecture.md
--                                (Specification Layer — module dependency DAG)
-- ════════════════════════════════════════════════════════════════════

record AmplitudeAlg : Type₁ where
  field
    A       : Type₀
    _+A_    : A → A → A
    _·A_    : A → A → A
    0A      : A
    embedℕ  : ℕ → A

  infixl 6 _+A_
  infixl 7 _·A_


-- ════════════════════════════════════════════════════════════════════
--  §2.  ℤ[i] — The Gaussian Integers
-- ════════════════════════════════════════════════════════════════════
--
--  The Gaussian integers ℤ[i] = { a + bi | a, b ∈ ℤ } are the
--  simplest number system supporting quantum interference patterns.
--  They form a ring under componentwise addition and the standard
--  complex multiplication rule:
--
--    (a + bi) + (c + di) = (a + c) + (b + d)i
--    (a + bi) · (c + di) = (ac − bd) + (ad + bc)i
--
--  All operations compute by structural recursion on closed ℤ terms,
--  preserving the judgmental-computation property that powers the
--  refl-based proof architecture of the repository.
--
--  For gauge groups requiring higher roots of unity (e.g., ℤ/nℤ
--  with n > 4), ℤ[i] would be replaced by cyclotomic integers
--  ℤ[ζₙ].  The quantum bridge theorem is indifferent to this
--  choice — it works for any AmplitudeAlg instance.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §3
--                                (constructive amplitude representation)
--    docs/physics/five-walls.md §Wall 2
--                                (infinite-dimensional path integrals —
--                                 the quantum bridge works for finite
--                                 sums only; ℤ[i] is the discrete
--                                 amplitude type that avoids Wall 2)
-- ════════════════════════════════════════════════════════════════════

record ℤ[i] : Type₀ where
  constructor mkℤi
  field
    re : ℤ
    im : ℤ

open ℤ[i]


-- ════════════════════════════════════════════════════════════════════
--  §3.  ℤ Multiplication (local helper)
-- ════════════════════════════════════════════════════════════════════
--
--  Defined locally by sign-based case split to guarantee judgmental
--  computation on all closed ℤ terms.  The four clauses cover
--  all sign combinations:
--
--    pos · pos     = pos (ℕ product)
--    pos · negsuc  = neg (ℕ product)
--    negsuc · pos  = neg (ℕ product)
--    negsuc · negsuc = pos (ℕ product)
--
--  The helper  negℕ  maps  0 ↦ pos 0  and  suc n ↦ negsuc n ,
--  ensuring that  0 · anything = 0  (not  negsuc something).
--
--  Computation traces:
--    pos 2 ·ℤ pos 3     = pos (2 ·ℕ 3)      = pos 6     (= 6)
--    pos 2 ·ℤ negsuc 0  = negℕ (2 ·ℕ 1)     = negsuc 1  (= −2)
--    negsuc 0 ·ℤ pos 3  = negℕ (1 ·ℕ 3)     = negsuc 2  (= −3)
--    negsuc 0 ·ℤ negsuc 0 = pos (1 ·ℕ 1)    = pos 1     (= 1)
-- ════════════════════════════════════════════════════════════════════

private
  negℕ : ℕ → ℤ
  negℕ zero    = pos 0
  negℕ (suc n) = negsuc n

  infixl 7 _·ℤ_

  _·ℤ_ : ℤ → ℤ → ℤ
  pos a    ·ℤ pos b    = pos (a ·ℕ b)
  pos a    ·ℤ negsuc b = negℕ (a ·ℕ suc b)
  negsuc a ·ℤ pos b    = negℕ (suc a ·ℕ b)
  negsuc a ·ℤ negsuc b = pos (suc a ·ℕ suc b)


-- ════════════════════════════════════════════════════════════════════
--  §4.  ℤ[i] Operations
-- ════════════════════════════════════════════════════════════════════
--
--  Addition:       (a + bi) + (c + di) = (a+c) + (b+d)i
--  Multiplication: (a + bi) · (c + di) = (ac−bd) + (ad+bc)i
--  Zero:           0 + 0i
--  Embedding:      n ↦ (pos n) + 0i
--
--  All reduce judgmentally on closed ℤ[i] terms because ℤ addition,
--  negation, and our local _·ℤ_ all compute by structural recursion.
-- ════════════════════════════════════════════════════════════════════

infixl 6 _+ℤi_
infixl 7 _·ℤi_

_+ℤi_ : ℤ[i] → ℤ[i] → ℤ[i]
(mkℤi a b) +ℤi (mkℤi c d) = mkℤi (a +ℤ c) (b +ℤ d)

_·ℤi_ : ℤ[i] → ℤ[i] → ℤ[i]
(mkℤi a b) ·ℤi (mkℤi c d) =
  mkℤi ((a ·ℤ c) +ℤ (-ℤ (b ·ℤ d)))
       ((a ·ℤ d) +ℤ (b ·ℤ c))

0ℤi : ℤ[i]
0ℤi = mkℤi (pos 0) (pos 0)

embedℕ-ℤi : ℕ → ℤ[i]
embedℕ-ℤi n = mkℤi (pos n) (pos 0)


-- ════════════════════════════════════════════════════════════════════
--  §5.  Named Constants for ℤ[i]
-- ════════════════════════════════════════════════════════════════════
--
--  The four units of the Gaussian integers:  1, −1, i, −i.
--
--  These are the fourth roots of unity ζ₄ = {1, i, −1, −i},
--  which generate the group of units of ℤ[i].  For the Q₈ gauge
--  group (the finite SU(2) replacement from Gauge/Q8.agda), the
--  Boltzmann amplitudes  e^{−S_W[ω]}  at each gauge configuration
--  are Gaussian integers constructed from these units.
-- ════════════════════════════════════════════════════════════════════

1ℤi : ℤ[i]
1ℤi = mkℤi (pos 1) (pos 0)

neg1ℤi : ℤ[i]
neg1ℤi = mkℤi (negsuc 0) (pos 0)

iℤi : ℤ[i]
iℤi = mkℤi (pos 0) (pos 1)

negiℤi : ℤ[i]
negiℤi = mkℤi (pos 0) (negsuc 0)


-- ════════════════════════════════════════════════════════════════════
--  §6.  ℤ[i] AmplitudeAlg Instance
-- ════════════════════════════════════════════════════════════════════
--
--  The Gaussian integer amplitude algebra:
--
--    A       = ℤ[i]
--    _+A_    = Gaussian integer addition
--    _·A_    = Gaussian integer multiplication
--    0A      = 0 + 0i
--    embedℕ  = n ↦ (pos n) + 0i
--
--  This instance supports quantum interference: the sum in the
--  expected value functional
--
--    𝔼[ψ, O] = Σᵢ αᵢ · ι(O(ωᵢ))
--
--  performs complex addition of Gaussian-integer amplitudes,
--  allowing cancellation (destructive interference) when
--  amplitudes have opposite signs.
--
--  This is the first of two concrete AmplitudeAlg instances
--  provided in this module.  The second (ℕAmplitude, §7) is the
--  classical counting instance with no interference.  Both are
--  consumed by the quantum bridge theorem
--  (Quantum/QuantumBridge.agda, Theorem 7 in
--  docs/formal/01-theorems.md).
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §2.3
--                                (concrete instances)
--    docs/formal/01-theorems.md §Thm 7
--                                (Quantum Superposition Bridge)
-- ════════════════════════════════════════════════════════════════════

ℤiAmplitude : AmplitudeAlg
ℤiAmplitude .AmplitudeAlg.A       = ℤ[i]
ℤiAmplitude .AmplitudeAlg._+A_    = _+ℤi_
ℤiAmplitude .AmplitudeAlg._·A_    = _·ℤi_
ℤiAmplitude .AmplitudeAlg.0A      = 0ℤi
ℤiAmplitude .AmplitudeAlg.embedℕ  = embedℕ-ℤi


-- ════════════════════════════════════════════════════════════════════
--  §7.  ℕ AmplitudeAlg Instance (Classical Counting)
-- ════════════════════════════════════════════════════════════════════
--
--  The trivial amplitude algebra for classical statistical mechanics:
--
--    A       = ℕ
--    _+A_    = natural number addition
--    _·A_    = natural number multiplication
--    0A      = 0
--    embedℕ  = identity
--
--  When A = ℕ, the expected value functional reduces to a weighted
--  sum with no interference: all amplitudes are non-negative, so
--  no cancellation can occur.  This recovers the classical
--  partition function:
--
--    𝔼[ψ, O] = Σᵢ αᵢ · O(ωᵢ)
--
--  where each αᵢ is a non-negative "multiplicity" or "count."
-- ════════════════════════════════════════════════════════════════════

ℕAmplitude : AmplitudeAlg
ℕAmplitude .AmplitudeAlg.A       = ℕ
ℕAmplitude .AmplitudeAlg._+A_    = _+ℕ_
ℕAmplitude .AmplitudeAlg._·A_    = _·ℕ_
ℕAmplitude .AmplitudeAlg.0A      = 0
ℕAmplitude .AmplitudeAlg.embedℕ  = λ n → n


-- ════════════════════════════════════════════════════════════════════
--  §8.  Regression Tests — ℤ[i] Arithmetic
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that Gaussian integer operations reduce judgmentally
--  on closed constructor terms.  Each test holds by  refl  because
--  all arithmetic (_+ℤ_, -ℤ_, _·ℤ_, and the record constructor)
--  computes by structural recursion on ℤ constructors.
--
--  If any test fails after a library upgrade, it signals that the
--  ℤ arithmetic has changed in a way that breaks judgmental
--  computation — a critical property for the quantum bridge proof.
-- ════════════════════════════════════════════════════════════════════

private

  -- ── ℤ multiplication spot checks ────────────────────────────
  check-ℤmul-pos :  pos 2 ·ℤ pos 3 ≡ pos 6
  check-ℤmul-pos = refl

  check-ℤmul-neg :  pos 2 ·ℤ negsuc 0 ≡ negsuc 1
  check-ℤmul-neg = refl       -- 2 · (−1) = −2 = negsuc 1

  check-ℤmul-neg-neg :  negsuc 0 ·ℤ negsuc 0 ≡ pos 1
  check-ℤmul-neg-neg = refl   -- (−1) · (−1) = 1

  check-ℤmul-zero :  pos 0 ·ℤ negsuc 5 ≡ pos 0
  check-ℤmul-zero = refl      -- 0 · anything = 0

  -- ── ℤ[i] addition ───────────────────────────────────────────

  -- (1 + i) + (2 + 3i) = 3 + 4i
  check-add : (mkℤi (pos 1) (pos 1)) +ℤi (mkℤi (pos 2) (pos 3))
              ≡ mkℤi (pos 3) (pos 4)
  check-add = refl

  -- ── Fundamental quaternion-like identity:  i² = −1 ──────────
  --
  --  (0 + 1·i) · (0 + 1·i)
  --  = (0·0 − 1·1) + (0·1 + 1·0)i
  --  = (0 + (−1)) + (0 + 0)i
  --  = −1 + 0i
  --
  --  Trace in ℤ arithmetic:
  --    re:  (pos 0 ·ℤ pos 0) +ℤ (-ℤ (pos 1 ·ℤ pos 1))
  --       = pos 0 +ℤ (-ℤ pos 1)
  --       = pos 0 +ℤ negsuc 0
  --       = negsuc 0              (by predℤ)
  --    im:  (pos 0 ·ℤ pos 1) +ℤ (pos 1 ·ℤ pos 0)
  --       = pos 0 +ℤ pos 0
  --       = pos 0

  check-i-squared : iℤi ·ℤi iℤi ≡ neg1ℤi
  check-i-squared = refl

  -- ── Norm computation:  (1 + i)(1 − i) = 2 ──────────────────
  --
  --  (1 + i) · (1 + (−1)i)
  --  = (1·1 − 1·(−1)) + (1·(−1) + 1·1)i
  --  = (1 − (−1)) + (−1 + 1)i
  --  = 2 + 0i
  --
  --  Trace:
  --    re:  (pos 1 ·ℤ pos 1) +ℤ (-ℤ (pos 1 ·ℤ negsuc 0))
  --       = pos 1 +ℤ (-ℤ negsuc 0)
  --       = pos 1 +ℤ pos 1
  --       = pos 2
  --    im:  (pos 1 ·ℤ negsuc 0) +ℤ (pos 1 ·ℤ pos 1)
  --       = negsuc 0 +ℤ pos 1
  --       = pos 0

  check-norm : (mkℤi (pos 1) (pos 1)) ·ℤi (mkℤi (pos 1) (negsuc 0))
               ≡ mkℤi (pos 2) (pos 0)
  check-norm = refl

  -- ── Zero is identity for addition ───────────────────────────

  check-zero-add : 0ℤi +ℤi iℤi ≡ iℤi
  check-zero-add = refl

  -- ── embedℕ tests ────────────────────────────────────────────

  check-embed-0 : embedℕ-ℤi 0 ≡ 0ℤi
  check-embed-0 = refl

  check-embed-1 : embedℕ-ℤi 1 ≡ 1ℤi
  check-embed-1 = refl

  check-embed-3 : embedℕ-ℤi 3 ≡ mkℤi (pos 3) (pos 0)
  check-embed-3 = refl

  -- ── Scaling: amplitude · embedded observable ─────────────────
  --
  --  This is the pattern used in the expected value functional:
  --    α ·A embedℕ(O(ω))
  --
  --  For α = i  and  O(ω) = 2:
  --    i · (2 + 0i) = (0·2 − 1·0) + (0·0 + 1·2)i = 0 + 2i

  check-scale : iℤi ·ℤi embedℕ-ℤi 2 ≡ mkℤi (pos 0) (pos 2)
  check-scale = refl

  -- ── Record field access ──────────────────────────────────────

  check-alg-zero : AmplitudeAlg.0A ℤiAmplitude ≡ 0ℤi
  check-alg-zero = refl

  check-alg-embed : AmplitudeAlg.embedℕ ℤiAmplitude 5
                    ≡ mkℤi (pos 5) (pos 0)
  check-alg-embed = refl

  -- ── ℕ instance spot checks ──────────────────────────────────

  check-ℕ-add : AmplitudeAlg._+A_ ℕAmplitude 3 4 ≡ 7
  check-ℕ-add = refl

  check-ℕ-mul : AmplitudeAlg._·A_ ℕAmplitude 3 4 ≡ 12
  check-ℕ-mul = refl

  check-ℕ-embed : AmplitudeAlg.embedℕ ℕAmplitude 5 ≡ 5
  check-ℕ-embed = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    AmplitudeAlg   : Type₁
--                     (record with fields A, _+A_, _·A_, 0A, embedℕ)
--
--    ℤ[i]           : Type₀
--                     (record with fields re, im : ℤ ; constructor mkℤi)
--    _+ℤi_          : ℤ[i] → ℤ[i] → ℤ[i]    (Gaussian addition)
--    _·ℤi_          : ℤ[i] → ℤ[i] → ℤ[i]    (Gaussian multiplication)
--    0ℤi            : ℤ[i]                    (zero: 0 + 0i)
--    1ℤi            : ℤ[i]                    (one:  1 + 0i)
--    neg1ℤi         : ℤ[i]                    (−1 + 0i)
--    iℤi            : ℤ[i]                    (0 + 1i)
--    negiℤi         : ℤ[i]                    (0 − 1i)
--    embedℕ-ℤi      : ℕ → ℤ[i]                (n ↦ n + 0i)
--
--    ℤiAmplitude    : AmplitudeAlg             (ℤ[i] instance)
--    ℕAmplitude     : AmplitudeAlg             (ℕ instance)
--
--  Design decisions:
--
--    1.  The AmplitudeAlg record contains NO ring axioms — only
--        operations.  This is deliberate: the quantum bridge
--        theorem (Theorem 7, docs/formal/01-theorems.md) uses
--        only  cong  and  cong₂ , which are automatic congruence
--        properties of functions in Cubical Agda.  No commutativity,
--        associativity, or distributivity is needed.  The proof is
--        "parametric in the amplitude type" — it works for any type
--        with the four operations.
--
--    2.  ℤ multiplication _·ℤ_ is defined locally (private) by
--        a 4-clause sign-based case split rather than imported
--        from the cubical library.  This ensures:
--        (a) no dependency on the exact module path, which may
--            vary between library versions;
--        (b) judgmental computation on all closed ℤ terms;
--        (c) the regression tests (i² = −1, etc.) hold by refl.
--
--    3.  The ℤ[i] record uses an explicit constructor  mkℤi  for
--        readable concrete Gaussian integer values:
--          mkℤi (pos 2) (pos 3)  represents  2 + 3i .
--
--    4.  Two AmplitudeAlg instances are provided:
--        • ℤiAmplitude (Gaussian integers) — the target for
--          quantum interference and the Q₈ gauge group.
--        • ℕAmplitude (natural numbers) — classical counting,
--          the trivial "no-interference" case.
--
--  Relationship to existing code:
--
--    This module imports ONLY from the cubical library:
--      • Cubical.Foundations.Prelude  — paths, ≡, refl
--      • Cubical.Data.Nat            — ℕ, _+ℕ_, _·ℕ_
--      • Cubical.Data.Int            — ℤ, pos, negsuc, _+ℤ_, -ℤ_
--
--    It does NOT import from any existing src/ module.  The quantum
--    layer is purely additive — it enriches the repository with
--    amplitude-polymorphic superposition infrastructure without
--    modifying the existing bridge, curvature, causal, gauge, or
--    dynamics modules.
--
--  Downstream modules:
--
--    src/Quantum/Superposition.agda      — Superposition type, 𝔼 functional
--    src/Quantum/QuantumBridge.agda      — quantum-bridge theorem (5 lines)
--    src/Quantum/StarQuantumBridge.agda  — instantiation for 6-tile star + Q₈
--
--  Reference:
--    docs/formal/07-quantum-superposition.md
--                    (quantum superposition — full formal treatment)
--    docs/formal/07-quantum-superposition.md §2
--                    (amplitude polymorphism — the AmplitudeAlg interface)
--    docs/formal/07-quantum-superposition.md §3
--                    (the Gaussian integers ℤ[i])
--    docs/formal/01-theorems.md §Thm 7
--                    (Quantum Superposition Bridge — theorem registry)
--    docs/physics/holographic-dictionary.md §6
--                    (quantum superposition Agda ↔ physics table)
--    docs/reference/module-index.md
--                    (module description)
--    docs/getting-started/architecture.md
--                    (Specification Layer — module dependency DAG)
--    docs/historical/development-docs/10-frontier.md §14
--                    (original development plan for the quantum layer)
-- ════════════════════════════════════════════════════════════════════