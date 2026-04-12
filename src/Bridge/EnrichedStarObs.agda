{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.EnrichedStarObs where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCut
open import Bulk.StarChain
open import Common.ObsPackage
open import Bridge.StarObs   using (star-pointwise ; Obs∂ ; ObsBulk)
open import Bridge.StarEquiv using (star-obs-path)

-- ════════════════════════════════════════════════════════════════════
--  §1.  Shorthand names for the boundary and bulk observables
-- ════════════════════════════════════════════════════════════════════
--
--  S∂ is the boundary min-cut entropy functional instantiated at the
--  canonical star specification.  LB is the bulk minimal-chain
--  length functional at the same specification.
--
--  These are definitionally distinct functions (defined by separate
--  case splits in Boundary/StarCut.agda and Bulk/StarChain.agda
--  respectively), but they are propositionally equal:
--
--    star-obs-path : S∂ ≡ LB
--
--  (constructed in Bridge/StarEquiv.agda via funExt star-pointwise).
--
--  The definitional distinctness is what makes the enriched types
--  below genuinely different types in the universe, and the
--  propositional equality is what makes them equivalent.  Together
--  these enable a nontrivial  ua  path and computable transport.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3  (enriched equivalence)
--    docs/instances/star-patch.md §6          (bridge construction)
-- ════════════════════════════════════════════════════════════════════

S∂ : Region → ℚ≥0
S∂ = S-cut (π∂ starSpec)

LB : Region → ℚ≥0
LB = L-min (πbulk starSpec)


-- ════════════════════════════════════════════════════════════════════
--  §2.  h-Level infrastructure
-- ════════════════════════════════════════════════════════════════════
--
--  The observable function space  Region → ℚ≥0  is a set (h-level 2)
--  because ℚ≥0 = ℕ is a set (isSetℚ≥0 from Util/Scalars.agda).
--
--  This is the key structural fact enabling the equivalence proof:
--  in a set, paths between elements are propositional (isProp),
--  which means the specification-agreement fields are propositional,
--  which means round-trip homotopies are automatic.
--
--  Reference:
--    docs/formal/02-foundations.md §1  (h-levels and truncation)
-- ════════════════════════════════════════════════════════════════════

isSetObs : isSet (Region → ℚ≥0)
isSetObs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Enriched observable types
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched boundary type pairs an observable function with a
--  proof that it agrees with the boundary specification S∂.  The
--  enriched bulk type pairs a function with agreement to LB.
--
--  These are "singleton types"  Σ[ f ] (f ≡ a)  — contractible
--  spaces centered at their respective reference functions.  They
--  are genuinely different types in the universe because S∂ and LB
--  are definitionally distinct.
--
--  The enrichment captures the idea that an observable bundle is
--  not just a function from regions to scalars, but a function
--  CERTIFIED to match a specific physical specification.  The
--  boundary certification references min-cut entropy; the bulk
--  certification references minimal chain length.
--
--  This is the enriched-package architecture from
--  docs/formal/03-holographic-bridge.md §3, where the
--  "asymmetric proof-carrying fields" are the specification-
--  agreement witnesses.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3.1  (specification-agreement types)
--    docs/formal/02-foundations.md §7           (the generic bridge pattern)
--    docs/instances/star-patch.md §6.2          (enriched bridge)
-- ════════════════════════════════════════════════════════════════════

EnrichedBdy : Type₀
EnrichedBdy = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ S∂)

EnrichedBulk : Type₀
EnrichedBulk = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ LB)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary instance carries the boundary observable function
--  together with the trivial agreement witness  refl : S∂ ≡ S∂ .
--  The bulk instance carries the bulk observable function with
--  refl : LB ≡ LB .
--
--  These are the concrete observable bundles for the 6-tile star
--  that the transport will convert between.
-- ════════════════════════════════════════════════════════════════════

bdy-instance : EnrichedBdy
bdy-instance = S∂ , refl

bulk-instance : EnrichedBulk
bulk-instance = LB , refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  The Iso between enriched types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map appends  star-obs-path  to the boundary
--  agreement witness, converting  f ≡ S∂  into  f ≡ LB  via
--  the discrete Ryu–Takayanagi correspondence.
--
--  The inverse map appends  sym star-obs-path  to convert back.
--
--  Round-trip proofs use the fact that the specification-agreement
--  fields are propositional (since Region → ℚ≥0 is a set):
--  any two paths  f ≡ S∂  (or  f ≡ LB) are equal, so composing
--  with  star-obs-path  and then with  sym star-obs-path  yields
--  a path propositionally equal to the original.
--
--  This is the core construction.  The forward map is the
--  "holographic translator": it takes a function certified against
--  the boundary specification and recertifies it against the bulk
--  specification, using the discrete RT correspondence as the
--  bridge.
--
--  The definition uses the  iso  constructor (rather than copattern
--  matching on the Iso record fields) for compatibility with the
--  no-eta-equality declaration on Iso.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §3.2  (the Iso construction)
--    docs/formal/02-foundations.md §4           (equivalences)
-- ════════════════════════════════════════════════════════════════════

enriched-iso : Iso EnrichedBdy EnrichedBulk
enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : EnrichedBdy → EnrichedBulk
    fwd (f , p) = f , p ∙ star-obs-path

    bwd : EnrichedBulk → EnrichedBdy
    bwd (f , q) = f , q ∙ sym star-obs-path

    fwd-bwd : (b : EnrichedBulk) → fwd (bwd b) ≡ b
    fwd-bwd (f , q) i =
      f , isSetObs f LB ((q ∙ sym star-obs-path) ∙ star-obs-path) q i

    bwd-fwd : (a : EnrichedBdy) → bwd (fwd a) ≡ a
    bwd-fwd (f , p) i =
      f , isSetObs f S∂ ((p ∙ star-obs-path) ∙ sym star-obs-path) p i


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

enriched-equiv : EnrichedBdy ≃ EnrichedBulk
enriched-equiv = isoToEquiv enriched-iso


-- ════════════════════════════════════════════════════════════════════
--  §7.  The Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Applying  ua  to the enriched equivalence yields a path between
--  EnrichedBdy and EnrichedBulk in the universe Type₀.
--
--  This path is NOT propositionally equal to  refl  (unlike the
--  trivial tree and star bridges that used  idEquiv ).  The two
--  types are genuinely different (they reference different
--  specification functions S∂ and LB), and the path carries the
--  nontrivial content of  star-obs-path  through the Glue type.
--
--  This is the "Univalence bridge": a path in the universe that
--  identifies boundary-certified and bulk-certified observable
--  packages as equal types, enabled by the discrete Ryu–Takayanagi
--  correspondence.
--
--  Reference:
--    docs/formal/02-foundations.md §5           (the Univalence axiom)
--    docs/formal/03-holographic-bridge.md §3.3  (Univalence application)
-- ════════════════════════════════════════════════════════════════════

enriched-ua-path : EnrichedBdy ≡ EnrichedBulk
enriched-ua-path = ua enriched-equiv


-- ════════════════════════════════════════════════════════════════════
--  §8.  Transport: the verified translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along the Univalence path converts the boundary
--  observable bundle to the bulk observable bundle.  By  uaβ ,
--  transport computes as the forward map of the equivalence:
--
--    transport enriched-ua-path bdy-instance
--    ≡  equivFun enriched-equiv bdy-instance
--    =  (S∂ , refl ∙ star-obs-path)
--    =  (S∂ , star-obs-path)
--
--  This is propositionally equal to  bulk-instance = (LB , refl) :
--  the first components are identified by  star-obs-path : S∂ ≡ LB ,
--  and the second components are identified because path spaces in
--  a set are propositional.
--
--  The computation step (uaβ) is the key:  transport does not get
--  stuck on an opaque postulate — it reduces to the concrete forward
--  map, which appends  star-obs-path  to the agreement witness.
--  This is the "compilation step": a computable transport between
--  exactly equivalent packaged types.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1  (ua and uaβ in Cubical Agda)
--    docs/formal/03-holographic-bridge.md §3.4  (verified transport)
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Step 1:  uaβ reduces transport to the forward map
-- ────────────────────────────────────────────────────────────────

transport-computes :
  transport enriched-ua-path bdy-instance
  ≡ equivFun enriched-equiv bdy-instance
transport-computes = uaβ enriched-equiv bdy-instance

-- ────────────────────────────────────────────────────────────────
--  Step 2:  The forward map output equals the bulk instance
-- ────────────────────────────────────────────────────────────────
--
--  equivFun enriched-equiv bdy-instance = (S∂ , refl ∙ star-obs-path)
--  bulk-instance                        = (LB , refl)
--
--  The path uses  star-obs-path  for the first component and
--  isProp of the path type for the second component (propositional
--  because Region → ℚ≥0 is a set).
-- ────────────────────────────────────────────────────────────────

private
  fwd-eq-bulk : equivFun enriched-equiv bdy-instance ≡ bulk-instance
  fwd-eq-bulk i =
    star-obs-path i ,
    isProp→PathP
      (λ j → isSetObs (star-obs-path j) LB)
      (refl ∙ star-obs-path)
      refl
      i

-- ────────────────────────────────────────────────────────────────
--  Combined: transport produces the bulk instance
-- ────────────────────────────────────────────────────────────────

enriched-transport :
  transport enriched-ua-path bdy-instance ≡ bulk-instance
enriched-transport = transport-computes ∙ fwd-eq-bulk


-- ════════════════════════════════════════════════════════════════════
--  §9.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported boundary instance equals the
--  bulk observable function  L-min (πbulk starSpec) .
--
--  In operational terms: given entanglement data (the boundary
--  observable function S∂) certified against the boundary
--  specification, transport produces a function certified against
--  the bulk specification — and that function is exactly the bulk
--  minimal-chain-length functional LB.
--
--  This is the discrete Ryu–Takayanagi correspondence (Theorem 1
--  in docs/formal/01-theorems.md) instantiated for the 6-tile
--  star: the boundary cut-entropy observable package and the bulk
--  minimal-chain-length observable package are connected by an
--  exact type equivalence, and transport along the resulting
--  Univalence path carries the boundary functional to the bulk
--  functional.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 1          (Discrete Ryu–Takayanagi)
--    docs/formal/03-holographic-bridge.md §3.4  (verified transport)
--    docs/instances/star-patch.md §6            (star bridge construction)
-- ════════════════════════════════════════════════════════════════════

enriched-transport-obs :
  fst (transport enriched-ua-path bdy-instance) ≡ LB
enriched-transport-obs = cong fst enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §10.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The transport result holds pointwise: for every admissible
--  boundary region, the transported observable agrees with the
--  bulk minimal-chain functional.
--
--  This makes the "verified translator" fully explicit: given any
--  region r, transport converts the boundary min-cut value S∂(r)
--  to the bulk chain-length value LB(r), and these are provably
--  equal.
-- ════════════════════════════════════════════════════════════════════

enriched-transport-pointwise :
  (r : Region) →
  fst (transport enriched-ua-path bdy-instance) r ≡ LB r
enriched-transport-pointwise r = cong (λ f → f r) enriched-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §11.  Nontriviality witness
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched  ua  path is NOT propositionally equal to  refl .
--  This distinguishes it from the trivial bridges in
--  Bridge/TreeEquiv.agda and Bridge/StarEquiv.agda, where
--  ua (idEquiv A) ≡ refl  by  uaIdEquiv .
--
--  The enriched equivalence is NOT  idEquiv  because the two types
--  are not definitionally equal (they reference different
--  specification functions).  Therefore  uaIdEquiv  does not apply,
--  and  transport  performs genuine computational work.
--
--  Formally, we witness nontriviality by showing that the forward
--  map is NOT the identity function on the underlying pairs:
--  it modifies the second component (the agreement witness) by
--  appending  star-obs-path .
-- ════════════════════════════════════════════════════════════════════

-- The forward map applied to bdy-instance yields a pair whose
-- second component is  refl ∙ star-obs-path , not  refl .
fwd-snd-is-star-obs-path :
  snd (equivFun enriched-equiv bdy-instance) ≡ refl ∙ star-obs-path
fwd-snd-is-star-obs-path = refl


-- ════════════════════════════════════════════════════════════════════
--  §12.  Type family and universe-level transport
-- ════════════════════════════════════════════════════════════════════
--
--  A type family Φ over the universe allows computing:
--
--    transport^Φ(p)(ρ∂)  :  Φ(EnrichedBulk)
--
--  where  p = enriched-ua-path  and  ρ∂ = bdy-instance .
--
--  The simplest nontrivial Φ is the identity family  id : Type → Type .
--  Transport along  p  with this family is just ordinary transport,
--  which we have already computed above.
--
--  A more interesting family:  Φ(X) = X → ℚ≥0 .  Transport along
--  p  converts a function on EnrichedBdy to a function on
--  EnrichedBulk by precomposing with the inverse of the equivalence.
--  This exercises the contravariant computational behavior of
--  transport in function types.
--
--  Reference:
--    docs/formal/02-foundations.md §3  (transport)
-- ════════════════════════════════════════════════════════════════════

-- Type family Φ : Type₀ → Type₀
Φ : Type₀ → Type₀
Φ X = X → ℚ≥0

-- A sample function on the boundary type: extract the observable
-- at region regN0
sample-bdy-fn : Φ EnrichedBdy
sample-bdy-fn (f , _) = f regN0

-- Transport Φ along the Univalence path
transported-fn : Φ EnrichedBulk
transported-fn = transport (cong Φ enriched-ua-path) sample-bdy-fn

-- The original function, when applied to the boundary instance,
-- yields the boundary min-cut value at regN0.
--
-- Specifically:  sample-bdy-fn bdy-instance = S∂ regN0 = 1q
--
-- This is verified as a concrete computation:
sample-bdy-value : sample-bdy-fn bdy-instance ≡ 1q
sample-bdy-value = refl


-- ════════════════════════════════════════════════════════════════════
--  §13.  Connection to subadditivity and monotonicity
-- ════════════════════════════════════════════════════════════════════
--
--  The enriched specification-agreement types above exercise  ua
--  nontrivially.  The FURTHER enrichment with structural properties
--  (subadditivity on the boundary, monotonicity on the bulk) is
--  COMPATIBLE with this architecture: since the agreement fields
--  pin down the observable function to S∂ (resp. LB), any
--  structural property of S∂ (resp. LB) can be derived from the
--  agreement witness.
--
--  Concretely, given  (f , p : f ≡ S∂) : EnrichedBdy , the
--  subadditivity of S∂ (proven in Boundary/StarSubadditivity.agda)
--  transports along  p  to yield subadditivity of  f .  Similarly,
--  monotonicity of LB (proven in Bulk/StarMonotonicity.agda)
--  transports to any  f  with  f ≡ LB .
--
--  The enriched equivalence therefore ALSO converts between:
--
--    • A boundary bundle (f, f≡S∂, subadd-f)    — where subadd-f
--      is derived from f≡S∂ and the subadditivity of S∂
--
--    • A bulk bundle (f, f≡LB, mono-f)            — where mono-f
--      is derived from f≡LB and the monotonicity of LB
--
--  This is the full enriched-package architecture described in
--  docs/formal/03-holographic-bridge.md §4.  The structural
--  property witnesses are NOT independent data: they are
--  determined by the specification-agreement field plus the
--  externally proven properties of S∂ and LB.  The equivalence
--  preserves them automatically because transport in propositions
--  is trivial.
--
--  The full record types with explicit subadd/mono fields are
--  defined in Bridge/FullEnrichedStarObs.agda, where transport
--  converts a subadditivity witness into a monotonicity witness.
--
--  The proof composes:
--
--    subadd-S∂ ──[transport along p]──▶ subadd-f
--                                           ║
--                                    (f ≡ S∂ ≡ LB)
--                                           ║
--    mono-LB   ──[transport along q]──▶ mono-f
--
--  where the two paths meet because  f  is identified with both
--  S∂ and LB through the enriched equivalence.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §4     (full enriched equivalence)
--    docs/formal/01-theorems.md §Thm 8           (subadditivity & monotonicity)
--    docs/instances/star-patch.md §5             (structural properties)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §14.  End-to-end pipeline summary
-- ════════════════════════════════════════════════════════════════════
--
--  The complete pipeline for the 6-tile star, with a nontrivial
--  Univalence step:
--
--    starSpec                                         (Common/StarSpec)
--      │
--      ├── π∂ ──▶ BoundaryView ──▶ S-cut             (Boundary/StarCut)
--      │
--      └── πbulk ──▶ BulkView ──▶ L-min              (Bulk/StarChain)
--             │
--             ▼
--         star-pointwise : S∂ r ≡ LB r  ∀ r           (Bridge/StarObs)
--             │
--             ▼
--         star-obs-path : S∂ ≡ LB                     (Bridge/StarEquiv)
--             │
--             ▼
--         enriched-equiv : EnrichedBdy ≃ EnrichedBulk (this module)
--             │
--             ▼
--         enriched-ua-path : EnrichedBdy ≡ EnrichedBulk
--             │
--             ▼
--         enriched-transport :
--           transport enriched-ua-path bdy-instance ≡ bulk-instance
--             │
--             ▼
--         enriched-transport-obs :
--           fst (transport ... bdy-instance) ≡ LB
--
--  Every step is machine-checked by the Cubical Agda type-checker.
--  The transport function is computable: it reduces via uaβ to the
--  forward map of the equivalence, which rewires the agreement
--  witness through the discrete Ryu–Takayanagi correspondence.
--
--  This module is the hand-written enriched bridge for the star
--  patch.  The generic bridge theorem (Bridge/GenericBridge.agda)
--  proves the same construction once for any PatchData, and
--  star-generic-witness (from Bridge/GenericValidation.agda)
--  subsumes this module's results.  This module is retained as
--  the historical first nontrivial Univalence bridge and as the
--  foundation for the full structural-property conversion in
--  Bridge/FullEnrichedStarObs.agda.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md   (holographic bridge overview)
--    docs/formal/11-generic-bridge.md       (generic bridge — subsumes this)
--    docs/formal/01-theorems.md §Thm 1      (Discrete Ryu–Takayanagi)
--    docs/instances/star-patch.md §6        (star bridge construction)
--    docs/getting-started/architecture.md   (module dependency DAG)
--    docs/reference/module-index.md         (module description)
-- ════════════════════════════════════════════════════════════════════