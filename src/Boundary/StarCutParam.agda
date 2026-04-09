{-# OPTIONS --cubical --safe --guardedness #-}

module Boundary.StarCutParam where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCut using (S-cut ; π∂ ; BoundaryView)


-- ════════════════════════════════════════════════════════════════════
--  S-param — Parameterized boundary min-cut for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  For each representative boundary region, S-param computes the
--  min-cut value from an arbitrary bond-weight function
--  w : Bond → ℚ≥0 , rather than returning a fixed constant.
--
--  In the 6-tile star topology, every min-cut severs a subset of
--  the 5 central bonds C–N_i.  For a contiguous region of k tiles:
--
--    Singletons  {N_i}:            cut = {C–N_i}            → w(bCN_i)
--    Pairs       {N_i, N_{i+1}}:   cut = {C–N_i, C–N_{i+1}} → w(bCN_i) + w(bCN_{i+1})
--
--  This is the discrete Ryu–Takayanagi computation for the star
--  topology: bulk geometry (bond weights) determines boundary
--  entanglement (min-cut values).
--
--  This definition is equivalent to  minCutFromWeights  from
--  Bridge/StarRawEquiv.agda (§4), now promoted to the Boundary
--  layer as a first-class definition for the step-invariance
--  theorem (§11 of docs/10-frontier.md).
--
--  Downstream modules:
--    src/Bulk/StarChainParam.agda         (identical parameterized L-min)
--    src/Bridge/StarStepInvariance.agda   (step-invariance theorem)
--    src/Bridge/StarDynamicsLoop.agda     (iterated loop)
--
--  Reference:
--    docs/10-frontier.md §11.5  (Strategy A, Step 1)
--    docs/10-frontier.md §11.7  (item 2 — this module)
-- ════════════════════════════════════════════════════════════════════

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


-- ════════════════════════════════════════════════════════════════════
--  §1.  Specification agreement: S-param starWeight ≡ S-cut
-- ════════════════════════════════════════════════════════════════════
--
--  At the canonical weight assignment  starWeight  (all bonds = 1q),
--  the parameterized observable  S-param starWeight  reduces to the
--  same ℕ literals as the existing lookup table  S-cut .
--
--  For singletons:
--    S-param starWeight regN_i = starWeight bCN_i = 1q = S-cut bv regN_i
--
--  For pairs:
--    S-param starWeight regN_iN_j
--      = starWeight bCN_i +ℚ starWeight bCN_j
--      = 1q +ℚ 1q
--      = 2q               (by judgmental computation: suc zero + suc zero = suc (suc zero))
--      = S-cut bv regN_iN_j
--
--  All 10 cases hold by  refl  because ℕ addition computes by
--  structural recursion on the first argument, and 1 + 1 = 2
--  judgmentally.
--
--  This lemma connects the parameterized observable (used by the
--  step-invariance theorem) to the existing verified bridge
--  (star-pointwise in Bridge/StarObs.agda), ensuring that the
--  new parameterized development is consistent with all existing
--  refl-based proofs.
-- ════════════════════════════════════════════════════════════════════

S-param-spec-pointwise :
  (r : Region) →
  S-param starWeight r ≡ S-cut (π∂ starSpec) r
S-param-spec-pointwise regN0   = refl
S-param-spec-pointwise regN1   = refl
S-param-spec-pointwise regN2   = refl
S-param-spec-pointwise regN3   = refl
S-param-spec-pointwise regN4   = refl
S-param-spec-pointwise regN0N1 = refl   -- 1 + 1 = 2  judgmentally
S-param-spec-pointwise regN1N2 = refl
S-param-spec-pointwise regN2N3 = refl
S-param-spec-pointwise regN3N4 = refl
S-param-spec-pointwise regN4N0 = refl

S-param-spec : S-param starWeight ≡ S-cut (π∂ starSpec)
S-param-spec = funExt S-param-spec-pointwise


-- ════════════════════════════════════════════════════════════════════
--  §2.  Regression tests — S-param on concrete weights
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that S-param applied to the canonical starWeight
--  produces the expected ℕ literals.  They serve as regression
--  tests: if the definition of S-param or starWeight changes,
--  these proofs will fail at type-check time.
-- ════════════════════════════════════════════════════════════════════

private
  -- Singleton:  starWeight bCN0 = 1
  check-singleton : S-param starWeight regN0 ≡ 1q
  check-singleton = refl

  -- Pair:  starWeight bCN2 + starWeight bCN3 = 1 + 1 = 2
  check-pair : S-param starWeight regN2N3 ≡ 2q
  check-pair = refl

  -- Wrap-around pair:  starWeight bCN4 + starWeight bCN0 = 1 + 1 = 2
  check-wrap : S-param starWeight regN4N0 ≡ 2q
  check-wrap = refl


-- ════════════════════════════════════════════════════════════════════
--  §3.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for downstream step-invariance modules:
--
--    S-param              : (Bond → ℚ≥0) → Region → ℚ≥0
--                           (parameterized boundary min-cut)
--    S-param-spec-pointwise : (r : Region)
--                           → S-param starWeight r ≡ S-cut (π∂ starSpec) r
--    S-param-spec         : S-param starWeight ≡ S-cut (π∂ starSpec)
--
--  Relationship to existing code:
--
--    The definition of  S-param  is identical to  minCutFromWeights
--    in  Bridge/StarRawEquiv.agda  (§4).  It is defined here in the
--    Boundary layer rather than imported from the Bridge layer
--    because:
--
--      1.  The step-invariance modules (Bridge/StarStepInvariance.agda)
--          should not depend on the raw structural equivalence
--          infrastructure.  The parameterized observable is a
--          boundary-layer concept: given bond weights, compute
--          the boundary entanglement entropy (min-cut).
--
--      2.  Placing S-param in the Boundary layer mirrors the
--          symmetric placement of L-param in the Bulk layer
--          (Bulk/StarChainParam.agda), maintaining the architectural
--          separation between boundary and bulk sides.
--
--      3.  If a future refactor wishes to eliminate the duplication
--          with  minCutFromWeights , either module can import from
--          the other — but this is not required for the current
--          milestone.
--
--  Design decisions:
--
--    1.  S-param does NOT take a BoundaryView argument.  The
--        parameterization is on the weight function directly,
--        bypassing the architectural wrapper.  This is deliberate:
--        the step-invariance theorem operates on weight functions
--        (which can be perturbed), not on view records.
--
--    2.  The addition  _+ℚ_  is imported from  Util/Scalars.agda
--        (where  _+ℚ_ = _+_  on ℕ).  This ensures that the same
--        addition operation is used in S-param as in the existing
--        subadditivity and monotonicity proofs.
--
--    3.  The specification agreement lemma  S-param-spec  is NOT
--        wrapped in  abstract  because it is a propositional
--        identity between functions into ℕ (a set), and the 10
--        refl cases are small enough to normalize quickly.
--
--  Conditions for advancement (§11.12 of docs/10-frontier.md):
--
--    "The  minCutFromWeights  function from  Bridge/StarRawEquiv.agda
--     has been validated as the correct parameterized observable for
--     both boundary and bulk sides."
--
--  This module satisfies that condition for the boundary side.
--  The next step is  Bulk/StarChainParam.agda  (item 3 of §11.7).
-- ════════════════════════════════════════════════════════════════════