# The Discrete Bekenstein–Hawking Bound

**Formal content:** The sharp half-bound S(A) ≤ area(A)/2, the `from-two-cuts` generic lemma, the `two-le-sum` arithmetic core, per-instance `HalfBoundWitness` records, tight achievers, tower integration via `ConvergenceCertificate3L-HB`, and the `DiscreteBekensteinHawking` capstone type.

**Primary modules:** `Bridge/HalfBound.agda`, `Boundary/Dense100HalfBound.agda`, `Boundary/Dense200HalfBound.agda`, `Bridge/SchematicTower.agda` (§25), `Bridge/Dense100Thermodynamics.agda` (§9–§11)

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [03-holographic-bridge.md](03-holographic-bridge.md) (generic bridge architecture), [09-thermodynamics.md](09-thermodynamics.md) (area law, coarse-graining, resolution tower), [11-generic-bridge.md](11-generic-bridge.md) (SchematicTower infrastructure)

---

## 1. Overview

The discrete Bekenstein–Hawking bound is **Theorem 3** in the canonical registry ([01-theorems.md](01-theorems.md)). It strengthens the discrete area law S(A) ≤ area(A) ([09-thermodynamics.md](09-thermodynamics.md)) to the sharp half-bound:

> 2 · S(A) ≤ area(A)

for all cell-aligned boundary regions A on verified patches, with a **tight achiever** — a concrete region where 2·S(A) = area(A). The discrete Newton's constant is thereby identified as 1/(4G) = 1/2 in bond-dimension-1 units.

This result carries three decisive consequences:

1. **The constructive-reals wall is bypassed.** The original `EntropicConvergence` type from §15.9.5 of the historical development docs required a `ConvergenceWitness` — a constructive statement about the limit of a sequence of entropy functionals, demanding Cauchy completeness and constructive real analysis. The sharp half-bound **replaces** this with `HalfBoundWitness` at each resolution level, requiring only ℕ arithmetic and `refl`. The discrete Newton's constant is an exact rational — not a real-valued limit.

2. **The bound is curvature-agnostic and dimension-agnostic.** Numerically verified across 32,134 regions on 4 tilings ({4,3,5} hyperbolic 3D, {5,4} hyperbolic 2D, {4,4} Euclidean flat, {5,3} spherical), 4 growth strategies (Dense, BFS, Geodesic, Hemisphere), and 3 bond capacities (c = 1, 2, 3) — zero violations.

3. **The bound has a clean graph-theoretic proof.** The area of any region decomposes as area = n_cross + n_bdy (crossing bonds + boundary legs). The min-cut is bounded independently by both: S ≤ n_cross and S ≤ n_bdy. Therefore S ≤ min(n_cross, n_bdy) ≤ (n_cross + n_bdy)/2 = area/2.

---

## 2. The Graph-Theoretic Proof

### 2.1 The Area Decomposition

For any cell-aligned boundary region A in a finite cell complex with uniform bond capacity:

> area(A) = n_cross(A) + n_bdy(A)

where:

- **n_cross(A)** = the number of bonds (internal shared faces) connecting A-cells to non-A-cells. These are the bonds that *cross* from the region to its complement.
- **n_bdy(A)** = the number of boundary legs of A-cells — faces exposed to the exterior of the patch (not shared with any other cell).

Each cell has `faces_per_cell` faces (6 for cubes in {4,3,5}, 5 for pentagons in {5,4}, 4 for squares in {4,4}). Each internal face shared between two A-cells is counted by both cells but does not exit A. Subtracting these double-counted internal faces yields the total count of faces that exit A:

> area(A) = faces_per_cell · |A| − 2 · |{internal faces within A}|

### 2.2 The Two Independent Cuts

The max-flow S(A) is bounded by **two independent cuts** of the flow graph:

**Cut 1 — Sever all crossing bonds:** After removing all n_cross bonds from A-cells to non-A-cells, every path from a source-connected boundary pseudo-node (inside A) to a sink-connected boundary pseudo-node (outside A) must cross at least one removed bond. This is a valid cut of capacity n_cross. Therefore:

> S(A) ≤ n_cross(A)

**Cut 2 — Sever all A-boundary-legs:** After removing all n_bdy boundary legs of A-cells, the source has no finite-capacity path to any cell node (all connections from source to the network pass through the removed legs). Therefore no path to the sink survives, and this is a valid cut of capacity n_bdy:

> S(A) ≤ n_bdy(A)

### 2.3 The Half-Bound

Combining both cuts:

> S(A) ≤ min(n_cross(A), n_bdy(A))
>      ≤ (n_cross(A) + n_bdy(A)) / 2
>      = area(A) / 2

The second inequality is the standard arithmetic fact min(a, b) ≤ (a + b) / 2 for non-negative a, b.

### 2.4 Equality Condition

Equality S(A) = area(A)/2 holds if and only if n_cross(A) = n_bdy(A) = area(A)/2 and the max-flow saturates both cuts simultaneously. This occurs for cells where exactly half their faces cross to neighbors and half are exposed as boundary legs. In {4,3,5} (6 faces per cube), a single cell with exactly 3 neighbors in the patch achieves S = 3, area = 6, ratio = 0.5.

---

## 3. The Agda Formalization

### 3.1 The `HalfBoundWitness` Record

The result is packaged in a record type parameterized by a `PatchData`:

```agda
-- Bridge/HalfBound.agda

record HalfBoundWitness (pd : PatchData) : Type₀ where
  open PatchData pd
  field
    area       : RegionTy → ℚ≥0
    half-bound : (r : RegionTy)
               → (S∂ r +ℚ S∂ r) ≤ℚ area r
    tight      : Σ[ r ∈ RegionTy ]
                   (S∂ r +ℚ S∂ r ≡ area r)
```

**Fields:**

- **`area`**: The boundary surface area function, returning the face-count boundary area of each region. Imported from the corresponding `AreaLaw` module (e.g., `Boundary/Dense100AreaLaw.regionArea`).

- **`half-bound`**: For every region r, the doubled min-cut is bounded by the area. Stated as `(S∂ r +ℚ S∂ r) ≤ℚ area r` rather than `S∂ r ≤ℚ half (area r)` to avoid division in ℕ. Each witness is `(k , refl)` where `k + (S r + S r) ≡ area r` judgmentally.

- **`tight`**: A concrete achiever region where `S∂ r +ℚ S∂ r ≡ area r` — the bound is saturated. This witness confirms that the bound is sharp: there exists at least one region achieving equality.

### 3.2 The `two-le-sum` Arithmetic Core

The key arithmetic lemma composing two independent ≤ℚ witnesses into a single doubled bound:

```agda
-- Bridge/HalfBound.agda

two-le-sum : {s a b : ℕ} → s ≤ℚ a → s ≤ℚ b → (s +ℚ s) ≤ℚ (a +ℚ b)
two-le-sum {s} {a} {b} (k₁ , p₁) (k₂ , p₂) =
  k₁ + k₂ , rearrange ∙ cong₂ _+_ p₁ p₂
  where
    rearrange : (k₁ + k₂) + (s + s) ≡ (k₁ + s) + (k₂ + s)
    rearrange =
        sym (+-assoc k₁ k₂ (s + s))
      ∙ cong (k₁ +_) (+-assoc k₂ s s)
      ∙ +-assoc k₁ (k₂ + s) s
      ∙ cong (_+ s) (cong (k₁ +_) (+-comm k₂ s) ∙ +-assoc k₁ s k₂)
      ∙ sym (+-assoc (k₁ + s) k₂ s)
```

**Proof outline:** Given witnesses `(k₁ , p₁)` for `s ≤ a` (meaning `k₁ + s ≡ a`) and `(k₂ , p₂)` for `s ≤ b` (meaning `k₂ + s ≡ b`), the composed witness is `(k₁ + k₂ , proof)` for `(s + s) ≤ (a + b)` (meaning `(k₁ + k₂) + (s + s) ≡ (a + b)`). The `rearrange` path shuffles `(k₁ + k₂) + (s + s)` into `(k₁ + s) + (k₂ + s)` using `+-assoc` and `+-comm` from `Util/NatLemmas.agda`, then `cong₂ _+_ p₁ p₂` converts `(k₁ + s) + (k₂ + s)` to `a + b`.

### 3.3 The `from-two-cuts` Generic Lemma

The two-cut decomposition, expressed generically for any region type:

```agda
-- Bridge/HalfBound.agda

from-two-cuts :
  {RegionTy : Type₀}
  (S∂ area n-cross n-bdy : RegionTy → ℚ≥0)
  → ((r : RegionTy) → area r ≡ n-cross r +ℚ n-bdy r)
  → ((r : RegionTy) → S∂ r ≤ℚ n-cross r)
  → ((r : RegionTy) → S∂ r ≤ℚ n-bdy r)
  → (r : RegionTy) → (S∂ r +ℚ S∂ r) ≤ℚ area r
from-two-cuts S∂ area nc nb decomp le-cross le-bdy r =
  subst ((S∂ r +ℚ S∂ r) ≤ℚ_) (sym (decomp r))
        (two-le-sum (le-cross r) (le-bdy r))
```

**Structure:** Given the area decomposition `area r ≡ n-cross r + n-bdy r`, and the two independent cut bounds `S r ≤ n-cross r` and `S r ≤ n-bdy r`, apply `two-le-sum` to get `(S r + S r) ≤ (n-cross r + n-bdy r)`, then `subst` along the (reversed) decomposition path to convert the RHS from `n-cross r + n-bdy r` to `area r`.

This lemma is the **generic proof** — it works for any finite cell complex with any area decomposition, not just the specific Dense-100 or Dense-200 patches.

---

## 4. Per-Instance Witnesses

### 4.1 The Oracle-Generated Approach

For concrete patches, the Python oracle (`17_generate_half_bound.py`) computes the per-region data:

- For each region r: `half-slack = area(r) − 2 · S(r)` (verified ≥ 0)
- Identifies at least one tight achiever where `half-slack = 0`

The oracle emits Agda modules with `abstract`-sealed proofs:

```agda
-- Boundary/Dense100HalfBound.agda (717 cases)

abstract
  half-bound-proof : (r : D100Region)
    → (S∂ r +ℚ S∂ r) ≤ℚ regionArea r
  -- S=3, area=6, 2·S=6, slack=0
  half-bound-proof d100r0 = 0 , refl
  -- S=3, area=10, 2·S=6, slack=4
  half-bound-proof d100r1 = 4 , refl
  ...
```

Each witness `(k , refl)` type-checks because `k + (S r + S r)` reduces judgmentally to `regionArea r` via ℕ addition on closed numerals. The `abstract` barrier prevents downstream modules from re-normalizing these 717 (or 1246) case analyses.

### 4.2 Dense-100 Instance

The Dense-100 patch (100 cells, 717 regions, 8 orbit representatives) has:

| Statistic | Value |
|-----------|-------|
| Regions | 717 |
| Half-slack range | 0 – 14 |
| Mean half-slack | 6.0 |
| Achievers (2·S = area) | 40 regions (all k=1 cells with S=3, area=6) |

The concrete `HalfBoundWitness`:

```agda
-- Boundary/Dense100HalfBound.agda

dense100HalfBound : HalfBoundWitness pd
dense100HalfBound .HalfBoundWitness.area       = regionArea
dense100HalfBound .HalfBoundWitness.half-bound = half-bound-proof
dense100HalfBound .HalfBoundWitness.tight      = tight-witness
```

where `tight-witness = d100r0 , refl` identifies a 1-cell region with S=3, area=6, 2·3=6.

### 4.3 Dense-200 Instance

The Dense-200 patch (200 cells, 1246 regions, 9 orbit representatives) has:

| Statistic | Value |
|-----------|-------|
| Regions | 1246 |
| Half-slack range | 0 – 14 |
| Mean half-slack | 5.3 |
| Achievers (2·S = area) | 88 regions (k=1: 80, k=2: 4, k=3: 4) |

The achievers at k=2 and k=3 demonstrate that equality is not restricted to single-cell regions: 2-cell regions with S=5, area=10 and 3-cell regions with S=7, area=14 also saturate the bound.

---

## 5. Tower Integration

### 5.1 HalfBoundLevel

A standalone half-bound witness at a single resolution level, storing the region type and observable as fields:

```agda
-- Bridge/SchematicTower.agda §25

record HalfBoundLevel : Type₁ where
  field
    RegionTy   : Type₀
    S-obs      : RegionTy → ℚ≥0
    area       : RegionTy → ℚ≥0
    half-bound : (r : RegionTy) → (S-obs r +ℚ S-obs r) ≤ℚ area r
    tight      : Σ[ r ∈ RegionTy ] (S-obs r +ℚ S-obs r ≡ area r)
```

Concrete instances `dense100-half-bound-level` and `dense200-half-bound-level` are filled from the per-instance modules.

### 5.2 FullLayerStep

Extends `RichLayerStep` with the sharp half-bound at the higher level:

```agda
-- Bridge/SchematicTower.agda §25

record FullLayerStep (lo hi : TowerLevel) : Type₁ where
  field
    monotone   : TowerLevel.maxCut lo ≤ℚ TowerLevel.maxCut hi
    area-law   : AreaLawForPatch (orbit-to-patch (TowerLevel.patch hi))
    half-bound : HalfBoundWitness (orbit-to-patch (TowerLevel.patch hi))
```

The concrete instance `d100→d200-full` carries monotonicity (8 ≤ 9 via `(1 , refl)`), the area law (1246 `abstract` cases), and the sharp half-bound (1246 `abstract` cases with tight achiever) in a single step.

### 5.3 ConvergenceCertificate3L-HB

The 3-level convergence certificate extended with sharp half-bounds:

```agda
-- Bridge/SchematicTower.agda §25

record ConvergenceCertificate3L-HB : Type₁ where
  field
    step-100 step-200   : ResolutionStep
    tower               : ResolutionTower (suc zero)
    monotone-50-100     : 7 ≤ℚ 8
    monotone-100-200    : 8 ≤ℚ 9
    half-bound-100      : HalfBoundLevel
    half-bound-200      : HalfBoundLevel
```

This replaces the weaker `ConvergenceCertificate3L` (which carried `AreaLawLevel` — S ≤ area) with the stronger half-bound (2·S ≤ area, with tight achievers).

### 5.4 DiscreteBekensteinHawking — The Capstone Type

```agda
-- Bridge/SchematicTower.agda §25

DiscreteBekensteinHawking : Type₁
DiscreteBekensteinHawking = ConvergenceCertificate3L-HB

discrete-bekenstein-hawking : DiscreteBekensteinHawking
discrete-bekenstein-hawking = convergence-certificate-3L-HB
```

This is Theorem 3 in its tower form. The type replaces `ContinuumLimitEvidence` as the strongest statement about the entropy-area relationship:

- **Old** (`EntropicConvergence`): `Σ[family] Σ[bridges] Σ[areas] Σ[mono] ConvergenceWitness` — required constructive reals and Cauchy completeness.

- **New** (`DiscreteBekensteinHawking`): `Σ[steps] Σ[tower] Σ[mono] Σ[halfBounds]` — requires only ℕ arithmetic and `refl`.

The `ConvergenceWitness` is eliminated entirely. The discrete Newton's constant 1/(4G) = 1/2 is verified by `refl` on closed ℕ terms at every resolution level — no limit argument needed.

---

## 6. Numerical Verification

The bound S(A) ≤ area(A)/2 was verified numerically across a comprehensive matrix of configurations before formalization:

| Script | Scope | Regions | Violations |
|--------|-------|---------|------------|
| `14c_entropic_convergence_sup_half.py` | 2 tilings, 6 patches, max_rc 5–8 | 23,963 | 0 |
| `15_discrete_bekenstein_hawking.py` | 4 strategies, 2 tilings, 3 capacities | 5,140 | 0 |
| `16_half_bound_scaling.py` | 4 tilings, 4 strategies, 3 capacities | 32,134 | 0 |
| `17_generate_half_bound.py` | Dense-100 + Dense-200 (Agda emission) | 1,963 | 0 |

**Tiling universality:**

| Tiling | Curvature | Dimension | sup(S/area) | Violations |
|--------|-----------|-----------|-------------|------------|
| {4,3,5} | Negative (hyperbolic) | 3D | 0.5000 | 0 / 27,753 |
| {5,4} | Negative (hyperbolic) | 2D | 0.5000 | 0 / 1,300 |
| {4,4} | Zero (Euclidean) | 2D | 0.5000 | 0 / 512 |
| {5,3} | Positive (spherical) | 2D | 0.5000 | 0 / 100 |

The bound is **curvature-agnostic**, **dimension-agnostic**, and **capacity-universal** — exactly as predicted by the two-cut proof.

---

## 7. The Eliminiation of the Constructive-Reals Wall

### 7.1 The Original Obstacle

The Entropic Convergence Conjecture (§15.9.3 of the historical development docs) asked whether the sequence of ratios η_N = max S_N / max area_N converges as N → ∞. Formalizing this required:

1. A constructive real number type with completeness (for the limit).
2. A Cauchy-sequence formalization for the η_N series.
3. An identification of the limiting constant with 1/(4G_N).

All three are beyond current Cubical Agda infrastructure. The constructive-reals wall (Wall 1 of the Five Walls from §15.6) blocked the entropy-area relationship.

### 7.2 The Resolution

The sharp half-bound eliminates the need for a limit entirely:

- **The question** was "does η_N converge, and to what?"
- **The answer** is "η = 1/2 exactly, at every finite N, by `refl`."

The discrete Newton's constant is not a real-valued limit of a sequence. It is an exact rational (1/2) verified by ℕ arithmetic on closed constructor terms at each resolution level independently. No convergence argument, no Cauchy completeness, no constructive reals.

The `ConvergenceWitness` field in the `EntropicConvergence` type is replaced by `HalfBoundLevel` at each tower level. The Five Walls from §15.6 are reduced to **four** — the constructive-reals wall for the entropy-area relationship is bypassed.

---

## 8. Relationship to Other Results

### 8.1 Three Levels of Entropy-Area Constraint

| Level | Statement | Module | Constraint |
|-------|-----------|--------|------------|
| 1 (RT) | S(A) = L(A) | `Bridge/GenericBridge.agda` | Exact correspondence |
| 2 (Area law) | S(A) ≤ area(A) | `Boundary/Dense*AreaLaw.agda` | Isoperimetric inequality |
| 3 (Half-bound) | 2·S(A) ≤ area(A) | `Boundary/Dense*HalfBound.agda` | **Sharp Bekenstein–Hawking** |

Level 3 subsumes Level 2 (since S ≤ 2·S ≤ area for non-negative S). Level 1 is independent (it is an equality, not a bound). All three cohere through the same observable `S-cut` and the same area function `regionArea`.

### 8.2 Orthogonality

The half-bound is orthogonal to all enrichment layers:

- **Curvature** ([04-discrete-geometry.md](04-discrete-geometry.md)): The bound holds for both positive ({5,3}) and negative ({5,4}) curvature. The Wick rotation ([08-wick-rotation.md](08-wick-rotation.md)) preserves the flow graph.
- **Gauge matter** ([05-gauge-theory.md](05-gauge-theory.md)): The bound operates on scalar capacities; gauge structure is invisible.
- **Causal structure** ([06-causal-structure.md](06-causal-structure.md)): The bound applies within each spatial slice; the causal arrow of time is independent.
- **Quantum superposition** ([07-quantum-superposition.md](07-quantum-superposition.md)): The half-bound constrains individual microstates; the quantum bridge lifts across superpositions.
- **Dynamics** ([10-dynamics.md](10-dynamics.md)): Step invariance preserves S = L under bond-weight perturbations; the half-bound applies at each perturbed configuration.

### 8.3 Integration with Thermodynamics

The `Dense100Thermodynamics` module ([09-thermodynamics.md](09-thermodynamics.md)) now carries both the area law (via `CoarseGrainedRT`) and the sharp half-bound (via `dense100-half-bound-witness : HalfBoundWitness`). The three levels of entropy-area constraint coexist through the same classification function `classify100` and the same observable `S-cut d100BdyView`.

---

## 9. The Physics Interpretation

### 9.1 The Discrete Newton's Constant

In the continuum Bekenstein–Hawking formula S = A / (4G), the constant 1/(4G) relates entanglement entropy to boundary surface area. In bond-dimension-1 units (where each bond/face carries one unit of entanglement capacity):

> 1/(4G) = 1/2

This is verified by `refl` on closed ℕ terms — the discrete Newton's constant is an exact rational, not an approximate or limiting quantity.

### 9.2 What This Does and Does Not Prove

**Proven (constructive, machine-checked):**

- S(A) ≤ area(A)/2 for all cell-aligned boundary regions on Dense-100 (717 regions) and Dense-200 (1246 regions), with tight achievers.
- The generic `from-two-cuts` lemma deriving the half-bound from the area decomposition and two independent cut bounds.
- The `two-le-sum` arithmetic core composing two ≤ witnesses into a doubled bound.
- Tower integration: the `DiscreteBekensteinHawking` type carrying half-bounds at each resolution level with monotonicity witnesses.

**Numerically verified (Python oracle, not yet in Agda):**

- The bound holds across 32,134 regions on 4 tilings, 4 strategies, and 3 capacities.
- Zero violations in any tested configuration.

**NOT proven:**

- That the bound S ≤ area/2 holds for ALL possible cell complexes (the Agda proof is per-instance via `abstract` witnesses; the generic `from-two-cuts` lemma provides the structural argument but requires per-instance area decomposition data).
- That the discrete Newton's constant 1/2 has any relationship to the physical Newton's constant G_N.
- That the discrete area-entropy relationship converges to the smooth Bekenstein–Hawking formula in any continuum limit.

---

## 10. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorem 3 |
| HoTT foundations (refl, subst, funExt) | [`formal/02-foundations.md`](02-foundations.md) |
| Holographic bridge (S = L, generic) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Discrete geometry (curvature, orthogonal) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Thermodynamics (area law, coarse-graining) | [`formal/09-thermodynamics.md`](09-thermodynamics.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](11-generic-bridge.md) |
| Orbit reduction (engineering) | [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) |
| `abstract` barrier (engineering) | [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) |
| Discrete Bekenstein–Hawking (physics interpretation) | [`physics/discrete-bekenstein-hawking.md`](../physics/discrete-bekenstein-hawking.md) |
| Five walls (now four) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Dense-100 instance data | [`instances/dense-100.md`](../instances/dense-100.md) |
| Dense-200 instance data | [`instances/dense-200.md`](../instances/dense-200.md) |
| Oracle: proof characterization | `sim/prototyping/15_discrete_bekenstein_hawking.py` |
| Oracle: scaling confirmation | `sim/prototyping/16_half_bound_scaling.py` |
| Oracle: Agda emission | `sim/prototyping/17_generate_half_bound.py` |
| Historical development (§15.9–15.11) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §15.9–15.11 |