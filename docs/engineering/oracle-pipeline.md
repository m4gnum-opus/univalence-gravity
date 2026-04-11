# The Oracle Pipeline

**Python-to-Agda code generation: scripts 01–17**

**Audience:** Proof engineers, formal verification researchers, and developers seeking to understand or extend the code-generation infrastructure.

**Prerequisites:** Familiarity with the repository architecture ([`getting-started/architecture.md`](../getting-started/architecture.md)), the generic bridge pattern ([`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md)), and basic knowledge of max-flow/min-cut algorithms.

---

## 1. Overview

The oracle pipeline is a collection of 17 Python scripts in `sim/prototyping/` that serve as the **search engine** for the formal verification: they enumerate combinatorial cases, compute min-cut values, classify orbit representatives, verify area-law bounds, and emit complete Cubical Agda modules containing explicit `(k , refl)` proof witnesses. Agda is the **checker** that verifies each emitted line individually.

This division of labor — external computation to find proofs, a simple kernel to check them — is the same pattern used by the largest verified proofs in computer science (the Four Color Theorem in Coq, the Kepler Conjecture in HOL Light). The oracle is *trusted to search correctly*; its output is *verified by the type-checker*. A bug in the oracle produces an Agda module that fails to type-check — it cannot silently introduce a false proof.

The pipeline evolved through four phases:

| Phase | Scripts | Innovation | Output |
|-------|---------|------------|--------|
| **Prototyping** (01–02) | Numerical exploration | Validate RT formula, curvature | No Agda output |
| **First generation** (03–04) | Flat enumeration | 90-region filled patch, raw equiv | `FilledSpec`, `FilledCut`, etc. |
| **Scaling** (05–13) | Orbit reduction, multi-strategy growth, multi-tiling | 717–1885 region patches, layer tower | `Dense*Spec`, `Layer54d*Spec`, etc. |
| **Bekenstein–Hawking** (14–17) | Entropic convergence analysis, half-bound proof | Sharp 1/2 bound, generic `from-two-cuts` | `Dense*HalfBound` |

Each phase built on the previous, reusing graph-construction and flow-computation infrastructure while adding new capabilities.

---

## 2. Environment

All scripts run under Python 3.12 with two dependencies:

| Package | Version | Role |
|---------|---------|------|
| NetworkX | 3.6.1 | Max-flow/min-cut computation (`nx.minimum_cut`) |
| NumPy | 2.4.4 | Coxeter geometry (matrix operations for {4,3,5} and {5,4}) |

The environment is pinned by `sim/prototyping/shell.nix` (NixOS 24.05) and `sim/prototyping/requirements.txt`. See [`getting-started/setup.md`](../getting-started/setup.md) §6 for installation instructions.

---

## 3. Script Registry

### 3.1 Phase 1 — Numerical Prototyping (no Agda output)

| Script | Purpose | Key Output |
|--------|---------|------------|
| **01** `happy_patch_cuts.py` | Build 6-tile star and 11-tile filled patches of the {5,4} tiling; compute min-cut for all contiguous boundary regions via max-flow; verify complement symmetry, subadditivity, and geodesic equality | Numerical tables: 20 regions (star), 90 regions (filled), 30/360 subadditivity checks — all pass |
| **02** `happy_patch_curvature.py` | Build the 11-tile polygon complex (30 vertices, 40 edges, 11 faces); compute combinatorial, angular, and Regge curvature; verify Gauss–Bonnet in all three formulations | Curvature tables: κ = −1/5 (interior), Σκ = χ = 1 by all three methods |

These two scripts validated the entire Phase 1.2 numerical blueprint before any Agda code was written. Every subsequent script imports graph-construction logic from `01`.

### 3.2 Phase 2 — First-Generation Code Emission

| Script | Purpose | Agda Modules Generated |
|--------|---------|------------------------|
| **03** `generate_filled_patch.py` | Enumerate 90 regions and 360 union triples for the 11-tile filled patch; emit flat-enumeration Agda modules with `abstract`-sealed subadditivity | `Common/FilledSpec.agda` (90 region + 360 union ctors), `Boundary/FilledCut.agda`, `Bulk/FilledChain.agda`, `Boundary/FilledSubadditivity.agda` (360 abstract cases), `Bridge/FilledObs.agda` |
| **04** `generate_raw_equiv.py` | Compute the forward map (RT: weights → min-cuts, 90 clauses) and backward map (peeling: min-cuts → weights, 15 clauses) for the 11-tile raw structural equivalence | `Bridge/FilledRawEquiv.agda` (RT lemma + extraction lemma + Iso + Equiv + ua + transport) |

Script 03 is the first use of the **Approach A+C strategy** (§3.6 of the historical development docs): Python finds the 360 `(k, refl)` witnesses (Approach C), and the Agda proof wraps them in `abstract` (Approach A) to prevent downstream RAM cascades. This pattern became the template for all subsequent large-case generators.

### 3.3 Phase 3 — 3D Extension and Multi-Strategy Growth

| Script | Purpose | Agda Modules Generated |
|--------|---------|------------------------|
| **05** `honeycomb_3d_prototype.py` | Implement {4,3,5} Coxeter geometry (Gram matrix, reflections, cell stabilizer, face crossings); build BFS star patch (32 cells); verify edge valence, min-cuts, curvature; gate check for 3D feasibility | No Agda output (feasibility probe) |
| **06** `generate_honeycomb_3d.py` | Generate Agda modules for the {4,3,5} BFS star patch (26 regions, all S=1) | `Common/Honeycomb3DSpec.agda`, `Boundary/Honeycomb3DCut.agda`, `Bulk/Honeycomb3DChain.agda`, `Bulk/Honeycomb3DCurvature.agda`, `Bridge/Honeycomb3DObs.agda` |
| **07** `honeycomb_3d_multiStrategy.py` | Implement four growth strategies — BFS (concentric shells), Dense (greedy max-connectivity), Geodesic (tube), Hemisphere (half-space) — and compare across target sizes | No Agda output (strategy comparison); **key finding**: Dense growth produces non-trivial min-cuts (up to 8), while BFS gives S ≈ 1 |
| **08** `generate_dense50.py` | Generate Agda modules for the Dense-50 patch (139 regions, S = 1–7) using flat enumeration | `Common/Dense50Spec.agda`, `Boundary/Dense50Cut.agda`, `Bulk/Dense50Chain.agda`, `Bulk/Dense50Curvature.agda`, `Bridge/Dense50Obs.agda` |
| **09** `generate_dense100.py` | Generate Agda modules for the Dense-100 patch (717 regions → 8 orbits) using **orbit reduction** | `Common/Dense100Spec.agda` (717 region ctors + 8 orbit ctors + 717-clause classify), `Boundary/Dense100Cut.agda` (8 S-cut-rep clauses + 1-line S-cut), `Bulk/Dense100Chain.agda`, `Bulk/Dense100Curvature.agda`, `Bridge/Dense100Obs.agda` |
| **10** `desitter_prototype.py` | Build the {5,3} dodecahedron star patch (6 faces, positive curvature); verify bond-graph isomorphism with {5,4} star and identical min-cut profiles; compute dS curvature (κ = +1/10); verify Gauss–Bonnet | No Agda output (numerical confirmation for WickRotation) |

Script 09 is the architectural pivot: it introduces the **orbit reduction strategy** (§6.5 of the historical development docs), reducing proof obligations from 717 flat `refl` cases to 8 orbit-representative `refl` cases + a 1-line lifting. This pattern scales to arbitrary patch sizes — adding cells grows only the `classify` function, not the proof.

### 3.4 Phase 4 — Resolution Tower and Area Law

| Script | Purpose | Agda Modules Generated |
|--------|---------|------------------------|
| **11** `generate_area_law.py` | Compute boundary surface area for each Dense-100 region (area = 6k − 2·|internal faces within A|); verify S ≤ area for all 717 regions; emit `abstract` area-law proof | `Boundary/Dense100AreaLaw.agda` (717 regionArea clauses + 717 abstract `(k, refl)` proofs) |
| **12** `generate_dense200.py` | Generate all 6 Agda modules for Dense-200 (1246 regions → 9 orbits) including orbit reduction + area law; verify monotonicity (max S grows 8 → 9) | `Common/Dense200Spec.agda`, `Boundary/Dense200Cut.agda`, `Bulk/Dense200Chain.agda`, `Bulk/Dense200Curvature.agda`, `Bridge/Dense200Obs.agda`, `Boundary/Dense200AreaLaw.agda` |
| **13** `generate_layerN.py` | Implement {5,4} Coxeter geometry ([5,4] group, tile stabilizer D₅, 5 edge crossings); build BFS-depth-N patches; emit orbit-reduced Agda modules for any depth | `Common/Layer54d{N}Spec.agda`, `Boundary/Layer54d{N}Cut.agda`, `Bulk/Layer54d{N}Chain.agda`, `Bridge/Layer54d{N}Obs.agda` — for depths 2–7 (21 to 3046 tiles) |

Script 13 is parameterized by `--depth N`, allowing the tower to be extended to arbitrary BFS depths. For the repository, depths 2–7 are generated, producing a 6-level {5,4} layer tower with exponential boundary growth (21 → 3046 tiles) but constant orbit count (2 orbits, maxCut = 2).

### 3.5 Phase 5 — The Discrete Bekenstein–Hawking Bound

| Script | Purpose | Agda Modules Generated |
|--------|---------|------------------------|
| **14a** `entropic_convergence.py` | Track η_N = max S / max area across resolutions and strategies; initial convergence analysis | No Agda output (data analysis); **finding**: adaptive max_rc confounds the measurement |
| **14b** `entropic_convergence_controlled.py` | Fix the confound: use FIXED max_rc=5; add {5,4} Dense growth, per-region-size tracking, distribution stats | No Agda output; **finding**: sup(S/area) = 0.5000 exactly, across all patches and tilings |
| **14c** `entropic_convergence_sup_half.py` | Sweep max_rc from 5 to 8; confirm sup(S/area) = 0.5 is stable, universal, and max_rc-independent | No Agda output; **finding**: 24 measurements, 23,963 regions, zero violations, sup = 0.5 in every case |
| **15** `discrete_bekenstein_hawking.py` | Graph-theoretic proof of S ≤ area/2 via the two-cut decomposition (area = n_cross + n_bdy); verify across 4 strategies, 2 tilings, 3 capacities | No Agda output; **finding**: 5,140 regions, 0 violations; proof sketch for `from-two-cuts` |
| **16** `half_bound_scaling.py` | Push to Dense-2000, add {4,4} Euclidean grid, {5,3} dodecahedron; non-unit capacities c = 1, 2, 3 | No Agda output; **finding**: 32,134 regions across 4 tilings, 4 strategies, 3 capacities — 0 violations |
| **17** `generate_half_bound.py` | Emit per-instance `HalfBoundWitness` Agda modules for Dense-100 and Dense-200: `abstract` proof of 2·S ≤ area with tight achiever | `Boundary/Dense100HalfBound.agda` (717 cases), `Boundary/Dense200HalfBound.agda` (1246 cases) |

Scripts 14a–14c form a methodological arc: 14a identifies a confound, 14b fixes it, 14c confirms the fix. Script 15 provides the graph-theoretic proof sketch that is formalized in `Bridge/HalfBound.agda`. Script 16 is the scaling confirmation across the full matrix of configurations. Script 17 is the final code generator, producing the per-instance witnesses consumed by `Bridge/SchematicTower.agda` §25.

---

## 4. The Pipeline Architecture

### 4.1 Data Flow

For each new patch instance, the pipeline follows a fixed pattern:

```
sim/prototyping/XX_generate_*.py          (Python oracle)
      │
      ├──▶ Common/*Spec.agda              (region type + orbit classification)
      ├──▶ Boundary/*Cut.agda             (S-cut via orbit reps)
      ├──▶ Bulk/*Chain.agda               (L-min via orbit reps)
      ├──▶ Bridge/*Obs.agda               (pointwise refl + funExt)
      ├──▶ Boundary/*AreaLaw.agda         (abstract: S ≤ area)     [optional]
      └──▶ Boundary/*HalfBound.agda       (abstract: 2·S ≤ area)   [optional]
                │
                ▼
      Bridge/GenericBridge.agda           (orbit-bridge-witness → BridgeWitness)
                │
                ▼
      Bridge/SchematicTower.agda          (mkTowerLevel → tower registration)
```

The oracle handles all combinatorial enumeration (Coxeter reflections, BFS/Dense growth, max-flow, orbit classification). The generic bridge theorem handles the proof — once. Adding a new patch requires **zero new hand-written Agda proof**.

### 4.2 The Orbit Reduction Pattern

For patches with more than ~200 regions, flat enumeration (one `refl` per region) wastes effort because many regions share the same min-cut value. The orbit reduction pattern, introduced in script 09 and used by all subsequent generators, factors the proof through a small orbit type:

**Generated data types:**

```
D100Region     — 717 constructors (one per region)
D100OrbitRep   — 8 constructors (one per distinct min-cut value)
classify100    — 717-clause function mapping each region to its orbit
```

**Generated observable functions:**

```
S-cut-rep : D100OrbitRep → ℚ≥0    — 8 clauses (one per orbit)
S-cut _ r = S-cut-rep (classify100 r)  — 1-line composition
```

**Generated proof:**

```
d100-pointwise-rep : (o : D100OrbitRep) → S-cut-rep o ≡ L-min-rep o
d100-pointwise-rep mc1 = refl    — 8 refl cases
...

d100-pointwise r = d100-pointwise-rep (classify100 r)  — 1-line lifting
```

The 717-clause `classify100` function is traversed only during concrete evaluation (when Agda reduces a specific constructor); the proof obligations remain on the 8-constructor orbit type. This pattern scales logarithmically: Dense-200 has 1246 regions but only 9 orbits (138× reduction), and {5,4} depth-7 has 1885 regions but only 2 orbits (942× reduction).

### 4.3 The `abstract` Barrier Strategy

Large case analyses (360 subadditivity triples, 717 area-law cases, 1246 half-bound cases) are sealed behind Agda's `abstract` keyword. This prevents downstream modules from re-normalizing the proof when they use the sealed lemma — halting the RAM cascade documented in [Agda Issue #4573](https://github.com/agda/agda/issues/4573).

The `abstract` barrier is safe because all sealed proofs target **propositional types** (`_≤ℚ_` is propositional by `isProp≤ℚ`). Sealing a propositional proof prevents re-normalization without losing information — any other proof of the same fact would be propositionally equal to the sealed one.

**Practical consequence:** If you modify an `abstract` module's *type signature*, all downstream modules must be rechecked. But changes to the proof *body* inside `abstract` do not propagate — that is the point.

### 4.4 Judgmental Stability

Every `refl`-based proof in the emitted modules depends on a critical invariant: **both sides of each equality reduce to the same ℕ normal form**. This requires:

1. **Scalar constants defined once.** The constants `1q`, `2q` (from `Util/Scalars.agda`) and all curvature constants (from `Util/Rationals.agda`) are defined in a single location and imported everywhere. Both the `S-cut` and `L-min` modules import from the same source, guaranteeing identical normal forms.

2. **Pattern matching on closed constructors.** For each region constructor `r`, `S-cut _ r` and `L-min _ r` both reduce to the same ℕ literal via deterministic pattern matching on closed constructor terms.

3. **Orbit-level agreement.** In orbit-reduced modules, `S-cut-rep` and `L-min-rep` are defined by separate 8-clause lookups returning the same ℕ literals. The `classify` function absorbs the 717-clause case analysis; the observable lookup operates on the small orbit type.

If any of these invariants is broken (e.g., a constant is reconstructed independently, or a classify clause maps to the wrong orbit), the `refl` proof fails at type-check time, producing an immediate error. The type-checker catches oracle bugs.

---

## 5. Coxeter Geometry Implementation

### 5.1 The {4,3,5} Honeycomb (3D)

Scripts 05–09, 11–12, and 14–17 use the {4,3,5} Coxeter group [4,3,5] with:

- **Generators:** s₀, s₁, s₂, s₃ (four reflections)
- **Coxeter matrix:** m(s₀,s₁) = 4, m(s₁,s₂) = 3, m(s₂,s₃) = 5
- **Gram matrix:** G_ij = −cos(π/m_ij), signature (3,1) → compact hyperbolic
- **Cell stabilizer:** ⟨s₀, s₁, s₂⟩ ≅ [4,3] (order 48, the octahedral group)
- **Face crossings:** 6 conjugates of s₃ by the cell stabilizer
- **Edge classification:** 12 adjacent face-pairs (dihedral order 5) + 3 opposite pairs

All geometry is computed in the **simple root basis** using the Gram matrix directly — no eigendecomposition or Poincaré ball embedding needed. Each cell is represented by a 4×4 matrix g (product of Coxeter reflections). The center of cell g is g @ cell_center. The 6 neighbors of cell g are g @ F_k for k = 0..5.

### 5.2 The {5,4} Tiling (2D)

Script 13 uses the {5,4} Coxeter group [5,4] with:

- **Generators:** s₀, s₁, s₂ (three reflections)
- **Coxeter matrix:** m(s₀,s₁) = 5, m(s₁,s₂) = 4, m(s₀,s₂) = 2
- **Gram matrix:** G_ij = −cos(π/m_ij), signature (2,1) → hyperbolic
- **Tile stabilizer:** ⟨s₀, s₁⟩ ≅ D₅ (dihedral group, order 10)
- **Edge crossings:** 5 conjugates of s₂ by the tile stabilizer

The construction is identical in structure to the 3D case, with 3×3 matrices instead of 4×4. Each tile is represented by a 3×3 matrix, its center is g @ tile_center, and its 5 neighbors are g @ F_k for k = 0..4.

### 5.3 Growth Strategies

Four strategies are implemented (script 07), all producing valid connected patches:

| Strategy | Growth Rule | Topology | Min-Cut Behavior |
|----------|-----------|----------|-----------------|
| **BFS** | Concentric shells from center | Thin shells, low connectivity | S ≈ 1–2 (all singletons have S = 1) |
| **Dense** | Greedy: add frontier cell with most existing neighbors | Clumpy, high connectivity | S = 1–9 (genuine multi-face RT surfaces) |
| **Geodesic** | Spine along opposite-face axis + 1-shell fattening | Tubular, anisotropic | S = 2 (cross-section), 0 full-valence edges |
| **Hemisphere** | BFS using only 3 of 6 face crossings | Saturates at ~20 cells (finite orbit) | Limited data |

The **Dense strategy** is the correct choice for holographic analysis: it produces multiply-connected bulk geometry with non-trivial separating surfaces, analogous to the RT minimal surfaces in AdS/CFT. BFS shells serve as a baseline with degenerate min-cut behavior.

---

## 6. Verification Chain

Each generated Agda module passes through a multi-stage verification chain:

1. **Python numerical verification.** The oracle computes min-cuts via `nx.minimum_cut`, boundary areas via the decomposition formula area = faces_per_cell · |A| − 2 · |internal links within A|, and verifies all bounds (S ≤ area, 2·S ≤ area) before emitting Agda code. Any violation causes the script to abort without generating files.

2. **Agda parsing.** The type-checker parses the emitted data types (up to 1885 constructors for `Layer54d7Region`) and function definitions. This is the most resource-intensive step for large modules, taking 30–90 seconds for Dense-200.

3. **Agda type-checking.** Each `(k, refl)` witness is independently verified: the type-checker evaluates `k + (S r)` by structural recursion on ℕ and confirms it equals `area r` (or `L-min r` for pointwise agreement). This is the **De Bruijn criterion** in action: the kernel is "stupid" and checks each case individually.

4. **Downstream consumption.** The generic bridge theorem (`GenericEnriched`) or `orbit-bridge-witness` consumes the emitted `obs-path` and produces the full enriched equivalence + Univalence path + verified transport. No per-instance proof engineering needed.

5. **Tower registration.** `mkTowerLevel` in `Bridge/SchematicTower.agda` registers the new patch level with its `maxCut` value and `BridgeWitness`.

If any stage fails, the error propagates immediately: the Python oracle aborts (stage 1), Agda reports a type error (stages 2–3), or the downstream module fails to load (stages 4–5). There is no silent failure mode.

---

## 7. Reproducibility

### 7.1 Determinism

All scripts are deterministic: given the same inputs (max-cells, max-region-cells, depth), they produce byte-identical output. This is ensured by:

- **Sorted iteration** over sets and dictionaries at all enumeration points
- **Deterministic BFS** with sorted frontier processing
- **Canonical edge/cell identification** via rounded floating-point keys (`ROUND_DIGITS = 5` or `8`)

### 7.2 Regeneration

To regenerate all auto-generated modules from scratch:

```bash
cd sim/prototyping

# Phase 2: Filled patch (11-tile)
python3 03_generate_filled_patch.py

# Phase 3: 3D patches
python3 06_generate_honeycomb_3d.py
python3 08_generate_dense50.py
python3 09_generate_dense100.py

# Phase 4: Area law, Dense-200, Layer tower
python3 11_generate_area_law.py
python3 12_generate_dense200.py
for d in 2 3 4 5 6 7; do
  python3 13_generate_layerN.py --depth $d
done

# Phase 5: Half-bound witnesses
python3 17_generate_half_bound.py
```

After regeneration, delete cached Agda interfaces (`find src/ -name '*.agdai' -delete`) and reload from scratch.

### 7.3 Environment Pinning

The `shell.nix` in `sim/prototyping/` pins NixOS 24.05, Python 3.12, NetworkX 3.6.1, and NumPy 2.4.4. Running `nix-shell` in that directory enters the exact environment used for all code generation. Alternatively, `requirements.txt` pins the Python packages for `pip install` in a virtual environment.

---

## 8. Scaling Report (Summary)

| Instance | Script | Regions | Orbits | Max S | Parse Time | Check Time | Total Lines |
|----------|--------|---------|--------|-------|------------|------------|-------------|
| Filled (11-tile) | 03 | 90 | — | 4 | <5s | <10s | ~1,765 |
| Honeycomb BFS | 06 | 26 | — | 1 | <5s | <10s | ~304 |
| Dense-50 | 08 | 139 | — | 7 | <5s | <10s | ~701 |
| Dense-100 | 09 | 717 | 8 | 8 | 30–60s | 10–30s | ~1,166 |
| Dense-100 AreaLaw | 11 | 717 | — | — | 20–60s | 30–120s | ~2,099 |
| Dense-200 (all 6) | 12 | 1,246 | 9 | 9 | 30–90s | 30–120s | ~5,213 |
| {5,4} depth 7 | 13 | 1,885 | 2 | 2 | 30–90s | 10–30s | ~2,216 |
| Dense-100 HalfBound | 17 | 717 | — | — | 20–60s | 30–120s | ~1,390 |
| Dense-200 HalfBound | 17 | 1,246 | — | — | 30–90s | 30–120s | ~2,350 |

Parse time is dominated by large `data` declarations (717–1885 constructors). Check time is dominated by `abstract`-sealed proofs (717–1246 `(k, refl)` cases). Both scale linearly with region count; the orbit reduction strategy keeps proof obligations constant or logarithmic.

For detailed resource usage per module, see [`getting-started/building.md`](../getting-started/building.md) §7.

---

## 9. Extending the Pipeline

### 9.1 Adding a New Patch Instance

To add a new patch (e.g., Dense-500 on {4,3,5}):

1. **Copy** `09_generate_dense100.py` as a template.
2. **Adjust** `MAX_CELLS` and file/module names.
3. **Run** the new script to generate 5 Agda modules.
4. **Register** the new `OrbitReducedPatch` in `Bridge/SchematicTower.agda` via `mkTowerLevel`.

The generic bridge theorem handles the proof automatically. No hand-written Agda is needed beyond the one-line `mkTowerLevel` call.

### 9.2 Adding a New Tiling

To add a new tiling (e.g., the {3,7} hyperbolic triangular tiling):

1. **Implement** the Coxeter geometry: Gram matrix, reflections, tile stabilizer, edge crossings. Follow the pattern from script 05 ({4,3,5}) or script 13 ({5,4}).
2. **Implement** a growth strategy (Dense recommended for non-trivial min-cuts).
3. **Feed** the patch topology into the existing flow-graph and region-enumeration infrastructure (dimension-agnostic via NetworkX).
4. **Emit** Agda modules following the `OrbitReducedPatch` pattern.

The flow-graph construction, min-cut computation, and Agda emission are independent of the specific tiling — only the Coxeter geometry and growth strategy are tiling-specific.

### 9.3 Adding a New Constraint Level

To add a new constraint (beyond S = L, S ≤ area, and 2·S ≤ area):

1. **Define** the constraint mathematically and implement the Python verification.
2. **Generate** `abstract`-sealed `(k, refl)` witnesses following the area-law pattern (script 11).
3. **Define** a new Agda record type (like `HalfBoundWitness`) and integrate into the tower infrastructure.

The `abstract` barrier + propositional target type pattern is generic: it works for any inequality constraint on ℕ-valued observables.

---

## 10. Design Decisions

1. **Python over Agda metaprogramming.** Agda's reflection API can generate terms internally, but it creates large ASTs in memory during type-checking. External Python avoids this: the generated file is parsed once (creating the AST), and then the small `refl` proofs are checked individually. This is more memory-efficient for 700+ cases.

2. **One script per patch family, not one script for all.** Each generator (08, 09, 12, 13, 17) is self-contained and independently runnable. This avoids a monolithic "generate-everything" script that would be harder to debug, version, and extend.

3. **Output files are committed to the repository.** The generated `.agda` files are checked into `src/`, not regenerated on every build. This ensures reproducibility without requiring Python in the Agda build environment and allows Agda users to type-check without running the oracle.

4. **Prototype scripts are preserved alongside generators.** Scripts 01, 02, 05, 07, 10, 14a–14c, 15, 16 produce no Agda output but are committed with their `_OUTPUT.txt` files as reproducible numerical evidence. They document the decision chain that led to each architectural choice.

5. **All scripts import from 01 and 07.** The graph-construction logic (patch topology, flow graphs, min-cut computation) is defined once in `01_happy_patch_cuts.py` (2D) and `07_honeycomb_3d_multiStrategy.py` (3D), and imported by all downstream scripts. This avoids duplicating the NetworkX max-flow interface.

---

## 11. Cross-References

| Topic | Document |
|-------|----------|
| Module dependency DAG and layer diagram | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Build instructions and type-check order | [`getting-started/building.md`](../getting-started/building.md) |
| Generic bridge theorem (consumes oracle output) | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Orbit reduction strategy (engineering) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| `abstract` barrier (engineering) | [`engineering/abstract-barrier.md`](abstract-barrier.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](generic-bridge-pattern.md) |
| Scaling report (per-module times) | [`engineering/scaling-report.md`](scaling-report.md) |
| Bekenstein–Hawking half-bound (formal) | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Per-instance data sheets | [`instances/`](../instances/) |
| Historical development (§3.5–3.6 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §3.5–3.6 |