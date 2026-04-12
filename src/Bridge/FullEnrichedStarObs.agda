{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.FullEnrichedStarObs where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.HLevels

open import Cubical.Data.Nat
  using (ℕ ; zero ; suc ; _+_ ; injSuc)
open import Cubical.Data.Nat.Properties
  using (isSetℕ ; +-comm)
open import Cubical.Data.Sigma
  using (ΣPathP)

open import Util.Scalars
open import Common.StarSpec
open import Boundary.StarCut
open import Bulk.StarChain
open import Bridge.StarObs   using (star-pointwise)
open import Bridge.StarEquiv using (star-obs-path)
open import Bridge.EnrichedStarObs
  using ( S∂ ; LB ; isSetObs
        ; enriched-equiv ; enriched-ua-path
        ; bdy-instance ; bulk-instance
        ; EnrichedBdy ; EnrichedBulk )
open import Bulk.StarMonotonicity
  using (_⊆R_ ; monotonicity)


-- ════════════════════════════════════════════════════════════════════
--  §1.  ℕ cancellation and  isProp≤ℚ
-- ════════════════════════════════════════════════════════════════════
--
--  The ordering  m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)  from
--  Util/Scalars.agda is a proposition: any two witnesses (k₁, p₁)
--  and (k₂, p₂) are equal.  The first components agree by ℕ
--  right-cancellation, and the second components agree because ℕ
--  is a set.
--
--  This is the foundational h-level lemma that makes both
--  Subadditive and Monotone propositional, enabling the round-trip
--  homotopies in the full enriched equivalence.
--
--  Reference:
--    docs/formal/02-foundations.md §1  (h-levels and truncation)
--    docs/formal/03-holographic-bridge.md §4  (full enriched equiv)
--    docs/engineering/abstract-barrier.md §3  (why propositionality
--                                              makes abstract safe)
-- ════════════════════════════════════════════════════════════════════

private
  -- Left cancellation:  m + k₁ ≡ m + k₂  →  k₁ ≡ k₂
  -- By induction on m, using  injSuc : suc a ≡ suc b → a ≡ b .
  +-cancelˡ : (m : ℕ) {k₁ k₂ : ℕ} → m + k₁ ≡ m + k₂ → k₁ ≡ k₂
  +-cancelˡ zero    p = p
  +-cancelˡ (suc m) p = +-cancelˡ m (injSuc p)

  -- Right cancellation:  k₁ + m ≡ k₂ + m  →  k₁ ≡ k₂
  -- Via commutativity:  k + m ≡ m + k  by  +-comm .
  +-cancelʳ : (m : ℕ) {k₁ k₂ : ℕ} → k₁ + m ≡ k₂ + m → k₁ ≡ k₂
  +-cancelʳ m {k₁} {k₂} p =
    +-cancelˡ m (+-comm m k₁ ∙ p ∙ sym (+-comm m k₂))

-- The ordering  m ≤ℚ n  is propositional.
--
-- Given  (k₁ , p₁) (k₂ , p₂) : m ≤ℚ n :
--   • k₁ ≡ k₂    by right-cancellation from  p₁ ∙ sym p₂ : k₁+m ≡ k₂+m
--   • PathP for the proofs    by isSetℕ  (ℕ is a set)
--
-- This uses  ΣPathP  from Cubical.Data.Sigma to package the two
-- component paths into a path between Sigma pairs.

isProp≤ℚ : ∀ {m n : ℚ≥0} → isProp (m ≤ℚ n)
isProp≤ℚ {m} {n} (k₁ , p₁) (k₂ , p₂) =
  ΣPathP (k≡ , isProp→PathP (λ i → isSetℕ (k≡ i + m) n) p₁ p₂)
  where
    k≡ : k₁ ≡ k₂
    k≡ = +-cancelʳ m (p₁ ∙ sym p₂)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Restricted union relation on Region (10-region type)
-- ════════════════════════════════════════════════════════════════════
--
--  The full 20-region union relation  _∪_≡_  from
--  Boundary/StarSubadditivity.agda covers 30 union triples on the
--  StarRegion type.  Here we define a restriction to the 10-region
--  representative type  Region  from Common/StarSpec.agda.
--
--  Only the 5 singleton-union-to-pair cases stay within the
--  representative type:
--
--    {N_i} ∪ {N_{i+1}}  =  {N_i, N_{i+1}}    for i = 0..4 (mod 5)
--
--  This is sufficient to demonstrate that subadditivity is a
--  well-defined structural property of functions  Region → ℚ≥0 .
--  The restriction to 5 cases (rather than 30) is not a loss of
--  mathematical content: the full subadditivity on the 20-region
--  type is already proven in Boundary/StarSubadditivity.agda.  The
--  restriction here serves only to stay within the  Region  type
--  used by the enriched types in EnrichedStarObs.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 8  (subadditivity & monotonicity)
--    docs/instances/star-patch.md §5     (structural properties)
-- ════════════════════════════════════════════════════════════════════

data _∪R_≡R_ : Region → Region → Region → Type₀ where
  u-N0∪N1 : regN0 ∪R regN1 ≡R regN0N1
  u-N1∪N2 : regN1 ∪R regN2 ≡R regN1N2
  u-N2∪N3 : regN2 ∪R regN3 ≡R regN2N3
  u-N3∪N4 : regN3 ∪R regN4 ≡R regN3N4
  u-N4∪N0 : regN4 ∪R regN0 ≡R regN4N0


-- ════════════════════════════════════════════════════════════════════
--  §3.  Structural property types
-- ════════════════════════════════════════════════════════════════════
--
--  Subadditive f  asserts that for every representable union
--  r₁ ∪ r₂ = r₃ within the 10-region type:
--
--      f(r₃) ≤ f(r₁) + f(r₂)
--
--  Monotone f  asserts that for every subregion inclusion
--  r₁ ⊆ r₂ within the 10-region type:
--
--      f(r₁) ≤ f(r₂)
--
--  Both use explicit (not implicit) quantifiers so that  isPropΠ
--  applies directly without the need for  implicitFunExt .
--
--  In the physical interpretation:
--    • Subadditivity is the boundary property: the entanglement
--      entropy of a composite region is bounded by the sum of the
--      entropies of its parts.
--    • Monotonicity is the bulk property: a larger boundary region
--      is separated by a longer (or equal) minimal chain.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §4.1  (enriched record types)
--    docs/physics/holographic-dictionary.md §7   (thermodynamics)
-- ════════════════════════════════════════════════════════════════════

Subadditive : (Region → ℚ≥0) → Type₀
Subadditive f =
  (r₁ r₂ r₃ : Region) → r₁ ∪R r₂ ≡R r₃ → f r₃ ≤ℚ (f r₁ +ℚ f r₂)

Monotone : (Region → ℚ≥0) → Type₀
Monotone f =
  (r₁ r₂ : Region) → r₁ ⊆R r₂ → f r₁ ≤ℚ f r₂


-- ════════════════════════════════════════════════════════════════════
--  §4.  S∂ is subadditive,  LB is monotone
-- ════════════════════════════════════════════════════════════════════
--
--  S∂-subadd:  all 5 cases reduce to  2 ≤ 1 + 1 = 2 ,  witnessed
--  by  (0 , refl)  because  0 + 2 ≡ 2  judgmentally.
--
--  LB-mono:  re-exports the monotonicity proof from
--  Bulk/StarMonotonicity.agda, adapting from implicit to explicit
--  region arguments.  All 10 cases reduce to  1 ≤ 2 ,  witnessed
--  by  (1 , refl)  because  1 + 1 ≡ 2  judgmentally.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 8  (theorem registry entry)
--    docs/instances/star-patch.md §5     (structural properties)
-- ════════════════════════════════════════════════════════════════════

S∂-subadd : Subadditive S∂
S∂-subadd _ _ _ u-N0∪N1 = 0 , refl     -- 2 ≤ 1 + 1 = 2
S∂-subadd _ _ _ u-N1∪N2 = 0 , refl
S∂-subadd _ _ _ u-N2∪N3 = 0 , refl
S∂-subadd _ _ _ u-N3∪N4 = 0 , refl
S∂-subadd _ _ _ u-N4∪N0 = 0 , refl

LB-mono : Monotone LB
LB-mono _ _ inc = monotonicity inc


-- ════════════════════════════════════════════════════════════════════
--  §5.  Propositionality of structural properties
-- ════════════════════════════════════════════════════════════════════
--
--  Both  Subadditive f  and  Monotone f  are propositions because
--  they are nested Π-types ending in  _≤ℚ_ , which is propositional
--  by  isProp≤ℚ .
--
--  This is the key h-level fact enabling the round-trip homotopies
--  in the full enriched equivalence: since the structural-property
--  fields are propositional, any two inhabitants are equal, and we
--  don't need to track how the properties are transported — only
--  that SOME inhabitant exists on each side.
--
--  Reference:
--    docs/formal/02-foundations.md §1  (h-levels: propositions)
--    docs/formal/03-holographic-bridge.md §4.2  (derivation, not
--                                                preservation)
--    docs/engineering/abstract-barrier.md §3    (propositionality
--                                                makes abstract safe)
-- ════════════════════════════════════════════════════════════════════

isPropSubadditive : (f : Region → ℚ≥0) → isProp (Subadditive f)
isPropSubadditive f =
  isPropΠ λ _ → isPropΠ λ _ → isPropΠ λ _ → isPropΠ λ _ → isProp≤ℚ

isPropMonotone : (f : Region → ℚ≥0) → isProp (Monotone f)
isPropMonotone f =
  isPropΠ λ _ → isPropΠ λ _ → isPropΠ λ _ → isProp≤ℚ


-- ════════════════════════════════════════════════════════════════════
--  §6.  Full enriched record types
-- ════════════════════════════════════════════════════════════════════
--
--  FullBdy  bundles an observable function with:
--    (1) a certification that it agrees with the boundary spec  S∂
--    (2) a subadditivity witness
--
--  FullBulk  bundles an observable function with:
--    (1) a certification that it agrees with the bulk spec  LB
--    (2) a monotonicity witness
--
--  These are the "full record types with explicit subadd/mono
--  fields" envisioned in §13 of Bridge/EnrichedStarObs.agda.
--
--  Both types are contractible: the spec field pins  obs  to a
--  unique function (S∂ or LB), and the structural-property field
--  is propositional and inhabited (by S∂-subadd or LB-mono).
--  But they are genuinely different types in the universe because
--  they reference different specification functions and different
--  structural properties.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §4.1  (enriched record types)
--    docs/formal/01-theorems.md §Thm 8          (theorem registry)
--    docs/instances/star-patch.md §6.2           (enriched bridge)
-- ════════════════════════════════════════════════════════════════════

record FullBdy : Type₀ where
  field
    obs    : Region → ℚ≥0
    spec   : obs ≡ S∂
    subadd : Subadditive obs

record FullBulk : Type₀ where
  field
    obs  : Region → ℚ≥0
    spec : obs ≡ LB
    mono : Monotone obs


-- ════════════════════════════════════════════════════════════════════
--  §7.  Canonical inhabitants
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary instance carries  S∂  with  refl  and the proven
--  subadditivity.  The bulk instance carries  LB  with  refl  and
--  the proven monotonicity.  These are the concrete observable
--  bundles that transport will convert between.
-- ════════════════════════════════════════════════════════════════════

full-bdy : FullBdy
full-bdy .FullBdy.obs    = S∂
full-bdy .FullBdy.spec   = refl
full-bdy .FullBdy.subadd = S∂-subadd

full-bulk : FullBulk
full-bulk .FullBulk.obs  = LB
full-bulk .FullBulk.spec = refl
full-bulk .FullBulk.mono = LB-mono


-- ════════════════════════════════════════════════════════════════════
--  §8.  Derivation lemmas
-- ════════════════════════════════════════════════════════════════════
--
--  The structural properties are NOT independent data: they are
--  determined by the specification-agreement field plus the
--  externally proven properties of S∂ and LB.
--
--  derive-subadd:  given  f ≡ S∂ , transport S∂'s subadditivity
--  along  sym p  to obtain subadditivity of  f .
--
--  derive-mono:  given  f ≡ LB , transport LB's monotonicity
--  along  sym q  to obtain monotonicity of  f .
--
--  These are the arrows in the transport diagram:
--
--    subadd-S∂ ──[subst Subadditive (sym p)]──▶ subadd-f
--    mono-LB   ──[subst Monotone   (sym q)]──▶ mono-f
--
--  Reference:
--    docs/formal/02-foundations.md §3.1  (subst)
--    docs/formal/03-holographic-bridge.md §4.2  (derivation, not
--                                                preservation)
-- ════════════════════════════════════════════════════════════════════

derive-subadd : (f : Region → ℚ≥0) → f ≡ S∂ → Subadditive f
derive-subadd f p = subst Subadditive (sym p) S∂-subadd

derive-mono : (f : Region → ℚ≥0) → f ≡ LB → Monotone f
derive-mono f q = subst Monotone (sym q) LB-mono


-- ════════════════════════════════════════════════════════════════════
--  §9.  The Iso between full types
-- ════════════════════════════════════════════════════════════════════
--
--  The forward map is the "holographic translator": it takes a
--  function certified against the boundary specification (with
--  subadditivity) and recertifies it against the bulk specification
--  (with monotonicity), using  star-obs-path  as the bridge.
--
--  Concretely, the forward map:
--    (1) keeps the observable function  f  unchanged
--    (2) extends the spec from  f ≡ S∂  to  f ≡ LB  by appending
--        star-obs-path  (the discrete Ryu–Takayanagi path)
--    (3) DISCARDS the subadditivity witness and DERIVES monotonicity
--        from the new spec and  LB-mono
--
--  This is the key insight: the structural property is not directly
--  "converted" — it is replaced.  The boundary property is no
--  longer relevant once  f  is recertified against the bulk spec;
--  the bulk property is derived afresh.
--
--  The inverse map does the symmetric operation: appends
--  sym star-obs-path  and derives subadditivity from  S∂-subadd .
--
--  Round-trip proofs:  Since  obs  is preserved by both maps, we
--  need only show that the  spec  and  subadd/mono  fields agree.
--  The  spec  fields agree because  Region → ℚ≥0  is a set
--  (isSetObs), so any two paths  f ≡ S∂  (or  f ≡ LB) are equal.
--  The structural-property fields agree because they are
--  propositional (isPropSubadditive, isPropMonotone).
--
--  Reference:
--    docs/formal/02-foundations.md §4    (equivalences and Iso)
--    docs/formal/03-holographic-bridge.md §4.2  (derivation, not
--                                                preservation)
-- ════════════════════════════════════════════════════════════════════

full-iso : Iso FullBdy FullBulk
full-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : FullBdy → FullBulk
    fwd a = record
      { obs  = FullBdy.obs a
      ; spec = FullBdy.spec a ∙ star-obs-path
      ; mono = derive-mono (FullBdy.obs a) (FullBdy.spec a ∙ star-obs-path)
      }

    bwd : FullBulk → FullBdy
    bwd b = record
      { obs    = FullBulk.obs b
      ; spec   = FullBulk.spec b ∙ sym star-obs-path
      ; subadd = derive-subadd (FullBulk.obs b)
                   (FullBulk.spec b ∙ sym star-obs-path)
      }

    fwd-bwd : (b : FullBulk) → fwd (bwd b) ≡ b
    fwd-bwd b i = record
      { obs  = FullBulk.obs b
      ; spec = isSetObs (FullBulk.obs b) LB
                 ((FullBulk.spec b ∙ sym star-obs-path) ∙ star-obs-path)
                 (FullBulk.spec b) i
      ; mono = isPropMonotone (FullBulk.obs b)
                 (derive-mono (FullBulk.obs b)
                   ((FullBulk.spec b ∙ sym star-obs-path) ∙ star-obs-path))
                 (FullBulk.mono b) i
      }

    bwd-fwd : (a : FullBdy) → bwd (fwd a) ≡ a
    bwd-fwd a i = record
      { obs    = FullBdy.obs a
      ; spec   = isSetObs (FullBdy.obs a) S∂
                   ((FullBdy.spec a ∙ star-obs-path) ∙ sym star-obs-path)
                   (FullBdy.spec a) i
      ; subadd = isPropSubadditive (FullBdy.obs a)
                   (derive-subadd (FullBdy.obs a)
                     ((FullBdy.spec a ∙ star-obs-path) ∙ sym star-obs-path))
                   (FullBdy.subadd a) i
      }


-- ════════════════════════════════════════════════════════════════════
--  §10.  The equivalence and Univalence path
-- ════════════════════════════════════════════════════════════════════
--
--  Promoting the Iso to a full coherent equivalence (with
--  contractible fibers) and applying  ua  to obtain the path
--  between  FullBdy  and  FullBulk  in the universe  Type₀ .
--
--  This path is nontrivial: the two types reference different
--  specification functions (S∂ vs LB) and different structural
--  properties (Subadditive vs Monotone).  The path threads through
--  star-obs-path  via the Glue type.
--
--  Reference:
--    docs/formal/02-foundations.md §5  (the Univalence axiom)
--    docs/formal/03-holographic-bridge.md §3.3  (Univalence application)
-- ════════════════════════════════════════════════════════════════════

full-equiv : FullBdy ≃ FullBulk
full-equiv = isoToEquiv full-iso

full-ua-path : FullBdy ≡ FullBulk
full-ua-path = ua full-equiv


-- ════════════════════════════════════════════════════════════════════
--  §11.  Transport: the verified translator
-- ════════════════════════════════════════════════════════════════════
--
--  Transport along  full-ua-path  converts the boundary observable
--  bundle (with subadditivity) to the bulk observable bundle (with
--  monotonicity).
--
--  By  uaβ , transport computes as the forward map of the
--  equivalence.  The forward map:
--
--    (S∂ , refl , S∂-subadd)
--    ↦  (S∂ , refl ∙ star-obs-path , derive-mono S∂ (refl ∙ star-obs-path))
--    =  (S∂ , star-obs-path , derive-mono S∂ star-obs-path)
--
--  This is propositionally equal to  full-bulk = (LB , refl , LB-mono) :
--  the first components are identified by  star-obs-path : S∂ ≡ LB ,
--  the second components by  isSetObs , and the third components by
--  isPropMonotone .
--
--  This is the "compilation step": a computable transport that
--  converts a boundary observable bundle carrying a subadditivity
--  witness into a bulk observable bundle carrying a monotonicity
--  witness.
--
--  Reference:
--    docs/formal/02-foundations.md §5.1         (ua and uaβ — transport
--                                                computes)
--    docs/formal/03-holographic-bridge.md §4.3  (transport converts
--                                                properties)
--    docs/formal/01-theorems.md §Thm 8          (theorem registry)
-- ════════════════════════════════════════════════════════════════════

-- Step 1:  uaβ reduces transport to the forward map
transport-computes :
  transport full-ua-path full-bdy
  ≡ equivFun full-equiv full-bdy
transport-computes = uaβ full-equiv full-bdy

-- Step 2:  The forward map output equals the bulk instance
--
--  equivFun full-equiv full-bdy
--    = (S∂ , refl ∙ star-obs-path , derive-mono S∂ (refl ∙ star-obs-path))
--
--  full-bulk
--    = (LB , refl , LB-mono)
--
--  The path uses:
--    • star-obs-path       for the obs field
--    • isSetObs            for the spec field (propositional)
--    • isPropMonotone      for the mono field (propositional)
private
  fwd-eq-bulk : equivFun full-equiv full-bdy ≡ full-bulk
  fwd-eq-bulk i = record
    { obs  = star-obs-path i
    ; spec = isProp→PathP
               (λ j → isSetObs (star-obs-path j) LB)
               (refl ∙ star-obs-path)
               refl i
    ; mono = isProp→PathP
               (λ j → isPropMonotone (star-obs-path j))
               (derive-mono S∂ (refl ∙ star-obs-path))
               LB-mono i
    }

-- Combined: transport produces the bulk instance
full-transport :
  transport full-ua-path full-bdy ≡ full-bulk
full-transport = transport-computes ∙ fwd-eq-bulk


-- ════════════════════════════════════════════════════════════════════
--  §12.  Observable function extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The primary computational artifact: the observable function
--  extracted from the transported boundary bundle equals  LB .
--
--  In operational terms: given a boundary observable function S∂
--  bundled with a subadditivity witness, transport produces a
--  function bundled with a monotonicity witness — and that function
--  is exactly the bulk minimal-chain-length functional LB.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §4.3  (transport converts
--                                                properties)
-- ════════════════════════════════════════════════════════════════════

full-transport-obs :
  FullBulk.obs (transport full-ua-path full-bdy) ≡ LB
full-transport-obs = cong FullBulk.obs full-transport


-- ════════════════════════════════════════════════════════════════════
--  §13.  The structural property is converted
-- ════════════════════════════════════════════════════════════════════
--
--  The mono field of the transported bundle is a valid monotonicity
--  witness for the transported observable.  This is the core claim
--  of §13 of EnrichedStarObs:  transport converts a subadditivity
--  witness into a monotonicity witness.
--
--  More precisely:  the input  full-bdy  carries
--    subadd : Subadditive S∂
--  and the output  transport full-ua-path full-bdy  carries
--    mono : Monotone (FullBulk.obs (transport full-ua-path full-bdy))
--  which is propositionally equal to
--    LB-mono : Monotone LB
--
--  The subadditivity witness is not "directly mapped" to a
--  monotonicity witness — it is REPLACED by a freshly derived
--  monotonicity witness, mediated by the functional identification
--  star-obs-path.  This replacement is the type-theoretic content
--  of the holographic duality: boundary structural properties
--  become bulk structural properties through the bridge.
--
--  Reference:
--    docs/formal/03-holographic-bridge.md §4.2  (derivation, not
--                                                preservation)
--    docs/formal/03-holographic-bridge.md §4.3  (transport converts
--                                                properties)
-- ════════════════════════════════════════════════════════════════════

full-transport-mono :
  PathP (λ i → Monotone (FullBulk.obs (full-transport i)))
        (FullBulk.mono (transport full-ua-path full-bdy))
        LB-mono
full-transport-mono = cong FullBulk.mono full-transport


-- ════════════════════════════════════════════════════════════════════
--  §14.  Pointwise extraction
-- ════════════════════════════════════════════════════════════════════
--
--  The transport result holds pointwise: for every admissible
--  boundary region, the transported observable agrees with LB.
-- ════════════════════════════════════════════════════════════════════

full-transport-pointwise :
  (r : Region) →
  FullBulk.obs (transport full-ua-path full-bdy) r ≡ LB r
full-transport-pointwise r = cong (λ f → f r) full-transport-obs


-- ════════════════════════════════════════════════════════════════════
--  §15.  Concrete monotonicity witness from transport
-- ════════════════════════════════════════════════════════════════════
--
--  As a concrete demonstration: transport produces a monotonicity
--  witness that can be applied to a specific subregion inclusion.
--
--  Starting from  full-bdy  (which carries subadditivity but NOT
--  monotonicity), transport yields a bulk bundle whose  mono  field
--  can prove  L(N₀) ≤ L(N₀N₁) , i.e.,  1 ≤ 2 .
--
--  This is the "compilation step" made fully explicit: the
--  subadditivity of boundary entanglement entropy, when transported
--  through the holographic correspondence, produces a monotonicity
--  witness for bulk geodesic length.
-- ════════════════════════════════════════════════════════════════════

transported-mono-witness :
  FullBulk.obs (transport full-ua-path full-bdy) regN0
  ≤ℚ FullBulk.obs (transport full-ua-path full-bdy) regN0N1
transported-mono-witness =
  FullBulk.mono (transport full-ua-path full-bdy) regN0 regN0N1 sub-N0∈N0N1
  where open Bulk.StarMonotonicity using (sub-N0∈N0N1)


-- ════════════════════════════════════════════════════════════════════
--  §16.  End-to-end pipeline summary
-- ════════════════════════════════════════════════════════════════════
--
--  The complete pipeline for the 6-tile star, with full structural
--  property conversion:
--
--    starSpec                                    (Common/StarSpec)
--      │
--      ├── π∂ ──▶ S-cut ──▶ S∂                  (Boundary/StarCut)
--      │                     │
--      │                     ├── S∂-subadd       (this module, §4)
--      │                     │
--      └── πbulk ──▶ L-min ──▶ LB               (Bulk/StarChain)
--                              │
--                              ├── LB-mono       (Bulk/StarMonotonicity)
--                              │
--    star-pointwise : S∂ r ≡ LB r  ∀ r           (Bridge/StarObs)
--             │
--    star-obs-path : S∂ ≡ LB                     (Bridge/StarEquiv)
--             │
--    full-equiv : FullBdy ≃ FullBulk             (this module, §10)
--             │
--    full-ua-path : FullBdy ≡ FullBulk           (this module, §10)
--             │
--    full-transport :                            (this module, §11)
--      transport full-ua-path full-bdy ≡ full-bulk
--             │
--    full-transport-obs :                        (this module, §12)
--      obs (transport ... full-bdy) ≡ LB
--             │
--    full-transport-mono :                       (this module, §13)
--      mono (transport ... full-bdy) ≡ LB-mono   (over PathP)
--
--  The subadditivity witness in  full-bdy  is consumed by the
--  forward map of the equivalence and replaced by a monotonicity
--  witness derived from  LB-mono  via  star-obs-path .  This is
--  the type-theoretic realization of the holographic principle:
--  boundary structural properties (subadditivity of entanglement
--  entropy) are not preserved verbatim but are replaced by the
--  corresponding bulk structural properties (monotonicity of
--  geodesic length), mediated by the discrete Ryu–Takayanagi
--  correspondence.
--
--  This module completes the future work outlined in §13 of
--  Bridge/EnrichedStarObs.agda and strengthens the enriched
--  bridge result: not only does transport carry boundary
--  observables to bulk observables, it carries boundary
--  STRUCTURAL PROPERTIES to bulk STRUCTURAL PROPERTIES.
--
--  Architectural role:
--    This is a Tier 3 (Bridge Layer) module.  It is the hand-written
--    enriched bridge for the 6-tile star patch carrying full
--    structural-property conversion.  It is consumed by:
--      • Bridge/EnrichedStarEquiv.agda  (Theorem3 alias)
--      • Bridge/EnrichedStarStepInvariance.agda  (parameterized version)
--    The generic bridge (Bridge/GenericBridge.agda) subsumes the
--    specification-agreement equivalence but NOT the structural-
--    property conversion, which is specific to this module.
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 8          (theorem registry)
--    docs/formal/03-holographic-bridge.md §4    (full enriched equiv)
--    docs/formal/02-foundations.md §5           (Univalence and transport)
--    docs/instances/star-patch.md §5–§6         (structural properties
--                                                 and bridge construction)
--    docs/getting-started/architecture.md       (Bridge Layer)
--    docs/reference/module-index.md             (module description)
-- ════════════════════════════════════════════════════════════════════