{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.StarObs where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCut
open import Bulk.StarChain

-- ════════════════════════════════════════════════════════════════════
--  ObsPackage — imported from Common.ObsPackage
-- ════════════════════════════════════════════════════════════════════
--
--  The minimal observable-package record  ObsPackage  is defined in
--  Bridge.TreeObs and parameterized by a region index type  R .
--  It has a single field  obs : R → ℚ≥0 .
--
--  We import it here via a selective  using  clause so that the
--  star bridge shares the same packaging interface as the tree
--  bridge, without pulling in tree-specific definitions (TreeSpec,
--  tree-pointwise, etc.) into this module's namespace.
--
--  A future refactor should factor  ObsPackage  into a shared
--  module (e.g. Common/ObsPackage.agda) so that neither bridge
--  module depends on the other.  For now, the selective import
--  avoids duplication and satisfies the design constraint from
--  §15.1 of docs/09-happy-instance.md: the tree proofs remain
--  untouched, and the star modules are purely additive.
--  The minimal observable-package record  ObsPackage  is defined
--  in  Common.ObsPackage  and parameterized by a region index
--  type  R .  It has a single field  obs : R → ℚ≥0 .
--
--  Importing from the shared  Common.ObsPackage  module ensures
--  that neither bridge module depends on the other, satisfying
--  the design constraint from §15.1 of docs/09-happy-instance.md.
-- ════════════════════════════════════════════════════════════════════

open import Common.ObsPackage

-- ════════════════════════════════════════════════════════════════════
--  Obs∂ — Boundary observable package for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  Constructs the boundary-side observable package for a given
--  common source specification.  The observable function is the
--  min-cut entropy functional  S-cut  applied to the boundary
--  view extracted by  π∂ .
--
--  Definitional unfolding for the canonical instance:
--    Obs∂ starSpec .obs r  ≡  S-cut (π∂ starSpec) r
--
--  Because  S-cut  ignores its  BoundaryView  argument and returns
--  canonical constants from  Util.Scalars , this unfolds further to
--  1q  or  2q  depending on the region  r .
-- ════════════════════════════════════════════════════════════════════

Obs∂ : StarSpec → ObsPackage Region
Obs∂ c .ObsPackage.obs = S-cut (π∂ c)

-- ════════════════════════════════════════════════════════════════════
--  ObsBulk — Bulk observable package for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  Constructs the bulk-side observable package for a given common
--  source specification.  The observable function is the minimal
--  separating-chain length functional  L-min  applied to the bulk
--  view extracted by  πbulk .
--
--  Definitional unfolding for the canonical instance:
--    ObsBulk starSpec .obs r  ≡  L-min (πbulk starSpec) r
--
--  Because  L-min  ignores its  BulkView  argument and returns
--  canonical constants from  Util.Scalars , this unfolds further to
--  1q  or  2q  depending on the region  r .
-- ════════════════════════════════════════════════════════════════════

ObsBulk : StarSpec → ObsPackage Region
ObsBulk c .ObsPackage.obs = L-min (πbulk c)

-- ════════════════════════════════════════════════════════════════════
--  star-pointwise — Pointwise observable agreement
-- ════════════════════════════════════════════════════════════════════
--
--  The central proof for the 6-tile star instance.
--
--  For every representative boundary region  r : Region , the
--  boundary min-cut value equals the bulk minimal-chain value:
--
--    S-cut (π∂ starSpec) r  ≡  L-min (πbulk starSpec) r
--
--  Proof method: complete pattern match on  r .  Each case holds
--  by  refl  because:
--
--    1. S-cut  ignores its  BoundaryView  argument and returns a
--       canonical constant from  Util.Scalars  (1q or 2q).
--
--    2. L-min  ignores its  BulkView  argument and returns the
--       same canonical constant from  Util.Scalars .
--
--    3. The constants are defined once in  Util.Scalars  and
--       imported by both  Boundary.StarCut  and  Bulk.StarChain ,
--       so the normal forms on both sides are judgmentally
--       identical (§15.5 of docs/09-happy-instance.md).
--
--  This proof is the content of the discrete Ryu–Takayanagi
--  correspondence for the 6-tile star: boundary entanglement
--  (min-cut) equals bulk geometry (minimal chain length) on every
--  admissible region.
--
--  Mathematical justification per region (see §10.1 of
--  docs/09-happy-instance.md):
--
--    regN0    :  S = 1  (cut {C–N0})         =  L = 1  (chain {C–N0})
--    regN1    :  S = 1  (cut {C–N1})         =  L = 1  (chain {C–N1})
--    regN2    :  S = 1  (cut {C–N2})         =  L = 1  (chain {C–N2})
--    regN3    :  S = 1  (cut {C–N3})         =  L = 1  (chain {C–N3})
--    regN4    :  S = 1  (cut {C–N4})         =  L = 1  (chain {C–N4})
--    regN0N1  :  S = 2  (cut {C–N0, C–N1})   =  L = 2  (chain {C–N0, C–N1})
--    regN1N2  :  S = 2  (cut {C–N1, C–N2})   =  L = 2  (chain {C–N1, C–N2})
--    regN2N3  :  S = 2  (cut {C–N2, C–N3})   =  L = 2  (chain {C–N2, C–N3})
--    regN3N4  :  S = 2  (cut {C–N3, C–N4})   =  L = 2  (chain {C–N3, C–N4})
--    regN4N0  :  S = 2  (cut {C–N4, C–N0})   =  L = 2  (chain {C–N4, C–N0})
--
--  All 10 values verified numerically by
--  sim/prototyping/01_happy_patch_cuts.py (§3.1 of
--  docs/09-happy-instance.md): geodesic equality  S = L  holds for
--  all 20 regions (including triples and quadruples by complement
--  symmetry  S(A) = S(Ā) ).
-- ════════════════════════════════════════════════════════════════════

star-pointwise :
  (r : Region) →
  S-cut (π∂ starSpec) r ≡ L-min (πbulk starSpec) r
star-pointwise regN0   = refl
star-pointwise regN1   = refl
star-pointwise regN2   = refl
star-pointwise regN3   = refl
star-pointwise regN4   = refl
star-pointwise regN0N1 = refl
star-pointwise regN1N2 = refl
star-pointwise regN2N3 = refl
star-pointwise regN3N4 = refl
star-pointwise regN4N0 = refl