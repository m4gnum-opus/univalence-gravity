{-# OPTIONS --cubical --safe --guardedness #-}
module Bridge.SchematicTower where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Data.Nat using (ℕ ; zero ; suc)
open import Cubical.Data.Sigma using (Σ-syntax)

open import Util.Scalars

open import Bridge.GenericBridge
  using ( PatchData ; OrbitReducedPatch
        ; orbit-to-patch ; orbit-bridge-witness )

open import Bridge.BridgeWitness
  using (BridgeWitness)

open import Bridge.HalfBound
  using (HalfBoundWitness)

-- ════════════════════════════════════════════════════════════════════
--  §1–§24:  ALL EXISTING CONTENT PRESERVED VERBATIM
-- ════════════════════════════════════════════════════════════════════
--
--  (The ~700 lines from §1 through §24 of the current file remain
--   exactly as they are.  Nothing is removed or renamed.  The full
--   content of §1–§24 is elided here for brevity but is unchanged.)
--
--  §1   TowerLevel, mkTowerLevel
--  §2   mkTowerLevel smart constructor
--  §3   LayerStep
--  §4   AreaLawForPatch
--  §5   RichLayerStep
--  §6–§8   Dense-100/200 instances, d100→d200, d100→d200-rich
--  §9–§11  {5,4} layer imports and OrbitReducedPatches
--  §12  TowerLevel instances for {5,4} layers
--  §13  BridgeWitness extraction
--  §14  LayerStep instances for {5,4}
--  §15  Tower packaging (TwoLevelTower, Layer54Tower)
--  §16  ResolutionStep (absorbed from ResolutionTower)
--  §17  Dense ResolutionStep instances
--  §18  ResolutionTower data type
--  §19  Spectrum monotonicity
--  §20  AreaLawLevel
--  §21  ConvergenceCertificate, ConvergenceCertificate3L
--  §22  ContinuumLimitEvidence
--  §23  ResolutionStep regression tests
--  §24  Summary and design notes
--
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
--  §1.  TowerLevel — A single verified holographic slice
-- ════════════════════════════════════════════════════════════════════
--
--  A TowerLevel bundles an oracle-generated OrbitReducedPatch with
--  the fully proof-carrying BridgeWitness extracted from the generic
--  bridge theorem.  The  maxCut  field records the maximum min-cut
--  value among the orbit representatives — the "holographic depth"
--  of this resolution level.
--
--  Reference:
--    docs/formal/11-generic-bridge.md §5  (The SchematicTower
--                                          Infrastructure)
-- ════════════════════════════════════════════════════════════════════

record TowerLevel : Type₁ where
  field
    patch  : OrbitReducedPatch
    maxCut : ℚ≥0
    bridge : BridgeWitness


-- ════════════════════════════════════════════════════════════════════
--  §2.  mkTowerLevel — Smart constructor (forces generic bridge)
-- ════════════════════════════════════════════════════════════════════
--
--  Derives the bridge witness from  orbit-bridge-witness , ensuring
--  topological consistency: every level uses the same generic proof
--  schema, parameterized only by the oracle-generated data.
-- ════════════════════════════════════════════════════════════════════

mkTowerLevel : OrbitReducedPatch → ℚ≥0 → TowerLevel
mkTowerLevel orp mc = record
  { patch  = orp
  ; maxCut = mc
  ; bridge = orbit-bridge-witness orp
  }


-- ════════════════════════════════════════════════════════════════════
--  §3.  LayerStep — Monotonicity between consecutive tower levels
-- ════════════════════════════════════════════════════════════════════

record LayerStep (lo hi : TowerLevel) : Type₀ where
  field
    monotone : TowerLevel.maxCut lo ≤ℚ TowerLevel.maxCut hi


-- ════════════════════════════════════════════════════════════════════
--  §4.  AreaLawForPatch — Discrete isoperimetric inequality
--       tied to a specific PatchData
-- ════════════════════════════════════════════════════════════════════

record AreaLawForPatch (pd : PatchData) : Type₀ where
  field
    area       : PatchData.RegionTy pd → ℚ≥0
    area-bound : (r : PatchData.RegionTy pd) → PatchData.S∂ pd r ≤ℚ area r


-- ════════════════════════════════════════════════════════════════════
--  §5. RichLayerStep
-- ════════════════════════════════════════════════════════════════════

record RichLayerStep (lo hi : TowerLevel) : Type₁ where
  field
    monotone : TowerLevel.maxCut lo ≤ℚ TowerLevel.maxCut hi
    area-law : AreaLawForPatch (orbit-to-patch (TowerLevel.patch hi))


-- ════════════════════════════════════════════════════════════════════
--  §6.  Dense-100 and Dense-200 — Existing orbit-reduced patches
-- ════════════════════════════════════════════════════════════════════
--
--  These are imported from Bridge/GenericValidation.agda, which
--  already constructs OrbitReducedPatch instances from the existing
--  Dense-100 (8 orbits, max S=8) and Dense-200 (9 orbits, max S=9)
--  infrastructure.
-- ════════════════════════════════════════════════════════════════════

open import Bridge.GenericValidation
  using (d100OrbitPatch ; d200OrbitPatch)

d100-tower-level : TowerLevel
d100-tower-level = mkTowerLevel d100OrbitPatch 8

d200-tower-level : TowerLevel
d200-tower-level = mkTowerLevel d200OrbitPatch 9


-- ════════════════════════════════════════════════════════════════════
--  §7.  Dense-100 → Dense-200 Layer Step
-- ════════════════════════════════════════════════════════════════════
--
--  The max min-cut grew from 8 to 9.
--  1 + 8 = 9 judgmentally.
-- ════════════════════════════════════════════════════════════════════

d100→d200 : LayerStep d100-tower-level d200-tower-level
d100→d200 .LayerStep.monotone = 1 , refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Dense-100 → Dense-200 Rich Layer Step  (with area law)
-- ════════════════════════════════════════════════════════════════════

import Boundary.Dense200AreaLaw as D200AL

d100→d200-rich : RichLayerStep d100-tower-level d200-tower-level
d100→d200-rich .RichLayerStep.monotone = 1 , refl
d100→d200-rich .RichLayerStep.area-law = record
  { area       = D200AL.regionArea
  ; area-bound = D200AL.area-law
  }


-- ════════════════════════════════════════════════════════════════════
--  §9.  {5,4} Layer Imports  (Depth 2 through Depth 7)
-- ════════════════════════════════════════════════════════════════════
--
--  Each depth-N patch of the {5,4} hyperbolic pentagonal tiling
--  is generated by sim/prototyping/13_generate_layerN.py and
--  produces 4 Agda modules: Spec, Cut, Chain, Obs.
--
--  Qualified imports prevent name clashes on  S-cut-rep  and
--  L-min-rep  (each depth defines its own versions).
--
--  From 13_generate_layerN_OUTPUT.txt:
--
--    Depth | Tiles | Regions | Orbits | Max S
--    ──────┼───────┼─────────┼────────┼──────
--      2   |   21  |    15   |    2   |   2
--      3   |   61  |    40   |    2   |   2
--      4   |  166  |   105   |    2   |   2
--      5   |  441  |   275   |    2   |   2
--      6   | 1161  |   720   |    2   |   2
--      7   | 3046  |  1885   |    2   |   2
--
--  The exponential boundary growth is the hallmark of hyperbolic
--  geometry: each layer ring adds ~2.6× more tiles than the
--  previous one.  The orbit count stays at 2 (min-cut values
--  are always 1 or 2 for BFS-grown {5,4} patches).
--
--  Reference:
--    docs/instances/layer-54-tower.md   (instance data sheet)
--    docs/engineering/oracle-pipeline.md (script 13)
-- ════════════════════════════════════════════════════════════════════

-- ── Depth 2 ────────────────────────────────────────────────────────
import Common.Layer54d2Spec    as L2S
import Boundary.Layer54d2Cut   as L2Cut
import Bulk.Layer54d2Chain     as L2Chain
import Bridge.Layer54d2Obs     as L2Obs

-- ── Depth 3 ────────────────────────────────────────────────────────
import Common.Layer54d3Spec    as L3S
import Boundary.Layer54d3Cut   as L3Cut
import Bulk.Layer54d3Chain     as L3Chain
import Bridge.Layer54d3Obs     as L3Obs

-- ── Depth 4 ────────────────────────────────────────────────────────
import Common.Layer54d4Spec    as L4S
import Boundary.Layer54d4Cut   as L4Cut
import Bulk.Layer54d4Chain     as L4Chain
import Bridge.Layer54d4Obs     as L4Obs

-- ── Depth 5 ────────────────────────────────────────────────────────
import Common.Layer54d5Spec    as L5S
import Boundary.Layer54d5Cut   as L5Cut
import Bulk.Layer54d5Chain     as L5Chain
import Bridge.Layer54d5Obs     as L5Obs

-- ── Depth 6 ────────────────────────────────────────────────────────
import Common.Layer54d6Spec    as L6S
import Boundary.Layer54d6Cut   as L6Cut
import Bulk.Layer54d6Chain     as L6Chain
import Bridge.Layer54d6Obs     as L6Obs

-- ── Depth 7 ────────────────────────────────────────────────────────
import Common.Layer54d7Spec    as L7S
import Boundary.Layer54d7Cut   as L7Cut
import Bulk.Layer54d7Chain     as L7Chain
import Bridge.Layer54d7Obs     as L7Obs


-- ════════════════════════════════════════════════════════════════════
--  §10.  OrbitReducedPatch instances for each {5,4} layer
-- ════════════════════════════════════════════════════════════════════

-- ── Depth 2:  21 tiles, 15 regions → 2 orbits ─────────────────────

layer54d2-orbit : OrbitReducedPatch
layer54d2-orbit .OrbitReducedPatch.RegionTy  = L2S.Layer54d2Region
layer54d2-orbit .OrbitReducedPatch.OrbitTy   = L2S.Layer54d2OrbitRep
layer54d2-orbit .OrbitReducedPatch.classify  = L2S.classifyLayer54d2
layer54d2-orbit .OrbitReducedPatch.S-rep     = L2Cut.S-cut-rep
layer54d2-orbit .OrbitReducedPatch.L-rep     = L2Chain.L-min-rep
layer54d2-orbit .OrbitReducedPatch.rep-agree = L2Obs.layer54d2-pointwise-rep

-- ── Depth 3:  61 tiles, 40 regions → 2 orbits ─────────────────────

layer54d3-orbit : OrbitReducedPatch
layer54d3-orbit .OrbitReducedPatch.RegionTy  = L3S.Layer54d3Region
layer54d3-orbit .OrbitReducedPatch.OrbitTy   = L3S.Layer54d3OrbitRep
layer54d3-orbit .OrbitReducedPatch.classify  = L3S.classifyLayer54d3
layer54d3-orbit .OrbitReducedPatch.S-rep     = L3Cut.S-cut-rep
layer54d3-orbit .OrbitReducedPatch.L-rep     = L3Chain.L-min-rep
layer54d3-orbit .OrbitReducedPatch.rep-agree = L3Obs.layer54d3-pointwise-rep

-- ── Depth 4:  166 tiles, 105 regions → 2 orbits ───────────────────

layer54d4-orbit : OrbitReducedPatch
layer54d4-orbit .OrbitReducedPatch.RegionTy  = L4S.Layer54d4Region
layer54d4-orbit .OrbitReducedPatch.OrbitTy   = L4S.Layer54d4OrbitRep
layer54d4-orbit .OrbitReducedPatch.classify  = L4S.classifyLayer54d4
layer54d4-orbit .OrbitReducedPatch.S-rep     = L4Cut.S-cut-rep
layer54d4-orbit .OrbitReducedPatch.L-rep     = L4Chain.L-min-rep
layer54d4-orbit .OrbitReducedPatch.rep-agree = L4Obs.layer54d4-pointwise-rep

-- ── Depth 5:  441 tiles, 275 regions → 2 orbits ───────────────────

layer54d5-orbit : OrbitReducedPatch
layer54d5-orbit .OrbitReducedPatch.RegionTy  = L5S.Layer54d5Region
layer54d5-orbit .OrbitReducedPatch.OrbitTy   = L5S.Layer54d5OrbitRep
layer54d5-orbit .OrbitReducedPatch.classify  = L5S.classifyLayer54d5
layer54d5-orbit .OrbitReducedPatch.S-rep     = L5Cut.S-cut-rep
layer54d5-orbit .OrbitReducedPatch.L-rep     = L5Chain.L-min-rep
layer54d5-orbit .OrbitReducedPatch.rep-agree = L5Obs.layer54d5-pointwise-rep

-- ── Depth 6:  1161 tiles, 720 regions → 2 orbits ──────────────────

layer54d6-orbit : OrbitReducedPatch
layer54d6-orbit .OrbitReducedPatch.RegionTy  = L6S.Layer54d6Region
layer54d6-orbit .OrbitReducedPatch.OrbitTy   = L6S.Layer54d6OrbitRep
layer54d6-orbit .OrbitReducedPatch.classify  = L6S.classifyLayer54d6
layer54d6-orbit .OrbitReducedPatch.S-rep     = L6Cut.S-cut-rep
layer54d6-orbit .OrbitReducedPatch.L-rep     = L6Chain.L-min-rep
layer54d6-orbit .OrbitReducedPatch.rep-agree = L6Obs.layer54d6-pointwise-rep

-- ── Depth 7:  3046 tiles, 1885 regions → 2 orbits ─────────────────

layer54d7-orbit : OrbitReducedPatch
layer54d7-orbit .OrbitReducedPatch.RegionTy  = L7S.Layer54d7Region
layer54d7-orbit .OrbitReducedPatch.OrbitTy   = L7S.Layer54d7OrbitRep
layer54d7-orbit .OrbitReducedPatch.classify  = L7S.classifyLayer54d7
layer54d7-orbit .OrbitReducedPatch.S-rep     = L7Cut.S-cut-rep
layer54d7-orbit .OrbitReducedPatch.L-rep     = L7Chain.L-min-rep
layer54d7-orbit .OrbitReducedPatch.rep-agree = L7Obs.layer54d7-pointwise-rep


-- ════════════════════════════════════════════════════════════════════
--  §11.  TowerLevel instances for each {5,4} layer
-- ════════════════════════════════════════════════════════════════════
--
--  Each call to  mkTowerLevel  invokes  orbit-bridge-witness ,
--  which composes  orbit-to-patch  with  GenericEnriched  to
--  produce the full enriched equivalence + Univalence path +
--  verified transport.  No per-layer proof engineering is needed.
--
--  All {5,4} BFS-grown layers have max min-cut = 2.
-- ════════════════════════════════════════════════════════════════════

layer54d2-level : TowerLevel
layer54d2-level = mkTowerLevel layer54d2-orbit 2

layer54d3-level : TowerLevel
layer54d3-level = mkTowerLevel layer54d3-orbit 2

layer54d4-level : TowerLevel
layer54d4-level = mkTowerLevel layer54d4-orbit 2

layer54d5-level : TowerLevel
layer54d5-level = mkTowerLevel layer54d5-orbit 2

layer54d6-level : TowerLevel
layer54d6-level = mkTowerLevel layer54d6-orbit 2

layer54d7-level : TowerLevel
layer54d7-level = mkTowerLevel layer54d7-orbit 2


-- ════════════════════════════════════════════════════════════════════
--  §12.  BridgeWitness extraction — the immutable registry
-- ════════════════════════════════════════════════════════════════════

-- ── Dense patches (3D {4,3,5} honeycomb) ───────────────────────────

dense100-bridge : BridgeWitness
dense100-bridge = TowerLevel.bridge d100-tower-level

dense200-bridge : BridgeWitness
dense200-bridge = TowerLevel.bridge d200-tower-level

-- ── {5,4} tiling layers (2D hyperbolic pentagonal tiling) ──────────

layer54d2-bridge : BridgeWitness
layer54d2-bridge = TowerLevel.bridge layer54d2-level

layer54d3-bridge : BridgeWitness
layer54d3-bridge = TowerLevel.bridge layer54d3-level

layer54d4-bridge : BridgeWitness
layer54d4-bridge = TowerLevel.bridge layer54d4-level

layer54d5-bridge : BridgeWitness
layer54d5-bridge = TowerLevel.bridge layer54d5-level

layer54d6-bridge : BridgeWitness
layer54d6-bridge = TowerLevel.bridge layer54d6-level

layer54d7-bridge : BridgeWitness
layer54d7-bridge = TowerLevel.bridge layer54d7-level


-- ════════════════════════════════════════════════════════════════════
--  §13.  LayerStep instances for the {5,4} tower
-- ════════════════════════════════════════════════════════════════════

step-d2→d3 : LayerStep layer54d2-level layer54d3-level
step-d2→d3 .LayerStep.monotone = 0 , refl

step-d3→d4 : LayerStep layer54d3-level layer54d4-level
step-d3→d4 .LayerStep.monotone = 0 , refl

step-d4→d5 : LayerStep layer54d4-level layer54d5-level
step-d4→d5 .LayerStep.monotone = 0 , refl

step-d5→d6 : LayerStep layer54d5-level layer54d6-level
step-d5→d6 .LayerStep.monotone = 0 , refl

step-d6→d7 : LayerStep layer54d6-level layer54d7-level
step-d6→d7 .LayerStep.monotone = 0 , refl


-- ════════════════════════════════════════════════════════════════════
--  §14.  Tower packaging records
-- ════════════════════════════════════════════════════════════════════

-- ── Two-level Dense tower (Dense-100 → Dense-200) ──────────────────

record TwoLevelTower : Type₁ where
  field
    lo-level  : TowerLevel
    hi-level  : TowerLevel
    step      : LayerStep lo-level hi-level

dense-two-level-tower : TwoLevelTower
dense-two-level-tower .TwoLevelTower.lo-level = d100-tower-level
dense-two-level-tower .TwoLevelTower.hi-level = d200-tower-level
dense-two-level-tower .TwoLevelTower.step     = d100→d200

-- ── Full {5,4} layer tower (depth 2 through 7) ────────────────────

record Layer54Tower : Type₁ where
  field
    level-d2   : TowerLevel
    level-d3   : TowerLevel
    level-d4   : TowerLevel
    level-d5   : TowerLevel
    level-d6   : TowerLevel
    level-d7   : TowerLevel
    step-2→3   : LayerStep level-d2 level-d3
    step-3→4   : LayerStep level-d3 level-d4
    step-4→5   : LayerStep level-d4 level-d5
    step-5→6   : LayerStep level-d5 level-d6
    step-6→7   : LayerStep level-d6 level-d7

layer54-tower : Layer54Tower
layer54-tower .Layer54Tower.level-d2 = layer54d2-level
layer54-tower .Layer54Tower.level-d3 = layer54d3-level
layer54-tower .Layer54Tower.level-d4 = layer54d4-level
layer54-tower .Layer54Tower.level-d5 = layer54d5-level
layer54-tower .Layer54Tower.level-d6 = layer54d6-level
layer54-tower .Layer54Tower.level-d7 = layer54d7-level
layer54-tower .Layer54Tower.step-2→3 = step-d2→d3
layer54-tower .Layer54Tower.step-3→4 = step-d3→d4
layer54-tower .Layer54Tower.step-4→5 = step-d4→d5
layer54-tower .Layer54Tower.step-5→6 = step-d5→d6
layer54-tower .Layer54Tower.step-6→7 = step-d6→d7


-- ════════════════════════════════════════════════════════════════════
--  §15.  TowerLevel / Layer regression tests
-- ════════════════════════════════════════════════════════════════════

private
  check-d100-maxCut : TowerLevel.maxCut d100-tower-level ≡ 8
  check-d100-maxCut = refl

  check-d200-maxCut : TowerLevel.maxCut d200-tower-level ≡ 9
  check-d200-maxCut = refl

  check-d2-maxCut : TowerLevel.maxCut layer54d2-level ≡ 2
  check-d2-maxCut = refl

  check-d3-maxCut : TowerLevel.maxCut layer54d3-level ≡ 2
  check-d3-maxCut = refl

  check-d7-maxCut : TowerLevel.maxCut layer54d7-level ≡ 2
  check-d7-maxCut = refl

  check-dense-monotone : LayerStep.monotone d100→d200 ≡ (1 , refl)
  check-dense-monotone = refl

  check-54-monotone : LayerStep.monotone step-d2→d3 ≡ (0 , refl)
  check-54-monotone = refl

  check-d2-bridge : BridgeWitness
  check-d2-bridge = layer54d2-bridge

  check-d7-bridge : BridgeWitness
  check-d7-bridge = layer54d7-bridge

  check-dense-bridge : BridgeWitness
  check-dense-bridge = dense200-bridge


-- ════════════════════════════════════════════════════════════════════
--  ABSORBED FROM Bridge/ResolutionTower.agda
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  Imports — Dense-100 / Dense-200 Infrastructure for ResolutionStep
-- ════════════════════════════════════════════════════════════════════
--
--  IMPORTANT: Boundary.Dense100AreaLaw is imported QUALIFIED (as
--  D100AL) rather than opened, to avoid clashing the bare name
--  "area-law" with identically-named record fields in FullLayerStep
--  and AreaLawForPatch.

open import Common.Dense100Spec
  using ( D100Region ; D100OrbitRep ; classify100 )
open import Boundary.Dense100Cut
  using ( S-cut-rep )
open import Bridge.Dense100Obs
  using ( d100-pointwise ; S∂D100 ; LBD100 )

import Boundary.Dense100AreaLaw as D100AL

open import Common.Dense200Spec
  using ( D200Region ; D200OrbitRep ; classify200 )

import Boundary.Dense200Cut as D200Cut

open import Bridge.Dense200Obs
  using ( d200-pointwise ; S∂D200 ; LBD200 )


-- ════════════════════════════════════════════════════════════════════
--  §16.  ResolutionStep
-- ════════════════════════════════════════════════════════════════════
--
-- ════════════════════════════════════════════════════════════════════
--  Imports — Dense-100 / Dense-200 Infrastructure for ResolutionStep
--  (repeated from the block above for historical reasons — the
--  duplicated open-imports are harmless in Agda 2.8.0 because
--  the same names are brought into scope again with identical
--  bindings.)
-- ════════════════════════════════════════════════════════════════════

open import Common.Dense100Spec
  using ( D100Region ; D100OrbitRep ; classify100 )
open import Boundary.Dense100Cut
  using ( S-cut-rep )
open import Bridge.Dense100Obs
  using ( d100-pointwise ; S∂D100 ; LBD100 )

-- ← CHANGED: qualified import instead of open import
import Boundary.Dense100AreaLaw as D100AL

open import Common.Dense200Spec
  using ( D200Region ; D200OrbitRep ; classify200 )

import Boundary.Dense200Cut as D200Cut

open import Bridge.Dense200Obs
  using ( d200-pointwise ; S∂D200 ; LBD200 )

--  A resolution step pairs two resolution levels (fine and coarse)
--  with a projection from the finer to the coarser, together with:
--
--    • Observable functions at each level  (S-fine, L-fine, S-coarse)
--    • The RT correspondence at the fine level  (rt-fine)
--    • A placeholder RT at the coarse level  (rt-coarse)
--    • A compatibility witness certifying that the fine-level
--      observable factors through the projection  (compat)
--
--  This is exactly  CoarseGrainWitness  from  Bridge/CoarseGrain.agda
--  augmented with the RT correspondence at the fine level.
--
--  The record lives in  Type₁  because it stores types as fields.
--
--  Reference:
--    docs/formal/09-thermodynamics.md §4  (The Resolution Tower)
--    docs/formal/11-generic-bridge.md §6  (Resolution Steps and
--                                          Convergence Certificates)
-- ════════════════════════════════════════════════════════════════════

record ResolutionStep : Type₁ where
  field
    -- The two resolution levels
    FineRegion   : Type₀
    CoarseRegion : Type₀

    -- Observables at each level
    S-fine       : FineRegion → ℚ≥0
    L-fine       : FineRegion → ℚ≥0
    S-coarse     : CoarseRegion → ℚ≥0

    -- RT correspondence at each level
    rt-fine      : (r : FineRegion) → S-fine r ≡ L-fine r
    rt-coarse    : (o : CoarseRegion) → S-coarse o ≡ S-coarse o

    -- The coarse-graining factorization
    project      : FineRegion → CoarseRegion
    compat       : (r : FineRegion) →
                   S-fine r ≡ S-coarse (project r)


-- ════════════════════════════════════════════════════════════════════
--  §17.  Dense ResolutionStep instances
-- ════════════════════════════════════════════════════════════════════

dense-resolution-step : ResolutionStep
dense-resolution-step .ResolutionStep.FineRegion   = D100Region
dense-resolution-step .ResolutionStep.CoarseRegion = D100OrbitRep
dense-resolution-step .ResolutionStep.S-fine       = S∂D100
dense-resolution-step .ResolutionStep.L-fine       = LBD100
dense-resolution-step .ResolutionStep.S-coarse     = S-cut-rep
dense-resolution-step .ResolutionStep.rt-fine      = d100-pointwise
dense-resolution-step .ResolutionStep.rt-coarse _  = refl
dense-resolution-step .ResolutionStep.project      = classify100
dense-resolution-step .ResolutionStep.compat _     = refl

dense200-resolution-step : ResolutionStep
dense200-resolution-step .ResolutionStep.FineRegion   = D200Region
dense200-resolution-step .ResolutionStep.CoarseRegion = D200OrbitRep
dense200-resolution-step .ResolutionStep.S-fine       = S∂D200
dense200-resolution-step .ResolutionStep.L-fine       = LBD200
dense200-resolution-step .ResolutionStep.S-coarse     = D200Cut.S-cut-rep
dense200-resolution-step .ResolutionStep.rt-fine      = d200-pointwise
dense200-resolution-step .ResolutionStep.rt-coarse _  = refl
dense200-resolution-step .ResolutionStep.project      = classify200
dense200-resolution-step .ResolutionStep.compat _     = refl


-- ════════════════════════════════════════════════════════════════════
--  §18.  ResolutionTower — ℕ-indexed list of resolution steps
-- ════════════════════════════════════════════════════════════════════
--
--  A tower is a sequence of resolution steps indexed by ℕ.  The
--  base case holds a single step; each subsequent step extends the
--  tower.  The index counts the number of  step  constructors used.
--
--  Reference:
--    docs/formal/09-thermodynamics.md §4  (The Resolution Tower)
--    docs/formal/11-generic-bridge.md §6  (Resolution Steps and
--                                          Convergence Certificates)
-- ════════════════════════════════════════════════════════════════════

data ResolutionTower : ℕ → Type₁ where
  base : ResolutionStep → ResolutionTower zero
  step : ∀ {n} → ResolutionStep → ResolutionTower n
       → ResolutionTower (suc n)

single-step-tower : ResolutionTower zero
single-step-tower = base dense-resolution-step

two-step-tower : ResolutionTower (suc zero)
two-step-tower = step dense200-resolution-step single-step-tower


-- ════════════════════════════════════════════════════════════════════
--  §19.  Spectrum monotonicity — The growing min-cut spectrum
-- ════════════════════════════════════════════════════════════════════
--
--  The min-cut spectrum grows monotonically with resolution:
--
--    Dense-50:   max min-cut = 7
--    Dense-100:  max min-cut = 8
--    Dense-200:  max min-cut = 9
--
--  Each transition is a concrete inequality witnessed by (k , refl).
--
--  Reference:
--    docs/formal/09-thermodynamics.md §4  (Spectrum Monotonicity)
--    docs/formal/11-generic-bridge.md §6  (Spectrum Monotonicity)
-- ════════════════════════════════════════════════════════════════════

spectrum-grows-50-100 : 7 ≤ℚ 8
spectrum-grows-50-100 = 1 , refl

spectrum-grows-100-200 : 8 ≤ℚ 9
spectrum-grows-100-200 = 1 , refl


-- ════════════════════════════════════════════════════════════════════
--  §20.  AreaLawLevel — The discrete area law at a single level
-- ════════════════════════════════════════════════════════════════════
--
--  At each finite resolution level, the min-cut entropy is bounded
--  by the boundary surface area of the region:
--
--    S_cut(A)  ≤  area(A)
--
--  This record stores types as fields (RegionTy), so it lives in
--  Type₁.  Compare with  AreaLawForPatch  (§4 above), which is
--  tied to a specific  PatchData  and lives in Type₀.
--
--  Reference:
--    docs/formal/09-thermodynamics.md §3  (The Discrete Area Law)
--    docs/formal/11-generic-bridge.md §6  (AreaLawLevel and
--                                          HalfBoundLevel)
-- ════════════════════════════════════════════════════════════════════

record AreaLawLevel : Type₁ where
  field
    RegionTy     : Type₀
    S-obs        : RegionTy → ℚ≥0
    area         : RegionTy → ℚ≥0
    area-bound   : (r : RegionTy) → S-obs r ≤ℚ area r

dense100-area-law-level : AreaLawLevel
dense100-area-law-level .AreaLawLevel.RegionTy   = D100Region
dense100-area-law-level .AreaLawLevel.S-obs      = S∂D100
dense100-area-law-level .AreaLawLevel.area       = D100AL.regionArea
dense100-area-law-level .AreaLawLevel.area-bound = D100AL.area-law

dense200-area-law-level : AreaLawLevel
dense200-area-law-level .AreaLawLevel.RegionTy   = D200Region
dense200-area-law-level .AreaLawLevel.S-obs      = S∂D200
dense200-area-law-level .AreaLawLevel.area       = D200AL.regionArea
dense200-area-law-level .AreaLawLevel.area-bound = D200AL.area-law


-- ════════════════════════════════════════════════════════════════════
--  §21.  ConvergenceCertificate, ConvergenceCertificate3L
-- ════════════════════════════════════════════════════════════════════
--
--  These records package the complete convergence evidence at
--  different tower heights.  The 2-level certificate is retained
--  for backward compatibility; the 3-level one extends it with
--  Dense-200.
--
--  Reference:
--    docs/formal/09-thermodynamics.md §4  (Resolution Tower and
--                                          Convergence Certificates)
--    docs/formal/11-generic-bridge.md §6  (The 3-Level Convergence
--                                          Certificate)
-- ════════════════════════════════════════════════════════════════════

-- ── 2-level certificate (Dense-50 → Dense-100) ────────────────────

record ConvergenceCertificate : Type₁ where
  field
    resolution       : ResolutionStep
    tower            : ResolutionTower zero
    monotone         : 7 ≤ℚ 8
    area-law-level   : AreaLawLevel

convergence-certificate : ConvergenceCertificate
convergence-certificate .ConvergenceCertificate.resolution     = dense-resolution-step
convergence-certificate .ConvergenceCertificate.tower          = single-step-tower
convergence-certificate .ConvergenceCertificate.monotone       = spectrum-grows-50-100
convergence-certificate .ConvergenceCertificate.area-law-level = dense100-area-law-level

-- ── 3-level certificate (Dense-50 → Dense-100 → Dense-200) ────────

record ConvergenceCertificate3L : Type₁ where
  field
    -- The two resolution steps (orbit reductions at each level)
    step-100         : ResolutionStep
    step-200         : ResolutionStep

    -- The 2-step resolution tower packaging both steps
    tower            : ResolutionTower (suc zero)

    -- Monotonicity: the max min-cut grows between consecutive levels
    monotone-50-100  : 7 ≤ℚ 8
    monotone-100-200 : 8 ≤ℚ 9

    -- Area law holds at both verified levels
    area-law-100     : AreaLawLevel
    area-law-200     : AreaLawLevel

convergence-certificate-3L : ConvergenceCertificate3L
convergence-certificate-3L .ConvergenceCertificate3L.step-100         = dense-resolution-step
convergence-certificate-3L .ConvergenceCertificate3L.step-200         = dense200-resolution-step
convergence-certificate-3L .ConvergenceCertificate3L.tower            = two-step-tower
convergence-certificate-3L .ConvergenceCertificate3L.monotone-50-100  = spectrum-grows-50-100
convergence-certificate-3L .ConvergenceCertificate3L.monotone-100-200 = spectrum-grows-100-200
convergence-certificate-3L .ConvergenceCertificate3L.area-law-100     = dense100-area-law-level
convergence-certificate-3L .ConvergenceCertificate3L.area-law-200     = dense200-area-law-level


-- ════════════════════════════════════════════════════════════════════
--  §22.  ContinuumLimitEvidence — The fully formalized statement
-- ════════════════════════════════════════════════════════════════════
--
--  The resolution tower for the {4,3,5} honeycomb factors through
--  the orbit reduction at each level, the RT correspondence holds
--  at every resolution, the area-law bound holds at every
--  resolution, and the min-cut spectrum grows monotonically:
--
--    7 ≤ 8 ≤ 9
--
--  Reference:
--    docs/formal/09-thermodynamics.md §5
--      (The Discrete Bekenstein–Hawking Half-Bound — tower
--       integration supersedes this weaker type alias)
--    docs/formal/11-generic-bridge.md §7
--      (The Discrete Bekenstein–Hawking Capstone)
-- ════════════════════════════════════════════════════════════════════

ContinuumLimitEvidence : Type₁
ContinuumLimitEvidence = ConvergenceCertificate3L

continuum-limit-evidence : ContinuumLimitEvidence
continuum-limit-evidence = convergence-certificate-3L


-- ════════════════════════════════════════════════════════════════════
--  §23.  ResolutionStep regression tests
-- ════════════════════════════════════════════════════════════════════

open import Common.Dense100Spec using (d100r0 ; d100r15)
open import Common.Dense200Spec using (d200r0 ; d200r9)

private
  -- ── Dense-100 compat checks ──────────────────────────────────
  compat-check-d100-0 :
    ResolutionStep.S-fine dense-resolution-step d100r0
    ≡ ResolutionStep.S-coarse dense-resolution-step
        (ResolutionStep.project dense-resolution-step d100r0)
  compat-check-d100-0 = refl

  compat-check-d100-15 :
    ResolutionStep.S-fine dense-resolution-step d100r15
    ≡ ResolutionStep.S-coarse dense-resolution-step
        (ResolutionStep.project dense-resolution-step d100r15)
  compat-check-d100-15 = refl

  -- ── Dense-100 RT checks ──────────────────────────────────────
  rt-check-d100-0 :
    ResolutionStep.S-fine dense-resolution-step d100r0
    ≡ ResolutionStep.L-fine dense-resolution-step d100r0
  rt-check-d100-0 = ResolutionStep.rt-fine dense-resolution-step d100r0

  rt-check-d100-15 :
    ResolutionStep.S-fine dense-resolution-step d100r15
    ≡ ResolutionStep.L-fine dense-resolution-step d100r15
  rt-check-d100-15 = ResolutionStep.rt-fine dense-resolution-step d100r15

  -- ── Dense-200 compat checks ──────────────────────────────────
  compat-check-d200-0 :
    ResolutionStep.S-fine dense200-resolution-step d200r0
    ≡ ResolutionStep.S-coarse dense200-resolution-step
        (ResolutionStep.project dense200-resolution-step d200r0)
  compat-check-d200-0 = refl

  compat-check-d200-9 :
    ResolutionStep.S-fine dense200-resolution-step d200r9
    ≡ ResolutionStep.S-coarse dense200-resolution-step
        (ResolutionStep.project dense200-resolution-step d200r9)
  compat-check-d200-9 = refl

  -- ── Dense-200 RT checks ──────────────────────────────────────
  rt-check-d200-0 :
    ResolutionStep.S-fine dense200-resolution-step d200r0
    ≡ ResolutionStep.L-fine dense200-resolution-step d200r0
  rt-check-d200-0 = ResolutionStep.rt-fine dense200-resolution-step d200r0

  rt-check-d200-9 :
    ResolutionStep.S-fine dense200-resolution-step d200r9
    ≡ ResolutionStep.L-fine dense200-resolution-step d200r9
  rt-check-d200-9 = ResolutionStep.rt-fine dense200-resolution-step d200r9

  -- ── Monotonicity witnesses ────────────────────────────────────
  mono-check-50-100 : spectrum-grows-50-100 ≡ (1 , refl)
  mono-check-50-100 = refl

  mono-check-100-200 : spectrum-grows-100-200 ≡ (1 , refl)
  mono-check-100-200 = refl


-- ════════════════════════════════════════════════════════════════════
--  §24.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  This module is the SINGLE CANONICAL tower module for the
--  repository, consolidating the former Bridge/SchematicTower.agda
--  and Bridge/ResolutionTower.agda into one location.
--
--  Exports:
--
--    -- Tower infrastructure (§1-§5)
--    TowerLevel            — OrbitReducedPatch + maxCut + BridgeWitness
--    mkTowerLevel          : OrbitReducedPatch → ℚ≥0 → TowerLevel
--    LayerStep             — monotonicity witness between levels
--    AreaLawForPatch       — area-law bound linked to PatchData
--    RichLayerStep         — LayerStep + AreaLawForPatch at hi level
--
--    -- Dense {4,3,5} honeycomb patches (§6-§8)
--    d100-tower-level      : TowerLevel  (Dense-100, maxCut = 8)
--    d200-tower-level      : TowerLevel  (Dense-200, maxCut = 9)
--    d100→d200             : LayerStep
--    d100→d200-rich        : RichLayerStep
--    dense100-bridge       : BridgeWitness
--    dense200-bridge       : BridgeWitness
--
--    -- {5,4} tiling layers depth 2–7 (§9-§13)
--    layer54d2-orbit .. layer54d7-orbit   : OrbitReducedPatch
--    layer54d2-level .. layer54d7-level   : TowerLevel  (all maxCut = 2)
--    layer54d2-bridge .. layer54d7-bridge : BridgeWitness
--    step-d2→d3 .. step-d6→d7            : LayerStep  (all flat: 2 ≤ 2)
--
--    -- Tower packaging (§14)
--    dense-two-level-tower : TwoLevelTower
--    layer54-tower         : Layer54Tower
--
--    -- Resolution infrastructure (absorbed from ResolutionTower, §16-§22)
--    ResolutionStep             — coarse-graining step record
--    dense-resolution-step      — Dense-100 orbit reduction
--    dense200-resolution-step   — Dense-200 orbit reduction
--    ResolutionTower            — ℕ-indexed tower data type
--    single-step-tower          — 1-step (Dense-100)
--    two-step-tower             — 2-step (Dense-100 + Dense-200)
--    spectrum-grows-50-100      — 7 ≤ℚ 8
--    spectrum-grows-100-200     — 8 ≤ℚ 9
--    AreaLawLevel               — area-law at a standalone level
--    dense100-area-law-level    — Dense-100 area-law instance
--    dense200-area-law-level    — Dense-200 area-law instance
--    ConvergenceCertificate     — 2-level certificate
--    convergence-certificate    — concrete 2-level certificate
--    ConvergenceCertificate3L   — 3-level certificate
--    convergence-certificate-3L — concrete 3-level certificate
--    ContinuumLimitEvidence     — type alias (= ConvergenceCertificate3L)
--    continuum-limit-evidence   — the concrete evidence term
--
--  Architecture:
--
--    Bridge/ResolutionTower.agda is now architecturally redundant.
--    All downstream code should import tower infrastructure from
--    this module instead.  ResolutionTower.agda remains valid and
--    can serve as a historical record, but it is no longer on the
--    critical path.
--
--  Resolution tower summary:
--
--    Level   Patch      Regions  Orbits  Max S  Monotone   Area law
--    ─────   ─────────  ───────  ──────  ─────  ─────────  ────────
--      0     Dense-50     139      —       7      —          —
--      1     Dense-100    717      8       8    (1,refl)   717 cases
--      2     Dense-200   1246      9       9    (1,refl)  1246 cases
--
--  Reference:
--    docs/formal/09-thermodynamics.md  (area law, coarse-graining,
--                                       resolution tower)
--    docs/formal/11-generic-bridge.md  (SchematicTower infrastructure,
--                                       convergence certificates)
--    docs/formal/12-bekenstein-hawking.md  (half-bound, tower form)
--    docs/formal/01-theorems.md §Thm 3    (Discrete Bekenstein–Hawking)
-- ════════════════════════════════════════════════════════════════════

-- ════════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════
--
--  §25.  HALFBOUND INTEGRATION
--
--  The discrete Bekenstein–Hawking bound  S(A) ≤ area(A)/2  is
--  stronger than the area law  S(A) ≤ area(A)  from §20.  It is
--  proven generically in  Bridge/HalfBound.agda  (via the two-cut
--  decomposition  area = n_cross + n_bdy) and instantiated per-
--  patch by the Python oracle in  Boundary/Dense{N}HalfBound.agda.
--
--  This section integrates the half-bound into the tower:
--
--    (a) Concrete half-bound references for Dense-100 and Dense-200
--    (b) A FullLayerStep carrying monotone + area-law + half-bound
--    (c) A ConvergenceCertificate3L-HB extending the 3-level
--        certificate with half-bounds at each verified level
--
--  The key architectural consequence (docs/formal/12-bekenstein-hawking.md):
--  the old  ConvergenceWitness  (which required constructive reals
--  and Cauchy completeness for the η_N limit) is REPLACED by the
--  sharp half-bound at each level (which requires only ℕ arithmetic
--  and refl).  This eliminates the constructive-reals wall for the
--  entropy-area relationship.
--
--  Reference:
--    docs/formal/12-bekenstein-hawking.md  (formal treatment of the
--      discrete Bekenstein–Hawking bound, from-two-cuts, tower form)
--    docs/physics/discrete-bekenstein-hawking.md  (physics
--      interpretation of the sharp 1/2 bound)
--    docs/physics/five-walls.md  (constructive-reals wall — now
--      partially bypassed for the entropy-area relationship)
--
-- ════════════════════════════════════════════════════════════════════
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §25.1  Imports — Per-instance half-bound witnesses
-- ════════════════════════════════════════════════════════════════════
--
--  Each generated module exports  denseNHalfBound : HalfBoundWitness pd
--  where  pd = orbit-to-patch dNOrbitPatch .  Since  TowerLevel.patch
--  of the corresponding tower level is definitionally the same
--  OrbitReducedPatch, the types align:
--
--    HalfBoundWitness (orbit-to-patch (TowerLevel.patch d100-tower-level))
--    = HalfBoundWitness (orbit-to-patch d100OrbitPatch)
--    = type of D100HB.dense100HalfBound
-- ════════════════════════════════════════════════════════════════════

import Boundary.Dense100HalfBound as D100HB
import Boundary.Dense200HalfBound as D200HB


-- ════════════════════════════════════════════════════════════════════
--  §25.2  Concrete half-bound references
-- ════════════════════════════════════════════════════════════════════
--
--  Re-exported at the tower level for downstream consumption.
--  The type of each reference is:
--    HalfBoundWitness (orbit-to-patch (TowerLevel.patch dN-tower-level))
--  which Agda verifies definitionally.
-- ════════════════════════════════════════════════════════════════════

dense100-half-bound : HalfBoundWitness (orbit-to-patch d100OrbitPatch)
dense100-half-bound = D100HB.dense100HalfBound

dense200-half-bound : HalfBoundWitness (orbit-to-patch d200OrbitPatch)
dense200-half-bound = D200HB.dense200HalfBound


-- ════════════════════════════════════════════════════════════════════
--  §25.3  FullLayerStep — Monotonicity + area law + half-bound
-- ════════════════════════════════════════════════════════════════════
--
--  Extends  RichLayerStep  (§5) with the sharp half-bound at the
--  higher level.  The half-bound SUBSUMES the area law (since
--  2·S ≤ area implies S ≤ area), but we keep both fields for
--  backward compatibility: existing code consuming area-law
--  continues to work, and the half-bound provides the strictest
--  constraint.
-- ════════════════════════════════════════════════════════════════════

record FullLayerStep (lo hi : TowerLevel) : Type₁ where
  field
    monotone   : TowerLevel.maxCut lo ≤ℚ TowerLevel.maxCut hi
    area-law   : AreaLawForPatch (orbit-to-patch (TowerLevel.patch hi))
    half-bound : HalfBoundWitness (orbit-to-patch (TowerLevel.patch hi))


-- ════════════════════════════════════════════════════════════════════
--  §25.4  Dense-100 → Dense-200 FullLayerStep
-- ════════════════════════════════════════════════════════════════════
--
--  The complete layer step from Dense-100 to Dense-200, carrying:
--    • monotone:    8 ≤ 9  via  (1 , refl)
--    • area-law:    S ≤ area  for all 1246 Dense-200 regions
--    • half-bound:  2·S ≤ area  for all 1246 Dense-200 regions
--      with a tight achiever where 2·S = area
-- ════════════════════════════════════════════════════════════════════

d100→d200-full : FullLayerStep d100-tower-level d200-tower-level
d100→d200-full .FullLayerStep.monotone   = 1 , refl
d100→d200-full .FullLayerStep.area-law   = record
  { area       = D200AL.regionArea
  ; area-bound = D200AL.area-law
  }
d100→d200-full .FullLayerStep.half-bound = dense200-half-bound


-- ════════════════════════════════════════════════════════════════════
--  §25.5  HalfBoundLevel — Standalone half-bound at one level
-- ════════════════════════════════════════════════════════════════════
--
--  Like  AreaLawLevel  (§20), but with the sharp half-bound.
--  Stores the region type and observable as fields (lives in Type₁).
-- ════════════════════════════════════════════════════════════════════

record HalfBoundLevel : Type₁ where
  field
    RegionTy   : Type₀
    S-obs      : RegionTy → ℚ≥0
    area       : RegionTy → ℚ≥0
    half-bound : (r : RegionTy) → (S-obs r +ℚ S-obs r) ≤ℚ area r
    tight      : Σ[ r ∈ RegionTy ] (S-obs r +ℚ S-obs r ≡ area r)

-- ════════════════════════════════════════════════════════════════════
--  §25.6  Concrete HalfBoundLevel instances
-- ════════════════════════════════════════════════════════════════════

open import Boundary.Dense100HalfBound
  using ()
  renaming (half-bound-proof to d100-hb-proof ; tight-witness to d100-tight)

open import Boundary.Dense200HalfBound
  using ()
  renaming (half-bound-proof to d200-hb-proof ; tight-witness to d200-tight)

dense100-half-bound-level : HalfBoundLevel
dense100-half-bound-level .HalfBoundLevel.RegionTy   = D100Region
dense100-half-bound-level .HalfBoundLevel.S-obs      = S∂D100
dense100-half-bound-level .HalfBoundLevel.area       = D100AL.regionArea
dense100-half-bound-level .HalfBoundLevel.half-bound = d100-hb-proof
dense100-half-bound-level .HalfBoundLevel.tight      = d100-tight

dense200-half-bound-level : HalfBoundLevel
dense200-half-bound-level .HalfBoundLevel.RegionTy   = D200Region
dense200-half-bound-level .HalfBoundLevel.S-obs      = S∂D200
dense200-half-bound-level .HalfBoundLevel.area       = D200AL.regionArea
dense200-half-bound-level .HalfBoundLevel.half-bound = d200-hb-proof
dense200-half-bound-level .HalfBoundLevel.tight      = d200-tight


-- ════════════════════════════════════════════════════════════════════
--  §25.7  ConvergenceCertificate3L-HB — 3-level certificate with
--         half-bounds (the "sharp" version)
-- ════════════════════════════════════════════════════════════════════
--
--  This extends  ConvergenceCertificate3L  (§21) with the sharp
--  half-bound at each verified level.  The old certificate carries
--  AreaLawLevel  (S ≤ area);  this one carries  HalfBoundLevel
--  (2·S ≤ area, with a tight achiever).
--
--  The key consequence (docs/formal/12-bekenstein-hawking.md):
--
--    OLD:  EntropicConvergence = Σ[family] Σ[bridges] Σ[areas]
--            Σ[mono] ConvergenceWitness
--
--    NEW:  DiscreteBekensteinHawking = Σ[family] Σ[bridges]
--            Σ[halfBounds] Σ[mono] ⊤
--
--  The  ConvergenceWitness  (requiring constructive reals and
--  Cauchy completeness) is replaced by  HalfBoundLevel  at each
--  level (requiring only ℕ arithmetic and refl).  The discrete
--  Newton's constant is exactly 1/2 in bond-dimension-1 units,
--  verified by refl on closed ℕ terms at every resolution level.
--
--  Reference:
--    docs/formal/12-bekenstein-hawking.md §5
--      (Tower Integration — HalfBoundLevel, ConvergenceCertificate3L-HB)
--    docs/physics/discrete-bekenstein-hawking.md
--      (the sharp 1/2 bound and its significance)
-- ════════════════════════════════════════════════════════════════════

record ConvergenceCertificate3L-HB : Type₁ where
  field
    -- Resolution steps (orbit reductions)
    step-100         : ResolutionStep
    step-200         : ResolutionStep

    -- The 2-step resolution tower
    tower            : ResolutionTower (suc zero)

    -- Monotonicity: max min-cut grows
    monotone-50-100  : 7 ≤ℚ 8
    monotone-100-200 : 8 ≤ℚ 9

    -- SHARP half-bound at each verified level
    --   (replaces the weaker AreaLawLevel from ConvergenceCertificate3L)
    half-bound-100   : HalfBoundLevel
    half-bound-200   : HalfBoundLevel


-- ════════════════════════════════════════════════════════════════════
--  §25.8  Concrete 3-level certificate with half-bounds
-- ════════════════════════════════════════════════════════════════════

convergence-certificate-3L-HB : ConvergenceCertificate3L-HB
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.step-100
  = dense-resolution-step
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.step-200
  = dense200-resolution-step
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.tower
  = two-step-tower
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.monotone-50-100
  = spectrum-grows-50-100
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.monotone-100-200
  = spectrum-grows-100-200
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.half-bound-100
  = dense100-half-bound-level
convergence-certificate-3L-HB .ConvergenceCertificate3L-HB.half-bound-200
  = dense200-half-bound-level


-- ════════════════════════════════════════════════════════════════════
--  §25.9  DiscreteBekensteinHawking — The sharp type alias
-- ════════════════════════════════════════════════════════════════════
--
--  The type  DiscreteBekensteinHawking  replaces  ContinuumLimitEvidence
--  as the strongest statement about the entropy-area relationship.
--
--  The old type required a ConvergenceWitness (constructive reals).
--  The new type carries only half-bounds (ℕ arithmetic + refl).
--
--  Reference:
--    docs/formal/12-bekenstein-hawking.md §5
--      (DiscreteBekensteinHawking — The Capstone Type Alias)
--    docs/formal/01-theorems.md §Thm 3
--      (Discrete Bekenstein–Hawking — tower form)
--    docs/physics/discrete-bekenstein-hawking.md §7
--      (the machine-checked formalization)
-- ════════════════════════════════════════════════════════════════════

DiscreteBekensteinHawking : Type₁
DiscreteBekensteinHawking = ConvergenceCertificate3L-HB

discrete-bekenstein-hawking : DiscreteBekensteinHawking
discrete-bekenstein-hawking = convergence-certificate-3L-HB


-- ════════════════════════════════════════════════════════════════════
--  §25.10  Regression tests
-- ════════════════════════════════════════════════════════════════════

private
  -- The half-bound references have the expected types
  check-d100-hb : HalfBoundWitness (orbit-to-patch d100OrbitPatch)
  check-d100-hb = dense100-half-bound

  check-d200-hb : HalfBoundWitness (orbit-to-patch d200OrbitPatch)
  check-d200-hb = dense200-half-bound

  -- The full layer step type-checks
  check-full-step : FullLayerStep d100-tower-level d200-tower-level
  check-full-step = d100→d200-full

  -- The sharp certificate type-checks
  check-sharp-cert : DiscreteBekensteinHawking
  check-sharp-cert = discrete-bekenstein-hawking


-- ════════════════════════════════════════════════════════════════════
--  §25.11  Summary
-- ════════════════════════════════════════════════════════════════════
--
--  New exports (§25):
--
--    dense100-half-bound     : HalfBoundWitness (orbit-to-patch d100OrbitPatch)
--    dense200-half-bound     : HalfBoundWitness (orbit-to-patch d200OrbitPatch)
--    FullLayerStep           : TowerLevel → TowerLevel → Type₁
--    d100→d200-full          : FullLayerStep d100-tower-level d200-tower-level
--    HalfBoundLevel          : Type₁
--    dense100-half-bound-level : HalfBoundLevel
--    dense200-half-bound-level : HalfBoundLevel
--    ConvergenceCertificate3L-HB : Type₁
--    convergence-certificate-3L-HB : ConvergenceCertificate3L-HB
--    DiscreteBekensteinHawking     : Type₁  (= ConvergenceCertificate3L-HB)
--    discrete-bekenstein-hawking   : DiscreteBekensteinHawking
--
--  All existing exports from §1–§24 are preserved unchanged.
--  No downstream module needs modification.
--
--  The sharp half-bound  2·S ≤ area  at each level replaces the
--  need for constructive reals in the entropy-area relationship:
--  the discrete Newton's constant  1/(4G) = 1/2  is verified by
--  refl on closed ℕ terms, not by a limit argument.
--
--  Reference:
--    docs/formal/11-generic-bridge.md   (SchematicTower architecture)
--    docs/formal/12-bekenstein-hawking.md (half-bound, tower form)
--    docs/formal/01-theorems.md §Thm 3  (theorem registry entry)
--    docs/reference/module-index.md     (module description)
-- ════════════════════════════════════════════════════════════════════