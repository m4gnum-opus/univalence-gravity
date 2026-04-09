# HaPPY Instance

## 1. Purpose

This document records the numerical results of Phase 1.2 prototyping on the
HaPPY code (\(\{5,4\}\) tiling) and fixes the concrete formalization blueprint
for the Agda implementation of Theorems 1–3. It is the direct successor to
[`08-tree-instance.md`](08-tree-instance.md): the tree pilot validated the
bridge **architecture** (common source → views → observable packages →
pointwise agreement → package path); this instance exercises **nontrivial 2D
bulk geometry**, curvature, and the full theorem slate.

Two patches of the \(\{5,4\}\) tiling were prototyped:

- The **6-tile star patch** (C + N0..N4): the primary min-cut / RT
  formalization target for Theorem 3 (Bridge).
- The **11-tile filled patch** (C + N0..N4 + G0..G4): the primary curvature /
  Gauss–Bonnet formalization target for Theorem 1 (Bulk Foundations).

Numerical verification of all Phase 1.2 items (a)–(d) was performed by the
tested Python prototypes
[`01_happy_patch_cuts.py`](../sim/prototyping/01_happy_patch_cuts.py) and
[`02_happy_patch_curvature.py`](../sim/prototyping/02_happy_patch_curvature.py).
Results are recorded in §3–§4. The Agda formalization blueprint occupies §5–§17.

---

## 2. Patch Descriptions

### 2.1 6-Tile Star Patch

The star patch consists of a central pentagon C surrounded by 5
edge-neighbouring pentagons N0..N4. Each N\_i shares exactly one pentagon edge
with C.

**Topology.**

- Tiles: 6 (1 central + 5 neighbours)
- Internal bonds: 5 (C–N0, C–N1, C–N2, C–N3, C–N4)
- Boundary legs per tile: C has 0; each N\_i has 4
- Total boundary legs: 20
- Boundary groups (cyclic): N0(4), N1(4), N2(4), N3(4), N4(4)

```
         N4
          |
    N3 ── C ── N0
        / |
      N2  N1
```

**Limitations.** The star patch is NOT a proper 2D manifold-with-boundary:
there are angular gaps between adjacent N\_i pentagons at each vertex of C.
These gaps are exactly where the gap-filler tiles G\_i of the filled patch sit.
Consequently, the star patch supports min-cut analysis (it has a well-defined
flow graph) but not polygon-level curvature analysis. It is the simplest
connected HaPPY network with a nontrivial central tile and serves as the
stepping stone from the tree pilot to a full 2D instance.

### 2.2 11-Tile Filled Patch

The filled patch completes the star by inserting 5 gap-filler pentagons
G0..G4. Gap-filler G\_i sits at vertex \(v_i\) of the central pentagon,
between \(N_{i-1 \bmod 5}\) and \(N_i\), sharing one pentagon edge with each.

**Topology.**

- Tiles: 11 (1 central + 5 neighbours + 5 gap-fillers)
- Internal bonds: 15 (5 C–N\_i + 5 G\_i–N\_{i−1} + 5 G\_i–N\_i)
- Boundary legs per tile: C has 0; each N\_i has 2; each G\_i has 3
- Total boundary legs: 25
- Boundary groups (cyclic): N0(2), G1(3), N1(2), G2(3), N2(2), G3(3),
  N3(2), G4(3), N4(2), G0(3)

**Polygon complex.**

- Vertices: 30
- Edges: 40
- Faces: 11
- Euler characteristic: \(\chi = 30 - 40 + 11 = 1\) (disk)
- Interior vertices: 5 (the tiling vertices \(v_0 \ldots v_4\) of C)
- Boundary vertices: 25

Each interior vertex \(v_i\) is shared by 4 pentagons (C, \(N_{i-1}\),
\(N_i\), \(G_i\)), giving valence 4 — exactly the \(\{5,4\}\) Schläfli
condition. This is the source of negative curvature: 4 regular pentagons
contribute \(4 \times 108° = 432°\) of angle, exceeding \(360°\) by
\(72° = 2\pi/5\).

**Tile naming conventions (for the polygon complex).**

- Central pentagon C: vertices \(v_0, v_1, v_2, v_3, v_4\) (shared with
  neighbours and gap-fillers)
- Edge-neighbour \(N_i\) shares edge \((v_i, v_{i+1 \bmod 5})\) with C;
  new vertices: \(a_i, b_i, c_i\)
- Gap-filler \(G_i\) shares vertex \(v_i\) with C and edges with
  \(N_{i-1}\) and \(N_i\); new vertices: \(g_{i,1}, g_{i,2}\)

---

## 3. Min-Cut Verification — Phase 1.2(a)

Verified by
[`01_happy_patch_cuts.py`](../sim/prototyping/01_happy_patch_cuts.py).

### 3.1 6-Tile Star Patch

For tile-aligned contiguous boundary regions, the min-cut value depends only on
the number of tiles \(k\) in the region:

\[
S(A) = \min(k, \; 5 - k)
\]

This follows from the star topology: every cut must sever some subset of the 5
central bonds C–N\_i, and the cheapest cut either isolates the \(k\) region
tiles or isolates the \(5 - k\) complement tiles.

**Complete tile-aligned region table (20 regions):**

| Region type | \(k\) | \(S(A)\) | Minimal cut |
|---|---|---|---|
| Single tile \(\{N_i\}\) | 1 | 1 | Bond C–\(N_i\) |
| Adjacent pair \(\{N_i, N_{i+1}\}\) | 2 | 2 | Bonds C–\(N_i\), C–\(N_{i+1}\) |
| Triple \(\{N_i, N_{i+1}, N_{i+2}\}\) | 3 | 2 | Bonds to complement (= pair) |
| Quadruple | 4 | 1 | Bond to excluded tile |

**Properties verified (all 20 regions):**

- Complement symmetry: \(S(A) = S(\bar A)\) ✓
- Subadditivity: \(S(A \cup B) \leq S(A) + S(B)\) for all 30 adjacent
  pairs ✓
- Geodesic bound: \(S(A) \leq \text{internal geodesic length}\) ✓
- **Geodesic equality**: \(S(A) = \text{internal geodesic length}\) for all
  20 regions ✓

The last property is critical: in the 6-tile star, the min-cut always passes
through internal bonds, never through boundary legs. This means the boundary
min-cut (entanglement entropy) exactly equals the bulk internal geodesic
(minimal chain length) for every tile-aligned region.

### 3.2 11-Tile Filled Patch

The min-cut structure is richer due to the alternating N-G boundary pattern.
All 90 nonempty proper tile-aligned contiguous regions were tested.

**Representative subset (one per rotation class):**

| Region | Tiles | \(S(A)\) | Geodesic | \(S =\) geo? |
|---|---|---|---|---|
| \(\{N_0\}\) | 1 | 2 | 3 | **No** |
| \(\{G_1\}\) | 1 | 2 | 2 | Yes |
| \(\{N_0, G_1\}\) | 2 | 3 | 3 | Yes |
| \(\{G_1, N_1\}\) | 2 | 3 | 3 | Yes |
| \(\{N_0, G_1, N_1\}\) | 3 | 4 | 4 | Yes |
| \(\{G_1, N_1, G_2\}\) | 3 | 3 | 3 | Yes |
| \(\{N_0, G_1, N_1, G_2\}\) | 4 | 4 | 4 | Yes |
| \(\{N_0, G_1, N_1, G_2, N_2\}\) | 5 | 4 | 4 | Yes |

**Observation: N-singleton discrepancy.** For N-type singleton regions,
\(S(A) = 2 < 3 = \text{geodesic}\). The min-cut goes through the 2 boundary
legs of \(N_i\) rather than the 3 internal bonds. For G-type singletons,
\(S(A) = 2 = \text{geodesic}\) because G tiles have 3 boundary legs but only 2
internal bonds. For all regions of size ≥ 2, \(S(A) = \text{geodesic}\).

This discrepancy is a concrete finding of Phase 1.2: the discrete RT formula
\(S_{\mathrm{cut}} = L_{\mathrm{min}}\) holds cleanly on the 6-tile star but
requires careful definition of "minimal chain length" on the 11-tile patch. The
6-tile star is therefore the preferred bridge instance.

**Properties verified (all 90 regions):**

- Complement symmetry: \(S(A) = S(\bar A)\) ✓ (90/90)
- Subadditivity: 360 pairs checked, all passed ✓
- Geodesic bound: \(S(A) \leq \text{geodesic}\) ✓ (90/90)

---

## 4. Discrete Curvature — Phase 1.2(b)

Verified by
[`02_happy_patch_curvature.py`](../sim/prototyping/02_happy_patch_curvature.py)
on the 11-tile filled patch.

### 4.1 Combinatorial Curvature

Using the formula

\[
\kappa(v) = 1 - \frac{\deg_E(v)}{2} + \sum_{f \ni v} \frac{1}{\mathrm{sides}(f)}
\]

which satisfies the combinatorial Gauss–Bonnet theorem \(\sum_v \kappa(v) =
\chi(K)\) for any polyhedral cell complex \(K\), automatically accounting for
boundary effects through the reduced degree and face count of boundary
vertices.

| Vertex type | Count | \(\kappa\) (exact) | Int/Bdy | Subtotal |
|---|---|---|---|---|
| Tiling vertex (\(v_i\)) | 5 | \(-1/5\) | Interior | \(-1\) |
| Shared (\(a_i, c_i\)) | 10 | \(-1/10\) | Boundary | \(-1\) |
| Outer N (\(b_i\)) | 5 | \(1/5\) | Boundary | \(1\) |
| Outer G (\(g_{i,j}\)) | 10 | \(1/5\) | Boundary | \(2\) |

**Gauss–Bonnet:**

\[
\sum_v \kappa(v) = (-1) + (-1) + 1 + 2 = 1 = \chi(K) \quad \checkmark
\]

### 4.2 Angular Curvature (Euclidean Pentagon Angles)

Regular pentagon interior angle: \((5-2)\pi/5 = 3\pi/5 = 108°\).

Interior vertices: \(\kappa(v) = 2\pi - \sum \theta\).
Boundary vertices: \(\tau(v) = \pi - \sum \theta\).

| Vertex type | Count | Value (rad) | Value (deg) | Int/Bdy |
|---|---|---|---|---|
| Tiling (\(v_i\)) | 5 | \(\kappa = -2\pi/5\) | \(-72°\) | Interior |
| Shared (\(a_i, c_i\)) | 10 | \(\tau = -\pi/5\) | \(-36°\) | Boundary |
| Outer N (\(b_i\)) | 5 | \(\tau = 2\pi/5\) | \(72°\) | Boundary |
| Outer G (\(g_{i,j}\)) | 10 | \(\tau = 2\pi/5\) | \(72°\) | Boundary |

**Gauss–Bonnet:**

\[
\sum_{\mathrm{int}} \kappa + \sum_{\partial} \tau
= 5\!\left(\!-\frac{2\pi}{5}\right)
  + 10\!\left(\!-\frac{\pi}{5}\right)
  + 5\!\left(\frac{2\pi}{5}\right)
  + 10\!\left(\frac{2\pi}{5}\right)
= -2\pi - 2\pi + 2\pi + 4\pi
= 2\pi = 2\pi\,\chi(K) \quad \checkmark
\]

### 4.3 Regge Curvature (Fan Triangulation)

Fan-triangulating each pentagon (inserting a center vertex connected to all
polygon vertices) produces:

- Vertices: 41 (30 original + 11 centers)
- Edges: 95
- Faces: 55 (11 × 5 triangles)
- \(\chi = 41 - 95 + 55 = 1\) ✓

Pentagon circumradius \(R = 1/(2 \sin(\pi/5)) \approx 0.8507\). Fan triangle
angles: apex \(= 72°\), base \(= 54°\).

Center vertices (O\_\*) have full \(2\pi\) angle sum → \(\kappa = 0\). Original
tiling and boundary vertices retain the same curvature values as the angular
computation.

**Gauss–Bonnet verified** with floating-point error \(< 10^{-14}\).

### 4.4 Summary of Curvature Values

| Vertex type | Combinatorial \(\kappa\) | Angular (rad) | Regge (rad) |
|---|---|---|---|
| Interior tiling (\(v_i\)) | \(-1/5\) | \(-2\pi/5\) | \(-2\pi/5\) |
| Center (O\_\*) [tri only] | — | — | \(0\) |
| Bdy: \(a_i, c_i\) (shared) | \(-1/10\) | \(-\pi/5\) | \(-\pi/5\) |
| Bdy: \(b_i\) (N only) | \(1/5\) | \(2\pi/5\) | \(2\pi/5\) |
| Bdy: \(g_{i,j}\) (G only) | \(1/5\) | \(2\pi/5\) | \(2\pi/5\) |

The \(\{5,4\}\) tiling is hyperbolic: interior vertices have \(\kappa < 0\).
All three formulations (combinatorial, angular, Regge) verify Gauss–Bonnet for
the 11-tile disk patch.

---

## 5. Formalization Strategy

### 5.1 Instance selection

The **6-tile star patch** is the primary bridge formalization target
(Theorem 3), chosen for the following reasons:

- 5 boundary groups → 10 representative regions (manageable case splits)
- Min-cut values in \(\{1, 2\}\) → `ℚ≥0 ≡ ℕ` still works (no scalar upgrade
  needed)
- Bulk structure is a genuine 2D tiling (pentagons), not a 1D tree
- Star topology: simplest connected HaPPY network with a central tile
- Clean RT correspondence: \(S_{\mathrm{cut}} = \text{geodesic}\) for all
  regions (no N-singleton discrepancy)

The **11-tile filled patch** is the primary curvature formalization target
(Theorem 1), chosen because it is the smallest \(\{5,4\}\) patch that forms a
proper disk (no gaps), has interior vertices with full valence 4, exhibits
negative curvature, and supports Gauss–Bonnet with both interior and boundary
terms.

### 5.2 Differences from tree pilot

The HaPPY instance introduces several features absent from the tree:

1. **Tiles as first-class objects.** The tree pilot used vertices and edges
   directly. The HaPPY instance introduces tiles (pentagons) as higher-level
   combinatorial objects, with bonds between tiles replacing edges between
   vertices.

2. **Nontrivial 2D bulk.** The bulk is a polygon complex (11-tile patch) or a
   star-shaped tile network (6-tile star), not a 1-dimensional tree.

3. **Curvature data.** The 11-tile patch supports combinatorial, angular, and
   Regge curvature computations. The tree had no curvature.

4. **5-fold symmetry.** The \(\{5,4\}\) tiling has a rich rotational symmetry
   that can be exploited to reduce proof effort. The tree had only a
   left-right mirror symmetry.

5. **Potential for nontrivial Univalence.** If the observable packages are
   enriched with asymmetric proof-carrying fields (e.g., subadditivity on the
   boundary, Gauss–Bonnet on the bulk), the type equivalence becomes genuinely
   nontrivial and exercises `ua` in a meaningful way (see §12.3).

### 5.3 Scalar representation

For the 6-tile star bridge (Theorem 3), min-cut values are in \(\{1, 2\}\),
so `ℚ≥0 = ℕ` from `Util/Scalars.agda` suffices without modification.

For the 11-tile curvature formalization (Theorem 1), combinatorial curvature
values are exact fractions: \(-1/5, -1/10, 1/5\). This requires upgrading
`Util/Scalars.agda` to a signed rational type (or at minimum, a type
supporting tenths). The upgrade is isolated to the curvature modules and does
not affect the bridge modules. Two strategies are available:

1. **Minimal:** define a custom `Frac₁₀` type supporting only the needed
   fractions (\(-1/5, -1/10, 0, 1/5, 1\)). Verify Gauss–Bonnet as a finite
   sum over this value set.

2. **General:** use `Cubical.HITs.Rationals.QuoQ` or a similar canonical-form
   rational type from the cubical library.

Strategy 1 is recommended for the initial formalization; strategy 2 for the
production version.

---

## 6. Agda-Level Carrier Types (6-Tile Star)

### 6.1 Tiles

```agda
data Tile : Type₀ where
  C N0 N1 N2 N3 N4 : Tile
```

This is preferable to `Fin 6` for the same reasons as the tree pilot: readable
pattern matching, transparent case splits, and deferred equivalences to `Fin`.

### 6.2 Bonds

The 5 internal bonds (tile-to-tile connections through shared pentagon edges):

```agda
data Bond : Type₀ where
  bCN0 bCN1 bCN2 bCN3 bCN4 : Bond
```

An incidence map recovers endpoints:

```agda
endpoints : Bond → Tile × Tile
endpoints bCN0 = C , N0
endpoints bCN1 = C , N1
endpoints bCN2 = C , N2
endpoints bCN3 = C , N3
endpoints bCN4 = C , N4
```

### 6.3 Boundary regions

For the cyclic ordering N0, N1, N2, N3, N4, the nonempty proper contiguous
tile-aligned intervals comprise 5 singletons, 5 adjacent pairs, 5 triples, and
5 quadruples (20 total). By complement symmetry (\(S(A) = S(\bar A)\)):

- triples have the same \(S\) as their complementary pairs,
- quadruples have the same \(S\) as their complementary singletons.

The representative region type therefore consists of the 5 singletons and 5
adjacent pairs:

```agda
data Region : Type₀ where
  regN0   regN1   regN2   regN3   regN4   : Region
  regN0N1 regN1N2 regN2N3 regN3N4 regN4N0 : Region
```

This is 10 constructors (compared to 8 for the tree pilot), covering all
distinct min-cut values and all rotation-distinct region shapes. Triples and
quadruples are omitted because they are complements of pairs and singletons
respectively, and carry the same separating value.

---

## 7. Common Source Specification — Phase 1.2(c)

### 7.1 Record shape

```agda
record StarSpec : Type₀ where
  field
    boundaryOrder : Tile × Tile × Tile × Tile × Tile
    bondWeight    : Bond → ℚ≥0
```

The record is intentionally specialized to the 6-tile star, following the
design principle from the tree pilot: do not over-generalize the source
specification before the bridge architecture has been validated.

### 7.2 Canonical instance

```agda
starWeight : Bond → ℚ≥0
starWeight bCN0 = 1q
starWeight bCN1 = 1q
starWeight bCN2 = 1q
starWeight bCN3 = 1q
starWeight bCN4 = 1q

starSpec : StarSpec
starSpec .StarSpec.boundaryOrder = (N0 , N1 , N2 , N3 , N4)
starSpec .StarSpec.bondWeight    = starWeight
```

All bonds have uniform weight 1, matching the standard HaPPY code where each
shared pentagon edge carries one unit of entanglement capacity.

---

## 8. Extracted Views

### 8.1 Boundary view

The boundary view packages the bond weights interpreted as a boundary-side
entanglement cut system.

```agda
record BoundaryView : Type₀ where
  field
    weight : Bond → ℚ≥0

π∂ : StarSpec → BoundaryView
π∂ c .BoundaryView.weight = StarSpec.bondWeight c
```

### 8.2 Bulk view

The bulk view packages the same bond weights interpreted as a 2D tiling with
tile-to-tile edge weights.

```agda
record BulkView : Type₀ where
  field
    weight : Bond → ℚ≥0

πbulk : StarSpec → BulkView
πbulk c .BulkView.weight = StarSpec.bondWeight c
```

### 8.3 Design note

As with the tree pilot, the two views are distinct wrapper types around the
same weight data. They differ semantically (boundary entanglement vs. bulk
geometry) rather than structurally. The purpose of having two distinct wrapper
types is to validate the **interface contract** before the 11-tile instance
introduces genuinely different view structure (the bulk view would carry face
incidence and curvature data absent from the boundary view).

Both projections from `starSpec` produce the expected constant weight function
(all bonds weight 1). This satisfies Phase 1.2(c).

---

## 9. Observable Functions

### 9.1 Boundary min-cut observable

```agda
S-cut : BoundaryView → Region → ℚ≥0
S-cut bv regN0   = 1q
S-cut bv regN1   = 1q
S-cut bv regN2   = 1q
S-cut bv regN3   = 1q
S-cut bv regN4   = 1q
S-cut bv regN0N1 = 2q
S-cut bv regN1N2 = 2q
S-cut bv regN2N3 = 2q
S-cut bv regN3N4 = 2q
S-cut bv regN4N0 = 2q
```

**Mathematical justification.** Each singleton region \(\{N_i\}\) requires
cutting 1 bond (C–\(N_i\), weight 1). Each adjacent pair \(\{N_i, N_{i+1}\}\)
requires cutting 2 bonds (C–\(N_i\) and C–\(N_{i+1}\), total weight 2). In
general, \(S = \min(k, 5-k)\) for a region of \(k\) tiles.

As with the tree pilot, `S-cut` accepts a `BoundaryView` argument but does not
inspect it: every clause returns a fixed constant from `Util.Scalars`. This is
the specification-level lookup realization for the star instance.

### 9.2 Bulk minimal-chain observable

```agda
L-min : BulkView → Region → ℚ≥0
L-min kv regN0   = 1q
L-min kv regN1   = 1q
L-min kv regN2   = 1q
L-min kv regN3   = 1q
L-min kv regN4   = 1q
L-min kv regN0N1 = 2q
L-min kv regN1N2 = 2q
L-min kv regN2N3 = 2q
L-min kv regN3N4 = 2q
L-min kv regN4N0 = 2q
```

**Mathematical justification.** In the star topology, the minimal separating
chain between a region \(A\) and its complement must sever exactly the bonds
connecting \(A\)'s tiles to C. For a singleton, this is 1 bond (cost 1). For
an adjacent pair, this is 2 bonds (cost 2). In the 6-tile star, the min-cut
always passes through internal bonds (never through boundary legs), so the
min-cut value and the internal geodesic length are equal for all regions.

### 9.3 Why explicit lookup remains correct

The same argument from the tree pilot applies: the goal at this stage is to
validate the package shape, finite indexing, equality proofs, and bridge
construction. Generic min-cut algorithms are a later phase.

---

## 10. Explicit Agreement Table

### 10.1 6-Tile Star (Primary Bridge Target)

| Region \(\mathcal{R}\) | Tiles | Minimal separator | \(S_{\mathrm{cut}}\) | \(L_{\mathrm{min}}\) |
|---|---|---|---|---|
| \(\{N_0\}\) | 1 | Bond C–N₀ | 1 | 1 |
| \(\{N_1\}\) | 1 | Bond C–N₁ | 1 | 1 |
| \(\{N_2\}\) | 1 | Bond C–N₂ | 1 | 1 |
| \(\{N_3\}\) | 1 | Bond C–N₃ | 1 | 1 |
| \(\{N_4\}\) | 1 | Bond C–N₄ | 1 | 1 |
| \(\{N_0, N_1\}\) | 2 | Bonds C–N₀, C–N₁ | 2 | 2 |
| \(\{N_1, N_2\}\) | 2 | Bonds C–N₁, C–N₂ | 2 | 2 |
| \(\{N_2, N_3\}\) | 2 | Bonds C–N₂, C–N₃ | 2 | 2 |
| \(\{N_3, N_4\}\) | 2 | Bonds C–N₃, C–N₄ | 2 | 2 |
| \(\{N_4, N_0\}\) | 2 | Bonds C–N₄, C–N₀ | 2 | 2 |

In every case, **boundary min-cut = bulk minimal chain length**. This is the
discrete Ryu–Takayanagi correspondence for the 6-tile star instance.

### 10.2 11-Tile Filled (Full Verification Reference)

All 90 tile-aligned contiguous regions verified by
[`01_happy_patch_cuts.py`](../sim/prototyping/01_happy_patch_cuts.py).
Min-cut values satisfy \(S(A) = S(\bar A)\), subadditivity (360 pairs), and
\(S(A) \leq \text{geodesic}\). The full output is recorded in
[`01_happy_patch_cuts_OUTPUT.txt`](../sim/prototyping/01_happy_patch_cuts_OUTPUT.txt).

For future formalization of the 11-tile bridge, the N-singleton discrepancy
(§3.2) must be resolved by either restricting the admissible region set to
regions of size ≥ 2, or by defining the bulk observable as the full min-cut
(including boundary bonds) rather than the internal-only geodesic.

---

## 11. Observable Package Shapes — Phase 1.2(d)

### 11.1 Package record

Reusing the same `ObsPackage` record from the tree pilot:

```agda
record ObsPackage (R : Type₀) : Type₀ where
  field
    obs : R → ℚ≥0
```

The region index `R` is a parameter, keeping `ObsPackage Region` in `Type₀`.
This is the same design decision as the tree pilot (see §8.1 of
[08-tree-instance.md](08-tree-instance.md)).

### 11.2 Package construction

```agda
Obs∂ : StarSpec → ObsPackage Region
Obs∂ c .ObsPackage.obs = S-cut (π∂ c)

ObsBulk : StarSpec → ObsPackage Region
ObsBulk c .ObsPackage.obs = L-min (πbulk c)
```

### 11.3 Pointwise agreement

```agda
star-pointwise :
  (r : Region) →
  S-cut (π∂ starSpec) r ≡ L-min (πbulk starSpec) r
star-pointwise regN0   = refl
star-pointwise regN1   = refl
star-pointwise regN2   = refl
star-pointwise regN3   = refl
star-pointwise regN4   = refl
star-pointwise regN0N1 = refl
star-pointwise regN1N2 = refl
star-pointwise regN2N3 = refl
star-pointwise regN3N4 = refl
star-pointwise regN4N0 = refl
```

All 10 cases hold by `refl` because both lookup tables return the same
canonical constants from `Util.Scalars`. The `refl` proofs depend on the same
judgmental stability guarantee as the tree pilot (§11.5 of
[08-tree-instance.md](08-tree-instance.md)): the constants `1q` and `2q` are
defined once in `Util/Scalars.agda` and imported by both the boundary and bulk
modules.

### 11.4 Function and package paths

```agda
star-obs-path : S-cut (π∂ starSpec) ≡ L-min (πbulk starSpec)
star-obs-path = funExt star-pointwise

star-package-path : Obs∂ starSpec ≡ ObsBulk starSpec
star-package-path i .ObsPackage.obs = star-obs-path i
```

This completes Phase 1.2(d) for the 6-tile star instance.

---

## 12. Explicit Proof Obligations

### 12.1 6-Tile Star Bridge (Theorem 3)

In dependency order:

**Step 1: finite carriers.** Define `Tile`, `Bond`, `Region` as explicit
enumerated datatypes. Ensure all case splits normalize cleanly.

**Step 2: scalar constants.** Reuse `0q`, `1q`, `2q` from `Util/Scalars.agda`.
No changes needed.

**Step 3: common source and views.** Define `StarSpec`, `starSpec`,
`starWeight`, `BoundaryView`, `BulkView`, `π∂`, `πbulk`.

**Step 4: observable lookup tables.** Define `S-cut` and `L-min` by explicit
case split (10 cases each).

**Step 5: agreement proof.** Prove `star-pointwise` (10 cases, all `refl`).

**Step 6: function path.** Construct `star-obs-path = funExt star-pointwise`.

**Step 7: package construction and path.** Define `Obs∂`, `ObsBulk`,
`star-package-path`.

**Step 7b (stretch): type-level equivalence.** As with the tree pilot, the
minimal packages produce the same underlying type (`Region → ℚ≥0`), so the
equivalence is `idEquiv` and the `ua` path is trivially `refl`. A nontrivial
`ua` step requires enriched packages (see §12.3).

### 12.2 11-Tile Patch Curvature (Theorem 1)

**Step 1: polygon complex carriers.** Define vertex, edge, and face types for
the 11-tile patch. The 30-vertex set should be organized by classification:

```agda
data VClass : Type₀ where
  vTiling : Fin 5 → VClass      -- v0..v4  (interior)
  vSharedA : Fin 5 → VClass     -- a0..a4  (boundary, shared N/G)
  vOuterB : Fin 5 → VClass      -- b0..b4  (boundary, N only)
  vSharedC : Fin 5 → VClass     -- c0..c4  (boundary, shared N/G)
  vOuterG : Fin 5 → Fin 2 → VClass -- g{i,j} (boundary, G only)
```

Alternatively, a flat 30-constructor datatype if `Fin`-indexed families prove
awkward.

**Step 2: incidence data.** Vertex-edge and vertex-face membership, encoded as
explicit functions or lookup tables.

**Step 3: curvature function.** `κ : Vertex → ℚ` defined by explicit case
split on vertex class (4 distinct values → 4 clauses if using the
classified encoding).

**Step 4: Gauss–Bonnet proof.** \(\sum_v \kappa(v) = \chi(K)\) as a rational
identity. Because the sum is finite and the curvature is constant within each
vertex class, this reduces to:

\[
5 \cdot (-1/5) + 10 \cdot (-1/10) + 5 \cdot (1/5) + 10 \cdot (1/5) = 1
\]

which is a straightforward rational arithmetic identity.

### 12.3 Nontrivial Univalence (Stretch Goal)

The value-level package paths (`tree-package-path`, `star-package-path`) do not
exercise `ua` nontrivially because both sides produce the same underlying type.
To obtain a genuine Univalence bridge, the observable packages should be
enriched with **asymmetric proof-carrying fields**:

**Candidate enrichment for the 6-tile star:**

```agda
record BdyObs (R : Type₀) : Type₀ where
  field
    obs   : R → ℚ≥0
    subadd : ∀ (r₁ r₂ : R) → obs (r₁ ∪ r₂) ≤ obs r₁ + obs r₂

record BulkObs (R : Type₀) : Type₀ where
  field
    obs    : R → ℚ≥0
    mono   : ∀ (r₁ r₂ : R) → r₁ ⊆ r₂ → obs r₁ ≤ obs r₂
```

(Pseudocode — actual definitions require region union/subset operations.)

These record types are genuinely different, and an equivalence between them
requires constructing maps that transform subadditivity witnesses into
monotonicity witnesses and vice versa. The resulting `ua` path would be
nontrivial, and transport along it would produce a verified translator between
boundary and bulk observable bundles.

This enrichment is a stretch goal for the HaPPY instance and should be
attempted only after the minimal bridge (Steps 1–7) succeeds.

---

## 13. Curvature Formalization Plan (11-Tile Patch)

### 13.1 Target theorem

Discrete Gauss–Bonnet (**Theorem 1** from
[§3.0](03-architecture.md#1-first-model-assumptions-and-initial-theorem-slate)):

\[
\sum_{v \in \mathrm{int}(K)} \kappa(v) + \sum_{v \in \partial K} \tau(v)
= 2\pi\,\chi(K)
\]

For the combinatorial formulation, this simplifies to
\(\sum_v \kappa(v) = \chi(K)\) with no separate boundary term (the boundary
effect is absorbed into the combinatorial formula). This is the recommended
first-pass target.

### 13.2 Encoding strategy

The polygon complex has 30 vertices, which is too many for a flat enumeration
to be ergonomic. Two encoding strategies are available:

**Strategy A — Classified vertices.** Group vertices by class (tiling, shared,
outer-N, outer-G) and define curvature as a function of class. Gauss–Bonnet
reduces to a weighted sum over 4 classes. This is compact and leverages the
5-fold symmetry.

**Strategy B — Flat enumeration.** Define all 30 vertices as constructors. The
curvature function has 30 clauses, and Gauss–Bonnet is verified by explicit
summation. This is brute-force but avoids abstraction overhead.

Strategy A is recommended. It produces a proof that is readable, maintainable,
and clearly connected to the mathematical structure of the \(\{5,4\}\) tiling.

### 13.3 Angular and Regge curvature (stretch goals)

Angular curvature using exact pentagon angles \(3\pi/5\) requires representing
\(\pi\) constructively — a significant obstacle. Regge curvature additionally
requires the law of cosines on rational edge lengths. Both are deferred as
stretch goals per [assumptions.md](assumptions.md) (assumption 5). The
combinatorial formulation is sufficient for Theorem 1 and does not require
any trigonometry.

---

## 14. Recommended Proof Order

The following order ensures that each step builds on the previous one and that
the 6-tile star bridge is validated before tackling the harder curvature work.

**Phase A — Star bridge (exercises Theorem 3 machinery):**

1. `Tile`, `Bond`, `Region` datatypes
2. `StarSpec`, `starSpec`, `starWeight`
3. `BoundaryView`, `BulkView`, `π∂`, `πbulk`
4. `S-cut`, `L-min` lookup tables
5. `star-pointwise` (10 refl cases)
6. `star-obs-path`, `star-package-path`

**Phase B — Curvature (exercises Theorem 1 machinery):**

7. Add `Util/Rationals.agda`
8. 11-tile polygon complex encoding (vertices, edges, faces)
9. Combinatorial curvature function
10. Gauss–Bonnet summation identity

**Phase C — Enriched bridge (exercises nontrivial `ua`):**

11. Define enriched observable packages with proof-carrying fields
12. Construct the type equivalence between enriched packages
13. Apply `ua` and verify transport

Phase A can proceed immediately after the tree pilot. Phase B requires the
scalar upgrade and can run in parallel with Phase A. Phase C depends on both
A and B.

---

## 15. Design Constraints

### 15.1 Maintain compatibility with tree pilot

The `ObsPackage` record type and the `ℚ≥0` scalar type from
`Util/Scalars.agda` should be shared across tree and star instances. If the
star instance requires changes to these shared types, the tree proofs must
still type-check. The star modules are additive, not replacement.

### 15.2 Explicit enumeration, not generic algorithms

As with the tree pilot, the star instance uses explicit lookup tables for
`S-cut` and `L-min`. Generic min-cut algorithms belong in a later phase.

### 15.3 Curvature requires rational arithmetic

The Gauss–Bonnet proof cannot use the `ℚ≥0 = ℕ` simplification because
curvature values include negative fractions (\(-1/5, -1/10\)). This is the
first module in the repository that requires a genuine rational type. The
upgrade should be isolated to the curvature modules so that the bridge modules
remain unaffected.

### 15.4 Polygon complex size

The 11-tile polygon complex has 30 vertices, 40 edges, and 11 faces. Explicit
case splits on all vertices would require 30-way pattern matches. The
classified vertex encoding (Strategy A in §13.2) reduces this to 4 classes,
which is manageable. However, the incidence data (which vertex belongs to which
edge and face) still requires substantial explicit lookup. Consider defining
incidence as a computed function of the vertex-class structure rather than a
manually enumerated table.

### 15.5 Ensure judgmental equality of scalar constants

The same constraint as the tree pilot (§11.5 of
[08-tree-instance.md](08-tree-instance.md)): all scalar constants (`0q`, `1q`,
`2q`) must be defined once in `Util/Scalars.agda` and imported by both sides.
For the curvature modules, the rational constants (\(-1/5\), etc.) must
similarly be defined once and shared.

---

## 16. Agda Module Plan

The 6-tile star bridge modules follow the tree pilot structure:

```text
src/Util/Scalars.agda           — ℚ≥0 (unchanged: ℕ)
src/Common/StarSpec.agda        — Tile, Bond, Region, StarSpec, starSpec
src/Boundary/StarCut.agda       — BoundaryView, π∂, S-cut
src/Bulk/StarChain.agda         — BulkView, πbulk, L-min
src/Bridge/StarObs.agda         — ObsPackage (reused), Obs∂, ObsBulk, star-pointwise
src/Bridge/StarEquiv.agda       — star-obs-path, star-package-path
```

The 11-tile curvature modules are separate:

```text
src/Util/Rationals.agda         — signed rational type (or upgrade Scalars)
src/Bulk/PatchComplex.agda      — 11-tile polygon complex: vertices, edges, faces
src/Bulk/Curvature.agda         — combinatorial curvature κ(v)
src/Bulk/GaussBonnet.agda       — Σ κ(v) = χ(K)
```

The tree pilot modules (`TreeSpec`, `TreeCut`, `TreeChain`, `TreeObs`,
`TreeEquiv`) remain as the calibration layer and are not replaced. The shared
`ObsPackage` record in `Bridge/TreeObs.agda` should be factored into a common
module (e.g. `Common/ObsPackage.agda`) so that both tree and star bridges
import it.

---

## 17. Success Criteria

This HaPPY instance counts as successfully specified if:

1. **Phase 1.2(a)**: Min-cut verification passes for both patches. ✅
   ([`01_happy_patch_cuts.py`](../sim/prototyping/01_happy_patch_cuts.py)
   tested successfully.)
2. **Phase 1.2(b)**: Discrete Gauss–Bonnet verified in combinatorial, angular,
   and Regge forms. ✅
   ([`02_happy_patch_curvature.py`](../sim/prototyping/02_happy_patch_curvature.py)
   tested successfully.)
3. **Phase 1.2(c)**: Common source specification, extraction functions, and
   both projected views are explicitly defined for the 6-tile star (§7–§8
   of this document). ✅
4. **Phase 1.2(d)**: Pointwise functional agreement verified for all 10
   representative regions (§11 of this document). ✅

The formalization succeeds when the Agda modules in §16 type-check and the star
bridge passes the same end-to-end pipeline as the tree pilot:

> starSpec → π∂ / πbulk → Obs∂ / ObsBulk → star-package-path

And separately, the curvature pipeline type-checks:

> PatchComplex → κ → Σ κ(v) ≡ χ(K)

---

## 18. Why This Instance Matters

The tree instance validated the **bridge architecture** on a trivially
1-dimensional example. The HaPPY instance validates the same architecture on a
**genuine 2D tiling** from the holographic literature, exercising:

- pentagonal tile structure (the \(\{5,4\}\) Schläfli type),
- star topology (central tile + peripheral tiles, beyond simple trees),
- nontrivial min-cut patterns (complementary region symmetry
  \(S(A) = S(\bar A)\)),
- negative combinatorial curvature at interior vertices,
- Gauss–Bonnet with both interior and boundary contributions,
- the three curvature formulations (combinatorial, angular, Regge) on the
  same underlying geometry,
- the curvature/entropy duality that motivates the entire project.

The 6-tile star is the **second bridge calibration object**, confirming that the
observable-package architecture scales from trees to tilings. The 11-tile filled
patch is the **first curvature test object**, providing the numerical target for
Theorem 1 (discrete Gauss–Bonnet). Together, these patches provide the complete
numerical foundation for Phases 2A, 2B, and 3 of the
[roadmap](05-roadmap.md).

The N-singleton discrepancy discovered in §3.2 (min-cut \(\neq\) internal
geodesic for single N-tiles on the 11-tile patch) is a concrete Phase 1.2
finding that would have been invisible without numerical prototyping. It
validates the roadmap's **strong recommendation** to reproduce paper examples
numerically before formalization, and it informs the formalization design:
the 6-tile star avoids the issue entirely, while the 11-tile patch requires
a precise definition of the bulk observable that accounts for boundary-bond
contributions.