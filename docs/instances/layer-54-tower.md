# Layer-54 Tower Instance

**The {5,4} BFS depths 2–7 — six verified holographic slices with exponential boundary growth and constant orbit count.**

**Modules:** `Common/Layer54d{2..7}Spec.agda` (AUTO-GEN), `Boundary/Layer54d{2..7}Cut.agda` (AUTO-GEN), `Bulk/Layer54d{2..7}Chain.agda` (AUTO-GEN), `Bridge/Layer54d{2..7}Obs.agda` (AUTO-GEN), `Bridge/SchematicTower.agda` (tower assembly)

**Role:** The {5,4} BFS-layer tower is the repository's primary demonstration of the **schematic bridge factorization** — the architectural innovation that separates geometry (handled by the Python oracle) from proof (handled once by the generic theorem). Six patches at BFS depths 2 through 7, ranging from 21 tiles to 3046 tiles, are each verified by the same 2-case orbit-level proof + 1-line lifting, then assembled into a `Layer54Tower` record with 5 monotonicity witnesses. The tower demonstrates that the holographic correspondence scales to exponentially growing hyperbolic patches without any increase in proof complexity: the orbit count is **constant at 2** regardless of depth, and the orbit reduction factor grows from 8× (depth 2) to 942× (depth 7).

---

## 1. Tower Overview

| Depth | Tiles | Regions | Orbits | Reduction | Max S | Monotone | Bridge |
|-------|-------|---------|--------|-----------|-------|----------|--------|
| 2 | 21 | 15 | 2 | 8× | 2 | — | `layer54d2-bridge` |
| 3 | 61 | 40 | 2 | 20× | 2 | (0, refl) | `layer54d3-bridge` |
| 4 | 166 | 105 | 2 | 53× | 2 | (0, refl) | `layer54d4-bridge` |
| 5 | 441 | 275 | 2 | 138× | 2 | (0, refl) | `layer54d5-bridge` |
| 6 | 1161 | 720 | 2 | 360× | 2 | (0, refl) | `layer54d6-bridge` |
| 7 | 3046 | 1885 | 2 | 942× | 2 | (0, refl) | `layer54d7-bridge` |

**Key properties:**

- **Exponential tile growth:** ~2.6× per depth level (21 → 3046 is 145× over 5 steps). This is the hallmark of hyperbolic geometry: the {5,4} tiling has exponentially growing boundary length with each BFS shell.

- **Constant orbit count:** The min-cut values are restricted to {1, 2} at every BFS depth. This is because BFS-grown pentagonal patches have a structural property: every boundary tile is either an outer leaf (connected to one internal tile, min-cut = 1) or a shared boundary tile (connected to two internal tiles through the center, min-cut = 2). The orbit type has **exactly 2 constructors** regardless of patch size.

- **Constant proof complexity:** Each bridge proof has exactly 2 orbit-level `refl` cases + 1-line lifting, regardless of whether the patch has 15 regions or 1885 regions. Adding tiles grows only the `classify` function — not the proof obligations.

- **Flat monotonicity:** All max min-cut values are 2, so every `LayerStep.monotone` witness is `(0, refl)`. The tower is spectrally flat — the holographic depth does not increase with resolution. This contrasts with the Dense resolution tower (7 → 8 → 9), where the spectrum grows monotonically.

---

## 2. The {5,4} Hyperbolic Pentagonal Tiling

The {5,4} tiling has regular pentagons with 4 meeting at each vertex. The Schläfli symbol {5,4} encodes pentagons ({5,·}) with vertex valence 4 ({·,4}). The product (5−2)(4−2) = 3·2 = 6 > 4 confirms hyperbolic geometry: the angular excess at each interior vertex is 4 × 108° − 360° = 72° = 2π/5.

The Coxeter group [5,4] has rank 3 with Gram matrix signature (2,1) — compact hyperbolic. The tile stabilizer is the dihedral group D₅ (order 10), and each tile has 5 edge-crossings (one per pentagon edge). Growth is by BFS from the central tile in the tile-adjacency graph.

**Coxeter geometry (from `13_generate_layerN.py`):**

| Property | Value |
|----------|-------|
| Coxeter group | [5,4] with 3 generators |
| Gram matrix signature | (2,1) — compact hyperbolic |
| Tile stabilizer | D₅ — order 10 (dihedral) |
| Edge crossings per tile | 5 |
| Tile center norm² | −2.236068 (timelike ✓) |

---

## 3. Per-Depth Patch Data

### 3.1 Depth 2 (21 tiles, 15 regions)

The smallest layer patch. The central tile + 5 edge-neighbours + 5 gap-fillers + 5 outer-ring tiles. This is the first BFS expansion beyond the 11-tile filled patch.

| Property | Value |
|----------|-------|
| Tiles | 21 |
| Internal bonds | 25 |
| Boundary legs | 55 |
| Density (2·bonds/tiles) | 2.38 |
| Regions (max 4 cells) | 15 |
| Orbit representatives | 2 (mc1: 10 regions, mc2: 5 regions) |
| Min-cut range | 1–2 |
| Reduction factor | 8× |

### 3.2 Depth 3 (61 tiles, 40 regions)

| Property | Value |
|----------|-------|
| Tiles | 61 |
| Internal bonds | ~75 |
| Boundary legs | ~155 |
| Density | ~2.46 |
| Regions | 40 |
| Orbit representatives | 2 (mc1: 25 regions, mc2: 15 regions) |
| Min-cut range | 1–2 |
| Reduction factor | 20× |

### 3.3 Depth 4 (166 tiles, 105 regions)

| Property | Value |
|----------|-------|
| Tiles | 166 |
| Regions | 105 |
| Orbit representatives | 2 |
| Min-cut range | 1–2 |
| Reduction factor | 53× |

### 3.4 Depth 5 (441 tiles, 275 regions)

| Property | Value |
|----------|-------|
| Tiles | 441 |
| Regions | 275 |
| Orbit representatives | 2 |
| Min-cut range | 1–2 |
| Reduction factor | 138× |

### 3.5 Depth 6 (1161 tiles, 720 regions)

| Property | Value |
|----------|-------|
| Tiles | 1161 |
| Regions | 720 |
| Orbit representatives | 2 |
| Min-cut range | 1–2 |
| Reduction factor | 360× |

### 3.6 Depth 7 (3046 tiles, 1885 regions)

The largest patch instance in the repository. The `Layer54d7Spec.agda` module has 1885 region constructors and a 1885-clause `classifyLayer54d7` function — but only 2 orbit-level proof cases.

| Property | Value |
|----------|-------|
| Tiles | 3046 |
| Internal bonds | 4205 |
| Boundary legs | 6820 |
| Density (2·bonds/tiles) | 2.76 |
| Regions (max 4 cells) | 1885 |
| Orbit representatives | 2 (mc1: 1165 regions, mc2: 720 regions) |
| Min-cut range | 1–2 |
| Reduction factor | **942×** |

This is the highest orbit reduction factor in the repository. The 1885-clause classification function absorbs all combinatorial case analysis; the proof has exactly 2 `refl` cases.

---

## 4. Min-Cut / Observable Agreement

For every depth, the min-cut values are restricted to {1, 2}:

| Orbit | Min-cut | Meaning | Count at depth 7 |
|-------|---------|---------|-------------------|
| mc1 | 1 | Outer leaf tile: 1 internal bond to parent | 1165 regions |
| mc2 | 2 | Shared boundary tile: 2 internal bonds | 720 regions |

The pointwise agreement proof at each depth has the same structure:

```agda
-- Bridge/Layer54d7Obs.agda (depth 7 example)
layer54d7-pointwise-rep :
  (o : Layer54d7OrbitRep) → S-cut-rep o ≡ L-min-rep o
layer54d7-pointwise-rep mc1 = refl
layer54d7-pointwise-rep mc2 = refl

layer54d7-pointwise :
  (r : Layer54d7Region) →
  S-cut layer54d7BdyView r ≡ L-min layer54d7BulkView r
layer54d7-pointwise r = layer54d7-pointwise-rep (classifyLayer54d7 r)
```

**Two proof cases. One lifting line. 1885 regions verified.**

This is the discrete Ryu–Takayanagi correspondence for the {5,4} BFS-layer patches: boundary min-cut entropy equals bulk minimal separating chain length on every boundary region, at every BFS depth from 2 to 7.

---

## 5. Tower Assembly

### 5.1 OrbitReducedPatch Instances

Each depth is registered as an `OrbitReducedPatch` in `Bridge/SchematicTower.agda`:

```agda
layer54d7-orbit : OrbitReducedPatch
layer54d7-orbit .OrbitReducedPatch.RegionTy  = Layer54d7Region
layer54d7-orbit .OrbitReducedPatch.OrbitTy   = Layer54d7OrbitRep
layer54d7-orbit .OrbitReducedPatch.classify  = classifyLayer54d7
layer54d7-orbit .OrbitReducedPatch.S-rep     = S-cut-rep
layer54d7-orbit .OrbitReducedPatch.L-rep     = L-min-rep
layer54d7-orbit .OrbitReducedPatch.rep-agree = layer54d7-pointwise-rep
```

### 5.2 TowerLevel Instances

Tower levels are constructed by `mkTowerLevel`, which calls `orbit-bridge-witness` internally:

```agda
layer54d2-level : TowerLevel
layer54d2-level = mkTowerLevel layer54d2-orbit 2

-- ... (depths 3–6 similarly)

layer54d7-level : TowerLevel
layer54d7-level = mkTowerLevel layer54d7-orbit 2
```

All levels have `maxCut = 2`. The `mkTowerLevel` smart constructor invokes `orbit-bridge-witness`, producing the full `BridgeWitness` (enriched type equivalence + Univalence path + verified transport) from the 2-orbit data automatically.

### 5.3 LayerStep Instances

The five monotonicity witnesses between consecutive depths are all `(0, refl)`:

```agda
step-d2→d3 : LayerStep layer54d2-level layer54d3-level
step-d2→d3 .LayerStep.monotone = 0 , refl   -- 0 + 2 = 2

step-d3→d4 : LayerStep layer54d3-level layer54d4-level
step-d3→d4 .LayerStep.monotone = 0 , refl

-- ... (d4→d5, d5→d6, d6→d7 similarly, all (0, refl))
```

### 5.4 The Layer54Tower Record

The complete tower is packaged in `Bridge/SchematicTower.agda`:

```agda
layer54-tower : Layer54Tower
layer54-tower .Layer54Tower.level-d2 = layer54d2-level
layer54-tower .Layer54Tower.level-d3 = layer54d3-level
layer54-tower .Layer54Tower.level-d4 = layer54d4-level
layer54-tower .Layer54Tower.level-d5 = layer54d5-level
layer54-tower .Layer54Tower.level-d6 = layer54d6-level
layer54-tower .Layer54Tower.level-d7 = layer54d7-level
layer54-tower .Layer54Tower.step-2→3 = step-d2→d3
layer54-tower .Layer54Tower.step-3→4 = step-d3→d4
layer54-tower .Layer54Tower.step-4→5 = step-d4→d5
layer54-tower .Layer54Tower.step-5→6 = step-d5→d6
layer54-tower .Layer54Tower.step-6→7 = step-d6→d7
```

### 5.5 CausalDiamond Packaging

The tower is repackaged as a `CausalDiamond` in `Causal/CausalDiamond.agda`:

```agda
layer54-diamond : CausalDiamond
-- 6 slices, 5 extensions
-- proper time = 5
-- maximin = 2 (all slices have maxCut = 2)
```

Verified:

```agda
proper-time-layer54 : proper-time layer54-diamond ≡ 5
proper-time-layer54 = refl

maximin-layer54 : maximin layer54-diamond ≡ 2
maximin-layer54 = refl

n-slices-layer54 : n-slices layer54-diamond ≡ 6
n-slices-layer54 = refl
```

---

## 6. The Exponential Growth Pattern

The hallmark of hyperbolic geometry is exponential boundary growth. The {5,4} tiling exhibits this clearly:

| Depth | Tiles | Growth | Regions | Region Growth |
|-------|-------|--------|---------|---------------|
| 2 | 21 | — | 15 | — |
| 3 | 61 | ×2.9 | 40 | ×2.7 |
| 4 | 166 | ×2.7 | 105 | ×2.6 |
| 5 | 441 | ×2.7 | 275 | ×2.6 |
| 6 | 1161 | ×2.6 | 720 | ×2.6 |
| 7 | 3046 | ×2.6 | 1885 | ×2.6 |

The growth factor stabilizes at ~2.6× per depth — consistent with the exponential growth rate of the {5,4} tiling. In a hyperbolic ball of radius r, the boundary length grows as e^{κr} where κ is the curvature; the discrete analogue is this constant multiplicative factor per BFS shell.

**Consequence for the proof architecture:** The region count grows exponentially (15 → 1885 over 5 depth steps), but the orbit count stays constant at 2. This means the proof complexity is **O(1)** — independent of the patch size. The exponential growth is absorbed entirely by the `classify` function, which is data (generated by the Python oracle) rather than proof (handled once by the generic theorem).

---

## 7. Comparison with Other Instances

### 7.1 vs. Dense Resolution Tower

| Property | Layer-54 Tower | Dense Resolution Tower |
|----------|----------------|------------------------|
| Tiling | {5,4} 2D pentagons | {4,3,5} 3D cubes |
| Growth strategy | BFS (concentric shells) | Dense (greedy max-connectivity) |
| Levels | 6 (depths 2–7) | 3 (Dense-50, -100, -200) |
| Max min-cut | 2 (constant) | 7, 8, 9 (growing) |
| Spectrum monotonicity | Flat (0, refl) | Strict (1, refl) |
| Orbit count | 2 (constant) | 7, 8, 9 (growing) |
| Largest region count | 1885 | 1246 |
| Largest reduction factor | 942× | 138× |
| Area law | Not verified | Verified (717 + 1246 cases) |
| Half-bound | Not verified | Verified (717 + 1246 cases) |

The layer tower demonstrates **scaling** (the architecture handles 1885-region patches with 2 proof cases). The Dense tower demonstrates **depth** (non-trivial min-cut values up to 9, monotone growth, and the Bekenstein–Hawking half-bound).

### 7.2 vs. Individual 2D Patches

| Instance | Regions | Orbits | Reduction | Proof Cases |
|----------|---------|--------|-----------|-------------|
| Star (6-tile) | 10 | — | flat | 10 |
| Filled (11-tile) | 90 | — | flat | 90 |
| {5,4} depth 2 | 15 | 2 | 8× | 2 |
| {5,4} depth 4 | 105 | 2 | 53× | 2 |
| {5,4} depth 7 | 1885 | 2 | 942× | **2** |

The progression from flat enumeration (star, filled) to orbit reduction ({5,4} depths 2–7) reduces proof obligations by up to 942×. The crossover point is around 200–300 regions; below that, flat enumeration is simpler.

---

## 8. Module Inventory

### 8.1 Per-Depth Modules (4 modules × 6 depths = 24 auto-generated modules)

| Module Pattern | Content | Lines (depth 7) |
|----------------|---------|------------------|
| `Common/Layer54d{N}Spec.agda` | Region type, orbit type, classify function | ~2109 |
| `Boundary/Layer54d{N}Cut.agda` | S-cut-rep (2 clauses), S-cut = S-cut-rep ∘ classify | ~25 |
| `Bulk/Layer54d{N}Chain.agda` | L-min-rep (2 clauses), L-min = L-min-rep ∘ classify | ~25 |
| `Bridge/Layer54d{N}Obs.agda` | pointwise-rep (2 refls), pointwise (1-line lifting), obs-path, package-path | ~57 |

**Scaling observation:** The Spec module grows linearly with region count (one constructor + one classify clause per region). The Cut, Chain, and Obs modules are **constant size** (~25–57 lines) regardless of region count, because they operate on the 2-constructor orbit type.

### 8.2 Tower Integration (in SchematicTower.agda)

| Content | Section |
|---------|---------|
| `layer54d{2..7}-orbit : OrbitReducedPatch` | §10 |
| `layer54d{2..7}-level : TowerLevel` | §11 |
| `layer54d{2..7}-bridge : BridgeWitness` | §12 |
| `step-d{2..6}→d{3..7} : LayerStep` | §13 |
| `layer54-tower : Layer54Tower` | §14 |

### 8.3 Causal Diamond (in CausalDiamond.agda)

| Content | Section |
|---------|---------|
| `layer54-diamond : CausalDiamond` | §7 |
| `proper-time-layer54 : proper-time layer54-diamond ≡ 5` | §10 |
| `maximin-layer54 : maximin layer54-diamond ≡ 2` | §9 |

---

## 9. The Python Oracle (Script 13)

All 24 per-depth modules are generated by `sim/prototyping/13_generate_layerN.py`, invoked once per depth:

```bash
cd sim/prototyping
python3 13_generate_layerN.py --depth 2
python3 13_generate_layerN.py --depth 3
python3 13_generate_layerN.py --depth 4
python3 13_generate_layerN.py --depth 5
python3 13_generate_layerN.py --depth 6
python3 13_generate_layerN.py --depth 7
```

The script:

1. Initializes the [5,4] Coxeter geometry (Gram matrix, reflections, tile stabilizer D₅, 5 edge crossings).
2. Builds the BFS-depth-N patch via Coxeter reflections.
3. Constructs the flow graph (tiles = nodes, shared pentagon edges = capacity-1 bonds, boundary legs attached with capacity 1).
4. Enumerates cell-aligned boundary regions (connected subsets of boundary tiles up to `--max-region-cells` tiles, default 4).
5. Computes min-cut values via max-flow (NetworkX).
6. Groups regions into orbits by min-cut value.
7. Emits 4 Cubical Agda modules following the `OrbitReducedPatch` pattern from `09_generate_dense100.py`.

**Key output statistics (from `13_generate_layerN_OUTPUT.txt`):**

| Depth | Generated Lines | Parse Time (est.) |
|-------|----------------|-------------------|
| 2 | ~159 | <5s |
| 3 | ~220 | <5s |
| 4 | ~420 | 5–10s |
| 5 | ~760 | 10–20s |
| 6 | ~1600 | 20–40s |
| 7 | ~2216 | 30–90s |

The depth-7 Spec module (2109 lines, 1885 constructors + 1885 classify clauses) is the largest single auto-generated data type in the repository.

---

## 10. What the Layer-54 Tower Validates

The {5,4} layer tower exercises several capabilities at a scale not reached by any other instance:

| Step | What it tests | First exercised? |
|------|---------------|-----------------|
| 1885-region data type | Largest flat constructor enumeration in the repo | **Yes** |
| 942× orbit reduction | Highest reduction factor in the repo | **Yes** |
| Constant orbit count across scales | 2 orbits at every depth (15–1885 regions) | **Yes** |
| 6-level tower assembly | Longest tower in the repo (5 LayerSteps) | **Yes** |
| Exponential hyperbolic growth | 21 → 3046 tiles (×145 over 5 steps) | **Yes** |
| CausalDiamond with 6 slices | Longest causal diamond (proper time = 5) | **Yes** |
| Generic bridge at 1885 regions | Largest single BridgeWitness instantiation | **Yes** |
| Flat monotonicity (all (0, refl)) | All layers have maxCut = 2 | **Yes** |
| 2D tiling tower (vs. 3D Dense tower) | First {5,4} multi-depth verified series | **Yes** |

---

## 11. What the Layer-54 Tower Does NOT Exercise

- **Non-trivial min-cut range.** All min-cuts are in {1, 2}. Non-trivial ranges (1–8, 1–9) require the Dense growth strategy: Dense-100 ([`instances/dense-100.md`](dense-100.md)) achieves min-cut up to 8.

- **Area law / Bekenstein–Hawking bound.** The discrete area law S ≤ area and the half-bound 2·S ≤ area are verified only on the Dense patches ([`instances/dense-100.md`](dense-100.md), [`instances/dense-200.md`](dense-200.md)).

- **Strict monotonicity.** All LayerStep witnesses are `(0, refl)` (flat spectrum). Strict growth (maxCut increasing between levels) requires the Dense resolution tower.

- **3D geometry.** The {5,4} tiling is 2D. The 3D {4,3,5} honeycomb is exercised by the Dense patches and the honeycomb BFS patch ([`instances/honeycomb-3d.md`](honeycomb-3d.md)).

- **Curvature formalization at each depth.** Only the depth-1 patch (≈ the 11-tile filled patch from [`instances/filled-patch.md`](filled-patch.md)) has curvature formalized. The layer tower verifies the *bridge* (S = L) at each depth, not the *curvature* (Gauss–Bonnet).

- **Gauge connections / quantum superposition / dynamics.** These enrichment layers are exercised on the 6-tile star patch ([`instances/star-patch.md`](star-patch.md)).

---

## 12. Architectural Significance

### 12.1 The Schematic Bridge Factorization in Action

The layer tower is the purest demonstration of the schematic bridge factorization from §5 of the historical development docs. The original plan (§5.2) proposed defining an inductive type `HaPPYPatch (n : ℕ)` that recursively generates the polygon complex. This collides with the closed-loop gluing obstruction: the {5,4} tiling wraps around itself, and encoding the loops inductively requires weeks of graph-theory formalization.

The schematic bridge factorization **changes the structure of the induction**:

> **Original:** Structural induction on the **geometry** (layer-by-layer polygon complex).
>
> **New:** Structural induction on the **proof schema** (generic theorem applied to oracle-generated instances).

The layer tower validates this architecture at scale: six depths, exponential tile growth, constant proof complexity.

### 12.2 Why the Orbit Count Stays at 2

The BFS-shell topology produces uniform min-cut ≈ 1 for outer-leaf boundary tiles (which connect to the interior through a single shared edge) and min-cut = 2 for shared boundary tiles (which connect through two shared edges). No BFS-grown {5,4} boundary tile connects to the interior through 3 or more edges, because each BFS ring adds tiles that share at most 2 edges with the previous ring. This structural property is independent of depth — it holds for depth 2 (21 tiles) and depth 100 (millions of tiles).

The consequence: the orbit type has **exactly 2 constructors** forever. The proof complexity is asymptotically **O(1)**.

### 12.3 The Dense Strategy Produces Deeper Holographic Surfaces

The multi-strategy comparison from `07_honeycomb_3d_multiStrategy_OUTPUT.txt` reveals that BFS-shell patches have thin, non-entangled boundaries (all min-cuts ≈ 1–2), while Dense patches have multiply-connected bulk (min-cuts up to 8 at 100 cells). The layer tower demonstrates **architectural scaling** (proof complexity stays constant), while the Dense tower demonstrates **physics depth** (genuine multi-face RT separating surfaces).

Both are needed: the layer tower shows the architecture works at scale; the Dense tower shows the physics is non-trivial. Together they provide the complete picture documented in [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md).

---

## 13. The Causal Interpretation

In the causal layer ([`formal/06-causal-structure.md`](../formal/06-causal-structure.md)), the layer tower is the **discrete spacetime**: 6 verified spatial slices connected by 5 future-directed causal extensions, with the full Univalence bridge and transport verified at every slice.

Each `LayerStep` is one **Pachner move** — one BFS expansion layer adding a new ring of pentagonal tiles to the boundary. The Pachner move produces a new verified spatial slice at depth *n*+1 from the slice at depth *n*. The `LayerStep.monotone` field witnesses that the holographic depth (maximin entropy) is non-decreasing.

The causal diamond `layer54-diamond` has:

- **6 spatial slices** (depths 2 through 7)
- **Proper time = 5** (5 causal extensions)
- **Maximin = 2** (all slices have maxCut = 2)

The maximin equals the maxCut at the topmost slice (depth 7), confirming the monotone tower property:

```agda
maximin-equals-top-layer54 :
  maximin layer54-diamond ≡ TowerLevel.maxCut (diamond-top layer54-diamond)
maximin-equals-top-layer54 = refl
```

---

## 14. Relationship to Other Instances

| Instance | What it adds beyond the layer tower |
|----------|-------------------------------------|
| **Tree pilot** ([tree-pilot.md](tree-pilot.md)) | Architecture validation only (1D, no curvature) |
| **Star (6-tile)** ([star-patch.md](star-patch.md)) | Nontrivial enriched equiv, dynamics, gauge, quantum |
| **Filled (11-tile)** ([filled-patch.md](filled-patch.md)) | Gauss–Bonnet, subadditivity (360 cases), `abstract` barrier |
| **Honeycomb (3D)** ([honeycomb-3d.md](honeycomb-3d.md)) | 3D dimension, edge curvature |
| **Dense-50** ([dense-50.md](dense-50.md)) | Dense growth, min-cut range 1–7 |
| **Dense-100** ([dense-100.md](dense-100.md)) | Orbit reduction (717 → 8), area law, half-bound |
| **Dense-200** ([dense-200.md](dense-200.md)) | Third resolution level, monotonicity 8 → 9 |
| **Layer-54 tower** (this) | **6 BFS depths, exponential growth, constant orbit count, longest tower** |
| [De Sitter patch](desitter-patch.md) | Positive curvature, curvature-agnostic bridge (Wick rotation) |

The layer tower's `OrbitReducedPatch` instances are reused by the `SchematicTower`, which also hosts the Dense tower. Both tower types feed into the `ConvergenceCertificate3L-HB` and `DiscreteBekensteinHawking` capstone types through independent channels — the layer tower provides the 2D {5,4} evidence while the Dense tower provides the 3D {4,3,5} evidence.

---

## 15. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (refl, funExt, ua) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Holographic bridge (generic architecture) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Causal structure (NoCTC, light cones, diamonds) | [`formal/06-causal-structure.md`](../formal/06-causal-structure.md) |
| Orbit reduction (engineering) | [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Scaling report (region counts, timings) | [`engineering/scaling-report.md`](../engineering/scaling-report.md) |
| Oracle pipeline (Python-to-Agda generation) | [`engineering/oracle-pipeline.md`](../engineering/oracle-pipeline.md) |
| Dense-100 (orbit-reduced companion) | [`instances/dense-100.md`](dense-100.md) |
| Dense-200 (third resolution level) | [`instances/dense-200.md`](dense-200.md) |
| Star patch (enrichment layers) | [`instances/star-patch.md`](star-patch.md) |
| De Sitter patch (curvature-agnostic bridge) | [`instances/desitter-patch.md`](desitter-patch.md) |
| Code generator (Python) | `sim/prototyping/13_generate_layerN.py` |
| Code generator output | `sim/prototyping/13_generate_layerN_OUTPUT.txt` |
| Historical development (§5 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §5 |
| Building & type-checking | [`getting-started/building.md`](../getting-started/building.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |