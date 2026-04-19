# De Sitter Patch Instance

**The {5,3} dodecahedron star — 6 pentagonal faces with positive curvature, sharing the holographic bridge with the {5,4} AdS star patch.**

**Modules:** `Bulk/DeSitterPatchComplex.agda`, `Bulk/DeSitterCurvature.agda`, `Bulk/DeSitterGaussBonnet.agda`, `Bridge/WickRotation.agda`

**Shared modules (reused from the star patch, NOT duplicated):** `Common/StarSpec.agda`, `Boundary/StarCut.agda`, `Bulk/StarChain.agda`, `Bridge/StarObs.agda`, `Bridge/StarEquiv.agda`, `Bridge/EnrichedStarObs.agda`, `Bridge/FullEnrichedStarObs.agda`, `Bridge/EnrichedStarEquiv.agda`, `Bridge/GenericValidation.agda`

**Role:** The {5,3} de Sitter star patch is the positively curved companion to the {5,4} Anti-de Sitter star patch ([`instances/star-patch.md`](star-patch.md)). It demonstrates that the holographic bridge (Theorem 1: discrete Ryu–Takayanagi) is **curvature-agnostic**: the same Agda term serves both the negatively curved AdS regime and the positively curved dS regime — without complex numbers, analytic continuation, or Lorentzian geometry. The curvature sign flip between the two regimes is the combinatorial analogue of the cosmological constant sign flip Λ\_AdS < 0 → Λ\_dS > 0, packaged as the `WickRotationWitness` coherence record (**Theorem 4**: Discrete Wick Rotation).

---

## 1. Patch Overview

| Property | Value |
|----------|-------|
| **Dimension** | 2D (pentagonal tiling) |
| **Tiling** | {5,3} spherical (regular pentagons, **3** meeting at each vertex) |
| **Source** | Regular dodecahedron (12 pentagonal faces on S²) |
| **Tiles** | 6 (1 central C + 5 edge-neighbours N₀…N₄) |
| **Gap-filler tiles** | **0** (none needed — {5,3} saturates every interior vertex) |
| **Internal bonds (restricted star)** | 5 (C–N₀, C–N₁, C–N₂, C–N₃, C–N₄) |
| **Boundary legs per tile** | C: 0, each Nᵢ: 4 |
| **Total boundary legs** | 20 |
| **Representative regions** | 10 (5 singletons + 5 adjacent pairs) |
| **Min-cut range** | 1–2 |
| **Bridge strategy** | **Reuses the {5,4} star bridge** (literally the same `BridgeWitness` term) |
| **Curvature** | Combinatorial: κ = **+1/10** at interior vertices (**positive** — spherical) |
| **Euler characteristic** | χ = V − E + F = 15 − 20 + 6 = 1 (disk) |
| **Auto-generated?** | No — hand-written (3 curvature modules + 1 coherence module) |

---

## 2. Topology

The {5,3} star patch is extracted from the regular dodecahedron by selecting one face as the central pentagon C and its 5 edge-neighbours N₀…N₄. Because the Schläfli symbol is {5,3} (only **3** pentagons meet at each vertex), the three faces C, N\_{i−1}, and N\_i completely tile the neighbourhood of each interior vertex v\_i. **No angular gaps remain**, and **no gap-filler tiles are needed** — in stark contrast to the {5,4} star patch, where 4 pentagons meet at each vertex and gap-fillers G₀…G₄ are required to complete the disk.

```
         N₄
          |
    N₃ ── C ── N₀
        /  \
      N₂    N₁
```

This is the same tile-adjacency diagram as the {5,4} star patch. The difference is invisible at the bond-graph level — it appears only in the polygon complex (vertex valence 3 vs 4) and in the curvature (positive vs negative).

**Tiles:**

| Tile | Role | Internal bonds | Boundary legs |
|------|------|----------------|---------------|
| C | Central | 5 (to N₀…N₄) | 0 |
| N₀…N₄ | Edge-neighbour | 1 each (to C) | 4 each |

**Bond graph (restricted star topology):**

| Bond | Tiles | Weight | Role |
|------|-------|--------|------|
| bCN0 | C–N₀ | 1 | Shared pentagon edge |
| bCN1 | C–N₁ | 1 | Shared pentagon edge |
| bCN2 | C–N₂ | 1 | Shared pentagon edge |
| bCN3 | C–N₃ | 1 | Shared pentagon edge |
| bCN4 | C–N₄ | 1 | Shared pentagon edge |

All bonds have uniform weight 1, **identical to the {5,4} star**. The boundary ordering is cyclic: N₀, N₁, N₂, N₃, N₄.

**The flow-graph isomorphism with the {5,4} star is exact:** the same tile set ({C, N₀, N₁, N₂, N₃, N₄}), the same 5 bonds, the same 10 representative regions, and the same min-cut values on every region. This is why the bridge is literally the same Agda term for both tilings.

**Key difference from the {5,4} star:** In the **full** polygon complex of the {5,3} star, each N\_i also shares an edge with its cyclic neighbours N\_{i−1} and N\_{i+1} (through the shared boundary vertices w\_i). These N–N bonds are **absent** in the {5,4} star (which has angular gaps between adjacent N tiles). However, the **restricted star topology** used by all Bridge modules ignores these lateral bonds — it uses only the 5 radial C–N\_i bonds. The restriction is the correct model because the holographic bridge depends only on the flow-graph topology, not on the embedding geometry.

---

## 3. The {5,3} Polygon Complex

### 3.1 Vertex Classification (3 Classes)

The 15 vertices of the {5,3} star patch fall into 3 classes (compared to 5 for the {5,4} filled patch):

| Class | Vertices | Count | Int/Bdy | deg | faces | κ (rational) | κ (tenths) |
|-------|----------|-------|---------|-----|-------|--------------|------------|
| dsTiling | v₀…v₄ | 5 | Interior | 3 | 3 | **+1/10** | **+1** |
| dsSharedW | w₀…w₄ | 5 | Boundary | 3 | 2 | −1/10 | −1 |
| dsOuterB | b₀…b₄ | 5 | Boundary | 2 | 1 | +1/5 | +2 |

**No gap-filler vertex classes exist** because there are no gap-filler tiles in {5,3}.

### 3.2 Topological Counts

| Property | {5,4} (AdS) | {5,3} (dS) |
|----------|-------------|------------|
| Tiles | 11 | **6** |
| Gap-fillers | 5 (G₀…G₄) | **0** |
| Vertices | 30 | **15** |
| Edges | 40 | **20** |
| Vertex classes | 5 | **3** |
| Interior valence | 4 | **3** |
| Euler χ | 1 | **1** |

Both patches are disks (χ = 1). The Euler identity is stated additively in Agda:

```agda
-- Bulk/DeSitterPatchComplex.agda
ds-euler-char : dsTotalV + dsTotalF ≡ dsTotalE + 1
ds-euler-char = refl     -- 15 + 6 = 21 = 20 + 1
```

### 3.3 Face-Vertex Incidence

Each pentagonal face is specified by an ordered 5-tuple of its vertices:

```agda
-- Bulk/DeSitterPatchComplex.agda
dsFaceVertices dsC  = dsv₀ , dsv₁ , dsv₂ , dsv₃ , dsv₄
dsFaceVertices dsN₀ = dsv₀ , dsv₁ , dsw₁ , dsb₀ , dsw₀
dsFaceVertices dsN₁ = dsv₁ , dsv₂ , dsw₂ , dsb₁ , dsw₁
  -- ... (6 clauses total)
```

---

## 4. Positive Interior Curvature

### 4.1 The Curvature Formula

The combinatorial curvature formula is the same as for {5,4}:

> κ(v) = 1 − deg\_E(v)/2 + Σ\_{f ∋ v} 1/sides(f)

In the ℚ₁₀ encoding (tenths):

> κ₁₀(v) = 10 − 5 · deg(v) + 2 · faceValence(v)

### 4.2 Interior Curvature: The Sign Flip

For the interior vertex class `dsTiling` (valence 3, 3 faces meeting):

```
dsTiling:  10 − 5·3 + 2·3 = 10 − 15 + 6 = +1   (positive!)
```

Compare with the {5,4} patch:

```
vTiling:   10 − 5·4 + 2·4 = 10 − 20 + 8 = −2   (negative)
```

The sign flip is manifest: **−2/10 (AdS) → +1/10 (dS)**. This is the combinatorial analogue of the cosmological constant sign flip Λ\_AdS < 0 → Λ\_dS > 0. At each interior vertex of the {5,3} patch, 3 regular pentagons contribute 3 × 108° = 324° < 360°, giving a **positive** angular deficit of +36° = π/5.

```agda
-- Bulk/DeSitterCurvature.agda
dsκ-class : DSVClass → ℚ₁₀
dsκ-class dsTiling  = pos1/10     --  +1/10  (POSITIVE — spherical!)
dsκ-class dsSharedW = neg1/10     --  −1/10
dsκ-class dsOuterB  = pos1/5      --  +2/10 = +1/5

dsκ-interior-positive : dsκ-class dsTiling ≡ pos 1
dsκ-interior-positive = refl
```

### 4.3 Curvature Comparison Table

| Vertex type | {5,4} κ (tenths) | {5,3} κ (tenths) | Sign change? |
|-------------|-------------------|-------------------|--------------|
| Interior (tiling) | **−2** (negative) | **+1** (positive) | **YES — the Wick rotation** |
| Shared boundary | −1 | −1 | No |
| Outer boundary | +2 | +2 | No |

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

| Component | {5,4} (AdS) | {5,3} (dS) |
|-----------|-------------|------------|
| Interior | −10/10 = −1 | **+5/10 = +1/2** |
| Boundary | +20/10 = +2 | **+5/10 = +1/2** |
| **Total** | **+10/10 = 1** | **+10/10 = 1** |

In the physics interpretation: positive cosmological curvature distributes evenly (interior = boundary = +1/2), while negative curvature creates a strong interior deficit compensated by large boundary turning (interior = −1, boundary = +2). Both sum to the topological invariant χ = 1.

---

## 6. The Curvature-Agnostic Bridge

### 6.1 Why No New Bridge Modules Are Needed

The de Sitter patch imports `Tile`, `Bond`, and `Region` directly from `Common/StarSpec.agda` — the **same types** used by the {5,4} star bridge. Since the restricted star topology has the same 5 bonds, the same 10 representative regions, and the same min-cut values S(k) = min(k, 5−k), the bridge equivalence is **literally the same Agda term** for both curvature regimes.

The `GenericBridge` module ([`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md)) depends on exactly four inputs: a region type, two observable functions (S∂ and LB), and a path between them. It never inspects curvature, vertex classification, face valence, or tiling parameters. The bridge is **geometrically blind**.

This means:

- **No new `Spec` module** — `Common/StarSpec.agda` is reused.
- **No new `Cut` module** — `Boundary/StarCut.agda` is reused.
- **No new `Chain` module** — `Bulk/StarChain.agda` is reused.
- **No new `Obs` module** — `Bridge/StarObs.agda` is reused.
- **No new `Equiv` module** — the `BridgeWitness` from `Bridge/GenericValidation.agda` (`star-generic-witness`) is reused.
- **No new `Dynamics` modules** — `Bridge/StarStepInvariance.agda`, `Bridge/StarDynamicsLoop.agda`, and `Bridge/EnrichedStarStepInvariance.agda` are all reused (they depend on the bond-weight parameterization, not on curvature).

The **only** new Agda content for the dS instance is:

1. `Bulk/DeSitterPatchComplex.agda` — the {5,3} vertex classification (3 classes, 15 vertices)
2. `Bulk/DeSitterCurvature.agda` — κ per vertex class, with positive interior κ = +1/10
3. `Bulk/DeSitterGaussBonnet.agda` — dS Gauss–Bonnet: Σκ = χ = 1 by `refl`
4. `Bridge/WickRotation.agda` — the coherence record packaging both GB witnesses with the shared bridge

### 6.2 The Shared Bridge Witness

```agda
-- Bridge/WickRotation.agda
the-bridge : BridgeWitness
the-bridge = star-generic-witness
-- Produced by GenericEnriched applied to starPatchData.
-- Never references curvature.
```

---

## 7. Min-Cut / Observable Agreement Table

Because the dS patch reuses the star patch's `Region`, `S-cut`, and `L-min`, the agreement table is **identical** to the star patch's:

| Region | Tiles | S\_cut | L\_min | S = L? |
|--------|-------|--------|--------|--------|
| regN0 | {N₀} | 1 | 1 | ✓ `refl` |
| regN1 | {N₁} | 1 | 1 | ✓ `refl` |
| regN2 | {N₂} | 1 | 1 | ✓ `refl` |
| regN3 | {N₃} | 1 | 1 | ✓ `refl` |
| regN4 | {N₄} | 1 | 1 | ✓ `refl` |
| regN0N1 | {N₀, N₁} | 2 | 2 | ✓ `refl` |
| regN1N2 | {N₁, N₂} | 2 | 2 | ✓ `refl` |
| regN2N3 | {N₂, N₃} | 2 | 2 | ✓ `refl` |
| regN3N4 | {N₃, N₄} | 2 | 2 | ✓ `refl` |
| regN4N0 | {N₄, N₀} | 2 | 2 | ✓ `refl` |

**Formula:** S(k tiles) = min(k, 5 − k) for a contiguous region of k tiles on the 5-tile cyclic boundary.

**Numerical verification:** All 10 representative regions verified by `sim/prototyping/10_desitter_prototype.py` — 10/10 min-cut values match the {5,4} star exactly.

---

## 8. The WickRotationWitness — Theorem 4

The `WickRotationWitness` record in `Bridge/WickRotation.agda` packages three independently verified components:

```agda
-- Bridge/WickRotation.agda
record WickRotationWitness : Type₁ where
  field
    shared-bridge      : BridgeWitness
    ads-gauss-bonnet   : GaussBonnetWitness
    ds-gauss-bonnet    : DSGaussBonnetWitness
    euler-coherence    : GaussBonnetWitness.eulerChar₁₀ ads-gauss-bonnet
                       ≡ DSGaussBonnetWitness.eulerChar₁₀ ds-gauss-bonnet

wick-rotation-witness : WickRotationWitness
wick-rotation-witness .shared-bridge    = star-generic-witness
wick-rotation-witness .ads-gauss-bonnet = patch-gb-witness
wick-rotation-witness .ds-gauss-bonnet  = ds-patch-gb-witness
wick-rotation-witness .euler-coherence  = refl
```

**Component 1** (`shared-bridge`): The curvature-agnostic holographic bridge, produced by the generic bridge machinery from `Bridge/GenericBridge.agda`. This carries the full enriched type equivalence, Univalence path, and verified transport.

**Component 2** (`ads-gauss-bonnet`): The AdS Gauss–Bonnet witness from `Bulk/GaussBonnet.agda` — discrete Gauss–Bonnet for the {5,4} tiling with negative interior curvature κ = −1/5.

**Component 3** (`ds-gauss-bonnet`): The dS Gauss–Bonnet witness from `Bulk/DeSitterGaussBonnet.agda` — discrete Gauss–Bonnet for the {5,3} tiling with positive interior curvature κ = +1/10.

**Coherence** (`euler-coherence`): Both patches target the same Euler characteristic χ = 1 (encoded as one₁₀ = pos 10 in ℚ₁₀). The proof is `refl` because both `χ₁₀` and `dsχ₁₀` are defined as `one₁₀` in their respective modules.

---

## 9. Why Complex Numbers Are Not Needed

The physics Wick rotation L\_dS = *i* · L\_AdS multiplies a length by the imaginary unit. In the discrete setting, this operation has **no analogue and no function**:

1. **No metric signature.** The "metric" is a weight function on bonds, always positive (ℕ-valued). There is no timelike/spacelike distinction to rotate.
2. **No analytic continuation.** All functions are defined by finite case splits on concrete constructors, not by holomorphic extension.
3. **The curvature sign change is achieved by changing the tiling parameter** *q* from 4 to 3 — a change of combinatorial input, not a complex rotation.
4. **The observable values are identical.** The min-cut values for both patches are the same ℕ literals (1 and 2). There is nothing to multiply by *i*.

The `Util/ComplexNumbers.agda` module conjectured in early project metadata is therefore **not required**.

---

## 10. Scalar Representation

The dS curvature modules use `ℚ₁₀ = ℤ` from `Util/Rationals.agda`:

| Rational | Tenths | ℤ constructor | Agda name | Used for |
|----------|--------|---------------|-----------|----------|
| +1/10 | +1 | `pos 1` | `pos1/10` | Interior curvature (dsTiling) |
| −1/10 | −1 | `negsuc 0` | `neg1/10` | Shared boundary (dsSharedW) |
| +1/5 | +2 | `pos 2` | `pos1/5` | Outer boundary (dsOuterB) |
| 1 | 10 | `pos 10` | `one₁₀` | Euler characteristic χ₁₀ |

All constants are imported from `Util/Rationals.agda` — never reconstructed locally. This maintains the judgmental stability required for `refl`-based proofs.

The bridge modules continue to use `ℚ≥0 = ℕ` from `Util/Scalars.agda` for the observable values (1q, 2q) — unchanged from the star patch.

---

## 11. Module Inventory

| Module | Lines | Content | New for dS? |
|--------|-------|---------|-------------|
| `Common/StarSpec.agda` | ~90 | `Tile`, `Bond`, `Region`, `StarSpec`, `starSpec`, `starWeight` | **No** — reused |
| `Boundary/StarCut.agda` | ~85 | `BoundaryView`, `π∂`, `S-cut` (10-clause lookup) | **No** — reused |
| `Bulk/StarChain.agda` | ~85 | `BulkView`, `πbulk`, `L-min` (10-clause lookup) | **No** — reused |
| `Bridge/StarObs.agda` | ~50 | `star-pointwise` (10 refls), `Obs∂`, `ObsBulk` | **No** — reused |
| `Bridge/GenericValidation.agda` | ~200 | `star-generic-witness : BridgeWitness` | **No** — reused |
| `Bulk/DeSitterPatchComplex.agda` | ~300 | `DSVClass` (3 ctors), `DSVertex` (15 ctors), topology | **Yes** |
| `Bulk/DeSitterCurvature.agda` | ~250 | `dsκ-class`, `dsTotalCurvature`, `dsTotalCurvature≡χ = refl` | **Yes** |
| `Bulk/DeSitterGaussBonnet.agda` | ~250 | `DSGaussBonnetWitness`, `ds-patch-gb-witness`, `DSTheorem1` | **Yes** |
| `Bridge/WickRotation.agda` | ~300 | `WickRotationWitness`, `wick-rotation-witness`, curvature sign witnesses | **Yes** |

**Total new Agda content:** ~1,100 lines across 4 hand-written modules.

**Total reused content:** ~510 lines across 5 modules (the entire star bridge infrastructure).

The reuse ratio is the architectural content of the claim that the holographic correspondence is curvature-agnostic: 5 modules worth of bridge infrastructure serve both curvature regimes without modification.

---

## 12. What the De Sitter Patch Validates

The dS patch exercises several capabilities not tested by any other instance:

| Step | What it tests | First exercised? |
|------|---------------|-----------------|
| Positive interior curvature | κ = +1/10 (spherical — the opposite sign from {5,4}) | **Yes** |
| Curvature-agnostic bridge | Same `BridgeWitness` for both κ < 0 and κ > 0 | **Yes** |
| `WickRotationWitness` coherence record | Packages shared bridge + two GB witnesses | **Yes** |
| Symmetric interior/boundary decomposition | Interior = boundary = +1/2 (unique to dS) | **Yes** |
| No gap-filler tiles | {5,3} has 0 gap-fillers (vs 5 for {5,4}) | **Yes** |
| 3-class vertex classification | Only 3 vertex classes (vs 5 for {5,4}) | **Yes** |
| Flow-graph reuse across tilings | Same `Tile`, `Bond`, `Region` types for both tilings | **Yes** |
| `euler-coherence = refl` | Both tilings target the same χ₁₀ = one₁₀ | **Yes** |
| Numerical verification on {5,3} | Python prototype confirms all 10 min-cuts match {5,4} | **Yes** |

---

## 13. What the De Sitter Patch Does NOT Exercise

- **Orbit reduction.** The dS patch has only 10 regions — far below the threshold (~500) where orbit reduction is needed. Orbit reduction is first used by Dense-100 ([`instances/dense-100.md`](dense-100.md)).

- **`abstract` barrier.** No large case analysis is needed. The `abstract` pattern is first used by the filled patch ([`instances/filled-patch.md`](filled-patch.md)).

- **Auto-generated modules.** All dS modules are hand-written. The Python oracle + `abstract` barrier pattern is used by the filled and Dense patches.

- **3D geometry.** The dS patch is 2D. The 3D extension is exercised by the honeycomb patches ([`instances/honeycomb-3d.md`](honeycomb-3d.md), [`instances/dense-100.md`](dense-100.md)).

- **Area law / Bekenstein–Hawking bound.** These are verified on the Dense patches ([`instances/dense-100.md`](dense-100.md), [`instances/dense-200.md`](dense-200.md)).

- **Gauge connections / quantum superposition / dynamics.** These enrichment layers are exercised on the 6-tile star patch ([`instances/star-patch.md`](star-patch.md)), which shares the same `Bond` and `Region` types.

- **Causal structure.** The causal diamond and NoCTC theorem operate on the SchematicTower infrastructure.

---

## 14. Numerical Verification

All curvature values, Gauss–Bonnet sums, and min-cut comparisons were verified numerically before formalization by the Python prototype `10_desitter_prototype.py`:

| Check | Result |
|-------|--------|
| Bond graph isomorphic to {5,4} star (restricted) | ✓ All 10 min-cut values match |
| Euler characteristic χ = 1 (disk) | ✓ 15 − 20 + 6 = 1 |
| Interior curvature κ = +1/10 (positive) | ✓ |
| Gauss–Bonnet: Σκ(v) = χ(K) = 1 | ✓ By `refl` on ℤ arithmetic |
| ℚ₁₀ encoding: all values have denominators dividing 10 | ✓ |
| All 10 flow-graph min-cuts match {5,4} star | ✓ (zero mismatches) |

**Key output from the prototype (§3 of `10_desitter_prototype_OUTPUT.txt`):**

```
  ── §3.  Min-Cut Analysis (Restricted Star Topology) ──

  ✓  ALL 10 min-cut values match the {5,4} star EXACTLY!
     The existing Bridge modules can be reused without modification.
```

---

## 15. Comparison: {5,3} dS vs {5,4} AdS

| Property | {5,4} (AdS) | {5,3} (dS) | Changes? |
|----------|-------------|------------|----------|
| Tile type | Pentagons (p = 5) | Pentagons (p = 5) | No |
| Vertex valence | **q = 4** | **q = 3** | **Yes** |
| Gap-filler tiles | **5** (G₀…G₄) | **0** | **Yes** |
| Bond graph (restricted star) | 5 C–N bonds | 5 C–N bonds | No |
| Region type | `Region` (10 ctors) | `Region` (10 ctors) | No |
| Min-cut values | S(k) = min(k, 5−k) | S(k) = min(k, 5−k) | No |
| Interior curvature sign | **κ < 0** (negative) | **κ > 0** (positive) | **Yes** |
| Interior curvature value | −1/5 (−2/10) | **+1/10** (+1/10) | **Yes** |
| Euler characteristic | χ = 1 | χ = 1 | No |
| Gauss–Bonnet total | Σκ = 1 | Σκ = 1 | No |
| Interior/boundary split | −1 / +2 (asymmetric) | **+1/2 / +1/2 (symmetric)** | **Yes** |
| Bridge equivalence | `star-generic-witness` | **Same** `star-generic-witness` | No |
| Transport | `enriched-transport` | **Same** `enriched-transport` | No |
| Vertex classes | 5 | **3** | **Yes** |
| Polygon complex vertices | 30 | **15** | **Yes** |

The "Wick rotation" is a parameter change (q = 4 → q = 3) that flips the curvature sign while preserving the flow graph and all holographic observables.

---

## 16. Historical Significance

The dS patch was developed as Direction E of the frontier extensions (§7 of `historical/development-docs/10-frontier.md`). The key CS insight (§7.3) was that the holographic bridge depends only on the **flow-graph topology**, not on the curvature:

> "If two patches with opposite curvature signs share the same flow-graph topology, they produce identical observable packages, and the same bridge equivalence serves both."

The Python prototype (`10_desitter_prototype.py`) confirmed this with all 10 min-cut values matching between {5,3} and {5,4}. The Agda formalization then required only 4 new hand-written modules (the curvature infrastructure + the coherence record), while the entire bridge infrastructure (5 modules, ~510 lines) was reused unchanged.

This is the structural content of the statement "gravity may partly be a macroscopic readout of microscopic entanglement" — formalized not as a claim about continuum spacetimes, but as a machine-checked proof that the combinatorial structure of the holographic correspondence is independent of the sign of curvature.

---

## 17. Conceptual Architecture

```
                      ┌────────────────────────┐
                      │  Common/StarSpec.agda  │
                      │  (Tile, Bond, Region)  │
                      └───────────┬────────────┘
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
                  │ (Theorem 1)    │
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
                  │ (Theorem 4)    │
                  │                │
                  │  Witnesses:    │
                  │  • AdS GB      │
                  │  • dS GB       │
                  │  • Shared      │
                  │    bridge      │
                  │    (generic!)  │
                  └────────────────┘
```

The bridge sits at the center, shared by both curvature regimes. It is produced once by `GenericBridge.agda` and validated by `GenericValidation.agda`. The two Gauss–Bonnet theorems attach independently to opposite sides. The Wick Rotation module witnesses their coherence.

---

## 18. Relationship to Other Instances

| Instance | What it adds beyond the dS patch |
|----------|----------------------------------|
| **Tree pilot** ([tree-pilot.md](tree-pilot.md)) | Architecture validation only (1D, no curvature) |
| **Star (6-tile)** ([star-patch.md](star-patch.md)) | Nontrivial enriched equiv, dynamics, gauge, quantum — **shares** the dS bridge |
| **Filled (11-tile)** ([filled-patch.md](filled-patch.md)) | Gauss–Bonnet for {5,4} (negative curvature, 5 vertex classes) |
| **Honeycomb (3D)** ([honeycomb-3d.md](honeycomb-3d.md)) | 3D dimension, edge curvature |
| **Dense-50** ([dense-50.md](dense-50.md)) | Dense growth, min-cut range 1–7 |
| **Dense-100** ([dense-100.md](dense-100.md)) | Orbit reduction (717 → 8), area law, half-bound |
| **Dense-200** ([dense-200.md](dense-200.md)) | Third tower level, monotonicity 8 → 9 |
| **Layer-54 tower** ([layer-54-tower.md](layer-54-tower.md)) | 6 BFS depths, exponential growth, constant orbit count |
| **De Sitter patch** (this) | **Positive curvature, curvature-agnostic bridge, Wick rotation** |

The dS patch's relationship to the star patch is unique in the repository: it is the **only** instance that shares the bridge types, functions, and proofs with another instance (the {5,4} star) while differing in geometric structure. This sharing is the formal content of the curvature-agnosticism claim. Every other pair of instances has distinct region types and distinct observable functions.

---

## 19. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) — Theorem 4 |
| HoTT foundations (refl, funExt, ua, transport) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Holographic bridge (curvature-agnostic) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Discrete geometry (curvature, Gauss–Bonnet) | [`formal/04-discrete-geometry.md`](../formal/04-discrete-geometry.md) |
| Wick rotation (formal treatment) | [`formal/08-wick-rotation.md`](../formal/08-wick-rotation.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Generic bridge pattern (engineering) | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Star patch (shared bridge) | [`instances/star-patch.md`](star-patch.md) |
| Filled patch (AdS curvature target) | [`instances/filled-patch.md`](filled-patch.md) |
| Holographic dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Translation problem (five walls) | [`physics/five-walls.md`](../physics/five-walls.md) |
| Three hypotheses (emergent / phase transition / discrete) | [`physics/three-hypotheses.md`](../physics/three-hypotheses.md) |
| Numerical verification (Python) | `sim/prototyping/10_desitter_prototype.py` |
| Numerical verification output | `sim/prototyping/10_desitter_prototype_OUTPUT.txt` |
| Historical development (§7 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §7 |
| Building & type-checking | [`getting-started/building.md`](../getting-started/building.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |