# Introduction & Motivation

Contemporary mathematical physics contains a striking family of conjectured
dualities: correspondences between physically distinct-looking structures that
are claimed to be "equivalent" in some deep sense. The most prominent is the
**AdS/CFT correspondence** (Maldacena, 1997; [see §7](07-references.md)), 
which relates quantum entanglement on a boundary to geometry in a bulk spacetime. The
**Ryu–Takayanagi formula** (2006; [see §7](07-references.md)) sharpens this into a precise
equation: the entanglement entropy of a boundary region equals the area of a
minimal bulk surface, measured in Planck units. Entanglement *is* geometry, at
least in the AdS/CFT regime.

These correspondences are typically stated in the language of theoretical
physics — involving infinite-dimensional Hilbert spaces, smooth manifolds, and
path integrals — and their "exactness" is claimed but never machine-checked.
From a **computer science and formal methods perspective**, this situation
presents a concrete opportunity: the claimed equivalences have never been stated
as equivalences between precisely defined mathematical objects in any formal
system, and the "translation" between dual descriptions has never been
extracted as a verified program.

This project asks a narrow, well-defined question:

> **Can a finite, discrete toy model of a holographic correspondence be
> formalized in Cubical Agda such that the boundary-side and bulk-side
> observable packages are connected by an exact type equivalence, with
> Univalence providing computational transport between them?**

The vehicle is Homotopy Type Theory. In HoTT, mathematical objects are types;
equalities between objects are paths in a universe; and the Univalence Axiom
says that if one exhibits a coherent equivalence between two types, one obtains
a path between them. In Cubical Agda, transport along that path has
computational content — it reduces to an executable function. The project's
thesis is therefore a claim about constructive formalization:

> **If suitably packaged finite observable types on the boundary and bulk
> sides of a discrete toy model can be shown equivalent, Univalence turns
> that equivalence into a path, and transport along that path becomes a
> verified translator between boundary data and bulk observables — a
> machine-checked program extracted from a proof.**

This framing places the project squarely in the territory of **proof
engineering, type-theoretic library design, and verified computation**, with
physics as inspiration rather than as the primary audience. The contribution is
not a new physical theory; it is a demonstration that formal type-theoretic
tools — in particular Univalence and computational transport — can be brought
to bear on a correspondence previously discussed only informally. The
project's comparative advantage is abstraction, formal precision,
representation design, and the ability to make vague ideas machine-checkable.

Alongside this mathematical thesis sits a second, methodological thesis:
**visualization should not be treated merely as downstream output of
equations**. For this project, geometry can also function as a *research
interface*. One may begin from a desired discrete or embedded geometry,
manipulate it directly, measure its invariants, and ask which mathematical
structures it is closest to. This inverts the usual workflow:

> equation → render → inspect

into:

> specify / perturb geometry → extract invariants → identify candidate math

Properly understood, this is not an attempt to infer rigorous mathematics from
arbitrary screen pixels. The authoritative object is a structured scene state
(graph, simplicial complex, weights, metric annotations, boundary partition),
while rendering is only one view of that state. The "reverse" step is therefore
not image recognition but **invariant extraction from a mathematically typed
representation**. This discovery layer is, however, **explicitly secondary** to
the formal proof effort and is not required for any milestone.

The honest framing is that the project begins as a *learning laboratory* in
HoTT and formalization of mathematical-physics-adjacent structures, with the
long-range target of assembling the first machine-checked building blocks of
an entanglement–geometry bridge. Even partial results — a formalized
Ryu–Takayanagi statement for a toy graph, a verified discrete Gauss–Bonnet
theorem with boundary correction, or a transport lemma moving a boundary
observable bundle to a bulk observable bundle across an exact packaged
equivalence — would be novel contributions to the formalization community.

## Non-Goals for v1

The following are explicitly **out of scope** for the initial version of this
project. They may become future directions, but they are not measured against
and should not drive design decisions.

**No continuum limit.** All formalized objects are finite and combinatorial.
No attempt is made to formalize smooth manifolds, take limits as mesh size
goes to zero, or prove convergence to a continuum theory.

**No full smooth or Lorentzian geometry.** The "bulk geometry" is a finite
simplicial complex with combinatorial curvature, not a Riemannian or
Lorentzian manifold.

**No claim about physical spacetime.** Results concern a mathematical toy
model inspired by holographic physics. They do not constitute evidence for
or against any theory of quantum gravity.

**No raw-type equivalence unless explicitly proven.** The primary target is
observable-package equivalence. Any claim of equivalence on richer or raw
structural types requires its own proof and is treated as a stretch goal.

**No dependence on AI for any formal result.** AI is used only in the
non-critical-path discovery layer, and only for heuristic ranking and
summarization. No formal milestone depends on AI output.

**No full tensor-network semantics.** The project abstracts from the internal
tensor structure of the HaPPY code to its combinatorial and
graph-theoretic content. Full quantum-mechanical tensor contraction in Agda
is not attempted.

**No cohesive HoTT implementation.** [Cohesive HoTT (§2.4)](02-foundations.md#4-cohesive-hott-and-synthetic-differential-geometry--future-conceptual-horizon) is discussed as a
future conceptual horizon, not as near-term machinery.

**No interactive visualizer required for formal milestones.** The discovery
workbench ([§3.6](03-architecture.md#7-geometry-first-discovery-engine-non-critical-path)) 
is a research convenience tool. All formal milestones are defined independently of it.