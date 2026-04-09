# Project Roadmap

This roadmap is organized into six phases with explicit **gate reviews**
between them. Each gate references the minimal success criteria defined in
Section 6.9 and determines whether the project proceeds, pivots, or declares
a partial result. Duration estimates are given as ranges; research does not
run on a sprint clock.

Dependencies are indicated where phases overlap. The critical path runs
through Phases 0 → 1 → 2A/2B (parallel) → 3 → 4 → 5. The discovery
workbench ([§3.6](03-architecture.md#7-geometry-first-discovery-engine-non-critical-path)) runs in parallel and is not on the critical path.

---

## Phase 0: Foundations & Tooling (Weeks 1–8)

**Objective.** Acquire working fluency in HoTT concepts and Cubical Agda
syntax. Establish the development environment and project repository.

**Study track.**
Work through Chapters 1–4 of the HoTT Book, focusing on identity types,
transport, equivalences, and the Univalence Axiom. Supplement with the
Cubical Agda tutorial by Mörtberg (available in the `cubical` library
documentation) and the "Introduction to Univalent Foundations" lectures
by Rijke (2022).

**Formalization exercises.**
These are not project deliverables; they are finger exercises to build
fluency with `ua`, `Glue`, `transport`, `PathP`, and higher inductive
types.

  (a) Prove that the type `Bool ≡ Bool` has exactly two inhabitants.
  (b) Construct the equivalence `Fin n ≃ Fin n` and show that applying
      `ua` recovers a permutation.
  (c) Define a simple higher inductive type (e.g. the suspension of
      `Bool`, or a pushout) and prove a basic property of its path space.
  (d) Define a toy graph as a record type (3 vertices, 3 edges) and
      transport a function along a path between two such graphs via `ua`.

**Note on exercise (c).** The circle \(S^1\) as a HIT and the proof that
\(\Omega S^1 \simeq \mathbb{Z}\) are excellent goals but may require more
time than this phase allows. They are recommended as optional stretch
exercises.

**Environment.**
Install Agda (≥ 2.6.3) with the `cubical` library. Set up the repository 
with the directory structure from [Section 4](04-tooling.md). Configure 
a Makefile for incremental type-checking. Optionally set up a Jupyter + SageMath
environment for the prototyping work in Phase 1. Define, at this stage, a
neutral scene/state schema shared between Agda-facing specifications,
prototype notebooks, and the future browser visualizer; otherwise the
discovery layer and the formal layer will diverge immediately.

**Exit criterion.** Exercise (d) type-checks. The developer can explain,
on paper, the difference between `transport`, `subst`, and `PathP`, and
can construct a simple equivalence and apply `ua` without consulting
documentation for every step.

---

## Phase 1: Mathematical Prototyping (Weeks 5–12)

**Objective.** Work out the core mathematical constructions on paper and in
a computational algebra system *before* attempting formalization. This phase
prevents the common failure mode of getting lost in Agda syntax while the
underlying mathematics is still unclear. It also defines which invariants are
worth tracking, freezes the common source specification, and designs the
observable packages.

**1.1 — Select the toy model.**

**Reference.**
Pastawski et al. (2015), "Holographic Quantum Error-Correcting Codes" ([§7](07-references.md)).
This paper should be treated as the *specification document* for the toy model.

The primary target is the **HaPPY code** (Pastawski–Yoshida–Harlow–Preskill,
2015): a tensor network defined on a \(\{5,4\}\) hyperbolic tiling (regular
pentagons, four meeting at each vertex) that realizes a holographic
quantum error-correcting code. It has a finite boundary (the outermost
uncontracted legs of the tensor network), a finite bulk (the interior
tiles), and an explicitly computable Ryu–Takayanagi-like formula relating
boundary entanglement entropy to the number of bulk tiles cut by a minimal
geodesic. This is the most concrete and formalizable existing model of the
entanglement–geometry correspondence.

Because this model is defined on a pentagonal tiling while Phase 2B formalizes
a simplicial complex, Phase 1 must also fix a canonical triangulation
convention — e.g. barycentric subdivision or a chosen diagonalization of each
pentagon — and treat that convention as part of the specification.

~~**But first:** validate the entire pipeline end-to-end on the **tree instance
from [§3.5](03-architecture.md#6-worked-example--smallest-nontrivial-instance)** before scaling up to the HaPPY code.~~

**1.2 — Paper constructions.**

**Strong recommendation.**
Reproduce at least one figure or example from Pastawski et al. (2015)
numerically before formalization.

For the chosen model, write out by hand (or in SageMath / Python):
  (a) The boundary graph with entanglement weights. Compute the min-cut
      for several contiguous boundary intervals. Verify that the min-cut
      values match the expected bulk minimal chain lengths.
  (b) The bulk triangulation with discrete curvature. Compute combinatorial
      vertex curvature values. Verify discrete Gauss–Bonnet with the
      appropriate boundary term. If attempting metric curvature, also
      compute angle deficits and verify Gauss–Bonnet in the Regge form.
  (c) The common source specification \(c : C\) and both extraction
      functions \(\pi_{\partial}(c)\) and \(\pi_{\mathrm{bulk}}(c)\).
      Verify that both projections produce the expected structures.
  (d) The candidate observable packages and the pointwise functional
      agreement. Check, for all admissible regions on the concrete instance,
      that cut entropy equals minimal chain length.

**1.3 — Identify the observable package contents.**

**Reference anchors.**
- RT functional: Ryu–Takayanagi (2006)
- Spectral methods: graph Laplacians (standard spectral graph theory)

Determine precisely which data enters the observable package. The minimal
viable package contains the region index type and the cut/length functional.
Additional candidates (to be evaluated during prototyping) include: Euler
characteristic, degree sequence, curvature summary, and Laplacian spectrum.
Each candidate should be evaluated on two criteria: does it improve the
discriminating power of the package (i.e. help distinguish genuinely different
structures), and is it tractable to formalize in Cubical Agda?

Per [§3.0](assumptions.md), spectral data is computed during prototyping but **deferred from
formalization** unless it proves essential.

**1.4 — Define the invariant schema and scene model.**

Write down the canonical machine-readable representation manipulated by the
future visualizer. This schema should distinguish clearly between:

- the authoritative mathematical object,
- optional embedding / rendering data,
- derived invariants.

For small instances, define and compute a minimal signature containing at least:

- Euler characteristic,
- degree sequence,
- boundary-region min-cut profile,
- edge-length multiset,
- angle-deficit curvature values,
- Laplacian spectrum.

The result of this step is the exact contract between prototyping,
visualization, and formalization.

Additionally, define the **conjecture record format** ([§3.6](03-architecture.md#7-geometry-first-discovery-engine-non-critical-path)) 
as a structured schema capturing invariant signatures, corpus matches, deviation vectors, and
candidate equivalence statements. This format serves as the handoff artifact
from the discovery layer to the formalization pipeline and should be specified
alongside the invariant schema.

**1.5 — Seed the reference corpus.**

Before building any AI matcher, build a small curated database of reference
objects and their signatures, such as:

- trees, cycles, grids,
- small negatively curved triangulations,
- finite hyperbolic patches,
- simple MERA-like and HaPPY-like networks,
- hand-constructed counterexamples that look similar visually but differ
  mathematically.

This corpus becomes the ground truth library against which the realtime
validator compares live geometry states.

**Exit criterion.** A written mathematical document (can be informal, e.g.
a notebook or PDF) specifying: the concrete model (graph sizes, tiling
parameters), the common source specification, the extraction functions, the
observable packages, and numerical evidence that the packages agree on all
admissible regions. It must also specify the scene schema, the invariant
signature, and an initial reference corpus. This document becomes the
blueprint for Phases 2, 3, and 4.

---

## ► Gate Review 1 (after Phase 1)

**Question:** Is the chosen model tractable for formalization? Does the
common source specification cleanly produce both boundary and bulk views?
Do the observable packages agree on all test regions? Do the selected
invariants actually discriminate meaningful structures?

**Proceed** if yes. **Pivot** to a simpler model (e.g. smaller tiling,
tree network) if the packages disagree or if the common source specification
is ill-defined. **Declare partial result** and publish the mathematical
notebook if the model is interesting but clearly beyond formalization scope.

---

## Phase 2A: Formalizing the Boundary — Type A (Weeks 11–18)

**Objective.** Encode the boundary entanglement network from the Phase 1
blueprint as a Cubical Agda type, together with the min-cut functional and
its key properties.

**2A.1 — Graph type.**
Define the finite graph as a record with a finite vertex type,
adjacency/incidence relation, and boundary labels. Use set-truncation or
propositional edge witnesses where needed to ensure the resulting structure
lives at the intended h-level (per [Section 6.4](06-challenges.md#4-higher-coherence--controlling-homotopy-complexity)). 
Parameterize by the number of boundary sites \(N\).

**2A.2 — Weights and cut entropy functional.**
Implement edge weights as a function into ℚ≥0 (nonneg. rationals), per
[Section 6.2](06-challenges.md#2-real-valued-quantities--constructive-substitutes). 
Define the cut entropy functional
\(S_{\mathrm{cut}}(\mathcal{R})\) of a contiguous boundary interval
\(\mathcal{R}\) as the total weight of the min-cut separating
\(\mathcal{R}\) from its complement.

**2A.3 — Structural theorems.**
Prove: (a) monotonicity of the entropy functional under subregion
inclusion, (b) subadditivity, and (c) for the HaPPY code specifically,
the explicit min-cut values for a few chosen boundary regions (verified
against the Phase 1 notebook).

**2A.4 — Concrete instance.**
Instantiate the parameterized type at the specific \(N\) from the Phase 1
blueprint. This is the concrete object that will enter the equivalence
in Phase 3.

**Exit criterion.** The concrete boundary type and its entropy functional
type-check. At least one structural theorem (subadditivity or monotonicity)
is proven. This satisfies **[Milestone 2 of Section 6.9](06-challenges.md#9-minimal-success-criteria)**.

---

## Phase 2B: Formalizing the Bulk — Type B (Weeks 11–18, parallel with 2A)

**Objective.** Encode the bulk discrete geometry from the Phase 1 blueprint
as a Cubical Agda type, together with the curvature functional and the
discrete Gauss–Bonnet theorem.

**2B.0 — Scalar Upgrade (Constructive Rationals).**
Upgrade the `Util/Scalars.agda` interface to support the signed fractions required for combinatorial curvature. 
*Implementation Strategy:* Attempt the "Pure Route" first using `Cubical.HITs.Rationals.QuoQ`. If the proof overhead of working with quotient types (e.g., proving denominators are non-zero, reducing fractions for equality) threatens the schedule, gracefully fall back to a custom, finite `Frac10` set-truncated type to unblock the Gauss-Bonnet theorem.

**2B.1 — Simplicial complex type.**
Define a finite 2-dimensional simplicial complex: vertices, edges, and
triangular faces, with incidence data. Apply set-truncation. Parameterize
by the tiling used in the Phase 1 blueprint (e.g. the \(\{5,4\}\)
hyperbolic tiling, truncated to a finite patch), using the canonical
triangulation convention fixed in Phase 1.

**2B.2 — Discrete curvature.**

**Implementation note.**
Follow the decision frozen in [§3.0](assumptions.md). If combinatorial curvature (Option A) was
chosen, implement vertex curvature as a combinatorial deficit and skip
trigonometric computation. If Regge curvature (Option B) was chosen, assign
rational-valued edge lengths and implement the angle-deficit formula with
rational approximations.

**2B.3 — Discrete Gauss–Bonnet.**

Prove discrete Gauss–Bonnet at the appropriate level:
\[
\sum_{v \in \mathrm{int}(K)} \kappa(v) + \sum_{v \in \partial K} \tau(v)
= 2\pi\,\chi(K)
\]
This is **Theorem 1** from [§3.0](03-architecture.md#1-first-model-assumptions-and-initial-theorem-slate)
and is independently publishable.

**2B.4 — Minimal admissible chain length.**
Define the **length** of a bulk separating chain (a sequence of edges in the
dual graph or 1-skeleton separating two boundary regions) as the sum of edge
weights along that chain. Define the minimal such length for a given
boundary partition. In the 2D toy model this is the bulk-side RT analogue.
The term "minimal admissible chain length" is preferred over "minimal
geodesic length" to avoid overselling a discrete shortest path as a smooth
geodesic.

**2B.5 — Concrete instance.**
Instantiate at the specific tiling from the Phase 1 blueprint.

**Exit criterion.** The concrete bulk type, discrete curvature, and
Gauss–Bonnet theorem type-check. This satisfies **[Milestone 1 of
Section 6.9](06-challenges.md#9-minimal-success-criteria)**.

---

## ► Gate Review 2 (after Phases 2A and 2B)

**Question:** Do both concrete types exist as well-typed Agda terms? Do the
entropy functional (Type A) and the length functional (Type B) agree
numerically on the test cases from Phase 1?

**Proceed** if both types and at least one functional per side are
formalized. **Extend Phase 2** (add 2–4 weeks) if one side is lagging.
**Declare partial result** if the types are formalized but the functionals
are intractable — the discrete Gauss–Bonnet theorem and the entropy
inequalities are independently publishable.

---

## Phase 3: The Univalence Bridge (Weeks 17–28)

This is the core of the project and the phase most likely to require
iteration. It is broken into three sub-phases corresponding to increasing
levels of ambition. Phase 3 operates on the **common source / observable
package architecture** from [§3.3](03-architecture.md#4-common-source-specification-and-observable-packages), 
not on raw types.

**3A — Common source and extraction functions (Weeks 17–21).**

**Dependency.**
Must match the common source specification validated in Phase 1.

Implement the common source type \(C\) and both extraction functions
\(\pi_{\partial} : C \to A\) and \(\pi_{\mathrm{bulk}} : C \to B\).
Verify on the tree instance from [§3.5](03-architecture.md#6-worked-example--smallest-nontrivial-instance) 
that both extractions produce the expected types. 
Implement the observable-package extraction for both
sides: given a \(c : C\), produce \(\mathrm{Obs}_{\partial}(c)\) and
\(\mathrm{Obs}_{\mathrm{bulk}}(c)\) as record types.

**3B — Observable package equivalence (Weeks 20–25).**

**Warning.**
This step contains the core proof work. The difficulty depends on whether
functional agreement can be verified by finite enumeration over admissible
regions or requires structural induction.

For a fixed specification \(c : C\), construct the equivalence:
\[
e : \mathrm{Obs}_{\partial}(c) \simeq \mathrm{Obs}_{\mathrm{bulk}}(c)
\]

This requires:
  (a) a forward map \(f\) and inverse \(g\) between the package records,
  (b) proof that all fields are preserved (region index, functional values,
      well-formedness conditions),
  (c) coherent round-trip homotopies.

Because the packages are set-truncated records with a shared index type,
the equivalence reduces largely to proving pointwise functional agreement:
for every admissible region \(\mathcal{R}\), the cut entropy equals the
minimal chain length. This is the content of the discrete Ryu–Takayanagi
correspondence for the chosen instance.

If the full package equivalence is blocked (e.g. well-formedness conditions
diverge in unexpected ways), define a smaller sub-package containing only
the functional data and prove equivalence there. This is still a meaningful
partial result.

**3C — Univalence application and transport (Weeks 24–28).**

**Reference.**
HoTT Book, Chapter 4 (Univalence) and Cubical Agda examples using `ua`.

Given the exact equivalence from 3B, apply `ua` to obtain the path
\(p : \mathrm{Obs}_{\partial}(c) =_{\mathcal{U}} \mathrm{Obs}_{\mathrm{bulk}}(c)\).
Define a type family \(\Phi\) over the universe and compute:
\[
\mathrm{transport}^{\Phi}(p)(\rho_{\partial}) : \Phi(\mathrm{Obs}_{\mathrm{bulk}}(c))
\]
where \(\rho_{\partial}\) is the boundary observable bundle, and verify that
the result agrees with the bulk minimal-chain-length observable bundle.
This is the "compilation step": a computable transport between exactly
equivalent packaged types, yielding a verified translator.

This is **Theorem 3** from [§3.0](03-architecture.md#1-first-model-assumptions-and-initial-theorem-slate).

**Exit criterion.** The transport computes on the chosen observable package
and produces the correct bulk observable bundle. This satisfies
**[Milestones 3 and 4 of Section 6.9](06-challenges.md#9-minimal-success-criteria)**.

---

## ► Gate Review 3 (after Phase 3)

**Question:** Does `transport` along the Univalence path produce a computable
function that maps the boundary observable bundle to the corresponding bulk
observable bundle on the chosen exact observable package?

**Proceed to Phase 4** if yes. **Publish Phase 3A/3B results** as a
partial formalization of holographic correspondence if 3C is blocked.
**Return to Phase 1** with a revised model if the common source
specification or observable packages turned out to be wrong.

---

## Phase 4: Extraction, Simulation & Discovery Workbench (Weeks 26–36)

**Objective.** Extract the transport function as executable code and
build a visual demonstration together with a geometry-first research
interface.

**4.1 — Code extraction.**
Use Agda's MAlonzo backend (compiles to Haskell) or the JavaScript
backend to extract the transport function as a standalone program.
Verify that the extracted code, given a concrete entanglement pattern as
input, produces the correct bulk package — or, if Phase 3 stopped at the
observable level, the transported bulk observable bundle.

**4.2 — Interactive visualizer.**
Build a browser-based tool (Three.js or similar) that:
  (a) edits a canonical structured scene state rather than raw meshes,
  (b) displays the boundary graph with adjustable entanglement weights,
  (c) runs the extracted transporter on the current boundary state,
  (d) renders the resulting bulk triangulation when full reconstruction is
      available, or otherwise displays the transported bulk observables with
      their associated reference geometry,
  (e) animates the transition when weights are modified.

**4.3 — Discovery Engine: realtime validator and matcher.**

This subsystem is the runtime core of the Geometry-First Discovery Engine
defined in [§3.6](03-architecture.md#7-geometry-first-discovery-engine-non-critical-path). 
The term "Discovery Engine" refers to the overall subsystem;
"validator" and "matcher" name its two principal subcomponents (invariant
extraction and corpus comparison, respectively).

Given the current scene state \(X\), compute the invariant signature \(I(X)\)
live and compare it against the local corpus of reference structures. The tool
should report:

  (a) nearest known matches,
  (b) exact vs approximate invariant agreement,
  (c) which quantities are drifting under user edits,
  (d) AI-generated conjecture notes written in terms of explicit invariants.

The AI layer must remain auditable: every claim it makes should be reducible to
named features already present in the signature or corpus metadata.

**Note on the discovery workbench.** Phase 4.3 (realtime validator and
matcher) and Phase 4.4 (stress testing) are valuable but non-critical.
If time is limited after Phase 3, prioritize 4.1 (code extraction) and
4.2 (basic visualizer) over the full discovery workbench.

**4.4 — Stress testing and neighborhood exploration.**
Test the extracted transporter on boundary configurations not used during
development. Document where it produces physically reasonable geometries
and where it breaks down (these breakdowns are interesting — they map
the boundary of the model's validity). Use the validator to explore
"nearby-but-not-identical" structures systematically.

**Exit criterion.** A working demo that takes entanglement input and either
renders geometry output or reports the transported bulk observables justified
by the machine-checked proof, recomputes invariant signatures in real time,
and reports nearest known structural matches.

---

## Phase 5: Documentation & Publication (Weeks 28–36)

**Objective.** Write up results for publication and release the
formalization as an open artifact.

**5.1 — Technical report.**
A paper-length document describing the formalization: the model chosen,
the types defined, the equivalence constructed (or the partial results
achieved), and the lessons learned about formalizing physical
correspondences in HoTT. Target venue: a formalization workshop (e.g.
ITP, CPP) or a mathematical physics preprint on arXiv.

**5.2 — Literate Agda documentation.**
Convert key modules to literate Agda with embedded explanations, so
the proof code is readable as a self-contained narrative.

**5.3 — Open-source release.**
Clean up the repository, write a README with build instructions, tag a
release. The formalization itself is a contribution to the community
regardless of whether the full equivalence was achieved.

**Exit criterion.** Preprint submitted. Repository public.

---

## Timeline Summary

| Phase | Description                        | Weeks (best) | Weeks (expected) | Depends On   |
|-------|------------------------------------|--------------|------------------|--------------|
| 0     | Foundations & tooling               | 1–6          | 1–8              | —            |
| 1     | Mathematical prototyping            | 5–10         | 5–12             | 0            |
| G1    | Gate review 1                       | ~10          | ~12              | 1            |
| 2A    | Boundary formalization (Type A)     | 9–16         | 11–18            | 1            |
| 2B    | Bulk formalization (Type B)         | 9–16         | 11–18            | 1            |
| G2    | Gate review 2                       | ~16          | ~18              | 2A, 2B       |
| 3A    | Common source & extraction          | 15–19        | 17–21            | 2A, 2B       |
| 3B    | Observable package equivalence      | 18–23        | 20–25            | 3A           |
| 3C    | Univalence application & transport  | 22–26        | 24–28            | 3B           |
| G3    | Gate review 3                       | ~26          | ~28              | 3C           |
| 4     | Extraction, simulation & discovery  | 24–32        | 26–36            | 3C           |
| 5     | Documentation & publication         | 28–36        | 32–42            | 3, 4         |

**Best case:** 7–9 months, assuming prior comfort with dependently typed
programming and no major representation refactors.

**Expected case:** 10–14 months part-time, accounting for the learning curve
in HoTT/Cubical Agda, at least one major representation refactor, and
periods of stalling on hard sub-problems. This is the realistic estimate for
someone entering from a CS background without prior Agda or HoTT experience.

**Scope-reduced case:** 5–7 months to reach Milestones 1–2 only (discrete
Gauss–Bonnet and cut entropy functional), deferring the bridge and transport
to a second phase of work. This is a valid outcome and produces publishable
formalization results.

Gate reviews should not be rushed in any scenario.