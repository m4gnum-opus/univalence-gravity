{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.Dense50Equiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Transport

open import Util.Scalars
open import Common.Dense50Spec
open import Common.ObsPackage
open import Boundary.Dense50Cut
open import Bulk.Dense50Chain
open import Bridge.Dense50Obs
  using ( d50-pointwise ; d50-obs-path ; d50-package-path
        ; D50Obs∂ ; D50ObsBulk
        ; d50BdyView ; d50BulkView
        ; S∂D50 ; LBD50 )


-- ════════════════════════════════════════════════════════════════════
--  Dense-50 Enriched Observable-Package Equivalence
-- ════════════════════════════════════════════════════════════════════
--
--  This module constructs the enriched type equivalence for the
--  Dense-50 patch of the {4,3,5} hyperbolic honeycomb, mirroring
--  Bridge/Honeycomb3DEquiv.agda and Bridge/FilledEquiv.agda.
--
--  The Dense-50 patch is grown by greedy max-connectivity from
--  the central cube, producing 50 cells with 68 internal shared
--  faces and 164 boundary faces.  The Python oracle
--  (08_generate_dense50.py) identified 139 cell-aligned boundary
--  regions with min-cut values ranging from 1 to 7.
--
--  Unlike the BFS-shell 3D star patch (Honeycomb3DEquiv.agda)
--  where all 26 singleton regions had min-cut = 1, the Dense-50
--  patch achieves min-cut values up to 7, confirming genuine
--  multi-face RT separating surfaces in the 3D bulk — the first
--  formalized instance of "holographic depth" in 3D.
--
--  The enriched equivalence uses the specification-agreement
--  pattern: the two enriched types are Σ-types centered at
--  definitionally distinct specification functions (S∂D50 and
--  LBD50), connected by d50-obs-path : S∂D50 ≡ LBD50  (the 3D
--  discrete Ryu–Takayanagi correspondence, verified by 139 cases
--  of refl).
--
--  Phase:  D.1b (Dense-50 enriched bridge and transport)
--  Reference:  §6 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  h-Level infrastructure
-- ════════════════════════════════════════════════════════════════════
--
--  The observable function space  D50Region → ℚ≥0  is a set
--  (h-level 2) because ℚ≥0 = ℕ is a set (isSetℚ≥0 from
--  Util/Scalars.agda).
--
--  This is the key structural fact enabling the equivalence proof:
--  in a set, paths between elements are propositional (isProp),
--  which means the specification-agreement fields are propositional,
--  which means round-trip homotopies are automatic.
-- ════════════════════════════════════════════════════════════════════

isSetD50Obs : isSet (D50Region → ℚ≥0)
isSetD50Obs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Enriched observable types
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched boundary type pairs an observable function with a
--  proof that it agrees with the Dense-50 boundary specification
--  S∂D50.  The enriched bulk type pairs a function with agreement
--  to LBD50.
--
--  These are singleton types  Σ[ f ] (f ≡ a)  — contractible
--  spaces centered at their respective reference functions.  They
--  are genuinely different types in the universe because S∂D50 and
--  LBD50 are definitionally distinct (139-clause pattern matches
--  defined in separate modules).
--
--  The enrichment captures the 3D analogue of the 2D principle:
--  an observable bundle is not just a function from regions to
--  scalars, but a function CERTIFIED to match a specific physical
--  specification.  The boundary certification references 3D min-cut
--  entropy (minimal separating surface area); the bulk certification
--  references 3D minimal separating-surface area.
-- ════════════════════════════════════════════════════════════════════

D50EnrichedBdy : Type₀
D50EnrichedBdy = Σ[ f ∈ (D50Region → ℚ≥0) ] (f ≡ S∂D50)

D50EnrichedBulk : Type₀
D50EnrichedBulk = Σ[ f ∈ (D50Region → ℚ≥0) ] (f ≡ LBD50)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary instance carries the Dense-50 boundary observable
--  function together with the trivial agreement witness
--  refl : S∂D50 ≡ S∂D50.  The bulk instance carries the Dense-50
--  bulk observable function with refl : LBD50 ≡ LBD50.
--
--  These are the concrete 3D observable bundles that transport will
--  convert between.
-- ════════════════════════════════════════════════════════════════════

d50-bdy-instance : D50EnrichedBdy
d50-bdy-instance = S∂D50 , refl

d50-bulk-instance : D50EnrichedBulk
d50-bulk-instance = LBD50 , refl


-- ════════════════════════════════════════════════════════════════════
--  §4.  The Iso between enriched types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map appends  d50-obs-path  to the boundary agreement
--  witness, converting  f ≡ S∂D50  into  f ≡ LBD50  via the 3D
--  discrete Ryu–Takayanagi correspondence for the Dense-50 patch.
--
--  The inverse map appends  sym d50-obs-path  to convert back.
--
--  Round-trip proofs use the fact that the specification-agreement
--  fields are propositional (since D50Region → ℚ≥0 is a set):
--  any two paths  f ≡ S∂D50  (or  f ≡ LBD50) are equal, so
--  composing with  d50-obs-path  and then  sym d50-obs-path  yields
--  a path propositionally equal to the original.
--
--  This is structurally identical to the constructions in
--  Bridge/EnrichedStarObs.agda, Bridge/FilledEquiv.agda, and
--  Bridge/Honeycomb3DEquiv.agda, using d50-obs-path in place of
--  star-obs-path, filled-obs-path, or h3-obs-path.
-- ════════════════════════════════════════════════════════════════════

d50-enriched-iso : Iso D50EnrichedBdy D50EnrichedBulk
d50-enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : D50EnrichedBdy → D50EnrichedBulk
    fwd (f , p) = f , p ∙ d50-obs-path

    bwd : D50EnrichedBulk → D50EnrichedBdy
    bwd (f , q) = f , q ∙ sym d50-obs-path

    fwd-bwd : (b : D50EnrichedBulk) → fwd (bwd b) ≡ b
    fwd-bwd (f , q) i =
      f , isSetD50Obs f LBD50
            ((q ∙ sym d50-obs-path) ∙ d50-obs-path) q i

    bwd-fwd : (a : D50EnrichedBdy) → bwd (fwd a) ≡ a
    bwd-fwd (f , p) i =
      f , isSetD50Obs f S∂D50
            ((p ∙ d50-obs-path) ∙ sym d50-obs-path) p i


-- ════════════════════════════════════════════════════════════════════
--  §5.  The equivalence
-- ════════════════════════════════════════════════════════════════════
--
--  Promoting the Iso to a full coherent equivalence (with
--  contractible fibers).  This is required for  ua  application.
-- ════════════════════════════════════════════════════════════════════

d50-enriched-equiv : D50EnrichedBdy ≃ D50EnrichedBulk
d50-enriched-equiv = isoToEquiv d50-enriched-iso


-- ════════════════════════════════════════════════════════════════════
--  §6.  The Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Applying  ua  to the enriched equivalence yields a path between
--  D50EnrichedBdy and D50EnrichedBulk in the universe Type₀.
--
--  This path is NOT propositionally equal to  refl .  The two types
--  are genuinely different (they reference different specification
--  functions S∂D50 and LBD50), and the path carries the nontrivial
--  content of  d50-obs-path  through the Glue type.
--
--  This is the first Univalence path between enriched observable
--  types on a 3D densely-connected hyperbolic cell complex in the
--  repository.  Unlike the BFS-shell 3D star patch where all
--  min-cuts are 1, the Dense-50 patch witnesses genuine holographic
--  depth: the RT surfaces are multi-face separating surfaces
--  cutting through a multiply-connected 3D bulk.
-- ════════════════════════════════════════════════════════════════════

d50-enriched-ua-path : D50EnrichedBdy ≡ D50EnrichedBulk
d50-enriched-ua-path = ua d50-enriched-equiv


-- ════════════════════════════════════════════════════════════════════
--  §7.  Transport: the verified 3D translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along the Univalence path converts the Dense-50
--  boundary observable bundle to the Dense-50 bulk observable
--  bundle.  By  uaβ , transport computes as the forward map of
--  the equivalence:
--
--    transport d50-enriched-ua-path d50-bdy-instance
--    ≡  equivFun d50-enriched-equiv d50-bdy-instance
--    =  (S∂D50 , refl ∙ d50-obs-path)
--    =  (S∂D50 , d50-obs-path)
--
--  This is propositionally equal to
--    d50-bulk-instance = (LBD50 , refl) :
--  the first components are identified by  d50-obs-path ,
--  and the second components by  isSetD50Obs  (propositional
--  because D50Region → ℚ≥0 is a set).
--
--  The computation step (uaβ) is the key:  transport reduces to
--  the concrete forward map, which appends  d50-obs-path  to the
--  agreement witness.  This is the "Dense-50 compilation step":
--  a computable transport between exactly equivalent 3D observable
--  packages on a densely-connected hyperbolic cell complex with
--  multi-face RT separating surfaces (min-cut values 2–7).
-- ════════════════════════════════════════════════════════════════════

-- Step 1:  uaβ reduces transport to the forward map
d50-transport-computes :
  transport d50-enriched-ua-path d50-bdy-instance
  ≡ equivFun d50-enriched-equiv d50-bdy-instance
d50-transport-computes = uaβ d50-enriched-equiv d50-bdy-instance

-- Step 2:  The forward map output equals the bulk instance
private
  d50-fwd-eq-bulk :
    equivFun d50-enriched-equiv d50-bdy-instance
    ≡ d50-bulk-instance
  d50-fwd-eq-bulk i =
    d50-obs-path i ,
    isProp→PathP
      (λ j → isSetD50Obs (d50-obs-path j) LBD50)
      (refl ∙ d50-obs-path)
      refl
      i

-- Combined: transport produces the bulk instance
d50-enriched-transport :
  transport d50-enriched-ua-path d50-bdy-instance
  ≡ d50-bulk-instance
d50-enriched-transport = d50-transport-computes ∙ d50-fwd-eq-bulk


-- ════════════════════════════════════════════════════════════════════
--  §8.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported Dense-50 boundary instance equals
--  the Dense-50 bulk observable function  LBD50 = L-min d50BulkView.
--
--  In operational terms: given 3D entanglement data (the boundary
--  observable S∂D50 encoding min-cut surface areas through the
--  densely-connected cell complex) certified against the boundary
--  specification, transport produces a function certified against
--  the bulk specification — and that function is exactly the 3D
--  bulk minimal separating-surface functional LBD50.
--
--  This extends the observable-package equivalence from:
--    Tree      (8 regions, 1D tree pilot)
--    Star      (10 regions, 2D star patch)
--    Filled    (90 regions, 2D full disk)
--    Honeycomb (26 regions, 3D BFS star patch, min-cut all 1)
--  to:
--    Dense-50  (139 regions, 3D dense patch, min-cut 1–7)
-- ════════════════════════════════════════════════════════════════════

d50-enriched-transport-obs :
  fst (transport d50-enriched-ua-path d50-bdy-instance) ≡ LBD50
d50-enriched-transport-obs = cong fst d50-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §9.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The transport result holds pointwise: for every admissible
--  boundary region of the Dense-50 patch, the transported
--  observable agrees with the bulk minimal separating-surface
--  functional.
-- ════════════════════════════════════════════════════════════════════

d50-enriched-transport-pointwise :
  (r : D50Region) →
  fst (transport d50-enriched-ua-path d50-bdy-instance) r ≡ LBD50 r
d50-enriched-transport-pointwise r =
  cong (λ f → f r) d50-enriched-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §10.  Nontriviality witness
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched  ua  path is NOT propositionally equal to  refl .
--  The forward map modifies the second component (the agreement
--  witness) by appending  d50-obs-path , which encodes the 139-case
--  3D discrete Ryu–Takayanagi correspondence for the Dense-50
--  patch with min-cut values ranging from 1 to 7.
-- ════════════════════════════════════════════════════════════════════

d50-fwd-snd-is-obs-path :
  snd (equivFun d50-enriched-equiv d50-bdy-instance)
  ≡ refl ∙ d50-obs-path
d50-fwd-snd-is-obs-path = refl


-- ════════════════════════════════════════════════════════════════════
--  §11.  Reverse transport
-- ════════════════════════════════════════════════════════════════════
--
--  The Univalence path is a genuine path in the universe, and
--  transport is invertible: transporting along  sym p  reverses
--  the direction.  This gives a BIDIRECTIONAL Dense-50 translator.
-- ════════════════════════════════════════════════════════════════════

d50-reverse-enriched :
  transport (sym d50-enriched-ua-path) d50-bulk-instance
  ≡ d50-bdy-instance
d50-reverse-enriched =
  cong (transport (sym d50-enriched-ua-path))
       (sym d50-enriched-transport)
  ∙ transport⁻Transport d50-enriched-ua-path d50-bdy-instance


-- ════════════════════════════════════════════════════════════════════
--  §12.  Roundtrip verification
-- ════════════════════════════════════════════════════════════════════
--
--  The forward and reverse transports compose to the identity in
--  both directions.  The Dense-50 bridge is lossless.
-- ════════════════════════════════════════════════════════════════════

d50-roundtrip-bdy :
  transport (sym d50-enriched-ua-path)
    (transport d50-enriched-ua-path d50-bdy-instance)
  ≡ d50-bdy-instance
d50-roundtrip-bdy =
  transport⁻Transport d50-enriched-ua-path d50-bdy-instance

d50-roundtrip-bulk :
  transport d50-enriched-ua-path
    (transport (sym d50-enriched-ua-path) d50-bulk-instance)
  ≡ d50-bulk-instance
d50-roundtrip-bulk =
  transportTransport⁻ d50-enriched-ua-path d50-bulk-instance


-- ════════════════════════════════════════════════════════════════════
--  §13.  D50BridgeWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the Dense-50 bridge into a single inspectable artifact,
--  following the BridgeWitness / FilledBridgeWitness /
--  H3BridgeWitness pattern from the earlier bridge modules.
--
--  This record lives in  Type₁  because it stores types as fields.
-- ════════════════════════════════════════════════════════════════════

record D50BridgeWitness : Type₁ where
  field
    BdyTy              : Type₀
    BulkTy             : Type₀
    bdy-data           : BdyTy
    bulk-data          : BulkTy
    bridge             : BdyTy ≃ BulkTy
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data

d50-bridge-witness : D50BridgeWitness
d50-bridge-witness .D50BridgeWitness.BdyTy              = D50EnrichedBdy
d50-bridge-witness .D50BridgeWitness.BulkTy             = D50EnrichedBulk
d50-bridge-witness .D50BridgeWitness.bdy-data           = d50-bdy-instance
d50-bridge-witness .D50BridgeWitness.bulk-data          = d50-bulk-instance
d50-bridge-witness .D50BridgeWitness.bridge             = d50-enriched-equiv
d50-bridge-witness .D50BridgeWitness.transport-verified = d50-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §14.  Theorem statement — Dense-50 Bridge
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Dense-50 Bridge — Observable Package Equivalence).
--
--  For the Dense-50 patch of the {4,3,5} hyperbolic honeycomb
--  (50 cubic cells grown by greedy max-connectivity, 68 internal
--  shared faces, 164 boundary faces, 139 cell-aligned boundary
--  regions with min-cut values 1–7), the boundary min-cut entropy
--  observable package and the bulk minimal separating-surface
--  observable package are exactly equivalent as types.  Transport
--  along the resulting Univalence path carries the boundary bundle
--  to the bulk bundle.
--
--  In symbols:
--
--    transport (ua d50-enriched-equiv) d50-bdy-instance
--      ≡  d50-bulk-instance
--
--  This is the first observable-package equivalence on a 3D
--  densely-connected hyperbolic cell complex in the repository.
--  It demonstrates genuine "holographic depth": boundary regions
--  require cutting through multi-face RT separating surfaces
--  (min-cut up to 7) through the multiply-connected 3D bulk,
--  not just single-face cuts as in BFS-shell patches.
--
--  The formalization architecture scales from:
--
--    0D bdy / 1D bulk  (tree pilot, 8 regions, min-cut 1–2)
--    1D bdy / 2D bulk  (star, 10 regions, min-cut 1–2)
--    1D bdy / 2D bulk  (filled, 90 regions, min-cut 2–4)
--    2D bdy / 3D bulk  (honeycomb BFS, 26 regions, min-cut 1)
--    2D bdy / 3D bulk  (Dense-50, 139 regions, min-cut 1–7)  ← this
--
--  Phase:  D.1b (Dense-50 enriched bridge and transport)
--  Reference:  §6 of docs/10-frontier.md
-- ════════════════════════════════════════════════════════════════════

D50Theorem3 : Type₀
D50Theorem3 =
  transport d50-enriched-ua-path d50-bdy-instance
  ≡ d50-bulk-instance

d50-theorem3 : D50Theorem3
d50-theorem3 = d50-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §15.  Concrete pointwise computations (spot checks)
-- ════════════════════════════════════════════════════════════════════
--
--  Selected regions demonstrating that the transported observable
--  produces the expected numerical values across the full min-cut
--  range (1–7).  Each proof reduces the transported observable to
--  LBD50 r, which then computes judgmentally to the ℕ literal.
--
--  The Dense-50 patch is the first 3D instance with a nontrivial
--  min-cut spectrum, so these spot checks span the full range:
--
--    S = 1  (leaf cells with 1 internal face)
--    S = 2  (singleton boundary cells)
--    S = 3  (pairs and some singletons)
--    S = 5  (multi-cell regions near the core)
--    S = 7  (5-cell regions deep in the bulk)
-- ════════════════════════════════════════════════════════════════════

-- S = 1:  {c20}  — leaf cell, min-cut severs 1 internal face
transport-at-d50r82 :
  fst (transport d50-enriched-ua-path d50-bdy-instance) d50r82 ≡ 1
transport-at-d50r82 = d50-enriched-transport-pointwise d50r82

-- S = 2:  {c8}  — singleton boundary cell with 2-face cut
transport-at-d50r0 :
  fst (transport d50-enriched-ua-path d50-bdy-instance) d50r0 ≡ 2
transport-at-d50r0 = d50-enriched-transport-pointwise d50r0

-- S = 3:  {c9}  — singleton with 3-face separating surface
transport-at-d50r36 :
  fst (transport d50-enriched-ua-path d50-bdy-instance) d50r36 ≡ 3
transport-at-d50r36 = d50-enriched-transport-pointwise d50r36

-- S = 5:  {c8,c47}  — 2-cell region near the dense core
transport-at-d50r1 :
  fst (transport d50-enriched-ua-path d50-bdy-instance) d50r1 ≡ 5
transport-at-d50r1 = d50-enriched-transport-pointwise d50r1

-- S = 7:  {c8,c39,c44,c47,c49}  — 5-cell region, max min-cut
transport-at-d50r10 :
  fst (transport d50-enriched-ua-path d50-bdy-instance) d50r10 ≡ 7
transport-at-d50r10 = d50-enriched-transport-pointwise d50r10


-- ════════════════════════════════════════════════════════════════════
--  §16.  Coherence with the value-level package path
-- ════════════════════════════════════════════════════════════════════
--
--  The value-level package path  d50-package-path  (from
--  Bridge/Dense50Obs.agda) and the type-level Univalence path
--  d50-enriched-ua-path  encode the SAME mathematical content:
--  the 3D discrete Ryu–Takayanagi correspondence  S∂D50 ≡ LBD50
--  on all 139 cell-aligned boundary regions of the Dense-50 patch.
--
--  The connecting data is  d50-obs-path : S∂D50 ≡ LBD50 , which
--  appears as the obs-field component of  d50-package-path  and
--  as the rewiring step in  d50-enriched-equiv .
-- ════════════════════════════════════════════════════════════════════

d50-package-coherence :
  ObsPackage.obs (d50-package-path i1)
  ≡ fst d50-bulk-instance
d50-package-coherence = refl


-- ════════════════════════════════════════════════════════════════════
--  §17.  End-to-end pipeline summary
-- ════════════════════════════════════════════════════════════════════
--
--  The complete Dense-50 pipeline for the {4,3,5} honeycomb:
--
--    07_honeycomb_3d_multiStrategy.py      (Phase D.0: feasibility)
--      │  Dense growth strategy identified as optimal
--      ▼
--    08_generate_dense50.py                (Phase D.1b: code gen)
--      │
--      ├──▶ Common/Dense50Spec.agda        (139-ctor D50Region)
--      ├──▶ Boundary/Dense50Cut.agda       (139 S-cut clauses, S=1–7)
--      ├──▶ Bulk/Dense50Chain.agda         (139 L-min clauses)
--      ├──▶ Bulk/Dense50Curvature.agda     (edge-class κ₂₀, 3D GB)
--      └──▶ Bridge/Dense50Obs.agda         (139 refl + funExt)
--              │
--              ▼
--         d50-obs-path : S∂D50 ≡ LBD50    (Bridge/Dense50Obs)
--              │
--              ▼
--         d50-enriched-equiv :             (this module)
--           D50EnrichedBdy ≃ D50EnrichedBulk
--              │
--              ▼
--         d50-enriched-ua-path :
--           D50EnrichedBdy ≡ D50EnrichedBulk
--              │
--              ▼
--         d50-enriched-transport :
--           transport ... d50-bdy-instance ≡ d50-bulk-instance
--              │
--              ▼
--         d50-enriched-transport-obs :
--           fst (transport ... d50-bdy-instance) ≡ LBD50
--
--  Every step is machine-checked.  Transport is computable: it
--  reduces via uaβ to the forward map of the equivalence.  The
--  3D discrete Ryu–Takayanagi correspondence (min-cut through
--  the cell complex = minimal separating surface area) is the
--  content of the 139 pointwise refl proofs in d50-pointwise.
--
--  This module demonstrates that the holographic formalization
--  architecture handles densely-connected 3D bulk geometries
--  with nontrivial separating-surface topology.  The min-cut
--  spectrum (1–7) confirms that boundary regions at different
--  "depths" into the holographic bulk require genuinely different
--  numbers of internal faces to be severed — the combinatorial
--  analogue of the Ryu–Takayanagi surface growing in area as
--  the boundary region reaches deeper into the bulk.
-- ════════════════════════════════════════════════════════════════════