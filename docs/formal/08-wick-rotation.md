# Discrete Wick Rotation

**Formal content:** Curvature-agnostic holographic bridge, the {5,3} de Sitter star patch, positive interior curvature, the `WickRotationWitness` coherence record, and the discrete analogue of the cosmological constant sign flip.

**Primary modules:** `Bridge/WickRotation.agda`, `Bulk/DeSitterPatchComplex.agda`, `Bulk/DeSitterCurvature.agda`, `Bulk/DeSitterGaussBonnet.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry), [03-holographic-bridge.md](03-holographic-bridge.md) (generic bridge architecture), [04-discrete-geometry.md](04-discrete-geometry.md) (combinatorial curvature and Gauss–Bonnet)

---

## 1. Overview

The discrete Wick rotation is **Theorem 4** in the canonical registry ([01-theorems.md](01-theorems.md)). It asserts that the holographic bridge (Theorem 1: discrete Ryu–Takayanagi) is **curvature-agnostic**: the same Agda term serves both the negatively curved AdS-like ({5,4}) and the positively curved dS-like ({5,3}) pentagonal tilings. The two Gauss–Bonnet theorems (one per curvature regime) attach independently to opposite sides of the shared bridge, and a coherence record witnesses that all three components coexist on the same geometric substrate.

In continuum physics, the Wick rotation maps between Anti-de Sitter space (negative cosmological constant, Λ < 0) and de Sitter space (positive cosmological constant, Λ > 0) via analytic continuation — multiplying the radius of curvature by the imaginary unit *i*. This requires complex analysis, smooth Lorentzian geometry, and unresolved conceptual issues about the nature of the dS boundary. The discrete formulation sidesteps all of these: the "Wick rotation" is a **parameter change in the tiling type** (vertex valence *q* = 4 → *q* = 3) that flips the curvature sign while preserving the flow graph. No complex numbers, no analytic continuation, no constructive ℂ.

The key CS insight: the holographic bridge depends only on the **flow-graph topology** — the bond-weight structure and min-cut values — not on the embedding geometry. The curvature enters only in Theorem 2 (Gauss–Bonnet), which is a separate, compatible structure. The bridge theorem is geometrically blind; the curvature enriches the topology without constraining it.

---

## 2. The Two Pentagonal Tilings

### 2.1 The Schläfli Classification

The Schläfli symbol {*p*, *q*} denotes a tiling by regular *p*-gons with *q* meeting at each vertex. For pentagonal tilings (*p* = 5):

| Symbol | (*p*−2)(*q*−2) | Curvature | Geometry |
|--------|-------|-----------|----------|
| {5, 3} | 3·1 = 3 < 4 | **Positive** (spherical) | Regular dodecahedron (12 faces on S²) |
| {5, 4} | 3·2 = 6 > 4 | **Negative** (hyperbolic) | Infinite {5,4} tiling of H² |

Both tilings are built from regular pentagons. The **only** difference is the vertex valence: 3 pentagons per vertex (spherical) vs 4 pentagons per vertex (hyperbolic).

### 2.2 The AdS Star Patch ({5,4}) — Already Formalized

The 6-tile star patch from `Common/StarSpec.agda`:

- Central pentagon C + 5 edge-neighbours N₀…N₄
- **5 interior vertices**, each at valence 4 (4 pentagons meeting)
- Gap-filler tiles needed between adjacent N tiles (the 11-tile filled patch fills these)
- Bond graph: star topology (C connected to each Nᵢ)
- Min-cut: S(*k*) = min(*k*, 5−*k*) for a region of *k* tiles
- Interior curvature: κ = −1/5 per vertex (**negative** — hyperbolic)

### 2.3 The dS Star Patch ({5,3}) — New

The 6-face star patch from `Bulk/DeSitterPatchComplex.agda`, extracted from the regular dodecahedron:

- Central pentagon C + 5 edge-neighbours N₀…N₄
- **5 interior vertices**, each at valence 3 (3 pentagons meeting)
- **No gap-filler tiles needed**: in {5,3}, only 3 pentagons meet at each vertex, and the star patch already saturates every interior vertex. At vertex vᵢ of C, the three faces C, Nᵢ₋₁, and Nᵢ are exactly the 3 faces of the dodecahedron meeting there. No angular gaps remain.
- Bond graph: **identical star topology** (C connected to each Nᵢ)
- Min-cut: S(*k*) = min(*k*, 5−*k*) — **identical to the AdS star**
- Interior curvature: κ = +1/10 per vertex (**positive** — spherical)

### 2.4 The Flow-Graph Isomorphism

The flow-graph isomorphism is **exact**: the dS star and the AdS star have the same tile set ({C, N₀, N₁, N₂, N₃, N₄}), the same 5 bonds, the same 10 representative regions, and the same min-cut values on every region. The Python prototype (`10_desitter_prototype.py`) confirms this across all 10 representative boundary regions — zero mismatches.

If the dS modules import `Tile`, `Bond`, and `Region` from `Common/StarSpec.agda` (rather than defining new types), the isomorphism is **definitional**: both sides use literally the same types, and the bridge is literally the same term.

---

## 3. The dS Polygon Complex

### 3.1 Vertex Classification (3 Classes)

The {5,3} star patch has only 3 vertex classes (compared to 5 for {5,4}), because no gap-filler tiles are needed:

```agda
-- Bulk/DeSitterPatchComplex.agda
data DSVClass : Type₀ where
  dsTiling  : DSVClass    -- v₀…v₄    (5 interior, valence 3)
  dsSharedW : DSVClass    -- w₀…w₄    (5 boundary, shared N/N)
  dsOuterB  : DSVClass    -- b₀…b₄    (5 boundary, N-only)
```

| Class | Count | deg | faces | Location |
|-------|-------|-----|-------|----------|
| dsTiling | 5 | 3 | 3 | Interior |
| dsSharedW | 5 | 3 | 2 | Boundary |
| dsOuterB | 5 | 2 | 1 | Boundary |

### 3.2 Topological Counts

| Property | {5,4} (AdS) | {5,3} (dS) |
|----------|-------------|------------|
| Tiles | 11 | 6 |
| Gap-fillers | 5 (G₀…G₄) | 0 |
| Vertices | 30 | 15 |
| Edges | 40 | 20 |
| Vertex classes | 5 | 3 |
| Interior valence | 4 | 3 |
| Euler χ | 1 | 1 |

Both patches are disks (χ = 1). The Euler identity is stated additively:

```agda
-- Bulk/DeSitterPatchComplex.agda
ds-euler-char : dsTotalV + dsTotalF ≡ dsTotalE + 1
ds-euler-char = refl     -- 15 + 6 = 21 = 20 + 1
```

---

## 4. Positive Interior Curvature

### 4.1 The Curvature Formula

The combinatorial curvature formula is the same as for {5,4} ([04-discrete-geometry.md](04-discrete-geometry.md) §4):

> κ(v) = 1 − deg_E(v)/2 + Σ_{f ∋ v} 1/sides(f)

In the ℚ₁₀ encoding (tenths):

> κ₁₀(v) = 10 − 5 · deg(v) + 2 · faceValence(v)

### 4.2 Curvature per Vertex Class

```agda
-- Bulk/DeSitterCurvature.agda
dsκ-class : DSVClass → ℚ₁₀
dsκ-class dsTiling  = pos1/10     --  +1/10  (POSITIVE — spherical!)
dsκ-class dsSharedW = neg1/10     --  −1/10
dsκ-class dsOuterB  = pos1/5      --  +2/10 = +1/5
```

Computation trace for the interior vertex class:

```
dsTiling:  10 − 5·3 + 2·3 = 10 − 15 + 6 = +1
```

Compared with AdS:

```
vTiling:   10 − 5·4 + 2·4 = 10 − 20 + 8 = −2
```

The sign flip is manifest: −2/10 (AdS) → +1/10 (dS). This is the combinatorial analogue of the cosmological constant sign flip Λ_AdS < 0 → Λ_dS > 0.

```agda
-- Bulk/DeSitterCurvature.agda
dsκ-interior-positive : dsκ-class dsTiling ≡ pos 1
dsκ-interior-positive = refl
```

### 4.3 Curvature Comparison Table

| Vertex type | {5,4} κ | {5,3} κ | Sign change? |
|-------------|---------|---------|--------------|
| Interior (tiling) | −1/5 (−2/10) | **+1/10** (+1/10) | **YES** — the Wick rotation |
| Shared boundary | −1/10 | −1/10 | No |
| Outer boundary | +1/5 (+2/10) | +1/5 (+2/10) | No |

Only the interior curvature changes sign. The boundary vertex classes have identical curvature in both tilings.

---

## 5. The dS Gauss–Bonnet Theorem

### 5.1 The Class-Weighted Sum

```agda
-- Bulk/DeSitterCurvature.agda
dsTotalCurvature : ℚ₁₀
dsTotalCurvature =
    dsVCount dsTiling  ·₁₀ dsκ-class dsTiling       -- 5·(+1) = +5
  +₁₀ dsVCount dsSharedW ·₁₀ dsκ-class dsSharedW     -- 5·(−1) = −5
  +₁₀ dsVCount dsOuterB  ·₁₀ dsκ-class dsOuterB       -- 5·(+2) = +10
```

### 5.2 The Proof: `refl`

```agda
-- Bulk/DeSitterGaussBonnet.agda
ds-discrete-gauss-bonnet : dsTotalCurvature ≡ dsχ₁₀
ds-discrete-gauss-bonnet = refl
```

The computation: (+5) + (−5) + (+10) = +10 = one₁₀ = χ₁₀.

### 5.3 The Symmetric Decomposition

The dS interior/boundary decomposition is **symmetric** — unique to the spherical regime:

```agda
-- Bulk/DeSitterGaussBonnet.agda
dsSymmetricSplit : dsInteriorCurv ≡ dsBoundaryCurv
dsSymmetricSplit = refl     -- both = pos 5 (= +5/10 = +1/2)
```

Contrast with the AdS decomposition, which is **asymmetric**:

| Component | {5,4} (AdS) | {5,3} (dS) |
|-----------|-------------|------------|
| Interior | −10/10 = −1 | +5/10 = +1/2 |
| Boundary | +20/10 = +2 | +5/10 = +1/2 |
| **Total** | **+10/10 = 1** | **+10/10 = 1** |

In the physics interpretation: positive cosmological curvature distributes evenly (interior = boundary = +1/2), while negative curvature creates a strong interior deficit compensated by large boundary turning (interior = −1, boundary = +2). Both sum to the topological invariant χ = 1.

---

## 6. The Curvature-Agnostic Bridge

### 6.1 Geometric Blindness of the Bridge

The generic bridge theorem (`GenericEnriched` from `Bridge/GenericBridge.agda`) depends on **exactly four inputs**:

1. A type `RegionTy : Type₀`
2. A function `S∂ : RegionTy → ℚ≥0`
3. A function `LB : RegionTy → ℚ≥0`
4. A path `obs-path : S∂ ≡ LB`

Nothing about curvature, vertex classification, face valence, gap-filler tiles, or tiling parameters appears in the proof. The bridge operates on the abstract flow graph, not on the embedding geometry.

The concrete bridge witness for the star patch (`star-generic-witness` from `Bridge/GenericValidation.agda`) is produced by applying `GenericEnriched` to a `PatchData` constructed from `Common/StarSpec.agda`. The `PatchData` references the 1q and 2q constants from `Util/Scalars.agda` — not any curvature value, vertex type, or Schläfli parameter.

### 6.2 The Same Term for Both Regimes

Since the dS modules import `Tile`, `Bond`, and `Region` from `Common/StarSpec.agda` (the same types used by the AdS bridge), the bridge equivalence is literally the same Agda term for both curvature regimes. The `shared-bridge` field of `WickRotationWitness` is `star-generic-witness` — unchanged, unmodified, curvature-unaware:

```agda
-- Bridge/WickRotation.agda
the-bridge : BridgeWitness
the-bridge = star-generic-witness
```

This is not a coincidence or a simplification. It is a **structural fact** about the holographic correspondence: the bridge is a property of information flow (the flow graph), not of geometry (the curvature). Geometry enriches the topology without constraining it.

---

## 7. The WickRotationWitness Record

### 7.1 The Three Components

The `WickRotationWitness` record packages three independently verified components into a single coherent artifact:

```agda
-- Bridge/WickRotation.agda
record WickRotationWitness : Type₁ where
  field
    shared-bridge      : BridgeWitness
    ads-gauss-bonnet   : GaussBonnetWitness
    ds-gauss-bonnet    : DSGaussBonnetWitness
    euler-coherence    : GaussBonnetWitness.eulerChar₁₀ ads-gauss-bonnet
                       ≡ DSGaussBonnetWitness.eulerChar₁₀ ds-gauss-bonnet
```

**Component 1** (shared-bridge): The curvature-agnostic holographic bridge, produced by the generic bridge machinery from `Bridge/GenericBridge.agda` via `Bridge/GenericValidation.agda`. This carries the full enriched type equivalence, Univalence path, and verified transport.

**Component 2** (ads-gauss-bonnet): The AdS Gauss–Bonnet witness from `Bulk/GaussBonnet.agda` — discrete Gauss–Bonnet for the {5,4} tiling with negative interior curvature κ = −1/5.

**Component 3** (ds-gauss-bonnet): The dS Gauss–Bonnet witness from `Bulk/DeSitterGaussBonnet.agda` — discrete Gauss–Bonnet for the {5,3} tiling with positive interior curvature κ = +1/10.

**Coherence** (euler-coherence): Both patches target the same Euler characteristic χ = 1 (encoded as one₁₀ = pos 10 in ℚ₁₀). The proof is `refl` because both `χ₁₀` and `dsχ₁₀` are defined as `one₁₀` in their respective modules.

### 7.2 The Concrete Witness

```agda
-- Bridge/WickRotation.agda
wick-rotation-witness : WickRotationWitness
wick-rotation-witness .WickRotationWitness.shared-bridge    = star-generic-witness
wick-rotation-witness .WickRotationWitness.ads-gauss-bonnet = patch-gb-witness
wick-rotation-witness .WickRotationWitness.ds-gauss-bonnet  = ds-patch-gb-witness
wick-rotation-witness .WickRotationWitness.euler-coherence  = refl
```

All fields are filled from existing, independently verified modules. No new proofs are constructed — the module assembles three independently verified components into a single coherent record.

---

## 8. Why Complex Numbers Are Not Needed

The physics Wick rotation L_dS = *i* · L_AdS multiplies a length by the imaginary unit. In the discrete setting, this operation has **no analogue and no function**:

1. **No metric signature.** The "metric" is a weight function on bonds, always positive (ℕ-valued). There is no timelike/spacelike distinction to rotate.

2. **No analytic continuation.** All functions are defined by finite case splits on concrete constructors, not by holomorphic extension.

3. **The curvature sign change is achieved by changing the tiling parameter** *q* from 4 to 3 — a change of combinatorial input, not a complex rotation.

4. **The observable values are identical.** The min-cut values for both patches are the same ℕ literals (1 and 2 for singletons and pairs respectively). There is nothing to multiply by *i*.

The `Util/ComplexNumbers.agda` module conjectured in early project metadata is therefore **not required**. The discrete Wick rotation lives entirely in the existing scalar infrastructure: `ℚ≥0 = ℕ` for observables (`Util/Scalars.agda`) and `ℚ₁₀ = ℤ` for curvature (`Util/Rationals.agda`).

---

## 9. What Changes and What Does Not

| Property | Changes? | AdS ({5,4}) | dS ({5,3}) |
|----------|----------|-------------|------------|
| Tile type | No | Pentagons (p = 5) | Pentagons (p = 5) |
| Vertex valence | **Yes** | q = 4 | q = 3 |
| Gap-filler tiles | **Yes** | 5 needed (G₀…G₄) | 0 needed |
| Bond graph (restricted star) | No | 5 C–N bonds | 5 C–N bonds |
| Region type | No | `Region` (10 ctors) | `Region` (10 ctors) |
| Min-cut values | No | S(k) = min(k, 5−k) | S(k) = min(k, 5−k) |
| Interior curvature sign | **Yes** | κ < 0 (negative) | κ > 0 (positive) |
| Euler characteristic | No | χ = 1 | χ = 1 |
| Gauss–Bonnet total | No | Σκ = 1 | Σκ = 1 |
| Bridge equivalence | No | Same `BridgeWitness` | Same `BridgeWitness` |
| Transport | No | Same `enriched-transport` | Same `enriched-transport` |

The "Wick rotation" is a parameter change (*q* = 4 → *q* = 3) that flips the curvature sign while preserving the flow graph and all holographic observables.

---

## 10. The Boundary Interpretation

In continuum AdS/CFT, the boundary is spatial (the conformal boundary ∂M of the hyperbolic bulk). In the conjectured dS/CFT (Strominger 2001), the boundary is temporal (the future/past conformal infinity I⁺/I⁻ of de Sitter space).

In the discrete formalization, the distinction between "spatial boundary" and "temporal boundary" is **not a property of the type**. The boundary is the set of exposed legs of the finite patch. Whether we interpret it as "the spatial edge of a hyperbolic disk" or "the temporal edge of a cosmological horizon" is a semantic choice that does not affect the combinatorial structure, the min-cut computation, or the type equivalence.

The "boundary swap" is therefore not a type-theoretic operation but a **change of physical interpretation** of the same formal object. This is precisely the situation the Observable Package architecture was designed to handle: the packages capture mathematical content while being agnostic about the physical interpretation.

---

## 11. Numerical Verification

All curvature values, Gauss–Bonnet sums, and min-cut comparisons were verified numerically before formalization by the Python prototype `10_desitter_prototype.py`:

| Check | Result |
|-------|--------|
| Bond graph isomorphic to {5,4} star (restricted) | ✓ All 10 min-cut values match |
| Euler characteristic χ = 1 (disk) | ✓ 15 − 20 + 6 = 1 |
| Interior curvature κ = +1/10 (positive) | ✓ |
| Gauss–Bonnet: Σκ(v) = χ(K) = 1 | ✓ By refl on ℤ arithmetic |
| ℚ₁₀ encoding: all values have denominators dividing 10 | ✓ |

The Python prototype serves as the search engine that confirms feasibility; Agda is the checker that verifies each proof line.

---

## 12. Architectural Significance

### 12.1 The Deepest Insight

The curvature-agnostic bridge is the structural content of a profound claim: **the holographic correspondence is a property of information flow, not of geometry**. Geometry (curvature, dimension, curvature sign) is *compatible with* but *independent of* the holographic bridge. The bridge is the deeper structure; geometry is the enrichment.

If this is correct, then the translation from the discrete model to our universe should focus not on recovering smooth geometry (which is an enrichment, not the core) but on recovering the **information-theoretic structure** — the flow graph, its capacities, and the min-cut entropy functional.

### 12.2 Orthogonality with Other Layers

The Wick rotation module is orthogonal to all other enrichment layers:

- **Gauge matter** ([05-gauge-theory.md](05-gauge-theory.md)): The gauge field lives on bonds within each patch; the Wick rotation changes the curvature between patches.
- **Causal structure** ([06-causal-structure.md](06-causal-structure.md)): The causal poset sequences time-stratified slices; spatial curvature is independent.
- **Quantum superposition** ([07-quantum-superposition.md](07-quantum-superposition.md)): The quantum bridge lifts per-microstate agreement across superpositions; the Wick rotation changes the geometric context.
- **Dynamics** ([10-dynamics.md](10-dynamics.md)): Step invariance preserves the bridge under bond-weight perturbations; the Wick rotation changes the tiling parameter.

### 12.3 Module Dependencies

The `Bridge/WickRotation.agda` module imports from (but does NOT modify):

| Import | Purpose |
|--------|---------|
| `Bulk/GaussBonnet.agda` | AdS Gauss–Bonnet witness |
| `Bulk/DeSitterGaussBonnet.agda` | dS Gauss–Bonnet witness |
| `Bridge/GenericValidation.agda` | `star-generic-witness` |
| `Bridge/BridgeWitness.agda` | `BridgeWitness` record |
| `Bridge/EnrichedStarEquiv.agda` | `Theorem3`, `theorem3` |
| `Bulk/Curvature.agda` | `κ-interior-negative` |
| `Bulk/DeSitterCurvature.agda` | `dsκ-interior-positive` |

No existing module is modified. The Wick rotation is purely additive: the dS curvature modules and the coherence record are new; everything else is reused.

---

## 13. Conceptual Architecture

```
                      ┌─────────────────────────┐
                      │   Common/StarSpec.agda  │
                      │   (Tile, Bond, Region)  │
                      └────────────┬────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
           ┌───────▼────┐  ┌──────▼──────┐ ┌─────▼──────┐
           │ Boundary/  │  │   Bulk/     │ │   Bulk/    │
           │ StarCut    │  │  StarChain  │ │ StarChain  │
           │ (S-cut)    │  │  (L-min)    │ │ (L-min)    │
           └──────┬─────┘  └──────┬──────┘ └──────┬─────┘
                  │               │               │
                  └───────┬───────┘               │
                          │                       │
                  ┌───────▼────────┐              │
                  │ Bridge/        │              │
                  │ GenericBridge  │   ◄──────────┘
                  │ + GenericVal.  │   (same bridge!)
                  │ (Theorem 1)   │
                  └───────┬────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
    ┌───────▼──────┐      │     ┌───────▼──────┐
    │ Bulk/        │      │     │ Bulk/        │
    │ GaussBonnet  │      │     │ DeSitter     │
    │ (κ < 0)      │      │     │ GaussBonnet  │
    │ Theorem 2    │      │     │ (κ > 0)      │
    │ [AdS]        │      │     │ [dS]         │
    └───────┬──────┘      │     └───────┬──────┘
            │             │             │
            └─────────────┼─────────────┘
                          │
                  ┌───────▼────────┐
                  │ Bridge/        │
                  │ WickRotation   │
                  │ (this chapter) │
                  │                │
                  │  Witnesses:    │
                  │  • AdS GB      │
                  │  • dS GB       │
                  │  • Shared      │
                  │    bridge      │
                  │    (generic!)  │
                  └────────────────┘
```

The bridge sits at the center, shared by both curvature regimes. It is produced by `GenericBridge.agda` (the generic theorem proven once) and validated by `GenericValidation.agda`. The two Gauss–Bonnet theorems attach independently to opposite sides. The Wick Rotation module witnesses their coherence.

---

## 14. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) — Theorem 4 |
| HoTT foundations (refl, funExt, ua) | [`formal/02-foundations.md`](02-foundations.md) |
| Holographic bridge (curvature-agnostic) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Discrete geometry (Gauss–Bonnet, ℚ₁₀) | [`formal/04-discrete-geometry.md`](04-discrete-geometry.md) |
| Gauge theory (orthogonal enrichment) | [`formal/05-gauge-theory.md`](05-gauge-theory.md) |
| Causal structure (orthogonal enrichment) | [`formal/06-causal-structure.md`](06-causal-structure.md) |
| Quantum superposition bridge | [`formal/07-quantum-superposition.md`](07-quantum-superposition.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| De Sitter patch instance | [`instances/desitter-patch.md`](../instances/desitter-patch.md) |
| Physics dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Translation problem (five walls) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Historical development (§7 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §7 |
| Numerical verification (Python) | `sim/prototyping/10_desitter_prototype.py` |