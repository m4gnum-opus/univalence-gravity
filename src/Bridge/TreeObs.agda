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
--  The minimal observable-package record  ObsPackage  is now defined
--  in  Common.ObsPackage  so that all instances (Tree, Star, and
--  future HaPPY-derived patches) import it from a single canonical
--  location, without any cross-dependency between bridge modules.
--
--  The region index is a parameter rather than a stored field to
--  keep  ObsPackage Region  in Type₀ (see §8.1 of
--  docs/08-tree-instance.md).
--
--  For the tree pilot the only field is the observable function
--  obs : R → ℚ≥0.  Proof-carrying fields (subadditivity,
--  monotonicity witnesses, etc.) are intentionally omitted in this
--  first pass — they should be added only after the minimal bridge
--  succeeds, and any such additions should be proposition-valued
--  (see §11.2 of docs/08-tree-instance.md).
--
--  Because the record has a single field, package equality reduces
--  directly to observable-function equality via a record path
--  whose sole component is the obs-field path.
--  See §8.1 of docs/08-tree-instance.md and §16 of
--  docs/09-happy-instance.md for the design rationale.
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
--       forms on both sides are judgmentally identical (§11.5 of
--       docs/08-tree-instance.md).
--
--  This proof is the content of the discrete Ryu–Takayanagi
--  correspondence for the tree instance: boundary entanglement
--  (min-cut) equals bulk geometry (minimal chain length) on every
--  admissible region.
--
--  Mathematical justification per region (see §7 of
--  docs/08-tree-instance.md):
--
--    regL₁    :  S-cut = 1  (cut {L₁–A})      =  L-min = 1  (chain {L₁–A})
--    regL₂    :  S-cut = 1  (cut {L₂–A})      =  L-min = 1  (chain {L₂–A})
--    regR₁    :  S-cut = 1  (cut {B–R₁})      =  L-min = 1  (chain {B–R₁})
--    regR₂    :  S-cut = 1  (cut {B–R₂})      =  L-min = 1  (chain {B–R₂})
--    regL₁L₂  :  S-cut = 2  (cut {A–Root})    =  L-min = 2  (chain {A–Root})
--    regL₂R₁  :  S-cut = 2  (cut {L₂–A,B–R₁})=  L-min = 2  (chain {L₂–A,B–R₁})
--    regR₁R₂  :  S-cut = 2  (cut {Root–B})    =  L-min = 2  (chain {Root–B})
--    regR₂L₁  :  S-cut = 2  (cut {L₁–A,B–R₂})=  L-min = 2  (chain {L₁–A,B–R₂})
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