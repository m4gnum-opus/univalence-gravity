# Univalence Gravity - The Spacetime Compiler v0.6.0

**A Constructive Formalization of Discrete Entanglement-Geometry Duality in Cubical Agda**

*By Sven Bichtemann* | Agda 2.8.0 | agda/cubical library | MIT License

## What This Is

A machine-checked proof that five pillars of a holographic universe
— geometry, causality, gauge matter, curvature, and quantum
superposition — coexist in a single formal artifact, verified by
the Cubical Agda type-checker via computational transport along
Univalence paths.

The project ships three cooperating layers:

- **Cubical Agda** formalization (`src/`) — the verification kernel.
- **Haskell backend** (`backend/`) — a REST API serving the verified,
  pre-computed patch data with startup-time invariant validation.
- **React + Three.js frontend** (`frontend/`) — an interactive WebGL
  visualization of the 16 verified holographic patch instances,
  rendered as Escher-style Poincaré projections.

## Key Results (All Machine-Checked)

| Result | Module | Statement |
|--------|--------|-----------|
| **Discrete Ryu–Takayanagi** | `Bridge/GenericBridge.agda` | S_cut = L_min for all boundary regions, on any patch, via a single generic theorem |
| **Discrete Gauss–Bonnet** | `Bulk/GaussBonnet.agda` | Σκ(v) = χ(K) = 1 for the {5,4} hyperbolic tiling (by `refl`) |
| **Discrete Bekenstein–Hawking** | `Bridge/HalfBound.agda` | S(A) ≤ area(A)/2 with 1/(4G) = 1/2 in bond-dimension-1 units |
| **Discrete Wick Rotation** | `Bridge/WickRotation.agda` | The holographic bridge is curvature-agnostic: same Agda term for AdS ({5,4}) and dS ({5,3}) |
| **No Closed Timelike Curves** | `Causal/NoCTC.agda` | Structural acyclicity from ℕ well-foundedness — the type system prevents time travel |
| **Matter as Topological Defects** | `Gauge/Holonomy.agda` | Non-trivial Q₈ Wilson loops on the holographic network |
| **Quantum Superposition Bridge** | `Quantum/QuantumBridge.agda` | ⟨S⟩ = ⟨L⟩ for any finite superposition (5-line proof, amplitude-polymorphic) |

For the full theorem registry with type signatures and module cross-references, see [`docs/formal/01-theorems.md`](formal/01-theorems.md).

## Quick Start

### Verify the Agda Proofs

```bash
# Prerequisites: Agda 2.8.0, agda/cubical library
# See docs/getting-started/setup.md for full environment setup
# See docs/getting-started/building.md for module load order

# Type-check the core theorems:
agda -i src src/Bridge/GenericBridge.agda    # Discrete RT (generic)
agda -i src src/Bulk/GaussBonnet.agda        # Discrete Gauss–Bonnet
agda -i src src/Bridge/HalfBound.agda        # Discrete Bekenstein–Hawking
agda -i src src/Bridge/WickRotation.agda     # Discrete Wick Rotation
agda -i src src/Causal/NoCTC.agda            # No CTCs
agda -i src src/Gauge/Holonomy.agda          # Matter defects
agda -i src src/Quantum/QuantumBridge.agda   # Quantum superposition bridge
```

### Run the Haskell Backend

```bash
# Prerequisites: GHC 9.6+, Cabal 3.10+
cd backend
cabal update && cabal build all
cabal test all            # property-based + integration tests
cabal run univalence-gravity-backend
# → Listening on http://localhost:8080
```

The backend serves pre-computed, Agda-verified holographic patch data via a REST API. It is a hand-written Haskell server — not compiled from Agda (Cubical Agda's `--cubical` flag has no meaningful GHC runtime extraction). Startup-time invariants re-check half-bound, orbit consistency, Gauss–Bonnet, graph structure, and per-cell Poincaré geometry against the JSON export. See [`docs/engineering/backend-spec-haskell.md`](engineering/backend-spec-haskell.md) and [`backend/README.md`](../backend/README.md) for details.

**API at a glance:**

| Endpoint | Description |
|----------|-------------|
| `GET /patches` | List all 16 verified patch instances (lightweight summaries) |
| `GET /patches/:name` | Full patch data (regions, curvature, half-bound, bulk graph with Poincaré coordinates + rotation quaternions + conformal scales) |
| `GET /tower` | Resolution tower with monotonicity witnesses |
| `GET /theorems` | All 10 machine-checked theorems |
| `GET /curvature` | Gauss–Bonnet summaries |
| `GET /meta` | Version, Agda version, data hash |
| `GET /health` | Server health check |

### Run the Frontend (WebGL Visualization)

```bash
# Prerequisites: Node.js 20+, npm 10+
cd frontend
cp .env.example .env         # defaults VITE_API_URL to http://localhost:8080
npm install
npm run dev
# → http://localhost:5173
```

The frontend is a React 18 + TypeScript 5 + Three.js single-page application. It consumes the backend REST API and renders interactive 3D visualizations of all 16 patches as Escher-style Poincaré projections — with the fundamental cell at the origin, per-cell conformal scaling `s(u) = (1 − |u|²)/2`, per-cell rotation quaternions extracted from the boosted hyperbolic frame, and a semi-transparent boundary shell enclosing the bulk graph. All cells (boundary + interior) and all physical bonds from `patchGraph` are rendered directly from the Agda-verified data; the frontend performs no mathematical computation of its own. See [`docs/engineering/frontend-spec-webgl.md`](engineering/frontend-spec-webgl.md) and [`frontend/README.md`](../frontend/README.md) for details.

### Regenerate Data (Optional)

```bash
# Prerequisites: Python 3.12, networkx, numpy
cd sim/prototyping
python3 18_export_json.py   # regenerates data/*.json from oracle outputs
# ~50 minutes total (Dense-1000 dominates)
```

The JSON export runs the full Coxeter + Lorentz-boost + SVD pipeline to produce centred Poincaré coordinates, unit rotation quaternions, and clamped conformal scale factors for every cell — the geometric data consumed by the WebGL frontend.

## Architecture

```
src/                          Cubical Agda formalization (verification layer)
├── Util/           — Scalars (ℚ≥0 = ℕ), Rationals (ℚ₁₀ = ℤ), NatLemmas
├── Common/         — Patch specifications (star, filled, dense, layer, honeycomb)
├── Boundary/       — Min-cut observables, subadditivity, area law, half-bound
├── Bulk/           — Chain observables, curvature, Gauss–Bonnet
├── Bridge/         — GenericBridge, SchematicTower, WickRotation, Dynamics,
│                   HalfBound, BridgeWitness, CoarseGrain
├── Causal/         — Event, CausalDiamond, NoCTC, LightCone
├── Gauge/          — FiniteGroup, Q₈, Connection, Holonomy, ConjugacyClass
└── Quantum/        — AmplitudeAlg, Superposition, QuantumBridge

sim/prototyping/              Python oracle pipeline (computation layer)
                              19 scripts generating Agda code + JSON data export
                              (script 18 applies the Lorentz-boost centring,
                              per-cell conformal scale, and SVD-based rotation
                              extraction for the frontend's Poincaré rendering)

data/                         Pre-computed JSON (served by the backend)
├── patches/        — 16 patch instance files, each with a full patchGraph
│                     (Poincaré coordinates, quaternions, conformal scales,
│                     physical bonds)
├── tower.json      — Resolution tower levels + monotonicity
├── theorems.json   — Theorem registry
├── curvature.json  — Gauss–Bonnet summaries
└── meta.json       — Version, build date, data hash

backend/                      Haskell REST API (serving layer)
├── src/            — Api.hs, Server.hs, Types.hs, DataLoader.hs, Invariants.hs
├── app/            — Main.hs (CLI, startup, Warp)
└── test/           — InvariantSpec.hs (property tests), ApiSpec.hs (integration)

frontend/                     React + Three.js SPA (visualization layer)
├── src/
│   ├── api/        — Typed fetch client for the 7 backend endpoints
│   ├── hooks/      — usePatch, usePatches, useTower, useTheorems, useMeta
│   ├── components/ — patches/ (3D scene, cells, bonds, wireframe, shell),
│   │                tower/, theorems/, home/, layout/, common/
│   ├── utils/      — Poincaré layout read-through, colour scales, tiling
│   └── types/      — TypeScript mirrors of the Haskell API types
└── tests/          — Vitest suites (api, types, hooks, components)

docs/                         Documentation
```

For the full module dependency DAG, see [`docs/getting-started/architecture.md`](getting-started/architecture.md).

## The Generic Bridge (The Core Innovation)

Every holographic bridge in this repository is an instance of a single
generic theorem (`Bridge/GenericBridge.agda`), parameterized by an
abstract `PatchData` interface. The Python oracle generates concrete
patches; the generic theorem handles the proof — once. Twelve patch
instances have been verified, spanning 1D trees, 2D pentagonal tilings,
and 3D cubic honeycombs. See [`docs/formal/11-generic-bridge.md`](formal/11-generic-bridge.md).

## The Discrete Bekenstein–Hawking Bound

The sharp bound S(A) ≤ area(A)/2 — identifying the discrete Newton's
constant as 1/(4G) = 1/2 in bond-dimension-1 units — is verified across
32,134 regions on 4 tilings ({4,3,5}, {5,4}, {4,4}, {5,3}), 4 growth
strategies, and 3 capacities. The bound is proven generically via the
`from-two-cuts` lemma and instantiated per-patch by `abstract` witnesses.
This eliminates the constructive-reals wall for the entropy-area
relationship. See [`docs/formal/12-bekenstein-hawking.md`](formal/12-bekenstein-hawking.md)
and [`docs/physics/discrete-bekenstein-hawking.md`](physics/discrete-bekenstein-hawking.md).

## What This Does NOT Prove

- That discrete structures converge to smooth geometry as N → ∞
- That finite gauge groups relate to continuous Lie groups
- That the causal poset approximates a Lorentzian metric
- That "transport along a Univalence path" has physical meaning

See [`docs/physics/translation-problem.md`](physics/translation-problem.md)
for the honest assessment of the gap between this discrete model and
our universe, and [`docs/physics/five-walls.md`](physics/five-walls.md) for
the hard boundaries of the formalization (now four — the constructive-reals
wall for entropy-area is bypassed).

## Documentation

```
docs/
├── CITATION.cff
│
├── getting-started/
│   ├── abstract.md                    # One-page summary of what is proven
│   ├── setup.md                       # Dev environment (Agda 2.8, cubical, Nix)
│   ├── building.md                    # How to type-check; module load order
│   └── architecture.md                # Module dependency DAG, layer diagram
│
├── formal/                            # Mathematical content
│   ├── 01-theorems.md                 # ★ Canonical theorem registry
│   ├── 02-foundations.md              # HoTT, Univalence, Cubical Agda
│   ├── 03-holographic-bridge.md       # RT: S=L, enriched equiv, ua
│   ├── 04-discrete-geometry.md        # Gauss–Bonnet, curvature
│   ├── 05-gauge-theory.md             # FiniteGroup, Q₈, holonomy
│   ├── 06-causal-structure.md         # Events, NoCTC, light cones
│   ├── 07-quantum-superposition.md    # AmplitudeAlg, quantum bridge
│   ├── 08-wick-rotation.md            # dS/AdS curvature-agnostic bridge
│   ├── 09-thermodynamics.md           # CoarseGrain, area law, tower
│   ├── 10-dynamics.md                 # Step invariance, dynamics loop
│   ├── 11-generic-bridge.md           # PatchData, OrbitReducedPatch
│   └── 12-bekenstein-hawking.md       # ★ HalfBound, 1/(4G) = 1/2
│
├── physics/                           # Physics interpretation
│   ├── translation-problem.md         # From discrete model to our universe
│   ├── holographic-dictionary.md      # Agda type ↔ physics table
│   ├── discrete-bekenstein-hawking.md # The sharp 1/2 bound
│   ├── three-hypotheses.md            # Emergent / phase transition / discrete
│   └── five-walls.md                  # Hard boundaries (now four)
│
├── engineering/                       # Proof engineering & tooling
│   ├── oracle-pipeline.md             # Python-to-Agda (scripts 01–18)
│   ├── orbit-reduction.md             # 717→8 orbits, scaling
│   ├── abstract-barrier.md            # The abstract keyword, Issue #4573
│   ├── generic-bridge-pattern.md      # PatchData → BridgeWitness
│   ├── scaling-report.md              # Region counts, parse/check times
│   ├── backend-spec-haskell.md        # ★ Haskell backend specification
│   └── frontend-spec-webgl.md         # ★ React + Three.js frontend specification
│
├── instances/                         # Per-patch data sheets
│   ├── tree-pilot.md                  # 7-vertex binary tree
│   ├── star-patch.md                  # 6-tile {5,4} star
│   ├── filled-patch.md                # 11-tile {5,4} disk
│   ├── honeycomb-3d.md                # {4,3,5} BFS star (32 cells)
│   ├── dense-50.md … dense-1000.md    # Dense patches with orbit reduction
│   ├── honeycomb-145.md               # {4,3,5} Dense intermediate (145 cells)
│   ├── layer-54-tower.md              # {5,4} BFS depths 2–7
│   └── desitter-patch.md              # {5,3} dodecahedron star
│
├── reference/
│   ├── assumptions.md                 # Frozen model assumptions
│   ├── glossary.md                    # Key terms
│   └── module-index.md                # Every src/ module with description
│
├── historical/                        # Development archive (verbatim)
│   └── development-docs/
│
└── papers/
    └── theory.tex                     # LaTeX paper draft
```

## Status

**Verification layer (Agda):** All 10 theorems machine-checked; 12 patch
instances bridged via the generic theorem; tower convergence certificate
for the Bekenstein–Hawking bound.

**Serving layer (Haskell backend):** Complete. Servant REST API with
type-level routing, CORS + Cache-Control middleware, startup-time
invariant validation over all 16 patches (half-bound, orbit consistency,
Gauss–Bonnet, graph structure, Poincaré geometry, quaternion unit norm,
conformal scale range), full property-based + integration test coverage.

**Visualization layer (WebGL frontend):** Complete. Interactive 3D scene
for every patch with the Lorentz-boost centring roadmap applied
(fundamental cell at origin, per-cell conformal scale, per-cell rotation
quaternion), `InstancedMesh` rendering above 500 cells, merged-buffer
boundary wireframe, origin-centred boundary shell, bond visibility via
`depthWrite: false`, four colour modes (min-cut / size / S·area⁻¹ /
curvature), Tower timeline with animated playback, Theorem dashboard,
8-step Dynamics demo. Full Vitest suite.

## Acknowledgements

While this repository is a solo-developed project, I want to express my gratitude
to Anthropic's Claude 4.6 Opus. Claude acted as an invaluable sounding board, pair-programmer,
and rubber duck throughout the mathematical groundwork and architectural design
phases. The realization of this project relied heavily on advanced prompt
engineering, which I orchestrated mostly through a tiny self-developed interface
based on `streamlit`, OpenRouterGUI (available at
`historical/tools/OpenRouterGUI.7z`).

## Citation

Please cite this repository as described in [`CITATION.cff`](CITATION.cff).

## License

MIT