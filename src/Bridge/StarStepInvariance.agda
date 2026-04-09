{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.StarStepInvariance where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Empty using (⊥ ; rec)

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCutParam using (S-param)
open import Bulk.StarChainParam
  using (L-param ; SL-param-pointwise ; SL-param)


-- ════════════════════════════════════════════════════════════════════
--  Step-Invariance of the Discrete Ryu–Takayanagi Correspondence
--  under Local Bond-Weight Perturbations on the 6-Tile Star
-- ════════════════════════════════════════════════════════════════════
--
--  This module proves that the discrete RT correspondence
--  (S-param w ≡ L-param w) is preserved under single-bond weight
--  perturbations.  It is item 4 of the §11.7 implementation plan
--  in docs/10-frontier.md (Phase F.2a — Parameterized Star Bridge,
--  Strategy A: Weight-Perturbation Invariance).
--
--  The key structural fact is that for the star topology, S-param
--  and L-param are the SAME function of the bond weights (both
--  defined by identical pattern-matching clauses in separate
--  modules).  This makes the step-invariance theorem trivial:
--  the hypothesis "if S ≡ L at weight w" is redundant, because
--  S and L agree at ANY weight function.
--
--  The non-trivial content is the DEFINITION of  perturb  and its
--  specification lemmas (perturb-self, perturb-other), which
--  establish that the perturbation modifies exactly one bond
--  weight and leaves all others unchanged.  These lemmas are
--  needed for the iterated loop (Bridge/StarDynamicsLoop.agda)
--  and for future generalizations to non-star topologies where
--  S-param ≠ L-param.
--
--  Module dependencies:
--
--    Util/Scalars.agda               — ℚ≥0 = ℕ, _+ℚ_
--    Common/StarSpec.agda            — Bond, Region
--    Boundary/StarCutParam.agda      — S-param
--    Bulk/StarChainParam.agda        — L-param, SL-param-pointwise
--
--  Reference:
--    docs/10-frontier.md §11.3   (target theorem)
--    docs/10-frontier.md §11.5   (Strategy A)
--    docs/10-frontier.md §11.7   (implementation plan, item 4)
--    docs/10-frontier.md §11.10  (exit criterion)
--
--  Exit criterion (§11.10 of docs/10-frontier.md):
--    "A  step-invariant  theorem type-checks in
--     Bridge/StarStepInvariance.agda, proving that the discrete
--     Ryu–Takayanagi correspondence is preserved under single-bond
--     weight perturbation for the 6-tile star topology."
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  perturb — Single-bond weight perturbation
-- ════════════════════════════════════════════════════════════════════
--
--  Given a weight function  w : Bond → ℚ≥0 , a target bond  b ,
--  and a perturbation magnitude  δ : ℚ≥0 ,  perturb w b δ  returns
--  a new weight function that adds  δ  to the weight of bond  b
--  and leaves all other bond weights unchanged.
--
--  The definition is a 5×5 case split on (target bond, query bond).
--  Case (b, b) returns  w b +ℚ δ  (the perturbed weight).
--  Case (b, b') for b ≠ b' returns  w b'  (unchanged).
--
--  This avoids the need for decidable equality on Bond by simply
--  enumerating all 25 cases.  For a 5-constructor type, this is
--  the most transparent approach and reduces judgmentally on any
--  pair of closed Bond constructors.
--
--  In the physics interpretation, each  perturb  application is
--  one "tick" of the discrete clock — a local modification to the
--  entanglement network that changes one bond's capacity.
--
--  Reference: §11.5 Step 2 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

perturb : (Bond → ℚ≥0) → Bond → ℚ≥0 → (Bond → ℚ≥0)
-- ── Target: bCN0 ───────────────────────────────────────────────
perturb w bCN0 δ bCN0 = w bCN0 +ℚ δ
perturb w bCN0 δ bCN1 = w bCN1
perturb w bCN0 δ bCN2 = w bCN2
perturb w bCN0 δ bCN3 = w bCN3
perturb w bCN0 δ bCN4 = w bCN4
-- ── Target: bCN1 ───────────────────────────────────────────────
perturb w bCN1 δ bCN0 = w bCN0
perturb w bCN1 δ bCN1 = w bCN1 +ℚ δ
perturb w bCN1 δ bCN2 = w bCN2
perturb w bCN1 δ bCN3 = w bCN3
perturb w bCN1 δ bCN4 = w bCN4
-- ── Target: bCN2 ───────────────────────────────────────────────
perturb w bCN2 δ bCN0 = w bCN0
perturb w bCN2 δ bCN1 = w bCN1
perturb w bCN2 δ bCN2 = w bCN2 +ℚ δ
perturb w bCN2 δ bCN3 = w bCN3
perturb w bCN2 δ bCN4 = w bCN4
-- ── Target: bCN3 ───────────────────────────────────────────────
perturb w bCN3 δ bCN0 = w bCN0
perturb w bCN3 δ bCN1 = w bCN1
perturb w bCN3 δ bCN2 = w bCN2
perturb w bCN3 δ bCN3 = w bCN3 +ℚ δ
perturb w bCN3 δ bCN4 = w bCN4
-- ── Target: bCN4 ───────────────────────────────────────────────
perturb w bCN4 δ bCN0 = w bCN0
perturb w bCN4 δ bCN1 = w bCN1
perturb w bCN4 δ bCN2 = w bCN2
perturb w bCN4 δ bCN3 = w bCN3
perturb w bCN4 δ bCN4 = w bCN4 +ℚ δ


-- ════════════════════════════════════════════════════════════════════
--  §2.  perturb-self — The perturbed bond gains δ
-- ════════════════════════════════════════════════════════════════════
--
--  For the target bond  b , the perturbed weight equals the
--  original weight plus δ:
--
--    perturb w b δ b  ≡  w b +ℚ δ
--
--  All 5 cases hold by  refl  because the diagonal clauses of
--  perturb  reduce judgmentally to  w b +ℚ δ .
--
--  Reference: §11.7 item 1 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

perturb-self : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → perturb w b δ b ≡ w b +ℚ δ
perturb-self w bCN0 δ = refl
perturb-self w bCN1 δ = refl
perturb-self w bCN2 δ = refl
perturb-self w bCN3 δ = refl
perturb-self w bCN4 δ = refl


-- ════════════════════════════════════════════════════════════════════
--  §3.  perturb-other — Non-target bonds are unchanged
-- ════════════════════════════════════════════════════════════════════
--
--  For any bond  b'  distinct from the target  b , the perturbed
--  weight equals the original weight:
--
--    (b ≡ b' → ⊥)  →  perturb w b δ b'  ≡  w b'
--
--  The 20 off-diagonal cases hold by  refl  (the off-diagonal
--  clauses of  perturb  return  w b'  directly).  The 5 diagonal
--  cases are contradicted by the distinctness hypothesis:
--  b ≡ b  is witnessed by  refl , so applying the negation
--  yields  ⊥ , from which any type is inhabited via  rec .
--
--  Note: the distinctness hypothesis  (b ≡ b' → ⊥)  is the
--  cubical-Agda encoding of  ¬ (b ≡ b') .  We write it
--  expanded to avoid importing  ¬_  from Cubical.Relation.Nullary.
-- ════════════════════════════════════════════════════════════════════

perturb-other : (w : Bond → ℚ≥0) (b b' : Bond) (δ : ℚ≥0)
  → (b ≡ b' → ⊥) → perturb w b δ b' ≡ w b'
-- ── Target: bCN0 ───────────────────────────────────────────────
perturb-other w bCN0 bCN0 δ ¬p = rec (¬p refl)
perturb-other w bCN0 bCN1 δ _  = refl
perturb-other w bCN0 bCN2 δ _  = refl
perturb-other w bCN0 bCN3 δ _  = refl
perturb-other w bCN0 bCN4 δ _  = refl
-- ── Target: bCN1 ───────────────────────────────────────────────
perturb-other w bCN1 bCN0 δ _  = refl
perturb-other w bCN1 bCN1 δ ¬p = rec (¬p refl)
perturb-other w bCN1 bCN2 δ _  = refl
perturb-other w bCN1 bCN3 δ _  = refl
perturb-other w bCN1 bCN4 δ _  = refl
-- ── Target: bCN2 ───────────────────────────────────────────────
perturb-other w bCN2 bCN0 δ _  = refl
perturb-other w bCN2 bCN1 δ _  = refl
perturb-other w bCN2 bCN2 δ ¬p = rec (¬p refl)
perturb-other w bCN2 bCN3 δ _  = refl
perturb-other w bCN2 bCN4 δ _  = refl
-- ── Target: bCN3 ───────────────────────────────────────────────
perturb-other w bCN3 bCN0 δ _  = refl
perturb-other w bCN3 bCN1 δ _  = refl
perturb-other w bCN3 bCN2 δ _  = refl
perturb-other w bCN3 bCN3 δ ¬p = rec (¬p refl)
perturb-other w bCN3 bCN4 δ _  = refl
-- ── Target: bCN4 ───────────────────────────────────────────────
perturb-other w bCN4 bCN0 δ _  = refl
perturb-other w bCN4 bCN1 δ _  = refl
perturb-other w bCN4 bCN2 δ _  = refl
perturb-other w bCN4 bCN3 δ _  = refl
perturb-other w bCN4 bCN4 δ ¬p = rec (¬p refl)


-- ════════════════════════════════════════════════════════════════════
--  §4.  step-invariant — The Step-Invariance Theorem
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Step-Invariance of the Discrete RT Correspondence).
--
--  For the 6-tile star patch of the {5,4} HaPPY code with
--  arbitrary bond weights, the discrete Ryu–Takayanagi
--  correspondence  S-param w ≡ L-param w  is invariant under
--  single-bond weight perturbations.
--
--  Formally:  if the RT correspondence holds at weight assignment
--  w , and we modify one bond weight by  δ , the correspondence
--  still holds at the perturbed assignment  perturb w b δ .
--
--  The proof is a single application of  SL-param-pointwise  from
--  Bulk/StarChainParam.agda, which establishes that S-param and
--  L-param agree at ANY weight function (not just the canonical
--  starWeight).  The hypothesis  hyp  is not used: the RT
--  correspondence at the perturbed weights holds independently
--  of whether it held at the original weights.
--
--  This is "trivially true" for the star topology BECAUSE S-param
--  and L-param are definitionally the same function.  The physical
--  content is that the boundary min-cut and the bulk minimal chain
--  respond IDENTICALLY to the weight change — any perturbation to
--  the entanglement network is faithfully reflected in the bulk
--  geometry, and vice versa.
--
--  For larger patches (e.g., the 11-tile filled patch) where
--  S-param and L-param may differ (due to boundary-leg effects),
--  the step-invariance proof would require genuine graph-theoretic
--  reasoning about which min-cuts are affected by the perturbation.
--  The star topology is the base case where this reasoning is
--  trivial.
--
--  Reference:
--    docs/10-frontier.md §11.3  (target theorem)
--    docs/10-frontier.md §11.7  (item 4)
-- ════════════════════════════════════════════════════════════════════

step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → ((r : Region) → S-param w r ≡ L-param w r)
  → ((r : Region) → S-param (perturb w b δ) r
                   ≡ L-param (perturb w b δ) r)
step-invariant w b δ _ r = SL-param-pointwise (perturb w b δ) r


-- ════════════════════════════════════════════════════════════════════
--  §5.  step-invariant-unconditional — Unconditional formulation
-- ════════════════════════════════════════════════════════════════════
--
--  For the star topology, the step-invariance theorem holds
--  unconditionally (the hypothesis is redundant).  This formulation
--  makes the unconditional nature explicit: the RT correspondence
--  holds at ANY weight function, perturbed or not.
--
--  The conditional formulation (§4) is retained because it matches
--  the type signature from §11.3 of docs/10-frontier.md and
--  generalizes to non-star topologies where the hypothesis is
--  genuinely needed.
-- ════════════════════════════════════════════════════════════════════

step-invariant-unconditional :
  (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → ((r : Region) → S-param (perturb w b δ) r
                   ≡ L-param (perturb w b δ) r)
step-invariant-unconditional w b δ r =
  SL-param-pointwise (perturb w b δ) r


-- ════════════════════════════════════════════════════════════════════
--  §6.  Regression tests — perturb on concrete weights
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that  perturb  produces the expected values
--  when applied to  starWeight  (the canonical all-ones weight
--  function) and specific bonds.
--
--  After perturbing  starWeight  at bond  bCN2  by  δ = 1 :
--
--    perturb starWeight bCN2 1  bCN0  =  starWeight bCN0  =  1
--    perturb starWeight bCN2 1  bCN2  =  starWeight bCN2 + 1  =  2
--    perturb starWeight bCN2 1  bCN4  =  starWeight bCN4  =  1
--
--  Each test holds by  refl  because all operations (perturb,
--  starWeight, _+ℚ_ = _+_ on ℕ) compute by structural recursion
--  on closed constructor terms.
-- ════════════════════════════════════════════════════════════════════

private
  -- Perturbing bCN2 by 1: non-target bond bCN0 is unchanged
  check-perturb-other : perturb starWeight bCN2 1 bCN0 ≡ 1
  check-perturb-other = refl

  -- Perturbing bCN2 by 1: target bond bCN2 gains δ
  check-perturb-self : perturb starWeight bCN2 1 bCN2 ≡ 2
  check-perturb-self = refl

  -- Perturbing bCN2 by 1: non-target bond bCN4 is unchanged
  check-perturb-other2 : perturb starWeight bCN2 1 bCN4 ≡ 1
  check-perturb-other2 = refl

  -- perturb-self produces the expected result on a concrete bond
  check-self-lemma : perturb-self starWeight bCN3 2 ≡ refl
  check-self-lemma = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Regression tests — step-invariant on perturbed starWeight
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify the step-invariance theorem end-to-end:
--  starting from the canonical starWeight, perturbing one bond,
--  and checking that S-param and L-param still agree.
--
--  After perturbing  starWeight  at  bCN0  by  δ = 3 :
--
--    Singleton regN0:
--      S-param (perturb starWeight bCN0 3) regN0
--        = (perturb starWeight bCN0 3) bCN0
--        = starWeight bCN0 + 3
--        = 1 + 3 = 4
--      L-param (perturb starWeight bCN0 3) regN0
--        = (perturb starWeight bCN0 3) bCN0
--        = 4   (same computation)
--      ✓  Both sides reduce to 4.
--
--    Pair regN0N1:
--      S-param (perturb starWeight bCN0 3) regN0N1
--        = (perturb ... bCN0 3) bCN0 + (perturb ... bCN0 3) bCN1
--        = 4 + 1 = 5
--      L-param (perturb starWeight bCN0 3) regN0N1
--        = 5   (same computation)
--      ✓  Both sides reduce to 5.
--
--    Singleton regN2 (unaffected bond):
--      S-param (perturb starWeight bCN0 3) regN2
--        = (perturb ... bCN0 3) bCN2
--        = starWeight bCN2
--        = 1
--      ✓  Unchanged by the perturbation.
-- ════════════════════════════════════════════════════════════════════

private
  w-perturbed : Bond → ℚ≥0
  w-perturbed = perturb starWeight bCN0 3

  -- S-param and L-param agree at the perturbed weight: regN0
  check-invariant-N0 :
    S-param w-perturbed regN0 ≡ L-param w-perturbed regN0
  check-invariant-N0 = refl     -- both reduce to 4

  -- S-param and L-param agree at the perturbed weight: regN0N1
  check-invariant-N0N1 :
    S-param w-perturbed regN0N1 ≡ L-param w-perturbed regN0N1
  check-invariant-N0N1 = refl   -- both reduce to 5

  -- S-param and L-param agree at the perturbed weight: regN2
  check-invariant-N2 :
    S-param w-perturbed regN2 ≡ L-param w-perturbed regN2
  check-invariant-N2 = refl     -- both reduce to 1

  -- Concrete value checks for the perturbed observables
  check-val-N0 : S-param w-perturbed regN0 ≡ 4
  check-val-N0 = refl

  check-val-N0N1 : S-param w-perturbed regN0N1 ≡ 5
  check-val-N0N1 = refl

  --   regN4N0 = w bCN4 +ℚ w bCN0
  --   perturb starWeight bCN0 3 bCN4 = starWeight bCN4 = 1
  --   perturb starWeight bCN0 3 bCN0 = starWeight bCN0 + 3 = 4
  --   1 + 4 = 5
  check-val-N4N0 : S-param w-perturbed regN4N0 ≡ 5
  check-val-N4N0 = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for downstream modules:
--
--    perturb             : (Bond → ℚ≥0) → Bond → ℚ≥0 → (Bond → ℚ≥0)
--                          (single-bond weight perturbation)
--    perturb-self        : perturb w b δ b ≡ w b +ℚ δ
--                          (target bond gains δ)
--    perturb-other       : (b ≡ b' → ⊥) → perturb w b δ b' ≡ w b'
--                          (non-target bonds unchanged)
--    step-invariant      : the conditional step-invariance theorem
--    step-invariant-unconditional : the unconditional formulation
--
--  Downstream modules:
--
--    src/Bridge/StarDynamicsLoop.agda   — iterated loop invariant
--
--  Relationship to existing code:
--
--    The step-invariance theorem consumes  SL-param-pointwise  from
--    Bulk/StarChainParam.agda, which is the parameterized discrete
--    RT correspondence: S-param and L-param agree at any weight
--    function.  The perturb function is new to this module and is
--    consumed by Bridge/StarDynamicsLoop.agda.
--
--  Design decisions:
--
--    1.  perturb  is defined by a 25-case pattern match rather than
--        using decidable equality on Bond.  This avoids importing
--        Cubical.Relation.Nullary.Discrete and keeps the definition
--        fully transparent to the normalizer: for any two closed
--        Bond constructors,  perturb w b δ b'  reduces in one step.
--
--    2.  perturb-other  uses the explicit negation  (b ≡ b' → ⊥)
--        rather than importing  ¬_  from Cubical.Relation.Nullary.
--        This avoids an additional import and makes the absurdity
--        derivation (rec (¬p refl)) visually clear.
--
--    3.  The conditional formulation of  step-invariant  matches the
--        target theorem from §11.3 of docs/10-frontier.md.  The
--        unconditional formulation is provided separately because
--        it more accurately reflects the mathematical content for
--        the star topology.  Future modules for non-star topologies
--        would use the conditional formulation.
--
--    4.  The hypothesis  hyp  in  step-invariant  is bound by  _
--        (unused) in the proof body.  A future linter might flag
--        this; the binding can be removed by switching to the
--        unconditional formulation in downstream code.
--
--  Proof effort breakdown (matching §11.5 estimates):
--
--    perturb definition:          25 lines  (5 bonds × 5 bonds)
--    perturb-self:                 5 lines  (5 bonds, all refl)
--    perturb-other:               25 lines  (5 absurd + 20 refl)
--    step-invariant:               1 line   (!)
--    step-invariant-unconditional: 1 line
--    regression tests:           ~20 lines
--    documentation:              ~80 lines
--                                ─────────
--    total:                     ~160 lines
--
--  This satisfies exit criterion 1 of §11.10:
--
--    "A  step-invariant  theorem type-checks in
--     Bridge/StarStepInvariance.agda, proving that the discrete
--     Ryu–Takayanagi correspondence is preserved under single-bond
--     weight perturbation for the 6-tile star topology."
--
--  The next step is  Bridge/StarDynamicsLoop.agda  (item 5 of §11.7),
--  which applies  step-invariant  iteratively to prove preservation
--  under arbitrary finite sequences of perturbations.
-- ════════════════════════════════════════════════════════════════════