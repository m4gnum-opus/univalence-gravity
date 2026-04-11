# Holographic Dictionary

**Agda Type ↔ Physics Counterpart — The Translation Table**

**Audience:** Theoretical physicists seeking to interpret the formal constructs; mathematicians seeking physical motivation for the type-theoretic definitions.

**Prerequisites:** Familiarity with AdS/CFT, the Ryu–Takayanagi formula, lattice gauge theory, and basic quantum gravity concepts. For the formal content referenced throughout, see [`formal/01-theorems.md`](../formal/01-theorems.md).

---

## 1. Purpose

This document maps every formally verified Agda construct in the repository to its hypothesized real-world physics counterpart. Each entry records:

- **The Agda construct** — the module, type signature, or definition.
- **The physical counterpart** — the continuum or semiclassical physics object it models.
- **Confidence** — a rating from ★★★ (well-supported by existing physics literature) to ★ (highly speculative), reflecting how well-established the correspondence is *independently of this project*.
- **The gap** — the principal obstruction to making the correspondence rigorous.

The dictionary is organized into seven sections corresponding to the seven pillars of the formalization: holographic correspondence, discrete geometry, gauge matter, causal structure, quantum superposition, thermodynamics, and dynamics.

**Honest caveat.** The entries rated ★★★ are correspondences that are well-known in the physics literature (e.g., lattice gauge theory, the Ryu–Takayanagi formula). The entries rated ★ or ★★ are interpretive — they are *plausible* translations, not established results. See [`physics/translation-problem.md`](translation-problem.md) for the full honest assessment and [`physics/five-walls.md`](five-walls.md) for the hard boundaries.

---

## 2. The Holographic Bridge

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `PatchData.RegionTy` (finite type, e.g., `D100Region` with 717 constructors) | `Bridge/GenericBridge.agda` | Boundary subregion *A* of the conformal boundary ∂*M* in AdS/CFT | ★★★ | Finite → infinite: the conformal boundary is a continuous manifold, not a finite set of cells |
| `S∂ : RegionTy → ℚ≥0` (min-cut entropy) | `Bridge/GenericBridge.agda` | Von Neumann entropy S_vN(ρ_A) = −Tr(ρ_A log ρ_A) of the reduced density matrix | ★★☆ | The min-cut is a combinatorial proxy; deriving S_cut = S_vN requires formalizing tensor contraction and the spectral theorem for perfect-tensor states |
| `LB : RegionTy → ℚ≥0` (minimal chain/surface) | `Bridge/GenericBridge.agda` | Area of the Ryu–Takayanagi minimal surface γ_A in Planck units: Area(γ_A) / 4G_N | ★★★ | The continuum RT surface is a codimension-2 extremal surface in a smooth bulk; the discrete chain is a set of bonds/faces in a graph |
| `obs-path : S∂ ≡ LB` (the discrete RT path) | `Bridge/GenericBridge.agda` | The Ryu–Takayanagi formula: S_A = Area(γ_A) / 4G_N | ★★★ | The formula is a conjecture in full generality; proven only for specific regimes (static, spherically symmetric, with 1/N corrections known) |
| `enriched-equiv : EnrichedBdy ≃ EnrichedBulk` | `Bridge/GenericBridge.agda` | The AdS/CFT correspondence itself: boundary CFT data is equivalent to bulk gravitational data | ★★☆ | The Univalence equivalence is between finite observable packages, not between infinite-dimensional Hilbert spaces or smooth field configurations |
| `transport (ua bridge) bdy-instance ≡ bulk-instance` | `Bridge/GenericBridge.agda` | Bulk reconstruction: computing bulk geometry from boundary entanglement data (entanglement wedge reconstruction, HKLL) | ★★☆ | The transport is a verified computable function; the physical bulk reconstruction involves operator algebra (modular flow) and causal wedge geometry |
| `BridgeWitness` (record packaging equivalence + transport) | `Bridge/BridgeWitness.agda` | A complete holographic dictionary entry: boundary and bulk descriptions are exactly equivalent, with a verified translator between them | ★★☆ | The record captures the finite, combinatorial core; the continuum correspondence involves infinite-dimensional structures |

---

## 3. Discrete Geometry and Curvature

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `κ-class : VClass → ℚ₁₀` (combinatorial curvature) | `Bulk/Curvature.agda` | Scalar curvature *R* of the bulk Riemannian metric, or Regge curvature on a simplicial manifold | ★★☆ | The combinatorial formula κ(v) = 1 − deg(v)/2 + Σ 1/p is a discrete proxy; convergence to smooth curvature requires a controlled continuum limit on the triangulation |
| `totalCurvature ≡ χ₁₀` (discrete Gauss–Bonnet) | `Bulk/GaussBonnet.agda` | The Gauss–Bonnet theorem: ∫_M K dA + ∫_{∂M} κ_g ds = 2π χ(M) | ★★★ | The discrete version is exact for any polyhedral complex; the smooth version follows in the continuum limit of Regge calculus (proven classically by Cheeger–Müller–Schrader) |
| `neg1/5 : ℚ₁₀` (interior curvature of {5,4}) | `Util/Rationals.agda` | Negative cosmological constant Λ < 0 (Anti-de Sitter) | ★★☆ | The combinatorial curvature is a vertex-level quantity; the cosmological constant is a smooth, global parameter |
| `pos1/10 : ℚ₁₀` (interior curvature of {5,3}) | `Bulk/DeSitterCurvature.agda` | Positive cosmological constant Λ > 0 (de Sitter) | ★★☆ | Same gap as above; additionally, the physical interpretation of de Sitter boundaries is contested |
| `PatchComplex` (30 vertices, 40 edges, 11 faces) | `Bulk/PatchComplex.agda` | A finite patch of the bulk spacetime manifold (a Regge triangulation or cell decomposition) | ★★☆ | The polygon complex is a fixed combinatorial object; the smooth manifold is a continuum limit |
| `D100EdgeClass` with `d100Kappa ev5 = negsuc 4` | `Bulk/Dense100Curvature.agda` | 3D edge curvature: angular deficit κ(e) = 2π − 5·(π/2) = −π/2 at fully-surrounded edges of the {4,3,5} honeycomb | ★★☆ | The 3D Regge curvature on edges is a well-studied discrete analogue; the gap is the passage to smooth Riemann curvature tensor |

---

## 4. Gauge Theory and Matter

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `GaugeConnection G Bond` (ω : Bond → G.Carrier) | `Gauge/Connection.agda` | A gauge connection A_μ on a principal G-bundle over spacetime (in lattice gauge theory: U_ℓ ∈ G on each lattice link ℓ) | ★★★ | The finite-group assignment is the standard lattice gauge theory formulation (Wilson 1974); the gap is the passage from the finite gauge group Q₈ to the continuous SU(2) |
| `holonomy ω boundary` (Wilson loop) | `Gauge/Holonomy.agda` | The Wilson loop observable W_f = Πₑ g_e around a plaquette, measuring gauge flux | ★★★ | This IS the standard lattice gauge theory definition of a plaquette holonomy |
| `ParticleDefect ω ∂f` (¬(holonomy ≡ ε)) | `Gauge/Holonomy.agda` | A gauge-theoretic defect (flux tube, monopole, or Wilson loop excitation W_f ≠ 1) localized at a plaquette | ★★★ | This IS the standard lattice gauge theory definition of a plaquette excitation; the gap is interpreting it as a "particle" (which requires dynamics, propagation, and the continuum limit) |
| `Q₈ : FiniteGroup` (quaternion group, \|Q₈\| = 8) | `Gauge/Q8.agda` | SU(2) (the gauge group of the weak interaction, or the spin group of spatial rotations) | ★★☆ | Q₈ ⊂ SU(2) is a well-studied finite subgroup (used in lattice QCD by Bhanot & Creutz 1981); the gap is the \|G\| → ∞ limit recovering the full Lie group |
| `ℤ/3 : FiniteGroup` | `Gauge/ZMod.agda` | U(1) (the gauge group of electromagnetism) | ★★☆ | ℤ/nℤ ⊂ U(1) for any n; the same \|G\| → ∞ limit gap |
| `dimQ8 q8-fund = 2` (representation dimension) | `Gauge/RepCapacity.agda` | The spin-1/2 representation of SU(2), with dimension 2; the bond capacity ln(dim ρ) is the Bekenstein–Hawking entropy contribution per edge in spin-network formulations | ★★☆ | The dimension functor is exact for finite representations; the spin-network entropy formula S = Σ_e ln(dim ρ_e) is a known result in Loop Quantum Gravity (Rovelli & Smolin 1995) |
| `Q8ConjClass` (5 conjugacy classes) | `Gauge/ConjugacyClass.agda` | The particle spectrum of the gauge theory: distinct particle species correspond to conjugacy classes (gauge-invariant quantum numbers) | ★★☆ | Conjugacy classes correctly classify gauge-invariant observables; the gap is that physical particles also require dynamics (propagation, mass spectrum) |
| `GaugedPatchWitness Q₈` | `Gauge/RepCapacity.agda` | A holographic spacetime with matter: a discrete network carrying both the holographic bridge (geometry ↔ entanglement) and gauge-field excitations (topological defects = particles) | ★☆☆ | This is the first machine-checked such object; the physics content depends on whether the discrete model has any relationship to actual matter |

---

## 5. Causal Structure

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `Event CellAt` (time : ℕ, cell : CellAt time) | `Causal/Event.agda` | A spacetime event: a point (t, x) in a globally hyperbolic Lorentzian manifold | ★★☆ | The discrete event uses ℕ-valued time and a finite cell type; the smooth event lives in a continuous manifold with Lorentzian metric |
| `CausalLink` (time-suc : suc(time e₁) ≡ time e₂) | `Causal/Event.agda` | A future-directed causal curve segment connecting two nearby spacetime events | ★★☆ | The type-level constraint suc(time e₁) ≡ time e₂ enforces strict time ordering by construction; in the continuum, the causal structure is determined by the light cone of the metric |
| `CausalChain` (composable sequence of links) | `Causal/Event.agda` | A causal curve γ: [0,1] → M connecting two spacetime events, with γ̇ future-directed | ★★☆ | The discrete chain has a well-defined "length" (number of steps); the smooth curve has proper time ∫√(−g_μν dx^μ dx^ν) |
| `CausalDiamond` | `Causal/CausalDiamond.agda` | A causal diamond J⁺(p) ∩ J⁻(q) in a globally hyperbolic Lorentzian spacetime | ★★☆ | The discrete diamond is a sequence of verified spatial slices connected by monotone extensions; the smooth diamond involves a Lorentzian metric and causal curves |
| `no-ctc : CausalChain e e' → CausalLink e' e → ⊥` | `Causal/NoCTC.agda` | Chronology protection: no closed timelike curves exist in physically reasonable spacetimes (Hawking's chronology protection conjecture) | ★★☆ | The discrete proof is structural (from the type signature); the physical conjecture involves the stress-energy tensor, topology change, and quantum backreaction — all absent from the discrete model |
| `maximin : CausalDiamond → ℚ≥0` | `Causal/CausalDiamond.agda` | The maximin prescription for covariant holographic entanglement entropy (Wall 2012): S_cov(A) = max_Σ min_{γ⊂Σ} Area(γ) | ★★☆ | The discrete maximin is a fold over finite slices; the continuous version involves optimization over all Cauchy surfaces in a Lorentzian spacetime |
| `same-time-spacelike : time e₁ ≡ time e₂ → Spacelike e₁ e₂` | `Causal/LightCone.agda` | Events at the same time on a Cauchy surface are spacelike-separated (incomparable in the causal order) | ★★☆ | The discrete version follows from ℕ well-foundedness; the continuum version requires defining simultaneity relative to a foliation |

---

## 6. Quantum Superposition

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `AmplitudeAlg` (record with A, _+A_, _·A_, 0A, embedℕ) | `Quantum/AmplitudeAlg.agda` | The algebraic structure of quantum probability amplitudes (a ring or semi-ring over which the path integral is evaluated) | ★★☆ | The record contains zero axioms — only operations; the physical amplitude algebra is ℂ (complex numbers) with full ring axioms |
| `ℤ[i]` (Gaussian integers: re + im·i) | `Quantum/AmplitudeAlg.agda` | Complex probability amplitudes α ∈ ℂ in quantum mechanics | ★★☆ | ℤ[i] ⊂ ℂ captures interference (destructive cancellation verified: `check-cancel`); the gap is density: ℤ[i] is discrete in ℂ, so continuous phases (e.g., e^{iθ} for irrational θ/π) are not representable |
| `Superposition Config alg` (= List (Config × A)) | `Quantum/Superposition.agda` | A quantum state ψ in a finite-dimensional Hilbert space, expressed in a particular basis as a superposition of configuration states | ★★☆ | The List encoding handles finite sums; the physical Hilbert space may be infinite-dimensional |
| `𝔼 alg ψ O` (fold over the superposition list) | `Quantum/Superposition.agda` | The expectation value ⟨ψ\|O\|ψ⟩ of a quantum observable O in state ψ, or the finite path integral Z⁻¹ Σ_ω α(ω) · O(ω) | ★★★ | This is the mathematical definition of a finite weighted sum; the physics content is that holographic duality survives quantization |
| `quantum-bridge alg ψ S L eq` (5-line proof) | `Quantum/QuantumBridge.agda` | Linearity of the path integral: ⟨S⟩_ψ = ⟨L⟩_ψ for any quantum state ψ if S(ω) = L(ω) for every classical configuration ω | ★★★ | This is a mathematical identity (linearity of finite sums); the physics content is that holographic duality survives quantization, which is expected but unproven in general QFT |

---

## 7. Thermodynamics and the Bekenstein–Hawking Bound

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `regionArea : RegionTy → ℚ≥0` | `Boundary/Dense100AreaLaw.agda` | The boundary surface area of a spatial region A in Planck units | ★★★ | The face-count area is exact for the discrete complex; the smooth area requires a Riemannian metric and integration |
| `area-law : S r ≤ℚ regionArea r` | `Boundary/Dense100AreaLaw.agda` | The Bekenstein–Hawking entropy bound: S(A) ≤ Area(∂A) / 4G_N (weak form) | ★★★ | The discrete isoperimetric inequality is a graph-theoretic tautology; the physical bound involves Newton's constant and the Planck area |
| `half-bound : (S r + S r) ≤ℚ area r` | `Bridge/HalfBound.agda` | The sharp Bekenstein–Hawking bound: S(A) ≤ Area(∂A) / 2 in bond-dimension-1 units, identifying 1/(4G) = 1/2 | ★★☆ | The discrete half-bound is proven by the two-cut decomposition (area = n_cross + n_bdy); the continuum identification of 1/(4G) with 1/2 requires understanding the bond-dimension ↔ Planck-area correspondence |
| `HalfBoundWitness pd` (area + half-bound + tight achiever) | `Bridge/HalfBound.agda` | A complete discrete Bekenstein–Hawking certificate: entropy is bounded by half the area, with equality achieved | ★★☆ | The witness is exact at every finite resolution level; the physics question is whether the discrete constant 1/2 relates to the physical Newton's constant G_N |
| `classify100 : D100Region → D100OrbitRep` | `Common/Dense100Spec.agda` | Coarse-graining: a macroscopic observer with limited memory classifies microscopic states into equivalence classes (thermodynamic averaging) | ★★☆ | The orbit reduction is a valid lossy compression that preserves the observable; the physics question is whether this is the "correct" coarse-graining for emergent smooth geometry |
| `CoarseGrainedRT` (triple: witness + area + bound) | `Bridge/CoarseGrain.agda` | The statement that the entropy–area relationship is preserved under thermodynamic averaging (the second law of horizon thermodynamics) | ★★☆ | The discrete triple is exact; the continuum extrapolation — that these witnesses converge to Einstein's equations via the Jacobson argument — is a conjecture |
| `DiscreteBekensteinHawking` (= ConvergenceCertificate3L-HB) | `Bridge/SchematicTower.agda` | The full discrete evidence package for the Bekenstein–Hawking formula: multi-resolution tower with monotone spectrum, sharp half-bounds at each level | ★☆☆ | This is the strongest formal statement, but interpreting it as "discrete quantum gravity" requires the translation path discussed in [`physics/translation-problem.md`](translation-problem.md) |

---

## 8. Dynamics and the Wick Rotation

| Agda Construct | Module | Physical Counterpart | ★ | Gap |
|---|---|---|---|---|
| `perturb w b δ` (single-bond weight change) | `Bridge/StarStepInvariance.agda` | A local unitary operation on the boundary quantum state, or a local modification to the bulk geometry (a "Pachner move" or "graph rewrite") | ★☆☆ | The perturbation changes a single bond weight; physical dynamics involves a Hamiltonian H, unitary time evolution U = e^{−iHt}, and backreaction of geometry on matter |
| `step-invariant` (RT preserved under perturbation) | `Bridge/StarStepInvariance.agda` | The holographic correspondence is preserved under local dynamics: the bulk geometry tracks the boundary entanglement at each time step | ★☆☆ | For the star topology, this is trivially true (S = L are the same function); for general patches it would require genuine graph-theoretic reasoning |
| `loop-invariant` (RT preserved under any finite sequence) | `Bridge/StarDynamicsLoop.agda` | Time evolution preserves the holographic duality: the "while(true) loop" of the universe compiling its next state | ★☆☆ | The discrete loop is structural induction on a list; physical time evolution is continuous and unitary |
| `WickRotationWitness` (shared bridge + AdS GB + dS GB) | `Bridge/WickRotation.agda` | The conjectured relationship between AdS/CFT and dS/CFT via analytic continuation L_AdS → iL_dS (Strominger 2001) | ★☆☆ | The discrete "Wick rotation" is a parameter change (q = 4 → 3) that flips the curvature sign while preserving the flow graph; the continuum Wick rotation involves complex analysis on the cosmological constant, Euclidean path integrals, and the still-unresolved nature of the dS/CFT boundary |
| `ConvergenceCertificate3L` (3-level tower) | `Bridge/SchematicTower.agda` | Evidence for universality of the holographic correspondence across scales (the holographic renormalization group) | ★☆☆ | The tower shows monotone growth of the min-cut spectrum (7 ≤ 8 ≤ 9); interpreting this as RG flow requires a notion of "running coupling" and a fixed point, neither of which is formalized |
| `Layer54Tower` (6 BFS depths, 21 → 3046 tiles) | `Bridge/SchematicTower.agda` | Spatial refinement of the bulk geometry: deeper layers resolve finer structure, analogous to the UV/IR connection in AdS/CFT | ★☆☆ | The exponential growth of tiles (21 → 3046) is the hallmark of hyperbolic geometry; interpreting this as UV/IR mixing requires the continuum limit |

---

## 9. Architectural Constructs (No Direct Physics Content)

| Agda Construct | Module | Role | Note |
|---|---|---|---|
| `ℚ≥0 = ℕ` | `Util/Scalars.agda` | Nonneg. scalar type for observables | No physical meaning; chosen for judgmental computation |
| `ℚ₁₀ = ℤ` | `Util/Rationals.agda` | Signed rational type for curvature (n/10) | Encoding choice; denominators dividing 10 suffice for {5,4} and {5,3} |
| `ObsPackage R` | `Common/ObsPackage.agda` | 1-field record wrapping obs : R → ℚ≥0 | Architectural packaging; no physics content |
| `TreeSpec` / `StarSpec` | `Common/TreeSpec.agda`, `Common/StarSpec.agda` | Common source specifications | Combinatorial data; the "physics" is in the observable agreement |
| `abstract` keyword | Various `*AreaLaw.agda`, `*HalfBound.agda` | Seals large case analyses to prevent RAM cascades | Proof engineering tool; no physics content (all sealed proofs are propositional) |
| `orbit-bridge-witness : OrbitReducedPatch → BridgeWitness` | `Bridge/GenericBridge.agda` | One-function composition producing a full proof-carrying bridge | Software architecture; the "physics" is that it works for *any* patch |
| `funExt` | Cubical Agda primitive | Function extensionality: pointwise equality → function equality | Mathematical infrastructure; assembles the discrete RT correspondence |
| `ua` / `uaβ` | Cubical Agda primitive | Univalence axiom / computation rule | The mechanism by which type equivalences become computable transport |

---

## 10. Reading Guide: Confidence Ratings

| Rating | Meaning | Examples |
|---|---|---|
| ★★★ | Well-established in the physics literature; the discrete construct IS the standard formulation (e.g., lattice gauge theory) or a direct theorem (e.g., Gauss–Bonnet) | `obs-path` ↔ RT formula; `holonomy` ↔ Wilson loop; `𝔼` ↔ finite path integral |
| ★★☆ | Plausible correspondence supported by structural analogy and limited literature; the discrete construct captures the *combinatorial core* of the physics | `enriched-equiv` ↔ AdS/CFT; `κ-class` ↔ scalar curvature; `no-ctc` ↔ chronology protection |
| ★☆☆ | Speculative interpretation; the correspondence requires assumptions not verified by the formalization | `WickRotationWitness` ↔ dS/CFT; `DiscreteBekensteinHawking` ↔ quantum gravity; `loop-invariant` ↔ time evolution |

The ★★★ entries are the safest: they correspond to mathematically precise identifications that would survive even if the broader physics interpretation fails. The ★☆☆ entries are the most ambitious: they are the "reach" interpretations that would follow only if the translation problem ([`physics/translation-problem.md`](translation-problem.md)) were solved.

---

## 11. The Geometric Blindness Observation

The deepest structural observation from the dictionary: the holographic bridge (`GenericBridge.agda`) depends on **strictly fewer** inputs than one would expect from the physics. It consumes exactly four inputs — `RegionTy`, `S∂`, `LB`, `obs-path` — and produces the full enriched equivalence, Univalence path, and verified transport.

Nothing about curvature, dimension, gauge groups, or Coxeter reflections appears in the proof. This blindness explains:

| What it explains | Column in this dictionary |
|---|---|
| The Wick rotation works (same term for {5,4} and {5,3}) | §8 — `WickRotationWitness` |
| The 3D extension works (same proof for cubes and pentagons) | §3 — edge curvature |
| The gauge enrichment is orthogonal (bridge sees only dim(ρ)) | §4 — `GaugedPatchWitness` |
| The quantum lift is trivial (5-line proof by cong₂) | §6 — `quantum-bridge` |

This suggests a meta-physical hypothesis:

> **The holographic correspondence is a property of information flow, not of geometry.** Geometry is compatible with, but independent of, the bridge. The bridge is the deeper structure; geometry is the enrichment.

Whether this observation survives the continuum limit — whether the "blindness" persists when smooth geometry replaces finite graphs — is the central open question of the translation problem.

---

## 12. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (ua, transport, funExt) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| The holographic bridge (core construction) | [`formal/03-holographic-bridge.md`](../formal/03-holographic-bridge.md) |
| Discrete geometry (curvature, Gauss–Bonnet) | [`formal/04-discrete-geometry.md`](../formal/04-discrete-geometry.md) |
| Gauge theory (Q₈, connections, holonomy) | [`formal/05-gauge-theory.md`](../formal/05-gauge-theory.md) |
| Causal structure (NoCTC, light cones) | [`formal/06-causal-structure.md`](../formal/06-causal-structure.md) |
| Quantum superposition bridge | [`formal/07-quantum-superposition.md`](../formal/07-quantum-superposition.md) |
| Wick rotation (curvature-agnostic bridge) | [`formal/08-wick-rotation.md`](../formal/08-wick-rotation.md) |
| Thermodynamics (area law, coarse-graining) | [`formal/09-thermodynamics.md`](../formal/09-thermodynamics.md) |
| Dynamics (step invariance, loop) | [`formal/10-dynamics.md`](../formal/10-dynamics.md) |
| Generic bridge and SchematicTower | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Translation problem (the honest assessment) | [`physics/translation-problem.md`](translation-problem.md) |
| The sharp 1/2 bound (physics significance) | [`physics/discrete-bekenstein-hawking.md`](discrete-bekenstein-hawking.md) |
| Three hypotheses for the continuum translation | [`physics/three-hypotheses.md`](three-hypotheses.md) |
| Five walls (hard boundaries of formalization) | [`physics/five-walls.md`](five-walls.md) |
| Historical development (§15.3 original dictionary) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §15.3 |

### Key Physics References

- Ryu, S. and Takayanagi, T. (2006). "Holographic Derivation of Entanglement Entropy from AdS/CFT."
- Maldacena, J. (1997). "The Large N Limit of Superconformal Field Theories and Supergravity."
- Pastawski, F., Yoshida, B., Harlow, D., and Preskill, J. (2015). "Holographic Quantum Error-Correcting Codes."
- Wilson, K. (1974). "Confinement of Quarks."
- Jacobson, T. (1995). "Thermodynamics of Spacetime: The Einstein Equation of State."
- Strominger, A. (2001). "The dS/CFT Correspondence."
- Wall, A. (2012). "Maximin Surfaces, and the Strong Subadditivity of the Covariant Holographic Entanglement Entropy."
- Regge, T. (1961). "General Relativity Without Coordinates."
- Rovelli, C. and Smolin, L. (1995). "Discreteness of Area and Volume in Quantum Gravity."
- Bhanot, G. and Creutz, M. (1981). "Variant Actions and Phase Structure in Lattice Gauge Theory."