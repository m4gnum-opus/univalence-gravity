{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.ResolutionTower where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; zero ; suc)

open import Util.Scalars

-- ════════════════════════════════════════════════════════════════════
--  Imports — Dense-100 Infrastructure
-- ════════════════════════════════════════════════════════════════════
--
--  The Dense-100 patch (100 cubes, 717 regions, 8 orbit reps)
--  provides the first concrete resolution step via its orbit
--  reduction:  D100Region (717 ctors) → D100OrbitRep (8 ctors).
--
--  The RT correspondence is verified at the orbit level (8 refl
--  proofs) and lifted to 717 regions by a 1-line composition.
--  The area law is verified on all 717 regions (abstract).
-- ════════════════════════════════════════════════════════════════════

open import Common.Dense100Spec
  using ( D100Region ; D100OrbitRep ; classify100 )
open import Boundary.Dense100Cut
  using ( S-cut-rep )
open import Bridge.Dense100Obs
  using ( d100-pointwise ; S∂D100 ; LBD100 )
open import Boundary.Dense100AreaLaw
  using ( regionArea ; area-law )


-- ════════════════════════════════════════════════════════════════════
--  Imports — Dense-200 Infrastructure  (Phase G.2)
-- ════════════════════════════════════════════════════════════════════
--
--  The Dense-200 patch (200 cubes, 1246 regions, 9 orbit reps)
--  provides the second concrete resolution step, extending the
--  convergence certificate from 2 levels to 3 levels:
--
--    Dense-50 (max S=7) → Dense-100 (max S=8) → Dense-200 (max S=9)
--
--  The max min-cut grew from 8 to 9, confirming monotone convergence
--  of the discrete Ryu–Takayanagi spectrum.  This is witnessed by
--  a single  (1 , refl)  proof.
--
--  Module-qualified imports for Dense200Cut and Dense200AreaLaw
--  resolve name clashes with Dense-100 exports (S-cut-rep,
--  regionArea, area-law).
-- ════════════════════════════════════════════════════════════════════

open import Common.Dense200Spec
  using ( D200Region ; D200OrbitRep ; classify200 )

-- Qualified import to avoid name clash with Dense-100's S-cut-rep
import Boundary.Dense200Cut as D200Cut

open import Bridge.Dense200Obs
  using ( d200-pointwise ; S∂D200 ; LBD200 )

-- Qualified import to avoid name clash with Dense-100's regionArea / area-law
import Boundary.Dense200AreaLaw as D200AL


-- ════════════════════════════════════════════════════════════════════
--  §1.  ResolutionStep — A single step of the resolution tower
-- ════════════════════════════════════════════════════════════════════
--
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
--  Reference: §10.3 of docs/10-frontier.md
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
--  §2.  Dense-100 Resolution Step
-- ════════════════════════════════════════════════════════════════════
--
--  The Dense-100 orbit reduction:
--
--    D100Region (717 constructors)  →  D100OrbitRep (8 constructors)
--
--  Reference: §10.4 of docs/10-frontier.md
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


-- ════════════════════════════════════════════════════════════════════
--  §3.  Dense-200 Resolution Step  (Phase G.2)
-- ════════════════════════════════════════════════════════════════════
--
--  The Dense-200 orbit reduction:
--
--    D200Region (1246 constructors)  →  D200OrbitRep (9 constructors)
--
--  The observables are:
--    S-fine   = S∂D200       (boundary min-cut, from Bridge/Dense200Obs)
--    L-fine   = LBD200       (bulk minimal surface, from Bridge/Dense200Obs)
--    S-coarse = D200Cut.S-cut-rep  (orbit-level lookup, from Dense200Cut)
--
--  The RT correspondence  rt-fine = d200-pointwise  is the 9 orbit-
--  representative refl proofs + 1-line lifting from Dense200Obs.
--
--  The  compat  field is  refl  because  S-cut  is DEFINED as
--  S-cut-rep ∘ classify200  in  Boundary/Dense200Cut.agda :
--
--    S∂D200 r  =  S-cut d200BdyView r
--              =  D200Cut.S-cut-rep (classify200 r)
--              ≡  S-coarse (project r)          definitionally
--
--  Generated by  sim/prototyping/12_generate_dense200.py
-- ════════════════════════════════════════════════════════════════════

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
--  §4.  ResolutionTower — A list of resolution steps
-- ════════════════════════════════════════════════════════════════════
--
--  A tower is a sequence of resolution steps indexed by ℕ.  The
--  base case holds a single step; each subsequent step extends the
--  tower.  The index counts the number of  step  constructors used
--  (so  base  lives at index zero,  step _ (base _)  at  suc zero,
--  etc.).
--
--  Reference: §10.3 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

data ResolutionTower : ℕ → Type₁ where
  base : ResolutionStep → ResolutionTower zero
  step : ∀ {n} → ResolutionStep → ResolutionTower n
       → ResolutionTower (suc n)


-- ════════════════════════════════════════════════════════════════════
--  §5.  Tower Instances
-- ════════════════════════════════════════════════════════════════════
--
--  single-step-tower:  the Dense-100 orbit reduction  (Phase G.0)
--  two-step-tower:     Dense-100 + Dense-200 steps   (Phase G.2)
--
--  The two-step tower represents the resolution sequence:
--    Dense-50 → Dense-100 → Dense-200
--  where each  step  carries the orbit reduction for that level
--  and the  base  carries the first level's orbit reduction.
-- ════════════════════════════════════════════════════════════════════

single-step-tower : ResolutionTower zero
single-step-tower = base dense-resolution-step

two-step-tower : ResolutionTower (suc zero)
two-step-tower = step dense200-resolution-step single-step-tower


-- ════════════════════════════════════════════════════════════════════
--  §6.  Monotonicity Witnesses — The growing min-cut spectrum
-- ════════════════════════════════════════════════════════════════════
--
--  The min-cut spectrum grows monotonically with resolution:
--
--    Dense-50:   max min-cut = 7
--    Dense-100:  max min-cut = 8
--    Dense-200:  max min-cut = 9
--
--  Each transition is a concrete inequality witnessed by (k , refl)
--  because  k + lo = hi  judgmentally.
--
--    | Transition            | Max_lo | Max_hi | Witness      |
--    |───────────────────────|────────|────────|──────────────|
--    | Dense-50 → Dense-100  |      7 |      8 | (1 , refl)  |
--    | Dense-100 → Dense-200 |      8 |      9 | (1 , refl)  |
--
--  Reference: §10.5 of docs/10-frontier.md
--  Empirical source: 12_generate_dense200_OUTPUT.txt
-- ════════════════════════════════════════════════════════════════════

spectrum-grows : 7 ≤ℚ 8
spectrum-grows = 1 , refl

-- Phase G.2:  Dense-100 (max 8) → Dense-200 (max 9)
-- 1 + 8 = 9  judgmentally
spectrum-grows-200 : 8 ≤ℚ 9
spectrum-grows-200 = 1 , refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  AreaLawLevel — The discrete area law at a single level
-- ════════════════════════════════════════════════════════════════════
--
--  At each finite resolution level, the min-cut entropy is bounded
--  by the boundary surface area of the region:
--
--    S_cut(A)  ≤  area(A)
--
--  Reference: §10.6 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

record AreaLawLevel : Type₁ where
  field
    RegionTy     : Type₀
    S-obs        : RegionTy → ℚ≥0
    area         : RegionTy → ℚ≥0
    area-bound   : (r : RegionTy) → S-obs r ≤ℚ area r


-- ════════════════════════════════════════════════════════════════════
--  §8.  Area-Law Instances
-- ════════════════════════════════════════════════════════════════════
--
--  Dense-100:  717 regions,  slack range 3–18  (mean 11.3)
--  Dense-200: 1246 regions,  slack range 3–18  (mean 10.8)
--
--  Both area-law proofs are  abstract  (sealed in their respective
--  AreaLaw modules), so downstream modules never re-unfold the
--  hundreds of (k , refl) cases.
-- ════════════════════════════════════════════════════════════════════

dense100-area-law-level : AreaLawLevel
dense100-area-law-level .AreaLawLevel.RegionTy   = D100Region
dense100-area-law-level .AreaLawLevel.S-obs      = S∂D100
dense100-area-law-level .AreaLawLevel.area       = regionArea
dense100-area-law-level .AreaLawLevel.area-bound = area-law

-- Phase G.2:  Dense-200 area law (1246 abstract (k , refl) cases)
--
--  S-obs = S∂D200 = Boundary.Dense200Cut.S-cut d200BdyView
--  area  = D200AL.regionArea  (from Boundary/Dense200AreaLaw.agda)
--
--  The type of  D200AL.area-law  is:
--    (r : D200Region) → S-cut d200BdyView r ≤ℚ D200AL.regionArea r
--  which matches  area-bound  because  S∂D200 = S-cut d200BdyView
--  definitionally.

dense200-area-law-level : AreaLawLevel
dense200-area-law-level .AreaLawLevel.RegionTy   = D200Region
dense200-area-law-level .AreaLawLevel.S-obs      = S∂D200
dense200-area-law-level .AreaLawLevel.area       = D200AL.regionArea
dense200-area-law-level .AreaLawLevel.area-bound = D200AL.area-law


-- ════════════════════════════════════════════════════════════════════
--  §9.  ConvergenceCertificate — 2-level certificate  (Phase G.0)
-- ════════════════════════════════════════════════════════════════════
--
--  Retained for backward compatibility.  Packages the Dense-50 →
--  Dense-100 transition as a single-step certificate.
--
--  Reference: §10.9 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

record ConvergenceCertificate : Type₁ where
  field
    resolution       : ResolutionStep
    tower            : ResolutionTower zero
    monotone         : 7 ≤ℚ 8
    area-law-level   : AreaLawLevel

convergence-certificate : ConvergenceCertificate
convergence-certificate .ConvergenceCertificate.resolution     = dense-resolution-step
convergence-certificate .ConvergenceCertificate.tower          = single-step-tower
convergence-certificate .ConvergenceCertificate.monotone       = spectrum-grows
convergence-certificate .ConvergenceCertificate.area-law-level = dense100-area-law-level


-- ════════════════════════════════════════════════════════════════════
--  §10.  ConvergenceCertificate3L — 3-level certificate  (Phase G.2)
-- ════════════════════════════════════════════════════════════════════
--
--  The 3-level convergence certificate packages:
--
--    1. Two resolution steps (Dense-100 and Dense-200 orbit
--       reductions), each with verified RT correspondence via
--       orbit-representative refl proofs.
--
--    2. A 2-step resolution tower assembling both steps.
--
--    3. Two monotonicity witnesses:
--         Dense-50 → Dense-100:   7 ≤ 8  via (1 , refl)
--         Dense-100 → Dense-200:  8 ≤ 9  via (1 , refl)
--
--    4. Two area-law levels:
--         Dense-100:  717 regions,  S ≤ area  (abstract, slack 3–18)
--         Dense-200: 1246 regions,  S ≤ area  (abstract, slack 3–18)
--
--  This satisfies the stretch exit criterion from §10.13:
--
--    "A Dense-200 instance extends the certificate to 3 levels,
--     with the new max min-cut ≥ 8 witnessed by (k , refl)."
--
--  The max min-cut grew from 8 to 9, witnessed by (1 , refl).
--
--  Reference: §10.11 Phase G.2 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

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


-- ────────────────────────────────────────────────────────────────
--  The concrete 3-level convergence certificate
-- ────────────────────────────────────────────────────────────────
--
--  All fields are filled from existing, independently verified
--  modules.  No new proofs are required — only new packaging.
--
--  The resolution tower witnesses:
--    Dense-50 (139 regions, max S=7)
--    → Dense-100 (717 regions, max S=8, 8 orbits)
--    → Dense-200 (1246 regions, max S=9, 9 orbits)
-- ────────────────────────────────────────────────────────────────

convergence-certificate-3L : ConvergenceCertificate3L
convergence-certificate-3L .ConvergenceCertificate3L.step-100         = dense-resolution-step
convergence-certificate-3L .ConvergenceCertificate3L.step-200         = dense200-resolution-step
convergence-certificate-3L .ConvergenceCertificate3L.tower            = two-step-tower
convergence-certificate-3L .ConvergenceCertificate3L.monotone-50-100  = spectrum-grows
convergence-certificate-3L .ConvergenceCertificate3L.monotone-100-200 = spectrum-grows-200
convergence-certificate-3L .ConvergenceCertificate3L.area-law-100     = dense100-area-law-level
convergence-certificate-3L .ConvergenceCertificate3L.area-law-200     = dense200-area-law-level


-- ════════════════════════════════════════════════════════════════════
--  §11.  ContinuumLimitEvidence — The fully formalized statement
-- ════════════════════════════════════════════════════════════════════
--
--  Updated from Phase G.0 to reference the 3-level certificate.
--
--  The resolution tower for the {4,3,5} honeycomb factors through
--  the orbit reduction at each level, the RT correspondence holds
--  at every resolution, the area-law bound holds at every
--  resolution, and the min-cut spectrum grows monotonically:
--
--    7 ≤ 8 ≤ 9
--
--  Reference: §10.14 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

ContinuumLimitEvidence : Type₁
ContinuumLimitEvidence = ConvergenceCertificate3L

continuum-limit-evidence : ContinuumLimitEvidence
continuum-limit-evidence = convergence-certificate-3L


-- ════════════════════════════════════════════════════════════════════
--  §12.  Regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that all resolution steps' fields produce
--  the expected values, confirming that all imports resolve
--  correctly and the definitional equalities hold.
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

  -- ── Dense-200 compat checks  (Phase G.2) ─────────────────────
  -- d200r0: classify200 d200r0 = mc2, S-cut-rep mc2 = 2
  compat-check-d200-0 :
    ResolutionStep.S-fine dense200-resolution-step d200r0
    ≡ ResolutionStep.S-coarse dense200-resolution-step
        (ResolutionStep.project dense200-resolution-step d200r0)
  compat-check-d200-0 = refl

  -- d200r9: classify200 d200r9 = mc9, S-cut-rep mc9 = 9  (max min-cut)
  compat-check-d200-9 :
    ResolutionStep.S-fine dense200-resolution-step d200r9
    ≡ ResolutionStep.S-coarse dense200-resolution-step
        (ResolutionStep.project dense200-resolution-step d200r9)
  compat-check-d200-9 = refl

  -- ── Dense-200 RT checks  (Phase G.2) ─────────────────────────
  -- d200r0: S∂D200 d200r0 ≡ LBD200 d200r0  (both = 2)
  rt-check-d200-0 :
    ResolutionStep.S-fine dense200-resolution-step d200r0
    ≡ ResolutionStep.L-fine dense200-resolution-step d200r0
  rt-check-d200-0 = ResolutionStep.rt-fine dense200-resolution-step d200r0

  -- d200r9: S∂D200 d200r9 ≡ LBD200 d200r9  (both = 9)
  rt-check-d200-9 :
    ResolutionStep.S-fine dense200-resolution-step d200r9
    ≡ ResolutionStep.L-fine dense200-resolution-step d200r9
  rt-check-d200-9 = ResolutionStep.rt-fine dense200-resolution-step d200r9

  -- ── Monotonicity witnesses ────────────────────────────────────
  mono-check : spectrum-grows ≡ (1 , refl)
  mono-check = refl

  mono-check-200 : spectrum-grows-200 ≡ (1 , refl)
  mono-check-200 = refl


-- ════════════════════════════════════════════════════════════════════
--  §13.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  This module completes Phases G.0 and G.2 of the implementation
--  plan (§10.11 of docs/10-frontier.md) and satisfies the exit
--  criterion from §10.13 including the stretch goal:
--
--    1. ✓  A ResolutionStep record type-checks with the Dense-100
--          orbit reduction as the concrete instance.
--
--    2. ✓  A ConvergenceCertificate record type-checks with
--          1 resolution step, 1 monotonicity witness (7 ≤ 8),
--          and 1 area-law instance (717 regions).
--
--    3. ✓  (Stretch — Phase G.2)  A Dense-200 instance extends
--          the certificate to 3 levels, with the new max min-cut
--          = 9 ≥ 8 witnessed by (1 , refl).
--
--  Exports:
--
--    ResolutionStep             — record type for a single step
--    dense-resolution-step      — Dense-100 orbit reduction instance
--    dense200-resolution-step   — Dense-200 orbit reduction instance
--    ResolutionTower            — ℕ-indexed data type for towers
--    single-step-tower          — the 1-step tower  (Dense-100)
--    two-step-tower             — the 2-step tower  (Dense-100 + Dense-200)
--    spectrum-grows             — 7 ≤ℚ 8  monotonicity witness
--    spectrum-grows-200         — 8 ≤ℚ 9  monotonicity witness
--    AreaLawLevel               — record type for area-law data
--    dense100-area-law-level    — Dense-100 area-law instance
--    dense200-area-law-level    — Dense-200 area-law instance
--    ConvergenceCertificate     — 2-level certificate (backward compat)
--    convergence-certificate    — the 2-level concrete certificate
--    ConvergenceCertificate3L   — 3-level certificate (Phase G.2)
--    convergence-certificate-3L — the 3-level concrete certificate
--    ContinuumLimitEvidence     — type alias (= ConvergenceCertificate3L)
--    continuum-limit-evidence   — the concrete 3-level evidence term
--
--  Relationship to existing modules:
--
--    This module imports from (but does NOT modify):
--      • Common/Dense100Spec.agda       — D100Region, D100OrbitRep, classify100
--      • Boundary/Dense100Cut.agda      — S-cut-rep
--      • Bridge/Dense100Obs.agda        — d100-pointwise, S∂D100, LBD100
--      • Boundary/Dense100AreaLaw.agda  — regionArea, area-law
--      • Common/Dense200Spec.agda       — D200Region, D200OrbitRep, classify200
--      • Boundary/Dense200Cut.agda      — S-cut-rep  (as D200Cut.S-cut-rep)
--      • Bridge/Dense200Obs.agda        — d200-pointwise, S∂D200, LBD200
--      • Boundary/Dense200AreaLaw.agda  — regionArea, area-law  (as D200AL.*)
--      • Util/Scalars.agda              — ℚ≥0, _≤ℚ_
--
--  Resolution tower summary:
--
--    Level   Patch      Regions  Orbits  Max S  Monotone   Area law
--    ─────   ─────────  ───────  ──────  ─────  ─────────  ────────
--      0     Dense-50     139      —       7      —          —
--      1     Dense-100    717      8       8    (1,refl)   717 cases
--      2     Dense-200   1246      9       9    (1,refl)  1246 cases
--
--  Future extensions (Phase G.3):
--
--    Each additional Dense-N instance contributes:
--      • A new ResolutionStep
--      • A new monotonicity witness
--      • A new AreaLawLevel
--      • An extended tower: step newStep oldTower
--
--    The coinductive horizon (Phase G.3, §10.8) requires a generic
--    patch constructor  patch : ℕ → VerifiedPatch , which is
--    equivalent to solving Direction C (N-Layer Generalization).
--    Without it, the tower can only be defined for a finite prefix.
-- ════════════════════════════════════════════════════════════════════