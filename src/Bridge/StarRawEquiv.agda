{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.StarRawEquiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Transport

open import Cubical.Data.Sigma using (ΣPathP)

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCut  using (S-cut ; π∂)
open import Bulk.StarChain    using (L-min ; πbulk)
open import Bridge.StarObs    using (star-pointwise)
open import Bridge.StarEquiv  using (star-obs-path)
open import Bridge.EnrichedStarObs
  using (S∂ ; LB ; isSetObs)


-- ════════════════════════════════════════════════════════════════════
--  Raw Structural Equivalence for the 6-Tile Star Patch
-- ════════════════════════════════════════════════════════════════════
--
--  STATUS:  DEAD CODE — superseded by the generic bridge
--           (Bridge/GenericBridge.agda).  This module remains valid
--           and type-checks, but it is NOT on the critical path.
--           The star patch's BridgeWitness is now produced by
--           GenericEnriched via Bridge/GenericValidation.agda
--           (star-generic-witness : BridgeWitness).
--
--  This module constructs an exact type equivalence between the raw
--  boundary type (min-cut functionals over Region) and the raw bulk
--  type (bond-weight assignments over Bond) for the 6-tile star
--  patch of the {5,4} HaPPY code.
--
--  The boundary type lives over the 10-constructor domain Region;
--  the bulk type lives over the 5-constructor domain Bond.  The
--  equivalence encodes the discrete Ryu–Takayanagi correspondence
--  at the structural level: 10-dimensional boundary entanglement
--  data and 5-dimensional bulk geometric data carry exactly the
--  same information.
--
--  Strategy: Reconstruction Fiber.  The forward map computes
--  min-cuts from bond weights (RT direction); the backward map
--  extracts bond weights from singleton min-cuts (holographic
--  reconstruction).  Both types are contractible (singleton types),
--  so the round-trip proofs are automatic.
--
--  Architectural role:
--    This is a Tier 3 (Bridge Layer) module providing an alternative
--    structural equivalence between genuinely different carrier types
--    (5-constructor Bond → ℚ≥0 vs 10-constructor Region → ℚ≥0).
--    Unlike the enriched equivalence in Bridge/EnrichedStarObs.agda
--    (which operates on reversed singletons with the SAME carrier
--    Region → ℚ≥0), this module connects types with different
--    domains.  However, both types are contractible, so the
--    equivalence is "trivially forced" by the type structure.
--    The physical content resides in the EXPLICIT MAPS, not in the
--    round-trip proofs.
--
--  The generic bridge from Bridge/GenericBridge.agda subsumes
--  the enriched-equivalence part of the star bridge.  This raw
--  structural equivalence is a separate, complementary construction
--  that demonstrates the holographic maps explicitly.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md   (holographic bridge)
--    docs/instances/star-patch.md §2        (star patch topology)
--    docs/instances/star-patch.md §4        (min-cut / observable
--                                            agreement table)
--    docs/formal/11-generic-bridge.md       (generic bridge —
--                                            supersedes this)
--    docs/reference/module-index.md         (module description:
--                                            DEAD CODE)
--    docs/getting-started/architecture.md   (Bridge Layer)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Shorthand and h-level infrastructure
-- ════════════════════════════════════════════════════════════════════

-- The bulk bond-weight specification (alias for readability)
sw : Bond → ℚ≥0
sw = starWeight

-- Bond → ℚ≥0 is a set (h-level 2)
isSetBondW : isSet (Bond → ℚ≥0)
isSetBondW = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Raw structural types
-- ════════════════════════════════════════════════════════════════════
--
--  The raw boundary type: a function from the 10-constructor
--  Region type to ℚ≥0, certified to agree with the boundary
--  min-cut specification S∂.
--
--  The raw bulk type: a function from the 5-constructor Bond type
--  to ℚ≥0, certified to agree with the bulk bond-weight
--  specification starWeight.
--
--  These are genuinely different types — their carriers have
--  different domains (10 constructors vs 5 constructors).  The
--  specification-agreement field pins each type to a single
--  inhabitant, making both contractible.
-- ════════════════════════════════════════════════════════════════════

RawStarBdy : Type₀
RawStarBdy = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ S∂)

RawStarBulk : Type₀
RawStarBulk = Σ[ w ∈ (Bond → ℚ≥0) ] (w ≡ sw)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════

raw-bdy : RawStarBdy
raw-bdy = S∂ , refl

raw-bulk : RawStarBulk
raw-bulk = sw , refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  Holographic reconstruction maps
-- ════════════════════════════════════════════════════════════════════
--
--  Forward (Ryu–Takayanagi direction): bond weights → min-cuts.
--
--  For singleton regions {Ni}, the min-cut severs the single bond
--  C–Ni, giving cost w(bCNi).  For adjacent pair regions
--  {Ni, Ni+1}, the min-cut severs the two bonds C–Ni and C–Ni+1,
--  giving cost w(bCNi) + w(bCNi+1).
--
--  This is the discrete analogue of the Ryu–Takayanagi formula:
--  the entanglement entropy of a boundary region equals the
--  "area" (total weight) of the minimal bulk surface separating
--  the region from its complement.
--
--  This definition is equivalent to S-param from
--  Boundary/StarCutParam.agda (the parameterized boundary min-cut
--  used by the dynamics layer).
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §2  (the discrete RT
--                                              correspondence)
--    docs/instances/star-patch.md §4           (min-cut / observable
--                                              agreement table)
--    docs/formal/10-dynamics.md §2             (parameterized
--                                              observables: S-param)
-- ════════════════════════════════════════════════════════════════════

minCutFromWeights : (Bond → ℚ≥0) → (Region → ℚ≥0)
minCutFromWeights w regN0   = w bCN0
minCutFromWeights w regN1   = w bCN1
minCutFromWeights w regN2   = w bCN2
minCutFromWeights w regN3   = w bCN3
minCutFromWeights w regN4   = w bCN4
minCutFromWeights w regN0N1 = w bCN0 +ℚ w bCN1
minCutFromWeights w regN1N2 = w bCN1 +ℚ w bCN2
minCutFromWeights w regN2N3 = w bCN2 +ℚ w bCN3
minCutFromWeights w regN3N4 = w bCN3 +ℚ w bCN4
minCutFromWeights w regN4N0 = w bCN4 +ℚ w bCN0

-- ────────────────────────────────────────────────────────────────
--  Backward (Holographic reconstruction): min-cuts → bond weights.
--
--  For each bond C–Ni, the weight is the singleton min-cut value
--  of region {Ni}.  In the star topology, the singleton min-cut
--  directly reveals the bond weight because {Ni} is separated
--  from its complement by the single bond C–Ni.
--
--  The pair values are NOT used: in the star topology they are
--  redundant (each pair value is the sum of two singleton values).
--  This is the discrete analogue of entanglement wedge
--  reconstruction: the boundary entanglement data uniquely
--  determines the bulk geometry.
-- ────────────────────────────────────────────────────────────────

weightsFromMinCut : (Region → ℚ≥0) → (Bond → ℚ≥0)
weightsFromMinCut f bCN0 = f regN0
weightsFromMinCut f bCN1 = f regN1
weightsFromMinCut f bCN2 = f regN2
weightsFromMinCut f bCN3 = f regN3
weightsFromMinCut f bCN4 = f regN4


-- ════════════════════════════════════════════════════════════════════
--  §5.  Specification agreement lemmas
-- ════════════════════════════════════════════════════════════════════
--
--  The RT lemma: computing min-cuts from the canonical bulk
--  specification produces the boundary specification.
--
--  This is the computational core of the discrete RT formula for
--  the 6-tile star.  All 10 cases hold by refl because:
--
--    Singletons:  sw bCNi = 1q = S∂ regNi
--    Pairs:       sw bCNi +ℚ sw bCNj = 1 + 1 = 2 = S∂ regNiNj
--
--  The pair cases rely on ℕ addition computing judgmentally:
--  suc zero + suc zero = suc (suc zero) = 2q.
--
--  The shared-constants discipline (constants defined once in
--  Util/Scalars.agda and imported everywhere) is what enables
--  all refl proofs — see docs/formal/02-foundations.md §6.3.
-- ════════════════════════════════════════════════════════════════════

rt-pointwise : (r : Region) → minCutFromWeights sw r ≡ S∂ r
rt-pointwise regN0   = refl
rt-pointwise regN1   = refl
rt-pointwise regN2   = refl
rt-pointwise regN3   = refl
rt-pointwise regN4   = refl
rt-pointwise regN0N1 = refl     -- 1 + 1 = 2 ≡ 2
rt-pointwise regN1N2 = refl
rt-pointwise regN2N3 = refl
rt-pointwise regN3N4 = refl
rt-pointwise regN4N0 = refl

rt-lemma : minCutFromWeights sw ≡ S∂
rt-lemma = funExt rt-pointwise

-- ────────────────────────────────────────────────────────────────
--  The extraction lemma: extracting bond weights from the boundary
--  specification produces the bulk specification.
--
--  All 5 cases hold by refl because S∂ regNi = 1q = sw bCNi.
-- ────────────────────────────────────────────────────────────────

extr-pointwise : (b : Bond) → weightsFromMinCut S∂ b ≡ sw b
extr-pointwise bCN0 = refl
extr-pointwise bCN1 = refl
extr-pointwise bCN2 = refl
extr-pointwise bCN3 = refl
extr-pointwise bCN4 = refl

extr-lemma : weightsFromMinCut S∂ ≡ sw
extr-lemma = funExt extr-pointwise


-- ════════════════════════════════════════════════════════════════════
--  §6.  Contractibility of both raw types
-- ════════════════════════════════════════════════════════════════════
--
--  Both RawStarBdy and RawStarBulk are "reversed singleton types"
--  of the form  Σ[ x ∈ A ] (x ≡ a) , which is contractible for
--  any  a : A .  The center is  (a , refl)  and the contraction
--  path is constructed from the given identification  p : x ≡ a .
--
--  This is the type-theoretic expression of the reconstruction
--  fiber being contractible: given any boundary (resp. bulk)
--  configuration satisfying the specification, there is a unique
--  such configuration.  For the 6-tile star, this uniqueness is
--  built into the singleton type by definition.  For larger
--  patches, proving contractibility would require a genuine
--  reconstruction argument.
--
--  Reference:
--    docs/formal/02-foundations.md §1  (h-levels: contractible types)
--    docs/formal/02-foundations.md §7  (the generic bridge pattern —
--                                       uses isContr-Singl)
-- ════════════════════════════════════════════════════════════════════

private
  isContrRevSingl : ∀ {ℓ} {A : Type ℓ} (a : A)
    → isContr (Σ[ x ∈ A ] (x ≡ a))
  isContrRevSingl a .fst = a , refl
  isContrRevSingl a .snd (x , p) i =
    p (~ i) , λ j → p (~ i ∨ j)

isContr-RawBdy : isContr RawStarBdy
isContr-RawBdy = isContrRevSingl S∂

isContr-RawBulk : isContr RawStarBulk
isContr-RawBulk = isContrRevSingl sw


-- ════════════════════════════════════════════════════════════════════
--  §7.  The Iso between raw types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map is the Ryu–Takayanagi computation: given a bulk
--  bond-weight assignment (w, w≡sw), compute the min-cut profile
--  minCutFromWeights w and certify it against S∂ using the RT lemma.
--
--  The backward map is holographic reconstruction: given a boundary
--  min-cut profile (f, f≡S∂), extract the bond weights
--  weightsFromMinCut f and certify them against sw using the
--  extraction lemma.
--
--  The round-trip proofs use contractibility: both types are
--  contractible, so any two elements are connected by a unique
--  path.  This is invoked via  isContr→isProp .
-- ════════════════════════════════════════════════════════════════════

raw-iso : Iso RawStarBulk RawStarBdy
raw-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    -- Ryu–Takayanagi direction: bulk → boundary
    fwd : RawStarBulk → RawStarBdy
    fwd (w , p) = minCutFromWeights w , cong minCutFromWeights p ∙ rt-lemma

    -- Reconstruction direction: boundary → bulk
    bwd : RawStarBdy → RawStarBulk
    bwd (f , q) = weightsFromMinCut f , cong weightsFromMinCut q ∙ extr-lemma

    -- Round trip: both types are propositions (contractible ⇒ prop)
    fwd-bwd : (b : RawStarBdy) → fwd (bwd b) ≡ b
    fwd-bwd b = isContr→isProp isContr-RawBdy (fwd (bwd b)) b

    bwd-fwd : (a : RawStarBulk) → bwd (fwd a) ≡ a
    bwd-fwd a = isContr→isProp isContr-RawBulk (bwd (fwd a)) a


-- ════════════════════════════════════════════════════════════════════
--  §8.  The equivalence
-- ════════════════════════════════════════════════════════════════════

raw-equiv : RawStarBulk ≃ RawStarBdy
raw-equiv = isoToEquiv raw-iso


-- ════════════════════════════════════════════════════════════════════
--  §9.  The Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Applying  ua  yields a path in the universe Type₀ between the
--  raw bulk type (over the 5-constructor Bond domain) and the raw
--  boundary type (over the 10-constructor Region domain).
--
--  This is a genuinely nontrivial path: the two types have
--  different carrier function spaces, and the path threads through
--  the Glue type encoding the holographic reconstruction maps.
--
--  Reference:
--    docs/formal/02-foundations.md §5  (the Univalence axiom, ua,
--                                       uaβ in Cubical Agda)
-- ════════════════════════════════════════════════════════════════════

raw-ua-path : RawStarBulk ≡ RawStarBdy
raw-ua-path = ua raw-equiv


-- ════════════════════════════════════════════════════════════════════
--  §10.  Transport: the verified structural translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along the Univalence path converts the canonical bulk
--  instance (starWeight, refl) to the canonical boundary instance
--  (S∂, refl).
--
--  By uaβ, transport computes as the forward map of the
--  equivalence: it applies  minCutFromWeights  to the bond weights
--  and certifies the result against S∂ using the RT lemma.
--
--  This is the "compilation step" at the raw structural level:
--  a verified translator from 5-dimensional bulk geometric data
--  to 10-dimensional boundary entanglement data.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1  (uaβ — transport computes)
--    docs/formal/03-holographic-bridge.md §3.4  (verified transport)
-- ════════════════════════════════════════════════════════════════════

-- Step 1: uaβ reduces transport to the forward map
raw-transport-computes :
  transport raw-ua-path raw-bulk
  ≡ equivFun raw-equiv raw-bulk
raw-transport-computes = uaβ raw-equiv raw-bulk

-- Step 2: the forward map output equals the boundary instance
-- Both types are contractible, so any two inhabitants are equal.
private
  raw-fwd-eq-bdy : equivFun raw-equiv raw-bulk ≡ raw-bdy
  raw-fwd-eq-bdy = isContr→isProp isContr-RawBdy _ _

-- Combined: transport produces the boundary instance
raw-transport :
  transport raw-ua-path raw-bulk ≡ raw-bdy
raw-transport = raw-transport-computes ∙ raw-fwd-eq-bdy


-- ════════════════════════════════════════════════════════════════════
--  §11.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported bulk instance equals S∂.
--
--  In operational terms: given the bulk bond-weight assignment
--  starWeight (5 values), the raw structural translator produces
--  the boundary min-cut functional S∂ (10 values), with the 5
--  pair values computed from the singleton values by addition.
-- ════════════════════════════════════════════════════════════════════

raw-transport-obs :
  fst (transport raw-ua-path raw-bulk) ≡ S∂
raw-transport-obs = cong fst raw-transport


-- ════════════════════════════════════════════════════════════════════
--  §12.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════

raw-transport-pointwise :
  (r : Region) →
  fst (transport raw-ua-path raw-bulk) r ≡ S∂ r
raw-transport-pointwise r = cong (λ f → f r) raw-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §13.  Reverse transport
-- ════════════════════════════════════════════════════════════════════
--
--  The reverse direction: boundary entanglement data → bulk
--  geometric data.  Transport along  sym raw-ua-path  converts
--  the boundary instance to the bulk instance.
-- ════════════════════════════════════════════════════════════════════

raw-reverse :
  transport (sym raw-ua-path) raw-bdy ≡ raw-bulk
raw-reverse =
    cong (transport (sym raw-ua-path)) (sym raw-transport)
  ∙ transport⁻Transport raw-ua-path raw-bulk


-- ════════════════════════════════════════════════════════════════════
--  §14.  Roundtrip verification
-- ════════════════════════════════════════════════════════════════════

raw-roundtrip-bulk :
  transport (sym raw-ua-path)
    (transport raw-ua-path raw-bulk)
  ≡ raw-bulk
raw-roundtrip-bulk = transport⁻Transport raw-ua-path raw-bulk

raw-roundtrip-bdy :
  transport raw-ua-path
    (transport (sym raw-ua-path) raw-bdy)
  ≡ raw-bdy
raw-roundtrip-bdy = transportTransport⁻ raw-ua-path raw-bdy


-- ════════════════════════════════════════════════════════════════════
--  §15.  Compatibility with the observable-level bridge
-- ════════════════════════════════════════════════════════════════════
--
--  The raw structural equivalence is compatible with the existing
--  bridge levels.  All levels produce the same boundary-side
--  function S∂ when the bulk specification is transported:
--
--    Level 1 (value path):       star-obs-path : S∂ ≡ LB
--    Level 2 (enriched spec):    enriched-transport-obs
--    Level 3 (full structural):  full-transport-obs
--    Level 4 (raw structural):   raw-transport-obs
--
--  The coherence is witnessed by the fact that all four extract
--  the same function S∂ = S-cut (π∂ starSpec) from their
--  respective transported instances.
--
--  The generic bridge from Bridge/GenericBridge.agda (the core
--  innovation of the repository) subsumes Levels 1–2 for any
--  PatchData instance.  See docs/formal/11-generic-bridge.md.
-- ════════════════════════════════════════════════════════════════════

-- The raw transport's extracted function agrees with the
-- observable-level boundary function.
raw-obs-coherence :
  fst (transport raw-ua-path raw-bulk) ≡ S∂
raw-obs-coherence = raw-transport-obs

-- Connection to star-obs-path: since LB = S∂ by star-obs-path,
-- the raw transport is also compatible with the bulk observable.
raw-bulk-coherence :
  fst (transport raw-ua-path raw-bulk) ≡ LB
raw-bulk-coherence = raw-transport-obs ∙ star-obs-path


-- ════════════════════════════════════════════════════════════════════
--  §16.  Concrete pointwise computations
-- ════════════════════════════════════════════════════════════════════
--
--  Demonstrate that the transported observable produces the correct
--  numerical values at specific boundary regions.
--
--  These hold by refl (via raw-transport-pointwise) because all
--  operations — minCutFromWeights, starWeight, ℕ addition — compute
--  by structural recursion on closed constructor terms, and the
--  scalar constants are imported from Util/Scalars.agda (the
--  shared-constants discipline from docs/formal/02-foundations.md §6.3).
-- ════════════════════════════════════════════════════════════════════

-- Singleton: transport produces 1 for {N0}
raw-at-N0 :
  fst (transport raw-ua-path raw-bulk) regN0 ≡ 1q
raw-at-N0 = raw-transport-pointwise regN0

-- Singleton: transport produces 1 for {N3}
raw-at-N3 :
  fst (transport raw-ua-path raw-bulk) regN3 ≡ 1q
raw-at-N3 = raw-transport-pointwise regN3

-- Adjacent pair: transport produces 2 for {N0, N1}
raw-at-N0N1 :
  fst (transport raw-ua-path raw-bulk) regN0N1 ≡ 2q
raw-at-N0N1 = raw-transport-pointwise regN0N1

-- Adjacent pair: transport produces 2 for {N2, N3}
raw-at-N2N3 :
  fst (transport raw-ua-path raw-bulk) regN2N3 ≡ 2q
raw-at-N2N3 = raw-transport-pointwise regN2N3


-- ════════════════════════════════════════════════════════════════════
--  §17.  RawBridgeWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the raw structural equivalence into a single
--  inspectable artifact, following the BridgeWitness pattern
--  from Bridge/BridgeWitness.agda.
--
--  Note: the canonical BridgeWitness for the star patch is now
--  star-generic-witness from Bridge/GenericValidation.agda,
--  produced by the generic bridge machinery.  This raw witness
--  is a separate, complementary construction demonstrating the
--  explicit holographic maps between genuinely different carrier
--  types (Bond → ℚ≥0 vs Region → ℚ≥0).
-- ════════════════════════════════════════════════════════════════════

record RawBridgeWitness : Type₁ where
  field
    BulkTy             : Type₀
    BdyTy              : Type₀
    bulk-data          : BulkTy
    bdy-data           : BdyTy
    bridge             : BulkTy ≃ BdyTy
    transport-verified : transport (ua bridge) bulk-data ≡ bdy-data

raw-bridge-witness : RawBridgeWitness
raw-bridge-witness .RawBridgeWitness.BulkTy             = RawStarBulk
raw-bridge-witness .RawBridgeWitness.BdyTy              = RawStarBdy
raw-bridge-witness .RawBridgeWitness.bulk-data           = raw-bulk
raw-bridge-witness .RawBridgeWitness.bdy-data            = raw-bdy
raw-bridge-witness .RawBridgeWitness.bridge              = raw-equiv
raw-bridge-witness .RawBridgeWitness.transport-verified  = raw-transport


-- ════════════════════════════════════════════════════════════════════
--  §18.  The explicit holographic maps on canonical instances
-- ════════════════════════════════════════════════════════════════════
--
--  These regression tests verify that the holographic maps produce
--  the expected values when applied to the canonical instances,
--  independently of the equivalence construction.
-- ════════════════════════════════════════════════════════════════════

-- RT direction: starWeight → S∂
-- minCutFromWeights sw = S∂  (by rt-lemma)
rt-on-canonical : minCutFromWeights sw ≡ S∂
rt-on-canonical = rt-lemma

-- Reconstruction direction: S∂ → starWeight
-- weightsFromMinCut S∂ = sw  (by extr-lemma)
recon-on-canonical : weightsFromMinCut S∂ ≡ sw
recon-on-canonical = extr-lemma

-- Spot checks on individual regions/bonds:

-- RT: starWeight bCN2 = 1 → minCut regN2 = 1
rt-spot-singleton : minCutFromWeights sw regN2 ≡ 1q
rt-spot-singleton = refl

-- RT: starWeight bCN3 + starWeight bCN4 = 2 → minCut regN3N4 = 2
rt-spot-pair : minCutFromWeights sw regN3N4 ≡ 2q
rt-spot-pair = refl

-- Reconstruction: S∂ regN4 = 1 → weight bCN4 = 1
recon-spot : weightsFromMinCut S∂ bCN4 ≡ 1q
recon-spot = refl

-- Round trip: extract (compute sw) = sw  (on a specific bond)
roundtrip-spot :
  weightsFromMinCut (minCutFromWeights sw) bCN1 ≡ sw bCN1
roundtrip-spot = refl


-- ════════════════════════════════════════════════════════════════════
--  §19.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  STATUS:  DEAD CODE — superseded by Bridge/GenericBridge.agda.
--  This module is NOT on the critical path of the repository.
--  The star patch's BridgeWitness is now produced by the generic
--  bridge machinery (star-generic-witness from
--  Bridge/GenericValidation.agda).  This module remains valid
--  as a historical artifact and as a demonstration of explicit
--  holographic maps between genuinely different carrier types.
--
--  Architecture:
--
--    RawStarBulk  ≃  RawStarBdy
--        │                │
--        │  forward       │  backward
--        │  (RT map)      │  (reconstruction)
--        ▼                ▼
--    minCutFromWeights    weightsFromMinCut
--    (5 bonds → 10 cuts) (10 cuts → 5 bonds)
--
--  The forward map is the discrete Ryu–Takayanagi computation;
--  the backward map is holographic reconstruction.  Both maps
--  are explicit 10-clause / 5-clause pattern matches, and the
--  specification agreement lemmas (rt-lemma, extr-lemma) are
--  verified by 10 / 5 cases of refl.
--
--  Limitations:
--
--    Both raw types are contractible (singleton types centered at
--    their specification functions), so the equivalence is
--    "trivially forced" by the type structure.  The physical
--    content lives in the EXPLICIT MAPS, not in the round-trip
--    proofs.  For larger patches where the reconstruction fiber
--    is not contractible by definition, proving contractibility
--    would be the hard part of the construction.
--
--  Relationship to other modules:
--
--    Bridge/StarEquiv.agda           — value-level package path
--    Bridge/EnrichedStarObs.agda     — spec-agreement equivalence
--    Bridge/FullEnrichedStarObs.agda — full structural-property equiv
--    Bridge/StarRawEquiv.agda        — raw structural equiv (this module)
--    Bridge/GenericBridge.agda       — generic bridge (subsumes the
--                                       enriched equivalence for any
--                                       PatchData; the raw structural
--                                       equiv is a separate construction
--                                       on different carrier types)
--
--  All four hand-written star bridge levels produce the same
--  S∂/LB identification and cohere via raw-obs-coherence and
--  raw-bulk-coherence.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md    (holographic bridge)
--    docs/formal/11-generic-bridge.md        (generic bridge —
--                                             supersedes enriched
--                                             part of this module)
--    docs/instances/star-patch.md            (star patch data sheet)
--    docs/instances/filled-patch.md §8       (FilledRawEquiv — the
--                                             11-tile analogue)
--    docs/reference/module-index.md          (module: DEAD CODE)
--    docs/getting-started/architecture.md    (Bridge Layer)
-- ════════════════════════════════════════════════════════════════════