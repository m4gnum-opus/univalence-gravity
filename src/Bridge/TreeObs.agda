{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.TreeObs where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.TreeSpec
open import Boundary.TreeCut
open import Bulk.TreeChain

-- ════════════════════════════════════════════════════════════════════
--  ObsPackage — imported from Common.ObsPackage
-- ════════════════════════════════════════════════════════════════════
--
--  A single-field record parameterized by a region index type R.
--  The minimal observable-package record  ObsPackage  is defined
--  in  Common.ObsPackage  so that all instances (Tree, Star, and
--  all subsequent patches) import it from a single canonical
--  location, without any cross-dependency between bridge modules.
--
--  The region index is a parameter rather than a stored field to
--  keep  ObsPackage Region  in Type₀.
--
--  For the tree pilot the only field is the observable function
--  obs : R → ℚ≥0.  Proof-carrying fields (subadditivity,
--  monotonicity witnesses, etc.) are intentionally omitted from
--  this minimal record — they are added in the enriched types
--  FullBdy / FullBulk  defined in Bridge/FullEnrichedStarObs.agda,
--  keeping the minimal packaging separate from the structural
--  property layer.  Any such additions should be proposition-valued
--  to enable round-trip homotopies via isProp.
--
--  Because the record has a single field, package equality reduces
--  directly to observable-function equality via a record path
--  whose sole component is the obs-field path.  This is exploited
--  in every  *-package-path  definition across the Bridge modules.
--
--  Architectural role:
--    This is a Tier 3 (Bridge Layer) module assembling observable
--    packages from the boundary and bulk views defined in Tier 2.
--    It is the tree pilot's first end-to-end bridge test.
--
--  Reference:
--    docs/instances/tree-pilot.md §5        (observable packages)
--    docs/formal/03-holographic-bridge.md   (observable packages)
--    docs/getting-started/architecture.md   (Bridge Layer)
--    docs/reference/module-index.md         (module description)
-- ════════════════════════════════════════════════════════════════════

open import Common.ObsPackage public

-- ════════════════════════════════════════════════════════════════════
--  Obs∂ — Boundary observable package
-- ════════════════════════════════════════════════════════════════════
--
--  Constructs the boundary-side observable package for a given
--  common source specification.  The observable function is the
--  min-cut entropy functional  S-cut  applied to the boundary
--  view extracted by  π∂.
--
--  Definitional unfolding for the canonical instance:
--    Obs∂ treeSpec .obs r  ≡  S-cut (π∂ treeSpec) r
--
--  Reference:
--    docs/instances/tree-pilot.md §5         (observable packages)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement)
-- ════════════════════════════════════════════════════════════════════

Obs∂ : TreeSpec → ObsPackage Region
Obs∂ c .ObsPackage.obs = S-cut (π∂ c)

-- ════════════════════════════════════════════════════════════════════
--  ObsBulk — Bulk observable package
-- ════════════════════════════════════════════════════════════════════
--
--  Constructs the bulk-side observable package for a given common
--  source specification.  The observable function is the minimal
--  separating-chain length functional  L-min  applied to the bulk
--  view extracted by  πbulk.
--
--  Definitional unfolding for the canonical instance:
--    ObsBulk treeSpec .obs r  ≡  L-min (πbulk treeSpec) r
--
--  Reference:
--    docs/instances/tree-pilot.md §5         (observable packages)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement)
-- ════════════════════════════════════════════════════════════════════

ObsBulk : TreeSpec → ObsPackage Region
ObsBulk c .ObsPackage.obs = L-min (πbulk c)

-- ════════════════════════════════════════════════════════════════════
--  tree-pointwise — Pointwise observable agreement
-- ════════════════════════════════════════════════════════════════════
--
--  The central proof for the tree pilot instance.
--
--  For every representative boundary region r : Region, the
--  boundary min-cut value equals the bulk minimal-chain value:
--
--    S-cut (π∂ treeSpec) r  ≡  L-min (πbulk treeSpec) r
--
--  Proof method: complete pattern match on r.  Each case holds by
--  refl because:
--
--    1. S-cut ignores its BoundaryView argument and returns a
--       canonical constant from Util.Scalars (1q or 2q).
--
--    2. L-min ignores its BulkView argument and returns the same
--       canonical constant from Util.Scalars.
--
--    3. The constants are defined once in Util.Scalars and imported
--       by both Boundary.TreeCut and Bulk.TreeChain, so the normal
--       forms on both sides are judgmentally identical.  This is
--       the shared-constants discipline documented in
--       docs/formal/02-foundations.md §6.3.
--
--  This proof is the content of the discrete Ryu–Takayanagi
--  correspondence for the tree instance: boundary entanglement
--  (min-cut) equals bulk geometry (minimal chain length) on every
--  admissible region.
--
--  The tree pilot is the repository's first bridge calibration
--  object — it validates the full common-source → views →
--  observable packages → pointwise agreement pipeline before any
--  2D or 3D geometry is introduced.  After this proof succeeds,
--  the function path  tree-obs-path = funExt tree-pointwise  and
--  the package path are assembled in Bridge/TreeEquiv.agda, and
--  the generic bridge from Bridge/GenericBridge.agda produces
--  the full BridgeWitness automatically.
--
--  Mathematical justification per region
--  (see docs/instances/tree-pilot.md §4):
--
--    regL₁    :  S-cut = 1  (cut {L₁–A})      =  L-min = 1  (chain {L₁–A})
--    regL₂    :  S-cut = 1  (cut {L₂–A})      =  L-min = 1  (chain {L₂–A})
--    regR₁    :  S-cut = 1  (cut {B–R₁})      =  L-min = 1  (chain {B–R₁})
--    regR₂    :  S-cut = 1  (cut {B–R₂})      =  L-min = 1  (chain {B–R₂})
--    regL₁L₂  :  S-cut = 2  (cut {A–Root})    =  L-min = 2  (chain {A–Root})
--    regL₂R₁  :  S-cut = 2  (cut {L₂–A,B–R₁})=  L-min = 2  (chain {L₂–A,B–R₁})
--    regR₁R₂  :  S-cut = 2  (cut {Root–B})    =  L-min = 2  (chain {Root–B})
--    regR₂L₁  :  S-cut = 2  (cut {L₁–A,B–R₂})=  L-min = 2  (chain {L₁–A,B–R₂})
--
--  Reference:
--    docs/instances/tree-pilot.md §4         (min-cut / observable agreement)
--    docs/instances/tree-pilot.md §6         (bridge construction)
--    docs/formal/02-foundations.md §6.3      (shared-constants discipline)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement path)
--    docs/formal/11-generic-bridge.md        (PatchData interface)
--    docs/reference/module-index.md          (module description)
-- ════════════════════════════════════════════════════════════════════

tree-pointwise :
  (r : Region) →
  S-cut (π∂ treeSpec) r ≡ L-min (πbulk treeSpec) r
tree-pointwise regL₁   = refl
tree-pointwise regL₂   = refl
tree-pointwise regR₁   = refl
tree-pointwise regR₂   = refl
tree-pointwise regL₁L₂ = refl
tree-pointwise regL₂R₁ = refl
tree-pointwise regR₁R₂ = refl
tree-pointwise regR₂L₁ = refl