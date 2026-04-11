# Mathematical Architecture

## 1. First Model Assumptions and Initial Theorem Slate

Before defining the individual types, the project relies on a strict set of 
combinatorial and topological boundaries for the chosen toy model (the HaPPY code). 
These are defined and frozen in `assumptions.md`.

**Initial theorem slate:**

The project targets three exact theorem candidates, in order of increasing
difficulty and ambition.

**Theorem 1 (Bulk foundations).** Discrete Gauss–Bonnet for finite
2-dimensional simplicial complexes with boundary:
\[
\sum_{v \in \mathrm{int}(K)} \kappa(v) + \sum_{v \in \partial K} \tau(v)
= 2\pi\,\chi(K)
\]
where \(\kappa\) is vertex curvature (angle deficit or combinatorial
surplus) and \(\tau\) is boundary turning angle. The closed case is a
corollary. This is a finite summation identity and is tractable in Cubical
Agda. It is independently publishable.

**Theorem 2 (Boundary foundations).** The min-cut entropy functional on a
finite weighted boundary graph is well-defined, and satisfies at least one
of: monotonicity under subregion inclusion, or subadditivity. This
establishes the boundary side as a rigorous formal object.

**Theorem 3 (Bridge).** For one fixed toy instance specified in Phase 1,
the boundary cut-entropy observable package and the bulk minimal-chain-length
observable package are exactly equivalent as types, and transport along the
resulting Univalence path carries the boundary functional to the bulk
functional. This is the core result. Even at the observable-package level, it
would be a novel machine-checked correspondence.

**Pivot criteria.** If, after Phase 1, the selected toy model does not admit
well-defined round-trip maps even at the observable level, pivot to a simpler
model (e.g. a tree tensor network, or a smaller tiling patch). If metric
angle computation in Agda proves numerically burdensome, remain with
combinatorial curvature and declare the metric extension a future direction.
If the inverse map \(g\) is unnatural on raw structures, commit fully to the
observable-package architecture without attempting raw-type equivalence.

## 2. Type A: Discrete Entanglement Networks

**Implementation note.**
Closely follows the HaPPY code construction (Pastawski et al. 2015, [§7](07-references.md)), 
which should be treated as the canonical concrete instance for Phase 1.

The boundary side is modeled as a **finite labeled graph** equipped with
additional quantum-informational structure. Concretely, Type A is built in
layers.

**Layer 0 — The graph.** A finite vertex type \(V\) of subsystems / degrees of
freedom, together with an adjacency or incidence family \(E : V \to V \to
\mathcal{U}\) and whatever boundary labels the toy model requires. For
practical Agda development, this should be implemented as a finite record type
or equivalent family-based encoding; a HIT presentation is a useful semantic
viewpoint, but should not be the default data structure unless it materially
simplifies a proof.

**Layer 1 — Entanglement weights.** Each edge carries a computable
nonnegative weight
\(\omega : \Sigma_{(v,w):V \times V}\, E(v,w) \to \mathbb{Q}_{\geq 0}\)
(or dyadics in later refinements), interpretable as the entanglement entropy
of the bipartite split across that link. For a MERA-like network, these
weights are structured by the renormalization hierarchy.

**Layer 2 — Cut entropy functional.**

**Reference anchor.**
This is the combinatorial analogue of the RT formula; 
see [§2.3](02-foundations.md#3-adscft-holography-and-ryutakayanagi) and Ryu–Takayanagi (2006).

For any contiguous boundary interval \(\mathcal{R}\) (per assumption 2 in
[§3.0](assumptions.md)), define the **cut entropy functional**
\(S_{\mathrm{cut}}(\mathcal{R})\) as the total weight of the minimal edge-cut
separating \(\mathcal{R}\) from its complement in the weighted graph. This is
the combinatorial analogue of entanglement entropy. In the 2D toy model, this
functional is what the Ryu–Takayanagi correspondence maps to minimal chain
length on the bulk side, with minimal surface area as the higher-dimensional
generalization.

The term "cut entropy functional" is preferred over "entanglement density"
because the object is region-dependent, not locally pointwise, and because
"entropy" is used here as a proxy defined by a min-cut, not as a full
quantum-mechanical von Neumann entropy. The proxy becomes exact under
perfect-tensor assumptions (as in the HaPPY code) but this should be stated
as an assumption, not a theorem.

**Layer 3 — Truncation discipline.** Depending on the chosen representation,
edge witnesses or graph-isomorphism data may need proposition- or set-level
truncation so that spurious higher structure does not enter by accident. The
choice here has real consequences for the equivalence in Phase 3.

## 3. Type B: Discrete Bulk Geometries

**Discrete reference.**
Regge calculus (Regge 1961, [§7](07-references.md)) is the primary formalization target for Phase 2B.

The long-term physics target is a Lorentzian spacetime, but the initial formal
object is more modest: a finite discrete bulk geometry approximating a
spacelike slice. Accordingly, the first formalization target is not a full
smooth Lorentzian manifold but a finite simplicial complex equipped with
metric data and Regge-style curvature. When this document uses "bulk
geometry" operationally, it means that discrete object; smooth and Lorentzian
structure remain interpretive goals for later work.

**Layer 0 — The combinatorial carrier.** A finite 2-dimensional simplicial
complex \(K\), typically a finite negatively curved patch with boundary.
Because the HaPPY code begins from a \(\{5,4\}\) pentagonal tiling rather than
a triangulation, Phase 1 must fix a canonical conversion to a simplicial
complex — for example, by barycentric subdivision or a chosen diagonalization
of each pentagon.

**Layer 1 — Discrete metric data.**

**First-pass strategy.** For the initial formalization, edge lengths are
rational-valued and may be uniform (all edges equal length) or assigned from a
small finite set of values determined by the tiling geometry. Triangle
inequality checking is required for faces. Optional embedding coordinates may
be stored for visualization but are auxiliary.

**Layer 2 — Discrete curvature.**

**Implementation note.**
The first-pass curvature notion is **combinatorial**, not metric. Two options
are available, and the choice is frozen in Phase 1.

**Option A — Combinatorial curvature (default for v1).** Define vertex
curvature as a function of the combinatorial neighborhood: the deviation of a
vertex's face count or degree from the value expected in a regular tiling.
For a \(\{5,4\}\)-derived triangulation, the "expected" count is determined by
the tiling parameters. This requires no trigonometry and no constructive-reals
machinery.

**Option B — Regge angle-deficit curvature (stretch goal for v1).** Assign
rational-valued edge lengths and define curvature via the angle-deficit
formula:
\[
\kappa(v) = 2\pi - \sum_{\text{faces } \ni v} \theta_v^{\text{face}}
\]
where angles are computed from edge lengths via rational approximations of the
law of cosines. This is the full Regge calculus approach and is more faithful
to the physics, but it introduces significant representational complexity:
trigonometric functions on rationals, approximation management, and
constructive proof obligations about angle bounds.

**Recommendation.** Begin with Option A. Prove discrete Gauss–Bonnet in the
combinatorial setting. Upgrade to Option B only if Option A is stable and if
the Phase 1 prototyping shows that metric curvature data materially improves
the correspondence.

**Implementation note (boundary curvature).**
For finite patches with boundary, both options require a boundary
turning-angle term. In Option A this is a combinatorial correction; in
Option B it is the discrete exterior angle at boundary vertices.

**Layer 3 — Continuum interpretation.** Once the discrete model is stable,
\(K\) may be interpreted as approximating a Riemannian spatial slice of a
Lorentzian spacetime. That continuum reading motivates the project, but it is
not the initial formal object.

## 4. Common Source Specification and Observable Packages

**New architectural principle.**
Instead of attempting a direct equivalence \(A \simeq B\) between boundary
networks and bulk complexes as raw types, the project introduces a
**common source specification type** from which both sides are derived.

**Motivation.** In the HaPPY code (and in most holographic toy models), the
boundary structure and the bulk structure are not independently defined objects
that happen to correspond. They are both determined by a single underlying
combinatorial specification — the tiling, together with boundary partition
data and weight assignments. The "maps" \(f : A \to B\) and \(g : B \to A\)
are more naturally understood as two projections from a common source than as
inverse functions between independently specified domains. A direct inverse
map \(g : B \to A\) on raw structures may be unnatural or underdetermined;
a common-source architecture avoids this by construction.

**Definition.** The **common source specification** is a type \(C\) that
encodes, at minimum:

1. a finite tiling specification (combinatorial type and truncation depth),
2. a canonical triangulation convention,
3. a boundary partition scheme (ordered cyclic boundary sites, admissible
   contiguous regions),
4. a weight assignment (rational-valued edge weights),
5. any auxiliary parameters required by the chosen toy model.

From \(C\), two extraction functions produce the boundary and bulk views:

\[
\pi_{\partial} : C \to A, \quad \pi_{\mathrm{bulk}} : C \to B
\]

These are not inverse maps; they are **projections** that extract the
appropriate semantic view from a shared specification.

**Observable packages.** The primary equivalence target is not \(A \simeq B\)
but rather a pair of **observable packages** extracted from the same common
source:

\[
\mathrm{Obs}_{\partial}(c) \quad \text{and} \quad \mathrm{Obs}_{\mathrm{bulk}}(c) \quad \text{for } c : C
\]

Each observable package is a finite record type containing:

1. an **index type** of admissible regions (contiguous boundary intervals),
2. a **functional** from regions to \(\mathbb{Q}_{\geq 0}\) (cut entropy on
   the boundary side, minimal chain length on the bulk side),
3. **well-formedness conditions** (e.g. monotonicity, subadditivity, boundary
   conditions),
4. optionally, additional invariant data (Euler characteristic, degree
   sequence, curvature summary) if these are included in the equivalence.

The **design decision** for v1 is:

> Observable-package equivalence is the **primary target**, not a fallback.
> Raw-type equivalence \(A \simeq B\) is a stretch goal that may be pursued
> only after the observable-level bridge is stable.

This is motivated both by tractability (observable packages are smaller,
more uniform types that are more likely to be exactly equivalent) and by
honesty (in many physical dualities, the claim is really about shared
observables, not about the identical structure of the underlying ontologies).

**Relationship to Univalence.** Given an exact equivalence
\(e : \mathrm{Obs}_{\partial}(c) \simeq \mathrm{Obs}_{\mathrm{bulk}}(c)\),
applying `ua` yields a path
\(p : \mathrm{Obs}_{\partial}(c) =_{\mathcal{U}} \mathrm{Obs}_{\mathrm{bulk}}(c)\),
and transport along \(p\) produces a computable translator between boundary
observables and bulk observables. This translator is the project's primary
computational artifact — a machine-checked program extracted from a proof of
type equivalence.

## 5. The Equivalence Problem

**Key dependency.**
This section depends critically on the invariant and package design selected in
Phase 1 ([§5](05-roadmap.md)) and frozen in [§3.0](assumptions.md) and
[§3.3](#4-common-source-specification-and-observable-packages).

The central mathematical challenge is to construct the exact equivalence
between observable packages extracted from the common source specification.
Concretely, for a fixed specification \(c : C\):

1. Define \(\mathrm{Obs}_{\partial}(c)\) and
   \(\mathrm{Obs}_{\mathrm{bulk}}(c)\) as record types per §3.3.
2. Construct a map
   \(f : \mathrm{Obs}_{\partial}(c) \to \mathrm{Obs}_{\mathrm{bulk}}(c)\)
   and an inverse
   \(g : \mathrm{Obs}_{\mathrm{bulk}}(c) \to \mathrm{Obs}_{\partial}(c)\).
3. Prove coherent round-trip homotopies: \(g \circ f \sim \mathrm{id}\) and
   \(f \circ g \sim \mathrm{id}\).
4. Apply `ua` to obtain the Univalence path.
5. Transport to obtain the verified translator.

Because both observable packages are derived from the same \(c\) and share the
same index type of admissible regions, the equivalence reduces to showing that
the boundary cut-entropy functional and the bulk minimal-chain-length
functional agree on every admissible region — plus agreement of any additional
invariant data included in the package. For the HaPPY code under
perfect-tensor assumptions, this agreement is exactly the discrete
Ryu–Takayanagi correspondence, and it is the content of **Theorem 3** from
[§3.0](#1-first-model-assumptions-and-initial-theorem-slate).

**Toy target (Phase 3a).** For one fixed small instance of \(c\) (specified
in [§3.5](#6-worked-example--smallest-nontrivial-instance) and refined in Phase 1), 
prove that the two observable packages are exactly equivalent as types. 
This may involve:

- verifying functional agreement region-by-region (finite enumeration),
- checking that well-formedness conditions are preserved,
- packaging the result as an explicit equivalence in Cubical Agda.

Exact or controlled approximate agreement of functionals is evidence for a
candidate correspondence and may already be a publishable partial result.
However, it is **not**, by itself, enough to justify application of Univalence:
the equivalence must be between fully specified types, not merely between
numerical outputs. Univalence enters only after constructing an exact
equivalence of the packaged record types.

**Stretch target (Phase 3b).** Formalize the Ryu–Takayanagi correspondence as
a type-theoretic transport statement: the boundary cut-entropy functional
should transport to the bulk minimal-chain-length functional along the
Univalence path. This would be a genuinely novel machine-checked result even
at the observable-package level.

**Stretch target (Phase 3c).** Investigate whether the equivalence can be
extended from observable packages to richer structural types — partial or
full raw-type equivalence. This is the most ambitious target and is not
expected to succeed in v1. Failure here is not project failure; it is a
data point about the limits of exact formalization for physical
correspondences.

## 6. Worked Example — Smallest Nontrivial Instance

**Purpose.** This section specifies one fully concrete tiny instance of the
correspondence, small enough to hold in one's head and to serve as the
first test case for every design decision, definition, and proof in the
project. Every Agda module should be tested against this instance before
moving to larger models.

**The model: a balanced binary tree network.**

Consider four boundary sites \(\{L_1, L_2, R_1, R_2\}\) connected by an
interior tree:

```
  L₁ ——(1)—— A ——(2)—— Root ——(2)—— B ——(1)—— R₁
              |                        |
  L₂ ——(1)——+                        +——(1)—— R₂
```

Here \(A\) and \(B\) are interior vertices, \(\mathrm{Root}\) is the central
interior vertex, and parenthesized numbers are edge weights.

**Edge weight summary:**

\(w(L_1, A) = 1\), \(w(L_2, A) = 1\), \(w(A, \mathrm{Root}) = 2\),
\(w(\mathrm{Root}, B) = 2\), \(w(B, R_1) = 1\), \(w(B, R_2) = 1\).

**Boundary regions.**
For the cyclic ordering \(L_1, L_2, R_1, R_2\), the nonempty proper
contiguous intervals consist of 4 singletons, 4 adjacent pairs, and 4 triple
intervals. For this worked example, we choose an explicit **representative
index type** of 8 admissible regions:

- the 4 singletons:
  \(\{L_1\}, \{L_2\}, \{R_1\}, \{R_2\}\),
- the 4 adjacent pairs:
  \(\{L_1, L_2\}, \{L_2, R_1\}, \{R_1, R_2\}, \{R_2, L_1\}\).

The triple intervals are omitted because each is the complement of a singleton
and therefore carries the same separating value in this symmetric cut setting.
This choice keeps the finite index type explicit and Agda-friendly.

| Region \(\mathcal{R}\) | Boundary min-cut | Bulk minimal chain length |
|-------------------------|------------------|---------------------------|
| \(\{L_1\}\)            | 1                | 1 (edge \(L_1\text{-}A\)) |
| \(\{L_2\}\)            | 1                | 1 (edge \(L_2\text{-}A\)) |
| \(\{R_1\}\)            | 1                | 1 (edge \(R_1\text{-}B\)) |
| \(\{R_2\}\)            | 1                | 1 (edge \(R_2\text{-}B\)) |
| \(\{L_1, L_2\}\)       | 2                | 2 (edge \(A\text{-}\mathrm{Root}\)) |
| \(\{L_2, R_1\}\)       | 2                | 2 (edges \(L_2\text{-}A\) + \(R_1\text{-}B\)) |
| \(\{R_1, R_2\}\)       | 2                | 2 (edge \(\mathrm{Root}\text{-}B\)) |
| \(\{R_2, L_1\}\)       | 2                | 2 (edges \(L_1\text{-}A\) + \(R_2\text{-}B\)) |

In every case, **boundary min-cut = bulk minimal separating chain length**.

**Observable packages for this instance.**

\(\mathrm{Obs}_{\partial}\): the record containing the representative finite
index type of admissible regions (the 8 explicit regions listed above) and the
min-cut functional taking values in \(\{1, 2\} \subset \mathbb{Q}_{\geq 0}\).

\(\mathrm{Obs}_{\mathrm{bulk}}\): the record containing the same finite index
type and the minimal-chain-length functional, also taking values in
\(\{1, 2\} \subset \mathbb{Q}_{\geq 0}\).

**The equivalence.** On this instance, the two record types have the same
index type and the same functional values on every representative region. The
resulting equivalence is therefore a trivial fieldwise equivalence, and `ua`
applied to it yields the corresponding path. This is intentionally simple:
the first formalization target should be obviously correct so that all the
**representation machinery** (graph types, complex types, observable-package
records, extraction functions, min-cut definitions, chain-length definitions)
can be tested against a known-good instance before scaling up.

**Scaling up.** After this tree instance type-checks end-to-end, the next
instance should be a small hyperbolic patch derived from the HaPPY code
(e.g. 1–2 layers of the \(\{5,4\}\) tiling), where the correspondence is
nontrivial and the equivalence requires real proof work.

**Common source for this instance.** The specification \(c : C\) is the tree
structure itself, together with the weight assignment and the cyclic boundary
ordering. The boundary extraction \(\pi_{\partial}(c)\) produces the weighted
boundary view. The bulk extraction \(\pi_{\mathrm{bulk}}(c)\) produces the
corresponding tree-shaped bulk view. From these two views, the observable
packages are computed by attaching the min-cut and minimal-chain-length
functionals on the shared finite index type of representative admissible
regions. All of these constructions are computable functions of \(c\).

## 7. Geometry-First Discovery Engine (Non-Critical Path)

**Status: non-critical-path.**
This subsystem is a parallel research-support tool and is **not required** for 
any formal milestone (Theorems 1–3, [Milestones 1–4 of §6.9](06-challenges.md#9-minimal-success-criteria)). 
Its schema should be defined early (Phase 1) to maintain compatibility with
the formal layer, but its implementation — especially the UI, matcher,
and AI components — should be deferred until after the first
machine-checked theorem.

This project includes a discovery subsystem whose purpose is to generate
candidate correspondences *before* formal proof, while remaining disciplined
enough to feed the formalization pipeline.

The phrase "reverse Three.js to the underlying math" should therefore be read
precisely. The system does **not** attempt to recover theorem-grade mathematics
from arbitrary rendered meshes or screenshots. Instead, the visual layer edits
a canonical structured object whose primitives already carry mathematical
meaning:

- finite graphs,
- simplicial complexes,
- embeddings into \(\mathbb{R}^2\) or \(\mathbb{R}^3\) when useful,
- edge weights / lengths,
- boundary labels and region selections,
- optional discrete metric and curvature annotations.

For any such object \(X\), the system computes an **invariant signature**
\[
I(X) =
\bigl(
  \chi(X),
  \deg(X),
  \mathrm{Spec}(\Delta_X),
  \mathrm{Cut}(X),
  \kappa(X),
  \mathrm{Sym}(X),
  \ldots
\bigr)
\]
whose components may include:

- Euler characteristic,
- degree sequence,
- Laplacian spectrum,
- boundary min-cut profile,
- discrete geodesic lengths,
- angle-deficit curvature values,
- automorphism / symmetry indicators.

**Implementation format.** Although \(I(X)\) is written above as a
mathematical tuple, the implementation encodes each signature as a
**named-field record** with semantic labels — not a positional vector of raw
numbers. Concretely, the matcher and AI layer receive structured data of the
form:

- `euler_characteristic`: integer,
- `degree_sequence`: sorted list of integers,
- `min_cut_profile`: map from region labels to \(\mathbb{Q}_{\geq 0}\) values,
- `curvature_type`: categorical descriptor (e.g. `negative_uniform`, `mixed`),
- `corpus_nearest`: identifier of the closest corpus entry,
- `deviation`: map from invariant names to numerical deltas.

This ensures that every output of the discovery layer — and every downstream
AI-generated statement — is **traceable to a named field**, satisfying the
auditability constraint of [§6.8](06-challenges.md#8-ai-as-heuristic-not-oracle). 
The named-field format also serves as the contract between the invariant-extraction code, 
the corpus comparison engine, and any AI summarization layer.

These signatures are then compared to a curated corpus of known structures
\(\mathcal{C}\) using a weighted similarity score
\[
\sigma(X,Y) = \sum_i w_i\, d_i\!\bigl(I_i(X), I_i(Y)\bigr),
\]
where the metric \(d_i\) and weights \(w_i\) are chosen according to the active
research phase. Early phases may privilege RT-relevant cut/length behavior in
the 2D toy setting; later phases may privilege spectral or curvature data.

The output of this layer is not a theorem but a **ranked conjecture report**:

- which known structures the current object is closest to,
- which invariants match exactly,
- where deviations occur,
- whether the mismatch is likely discretization error, parameter drift, or
  evidence of a genuinely different nearby model.

When a conjecture report identifies a promising candidate, the discovery layer
produces a structured **conjecture record** — the handoff artifact to the
formalization pipeline. This record captures:

- the invariant signature of the discovered object (in named-field format),
- the nearest corpus match and its deviation vector,
- a candidate equivalence statement in pseudocode (e.g.
  "\(\mathrm{Obs}_{\partial}(c) \simeq \mathrm{Obs}_{\mathrm{bulk}}(c)\) with
  functional agreement on all 8 admissible regions"),
- a human-readable hypothesis summarizing the conjecture.

The conjecture record is not Agda code, but it is structured enough that
translating it into Agda type definitions and proof obligations is mechanical
rather than creative. This closes the loop between the discovery layer and the
formal layer explicitly, and replaces the underspecified "export" step in the
tooling pipeline ([§4](04-tooling.md)) with a concrete artifact format. 
The format should be defined as a JSON schema (or equivalent) in Phase 1 alongside the invariant
schema ([§5, Phase 1.4](05-roadmap.md#phase-1-mathematical-prototyping-weeks-5-12)).

In this architecture, AI serves three bounded functions:

1. **Pattern explanation** — translate invariant matches into human-readable
   hypotheses.
2. **Corpus navigation** — surface nearby reference structures from a curated
   library.
3. **Conjecture generation** — propose candidate maps \(f\), \(g\), or missing
   invariants to test.

AI does **not** certify proofs, choose truth conditions, or replace the role of
Agda. Every successful match from the discovery engine must eventually be
re-expressed as explicit mathematics and, where possible, as a formal term in
the proof assistant.