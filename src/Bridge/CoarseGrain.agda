{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.CoarseGrain where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Sigma using (Σ-syntax)

open import Util.Scalars


-- ════════════════════════════════════════════════════════════════════
--  §1.  CoarseGrainLevel — A single level of coarse-graining
-- ════════════════════════════════════════════════════════════════════
--
--  A coarse-graining level is a surjection from a fine-grained
--  region type to a coarse-grained one, equipped with observable
--  functions on both levels and a compatibility proof that the
--  fine observable factors through the coarse observable via the
--  projection.
--
--  The parametric version keeps Fine and Coarse as parameters
--  (in Type₀), so the record itself lives in Type₀.
--
--  Reference: §8.4 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

record CoarseGrainLevel (Fine Coarse : Type₀) : Type₀ where
  field
    project    : Fine → Coarse
    obs-fine   : Fine → ℚ≥0
    obs-coarse : Coarse → ℚ≥0
    compat     : (r : Fine) → obs-fine r ≡ obs-coarse (project r)


-- ════════════════════════════════════════════════════════════════════
--  §2.  CoarseGrainWitness — Existential packaging
-- ════════════════════════════════════════════════════════════════════
--
--  The witness record packs the fine and coarse region types as
--  fields (rather than parameters), enabling heterogeneous
--  collections of coarse-graining levels.  Because it stores
--  types as fields, the record lives in Type₁.
--
--  The  bridge  field is a placeholder for the Ryu–Takayanagi
--  correspondence at the coarse level:  it asserts that the
--  coarse observable agrees with itself.  In a richer formulation,
--  this would be replaced by a proof that the coarse observable
--  equals a bulk-side coarse observable (extending Theorem 3 to
--  the coarse resolution).  For now, the trivial  refl  suffices
--  as the coarse-grained RT follows from the fine-grained RT
--  (d100-pointwise) composed with compat.
--
--  Reference: §8.7 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

record CoarseGrainWitness : Type₁ where
  field
    FineRegion   : Type₀
    CoarseRegion : Type₀
    project      : FineRegion → CoarseRegion
    obs-fine     : FineRegion → ℚ≥0
    obs-coarse   : CoarseRegion → ℚ≥0
    compat       : (r : FineRegion) → obs-fine r ≡ obs-coarse (project r)
    bridge       : (o : CoarseRegion) → obs-coarse o ≡ obs-coarse o
                   -- Placeholder for the RT correspondence at the
                   -- coarse level.  Trivially  refl  because both
                   -- sides are the same term.  A future enrichment
                   -- would replace this with a genuine coarse-level
                   -- bridge:  obs-coarse-bdy o ≡ obs-coarse-bulk o .


-- ════════════════════════════════════════════════════════════════════
--  §3.  Dense-100 Imports
-- ════════════════════════════════════════════════════════════════════
--
--  The orbit reduction machinery from Dense-100 (09_generate_dense100.py)
--  provides the first concrete coarse-graining instance:
--
--    Fine   = D100Region   (717 constructors)  — cell-aligned boundary
--                                                regions of the Dense-100
--                                                patch of the {4,3,5}
--                                                hyperbolic honeycomb
--    Coarse = D100OrbitRep (8 constructors)    — orbit representatives
--                                                grouped by min-cut value
--    project = classify100                      — 717-clause classification
--
--  The observable on the fine level is  S-cut d100BdyView : D100Region → ℚ≥0 ,
--  the boundary min-cut entropy functional.  On the coarse level it is
--  S-cut-rep : D100OrbitRep → ℚ≥0 , the 8-clause orbit lookup.
--
--  The compatibility condition  S-cut d100BdyView r ≡ S-cut-rep (classify100 r)
--  holds DEFINITIONALLY because  S-cut  is defined as  S-cut-rep ∘ classify100
--  in Boundary/Dense100Cut.agda.  The compat proof is therefore  refl .
--
--  This definitional factorization is the type-theoretic content of
--  the statement "orbit reduction preserves the observable" — the
--  observer who sees only D100OrbitRep cannot distinguish individual
--  regions but reads the correct entropy value for each orbit class.
-- ════════════════════════════════════════════════════════════════════

open import Common.Dense100Spec
  using (D100Region ; D100OrbitRep ; classify100)
open import Boundary.Dense100Cut
  using (D100BdyView ; S-cut ; S-cut-rep)
open import Bridge.Dense100Obs
  using (d100BdyView)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Dense-100 CoarseGrainLevel instance
-- ════════════════════════════════════════════════════════════════════
--
--  The parametric instance, keeping the region types as parameters.
--
--  All fields are filled from the existing Dense-100 orbit reduction
--  machinery.  The compat field is  λ _ → refl  because S-cut is
--  defined as  S-cut-rep ∘ classify100  in Boundary/Dense100Cut.agda.
--
--  This instance witnesses that the orbit reduction from
--  Common/Dense100Spec.agda is a valid coarse-graining: the
--  classification function  classify100  preserves the min-cut
--  entropy observable.
-- ════════════════════════════════════════════════════════════════════

dense100-level : CoarseGrainLevel D100Region D100OrbitRep
dense100-level .CoarseGrainLevel.project    = classify100
dense100-level .CoarseGrainLevel.obs-fine   = S-cut d100BdyView
dense100-level .CoarseGrainLevel.obs-coarse = S-cut-rep
dense100-level .CoarseGrainLevel.compat     = λ _ → refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Dense-100 CoarseGrainWitness instance
-- ════════════════════════════════════════════════════════════════════
--
--  The existential packaging, storing the region types as fields.
--
--  This is the record from §8.7 of docs/10-frontier.md, fully
--  instantiated for the Dense-100 orbit reduction:
--
--    717 fine-grained regions  →  8 orbit representatives
--
--  The  bridge  field is  λ _ → refl  (placeholder).  The physical
--  content of the bridge at the coarse level is inherited from the
--  fine-grained Theorem 3 (d100-theorem3 from Bridge/Dense100Equiv.agda)
--  via the compat factorization.  Explicitly:
--
--    For any orbit representative o = classify100 r :
--      S-cut-rep o  ≡  L-min-rep o       (by d100-pointwise-rep o)
--
--  This is the orbit-level discrete RT correspondence, already proven
--  in Bridge/Dense100Obs.agda.  The bridge field here is the trivial
--  self-equality version, which suffices for the exit criterion of §8.11.
-- ════════════════════════════════════════════════════════════════════

dense100-coarse-witness : CoarseGrainWitness
dense100-coarse-witness .CoarseGrainWitness.FineRegion   = D100Region
dense100-coarse-witness .CoarseGrainWitness.CoarseRegion = D100OrbitRep
dense100-coarse-witness .CoarseGrainWitness.project      = classify100
dense100-coarse-witness .CoarseGrainWitness.obs-fine     = S-cut d100BdyView
dense100-coarse-witness .CoarseGrainWitness.obs-coarse   = S-cut-rep
dense100-coarse-witness .CoarseGrainWitness.compat       = λ _ → refl
dense100-coarse-witness .CoarseGrainWitness.bridge       = λ _ → refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Spot checks — compat is definitional
-- ════════════════════════════════════════════════════════════════════
--
--  These regression tests verify that the compat field produces the
--  expected refl for specific regions.  Each test unfolds S-cut at
--  the given region (which first evaluates classify100 on the
--  717-clause function, then S-cut-rep on the 8-clause function)
--  and checks that both sides reduce to the same ℕ literal.
--
--  These serve as documentation: they make explicit that the
--  coarse-graining factorization is judgmentally trivial for the
--  orbit-reduction architecture.
-- ════════════════════════════════════════════════════════════════════

open import Common.Dense100Spec using (d100r0 ; d100r1 ; d100r15)

private
  -- d100r0 is a singleton cell with min-cut 1
  compat-check-r0 : S-cut d100BdyView d100r0 ≡ S-cut-rep (classify100 d100r0)
  compat-check-r0 = refl

  -- d100r1 has min-cut 3
  compat-check-r1 : S-cut d100BdyView d100r1 ≡ S-cut-rep (classify100 d100r1)
  compat-check-r1 = refl

  -- d100r15 has min-cut 8 (the highest value)
  compat-check-r15 : S-cut d100BdyView d100r15 ≡ S-cut-rep (classify100 d100r15)
  compat-check-r15 = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  CoarseGrainedRT — The fully formalized statement (§8.10)
-- ════════════════════════════════════════════════════════════════════
--
--  The fully formalized coarse-grained RT statement packages
--  three pieces of data:
--
--    1. A CoarseGrainWitness  w  (coarse-graining infrastructure)
--    2. A  regionArea  function  (FineRegion w → ℚ≥0)  computing
--       the boundary surface area of each fine-grained region
--    3. An area-law bound:  for every region  r ,
--       obs-fine w r  ≤ℚ  regionArea r
--
--  Crucially,  regionArea  is placed INSIDE the Sigma, indexed by
--  the same witness  w .  This ensures that  r : FineRegion w  and
--  regionArea : FineRegion w → ℚ≥0  share the same domain, making
--  the application  regionArea r  well-typed for any  w .
--
--  When  w = dense100-coarse-witness , the types specialise:
--    FineRegion w  =  D100Region
--    regionArea    :  D100Region → ℚ≥0
--
--  The  regionArea  function will be defined in
--  Boundary/Dense100AreaLaw.agda  (generated by
--  sim/prototyping/11_generate_area_law.py).  To instantiate
--  CoarseGrainedRT , that module provides the triple:
--
--    (dense100-coarse-witness , regionArea , λ r → (k , refl))
--
--  Reference: §8.10 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

CoarseGrainedRT : Type₁
CoarseGrainedRT =
  Σ[ w ∈ CoarseGrainWitness ]
  Σ[ regionArea ∈ (CoarseGrainWitness.FineRegion w → ℚ≥0) ]
    ((r : CoarseGrainWitness.FineRegion w) →
     CoarseGrainWitness.obs-fine w r ≤ℚ regionArea r)


-- ════════════════════════════════════════════════════════════════════
--  §8.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  This module provides the coarse-graining infrastructure for
--  Section 8 of docs/10-frontier.md ("The Thermodynamic Illusion
--  Route").
--
--  Exports:
--
--    CoarseGrainLevel     — parametric coarse-graining record
--    CoarseGrainWitness   — existential coarse-graining record
--    dense100-level       — Dense-100 parametric instance
--    dense100-coarse-witness — Dense-100 existential instance
--    CoarseGrainedRT      — type for the full area-law statement
--
--  The Dense-100 instance demonstrates that the orbit reduction
--  strategy from §6.5 of docs/10-frontier.md IS a coarse-graining:
--
--    • The classification function  classify100 : D100Region → D100OrbitRep
--      maps 717 fine-grained regions to 8 orbit representatives.
--
--    • The observable  S-cut-rep  on orbit representatives returns
--      the min-cut value shared by all regions in each orbit.
--
--    • The compat condition holds DEFINITIONALLY (by refl) because
--      S-cut is defined as  S-cut-rep ∘ classify100 .
--
--  This "compat by refl" property is the type-theoretic content of
--  the statement "statistical averaging preserves the entropy–area
--  relationship."  An observer who sees only orbit classes reads
--  the same entropy value as an observer who sees the full 717-region
--  state space.
--
--  The physical interpretation (§8.6):
--
--    Observer 1  (Dense-100 orbit reduction):
--      Fine   = D100Region   (717 constructors)
--      Coarse = D100OrbitRep (8 constructors)
--      Memory = 3 bits (⌈log₂ 8⌉)
--
--  The thermodynamic claim — that these finite witnesses form a
--  convergent sequence as N → ∞ — is a metatheoretic claim beyond
--  the scope of constructive Cubical Agda (§8.8).  This module
--  provides the finite constructive content.
--
--  Exit criterion (§8.11):
--    "A CoarseGrainWitness record type-checks in
--     Bridge/CoarseGrain.agda with the Dense-100 orbit reduction
--     as the concrete instance."
--
--  New modules (Tier 2):
--
--    Boundary/Dense100AreaLaw.agda   (generated by 11_generate_area_law.py)
--    will provide  regionArea  and the  abstract  proof that
--    S-cut d100BdyView r ≤ℚ regionArea r  for each of the 717 regions.
--    Together with  dense100-coarse-witness , this instantiates
--    CoarseGrainedRT  to produce the full formalized statement
--    from §8.10.
--
--  Relationship to existing code:
--
--    This module builds on (but does NOT modify):
--      • Common/Dense100Spec.agda       — D100OrbitRep, classify100
--      • Boundary/Dense100Cut.agda      — S-cut, S-cut-rep
--      • Bridge/Dense100Obs.agda        — d100BdyView, d100-pointwise
--      • Bridge/Dense100Equiv.agda      — enriched equivalence
--      • Util/Scalars.agda              — ℚ≥0, _≤ℚ_
-- ════════════════════════════════════════════════════════════════════