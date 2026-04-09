{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.StarDynamicsLoop where

open import Cubical.Foundations.Prelude
open import Cubical.Data.List  using (List ; [] ; _∷_)
open import Cubical.Data.Sigma using (_×_ ; fst ; snd)

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCutParam using (S-param)
open import Bulk.StarChainParam
  using (L-param ; SL-param-pointwise ; SL-param)
open import Bridge.StarStepInvariance
  using (perturb ; step-invariant ; step-invariant-unconditional)


-- ════════════════════════════════════════════════════════════════════
--  The "while(true) Loop" — Iterated Bond-Weight Perturbation
--  Dynamics for the 6-Tile Star Patch
-- ════════════════════════════════════════════════════════════════════
--
--  This module proves that the discrete Ryu–Takayanagi
--  correspondence  S-param w ≡ L-param w  is preserved under
--  arbitrary finite sequences of single-bond weight perturbations.
--
--  Each "tick" of the discrete clock is one  perturb  application
--  — a local modification to the entanglement network that changes
--  one bond's capacity by δ.  The  loop-invariant  theorem
--  guarantees that the holographic correspondence is maintained
--  at every tick, for any number of ticks.
--
--  This is item 5 of the §11.7 implementation plan in
--  docs/10-frontier.md (Phase F.2a — Parameterized Star Bridge,
--  Strategy A: Weight-Perturbation Invariance).
--
--  Module dependencies:
--
--    Util/Scalars.agda                  — ℚ≥0 = ℕ, _+ℚ_
--    Common/StarSpec.agda               — Bond, Region, starWeight
--    Boundary/StarCutParam.agda         — S-param
--    Bulk/StarChainParam.agda           — L-param, SL-param-pointwise
--    Bridge/StarStepInvariance.agda     — perturb, step-invariant
--
--  Reference:
--    docs/10-frontier.md §11.5   (Strategy A — weight perturbation)
--    docs/10-frontier.md §11.7   (item 5 — this module)
--    docs/10-frontier.md §11.10  (exit criterion, item 2)
--    docs/10-frontier.md §11.11  (what success looks like)
--
--  Exit criterion (§11.10 of docs/10-frontier.md):
--    "A  loop-invariant  theorem type-checks in
--     Bridge/StarDynamicsLoop.agda, proving preservation under
--     arbitrary finite sequences of perturbations (by induction
--     on the list of steps)."
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  weight-sequence — Iterated perturbation
-- ════════════════════════════════════════════════════════════════════
--
--  Given an initial weight function  w₀ : Bond → ℚ≥0  and a list
--  of perturbation steps (each a pair of target bond and delta),
--  weight-sequence  produces the weight function after all steps
--  have been applied.
--
--  The list is folded right-to-left:  the head of the list is the
--  LAST perturbation applied.  Equivalently, the tail is processed
--  first (building up from the initial weights), and the head step
--  wraps the result.
--
--  In the physics interpretation, the list encodes a discrete time
--  history of local modifications to the entanglement network.
--  Each entry  (b , δ)  represents one "tick" where bond  b  has
--  its capacity increased by  δ .
--
--  Examples:
--    weight-sequence w₀ []
--      = w₀                                    (no perturbations)
--
--    weight-sequence w₀ ((bCN0 , 1) ∷ [])
--      = perturb w₀ bCN0 1                     (one perturbation)
--
--    weight-sequence w₀ ((bCN1 , 2) ∷ (bCN0 , 1) ∷ [])
--      = perturb (perturb w₀ bCN0 1) bCN1 2    (two perturbations)
-- ════════════════════════════════════════════════════════════════════

weight-sequence : (Bond → ℚ≥0) → List (Bond × ℚ≥0) → (Bond → ℚ≥0)
weight-sequence w₀ []            = w₀
weight-sequence w₀ ((b , δ) ∷ s) = perturb (weight-sequence w₀ s) b δ


-- ════════════════════════════════════════════════════════════════════
--  §2.  loop-invariant — The "while(true) loop" theorem
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Loop Invariance of the Discrete RT Correspondence).
--
--  For the 6-tile star patch of the {5,4} HaPPY code with
--  arbitrary bond weights, the discrete Ryu–Takayanagi
--  correspondence is preserved under ANY finite sequence of
--  single-bond weight perturbations.
--
--  Formally:  if the RT correspondence holds at the initial
--  weight assignment  w₀ , then it holds at the weight assignment
--  obtained by applying any list of perturbation steps.
--
--  The proof is by structural induction on the list of steps:
--
--    Base case (empty list):
--      weight-sequence w₀ [] = w₀ , so the hypothesis applies
--      directly.
--
--    Inductive step (s ∷ ss):
--      weight-sequence w₀ (s ∷ ss)
--        = perturb (weight-sequence w₀ ss) (fst s) (snd s)
--
--      By the induction hypothesis, the RT correspondence holds at
--      weight-sequence w₀ ss .  By  step-invariant , it is
--      preserved under one more perturbation.
--
--  The proof term is ~5 lines.
--
--  The "while(true) loop" claim:  this works for lists of
--  ARBITRARY length — any finite number of ticks maintains the
--  holographic correspondence.
--
--  Reference:
--    docs/10-frontier.md §11.7  (item 5)
--    docs/10-frontier.md §11.11 (what success looks like)
-- ════════════════════════════════════════════════════════════════════

loop-invariant :
  (w₀ : Bond → ℚ≥0)
  → ((r : Region) → S-param w₀ r ≡ L-param w₀ r)
  → (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence w₀ steps) r
                   ≡ L-param (weight-sequence w₀ steps) r)
loop-invariant w₀ base []         = base
loop-invariant w₀ base (s ∷ ss)   =
  step-invariant (weight-sequence w₀ ss) (fst s) (snd s)
                 (loop-invariant w₀ base ss)


-- ════════════════════════════════════════════════════════════════════
--  §3.  loop-invariant-unconditional — Hypothesis-free formulation
-- ════════════════════════════════════════════════════════════════════
--
--  For the star topology, the RT correspondence holds at ANY
--  weight function (the hypothesis in §2 is redundant), because
--  S-param and L-param are the same function.  This formulation
--  makes the unconditional nature explicit.
--
--  The proof delegates to  SL-param-pointwise  which establishes
--  S-param w r ≡ L-param w r  for any  w  and  r  by refl.
--
--  The conditional formulation (§2) is retained because it matches
--  the target theorem from §11.3 of docs/10-frontier.md and
--  generalizes to non-star topologies where the hypothesis would
--  be genuinely needed.
-- ════════════════════════════════════════════════════════════════════

loop-invariant-unconditional :
  (w₀ : Bond → ℚ≥0)
  → (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence w₀ steps) r
                   ≡ L-param (weight-sequence w₀ steps) r)
loop-invariant-unconditional w₀ steps r =
  SL-param-pointwise (weight-sequence w₀ steps) r


-- ════════════════════════════════════════════════════════════════════
--  §4.  Canonical base case — Starting from starWeight
-- ════════════════════════════════════════════════════════════════════
--
--  The canonical instantiation starts from the uniform all-ones
--  weight function  starWeight  (from Common/StarSpec.agda).
--  This is the standard HaPPY code configuration where each
--  shared pentagon edge carries one unit of entanglement capacity.
--
--  star-base:  the RT correspondence at the initial configuration.
--  star-loop:  the correspondence after any sequence of ticks.
-- ════════════════════════════════════════════════════════════════════

-- The base case:  S-param starWeight r ≡ L-param starWeight r
-- holds by SL-param-pointwise (each case is refl).
star-base : (r : Region) → S-param starWeight r ≡ L-param starWeight r
star-base = SL-param-pointwise starWeight

-- Starting from starWeight, any finite sequence of perturbations
-- preserves the RT correspondence.
star-loop :
  (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence starWeight steps) r
                   ≡ L-param (weight-sequence starWeight steps) r)
star-loop = loop-invariant starWeight star-base


-- ════════════════════════════════════════════════════════════════════
--  §5.  Regression tests — concrete iterated perturbations
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify the loop invariant end-to-end on small
--  concrete step sequences starting from starWeight.
--
--  Each test constructs a specific perturbation history, applies
--  weight-sequence, and checks that S-param and L-param still
--  agree at the resulting weight function.
-- ════════════════════════════════════════════════════════════════════

private
  -- ── 0 steps: the identity ────────────────────────────────────
  --
  -- weight-sequence starWeight []  =  starWeight
  -- S-param starWeight regN0  =  1  =  L-param starWeight regN0

  check-0-steps :
    S-param (weight-sequence starWeight []) regN0
    ≡ L-param (weight-sequence starWeight []) regN0
  check-0-steps = refl

  -- ── 1 step: perturb bCN0 by 3 ───────────────────────────────
  --
  -- weight-sequence starWeight ((bCN0 , 3) ∷ [])
  --   = perturb starWeight bCN0 3
  --
  -- S-param (perturb starWeight bCN0 3) regN0
  --   = (perturb starWeight bCN0 3) bCN0
  --   = starWeight bCN0 + 3
  --   = 1 + 3 = 4
  -- L-param (perturb starWeight bCN0 3) regN0
  --   = 4                                        (same computation)

  check-1-step-N0 :
    S-param (weight-sequence starWeight ((bCN0 , 3) ∷ [])) regN0
    ≡ L-param (weight-sequence starWeight ((bCN0 , 3) ∷ [])) regN0
  check-1-step-N0 = refl

  -- Value check:  the perturbed val is 4
  check-1-step-val :
    S-param (weight-sequence starWeight ((bCN0 , 3) ∷ [])) regN0 ≡ 4
  check-1-step-val = refl

  -- ── 2 steps: perturb bCN0 by 1, then bCN1 by 2 ─────────────
  --
  -- weight-sequence starWeight ((bCN1 , 2) ∷ (bCN0 , 1) ∷ [])
  --   = perturb (perturb starWeight bCN0 1) bCN1 2
  --
  -- At regN0N1 (the pair {N0, N1}):
  --   S-param w regN0N1
  --     = w bCN0 + w bCN1
  --     = (1 + 1) + (1 + 2)      (starWeight + perturbations)
  --     = 2 + 3 = 5

  two-steps : List (Bond × ℚ≥0)
  two-steps = (bCN1 , 2) ∷ (bCN0 , 1) ∷ []

  check-2-steps-N0N1 :
    S-param (weight-sequence starWeight two-steps) regN0N1
    ≡ L-param (weight-sequence starWeight two-steps) regN0N1
  check-2-steps-N0N1 = refl

  check-2-steps-val :
    S-param (weight-sequence starWeight two-steps) regN0N1 ≡ 5
  check-2-steps-val = refl

  -- Unaffected region: regN2 uses bCN2, which is not perturbed.
  -- S-param w regN2 = w bCN2 = starWeight bCN2 = 1
  check-2-steps-unaffected :
    S-param (weight-sequence starWeight two-steps) regN2 ≡ 1
  check-2-steps-unaffected = refl

  -- ── 3 steps: three different bonds ───────────────────────────
  --
  -- Perturb bCN0 by 1, bCN1 by 1, bCN2 by 1.
  -- All singleton min-cuts become 2; pairs become 4 (for affected),
  -- or stay at their adjusted values.

  three-steps : List (Bond × ℚ≥0)
  three-steps = (bCN2 , 1) ∷ (bCN1 , 1) ∷ (bCN0 , 1) ∷ []

  -- regN0N1:  w bCN0 + w bCN1 = 2 + 2 = 4
  check-3-steps-pair :
    S-param (weight-sequence starWeight three-steps) regN0N1 ≡ 4
  check-3-steps-pair = refl

  check-3-steps-agree :
    S-param (weight-sequence starWeight three-steps) regN0N1
    ≡ L-param (weight-sequence starWeight three-steps) regN0N1
  check-3-steps-agree = refl

  -- regN3: unaffected.  w bCN3 = starWeight bCN3 = 1
  check-3-steps-N3 :
    S-param (weight-sequence starWeight three-steps) regN3 ≡ 1
  check-3-steps-N3 = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  The loop invariant applied via star-loop
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that  star-loop  (the canonical instantiation
--  of  loop-invariant  at  starWeight) produces the same results
--  as the direct regression tests above.  This exercises the full
--  chain:  star-base → loop-invariant → step-invariant → SL-param.
-- ════════════════════════════════════════════════════════════════════

private
  -- star-loop [] = star-base
  check-star-loop-empty :
    star-loop [] regN0 ≡ star-base regN0
  check-star-loop-empty = refl

  -- star-loop on two-steps agrees with direct computation
  check-star-loop-2 :
    star-loop two-steps regN0N1
    ≡ SL-param-pointwise (weight-sequence starWeight two-steps) regN0N1
  check-star-loop-2 = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for downstream modules:
--
--    weight-sequence          : (Bond → ℚ≥0) → List (Bond × ℚ≥0)
--                               → (Bond → ℚ≥0)
--                               (iterated perturbation)
--    loop-invariant           : conditional iterated invariance
--    loop-invariant-unconditional : hypothesis-free formulation
--    star-base                : RT at starWeight (base case)
--    star-loop                : RT after any perturbation sequence
--                               starting from starWeight
--
--  Proof structure:
--
--    The loop-invariant proof has exactly the shape predicted in
--    §11.7 item 5 of docs/10-frontier.md:
--
--      loop-invariant w₀ base []       = base
--      loop-invariant w₀ base (s ∷ ss) =
--        step-invariant (weight-sequence w₀ ss) (fst s) (snd s)
--                       (loop-invariant w₀ base ss)
--
--    This is structural induction on the list of perturbation
--    steps.  At each step, step-invariant (from §4 of
--    StarStepInvariance.agda) is applied to extend the invariant
--    by one perturbation.  The proof term is ~5 lines.
--
--  Physical interpretation:
--
--    Each entry  (b , δ)  in the perturbation list is one "tick"
--    of the discrete clock — a local modification to the
--    entanglement network that changes one bond's capacity.  The
--    loop-invariant theorem guarantees that the bulk geometry
--    (L-param) tracks the boundary entanglement (S-param) at
--    every tick, for arbitrarily long sequences.
--
--    This is the constructive, machine-checked content of the
--    informal claim "time is just the universe compiling its
--    next state."  Each tick is a single perturbation; the
--    step-invariant theorem guarantees correctness of each tick;
--    and the loop-invariant theorem guarantees that arbitrarily
--    long sequences of ticks maintain the holographic
--    correspondence.
--
--  Relationship to §9 (Snapshot Dynamics):
--
--    Section 9 packages pre-verified snapshots as
--    DynamicsWitness records.  Each snapshot requires an
--    independently verified bridge.  This module provides the
--    STRONGER claim:  given one verified bridge at an initial
--    configuration, ALL subsequent configurations obtained by
--    perturbation are automatically verified.  No additional
--    Python oracle invocations or Agda type-checking runs are
--    needed for new snapshots.
--
--    | Aspect         | §9 Snapshots    | §11 Loop         |
--    |────────────────|─────────────────|──────────────────|
--    | # proofs       | one per snap    | one for all      |
--    | new-snap cost  | re-verify       | zero (automatic) |
--    | weight fn      | fixed canonical | arbitrary        |
--    | proof method   | refl on closed  | induction + arith|
--
--  Limitation:
--
--    This proves invariance for the star topology only, where
--    S-param and L-param coincide.  For the 11-tile filled patch
--    (where they may differ due to boundary-leg effects), the
--    step-invariant proof would require genuine graph-theoretic
--    reasoning.  See §11.8 of docs/10-frontier.md.
--
--  Exit criterion satisfaction:
--
--    This module satisfies exit criterion 2 of §11.10:
--
--      "A  loop-invariant  theorem type-checks in
--       Bridge/StarDynamicsLoop.agda, proving preservation under
--       arbitrary finite sequences of perturbations (by induction
--       on the list of steps)."
--
--    Together with  Bridge/StarStepInvariance.agda  (exit
--    criterion 1), the "while(true) loop" route is complete.
-- ════════════════════════════════════════════════════════════════════