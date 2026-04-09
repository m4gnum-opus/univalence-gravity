{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.Dense100Equiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Transport

open import Util.Scalars
open import Common.Dense100Spec
open import Common.ObsPackage
open import Boundary.Dense100Cut
open import Bulk.Dense100Chain
open import Bridge.Dense100Obs
  using ( d100-pointwise ; d100-obs-path ; d100-package-path
        ; D100Obs∂ ; D100ObsBulk
        ; d100BdyView ; d100BulkView
        ; S∂D100 ; LBD100 )


-- ════════════════════════════════════════════════════════════════════
--  Dense-100 Enriched Observable-Package Equivalence
-- ════════════════════════════════════════════════════════════════════
--
--  This module constructs the enriched type equivalence for the
--  Dense-100 patch of the {4,3,5} hyperbolic honeycomb, mirroring
--  Bridge/Dense50Equiv.agda and Bridge/Honeycomb3DEquiv.agda.
--
--  The Dense-100 patch is grown by greedy max-connectivity from
--  the central cube, producing 100 cells with 150 internal shared
--  faces and 300 boundary faces.  The Python oracle
--  (09_generate_dense100.py) identified 717 cell-aligned boundary
--  regions with min-cut values ranging from 1 to 8, classified
--  into 8 orbit representatives by min-cut value.
--
--  This is the first enriched type equivalence utilizing the orbit
--  reduction strategy in the repository: the pointwise agreement
--  proof operates on 8 orbit representatives (not 717 regions),
--  and the 1-line lifting  d100-pointwise r = d100-pointwise-rep
--  (classify100 r)  handles the full region type.
--
--  The enriched equivalence uses the specification-agreement
--  pattern: the two enriched types are Σ-types centered at
--  definitionally distinct specification functions (S∂D100 and
--  LBD100), connected by d100-obs-path : S∂D100 ≡ LBD100  (the
--  3D discrete Ryu–Takayanagi correspondence, verified by 8
--  orbit-representative cases of refl, lifted to 717 regions).
--
--  Phase:  D.1c (Dense-100 enriched bridge and transport)
--  Reference:  §6 of docs/10-frontier.md
--              §6.5 (orbit reduction strategy)


-- ════════════════════════════════════════════════════════════════════
--  §1.  h-Level infrastructure
-- ════════════════════════════════════════════════════════════════════
--
--  The observable function space  D100Region → ℚ≥0  is a set
--  (h-level 2) because ℚ≥0 = ℕ is a set (isSetℚ≥0 from
--  Util/Scalars.agda).
--
--  This is the key structural fact enabling the equivalence proof:
--  in a set, paths between elements are propositional (isProp),
--  which means the specification-agreement fields are propositional,
--  which means round-trip homotopies are automatic.
-- ════════════════════════════════════════════════════════════════════

isSetD100Obs : isSet (D100Region → ℚ≥0)
isSetD100Obs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Enriched observable types
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched boundary type pairs an observable function with a
--  proof that it agrees with the Dense-100 boundary specification
--  S∂D100.  The enriched bulk type pairs a function with agreement
--  to LBD100.
--
--  These are singleton types  Σ[ f ] (f ≡ a)  — contractible
--  spaces centered at their respective reference functions.  They
--  are genuinely different types in the universe because S∂D100 and
--  LBD100 are definitionally distinct (defined via different rep
--  functions in separate modules, composed with classify100).
--
--  The enrichment captures the 3D analogue of the 2D principle:
--  an observable bundle is not just a function from regions to
--  scalars, but a function CERTIFIED to match a specific physical
--  specification.  The boundary certification references 3D min-cut
--  entropy (minimal separating surface area); the bulk certification
--  references 3D minimal separating-surface area.
-- ════════════════════════════════════════════════════════════════════

D100EnrichedBdy : Type₀
D100EnrichedBdy = Σ[ f ∈ (D100Region → ℚ≥0) ] (f ≡ S∂D100)

D100EnrichedBulk : Type₀
D100EnrichedBulk = Σ[ f ∈ (D100Region → ℚ≥0) ] (f ≡ LBD100)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary instance carries the Dense-100 boundary observable
--  function together with the trivial agreement witness
--  refl : S∂D100 ≡ S∂D100.  The bulk instance carries the Dense-100
--  bulk observable function with refl : LBD100 ≡ LBD100.
--
--  These are the concrete 3D observable bundles that transport will
--  convert between.
-- ════════════════════════════════════════════════════════════════════

d100-bdy-instance : D100EnrichedBdy
d100-bdy-instance = S∂D100 , refl

d100-bulk-instance : D100EnrichedBulk
d100-bulk-instance = LBD100 , refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  The Iso between enriched types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map appends  d100-obs-path  to the boundary agreement
--  witness, converting  f ≡ S∂D100  into  f ≡ LBD100  via the 3D
--  discrete Ryu–Takayanagi correspondence for the Dense-100 patch.
--
--  The inverse map appends  sym d100-obs-path  to convert back.
--
--  Round-trip proofs use the fact that the specification-agreement
--  fields are propositional (since D100Region → ℚ≥0 is a set):
--  any two paths  f ≡ S∂D100  (or  f ≡ LBD100) are equal, so
--  composing with  d100-obs-path  and then  sym d100-obs-path
--  yields a path propositionally equal to the original.
--
--  This is structurally identical to the constructions in
--  Bridge/EnrichedStarObs.agda, Bridge/FilledEquiv.agda,
--  Bridge/Honeycomb3DEquiv.agda, and Bridge/Dense50Equiv.agda,
--  using d100-obs-path in place of the previous obs-paths.
--
--  The orbit reduction innovation is invisible at this level:
--  d100-obs-path was constructed from 8 orbit-representative
--  refl proofs + 1-line lifting in Bridge/Dense100Obs.agda,
--  but here it is consumed as a single path  S∂D100 ≡ LBD100 .
-- ════════════════════════════════════════════════════════════════════

d100-enriched-iso : Iso D100EnrichedBdy D100EnrichedBulk
d100-enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : D100EnrichedBdy → D100EnrichedBulk
    fwd (f , p) = f , p ∙ d100-obs-path

    bwd : D100EnrichedBulk → D100EnrichedBdy
    bwd (f , q) = f , q ∙ sym d100-obs-path

    fwd-bwd : (b : D100EnrichedBulk) → fwd (bwd b) ≡ b
    fwd-bwd (f , q) i =
      f , isSetD100Obs f LBD100
            ((q ∙ sym d100-obs-path) ∙ d100-obs-path) q i

    bwd-fwd : (a : D100EnrichedBdy) → bwd (fwd a) ≡ a
    bwd-fwd (f , p) i =
      f , isSetD100Obs f S∂D100
            ((p ∙ d100-obs-path) ∙ sym d100-obs-path) p i


-- ════════════════════════════════════════════════════════════════════
--  §5.  The equivalence
-- ════════════════════════════════════════════════════════════════════
--
--  Promoting the Iso to a full coherent equivalence (with
--  contractible fibers).  This is required for  ua  application.
-- ════════════════════════════════════════════════════════════════════

d100-enriched-equiv : D100EnrichedBdy ≃ D100EnrichedBulk
d100-enriched-equiv = isoToEquiv d100-enriched-iso


-- ════════════════════════════════════════════════════════════════════
--  §6.  The Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Applying  ua  to the enriched equivalence yields a path between
--  D100EnrichedBdy and D100EnrichedBulk in the universe Type₀.
--
--  This path is NOT propositionally equal to  refl .  The two types
--  are genuinely different (they reference different specification
--  functions S∂D100 and LBD100), and the path carries the nontrivial
--  content of  d100-obs-path  through the Glue type.
--
--  This is the first Univalence path between enriched observable
--  types utilizing the orbit reduction strategy: 717 regions are
--  handled by 8 orbit-representative proofs, yet the resulting
--  ua path identifies the full 717-region observable packages.
-- ════════════════════════════════════════════════════════════════════

d100-enriched-ua-path : D100EnrichedBdy ≡ D100EnrichedBulk
d100-enriched-ua-path = ua d100-enriched-equiv


-- ════════════════════════════════════════════════════════════════════
--  §7.  Transport: the verified 3D translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along the Univalence path converts the Dense-100
--  boundary observable bundle to the Dense-100 bulk observable
--  bundle.  By  uaβ , transport computes as the forward map of
--  the equivalence:
--
--    transport d100-enriched-ua-path d100-bdy-instance
--    ≡  equivFun d100-enriched-equiv d100-bdy-instance
--    =  (S∂D100 , refl ∙ d100-obs-path)
--    =  (S∂D100 , d100-obs-path)
--
--  This is propositionally equal to
--    d100-bulk-instance = (LBD100 , refl) :
--  the first components are identified by  d100-obs-path ,
--  and the second components by  isSetD100Obs  (propositional
--  because D100Region → ℚ≥0 is a set).
--
--  The computation step (uaβ) is the key:  transport reduces to
--  the concrete forward map, which appends  d100-obs-path  to the
--  agreement witness.  This is the "Dense-100 compilation step":
--  a computable transport between exactly equivalent 3D observable
--  packages on a densely-connected hyperbolic cell complex with
--  multi-face RT separating surfaces (min-cut values 1–8),
--  managed by the orbit reduction architecture.
-- ════════════════════════════════════════════════════════════════════

-- Step 1:  uaβ reduces transport to the forward map
d100-transport-computes :
  transport d100-enriched-ua-path d100-bdy-instance
  ≡ equivFun d100-enriched-equiv d100-bdy-instance
d100-transport-computes = uaβ d100-enriched-equiv d100-bdy-instance

-- Step 2:  The forward map output equals the bulk instance
private
  d100-fwd-eq-bulk :
    equivFun d100-enriched-equiv d100-bdy-instance
    ≡ d100-bulk-instance
  d100-fwd-eq-bulk i =
    d100-obs-path i ,
    isProp→PathP
      (λ j → isSetD100Obs (d100-obs-path j) LBD100)
      (refl ∙ d100-obs-path)
      refl
      i

-- Combined: transport produces the bulk instance
d100-enriched-transport :
  transport d100-enriched-ua-path d100-bdy-instance
  ≡ d100-bulk-instance
d100-enriched-transport = d100-transport-computes ∙ d100-fwd-eq-bulk


-- ════════════════════════════════════════════════════════════════════
--  §8.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported Dense-100 boundary instance equals
--  the Dense-100 bulk observable function  LBD100 = L-min d100BulkView.
--
--  In operational terms: given 3D entanglement data (the boundary
--  observable S∂D100 encoding min-cut surface areas through the
--  densely-connected cell complex) certified against the boundary
--  specification, transport produces a function certified against
--  the bulk specification — and that function is exactly the 3D
--  bulk minimal separating-surface functional LBD100.
--
--  This extends the observable-package equivalence from:
--    Tree      (8 regions, 1D tree pilot)
--    Star      (10 regions, 2D star patch)
--    Filled    (90 regions, 2D full disk)
--    Honeycomb (26 regions, 3D BFS star patch, min-cut all 1)
--    Dense-50  (139 regions, 3D dense patch, min-cut 1–7)
--  to:
--    Dense-100 (717 regions, 3D dense patch, min-cut 1–8,
--               orbit-reduced to 8 representative proofs)
-- ════════════════════════════════════════════════════════════════════

d100-enriched-transport-obs :
  fst (transport d100-enriched-ua-path d100-bdy-instance) ≡ LBD100
d100-enriched-transport-obs = cong fst d100-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §9.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The transport result holds pointwise: for every admissible
--  boundary region of the Dense-100 patch, the transported
--  observable agrees with the bulk minimal separating-surface
--  functional.
-- ════════════════════════════════════════════════════════════════════

d100-enriched-transport-pointwise :
  (r : D100Region) →
  fst (transport d100-enriched-ua-path d100-bdy-instance) r ≡ LBD100 r
d100-enriched-transport-pointwise r =
  cong (λ f → f r) d100-enriched-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §10.  Nontriviality witness
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched  ua  path is NOT propositionally equal to  refl .
--  The forward map modifies the second component (the agreement
--  witness) by appending  d100-obs-path , which encodes the
--  717-region 3D discrete Ryu–Takayanagi correspondence for the
--  Dense-100 patch with min-cut values ranging from 1 to 8,
--  proven via 8 orbit-representative refl cases.
-- ════════════════════════════════════════════════════════════════════

d100-fwd-snd-is-obs-path :
  snd (equivFun d100-enriched-equiv d100-bdy-instance)
  ≡ refl ∙ d100-obs-path
d100-fwd-snd-is-obs-path = refl


-- ════════════════════════════════════════════════════════════════════
--  §11.  Reverse transport
-- ════════════════════════════════════════════════════════════════════
--
--  The Univalence path is a genuine path in the universe, and
--  transport is invertible: transporting along  sym p  reverses
--  the direction.  This gives a BIDIRECTIONAL Dense-100 translator.
-- ════════════════════════════════════════════════════════════════════

d100-reverse-enriched :
  transport (sym d100-enriched-ua-path) d100-bulk-instance
  ≡ d100-bdy-instance
d100-reverse-enriched =
  cong (transport (sym d100-enriched-ua-path))
       (sym d100-enriched-transport)
  ∙ transport⁻Transport d100-enriched-ua-path d100-bdy-instance


-- ════════════════════════════════════════════════════════════════════
--  §12.  Roundtrip verification
-- ════════════════════════════════════════════════════════════════════
--
--  The forward and reverse transports compose to the identity in
--  both directions.  The Dense-100 bridge is lossless.
-- ════════════════════════════════════════════════════════════════════

d100-roundtrip-bdy :
  transport (sym d100-enriched-ua-path)
    (transport d100-enriched-ua-path d100-bdy-instance)
  ≡ d100-bdy-instance
d100-roundtrip-bdy =
  transport⁻Transport d100-enriched-ua-path d100-bdy-instance

d100-roundtrip-bulk :
  transport d100-enriched-ua-path
    (transport (sym d100-enriched-ua-path) d100-bulk-instance)
  ≡ d100-bulk-instance
d100-roundtrip-bulk =
  transportTransport⁻ d100-enriched-ua-path d100-bulk-instance


-- ════════════════════════════════════════════════════════════════════
--  §13.  D100BridgeWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the Dense-100 bridge into a single inspectable artifact,
--  following the BridgeWitness / FilledBridgeWitness /
--  H3BridgeWitness / D50BridgeWitness pattern from the earlier
--  bridge modules.
--
--  This record lives in  Type₁  because it stores types as fields.
-- ════════════════════════════════════════════════════════════════════

record D100BridgeWitness : Type₁ where
  field
    BdyTy              : Type₀
    BulkTy             : Type₀
    bdy-data           : BdyTy
    bulk-data          : BulkTy
    bridge             : BdyTy ≃ BulkTy
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data

d100-bridge-witness : D100BridgeWitness
d100-bridge-witness .D100BridgeWitness.BdyTy              = D100EnrichedBdy
d100-bridge-witness .D100BridgeWitness.BulkTy             = D100EnrichedBulk
d100-bridge-witness .D100BridgeWitness.bdy-data           = d100-bdy-instance
d100-bridge-witness .D100BridgeWitness.bulk-data          = d100-bulk-instance
d100-bridge-witness .D100BridgeWitness.bridge             = d100-enriched-equiv
d100-bridge-witness .D100BridgeWitness.transport-verified = d100-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §14.  Theorem statement — Dense-100 Bridge
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Dense-100 Bridge — Observable Package Equivalence).
--
--  For the Dense-100 patch of the {4,3,5} hyperbolic honeycomb
--  (100 cubic cells grown by greedy max-connectivity, 150 internal
--  shared faces, 300 boundary faces, 717 cell-aligned boundary
--  regions with min-cut values 1–8, orbit-reduced to 8
--  representative proofs), the boundary min-cut entropy observable
--  package and the bulk minimal separating-surface observable
--  package are exactly equivalent as types.  Transport along the
--  resulting Univalence path carries the boundary bundle to the
--  bulk bundle.
--
--  In symbols:
--
--    transport (ua d100-enriched-equiv) d100-bdy-instance
--      ≡  d100-bulk-instance
--
--  This is the first observable-package equivalence utilizing the
--  orbit reduction strategy in the repository.  It demonstrates
--  that the holographic formalization architecture scales past the
--  ~500-constructor threshold by factoring proofs through a small
--  orbit type (8 constructors), while the 717-clause classification
--  function is traversed only during concrete evaluation.
--
--  The formalization architecture scales from:
--
--    0D bdy / 1D bulk  (tree pilot, 8 regions, min-cut 1–2)
--    1D bdy / 2D bulk  (star, 10 regions, min-cut 1–2)
--    1D bdy / 2D bulk  (filled, 90 regions, min-cut 2–4)
--    2D bdy / 3D bulk  (honeycomb BFS, 26 regions, min-cut 1)
--    2D bdy / 3D bulk  (Dense-50, 139 regions, min-cut 1–7)
--    2D bdy / 3D bulk  (Dense-100, 717 regions → 8 orbits,
--                        min-cut 1–8)  ← this
--
--  Phase:  D.1c (Dense-100 enriched bridge and transport)
--  Reference:  §6 of docs/10-frontier.md
--              §6.5 (orbit reduction strategy)
-- ════════════════════════════════════════════════════════════════════

D100Theorem3 : Type₀
D100Theorem3 =
  transport d100-enriched-ua-path d100-bdy-instance
  ≡ d100-bulk-instance

d100-theorem3 : D100Theorem3
d100-theorem3 = d100-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §15.  Concrete pointwise computations (spot checks)
-- ════════════════════════════════════════════════════════════════════
--
--  Selected regions demonstrating that the transported observable
--  produces the expected numerical values across the full min-cut
--  range (1–8).  Each proof reduces the transported observable to
--  LBD100 r, which computes via classify100 r (one step on the
--  717-clause function) then L-min-rep on the result (one step on
--  the 8-clause function), yielding the ℕ literal judgmentally.
--
--  The Dense-100 patch achieves min-cut values up to 8, the
--  highest in the repository, confirming that boundary regions
--  at different "depths" into the holographic bulk require
--  genuinely different numbers of internal faces to be severed.
-- ════════════════════════════════════════════════════════════════════

-- S = 1:  d100r0 is a singleton cell with min-cut 1
transport-at-d100r0 :
  fst (transport d100-enriched-ua-path d100-bdy-instance) d100r0 ≡ 1
transport-at-d100r0 = d100-enriched-transport-pointwise d100r0

-- S = 2:  d100r215 has min-cut 2
transport-at-d100r215 :
  fst (transport d100-enriched-ua-path d100-bdy-instance) d100r215 ≡ 2
transport-at-d100r215 = d100-enriched-transport-pointwise d100r215

-- S = 3:  d100r1 has min-cut 3
transport-at-d100r1 :
  fst (transport d100-enriched-ua-path d100-bdy-instance) d100r1 ≡ 3
transport-at-d100r1 = d100-enriched-transport-pointwise d100r1

-- S = 5:  d100r8 has min-cut 5
transport-at-d100r8 :
  fst (transport d100-enriched-ua-path d100-bdy-instance) d100r8 ≡ 5
transport-at-d100r8 = d100-enriched-transport-pointwise d100r8

-- S = 7:  d100r4 has min-cut 7
transport-at-d100r4 :
  fst (transport d100-enriched-ua-path d100-bdy-instance) d100r4 ≡ 7
transport-at-d100r4 = d100-enriched-transport-pointwise d100r4

-- S = 8:  d100r15 has min-cut 8
transport-at-d100r15 :
  fst (transport d100-enriched-ua-path d100-bdy-instance) d100r15 ≡ 8
transport-at-d100r15 = d100-enriched-transport-pointwise d100r15


-- ════════════════════════════════════════════════════════════════════
--  §16.  Coherence with the value-level package path
-- ════════════════════════════════════════════════════════════════════
--
--  The value-level package path  d100-package-path  (from
--  Bridge/Dense100Obs.agda) and the type-level Univalence path
--  d100-enriched-ua-path  encode the SAME mathematical content:
--  the 3D discrete Ryu–Takayanagi correspondence  S∂D100 ≡ LBD100
--  on all 717 cell-aligned boundary regions of the Dense-100 patch.
--
--  The connecting data is  d100-obs-path : S∂D100 ≡ LBD100 , which
--  appears as the obs-field component of  d100-package-path  and
--  as the rewiring step in  d100-enriched-equiv .
-- ════════════════════════════════════════════════════════════════════

d100-package-coherence :
  ObsPackage.obs (d100-package-path i1)
  ≡ fst d100-bulk-instance
d100-package-coherence = refl


-- ════════════════════════════════════════════════════════════════════
--  §17.  End-to-end pipeline summary
-- ════════════════════════════════════════════════════════════════════
--
--  The complete Dense-100 pipeline for the {4,3,5} honeycomb:
--
--    07_honeycomb_3d_multiStrategy.py      (Phase D.0: feasibility)
--      │  Dense growth strategy identified as optimal
--      ▼
--    09_generate_dense100.py               (Phase D.1c: code gen)
--      │  Orbit reduction: 717 regions → 8 orbit representatives
--      │
--      ├──▶ Common/Dense100Spec.agda       (717-ctor D100Region,
--      │                                    8-ctor D100OrbitRep,
--      │                                    717-clause classify100)
--      ├──▶ Boundary/Dense100Cut.agda      (S-cut via 8-clause rep)
--      ├──▶ Bulk/Dense100Chain.agda        (L-min via 8-clause rep)
--      ├──▶ Bulk/Dense100Curvature.agda    (edge-class κ₂₀, 3D GB)
--      └──▶ Bridge/Dense100Obs.agda        (8 orbit refl + 1-line lift
--              │                            + funExt)
--              ▼
--         d100-obs-path : S∂D100 ≡ LBD100  (Bridge/Dense100Obs)
--              │
--              ▼
--         d100-enriched-equiv :             (this module)
--           D100EnrichedBdy ≃ D100EnrichedBulk
--              │
--              ▼
--         d100-enriched-ua-path :
--           D100EnrichedBdy ≡ D100EnrichedBulk
--              │
--              ▼
--         d100-enriched-transport :
--           transport ... d100-bdy-instance ≡ d100-bulk-instance
--              │
--              ▼
--         d100-enriched-transport-obs :
--           fst (transport ... d100-bdy-instance) ≡ LBD100
--
--  Every step is machine-checked.  Transport is computable: it
--  reduces via uaβ to the forward map of the equivalence.  The
--  3D discrete Ryu–Takayanagi correspondence (min-cut through
--  the cell complex = minimal separating surface area) is the
--  content of the 8 orbit-representative refl proofs in
--  d100-pointwise-rep, lifted to 717 regions by
--  d100-pointwise r = d100-pointwise-rep (classify100 r).
--
--  This module demonstrates that the orbit reduction strategy
--  from §6.5 of docs/10-frontier.md successfully scales the
--  holographic formalization architecture past the ~500-region
--  threshold.  The pattern generalizes: adding more cells to the
--  patch only grows the classify function (a flat lookup), not
--  the proof obligations (which remain on the compact orbit type).
-- ════════════════════════════════════════════════════════════════════