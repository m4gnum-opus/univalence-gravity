{-# OPTIONS --cubical --safe --guardedness #-}

module Util.Scalars where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat            using (ℕ ; zero ; suc ; _+_)
open import Cubical.Data.Nat.Properties using (isSetℕ)

-- ════════════════════════════════════════════════════════════════════
--  ℚ≥0 — Nonnegative Scalars (Pilot Representation)
-- ════════════════════════════════════════════════════════════════════
--
--  Current pilot choice:
--
--      ℚ≥0 = ℕ
--
--  This is sufficient for the tree pilot and the 6-tile star bridge,
--  where all observable values lie in {0, 1, 2}.  The key advantage
--  is judgmental stability:
--
--    • identical scalar constants normalize to identical normal forms;
--    • scalar addition computes by recursion on the left argument;
--    • the ordering witness type below admits concrete proofs
--      of the form  (k , refl).
--
--  This is exactly the computational behavior relied upon by:
--
--    • Bridge.TreeObs.tree-pointwise
--    • Bridge.StarObs.star-pointwise
--    • Boundary.StarSubadditivity.subadditivity
--
--  In particular, the subadditivity proof uses witnesses such as
--  (0 , refl), (1 , refl), (2 , refl), (3 , refl), and these type-check
--  only because _+ℚ_ computes judgmentally on closed numerals.
--
--  Upgrade path:
--
--  When the bulk curvature development requires genuine fractions,
--  replace the carrier ℕ by a canonical nonnegative rational type
--  while preserving this exported interface as far as possible:
--
--      ℚ≥0      : Type₀
--      isSetℚ≥0 : isSet ℚ≥0
--      0q 1q 2q : ℚ≥0
--      _+ℚ_     : ℚ≥0 → ℚ≥0 → ℚ≥0
--      _≤ℚ_     : ℚ≥0 → ℚ≥0 → Type₀
--
--  The exact representation may change, but clients of the scalar
--  interface should not need to know whether the implementation is
--  ℕ, canonical fractions, or a wrapped cubical rational quotient.
-- ════════════════════════════════════════════════════════════════════

ℚ≥0 : Type₀
ℚ≥0 = ℕ

isSetℚ≥0 : isSet ℚ≥0
isSetℚ≥0 = isSetℕ

-- ── Canonical constants ─────────────────────────────────────────
--  Defined once and imported everywhere.  Do NOT reconstruct these
--  independently on the boundary and bulk sides: identical normal
--  forms are required for refl-based agreement proofs.
-- ────────────────────────────────────────────────────────────────

0q : ℚ≥0
0q = 0

1q : ℚ≥0
1q = 1

2q : ℚ≥0
2q = 2

-- ════════════════════════════════════════════════════════════════════
--  Scalar addition and ordering
-- ════════════════════════════════════════════════════════════════════
--
--  These operations were first introduced locally in
--  Boundary.StarSubadditivity.agda.  They now live here so that all
--  boundary/bulk developments share one scalar-ordering interface.
--
--  Addition is inherited directly from ℕ.
--
--  Ordering is encoded by a witness that n is obtained from m by
--  adding some nonnegative scalar k on the left:
--
--      m ≤ℚ n  ≔  Σ[ k ∈ ℕ ] (k + m ≡ n)
--
--  Because ℕ addition computes by recursion on the first argument,
--  any closed witness  (k , refl)  reduces judgmentally whenever
--  k + m normalizes to n.  This is the exact proof-relevant shape
--  needed by the current star-subadditivity development.
-- ════════════════════════════════════════════════════════════════════

infixl 6 _+ℚ_
infix  4 _≤ℚ_

_+ℚ_ : ℚ≥0 → ℚ≥0 → ℚ≥0
_+ℚ_ = _+_

_≤ℚ_ : ℚ≥0 → ℚ≥0 → Type₀
m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)

-- ════════════════════════════════════════════════════════════════════
--  Canonical concrete inequality witnesses
-- ════════════════════════════════════════════════════════════════════
--
--  These lemmas are not mathematically deep; they serve as explicit
--  regression tests for the judgmental behavior of the scalar
--  interface.  They are exactly the closed inequalities currently
--  used in Boundary.StarSubadditivity.
--
--  If a future scalar upgrade breaks any of these refl proofs, that
--  is a signal that the replacement representation has lost the
--  judgmental stability the current proof scripts rely on.
-- ════════════════════════════════════════════════════════════════════

-- 2 ≤ 1 + 1 = 2
≤-check-2≤2 : 2q ≤ℚ (1q +ℚ 1q)
≤-check-2≤2 = 0 , refl

-- 2 ≤ 1 + 2 = 3
≤-check-2≤3a : 2q ≤ℚ (1q +ℚ 2q)
≤-check-2≤3a = 1 , refl

-- 2 ≤ 2 + 1 = 3
≤-check-2≤3b : 2q ≤ℚ (2q +ℚ 1q)
≤-check-2≤3b = 1 , refl

-- 1 ≤ 1 + 2 = 3
≤-check-1≤3a : 1q ≤ℚ (1q +ℚ 2q)
≤-check-1≤3a = 2 , refl

-- 1 ≤ 2 + 1 = 3
≤-check-1≤3b : 1q ≤ℚ (2q +ℚ 1q)
≤-check-1≤3b = 2 , refl

-- 1 ≤ 2 + 2 = 4
≤-check-1≤4 : 1q ≤ℚ (2q +ℚ 2q)
≤-check-1≤4 = 3 , refl