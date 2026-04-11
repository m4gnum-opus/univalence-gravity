# The Holographic Bridge

**Formal content:** Discrete Ryu–Takayanagi correspondence, enriched type equivalence, Univalence transport, and the Generic Bridge theorem.

**Primary modules:** `Bridge/GenericBridge.agda`, `Bridge/EnrichedStarObs.agda`, `Bridge/FullEnrichedStarObs.agda`, `Bridge/EnrichedStarEquiv.agda`, `Bridge/GenericValidation.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry)

---

## 1. Overview

The holographic bridge is the central construction of the repository. It connects two independently defined observable packages — boundary min-cut entropy and bulk minimal separating chain length — via an exact type equivalence in Cubical Agda, with verified computational transport along the resulting Univalence path.

The construction evolved through three stages:

1. **Concrete bridges** (star, filled patches): hand-written equivalences between specific observable types, establishing the pattern.
2. **Enriched bridges** (star patch): full structural-property conversion (subadditivity ↔ monotonicity) through transport, demonstrating nontrivial `ua` content.
3. **Generic bridge** (`GenericBridge.agda`): a single parameterized proof that subsumes all instances, factoring the architecture into a reusable kernel instantiated by the Python oracle.

This document traces the mathematical development through all three stages.

---

## 2. The Discrete Ryu–Takayanagi Correspondence

### 2.1 The Physical Claim

The Ryu–Takayanagi formula (2006) asserts that in the AdS/CFT correspondence, the entanglement entropy S(A) of a boundary region A equals the area of the minimal bulk surface homologous to A, measured in Planck units:

> S(A) = Area(γ_A) / 4G_N

The discrete analogue, formalized in this repository, replaces smooth surfaces with combinatorial min-cuts:

> S_cut(A) = L_min(A)

where S_cut is the boundary min-cut entropy (max-flow through the tensor network) and L_min is the bulk minimal separating chain length (total weight of the cheapest set of bonds/faces disconnecting A from its complement).

### 2.2 The Pointwise Agreement Path

For each concrete patch, the Python oracle computes both S_cut and L_min for every boundary region and confirms they agree. The Agda formalization encodes both as lookup tables (or orbit-representative lookups) returning the same ℕ literals, so agreement holds by `refl` at each region:

```agda
-- Bridge/StarObs.agda
star-pointwise : (r : Region) →
  S-cut (π∂ starSpec) r ≡ L-min (πbulk starSpec) r
star-pointwise regN0   = refl
star-pointwise regN1   = refl
  ...
star-pointwise regN4N0 = refl
```

The `refl` proofs work because both observable functions return canonical constants (`1q`, `2q`) defined once in `Util/Scalars.agda` and imported by both the boundary and bulk modules. Identical normal forms are the computational foundation of every bridge in the repository.

Function extensionality assembles pointwise agreement into a single path:

```agda
-- Bridge/StarEquiv.agda
star-obs-path : S-cut (π∂ starSpec) ≡ L-min (πbulk starSpec)
star-obs-path = funExt star-pointwise
```

### 2.3 The Orbit Reduction Strategy

For large patches (717+ regions), pointwise agreement is proven on the small orbit type and lifted to the full region type in a single line:

```agda
-- Bridge/Dense100Obs.agda
d100-pointwise r = d100-pointwise-rep (classify100 r)
```

This works because both `S-cut` and `L-min` are *defined* as their orbit-representative versions composed with the classification function:

```agda
S-cut _ r = S-cut-rep (classify100 r)
L-min _ r = L-min-rep (classify100 r)
```

The 717-clause classification function is traversed only during concrete evaluation; the proof obligations remain on the 8-constructor orbit type.

---

## 3. The Enriched Type Equivalence

### 3.1 Specification-Agreement Types

The raw observable path `S∂ ≡ LB` connects two *values* of the same type `Region → ℚ≥0`. To exercise Univalence nontrivially, the bridge operates on *enriched types* — reversed singleton types centered at their respective specification functions:

```agda
-- Bridge/EnrichedStarObs.agda
EnrichedBdy : Type₀
EnrichedBdy = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ S∂)

EnrichedBulk : Type₀
EnrichedBulk = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ LB)
```

These are genuinely different types in the universe: `S∂` and `LB` are definitionally distinct functions (defined by separate pattern-matching clauses in separate modules). The specification-agreement field `f ≡ S∂` (resp. `f ≡ LB`) certifies that the carried observable matches a specific physical specification.

Both types are contractible (`Σ[ x ∈ A ] (x ≡ a)` is contractible for any `a`), but they are *not definitionally equal* — the equivalence between them is propositionally nontrivial and carries the content of the discrete RT correspondence through the Glue type.

### 3.2 The Iso Construction

The forward map appends `obs-path : S∂ ≡ LB` to the agreement witness, converting boundary certification into bulk certification:

```agda
enriched-iso : Iso EnrichedBdy EnrichedBulk
enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
  where
    fwd : EnrichedBdy → EnrichedBulk
    fwd (f , p) = f , p ∙ obs-path

    bwd : EnrichedBulk → EnrichedBdy
    bwd (f , q) = f , q ∙ sym obs-path
```

Round-trip proofs close because the specification-agreement fields are propositional: `Region → ℚ≥0` is a set (`isOfHLevelΠ 2 (λ _ → isSetℚ≥0)`), so any two paths `f ≡ S∂` are equal. The composed path `(p ∙ obs-path) ∙ sym obs-path` is propositionally equal to `p` by `isSetObs`.

### 3.3 Univalence Application

Promotion through the standard pipeline:

```agda
enriched-equiv   : EnrichedBdy ≃ EnrichedBulk
enriched-equiv   = isoToEquiv enriched-iso

enriched-ua-path : EnrichedBdy ≡ EnrichedBulk
enriched-ua-path = ua enriched-equiv
```

The resulting path `enriched-ua-path` is *not* propositionally equal to `refl` — unlike the trivial tree and star bridges that used `idEquiv`. The two types reference different specification functions, and the path threads `star-obs-path` through the Glue type.

### 3.4 Verified Transport

Transport along the Univalence path converts the boundary instance to the bulk instance:

```agda
enriched-transport :
  transport enriched-ua-path bdy-instance ≡ bulk-instance
```

The proof decomposes into two steps:

1. **`uaβ`** reduces transport to the forward map of the equivalence: `transport (ua e) x ≡ equivFun e x`.
2. **Contractibility** of `EnrichedBulk` identifies the forward map's output with `bulk-instance`: both are elements of the contractible type `Σ[ f ] (f ≡ LB)`.

This is the "compilation step": transport along the `ua` path is not stuck on an opaque postulate — it reduces via `uaβ` to a concrete function that rewires the specification-agreement witness through the discrete RT correspondence.

---

## 4. Full Enriched Equivalence (Structural Property Conversion)

### 4.1 Enriched Record Types

The full enriched types carry structural property witnesses alongside the specification agreement:

```agda
-- Bridge/FullEnrichedStarObs.agda
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
```

The boundary type carries a **subadditivity** witness: S(A∪B) ≤ S(A) + S(B). The bulk type carries a **monotonicity** witness: r₁ ⊆ r₂ → L(r₁) ≤ L(r₂). These are genuinely different structural properties — the type equivalence between `FullBdy` and `FullBulk` converts one into the other.

### 4.2 Derivation, Not Preservation

The structural property is *not* directly transported through the equivalence. Instead:

- The forward map **discards** the subadditivity witness and **derives** monotonicity from `LB-mono` via the new specification agreement `f ≡ LB`.
- The inverse map **discards** monotonicity and **derives** subadditivity from `S∂-subadd`.

This replacement is possible because both structural properties are *determined by* the specification-agreement field: if `f ≡ S∂`, then `f` inherits all properties of `S∂` via `subst`. The round-trip proofs close because both `Subadditive` and `Monotone` are propositional (`isPropSubadditive`, `isPropMonotone`), following from `isProp≤ℚ`.

### 4.3 Transport Converts Properties

```agda
full-transport :
  transport full-ua-path full-bdy ≡ full-bulk
```

Starting from `full-bdy = (S∂, refl, S∂-subadd)`, transport produces `full-bulk = (LB, refl, LB-mono)`. The observable function changes from `S∂` to `LB` (via `star-obs-path`), and the structural property changes from subadditivity to monotonicity. This is the type-theoretic content of the holographic duality: boundary structural properties become bulk structural properties through the bridge.

---

## 5. The Generic Bridge Theorem

### 5.1 Motivation

Every enriched equivalence in the repository has the same proof structure:

1. Define `S∂ LB : RegionTy → ℚ≥0`
2. Prove `obs-path : S∂ ≡ LB` via `funExt` of pointwise `refl`
3. Define enriched types as reversed singletons
4. Build `Iso` from `obs-path` + `isSet (RegionTy → ℚ≥0)`
5. `isoToEquiv` → `ua` → `transport` → `uaβ`

Steps 3–5 depend on **exactly three inputs**: a type `RegionTy`, two functions `S∂ LB`, and a path `obs-path`. Nothing about pentagons, cubes, curvature, or tiling geometry appears.

### 5.2 The PatchData Interface

```agda
-- Bridge/GenericBridge.agda
record PatchData : Type₁ where
  field
    RegionTy : Type₀
    S∂       : RegionTy → ℚ≥0
    LB       : RegionTy → ℚ≥0
    obs-path : S∂ ≡ LB
```

This is the minimal interface for any holographic patch. The region type may have 10 constructors (star) or 1885 (depth-7 layer) — the record is agnostic.

### 5.3 The Parameterized Module

```agda
module GenericEnriched (pd : PatchData) where
  open PatchData pd

  enriched-equiv     : EnrichedBdy ≃ EnrichedBulk
  enriched-ua-path   : EnrichedBdy ≡ EnrichedBulk
  enriched-transport : transport enriched-ua-path bdy-instance ≡ bulk-instance
  abstract-bridge-witness : BridgeWitness
```

This module is **written once, proven once, and never modified**. Every bridge in the repository is a specialization — no per-instance proof engineering.

The transport proof uses contractibility of reversed singletons:

```agda
enriched-transport =
  transport-computes ∙ isContr→isProp (isContr-Singl LB) _ _
```

where `isContr-Singl a .fst = a , refl` and the contraction uses `λ j → p (~ i ∨ j)`.

### 5.4 The Orbit-Reduced Interface

```agda
record OrbitReducedPatch : Type₁ where
  field
    RegionTy  : Type₀
    OrbitTy   : Type₀
    classify  : RegionTy → OrbitTy
    S-rep     : OrbitTy → ℚ≥0
    L-rep     : OrbitTy → ℚ≥0
    rep-agree : (o : OrbitTy) → S-rep o ≡ L-rep o
```

The `PatchData` is extracted automatically:

```agda
orbit-to-patch : OrbitReducedPatch → PatchData
orbit-to-patch orp = record
  { RegionTy = RegionTy
  ; S∂       = λ r → S-rep (classify r)
  ; LB       = λ r → L-rep (classify r)
  ; obs-path = funExt (λ r → rep-agree (classify r))
  }
```

The **one-function composition** `orbit-bridge-witness : OrbitReducedPatch → BridgeWitness` produces the full proof-carrying bridge witness from oracle-generated orbit data:

```agda
orbit-bridge-witness orp =
  GenericEnriched.abstract-bridge-witness (orbit-to-patch orp)
```

### 5.5 Retroactive Validation

Six pre-existing bridge instances are validated as instantiations of `GenericEnriched` in `Bridge/GenericValidation.agda`:

| Instance | RegionTy | #ctors | Strategy |
|----------|----------|--------|----------|
| Star | Region | 10 | PatchData |
| Filled | FilledRegion | 90 | PatchData |
| Honeycomb | H3Region | 26 | PatchData |
| Dense-50 | D50Region | 139 | PatchData |
| Dense-100 | D100Region | 717 | OrbitReducedPatch |
| Dense-200 | D200Region | 1246 | OrbitReducedPatch |

Six additional layer instances (depths 2–7) are produced by `orbit-bridge-witness` in `Bridge/SchematicTower.agda`, bringing the total to **twelve verified bridge instances** spanning 1D trees, 2D pentagonal tilings, and 3D cubic honeycombs.

---

## 6. The BridgeWitness Record

All bridge results are packaged into a single universal record:

```agda
-- Bridge/BridgeWitness.agda
record BridgeWitness : Type₁ where
  field
    BdyTy              : Type₀
    BulkTy             : Type₀
    bdy-data           : BdyTy
    bulk-data          : BulkTy
    bridge             : BdyTy ≃ BulkTy
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data
```

This record is the **Milestones 3–4 deliverable**: a machine-checked proof that boundary and bulk observable packages are exactly equivalent types, with verified computable transport.

The record is consumed by:
- `Bridge/SchematicTower.agda` (tower assembly)
- `Bridge/WickRotation.agda` (dS/AdS coherence)
- `Bridge/GenericValidation.agda` (retroactive consistency)

It is defined in its own leaf module (`Bridge/BridgeWitness.agda`) to break the dependency chain: generic infrastructure depends only on abstract interfaces, not on per-instance implementations.

---

## 7. Architectural Significance

### 7.1 Geometry Stays in Python; Proof Stays in Agda

The Python oracle (scripts 01–17 in `sim/prototyping/`) handles all combinatorial case enumeration: Coxeter reflections, BFS growth, max-flow computation, orbit classification. Agda checks the emitted `(k, refl)` witnesses individually.

### 7.2 The Bridge Is Geometrically Blind

The `GenericEnriched` module depends on exactly four inputs: `RegionTy`, `S∂`, `LB`, `obs-path`. Nothing about pentagons, cubes, hyperbolic geometry, curvature, dimension, gauge groups, or Coxeter reflections appears in the proof. This blindness explains:

- **Why the Wick rotation works** ([08-wick-rotation.md](08-wick-rotation.md)): the bridge is literally the same Agda term for both {5,4} and {5,3} tilings.
- **Why the 3D extension works** ([04-discrete-geometry.md](04-discrete-geometry.md)): the bridge is dimension-agnostic.
- **Why the gauge enrichment is orthogonal** ([05-gauge-theory.md](05-gauge-theory.md)): the bridge sees only scalar capacities, not gauge group structure.
- **Why the quantum lift is trivial** ([07-quantum-superposition.md](07-quantum-superposition.md)): the bridge is consumed by `cong₂` in a 5-line list induction.

### 7.3 One Proof, N Instances

Adding a new patch instance requires **zero new hand-written proof**. The workflow is:

1. Python oracle generates `OrbitReducedPatch` data (Spec, Cut, Chain, Obs modules).
2. `orbit-bridge-witness` produces the `BridgeWitness` automatically.
3. `Bridge/SchematicTower.agda` registers the new level via `mkTowerLevel`.

This is the division of labor used by the Four Color Theorem (Coq) and the Kepler Conjecture (HOL Light): external computation finds proofs, a simple kernel checks them.

---

## 8. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) |
| Discrete geometry (Gauss–Bonnet, curvature) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Orbit reduction (engineering) | [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) |
| Per-instance data sheets | [`instances/`](../instances/) |
| Step invariance and dynamics | [`formal/10-dynamics.md`](10-dynamics.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md) |