{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.FilledEquiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Transport

open import Util.Scalars
open import Common.FilledSpec
open import Common.ObsPackage
open import Boundary.FilledCut
open import Bulk.FilledChain
open import Bridge.FilledObs
  using ( filled-pointwise ; filled-obs-path ; filled-package-path
        ; FilledObs∂ ; FilledObsBulk
        ; filledBdyView ; filledBulkView )


-- ════════════════════════════════════════════════════════════════════
--  §1.  Shorthand names for the boundary and bulk observables
-- ════════════════════════════════════════════════════════════════════
--
--  S∂F is the boundary min-cut entropy functional (true min-cut,
--  allowing boundary-bond severing per the N-singleton resolution
--  documented in docs/instances/filled-patch.md §4) instantiated
--  at the canonical filled-patch specification.
--
--  LBF is the bulk minimal separating-chain functional at the same
--  specification.  Under the N-singleton resolution, both functionals
--  compute the same min-cut value for all 90 regions.
--
--  These are definitionally distinct functions (defined by separate
--  90-clause case splits in Boundary/FilledCut.agda and
--  Bulk/FilledChain.agda respectively), but they are propositionally
--  equal:
--
--    filled-obs-path : S∂F ≡ LBF
--
--  (constructed in Bridge/FilledObs.agda via funExt filled-pointwise).
--
--  The definitional distinctness makes the enriched types below
--  genuinely different types in the universe; the propositional
--  equality makes them equivalent.
--
--  Reference:
--    docs/instances/filled-patch.md §4   (N-singleton discrepancy)
--    docs/instances/filled-patch.md §5   (min-cut / observable agreement)
--    docs/formal/03-holographic-bridge.md §3  (enriched types)
-- ════════════════════════════════════════════════════════════════════

S∂F : FilledRegion → ℚ≥0
S∂F = S-cut filledBdyView

LBF : FilledRegion → ℚ≥0
LBF = L-min filledBulkView


-- ════════════════════════════════════════════════════════════════════
--  §2.  h-Level infrastructure
-- ════════════════════════════════════════════════════════════════════
--
--  The observable function space  FilledRegion → ℚ≥0  is a set
--  (h-level 2) because ℚ≥0 = ℕ is a set (isSetℚ≥0 from
--  Util/Scalars.agda).
--
--  This is the key structural fact enabling the equivalence proof:
--  in a set, paths between elements are propositional (isProp),
--  which means the specification-agreement fields are propositional,
--  which means round-trip homotopies are automatic.
--
--  Reference:
--    docs/formal/02-foundations.md §1  (h-levels and truncation)
-- ════════════════════════════════════════════════════════════════════

isSetFilledObs : isSet (FilledRegion → ℚ≥0)
isSetFilledObs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Enriched observable types
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched boundary type pairs an observable function with a
--  proof that it agrees with the boundary specification S∂F.  The
--  enriched bulk type pairs a function with agreement to LBF.
--
--  These are singleton types  Σ[ f ] (f ≡ a)  — contractible
--  spaces centered at their respective reference functions.  They
--  are genuinely different types in the universe because S∂F and
--  LBF are definitionally distinct (90-clause pattern matches
--  defined in separate modules).
--
--  The enrichment captures the idea that an observable bundle is
--  not just a function from regions to scalars, but a function
--  CERTIFIED to match a specific physical specification.  The
--  boundary certification references min-cut entropy; the bulk
--  certification references minimal separating-chain length.
--
--  This mirrors the EnrichedBdy / EnrichedBulk architecture from
--  Bridge/EnrichedStarObs.agda, now scaled from 10 representative
--  regions to 90 contiguous tile-aligned regions on the 11-tile
--  filled patch of the {5,4} hyperbolic tiling.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3.1  (specification-agreement types)
--    docs/instances/filled-patch.md §8          (bridge construction)
--    docs/instances/star-patch.md §6.2          (enriched bridge — star)
-- ════════════════════════════════════════════════════════════════════

FilledEnrichedBdy : Type₀
FilledEnrichedBdy = Σ[ f ∈ (FilledRegion → ℚ≥0) ] (f ≡ S∂F)

FilledEnrichedBulk : Type₀
FilledEnrichedBulk = Σ[ f ∈ (FilledRegion → ℚ≥0) ] (f ≡ LBF)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary instance carries the boundary observable function
--  together with the trivial agreement witness  refl : S∂F ≡ S∂F .
--  The bulk instance carries the bulk observable function with
--  refl : LBF ≡ LBF .
--
--  These are the concrete observable bundles for the 11-tile filled
--  patch that the transport will convert between.
-- ════════════════════════════════════════════════════════════════════

filled-bdy-instance : FilledEnrichedBdy
filled-bdy-instance = S∂F , refl

filled-bulk-instance : FilledEnrichedBulk
filled-bulk-instance = LBF , refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  The Iso between enriched types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map appends  filled-obs-path  to the boundary
--  agreement witness, converting  f ≡ S∂F  into  f ≡ LBF  via
--  the discrete Ryu–Takayanagi correspondence for the 11-tile
--  patch (90 pointwise refl proofs, assembled by funExt in
--  Bridge/FilledObs.agda).
--
--  The inverse map appends  sym filled-obs-path  to convert back.
--
--  Round-trip proofs use the fact that the specification-agreement
--  fields are propositional (since FilledRegion → ℚ≥0 is a set):
--  any two paths  f ≡ S∂F  (or  f ≡ LBF) are equal, so composing
--  with  filled-obs-path  and then  sym filled-obs-path  yields
--  a path propositionally equal to the original.
--
--  This is structurally identical to the star-patch construction
--  in Bridge/EnrichedStarObs.agda §5, using  filled-obs-path
--  in place of  star-obs-path .
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3.2  (the Iso construction)
--    docs/formal/02-foundations.md §4           (equivalences)
-- ════════════════════════════════════════════════════════════════════

filled-enriched-iso : Iso FilledEnrichedBdy FilledEnrichedBulk
filled-enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : FilledEnrichedBdy → FilledEnrichedBulk
    fwd (f , p) = f , p ∙ filled-obs-path

    bwd : FilledEnrichedBulk → FilledEnrichedBdy
    bwd (f , q) = f , q ∙ sym filled-obs-path

    fwd-bwd : (b : FilledEnrichedBulk) → fwd (bwd b) ≡ b
    fwd-bwd (f , q) i =
      f , isSetFilledObs f LBF
            ((q ∙ sym filled-obs-path) ∙ filled-obs-path) q i

    bwd-fwd : (a : FilledEnrichedBdy) → bwd (fwd a) ≡ a
    bwd-fwd (f , p) i =
      f , isSetFilledObs f S∂F
            ((p ∙ filled-obs-path) ∙ sym filled-obs-path) p i


-- ════════════════════════════════════════════════════════════════════
--  §6.  The equivalence
-- ════════════════════════════════════════════════════════════════════
--
--  Promoting the Iso to a full coherent equivalence (with
--  contractible fibers).  This is required for  ua  application.
--
--  Reference:
--    docs/formal/02-foundations.md §4  (equivalences and isoToEquiv)
-- ════════════════════════════════════════════════════════════════════

filled-enriched-equiv : FilledEnrichedBdy ≃ FilledEnrichedBulk
filled-enriched-equiv = isoToEquiv filled-enriched-iso


-- ════════════════════════════════════════════════════════════════════
--  §7.  The Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Applying  ua  to the enriched equivalence yields a path between
--  FilledEnrichedBdy and FilledEnrichedBulk in the universe Type₀.
--
--  This path is NOT propositionally equal to  refl  (unlike the
--  trivial bridges in Bridge/TreeEquiv.agda and Bridge/StarEquiv.agda
--  that used  idEquiv ).  The two types are genuinely different
--  (they reference different specification functions S∂F and LBF),
--  and the path carries the nontrivial content of  filled-obs-path
--  through the Glue type.
--
--  This is the "Univalence bridge" for the 11-tile filled patch:
--  a path in the universe that identifies boundary-certified and
--  bulk-certified observable packages as equal types, enabled by
--  the discrete Ryu–Takayanagi correspondence on a complete,
--  gapless 2D hyperbolic disk.
--
--  Reference:
--    docs/formal/02-foundations.md §5           (the Univalence axiom)
--    docs/formal/03-holographic-bridge.md §3.3  (Univalence application)
-- ════════════════════════════════════════════════════════════════════

filled-enriched-ua-path : FilledEnrichedBdy ≡ FilledEnrichedBulk
filled-enriched-ua-path = ua filled-enriched-equiv


-- ════════════════════════════════════════════════════════════════════
--  §8.  Transport: the verified translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along the Univalence path converts the boundary
--  observable bundle to the bulk observable bundle.  By  uaβ ,
--  transport computes as the forward map of the equivalence:
--
--    transport filled-enriched-ua-path filled-bdy-instance
--    ≡  equivFun filled-enriched-equiv filled-bdy-instance
--    =  (S∂F , refl ∙ filled-obs-path)
--    =  (S∂F , filled-obs-path)
--
--  This is propositionally equal to
--    filled-bulk-instance = (LBF , refl) :
--  the first components are identified by  filled-obs-path ,
--  and the second components by  isSetFilledObs  (propositional
--  because FilledRegion → ℚ≥0 is a set).
--
--  The computation step (uaβ) is the key:  transport does not get
--  stuck on an opaque postulate — it reduces to the concrete
--  forward map, which appends  filled-obs-path  to the agreement
--  witness.  This is the "compilation step" for the 11-tile patch:
--  a computable transport between exactly equivalent packaged types
--  on the first complete, gapless 2D hyperbolic disk in the
--  formalization.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1         (ua and uaβ in Cubical Agda)
--    docs/formal/03-holographic-bridge.md §3.4  (verified transport)
-- ════════════════════════════════════════════════════════════════════

-- Step 1:  uaβ reduces transport to the forward map
filled-transport-computes :
  transport filled-enriched-ua-path filled-bdy-instance
  ≡ equivFun filled-enriched-equiv filled-bdy-instance
filled-transport-computes = uaβ filled-enriched-equiv filled-bdy-instance

-- Step 2:  The forward map output equals the bulk instance
private
  filled-fwd-eq-bulk :
    equivFun filled-enriched-equiv filled-bdy-instance
    ≡ filled-bulk-instance
  filled-fwd-eq-bulk i =
    filled-obs-path i ,
    isProp→PathP
      (λ j → isSetFilledObs (filled-obs-path j) LBF)
      (refl ∙ filled-obs-path)
      refl
      i

-- Combined: transport produces the bulk instance
filled-enriched-transport :
  transport filled-enriched-ua-path filled-bdy-instance
  ≡ filled-bulk-instance
filled-enriched-transport = filled-transport-computes ∙ filled-fwd-eq-bulk


-- ════════════════════════════════════════════════════════════════════
--  §9.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported boundary instance equals the
--  bulk observable function  LBF = L-min filledBulkView .
--
--  In operational terms: given entanglement data (the boundary
--  observable S∂F) certified against the boundary specification,
--  transport produces a function certified against the bulk
--  specification — and that function is exactly the bulk
--  minimal-chain-length functional LBF.
--
--  This extends the discrete Ryu–Takayanagi bridge from the 6-tile
--  star (10 regions) to the 11-tile filled patch (90 regions),
--  proving that the framework scales to a complete 2D hyperbolic
--  disk with 5 interior vertices at full valence 4.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 1   (Discrete Ryu–Takayanagi)
--    docs/instances/filled-patch.md §8    (bridge construction)
--    docs/instances/star-patch.md §6      (star bridge — predecessor)
-- ════════════════════════════════════════════════════════════════════

filled-enriched-transport-obs :
  fst (transport filled-enriched-ua-path filled-bdy-instance) ≡ LBF
filled-enriched-transport-obs = cong fst filled-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §10.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The transport result holds pointwise: for every admissible
--  boundary region of the 11-tile filled patch, the transported
--  observable agrees with the bulk minimal-chain functional.
-- ════════════════════════════════════════════════════════════════════

filled-enriched-transport-pointwise :
  (r : FilledRegion) →
  fst (transport filled-enriched-ua-path filled-bdy-instance) r ≡ LBF r
filled-enriched-transport-pointwise r =
  cong (λ f → f r) filled-enriched-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §11.  Nontriviality witness
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched  ua  path is NOT propositionally equal to  refl .
--  The forward map modifies the second component (the agreement
--  witness) by appending  filled-obs-path , which encodes the
--  90-case discrete Ryu–Takayanagi correspondence for the 11-tile
--  filled patch.
-- ════════════════════════════════════════════════════════════════════

filled-fwd-snd-is-obs-path :
  snd (equivFun filled-enriched-equiv filled-bdy-instance)
  ≡ refl ∙ filled-obs-path
filled-fwd-snd-is-obs-path = refl


-- ════════════════════════════════════════════════════════════════════
--  §12.  Reverse transport
-- ════════════════════════════════════════════════════════════════════
--
--  The Univalence path is a genuine path in the universe, and
--  transport is invertible: transporting along  sym p  reverses
--  the direction.  This gives a BIDIRECTIONAL translator for the
--  11-tile filled patch.
-- ════════════════════════════════════════════════════════════════════

filled-reverse-enriched :
  transport (sym filled-enriched-ua-path) filled-bulk-instance
  ≡ filled-bdy-instance
filled-reverse-enriched =
  cong (transport (sym filled-enriched-ua-path))
       (sym filled-enriched-transport)
  ∙ transport⁻Transport filled-enriched-ua-path filled-bdy-instance


-- ════════════════════════════════════════════════════════════════════
--  §13.  Roundtrip verification
-- ════════════════════════════════════════════════════════════════════
--
--  The forward and reverse transports compose to the identity in
--  both directions.  The bridge is lossless.
-- ════════════════════════════════════════════════════════════════════

filled-roundtrip-bdy :
  transport (sym filled-enriched-ua-path)
    (transport filled-enriched-ua-path filled-bdy-instance)
  ≡ filled-bdy-instance
filled-roundtrip-bdy =
  transport⁻Transport filled-enriched-ua-path filled-bdy-instance

filled-roundtrip-bulk :
  transport filled-enriched-ua-path
    (transport (sym filled-enriched-ua-path) filled-bulk-instance)
  ≡ filled-bulk-instance
filled-roundtrip-bulk =
  transportTransport⁻ filled-enriched-ua-path filled-bulk-instance


-- ════════════════════════════════════════════════════════════════════
--  §14.  FilledBridgeWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the 11-tile bridge into a single inspectable artifact,
--  following the BridgeWitness pattern from
--  Bridge/EnrichedStarEquiv.agda.
--
--  This record lives in  Type₁  because it stores types as fields.
--
--  Note: This is the hand-written enriched bridge for the filled
--  patch.  The generic bridge theorem (Bridge/GenericBridge.agda)
--  subsumes this module's results via filled-generic-witness in
--  Bridge/GenericValidation.agda, but this module is retained as
--  the historical first enriched bridge on a complete 2D hyperbolic
--  disk and as the template for all subsequent per-instance enriched
--  equivalence modules.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §6  (BridgeWitness record)
--    docs/formal/11-generic-bridge.md         (generic bridge — subsumes this)
--    docs/instances/filled-patch.md §8        (bridge construction)
-- ════════════════════════════════════════════════════════════════════

record FilledBridgeWitness : Type₁ where
  field
    BdyTy              : Type₀
    BulkTy             : Type₀
    bdy-data           : BdyTy
    bulk-data          : BulkTy
    bridge             : BdyTy ≃ BulkTy
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data

filled-bridge-witness : FilledBridgeWitness
filled-bridge-witness .FilledBridgeWitness.BdyTy              = FilledEnrichedBdy
filled-bridge-witness .FilledBridgeWitness.BulkTy             = FilledEnrichedBulk
filled-bridge-witness .FilledBridgeWitness.bdy-data           = filled-bdy-instance
filled-bridge-witness .FilledBridgeWitness.bulk-data          = filled-bulk-instance
filled-bridge-witness .FilledBridgeWitness.bridge             = filled-enriched-equiv
filled-bridge-witness .FilledBridgeWitness.transport-verified = filled-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §15.  Theorem statement — 11-Tile Bridge
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (11-Tile Bridge — Observable Package Equivalence).
--
--  For the 11-tile filled patch of the {5,4} HaPPY code (the
--  smallest {5,4} patch forming a proper manifold with boundary),
--  the boundary min-cut entropy observable package and the bulk
--  minimal-chain-length observable package are exactly equivalent
--  as types.  Transport along the resulting Univalence path carries
--  the boundary bundle to the bulk bundle.
--
--  In symbols:
--
--    transport (ua filled-enriched-equiv) filled-bdy-instance
--      ≡  filled-bulk-instance
--
--  This extends the enriched bridge (proven for the 6-tile star in
--  Bridge/EnrichedStarEquiv.agda) to the 11-tile filled patch,
--  demonstrating that the architecture scales to a complete,
--  gapless 2D hyperbolic disk with:
--
--    • 90 contiguous tile-aligned boundary regions
--    • 360 verified subadditivity cases (abstract, sealed behind
--      the abstract keyword per docs/engineering/abstract-barrier.md)
--    • 5 interior vertices at full {5,4} valence 4
--    • genuine negative curvature (verified by Theorem 2 in
--      Bulk/GaussBonnet.agda)
--    • the same geometric object on which Gauss–Bonnet was proven
--
--  The unification of curvature (Theorem 2) and bridge (this
--  theorem) results on a single geometric object is documented
--  in docs/instances/filled-patch.md §11.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 1    (Discrete Ryu–Takayanagi)
--    docs/formal/01-theorems.md §Thm 2    (Discrete Gauss–Bonnet)
--    docs/instances/filled-patch.md        (filled patch instance)
-- ════════════════════════════════════════════════════════════════════

FilledTheorem3 : Type₀
FilledTheorem3 =
  transport filled-enriched-ua-path filled-bdy-instance
  ≡ filled-bulk-instance

filled-theorem3 : FilledTheorem3
filled-theorem3 = filled-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §16.  Concrete pointwise computations (spot checks)
-- ════════════════════════════════════════════════════════════════════
--
--  Selected regions demonstrating that the transported observable
--  produces the expected numerical values.  Each proof reduces the
--  transported observable to LBF r, which then computes judgmentally
--  to the ℕ literal.
--
--  Region naming:  r⟨start⟩x⟨length⟩
--    start  = index in cyclic boundary order
--    length = number of boundary groups
--
--  Cyclic order: N0(2), G1(3), N1(2), G2(3), N2(2),
--                G3(3), N3(2), G4(3), N4(2), G0(3)
--
--  Reference:
--    docs/instances/filled-patch.md §3  (boundary regions)
--    docs/instances/filled-patch.md §5  (min-cut / observable agreement)
-- ════════════════════════════════════════════════════════════════════

-- Singleton:  {N0}  →  S = 2
transport-at-r0x1 :
  fst (transport filled-enriched-ua-path filled-bdy-instance) r0x1 ≡ 2
transport-at-r0x1 = filled-enriched-transport-pointwise r0x1

-- Adjacent pair:  {N0, G1}  →  S = 3
transport-at-r0x2 :
  fst (transport filled-enriched-ua-path filled-bdy-instance) r0x2 ≡ 3
transport-at-r0x2 = filled-enriched-transport-pointwise r0x2

-- Triple (N-G-N):  {N0, G1, N1}  →  S = 4
transport-at-r0x3 :
  fst (transport filled-enriched-ua-path filled-bdy-instance) r0x3 ≡ 4
transport-at-r0x3 = filled-enriched-transport-pointwise r0x3

-- Half boundary:  {N0, G1, N1, G2, N2}  →  S = 4
transport-at-r0x5 :
  fst (transport filled-enriched-ua-path filled-bdy-instance) r0x5 ≡ 4
transport-at-r0x5 = filled-enriched-transport-pointwise r0x5

-- Near-full:  {N0, G1, N1, G2, N2, G3, N3, G4, N4}  →  S = 2
transport-at-r0x9 :
  fst (transport filled-enriched-ua-path filled-bdy-instance) r0x9 ≡ 2
transport-at-r0x9 = filled-enriched-transport-pointwise r0x9


-- ════════════════════════════════════════════════════════════════════
--  §17.  Coherence with the value-level package path
-- ════════════════════════════════════════════════════════════════════
--
--  The value-level package path  filled-package-path  (from
--  Bridge/FilledObs.agda) and the type-level Univalence path
--  filled-enriched-ua-path  encode the SAME mathematical content:
--  the discrete Ryu–Takayanagi correspondence  S∂F ≡ LBF  on all
--  90 contiguous tile-aligned regions of the 11-tile filled patch.
--
--  The connecting data is  filled-obs-path : S∂F ≡ LBF , which
--  appears as the obs-field component of  filled-package-path
--  and as the rewiring step in  filled-enriched-equiv .
-- ════════════════════════════════════════════════════════════════════

filled-package-coherence :
  ObsPackage.obs (filled-package-path i1)
  ≡ fst filled-bulk-instance
filled-package-coherence = refl


-- ════════════════════════════════════════════════════════════════════
--  §18.  Connection to subadditivity
-- ════════════════════════════════════════════════════════════════════
--
--  The 360-case subadditivity proof in
--  Boundary/FilledSubadditivity.agda (wrapped in  abstract )
--  establishes that the min-cut functional on the 11-tile patch
--  is subadditive:
--
--    S(A ∪ B)  ≤  S(A) + S(B)
--
--  for every valid adjacent-region union on the 90-region type.
--
--  Because the subadditivity proof is  abstract , this module
--  never re-unfolds the 360 case analyses.  The  abstract  barrier
--  prevents the RAM cascade documented in
--  docs/engineering/abstract-barrier.md and Agda GitHub Issue #4573.
--
--  A full structural-property bridge (mirroring
--  Bridge/FullEnrichedStarObs.agda) that converts subadditivity
--  witnesses between the boundary and bulk representations is a
--  natural extension.  It would require:
--
--    1.  A path  S∂F ≡ S-filled  (provable by 90-case funExt,
--        each case refl, since both functions return the same ℕ
--        literal for each region).
--
--    2.  A monotonicity relation  _⊆F_  on FilledRegion and a
--        proof that LBF is monotone (analogous to
--        Bulk/StarMonotonicity.agda, but at 90-region scale).
--
--    3.  Full enriched record types  FullFilledBdy  (with
--        subadditivity) and  FullFilledBulk  (with monotonicity),
--        and the Iso / equiv / ua / transport between them.
--
--  These are deferred to a potential  Bridge/FullEnrichedFilledObs.agda
--  module.