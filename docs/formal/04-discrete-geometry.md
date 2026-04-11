# Discrete Geometry

**Formal content:** Polygon complexes, combinatorial curvature, discrete Gauss–Bonnet theorem, 3D edge curvature, curvature across tilings and dimensions.

**Primary modules:** `Bulk/PatchComplex.agda`, `Bulk/Curvature.agda`, `Bulk/GaussBonnet.agda`, `Bulk/DeSitterPatchComplex.agda`, `Bulk/DeSitterCurvature.agda`, `Bulk/DeSitterGaussBonnet.agda`, `Bulk/Honeycomb3DCurvature.agda`, `Bulk/Dense{50,100,200}Curvature.agda`

**Prerequisites:** [02-foundations.md](02-foundations.md) (HoTT background), [01-theorems.md](01-theorems.md) (theorem registry)

---

## 1. Overview

The discrete geometry layer provides the bulk-side structural foundation for the holographic correspondence. It encodes finite polygon and cell complexes as Cubical Agda types, defines combinatorial curvature as a rational-valued function on vertices (2D) or edges (3D), and proves the discrete Gauss–Bonnet theorem: the total curvature equals the Euler characteristic.

This is **Theorem 2** in the canonical registry ([01-theorems.md](01-theorems.md)) — the first independently publishable formalization result of the project, corresponding to **Milestone 1** of the roadmap (§6.9 of `historical/development-docs/06-challenges.md`).

The geometry layer is **orthogonal to the holographic bridge**: the bridge ([03-holographic-bridge.md](03-holographic-bridge.md)) depends only on the flow-graph topology (min-cut values), not on curvature. Curvature enriches the bulk with geometric content — negative for AdS-like ({5,4}) patches, positive for dS-like ({5,3}) patches — but the bridge equivalence is literally the same Agda term in both regimes. This orthogonality is the structural content of the discrete Wick rotation ([08-wick-rotation.md](08-wick-rotation.md)).

---

## 2. The Scalar Representation: ℚ₁₀ = ℤ

Curvature values for pentagonal tilings have denominators dividing 10. Rather than formalizing full constructive rationals (which would require quotient-type reasoning), the repository uses a minimal exact representation:

> The integer *n* : ℤ represents the rational *n*/10.

This is `ℚ₁₀ = ℤ` from `Util/Rationals.agda`. All arithmetic — addition `_+₁₀_`, negation `-₁₀_`, ℕ-scalar multiplication `_·₁₀_` — inherits from the cubical library's ℤ operations, which compute by structural recursion on closed constructor terms. This guarantees that identical expressions normalize to identical ℤ values, enabling all Gauss–Bonnet sums to be discharged by `refl`.

Named curvature constants are defined **once** in `Util/Rationals.agda` and imported everywhere:

| Rational | Tenths | ℤ constructor | Agda name |
|----------|--------|---------------|-----------|
| −1/5 | −2 | `negsuc 1` | `neg1/5` |
| −1/10 | −1 | `negsuc 0` | `neg1/10` |
| 0 | 0 | `pos 0` | `zero₁₀` |
| +1/10 | +1 | `pos 1` | `pos1/10` |
| +1/5 | +2 | `pos 2` | `pos1/5` |
| 1 | 10 | `pos 10` | `one₁₀` |

The judgmental stability guarantee (identical constants have identical normal forms) is the same principle used for the bridge proofs — §11.5 of `historical/development-docs/08-tree-instance.md`.

---

## 3. The 11-Tile {5,4} Polygon Complex

### 3.1 Patch Composition

The primary curvature target is the 11-tile filled patch of the {5,4} hyperbolic pentagonal tiling:

- **1 central pentagon** C with vertices v₀ … v₄
- **5 edge-neighbour pentagons** N₀ … N₄, where Nᵢ shares edge (vᵢ, vᵢ₊₁) with C
- **5 gap-filler pentagons** G₀ … G₄, where Gᵢ sits at vertex vᵢ between Nᵢ₋₁ and Nᵢ

This is the smallest {5,4} patch forming a proper manifold with boundary, having 5 interior vertices at full valence 4 and exhibiting genuine negative curvature.

### 3.2 Topological Counts

| Count | Value | Computation |
|-------|-------|-------------|
| Vertices (V) | 30 | 5 + 15 + 10 (tiling + N-new + G-new) |
| Edges (E) | 40 | 15 internal + 25 boundary |
| Faces (F) | 11 | all regular pentagons |
| Euler (χ) | 1 | 30 − 40 + 11 = 1 (disk) |

Since ℕ has no subtraction, the Euler identity is stated additively:

```agda
-- Bulk/PatchComplex.agda
euler-char : totalV + totalF ≡ totalE + 1
euler-char = refl     -- 30 + 11 = 41 = 40 + 1
```

### 3.3 Vertex Classification (Strategy A)

Rather than enumerating all 30 vertices individually (which would require 30-way pattern matches), vertices are grouped into 5 classes by combinatorial neighbourhood. Curvature is constant within each class:

```agda
-- Bulk/PatchComplex.agda
data VClass : Type₀ where
  vTiling  : VClass    -- v₀…v₄    (5 interior, valence 4)
  vSharedA : VClass    -- a₀…a₄    (5 boundary, shared N/G)
  vOuterB  : VClass    -- b₀…b₄    (5 boundary, N-only)
  vSharedC : VClass    -- c₀…c₄    (5 boundary, shared N/G)
  vOuterG  : VClass    -- g₀₁…g₄₂  (10 boundary, G-only)
```

The classification function `classify : Vertex → VClass` is a 30-clause pattern match mapping each named vertex to its class. Downstream proofs operate on the 5-constructor `VClass` type, not on the 30-constructor `Vertex` type.

### 3.4 Incidence Data

The polygon complex stores face-vertex incidence as an explicit lookup:

```agda
-- Bulk/PatchComplex.agda
faceVertices : PatchFace → Pentagon
faceVertices fC  = v₀ , v₁ , v₂ , v₃ , v₄
faceVertices fN₀ = v₀ , v₁ , a₀ , b₀ , c₀
faceVertices fG₀ = v₀ , a₄ , g₀₁ , g₀₂ , c₀
-- ... (11 clauses total)
```

Consistency is verified by machine-checked regression tests:

- **Handshaking:** Σ (count · edgeDeg) = 2 · totalE (verified by `refl`)
- **Face-incidence:** Σ (count · faceValence) = totalF · faceSides (verified by `refl`)
- **Count decomposition:** sum of class counts = totalV (verified by `refl`)

---

## 4. Combinatorial Curvature

### 4.1 The Formula

The combinatorial curvature at a vertex v of a polyhedral cell complex is:

> κ(v) = 1 − deg_E(v)/2 + Σ_{f ∋ v} 1/sides(f)

This formula satisfies the combinatorial Gauss–Bonnet theorem Σᵥ κ(v) = χ(K) for **any** polyhedral complex K, automatically accounting for boundary effects through the reduced degree and face count of boundary vertices. No separate boundary term is needed.

### 4.2 Curvature per Vertex Class

In the ℚ₁₀ encoding (tenths), multiplying through by 10:

> κ₁₀(v) = 10 − 5 · deg(v) + 2 · faceValence(v)

```agda
-- Bulk/Curvature.agda
κ-class : VClass → ℚ₁₀
κ-class vTiling  = neg1/5     -- −2/10:  10 − 5·4 + 2·4 = −2
κ-class vSharedA = neg1/10    -- −1/10:  10 − 5·3 + 2·2 = −1
κ-class vOuterB  = pos1/5     -- +2/10:  10 − 5·2 + 2·1 = +2
κ-class vSharedC = neg1/10    -- −1/10:  10 − 5·3 + 2·2 = −1
κ-class vOuterG  = pos1/5     -- +2/10:  10 − 5·2 + 2·1 = +2
```

A computable formula `κ-formula` is defined independently and verified to agree with the lookup table on all 5 classes by `refl`:

```agda
κ-formula≡κ-class : (cl : VClass) → κ-formula cl ≡ κ-class cl
κ-formula≡κ-class vTiling  = refl
-- ... (5 cases, all refl)
```

### 4.3 Interior Curvature is Negative

The defining characteristic of the {5,4} hyperbolic tiling: at each interior vertex, 4 regular pentagons meet with a total angle of 4 × 108° = 432° > 360°, giving a negative angular deficit of −72° = −2π/5.

In the combinatorial formulation:

```agda
κ-interior-negative : κ-class vTiling ≡ negsuc 1
κ-interior-negative = refl       -- −2 in tenths = −1/5
```

---

## 5. The Discrete Gauss–Bonnet Theorem

### 5.1 The Class-Weighted Sum

The total curvature is computed as a class-weighted sum over the 5 vertex classes:

```agda
-- Bulk/Curvature.agda (computational core)
-- Bulk/GaussBonnet.agda (theorem packaging)

totalCurvature : ℚ₁₀
totalCurvature =
    vCount vTiling  ·₁₀ κ-class vTiling       -- 5·(−2) = −10
  +₁₀ vCount vSharedA ·₁₀ κ-class vSharedA     -- 5·(−1) = −5
  +₁₀ vCount vOuterB  ·₁₀ κ-class vOuterB      -- 5·(+2) = +10
  +₁₀ vCount vSharedC ·₁₀ κ-class vSharedC      -- 5·(−1) = −5
  +₁₀ vCount vOuterG  ·₁₀ κ-class vOuterG       -- 10·(+2) = +20
```

### 5.2 The Proof: `refl`

```agda
discrete-gauss-bonnet : totalCurvature ≡ χ₁₀
discrete-gauss-bonnet = refl
```

The entire left-hand side normalizes judgmentally to `pos 10 = one₁₀ = χ₁₀` because:

1. `vCount` and `κ-class` both reduce by pattern matching on closed constructors.
2. `_·₁₀_` computes by structural recursion on the ℕ argument.
3. `_+₁₀_ = _+ℤ_` computes by structural recursion on closed ℤ terms.
4. All named constants are defined once in `Util/Rationals.agda`, guaranteeing identical normal forms.

The computation trace:

```
(−10) + (−5) + (+10) + (−5) + (+20) = +10 = one₁₀ = χ₁₀
```

### 5.3 Interior/Boundary Decomposition

The total curvature decomposes into an interior contribution and a boundary contribution, making the geometric structure visible:

| Component | Value (tenths) | Rational | Interpretation |
|-----------|---------------|----------|----------------|
| Interior (5 tiling vertices) | −10 | −1 | Strong negative curvature (hyperbolic) |
| Boundary (25 other vertices) | +20 | +2 | Positive boundary turning |
| **Total** | **+10** | **1** | **χ(K) = 1** |

```agda
totalCurvature-split :
  totalCurvature ≡ interiorCurvature +₁₀ boundaryCurvature
totalCurvature-split = refl

interior+boundary≡χ :
  interiorCurvature +₁₀ boundaryCurvature ≡ χ₁₀
interior+boundary≡χ = refl
```

### 5.4 The GaussBonnetWitness Record

All data and proofs are packaged into a single inspectable milestone artifact:

```agda
-- Bulk/GaussBonnet.agda
record GaussBonnetWitness : Type₀ where
  field
    V E F          : ℕ
    euler-identity : V + F ≡ E + 1
    curvatureSum   : ℚ₁₀
    eulerChar₁₀    : ℚ₁₀
    gauss-bonnet   : curvatureSum ≡ eulerChar₁₀

patch-gb-witness : GaussBonnetWitness
-- All fields filled from PatchComplex and Curvature modules
```

---

## 6. The {5,3} De Sitter Patch

### 6.1 Patch Structure

The 6-face star patch of the {5,3} tiling (regular dodecahedron) consists of a central pentagon C and its 5 edge-neighbours N₀…N₄ — **no gap-filler tiles needed**, because in {5,3} only 3 pentagons meet at each vertex, and the star patch already saturates every interior vertex.

| Property | {5,4} (AdS) | {5,3} (dS) |
|----------|-------------|------------|
| Tiles | 11 | 6 |
| Gap-fillers | 5 (G₀…G₄) | 0 |
| Vertices | 30 | 15 |
| Edges | 40 | 20 |
| Vertex classes | 5 | 3 |
| Interior valence | 4 | 3 |
| Interior curvature | −1/5 | **+1/10** |
| Euler characteristic | 1 | 1 |

### 6.2 Positive Interior Curvature

The defining characteristic of the spherical (de Sitter) regime:

```agda
-- Bulk/DeSitterCurvature.agda
dsκ-class : DSVClass → ℚ₁₀
dsκ-class dsTiling  = pos1/10    -- +1/10 (POSITIVE — spherical!)
dsκ-class dsSharedW = neg1/10    -- −1/10
dsκ-class dsOuterB  = pos1/5     -- +2/10

dsκ-interior-positive : dsκ-class dsTiling ≡ pos 1
dsκ-interior-positive = refl
```

At each interior vertex, 3 regular pentagons contribute 3 × 108° = 324° < 360°, giving a **positive** angular deficit of +36° = π/5. This is the combinatorial analogue of the cosmological constant sign flip Λ_AdS < 0 → Λ_dS > 0.

### 6.3 dS Gauss–Bonnet: Symmetric Decomposition

```agda
-- Bulk/DeSitterGaussBonnet.agda
ds-discrete-gauss-bonnet : dsTotalCurvature ≡ dsχ₁₀
ds-discrete-gauss-bonnet = refl

dsSymmetricSplit : dsInteriorCurv ≡ dsBoundaryCurv
dsSymmetricSplit = refl     -- both = pos 5 (= +5/10 = +1/2)
```

The dS decomposition is **symmetric**: interior = boundary = +1/2. Contrast with the AdS decomposition: interior = −1, boundary = +2. Both sum to χ = 1, but the distribution differs — reflecting the physics that positive cosmological curvature distributes evenly, while negative curvature creates a strong interior deficit compensated by large boundary turning.

---

## 7. 3D Edge Curvature ({4,3,5} Honeycomb)

### 7.1 Curvature on Edges, Not Vertices

In 3 dimensions, the combinatorial curvature lives on **edges** (not vertices). At an interior edge e of a polyhedral 3-complex with valence v (number of cells meeting at the edge):

> κ(e) = 2π − v · (dihedral angle of cell)

For the {4,3,5} honeycomb (5 cubes at every edge, dihedral angle π/2):

> κ(e) = 2π − 5 · π/2 = −π/2

This negative edge deficit confirms the hyperbolic character of the honeycomb.

### 7.2 Combinatorial Encoding

The 3D curvature is encoded in twentieths (via ℚ₁₀ = ℤ) to avoid fractions:

> κ₂₀(e) = 20 − 5 · v

| Valence v | κ₂₀ | Interpretation |
|-----------|------|----------------|
| 5 | −5 | Hyperbolic (full {4,3,5} condition) |
| 4 | 0 | Flat (Euclidean) |
| 3 | +5 | Boundary |
| 2 | +10 | Boundary |

### 7.3 Per-Patch Edge Classes

Each Dense patch has its 12 central-cube edges classified by in-patch valence. For the Dense-100 patch (100 cells, all 12 edges fully surrounded):

```agda
-- Bulk/Dense100Curvature.agda
data D100EdgeClass : Type₀ where
  ev5 : D100EdgeClass          -- all 12 edges at full valence 5

d100Kappa : D100EdgeClass → ℚ₁₀
d100Kappa ev5 = negsuc 4        -- κ₂₀ = −5

totalD100Curvature-check : totalD100Curvature ≡ negsuc 59
totalD100Curvature-check = refl  -- 12 · (−5) = −60
```

The total edge curvature sum is verified by `refl` for each patch because all operations (class count, κ-class lookup, scalar multiplication, ℤ addition) compute by structural recursion on closed terms.

---

## 8. Curvature Across the Repository

The curvature formalization spans 2D and 3D, across three curvature regimes:

| Patch | Tiling | Dim | Interior κ | Total κ | χ | Module |
|-------|--------|-----|-----------|---------|---|--------|
| 11-tile filled | {5,4} | 2D | −1/5 (vertex) | 1 | 1 | `Bulk/GaussBonnet.agda` |
| 6-face star | {5,3} | 2D | +1/10 (vertex) | 1 | 1 | `Bulk/DeSitterGaussBonnet.agda` |
| Dense-50 | {4,3,5} | 3D | −5/20 (edge) | −60/20 | — | `Bulk/Dense50Curvature.agda` |
| Dense-100 | {4,3,5} | 3D | −5/20 (edge) | −60/20 | — | `Bulk/Dense100Curvature.agda` |
| Dense-200 | {4,3,5} | 3D | −5/20 (edge) | −60/20 | — | `Bulk/Dense200Curvature.agda` |
| Honeycomb BFS | {4,3,5} | 3D | mixed | mixed | — | `Bulk/Honeycomb3DCurvature.agda` |

All curvature sum verifications are discharged by `refl`. The 2D theorems target the Euler characteristic (disk topology, χ = 1); the 3D curvature sums are recorded as regression tests but are not yet packaged into a 3D Gauss–Bonnet theorem (which would require formalizing the 3D Euler characteristic for cell complexes with boundary).

---

## 9. Relationship to the Holographic Bridge

### 9.1 Geometric Blindness of the Bridge

The bridge construction ([03-holographic-bridge.md](03-holographic-bridge.md)) depends on **exactly four inputs**: a region type, two observable functions (S∂ and LB), and a path between them. It never references curvature, vertex classification, face valence, or tiling parameters.

This blindness is not a weakness — it is a structural fact. The bridge operates on the flow graph (bond weights and min-cuts); the curvature operates on the polygon/cell complex (vertex degrees and face counts). The two structures coexist on the same geometric substrate but are logically independent.

### 9.2 The Wick Rotation Coherence

The `WickRotationWitness` record ([08-wick-rotation.md](08-wick-rotation.md)) packages:

- One shared bridge (curvature-agnostic, from `GenericBridge.agda`)
- Two curvature witnesses (AdS: κ < 0, dS: κ > 0)
- A coherence proof (`euler-coherence : χ₁₀ ≡ dsχ₁₀`, which is `refl`)

The curvature sign flip is a parameter change in the tiling type (q = 4 → q = 3), not a complex rotation. The bridge is literally the same Agda term for both regimes — the curvature enriches the topology without constraining it.

---

## 10. Numerical Verification

All curvature values and Gauss–Bonnet sums were verified numerically before formalization by the Python prototypes:

| Script | Verified |
|--------|----------|
| `02_happy_patch_curvature.py` | {5,4} combinatorial, angular, and Regge curvature; all three Gauss–Bonnet formulations |
| `10_desitter_prototype.py` | {5,3} curvature values, Gauss–Bonnet, ℚ₁₀ encoding |
| `06_generate_honeycomb_3d.py` | {4,3,5} 3D edge curvature classes |
| `08_generate_dense50.py` | Dense-50 edge curvature |
| `09_generate_dense100.py` | Dense-100 edge curvature |
| `12_generate_dense200.py` | Dense-200 edge curvature |

The Python oracles serve as the search engine; Agda is the checker. The curvature values are emitted as Agda constants and verified by `refl` during type-checking.

---

## 11. Design Decisions

1. **Combinatorial curvature (Option A) over Regge curvature (Option B).** The combinatorial formula requires no trigonometry, no constructive reals, and no angle computation. It is sufficient for Theorem 2 and produces the same Gauss–Bonnet total as the angular formulation. Regge-style metric curvature (requiring law-of-cosines angle computation with rational edge lengths) remains a stretch goal.

2. **Classified vertices over flat enumeration.** The 30-vertex complex is encoded via 5 vertex classes, reducing Gauss–Bonnet to a 5-term weighted sum rather than a 30-term enumeration. This leverages the 5-fold symmetry of the {5,4} tiling and keeps proofs compact.

3. **Lookup table as primary definition.** `κ-class` is a 5-clause lookup; `κ-formula` is a derived verification. Downstream modules depend on the stable lookup, not on the encoding-specific formula.

4. **Constants defined once.** All curvature constants are imported from `Util/Rationals.agda`, never reconstructed locally. This maintains the judgmental stability required for `refl`-based proofs.

5. **2D and 3D curvature in separate modules.** The 2D vertex curvature and 3D edge curvature have different mathematical structures (vertices vs. edges, pentagons vs. cubes) and are kept in separate module hierarchies, connected only through the Wick rotation and the schematic tower.

---

## 12. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all type signatures) | [`formal/01-theorems.md`](01-theorems.md) |
| Holographic bridge (curvature-agnostic) | [`formal/03-holographic-bridge.md`](03-holographic-bridge.md) |
| Wick rotation (dS/AdS coherence) | [`formal/08-wick-rotation.md`](08-wick-rotation.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md) |
| Generic bridge pattern | [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md) |
| Per-instance data sheets | [`instances/`](../instances/) |
| Historical development (curvature plan) | [`historical/development-docs/09-happy-instance.md`](../historical/development-docs/09-happy-instance.md) §4, §13 |