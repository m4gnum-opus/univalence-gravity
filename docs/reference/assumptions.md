# Frozen Model Assumptions

**The fixed parameters and design choices underlying all machine-checked results in the repository.**

**Audience:** Anyone evaluating the scope, validity, or limitations of the formal proofs. Every theorem in [`formal/01-theorems.md`](../formal/01-theorems.md) is proven *relative to* the assumptions listed here.

---

## 1. Purpose

Before any formal proof can be stated, the model must be fixed. This document records every non-trivial choice that was frozen before or during the development of the Agda formalization. Each assumption is tagged with its current status:

| Status | Meaning |
|--------|---------|
| **Active** | Still in force; all current proofs depend on it |
| **Superseded** | Replaced by a stronger or more general choice during development |
| **Relaxed** | Originally frozen but later shown to be unnecessary for the core results |

The assumptions are grouped into three categories: **geometric** (what the discrete spacetime looks like), **algebraic** (what scalar and group types are used), and **architectural** (how the proof is structured).

---

## 2. Geometric Assumptions

### A1. Finite, Simple, Undirected Graphs

**Status: Active**

The boundary and bulk graphs are **undirected**, **simple** (no multi-edges, no self-loops), and **finite**. Boundary sites and bulk cells are drawn from finite types (`Fin N` or explicit finite `data` declarations) for a fixed `N` determined per patch instance.

**Modules depending on this:** Every `Common/*Spec.agda` module. The `data Region`, `data Bond`, `data Tile` types are all finite enumerations with no path constructors.

**Origin:** Assumption 1 of the original [`historical/development-docs/assumptions.md`](../historical/development-docs/assumptions.md).

---

### A2. Contiguous Tile-Aligned Boundary Regions

**Status: Active (but generalized)**

Boundary regions are **contiguous, tile-aligned** subsets of the cyclic boundary ordering. This matches the standard Ryu–Takayanagi setting and restricts the space of regions to connected subsets of boundary cells.

For the 6-tile star patch, regions are contiguous intervals of the 5-tile cyclic ordering. For dense patches, regions are connected subsets of boundary cells in the cell-adjacency graph, up to a maximum size (`max_region_cells`, typically 4–5).

**Generalization from original:** The original assumption specified "contiguous intervals of the cyclic boundary ordering." The dense patches generalize this to connected subsets of boundary cells in the adjacency graph, which subsumes the cyclic-interval definition for 1D boundaries.

**Modules depending on this:** `Common/*Spec.agda` (region type definitions), all `Boundary/*Cut.agda` and `Bulk/*Chain.agda` modules.

**Origin:** Assumption 2 of the original assumptions.

---

### A3. The {5,4} Hyperbolic Pentagonal Tiling (Primary 2D Target)

**Status: Active**

The primary 2D bulk carrier is a finite patch of the **{5,4} pentagonal tiling** — regular pentagons with 4 meeting at each vertex. The Schläfli condition (5−2)(4−2) = 6 > 4 confirms hyperbolic geometry. Interior curvature is κ = −1/5 per vertex.

Three patch sizes are formalized:
- **6-tile star** (`Common/StarSpec.agda`): C + 5 edge-neighbours
- **11-tile filled disk** (`Common/FilledSpec.agda`): C + 5 N + 5 G (gap-fillers)
- **BFS layers depth 2–7** (`Common/Layer54d{2..7}Spec.agda`): 21 to 3046 tiles

**Origin:** Assumption 4 of the original assumptions (which specified only the 11-tile patch). Extended during development to include the star patch and the BFS-layer tower.

---

### A4. The {4,3,5} Hyperbolic Cubic Honeycomb (Primary 3D Target)

**Status: Active (new — not in original assumptions)**

The primary 3D bulk carrier is a finite patch of the **{4,3,5} honeycomb** — regular cubes with 5 meeting at every edge. The Coxeter group [4,3,5] has Gram matrix signature (3,1), confirming compact hyperbolic geometry. Interior edge curvature is κ = −π/2.

Three patch variants are formalized:
- **BFS star** (`Common/Honeycomb3DSpec.agda`): 32 cells, 130 boundary faces
- **Dense-50 / Dense-100 / Dense-200** (`Common/Dense{50,100,200}Spec.agda`): greedy max-connectivity growth, 50–200 cells

The Dense growth strategy was chosen over BFS because it produces multiply-connected bulk with non-trivial min-cut values (up to 9), unlike the BFS-shell topology where all singleton min-cuts are 1.

**Origin:** Introduced during Direction D (§6 of `historical/development-docs/10-frontier.md`). Validated by `sim/prototyping/05_honeycomb_3d_prototype.py`.

---

### A5. The {5,3} Spherical Pentagonal Tiling (De Sitter Target)

**Status: Active (new — not in original assumptions)**

The de Sitter (positive curvature) target is the **{5,3} tiling** — the regular dodecahedron. The 6-face star patch has interior curvature κ = +1/10 per vertex. The restricted star-topology flow graph is **identical** to the {5,4} star, so the holographic bridge is literally the same Agda term for both curvature regimes.

**Modules:** `Bulk/DeSitterPatchComplex.agda`, `Bulk/DeSitterCurvature.agda`, `Bulk/DeSitterGaussBonnet.agda`, `Bridge/WickRotation.agda`.

**Origin:** Introduced during Direction E (§7 of `historical/development-docs/10-frontier.md`). Validated by `sim/prototyping/10_desitter_prototype.py`.

---

### A6. The {4,4} Euclidean Square Grid (Flat Target)

**Status: Active (numerically only — not formalized in Agda)**

The Euclidean {4,4} square grid (4 squares per vertex, zero curvature) is tested numerically by `sim/prototyping/16_half_bound_scaling.py` to confirm that the half-bound S ≤ area/2 holds in the flat regime. No Agda modules are generated for this tiling.

**Origin:** Introduced during the half-bound scaling confirmation (§15.10 of `historical/development-docs/10-frontier.md`).

---

## 3. Algebraic Assumptions

### A7. ℚ≥0 = ℕ (Nonnegative Scalars)

**Status: Active**

Nonnegative scalar values (bond weights, min-cut values, boundary areas) are represented as **bare natural numbers** `ℚ≥0 = ℕ` in `Util/Scalars.agda`. Addition `_+ℚ_ = _+_` computes by structural recursion; the ordering `m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)` admits concrete witnesses `(k , refl)`.

This is sufficient for all formalized patches, where bond capacities are 1 or 2 (Q₈ fundamental representation dimension). The key advantage is **judgmental stability**: identical scalar constants normalize to identical `ℕ` normal forms, enabling all pointwise agreement proofs to be `refl`.

**Upgrade path:** When genuine fractions are needed (e.g., for non-integer bond dimensions), replace the carrier `ℕ` by a canonical nonneg. rational type while preserving the exported interface.

**Origin:** Assumption 3 of the original assumptions (which specified "nonnegative rationals ℚ≥0"). The specialization to `ℕ` was adopted during Phase 1 as the minimal representation supporting `refl`-based proofs.

---

### A8. ℚ₁₀ = ℤ (Signed Curvature Scalars)

**Status: Active**

Signed rational curvature values are represented as **integers** `ℚ₁₀ = ℤ` in `Util/Rationals.agda`, where integer `n` represents the rational `n/10`. All combinatorial curvature values for the {5,4} and {5,3} tilings have denominators dividing 10, so this representation is exact.

The Gauss–Bonnet sum `totalCurvature ≡ one₁₀` holds by `refl` because `ℤ` addition computes by structural recursion on closed constructor terms.

For 3D edge curvature ({4,3,5}), the encoding uses twentieths: `κ₂₀ = 20 − 5·v` where `v` is the edge valence.

**Origin:** Introduced during Phase 2B (curvature formalization). Not in the original assumptions.

---

### A9. Finite Gauge Groups Replace Continuous Lie Groups

**Status: Active**

The Standard Model gauge group SU(3) × SU(2) × U(1) is replaced by well-studied finite subgroups:

| Continuum Factor | Finite Replacement | Order | Irreps (dims) |
|---|---|---|---|
| U(1) | ℤ/nℤ (n = 2, 3) | n | n irreps, all dim 1 |
| SU(2) | Q₈ (quaternion) | 8 | 5 irreps: 1,1,1,1,2 |

All group axioms are verified by exhaustive case split with every case holding by `refl`. The 400-case Q₈ associativity proof is the largest single exhaustive verification in the repository.

The bridge is **gauge-agnostic**: the dimension functor `dim : Rep G → ℕ` extracts scalar bond capacities, and the generic bridge operates on these scalars without seeing the group.

**Modules:** `Gauge/FiniteGroup.agda`, `Gauge/ZMod.agda`, `Gauge/Q8.agda`, `Gauge/Connection.agda`, `Gauge/Holonomy.agda`, `Gauge/ConjugacyClass.agda`, `Gauge/RepCapacity.agda`.

**Origin:** Assumption implicit in the original "finite subgroup replacement" strategy from §13.4 of `historical/development-docs/10-frontier.md`.

---

### A10. Amplitude-Polymorphic Quantum Superposition

**Status: Active (new — not in original assumptions)**

Quantum amplitudes are elements of an arbitrary `AmplitudeAlg` record carrying addition, scaling, zero, and an ℕ-embedding — **no ring axioms**. Two concrete instances are provided:

- **ℕAmplitude** (classical counting, no interference)
- **ℤiAmplitude** (Gaussian integers ℤ[i], quantum interference)

The quantum bridge theorem uses only `refl`, `cong`, and `cong₂` — automatic congruence properties in Cubical Agda. No commutativity, associativity, or distributivity is needed.

**Modules:** `Quantum/AmplitudeAlg.agda`, `Quantum/Superposition.agda`, `Quantum/QuantumBridge.agda`, `Quantum/StarQuantumBridge.agda`.

**Origin:** Introduced during Direction Q (§14 of `historical/development-docs/10-frontier.md`).

---

## 4. Architectural Assumptions

### A11. Combinatorial Curvature (Not Regge Curvature)

**Status: Active**

The curvature notion is **purely combinatorial**: vertex degree deficits from the expected regular degree, computed via the formula

> κ(v) = 1 − deg\_E(v)/2 + Σ\_{f ∋ v} 1/sides(f)

This requires no trigonometry, no constructive reals, and no angle computation. It satisfies the combinatorial Gauss–Bonnet theorem Σ κ(v) = χ(K) for any polyhedral complex K, automatically accounting for boundary effects.

Full Regge-style metric curvature (involving law-of-cosines angle computation) remains a stretch goal. The Python prototype (`02_happy_patch_curvature.py`) verified that the combinatorial, angular, and Regge formulations all produce the same Gauss–Bonnet total for the 11-tile patch.

**Origin:** Assumption 5 of the original assumptions.

---

### A12. Min-Cut as the Entropy Proxy

**Status: Active**

The cut-entropy functional `S-cut` acts as an exact proxy for quantum entanglement entropy under **perfect-tensor assumptions** (as in the HaPPY code). The min-cut is computed via max-flow on the flow graph, not by computing the von Neumann entropy of a reduced density matrix.

The min-cut value equals the minimum number of bonds (or faces, in 3D) that must be severed to disconnect a boundary region from its complement. For the star topology, this is also the bulk minimal separating chain length (both are the same set of central bonds).

For the 11-tile filled patch, the min-cut may sever boundary legs (not just internal bonds) — the "N-singleton discrepancy" resolved in §3.2 of `historical/development-docs/10-frontier.md`. Both boundary and bulk observables use the true min-cut (allowing boundary-leg severance).

**Origin:** Assumptions 6 and 8 of the original assumptions.

---

### A13. Specification-Level Lookup Tables (Not Algorithmic Min-Cut)

**Status: Active**

Observable functions (`S-cut`, `L-min`) are defined as **specification-level lookup tables** returning canonical ℕ constants, not by generic min-cut algorithms formalized in Agda. The Python oracle computes the correct values; Agda verifies each `(k, refl)` witness.

This is the "external oracle + simple kernel" paradigm from the Four Color Theorem (Coq) and the Kepler Conjecture (HOL Light): external computation finds proofs, a simple kernel checks them.

For orbit-reduced patches (Dense-100, Dense-200, Layer-54), the lookup is factored through a classification function: `S-cut _ r = S-cut-rep (classify r)`. The classification function absorbs the large case analysis; the observable lookup operates on the small orbit type.

**Origin:** Implicit in the original approach. Formalized explicitly during Phase 3.5 (Python oracle + abstract barrier strategy).

---

### A14. Uniform Bond Capacity

**Status: Active (with demonstrated generalization)**

All bonds in the primary formalized patches have **uniform capacity 1** (one unit of entanglement per shared edge/face). The gauge-enriched bridge (`Gauge/RepCapacity.agda`) demonstrates non-unit capacity (dim = 2 for Q₈ fundamental representation), and the Python oracle confirms the half-bound S ≤ area/2 under uniform capacities c = 1, 2, 3 (`sim/prototyping/16_half_bound_scaling.py`).

The half-bound proof (`Bridge/HalfBound.agda`) applies to any uniform capacity: the `from-two-cuts` lemma composes two independent cut bounds regardless of the capacity value.

**Origin:** Implicit in Assumption 3 of the original assumptions.

---

### A15. Laplacian Spectra Are Deferred

**Status: Active (unchanged)**

Laplacian spectra are **deferred** from the formal target. They are computed during prototyping to check discriminating power, but formalization of spectral operations is not required for any current theorem.

**Origin:** Assumption 7 of the original assumptions.

---

### A16. The `abstract` Barrier for Propositional Proofs

**Status: Active (new — not in original assumptions)**

Large case analyses (360+ cases) are sealed behind Agda's `abstract` keyword to prevent downstream RAM cascades ([Agda Issue #4573](https://github.com/agda/agda/issues/4573)). This is safe because all sealed proofs target **propositional types** (`_≤ℚ_` is propositional by `isProp≤ℚ`): sealing loses zero information since any two inhabitants of a proposition are equal.

The `abstract` barrier is applied only to inequality proofs, never to observable functions, specification-agreement paths, or enriched equivalences — these retain full computational content for `ua` and `transport`.

**Modules using `abstract`:** `Boundary/FilledSubadditivity.agda` (360 cases), `Boundary/Dense100AreaLaw.agda` (717), `Boundary/Dense200AreaLaw.agda` (1246), `Boundary/Dense100HalfBound.agda` (717), `Boundary/Dense200HalfBound.agda` (1246).

**Origin:** Introduced during Phase 3.5 (the combined Approach A+C strategy).

---

### A17. Scalar Constants Defined Once

**Status: Active (new — not in original assumptions)**

All scalar constants (`1q`, `2q` from `Util/Scalars.agda`; `neg1/5`, `pos1/10`, `one₁₀` from `Util/Rationals.agda`) are defined **once** in utility modules and imported everywhere. No module reconstructs these constants independently.

This **shared-constants discipline** is the foundational invariant enabling all `refl`-based proofs: both sides of every equality must reduce to the **same normal form**, which is guaranteed only if they import the same constant definitions.

**Origin:** Identified as a critical invariant during the tree pilot (§11.5 of `historical/development-docs/08-tree-instance.md`).

---

## 5. Assumptions That Were Superseded or Relaxed

### S1. "Boundary Regions Are Cyclic Intervals" → Generalized to Connected Subsets

The original Assumption 2 specified contiguous intervals of a cyclic ordering. The Dense patches generalize to connected subsets of boundary cells in the adjacency graph. The cyclic-interval definition remains valid for the 2D pentagonal patches (star, filled, layer tower).

### S2. "Edge Weights Are ℚ≥0" → Specialized to ℕ

The original Assumption 3 specified nonneg. rationals. The actual implementation uses `ℚ≥0 = ℕ`, which is more restrictive but sufficient for all formalized patches and enables `refl`-based proofs.

### S3. "Single 2D Bulk Carrier" → Extended to 3D

The original Assumption 4 specified "a finite 2-dimensional simplicial complex." The repository now includes 3D cell complexes ({4,3,5} honeycomb patches) in addition to 2D pentagonal patches.

### S4. "Constructive Reals Needed for Entropy-Area" → Bypassed by Half-Bound

The original understanding (from §15.6 of the historical development docs) was that formalizing the Bekenstein–Hawking entropy-area relationship would require constructive real analysis. The sharp half-bound S ≤ area/2 with 1/(4G) = 1/2 **eliminates this requirement**: the discrete Newton's constant is an exact rational verified by `refl` on closed ℕ terms, not a real-valued limit.

---

## 6. What Is NOT Assumed

The following are **not** assumptions — they are proven results:

| Claim | Status | Module |
|-------|--------|--------|
| S\_cut = L\_min for all regions | **Proven** (Theorem 1) | `Bridge/GenericBridge.agda` |
| Σκ(v) = χ(K) = 1 | **Proven** (Theorem 2) | `Bulk/GaussBonnet.agda` |
| S(A) ≤ area(A)/2 | **Proven** (Theorem 3) | `Bridge/HalfBound.agda` |
| No closed timelike curves | **Proven** (Theorem 5) | `Causal/NoCTC.agda` |
| ⟨S⟩ = ⟨L⟩ for superpositions | **Proven** (Theorem 7) | `Quantum/QuantumBridge.agda` |

The proofs are constructive, machine-checked by the Cubical Agda 2.8.0 type-checker, and depend only on the assumptions listed in this document.

---

## 7. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (ua, transport, funExt) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Translation problem (what is NOT proven) | [`physics/translation-problem.md`](../physics/translation-problem.md) |
| Five walls (hard boundaries) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Holographic dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| `abstract` barrier (engineering) | [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) |
| Orbit reduction (engineering) | [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) |
| Historical assumptions (original version) | [`historical/development-docs/assumptions.md`](../historical/development-docs/assumptions.md) |