## Summarized Proposed File Tree

```
docs/
├── README.md                          # Repository landing page (current, updated)
├── CITATION.cff
│
├── getting-started/
│   ├── abstract.md                    # One-page summary of what is proven (v0.4+)
│   ├── setup.md                       # Dev environment (Agda 2.8, cubical, Nix)
│   ├── building.md                    # How to type-check; module load order
│   └── architecture.md               # Module dependency DAG, layer diagram
│
├── formal/                            # Mathematical content (the "paper")
│   ├── 01-theorems.md                 # ★ Canonical theorem registry (ALL results)
│   ├── 02-foundations.md              # HoTT, Univalence, Cubical Agda background
│   ├── 03-holographic-bridge.md       # RT: S=L, enriched equiv, ua, GenericBridge
│   ├── 04-discrete-geometry.md        # Gauss–Bonnet, curvature, patch complexes
│   ├── 05-gauge-theory.md             # FiniteGroup, Q₈, connections, holonomy
│   ├── 06-causal-structure.md         # Events, causal diamonds, NoCTC, light cones
│   ├── 07-quantum-superposition.md    # AmplitudeAlg, Superposition, quantum bridge
│   ├── 08-wick-rotation.md            # dS/AdS, curvature-agnostic bridge
│   ├── 09-thermodynamics.md           # CoarseGrain, area law, resolution tower
│   ├── 10-dynamics.md                 # Step invariance, parameterized bridge, loop
│   ├── 11-generic-bridge.md           # PatchData, OrbitReducedPatch, SchematicTower
│   └── 12-bekenstein-hawking.md       # ★ HalfBound, from-two-cuts, 1/(4G) = 1/2
│
├── physics/                           # Theoretical physics interpretation
│   ├── translation-problem.md         # From HaPPY code to our universe (§15 core)
│   ├── holographic-dictionary.md      # Agda type ↔ physics counterpart table
│   ├── discrete-bekenstein-hawking.md # The sharp 1/2 bound and its significance
│   ├── three-hypotheses.md            # Thermodynamic illusion / phase transition / discreteness
│   └── five-walls.md                  # Hard boundaries (now four: reals wall bypassed)
│
├── engineering/                       # Proof engineering & CS contributions
│   ├── oracle-pipeline.md            # Python-to-Agda code generation (scripts 01–17)
│   ├── orbit-reduction.md            # Orbit reduction strategy (717→8, scaling)
│   ├── abstract-barrier.md           # The `abstract` keyword, Agda RAM, Issue #4573
│   ├── generic-bridge-pattern.md     # PatchData → BridgeWitness (one proof, N instances)
│   └── scaling-report.md             # Region counts, orbit counts, parse/check times
│
├── instances/                         # Per-patch data sheets
│   ├── tree-pilot.md                  # 7-vertex weighted binary tree
│   ├── star-patch.md                  # 6-tile {5,4} star (primary bridge target)
│   ├── filled-patch.md               # 11-tile {5,4} disk (Thm 1 + Thm 3)
│   ├── honeycomb-3d.md               # {4,3,5} BFS star (32 cells, first 3D instance)
│   ├── dense-50.md                    # Dense-50 (139 regions, min-cut 1–7)
│   ├── dense-100.md                   # Dense-100 (717→8 orbits, min-cut 1–8, half-bound)
│   ├── dense-200.md                   # Dense-200 (1246→9 orbits, min-cut 1–9, half-bound)
│   ├── layer-54-tower.md             # {5,4} BFS depths 2–7, tower structure
│   └── desitter-patch.md             # {5,3} dodecahedron star (positive curvature)
│
├── reference/
│   ├── bibliography.md               # All citations
│   ├── assumptions.md                # Frozen model assumptions (carried over)
│   ├── glossary.md                   # Key terms
│   └── module-index.md              # Every src/ module: one-line desc + doc link
│
├── historical/                       # Development archive (verbatim preservation)
│   └── development-docs/
│       ├── README.md
│       ├── 00-abstract.md … 10-frontier.md
│       ├── assumptions.md, dev-setup.md
│       ├── repo-close.md, repo-close_2.md
│       └── refactoring.md           # This document's predecessor (verbatim)
│
└── papers/
    ├── theory.tex                    # LaTeX paper draft
    └── figures/                      # Architecture diagrams, dependency DAGs
```

---

## Elaboration Content

### 1. Design Principles

1. **Audience-oriented splits**: `formal/` for mathematicians, `physics/` for physicists, `engineering/` for proof engineers, `instances/` for per-patch data sheets.
2. **The monolithic `10-frontier.md` is dissolved**: Its 18 sections become focused, self-contained documents distributed across `formal/`, `physics/`, and `engineering/`.
3. **Theorem registry**: `formal/01-theorems.md` is the canonical statement of everything machine-checked.
4. **Historical preservation**: The original sequential docs remain verbatim in `historical/development-docs/`.
5. **Cross-referencing**: Each `.agda` file header will reference new section numbers.

### 2. Updated Dissolution Table

| Old Location | New Location(s) | Rationale |
|---|---|---|
| `10-frontier.md` §1–4 (Directions A–B) | `formal/03-holographic-bridge.md`, `instances/filled-patch.md`, `instances/star-patch.md` | Completed work → formal statements + instance sheets |
| `10-frontier.md` §5 (Direction C) | `formal/11-generic-bridge.md`, `engineering/generic-bridge-pattern.md` | Generic bridge = math result + engineering pattern |
| `10-frontier.md` §6 (Direction D) | `formal/03-holographic-bridge.md` (3D section), `instances/honeycomb-3d.md`, `instances/dense-*.md` | 3D work → formal + instance sheets |
| `10-frontier.md` §7 (Direction E) | `formal/08-wick-rotation.md`, `instances/desitter-patch.md` | dS/AdS → formal result |
| `10-frontier.md` §8 (Thermodynamics) | `formal/09-thermodynamics.md`, `physics/three-hypotheses.md` | Formal (CoarseGrain, area law) separated from speculative |
| `10-frontier.md` §9 (Dynamics) | `formal/10-dynamics.md` | Completed step-invariance + loop |
| `10-frontier.md` §10 (Continuum limit) | `formal/09-thermodynamics.md` (tower part), `physics/discrete-bekenstein-hawking.md` | Formal tower vs. BH interpretation |
| `10-frontier.md` §11 (Local rewriting) | `formal/10-dynamics.md` | Completed step-invariance |
| `10-frontier.md` §12 (Causal) | `formal/06-causal-structure.md` | Completed Causal/ modules |
| `10-frontier.md` §13 (Gauge/Matter) | `formal/05-gauge-theory.md` | Completed Gauge/ modules |
| `10-frontier.md` §14 (Quantum) | `formal/07-quantum-superposition.md` | Completed Quantum/ modules |
| `10-frontier.md` §15.1–15.8 (Translation) | `physics/translation-problem.md`, `physics/holographic-dictionary.md`, `physics/three-hypotheses.md`, `physics/five-walls.md` | Speculative chapter broken into focused physics docs |
| `10-frontier.md` §15.9 (Entropic convergence) | `physics/discrete-bekenstein-hawking.md` | **Resolved**: the BH bound is now a theorem, not a conjecture |
| `10-frontier.md` §15.10 (BH proof) | `formal/12-bekenstein-hawking.md` | Completed formal result |
| `10-frontier.md` §15.11 (Phase A–E roadmap) | Split: formal → `formal/12-bekenstein-hawking.md`, engineering → `engineering/scaling-report.md` | Mixed content |
| `10-frontier.md` §15.12 (Finalization) | `formal/01-theorems.md` (summary), `physics/five-walls.md` (honest assessment) | Summary + boundary |
| `10-frontier.md` §16 (Crossing walls) | `physics/five-walls.md` | IN ELABORATION → now four walls |
| `10-frontier.md` §17 (Execution plan) | `getting-started/architecture.md` or new `engineering/extraction.md` | Haskell backend + WebGL |
| `00-abstract.md` | `getting-started/abstract.md` (rewritten), `historical/` (verbatim) | Rewritten for v0.4+; original preserved |
| `08-tree-instance.md`, `09-happy-instance.md` | `instances/tree-pilot.md`, `instances/star-patch.md`, `instances/filled-patch.md` + `historical/` | Instance data → per-patch sheets |
| `assumptions.md` | `reference/assumptions.md` | Relocated |
| `dev-setup.md` | `getting-started/setup.md` (reviewed) + `historical/` | Content is correct; minor updates |

### 3. Content Notes for Key New/Updated Documents

**`formal/01-theorems.md`** — The single most important document. Clean registry of every machine-checked result:

| # | Result | Module | Type Signature (sketch) |
|---|--------|--------|-------------------------|
| 1 | Discrete Gauss–Bonnet | `Bulk/GaussBonnet.agda` | `totalCurvature ≡ χ₁₀` |
| 2 | Subadditivity + Monotonicity | `Boundary/StarSubadditivity.agda`, `Bulk/StarMonotonicity.agda` | `S(A∪B) ≤ S(A)+S(B)`, `r₁⊆r₂ → L(r₁)≤L(r₂)` |
| 3 | Holographic Bridge (Generic) | `Bridge/GenericBridge.agda` | `transport (ua bridge) bdy ≡ bulk` |
| 4 | **Discrete Bekenstein–Hawking** | `Bridge/HalfBound.agda` | `(S r + S r) ≤ area r` with tight achiever |
| 5 | No Closed Timelike Curves | `Causal/NoCTC.agda` | `CausalChain e e' → CausalLink e' e → ⊥` |
| 6 | Discrete Wick Rotation | `Bridge/WickRotation.agda` | `WickRotationWitness` coherence record |
| 7 | Quantum Superposition Bridge | `Quantum/QuantumBridge.agda` | `𝔼 alg ψ S ≡ 𝔼 alg ψ L` |
| 8 | Matter as Topological Defects | `Gauge/Holonomy.agda` | `ParticleDefect` inhabited for Q₈ connection |

**`formal/12-bekenstein-hawking.md`** — NEW document covering:
- The `from-two-cuts` generic lemma and `two-le-sum` arithmetic
- The `HalfBoundWitness` record type
- Per-instance witnesses (Dense-100, Dense-200) via Python oracle
- Integration into `SchematicTower` §25 (`ConvergenceCertificate3L-HB`, `DiscreteBekensteinHawking`)
- The elimination of the constructive-reals wall: 1/(4G) = 1/2 by `refl`

**`physics/discrete-bekenstein-hawking.md`** — Replaces and sharpens the old `physics/entropic-convergence.md`:
- The Entropic Convergence **Conjecture** from §15.9.3 is **resolved** — it is now a **theorem**
- The discrete Newton's constant is exactly 1/2 in bond-dimension-1 units
- Verified across 32,134 regions on 4 tilings ({4,3,5}, {5,4}, {4,4}, {5,3}), 4 strategies, 3 capacities
- The `ConvergenceWitness` (which required constructive reals) is replaced by `HalfBoundWitness` (ℕ arithmetic + `refl`)

**`physics/five-walls.md`** — Updated from 5 walls to **4 walls**:
- Wall 1 (Constructive Reals) is **partially bypassed** for the entropy-area relationship
- Walls 2–5 remain: infinite path integrals, continuous gauge groups, Lorentzian signature, fermionic matter

**`engineering/oracle-pipeline.md`** — Updated to cover scripts 01–17:

| Scripts | Purpose |
|---------|---------|
| 01–02 | HaPPY patch cuts + curvature prototype |
| 03–04 | Filled patch + raw equiv Agda generation |
| 05–07 | {4,3,5} honeycomb: prototype, generator, multi-strategy |
| 08–09 | Dense-50 and Dense-100 Agda generation (orbit reduction) |
| 10 | de Sitter prototype |
| 11 | Area-law Agda generation |
| 12 | Dense-200 Agda generation |
| 13 | Layer-N {5,4} Agda generation |
| 14a–c | Entropic convergence analysis (adaptive → controlled → sup-half) |
| 15 | Discrete Bekenstein–Hawking proof characterization |
| 16 | Half-bound scaling confirmation (32,134 regions) |
| 17 | HalfBound Agda generation (Dense-100, Dense-200) |

**`instances/dense-100.md`** and **`instances/dense-200.md`** — Updated to carry **three** levels of entropy-area constraint:
1. RT correspondence: S = L (via GenericBridge)
2. Area law: S ≤ area (via Dense*AreaLaw)
3. **Half-bound: 2·S ≤ area** (via Dense*HalfBound, with tight achiever)

### 4. Recommended Elaboration Order

| Order | Target File | Source Material | Effort | Notes |
|-------|-------------|-----------------|--------|-------|
| 0 | **This document** (`docs/refactoring.md`) | Current state analysis | Done | This is the map |
| 1 | `formal/01-theorems.md` | All theorem statements | 1 day | **Most important.** Every result with type sig, module, one-sentence desc. Include BH bound as Theorem 4. |
| 2 | `getting-started/abstract.md` | Rewrite of `00-abstract.md` | 0.5 day | One-page summary for v0.4+ state |
| 3 | `getting-started/setup.md` | `dev-setup.md` | 0.5 day | Current content is accurate; minor updates |
| 4 | **Move** `historical/` verbatim | `00`–`10` + ancillary docs | 0.5 day | Preserves narrative, unblocks dissolution |
| 5 | `formal/12-bekenstein-hawking.md` | §15.10–15.11 of `10-frontier.md` | 1 day | NEW: the sharp half-bound theorem |
| 6 | `formal/03-holographic-bridge.md` | §3–4 of `10-frontier.md` | 1 day | Core RT bridge, all 12 instances |
| 7 | `formal/09-thermodynamics.md` | §8, §10, §15.10 | 1 day | CoarseGrain, area law, tower, BH integration |
| 8 | `physics/discrete-bekenstein-hawking.md` | §15.9 (sharpened) | 0.5 day | Conjecture → theorem |
| 9 | `physics/five-walls.md` | §15.6 of `10-frontier.md` | 0.5 day | Update: 5 walls → 4 walls |
| 10 | `engineering/oracle-pipeline.md` | Document scripts 01–17 | 1 day | Full pipeline including 14–17 |
| 11 | Remaining formal/, physics/, engineering/, instances/ | Remaining 10-frontier.md sections | 2–3 days | Everything else |
| 12 | `papers/theory.tex` update | Add BH bound section | 0.5 day | New §4.x or §5.x |
| 13 | `reference/module-index.md` | Enumerate all `src/` modules | 0.5 day | One-line description each |

### 5. What Remains Valid from the Original Proposal

- The audience-oriented top-level split (`formal/`, `physics/`, `engineering/`, `instances/`)
- The historical preservation strategy
- The module-index and glossary plans
- The cross-referencing strategy (Agda file headers → doc sections)
- The `papers/theory.tex` location

### 6. What Changed Since the Original Proposal

| Change | Impact |
|--------|--------|
| Discrete Bekenstein–Hawking bound proven | New `formal/12-bekenstein-hawking.md`; `physics/entropic-convergence.md` renamed to `physics/discrete-bekenstein-hawking.md` |
| Python scripts 14–17 added | `engineering/oracle-pipeline.md` must cover 17 scripts, not 13 |
| `Bridge/HalfBound.agda` + `Dense*HalfBound.agda` created | `instances/dense-100.md` and `dense-200.md` gain a third constraint level |
| `SchematicTower.agda` §25 added | `formal/11-generic-bridge.md` must document `ConvergenceCertificate3L-HB` and `DiscreteBekensteinHawking` |
| Constructive-reals wall partially bypassed | `physics/five-walls.md` drops from 5 to 4 active walls |
| `ConvergenceWitness` replaced by `HalfBoundWitness` | `formal/09-thermodynamics.md` and `physics/discrete-bekenstein-hawking.md` must reflect this substitution |
| §15.9.3 Entropic Convergence Conjecture resolved | No longer a conjecture; the document becomes a theorem statement |