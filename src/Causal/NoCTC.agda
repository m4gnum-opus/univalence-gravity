{-# OPTIONS --cubical --safe --guardedness #-}

module Causal.NoCTC where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc ; _+_ ; snotz ; injSuc)
open import Cubical.Data.Nat.Properties
  using (+-suc ; +-assoc)
open import Cubical.Data.Empty
  using (⊥)

open import Causal.Event


-- ════════════════════════════════════════════════════════════════════
--  Structural Acyclicity of the Stratified Causal Poset
-- ════════════════════════════════════════════════════════════════════
--
--  This module proves that no Closed Timelike Curve (CTC) can exist
--  in a time-stratified causal poset.  The proof is a direct
--  consequence of the well-foundedness of (ℕ, <):
--
--    1.  Every CausalLink strictly increases the time index
--        (causal-link-< from Causal/Event.agda).
--
--    2.  The strict ordering _<ℕ_ is irreflexive: ¬ (n <ℕ n).
--
--    3.  The strict ordering is transitive: composing links gives
--        a strict ordering across multi-step chains.
--
--    4.  A CTC (a causal chain from e back to e with at least one
--        step) would require  time e <ℕ time e , contradicting (2).
--
--  This is the deepest advantage of the dependent-type approach:
--  the type system itself prevents time travel.  The CTC-freedom
--  is enforced by the type signature of CausalLink, not by a
--  separate axiom or proof obligation added after the fact.
--
--  Module dependencies:
--
--    Cubical.Data.Nat            — ℕ, snotz, injSuc
--    Cubical.Data.Nat.Properties — +-suc, +-assoc
--    Cubical.Data.Empty          — ⊥
--    Causal/Event.agda           — Event, _<ℕ_, CausalLink,
--                                  CausalChain, causal-link-<
--
--  Reference:
--    docs/10-frontier.md §12.5   (Acyclicity: No CTCs)
--    docs/10-frontier.md §12.12  (Phase H.2 — No-CTC proof)
--    docs/10-frontier.md §12.13  (Exit Criterion, item 3)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Helper lemma:  suc k + n ≡ n  is absurd
-- ════════════════════════════════════════════════════════════════════
--
--  Proof by induction on  n :
--
--  Base case (n = 0):
--    suc k + 0  =  suc (k + 0)  (by _+_ recursion on left arg)
--    suc (k + 0) ≡ 0  is absurd by  snotz .
--
--  Inductive step (n = suc n'):
--    suc k + suc n'  =  suc (k + suc n')  (by _+_ recursion)
--    So  p : suc (k + suc n') ≡ suc n'
--    By  injSuc :  k + suc n' ≡ n'
--    By  +-suc k n' : k + suc n' ≡ suc (k + n')
--    So  sym (+-suc k n') ∙ injSuc p : suc (k + n') ≡ n'
--    And  suc (k + n')  is definitionally  suc k + n'
--    so we have  suc k + n' ≡ n'  and the IH applies.
-- ════════════════════════════════════════════════════════════════════

private
  suc+n≢n : (k n : ℕ) → suc k + n ≡ n → ⊥
  suc+n≢n k zero    p = snotz p
  suc+n≢n k (suc n) p =
    suc+n≢n k n (sym (+-suc k n) ∙ injSuc p)


-- ════════════════════════════════════════════════════════════════════
--  §2.  Irreflexivity of the strict ordering on ℕ
-- ════════════════════════════════════════════════════════════════════
--
--  ¬ (n <ℕ n)  :  there exists no  k  such that  suc k + n ≡ n .
--
--  This is the foundational acyclicity fact.  In the causal poset,
--  it means no event can be strictly earlier than itself.
--
--  The proof is immediate from  suc+n≢n :  given  (k , p) : n <ℕ n
--  where  p : suc k + n ≡ n ,  we apply the helper lemma.
-- ════════════════════════════════════════════════════════════════════

<ℕ-irrefl : (n : ℕ) → n <ℕ n → ⊥
<ℕ-irrefl n (k , p) = suc+n≢n k n p


-- ════════════════════════════════════════════════════════════════════
--  §3.  Transitivity of the strict ordering on ℕ
-- ════════════════════════════════════════════════════════════════════
--
--  If  a <ℕ b  and  b <ℕ c , then  a <ℕ c .
--
--  Given  (j , p) : a <ℕ b   where  p : suc j + a ≡ b
--  and    (k , q) : b <ℕ c   where  q : suc k + b ≡ c
--
--  we produce  (k + suc j , r) : a <ℕ c   where:
--
--    suc (k + suc j) + a
--    = suc ((k + suc j) + a)             [_+_ recursion]
--    ≡ suc (k + (suc j + a))             [+-assoc]
--    ≡ suc (k + b)                       [p : suc j + a ≡ b]
--    = suc k + b                         [_+_ recursion]
--    ≡ c                                  [q]
--
--  This is needed to lift the single-step ordering from CausalLink
--  to multi-step CausalChain.
-- ════════════════════════════════════════════════════════════════════

<ℕ-trans : {a b c : ℕ} → a <ℕ b → b <ℕ c → a <ℕ c
<ℕ-trans {a} (j , p) (k , q) =
  k + suc j ,
  cong suc (sym (+-assoc k (suc j) a) ∙ cong (λ x → k + x) p) ∙ q


-- ════════════════════════════════════════════════════════════════════
--  §4.  Non-trivial causal chains imply strict time ordering
-- ════════════════════════════════════════════════════════════════════
--
--  A CausalChain from  e₁  to  e₂  followed by one more CausalLink
--  from  e₂  to  e₃  (i.e., a chain of length ≥ 1) implies:
--
--    Event.time e₁  <ℕ  Event.time e₃
--
--  Proof by induction on the chain prefix:
--
--  Base case (done e):
--    The prefix is trivial (e₁ = e₂ = e), and the link gives
--    time e <ℕ time e₃  via  causal-link-< .
--
--  Inductive step (step ch link₁):
--    The prefix already has a step, so by IH:
--      time e₁ <ℕ time e₂   (from the prefix chain + link₁)
--    And the new link gives:
--      time e₂ <ℕ time e₃   (from causal-link-<)
--    By  <ℕ-trans :
--      time e₁ <ℕ time e₃
--
--  This is the core lemma connecting the combinatorial chain
--  structure to the arithmetic ordering on time indices.
-- ════════════════════════════════════════════════════════════════════

chain-step-< :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e₁ e₂ e₃ : Event CellAt}
  → CausalChain CellAt Adj e₁ e₂
  → CausalLink CellAt Adj e₂ e₃
  → Event.time e₁ <ℕ Event.time e₃
chain-step-< (done _)       link = causal-link-< link
chain-step-< (step ch link₁) link₂ =
  <ℕ-trans (chain-step-< ch link₁) (causal-link-< link₂)


-- ════════════════════════════════════════════════════════════════════
--  §5.  No Closed Timelike Curves
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (CTC-Freedom of the Stratified Causal Poset).
--
--  For any cell family  CellAt  and adjacency relation  Adj , there
--  is no CausalChain from an event  e  back to itself that uses at
--  least one CausalLink.
--
--  Formally:  given a chain from  e  to  e'  and a link from  e'
--  back to  e , we derive  ⊥ .
--
--  Proof outline:
--    1.  chain-step-<  gives  time e <ℕ time e .
--    2.  <ℕ-irrefl     gives  ⊥ .
--
--  This is the "one-line appeal to the well-foundedness of (ℕ, <)"
--  described in Phase H.2 of §12.12 of docs/10-frontier.md.
--
--  The theorem is fully parametric: it works for ANY cell family and
--  ANY adjacency relation.  It does not depend on the specific
--  structure of the {5,4} tiling, the Dense-100 patch, or any
--  other concrete instance.  The acyclicity is a structural
--  property of time-stratified causality, not of the spatial
--  geometry.
--
--  In the physics interpretation: the type system prevents time
--  travel.  Any causal process that advances through the tower
--  (each step increasing the time index by 1) can never return
--  to a previously visited time — because ℕ has no cycles.
--
--  Reference:
--    docs/10-frontier.md §12.5   (Acyclicity: No CTCs)
--    docs/10-frontier.md §12.12  (Phase H.2)
--    docs/10-frontier.md §12.13  (Exit criterion, item 3)
-- ════════════════════════════════════════════════════════════════════

no-ctc :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e e'   : Event CellAt}
  → CausalChain CellAt Adj e e'
  → CausalLink CellAt Adj e' e
  → ⊥
no-ctc {e = e} ch link =
  <ℕ-irrefl (Event.time e) (chain-step-< ch link)


-- ════════════════════════════════════════════════════════════════════
--  §6.  Named theorem alias
-- ════════════════════════════════════════════════════════════════════
--
--  The type  NoCTCs  and its inhabitant  no-ctcs  provide a stable
--  reference point for the roadmap and documentation.
--
--  NoCTCs is parameterized by the cell family and adjacency
--  relation, stating that for ALL events and chain/link decompositions,
--  the return type is empty.
-- ════════════════════════════════════════════════════════════════════

NoCTCs :
  (CellAt : ℕ → Type₀)
  (Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀)
  → Type₀
NoCTCs CellAt Adj =
  {e e' : Event CellAt}
  → CausalChain CellAt Adj e e'
  → CausalLink CellAt Adj e' e
  → ⊥

no-ctcs :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  → NoCTCs CellAt Adj
no-ctcs = no-ctc


-- ════════════════════════════════════════════════════════════════════
--  §7.  Regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These tests verify that the irreflexivity and transitivity lemmas
--  produce the expected results on concrete numeral arguments, and
--  that the full chain-step-< proof computes correctly on the
--  trivial test infrastructure from Causal/Event.agda.
-- ════════════════════════════════════════════════════════════════════

private
  -- ── Irreflexivity checks ─────────────────────────────────────
  --
  --  These confirm that  <ℕ-irrefl  correctly rejects concrete
  --  self-comparison witnesses.

  -- If  0 <ℕ 0  via (0, p), then  p : suc 0 + 0 ≡ 0 = 1 ≡ 0.
  -- snotz rejects this.
  check-irrefl-type : (0 <ℕ 0) → ⊥
  check-irrefl-type = <ℕ-irrefl 0

  check-irrefl-type-3 : (3 <ℕ 3) → ⊥
  check-irrefl-type-3 = <ℕ-irrefl 3

  -- ── Transitivity checks ──────────────────────────────────────
  --
  --  Verify that  <ℕ-trans  computes correctly on closed witnesses.
  --
  --  0 <ℕ 1  via  (0 , refl)  :  suc 0 + 0 = 1 ≡ 1
  --  1 <ℕ 2  via  (0 , refl)  :  suc 0 + 1 = 2 ≡ 2
  --  ⟹  0 <ℕ 2  (composed)

  -- Check that  <ℕ-trans  produces a valid witness for 0 <ℕ 2
  check-trans : 0 <ℕ 2
  check-trans = <ℕ-trans {0} {1} {2} (0 , refl) (0 , refl)

  -- ── Trivial cell infrastructure (reused from Event tests) ────

  TrivCell : ℕ → Type₀
  TrivCell _ = ℕ

  TrivAdj : ∀ n → TrivCell n → TrivCell (suc n) → Type₀
  TrivAdj _ _ _ = ℕ

  ev0 : Event TrivCell
  ev0 = mkEvent 0 0

  ev1 : Event TrivCell
  ev1 = mkEvent 1 0

  ev2 : Event TrivCell
  ev2 = mkEvent 2 0

  link01 : CausalLink TrivCell TrivAdj ev0 ev1
  link01 .CausalLink.time-suc = refl
  link01 .CausalLink.adjacent = 0

  link12 : CausalLink TrivCell TrivAdj ev1 ev2
  link12 .CausalLink.time-suc = refl
  link12 .CausalLink.adjacent = 0

  -- ── chain-step-< regression: single step ─────────────────────
  --
  --  done ev0  +  link01  should give  0 <ℕ 1  via  (0 , refl) .

  check-single-step : Event.time ev0 <ℕ Event.time ev1
  check-single-step = chain-step-< (done ev0) link01

  check-single-step-witness : check-single-step ≡ (0 , refl)
  check-single-step-witness = refl

  -- ── chain-step-< regression: two steps ───────────────────────
  --
  --  step (done ev0) link01  +  link12  should give  0 <ℕ 2 .

  check-two-step : Event.time ev0 <ℕ Event.time ev2
  check-two-step = chain-step-< (step (done ev0) link01) link12


-- ════════════════════════════════════════════════════════════════════
--  §8.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    <ℕ-irrefl    : (n : ℕ) → n <ℕ n → ⊥
--                   (irreflexivity of strict ℕ ordering)
--
--    <ℕ-trans     : a <ℕ b → b <ℕ c → a <ℕ c
--                   (transitivity of strict ℕ ordering)
--
--    chain-step-< : CausalChain ... e₁ e₂ → CausalLink ... e₂ e₃
--                   → Event.time e₁ <ℕ Event.time e₃
--                   (positive-length chains imply strict ordering)
--
--    no-ctc       : CausalChain ... e e' → CausalLink ... e' e → ⊥
--                   (no closed timelike curve)
--
--    NoCTCs       : (CellAt : ℕ → Type₀) → (Adj : ...) → Type₀
--                   (parameterized no-CTC property)
--
--    no-ctcs      : NoCTCs CellAt Adj
--                   (the theorem, for any cell family and adjacency)
--
--  Architecture:
--
--    The proof decomposes into three independent lemmas:
--
--      suc+n≢n    :  suc k + n ≡ n → ⊥    (core arithmetic fact)
--      <ℕ-irrefl  :  n <ℕ n → ⊥            (irreflexivity)
--      <ℕ-trans   :  a <ℕ b → b <ℕ c → a <ℕ c  (transitivity)
--
--    These compose via chain-step-< (induction on CausalChain)
--    into the no-ctc theorem.  The entire proof is:
--
--      no-ctc ch link = <ℕ-irrefl (time e) (chain-step-< ch link)
--
--    This is the "one-line appeal to well-foundedness" promised in
--    Phase H.2 of §12.12 of docs/10-frontier.md.
--
--  Relationship to existing infrastructure:
--
--    This module imports from (but does NOT modify):
--      • Cubical.Data.Nat            — snotz, injSuc
--      • Cubical.Data.Nat.Properties — +-suc, +-assoc
--      • Cubical.Data.Empty          — ⊥
--      • Causal/Event.agda           — Event, _<ℕ_, CausalLink,
--                                      CausalChain, causal-link-<
--
--    The lemmas  <ℕ-irrefl  and  <ℕ-trans  are pure ℕ arithmetic
--    facts independent of the causal infrastructure.  They could
--    be moved to  Util/NatLemmas.agda  if needed by other modules.
--
--  Design decisions:
--
--    1.  The no-CTC theorem is stated as "a chain + a closing link
--        yield ⊥," rather than "CausalChain e e with positive
--        length yields ⊥."  This avoids defining an auxiliary
--        "positive-length chain" type and makes the theorem
--        directly applicable: any attempted CTC must have at least
--        one link, and the chain preceding that last link provides
--        the  CausalChain  argument.
--
--    2.  The transitivity proof  <ℕ-trans  uses  +-assoc  and
--        path composition rather than a custom inductive argument.
--        This keeps the proof compact and leverages the cubical
--        library's existing arithmetic infrastructure.
--
--    3.  The helper  suc+n≢n  uses  +-suc  to transform the
--        inductive step from  k + suc n' ≡ n'  into
--        suc k + n' ≡ n' ,  matching the shape of the IH.
--        This is the key arithmetic trick: addition reduces on
--        the LEFT argument, but the induction is on the RIGHT
--        argument, so  +-suc  bridges the gap.
--
--    4.  All results are fully parametric in  CellAt  and  Adj .
--        The no-CTC property holds for ANY discrete causal
--        spacetime stratified by ℕ — not just the {5,4} tower
--        or the Dense resolution tower.  This generality is the
--        architectural advantage of the time-stratification
--        approach: the acyclicity guarantee is free.
--
--  Exit criterion (§12.13 of docs/10-frontier.md):
--
--    3. ✓  A  no-ctcs  proof type-checks, witnessing that the
--          stratified causal poset admits no directed cycles.
--
--  Research significance (§12.14):
--
--    This is the first machine-checked proof of CTC-freedom as a
--    structural consequence of type-level time stratification in a
--    cubical type theory.  The proof demonstrates that the causal
--    structure of discrete quantum gravity is compatible with the
--    spatial holographic correspondence formalized in the rest of
--    the repository.
--
--  Reference:
--    docs/10-frontier.md §12.5   (Acyclicity: No CTCs)
--    docs/10-frontier.md §12.12  (Phase H.2 — No-CTC proof)
--    docs/10-frontier.md §12.13  (Exit Criterion, item 3)
--    docs/10-frontier.md §12.14  (Research Significance, item 3)
-- ════════════════════════════════════════════════════════════════════