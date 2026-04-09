{-# OPTIONS --cubical --safe --guardedness #-}

module Boundary.StarSubadditivity where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; zero ; suc ; _+_)

open import Util.Scalars

-- ════════════════════════════════════════════════════════════════════
--  ℚ≥0 ordering and addition
-- ════════════════════════════════════════════════════════════════════
--
--  These definitions extend the Util/Scalars interface with the
--  ordering and addition required for subadditivity.  They should
--  eventually be migrated into Util/Scalars.agda itself.
--
--  Since  ℚ≥0 = ℕ  (Util/Scalars.agda), both are inherited
--  directly from the natural numbers.
--
--  The ≤ relation is defined as  m ≤ℚ n = Σ ℕ (λ k → k + m ≡ n).
--  Because  _+_  on ℕ computes by recursion on the first argument:
--
--       zero  + n = n              (definitional)
--       suc k + n = suc (k + n)   (definitional)
--
--  every concrete witness  (k , refl)  type-checks: the equality
--  component reduces judgmentally.  This is the key property that
--  makes the entire subadditivity proof computable by refl.
-- ════════════════════════════════════════════════════════════════════

infixl 6 _+ℚ_
infix  4 _≤ℚ_

_+ℚ_ : ℚ≥0 → ℚ≥0 → ℚ≥0
_+ℚ_ = _+_

_≤ℚ_ : ℚ≥0 → ℚ≥0 → Type₀
m ≤ℚ n = Σ ℕ (λ k → k + m ≡ n)

-- ════════════════════════════════════════════════════════════════════
--  Verification: refl satisfies ≤ℚ for every concrete case
-- ════════════════════════════════════════════════════════════════════
--
--  The subadditivity proof below uses exactly 4 distinct (k , refl)
--  witnesses.  We verify each one in isolation before the main proof.
--
--  ┌────────────────────────────────────────────────────────────────┐
--  │  Inequality    │  Witness      │  Computation                 │
--  ├────────────────┼──────────────┼──────────────────────────────┤
--  │  2 ≤ 1+1 = 2  │  (0 , refl)  │  0 + 2 = 2   judgmentally   │
--  │  2 ≤ 1+2 = 3  │  (1 , refl)  │  1 + 2 = 3   judgmentally   │
--  │  1 ≤ 1+2 = 3  │  (2 , refl)  │  2 + 1 = 3   judgmentally   │
--  │  1 ≤ 2+2 = 4  │  (3 , refl)  │  3 + 1 = 4   judgmentally   │
--  └────────────────────────────────────────────────────────────────┘
-- ════════════════════════════════════════════════════════════════════

-- 2 ≤ 1 + 1 = 2   (singleton ∪ singleton → pair)
≤-check-2≤2 : 2q ≤ℚ (1q +ℚ 1q)
≤-check-2≤2 = 0 , refl

-- 2 ≤ 1 + 2 = 3   (singleton ∪ pair → triple)
≤-check-2≤3a : 2q ≤ℚ (1q +ℚ 2q)
≤-check-2≤3a = 1 , refl

-- 2 ≤ 2 + 1 = 3   (pair ∪ singleton → triple)
≤-check-2≤3b : 2q ≤ℚ (2q +ℚ 1q)
≤-check-2≤3b = 1 , refl

-- 1 ≤ 1 + 2 = 3   (singleton ∪ triple → quadruple)
≤-check-1≤3a : 1q ≤ℚ (1q +ℚ 2q)
≤-check-1≤3a = 2 , refl

-- 1 ≤ 2 + 1 = 3   (triple ∪ singleton → quadruple)
≤-check-1≤3b : 1q ≤ℚ (2q +ℚ 1q)
≤-check-1≤3b = 2 , refl

-- 1 ≤ 2 + 2 = 4   (pair ∪ pair → quadruple)
≤-check-1≤4 : 1q ≤ℚ (2q +ℚ 2q)
≤-check-1≤4 = 3 , refl


-- ════════════════════════════════════════════════════════════════════
--  StarRegion — All 20 nonempty proper contiguous tile-aligned
--               boundary regions of the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  Cyclic boundary order:  N0 , N1 , N2 , N3 , N4
--
--  The 10 representative regions from docs/09-happy-instance.md §6.3
--  (5 singletons + 5 pairs) are extended here to the full 20
--  nonempty proper regions (adding 5 triples + 5 quadruples)
--  because union of smaller regions may produce larger regions.
--
--  By complement symmetry  S(A) = S(Ā):
--    singletons (size 1) and quadruples (size 4) have  S = 1
--    pairs      (size 2) and triples    (size 3) have  S = 2
--
--  Verified by 01_happy_patch_cuts.py: 20/20 regions, 30/30
--  subadditivity checks, 20/20 complement-symmetry checks.
-- ════════════════════════════════════════════════════════════════════

data StarRegion : Type₀ where
  -- Singletons  (size 1,  S = 1)
  sN0 sN1 sN2 sN3 sN4 : StarRegion
  -- Adjacent pairs  (size 2,  S = 2)
  sN01 sN12 sN23 sN34 sN40 : StarRegion
  -- Triples  (size 3,  S = 2)
  sN012 sN123 sN234 sN340 sN401 : StarRegion
  -- Quadruples  (size 4,  S = 1)
  sN0123 sN1234 sN2340 sN3401 sN4012 : StarRegion


-- ════════════════════════════════════════════════════════════════════
--  S-star — Min-cut entropy for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  S(k tiles) = min(k, 5 − k)   for a contiguous region of k tiles
--  on the 5-tile cyclic boundary.
--
--  All constants are canonical values from Util.Scalars, ensuring
--  that S-star applied to any closed StarRegion reduces to a
--  canonical numeral (1q = suc zero  or  2q = suc (suc zero)).
-- ════════════════════════════════════════════════════════════════════

S-star : StarRegion → ℚ≥0
-- Singletons:  min(1, 4) = 1
S-star sN0    = 1q
S-star sN1    = 1q
S-star sN2    = 1q
S-star sN3    = 1q
S-star sN4    = 1q
-- Pairs:  min(2, 3) = 2
S-star sN01   = 2q
S-star sN12   = 2q
S-star sN23   = 2q
S-star sN34   = 2q
S-star sN40   = 2q
-- Triples:  min(3, 2) = 2
S-star sN012  = 2q
S-star sN123  = 2q
S-star sN234  = 2q
S-star sN340  = 2q
S-star sN401  = 2q
-- Quadruples:  min(4, 1) = 1
S-star sN0123 = 1q
S-star sN1234 = 1q
S-star sN2340 = 1q
S-star sN3401 = 1q
S-star sN4012 = 1q


-- ════════════════════════════════════════════════════════════════════
--  _∪_≡_ — Region-union relation for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  A witness   u : r₁ ∪ r₂ ≡ r₃   asserts that the contiguous
--  boundary arc  r₁  is immediately followed (cyclically) by  r₂ ,
--  and their concatenation is the contiguous arc  r₃ .
--
--  There are exactly 30 valid union triples, arising from all
--  (lenA , lenB) pairs with  1 ≤ lenA, 1 ≤ lenB, lenA + lenB ≤ 4,
--  over 5 cyclic starting positions.
--
--  Constructor naming:  uAB₊S  where
--    A  = number of tiles in the first region
--    B  = number of tiles in the second region
--    S  = cyclic starting index (subscript digit)
--
--  Note: the  ≡  in the name  _∪_≡_  is a name-part of this
--  ternary operator, NOT the path type  _≡_  from Prelude.
--  Agda's mixfix parser resolves this unambiguously because the
--  binary operator  _∪_  is not in scope.
-- ════════════════════════════════════════════════════════════════════

data _∪_≡_ : StarRegion → StarRegion → StarRegion → Type₀ where

  -- ── lenA = 1, lenB = 1  →  pair  (5 cases) ───────────────────
  u11₀ : sN0 ∪ sN1 ≡ sN01
  u11₁ : sN1 ∪ sN2 ≡ sN12
  u11₂ : sN2 ∪ sN3 ≡ sN23
  u11₃ : sN3 ∪ sN4 ≡ sN34
  u11₄ : sN4 ∪ sN0 ≡ sN40

  -- ── lenA = 1, lenB = 2  →  triple  (5 cases) ─────────────────
  u12₀ : sN0  ∪ sN12 ≡ sN012
  u12₁ : sN1  ∪ sN23 ≡ sN123
  u12₂ : sN2  ∪ sN34 ≡ sN234
  u12₃ : sN3  ∪ sN40 ≡ sN340
  u12₄ : sN4  ∪ sN01 ≡ sN401

  -- ── lenA = 1, lenB = 3  →  quadruple  (5 cases) ──────────────
  u13₀ : sN0  ∪ sN123 ≡ sN0123
  u13₁ : sN1  ∪ sN234 ≡ sN1234
  u13₂ : sN2  ∪ sN340 ≡ sN2340
  u13₃ : sN3  ∪ sN401 ≡ sN3401
  u13₄ : sN4  ∪ sN012 ≡ sN4012

  -- ── lenA = 2, lenB = 1  →  triple  (5 cases) ─────────────────
  u21₀ : sN01 ∪ sN2  ≡ sN012
  u21₁ : sN12 ∪ sN3  ≡ sN123
  u21₂ : sN23 ∪ sN4  ≡ sN234
  u21₃ : sN34 ∪ sN0  ≡ sN340
  u21₄ : sN40 ∪ sN1  ≡ sN401

  -- ── lenA = 2, lenB = 2  →  quadruple  (5 cases) ──────────────
  u22₀ : sN01 ∪ sN23 ≡ sN0123
  u22₁ : sN12 ∪ sN34 ≡ sN1234
  u22₂ : sN23 ∪ sN40 ≡ sN2340
  u22₃ : sN34 ∪ sN01 ≡ sN3401
  u22₄ : sN40 ∪ sN12 ≡ sN4012

  -- ── lenA = 3, lenB = 1  →  quadruple  (5 cases) ──────────────
  u31₀ : sN012 ∪ sN3  ≡ sN0123
  u31₁ : sN123 ∪ sN4  ≡ sN1234
  u31₂ : sN234 ∪ sN0  ≡ sN2340
  u31₃ : sN340 ∪ sN1  ≡ sN3401
  u31₄ : sN401 ∪ sN2  ≡ sN4012


-- ════════════════════════════════════════════════════════════════════
--  subadditivity — S(A ∪ B) ≤ S(A) + S(B) for every union triple
-- ════════════════════════════════════════════════════════════════════
--
--  The proof proceeds by exhaustive pattern match on the union
--  witness.  Each case reduces to one of 4 concrete ℕ inequalities:
--
--    (0 , refl)  :  2 ≤ 2   [1+1 → 2 : singleton ∪ singleton]
--    (1 , refl)  :  2 ≤ 3   [1+2 or 2+1 → 3 : mixed sizes]
--    (2 , refl)  :  1 ≤ 3   [1+2 or 2+1 → 3 : into quadruple]
--    (3 , refl)  :  1 ≤ 4   [2+2 → 4 : pair ∪ pair]
--
--  In every case, the second component is  refl  because  k + m
--  computes judgmentally to  n  (definitional reduction of  _+_
--  on ℕ by recursion on the first argument).
--
--  This proof matches the 30/30 subadditivity check performed by
--  01_happy_patch_cuts.py on the 6-tile star patch.
-- ════════════════════════════════════════════════════════════════════

subadditivity :
  ∀ {r₁ r₂ r₃ : StarRegion}
  → r₁ ∪ r₂ ≡ r₃
  → S-star r₃ ≤ℚ (S-star r₁ +ℚ S-star r₂)

-- ── lenA = 1, lenB = 1:  S(pair) = 2  ≤  S(1) + S(1) = 2 ──────
subadditivity u11₀ = 0 , refl     -- 2 ≤ 1 + 1 = 2
subadditivity u11₁ = 0 , refl
subadditivity u11₂ = 0 , refl
subadditivity u11₃ = 0 , refl
subadditivity u11₄ = 0 , refl

-- ── lenA = 1, lenB = 2:  S(triple) = 2  ≤  S(1) + S(2) = 3 ────
subadditivity u12₀ = 1 , refl     -- 2 ≤ 1 + 2 = 3
subadditivity u12₁ = 1 , refl
subadditivity u12₂ = 1 , refl
subadditivity u12₃ = 1 , refl
subadditivity u12₄ = 1 , refl

-- ── lenA = 1, lenB = 3:  S(quad) = 1  ≤  S(1) + S(3) = 3 ──────
subadditivity u13₀ = 2 , refl     -- 1 ≤ 1 + 2 = 3
subadditivity u13₁ = 2 , refl
subadditivity u13₂ = 2 , refl
subadditivity u13₃ = 2 , refl
subadditivity u13₄ = 2 , refl

-- ── lenA = 2, lenB = 1:  S(triple) = 2  ≤  S(2) + S(1) = 3 ────
subadditivity u21₀ = 1 , refl     -- 2 ≤ 2 + 1 = 3
subadditivity u21₁ = 1 , refl
subadditivity u21₂ = 1 , refl
subadditivity u21₃ = 1 , refl
subadditivity u21₄ = 1 , refl

-- ── lenA = 2, lenB = 2:  S(quad) = 1  ≤  S(2) + S(2) = 4 ──────
subadditivity u22₀ = 3 , refl     -- 1 ≤ 2 + 2 = 4
subadditivity u22₁ = 3 , refl
subadditivity u22₂ = 3 , refl
subadditivity u22₃ = 3 , refl
subadditivity u22₄ = 3 , refl

-- ── lenA = 3, lenB = 1:  S(quad) = 1  ≤  S(3) + S(1) = 3 ──────
subadditivity u31₀ = 2 , refl     -- 1 ≤ 2 + 1 = 3
subadditivity u31₁ = 2 , refl
subadditivity u31₂ = 2 , refl
subadditivity u31₃ = 2 , refl
subadditivity u31₄ = 2 , refl


-- ════════════════════════════════════════════════════════════════════
--  Summary
-- ════════════════════════════════════════════════════════════════════
--
--  This module verifies the following claims from Phase 1.2:
--
--  1.  The _∪_≡_ relation exhaustively encodes all 30 valid
--      adjacent-region union triples for the 6-tile star's cyclic
--      boundary (5 starting positions × 6 (lenA, lenB) classes).
--
--  2.  The min-cut entropy functional S-star is subadditive on
--      every union triple: S(A∪B) ≤ S(A) + S(B).
--
--  3.  The ≤ℚ proposition  m ≤ℚ n = Σ ℕ (λ k → k + m ≡ n)  is
--      satisfied by  (k , refl)  in every concrete case, because
--      ℕ addition computes judgmentally.  The 4 distinct witnesses:
--
--        (0 , refl)  for  2 ≤ 2      (5 cases)
--        (1 , refl)  for  2 ≤ 3      (10 cases)
--        (2 , refl)  for  1 ≤ 3      (10 cases)
--        (3 , refl)  for  1 ≤ 4      (5 cases)
--
--      cover all 30 subadditivity obligations.
--
--  This file serves as the verified template for the exporter
--  (see docs/09-happy-instance.md §14, Phase A, and the Next Steps
--  note on writing the string-formatting loop in
--  01_happy_patch_cuts.py).
-- ════════════════════════════════════════════════════════════════════