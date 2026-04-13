## TASK

[...]

---

## METADATA / CONTEXT

- **Compiler:** Agda 2.8.0
- **Library:** agda/cubical (April 2026 version)
- **Primary Domain:** Univalent Foundations / Synthetic Homotopy Theory

---

## REPOSITORY CONTEXT

*Note: In this document, file contents are enclosed in four tildes (e.g., `~~~~agda` or `~~~~md`) to prevent markdown block collision.*

### Current Repo Structure

```
/univalence-gravity/
├── LICENSE
│
├── docs/
│   ├── README.md
│   ├── CITATION.cff
│   │
│   ├── getting-started/
│   │   ├── abstract.md                    # One-page summary of what is proven (v0.4+)
│   │   ├── setup.md                       # Dev environment (Agda 2.8, cubical, Nix)
│   │   ├── building.md                    # How to type-check; module load order
│   │   └── architecture.md                # Module dependency DAG, layer diagram
│   │
│   ├── formal/                            # Mathematical content (the "paper")
│   │   ├── 01-theorems.md                 # ★ Canonical theorem registry (ALL results)
│   │   ├── 02-foundations.md              # HoTT, Univalence, Cubical Agda background
│   │   ├── 03-holographic-bridge.md       # RT: S=L, enriched equiv, ua, GenericBridge
│   │   ├── 04-discrete-geometry.md        # Gauss–Bonnet, curvature, patch complexes
│   │   ├── 05-gauge-theory.md             # FiniteGroup, Q₈, connections, holonomy
│   │   ├── 06-causal-structure.md         # Events, causal diamonds, NoCTC, light cones
│   │   ├── 07-quantum-superposition.md    # AmplitudeAlg, Superposition, quantum bridge
│   │   ├── 08-wick-rotation.md            # dS/AdS, curvature-agnostic bridge
│   │   ├── 09-thermodynamics.md           # CoarseGrain, area law, resolution tower
│   │   ├── 10-dynamics.md                 # Step invariance, parameterized bridge, loop
│   │   ├── 11-generic-bridge.md           # PatchData, OrbitReducedPatch, SchematicTower
│   │   └── 12-bekenstein-hawking.md       # ★ HalfBound, from-two-cuts, 1/(4G) = 1/2
│   │
│   ├── physics/                           # Theoretical physics interpretation
│   │   ├── translation-problem.md         # From HaPPY code to our universe (§15 core)
│   │   ├── holographic-dictionary.md      # Agda type ↔ physics counterpart table
│   │   ├── discrete-bekenstein-hawking.md # The sharp 1/2 bound and its significance
│   │   ├── three-hypotheses.md            # Thermodynamic illusion / phase transition / discreteness
│   │   └── five-walls.md                  # Hard boundaries (now four: reals wall bypassed)
│   │
│   ├── engineering/                       # Proof engineering & CS contributions
│   │   ├── oracle-pipeline.md             # Python-to-Agda code generation (scripts 01–17)
│   │   ├── orbit-reduction.md             # Orbit reduction strategy (717→8, scaling)
│   │   ├── abstract-barrier.md            # The `abstract` keyword, Agda RAM, Issue #4573
│   │   ├── generic-bridge-pattern.md      # PatchData → BridgeWitness (one proof, N instances)
│   │   ├── scaling-report.md              # Region counts, orbit counts, parse/check times
│   │   ├── backend-spec-haskell.md        # Relevant specs for the backend
│   │   └── frontend-spec-webgl.md         # Relevant specs for the frontend
│   │
│   ├── instances/                         # Per-patch data sheets
│   │   ├── tree-pilot.md                  # 7-vertex weighted binary tree
│   │   ├── star-patch.md                  # 6-tile {5,4} star (primary bridge target)
│   │   ├── filled-patch.md                # 11-tile {5,4} disk (Thm 1 + Thm 3)
│   │   ├── honeycomb-3d.md                # {4,3,5} BFS star (32 cells, first 3D instance)
│   │   ├── dense-50.md                    # Dense-50 (139 regions, min-cut 1–7)
│   │   ├── dense-100.md                   # Dense-100 (717→8 orbits, min-cut 1–8, half-bound)
│   │   ├── dense-200.md                   # Dense-200 (1246→9 orbits, min-cut 1–9, half-bound)
│   │   ├── layer-54-tower.md              # {5,4} BFS depths 2–7, tower structure
│   │   └── desitter-patch.md              # {5,3} dodecahedron star (positive curvature)
│   │
│   ├── reference/
│   │   ├── bibliography.md                # All citations
│   │   ├── assumptions.md                 # Frozen model assumptions (carried over)
│   │   ├── glossary.md                    # Key terms
│   │   └── module-index.md                # Every src/ module: one-line desc + doc link
│   │
│   ├── papers/
│   │   ├── theory.tex
│   │   └── figures/
│   │
│   └── historical/
│       └── development-docs/
│           ├── README.md
│           ├── 00-abstract.md
│           ├── 01-introduction.md
│           ├── 02-foundations.md
│           ├── 03-architecture.md
│           ├── 04-tooling.md
│           ├── 05-roadmap.md
│           ├── 06-challenges.md
│           ├── 07-references.md
│           ├── 08-tree-instance.md
│           ├── 09-happy-instance.md
│           ├── 10-frontier.md
│           ├── assumptions.md
│           ├── CITATION.cff
│           ├── dev-setup.md
│           └── refactoring.md
│
├── src/
│   ├── Util/
│   │   ├── Scalars.agda
│   │   ├── Rationals.agda
│   │   └── NatLemmas.agda
│   │
│   ├── Common/
│   │   ├── ObsPackage.agda
│   │   ├── TreeSpec.agda
│   │   ├── StarSpec.agda
│   │   ├── FilledSpec.agda            (AUTO-GEN PY FILE)
│   │   ├── Honeycomb3DSpec.agda       (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Spec.agda      (AUTO-GEN PY FILE)
│   │   ├── Dense50Spec.agda           (AUTO-GEN PY FILE)
│   │   ├── Dense100Spec.agda          (AUTO-GEN PY FILE)
│   │   ├── Dense200Spec.agda          (AUTO-GEN PY FILE)
│   │   ├── Layer54d2Spec.agda         (AUTO-GEN PY FILE)
│   │   ├── ...
│   │   └── Layer54d7Spec.agda         (AUTO-GEN PY FILE)
│   │
│   ├── Boundary/
│   │   ├── TreeCut.agda
│   │   ├── StarSubadditivity.agda
│   │   ├── StarCut.agda
│   │   ├── FilledCut.agda             (AUTO-GEN PY FILE)
│   │   ├── FilledSubadditivity.agda   (AUTO-GEN PY FILE)
│   │   ├── Honeycomb3DCut.agda        (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Cut.agda       (AUTO-GEN PY FILE)
│   │   ├── Dense50Cut.agda            (AUTO-GEN PY FILE)
│   │   ├── Dense100Cut.agda           (AUTO-GEN PY FILE)
│   │   ├── Dense100AreaLaw.agda
│   │   ├── Dense200Cut.agda           (AUTO-GEN PY FILE)
│   │   ├── Dense200AreaLaw.agda       (AUTO-GEN PY FILE)
│   │   ├── StarCutParam.agda
│   │   ├── Layer54d2Cut.agda          (AUTO-GEN PY FILE)
│   │   ├── ...
│   │   ├── Layer54d7Cut.agda          (AUTO-GEN PY FILE)
│   │   ├── Dense100HalfBound.agda     (AUTO-GEN PY FILE)
│   │   └── Dense200HalfBound.agda     (AUTO-GEN PY FILE)
│   │
│   ├── Bulk/
│   │   ├── TreeChain.agda
│   │   ├── StarChain.agda
│   │   ├── PatchComplex.agda
│   │   ├── Curvature.agda
│   │   ├── GaussBonnet.agda
│   │   ├── StarMonotonicity.agda
│   │   ├── FilledChain.agda           (AUTO-GEN PY FILE)
│   │   ├── Honeycomb3DChain.agda      (AUTO-GEN PY FILE)
│   │   ├── Honeycomb3DCurvature.agda  (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Chain.agda     (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Curvature.agda (AUTO-GEN PY FILE)
│   │   ├── Dense50Chain.agda          (AUTO-GEN PY FILE)
│   │   ├── Dense50Curvature.agda      (AUTO-GEN PY FILE)
│   │   ├── Dense100Chain.agda         (AUTO-GEN PY FILE)
│   │   ├── Dense100Curvature.agda     (AUTO-GEN PY FILE)
│   │   ├── DeSitterPatchComplex.agda
│   │   ├── DeSitterCurvature.agda
│   │   ├── DeSitterGaussBonnet.agda
│   │   ├── Dense200Chain.agda
│   │   ├── Dense200Curvature.agda
│   │   ├── StarChainParam.agda
│   │   ├── Layer54d2Chain.agda        (AUTO-GEN PY FILE)
│   │   ├── ...
│   │   └── Layer54d7Chain.agda        (AUTO-GEN PY FILE)
│   │
│   ├── Bridge/
│   │   ├── TreeObs.agda
│   │   ├── TreeEquiv.agda             (DEAD CODE)
│   │   ├── StarObs.agda
│   │   ├── StarEquiv.agda
│   │   ├── EnrichedStarObs.agda
│   │   ├── FullEnrichedStarObs.agda
│   │   ├── EnrichedStarEquiv.agda
│   │   ├── FilledObs.agda             (AUTO-GEN PY FILE)
│   │   ├── FilledEquiv.agda
│   │   ├── StarRawEquiv.agda          (DEAD CODE)
│   │   ├── Honeycomb3DObs.agda        (AUTO-GEN PY FILE)
│   │   ├── Honeycomb3DEquiv.agda
│   │   ├── Honeycomb145Obs.agda      (AUTO-GEN PY FILE)
│   │   ├── Dense50Obs.agda            (AUTO-GEN PY FILE)
│   │   ├── Dense50Equiv.agda          (DEAD CODE)
│   │   ├── Dense100Obs.agda           (AUTO-GEN PY FILE)
│   │   ├── Dense100Equiv.agda         (DEAD CODE)
│   │   ├── WickRotation.agda
│   │   ├── CoarseGrain.agda
│   │   ├── Dense100Thermodynamics.agda
│   │   ├── ResolutionTower.agda      (DEAD CODE)
│   │   ├── Dense200Obs.agda
│   │   ├── StarStepInvariance.agda
│   │   ├── StarDynamicsLoop.agda
│   │   ├── EnrichedStarStepInvariance.agda
│   │   ├── GenericBridge.agda
│   │   ├── GenericValidation.agda
│   │   ├── SchematicTower.agda
│   │   ├── Layer54d2Obs.agda         (AUTO-GEN PY FILE)
│   │   ├── ...
│   │   ├── Layer54d7Obs.agda         (AUTO-GEN PY FILE)
│   │   ├── BridgeWitness.agda
│   │   └── HalfBound.agda
│   │
│   ├── Causal/
│   │   ├── Event.agda
│   │   ├── CausalDiamond.agda
│   │   ├── NoCTC.agda
│   │   └── LightCone.agda
│   │
│   ├── Gauge/
│   │   ├── FiniteGroup.agda
│   │   ├── ZMod.agda
│   │   ├── Q8.agda
│   │   ├── Connection.agda
│   │   ├── Holonomy.agda
│   │   ├── ConjugacyClass.agda
│   │   └── RepCapacity.agda
│   │
│   └── Quantum
│       ├── AmplitudeAlg.agda
│       ├── Superposition.agda
│       ├── QuantumBridge.agda
│       └── StarQuantumBridge.agda
│
├── sim/
│   └── prototyping/
│       ├── requirements.txt
│       ├── shell.nix
│       ├── 01_happy_patch_cuts.py
│       ├── 01_happy_patch_cuts_OUTPUT.txt
│       ├── 02_happy_patch_curvature.py
│       ├── 02_happy_patch_curvature_OUTPUT.txt
│       ├── 03_generate_filled_patch.py
│       ├── 03_generate_filled_patch_OUTPUT.txt
│       ├── 04_generate_raw_equiv.py
│       ├── 04_generate_raw_equiv_OUTPUT.txt
│       ├── 05_honeycomb_3d_prototype.py
│       ├── 05_honeycomb_3d_prototype_OUTPUT.txt
│       ├── 06_generate_honeycomb_3d.py
│       ├── 06_generate_honeycomb_3d_OUTPUT.txt
│       ├── 07_honeycomb_3d_multiStrategy.py
│       ├── 07_honeycomb_3d_multiStrategy_OUTPUT.txt
│       ├── 08_generate_dense50.py
│       ├── 08_generate_dense50_OUTPUT.txt
│       ├── 09_generate_dense100.py
│       ├── 09_generate_dense100_OUTPUT.txt
│       ├── 10_desitter_prototype.py
│       ├── 10_desitter_prototype_OUTPUT.txt
│       ├── 11_generate_area_law.py
│       ├── 12_generate_dense200.py
│       ├── 12_generate_dense200_OUTPUT.txt
│       ├── 13_generate_layerN.py
│       ├── 13_generate_layerN_OUTPUT.txt
│       ├── 14_entropic_convergence.py
│       ├── 14_entropic_convergence_OUTPUT.txt
│       ├── 14b_entropic_convergence_controlled.py
│       ├── 14b_entropic_convergence_controlled_OUTPUT.txt
│       ├── 14c_entropic_convergence_sup_half.py
│       ├── 14c_entropic_convergence_sup_half_OUTPUT.py
│       ├── 15_discrete_bekenstein_hawking.py
│       ├── 15_discrete_bekenstein_hawking_OUTPUT.txt
│       ├── 16_half_bound_scaling.py
│       ├── 16_half_bound_scaling_OUTPUT.txt
│       ├── 17_generate_half_bound.py
│       ├── 17_generate_half_bound_OUTPUT.txt
│       ├── 18_export_json.py
│       └── 18_export_json_OUTPUT.txt
│
├── data/
│   ├── curvature.json
│   ├── meta.json
│   ├── theorems.json
│   ├── tower.json
│   │
│   └── patches/
│       ├── tree.json
│       ├── star.json
│       ├── filled.json
│       ├── desitter.json
│       ├── dense-50.json
│       ├── dense-100.json
│       ├── dense-200.json
│       ├── honeycomb-3d.json
│       ├── layer-54-d2.json
│       ├── layer-54-d3.json
│       ├── layer-54-d4.json
│       ├── layer-54-d5.json
│       ├── layer-54-d6.json
│       └── layer-54-d7.json
│
└── backend/
    ├── README.md
    ├── backend.cabal
    ├── cabal.project
    ├── cabal.project.freeze
    │
    ├── app/
    │   └── Main.hs             -- entry point, CLI parsing, server start
    │
    ├── src/
    │   ├── Api.hs              -- Servant API type definition
    │   ├── Server.hs           -- handler implementations + CORS middleware
    │   ├── Types.hs            -- domain model (§3) + Meta, Health, CurvatureSummary
    │   ├── DataLoader.hs       -- JSON parsing from data/ directory
    │   └── Invariants.hs       -- startup validation checks
    │
    ├── test/
    │   ├── Spec.hs             -- test entry point (hspec-discover)
    │   ├── InvariantSpec.hs    -- property-based tests (§6)
    │   └── ApiSpec.hs          -- Servant client tests
    │
    └── data/                   -- symlink to repo-root data/
```

---

### Root

* **`LICENSE`:**
* Content in this document not shown due to length.

### Documentation

* **`docs/README.md`:**
~~~~md
[IMPORT] wsl:docs/README.md
~~~~

* **`docs/CITATION.cff`:**
* Content in this document not shown due to length.

* **`docs/development-docs/refactoring.md`:**
* Outsourced

* **`docs/historical/development-docs/assumptions.md`:**
* Outsourced

* **`docs/historical/development-docs/dev-setup.md`:**
* Outsourced

* **`docs/historical/development-docs/00-abstract.md`:**
* Outsourced

* **`docs/historical/development-docs/01-introduction.md`:**
* Outsourced

* **`docs/historical/development-docs/02-foundations.md`:**
* Outsourced

* **`docs/historical/development-docs/03-architecture.md`:**
* Outsourced

* **`docs/historical/development-docs/04-tooling.md`:**
* Outsourced

* **`docs/historical/development-docs/05-roadmap.md`:**
* Outsourced

* **`docs/historical/development-docs/06-challenges.md`:**
* Outsourced

* **`docs/historical/development-docs/07-references.md`:**
* Outsourced

* **`docs/historical/development-docs/08-tree-instance.md`:**
* Outsourced

* **`docs/historical/development-docs/09-happy-instance.md`:**
* Outsourced

* **`docs/historical/development-docs/10-frontier.md`:**
* Outsourced

---

#### Getting Started

* **`docs/getting-started/abstract.md`:**
~~~~md
[IMPORT] wsl:docs/getting-started/abstract.md
~~~~

* **`docs/getting-started/setup.md`:**
* Content in this document not shown due to length.

* **`docs/getting-started/building.md`:**
* Content in this document not shown due to length.

* **`docs/getting-started/architecture.md`:**
~~~~md
[IMPORT] wsl:docs/getting-started/architecture.md
~~~~

---

#### Formal

* **`docs/formal/01-theorems.md`:**
~~~~md
[IMPORT] wsl:docs/formal/01-theorems.md
~~~~

* **`docs/formal/02-foundations.md`:**
~~~~md
[IMPORT] wsl:docs/formal/02-foundations.md
~~~~

* **`docs/formal/03-holographic-bridge.md`:**
~~~~md
[IMPORT] wsl:docs/formal/03-holographic-bridge.md
~~~~

* **`docs/formal/04-discrete-geometry.md`:**
~~~~md
[IMPORT] wsl:docs/formal/04-discrete-geometry.md
~~~~

* **`docs/formal/05-gauge-theory.md`:**
~~~~md
[IMPORT] wsl:docs/formal/05-gauge-theory.md
~~~~

* **`docs/formal/06-causal-structure.md`:**
~~~~md
[IMPORT] wsl:docs/formal/06-causal-structure.md
~~~~

* **`docs/formal/07-quantum-superposition.md`:**
~~~~md
[IMPORT] wsl:docs/formal/07-quantum-superposition.md
~~~~

* **`docs/formal/08-wick-rotation.md`:**
~~~~md
[IMPORT] wsl:docs/formal/08-wick-rotation.md
~~~~

* **`docs/formal/09-thermodynamics.md`:**
~~~~md
[IMPORT] wsl:docs/formal/09-thermodynamics.md
~~~~

* **`docs/formal/10-dynamics.md`:**
~~~~md
[IMPORT] wsl:docs/formal/10-dynamics.md
~~~~

* **`docs/formal/11-generic-bridge.md`:**
~~~~md
[IMPORT] wsl:docs/formal/11-generic-bridge.md
~~~~

* **`docs/formal/12-bekenstein-hawking.md`:**
~~~~md
[IMPORT] wsl:docs/formal/12-bekenstein-hawking.md
~~~~

---

#### Physics

* **`docs/physics/translation-problem.md`:**
* Content in this document not shown due to length.

* **`docs/physics/holographic-dictionary.md`:**
* Content in this document not shown due to length.

* **`docs/physics/discrete-bekenstein-hawking.md`:**
* Content in this document not shown due to length.

* **`docs/physics/three-hypotheses.md`:**
* Content in this document not shown due to length.

* **`docs/physics/five-walls.md`:**
* Content in this document not shown due to length.

---

#### Engineering

* **`docs/engineering/oracle-pipeline.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/oracle-pipeline.md
~~~~

* **`docs/engineering/orbit-reduction.md`:**
Content in this document not shown due to length.

* **`docs/engineering/abstract-barrier.md`:**
Content in this document not shown due to length.

* **`docs/engineering/generic-bridge-pattern.md`:**
Content in this document not shown due to length.

* **`docs/engineering/scaling-report.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/scaling-report.md
~~~~

* **`docs/engineering/backend-spec-haskell.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/backend-spec-haskell.md
~~~~

* **`docs/engineering/frontend-spec-webgl.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/frontend-spec-webgl.md
~~~~

---

#### Instances

* **`docs/instances/tree-pilot.md`:**
~~~~md
[IMPORT] wsl:docs/instances/tree-pilot.md
~~~~

* **`docs/instances/star-patch.md`:**
~~~~md
[IMPORT] wsl:docs/instances/star-patch.md
~~~~

* **`docs/instances/filled-patch.md`:**
~~~~md
[IMPORT] wsl:docs/instances/filled-patch.md
~~~~

* **`docs/instances/honeycomb-3d.md`:**
~~~~md
[IMPORT] wsl:docs/instances/honeycomb-3d.md
~~~~

* **`docs/instances/dense-50.md`:**
~~~~md
[IMPORT] wsl:docs/instances/dense-50.md
~~~~

* **`docs/instances/dense-100.md`:**
~~~~md
[IMPORT] wsl:docs/instances/dense-100.md
~~~~

* **`docs/instances/dense-200.md`:**
~~~~md
[IMPORT] wsl:docs/instances/dense-200.md
~~~~

* **`docs/instances/layer-54-tower.md`:**
~~~~md
[IMPORT] wsl:docs/instances/layer-54-tower.md
~~~~

* **`docs/instances/desitter-patch.md`:**
~~~~md
[IMPORT] wsl:docs/instances/desitter-patch.md
~~~~

---

#### Reference

* **`docs/reference/bibliography.md`:**
* Content in this document not shown due to length.

* **`docs/reference/assumptions.md`:**
* Content in this document not shown due to length.

* **`docs/reference/glossary.md`:**
Content in this document not shown due to length.

* **`docs/reference/module-index.md`:**
* Content in this document not shown due to length.

---

#### Papers

* **`docs/papers/theory.tex`:**
~~~~tex
[IMPORT] wsl:docs/papers/theory.tex
~~~~

### Source Code

#### Util

* **`Util/Scalars.agda`:**
Content in this document not shown due to length.

* **`Util/Rationals.agda`:**
Content in this document not shown due to length.

* **`Util/NatLemmas.agda`:**
Content in this document not shown due to length.

---

#### Common

* **`Common/ObsPackage.agda`:**
Content in this document not shown due to length.

* **`Common/TreeSpec.agda`:**
Content in this document not shown due to length.

* **`Common/StarSpec.agda`:**
Content in this document not shown due to length.

* **`Common/FilledSpec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`.
Content in this document not shown due to length.

* **`Common/Honeycomb3DSpec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Common/Honeycomb145Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
Content in this document not shown due to length.

* **`Common/Dense50Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
Content in this document not shown due to length.

* **`Common/Dense100Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
Content in this document not shown due to length.

* **`Common/Dense200Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Common/Layer54d2Spec.agda` ... `Common/Layer54d7Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

---

#### Boundary

* **`Boundary/TreeCut.agda`:**
Content in this document not shown due to length.

* **`Boundary/StarSubadditivity.agda`:**
Content in this document not shown due to length.

* **`Boundary/StarCut.agda`:**
Content in this document not shown due to length.

* **`Boundary/FilledCut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Boundary/FilledSubadditivity.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Boundary/Honeycomb3DCut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Boundary/Honeycomb145Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
Content in this document not shown due to length.

* **`Boundary/Dense50Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
Content in this document not shown due to length.

* **`Boundary/Dense100Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
Content in this document not shown due to length.

* **`Boundary/Dense100AreaLaw.agda`:**
AUTO-GENERATED PYTHON FILE FROM `11_generate_area_law.py`.
Content in this document not shown due to length.

* **`Boundary/Dense200Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Boundary/Dense200AreaLaw.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Boundary/StarCutParam.agda`:**
Content in this document not shown due to length.

* **`Boundary/Layer54d2Cut.agda` ... `Layer54d7Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

* **`Boundary/Dense100HalfBound.agda`:**
AUTO-GENERATED PYTHON FILE FROM `17_generate_half_bound.py.py`.
Content in this document not shown due to length.

* **`Boundary/Dense200HalfBound.agda`:**
AUTO-GENERATED PYTHON FILE FROM `17_generate_half_bound.py.py`.
Content in this document not shown due to length.

---

#### Bulk

* **`Bulk/TreeChain.agda`:**
Content in this document not shown due to length.

* **`Bulk/StarChain.agda`:**
Content in this document not shown due to length.

* **`Bulk/PatchComplex.agda`:**
Content in this document not shown due to length.

* **`Bulk/Curvature.agda`:**
Content in this document not shown due to length.

* **`Bulk/GaussBonnet.agda`:**
Content in this document not shown due to length.

* **`Bulk/StarMonotonicity.agda`:**
Content in this document not shown due to length.

* **`Bulk/FilledChain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Bulk/Honeycomb3DChain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Bulk/Honeycomb3DCurvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Bulk/Honeycomb145Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
Content in this document not shown due to length.

* **`Bulk/Honeycomb145Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
Content in this document not shown due to length.

* **`Bulk/Dense50Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
Content in this document not shown due to length.

* **`Bulk/Dense50Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
Content in this document not shown due to length.

* **`Bulk/Dense100Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
Content in this document not shown due to length.

* **`Bulk/Dense100Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
Content in this document not shown due to length.

* **`Bulk/DeSitterPatchComplex.agda`:**
Content in this document not shown due to length.

* **`Bulk/DeSitterCurvature.agda`:**
Content in this document not shown due to length.

* **`Bulk/DeSitterGaussBonnet.agda`:**
Content in this document not shown due to length.

* **`Bulk/Dense200Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Bulk/Dense200Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Bulk/StarChainParam.agda`:**
Content in this document not shown due to length.

* **`Bulk/Layer54d2Chain.agda` ... `Layer54d7Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

---

#### Bridge

* **`Bridge/TreeObs.agda`:**
Content in this document not shown due to length.

* **`Bridge/TreeEquiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/StarObs.agda`:**
Content in this document not shown due to length.

* **`Bridge/StarEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
Content in this document not shown due to length.

* **`Bridge/EnrichedStarObs.agda`:**
Content in this document not shown due to length.

* **`Bridge/FullEnrichedStarObs.agda`:**
Content in this document not shown due to length.

* **`Bridge/EnrichedStarEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
Content in this document not shown due to length.

* **`Bridge/FilledObs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Bridge/FilledEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
Content in this document not shown due to length.

* **`Bridge/StarRawEquiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/FilledRawEquiv.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Bridge/Honeycomb3DObs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Bridge/Honeycomb3DEquiv.agda`:**
Content in this document not shown due to length.

* **`Bridge/Honeycomb145Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
Content in this document not shown due to length.

* **`Bridge/Dense50Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
Content in this document not shown due to length.

* **`Bridge/Dense50Equiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/Dense100Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
Content in this document not shown due to length.

* **`Bridge/Dense100Equiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/WickRotation.agda`:**
Content in this document not shown due to length.

* **`Bridge/CoarseGrain.agda`:**
Content in this document not shown due to length.

* **`Bridge/Dense100Thermodynamics.agda`:**
Content in this document not shown due to length.

* **`Bridge/ResolutionTower.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/Dense200Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
* Content in this document not shown due to length.

* **`Bridge/StarStepInvariance.agda`:**
Content in this document not shown due to length.

* **`Bridge/StarDynamicsLoop.agda`:**
Content in this document not shown due to length.

* **`Bridge/EnrichedStarStepInvariance.agda`:**
Content in this document not shown due to length.

* **`Bridge/GenericBridge.agda`:**
Content in this document not shown due to length.

* **`Bridge/GenericValidation.agda`:**
Content in this document not shown due to length.

* **`Bridge/SchematicTower.agda`:**
Content in this document not shown due to length.

* **`Bulk/Layer54d2Obs.agda` ... `Layer54d7Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

* **`Bridge/BridgeWitness.agda`:**
Content in this document not shown due to length.

* **`Bridge/HalfBound.agda`:**
Content in this document not shown due to length.

---

#### Causal

* **`Causal/Event.agda`:**
Content in this document not shown due to length.

* **`Causal/CausalDiamond.agda`:**
Content in this document not shown due to length.

* **`Causal/NoCTC.agda`:**
Content in this document not shown due to length.

* **`Causal/LightCone.agda`:**
Content in this document not shown due to length.

#### Gauge

* **`Gauge/FiniteGroup.agda`:**
Content in this document not shown due to length.

* **`Gauge/ZMod.agda`:**
Content in this document not shown due to length.

* **`Gauge/Q8.agda`:**
Content in this document not shown due to length.

* **`Gauge/Connection.agda`:**
Content in this document not shown due to length.

* **`Gauge/Holonomy.agda`:**
Content in this document not shown due to length.

* **`Gauge/ConjugacyClass.agda`:**
Content in this document not shown due to length.

* **`Gauge/RepCapacity.agda`:**
Content in this document not shown due to length.

---

#### Quantum

* **`Quantum/AmplitudeAlg.agda`:**
Content in this document not shown due to length.

* **`Quantum/Superposition.agda`:**
Content in this document not shown due to length.

* **`Quantum/QuantumBridge.agda`:**
Content in this document not shown due to length.

* **`Quantum/StarQuantumBridge.agda`:**
Content in this document not shown due to length.

---

### SIM

* **`prototyping/requirements.txt`:**
Content in this document not shown due to length.

* **`prototyping/shell.nix`:**
Content in this document not shown due to length.

* **`prototyping/01_happy_patch_cuts.py`:**
Content in this document not shown due to length.

* **`prototyping/01_happy_patch_cuts_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/02_happy_patch_curvature.py`:**
Content in this document not shown due to length.

* **`prototyping/02_happy_patch_curvature_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/03_generate_filled_patch.py`:**
Content in this document not shown due to length.

* **`prototyping/03_generate_filled_patch_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/04_generate_raw_equiv.py`:**
Content in this document not shown due to length.

* **`prototyping/04_generate_raw_equiv_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/05_honeycomb_3d_prototype.py`:**
Content in this document not shown due to length.

* **`prototyping/05_honeycomb_3d_prototype_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/06_generate_honeycomb_3d.py`:**
Content in this document not shown due to length.

* **`prototyping/06_generate_honeycomb_3d_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/06b_generate_honeycomb145.py`:**
Content in this document not shown due to length.

* **`prototyping/06b_generate_honeycomb145_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/07_honeycomb_3d_multiStrategy.py`:**
Content in this document not shown due to length.

* **`prototyping/07_honeycomb_3d_multiStrategy_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/08_generate_dense50.py`:**
Content in this document not shown due to length.

* **`prototyping/08_generate_dense50_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/09_generate_dense100.py`:**
Content in this document not shown due to length.

* **`prototyping/09_generate_dense100_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/10_desitter_prototype.py`:**
Content in this document not shown due to length.

* **`prototyping/10_desitter_prototype_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/11_generate_area_law.py`:**
Content in this document not shown due to length.

* **`prototyping/11_generate_area_law_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/12_generate_dense200.py`:**
Content in this document not shown due to length.

* **`prototyping/12_generate_dense200_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/13_generate_layerN.py`:**
Content in this document not shown due to length.

* **`prototyping/13_generate_layerN_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/14_entropic_convergence.py`:**
Content in this document not shown due to length.

* **`prototyping/14_entropic_convergence_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/14b_entropic_convergence_controlled.py`:**
Content in this document not shown due to length.

* **`prototyping/14b_entropic_convergence_controlled_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/14c_entropic_convergence_sup_half.py`:**
Content in this document not shown due to length.

* **`prototyping/14c_entropic_convergence_sup_half_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/15_discrete_bekenstein_hawking.py`:**
Content in this document not shown due to length.

* **`prototyping/15_discrete_bekenstein_hawking_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/16_half_bound_scaling.py`:**
Content in this document not shown due to length.

* **`prototyping/16_half_bound_scaling_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/17_generate_half_bound.py`:**
Content in this document not shown due to length.

* **`prototyping/17_generate_half_bound_OUTPUT.txt`:**
Content in this document not shown due to length.

* **`prototyping/18_export_json.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/18_export_json.py
~~~~

* **`prototyping/18_export_json_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/18_export_json_OUTPUT.txt
~~~~

---

### Backend

#### Root

* **`backend/README.md`:**
~~~~cabal
[IMPORT] wsl:backend/README.md
~~~~

* **`backend/backend.cabal`:**
~~~~cabal
[IMPORT] wsl:backend/backend.cabal
~~~~

* **`backend/cabal.project`:**
~~~~project
[IMPORT] wsl:backend/cabal.project
~~~~

* **`backend/cabal.project.freeze`:**
~~~~freeze
[IMPORT] wsl:backend/cabal.project.freeze
~~~~

---

#### App

* **`backend/app/Main.hs`:**
~~~~hs
[IMPORT] wsl:backend/app/Main.hs
~~~~

#### Source Code

* **`backend/src/Types.hs`:**
~~~~hs
[IMPORT] wsl:backend/src/Types.hs
~~~~

* **`backend/src/DataLoader.hs`:**
~~~~hs
[IMPORT] wsl:backend/src/DataLoader.hs
~~~~

* **`backend/src/Invariants.hs`:**
~~~~hs
[IMPORT] wsl:backend/src/Invariants.hs
~~~~

* **`backend/src/Api.hs`:**
~~~~hs
[IMPORT] wsl:backend/src/Api.hs
~~~~

* **`backend/src/Server.hs`:**
~~~~hs
[IMPORT] wsl:backend/src/Server.hs
~~~~

---

#### Tests

* **`backend/test/Spec.hs`:**
~~~~hs
[IMPORT] wsl:backend/test/Spec.hs
~~~~

* **`backend/test/InvariantSpec.hs`:**
~~~~hs
[IMPORT] wsl:backend/test/InvariantSpec.hs
~~~~

* **`backend/test/ApiSpec.hs`:**
~~~~hs
[IMPORT] wsl:backend/test/ApiSpec.hs
~~~~

---

#### Data (Symlink to `root` `data/`)

* **`backend/data/curvature.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/curvature.json
~~~~

* **`backend/data/meta.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/meta.json
~~~~

* **`backend/data/theorems.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/theorems.json
~~~~

* **`backend/data/tower.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/tower.json
~~~~

---

##### Patches

* **`backend/data/patches/tree.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/patches/tree.json
~~~~

* **`backend/data/patches/star.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/patches/star.json
~~~~

* **`backend/data/patches/desitter.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/patches/desitter.json
~~~~

* **`backend/data/patches/dense-50.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/patches/dense-50.json
~~~~

* **`backend/data/patches/layer-54-d2.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
[IMPORT] wsl:data/patches/layer-54-d2.json
~~~~

Not shows due to length: `layer-54-d[3-7].json`, `dense-[100; 200].json`, `filled.json`, `honeycomb-3d.json`. Please request if neccessary.