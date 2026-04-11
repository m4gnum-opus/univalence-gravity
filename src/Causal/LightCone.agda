{-# OPTIONS --cubical --safe --guardedness #-}

module Causal.LightCone where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; zero ; suc ; _+_)
open import Cubical.Data.Empty using (⊥)
open import Cubical.Data.Sigma using (Σ-syntax ; _×_)

open import Causal.Event
open import Causal.NoCTC using (<ℕ-irrefl ; chain-step-<)


-- ════════════════════════════════════════════════════════════════════
--  §1.  FutureCone — Events reachable from a given event
-- ════════════════════════════════════════════════════════════════════
--
--  Given an event  e = (n, c) , its future light cone is:
--
--    J⁺(e) = { (m, c') | m ≥ n, ∃ causal chain from (n,c) to (m,c') }
--
--  In the tower,  J⁺(e)  contains all events at time  m ≥ n  whose
--  spatial cell is "reachable" from  c  through the BFS expansion.
--  Two events at the same time that are NOT in each other's light
--  cones are spacelike separated — they cannot influence each other.
--
--  The light cone is a subposet of the causal diamond, computable
--  by forward BFS from  e  through the causal links.
--
--  A  FutureCone CellAt Adj e  element packages a target event
--  together with a causal chain (a composable sequence of
--  CausalLinks) connecting  e  to that target.  The chain includes
--  the zero-length case  done e  (reflexivity: every event is in
--  its own future light cone, corresponding to  m ≥ n  when  m = n).
--
--  Reference:
--    docs/10-frontier.md §12.8  (The Discrete Light Cone)
--    docs/10-frontier.md §12.11 (New Module Plan)
--    docs/10-frontier.md §12.13 (Exit Criterion, item 4 — stretch)
-- ════════════════════════════════════════════════════════════════════

record FutureCone
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  (e      : Event CellAt)
  : Type₀ where
  field
    target : Event CellAt
    chain  : CausalChain CellAt Adj e target


-- ════════════════════════════════════════════════════════════════════
--  §2.  Self-inclusion — Every event is in its own future cone
-- ════════════════════════════════════════════════════════════════════
--
--  The reflexive case:  J⁺(e)  contains  e  itself, via the
--  zero-length chain  done e .  This corresponds to  m ≥ n  when
--  m = n  in the definition of  J⁺(e) .
-- ════════════════════════════════════════════════════════════════════

self-in-cone :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  → (e : Event CellAt)
  → FutureCone CellAt Adj e
self-in-cone e .FutureCone.target = e
self-in-cone e .FutureCone.chain  = done e


-- ════════════════════════════════════════════════════════════════════
--  §3.  Cone extension — One causal step extends the light cone
-- ════════════════════════════════════════════════════════════════════
--
--  If  e₂  is in  J⁺(e₁)  (witnessed by a FutureCone element)
--  and there is a CausalLink from  e₂  to  e₃ , then  e₃ ∈ J⁺(e₁) .
--
--  This is the transitivity of causal reachability: the new chain
--  is the old chain extended by one step.
-- ════════════════════════════════════════════════════════════════════

extend-cone :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e : Event CellAt}
  → (fc : FutureCone CellAt Adj e)
  → {e' : Event CellAt}
  → CausalLink CellAt Adj (FutureCone.target fc) e'
  → FutureCone CellAt Adj e
extend-cone fc {e'} link .FutureCone.target = e'
extend-cone fc       link .FutureCone.chain  =
  step (FutureCone.chain fc) link


-- ════════════════════════════════════════════════════════════════════
--  §4.  CausallyRelated — Positive-length causal chain
-- ════════════════════════════════════════════════════════════════════
--
--  Two events are causally related if there exists a causal chain
--  of positive length (at least one CausalLink) connecting them.
--
--  This is decomposed as: there exists an intermediate event  e'
--  with a CausalChain from  e₁  to  e'  and a CausalLink from
--  e'  to  e₂ .  This decomposition matches the pattern consumed
--  by  chain-step-<  (from Causal/NoCTC.agda), which extracts the
--  strict time ordering  time e₁ <ℕ time e₂  from exactly this
--  data.
--
--  The zero-length case  done  is excluded: CausallyRelated
--  requires at least one step.  This matters for spacelike
--  separation: an event is trivially in its own FutureCone
--  (via  done), but it is NOT causally related to itself
--  (no positive-length self-loop, by the no-CTC theorem).
-- ════════════════════════════════════════════════════════════════════

CausallyRelated :
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  → Event CellAt → Event CellAt → Type₀
CausallyRelated CellAt Adj e₁ e₂ =
  Σ[ e' ∈ Event CellAt ]
    (CausalChain CellAt Adj e₁ e' × CausalLink CellAt Adj e' e₂)


-- ════════════════════════════════════════════════════════════════════
--  §5.  Causal relatedness implies strict time ordering
-- ════════════════════════════════════════════════════════════════════
--
--  If  e₁  is causally related to  e₂  (positive-length chain),
--  then  time e₁ <ℕ time e₂ .
--
--  The proof delegates to  chain-step-<  from Causal/NoCTC.agda,
--  which establishes the strict ordering from the chain + link
--  decomposition.
--
--  This is the type-theoretic content of the physical statement:
--  "causally related events are timelike-separated."
-- ════════════════════════════════════════════════════════════════════

related→time-< :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂  : Event CellAt}
  → CausallyRelated CellAt Adj e₁ e₂
  → Event.time e₁ <ℕ Event.time e₂
related→time-< (e' , ch , link) = chain-step-< ch link


-- ════════════════════════════════════════════════════════════════════
--  §6.  Spacelike Separation
-- ════════════════════════════════════════════════════════════════════
--
--  Two events are spacelike-separated if there is no positive-length
--  causal chain connecting them in EITHER direction.  That is:
--
--    • e₁ is NOT causally related to e₂   (no forward chain)
--    • e₂ is NOT causally related to e₁   (no backward chain)
--
--  In the physics interpretation: spacelike-separated events cannot
--  influence each other.  They exist "at the same moment" in some
--  foliation of the causal poset — they are incomparable in the
--  partial order.
--
--  For a time-stratified causal poset (the SchematicTower), events
--  at the same time index are AUTOMATICALLY spacelike-separated
--  (proven below in §8).  This is because every CausalLink strictly
--  increases the time index, so there can be no positive-length
--  chain between same-time events.
--
--  Reference:
--    docs/10-frontier.md §12.8 :  "Two events at the same time
--    that are not in each other's light cones are spacelike
--    separated — they cannot influence each other."
--    docs/10-frontier.md §12.9 :  "Spacelike = incomparable in
--    the poset."
-- ════════════════════════════════════════════════════════════════════

Spacelike :
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  → Event CellAt → Event CellAt → Type₀
Spacelike CellAt Adj e₁ e₂ =
    (CausallyRelated CellAt Adj e₁ e₂ → ⊥)
  × (CausallyRelated CellAt Adj e₂ e₁ → ⊥)


-- ════════════════════════════════════════════════════════════════════
--  §7.  Same-time events cannot be causally related
-- ════════════════════════════════════════════════════════════════════
--
--  If  time e₁ ≡ time e₂ , then there is no positive-length causal
--  chain from  e₁  to  e₂ .
--
--  Proof:
--    1. A positive-length chain from  e₁  to  e₂  implies
--       time e₁ <ℕ time e₂   (by  related→time-< / chain-step-<).
--    2. Substituting  time e₂ = time e₁  (via  sym p ) converts
--       this to  time e₁ <ℕ time e₁ .
--    3. This contradicts  <ℕ-irrefl  (from Causal/NoCTC.agda).
--
--  This lemma is the bridge between the no-CTC theorem (which
--  prevents self-loops) and spacelike separation (which prevents
--  same-time causal connections).
-- ════════════════════════════════════════════════════════════════════

same-time→¬related :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂  : Event CellAt}
  → Event.time e₁ ≡ Event.time e₂
  → CausallyRelated CellAt Adj e₁ e₂ → ⊥
same-time→¬related {e₁ = e₁} p rel =
  <ℕ-irrefl (Event.time e₁)
    (subst (Event.time e₁ <ℕ_) (sym p) (related→time-< rel))


-- ════════════════════════════════════════════════════════════════════
--  §8.  Same-time events are spacelike-separated
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Spacelike Separation of Same-Time Events).
--
--  For any cell family  CellAt  and adjacency relation  Adj , if
--  two events have the same time index, they are spacelike-separated.
--
--  Proof:
--    The forward direction uses  same-time→¬related  with  p .
--    The backward direction uses  same-time→¬related  with  sym p .
--
--  This is the deepest structural result of the stratified causal
--  architecture: the type system not only prevents time travel
--  (no-CTC, from NoCTC.agda) but also enforces the causal structure
--  of spacetime — events at the same time are automatically
--  spacelike-separated, without any additional axiom.
--
--  In the physics interpretation: spatial simultaneity implies
--  causal independence.  This is the discrete analogue of the
--  statement that the causal poset restricted to a single time
--  slice is an ANTICHAIN (a set of pairwise incomparable elements).
--
--  The theorem is fully parametric: it works for ANY cell family
--  and ANY adjacency relation.  It does not depend on the specific
--  structure of the {5,4} tiling, the Dense-100 patch, or any
--  other concrete instance.
--
--  Reference:
--    docs/10-frontier.md §12.8   (spacelike separation definition)
--    docs/10-frontier.md §12.13  (Exit Criterion, item 4 — stretch)
-- ════════════════════════════════════════════════════════════════════

same-time-spacelike :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂  : Event CellAt}
  → Event.time e₁ ≡ Event.time e₂
  → Spacelike CellAt Adj e₁ e₂
same-time-spacelike p =
  same-time→¬related p , same-time→¬related (sym p)


-- ════════════════════════════════════════════════════════════════════
--  §9.  Concrete instantiation — Trivial cell family
-- ════════════════════════════════════════════════════════════════════
--
--  These regression tests verify FutureCone and spacelike-separation
--  on a trivial cell family (ℕ at all times) with a trivially-
--  satisfied adjacency relation.  This satisfies the stretch goal
--  of exit criterion §12.13 item 4:
--
--    "(Stretch) FutureCone and spacelike-separation are defined
--     and instantiated for at least one concrete event."
--
--  A genuine instantiation for the {5,4} tower diamond would
--  require the Python oracle to emit adjacency data between
--  cells at consecutive BFS depths (Phase H.3, estimated 1–2
--  weeks).  The trivial instantiation below demonstrates that
--  the types are well-formed and the proofs compute.
-- ════════════════════════════════════════════════════════════════════

private

  -- Trivial cell family: ℕ at all times
  TrivCell : ℕ → Type₀
  TrivCell _ = ℕ

  -- Trivial adjacency: always holds (witnessed by 0)
  TrivAdj : ∀ n → TrivCell n → TrivCell (suc n) → Type₀
  TrivAdj _ _ _ = ℕ

  -- ── Events ───────────────────────────────────────────────────────

  -- Two events at time 0 with DIFFERENT cells
  ev0-cell0 : Event TrivCell
  ev0-cell0 = mkEvent 0 0

  ev0-cell1 : Event TrivCell
  ev0-cell1 = mkEvent 0 1

  -- An event at time 1
  ev1 : Event TrivCell
  ev1 = mkEvent 1 0

  -- An event at time 2
  ev2 : Event TrivCell
  ev2 = mkEvent 2 0

  -- ── CausalLinks ──────────────────────────────────────────────────

  link-0-to-1 : CausalLink TrivCell TrivAdj ev0-cell0 ev1
  link-0-to-1 .CausalLink.time-suc = refl
  link-0-to-1 .CausalLink.adjacent = 0

  link-1-to-2 : CausalLink TrivCell TrivAdj ev1 ev2
  link-1-to-2 .CausalLink.time-suc = refl
  link-1-to-2 .CausalLink.adjacent = 0

  -- ── FutureCone examples ──────────────────────────────────────────

  -- Every event is in its own future cone (zero-length chain)
  cone-self : FutureCone TrivCell TrivAdj ev0-cell0
  cone-self = self-in-cone ev0-cell0

  check-self-target :
    Event.time (FutureCone.target cone-self) ≡ 0
  check-self-target = refl

  check-self-length :
    chain-length (FutureCone.chain cone-self) ≡ 0
  check-self-length = refl

  -- ev1 is in J⁺(ev0-cell0) via one causal step
  cone-one-step : FutureCone TrivCell TrivAdj ev0-cell0
  cone-one-step = extend-cone (self-in-cone ev0-cell0) link-0-to-1

  check-one-target :
    Event.time (FutureCone.target cone-one-step) ≡ 1
  check-one-target = refl

  check-one-length :
    chain-length (FutureCone.chain cone-one-step) ≡ 1
  check-one-length = refl

  -- ev2 is in J⁺(ev0-cell0) via two causal steps
  cone-two-steps : FutureCone TrivCell TrivAdj ev0-cell0
  cone-two-steps = extend-cone cone-one-step link-1-to-2

  check-two-target :
    Event.time (FutureCone.target cone-two-steps) ≡ 2
  check-two-target = refl

  check-two-length :
    chain-length (FutureCone.chain cone-two-steps) ≡ 2
  check-two-length = refl

  -- ── Spacelike separation examples ────────────────────────────────

  -- ev0-cell0 and ev0-cell1 are at the same time (time 0)
  check-same-time :
    Event.time ev0-cell0 ≡ Event.time ev0-cell1
  check-same-time = refl

  -- Therefore they are spacelike-separated
  concrete-spacelike :
    Spacelike TrivCell TrivAdj ev0-cell0 ev0-cell1
  concrete-spacelike = same-time-spacelike refl

  -- ── CausallyRelated example ──────────────────────────────────────

  -- ev0-cell0 IS causally related to ev1 (one-step chain)
  concrete-related :
    CausallyRelated TrivCell TrivAdj ev0-cell0 ev1
  concrete-related = ev0-cell0 , done ev0-cell0 , link-0-to-1

  -- The causal relationship implies strict time ordering
  check-related-< : Event.time ev0-cell0 <ℕ Event.time ev1
  check-related-< = related→time-< concrete-related

  check-related-witness : check-related-< ≡ (0 , refl)
  check-related-witness = refl


-- ════════════════════════════════════════════════════════════════════
--  §10.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    FutureCone       : (CellAt : ℕ → Type₀)
--                       → (Adj : ∀ n → CellAt n → CellAt (suc n) → Type₀)
--                       → Event CellAt → Type₀
--                       (record with fields  target ,  chain)
--
--    self-in-cone     : (e : Event CellAt) → FutureCone CellAt Adj e
--                       (reflexivity: every event is in its own cone)
--
--    extend-cone      : FutureCone CellAt Adj e
--                       → CausalLink CellAt Adj (target fc) e'
--                       → FutureCone CellAt Adj e
--                       (transitivity: one step extends the cone)
--
--    CausallyRelated  : ... → Event CellAt → Event CellAt → Type₀
--                       (positive-length chain: Σ intermediate + link)
--
--    related→time-<   : CausallyRelated ... e₁ e₂
--                       → Event.time e₁ <ℕ Event.time e₂
--                       (causal ⟹ timelike)
--
--    Spacelike        : ... → Event CellAt → Event CellAt → Type₀
--                       (no positive chain in either direction)
--
--    same-time→¬related : time e₁ ≡ time e₂
--                       → CausallyRelated ... e₁ e₂ → ⊥
--                       (same time ⟹ not causally related)
--
--    same-time-spacelike : time e₁ ≡ time e₂
--                        → Spacelike ... e₁ e₂
--                        (same time ⟹ spacelike-separated)
--
--  Architecture:
--
--    This module completes the discrete light-cone infrastructure
--    for §12 of docs/10-frontier.md.  The four Causal modules form
--    a coherent package:
--
--      Event.agda         — spacetime atoms, causal links, chains
--      CausalDiamond.agda — finite causal intervals, maximin, proper time
--      NoCTC.agda         — no closed timelike curves (acyclicity)
--      LightCone.agda     — future cone, spacelike separation (this module)
--
--    The proof architecture leverages the existing NoCTC infrastructure:
--
--      chain-step-<   (NoCTC)   — positive chain ⟹ strict time ordering
--      <ℕ-irrefl     (NoCTC)   — ¬ (n <ℕ n)
--      related→time-< (this)    — wrapper: CausallyRelated ⟹ strict <
--      same-time→¬related (this) — same time + chain ⟹ ⊥  (via subst)
--      same-time-spacelike (this) — both directions
--
--    The key insight: spacelike separation in a time-stratified poset
--    is a CONSEQUENCE of acyclicity (no-CTC), not an independent axiom.
--    The type system enforces both properties simultaneously through
--    the single constraint that CausalLink.time-suc strictly advances
--    the time index.
--
--  Relationship to the physical causal interpretation (§12.9):
--
--    • "Timelike" = causally related = CausallyRelated CellAt Adj e₁ e₂
--    • "Spacelike" = incomparable in the poset = Spacelike CellAt Adj e₁ e₂
--    • "Null" = adjacent in the causal graph with zero spatial separation
--      (single-step links to the same spatial cell at the next time)
--      — not formalized here; would require a notion of "same cell"
--      across time steps.
--
--  Exit criterion (§12.13 of docs/10-frontier.md):
--
--    4. (Stretch) ✓  FutureCone and spacelike-separation are defined
--       and instantiated for concrete events (§9 above: trivial cell
--       family with two same-time events proven spacelike-separated,
--       and future cone elements constructed with chains of length
--       0, 1, and 2).
--
--  Future work (Phase H.3 — Python oracle):
--
--    To instantiate FutureCone for concrete events in the {5,4}
--    tower diamond, the Python oracle (13_generate_layerN.py) would
--    need to emit adjacency data between cells at consecutive BFS
--    depths.  This would enable:
--
--      • Concrete  CellAt : ℕ → Type₀  mapping each depth to the
--        tile type at that layer (e.g., Layer54d2Region at time 0,
--        Layer54d3Region at time 1, etc.)
--
--      • Concrete  Adj  specifying which tiles at depth n are
--        connected to which tiles at depth n+1 through the BFS
--        expansion.
--
--      • Concrete  FutureCone  elements showing reachability
--        through multiple tower levels.
--
--    This is estimated at 1–2 weeks of development (Phase H.3 of
--    §12.12) and is not required for the current exit criteria.
--
--  Reference:
--    docs/10-frontier.md §12    (The Causal Light Cone)
--    docs/10-frontier.md §12.8  (The Discrete Light Cone)
--    docs/10-frontier.md §12.9  (Bypassing Smooth Geometry)
--    docs/10-frontier.md §12.11 (New Module Plan)
--    docs/10-frontier.md §12.13 (Exit Criterion)
-- ════════════════════════════════════════════════════════════════════