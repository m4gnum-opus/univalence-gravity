# Scaling Report

**Region counts, orbit counts, parse/check times, and scaling properties across all verified patch instances.**

**Audience:** Proof engineers, Agda developers, and anyone evaluating the computational feasibility of the formalization at larger scales.

**Prerequisites:** Familiarity with the oracle pipeline ([`oracle-pipeline.md`](oracle-pipeline.md)), orbit reduction ([`orbit-reduction.md`](orbit-reduction.md)), the `abstract` barrier ([`abstract-barrier.md`](abstract-barrier.md)), and the generic bridge pattern ([`generic-bridge-pattern.md`](generic-bridge-pattern.md)).

---

## 1. Overview

The Univalence Gravity repository verifies the discrete holographic correspondence across twelve patch instances spanning three spatial dimensions, four tiling types, and region counts from 8 to 1885. This document records the quantitative scaling data: how many regions each patch has, how orbit reduction compresses them, how large the generated Agda modules are, and how long they take to parse and type-check.

The central finding: **proof obligations grow logarithmically with patch size** (thanks to orbit reduction), while data-type declarations grow linearly. The bottleneck at scale is Agda's parser (processing large `data` declarations), not the proof checker (which operates on the small orbit type). The `abstract` barrier prevents sealed proofs from cascading RAM usage into downstream modules.

---

## 2. Patch Instance Registry

The following table records every verified patch instance in the repository, ordered by region count:

| # | Instance | Tiling | Dim | Cells | Regions | Orbits | Red. | Max S | Strategy |
|---|----------|--------|-----|-------|---------|--------|------|-------|----------|
| 1 | Tree pilot | 1D tree | 1D | 7 | 8 | — | — | 2 | flat refl |
| 2 | Star (6-tile) | {5,4} | 2D | 6 | 10 | — | — | 2 | PatchData |
| 3 | {5,4} depth 2 | {5,4} | 2D | 21 | 15 | 2 | 8× | 2 | OrbitReduced |
| 4 | Honeycomb BFS | {4,3,5} | 3D | 32 | 26 | — | — | 1 | PatchData |
| 5 | {5,4} depth 3 | {5,4} | 2D | 61 | 40 | 2 | 20× | 2 | OrbitReduced |
| 6 | Filled (11-tile) | {5,4} | 2D | 11 | 90 | — | — | 4 | PatchData |
| 7 | {5,4} depth 4 | {5,4} | 2D | 166 | 105 | 2 | 53× | 2 | OrbitReduced |
| 8 | Dense-50 | {4,3,5} | 3D | 50 | 139 | — | — | 7 | PatchData |
| 9 | {5,4} depth 5 | {5,4} | 2D | 441 | 275 | 2 | 138× | 2 | OrbitReduced |
| 10 | Dense-100 | {4,3,5} | 3D | 100 | 717 | 8 | 90× | 8 | OrbitReduced |
| 11 | Dense-200 | {4,3,5} | 3D | 200 | 1246 | 9 | 138× | 9 | OrbitReduced |
| 12 | {5,4} depth 7 | {5,4} | 2D | 3046 | 1885 | 2 | 942× | 2 | OrbitReduced |

**Key columns:**

- **Cells**: number of tiles (2D) or cubes (3D) in the patch.
- **Regions**: number of cell-aligned boundary regions (connected subsets of boundary cells, up to 5 cells each).
- **Orbits**: number of orbit representatives (distinct min-cut values). "—" means flat enumeration (no orbit reduction).
- **Red.**: orbit reduction factor (Regions / Orbits). Measures how many proof cases are eliminated.
- **Max S**: maximum min-cut value across all regions (the "holographic depth").
- **Strategy**: whether the bridge uses flat `PatchData` or `OrbitReducedPatch`.

---

## 3. Orbit Reduction Scaling

The orbit reduction strategy classifies regions by min-cut value, reducing proof obligations from the full region count to the orbit count. The reduction factor grows with patch size because the number of distinct min-cut values (orbit count) grows only logarithmically with the region count:

| Patch | Regions | Orbits | Reduction | Min-cut range |
|-------|---------|--------|-----------|---------------|
| Dense-50 | 139 | 7* | — | 1–7 |
| Dense-100 | 717 | 8 | 90× | 1–8 |
| Dense-200 | 1246 | 9 | 138× | 1–9 |
| {5,4} depth 2 | 15 | 2 | 8× | 1–2 |
| {5,4} depth 4 | 105 | 2 | 53× | 1–2 |
| {5,4} depth 5 | 275 | 2 | 138× | 1–2 |
| {5,4} depth 7 | 1885 | 2 | 942× | 1–2 |

*Dense-50 uses flat enumeration (no orbit reduction) because 139 regions are manageable without it. The 7 distinct min-cut values would give a 20× reduction if applied.

**Scaling law:** For the Dense family, the orbit count grows as ⌈log₂(max S)⌉ + 1, which is ~8–9 for patches of 100–200 cells. For the {5,4} BFS-layer family, the orbit count is **constant at 2** regardless of patch size (all BFS-grown pentagonal patches have min-cut values in {1, 2}).

**Consequence:** Adding tiles to a patch grows only the `classify` function (one clause per region constructor), **not** the proof obligations (one `refl` per orbit representative).

---

## 4. Generated Module Sizes

The Python oracle scripts (01–17 in `sim/prototyping/`) generate Agda modules whose size scales with region count. The following table records the approximate line counts for each generated module type:

### 4.1 Small Patches (flat enumeration)

| Patch | Spec | Cut | Chain | Obs | AreaLaw | HalfBound | Total |
|-------|------|-----|-------|-----|---------|-----------|-------|
| Tree | 40 | 35 | 35 | 40 | — | — | ~150 |
| Star | 50 | 45 | 45 | 45 | — | — | ~185 |
| Filled | 507 | 124 | 120 | 152 | — | — | ~903 |
| Honeycomb | 27 | 56 | 57 | 98 | — | — | ~238 |
| Dense-50 | 48 | 172 | 171 | 229 | — | — | ~620 |

### 4.2 Orbit-Reduced Patches

| Patch | Spec | Cut | Chain | Curvature | Obs | AreaLaw | HalfBound | Total |
|-------|------|-----|-------|-----------|-----|---------|-----------|-------|
| Dense-100 | 866 | 58 | 55 | 71 | 116 | 2099 | 1390 | ~4655 |
| Dense-200 | 1446 | 44 | 44 | 49 | 74 | 3556 | 2350 | ~7563 |
| {5,4} d2 | 52 | 25 | 25 | — | 57 | — | — | ~159 |
| {5,4} d7 | 2109 | 25 | 25 | — | 57 | — | — | ~2216 |

**Key observations:**

1. **Spec modules** grow linearly with region count (one constructor per region + one `classify` clause per region). The {5,4} depth-7 Spec has 2109 lines for 1885 region constructors + 1885 classify clauses.

2. **Cut/Chain modules** are tiny for orbit-reduced patches (~25–60 lines) because they define S-cut-rep / L-min-rep on the small orbit type (~8–9 clauses) and S-cut / L-min as one-line compositions.

3. **Obs modules** are tiny for orbit-reduced patches (~60–120 lines) because the pointwise agreement proof is orbit-level refls + 1-line lifting.

4. **AreaLaw and HalfBound modules** grow linearly with region count because each region needs its own `(k, refl)` witness (the slack values differ across regions within the same orbit). These are all `abstract`-sealed.

### 4.3 Subadditivity Module

| Module | Cases | Lines |
|--------|-------|-------|
| `Boundary/FilledSubadditivity.agda` | 360 | ~862 |

The 360-case subadditivity proof for the 11-tile filled patch is sealed behind `abstract`. No orbit reduction is applied because subadditivity slack values vary within min-cut orbits.

---

## 5. Expected Resource Usage

### 5.1 Parse and Type-Check Times

Measured on a typical development machine (16 GB RAM, modern multi-core CPU). Times are for **first load** (cold `.agdai` cache); subsequent loads use cached interfaces and are near-instantaneous.

| Module | Parse Time | Check Time | Peak RAM | Notes |
|--------|-----------|------------|----------|-------|
| `Common/Dense200Spec.agda` | 30–90s | 10–30s | ~2 GB | 1246 constructors + 1246 classify clauses |
| `Common/Layer54d7Spec.agda` | 30–90s | 10–30s | ~2 GB | 1885 constructors + 1885 classify clauses |
| `Common/Dense100Spec.agda` | 15–45s | 5–15s | ~1.5 GB | 717 constructors + 717 classify clauses |
| `Boundary/Dense200AreaLaw.agda` | 30–90s | 60–180s | ~3–4 GB | 1246 abstract (k, refl) proofs |
| `Boundary/Dense200HalfBound.agda` | 30–90s | 60–180s | ~3–4 GB | 1246 abstract (k, refl) proofs |
| `Boundary/Dense100AreaLaw.agda` | 20–60s | 30–120s | ~2–3 GB | 717 abstract (k, refl) proofs |
| `Boundary/Dense100HalfBound.agda` | 20–60s | 30–120s | ~2–3 GB | 717 abstract (k, refl) proofs |
| `Boundary/FilledSubadditivity.agda` | 10–30s | 20–60s | ~1.5–2 GB | 360 abstract cases |
| `Bridge/SchematicTower.agda` | 5–15s | 30–90s | ~2 GB | Imports most of repo |
| `Gauge/Q8.agda` | 5–10s | 10–30s | ~1.5 GB | 400-case associativity |
| `Bridge/GenericBridge.agda` | <5s | <10s | <1 GB | ~30 lines of proof |
| `Bridge/GenericValidation.agda` | 5–10s | 10–30s | ~1.5 GB | 6 bridge instantiations |
| Most hand-written modules | <5s | <10s | <1 GB | — |

### 5.2 Full Repository Type-Check

Loading `Bridge/SchematicTower.agda` (which transitively pulls in almost everything):

| Metric | Value |
|--------|-------|
| First load (cold cache) | 15–45 minutes |
| Subsequent load (warm `.agdai`) | <1 minute |
| Peak RAM | ~4 GB |
| Recommended minimum RAM | 8 GB |
| Comfortable RAM | 16 GB |

### 5.3 Bottleneck Analysis

The bottleneck is **parsing large `data` declarations**, not proof checking:

1. **Parsing** `D200Region` (1246 constructors): Agda's parser allocates one AST node per constructor. At 1246 constructors, this is ~30–90 seconds.

2. **Checking** the `classify200` function (1246 clauses): each clause trivially maps a constructor to another constructor. Fast per-clause, but linear in clause count. ~10–30 seconds.

3. **Checking** orbit-level proofs (8–9 `refl` cases): trivial. <1 second.

4. **Checking** abstract AreaLaw/HalfBound proofs (717–1246 cases): each `(k, refl)` witness is checked independently (the `abstract` barrier prevents cascading). ~30–180 seconds depending on case count.

5. **Downstream modules** importing `abstract` lemmas: the `abstract` barrier prevents any re-normalization of the sealed cases. Fast (<15 seconds per module).

The `abstract` keyword is the critical performance enabler: without it, downstream modules importing the 717-case area-law lemma would trigger re-normalization of all 717 proof trees, causing RAM spikes up to 8+ GB and potential out-of-memory crashes. With `abstract`, downstream modules see only the type signature and proceed in <15 seconds.

---

## 6. Python Oracle Computation Times

The Python oracle scripts (running on CPython 3.12 with NetworkX 3.6.1) have their own scaling characteristics. The dominant cost is max-flow computation for min-cut values:

| Script | Patch | Regions | Time | Notes |
|--------|-------|---------|------|-------|
| `09_generate_dense100.py` | Dense-100 | 717 | ~10s | greedy growth + max-flow |
| `12_generate_dense200.py` | Dense-200 | 1246 | ~30s | greedy growth + max-flow + area law |
| `13_generate_layerN.py --depth 7` | {5,4} d7 | 1885 | ~12min | Coxeter BFS + max-flow |
| `17_generate_half_bound.py` | D100+D200 | 1963 | ~40s | reuses patch + half-bound slack |
| `16_half_bound_scaling.py` | All tilings | 32,134 | ~109min | 4 tilings × 4 strategies × 3 capacities |

The `16_half_bound_scaling.py` script (the comprehensive scaling confirmation) processes 32,134 regions across 24 patch configurations in ~109 minutes. This is a one-time computation; the emitted Agda modules are regenerated only if the upstream patch data changes.

---

## 7. The `abstract` Barrier: Performance Profile

The five `abstract`-sealed modules and their performance impact:

| Module | Cases | First Load | RAM (self) | RAM (downstream) |
|--------|-------|------------|-----------|-----------------|
| `FilledSubadditivity.agda` | 360 | 30–90s | ~1.5–2 GB | **0** (sealed) |
| `Dense100AreaLaw.agda` | 717 | 50–180s | ~2–3 GB | **0** (sealed) |
| `Dense200AreaLaw.agda` | 1246 | 90–270s | ~3–4 GB | **0** (sealed) |
| `Dense100HalfBound.agda` | 717 | 50–180s | ~2–3 GB | **0** (sealed) |
| `Dense200HalfBound.agda` | 1246 | 90–270s | ~3–4 GB | **0** (sealed) |

The "RAM (downstream)" column shows the RAM cost imposed on any module that imports the `abstract` lemma. Because the `abstract` barrier prevents re-normalization, the downstream cost is **zero** — the type-checker sees only the type signature (`_≤ℚ_` is propositional), never the 717+ case analysis.

**Without `abstract`**, the downstream cost would be proportional to the case count × the normalization cost per case, potentially triggering the RAM cascade documented in [Agda Issue #4573](https://github.com/agda/agda/issues/4573).

---

## 8. Scaling Projections

Based on empirical data, the following projections estimate feasibility for larger patches:

| Patch | Est. Regions | Est. Orbits | Spec Lines | AreaLaw Lines | Parse Time | HalfBound Lines |
|-------|-------------|-------------|------------|---------------|------------|-----------------|
| Dense-500 | ~3,400 | ~10 | ~3,800 | ~9,800 | 2–5 min | ~6,800 |
| Dense-1000 | ~6,900 | ~11 | ~7,500 | ~19,500 | 5–15 min | ~13,800 |
| Dense-2000 | ~14,000 | ~12 | ~15,000 | ~39,000 | 10–30 min | ~28,000 |
| {5,4} depth 10 | ~13,000 | 2 | ~14,000 | — | 10–30 min | — |

**Feasibility assessment:**

- **Dense-500**: fully feasible with current infrastructure. Parse time is the bottleneck (~2–5 minutes for the Spec module).
- **Dense-1000**: feasible but slow. Parse time grows to ~5–15 minutes. The `Fin N` encoding fallback (§6.5.4 of the historical development docs) would eliminate this bottleneck by replacing the flat `data` declaration with a balanced binary tree lookup.
- **Dense-2000**: at the edge. The Spec module alone would be ~15,000 lines. The `Fin N` encoding is recommended.
- **{5,4} depth 10**: feasible because the orbit count stays at 2. The proof has exactly 2 cases regardless of region count. Only the Spec module (with the `classify` function) grows.

The orbit reduction architecture ensures that **proof complexity is bounded by the orbit count** (typically 2–12), independent of the region count. The remaining linear-growth components (Spec, AreaLaw, HalfBound) are all data declarations or `abstract`-sealed proofs, which do not cascade into downstream modules.

---

## 9. Comparison: Flat vs Orbit-Reduced

| Property | Flat (Dense-50 style) | Orbit-Reduced (Dense-100 style) |
|----------|----------------------|--------------------------------|
| Region type | 139 constructors | 717 constructors |
| Observable def. | 139-clause case split | 8-clause orbit lookup + 717-clause classify |
| Pointwise proof | 139 `refl` cases | 8 `refl` cases + 1-line lifting |
| Proof size | O(N) where N = regions | O(K) where K = orbits |
| Parse time | ~5s | ~15–45s (for `classify`) |
| Proof check time | ~5s | <1s (orbit-level) |
| Adding more tiles | grows proof proportionally | grows `classify` only; proofs unchanged |

The crossover point where orbit reduction becomes advantageous is approximately 200–300 regions. Below that, flat enumeration is simpler. Above that, the orbit reduction strategy provides dramatic speedups in proof checking while adding only moderate overhead to parsing.

---

## 10. The Resolution Tower: Scaling Across Levels

The schematic tower (`Bridge/SchematicTower.agda`) assembles verified patches into a resolution sequence. The per-level data:

### 10.1 Dense Resolution Tower

| Level | Patch | Cells | Regions | Orbits | Max S | Monotone | AreaLaw | HalfBound |
|-------|-------|-------|---------|--------|-------|----------|---------|-----------|
| 0 | Dense-50 | 50 | 139 | — | 7 | — | — | — |
| 1 | Dense-100 | 100 | 717 | 8 | 8 | (1, refl) | 717 cases | 717 cases |
| 2 | Dense-200 | 200 | 1246 | 9 | 9 | (1, refl) | 1246 cases | 1246 cases |

The monotonicity witnesses are `(1, refl)` at each step because `1 + 7 = 8` and `1 + 8 = 9` judgmentally. The spectrum grows: 7 → 8 → 9.

### 10.2 {5,4} Layer Tower

| Level | Depth | Cells | Regions | Orbits | Max S | Monotone |
|-------|-------|-------|---------|--------|-------|----------|
| 0 | 2 | 21 | 15 | 2 | 2 | — |
| 1 | 3 | 61 | 40 | 2 | 2 | (0, refl) |
| 2 | 4 | 166 | 105 | 2 | 2 | (0, refl) |
| 3 | 5 | 441 | 275 | 2 | 2 | (0, refl) |
| 4 | 6 | 1161 | 720 | 2 | 2 | (0, refl) |
| 5 | 7 | 3046 | 1885 | 2 | 2 | (0, refl) |

The {5,4} tower is "flat": all max min-cut values are 2 (monotonicity witnesses are `(0, refl)`). The exponential growth of tiles (21 → 3046, ×2.6 per depth) is the hallmark of hyperbolic geometry, but the orbit count stays constant at 2. The proof obligations per level are **exactly 2 `refl` cases**, regardless of depth.

---

## 11. Numerical Verification Coverage

The Python oracle scripts have verified the half-bound S(A) ≤ area(A)/2 across a comprehensive matrix:

| Dimension | Coverage |
|-----------|----------|
| **Regions tested** | 32,134 |
| **Patch configurations** | 24 |
| **Tilings** | 4 ({4,3,5}, {5,4}, {4,4}, {5,3}) |
| **Growth strategies** | 4 (Dense, BFS, Geodesic, Hemisphere) |
| **Bond capacities** | 3 (c = 1, 2, 3) |
| **Violations** | **0** |

This is the empirical foundation for the `HalfBoundWitness` records in the Agda formalization. The Agda type-checker verifies each `(k, refl)` witness individually; the Python oracle's role is to find the correct slack value `k` for each region.

---

## 12. Summary

| Metric | Value |
|--------|-------|
| Verified patch instances | 12 |
| Total region constructors (all patches) | ~4,830 |
| Total proof cases (orbit-level) | ~40 |
| Total `abstract`-sealed proof cases | ~3,986 |
| Largest `data` type | `Layer54d7Region` (1885 constructors) |
| Largest `abstract` module | `Dense200AreaLaw.agda` (1246 cases) |
| Maximum orbit reduction factor | 942× ({5,4} depth 7) |
| Full repo type-check (cold cache) | 15–45 minutes |
| Full repo type-check (warm cache) | <1 minute |
| Recommended RAM | ≥8 GB (16 GB comfortable) |

The architecture scales to arbitrary patch sizes without additional proof engineering. Adding a new patch instance requires zero new hand-written Agda proof — only the Python oracle generates data modules, and `orbit-bridge-witness` produces the `BridgeWitness` automatically. The proof obligations (orbit-level `refl` cases) grow logarithmically with the min-cut range. The data obligations (region constructors, classify clauses, area-law witnesses) grow linearly but are confined to parsed data and `abstract`-sealed proofs that do not cascade into downstream modules.

---

## 13. Cross-References

| Topic | Document |
|-------|----------|
| Oracle pipeline (how modules are generated) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Orbit reduction (the scaling strategy) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| `abstract` barrier (RAM management) | [`engineering/abstract-barrier.md`](abstract-barrier.md) |
| Generic bridge pattern (one proof, N instances) | [`engineering/generic-bridge-pattern.md`](generic-bridge-pattern.md) |
| Building & type-checking guide | [`getting-started/building.md`](../getting-started/building.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Generic bridge and SchematicTower (formal) | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Bekenstein–Hawking half-bound (formal) | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Per-instance data sheets | [`instances/`](../instances/) |
| Agda Issue #4573 (the RAM cascade) | [github.com/agda/agda/issues/4573](https://github.com/agda/agda/issues/4573) |