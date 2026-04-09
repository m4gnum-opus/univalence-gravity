{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.DeSitterGaussBonnet where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat  using (ℕ ; _+_)
open import Cubical.Data.Int  using (ℤ ; pos ; negsuc)

open import Util.Rationals
open import Bulk.DeSitterPatchComplex
open import Bulk.DeSitterCurvature

-- ════════════════════════════════════════════════════════════════════
--  Discrete Gauss–Bonnet Theorem for the 6-Face {5,3} Star Patch
-- ════════════════════════════════════════════════════════════════════
--
--  This module provides the polished theorem statement and milestone
--  packaging for the de Sitter (dS) Gauss–Bonnet theorem: the
--  combinatorial curvature sum over the 6-face star patch of the
--  {5,3} spherical tiling equals the Euler characteristic χ(K) = 1.
--
--  This is the dS counterpart of Bulk/GaussBonnet.agda (which proves
--  the AdS Gauss–Bonnet for the {5,4} tiling).  The two theorems
--  share the same Euler characteristic (χ = 1, disk topology) and
--  the same proof technique (class-weighted refl), but differ in:
--
--    • The number of vertex classes:  3 (dS) vs 5 (AdS)
--    • The sign of interior curvature:  +1/10 (dS) vs −1/5 (AdS)
--    • The interior/boundary decomposition:
--        dS:   (+5/10) + (+5/10) = 10/10
--        AdS:  (−10/10) + (+20/10) = 10/10
--
--  The positive interior curvature is the defining characteristic of
--  the de Sitter (spherical) regime.  The curvature sign flip is the
--  combinatorial analogue of the cosmological constant sign flip
--  Λ_AdS < 0 → Λ_dS > 0.
--
--  Module dependencies:
--
--    Util/Rationals.agda                — ℚ₁₀ = ℤ, arithmetic, constants
--    Bulk/DeSitterPatchComplex.agda     — DSVClass, dsVCount, topology
--    Bulk/DeSitterCurvature.agda        — dsκ-class, dsTotalCurvature,
--                                         dsTotalCurvature≡χ
--
--  Mathematical references:
--    §7.4.4 of docs/10-frontier.md    (curvature comparison)
--    §7.5.1 of docs/10-frontier.md    (Component 2: dS Gauss–Bonnet)
--    sim/prototyping/10_desitter_prototype.py  (Python prototype)
--
--  Exit criterion (§7.13 of docs/10-frontier.md):
--    "An Agda module Bulk/DeSitterGaussBonnet.agda proves discrete
--     Gauss–Bonnet for the {5,3} star patch with positive interior
--     curvature, discharged by refl."
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Euler characteristic — ℕ and ℚ₁₀ representations
-- ════════════════════════════════════════════════════════════════════
--
--  The Euler characteristic of the 6-face {5,3} star patch is
--
--      χ(K) = V − E + F = 15 − 20 + 6 = 1
--
--  Since ℕ has no subtraction, DeSitterPatchComplex states this as
--  the additive identity  V + F = E + χ ,  i.e.  15 + 6 = 20 + 1 = 21.
--
--  In the ℚ₁₀ representation (where the integer n represents the
--  rational n/10), the Euler characteristic χ = 1 is encoded as
--  one₁₀ = pos 10 = 10/10.  The Gauss–Bonnet theorem then states
--  that the curvature sum (also in tenths) equals pos 10.
-- ════════════════════════════════════════════════════════════════════

-- The Euler characteristic as a natural number.
dsχ-ℕ : ℕ
dsχ-ℕ = 1

-- ────────────────────────────────────────────────────────────────
--  Euler identity:  V + F = E + χ
--  15 + 6 = 21 = 20 + 1
--
--  Re-exported from DeSitterPatchComplex with explicit χ naming.
-- ────────────────────────────────────────────────────────────────

dsχ-euler : dsTotalV + dsTotalF ≡ dsTotalE + dsχ-ℕ
dsχ-euler = ds-euler-char

-- ────────────────────────────────────────────────────────────────
--  Euler characteristic in the ℚ₁₀ encoding.
--
--  χ = 1  is encoded as  10/10 = pos 10 = one₁₀ .
--
--  This is the target value of the dS Gauss–Bonnet sum.
-- ────────────────────────────────────────────────────────────────

dsχ₁₀ : ℚ₁₀
dsχ₁₀ = one₁₀

-- ────────────────────────────────────────────────────────────────
--  Encoding consistency:  dsχ₁₀  faithfully represents  dsχ-ℕ .
--
--  The ℚ₁₀ encoding of a natural number n is  10 · n  in tenths.
--  For n = 1:  10 ·₁₀ pos 1  reduces to  pos 10 = one₁₀ = dsχ₁₀ .
-- ────────────────────────────────────────────────────────────────

dsχ₁₀-encodes-χ : dsχ₁₀ ≡ 10 ·₁₀ pos dsχ-ℕ
dsχ₁₀-encodes-χ = refl


-- ════════════════════════════════════════════════════════════════════
--  §2.  Discrete Gauss–Bonnet theorem  (dS — Theorem 1 analogue)
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Discrete Gauss–Bonnet, combinatorial form, dS).
--
--  For the 6-face star patch K of the {5,3} spherical tiling
--  with combinatorial curvature  dsκ : DSVertex → ℚ₁₀ :
--
--      Σ_v dsκ(v)  =  χ(K)
--
--  In the classified ℚ₁₀ representation:
--
--      Σ_{cl ∈ DSVClass}  dsVCount(cl) · dsκ-class(cl)  =  one₁₀
--
--  Expansion (3-class grouping):
--
--    Class       Count   κ (tenths)   Contribution
--    ────────    ─────   ──────────   ────────────
--    dsTiling      5       +1              +5
--    dsSharedW     5       −1              −5
--    dsOuterB      5       +2             +10
--                 ──                      ──
--                 15                      10  = one₁₀ = χ(K)
--
--  The proof is  refl  because all operations (dsVCount, dsκ-class,
--  _·₁₀_, _+₁₀_) compute by structural recursion on closed
--  constructor terms, and the ℤ normalizer reduces the entire
--  expression to  pos 10 .
--
--  This is the dS analogue of Phase 2B.3 (docs/05-roadmap.md),
--  and corresponds to Component 2 of the discrete Wick rotation
--  theorem (§7.5.1 of docs/10-frontier.md).
--
--  Verified numerically by
--  sim/prototyping/10_desitter_prototype.py §8:
--    5·(+1) + 5·(−1) + 5·(+2) = 5 − 5 + 10 = 10 = one₁₀  ✓
-- ════════════════════════════════════════════════════════════════════

ds-discrete-gauss-bonnet : dsTotalCurvature ≡ dsχ₁₀
ds-discrete-gauss-bonnet = dsTotalCurvature≡χ


-- ════════════════════════════════════════════════════════════════════
--  §3.  Interior / boundary curvature decomposition
-- ════════════════════════════════════════════════════════════════════
--
--  The total curvature decomposes into an interior contribution
--  (from the 5 tiling vertices dsv₀..dsv₄ of class dsTiling) and
--  a boundary contribution (from the 10 boundary vertices of the
--  remaining 2 classes).
--
--  This decomposition makes the geometric contrast with AdS visible:
--
--    • dS  interior curvature:  +5/10  = +1/2  (POSITIVE — spherical)
--    • AdS interior curvature:  −10/10 = −1    (negative — hyperbolic)
--
--    • dS  boundary curvature:  +5/10  = +1/2
--    • AdS boundary curvature:  +20/10 = +2
--
--    • Both total:  10/10 = 1 = χ(K)
--
--  The dS decomposition is SYMMETRIC:  interior = boundary = +1/2.
--  The AdS decomposition is ASYMMETRIC: interior = −1, boundary = +2.
--  In both cases, the total equals χ(K) = 1.
--
--  This mirrors the physics: in de Sitter space, the positive
--  cosmological constant distributes curvature evenly, while in
--  Anti-de Sitter space, the negative cosmological constant creates
--  a strong interior deficit that must be compensated by large
--  positive boundary turning.
--
--  NOTE: The names dsInteriorCurvature, dsBoundaryCurvature, and
--  dsTotalCurvature-split are already exported from
--  Bulk/DeSitterCurvature.agda.  This section defines LOCAL
--  shorthands (dsInteriorCurv, dsBoundaryCurv) with distinct names
--  to avoid scope clashes, and prefixes the decomposition lemmas
--  with ds-gb- to distinguish them from the imported versions.
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Interior curvature:  5 tiling vertices × (+1/10) = +5/10
--
--  This is the contribution from the 5 interior vertices of the
--  {5,3} patch.  Each interior vertex has valence 3 in the tiling
--  (3 pentagons meeting), giving combinatorial curvature +1/10
--  per vertex.  The POSITIVE sign confirms the spherical (de Sitter)
--  character of the tiling.
--
--  Compare with AdS ({5,4}):  5 vertices × (−2/10) = −10/10
-- ────────────────────────────────────────────────────────────────

dsInteriorCurv : ℚ₁₀
dsInteriorCurv = dsVCount dsTiling ·₁₀ dsκ-class dsTiling

-- 5 × (+1) = +5  in tenths
dsInteriorCurv-val : dsInteriorCurv ≡ pos 5
dsInteriorCurv-val = refl

-- ────────────────────────────────────────────────────────────────
--  Boundary curvature:  sum over 2 boundary vertex classes
--
--    5 shared-W × (−1)  +  5 outer-B × (+2)
--  = (−5) + 10
--  = 5  in tenths
--
--  Compare with AdS ({5,4}):  (−5) + 10 + (−5) + 20 = 20  in tenths
-- ────────────────────────────────────────────────────────────────

dsBoundaryCurv : ℚ₁₀
dsBoundaryCurv =
    dsVCount dsSharedW ·₁₀ dsκ-class dsSharedW
  +₁₀ dsVCount dsOuterB  ·₁₀ dsκ-class dsOuterB

-- (−5) + 10 = 5  in tenths
dsBoundaryCurv-val : dsBoundaryCurv ≡ pos 5
dsBoundaryCurv-val = refl

-- ────────────────────────────────────────────────────────────────
--  The total curvature splits into interior + boundary.
--
--  Both sides normalize to  pos 10  (= one₁₀ = dsχ₁₀).
--  The proof is  refl  because all subexpressions are closed
--  integer terms that reduce judgmentally.
--
--  Named ds-gb-curvature-split to avoid clashing with the
--  dsTotalCurvature-split imported from DeSitterCurvature.agda
--  (which uses the longer names dsInteriorCurvature /
--  dsBoundaryCurvature).
-- ────────────────────────────────────────────────────────────────

ds-gb-curvature-split :
  dsTotalCurvature ≡ dsInteriorCurv +₁₀ dsBoundaryCurv
ds-gb-curvature-split = refl

-- ────────────────────────────────────────────────────────────────
--  Verification:  (+5) + (+5) = 10 = one₁₀
--
--  Named ds-gb-interior+boundary≡χ to avoid clashing with
--  dsInterior+boundary≡χ imported from DeSitterCurvature.agda.
-- ────────────────────────────────────────────────────────────────

ds-gb-interior+boundary≡χ :
  dsInteriorCurv +₁₀ dsBoundaryCurv ≡ dsχ₁₀
ds-gb-interior+boundary≡χ = refl

-- ────────────────────────────────────────────────────────────────
--  SYMMETRIC decomposition witness:  interior = boundary
--
--  This is unique to de Sitter.  In AdS, interior ≠ boundary.
--  The symmetry reflects the even distribution of positive
--  cosmological curvature in spherical geometry.
-- ────────────────────────────────────────────────────────────────

dsSymmetricSplit : dsInteriorCurv ≡ dsBoundaryCurv
dsSymmetricSplit = refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  DSGaussBonnetWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  This record packages all the data and proofs constituting the
--  dS Gauss–Bonnet theorem into a single inspectable artifact.
--  It mirrors the GaussBonnetWitness from Bulk/GaussBonnet.agda.
--
--  The record captures:
--
--    • Topology:  V, E, F counts and the Euler identity V+F = E+1
--    • Curvature: the total curvature sum (in ℚ₁₀)
--    • Target:    the Euler characteristic (in ℚ₁₀)
--    • Theorem:   curvature sum = Euler characteristic
--
--  This is the dS companion to patch-gb-witness (the AdS witness).
--  Together they form the two curvature inputs to the WickRotation
--  coherence record (Bridge/WickRotation.agda).
-- ════════════════════════════════════════════════════════════════════

record DSGaussBonnetWitness : Type₀ where
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
--  The concrete witness for the 6-face {5,3} star patch.
--
--  All fields are filled from DeSitterPatchComplex and
--  DeSitterCurvature.  The gauss-bonnet field is the core proof:
--    dsTotalCurvature ≡ dsχ₁₀  by  refl  (via ds-discrete-gauss-bonnet).
-- ────────────────────────────────────────────────────────────────

ds-patch-gb-witness : DSGaussBonnetWitness
ds-patch-gb-witness .DSGaussBonnetWitness.V              = dsTotalV
ds-patch-gb-witness .DSGaussBonnetWitness.E              = dsTotalE
ds-patch-gb-witness .DSGaussBonnetWitness.F              = dsTotalF
ds-patch-gb-witness .DSGaussBonnetWitness.euler-identity = ds-euler-char
ds-patch-gb-witness .DSGaussBonnetWitness.curvatureSum   = dsTotalCurvature
ds-patch-gb-witness .DSGaussBonnetWitness.eulerChar₁₀    = dsχ₁₀
ds-patch-gb-witness .DSGaussBonnetWitness.gauss-bonnet   = ds-discrete-gauss-bonnet


-- ════════════════════════════════════════════════════════════════════
--  §5.  Named theorem alias  (for downstream reference)
-- ════════════════════════════════════════════════════════════════════
--
--  The type  DSTheorem1  and its inhabitant  ds-theorem1  provide a
--  stable reference point for the roadmap and documentation.
--  The Bridge/WickRotation.agda module will import  ds-theorem1
--  alongside  theorem1  (from Bulk/GaussBonnet.agda) and the shared
--  bridge equivalence (from Bridge/EnrichedStarEquiv.agda).
--
--  The type is a proposition (it lives in a set type ℚ₁₀ = ℤ,
--  so paths between elements of ℤ are propositions by isSetℤ).
--  This means any two proofs of  DSTheorem1  are equal — there is
--  no spurious higher structure in the theorem statement.
-- ════════════════════════════════════════════════════════════════════

DSTheorem1 : Type₀
DSTheorem1 = dsTotalCurvature ≡ dsχ₁₀

ds-theorem1 : DSTheorem1
ds-theorem1 = ds-discrete-gauss-bonnet


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
dsTotalCurvature-raw : dsTotalCurvature ≡ pos 10
dsTotalCurvature-raw = refl

-- Euler characteristic is literally  pos 10
dsχ₁₀-raw : dsχ₁₀ ≡ pos 10
dsχ₁₀-raw = refl

-- Interior contribution is literally  pos 5  (= 5/10 = +1/2)
dsInterior-raw : dsInteriorCurv ≡ pos 5
dsInterior-raw = refl

-- Boundary contribution is literally  pos 5  (= 5/10 = +1/2)
dsBoundary-raw : dsBoundaryCurv ≡ pos 5
dsBoundary-raw = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Curvature sign comparison with AdS
-- ════════════════════════════════════════════════════════════════════
--
--  The discrete Wick rotation is visible in the curvature sign
--  flip at interior vertices.  This section provides exportable
--  witnesses that the dS interior curvature is POSITIVE, enabling
--  Bridge/WickRotation.agda to contrast it with the NEGATIVE
--  interior curvature of the {5,4} patch.
--
--  Interior curvature comparison:
--
--    {5,4} (AdS):  κ_int = −1/5  = −2/10  = negsuc 1
--    {5,3} (dS):   κ_int = +1/10 = +1/10  = pos 1
--
--  Both patches have χ = 1, so the total curvature is the same.
--  The sign flip at interior vertices is compensated by a different
--  boundary curvature distribution:
--
--    {5,4} (AdS):  interior = −10/10,  boundary = +20/10
--    {5,3} (dS):   interior =  +5/10,  boundary =  +5/10
--
--  This is the combinatorial analogue of the cosmological constant
--  sign flip:  Λ_AdS < 0  →  Λ_dS > 0 .
-- ════════════════════════════════════════════════════════════════════

-- dS interior curvature is POSITIVE:  pos 1  (= +1 in tenths)
dsκ-interior-is-positive : dsκ-class dsTiling ≡ pos 1
dsκ-interior-is-positive = refl

-- dS interior contribution is POSITIVE:  pos 5  (= +5 in tenths)
dsInterior-is-positive : dsInteriorCurv ≡ pos 5
dsInterior-is-positive = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  This module completes Phase E.1 Step 4 of the dS/AdS translator
--  development plan (§7.11 of docs/10-frontier.md) and satisfies
--  the exit criterion from §7.13:
--
--    "An Agda module Bulk/DeSitterGaussBonnet.agda proves discrete
--     Gauss–Bonnet for the {5,3} star patch with positive interior
--     curvature, discharged by refl."
--
--  Proof pipeline:
--
--    DeSitterPatchComplex.agda   defines the 6-face polygon complex
--         │                     (DSVClass, dsVCount, topology)
--         ▼
--    DeSitterCurvature.agda     defines dsκ-class, dsTotalCurvature
--         │                     and verifies dsTotalCurvature≡χ = refl
--         ▼
--    DeSitterGaussBonnet.agda   names dsχ₁₀, states the dS theorem,
--      (this module)            decomposes interior/boundary,
--                               and packages DSGaussBonnetWitness.
--
--  Name clash resolution:
--
--    DeSitterCurvature.agda exports dsTotalCurvature-split and
--    dsInterior+boundary≡χ using the longer names
--    dsInteriorCurvature / dsBoundaryCurvature.  This module
--    defines local shorthands (dsInteriorCurv / dsBoundaryCurv)
--    and prefixes the split lemmas with ds-gb- to avoid the scope
--    clash.  Both versions are definitionally equal (same RHS)
--    and both proofs are refl.
--
--  Exports for Bridge/WickRotation.agda:
--
--    DSGaussBonnetWitness    — the packaging record type
--    ds-patch-gb-witness     — the concrete dS witness
--    DSTheorem1              — the dS theorem type
--    ds-theorem1             — the dS theorem proof
--    dsχ₁₀                   — the Euler characteristic in ℚ₁₀
--    dsInteriorCurv           — interior curvature contribution
--    dsBoundaryCurv           — boundary curvature contribution
--    dsκ-interior-is-positive — witness of positive interior curvature
--
--  Next step:
--
--    Bridge/WickRotation.agda — the "Theory of Everything" coherence
--    record, importing both the AdS Gauss–Bonnet witness
--    (patch-gb-witness from Bulk/GaussBonnet.agda), the dS
--    Gauss–Bonnet witness (ds-patch-gb-witness from this module),
--    and the shared holographic bridge
--    (enriched-equiv from Bridge/EnrichedStarEquiv.agda).
-- ════════════════════════════════════════════════════════════════════