# Known Challenges & Operational Research Constraints

This document does not merely list obstacles; it defines the *active research boundary* of the project. Each challenge is paired with a restriction, approximation, or concrete sub-problem that renders it tractable within a formalization setting.

---

## 1. The Continuum Limit — From Discrete to Smooth

**Reference anchors.**
- Regge calculus (discrete side)
- AdS/CFT literature (continuum side)
Bridging these is an open problem; no canonical reference exists.

**Problem.** The physically meaningful statement relates discrete structures (graphs, triangulations) to smooth manifolds via a limit \(N \to \infty\). A fully general theory of such limits inside Homotopy Type Theory is currently undeveloped.

**Operational constraint.**
All formalized results are restricted to **finite, combinatorial objects**:
- finite graphs (Type A),
- finite triangulations / simplicial complexes (Type B).

**Research direction.**
Rather than attempting a full continuum limit, the project targets **weak convergence notions** that are formalizable:
- spectral convergence (equality or approximation of Laplacian spectra),
- convergence of curvature functionals (e.g. angle-deficit sums),
- stability under refinement of triangulations.

**Concrete sub-goal.**
Define a notion of convergence
\[
T_n \to M
\]
such that discrete curvature and/or spectral data converge in a provable sense. This replaces the analytic continuum limit with a type-theoretic approximation scheme.

---

## 2. Real-Valued Quantities — Constructive Substitutes

**Implementation note.**
Prefer ℚ or dyadics unless a proof explicitly requires limits.

**Problem.** Entanglement entropy and curvature are real-valued. Constructive real analysis in Cubical Agda is significantly less developed than classical libraries.

**Operational constraint.**
All primary constructions use **computable numeric domains**:
- nonnegative rationals \(\mathbb{Q}_{\ge 0}\),
- dyadic rationals (binary fractions),
- or finite-precision approximations where necessary.

**Research direction.**
Lift results to more refined number systems only when required, and only after discrete versions are stable.

**Concrete sub-goal.**
Formalize:
- entropy-like functionals as rational-valued cut functions,
- curvature as combinatorial angle deficits,
and prove their key structural properties (monotonicity, additivity, invariance).

---

## 3. The Equivalence Gap — Exact vs Approximate Equivalence

**Conceptual reference.**
Compare with "duality vs isomorphism" discussions in AdS/CFT literature (Maldacena 1997, [§7](07-references.md)).

**Problem.** The Univalence Axiom applies only to *exact equivalences of
types*. Physical correspondences (e.g. AdS/CFT, RT) are often approximate,
asymptotic, or dependent on additional structure.

**Operational constraint.**
The project distinguishes sharply between:
- **exact equivalences of explicitly defined packaged types**, on which
  Univalence may be applied;
- **invariant-preserving correspondences** or controlled approximations, which
  count as partial results but do not themselves license `ua` on the raw
  structures.

All candidate Univalence steps therefore occur only after restricting to
finite, truncated, and explicitly packaged objects.

**Research direction.**
Move stepwise:
- first establish agreement of selected observables (spectra, min-cut / length
  profiles, etc.),
- then identify the smallest package of structure on which that agreement can
  be upgraded to an exact equivalence,
- apply Univalence only at that exact level.

**Concrete sub-goal.**
Working from the common source specification \(c : C\) 
([§3.3](03-architecture.md#4-common-source-specification-and-observable-packages)), 
construct observable packages \(\mathrm{Obs}_{\partial}(c)\) and
\(\mathrm{Obs}_{\mathrm{bulk}}(c)\) and either:

1. prove an exact equivalence
   \(\mathrm{Obs}_{\partial}(c) \simeq \mathrm{Obs}_{\mathrm{bulk}}(c)\)
   and apply Univalence to obtain transport; or
2. if exact package equivalence is blocked, record which invariants agree
   exactly and which only approximately, and report an
   invariant-preserving correspondence as a partial result.

As a **stretch goal**, investigate whether the equivalence extends beyond
observable packages to richer structural types — constructing maps
\(f : A \to B\) and \(g : B \to A\) on raw types with coherent round-trip
homotopies. This is the most ambitious target and is not expected for v1.

Invariant-preserving correspondence is therefore the main fallback result if
exact type equivalence is unavailable: it is valuable mathematics, but not
itself a Univalence bridge.

---

## 4. Higher Coherence — Controlling Homotopy Complexity

**Reference.**
HoTT Book (higher inductive types, truncation levels).

**Problem.** Full equivalences in higher-type settings require towers of coherence data, which quickly become intractable.

**Operational constraint.**
Both Type A and Type B are **set-truncated** unless higher structure is explicitly required:
\[
\| A \|_0, \quad \| B \|_0
\]

**Research direction.**
Reintroduce higher homotopy structure only where it encodes meaningful physics (e.g. gauge symmetries).

**Concrete sub-goal.**
Work initially in the category of sets (h-level 2), where:
- equivalences reduce to bijections with proofs,
- coherence reduces to standard round-trip homotopies.

---

## 5. AdS vs. Physical Spacetime

**Problem.** The entanglement–geometry correspondence is best understood in Anti-de Sitter (AdS) space, whereas the observed universe is approximately de Sitter (dS).

**Operational constraint.**
All geometric constructions are performed in **AdS-like or negatively curved settings**, typically:
- hyperbolic disks,
- triangulations with negative curvature (via angle deficits).

**Research direction.**
Treat the AdS setting as a **mathematical laboratory**, independent of direct physical realism.

**Concrete sub-goal.**
Demonstrate the entanglement–geometry mapping in hyperbolic discrete models without attempting extension to dS.

---

## 6. Computational Complexity and Proof Engineering

**Practical reference.**
Cubical Agda issue tracker and examples often document performance pitfalls better than formal papers.

**Problem.** Terms involving Univalence (`ua`) and Glue types can be computationally expensive to type-check and evaluate.

**Operational constraint.**
The codebase enforces **strict modularity**:
- small, composable lemmas,
- separation between proof-heavy and computation-heavy components,
- minimal use of large dependent eliminations.

**Research direction.**
Treat the formalization as a **compiler architecture problem**:
- core logical kernel (proofs),
- extraction layer (transport functions),
- runtime layer (simulation).

**Concrete sub-goal.**
Ensure that extracted transport functions remain computationally tractable, even if proofs themselves are complex.

---

## 7. The Inverse Problem — Geometry Underdetermines Mathematics

**Problem.** A rendered or embedded geometry does not determine a unique
mathematical structure. Distinct graphs, simplicial complexes, or weighted
objects can appear visually similar; conversely, small mathematical changes may
produce large visual changes.

**Operational constraint.**
The visualizer never treats pixels, meshes, or camera-space appearances as the
authoritative object. All interaction must compile down to a canonical internal
representation with explicit combinatorial and metric semantics.

**Research direction.**
Treat the discovery engine as a search over **equivalence classes described by
invariants**, not as a magical inversion from image to theorem.

**Concrete sub-goal.**
Every state edited in the visualizer must admit deterministic extraction of a
named invariant signature. If a user performs a deformation that cannot be
projected back into the canonical schema, that deformation is exploratory only
and cannot directly enter the formal pipeline.

---

## 8. AI as Heuristic, Not Oracle

**Problem.** AI systems are good at pattern suggestion and bad at providing
trustworthy guarantees in frontier mathematics. Used naively, they can create a
false sense of structural understanding.

**Operational constraint.**
AI is restricted to:

- ranking candidate matches from a curated corpus,
- summarizing invariant agreements and disagreements,
- proposing conjectures or missing quantities to compute.

AI is not permitted to count as evidence of equivalence, proof of transport,
or validation of physical interpretation.

**Research direction.**
Use AI where it is strongest — search, summarization, and analogy over a finite
knowledge base — while routing all mathematically load-bearing claims back
through explicit derivation and formalization.

**Concrete sub-goal.**
Design the validator so that every AI-generated statement can be traced to:

- a concrete invariant,
- a corpus entry,
- a numerical or symbolic comparison already performed by the system.

---

## 9. Minimal Success Criteria

Given the scope of the project, success is defined incrementally. The
following milestones are ordered by the critical path and are considered
sufficient outcomes independently of full equivalence. **Milestones 1 and 2
are the minimum viable project.**

1. **Discrete Geometry Foundations (Theorem 1)**
   - Formal proof of discrete Gauss–Bonnet (combinatorial or Regge form,
     with boundary correction for finite patches).
   - This is independently publishable as a formalization result.

2. **Boundary Formalization (Theorem 2)**
   - Verified implementation of the cut entropy functional via min-cut on
     finite weighted graphs.
   - Proof of at least one structural property (subadditivity or
     monotonicity).
   - This is independently publishable.

3. **Common Source and Observable Packages**
   - A well-typed common source specification producing both boundary and
     bulk views.
   - Observable packages extracted as record types from the common source.
   - This is publishable as formal infrastructure for holographic toy models.

4. **Bridge Construction — Observable Package Equivalence (Theorem 3)**
   - An exact equivalence between boundary and bulk observable packages for
     at least one concrete instance.
   - Transport along the Univalence path producing a verified translator.
   - This is the core novel result.

5. **Extraction and Demonstration**
   - The transport function extracted as executable code.
   - A working demo (visualizer or command-line) that takes boundary input
     and produces bulk observables justified by the machine-checked proof.

6. **Geometry-First Discovery Layer (Non-Critical)**
   - A working validator that extracts invariant signatures from structured
     live geometry states.
   - A curated corpus of reference structures.
   - Auditable AI-assisted reports.
   - This milestone is valuable but not required for the project to succeed.

## 10. Summary

The central strategy of the project is not to eliminate difficulty, but to
**bound it**:

- Replace continuum limits with discrete convergence schemes.
- Replace full real analysis with computable numeric approximations.
- Replace direct raw-type equivalence \(A \simeq B\) with exact equivalence
  of observable packages derived from a common source specification, and
  treat invariant-preserving correspondences as partial results rather than
  as automatic Univalence inputs.
- Replace uncontrolled higher coherence with truncation and explicit h-level
  discipline.
- Replace metric angle computation with combinatorial curvature for v1.
- Replace raw visual inversion with canonical scene states plus invariant
  extraction.
- Replace AI authority with AI-assisted conjecture ranking over a curated
  corpus.
- Treat the discovery workbench as non-critical-path infrastructure.

Within these constraints, the Univalence Axiom becomes operational only where
exact equivalence has actually been constructed: not as a philosophical
statement, but as a concrete mechanism for transporting structure between
formally defined domains. Elsewhere, the project records invariant-level
evidence honestly as evidence, not identity.

The result is a system where partial success is still mathematically precise,
mechanically verified, and incrementally extensible — and where the
contribution is framed as **proof engineering and constructive formalization**
rather than as a claim about physics.