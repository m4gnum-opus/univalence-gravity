{-# OPTIONS --cubical --safe --guardedness #-}

module Util.NatLemmas where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc ; _+_ ; injSuc)
open import Cubical.Data.Nat.Properties
  using (isSetℕ)

-- ════════════════════════════════════════════════════════════════════
--  ℕ Arithmetic Lemmas — Curated Re-Export Layer
-- ════════════════════════════════════════════════════════════════════
--
--  This module collects the ℕ arithmetic lemmas needed for
--  parameterized min-cut reasoning in the step-invariance theorem
--  (§11 of docs/10-frontier.md, Phase F.2a).
--
--  The existing bridge proofs (star-pointwise, filled-pointwise,
--  etc.) all hold by  refl  on closed numeral terms because both
--  sides reduce to the same canonical ℕ literal.  The step-
--  invariance theorem operates on VARIABLE bond weights
--  (w : Bond → ℚ≥0), producing computed expressions like
--
--    w bCN0 +ℚ w bCN1
--
--  that require explicit ℕ arithmetic lemmas — commutativity,
--  associativity, cancellation — to manipulate.
--
--  Most lemmas are available in  Cubical.Data.Nat.Properties ;
--  this module re-exports them through a single stable interface
--  and adds cancellation lemmas not directly provided by the
--  cubical library.
--
--  Downstream modules:
--
--    src/Boundary/StarCutParam.agda        (parameterized S-cut)
--    src/Bulk/StarChainParam.agda          (parameterized L-min)
--    src/Bridge/StarStepInvariance.agda    (step-invariance theorem)
--    src/Bridge/StarDynamicsLoop.agda      (iterated loop)
--
--  Relationship to existing code:
--
--    The cancellation lemmas  +-cancelˡ  and  +-cancelʳ  are
--    currently defined PRIVATELY in  Bridge/FullEnrichedStarObs.agda
--    (§1) for the  isProp≤ℚ  proof.  Factoring them here makes
--    them available to the new step-invariance modules without
--    creating a dependency on the enriched bridge.  The existing
--    private definitions in FullEnrichedStarObs remain valid and
--    are NOT modified.
--
--  Reference:
--    docs/10-frontier.md §11.4  (why ℕ lemmas are needed)
--    docs/10-frontier.md §11.7  (implementation plan, item 1)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  Re-exports from Cubical.Data.Nat.Properties
-- ════════════════════════════════════════════════════════════════════
--
--  These are the standard ℕ arithmetic identities from the cubical
--  library, re-exported publicly so that downstream modules can
--  import  Util.NatLemmas  as their single source for arithmetic.
--
--    +-comm  : ∀ m n   → m + n       ≡ n + m
--    +-assoc : ∀ m n o → m + (n + o) ≡ (m + n) + o
--    +-zero  : ∀ m     → m + 0       ≡ m
--    +-suc   : ∀ m n   → m + suc n   ≡ suc (m + n)
--
--  These hold by structural induction on the first argument of  _+_
--  (which computes by recursion on its left argument in the cubical
--  library).  They are NOT definitional equalities — they are paths
--  proven by induction — which is why parameterized proofs need
--  them explicitly, unlike the  refl  proofs on closed numerals.
-- ════════════════════════════════════════════════════════════════════

open import Cubical.Data.Nat.Properties
  using ( +-comm ; +-assoc ; +-zero ; +-suc )
  public


-- ════════════════════════════════════════════════════════════════════
--  §2.  Re-exports from Cubical.Data.Nat
-- ════════════════════════════════════════════════════════════════════
--
--  injSuc : suc m ≡ suc n → m ≡ n
--
--  The injectivity of the  suc  constructor, used as the base case
--  reducer in left cancellation.  Re-exported publicly.
--
--  isSetℕ : isSet ℕ
--
--  ℕ is a set (h-level 2).  This is the foundational h-level fact
--  enabling  isProp≤ℚ  and the round-trip homotopies in enriched
--  bridge equivalences.  Already available from
--  Cubical.Data.Nat.Properties ; re-exported here for convenience.
-- ════════════════════════════════════════════════════════════════════

open import Cubical.Data.Nat
  using ( injSuc )
  public

open import Cubical.Data.Nat.Properties
  using ( isSetℕ )
  public


-- ════════════════════════════════════════════════════════════════════
--  §3.  Left cancellation:  m + k₁ ≡ m + k₂  →  k₁ ≡ k₂
-- ════════════════════════════════════════════════════════════════════
--
--  Proof by induction on  m :
--
--    Base case (m = 0):
--      0 + k₁ ≡ 0 + k₂  reduces definitionally to  k₁ ≡ k₂ .
--
--    Inductive step (m = suc m'):
--      suc m' + k₁ ≡ suc m' + k₂
--      ≡  suc (m' + k₁) ≡ suc (m' + k₂)    (definitional)
--      →  m' + k₁ ≡ m' + k₂                  (by injSuc)
--      →  k₁ ≡ k₂                             (by IH)
--
--  This is the same proof as the private version in
--  Bridge/FullEnrichedStarObs.agda §1, now exported publicly.
-- ════════════════════════════════════════════════════════════════════

+-cancelˡ : (m : ℕ) {k₁ k₂ : ℕ} → m + k₁ ≡ m + k₂ → k₁ ≡ k₂
+-cancelˡ zero    p = p
+-cancelˡ (suc m) p = +-cancelˡ m (injSuc p)


-- ════════════════════════════════════════════════════════════════════
--  §4.  Right cancellation:  k₁ + m ≡ k₂ + m  →  k₁ ≡ k₂
-- ════════════════════════════════════════════════════════════════════
--
--  Derived from left cancellation via commutativity:
--
--    k₁ + m ≡ k₂ + m
--    →  m + k₁ ≡ m + k₂       (by +-comm on both sides)
--    →  k₁ ≡ k₂                (by +-cancelˡ)
--
--  The path composition uses:
--    +-comm m k₁  :  m + k₁ ≡ k₁ + m
--    p            :  k₁ + m ≡ k₂ + m
--    sym (+-comm m k₂)  :  k₂ + m ≡ m + k₂
--
--  Composing:  m + k₁ ≡ k₁ + m ≡ k₂ + m ≡ m + k₂
--  Then applying  +-cancelˡ m  yields  k₁ ≡ k₂ .
--
--  This is the same proof as the private version in
--  Bridge/FullEnrichedStarObs.agda §1, now exported publicly.
-- ════════════════════════════════════════════════════════════════════

+-cancelʳ : (m : ℕ) {k₁ k₂ : ℕ} → k₁ + m ≡ k₂ + m → k₁ ≡ k₂
+-cancelʳ m {k₁} {k₂} p =
  +-cancelˡ m (+-comm m k₁ ∙ p ∙ sym (+-comm m k₂))


-- ════════════════════════════════════════════════════════════════════
--  §5.  Regression tests — cancellation on closed terms
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the cancellation lemmas produce the expected
--  results on concrete numeral arguments.  Each test applies
--  cancellation to a  refl  proof (which suffices because both
--  sides of the equality compute to the same ℕ literal) and checks
--  that the output is  refl .
--
--  If any test fails after a library upgrade, it signals that the
--  cancellation proofs or the underlying ℕ arithmetic have changed.
-- ════════════════════════════════════════════════════════════════════

private
  -- Left cancellation:  3 + 2 ≡ 3 + 2  →  2 ≡ 2
  cancel-left-test : +-cancelˡ 3 {2} {2} refl ≡ refl
  cancel-left-test = refl

  -- Right cancellation:  2 + 3 ≡ 2 + 3  →  2 ≡ 2
  cancel-right-test : +-cancelʳ 3 {2} {2} refl ≡ refl
  cancel-right-test = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Congruence helper for addition
-- ════════════════════════════════════════════════════════════════════
--
--  When the parameterized observable computes a sum of bond weights:
--
--    S-param w regN0N1 = w bCN0 +ℚ w bCN1
--
--  and we need to show that replacing  w  by  perturb w b δ  changes
--  (or preserves) this sum, we often need congruence lemmas of the
--  form:
--
--    a₁ ≡ a₂  →  b₁ ≡ b₂  →  a₁ + b₁ ≡ a₂ + b₂
--
--  This is a direct consequence of  cong₂  from Prelude, but we
--  provide a named version for readability in downstream proofs.
-- ════════════════════════════════════════════════════════════════════

+-cong₂ : {a₁ a₂ b₁ b₂ : ℕ} → a₁ ≡ a₂ → b₁ ≡ b₂ → a₁ + b₁ ≡ a₂ + b₂
+-cong₂ p q i = p i + q i


-- ════════════════════════════════════════════════════════════════════
--  §7.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for downstream step-invariance modules:
--
--    +-comm     : ∀ m n   → m + n       ≡ n + m
--    +-assoc    : ∀ m n o → m + (n + o) ≡ (m + n) + o
--    +-zero     : ∀ m     → m + 0       ≡ m
--    +-suc      : ∀ m n   → m + suc n   ≡ suc (m + n)
--    injSuc     : suc m ≡ suc n         → m ≡ n
--    isSetℕ     : isSet ℕ
--    +-cancelˡ  : m + k₁ ≡ m + k₂      → k₁ ≡ k₂
--    +-cancelʳ  : k₁ + m ≡ k₂ + m      → k₁ ≡ k₂
--    +-cong₂    : a₁ ≡ a₂ → b₁ ≡ b₂   → a₁ + b₁ ≡ a₂ + b₂
--
--  Design decisions:
--
--    1.  This module does NOT import  Util/Scalars.agda  or any
--        Bond/Region types.  It is a pure ℕ arithmetic utility,
--        independent of the holographic topology.  The  perturb
--        function and its specification lemmas (perturb-self,
--        perturb-other) belong in the modules that define  perturb
--        (Boundary/StarCutParam.agda or Bridge/StarStepInvariance.agda).
--
--    2.  The cancellation lemmas duplicate the private definitions
--        in  Bridge/FullEnrichedStarObs.agda .  This is deliberate:
--        the step-invariance modules should not depend on the
--        enriched bridge infrastructure.  If a future refactor
--        wishes to eliminate the duplication, FullEnrichedStarObs
--        can import from here — but that is not required for the
--        current milestone.
--
--    3.  All re-exported lemmas use  public  so that a single
--        import  open import Util.NatLemmas  in a downstream
--        module provides the complete arithmetic toolkit.
--
--    4.  The module uses  --guardedness  in the OPTIONS pragma
--        for consistency with all other src/ modules in the
--        repository, even though no coinductive types appear here.
--
--  Conditions for advancement (§11.12 of docs/10-frontier.md):
--
--    "The ℕ arithmetic lemmas needed for parameterized reasoning
--     have been curated and tested in a  Util/NatLemmas.agda
--     module."
--
--  This module satisfies that condition.  The next step is
--  Boundary/StarCutParam.agda (item 2 of §11.7).
-- ════════════════════════════════════════════════════════════════════