# Foundations: HoTT, Univalence, and Cubical Agda

This document provides the mathematical background in Homotopy Type Theory (HoTT) and Cubical Agda needed to read the formal content of the repository. It is not a textbook introduction — it focuses specifically on the concepts, primitives, and proof patterns that appear in the `src/` modules.

**Prerequisites.** Familiarity with dependent type theory at the level of "a type can depend on a term" and "a proof is a term inhabiting a proposition type." No prior knowledge of HoTT or cubical methods is assumed.

**Primary references.**
- The Univalent Foundations Program, *Homotopy Type Theory: Univalent Foundations of Mathematics* (The HoTT Book), 2013.
- Cohen, Coquand, Huber, Mörtberg, "Cubical Type Theory: A Constructive Interpretation of the Univalence Axiom," 2018 (the CCHM paper).
- Vezzosi, Mörtberg, Abel, "Cubical Agda: A Dependently Typed Programming Language with Univalence and Higher Inductive Types," 2021.

---

## 1. Types as Spaces

In HoTT, every type `A : Type` is interpreted as a *space* (more precisely, an ∞-groupoid). The inhabitants `a : A` are *points* of that space. The identity type `a ≡ b` (a path from `a` to `b`) is itself a type — its inhabitants are *paths* between points. Paths between paths are *homotopies*, and so on.

This stratified structure gives every type a natural **homotopy level** (also called truncation level):

| h-level | Name | Meaning | Example in the repo |
|---------|------|---------|---------------------|
| −2 | Contractible | Exactly one point, up to paths | `Σ[ f ∈ (R → ℚ≥0) ] (f ≡ S∂)` — reversed singleton |
| −1 | Proposition | At most one point, up to paths | `m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)` — proved propositional by `isProp≤ℚ` |
| 0 | Set | Path space is propositional | `ℕ`, `ℤ`, `Region`, `Bond`, all finite data types |
| 1 | Groupoid | Path-of-path space is propositional | `Type₀` itself (the universe) |

**Why this matters for the repository.** The h-level discipline determines which equalities are automatic:

- **Sets** (h-level 0): Any two proofs `p q : a ≡ b` are themselves equal (`isSet` says the path space is propositional). This is why `isProp≤ℚ` works — once you know `m ≤ n`, there is essentially one way to know it. All scalar types (`ℚ≥0 = ℕ`, `ℚ₁₀ = ℤ`), all finite data types (`Region`, `Bond`, `Q8`, etc.), and all function spaces into sets (`Region → ℚ≥0`) are sets.

- **Propositions** (h-level −1): Any two inhabitants are equal. The `abstract` barrier seals proofs of propositional types without losing information — if `_≤ℚ_` is propositional, then sealing the proof term prevents re-normalization while guaranteeing that any other proof of the same fact would be equal to it.

- **Contractible types** (h-level −2): There is exactly one point. The enriched types `EnrichedBdy = Σ[ f ∈ (R → ℚ≥0) ] (f ≡ S∂)` are contractible (reversed singletons), which is exploited in the generic bridge proof to close the transport step via `isContr→isProp`.

---

## 2. Paths in Cubical Agda

Standard (Book) HoTT postulates the identity type and its eliminator (J). Cubical Agda takes a different approach: paths are *functions from the interval*.

### 2.1 The Interval and PathP

Cubical Agda has a built-in abstract interval type with two endpoints `i0` and `i1`. A **path** from `a` to `b` in type `A` is a function `p : I → A` with `p i0 ≡ a` and `p i1 ≡ b` (judgmentally). The type of such paths is written:

```
PathP (λ i → A) a b
```

When `A` does not depend on `i`, this simplifies to the familiar:

```
a ≡ b   =   PathP (λ _ → A) a b
```

**In the repository:** The path `star-obs-path : S∂ ≡ LB` is a function `I → (Region → ℚ≥0)` that at `i0` returns the boundary observable `S∂` and at `i1` returns the bulk observable `LB`. Transport along this path is the "holographic translator."

### 2.2 refl, sym, and Path Composition

- **`refl`**: The constant path `λ i → a : a ≡ a`. In the repository, `star-pointwise regN0 = refl` works because `S-cut (π∂ starSpec) regN0` and `L-min (πbulk starSpec) regN0` both reduce to the same ℕ literal `1`. The path is literally the constant function.

- **`sym`**: Path reversal. `sym p = λ i → p (~ i)`, where `~` is the interval involution (`~ i0 = i1`, `~ i1 = i0`).

- **`_∙_`**: Path composition. `p ∙ q` connects the endpoint of `p` to the startpoint of `q`. Used throughout the bridge proofs: `FullBdy.spec a ∙ star-obs-path` appends the RT path to the specification-agreement witness.

### 2.3 funExt — Function Extensionality

In Cubical Agda, function extensionality is a *theorem*, not an axiom:

```agda
funExt : {f g : A → B} → ((x : A) → f x ≡ g x) → f ≡ g
funExt h i x = h x i
```

The pointwise paths `h x : f x ≡ g x` are assembled into a single function-level path by swapping the interval variable `i` inside the lambda.

**In the repository:** Every `obs-path` in the bridge modules is constructed by `funExt` of pointwise `refl` proofs:

```agda
star-obs-path : S∂ ≡ LB
star-obs-path = funExt star-pointwise
```

This is the discrete Ryu–Takayanagi correspondence packaged as a single path between functions.

### 2.4 cong and cong₂

Path congruence — applying a function to a path:

```agda
cong  : (f : A → B) → a ≡ b → f a ≡ f b
cong₂ : (f : A → B → C) → a₁ ≡ a₂ → b₁ ≡ b₂ → f a₁ b₁ ≡ f a₂ b₂
```

**In the repository:** The quantum bridge theorem (`Quantum/QuantumBridge.agda`) is a 5-line proof that uses only `refl`, `cong`, and `cong₂`:

```agda
quantum-bridge alg []             S L eq = refl
quantum-bridge alg ((ω , α) ∷ ψ) S L eq =
  cong₂ _+A_
    (cong (_·A_ α) (cong embedℕ (eq ω)))
    (quantum-bridge alg ψ S L eq)
```

No ring axioms are needed — just the automatic congruence of functions in cubical type theory.

---

## 3. Transport

Given a type family `P : A → Type` and a path `p : a ≡ b`, transport produces a function:

```agda
transport : {A : Type} → (P : A → Type) → a ≡ b → P a → P b
```

This is HoTT's version of "moving data along an equality." Transport is the mechanism by which a proof that two types are equivalent becomes a *computable function* converting inhabitants of one to inhabitants of the other.

**In the repository:** The central "compilation step" is:

```agda
enriched-transport :
  transport enriched-ua-path bdy-instance ≡ bulk-instance
```

This says: transporting the boundary observable bundle along the Univalence path produces the bulk observable bundle. The `uaβ` computation rule (§5) ensures this transport actually *computes* — it reduces to the forward map of the equivalence.

### 3.1 subst

A common special case of transport where the type family is applied to a specific variable position:

```agda
subst : (P : A → Type) → a ≡ b → P a → P b
```

**In the repository:** Used for deriving structural properties from specification agreement:

```agda
derive-subadd : (f : Region → ℚ≥0) → f ≡ S∂ → Subadditive f
derive-subadd f p = subst Subadditive (sym p) S∂-subadd
```

If `f ≡ S∂` and `S∂` is subadditive, then `f` is subadditive by transporting the subadditivity witness along the reversed path.

### 3.2 isProp→PathP

When the fibers of a dependent path are propositional, any two sections are connected by a dependent path:

```agda
isProp→PathP : ((i : I) → isProp (B i)) → (b₀ : B i0) → (b₁ : B i1)
             → PathP B b₀ b₁
```

**In the repository:** Used in the enriched bridge to connect the specification-agreement witnesses across the `obs-path`:

```agda
isProp→PathP
  (λ j → isSetObs (star-obs-path j) LB)
  (refl ∙ star-obs-path)
  refl
```

The path between `refl ∙ star-obs-path` and `refl` exists because paths in a set are propositional.

---

## 4. Equivalences

An **equivalence** `A ≃ B` is a function `f : A → B` together with a proof that `f` has contractible fibers — for every `b : B`, the type `Σ[ a ∈ A ] (f a ≡ b)` is contractible.

In practice, equivalences are constructed by first building an **Iso** (a bijection with explicit inverse and round-trip proofs), then promoting it:

```agda
record Iso (A B : Type) : Type where
  field
    fun     : A → B
    inv     : B → A
    rightInv : (b : B) → fun (inv b) ≡ b
    leftInv  : (a : A) → inv (fun a) ≡ a

isoToEquiv : Iso A B → A ≃ B
```

**In the repository:** Every bridge module constructs an `Iso` between enriched types, then promotes it:

```agda
enriched-iso : Iso EnrichedBdy EnrichedBulk
enriched-equiv : EnrichedBdy ≃ EnrichedBulk
enriched-equiv = isoToEquiv enriched-iso
```

The forward map appends `obs-path` to the boundary agreement witness; the inverse appends `sym obs-path`. Round-trip proofs close because `Region → ℚ≥0` is a set (`isSetObs`), making all specification-agreement paths propositional.

---

## 5. The Univalence Axiom

For a universe `Type₀`, the canonical map

```
idtoeqv : (A ≡ B) → (A ≃ B)
```

sends a path between types to the equivalence obtained by transporting along it. The **Univalence Axiom** asserts that `idtoeqv` is itself an equivalence:

```agda
ua : A ≃ B → A ≡ B
```

In words: to give a path (identity) between two types in the universe is *exactly* to give an equivalence between them. This is far stronger than classical isomorphism: once the equivalence is exhibited, *every* property, construction, and theorem about `A` automatically transfers to `B` — by transport.

### 5.1 ua and uaβ in Cubical Agda

In Cubical Agda, `ua` is not a postulate — it is implemented via **Glue types**, giving it genuine computational content. The key computation rule is:

```agda
uaβ : (e : A ≃ B) → (a : A) → transport (ua e) a ≡ equivFun e a
```

This says: transporting along the `ua` path is the same as applying the forward map of the equivalence. Transport *computes*.

**In the repository:** This is the "compilation step" that makes the holographic bridge operational:

```agda
transport-computes :
  transport enriched-ua-path bdy-instance
  ≡ equivFun enriched-equiv bdy-instance
transport-computes = uaβ enriched-equiv bdy-instance
```

The boundary observable bundle, when transported through the Univalence path, produces the forward map applied to the boundary data — which then equals the bulk observable bundle by contractibility of the target type.

### 5.2 The Univalence Caveat

Univalence does not assert that any two vaguely related structures are identical. It asserts that *equivalent types in the same universe* are identical. The hard work is constructing the equivalence: exhibiting the forward map, the inverse, and the coherent round-trip proofs. For the holographic bridge, this is where 99% of the mathematical effort lives — the `obs-path` (discrete Ryu–Takayanagi correspondence) is the non-trivial content; `ua` and `transport` are the delivery mechanism.

---

## 6. The Scalar Representation and Judgmental Computation

A distinctive feature of this repository's proof architecture is the reliance on **judgmental equality** — equalities that hold by computation, before any proof term is constructed. This is the reason all pointwise agreement proofs are `refl`.

### 6.1 ℚ≥0 = ℕ

The nonnegative scalar type (`Util/Scalars.agda`) is implemented as bare natural numbers:

```agda
ℚ≥0 : Type₀
ℚ≥0 = ℕ
```

Natural number addition `_+_` computes by structural recursion on the left argument:

```
zero  + n = n        (definitional)
suc m + n = suc (m + n)   (definitional)
```

This means `1 + 1` reduces to `2` *judgmentally* — the type-checker computes this without any proof term. The pointwise agreement `S-cut (π∂ starSpec) regN0 ≡ L-min (πbulk starSpec) regN0` holds by `refl` because both sides reduce to the literal `1`.

### 6.2 ℚ₁₀ = ℤ

The signed rational type for curvature (`Util/Rationals.agda`) represents n/10 as the integer n:

```agda
ℚ₁₀ : Type₀
ℚ₁₀ = ℤ
```

All curvature values for the {5,4} and {5,3} tilings have denominators dividing 10, so this representation is exact. The Gauss–Bonnet proof `totalCurvature ≡ χ₁₀` holds by `refl` because the class-weighted ℤ sum normalizes judgmentally to `pos 10`.

### 6.3 The Shared-Constants Discipline

The `refl`-based proof strategy requires that both sides of each equality reduce to *the same normal form*. This means scalar constants must be defined **once** in a utility module and imported everywhere:

```agda
-- Util/Scalars.agda
1q : ℚ≥0
1q = 1

2q : ℚ≥0
2q = 2
```

Both `Boundary/StarCut.agda` (defining `S-cut`) and `Bulk/StarChain.agda` (defining `L-min`) import `1q` and `2q` from the same source. If either module reconstructed `1q` independently (e.g., by computing `suc zero` via a different path), the normal forms might diverge and `refl` would fail.

This is not a theoretical concern — it is a practical constraint enforced by the repository's module structure. See [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) for cases where this discipline interacts with the `abstract` keyword.

---

## 7. The Generic Bridge Pattern

The architectural core of the repository is a single parameterized proof that every `PatchData` record admits a full enriched type equivalence. Understanding this pattern requires combining all the concepts above.

### 7.1 PatchData — The Abstract Interface

```agda
record PatchData : Type₁ where
  field
    RegionTy : Type₀
    S∂       : RegionTy → ℚ≥0
    LB       : RegionTy → ℚ≥0
    obs-path : S∂ ≡ LB
```

This captures the *minimum* data for the holographic bridge: a region type, two observable functions, and a path between them. Nothing about geometry, curvature, dimension, or gauge groups appears.

### 7.2 The Proof in 30 Lines

Given any `PatchData pd`, the `GenericEnriched` module (`Bridge/GenericBridge.agda`) constructs:

1. **Enriched types**: `EnrichedBdy = Σ[ f ] (f ≡ S∂)` and `EnrichedBulk = Σ[ f ] (f ≡ LB)` — reversed singleton types (contractible).

2. **Iso**: Forward map appends `obs-path`; inverse appends `sym obs-path`. Round-trips close by `isSetObs` (the function space `RegionTy → ℚ≥0` is a set because `ℚ≥0 = ℕ` is a set).

3. **Equiv**: `isoToEquiv enriched-iso`.

4. **ua path**: `ua enriched-equiv : EnrichedBdy ≡ EnrichedBulk`.

5. **Transport**: `uaβ` reduces `transport` to the forward map; `isContr→isProp` of the contractible target type closes the gap to `bulk-instance`.

6. **BridgeWitness**: All data packaged into a single record.

This module is written **once** and instantiated at each concrete patch by the Python oracle.

### 7.3 Why Contractibility Matters

Both `EnrichedBdy` and `EnrichedBulk` are reversed singleton types `Σ[ x ∈ A ] (x ≡ a)`, which are contractible. The contractibility proof:

```agda
isContr-Singl : (a : A) → isContr (Σ[ x ∈ A ] (x ≡ a))
isContr-Singl a .fst = a , refl
isContr-Singl a .snd (x , p) i = p (~ i) , λ j → p (~ i ∨ j)
```

This is used in the transport step: since `EnrichedBulk` is contractible, any two of its inhabitants are equal (`isContr→isProp`). Therefore the forward map output and `bulk-instance` are automatically identified — no further path algebra needed.

---

## 8. What Cubical Agda Is NOT

Several common misconceptions about the formalization framework:

- **Not standard Agda `Id` types.** The repository uses Cubical Agda's native `PathP` and `≡`, not the standard library's propositional identity type `Id`. The `--cubical` flag is required.

- **Not the standard library.** All imports are from `agda/cubical` (e.g., `Cubical.Foundations.Prelude`), never from `agda-stdlib`.

- **Not postulated Univalence.** In Cubical Agda, `ua` computes via Glue types. The `uaβ` reduction rule is a *theorem*, not an axiom. This is what makes transport genuinely computational — the "holographic translator" is an extractable program, not a postulated existence.

- **Not cohesive HoTT.** The cohesive modalities (flat ♭, sharp ♯, shape ∫) are not used. All constructions are finite and combinatorial, living in ordinary Cubical Agda without smooth or continuous structure. Cohesive HoTT is a conceptual horizon for future work involving smooth geometry, but it is not on the critical path. See [`physics/five-walls.md`](../physics/five-walls.md) for the hard boundaries.

---

## 9. Further Reading

| Topic | Reference | Relevance |
|-------|-----------|-----------|
| HoTT fundamentals | HoTT Book, Chapters 1–4 | Identity types, transport, equivalences, Univalence |
| Cubical Type Theory | CCHM 2018 | Interval, PathP, Glue types, computational ua |
| Cubical Agda | Vezzosi–Mörtberg–Abel 2021 | Implementation details, --cubical flag, HITs |
| h-levels and truncation | HoTT Book, Chapter 7 | isProp, isSet, propositional truncation |
| Function extensionality | HoTT Book, §4.9 | funExt as a theorem in cubical |

For the specific proof patterns used in this repository (oracle-generated `(k, refl)` witnesses, `abstract` barriers, orbit reduction, the `PatchData` interface), see:

- [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) — the one-proof-many-instances architecture
- [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) — why `abstract` is safe for propositional proofs
- [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) — factoring proofs through small orbit types
- [`formal/01-theorems.md`](01-theorems.md) — the canonical theorem registry with type signatures