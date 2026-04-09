{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.EnrichedStarStepInvariance where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels

open import Util.Scalars
open import Util.NatLemmas using (+-comm)
open import Common.StarSpec

open import Boundary.StarCutParam using (S-param)
open import Bulk.StarChainParam   using (L-param ; SL-param)
open import Bridge.StarStepInvariance using (perturb)
open import Bridge.EnrichedStarObs using (isSetObs)
open import Bulk.StarMonotonicity
  using ( _⊆R_
        ; sub-N0∈N4N0 ; sub-N0∈N0N1
        ; sub-N1∈N0N1 ; sub-N1∈N1N2
        ; sub-N2∈N1N2 ; sub-N2∈N2N3
        ; sub-N3∈N2N3 ; sub-N3∈N3N4
        ; sub-N4∈N3N4 ; sub-N4∈N4N0 )
open import Bridge.FullEnrichedStarObs
  using ( Subadditive ; Monotone
        ; isPropSubadditive ; isPropMonotone
        ; _∪R_≡R_ ; u-N0∪N1 ; u-N1∪N2 ; u-N2∪N3 ; u-N3∪N4 ; u-N4∪N0 )


-- ════════════════════════════════════════════════════════════════════
--  Enriched Step-Invariance of the Discrete RT Correspondence
--  under Local Bond-Weight Perturbations on the 6-Tile Star
-- ════════════════════════════════════════════════════════════════════
--
--  This module proves that the full enriched type equivalence
--  (including subadditivity ↔ monotonicity conversion) is preserved
--  under single-bond weight perturbations.  It is Phase F.2b of the
--  §11.7 implementation plan in docs/10-frontier.md.
--
--  The construction parameterizes FullBdy and FullBulk by an
--  arbitrary weight function  w : Bond → ℚ≥0 , proves that:
--
--    (a) S-param w is subadditive for any w  (trivially: both sides
--        of each union inequality are the same ℕ expression)
--    (b) L-param w is monotone for any w  (using +-comm from
--        Util.NatLemmas for 5 of 10 cases, refl for the other 5)
--    (c) FullBdy-w w ≃ FullBulk-w w  for any w  (via SL-param w)
--
--  The step-invariance theorem follows immediately: instantiate the
--  generic equivalence at  perturb w b δ .
--
--  Module dependencies:
--
--    Util/NatLemmas.agda                 — +-comm
--    Boundary/StarCutParam.agda          — S-param
--    Bulk/StarChainParam.agda            — L-param, SL-param
--    Bridge/StarStepInvariance.agda      — perturb
--    Bridge/EnrichedStarObs.agda         — isSetObs
--    Bridge/FullEnrichedStarObs.agda     — Subadditive, Monotone,
--                                          isPropSubadditive, isPropMonotone
--    Bulk/StarMonotonicity.agda          — _⊆R_ constructors
--
--  Reference:
--    docs/10-frontier.md §11.7 Phase F.2b  (enriched step invariance)
--    docs/10-frontier.md §11.10 item 3     (stretch exit criterion)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Parameterized subadditivity — S-param w is subadditive
-- ════════════════════════════════════════════════════════════════════
--
--  For the restricted 5-union relation on the 10-region type,
--  every union is  {N_i} ∪ {N_{i+1}} = {N_i,N_{i+1}} .
--
--  The subadditivity obligation  S(regNiN_{i+1}) ≤ S(regNi) + S(regN_{i+1})
--  reduces to:
--
--    w bCNi + w bCN_{i+1}  ≤  w bCNi + w bCN_{i+1}
--
--  because both sides compute to the same expression.  The witness
--  is  (0 , refl)  since  0 + n = n  definitionally.
--
--  This works for VARIABLE w — no closed-numeral reduction needed.
-- ════════════════════════════════════════════════════════════════════

S-param-subadd : (w : Bond → ℚ≥0) → Subadditive (S-param w)
S-param-subadd w _ _ _ u-N0∪N1 = 0 , refl
S-param-subadd w _ _ _ u-N1∪N2 = 0 , refl
S-param-subadd w _ _ _ u-N2∪N3 = 0 , refl
S-param-subadd w _ _ _ u-N3∪N4 = 0 , refl
S-param-subadd w _ _ _ u-N4∪N0 = 0 , refl


-- ════════════════════════════════════════════════════════════════════
--  §2.  Parameterized monotonicity — L-param w is monotone
-- ════════════════════════════════════════════════════════════════════
--
--  For the 10 subregion inclusions  {N_i} ⊆ {N_j,N_k} , the
--  monotonicity obligation  L(regNi) ≤ L(pair)  reduces to:
--
--    w bCNi  ≤  w bCNj + w bCNk
--
--  The witness  k  is the "other" bond weight.  When Ni is the
--  SECOND summand in the pair (i.e., pair = w bCNj + w bCNi),
--  we get  k + w bCNi = w bCNj + w bCNi  by  refl .  When Ni is
--  the FIRST summand (pair = w bCNi + w bCNk), we need
--  k + w bCNi = w bCNi + w bCNk ,  i.e.,  +-comm k (w bCNi) .
--
--  This is the parameterized arithmetic that §11.4 of
--  docs/10-frontier.md identified as necessary for step-invariance
--  beyond closed-numeral reasoning.
-- ════════════════════════════════════════════════════════════════════

L-param-mono : (w : Bond → ℚ≥0) → Monotone (L-param w)
-- ── N0 inclusions ──────────────────────────────────────────────
--  sub-N0∈N4N0:  w bCN0 ≤ w bCN4 + w bCN0
--    k = w bCN4,  w bCN4 + w bCN0 ≡ w bCN4 + w bCN0  →  refl
L-param-mono w _ _ sub-N0∈N4N0 = w bCN4 , refl
--  sub-N0∈N0N1:  w bCN0 ≤ w bCN0 + w bCN1
--    k = w bCN1,  w bCN1 + w bCN0 ≡ w bCN0 + w bCN1  →  +-comm
L-param-mono w _ _ sub-N0∈N0N1 = w bCN1 , +-comm (w bCN1) (w bCN0)
-- ── N1 inclusions ──────────────────────────────────────────────
L-param-mono w _ _ sub-N1∈N0N1 = w bCN0 , refl
L-param-mono w _ _ sub-N1∈N1N2 = w bCN2 , +-comm (w bCN2) (w bCN1)
-- ── N2 inclusions ──────────────────────────────────────────────
L-param-mono w _ _ sub-N2∈N1N2 = w bCN1 , refl
L-param-mono w _ _ sub-N2∈N2N3 = w bCN3 , +-comm (w bCN3) (w bCN2)
-- ── N3 inclusions ──────────────────────────────────────────────
L-param-mono w _ _ sub-N3∈N2N3 = w bCN2 , refl
L-param-mono w _ _ sub-N3∈N3N4 = w bCN4 , +-comm (w bCN4) (w bCN3)
-- ── N4 inclusions ──────────────────────────────────────────────
L-param-mono w _ _ sub-N4∈N3N4 = w bCN3 , refl
L-param-mono w _ _ sub-N4∈N4N0 = w bCN0 , +-comm (w bCN0) (w bCN4)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Parameterized full enriched record types
-- ════════════════════════════════════════════════════════════════════
--
--  FullBdy-w w  bundles an observable function with:
--    (1) certification against the parameterized boundary spec S-param w
--    (2) a subadditivity witness
--
--  FullBulk-w w  bundles an observable function with:
--    (1) certification against the parameterized bulk spec L-param w
--    (2) a monotonicity witness
--
--  These generalize  FullBdy / FullBulk  from
--  Bridge/FullEnrichedStarObs.agda (which are specialized to the
--  canonical  starWeight ) to arbitrary weight functions.
-- ════════════════════════════════════════════════════════════════════

record FullBdy-w (w : Bond → ℚ≥0) : Type₀ where
  field
    obs    : Region → ℚ≥0
    spec   : obs ≡ S-param w
    subadd : Subadditive obs

record FullBulk-w (w : Bond → ℚ≥0) : Type₀ where
  field
    obs  : Region → ℚ≥0
    spec : obs ≡ L-param w
    mono : Monotone obs


-- ════════════════════════════════════════════════════════════════════
--  §4.  Canonical inhabitants for any w
-- ════════════════════════════════════════════════════════════════════

full-bdy-w : (w : Bond → ℚ≥0) → FullBdy-w w
full-bdy-w w .FullBdy-w.obs    = S-param w
full-bdy-w w .FullBdy-w.spec   = refl
full-bdy-w w .FullBdy-w.subadd = S-param-subadd w

full-bulk-w : (w : Bond → ℚ≥0) → FullBulk-w w
full-bulk-w w .FullBulk-w.obs  = L-param w
full-bulk-w w .FullBulk-w.spec = refl
full-bulk-w w .FullBulk-w.mono = L-param-mono w


-- ════════════════════════════════════════════════════════════════════
--  §5.  Derivation lemmas
-- ════════════════════════════════════════════════════════════════════
--
--  Given a specification-agreement witness, derive the structural
--  property by transporting the known property of S-param w / L-param w.
-- ════════════════════════════════════════════════════════════════════

private
  derive-subadd-w : (w : Bond → ℚ≥0) (f : Region → ℚ≥0)
    → f ≡ S-param w → Subadditive f
  derive-subadd-w w _ p = subst Subadditive (sym p) (S-param-subadd w)

  derive-mono-w : (w : Bond → ℚ≥0) (f : Region → ℚ≥0)
    → f ≡ L-param w → Monotone f
  derive-mono-w w _ q = subst Monotone (sym q) (L-param-mono w)


-- ════════════════════════════════════════════════════════════════════
--  §6.  The Iso between FullBdy-w and FullBulk-w
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map converts a boundary-certified bundle (with
--  subadditivity) into a bulk-certified bundle (with monotonicity)
--  by appending  SL-param w : S-param w ≡ L-param w  to the spec
--  field and deriving monotonicity from  L-param-mono w .
--
--  Round-trip proofs close because:
--    • spec fields live in a set (isSetObs)
--    • structural property fields are propositional
--      (isPropSubadditive, isPropMonotone)
-- ════════════════════════════════════════════════════════════════════

full-iso-w : (w : Bond → ℚ≥0) → Iso (FullBdy-w w) (FullBulk-w w)
full-iso-w w = iso fwd bwd fwd-bwd bwd-fwd
  where
    obs-path : S-param w ≡ L-param w
    obs-path = SL-param w

    fwd : FullBdy-w w → FullBulk-w w
    fwd a = record
      { obs  = FullBdy-w.obs a
      ; spec = FullBdy-w.spec a ∙ obs-path
      ; mono = derive-mono-w w (FullBdy-w.obs a)
                 (FullBdy-w.spec a ∙ obs-path)
      }

    bwd : FullBulk-w w → FullBdy-w w
    bwd b = record
      { obs    = FullBulk-w.obs b
      ; spec   = FullBulk-w.spec b ∙ sym obs-path
      ; subadd = derive-subadd-w w (FullBulk-w.obs b)
                   (FullBulk-w.spec b ∙ sym obs-path)
      }

    fwd-bwd : (b : FullBulk-w w) → fwd (bwd b) ≡ b
    fwd-bwd b i = record
      { obs  = FullBulk-w.obs b
      ; spec = isSetObs (FullBulk-w.obs b) (L-param w)
                 ((FullBulk-w.spec b ∙ sym obs-path) ∙ obs-path)
                 (FullBulk-w.spec b) i
      ; mono = isPropMonotone (FullBulk-w.obs b)
                 (derive-mono-w w (FullBulk-w.obs b)
                   ((FullBulk-w.spec b ∙ sym obs-path) ∙ obs-path))
                 (FullBulk-w.mono b) i
      }

    bwd-fwd : (a : FullBdy-w w) → bwd (fwd a) ≡ a
    bwd-fwd a i = record
      { obs    = FullBdy-w.obs a
      ; spec   = isSetObs (FullBdy-w.obs a) (S-param w)
                   ((FullBdy-w.spec a ∙ obs-path) ∙ sym obs-path)
                   (FullBdy-w.spec a) i
      ; subadd = isPropSubadditive (FullBdy-w.obs a)
                   (derive-subadd-w w (FullBdy-w.obs a)
                     ((FullBdy-w.spec a ∙ obs-path) ∙ sym obs-path))
                   (FullBdy-w.subadd a) i
      }


-- ════════════════════════════════════════════════════════════════════
--  §7.  The equivalence — for any weight function
-- ════════════════════════════════════════════════════════════════════

full-equiv-w : (w : Bond → ℚ≥0) → FullBdy-w w ≃ FullBulk-w w
full-equiv-w w = isoToEquiv (full-iso-w w)


-- ════════════════════════════════════════════════════════════════════
--  §8.  enriched-step-invariant — The Main Theorem
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Enriched Step-Invariance).
--
--  For the 6-tile star patch of the {5,4} HaPPY code with
--  arbitrary bond weights, the enriched type equivalence
--  (including subadditivity ↔ monotonicity conversion) is
--  invariant under single-bond weight perturbations.
--
--  Formally:  if the enriched equivalence holds at weight
--  assignment  w , it holds at  perturb w b δ .
--
--  The hypothesis is unused: the equivalence holds for ANY
--  weight function because  S-param  and  L-param  are
--  definitionally the same function on the star topology.
--  The hypothesis is retained to match the type signature
--  from §11.7 Phase F.2b of docs/10-frontier.md and to
--  generalize to non-star topologies where it would be needed.
--
--  Reference:
--    docs/10-frontier.md §11.7 Phase F.2b
--    docs/10-frontier.md §11.10 item 3  (stretch exit criterion)
-- ════════════════════════════════════════════════════════════════════

enriched-step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → FullBdy-w w ≃ FullBulk-w w
  → FullBdy-w (perturb w b δ) ≃ FullBulk-w (perturb w b δ)
enriched-step-invariant w b δ _ = full-equiv-w (perturb w b δ)


-- ════════════════════════════════════════════════════════════════════
--  §9.  Unconditional formulation
-- ════════════════════════════════════════════════════════════════════
--
--  For the star topology, the enriched equivalence holds at ANY
--  weight function.  This formulation drops the redundant hypothesis.
-- ════════════════════════════════════════════════════════════════════

enriched-step-invariant-unconditional :
  (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → FullBdy-w (perturb w b δ) ≃ FullBulk-w (perturb w b δ)
enriched-step-invariant-unconditional w b δ = full-equiv-w (perturb w b δ)


-- ════════════════════════════════════════════════════════════════════
--  §10.  Regression tests — structural properties at perturbed weights
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the parameterized structural property proofs
--  produce the expected results when applied to concrete perturbed
--  weight functions.
-- ════════════════════════════════════════════════════════════════════

private
  w-test : Bond → ℚ≥0
  w-test = perturb starWeight bCN0 3

  -- Subadditivity at the perturbed weight:
  --   S(regN0N1) ≤ S(regN0) + S(regN1)
  --   = (w bCN0 + w bCN1) ≤ w bCN0 + w bCN1
  --   = (4 + 1) ≤ (4 + 1)  =  5 ≤ 5
  check-subadd :
    S-param w-test regN0N1
    ≤ℚ (S-param w-test regN0 +ℚ S-param w-test regN1)
  check-subadd = S-param-subadd w-test _ _ _ u-N0∪N1

  -- Monotonicity at the perturbed weight:
  --   L(regN0) ≤ L(regN0N1)
  --   = w bCN0 ≤ (w bCN0 + w bCN1)
  --   = 4 ≤ (4 + 1)  =  4 ≤ 5
  check-mono :
    L-param w-test regN0
    ≤ℚ L-param w-test regN0N1
  check-mono = L-param-mono w-test _ _ sub-N0∈N0N1

  -- The enriched equivalence exists at the perturbed weight
  check-equiv : FullBdy-w w-test ≃ FullBulk-w w-test
  check-equiv = full-equiv-w w-test


-- ════════════════════════════════════════════════════════════════════
--  §11.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    S-param-subadd   : (w : Bond → ℚ≥0) → Subadditive (S-param w)
--    L-param-mono     : (w : Bond → ℚ≥0) → Monotone (L-param w)
--    FullBdy-w        : (Bond → ℚ≥0) → Type₀  (parameterized record)
--    FullBulk-w       : (Bond → ℚ≥0) → Type₀  (parameterized record)
--    full-bdy-w       : (w : Bond → ℚ≥0) → FullBdy-w w
--    full-bulk-w      : (w : Bond → ℚ≥0) → FullBulk-w w
--    full-equiv-w     : (w : Bond → ℚ≥0) → FullBdy-w w ≃ FullBulk-w w
--    enriched-step-invariant : conditional formulation
--    enriched-step-invariant-unconditional : hypothesis-free
--
--  Proof effort breakdown:
--
--    S-param-subadd:     5 cases,  all  (0 , refl)
--    L-param-mono:      10 cases,  5 × refl  +  5 × +-comm
--    full-iso-w:        ~30 lines  (mirroring full-iso from
--                                   FullEnrichedStarObs, parameterized)
--    enriched-step-invariant:  1 line (!)
--
--  The +-comm dependency is the ONLY piece of ℕ arithmetic lemma
--  infrastructure needed.  This validates the estimate from §11.5
--  of docs/10-frontier.md that Strategy A would require "50 lines
--  of ℕ reasoning" — the actual arithmetic is much simpler because
--  subadditivity is trivial and monotonicity needs only commutativity.
--
--  This module satisfies exit criterion 3 (stretch) of §11.10:
--
--    "An analogous theorem for the enriched equivalence (including
--     subadditivity ↔ monotonicity conversion)."
-- ════════════════════════════════════════════════════════════════════