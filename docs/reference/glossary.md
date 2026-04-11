# Glossary

**Key terms, definitions, and cross-references for the Univalence Gravity repository.**

**Audience:** All readers — mathematicians, physicists, proof engineers, and newcomers seeking quick definitions of specialized terms used throughout the documentation and source code.

**Organization:** Alphabetical. Each entry records the term, a concise definition, the primary context (HoTT/Agda, Physics, Engineering, or Project-specific), and cross-references to the documentation or source modules where the term is used most heavily.

---

## A

**`abstract` (Agda keyword)**
: An Agda pragma that seals a definition's body after type-checking, preventing downstream modules from unfolding it during normalization. Used in this repository to wrap large propositional proofs (area law, half-bound) behind a black box, halting the RAM cascade documented in [Agda Issue #4573](https://github.com/agda/agda/issues/4573). Safe for propositional types because any two inhabitants are equal. See [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md).

**AdS (Anti-de Sitter)**
: A spacetime with negative cosmological constant (Λ < 0). In the discrete model, the {5,4} pentagonal tiling serves as the AdS-like regime, with negative interior curvature κ = −1/5. Contrasted with dS (de Sitter). See [`formal/08-wick-rotation.md`](../formal/08-wick-rotation.md).

**AmplitudeAlg**
: A Cubical Agda record (`Quantum/AmplitudeAlg.agda`) providing the minimal interface for quantum amplitudes: a carrier type A, addition `_+A_`, scaling `_·A_`, zero `0A`, and an ℕ-embedding `embedℕ`. Contains zero ring axioms — the quantum bridge proof uses only `cong` and `cong₂`. Instances: ℕAmplitude (classical), ℤiAmplitude (Gaussian integers). See [`formal/07-quantum-superposition.md`](../formal/07-quantum-superposition.md).

**Area law**
: The discrete isoperimetric inequality S(A) ≤ area(A), where S is the min-cut entropy and area is the boundary surface area (face-count) of a cell-aligned region. A graph-theoretic tautology: the max-flow is bounded by the capacity of any cut. Verified for Dense-100 (717 cases) and Dense-200 (1246 cases) in `Boundary/Dense*AreaLaw.agda`. Subsumed by the sharp half-bound. See [`formal/09-thermodynamics.md`](../formal/09-thermodynamics.md).

## B

**Bekenstein–Hawking bound (discrete)**
: The sharp bound S(A) ≤ area(A)/2 for all cell-aligned boundary regions, with equality achieved. Identifies the discrete Newton's constant as 1/(4G) = 1/2 in bond-dimension-1 units. **Theorem 3** of the repository. See [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md), [`physics/discrete-bekenstein-hawking.md`](../physics/discrete-bekenstein-hawking.md).

**Bond**
: A shared edge (2D) or shared face (3D) between two adjacent tiles/cells in a holographic patch. Each bond carries a scalar capacity (default: 1) representing one unit of entanglement. In the Agda source, the `Bond` type is a finite data type with one constructor per internal connection (e.g., `bCN0` through `bCN4` for the 6-tile star). See `Common/StarSpec.agda`.

**BridgeWitness**
: A Cubical Agda record (`Bridge/BridgeWitness.agda`) packaging the complete holographic bridge: two enriched types (`BdyTy`, `BulkTy`), their canonical inhabitants, the type equivalence between them, and a verified transport proof. The Milestones 3–4 deliverable. See [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md).

**Bulk**
: The interior of the holographic patch — the discrete analogue of the bulk spacetime in AdS/CFT. In the repository, the `Bulk/` directory contains chain-length observables (`L-min`), curvature data, and Gauss–Bonnet proofs. Contrasted with Boundary. See [`getting-started/architecture.md`](../getting-started/architecture.md).

## C

**Causal chain**
: A finite composable sequence of `CausalLink`s in the discrete causal poset, connecting two events. The length of the chain is the proper time between endpoints. Defined in `Causal/Event.agda`. See [`formal/06-causal-structure.md`](../formal/06-causal-structure.md).

**Causal diamond**
: A finite causal interval — a non-empty sequence of verified spatial slices (`TowerLevel` records) connected by future-directed `LayerStep` monotonicity witnesses. Defined in `Causal/CausalDiamond.agda`. See [`formal/06-causal-structure.md`](../formal/06-causal-structure.md).

**CausalLink**
: A single future-directed step in the discrete causal poset, connecting two events separated by exactly one time step. The `time-suc` field enforces `suc(time e₁) ≡ time e₂` by construction, making CTC-freedom a structural property. Defined in `Causal/Event.agda`.

**Classify (function)**
: A surjection from the full region type to the small orbit type, grouping regions by min-cut value. E.g., `classify100 : D100Region → D100OrbitRep` (717 → 8). The observable functions are defined on the orbit type and composed with the classification, reducing proof obligations. See [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md).

**Coarse-graining**
: The thermodynamic process of replacing fine-grained microscopic data with macroscopic summaries. In the repository, the orbit reduction (717 → 8 regions) is formalized as a `CoarseGrainWitness` in `Bridge/CoarseGrain.agda`, demonstrating that the entropy observable is preserved under lossy compression. See [`formal/09-thermodynamics.md`](../formal/09-thermodynamics.md).

**`cong` / `cong₂`**
: Cubical Agda primitives for path congruence. `cong f p` pushes a path `p : a ≡ b` through a function `f`, producing `f a ≡ f b`. `cong₂ f p q` works for binary functions. The quantum bridge theorem uses only `refl`, `cong`, and `cong₂`. See [`formal/02-foundations.md`](../formal/02-foundations.md).

**Conjugacy class**
: The equivalence class of a group element under conjugation: [g] = {k⁻¹ · g · k | k ∈ G}. Determines the gauge-invariant particle species. Q₈ has 5 classes: {1}, {−1}, {±i}, {±j}, {±k}. See `Gauge/ConjugacyClass.agda`, [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md).

**Constructive-reals wall**
: The obstacle that the cubical library's `Cubical.HITs.Reals` provides no completeness, convergence, or integration — preventing formalization of smooth manifolds or the continuum Bekenstein–Hawking formula. **Partially bypassed** by the sharp half-bound, which identifies 1/(4G) = 1/2 as an exact rational, not a real-valued limit. See [`physics/five-walls.md`](../physics/five-walls.md).

**Contractible (type)**
: A type with exactly one inhabitant up to paths (h-level −2). Both enriched types `EnrichedBdy` and `EnrichedBulk` are contractible (reversed singletons), which is exploited in the generic bridge proof to close the transport step. See [`formal/02-foundations.md`](../formal/02-foundations.md).

**Cubical Agda**
: An implementation of Cubical Type Theory in the Agda proof assistant, where paths are functions from the abstract interval, `funExt` is a theorem, and Univalence (`ua`) computes via Glue types. The repository uses Agda 2.8.0 with the `agda/cubical` library (April 2026). See [`formal/02-foundations.md`](../formal/02-foundations.md).

## D

**Dense (growth strategy)**
: A greedy max-connectivity patch growth strategy: at each step, add the frontier cell with the most existing neighbors. Produces compact, multiply-connected patches with non-trivial min-cut values (up to 9 at 200 cells), unlike BFS-shell growth. The correct strategy for testing the entropy-area relationship. See [`engineering/oracle-pipeline.md`](../engineering/oracle-pipeline.md).

**De Sitter (dS)**
: A spacetime with positive cosmological constant (Λ > 0). In the discrete model, the {5,3} pentagonal tiling serves as the dS-like regime, with positive interior curvature κ = +1/10. See [`instances/desitter-patch.md`](../instances/desitter-patch.md).

**Dimension functor**
: The function `dim : Rep G → ℕ` extracting the dimension of an irreducible representation. For Q₈, `dim(q8-fund) = 2`. This converts gauge-theoretic structure to scalar bond capacities, feeding into the `PatchData` interface. See `Gauge/RepCapacity.agda`.

**Discrete Ryu–Takayanagi (RT)**
: The formula S_cut(A) = L_min(A): boundary min-cut entropy equals bulk minimal separating surface area on every boundary region. **Theorem 1** of the repository. See [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md).

## E

**Enriched type**
: A reversed singleton type `Σ[ f ∈ (R → ℚ≥0) ] (f ≡ S∂)` pairing an observable function with a proof that it matches a specific physical specification. Contractible, but genuinely distinct from the corresponding bulk enriched type in the universe. The equivalence between enriched types carries the RT correspondence through the Glue type. See [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md).

**Euler characteristic (χ)**
: The topological invariant V − E + F for a polygon complex. For every formalized disk patch: χ = 1. Stated additively in Agda as V + F ≡ E + 1 (since ℕ has no subtraction). Target of the Gauss–Bonnet theorem.

**Event**
: A spacetime atom in the discrete causal poset: a pair of a time index (ℕ) and a spatial cell at that time. Defined as a dependent record in `Causal/Event.agda`. See [`formal/06-causal-structure.md`](../formal/06-causal-structure.md).

## F

**Five walls**
: Five independent obstacles between the discrete formalization and continuum physics: (1) constructive reals (partially bypassed), (2) infinite path integrals, (3) continuous gauge groups, (4) Lorentzian signature, (5) fermionic matter. See [`physics/five-walls.md`](../physics/five-walls.md).

**Flow graph**
: A directed graph used for max-flow/min-cut computation. Tiles/cells are internal nodes, boundary pseudo-nodes represent exposed faces/legs. Internal bonds and boundary legs are bidirectional edges with capacity 1. The min-cut of this graph gives the boundary entanglement entropy S(A).

**`from-two-cuts`**
: The generic lemma in `Bridge/HalfBound.agda` that derives the half-bound from the area decomposition: given `area r ≡ n_cross r + n_bdy r` and two independent cut bounds `S r ≤ n_cross r` and `S r ≤ n_bdy r`, conclude `(S r + S r) ≤ area r`. See [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md).

**`funExt` (function extensionality)**
: In Cubical Agda, a theorem (not an axiom): if `h x : f x ≡ g x` for all `x`, then `funExt h : f ≡ g`. Implemented as `funExt h i x = h x i`. Used to assemble pointwise `refl` proofs into function-level paths (`obs-path`). See [`formal/02-foundations.md`](../formal/02-foundations.md).

## G

**Gauge connection**
: An assignment of group elements to bonds: `ω : Bond → G.Carrier`. In lattice gauge theory, determines parallel transport. The convention `g_ē = inv(g_e)` for reversed bonds is enforced by `readBond`. See `Gauge/Connection.agda`, [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md).

**Gauss–Bonnet (discrete)**
: The theorem Σ κ(v) = χ(K) = 1 for the combinatorial curvature on a disk-topology polygon complex. **Theorem 2** of the repository, discharged by `refl` in `Bulk/GaussBonnet.agda`. See [`formal/04-discrete-geometry.md`](../formal/04-discrete-geometry.md).

**`GaugedPatchWitness`**
: A record in `Gauge/RepCapacity.agda` packaging a `BridgeWitness` (capacity-weighted), a `GaugeConnection`, and a `ParticleDefect` into a single artifact — the first machine-checked holographic spacetime with matter.

**`GenericEnriched`**
: The parameterized Agda module in `Bridge/GenericBridge.agda` that proves the full enriched type equivalence + Univalence path + verified transport for **any** `PatchData`. Written once, proven once, never modified. The core architectural innovation. See [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md).

**Geometric blindness**
: The structural property that the holographic bridge depends only on four inputs (a region type, two observable functions, and a path between them) — never inspecting curvature, dimension, gauge groups, or tiling geometry. Explains why the Wick rotation, 3D extension, and gauge enrichment all work. See [`physics/translation-problem.md`](../physics/translation-problem.md).

## H

**h-level**
: The homotopy level (truncation level) of a type in HoTT. h-level −2 = contractible, −1 = proposition (`isProp`), 0 = set (`isSet`), 1 = groupoid. All scalar types (ℕ, ℤ), finite data types, and function spaces into sets are sets. The ordering `_≤ℚ_` is propositional. See [`formal/02-foundations.md`](../formal/02-foundations.md).

**Half-bound**
: The sharp entropy-area inequality 2·S(A) ≤ area(A), equivalently S(A) ≤ area(A)/2. Proven generically in `Bridge/HalfBound.agda` via the two-cut decomposition, and instantiated per-patch by `abstract` witnesses. See [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md).

**`HalfBoundWitness`**
: A record in `Bridge/HalfBound.agda` packaging the area function, the abstract half-bound proof, and a tight achiever where 2·S = area. The per-instance deliverable that replaces the `ConvergenceWitness` (which required constructive reals).

**HaPPY code**
: The holographic quantum error-correcting code by Pastawski, Yoshida, Harlow, and Preskill (2015). The repository's discrete model is based on the combinatorial and graph-theoretic content of this code, abstracted from its quantum-information theoretic setting.

**Holonomy**
: The Wilson loop — the ordered group product of gauge connection values around a face boundary: `holonomy ω ∂f = fold (_·_) ε (map (readBond ω) ∂f)`. Computed in `Gauge/Holonomy.agda`. See [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md).

## I

**`isProp` (propositional)**
: A type where any two inhabitants are equal. The ordering `_≤ℚ_` is propositional (by `isProp≤ℚ`), which makes the `abstract` barrier safe for inequality proofs. See [`formal/02-foundations.md`](../formal/02-foundations.md).

**`isSet`**
: A type where path spaces are propositional. All scalar types (`ℚ≥0 = ℕ`, `ℚ₁₀ = ℤ`), finite data types, and function spaces `Region → ℚ≥0` are sets. This is the h-level discipline enabling round-trip homotopies in the enriched bridge.

## J

**Judgmental equality**
: An equality that holds by computation, before any proof term is constructed — the type-checker reduces both sides to the same normal form. All pointwise agreement proofs in the repository are `refl` because both observables return canonical ℕ constants from `Util/Scalars.agda` with identical normal forms.

## L

**`LayerStep`**
: A record in `Bridge/SchematicTower.agda` witnessing monotonicity between two consecutive tower levels: `monotone : maxCut lo ≤ℚ maxCut hi`. Each witness is `(k , refl)` on closed ℕ terms.

**L-min (bulk minimal chain)**
: The bulk observable: the total weight of the minimal set of bonds/faces whose removal disconnects a boundary region from its complement. The 2D/3D discrete analogue of the Ryu–Takayanagi minimal surface area. Defined as specification-level lookup tables in `Bulk/*Chain.agda`.

## M

**Maximin**
: The covariant holographic entanglement entropy construction (Wall 2012): maximize the min-cut over all spatial slices. Defined in `Causal/CausalDiamond.agda` as a fold of `max-ℕ` over tower levels. See [`formal/06-causal-structure.md`](../formal/06-causal-structure.md).

**Min-cut**
: The minimum total capacity of edges whose removal disconnects a source set from a sink set in a flow network. Computed via max-flow (NetworkX) in the Python oracle, and verified as `(k , refl)` witnesses in Agda. Equals the boundary entanglement entropy S(A) under perfect-tensor assumptions.

**Monotonicity (bulk)**
: The property that enlarging a boundary region does not decrease its bulk minimal chain length: r₁ ⊆ r₂ → L(r₁) ≤ L(r₂). Proven for the 6-tile star in `Bulk/StarMonotonicity.agda`.

## N

**Newton's constant (discrete)**
: The discrete analogue of the physical Newton's constant G_N, identified as 1/(4G) = 1/2 in bond-dimension-1 units. An exact rational verified by `refl`, not a real-valued limit.

**NoCTC (No Closed Timelike Curves)**
: **Theorem 5**: structural acyclicity of the stratified causal poset, proven by composing `chain-step-<` (multi-step strict ordering) with `<ℕ-irrefl` (irreflexivity of ℕ). One line of proof. See `Causal/NoCTC.agda`, [`formal/06-causal-structure.md`](../formal/06-causal-structure.md).

## O

**Observable package (`ObsPackage`)**
: A single-field record wrapping `obs : R → ℚ≥0` — the minimal interface for boundary or bulk observable functions. Defined in `Common/ObsPackage.agda`.

**`obs-path`**
: The function-level path `S∂ ≡ LB` connecting boundary and bulk observables. Constructed by `funExt` of pointwise `refl` proofs. This IS the discrete RT correspondence packaged as a single path. See [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md).

**Oracle (Python)**
: External Python scripts (17 in `sim/prototyping/`) that enumerate combinatorial cases, compute min-cut values via max-flow, classify orbits, and emit Agda modules with explicit `(k , refl)` witnesses. Agda is the checker; Python is the search engine. See [`engineering/oracle-pipeline.md`](../engineering/oracle-pipeline.md).

**Orbit reduction**
: The strategy of classifying regions by min-cut value into a small orbit type, then defining observables on the orbit type and lifting proofs via a 1-line composition through the classification function. Reduces proof cases from 717 to 8 (Dense-100) or from 1885 to 2 ({5,4} depth-7). See [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md).

**`OrbitReducedPatch`**
: A record in `Bridge/GenericBridge.agda` capturing the orbit reduction pattern: `RegionTy`, `OrbitTy`, `classify`, `S-rep`, `L-rep`, `rep-agree`. Automatically converts to `PatchData` via `orbit-to-patch`.

## P

**`ParticleDefect`**
: A type in `Gauge/Holonomy.agda` asserting that a holonomy is NOT the identity: `holonomy ω ∂f ≡ ε → ⊥`. Matter as a topological excitation in the gauge field. **Theorem 6**. See [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md).

**`PatchData`**
: The minimal abstract interface for any holographic patch, defined in `Bridge/GenericBridge.agda`: `RegionTy : Type₀`, `S∂ LB : RegionTy → ℚ≥0`, `obs-path : S∂ ≡ LB`. Four fields — nothing about geometry. See [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md).

**`PathP` (dependent path)**
: The Cubical Agda primitive for paths. `PathP (λ i → A i) a b` is a function `p : I → A` with `p i0 ≡ a` and `p i1 ≡ b` judgmentally. When `A` is constant, simplifies to `a ≡ b`.

**Proper time**
: The number of `CausalLink` steps in a `CausalChain` or the number of `extend` constructors in a `CausalDiamond`. In the stratified tower, equals the time difference between endpoints.

## Q

**Q₈ (quaternion group)**
: The 8-element non-abelian group with constructors `q1 qn1 qi qni qj qnj qk qnk`, representing {1, −1, i, −i, j, −j, k, −k}. The finite replacement for SU(2). 400-case associativity verified by `refl`. 5 conjugacy classes → 4 particle species. See `Gauge/Q8.agda`, [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md).

**ℚ≥0 (nonneg scalars)**
: The scalar type for observables, implemented as bare natural numbers: `ℚ≥0 = ℕ` in `Util/Scalars.agda`. Addition `_+ℚ_ = _+_` computes judgmentally. The ordering `m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)` admits `(k , refl)` witnesses.

**ℚ₁₀ (signed rational tenths)**
: The curvature scalar type, implemented as `ℚ₁₀ = ℤ` in `Util/Rationals.agda`, where integer `n` represents `n/10`. All {5,4} and {5,3} curvature values have denominators dividing 10. Enables `refl`-based Gauss–Bonnet proofs.

**Quantum bridge**
: **Theorem 7**: `𝔼[ψ, S] ≡ 𝔼[ψ, L]` for any finite superposition ψ, any amplitude algebra A, given pointwise microstate agreement. A 5-line proof by structural induction on a list, using only `refl`, `cong`, and `cong₂`. See `Quantum/QuantumBridge.agda`, [`formal/07-quantum-superposition.md`](../formal/07-quantum-superposition.md).

## R

**`refl`**
: The constant path `λ i → a : a ≡ a`. Every pointwise agreement proof in the repository is `refl` because both sides reduce to the same ℕ literal via the shared-constants discipline.

**Region**
: A contiguous, cell-aligned boundary subset of a holographic patch. Defined as finite data types with one constructor per region (e.g., `D100Region` with 717 constructors). The domain of the observable functions `S∂` and `LB`.

**Resolution tower**
: A sequence of verified patches at increasing resolution, connected by monotonicity witnesses. The Dense tower: Dense-50 (max S = 7) → Dense-100 (max S = 8) → Dense-200 (max S = 9). The {5,4} layer tower: 6 levels at BFS depths 2–7. See [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md).

**Ryu–Takayanagi formula**
: In continuum AdS/CFT: S(A) = Area(γ_A) / 4G_N. The discrete analogue formalized here: S_cut(A) = L_min(A). See **Discrete Ryu–Takayanagi** above.

## S

**S-cut (boundary min-cut)**
: The boundary observable: the minimum total capacity of bonds/faces that must be severed to disconnect a boundary region from its complement. Defined as specification-level lookup tables in `Boundary/*Cut.agda`.

**`SchematicTower`**
: The module `Bridge/SchematicTower.agda` assembling verified patches into resolution towers, carrying `TowerLevel`s, `LayerStep`s, monotonicity witnesses, area-law and half-bound levels, and the `DiscreteBekensteinHawking` capstone type. The heaviest module in the repository.

**Schläfli symbol {p, q}**
: Notation for a tiling by regular p-gons with q meeting at each vertex. {5,4}: hyperbolic pentagons (negative curvature). {5,3}: spherical pentagons (positive curvature). {4,3,5}: hyperbolic cubes in 3-space (5 cubes per edge). {4,4}: Euclidean squares (flat).

**Shared-constants discipline**
: The architectural invariant that all scalar constants (`1q`, `2q`, `neg1/5`, etc.) are defined **once** in utility modules (`Util/Scalars.agda`, `Util/Rationals.agda`) and imported everywhere. This guarantees identical normal forms on both sides of every `refl`-based proof.

**Spacelike separation**
: Two events are spacelike-separated if there is no positive-length causal chain connecting them in either direction. In the stratified tower, events at the same time are automatically spacelike-separated (`same-time-spacelike` in `Causal/LightCone.agda`).

**Subadditivity**
: The boundary property S(A∪B) ≤ S(A) + S(B). Proven for the 6-tile star (30 cases in `Boundary/StarSubadditivity.agda`) and the 11-tile filled patch (360 `abstract` cases in `Boundary/FilledSubadditivity.agda`).

**Superposition**
: A finite list of (configuration, amplitude) pairs: `List (Config × A)`. The domain of the expected-value functional `𝔼`. Defined in `Quantum/Superposition.agda`.

## T

**`TowerLevel`**
: A record in `Bridge/SchematicTower.agda` bundling an `OrbitReducedPatch`, a `maxCut` value (holographic depth), and a `BridgeWitness`. Constructed by `mkTowerLevel`, which calls `orbit-bridge-witness` internally.

**Transport**
: Given `P : A → Type` and `p : a ≡ b`, `transport P p : P a → P b` — moving data along an equality. In Cubical Agda, transport is computational: `uaβ` reduces `transport (ua e) x` to `equivFun e x`. See [`formal/02-foundations.md`](../formal/02-foundations.md).

**`two-le-sum`**
: The arithmetic lemma in `Bridge/HalfBound.agda`: given `s ≤ a` and `s ≤ b`, derive `(s + s) ≤ (a + b)`. The core of the half-bound proof, composing two independent ≤ witnesses using `+-assoc` and `+-comm`.

## U

**`ua` (Univalence axiom)**
: In Cubical Agda, a function `ua : A ≃ B → A ≡ B` converting type equivalences to paths in the universe. Implemented via Glue types with a computation rule: `uaβ(e, a) : transport(ua e) a ≡ equivFun e a`. See [`formal/02-foundations.md`](../formal/02-foundations.md).

**`uaβ` (ua computation rule)**
: Transport along a `ua` path is the forward map of the equivalence. This is what makes the holographic bridge operational: transport computes, producing the bulk observable from the boundary observable.

**Univalence**
: The principle that equivalent types are identical: `(A ≃ B) ≃ (A ≡ B)`. In practice, once the equivalence between enriched boundary and bulk types is constructed, every property of one transfers to the other by transport. See [`formal/02-foundations.md`](../formal/02-foundations.md).

## V

**Vertex class (`VClass`)**
: A classification of vertices in the polygon complex by combinatorial neighbourhood. The {5,4} filled patch has 5 classes (30 vertices → 5 classes); the {5,3} star has 3 classes (15 vertices → 3 classes). Curvature is constant within each class. See `Bulk/PatchComplex.agda`.

## W

**Wick rotation (discrete)**
: The curvature-agnostic bridge: the same Agda term serves both AdS-like ({5,4}, κ < 0) and dS-like ({5,3}, κ > 0) geometries. A parameter change in the tiling type (q = 4 → q = 3), not a complex multiplication. **Theorem 4**. See `Bridge/WickRotation.agda`, [`formal/08-wick-rotation.md`](../formal/08-wick-rotation.md).

**Wilson loop**
: See **Holonomy**.

## Z

**ℤ[i] (Gaussian integers)**
: The ring of complex numbers with integer real and imaginary parts: `ℤ[i] = { a + bi | a, b ∈ ℤ }`. The simplest number system supporting quantum interference (destructive cancellation). Used as the concrete quantum amplitude type. See `Quantum/AmplitudeAlg.agda`.

**ℤ/nℤ (cyclic group)**
: The group of integers modulo n. ℤ/2ℤ and ℤ/3ℤ are the finite replacements for U(1). All axioms verified by exhaustive `refl` case splits. See `Gauge/FiniteGroup.agda`, `Gauge/ZMod.agda`.

---

## Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (detailed background) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Holographic bridge (core construction) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Module index (every `src/` module) | [`reference/module-index.md`](module-index.md) |
| Assumptions (frozen model parameters) | [`reference/assumptions.md`](assumptions.md) |
| Holographic dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |