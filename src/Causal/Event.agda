{-# OPTIONS --cubical --safe --guardedness #-}

module Causal.Event where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; zero ; suc ; _+_)


-- ════════════════════════════════════════════════════════════════════
--  §1.  Event — A spacetime atom
-- ════════════════════════════════════════════════════════════════════
--
--  An Event is a pair of a time-index  n : ℕ  and a spatial cell
--  within the slice at time n.  The cell type varies with n (as
--  the patch grows), making Event a dependent type.
--
--  In the SchematicTower architecture (Bridge/SchematicTower.agda),
--  each TowerLevel at depth n carries an OrbitReducedPatch whose
--  RegionTy serves as CellAt n.  The tower index IS the time
--  coordinate; each TowerLevel IS a spatial slice (antichain) in
--  the discrete causal poset.
--
--  Architectural role:
--    This is a Tier 1 (Specification Layer) standalone type with
--    no internal dependencies beyond Cubical.Foundations.Prelude
--    and Cubical.Data.Nat.  It is consumed by:
--      • Causal/CausalDiamond.agda  (CausalDiamond, maximin, proper-time)
--      • Causal/NoCTC.agda          (structural acyclicity proof)
--      • Causal/LightCone.agda      (FutureCone, spacelike separation)
--
--  Reference:
--    docs/formal/06-causal-structure.md §2   (Events — Spacetime Atoms)
--    docs/formal/06-causal-structure.md §1   (The Tower IS the Spacetime)
--    docs/formal/01-theorems.md §Thm 5       (No Closed Timelike Curves)
--    docs/getting-started/architecture.md    (Specification Layer)
--    docs/reference/module-index.md          (module description)
-- ════════════════════════════════════════════════════════════════════

record Event (CellAt : ℕ → Type₀) : Type₀ where
  field
    time : ℕ
    cell : CellAt time


-- ════════════════════════════════════════════════════════════════════
--  §2.  Strict ordering on ℕ
-- ════════════════════════════════════════════════════════════════════
--
--  m <ℕ n  means there exists  k : ℕ  such that  suc k + m ≡ n .
--  Since  _+_  reduces by recursion on its first argument:
--
--    suc k + m  =  suc (k + m)       (definitional)
--
--  the witness  (0 , p)  where  p : suc m ≡ n  gives an immediate
--  successor relationship (single time-step).  The witness  (k , p)
--  for general  k  gives  n = m + k + 1  (multi-step separation).
--
--  This is consistent with the ordering  _≤ℚ_  from
--  Util/Scalars.agda:  m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n) .
--  The strict version requires  suc k  rather than  k  in the
--  first position, ensuring  n ≥ m + 1 .
--
--  The irreflexivity of  _<ℕ_  (the impossibility of  n <ℕ n)
--  is the structural guarantee that no closed timelike curve can
--  exist.  It is formalized in  Causal/NoCTC.agda .
--
--  Reference:
--    docs/formal/06-causal-structure.md §2.2  (Strict Ordering on ℕ)
--    docs/formal/06-causal-structure.md §5    (No Closed Timelike Curves)
-- ════════════════════════════════════════════════════════════════════

infix 4 _<ℕ_

_<ℕ_ : ℕ → ℕ → Type₀
m <ℕ n = Σ[ k ∈ ℕ ] (suc k + m ≡ n)


-- ════════════════════════════════════════════════════════════════════
--  §3.  CausalLink — A single future-directed step
-- ════════════════════════════════════════════════════════════════════
--
--  A CausalLink connects two events separated by exactly one
--  time-step.  It is parameterized by:
--
--    CellAt : ℕ → Type₀
--      The family of spatial-cell types at each time index.
--
--    Adj : ∀ n → CellAt n → CellAt (suc n) → Type₀
--      A spatial adjacency relation between cells at consecutive
--      times.  In concrete instances, this encodes whether a cell
--      at time n is "connected to" (reachable from) a cell at
--      time suc n through the BFS expansion.  The Python oracle
--      (sim/prototyping/13_generate_layerN.py) computes these
--      adjacencies.
--
--  Fields:
--
--    time-suc : suc (Event.time e₁) ≡ Event.time e₂
--      Witnesses that e₂ is at the immediate next time-step after e₁.
--      This is the TYPE-LEVEL acyclicity guarantee: causal links
--      go strictly forward in time by construction.
--
--    adjacent : Adj (Event.time e₁) (Event.cell e₁) (transported e₂.cell)
--      Witnesses that the spatial cells of the two events are
--      adjacent across the time-step.  The target cell is
--      transported along  sym time-suc  to match the expected
--      type  CellAt (suc (Event.time e₁)) .
--
--  Transport note:
--
--    When  Event.time e₂  is literally  suc (Event.time e₁)
--    (which is the common case for tower-based instantiation),
--    time-suc = refl  and  subst CellAt (sym refl) = id ,
--    so the transport vanishes and the adjacent field reduces to
--    Adj n c₁ c₂  directly.
--
--  Design note (single-step vs general strict ordering):
--
--    The formal documentation (docs/formal/06-causal-structure.md §3)
--    notes that a general strict ordering  time e₁ < time e₂  could
--    be used for the time-step field.  This implementation
--    strengthens the field to  time-suc : suc (time e₁) ≡ time e₂
--    (single step), which:
--
--      (a) makes the  adjacent  field well-typed without needing
--          a multi-step adjacency relation;
--      (b) matches the tower architecture where each LayerStep
--          goes from level n to level n+1;
--      (c) composes into CausalChain (§5) for multi-step paths;
--      (d) implies the general strict ordering via  causal-link-<
--          (§4), so the NoCTC argument is preserved.
--
--  Reference:
--    docs/formal/06-causal-structure.md §3    (Causal Links)
--    docs/formal/06-causal-structure.md §3.1  (The CausalLink Record)
--    docs/formal/06-causal-structure.md §5    (Acyclicity: No CTCs)
--    docs/formal/01-theorems.md §Thm 5        (No Closed Timelike Curves)
-- ════════════════════════════════════════════════════════════════════

record CausalLink
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  (e₁ e₂ : Event CellAt) : Type₀ where
  field
    time-suc : suc (Event.time e₁) ≡ Event.time e₂
    adjacent : Adj (Event.time e₁)
                   (Event.cell e₁)
                   (subst CellAt (sym time-suc) (Event.cell e₂))


-- ════════════════════════════════════════════════════════════════════
--  §4.  CausalLink implies strict ordering
-- ════════════════════════════════════════════════════════════════════
--
--  Every CausalLink strictly increases the time index:
--
--    Event.time e₁  <ℕ  Event.time e₂
--
--  The witness is  (0 , time-suc) :
--
--    suc 0 + Event.time e₁
--      = suc (0 + Event.time e₁)     (by _+_ recursion)
--      = suc (Event.time e₁)          (by 0 + n = n)
--      ≡ Event.time e₂                (by time-suc)
--
--  This derivation is the formal content of the acyclicity
--  guarantee: the type signature of CausalLink prevents time
--  travel because a CTC would require  Event.time e <ℕ Event.time e
--  for some event e, contradicting the irreflexivity of  _<ℕ_  on ℕ.
--  The irreflexivity proof is in  Causal/NoCTC.agda .
--
--  Reference:
--    docs/formal/06-causal-structure.md §3.2  (Links Imply Strict
--                                              Time Ordering)
--    docs/formal/06-causal-structure.md §5    (No Closed Timelike Curves)
-- ════════════════════════════════════════════════════════════════════

causal-link-< :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂ : Event CellAt}
  → CausalLink CellAt Adj e₁ e₂
  → Event.time e₁ <ℕ Event.time e₂
causal-link-< cl = 0 , CausalLink.time-suc cl


-- ════════════════════════════════════════════════════════════════════
--  §5.  CausalChain — Composable path of causal steps
-- ════════════════════════════════════════════════════════════════════
--
--  A CausalChain from  e₁  to  e₂  is a finite sequence of
--  CausalLinks composing to a directed path in the causal poset.
--  Its length is the proper time between the endpoints.
--
--  Constructors:
--
--    done :  the trivial chain from an event to itself (length 0).
--            This represents zero proper time and is needed for
--            the reflexive case of the future light cone:
--            J⁺(e) includes e itself.
--
--    step :  extend a chain by one CausalLink at the end.
--            If we have a chain from e₁ to e₂ and a link from
--            e₂ to e₃, we get a chain from e₁ to e₃.
--
--  In the stratified tower, all maximal chains between levels
--  n and m have the same length  m − n  (the proper time).
--  CausalChain provides the type-theoretic substrate for:
--
--    • FutureCone (Causal/LightCone.agda): the set of events
--      reachable from a given event via some CausalChain.
--
--    • Proper time (Causal/CausalDiamond.agda): the length of
--      the longest CausalChain between two events (here: all
--      chains have the same length in the stratified tower).
--
--    • Spacelike separation (Causal/LightCone.agda): two events
--      at the same time are spacelike-separated if neither is
--      in the other's future light cone.
--
--  Reference:
--    docs/formal/06-causal-structure.md §4   (Causal Chains)
--    docs/formal/06-causal-structure.md §6   (Causal Diamonds)
--    docs/formal/06-causal-structure.md §8   (The Discrete Light Cone)
-- ════════════════════════════════════════════════════════════════════

data CausalChain
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  : Event CellAt → Event CellAt → Type₀ where

  done : (e : Event CellAt)
    → CausalChain CellAt Adj e e

  step : {e₁ e₂ e₃ : Event CellAt}
    → CausalChain CellAt Adj e₁ e₂
    → CausalLink CellAt Adj e₂ e₃
    → CausalChain CellAt Adj e₁ e₃


-- ════════════════════════════════════════════════════════════════════
--  §6.  Chain length — Proper time in the stratified tower
-- ════════════════════════════════════════════════════════════════════
--
--  The number of CausalLink steps in a CausalChain.  In the
--  stratified tower (where every CausalLink advances time by
--  exactly 1), the chain length equals the time difference:
--
--    chain-length (chain from (n,c₁) to (m,c₂))  =  m − n
--
--  This is computable as truncated subtraction  m ∸ n  on ℕ
--  (already available in the cubical library), but here it is
--  computed structurally from the chain itself.
--
--  Reference:
--    docs/formal/06-causal-structure.md §4   (Causal Chains —
--                                             chain length as
--                                             proper time)
--    docs/formal/06-causal-structure.md §6   (Causal Diamonds —
--                                             proper time)
-- ════════════════════════════════════════════════════════════════════

chain-length :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂ : Event CellAt}
  → CausalChain CellAt Adj e₁ e₂
  → ℕ
chain-length (done _)     = 0
chain-length (step ch _)  = suc (chain-length ch)


-- ════════════════════════════════════════════════════════════════════
--  §7.  Convenience: constructing events
-- ════════════════════════════════════════════════════════════════════
--
--  mkEvent  constructs an Event from an explicit time index and
--  cell.  This is a trivial wrapper, but it makes concrete
--  instantiations more readable than copattern matching.
-- ════════════════════════════════════════════════════════════════════

mkEvent :
  {CellAt : ℕ → Type₀}
  → (n : ℕ) → CellAt n → Event CellAt
mkEvent n c .Event.time = n
mkEvent n c .Event.cell = c


-- ════════════════════════════════════════════════════════════════════
--  §8.  Regression tests — chain-length on concrete chains
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that chain-length computes correctly on small
--  concrete examples using a trivial cell type (ℕ at all times)
--  and a trivially-satisfied adjacency relation.
-- ════════════════════════════════════════════════════════════════════

private
  -- Trivial cell family: ℕ at all times
  TrivCell : ℕ → Type₀
  TrivCell _ = ℕ

  -- Trivial adjacency: always holds (witnessed by 0)
  TrivAdj : ∀ n → TrivCell n → TrivCell (suc n) → Type₀
  TrivAdj _ _ _ = ℕ

  -- Events at times 0, 1, 2
  ev0 : Event TrivCell
  ev0 = mkEvent 0 0

  ev1 : Event TrivCell
  ev1 = mkEvent 1 0

  ev2 : Event TrivCell
  ev2 = mkEvent 2 0

  -- A CausalLink from ev0 to ev1
  link01 : CausalLink TrivCell TrivAdj ev0 ev1
  link01 .CausalLink.time-suc = refl
  link01 .CausalLink.adjacent = 0    -- trivial witness

  -- A CausalLink from ev1 to ev2
  link12 : CausalLink TrivCell TrivAdj ev1 ev2
  link12 .CausalLink.time-suc = refl
  link12 .CausalLink.adjacent = 0

  -- Chain of length 0 (reflexive)
  chain-0 : CausalChain TrivCell TrivAdj ev0 ev0
  chain-0 = done ev0

  -- Chain of length 1 (one step)
  chain-1 : CausalChain TrivCell TrivAdj ev0 ev1
  chain-1 = step (done ev0) link01

  -- Chain of length 2 (two steps)
  chain-2 : CausalChain TrivCell TrivAdj ev0 ev2
  chain-2 = step (step (done ev0) link01) link12

  -- chain-length regression tests
  check-len-0 : chain-length chain-0 ≡ 0
  check-len-0 = refl

  check-len-1 : chain-length chain-1 ≡ 1
  check-len-1 = refl

  check-len-2 : chain-length chain-2 ≡ 2
  check-len-2 = refl

  -- causal-link-< regression test
  -- link01 implies  0 <ℕ 1 ,  witnessed by  (0 , refl)
  check-<-01 : causal-link-< link01 ≡ (0 , refl)
  check-<-01 = refl

  -- link12 implies  1 <ℕ 2 ,  witnessed by  (0 , refl)
  check-<-12 : causal-link-< link12 ≡ (0 , refl)
  check-<-12 = refl

  -- subst vanishes when time-suc = refl
  -- (the adjacent field reduces to TrivAdj 0 0 0 = ℕ)
  check-subst-vanishes :
    subst TrivCell (sym (CausalLink.time-suc link01)) (Event.cell ev1)
    ≡ Event.cell ev1
  check-subst-vanishes = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    Event         : (ℕ → Type₀) → Type₀
--                    (record with fields  time : ℕ ,  cell : CellAt time)
--    mkEvent       : (n : ℕ) → CellAt n → Event CellAt
--    _<ℕ_         : ℕ → ℕ → Type₀
--                    (strict ordering:  Σ[ k ∈ ℕ ] (suc k + m ≡ n) )
--    CausalLink    : (CellAt : ℕ → Type₀)
--                    → (Adj : ∀ n → CellAt n → CellAt (suc n) → Type₀)
--                    → Event CellAt → Event CellAt → Type₀
--                    (record with fields  time-suc ,  adjacent)
--    causal-link-< : CausalLink ... e₁ e₂ → time e₁ <ℕ time e₂
--    CausalChain   : ... → Event CellAt → Event CellAt → Type₀
--                    (inductive: done | step)
--    chain-length  : CausalChain ... e₁ e₂ → ℕ
--
--  Downstream modules:
--
--    src/Causal/CausalDiamond.agda
--      — CausalDiamond (finite causal interval [t₁, t₂])
--      — CausalExtension (= LayerStep from SchematicTower)
--      — maximin functional (max over slices of MinCut)
--      — proper-time (= chain-length for the stratified case)
--
--    src/Causal/NoCTC.agda
--      — Structural acyclicity proof: ¬ (n <ℕ n) by
--        well-foundedness of (ℕ, <).  Consequence of the type
--        signature of CausalLink (time-suc field).
--
--    src/Causal/LightCone.agda
--      — FutureCone (Event pairs connected by CausalChain)
--      — spacelike-separation (events at the same time not
--        in each other's light cones)
--
--  Relationship to existing infrastructure:
--
--    This module imports from (but does NOT modify):
--      • Cubical.Foundations.Prelude   — PathP, ≡, subst, Σ-syntax
--      • Cubical.Data.Nat             — ℕ, suc, _+_
--
--    The causal types are a NEW WRAPPER LAYER over the existing
--    SchematicTower (Bridge/SchematicTower.agda).  No existing
--    module is modified.  The causal structure reinterprets the
--    tower data through a Lorentzian lens:
--
--      TowerLevel     ↔  spatial slice (antichain)
--      LayerStep      ↔  CausalExtension (future-directed step)
--      tower index n  ↔  Event.time
--      OrbitReducedPatch.RegionTy at depth n  ↔  CellAt n
--
--  Design decisions:
--
--    1.  CausalLink is restricted to SINGLE time-steps
--        (time-suc : suc (time e₁) ≡ time e₂) rather than
--        arbitrary strict ordering (time e₁ < time e₂).  This
--        makes the  adjacent  field well-typed and matches the
--        tower architecture.  Multi-step separation is handled
--        by CausalChain (composition of single steps).
--
--    2.  The  adjacent  field uses  subst CellAt (sym time-suc)
--        to transport the target cell to the expected type.
--        When time-suc = refl (the common case for concrete
--        tower-based instantiation), the transport vanishes
--        judgmentally (subst _ refl = id).
--
--    3.  CausalChain uses snoc-style extension (step extends
--        at the END of the chain) rather than cons-style
--        (prepend at the beginning).  This matches "extending
--        a causal history by one more tick" — the natural
--        order for the tower construction.
--
--    4.  The strict ordering  _<ℕ_  is defined in the same
--        Sigma-style as  _≤ℚ_  from Util/Scalars.agda, ensuring
--        concrete witnesses like  (0 , refl)  type-check by
--        judgmental computation of ℕ addition.
--
--  Reference:
--    docs/formal/06-causal-structure.md       (The Causal Light Cone —
--                                              full formal treatment)
--    docs/formal/06-causal-structure.md §1    (Overview — the tower IS
--                                              the spacetime)
--    docs/formal/06-causal-structure.md §2    (Events)
--    docs/formal/06-causal-structure.md §3    (Causal Links)
--    docs/formal/06-causal-structure.md §4    (Causal Chains)
--    docs/formal/06-causal-structure.md §5    (No Closed Timelike Curves)
--    docs/formal/06-causal-structure.md §8    (The Discrete Light Cone)
--    docs/formal/01-theorems.md §Thm 5        (NoCTC theorem registry)
--    docs/formal/11-generic-bridge.md §5      (SchematicTower —
--                                              TowerLevel, LayerStep)
--    docs/getting-started/architecture.md     (module dependency DAG)
--    docs/reference/module-index.md           (module description)
--    docs/physics/holographic-dictionary.md §5 (causal structure
--                                              Agda ↔ physics table)
--    docs/historical/development-docs/10-frontier.md §12
--                                             (original development plan)
-- ════════════════════════════════════════════════════════════════════