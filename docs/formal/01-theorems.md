# Canonical Theorem Registry

**Status:** All results listed below are machine-checked by the Cubical Agda 2.8.0 type-checker against the `agda/cubical` library (April 2026). No axioms are postulated; all transport computes.

This document is the single canonical reference for every formally verified result in the repository. For each theorem, it records: the informal statement, the Agda type signature, the source module, the proof method, and cross-references to related documentation.

---

## Overview

| # | Result | Primary Module | Proof Method |
|---|--------|----------------|--------------|
| 1 | [Discrete Ryu–Takayanagi](#theorem-1-discrete-ryutakayanagi-generic-bridge) | `Bridge/GenericBridge.agda` | Generic parameterized module; `isoToEquiv` + `ua` + `uaβ` |
| 2 | [Discrete Gauss–Bonnet](#theorem-2-discrete-gaussbonnet) | `Bulk/GaussBonnet.agda` | `refl` on class-weighted ℤ sum |
| 3 | [Discrete Bekenstein–Hawking](#theorem-3-discrete-bekensteinhawking-half-bound) | `Bridge/HalfBound.agda` | `from-two-cuts` generic lemma + per-instance `abstract` witnesses |
| 4 | [Discrete Wick Rotation](#theorem-4-discrete-wick-rotation) | `Bridge/WickRotation.agda` | Coherence record importing shared bridge + two GB witnesses |
| 5 | [No Closed Timelike Curves](#theorem-5-no-closed-timelike-curves) | `Causal/NoCTC.agda` | Well-foundedness of (ℕ, <) via `snotz` + `injSuc` |
| 6 | [Matter as Topological Defects](#theorem-6-matter-as-topological-defects) | `Gauge/Holonomy.agda` | Decidable equality on Q₈ + discriminator on `q1` |
| 7 | [Quantum Superposition Bridge](#theorem-7-quantum-superposition-bridge) | `Quantum/QuantumBridge.agda` | Structural induction on `List`; `cong₂` on `_+A_` |
| 8 | [Subadditivity & Monotonicity](#theorem-8-structural-properties-subadditivity--monotonicity) | `Boundary/StarSubadditivity.agda`, `Bulk/StarMonotonicity.agda` | Exhaustive `(k , refl)` case splits |
| 9 | [Step Invariance & Dynamics Loop](#theorem-9-step-invariance--dynamics-loop) | `Bridge/StarStepInvariance.agda`, `Bridge/StarDynamicsLoop.agda` | Parameterized `SL-param` + list induction |
| 10 | [Enriched Step Invariance](#theorem-10-enriched-step-invariance) | `Bridge/EnrichedStarStepInvariance.agda` | Parameterized `full-equiv-w` for arbitrary weight functions |

**Additional verified artifacts:** [Resolution Tower & Convergence Certificate](#additional-verified-artifacts), [Area Law](#area-law-instances), [Coarse-Graining](#coarse-graining), [Generic Validation](#generic-bridge-validation).

---

## Theorem 1: Discrete Ryu–Takayanagi (Generic Bridge)

**Informal statement.** For any finite holographic patch satisfying the abstract `PatchData` interface — a region type, two observable functions (boundary min-cut and bulk minimal chain), and a path between them — there exists an exact type equivalence between the enriched boundary and bulk observable packages, with transport along the resulting Univalence path verified.

**Agda type signatures:**

```agda
-- Bridge/GenericBridge.agda

record PatchData : Type₁ where
  field
    RegionTy : Type₀
    S∂       : RegionTy → ℚ≥0
    LB       : RegionTy → ℚ≥0
    obs-path : S∂ ≡ LB

module GenericEnriched (pd : PatchData) where
  enriched-equiv     : EnrichedBdy ≃ EnrichedBulk
  enriched-ua-path   : EnrichedBdy ≡ EnrichedBulk
  enriched-transport : transport enriched-ua-path bdy-instance ≡ bulk-instance
  abstract-bridge-witness : BridgeWitness

orbit-bridge-witness : OrbitReducedPatch → BridgeWitness
```

**Proof method.** The enriched types `EnrichedBdy = Σ[ f ∈ (RegionTy → ℚ≥0) ] (f ≡ S∂)` and `EnrichedBulk = Σ[ f ∈ (RegionTy → ℚ≥0) ] (f ≡ LB)` are reversed singleton types (contractible). The `Iso` is built by appending `obs-path` to the agreement witness; round-trip proofs close because `RegionTy → ℚ≥0` is a set (`isOfHLevelΠ 2`). Transport reduces via `uaβ` to the forward map; the second component closes by contractibility (`isContr-Singl`).

**Instantiation breadth.** Twelve patch instances verified, spanning 1D trees, 2D pentagonal tilings, and 3D cubic honeycombs — see [Generic Bridge Validation](#generic-bridge-validation) below.

**Cross-references:** [`formal/03-holographic-bridge.md`](03-holographic-bridge.md), [`formal/11-generic-bridge.md`](11-generic-bridge.md), [`engineering/generic-bridge-pattern.md`](../engineering/generic-bridge-pattern.md).

---

## Theorem 2: Discrete Gauss–Bonnet

**Informal statement.** For the 11-tile filled patch of the {5,4} hyperbolic pentagonal tiling, the total combinatorial curvature equals the Euler characteristic of the disk:

> Σᵥ κ(v) = χ(K) = 1

**Agda type signature:**

```agda
-- Bulk/GaussBonnet.agda

discrete-gauss-bonnet : totalCurvature ≡ χ₁₀

-- where:
--   totalCurvature = 5 ·₁₀ neg1/5  +₁₀  5 ·₁₀ neg1/10
--                  +₁₀  5 ·₁₀ pos1/5  +₁₀  5 ·₁₀ neg1/10
--                  +₁₀ 10 ·₁₀ pos1/5
--   χ₁₀ = one₁₀ = pos 10    (representing 10/10 = 1)
```

**Proof method.** `refl`. The scalar type is `ℚ₁₀ = ℤ` (integer *n* represents *n*/10). All curvature values for {5,4} have denominators dividing 10. The class-weighted sum `5·(−2) + 5·(−1) + 5·(2) + 5·(−1) + 10·(2) = 10` normalizes judgmentally because `ℤ` addition computes by structural recursion on closed constructor terms.

**De Sitter analogue.** A parallel theorem holds for the {5,3} spherical tiling with *positive* interior curvature κ = +1/10 (module `Bulk/DeSitterGaussBonnet.agda`), also discharged by `refl`.

**Cross-references:** [`formal/04-discrete-geometry.md`](04-discrete-geometry.md), `Bulk/PatchComplex.agda` (polygon complex encoding), `Bulk/Curvature.agda` (κ function).

---

## Theorem 3: Discrete Bekenstein–Hawking (Half-Bound)

**Informal statement.** For all cell-aligned boundary regions on verified patches, the entropy is bounded by half the boundary surface area:

> S(A) ≤ area(A) / 2

with a tight achiever where 2·S(A) = area(A). The discrete Newton's constant is 1/(4G) = 1/2 in bond-dimension-1 units.

**Agda type signatures:**

```agda
-- Bridge/HalfBound.agda

record HalfBoundWitness (pd : PatchData) : Type₀ where
  field
    area       : PatchData.RegionTy pd → ℚ≥0
    half-bound : (r : PatchData.RegionTy pd)
               → (S∂ pd r +ℚ S∂ pd r) ≤ℚ area r
    tight      : Σ[ r ∈ PatchData.RegionTy pd ]
                   (S∂ pd r +ℚ S∂ pd r ≡ area r)

two-le-sum : {s a b : ℕ} → s ≤ℚ a → s ≤ℚ b → (s +ℚ s) ≤ℚ (a +ℚ b)

from-two-cuts :
  {RegionTy : Type₀}
  (S∂ area n-cross n-bdy : RegionTy → ℚ≥0)
  → ((r : RegionTy) → area r ≡ n-cross r +ℚ n-bdy r)
  → ((r : RegionTy) → S∂ r ≤ℚ n-cross r)
  → ((r : RegionTy) → S∂ r ≤ℚ n-bdy r)
  → (r : RegionTy) → (S∂ r +ℚ S∂ r) ≤ℚ area r
```

**Proof method.** The generic `from-two-cuts` lemma decomposes `area(A) = n_cross + n_bdy` (crossing bonds + boundary legs) and uses the fact that the min-cut is bounded by both independent cuts: `S ≤ min(n_cross, n_bdy) ≤ (n_cross + n_bdy)/2 = area/2`. Per-instance witnesses (Dense-100: 717 `abstract` cases, Dense-200: 1246 `abstract` cases) are generated by the Python oracle (`17_generate_half_bound.py`).

**Verification scope.** Numerically confirmed across 32,134 regions on 4 tilings ({4,3,5}, {5,4}, {4,4}, {5,3}), 4 growth strategies (Dense, BFS, Geodesic, Hemisphere), and 3 bond capacities (c = 1, 2, 3) — zero violations.

**Tower integration:**

```agda
-- Bridge/SchematicTower.agda §25

DiscreteBekensteinHawking : Type₁
DiscreteBekensteinHawking = ConvergenceCertificate3L-HB

discrete-bekenstein-hawking : DiscreteBekensteinHawking
```

**Cross-references:** [`formal/12-bekenstein-hawking.md`](12-bekenstein-hawking.md), [`physics/discrete-bekenstein-hawking.md`](../physics/discrete-bekenstein-hawking.md).

---

## Theorem 4: Discrete Wick Rotation

**Informal statement.** The holographic bridge (Theorem 1) is curvature-agnostic: the same Agda term serves both AdS-like ({5,4}, κ < 0) and dS-like ({5,3}, κ > 0) geometries. The Gauss–Bonnet theorem holds independently in both curvature regimes, targeting the same Euler characteristic χ = 1.

**Agda type signature:**

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
```

**Proof method.** The `shared-bridge` field is `star-generic-witness` from `Bridge/GenericValidation.agda` — produced by the generic bridge machinery, which never inspects curvature. The `euler-coherence` field is `refl` because both `χ₁₀` and `dsχ₁₀` are defined as `one₁₀ = pos 10`.

**Cross-references:** [`formal/08-wick-rotation.md`](08-wick-rotation.md), `Bulk/DeSitterCurvature.agda`, `Bulk/DeSitterGaussBonnet.agda`.

---

## Theorem 5: No Closed Timelike Curves

**Informal statement.** In any time-stratified causal poset (where each causal link strictly increases the ℕ-valued time index), no closed timelike curve can exist. The acyclicity is a structural consequence of the type signature of `CausalLink`, not an axiom.

**Agda type signature:**

```agda
-- Causal/NoCTC.agda

no-ctc :
  {CellAt : ℕ → Type₀}
  {Adj    : ∀ n → CellAt n → CellAt (suc n) → Type₀}
  {e e'   : Event CellAt}
  → CausalChain CellAt Adj e e'
  → CausalLink CellAt Adj e' e
  → ⊥
```

**Proof method.** A `CausalChain` from `e` to `e'` followed by a `CausalLink` from `e'` back to `e` implies `time(e) <ℕ time(e)` via `chain-step-<` (structural induction on the chain composing single-step strict orderings via `<ℕ-trans`). This contradicts `<ℕ-irrefl` (proven from `snotz` + `injSuc` + `+-suc` on ℕ).

**Additional results:**

```agda
-- Causal/LightCone.agda

same-time-spacelike :
  Event.time e₁ ≡ Event.time e₂ → Spacelike CellAt Adj e₁ e₂
```

Events at the same time are automatically spacelike-separated.

**Cross-references:** [`formal/06-causal-structure.md`](06-causal-structure.md), `Causal/Event.agda`, `Causal/CausalDiamond.agda`, `Causal/LightCone.agda`.

---

## Theorem 6: Matter as Topological Defects

**Informal statement.** Non-trivial Wilson loops (holonomies ≠ identity) on the holographic network produce inhabited `ParticleDefect` types — topological defects in the gauge field interpretable as discrete matter.

**Agda type signatures:**

```agda
-- Gauge/Holonomy.agda

ParticleDefect :
  {G : FiniteGroup} {BondTy : Type₀}
  → GaugeConnection G BondTy → List (BondTy × Dir) → Type₀
ParticleDefect {G} ω boundary =
  holonomy {G} ω boundary ≡ FiniteGroup.ε G → ⊥

-- Concrete inhabitant for Q₈ on the star patch:
defect-Q8-i : ParticleDefect starQ8-i centralFaceBdy
```

**Proof method.** For `starQ8-i` (bond bCN0 = qi, rest = q1), the holonomy around the central pentagon reduces judgmentally to `qi`. The proof `defect-Q8-i p = qi≢q1 p` uses a discriminator function mapping `q1` to `⊥` and `qi` to `Q8`, then `subst` along the hypothetical path `qi ≡ q1`.

**Non-commutativity witness:**

```agda
-- Gauge/Holonomy.agda

noncommutative-holonomy :
  holonomy starQ8-ij centralFaceBdy     -- = qk   (i·j = k)
  ≡ holonomy starQ8-ji centralFaceBdy   -- = qnk  (j·i = −k)
  → ⊥
```

**Gauge-enriched bridge:**

```agda
-- Gauge/RepCapacity.agda

gauged-star-Q8 : GaugedPatchWitness Q₈
-- Packages: BridgeWitness (dim-2 bonds) + Q₈ connection + ParticleDefect
```

**Cross-references:** [`formal/05-gauge-theory.md`](05-gauge-theory.md), `Gauge/FiniteGroup.agda`, `Gauge/Q8.agda` (400-case associativity by `refl`), `Gauge/Connection.agda`, `Gauge/ConjugacyClass.agda`, `Gauge/RepCapacity.agda`.

---

## Theorem 7: Quantum Superposition Bridge

**Informal statement.** For any finite superposition of configurations with amplitudes in any algebra, the expected boundary entropy equals the expected bulk chain length — provided the per-microstate bridge holds.

**Agda type signature:**

```agda
-- Quantum/QuantumBridge.agda

quantum-bridge :
  (alg : AmplitudeAlg) {Config : Type₀}
  → (ψ : Superposition Config alg)
  → (S L : Config → ℕ)
  → ((ω : Config) → S ω ≡ L ω)
  → 𝔼 alg ψ S ≡ 𝔼 alg ψ L
```

**Proof method.** Structural induction on the list `ψ`. Base case: `refl` (empty sum = `0A`). Inductive step: `cong₂ _+A_ (cong (_·A_ α) (cong embedℕ (eq ω))) (quantum-bridge alg ψ S L eq)`. The proof is 5 lines, amplitude-polymorphic (works for ℕ, ℤ[i], or any `AmplitudeAlg`), and requires zero ring axioms.

**Concrete instantiation:**

```agda
-- Quantum/StarQuantumBridge.agda

star-quantum-bridge :
  (alg : AmplitudeAlg)
  → (ψ : Superposition (GaugeConnection Q₈ Bond) alg)
  → (r : Region)
  → 𝔼 alg ψ (λ ω → S-param starQ8Capacity r)
  ≡ 𝔼 alg ψ (λ ω → L-param starQ8Capacity r)
```

Verified with 3-configuration Q₈ superpositions exhibiting destructive interference (partial amplitude cancellation), with the bridge holding through the interference.

**Cross-references:** [`formal/07-quantum-superposition.md`](07-quantum-superposition.md), `Quantum/AmplitudeAlg.agda` (ℤ[i] instance), `Quantum/Superposition.agda` (𝔼 functional).

---

## Theorem 8: Structural Properties (Subadditivity & Monotonicity)

**Informal statement.** The boundary min-cut functional is subadditive, and the bulk minimal-chain functional is monotone under subregion inclusion.

**Agda type signatures:**

```agda
-- Boundary/StarSubadditivity.agda

subadditivity :
  ∀ {r₁ r₂ r₃ : StarRegion}
  → r₁ ∪ r₂ ≡ r₃
  → S-star r₃ ≤ℚ (S-star r₁ +ℚ S-star r₂)

-- Bulk/StarMonotonicity.agda

monotonicity :
  ∀ {r₁ r₂ : Region}
  → r₁ ⊆R r₂
  → L-star r₁ ≤ℚ L-star r₂
```

**Proof method.** Exhaustive case splits with `(k , refl)` witnesses. Subadditivity: 30 union triples on the 20-region star type (4 distinct witnesses). Monotonicity: 10 subregion inclusions (all witnessed by `(1 , refl)`). The 11-tile filled patch's 360 subadditivity triples are verified in `Boundary/FilledSubadditivity.agda` (auto-generated, sealed behind `abstract`).

**Full enriched equivalence:**

```agda
-- Bridge/FullEnrichedStarObs.agda

full-equiv : FullBdy ≃ FullBulk
full-transport : transport full-ua-path full-bdy ≡ full-bulk
-- Transport converts a subadditivity witness into a monotonicity witness.
```

**Cross-references:** [`formal/03-holographic-bridge.md`](03-holographic-bridge.md), `Bridge/EnrichedStarObs.agda`, `Bridge/EnrichedStarEquiv.agda`.

---

## Theorem 9: Step Invariance & Dynamics Loop

**Informal statement.** The discrete RT correspondence is preserved under arbitrary single-bond weight perturbations, and any finite sequence of such perturbations maintains the holographic bridge.

**Agda type signatures:**

```agda
-- Bridge/StarStepInvariance.agda

step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → ((r : Region) → S-param w r ≡ L-param w r)
  → ((r : Region) → S-param (perturb w b δ) r
                   ≡ L-param (perturb w b δ) r)

-- Bridge/StarDynamicsLoop.agda

loop-invariant : (w₀ : Bond → ℚ≥0)
  → ((r : Region) → S-param w₀ r ≡ L-param w₀ r)
  → (steps : List (Bond × ℚ≥0))
  → ((r : Region) → S-param (weight-sequence w₀ steps) r
                   ≡ L-param (weight-sequence w₀ steps) r)
```

**Proof method.** For the star topology, `S-param` and `L-param` are definitionally the same function (both defined by identical pattern-matching clauses). The hypothesis is redundant; the proof delegates to `SL-param-pointwise`. The loop invariant is structural induction on the list of perturbation steps.

**Cross-references:** [`formal/10-dynamics.md`](10-dynamics.md), `Boundary/StarCutParam.agda`, `Bulk/StarChainParam.agda`.

---

## Theorem 10: Enriched Step Invariance

**Informal statement.** The full enriched type equivalence (including subadditivity ↔ monotonicity conversion via `+-comm`) holds for *any* weight function, not just the canonical all-ones assignment.

**Agda type signature:**

```agda
-- Bridge/EnrichedStarStepInvariance.agda

full-equiv-w : (w : Bond → ℚ≥0) → FullBdy-w w ≃ FullBulk-w w

enriched-step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → FullBdy-w w ≃ FullBulk-w w
  → FullBdy-w (perturb w b δ) ≃ FullBulk-w (perturb w b δ)
```

**Proof method.** `S-param-subadd w` holds for variable `w` because both sides of each union inequality are the same computed expression (witness `(0, refl)`). `L-param-mono w` uses `+-comm` from `Util/NatLemmas.agda` for 5 of 10 cases; the other 5 hold by `refl`.

**Cross-references:** [`formal/10-dynamics.md`](10-dynamics.md).

---

## Additional Verified Artifacts

### Generic Bridge Validation

Six pre-existing bridge instances retroactively validated as instantiations of `GenericEnriched`:

```agda
-- Bridge/GenericValidation.agda

star-generic-witness   : BridgeWitness   -- 10 regions
filled-generic-witness : BridgeWitness   -- 90 regions
h3-generic-witness     : BridgeWitness   -- 26 regions (3D {4,3,5})
d50-generic-witness    : BridgeWitness   -- 139 regions
d100-generic-witness   : BridgeWitness   -- 717 → 8 orbits
d200-generic-witness   : BridgeWitness   -- 1246 → 9 orbits
```

Six additional layer instances produced by `orbit-bridge-witness` in `Bridge/SchematicTower.agda`:

| Instance | Tiling | Regions | Orbits | Max S |
|----------|--------|---------|--------|-------|
| Tree pilot | 1D tree | 8 | — | 2 |
| Star (6-tile) | 2D {5,4} | 10 | — | 2 |
| Filled (11-tile) | 2D {5,4} | 90 | — | 4 |
| Honeycomb (BFS) | 3D {4,3,5} | 26 | — | 1 |
| Dense-50 | 3D {4,3,5} | 139 | — | 7 |
| Dense-100 | 3D {4,3,5} | 717 | 8 | 8 |
| Dense-200 | 3D {4,3,5} | 1246 | 9 | 9 |
| {5,4} depth 2 | 2D {5,4} | 15 | 2 | 2 |
| {5,4} depth 3 | 2D {5,4} | 40 | 2 | 2 |
| {5,4} depth 4 | 2D {5,4} | 105 | 2 | 2 |
| {5,4} depth 5 | 2D {5,4} | 275 | 2 | 2 |
| {5,4} depth 7 | 2D {5,4} | 1885 | 2 | 2 |

### Resolution Tower & Convergence Certificate

```agda
-- Bridge/SchematicTower.agda

convergence-certificate-3L-HB : ConvergenceCertificate3L-HB
-- 3-level tower: Dense-50 (maxS=7) → Dense-100 (maxS=8) → Dense-200 (maxS=9)
-- Monotonicity: (1, refl) at each step
-- HalfBound at each verified level

layer54-tower : Layer54Tower
-- 6-level {5,4} tower: depths 2–7 (21 to 3046 tiles)
-- All maxCut = 2; LayerStep monotone = (0, refl)
```

### Area Law Instances

```agda
-- Boundary/Dense100AreaLaw.agda (717 abstract cases)
area-law : (r : D100Region) → S-cut d100BdyView r ≤ℚ regionArea r

-- Boundary/Dense200AreaLaw.agda (1246 abstract cases)
area-law : (r : D200Region) → S-cut d200BdyView r ≤ℚ regionArea r
```

### Coarse-Graining

```agda
-- Bridge/CoarseGrain.agda

dense100-coarse-witness : CoarseGrainWitness
-- 717 fine-grained regions → 8 orbit representatives
-- compat : refl (S-cut is definitionally S-cut-rep ∘ classify100)

-- Bridge/Dense100Thermodynamics.agda
dense100-thermodynamics : CoarseGrainedRT
-- Triple: (coarse-witness, regionArea, area-law)
```

### Causal Diamond

```agda
-- Causal/CausalDiamond.agda

layer54-diamond : CausalDiamond    -- 6 slices, proper time = 5
dense-diamond   : CausalDiamond    -- 2 slices, proper time = 1

maximin-layer54 : maximin layer54-diamond ≡ 2
maximin-dense   : maximin dense-diamond ≡ 9
```

---

## Verification Commands

```bash
# Core theorems (each loads all transitive dependencies):
agda src/Bridge/GenericBridge.agda        # Theorem 1 (RT, generic)
agda src/Bulk/GaussBonnet.agda            # Theorem 2 (Gauss–Bonnet)
agda src/Bridge/HalfBound.agda            # Theorem 3 (Bekenstein–Hawking)
agda src/Bridge/WickRotation.agda         # Theorem 4 (Wick Rotation)
agda src/Causal/NoCTC.agda                # Theorem 5 (No CTCs)
agda src/Gauge/Holonomy.agda              # Theorem 6 (Matter defects)
agda src/Quantum/QuantumBridge.agda       # Theorem 7 (Quantum bridge)

# Full repository (heaviest transitive closure):
agda src/Bridge/SchematicTower.agda       # Loads most of the repo
```

See [`getting-started/building.md`](../getting-started/building.md) for full build instructions and expected resource usage.

---

## What Is NOT Proven

- That discrete structures converge to smooth geometry as N → ∞
- That finite gauge groups relate to continuous Lie groups
- That the causal poset approximates a Lorentzian metric
- That "transport along a Univalence path" has physical meaning

See [`physics/translation-problem.md`](../physics/translation-problem.md) and [`physics/five-walls.md`](../physics/five-walls.md) for the honest assessment.
