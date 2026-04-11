# Tree Pilot Instance

**The 7-vertex weighted binary tree — the first bridge calibration object.**

**Modules:** `Common/TreeSpec.agda`, `Boundary/TreeCut.agda`, `Bulk/TreeChain.agda`, `Bridge/TreeObs.agda`, `Bridge/TreeEquiv.agda` (dead code)

**Role:** Architecture validation. The tree pilot was the first end-to-end test of the common-source → views → observable packages → pointwise agreement → package path pipeline, before any 2D or 3D geometry was introduced.

---

## 1. Patch Overview

| Property | Value |
|----------|-------|
| **Dimension** | 1D (tree graph, no faces or curvature) |
| **Tiling** | Weighted binary tree |
| **Vertices** | 7 (L₁, L₂, R₁, R₂, A, B, Root) |
| **Edges** | 6 |
| **Boundary sites** | 4 (L₁, L₂, R₁, R₂) in cyclic order |
| **Representative regions** | 8 (4 singletons + 4 adjacent pairs) |
| **Min-cut range** | 1–2 |
| **Orbit representatives** | — (flat enumeration, no orbit reduction) |
| **Bridge strategy** | Flat `PatchData` via `GenericBridge` |
| **Curvature** | None (1D tree has no faces) |
| **Auto-generated?** | No — hand-written |

---

## 2. Topology

The tree pilot is a weighted binary tree with 4 boundary sites (leaves) and 3 interior nodes:

```
    L₁ ──(1)── A ──(2)── Root ──(2)── B ──(1)── R₁
                |                        |
    L₂ ──(1)──+                        +──(1)── R₂
```

**Vertices:**

| Vertex | Role | Degree |
|--------|------|--------|
| L₁ | Boundary (leaf) | 1 |
| L₂ | Boundary (leaf) | 1 |
| R₁ | Boundary (leaf) | 1 |
| R₂ | Boundary (leaf) | 1 |
| A | Interior | 3 |
| B | Interior | 3 |
| Root | Interior | 2 |

**Edges and weights:**

| Edge | Weight | Role |
|------|--------|------|
| L₁–A | 1 | Left branch (leaf) |
| L₂–A | 1 | Left branch (leaf) |
| A–Root | 2 | Central spine |
| Root–B | 2 | Central spine |
| B–R₁ | 1 | Right branch (leaf) |
| B–R₂ | 1 | Right branch (leaf) |

The boundary ordering is cyclic: L₁, L₂, R₁, R₂. The tree has a left-right mirror symmetry exchanging {L₁, L₂, A} with {R₁, R₂, B} while fixing Root.

---

## 3. Boundary Regions

For the cyclic ordering L₁, L₂, R₁, R₂, the nonempty proper contiguous intervals comprise:

- **4 singletons:** {L₁}, {L₂}, {R₁}, {R₂}
- **4 adjacent pairs:** {L₁,L₂}, {L₂,R₁}, {R₁,R₂}, {R₂,L₁}
- **4 triples** (omitted — complement of a singleton, same min-cut value)

The 8-constructor `Region` type in `Common/TreeSpec.agda` covers all singletons and adjacent pairs. Triples are omitted because each is the complement of a singleton and carries the same min-cut value by complement symmetry S(A) = S(Ā).

---

## 4. Min-Cut / Observable Agreement Table

| Region | Tiles | Minimal Separator | S_cut | L_min | S = L? |
|--------|-------|-------------------|-------|-------|--------|
| {L₁} | 1 | {L₁–A} | 1 | 1 | ✓ `refl` |
| {L₂} | 1 | {L₂–A} | 1 | 1 | ✓ `refl` |
| {R₁} | 1 | {B–R₁} | 1 | 1 | ✓ `refl` |
| {R₂} | 1 | {B–R₂} | 1 | 1 | ✓ `refl` |
| {L₁,L₂} | 2 | {A–Root} | 2 | 2 | ✓ `refl` |
| {L₂,R₁} | 2 | {L₂–A}, {B–R₁} | 2 | 2 | ✓ `refl` |
| {R₁,R₂} | 2 | {Root–B} | 2 | 2 | ✓ `refl` |
| {R₂,L₁} | 2 | {L₁–A}, {B–R₂} | 2 | 2 | ✓ `refl` |

All 8 pointwise agreement cases hold by `refl` because both `S-cut` and `L-min` return the same canonical ℕ constants (`1q` or `2q`) imported from `Util/Scalars.agda`. The `refl` proofs depend on both sides reducing to identical normal forms — guaranteed by the shared-constants discipline (constants defined once in `Util/Scalars.agda` and imported everywhere).

**Min-cut value distribution:**

| Min-cut value | Count |
|---------------|-------|
| S = 1 | 4 regions (singletons) |
| S = 2 | 4 regions (pairs) |

---

## 5. Observable Packages

The tree pilot uses the shared `ObsPackage` record from `Common/ObsPackage.agda`:

```agda
record ObsPackage (R : Type₀) : Type₀ where
  field
    obs : R → ℚ≥0
```

The region index `R = Region` is a parameter (not a stored field), keeping `ObsPackage Region` in `Type₀`. The single `obs` field carries the observable function.

**Boundary package:**

```agda
Obs∂ : TreeSpec → ObsPackage Region
Obs∂ c .ObsPackage.obs = S-cut (π∂ c)
```

**Bulk package:**

```agda
ObsBulk : TreeSpec → ObsPackage Region
ObsBulk c .ObsPackage.obs = L-min (πbulk c)
```

Both packages wrap the same underlying lookup tables — the boundary and bulk views are structurally identical for this 1D pilot. The architectural purpose is to validate the interface contract (views produce packages, packages produce paths) before the 2D instance introduces genuinely different structure.

---

## 6. Bridge Construction

**Pointwise agreement** (`Bridge/TreeObs.agda`):

```agda
tree-pointwise : (r : Region) →
  S-cut (π∂ treeSpec) r ≡ L-min (πbulk treeSpec) r
tree-pointwise regL₁   = refl
tree-pointwise regL₂   = refl
  ...
tree-pointwise regR₂L₁ = refl
```

**Function path** (`Bridge/TreeEquiv.agda`):

```agda
tree-obs-path : S-cut (π∂ treeSpec) ≡ L-min (πbulk treeSpec)
tree-obs-path = funExt tree-pointwise
```

**Package path** (`Bridge/TreeEquiv.agda`):

```agda
tree-package-path : Obs∂ treeSpec ≡ ObsBulk treeSpec
tree-package-path i .ObsPackage.obs = tree-obs-path i
```

**Generic bridge integration** (`Bridge/GenericValidation.agda`):

The tree pilot is retroactively validated as an instantiation of `GenericEnriched` via the `PatchData` interface. The tree's `PatchData` is constructed from the boundary and bulk observable functions and `tree-obs-path`, then fed to `GenericEnriched` to produce a full `BridgeWitness` with enriched type equivalence, Univalence path, and verified transport — all automatically, without per-instance proof engineering.

---

## 7. Scalar Representation

The tree pilot uses `ℚ≥0 = ℕ` from `Util/Scalars.agda`:

| Constant | ℕ value | Used for |
|----------|---------|----------|
| `1q` | `suc zero` | Singleton min-cuts, leaf edge weights |
| `2q` | `suc (suc zero)` | Pair min-cuts, spine edge weights |

The judgmental computation of ℕ addition (`zero + n = n`, `suc m + n = suc (m + n)`) enables all `refl`-based proofs: both sides of each equality reduce to the same ℕ literal without any explicit arithmetic reasoning.

**Critical invariant:** The constants `1q` and `2q` are defined **once** in `Util/Scalars.agda` and imported by both `Boundary/TreeCut.agda` and `Bulk/TreeChain.agda`. If either module reconstructed these constants independently (e.g., by computing `suc zero` via a different path), the normal forms might diverge and `refl` would fail.

---

## 8. Module Inventory

| Module | Lines | Content | Hand-written? |
|--------|-------|---------|---------------|
| `Common/TreeSpec.agda` | ~80 | `Vertex`, `Edge`, `Region`, `TreeSpec`, `treeSpec`, `treeWeight` | Yes |
| `Boundary/TreeCut.agda` | ~55 | `BoundaryView`, `π∂`, `S-cut` (8-clause lookup) | Yes |
| `Bulk/TreeChain.agda` | ~55 | `BulkView`, `πbulk`, `L-min` (8-clause lookup) | Yes |
| `Bridge/TreeObs.agda` | ~50 | `ObsPackage` (import), `Obs∂`, `ObsBulk`, `tree-pointwise` (8 refls) | Yes |
| `Bridge/TreeEquiv.agda` | ~15 | `tree-obs-path`, `tree-package-path` | Yes (dead code) |

**Total:** ~255 lines of hand-written Agda across 5 modules.

The `Bridge/TreeEquiv.agda` module is marked as **dead code** — it is architecturally superseded by the generic bridge (`Bridge/GenericBridge.agda`) but remains valid as a historical artifact from the initial development. The tree's `BridgeWitness` is now produced by `GenericEnriched` via `Bridge/GenericValidation.agda`.

---

## 9. What the Tree Pilot Validates

The tree instance was designed to test each step of the bridge architecture in a controlled, fully finite setting:

| Step | What it tests | Validated? |
|------|---------------|------------|
| 1. Finite carrier types | `Vertex` (7 ctors), `Edge` (6 ctors), `Region` (8 ctors) | ✓ |
| 2. Scalar constants | `1q`, `2q` from `Util/Scalars.agda` — shared, judgmentally stable | ✓ |
| 3. Common source | `TreeSpec` record with `boundaryOrder` and `edgeWeight` | ✓ |
| 4. View extraction | `π∂ : TreeSpec → BoundaryView`, `πbulk : TreeSpec → BulkView` | ✓ |
| 5. Observable lookup | `S-cut` and `L-min` as specification-level lookup tables | ✓ |
| 6. Pointwise agreement | `tree-pointwise` — 8 cases, all `refl` | ✓ |
| 7. Function path | `tree-obs-path = funExt tree-pointwise` | ✓ |
| 8. Package path | `tree-package-path` — single-field record path | ✓ |
| 9. Generic bridge | `GenericEnriched` produces `BridgeWitness` automatically | ✓ |

---

## 10. What the Tree Pilot Does NOT Exercise

The tree instance is intentionally limited. It does **not** test:

- **Nontrivial Univalence.** Both observable packages produce the same underlying type (`Region → ℚ≥0`), making the equivalence `idEquiv` and the `ua` path trivially `refl`. A nontrivial `ua` step requires enriched packages with asymmetric proof-carrying fields — exercised first by the 6-tile star patch ([`instances/star-patch.md`](star-patch.md)).

- **Face/curvature data.** The tree is 1-dimensional — no faces, no polygon complex, no curvature. Curvature requires the 11-tile filled patch ([`instances/filled-patch.md`](filled-patch.md)) with its 2D polygon complex.

- **Heterogeneous index types.** Both sides share the same `Region` type. Genuinely different domain types (e.g., 10-constructor boundary vs. 5-constructor bulk bond type) are exercised by the raw structural equivalence modules.

- **Non-trivial proof-carrying fields.** The `ObsPackage` record has a single field (`obs`). Subadditivity and monotonicity witnesses are added in `Bridge/FullEnrichedStarObs.agda`.

- **Orbit reduction.** The tree has only 8 regions — far below the threshold (~500) where orbit reduction becomes necessary. Orbit reduction is first used by Dense-100 ([`instances/dense-100.md`](dense-100.md)).

- **Auto-generated modules.** All tree modules are hand-written. The Python oracle + `abstract` barrier pattern is first used by the filled patch ([`instances/filled-patch.md`](filled-patch.md)).

These limitations are **by design**: the tree pilot validates the packaging and bridge machinery in the simplest possible setting. Each limitation is addressed by a subsequent instance in the progression: tree → star → filled → honeycomb → Dense-50 → Dense-100 → Dense-200 → layer tower.

---

## 11. Historical Significance

The tree pilot is the repository's **first bridge calibration object** — the term introduced in §14 of the historical development docs (`historical/development-docs/08-tree-instance.md`). Its role is methodological, not physically ambitious:

> "This tree instance is not physically ambitious. Its importance is methodological. It is the first place where the repository can test, in a controlled and fully finite setting, the exact pattern that later phases depend on: one source specification, two extracted views, shared region indexing, equal observables, a direct package path."

The tree pilot was completed during Phase 1 of the roadmap (Mathematical Prototyping) and served as the gate review criterion for proceeding to Phase 2 (Boundary + Bulk formalization):

> "Exercise (d) type-checks. The developer can explain, on paper, the difference between `transport`, `subst`, and `PathP`, and can construct a simple equivalence and apply `ua` without consulting documentation for every step."

After the tree pilot succeeded, the project scaled to the 6-tile star patch (the second calibration object), which introduced pentagonal tile structure, 5-fold symmetry, and the first nontrivial min-cut patterns.

---

## 12. Relationship to Subsequent Instances

The tree pilot is the base case of the instance progression:

| Instance | What it adds beyond the previous |
|----------|----------------------------------|
| **Tree pilot** (this) | Architecture validation (1D, trivial bridge) |
| [Star (6-tile)](star-patch.md) | 2D tiling, nontrivial enriched equiv, `ua` + transport |
| [Filled (11-tile)](filled-patch.md) | Gauss–Bonnet, subadditivity (360 cases), `abstract` barrier |
| [Honeycomb (3D)](honeycomb-3d.md) | 3D dimension, edge curvature |
| [Dense-50](dense-50.md) | Greedy growth, min-cut range 1–7 |
| [Dense-100](dense-100.md) | Orbit reduction (717 → 8), first orbit-based bridge |
| [Dense-200](dense-200.md) | Third tower level, monotonicity 8 → 9 |
| [Layer-54 tower](layer-54-tower.md) | 6 BFS depths, exponential growth, constant orbit count |
| [De Sitter patch](desitter-patch.md) | Positive curvature, curvature-agnostic bridge (Wick rotation) |

The tree's `ObsPackage` record is shared by all subsequent instances via `Common/ObsPackage.agda`. The tree's `Region` type (8 constructors) and lookup-table observable pattern are the templates for all later instances — just with more constructors and, for large patches, the orbit reduction strategy.

---

## 13. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (refl, funExt, ua) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Holographic bridge (generic architecture) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Star patch (next instance) | [`instances/star-patch.md`](star-patch.md) |
| Historical development (full specification) | [`historical/development-docs/08-tree-instance.md`](../historical/development-docs/08-tree-instance.md) |
| Building & type-checking | [`getting-started/building.md`](../getting-started/building.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |