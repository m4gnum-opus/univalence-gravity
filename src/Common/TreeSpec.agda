{-# OPTIONS --cubical --safe --guardedness #-}

module Common.TreeSpec where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Sigma          using (_×_)

open import Util.Scalars

-- ════════════════════════════════════════════════════════════════════
--  Vertex — 7 vertices of the weighted binary tree
-- ════════════════════════════════════════════════════════════════════
--
--  Boundary sites: L₁, L₂, R₁, R₂
--  Interior nodes: A, B, Root
--
--  Topology:
--
--    L₁ ——(1)—— A ——(2)—— Root ——(2)—— B ——(1)—— R₁
--                |                        |
--    L₂ ——(1)——+                        +——(1)—— R₂
--
-- ════════════════════════════════════════════════════════════════════

data Vertex : Type₀ where
  L₁ L₂ R₁ R₂ A B Root : Vertex

-- ════════════════════════════════════════════════════════════════════
--  Edge — 6 undirected edges (explicit enumeration)
-- ════════════════════════════════════════════════════════════════════
--
--  Using a dedicated datatype with one constructor per link avoids
--  having to quotient ordered vertex-pairs by symmetry.
-- ════════════════════════════════════════════════════════════════════

data Edge : Type₀ where
  eL₁A eL₂A eARoot eRootB eBR₁ eBR₂ : Edge

-- Recover the two endpoints of each edge by explicit lookup.
endpoints : Edge → Vertex × Vertex
endpoints eL₁A    = L₁    , A
endpoints eL₂A    = L₂    , A
endpoints eARoot  = A     , Root
endpoints eRootB  = Root  , B
endpoints eBR₁    = B     , R₁
endpoints eBR₂    = B     , R₂

-- ════════════════════════════════════════════════════════════════════
--  Region — 8 representative boundary regions
-- ════════════════════════════════════════════════════════════════════
--
--  For the cyclic boundary ordering  L₁ , L₂ , R₁ , R₂  the
--  nonempty proper contiguous intervals comprise 4 singletons,
--  4 adjacent pairs, and 4 triples.  Triples are omitted because
--  each is the complement of a singleton and carries the same
--  min-cut / minimal-chain value in this symmetric tree.
--
--  This explicit 8-constructor type keeps all downstream case
--  splits transparent and avoids any need for subset reasoning.
-- ════════════════════════════════════════════════════════════════════

data Region : Type₀ where
  regL₁   regL₂   regR₁   regR₂   : Region
  regL₁L₂ regL₂R₁ regR₁R₂ regR₂L₁ : Region

-- ════════════════════════════════════════════════════════════════════
--  TreeSpec — Common source specification for the tree pilot
-- ════════════════════════════════════════════════════════════════════
--
--  A single term  c : TreeSpec  encodes the full tree instance:
--  tiling topology (implicit in the Edge type), boundary ordering,
--  and edge weights.  Downstream modules extract two views:
--
--    π∂    : TreeSpec → BoundaryView   (Boundary/TreeCut.agda)
--    πbulk : TreeSpec → BulkView       (Bulk/TreeChain.agda)
--
--  and from those views, observable packages are constructed in
--  Bridge/TreeObs.agda.
-- ════════════════════════════════════════════════════════════════════

record TreeSpec : Type₀ where
  field
    boundaryOrder : Vertex × Vertex × Vertex × Vertex
    edgeWeight    : Edge → ℚ≥0

-- ════════════════════════════════════════════════════════════════════
--  treeSpec — The canonical tree instance
-- ════════════════════════════════════════════════════════════════════
--
--  Edge weights:
--    L₁–A  = 1    L₂–A  = 1
--    A–Root = 2    Root–B = 2
--    B–R₁  = 1    B–R₂  = 1
--
--  The weight function is factored out as treeWeight so that both
--  π∂ and πbulk share the same definitional term.  This ensures
--  that the scalar constants flowing into S-cut (boundary) and
--  L-min (bulk) have identical normal forms, enabling the refl
--  proofs in tree-pointwise (Bridge/TreeObs.agda).
-- ════════════════════════════════════════════════════════════════════

treeWeight : Edge → ℚ≥0
treeWeight eL₁A   = 1q
treeWeight eL₂A   = 1q
treeWeight eARoot  = 2q
treeWeight eRootB  = 2q
treeWeight eBR₁    = 1q
treeWeight eBR₂    = 1q

treeSpec : TreeSpec
treeSpec .TreeSpec.boundaryOrder = L₁ , L₂ , R₁ , R₂
treeSpec .TreeSpec.edgeWeight    = treeWeight