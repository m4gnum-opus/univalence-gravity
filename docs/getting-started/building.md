# Building & Type-Checking

This guide explains how to type-check the **Univalence Gravity** repository, the recommended module load order, and what to expect during verification.

## Prerequisites

Ensure your environment is set up per [`setup.md`](setup.md):

| Component | Version |
|-----------|---------|
| Agda      | 2.8.0   |
| cubical   | April 2026 (HEAD) |
| Python    | 3.12 (for oracle scripts only) |

Verify with:

```bash
agda --version          # Agda version 2.8.0
agda --print-agda-dir   # should show path containing cubical
```

## Quick Verification (Core Theorems)

To check the seven headline results without loading the full repository:

```bash
# Discrete Ryu–Takayanagi (generic, subsumes all 12 instances)
agda src/Bridge/GenericBridge.agda

# Discrete Gauss–Bonnet (Σκ = χ by refl)
agda src/Bulk/GaussBonnet.agda

# Discrete Bekenstein–Hawking (S ≤ area/2, generic + tower)
agda src/Bridge/HalfBound.agda

# Discrete Wick Rotation (curvature-agnostic bridge)
agda src/Bridge/WickRotation.agda

# No Closed Timelike Curves (structural acyclicity)
agda src/Causal/NoCTC.agda

# Matter as Topological Defects (Q₈ Wilson loops)
agda src/Gauge/Holonomy.agda

# Quantum Superposition Bridge (⟨S⟩ = ⟨L⟩, 5-line proof)
agda src/Quantum/QuantumBridge.agda
```

Each command loads the target module and all its transitive dependencies. Agda caches interface files (`.agdai`) in the source tree, so subsequent loads of overlapping dependencies are fast.

> **Tip:** On first load, modules with large auto-generated datatypes (e.g., `Common/Dense200Spec.agda` with 1246 constructors) may take a minute to parse. Subsequent loads use the cached interface.

## Full Repository Type-Check

To verify every module in the repository, load the heaviest downstream modules — their transitive closures cover the entire source tree:

```bash
# This single module transitively loads almost everything:
agda src/Bridge/SchematicTower.agda

# These cover the remaining independent layers:
agda src/Causal/LightCone.agda
agda src/Quantum/StarQuantumBridge.agda
agda src/Gauge/RepCapacity.agda
agda src/Bridge/EnrichedStarStepInvariance.agda
agda src/Bridge/Dense100Thermodynamics.agda
```

**Expected total time (first load, cold cache):** 15–45 minutes depending on machine RAM and CPU. The bulk of this is parsing large auto-generated `data` declarations (Dense-100: 717 constructors, Dense-200: 1246 constructors, Layer-54-d7: 1885 constructors).

**Subsequent loads (warm `.agdai` cache):** Under 1 minute for any individual module.

## Module Dependency Order

The dependency DAG has four tiers. Within each tier, modules can be loaded in any order; the only constraint is that all dependencies from earlier tiers are loaded first.

### Tier 0 — Utilities (no internal dependencies)

```
Util/Scalars.agda           ℚ≥0 = ℕ, _+ℚ_, _≤ℚ_
Util/Rationals.agda         ℚ₁₀ = ℤ, curvature constants
Util/NatLemmas.agda         ℕ arithmetic: +-comm, cancel, cong
```

### Tier 1 — Specifications & Standalone Types

```
Common/ObsPackage.agda      ObsPackage record (1 field)
Common/TreeSpec.agda        Tree pilot: Vertex, Edge, Region
Common/StarSpec.agda        6-tile star: Tile, Bond, Region
Common/FilledSpec.agda      11-tile filled: 90 regions, 360 unions  (AUTO-GEN)
Common/Honeycomb3DSpec.agda {4,3,5} BFS star: 26 regions           (AUTO-GEN)
Common/Dense50Spec.agda     Dense-50: 139 regions                   (AUTO-GEN)
Common/Dense100Spec.agda    Dense-100: 717 regions → 8 orbits       (AUTO-GEN)
Common/Dense200Spec.agda    Dense-200: 1246 regions → 9 orbits      (AUTO-GEN)
Common/Layer54d2Spec.agda   {5,4} depth 2: 15 regions → 2 orbits   (AUTO-GEN)
  ...
Common/Layer54d7Spec.agda   {5,4} depth 7: 1885 regions → 2 orbits (AUTO-GEN)

Bulk/PatchComplex.agda      11-tile polygon complex (30 vertices)
Bulk/DeSitterPatchComplex.agda  {5,3} star complex (15 vertices)

Bridge/BridgeWitness.agda   BridgeWitness record (standalone)

Gauge/FiniteGroup.agda      FiniteGroup record + ℤ/2 instance
Causal/Event.agda           Event, CausalLink, CausalChain, _<ℕ_
Quantum/AmplitudeAlg.agda   AmplitudeAlg record + ℤ[i], ℕ instances
```

### Tier 2 — Observables, Curvature & Core Infrastructure

```
── Boundary/Bulk observable lookups (one per patch, mostly AUTO-GEN) ──
Boundary/TreeCut.agda       Boundary/StarCut.agda
Bulk/TreeChain.agda         Bulk/StarChain.agda
Boundary/FilledCut.agda     Bulk/FilledChain.agda
Boundary/Honeycomb3DCut.agda  Bulk/Honeycomb3DChain.agda
Boundary/Dense50Cut.agda    Bulk/Dense50Chain.agda
Boundary/Dense100Cut.agda   Bulk/Dense100Chain.agda
Boundary/Dense200Cut.agda   Bulk/Dense200Chain.agda
Boundary/Layer54d{2..7}Cut.agda  Bulk/Layer54d{2..7}Chain.agda

── Structural properties ──
Boundary/StarSubadditivity.agda     30 subadditivity cases (refl)
Boundary/FilledSubadditivity.agda   360 cases (abstract, AUTO-GEN)
Bulk/StarMonotonicity.agda          10 monotonicity cases (refl)

── Curvature ──
Bulk/Curvature.agda                 κ for {5,4} (combinatorial)
Bulk/GaussBonnet.agda               Σκ = χ by refl  ★ Theorem 1
Bulk/DeSitterCurvature.agda         κ for {5,3} (positive)
Bulk/DeSitterGaussBonnet.agda       dS Gauss–Bonnet by refl
Bulk/Honeycomb3DCurvature.agda      3D edge curvature  (AUTO-GEN)
Bulk/Dense{50,100,200}Curvature.agda                   (AUTO-GEN)

── Parameterized observables (for dynamics) ──
Boundary/StarCutParam.agda          S-param : (Bond → ℚ≥0) → Region → ℚ≥0
Bulk/StarChainParam.agda            L-param + SL-param (S ≡ L for any w)

── Gauge infrastructure ──
Gauge/ZMod.agda                     ℤ/3 instance + commutativity
Gauge/Q8.agda                       Q₈: 8 elements, 400-case associativity
Gauge/Connection.agda               GaugeConnection, Dir, readBond
Gauge/Holonomy.agda                 holonomy, ParticleDefect  ★ Theorem 6
Gauge/ConjugacyClass.agda           Conjugacy classes, species
Gauge/RepCapacity.agda              Dimension functor, GaugedPatchWitness

── Causal infrastructure ──
Causal/NoCTC.agda                   No CTCs by ℕ well-foundedness  ★ Theorem 5

── Quantum infrastructure ──
Quantum/Superposition.agda          Superposition type, 𝔼 functional
Quantum/QuantumBridge.agda          ⟨S⟩ ≡ ⟨L⟩ (5 lines)  ★ Theorem 7
```

### Tier 3 — Bridge Equivalences, Tower & Integration

```
── Per-instance bridge (pointwise agreement + package path) ──
Bridge/TreeObs.agda          Bridge/StarObs.agda
Bridge/FilledObs.agda        Bridge/Honeycomb3DObs.agda     (AUTO-GEN)
Bridge/Dense50Obs.agda       Bridge/Dense100Obs.agda        (AUTO-GEN)
Bridge/Dense200Obs.agda      Bridge/Layer54d{2..7}Obs.agda  (AUTO-GEN)

── Enriched star equiv (hand-written, the original bridge) ──
Bridge/StarEquiv.agda             star-obs-path = funExt star-pointwise
Bridge/EnrichedStarObs.agda       EnrichedBdy ≃ EnrichedBulk + ua + transport
Bridge/FullEnrichedStarObs.agda   FullBdy ≃ FullBulk (subadd ↔ mono)
Bridge/EnrichedStarEquiv.agda     Theorem3, theorem3, BridgeWitness

── Generic bridge (the core innovation — proves once, used everywhere) ──
Bridge/GenericBridge.agda         PatchData → BridgeWitness  ★ Theorem 1 (RT)
Bridge/GenericValidation.agda     Retroactive validation of 6 instances
Bridge/HalfBound.agda             from-two-cuts, HalfBoundWitness  ★ Theorem 3

── Area law & half-bound (per-instance, AUTO-GEN) ──
Boundary/Dense100AreaLaw.agda     717 abstract (k, refl) proofs
Boundary/Dense200AreaLaw.agda     1246 abstract (k, refl) proofs
Boundary/Dense100HalfBound.agda   717 abstract half-bound proofs  (AUTO-GEN)
Boundary/Dense200HalfBound.agda   1246 abstract half-bound proofs (AUTO-GEN)

── Coarse-graining & thermodynamics ──
Bridge/CoarseGrain.agda                CoarseGrainWitness, CoarseGrainedRT
Bridge/Dense100Thermodynamics.agda     CoarseGrainedRT + HalfBound integration

── Dynamics ──
Bridge/StarStepInvariance.agda         perturb + step-invariant
Bridge/StarDynamicsLoop.agda           loop-invariant (list induction)
Bridge/EnrichedStarStepInvariance.agda full-equiv-w for any w

── Wick rotation ──
Bridge/WickRotation.agda               WickRotationWitness  ★ Theorem 4

── Schematic tower (the heaviest module — imports most of the repo) ──
Bridge/SchematicTower.agda    TowerLevel, LayerStep, ConvergenceCertificate3L-HB,
                              DiscreteBekensteinHawking  ★ Theorem 3 (tower form)

── Causal diamond ──
Causal/CausalDiamond.agda    CausalDiamond, maximin, proper-time
Causal/LightCone.agda        FutureCone, Spacelike, same-time-spacelike

── Quantum star bridge ──
Quantum/StarQuantumBridge.agda  star-quantum-bridge for Q₈ + ℤ[i]

── Raw structural equivalences (not on critical path) ──
Bridge/StarRawEquiv.agda      (DEAD CODE — superseded by GenericBridge)
Bridge/FilledRawEquiv.agda    (AUTO-GEN, 11-tile peeling strategy)
```

## Auto-Generated Modules

Modules marked `(AUTO-GEN)` are produced by the Python oracle scripts in `sim/prototyping/`. They should **not** be edited by hand. To regenerate:

| Script | Generates |
|--------|-----------|
| `03_generate_filled_patch.py` | FilledSpec, FilledCut, FilledChain, FilledSubadditivity, FilledObs |
| `06_generate_honeycomb_3d.py` | Honeycomb3DSpec, Honeycomb3DCut, Honeycomb3DChain, Honeycomb3DCurvature, Honeycomb3DObs |
| `08_generate_dense50.py` | Dense50Spec, Dense50Cut, Dense50Chain, Dense50Curvature, Dense50Obs |
| `09_generate_dense100.py` | Dense100Spec, Dense100Cut, Dense100Chain, Dense100Curvature, Dense100Obs |
| `11_generate_area_law.py` | Dense100AreaLaw |
| `12_generate_dense200.py` | Dense200Spec, Dense200Cut, Dense200Chain, Dense200Curvature, Dense200Obs, Dense200AreaLaw |
| `13_generate_layerN.py --depth N` | Layer54d{N}Spec, Layer54d{N}Cut, Layer54d{N}Chain, Layer54d{N}Obs |
| `17_generate_half_bound.py` | Dense100HalfBound, Dense200HalfBound |

Example regeneration:

```bash
cd sim/prototyping
python3 09_generate_dense100.py          # regenerates 5 Dense-100 modules
python3 13_generate_layerN.py --depth 7  # regenerates 4 Layer-54-d7 modules
python3 17_generate_half_bound.py        # regenerates 2 HalfBound modules
```

> **Note:** The Python oracle scripts depend on `numpy` and `networkx`. See [`setup.md`](setup.md) §6 for environment setup.

## The `abstract` Barrier

Several auto-generated modules use Agda's `abstract` keyword to seal large proofs:

| Module | Cases | Purpose |
|--------|-------|---------|
| `Boundary/FilledSubadditivity.agda` | 360 | Subadditivity of S on 11-tile patch |
| `Boundary/Dense100AreaLaw.agda` | 717 | Discrete area law S ≤ area |
| `Boundary/Dense200AreaLaw.agda` | 1246 | Discrete area law S ≤ area |
| `Boundary/Dense100HalfBound.agda` | 717 | Half-bound 2·S ≤ area |
| `Boundary/Dense200HalfBound.agda` | 1246 | Half-bound 2·S ≤ area |

The `abstract` barrier prevents downstream modules from re-normalizing these large case analyses, avoiding the RAM cascade documented in [Agda Issue #4573](https://github.com/agda/agda/issues/4573). Since all sealed proofs target propositional types (`_≤ℚ_` is propositional by `isProp≤ℚ`), the barrier does not damage any Univalence bridge or transport computation.

**Practical consequence:** If you modify an `abstract` module's *type signature*, all downstream modules must be rechecked. But changes to the proof *body* inside `abstract` do not propagate — that is the point.

## Expected Resource Usage

| Module | Parse Time | Check Time | Peak RAM |
|--------|-----------|------------|----------|
| `Common/Dense200Spec.agda` | 30–90s | 10–30s | ~2 GB |
| `Boundary/Dense200AreaLaw.agda` | 20–60s | 30–120s | ~3 GB |
| `Bridge/SchematicTower.agda` | 5–15s | 30–90s | ~2 GB |
| `Gauge/Q8.agda` (400-case assoc) | 5–10s | 10–30s | ~1.5 GB |
| Most hand-written modules | <5s | <10s | <1 GB |

**Recommendation:** At least 8 GB of RAM for full repository type-checking. 16 GB is comfortable. If memory is tight, check modules individually rather than loading `SchematicTower.agda` (which transitively pulls in everything).

## Troubleshooting

### "Not in scope" errors on cubical imports

Ensure `~/.agda/libraries` contains the full absolute path to `cubical.agda-lib` and `~/.agda/defaults` contains `cubical`. See [`setup.md`](setup.md) §4.

### Out-of-memory on large modules

Increase the stack/heap limits:

```bash
agda +RTS -M8G -RTS src/Bridge/SchematicTower.agda
```

Or check modules individually rather than through the heaviest transitive closure.

### Stale `.agdai` caches after regeneration

If you regenerate auto-generated modules, delete their cached interfaces:

```bash
find src/ -name '*.agdai' -delete
```

Then reload from scratch. This forces Agda to re-parse and re-check all modules.

### Module load order errors

Agda resolves dependencies automatically — you do not need to manually specify a load order. Just invoke `agda` on the target module and it will load all transitive dependencies. The tier diagram above is for *understanding* the architecture, not for manual sequencing.

## Next Steps