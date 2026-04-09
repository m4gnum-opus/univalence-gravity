{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.GenericBridge where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels

open import Util.Scalars
open import Bridge.EnrichedStarEquiv
  using (BridgeWitness)


-- ════════════════════════════════════════════════════════════════════
--  §1.  PatchData — The minimal interface for any holographic patch
-- ════════════════════════════════════════════════════════════════════
--
--  A PatchData record captures the three inputs that the enriched
--  bridge construction depends on:
--
--    • A region type  RegionTy : Type₀
--    • Two observable functions  S∂ LB : RegionTy → ℚ≥0
--    • A path  obs-path : S∂ ≡ LB
--
--  The region type may have 10 constructors (star), 90 (filled),
--  717 (Dense-100), 1246 (Dense-200), or tens of thousands (future
--  layer-N patches) — the record is agnostic.
--
--  The obs-path is the discrete Ryu–Takayanagi correspondence:
--  boundary min-cut entropy equals bulk minimal separating surface
--  area on every admissible region.  It is typically constructed
--  by  funExt  of pointwise  refl  proofs (or orbit-representative
--  refl proofs + 1-line lifting for orbit-reduced patches).
--
--  The record lives in Type₁ because it stores  RegionTy : Type₀
--  as a field.
--
--  Reference:
--    docs/10-frontier.md §5.4  (Step 1 — The PatchData Record)
-- ════════════════════════════════════════════════════════════════════

record PatchData : Type₁ where
  field
    RegionTy : Type₀
    S∂       : RegionTy → ℚ≥0
    LB       : RegionTy → ℚ≥0
    obs-path : S∂ ≡ LB


-- ════════════════════════════════════════════════════════════════════
--  §2.  GenericEnriched — The generic bridge theorem
-- ════════════════════════════════════════════════════════════════════
--
--  This parameterized module proves, once and for all, that any
--  PatchData admits the full enriched equivalence:
--
--    EnrichedBdy  ≃  EnrichedBulk
--
--  together with the Univalence path, verified transport, and a
--  fully proof-carrying BridgeWitness record.
--
--  The module is written ONCE, proven ONCE, and instantiated at
--  each concrete patch by applying it to a specific PatchData
--  instance.  Every existing bridge module in the repository
--  (EnrichedStarObs, FilledEquiv, Honeycomb3DEquiv, Dense50Equiv,
--  Dense100Equiv, Dense200Equiv) is a special case of this
--  construction.
--
--  The key structural fact enabling the proof: both enriched types
--  are reversed singleton types  Σ[ f ] (f ≡ a)  — contractible
--  spaces centered at their respective specification functions.
--  The Iso is built from  obs-path  (the discrete RT correspondence),
--  and round-trip proofs use the fact that  RegionTy → ℚ≥0  is a
--  set (h-level 2), making specification-agreement fields
--  propositional.
--
--  Reference:
--    docs/10-frontier.md §5.4  (Step 2 — The Generic Bridge Theorem)
--    docs/10-frontier.md §5.3  (Separation of Geometry and Proof)
-- ════════════════════════════════════════════════════════════════════

module GenericEnriched (pd : PatchData) where
  open PatchData pd


  -- ── h-Level infrastructure ───────────────────────────────────────
  --
  --  The observable function space  RegionTy → ℚ≥0  is a set
  --  (h-level 2) because  ℚ≥0 = ℕ  is a set (isSetℚ≥0 from
  --  Util/Scalars.agda).
  --
  --  This is the key structural fact enabling the equivalence:
  --  in a set, paths between elements are propositional (isProp),
  --  which makes specification-agreement fields propositional,
  --  which makes round-trip homotopies automatic.

  isSetObs : isSet (RegionTy → ℚ≥0)
  isSetObs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


  -- ── Enriched observable types ────────────────────────────────────
  --
  --  EnrichedBdy  pairs an observable function with a proof that it
  --  agrees with the boundary specification  S∂ .
  --
  --  EnrichedBulk  pairs a function with agreement to  LB .
  --
  --  These are "reversed singleton types"  Σ[ f ] (f ≡ a)  —
  --  contractible spaces centered at their respective reference
  --  functions.  They are genuinely different types in the universe
  --  because  S∂  and  LB  are (in concrete instances) definitionally
  --  distinct functions defined by separate case splits.
  --
  --  The enrichment captures the idea that an observable bundle is
  --  not just a function from regions to scalars, but a function
  --  CERTIFIED to match a specific physical specification.

  EnrichedBdy : Type₀
  EnrichedBdy = Σ[ f ∈ (RegionTy → ℚ≥0) ] (f ≡ S∂)

  EnrichedBulk : Type₀
  EnrichedBulk = Σ[ f ∈ (RegionTy → ℚ≥0) ] (f ≡ LB)


  -- ── Canonical inhabitants ────────────────────────────────────────

  bdy-instance : EnrichedBdy
  bdy-instance = S∂ , refl

  bulk-instance : EnrichedBulk
  bulk-instance = LB , refl


  -- ── The Iso between enriched types ───────────────────────────────
  --
  --  The forward map appends  obs-path  to the boundary agreement
  --  witness, converting  f ≡ S∂  into  f ≡ LB  via the discrete
  --  Ryu–Takayanagi correspondence.
  --
  --  The inverse map appends  sym obs-path  to convert back.
  --
  --  Round-trip proofs use  isSetObs : isSet (RegionTy → ℚ≥0) ,
  --  which makes all paths  f ≡ S∂  (or  f ≡ LB) propositional.
  --  Any two such paths are equal, so the composed path
  --  (p ∙ obs-path) ∙ sym obs-path  is propositionally equal
  --  to the original  p .
  --
  --  This construction is identical in structure to every existing
  --  bridge in the repository (EnrichedStarObs, FilledEquiv,
  --  Honeycomb3DEquiv, etc.) — it is the same Iso, parameterized
  --  over the abstract  obs-path  instead of a concrete one.

  enriched-iso : Iso EnrichedBdy EnrichedBulk
  enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
    where
      fwd : EnrichedBdy → EnrichedBulk
      fwd (f , p) = f , p ∙ obs-path

      bwd : EnrichedBulk → EnrichedBdy
      bwd (f , q) = f , q ∙ sym obs-path

      fwd-bwd : (b : EnrichedBulk) → fwd (bwd b) ≡ b
      fwd-bwd (f , q) i =
        f , isSetObs f LB
              ((q ∙ sym obs-path) ∙ obs-path) q i

      bwd-fwd : (a : EnrichedBdy) → bwd (fwd a) ≡ a
      bwd-fwd (f , p) i =
        f , isSetObs f S∂
              ((p ∙ obs-path) ∙ sym obs-path) p i


  -- ── The equivalence ──────────────────────────────────────────────

  enriched-equiv : EnrichedBdy ≃ EnrichedBulk
  enriched-equiv = isoToEquiv enriched-iso


  -- ── The Univalence path ──────────────────────────────────────────
  --
  --  Applying  ua  to the enriched equivalence yields a path
  --  between  EnrichedBdy  and  EnrichedBulk  in the universe
  --  Type₀ .  This path is NOT propositionally equal to  refl :
  --  the two types are genuinely different (they reference
  --  different specification functions), and the path carries the
  --  nontrivial content of  obs-path  through the Glue type.

  enriched-ua-path : EnrichedBdy ≡ EnrichedBulk
  enriched-ua-path = ua enriched-equiv


  -- ── Transport: the verified translator ───────────────────────────
  --
  --  Transport along the Univalence path converts the boundary
  --  observable bundle to the bulk observable bundle.
  --
  --  Step 1:  uaβ reduces transport to the forward map of the
  --  equivalence.
  --
  --  Step 2:  Both the forward map output and bulk-instance are
  --  elements of EnrichedBulk, which is a reversed singleton type
  --  Σ[ f ] (f ≡ LB) — CONTRACTIBLE.  Any contractible type is
  --  a proposition, so any two elements are equal.  This discharges
  --  the second half of the transport proof without inspecting the
  --  specific structure of the forward map.
  --
  --  This approach is simpler and more generic than the explicit
  --  isProp→PathP construction used in the concrete bridge modules
  --  (EnrichedStarObs, FilledEquiv, etc.), because it leverages
  --  contractibility directly.

  transport-computes :
    transport enriched-ua-path bdy-instance
    ≡ equivFun enriched-equiv bdy-instance
  transport-computes = uaβ enriched-equiv bdy-instance

  -- Reversed singleton contractibility:
  --   Σ[ x ∈ A ] (x ≡ a)  is contractible for any  a : A .
  --
  --  Center:  (a , refl)
  --  Contraction:  given  (x , p : x ≡ a) , the path
  --    i ↦ (p (~ i) , λ j → p (~ i ∨ j))
  --  connects  (a , refl)  at  i = i0  to  (x , p)  at  i = i1 .

  private
    isContr-Singl : ∀ {ℓ} {A : Type ℓ} (a : A)
      → isContr (Σ[ x ∈ A ] (x ≡ a))
    isContr-Singl a .fst = a , refl
    isContr-Singl a .snd (x , p) i =
      p (~ i) , λ j → p (~ i ∨ j)

  -- Assemble the exact transport step:
  --
  --  transport enriched-ua-path bdy-instance
  --    ≡ equivFun enriched-equiv bdy-instance     by uaβ
  --    ≡ bulk-instance                             by contractibility

  enriched-transport :
    transport enriched-ua-path bdy-instance ≡ bulk-instance
  enriched-transport =
    transport-computes ∙ isContr→isProp (isContr-Singl LB) _ _


  -- ── Observable function extraction ───────────────────────────────
  --
  --  The primary computational artifact: the observable function
  --  extracted from the transported boundary instance equals  LB .

  enriched-transport-obs :
    fst (transport enriched-ua-path bdy-instance) ≡ LB
  enriched-transport-obs = cong fst enriched-transport


  -- ── Pointwise extraction ─────────────────────────────────────────

  enriched-transport-pointwise :
    (r : RegionTy) →
    fst (transport enriched-ua-path bdy-instance) r ≡ LB r
  enriched-transport-pointwise r =
    cong (λ f → f r) enriched-transport-obs


  -- ── The Magnum Opus: fully proof-carrying bridge witness ─────────
  --
  --  Packages the entire construction into a single BridgeWitness
  --  record (defined in Bridge/EnrichedStarEquiv.agda).  This is
  --  the "Milestone 3–4 deliverable" — a machine-checked proof that
  --  the boundary and bulk observable packages are exactly
  --  equivalent types, with verified computable transport.
  --
  --  Every bridge instance in the repository (Star, Filled,
  --  Honeycomb, Dense-50, Dense-100, Dense-200) is a special case
  --  of this construction applied to a specific PatchData.

  abstract-bridge-witness : BridgeWitness
  abstract-bridge-witness = record
    { BdyTy              = EnrichedBdy
    ; BulkTy             = EnrichedBulk
    ; bdy-data           = bdy-instance
    ; bulk-data          = bulk-instance
    ; bridge             = enriched-equiv
    ; transport-verified = enriched-transport
    }


-- ════════════════════════════════════════════════════════════════════
--  §3.  OrbitReducedPatch — Interface for orbit-reduced patches
-- ════════════════════════════════════════════════════════════════════
--
--  The orbit reduction strategy (§6.5 of docs/10-frontier.md)
--  factors the observable lookup through a small orbit type.
--  The OrbitReducedPatch record captures this pattern:
--
--    • RegionTy  — the (potentially large) region type
--    • OrbitTy   — the (small) orbit representative type
--    • classify  — surjection from regions to orbit representatives
--    • S-rep, L-rep — observable functions on orbit representatives
--    • rep-agree — pointwise agreement on orbit representatives
--
--  The key property: the observable at a region  r  is computed as
--  S-rep (classify r)  (resp. L-rep (classify r)), so the proof
--  obligations are on OrbitTy (small), not on RegionTy (large).
--
--  This is the exact pattern from Dense-100 (8 orbit reps,
--  717 regions) and Dense-200 (9 orbit reps, 1246 regions).
--  The Python oracle's job is to produce valid OrbitReducedPatch
--  instances with  rep-agree  reducible to pointwise  refl .
--
--  The record lives in Type₁ because it stores types as fields.
--
--  Reference:
--    docs/10-frontier.md §5.4  (Step 3 — The Orbit-Reduced Interface)
--    docs/10-frontier.md §6.5  (Stage 2 — Orbit Reduction)
--    Bridge/Dense100Obs.agda   (the pattern being generalized)
-- ════════════════════════════════════════════════════════════════════

record OrbitReducedPatch : Type₁ where
  field
    RegionTy  : Type₀
    OrbitTy   : Type₀
    classify  : RegionTy → OrbitTy
    S-rep     : OrbitTy → ℚ≥0
    L-rep     : OrbitTy → ℚ≥0
    rep-agree : (o : OrbitTy) → S-rep o ≡ L-rep o


-- ════════════════════════════════════════════════════════════════════
--  §4.  orbit-to-patch — Convert OrbitReducedPatch to PatchData
-- ════════════════════════════════════════════════════════════════════
--
--  The PatchData is extracted automatically from an OrbitReducedPatch:
--
--    S∂  =  λ r → S-rep (classify r)
--    LB  =  λ r → L-rep (classify r)
--    obs-path  =  funExt (λ r → rep-agree (classify r))
--
--  The obs-path is constructed by the familiar 1-line lifting:
--  the orbit-level agreement  rep-agree (classify r)  at each
--  region  r  is assembled into a function-level path by  funExt .
--
--  This is exactly the pattern from  Bridge/Dense100Obs.agda :
--
--    d100-pointwise r = d100-pointwise-rep (classify100 r)
--
--  now stated generically for any orbit-reduced patch.
--
--  Reference:
--    docs/10-frontier.md §5.4  (Step 3)
--    Bridge/Dense100Obs.agda   (d100-pointwise via classify100)
-- ════════════════════════════════════════════════════════════════════

orbit-to-patch : OrbitReducedPatch → PatchData
orbit-to-patch orp = record
  { RegionTy = RegionTy
  ; S∂       = λ r → S-rep (classify r)
  ; LB       = λ r → L-rep (classify r)
  ; obs-path = funExt (λ r → rep-agree (classify r))
  }
  where open OrbitReducedPatch orp


-- ════════════════════════════════════════════════════════════════════
--  §5.  Automatic Bridge from Orbit Data
-- ════════════════════════════════════════════════════════════════════
--
--  The composition  GenericEnriched (orbit-to-patch orp)  produces
--  the full enriched equivalence + Univalence path + verified
--  transport for ANY orbit-reduced patch, regardless of its region
--  count, orbit count, or geometric origin.
--
--  The Python oracle's job is solely to produce valid
--  OrbitReducedPatch instances; the generic theorem handles the rest.
--
--  Convenience: extract the BridgeWitness directly from an
--  OrbitReducedPatch in a single step.
--
--  Reference:
--    docs/10-frontier.md §5.4  (Step 4 — Automatic Bridge)
-- ════════════════════════════════════════════════════════════════════

orbit-bridge-witness : OrbitReducedPatch → BridgeWitness
orbit-bridge-witness orp =
  GenericEnriched.abstract-bridge-witness (orbit-to-patch orp)


-- ════════════════════════════════════════════════════════════════════
--  §6.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    PatchData                — the minimal interface for any patch
--    GenericEnriched          — parameterized module producing:
--      isSetObs               : isSet (RegionTy → ℚ≥0)
--      EnrichedBdy            : Type₀
--      EnrichedBulk           : Type₀
--      bdy-instance           : EnrichedBdy
--      bulk-instance          : EnrichedBulk
--      enriched-iso           : Iso EnrichedBdy EnrichedBulk
--      enriched-equiv         : EnrichedBdy ≃ EnrichedBulk
--      enriched-ua-path       : EnrichedBdy ≡ EnrichedBulk
--      transport-computes     : transport ... ≡ equivFun ...
--      enriched-transport     : transport ... bdy-instance ≡ bulk-instance
--      enriched-transport-obs : fst (transport ...) ≡ LB
--      enriched-transport-pointwise : ∀ r → fst (...) r ≡ LB r
--      abstract-bridge-witness : BridgeWitness
--    OrbitReducedPatch        — interface for orbit-reduced patches
--    orbit-to-patch           : OrbitReducedPatch → PatchData
--    orbit-bridge-witness     : OrbitReducedPatch → BridgeWitness
--
--  Architecture:
--
--    The schematic bridge factorization resolves the N-layer
--    challenge by changing the structure of the induction:
--
--      Original plan:  structural induction on the GEOMETRY
--                      (layer-by-layer polygon complex)
--
--      New approach:   structural induction on the PROOF SCHEMA
--                      (generic theorem, oracle-generated instances)
--
--    The hard geometry stays in Python.  The Agda proof is written
--    once (~30 lines each for GenericEnriched and orbit-to-patch).
--    No new hand-written bridge module is needed for layer 3, 4, 5,
--    or N — only the generated modules (Spec, Cut, Chain, Obs).
--
--  Retroactive validation:
--
--    Every existing bridge is an instance of GenericEnriched:
--
--      Star:       PatchData with RegionTy = Region (10 ctors)
--      Filled:     PatchData with RegionTy = FilledRegion (90 ctors)
--      Honeycomb:  PatchData with RegionTy = H3Region (26 ctors)
--      Dense-50:   PatchData with RegionTy = D50Region (139 ctors)
--      Dense-100:  orbit-to-patch with OrbitTy = D100OrbitRep (8 ctors)
--      Dense-200:  orbit-to-patch with OrbitTy = D200OrbitRep (9 ctors)
--
--    The factorization is not speculative — it is a refactoring of
--    existing, type-checked code.
--
--  Relationship to existing modules:
--
--    This module imports from (but does NOT modify):
--      • Util/Scalars.agda              — ℚ≥0, isSetℚ≥0
--      • Bridge/EnrichedStarEquiv.agda  — BridgeWitness record
--
--    New modules that would consume this:
--      • Bridge/SchematicTower.agda     — TowerLevel, LayerStep
--      • Bridge/GenericValidation.agda  — regression tests
--
--  Reference:
--    docs/10-frontier.md §5    (Direction C — N Layers)
--    docs/10-frontier.md §5.4  (The Novel Approach)
--    docs/10-frontier.md §5.5  (What This Achieves)
--    docs/10-frontier.md §5.11 (Execution Plan, Phase C.0)
--    docs/10-frontier.md §5.12 (Conditions for Advancement)
-- ════════════════════════════════════════════════════════════════════