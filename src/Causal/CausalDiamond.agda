{-# OPTIONS --cubical --safe --guardedness #-}

module Causal.CausalDiamond where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; zero ; suc ; _+_)

open import Util.Scalars

open import Bridge.BridgeWitness
  using (BridgeWitness)
open import Bridge.SchematicTower
  using ( TowerLevel ; LayerStep
        ; layer54d2-level ; layer54d3-level ; layer54d4-level
        ; layer54d5-level ; layer54d6-level ; layer54d7-level
        ; d100-tower-level ; d200-tower-level
        ; step-d2→d3 ; step-d3→d4 ; step-d4→d5
        ; step-d5→d6 ; step-d6→d7
        ; d100→d200 )


-- ════════════════════════════════════════════════════════════════════
--  §1.  CausalExtension — Type alias for LayerStep
-- ════════════════════════════════════════════════════════════════════
--
--  A single time-step in the causal poset, witnessing that the
--  holographic depth (maxCut) is non-decreasing.  This is
--  syntactically identical to  LayerStep  from
--  Bridge/SchematicTower.agda — a  CausalExtension lo hi  is a
--  record with field  monotone : maxCut lo ≤ℚ maxCut hi .
--
--  In the physics interpretation, each CausalExtension is one
--  Pachner move: it adds one BFS layer to the {5,4} tiling,
--  producing a new verified spatial slice at depth n+1 from the
--  slice at depth n.
--
--  Reference:
--    docs/10-frontier.md §12.4  (New Types — CausalExtension)
--    docs/10-frontier.md §12.6  (Pachner Moves and Time Evolution)
-- ════════════════════════════════════════════════════════════════════

CausalExtension : TowerLevel → TowerLevel → Type₀
CausalExtension = LayerStep


-- ════════════════════════════════════════════════════════════════════
--  §2.  CausalDiamond — A finite causal interval [t₁, t₂]
-- ════════════════════════════════════════════════════════════════════
--
--  A CausalDiamond packages a non-empty sequence of verified
--  spatial slices (TowerLevels) connected by future-directed
--  causal extensions (LayerSteps).
--
--  The data type is defined mutually with  diamond-top , which
--  extracts the topmost (most recent) slice.  The  extend
--  constructor requires a LayerStep from the current top to the
--  new level, enforcing monotonicity at every step by construction.
--
--  Constructors:
--
--    base t    — a diamond of depth 0 (one slice, no extensions).
--               Represents a single spatial snapshot at one time.
--
--    extend d hi s  — extend diamond  d  by one step to level  hi ,
--               with  s : LayerStep (diamond-top d) hi  witnessing
--               that the holographic depth does not decrease.
--
--  This is the "snoc-style" extension: new slices are appended at
--  the future end of the diamond, matching the natural order of
--  time evolution ("extending the causal history by one tick").
--
--  The data type lives in  Type₁  because  TowerLevel  stores
--  types (OrbitReducedPatch, BridgeWitness) as fields.
--
--  Reference:
--    docs/10-frontier.md §12.4  (New Types — CausalDiamond)
--    docs/10-frontier.md §12.6  (Pachner Moves and Time Evolution)
--    docs/10-frontier.md §12.12 (Phase H.0 — CausalDiamond packaging)
-- ════════════════════════════════════════════════════════════════════

-- ── Forward declarations (mutual recursion) ────────────────────────
--
--  diamond-top  is used in the type of the  extend  constructor,
--  creating a mutual dependency between the data type and the
--  function.  Agda resolves this via forward declaration: the
--  type signature of  diamond-top  is given before the data
--  constructors, and its definition follows after.

data CausalDiamond : Type₁

diamond-top : CausalDiamond → TowerLevel

-- ── Data constructors ──────────────────────────────────────────────

data CausalDiamond where
  base   : TowerLevel → CausalDiamond
  extend : (d : CausalDiamond) (hi : TowerLevel)
         → LayerStep (diamond-top d) hi → CausalDiamond

-- ── diamond-top definition ─────────────────────────────────────────
--
--  The topmost (latest-time) slice of the diamond.
--  For  base t , this is  t  itself.
--  For  extend d hi _ , this is  hi  (the newly appended level).

diamond-top (base t)        = t
diamond-top (extend _ hi _) = hi


-- ════════════════════════════════════════════════════════════════════
--  §3.  Basic diamond operations
-- ════════════════════════════════════════════════════════════════════

-- ── diamond-base — The bottom (earliest-time) slice ────────────────

diamond-base : CausalDiamond → TowerLevel
diamond-base (base t)        = t
diamond-base (extend d _ _)  = diamond-base d

-- ── n-slices — Number of spatial slices in the diamond ─────────────
--
--  A  base  has 1 slice; each  extend  adds 1.

n-slices : CausalDiamond → ℕ
n-slices (base _)        = 1
n-slices (extend d _ _)  = suc (n-slices d)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Proper Time — Chain length in the stratified tower
-- ════════════════════════════════════════════════════════════════════
--
--  The proper time of a CausalDiamond is the number of causal
--  extensions (LayerSteps) it contains.  In the stratified tower,
--  every maximal causal chain between levels n and m has length
--  m − n, so the proper time equals  n-slices − 1 .
--
--  In the physics interpretation: each causal extension is one
--  "tick" of the discrete clock.  The proper time counts these
--  ticks — the total elapsed time from the earliest to the latest
--  spatial slice.
--
--  This is always one less than the number of slices:
--    proper-time d  =  n-slices d ∸ 1
--
--  Reference:
--    docs/10-frontier.md §12.7  (Proper Time as Chain Length)
--    docs/10-frontier.md §12.12 (Phase H.4 — Proper time verification)
-- ════════════════════════════════════════════════════════════════════

proper-time : CausalDiamond → ℕ
proper-time (base _)        = 0
proper-time (extend d _ _)  = suc (proper-time d)


-- ════════════════════════════════════════════════════════════════════
--  §5.  Maximum on ℕ (local utility)
-- ════════════════════════════════════════════════════════════════════
--
--  Defined by structural recursion on both arguments, ensuring
--  judgmental computation on closed numerals.  Used by  maximin .
--
--    max-ℕ 0 n = n
--    max-ℕ m 0 = m
--    max-ℕ (suc m) (suc n) = suc (max-ℕ m n)
--
--  Key computation traces:
--    max-ℕ 2 2 = suc (suc (max-ℕ 0 0)) = suc (suc 0) = 2
--    max-ℕ 8 9 = suc (max-ℕ 7 8) = ... = suc^8 (max-ℕ 0 1) = 9
-- ════════════════════════════════════════════════════════════════════

private
  max-ℕ : ℕ → ℕ → ℕ
  max-ℕ zero    n       = n
  max-ℕ (suc m) zero    = suc m
  max-ℕ (suc m) (suc n) = suc (max-ℕ m n)


-- ════════════════════════════════════════════════════════════════════
--  §6.  Maximin — Covariant holographic entanglement entropy
-- ════════════════════════════════════════════════════════════════════
--
--  The maximin construction (Wall 2012, discrete version):
--
--    S_cov(A) = max_Σ  MinCut_Σ(A, Ā)
--
--  where Σ ranges over spatial slices (antichains).  The inner
--  minimization is the standard spatial RT formula — exactly what
--  S-cut computes for each PatchData.  The outer maximization
--  selects the slice with the deepest cut.
--
--  In the monotone tower, the LayerStep.monotone witnesses
--  guarantee that  maxCut  is non-decreasing, so the maximum is
--  always realized at the deepest (topmost) slice.  The maximin
--  functional verifies this by folding  max-ℕ  over all slices.
--
--  For a base diamond (single slice):
--    maximin (base t) = maxCut t
--
--  For an extended diamond:
--    maximin (extend d hi _) = max-ℕ (maximin d) (maxCut hi)
--
--  In the monotone case this reduces to  maxCut hi  (the top),
--  but the definition is correct for non-monotone diamonds too.
--
--  Reference:
--    docs/10-frontier.md §12.3  (The Lorentzian Inversion: Maximin)
--    docs/10-frontier.md §12.12 (Phase H.1 — Maximin computation)
-- ════════════════════════════════════════════════════════════════════

maximin : CausalDiamond → ℚ≥0
maximin (base t)        = TowerLevel.maxCut t
maximin (extend d hi _) = max-ℕ (maximin d) (TowerLevel.maxCut hi)


-- ════════════════════════════════════════════════════════════════════
--  §7.  {5,4} Layer Tower Diamond (6 slices, depths 2–7)
-- ════════════════════════════════════════════════════════════════════
--
--  The {5,4} BFS-layer tower from Bridge/SchematicTower.agda,
--  repackaged as a CausalDiamond.  This is the discrete spacetime
--  of §12.2: 6 verified spatial slices connected by 5 future-
--  directed causal extensions.
--
--  Each slice carries:
--    • An OrbitReducedPatch (the spatial geometry at that depth)
--    • A BridgeWitness (the verified holographic correspondence)
--    • A maxCut value (the holographic depth = 2 for all layers)
--
--  Each extension carries:
--    • A monotonicity witness: maxCut(depth n) ≤ maxCut(depth n+1)
--      For the {5,4} tower, all maxCuts are 2, so monotone = (0, refl).
--
--  Tower structure:
--
--    depth 2 ──▶ depth 3 ──▶ depth 4 ──▶ depth 5 ──▶ depth 6 ──▶ depth 7
--    (21 tiles)  (61 tiles)  (166 tiles) (441 tiles) (1161 tiles) (3046 tiles)
--    maxCut=2    maxCut=2    maxCut=2    maxCut=2    maxCut=2     maxCut=2
--
--  Each arrow is one Pachner move (one BFS expansion layer).
--
--  Reference:
--    docs/10-frontier.md §12.6  (Pachner Moves and Time Evolution)
--    docs/10-frontier.md §12.12 (Phase H.0, H.1, H.4)
-- ════════════════════════════════════════════════════════════════════

layer54-diamond : CausalDiamond
layer54-diamond =
  extend
    (extend
      (extend
        (extend
          (extend
            (base layer54d2-level)
            layer54d3-level step-d2→d3)
          layer54d4-level step-d3→d4)
        layer54d5-level step-d4→d5)
      layer54d6-level step-d5→d6)
    layer54d7-level step-d6→d7


-- ════════════════════════════════════════════════════════════════════
--  §8.  Dense Resolution Tower Diamond (2 slices)
-- ════════════════════════════════════════════════════════════════════
--
--  The Dense-100 → Dense-200 resolution tower from
--  Bridge/SchematicTower.agda, repackaged as a CausalDiamond.
--
--  This represents a "temporal" step where the spatial resolution
--  increases: the patch grows from 100 to 200 cells, and the
--  max min-cut grows from 8 to 9.
--
--  Tower structure:
--
--    Dense-100 ──▶ Dense-200
--    (100 cells)   (200 cells)
--    maxCut=8      maxCut=9
--
--  The monotonicity witness is  (1, refl)  because  1 + 8 = 9
--  judgmentally.
--
--  Reference:
--    docs/10-frontier.md §12.12 (Phase H.0, H.1, H.4)
-- ════════════════════════════════════════════════════════════════════

dense-diamond : CausalDiamond
dense-diamond = extend (base d100-tower-level) d200-tower-level d100→d200


-- ════════════════════════════════════════════════════════════════════
--  §9.  Maximin Verification
-- ════════════════════════════════════════════════════════════════════
--
--  Phase H.1 (§12.12):  maximin type-checks and reduces to the
--  correct ℕ literal on each instantiated diamond.
--
--  {5,4} tower:  all maxCuts are 2, so  max-ℕ 2 2 = 2  at every
--  step.  maximin = 2.
--
--  Dense tower:  max-ℕ 8 9 = 9  (structural recursion on closed
--  numerals: suc^8(max-ℕ 0 1) = suc^8(1) = 9).
-- ════════════════════════════════════════════════════════════════════

-- All {5,4} layers have maxCut = 2.
-- maximin = max 2 (max 2 (max 2 (max 2 (max 2 2)))) = 2
maximin-layer54 : maximin layer54-diamond ≡ 2
maximin-layer54 = refl

-- Dense-100 maxCut = 8, Dense-200 maxCut = 9.
-- maximin = max 8 9 = 9
maximin-dense : maximin dense-diamond ≡ 9
maximin-dense = refl


-- ════════════════════════════════════════════════════════════════════
--  §10.  Proper Time Verification
-- ════════════════════════════════════════════════════════════════════
--
--  Phase H.4 (§12.12):  proper time through the {5,4} tower
--  diamond is 5 (= 6 slices − 1 = depths 7 − 2).  For the Dense
--  tower: proper time = 1 (one step, Dense-100 → Dense-200).
--
--  Each proof is  refl  on closed ℕ terms because  proper-time
--  counts  extend  constructors by structural recursion.
-- ════════════════════════════════════════════════════════════════════

-- 6 slices, 5 extensions → proper time = 5
proper-time-layer54 : proper-time layer54-diamond ≡ 5
proper-time-layer54 = refl

-- 2 slices, 1 extension → proper time = 1
proper-time-dense : proper-time dense-diamond ≡ 1
proper-time-dense = refl


-- ════════════════════════════════════════════════════════════════════
--  §11.  Slice Count Verification
-- ════════════════════════════════════════════════════════════════════

n-slices-layer54 : n-slices layer54-diamond ≡ 6
n-slices-layer54 = refl

n-slices-dense : n-slices dense-diamond ≡ 2
n-slices-dense = refl


-- ════════════════════════════════════════════════════════════════════
--  §12.  Diamond Endpoint Verification
-- ════════════════════════════════════════════════════════════════════
--
--  Verify that diamond-base and diamond-top return the expected
--  tower levels for both concrete diamonds.
-- ════════════════════════════════════════════════════════════════════

-- {5,4} tower: base is depth 2, top is depth 7
layer54-base : diamond-base layer54-diamond ≡ layer54d2-level
layer54-base = refl

layer54-top : diamond-top layer54-diamond ≡ layer54d7-level
layer54-top = refl

-- Dense tower: base is Dense-100, top is Dense-200
dense-base : diamond-base dense-diamond ≡ d100-tower-level
dense-base = refl

dense-top : diamond-top dense-diamond ≡ d200-tower-level
dense-top = refl


-- ════════════════════════════════════════════════════════════════════
--  §13.  maxCut Endpoint Checks
-- ════════════════════════════════════════════════════════════════════
--
--  These regression tests verify that the maxCut values at the
--  base and top of each diamond are the expected ℕ literals.
-- ════════════════════════════════════════════════════════════════════

private
  -- {5,4} tower: maxCut = 2 everywhere
  check-layer54-base-maxCut :
    TowerLevel.maxCut (diamond-base layer54-diamond) ≡ 2
  check-layer54-base-maxCut = refl

  check-layer54-top-maxCut :
    TowerLevel.maxCut (diamond-top layer54-diamond) ≡ 2
  check-layer54-top-maxCut = refl

  -- Dense tower: maxCut grows from 8 to 9
  check-dense-base-maxCut :
    TowerLevel.maxCut (diamond-base dense-diamond) ≡ 8
  check-dense-base-maxCut = refl

  check-dense-top-maxCut :
    TowerLevel.maxCut (diamond-top dense-diamond) ≡ 9
  check-dense-top-maxCut = refl

  -- max-ℕ regression tests
  check-max-2-2 : max-ℕ 2 2 ≡ 2
  check-max-2-2 = refl

  check-max-8-9 : max-ℕ 8 9 ≡ 9
  check-max-8-9 = refl

  check-max-9-8 : max-ℕ 9 8 ≡ 9
  check-max-9-8 = refl

  check-max-0-5 : max-ℕ 0 5 ≡ 5
  check-max-0-5 = refl


-- ════════════════════════════════════════════════════════════════════
--  §14.  Maximin at the Top — Monotone tower property
-- ════════════════════════════════════════════════════════════════════
--
--  For both concrete diamonds, the maximin equals the maxCut at
--  the top level.  This is a consequence of the monotonicity
--  witnesses carried by the LayerStep fields: since maxCut is
--  non-decreasing, the maximum is always realized at the top.
--
--  These proofs hold by  refl  because the ℕ computation fully
--  reduces on closed terms.  A general proof for arbitrary
--  monotone diamonds would require induction on the diamond
--  structure and the monotonicity witnesses — this is left as
--  a straightforward exercise (the concrete verification is
--  sufficient for the exit criteria).
-- ════════════════════════════════════════════════════════════════════

maximin-equals-top-layer54 :
  maximin layer54-diamond ≡ TowerLevel.maxCut (diamond-top layer54-diamond)
maximin-equals-top-layer54 = refl

maximin-equals-top-dense :
  maximin dense-diamond ≡ TowerLevel.maxCut (diamond-top dense-diamond)
maximin-equals-top-dense = refl


-- ════════════════════════════════════════════════════════════════════
--  §15.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    CausalExtension : TowerLevel → TowerLevel → Type₀
--                      (type alias for LayerStep)
--
--    CausalDiamond   : Type₁
--                      (data type: base | extend)
--    diamond-top     : CausalDiamond → TowerLevel
--    diamond-base    : CausalDiamond → TowerLevel
--    n-slices        : CausalDiamond → ℕ
--    proper-time     : CausalDiamond → ℕ
--    maximin         : CausalDiamond → ℚ≥0
--
--    layer54-diamond : CausalDiamond  (6 slices, depths 2–7)
--    dense-diamond   : CausalDiamond  (2 slices, Dense-100→200)
--
--    maximin-layer54         : maximin layer54-diamond ≡ 2
--    maximin-dense           : maximin dense-diamond ≡ 9
--    proper-time-layer54     : proper-time layer54-diamond ≡ 5
--    proper-time-dense       : proper-time dense-diamond ≡ 1
--    n-slices-layer54        : n-slices layer54-diamond ≡ 6
--    n-slices-dense          : n-slices dense-diamond ≡ 2
--    maximin-equals-top-layer54 : maximin = maxCut at top
--    maximin-equals-top-dense   : maximin = maxCut at top
--
--  Architecture:
--
--    The CausalDiamond is a NEW WRAPPER LAYER over the existing
--    SchematicTower infrastructure.  No existing module is modified.
--    The causal structure reinterprets the tower data through a
--    Lorentzian lens:
--
--      TowerLevel           ↔  spatial slice (antichain)
--      LayerStep            ↔  CausalExtension (future-directed step)
--      extend               ↔  Pachner move (BFS expansion)
--      diamond-top          ↔  latest spatial slice
--      maximin              ↔  covariant holographic entropy
--      proper-time          ↔  elapsed time (chain length)
--
--  The mutual recursion between  CausalDiamond  and  diamond-top
--  ensures that each  extend  step is type-correct: the  LayerStep
--  must connect the current top to the new level.  This is the
--  type-level enforcement of the causal arrow of time.
--
--  Exit criteria (§12.13 of docs/10-frontier.md):
--
--    1. ✓  A CausalDiamond record type-checks, instantiated for
--          the {5,4} layer tower (6 slices) and the Dense
--          resolution tower (2 slices).
--
--    2. ✓  The maximin function type-checks and reduces to the
--          correct ℕ literal on each instantiated diamond:
--            maximin layer54-diamond = 2
--            maximin dense-diamond   = 9
--
--  Downstream modules:
--
--    src/Causal/NoCTC.agda     — Structural acyclicity proof
--    src/Causal/LightCone.agda — FutureCone, spacelike-separation
--
--  Reference:
--    docs/10-frontier.md §12    (The Causal Light Cone)
--    docs/10-frontier.md §12.2  (The Tower IS the Spacetime)
--    docs/10-frontier.md §12.3  (Maximin)
--    docs/10-frontier.md §12.4  (New Types)
--    docs/10-frontier.md §12.7  (Proper Time as Chain Length)
--    docs/10-frontier.md §12.11 (New Module Plan)
--    docs/10-frontier.md §12.12 (Execution Plan)
--    docs/10-frontier.md §12.13 (Exit Criterion)
-- ════════════════════════════════════════════════════════════════════