{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.DeSitterCurvature where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat  using (ℕ ; _·_)
open import Cubical.Data.Int  using (pos ; negsuc)

open import Util.Rationals
open import Bulk.DeSitterPatchComplex

-- ════════════════════════════════════════════════════════════════════
--  Combinatorial Curvature for the 6-Face {5,3} Star Patch
-- ════════════════════════════════════════════════════════════════════
--
--  This module defines the combinatorial curvature function  dsκ  for
--  the 6-face star patch of the {5,3} spherical tiling (regular
--  dodecahedron), encoded in  Bulk/DeSitterPatchComplex.agda .  It is
--  the primary curvature formalization for the de Sitter (dS) side
--  of the discrete Wick rotation (Theorem 4 in the canonical
--  theorem registry, docs/formal/01-theorems.md).
--
--  The combinatorial curvature formula is:
--
--      κ(v) = 1 − deg_E(v)/2 + Σ_{f ∋ v} 1/sides(f)
--
--  This is the same formula used for the {5,4} patch in
--  Bulk/Curvature.agda.  The only difference is the input data:
--  interior vertices have valence 3 (not 4), producing POSITIVE
--  curvature (+1/10) instead of negative curvature (−1/5).
--
--  The scalar type is  ℚ₁₀ = ℤ  from  Util/Rationals.agda , where
--  the integer  n  represents the rational  n/10 .  All curvature
--  values for the {5,3} tiling have denominators dividing 10, so
--  this representation is exact and supports judgmental computation.
--
--  Architectural role:
--    This is a Tier 2 (Observable / Geometry Layer) module providing
--    the dS-side curvature function consumed by
--    Bulk/DeSitterGaussBonnet.agda (the dS Gauss–Bonnet theorem)
--    and Bridge/WickRotation.agda (the curvature-agnostic coherence
--    record).  It has no dependencies on any Bridge or Boundary
--    module.
--
--  Numerical verification:
--    sim/prototyping/10_desitter_prototype.py  (§5–§8 of output)
--
--  Downstream modules:
--    src/Bulk/DeSitterGaussBonnet.agda  — Σ κ(v) ≡ χ(K)
--    src/Bridge/WickRotation.agda       — coherence record
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §6  (the {5,3} dS patch)
--    docs/formal/08-wick-rotation.md §4      (positive interior curvature)
--    docs/instances/desitter-patch.md §4     (curvature per vertex class)
--    docs/formal/01-theorems.md §Thm 4      (Discrete Wick Rotation)
--    docs/reference/module-index.md          (module description)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  dsκ-class — Curvature per vertex class (primary definition)
-- ════════════════════════════════════════════════════════════════════
--
--  The 15 vertices of the 6-face {5,3} patch fall into 3 classes
--  with identical combinatorial neighborhoods.  Curvature is constant
--  within each class:
--
--    Class      Count   deg   faces   κ (rational)   κ (tenths)
--    ────────   ─────   ───   ─────   ────────────   ──────────
--    dsTiling     5      3      3       +1/10           +1
--    dsSharedW    5      3      2       −1/10           −1
--    dsOuterB     5      2      1       +1/5            +2
--
--  The curvature values are named constants from Util/Rationals.agda,
--  defined once and imported here.  This guarantees judgmental
--  stability: identical constants have identical ℤ normal forms,
--  enabling all downstream proofs to be discharged by  refl .
--
--  INTERIOR CURVATURE IS POSITIVE:  κ(v_i) = +1/10 .
--  This is the defining feature of the spherical (de Sitter) regime.
--  Compare with the {5,4} patch where κ(v_i) = −1/5 (hyperbolic).
--
--  The curvature sign flip is the combinatorial analogue of the
--  cosmological constant sign flip  Λ_AdS < 0  →  Λ_dS > 0 .
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §6.2  (positive interior curvature)
--    docs/formal/08-wick-rotation.md §4.2      (curvature per class)
--    docs/instances/desitter-patch.md §4       (curvature comparison table)
-- ════════════════════════════════════════════════════════════════════

dsκ-class : DSVClass → ℚ₁₀
dsκ-class dsTiling  = pos1/10     --  1/10  (interior, 3 pentagons, POSITIVE)
dsκ-class dsSharedW = neg1/10     -- −1/10  (boundary shared, 2 pentagons)
dsκ-class dsOuterB  = pos1/5      --  2/10 = 1/5  (boundary outer, 1 pentagon)


-- ════════════════════════════════════════════════════════════════════
--  §2.  dsκ — Curvature per individual vertex
-- ════════════════════════════════════════════════════════════════════
--
--  Defined as  dsκ-class ∘ dsClassify , where  dsClassify : DSVertex → DSVClass
--  is the 15-clause classification function from DeSitterPatchComplex.
--
--  For any concrete vertex  w : DSVertex ,  dsκ w  reduces judgmentally
--  to the named constant for the corresponding class.  For example:
--
--    dsκ dsv₀ = dsκ-class (dsClassify dsv₀) = dsκ-class dsTiling = pos1/10
--    dsκ dsw₂ = dsκ-class (dsClassify dsw₂) = dsκ-class dsSharedW = neg1/10
--    dsκ dsb₃ = dsκ-class (dsClassify dsb₃) = dsκ-class dsOuterB = pos1/5
-- ════════════════════════════════════════════════════════════════════

dsκ : DSVertex → ℚ₁₀
dsκ w = dsκ-class (dsClassify w)


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
--  Computation traces:
--
--    dsTiling:   10 − 5·3 + 2·3 = 10 − 15 + 6  =  1  = pos1/10  ✓
--    dsSharedW:  10 − 5·3 + 2·2 = 10 − 15 + 4  = −1  = neg1/10  ✓
--    dsOuterB:   10 − 5·2 + 2·1 = 10 − 10 + 2  =  2  = pos1/5   ✓
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §4.1  (the curvature formula)
--    sim/prototyping/10_desitter_prototype.py   (numerical verification)
-- ════════════════════════════════════════════════════════════════════

dsκ-formula : DSVClass → ℚ₁₀
dsκ-formula cl =
  one₁₀ +₁₀ (-₁₀ (pos (5 · dsEdgeDeg cl))) +₁₀ pos (2 · dsFaceValence cl)

-- The computable formula agrees with the lookup table on all 3 classes.

dsκ-formula≡dsκ-class : (cl : DSVClass) → dsκ-formula cl ≡ dsκ-class cl
dsκ-formula≡dsκ-class dsTiling  = refl
dsκ-formula≡dsκ-class dsSharedW = refl
dsκ-formula≡dsκ-class dsOuterB  = refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  Per-class regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These lemmas verify that dsκ-class maps each class to the expected
--  named constant from Util/Rationals.agda.  They serve as regression
--  tests: if any curvature value is accidentally changed, these proofs
--  will fail at type-check time.
-- ════════════════════════════════════════════════════════════════════

-- Interior tiling vertices: κ = +1/10 = pos 1  (POSITIVE — spherical!)
dsκ-tiling : dsκ-class dsTiling ≡ pos1/10
dsκ-tiling = refl

-- Boundary shared-W vertices: κ = −1/10 = negsuc 0
dsκ-sharedW : dsκ-class dsSharedW ≡ neg1/10
dsκ-sharedW = refl

-- Boundary outer-B vertices: κ = +1/5 = pos 2
dsκ-outerB : dsκ-class dsOuterB ≡ pos1/5
dsκ-outerB = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Per-vertex spot checks
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the composition  dsκ = dsκ-class ∘ dsClassify
--  produces the expected values on representative vertices from
--  each class.  The proofs hold by refl because dsClassify and
--  dsκ-class both reduce by pattern matching on closed constructor
--  terms.
-- ════════════════════════════════════════════════════════════════════

-- Tiling vertex dsv₀ (interior, class dsTiling)
dsκ-v₀ : dsκ dsv₀ ≡ pos1/10
dsκ-v₀ = refl

-- Tiling vertex dsv₃ (interior, class dsTiling)
dsκ-v₃ : dsκ dsv₃ ≡ pos1/10
dsκ-v₃ = refl

-- Shared-W vertex dsw₁ (boundary, class dsSharedW)
dsκ-w₁ : dsκ dsw₁ ≡ neg1/10
dsκ-w₁ = refl

-- Outer-B vertex dsb₂ (boundary, class dsOuterB)
dsκ-b₂ : dsκ dsb₂ ≡ pos1/5
dsκ-b₂ = refl

-- Outer-B vertex dsb₄ (boundary, class dsOuterB)
dsκ-b₄ : dsκ dsb₄ ≡ pos1/5
dsκ-b₄ = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Total curvature (class-weighted sum)
-- ════════════════════════════════════════════════════════════════════
--
--  The total curvature of the 6-face {5,3} patch, computed as the
--  class-weighted sum:
--
--    Σ_v κ(v) = Σ_{cl ∈ DSVClass} dsVCount(cl) · dsκ-class(cl)
--
--  Expansion in tenths (3-class grouping):
--
--    5 · (+1)  +  5 · (−1)  +  5 · (+2)
--    = (+5)    +  (−5)     +  (+10)
--    = 10
--    = one₁₀
--    = χ(K)  in tenths
--
--  Computation trace for ℤ arithmetic:
--
--    5 ·₁₀ pos 1  = pos 5
--    5 ·₁₀ negsuc 0  = negsuc 4   (= −5)
--    5 ·₁₀ pos 2  = pos 10
--
--    pos 5 +₁₀ negsuc 4 = pos 0
--    pos 0 +₁₀ pos 10   = pos 10  = one₁₀
--
--  Because all operations compute by structural recursion on closed
--  constructor terms, the entire left-hand side normalizes
--  judgmentally to  pos 10 = one₁₀ , and the proof is  refl .
-- ════════════════════════════════════════════════════════════════════

dsTotalCurvature : ℚ₁₀
dsTotalCurvature =
    dsVCount dsTiling  ·₁₀ dsκ-class dsTiling
  +₁₀ dsVCount dsSharedW ·₁₀ dsκ-class dsSharedW
  +₁₀ dsVCount dsOuterB  ·₁₀ dsκ-class dsOuterB

-- ────────────────────────────────────────────────────────────────
--  Gauss–Bonnet witness:  Σ κ(v) = χ(K) = 1 = 10/10
-- ────────────────────────────────────────────────────────────────

dsTotalCurvature≡χ : dsTotalCurvature ≡ one₁₀
dsTotalCurvature≡χ = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Per-class contribution checks
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that each class-weighted contribution normalizes
--  to the expected ℤ value.  They decompose the Gauss–Bonnet sum
--  into inspectable pieces.
-- ════════════════════════════════════════════════════════════════════

-- 5 tiling vertices × (+1/10) = +5/10 = pos 5
dsContrib-tiling : dsVCount dsTiling ·₁₀ dsκ-class dsTiling ≡ pos 5
dsContrib-tiling = refl

-- 5 shared-W vertices × (−1/10) = −5/10 = negsuc 4
dsContrib-sharedW : dsVCount dsSharedW ·₁₀ dsκ-class dsSharedW ≡ negsuc 4
dsContrib-sharedW = refl

-- 5 outer-B vertices × (+2/10) = +10/10 = pos 10
dsContrib-outerB : dsVCount dsOuterB ·₁₀ dsκ-class dsOuterB ≡ pos 10
dsContrib-outerB = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Interior / boundary curvature decomposition
-- ════════════════════════════════════════════════════════════════════
--
--  The total curvature decomposes into an interior contribution
--  (from the 5 tiling vertices dsv₀..dsv₄ of class dsTiling) and a
--  boundary contribution (from the 10 boundary vertices of the
--  remaining 2 classes).
--
--  This decomposition makes the geometric contrast with AdS visible:
--
--    • dS interior curvature is POSITIVE (+5/10 = +1/2),
--      confirming the spherical character of the {5,3} tiling.
--      At each interior vertex, 3 regular pentagons meet with a
--      total angle of 3 × 108° = 324° < 360°.
--
--    • AdS interior curvature is NEGATIVE (−10/10 = −1),
--      confirming the hyperbolic character of the {5,4} tiling.
--      At each interior vertex, 4 regular pentagons meet with a
--      total angle of 4 × 108° = 432° > 360°.
--
--    • Both sum to χ(K) = 1, but the interior/boundary split
--      distributes differently:
--        dS:   (+1/2) + (+1/2) = 1    (symmetric)
--        AdS:  (−1)   + (2)    = 1    (asymmetric)
--
--  The symmetric dS decomposition reflects the even distribution
--  of positive cosmological curvature in spherical geometry.  The
--  asymmetric AdS decomposition reflects the strong interior
--  deficit compensated by large boundary turning in hyperbolic
--  geometry.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §6.3  (dS symmetric decomposition)
--    docs/formal/08-wick-rotation.md §5.3      (dS vs AdS decomposition)
--    docs/instances/desitter-patch.md §5       (Gauss–Bonnet)
-- ════════════════════════════════════════════════════════════════════

dsInteriorCurvature : ℚ₁₀
dsInteriorCurvature = dsVCount dsTiling ·₁₀ dsκ-class dsTiling

-- 5 × (+1) = +5  in tenths
dsInteriorCurvature-val : dsInteriorCurvature ≡ pos 5
dsInteriorCurvature-val = refl

dsBoundaryCurvature : ℚ₁₀
dsBoundaryCurvature =
    dsVCount dsSharedW ·₁₀ dsκ-class dsSharedW
  +₁₀ dsVCount dsOuterB  ·₁₀ dsκ-class dsOuterB

-- (−5) + 10 = 5  in tenths
dsBoundaryCurvature-val : dsBoundaryCurvature ≡ pos 5
dsBoundaryCurvature-val = refl

-- The total curvature splits into interior + boundary.
dsTotalCurvature-split :
  dsTotalCurvature ≡ dsInteriorCurvature +₁₀ dsBoundaryCurvature
dsTotalCurvature-split = refl

-- Verification:  (+5) + (+5) = 10 = one₁₀
dsInterior+boundary≡χ :
  dsInteriorCurvature +₁₀ dsBoundaryCurvature ≡ one₁₀
dsInterior+boundary≡χ = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Curvature sign checks
-- ════════════════════════════════════════════════════════════════════
--
--  The {5,3} tiling is SPHERICAL: interior vertices have strictly
--  POSITIVE curvature.  This is a consequence of the Schläfli
--  condition: 3 regular pentagons meeting at a vertex produce an
--  angle sum of 3 × 108° = 324° < 360°.
--
--  The positive interior curvature is the defining characteristic
--  that distinguishes the de Sitter (dS) regime from the
--  Anti-de Sitter (AdS) regime of the {5,4} tiling.
--
--  Comparison with AdS ({5,4}):
--    AdS interior:  κ = negsuc 1  (= −2 in tenths = −1/5)  NEGATIVE
--    dS  interior:  κ = pos 1     (= +1 in tenths = +1/10) POSITIVE
--
--  Reference:
--    docs/formal/08-wick-rotation.md §4.3  (curvature comparison table)
--    docs/instances/desitter-patch.md §4   (curvature per vertex class)
-- ════════════════════════════════════════════════════════════════════

-- Interior curvature is POSITIVE:  κ(v_i) = pos 1  (i.e., +1 in tenths)
dsκ-interior-positive : dsκ-class dsTiling ≡ pos 1
dsκ-interior-positive = refl

-- The shared boundary class has negative curvature:
-- κ(w_i) = negsuc 0  (i.e., −1 in tenths)
dsκ-shared-negative : dsκ-class dsSharedW ≡ negsuc 0
dsκ-shared-negative = refl

-- The outer boundary class has positive curvature:
-- κ(b_i) = pos 2  (i.e., +2 in tenths)
dsκ-outer-positive : dsκ-class dsOuterB ≡ pos 2
dsκ-outer-positive = refl


-- ════════════════════════════════════════════════════════════════════
--  §10.  Curvature sign comparison with AdS
-- ════════════════════════════════════════════════════════════════════
--
--  The discrete Wick rotation is visible as a curvature sign flip
--  at interior vertices:
--
--    {5,4} (AdS):  κ_int = −1/5  = −2/10  = negsuc 1
--    {5,3} (dS):   κ_int = +1/10 = +1/10  = pos 1
--
--  Both satisfy Gauss–Bonnet:  Σ κ(v) = χ(K) = 1 = one₁₀
--
--  The boundary curvature compensates differently:
--
--    {5,4} (AdS):  interior = −10/10,  boundary = +20/10
--    {5,3} (dS):   interior =  +5/10,  boundary =  +5/10
--
--  The shared boundary vertex class (dsSharedW / vSharedA,vSharedC)
--  has the SAME curvature in both tilings:  κ = −1/10 = neg1/10.
--  The outer boundary class also matches:  κ = +1/5 = pos1/5.
--  Only the interior curvature changes sign.
--
--  Formally, the curvature sign flip is a change of tiling parameter
--  q (from 4 to 3), not a complex rotation.  No complex numbers,
--  no analytic continuation, no Lorentzian geometry.
--
--  Reference:
--    docs/formal/08-wick-rotation.md §4.3  (curvature comparison)
--    docs/formal/08-wick-rotation.md §9    (what changes / what doesn't)
--    docs/instances/desitter-patch.md §15  (comparison table)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §11.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for Bulk/DeSitterGaussBonnet.agda:
--
--    dsκ-class          : DSVClass → ℚ₁₀   (curvature per class)
--    dsκ                : DSVertex → ℚ₁₀   (curvature per vertex)
--    dsTotalCurvature   : ℚ₁₀              (class-weighted sum)
--    dsTotalCurvature≡χ : dsTotalCurvature ≡ one₁₀
--                                           (the Gauss–Bonnet identity)
--
--  Exports for Bridge/WickRotation.agda:
--
--    dsκ-class          — the dS curvature function
--    dsTotalCurvature≡χ — the dS Gauss–Bonnet proof
--    dsκ-interior-positive — witness of positive interior curvature
--
--  Design decisions:
--
--    1.  Curvature is defined on DSVClass (3 clauses) rather than
--        on DSVertex (15 clauses).  The per-vertex function  dsκ  is
--        the composition  dsκ-class ∘ dsClassify .  This leverages the
--        5-fold symmetry of the patch and keeps the curvature
--        function compact and readable.
--
--    2.  The lookup table is the PRIMARY definition;  dsκ-formula  is
--        a DERIVED verification.  Downstream modules should depend
--        on  dsκ-class  (which is stable under reformulation) rather
--        than on  dsκ-formula .
--
--    3.  All named constants (pos1/10, neg1/10, pos1/5, one₁₀) are
--        imported from Util/Rationals.agda and NEVER reconstructed
--        locally.  This maintains the judgmental stability guarantee
--        required for refl-based proofs — the shared-constants
--        discipline documented in docs/formal/02-foundations.md §6.3.
--
--    4.  The interior curvature is POSITIVE (pos 1 = +1/10), in
--        direct contrast to the {5,4} patch (negsuc 1 = −2/10 = −1/5).
--        This is the type-theoretic content of the cosmological
--        constant sign flip.
--
--    5.  The module does NOT import or modify any existing curvature
--        or bridge modules.  It is purely additive: the {5,4}
--        curvature formalization in Bulk/Curvature.agda and the
--        shared bridge in Bridge/GenericValidation.agda remain
--        untouched.
--
--  Numerical verification:
--    sim/prototyping/10_desitter_prototype.py  §5–§8
--    All curvature values and the Gauss–Bonnet sum verified.
--
--  Architectural role:
--    This is a Tier 2 (Observable / Geometry Layer) module.  It
--    provides the dS-side curvature function consumed by
--    Bulk/DeSitterGaussBonnet.agda and Bridge/WickRotation.agda.
--    See docs/getting-started/architecture.md for the full module
--    dependency DAG.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §6  (the {5,3} dS patch)
--    docs/formal/08-wick-rotation.md §4      (positive curvature)
--    docs/formal/01-theorems.md §Thm 4      (Discrete Wick Rotation)
--    docs/instances/desitter-patch.md        (instance data sheet)
--    docs/reference/module-index.md          (module description)
-- ════════════════════════════════════════════════════════════════════