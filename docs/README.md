# Univalence Gravity v0.4.5

**A Constructive Formalization of Discrete Entanglement-Geometry Duality in Cubical Agda**

*By Sven Bichtemann* | Agda 2.8.0 | agda/cubical library | MIT License

## What This Is

A machine-checked proof that five pillars of a holographic universe
— geometry, causality, gauge matter, curvature, and quantum
superposition — coexist in a single formal artifact, verified by
the Cubical Agda type-checker via computational transport along
Univalence paths.

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

For the full theorem registry with type signatures and module cross-references, see [`formal/01-theorems.md`](formal/01-theorems.md).

## Verification

```bash
# Prerequisites: Agda 2.8.0, agda/cubical library
# See docs/getting-started/setup.md for full environment setup
# See docs/getting-started/building.md for module load order

# Type-check the core theorems:
agda src/Bridge/GenericBridge.agda
agda src/Bulk/GaussBonnet.agda
agda src/Bridge/WickRotation.agda
agda src/Causal/NoCTC.agda
agda src/Quantum/QuantumBridge.agda
agda src/Bridge/HalfBound.agda
```

## Architecture

```
src/
├── Util/         — Scalars (ℚ≥0 = ℕ), Rationals (ℚ₁₀ = ℤ), NatLemmas
├── Common/       — Patch specifications (star, filled, dense, layer)
├── Boundary/     — Min-cut observables, subadditivity, area law, half-bound
├── Bulk/         — Chain observables, curvature, Gauss–Bonnet
├── Bridge/       — GenericBridge, SchematicTower, WickRotation, Dynamics,
│                   HalfBound, BridgeWitness, CoarseGrain
├── Causal/       — Event, CausalDiamond, NoCTC, LightCone
├── Gauge/        — FiniteGroup, Q₈, Connection, Holonomy, ConjugacyClass
└── Quantum/      — AmplitudeAlg, Superposition, QuantumBridge

sim/prototyping/  — 17 Python oracle scripts generating Agda code
docs/             — Documentation (see below)
```

For the full module dependency DAG, see [`getting-started/architecture.md`](getting-started/architecture.md).

## The Generic Bridge (The Core Innovation)

Every holographic bridge in this repository is an instance of a single
generic theorem (`Bridge/GenericBridge.agda`), parameterized by an
abstract `PatchData` interface. The Python oracle generates concrete
patches; the generic theorem handles the proof — once. Twelve patch
instances have been verified, spanning 1D trees, 2D pentagonal tilings,
and 3D cubic honeycombs. See [`formal/11-generic-bridge.md`](formal/11-generic-bridge.md).

## The Discrete Bekenstein–Hawking Bound

The sharp bound S(A) ≤ area(A)/2 — identifying the discrete Newton's
constant as 1/(4G) = 1/2 in bond-dimension-1 units — is verified across
32,134 regions on 4 tilings ({4,3,5}, {5,4}, {4,4}, {5,3}), 4 growth
strategies, and 3 capacities. The bound is proven generically via the
`from-two-cuts` lemma and instantiated per-patch by `abstract` witnesses.
This eliminates the constructive-reals wall for the entropy-area
relationship. See [`formal/12-bekenstein-hawking.md`](formal/12-bekenstein-hawking.md)
and [`physics/discrete-bekenstein-hawking.md`](physics/discrete-bekenstein-hawking.md).

## What This Does NOT Prove

- That discrete structures converge to smooth geometry as N → ∞
- That finite gauge groups relate to continuous Lie groups
- That the causal poset approximates a Lorentzian metric
- That "transport along a Univalence path" has physical meaning

See [`physics/translation-problem.md`](physics/translation-problem.md)
for the honest assessment of the gap between this discrete model and
our universe, and [`physics/five-walls.md`](physics/five-walls.md) for
the hard boundaries of the formalization (now four — the constructive-reals
wall for entropy-area is bypassed).

## Documentation

```
docs/
├── README.md                          # This file
├── CITATION.cff
│
├── getting-started/
│   ├── abstract.md                    # One-page summary of what is proven
│   ├── setup.md                       # Dev environment (Agda 2.8, cubical, Nix)
│   ├── building.md                    # How to type-check; module load order
│   └── architecture.md               # Module dependency DAG, layer diagram
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
├── engineering/                       # Proof engineering
│   ├── oracle-pipeline.md             # Python-to-Agda (scripts 01–17)
│   ├── orbit-reduction.md             # 717→8 orbits, scaling
│   ├── abstract-barrier.md            # The abstract keyword, Issue #4573
│   ├── generic-bridge-pattern.md      # PatchData → BridgeWitness
│   └── scaling-report.md              # Region counts, parse/check times
│
├── instances/                         # Per-patch data sheets
│   ├── tree-pilot.md                  # 7-vertex binary tree
│   ├── star-patch.md                  # 6-tile {5,4} star
│   ├── filled-patch.md                # 11-tile {5,4} disk
│   ├── honeycomb-3d.md                # {4,3,5} BFS star (32 cells)
│   ├── dense-50.md … dense-200.md     # Dense patches with orbit reduction
│   ├── layer-54-tower.md              # {5,4} BFS depths 2–7
│   └── desitter-patch.md              # {5,3} dodecahedron star
│
├── reference/
│   ├── assumptions.md                 # Frozen model assumptions
│   ├── glossary.md                    # Key terms
│   └── module-index.md               # Every src/ module with description
│
├── historical/                        # Development archive (verbatim)
│   └── development-docs/
│
└── papers/
    └── theory.tex                     # LaTeX paper draft
```

## Future Work & Roadmap

This project is currently at version 0.4.0. Active development is split
into three phases:

**Phase 1: Mathematical Groundwork (Complete)**
* All core theorems mechanized (RT, Gauss–Bonnet, Bekenstein–Hawking)
* Generic bridge + orbit reduction architecture validated
* 12 patch instances verified across 2D and 3D
* Causal, gauge, and quantum layers integrated

**Phase 2: Documentation & Refactoring (Current)**
* Overhaul `docs/` into the audience-oriented structure above
* Expand inline comments across all `.agda` files
* Historical development docs preserved in `historical/`

**Phase 3: Tooling & Visualization**
* Develop a Haskell backend via `agda --compile --ghc`
* Create a WebGL adapter for browser-based visualization

## Acknowledgements

While this repository is a solo-developed project, I want to express my
gratitude to Anthropic's Claude Opus 4.6. Claude acted as an invaluable sounding
board, pair-programmer, and rubber duck throughout the mathematical
groundwork and architectural design phases of this project. I operated the AI assistance
only by using the self-developed program `OpenRouterGUI.7z`, that can also be used and found 
in `documents/historical/tools/OpenRouterGUI.7z`.

## Citation

Please cite this repository as described in [`CITATION.cff`](CITATION.cff).

## License

MIT