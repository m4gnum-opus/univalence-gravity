{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.Curvature where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat  using (ℕ ; _·_)
open import Cubical.Data.Int  using (pos ; negsuc)

open import Util.Rationals
open import Bulk.PatchComplex

-- ════════════════════════════════════════════════════════════════════
--  Combinatorial Curvature for the 11-Tile {5,4} Patch
-- ════════════════════════════════════════════════════════════════════
--
--  This module defines the combinatorial curvature function  κ  for
--  the 11-tile filled patch of the {5,4} hyperbolic tiling, encoded
--  in  Bulk/PatchComplex.agda .  It is the primary curvature
--  formalization, implementing Option A (combinatorial curvature)
--  as frozen in  docs/reference/assumptions.md  (Assumption A11).
--
--  The combinatorial curvature formula is:
--
--      κ(v) = 1 − deg_E(v)/2 + Σ_{f ∋ v} 1/sides(f)
--
--  This is a purely algebraic quantity requiring no trigonometry,
--  no constructive reals, and no angle computation.  It satisfies
--  the combinatorial Gauss–Bonnet theorem:
--
--      Σ_v κ(v) = χ(K)
--
--  for any polyhedral cell complex K, automatically accounting for
--  boundary effects through the reduced degree and face count of
--  boundary vertices.
--
--  The scalar type is  ℚ₁₀ = ℤ  from  Util/Rationals.agda , where
--  the integer  n  represents the rational  n/10 .  All curvature
--  values for the {5,4} tiling have denominators dividing 10, so
--  this representation is exact and supports judgmental computation
--  of all arithmetic identities.
--
--  Numerical verification:
--    sim/prototyping/02_happy_patch_curvature.py
--
--  Downstream modules:
--    src/Bulk/GaussBonnet.agda  — Σ κ(v) ≡ χ(K)  (Theorem 2)
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §4  (curvature formula)
--    docs/formal/01-theorems.md §Thm 2      (Discrete Gauss–Bonnet)
--    docs/instances/filled-patch.md §6       (curvature on filled patch)
--    docs/reference/assumptions.md §A11      (combinatorial curvature)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  κ-class — Curvature per vertex class (primary definition)
-- ════════════════════════════════════════════════════════════════════
--
--  The 30 vertices of the 11-tile patch fall into 5 classes with
--  identical combinatorial neighborhoods.  Curvature is constant
--  within each class:
--
--    Class     Count   deg   faces   κ (rational)   κ (tenths)
--    ────────  ─────   ───   ─────   ────────────   ──────────
--    vTiling     5      4      4       −1/5           −2
--    vSharedA    5      3      2       −1/10          −1
--    vOuterB     5      2      1        1/5            2
--    vSharedC    5      3      2       −1/10          −1
--    vOuterG    10      2      1        1/5            2
--
--  The curvature values are named constants from Util/Rationals.agda,
--  defined once and imported here.  This guarantees judgmental
--  stability: identical constants have identical ℤ normal forms,
--  enabling all downstream proofs (formula verification, total
--  curvature, Gauss–Bonnet) to be discharged by  refl .
--
--  Interior vertices (vTiling) have κ < 0, confirming the negative
--  (hyperbolic) curvature of the {5,4} tiling.  Boundary vertices
--  have mixed signs; the sum over all vertices yields χ(K) = 1.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §4.2  (curvature per class)
-- ════════════════════════════════════════════════════════════════════

κ-class : VClass → ℚ₁₀
κ-class vTiling  = neg1/5     -- −2/10 = −1/5   (interior, 4 pentagons)
κ-class vSharedA = neg1/10    -- −1/10           (boundary, 2 pentagons)
κ-class vOuterB  = pos1/5     --  2/10 =  1/5   (boundary, 1 pentagon)
κ-class vSharedC = neg1/10    -- −1/10           (boundary, 2 pentagons)
κ-class vOuterG  = pos1/5     --  2/10 =  1/5   (boundary, 1 pentagon)


-- ════════════════════════════════════════════════════════════════════
--  §2.  κ — Curvature per individual vertex
-- ════════════════════════════════════════════════════════════════════
--
--  Defined as  κ-class ∘ classify , where  classify : Vertex → VClass
--  is the 30-clause classification function from PatchComplex.
--
--  For any concrete vertex  w : Vertex ,  κ w  reduces judgmentally
--  to the named constant for the corresponding class.  For example:
--
--    κ v₀ = κ-class (classify v₀) = κ-class vTiling = neg1/5
--    κ a₃ = κ-class (classify a₃) = κ-class vSharedA = neg1/10
--    κ g₂₁ = κ-class (classify g₂₁) = κ-class vOuterG = pos1/5
-- ════════════════════════════════════════════════════════════════════

κ : Vertex → ℚ₁₀
κ w = κ-class (classify w)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Computable formula and verification
-- ════════════════════════════════════════════════════════════════════
--
--  The combinatorial curvature formula:
--
--      κ(v) = 1 − deg(v)/2 + faceVal(v)/sides
--
--  In the ℚ₁₀ representation (tenths), multiplying through by 10:
--
--      κ₁₀(v) = 10 − 5 · deg(v) + 2 · faceValence(v)
--
--  because:
--      10 · 1         = 10
--      10 · (deg/2)   = 5 · deg
--      10 · (fVal/5)  = 2 · fVal    (all faces are pentagons)
--
--  The formula is computed in ℤ arithmetic:
--      one₁₀  +₁₀  (−₁₀ pos (5 · deg))  +₁₀  pos (2 · fVal)
--
--  where  _·_  is ℕ multiplication,  pos  lifts to ℤ,  −₁₀_  is
--  ℤ negation, and  _+₁₀_  is ℤ addition.
--
--  Computation trace for vTiling  (deg = 4, fVal = 4):
--
--    one₁₀ +₁₀ (−₁₀ pos 20) +₁₀ pos 8
--    = pos 10 +₁₀ negsuc 19 +₁₀ pos 8
--    = negsuc 9 +₁₀ pos 8            (pos 10 + negsuc 19 = negsuc 9)
--    = negsuc 1                       (negsuc 9 + pos 8 = negsuc 1)
--    = neg1/5                         ✓
--
--  The formula-verification proof  κ-formula≡κ-class  confirms that
--  this computation matches the lookup table on all 5 classes.  Each
--  case holds by  refl  because ℤ arithmetic reduces judgmentally on
--  closed terms.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §4.1  (the curvature formula)
--    sim/prototyping/02_happy_patch_curvature.py  (numerical check)
-- ════════════════════════════════════════════════════════════════════

κ-formula : VClass → ℚ₁₀
κ-formula cl =
  one₁₀ +₁₀ (-₁₀ (pos (5 · edgeDeg cl))) +₁₀ pos (2 · faceValence cl)

-- ────────────────────────────────────────────────────────────────
--  The computable formula agrees with the lookup table:
--
--    vTiling:   10 − 5·4 + 2·4 = 10 − 20 + 8  = −2  = neg1/5   ✓
--    vSharedA:  10 − 5·3 + 2·2 = 10 − 15 + 4  = −1  = neg1/10  ✓
--    vOuterB:   10 − 5·2 + 2·1 = 10 − 10 + 2  =  2  = pos1/5   ✓
--    vSharedC:  10 − 5·3 + 2·2 = 10 − 15 + 4  = −1  = neg1/10  ✓
--    vOuterG:   10 − 5·2 + 2·1 = 10 − 10 + 2  =  2  = pos1/5   ✓
-- ────────────────────────────────────────────────────────────────

κ-formula≡κ-class : (cl : VClass) → κ-formula cl ≡ κ-class cl
κ-formula≡κ-class vTiling  = refl
κ-formula≡κ-class vSharedA = refl
κ-formula≡κ-class vOuterB  = refl
κ-formula≡κ-class vSharedC = refl
κ-formula≡κ-class vOuterG  = refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  Per-class regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These lemmas verify that κ-class maps each class to the expected
--  named constant from Util/Rationals.agda.  They serve as
--  regression tests: if any curvature value is accidentally changed,
--  these proofs will fail at type-check time.
--
--  They also make the concrete ℤ normal forms explicit and
--  inspectable, providing documentation of the curvature values
--  alongside their named aliases.
-- ════════════════════════════════════════════════════════════════════

-- Interior tiling vertices: κ = −1/5 = −2/10 = negsuc 1
κ-tiling : κ-class vTiling ≡ neg1/5
κ-tiling = refl

-- Boundary shared-A vertices: κ = −1/10 = negsuc 0
κ-sharedA : κ-class vSharedA ≡ neg1/10
κ-sharedA = refl

-- Boundary outer-B vertices: κ = 1/5 = 2/10 = pos 2
κ-outerB : κ-class vOuterB ≡ pos1/5
κ-outerB = refl

-- Boundary shared-C vertices: κ = −1/10 = negsuc 0
κ-sharedC : κ-class vSharedC ≡ neg1/10
κ-sharedC = refl

-- Boundary outer-G vertices: κ = 1/5 = 2/10 = pos 2
κ-outerG : κ-class vOuterG ≡ pos1/5
κ-outerG = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Per-vertex spot checks
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the composition  κ = κ-class ∘ classify
--  produces the expected values on representative vertices from
--  each class.  The proofs hold by refl because classify and
--  κ-class both reduce by pattern matching on closed constructor
--  terms.
-- ════════════════════════════════════════════════════════════════════

-- Tiling vertex v₀ (interior, class vTiling)
κ-v₀ : κ v₀ ≡ neg1/5
κ-v₀ = refl

-- Tiling vertex v₃ (interior, class vTiling)
κ-v₃ : κ v₃ ≡ neg1/5
κ-v₃ = refl

-- Shared-A vertex a₂ (boundary, class vSharedA)
κ-a₂ : κ a₂ ≡ neg1/10
κ-a₂ = refl

-- Outer-B vertex b₁ (boundary, class vOuterB)
κ-b₁ : κ b₁ ≡ pos1/5
κ-b₁ = refl

-- Shared-C vertex c₄ (boundary, class vSharedC)
κ-c₄ : κ c₄ ≡ neg1/10
κ-c₄ = refl

-- Outer-G vertex g₂₁ (boundary, class vOuterG)
κ-g₂₁ : κ g₂₁ ≡ pos1/5
κ-g₂₁ = refl

-- Outer-G vertex g₀₂ (boundary, class vOuterG)
κ-g₀₂ : κ g₀₂ ≡ pos1/5
κ-g₀₂ = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Total curvature (class-weighted sum)
-- ════════════════════════════════════════════════════════════════════
--
--  The total curvature of the 11-tile patch, computed as the
--  class-weighted sum:
--
--    Σ_v κ(v) = Σ_{cl ∈ VClass} vCount(cl) · κ-class(cl)
--
--  Expansion in tenths:
--
--    5 · (−2)  +  5 · (−1)  +  5 · (2)  +  5 · (−1)  +  10 · (2)
--    = (−10)   +  (−5)     +  (10)     +  (−5)     +  (20)
--    = 10
--    = one₁₀
--    = χ(K)  in tenths
--
--  This is the 5-class grouping from gauss-bonnet-sum-5class
--  in Util/Rationals.agda, now expressed through the curvature
--  function defined in this module rather than through raw constants.
--
--  Because  vCount  and  κ-class  both reduce by pattern matching
--  to the same constants used in  gauss-bonnet-sum-5class , the
--  entire left-hand side normalizes judgmentally to  pos 10 = one₁₀ ,
--  and the proof is  refl .
-- ════════════════════════════════════════════════════════════════════

totalCurvature : ℚ₁₀
totalCurvature =
    vCount vTiling  ·₁₀ κ-class vTiling
  +₁₀ vCount vSharedA ·₁₀ κ-class vSharedA
  +₁₀ vCount vOuterB  ·₁₀ κ-class vOuterB
  +₁₀ vCount vSharedC ·₁₀ κ-class vSharedC
  +₁₀ vCount vOuterG  ·₁₀ κ-class vOuterG

-- ────────────────────────────────────────────────────────────────
--  Gauss–Bonnet witness:  Σ κ(v) = χ(K) = 1 = 10/10
-- ────────────────────────────────────────────────────────────────
--
--  This is the computational core of Theorem 2 (Discrete
--  Gauss–Bonnet) for the combinatorial curvature formulation.
--
--  The proof is  refl  because every operation in the left-hand
--  side ( vCount, κ-class, _·₁₀_, _+₁₀_ ) computes by
--  structural recursion on closed constructor terms, and the
--  ℤ normalizer reduces the entire expression to  pos 10 = one₁₀ .
--
--  Verified numerically by
--  sim/prototyping/02_happy_patch_curvature.py :
--    Σ κ(v) = (−1) + (−1/2) + 1 + (−1/2) + 2 = 1 = χ(K)   ✓
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 2    (Discrete Gauss–Bonnet)
--    docs/formal/04-discrete-geometry.md §5 (the proof)
-- ────────────────────────────────────────────────────────────────

totalCurvature≡χ : totalCurvature ≡ one₁₀
totalCurvature≡χ = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Per-class contribution checks
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that each class-weighted contribution normalizes
--  to the expected ℤ value.  They decompose the Gauss–Bonnet sum
--  into inspectable pieces and serve as debugging aids if a future
--  modification to PatchComplex or Rationals changes a count or
--  curvature value.
-- ════════════════════════════════════════════════════════════════════

-- 5 tiling vertices × (−2/10) = −10/10 = negsuc 9
contrib-tiling : vCount vTiling ·₁₀ κ-class vTiling ≡ negsuc 9
contrib-tiling = refl

-- 5 shared-A vertices × (−1/10) = −5/10 = negsuc 4
contrib-sharedA : vCount vSharedA ·₁₀ κ-class vSharedA ≡ negsuc 4
contrib-sharedA = refl

-- 5 outer-B vertices × (2/10) = 10/10 = pos 10
contrib-outerB : vCount vOuterB ·₁₀ κ-class vOuterB ≡ pos 10
contrib-outerB = refl

-- 5 shared-C vertices × (−1/10) = −5/10 = negsuc 4
contrib-sharedC : vCount vSharedC ·₁₀ κ-class vSharedC ≡ negsuc 4
contrib-sharedC = refl

-- 10 outer-G vertices × (2/10) = 20/10 = pos 20
contrib-outerG : vCount vOuterG ·₁₀ κ-class vOuterG ≡ pos 20
contrib-outerG = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Curvature sign checks
-- ════════════════════════════════════════════════════════════════════
--
--  The {5,4} tiling is hyperbolic: interior vertices have strictly
--  negative curvature.  This is a consequence of the Schläfli
--  condition: 4 regular pentagons meeting at a vertex produce an
--  angle sum of 4 × 108° = 432° > 360°.
--
--  The following checks verify the sign of curvature at interior
--  vs. boundary vertices, confirming the hyperbolic character of
--  the tiling.  The inequality  neg1/5 ≡ negsuc 1  makes the
--  negative sign manifest in the ℤ representation.
-- ════════════════════════════════════════════════════════════════════

-- Interior curvature is negative:  κ(v_i) = negsuc 1  (i.e., −2)
κ-interior-negative : κ-class vTiling ≡ negsuc 1
κ-interior-negative = refl

-- The two shared boundary classes also have negative curvature:
-- κ(a_i) = κ(c_i) = negsuc 0  (i.e., −1)
κ-shared-negative : κ-class vSharedA ≡ negsuc 0
κ-shared-negative = refl

-- The outer boundary classes have positive curvature:
-- κ(b_i) = κ(g_{i,j}) = pos 2  (i.e., +2)
κ-outer-positive : κ-class vOuterB ≡ pos 2
κ-outer-positive = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for Bulk/GaussBonnet.agda:
--
--    κ-class          : VClass → ℚ₁₀   (curvature per class)
--    κ                : Vertex → ℚ₁₀   (curvature per vertex)
--    totalCurvature   : ℚ₁₀            (class-weighted sum)
--    totalCurvature≡χ : totalCurvature ≡ one₁₀
--                                       (the Gauss–Bonnet identity)
--
--  Exports for future angular / Regge curvature modules:
--
--    κ-formula        : VClass → ℚ₁₀
--    κ-formula≡κ-class : agreement with lookup table
--
--  Design decisions:
--
--    1.  Curvature is defined on VClass (5 clauses) rather than
--        on Vertex (30 clauses).  The per-vertex function  κ  is
--        the composition  κ-class ∘ classify .  This leverages the
--        5-fold symmetry of the {5,4} tiling and keeps the
--        curvature function compact and readable.
--        (See docs/formal/04-discrete-geometry.md §3.3.)
--
--    2.  The lookup table is the PRIMARY definition;  κ-formula  is
--        a DERIVED verification.  The formula serves as a
--        machine-checked derivation connecting the lookup values to
--        the mathematical definition, but downstream modules should
--        depend on  κ-class  (which is stable under reformulation)
--        rather than on  κ-formula  (which is tied to the specific
--        ℚ₁₀ encoding of the combinatorial formula).
--
--    3.  The  totalCurvature≡χ  proof is included here as a sanity
--        check.  The downstream  GaussBonnet.agda  module provides
--        a more formally packaged version connecting this to the
--        Euler characteristic from PatchComplex, with an explicit
--        statement of the theorem:
--
--            Σ_v κ(v) = χ(K)
--
--        where χ(K) is computed from the V, E, F counts.
--        (See docs/formal/01-theorems.md §Thm 2.)
--
--    4.  The angular curvature (Option B, stretch goal) would
--        require representing π constructively.  If attempted,
--        it should be defined in a separate module
--        (e.g. Bulk/AngularCurvature.agda) and should NOT modify
--        this module.  The combinatorial formulation is sufficient
--        for Theorem 2 (Discrete Gauss–Bonnet).
--        (See docs/reference/assumptions.md §A11.)
--
--    5.  All named constants (neg1/5, neg1/10, pos1/5, one₁₀) are
--        imported from Util/Rationals.agda and NEVER reconstructed
--        locally.  This maintains the judgmental stability guarantee
--        required for refl-based proofs — the shared-constants
--        discipline documented in docs/formal/02-foundations.md §6.3.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md   (curvature and Gauss–Bonnet)
--    docs/formal/01-theorems.md §Thm 2    (Theorem 2 registry entry)
--    docs/formal/02-foundations.md §6      (scalar representation)
--    docs/instances/filled-patch.md §6     (curvature on the filled patch)
--    docs/reference/assumptions.md §A11    (combinatorial curvature)
-- ════════════════════════════════════════════════════════════════════