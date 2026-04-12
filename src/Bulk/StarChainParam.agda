{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.StarChainParam where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.StarSpec
open import Bulk.StarChain using (L-min ; πbulk ; BulkView)
open import Boundary.StarCutParam using (S-param)


-- ════════════════════════════════════════════════════════════════════
--  L-param — Parameterized bulk minimal chain for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  For each representative boundary region, L-param computes the
--  minimal separating-chain cost from an arbitrary bond-weight
--  function  w : Bond → ℚ≥0 .
--
--  In the 6-tile star topology, every minimal separating chain
--  severs a subset of the 5 central bonds C–N_i.  For a contiguous
--  region of k tiles:
--
--    Singletons  {N_i}:            chain = {C–N_i}            → w(bCN_i)
--    Pairs       {N_i, N_{i+1}}:   chain = {C–N_i, C–N_{i+1}} → w(bCN_i) + w(bCN_{i+1})
--
--  This definition is IDENTICAL to  S-param  from
--  Boundary/StarCutParam.agda .  The coincidence is not accidental:
--  in the star topology, the boundary min-cut and the bulk minimal
--  separating chain are always the same set of bonds, because every
--  cut must pass through central bonds (never through boundary
--  legs).  This is the structural reason why the discrete
--  Ryu–Takayanagi correspondence holds for the star.
--
--  The coincidence S-param = L-param (proven below as  SL-param )
--  is what makes the step-invariance theorem (Theorem 9 in
--  docs/formal/01-theorems.md) trivial for the star topology:  any
--  perturbation of the weight function affects both observables
--  identically.
--
--  Downstream modules:
--    src/Bridge/StarStepInvariance.agda   (step-invariance theorem)
--    src/Bridge/StarDynamicsLoop.agda     (iterated loop)
--
--  Architectural role:
--    This is a Tier 2 (Observable Layer) module providing the
--    parameterized bulk observable consumed by the dynamics layer.
--    The boundary-side counterpart is S-param in
--    Boundary/StarCutParam.agda.  For the star topology, S-param
--    and L-param are definitionally the same function — the
--    structural content of the discrete RT correspondence for
--    parameterized weights.
--
--  Reference:
--    docs/formal/10-dynamics.md §2        (parameterized observables)
--    docs/formal/01-theorems.md §Thm 9    (step invariance statement)
--    docs/instances/star-patch.md §7      (dynamics on the star patch)
--    docs/reference/module-index.md       (module description)
-- ════════════════════════════════════════════════════════════════════

L-param : (Bond → ℚ≥0) → Region → ℚ≥0
L-param w regN0   = w bCN0
L-param w regN1   = w bCN1
L-param w regN2   = w bCN2
L-param w regN3   = w bCN3
L-param w regN4   = w bCN4
L-param w regN0N1 = w bCN0 +ℚ w bCN1
L-param w regN1N2 = w bCN1 +ℚ w bCN2
L-param w regN2N3 = w bCN2 +ℚ w bCN3
L-param w regN3N4 = w bCN3 +ℚ w bCN4
L-param w regN4N0 = w bCN4 +ℚ w bCN0


-- ════════════════════════════════════════════════════════════════════
--  §1.  Specification agreement: L-param starWeight ≡ L-min
-- ════════════════════════════════════════════════════════════════════
--
--  At the canonical weight assignment  starWeight  (all bonds = 1q),
--  the parameterized observable  L-param starWeight  reduces to the
--  same ℕ literals as the existing lookup table  L-min .
--
--  For singletons:
--    L-param starWeight regN_i = starWeight bCN_i = 1q = L-min kv regN_i
--
--  For pairs:
--    L-param starWeight regN_iN_j
--      = starWeight bCN_i +ℚ starWeight bCN_j
--      = 1q +ℚ 1q
--      = 2q               (by judgmental computation: suc zero + suc zero = suc (suc zero))
--      = L-min kv regN_iN_j
--
--  All 10 cases hold by  refl  because ℕ addition computes by
--  structural recursion on the first argument, and 1 + 1 = 2
--  judgmentally.
--
--  This lemma connects the parameterized bulk observable (used by
--  the step-invariance theorem) to the existing verified bridge
--  (star-pointwise in Bridge/StarObs.agda), ensuring that the
--  new parameterized development is consistent with all existing
--  refl-based proofs.
--
--  Reference:
--    docs/formal/10-dynamics.md §2.5   (specification agreement)
--    docs/formal/02-foundations.md §6.3 (shared-constants discipline)
-- ════════════════════════════════════════════════════════════════════

L-param-spec-pointwise :
  (r : Region) →
  L-param starWeight r ≡ L-min (πbulk starSpec) r
L-param-spec-pointwise regN0   = refl
L-param-spec-pointwise regN1   = refl
L-param-spec-pointwise regN2   = refl
L-param-spec-pointwise regN3   = refl
L-param-spec-pointwise regN4   = refl
L-param-spec-pointwise regN0N1 = refl   -- 1 + 1 = 2  judgmentally
L-param-spec-pointwise regN1N2 = refl
L-param-spec-pointwise regN2N3 = refl
L-param-spec-pointwise regN3N4 = refl
L-param-spec-pointwise regN4N0 = refl

L-param-spec : L-param starWeight ≡ L-min (πbulk starSpec)
L-param-spec = funExt L-param-spec-pointwise


-- ════════════════════════════════════════════════════════════════════
--  §2.  S-param ≡ L-param — The parameterized RT correspondence
-- ════════════════════════════════════════════════════════════════════
--
--  For the 6-tile star topology, the boundary min-cut observable
--  (S-param) and the bulk minimal-chain observable (L-param) are
--  the SAME function of the bond weights.  This is the structural
--  content of the discrete Ryu–Takayanagi correspondence:
--
--    boundary entanglement (min-cut) = bulk geometry (chain length)
--
--  For each region constructor  r  and any weight function  w :
--
--    S-param w r  reduces to the same expression as  L-param w r
--
--  because both are defined by identical pattern-matching clauses:
--
--    Singletons:  w bCN_i
--    Pairs:       w bCN_i +ℚ w bCN_j
--
--  The proof is by case split on  r , with each case holding by
--  refl  because Agda reduces both sides to the same normal form.
--
--  This proof works for VARIABLE  w  — not just the canonical
--  starWeight — which is the key property needed by the step-
--  invariance theorem:  if  S-param w ≡ L-param w  for any  w ,
--  then  S-param (perturb w b δ) ≡ L-param (perturb w b δ)
--  follows immediately (the hypothesis is not even needed, because
--  both sides are the same function applied to the same argument).
--
--  In the step-invariance proof (Bridge/StarStepInvariance.agda),
--  this is the "trivially true" case: the hypothesis "if S ≡ L
--  at weight w" is redundant because S and L are the same function
--  for ANY w on the star topology.  See docs/formal/10-dynamics.md
--  §4 for the step-invariance theorem statement and proof.
-- ════════════════════════════════════════════════════════════════════

SL-param-pointwise :
  (w : Bond → ℚ≥0) (r : Region) → S-param w r ≡ L-param w r
SL-param-pointwise w regN0   = refl
SL-param-pointwise w regN1   = refl
SL-param-pointwise w regN2   = refl
SL-param-pointwise w regN3   = refl
SL-param-pointwise w regN4   = refl
SL-param-pointwise w regN0N1 = refl
SL-param-pointwise w regN1N2 = refl
SL-param-pointwise w regN2N3 = refl
SL-param-pointwise w regN3N4 = refl
SL-param-pointwise w regN4N0 = refl

SL-param : (w : Bond → ℚ≥0) → S-param w ≡ L-param w
SL-param w = funExt (SL-param-pointwise w)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Regression tests — L-param on concrete weights
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that L-param applied to the canonical starWeight
--  produces the expected ℕ literals.  They serve as regression
--  tests: if the definition of L-param or starWeight changes,
--  these proofs will fail at type-check time.
-- ════════════════════════════════════════════════════════════════════

private
  -- Singleton:  starWeight bCN0 = 1
  check-singleton : L-param starWeight regN0 ≡ 1q
  check-singleton = refl

  -- Pair:  starWeight bCN2 + starWeight bCN3 = 1 + 1 = 2
  check-pair : L-param starWeight regN2N3 ≡ 2q
  check-pair = refl

  -- Wrap-around pair:  starWeight bCN4 + starWeight bCN0 = 1 + 1 = 2
  check-wrap : L-param starWeight regN4N0 ≡ 2q
  check-wrap = refl

  -- S-param and L-param agree on a concrete region with variable w
  check-SL-agree : (w : Bond → ℚ≥0) → S-param w regN1N2 ≡ L-param w regN1N2
  check-SL-agree w = refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for downstream step-invariance modules:
--
--    L-param              : (Bond → ℚ≥0) → Region → ℚ≥0
--                           (parameterized bulk minimal chain)
--    L-param-spec-pointwise : (r : Region)
--                           → L-param starWeight r ≡ L-min (πbulk starSpec) r
--    L-param-spec         : L-param starWeight ≡ L-min (πbulk starSpec)
--    SL-param-pointwise   : (w : Bond → ℚ≥0) (r : Region)
--                           → S-param w r ≡ L-param w r
--    SL-param             : (w : Bond → ℚ≥0)
--                           → S-param w ≡ L-param w
--
--  Key architectural property:
--
--    S-param and L-param are defined by IDENTICAL pattern-matching
--    clauses in separate modules (Boundary/StarCutParam.agda and
--    this module).  For each region constructor  r , both sides
--    reduce to the same expression in terms of  w , so
--    SL-param-pointwise w r = refl  for every  r .
--
--    This definitional coincidence IS the discrete Ryu–Takayanagi
--    correspondence for the star topology, stated at the level of
--    parameterized observables rather than fixed canonical values.
--    It makes the step-invariance theorem trivial: the hypothesis
--    "if S ≡ L at weight w" is redundant, because S and L are the
--    same function for ANY w.
--
--  Relationship to existing code:
--
--    The definition of  L-param  is identical to  S-param  in
--    Boundary/StarCutParam.agda  and to  minCutFromWeights  in
--    Bridge/StarRawEquiv.agda  (§4).  It is defined here in the
--    Bulk layer rather than imported from the Boundary or Bridge
--    layers because:
--
--      1.  The step-invariance modules should not conflate the
--          boundary and bulk observables.  Even though they
--          coincide for the star topology, they are conceptually
--          distinct: one computes entanglement entropy (boundary),
--          the other computes minimal chain length (bulk).
--
--      2.  Placing L-param in the Bulk layer mirrors the
--          symmetric placement of S-param in the Boundary layer,
--          maintaining the architectural separation.
--          See docs/getting-started/architecture.md for the full
--          module dependency DAG and layer diagram.
--
--      3.  For larger patches (e.g., the 11-tile filled patch),
--          S-param and L-param would NOT coincide — the bulk
--          observable might differ from the boundary one due to
--          boundary-leg effects (the N-singleton discrepancy
--          documented in docs/instances/filled-patch.md §4).
--          Keeping them separate now ensures the architecture
--          generalizes.
--
--  Design decisions:
--
--    1.  L-param does NOT take a BulkView argument, mirroring the
--        design of S-param (which does not take a BoundaryView).
--        The parameterization is on the weight function directly.
--
--    2.  The addition  _+ℚ_  is imported from  Util/Scalars.agda
--        (where  _+ℚ_ = _+_  on ℕ).  This ensures the same
--        addition operation is used across all modules.
--
--    3.  The  SL-param  proof is NOT wrapped in  abstract  because
--        it is the foundational lemma consumed by the step-
--        invariance theorem, and its computational content (refl
--        at each constructor) must be available for downstream
--        proofs to normalize.
--
--  Reference:
--    docs/formal/10-dynamics.md          (dynamics layer overview)
--    docs/formal/10-dynamics.md §2       (parameterized observables)
--    docs/formal/10-dynamics.md §4       (step invariance — consumes
--                                         SL-param-pointwise)
--    docs/formal/01-theorems.md §Thm 9   (theorem registry entry)
--    docs/instances/star-patch.md §7     (dynamics on the star patch)
--    docs/getting-started/architecture.md (Observable Layer)
--    docs/reference/module-index.md      (module description)
-- ════════════════════════════════════════════════════════════════════