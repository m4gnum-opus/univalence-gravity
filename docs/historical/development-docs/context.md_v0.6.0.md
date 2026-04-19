## TASK

Your task is to ...

---

## Toggle Context Inclusion
Toggles:
INCLUDE_FAMILY: [0,1]
INCLUDE_WHOLE_FAMILY[0,1]

- Root               -           [### Root](#Root)

- Docs               -  [### Documentation](#Documentation)
  - Root             -            [#### Root](#Root)
  - Getting-Started  - [#### Getting-Started](#Getting-Started)
  - Formal           -          [#### Formal](#Formal)
  - Physics          -         [#### Physics](#Physics)
  - Engineering      -     [#### Engineering](#Engineering)
  - Instances        -       [#### Instances](#Instances)
  - Reference        -       [#### Reference](#Reference)
  - Papers           -          [#### Papers](#Papers)

- Source (Agda)      -     [### SourceCode](#SourceCode)
  - Util             -            [#### Util](#Util)
  - Common           -          [#### Common](#Common)
  - Boundary         -        [#### Boundary](#Boundary)
  - Bulk             -            [#### Bulk](#Bulk)
  - Bridge           -          [#### Bridge](#Bridge)
  - Causal           -          [#### Causal](#Causal)
  - Gauge            -           [#### Gauge](#Gauge)
  - Quantum          -         [#### Quantum](#Quantum)

- SIM/Protot.        -            [### SIM](#SIM)

- Data               -           [### Data](#Data)
  - Patches          -         [#### Patches](#Patches)

- Backend            -        [### Backend](#Backend)
  - Tests            -   [#### Backend-Tests](#Backend-Tests)

- Frontend           -       [### Frontend](#Frontend)
  - Tests            -   [#### Frontend-Tests](#Frontend-Tests)

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
univalence-gravity/
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
│   │   ├── honeycomb-145.md
│   │   ├── dense-50.md                    # Dense-50 (139 regions, min-cut 1–7)
│   │   ├── dense-100.md                   # Dense-100 (717→8 orbits, min-cut 1–8, half-bound)
│   │   ├── dense-200.md                   # Dense-200 (1246→9 orbits, min-cut 1–9, half-bound)
│   │   ├── dense-1000.md
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
│   │   ├── Dense50Spec.agda           (AUTO-GEN PY FILE)
│   │   ├── Dense100Spec.agda          (AUTO-GEN PY FILE)
│   │   ├── Dense200Spec.agda          (AUTO-GEN PY FILE)
│   │   ├── Layer54d2Spec.agda         (AUTO-GEN PY FILE)
│   │   ├── ...
│   │   ├── Layer54d7Spec.agda         (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Spec.agda      (AUTO-GEN PY FILE)
│   │   └── Dense1000Spec.agda         (AUTO-GEN PY FILE)
│   │
│   ├── Boundary/
│   │   ├── TreeCut.agda
│   │   ├── StarSubadditivity.agda
│   │   ├── StarCut.agda
│   │   ├── FilledCut.agda             (AUTO-GEN PY FILE)
│   │   ├── FilledSubadditivity.agda   (AUTO-GEN PY FILE)
│   │   ├── Honeycomb3DCut.agda        (AUTO-GEN PY FILE)
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
│   │   ├── Dense200HalfBound.agda     (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Cut.agda       (AUTO-GEN PY FILE)
│   │   ├── Dense1000Cut.agda          (AUTO-GEN PY FILE)
│   │   ├── Dense1000AreaLaw.agda      (AUTO-GEN PY FILE)
│   │   └── Dense1000HalfBound.agda    (AUTO-GEN PY FILE)
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
│   │   ├── Layer54d7Chain.agda        (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Chain.agda     (AUTO-GEN PY FILE)
│   │   ├── Honeycomb145Curvature.agda (AUTO-GEN PY FILE)
│   │   ├── Dense1000Chain.agda
│   │   └── Dense1000Curvature.agda
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
│   │   ├── Honeycomb145Obs.agda       (AUTO-GEN PY FILE)
│   │   ├── Dense50Obs.agda            (AUTO-GEN PY FILE)
│   │   ├── Dense50Equiv.agda          (DEAD CODE)
│   │   ├── Dense100Obs.agda           (AUTO-GEN PY FILE)
│   │   ├── Dense100Equiv.agda         (DEAD CODE)
│   │   ├── WickRotation.agda
│   │   ├── CoarseGrain.agda
│   │   ├── Dense100Thermodynamics.agda
│   │   ├── ResolutionTower.agda       (DEAD CODE)
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
│   │   ├── HalfBound.agda
│   │   ├── Dense200Obs.agda
│   │   └── Dense1000Obs.agda
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
│       ├── 06b_generate_honeycomb145.py
│       ├── 06b_generate_honeycomb145_OUTPUT.txt
│       ├── 07_honeycomb_3d_multiStrategy.py
│       ├── 07_honeycomb_3d_multiStrategy_OUTPUT.txt
│       ├── 07b_honeycomb_3d_multiStrategy_reviewed.py
│       ├── 07b_honeycomb_3d_multiStrategy_reviewed_OUTPUT.txt
│       ├── 07c_honeycomb_3d_multiStrategy_hemisphere.py
│       ├── 07c_honeycomb_3d_multiStrategy_hemisphere_OUTPUT.txt
│       ├── 08_generate_dense50.py
│       ├── 08_generate_dense50_OUTPUT.txt
│       ├── 09_generate_dense100.py
│       ├── 09_generate_dense100_OUTPUT.txt
│       ├── 10_desitter_prototype.py
│       ├── 10_desitter_prototype_OUTPUT.txt
│       ├── 11_generate_area_law.py
│       ├── 12_generate_dense200.py
│       ├── 12_generate_dense200_OUTPUT.txt
│       ├── 12b_generate_dense1000.py
│       ├── 12b_generate_dense1000_OUTPUT.txt
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
├── backend/
│   ├── README.md
│   ├── backend.cabal
│   ├── cabal.project
│   ├── cabal.project.freeze
│   │
│   ├── app/
│   │   └── Main.hs             -- entry point, CLI parsing, server start
│   │
│   ├── src/
│   │   ├── Api.hs              -- Servant API type definition
│   │   ├── Server.hs           -- handler implementations + CORS middleware
│   │   ├── Types.hs            -- domain model (§3) + Meta, Health, CurvatureSummary
│   │   ├── DataLoader.hs       -- JSON parsing from data/ directory
│   │   └── Invariants.hs       -- startup validation checks
│   │
│   ├── test/
│   │   ├── Spec.hs             -- test entry point (hspec-discover)
│   │   ├── InvariantSpec.hs    -- property-based tests (§6)
│   │   └── ApiSpec.hs          -- Servant client tests
│   │
│   └── data/                   -- symlink to repo-root data/
│
└── frontend/
    ├── package.json
    ├── tsconfig.json
    ├── vite.config.ts
    ├── tailwind.config.js
    ├── postcss.config.js
    ├── .env.example
    ├── eslint.config.js
    ├── index.html
    │
    ├── public/
    │   └── favicon.ico
    │
    ├── src/
    │   ├── vite-env.d.ts
    │   ├── main.tsx
    │   ├── App.tsx
    │   ├── api/
    │   │   └── client.ts
    │   │
    │   ├── types/
    │   │   └── index.ts
    │   │
    │   ├── hooks/
    │   │   ├── usePatch.ts
    │   │   ├── usePatches.ts
    │   │   ├── useTower.ts
    │   │   ├── useTheorems.ts
    │   │   └── useMeta.ts
    │   │
    │   ├── components/
    │   │   ├── common/
    │   │   │   ├── Loading.tsx
    │   │   │   ├── ErrorMessage.tsx
    │   │   │   └── NotFound.tsx
    │   │   │
    │   │   ├── layout/
    │   │   │   ├── Header.tsx
    │   │   │   ├── Footer.tsx
    │   │   │   └── Layout.tsx
    │   │   │
    │   │   ├── home/
    │   │   │   ├── TheoremCard.tsx
    │   │   │   └── HomePage.tsx
    │   │   │
    │   │   ├── patches/
    │   │   │   ├── PatchCard.tsx
    │   │   │   ├── PatchList.tsx
    │   │   │   ├── PatchView.tsx
    │   │   │   ├── PatchScene.tsx
    │   │   │   ├── CellMesh.tsx
    │   │   │   ├── BondConnector.tsx
    │   │   │   ├── BoundaryWireframe.tsx
    │   │   │   ├── BoundaryShell.tsx
    │   │   │   ├── DynamicsView.tsx
    │   │   │   ├── RegionInspector.tsx
    │   │   │   ├── CurvaturePanel.tsx
    │   │   │   ├── HalfBoundPanel.tsx
    │   │   │   ├── DistributionChart.tsx
    │   │   │   └── ColorControls.tsx
    │   │   │
    │   │   ├── tower/
    │   │   │   ├── TowerTimeline.tsx
    │   │   │   ├── TowerLevel.tsx
    │   │   │   ├── TowerAnimation.tsx
    │   │   │   └── TowerView.tsx
    │   │   │
    │   │   └── theorems/
    │   │       ├── TheoremRow.tsx
    │   │       └── TheoremDashboard.tsx
    │   │
    │   ├── utils/
    │   │   ├── colors.ts
    │   │   ├── layout.ts
    │   │   └── tiling.ts
    │   │
    │   └── styles/
    │       └── globals.css
    │
    ├── tests/
    │   ├── setup.ts
    │   ├── api.test.ts
    │   ├── types.test.ts
    │   ├── utils/
    │   │   └── colors.test.ts
    │   │
    │   ├── hooks/
    │   │   └── usePatch.test.ts
    │   │
    │   └── components/
    │       ├── PatchCard.test.tsx
    │       ├── PatchScene.test.tsx
    │       └── TheoremCard.test.tsx
    │
    └── README.md
```

---

### Root

* **`LICENSE`:**
~~~~
- [ ] [IMPORT] wsl:LICENSE
~~~~

* **`.gitignore`:**
~~~~
- [ ] [IMPORT] wsl:.gitignore
~~~~

### Documentation
INCLUDE_FAMILY: 1
INCLUDE_WHOLE_FAMILY: 0

#### Root

* **`docs/README.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/README.md
~~~~

* **`docs/CITATION.cff`:**
~~~~md
- [ ] [IMPORT] wsl:docs/CITATION.cff
~~~~

* **docs/historical/:**
* Outsourced

---

#### Getting-Started
INCLUDE_FAMILY: 1

* **`docs/getting-started/abstract.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/getting-started/abstract.md
~~~~

* **`docs/getting-started/setup.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/getting-started/setup.md
~~~~

* **`docs/getting-started/building.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/getting-started/building.md
~~~~

* **`docs/getting-started/architecture.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/getting-started/architecture.md
~~~~

---

#### Formal
INCLUDE_FAMILY: 1
INCLUDE_WHOLE_FAMILY: 0

* **`docs/formal/01-theorems.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/formal/01-theorems.md
~~~~

* **`docs/formal/02-foundations.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/formal/02-foundations.md
~~~~

* **`docs/formal/03-holographic-bridge.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/03-holographic-bridge.md
~~~~

* **`docs/formal/04-discrete-geometry.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/04-discrete-geometry.md
~~~~

* **`docs/formal/05-gauge-theory.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/05-gauge-theory.md
~~~~

* **`docs/formal/06-causal-structure.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/06-causal-structure.md
~~~~

* **`docs/formal/07-quantum-superposition.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/07-quantum-superposition.md
~~~~

* **`docs/formal/08-wick-rotation.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/08-wick-rotation.md
~~~~

* **`docs/formal/09-thermodynamics.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/09-thermodynamics.md
~~~~

* **`docs/formal/10-dynamics.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/10-dynamics.md
~~~~

* **`docs/formal/11-generic-bridge.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/11-generic-bridge.md
~~~~

* **`docs/formal/12-bekenstein-hawking.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/formal/12-bekenstein-hawking.md
~~~~

---

#### Physics
INCLUDE_FAMILY: 0

* **`docs/physics/translation-problem.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/physics/translation-problem.md
~~~~

* **`docs/physics/holographic-dictionary.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/physics/holographic-dictionary.md
~~~~

* **`docs/physics/discrete-bekenstein-hawking.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/physics/discrete-bekenstein-hawking.md
~~~~

* **`docs/physics/three-hypotheses.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/physics/three-hypotheses.md
~~~~

* **`docs/physics/five-walls.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/physics/five-walls.md
~~~~

---

#### Engineering
INCLUDE_FAMILY: 1

* **`docs/engineering/oracle-pipeline.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/engineering/oracle-pipeline.md
~~~~

* **`docs/engineering/orbit-reduction.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/engineering/orbit-reduction.md
~~~~

* **`docs/engineering/abstract-barrier.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/engineering/abstract-barrier.md
~~~~

* **`docs/engineering/generic-bridge-pattern.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/engineering/generic-bridge-pattern.md
~~~~

* **`docs/engineering/scaling-report.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/engineering/scaling-report.md
~~~~

* **`docs/engineering/backend-spec-haskell.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/engineering/backend-spec-haskell.md
~~~~

* **`docs/engineering/frontend-spec-webgl.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/engineering/frontend-spec-webgl.md
~~~~

---

#### Instances
INCLUDE_FAMILY: 1
INCLUDE_WHOLE_FAMILY: 0

* **`docs/instances/tree-pilot.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/tree-pilot.md
~~~~

* **`docs/instances/star-patch.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/star-patch.md
~~~~

* **`docs/instances/filled-patch.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/filled-patch.md
~~~~

* **`docs/instances/honeycomb-3d.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/honeycomb-3d.md
~~~~

* **`docs/instances/honeycomb-145.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/honeycomb-145.md
~~~~

* **`docs/instances/dense-50.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/dense-50.md
~~~~

* **`docs/instances/dense-100.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/dense-100.md
~~~~

* **`docs/instances/dense-200.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/dense-200.md
~~~~

* **`docs/instances/dense-1000.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/dense-1000.md
~~~~

* **`docs/instances/layer-54-tower.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/layer-54-tower.md
~~~~

* **`docs/instances/desitter-patch.md`:**
~~~~md
- [ ] [IMPORT] wsl:docs/instances/desitter-patch.md
~~~~

---

#### Reference
INCLUDE_FAMILY: 0

* **`docs/reference/bibliography.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/reference/bibliography.md
~~~~

* **`docs/reference/assumptions.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/reference/assumptions.md
~~~~

* **`docs/reference/glossary.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/reference/glossary.md
~~~~

* **`docs/reference/module-index.md`:**
~~~~md
- [x] [IMPORT] wsl:docs/reference/module-index.md
~~~~

---

#### Papers

* **`docs/papers/theory.tex`:**
~~~~tex
- [ ] [IMPORT] wsl:docs/papers/theory.tex
~~~~

### SourceCode
INCLUDE_FAMILY: 0

#### Util
INCLUDE_FAMILY: 0

* **`Util/Scalars.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Util/Scalars.agda
~~~~

* **`Util/Rationals.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Util/Rationals.agda
~~~~

* **`Util/NatLemmas.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Util/NatLemmas.agda
~~~~

---

#### Common
INCLUDE_FAMILY: 1

* **`Common/ObsPackage.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Common/ObsPackage.agda
~~~~

* **`Common/TreeSpec.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Common/TreeSpec.agda
~~~~

* **`Common/StarSpec.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Common/StarSpec.agda
~~~~

* **`Common/FilledSpec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Common/FilledSpec.agda
~~~~

* **`Common/Honeycomb3DSpec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Common/Honeycomb3DSpec.agda
~~~~

* **`Common/Honeycomb145Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Common/Honeycomb145Spec.agda
~~~~

* **`Common/Dense50Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Common/Dense50Spec.agda
~~~~

* **`Common/Dense100Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Common/Dense100Spec.agda
~~~~

* **`Common/Dense200Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Common/Dense200Spec.agda
~~~~

* **`Common/Dense1000Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
Only the header is shown.
~~~~agda
{-# OPTIONS --cubical --safe --guardedness #-}

module Common.Dense1000Spec where

open import Cubical.Foundations.Prelude
open import Util.Scalars

--  Generated by sim/prototyping/12b_generate_dense1000.py
--  Do not edit by hand.  Regenerate with:
--    python3 sim/prototyping/12b_generate_dense1000.py

data D1000Region : Type₀ where
  -- size 1  (833 regions)
  d1000r0 d1000r1 d1000r94 d1000r98 d1000r101 d1000r103 d1000r104 d1000r113 d1000r182 d1000r216 : D1000Region
  d1000r285 d1000r319 d1000r340 d1000r401 d1000r429 d1000r498 d1000r532 d1000r543 d1000r544 d1000r577 : D1000Region
  d1000r595 d1000r607 d1000r628 d1000r697 d1000r731 d1000r742 d1000r743 d1000r754 d1000r758 d1000r761 : D1000Region
  d1000r763 d1000r764 d1000r773 d1000r842 d1000r876 d1000r885 d1000r891 d1000r897 d1000r899 d1000r900 : D1000Region
  d1000r909 d1000r930 d1000r999 d1000r1033 d1000r1094 d1000r1122 d1000r1191 d1000r1225 d1000r1236 d1000r1237 : D1000Region
  d1000r1270 d1000r1288 d1000r1300 d1000r1321 d1000r1390 d1000r1424 d1000r1485 d1000r1513 d1000r1582 d1000r1616 : D1000Region
  ...
~~~~

* **`Common/Layer54d2Spec.agda` ... `Layer54d7Spec.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Common/Layer54d2Spec.agda
~~~~

---

#### Boundary
INCLUDE_FAMILY: 1

* **`Boundary/TreeCut.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/TreeCut.agda
~~~~

* **`Boundary/StarSubadditivity.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/StarSubadditivity.agda
~~~~

* **`Boundary/StarCut.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/StarCut.agda
~~~~

* **`Boundary/FilledCut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/FilledCut.agda
~~~~

* **`Boundary/FilledSubadditivity.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/FilledSubadditivity.agda
~~~~

* **`Boundary/Honeycomb3DCut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Boundary/Honeycomb3DCut.agda
~~~~

* **`Boundary/Honeycomb145Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Boundary/Honeycomb145Cut.agda
~~~~

* **`Boundary/Dense50Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense50Cut.agda
~~~~

* **`Boundary/Dense100Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense100Cut.agda
~~~~

* **`Boundary/Dense100AreaLaw.agda`:**
AUTO-GENERATED PYTHON FILE FROM `11_generate_area_law.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense100AreaLaw.agda
~~~~

* **`Boundary/Dense100HalfBound.agda`:**
AUTO-GENERATED PYTHON FILE FROM `17_generate_half_bound.py.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense100HalfBound.agda
~~~~

* **`Boundary/Dense200Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense200Cut.agda
~~~~

* **`Boundary/Dense200AreaLaw.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense200AreaLaw.agda
~~~~

* **`Boundary/Dense200HalfBound.agda`:**
AUTO-GENERATED PYTHON FILE FROM `17_generate_half_bound.py.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Dense200HalfBound.agda
~~~~

* **`Boundary/Dense1000Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Boundary/Dense1000Cut.agda
~~~~

* **`Boundary/Dense1000AreaLaw.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
Only the header is shown.
~~~~agda
{-# OPTIONS --cubical --safe --guardedness #-}

module Boundary.Dense1000AreaLaw where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; _+_)
open import Util.Scalars
open import Common.Dense1000Spec
open import Boundary.Dense1000Cut
open import Bridge.Dense1000Obs using (d1000BdyView)

--  Generated by sim/prototyping/12b_generate_dense1000.py
--  Do not edit by hand.  Regenerate with:
--    python3 sim/prototyping/12b_generate_dense1000.py

regionArea : D1000Region → ℚ≥0
regionArea d1000r0 = 6    -- 1 cells
regionArea d1000r1 = 6    -- 1 cells
regionArea d1000r2 = 10    -- 2 cells
regionArea d1000r3 = 14    -- 3 cells
regionArea d1000r4 = 18    -- 4 cells
regionArea d1000r5 = 22    -- 5 cells
regionArea d1000r6 = 26    -- 6 cells
regionArea d1000r7 = 26    -- 6 cells
regionArea d1000r8 = 26    -- 6 cells
regionArea d1000r9 = 22    -- 5 cells
regionArea d1000r10 = 26    -- 6 cells
regionArea d1000r11 = 26    -- 6 cells
regionArea d1000r12 = 22    -- 5 cells
regionArea d1000r13 = 26    -- 6 cells
regionArea d1000r14 = 18    -- 4 cells
regionArea d1000r15 = 22    -- 5 cells
regionArea d1000r16 = 26    -- 6 cells
regionArea d1000r17 = 26    -- 6 cells
regionArea d1000r18 = 22    -- 5 cells
regionArea d1000r19 = 26    -- 6 cells
...
~~~~

* **`Boundary/Dense1000HalfBound.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
Only the header is shown.
~~~~agda
{-# OPTIONS --cubical --safe --guardedness #-}

module Boundary.Dense1000HalfBound where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ ; _+_)
open import Cubical.Data.Sigma using (Σ-syntax)

open import Util.Scalars
open import Common.Dense1000Spec
open import Boundary.Dense1000AreaLaw using (regionArea)
open import Bridge.GenericBridge using (PatchData ; orbit-to-patch)
open import Bridge.GenericValidation using (d1000OrbitPatch)
open import Bridge.HalfBound using (HalfBoundWitness)

--  Generated by sim/prototyping/12b_generate_dense1000.py
--  Do not edit by hand.  Regenerate with:
--    python3 sim/prototyping/12b_generate_dense1000.py

private
  pd : PatchData
  pd = orbit-to-patch d1000OrbitPatch

  S∂ : D1000Region → ℚ≥0
  S∂ = PatchData.S∂ pd

abstract
  half-bound-proof : (r : D1000Region) → (S∂ r +ℚ S∂ r) ≤ℚ regionArea r
  -- S=2, area=6, 2·S=4, slack=2
  half-bound-proof d1000r0 = 2 , refl
  -- S=1, area=6, 2·S=2, slack=4
  half-bound-proof d1000r1 = 4 , refl
  -- S=3, area=10, 2·S=6, slack=4
  half-bound-proof d1000r2 = 4 , refl
  -- S=3, area=14, 2·S=6, slack=8
  half-bound-proof d1000r3 = 8 , refl
  -- S=5, area=18, 2·S=10, slack=8
  half-bound-proof d1000r4 = 8 , refl
  -- S=6, area=22, 2·S=12, slack=10
  half-bound-proof d1000r5 = 10 , refl
  -- S=6, area=26, 2·S=12, slack=14
  half-bound-proof d1000r6 = 14 , refl
  -- S=7, area=26, 2·S=14, slack=12
  half-bound-proof d1000r7 = 12 , refl
  half-bound-proof d1000r8 = 12 , refl
  -- S=6, area=22, 2·S=12, slack=10
  half-bound-proof d1000r9 = 10 , refl
  -- S=7, area=26, 2·S=14, slack=12
  half-bound-proof d1000r10 = 12 , refl
  half-bound-proof d1000r11 = 12 , refl
  -- S=6, area=22, 2·S=12, slack=10
  half-bound-proof d1000r12 = 10 , refl
  -- S=7, area=26, 2·S=14, slack=12
  half-bound-proof d1000r13 = 12 , refl
  -- S=6, area=18, 2·S=12, slack=6
  half-bound-proof d1000r14 = 6 , refl
  -- S=7, area=22, 2·S=14, slack=8
~~~~

* **`Boundary/StarCutParam.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/StarCutParam.agda
~~~~

* **`Boundary/Layer54d2Cut.agda` ... `Layer54d7Cut.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Boundary/Layer54d2Cut.agda
~~~~

---

#### Bulk
INCLUDE_FAMILY: 1

* **`Bulk/TreeChain.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/TreeChain.agda
~~~~

* **`Bulk/StarChain.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/StarChain.agda
~~~~

* **`Bulk/PatchComplex.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/PatchComplex.agda
~~~~

* **`Bulk/Curvature.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Curvature.agda
~~~~

* **`Bulk/GaussBonnet.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/GaussBonnet.agda
~~~~

* **`Bulk/StarMonotonicity.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/StarMonotonicity.agda
~~~~

* **`Bulk/FilledChain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/StarMonotonicity.agda
~~~~

* **`Bulk/Honeycomb3DChain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/Honeycomb3DChain.agda
~~~~

* **`Bulk/Honeycomb3DCurvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/Honeycomb3DCurvature.agda
~~~~

* **`Bulk/Honeycomb145Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/Honeycomb145Chain.agda
~~~~

* **`Bulk/Honeycomb145Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/Honeycomb145Curvature.agda
~~~~

* **`Bulk/Dense50Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Dense50Chain.agda
~~~~

* **`Bulk/Dense50Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Dense50Curvature.agda
~~~~

* **`Bulk/Dense100Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Dense100Chain.agda
~~~~

* **`Bulk/Dense100Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Dense100Curvature.agda
~~~~

* **`Bulk/Dense200Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Dense200Chain.agda
~~~~

* **`Bulk/Dense200Curvature.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/Dense200Curvature.agda
~~~~

* **`Bulk/Dense1000Chain.agda   .agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/Dense1000Chain.agda
~~~~

* **`Bulk/Dense1000Curvature.agda   .agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/Dense1000Curvature.agda
~~~~

* **`Bulk/DeSitterPatchComplex.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/DeSitterPatchComplex.agda
~~~~

* **`Bulk/DeSitterCurvature.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/DeSitterCurvature.agda
~~~~

* **`Bulk/DeSitterGaussBonnet.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bulk/DeSitterGaussBonnet.agda
~~~~

* **`Bulk/StarChainParam.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bulk/StarChainParam.agda
~~~~

* **`Bulk/Layer54d2Chain.agda` ... `Layer54d7Chain.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
Content in this document not shown due to length.

---

#### Bridge
INCLUDE_FAMILY: 1

* **`Bridge/TreeObs.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/TreeObs.agda
~~~~

* **`Bridge/TreeEquiv.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/TreeObs.agda
~~~~

* **`Bridge/StarObs.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/StarObs.agda
~~~~

* **`Bridge/StarEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
~~~~agda
-- Bridge/StarEquiv.agda (critical exports only)
star-obs-path : S-cut (π∂ starSpec) ≡ L-min (πbulk starSpec)
star-obs-path = funExt star-pointwise
~~~~

* **`Bridge/StarRawEquiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore. (dead code)

* **`Bridge/StarStepInvariance.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/StarStepInvariance.agda
~~~~

* **`Bridge/StarDynamicsLoop.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/StarDynamicsLoop.agda
~~~~

* **`Bridge/EnrichedStarObs.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/EnrichedStarObs.agda
~~~~

* **`Bridge/FullEnrichedStarObs.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/FullEnrichedStarObs.agda
~~~~

* **`Bridge/EnrichedStarEquiv.agda`:**
Stub, showing only the exported definitions for the critical path. (dead code)
~~~~agda
Theorem3 : Type₀
Theorem3 = transport full-ua-path full-bdy ≡ full-bulk
theorem3 : Theorem3
theorem3 = full-transport
~~~~

* **`Bridge/EnrichedStarStepInvariance.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/EnrichedStarStepInvariance.agda
~~~~

* **`Bridge/FilledObs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/FilledObs.agda
~~~~

* **`Bridge/FilledRawEquiv.agda`:**
AUTO-GENERATED PYTHON FILE FROM `03_generate_filled_patch.py`
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/FilledRawEquiv.agda
~~~~

* **`Bridge/FilledEquiv.agda`:**
Stub, showing only the exported definitions for the critical path.
~~~~agda
S∂F : FilledRegion → ℚ≥0
S∂F = S-cut filledBdyView
LBF : FilledRegion → ℚ≥0  
LBF = L-min filledBulkView
~~~~

* **`Bridge/Honeycomb3DObs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06_generate_honeycomb_3d.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/Honeycomb3DObs.agda
~~~~

* **`Bridge/Honeycomb3DEquiv.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/Honeycomb3DEquiv.agda
~~~~

* **`Bridge/Honeycomb145Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `06b_generate_honeycomb145.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/Honeycomb145Obs.agda
~~~~

* **`Bridge/Dense50Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `08_generate_dense50.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/Dense50Obs.agda
~~~~

* **`Bridge/Dense50Equiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore. (dead code)

* **`Bridge/Dense100Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `09_generate_dense100.py`.
Content in this document not shown due to length.

* **`Bridge/Dense100Equiv.agda`:**
Content in this document not shown due to being no member of the critical path anymore. (dead code)

* **`Bridge/Dense100Thermodynamics.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/Dense100Thermodynamics.agda
~~~~

* **`Bridge/Dense200Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `12_generate_dense200.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/Dense200Obs.agda
~~~~

* **`Bulk/Dense1000Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13b_generate_dense1000.py`.
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/Dense1000Obs.agda
~~~~

* **`Bulk/Layer54d2Obs.agda` ... `Layer54d7Obs.agda`:**
AUTO-GENERATED PYTHON FILE FROM `13_generate_layerN.py`.
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/Layer54d2Obs.agda
~~~~

* **`Bridge/ResolutionTower.agda`:**
Content in this document not shown due to being no member of the critical path anymore. (dead code)

* **`Bridge/BridgeWitness.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/BridgeWitness.agda
~~~~

* **`Bridge/CoarseGrain.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Bridge/CoarseGrain.agda
~~~~

* **`Bridge/GenericBridge.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/GenericBridge.agda
~~~~

* **`Bridge/GenericValidation.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/GenericValidation.agda
~~~~

* **`Bridge/SchematicTower.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/SchematicTower.agda
~~~~

* **`Bridge/WickRotation.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/WickRotation.agda
~~~~

* **`Bridge/HalfBound.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Bridge/HalfBound.agda
~~~~

---

#### Causal
INCLUDE_FAMILY: ß

* **`Causal/Event.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Causal/Event.agda
~~~~

* **`Causal/CausalDiamond.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Causal/CausalDiamond.agda
~~~~

* **`Causal/NoCTC.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Causal/NoCTC.agda
~~~~

* **`Causal/LightCone.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Causal/LightCone.agda
~~~~

#### Gauge
INCLUDE_FAMILY: 0

* **`Gauge/FiniteGroup.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Gauge/FiniteGroup.agda
~~~~

* **`Gauge/ZMod.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Gauge/ZMod.agda
~~~~

* **`Gauge/Q8.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Gauge/Q8.agda
~~~~

* **`Gauge/Connection.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Gauge/Connection.agda
~~~~

* **`Gauge/Holonomy.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Gauge/Holonomy.agda
~~~~

* **`Gauge/ConjugacyClass.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Gauge/ConjugacyClass.agda
~~~~

* **`Gauge/RepCapacity.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Gauge/RepCapacity.agda
~~~~

---

#### Quantum
INCLUDE_FAMILY: 0

* **`Quantum/AmplitudeAlg.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Quantum/AmplitudeAlg.agda
~~~~

* **`Quantum/Superposition.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Quantum/Superposition.agda
~~~~

* **`Quantum/QuantumBridge.agda`:**
~~~~agda
- [x] [IMPORT] wsl:src/Quantum/QuantumBridge.agda
~~~~

* **`Quantum/StarQuantumBridge.agda`:**
~~~~agda
- [ ] [IMPORT] wsl:src/Quantum/StarQuantumBridge.agda
~~~~

---

### SIM
INCLUDE_FAMILY: 1
INCLUDE_WHOLE_FAMILY: 0

* **`prototyping/requirements.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/requirements.txt
~~~~

* **`prototyping/shell.nix`:**
~~~~nix
- [ ] [IMPORT] wsl:sim/prototyping/shell.nix
~~~~

* **`prototyping/01_happy_patch_cuts.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/01_happy_patch_cuts.py
~~~~

* **`prototyping/01_happy_patch_cuts_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/01_happy_patch_cuts_OUTPUT.txt
~~~~

* **`prototyping/02_happy_patch_curvature.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/02_happy_patch_curvature.py
~~~~

* **`prototyping/02_happy_patch_curvature_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/02_happy_patch_curvature_OUTPUT.txt
~~~~

* **`prototyping/03_generate_filled_patch.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/03_generate_filled_patch.py
~~~~

* **`prototyping/03_generate_filled_patch_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/03_generate_filled_patch_OUTPUT.txt
~~~~

* **`prototyping/04_generate_raw_equiv.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/04_generate_raw_equiv.py
~~~~

* **`prototyping/04_generate_raw_equiv_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/04_generate_raw_equiv_OUTPUT.txt
~~~~

* **`prototyping/05_honeycomb_3d_prototype.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/05_honeycomb_3d_prototype.py
~~~~

* **`prototyping/05_honeycomb_3d_prototype_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/05_honeycomb_3d_prototype_OUTPUT.txt
~~~~

* **`prototyping/06_generate_honeycomb_3d.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/06_generate_honeycomb_3d.py
~~~~

* **`prototyping/06_generate_honeycomb_3d_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/06_generate_honeycomb_3d_OUTPUT.txt
~~~~

* **`prototyping/06b_generate_honeycomb145.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/06b_generate_honeycomb145.py
~~~~

* **`prototyping/06b_generate_honeycomb145_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/06b_generate_honeycomb145_OUTPUT.txt
~~~~

* **`prototyping/07_honeycomb_3d_multiStrategy.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/07_honeycomb_3d_multiStrategy.py
~~~~

* **`prototyping/07_honeycomb_3d_multiStrategy_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/07_honeycomb_3d_multiStrategy_OUTPUT.txt
~~~~

* **`prototyping/07b_honeycomb_3d_multiStrategy_reviewed.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/07b_honeycomb_3d_multiStrategy_reviewed.py
~~~~

* **`prototyping/07b_honeycomb_3d_multiStrategy_reviewed_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/07b_honeycomb_3d_multiStrategy_reviewed_OUTPUT.txt
~~~~

* **`prototyping/07c_honeycomb_3d_multiStrategy_hemisphere.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/07c_honeycomb_3d_multiStrategy_hemisphere.py
~~~~

* **`prototyping/07c_honeycomb_3d_multiStrategy_hemisphere_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/07c_honeycomb_3d_multiStrategy_hemisphere_OUTPUT.txt
~~~~

* **`prototyping/08_generate_dense50.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/08_generate_dense50.py
~~~~

* **`prototyping/08_generate_dense50_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/08_generate_dense50_OUTPUT.txt
~~~~

* **`prototyping/09_generate_dense100.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/09_generate_dense100.py
~~~~

* **`prototyping/09_generate_dense100_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/09_generate_dense100_OUTPUT.txt
~~~~

* **`prototyping/10_desitter_prototype.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/10_desitter_prototype.py
~~~~

* **`prototyping/10_desitter_prototype_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/10_desitter_prototype_OUTPUT.txt
~~~~

* **`prototyping/11_generate_area_law.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/11_generate_area_law.py
~~~~

* **`prototyping/11_generate_area_law_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/11_generate_area_law_OUTPUT.txt
~~~~

* **`prototyping/12_generate_dense200.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/12_generate_dense200.py
~~~~

* **`prototyping/12_generate_dense200_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/12_generate_dense200_OUTPUT.txt
~~~~

* **`prototyping/12b_generate_dense1000.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/12b_generate_dense1000.py
~~~~

* **`prototyping/12b_generate_dense1000_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/12b_generate_dense1000_OUTPUT.txt
~~~~

* **`prototyping/13_generate_layerN.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/13_generate_layerN.py
~~~~

* **`prototyping/13_generate_layerN_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/13_generate_layerN_OUTPUT.txt
~~~~

* **`prototyping/14_entropic_convergence.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/14_entropic_convergence.py
~~~~

* **`prototyping/14_entropic_convergence_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/14_entropic_convergence_OUTPUT.txt
~~~~

* **`prototyping/14b_entropic_convergence_controlled.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/14b_entropic_convergence_controlled.py
~~~~

* **`prototyping/14b_entropic_convergence_controlled_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/14b_entropic_convergence_controlled_OUTPUT.txt
~~~~

* **`prototyping/14c_entropic_convergence_sup_half.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/14c_entropic_convergence_sup_half.py
~~~~

* **`prototyping/14c_entropic_convergence_sup_half_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/14c_entropic_convergence_sup_half_OUTPUT.txt
~~~~

* **`prototyping/15_discrete_bekenstein_hawking.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/15_discrete_bekenstein_hawking.py
~~~~

* **`prototyping/15_discrete_bekenstein_hawking_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/15_discrete_bekenstein_hawking_OUTPUT.txt
~~~~

* **`prototyping/16_half_bound_scaling.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/16_half_bound_scaling.py
~~~~

* **`prototyping/16_half_bound_scaling_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/16_half_bound_scaling_OUTPUT.txt
~~~~

* **`prototyping/17_generate_half_bound.py`:**
~~~~py
- [ ] [IMPORT] wsl:sim/prototyping/17_generate_half_bound.py
~~~~

* **`prototyping/17_generate_half_bound_OUTPUT.txt`:**
~~~~text
- [ ] [IMPORT] wsl:sim/prototyping/17_generate_half_bound_OUTPUT.txt
~~~~

* **`prototyping/18_export_json.py`:**
~~~~py
- [x] [IMPORT] wsl:sim/prototyping/18_export_json.py
~~~~

* **`prototyping/18_export_json_OUTPUT.txt`:**
~~~~text
- [x] [IMPORT] wsl:sim/prototyping/18_export_json_OUTPUT.txt
~~~~

---

### Data
INCLUDE_FAMILY: 0
INCLUDE_WHOLE_FAMILY: 0

* **`backend/data/curvature.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/curvature.json
~~~~

* **`backend/data/meta.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/meta.json
~~~~

* **`backend/data/theorems.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/theorems.json
~~~~

* **`backend/data/tower.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/tower.json
~~~~

---

#### Patches
INCLUDE_FAMILY: 1

* **`patches/tree.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/patches/tree.json
~~~~

* **`patches/star.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/patches/star.json
~~~~

* **`patches/desitter.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/patches/desitter.json
~~~~

* **`patches/dense-50.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/dense-50.json
~~~~

* **`patches/dense-100.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/dense-100.json
~~~~

* **`patches/dense-200.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/dense-200.json
~~~~

* **`patches/dense-1000.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/dense-1000.json
~~~~

* **`patches/honeycomb-3d.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/patches/honeycomb-3d.json
~~~~

* **`patches/honeycomb-145.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/honeycomb-145.json
~~~~

* **`patches/layer-54-d2.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [x] [IMPORT] wsl:data/patches/layer-54-d2.json
~~~~

* **`patches/layer-54-d3.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/layer-54-d3.json
~~~~

* **`patches/layer-54-d4.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/layer-54-d4.json
~~~~

* **`patches/layer-54-d5.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/layer-54-d5.json
~~~~

* **`patches/layer-54-d6.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/layer-54-d6.json
~~~~

* **`patches/layer-54-d7.json`:**
AUTO-GENERATED PYTHON FILE FROM `18_export_json.py`.
~~~~json
- [ ] [IMPORT] wsl:data/patches/layer-54-d7.json
~~~~

---

### Backend
INCLUDE_FAMILY: 0
INCLUDE_WHOLE_FAMILY: 0

#### Root

* **`README.md`:**
~~~~cabal
- [x] [IMPORT] wsl:backend/README.md
~~~~

* **`backend.cabal`:**
~~~~cabal
- [ ] [IMPORT] wsl:backend/backend.cabal
~~~~

* **`cabal.project`:**
~~~~project
- [ ] [IMPORT] wsl:backend/cabal.project
~~~~

* **`cabal.project.freeze`:**
~~~~freeze
- [ ] [IMPORT] wsl:backend/cabal.project.freeze
~~~~

---

#### App

* **`app/Main.hs`:**
~~~~hs
- [ ] [IMPORT] wsl:backend/app/Main.hs
~~~~

#### Source Code

* **`src/Types.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/src/Types.hs
~~~~

* **`src/DataLoader.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/src/DataLoader.hs
~~~~

* **`src/Invariants.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/src/Invariants.hs
~~~~

* **`src/Api.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/src/Api.hs
~~~~

* **`src/Server.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/src/Server.hs
~~~~

---

#### Backend-Tests
INCLUDE_FAMILY: 0

* **`test/Spec.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/test/Spec.hs
~~~~

* **`test/InvariantSpec.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/test/InvariantSpec.hs
~~~~

* **`test/ApiSpec.hs`:**
~~~~hs
- [x] [IMPORT] wsl:backend/test/ApiSpec.hs
~~~~

---

---

### Frontend
INCLUDE_FAMILY: 0
INCLUDE_WHOLE_FAMILY: 0

#### Root

* **`README.md`:**
~~~~json
- [x] [IMPORT] wsl:frontend/README.md
~~~~

* **`package.json`:**
~~~~json
- [ ] [IMPORT] wsl:frontend/package.json
~~~~

* **`tsconfig.json`:**
~~~~json
- [x] [IMPORT] wsl:frontend/tsconfig.json
~~~~

* **`vite.config.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/vite.config.ts
~~~~

* **`tailwind.config.js`:**
~~~~js
- [x] [IMPORT] wsl:frontend/tailwind.config.js
~~~~

* **`postcss.config.js`:**
~~~~js
- [x] [IMPORT] wsl:frontend/postcss.config.js
~~~~

* **`.env.example`:**
~~~~
- [ ] [IMPORT] wsl:frontend/.env.example
~~~~

* **`.env`:**
~~~~
- [ ] [IMPORT] wsl:frontend/.env
~~~~

* **`eslint.config.js`:**
~~~~js
- [x] [IMPORT] wsl:frontend/eslint.config.js
~~~~

* **`index.html`:**
~~~~html
- [x] [IMPORT] wsl:frontend/index.html
~~~~

---

#### Source Code

##### Root

* **`src/vite-env.d.ts`:**
~~~~tsx
- [ ] [IMPORT] wsl:frontend/src/vite-env.d.ts
~~~~

* **`src/main.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/main.tsx
~~~~

* **`src/App.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/App.tsx
~~~~

---

##### API

* **`src/api/client.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/api/client.ts
~~~~

---

##### Types

* **`src/types/index.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/types/index.ts
~~~~

---

##### Hooks

* **`src/hooks/usePatch.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/hooks/usePatch.ts
~~~~

* **`src/hooks/usePatches.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/hooks/usePatches.ts
~~~~

* **`src/hooks/useTower.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/hooks/useTower.ts
~~~~

* **`src/hooks/useTheorems.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/hooks/useTheorems.ts
~~~~

* **`src/hooks/useMeta.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/hooks/useMeta.ts
~~~~

---

##### Components

###### Common

* **`src/components/common/Loading.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/common/Loading.tsx
~~~~

* **`src/components/common/ErrorMessage.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/common/ErrorMessage.tsx
~~~~

* **`src/components/common/NotFound.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/common/NotFound.tsx
~~~~

---

###### Layout

* **`src/components/layout/Header.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/layout/Header.tsx
~~~~

* **`src/components/layout/Footer.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/layout/Footer.tsx
~~~~

* **`src/components/layout/Layout.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/layout/Layout.tsx
~~~~

---

###### Home

* **`src/components/home/TheoremCard.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/home/TheoremCard.tsx
~~~~

* **`src/components/home/HomePage.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/home/HomePage.tsx
~~~~

---

###### Patches

* **`src/components/patches/PatchCard.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/PatchCard.tsx
~~~~

* **`src/components/patches/PatchList.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/PatchList.tsx
~~~~

* **`src/components/patches/PatchView.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/PatchView.tsx
~~~~

* **`src/components/patches/PatchScene.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/PatchScene.tsx
~~~~

* **`src/components/patches/CellMesh.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/CellMesh.tsx
~~~~

* **`src/components/patches/BondConnector.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/BondConnector.tsx
~~~~

* **`src/components/patches/BoundaryWireframe.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/BoundaryWireframe.tsx
~~~~

* **`src/components/patches/BoundaryShell.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/BoundaryShell.tsx
~~~~

* **`src/components/patches/DynamicsView.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/DynamicsView.tsx
~~~~

* **`src/components/patches/RegionInspector.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/RegionInspector.tsx
~~~~

* **`src/components/patches/CurvaturePanel.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/CurvaturePanel.tsx
~~~~

* **`src/components/patches/HalfBoundPanel.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/HalfBoundPanel.tsx
~~~~

* **`src/components/patches/DistributionChart.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/DistributionChart.tsx
~~~~

* **`src/components/patches/ColorControls.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/patches/ColorControls.tsx
~~~~

---

###### Tower

* **`src/components/tower/TowerLevel.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/tower/TowerLevel.tsx
~~~~

* **`src/components/tower/TowerTimeline.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/tower/TowerTimeline.tsx
~~~~

* **`src/components/tower/TowerAnimation.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/tower/TowerAnimation.tsx
~~~~

* **`src/components/tower/TowerView.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/tower/TowerView.tsx
~~~~

---

###### Theorems

* **`src/components/theorems/TheoremRow.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/theorems/TheoremRow.tsx
~~~~

* **`src/components/theorems/TheoremDashboard.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/src/components/theorems/TheoremDashboard.tsx
~~~~

---

##### Utils

* **`src/utils/colors.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/utils/colors.ts
~~~~

* **`src/utils/layout.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/utils/layout.ts
~~~~

* **`src/utils/tiling.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/src/utils/tiling.ts
~~~~

---

##### Styles

* **`src/styles/globals.css`:**
~~~~css
- [x] [IMPORT] wsl:frontend/src/styles/globals.css
~~~~

---

#### Frontend-Tests
INCLUDE_FAMILY: 0

##### Root

* **`tests/setup.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/tests/setup.ts
~~~~

* **`tests/api.test.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/tests/api.test.ts
~~~~

* **`tests/types.test.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/tests/types.test.ts
~~~~

---

##### Utils

* **`tests/utils/colors.test.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/tests/utils/colors.test.ts
~~~~

---

##### Hooks

* **`tests/hooks/usePatch.test.ts`:**
~~~~ts
- [x] [IMPORT] wsl:frontend/tests/hooks/usePatch.test.ts
~~~~

---

##### Components

* **`tests/components/PatchCard.test.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/tests/components/PatchCard.test.tsx
~~~~

* **`tests/components/PatchScene.test.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/tests/components/PatchScene.test.tsx
~~~~

* **`tests/components/TheoremCard.test.tsx`:**
~~~~tsx
- [x] [IMPORT] wsl:frontend/tests/components/TheoremCard.test.tsx
~~~~