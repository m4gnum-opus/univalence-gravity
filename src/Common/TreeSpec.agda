{-# OPTIONS --cubical --safe --guardedness #-}

module Common.TreeSpec where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Sigma          using (_×_)

open import Util.Scalars

-- ════════════════════════════════════════════════════════════════════
--  Vertex — 7 vertices of the weighted binary tree
-- ════════════════════════════════════════════════════════════════════
--
--  The tree pilot is the repository's first bridge calibration
--  object — a 1D weighted binary tree with 4 boundary sites
--  (leaves) and 3 interior nodes.  It validates the full
--  common-source → views → observable packages → pointwise
--  agreement → package path pipeline before any 2D or 3D
--  geometry is introduced.
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
--  Architectural role:
--    This is a Tier 1 (Specification Layer) module.  It defines
--    the common source specification consumed by the boundary
--    view (Boundary/TreeCut.agda) and bulk view (Bulk/TreeChain.agda),
--    which produce observable packages assembled in Bridge/TreeObs.agda.
--
--  Reference:
--    docs/instances/tree-pilot.md         (instance data sheet)
--    docs/getting-started/architecture.md (Specification Layer)
--    docs/formal/03-holographic-bridge.md (observable packages)
--    docs/reference/module-index.md       (module description)
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
--  Bridge/TreeObs.agda.  The generic bridge theorem from
--  Bridge/GenericBridge.agda then produces the full enriched
--  type equivalence + Univalence path + verified transport
--  automatically from the resulting PatchData.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement)
--    docs/formal/11-generic-bridge.md        (PatchData interface)
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
--
--  The constants 1q and 2q are imported from Util.Scalars (where
--  1q = 1 and 2q = 2 as natural numbers).  They must NOT be
--  reconstructed independently on each side — identical normal
--  forms are required for the refl proofs of pointwise observable
--  agreement.  This shared-constants discipline is documented in
--  docs/formal/02-foundations.md §6.3.
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