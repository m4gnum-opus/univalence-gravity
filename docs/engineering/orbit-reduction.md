# Orbit Reduction

**The strategy that scales holographic proofs from 10 regions to 1885 — by factoring through small orbit types.**

**Audience:** Proof engineers, Agda developers, and anyone implementing large-scale formal verification with exhaustive case analysis.

**Primary modules:** `Bridge/GenericBridge.agda` (`OrbitReducedPatch`, `orbit-to-patch`, `orbit-bridge-witness`), `Common/Dense100Spec.agda` (`classify100`), `Common/Dense200Spec.agda` (`classify200`), `Common/Layer54d*Spec.agda` (`classifyLayer54d*`)

**Prerequisites:** Familiarity with the generic bridge architecture ([`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md)), the `abstract` barrier ([`engineering/abstract-barrier.md`](abstract-barrier.md)), and the oracle pipeline ([`engineering/oracle-pipeline.md`](oracle-pipeline.md)).

---

## 1. The Problem: Proof Obligations Grow with Region Count

Every holographic bridge instance in the repository requires a **pointwise agreement proof**: for each boundary region `r`, the boundary min-cut `S∂ r` equals the bulk minimal chain `LB r`. For small patches, this is a flat case split with one `refl` per region constructor:

```agda
star-pointwise regN0   = refl    -- 10 cases for the 6-tile star
star-pointwise regN1   = refl
...
star-pointwise regN4N0 = refl
```

This works well up to ~500 constructors (the filled patch has 90, Dense-50 has 139). But as patches grow:

| Patch | Regions | Flat proof cases | Feasible? |
|-------|---------|-----------------|-----------|
| Star (6-tile) | 10 | 10 | ✓ trivial |
| Filled (11-tile) | 90 | 90 | ✓ manageable |
| Dense-50 | 139 | 139 | ✓ at the limit |
| Dense-100 | 717 | 717 | ✗ wasteful |
| Dense-200 | 1246 | 1246 | ✗ very wasteful |
| {5,4} depth 7 | 1885 | 1885 | ✗ absurd |

The waste is not in the *data type declarations* (Agda's parser handles large constructors, albeit slowly) but in the *proof obligations*: 717 identical `refl` proofs carry zero mathematical content beyond the first one that establishes the pattern. All 717 regions share only 8 distinct min-cut values.

---

## 2. The Insight: Factor Through a Small Orbit Type

The orbit reduction strategy exploits a structural property of flow-graph observables: **regions with the same min-cut value carry the same observable data**. If 717 regions produce only 8 distinct min-cut values, then the observable function factors as:

```
S∂ = S-rep ∘ classify
```

where:
- `classify : RegionTy → OrbitTy` maps each region to its orbit representative (717 → 8)
- `S-rep : OrbitTy → ℚ≥0` is the observable on the small orbit type (8 clauses)

The proof obligations similarly factor:

```
pointwise r = pointwise-rep (classify r)
```

The 717-clause classification function is traversed only during **concrete evaluation** (when Agda reduces a specific constructor). The **proof** operates on the 8-constructor orbit type and is lifted to the full region type in a single line.

---

## 3. The `OrbitReducedPatch` Record

The orbit reduction pattern is captured by the `OrbitReducedPatch` record in `Bridge/GenericBridge.agda`:

```agda
record OrbitReducedPatch : Type₁ where
  field
    RegionTy  : Type₀           -- the (potentially large) region type
    OrbitTy   : Type₀           -- the (small) orbit representative type
    classify  : RegionTy → OrbitTy   -- surjection: regions → orbits
    S-rep     : OrbitTy → ℚ≥0   -- boundary observable on orbits
    L-rep     : OrbitTy → ℚ≥0   -- bulk observable on orbits
    rep-agree : (o : OrbitTy) → S-rep o ≡ L-rep o
```

**Fields explained:**

| Field | Role | Size |
|-------|------|------|
| `RegionTy` | Full region type with one constructor per boundary region | 717, 1246, 1885 constructors |
| `OrbitTy` | Small type with one constructor per distinct min-cut value | 8, 9, 2 constructors |
| `classify` | Classification function mapping each region to its orbit | 717, 1246, 1885 clauses |
| `S-rep` | Boundary min-cut lookup on orbit representatives | 8, 9, 2 clauses |
| `L-rep` | Bulk chain-length lookup on orbit representatives | 8, 9, 2 clauses |
| `rep-agree` | Pointwise agreement on orbit representatives | 8, 9, 2 `refl` proofs |

The orbit classification is by **min-cut value**: all regions with the same min-cut share an orbit. This is the simplest classification that guarantees `S-rep` and `L-rep` agree. A finer classification (e.g., by region size + min-cut) could be used if needed for subadditivity proofs, but for the RT correspondence the min-cut grouping suffices.

---

## 4. Automatic `PatchData` Extraction

The `orbit-to-patch` function converts an `OrbitReducedPatch` into the `PatchData` consumed by the generic bridge theorem:

```agda
orbit-to-patch : OrbitReducedPatch → PatchData
orbit-to-patch orp = record
  { RegionTy = RegionTy
  ; S∂       = λ r → S-rep (classify r)
  ; LB       = λ r → L-rep (classify r)
  ; obs-path = funExt (λ r → rep-agree (classify r))
  }
  where open OrbitReducedPatch orp
```

The `obs-path` is assembled automatically: at each region `r`, `rep-agree (classify r)` gives the orbit-level `refl`, and `funExt` packages these into a single function-level path.

This is the **1-line lifting**: the exact pattern from `Bridge/Dense100Obs.agda`:

```agda
d100-pointwise r = d100-pointwise-rep (classify100 r)
```

---

## 5. The One-Function Composition

The full pipeline from oracle-generated data to proof-carrying `BridgeWitness` is a single function call:

```agda
orbit-bridge-witness : OrbitReducedPatch → BridgeWitness
orbit-bridge-witness orp =
  GenericEnriched.abstract-bridge-witness (orbit-to-patch orp)
```

This composes:
1. `orbit-to-patch` — extracts `PatchData` from the orbit-reduced data
2. `GenericEnriched` — the parameterized module proving the enriched equivalence
3. `abstract-bridge-witness` — packages everything into a `BridgeWitness`

**No per-instance proof engineering is needed.** The Python oracle generates the `OrbitReducedPatch` data (Spec, Cut, Chain, Obs modules); `orbit-bridge-witness` produces the `BridgeWitness` automatically.

---

## 6. How the Classification Function Works

The `classify` function is a flat pattern match mapping each region constructor to an orbit representative constructor. For Dense-100:

```agda
-- Common/Dense100Spec.agda (generated by 09_generate_dense100.py)

classify100 : D100Region → D100OrbitRep
classify100 d100r0   = mc1    -- S = 1
classify100 d100r1   = mc3    -- S = 3
classify100 d100r2   = mc3    -- S = 3
...                            -- (717 clauses total)
classify100 d100r716 = mc7    -- S = 7
```

The orbit representatives are named by their min-cut value:

```agda
data D100OrbitRep : Type₀ where
  mc1 mc2 mc3 mc4 mc5 mc6 mc7 mc8 : D100OrbitRep
```

The observable lookups on orbit representatives are trivial:

```agda
-- Boundary/Dense100Cut.agda
S-cut-rep : D100OrbitRep → ℚ≥0
S-cut-rep mc1 = 1
S-cut-rep mc2 = 2
S-cut-rep mc3 = 3
S-cut-rep mc4 = 4
S-cut-rep mc5 = 5
S-cut-rep mc6 = 6
S-cut-rep mc7 = 7
S-cut-rep mc8 = 8

-- The full S-cut is the composition:
S-cut : D100BdyView → D100Region → ℚ≥0
S-cut _ r = S-cut-rep (classify100 r)
```

**Key property:** `S-cut` is *defined* as `S-cut-rep ∘ classify100`. This is not a derived equality — it is the definitional structure of the module. The coarse-graining compatibility (`compat = λ _ → refl` in `Bridge/CoarseGrain.agda`) holds *definitionally* because of this factorization.

---

## 7. Normalization Behavior

When Agda evaluates `S-cut d100BdyView d100r15` (a specific region):

1. **Step 1:** `S-cut _ d100r15` unfolds to `S-cut-rep (classify100 d100r15)`.
2. **Step 2:** `classify100 d100r15` pattern-matches on the 717-clause function, reducing to (say) `mc8`.
3. **Step 3:** `S-cut-rep mc8` pattern-matches on the 8-clause function, reducing to `8`.

Total: two pattern-match steps. The 717-clause classification is traversed once; the 8-clause lookup is traversed once. Fast.

When Agda checks `d100-pointwise d100r15 = d100-pointwise-rep (classify100 d100r15)`:

1. **Step 1:** `classify100 d100r15` reduces to `mc8`.
2. **Step 2:** `d100-pointwise-rep mc8` reduces to `refl`.
3. **Step 3:** The type of `refl` is `S-cut-rep mc8 ≡ L-min-rep mc8`, which is `8 ≡ 8`. ✓

The 717-clause function is never re-normalized during proof checking — only during concrete evaluation of a specific constructor.

---

## 8. Scaling Properties

The orbit reduction scales **logarithmically** with patch size:

| Patch | Regions | Orbits | Reduction | Proof cases | classify clauses |
|-------|---------|--------|-----------|-------------|------------------|
| Dense-50 | 139 | — | flat | 139 | — |
| Dense-100 | 717 | 8 | 90× | 8 | 717 |
| Dense-200 | 1246 | 9 | 138× | 9 | 1246 |
| {5,4} depth 2 | 15 | 2 | 8× | 2 | 15 |
| {5,4} depth 4 | 105 | 2 | 53× | 2 | 105 |
| {5,4} depth 5 | 275 | 2 | 138× | 2 | 275 |
| {5,4} depth 7 | 1885 | 2 | 942× | 2 | 1885 |

**Adding more tiles grows only the `classify` function**, not the proof obligations. The orbit count grows logarithmically with the min-cut range, which itself grows slowly with patch size. Empirically:

- Dense-50: max S = 7 → 7 orbits (using flat enumeration, no orbit reduction needed)
- Dense-100: max S = 8 → 8 orbits
- Dense-200: max S = 9 → 9 orbits
- {5,4} depths 2–7: max S = 2 → 2 orbits (constant!)

The {5,4} BFS-layer patches are particularly striking: from 21 tiles (depth 2) to 3046 tiles (depth 7), the orbit count stays at 2 because BFS-grown pentagonal patches always have min-cut values in {1, 2}. The exponential boundary growth (15 → 1885 regions) is absorbed entirely by the classification function.

---

## 9. The Dense-100 Instance — Worked Example

The Dense-100 patch is the canonical example of orbit reduction in action. Here is the complete data flow:

### 9.1 Python Oracle (Script 09)

The Python oracle `09_generate_dense100.py`:
1. Builds a 100-cell Dense patch of the {4,3,5} honeycomb via greedy max-connectivity.
2. Enumerates 717 cell-aligned boundary regions (connected subsets of boundary cells, up to 5 cells each).
3. Computes min-cut values via max-flow (NetworkX): range 1–8.
4. Groups regions by min-cut value: 8 orbit representatives.
5. Emits 5 Agda modules:

| Module | Content | Size |
|--------|---------|------|
| `Common/Dense100Spec.agda` | `D100Region` (717 ctors), `D100OrbitRep` (8 ctors), `classify100` (717 clauses) | ~866 lines |
| `Boundary/Dense100Cut.agda` | `S-cut-rep` (8 clauses), `S-cut = S-cut-rep ∘ classify100` | ~58 lines |
| `Bulk/Dense100Chain.agda` | `L-min-rep` (8 clauses), `L-min = L-min-rep ∘ classify100` | ~55 lines |
| `Bulk/Dense100Curvature.agda` | Edge-class curvature + Gauss–Bonnet refl | ~71 lines |
| `Bridge/Dense100Obs.agda` | `d100-pointwise-rep` (8 refls), `d100-pointwise` (1-line lifting) | ~116 lines |

### 9.2 Agda Verification

Once generated, the modules are loaded in Agda. The type-checker:

1. **Parses** `D100Region` with 717 constructors (~30s on first load; cached thereafter).
2. **Checks** `classify100` — a 717-clause pattern match, each clause trivially maps a constructor to another constructor. Fast.
3. **Checks** `S-cut-rep` and `L-min-rep` — 8 clauses each, returning ℕ literals. Trivial.
4. **Checks** `d100-pointwise-rep` — 8 cases, each `refl`. Trivial (each case: Agda evaluates `S-cut-rep mcK` and `L-min-rep mcK` to the same ℕ literal).
5. **Checks** `d100-pointwise r = d100-pointwise-rep (classify100 r)` — the type-checker verifies that the RHS has the correct type. This requires no case split on `r`; the type follows from the definitional structure of `S-cut` and `L-min`.

### 9.3 Generic Bridge Integration

In `Bridge/GenericValidation.agda`, the orbit-reduced patch is constructed:

```agda
d100OrbitPatch : OrbitReducedPatch
d100OrbitPatch .OrbitReducedPatch.RegionTy  = D100Region
d100OrbitPatch .OrbitReducedPatch.OrbitTy   = D100OrbitRep
d100OrbitPatch .OrbitReducedPatch.classify  = classify100
d100OrbitPatch .OrbitReducedPatch.S-rep     = S-cut-rep
d100OrbitPatch .OrbitReducedPatch.L-rep     = L-min-rep
d100OrbitPatch .OrbitReducedPatch.rep-agree = d100-pointwise-rep

d100-generic-witness : BridgeWitness
d100-generic-witness = orbit-bridge-witness d100OrbitPatch
```

The `orbit-bridge-witness` call produces the full enriched equivalence + Univalence path + verified transport — all from the 8-orbit data, with no additional proof engineering.

### 9.4 Coherence Verification

The generated `S∂` from `orbit-to-patch` agrees definitionally with the concrete `S∂D100`:

```agda
d100-S∂-pointwise : (r : D100Region)
  → PatchData.S∂ (orbit-to-patch d100OrbitPatch) r ≡ S∂D100 r
d100-S∂-pointwise _ = refl
```

Both sides reduce to `S-cut-rep (classify100 r)` — the generic `orbit-to-patch` lambda and the concrete `S-cut` definition produce the same normal form. The fact that this is `refl` is the validation: the generic architecture correctly captures the concrete instance.

---

## 10. The {5,4} Layer Tower — Maximal Reduction

The {5,4} BFS-layer patches demonstrate the extreme case of orbit reduction. At every BFS depth from 2 to 7, the min-cut values are restricted to {1, 2} — because in a BFS-grown pentagonal patch, every boundary tile is either an outer leaf (connected to one internal tile, min-cut = 1) or a shared boundary tile (connected to two internal tiles through the center, min-cut = 2).

This means the orbit type has **exactly 2 constructors** regardless of how many tiles the patch contains:

```agda
data Layer54d7OrbitRep : Type₀ where
  mc1 mc2 : Layer54d7OrbitRep
```

And the proof has exactly 2 cases:

```agda
layer54d7-pointwise-rep : (o : Layer54d7OrbitRep) → S-cut-rep o ≡ L-min-rep o
layer54d7-pointwise-rep mc1 = refl
layer54d7-pointwise-rep mc2 = refl
```

The classification function has 1885 clauses (one per region at depth 7), but the proof has 2 cases. The reduction factor is 942×.

In `Bridge/SchematicTower.agda`, the tower level is constructed by `mkTowerLevel`:

```agda
layer54d7-level : TowerLevel
layer54d7-level = mkTowerLevel layer54d7-orbit 2
```

The `mkTowerLevel` smart constructor calls `orbit-bridge-witness` internally, producing the full `BridgeWitness` from the 2-orbit data.

---

## 11. Why the 1-Line Lifting Works

The 1-line lifting `d100-pointwise r = d100-pointwise-rep (classify100 r)` is the architectural pivot of the orbit reduction. Here is why it type-checks:

**Goal type:** `S-cut d100BdyView r ≡ L-min d100BulkView r`

**Definitional unfolding:**
- `S-cut d100BdyView r` unfolds to `S-cut-rep (classify100 r)` (by the single-clause definition in `Dense100Cut.agda`).
- `L-min d100BulkView r` unfolds to `L-min-rep (classify100 r)` (by the single-clause definition in `Dense100Chain.agda`).

**Substitution:** The goal becomes `S-cut-rep (classify100 r) ≡ L-min-rep (classify100 r)`.

**Type of the RHS:** `d100-pointwise-rep (classify100 r)` has type `S-cut-rep (classify100 r) ≡ L-min-rep (classify100 r)` — exactly matching the goal.

No case split on `r` is needed. The definitional structure of `S-cut` and `L-min` (both defined as `*-rep ∘ classify100`) ensures that the orbit-level proof lifts to the full region type.

**This is not a proof trick — it is a consequence of the architectural decision** to define the observables as compositions through the classification function. If `S-cut` were instead defined by a flat 717-clause pattern match, the lifting would not work: Agda would need to case-split on `r` to reduce `S-cut _ r` to a normal form.

---

## 12. Comparison with Flat Enumeration

| Property | Flat (Dense-50 style) | Orbit Reduced (Dense-100 style) |
|----------|----------------------|--------------------------------|
| Region type | 139 constructors | 717 constructors |
| Observable definition | 139-clause case split returning ℕ literals | 8-clause orbit lookup composed with 717-clause classify |
| Pointwise proof | 139 `refl` cases | 8 `refl` cases + 1-line lifting |
| Proof size | O(N) where N = region count | O(K) where K = orbit count |
| Parse time | Proportional to N | Proportional to N (for classify) |
| Normalization cost | Each `refl` normalizes independently | 8 normalizations + O(1) lifting |
| Adding more regions | Grows proof proportionally | Grows classify only; proofs unchanged |

The key advantage: **adding tiles to the patch only grows the `classify` function — not the proof obligations**. The orbit count (K) grows logarithmically with the min-cut range, which grows slowly with patch size. In practice, K stays in the single digits even for patches with thousands of regions.

---

## 13. Relationship to Symmetry Quotient

The orbit reduction strategy from §6.5 of the historical development docs was originally motivated by group-theoretic symmetry: the {4,3,5} honeycomb has an octahedral symmetry group (order 48) acting on boundary cells, and equivariant properties need only be checked on orbit representatives.

The implemented version is **simpler and more general**: instead of computing the automorphism group and its orbits (which requires graph isomorphism computation), it classifies regions by their observable value (min-cut). This is:

1. **Easier to compute:** Just group regions by min-cut value — no group theory needed.
2. **More general:** Works for any patch topology, not just symmetric ones.
3. **Sufficient for the bridge:** The RT correspondence S = L depends only on the observable values, not on the geometric structure of the regions.

A finer orbit classification (using the actual symmetry group) would produce fewer, larger orbits — but it would not change the proof architecture. The min-cut grouping is the coarsest classification compatible with the bridge, and the coarsest is the most efficient.

---

## 14. Integration with Other Engineering Patterns

### 14.1 The `abstract` Barrier

For the area law and half-bound proofs (`Boundary/Dense100AreaLaw.agda`, `Boundary/Dense100HalfBound.agda`), the orbit reduction is *not* used — these proofs operate on the full `D100Region` type with 717 `abstract`-sealed `(k, refl)` witnesses. This is because the area and half-bound values vary within orbits (regions with the same min-cut can have different boundary areas), so the min-cut grouping does not help.

The two patterns are complementary:
- **Orbit reduction** for the RT correspondence (S = L): proof cases = orbit count.
- **`abstract` barrier** for the area law / half-bound (S ≤ area, 2·S ≤ area): proof cases = region count, but sealed to prevent downstream normalization.

### 14.2 The Generic Bridge

The orbit reduction feeds directly into the generic bridge theorem (`GenericBridge.agda`). The composition `orbit-bridge-witness : OrbitReducedPatch → BridgeWitness` is the canonical way to produce bridge witnesses for large patches. All twelve bridge instances in the repository pass through this composition (six via `orbit-to-patch` + `GenericEnriched`, six via flat `PatchData` + `GenericEnriched`).

### 14.3 The Schematic Tower

The `SchematicTower` uses `mkTowerLevel` which calls `orbit-bridge-witness` internally:

```agda
mkTowerLevel : OrbitReducedPatch → ℚ≥0 → TowerLevel
mkTowerLevel orp mc = record
  { patch  = orp
  ; maxCut = mc
  ; bridge = orbit-bridge-witness orp
  }
```

Each tower level carries its `OrbitReducedPatch` data and the automatically derived `BridgeWitness`. No additional proof engineering per level.

---

## 15. The Python Oracle's Role

The Python oracle scripts (08, 09, 12, 13) are responsible for:

1. **Building the patch** via Coxeter reflections and the chosen growth strategy (BFS, Dense, etc.).
2. **Enumerating boundary regions** as connected subsets of boundary cells.
3. **Computing min-cut values** via max-flow (NetworkX).
4. **Grouping into orbits** by min-cut value.
5. **Emitting Agda modules** with the `OrbitReducedPatch` data: region type, orbit type, classify function, orbit-level observable lookups, and orbit-level `refl` proofs.

The oracle is the **search engine**; Agda is the **checker**. The oracle finds the correct classification and observable values; Agda verifies that each `(k, refl)` witness type-checks. If the oracle produces incorrect data (e.g., a misclassified region or a wrong min-cut value), the generated Agda module will fail to type-check — the `refl` proof will not reduce because the two sides of the equality will normalize to different ℕ literals.

This is the same division of labor used by the Four Color Theorem proof (Coq) and the Kepler Conjecture proof (HOL Light): external computation finds proofs, a simple kernel checks them.

---

## 16. Limitations and Future Directions

### 16.1 Subadditivity and Monotonicity

The orbit reduction by min-cut value does not help with subadditivity proofs (S(A∪B) ≤ S(A) + S(B)), because the union operation does not respect min-cut orbits: two regions with the same min-cut can produce a union with a different min-cut. For the filled patch's 360 subadditivity cases, the `abstract` barrier (not orbit reduction) is the operative technique.

A potential extension: orbit reduction by *(min-cut, region-size)* pairs would produce more orbits but could help with size-dependent properties. This is not currently implemented.

### 16.2 The ℕ-Encoded Fallback

For extremely large patches (tens of thousands of regions), even the `data` declaration might stress Agda's parser. The fallback strategy from §6.5.4 of the historical development docs encodes `RegionTy` as `Fin N` (or `Σ[ n ∈ ℕ ] (n < N)`) instead of a flat constructor enumeration. The `classify` function becomes a balanced binary decision tree of depth ⌈log₂ N⌉, normalizing in ~log₂ N steps per query. The proofs still operate on `OrbitTy` (always small); the tree encoding is invisible to the proof layer.

This fallback has not been needed: the depth-7 {5,4} patch (1885 constructors) type-checks successfully with flat enumeration. But the architecture supports it if scaling demands it.

### 16.3 Automatic Orbit Detection

Currently, the orbit classification is performed by the Python oracle and emitted as explicit Agda code. A more ambitious approach would compute the orbit classification *inside Agda* using decidable equality on ℕ — but this would require formalizing a min-cut algorithm in Agda, defeating the purpose of the oracle pattern. The external-oracle approach is the pragmatic choice: the Python script is trusted to find the correct orbits, and Agda is trusted to verify each `refl` witness.

---

## 17. Summary

| What | How |
|------|-----|
| **Problem** | Flat enumeration of pointwise proofs grows linearly with region count |
| **Solution** | Factor observables through a small orbit type; lift proofs in 1 line |
| **Record** | `OrbitReducedPatch` in `Bridge/GenericBridge.agda` |
| **Composition** | `orbit-bridge-witness : OrbitReducedPatch → BridgeWitness` |
| **Classification** | By min-cut value (simplest grouping compatible with RT) |
| **Proof cases** | = orbit count (8, 9, or 2), not region count (717, 1246, 1885) |
| **Lifting** | `d100-pointwise r = d100-pointwise-rep (classify100 r)` — 1 line |
| **Scaling** | Adding tiles grows `classify` only; proofs unchanged |
| **Generated by** | Python oracle scripts 09, 12, 13 |

The orbit reduction strategy is not a proof trick — it is a **design pattern for scaling formal verification of parameterized combinatorial systems**. The pattern says:

> If a proof about a concrete combinatorial structure depends only on an abstract observable value (here: the min-cut), then the proof can be stated on the small orbit type and lifted to the full region type by the classification function.

This pattern is the reason the repository can verify the holographic correspondence on patches with 3046 tiles and 1885 boundary regions — using only 2 proof cases.

---

## 18. Cross-References

| Topic | Document |
|-------|----------|
| Generic bridge (core innovation) | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Generic bridge pattern (engineering complement) | [`engineering/generic-bridge-pattern.md`](generic-bridge-pattern.md) |
| `abstract` barrier (complementary technique) | [`engineering/abstract-barrier.md`](abstract-barrier.md) |
| Oracle pipeline (how modules are generated) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Scaling report (region counts, timings) | [`engineering/scaling-report.md`](scaling-report.md) |
| Holographic bridge (formal content) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Thermodynamics (coarse-graining as orbit reduction) | [`formal/09-thermodynamics.md`](../formal/09-thermodynamics.md) |
| Dense-100 instance data | [`instances/dense-100.md`](../instances/dense-100.md) |
| Dense-200 instance data | [`instances/dense-200.md`](../instances/dense-200.md) |
| Layer-54 tower data | [`instances/layer-54-tower.md`](../instances/layer-54-tower.md) |
| Historical development (§5, §6.5 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §5, §6.5 |