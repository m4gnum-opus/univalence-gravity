{-# OPTIONS --cubical --safe --guardedness #-}

module Gauge.FiniteGroup where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.HLevels
open import Cubical.Relation.Nullary
  using (Dec ; yes ; no ; Discrete ; Discrete→isSet)
open import Cubical.Data.Empty using (⊥)


-- ════════════════════════════════════════════════════════════════════
--  FiniteGroup — Group axioms verified by finite case split
-- ════════════════════════════════════════════════════════════════════
--
--  A finite group in the sense of this project: a Type₀ carrier
--  equipped with group operations, decidable equality, a proof
--  that the carrier is a set (h-level 2), and the standard group
--  axioms.
--
--  The carrier is a field of the record (not a parameter), so the
--  record lives in Type₁.
--
--  Design decisions:
--
--    1.  isSetCarrier is included for h-level discipline.  Every
--        downstream construction (GaugeConnection, Holonomy,
--        ConjugacyClass) operates on functions into the carrier
--        (e.g., ω : Bond → G.Carrier), and the function spaces
--        must be sets for the enriched bridge architecture to work.
--        isSet of the function space follows from isSet of the
--        codomain via  isOfHLevelΠ 2 .
--
--    2.  Decidable equality (_≟_) is needed for ParticleDefect
--        (Gauge/Holonomy.agda).  A defect at face f is
--        ¬ (holonomy ω f ≡ ε) , which is a decidable proposition
--        when equality on the carrier is decidable.  Given a
--        concrete connection and a concrete face, the Agda
--        type-checker can evaluate whether a defect exists.
--
--    3.  The inverse is named  inv  (rather than  _⁻¹ ) for
--        parsing safety.  Downstream modules can define
--        superscript notation locally if desired.
--
--    4.  The axioms are stated with explicit universal quantifiers
--        (rather than implicit arguments) to match the style of
--        Subadditive and Monotone in Bridge/FullEnrichedStarObs.agda,
--        enabling isPropΠ to apply directly for h-level arguments.
--
--  For finite groups with elements defined as constructors of a
--  data type, all axioms are verified by exhaustive case split on
--  closed constructor terms, with every case holding by  refl .
--  This requires zero smooth analysis and zero constructive ℂ —
--  exactly as described in §13.4 of docs/10-frontier.md.
--
--  Downstream modules:
--    src/Gauge/ZMod.agda          — ℤ/nℤ instances (n = 2, 3, ...)
--    src/Gauge/Q8.agda            — Quaternion group Q₈ instance
--    src/Gauge/Connection.agda    — GaugeConnection : Bond → Carrier
--    src/Gauge/Holonomy.agda      — holonomy, isFlat, ParticleDefect
--    src/Gauge/ConjugacyClass.agda — particle species classification
--    src/Gauge/RepCapacity.agda   — SpinLabel, dim functor
--
--  Reference:
--    docs/10-frontier.md §13.1   (Goal)
--    docs/10-frontier.md §13.4   (finite subgroup replacement)
--    docs/10-frontier.md §13.7   (three-layer architecture)
--    docs/10-frontier.md §13.8   (module plan)
--    docs/10-frontier.md §13.9   (Phase M.0)
--    docs/10-frontier.md §13.12  (exit criterion, item 1)
-- ════════════════════════════════════════════════════════════════════

record FiniteGroup : Type₁ where
  field
    -- ── Carrier and operations ──────────────────────────────────
    Carrier      : Type₀
    ε            : Carrier                   -- identity element
    _·_          : Carrier → Carrier → Carrier   -- multiplication
    inv          : Carrier → Carrier         -- group inverse

    -- ── h-Level and decidability ────────────────────────────────
    isSetCarrier : isSet Carrier
    _≟_          : Discrete Carrier

    -- ── Group axioms ────────────────────────────────────────────
    ·-identityˡ  : (x : Carrier) → ε · x ≡ x
    ·-identityʳ  : (x : Carrier) → x · ε ≡ x
    ·-inverseˡ   : (x : Carrier) → inv x · x ≡ ε
    ·-inverseʳ   : (x : Carrier) → x · inv x ≡ ε
    ·-assoc      : (x y z : Carrier) → (x · y) · z ≡ x · (y · z)

  infixl 7 _·_


-- ════════════════════════════════════════════════════════════════════
--  §1.  Z2 — The carrier type for ℤ/2ℤ
-- ════════════════════════════════════════════════════════════════════
--
--  Two elements:  e0 (identity, 0 mod 2) and e1 (generator, 1 mod 2).
--
--  Multiplication is addition mod 2:
--
--    ·  │  e0   e1
--    ───┼──────────
--    e0 │  e0   e1
--    e1 │  e1   e0
--
--  Every element is its own inverse:  inv(e0) = e0,  inv(e1) = e1.
--
--  ℤ/2ℤ is the simplest nontrivial group and serves as the first
--  gauge group instance:  it is the finite replacement for U(1)
--  with n = 2 (§13.4 of docs/10-frontier.md).
--
--  The group has 2 conjugacy classes (trivially, since it is
--  abelian: each element is its own conjugacy class), giving a
--  particle spectrum of vacuum + 1 charge type.
-- ════════════════════════════════════════════════════════════════════

data Z2 : Type₀ where
  e0 e1 : Z2


-- ════════════════════════════════════════════════════════════════════
--  §2.  Z2 group operations
-- ════════════════════════════════════════════════════════════════════
--
--  The multiplication _+Z2_ computes by pattern matching on the
--  left argument first.  The first clause  e0 +Z2 y = y  makes
--  left-identity hold definitionally (without case split on y),
--  enabling  ·-identityˡ _ = refl .
--
--  The inverse  invZ2  is the identity function on Z2 (every
--  element is self-inverse in ℤ/2ℤ).
-- ════════════════════════════════════════════════════════════════════

infixl 7 _+Z2_

_+Z2_ : Z2 → Z2 → Z2
e0 +Z2 y  = y
e1 +Z2 e0 = e1
e1 +Z2 e1 = e0

invZ2 : Z2 → Z2
invZ2 e0 = e0
invZ2 e1 = e1


-- ════════════════════════════════════════════════════════════════════
--  §3.  Decidable equality on Z2
-- ════════════════════════════════════════════════════════════════════
--
--  Decidable equality is verified by a 4-case pattern match.
--  The two diagonal cases hold by  yes refl .  The two off-diagonal
--  cases use a discriminator function  Z2-discrim  that maps e0 to
--  an inhabited type and e1 to ⊥ (or vice versa), so that
--  transporting along a hypothetical  e0 ≡ e1  path produces an
--  element of ⊥.
--
--  The isSet proof follows from Hedberg's theorem (decidable
--  equality implies UIP implies isSet), provided by the cubical
--  library as  Discrete→isSet .
-- ════════════════════════════════════════════════════════════════════

private
  -- Discriminator: maps e0 to an inhabited type, e1 to ⊥.
  -- Used to derive absurdity from a hypothetical  e0 ≡ e1  path.
  Z2-discrim : Z2 → Type₀
  Z2-discrim e0 = Z2
  Z2-discrim e1 = ⊥

  e0≢e1 : e0 ≡ e1 → ⊥
  e0≢e1 p = subst Z2-discrim p e0

  e1≢e0 : e1 ≡ e0 → ⊥
  e1≢e0 p = e0≢e1 (sym p)

discreteZ2 : Discrete Z2
discreteZ2 e0 e0 = yes refl
discreteZ2 e0 e1 = no e0≢e1
discreteZ2 e1 e0 = no e1≢e0
discreteZ2 e1 e1 = yes refl

isSetZ2 : isSet Z2
isSetZ2 = Discrete→isSet discreteZ2


-- ════════════════════════════════════════════════════════════════════
--  §4.  Group axioms for Z2 — all by refl
-- ════════════════════════════════════════════════════════════════════
--
--  Every axiom is proved by exhaustive case split on the Z2
--  arguments, with each case holding by  refl  because ℕ-free
--  pattern matching on closed constructor terms reduces
--  judgmentally.
--
--  This is the "exhaustive case split on closed constructor terms"
--  proof strategy described in §13.4 of docs/10-frontier.md.
--
--  Case counts:
--    ·-identityˡ:  0 cases (wildcard — e0 is left-absorbing)
--    ·-identityʳ:  2 cases  (case split on x)
--    ·-inverseˡ:   2 cases  (case split on x)
--    ·-inverseʳ:   2 cases  (case split on x)
--    ·-assoc:      4 cases  (case split on x, y, z)
--    Total: 10 cases, all refl.
-- ════════════════════════════════════════════════════════════════════

-- ── Left identity ──────────────────────────────────────────────
--
--  e0 +Z2 x  reduces to  x  by the first clause of  _+Z2_
--  regardless of  x .  No case split needed.

Z2-identityˡ : (x : Z2) → e0 +Z2 x ≡ x
Z2-identityˡ _ = refl

-- ── Right identity ─────────────────────────────────────────────
--
--  x +Z2 e0  requires case split on  x :
--    e0 +Z2 e0 = e0   (by clause 1)    ✓
--    e1 +Z2 e0 = e1   (by clause 2)    ✓

Z2-identityʳ : (x : Z2) → x +Z2 e0 ≡ x
Z2-identityʳ e0 = refl
Z2-identityʳ e1 = refl

-- ── Left inverse ───────────────────────────────────────────────
--
--  invZ2 x +Z2 x ≡ e0 :
--    x = e0:  e0 +Z2 e0 = e0   ✓
--    x = e1:  e1 +Z2 e1 = e0   ✓

Z2-inverseˡ : (x : Z2) → invZ2 x +Z2 x ≡ e0
Z2-inverseˡ e0 = refl
Z2-inverseˡ e1 = refl

-- ── Right inverse ──────────────────────────────────────────────
--
--  x +Z2 invZ2 x ≡ e0 :
--    x = e0:  e0 +Z2 e0 = e0   ✓
--    x = e1:  e1 +Z2 e1 = e0   ✓

Z2-inverseʳ : (x : Z2) → x +Z2 invZ2 x ≡ e0
Z2-inverseʳ e0 = refl
Z2-inverseʳ e1 = refl

-- ── Associativity ──────────────────────────────────────────────
--
--  (x +Z2 y) +Z2 z ≡ x +Z2 (y +Z2 z) :
--
--  When x = e0:  both sides reduce to  y +Z2 z  (by clause 1).
--  When x = e1, y = e0:  both sides reduce to  e1 +Z2 z .
--  When x = e1, y = e1:  LHS = (e0) +Z2 z = z ;
--                         RHS = e1 +Z2 (e1 +Z2 z) .
--    z = e0:  LHS = e0,  RHS = e1 +Z2 e1 = e0   ✓
--    z = e1:  LHS = e1,  RHS = e1 +Z2 e0 = e1   ✓

Z2-assoc : (x y z : Z2) → (x +Z2 y) +Z2 z ≡ x +Z2 (y +Z2 z)
Z2-assoc e0 _  _  = refl
Z2-assoc e1 e0 _  = refl
Z2-assoc e1 e1 e0 = refl
Z2-assoc e1 e1 e1 = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  ℤ/2 — The concrete FiniteGroup instance
-- ════════════════════════════════════════════════════════════════════
--
--  All fields are filled from the definitions above.  The group
--  axiom fields are the refl-based proofs from §4.
--
--  This is the first concrete gauge group instance for the project.
--  Instantiation on the 6-tile star patch (Phase M.1) will assign
--  Z2 elements to each of the 5 bonds, and compute holonomies
--  around faces by folding _+Z2_ over the ordered boundary bonds.
--
--  Exit criterion (§13.12 of docs/10-frontier.md):
--    "A FiniteGroup record type-checks in Gauge/FiniteGroup.agda
--     with at least one concrete instance (ℤ/2ℤ or ℤ/3ℤ) where
--     all axioms hold by refl."
--
--  This instance satisfies the criterion for ℤ/2ℤ.
-- ════════════════════════════════════════════════════════════════════

ℤ/2 : FiniteGroup
ℤ/2 .FiniteGroup.Carrier      = Z2
ℤ/2 .FiniteGroup.ε            = e0
ℤ/2 .FiniteGroup._·_          = _+Z2_
ℤ/2 .FiniteGroup.inv          = invZ2
ℤ/2 .FiniteGroup.isSetCarrier = isSetZ2
ℤ/2 .FiniteGroup._≟_          = discreteZ2
ℤ/2 .FiniteGroup.·-identityˡ  = Z2-identityˡ
ℤ/2 .FiniteGroup.·-identityʳ  = Z2-identityʳ
ℤ/2 .FiniteGroup.·-inverseˡ   = Z2-inverseˡ
ℤ/2 .FiniteGroup.·-inverseʳ   = Z2-inverseʳ
ℤ/2 .FiniteGroup.·-assoc      = Z2-assoc


-- ════════════════════════════════════════════════════════════════════
--  §6.  Regression tests — multiplication table
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the Z2 multiplication table reduces to the
--  expected values on all 4 input pairs.  They serve as regression
--  tests: if the definition of _+Z2_ is accidentally changed,
--  these proofs will fail at type-check time.
-- ════════════════════════════════════════════════════════════════════

private
  -- Full multiplication table
  check-00 : e0 +Z2 e0 ≡ e0
  check-00 = refl

  check-01 : e0 +Z2 e1 ≡ e1
  check-01 = refl

  check-10 : e1 +Z2 e0 ≡ e1
  check-10 = refl

  check-11 : e1 +Z2 e1 ≡ e0
  check-11 = refl

  -- Inverse table
  check-inv0 : invZ2 e0 ≡ e0
  check-inv0 = refl

  check-inv1 : invZ2 e1 ≡ e1
  check-inv1 = refl

  -- Decidable equality spot checks
  check-dec-eq : discreteZ2 e0 e0 ≡ yes refl
  check-dec-eq = refl

  -- Record field access spot check: ε is e0
  check-ε : FiniteGroup.ε ℤ/2 ≡ e0
  check-ε = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    FiniteGroup    : Type₁
--                     (record with fields Carrier, ε, _·_, inv,
--                      isSetCarrier, _≟_, and 5 group axioms)
--
--    Z2             : Type₀
--                     (data type with constructors e0, e1)
--    _+Z2_          : Z2 → Z2 → Z2     (addition mod 2)
--    invZ2          : Z2 → Z2           (self-inverse)
--    discreteZ2     : Discrete Z2       (decidable equality)
--    isSetZ2        : isSet Z2          (h-level 2)
--
--    Z2-identityˡ   : left identity     (refl)
--    Z2-identityʳ   : right identity    (2 × refl)
--    Z2-inverseˡ    : left inverse      (2 × refl)
--    Z2-inverseʳ    : right inverse     (2 × refl)
--    Z2-assoc       : associativity     (4 × refl)
--
--    ℤ/2            : FiniteGroup       (the concrete instance)
--
--  Relationship to existing code:
--
--    This module is the first file in the new  src/Gauge/  directory.
--    It imports ONLY from:
--      • Cubical.Foundations.Prelude     — PathP, ≡, refl, subst, sym
--      • Cubical.Foundations.HLevels     — isSet
--      • Cubical.Relation.Nullary        — Dec, Discrete, Discrete→isSet
--      • Cubical.Data.Empty              — ⊥  (for discrimination)
--
--    It does NOT import from any existing src/ module.  The gauge
--    layer is purely additive — it enriches the holographic network
--    with algebraic structure without modifying the existing bridge,
--    curvature, causal, or dynamics infrastructure.
--
--  Next steps (Phase M.0 → M.1):
--
--    1. src/Gauge/ZMod.agda  — ℤ/nℤ instances for n = 3, 4, ...
--       using a generic n-element cyclic type.  The ℤ/3ℤ instance
--       has 3 conjugacy classes (vacuum + 2 charge types).
--
--    2. src/Gauge/Q8.agda    — Quaternion group Q₈ (8 elements,
--       5 conjugacy classes, representations of dimensions
--       1,1,1,1,2).  This is the finite replacement for SU(2).
--
--    3. src/Gauge/Connection.agda  — GaugeConnection record:
--         ω : Bond → G.Carrier
--       with the convention  ω(ē) = inv(ω(e))  for reversed bonds.
--
--    4. src/Gauge/Holonomy.agda  — holonomy computation:
--         holonomy ω ∂f = fold (_·_) ε (map ω (boundary f))
--       ParticleDefect ω f = ¬ (holonomy ω f ≡ ε)
--
--  The FiniteGroup record is the foundation for all of these.
--  Its design — decidable equality, set-level carrier, axioms
--  by refl — ensures that all downstream constructions are
--  computationally well-behaved in Cubical Agda.
-- ════════════════════════════════════════════════════════════════════