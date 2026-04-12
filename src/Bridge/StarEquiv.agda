{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.StarEquiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCut
open import Bulk.StarChain
open import Common.ObsPackage
open import Bridge.StarObs

-- ════════════════════════════════════════════════════════════════════
--  star-obs-path — Function equality of observables
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the pointwise agreement proof  star-pointwise  into a
--  single path between the observable functions:
--
--    S-cut (π∂ starSpec)  ≡  L-min (πbulk starSpec)
--
--  In Cubical Agda, function extensionality is native to the path
--  type.  The term  funExt star-pointwise  is definitionally equal
--  to  λ i r → star-pointwise r i , a path in the function space
--  Region → ℚ≥0 that interpolates between the boundary min-cut
--  functional and the bulk minimal-chain-length functional.
--
--  The 10 pointwise equalities (5 singletons + 5 pairs) encode the
--  discrete Ryu–Takayanagi correspondence for the 6-tile star:
--    S_cut(A) = L_min(A)   for all tile-aligned contiguous regions A
--  verified numerically by sim/prototyping/01_happy_patch_cuts.py.
--
--  This is the discrete Ryu–Takayanagi correspondence (Theorem 1
--  in docs/formal/01-theorems.md) for the 6-tile star instance,
--  assembling the pointwise agreement from Bridge/StarObs.agda
--  into a single function-level path via funExt.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §2  (pointwise agreement)
--    docs/formal/02-foundations.md §2.3       (funExt in Cubical Agda)
--    docs/instances/star-patch.md §4          (min-cut / observable
--                                              agreement table)
--    docs/instances/star-patch.md §6          (bridge construction)
--    sim/prototyping/01_happy_patch_cuts.py   (numerical verification)
-- ════════════════════════════════════════════════════════════════════

star-obs-path :
  S-cut (π∂ starSpec) ≡ L-min (πbulk starSpec)
star-obs-path = funExt star-pointwise

-- ════════════════════════════════════════════════════════════════════
--  star-package-path — Package-level path
-- ════════════════════════════════════════════════════════════════════
--
--  Lifts the observable-function path  star-obs-path  to a path
--  between the full observable packages:
--
--    Obs∂ starSpec  ≡  ObsBulk starSpec
--
--  Because  ObsPackage Region  has a single field (obs), the record
--  path is simply the obs-field path wrapped in copattern syntax.
--  At dimension i, we build a record whose obs field is the
--  function  star-obs-path i : Region → ℚ≥0 .  At i = i0 this is
--  S-cut (π∂ starSpec)  (the boundary observable), and at i = i1
--  it is  L-min (πbulk starSpec)  (the bulk observable).
--
--  This completes the minimal bridge for the 6-tile star instance.
--  The end-to-end pipeline is:
--
--    starSpec  →  π∂ / πbulk  →  Obs∂ / ObsBulk  →  star-package-path
--
--  All of which is verified by the Cubical Agda type-checker.
--
--  This is the **second bridge calibration object** in the
--  repository (the first being tree-package-path in
--  Bridge/TreeEquiv.agda), confirming that the observable-package
--  architecture scales from 1D trees to genuine 2D tilings from
--  the holographic literature.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §2  (pointwise agreement)
--    docs/instances/star-patch.md §6          (bridge construction)
--    docs/instances/tree-pilot.md §6          (tree pilot bridge)
-- ════════════════════════════════════════════════════════════════════

star-package-path : Obs∂ starSpec ≡ ObsBulk starSpec
star-package-path i .ObsPackage.obs = star-obs-path i

-- ════════════════════════════════════════════════════════════════════
--  STRETCH GOAL (Step 7b) — Type-level Univalence calibration
-- ════════════════════════════════════════════════════════════════════
--
--  The path  star-package-path  above is a path between *values*
--  of  ObsPackage Region , not between *types* in a universe.
--  The ua combinator applies to type equivalences, not value
--  equalities.  To exercise the Univalence machinery on the star
--  instance, we define type-family variants of the observable
--  packages and run ua on the resulting (trivial) equivalence.
--
--  For the star instance, both type families produce the same type
--  (Region → ℚ≥0), so the equivalence is  idEquiv  and transport
--  along the resulting  ua  path is the identity function.  This
--  is expected and intentional: the star instance, like the tree
--  pilot, calibrates the plumbing on a known-trivial case.
--
--  A nontrivial  ua  step requires enriched packages with
--  asymmetric proof-carrying fields — e.g. a subadditivity witness
--  on the boundary side (as formalized in
--  Boundary/StarSubadditivity.agda) and a monotonicity witness on
--  the bulk side (as formalized in Bulk/StarMonotonicity.agda).
--  The full enriched equivalence converting subadditivity into
--  monotonicity via transport is constructed in
--  Bridge/FullEnrichedStarObs.agda.
--
--  See also Bridge/TreeEquiv.agda for the tree-pilot analogue
--  and docs/formal/03-holographic-bridge.md §3–§4 for the
--  enriched type equivalence construction.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3  (enriched types)
--    docs/formal/03-holographic-bridge.md §4  (full enriched equiv)
--    docs/formal/02-foundations.md §5         (ua and uaβ)
--    docs/instances/tree-pilot.md §10         (what tree does NOT exercise)
--    docs/instances/star-patch.md §6          (bridge construction)
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Type families extracting the underlying observable type from
--  a common source specification.  For the star instance, both
--  sides produce  Region → ℚ≥0 .
--
--  In the enriched-package architecture (Bridge/FullEnrichedStarObs.agda),
--  the boundary type family produces a record with a subadditivity
--  field and the bulk type family produces a record with a
--  monotonicity field — making these two families genuinely
--  different and the resulting equivalence nontrivial.
-- ────────────────────────────────────────────────────────────────

Obs∂-Ty : StarSpec → Type₀
Obs∂-Ty _ = Region → ℚ≥0

ObsBulk-Ty : StarSpec → Type₀
ObsBulk-Ty _ = Region → ℚ≥0

-- ────────────────────────────────────────────────────────────────
--  star-type-equiv — The type-level equivalence
-- ────────────────────────────────────────────────────────────────
--
--  Since both type families produce the same type, the equivalence
--  is the identity equivalence on  Region → ℚ≥0 .  In the enriched
--  bridge (Bridge/EnrichedStarObs.agda, Bridge/FullEnrichedStarObs.agda)
--  where the boundary and bulk sides carry different record
--  structure (specification-agreement fields, structural property
--  witnesses), this equivalence requires genuine construction work
--  (forward/inverse maps + coherent round-trip homotopies).
-- ────────────────────────────────────────────────────────────────

star-type-equiv : Obs∂-Ty starSpec ≃ ObsBulk-Ty starSpec
star-type-equiv = idEquiv (Region → ℚ≥0)

-- ────────────────────────────────────────────────────────────────
--  star-ua-path — The Univalence path between observable types
-- ────────────────────────────────────────────────────────────────
--
--  Applying  ua  to the identity equivalence yields a path in the
--  universe  Type₀  from  Obs∂-Ty starSpec  to
--  ObsBulk-Ty starSpec .  Because  idEquiv  is the trivial
--  equivalence, this path is propositionally (though not
--  judgmentally) equal to  refl , as witnessed by
--  star-ua-trivial  below.
-- ────────────────────────────────────────────────────────────────

star-ua-path : Obs∂-Ty starSpec ≡ ObsBulk-Ty starSpec
star-ua-path = ua star-type-equiv

-- ────────────────────────────────────────────────────────────────
--  star-ua-trivial — The ua path is propositionally refl
-- ────────────────────────────────────────────────────────────────
--
--  The cubical library provides  uaIdEquiv : ua (idEquiv A) ≡ refl .
--  This confirms that the Univalence path we constructed adds no
--  nontrivial content for the star instance, as expected.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1  (ua and uaβ)
-- ────────────────────────────────────────────────────────────────

star-ua-trivial : star-ua-path ≡ refl
star-ua-trivial = uaIdEquiv

-- ────────────────────────────────────────────────────────────────
--  star-transport-id — Transport is the identity
-- ────────────────────────────────────────────────────────────────
--
--  Transport along  ua (idEquiv A)  sends every element to itself.
--  This follows from  uaβ , which states:
--
--    transport (ua e) x  ≡  equivFun e x
--
--  Since  equivFun (idEquiv A) x  reduces judgmentally to  x ,
--  the result is  transport star-ua-path f ≡ f .
--
--  Reference:
--    docs/formal/02-foundations.md §5.1  (uaβ computation rule)
-- ────────────────────────────────────────────────────────────────

star-transport-id :
  (f : Obs∂-Ty starSpec) → transport star-ua-path f ≡ f
star-transport-id f = uaβ star-type-equiv f

-- ────────────────────────────────────────────────────────────────
--  star-transport-obs — End-to-end transport verification
-- ────────────────────────────────────────────────────────────────
--
--  Combines the transport identity with the observable agreement
--  to show that transporting the boundary observable function
--  along the Univalence path yields the bulk observable function:
--
--    transport star-ua-path (obs (Obs∂ starSpec))
--      ≡ obs (Obs∂ starSpec)                         by star-transport-id
--      ≡ obs (ObsBulk starSpec)                      by star-obs-path
--
--  For the star instance this is a trivial composition, but it
--  exercises the full pipeline that later instances depend on:
--
--    common source  →  extract views  →  build packages
--      →  construct equivalence  →  apply ua  →  transport
--
--  This is the second time the repository runs this full pipeline
--  (the first being tree-transport-obs in Bridge/TreeEquiv.agda),
--  now validated on a genuine 2D tiling from the holographic
--  literature rather than a 1D tree.
--
--  The nontrivial enriched equivalence — where transport converts
--  a subadditivity witness into a monotonicity witness — is
--  constructed in Bridge/EnrichedStarObs.agda (specification-
--  agreement equivalence) and Bridge/FullEnrichedStarObs.agda
--  (full structural-property conversion).  The generic bridge
--  from Bridge/GenericBridge.agda subsumes both constructions
--  for all twelve verified patch instances.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3  (enriched equiv)
--    docs/formal/03-holographic-bridge.md §4  (full enriched equiv)
--    docs/formal/03-holographic-bridge.md §5  (generic bridge)
--    docs/formal/02-foundations.md §3         (transport)
--    docs/formal/02-foundations.md §5         (ua and uaβ)
--    docs/instances/star-patch.md §6          (bridge construction)
--    docs/instances/tree-pilot.md §6          (tree pilot bridge)
--    docs/formal/11-generic-bridge.md         (PatchData → BridgeWitness)
-- ────────────────────────────────────────────────────────────────

star-transport-obs :
  transport star-ua-path (ObsPackage.obs (Obs∂ starSpec))
  ≡ ObsPackage.obs (ObsBulk starSpec)
star-transport-obs =
  star-transport-id (ObsPackage.obs (Obs∂ starSpec)) ∙ star-obs-path