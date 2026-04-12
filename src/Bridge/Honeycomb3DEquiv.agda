{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.Honeycomb3DEquiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Transport

open import Util.Scalars
open import Common.Honeycomb3DSpec
open import Common.ObsPackage
open import Boundary.Honeycomb3DCut
open import Bulk.Honeycomb3DChain
open import Bridge.Honeycomb3DObs
  using ( h3-pointwise ; h3-obs-path ; h3-package-path
        ; H3Obs∂ ; H3ObsBulk
        ; h3BdyView ; h3BulkView )


-- ════════════════════════════════════════════════════════════════════
--  3D Honeycomb Enriched Observable-Package Equivalence
-- ════════════════════════════════════════════════════════════════════
--
--  This module constructs the enriched type equivalence for the
--  {4,3,5} honeycomb 3D star patch, mirroring Bridge/FilledEquiv.agda.
--
--  The 3D patch has 32 cells (1 central cube + 6 face-neighbors +
--  25 BFS-expanded neighbors), 31 internal shared faces, and 130
--  boundary faces.  The Python oracle (06_generate_honeycomb_3d.py)
--  identified 26 singleton-cell boundary regions, all with min-cut
--  value 1.  Since the orbit count (26) is small, flat enumeration
--  suffices (no orbit reduction needed).
--
--  The enriched equivalence uses the specification-agreement pattern:
--  the two enriched types are Σ-types centered at definitionally
--  distinct specification functions (S∂3D and LB3D), connected by
--  h3-obs-path : S∂3D ≡ LB3D  (the 3D discrete Ryu–Takayanagi
--  correspondence, verified by 26 cases of refl).
--
--  This is the first enriched type equivalence on a 3D hyperbolic
--  cell complex in the repository, demonstrating that the
--  holographic formalization architecture is not dimension-specific.
--
--  Architectural note:
--    This hand-written module is architecturally superseded by the
--    generic bridge (Bridge/GenericBridge.agda).  The 3D honeycomb
--    BridgeWitness is now produced automatically by GenericEnriched
--    via h3-generic-witness in Bridge/GenericValidation.agda.  This
--    module is retained as the historical first 3D enriched bridge
--    and as a concrete demonstration of the enriched-Σ / Iso /
--    isoToEquiv / ua / uaβ pipeline on a 3D cell complex.
--
--  Reference:
--    docs/instances/honeycomb-3d.md        (instance data sheet)
--    docs/formal/03-holographic-bridge.md  (enriched equivalence)
--    docs/formal/11-generic-bridge.md      (generic bridge — subsumes this)
--    docs/engineering/oracle-pipeline.md   (Python oracle: script 06)
--    docs/reference/module-index.md        (module description)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Shorthand names for the boundary and bulk observables
-- ════════════════════════════════════════════════════════════════════
--
--  S∂3D is the boundary min-cut functional for the 3D {4,3,5}
--  patch.  In 3D, the min-cut is a set of internal cube faces
--  whose removal disconnects the cell-aligned boundary region from
--  its complement — a minimal separating SURFACE, not a 1D curve.
--
--  LB3D is the bulk minimal separating-surface functional at the
--  same specification.  Under uniform face weights, both functionals
--  compute the same face-count min-cut for all 26 regions.
--
--  These are definitionally distinct functions (defined by separate
--  26-clause case splits in Boundary/Honeycomb3DCut.agda and
--  Bulk/Honeycomb3DChain.agda respectively), but they are
--  propositionally equal:
--
--    h3-obs-path : S∂3D ≡ LB3D
--
--  (constructed in Bridge/Honeycomb3DObs.agda via funExt h3-pointwise).
-- ════════════════════════════════════════════════════════════════════

S∂3D : H3Region → ℚ≥0
S∂3D = S-cut h3BdyView

LB3D : H3Region → ℚ≥0
LB3D = L-min h3BulkView


-- ════════════════════════════════════════════════════════════════════
--  §2.  h-Level infrastructure
-- ════════════════════════════════════════════════════════════════════
--
--  The observable function space  H3Region → ℚ≥0  is a set
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

isSetH3Obs : isSet (H3Region → ℚ≥0)
isSetH3Obs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Enriched observable types
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched boundary type pairs an observable function with a
--  proof that it agrees with the 3D boundary specification S∂3D.
--  The enriched bulk type pairs a function with agreement to LB3D.
--
--  These are singleton types  Σ[ f ] (f ≡ a)  — contractible
--  spaces centered at their respective reference functions.  They
--  are genuinely different types in the universe because S∂3D and
--  LB3D are definitionally distinct (26-clause pattern matches
--  defined in separate modules).
--
--  The enrichment captures the 3D analogue of the 2D principle:
--  an observable bundle is not just a function from regions to
--  scalars, but a function CERTIFIED to match a specific physical
--  specification.  The boundary certification references 3D min-cut
--  entropy (minimal separating surface area); the bulk certification
--  references 3D minimal separating-surface area.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3.1  (specification-agreement types)
--    docs/formal/02-foundations.md §7            (the generic bridge pattern)
--    docs/instances/honeycomb-3d.md §6           (bridge construction)
-- ════════════════════════════════════════════════════════════════════

H3EnrichedBdy : Type₀
H3EnrichedBdy = Σ[ f ∈ (H3Region → ℚ≥0) ] (f ≡ S∂3D)

H3EnrichedBulk : Type₀
H3EnrichedBulk = Σ[ f ∈ (H3Region → ℚ≥0) ] (f ≡ LB3D)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary instance carries the 3D boundary observable function
--  together with the trivial agreement witness  refl : S∂3D ≡ S∂3D.
--  The bulk instance carries the 3D bulk observable function with
--  refl : LB3D ≡ LB3D.
--
--  These are the concrete 3D observable bundles that transport will
--  convert between.
-- ════════════════════════════════════════════════════════════════════

h3-bdy-instance : H3EnrichedBdy
h3-bdy-instance = S∂3D , refl

h3-bulk-instance : H3EnrichedBulk
h3-bulk-instance = LB3D , refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  The Iso between enriched types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map appends  h3-obs-path  to the boundary agreement
--  witness, converting  f ≡ S∂3D  into  f ≡ LB3D  via the 3D
--  discrete Ryu–Takayanagi correspondence.
--
--  The inverse map appends  sym h3-obs-path  to convert back.
--
--  Round-trip proofs use the fact that the specification-agreement
--  fields are propositional (since H3Region → ℚ≥0 is a set):
--  any two paths  f ≡ S∂3D  (or  f ≡ LB3D) are equal, so
--  composing with  h3-obs-path  and then  sym h3-obs-path  yields
--  a path propositionally equal to the original.
--
--  This is structurally identical to the 2D constructions in
--  Bridge/EnrichedStarObs.agda and Bridge/FilledEquiv.agda, using
--  h3-obs-path in place of star-obs-path or filled-obs-path.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3.2  (the Iso construction)
--    docs/formal/02-foundations.md §4            (equivalences)
-- ════════════════════════════════════════════════════════════════════

h3-enriched-iso : Iso H3EnrichedBdy H3EnrichedBulk
h3-enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : H3EnrichedBdy → H3EnrichedBulk
    fwd (f , p) = f , p ∙ h3-obs-path

    bwd : H3EnrichedBulk → H3EnrichedBdy
    bwd (f , q) = f , q ∙ sym h3-obs-path

    fwd-bwd : (b : H3EnrichedBulk) → fwd (bwd b) ≡ b
    fwd-bwd (f , q) i =
      f , isSetH3Obs f LB3D
            ((q ∙ sym h3-obs-path) ∙ h3-obs-path) q i

    bwd-fwd : (a : H3EnrichedBdy) → bwd (fwd a) ≡ a
    bwd-fwd (f , p) i =
      f , isSetH3Obs f S∂3D
            ((p ∙ h3-obs-path) ∙ sym h3-obs-path) p i


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

h3-enriched-equiv : H3EnrichedBdy ≃ H3EnrichedBulk
h3-enriched-equiv = isoToEquiv h3-enriched-iso


-- ════════════════════════════════════════════════════════════════════
--  §7.  The Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Applying  ua  to the enriched equivalence yields a path between
--  H3EnrichedBdy and H3EnrichedBulk in the universe Type₀.
--
--  This path is NOT propositionally equal to  refl .  The two types
--  are genuinely different (they reference different specification
--  functions S∂3D and LB3D), and the path carries the nontrivial
--  content of  h3-obs-path  through the Glue type.
--
--  This is the first Univalence path between enriched observable
--  types on a 3D hyperbolic cell complex in the repository,
--  extending the holographic formalization from the 2D → 3D
--  dimensional regime where holographic duality was originally
--  formulated (Maldacena, 1997).
--
--  Reference:
--    docs/formal/02-foundations.md §5            (the Univalence axiom)
--    docs/formal/03-holographic-bridge.md §3.3   (Univalence application)
--    docs/instances/honeycomb-3d.md §14          (the dimensional transition)
-- ════════════════════════════════════════════════════════════════════

h3-enriched-ua-path : H3EnrichedBdy ≡ H3EnrichedBulk
h3-enriched-ua-path = ua h3-enriched-equiv


-- ════════════════════════════════════════════════════════════════════
--  §8.  Transport: the verified 3D translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along the Univalence path converts the 3D boundary
--  observable bundle to the 3D bulk observable bundle.  By  uaβ ,
--  transport computes as the forward map of the equivalence:
--
--    transport h3-enriched-ua-path h3-bdy-instance
--    ≡  equivFun h3-enriched-equiv h3-bdy-instance
--    =  (S∂3D , refl ∙ h3-obs-path)
--    =  (S∂3D , h3-obs-path)
--
--  This is propositionally equal to
--    h3-bulk-instance = (LB3D , refl) :
--  the first components are identified by  h3-obs-path ,
--  and the second components by  isSetH3Obs  (propositional
--  because H3Region → ℚ≥0 is a set).
--
--  The computation step (uaβ) is the key:  transport reduces to
--  the concrete forward map, which appends  h3-obs-path  to the
--  agreement witness.  This is the "3D compilation step":
--  a computable transport between exactly equivalent 3D observable
--  packages, where the min-cut is a minimal SURFACE (not a curve)
--  through the 3D cell complex.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1          (ua and uaβ in Cubical Agda)
--    docs/formal/03-holographic-bridge.md §3.4   (verified transport)
-- ════════════════════════════════════════════════════════════════════

-- Step 1:  uaβ reduces transport to the forward map
h3-transport-computes :
  transport h3-enriched-ua-path h3-bdy-instance
  ≡ equivFun h3-enriched-equiv h3-bdy-instance
h3-transport-computes = uaβ h3-enriched-equiv h3-bdy-instance

-- Step 2:  The forward map output equals the bulk instance
private
  h3-fwd-eq-bulk :
    equivFun h3-enriched-equiv h3-bdy-instance
    ≡ h3-bulk-instance
  h3-fwd-eq-bulk i =
    h3-obs-path i ,
    isProp→PathP
      (λ j → isSetH3Obs (h3-obs-path j) LB3D)
      (refl ∙ h3-obs-path)
      refl
      i

-- Combined: transport produces the bulk instance
h3-enriched-transport :
  transport h3-enriched-ua-path h3-bdy-instance
  ≡ h3-bulk-instance
h3-enriched-transport = h3-transport-computes ∙ h3-fwd-eq-bulk


-- ════════════════════════════════════════════════════════════════════
--  §9.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported 3D boundary instance equals the
--  3D bulk observable function  LB3D = L-min h3BulkView .
--
--  In operational terms: given 3D entanglement data (the boundary
--  observable S∂3D encoding min-cut surface areas through the cell
--  complex) certified against the boundary specification, transport
--  produces a function certified against the bulk specification —
--  and that function is exactly the 3D bulk minimal separating-
--  surface functional LB3D.
--
--  This extends the observable-package equivalence from:
--    Tree  (8 regions, 1D tree pilot)
--    Star  (10 regions, 2D star patch)
--    Filled (90 regions, 2D full disk)
--  to:
--    Honeycomb (26 regions, 3D {4,3,5} star patch)
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 1           (Discrete Ryu–Takayanagi)
--    docs/formal/03-holographic-bridge.md §3.4    (verified transport)
--    docs/instances/honeycomb-3d.md §6            (bridge construction)
-- ════════════════════════════════════════════════════════════════════

h3-enriched-transport-obs :
  fst (transport h3-enriched-ua-path h3-bdy-instance) ≡ LB3D
h3-enriched-transport-obs = cong fst h3-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §10.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The transport result holds pointwise: for every admissible
--  boundary region of the 3D {4,3,5} patch, the transported
--  observable agrees with the bulk minimal separating-surface
--  functional.
-- ════════════════════════════════════════════════════════════════════

h3-enriched-transport-pointwise :
  (r : H3Region) →
  fst (transport h3-enriched-ua-path h3-bdy-instance) r ≡ LB3D r
h3-enriched-transport-pointwise r =
  cong (λ f → f r) h3-enriched-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §11.  Nontriviality witness
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched  ua  path is NOT propositionally equal to  refl .
--  The forward map modifies the second component (the agreement
--  witness) by appending  h3-obs-path , which encodes the 26-case
--  3D discrete Ryu–Takayanagi correspondence for the {4,3,5}
--  honeycomb patch.
-- ════════════════════════════════════════════════════════════════════

h3-fwd-snd-is-obs-path :
  snd (equivFun h3-enriched-equiv h3-bdy-instance)
  ≡ refl ∙ h3-obs-path
h3-fwd-snd-is-obs-path = refl


-- ════════════════════════════════════════════════════════════════════
--  §12.  Reverse transport
-- ════════════════════════════════════════════════════════════════════
--
--  The Univalence path is a genuine path in the universe, and
--  transport is invertible: transporting along  sym p  reverses
--  the direction.  This gives a BIDIRECTIONAL 3D translator.
-- ════════════════════════════════════════════════════════════════════

h3-reverse-enriched :
  transport (sym h3-enriched-ua-path) h3-bulk-instance
  ≡ h3-bdy-instance
h3-reverse-enriched =
  cong (transport (sym h3-enriched-ua-path))
       (sym h3-enriched-transport)
  ∙ transport⁻Transport h3-enriched-ua-path h3-bdy-instance


-- ════════════════════════════════════════════════════════════════════
--  §13.  Roundtrip verification
-- ════════════════════════════════════════════════════════════════════
--
--  The forward and reverse transports compose to the identity in
--  both directions.  The 3D bridge is lossless.
-- ════════════════════════════════════════════════════════════════════

h3-roundtrip-bdy :
  transport (sym h3-enriched-ua-path)
    (transport h3-enriched-ua-path h3-bdy-instance)
  ≡ h3-bdy-instance
h3-roundtrip-bdy =
  transport⁻Transport h3-enriched-ua-path h3-bdy-instance

h3-roundtrip-bulk :
  transport h3-enriched-ua-path
    (transport (sym h3-enriched-ua-path) h3-bulk-instance)
  ≡ h3-bulk-instance
h3-roundtrip-bulk =
  transportTransport⁻ h3-enriched-ua-path h3-bulk-instance


-- ════════════════════════════════════════════════════════════════════
--  §14.  H3BridgeWitness — Milestone packaging record
-- ════════════════════════════════════════════════════════════════════
--
--  Packages the 3D honeycomb bridge into a single inspectable
--  artifact, following the BridgeWitness pattern from
--  Bridge/BridgeWitness.agda (originally from
--  Bridge/EnrichedStarEquiv.agda).
--
--  This record lives in  Type₁  because it stores types as fields.
--
--  Note: The canonical BridgeWitness for the honeycomb patch is now
--  produced by the generic bridge machinery (GenericEnriched applied
--  to h3PatchData in Bridge/GenericValidation.agda).  This local
--  record type is retained for the self-contained demonstration.
-- ════════════════════════════════════════════════════════════════════

record H3BridgeWitness : Type₁ where
  field
    BdyTy              : Type₀
    BulkTy             : Type₀
    bdy-data           : BdyTy
    bulk-data          : BulkTy
    bridge             : BdyTy ≃ BulkTy
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data

h3-bridge-witness : H3BridgeWitness
h3-bridge-witness .H3BridgeWitness.BdyTy              = H3EnrichedBdy
h3-bridge-witness .H3BridgeWitness.BulkTy             = H3EnrichedBulk
h3-bridge-witness .H3BridgeWitness.bdy-data           = h3-bdy-instance
h3-bridge-witness .H3BridgeWitness.bulk-data          = h3-bulk-instance
h3-bridge-witness .H3BridgeWitness.bridge             = h3-enriched-equiv
h3-bridge-witness .H3BridgeWitness.transport-verified = h3-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §15.  Theorem statement — 3D Honeycomb Bridge
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (3D Honeycomb Bridge — Observable Package Equivalence).
--
--  For the 3D star patch of the {4,3,5} hyperbolic honeycomb
--  (32 cubic cells, 130 boundary faces, 26 cell-aligned boundary
--  regions), the boundary min-cut entropy observable package and
--  the bulk minimal separating-surface observable package are
--  exactly equivalent as types.  Transport along the resulting
--  Univalence path carries the boundary bundle to the bulk bundle.
--
--  In symbols:
--
--    transport (ua h3-enriched-equiv) h3-bdy-instance
--      ≡  h3-bulk-instance
--
--  This is the first observable-package equivalence on a 3D
--  hyperbolic cell complex in the repository.  It demonstrates
--  that the holographic formalization architecture scales from:
--
--    0D bdy / 1D bulk  (tree pilot)
--    1D bdy / 2D bulk  (star + filled patches)
--    2D bdy / 3D bulk  (this module)
--
--  — the dimensional regime where holographic duality was
--  originally formulated by Maldacena (1997).
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 1           (Discrete Ryu–Takayanagi)
--    docs/formal/03-holographic-bridge.md         (holographic bridge overview)
--    docs/instances/honeycomb-3d.md               (instance data sheet)
--    docs/reference/module-index.md               (module description)
-- ════════════════════════════════════════════════════════════════════

H3Theorem3 : Type₀
H3Theorem3 =
  transport h3-enriched-ua-path h3-bdy-instance
  ≡ h3-bulk-instance

h3-theorem3 : H3Theorem3
h3-theorem3 = h3-enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §16.  Concrete pointwise computations (spot checks)
-- ════════════════════════════════════════════════════════════════════
--
--  Selected regions demonstrating that the transported observable
--  produces the expected numerical values.  Each proof reduces the
--  transported observable to  LB3D r , which then computes
--  judgmentally to the ℕ literal.
--
--  All 26 singleton-cell regions have min-cut value 1 because each
--  boundary cell shares exactly one internal face with its
--  neighbor — severing that single face disconnects the cell.
--
--  Region naming:  h3r⟨index⟩  (0-indexed, matching the Python
--  oracle output from 06_generate_honeycomb_3d.py).
-- ════════════════════════════════════════════════════════════════════

-- Singleton: {c6}  →  S = 1
transport-at-h3r0 :
  fst (transport h3-enriched-ua-path h3-bdy-instance) h3r0 ≡ 1
transport-at-h3r0 = h3-enriched-transport-pointwise h3r0

-- Singleton: {c15}  →  S = 1
transport-at-h3r9 :
  fst (transport h3-enriched-ua-path h3-bdy-instance) h3r9 ≡ 1
transport-at-h3r9 = h3-enriched-transport-pointwise h3r9

-- Singleton: {c25}  →  S = 1
transport-at-h3r19 :
  fst (transport h3-enriched-ua-path h3-bdy-instance) h3r19 ≡ 1
transport-at-h3r19 = h3-enriched-transport-pointwise h3r19

-- Singleton: {c31}  →  S = 1  (last region)
transport-at-h3r25 :
  fst (transport h3-enriched-ua-path h3-bdy-instance) h3r25 ≡ 1
transport-at-h3r25 = h3-enriched-transport-pointwise h3r25


-- ════════════════════════════════════════════════════════════════════
--  §17.  Coherence with the value-level package path
-- ════════════════════════════════════════════════════════════════════
--
--  The value-level package path  h3-package-path  (from
--  Bridge/Honeycomb3DObs.agda) and the type-level Univalence path
--  h3-enriched-ua-path  encode the SAME mathematical content:
--  the 3D discrete Ryu–Takayanagi correspondence  S∂3D ≡ LB3D
--  on all 26 cell-aligned boundary regions of the {4,3,5} patch.
--
--  The connecting data is  h3-obs-path : S∂3D ≡ LB3D , which
--  appears as the obs-field component of  h3-package-path  and
--  as the rewiring step in  h3-enriched-equiv .
-- ════════════════════════════════════════════════════════════════════

h3-package-coherence :
  ObsPackage.obs (h3-package-path i1)
  ≡ fst h3-bulk-instance
h3-package-coherence = refl


-- ════════════════════════════════════════════════════════════════════
--  §18.  End-to-end pipeline summary
-- ════════════════════════════════════════════════════════════════════
--
--  The complete 3D pipeline for the {4,3,5} honeycomb patch:
--
--    05_honeycomb_3d_prototype.py          (feasibility probe)
--      │  Gate: 130 bdy faces ✓, 26 regions ✓, full valence ✓
--      ▼
--    06_generate_honeycomb_3d.py           (Agda code generation)
--      │
--      ├──▶ Common/Honeycomb3DSpec.agda    (26-ctor H3Region)
--      ├──▶ Boundary/Honeycomb3DCut.agda   (26 S-cut clauses)
--      ├──▶ Bulk/Honeycomb3DChain.agda     (26 L-min clauses)
--      ├──▶ Bulk/Honeycomb3DCurvature.agda (edge-class κ, 3D GB)
--      └──▶ Bridge/Honeycomb3DObs.agda     (26 refl + funExt)
--              │
--              ▼
--         h3-obs-path : S∂3D ≡ LB3D       (Bridge/Honeycomb3DObs)
--              │
--              ▼
--         h3-enriched-equiv :              (this module)
--           H3EnrichedBdy ≃ H3EnrichedBulk
--              │
--              ▼
--         h3-enriched-ua-path :
--           H3EnrichedBdy ≡ H3EnrichedBulk
--              │
--              ▼
--         h3-enriched-transport :
--           transport ... h3-bdy-instance ≡ h3-bulk-instance
--              │
--              ▼
--         h3-enriched-transport-obs :
--           fst (transport ... h3-bdy-instance) ≡ LB3D
--
--  Every step is machine-checked.  Transport is computable: it
--  reduces via uaβ to the forward map of the equivalence.  The
--  3D discrete Ryu–Takayanagi correspondence (min-cut through
--  the cell complex = minimal separating surface area) is the
--  content of the 26 pointwise refl proofs in h3-pointwise.
--
--  This module demonstrates that the holographic formalization
--  architecture is dimension-agnostic: the same enriched-Σ / Iso
--  / isoToEquiv / ua / uaβ pipeline works identically on 1D trees,
--  2D tilings, and 3D honeycombs.
--
--  The generic bridge theorem (Bridge/GenericBridge.agda) subsumes
--  this hand-written construction: h3-generic-witness in
--  Bridge/GenericValidation.agda produces the same BridgeWitness
--  automatically from the h3PatchData interface, without any
--  per-instance proof engineering.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md         (enriched equivalence)
--    docs/formal/11-generic-bridge.md             (generic bridge — subsumes)
--    docs/instances/honeycomb-3d.md               (instance data sheet)
--    docs/engineering/oracle-pipeline.md           (Python oracle scripts)
--    docs/getting-started/architecture.md         (module dependency DAG)
--    docs/reference/module-index.md               (module description)
--    docs/historical/development-documents/10-frontier.md §6
--                                                 (original development plan)
-- ════════════════════════════════════════════════════════════════════