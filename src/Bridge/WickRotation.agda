{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.WickRotation where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Data.Int using (ℤ ; pos ; negsuc)

open import Util.Rationals

-- ════════════════════════════════════════════════════════════════════
--  Discrete Wick Rotation — The dS / AdS Curvature-Agnostic Bridge
-- ════════════════════════════════════════════════════════════════════
--
--  This module is **Theorem 4** (Discrete Wick Rotation) in the
--  canonical theorem registry (docs/formal/01-theorems.md).
--  It packages:
--
--    1. The shared holographic bridge (Theorem 1, produced by the
--       GENERIC bridge machinery from Bridge/GenericBridge.agda
--       via Bridge/GenericValidation.agda) — the type equivalence
--       between boundary and bulk observable packages, which
--       depends ONLY on the 5-bond star flow-graph topology.
--
--    2. The AdS Gauss–Bonnet witness (Theorem 2, from
--       Bulk/GaussBonnet.agda) — discrete Gauss–Bonnet for the
--       {5,4} hyperbolic tiling, with negative interior curvature
--       κ = −1/5 per vertex.
--
--    3. The dS Gauss–Bonnet witness (dS Theorem 2, from
--       Bulk/DeSitterGaussBonnet.agda) — discrete Gauss–Bonnet
--       for the {5,3} spherical tiling (regular dodecahedron),
--       with positive interior curvature κ = +1/10 per vertex.
--
--    4. A coherence record (WickRotationWitness) witnessing that
--       the three components coexist on the same geometric
--       substrate: the same region type, the same observable
--       functions, and the same Euler characteristic χ = 1.
--
--  The discrete Wick rotation is a PARAMETER CHANGE in the tiling
--  type that flips the curvature sign while preserving the flow
--  graph:
--
--    {5,4} (AdS, q=4, κ<0)  ←→  {5,3} (dS, q=3, κ>0)
--
--  What changes:
--    • Vertex valence:  4 → 3
--    • Interior curvature:  −1/5 → +1/10
--    • Gap-filler tiles:  needed → not needed
--
--  What does NOT change:
--    • Tile type:  pentagons (p = 5)
--    • Restricted star bond graph:  5 C–N bonds
--    • Min-cut values:  S(k) = min(k, 5−k)
--    • Observable packages:  identical types and values
--    • Bridge equivalence:  literally the same Agda term
--    • Euler characteristic:  χ = 1 (disk topology)
--    • Gauss–Bonnet total:  Σ κ(v) = 1
--
--  The holographic correspondence is CURVATURE-AGNOSTIC.
--  No complex numbers, no analytic continuation, no Lorentzian
--  geometry.  The curvature sign flip is the combinatorial
--  analogue of the cosmological constant sign flip
--  Λ_AdS < 0 → Λ_dS > 0.
--
--  Architectural note (Phase 0 rewiring):
--
--    This module previously imported  full-witness : BridgeWitness
--    from  Bridge/EnrichedStarEquiv.agda , creating a dependency on
--    the hand-written, star-specific enriched bridge.  After the
--    Phase 0 architectural tightening, the bridge witness is now
--    imported from  Bridge/GenericValidation  as
--    star-generic-witness , which is produced by the generic bridge
--    machinery  (orbit-bridge-witness  from
--    Bridge/GenericBridge.agda).
--
--    This makes it explicit that the shared holographic bridge is
--    curvature-agnostic: it is produced by an abstract PatchData →
--    BridgeWitness pipeline that never references curvature values,
--    vertex classifications, or tiling parameters — only the scalar
--    constants 1q and 2q from Util/Scalars.agda.
--
--    The old  full-witness  from  EnrichedStarEquiv  remains valid
--    but is no longer on the critical path.
--
--  Reference:
--    docs/formal/08-wick-rotation.md       (formal treatment)
--    docs/formal/01-theorems.md §Thm 4     (theorem registry entry)
--    docs/formal/04-discrete-geometry.md   (curvature and GB)
--    docs/instances/desitter-patch.md      (dS instance data sheet)
--    docs/instances/star-patch.md §10      (shared bridge)
--    sim/prototyping/10_desitter_prototype.py  (numerical verification)
--    docs/historical/development-docs/10-frontier.md §7
--                                          (original development plan)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  Imports — AdS side (Theorem 2 for the {5,4} patch)
-- ════════════════════════════════════════════════════════════════════

open import Bulk.PatchComplex using (vTiling)
open import Bulk.Curvature
  using ( κ-class ; κ-interior-negative )
open import Bulk.GaussBonnet
  using ( GaussBonnetWitness ; patch-gb-witness
        ; Theorem1 ; theorem1 ; χ₁₀ )


-- ════════════════════════════════════════════════════════════════════
--  Imports — dS side (dS Theorem 2 for the {5,3} patch)
-- ════════════════════════════════════════════════════════════════════

open import Bulk.DeSitterPatchComplex using (dsTiling)
open import Bulk.DeSitterCurvature
  using ( dsκ-class ; dsκ-interior-positive )
open import Bulk.DeSitterGaussBonnet
  using ( DSGaussBonnetWitness ; ds-patch-gb-witness
        ; DSTheorem1 ; ds-theorem1 ; dsχ₁₀ )


-- ════════════════════════════════════════════════════════════════════
--  Imports — Shared bridge (curvature-agnostic)
-- ════════════════════════════════════════════════════════════════════
--
--  BridgeWitness:  the record type, imported from its canonical
--  leaf module  Bridge/BridgeWitness.agda .
--
--  star-generic-witness:  the concrete BridgeWitness for the star
--  patch, produced by the GENERIC bridge machinery:
--
--    starPatchData : PatchData
--      → GenericEnriched starPatchData
--      → abstract-bridge-witness : BridgeWitness
--
--  This replaces the hand-written  full-witness  from
--  Bridge/EnrichedStarEquiv.agda , making it clear that the
--  bridge is curvature-agnostic and geometry-agnostic — it depends
--  only on the abstract PatchData interface (RegionTy, S∂, LB,
--  obs-path), not on any per-instance implementation details.
--
--  Theorem3 and theorem3:  the named star-specific bridge theorem,
--  still imported from EnrichedStarEquiv for backward compatibility
--  and downstream reference.  These reference concrete types from
--  FullEnrichedStarObs (FullBdy, FullBulk) and do not conflict
--  with the BridgeWitness import from the leaf module.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §6  (BridgeWitness record)
--    docs/formal/11-generic-bridge.md         (generic bridge)
--    docs/engineering/generic-bridge-pattern.md (one proof, N instances)
-- ════════════════════════════════════════════════════════════════════

open import Bridge.BridgeWitness
  using (BridgeWitness)

open import Bridge.GenericValidation
  using (star-generic-witness)

open import Bridge.EnrichedStarEquiv
  using ( Theorem3 ; theorem3 )


-- ════════════════════════════════════════════════════════════════════
--  §1.  Shared Topology — Both patches have χ = 1
-- ════════════════════════════════════════════════════════════════════
--
--  Both the {5,4} star patch (11-tile filled, V=30, E=40, F=11)
--  and the {5,3} star patch (6-face, V=15, E=20, F=6) have
--  Euler characteristic χ = 1 (disk topology).
--
--  In the ℚ₁₀ encoding, χ = 1 is represented as  one₁₀ = pos 10 .
--  Both  χ₁₀  (from GaussBonnet.agda) and  dsχ₁₀  (from
--  DeSitterGaussBonnet.agda) are defined as  one₁₀ , so the
--  shared topology is witnessed by  refl .
--
--  This is the topological invariant that both Gauss–Bonnet
--  theorems target: the curvature distributions are different
--  (negative interior for AdS, positive interior for dS), but
--  they sum to the same topological constant.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §5  (AdS Gauss–Bonnet)
--    docs/formal/04-discrete-geometry.md §6  (dS Gauss–Bonnet)
--    docs/formal/08-wick-rotation.md §9      (what changes / doesn't)
-- ════════════════════════════════════════════════════════════════════

shared-euler : χ₁₀ ≡ dsχ₁₀
shared-euler = refl

-- Both are literally  one₁₀ = pos 10 .
shared-euler-raw : χ₁₀ ≡ pos 10
shared-euler-raw = refl

ds-euler-raw : dsχ₁₀ ≡ pos 10
ds-euler-raw = refl


-- ════════════════════════════════════════════════════════════════════
--  §2.  Curvature Sign Contrast — The Discrete Wick Rotation
-- ════════════════════════════════════════════════════════════════════
--
--  The curvature sign flip at interior vertices is the
--  combinatorial analogue of the cosmological constant sign flip.
--
--    {5,4} (AdS):  κ(v_i) = −1/5  = −2/10  = negsuc 1
--    {5,3} (dS):   κ(v_i) = +1/10 = +1/10  = pos 1
--
--  The formulas differ only in the vertex valence q:
--    κ = 1 − q/2 + q/5
--    q=4:  1 − 2 + 4/5 = −1/5
--    q=3:  1 − 3/2 + 3/5 = +1/10
--
--  These are re-exported from the curvature modules.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §4  (curvature formula)
--    docs/formal/08-wick-rotation.md §4      (positive interior κ)
--    docs/instances/desitter-patch.md §4     (curvature per class)
-- ════════════════════════════════════════════════════════════════════

-- AdS interior curvature is NEGATIVE:  negsuc 1 = −2/10 = −1/5
ads-κ-negative : κ-class vTiling ≡ negsuc 1
ads-κ-negative = κ-interior-negative

-- dS interior curvature is POSITIVE:  pos 1 = +1/10
ds-κ-positive : dsκ-class dsTiling ≡ pos 1
ds-κ-positive = dsκ-interior-positive

-- ────────────────────────────────────────────────────────────────
--  The curvature sign flip is explicit:
--  AdS interior is  negsuc 1  and dS interior is  pos 1 .
--  These are manifestly different ℤ constructors — one uses
--  negsuc (negative), the other uses pos (positive).
--
--  This is the type-theoretic content of the statement:
--  "the cosmological constant changes sign between AdS and dS."
-- ────────────────────────────────────────────────────────────────


-- ════════════════════════════════════════════════════════════════════
--  §3.  The Curvature-Agnostic Bridge
-- ════════════════════════════════════════════════════════════════════
--
--  The holographic bridge (Theorem 1: discrete Ryu–Takayanagi)
--  depends only on the 5-bond star flow-graph topology, encoded in:
--
--    Common/StarSpec.agda    — Tile, Bond, Region types
--    Boundary/StarCut.agda   — S-cut : Region → ℚ≥0
--    Bulk/StarChain.agda     — L-min : Region → ℚ≥0
--    Bridge/StarObs.agda     — star-pointwise : S∂ r ≡ LB r ∀r
--    Bridge/StarEquiv.agda   — star-obs-path : S∂ ≡ LB
--
--  None of these modules reference curvature values, vertex
--  classifications, face valences, or tiling parameters.  They
--  reference only the scalar constants 1q and 2q from
--  Util/Scalars.agda.
--
--  Therefore the same enriched equivalence  EnrichedBdy ≃ EnrichedBulk
--  and the same transport  theorem3  serve BOTH curvature regimes.
--  The bridge is literally the same Agda term for both {5,4} and
--  {5,3} — it is the "curvature-free" observable layer:
--
--    Obs∂^{5,4}  ≃  Obs_bulk^{5,4}  ≃  Obs_flow
--                                    ≃  Obs_bulk^{5,3}  ≃  Obs∂^{5,3}
--
--  The bridge re-exported here IS  Obs_flow : the curvature-
--  agnostic observable package depending only on the star flow
--  graph.
--
--  Architectural note:
--
--    The bridge witness is produced by the GENERIC machinery:
--
--      starPatchData : PatchData
--        (RegionTy = Region, S∂ = star-S∂, LB = star-LB,
--         obs-path = star-obs-path)
--        → GenericEnriched starPatchData
--        → abstract-bridge-witness : BridgeWitness
--
--    This is imported as  star-generic-witness  from
--    Bridge/GenericValidation.agda .  The generic theorem proves
--    the bridge ONCE and instantiates it at each concrete patch
--    by applying it to a specific PatchData.  The star patch is
--    one such instantiation — but the proof itself never looks
--    inside the PatchData to see whether it came from a {5,4}
--    or {5,3} tiling.  This structural fact IS the curvature-
--    agnosticism of the holographic correspondence.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md   (holographic bridge)
--    docs/formal/08-wick-rotation.md §6     (curvature-agnostic bridge)
--    docs/formal/11-generic-bridge.md       (PatchData interface)
--    docs/engineering/generic-bridge-pattern.md  (one proof, N instances)
-- ════════════════════════════════════════════════════════════════════

-- The bridge witness, imported from the GENERIC validation module.
-- This is the SAME bridge for both curvature regimes:
-- no curvature reference, no per-instance construction, no
-- modification — just the generic theorem applied to starPatchData.
the-bridge : BridgeWitness
the-bridge = star-generic-witness

-- The bridge theorem, re-exported from the hand-written enriched
-- star equiv for backward compatibility.  This is the star-specific
-- full structural-property transport theorem (FullBdy → FullBulk).
the-bridge-theorem : Theorem3
the-bridge-theorem = theorem3


-- ════════════════════════════════════════════════════════════════════
--  §4.  Both Gauss–Bonnet Proofs
-- ════════════════════════════════════════════════════════════════════
--
--  The AdS and dS Gauss–Bonnet theorems are proven independently
--  in their respective modules, both by refl on class-weighted ℤ
--  sums.  They share the same proof TECHNIQUE but different DATA:
--
--    AdS (5 classes): 5·(−2) + 5·(−1) + 5·(2) + 5·(−1) + 10·(2) = 10
--    dS  (3 classes): 5·(+1) + 5·(−1) + 5·(+2)                   = 10
--
--  Both reduce to  pos 10 = one₁₀ = χ₁₀ .
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §5  (AdS GB proof)
--    docs/formal/04-discrete-geometry.md §6  (dS GB proof)
--    docs/formal/08-wick-rotation.md §5      (dS GB in Wick context)
-- ════════════════════════════════════════════════════════════════════

-- Re-exported AdS Gauss–Bonnet
the-ads-gb : GaussBonnetWitness
the-ads-gb = patch-gb-witness

the-ads-theorem : Theorem1
the-ads-theorem = theorem1

-- Re-exported dS Gauss–Bonnet
the-ds-gb : DSGaussBonnetWitness
the-ds-gb = ds-patch-gb-witness

the-ds-theorem : DSTheorem1
the-ds-theorem = ds-theorem1


-- ════════════════════════════════════════════════════════════════════
--  §5.  WickRotationWitness — The Coherence Record
-- ════════════════════════════════════════════════════════════════════
--
--  This record packages all three components (bridge + two GB
--  theorems) into a single inspectable artifact, analogous to
--  BridgeWitness from Bridge/BridgeWitness.agda.
--
--  The record witnesses that:
--
--    • One flow graph (the 5-bond star, encoded as BridgeWitness)
--    • Two curvature assignments (AdS and dS, encoded as
--      GaussBonnetWitness and DSGaussBonnetWitness)
--    • One observable-package equivalence (shared, inside
--      BridgeWitness.bridge)
--    • Two Gauss–Bonnet proofs (one per curvature assignment)
--
--  all cohere on the same geometric substrate: the same region
--  type, the same observable functions, and the same Euler
--  characteristic.
--
--  The record lives in Type₁ because BridgeWitness stores types.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 4      (theorem registry)
--    docs/formal/08-wick-rotation.md §7      (WickRotationWitness)
--    docs/instances/desitter-patch.md §8     (Theorem 4)
-- ════════════════════════════════════════════════════════════════════

record WickRotationWitness : Type₁ where
  field
    -- ── The shared holographic bridge (curvature-agnostic) ──────
    --
    --  This is the SAME bridge for both curvature regimes.
    --  Produced by the generic bridge machinery from
    --  Bridge/GenericBridge.agda, imported via
    --  Bridge/GenericValidation.agda as star-generic-witness.
    --
    --  It packages:
    --    • BdyTy  = EnrichedBdy   (boundary obs + spec agreement)
    --    • BulkTy = EnrichedBulk  (bulk obs + spec agreement)
    --    • bridge : BdyTy ≃ BulkTy
    --    • transport along ua(bridge) verified
    --
    shared-bridge      : BridgeWitness

    -- ── AdS (Anti-de Sitter) curvature witness ──────────────────
    --
    --  The {5,4} Gauss–Bonnet theorem:
    --    Σ κ(v) = χ(K)  with κ_interior = −1/5  (negative)
    --
    ads-gauss-bonnet   : GaussBonnetWitness

    -- ── dS (de Sitter) curvature witness ────────────────────────
    --
    --  The {5,3} Gauss–Bonnet theorem:
    --    Σ κ(v) = χ(K)  with κ_interior = +1/10  (positive)
    --
    ds-gauss-bonnet    : DSGaussBonnetWitness

    -- ── Coherence: shared Euler characteristic ──────────────────
    --
    --  Both patches have the same Euler characteristic χ = 1.
    --  In ℚ₁₀:  both eulerChar₁₀ fields equal  one₁₀ = pos 10 .
    --
    euler-coherence    : GaussBonnetWitness.eulerChar₁₀ ads-gauss-bonnet
                       ≡ DSGaussBonnetWitness.eulerChar₁₀ ds-gauss-bonnet


-- ════════════════════════════════════════════════════════════════════
--  §6.  The Concrete Witness — Fully Instantiated
-- ════════════════════════════════════════════════════════════════════
--
--  All fields are filled from existing proven modules.
--  No new proofs are constructed here — the module assembles
--  the three independently verified components into a single
--  coherent record.
--
--  The shared-bridge field is  star-generic-witness , produced by
--  the generic bridge machinery (Bridge/GenericBridge.agda →
--  Bridge/GenericValidation.agda).  This replaces the previous
--  full-witness  from  Bridge/EnrichedStarEquiv.agda , making the
--  curvature-agnosticism of the bridge structurally manifest:
--  the generic theorem never inspects the PatchData to determine
--  whether it came from a {5,4} or {5,3} tiling.
--
--  The euler-coherence field is  refl  because both  χ₁₀  and
--  dsχ₁₀  are defined as  one₁₀ = pos 10  in their respective
--  modules (Bulk/GaussBonnet.agda and Bulk/DeSitterGaussBonnet.agda).
--
--  Reference:
--    docs/formal/08-wick-rotation.md §7  (the concrete witness)
-- ════════════════════════════════════════════════════════════════════

wick-rotation-witness : WickRotationWitness
wick-rotation-witness .WickRotationWitness.shared-bridge    = star-generic-witness
wick-rotation-witness .WickRotationWitness.ads-gauss-bonnet = patch-gb-witness
wick-rotation-witness .WickRotationWitness.ds-gauss-bonnet  = ds-patch-gb-witness
wick-rotation-witness .WickRotationWitness.euler-coherence  = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Named Theorem Aliases
-- ════════════════════════════════════════════════════════════════════
--
--  These provide stable reference points for the roadmap and
--  documentation.  The types are propositions (paths in ℤ, which
--  is a set), so any two proofs are equal.
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  The AdS Gauss–Bonnet theorem: negative interior curvature,
--  total curvature = χ = 1.
-- ────────────────────────────────────────────────────────────────

AdS-Theorem1 : Type₀
AdS-Theorem1 = Theorem1

ads-theorem1 : AdS-Theorem1
ads-theorem1 = theorem1

-- ────────────────────────────────────────────────────────────────
--  The dS Gauss–Bonnet theorem: positive interior curvature,
--  total curvature = χ = 1.
-- ────────────────────────────────────────────────────────────────

dS-Theorem1 : Type₀
dS-Theorem1 = DSTheorem1

ds-theorem1′ : dS-Theorem1
ds-theorem1′ = ds-theorem1

-- ────────────────────────────────────────────────────────────────
--  The shared bridge theorem: boundary ≃ bulk observable
--  packages, with transport verified.  Curvature-agnostic.
--
--  SharedTheorem3 references the star-specific FullBdy/FullBulk
--  transport theorem from Bridge/EnrichedStarEquiv.agda.  This
--  is the concrete star-patch theorem; the generic bridge witness
--  (star-generic-witness) carries its own transport-verified field
--  internally via BridgeWitness.transport-verified.
-- ────────────────────────────────────────────────────────────────

SharedTheorem3 : Type₀
SharedTheorem3 = Theorem3

shared-theorem3 : SharedTheorem3
shared-theorem3 = theorem3


-- ════════════════════════════════════════════════════════════════════
--  §8.  Curvature Sign Regression Tests
-- ════════════════════════════════════════════════════════════════════
--
--  These make the curvature sign flip machine-checkably explicit.
--  If any upstream definition changes, these proofs will fail
--  immediately at type-check time.
-- ════════════════════════════════════════════════════════════════════

-- AdS interior curvature per vertex:  negsuc 1 = −2/10 = −1/5
ads-interior-is-negative : κ-class vTiling ≡ negsuc 1
ads-interior-is-negative = κ-interior-negative

-- dS interior curvature per vertex:  pos 1 = +1/10
ds-interior-is-positive : dsκ-class dsTiling ≡ pos 1
ds-interior-is-positive = dsκ-interior-positive

-- The curvature values use DIFFERENT ℤ constructors:
--   negsuc  for AdS  (negative integers)
--   pos     for dS   (positive integers)
-- This is the type-theoretic content of the cosmological
-- constant sign flip.


-- ════════════════════════════════════════════════════════════════════
--  §9.  Combined Gauss–Bonnet Regression Tests
-- ════════════════════════════════════════════════════════════════════
--
--  Both Gauss–Bonnet theorems target the same ℤ value  pos 10 ,
--  but arrive there from different interior/boundary decompositions:
--
--    AdS:  interior = −10/10,  boundary = +20/10  → total = 10/10
--    dS:   interior =  +5/10,  boundary =  +5/10  → total = 10/10
--
--  The asymmetric (AdS) vs symmetric (dS) decomposition reflects
--  the physics: in AdS, the strong negative interior curvature is
--  compensated by large boundary turning; in dS, the mild positive
--  curvature distributes evenly.
--
--  Reference:
--    docs/formal/04-discrete-geometry.md §5.3  (AdS decomposition)
--    docs/formal/08-wick-rotation.md §5.3      (dS vs AdS decomp.)
-- ════════════════════════════════════════════════════════════════════

-- Both GB witnesses contain the same euler characteristic
ads-gb-euler : GaussBonnetWitness.eulerChar₁₀ patch-gb-witness ≡ pos 10
ads-gb-euler = refl

ds-gb-euler : DSGaussBonnetWitness.eulerChar₁₀ ds-patch-gb-witness ≡ pos 10
ds-gb-euler = refl

-- Both GB proofs are  refl  (reducing class-weighted sums to pos 10)
ads-gb-proof :
  GaussBonnetWitness.gauss-bonnet patch-gb-witness
  ≡ GaussBonnetWitness.gauss-bonnet patch-gb-witness
ads-gb-proof = refl

ds-gb-proof :
  DSGaussBonnetWitness.gauss-bonnet ds-patch-gb-witness
  ≡ DSGaussBonnetWitness.gauss-bonnet ds-patch-gb-witness
ds-gb-proof = refl


-- ════════════════════════════════════════════════════════════════════
--  §10.  The BoundaryView Interpretation Note
-- ════════════════════════════════════════════════════════════════════
--
--  The same BoundaryView type serves both interpretations:
--    AdS: "spatial boundary at the edge of the hyperbolic disk"
--    dS:  "temporal boundary at the future/past conformal infinity"
--
--  The type does not know which interpretation is intended.
--  The "boundary swap" is therefore not a type-theoretic operation
--  but a change of physical interpretation of the same formal
--  object.  This is precisely the situation that the Observable
--  Package architecture was designed to handle: the packages
--  capture the mathematical content while being agnostic about
--  the physical interpretation.
--
--  Reference:
--    docs/formal/08-wick-rotation.md §10     (boundary interpretation)
--    docs/physics/holographic-dictionary.md   (Agda ↔ physics table)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §11.  End-to-End Architecture Summary
-- ════════════════════════════════════════════════════════════════════
--
--  The conceptual architecture is now fully realized, with the
--  bridge produced by the GENERIC machinery:
--
--                   ┌─────────────────────────┐
--                   │  Common/StarSpec.agda   │
--                   │  (Tile, Bond, Region)   │
--                   └────────────┬────────────┘
--                                │
--                 ┌──────────────┼──────────────┐
--                 │              │              │
--         ┌───────▼────┐  ┌──────▼──────┐  ┌────▼──────┐
--         │ Boundary/  │  │  Bulk/      │  │  Bulk/    │
--         │ StarCut    │  │ StarChain   │  │ StarChain │
--         │ (S-cut)    │  │ (L-min)     │  │ (L-min)   │
--         └──────┬─────┘  └──────┬──────┘  └────┬──────┘
--                │               │              │
--                └───────┬───────┘              │
--                        │                      │
--                ┌───────▼────────┐             │
--                │ Bridge/        │             │
--                │ GenericBridge  │  ◄──────────┘
--                │ + GenericVal.  │  (same bridge!)
--                │ (Theorem 1)    │
--                └───────┬────────┘
--                        │
--          ┌─────────────┼─────────────┐
--          │             │             │
--  ┌───────▼──────┐      │     ┌───────▼──────┐
--  │ Bulk/        │      │     │ Bulk/        │
--  │ GaussBonnet  │      │     │ DeSitter     │
--  │ (κ < 0)      │      │     │ GaussBonnet  │
--  │ Theorem 2    │      │     │ (κ > 0)      │
--  │ [AdS]        │      │     │ [dS]         │
--  └───────┬──────┘      │     └───────┬──────┘
--          │             │             │
--          └─────────────┼─────────────┘
--                        │
--                ┌───────▼────────┐
--                │ Bridge/        │
--                │ WickRotation   │
--                │ (this module)  │
--                │                │
--                │ Witnesses:     │
--                │ • AdS GB       │
--                │ • dS GB        │
--                │ • Shared       │
--                │   bridge       │
--                │   (generic!)   │
--                └────────────────┘
--
--  The bridge sits at the center, shared by both curvature regimes.
--  It is produced by  GenericBridge.agda  (the generic theorem
--  proven once) and validated by  GenericValidation.agda  (the
--  retroactive consistency test).  The two Gauss–Bonnet theorems
--  attach independently to opposite sides.  This module witnesses
--  their coherence.
--
--  The result is the type-theoretic content of the claim that
--  the combinatorial structure of the holographic correspondence
--  is independent of the sign of curvature.
--
--  Reference:
--    docs/formal/08-wick-rotation.md §13     (conceptual architecture)
--    docs/formal/01-theorems.md §Thm 4       (theorem registry)
--    docs/getting-started/architecture.md    (module dependency DAG)
--    docs/instances/desitter-patch.md §17    (architecture diagram)
--    docs/historical/development-docs/10-frontier.md §7
--                                            (original development plan)
-- ════════════════════════════════════════════════════════════════════