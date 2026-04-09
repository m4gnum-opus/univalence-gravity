{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.GaussBonnet where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat  using (ℕ ; _+_)
open import Cubical.Data.Int  using (ℤ ; pos ; negsuc)

open import Util.Rationals
open import Bulk.PatchComplex
open import Bulk.Curvature

-- ════════════════════════════════════════════════════════════════════
--  Discrete Gauss–Bonnet Theorem for the 11-Tile {5,4} Patch
-- ════════════════════════════════════════════════════════════════════
--
--  This module provides the polished theorem statement and milestone
--  packaging for **Theorem 1** (Discrete Gauss–Bonnet), as defined
--  in §3.0 of docs/03-architecture.md and targeted by Phase 2B.3
--  of docs/05-roadmap.md.
--
--  The theorem asserts that for the 11-tile filled patch K of the
--  {5,4} hyperbolic tiling:
--
--      Σ_v κ(v) = χ(K)
--
--  where κ is the combinatorial curvature function (Option A from
--  assumptions.md) and χ(K) = V − E + F = 30 − 40 + 11 = 1 is
--  the Euler characteristic of the disk-shaped patch.
--
--  The proof is entirely computational: the curvature function
--  κ-class : VClass → ℚ₁₀  and the class counts  vCount : VClass → ℕ
--  are both defined by pattern matching on a 5-constructor datatype,
--  and the weighted sum normalizes judgmentally to  pos 10 = one₁₀
--  (representing 10/10 = 1 in the ℚ₁₀ encoding).  The proof term
--  is  refl .
--
--  Module dependencies:
--
--    Util/Rationals.agda    — ℚ₁₀ = ℤ, arithmetic, named constants
--    Bulk/PatchComplex.agda — VClass, vCount, totalV/E/F, euler-char
--    Bulk/Curvature.agda    — κ-class, κ, totalCurvature,
--                             totalCurvature≡χ
--
--  Mathematical references:
--    §4.1 of docs/09-happy-instance.md  (numerical verification)
--    §13  of docs/09-happy-instance.md  (formalization plan)
--    sim/prototyping/02_happy_patch_curvature.py  (Python prototype)
--
--  Exit criterion (docs/05-roadmap.md, Phase 2B):
--    "The concrete bulk type, discrete curvature, and Gauss–Bonnet
--     theorem type-check.  This satisfies Milestone 1 of §6.9."
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Euler characteristic — ℕ and ℚ₁₀ representations
-- ════════════════════════════════════════════════════════════════════
--
--  The Euler characteristic of the 11-tile filled patch is
--
--      χ(K) = V − E + F = 30 − 40 + 11 = 1
--
--  Since ℕ has no subtraction, PatchComplex states this as the
--  additive identity  V + F = E + χ ,  i.e.  30 + 11 = 40 + 1 = 41.
--
--  In the ℚ₁₀ representation (where the integer n represents the
--  rational n/10), the Euler characteristic χ = 1 is encoded as
--  one₁₀ = pos 10 = 10/10.  The Gauss–Bonnet theorem then states
--  that the curvature sum (also in tenths) equals pos 10.
-- ════════════════════════════════════════════════════════════════════

-- The Euler characteristic as a natural number.
χ-ℕ : ℕ
χ-ℕ = 1

-- ────────────────────────────────────────────────────────────────
--  Euler identity:  V + F = E + χ
--  30 + 11 = 41 = 40 + 1
--
--  Re-exported from PatchComplex with explicit χ naming.
-- ────────────────────────────────────────────────────────────────

χ-euler : totalV + totalF ≡ totalE + χ-ℕ
χ-euler = euler-char

-- ────────────────────────────────────────────────────────────────
--  Euler characteristic in the ℚ₁₀ encoding.
--
--  χ = 1  is encoded as  10/10 = pos 10 = one₁₀ .
--
--  This is the target value of the Gauss–Bonnet sum.
-- ────────────────────────────────────────────────────────────────

χ₁₀ : ℚ₁₀
χ₁₀ = one₁₀

-- ────────────────────────────────────────────────────────────────
--  Encoding consistency:  χ₁₀  faithfully represents  χ-ℕ .
--
--  The ℚ₁₀ encoding of a natural number n is  10 · n  in tenths.
--  For n = 1:  10 ·₁₀ pos 1  reduces to  pos 10 = one₁₀ = χ₁₀ .
-- ────────────────────────────────────────────────────────────────

χ₁₀-encodes-χ : χ₁₀ ≡ 10 ·₁₀ pos χ-ℕ
χ₁₀-encodes-χ = refl


-- ════════════════════════════════════════════════════════════════════
--  §2.  Discrete Gauss–Bonnet theorem  (Theorem 1)
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Discrete Gauss–Bonnet, combinatorial form).
--
--  For the 11-tile filled patch K of the {5,4} hyperbolic tiling
--  with combinatorial curvature  κ : Vertex → ℚ₁₀ :
--
--      Σ_v κ(v)  =  χ(K)
--
--  In the classified ℚ₁₀ representation:
--
--      Σ_{cl ∈ VClass}  vCount(cl) · κ-class(cl)  =  one₁₀
--
--  Expansion (5-class grouping):
--
--    Class       Count   κ (tenths)   Contribution
--    ────────    ─────   ──────────   ────────────
--    vTiling       5       −2            −10
--    vSharedA      5       −1             −5
--    vOuterB       5        2             10
--    vSharedC      5       −1             −5
--    vOuterG      10        2             20
--                 ──                      ──
--                 30                      10  = one₁₀ = χ(K)
--
--  The proof is  refl  because all operations (vCount, κ-class,
--  _·₁₀_, _+₁₀_) compute by structural recursion on closed
--  constructor terms, and the ℤ normalizer reduces the entire
--  expression to  pos 10 .
--
--  This corresponds to Phase 2B.3 of docs/05-roadmap.md and
--  §13 of docs/09-happy-instance.md.  Verified numerically by
--  sim/prototyping/02_happy_patch_curvature.py :
--    Σ κ(v) = (−1) + (−1/2) + 1 + (−1/2) + 2 = 1 = χ(K)  ✓
-- ════════════════════════════════════════════════════════════════════

discrete-gauss-bonnet : totalCurvature ≡ χ₁₀
discrete-gauss-bonnet = totalCurvature≡χ


-- ════════════════════════════════════════════════════════════════════
--  §3.  Interior / boundary curvature decomposition
-- ════════════════════════════════════════════════════════════════════
--
--  The total curvature decomposes into an interior contribution
--  (from the 5 tiling vertices v₀..v₄ of class vTiling) and a
--  boundary contribution (from the 25 boundary vertices of the
--  remaining 4 classes).
--
--  This decomposition makes the geometric structure visible:
--
--    • Interior curvature is strictly negative (−10/10 = −1),
--      confirming the hyperbolic character of the {5,4} tiling.
--      At each interior vertex, 4 regular pentagons meet with a
--      total angle of 4 × 108° = 432° > 360°.
--
--    • Boundary curvature is positive (20/10 = 2), reflecting
--      the turning of the boundary curve around the disk.
--
--    • The sum −1 + 2 = 1 = χ(K) is the topological invariant.
--
--  In the angular (non-combinatorial) formulation, this would
--  correspond to:
--
--      Σ_{int} κ(v)  +  Σ_{∂} τ(v)  =  2π · χ(K)
--
--  where κ(v) = 2π − angle_sum(v) for interior vertices and
--  τ(v) = π − angle_sum(v) for boundary vertices.  The
--  combinatorial formula absorbs the interior/boundary distinction
--  into a single formula, but the decomposition below makes the
--  two contributions explicit.
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Interior curvature:  5 tiling vertices × (−2/10) = −10/10
--
--  This is the contribution from the 5 interior vertices of the
--  {5,4} patch.  Each interior vertex has valence 4 in the tiling
--  (4 pentagons meeting), giving combinatorial curvature −1/5
--  = −2/10 per vertex.
-- ────────────────────────────────────────────────────────────────

interiorCurvature : ℚ₁₀
interiorCurvature = vCount vTiling ·₁₀ κ-class vTiling

-- 5 × (−2) = −10  in tenths
interiorCurvature-val : interiorCurvature ≡ negsuc 9
interiorCurvature-val = refl

-- ────────────────────────────────────────────────────────────────
--  Boundary curvature:  sum over 4 boundary vertex classes
--
--    5 shared-A × (−1)  +  5 outer-B × (+2)
--  + 5 shared-C × (−1)  + 10 outer-G × (+2)
--  = (−5) + 10 + (−5) + 20
--  = 20  in tenths
-- ────────────────────────────────────────────────────────────────

boundaryCurvature : ℚ₁₀
boundaryCurvature =
    vCount vSharedA ·₁₀ κ-class vSharedA
  +₁₀ vCount vOuterB  ·₁₀ κ-class vOuterB
  +₁₀ vCount vSharedC ·₁₀ κ-class vSharedC
  +₁₀ vCount vOuterG  ·₁₀ κ-class vOuterG

-- (−5) + 10 + (−5) + 20 = 20  in tenths
boundaryCurvature-val : boundaryCurvature ≡ pos 20
boundaryCurvature-val = refl

-- ────────────────────────────────────────────────────────────────
--  The total curvature splits into interior + boundary.
--
--  Both sides normalize to  pos 10  (= one₁₀ = χ₁₀).
--  The proof is  refl  because all subexpressions are closed
--  integer terms that reduce judgmentally.
-- ────────────────────────────────────────────────────────────────

totalCurvature-split :
  totalCurvature ≡ interiorCurvature +₁₀ boundaryCurvature
totalCurvature-split = refl

-- ────────────────────────────────────────────────────────────────
--  Verification:  (−10) + 20 = 10 = one₁₀
-- ────────────────────────────────────────────────────────────────

interior+boundary≡χ :
  interiorCurvature +₁₀ boundaryCurvature ≡ χ₁₀
interior+boundary≡χ = refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  GaussBonnetWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  This record packages all the data and proofs constituting
--  Theorem 1 into a single inspectable artifact.  It serves as
--  the **Milestone 1 deliverable** from §6.9 of docs/06-challenges.md:
--
--    "Formal proof of discrete Gauss–Bonnet (combinatorial or Regge
--     form, with boundary correction for finite patches).  This is
--     independently publishable as a formalization result."
--
--  The record captures:
--
--    • Topology:  V, E, F counts and the Euler identity V+F = E+1
--    • Curvature: the total curvature sum (in ℚ₁₀)
--    • Target:    the Euler characteristic (in ℚ₁₀)
--    • Theorem:   curvature sum = Euler characteristic
--
--  Future extensions could add:
--
--    • The curvature function itself (κ-class or κ)
--    • The vertex classification data
--    • Interior/boundary decomposition fields
--    • A face-count field for completeness
--
--  These are omitted in the first pass following the design
--  principle from §11.2 of docs/08-tree-instance.md: keep records
--  minimal until the end-to-end pipeline works.
-- ════════════════════════════════════════════════════════════════════

record GaussBonnetWitness : Type₀ where
  field
    -- Topology of the polygon complex
    V E F          : ℕ
    euler-identity : V + F ≡ E + 1

    -- Curvature data (in ℚ₁₀ representation)
    curvatureSum   : ℚ₁₀
    eulerChar₁₀    : ℚ₁₀

    -- The theorem:  Σ κ(v) = χ(K)
    gauss-bonnet   : curvatureSum ≡ eulerChar₁₀

-- ────────────────────────────────────────────────────────────────
--  The concrete witness for the 11-tile {5,4} patch.
--
--  All fields are filled from PatchComplex and Curvature.
--  The gauss-bonnet field is the core proof:
--    totalCurvature ≡ χ₁₀  by  refl  (via discrete-gauss-bonnet).
-- ────────────────────────────────────────────────────────────────

patch-gb-witness : GaussBonnetWitness
patch-gb-witness .GaussBonnetWitness.V              = totalV
patch-gb-witness .GaussBonnetWitness.E              = totalE
patch-gb-witness .GaussBonnetWitness.F              = totalF
patch-gb-witness .GaussBonnetWitness.euler-identity = euler-char
patch-gb-witness .GaussBonnetWitness.curvatureSum   = totalCurvature
patch-gb-witness .GaussBonnetWitness.eulerChar₁₀    = χ₁₀
patch-gb-witness .GaussBonnetWitness.gauss-bonnet   = discrete-gauss-bonnet


-- ════════════════════════════════════════════════════════════════════
--  §5.  Named theorem alias  (for downstream reference)
-- ════════════════════════════════════════════════════════════════════
--
--  The type  Theorem1  and its inhabitant  theorem1  provide a
--  stable reference point for the roadmap and documentation.
--  Phase 3 modules (Bridge/) may refer to  Theorem1  when
--  recording that the bulk foundations are in place.
--
--  The type is a proposition (it lives in a set type ℚ₁₀ = ℤ,
--  so paths between elements of ℤ are propositions by isSetℤ).
--  This means any two proofs of  Theorem1  are equal — there is
--  no spurious higher structure in the theorem statement.
-- ════════════════════════════════════════════════════════════════════

Theorem1 : Type₀
Theorem1 = totalCurvature ≡ χ₁₀

theorem1 : Theorem1
theorem1 = discrete-gauss-bonnet


-- ════════════════════════════════════════════════════════════════════
--  §6.  Concrete numeric verification
-- ════════════════════════════════════════════════════════════════════
--
--  These lemmas state the theorem's content in terms of raw ℤ
--  numerals, making the computation fully transparent and
--  independent of named constant aliases.  They serve as the
--  most basic regression test: if any upstream definition changes
--  (curvature values, class counts, or ℤ arithmetic), these
--  proofs will fail immediately.
-- ════════════════════════════════════════════════════════════════════

-- Total curvature is literally  pos 10  (= 10/10 = 1)
totalCurvature-raw : totalCurvature ≡ pos 10
totalCurvature-raw = refl

-- Euler characteristic is literally  pos 10
χ₁₀-raw : χ₁₀ ≡ pos 10
χ₁₀-raw = refl

-- Interior contribution is literally  negsuc 9  (= −10/10 = −1)
interior-raw : interiorCurvature ≡ negsuc 9
interior-raw = refl

-- Boundary contribution is literally  pos 20  (= 20/10 = 2)
boundary-raw : boundaryCurvature ≡ pos 20
boundary-raw = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  This module completes Phase 2B.3 of the roadmap and satisfies
--  Milestone 1 of §6.9 (docs/06-challenges.md).
--
--  Proof pipeline:
--
--    PatchComplex.agda        defines the 11-tile polygon complex
--         │                   (VClass, vCount, totalV/E/F, euler-char)
--         ▼
--    Curvature.agda           defines κ-class, κ, totalCurvature
--         │                   and verifies  totalCurvature≡χ = refl
--         ▼
--    GaussBonnet.agda         names χ₁₀, states Theorem 1,
--      (this module)          decomposes interior/boundary,
--                             and packages GaussBonnetWitness.
--
--  The scalar infrastructure comes from:
--
--    Util/Rationals.agda      defines ℚ₁₀ = ℤ, arithmetic,
--                             and named curvature constants.
--
--  All proofs in this module are  refl  (or trivially derived from
--  upstream  refl  proofs), because:
--
--    1.  Every curvature value and class count is a closed
--        constructor term (pos n  or  negsuc n  with concrete n).
--
--    2.  ℕ-scalar multiplication  _·₁₀_  computes by structural
--        recursion on the ℕ argument.
--
--    3.  ℤ addition  _+₁₀_ = _+ℤ_  computes by structural
--        recursion on closed terms.
--
--    4.  All named constants are defined once in Util/Rationals.agda
--        and imported (never reconstructed), guaranteeing identical
--        normal forms wherever they appear.
--
--  Relationship to the angular formulation:
--
--    The combinatorial Gauss–Bonnet  Σ κ(v) = χ(K)  does not
--    mention π or 2π.  The angular version
--
--        Σ_{int} κ(v) + Σ_{∂} τ(v) = 2π · χ(K)
--
--    requires representing π constructively, which is a stretch
--    goal (assumptions.md, assumption 5).  The decomposition in §3
--    above is the combinatorial analogue of this split, with:
--
--      interiorCurvature  ↔  Σ_{int} κ    (= −10/10 ↔ −2π)
--      boundaryCurvature  ↔  Σ_{∂} τ      (=  20/10 ↔  4π)
--      total              ↔  2π·χ          (=  10/10 ↔  2π)
--
--    The proportionality factor is  2π/10  per tenth-unit, but
--    this identification is interpretive, not formalized.  The
--    combinatorial formulation is self-contained and sufficient
--    for Theorem 1.
--
--  Next steps:
--
--    • Phase 2B.4 (Bulk/StarChain.agda):  already complete for
--      the 6-tile star.
--    • Phase 2B.5 (concrete instance):  the patch-gb-witness
--      record IS the concrete instance.
--    • Phase 3 (Bridge):  the bulk foundations are now in place
--      for constructing the observable-package equivalence.
-- ════════════════════════════════════════════════════════════════════