{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.StarMonotonicity where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ)

open import Util.Scalars
open import Common.StarSpec
open import Bulk.StarChain

-- ════════════════════════════════════════════════════════════════════
--  Monotonicity of the Bulk Minimal-Chain Functional
--  for the 6-Tile Star Patch
-- ════════════════════════════════════════════════════════════════════
--
--  This module proves that the bulk minimal separating-chain length
--  functional  L-min  is monotone under contiguous subregion
--  inclusion on the 10 representative boundary regions of the
--  6-tile star.
--
--  The min-cut / minimal-chain values on the 6-tile star are:
--
--    Singletons (regN0 .. regN4):    L = 1   (sever 1 bond)
--    Adjacent pairs (regN0N1 .. regN4N0):  L = 2   (sever 2 bonds)
--
--  Monotonicity under subregion inclusion:
--
--    If r₁ ⊆ r₂ (as contiguous tile-aligned boundary arcs),
--    then  L-min r₁ ≤ L-min r₂.
--
--  On the 10-region representative type, the only non-trivial
--  subregion inclusions are singleton ⊆ adjacent pair:
--
--    {N_i} ⊆ {N_i, N_{i+1}}   and   {N_i} ⊆ {N_{i-1}, N_i}
--
--  Each such inclusion gives  1 ≤ 2 ,  witnessed by  (1 , refl) .
--
--  Note on scope.  Full monotonicity on the 20-region type (which
--  includes triples and quadruples) FAILS for size-4 regions:
--
--    {N₀,N₁} ⊆ {N₀,N₁,N₂,N₃}  but  L(pair) = 2  >  1 = L(quad)
--
--  This is because  L(k tiles) = min(k, 5 − k)  decreases once a
--  region exceeds half the boundary.  The 10-region representative
--  type restricts to regions of size ≤ 2 (at most half the 5-tile
--  cycle), where monotonicity holds cleanly.  This restriction is
--  natural: the representative type was designed to cover all
--  distinct min-cut values without redundancy from complement
--  symmetry  S(A) = S(Ā)  (see §6.3 of docs/09-happy-instance.md).
--
--  Purpose in the project.  This module contributes to:
--
--    • Theorem 2 (§3.0 of docs/03-architecture.md):  structural
--      property of the entropy functional.  Together with
--      Boundary/StarSubadditivity.agda, this establishes both
--      subadditivity (boundary side) and monotonicity (bulk side)
--      for the 6-tile star instance.
--
--    • Phase 3C enriched-package equivalence (§12.3 of
--      docs/09-happy-instance.md):  the monotonicity witness
--      becomes a proof-carrying field in an enriched bulk
--      observable package  BulkObs , making the type-level
--      equivalence between  BdyObs  (with subadditivity) and
--      BulkObs  (with monotonicity) genuinely nontrivial.
--      Transport along the resulting  ua  path would produce a
--      verified translator between boundary and bulk observable
--      bundles — the "compilation step" of Phase 3C.
--
--  Mathematical reference:
--    §3.1, §10.1  of docs/09-happy-instance.md  (numerical data)
--    §12.1, §12.3 of docs/09-happy-instance.md  (proof obligations)
--    sim/prototyping/01_happy_patch_cuts.py      (Python prototype)
--
--  Scalar infrastructure:
--    _≤ℚ_ : ℚ≥0 → ℚ≥0 → Type₀
--    m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)
--
--    from Util/Scalars.agda.  Because  _+_  on ℕ computes by
--    recursion on the first argument, the witness  (1 , refl)
--    for  1 ≤ 2  type-checks judgmentally:  1 + 1 = 2 .
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  L-star — Shorthand for the instantiated bulk observable
-- ════════════════════════════════════════════════════════════════════
--
--  The bulk minimal-chain functional instantiated at the canonical
--  star specification.  Defined as a shorthand so that the
--  monotonicity statement does not carry the  (πbulk starSpec)
--  argument through every clause.
--
--  By computation:
--    L-star regN0   = 1q     L-star regN0N1 = 2q
--    L-star regN1   = 1q     L-star regN1N2 = 2q
--    L-star regN2   = 1q     L-star regN2N3 = 2q
--    L-star regN3   = 1q     L-star regN3N4 = 2q
--    L-star regN4   = 1q     L-star regN4N0 = 2q
-- ════════════════════════════════════════════════════════════════════

L-star : Region → ℚ≥0
L-star = L-min (πbulk starSpec)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Regression tests — L-star values
-- ════════════════════════════════════════════════════════════════════
--
--  Verify that L-star reduces to the expected canonical constants.
--  These hold by refl because L-min pattern-matches on the region
--  argument (ignoring the BulkView) and returns 1q or 2q from
--  Util.Scalars.
-- ════════════════════════════════════════════════════════════════════

private
  check-N0   : L-star regN0   ≡ 1q
  check-N0   = refl

  check-N2   : L-star regN2   ≡ 1q
  check-N2   = refl

  check-N0N1 : L-star regN0N1 ≡ 2q
  check-N0N1 = refl

  check-N3N4 : L-star regN3N4 ≡ 2q
  check-N3N4 = refl


-- ════════════════════════════════════════════════════════════════════
--  §3.  _⊆R_ — Subregion inclusion relation
-- ════════════════════════════════════════════════════════════════════
--
--  A witness  p : r₁ ⊆R r₂  asserts that the contiguous boundary
--  arc  r₁  is a proper contiguous sub-arc of  r₂  among the 10
--  representative regions.
--
--  The only proper contiguous inclusions among the representatives
--  (5 singletons + 5 adjacent pairs) are the 10 singleton-in-pair
--  relationships:  each singleton  {N_i}  is contained in exactly
--  two adjacent pairs,  {N_{i-1}, N_i}  and  {N_i, N_{i+1}} .
--
--  Constructor naming:  sub-Ni∈NjNk  where  {N_i} ⊆ {N_j, N_k} .
--
--  This relation exhaustively enumerates all valid proper subregion
--  inclusions on the representative type.  Reflexive inclusion
--  (r ⊆R r) is omitted because every such case is trivially
--  monotone (L-star r ≤ℚ L-star r  by  (0 , refl)) and adds no
--  mathematical content.
--
--  Pair-in-pair inclusions do not exist among the representatives
--  because no representative pair is a proper contiguous sub-arc
--  of another representative pair.
-- ════════════════════════════════════════════════════════════════════

data _⊆R_ : Region → Region → Type₀ where

  -- ── N0 is contained in its two adjacent pairs ────────────────
  sub-N0∈N4N0 : regN0 ⊆R regN4N0
  sub-N0∈N0N1 : regN0 ⊆R regN0N1

  -- ── N1 is contained in its two adjacent pairs ────────────────
  sub-N1∈N0N1 : regN1 ⊆R regN0N1
  sub-N1∈N1N2 : regN1 ⊆R regN1N2

  -- ── N2 is contained in its two adjacent pairs ────────────────
  sub-N2∈N1N2 : regN2 ⊆R regN1N2
  sub-N2∈N2N3 : regN2 ⊆R regN2N3

  -- ── N3 is contained in its two adjacent pairs ────────────────
  sub-N3∈N2N3 : regN3 ⊆R regN2N3
  sub-N3∈N3N4 : regN3 ⊆R regN3N4

  -- ── N4 is contained in its two adjacent pairs ────────────────
  sub-N4∈N3N4 : regN4 ⊆R regN3N4
  sub-N4∈N4N0 : regN4 ⊆R regN4N0


-- ════════════════════════════════════════════════════════════════════
--  §4.  monotonicity — L-star is monotone under ⊆R
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Bulk Monotonicity for the 6-tile star).
--
--  For every subregion inclusion  r₁ ⊆R r₂  among the 10
--  representative boundary regions:
--
--      L-star r₁  ≤ℚ  L-star r₂
--
--  All 10 cases reduce to the single concrete inequality  1 ≤ 2 ,
--  witnessed by  (1 , refl)  because  1 + 1 ≡ 2  judgmentally.
--
--  ┌──────────────────────────────────────────────────────────────┐
--  │  Inclusion           │  LHS    │  RHS    │  Witness         │
--  ├──────────────────────┼─────────┼─────────┼──────────────────┤
--  │  {N₀} ⊆ {N₄,N₀}    │  1      │  2      │  (1 , refl)     │
--  │  {N₀} ⊆ {N₀,N₁}    │  1      │  2      │  (1 , refl)     │
--  │  {N₁} ⊆ {N₀,N₁}    │  1      │  2      │  (1 , refl)     │
--  │  {N₁} ⊆ {N₁,N₂}    │  1      │  2      │  (1 , refl)     │
--  │  {N₂} ⊆ {N₁,N₂}    │  1      │  2      │  (1 , refl)     │
--  │  {N₂} ⊆ {N₂,N₃}    │  1      │  2      │  (1 , refl)     │
--  │  {N₃} ⊆ {N₂,N₃}    │  1      │  2      │  (1 , refl)     │
--  │  {N₃} ⊆ {N₃,N₄}    │  1      │  2      │  (1 , refl)     │
--  │  {N₄} ⊆ {N₃,N₄}    │  1      │  2      │  (1 , refl)     │
--  │  {N₄} ⊆ {N₄,N₀}    │  1      │  2      │  (1 , refl)     │
--  └──────────────────────────────────────────────────────────────┘
--
--  Geometric interpretation:  severing the bond  C–N_i  (cost 1)
--  disconnects the singleton  {N_i}  from the rest of the star.
--  Severing bonds  C–N_i  and  C–N_{i+1}  (cost 2) disconnects
--  the pair  {N_i, N_{i+1}} .  Because the pair's separating
--  chain includes the singleton's separating chain (plus one
--  additional bond), the cost is strictly larger.
--
--  This proof, together with  Boundary.StarSubadditivity.subadditivity ,
--  completes the structural-property slate for the 6-tile star:
--
--    Boundary:  subadditivity   S(A ∪ B) ≤ S(A) + S(B)
--    Bulk:      monotonicity    r₁ ⊆ r₂  →  L(r₁) ≤ L(r₂)
--
--  Numerical verification:
--    sim/prototyping/01_happy_patch_cuts.py
--    §3.1 of docs/09-happy-instance.md:
--      "Geodesic bound: S(A) ≤ internal geodesic length  ✓ (20/20)"
--      "Geodesic equality: S(A) = internal geodesic length for all
--       20 regions  ✓"
-- ════════════════════════════════════════════════════════════════════

monotonicity :
  ∀ {r₁ r₂ : Region}
  → r₁ ⊆R r₂
  → L-star r₁ ≤ℚ L-star r₂

-- ── N0 inclusions:  L(N0) = 1  ≤  2 = L(pair) ─────────────────
monotonicity sub-N0∈N4N0 = 1 , refl     -- 1 + 1 ≡ 2
monotonicity sub-N0∈N0N1 = 1 , refl

-- ── N1 inclusions ──────────────────────────────────────────────
monotonicity sub-N1∈N0N1 = 1 , refl
monotonicity sub-N1∈N1N2 = 1 , refl

-- ── N2 inclusions ──────────────────────────────────────────────
monotonicity sub-N2∈N1N2 = 1 , refl
monotonicity sub-N2∈N2N3 = 1 , refl

-- ── N3 inclusions ──────────────────────────────────────────────
monotonicity sub-N3∈N2N3 = 1 , refl
monotonicity sub-N3∈N3N4 = 1 , refl

-- ── N4 inclusions ──────────────────────────────────────────────
monotonicity sub-N4∈N3N4 = 1 , refl
monotonicity sub-N4∈N4N0 = 1 , refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Concrete inequality witnesses  (regression tests)
-- ════════════════════════════════════════════════════════════════════
--
--  These isolate the single concrete inequality used in all 10
--  monotonicity cases.  They serve as regression tests: if a future
--  scalar upgrade breaks the judgmental reduction  1 + 1 ≡ 2 ,
--  this lemma will fail before the full monotonicity proof does,
--  giving a more informative error message.
-- ════════════════════════════════════════════════════════════════════

-- 1 ≤ 2  :  the only inequality needed for singleton ⊆ pair
≤-1≤2 : 1q ≤ℚ 2q
≤-1≤2 = 1 , refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Boundary-side agreement
-- ════════════════════════════════════════════════════════════════════
--
--  Because  S-cut  and  L-min  agree on all 10 representative
--  regions (star-pointwise in Bridge/StarObs.agda), monotonicity
--  of  L-min  immediately implies monotonicity of  S-cut  on the
--  same regions.  This is not a separate proof obligation: it
--  follows from the pointwise agreement path composed with the
--  monotonicity witnesses.
--
--  In the enriched-package architecture (§12.3 of
--  docs/09-happy-instance.md), this observation means that the
--  forward map of the type equivalence can transport a
--  subadditivity witness to a monotonicity witness by:
--
--    1.  Using the pointwise agreement to rewrite  S-cut  as  L-min
--        in all inequality statements.
--    2.  Deriving monotonicity from the rewritten subadditivity
--        witnesses.
--
--  The reverse map would derive subadditivity from monotonicity.
--  Both directions require the functional agreement as a
--  connecting lemma — which is exactly what  star-obs-path
--  (in Bridge/StarEquiv.agda) provides.
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §7.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for downstream modules:
--
--    L-star       : Region → ℚ≥0
--                   (shorthand for L-min (πbulk starSpec))
--    _⊆R_        : Region → Region → Type₀
--                   (subregion inclusion on representatives)
--    monotonicity : r₁ ⊆R r₂ → L-star r₁ ≤ℚ L-star r₂
--                   (monotonicity of the bulk functional)
--
--  Relationship to other modules:
--
--    Boundary/StarSubadditivity.agda
--      — proves subadditivity of S-star on the full 20-region type
--      — uses the same _≤ℚ_ and (k , refl) proof pattern
--      — serves as the boundary-side enrichment for Phase 3C
--
--    Bridge/StarObs.agda
--      — proves star-pointwise: S-cut ≡ L-min on all 10 regions
--      — the connecting lemma between boundary and bulk sides
--
--    Bridge/StarEquiv.agda
--      — currently uses idEquiv for the trivial package equivalence
--      — future enriched-package equivalence will depend on both
--        subadditivity (boundary) and monotonicity (bulk) as
--        proof fields in the enriched record types
--
--  Design decisions:
--
--    1.  The subregion relation _⊆R_ is defined on the 10-region
--        representative type (Common/StarSpec.Region), not on the
--        20-region StarRegion (Boundary/StarSubadditivity.StarRegion).
--        This is because monotonicity on representatives (size ≤ 2)
--        holds cleanly, while it fails on the full type for regions
--        exceeding half the boundary (size > 2).  The restriction
--        is not a limitation: it matches the representative type
--        used in the bridge modules (StarObs, StarEquiv).
--
--    2.  Reflexive inclusion (r ⊆R r) is omitted.  Every such case
--        is trivially monotone by (0 , refl) and adds no geometric
--        content.  If needed for downstream proofs, a reflexive
--        closure can be added as a wrapper datatype.
--
--    3.  All scalar constants (1q, 2q) are imported from
--        Util/Scalars.agda, never reconstructed locally.  This
--        maintains the judgmental stability guarantee required for
--        refl-based proofs (same principle as §11.5 of
--        docs/08-tree-instance.md and §15.5 of
--        docs/09-happy-instance.md).
--
--    4.  The module follows the same proof-engineering pattern as
--        Boundary/StarSubadditivity.agda: an inductive relation
--        encoding the structural property (here _⊆R_, there _∪_≡_),
--        proved by exhaustive pattern match with concrete (k , refl)
--        witnesses.  This uniformity makes both sides of the
--        enriched-package equivalence structurally parallel.
--
--  Next steps:
--
--    • Define enriched record types  BdyObs  and  BulkObs  with
--      proof-carrying fields (subadditivity and monotonicity
--      respectively).
--    • Construct the forward map  f : BdyObs → BulkObs  using
--      star-obs-path to rewrite S-cut as L-min and derive
--      monotonicity from the rewritten subadditivity.
--    • Construct the inverse map  g : BulkObs → BdyObs  using
--      the symmetric rewriting.
--    • Prove round-trip homotopies  g ∘ f ~ id  and  f ∘ g ~ id .
--    • Apply  ua  to obtain the nontrivial Univalence path.
--    • Verify that  transport  along this path carries the
--      boundary observable bundle to the bulk observable bundle.
--    • This completes Phase 3C and satisfies Milestones 3–4 of
--      §6.9 of docs/06-challenges.md.
-- ════════════════════════════════════════════════════════════════════