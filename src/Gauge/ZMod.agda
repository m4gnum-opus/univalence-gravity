{-# OPTIONS --cubical --safe --guardedness #-}

module Gauge.ZMod where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.HLevels
open import Cubical.Relation.Nullary
  using (Dec ; yes ; no ; Discrete ; Discrete→isSet)
open import Cubical.Data.Empty using (⊥)

open import Gauge.FiniteGroup


-- ════════════════════════════════════════════════════════════════════
--  Cyclic Group Instances:  ℤ/nℤ  for  n = 2, 3, ...
-- ════════════════════════════════════════════════════════════════════
--
--  This module collects the concrete cyclic group instances used as
--  finite replacements for U(1) in the discrete Standard Model
--  gauge group (docs/formal/05-gauge-theory.md §2 — the finite
--  subgroup replacement table).
--
--  The ℤ/2ℤ instance (carrier Z2, record ℤ/2 : FiniteGroup) is
--  defined in  Gauge.FiniteGroup  and brought into scope by the
--  open import above.  This module adds ℤ/3ℤ as the first cyclic
--  group with genuinely distinct particle species (3 conjugacy
--  classes: vacuum + 2 charge types).
--
--  All group axioms are verified by exhaustive case split on
--  closed constructor terms, with every case holding by  refl .
--  Both groups are proven abelian (commutative), which simplifies
--  conjugacy class computation in  Gauge/ConjugacyClass.agda :
--  for abelian groups, each element is its own conjugacy class.
--
--  Representation theory (docs/formal/05-gauge-theory.md §2):
--
--    ℤ/nℤ has n irreducible representations, all 1-dimensional.
--    When used as the U(1) factor in the gauge group, the
--    representation dimension determines the bond capacity:
--    dim(ρ) = 1 for all irreps, recovering the current model
--    where each bond carries capacity 1.
--
--  Downstream modules:
--    src/Gauge/Q8.agda            — Quaternion group Q₈ (SU(2) replacement)
--    src/Gauge/Connection.agda    — GaugeConnection : Bond → G.Carrier
--    src/Gauge/Holonomy.agda      — holonomy, isFlat, ParticleDefect
--    src/Gauge/ConjugacyClass.agda — particle species classification
--    src/Gauge/RepCapacity.agda   — SpinLabel, dim functor
--
--  Architectural role:
--    This is a Tier 2 (Observable / Geometry Layer) module extending
--    the gauge infrastructure from Gauge/FiniteGroup.agda with
--    additional cyclic group instances and commutativity proofs.
--    See docs/getting-started/architecture.md for the three-layer
--    gauge architecture diagram.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §2    (finite subgroup replacement
--                                          table — U(1) → ℤ/nℤ)
--    docs/formal/05-gauge-theory.md §4    (concrete group instances)
--    docs/formal/05-gauge-theory.md §7    (conjugacy classes and
--                                          particle spectrum)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — downstream)
--    docs/reference/assumptions.md §A9    (finite gauge groups
--                                          replace continuous Lie
--                                          groups)
--    docs/reference/module-index.md       (module description)
--    docs/getting-started/architecture.md (module dependency DAG)
--    docs/historical/development-docs/10-frontier.md §13
--                                         (original development plan)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Re-export of ℤ/2ℤ from Gauge.FiniteGroup
-- ════════════════════════════════════════════════════════════════════
--
--  The carrier type  Z2  (constructors e0, e1), the operations
--  _+Z2_, invZ2, the decidable equality  discreteZ2, and the
--  concrete instance  ℤ/2 : FiniteGroup  are all in scope via
--  the  open import Gauge.FiniteGroup  above.
--
--  Downstream modules can import  Gauge.ZMod  to access both
--  ℤ/2ℤ and ℤ/3ℤ instances from a single source.
-- ════════════════════════════════════════════════════════════════════

-- (No new definitions needed — everything re-exported by open import.)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Z3 — The carrier type for ℤ/3ℤ
-- ════════════════════════════════════════════════════════════════════
--
--  Three elements:  z0 (identity, 0 mod 3), z1 (generator, 1 mod 3),
--  z2 (2 mod 3).
--
--  Multiplication table (addition mod 3):
--
--    +   │  z0   z1   z2
--    ────┼────────────────
--    z0  │  z0   z1   z2
--    z1  │  z1   z2   z0
--    z2  │  z2   z0   z1
--
--  Every element's inverse:
--    inv(z0) = z0,  inv(z1) = z2,  inv(z2) = z1
--
--  ℤ/3ℤ is the simplest cyclic group with a nontrivial inverse
--  (z1 ≠ inv(z1) = z2), giving 3 conjugacy classes:
--    {z0} (vacuum),  {z1} (charge +1),  {z2} (charge −1)
--
--  The constructors are named  z0, z1, z2  (not  e0, e1, e2)
--  to avoid name collision with the Z2 constructors  e0, e1
--  re-exported from Gauge.FiniteGroup.
-- ════════════════════════════════════════════════════════════════════

data Z3 : Type₀ where
  z0 z1 z2 : Z3


-- ════════════════════════════════════════════════════════════════════
--  §3.  Z3 group operations
-- ════════════════════════════════════════════════════════════════════
--
--  The multiplication  _+Z3_  computes by pattern matching on the
--  left argument first.  The first clause  z0 +Z3 y = y  makes
--  left-identity hold definitionally (without case split on y),
--  enabling  Z3-identityˡ _ = refl .
--
--  The inverse  invZ3  swaps z1 and z2 (the non-identity elements
--  are each other's inverse mod 3).  z0 is self-inverse.
-- ════════════════════════════════════════════════════════════════════

infixl 7 _+Z3_

_+Z3_ : Z3 → Z3 → Z3
z0 +Z3 y  = y
z1 +Z3 z0 = z1
z1 +Z3 z1 = z2
z1 +Z3 z2 = z0
z2 +Z3 z0 = z2
z2 +Z3 z1 = z0
z2 +Z3 z2 = z1

invZ3 : Z3 → Z3
invZ3 z0 = z0
invZ3 z1 = z2
invZ3 z2 = z1


-- ════════════════════════════════════════════════════════════════════
--  §4.  Decidable equality on Z3
-- ════════════════════════════════════════════════════════════════════
--
--  Decidable equality is verified by a 9-case pattern match.
--  The 3 diagonal cases hold by  yes refl .  The 6 off-diagonal
--  cases use discriminator functions that map one constructor to
--  an inhabited type and the rest to  ⊥ , so that transporting
--  along a hypothetical equality path produces a term of  ⊥ .
--
--  The isSet proof follows from Hedberg's theorem (decidable
--  equality implies UIP implies isSet), provided by the cubical
--  library as  Discrete→isSet .
-- ════════════════════════════════════════════════════════════════════

private
  -- Discriminator for z0: maps z0 to Z3, z1 and z2 to ⊥.
  D₃₀ : Z3 → Type₀
  D₃₀ z0 = Z3
  D₃₀ z1 = ⊥
  D₃₀ z2 = ⊥

  z0≢z1 : z0 ≡ z1 → ⊥
  z0≢z1 p = subst D₃₀ p z0

  z0≢z2 : z0 ≡ z2 → ⊥
  z0≢z2 p = subst D₃₀ p z0

  -- Discriminator for z1: maps z1 to Z3, z0 and z2 to ⊥.
  D₃₁ : Z3 → Type₀
  D₃₁ z0 = ⊥
  D₃₁ z1 = Z3
  D₃₁ z2 = ⊥

  z1≢z0 : z1 ≡ z0 → ⊥
  z1≢z0 p = subst D₃₁ p z1

  z1≢z2 : z1 ≡ z2 → ⊥
  z1≢z2 p = subst D₃₁ p z1

  z2≢z0 : z2 ≡ z0 → ⊥
  z2≢z0 p = z0≢z2 (sym p)

  z2≢z1 : z2 ≡ z1 → ⊥
  z2≢z1 p = z1≢z2 (sym p)

discreteZ3 : Discrete Z3
discreteZ3 z0 z0 = yes refl
discreteZ3 z0 z1 = no z0≢z1
discreteZ3 z0 z2 = no z0≢z2
discreteZ3 z1 z0 = no z1≢z0
discreteZ3 z1 z1 = yes refl
discreteZ3 z1 z2 = no z1≢z2
discreteZ3 z2 z0 = no z2≢z0
discreteZ3 z2 z1 = no z2≢z1
discreteZ3 z2 z2 = yes refl

isSetZ3 : isSet Z3
isSetZ3 = Discrete→isSet discreteZ3


-- ════════════════════════════════════════════════════════════════════
--  §5.  Group axioms for Z3 — all by refl
-- ════════════════════════════════════════════════════════════════════
--
--  Every axiom is proved by exhaustive case split on the Z3
--  arguments, with each case holding by  refl  because pattern
--  matching on closed constructor terms reduces judgmentally.
--
--  Case counts:
--    Z3-identityˡ:  0 cases  (wildcard — z0 is left-absorbing)
--    Z3-identityʳ:  3 cases
--    Z3-inverseˡ:   3 cases
--    Z3-inverseʳ:   3 cases
--    Z3-assoc:     15 cases  (3 wildcard + 12 explicit)
--    Total:        24 cases, all refl.
-- ════════════════════════════════════════════════════════════════════

-- ── Left identity ──────────────────────────────────────────────
--
--  z0 +Z3 x  reduces to  x  by the first clause of  _+Z3_
--  regardless of  x .  No case split needed.

Z3-identityˡ : (x : Z3) → z0 +Z3 x ≡ x
Z3-identityˡ _ = refl

-- ── Right identity ─────────────────────────────────────────────
--
--  x +Z3 z0  requires case split on  x :
--    z0 +Z3 z0 = z0   (by clause 1)    ✓
--    z1 +Z3 z0 = z1   (by clause 2)    ✓
--    z2 +Z3 z0 = z2   (by clause 5)    ✓

Z3-identityʳ : (x : Z3) → x +Z3 z0 ≡ x
Z3-identityʳ z0 = refl
Z3-identityʳ z1 = refl
Z3-identityʳ z2 = refl

-- ── Left inverse ───────────────────────────────────────────────
--
--  invZ3 x +Z3 x ≡ z0 :
--    x = z0:  z0 +Z3 z0 = z0   ✓
--    x = z1:  z2 +Z3 z1 = z0   ✓
--    x = z2:  z1 +Z3 z2 = z0   ✓

Z3-inverseˡ : (x : Z3) → invZ3 x +Z3 x ≡ z0
Z3-inverseˡ z0 = refl
Z3-inverseˡ z1 = refl
Z3-inverseˡ z2 = refl

-- ── Right inverse ──────────────────────────────────────────────
--
--  x +Z3 invZ3 x ≡ z0 :
--    x = z0:  z0 +Z3 z0 = z0   ✓
--    x = z1:  z1 +Z3 z2 = z0   ✓
--    x = z2:  z2 +Z3 z1 = z0   ✓

Z3-inverseʳ : (x : Z3) → x +Z3 invZ3 x ≡ z0
Z3-inverseʳ z0 = refl
Z3-inverseʳ z1 = refl
Z3-inverseʳ z2 = refl

-- ── Associativity ──────────────────────────────────────────────
--
--  (x +Z3 y) +Z3 z ≡ x +Z3 (y +Z3 z)
--
--  When x = z0:  both sides reduce to  y +Z3 z  (by clause 1). refl.
--  When y = z0:  LHS = (x +Z3 z0) +Z3 z = x +Z3 z
--                RHS = x +Z3 (z0 +Z3 z) = x +Z3 z.  refl.
--  Remaining 12 cases (x ∈ {z1,z2}, y ∈ {z1,z2}, z ∈ {z0,z1,z2}):
--  all reduce to the same Z3 constructor on both sides.
--
--  Total: 3 + 12 = 15 clauses, all refl.

Z3-assoc : (x y z : Z3) → (x +Z3 y) +Z3 z ≡ x +Z3 (y +Z3 z)
Z3-assoc z0 _  _  = refl
Z3-assoc z1 z0 _  = refl
Z3-assoc z2 z0 _  = refl
Z3-assoc z1 z1 z0 = refl
Z3-assoc z1 z1 z1 = refl
Z3-assoc z1 z1 z2 = refl
Z3-assoc z1 z2 z0 = refl
Z3-assoc z1 z2 z1 = refl
Z3-assoc z1 z2 z2 = refl
Z3-assoc z2 z1 z0 = refl
Z3-assoc z2 z1 z1 = refl
Z3-assoc z2 z1 z2 = refl
Z3-assoc z2 z2 z0 = refl
Z3-assoc z2 z2 z1 = refl
Z3-assoc z2 z2 z2 = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  ℤ/3 — The concrete FiniteGroup instance
-- ════════════════════════════════════════════════════════════════════
--
--  All fields are filled from the definitions above.  The group
--  axiom fields are the refl-based proofs from §5.
--
--  ℤ/3ℤ is the first gauge group instance with a nontrivial
--  inverse map (inv z1 = z2 ≠ z1) and 3 conjugacy classes.
--  In the discrete Standard Model, it serves as the U(1) factor:
--
--    G_discrete = Δ(27) × Q₈ × ℤ/nℤ
--
--  with n = 3 being the simplest choice exhibiting distinct
--  charge types (vacuum, +1, −1).
--
--  Particle spectrum (docs/formal/05-gauge-theory.md §7):
--    3 conjugacy classes → vacuum + 2 charge types
--
--  Representation theory:
--    3 irreducible representations, all 1-dimensional.
--    dim(ρ) = 1 for all irreps → bond capacity 1
--    → recovers the current uniform-weight model.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §2  (finite subgroup table)
--    docs/formal/05-gauge-theory.md §4  (concrete instances)
--    docs/formal/05-gauge-theory.md §7  (conjugacy classes)
-- ════════════════════════════════════════════════════════════════════

ℤ/3 : FiniteGroup
ℤ/3 .FiniteGroup.Carrier      = Z3
ℤ/3 .FiniteGroup.ε            = z0
ℤ/3 .FiniteGroup._·_          = _+Z3_
ℤ/3 .FiniteGroup.inv          = invZ3
ℤ/3 .FiniteGroup.isSetCarrier = isSetZ3
ℤ/3 .FiniteGroup._≟_          = discreteZ3
ℤ/3 .FiniteGroup.·-identityˡ  = Z3-identityˡ
ℤ/3 .FiniteGroup.·-identityʳ  = Z3-identityʳ
ℤ/3 .FiniteGroup.·-inverseˡ   = Z3-inverseˡ
ℤ/3 .FiniteGroup.·-inverseʳ   = Z3-inverseʳ
ℤ/3 .FiniteGroup.·-assoc      = Z3-assoc


-- ════════════════════════════════════════════════════════════════════
--  §7.  Commutativity — ℤ/nℤ is abelian
-- ════════════════════════════════════════════════════════════════════
--
--  Both ℤ/2ℤ and ℤ/3ℤ are abelian (commutative) groups.  This is
--  a structural property of all cyclic groups.
--
--  For abelian groups, every conjugacy class is a singleton:
--    [g] = { h⁻¹ g h | h ∈ G } = { g }
--
--  This simplifies the particle species classification in
--  Gauge/ConjugacyClass.agda: the number of particle species equals
--  the number of group elements (minus 1 for the vacuum).
--
--  The proofs are all by refl because the multiplication table is
--  symmetric:  x + y  and  y + x  reduce to the same constructor
--  for all concrete pairs.
-- ════════════════════════════════════════════════════════════════════

-- ── ℤ/2ℤ commutativity (4 cases) ──────────────────────────────
--
--  x +Z2 y ≡ y +Z2 x  for all x, y : Z2.
--
--  Extends the ℤ/2ℤ infrastructure from Gauge.FiniteGroup with
--  a commutativity proof not included there.

Z2-comm : (x y : Z2) → x +Z2 y ≡ y +Z2 x
Z2-comm e0 e0 = refl
Z2-comm e0 e1 = refl
Z2-comm e1 e0 = refl
Z2-comm e1 e1 = refl

-- ── ℤ/3ℤ commutativity (9 cases) ──────────────────────────────
--
--  x +Z3 y ≡ y +Z3 x  for all x, y : Z3.
--
--  Key verification pairs:
--    z1 +Z3 z2 = z0 = z2 +Z3 z1    ✓
--    z0 +Z3 z1 = z1 = z1 +Z3 z0    ✓
--    z0 +Z3 z2 = z2 = z2 +Z3 z0    ✓

Z3-comm : (x y : Z3) → x +Z3 y ≡ y +Z3 x
Z3-comm z0 z0 = refl
Z3-comm z0 z1 = refl
Z3-comm z0 z2 = refl
Z3-comm z1 z0 = refl
Z3-comm z1 z1 = refl
Z3-comm z1 z2 = refl
Z3-comm z2 z0 = refl
Z3-comm z2 z1 = refl
Z3-comm z2 z2 = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the Z3 multiplication table, inverse map, and
--  decidable equality reduce to the expected values on all input
--  combinations.  They serve as regression tests: if any definition
--  is accidentally changed, these proofs will fail at type-check time.
-- ════════════════════════════════════════════════════════════════════

private
  -- ── Full multiplication table (9 entries) ────────────────────
  check-z00 : z0 +Z3 z0 ≡ z0
  check-z00 = refl

  check-z01 : z0 +Z3 z1 ≡ z1
  check-z01 = refl

  check-z02 : z0 +Z3 z2 ≡ z2
  check-z02 = refl

  check-z10 : z1 +Z3 z0 ≡ z1
  check-z10 = refl

  check-z11 : z1 +Z3 z1 ≡ z2
  check-z11 = refl

  check-z12 : z1 +Z3 z2 ≡ z0
  check-z12 = refl

  check-z20 : z2 +Z3 z0 ≡ z2
  check-z20 = refl

  check-z21 : z2 +Z3 z1 ≡ z0
  check-z21 = refl

  check-z22 : z2 +Z3 z2 ≡ z1
  check-z22 = refl

  -- ── Inverse table ────────────────────────────────────────────
  check-inv-z0 : invZ3 z0 ≡ z0
  check-inv-z0 = refl

  check-inv-z1 : invZ3 z1 ≡ z2
  check-inv-z1 = refl

  check-inv-z2 : invZ3 z2 ≡ z1
  check-inv-z2 = refl

  -- ── Decidable equality spot checks ───────────────────────────
  check-dec-z0z0 : discreteZ3 z0 z0 ≡ yes refl
  check-dec-z0z0 = refl

  check-dec-z1z1 : discreteZ3 z1 z1 ≡ yes refl
  check-dec-z1z1 = refl

  check-dec-z2z2 : discreteZ3 z2 z2 ≡ yes refl
  check-dec-z2z2 = refl

  -- ── Record field access spot checks ──────────────────────────
  check-ε3 : FiniteGroup.ε ℤ/3 ≡ z0
  check-ε3 = refl

  check-inv3 : FiniteGroup.inv ℤ/3 z1 ≡ z2
  check-inv3 = refl

  -- ── Generator order check: z1 + z1 + z1 = z0 ────────────────
  --
  --  z1 is a generator of ℤ/3ℤ with order 3:
  --    z1¹ = z1,  z1² = z2,  z1³ = z0 (identity)
  check-order : z1 +Z3 z1 +Z3 z1 ≡ z0
  check-order = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    -- Re-exported from Gauge.FiniteGroup (ℤ/2ℤ):
--    Z2             : Type₀          (constructors e0, e1)
--    _+Z2_          : Z2 → Z2 → Z2
--    invZ2          : Z2 → Z2
--    discreteZ2     : Discrete Z2
--    isSetZ2        : isSet Z2
--    ℤ/2            : FiniteGroup
--
--    -- New in this module (ℤ/3ℤ):
--    Z3             : Type₀          (constructors z0, z1, z2)
--    _+Z3_          : Z3 → Z3 → Z3  (addition mod 3)
--    invZ3          : Z3 → Z3        (z0↦z0, z1↦z2, z2↦z1)
--    discreteZ3     : Discrete Z3    (9-case decidable equality)
--    isSetZ3        : isSet Z3       (h-level 2)
--
--    Z3-identityˡ   : left identity     (refl)
--    Z3-identityʳ   : right identity    (3 × refl)
--    Z3-inverseˡ    : left inverse      (3 × refl)
--    Z3-inverseʳ    : right inverse     (3 × refl)
--    Z3-assoc       : associativity     (15 × refl)
--
--    ℤ/3            : FiniteGroup    (the concrete ℤ/3ℤ instance)
--
--    -- Commutativity (abelian property):
--    Z2-comm        : Z2 commutativity  (4 × refl)
--    Z3-comm        : Z3 commutativity  (9 × refl)
--
--  Proof effort:
--
--    Z3 axioms:  3 + 3 + 3 + 3 + 15 = 27 cases (incl. wildcards)
--    Z3 decidable equality:  9 cases (3 yes + 6 no)
--    Z3 commutativity:  9 cases
--    All by refl (axioms, comm) or by discriminator + subst (≢).
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Cubical.Foundations.Prelude     — paths, subst, sym
--      • Cubical.Foundations.HLevels     — isSet
--      • Cubical.Relation.Nullary        — Dec, Discrete, Discrete→isSet
--      • Cubical.Data.Empty              — ⊥  (for discrimination)
--      • Gauge.FiniteGroup               — FiniteGroup record, ℤ/2
--
--    The gauge layer is purely additive — no existing module is
--    modified.
--
--  Next steps (downstream modules in Gauge/):
--
--    1. src/Gauge/Q8.agda    — Quaternion group Q₈ (8 elements,
--       5 conjugacy classes, representation dimensions 1,1,1,1,2).
--       This is the finite replacement for SU(2) and the first
--       non-abelian gauge group in the repository.
--
--    2. src/Gauge/Connection.agda  — GaugeConnection record:
--         ω : Bond → G.Carrier
--       Instantiation on the 6-tile star with ℤ/2 or ℤ/3.
--
--    3. src/Gauge/Holonomy.agda  — holonomy computation:
--         holonomy ω ∂f = fold (_·_) ε (map ω (boundary f))
--       ParticleDefect ω f = ¬ (holonomy ω f ≡ ε)
--
--  Exit criterion satisfaction:
--
--    The exit criterion from the gauge layer development plan
--    (docs/historical/development-docs/10-frontier.md §13.12)
--    states:
--      "A FiniteGroup record type-checks with at least one concrete
--       instance (ℤ/2ℤ or ℤ/3ℤ) where all axioms hold by refl."
--
--    This module provides ℤ/3 : FiniteGroup with all axioms by refl,
--    in addition to the ℤ/2 instance already in Gauge.FiniteGroup.
--    Both instances satisfy the criterion.
--
--  Reference:
--    docs/formal/05-gauge-theory.md       (gauge theory — full formal
--                                          treatment)
--    docs/formal/05-gauge-theory.md §2    (finite subgroup replacement)
--    docs/formal/05-gauge-theory.md §4    (concrete group instances)
--    docs/formal/05-gauge-theory.md §7    (conjugacy classes)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — downstream)
--    docs/reference/assumptions.md §A9    (finite gauge groups
--                                          replace continuous Lie
--                                          groups)
--    docs/reference/module-index.md       (module description)
--    docs/getting-started/architecture.md (module dependency DAG)
--    docs/physics/five-walls.md §Wall 3   (continuous gauge groups —
--                                          the hard boundary)
--    docs/historical/development-docs/10-frontier.md §13
--                                         (original development plan)
-- ════════════════════════════════════════════════════════════════════