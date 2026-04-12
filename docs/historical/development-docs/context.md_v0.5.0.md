## TASK

[]

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
/home/zimablue/univalence-gravity/
│
├── docs/
│    ├── README.md
│    ├── CITATION.cff
│    │
│    ├── getting-started/
│    │   ├── abstract.md                    # One-page summary of what is proven (v0.4+)
│    │   ├── setup.md                       # Dev environment (Agda 2.8, cubical, Nix)
│    │   ├── building.md                    # How to type-check; module load order
│    │   └── architecture.md                # Module dependency DAG, layer diagram
│    │
│    ├── formal/                            # Mathematical content (the "paper")
│    │   ├── 01-theorems.md                 # ★ Canonical theorem registry (ALL results)
│    │   ├── 02-foundations.md              # HoTT, Univalence, Cubical Agda background
│    │   ├── 03-holographic-bridge.md       # RT: S=L, enriched equiv, ua, GenericBridge
│    │   ├── 04-discrete-geometry.md        # Gauss–Bonnet, curvature, patch complexes
│    │   ├── 05-gauge-theory.md             # FiniteGroup, Q₈, connections, holonomy
│    │   ├── 06-causal-structure.md         # Events, causal diamonds, NoCTC, light cones
│    │   ├── 07-quantum-superposition.md    # AmplitudeAlg, Superposition, quantum bridge
│    │   ├── 08-wick-rotation.md            # dS/AdS, curvature-agnostic bridge
│    │   ├── 09-thermodynamics.md           # CoarseGrain, area law, resolution tower
│    │   ├── 10-dynamics.md                 # Step invariance, parameterized bridge, loop
│    │   ├── 11-generic-bridge.md           # PatchData, OrbitReducedPatch, SchematicTower
│    │   └── 12-bekenstein-hawking.md       # ★ HalfBound, from-two-cuts, 1/(4G) = 1/2
│    │
│    ├── physics/                           # Theoretical physics interpretation
│    │   ├── translation-problem.md         # From HaPPY code to our universe (§15 core)
│    │   ├── holographic-dictionary.md      # Agda type ↔ physics counterpart table
│    │   ├── discrete-bekenstein-hawking.md # The sharp 1/2 bound and its significance
│    │   ├── three-hypotheses.md            # Thermodynamic illusion / phase transition / discreteness
│    │   └── five-walls.md                  # Hard boundaries (now four: reals wall bypassed)
│    │
│    ├── engineering/                       # Proof engineering & CS contributions
│    │   ├── oracle-pipeline.md             # Python-to-Agda code generation (scripts 01–17)
│    │   ├── orbit-reduction.md             # Orbit reduction strategy (717→8, scaling)
│    │   ├── abstract-barrier.md            # The `abstract` keyword, Agda RAM, Issue #4573
│    │   ├── generic-bridge-pattern.md      # PatchData → BridgeWitness (one proof, N instances)
│    │   └── scaling-report.md              # Region counts, orbit counts, parse/check times
│    │
│    ├── instances/                         # Per-patch data sheets
│    │   ├── tree-pilot.md                  # 7-vertex weighted binary tree
│    │   ├── star-patch.md                  # 6-tile {5,4} star (primary bridge target)
│    │   ├── filled-patch.md                # 11-tile {5,4} disk (Thm 1 + Thm 3)
│    │   ├── honeycomb-3d.md                # {4,3,5} BFS star (32 cells, first 3D instance)
│    │   ├── dense-50.md                    # Dense-50 (139 regions, min-cut 1–7)
│    │   ├── dense-100.md                   # Dense-100 (717→8 orbits, min-cut 1–8, half-bound)
│    │   ├── dense-200.md                   # Dense-200 (1246→9 orbits, min-cut 1–9, half-bound)
│    │   ├── layer-54-tower.md              # {5,4} BFS depths 2–7, tower structure
│    │   └── desitter-patch.md              # {5,3} dodecahedron star (positive curvature)
│    │
│    ├── reference/
│    │   ├── bibliography.md                # All citations
│    │   ├── assumptions.md                 # Frozen model assumptions (carried over)
│    │   ├── glossary.md                    # Key terms
│    │   └── module-index.md                # Every src/ module: one-line desc + doc link
│    │
│    ├── papers/
│    │    ├── theory.tex
│    │    └── figures/
│    │
│    └── historical/
│         └── development-docs/
│              ├── README.md
│              ├── 00-abstract.md
│              ├── 01-introduction.md
│              ├── 02-foundations.md
│              ├── 03-architecture.md
│              ├── 04-tooling.md
│              ├── 05-roadmap.md
│              ├── 06-challenges.md
│              ├── 07-references.md
│              ├── 08-tree-instance.md
│              ├── 09-happy-instance.md
│              ├── 10-frontier.md
│              ├── assumptions.md
│              ├── CITATION.cff
│              ├── dev-setup.md
│              └── refactoring.md
│
├── src/
│    ├── Util/
│    │    ├── Scalars.agda
│    │    ├── Rationals.agda
│    │    └── NatLemmas.agda
│    │
│    ├── Common/
│    │    ├── ObsPackage.agda
│    │    ├── TreeSpec.agda
│    │    ├── StarSpec.agda
│    │    ├── FilledSpec.agda           (AUTO-GEN PY FILE)
│    │    ├── Honeycomb3DSpec.agda      (AUTO-GEN PY FILE)
│    │    ├── Dense50Spec.agda          (AUTO-GEN PY FILE)
│    │    ├── Dense100Spec.agda         (AUTO-GEN PY FILE)
│    │    ├── Dense200Spec.agda         (AUTO-GEN PY FILE)
│    │    ├── Layer54d2Spec.agda        (AUTO-GEN PY FILE)
│    │    ├── ...
│    │    └── Layer54d7Spec.agda        (AUTO-GEN PY FILE)
│    │
│    ├── Boundary/
│    │    ├── TreeCut.agda
│    │    ├── StarSubadditivity.agda
│    │    ├── StarCut.agda
│    │    ├── FilledCut.agda            (AUTO-GEN PY FILE)
│    │    ├── FilledSubadditivity.agda  (AUTO-GEN PY FILE)
│    │    ├── Honeycomb3DCut.agda       (AUTO-GEN PY FILE)
│    │    ├── Dense50Cut.agda           (AUTO-GEN PY FILE)
│    │    ├── Dense100Cut.agda          (AUTO-GEN PY FILE)
│    │    ├── Dense100AreaLaw.agda
│    │    ├── Dense200Cut.agda          (AUTO-GEN PY FILE)
│    │    ├── Dense200AreaLaw.agda      (AUTO-GEN PY FILE)
│    │    ├── StarCutParam.agda
│    │    ├── Layer54d2Cut.agda         (AUTO-GEN PY FILE)
│    │    ├── ...
│    │    ├── Layer54d7Cut.agda         (AUTO-GEN PY FILE)
│    │    ├── Dense100HalfBound.agda    (AUTO-GEN PY FILE)
│    │    └── Dense200HalfBound.agda    (AUTO-GEN PY FILE)
│    │
│    ├── Bulk/
│    │    ├── TreeChain.agda
│    │    ├── StarChain.agda
│    │    ├── PatchComplex.agda
│    │    ├── Curvature.agda
│    │    ├── GaussBonnet.agda
│    │    ├── StarMonotonicity.agda
│    │    ├── FilledChain.agda          (AUTO-GEN PY FILE)
│    │    ├── Honeycomb3DChain.agda     (AUTO-GEN PY FILE)
│    │    ├── Honeycomb3DCurvature.agda (AUTO-GEN PY FILE)
│    │    ├── Dense50Chain.agda         (AUTO-GEN PY FILE)
│    │    ├── Dense50Curvature.agda     (AUTO-GEN PY FILE)
│    │    ├── Dense100Chain.agda        (AUTO-GEN PY FILE)
│    │    ├── Dense100Curvature.agda    (AUTO-GEN PY FILE)
│    │    ├── DeSitterPatchComplex.agda
│    │    ├── DeSitterCurvature.agda
│    │    ├── DeSitterGaussBonnet.agda
│    │    ├── Dense200Chain.agda
│    │    ├── Dense200Curvature.agda
│    │    ├── StarChainParam.agda
│    │    ├── Layer54d2Chain.agda       (AUTO-GEN PY FILE)
│    │    ├── ...
│    │    └── Layer54d7Chain.agda       (AUTO-GEN PY FILE)
│    │
│    ├── Bridge/
│    │    ├── TreeObs.agda
│    │    ├── TreeEquiv.agda            (DEAD CODE)
│    │    ├── StarObs.agda
│    │    ├── StarEquiv.agda
│    │    ├── EnrichedStarObs.agda
│    │    ├── FullEnrichedStarObs.agda
│    │    ├── EnrichedStarEquiv.agda
│    │    ├── FilledObs.agda            (AUTO-GEN PY FILE)
│    │    ├── FilledEquiv.agda
│    │    ├── StarRawEquiv.agda         (DEAD CODE)
│    │    ├── Honeycomb3DObs.agda       (AUTO-GEN PY FILE)
│    │    ├── Honeycomb3DEquiv.agda
│    │    ├── Dense50Obs.agda           (AUTO-GEN PY FILE)
│    │    ├── Dense50Equiv.agda         (DEAD CODE)
│    │    ├── Dense100Obs.agda          (AUTO-GEN PY FILE)
│    │    ├── Dense100Equiv.agda        (DEAD CODE)
│    │    ├── WickRotation.agda
│    │    ├── CoarseGrain.agda
│    │    ├── Dense100Thermodynamics.agda
│    │    ├── ResolutionTower.agda     (DEAD CODE)
│    │    ├── Dense200Obs.agda
│    │    ├── StarStepInvariance.agda
│    │    ├── StarDynamicsLoop.agda
│    │    ├── EnrichedStarStepInvariance.agda
│    │    ├── GenericBridge.agda
│    │    ├── GenericValidation.agda
│    │    ├── SchematicTower.agda
│    │    ├── Layer54d2Obs.agda        (AUTO-GEN PY FILE)
│    │    ├── ...
│    │    ├── Layer54d7Obs.agda        (AUTO-GEN PY FILE)
│    │    ├── BridgeWitness.agda
│    │    └── HalfBound.agda
│    │
│    ├── Causal/
│    │    ├── Event.agda
│    │    ├── CausalDiamond.agda
│    │    ├── NoCTC.agda
│    │    └── LightCone.agda
│    │
│    ├── Gauge/
│    │    ├── FiniteGroup.agda
│    │    ├── ZMod.agda
│    │    ├── Q8.agda
│    │    ├── Connection.agda
│    │    ├── Holonomy.agda
│    │    ├── ConjugacyClass.agda
│    │    └── RepCapacity.agda
│    │
│    └── Quantum
│         ├── AmplitudeAlg.agda
│         ├── Superposition.agda
│         ├── QuantumBridge.agda
│         └── StarQuantumBridge.agda
│
└── sim/
     └── prototyping/
          ├── requirements.txt
          ├── shell.nix
          ├── 01_happy_patch_cuts.py
          ├── 01_happy_patch_cuts_OUTPUT.txt
          ├── 02_happy_patch_curvature.py
          ├── 02_happy_patch_curvature_OUTPUT.txt
          ├── 03_generate_filled_patch.py
          ├── 03_generate_filled_patch_OUTPUT.txt
          ├── 04_generate_raw_equiv.py
          ├── 04_generate_raw_equiv_OUTPUT.txt
          ├── 05_honeycomb_3d_prototype.py
          ├── 05_honeycomb_3d_prototype_OUTPUT.txt
          ├── 06_generate_honeycomb_3d.py
          ├── 06_generate_honeycomb_3d_OUTPUT.txt
          ├── 07_honeycomb_3d_multiStrategy.py
          ├── 07_honeycomb_3d_multiStrategy_OUTPUT.txt
          ├── 08_generate_dense50.py
          ├── 08_generate_dense50_OUTPUT.txt
          ├── 09_generate_dense100.py
          ├── 09_generate_dense100_OUTPUT.txt
          ├── 10_desitter_prototype.py
          ├── 10_desitter_prototype_OUTPUT.txt
          ├── 11_generate_area_law.py
          ├── 12_generate_dense200.py
          ├── 12_generate_dense200_OUTPUT.txt
          ├── 13_generate_layerN.py
          ├── 13_generate_layerN_OUTPUT.txt
          ├── 14_entropic_convergence.py
          ├── 14_entropic_convergence_OUTPUT.txt
          ├── 14b_entropic_convergence_controlled.py
          ├── 14b_entropic_convergence_controlled_OUTPUT.txt
          ├── 14c_entropic_convergence_sup_half.py
          ├── 14c_entropic_convergence_sup_half_OUTPUT.py
          ├── 15_discrete_bekenstein_hawking.py
          ├── 15_discrete_bekenstein_hawking_OUTPUT.txt
          ├── 16_half_bound_scaling.py
          ├── 16_half_bound_scaling_OUTPUT.txt
          ├── 17_generate_half_bound.py
          └── 17_generate_half_bound_OUTPUT.txt
```

---

### Documentation

* **`docs/README.md`:**
~~~~md
[IMPORT] wsl:docs/README.md
~~~~

* **`docs/CITATION.cff`:**
~~~~md
[IMPORT] wsl:docs/CITATION.cff
~~~~

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
~~~~md
[IMPORT] wsl:docs/getting-started/setup.md
~~~~

* **`docs/getting-started/building.md`:**
~~~~md
[IMPORT] wsl:docs/getting-started/building.md
~~~~

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
~~~~md
[IMPORT] wsl:docs/physics/translation-problem.md
~~~~

* **`docs/physics/holographic-dictionary.md`:**
~~~~md
[IMPORT] wsl:docs/physics/holographic-dictionary.md
~~~~

* **`docs/physics/discrete-bekenstein-hawking.md`:**
~~~~md
[IMPORT] wsl:docs/physics/discrete-bekenstein-hawking.md
~~~~

* **`docs/physics/three-hypotheses.md`:**
~~~~md
[IMPORT] wsl:docs/physics/three-hypotheses.md
~~~~

* **`docs/physics/five-walls.md`:**
~~~~md
[IMPORT] wsl:docs/physics/five-walls.md
~~~~

---

#### Engineering

* **`docs/engineering/oracle-pipeline.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/oracle-pipeline.md
~~~~

* **`docs/engineering/orbit-reduction.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/orbit-reduction.md
~~~~

* **`docs/engineering/abstract-barrier.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/abstract-barrier.md
~~~~

* **`docs/engineering/generic-bridge-pattern.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/generic-bridge-pattern.md
~~~~

* **`docs/engineering/scaling-report.md`:**
~~~~md
[IMPORT] wsl:docs/engineering/scaling-report.md
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
~~~~md
[IMPORT] wsl:docs/reference/bibliography.md
~~~~

* **`docs/reference/assumptions.md`:**
~~~~md
[IMPORT] wsl:docs/reference/assumptions.md
~~~~

* **`docs/reference/glossary.md`:**
Content in this document not shown due to length.

* **`docs/reference/module-index.md`:**
~~~~md
[IMPORT] wsl:docs/reference/module-index.md
~~~~

---

#### Papers

* **`docs/papers/theory.tex`:**
~~~~tex
[IMPORT] wsl:docs/papers/theory.tex
~~~~

### Source Code

#### Util

* **`Util/Scalars.agda`:**
~~~~agda
[IMPORT] wsl:src/Util/Scalars.agda
~~~~

* **`Util/Rationals.agda`:**
~~~~agda
[IMPORT] wsl:src/Util/Rationals.agda
~~~~

* **`Util/NatLemmas.agda`:**
~~~~agda
[IMPORT] wsl:src/Util/NatLemmas.agda
~~~~

---

#### Common

* **`Common/ObsPackage.agda`:**
~~~~agda
[IMPORT] wsl:src/Common/ObsPackage.agda
~~~~

* **`Common/TreeSpec.agda`:**
~~~~agda
[IMPORT] wsl:src/Common/TreeSpec.agda
~~~~

* **`Common/StarSpec.agda`:**
~~~~agda
[IMPORT] wsl:src/Common/StarSpec.agda
~~~~

* **`Common/FilledSpec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`.
Content in this document not shown due to length.

* **`Common/Honeycomb3DSpec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
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

* **`Common/Layer54d2Spec.agda` ... `Layer54d7Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

---

#### Boundary

* **`Boundary/TreeCut.agda`:**
~~~~agda
[IMPORT] wsl:src/Boundary/TreeCut.agda
~~~~

* **`Boundary/StarSubadditivity.agda`:**
~~~~agda
[IMPORT] wsl:src/Boundary/StarSubadditivity.agda
~~~~

* **`Boundary/StarCut.agda`:**
~~~~agda
[IMPORT] wsl:src/Boundary/StarCut.agda
~~~~

* **`Boundary/FilledCut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Boundary/FilledSubadditivity.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Boundary/Honeycomb3DCut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
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
~~~~agda
[IMPORT] wsl:src/Boundary/StarCutParam.agda
~~~~

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
~~~~agda
[IMPORT] wsl:src/Bulk/TreeChain.agda
~~~~

* **`Bulk/StarChain.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/StarChain.agda
~~~~

* **`Bulk/PatchComplex.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/PatchComplex.agda
~~~~

* **`Bulk/Curvature.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/Curvature.agda
~~~~

* **`Bulk/GaussBonnet.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/GaussBonnet.agda
~~~~

* **`Bulk/StarMonotonicity.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/StarMonotonicity.agda
~~~~

* **`Bulk/FilledChain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Bulk/Honeycomb3DChain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Bulk/Honeycomb3DCurvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
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
~~~~agda
[IMPORT] wsl:src/Bulk/DeSitterPatchComplex.agda
~~~~

* **`Bulk/DeSitterCurvature.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/DeSitterCurvature.agda
~~~~

* **`Bulk/DeSitterGaussBonnet.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/DeSitterGaussBonnet.agda
~~~~

* **`Bulk/Dense200Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Bulk/Dense200Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Bulk/StarChainParam.agda`:**
~~~~agda
[IMPORT] wsl:src/Bulk/StarChainParam.agda
~~~~

* **`Bulk/Layer54d2Chain.agda` ... `Layer54d7Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

---

#### Bridge

* **`Bridge/TreeObs.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/TreeObs.agda
~~~~

* **`Bridge/TreeEquiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/StarObs.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/StarObs.agda
~~~~

* **`Bridge/StarEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
~~~~agda
-- Bridge/StarEquiv.agda (critical exports only)
star-obs-path : S-cut (π∂ starSpec) ≡ L-min (πbulk starSpec)
star-obs-path = funExt star-pointwise
~~~~

* **`Bridge/EnrichedStarObs.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/EnrichedStarObs.agda
~~~~

* **`Bridge/FullEnrichedStarObs.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/FullEnrichedStarObs.agda
~~~~

* **`Bridge/EnrichedStarEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
~~~~agda
Theorem3 : Type₀
Theorem3 = transport full-ua-path full-bdy ≡ full-bulk
theorem3 : Theorem3
theorem3 = full-transport
~~~~

* **`Bridge/FilledObs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Bridge/FilledEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
~~~~agda
S∂F : FilledRegion → ℚ≥0
S∂F = S-cut filledBdyView
LBF : FilledRegion → ℚ≥0  
LBF = L-min filledBulkView
~~~~

* **`Bridge/StarRawEquiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/FilledRawEquiv.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
Content in this document not shown due to length.

* **`Bridge/Honeycomb3DObs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
Content in this document not shown due to length.

* **`Bridge/Honeycomb3DEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
~~~~agda
S∂3D : H3Region → ℚ≥0
S∂3D = S-cut h3BdyView
LB3D : H3Region → ℚ≥0
LB3D = L-min h3BulkView
~~~~

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
~~~~agda
[IMPORT] wsl:src/Bridge/WickRotation.agda
~~~~

* **`Bridge/CoarseGrain.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/CoarseGrain.agda
~~~~

* **`Bridge/Dense100Thermodynamics.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/Dense100Thermodynamics.agda
~~~~

* **`Bridge/ResolutionTower.agda`:**
Content in this document not shown due to being no member of the critical path anymore.

* **`Bridge/Dense200Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
Content in this document not shown due to length.

* **`Bridge/StarStepInvariance.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/StarStepInvariance.agda
~~~~

* **`Bridge/StarDynamicsLoop.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/StarDynamicsLoop.agda
~~~~

* **`Bridge/EnrichedStarStepInvariance.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/EnrichedStarStepInvariance.agda
~~~~

* **`Bridge/GenericBridge.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/GenericBridge.agda
~~~~

* **`Bridge/GenericValidation.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/GenericValidation.agda
~~~~

* **`Bridge/SchematicTower.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/SchematicTower.agda
~~~~

* **`Bulk/Layer54d2Obs.agda` ... `Layer54d7Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

* **`Bridge/BridgeWitness.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/BridgeWitness.agda
~~~~

* **`Bridge/HalfBound.agda`:**
~~~~agda
[IMPORT] wsl:src/Bridge/HalfBound.agda
~~~~

---

#### Causal

* **`Causal/Event.agda`:**
~~~~agda
[IMPORT] wsl:src/Causal/Event.agda
~~~~

* **`Causal/CausalDiamond.agda`:**
~~~~agda
[IMPORT] wsl:src/Causal/CausalDiamond.agda
~~~~

* **`Causal/NoCTC.agda`:**
~~~~agda
[IMPORT] wsl:src/Causal/NoCTC.agda
~~~~

* **`Causal/LightCone.agda`:**
~~~~agda
[IMPORT] wsl:src/Causal/LightCone.agda
~~~~

#### Gauge

* **`Gauge/FiniteGroup.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/FiniteGroup.agda
~~~~

* **`Gauge/ZMod.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/ZMod.agda
~~~~

* **`Gauge/Q8.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/Q8.agda
~~~~

* **`Gauge/Connection.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/Connection.agda
~~~~

* **`Gauge/Holonomy.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/Holonomy.agda
~~~~

* **`Gauge/ConjugacyClass.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/ConjugacyClass.agda
~~~~

* **`Gauge/RepCapacity.agda`:**
~~~~agda
[IMPORT] wsl:src/Gauge/RepCapacity.agda
~~~~

---

#### Quantum

* **`Quantum/AmplitudeAlg.agda`:**
~~~~agda
[IMPORT] wsl:src/Quantum/AmplitudeAlg.agda
~~~~

* **`Quantum/Superposition.agda`:**
~~~~agda
[IMPORT] wsl:src/Quantum/Superposition.agda
~~~~

* **`Quantum/QuantumBridge.agda`:**
~~~~agda
[IMPORT] wsl:src/Quantum/QuantumBridge.agda
~~~~

* **`Quantum/StarQuantumBridge.agda`:**
~~~~agda
[IMPORT] wsl:src/Quantum/StarQuantumBridge.agda
~~~~

---

### SIM

* **`prototyping/requirements.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/requirements.txt
~~~~

* **`prototyping/shell.nix`:**
~~~~nix
[IMPORT] wsl:sim/prototyping/shell.nix
~~~~

* **`prototyping/01_happy_patch_cuts.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/01_happy_patch_cuts.py
~~~~

* **`prototyping/01_happy_patch_cuts_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/01_happy_patch_cuts_OUTPUT.txt
~~~~

* **`prototyping/02_happy_patch_curvature.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/02_happy_patch_curvature.py
~~~~

* **`prototyping/02_happy_patch_curvature_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/02_happy_patch_curvature_OUTPUT.txt
~~~~

* **`prototyping/03_generate_filled_patch.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/03_generate_filled_patch.py
~~~~

* **`prototyping/03_generate_filled_patch_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/03_generate_filled_patch_OUTPUT.txt
~~~~

* **`prototyping/04_generate_raw_equiv.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/04_generate_raw_equiv.py
~~~~

* **`prototyping/04_generate_raw_equiv_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/04_generate_raw_equiv_OUTPUT.txt
~~~~

* **`prototyping/05_honeycomb_3d_prototype.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/05_honeycomb_3d_prototype.py
~~~~

* **`prototyping/05_honeycomb_3d_prototype_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/05_honeycomb_3d_prototype_OUTPUT.txt
~~~~

* **`prototyping/06_generate_honeycomb_3d.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/06_generate_honeycomb_3d.py
~~~~

* **`prototyping/06_generate_honeycomb_3d_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/06_generate_honeycomb_3d_OUTPUT.txt
~~~~

* **`prototyping/07_honeycomb_3d_multiStrategy.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/07_honeycomb_3d_multiStrategy.py
~~~~

* **`prototyping/07_honeycomb_3d_multiStrategy_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/07_honeycomb_3d_multiStrategy_OUTPUT.txt
~~~~

* **`prototyping/08_generate_dense50.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/08_generate_dense50.py
~~~~

* **`prototyping/08_generate_dense50_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/08_generate_dense50_OUTPUT.txt
~~~~

* **`prototyping/09_generate_dense100.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/09_generate_dense100.py
~~~~

* **`prototyping/09_generate_dense100_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/09_generate_dense100_OUTPUT.txt
~~~~

* **`prototyping/10_desitter_prototype.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/10_desitter_prototype.py
~~~~

* **`prototyping/10_desitter_prototype_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/10_desitter_prototype_OUTPUT.txt
~~~~

* **`prototyping/11_generate_area_law.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/11_generate_area_law.py
~~~~

* **`prototyping/11_generate_area_law_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/11_generate_area_law_OUTPUT.txt
~~~~

* **`prototyping/12_generate_dense200.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/12_generate_dense200.py
~~~~

* **`prototyping/12_generate_dense200_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/12_generate_dense200_OUTPUT.txt
~~~~

* **`prototyping/13_generate_layerN.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/13_generate_layerN.py
~~~~

* **`prototyping/13_generate_layerN_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/13_generate_layerN_OUTPUT.txt
~~~~

* **`prototyping/14_entropic_convergence.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/14_entropic_convergence.py
~~~~

* **`prototyping/14_entropic_convergence_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/14_entropic_convergence_OUTPUT.txt
~~~~

* **`prototyping/14b_entropic_convergence_controlled.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/14b_entropic_convergence_controlled.py
~~~~

* **`prototyping/14b_entropic_convergence_controlled_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/14b_entropic_convergence_controlled_OUTPUT.txt
~~~~

* **`prototyping/14c_entropic_convergence_sup_half.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/14c_entropic_convergence_sup_half.py
~~~~

* **`prototyping/14c_entropic_convergence_sup_half_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/14c_entropic_convergence_sup_half_OUTPUT.txt
~~~~

* **`prototyping/15_discrete_bekenstein_hawking.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/15_discrete_bekenstein_hawking.py
~~~~

* **`prototyping/15_discrete_bekenstein_hawking_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/15_discrete_bekenstein_hawking_OUTPUT.txt
~~~~

* **`prototyping/16_half_bound_scaling.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/16_half_bound_scaling.py
~~~~

* **`prototyping/16_half_bound_scaling_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/16_half_bound_scaling_OUTPUT.txt
~~~~

* **`prototyping/17_generate_half_bound.py`:**
~~~~py
[IMPORT] wsl:sim/prototyping/17_generate_half_bound.py
~~~~

* **`prototyping/17_generate_half_bound_OUTPUT.txt`:**
~~~~text
[IMPORT] wsl:sim/prototyping/17_generate_half_bound_OUTPUT.txt
~~~~