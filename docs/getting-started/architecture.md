# Architecture

This document describes the module dependency structure, layer diagram, and design rationale for the **Univalence Gravity** source tree. For build instructions and type-checking order, see [`building.md`](building.md). For the complete theorem registry, see [`formal/01-theorems.md`](../formal/01-theorems.md).

---

## Conceptual Layers

The `src/` tree is organized into seven directories, each corresponding to a conceptual layer with a well-defined role and dependency direction. Information flows **downward** through the layers; no module imports from a layer above it.

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   Quantum/          Causal/            Gauge/                    │
│   AmplitudeAlg      Event              FiniteGroup, ZMod, Q8     │
│   Superposition     CausalDiamond      Connection, Holonomy      │
│   QuantumBridge     NoCTC              ConjugacyClass            │
│   StarQuantumBr.    LightCone          RepCapacity               │
│                                                                  │
│   ─── Enrichment Layers (additive, orthogonal to each other) ──  │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Bridge/                                                        │
│   GenericBridge          ← the core innovation (proven once)     │
│   GenericValidation      ← retroactive consistency (6 instances) │
│   SchematicTower         ← tower assembly + convergence cert.    │
│   BridgeWitness          ← universal result record               │
│   HalfBound              ← discrete Bekenstein–Hawking           │
│   WickRotation           ← curvature-agnostic coherence          │
│   CoarseGrain            ← thermodynamic coarse-graining         │
│   StarStepInvariance     }                                       │
│   StarDynamicsLoop       } dynamics (parameterized weight)       │
│   EnrichedStarStepInv.   }                                       │
│   Dense100Thermodynamics ← area law + half-bound integration     │
│   StarObs, FilledObs, …  ← per-instance pointwise agreement      │
│   StarEquiv, …           ← per-instance enriched equivalence     │
│                                                                  │
│   ─── Bridge Layer (holographic correspondence) ──────────────── │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Boundary/                           Bulk/                      │
│   TreeCut, StarCut, …                 TreeChain, StarChain, …    │
│   StarCutParam                        StarChainParam             │
│   StarSubadditivity                   StarMonotonicity           │
│   FilledSubadditivity (abstract)      PatchComplex, Curvature    │
│   Dense100AreaLaw     (abstract)      GaussBonnet                │
│   Dense100HalfBound   (abstract)      DeSitter{PatchComplex,     │
│   Dense200AreaLaw     (abstract)        Curvature, GaussBonnet}  │
│   Dense200HalfBound   (abstract)      Honeycomb3DCurvature       │
│                                       Dense{50,100,200}Curvature │
│                                                                  │
│   ─── Observable / Geometry Layer ────────────────────────────── │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Common/                                                        │
│   ObsPackage             ← shared 1-field record                 │
│   TreeSpec, StarSpec     ← hand-written patch specifications     │
│   FilledSpec             ← auto-generated (90 regions)           │
│   Honeycomb3DSpec        ← auto-generated (26 regions)           │
│   Dense50Spec            ← auto-generated (139 regions)          │
│   Dense100Spec           ← auto-generated (717 → 8 orbits)       │
│   Dense200Spec           ← auto-generated (1246 → 9 orbits)      │
│   Layer54d{2..7}Spec     ← auto-generated (15–1885 → 2 orbits)   │
│                                                                  │
│   ─── Specification Layer ────────────────────────────────────── │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│   Util/                                                          │
│   Scalars      (ℚ≥0 = ℕ, _+ℚ_, _≤ℚ_)                            │
│   Rationals    (ℚ₁₀ = ℤ, curvature constants)                    │
│   NatLemmas    (+-comm, +-assoc, cancel, cong)                   │
│                                                                  │
│   ─── Utility Layer (no internal deps) ───────────────────────── │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

**Key architectural property:** The three enrichment layers (Quantum, Causal, Gauge) are **mutually independent** and **additive**. Each enriches the holographic network with new structure (superposition, time, matter) without modifying or depending on the other two. They all consume the Bridge layer's output but never import from each other.

---

## The Generic Bridge — Architectural Pivot

The single most important module in the repository is `Bridge/GenericBridge.agda`. It contains:

- **`PatchData`** — the minimal interface for any holographic patch (a region type, two observable functions, and a path between them).
- **`OrbitReducedPatch`** — the orbit-reduced variant used by large patches (717+ regions).
- **`GenericEnriched`** — a parameterized module that proves, *once*, the full enriched type equivalence + Univalence path + verified transport for *any* `PatchData`.
- **`orbit-bridge-witness`** — the composition `OrbitReducedPatch → PatchData → BridgeWitness` in a single function call.

Every holographic bridge in the repository is an instantiation of `GenericEnriched`:

```
                    ┌─────────────────────┐
                    │  PatchData          │
                    │  (RegionTy, S∂, LB, │
                    │   obs-path)         │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼────────┐  ┌────▼────┐  ┌────────▼───────┐
     │ Hand-written    │  │ Orbit-  │  │ Auto-generated │
     │ PatchData       │  │ Reduced │  │ PatchData      │
     │ (Star, Filled,  │  │ Patch   │  │ (Layer54d2–d7) │
     │ Honeycomb, D50) │  │ (D100,  │  │                │
     └────────┬────────┘  │  D200)  │  └────────┬───────┘
              │           └────┬────┘           │
              │                │                │
              └────────────────┼────────────────┘
                               │
                    ┌──────────▼────────────┐
                    │  GenericEnriched      │
                    │  (proven ONCE)        │
                    │                       │
                    │  → EnrichedBdy        │
                    │  → EnrichedBulk       │
                    │  → enriched-equiv     │
                    │  → enriched-ua-path   │
                    │  → enriched-transport │
                    │  → BridgeWitness      │
                    └──────────┬────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼───────┐  ┌────▼────────┐  ┌───▼────────────┐
     │ SchematicTower │  │ WickRotation│  │ Thermodynamics │
     │ (all levels)   │  │ (dS/AdS)    │  │ (area law +    │
     │                │  │             │  │  half-bound)   │
     └────────────────┘  └─────────────┘  └────────────────┘
```

The factorization ensures that **adding a new patch instance requires zero new hand-written proof**. The Python oracle generates the `OrbitReducedPatch` data (Spec, Cut, Chain, Obs modules); `orbit-bridge-witness` produces the `BridgeWitness` automatically.

---

## Module Dependency DAG

The following diagram shows the critical-path dependencies. Arrows point from importer to imported module. Modules at the same vertical level have no mutual dependencies.

```
Util/Scalars ─────────────────┬──────────────────────────────────────┐
Util/Rationals ───────────────┤                                      │
Util/NatLemmas ───────────────┘                                      │
       │                                                             │
       ▼                                                             │
Common/ObsPackage                                                    │
Common/{Tree,Star}Spec  ◄── hand-written                             │
Common/{Filled,...,Layer54d7}Spec  ◄── AUTO-GEN                      │
       │                                                             │
       ├──────────────────────────┬──────────────────────────┐       │
       ▼                          ▼                          ▼       │
  Boundary/                      Bulk/                     Bulk/     │
  {Tree,Star,…}Cut          {Tree,Star,…}Chain         PatchComplex  │
  StarCutParam               StarChainParam             Curvature    │
  StarSubadditivity          StarMonotonicity           GaussBonnet  │
  FilledSubadditivity        DeSitterPatchComplex                    │
  Dense{100,200}AreaLaw      DeSitterCurvature               │       │
  Dense{100,200}HalfBound    DeSitterGaussBonnet             │       │
       │                          │                          │       │
       └──────────┬───────────────┘                          │       │
                  ▼                                          │       │
  Bridge/BridgeWitness  (standalone leaf)                    │       │
  Bridge/GenericBridge  ─────────────────────────────────────┤       │
  Bridge/GenericValidation  (6 instances validated)          │       │
  Bridge/HalfBound  (from-two-cuts, two-le-sum)              │       │
       │                                                     │       │
       ├── Bridge/{Star,Filled,…}Obs                         │       │
       ├── Bridge/{Star,Filled,…}Equiv                       │       │
       ├── Bridge/EnrichedStarObs                            │       │
       ├── Bridge/FullEnrichedStarObs                        │       │
       ├── Bridge/EnrichedStarEquiv                          │       │
       ├── Bridge/StarStepInvariance                         │       │
       ├── Bridge/StarDynamicsLoop                           │       │
       ├── Bridge/EnrichedStarStepInvariance                 │       │
       ├── Bridge/CoarseGrain                                │       │
       ├── Bridge/Dense100Thermodynamics ◄───────────────────┘       │
       ├── Bridge/WickRotation ◄─────────────────────────────────────┘
       │                                                     
       ▼                                                     
  Bridge/SchematicTower  ← HEAVIEST MODULE (imports most of repo)
       │
       ├──────────────────────────┬──────────────────────────┐
       ▼                          ▼                          ▼
  Causal/Event              Gauge/FiniteGroup          Quantum/AmplitudeAlg
  Causal/CausalDiamond      Gauge/ZMod                 Quantum/Superposition
  Causal/NoCTC              Gauge/Q8                   Quantum/QuantumBridge
  Causal/LightCone          Gauge/Connection           Quantum/StarQuantumBridge
                            Gauge/Holonomy
                            Gauge/ConjugacyClass
                            Gauge/RepCapacity
```

---

## Hand-Written vs Auto-Generated Modules

| Category | Count | Pattern | Modifiable by hand? |
|----------|-------|---------|---------------------|
| **Utility** | 3 | `Util/*.agda` | Yes |
| **Common specs (small)** | 3 | `TreeSpec`, `StarSpec`, `ObsPackage` | Yes |
| **Common specs (large)** | ~10 | `FilledSpec`, `Dense*Spec`, `Layer54d*Spec` | **No** — regenerate via Python |
| **Boundary/Bulk lookups** | ~30 | `*Cut.agda`, `*Chain.agda` | **No** — auto-generated |
| **Boundary proofs** | ~5 | `*Subadditivity`, `*AreaLaw`, `*HalfBound` | **No** — auto-generated, `abstract` |
| **Bulk curvature** | ~8 | `*Curvature.agda`, `*GaussBonnet.agda` | Mixed (dS hand-written, Dense auto-gen) |
| **Bridge (per-instance)** | ~12 | `*Obs.agda`, `*Equiv.agda` | Mixed (Star hand-written, others auto-gen) |
| **Bridge (generic)** | 6 | `GenericBridge`, `GenericValidation`, `SchematicTower`, `BridgeWitness`, `HalfBound`, `WickRotation` | Yes |
| **Bridge (dynamics)** | 3 | `StarStepInvariance`, `StarDynamicsLoop`, `EnrichedStarStepInvariance` | Yes |
| **Bridge (thermo)** | 2 | `CoarseGrain`, `Dense100Thermodynamics` | Yes |
| **Causal** | 4 | `Event`, `CausalDiamond`, `NoCTC`, `LightCone` | Yes |
| **Gauge** | 7 | `FiniteGroup` through `RepCapacity` | Yes |
| **Quantum** | 4 | `AmplitudeAlg` through `StarQuantumBridge` | Yes |

**Rule:** Modules marked `(AUTO-GEN)` in the repo tree are produced by the Python oracle scripts in `sim/prototyping/`. They should **never** be edited by hand. To modify their content, update the corresponding Python generator and re-run it.

---

## The `abstract` Barrier Modules

Several auto-generated modules use Agda's `abstract` keyword to seal large case analyses:

| Module | Cases | Purpose |
|--------|-------|---------|
| `Boundary/FilledSubadditivity.agda` | 360 | S(A∪B) ≤ S(A) + S(B) on 11-tile patch |
| `Boundary/Dense100AreaLaw.agda` | 717 | S ≤ area for Dense-100 |
| `Boundary/Dense200AreaLaw.agda` | 1246 | S ≤ area for Dense-200 |
| `Boundary/Dense100HalfBound.agda` | 717 | 2·S ≤ area for Dense-100 |
| `Boundary/Dense200HalfBound.agda` | 1246 | 2·S ≤ area for Dense-200 |

The `abstract` barrier prevents downstream modules from re-normalizing these proofs when they use the sealed lemma. Since all sealed proofs target propositional types (`_≤ℚ_` is propositional by `isProp≤ℚ`), the barrier does not damage any Univalence bridge or transport computation. See [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) for details and [Agda Issue #4573](https://github.com/agda/agda/issues/4573) for the underlying compiler behavior.

---

## The Three-Layer Gauge Architecture

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

## The Oracle Pipeline

The Python oracle scripts in `sim/prototyping/` serve as the **search engine**; Agda is the **checker**. The pipeline for each new patch instance is:

```
sim/prototyping/XX_generate_*.py    (Python oracle)
      │
      ├──▶ Common/*Spec.agda        (region type + orbit classification)
      ├──▶ Boundary/*Cut.agda       (S-cut via orbit reps)
      ├──▶ Bulk/*Chain.agda         (L-min via orbit reps)
      ├──▶ Bridge/*Obs.agda         (pointwise refl + funExt)
      ├──▶ Boundary/*AreaLaw.agda   (abstract: S ≤ area)     [optional]
      └──▶ Boundary/*HalfBound.agda (abstract: 2·S ≤ area)   [optional]
                │
                ▼
      Bridge/GenericBridge.agda     (orbit-bridge-witness → BridgeWitness)
                │
                ▼
      Bridge/SchematicTower.agda    (tower level registration)
```

This is the same division of labor used by the Four Color Theorem proof (Coq) and the Kepler Conjecture proof (HOL Light): external computation finds proofs, a simple kernel checks them.

---

## Transitive Closure Entry Points

To type-check the entire repository, load the heaviest downstream modules — their transitive closures cover the full source tree:

| Entry point | Covers |
|-------------|--------|
| `Bridge/SchematicTower.agda` | Almost everything (all patches, towers, area laws, half-bounds) |
| `Causal/LightCone.agda` | Full causal layer (Event, CausalDiamond, NoCTC) |
| `Quantum/StarQuantumBridge.agda` | Full quantum layer (AmplitudeAlg, Superposition, QuantumBridge) |
| `Gauge/RepCapacity.agda` | Full gauge layer (FiniteGroup through GaugedPatchWitness) |
| `Bridge/EnrichedStarStepInvariance.agda` | Dynamics layer (parameterized step invariance) |
| `Bridge/Dense100Thermodynamics.agda` | Thermodynamics (CoarseGrainedRT + HalfBound integration) |

For individual theorem verification, see the quick-check commands in [`building.md`](building.md).

---

## Design Principles

1. **Geometry stays in Python; proof stays in Agda.** The Python oracle handles all combinatorial case enumeration (Coxeter reflections, BFS growth, max-flow computation, orbit classification). Agda checks the emitted `(k, refl)` witnesses individually.

2. **The bridge is proven once.** `GenericEnriched` is a ~30-line parameterized module. Every bridge instance in the repository is a specialization — no per-instance proof engineering.

3. **Enrichment layers are additive and orthogonal.** Causal, Gauge, and Quantum modules enrich the network without modifying existing Bridge, Boundary, or Bulk modules. They compose independently.

4. **Scalar constants are defined once.** All ℕ constants (`1q`, `2q`) and ℤ constants (`neg1/5`, `pos1/10`, `one₁₀`) are defined in `Util/Scalars.agda` and `Util/Rationals.agda` respectively. Both sides of every `refl`-based proof import from the same source, guaranteeing identical normal forms.

5. **`abstract` seals propositions, not computations.** The `abstract` barrier is applied only to proof terms targeting propositional types (`_≤ℚ_`), never to observable functions or the `obs-path` that carries the RT correspondence. The Univalence bridge and transport retain full computational content.