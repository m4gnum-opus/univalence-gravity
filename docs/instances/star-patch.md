# Star Patch Instance

**The 6-tile {5,4} pentagonal star — the primary bridge target and the second calibration object.**

**Modules:** `Common/StarSpec.agda`, `Boundary/StarCut.agda`, `Boundary/StarSubadditivity.agda`, `Boundary/StarCutParam.agda`, `Bulk/StarChain.agda`, `Bulk/StarChainParam.agda`, `Bulk/StarMonotonicity.agda`, `Bridge/StarObs.agda`, `Bridge/StarEquiv.agda`, `Bridge/EnrichedStarObs.agda`, `Bridge/FullEnrichedStarObs.agda`, `Bridge/EnrichedStarEquiv.agda`, `Bridge/StarStepInvariance.agda`, `Bridge/StarDynamicsLoop.agda`, `Bridge/EnrichedStarStepInvariance.agda`

**Role:** The 6-tile star is the first instance on a genuine 2D hyperbolic tiling. It exercises nontrivial Univalence transport (converting subadditivity into monotonicity), parameterized step-invariance dynamics, the generic bridge factorization, the Wick rotation (shared bridge with the {5,3} dS patch), the gauge layer (Q₈ connections and particle defects), and the quantum superposition bridge. It is the most heavily exercised single patch in the repository.

---

## 1. Patch Overview

| Property | Value |
|----------|-------|
| **Dimension** | 2D (pentagonal tiling) |
| **Tiling** | {5,4} hyperbolic (regular pentagons, 4 meeting at each vertex) |
| **Tiles** | 6 (1 central C + 5 edge-neighbours N₀…N₄) |
| **Internal bonds** | 5 (C–N₀, C–N₁, C–N₂, C–N₃, C–N₄) |
| **Boundary legs per tile** | C: 0, each Nᵢ: 4 |
| **Total boundary legs** | 20 |
| **Representative regions** | 10 (5 singletons + 5 adjacent pairs) |
| **Min-cut range** | 1–2 |
| **Orbit representatives** | — (flat enumeration, no orbit reduction) |
| **Bridge strategy** | Flat `PatchData` via `GenericBridge` |
| **Curvature** | Not directly on the star patch (requires the 11-tile filled patch for interior vertices) |
| **Auto-generated?** | No — hand-written |

---

## 2. Topology

The star patch consists of a central pentagon C surrounded by 5 edge-neighbouring pentagons N₀…N₄. Each Nᵢ shares exactly one pentagon edge with C. The patch is the simplest connected HaPPY network with a nontrivial central tile.

```
         N₄
          |
    N₃ ── C ── N₀
        / |
      N₂  N₁
```

**Tiles:**

| Tile | Role | Boundary legs |
|------|------|---------------|
| C | Central | 0 (all 5 edges shared) |
| N₀ | Edge-neighbour | 4 |
| N₁ | Edge-neighbour | 4 |
| N₂ | Edge-neighbour | 4 |
| N₃ | Edge-neighbour | 4 |
| N₄ | Edge-neighbour | 4 |

**Bonds and weights:**

| Bond | Tiles | Weight | Role |
|------|-------|--------|------|
| bCN0 | C–N₀ | 1 | Shared pentagon edge |
| bCN1 | C–N₁ | 1 | Shared pentagon edge |
| bCN2 | C–N₂ | 1 | Shared pentagon edge |
| bCN3 | C–N₃ | 1 | Shared pentagon edge |
| bCN4 | C–N₄ | 1 | Shared pentagon edge |

All bonds have uniform weight 1, matching the standard HaPPY code where each shared pentagon edge carries one unit of entanglement capacity. The bond graph is a star topology: the central tile connected to 5 leaves. The boundary ordering is cyclic: N₀, N₁, N₂, N₃, N₄.

**Limitations.** The star patch is NOT a proper 2D manifold with boundary: there are angular gaps between adjacent Nᵢ pentagons at each vertex of C. These gaps are where the gap-filler tiles G₀…G₄ of the 11-tile filled patch ([`instances/filled-patch.md`](filled-patch.md)) sit. Consequently, the star patch supports min-cut analysis (it has a well-defined flow graph) but not polygon-level curvature analysis. The curvature formalization requires the filled patch.

---

## 3. Boundary Regions

For the cyclic boundary ordering N₀, N₁, N₂, N₃, N₄, the nonempty proper contiguous tile-aligned intervals comprise:

- **5 singletons** (size 1): S = min(1, 4) = 1
- **5 adjacent pairs** (size 2): S = min(2, 3) = 2
- **5 triples** (size 3): S = min(3, 2) = 2 (complement of a pair)
- **5 quadruples** (size 4): S = min(4, 1) = 1 (complement of a singleton)

By complement symmetry S(A) = S(Ā), triples carry the same min-cut value as their complementary pairs, and quadruples the same as their complementary singletons. The 10-constructor `Region` type in `Common/StarSpec.agda` covers the 5 singletons and 5 adjacent pairs — all distinct min-cut values and all rotation-distinct region shapes.

The full 20-constructor `StarRegion` type in `Boundary/StarSubadditivity.agda` extends this to include triples and quadruples for the subadditivity proof.

---

## 4. Min-Cut / Observable Agreement Table

| Region | Tiles | Minimal Separator | S_cut | L_min | S = L? |
|--------|-------|-------------------|-------|-------|--------|
| regN0 | {N₀} | Bond C–N₀ | 1 | 1 | ✓ `refl` |
| regN1 | {N₁} | Bond C–N₁ | 1 | 1 | ✓ `refl` |
| regN2 | {N₂} | Bond C–N₂ | 1 | 1 | ✓ `refl` |
| regN3 | {N₃} | Bond C–N₃ | 1 | 1 | ✓ `refl` |
| regN4 | {N₄} | Bond C–N₄ | 1 | 1 | ✓ `refl` |
| regN0N1 | {N₀, N₁} | Bonds C–N₀, C–N₁ | 2 | 2 | ✓ `refl` |
| regN1N2 | {N₁, N₂} | Bonds C–N₁, C–N₂ | 2 | 2 | ✓ `refl` |
| regN2N3 | {N₂, N₃} | Bonds C–N₂, C–N₃ | 2 | 2 | ✓ `refl` |
| regN3N4 | {N₃, N₄} | Bonds C–N₃, C–N₄ | 2 | 2 | ✓ `refl` |
| regN4N0 | {N₄, N₀} | Bonds C–N₄, C–N₀ | 2 | 2 | ✓ `refl` |

In every case, **boundary min-cut = bulk minimal chain length**. This is the discrete Ryu–Takayanagi correspondence for the 6-tile star instance: the min-cut always passes through internal bonds (never through boundary legs), so the boundary entanglement entropy exactly equals the bulk separating chain cost.

All 10 pointwise agreement proofs hold by `refl` because both `S-cut` and `L-min` return canonical constants (`1q`, `2q`) defined once in `Util/Scalars.agda` and imported into both modules.

**Min-cut value distribution:**

| Min-cut value | Count |
|---------------|-------|
| S = 1 | 5 regions (singletons) |
| S = 2 | 5 regions (pairs) |

**Formula:** S(k tiles) = min(k, 5 − k) for a contiguous region of k tiles on the 5-tile cyclic boundary.

**Numerical verification:** All 20 regions (including triples and quadruples by complement symmetry) verified by `sim/prototyping/01_happy_patch_cuts.py` — 20/20 symmetry checks passed, 30/30 subadditivity checks passed, S = geodesic for all 20 regions.

---

## 5. Structural Properties

### 5.1 Subadditivity (Boundary)

The boundary min-cut functional is subadditive: S(A ∪ B) ≤ S(A) + S(B) for all representable unions. This is proven in `Boundary/StarSubadditivity.agda` on the full 20-region `StarRegion` type (30 union triples, 4 distinct witnesses):

| Witness | Inequality | Cases |
|---------|-----------|-------|
| (0, refl) | 2 ≤ 1 + 1 = 2 | 5 |
| (1, refl) | 2 ≤ 1 + 2 = 3 or 2 ≤ 2 + 1 = 3 | 10 |
| (2, refl) | 1 ≤ 1 + 2 = 3 or 1 ≤ 2 + 1 = 3 | 10 |
| (3, refl) | 1 ≤ 2 + 2 = 4 | 5 |

### 5.2 Monotonicity (Bulk)

The bulk minimal-chain functional is monotone under subregion inclusion: r₁ ⊆ r₂ → L(r₁) ≤ L(r₂). This is proven in `Bulk/StarMonotonicity.agda` on the 10-region representative type (10 singleton-in-pair inclusions, all witnessed by `(1, refl)` for 1 ≤ 2).

### 5.3 Full Enriched Equivalence

The full enriched type equivalence converts subadditivity to monotonicity through transport:

```agda
full-equiv : FullBdy ≃ FullBulk
full-transport : transport full-ua-path full-bdy ≡ full-bulk
```

Starting from `full-bdy = (S∂, refl, S∂-subadd)`, transport produces `full-bulk = (LB, refl, LB-mono)`. The observable function changes from S∂ to LB, and the structural property changes from subadditivity to monotonicity. This is the type-theoretic content of the holographic duality: boundary structural properties become bulk structural properties through the bridge.

---

## 6. Bridge Construction

### 6.1 Basic Bridge

**Pointwise agreement** (`Bridge/StarObs.agda`):

```agda
star-pointwise : (r : Region) →
  S-cut (π∂ starSpec) r ≡ L-min (πbulk starSpec) r
star-pointwise regN0 = refl
  ...  -- 10 cases, all refl
```

**Function path** (`Bridge/StarEquiv.agda`):

```agda
star-obs-path : S-cut (π∂ starSpec) ≡ L-min (πbulk starSpec)
star-obs-path = funExt star-pointwise
```

### 6.2 Enriched Bridge

**Specification-agreement types** (`Bridge/EnrichedStarObs.agda`):

```agda
EnrichedBdy  = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ S∂)
EnrichedBulk = Σ[ f ∈ (Region → ℚ≥0) ] (f ≡ LB)

enriched-equiv : EnrichedBdy ≃ EnrichedBulk
enriched-ua-path : EnrichedBdy ≡ EnrichedBulk
enriched-transport : transport enriched-ua-path bdy-instance ≡ bulk-instance
```

Transport reduces via `uaβ` to the forward map, which appends `star-obs-path` to the agreement witness. The enriched types are genuinely different types in the universe (S∂ and LB are definitionally distinct), so the `ua` path is nontrivial.

### 6.3 Generic Bridge Integration

The star patch is retroactively validated as an instantiation of `GenericEnriched` in `Bridge/GenericValidation.agda`:

```agda
starPatchData : PatchData
star-generic-witness : BridgeWitness
star-generic-witness = GenericEnriched.abstract-bridge-witness starPatchData
```

This is the bridge witness consumed by `Bridge/WickRotation.agda` (the shared curvature-agnostic bridge) and `Bridge/SchematicTower.agda` (retroactive validation).

---

## 7. Dynamics

### 7.1 Parameterized Observables

`Boundary/StarCutParam.agda` and `Bulk/StarChainParam.agda` define `S-param` and `L-param` as functions of an arbitrary weight function `w : Bond → ℚ≥0`:

```agda
S-param w regN0   = w bCN0
S-param w regN0N1 = w bCN0 +ℚ w bCN1
```

The key structural fact: for the star topology, `S-param` and `L-param` are **definitionally the same function** — both defined by identical pattern-matching clauses. This is proven by:

```agda
SL-param-pointwise : (w : Bond → ℚ≥0) (r : Region) → S-param w r ≡ L-param w r
SL-param-pointwise w regN0 = refl    -- all 10 cases refl for variable w
```

### 7.2 Step Invariance (Theorem 9)

`Bridge/StarStepInvariance.agda` defines the `perturb` function (single-bond weight modification) and proves that the RT correspondence is preserved:

```agda
step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → ((r : Region) → S-param w r ≡ L-param w r)
  → ((r : Region) → S-param (perturb w b δ) r ≡ L-param (perturb w b δ) r)
```

### 7.3 Dynamics Loop (Theorem 9)

`Bridge/StarDynamicsLoop.agda` extends this by structural induction on a list of perturbation steps:

```agda
loop-invariant : (w₀ : Bond → ℚ≥0)
  → ((r : Region) → S-param w₀ r ≡ L-param w₀ r)
  → (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence w₀ steps) r
                   ≡ L-param (weight-sequence w₀ steps) r)
```

### 7.4 Enriched Step Invariance (Theorem 10)

`Bridge/EnrichedStarStepInvariance.agda` proves that the full enriched equivalence (including subadditivity ↔ monotonicity conversion via `+-comm`) holds for any weight function:

```agda
full-equiv-w : (w : Bond → ℚ≥0) → FullBdy-w w ≃ FullBulk-w w
```

---

## 8. Gauge Enrichment

The star patch is the primary target for the gauge layer ([`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md)):

### 8.1 Concrete Connections

Three concrete Q₈ connections are defined on the star's Bond type in `Gauge/Holonomy.agda`:

| Connection | Assignment | Holonomy at C | Defect? |
|-----------|-----------|---------------|---------|
| `starQ8-i` | bCN0 = qi, rest = q1 | qi | ✓ (qi ≢ q1) |
| `starQ8-ij` | bCN0 = qi, bCN1 = qj, rest = q1 | qk (ij = k) | ✓ |
| `starQ8-ji` | bCN0 = qj, bCN1 = qi, rest = q1 | qnk (ji = −k) | ✓ |

The non-commutativity witness: `holonomy starQ8-ij centralFaceBdy ≠ holonomy starQ8-ji centralFaceBdy` (k ≠ −k).

### 8.2 Dimension-Weighted Bridge

In `Gauge/RepCapacity.agda`, the Q₈ fundamental representation (dim = 2) labels all 5 bonds, giving capacity 2 per bond. The min-cut values double (singletons: S = 2, pairs: S = 4), and a `BridgeWitness` is produced via `GenericEnriched` for the dimension-weighted `PatchData` — confirming that the generic bridge handles non-unit capacities.

### 8.3 GaugedPatchWitness

The `gauged-star-Q8 : GaugedPatchWitness Q₈` record packages the dimension-weighted bridge, a Q₈ connection (`starQ8-i`), and a `ParticleDefect` at the central face into a single artifact — the first machine-checked holographic spacetime with matter.

---

## 9. Quantum Superposition

The star patch is the target for the quantum layer ([`formal/07-quantum-superposition.md`](../formal/07-quantum-superposition.md)):

```agda
star-quantum-bridge : (alg : AmplitudeAlg)
  → (ψ : Superposition (GaugeConnection Q₈ Bond) alg)
  → (r : Region)
  → 𝔼 alg ψ (λ ω → S-param starQ8Capacity r)
  ≡ 𝔼 alg ψ (λ ω → L-param starQ8Capacity r)
```

Verified with 2- and 3-configuration Q₈ superpositions with ℤ[i] amplitudes, including destructive interference (partial amplitude cancellation), with the bridge holding through the interference.

---

## 10. Wick Rotation

The star patch is the **shared** bridge for both the AdS ({5,4}) and dS ({5,3}) curvature regimes. The `WickRotationWitness` in `Bridge/WickRotation.agda` packages:

- `shared-bridge = star-generic-witness` (produced by `GenericBridge`, curvature-agnostic)
- `ads-gauss-bonnet = patch-gb-witness` (negative interior curvature κ = −1/5)
- `ds-gauss-bonnet = ds-patch-gb-witness` (positive interior curvature κ = +1/10)
- `euler-coherence = refl` (both target χ₁₀ = one₁₀ = pos 10)

The bridge is literally the same Agda term for both tilings. See [`instances/desitter-patch.md`](desitter-patch.md) and [`formal/08-wick-rotation.md`](../formal/08-wick-rotation.md).

---

## 11. Scalar Representation

The star patch uses `ℚ≥0 = ℕ` from `Util/Scalars.agda`:

| Constant | ℕ value | Used for |
|----------|---------|----------|
| `1q` | `suc zero` | Singleton min-cuts, bond weights |
| `2q` | `suc (suc zero)` | Pair min-cuts |

All `refl`-based proofs depend on both sides reducing to identical normal forms — guaranteed by the shared-constants discipline.

For the gauge-enriched bridge (Q₈ fundamental, dim = 2), capacity values are 2 and 4 (still ℕ, still `refl`-based).

---

## 12. Module Inventory

| Module | Lines | Content | Hand-written? |
|--------|-------|---------|---------------|
| `Common/StarSpec.agda` | ~90 | `Tile`, `Bond`, `Region`, `StarSpec`, `starSpec`, `starWeight` | Yes |
| `Boundary/StarCut.agda` | ~85 | `BoundaryView`, `π∂`, `S-cut` (10-clause lookup) | Yes |
| `Boundary/StarSubadditivity.agda` | ~200 | `StarRegion` (20 ctors), `_∪_≡_` (30 ctors), `subadditivity` (30 cases) | Yes |
| `Boundary/StarCutParam.agda` | ~80 | `S-param`, `S-param-spec` | Yes |
| `Bulk/StarChain.agda` | ~85 | `BulkView`, `πbulk`, `L-min` (10-clause lookup) | Yes |
| `Bulk/StarChainParam.agda` | ~90 | `L-param`, `SL-param-pointwise`, `SL-param` | Yes |
| `Bulk/StarMonotonicity.agda` | ~100 | `_⊆R_` (10 ctors), `monotonicity` (10 cases) | Yes |
| `Bridge/StarObs.agda` | ~50 | `Obs∂`, `ObsBulk`, `star-pointwise` (10 refls) | Yes |
| `Bridge/StarEquiv.agda` | ~15 | `star-obs-path` | Yes |
| `Bridge/EnrichedStarObs.agda` | ~200 | `EnrichedBdy`, `EnrichedBulk`, `enriched-equiv`, `enriched-ua-path`, `enriched-transport` | Yes |
| `Bridge/FullEnrichedStarObs.agda` | ~300 | `FullBdy`, `FullBulk`, `full-equiv`, `full-transport`, `isProp≤ℚ` | Yes |
| `Bridge/EnrichedStarEquiv.agda` | ~30 | `Theorem3`, `theorem3`, `BridgeWitness` (original home) | Yes |
| `Bridge/StarStepInvariance.agda` | ~180 | `perturb` (25 clauses), `step-invariant` | Yes |
| `Bridge/StarDynamicsLoop.agda` | ~120 | `weight-sequence`, `loop-invariant`, `star-loop` | Yes |
| `Bridge/EnrichedStarStepInvariance.agda` | ~160 | `full-equiv-w`, `enriched-step-invariant` | Yes |

**Total:** ~1,785 lines of hand-written Agda across 15 modules (the most of any single patch).

---

## 13. What the Star Patch Validates

The star patch exercises more of the repository's architecture than any other instance:

| Step | What it tests | First exercised? |
|------|---------------|-----------------|
| Finite carrier types | `Tile` (6 ctors), `Bond` (5 ctors), `Region` (10 ctors) | No (tree first) |
| Scalar constants | `1q`, `2q` from `Util/Scalars.agda` | No (tree first) |
| Common source spec | `StarSpec` record with 5-fold cyclic boundary | **Yes** |
| Pentagonal tile structure | {5,4} Schläfli type, star topology | **Yes** |
| 5-fold rotational symmetry | All 5 singletons equivalent, all 5 pairs equivalent | **Yes** |
| Nontrivial min-cut patterns | Complement symmetry S(A) = S(Ā) | **Yes** |
| Pointwise agreement (10 cases) | `star-pointwise` | **Yes** |
| Function path via `funExt` | `star-obs-path` | No (tree first) |
| Subadditivity (30 union triples) | `subadditivity` on `StarRegion` | **Yes** |
| Monotonicity (10 inclusions) | `monotonicity` on `_⊆R_` | **Yes** |
| `isProp≤ℚ` | Propositionality of the ordering type | **Yes** |
| Enriched type equivalence | `EnrichedBdy ≃ EnrichedBulk` with nontrivial `ua` | **Yes** |
| Full structural-property conversion | `FullBdy ≃ FullBulk` (subadd ↔ mono) | **Yes** |
| `uaβ` reduction | Transport computes via `uaβ` to the forward map | **Yes** |
| Generic bridge (`GenericEnriched`) | `star-generic-witness : BridgeWitness` | No (all 6 validated simultaneously) |
| Parameterized observables | `S-param`, `L-param` for variable `w` | **Yes** |
| Bond-weight perturbation | `perturb`, `step-invariant` | **Yes** |
| Iterated dynamics loop | `loop-invariant` (list induction) | **Yes** |
| Enriched step invariance | `full-equiv-w` using `+-comm` | **Yes** |
| Gauge connections (Q₈) | `starQ8-i`, `starQ8-ij`, `starQ8-ji` | **Yes** |
| Holonomy computation | Wilson loop folding over directed face boundary | **Yes** |
| `ParticleDefect` | Non-trivial holonomy (qi ≢ q1) | **Yes** |
| Non-commutativity | `holonomy(ij) ≠ holonomy(ji)` (qk ≠ qnk) | **Yes** |
| Conjugacy classes (Q₈) | 5 classes, species classification | **Yes** |
| Dimension-weighted bridge | Bond capacity 2 (Q₈ fundamental) | **Yes** |
| `GaugedPatchWitness` | Bridge + connection + defect in one record | **Yes** |
| Quantum superposition bridge | `star-quantum-bridge` for Q₈ + ℤ[i] | **Yes** |
| Destructive interference | 3-config ψ₃ with amplitude cancellation | **Yes** |
| Wick rotation (shared bridge) | `WickRotationWitness` with AdS + dS GB | **Yes** |

---

## 14. What the Star Patch Does NOT Exercise

- **Orbit reduction.** The star has only 10 regions — far below the threshold (~500) where orbit reduction is needed. Orbit reduction is first used by Dense-100 ([`instances/dense-100.md`](dense-100.md)).

- **`abstract` barrier.** The 30-case subadditivity proof in `StarSubadditivity.agda` is NOT sealed behind `abstract` — it is small enough to normalize quickly. The `abstract` pattern is first used by the 11-tile filled patch ([`instances/filled-patch.md`](filled-patch.md)) with 360 cases.

- **Auto-generated modules.** All star modules are hand-written. The Python oracle + `abstract` barrier pattern is first used by the filled patch.

- **3D geometry.** The star is 2D. The 3D extension to the {4,3,5} honeycomb is first exercised by the honeycomb BFS patch ([`instances/honeycomb-3d.md`](honeycomb-3d.md)).

- **Area law / Bekenstein–Hawking bound.** The area law S ≤ area and the half-bound 2·S ≤ area are first verified on Dense-100 ([`instances/dense-100.md`](dense-100.md)).

- **Causal structure.** The causal diamond and NoCTC theorem operate on the SchematicTower infrastructure, not on individual patches.

- **Polygon complex / curvature.** The star patch has angular gaps between adjacent N tiles — it is not a proper manifold with boundary. The curvature formalization requires the 11-tile filled patch.

---

## 15. Historical Significance

The star patch is the repository's **second bridge calibration object** — the 2D successor to the tree pilot ([`instances/tree-pilot.md`](tree-pilot.md)). It is described in detail in §5–§18 of `historical/development-docs/09-happy-instance.md`.

The star was chosen as the primary bridge formalization target (Theorem 3) for five reasons (§5.1 of the historical docs):

1. **5 boundary groups → 10 representative regions** (manageable case splits)
2. **Min-cut values in {1, 2} → ℚ≥0 ≡ ℕ still works** (no scalar upgrade needed)
3. **Genuine 2D tiling** (pentagons), not a 1D tree
4. **Star topology** — simplest connected HaPPY network with a central tile
5. **Clean RT correspondence** — S = geodesic for all regions (no N-singleton discrepancy)

The last point is critical: the 11-tile filled patch has an N-singleton discrepancy (min-cut ≠ internal geodesic for single N-tiles) that required redefining the bulk observable. The star avoids this entirely.

The star patch validated every step of the bridge architecture before the project scaled to the 11-tile disk (curvature), the 3D honeycombs (dimension), and the dense patches (orbit reduction). It remains the most exercised single object in the repository: 15 hand-written modules touching the bridge, dynamics, gauge, quantum, and Wick rotation layers.

---

## 16. Relationship to Subsequent Instances

| Instance | What it adds beyond the star |
|----------|------------------------------|
| **Tree pilot** ([tree-pilot.md](tree-pilot.md)) | Architecture validation only (1D, trivial bridge) — the star EXTENDS this |
| [Filled (11-tile)](filled-patch.md) | Gauss–Bonnet, subadditivity (360 cases), `abstract` barrier, unification of Theorems 1 + 3 |
| [Honeycomb (3D)](honeycomb-3d.md) | 3D dimension, edge curvature |
| [Dense-50](dense-50.md) | Greedy growth, min-cut range 1–7 |
| [Dense-100](dense-100.md) | Orbit reduction (717 → 8), area law, half-bound |
| [Dense-200](dense-200.md) | Third tower level, monotonicity 8 → 9 |
| [Layer-54 tower](layer-54-tower.md) | 6 BFS depths, exponential growth, constant orbit count |
| [De Sitter patch](desitter-patch.md) | Positive curvature, curvature-agnostic bridge — **shares** the star's bridge |

The star's `Region`, `Bond`, and `Tile` types from `Common/StarSpec.agda` are reused by the de Sitter patch (which imports them directly rather than defining new types). The star's bridge equivalence is literally the `shared-bridge` field of the `WickRotationWitness`. The star's `SL-param-pointwise` is consumed by the quantum superposition bridge and the gauge-enriched bridge.

---

## 17. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (refl, funExt, ua, transport) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Holographic bridge (generic architecture) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Discrete geometry (curvature — filled patch) | [`formal/04-discrete-geometry.md`](../formal/04-discrete-geometry.md) |
| Gauge theory (Q₈ connections on the star) | [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md) |
| Quantum superposition (star quantum bridge) | [`formal/07-quantum-superposition.md`](../formal/07-quantum-superposition.md) |
| Wick rotation (shared bridge) | [`formal/08-wick-rotation.md`](../formal/08-wick-rotation.md) |
| Dynamics (step invariance, loop) | [`formal/10-dynamics.md`](../formal/10-dynamics.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Tree pilot (previous instance) | [`instances/tree-pilot.md`](tree-pilot.md) |
| Filled patch (next instance) | [`instances/filled-patch.md`](filled-patch.md) |
| De Sitter patch (shares the bridge) | [`instances/desitter-patch.md`](desitter-patch.md) |
| Historical development (full specification) | [`historical/development-docs/09-happy-instance.md`](../historical/development-docs/09-happy-instance.md) |
| Numerical verification (Python) | `sim/prototyping/01_happy_patch_cuts.py` |
| Building & type-checking | [`getting-started/building.md`](../getting-started/building.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |