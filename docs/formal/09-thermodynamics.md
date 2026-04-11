# Thermodynamics

**Formal content:** Coarse-graining as orbit reduction, the discrete area law, resolution towers, convergence certificates, and the integration of the Bekenstein–Hawking half-bound into the tower infrastructure.

**Primary modules:** `Bridge/CoarseGrain.agda`, `Boundary/Dense100AreaLaw.agda`, `Boundary/Dense200AreaLaw.agda`, `Bridge/Dense100Thermodynamics.agda`, `Bridge/SchematicTower.agda` (§15–§25)

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry), [03-holographic-bridge.md](03-holographic-bridge.md) (generic bridge architecture), [04-discrete-geometry.md](04-discrete-geometry.md) (curvature)

---

## 1. Overview

The thermodynamic layer provides the discrete analogue of the Bekenstein–Hawking entropy-area relationship S = A / 4G. It builds on the holographic bridge (Theorem 1: S = L on every region) by adding three progressively stronger constraints:

| Level | Statement | Module | Constraint |
|-------|-----------|--------|------------|
| 1 (RT) | S(A) = L(A) | `Bridge/GenericBridge.agda` | Exact correspondence |
| 2 (Area law) | S(A) ≤ area(A) | `Boundary/Dense*AreaLaw.agda` | Isoperimetric inequality |
| 3 (Half-bound) | 2·S(A) ≤ area(A) | `Boundary/Dense*HalfBound.agda` | Sharp Bekenstein–Hawking |

Each level subsumes the previous: the half-bound implies the area law (since S ≤ 2·S ≤ area for non-negative S), and the area law is independent of the RT correspondence (it is a property of the flow graph, not of the bulk geometry).

The three levels are assembled into a **resolution tower** — a sequence of verified patches at increasing resolution, connected by monotonicity witnesses certifying that the min-cut spectrum grows with resolution. The tower culminates in the `DiscreteBekensteinHawking` type (`Bridge/SchematicTower.agda` §25), which packages all three levels across multiple resolution steps into a single machine-checked artifact.

The key architectural consequence: the `ConvergenceWitness` originally envisioned in §15.9.5 of the historical development docs — which would have required constructive reals and Cauchy completeness — is **replaced** by the sharp half-bound `HalfBoundWitness` at each level, which requires only ℕ arithmetic and `refl`. The discrete Newton's constant is exactly 1/(4G) = 1/2 in bond-dimension-1 units, verified by `refl` on closed ℕ terms at every resolution level. This **eliminates the constructive-reals wall** for the entropy-area relationship.

---

## 2. Coarse-Graining: Orbit Reduction as Thermodynamic Averaging

### 2.1 The Physical Intuition

In statistical mechanics, coarse-graining is the process of replacing a fine-grained microscopic description (individual particles, exact positions) with a coarse-grained macroscopic description (temperature, pressure, density). Information is irreversibly lost, but the macroscopic observables are preserved.

In the holographic setting, the orbit reduction strategy already implemented in `Common/Dense100Spec.agda` is the first concrete step of this thermodynamic limit: the classification function `classify100 : D100Region → D100OrbitRep` maps 717 fine-grained boundary regions to 8 orbit representatives, grouped by min-cut value. All regions in a given orbit have the same entropy. An observer who only sees `D100OrbitRep` cannot distinguish between the 717 individual boundary configurations — they can only read the *statistical summary* (the min-cut value class).

### 2.2 The CoarseGrainLevel Record

A single level of coarse-graining is formalized as a record pairing a fine region type with a coarse region type, a projection between them, and a compatibility proof:

```agda
-- Bridge/CoarseGrain.agda
record CoarseGrainLevel (Fine Coarse : Type₀) : Type₀ where
  field
    project    : Fine → Coarse
    obs-fine   : Fine → ℚ≥0
    obs-coarse : Coarse → ℚ≥0
    compat     : (r : Fine) → obs-fine r ≡ obs-coarse (project r)
```

The `compat` field is the type-theoretic content of the statement "statistical averaging preserves the observable." For the Dense-100 orbit reduction, `compat` holds **definitionally** (`refl`) because `S-cut` is *defined* as `S-cut-rep ∘ classify100` in `Boundary/Dense100Cut.agda`. The classification function absorbs the case analysis; the observable factorizes through it by construction.

### 2.3 The CoarseGrainWitness Record

The existential packaging stores the fine and coarse region types as fields (rather than parameters), enabling heterogeneous collections:

```agda
-- Bridge/CoarseGrain.agda
record CoarseGrainWitness : Type₁ where
  field
    FineRegion   : Type₀
    CoarseRegion : Type₀
    project      : FineRegion → CoarseRegion
    obs-fine     : FineRegion → ℚ≥0
    obs-coarse   : CoarseRegion → ℚ≥0
    compat       : (r : FineRegion) → obs-fine r ≡ obs-coarse (project r)
    bridge       : (o : CoarseRegion) → obs-coarse o ≡ obs-coarse o
```

The `bridge` field is a placeholder for the RT correspondence at the coarse level; in the current instantiation it is `λ _ → refl`. The genuine coarse-level RT follows from the fine-grained RT composed with `compat`.

### 2.4 The Dense-100 Instance

```agda
-- Bridge/CoarseGrain.agda
dense100-coarse-witness : CoarseGrainWitness
dense100-coarse-witness .FineRegion   = D100Region     -- 717 constructors
dense100-coarse-witness .CoarseRegion = D100OrbitRep   -- 8 constructors
dense100-coarse-witness .project      = classify100
dense100-coarse-witness .obs-fine     = S-cut d100BdyView
dense100-coarse-witness .obs-coarse   = S-cut-rep
dense100-coarse-witness .compat       = λ _ → refl
dense100-coarse-witness .bridge       = λ _ → refl
```

The `compat` field is `λ _ → refl` because `S-cut` is definitionally `S-cut-rep ∘ classify100`. The "compat by refl" property is the type-theoretic content of the statement "orbit reduction preserves the entropy–area relationship": an observer with 3 bits of memory (⌈log₂ 8⌉) reads the correct entropy value for each orbit class.

---

## 3. The Discrete Area Law

### 3.1 The Theorem

For each cell-aligned boundary region A of the Dense-100 (resp. Dense-200) patch:

> S_cut(A) ≤ area(A)

where `area(A) = 6k − 2·|internal faces within A|` is the boundary surface area (in face-count units) of a region of k cells, and S_cut is the min-cut entropy.

This is a graph-theoretic tautology: the max-flow is bounded by the capacity of any cut, and the trivial cut (severing all exiting faces of A) provides the upper bound.

### 3.2 The Agda Formalization

```agda
-- Boundary/Dense100AreaLaw.agda

regionArea : D100Region → ℚ≥0
-- 717 clauses: each maps a region to its face-count boundary area

abstract
  area-law : (r : D100Region) → S-cut d100BdyView r ≤ℚ regionArea r
  -- 717 abstract cases: each is  (k , refl)  where k = area − S
```

The `regionArea` function returns the boundary surface area of each region, computed by the Python oracle (`11_generate_area_law.py`) from the cell complex topology. The `area-law` proof is wrapped in `abstract` so downstream modules never re-unfold the 717-case analysis, halting the RAM cascade documented in [Agda Issue #4573](https://github.com/agda/agda/issues/4573). Since `_≤ℚ_` is propositional (by `isProp≤ℚ`), the `abstract` barrier does not damage any Univalence bridge or transport computation.

### 3.3 Slack Distribution

The slack values (area − S) for Dense-100 range from 3 to 18 with a mean of 11.3. The area law is never tight (S < area for all 717 regions) — the half-bound (§5) provides the tighter constraint.

For Dense-200 (1246 regions), the slack range is also 3–18 with mean 10.8, confirming the pattern at higher resolution.

---

## 4. The Resolution Tower

### 4.1 ResolutionStep

A resolution step pairs two resolution levels with a projection from the finer to the coarser, together with the RT correspondence and a compatibility witness:

```agda
-- Bridge/SchematicTower.agda §16
record ResolutionStep : Type₁ where
  field
    FineRegion   : Type₀
    CoarseRegion : Type₀
    S-fine       : FineRegion → ℚ≥0
    L-fine       : FineRegion → ℚ≥0
    S-coarse     : CoarseRegion → ℚ≥0
    rt-fine      : (r : FineRegion) → S-fine r ≡ L-fine r
    rt-coarse    : (o : CoarseRegion) → S-coarse o ≡ S-coarse o
    project      : FineRegion → CoarseRegion
    compat       : (r : FineRegion) → S-fine r ≡ S-coarse (project r)
```

Two concrete instances are provided: `dense-resolution-step` (Dense-100 orbit reduction) and `dense200-resolution-step` (Dense-200 orbit reduction).

### 4.2 The ResolutionTower Data Type

A tower is an ℕ-indexed list of resolution steps:

```agda
-- Bridge/SchematicTower.agda §18
data ResolutionTower : ℕ → Type₁ where
  base : ResolutionStep → ResolutionTower zero
  step : ∀ {n} → ResolutionStep → ResolutionTower n
       → ResolutionTower (suc n)
```

The Dense-50 → Dense-100 transition is a single-step tower; Dense-50 → Dense-100 → Dense-200 is a two-step tower.

### 4.3 Spectrum Monotonicity

The min-cut spectrum grows monotonically with resolution:

| Transition | Max_lo | Max_hi | Witness |
|---|---|---|---|
| Dense-50 → Dense-100 | 7 | 8 | `(1 , refl)` |
| Dense-100 → Dense-200 | 8 | 9 | `(1 , refl)` |

Each witness is `(k , refl)` where `k + maxCut_lo ≡ maxCut_hi` judgmentally. This is the discrete analogue of the statement "the RT minimal surface grows in area as the resolution increases."

### 4.4 AreaLawLevel

A standalone area-law witness at a single resolution level:

```agda
-- Bridge/SchematicTower.agda §20
record AreaLawLevel : Type₁ where
  field
    RegionTy   : Type₀
    S-obs      : RegionTy → ℚ≥0
    area       : RegionTy → ℚ≥0
    area-bound : (r : RegionTy) → S-obs r ≤ℚ area r
```

Concrete instances: `dense100-area-law-level` (717 cases) and `dense200-area-law-level` (1246 cases).

### 4.5 ConvergenceCertificate3L

The 3-level convergence certificate packages the resolution steps, monotonicity witnesses, and area-law instances:

```agda
-- Bridge/SchematicTower.agda §21
record ConvergenceCertificate3L : Type₁ where
  field
    step-100         : ResolutionStep
    step-200         : ResolutionStep
    tower            : ResolutionTower (suc zero)
    monotone-50-100  : 7 ≤ℚ 8
    monotone-100-200 : 8 ≤ℚ 9
    area-law-100     : AreaLawLevel
    area-law-200     : AreaLawLevel

convergence-certificate-3L : ConvergenceCertificate3L
```

This is the `ContinuumLimitEvidence` type — the formal evidence for the resolution-independence of the holographic correspondence.

---

## 5. The Discrete Bekenstein–Hawking Half-Bound

### 5.1 The Strengthened Bound

The area law S ≤ area is strengthened to:

> 2·S(A) ≤ area(A)

equivalently S(A) ≤ area(A)/2. This identifies the discrete Newton's constant as 1/(4G) = 1/2 in bond-dimension-1 units.

The bound is verified numerically across 32,134 regions on 4 tilings ({4,3,5}, {5,4}, {4,4}, {5,3}), 4 growth strategies (Dense, BFS, Geodesic, Hemisphere), and 3 bond capacities (c = 1, 2, 3) — zero violations. The detailed proof and characterization are in [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md).

### 5.2 Integration with the Tower

The half-bound is integrated into the tower infrastructure via `HalfBoundLevel` and `ConvergenceCertificate3L-HB`:

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

The `tight` field identifies a concrete achiever region where 2·S = area — the bound is saturated. For Dense-100, 40 achiever regions exist (all k=1 cells with S=3, area=6, ratio=0.5). For Dense-200, 88 achievers exist (k=1, k=2, and k=3 cells).

The `ConvergenceCertificate3L-HB` extends the 3-level certificate with the sharp half-bound:

```agda
record ConvergenceCertificate3L-HB : Type₁ where
  field
    step-100         : ResolutionStep
    step-200         : ResolutionStep
    tower            : ResolutionTower (suc zero)
    monotone-50-100  : 7 ≤ℚ 8
    monotone-100-200 : 8 ≤ℚ 9
    half-bound-100   : HalfBoundLevel
    half-bound-200   : HalfBoundLevel

convergence-certificate-3L-HB : ConvergenceCertificate3L-HB
```

### 5.3 DiscreteBekensteinHawking

The capstone type alias:

```agda
DiscreteBekensteinHawking : Type₁
DiscreteBekensteinHawking = ConvergenceCertificate3L-HB

discrete-bekenstein-hawking : DiscreteBekensteinHawking
discrete-bekenstein-hawking = convergence-certificate-3L-HB
```

This is **Theorem 3** (Discrete Bekenstein–Hawking) in its tower form. It carries the full enriched equivalence + area law + half-bound + monotonicity at each resolution level, verified by `refl` on closed ℕ terms.

---

## 6. The CoarseGrainedRT Triple

The fully formalized thermodynamic statement packages three independently constructed components:

```agda
-- Bridge/CoarseGrain.agda §7
CoarseGrainedRT : Type₁
CoarseGrainedRT =
  Σ[ w ∈ CoarseGrainWitness ]
  Σ[ regionArea ∈ (CoarseGrainWitness.FineRegion w → ℚ≥0) ]
    ((r : CoarseGrainWitness.FineRegion w) →
     CoarseGrainWitness.obs-fine w r ≤ℚ regionArea r)
```

The concrete instance from `Bridge/Dense100Thermodynamics.agda`:

```agda
dense100-thermodynamics : CoarseGrainedRT
dense100-thermodynamics = dense100-coarse-witness , regionArea , area-law
```

This packages:

1. **The exact discrete RT correspondence** (S = L on all 717 regions) — via the coarse-graining witness, which carries `compat` factoring through `classify100`.
2. **The orbit reduction** (717 → 8 representative classes) — via `project = classify100`.
3. **The area-law upper bound** (S ≤ area on all 717 regions) — via the `abstract` proof in `Dense100AreaLaw.agda`.

The half-bound witness (`dense100-half-bound-witness : HalfBoundWitness`) is additionally carried in the same module, providing the sharp constraint 2·S ≤ area with a tight achiever.

---

## 7. The Macroscopic Observer Interpretation

The Dense-100 orbit reduction implements a concrete "macroscopic observer" with bounded memory:

| Property | Value |
|----------|-------|
| Fine resolution | D100Region (717 constructors) |
| Coarse resolution | D100OrbitRep (8 constructors) |
| Observer memory | 3 bits (⌈log₂ 8⌉) |
| Observable preservation | `compat = λ _ → refl` (definitional) |

An observer with 3 bits of memory cannot distinguish the 717 individual boundary configurations — they can only track which of the 8 min-cut-value classes each region belongs to. The `compat` field certifies that this lossy compression preserves the entropy observable exactly.

The area-law and half-bound hold at both resolution levels:

- **Fine level:** `S-cut d100BdyView r ≤ℚ regionArea r` (directly from `area-law`)
- **Coarse level:** `S-cut-rep (classify100 r) ≤ℚ regionArea r` (by `compat + area-law`)

The thermodynamic claim — that as the patch grows (N → ∞) while the observer's memory stays bounded, the coarse-grained observable approaches the continuum entropy formula — is a metatheoretic claim beyond the scope of constructive Cubical Agda. However, the **sharp half-bound eliminates the need for a limit argument**: the discrete Newton's constant is exactly 1/2 at every finite resolution level, verified by `refl` on closed ℕ terms.

---

## 8. The Hard Boundary: Continuum Convergence

Three independent obstacles prevent formalizing the full continuum limit in Cubical Agda:

1. **No constructive reals.** The continuum formula S = A/4G involves real-valued areas and Newton's constant G. The cubical library's `Cubical.HITs.Reals` provides no completeness, no convergence of sequences, no integration.

2. **No inductive limit.** Defining the N → ∞ limit requires either a coinductive stream of verified patches (incompatible with `--safe` in the general case) or an external metatheoretic argument. The Agda formalization can produce verified witnesses for each finite N but cannot internalize the limit.

3. **No smooth geometry.** The factor 1/4G depends on the embedding geometry (Planck length, Newton's constant) which has no discrete analogue without a continuum interpretation.

**The half-bound bypasses obstacle 1** for the entropy-area relationship: the discrete Newton's constant 1/(4G) = 1/2 is an exact rational verified by `refl`, not a real-valued limit. Obstacles 2 and 3 remain as the correct conceptual boundary between the discrete formalization and the continuum physics claim.

---

## 9. Relationship to Other Layers

### 9.1 Orthogonality

The thermodynamic layer is orthogonal to and independent of:

- **Curvature** ([04-discrete-geometry.md](04-discrete-geometry.md)): The area law and half-bound are properties of the flow graph; curvature enriches the bulk independently.
- **Gauge matter** ([05-gauge-theory.md](05-gauge-theory.md)): The gauge field lives on bonds; the area law operates on scalar capacities.
- **Causal structure** ([06-causal-structure.md](06-causal-structure.md)): The causal poset sequences time-stratified slices; the thermodynamic structure operates within each slice.
- **Quantum superposition** ([07-quantum-superposition.md](07-quantum-superposition.md)): The quantum bridge lifts per-microstate S = L across superpositions; the area law constrains each microstate's S independently.

### 9.2 The Three Parameterizations

| Section | Parameter Varied | Invariant Preserved |
|---|---|---|
| Wick rotation ([08-wick-rotation.md](08-wick-rotation.md)) | Curvature sign | Bridge equivalence |
| **Thermodynamics (this chapter)** | **Observer resolution** | **Area law + RT** |
| Dynamics ([10-dynamics.md](10-dynamics.md)) | Bond weights | Bridge at each step |

All three are instances of the same architectural pattern: parameterize the common source specification, verify the bridge at each parameter value, and package the coherence.

---

## 10. Numerical Verification

All area-law bounds, half-bound witnesses, and tight achievers were verified numerically before formalization by the Python oracle scripts:

| Script | Generates | Verified |
|--------|-----------|----------|
| `11_generate_area_law.py` | `Dense100AreaLaw.agda` | S ≤ area for 717 regions |
| `12_generate_dense200.py` | `Dense200AreaLaw.agda` | S ≤ area for 1246 regions |
| `14c_entropic_convergence_sup_half.py` | — | sup(S/area) = 0.5 across 23,963 regions |
| `15_discrete_bekenstein_hawking.py` | — | 2·S ≤ area for 5,140 regions, 0 violations |
| `16_half_bound_scaling.py` | — | 2·S ≤ area for 32,134 regions, 4 tilings, 3 capacities |
| `17_generate_half_bound.py` | `Dense100HalfBound.agda`, `Dense200HalfBound.agda` | Per-instance `(k, refl)` witnesses |

---

## 11. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorem 3 |
| Holographic bridge (S = L) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Discrete geometry (curvature, orthogonal) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Dynamics (parameterized step invariance) | [`formal/10-dynamics.md`](10-dynamics.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Orbit reduction (engineering) | [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) |
| `abstract` barrier (engineering) | [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) |
| Bekenstein–Hawking half-bound (formal) | [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md) |
| Discrete Bekenstein–Hawking (physics) | [`physics/discrete-bekenstein-hawking.md`](../physics/discrete-bekenstein-hawking.md) |
| Dense-100 instance data | [`instances/dense-100.md`](../instances/dense-100.md) |
| Dense-200 instance data | [`instances/dense-200.md`](../instances/dense-200.md) |
| Historical development (§8, §10 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §8, §10 |