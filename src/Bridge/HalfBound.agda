{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.HalfBound where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc ; _+_)
open import Cubical.Data.Sigma
  using (Σ-syntax)

open import Util.Scalars
open import Util.NatLemmas using (+-comm ; +-assoc)
open import Bridge.GenericBridge using (PatchData)


record HalfBoundWitness (pd : PatchData) : Type₀ where
  open PatchData pd
  field
    area       : RegionTy → ℚ≥0
    half-bound : (r : RegionTy)
               → (S∂ r +ℚ S∂ r) ≤ℚ area r
    tight      : Σ[ r ∈ RegionTy ]
                   (S∂ r +ℚ S∂ r ≡ area r)


two-le-sum : {s a b : ℕ} → s ≤ℚ a → s ≤ℚ b → (s +ℚ s) ≤ℚ (a +ℚ b)
two-le-sum {s} {a} {b} (k₁ , p₁) (k₂ , p₂) =
  k₁ + k₂ , rearrange ∙ cong₂ _+_ p₁ p₂
  where
    rearrange : (k₁ + k₂) + (s + s) ≡ (k₁ + s) + (k₂ + s)
    rearrange =
        sym (+-assoc k₁ k₂ (s + s))
      ∙ cong (k₁ +_) (+-assoc k₂ s s)
      ∙ +-assoc k₁ (k₂ + s) s
      ∙ cong (_+ s) (cong (k₁ +_) (+-comm k₂ s) ∙ +-assoc k₁ s k₂)
      ∙ sym (+-assoc (k₁ + s) k₂ s)


from-two-cuts :
  {RegionTy : Type₀}
  (S∂ area n-cross n-bdy : RegionTy → ℚ≥0)
  → ((r : RegionTy) → area r ≡ n-cross r +ℚ n-bdy r)
  → ((r : RegionTy) → S∂ r ≤ℚ n-cross r)
  → ((r : RegionTy) → S∂ r ≤ℚ n-bdy r)
  → (r : RegionTy) → (S∂ r +ℚ S∂ r) ≤ℚ area r
from-two-cuts S∂ area nc nb decomp le-cross le-bdy r =
  subst ((S∂ r +ℚ S∂ r) ≤ℚ_) (sym (decomp r))
        (two-le-sum (le-cross r) (le-bdy r))


private

  test-two-le : (3 +ℚ 3) ≤ℚ (5 +ℚ 4)
  test-two-le = two-le-sum {3} {5} {4} (2 , refl) (1 , refl)

  test-two-le-fst : fst test-two-le ≡ 3
  test-two-le-fst = refl

  test-tight : (3 +ℚ 3) ≤ℚ (3 +ℚ 3)
  test-tight = two-le-sum {3} {3} {3} (0 , refl) (0 , refl)

  test-tight-fst : fst test-tight ≡ 0
  test-tight-fst = refl

  test-halfbound-value : 3 +ℚ 3 ≡ 6
  test-halfbound-value = refl

  test-halfbound-slack : (1 +ℚ 1) ≤ℚ 6
  test-halfbound-slack = 4 , refl

  test-from-two-cuts :
    from-two-cuts {ℕ}
      (λ _ → 3) (λ _ → 9) (λ _ → 5) (λ _ → 4)
      (λ _ → refl) (λ _ → (2 , refl)) (λ _ → (1 , refl))
      0 .fst
    ≡ 3
  test-from-two-cuts = refl