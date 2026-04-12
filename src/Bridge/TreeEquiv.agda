{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.TreeEquiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence

open import Util.Scalars
open import Common.TreeSpec
open import Boundary.TreeCut
open import Bulk.TreeChain
open import Common.ObsPackage
open import Bridge.TreeObs

-- ════════════════════════════════════════════════════════════════════
--  tree-obs-path — Function equality of observables
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the pointwise agreement proof  tree-pointwise  into a
--  single path between the observable functions:
--
--    S-cut (π∂ treeSpec)  ≡  L-min (πbulk treeSpec)
--
--  In Cubical Agda, function extensionality is native to the path
--  type.  The term  funExt tree-pointwise  is definitionally equal
--  to  λ i r → tree-pointwise r i , a path in the function space
--  Region → ℚ≥0 that interpolates between the boundary min-cut
--  functional and the bulk minimal-chain-length functional.
--
--  Architectural status:
--    This module is DEAD CODE — architecturally superseded by the
--    generic bridge (Bridge/GenericBridge.agda).  The tree pilot's
--    BridgeWitness is now produced by GenericEnriched via
--    Bridge/GenericValidation.agda.  This module remains valid as
--    a historical artifact from the initial development phase and
--    as a pedagogical example of the simplest bridge construction.
--
--  Reference:
--    docs/instances/tree-pilot.md §6          (bridge construction)
--    docs/formal/03-holographic-bridge.md §2  (pointwise agreement)
--    docs/formal/02-foundations.md §2.3       (funExt in Cubical Agda)
--    docs/formal/11-generic-bridge.md         (superseding architecture)
--    Historical: docs/historical/development-docs/08-tree-instance.md
-- ════════════════════════════════════════════════════════════════════

tree-obs-path :
  S-cut (π∂ treeSpec) ≡ L-min (πbulk treeSpec)
tree-obs-path = funExt tree-pointwise

-- ════════════════════════════════════════════════════════════════════
--  tree-package-path — Package-level path
-- ════════════════════════════════════════════════════════════════════
--
--  Lifts the observable-function path  tree-obs-path  to a path
--  between the full observable packages:
--
--    Obs∂ treeSpec  ≡  ObsBulk treeSpec
--
--  Because  ObsPackage Region  has a single field (obs), the record
--  path is simply the obs-field path wrapped in copattern syntax.
--  At dimension i, we build a record whose obs field is the
--  function  tree-obs-path i : Region → ℚ≥0 .  At i = i0 this is
--  S-cut (π∂ treeSpec)  (the boundary observable), and at i = i1
--  it is  L-min (πbulk treeSpec)  (the bulk observable).
--
--  This completes the minimal bridge for the tree pilot instance.
--  The end-to-end pipeline is:
--
--    treeSpec  →  π∂ / πbulk  →  Obs∂ / ObsBulk  →  tree-package-path
--
--  All of which is verified by the Cubical Agda type-checker.
--
--  Reference:
--    docs/instances/tree-pilot.md §6          (bridge construction)
--    docs/formal/03-holographic-bridge.md §2  (pointwise agreement)
-- ════════════════════════════════════════════════════════════════════

tree-package-path : Obs∂ treeSpec ≡ ObsBulk treeSpec
tree-package-path i .ObsPackage.obs = tree-obs-path i

-- ════════════════════════════════════════════════════════════════════
--  STRETCH GOAL — Type-level Univalence calibration
-- ════════════════════════════════════════════════════════════════════
--
--  The path  tree-package-path  above is a path between *values*
--  of  ObsPackage Region , not between *types* in a universe.
--  The ua combinator applies to type equivalences, not value
--  equalities.  To exercise the Univalence machinery on the tree
--  pilot, we define type-family variants of the observable
--  packages and run ua on the resulting (trivial) equivalence.
--
--  For the tree pilot, both type families produce the same type
--  (Region → ℚ≥0), so the equivalence is  idEquiv  and transport
--  along the resulting  ua  path is the identity function.  This
--  is expected and intentional: the tree pilot calibrates the
--  plumbing on a known-trivial case before the enriched star
--  instance (Bridge/EnrichedStarObs.agda) introduces genuinely
--  distinct type structure with a nontrivial ua step.
--
--  The nontrivial Univalence application is exercised first by the
--  6-tile star patch (Bridge/EnrichedStarObs.agda) and then
--  generically by Bridge/GenericBridge.agda (GenericEnriched),
--  which handles all twelve patch instances in the repository.
--
--  Reference:
--    docs/formal/02-foundations.md §5         (the Univalence axiom)
--    docs/formal/03-holographic-bridge.md §3  (enriched equivalence)
--    docs/instances/tree-pilot.md §10         (what tree does NOT exercise)
--    Historical: docs/historical/development-docs/08-tree-instance.md §9.5
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Type families extracting the underlying observable type from
--  a common source specification.  For the tree pilot, both sides
--  produce  Region → ℚ≥0 .
-- ────────────────────────────────────────────────────────────────

Obs∂-Ty : TreeSpec → Type₀
Obs∂-Ty _ = Region → ℚ≥0

ObsBulk-Ty : TreeSpec → Type₀
ObsBulk-Ty _ = Region → ℚ≥0

-- ────────────────────────────────────────────────────────────────
--  tree-type-equiv — The type-level equivalence
-- ────────────────────────────────────────────────────────────────
--
--  Since both type families produce the same type, the equivalence
--  is the identity equivalence on  Region → ℚ≥0 .  In the
--  enriched star instance (Bridge/EnrichedStarObs.agda) and the
--  generic bridge (Bridge/GenericBridge.agda), this equivalence
--  is genuinely nontrivial: the boundary and bulk enriched types
--  reference different specification functions, making the
--  equivalence carry the content of the discrete RT correspondence
--  through the Glue type.
-- ────────────────────────────────────────────────────────────────

tree-type-equiv : Obs∂-Ty treeSpec ≃ ObsBulk-Ty treeSpec
tree-type-equiv = idEquiv (Region → ℚ≥0)

-- ────────────────────────────────────────────────────────────────
--  tree-ua-path — The Univalence path between observable types
-- ────────────────────────────────────────────────────────────────
--
--  Applying  ua  to the identity equivalence yields a path in the
--  universe  Type₀  from  Obs∂-Ty treeSpec  to  ObsBulk-Ty treeSpec .
--  Because  idEquiv  is the trivial equivalence, this path is
--  propositionally (though not judgmentally) equal to  refl ,
--  as witnessed by  uaIdEquiv  below.
-- ────────────────────────────────────────────────────────────────

tree-ua-path : Obs∂-Ty treeSpec ≡ ObsBulk-Ty treeSpec
tree-ua-path = ua tree-type-equiv

-- ────────────────────────────────────────────────────────────────
--  tree-ua-trivial — The ua path is propositionally refl
-- ────────────────────────────────────────────────────────────────
--
--  The cubical library provides  uaIdEquiv : ua (idEquiv A) ≡ refl .
--  This confirms that the Univalence path we constructed adds no
--  nontrivial content for the tree pilot, as expected.
-- ────────────────────────────────────────────────────────────────

tree-ua-trivial : tree-ua-path ≡ refl
tree-ua-trivial = uaIdEquiv

-- ────────────────────────────────────────────────────────────────
--  tree-transport-id — Transport is the identity
-- ────────────────────────────────────────────────────────────────
--
--  Transport along  ua (idEquiv A)  sends every element to itself.
--  This follows from  uaβ , which states:
--
--    transport (ua e) x  ≡  equivFun e x
--
--  Since  equivFun (idEquiv A) x  reduces judgmentally to  x ,
--  the result is  transport tree-ua-path f ≡ f .
--
--  Reference:
--    docs/formal/02-foundations.md §5.1  (ua and uaβ in Cubical Agda)
-- ────────────────────────────────────────────────────────────────

tree-transport-id :
  (f : Obs∂-Ty treeSpec) → transport tree-ua-path f ≡ f
tree-transport-id f = uaβ tree-type-equiv f

-- ────────────────────────────────────────────────────────────────
--  tree-transport-obs — End-to-end transport verification
-- ────────────────────────────────────────────────────────────────
--
--  Combines the transport identity with the observable agreement
--  to show that transporting the boundary observable function
--  along the Univalence path yields the bulk observable function:
--
--    transport tree-ua-path (obs (Obs∂ treeSpec))
--      ≡ obs (Obs∂ treeSpec)                         by tree-transport-id
--      ≡ obs (ObsBulk treeSpec)                      by tree-obs-path
--
--  For the tree pilot this is a trivial composition, but it
--  exercises the full pipeline that later instances depend on:
--
--    common source  →  extract views  →  build packages
--      →  construct equivalence  →  apply ua  →  transport
--
--  The analogous proof for the enriched star instance
--  (Bridge/EnrichedStarObs.agda) replaces idEquiv with a genuine
--  equivalence between structurally different enriched types,
--  making the transport a nontrivial verified translator.  The
--  generic bridge (Bridge/GenericBridge.agda) then generalizes
--  this to all twelve patch instances via the PatchData interface.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1       (uaβ computation rule)
--    docs/formal/03-holographic-bridge.md §3  (enriched equivalence)
--    docs/formal/11-generic-bridge.md         (generic bridge pattern)
--    docs/instances/tree-pilot.md §9          (what the tree validates)
-- ────────────────────────────────────────────────────────────────

tree-transport-obs :
  transport tree-ua-path (ObsPackage.obs (Obs∂ treeSpec))
  ≡ ObsPackage.obs (ObsBulk treeSpec)
tree-transport-obs =
  tree-transport-id (ObsPackage.obs (Obs∂ treeSpec)) ∙ tree-obs-path