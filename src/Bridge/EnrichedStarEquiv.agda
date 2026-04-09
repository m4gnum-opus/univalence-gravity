{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.EnrichedStarEquiv where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Transport

open import Util.Scalars
open import Common.StarSpec
open import Common.ObsPackage
open import Boundary.StarCut
open import Bulk.StarChain
open import Bridge.StarObs
  using (star-pointwise ; Obs∂ ; ObsBulk)
open import Bridge.StarEquiv
  using (star-obs-path ; star-package-path)
open import Bridge.EnrichedStarObs
  using ( S∂ ; LB ; isSetObs
        ; EnrichedBdy ; EnrichedBulk
        ; bdy-instance ; bulk-instance
        ; enriched-equiv ; enriched-ua-path
        ; enriched-transport ; enriched-transport-obs
        ; enriched-transport-pointwise )
open import Bridge.FullEnrichedStarObs
  using ( FullBdy ; FullBulk
        ; full-bdy ; full-bulk
        ; full-equiv ; full-ua-path
        ; full-transport ; full-transport-obs
        ; full-transport-pointwise
        ; full-transport-mono
        ; transported-mono-witness
        ; Subadditive ; Monotone
        ; S∂-subadd ; LB-mono )


-- ════════════════════════════════════════════════════════════════════
--  §1.  BridgeWitness — Milestone 3–4 Packaging Record
-- ════════════════════════════════════════════════════════════════════
--
--  This record packages the data and proofs constituting the
--  Univalence bridge (Phase 3C) into a single inspectable artifact.
--  It is the counterpart of  GaussBonnetWitness  (Bulk/GaussBonnet.agda)
--  for the bridge side of the project.
--
--  The record captures:
--
--    • Two observable types (boundary-certified and bulk-certified)
--    • Canonical inhabitants (the concrete observable bundles)
--    • The exact type equivalence between them
--    • Verification that transport along the resulting  ua  path
--      carries the boundary instance to the bulk instance
--
--  This is the **Milestones 3–4 deliverable** from §6.9 of
--  docs/06-challenges.md:
--
--    Milestone 3:  "A well-typed common source specification
--    producing both boundary and bulk views.  Observable packages
--    extracted as record types from the common source."
--
--    Milestone 4:  "An exact equivalence between boundary and bulk
--    observable packages for at least one concrete instance.
--    Transport along the Univalence path producing a verified
--    translator."
--
--  Field naming:  The record fields are named  BdyTy  and  BulkTy
--  (not  ObsBdy / ObsBulk) to avoid clashing with the imported
--  functions  Obs∂ : StarSpec → ObsPackage Region  and
--  ObsBulk : StarSpec → ObsPackage Region  from Bridge.StarObs.
--  Agda's scope checker treats record field declarations as names
--  at the module level, so a field named  ObsBulk  would collide
--  with the imported projection function of the same name.
--
--  The record lives in  Type₁  because it stores types as fields.
--  This is the correct universe level:  Type₀  values inhabit
--  Type₀ , but the types themselves are elements of  Type₁ .
-- ════════════════════════════════════════════════════════════════════

record BridgeWitness : Type₁ where
  field
    -- The two enriched observable types
    BdyTy              : Type₀
    BulkTy             : Type₀

    -- Canonical inhabitants (the concrete observable bundles)
    bdy-data           : BdyTy
    bulk-data          : BulkTy

    -- The exact type equivalence
    bridge             : BdyTy ≃ BulkTy

    -- Transport verification:
    --   transporting the boundary bundle along  ua bridge
    --   yields the bulk bundle
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data


-- ════════════════════════════════════════════════════════════════════
--  §2.  Specification-Agreement Bridge Witness
-- ════════════════════════════════════════════════════════════════════
--
--  At this level, observable bundles are pairs  (f , f ≡ S∂)  and
--  (f , f ≡ LB) — functions certified against their respective
--  physical specifications.  The types are genuinely different
--  (they reference definitionally distinct functions) and the
--  equivalence is nontrivial: its forward map rewires the agreement
--  witness through the discrete Ryu–Takayanagi path  star-obs-path .
--
--  This exercises  ua  meaningfully while keeping the structural
--  property witnesses external to the type.
-- ════════════════════════════════════════════════════════════════════

spec-witness : BridgeWitness
spec-witness .BridgeWitness.BdyTy              = EnrichedBdy
spec-witness .BridgeWitness.BulkTy             = EnrichedBulk
spec-witness .BridgeWitness.bdy-data           = bdy-instance
spec-witness .BridgeWitness.bulk-data          = bulk-instance
spec-witness .BridgeWitness.bridge             = enriched-equiv
spec-witness .BridgeWitness.transport-verified = enriched-transport


-- ════════════════════════════════════════════════════════════════════
--  §3.  Full Structural-Property Bridge Witness
-- ════════════════════════════════════════════════════════════════════
--
--  At this level, the boundary bundle carries a subadditivity
--  witness and the bulk bundle carries a monotonicity witness.
--  The forward map REPLACES the boundary structural property with
--  the corresponding bulk structural property, derived from
--  LB-mono  via the functional identification  star-obs-path .
--
--  This is the strongest version of the bridge: transport converts
--  not just observable functions but observable STRUCTURAL PROPERTIES
--  between boundary and bulk formulations.
-- ════════════════════════════════════════════════════════════════════

full-witness : BridgeWitness
full-witness .BridgeWitness.BdyTy              = FullBdy
full-witness .BridgeWitness.BulkTy             = FullBulk
full-witness .BridgeWitness.bdy-data           = full-bdy
full-witness .BridgeWitness.bulk-data          = full-bulk
full-witness .BridgeWitness.bridge             = full-equiv
full-witness .BridgeWitness.transport-verified = full-transport


-- ════════════════════════════════════════════════════════════════════
--  §4.  Theorem 3 — Named Statement and Proof
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM 3  (Bridge — Observable Package Equivalence).
--
--  For the 6-tile star patch of the {5,4} HaPPY code, the boundary
--  cut-entropy observable package (carrying a subadditivity witness)
--  and the bulk minimal-chain-length observable package (carrying a
--  monotonicity witness) are exactly equivalent as types.  Transport
--  along the resulting Univalence path carries the boundary bundle
--  to the bulk bundle.
--
--  In symbols:
--
--    transport (ua full-equiv) full-bdy  ≡  full-bulk
--
--  The type  Theorem3  is a proposition (it is a path type in
--  FullBulk, which is a set because all its fields are either
--  functions into ℕ — a set — or propositional proof fields).
--  Any two proofs of Theorem3 are therefore equal.
--
--  This corresponds to:
--    • Phase 3C of docs/05-roadmap.md
--    • §3.0 Theorem 3 of docs/03-architecture.md
--    • §12.3 of docs/09-happy-instance.md (nontrivial Univalence)
--    • Milestones 3–4 of §6.9 of docs/06-challenges.md
-- ════════════════════════════════════════════════════════════════════

Theorem3 : Type₀
Theorem3 = transport full-ua-path full-bdy ≡ full-bulk

theorem3 : Theorem3
theorem3 = full-transport


-- ════════════════════════════════════════════════════════════════════
--  §5.  Reverse Transport — The Bulk-to-Boundary Translator
-- ════════════════════════════════════════════════════════════════════
--
--  The Univalence path is a genuine path in the universe, and
--  transport is invertible: transporting along  sym p  reverses
--  the direction.  This gives a BIDIRECTIONAL translator:
--
--    Forward  (§4):  boundary bundle  →  bulk bundle
--    Reverse (here):  bulk bundle    →  boundary bundle
--
--  The reverse transport takes a bulk observable bundle certified
--  with a monotonicity witness and produces a boundary observable
--  bundle certified with a subadditivity witness.
--
--  The proof uses the roundtrip lemma  transport⁻Transport  from
--  Cubical.Foundations.Transport:
--
--    transport (sym p) (transport p a) ≡ a
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Specification-agreement level: bulk → boundary
-- ────────────────────────────────────────────────────────────────

reverse-enriched :
  transport (sym enriched-ua-path) bulk-instance ≡ bdy-instance
reverse-enriched =
  cong (transport (sym enriched-ua-path)) (sym enriched-transport)
  ∙ transport⁻Transport enriched-ua-path bdy-instance

-- ────────────────────────────────────────────────────────────────
--  Full structural-property level: bulk → boundary
-- ────────────────────────────────────────────────────────────────

reverse-full :
  transport (sym full-ua-path) full-bulk ≡ full-bdy
reverse-full =
  cong (transport (sym full-ua-path)) (sym full-transport)
  ∙ transport⁻Transport full-ua-path full-bdy


-- ════════════════════════════════════════════════════════════════════
--  §6.  Observable Extraction from Reverse Transport
-- ════════════════════════════════════════════════════════════════════
--
--  The reverse transport carries the bulk observable function  LB
--  back to the boundary observable function  S∂ .  This is the
--  "decompiler": given a bulk minimal-chain-length observable,
--  the reverse translator produces a boundary min-cut entropy
--  observable.
-- ════════════════════════════════════════════════════════════════════

-- The reverse-transported value is a FullBdy term.
reverse-bdy : FullBdy
reverse-bdy = transport (sym full-ua-path) full-bulk

-- Its observable function equals the boundary specification S∂.
reverse-bdy-obs : FullBdy.obs reverse-bdy ≡ S∂
reverse-bdy-obs = cong FullBdy.obs reverse-full

-- It carries a subadditivity witness (the structural property
-- survives the reverse transport).
reverse-bdy-subadd : Subadditive (FullBdy.obs reverse-bdy)
reverse-bdy-subadd = FullBdy.subadd reverse-bdy

-- Pointwise: the reverse-transported observable agrees with S∂.
reverse-bdy-pointwise :
  (r : Region) → FullBdy.obs reverse-bdy r ≡ S∂ r
reverse-bdy-pointwise r = cong (λ f → f r) reverse-bdy-obs


-- ════════════════════════════════════════════════════════════════════
--  §7.  Roundtrip Verification
-- ════════════════════════════════════════════════════════════════════
--
--  The forward and reverse transports compose to the identity in
--  both directions.  These are direct consequences of the general
--  roundtrip lemmas for transport along paths and their inverses.
--
--  In operational terms: applying the holographic translator and
--  then its inverse recovers the original observable bundle.  This
--  is the machine-checked guarantee that the bridge is lossless.
-- ════════════════════════════════════════════════════════════════════

-- Boundary → bulk → boundary = identity
roundtrip-bdy :
  transport (sym enriched-ua-path)
    (transport enriched-ua-path bdy-instance)
  ≡ bdy-instance
roundtrip-bdy = transport⁻Transport enriched-ua-path bdy-instance

-- Bulk → boundary → bulk = identity
roundtrip-bulk :
  transport enriched-ua-path
    (transport (sym enriched-ua-path) bulk-instance)
  ≡ bulk-instance
roundtrip-bulk = transportTransport⁻ enriched-ua-path bulk-instance

-- Full level: boundary → bulk → boundary = identity
roundtrip-full-bdy :
  transport (sym full-ua-path)
    (transport full-ua-path full-bdy)
  ≡ full-bdy
roundtrip-full-bdy = transport⁻Transport full-ua-path full-bdy

-- Full level: bulk → boundary → bulk = identity
roundtrip-full-bulk :
  transport full-ua-path
    (transport (sym full-ua-path) full-bulk)
  ≡ full-bulk
roundtrip-full-bulk = transportTransport⁻ full-ua-path full-bulk


-- ════════════════════════════════════════════════════════════════════
--  §8.  Three-Level Coherence
-- ════════════════════════════════════════════════════════════════════
--
--  The three levels of the bridge (trivial, spec-agreement, full)
--  are consistent:  the observable functions extracted from
--  transport at each level all agree with the bulk specification LB.
--
--  Level 1 (trivial):
--    star-obs-path : S∂ ≡ LB            (Bridge/StarEquiv.agda)
--
--  Level 2 (spec-agreement):
--    enriched-transport-obs :
--      fst (transport enriched-ua-path bdy-instance) ≡ LB
--
--  Level 3 (full structural):
--    full-transport-obs :
--      FullBulk.obs (transport full-ua-path full-bdy) ≡ LB
--
--  All three produce  LB  as the bulk-side observable.
-- ════════════════════════════════════════════════════════════════════

-- The value-level path (Level 1) agrees with the type-level
-- transport (Level 2) on the target function.
coherence-1-2 :
  ObsPackage.obs (ObsBulk starSpec) ≡ fst bulk-instance
coherence-1-2 = refl

-- The spec-agreement transport (Level 2) agrees with the full
-- transport (Level 3) on the extracted observable.
coherence-2-3 :
  fst bulk-instance ≡ FullBulk.obs full-bulk
coherence-2-3 = refl

-- Combined: all three levels produce LB.
coherence-all :
  ObsPackage.obs (ObsBulk starSpec) ≡ FullBulk.obs full-bulk
coherence-all = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Concrete Pointwise Computations
-- ════════════════════════════════════════════════════════════════════
--
--  The following lemmas demonstrate that the transported observable
--  function produces the expected numerical values at specific
--  boundary regions.  These serve as concrete regression tests for
--  the entire pipeline:
--
--    common source → extract views → build packages → construct
--    equivalence → apply ua → transport → extract observable
--
--  For singletons  {N_i} , the min-cut / chain-length is  1q = 1.
--  For adjacent pairs  {N_i, N_{i+1}} , the value is  2q = 2.
--
--  Each proof is a direct application of  full-transport-pointwise ,
--  which reduces the transported observable to  LB r ,  and then
--  LB r  computes judgmentally to  1q  or  2q .
-- ════════════════════════════════════════════════════════════════════

-- Singleton region:  transport produces the correct value  1
transport-at-N0 :
  FullBulk.obs (transport full-ua-path full-bdy) regN0 ≡ 1q
transport-at-N0 = full-transport-pointwise regN0

transport-at-N3 :
  FullBulk.obs (transport full-ua-path full-bdy) regN3 ≡ 1q
transport-at-N3 = full-transport-pointwise regN3

-- Adjacent pair region:  transport produces the correct value  2
transport-at-N0N1 :
  FullBulk.obs (transport full-ua-path full-bdy) regN0N1 ≡ 2q
transport-at-N0N1 = full-transport-pointwise regN0N1

transport-at-N2N3 :
  FullBulk.obs (transport full-ua-path full-bdy) regN2N3 ≡ 2q
transport-at-N2N3 = full-transport-pointwise regN2N3


-- ════════════════════════════════════════════════════════════════════
--  §10.  Structural Property Conversion — Concrete Witness
-- ════════════════════════════════════════════════════════════════════
--
--  The forward transport converts a subadditivity witness into a
--  monotonicity witness.  The reverse transport converts a
--  monotonicity witness into a subadditivity witness.
--
--  Here we demonstrate both directions concretely.
--
--  Forward: starting from  full-bdy  (which carries S∂-subadd),
--  transport produces a bulk bundle whose  mono  field proves
--  L(N₀) ≤ L(N₀N₁) ,  i.e.,  1 ≤ 2 .
--
--  Reverse: starting from  full-bulk  (which carries LB-mono),
--  transport produces a boundary bundle whose  subadd  field
--  proves  S(N₀N₁) ≤ S(N₀) + S(N₁) ,  i.e.,  2 ≤ 1 + 1 = 2 .
--
--  This is the type-theoretic realization of the holographic
--  principle: boundary structural properties ↔ bulk structural
--  properties, mediated by the discrete RT correspondence.
-- ════════════════════════════════════════════════════════════════════

-- Forward: subadditivity → monotonicity  (re-exported for reference)
fwd-mono-witness :
  FullBulk.obs (transport full-ua-path full-bdy) regN0
  ≤ℚ FullBulk.obs (transport full-ua-path full-bdy) regN0N1
fwd-mono-witness = transported-mono-witness

-- Reverse: monotonicity → subadditivity
--
-- The reverse-transported bundle is a  FullBdy  value whose  subadd
-- field is a valid subadditivity witness.  We apply it to the
-- singleton union  {N₀} ∪ {N₁} = {N₀,N₁}  to produce the concrete
-- inequality  2 ≤ 1 + 1 = 2 .

open import Bridge.FullEnrichedStarObs using (_∪R_≡R_ ; u-N0∪N1)

rev-subadd-witness :
  FullBdy.obs reverse-bdy regN0N1
  ≤ℚ (FullBdy.obs reverse-bdy regN0 +ℚ FullBdy.obs reverse-bdy regN1)
rev-subadd-witness =
  reverse-bdy-subadd regN0 regN1 regN0N1 u-N0∪N1


-- ════════════════════════════════════════════════════════════════════
--  §11.  Contravariant Type-Family Transport
-- ════════════════════════════════════════════════════════════════════
--
--  Phase 3C of docs/05-roadmap.md specifies defining a type family
--  Φ over the universe and computing  transport^Φ(p)(ρ∂) .
--
--  The simplest type family is  id : Type₀ → Type₀ , for which
--  transport is just ordinary transport (already demonstrated).
--
--  A more interesting family is the contravariant function type:
--
--    Ψ : Type₀ → Type₀
--    Ψ X = X → ℚ≥0
--
--  Transport along  p : A ≡ B  with family  Ψ  converts a function
--  on A to a function on B by precomposing with the inverse of the
--  transport.  Concretely, for  p = enriched-ua-path :
--
--    transport (cong Ψ p) : (EnrichedBdy → ℚ≥0) → (EnrichedBulk → ℚ≥0)
--
--  This exercises the CONTRAVARIANT computational behavior of
--  transport in function types.
-- ════════════════════════════════════════════════════════════════════

Ψ : Type₀ → Type₀
Ψ X = X → ℚ≥0

-- A sample function on the boundary type: extract the observable
-- at region regN2 from the enriched boundary bundle.
sample-fn : Ψ EnrichedBdy
sample-fn (f , _) = f regN2

-- Transport Ψ along the enriched Univalence path.
transported-fn : Ψ EnrichedBulk
transported-fn = transport (cong Ψ enriched-ua-path) sample-fn

-- Verify that the original function produces the expected value.
sample-fn-value : sample-fn bdy-instance ≡ 1q
sample-fn-value = refl


-- ════════════════════════════════════════════════════════════════════
--  §12.  Connection to Value-Level Package Path
-- ════════════════════════════════════════════════════════════════════
--
--  The value-level package path  star-package-path  (from
--  Bridge/StarEquiv.agda) and the type-level Univalence path
--  enriched-ua-path  (from Bridge/EnrichedStarObs.agda) encode the
--  SAME mathematical content: the discrete Ryu–Takayanagi
--  correspondence  S∂ ≡ LB .
--
--  The difference is architectural:
--
--    • star-package-path  is a path between VALUES of  ObsPackage Region .
--      It says the two observable packages are equal as records.
--
--    • enriched-ua-path  is a path between TYPES in  Type₀ .
--      It says the two enriched types are equal as types.
--
--    • full-ua-path  is a path between TYPES  FullBdy  and  FullBulk .
--      It identifies types that additionally carry different structural
--      properties (subadditivity vs monotonicity).
--
--  The connecting data is  star-obs-path : S∂ ≡ LB , which appears
--  as the obs-field component of  star-package-path , as the
--  rewiring step in  enriched-equiv , and as the link between
--  specification-agreement fields in  full-equiv .
-- ════════════════════════════════════════════════════════════════════

-- The package-path obs field at  i1  agrees with the enriched
-- transport obs extraction.
package-path-coherence :
  ObsPackage.obs (star-package-path i1) ≡ fst bulk-instance
package-path-coherence = refl


-- ════════════════════════════════════════════════════════════════════
--  §13.  End-to-End Pipeline Summary
-- ════════════════════════════════════════════════════════════════════
--
--  The complete Phase 3 pipeline for the 6-tile star, at the full
--  structural-property level:
--
--    ┌──────────────────────────────────────────────────────────┐
--    │  BOUNDARY SIDE                                          │
--    │                                                         │
--    │  starSpec  →  π∂  →  S-cut  →  S∂                       │
--    │                                  │                      │
--    │                                  ├── S∂-subadd          │
--    │                                  │     (Boundary/       │
--    │                                  │      StarSubadd.)    │
--    │                                  │                      │
--    │                          full-bdy : FullBdy             │
--    │                          (S∂, refl, S∂-subadd)          │
--    └──────────────┬───────────────────────────────────────────┘
--                   │
--                   │   star-obs-path : S∂ ≡ LB
--                   │   (Bridge/StarEquiv.agda)
--                   │
--                   │   full-equiv : FullBdy ≃ FullBulk
--                   │   full-ua-path : FullBdy ≡ FullBulk
--                   │   (Bridge/FullEnrichedStarObs.agda)
--                   │
--                   │   theorem3 :
--                   │     transport full-ua-path full-bdy ≡ full-bulk
--                   │   (this module, §4)
--                   │
--                   │   reverse-full :
--                   │     transport (sym full-ua-path) full-bulk ≡ full-bdy
--                   │   (this module, §5)
--                   │
--    ┌──────────────┴───────────────────────────────────────────┐
--    │  BULK SIDE                                              │
--    │                                                         │
--    │  starSpec  →  πbulk  →  L-min  →  LB                    │
--    │                                    │                    │
--    │                                    ├── LB-mono          │
--    │                                    │     (Bulk/         │
--    │                                    │      StarMono.)    │
--    │                                    │                    │
--    │                          full-bulk : FullBulk            │
--    │                          (LB, refl, LB-mono)            │
--    └──────────────────────────────────────────────────────────┘
--
--  Every step is machine-checked by the Cubical Agda type-checker.
--  Transport is computable: it reduces via  uaβ  to the forward map
--  of the equivalence.  The roundtrip lemmas (§7) guarantee that the
--  translation is lossless in both directions.
--
--  Exit criterion (docs/05-roadmap.md, Phase 3C):
--    "The transport computes on the chosen observable package and
--     produces the correct bulk observable bundle.  This satisfies
--     Milestones 3 and 4 of §6.9."
--
--  Satisfied by:
--    • theorem3        : forward transport is correct
--    • reverse-full    : reverse transport is correct
--    • full-witness    : milestone record packaging
--    • transport-at-*  : pointwise numerical verification
--    • fwd-mono-witness / rev-subadd-witness :
--        structural property conversion in both directions
-- ════════════════════════════════════════════════════════════════════