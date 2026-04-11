# Univalence Gravity

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
| **Discrete Wick Rotation** | `Bridge/WickRotation.agda` | The holographic bridge is curvature-agnostic: same Agda term for AdS ({5,4}) and dS ({5,3}) |
| **No Closed Timelike Curves** | `Causal/NoCTC.agda` | Structural acyclicity from ℕ well-foundedness — the type system prevents time travel |
| **Discrete Bekenstein–Hawking** | `Bridge/HalfBound.agda` | S(A) ≤ area(A)/2 with 1/(4G) = 1/2 in bond-dimension-1 units |
| **Matter as Topological Defects** | `Gauge/Holonomy.agda` | Non-trivial Q₈ Wilson loops on the holographic network |
| **Quantum Superposition Bridge** | `Quantum/QuantumBridge.agda` | ⟨S⟩ = ⟨L⟩ for any finite superposition (5-line proof, amplitude-polymorphic) |

## Verification

```bash
# Prerequisites: Agda 2.8.0, agda/cubical library
# See docs/dev-setup.md for full setup instructions

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
├── Bridge/       — GenericBridge, SchematicTower, WickRotation, Dynamics
├── Causal/       — Event, CausalDiamond, NoCTC, LightCone
├── Gauge/        — FiniteGroup, Q₈, Connection, Holonomy, ConjugacyClass
└── Quantum/      — AmplitudeAlg, Superposition, QuantumBridge

sim/prototyping/  — 17 Python oracle scripts generating Agda code
docs/             — Mathematical documentation and development narrative
```

## The Generic Bridge (The Core Innovation)

Every holographic bridge in this repository is an instance of a single
generic theorem (`Bridge/GenericBridge.agda`), parameterized by an
abstract `PatchData` interface. The Python oracle generates concrete
patches; the generic theorem handles the proof — once.

## What This Does NOT Prove

- That discrete structures converge to smooth geometry as N → ∞
- That finite gauge groups relate to continuous Lie groups
- That the causal poset approximates a Lorentzian metric
- That "transport along a Univalence path" has physical meaning

See `docs/10-frontier.md` §15 for the honest assessment of the
translation problem between this discrete model and our universe.

## Future Work & Roadmap

This project is currently in version 0.4.0, and active development is split into three upcoming phases:

**Phase 1: Mathematical Groundwork (Current)**
* Generate `HalfBound` modules for 2D {5,4} patches (star, filled).
* Generate `HalfBound` for the {4,4} Euclidean grid.
* Prove the generic half-bound without relying on Python oracles.
* Revisit and resolve (at least one) of the 5 pillar proof boundaries.

**Phase 2: Documentation & Refactoring**
* Overhaul the `docs/` directory to align with the proposed structural refactoring in `docs/refactoring.md`.
* Expand and clean up inline comments across all `.agda` files.
* Restructure the core Agda files into distinct, logically separated directories.

**Phase 3: Tooling & Visualization**
* Develop a Haskell backend.
* Create a WebGL adapter for browser-based visualization of the holographic network.

## Acknowledgements

While this repository is a solo-developed project, I want to express my gratitude to Anthropic's Claude Opus 4.6. Claude acted as an invaluable sounding board, pair-programmer, and rubber duck throughout the mathematical groundwork and architectural design phases of this project.

## Citation

Please cite this repository as described in `CITATION.cff`.

## License

MIT