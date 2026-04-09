{-# OPTIONS --cubical --safe --guardedness #-}

module Util.Rationals where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Int
  using (ℤ ; pos ; negsuc ; isSetℤ)
  renaming (_+_ to _+ℤ_ ; -_ to -ℤ_)
open import Cubical.Data.Nat using (ℕ ; zero ; suc)

-- ════════════════════════════════════════════════════════════════════
--  ℚ₁₀ — Signed Rationals in Tenths (Frac10 Representation)
-- ════════════════════════════════════════════════════════════════════
--
--  Representation:  the integer  n : ℤ  represents the rational  n/10.
--
--  All combinatorial curvature values for the {5,4} tiling have
--  denominators dividing 10:
--
--      κ = −1/5   = −2/10    (interior tiling vertices v_i)
--      κ = −1/10  = −1/10    (boundary shared vertices a_i, c_i)
--      κ =  1/5   =  2/10    (boundary outer vertices b_i, g_{i,j})
--      χ =  1     = 10/10    (Euler characteristic of the disk)
--
--  Using ℤ as the carrier gives perfect judgmental computation:
--  all arithmetic reduces by the built-in ℤ operations from the
--  cubical library, and identical expressions normalize to
--  identical ℤ terms.  This enables the Gauss–Bonnet summation
--  identity to be verified by  refl .
--
--  This is the "Frac10" fallback strategy from Phase 2B.0 of
--  docs/05-roadmap.md, recommended as Strategy 1 in §5.3 of
--  docs/09-happy-instance.md.  It is sufficient for the entire
--  combinatorial curvature formalization (Theorem 1).
--
--  Upgrade path
--  ────────────
--  When curvature computations require denominators not dividing 10
--  (e.g., for tilings with heptagonal or other polygon faces),
--  replace this module with:
--
--    (a)  a general canonical-form rational type, or
--    (b)  Cubical.HITs.Rationals.QuoQ
--
--  preserving the exported interface (ℚ₁₀, isSetℚ₁₀, _+₁₀_,
--  _·₁₀_, named constants) as far as possible.  The QuoQ route
--  sacrifices judgmental computation of arithmetic identities
--  (requiring explicit quotient-path reasoning instead of refl)
--  but supports arbitrary denominators.
--
--  Relationship to Util/Scalars.agda
--  ──────────────────────────────────
--  Util/Scalars provides  ℚ≥0 = ℕ  for the nonneg. scalar values
--  used in the boundary/bridge modules (min-cut and chain-length
--  values in {0, 1, 2}).  Util/Rationals provides  ℚ₁₀ = ℤ  for
--  the signed rational values used in the bulk curvature modules.
--  The two types serve different modules and do not conflict.
-- ════════════════════════════════════════════════════════════════════

ℚ₁₀ : Type₀
ℚ₁₀ = ℤ

isSetℚ₁₀ : isSet ℚ₁₀
isSetℚ₁₀ = isSetℤ

-- ════════════════════════════════════════════════════════════════════
--  Arithmetic operations
-- ════════════════════════════════════════════════════════════════════
--
--  Addition and negation are inherited directly from ℤ.
--
--  ℕ-scalar multiplication  n ·₁₀ q  computes  q + q + ⋯ + q
--  (n times) by structural recursion on the ℕ argument.  Because
--  _+ℤ_ on closed terms reduces judgmentally, any expression of
--  the form  k ·₁₀ (pos m)  or  k ·₁₀ (negsuc m)  with concrete
--  k, m normalizes to a single  pos _  or  negsuc _  constructor.
--
--  Fixity: scalar multiplication binds tighter than addition, so
--    5 ·₁₀ x +₁₀ 10 ·₁₀ y   parses as   (5 ·₁₀ x) +₁₀ (10 ·₁₀ y)
-- ════════════════════════════════════════════════════════════════════

infixl 6 _+₁₀_
infixl 7 _·₁₀_

_+₁₀_ : ℚ₁₀ → ℚ₁₀ → ℚ₁₀
_+₁₀_ = _+ℤ_

-₁₀_ : ℚ₁₀ → ℚ₁₀
-₁₀_ = -ℤ_

_·₁₀_ : ℕ → ℚ₁₀ → ℚ₁₀
zero  ·₁₀ _ = pos 0
suc n ·₁₀ z = z +₁₀ (n ·₁₀ z)

-- ════════════════════════════════════════════════════════════════════
--  Canonical constants — Curvature values of the {5,4} tiling
-- ════════════════════════════════════════════════════════════════════
--
--  Each constant is named by its rational value.  The underlying
--  integer is the numerator when the denominator is 10:
--
--      rational    ℤ value    constructor
--      ────────    ────────   ──────────────
--      −1/5        −2         negsuc 1
--      −1/10       −1         negsuc 0
--       0           0         pos 0
--       1/10        1         pos 1
--       1/5         2         pos 2
--       1          10         pos 10
--       2          20         pos 20
--
--  Convention:  define each constant ONCE here and import it into
--  all curvature and Gauss–Bonnet modules.  Do NOT reconstruct
--  these independently — identical normal forms are required for
--  refl-based summation proofs.  This is the same principle as
--  §11.5 of docs/08-tree-instance.md for the ℚ≥0 constants.
-- ════════════════════════════════════════════════════════════════════

-- −1/5 = −2/10   (interior tiling vertices: κ(v_i))
neg1/5 : ℚ₁₀
neg1/5 = negsuc 1

-- −1/10 = −1/10   (boundary shared vertices: κ(a_i), κ(c_i))
neg1/10 : ℚ₁₀
neg1/10 = negsuc 0

-- 0 = 0/10
zero₁₀ : ℚ₁₀
zero₁₀ = pos 0

-- 1/10 = 1/10
pos1/10 : ℚ₁₀
pos1/10 = pos 1

-- 1/5 = 2/10   (boundary outer vertices: κ(b_i), κ(g_{i,j}))
pos1/5 : ℚ₁₀
pos1/5 = pos 2

-- 1 = 10/10   (Euler characteristic χ(K) for the disk)
one₁₀ : ℚ₁₀
one₁₀ = pos 10

-- 2 = 20/10   (available for future use)
two₁₀ : ℚ₁₀
two₁₀ = pos 20

-- ════════════════════════════════════════════════════════════════════
--  Additive inverse regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that opposite curvature constants cancel to
--  zero under ℤ addition, as a sanity check on the representation.
--
--      pos 2 +ℤ negsuc 1
--    = pos 2 + negsuc (suc 0)
--    = predℤ (pos 2 + negsuc 0)
--    = predℤ (predℤ (pos 2))
--    = predℤ (pos 1)
--    = pos 0                       judgmentally
-- ════════════════════════════════════════════════════════════════════

cancel-1/5 : pos1/5 +₁₀ neg1/5 ≡ zero₁₀
cancel-1/5 = refl

cancel-1/10 : pos1/10 +₁₀ neg1/10 ≡ zero₁₀
cancel-1/10 = refl

-- ════════════════════════════════════════════════════════════════════
--  Scalar multiplication regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that ℕ-scalar multiplication of curvature
--  constants produces the expected ℤ normal forms.  Each test
--  corresponds to a class-count × curvature-value product appearing
--  in the Gauss–Bonnet sum for the 11-tile {5,4} patch.
--
--  The tests are grouped by the four vertex classes:
--
--    5 × (−1/5)  :  5 interior tiling vertices
--   10 × (−1/10) : 10 boundary shared vertices (5 a_i + 5 c_i)
--    5 × (1/5)   :  5 boundary outer-N vertices (b_i)
--   10 × (1/5)   : 10 boundary outer-G vertices (g_{i,j})
--
--  Computation trace for  5 ·₁₀ neg1/5 :
--
--    5 ·₁₀ (negsuc 1)
--    = negsuc 1 +₁₀ (4 ·₁₀ negsuc 1)
--    = negsuc 1 +₁₀ (negsuc 1 +₁₀ (3 ·₁₀ negsuc 1))
--    = ⋯
--    = negsuc 1 +₁₀ negsuc 1 +₁₀ negsuc 1 +₁₀ negsuc 1 +₁₀ negsuc 1 +₁₀ pos 0
--    = negsuc 9                                             judgmentally
--
--  negsuc 9 = −(9+1) = −10,  and  5 × (−2/10) = −10/10.   ✓
-- ════════════════════════════════════════════════════════════════════

-- 5 interior tiling vertices, each with κ = −1/5 = −2/10
-- 5 · (−2) = −10
check-5·neg1/5 : 5 ·₁₀ neg1/5 ≡ negsuc 9
check-5·neg1/5 = refl

-- 10 boundary shared vertices, each with κ = −1/10 = −1/10
-- 10 · (−1) = −10
check-10·neg1/10 : 10 ·₁₀ neg1/10 ≡ negsuc 9
check-10·neg1/10 = refl

-- 5 boundary outer-N vertices, each with κ = 1/5 = 2/10
-- 5 · 2 = 10
check-5·pos1/5 : 5 ·₁₀ pos1/5 ≡ pos 10
check-5·pos1/5 = refl

-- 10 boundary outer-G vertices, each with κ = 1/5 = 2/10
-- 10 · 2 = 20
check-10·pos1/5 : 10 ·₁₀ pos1/5 ≡ pos 20
check-10·pos1/5 = refl

-- ════════════════════════════════════════════════════════════════════
--  Gauss–Bonnet summation witness  (4-class grouping)
-- ════════════════════════════════════════════════════════════════════
--
--  The combinatorial Gauss–Bonnet theorem for the 11-tile {5,4}
--  patch states  Σ_v κ(v) = χ(K) = 1.
--
--  Grouping vertices by curvature value:
--
--    Class              Count   κ (rational)   κ (tenths)
--    ─────              ─────   ────────────   ──────────
--    tiling  (v_i)        5       −1/5           −2
--    shared  (a_i, c_i)  10       −1/10          −1
--    outer-N (b_i)        5        1/5            2
--    outer-G (g_{i,j})   10        1/5            2
--                        ──
--                        30
--
--  Sum in tenths:
--    5·(−2) + 10·(−1) + 5·(2) + 10·(2)
--    = (−10)  + (−10)  +  10   +  20
--    = 10
--    = one₁₀
--
--  Because ℤ addition computes by structural recursion on closed
--  terms, the entire left-hand side normalizes judgmentally to
--  pos 10 = one₁₀, and the proof is refl.
--
--  This witness is the computational core of Theorem 1 (discrete
--  Gauss–Bonnet), corresponding to Phase 2B.3 of docs/05-roadmap.md
--  and §13 of docs/09-happy-instance.md.
--
--  Verified numerically by sim/prototyping/02_happy_patch_curvature.py:
--    Σ κ(v) = (−1) + (−1) + 1 + 2 = 1 = χ(K)   ✓
-- ════════════════════════════════════════════════════════════════════

gauss-bonnet-sum :
    5 ·₁₀ neg1/5
  +₁₀ 10 ·₁₀ neg1/10
  +₁₀  5 ·₁₀ pos1/5
  +₁₀ 10 ·₁₀ pos1/5
  ≡ one₁₀
gauss-bonnet-sum = refl

-- ════════════════════════════════════════════════════════════════════
--  Gauss–Bonnet summation witness  (5-class grouping)
-- ════════════════════════════════════════════════════════════════════
--
--  Alternative grouping matching the 5 vertex types from §4.1 of
--  docs/09-happy-instance.md:
--
--    Class             Count   κ (tenths)
--    ─────             ─────   ──────────
--    v (tiling)          5       −2
--    a (N/G shared)      5       −1
--    b (N outer)         5        2
--    c (N/G shared)      5       −1
--    g (G outer)        10        2
--
--  Sum in tenths:
--    5·(−2) + 5·(−1) + 5·(2) + 5·(−1) + 10·(2)
--    = (−10) + (−5) + 10 + (−5) + 20
--    = 10
-- ════════════════════════════════════════════════════════════════════

gauss-bonnet-sum-5class :
    5 ·₁₀ neg1/5
  +₁₀  5 ·₁₀ neg1/10
  +₁₀  5 ·₁₀ pos1/5
  +₁₀  5 ·₁₀ neg1/10
  +₁₀ 10 ·₁₀ pos1/5
  ≡ one₁₀
gauss-bonnet-sum-5class = refl

-- ════════════════════════════════════════════════════════════════════
--  Intermediate summation steps  (fallback if full refl times out)
-- ════════════════════════════════════════════════════════════════════
--
--  If the Agda type-checker is slow on the full gauss-bonnet-sum
--  proof (unlikely for numbers this small, but possible on
--  resource-constrained machines), the following stepwise witnesses
--  decompose the computation into smaller refl proofs that can be
--  composed via transitivity (_∙_).
--
--  These are also useful as documentation: they make the intermediate
--  ℤ normal forms explicit and inspectable.
-- ════════════════════════════════════════════════════════════════════

-- Step 1: each scalar multiplication
private
  -- 5 · (−2) = −10
  step-tiling  : 5 ·₁₀ neg1/5  ≡ negsuc 9
  step-tiling  = refl

  -- 10 · (−1) = −10
  step-shared  : 10 ·₁₀ neg1/10 ≡ negsuc 9
  step-shared  = refl

  -- 5 · 2 = 10
  step-outerN  : 5 ·₁₀ pos1/5  ≡ pos 10
  step-outerN  = refl

  -- 10 · 2 = 20
  step-outerG  : 10 ·₁₀ pos1/5 ≡ pos 20
  step-outerG  = refl

-- Step 2: partial sums (left to right)
private
  -- (−10) + (−10) = −20
  partial-1 : negsuc 9 +₁₀ negsuc 9 ≡ negsuc 19
  partial-1 = refl

  -- (−20) + 10 = −10
  partial-2 : negsuc 19 +₁₀ pos 10  ≡ negsuc 9
  partial-2 = refl

  -- (−10) + 20 = 10
  partial-3 : negsuc 9 +₁₀ pos 20   ≡ pos 10
  partial-3 = refl

-- ════════════════════════════════════════════════════════════════════
--  Negation regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  Verify that negation of curvature constants produces the expected
--  ℤ normal forms.  These may be useful for the angular curvature
--  formulation where boundary turning angles have opposite signs.
-- ════════════════════════════════════════════════════════════════════

neg-neg1/5 : -₁₀ neg1/5 ≡ pos1/5
neg-neg1/5 = refl

neg-pos1/5 : -₁₀ pos1/5 ≡ neg1/5
neg-pos1/5 = refl

neg-neg1/10 : -₁₀ neg1/10 ≡ pos1/10
neg-neg1/10 = refl

neg-zero : -₁₀ zero₁₀ ≡ zero₁₀
neg-zero = refl

-- ════════════════════════════════════════════════════════════════════
--  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  This module provides the complete scalar infrastructure for
--  Phase 2B of the roadmap:
--
--    • ℚ₁₀ = ℤ  as the signed rational type for curvature
--    • isSetℚ₁₀  for h-level discipline
--    • _+₁₀_, _·₁₀_  for arithmetic
--    • Named constants for all curvature values of the {5,4} tiling
--    • gauss-bonnet-sum : the arithmetic core of Theorem 1
--
--  The Gauss–Bonnet sum is verified by refl because:
--
--    1.  ℕ-scalar multiplication _·₁₀_ computes by structural
--        recursion on the ℕ argument.
--
--    2.  ℤ addition _+ℤ_ computes by structural recursion on the
--        second argument (via sucℤ / predℤ).
--
--    3.  All scalar constants are defined once here, ensuring that
--        identical values have identical ℤ normal forms.
--
--  Downstream modules:
--
--    src/Bulk/PatchComplex.agda   — 11-tile polygon complex encoding
--    src/Bulk/Curvature.agda     — κ : VClass → ℚ₁₀ (lookup table)
--    src/Bulk/GaussBonnet.agda   — Σ κ(v) ≡ χ(K) (uses gauss-bonnet-sum)
--
--  The existing tree and star bridge modules (using ℚ≥0 = ℕ from
--  Util/Scalars.agda) are unaffected by this module and continue
--  to type-check without modification, satisfying the compatibility
--  constraint from §15.1 of docs/09-happy-instance.md.
-- ════════════════════════════════════════════════════════════════════