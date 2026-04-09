{-# OPTIONS --cubical --safe --guardedness #-}

module Common.StarSpec where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Sigma          using (_×_)

open import Util.Scalars

-- ════════════════════════════════════════════════════════════════════
--  Tile — 6 pentagonal tiles of the star patch
-- ════════════════════════════════════════════════════════════════════
--
--  The 6-tile star patch consists of a central pentagon C surrounded
--  by 5 edge-neighbouring pentagons N0..N4.  Each N_i shares exactly
--  one pentagon edge with C.
--
--  Topology (dual graph):
--
--           N4
--            |
--      N3 ── C ── N0
--          / |
--        N2  N1
--
--  This is the simplest connected HaPPY network with a nontrivial
--  central tile.  It supports min-cut analysis with a clean discrete
--  RT correspondence: S_cut(A) = L_min(A) for all contiguous
--  tile-aligned boundary regions.
--
--  Tile counts:
--    Central:     1  (C)
--    Neighbours:  5  (N0..N4)
--    Total:       6
--
--  Boundary legs per tile:
--    C:   5 edges, 5 shared → 0 boundary legs
--    N_i: 5 edges, 1 shared → 4 boundary legs
--  Total boundary legs: 20
--
--  Reference: Pastawski et al. (2015), arXiv:1503.06237
--  Numerical verification: sim/prototyping/01_happy_patch_cuts.py
-- ════════════════════════════════════════════════════════════════════

data Tile : Type₀ where
  C N0 N1 N2 N3 N4 : Tile

-- ════════════════════════════════════════════════════════════════════
--  Bond — 5 internal tile-to-tile bonds (shared pentagon edges)
-- ════════════════════════════════════════════════════════════════════
--
--  Each bond represents a shared pentagon edge between the central
--  tile C and one of its neighbours N_i.  All bonds carry uniform
--  weight 1 in the standard HaPPY code (one unit of entanglement
--  capacity per shared edge).
--
--  Using a dedicated 5-constructor datatype (rather than pairs of
--  tiles quotiented by symmetry) keeps pattern matching readable
--  and avoids quotient overhead, following the same design principle
--  as the tree pilot's Edge type.
-- ════════════════════════════════════════════════════════════════════

data Bond : Type₀ where
  bCN0 bCN1 bCN2 bCN3 bCN4 : Bond

-- Recover the two endpoint tiles of each bond by explicit lookup.
endpoints : Bond → Tile × Tile
endpoints bCN0 = C , N0
endpoints bCN1 = C , N1
endpoints bCN2 = C , N2
endpoints bCN3 = C , N3
endpoints bCN4 = C , N4

-- ════════════════════════════════════════════════════════════════════
--  Region — 10 representative boundary regions
-- ════════════════════════════════════════════════════════════════════
--
--  For the cyclic boundary ordering  N0 , N1 , N2 , N3 , N4  the
--  nonempty proper contiguous tile-aligned intervals comprise:
--
--    5 singletons   (size 1)  :  S = min(1,4) = 1
--    5 adjacent pairs (size 2):  S = min(2,3) = 2
--    5 triples      (size 3)  :  S = min(3,2) = 2
--    5 quadruples   (size 4)  :  S = min(4,1) = 1
--
--  By complement symmetry  S(A) = S(Ā):
--    • triples carry the same min-cut value as their complementary pairs
--    • quadruples carry the same value as their complementary singletons
--
--  The representative region type therefore consists of the 5
--  singletons and 5 adjacent pairs (10 constructors), covering all
--  distinct min-cut values and all rotation-distinct region shapes.
--
--  This explicit 10-constructor type keeps all downstream case
--  splits transparent and avoids any need for subset reasoning or
--  complement computation.
--
--  Numerical verification: all 20 regions verified by
--  sim/prototyping/01_happy_patch_cuts.py (§3.1 of
--  docs/09-happy-instance.md).
-- ════════════════════════════════════════════════════════════════════

data Region : Type₀ where
  regN0   regN1   regN2   regN3   regN4   : Region
  regN0N1 regN1N2 regN2N3 regN3N4 regN4N0 : Region

-- ════════════════════════════════════════════════════════════════════
--  StarSpec — Common source specification for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  A single term  c : StarSpec  encodes the full star instance:
--  tiling topology (implicit in the Bond type), cyclic boundary
--  ordering of the 5 neighbour tiles, and bond weights.
--
--  Downstream modules extract two views:
--
--    π∂    : StarSpec → BoundaryView   (Boundary/StarCut.agda)
--    πbulk : StarSpec → BulkView       (Bulk/StarChain.agda)
--
--  and from those views, observable packages are constructed in
--  Bridge/StarObs.agda.
--
--  The record is intentionally specialized to the 6-tile star,
--  following the design principle from the tree pilot (§4.3 of
--  docs/08-tree-instance.md): do not over-generalize the source
--  specification before the bridge architecture has been validated
--  on this instance.
-- ════════════════════════════════════════════════════════════════════

record StarSpec : Type₀ where
  field
    boundaryOrder : Tile × Tile × Tile × Tile × Tile
    bondWeight    : Bond → ℚ≥0

-- ════════════════════════════════════════════════════════════════════
--  starSpec — The canonical star instance
-- ════════════════════════════════════════════════════════════════════
--
--  Bond weights:
--    C–N0 = 1    C–N1 = 1    C–N2 = 1    C–N3 = 1    C–N4 = 1
--
--  All bonds have uniform weight 1, matching the standard HaPPY code
--  where each shared pentagon edge carries one unit of entanglement
--  capacity.
--
--  The weight function is factored out as starWeight so that both
--  π∂ and πbulk share the same definitional term.  This ensures
--  that the scalar constants flowing into S-cut (boundary) and
--  L-min (bulk) have identical normal forms, enabling the refl
--  proofs in star-pointwise (Bridge/StarObs.agda).
--
--  The constants 1q are imported from Util.Scalars (where 1q = 1
--  as a natural number).  They must NOT be reconstructed
--  independently on each side — identical normal forms are required
--  for the refl proofs of pointwise observable agreement (§15.5 of
--  docs/09-happy-instance.md).
-- ════════════════════════════════════════════════════════════════════

starWeight : Bond → ℚ≥0
starWeight bCN0 = 1q
starWeight bCN1 = 1q
starWeight bCN2 = 1q
starWeight bCN3 = 1q
starWeight bCN4 = 1q

starSpec : StarSpec
starSpec .StarSpec.boundaryOrder = N0 , N1 , N2 , N3 , N4
starSpec .StarSpec.bondWeight    = starWeight