## TASK

[...]

---

## METADATA / CONTEXT

- **Compiler:** Agda 2.8.0
- **Library:** agda/cubical (April 2026 version)
- **Primary Domain:** Univalent Foundations / Synthetic Homotopy Theory

- **`docs/10-frontier.md`:**
~~~~md

~~~~

---

## REPOSITORY CONTEXT

*Note: In this document, file contents are enclosed in four tildes (e.g., `~~~~agda` or `~~~~md`) to prevent markdown block collision.*

### Current Repo Structure

```
/home/zimablue/univalence-gravity/
├── README.md
│
├── docs/
│    ├── 00-abstract.md
│    ├── 01-introduction.md
│    ├── 02-foundations.md
│    ├── 03-architecture.md
│    ├── 04-tooling.md
│    ├── 05-roadmap.md
│    ├── 06-challenges.md
│    ├── 07-references.md
│    ├── 08-tree-instance.md
│    ├── 09-happy-instance.md
│    ├── 10-frontier.md
│    ├── assumptions.md
│    ├── dev-setup.md
│    ├── theory.tex
│    ├── repo-close.md
│    ├── refactoring.md
│    └── repo-close_2.md
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
│    │    └── Layer54d7Cut.agda         (AUTO-GEN PY FILE)
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
│    │    ├── Layer54d7Chain.agda       (AUTO-GEN PY FILE)
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
│    │    ├── Layer54d7Obs.agda        (AUTO-GEN PY FILE)
│    │    ├── ...
│    │    ├── Layer54d7Obs.agda        (AUTO-GEN PY FILE)
│    │    └── BridgeWitness.agda
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
          └── 13_generate_layerN_OUTPUT.txt
```

---

### Documentation

* **`README.md`:**
~~~~md
[IMPORT] wsl:README.md
~~~~

* **`docs/00-abstract.md`:**
~~~~md
[IMPORT] wsl:docs/00-abstract.md
~~~~

* **`docs/01-introduction.md`:**
~~~~md
[IMPORT] wsl:docs/01-introduction.md
~~~~

* **`docs/02-foundations.md`:**
~~~~md
[IMPORT] wsl:docs/02-foundations.md
~~~~

* **`docs/03-architecture.md`:**
~~~~md
[IMPORT] wsl:docs/03-architecture.md
~~~~

* **`docs/04-tooling.md`:**
~~~~md
[IMPORT] wsl:docs/04-tooling.md
~~~~

* **`docs/05-roadmap.md`:**
~~~~md
[IMPORT] wsl:docs/05-roadmap.md
~~~~

* **`docs/06-challenges.md`:**
~~~~md
[IMPORT] wsl:docs/06-challenges.md
~~~~

* **`docs/07-references.md`:**
~~~~md
[IMPORT] wsl:docs/07-references.md
~~~~

* **`docs/08-tree-instance.md`:**
~~~~md
[IMPORT] wsl:docs/08-tree-instance.md
~~~~

* **`docs/09-happy-instance.md`:**
~~~~md
[IMPORT] wsl:docs/09-happy-instance.md
~~~~

* **`docs/10-frontier.md`:**
~~~~md
[IMPORT] wsl:docs/10-frontier.md
~~~~

* **`docs/assumptions.md`:**
~~~~md
[IMPORT] wsl:docs/assumptions.md
~~~~

* **`docs/dev-setup.md`:**
~~~~md
[IMPORT] wsl:docs/dev-setup.md
~~~~

* **`docs/theory.tex`:**
~~~~tex
[IMPORT] wsl:docs/repo-close.md
~~~~

* **`docs/repo-close.md`:**
~~~~md
[IMPORT] wsl:docs/repo-close.md
~~~~

* **`docs/refactoring.md`:**
~~~~md
[IMPORT] wsl:docs/refactoring.md
~~~~

* **`docs/repo-close_2.md`:**
~~~~md
[IMPORT] wsl:docs/repo-close_2.md
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