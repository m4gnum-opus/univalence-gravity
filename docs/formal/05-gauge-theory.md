# Gauge Theory

**Formal content:** Finite gauge groups, the quaternion group Q₈, gauge connections on the holographic network, Wilson loop holonomy, particle defects as topological excitations, conjugacy class classification of particle species, representation-dimension capacity extraction, and the gauge-enriched bridge.

**Primary modules:** `Gauge/FiniteGroup.agda`, `Gauge/ZMod.agda`, `Gauge/Q8.agda`, `Gauge/Connection.agda`, `Gauge/Holonomy.agda`, `Gauge/ConjugacyClass.agda`, `Gauge/RepCapacity.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry), [03-holographic-bridge.md](03-holographic-bridge.md) (generic bridge architecture)

---

## 1. Overview

The gauge layer enriches the holographic network with algebraic structure — group elements on bonds, Wilson loops around faces, and topological defects interpretable as discrete matter — without modifying any existing bridge, curvature, or causal module. It is the formal content of **Theorem 6** (Matter as Topological Defects) in the canonical registry ([01-theorems.md](01-theorems.md)).

In continuum physics, matter fields are sections of vector bundles associated to the principal gauge bundle over spacetime; in lattice gauge theory (Wilson 1974), this reduces to assigning group elements to lattice links and computing holonomies around plaquettes. The repository implements the discrete, finite analogue: bonds carry elements of a finite group G, holonomy is the ordered product around a face boundary, and a **particle** is a face where the holonomy is not the identity.

The key architectural property is **orthogonality**: the gauge layer is purely additive. The bridge ([03-holographic-bridge.md](03-holographic-bridge.md)) sees only scalar capacities extracted by the dimension functor, not the internal gauge-algebraic structure. This means the holographic correspondence S = L coexists with gauge matter without any modification to the bridge proof — gauge enrichment and the RT formula operate on independent layers of the same geometric substrate.

---

## 2. The Constructive Lie Group Problem and Its Resolution

### 2.1 The Problem

The Standard Model gauge group SU(3) × SU(2) × U(1) is a continuous compact Lie group. Its elements are complex unitary matrices. Cubical Agda has no robust library for complex analysis, unitary matrix groups, or Lie algebras — formalizing any of these would be a multi-year effort comparable to Lean's `mathlib`.

### 2.2 The Resolution: Finite Subgroup Replacement

On a *finite discrete graph*, there is no mathematical obligation to use continuous groups. The gauge field is a finite assignment of elements to bonds — the group can be any group. The repository replaces each factor of the Standard Model gauge group with a well-studied finite subgroup:

| Continuum Factor | Finite Replacement | Order | Irreps (dims) |
|---|---|---|---|
| U(1) | ℤ/nℤ (cyclic) | n | n irreps, all dim 1 |
| SU(2) | Q₈ (quaternion) | 8 | 5 irreps: 1,1,1,1,2 |

Every group axiom is verified by exhaustive case split on closed constructor terms, with all cases holding by `refl`. This requires zero smooth analysis and zero constructive ℂ.

**Mathematical precedent.** Finite subgroups of SU(2) and SU(3) have been used in lattice QCD computations since Bhanot & Creutz (1981). The discrete gauge theory on a finite graph is not an approximation of the continuum theory — it IS the gauge theory at the lattice scale.

---

## 3. The FiniteGroup Record

The foundational type is the `FiniteGroup` record from `Gauge/FiniteGroup.agda`:

```agda
record FiniteGroup : Type₁ where
  field
    Carrier      : Type₀
    ε            : Carrier                     -- identity
    _·_          : Carrier → Carrier → Carrier -- multiplication
    inv          : Carrier → Carrier           -- inverse

    isSetCarrier : isSet Carrier
    _≟_          : Discrete Carrier            -- decidable equality

    ·-identityˡ  : (x : Carrier) → ε · x ≡ x
    ·-identityʳ  : (x : Carrier) → x · ε ≡ x
    ·-inverseˡ   : (x : Carrier) → inv x · x ≡ ε
    ·-inverseʳ   : (x : Carrier) → x · inv x ≡ ε
    ·-assoc      : (x y z : Carrier) → (x · y) · z ≡ x · (y · z)
```

**Design decisions:**

1. **`isSetCarrier`** ensures h-level discipline: downstream function spaces `Bond → G.Carrier` are sets, enabling the enriched bridge architecture to work.
2. **Decidable equality (`_≟_`)** is needed for `ParticleDefect` — deciding whether a holonomy equals the identity is a computable proposition for finite groups.
3. **All axioms by `refl`** on closed constructor terms: for concrete instances (ℤ/2, ℤ/3, Q₈), every axiom clause reduces judgmentally because pattern matching on finite datatype constructors is deterministic.

---

## 4. Concrete Group Instances

### 4.1 ℤ/2ℤ — The Simplest Gauge Group

The carrier `Z2` has two constructors `e0` (identity) and `e1` (generator). Multiplication is addition mod 2. Every element is self-inverse. The `ℤ/2 : FiniteGroup` instance has:

- 0 cases for left identity (wildcard — `e0 +Z2 y = y` definitionally)
- 2 cases each for right identity, left inverse, right inverse
- 4 cases for associativity

Total: 10 cases, all `refl`.

### 4.2 ℤ/3ℤ — The First Non-Trivial Inverse

The carrier `Z3` has constructors `z0`, `z1`, `z2`. The inverse map is non-trivial: `inv z1 = z2 ≠ z1`. This gives 3 conjugacy classes (vacuum + 2 charge types) — the first group with genuinely distinct particle species.

- 15 cases for associativity (3 wildcard + 12 explicit)
- 9 cases for decidable equality (3 `yes refl` + 6 discriminator-based `no`)

Both ℤ/2 and ℤ/3 are proven **abelian** (commutative) in `Gauge/ZMod.agda`:

```agda
Z2-comm : (x y : Z2) → x +Z2 y ≡ y +Z2 x    -- 4 cases, all refl
Z3-comm : (x y : Z3) → x +Z3 y ≡ y +Z3 x    -- 9 cases, all refl
```

For abelian groups, every conjugacy class is a singleton — simplifying particle species classification in `Gauge/ConjugacyClass.agda`.

### 4.3 Q₈ — The Quaternion Group

The carrier `Q8` has 8 constructors: `q1 qn1 qi qni qj qnj qk qnk` (representing {1, −1, i, −i, j, −j, k, −k}). The fundamental quaternion relations hold:

```agda
check-ii : qi *Q8 qi ≡ qn1     -- i² = −1
check-ij : qi *Q8 qj ≡ qk      -- ij = k
check-ji : qj *Q8 qi ≡ qnk     -- ji = −k  (≠ ij!)
```

Q₈ is the first **non-abelian** gauge group in the repository. The `Q₈ : FiniteGroup` instance has:

- 1 wildcard case for left identity (`q1 *Q8 y = y`)
- 8 cases each for right identity, left inverse, right inverse
- **400 cases for associativity** (8³ = 512 total, reduced to 400 by wildcard optimization)

All 400 associativity cases hold by `refl` — a 400-line exhaustive verification that type-checks in Agda, confirming the full quaternion multiplication table is associative.

A non-commutativity witness is exported:

```agda
Q8-noncomm : (qi *Q8 qj ≡ qj *Q8 qi) → ⊥
```

The proof uses a discriminator function mapping `qk` to an inhabited type and `qnk` to `⊥`, then `subst` along the hypothetical path `qk ≡ qnk`.

---

## 5. Gauge Connections

### 5.1 The GaugeConnection Record

A gauge connection assigns a group element to each bond of the network:

```agda
record GaugeConnection (G : FiniteGroup) (BondTy : Type₀) : Type₀ where
  field
    assign : BondTy → FiniteGroup.Carrier G
```

### 5.2 Bond Traversal Direction

Each bond has a fixed forward orientation. When computing holonomy around a face, some bonds are traversed forward and some in reverse:

```agda
data Dir : Type₀ where
  fwd rev : Dir

readBond : GaugeConnection G BondTy → Dir → BondTy → G.Carrier
readBond conn fwd b = assign conn b
readBond conn rev b = inv G (assign conn b)
```

The convention `g_ē = inv(g_e)` for reversed bonds is the standard lattice gauge theory formulation.

### 5.3 The Flat (Vacuum) Connection

The flat connection assigns the identity ε to every bond:

```agda
flatConnection : (G : FiniteGroup) → GaugeConnection G BondTy
flatConnection G .assign _ = ε G
```

A flat connection has trivial holonomy around every face — it is "empty space" with no matter content.

### 5.4 Concrete Connections on the Star Patch

Three concrete connections are defined on the 5-bond star patch (Bond from `Common/StarSpec.agda`):

- **`starFlatZ2`** — all bonds → `e0` (vacuum)
- **`starNontrivZ2`** — `bCN0 → e1`, rest → `e0` (one excited ℤ/2 bond)
- **`starQ8-i`** — `bCN0 → qi`, rest → `q1` (single Q₈ excitation)
- **`starQ8-ij`** — `bCN0 → qi`, `bCN1 → qj`, rest → `q1` (two Q₈ bonds)
- **`starQ8-ji`** — `bCN0 → qj`, `bCN1 → qi`, rest → `q1` (swapped order)

---

## 6. Holonomy and Particle Defects

### 6.1 Wilson Loop Computation

The holonomy (Wilson loop) around a face with directed boundary `[(b₁,d₁), …, (bₙ,dₙ)]` is the ordered group product:

```agda
holonomy : GaugeConnection G BondTy → List (BondTy × Dir) → G.Carrier
holonomy ω []              = ε
holonomy ω ((b , d) ∷ rest) = readBond ω d b · holonomy ω rest
```

This is a right fold starting from the identity ε.

### 6.2 Flatness

A connection is flat if the holonomy around every face equals the identity:

```agda
isFlat : GaugeConnection G BondTy → (FaceTy → List (BondTy × Dir)) → Type₀
isFlat ω ∂f = (f : _) → holonomy ω (∂f f) ≡ ε
```

### 6.3 ParticleDefect — Matter as Topological Excitation

A **particle** at a face is a configuration where the holonomy is NOT the identity:

```agda
ParticleDefect : GaugeConnection G BondTy → List (BondTy × Dir) → Type₀
ParticleDefect ω boundary = holonomy ω boundary ≡ ε → ⊥
```

This is a negation of a path, hence automatically a proposition (`isProp` of negation types). For finite groups with decidable equality, it is a decidable proposition.

### 6.4 Concrete Defect Witnesses

The central pentagon of the star patch has a 5-bond boundary `centralFaceBdy`. The following results are machine-checked:

**ℤ/2 flat connection:** holonomy = `e0` = ε. No defect.

```agda
holonomy-flat-Z2 : holonomy starFlatZ2 centralFaceBdy ≡ e0
holonomy-flat-Z2 = refl

flat-Z2-isFlat : isFlat starFlatZ2 starBoundary
flat-Z2-isFlat centralFace = refl
```

**ℤ/2 non-trivial connection:** holonomy = `e1` ≠ ε. **DEFECT!**

```agda
holonomy-nontrivZ2 : holonomy starNontrivZ2 centralFaceBdy ≡ e1
holonomy-nontrivZ2 = refl

defect-Z2 : ParticleDefect starNontrivZ2 centralFaceBdy
defect-Z2 p = e1≢e0 p
```

This is the first machine-checked topological defect (non-trivial Wilson loop) on a holographic tensor network.

**Q₈ connections — non-commutativity:**

```agda
holonomy-Q8-ij : holonomy starQ8-ij centralFaceBdy ≡ qk      -- ij = k
holonomy-Q8-ji : holonomy starQ8-ji centralFaceBdy ≡ qnk     -- ji = −k

noncommutative-holonomy :
  holonomy starQ8-ij centralFaceBdy ≡ holonomy starQ8-ji centralFaceBdy → ⊥
```

Swapping the bond assignments (i↔j) changes the holonomy from `qk` to `qnk` — the discrete manifestation of non-abelian gauge theory.

---

## 7. Conjugacy Classes and Particle Species

### 7.1 The Conjugacy Relation

Two group elements g and h are conjugate if there exists k with `inv(k) · g · k ≡ h`:

```agda
_~G_ : Carrier → Carrier → Type₀
g ~G h = Σ[ k ∈ Carrier ] ((inv k · g) · k ≡ h)
```

The **species** of a particle is the conjugacy class of the holonomy — the gauge-invariant notion of particle type.

### 7.2 Abelian Groups: Trivial Conjugacy

For abelian (commutative) groups, conjugation is the identity operation:

```agda
abelian-self-conjugate :
  ((x y : Carrier) → x · y ≡ y · x)
  → (g k : Carrier) → (inv k · g) · k ≡ g
```

The proof composes 5 steps: `·-assoc`, `comm`, `sym ·-assoc`, `·-inverseˡ`, `·-identityˡ`. For concrete abelian groups (ℤ/2, ℤ/3), all 5 steps are `refl`, so the composed path is also `refl` — verified by regression tests.

### 7.3 Q₈ Conjugacy Classes

Q₈ has **5 conjugacy classes**:

| Class | Elements | Representative | Description |
|---|---|---|---|
| cc-1 | {q1} | q1 | vacuum (identity) |
| cc-n1 | {qn1} | qn1 | center element (−1) |
| cc-i | {qi, qni} | qi | ±i pair |
| cc-j | {qj, qnj} | qj | ±j pair |
| cc-k | {qk, qnk} | qk | ±k pair |

The non-trivial identifications are witnessed by explicit conjugating elements:

```agda
conj-i-ni : Conj._~G_ Q₈ qi qni
conj-i-ni = qj , refl       -- inv(j) · i · j = −i

conj-j-nj : Conj._~G_ Q₈ qj qnj
conj-j-nj = qi , refl       -- inv(i) · j · i = −j

conj-k-nk : Conj._~G_ Q₈ qk qnk
conj-k-nk = qi , refl       -- inv(i) · k · i = −k
```

All three witnesses type-check as `refl` because the Q₈ multiplication table reduces judgmentally on closed constructor terms.

**Particle spectrum:** 5 total classes − 1 identity = **4 particle species**.

### 7.4 Species Classification

The `sameSpecies` predicate identifies particles by conjugacy class:

```agda
sameSpeciesQ8 : Q8 → Q8 → Type₀
sameSpeciesQ8 g h = classifyQ8 g ≡ classifyQ8 h

species-i-ni : sameSpeciesQ8 qi qni     -- ✓ same species (both cc-i)
species-i≢j  : sameSpeciesQ8 qi qj → ⊥  -- ✗ different species
```

Two holonomies produce the same particle type iff their conjugacy classes agree, regardless of the specific conjugating element.

---

## 8. Representation Capacity and the Dimension Functor

### 8.1 The Observable Collapse Problem

The standard holographic observables S and L are ℕ-valued min-cuts computed by summing bond weights. If bonds carry group representations (not numbers), the summation is undefined.

### 8.2 The Resolution: The Dimension Functor

Each bond is labeled by an irreducible representation ρ of G. The **capacity** is `dim(ρ) : ℕ`:

```agda
mkCapacity : {BondTy RepTy : Type₀}
  → (RepTy → ℕ) → (BondTy → RepTy) → BondTy → ℚ≥0
mkCapacity dim label b = dim (label b)
```

For Q₈, the 2-dimensional fundamental representation gives bond capacity 2:

```agda
data Q8Rep : Type₀ where
  q8-triv q8-sgn-i q8-sgn-j q8-sgn-k q8-fund : Q8Rep

dimQ8 : Q8Rep → ℕ
dimQ8 q8-fund = 2          -- the 2-dim fundamental

starQ8Capacity : Bond → ℚ≥0
starQ8Capacity = mkCapacity dimQ8 (λ _ → q8-fund)   -- all bonds → dim 2
```

### 8.3 The Dimension-Weighted Bridge

With capacity 2 per bond, the min-cut values double:

- Singletons: S = 2 (cut 1 bond of capacity 2)
- Pairs: S = 4 (cut 2 bonds of capacity 2)

The pointwise agreement `S-cut-dim2 ≡ L-min-dim2` holds by `refl` on all 10 regions. The `PatchData` is constructed and fed to `GenericEnriched`, which produces a full `BridgeWitness` — confirming that the generic bridge handles non-unit capacities without modification:

```agda
dimWeightedBridge : BridgeWitness
dimWeightedBridge = DimGeneric.abstract-bridge-witness
```

---

## 9. The GaugedPatchWitness — Holographic Spacetime with Matter

The capstone of the gauge layer packages the bridge, the connection, and the matter content into a single record:

```agda
record GaugedPatchWitness (G : FiniteGroup) : Type₁ where
  field
    bridge-witness : BridgeWitness
    connection     : GaugeConnection G Bond
    face-boundary  : StarFace → List (Bond × Dir)
    defect-face    : StarFace
    defect-proof   : ParticleDefect connection (face-boundary defect-face)
```

The concrete instance for Q₈:

```agda
gauged-star-Q8 : GaugedPatchWitness Q₈
gauged-star-Q8 .bridge-witness = dimWeightedBridge    -- capacity-2 bridge
gauged-star-Q8 .connection     = starQ8-i             -- bCN0 = i
gauged-star-Q8 .defect-face    = centralFace          -- holonomy = i ≠ 1
gauged-star-Q8 .defect-proof   = defect-Q8-i
```

This is the first machine-checked holographic spacetime with matter: a discrete network where the holographic correspondence (bridge) coexists with a non-trivial gauge field (connection) producing a topological defect (particle) at a specified face.

---

## 10. The Three-Layer Architecture

The gauge enrichment follows an explicit three-layer stack, each orthogonal to the others:

```
┌─────────────────────────────────────────────────────────┐
│  GAUGE LAYER                                            │
│  FiniteGroup → ZMod / Q8 → Connection → Holonomy        │
│  → ConjugacyClass → ParticleDefect                      │
│                                                         │
│  Defines: group elements on bonds, Wilson loops,        │
│  topological defects (matter)                           │
├─────────────────────────────────────────────────────────┤
│  CAPACITY LAYER                                         │
│  RepCapacity: dim functor extracts ℕ-valued capacities  │
│  from representation labels                             │
│                                                         │
│  Converts: gauge structure → scalar bond weights        │
├─────────────────────────────────────────────────────────┤
│  BRIDGE LAYER (UNCHANGED)                               │
│  GenericBridge operates on PatchData (scalar weights)   │
│  — completely unaware of the gauge group                │
│                                                         │
│  Proves: S = L for any weight function                  │
└─────────────────────────────────────────────────────────┘
```

The bridge layer sees only scalar capacities extracted by the dimension functor. This is the architectural content of the claim that the holographic correspondence is **gauge-agnostic**: the bridge theorem is parameterized by abstract `PatchData`, not by gauge-group-specific structure.

---

## 11. What This Does and Does Not Prove

### Proven (constructive, machine-checked)

- Finite gauge groups (ℤ/2, ℤ/3, Q₈) with all axioms verified by `refl`
- Non-abelian holonomies on the discrete network (ij ≠ ji for Q₈)
- Inhabited `ParticleDefect` types — the first machine-checked "particles" on a tensor network
- Conjugacy class classification with 5 Q₈ classes verified
- The bridge is compatible with gauge-group enrichment: `dimWeightedBridge` type-checks with capacity > 1
- The `GaugedPatchWitness` packaging: bridge + connection + defect in one record

### NOT proven

- **No fermionic matter.** The gauge-theory construction describes gauge bosons and topological charges; true fermions require Grassmann-valued path integrals and lattice Dirac operators.
- **No gauge dynamics.** The Wilson action S_W = β Σ_f (1 − Re Tr W_f / N) is not formalized; the gauge field is a static assignment.
- **No spontaneous symmetry breaking.** The Higgs mechanism requires a scalar field minimizing a potential.
- **No continuum limit.** The passage from Q₈ to SU(2) requires n → ∞ limits on group order.

These are the correct conceptual boundary between the discrete formalization and the continuum Standard Model.

---

## 12. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorem 6 |
| Holographic bridge (gauge-agnostic) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Quantum superposition bridge | [`formal/07-quantum-superposition.md`](07-quantum-superposition.md) |
| Wick rotation (curvature-agnostic) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md) |
| Physics dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Translation problem (five walls) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Historical development (§13 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §13 |