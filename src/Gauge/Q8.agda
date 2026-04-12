{-# OPTIONS --cubical --safe --guardedness #-}

module Gauge.Q8 where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.HLevels
open import Cubical.Relation.Nullary
  using (Dec ; yes ; no ; Discrete ; Discrete→isSet)
open import Cubical.Data.Empty using (⊥ ; rec)

open import Gauge.FiniteGroup


-- ════════════════════════════════════════════════════════════════════
--  §1.  Q8 — Carrier type for the Quaternion Group Q₈
-- ════════════════════════════════════════════════════════════════════
--
--  8 elements:  {1, −1, i, −i, j, −j, k, −k}
--
--  Constructor naming:
--    q1  = 1,   qn1 = −1
--    qi  = i,   qni = −i
--    qj  = j,   qnj = −j
--    qk  = k,   qnk = −k
--
--  Fundamental relations:
--    i² = j² = k² = ijk = −1
--    ij = k,  jk = i,  ki = j
--    ji = −k, kj = −i, ik = −j
--
--  |Q₈| = 8,  5 conjugacy classes:
--    {1}, {−1}, {i,−i}, {j,−j}, {k,−k}
--
--  5 irreducible representations with dimensions 1,1,1,1,2.
--  Q₈ is the finite replacement for SU(2) in the discrete
--  Standard Model gauge group:
--
--    G_discrete = Δ(27) × Q₈ × ℤ/nℤ
--
--  This follows the finite subgroup replacement strategy
--  documented in docs/formal/05-gauge-theory.md §2 and
--  docs/reference/assumptions.md §A9.
--
--  Architectural role:
--    This is a Tier 2 (Observable / Geometry Layer) module
--    providing the quaternion group Q₈ — the first non-abelian
--    gauge group in the repository and the finite replacement
--    for SU(2).  It extends the gauge infrastructure from
--    Gauge/FiniteGroup.agda and Gauge/ZMod.agda.
--    See docs/getting-started/architecture.md for the three-layer
--    gauge architecture diagram.
--
--  Downstream modules:
--    src/Gauge/Connection.agda    — GaugeConnection Q₈ Bond
--    src/Gauge/Holonomy.agda      — holonomy, ParticleDefect
--    src/Gauge/ConjugacyClass.agda — 5 conjugacy classes
--    src/Gauge/RepCapacity.agda   — Q8Rep, dimQ8, GaugedPatchWitness
--    src/Quantum/StarQuantumBridge.agda — quantum superposition
--
--  Reference:
--    docs/formal/05-gauge-theory.md §2    (finite subgroup replacement
--                                          table — SU(2) → Q₈)
--    docs/formal/05-gauge-theory.md §4.3  (Q₈ — the quaternion group)
--    docs/formal/05-gauge-theory.md §7    (conjugacy classes and
--                                          particle spectrum)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — downstream)
--    docs/reference/assumptions.md §A9    (finite gauge groups
--                                          replace continuous Lie
--                                          groups)
--    docs/reference/module-index.md       (module description)
--    docs/getting-started/architecture.md (module dependency DAG)
-- ════════════════════════════════════════════════════════════════════

data Q8 : Type₀ where
  q1 qn1 qi qni qj qnj qk qnk : Q8


-- ════════════════════════════════════════════════════════════════════
--  §2.  negQ8 — Quaternion negation
-- ════════════════════════════════════════════════════════════════════

negQ8 : Q8 → Q8
negQ8 q1  = qn1
negQ8 qn1 = q1
negQ8 qi  = qni
negQ8 qni = qi
negQ8 qj  = qnj
negQ8 qnj = qj
negQ8 qk  = qnk
negQ8 qnk = qk


-- ════════════════════════════════════════════════════════════════════
--  §3.  _*Q8_ — Quaternion multiplication (50 clauses)
-- ════════════════════════════════════════════════════════════════════
--
--  Structured for maximal wildcard coverage:
--    q1  row: wildcard (left identity)
--    qn1 row: via negQ8 (left negation)
--    Remaining 6 rows × 8 columns: explicit (36 + 12 = 48 clauses)

infixl 7 _*Q8_

_*Q8_ : Q8 → Q8 → Q8
-- ── q1 row (identity) ──────────────────────────────────────────
q1  *Q8 y   = y
-- ── qn1 row (negation) ────────────────────────────────────────
qn1 *Q8 y   = negQ8 y
-- ── qi row ─────────────────────────────────────────────────────
qi  *Q8 q1  = qi
qi  *Q8 qn1 = qni
qi  *Q8 qi  = qn1
qi  *Q8 qni = q1
qi  *Q8 qj  = qk
qi  *Q8 qnj = qnk
qi  *Q8 qk  = qnj
qi  *Q8 qnk = qj
-- ── qni row ────────────────────────────────────────────────────
qni *Q8 q1  = qni
qni *Q8 qn1 = qi
qni *Q8 qi  = q1
qni *Q8 qni = qn1
qni *Q8 qj  = qnk
qni *Q8 qnj = qk
qni *Q8 qk  = qj
qni *Q8 qnk = qnj
-- ── qj row ─────────────────────────────────────────────────────
qj  *Q8 q1  = qj
qj  *Q8 qn1 = qnj
qj  *Q8 qi  = qnk
qj  *Q8 qni = qk
qj  *Q8 qj  = qn1
qj  *Q8 qnj = q1
qj  *Q8 qk  = qi
qj  *Q8 qnk = qni
-- ── qnj row ────────────────────────────────────────────────────
qnj *Q8 q1  = qnj
qnj *Q8 qn1 = qj
qnj *Q8 qi  = qk
qnj *Q8 qni = qnk
qnj *Q8 qj  = q1
qnj *Q8 qnj = qn1
qnj *Q8 qk  = qni
qnj *Q8 qnk = qi
-- ── qk row ─────────────────────────────────────────────────────
qk  *Q8 q1  = qk
qk  *Q8 qn1 = qnk
qk  *Q8 qi  = qj
qk  *Q8 qni = qnj
qk  *Q8 qj  = qni
qk  *Q8 qnj = qi
qk  *Q8 qk  = qn1
qk  *Q8 qnk = q1
-- ── qnk row ────────────────────────────────────────────────────
qnk *Q8 q1  = qnk
qnk *Q8 qn1 = qk
qnk *Q8 qi  = qnj
qnk *Q8 qni = qj
qnk *Q8 qj  = qi
qnk *Q8 qnj = qni
qnk *Q8 qk  = q1
qnk *Q8 qnk = qn1


-- ════════════════════════════════════════════════════════════════════
--  §4.  invQ8 — Quaternion inverse
-- ════════════════════════════════════════════════════════════════════
--
--  inv(±1) = ±1,  inv(±x) = ∓x  for x ∈ {i,j,k}

invQ8 : Q8 → Q8
invQ8 q1  = q1
invQ8 qn1 = qn1
invQ8 qi  = qni
invQ8 qni = qi
invQ8 qj  = qnj
invQ8 qnj = qj
invQ8 qk  = qnk
invQ8 qnk = qk


-- ════════════════════════════════════════════════════════════════════
--  §5.  Decidable equality on Q8
-- ════════════════════════════════════════════════════════════════════

private
  -- Discriminator functions: one per constructor
  Dq1  : Q8 → Type₀
  Dq1  q1  = Q8 ; Dq1  _ = ⊥
  Dqn1 : Q8 → Type₀
  Dqn1 qn1 = Q8 ; Dqn1 _ = ⊥
  Dqi  : Q8 → Type₀
  Dqi  qi  = Q8 ; Dqi  _ = ⊥
  Dqni : Q8 → Type₀
  Dqni qni = Q8 ; Dqni _ = ⊥
  Dqj  : Q8 → Type₀
  Dqj  qj  = Q8 ; Dqj  _ = ⊥
  Dqnj : Q8 → Type₀
  Dqnj qnj = Q8 ; Dqnj _ = ⊥
  Dqk  : Q8 → Type₀
  Dqk  qk  = Q8 ; Dqk  _ = ⊥
  Dqnk : Q8 → Type₀
  Dqnk qnk = Q8 ; Dqnk _ = ⊥

  -- Forward distinctness (28 proofs, using discriminators)
  q1≢qn1 : q1 ≡ qn1 → ⊥ ; q1≢qn1 p = subst Dq1 p q1
  q1≢qi  : q1 ≡ qi  → ⊥ ; q1≢qi  p = subst Dq1 p q1
  q1≢qni : q1 ≡ qni → ⊥ ; q1≢qni p = subst Dq1 p q1
  q1≢qj  : q1 ≡ qj  → ⊥ ; q1≢qj  p = subst Dq1 p q1
  q1≢qnj : q1 ≡ qnj → ⊥ ; q1≢qnj p = subst Dq1 p q1
  q1≢qk  : q1 ≡ qk  → ⊥ ; q1≢qk  p = subst Dq1 p q1
  q1≢qnk : q1 ≡ qnk → ⊥ ; q1≢qnk p = subst Dq1 p q1

  qn1≢qi  : qn1 ≡ qi  → ⊥ ; qn1≢qi  p = subst Dqn1 p qn1
  qn1≢qni : qn1 ≡ qni → ⊥ ; qn1≢qni p = subst Dqn1 p qn1
  qn1≢qj  : qn1 ≡ qj  → ⊥ ; qn1≢qj  p = subst Dqn1 p qn1
  qn1≢qnj : qn1 ≡ qnj → ⊥ ; qn1≢qnj p = subst Dqn1 p qn1
  qn1≢qk  : qn1 ≡ qk  → ⊥ ; qn1≢qk  p = subst Dqn1 p qn1
  qn1≢qnk : qn1 ≡ qnk → ⊥ ; qn1≢qnk p = subst Dqn1 p qn1

  qi≢qni : qi ≡ qni → ⊥ ; qi≢qni p = subst Dqi p qi
  qi≢qj  : qi ≡ qj  → ⊥ ; qi≢qj  p = subst Dqi p qi
  qi≢qnj : qi ≡ qnj → ⊥ ; qi≢qnj p = subst Dqi p qi
  qi≢qk  : qi ≡ qk  → ⊥ ; qi≢qk  p = subst Dqi p qi
  qi≢qnk : qi ≡ qnk → ⊥ ; qi≢qnk p = subst Dqi p qi

  qni≢qj  : qni ≡ qj  → ⊥ ; qni≢qj  p = subst Dqni p qni
  qni≢qnj : qni ≡ qnj → ⊥ ; qni≢qnj p = subst Dqni p qni
  qni≢qk  : qni ≡ qk  → ⊥ ; qni≢qk  p = subst Dqni p qni
  qni≢qnk : qni ≡ qnk → ⊥ ; qni≢qnk p = subst Dqni p qni

  qj≢qnj : qj ≡ qnj → ⊥ ; qj≢qnj p = subst Dqj p qj
  qj≢qk  : qj ≡ qk  → ⊥ ; qj≢qk  p = subst Dqj p qj
  qj≢qnk : qj ≡ qnk → ⊥ ; qj≢qnk p = subst Dqj p qj

  qnj≢qk  : qnj ≡ qk  → ⊥ ; qnj≢qk  p = subst Dqnj p qnj
  qnj≢qnk : qnj ≡ qnk → ⊥ ; qnj≢qnk p = subst Dqnj p qnj

  qk≢qnk : qk ≡ qnk → ⊥ ; qk≢qnk p = subst Dqk p qk


discreteQ8 : Discrete Q8
discreteQ8 q1  q1  = yes refl
discreteQ8 q1  qn1 = no q1≢qn1
discreteQ8 q1  qi  = no q1≢qi
discreteQ8 q1  qni = no q1≢qni
discreteQ8 q1  qj  = no q1≢qj
discreteQ8 q1  qnj = no q1≢qnj
discreteQ8 q1  qk  = no q1≢qk
discreteQ8 q1  qnk = no q1≢qnk
discreteQ8 qn1 q1  = no (λ p → q1≢qn1 (sym p))
discreteQ8 qn1 qn1 = yes refl
discreteQ8 qn1 qi  = no qn1≢qi
discreteQ8 qn1 qni = no qn1≢qni
discreteQ8 qn1 qj  = no qn1≢qj
discreteQ8 qn1 qnj = no qn1≢qnj
discreteQ8 qn1 qk  = no qn1≢qk
discreteQ8 qn1 qnk = no qn1≢qnk
discreteQ8 qi  q1  = no (λ p → q1≢qi  (sym p))
discreteQ8 qi  qn1 = no (λ p → qn1≢qi (sym p))
discreteQ8 qi  qi  = yes refl
discreteQ8 qi  qni = no qi≢qni
discreteQ8 qi  qj  = no qi≢qj
discreteQ8 qi  qnj = no qi≢qnj
discreteQ8 qi  qk  = no qi≢qk
discreteQ8 qi  qnk = no qi≢qnk
discreteQ8 qni q1  = no (λ p → q1≢qni  (sym p))
discreteQ8 qni qn1 = no (λ p → qn1≢qni (sym p))
discreteQ8 qni qi  = no (λ p → qi≢qni  (sym p))
discreteQ8 qni qni = yes refl
discreteQ8 qni qj  = no qni≢qj
discreteQ8 qni qnj = no qni≢qnj
discreteQ8 qni qk  = no qni≢qk
discreteQ8 qni qnk = no qni≢qnk
discreteQ8 qj  q1  = no (λ p → q1≢qj   (sym p))
discreteQ8 qj  qn1 = no (λ p → qn1≢qj  (sym p))
discreteQ8 qj  qi  = no (λ p → qi≢qj   (sym p))
discreteQ8 qj  qni = no (λ p → qni≢qj  (sym p))
discreteQ8 qj  qj  = yes refl
discreteQ8 qj  qnj = no qj≢qnj
discreteQ8 qj  qk  = no qj≢qk
discreteQ8 qj  qnk = no qj≢qnk
discreteQ8 qnj q1  = no (λ p → q1≢qnj  (sym p))
discreteQ8 qnj qn1 = no (λ p → qn1≢qnj (sym p))
discreteQ8 qnj qi  = no (λ p → qi≢qnj  (sym p))
discreteQ8 qnj qni = no (λ p → qni≢qnj (sym p))
discreteQ8 qnj qj  = no (λ p → qj≢qnj  (sym p))
discreteQ8 qnj qnj = yes refl
discreteQ8 qnj qk  = no qnj≢qk
discreteQ8 qnj qnk = no qnj≢qnk
discreteQ8 qk  q1  = no (λ p → q1≢qk   (sym p))
discreteQ8 qk  qn1 = no (λ p → qn1≢qk  (sym p))
discreteQ8 qk  qi  = no (λ p → qi≢qk   (sym p))
discreteQ8 qk  qni = no (λ p → qni≢qk  (sym p))
discreteQ8 qk  qj  = no (λ p → qj≢qk   (sym p))
discreteQ8 qk  qnj = no (λ p → qnj≢qk  (sym p))
discreteQ8 qk  qk  = yes refl
discreteQ8 qk  qnk = no qk≢qnk
discreteQ8 qnk q1  = no (λ p → q1≢qnk  (sym p))
discreteQ8 qnk qn1 = no (λ p → qn1≢qnk (sym p))
discreteQ8 qnk qi  = no (λ p → qi≢qnk  (sym p))
discreteQ8 qnk qni = no (λ p → qni≢qnk (sym p))
discreteQ8 qnk qj  = no (λ p → qj≢qnk  (sym p))
discreteQ8 qnk qnj = no (λ p → qnj≢qnk (sym p))
discreteQ8 qnk qk  = no (λ p → qk≢qnk  (sym p))
discreteQ8 qnk qnk = yes refl

isSetQ8 : isSet Q8
isSetQ8 = Discrete→isSet discreteQ8


-- ════════════════════════════════════════════════════════════════════
--  §6.  Group axioms — all by refl
-- ════════════════════════════════════════════════════════════════════
--
--  Every axiom is proved by exhaustive case split on the Q8
--  arguments, with each case holding by  refl  because pattern
--  matching on closed constructor terms reduces judgmentally.
--
--  This is the "exhaustive case split on closed constructor terms"
--  proof strategy described in docs/formal/05-gauge-theory.md §2
--  and docs/reference/assumptions.md §A9.
--
--  Case counts:
--    Q8-identityˡ:   0 cases (wildcard — q1 is left-absorbing)
--    Q8-identityʳ:   8 cases
--    Q8-inverseˡ:    8 cases
--    Q8-inverseʳ:    8 cases
--    Q8-assoc:     400 cases (1 wildcard + 7 wildcard + 392 explicit)
--    Total:        424 cases, all refl.
-- ════════════════════════════════════════════════════════════════════

-- ── §6a.  Left identity:  q1 * x ≡ x ─────────────────────────
Q8-identityˡ : (x : Q8) → q1 *Q8 x ≡ x
Q8-identityˡ _ = refl

-- ── §6b.  Right identity:  x * q1 ≡ x ────────────────────────
Q8-identityʳ : (x : Q8) → x *Q8 q1 ≡ x
Q8-identityʳ q1  = refl
Q8-identityʳ qn1 = refl
Q8-identityʳ qi  = refl
Q8-identityʳ qni = refl
Q8-identityʳ qj  = refl
Q8-identityʳ qnj = refl
Q8-identityʳ qk  = refl
Q8-identityʳ qnk = refl

-- ── §6c.  Left inverse:  invQ8 x * x ≡ q1 ────────────────────
Q8-inverseˡ : (x : Q8) → invQ8 x *Q8 x ≡ q1
Q8-inverseˡ q1  = refl
Q8-inverseˡ qn1 = refl
Q8-inverseˡ qi  = refl
Q8-inverseˡ qni = refl
Q8-inverseˡ qj  = refl
Q8-inverseˡ qnj = refl
Q8-inverseˡ qk  = refl
Q8-inverseˡ qnk = refl

-- ── §6d.  Right inverse:  x * invQ8 x ≡ q1 ───────────────────
Q8-inverseʳ : (x : Q8) → x *Q8 invQ8 x ≡ q1
Q8-inverseʳ q1  = refl
Q8-inverseʳ qn1 = refl
Q8-inverseʳ qi  = refl
Q8-inverseʳ qni = refl
Q8-inverseʳ qj  = refl
Q8-inverseʳ qnj = refl
Q8-inverseʳ qk  = refl
Q8-inverseʳ qnk = refl

-- ── §6e.  Associativity:  (x * y) * z ≡ x * (y * z) ──────────
--
--  The proof has 400 clauses organized as:
--    • x = q1:    1 clause (wildcard on y, z)
--    • x ≠ q1, y = q1:  7 clauses (case on x, wildcard on z)
--    • x ≠ q1, y ≠ q1:  7 × 7 × 8 = 392 clauses
--
--  Each case holds by refl because all three arguments are
--  concrete constructors, and _*Q8_ reduces by pattern matching.
--
--  This is the largest single exhaustive verification in the
--  repository (400 cases).  See docs/engineering/scaling-report.md
--  for expected parse and type-check times (~5–10s parse,
--  ~10–30s check, ~1.5 GB peak RAM).

Q8-assoc : (x y z : Q8) → (x *Q8 y) *Q8 z ≡ x *Q8 (y *Q8 z)
-- ── x = q1 ─────────────────────────────────────────────────────
Q8-assoc q1  _   _   = refl
-- ── y = q1 (x ≠ q1) ────────────────────────────────────────────
Q8-assoc qn1 q1  _   = refl
Q8-assoc qi  q1  _   = refl
Q8-assoc qni q1  _   = refl
Q8-assoc qj  q1  _   = refl
Q8-assoc qnj q1  _   = refl
Q8-assoc qk  q1  _   = refl
Q8-assoc qnk q1  _   = refl
-- ── x = qn1, y ≠ q1 ────────────────────────────────────────────
Q8-assoc qn1 qn1 q1  = refl ; Q8-assoc qn1 qn1 qn1 = refl
Q8-assoc qn1 qn1 qi  = refl ; Q8-assoc qn1 qn1 qni = refl
Q8-assoc qn1 qn1 qj  = refl ; Q8-assoc qn1 qn1 qnj = refl
Q8-assoc qn1 qn1 qk  = refl ; Q8-assoc qn1 qn1 qnk = refl
Q8-assoc qn1 qi  q1  = refl ; Q8-assoc qn1 qi  qn1 = refl
Q8-assoc qn1 qi  qi  = refl ; Q8-assoc qn1 qi  qni = refl
Q8-assoc qn1 qi  qj  = refl ; Q8-assoc qn1 qi  qnj = refl
Q8-assoc qn1 qi  qk  = refl ; Q8-assoc qn1 qi  qnk = refl
Q8-assoc qn1 qni q1  = refl ; Q8-assoc qn1 qni qn1 = refl
Q8-assoc qn1 qni qi  = refl ; Q8-assoc qn1 qni qni = refl
Q8-assoc qn1 qni qj  = refl ; Q8-assoc qn1 qni qnj = refl
Q8-assoc qn1 qni qk  = refl ; Q8-assoc qn1 qni qnk = refl
Q8-assoc qn1 qj  q1  = refl ; Q8-assoc qn1 qj  qn1 = refl
Q8-assoc qn1 qj  qi  = refl ; Q8-assoc qn1 qj  qni = refl
Q8-assoc qn1 qj  qj  = refl ; Q8-assoc qn1 qj  qnj = refl
Q8-assoc qn1 qj  qk  = refl ; Q8-assoc qn1 qj  qnk = refl
Q8-assoc qn1 qnj q1  = refl ; Q8-assoc qn1 qnj qn1 = refl
Q8-assoc qn1 qnj qi  = refl ; Q8-assoc qn1 qnj qni = refl
Q8-assoc qn1 qnj qj  = refl ; Q8-assoc qn1 qnj qnj = refl
Q8-assoc qn1 qnj qk  = refl ; Q8-assoc qn1 qnj qnk = refl
Q8-assoc qn1 qk  q1  = refl ; Q8-assoc qn1 qk  qn1 = refl
Q8-assoc qn1 qk  qi  = refl ; Q8-assoc qn1 qk  qni = refl
Q8-assoc qn1 qk  qj  = refl ; Q8-assoc qn1 qk  qnj = refl
Q8-assoc qn1 qk  qk  = refl ; Q8-assoc qn1 qk  qnk = refl
Q8-assoc qn1 qnk q1  = refl ; Q8-assoc qn1 qnk qn1 = refl
Q8-assoc qn1 qnk qi  = refl ; Q8-assoc qn1 qnk qni = refl
Q8-assoc qn1 qnk qj  = refl ; Q8-assoc qn1 qnk qnj = refl
Q8-assoc qn1 qnk qk  = refl ; Q8-assoc qn1 qnk qnk = refl
-- ── x = qi, y ≠ q1 ─────────────────────────────────────────────
Q8-assoc qi  qn1 q1  = refl ; Q8-assoc qi  qn1 qn1 = refl
Q8-assoc qi  qn1 qi  = refl ; Q8-assoc qi  qn1 qni = refl
Q8-assoc qi  qn1 qj  = refl ; Q8-assoc qi  qn1 qnj = refl
Q8-assoc qi  qn1 qk  = refl ; Q8-assoc qi  qn1 qnk = refl
Q8-assoc qi  qi  q1  = refl ; Q8-assoc qi  qi  qn1 = refl
Q8-assoc qi  qi  qi  = refl ; Q8-assoc qi  qi  qni = refl
Q8-assoc qi  qi  qj  = refl ; Q8-assoc qi  qi  qnj = refl
Q8-assoc qi  qi  qk  = refl ; Q8-assoc qi  qi  qnk = refl
Q8-assoc qi  qni q1  = refl ; Q8-assoc qi  qni qn1 = refl
Q8-assoc qi  qni qi  = refl ; Q8-assoc qi  qni qni = refl
Q8-assoc qi  qni qj  = refl ; Q8-assoc qi  qni qnj = refl
Q8-assoc qi  qni qk  = refl ; Q8-assoc qi  qni qnk = refl
Q8-assoc qi  qj  q1  = refl ; Q8-assoc qi  qj  qn1 = refl
Q8-assoc qi  qj  qi  = refl ; Q8-assoc qi  qj  qni = refl
Q8-assoc qi  qj  qj  = refl ; Q8-assoc qi  qj  qnj = refl
Q8-assoc qi  qj  qk  = refl ; Q8-assoc qi  qj  qnk = refl
Q8-assoc qi  qnj q1  = refl ; Q8-assoc qi  qnj qn1 = refl
Q8-assoc qi  qnj qi  = refl ; Q8-assoc qi  qnj qni = refl
Q8-assoc qi  qnj qj  = refl ; Q8-assoc qi  qnj qnj = refl
Q8-assoc qi  qnj qk  = refl ; Q8-assoc qi  qnj qnk = refl
Q8-assoc qi  qk  q1  = refl ; Q8-assoc qi  qk  qn1 = refl
Q8-assoc qi  qk  qi  = refl ; Q8-assoc qi  qk  qni = refl
Q8-assoc qi  qk  qj  = refl ; Q8-assoc qi  qk  qnj = refl
Q8-assoc qi  qk  qk  = refl ; Q8-assoc qi  qk  qnk = refl
Q8-assoc qi  qnk q1  = refl ; Q8-assoc qi  qnk qn1 = refl
Q8-assoc qi  qnk qi  = refl ; Q8-assoc qi  qnk qni = refl
Q8-assoc qi  qnk qj  = refl ; Q8-assoc qi  qnk qnj = refl
Q8-assoc qi  qnk qk  = refl ; Q8-assoc qi  qnk qnk = refl
-- ── x = qni, y ≠ q1 ────────────────────────────────────────────
Q8-assoc qni qn1 q1  = refl ; Q8-assoc qni qn1 qn1 = refl
Q8-assoc qni qn1 qi  = refl ; Q8-assoc qni qn1 qni = refl
Q8-assoc qni qn1 qj  = refl ; Q8-assoc qni qn1 qnj = refl
Q8-assoc qni qn1 qk  = refl ; Q8-assoc qni qn1 qnk = refl
Q8-assoc qni qi  q1  = refl ; Q8-assoc qni qi  qn1 = refl
Q8-assoc qni qi  qi  = refl ; Q8-assoc qni qi  qni = refl
Q8-assoc qni qi  qj  = refl ; Q8-assoc qni qi  qnj = refl
Q8-assoc qni qi  qk  = refl ; Q8-assoc qni qi  qnk = refl
Q8-assoc qni qni q1  = refl ; Q8-assoc qni qni qn1 = refl
Q8-assoc qni qni qi  = refl ; Q8-assoc qni qni qni = refl
Q8-assoc qni qni qj  = refl ; Q8-assoc qni qni qnj = refl
Q8-assoc qni qni qk  = refl ; Q8-assoc qni qni qnk = refl
Q8-assoc qni qj  q1  = refl ; Q8-assoc qni qj  qn1 = refl
Q8-assoc qni qj  qi  = refl ; Q8-assoc qni qj  qni = refl
Q8-assoc qni qj  qj  = refl ; Q8-assoc qni qj  qnj = refl
Q8-assoc qni qj  qk  = refl ; Q8-assoc qni qj  qnk = refl
Q8-assoc qni qnj q1  = refl ; Q8-assoc qni qnj qn1 = refl
Q8-assoc qni qnj qi  = refl ; Q8-assoc qni qnj qni = refl
Q8-assoc qni qnj qj  = refl ; Q8-assoc qni qnj qnj = refl
Q8-assoc qni qnj qk  = refl ; Q8-assoc qni qnj qnk = refl
Q8-assoc qni qk  q1  = refl ; Q8-assoc qni qk  qn1 = refl
Q8-assoc qni qk  qi  = refl ; Q8-assoc qni qk  qni = refl
Q8-assoc qni qk  qj  = refl ; Q8-assoc qni qk  qnj = refl
Q8-assoc qni qk  qk  = refl ; Q8-assoc qni qk  qnk = refl
Q8-assoc qni qnk q1  = refl ; Q8-assoc qni qnk qn1 = refl
Q8-assoc qni qnk qi  = refl ; Q8-assoc qni qnk qni = refl
Q8-assoc qni qnk qj  = refl ; Q8-assoc qni qnk qnj = refl
Q8-assoc qni qnk qk  = refl ; Q8-assoc qni qnk qnk = refl
-- ── x = qj, y ≠ q1 ─────────────────────────────────────────────
Q8-assoc qj  qn1 q1  = refl ; Q8-assoc qj  qn1 qn1 = refl
Q8-assoc qj  qn1 qi  = refl ; Q8-assoc qj  qn1 qni = refl
Q8-assoc qj  qn1 qj  = refl ; Q8-assoc qj  qn1 qnj = refl
Q8-assoc qj  qn1 qk  = refl ; Q8-assoc qj  qn1 qnk = refl
Q8-assoc qj  qi  q1  = refl ; Q8-assoc qj  qi  qn1 = refl
Q8-assoc qj  qi  qi  = refl ; Q8-assoc qj  qi  qni = refl
Q8-assoc qj  qi  qj  = refl ; Q8-assoc qj  qi  qnj = refl
Q8-assoc qj  qi  qk  = refl ; Q8-assoc qj  qi  qnk = refl
Q8-assoc qj  qni q1  = refl ; Q8-assoc qj  qni qn1 = refl
Q8-assoc qj  qni qi  = refl ; Q8-assoc qj  qni qni = refl
Q8-assoc qj  qni qj  = refl ; Q8-assoc qj  qni qnj = refl
Q8-assoc qj  qni qk  = refl ; Q8-assoc qj  qni qnk = refl
Q8-assoc qj  qj  q1  = refl ; Q8-assoc qj  qj  qn1 = refl
Q8-assoc qj  qj  qi  = refl ; Q8-assoc qj  qj  qni = refl
Q8-assoc qj  qj  qj  = refl ; Q8-assoc qj  qj  qnj = refl
Q8-assoc qj  qj  qk  = refl ; Q8-assoc qj  qj  qnk = refl
Q8-assoc qj  qnj q1  = refl ; Q8-assoc qj  qnj qn1 = refl
Q8-assoc qj  qnj qi  = refl ; Q8-assoc qj  qnj qni = refl
Q8-assoc qj  qnj qj  = refl ; Q8-assoc qj  qnj qnj = refl
Q8-assoc qj  qnj qk  = refl ; Q8-assoc qj  qnj qnk = refl
Q8-assoc qj  qk  q1  = refl ; Q8-assoc qj  qk  qn1 = refl
Q8-assoc qj  qk  qi  = refl ; Q8-assoc qj  qk  qni = refl
Q8-assoc qj  qk  qj  = refl ; Q8-assoc qj  qk  qnj = refl
Q8-assoc qj  qk  qk  = refl ; Q8-assoc qj  qk  qnk = refl
Q8-assoc qj  qnk q1  = refl ; Q8-assoc qj  qnk qn1 = refl
Q8-assoc qj  qnk qi  = refl ; Q8-assoc qj  qnk qni = refl
Q8-assoc qj  qnk qj  = refl ; Q8-assoc qj  qnk qnj = refl
Q8-assoc qj  qnk qk  = refl ; Q8-assoc qj  qnk qnk = refl
-- ── x = qnj, y ≠ q1 ────────────────────────────────────────────
Q8-assoc qnj qn1 q1  = refl ; Q8-assoc qnj qn1 qn1 = refl
Q8-assoc qnj qn1 qi  = refl ; Q8-assoc qnj qn1 qni = refl
Q8-assoc qnj qn1 qj  = refl ; Q8-assoc qnj qn1 qnj = refl
Q8-assoc qnj qn1 qk  = refl ; Q8-assoc qnj qn1 qnk = refl
Q8-assoc qnj qi  q1  = refl ; Q8-assoc qnj qi  qn1 = refl
Q8-assoc qnj qi  qi  = refl ; Q8-assoc qnj qi  qni = refl
Q8-assoc qnj qi  qj  = refl ; Q8-assoc qnj qi  qnj = refl
Q8-assoc qnj qi  qk  = refl ; Q8-assoc qnj qi  qnk = refl
Q8-assoc qnj qni q1  = refl ; Q8-assoc qnj qni qn1 = refl
Q8-assoc qnj qni qi  = refl ; Q8-assoc qnj qni qni = refl
Q8-assoc qnj qni qj  = refl ; Q8-assoc qnj qni qnj = refl
Q8-assoc qnj qni qk  = refl ; Q8-assoc qnj qni qnk = refl
Q8-assoc qnj qj  q1  = refl ; Q8-assoc qnj qj  qn1 = refl
Q8-assoc qnj qj  qi  = refl ; Q8-assoc qnj qj  qni = refl
Q8-assoc qnj qj  qj  = refl ; Q8-assoc qnj qj  qnj = refl
Q8-assoc qnj qj  qk  = refl ; Q8-assoc qnj qj  qnk = refl
Q8-assoc qnj qnj q1  = refl ; Q8-assoc qnj qnj qn1 = refl
Q8-assoc qnj qnj qi  = refl ; Q8-assoc qnj qnj qni = refl
Q8-assoc qnj qnj qj  = refl ; Q8-assoc qnj qnj qnj = refl
Q8-assoc qnj qnj qk  = refl ; Q8-assoc qnj qnj qnk = refl
Q8-assoc qnj qk  q1  = refl ; Q8-assoc qnj qk  qn1 = refl
Q8-assoc qnj qk  qi  = refl ; Q8-assoc qnj qk  qni = refl
Q8-assoc qnj qk  qj  = refl ; Q8-assoc qnj qk  qnj = refl
Q8-assoc qnj qk  qk  = refl ; Q8-assoc qnj qk  qnk = refl
Q8-assoc qnj qnk q1  = refl ; Q8-assoc qnj qnk qn1 = refl
Q8-assoc qnj qnk qi  = refl ; Q8-assoc qnj qnk qni = refl
Q8-assoc qnj qnk qj  = refl ; Q8-assoc qnj qnk qnj = refl
Q8-assoc qnj qnk qk  = refl ; Q8-assoc qnj qnk qnk = refl
-- ── x = qk, y ≠ q1 ─────────────────────────────────────────────
Q8-assoc qk  qn1 q1  = refl ; Q8-assoc qk  qn1 qn1 = refl
Q8-assoc qk  qn1 qi  = refl ; Q8-assoc qk  qn1 qni = refl
Q8-assoc qk  qn1 qj  = refl ; Q8-assoc qk  qn1 qnj = refl
Q8-assoc qk  qn1 qk  = refl ; Q8-assoc qk  qn1 qnk = refl
Q8-assoc qk  qi  q1  = refl ; Q8-assoc qk  qi  qn1 = refl
Q8-assoc qk  qi  qi  = refl ; Q8-assoc qk  qi  qni = refl
Q8-assoc qk  qi  qj  = refl ; Q8-assoc qk  qi  qnj = refl
Q8-assoc qk  qi  qk  = refl ; Q8-assoc qk  qi  qnk = refl
Q8-assoc qk  qni q1  = refl ; Q8-assoc qk  qni qn1 = refl
Q8-assoc qk  qni qi  = refl ; Q8-assoc qk  qni qni = refl
Q8-assoc qk  qni qj  = refl ; Q8-assoc qk  qni qnj = refl
Q8-assoc qk  qni qk  = refl ; Q8-assoc qk  qni qnk = refl
Q8-assoc qk  qj  q1  = refl ; Q8-assoc qk  qj  qn1 = refl
Q8-assoc qk  qj  qi  = refl ; Q8-assoc qk  qj  qni = refl
Q8-assoc qk  qj  qj  = refl ; Q8-assoc qk  qj  qnj = refl
Q8-assoc qk  qj  qk  = refl ; Q8-assoc qk  qj  qnk = refl
Q8-assoc qk  qnj q1  = refl ; Q8-assoc qk  qnj qn1 = refl
Q8-assoc qk  qnj qi  = refl ; Q8-assoc qk  qnj qni = refl
Q8-assoc qk  qnj qj  = refl ; Q8-assoc qk  qnj qnj = refl
Q8-assoc qk  qnj qk  = refl ; Q8-assoc qk  qnj qnk = refl
Q8-assoc qk  qk  q1  = refl ; Q8-assoc qk  qk  qn1 = refl
Q8-assoc qk  qk  qi  = refl ; Q8-assoc qk  qk  qni = refl
Q8-assoc qk  qk  qj  = refl ; Q8-assoc qk  qk  qnj = refl
Q8-assoc qk  qk  qk  = refl ; Q8-assoc qk  qk  qnk = refl
Q8-assoc qk  qnk q1  = refl ; Q8-assoc qk  qnk qn1 = refl
Q8-assoc qk  qnk qi  = refl ; Q8-assoc qk  qnk qni = refl
Q8-assoc qk  qnk qj  = refl ; Q8-assoc qk  qnk qnj = refl
Q8-assoc qk  qnk qk  = refl ; Q8-assoc qk  qnk qnk = refl
-- ── x = qnk, y ≠ q1 ────────────────────────────────────────────
Q8-assoc qnk qn1 q1  = refl ; Q8-assoc qnk qn1 qn1 = refl
Q8-assoc qnk qn1 qi  = refl ; Q8-assoc qnk qn1 qni = refl
Q8-assoc qnk qn1 qj  = refl ; Q8-assoc qnk qn1 qnj = refl
Q8-assoc qnk qn1 qk  = refl ; Q8-assoc qnk qn1 qnk = refl
Q8-assoc qnk qi  q1  = refl ; Q8-assoc qnk qi  qn1 = refl
Q8-assoc qnk qi  qi  = refl ; Q8-assoc qnk qi  qni = refl
Q8-assoc qnk qi  qj  = refl ; Q8-assoc qnk qi  qnj = refl
Q8-assoc qnk qi  qk  = refl ; Q8-assoc qnk qi  qnk = refl
Q8-assoc qnk qni q1  = refl ; Q8-assoc qnk qni qn1 = refl
Q8-assoc qnk qni qi  = refl ; Q8-assoc qnk qni qni = refl
Q8-assoc qnk qni qj  = refl ; Q8-assoc qnk qni qnj = refl
Q8-assoc qnk qni qk  = refl ; Q8-assoc qnk qni qnk = refl
Q8-assoc qnk qj  q1  = refl ; Q8-assoc qnk qj  qn1 = refl
Q8-assoc qnk qj  qi  = refl ; Q8-assoc qnk qj  qni = refl
Q8-assoc qnk qj  qj  = refl ; Q8-assoc qnk qj  qnj = refl
Q8-assoc qnk qj  qk  = refl ; Q8-assoc qnk qj  qnk = refl
Q8-assoc qnk qnj q1  = refl ; Q8-assoc qnk qnj qn1 = refl
Q8-assoc qnk qnj qi  = refl ; Q8-assoc qnk qnj qni = refl
Q8-assoc qnk qnj qj  = refl ; Q8-assoc qnk qnj qnj = refl
Q8-assoc qnk qnj qk  = refl ; Q8-assoc qnk qnj qnk = refl
Q8-assoc qnk qk  q1  = refl ; Q8-assoc qnk qk  qn1 = refl
Q8-assoc qnk qk  qi  = refl ; Q8-assoc qnk qk  qni = refl
Q8-assoc qnk qk  qj  = refl ; Q8-assoc qnk qk  qnj = refl
Q8-assoc qnk qk  qk  = refl ; Q8-assoc qnk qk  qnk = refl
Q8-assoc qnk qnk q1  = refl ; Q8-assoc qnk qnk qn1 = refl
Q8-assoc qnk qnk qi  = refl ; Q8-assoc qnk qnk qni = refl
Q8-assoc qnk qnk qj  = refl ; Q8-assoc qnk qnk qnj = refl
Q8-assoc qnk qnk qk  = refl ; Q8-assoc qnk qnk qnk = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Q₈ — The concrete FiniteGroup instance
-- ════════════════════════════════════════════════════════════════════
--
--  Q₈ is the first non-abelian gauge group in the repository.
--  It is the finite replacement for SU(2) in the discrete
--  Standard Model gauge group
--  (docs/formal/05-gauge-theory.md §2):
--
--    G_discrete = Δ(27) × Q₈ × ℤ/nℤ
--
--  Particle spectrum:  5 conjugacy classes → vacuum + 4 species
--  (docs/formal/05-gauge-theory.md §7)
--
--  Representation theory:
--    5 irreps of dimensions  1, 1, 1, 1, 2
--    The 2-dimensional irrep (the fundamental representation)
--    gives bond capacity 2 when used as a spin label, via the
--    dimension functor  dim : Rep G → ℕ  (Gauge/RepCapacity.agda).
--    See docs/formal/05-gauge-theory.md §8 for the capacity
--    extraction and the gauge-enriched bridge.
--
--  This instance is consumed by:
--    • Gauge/Connection.agda  — starQ8-i, starQ8-ij, starQ8-ji
--    • Gauge/Holonomy.agda    — defect-Q8-i, noncommutative-holonomy
--    • Gauge/ConjugacyClass.agda — 5 Q₈ conjugacy classes
--    • Gauge/RepCapacity.agda — dimWeightedBridge, gauged-star-Q8
--    • Quantum/StarQuantumBridge.agda — quantum superposition bridge
-- ════════════════════════════════════════════════════════════════════

Q₈ : FiniteGroup
Q₈ .FiniteGroup.Carrier      = Q8
Q₈ .FiniteGroup.ε            = q1
Q₈ .FiniteGroup._·_          = _*Q8_
Q₈ .FiniteGroup.inv          = invQ8
Q₈ .FiniteGroup.isSetCarrier = isSetQ8
Q₈ .FiniteGroup._≟_          = discreteQ8
Q₈ .FiniteGroup.·-identityˡ  = Q8-identityˡ
Q₈ .FiniteGroup.·-identityʳ  = Q8-identityʳ
Q₈ .FiniteGroup.·-inverseˡ   = Q8-inverseˡ
Q₈ .FiniteGroup.·-inverseʳ   = Q8-inverseʳ
Q₈ .FiniteGroup.·-assoc      = Q8-assoc


-- ════════════════════════════════════════════════════════════════════
--  §8.  Regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the Q₈ multiplication table, inverse map, and
--  record field access reduce to the expected values on closed
--  constructor terms.  They serve as regression tests: if any
--  definition is accidentally changed, these proofs will fail at
--  type-check time.

private
  -- Fundamental quaternion relations
  check-ii : qi *Q8 qi ≡ qn1
  check-ii = refl

  check-jj : qj *Q8 qj ≡ qn1
  check-jj = refl

  check-kk : qk *Q8 qk ≡ qn1
  check-kk = refl

  check-ij : qi *Q8 qj ≡ qk
  check-ij = refl

  check-jk : qj *Q8 qk ≡ qi
  check-jk = refl

  check-ki : qk *Q8 qi ≡ qj
  check-ki = refl

  -- Non-commutativity witnesses
  check-ji : qj *Q8 qi ≡ qnk
  check-ji = refl

  check-kj : qk *Q8 qj ≡ qni
  check-kj = refl

  check-ik : qi *Q8 qk ≡ qnj
  check-ik = refl

  -- ijk = −1
  check-ijk : qi *Q8 (qj *Q8 qk) ≡ qn1
  check-ijk = refl

  -- Inverse table
  check-inv-i : invQ8 qi ≡ qni
  check-inv-i = refl

  check-inv-ni : invQ8 qni ≡ qi
  check-inv-ni = refl

  -- Identity is q1
  check-ε : FiniteGroup.ε Q₈ ≡ q1
  check-ε = refl

  -- Decidable equality spot check
  check-dec-q1 : discreteQ8 q1 q1 ≡ yes refl
  check-dec-q1 = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Non-commutativity witness
-- ════════════════════════════════════════════════════════════════════
--
--  Q₈ is the first non-abelian group in the repository.
--  ij = k ≠ −k = ji demonstrates non-commutativity.
--
--  The proof uses the Dqk discriminator (from §5) which maps
--  qk to an inhabited type and qnk to ⊥, then  subst  along
--  the hypothetical path  qk ≡ qnk  to derive ⊥.
--
--  This witness is consumed by Gauge/Holonomy.agda to construct
--  noncommutative-holonomy: swapping two Q₈ bond assignments
--  changes the Wilson loop from k to −k.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §4.3  (Q₈ non-commutativity)
--    docs/formal/05-gauge-theory.md §6    (non-commutative holonomy)

Q8-noncomm : (qi *Q8 qj ≡ qj *Q8 qi) → ⊥
Q8-noncomm p = subst Dqk p qk