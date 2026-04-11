# Refactoring

After a thorough evaluation of the repository — its ~80 Agda modules, 13 Python oracles, and ~170-page `10-frontier.md` — here is a clean documentation architecture organized by audience and concern.

---

## Design Principles

1. **Audience-oriented top-level splits**: `formal/` for mathematicians, `physics/` for physicists, `engineering/` for CS/proof engineers, `instances/` for per-patch data sheets.
2. **The monolithic `10-frontier.md` is dissolved**: Its 17 sections become focused, self-contained documents distributed across `formal/`, `physics/`, and `engineering/`.
3. **Theorem registry**: A single `formal/theorems.md` serves as the canonical statement of everything machine-checked — the scientific "results section."
4. **Historical preservation**: The original sequential docs (`00`–`10`) are archived intact in `historical/`, preserving the development narrative for the GitHub historical record.
5. **Cross-referencing**: Each Agda file's header comments will reference the new section numbers (e.g., `-- Reference: docs/formal/04-gauge-theory.md §2`).

---

## Proposed File Tree

```
docs/
│
├── README.md                              # Repository landing page (rewritten)
│
├── getting-started/
│   ├── abstract.md                        # One-page summary of what is proven
│   ├── setup.md                           # Dev environment (Agda 2.8, cubical lib, Nix)
│   ├── building.md                        # How to type-check; module load order
│   └── architecture.md                    # Module dependency DAG, layer diagram
│
├── formal/                                # Mathematical content (the "paper")
│   ├── 01-theorems.md                     # ★ Canonical theorem registry (all results)
│   ├── 02-foundations.md                   # HoTT, Univalence, Cubical Agda background
│   ├── 03-holographic-bridge.md           # RT correspondence: S=L, enriched equiv, ua
│   ├── 04-discrete-geometry.md            # Gauss-Bonnet, curvature, patch complexes
│   ├── 05-gauge-theory.md                 # FiniteGroup, Q₈, connections, holonomy, defects
│   ├── 06-causal-structure.md             # Events, causal diamonds, NoCTC, light cones
│   ├── 07-quantum-superposition.md        # AmplitudeAlg, Superposition, quantum bridge
│   ├── 08-wick-rotation.md                # dS/AdS, curvature-agnostic bridge, WickRotationWitness
│   ├── 09-thermodynamics.md               # CoarseGrain, area law, resolution tower
│   ├── 10-dynamics.md                     # Step invariance, parameterized bridge, dynamics loop
│   └── 11-generic-bridge.md              # PatchData, OrbitReducedPatch, SchematicTower, BridgeWitness
│
├── physics/                               # Theoretical physics interpretation & speculation
│   ├── translation-problem.md             # From HaPPY code to our universe (§15 core)
│   ├── holographic-dictionary.md          # Agda type ↔ physics counterpart table
│   ├── entropic-convergence.md            # The entropy-first route to Einstein's equations
│   ├── three-hypotheses.md                # Thermodynamic illusion / phase transition / fundamental discreteness
│   └── five-walls.md                      # Hard boundaries: reals, path integrals, Lie groups, Lorentz, fermions
│
├── engineering/                           # Proof engineering & CS contributions
│   ├── oracle-pipeline.md                 # Python-to-Agda code generation (Approach A+C)
│   ├── orbit-reduction.md                 # The orbit reduction strategy (717→8, scaling analysis)
│   ├── abstract-barrier.md                # The `abstract` keyword, Agda RAM, Issue #4573
│   ├── generic-bridge-pattern.md          # Design pattern: PatchData → BridgeWitness (one proof, N instances)
│   └── scaling-report.md                  # Empirical: region counts, orbit counts, parse times, type-check times
│
├── instances/                             # Per-patch data sheets (numerical + formalization status)
│   ├── tree-pilot.md                      # 7-vertex weighted binary tree
│   ├── star-patch.md                      # 6-tile {5,4} star (primary bridge target)
│   ├── filled-patch.md                    # 11-tile {5,4} disk (Theorem 1 + Theorem 3)
│   ├── honeycomb-3d.md                    # {4,3,5} BFS star (32 cells, first 3D instance)
│   ├── dense-50.md                        # Dense-50 (139 regions, min-cut 1–7)
│   ├── dense-100.md                       # Dense-100 (717 regions → 8 orbits, min-cut 1–8)
│   ├── dense-200.md                       # Dense-200 (1246 regions → 9 orbits, min-cut 1–9)
│   ├── layer-54-tower.md                  # {5,4} BFS depths 2–7 (exponential boundary growth)
│   └── desitter-patch.md                  # {5,3} dodecahedron star (positive curvature, shared bridge)
│
├── reference/
│   ├── bibliography.md                    # All citations (Maldacena, RT, HaPPY, Regge, HoTT Book, etc.)
│   ├── assumptions.md                     # Frozen model assumptions (carried over)
│   ├── glossary.md                        # Key terms: min-cut, observable package, orbit reduction, etc.
│   └── module-index.md                    # Every src/ module: one-line description + upstream docs link
│
├── historical/                            # Development archive (preserved for the GitHub record)
│   ├── 00-abstract.md                     # Original abstract (verbatim)
│   ├── 01-introduction.md                 # Original introduction (verbatim)
│   ├── 02-foundations.md                   # Original foundations (verbatim)
│   ├── 03-architecture.md                 # Original architecture (verbatim)
│   ├── 04-tooling.md                      # Original tooling (verbatim)
│   ├── 05-roadmap.md                      # Original roadmap (verbatim)
│   ├── 06-challenges.md                   # Original challenges (verbatim)
│   ├── 07-references.md                   # Original references (verbatim)
│   ├── 08-tree-instance.md                # Original tree specification (verbatim)
│   ├── 09-happy-instance.md               # Original HaPPY specification (verbatim)
│   ├── 10-frontier.md                     # Original frontier document (verbatim, the monolith)
│   ├── dev-setup.md                       # Original dev-setup (verbatim)
│   ├── repo-close.md                      # Architectural rewiring analysis (verbatim)
│   └── development-narrative.md           # NEW: chronological account of how the repo evolved
│
└── papers/
    ├── theory.tex                         # LaTeX paper draft (carried over)
    └── figures/                           # Architecture diagrams, dependency DAGs
```

---

## Key Refactoring Decisions

| Old Location | New Location(s) | Rationale |
|---|---|---|
| `10-frontier.md` §1–4 (Directions A–B) | `formal/03-holographic-bridge.md`, `instances/filled-patch.md`, `instances/star-patch.md` | Completed work belongs in formal statements and instance data sheets |
| `10-frontier.md` §5 (Direction C) | `formal/11-generic-bridge.md`, `engineering/generic-bridge-pattern.md` | Generic bridge is both a mathematical result and an engineering pattern |
| `10-frontier.md` §6 (Direction D) | `formal/03-holographic-bridge.md` (3D section), `instances/honeycomb-3d.md`, `instances/dense-*.md` | Completed 3D work is a formal result; per-patch data goes to instance sheets |
| `10-frontier.md` §7 (Direction E) | `formal/08-wick-rotation.md`, `instances/desitter-patch.md` | Completed dS/AdS work is a formal result |
| `10-frontier.md` §8 (Thermodynamics) | `formal/09-thermodynamics.md`, `physics/three-hypotheses.md` | Formal part (CoarseGrain, area law) separated from speculative part |
| `10-frontier.md` §9 (Dynamics) | `formal/10-dynamics.md` | Completed dynamics formalization |
| `10-frontier.md` §10 (Continuum limit) | `formal/09-thermodynamics.md` (resolution tower part), `physics/entropic-convergence.md` | Formal tower structure vs. speculative limit |
| `10-frontier.md` §11 (Local rewriting) | `formal/10-dynamics.md` | Completed step-invariance + loop |
| `10-frontier.md` §12 (Causal) | `formal/06-causal-structure.md` | Completed Causal/ modules |
| `10-frontier.md` §13 (Gauge/Matter) | `formal/05-gauge-theory.md` | Completed Gauge/ modules |
| `10-frontier.md` §14 (Quantum) | `formal/07-quantum-superposition.md` | Completed Quantum/ modules |
| `10-frontier.md` §15 (Translation) | `physics/translation-problem.md`, `physics/holographic-dictionary.md`, `physics/entropic-convergence.md`, `physics/three-hypotheses.md`, `physics/five-walls.md` | The speculative concluding chapter is broken into focused physics documents |
| `00-abstract.md` | `getting-started/abstract.md` (rewritten), `historical/00-abstract.md` (verbatim) | Rewritten for current state; original preserved |
| `08-tree-instance.md`, `09-happy-instance.md` | `instances/tree-pilot.md`, `instances/star-patch.md`, `instances/filled-patch.md` + `historical/` (verbatim) | Instance data normalized to per-patch sheets; originals preserved |
| `assumptions.md` | `reference/assumptions.md` | Unchanged, just relocated |
| `dev-setup.md` | `getting-started/setup.md` (rewritten) + `historical/dev-setup.md` | The current dev-setup has the wrong content (it's a copy of 01-introduction); needs rewrite |

---

## Content Notes for Key New Documents

**`formal/01-theorems.md`** — The single most important document. A clean registry of every machine-checked result: Theorem 1 (Gauss-Bonnet), Theorem 2 (subadditivity/monotonicity), Theorem 3 (enriched bridge + transport), NoCTC, area law, quantum bridge, Wick rotation coherence, etc. Each entry: precise type signature, module location, one-sentence description.

**`physics/holographic-dictionary.md`** — The translation table from §15.3 as a standalone reference document (Agda type → physics counterpart → confidence → gap).

**`physics/entropic-convergence.md`** — The §15.9 "entropy-first route" as a standalone conjecture document with the empirical η_N data.

**`engineering/oracle-pipeline.md`** — Documents the 13 Python scripts, their dependency chain, what each emits, and the reproducibility setup (Nix shell, requirements.txt).

**`reference/module-index.md`** — A flat table of every `src/` module with: path, one-line description, upstream doc reference, auto-generated flag. This is what Agda file comments will cross-reference.

**`historical/development-narrative.md`** — A new document that tells the chronological story: "We started with the tree pilot, then scaled to the star, then hit the RAM wall at 360 cases, then invented the orbit reduction strategy..." — turning the GitHub commit history into a readable narrative.