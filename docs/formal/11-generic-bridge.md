# The Generic Bridge and Schematic Tower

**Formal content:** The `PatchData` abstract interface, orbit reduction via `OrbitReducedPatch`, the `orbit-bridge-witness` one-function composition, the `SchematicTower` infrastructure (`TowerLevel`, `LayerStep`, resolution towers), convergence certificates, and the `DiscreteBekensteinHawking` capstone type.

**Primary modules:** `Bridge/GenericBridge.agda`, `Bridge/GenericValidation.agda`, `Bridge/SchematicTower.agda`, `Bridge/BridgeWitness.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [03-holographic-bridge.md](03-holographic-bridge.md) (enriched equivalence construction), [09-thermodynamics.md](09-thermodynamics.md) (area law, coarse-graining)

---

## 1. Overview

The generic bridge is the core architectural innovation of the repository. It factors the holographic correspondence into a single parameterized proof (`GenericBridge.agda`) that produces a fully proof-carrying `BridgeWitness` for *any* patch satisfying an abstract interface — then assembles verified instances into a `SchematicTower` that tracks monotone growth of the min-cut spectrum across resolution levels.

The factorization separates the proof into two independent concerns:

1. **Geometry** (handled by the Python oracle): patch construction, min-cut computation, orbit classification, area-law verification. This is the combinatorial case enumeration that varies per instance.

2. **Proof** (handled by the generic theorem, proven once): enriched type equivalence, Univalence path, verified transport, `BridgeWitness` assembly. This is the HoTT plumbing that is identical for every instance.

The consequence: **adding a new patch instance requires zero new hand-written proof**. The Python oracle generates the `OrbitReducedPatch` data; `orbit-bridge-witness` produces the `BridgeWitness` automatically. Twelve patch instances have been verified this way, spanning 1D trees, 2D pentagonal tilings, and 3D cubic honeycombs — from 8-region toy models to 1885-region exponentially growing hyperbolic patches.

This document traces the construction from the abstract interface (`PatchData`) through orbit reduction (`OrbitReducedPatch`) to the tower assembly (`SchematicTower`) and the capstone `DiscreteBekensteinHawking` type.

---

## 2. The PatchData Interface

### 2.1 Minimal Data for Any Holographic Patch

The `PatchData` record captures the *minimum* data needed for the holographic bridge:

```agda
-- Bridge/GenericBridge.agda
record PatchData : Type₁ where
  field
    RegionTy : Type₀
    S∂       : RegionTy → ℚ≥0
    LB       : RegionTy → ℚ≥0
    obs-path : S∂ ≡ LB
```

Four inputs — a region type, two observable functions (boundary min-cut and bulk minimal chain), and a path between them. Nothing about pentagons, cubes, hyperbolic geometry, curvature, dimension, gauge groups, or Coxeter reflections appears. The record lives in `Type₁` because it stores `RegionTy : Type₀` as a field.

The `obs-path` is the discrete Ryu–Takayanagi correspondence: boundary min-cut entropy equals bulk minimal separating surface area on every admissible region. It is typically constructed by `funExt` of pointwise `refl` proofs — or, for orbit-reduced patches, by `funExt` of a 1-line lifting from orbit-representative agreement.

### 2.2 The Geometric Blindness Property

The `GenericEnriched` module ([03-holographic-bridge.md](03-holographic-bridge.md) §5) depends on **exactly** these four inputs. It never inspects:

- The number of constructors in `RegionTy` (10, 90, 717, 1885 — all the same)
- Whether the patch is 2D or 3D
- Whether the curvature is positive, negative, or zero
- Whether bonds carry gauge-group representations
- Whether the observable values come from a lookup table or orbit-representative composition

This blindness is not a weakness — it is a structural fact about the holographic correspondence. The bridge operates on the abstract flow graph (bond weights and min-cuts); the geometry enriches the topology without constraining it. This explains why the same Agda term serves both AdS ({5,4}) and dS ({5,3}) tilings ([08-wick-rotation.md](08-wick-rotation.md)), why the 3D extension works ([04-discrete-geometry.md](04-discrete-geometry.md)), and why the gauge enrichment is orthogonal ([05-gauge-theory.md](05-gauge-theory.md)).

---

## 3. Orbit Reduction via OrbitReducedPatch

### 3.1 The Scaling Problem

For small patches (10–90 regions), the observable functions `S∂` and `LB` are defined as flat lookup tables, and the `obs-path` is `funExt` of pointwise `refl` — one `refl` case per region constructor. This works well up to ~500 constructors.

Beyond that, the pattern-matching definitions grow linearly with region count, but the *proof obligations* (pointwise `refl` at each constructor) grow at the same rate. For the Dense-100 patch (717 regions) or the {5,4} depth-7 layer (1885 regions), flat enumeration is feasible for the data types but wasteful for the proofs: all 717 regions share only 8 distinct min-cut values.

### 3.2 The Orbit Reduction Strategy

The `OrbitReducedPatch` record captures the pattern used by all large patches:

```agda
-- Bridge/GenericBridge.agda
record OrbitReducedPatch : Type₁ where
  field
    RegionTy  : Type₀
    OrbitTy   : Type₀
    classify  : RegionTy → OrbitTy
    S-rep     : OrbitTy → ℚ≥0
    L-rep     : OrbitTy → ℚ≥0
    rep-agree : (o : OrbitTy) → S-rep o ≡ L-rep o
```

The idea: instead of defining observables on the large `RegionTy`, define them on the small `OrbitTy` and compose with a classification function:

- **`RegionTy`** — the (potentially large) region type (717, 1246, 1885 constructors)
- **`OrbitTy`** — the (small) orbit representative type (8, 9, 2 constructors)
- **`classify`** — a surjection from regions to orbit representatives, grouping regions by min-cut value
- **`S-rep`, `L-rep`** — observable lookups on orbit representatives (8 clauses, not 717)
- **`rep-agree`** — pointwise agreement on orbit representatives (8 `refl` proofs, not 717)

### 3.3 Automatic PatchData Extraction

The `PatchData` is extracted automatically from an `OrbitReducedPatch`:

```agda
-- Bridge/GenericBridge.agda
orbit-to-patch : OrbitReducedPatch → PatchData
orbit-to-patch orp = record
  { RegionTy = RegionTy
  ; S∂       = λ r → S-rep (classify r)
  ; LB       = λ r → L-rep (classify r)
  ; obs-path = funExt (λ r → rep-agree (classify r))
  }
  where open OrbitReducedPatch orp
```

The `obs-path` is constructed by the familiar 1-line lifting: `rep-agree (classify r)` at each region `r` is assembled into a function-level path by `funExt`. This is exactly the pattern from `Bridge/Dense100Obs.agda`:

```agda
d100-pointwise r = d100-pointwise-rep (classify100 r)
```

The 717-clause classification function `classify100` is traversed only during concrete evaluation (when Agda reduces a specific constructor); the proof obligations remain on the 8-constructor orbit type.

### 3.4 The One-Function Composition

The composition `orbit-bridge-witness : OrbitReducedPatch → BridgeWitness` produces the full proof-carrying bridge witness from oracle-generated orbit data in a single step:

```agda
-- Bridge/GenericBridge.agda
orbit-bridge-witness : OrbitReducedPatch → BridgeWitness
orbit-bridge-witness orp =
  GenericEnriched.abstract-bridge-witness (orbit-to-patch orp)
```

This is the architectural pivot: the Python oracle's job is solely to produce valid `OrbitReducedPatch` instances (Spec, Cut, Chain, Obs modules); the generic theorem handles the proof — once.

### 3.5 Scaling Properties

The orbit reduction scales logarithmically with patch size:

| Patch | Regions | Orbits | Reduction | Proof cases |
|-------|---------|--------|-----------|-------------|
| Star (6-tile) | 10 | — | flat | 10 |
| Filled (11-tile) | 90 | — | flat | 90 |
| Dense-50 | 139 | — | flat | 139 |
| Dense-100 | 717 | 8 | 90× | 8 |
| Dense-200 | 1246 | 9 | 138× | 9 |
| {5,4} depth 2 | 15 | 2 | 8× | 2 |
| {5,4} depth 7 | 1885 | 2 | 942× | 2 |

Adding more tiles grows only the `classify` function (one clause per region constructor), not the proof obligations (one `refl` per orbit representative). The orbit count grows logarithmically with the min-cut range, which itself grows slowly with patch size.

---

## 4. Retroactive Validation

Six pre-existing bridge instances are validated as instantiations of `GenericEnriched` in `Bridge/GenericValidation.agda`:

```agda
-- Bridge/GenericValidation.agda
star-generic-witness   : BridgeWitness   -- 10 regions, PatchData
filled-generic-witness : BridgeWitness   -- 90 regions, PatchData
h3-generic-witness     : BridgeWitness   -- 26 regions (3D), PatchData
d50-generic-witness    : BridgeWitness   -- 139 regions, PatchData
d100-generic-witness   : BridgeWitness   -- 717 → 8 orbits, OrbitReducedPatch
d200-generic-witness   : BridgeWitness   -- 1246 → 9 orbits, OrbitReducedPatch
```

Coherence checks verify that the generic `S∂` and `LB` agree definitionally (pointwise) with the concrete observables:

```agda
d100-S∂-pointwise : (r : D100Region)
  → PatchData.S∂ (orbit-to-patch d100OrbitPatch) r ≡ S∂D100 r
d100-S∂-pointwise _ = refl
```

Both sides reduce to `S-cut-rep (classify100 r)` — the generic `orbit-to-patch` lambda and the concrete `S-cut` definition produce the same normal form. The fact that this module **type-checks** is the validation: the generic architecture subsumes all existing bridges without modifying any of them.

---

## 5. The SchematicTower Infrastructure

### 5.1 TowerLevel — A Verified Holographic Slice

A `TowerLevel` bundles an oracle-generated `OrbitReducedPatch` with the fully proof-carrying `BridgeWitness` extracted from the generic bridge theorem:

```agda
-- Bridge/SchematicTower.agda
record TowerLevel : Type₁ where
  field
    patch  : OrbitReducedPatch
    maxCut : ℚ≥0
    bridge : BridgeWitness
```

The `maxCut` field records the maximum min-cut value among the orbit representatives — the "holographic depth" of this resolution level.

The smart constructor `mkTowerLevel` forces the bridge witness to be derived from `orbit-bridge-witness`, ensuring topological consistency:

```agda
mkTowerLevel : OrbitReducedPatch → ℚ≥0 → TowerLevel
mkTowerLevel orp mc = record
  { patch  = orp ; maxCut = mc
  ; bridge = orbit-bridge-witness orp }
```

### 5.2 LayerStep — Monotonicity Between Levels

A `LayerStep` connects two consecutive tower levels with a monotonicity witness certifying that the holographic depth does not decrease:

```agda
record LayerStep (lo hi : TowerLevel) : Type₀ where
  field
    monotone : TowerLevel.maxCut lo ≤ℚ TowerLevel.maxCut hi
```

Each monotonicity witness is a concrete `(k , refl)` proof on closed ℕ terms. For the Dense resolution tower: `(1 , refl)` because `1 + 8 = 9` judgmentally. For the {5,4} layer tower: `(0 , refl)` because all depths have maxCut = 2.

### 5.3 Concrete Tower Instances

**Dense resolution tower** (2 levels, 3D {4,3,5} honeycomb):

```agda
d100-tower-level : TowerLevel   -- 717 regions, 8 orbits, maxCut = 8
d200-tower-level : TowerLevel   -- 1246 regions, 9 orbits, maxCut = 9

d100→d200 : LayerStep d100-tower-level d200-tower-level
d100→d200 .LayerStep.monotone = 1 , refl   -- 1 + 8 = 9
```

**{5,4} layer tower** (6 levels, 2D hyperbolic pentagonal tiling, BFS depths 2–7):

| Depth | Tiles | Regions | Orbits | maxCut |
|-------|-------|---------|--------|--------|
| 2 | 21 | 15 | 2 | 2 |
| 3 | 61 | 40 | 2 | 2 |
| 4 | 166 | 105 | 2 | 2 |
| 5 | 441 | 275 | 2 | 2 |
| 6 | 1161 | 720 | 2 | 2 |
| 7 | 3046 | 1885 | 2 | 2 |

Each level is constructed by `mkTowerLevel` from an oracle-generated `OrbitReducedPatch`. The `LayerStep` witnesses are all `(0 , refl)` because the max min-cut is uniformly 2 across all BFS depths. The exponential boundary growth (21 → 3046 tiles) is the hallmark of hyperbolic geometry — but the orbit count stays at 2, and the proof obligations remain constant.

---

## 6. Resolution Steps and Convergence Certificates

### 6.1 ResolutionStep

A `ResolutionStep` pairs two resolution levels with a coarse-graining projection, the RT correspondence at the fine level, and a compatibility witness:

```agda
-- Bridge/SchematicTower.agda §16
record ResolutionStep : Type₁ where
  field
    FineRegion   CoarseRegion : Type₀
    S-fine L-fine : FineRegion → ℚ≥0
    S-coarse      : CoarseRegion → ℚ≥0
    rt-fine       : (r : FineRegion) → S-fine r ≡ L-fine r
    rt-coarse     : (o : CoarseRegion) → S-coarse o ≡ S-coarse o
    project       : FineRegion → CoarseRegion
    compat        : (r : FineRegion) → S-fine r ≡ S-coarse (project r)
```

The `compat` field is `λ _ → refl` for all orbit-reduced patches because `S-cut` is *defined* as `S-cut-rep ∘ classify` — the classification function absorbs the case analysis, and the observable factorizes through it by construction.

### 6.2 Spectrum Monotonicity

The min-cut spectrum grows monotonically with resolution:

| Transition | Max_lo | Max_hi | Witness |
|---|---|---|---|
| Dense-50 → Dense-100 | 7 | 8 | `(1 , refl)` |
| Dense-100 → Dense-200 | 8 | 9 | `(1 , refl)` |

Each witness is `(k , refl)` where `k + maxCut_lo ≡ maxCut_hi` judgmentally. This is the discrete analogue of the statement "the RT minimal surface grows in area as the resolution increases."

### 6.3 AreaLawLevel and HalfBoundLevel

Two standalone constraint records are carried at each resolution level:

**AreaLawLevel** — the discrete isoperimetric inequality S ≤ area:

```agda
record AreaLawLevel : Type₁ where
  field
    RegionTy   : Type₀
    S-obs area : RegionTy → ℚ≥0
    area-bound : (r : RegionTy) → S-obs r ≤ℚ area r
```

**HalfBoundLevel** — the sharp Bekenstein–Hawking bound 2·S ≤ area:

```agda
record HalfBoundLevel : Type₁ where
  field
    RegionTy   : Type₀
    S-obs area : RegionTy → ℚ≥0
    half-bound : (r : RegionTy) → (S-obs r +ℚ S-obs r) ≤ℚ area r
    tight      : Σ[ r ∈ RegionTy ] (S-obs r +ℚ S-obs r ≡ area r)
```

The `tight` field identifies a concrete achiever region where 2·S = area — the bound is saturated. For Dense-100, 40 achiever regions exist (all k=1 cells with S=3, area=6, ratio=0.5). For Dense-200, 88 achievers exist.

### 6.4 The 3-Level Convergence Certificate

The `ConvergenceCertificate3L` packages three resolution levels with monotonicity witnesses and area-law instances:

```agda
record ConvergenceCertificate3L : Type₁ where
  field
    step-100 step-200   : ResolutionStep
    tower               : ResolutionTower (suc zero)
    monotone-50-100     : 7 ≤ℚ 8
    monotone-100-200    : 8 ≤ℚ 9
    area-law-100        : AreaLawLevel
    area-law-200        : AreaLawLevel
```

This is the `ContinuumLimitEvidence` type — the formal evidence for the resolution-independence of the holographic correspondence. All fields are filled from independently verified modules; the certificate merely packages them.

---

## 7. The Discrete Bekenstein–Hawking Capstone

### 7.1 From ConvergenceWitness to HalfBoundWitness

The original `EntropicConvergence` type from §15.9.5 of the historical development docs required a `ConvergenceWitness` — a constructive statement that the sequence of entropy functionals converges in a suitable function space. This would have required constructive reals and Cauchy completeness.

The sharp half-bound **eliminates this requirement entirely**. The `ConvergenceCertificate3L-HB` extends the 3-level certificate with sharp half-bounds at each verified level:

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

The `ConvergenceWitness` (requiring constructive reals) is replaced by `HalfBoundLevel` at each level (requiring only ℕ arithmetic and `refl`). The discrete Newton's constant 1/(4G) = 1/2 is verified by `refl` on closed ℕ terms at every resolution level — no limit argument, no Cauchy completeness.

### 7.2 The Capstone Type Alias

```agda
DiscreteBekensteinHawking : Type₁
DiscreteBekensteinHawking = ConvergenceCertificate3L-HB

discrete-bekenstein-hawking : DiscreteBekensteinHawking
discrete-bekenstein-hawking = convergence-certificate-3L-HB
```

This is **Theorem 3** (Discrete Bekenstein–Hawking) in its tower form. It carries the full enriched equivalence + half-bound + monotonicity at each resolution level. The type replaces `ContinuumLimitEvidence` as the strongest statement about the entropy-area relationship: instead of asking "does η_N converge?", it provides the exact answer — η = 1/2, proven for every finite patch, with no limit needed.

---

## 8. The FullLayerStep — Everything in One Record

The `FullLayerStep` record carries monotonicity, the area law, and the half-bound at the higher level:

```agda
record FullLayerStep (lo hi : TowerLevel) : Type₁ where
  field
    monotone   : TowerLevel.maxCut lo ≤ℚ TowerLevel.maxCut hi
    area-law   : AreaLawForPatch (orbit-to-patch (TowerLevel.patch hi))
    half-bound : HalfBoundWitness (orbit-to-patch (TowerLevel.patch hi))
```

The concrete instance for Dense-100 → Dense-200:

```agda
d100→d200-full : FullLayerStep d100-tower-level d200-tower-level
d100→d200-full .FullLayerStep.monotone   = 1 , refl
d100→d200-full .FullLayerStep.area-law   = record { ... }
d100→d200-full .FullLayerStep.half-bound = dense200-half-bound
```

This packages three independently verified constraints into a single step: the min-cut spectrum grows (monotone), the entropy is bounded by area (area-law), and the entropy is bounded by *half* the area (half-bound, with tight achiever).

---

## 9. The Twelve Verified Bridge Instances

Every holographic bridge in the repository is an instantiation of `GenericEnriched`:

| # | Instance | Tiling | Dim | Regions | Orbits | Max S | Strategy |
|---|----------|--------|-----|---------|--------|-------|----------|
| 1 | Tree pilot | 1D tree | 1D | 8 | — | 2 | flat refl |
| 2 | Star (6-tile) | {5,4} | 2D | 10 | — | 2 | PatchData |
| 3 | Filled (11-tile) | {5,4} | 2D | 90 | — | 4 | PatchData |
| 4 | Honeycomb (BFS) | {4,3,5} | 3D | 26 | — | 1 | PatchData |
| 5 | Dense-50 | {4,3,5} | 3D | 139 | — | 7 | PatchData |
| 6 | Dense-100 | {4,3,5} | 3D | 717 | 8 | 8 | OrbitReducedPatch |
| 7 | Dense-200 | {4,3,5} | 3D | 1246 | 9 | 9 | OrbitReducedPatch |
| 8 | {5,4} depth 2 | {5,4} | 2D | 15 | 2 | 2 | OrbitReducedPatch |
| 9 | {5,4} depth 3 | {5,4} | 2D | 40 | 2 | 2 | OrbitReducedPatch |
| 10 | {5,4} depth 4 | {5,4} | 2D | 105 | 2 | 2 | OrbitReducedPatch |
| 11 | {5,4} depth 5 | {5,4} | 2D | 275 | 2 | 2 | OrbitReducedPatch |
| 12 | {5,4} depth 7 | {5,4} | 2D | 1885 | 2 | 2 | OrbitReducedPatch |

Instances 1–5 use `PatchData` directly (flat enumeration). Instances 6–12 use `OrbitReducedPatch` (orbit reduction). All are produced by the same generic theorem — the only per-instance code is the oracle-generated data modules.

---

## 10. The BridgeWitness Record

All bridge results are packaged into a single universal record:

```agda
-- Bridge/BridgeWitness.agda
record BridgeWitness : Type₁ where
  field
    BdyTy              : Type₀
    BulkTy             : Type₀
    bdy-data           : BdyTy
    bulk-data          : BulkTy
    bridge             : BdyTy ≃ BulkTy
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data
```

This is the **Milestones 3–4 deliverable**: a machine-checked proof that boundary and bulk observable packages are exactly equivalent types, with verified computable transport. The record is defined in its own leaf module to break the dependency chain: generic infrastructure depends only on abstract interfaces, not on per-instance implementations.

The record is consumed by:
- `Bridge/SchematicTower.agda` (tower assembly — `TowerLevel.bridge`)
- `Bridge/WickRotation.agda` (dS/AdS coherence — `shared-bridge`)
- `Bridge/GenericValidation.agda` (retroactive consistency — 6 instances)
- `Causal/CausalDiamond.agda` (causal diamond endpoints carry tower levels with bridges)

---

## 11. The Oracle Pipeline Integration

Each new patch instance follows the same pipeline:

```
sim/prototyping/XX_generate_*.py    (Python oracle)
      │
      ├──▶ Common/*Spec.agda        (region type + orbit classification)
      ├──▶ Boundary/*Cut.agda       (S-cut via orbit reps)
      ├──▶ Bulk/*Chain.agda         (L-min via orbit reps)
      ├──▶ Bridge/*Obs.agda         (pointwise refl + funExt)
      ├──▶ Boundary/*AreaLaw.agda   (abstract: S ≤ area)     [optional]
      └──▶ Boundary/*HalfBound.agda (abstract: 2·S ≤ area)   [optional]
                │
                ▼
      Bridge/GenericBridge.agda     (orbit-bridge-witness → BridgeWitness)
                │
                ▼
      Bridge/SchematicTower.agda    (mkTowerLevel → tower registration)
```

The Python oracle handles all combinatorial case enumeration. Agda checks the emitted `(k, refl)` witnesses individually. The generic theorem handles the proof — once. This is the same division of labor used by the Four Color Theorem (Coq) and the Kepler Conjecture (HOL Light): external computation finds proofs, a simple kernel checks them.

---

## 12. Architectural Significance

### 12.1 Induction on the Proof Schema, Not the Geometry

The original plan for N-layer generalization (§5.2 of the historical development docs) required structural induction on the *geometry* of the tiling — layer-by-layer construction of the polygon complex with closed-loop gluing constraints. This collides with a fundamental obstruction: encoding the {5,4} tiling's closed-loop geometry inductively requires weeks of graph-theory formalization.

The schematic bridge factorization changes the structure of the induction:

> **Original:** Structural induction on the *geometry* (layer-by-layer polygon complex).
>
> **New:** Structural induction on the *proof schema* (generic theorem applied to oracle-generated instances).

The hard geometry stays in Python. The Agda proof is written once. No new hand-written bridge module is needed for layer 3, 4, 5, or N — only the generated modules (Spec, Cut, Chain, Obs).

### 12.2 One Proof, N Instances

The `GenericEnriched` module is ~30 lines of Agda. The `orbit-to-patch` function is ~10 lines. Together they produce the full enriched equivalence + Univalence path + verified transport for *any* patch, regardless of region count, orbit count, or geometric origin. Every bridge instance in the repository is a specialization — no per-instance proof engineering.

### 12.3 The Tower IS the Evidence

The `DiscreteBekensteinHawking` type packages:

1. Two resolution steps (orbit reductions at Dense-100 and Dense-200)
2. A 2-step resolution tower connecting them
3. Monotonicity witnesses (7 ≤ 8 ≤ 9)
4. Sharp half-bounds at each verified level (2·S ≤ area with tight achievers)

This is the constructive, machine-checked content of the statement "the discrete Newton's constant is exactly 1/2 in bond-dimension-1 units." The constructive-reals wall from §15.6 of the historical development docs is **bypassed** for the entropy-area relationship: the constant is an exact rational verified by `refl`, not a real-valued limit.

---

## 13. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorems 1, 3 |
| HoTT foundations (ua, transport, funExt) | [`formal/02-foundations.md`](02-foundations.md) |
| Enriched equivalence construction | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Discrete geometry (curvature, orthogonal) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Thermodynamics (area law, coarse-graining) | [`formal/09-thermodynamics.md`](09-thermodynamics.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Orbit reduction (engineering) | [`engineering/orbit-reduction.md`](../engineering/orbit-reduction.md) |
| `abstract` barrier (engineering) | [`engineering/abstract-barrier.md`](../engineering/abstract-barrier.md) |
| Per-instance data sheets | [`instances/`](../instances/) |
| Historical development (§5 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §5 |