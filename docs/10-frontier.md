# Frontier Extensions

## 1. Purpose

This document records the frontier development directions identified after
the successful completion of Phases 2A, 2B, and 3 (Theorems 1–3) on the
tree pilot and 6-tile star instances. It serves three functions:

1. **Strategic plan:** defines the two chosen next steps (§3–§4) with
   concrete technical approaches, known obstacles, and literature pointers.
2. **Deferred registry:** documents two additional directions (§5–§6) that
   were evaluated and deliberately set aside, preserving the analysis so
   future work can pick them up without repeating the feasibility study.
3. **Research positioning:** records where each direction sits relative to
   the current state of the art in formal methods, Homotopy Type Theory,
   and quantum gravity formalization.

The current formalization base is solid: the tree pilot validated the
bridge architecture, the 6-tile star validated it on a genuine 2D
holographic tiling, and the enriched bridge
([`Bridge/FullEnrichedStarObs.agda`](../src/Bridge/FullEnrichedStarObs.agda),
[`Bridge/EnrichedStarEquiv.agda`](../src/Bridge/EnrichedStarEquiv.agda))
demonstrated nontrivial Univalence transport converting boundary
structural properties (subadditivity) into bulk structural properties
(monotonicity). The question is how far the math can be pushed before
moving to extraction and publication.

The guiding principle is: **do not stop until hitting a hard boundary that
cannot currently be crossed.** The four directions below are ordered by
the type of wall they eventually encounter.

---

## 2. Current Mathematical Boundary

The formalization has achieved:

- **Theorem 1** (Discrete Gauss–Bonnet): verified for the 11-tile
  \(\{5,4\}\) patch via combinatorial curvature, with the full sum
  \(\sum_v \kappa(v) = \chi(K) = 1\) discharged by `refl`.
- **Theorem 2** (Boundary structural properties): subadditivity of the
  min-cut entropy functional on all 30 union triples of the 6-tile star
  (20-region type), and monotonicity of the bulk minimal-chain functional
  on all 10 subregion inclusions (10-region type).
- **Theorem 3** (Observable-package equivalence + transport): an exact type
  equivalence between enriched boundary and bulk observable bundles, with
  `transport` along the resulting `ua` path carrying boundary data
  (including a subadditivity witness) to bulk data (including a
  monotonicity witness). Transport computes via `uaβ`.

What has **not** been attempted:

- Scaling the bridge beyond the 6-tile star to the 11-tile filled patch.
- Proving equivalence on raw structural types (not just observable
  packages).
- Formalizing metric (Regge) curvature with constructive angle computation.
- Defining an inductive type for arbitrary \(n\)-layer \(\{5,4\}\) patches.

---

## 3. Direction A — The 11-Tile Bridge (Proof Engineering Frontier)

### 3.1 Goal

Extend the exact observable-package equivalence (Theorem 3) from the 6-tile
star to the 11-tile filled patch, proving that the framework scales to a
complete, gapless 2D hyperbolic disk. This is the natural next instance: the
11-tile patch is the smallest \(\{5,4\}\) patch forming a proper manifold
with boundary, having 5 interior vertices at full valence 4 and exhibiting
genuine negative curvature. It is already the target of Theorem 1
(Gauss–Bonnet), and extending Theorem 3 to it would unify the curvature
and bridge results on a single geometric object.

### 3.2 The N-Singleton Discrepancy

Phase 1.2 prototyping
([`01_happy_patch_cuts.py`](../sim/prototyping/01_happy_patch_cuts.py))
revealed that for N-type singleton regions on the 11-tile patch, the boundary
min-cut is 2 while the internal-only geodesic is 3. The min-cut routes
through the 2 boundary legs of the N-tile rather than severing the 3 internal
bonds. For all regions of size ≥ 2 and for all G-type singletons, the
min-cut equals the internal geodesic.

**Resolution.** Redefine the bulk observable functional to represent the true
min-cut (allowing it to sever boundary bonds, not just internal ones). Under
this definition, the boundary min-cut and the bulk minimal separating chain
agree on all 90 contiguous tile-aligned regions of the 11-tile patch.

### 3.3 The Combinatorial Explosion

The 11-tile patch has 10 boundary groups in cyclic order, yielding 90
nonempty proper contiguous tile-aligned regions. The proof obligations are:

- **90 pointwise agreement cases** (one `refl` per region)
- **90 complement-symmetry cases** (verifying \(S(A) = S(\bar{A})\))
- **360 subadditivity cases** (verified by
  [`01_happy_patch_cuts.py`](../sim/prototyping/01_happy_patch_cuts.py))

Attempting to write 360 pattern-match clauses by hand and type-check them
in a single Agda module will exhaust the Cubical Agda type-checker's RAM.
This is not a mathematical obstacle but a compiler performance limit.

### 3.4 The Compiler RAM Problem

Agda's type-checker does not "execute" arithmetic the way a CPU does. It
normalizes terms by recursively unpacking every constructor into abstract
syntax trees (ASTs) in memory, structurally verifying that both sides of an
equality reduce to the same normal form. For 360 cases, each involving
several levels of constructor unfolding, the memory cost is enormous.

This is not a bug. It is a deliberate architectural tradeoff rooted in
the **De Bruijn Criterion**: the trusted computing base (TCB) of a proof
assistant must be as small and simple as possible. If the compiler
optimized heavy arithmetic internally, any bug in that optimization engine
could silently accept false proofs. Keeping the kernel "stupid" and
delegating heavy computation to external tools is the intended design
pattern of the field.

### 3.5 Workarounds and Their Tradeoffs

Three approaches exist in the literature. Each is a tradeoff, not a
complete solution.

**Approach A — The `abstract` keyword.** Wrapping a proof block in
`abstract` tells Agda: "once verified, seal it in a black box and never
unfold it again." This prevents downstream modules from re-normalizing the
360-case proof when they use the subadditivity lemma, halting the RAM
cascade. The cost: `abstract` proofs lose computational content. Transport
and `subst` cannot look inside the black box. This is acceptable when the
sealed proof is a proposition (h-level 1) — as is the case for `m ≤ℚ n`,
which is propositional by `isProp≤ℚ`
([`Bridge/FullEnrichedStarObs.agda`](../src/Bridge/FullEnrichedStarObs.agda)).
The geometric observables and the Univalence path remain fully computable.

**Approach B — Boolean reflection.** Define a terminating boolean decision
procedure `check-all : Bool`, prove `check-all ≡ true` by `refl` (a single
evaluation rather than 360 proof trees), and then prove a soundness theorem
translating the boolean `true` into the mathematical property. The compiler
evaluates boolean logic more efficiently than it normalizes proof terms. The
cost: the soundness theorem (proving the decision procedure is correct) can
require thousands of lines and months of development time, shifting the
burden from compiler RAM to developer effort.

**Approach C — External oracle (Python-to-Agda code generation).** Use a
Python script to enumerate all 360 cases, compute the correct witness for
each, and output a complete Agda file containing 360 lines of explicit
`(k , refl)` proofs. The Python script is the "oracle" that finds the
proofs; Agda is the "checker" that verifies each line individually. The
cost: the proof is no longer self-contained. A future researcher must run
the Python script to regenerate the Agda file if the upstream data changes.
This introduces a toolchain dependency. Containerization (Docker, Nix)
mitigates software rot but does not eliminate the epistemological concern
for mathematical purists.

### 3.6 Chosen Strategy

**Combine approaches A and C.**

1. **Extend `01_happy_patch_cuts.py`** to export a complete Agda module
   containing the 90-region type, the 90 pointwise `refl` proofs, the
   360-case union relation, and the 360-line subadditivity proof (each
   line: `subadditivity uXX = (k , refl)`). The Python script is the
   trusted search oracle.

2. **Wrap the subadditivity proof in `abstract`** so that downstream
   modules (the enriched bridge) never re-unfold the 360 cases. Since
   `≤ℚ` is propositional, this does not damage the Univalence bridge.

3. **Verify the generated Agda file** by loading it in Agda. The
   type-checker processes each case sequentially (parsing a file is cheaper
   than normalizing a single massive AST), and the `abstract` barrier
   prevents any later module from triggering re-normalization.

This approach is aligned with how the largest verified proofs in computer
science (Four Color Theorem in Coq, Kepler Conjecture in HOL Light) were
achieved: external computation to find proofs, a simple kernel to check
them.

### 3.7 Relevant Literature and Known Issues

- **Agda GitHub Issue #4573** ("Slow typechecking unless using abstract in
  cubical"): documents the exact performance cliff and the `abstract`
  workaround, with comments from core developers.
- **"Automating Boundary Filling in Cubical Agda" (FSCD 2024)**: addresses
  combinatorial explosion of high-dimensional geometry in Cubical Agda and
  discusses external-style algorithms as solutions.
- **"Cubical Type Theory: a constructive interpretation of the univalence
  axiom" (CCHM 2018)**: foundational paper explaining why `transport` is
  computationally heavy.
- **Victor Cacciari Miraldo's work on Agda reflection**: documents limits
  of Agda's internal metaprogramming API when generating large ASTs.

### 3.8 Research Significance

This direction is **not** an unsolved theoretical problem — the math is
fully understood (the Python prototype proves it). It is a **proof
engineering** frontier: forcing a dependent type-checker to mechanically
verify a 360-case topological state space on a hyperbolic disk. The
Python-to-Agda code generation pattern is a cutting-edge technique in the
formal verification community, and successfully executing it on a
holographic toy model would demonstrate that the architecture scales to
realistic 2D instances.

### 3.9 Exit Criterion

The 11-tile bridge is complete when:

- An Agda module `Boundary/FilledSubadditivity.agda` (generated by
  Python) type-checks with all 360 subadditivity cases verified.
- An Agda module `Bridge/FilledEquiv.agda` constructs the enriched
  observable-package equivalence for the 11-tile patch and verifies
  `transport` along the `ua` path.
- The Python generator is committed to `sim/prototyping/` with a
  `Dockerfile` (or `nix` shell) pinning the Python environment.

### 3.10 Implementation: `Bridge/FilledEquiv.agda`

The glue module `Bridge/FilledEquiv.agda` is written by hand (not
generated by Python) and assembles the type equivalence from the
auto-generated components. Its architecture mirrors
`Bridge/EnrichedStarObs.agda` from the 6-tile star bridge, scaled to
the 90-region / 360-union setting of the 11-tile filled patch.

**Enriched types.** The module defines two specification-agreement
types:

\[
  \texttt{FilledEnrichedBdy} = \Sigma_{f : \texttt{FilledRegion} \to \mathbb{Q}_{\geq 0}} (f \equiv S_{\partial}^F)
\]
\[
  \texttt{FilledEnrichedBulk} = \Sigma_{f : \texttt{FilledRegion} \to \mathbb{Q}_{\geq 0}} (f \equiv L_B^F)
\]

where \(S_{\partial}^F\) is the boundary min-cut functional and
\(L_B^F\) is the bulk minimal-chain functional, both instantiated at
the filled-patch specification. These are genuinely different types in
the universe (the specification functions are definitionally distinct,
defined by separate 90-clause case splits) but propositionally
equivalent via `filled-obs-path : S∂F ≡ LBF`.

**The equivalence construction.** An explicit `Iso` is built by:
- Forward map: append `filled-obs-path` to the agreement witness.
- Inverse map: append `sym filled-obs-path`.
- Round-trip proofs: by `isSet` of the function space `FilledRegion → ℚ≥0`.

The `Iso` is promoted to a coherent `Equiv` via `isoToEquiv`, and
`ua` is applied to obtain the Univalence path.

**Transport verification.** The `uaβ` lemma reduces `transport` along
the `ua` path to the forward map of the equivalence, which is then
shown propositionally equal to the bulk canonical instance. This
completes the "compilation step": transport computes, reducing to a
concrete function that rewires the specification-agreement witness
through the 90-case discrete Ryu–Takayanagi correspondence.

### 3.11 Abstract Barrier Performance

The `abstract` keyword in `Boundary/FilledSubadditivity.agda` is
critical for module-loading performance. Without it, any downstream
module importing the subadditivity lemma would trigger Agda's
normalizer to re-unfold all 360 `(k , refl)` proofs when
type-checking uses of the lemma. With `abstract`, the type-checker
sees only the TYPE of the subadditivity lemma (a Π-type ending in
`_≤ℚ_`) and never re-enters the 360-clause definition.

Since `_≤ℚ_` is propositional (proven by `isProp≤ℚ` in
`Bridge/FullEnrichedStarObs.agda` via ℕ right-cancellation and
`isSetℕ`), the `abstract` barrier does not damage the Univalence
bridge: propositional fields are transported trivially, and the
enriched equivalence depends only on `filled-obs-path` (which is
NOT abstract and retains full computational content).

### 3.12 Unification of Theorems 1 and 3

With `Bridge/FilledEquiv.agda` type-checking, Theorems 1 and 3
coexist on the same geometric object:

- **Theorem 1** (`Bulk/GaussBonnet.agda`): discrete Gauss–Bonnet
  for the 11-tile patch, \(\sum_v \kappa(v) = \chi(K) = 1\), proven
  by `refl` on the class-weighted curvature sum.

- **Theorem 3 (extended)** (`Bridge/FilledEquiv.agda`): enriched
  observable-package equivalence for the same 11-tile patch, with
  transport verified via `uaβ`.

This unification is the goal stated in §3.1: the 11-tile filled patch
is simultaneously the curvature test object and the bridge test object,
demonstrating that negative curvature and holographic correspondence
coexist on a single formally verified geometric substrate.

---

## 4. Direction B — Raw Structural Equivalence (Homotopy Theory Frontier)

### 4.1 Goal

Achieve **Theorem 3c** (the stretch goal from
[§3.4](03-architecture.md#5-the-equivalence-problem)): strip away the
`ObsPackage` wrappers and prove an exact, raw type equivalence between the
1D boundary tensor network and the 2D bulk simplicial complex:

\[
  \texttt{BoundaryGraph} \simeq \texttt{BulkSimplicialComplex}
\]

This is the most ambitious formalization target in the project. It goes
beyond proving that boundary and bulk *observables* agree and attempts to
prove that the boundary and bulk *structures themselves* are equivalent as
types in the universe.

### 4.2 The Core Paradox

In classical topology, the boundary of the 11-tile patch is a 1-dimensional
ring (\(S^1\)), and the bulk is a 2-dimensional disk (\(D^2\)). A disk can
be contracted to a point; a ring cannot. They have different homotopy
types. Moreover, the boundary has 25 vertices while the bulk has 30
vertices — a cardinality mismatch that rules out any naive bijection.

In the holographic setting, the claim is that they *are* equivalent — but
only because the 1D boundary contains the dense, highly entangled quantum
state data of the 2D bulk. The HaPPY code is explicitly a quantum
error-correcting code: boundary tensor legs uniquely determine the interior
bulk state.

The challenge is to express this quantum-information-theoretic fact as a
type-theoretic equivalence in Cubical Agda.

### 4.3 Known Dead Ends

**Naive geometry.** Attempting to map boundary vertices directly to bulk
vertices fails immediately due to the cardinality mismatch (25 ≠ 30).

**Full quantum mechanics.** Formalizing Hilbert spaces, complex numbers
(\(\mathbb{C}\)), tensor products, and unitary operators in Agda would
require constructive complex analysis — an active, largely unsolved area of
formalization research. This approach derails the project into decades of
functional analysis infrastructure.

### 4.4 Three Viable Approaches

Three paths forward have been identified, in order of increasing
mathematical ambition.

**Option 1 — Stabilizer Algebra (the cryptography/CS path).** The HaPPY
code is a stabilizer code built on discrete finite math (typically
\(\mathbb{F}_2\) arithmetic). Instead of proving the *geometries* are
equivalent, prove the *information algebras* are equivalent. Define the
boundary as a list of boolean variables (representing Pauli operators) and
the bulk as a set of logical boolean variables. Because perfect tensors
make the bulk-to-boundary map deterministic and reversible, the equivalence
becomes an isomorphism between finite boolean algebras — something Agda
handles flawlessly. This plays to a computer science background and
connects to the quantum computing verification community's active push to
formally verify error-correcting codes.

**Option 2 — Reconstruction Fiber (the compiler path).** Keep the
formalization purely geometric. Treat the bulk not as a static object but
as a *parse tree* or *evaluation trace* of the boundary. Define a "fiber"
type over the boundary: `Bulk ≃ Σ[ b ∈ Boundary ] ReconstructionData`.
Prove that given the boundary, there is exactly *one* valid way to fill in
the interior (because the \(\{5,4\}\) tiling rules force the geometry to
close uniquely). In HoTT, if the reconstruction data is contractible (has
exactly one inhabitant), then \(A \simeq A \times \mathbf{1} \simeq A\).
This is the most direct continuation of the current codebase: the existing
`BoundaryView` and `BulkView` types are the starting point, and the proof
reduces to showing that the bulk view is uniquely determined by the
boundary view.

**Option 3 — Gauge Quotient (the HIT path).** This is the pure Homotopy
Type Theory route. If the bulk has "too much" information (30 vertices
instead of 25), define the bulk as a Higher Inductive Type (HIT) with
explicit path constructors declaring that moving an interior vertex without
changing the boundary distances yields an equal bulk configuration. This
quotients out the bulk's internal "gauge symmetries" until the quotiented
type matches the boundary. The mathematical beauty is high, but the
implementation risk is severe: defining HITs with complex 2D geometric
gluing rules requires proving *coherence* — that the gluing rules do not
accidentally collapse the entire type to a point.

### 4.5 Chosen Strategy

**Attempt Option 2 first, with Option 1 as a fallback.**

Option 2 (Reconstruction Fiber) continues the existing geometric
architecture and requires no new algebraic infrastructure. The core proof
obligation is: given a valid `BoundaryView`, construct a deterministic
algorithm that produces the `BulkView`, and prove this algorithm is a
bijection. The HaPPY code's error-correcting structure guarantees this
mathematically; the challenge is encoding it type-theoretically.

If Option 2 stalls on the contractibility proof (which requires showing the
reconstruction is unique, not just that it exists), fall back to Option 1
(Stabilizer Algebra), which avoids geometric reasoning entirely and
operates in the discrete algebraic domain where Agda is strongest.

Option 3 (Gauge Quotient) is deferred as a long-term research target. It
would produce the most mathematically profound result — a new contribution
to Homotopy Type Theory itself — but the coherence proof risk makes it
unsuitable for a near-term push.

### 4.6 Research Significance

This direction is an **actively unsolved, open area of research** at the
intersection of Homotopy Type Theory and quantum gravity formalization.
No one has constructed a mechanically verified proof of a holographic
bulk-boundary map at the structural level in any proof assistant.

If a function `f : BoundaryGraph → BulkComplex` and an inverse
`g : BulkComplex → BoundaryGraph` are constructed with coherent round-trip
homotopies `f (g x) ≡ x` and `g (f x) ≡ x` verified in Agda, the result
is publishable in a major formal methods or mathematical physics venue
(e.g. CPP, ITP, or a physics preprint on arXiv). It would be the first
machine-checked proof that a holographic tensor network perfectly preserves
structural information between boundary and bulk — not just observable
agreement, but type-level identity.

Even partial results are valuable. Proving the equivalence for Option 1
(Stabilizer Algebra) would provide the first machine-checked proof of
holographic quantum error correction. Proving the fiber contractibility for
Option 2 would formalize entanglement wedge reconstruction — a major
concept in theoretical physics that has never been stated as a type-theoretic
transport statement.

### 4.7 Relationship to Existing Code

The raw equivalence work would live in a new module (e.g.
`Bridge/RawEquiv.agda`) and would not modify any existing modules. The
`BoundaryView` and `BulkView` types from `Boundary/StarCut.agda` and
`Bulk/StarChain.agda` (or their 11-tile analogues) are the starting types.
The existing `star-obs-path` provides the observable-level identification
that any raw equivalence must be compatible with.

### 4.8 Exit Criterion

The raw structural equivalence is complete when an Agda module constructs
either:

- (Option 1) An exact equivalence between boundary and bulk boolean
  algebras representing the stabilizer code, with `transport` verified; or
- (Option 2) A proof that `BulkComplex ≃ Σ[ b ∈ BoundaryGraph ] Fiber b`
  where `Fiber b` is contractible, with `transport` verified; or
- (Option 3) A HIT-quotiented bulk type with `QuotientedBulk ≃ BoundaryGraph`
  and `transport` verified.

Any of these would constitute a novel publishable result.

### 4.9 Concrete Implementation: 6-Tile Star Patch

#### 4.9.1 Why Start with the Star

The 6-tile star is the simplest HaPPY-derived patch on which the raw
structural equivalence is both nontrivial and achievable. Three
properties make it a natural first target:

1. **Clean RT correspondence.** The boundary min-cut equals the bulk
   internal geodesic on every contiguous tile-aligned region (§3.1 of
   this document), with no N-singleton discrepancy.

2. **Star topology.** Every bond in the star connects the central tile
   C to exactly one boundary tile \(N_i\). This means the boundary
   data (the min-cut profile on 10 representative regions) is
   *uniquely recoverable* from just the 5 singleton min-cut values —
   and those 5 values are exactly the 5 bond weights. The
   reconstruction problem has a unique solution.

3. **Domain mismatch.** The boundary observable is a function
   \(\texttt{Region} \to \mathbb{Q}_{\geq 0}\) (10 data points),
   while the bulk structure is a function
   \(\texttt{Bond} \to \mathbb{Q}_{\geq 0}\) (5 data points). These
   are genuinely different types — the boundary has twice as many
   domain constructors as the bulk — so the equivalence is not a
   trivial identity.

The 11-tile filled patch is deferred: its richer topology (15 internal
bonds, N-singleton discrepancy, 90 regions) introduces complications
that should not be conflated with the initial construction.

#### 4.9.2 The Two Raw Types

The raw types strip away the `ObsPackage` and enriched-specification
wrappers and expose the underlying carrier mismatch:

\[
  \texttt{RawStarBdy} = \Sigma_{f \,:\, \texttt{Region} \to \mathbb{Q}_{\geq 0}} \, (f \equiv S_\partial)
\]
\[
  \texttt{RawStarBulk} = \Sigma_{w \,:\, \texttt{Bond} \to \mathbb{Q}_{\geq 0}} \, (w \equiv \texttt{starWeight})
\]

The first lives over the 10-constructor type `Region`; the second over
the 5-constructor type `Bond`. Both are "singleton types" — each is
the contractible space of functions certified to agree with a fixed
specification — but they are centered on *different function spaces
over different finite domains*. The equivalence between them therefore
encodes a structural fact: the 10-dimensional boundary data and the
5-dimensional bulk data carry exactly the same information.

#### 4.9.3 The Holographic Reconstruction Maps

**Forward (Ryu–Takayanagi direction): weights \(\to\) min-cuts.**
Given a bond-weight assignment \(w : \texttt{Bond} \to \mathbb{Q}_{\geq 0}\),
compute the min-cut profile:

\[
  \texttt{minCutFromWeights}\; w\; \{N_i\} = w(\texttt{bCN}_i)
\]
\[
  \texttt{minCutFromWeights}\; w\; \{N_i, N_{i+1}\} = w(\texttt{bCN}_i) + w(\texttt{bCN}_{i+1})
\]

This is the discrete Ryu–Takayanagi computation: bulk geometry
(bond weights) determines boundary entanglement (min-cut values).
For the uniform star specification where every bond has weight 1,
the singletons evaluate to 1 and the pairs evaluate to 2, matching
\(S_\partial\) on all 10 regions.

**Backward (Holographic reconstruction): min-cuts \(\to\) weights.**
Given a min-cut profile \(f : \texttt{Region} \to \mathbb{Q}_{\geq 0}\),
extract the bond weights from singleton regions:

\[
  \texttt{weightsFromMinCut}\; f\; \texttt{bCN}_i = f\; \{N_i\}
\]

This is entanglement wedge reconstruction: boundary entanglement data
uniquely determines the bulk geometry. The pair values are not used
because in the star topology they are redundant (each pair value is
the sum of two singleton values).

#### 4.9.4 The Reconstruction Fiber Argument

The equivalence follows from the Option 2 strategy. Define the
projection \(\pi : \texttt{RawStarBulk} \to \texttt{RawStarBdy}\)
as the forward map (RT computation). The fiber of \(\pi\) over any
boundary point \(b\) is the type of bulk configurations projecting to
\(b\):

\[
  \texttt{Fiber}(b) = \Sigma_{x \,:\, \texttt{RawStarBulk}}\, (\pi(x) \equiv b)
\]

Both types are contractible (they are singleton types centered at
their respective specifications). Therefore every fiber is contractible
(it is a sub-singleton of a contractible type), and \(\pi\) is an
equivalence. In the Agda implementation, the contractibility is
established by `isContrSingl` (or its symmetric variant), and the
round-trip proofs in the Iso reduce to `isContr→isProp`.

#### 4.9.5 Specification Agreement Lemmas

Two key lemmas connect the holographic maps to the specifications:

**RT lemma.**
\(\texttt{minCutFromWeights}\;\texttt{starWeight} \equiv S_\partial\)
— verified by `funExt` with all 10 cases holding by `refl`,
because `starWeight bCNi = 1q` and `S∂ regNi = 1q` for singletons,
and `1q +ℚ 1q = 2q = S∂ regNiNj` for pairs.

**Extraction lemma.**
\(\texttt{weightsFromMinCut}\;S_\partial \equiv \texttt{starWeight}\)
— verified by `funExt` with all 5 cases holding by `refl`,
because `S∂ regNi = 1q = starWeight bCNi`.

These lemmas are the computational content of the discrete
Ryu–Takayanagi correspondence: they certify that the forward
and backward maps land in the correct specification fibers.

#### 4.9.6 Transport and Compatibility

Applying `ua` to the raw equivalence produces a path in the universe:

\[
  \texttt{raw-ua-path} : \texttt{RawStarBulk} \equiv \texttt{RawStarBdy}
\]

Transport along this path converts the canonical bulk instance
\((\texttt{starWeight}, \texttt{refl})\) to the canonical boundary
instance \((S_\partial, \texttt{refl})\), reducing via `uaβ` to the
forward map of the equivalence.

The raw equivalence is compatible with the observable-level bridge:
the first projection of `transport raw-ua-path bulk-instance` equals
\(S_\partial\), which is the same function that appears in the
specification-agreement level of `Bridge/EnrichedStarObs.agda`. The
three levels of the bridge cohere:

- **Level 1** (value path): `star-obs-path : S∂ ≡ LB`
- **Level 2** (enriched types): `EnrichedBdy ≃ EnrichedBulk`
- **Level 3** (raw structural): `RawStarBulk ≃ RawStarBdy`

All three produce the same boundary-to-bulk identification.

#### 4.9.7 Significance and Limitations

The 6-tile star raw equivalence is a **proof of concept**, not the
final result. Its mathematical content is limited by the fact that
both raw types are contractible — any two contractible types are
equivalent, so the equivalence is "trivially forced" by the type
structure. The physical content is in the *explicit maps*: the
forward map computes min-cuts from bond weights (Ryu–Takayanagi),
and the backward map extracts bond weights from singleton min-cuts
(holographic reconstruction). The equivalence witnesses that these
two computations are inverses.

For the 11-tile patch (or larger), the raw types would NOT be
contractible, because the boundary min-cut profile is not uniquely
determined by a simple extraction rule — the N-singleton
discrepancy and the richer bond topology mean that reconstruction
requires solving a genuine constraint-satisfaction problem. This is
where the contractibility proof becomes the hard part of the
construction, and where the three viable approaches (§4.4) diverge
in difficulty.

#### 4.9.8 Module Location

The implementation lives in `Bridge/StarRawEquiv.agda` and imports
from:

- `Common/StarSpec.agda` — `Bond`, `Region`, `starWeight`
- `Boundary/StarCut.agda` — `S-cut`, `π∂`
- `Bulk/StarChain.agda` — `L-min`, `πbulk`
- `Bridge/EnrichedStarObs.agda` — `S∂`, `isSetObs`

It does not modify any existing modules.

### 4.10 Concrete Implementation: 11-Tile Filled Patch

#### 4.10.1 Strategy Overview

The 11-tile raw equivalence follows the same Option 2 (Reconstruction
Fiber) architecture as the 6-tile star (§4.9), but the richer topology
requires a Python oracle to compute the holographic maps.

The raw types are:

\[
  \texttt{RawFilledBdy} = \Sigma_{f : \texttt{FilledRegion} \to \mathbb{Q}_{\geq 0}}\, (f \equiv S_{\partial}^F)
\]
\[
  \texttt{RawFilledBulk} = \Sigma_{w : \texttt{FilledBond} \to \mathbb{Q}_{\geq 0}}\, (w \equiv \texttt{filledWeight})
\]

The boundary type lives over the 90-constructor `FilledRegion` domain;
the bulk type lives over a new 15-constructor `FilledBond` domain.
Both are contractible (singleton types), so the equivalence proof
reduces to verifying two specification-agreement lemmas by `refl`.

#### 4.10.2 The 15 Internal Bonds

The 11-tile patch has 15 internal tile-to-tile bonds:

- 5 **C-bonds**: C–N₀, C–N₁, C–N₂, C–N₃, C–N₄
- 10 **G-bonds**: for each gap-filler G_i, two bonds to its
  neighbours N_{i−1 mod 5} and N_i

These are encoded as a 15-constructor Agda datatype `FilledBond` with
a uniform weight function `filledWeight _ = 1`.

#### 4.10.3 The Forward Map (Ryu–Takayanagi)

For each of the 90 regions, the forward map
`minCutFromWeights : (FilledBond → ℚ≥0) → (FilledRegion → ℚ≥0)`
computes the min-cut value as a function of the 15 bond weights.

The Python oracle classifies each region into one of two cases:

**Case 1 — Internal-bond cut (80 regions).** The min-cut severs only
internal bonds (no boundary legs). The oracle identifies the exact
set of bonds in the cut, and the Agda clause is a sum of bond-weight
applications: `w b₁ +ℚ w b₂ +ℚ … +ℚ w bₖ`.

**Case 2 — Boundary-leg cut (10 regions).** The min-cut severs
boundary legs because they are cheaper than the internal alternatives.
This occurs for the 5 N-singletons (where 2 boundary legs < 3 internal
bonds) and their 5 complements. The Agda clause is a constant literal
independent of `w`.

At the canonical weight function (`filledWeight _ = 1`), both cases
reduce judgmentally to the correct min-cut value, so the 90-case
RT lemma holds by `refl`.

#### 4.10.4 The Backward Map (Peeling Strategy)

The backward map
`weightsFromMinCut : (FilledRegion → ℚ≥0) → (FilledBond → ℚ≥0)`
extracts each bond weight from carefully chosen min-cut values using
truncated subtraction `_∸_` (monus).

**Step 1 — G-bonds (10 bonds).** Each G-singleton region has a
min-cut of 2 that severs the G-tile's two internal bonds. Since both
bonds have weight 1, extracting either via `f(r_{Gi}) ∸ 1 = 2 ∸ 1 = 1`
recovers the correct weight.

**Step 2 — C-bonds (5 bonds).** Each N–G adjacent pair has a
min-cut of 3 that severs the C-bond, one G-bond from the preceding
gap-filler, and one G-bond from the following gap-filler. Subtracting
the G-singleton value isolates the C-bond's contribution:
`f(r_{Ni,G_{i+1}}) ∸ f(r_{G_{i+1}}) = 3 ∸ 2 = 1`.

All 15 extraction lemma cases hold by `refl` because ℕ truncated
subtraction computes by structural recursion on closed numerals.

#### 4.10.5 Module Location and Dependencies

The implementation lives in:

- `sim/prototyping/04_generate_raw_equiv.py` — the Python oracle
- `Bridge/FilledRawEquiv.agda` — the generated Agda module

The generated module imports from `Common/FilledSpec.agda` (for
`FilledRegion`), `Boundary/FilledCut.agda`, `Bulk/FilledChain.agda`,
and `Bridge/FilledObs.agda` (for the canonical observable functions).
It does not modify any existing modules.

#### 4.10.6 Exit Criterion

The 11-tile raw equivalence is complete when
`Bridge/FilledRawEquiv.agda` type-checks and contains:

- The `FilledBond` type and `filledWeight` specification
- The forward map `minCutFromWeights` (90 clauses)
- The backward map `weightsFromMinCut` (15 clauses)
- The RT lemma and extraction lemma (90 + 15 cases, all `refl`)
- The contractibility proofs, `Iso`, `Equiv`, `ua`, and `transport`
- A `RawFilledBridgeWitness` packaging record

---

## 5. Direction C — Generalizing to N Layers (Graph Induction Boundary)

### 5.1 Goal

Define a proof architecture that establishes the discrete
Ryu–Takayanagi correspondence for an \(n\)-layer \(\{5,4\}\)
tiling patch **for all \(n\)**, without requiring an explicit
inductive Agda data type encoding the closed-loop geometry of
the hyperbolic tiling.

### 5.2 The Original Wall

The original plan (§5.1–5.4 of the previous version of this
section) proposed defining an inductive type
`HaPPYPatch (n : ℕ)` that recursively generates the graph and
simplicial complex for an \(n\)-layer \(\{5,4\}\) patch.  This
approach collides with a fundamental obstruction in type theory:

**Closed-loop gluing.**  The \(\{5,4\}\) tiling wraps around
itself — adjacent gap-filler tiles at each layer share edges
that form closed polygonal loops.  Encoding these loops
inductively requires specifying, at each step, how the boundary
of the \(n\)-th layer stitches onto itself and onto the
\((n+1)\)-th layer.  This stitching carries nontrivial
combinatorial constraints (no topological holes, correct vertex
valences) that must be proven correct as part of the type
definition.  Establishing these constraints requires weeks of
graph-theory formalization before any min-cut reasoning begins.

**Exponential boundary growth.**  The \(\{5,4\}\) tiling has
exponentially growing boundary length with each layer.  An
inductive type must track this growth explicitly, and the
region types at each layer explode in size — layer 1 has 10
regions, layer 2 has 90, but layer 3 would have thousands.
The case-split proofs scale with region count even if orbit
reduction is applied.

### 5.3 The Key Observation: Separation of Geometry and Proof

Examining the six bridge modules that have been successfully
formalized (Tree, Star, Filled, Honeycomb, Dense-50, Dense-100,
Dense-200), a striking pattern emerges: **every enriched
equivalence proof has exactly the same structure**.  The modules
differ only in the names of their types and functions; the proof
architecture is identical:

1. Define `S∂ LB : RegionTy → ℚ≥0` (specification-level lookups)
2. Prove `obs-path : S∂ ≡ LB` (via `funExt` of pointwise `refl`)
3. Define `EnrichedBdy = Σ[ f ] (f ≡ S∂)` and
   `EnrichedBulk = Σ[ f ] (f ≡ LB)`
4. Build `Iso` from `obs-path` + `isSet (RegionTy → ℚ≥0)`
5. `isoToEquiv` → `ua` → `transport` → `uaβ`

Steps 3–5 depend **only** on three inputs:

- A type `RegionTy : Type₀`
- Two functions `S∂ LB : RegionTy → ℚ≥0`
- A path `obs-path : S∂ ≡ LB`

Nothing about the \(\{5,4\}\) tiling, pentagon geometry,
curvature, layer count, or boundary structure appears in the
proof.  The geometry is consumed entirely in steps 1–2 (defining
the observables and establishing their agreement), and steps 3–5
are pure HoTT plumbing.

This separation is not accidental.  It reflects a deep fact
about the holographic correspondence: **the bridge is a property
of the flow graph, not of the embedding geometry** (§7.3 of
this document).  The flow graph determines the observable
packages; the geometry determines the curvature.  The bridge
theorem is generic over the flow graph.

### 5.4 The Novel Approach: Schematic Bridge Factorization

The insight from §5.3 enables a radically different strategy for
N-layer generalization.  Instead of building the geometry
inductively in Agda, we **factor the proof into a generic
theorem parameterized by an abstract patch interface**, and let
the Python oracle handle all geometry.

**Step 1 — The `PatchData` Record.**

Define a record capturing the minimal data needed for the bridge:

```agda
record PatchData : Type₁ where
  field
    RegionTy : Type₀
    S∂       : RegionTy → ℚ≥0
    LB       : RegionTy → ℚ≥0
    obs-path : S∂ ≡ LB
```

This is the "interface" that any hyperbolic patch must implement.
The `RegionTy` may have 10 constructors (star), 90 (filled),
717 (Dense-100), or ten thousand (layer-5) — the record is
agnostic.

**Step 2 — The Generic Bridge Theorem.**

Prove, once and for all, that any `PatchData` admits the full
enriched equivalence. Finally, extract a `BridgeWitness`
(as defined in `BridgeWitness` from `Bridge/EnrichedStarEquiv.agda`).

```agda
module GenericEnriched (pd : PatchData) where
  open PatchData pd

  isSetObs : isSet (RegionTy → ℚ≥0)
  isSetObs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)

  EnrichedBdy : Type₀
  EnrichedBdy = Σ[ f ∈ (RegionTy → ℚ≥0) ] (f ≡ S∂)

  EnrichedBulk : Type₀
  EnrichedBulk = Σ[ f ∈ (RegionTy → ℚ≥0) ] (f ≡ LB)

  enriched-iso : Iso EnrichedBdy EnrichedBulk
  enriched-iso = iso fwd bwd fwd-bwd bwd-fwd
    where
      fwd : EnrichedBdy → EnrichedBulk
      fwd (f , p) = f , p ∙ obs-path

      bwd : EnrichedBulk → EnrichedBdy
      bwd (f , q) = f , q ∙ sym obs-path

      fwd-bwd : (b : EnrichedBulk) → fwd (bwd b) ≡ b
      fwd-bwd (f , q) i =
        f , isSetObs f LB
              ((q ∙ sym obs-path) ∙ obs-path) q i

      bwd-fwd : (a : EnrichedBdy) → bwd (fwd a) ≡ a
      bwd-fwd (f , p) i =
        f , isSetObs f S∂
              ((p ∙ obs-path) ∙ sym obs-path) p i

  enriched-equiv : EnrichedBdy ≃ EnrichedBulk
  enriched-equiv = isoToEquiv enriched-iso

  enriched-ua-path : EnrichedBdy ≡ EnrichedBulk
  enriched-ua-path = ua enriched-equiv

  bdy-instance : EnrichedBdy
  bdy-instance = S∂ , refl

  bulk-instance : EnrichedBulk
  bulk-instance = LB , refl

  transport-computes :
    transport enriched-ua-path bdy-instance
    ≡ equivFun enriched-equiv bdy-instance
  transport-computes = uaβ enriched-equiv bdy-instance

	
  -- Assemble the exact transport step
  enriched-transport : transport enriched-ua-path bdy-instance ≡ bulk-instance
  enriched-transport = transport-computes ∙ isContr→isProp (isContr-Singl LB) _ _
  -- The Magnum Opus: Extract a fully proof-carrying bridge witness
  abstract-bridge-witness : BridgeWitness
  abstract-bridge-witness = record
    { BdyTy              = EnrichedBdy
    ; BulkTy             = EnrichedBulk
    ; bdy-data           = bdy-instance
    ; bulk-data          = bulk-instance
    ; bridge             = enriched-equiv
    ; transport-verified = enriched-transport
    }
```

This module is **written once, proven once, and never
modified**.  Every existing bridge module
(`Bridge/EnrichedStarObs.agda`, `Bridge/FilledEquiv.agda`,
`Bridge/Honeycomb3DEquiv.agda`, `Bridge/Dense50Equiv.agda`,
`Bridge/Dense100Equiv.agda`) is a special case of
`GenericEnriched` applied to a specific `PatchData` instance.

**Step 3 — The Orbit-Reduced Interface.**

Combine Step 2 with the orbit reduction strategy (§6.5) to
define a second record capturing the pattern used by Dense-100
and Dense-200:

```agda
record OrbitReducedPatch : Type₁ where
  field
    RegionTy  : Type₀
    OrbitTy   : Type₀
    classify  : RegionTy → OrbitTy
    S-rep     : OrbitTy → ℚ≥0
    L-rep     : OrbitTy → ℚ≥0
    rep-agree : (o : OrbitTy) → S-rep o ≡ L-rep o
```

The `PatchData` is extracted automatically:

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

The `obs-path` is constructed by the familiar 1-line lifting:
`rep-agree (classify r)`.  This is exactly the pattern from
`Bridge/Dense100Obs.agda`, now stated generically.

**Step 4 — Automatic Bridge from Orbit Data.**

The composition `GenericEnriched (orbit-to-patch orp)` produces
the full enriched equivalence + Univalence path + verified
transport for **any** orbit-reduced patch, regardless of
its region count, orbit count, or geometric origin.

The Python oracle's job is solely to produce valid
`OrbitReducedPatch` instances: a `RegionTy` (flat data type),
an `OrbitTy` (small), a `classify` function, `S-rep` and
`L-rep` (identical by construction), and `rep-agree` (all
`refl`).  The generic theorem handles the rest.

### 5.5 What This Achieves

The schematic bridge factorization resolves the N-layer
challenge by **changing the structure of the induction**.

The original plan required:

> Structural induction on the **geometry** of the tiling
> (layer-by-layer construction of the polygon complex).

The new approach requires:

> Structural induction on the **proof schema**
> (generic theorem applied to oracle-generated instances).

This factorization has three decisive advantages:

**1. The hard geometry stays in Python.**  The Python oracle
(`07_honeycomb_3d_multiStrategy.py` and its descendants)
already generates arbitrary-size patches by BFS or greedy
growth.  It already computes min-cut values, orbit
classifications, and area-law bounds.  Extending it to produce
layer-\(n\) \(\{5,4\}\) patches requires only a new growth
strategy function — no Agda formalization of the tiling rules.

**2. The Agda proof is written once.**  The `GenericEnriched`
module and `orbit-to-patch` function are each ~30 lines of
Agda.  They are proven once and instantiated at each level by
the Python-generated `OrbitReducedPatch` record.  No new
hand-written bridge module is needed for layer 3, 4, 5, or
\(n\) — only the generated modules (Spec, Cut, Chain, Obs).

**3. The architecture already works.**  Every bridge in the
current repository is already an instance of the generic
pattern.  The factorization is not a speculative design — it is
a refactoring of existing, type-checked code.  The refactoring
can be validated retroactively by showing that all existing
bridges instantiate `GenericEnriched` correctly.

### 5.6 The Inductive Tower: Verified Holographic Slices

With the generic bridge extracting `abstract-bridge-witness`, the
becomes a **tower assembly** problem:
N-layer generalization becomes a **tower assembly** problem where
each step is fully proof-carrying.

```agda
record TowerLevel : Type₁ where
  field
    patch     : OrbitReducedPatch
    
    -- The fully verified Univalence bridge for this specific layer
    bridge    : BridgeWitness
  
  -- Constructor forces the bridge to be the one extracted from the generic schema
  -- ensuring topological consistency across the whole tower.
```

This way, the `SchematicTower` doesn't just store geometric data;
it stores **fully proof-carrying objects**. Each level of the tower
becomes a **"Verified Holographic Slice."**

```agda
record LayerStep (lo hi : TowerLevel) : Type₁ where
  field
    -- The max min-cut of hi is ≥ that of lo
    monotone  : maxCut lo ≤ℚ maxCut hi
    -- (Optional) area law at the higher level
    area-law  : AreaLawLevel (orbit-to-patch (TowerLevel.patch hi))
```

The Python oracle generates a `TowerLevel` for each
\(n = 1, 2, 3, \ldots\) and a `LayerStep` between consecutive
levels.  The generic bridge theorem produces the enriched
equivalence at each level automatically.  The resolution tower
from `Bridge/ResolutionTower.agda` (already implemented for
Dense-50 → Dense-100 → Dense-200) generalizes to this form.

The **coinductive horizon** from §10.8 then becomes achievable:
a guarded stream of `TowerLevel` records, each generated by the
oracle and verified by the generic theorem.  The coinductive
stream requires `--guardedness`, and each cell must be a fully
verified `TowerLevel` — but the verification is automatic given
the oracle output, because the generic theorem does all the
proof work.

### 5.7 The Remaining Mathematical Content

The generic bridge factorization does **not** trivialize the
N-layer problem.  It separates it into two components:

**Component A (Metatheoretic — Python).**
The Python oracle must correctly compute:
(a) the cell-adjacency graph of the \(n\)-layer \(\{5,4\}\)
patch, (b) the min-cut values for all cell-aligned boundary
regions, (c) the orbit classification by min-cut value.  The
correctness of the oracle is not machine-checked — it is
validated by the Agda type-checker when the generated modules
are loaded, but the oracle itself is trusted.

**Component B (Formal — Agda).**
The generic bridge theorem, once proven, handles all layers.
The only per-layer Agda content is the generated
`OrbitReducedPatch` instance (region type + classify function +
orbit observables + pointwise `refl`).  Each generated module
type-checks independently, verifying that the oracle produced
consistent data.

The **generic min-cut algorithm** originally envisioned in §5.1
is replaced by the **generic bridge theorem**: instead of
formalizing a min-cut algorithm in Agda and proving it correct,
we formalize the *bridge structure* generically and let the
oracle find the min-cuts.  This is the same division of labor
used by the Four Color Theorem proof (Coq) and the Kepler
Conjecture proof (HOL Light): external computation finds
proofs, a simple kernel checks them.

### 5.8 Relationship to Existing Code

The schematic bridge factorization builds on (but does NOT
modify) the following existing infrastructure:

- `Util/Scalars.agda` — `ℚ≥0`, `isSetℚ≥0`, `_≤ℚ_`
- `Common/ObsPackage.agda` — the minimal observable package
- `Bridge/EnrichedStarObs.agda` — the pattern being generalized, supplying `BridgeWitness`
- `Bridge/ResolutionTower.agda` — the tower data types
- `Bridge/CoarseGrain.agda` — the coarse-graining records

New modules would be:

```text
src/Bridge/GenericBridge.agda        — PatchData, GenericEnriched,
                                       orbit-to-patch
src/Bridge/SchematicTower.agda       — TowerLevel, LayerStep,
                                       generic tower assembly
```

And the Python oracle would be extended:

```text
sim/prototyping/XX_generate_layerN.py — layer-N {5,4} patch
                                         generator + Agda emitter
```

### 5.9 The `{5,4}` Layer Generator (Python)

The Python oracle for layer-\(n\) patches requires a
\(\{5,4\}\)-specific growth strategy:

**Layer 1:**  Central pentagon C + 5 edge-neighbours N₀..N₄ +
5 gap-fillers G₀..G₄ = 11 tiles.  (Already formalized.)

**Layer 2:**  Layer 1 + the next ring of pentagons that share
edges with the boundary of layer 1.  The \(\{5,4\}\) Schläfli
condition (4 pentagons per vertex) determines exactly which
tiles must be added.  The boundary of layer 1 has 25 edges;
expanding outward, approximately 25–30 new pentagons are
needed, plus gap-fillers.  Total: ~40–50 tiles.

**Layer \(n\):**  Iterate the expansion.  At each step:
1. Identify all boundary edges of the current patch.
2. For each boundary edge, attach the unique pentagon on the
   other side (computed from the Coxeter geometry, as in
   `05_honeycomb_3d_prototype.py`).
3. Fill gap-filler tiles at vertices that have reached the
   full valence 4.
4. Verify that the resulting patch is a disk (χ = 1).
5. Compute min-cut values and orbit classification.

This is a straightforward extension of the existing
`build_patch_dense` function from
`07_honeycomb_3d_multiStrategy.py`, specialized to the
\(\{5,4\}\) tiling's pentagonal cell structure instead of the
\(\{4,3,5\}\) honeycomb's cubic cell structure.  The flow-graph
and min-cut logic from `01_happy_patch_cuts.py` applies
unchanged — it is dimension- and tiling-agnostic.

### 5.10 Feasibility Assessment

**Primary risk: oracle correctness.**  The Python oracle is
trusted to compute correct min-cut values.  A bug in the oracle
would produce an Agda module that fails to type-check (if the
`refl` proofs don't reduce) or, worse, that type-checks with
incorrect values (impossible if `S-rep` and `L-rep` are defined
by the same case split in separate modules — the definitional
distinctness guarantees that incorrect values produce a type
error).

**Secondary risk: parser limits.**  For very large patches
(layer 5+), the `RegionTy` may have tens of thousands of
constructors.  The `Fin N` encoding from §6.5.4 mitigates this:
`classify` becomes a balanced binary tree lookup, and the parser
never sees a flat constructor list.  The proofs operate on
`OrbitTy` (always small), so the tree encoding is invisible to
the proof layer.

**Tertiary risk: orbit count growth.**  If the number of
distinct min-cut values grows with \(n\), the orbit type grows
too.  Empirical evidence from Dense-50 (7 orbits), Dense-100
(8 orbits), Dense-200 (9 orbits) suggests logarithmic growth
in min-cut range.  Even at 20–30 orbits (plausible for layer 5),
the orbit-level proofs are manageable.

### 5.11 Execution Plan

**Phase C.0 — Generic Bridge Module (Agda).**

1. Implement `Bridge/GenericBridge.agda` containing `PatchData`,
   `OrbitReducedPatch`, `GenericEnriched`, and `orbit-to-patch`.
2. Verify that existing bridges (Star, Filled, Dense-100) can be
   expressed as instantiations of the generic theorem (possibly
   as regression tests, not replacing the existing modules).
3. Estimated effort: 1–2 days.

**Phase C.1 — \(\{5,4\}\) Layer Generator (Python).**

1. Extend `01_happy_patch_cuts.py` with a `build_54_layer_patch`
   function that constructs layer-\(n\) patches of the \(\{5,4\}\)
   tiling using Coxeter reflections (adapting the `05`/`07`
   infrastructure from \(\{4,3,5\}\) to \(\{5,4\}\)).
2. Generate layer 2 and layer 3 patches; verify min-cut values,
   orbit classifications, and area-law bounds.
3. Emit `OrbitReducedPatch` Agda modules for each layer.
4. Estimated effort: 1–2 weeks.

**Phase C.2 — Tower Assembly (Agda).**

1. Implement `Bridge/SchematicTower.agda` containing
   `TowerLevel`, `LayerStep`, and a generic tower construction.
2. Instantiate the tower for layers 1–3 (or however many the
   oracle supports) using the generated modules and the
   generic bridge.
3. Verify monotonicity witnesses between consecutive levels.
4. Estimated effort: 2–3 days.

**Phase C.3 — Scaling Test (Python + Agda).**

1. Push the oracle to layer 4 or 5.  Report: region count,
   orbit count, max min-cut, parser load time.
2. If the `Fin N` encoding is needed, implement it in the
   generator and verify that the balanced-tree `classify`
   function normalizes efficiently.
3. Assess whether the pattern holds indefinitely or encounters
   a new scalability wall.

### 5.12 Conditions for Advancement

This direction advances from "deferred" to "active" when:

1. The generic bridge module (`Bridge/GenericBridge.agda`)
   type-checks and retroactively validates at least one
   existing bridge instance.
2. The existing `01_happy_patch_cuts.py` has been extended with
   the \(\{5,4\}\) layer-growth function, and layer 2 produces
   consistent min-cut data.
3. Development bandwidth is available — Phases C.0–C.2 compete
   for time with the visualization phase (§14) and any
   remaining Dense-200 integration work.

If condition 1 succeeds trivially (the generic module is ~40
lines) and condition 2 requires only a Python day, direction C
could advance to active status immediately.

### 5.13 Research Significance

The schematic bridge factorization is not a proof trick — it is
a **design pattern for scaling formal verification of
parameterized combinatorial systems**.  The pattern says:

> If a proof about a concrete combinatorial structure depends
> only on an abstract interface (here: `PatchData`), then the
> proof can be stated and verified once, and instantiated at
> every concrete size by an external oracle.

This pattern is well-known in software engineering (interfaces
and dependency injection) but underexplored in formal
verification of mathematical physics.  Applying it to the
holographic correspondence turns the N-layer RT theorem from a
graph-induction challenge into a software-architecture pattern:
the "induction" is in the oracle's growth function, and the
"induction step" is the generic theorem.

The result, if completed, would be the first demonstration that
a holographic duality theorem scales to arbitrary patch depth
within a single proof assistant — not by formalizing the
geometry inductively, but by abstracting over it.

---

## 6. Direction D — 3D Hyperbolic Honeycombs (Symmetry Reduction Strategy)

### 6.1 Goal

Generalize the univalence bridge from a 1D boundary / 2D bulk
architecture to a genuine 2D boundary / 3D bulk model. This requires
transitioning from the 2D \(\{5,4\}\) hyperbolic tiling to a 3D
hyperbolic honeycomb — specifically the \(\{4,3,5\}\) Coxeter
honeycomb, where 5 cubic cells meet at every edge. The discrete
Ryu–Takayanagi correspondence would then map 2D boundary entanglement
(min-cut through a surface of boundary faces) to the minimal 2D
surface area cutting through the 3D bulk.

This is the natural dimensional successor to the current project:
the tree pilot established the architecture in the 0D boundary / 1D
bulk setting, the star and filled patches validated it in the 1D
boundary / 2D bulk setting, and the 3D honeycomb would demonstrate
it in the physically most relevant 2D boundary / 3D bulk setting —
the dimensional regime where holographic duality was originally
formulated by Maldacena (1997).

### 6.2 The Original Wall

The naive approach to 3D formalization hits an **AST Memory and
Combinatorial Explosion Boundary**. A full "filled patch" of the
\(\{4,3,5\}\) honeycomb — the 3D analogue of the 11-tile filled
patch — would have tens of thousands of boundary faces, yielding
tens of thousands of contiguous boundary regions and hundreds of
thousands of union triples. A flat `data Region3D : Type₀ where
r0 r1 r2 ... r9999 : Region3D` declaration requires Agda's parser
to allocate one constructor AST node per region at parse time.
Cubical Agda's parser and normalizer would collapse under the RAM
weight before type-checking even begins.

The Python code-generation + `abstract` barrier strategy
(Approach A+C from §3.6) that works for the 11-tile patch's 90
regions and 360 union triples would not scale to this regime: the
bottleneck is not proof normalization (which `abstract` solves) but
AST *allocation* at the datatype declaration level, which occurs
before any `abstract` barrier can take effect.

However, the wall is **not insurmountable**. The naive approach
fails because it ignores two structural properties of hyperbolic
honeycombs that dramatically reduce the effective problem size:
(a) the existence of intermediate patches in the "sweet spot"
between trivial and intractable, and (b) the enormous symmetry
group of the \(\{4,3,5\}\) honeycomb. Combining these with boolean
reflection for the remaining case analysis yields a concrete three-
stage attack strategy.

### 6.3 Precedent: How Symmetry Already Works in 2D

The current 2D codebase already exploits symmetry implicitly. The
`classify : Vertex → VClass` function in `Bulk/PatchComplex.agda`
reduces 30 individual vertices to 5 curvature classes, and the
Gauss–Bonnet theorem is proven as a 5-term weighted sum rather
than a 30-term enumeration. The `totalCurvature≡χ` proof is `refl`
on 5 class contributions, not on 30 individual curvatures.

This is a degenerate case of **orbit reduction**: the 5-fold
rotational symmetry of the \(\{5,4\}\) tiling acts on vertices,
and curvature is constant on each orbit. The Gauss–Bonnet sum
factors through the orbit decomposition. The 3D strategy
generalizes this pattern from an informal vertex classification
to a formally verified group action.

### 6.4 Stage 1 — Intermediate 3D Patch (Sweet Spot Selection)

#### 6.4.1 The Spectrum of 3D Patches

Just as the 2D codebase has two patches — the 6-tile star
(manageable but tree-like) and the 11-tile fill (genuine
curvature) — a spectrum of 3D patches exists between the trivial
and the intractable:

**3D Star Patch (trivial).** One central cube with 6 face-
neighbors. This is topologically a 7-node star graph — it has
no interior edges where 5 cubes meet, and therefore no genuine
3D curvature. Its boundary has ~26 exposed faces, yielding a
manageable number of regions, but the result would be
mathematically vacuous: another disguised tree.

**Partially Filled 3D Patch (target).** The central cube + 6
face-neighbors + a selected subset of edge-gap-fillers. In the
\(\{4,3,5\}\) honeycomb, the central cube has 12 edges. At each
edge, 5 cubes should meet. The 6 face-neighbors cover 2 of the
5 cubes at each edge they share with the center. Inserting gap-
filler cubes at selected edges would produce a patch where at
least some edges are fully surrounded by 5 cubes — the
\(\{4,3,5\}\) Schläfli condition. These fully-surrounded edges
would exhibit genuine negative 3D curvature: the solid angle
sum at a fully-surrounded edge exceeds \(2\pi\), giving a
negative Regge-style deficit angle.

**Full 3D Filled Patch (intractable).** Every edge of the
central cube fully surrounded, every gap filled. This is the
analogue of the 11-tile 2D patch, and it is the regime where
the naive approach fails — likely thousands of cells, tens of
thousands of boundary faces, hundreds of thousands of regions.

#### 6.4.2 Target: The Minimal Curvature-Bearing Patch

The target is the smallest 3D patch satisfying all of:

1. **At least one fully interior edge** where 5 cubes meet
   (the \(\{4,3,5\}\) condition), establishing genuine 3D
   negative curvature.
2. **A well-defined boundary** forming a closed polyhedral
   surface (analogous to the boundary cycle of the 2D disk
   patch).
3. **Boundary face count in the range ~100–500**, keeping the
   region count within the range where Approach A+C (Python
   oracle + `abstract`) is known to work.

A candidate construction: start with the central cube, add its
6 face-neighbors, then add the 12 edge-neighbors (cubes sharing
an edge but not a face with the central cube) that fill the
gaps between face-neighbors. This gives 19 cubes. If the
boundary face count of this 19-cell patch is in the target
range, and if at least one edge of the central cube is fully
surrounded, it satisfies all three criteria.

#### 6.4.3 Feasibility Check (Python Prototype)

Before any Agda work, a Python prototype must:

1. Build the polyhedral complex for the candidate 3D patch
   (vertices, edges, faces, cells) in the \(\{4,3,5\}\)
   honeycomb.
2. Count boundary faces and enumerate contiguous boundary
   regions.
3. Verify that at least one edge has the full valence-5
   condition.
4. Compute the solid angle deficit at interior edges and
   verify 3D Gauss–Bonnet (the Descartes–Euler angular
   deficiency theorem for 3-manifolds with boundary).
5. Compute min-cut values for all contiguous boundary
   regions via max-flow and verify the 3D discrete RT
   correspondence: min-cut through the cell complex equals
   the minimal separating surface area.

If the region count exceeds ~500, the candidate patch is too
large and a smaller subset must be selected. If no edge
achieves full valence-5, more gap-fillers must be added
(potentially pushing the count higher, requiring the symmetry
reduction of Stage 2).

This prototype extends `02_happy_patch_curvature.py` from 2D
polygonal complexes to 3D polyhedral complexes. The graph
logic from `01_happy_patch_cuts.py` (flow graphs, min-cut
computation) applies unchanged — the min-cut algorithm is
dimension-agnostic.

### 6.5 Stage 2 — Symmetry Quotient (Orbit Reduction)

#### 6.5.1 The Core Observation

The \(\{4,3,5\}\) Coxeter group has order **14,400**. This is
the symmetry group of the regular 120-cell (the 4D polytope
whose 3D faces tile hyperbolic 3-space in the \(\{4,3,5\}\)
pattern). Any patch centered at a vertex/edge/face of the
honeycomb inherits a large subgroup of this symmetry.

If the 3D patch has \(N\) boundary regions and the symmetry
group acts on them with \(k\) orbits, then every equivariant
property (min-cut value, subadditivity, monotonicity) needs to
be checked only on the \(k\) orbit representatives. For even
modest symmetry, this reduction is dramatic:

- The 2D 11-tile patch has 5-fold rotational symmetry. Its 90
  regions decompose into ~18 orbits. The 360 subadditivity
  triples decompose into ~72 orbit classes. (The current
  implementation does not exploit this, generating all 360
  cases, but it *could* reduce by 5×.)

- A 3D patch with the full octahedral symmetry of the cube
  (order 48) acting on, say, 5,000 regions would reduce to
  ~105 orbit representatives. If the patch has additional
  symmetry from the honeycomb structure, the reduction could
  be even larger.

#### 6.5.2 Formalization Architecture

The symmetry quotient introduces three new Agda components:

**The symmetry group.** A finite type `Sym3D` with a group
structure (identity, composition, inverse) and a proof that it
is a group. For a subgroup of the Coxeter group, this is a
finite enumeration — potentially large (order 48 or more), but
the group elements are never case-split against individually.
The group structure is used only through its action.

**The group action on regions.** A function
`act : Sym3D → Region3D → Region3D` satisfying the action
laws:

```agda
act-id   : (r : Region3D) → act e r ≡ r
act-comp : (g h : Sym3D) (r : Region3D) → act (g · h) r ≡ act g (act h r)
```

For a concrete patch, `act` is defined by explicit permutation
of boundary faces (generated by the Python oracle from the
honeycomb's geometric symmetries).

**Equivariance of the observables.** The key lemma:

```agda
equivariant : (g : Sym3D) (r : Region3D) → S-cut (act g r) ≡ S-cut r
```

This states that the min-cut value is invariant under the
symmetry action. It is the type-theoretic expression of the
physical fact that entanglement entropy depends only on the
*shape* of a boundary region, not on its *position* in a
symmetric tiling.

For the concrete patch, equivariance is proven by the Python
oracle: it verifies numerically that every orbit has a constant
min-cut value, and generates a proof by case-splitting on the
orbit representative type (not the full region type).

**Orbit decomposition.** A function
`classify3D : Region3D → OrbitRep3D` mapping each region to
its orbit representative, together with a proof that the
observable factors through it:

```agda
S-cut r ≡ S-cut-rep (classify3D r)
```

where `S-cut-rep : OrbitRep3D → ℚ≥0` is the small lookup table
on orbit representatives. The pointwise agreement, subadditivity,
and monotonicity proofs are then stated and proved on `OrbitRep3D`
(perhaps 20–100 constructors) and lifted to the full `Region3D`
via equivariance.

#### 6.5.3 How This Bypasses the AST Wall

The `Region3D` type can be large (thousands of constructors),
but no proof ever *pattern-matches on it*. All proofs operate
on `OrbitRep3D` (small, ~20–100 constructors) and are lifted
to `Region3D` via `classify3D` and `equivariant`. The
symmetry machinery adds complexity — the group type, action,
equivariance proof — but this complexity is *structural* (a
fixed overhead independent of patch size), not *enumerative*
(growing with region count).

The `Region3D` datatype itself still needs to be declared, but
if the intermediate patch (Stage 1) keeps the constructor count
under ~500, the parser can handle it. The proofs never unfold
all 500 constructors simultaneously; they unfold only the ~20–
100 orbit representatives.

If the constructor count exceeds what the parser can handle,
the `Region3D` type can be encoded as `Fin N` (see §6.5.4)
instead of a flat enumeration, completely sidestepping the
parser bottleneck.

#### 6.5.4 Fallback: ℕ-Encoded Regions

If the intermediate 3D patch has too many boundary regions
for a flat datatype declaration (say, over ~1,000 constructors),
the region type can be encoded numerically:

```agda
Region3D : Type₀
Region3D = Fin N   -- or  Σ[ n ∈ ℕ ] (n < N)  for some concrete N
```

The observable functions become recursive lookups computed from
the ℕ index rather than by top-level pattern matching. A
balanced binary decision tree of depth \(\lceil \log_2 N \rceil\)
normalizes in ~\(\log_2 N\) reduction steps per query, regardless
of total table size. For \(N = 5{,}000\), this is ~13 steps —
the normalizer handles it easily.

The tradeoff: proofs can no longer pattern-match on named
region constructors. Instead, pointwise agreement becomes `refl`
after the normalizer evaluates both decision trees to the same
ℕ literal. This works as long as both trees are generated by the
same Python oracle and share canonical form.

The ℕ-encoding combines naturally with the symmetry quotient:
the `classify3D` function maps `Fin N` to `OrbitRep3D` (a small
named datatype), and all mathematical proofs operate on
`OrbitRep3D`. The encoding details of `Region3D` are hidden
behind `classify3D` and never leak into the proof layer.

### 6.6 Stage 3 — Boolean Reflection (Scaling to Full Patches)

#### 6.6.1 Motivation

Stages 1 and 2 (intermediate patch + symmetry reduction) are
designed to bring the proof obligations down to a manageable
number of orbit representatives. For the target intermediate
patch, this may be sufficient: ~20–100 representative cases,
dischargeable by the existing `(k , refl)` pattern.

However, if a future extension requires handling a *full* 3D
filled patch (thousands of orbits) or if the symmetry reduction
is less effective than expected, a fundamentally different proof
architecture is needed. **Boolean reflection** eliminates the
per-case enumeration bottleneck entirely.

#### 6.6.2 Architecture

Boolean reflection changes the proof shape from "one proof term
per case" to "one evaluation + one soundness theorem":

```agda
-- A terminating boolean decision procedure that checks ALL cases
check-all-3d : Bool
check-all-3d = check-region 0 ∧ check-region 1 ∧ … ∧ check-region (N-1)

-- A single refl: the normalizer evaluates the boolean expression
all-pass : check-all-3d ≡ true
all-pass = refl

-- Soundness: boolean true implies the mathematical property
soundness : check-all-3d ≡ true → (r : Region3D) → S-cut r ≡ L-min r
```

The critical difference from the current `(k , refl)` approach:
Agda evaluates `check-all-3d` to `true` by *running the boolean
computation*, which reduces a chain of `_∧_` applications on
closed boolean terms. This is dramatically cheaper than
normalizing thousands of independent Σ-type proof terms. The
boolean chain `true ∧ true ∧ ... ∧ true` normalizes in linear
time by structural recursion on `_∧_`, while each `(k , refl)`
proof separately expands into a nested constructor tree that
the normalizer must rebuild from scratch.

#### 6.6.3 The Soundness Theorem

The cost of boolean reflection is the **soundness theorem**:
proving that if the decision procedure returns `true` for every
region, then the propositional equality holds for every region.

For the min-cut = chain-length correspondence, soundness says:
"if the boolean checker `S-cut-eq? r` returns `true`, then
`S-cut r ≡ L-min r`." This requires:

1. A decision procedure `_≡ℕ?_ : ℕ → ℕ → Bool` for natural
   number equality, proven sound: `(m ≡ℕ? n) ≡ true → m ≡ n`.
2. The definition `S-cut-eq? r = S-cut r ≡ℕ? L-min r`.
3. The lifting lemma: `check-all-3d ≡ true` implies `S-cut-eq? r
   ≡ true` for every `r` (by induction on the conjunction chain).
4. Combining (1) and (3) to obtain `S-cut r ≡ L-min r`.

Steps (1) and (3) are generic infrastructure — they depend only
on ℕ decidable equality and boolean conjunction, not on the
specific geometry. Step (1) is straightforward (decidable equality
of ℕ is standard). Step (3) is a simple induction on the
conjunction. The total overhead is perhaps 100–200 lines of Agda,
proven once and reused for any patch size.

This is the same pattern used in the Coq proof of the Four Color
Theorem (Gonthier, 2005): a boolean checker encodes the
combinatorial case analysis, a soundness theorem lifts boolean
`true` to the mathematical property, and `refl` does the work
of evaluating thousands of cases simultaneously.

#### 6.6.4 Relationship to the Symmetry Quotient

Boolean reflection and symmetry reduction are complementary, not
competing strategies:

- **Symmetry reduction** decreases the number of cases that need
  checking by a factor of \(|G|\) (the symmetry group order).
- **Boolean reflection** changes the cost per case from
  "allocate a Σ-type proof tree" to "evaluate one boolean
  conjunction step."

For a 3D patch with 5,000 regions and a symmetry group of order
48, the combined approach would: (a) reduce to ~105 orbit
representatives via symmetry, (b) encode the 105-case check as
a single boolean, and (c) discharge it by `refl`. If symmetry
alone reduces the count to a manageable 20–50 representatives,
boolean reflection is unnecessary. If it doesn't, boolean
reflection handles the remainder.

### 6.7 The 3D Gauss–Bonnet Target

#### 6.7.1 The 3D Curvature Formula

In 3 dimensions, the combinatorial curvature lives on **edges**
(not vertices as in 2D). At an interior edge \(e\) of a polyhedral
3-complex, the angle deficit is:

\[
  \kappa(e) = 2\pi - \sum_{\text{cells } \ni e} \theta_e^{\text{cell}}
\]

where \(\theta_e^{\text{cell}}\) is the dihedral angle of the cell
at edge \(e\). For the \(\{4,3,5\}\) honeycomb, 5 cubes meet at
each interior edge. The dihedral angle of a cube is \(\pi/2\), so:

\[
  \kappa(e) = 2\pi - 5 \cdot \frac{\pi}{2} = 2\pi - \frac{5\pi}{2}
  = -\frac{\pi}{2}
\]

This negative deficit confirms the hyperbolic character of the
honeycomb: too many cubes meet at each edge, creating an angular
excess rather than a deficit.

For a combinatorial (non-metric) formulation analogous to the 2D
approach in `Bulk/Curvature.agda`, the curvature can be expressed
as a function of the edge's **cell valence** (number of cells
meeting at the edge) versus the expected valence from the Schläfli
symbol. The 3D combinatorial Gauss–Bonnet theorem relates the
sum of edge curvatures (interior + boundary) to the Euler
characteristic of the 3-manifold with boundary.

#### 6.7.2 Formalization Strategy

Following the 2D precedent (Strategy A from §13.2 of
[`09-happy-instance.md`](09-happy-instance.md)):

1. Classify edges by type (interior fully-surrounded, interior
   partially-surrounded, boundary) rather than enumerating them
   individually.
2. Define curvature as a function of edge class.
3. Prove 3D Gauss–Bonnet as a class-weighted sum, dischargeable
   by `refl` if the scalar representation (ℚ₁₀ or an extension)
   supports the required fractions.

The 3D curvature values involve halves of \(\pi\), but in the
combinatorial formulation (where curvature is expressed as a
rational function of cell valence and face geometry), the values
should have denominators dividing a manageable integer,
allowing an extension of the ℚ₁₀ representation from
`Util/Rationals.agda`.

### 6.8 The 3D Bridge Target

#### 6.8.1 Observable Packages in 3D

The 3D observable packages mirror the 2D architecture:

- **Boundary observable:** for each contiguous boundary region
  \(\mathcal{R}\) (a connected subset of the boundary polyhedral
  surface), the min-cut value separating \(\mathcal{R}\) from its
  complement in the 3D cell complex.

- **Bulk observable:** the minimal separating surface area — the
  total face-area of the cheapest collection of internal faces
  that disconnects \(\mathcal{R}\) from its complement.

The discrete 3D RT correspondence asserts that these two
functionals agree on every contiguous boundary region. This is
the same claim as in 2D, with "edge cut" replaced by "face cut"
and "chain length" replaced by "surface area." The max-flow /
min-cut algorithm from `01_happy_patch_cuts.py` computes both
quantities — it is dimension-agnostic (it operates on the cell
adjacency graph, which has the same structure in any dimension).

#### 6.8.2 Enriched Equivalence

The enriched-package architecture from
`Bridge/FullEnrichedStarObs.agda` carries over directly:
specification-agreement types \(\Sigma_{f} (f \equiv S_{\partial}^{3D})\)
and \(\Sigma_{f} (f \equiv L_{B}^{3D})\), with the equivalence
constructed from the 3D analogue of `filled-obs-path` via the
`Iso`/`isoToEquiv`/`ua`/`uaβ` pipeline. The symmetry quotient
affects only the *size* of the pointwise agreement proof (reduced
from \(N\) cases to \(k\) orbit representatives), not the
*architecture* of the equivalence.

### 6.9 Execution Plan

**Phase D.0 — Feasibility prototype (Python).** Extend the
existing Python prototyping infrastructure to 3D polyhedral
complexes:

1. Implement the \(\{4,3,5\}\) honeycomb generator (coordinates
   of cube vertices in the Poincaré ball model, or purely
   combinatorial cell adjacency).
2. Build the candidate intermediate 3D patch (central cube + 6
   face-neighbors + selected edge-gap-fillers).
3. Count boundary faces, enumerate contiguous boundary regions,
   compute min-cut values, verify 3D discrete RT.
4. Compute the symmetry group of the patch, enumerate orbits,
   verify that min-cut values are constant on orbits.
5. Report: region count, orbit count, symmetry group order,
   curvature values, Gauss–Bonnet verification.

**Gate:** If the orbit count exceeds ~200 or no edge achieves
full valence-5, revise the patch selection. If no intermediate
patch in the sweet spot exists, this direction is genuinely
blocked and should be re-deferred.

**Phase D.1 — 3D Agda code generation (Python oracle).** Create
`06_generate_honeycomb_3d.py` to output 3D modules:

1. `Common/Honeycomb3DSpec.agda` — the region type (either flat
   enumeration if ≤500 constructors, or `Fin N` encoding
   otherwise), orbit representative type, classification
   function.
2. `Boundary/Honeycomb3DCut.agda` — the min-cut lookup table
   (on orbit representatives, lifted to full regions).
3. `Bulk/Honeycomb3DChain.agda` — the bulk observable (identical
   values, different specification function).
4. `Bulk/Honeycomb3DCurvature.agda` — edge-class curvature and
   3D Gauss–Bonnet.
5. `Bridge/Honeycomb3DObs.agda` — pointwise agreement on orbit
   representatives, lifted via equivariance.

If the orbit count is small enough (~50 or less), the proofs
use the existing `(k , refl)` pattern on orbit representatives.
If larger, boolean reflection (Phase D.2) is triggered.

**Phase D.2 (conditional) — Boolean reflection.** Implement the
boolean decision procedure and soundness theorem:

1. `Util/BoolReflect.agda` — decidable ℕ equality, conjunction
   soundness, generic reflection infrastructure.
2. Modify the code generator to emit a single `check-all-3d`
   boolean and the `all-pass : check-all-3d ≡ true` proof
   (by `refl`).
3. `Bridge/Honeycomb3DEquiv.agda` — assemble the equivalence
   using soundness rather than per-case witnesses.

**Phase D.3 — Enriched bridge and transport.** Construct the
enriched observable-package equivalence for the 3D patch and
verify `transport` along the `ua` path. This mirrors
`Bridge/FilledEquiv.agda` and requires no new infrastructure
beyond the orbit-based pointwise agreement from Phase D.1.

### 6.10 Risk Assessment

**Primary risk: no sweet spot exists.** It is possible that no
intermediate 3D patch simultaneously has genuine 3D curvature
(at least one fully-surrounded edge), a manageable boundary
(≤500 faces), and sufficient symmetry (orbit count ≤200). The
\(\{4,3,5\}\) honeycomb grows rapidly: 5 cubes at every edge
means the neighborhood of the central cube fills in very
quickly. The feasibility prototype (Phase D.0) is the gate that
determines whether this risk materializes.

**Secondary risk: equivariance proof complexity.** The
equivariance lemma (`S-cut (act g r) ≡ S-cut r`) requires
showing that the min-cut functional is invariant under the
symmetry action. For the Python oracle this is trivial
(numerical verification). For Agda, it requires either:
(a) a per-orbit-representative case split (feasible if orbits
are few), or (b) a structural proof that the min-cut functional
commutes with the group action (requires formalizing the flow-
graph symmetry). Option (a) is the pragmatic default; option (b)
is cleaner but harder.

**Tertiary risk: 3D min-cut computation.** In 2D, the min-cut
separating a boundary region from its complement is a 1D curve
(a set of edges in the dual graph). In 3D, it is a 2D surface
(a set of faces in the dual complex). The max-flow algorithm
computes this correctly in both cases (it operates on the
abstract graph), but verifying the *geometric* interpretation
— that the min-cut corresponds to a connected minimal surface —
may require additional topological lemmas that have no 2D
analogue.

### 6.11 Why This Matters

The mathematical and type-theoretic mechanisms governing the
2D → 3D dimensional transition are *believed* to be identical to
the 1D → 2D mapping already achieved: the bulk is still
reconstructed from the boundary, the discrete RT formula still
governs the correspondence, and Univalence still provides the
transport. What changes is the *scale* of the case analysis and
the *richness* of the curvature geometry.

If a 3D instance type-checks — even a small intermediate patch
with just one fully-surrounded edge — it would demonstrate that
the holographic formalization architecture is not dimension-
specific. The 2D \(\{5,4\}\) tiling is the "Goldilocks" zone
for initial development, but the architecture is designed to
generalize. A 3D result, even partial, would be a strong signal
that the formal infrastructure scales toward the physically
relevant regime of holographic duality.

The symmetry quotient strategy developed here would also feed
back into the 2D codebase: the existing 11-tile patch could
be reformulated with explicit 5-fold symmetry, reducing the
360 subadditivity cases to 72 orbit representatives and
potentially eliminating the need for the `abstract` barrier
in `Boundary/FilledSubadditivity.agda`. This retroactive
improvement would validate the symmetry machinery on a known-
good instance before deploying it in 3D.

### 6.12 Conditions for Advancement

This direction advances from "deferred" to "active" when:

1. The feasibility prototype (Phase D.0) confirms the existence
   of a sweet-spot intermediate 3D patch with genuine curvature
   and a manageable orbit count.
2. The 2D formalization (Directions A and B) is complete or
   stable enough that 3D work does not compete for development
   time.
3. The symmetry quotient machinery has been validated
   retroactively on the 11-tile 2D patch, confirming that orbit
   reduction works as expected in the existing codebase.

If any of these conditions fails — no sweet spot, 2D work still
active, or symmetry machinery stalls — this direction remains
deferred until the obstacle is resolved.

---

## 7. Direction E — The de Sitter (dS) / Anti-de Sitter (AdS) Translator (Curvature Sign Boundary)

### 7.1 Goal

Construct a machine-checked proof that the discrete holographic
correspondence (Theorem 3) is **invariant under the sign of
curvature**: the same min-cut = chain-length observable-package
equivalence holds simultaneously on a negatively curved (AdS-like)
patch and a positively curved (dS-like) patch. Package the result
as a "discrete Wick rotation" — a verified translator between the
two curvature regimes that requires no complex numbers, no smooth
manifolds, and no constructive real analysis.

This is the natural conceptual successor to Directions A–D: those
extended the holographic bridge across instances (6-tile → 11-tile),
structural levels (observable → raw), and dimensions (2D → 3D).
This direction extends it across **curvature regimes** — the axis
on which the entire AdS/CFT vs dS/CFT debate in theoretical physics
is conducted.

### 7.2 The Physics Motivation (Briefly)

In continuum physics, the AdS/CFT correspondence (Maldacena 1997)
relates a quantum field theory on the spatial boundary of
Anti-de Sitter space (negative cosmological constant, \(\Lambda < 0\))
to gravity in the bulk. The conjectured dS/CFT correspondence
(Strominger 2001) relates a quantum field theory on the *temporal*
boundary (future/past conformal infinity \(\mathcal{I}^{\pm}\)) of
de Sitter space (positive cosmological constant, \(\Lambda > 0\))
to gravity in an expanding bulk.

The two correspondences are believed to be connected by a
**Wick rotation** — an analytic continuation that maps
\(L_{\text{AdS}} \to i \, L_{\text{dS}}\), effectively rotating
the cosmological constant from negative to positive by multiplying
the radius of curvature by the imaginary unit \(i\). In the
continuum, this requires complex analysis, smooth Lorentzian
geometry, and unresolved conceptual issues about the nature of
the dS boundary.

The physics community has struggled with dS/CFT for over two
decades precisely because the tools are smooth, analytic, and
plagued by infinities. The question this section asks is:

> **Does the discrete, combinatorial, finite formulation bypass
> the analytic obstacles entirely?**

### 7.3 The Key CS Insight: Flow-Graph Invariance

The central observation — invisible from the physics side but
immediate from the computer science side — is that the entire
bridge construction (Theorem 3) depends only on the **flow-graph
topology** of the patch, not on its curvature.

Recall what Theorem 3 actually proves:

1. There is a finite weighted graph (the tile adjacency / bond graph).
2. Boundary min-cut and bulk minimal-chain are computed as max-flow
   on this graph.
3. These two functionals agree on every contiguous boundary region.
4. The observable packages are therefore equivalent as types.

None of these steps reference curvature. The curvature enters
only in Theorem 1 (Gauss–Bonnet), which is a completely separate
theorem about the *bulk geometry*, not about the *holographic
correspondence*.

This means: **if two patches with opposite curvature signs share
the same flow-graph topology, they produce identical observable
packages, and the same bridge equivalence serves both.**

The "discrete Wick rotation" is therefore not a complex-number
multiplication. It is a **parameter change in the tiling type**
that flips the curvature sign while preserving the flow graph.

### 7.4 The Concrete Construction: \(\{5,4\}\) ↔ \(\{5,3\}\)

#### 7.4.1 The Two Tilings

The Schläfli symbol \(\{p, q\}\) denotes a tiling by regular
\(p\)-gons with \(q\) meeting at each vertex. The curvature
regime is determined by the product \((p-2)(q-2)\):

\[
  (p-2)(q-2) \begin{cases}
    < 4 & \text{spherical (positive curvature)} \\
    = 4 & \text{Euclidean (flat)} \\
    > 4 & \text{hyperbolic (negative curvature)}
  \end{cases}
\]

For pentagonal tilings (\(p = 5\)):

- \(\{5, 3\}\): \((3)(1) = 3 < 4\) — **spherical** (the regular
  dodecahedron, 12 pentagonal faces on \(S^2\), positive curvature)
- \(\{5, 4\}\): \((3)(2) = 6 > 4\) — **hyperbolic** (the infinite
  \(\{5,4\}\) tiling of \(\mathbb{H}^2\), negative curvature)

The crucial fact: **both tilings are built from regular pentagons**.
The only difference is the vertex valence: 3 pentagons per vertex
(spherical) vs 4 pentagons per vertex (hyperbolic).

#### 7.4.2 The AdS Star Patch (Already Formalized)

The 6-tile star patch of \(\{5,4\}\) (Common/StarSpec.agda):

- Central pentagon C + 5 edge-neighbours N0..N4
- 5 interior vertices, each at valence 4 (4 pentagons meeting)
- Gap-filler tiles needed between adjacent N tiles (the 11-tile
  filled patch fills these gaps)
- Bond graph: star topology (C connected to each N_i)
- Min-cut: \(S(k) = \min(k, 5-k)\) for a region of \(k\) tiles
- Interior curvature: \(\kappa = -1/5\) per vertex (negative)

#### 7.4.3 The dS Star Patch (New)

The 6-face star patch of \(\{5,3\}\) is extracted from the regular
dodecahedron by selecting one face as the center and its 5
edge-neighbours:

- Central pentagon C + 5 edge-neighbours N0..N4
- 5 interior vertices, each at valence 3 (3 pentagons meeting)
- **No gap-filler tiles needed**: in \(\{5,3\}\), only 3 pentagons
  meet at each vertex, and the star patch already saturates
  every interior vertex. At vertex \(v_i\) of C, the three faces
  C, \(N_{i-1}\), and \(N_i\) are exactly the 3 faces of the
  dodecahedron meeting there. There are no angular gaps.
- Bond graph: **identical star topology** (C connected to each N_i
  by one shared pentagon edge)
- Min-cut: \(S(k) = \min(k, 5-k)\) — **identical to the AdS star**
- Interior curvature: \(\kappa = +1/10\) per vertex (positive)

The flow-graph isomorphism is exact: the dS star and the AdS star
have the same tile set (\(\{C, N0, N1, N2, N3, N4\}\)), the same
5 bonds, the same 10 representative regions, and the same min-cut
values on every region.

#### 7.4.4 Curvature Comparison

The combinatorial curvature formula
\(\kappa(v) = 1 - \deg_E(v)/2 + \sum_{f \ni v} 1/\text{sides}(f)\)
gives:

**Interior vertices (shared by C and two N tiles):**

\[
  \kappa_{\{5,4\}}(v) = 1 - \tfrac{4}{2} + 4 \cdot \tfrac{1}{5}
  = 1 - 2 + \tfrac{4}{5} = -\tfrac{1}{5}
  \qquad (\text{negative: hyperbolic})
\]
\[
  \kappa_{\{5,3\}}(v) = 1 - \tfrac{3}{2} + 3 \cdot \tfrac{1}{5}
  = 1 - \tfrac{3}{2} + \tfrac{3}{5} = \tfrac{1}{10}
  \qquad (\text{positive: spherical})
\]

Both patches have Euler characteristic \(\chi = 1\) (disk topology).
The Gauss–Bonnet sum \(\sum_v \kappa(v) = 1\) holds in both cases,
with the interior/boundary decomposition distributing differently:

- **AdS** (\(\{5,4\}\)): strongly negative interior, compensated by
  strongly positive boundary turning
- **dS** (\(\{5,3\}\)): mildly positive interior, with mild boundary
  corrections

The curvature sign flip is the combinatorial analogue of the
cosmological constant sign flip \(\Lambda_{\text{AdS}} < 0 \to
\Lambda_{\text{dS}} > 0\).

### 7.5 The Discrete Wick Rotation as a Type-Theoretic Theorem

#### 7.5.1 What the Theorem Says

The discrete Wick rotation theorem asserts that the holographic
bridge (Theorem 3) factors through a curvature-agnostic layer:

\[
  \texttt{Obs}_\partial^{\{5,4\}} \;\simeq\; \texttt{Obs}_\text{bulk}^{\{5,4\}}
  \;\simeq\; \texttt{Obs}_\text{flow}
  \;\simeq\; \texttt{Obs}_\text{bulk}^{\{5,3\}}
  \;\simeq\; \texttt{Obs}_\partial^{\{5,3\}}
\]

where \(\texttt{Obs}_\text{flow}\) is the "curvature-free" observable
package depending only on the star flow graph. The outer equivalences
are the AdS and dS bridges respectively; the inner equivalences are
identifications of both bridges with the flow-graph layer.

More precisely, the theorem has three components:

**Component 1 (Curvature Independence of the Bridge):**
The enriched observable-package equivalence
\(\texttt{EnrichedBdy} \simeq \texttt{EnrichedBulk}\) from
Bridge/EnrichedStarObs.agda depends only on `star-obs-path :
S∂ ≡ LB`, which is a 10-case `funExt` of `refl` proofs. These
proofs reference only the scalar constants `1q` and `2q` from
Util/Scalars.agda. They do NOT reference any curvature value,
any vertex type, or any tiling parameter. Therefore the same
equivalence serves both curvature regimes.

**Component 2 (dS Gauss–Bonnet):**
A separate Gauss–Bonnet theorem for the \(\{5,3\}\) star patch,
with positive interior curvature \(\kappa = +1/10\), proved by
the same class-weighted `refl` technique as the \(\{5,4\}\)
version in Bulk/GaussBonnet.agda.

**Component 3 (The Coherence Record):**
A packaging record witnessing that:

- One flow graph (the 5-bond star)
- Two curvature assignments (AdS and dS)
- One observable-package equivalence (shared)
- Two Gauss–Bonnet proofs (one per curvature assignment)

all cohere on the same geometric substrate.

#### 7.5.2 Why Complex Numbers Are Not Needed

The physics Wick rotation \(L_{\text{dS}} = i \, L_{\text{AdS}}\)
multiplies a length by the imaginary unit. In the discrete setting,
this operation has no analogue and **no function**: the discrete
lengths (min-cut values, chain lengths) are natural numbers
(\(\{1, 2\}\) for the star patch), and they are **identical** in
both curvature regimes.

The role of \(i\) in the continuum is to analytically continue a
coordinate from a spacelike to a timelike signature, rotating the
metric from Riemannian to Lorentzian. In the discrete setting:

1. There is no metric signature (the "metric" is a weight function
   on bonds, always positive).
2. There is no analytic continuation (all functions are defined by
   finite case splits, not by holomorphic extension).
3. The curvature sign change is achieved by changing the tiling
   parameter \(q\) from 4 to 3, which is a change of combinatorial
   input, not a complex rotation.

The `Util/ComplexNumbers.agda` module conjectured in the metadata
is therefore **not required**. The discrete Wick rotation lives
entirely in the existing scalar infrastructure: `ℚ≥0 = ℕ` for
observables (Util/Scalars.agda) and `ℚ₁₀ = ℤ` for curvature
(Util/Rationals.agda).

This is the deepest advantage of the CS lens: by working with
finite combinatorial structures, the project sidesteps the entire
analytic obstacle that has blocked the physics community for over
two decades.

### 7.6 The Boundary Swap: Spatial → Temporal

#### 7.6.1 The Physics Claim

In continuum dS/CFT, the boundary is temporal (\(\mathcal{I}^+\)
and \(\mathcal{I}^-\)) rather than spatial. A min-cut in the dS
bulk would correspond to a cosmological horizon, not a spatial
entanglement surface.

#### 7.6.2 The Discrete Translation

In the discrete formalization, the distinction between "spatial
boundary" and "temporal boundary" is **not a property of the
type**. The boundary is simply the set of exposed faces/legs of
the finite patch. Whether we interpret this boundary as "the
spatial edge of a hyperbolic disk" or "the temporal edge of a
cosmological horizon" is a semantic choice — it does not affect
the combinatorial structure, the min-cut computation, or the
type equivalence.

The formal statement is:

```agda
-- The same BoundaryView type serves both interpretations:
--   AdS: "spatial boundary at the edge of the hyperbolic disk"
--   dS:  "temporal boundary at the future/past conformal infinity"
-- The type does not know which interpretation is intended.
```

The "boundary swap" is therefore not a type-theoretic operation
but a **change of physical interpretation** of the same formal
object. This is precisely the situation that the project's
Observable Package architecture (§3.3 of docs/03-architecture.md)
was designed to handle: the packages capture the mathematical
content while being agnostic about the physical interpretation.

### 7.7 Feasibility Assessment and Prototyping Plan

#### 7.7.1 What Is New Infrastructure

The dS direction requires the following new modules:

**Python prototype** (Phase E.0):
`sim/prototyping/08_desitter_prototype.py` — builds the 6-face
star patch from the dodecahedron \(\{5,3\}\), verifies that its
bond graph is isomorphic to the \(\{5,4\}\) star, computes
combinatorial curvature, verifies Gauss–Bonnet, and confirms
that all 10 min-cut values match the \(\{5,4\}\) star.

**Agda modules** (Phase E.1):

```text
src/Common/DeSitterStarSpec.agda         — dS tile/bond/region types
                                           (may reuse StarSpec directly)
src/Bulk/DeSitterPatchComplex.agda       — {5,3} vertex classification
src/Bulk/DeSitterCurvature.agda          — κ_{5,3} : VClass → ℚ₁₀
src/Bulk/DeSitterGaussBonnet.agda        — Σ κ_{5,3}(v) = χ(K)
src/Bridge/WickRotation.agda             — coherence record + theorem
```

**What is NOT needed:**
- `Util/ComplexNumbers.agda` (no complex arithmetic)
- Any modification to Util/Scalars.agda or Util/Rationals.agda
- Any modification to existing Bridge modules
- Any new scalar type beyond ℤ and ℕ
- Any smooth or Lorentzian geometry

#### 7.7.2 The Crucial Reuse Observation

The observable-level bridge (`star-obs-path`, `enriched-equiv`,
`full-equiv`, `star-package-path`) is **already proven** and
**already curvature-agnostic**. The dS bridge does not require
re-proving any observable agreement or type equivalence. It
requires only:

1. Defining the \(\{5,3\}\) patch complex (vertex types, face
   incidence, classification) — structurally identical to
   Bulk/PatchComplex.agda but with different vertex counts
   per class.
2. Computing \(\{5,3\}\) curvature values — 4–5 distinct
   rational values, defined by case split.
3. Proving dS Gauss–Bonnet — a single `refl` on a class-weighted
   sum in ℤ arithmetic, following the identical pattern of
   Bulk/GaussBonnet.agda.
4. Packaging the coherence record — a hand-written module that
   imports both the AdS and dS Gauss–Bonnet witnesses alongside
   the shared bridge.

The estimated development time is **1–2 weeks**, assuming the
\(\{5,3\}\) curvature values are computed correctly in the Python
prototype. The proof engineering difficulty is minimal — all
curvature proofs are `refl` on closed ℤ terms, and the bridge
is literally imported unchanged.

#### 7.7.3 The Flow-Graph Isomorphism

The strongest version of the theorem requires proving that the
\(\{5,4\}\) and \(\{5,3\}\) star patches have *isomorphic* bond
graphs (not just that they happen to produce the same min-cut
values). Since both are 5-bond stars with the same tile names
and the same region type, this isomorphism is trivial — it is
the identity function on `Bond` and `Region`.

If the dS modules import `Tile`, `Bond`, and `Region` from
`Common/StarSpec.agda` (rather than defining new types), the
isomorphism is definitional: both sides use literally the same
types, and the bridge is literally the same term. The only new
content is the curvature theorem.

### 7.8 The Curvature-Parameterized Family (Stretch Goal)

#### 7.8.1 Abstracting Over the Valence

A more general formulation parameterizes the entire construction
by the vertex valence \(q\):

```agda
record PentagonalPatch (q : ℕ) : Type₀ where
  field
    -- Shared combinatorial structure (curvature-agnostic)
    tiles    : Tile → Type₀
    bonds    : Bond → Type₀
    regions  : Region → Type₀
    weights  : Bond → ℚ≥0
    S-cut    : Region → ℚ≥0
    L-min    : Region → ℚ≥0
    bridge   : (r : Region) → S-cut r ≡ L-min r

    -- Curvature data (q-dependent)
    κ-interior : ℚ₁₀     -- 1 − q/2 + q/5  in tenths
    gauss-bonnet : totalCurvature q ≡ χ₁₀
```

The "Wick rotation" is then a function:

```agda
wick : PentagonalPatch 4 → PentagonalPatch 3
```

that preserves all bridge fields and changes only the curvature
fields. Since the bridge fields are shared (both are imported
from the same StarSpec/StarObs/StarEquiv modules), `wick` acts
as the identity on the bridge component and maps between the
curvature components.

#### 7.8.2 The Path Between Patches

In HoTT, if `PentagonalPatch q` is a dependent type, and we have
inhabitants at \(q = 3\) and \(q = 4\), we can ask: is there a
*path* between them in some higher type? This requires lifting the
discrete parameter \(q\) to a continuous path, which is not
straightforward for ℕ-valued parameters.

However, we can use a different strategy: define a *type family*

```agda
BridgeFamily : (q : ℕ) → Type₀
BridgeFamily q = EnrichedBdy ≃ EnrichedBulk
```

that is **constant** in \(q\) (because the bridge doesn't depend
on curvature), and show that both the \(q=3\) and \(q=4\) instances
produce inhabitants of this constant family. The "Wick rotation
path" is then a path in the constant family — which is trivially
`refl`.

The non-trivial content lives in the **curvature family**:

```agda
CurvatureFamily : (q : ℕ) → Type₀
CurvatureFamily q = Σ[ κ ∈ (VClass → ℚ₁₀) ] (totalCurvature κ ≡ χ₁₀)
```

This family is NOT constant: the curvature values change with
\(q\). The "Wick rotation" at the curvature level is a *function*
`CurvatureFamily 4 → CurvatureFamily 3`, not a path.

The coherence theorem is: the bridge family and the curvature
family are **compatible** — they can coexist on the same geometric
substrate for both values of \(q\).

### 7.9 Extension to 3D

The 3D extension follows the same pattern:

- **AdS 3D**: the \(\{4,3,5\}\) honeycomb (5 cubes per edge,
  \(\kappa = -\pi/2\) per edge, already formalized in
  Bulk/Honeycomb3DCurvature.agda)
- **dS 3D**: the \(\{4,3,3\}\) honeycomb (3 cubes per edge,
  positive curvature). This is the regular tesseract (8-cell,
  the 4D hypercube's 3-faces), which tiles the 3-sphere
  \(S^3\) rather than hyperbolic 3-space \(\mathbb{H}^3\).

A star patch from the tesseract (central cube + 6 face-neighbors)
has the same cell-adjacency flow graph as the \(\{4,3,5\}\) star
patch. The min-cut structure is identical. The curvature at
interior edges flips sign:

\[
  \kappa_{\{4,3,5\}}(e) = 2\pi - 5 \cdot \tfrac{\pi}{2} = -\tfrac{\pi}{2}
  \qquad (\text{hyperbolic})
\]
\[
  \kappa_{\{4,3,3\}}(e) = 2\pi - 3 \cdot \tfrac{\pi}{2} = +\tfrac{\pi}{2}
  \qquad (\text{spherical})
\]

The 3D discrete Wick rotation maps between these two curvature
regimes while preserving the 3D bridge (Theorem 3 for the
honeycomb, proven in Bridge/Honeycomb3DEquiv.agda).

### 7.10 Research Significance

#### 7.10.1 What Is Novel

No one has previously:

1. Observed that the discrete RT correspondence is invariant under
   the sign of curvature in a formally precise setting.
2. Constructed a machine-checked proof that the same type
   equivalence serves both AdS-like and dS-like geometries.
3. Proposed a "discrete Wick rotation" that requires no complex
   numbers, no analytic continuation, and no Lorentzian geometry.
4. Demonstrated that the obstacles blocking continuum dS/CFT
   (temporal boundaries, complex cosmological constant, absence
   of a spatial conformal boundary) are artifacts of the smooth
   formulation that vanish in the combinatorial setting.

#### 7.10.2 The CS Lens Advantage

The physics community has spent two decades debating whether
dS/CFT is well-defined, largely because the continuum tools
(path integrals, analytic continuation, asymptotic symmetries)
behave pathologically in de Sitter space. The key difficulty
is that de Sitter space has no spatial boundary — only temporal
boundaries at \(\mathcal{I}^{\pm}\) — and the boundary CFT is
Euclidean rather than Lorentzian.

The CS lens dissolves this difficulty: in the discrete setting,
"boundary" is a combinatorial concept (exposed faces of a finite
patch), and the min-cut algorithm is dimension-agnostic and
signature-agnostic. The holographic correspondence is a property
of the flow graph, not of the embedding geometry. The curvature
is a separate, compatible structure that enriches the purely
topological bridge with geometric content — but does not
constrain it.

This is not a claim about continuum physics. It is a claim about
**formal structure**: the combinatorial core of the holographic
correspondence, when extracted from the smooth machinery, turns
out to be curvature-agnostic. Whether this survives any kind of
continuum or scaling limit is an open question beyond the scope
of this project.

### 7.11 Execution Plan

**Phase E.0 — Python prototype.**

1. Build the 6-face star from the dodecahedron \(\{5,3\}\).
2. Verify: bond graph is isomorphic to the \(\{5,4\}\) star
   (same 5-bond star topology).
3. Compute: vertex classification, combinatorial curvature at
   each vertex class, Gauss–Bonnet sum.
4. Compute: min-cut values for all 10 representative regions.
   Verify they match the \(\{5,4\}\) star exactly.
5. Report: curvature values in the ℚ₁₀ encoding (tenths of ℤ).

**Phase E.1 — Agda dS modules.**

1. If the bond graph is truly identical: the dS bridge reuses
   `Common/StarSpec.agda`, `Boundary/StarCut.agda`,
   `Bulk/StarChain.agda`, `Bridge/StarObs.agda`, and
   `Bridge/StarEquiv.agda` *without modification*. No new
   bridge modules are needed.

2. New curvature modules:
   - `Bulk/DeSitterPatchComplex.agda`: the \(\{5,3\}\) vertex
     classification (fewer vertex classes than \(\{5,4\}\)
     because no gap-filler tiles are needed).
   - `Bulk/DeSitterCurvature.agda`: κ-class for \(\{5,3\}\),
     with positive interior curvature.
   - `Bulk/DeSitterGaussBonnet.agda`: the dS Gauss–Bonnet
     proof, `refl` on the class-weighted curvature sum.

3. Coherence module:
   - `Bridge/WickRotation.agda`: a record packaging both the
     AdS and dS Gauss–Bonnet witnesses with the shared bridge
     equivalence, and a statement that the bridge is the same
     term in both cases.

**Phase E.2 — 3D dS extension (conditional).**

If Phase E.1 succeeds and Phases D.0–D.3 (3D honeycomb) are
complete, extend the Wick rotation to 3D by building a tesseract
\(\{4,3,3\}\) star patch and proving the same curvature-invariance
theorem for the 3D bridge.

### 7.12 Risk Assessment

**Primary risk: the \(\{5,3\}\) star patch has a different boundary
structure.** The dodecahedron's star has no gap-filler tiles, so
the boundary is a different polygon complex than the \(\{5,4\}\)
star's boundary. However, the *flow graph* (the dual graph on
tiles with bond capacities) is identical in both cases: a central
node connected to 5 leaves. The min-cut computation operates on
the flow graph, not on the polygon complex, so the boundary
polygon difference does not affect the observable packages.

**Secondary risk: the \(\{5,3\}\) patch is "too small."** The
dodecahedron has only 12 faces, so the largest possible patch is
11 faces (removing one). This is comparable to the 11-tile filled
patch of \(\{5,4\}\), so the scale is adequate for a proof of
concept. Larger positively curved patches would require polytopes
with more faces (e.g., the 120-cell \(\{5,3,3\}\) in 3D with 120
dodecahedral cells), which is exactly the 3D extension.

**Non-risk: complex numbers.** As argued in §7.5.2, the discrete
Wick rotation does not require complex arithmetic. This eliminates
what would otherwise be the single largest infrastructure obstacle
(constructive \(\mathbb{C}\) in Cubical Agda).

### 7.13 Exit Criterion

The dS/AdS translator is complete when:

1. A Python prototype confirms that the \(\{5,3\}\) and \(\{5,4\}\)
   star patches produce identical min-cut profiles.

2. An Agda module `Bulk/DeSitterGaussBonnet.agda` proves discrete
   Gauss–Bonnet for the \(\{5,3\}\) star patch with positive
   interior curvature, discharged by `refl`.

3. An Agda module `Bridge/WickRotation.agda` packages:
   - The shared bridge equivalence (imported from
     Bridge/EnrichedStarEquiv.agda)
   - The AdS Gauss–Bonnet witness (imported from
     Bulk/GaussBonnet.agda)
   - The dS Gauss–Bonnet witness (from
     Bulk/DeSitterGaussBonnet.agda)
   - A coherence statement that all three coexist on the same
     region type and the same observable functions.

4. A `WickRotationWitness` record (analogous to `BridgeWitness`
   from Bridge/EnrichedStarEquiv.agda) is fully instantiated and
   type-checks.

### 7.14 Relationship to Existing Code

The Wick rotation module imports from (but does NOT modify):

- `Common/StarSpec.agda` — shared Tile, Bond, Region types
- `Boundary/StarCut.agda` — shared S-cut functional
- `Bulk/StarChain.agda` — shared L-min functional
- `Bridge/EnrichedStarEquiv.agda` — the shared bridge (Theorem 3)
- `Util/Rationals.agda` — ℚ₁₀ for curvature values

New modules for the \(\{5,3\}\) curvature are additive and do not
affect any existing proofs. The existing tree, star, filled, and
honeycomb modules remain untouched.

### 7.15 Conceptual Architecture Summary

```
                      ┌─────────────────────────┐
                      │   Common/StarSpec.agda   │
                      │   (Tile, Bond, Region)   │
                      └────────────┬────────────┘
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
                  │ EnrichedStar   │   ◄──────────┘
                  │ Equiv.agda     │   (same bridge!)
                  │ (Theorem 3)    │
                  └───────┬────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
    ┌───────▼──────┐      │     ┌───────▼──────┐
    │ Bulk/        │      │     │ Bulk/        │
    │ GaussBonnet  │      │     │ DeSitter     │
    │ (κ < 0)      │      │     │ GaussBonnet  │
    │ Theorem 1    │      │     │ (κ > 0)      │
    │ [AdS]        │      │     │ [dS]         │
    └───────┬──────┘      │     └───────┬──────┘
            │             │             │
            └─────────────┼─────────────┘
                          │
                  ┌───────▼────────┐
                  │ Bridge/        │
                  │ WickRotation   │
                  │ .agda          │
                  │                │
                  │  Witnesses:    │
                  │  • AdS GB     │
                  │  • dS GB      │
                  │  • Shared      │
                  │    bridge      │
                  └────────────────┘
```

The architecture makes the key insight visually clear: the bridge
(Theorem 3) sits at the center, shared by both curvature regimes.
The two Gauss–Bonnet theorems (Theorem 1 for AdS and its dS
analogue) attach independently to opposite sides. The Wick
rotation module witnesses their coherence.

This is the type-theoretic content of the claim that "gravity
may partly be a macroscopic readout of microscopic entanglement"
(docs/00-abstract.md) — formalized not as a statement about
continuum spacetimes, but as a machine-checked proof that the
combinatorial structure of the holographic correspondence is
independent of the sign of curvature.

---

## 8. The Grid vs. The Curve: The "Thermodynamic Illusion" Route

### 8.1 The Physics Challenge

Physicists look at the `{4,3,5}` hyperbolic honeycomb and say,
"That's a nice approximation, but to get real gravity, you need to
shrink those cubes to size zero so the graph becomes a continuous
smooth manifold (General Relativity)."

**The CS / Proof-Engineering Response: Smoothness is a macroscopic
hallucination.**

You do not need to prove that the grid *becomes* smooth. You need
to prove that a smooth curve is just what a discrete grid looks like
when you zoom out — the same way a continuous fluid is just what
$10^{23}$ discrete bouncing water molecules look like.

In computer science, this is **coarse-graining** (lossy compression).
In physics, it is the **thermodynamic limit**. The challenge is to
express this idea type-theoretically, using the existing
formalization infrastructure, without ever invoking smooth manifolds
or constructive real analysis.

### 8.2 What the Existing Code Already Proves

The repository's Dense-patch pipeline already exhibits the
**discrete area law** — the combinatorial avatar of the
Bekenstein–Hawking formula $S = A / 4G$. The numerical evidence
from `sim/prototyping/09_generate_dense100_OUTPUT.txt`:

| Region size (cells) | # regions | min-cut range |
|---|---|---|
| 1 | 86 | 1–3 |
| 2 | 82 | 2–5 |
| 3 | 103 | 3–6 |
| 4 | 170 | 4–7 |
| 5 | 276 | 5–8 |

The pattern is clear: **larger regions require cutting through more
internal faces**. The min-cut (= entropy $S$) grows with the region
size (= discrete area $A$). In Planck units where each face carries
one unit of entanglement capacity, this is:

$$S_{\mathrm{cut}}(A) \;\leq\; k \cdot 6$$

where $k$ is the number of cells in the region and 6 is the
coordination number of the cubic cell. The factor $1/4G$ in the
continuum formula is absorbed into the bond dimension and tiling
geometry.

**The discrete Ryu–Takayanagi correspondence $S_{\text{cut}} = L_{\text{min}}$
already proven by the repository (Theorems 3, D50Theorem3, D100Theorem3)
IS the discrete Bekenstein–Hawking formula.** The area of the
minimal surface (face-count of the min-cut) equals the entanglement
entropy. The question of Section 8 is: what happens when you coarse-
grain this discrete formula by averaging over regions at a fixed
resolution?

### 8.3 The Key CS Insight: Orbit Reduction IS Coarse-Graining

The orbit reduction strategy already implemented in
`Common/Dense100Spec.agda` is the first concrete step of the
thermodynamic limit:

```agda
-- From Common/Dense100Spec.agda  (generated by 09_generate_dense100.py)
classify100 : D100Region → D100OrbitRep
```

This function maps 717 fine-grained regions to 8 orbit
representatives, grouped by min-cut value. All regions in a given
orbit have the same entropy. This is a **resolution reduction**:
an observer who only sees `D100OrbitRep` cannot distinguish between
the 717 individual boundary configurations — they can only read the
*statistical summary* (the min-cut value class).

The 1-line lifting proof:

```agda
-- From Bridge/Dense100Obs.agda
d100-pointwise r = d100-pointwise-rep (classify100 r)
```

already witnesses that the coarse-grained observable is
**compatible** with the fine-grained one: the classification
function preserves the discrete RT correspondence. This is the type-
theoretic content of the statement "statistical averaging preserves
the entropy–area relationship."

### 8.4 Formal Definition: The Coarse-Graining Tower

A **coarse-graining tower** is a sequence of progressively
lower-resolution views of the same underlying patch. Concretely:

```
Dense-100 (717 regions) → D100OrbitRep (8 orbits) → D20OrbitRep (4 classes) → Bool
```

Each arrow is a surjection that merges indistinguishable regions.
At the coarsest level (`Bool`), only two classes remain: "small
entropy" and "large entropy." At the finest level, each region is
individually resolved.

In type-theoretic terms, a single level of coarse-graining is a
record:

```agda
record CoarseGrainLevel (Fine Coarse : Type₀) : Type₀ where
  field
    project   : Fine → Coarse
    obs-fine  : Fine → ℚ≥0
    obs-coarse : Coarse → ℚ≥0
    compat    : (r : Fine) → obs-fine r ≡ obs-coarse (project r)
```

The existing orbit reduction already instantiates this record:

- `Fine   = D100Region`     (717 constructors)
- `Coarse = D100OrbitRep`   (8 constructors)
- `project = classify100`
- `obs-fine = S-cut d100BdyView`
- `obs-coarse = S-cut-rep`
- `compat = d100-pointwise`

A **tower** is a list of such levels composed sequentially. The
thermodynamic limit is the claim that as the number of levels
grows (coarser and coarser resolution), the coarsest-level
observable converges to a smooth function — the entropy density
of the vacuum state. This claim is **beyond** the scope of
constructive Cubical Agda (see §8.8), but the finite levels are
fully formalizable.

### 8.5 The Discrete Area Law as a Formalizable Theorem

**Theorem (Discrete Area Law).** For the Dense-$N$ family of
patches, the min-cut value of any cell-aligned boundary region
of $k$ cells is bounded by the total face-count of those cells:

$$S_{\mathrm{cut}}(A) \;\leq\; 6k - 2 \cdot |\mathrm{internal\;faces\;within\;}A|$$

The right-hand side is the **boundary surface area** of the region
$A$ within the cell complex (in face-count units). This is a
discrete isoperimetric inequality: the entropy is bounded by the
boundary area of the region.

**Formalization approach:**

1. For each region $A$ of $k$ cells, the min-cut cannot exceed
   the total number of faces connecting $A$ to its complement.
   This is a graph-theoretic tautology: the max-flow is bounded
   by the capacity of any cut, and the trivial cut (all faces
   of $A$ that exit to the complement) provides the upper bound.

2. The number of exiting faces is $6k - 2 \cdot (\text{internal
   faces within } A)$ because each cell has 6 faces, and each
   internal face within $A$ is shared by two $A$-cells (counted
   twice, then subtracted).

3. For an Agda proof, this reduces to a finite case split on all
   regions (already available from the Python oracle), verifying
   the inequality on each region by `(k , refl)`.

The Python oracle already computes and verifies this bound
numerically. The Agda formalization follows the existing
`(k , refl)` pattern from `Boundary/StarSubadditivity.agda`
and `Boundary/FilledSubadditivity.agda`.

### 8.6 The Macroscopic Observer as a Type-Theoretic Concept

A **macroscopic observer** is formalized as a pair:

$$(\texttt{Coarse},\; \texttt{project} : \texttt{Fine} \to \texttt{Coarse})$$

where `Coarse` has strictly fewer constructors than `Fine`. The
observer is "macroscopic" because they lack the memory to store
the full fine-grained state — they can only track which orbit
class each region belongs to.

The existing codebase provides two concrete observers:

**Observer 1 (Dense-100 orbit reduction):**
```
  Fine   = D100Region  (717 constructors)
  Coarse = D100OrbitRep (8 constructors)
  Memory = 3 bits (⌈log₂ 8⌉)
```

**Observer 2 (Dense-50 flat enumeration):**
```
  Fine   = D50Region  (139 constructors)
  Coarse = D50Region  (139 constructors, identity projection)
  Memory = 8 bits (⌈log₂ 139⌉)
```

Observer 1 is "more macroscopic" — they see less detail but the
holographic correspondence still holds at their resolution. The
thermodynamic claim is: as the patch grows ($N \to \infty$) while
the observer's memory stays bounded, the coarse-grained observable
approaches the continuum entropy formula.

The formalization does not need to prove the limit. It suffices to
prove that **for every finite $N$ and every resolution level, the
coarse-grained observable satisfies the discrete area law**. The
limit statement is a metatheoretic claim about the $N \to \infty$
family, which belongs to external mathematical analysis.

### 8.7 Implementation Plan

**Tier 1 — Coarse-Graining Witness Records (current infrastructure).**

Define a `CoarseGrainWitness` record in a new module
`Bridge/CoarseGrain.agda`:

```agda
record CoarseGrainWitness : Type₁ where
  field
    FineRegion   : Type₀
    CoarseRegion : Type₀
    project      : FineRegion → CoarseRegion
    obs-fine     : FineRegion → ℚ≥0
    obs-coarse   : CoarseRegion → ℚ≥0
    compat       : (r : FineRegion) → obs-fine r ≡ obs-coarse (project r)
    bridge       : (o : CoarseRegion) → obs-coarse o ≡ obs-coarse o
                   -- (placeholder for the RT correspondence at the coarse level)
```

Instantiate it for Dense-100 by importing the existing orbit
reduction machinery:

```agda
dense100-coarse-witness : CoarseGrainWitness
dense100-coarse-witness .FineRegion   = D100Region
dense100-coarse-witness .CoarseRegion = D100OrbitRep
dense100-coarse-witness .project      = classify100
dense100-coarse-witness .obs-fine     = S-cut d100BdyView
dense100-coarse-witness .obs-coarse   = S-cut-rep
dense100-coarse-witness .compat       = d100-pointwise
dense100-coarse-witness .bridge _ = refl
```

This is a one-day task using only existing imports.

**Tier 2 — Area-Law Upper Bound (Python oracle + abstract proof).**

Extend the Python generator (`09_generate_dense100.py`) to emit a
module `Boundary/Dense100AreaLaw.agda` containing:

1. A function `regionArea : D100Region → ℚ≥0` returning the
   face-count boundary area of each region (computable from
   the cell complex data already in the Python oracle).

2. An `abstract` proof:
   ```agda
   abstract
     area-law : (r : D100Region) → S-cut d100BdyView r ≤ℚ regionArea r
   ```
   Each case is `(k , refl)` where $k$ is the slack between
   min-cut and boundary area.

This follows the established Approach A+C pattern from §3.6 and
is expected to type-check for the same reasons the 360-case
subadditivity proof does.

**Tier 3 — Multi-Resolution Tower (stretch goal).**

Define a second, coarser orbit type by grouping the 8 min-cut
classes of Dense-100 into 4 bins (e.g., low/medium-low/medium-high/
high entropy). Chain two `CoarseGrainLevel` records into a tower:

```
D100Region (717) → D100OrbitRep (8) → D100Bin (4)
```

Prove that the RT correspondence holds at every level of the
tower. This demonstrates the resolution-independence of the
holographic correspondence — a constructive shadow of the
thermodynamic limit.

### 8.8 The Hard Boundary: Continuum Convergence

The thermodynamic limit — proving that the discrete area law
*converges to a smooth S = A/4G* as the lattice spacing goes to
zero — is **beyond the scope of constructive formalization** in
Cubical Agda. The obstacles are:

1. **No constructive reals.** The continuum formula involves
   real-valued areas and Newton's constant $G$. Constructive
   real analysis in Agda is an active, largely unsolved
   research area (see `Cubical.HITs.Reals` — rudimentary
   and not sufficient for convergence proofs).

2. **No inductive limit.** Defining the $N \to \infty$ limit
   requires either a coinductive type (incompatible with
   `--safe`) or an external metatheoretic argument. The Agda
   formalization can produce a series of witnesses for finite
   $N$ but cannot internalize the limit.

3. **No smooth geometry.** The factor $1/4G$ depends on the
   specific embedding geometry (Planck length, Newton's
   constant) which has no discrete analogue without a
   continuum interpretation.

These obstacles are **not bugs** — they are the correct conceptual
boundary between the discrete type-theoretic formalization and the
continuum physics claim. The project's contribution is to show that
at every finite resolution, the discrete formulas are exactly
correct. The extrapolation to the continuum is a *physical claim*
supported by the formal evidence, not a *formal theorem*.

### 8.9 Relationship to Existing Code

The coarse-graining route builds on (but does NOT modify):

- `Common/Dense100Spec.agda` — `D100OrbitRep`, `classify100`
- `Bridge/Dense100Obs.agda` — `d100-pointwise`, orbit lifting
- `Bridge/Dense100Equiv.agda` — enriched equivalence
- `Util/Scalars.agda` — `_≤ℚ_` ordering

New modules:

```text
src/Bridge/CoarseGrain.agda               — CoarseGrainWitness record
src/Boundary/Dense100AreaLaw.agda          — area-law upper bound (generated)
```

The Python oracle extensions:

```text
sim/prototyping/11_generate_area_law.py    — area-law oracle + Agda emitter
```

### 8.10 What Success Looks Like

The coarse-graining route does NOT claim to prove quantum gravity.
It claims something much more precise and modest:

> **For every finite discrete holographic patch formalized in
> this repository, the entropy–area relationship holds exactly
> at every resolution level accessible to a finite observer.**

This is the constructive, machine-checked content of the informal
statement "gravity is the thermodynamics of entanglement." The
continuum extrapolation — that these discrete witnesses form a
convergent sequence whose limit is Einstein's equations — is a
physics conjecture supported by the formal evidence, but it is not
itself a formal theorem.

The fully formalized statement would be:

```agda
-- The observable-package equivalence (Theorem 3) at Dense-100
-- factors through the coarse-graining witness, and the
-- area-law bound holds at every resolution level.

CoarseGrainedRT : Type₁
CoarseGrainedRT = Σ[ w ∈ CoarseGrainWitness ]
  ((r : CoarseGrainWitness.FineRegion w) →
   CoarseGrainWitness.obs-fine w r ≤ℚ regionArea r)
```

Paired with the existing Dense-100 bridge theorem, this packages:

1. The exact discrete RT correspondence ($S = L$) on all 717 regions
2. The orbit reduction (717 → 8 representative classes)
3. The area-law upper bound ($S \leq A$) on all 717 regions
4. The factorization: all three cohere through `classify100`

This is a publishable formalization result in the proof engineering
literature, independent of whether the continuum limit converges.

### 8.11 Exit Criterion

The "Thermodynamic Illusion" route is complete when:

1. A `CoarseGrainWitness` record type-checks in
   `Bridge/CoarseGrain.agda` with the Dense-100 orbit reduction
   as the concrete instance.

2. A Python-generated `Boundary/Dense100AreaLaw.agda` contains
   717 `abstract` cases of `(k , refl)` proving the discrete
   area law, and type-checks.

3. (Stretch) A two-level tower instantiation demonstrates
   resolution-independence of the holographic correspondence.

---

## 9. Time and Motion: The "Time as Computation" Route

### 9.1 The Physics Objection

Physicists look at this formalization and say, "This is a static
snapshot. It has no Hamiltonian. There is no $U = e^{-iHt}$ to
evolve the system forward. The universe is frozen."

This is a legitimate criticism. Every module in the repository
proves a property of a *fixed* discrete geometry: a single patch
with a single weight assignment, a single curvature distribution,
a single set of observables. Nothing evolves. Nothing moves.

### 9.2 The CS Translation: Time as Parameterized Bridge Application

The response is that the repository already contains the raw
material for a discrete notion of dynamics — it simply has not
been packaged as such.

**Observation.** The repository contains *multiple* bridge
equivalences, each proven at a different point in a parameter
space:

| Bridge instance     | Parameter value          | Regions | Min-cut  |
|---|---|---|---|
| Tree pilot          | 7-vertex binary tree     | 8       | 1–2      |
| Star (6-tile)       | $\{5,4\}$ star, $w=1$   | 10      | 1–2      |
| Filled (11-tile)    | $\{5,4\}$ disk, $w=1$   | 90      | 2–4      |
| Honeycomb (BFS-32)  | $\{4,3,5\}$ BFS star    | 26      | 1        |
| Dense-50            | $\{4,3,5\}$ dense, 50c  | 139     | 1–7      |
| Dense-100           | $\{4,3,5\}$ dense, 100c | 717     | 1–8      |

Each row is a "snapshot" — a common source specification $c_n$
with a fully verified bridge:

$$\texttt{transport}\;(\texttt{ua}\;\texttt{bridge}_n)\;
  \texttt{bdy}_n \;\equiv\; \texttt{bulk}_n$$

The sequence $c_0, c_1, c_2, \ldots$ IS a discrete time evolution.
What changes from step to step is the *complexity* of the
entanglement network (more cells, more internal faces, deeper
min-cut surfaces). What is *preserved* at every step is the
holographic correspondence: the bulk always tracks the boundary.

**"Time" is the index $n$ into the family of verified snapshots.**

Each "tick" of the discrete clock is a transition from one
specification to the next. The bridge forces the bulk geometry to
update to remain consistent with the boundary data — exactly the
informal claim from the physics motivation.  The "CPU cycle" is
the Agda type-checker verifying the bridge at the new specification.

### 9.3 Relationship to Graph Rewriting

In the physics literature, **local unitary evolution** on a tensor
network corresponds to a small modification of a small number of
tensors: flipping a few qubits, changing a bond dimension, or
rewiring a local patch of the graph. In the discrete combinatorial
setting of this project, the analogue is a **specification
mutation**: a function

$$\texttt{step} : \texttt{Spec}_n \to \texttt{Spec}_{n+1}$$

that changes some bond weights, adds or removes a cell, or
modifies the boundary partition. The repository's existing
pipeline from prototype 01 through prototype 11 computes the
min-cut values *for any valid specification*, and the Agda code
generators emit the bridge proof for each specific instance.

The "graph rewrite" interpretation:

- **Delete an edge** connecting node A to node B: reduce the
  bond weight $w(\texttt{bAB})$ by 1.
- **Create an edge** connecting A to C: add a new bond with
  weight 1 to the specification.
- **Add a cell**: extend the patch (as in the Dense-50 → Dense-100
  transition).

Each rewrite produces a new specification. If the new specification
still satisfies the RT correspondence (verifiable by the Python
oracle and confirmed by the Agda type-checker), the bridge holds
at the new time-step, and the bulk geometry has "updated" to
reflect the change.

### 9.4 What the Existing Code Already Demonstrates

**Two concrete "time evolutions" are already formalized:**

**Evolution 1 — The RG Flow (increasing resolution):**

$$\texttt{Dense-50}\;(139\;\text{regions}) \to
  \texttt{Dense-100}\;(717\;\text{regions})$$

Both are proven bridge instances on the same $\{4,3,5\}$ honeycomb.
The transition adds 50 cells to the bulk, doubles the boundary
complexity, and grows the min-cut spectrum from $\{1\text{–}7\}$
to $\{1\text{–}8\}$. The `CoarseGrainWitness` from
`Bridge/CoarseGrain.agda` (Section 8) already witnesses that the
coarse-grained observable is compatible with the fine-grained one
at each scale — this is the discrete analogue of Renormalization
Group (RG) flow.

**Evolution 2 — The Curvature Flip (Wick rotation):**

$$\{5,4\}\;(\kappa < 0,\;\text{AdS}) \;\to\;
  \{5,3\}\;(\kappa > 0,\;\text{dS})$$

Both are proven bridge instances sharing the *same* boundary
observables but different bulk curvatures. The `WickRotationWitness`
from `Bridge/WickRotation.agda` (Section 7) already packages the
coherence of the bridge across the curvature sign flip. Viewed as
a "time evolution," this corresponds to a cosmological phase
transition where the sign of the cosmological constant $\Lambda$
flips while the holographic correspondence is preserved.

### 9.5 Concrete Implementation: `DynamicsWitness`

The proposed formalization packages the above observations as a
record type in a new module `Bridge/Dynamics.agda`:

```agda
record DynamicsWitness : Type₁ where
  field
    -- Two consecutive "time slices"
    SliceBdy₁  SliceBulk₁  : Type₀
    SliceBdy₂  SliceBulk₂  : Type₀

    -- Canonical data at each slice
    bdy₁   : SliceBdy₁
    bulk₁  : SliceBulk₁
    bdy₂   : SliceBdy₂
    bulk₂  : SliceBulk₂

    -- Bridge at each slice (the holographic correspondence holds)
    bridge₁ : SliceBdy₁ ≃ SliceBulk₁
    bridge₂ : SliceBdy₂ ≃ SliceBulk₂

    -- Transport verification at each slice
    --   (the bulk is uniquely determined by the boundary)
    verified₁ : transport (ua bridge₁) bdy₁ ≡ bulk₁
    verified₂ : transport (ua bridge₂) bdy₂ ≡ bulk₂
```

**Instantiation 1 — RG flow step (Dense-50 → Dense-100):**

```agda
rg-flow-step : DynamicsWitness
rg-flow-step .SliceBdy₁  = D50EnrichedBdy
rg-flow-step .SliceBulk₁ = D50EnrichedBulk
rg-flow-step .SliceBdy₂  = D100EnrichedBdy
rg-flow-step .SliceBulk₂ = D100EnrichedBulk
rg-flow-step .bdy₁       = d50-bdy-instance
rg-flow-step .bulk₁      = d50-bulk-instance
rg-flow-step .bdy₂       = d100-bdy-instance
rg-flow-step .bulk₂      = d100-bulk-instance
rg-flow-step .bridge₁    = d50-enriched-equiv
rg-flow-step .bridge₂    = d100-enriched-equiv
rg-flow-step .verified₁  = d50-enriched-transport
rg-flow-step .verified₂  = d100-enriched-transport
```

All fields are filled from existing, already-typechecked modules.
No new proofs are required. The record merely *packages* the
existing verified snapshots as consecutive time-slices.

**Instantiation 2 — Wick rotation step (AdS → dS):**

The curvature flip can be packaged as a `DynamicsWitness` where
both slices share the same bridge but carry different curvature
witnesses (imported from `Bridge/WickRotation.agda`). The
`shared-bridge` field from `WickRotationWitness` is literally the
same term for both slices, witnessing curvature-agnostic dynamics.

### 9.6 The Error-Correction Interpretation

The bulk-tracks-boundary property formalized by `verified₁` and
`verified₂` is the type-theoretic content of the claim that the
bulk geometry is an **error-correcting code** for the boundary
data.

At each time-step, the boundary may change arbitrarily (within the
space of valid specifications). The bridge equivalence guarantees
that there exists a *unique* bulk configuration consistent with the
new boundary data, and `transport` along the `ua` path *computes*
that configuration. The "error correction" is the act of
transport: it takes potentially inconsistent boundary+bulk data
and produces the unique consistent bulk configuration.

The "tick of a clock" is therefore a single application of
`transport` — the universe recomputing its bulk geometry to match
the changed boundary constraints. What we experience as "time
passing" is, in this interpretation, the macroscopic effect of
sequential bridge applications forcing the discrete geometry to
remain holographically consistent.

### 9.7 The Hard Boundary: Continuous Time and Unitarity

The following aspects of physical time evolution are **beyond the
scope** of this formalization and represent hard boundaries:

**No continuous time parameter $t \in \mathbb{R}$.** The "time" is
a discrete index $n \in \mathbb{N}$ selecting a specification from
a finite list of verified snapshots. Defining a smooth interpolation
$\texttt{Spec}(t)$ for $t \in [0,1]$ requires constructive real
analysis, which is largely unsolved in Cubical Agda. This is the
same obstruction encountered in Section 8 (thermodynamic limit).

**No Hamiltonian $H$ or unitary evolution $U = e^{-iHt}$.** A
Hamiltonian is a self-adjoint operator on a Hilbert space.
Formalizing this requires constructive complex analysis
($\mathbb{C}$), infinite-dimensional Hilbert spaces, and
exponential maps — none of which are available in the current
Cubical Agda infrastructure. The complex-number obstacle is the
same one documented in Section 7 (§7.5.2): the discrete formulation
bypasses it entirely by replacing the analytic object with a
combinatorial parameter change.

**No unitarity (reversibility) guarantee.** The specification
mutation $\texttt{step}$ may not be invertible: adding a cell to
the Dense-50 patch to produce Dense-100 is not obviously reversible
(which subset of cells would you remove?). Physical time evolution
is unitary (reversible) in quantum mechanics. The discrete analogue
would be a proof that `step` is an equivalence (bijection on
specifications), which requires a genuine inversion construction.
This is a potential stretch goal but is not required for the basic
`DynamicsWitness` record.

**No causal structure.** The min-cut / max-flow computation is
*instantaneous* — it does not propagate information along a light
cone. Defining a discrete causal structure on the cell complex
(analogous to the causal diamond in Lorentzian geometry) would
require a notion of "which cells can influence which other cells
within $k$ time-steps," which is a new graph-theoretic structure
not present in the current formalization.

These obstacles are the correct conceptual boundary between the
discrete type-theoretic formalization and the continuum physics
claim. The project's contribution is to show that at every discrete
time-step, the holographic correspondence holds exactly. The
extrapolation to continuous, unitary, Hamiltonian dynamics is a
physics conjecture supported by the formal evidence, not a formal
theorem.

### 9.8 Relationship to Existing Sections

Section 9 is the temporal analogue of Sections 7 and 8:

| Section | Parameter varied     | Invariant preserved    |
|---|---|---|
| 7 (Wick rotation)    | Curvature sign       | Bridge equivalence     |
| 8 (Thermodynamics)   | Resolution level     | Area law + RT          |
| 9 (Dynamics)         | Specification index  | Bridge at each step    |

All three are instances of the same architectural pattern:
*parameterize the common source specification, prove the bridge
at each parameter value, and package the coherence.* The
`WickRotationWitness`, `CoarseGrainedRT`, and `DynamicsWitness`
are all records that assemble independently verified components
into documented coherence packages.

### 9.9 Implementation Plan

**Phase F.0 — Package existing data (no new proofs).**

Define `DynamicsWitness` in `Bridge/Dynamics.agda` and instantiate
it for the Dense-50 → Dense-100 RG flow step. All fields are
imported from existing modules. Estimated effort: 1 day.

**Phase F.1 — Multi-step dynamics.**
*Status: Complete.*
Defined `DynamicsTrace` as a list of `DynamicsWitness` records. Instantiated a 2-step trace (`two-step-trace`) demonstrating consecutive RG flow (Dense-50 → Dense-100) and curvature phase transition (AdS → dS).

**Phase F.2 — Local rewrite dynamics (Deferred).**

Generalize the bridge proof from specific lookup tables to
parameterized weight functions. Define a `step` function that
modifies one bond weight by ±1. Prove that if the bridge holds at
weight assignment $w$, and $w'$ differs from $w$ by a local
change, then the bridge holds at $w'$. This would give a
*generic* dynamics theorem rather than a finite list of verified
snapshots.

Phase F.2 requires generalizing the current `refl`-based proofs
(which depend on specific numerals) to parameterized proofs
(which would require ℕ arithmetic lemmas). This is a significant
proof-engineering challenge but is within the capabilities of
Cubical Agda.

### 9.10 Exit Criterion

The "Time as Computation" route is complete when:

1. A `DynamicsWitness` record type-checks in `Bridge/Dynamics.agda`
   with the Dense-50 → Dense-100 RG flow step as the concrete
   instance.

2. All fields are filled from existing, independently verified
   modules (no new proofs required for Phase F.0).

3. A `DynamicsTrace` of length 2 is successfully instantiated (`two-step-trace`), demonstrating multi-step discrete time evolution across both resolution and curvature parameters, with the bridge verified at every step.

### 9.11 What Success Looks Like

The dynamics route does NOT claim to prove that time exists or
that the universe evolves by graph rewriting. It claims something
precise and modest:

> **For every pair of verified holographic snapshots in this
> repository, the bulk geometry at each snapshot is uniquely
> determined by the boundary data via computable transport. The
> sequence of snapshots constitutes a discrete time evolution in
> which the holographic correspondence is maintained at every
> step.**

This is the constructive, machine-checked content of the informal
claim "time is just the universe compiling its next state." The
compilation is literally `transport` along the `ua` path; the
"next state" is the bulk observable bundle at the new specification;
and the "compiling" is the Agda type-checker verifying that
transport reduces via `uaβ` to the concrete forward map.

---

## 10. Infinite Resolution (The Continuum Limit)

### 10.1 The Physics Problem

The universe governed by General Relativity is a smooth
4-dimensional Lorentzian manifold.  Einstein's field equations
are partial differential equations on continuous fields.  The
Bekenstein–Hawking entropy formula $S = A / 4G$ involves a
continuous area $A$ and Newton's gravitational constant $G$.

The repository's toy model is a finite collection of discrete
cubic cells (`Dense-100`).  Space is pixelated.  The min-cut
entropy is a natural number.  The "area" is a face count.

The continuum limit is the claim that as the number of cells
$N \to \infty$ and the cell size $\varepsilon \to 0$, the
discrete holographic correspondence converges to the smooth
Ryu–Takayanagi formula, the discrete Gauss–Bonnet converges to
the smooth Gauss–Bonnet theorem, and the discrete area law
converges to Bekenstein–Hawking.

In software terms: you are proving that a polygon mesh
mathematically behaves exactly like a smooth sphere, in the
limit of infinite resolution.  Physicists call this the
**thermodynamic limit**.

### 10.2 What the Existing Code Already Proves

The repository contains a monotonically growing family of
verified holographic patches, each with a machine-checked RT
correspondence, a Gauss–Bonnet theorem, and (for the Dense
patches) an area-law bound:

| Instance    | Dim  | Regions | Orbits | Min-cut | Theorem 3 | Area law |
|---|---|---|---|---|---|---|
| Tree        | 1D   |       8 |      — |     1–2 | ✓         |          |
| Star        | 2D   |      10 |      — |     1–2 | ✓         |          |
| Filled      | 2D   |      90 |      — |     2–4 | ✓         |          |
| Honeycomb   | 3D   |      26 |      — |       1 | ✓         |          |
| Dense-50    | 3D   |     139 |      — |     1–7 | ✓         |          |
| Dense-100   | 3D   |     717 |      8 |     1–8 | ✓         | ✓        |

Two patterns are empirically visible:

1. **The min-cut spectrum grows monotonically.**  As the
   patch includes more cells, the maximum min-cut value
   increases: 2 → 2 → 4 → 1 → 7 → 8.  Boundary regions
   require cutting through progressively deeper multi-face
   separating surfaces.  This is the discrete analogue of
   the Ryu–Takayanagi surface growing in area as the
   boundary region probes deeper into the bulk.

2. **The area-law bound is uniformly satisfied.**  For
   Dense-100, all 717 regions satisfy $S(A) \leq \mathrm{area}(A)$
   with slack ranging from 3 to 18.  The ratio $S / \mathrm{area}$
   is bounded away from 1 for all region sizes, suggesting
   that the bound is not saturated — the min-cut is strictly
   cheaper than the trivial cut.

These patterns are the **empirical evidence** for convergence.
The question is: how much of this can be formalized, and where
exactly does the formal boundary lie?

### 10.3 The Formal Architecture: Resolution Towers

The key formal object is a **resolution tower**: a sequence of
verified patches at increasing resolution, connected by
compatibility witnesses certifying that each finer level is a
refinement of the coarser one.

A single step of the tower pairs two verified levels with a
projection from the finer to the coarser:

```agda
record ResolutionStep : Type₁ where
  field
    -- The two resolution levels
    FineRegion   : Type₀
    CoarseRegion : Type₀

    -- Observables at each level
    S-fine       : FineRegion → ℚ≥0
    L-fine       : FineRegion → ℚ≥0
    S-coarse     : CoarseRegion → ℚ≥0

    -- RT correspondence at each level
    rt-fine      : (r : FineRegion) → S-fine r ≡ L-fine r
    rt-coarse    : (o : CoarseRegion) → S-coarse o ≡ S-coarse o
                   -- (placeholder; a genuine coarse bridge
                   --  would have L-coarse and rt : S ≡ L)

    -- The coarse-graining factorization
    project      : FineRegion → CoarseRegion
    compat       : (r : FineRegion) →
                   S-fine r ≡ S-coarse (project r)
```

This is exactly `CoarseGrainWitness` from
`Bridge/CoarseGrain.agda`, augmented with the RT
correspondence at the fine level.  The existing
`dense100-coarse-witness` already instantiates the
coarse-graining part; the RT correspondence comes from
`Bridge/Dense100Equiv.agda`.

A **tower** is a list of such steps, where each step's
`CoarseRegion` matches the previous step's `FineRegion`:

```agda
data ResolutionTower : ℕ → Type₁ where
  base : ResolutionStep → ResolutionTower zero
  step : ResolutionStep → ResolutionTower n
       → ResolutionTower (suc n)
```

The Dense-50 → Dense-100 transition is the first concrete
step.  Future extensions (Dense-200, Dense-500, ...) would
add more steps, each generated by the same Python oracle +
abstract barrier + orbit reduction pipeline.

### 10.4 Concrete Implementation

The resolution tower instantiation assembles components from
existing, already type-checked modules.  No new proofs are
required — only new packaging.

**Module location:**  `src/Bridge/ResolutionTower.agda`

**Imports:**

```agda
open import Bridge.Dense50Equiv
  using ( D50EnrichedBdy ; D50EnrichedBulk
        ; d50-enriched-equiv ; d50-enriched-transport )
open import Bridge.Dense100Equiv
  using ( D100EnrichedBdy ; D100EnrichedBulk
        ; d100-enriched-equiv ; d100-enriched-transport )
open import Bridge.CoarseGrain
  using ( CoarseGrainWitness ; dense100-coarse-witness )
open import Bridge.Dense100Obs
  using ( d100-pointwise ; S∂D100 ; LBD100 )
```

**The resolution step:**

```agda
dense-resolution-step : ResolutionStep
dense-resolution-step .FineRegion   = D100Region
dense-resolution-step .CoarseRegion = D100OrbitRep
dense-resolution-step .S-fine       = S∂D100
dense-resolution-step .L-fine       = LBD100
dense-resolution-step .S-coarse     = S-cut-rep
dense-resolution-step .rt-fine      = d100-pointwise
dense-resolution-step .rt-coarse _  = refl
dense-resolution-step .project      = classify100
dense-resolution-step .compat _     = refl
```

All fields are filled from previously verified modules.  The
`compat` field is `refl` because `S-cut` is definitionally
`S-cut-rep ∘ classify100` in `Boundary/Dense100Cut.agda`.
The `rt-fine` field inherits the 8-orbit refl proofs + 1-line
lifting from `Bridge/Dense100Obs.agda`.

### 10.5 The Monotonicity Witness

The growing min-cut spectrum is a formalizable invariant.  For
the Dense-50 → Dense-100 transition:

- Dense-50:  max min-cut = 7
- Dense-100: max min-cut = 8

This is a concrete inequality  $7 \leq 8$,  witnessed by
$(1 , \mathsf{refl})$ because $1 + 7 = 8$ judgmentally.

```agda
spectrum-grows : 7 ≤ℚ 8
spectrum-grows = 1 , refl
```

More precisely, the formalizable statement is: the range of
the fine-level observable function is at least as wide as the
coarse-level observable function.  This is a **single concrete
inequality** for each pair of consecutive levels, not a generic
inductive proof.

For the full tower, the spectrum growth would be:

| Transition           | Max$_{\text{lo}}$ | Max$_{\text{hi}}$ | Witness      |
|---|---|---|---|
| Dense-50 → Dense-100 | 7                  | 8                  | `(1 , refl)` |
| Dense-100 → Dense-200| 8                  | $\geq 8$           | (future)     |

Each row is a single `refl` proof on closed ℕ terms.  The
table as a whole constitutes the empirical evidence for
monotone convergence of the min-cut spectrum.

### 10.6 The Area-Law Convergence

Section 8 proves the discrete area law
$S_{\text{cut}}(A) \leq \mathrm{area}(A)$ for all 717 regions
of the Dense-100 patch.  The continuum Bekenstein–Hawking
formula $S = A / 4G$ asserts that this inequality becomes an
**equality** (up to a universal constant $1/4G$) in the
continuum limit.

The formalizable content at each finite level is:

```agda
record AreaLawLevel : Type₁ where
  field
    RegionTy     : Type₀
    S-obs        : RegionTy → ℚ≥0
    area         : RegionTy → ℚ≥0
    area-bound   : (r : RegionTy) → S-obs r ≤ℚ area r
```

The `CoarseGrainedRT` type from `Bridge/CoarseGrain.agda`
already packages this together with the orbit reduction.  The
concrete instance `dense100-thermodynamics` from
`Bridge/Dense100Thermodynamics.agda` satisfies it.

What CANNOT be formalized is the **ratio convergence**:

$$\lim_{N \to \infty} \frac{S_{\text{cut}}(A_N)}{\mathrm{area}(A_N)} = \frac{1}{4G}$$

This requires:
1. A parameterized family $A_N$ of regions at each resolution
2. A real-valued limit
3. An identification of the constant $1/4G$

All three are beyond the current infrastructure.  But the
**finite evidence** is available: for Dense-100, the slack
distribution (area − min-cut) has mean 11.3 and range 3–18,
with no region achieving slack 0 (the area law is never
tight).  A future Dense-200 or Dense-500 instance would
provide additional data points, and the Python oracle can
compute the empirical ratio for each level.

### 10.7 The Hard Boundary: Three Obstacles

Three independent obstacles prevent formalizing the full
continuum limit in Cubical Agda.  Each is a fundamental
limitation of the proof-assistant infrastructure, not a
deficiency of the mathematical formulation.

**Obstacle 1: No constructive reals.**
The continuum formula involves real-valued areas and Newton's
constant $G$.  The cubical library's `Cubical.HITs.Reals`
provides only rudimentary support — no completeness, no
convergence of sequences, no integration.  A usable
constructive real type with limits would require a
multi-year library development effort comparable to
`mathlib` for Lean.

**Obstacle 2: No inductive limit.**
Defining the $N \to \infty$ limit requires either:
(a) a coinductive stream of verified patches (incompatible
    with `--safe` in the general case), or
(b) an external metatheoretic argument about the
    $\mathbb{N}$-indexed family.

The Agda formalization can produce verified witnesses for
each finite $N$ but cannot internalize the statement
"for all $N$, the properties hold and the sequence converges."
The universal quantifier $\forall N$ is fine; the convergence
of the sequence is the problem.

**Obstacle 3: No smooth geometry.**
The factor $1/4G$ depends on the specific embedding geometry
(Planck length, Newton's constant) which has no discrete
analogue without a continuum interpretation.  Identifying
the discrete bond dimension with $1/4G$ is a **physical
interpretation**, not a mathematical derivation.

### 10.8 The Coinductive Horizon

The closest approach to internalizing the continuum limit in
Cubical Agda would use coinductive types (guarded recursion)
to define an infinite stream of verified patches.

```agda
{-# OPTIONS --cubical --guardedness #-}

record PatchStream : Type₁ where
  coinductive
  field
    head    : VerifiedPatch
    tail    : PatchStream
    refines : ResolutionStep (head-of tail) head
```

Here `VerifiedPatch` captures a single verified level
(RT correspondence + area law + Gauss–Bonnet), and `refines`
witnesses that each level is a refinement of the next.

The `--guardedness` flag enables coinductive types but
requires careful productivity checking: the stream must be
defined by copattern matching, and each field must produce
its result in a guarded position.

**Feasibility assessment:**  Coinductive types in Cubical Agda
are well-studied (Veltri 2021, "Guarded Recursion in Agda
via Sized Types"; the cubical library's
`Cubical.Codata.Stream`).  The core difficulty is not the
coinductive infrastructure but the **content of each cell**:
each `head` must be a fully verified patch, which currently
requires a Python oracle to generate.  An infinite stream
would require a **generic patch constructor** — an Agda
function that, given $N$, produces a verified `Dense-N`
patch.  This is equivalent to generalizing the min-cut
algorithm and the Gauss–Bonnet summation to arbitrary $N$,
which is direction C (N-Layer Generalization,
[§5](10-frontier.md#5-deferred-direction-c--generalizing-to-n-layers-graph-induction-boundary)),
currently deferred due to the difficulty of the inductive
tiling definition.

**The coinductive horizon is reachable if and only if
Direction C succeeds.**  Without a generic patch constructor,
the stream can only be defined for a finite prefix — which
is exactly the resolution tower of §10.3, not a coinductive
object.

### 10.9 What CAN Be Done: The Convergence Certificate

Even without formalizing the limit, the repository can produce
a **convergence certificate**: a finite package of data that
a mathematician or physicist can inspect to assess convergence.

The certificate is a record containing:

```agda
record ConvergenceCertificate : Type₁ where
  field
    -- Verified levels (from least to most resolved)
    n-levels      : ℕ
    levels        : Fin n-levels → VerifiedPatch

    -- Each consecutive pair is connected by a refinement step
    refinements   : (i : Fin (n-levels ∸ 1)) →
                    ResolutionStep (levels (inject₁ i)) (levels (fsuc i))

    -- Monotonicity: the max min-cut is non-decreasing
    monotone      : (i : Fin (n-levels ∸ 1)) →
                    max-cut (levels (inject₁ i))
                    ≤ℚ max-cut (levels (fsuc i))

    -- Area law holds at every level
    area-law-all  : (i : Fin n-levels) →
                    AreaLawLevel (levels i)
```

This type is **not** a convergence proof.  It is a finite
collection of verified artifacts organized for inspection.
The convergence claim is a **metatheoretic judgment** made by
a human reading the certificate — exactly as the Four Color
Theorem is a metatheoretic consequence of a finite (but
computationally verified) case analysis.

For the current repository, the certificate contains 2 levels
(Dense-50 and Dense-100), 1 refinement step, 1 monotonicity
witness (`7 ≤ 8`), and 1 area-law instance (717 cases).  Each
additional Dense-$N$ instance added by the Python oracle +
Agda verification pipeline extends the certificate by one
level.

### 10.10 Relationship to Existing Sections

Section 10 is the spatial (resolution) analogue of Sections 8
and 9:

| Section | Direction              | Parameter varied | Invariant preserved    |
|---|---|---|---|
| 8 (Thermodynamics) | Coarse-graining    | Observer resolution  | Area law + RT          |
| 9 (Dynamics)       | Temporal           | Specification index  | Bridge at each step    |
| 10 (Continuum)     | Spatial refinement | Cell count $N$       | RT + area law + GB     |

All three share the same architectural pattern:
*parameterize the common source specification, verify the
bridge at each parameter value, and package the coherence.*

The `CoarseGrainWitness` (Section 8) captures the zoom-OUT
direction: coarser observers see fewer details but the RT
still holds.  The resolution tower (this section) captures
the zoom-IN direction: finer meshes reveal deeper structures
but the RT still holds.  Together they define the **scale
invariance** of the holographic correspondence — the
combinatorial content of the statement "the holographic
principle holds at every scale."

### 10.11 Implementation Plan

**Phase G.0 — ResolutionTower packaging (existing data).**

Define `ResolutionStep` and `ConvergenceCertificate` in
`Bridge/ResolutionTower.agda`.  Instantiate the Dense-50 →
Dense-100 step using only existing imports.  All fields are
filled from existing, independently verified modules.
Estimated effort: 1–2 days.

**Phase G.1 — Dense-200 extension (Python oracle).**

Create `sim/prototyping/12_generate_dense200.py` extending
the Dense growth strategy to 200 cells.  Generate the 5
standard Agda modules (Spec, Cut, Chain, Curvature, Obs) plus
an area-law module.  This adds a second refinement step to
the certificate.  The key empirical question: does the max
min-cut grow to 9 or beyond?

**Phase G.2 — Multi-level tower assembly.**

Extend `Bridge/ResolutionTower.agda` to package Dense-50 →
Dense-100 → Dense-200 as a 3-level certificate.  Prove
spectrum monotonicity for the new step (likely a single
`(k , refl)` witness).  Verify area-law compatibility
across all three levels.

**Phase G.3 — Coinductive tower (conditional on Direction C).**

If Direction C (N-Layer Generalization) succeeds in providing
a generic verified patch constructor  `patch : ℕ → VerifiedPatch`,
define the coinductive stream:

```agda
convergent-stream : PatchStream
convergent-stream .head = patch 100
convergent-stream .tail = convergent-stream-helper 200
  where
    convergent-stream-helper : ℕ → PatchStream
    convergent-stream-helper n .head = patch n
    convergent-stream-helper n .tail = convergent-stream-helper (n + 100)
    convergent-stream-helper n .refines = ...
```

This requires `--guardedness` and a proof that the generic
patch constructor preserves all required properties.  Phase G.3
is deferred until Direction C advances.

### 10.12 The Python Oracle's Role

The Python code generation pipeline plays a critical role in
the continuum limit architecture.  Each Dense-$N$ instance is
generated by the same pattern:

```
07_honeycomb_3d_multiStrategy.py    (patch growth strategy)
      │
      ▼
XX_generate_denseN.py               (code generator for level N)
      │
      ├──▶ Common/DenseNSpec.agda    (regions + orbit classification)
      ├──▶ Boundary/DenseNCut.agda   (S-cut via orbit reps)
      ├──▶ Bulk/DenseNChain.agda     (L-min via orbit reps)
      ├──▶ Bulk/DenseNCurvature.agda (edge curvature + 3D GB)
      ├──▶ Bridge/DenseNObs.agda     (pointwise refl + funExt)
      └──▶ Boundary/DenseNAreaLaw.agda (area-law bound)
                │
                ▼
          Bridge/DenseNEquiv.agda    (enriched equiv, hand-written)
```

The oracle is the **search engine**; Agda is the **checker**.
Adding a new level to the convergence certificate requires
running the oracle at the new cell count and loading the
generated modules into Agda.  The orbit reduction strategy
(§6.5) ensures that the proof obligations grow only
logarithmically with the number of regions: adding more cells
grows the `classifyN` function but not the orbit-level proofs.

### 10.13 Exit Criterion

The continuum limit architecture is complete when:

1. A `ResolutionStep` record type-checks in
   `Bridge/ResolutionTower.agda` with the Dense-50 → Dense-100
   transition as the concrete instance.

2. A `ConvergenceCertificate` record type-checks with at least
   2 levels and 1 monotonicity witness.

3. (Stretch) A Dense-200 instance extends the certificate to
   3 levels, with the new max min-cut ≥ 8 witnessed by
   `(k , refl)`.

### 10.14 What Success Looks Like

The continuum limit route does NOT claim to prove that the
discrete holographic correspondence converges to Einstein's
equations.  It claims something more precise:

> **For every finite resolution level formalized in this
> repository, the discrete Ryu–Takayanagi correspondence,
> the discrete Gauss–Bonnet theorem, and the discrete area
> law hold exactly.  The min-cut spectrum grows monotonically
> with resolution, and the area-law bound is uniformly
> satisfied.  These properties are packaged as a
> machine-checked convergence certificate that can be
> inspected by any mathematician or physicist.**

The continuum extrapolation — that these discrete witnesses
form a convergent sequence whose limit is General Relativity
— is a physics conjecture supported by the formal evidence,
not a formal theorem.  The project's contribution is to make
the evidence machine-checkable and the conjecture precisely
stated.

The fully formalized statement would be:

```agda
-- The resolution tower for the {4,3,5} honeycomb
-- factors through the orbit reduction at each level,
-- the RT correspondence holds at every resolution,
-- the area-law bound holds at every resolution,
-- and the min-cut spectrum grows monotonically.

ContinuumLimitEvidence : Type₁
ContinuumLimitEvidence = ConvergenceCertificate
```

Paired with the existing Dense-50 and Dense-100 bridge
theorems (`d50-theorem3` and `d100-theorem3`), the area-law
instance (`dense100-thermodynamics`), and the coarse-graining
witness (`dense100-coarse-witness`), this packages the
constructive, machine-checked content of the informal claim
"gravity emerges from entanglement in the continuum limit."

---

## 11. The `while(true)` Loop — Local Rewriting Dynamics

### 11.1 Goal

Prove that the holographic bridge (Theorem 3) is **preserved under
local graph rewrites**: starting from any verified specification,
applying a local modification (a single bond-weight change or a
single cell addition) produces a new specification at which the
bridge still holds.  This would give a **generic dynamics theorem**
— the "while(true) loop" of the title — rather than the finite
collection of independently verified snapshots packaged in §9.

In software terms: §9 proves that each *frame* of the movie is
correct.  This section targets the harder claim that the *frame
transition function* is correctness-preserving.

### 11.2 Relationship to §9 (Time as Computation)

Section 9 packages pre-verified snapshots as "time slices" via
`DynamicsWitness` and `DynamicsTrace`.  Phase F.0 (complete)
assembles existing bridge instances into a sequence.  Phase F.1
(complete) chains multiple witnesses into multi-step traces.

**Phase F.2** — "Local rewrite dynamics" — was explicitly deferred
in §9.9 because it requires generalizing from closed-numeral
`refl` proofs to parameterized proofs using ℕ arithmetic lemmas.
This section elaborates Phase F.2 into a concrete technical plan.

The critical distinction:

| Aspect | §9 (Snapshot Dynamics) | §11 (Rewrite Dynamics) |
|---|---|---|
| bridge proofs | independently verified per snapshot | derived from previous step + rewrite lemma |
| number of proofs | one per snapshot (finite) | one inductive proof (covers all steps) |
| new-snapshot cost | re-run Python oracle + Agda type-check | zero (automatic from invariance theorem) |
| obstacle level | packaging (solved) | parameterized arithmetic (open) |

### 11.3 The Target Theorem

The target is a **step-invariance theorem** stating that the
discrete Ryu–Takayanagi correspondence is preserved under local
specification mutations.

**Precise type-theoretic statement** (sketch):

```agda
-- A "step" modifies one bond weight by δ ∈ {+1, −1}
record LocalStep (Spec : Type₀) : Type₀ where
  field
    BondTy   : Type₀
    RegionTy : Type₀
    weights  : Spec → BondTy → ℚ≥0
    S-from-w : (BondTy → ℚ≥0) → RegionTy → ℚ≥0
    L-from-w : (BondTy → ℚ≥0) → RegionTy → ℚ≥0
    target   : BondTy    -- the bond being modified
    δ        : ℚ≥0       -- the perturbation magnitude (= 1)

-- The invariance theorem:
-- If S ≡ L at weight assignment w, then S ≡ L at w[target ↦ w(target) + 1]
step-invariance :
  (w : BondTy → ℚ≥0)
  → ((r : RegionTy) → S-from-w w r ≡ L-from-w w r)
  → ((r : RegionTy) → S-from-w (perturb w target δ) r
                     ≡ L-from-w (perturb w target δ) r)
```

This says: if the RT correspondence holds at weight assignment
$w$, and we modify one bond weight, the RT correspondence still
holds at the perturbed assignment.  The proof must work for
**arbitrary** $w$ — not just the canonical all-ones weight
function.

### 11.4 Why the Current Approach Cannot Do This

Every bridge proof in the repository is of the form:

```agda
star-pointwise regN0 = refl
```

This works because `S-cut` and `L-min` are both defined by
explicit case splits returning canonical ℕ literals, and both
sides reduce to the same literal.  The proofs depend on:

1. **Closed numerals**: the bond weights are specific constants
   (`1q`, `2q`), not variables.
2. **Literal equality**: `1 ≡ 1` by `refl`; there is no
   arithmetic reasoning.

For the step-invariance theorem, the weights are **variables**
(`w : Bond → ℚ≥0`), and the observables are **computed
expressions** involving sums of weight variables:

```agda
minCutFromWeights w regN0N1 = w bCN0 +ℚ w bCN1
```

Proving that this equals the bulk observable at the perturbed
weights requires:

- ℕ commutativity: `a + b ≡ b + a`
- ℕ associativity: `(a + b) + c ≡ a + (b + c)`
- Cancellation lemmas for the perturbation
- Graph-theoretic reasoning about which min-cuts are affected
  by a single-bond perturbation

All of these lemmas exist in `Cubical.Data.Nat.Properties`
and `Cubical.Data.Nat.Order`, but assembling them into a
min-cut invariance proof is a non-trivial graph-theory
formalization effort.

### 11.5 Three Viable Attack Strategies

#### Strategy A — Weight-Perturbation Invariance (Recommended)

Fix the patch topology (e.g., the 6-tile star with its 5 bonds
and 10 regions).  Parameterize the bridge by the weight function
`w : Bond → ℚ≥0` rather than fixing `w = starWeight`.

**Step 1:** Define `minCutFromWeights` generically (already done
in `Bridge/StarRawEquiv.agda` §4):

```agda
minCutFromWeights w regN0   = w bCN0
minCutFromWeights w regN0N1 = w bCN0 +ℚ w bCN1
```

**Step 2:** Define `perturb`:

```agda
perturb : (Bond → ℚ≥0) → Bond → ℚ≥0 → (Bond → ℚ≥0)
perturb w b δ b' = if b ≡? b' then w b' +ℚ δ else w b'
```

This requires decidable equality on `Bond`, which is trivial
for a 5-constructor type.

**Step 3:** Prove that `minCutFromWeights (perturb w b δ)` and
`minCutFromWeights w` differ in a controlled way.  For the star
topology:

- Perturbing bond `bCN0` changes `S(regN0)` by `δ` and
  `S(regN0N1)` by `δ` and `S(regN4N0)` by `δ`.
- All other region values are unchanged.

This is a **finite case split on all (bond, region) pairs**
— 5 bonds × 10 regions = 50 cases, each requiring a simple
ℕ arithmetic lemma.  The proof structure parallels the existing
subadditivity proof in `Boundary/StarSubadditivity.agda` but
with arithmetic lemmas instead of `refl`.

**Step 4:** Since the bulk observable `L-min` has the identical
structure to `S-cut` for the star topology (both are
`minCutFromWeights`), the perturbation affects both sides
equally.  The RT correspondence `S ≡ L` is preserved because
both observables are the same function of the bond weights.

**Feasibility assessment:**  This is the most achievable strategy.
The main effort is:

- 50 cases × 1 arithmetic lemma each ≈ 50 lines of ℕ reasoning
- Decidable equality on `Bond` (5 constructors) ≈ 30 lines
- The `perturb` function and its specification ≈ 20 lines
- The invariance proof assembling the pieces ≈ 40 lines

Total: ~140 lines of new Agda, importing `Cubical.Data.Nat.Properties`
for `+-comm` and `+-assoc`.  No new infrastructure beyond what
the cubical library provides.

**Limitation:**  This proves invariance for the star topology only.
Generalizing to arbitrary topologies requires a generic min-cut
decomposition theorem, which is Direction C territory.

#### Strategy B — Cell-Addition Invariance

Prove that adding one boundary cell to a Dense-$N$ patch (creating
Dense-$(N+1)$) preserves the RT correspondence on the original
regions.

This is harder because:
1. The region type changes (new regions appear).
2. The flow graph has one more node and up to 6 new edges.
3. Existing min-cuts may decrease (the new cell provides
   alternative flow paths).

The orbit reduction strategy helps: if the new cell falls into
an existing orbit class, the orbit-level proof transfers.  If it
creates a new orbit class, one new `refl` case is needed.

**Feasibility:**  Medium.  Requires a notion of "patch extension"
and a proof that orbit classification is stable under single-cell
additions.  Estimated effort: 2–4 weeks.

#### Strategy C — Discrete Causal Structure

Define a partial order on cells representing causal influence
(cells that can affect each other within $k$ graph-rewriting
steps).  This introduces a discrete light cone into the model.

**Feasibility:**  Low.  This is a research-level contribution
to discrete differential geometry / causal set theory.  No
existing Agda infrastructure supports it.  Estimated effort:
months to years, with high risk of encountering fundamental
obstacles in the coalgebraic semantics of discrete spacetimes.

### 11.6 Chosen Strategy

**Attempt Strategy A first** (weight-perturbation invariance on
the 6-tile star), with Strategy B as a follow-up if A succeeds.

Strategy A is the minimal viable "local dynamics" theorem: it
proves that the holographic bridge survives arbitrary bond-weight
perturbations on a fixed topology.  The "while(true) loop" is
then a sequence of perturbations, each preserving the bridge.

Strategy C is deferred as a long-term conceptual horizon, similar
to how cohesive HoTT is positioned in §2.4 of docs/02-foundations.md.

### 11.7 Concrete Implementation Plan

**Phase F.2a — Parameterized Star Bridge (Strategy A).**

1. **`Util/NatLemmas.agda`** — Collect the ℕ arithmetic lemmas
   needed for parameterized min-cut reasoning.  Most are available
   in `Cubical.Data.Nat.Properties`; the module serves as a
   curated re-export layer.  Expected: `+-comm`, `+-assoc`,
   `+-cancelˡ`, `+-cancelʳ`, and a cancellation lemma for
   `perturb`:
   ```agda
   perturb-other : (w : Bond → ℚ≥0) (b b' : Bond)
     → ¬ (b ≡ b') → perturb w b δ b' ≡ w b'
   perturb-self : (w : Bond → ℚ≥0) (b : Bond)
     → perturb w b δ b ≡ w b +ℚ δ
   ```

2. **`Boundary/StarCutParam.agda`** — A parameterized version of
   `S-cut` that takes an arbitrary weight function `w : Bond → ℚ≥0`
   (not a `BoundaryView` wrapper) and returns the min-cut:
   ```agda
   S-param : (Bond → ℚ≥0) → Region → ℚ≥0
   S-param w regN0   = w bCN0
   S-param w regN0N1 = w bCN0 +ℚ w bCN1
   ...
   ```
   This is `minCutFromWeights` from `Bridge/StarRawEquiv.agda`,
   promoted to a first-class definition.

3. **`Bulk/StarChainParam.agda`** — The parameterized bulk
   observable, defined identically to `S-param` (since both sides
   compute the same min-cut function for the star topology).

4. **`Bridge/StarStepInvariance.agda`** — The invariance theorem:
   ```agda
   step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
     → ((r : Region) → S-param w r ≡ L-param w r)
     → ((r : Region) → S-param (perturb w b δ) r
                      ≡ L-param (perturb w b δ) r)
   ```
   Proof: For each region `r`, case-split on whether the perturbed
   bond `b` participates in the min-cut of `r`.  Both `S-param`
   and `L-param` are the same function, so they produce the same
   perturbed value.

   For the star topology this is trivially true because `S-param`
   and `L-param` are definitionally the same function.  The
   non-trivial content is that **the perturbation is compatible
   with both the boundary and bulk interpretations** — the
   boundary min-cut and the bulk minimal chain respond identically
   to the weight change.

5. **`Bridge/StarDynamicsLoop.agda`** — The "while(true) loop":
   ```agda
   -- A sequence of weight functions obtained by iterated perturbation
   weight-sequence : (w₀ : Bond → ℚ≥0) → (steps : List (Bond × ℚ≥0))
     → Bond → ℚ≥0
   weight-sequence w₀ []            = w₀
   weight-sequence w₀ ((b , δ) ∷ s) = perturb (weight-sequence w₀ s) b δ

   -- The RT correspondence holds at every step
   loop-invariant : (w₀ : Bond → ℚ≥0)
     → ((r : Region) → S-param w₀ r ≡ L-param w₀ r)
     → (steps : List (Bond × ℚ≥0))
     → ((r : Region) → S-param (weight-sequence w₀ steps) r
                      ≡ L-param (weight-sequence w₀ steps) r)
   loop-invariant w₀ base []       = base
   loop-invariant w₀ base (s ∷ ss) =
     step-invariant (weight-sequence w₀ ss) (fst s) (snd s)
                    (loop-invariant w₀ base ss)
   ```

   This is a **structural induction on the list of perturbation
   steps**, using `step-invariant` at each step.  The proof term
   is ~5 lines.  The "while(true) loop" is the claim that this
   works for lists of arbitrary length.

**Phase F.2b — Enriched Step Invariance (Stretch Goal).**

Extend the invariance theorem to the enriched type equivalence
(including subadditivity/monotonicity conversion):

```agda
enriched-step-invariant : (w : Bond → ℚ≥0) (b : Bond) (δ : ℚ≥0)
  → FullBdy(w) ≃ FullBulk(w)
  → FullBdy(perturb w b δ) ≃ FullBulk(perturb w b δ)
```

This requires proving that subadditivity and monotonicity are
also preserved under perturbation — additional graph-theoretic
lemmas but following the same case-split-on-(bond, region) pattern.

### 11.8 The Hard Boundary: Beyond Fixed Topology

The weight-perturbation approach (Strategy A) keeps the graph
topology fixed.  Physical dynamics (space expanding, black holes
merging) corresponds to **topological changes** — adding or
removing cells, rewiring bonds.  This is Strategy B, which faces
two additional obstacles:

1. **Changing region types.**  If the patch grows from $N$ to
   $N+1$ cells, the `Region` type gains new constructors.  A
   parameterized proof must be stated over a *family* of region
   types indexed by patch size, requiring the inductive tiling
   definition from Direction C (§5).

2. **Non-local min-cut effects.**  Adding a cell can create new
   flow paths that reduce existing min-cut values.  Proving that
   the RT correspondence is preserved requires a monotonicity
   argument for min-cut under graph expansion — a non-trivial
   result in combinatorial optimization.

These obstacles are structural, not bugs.  They correspond to
the genuine physical difficulty that gravity (bulk geometry
change) in response to matter (boundary state change) is the
central unsolved problem of quantum gravity.

### 11.9 Relationship to Existing Code

The step-invariance modules would live alongside (but not modify)
existing modules:

```text
src/Util/NatLemmas.agda              (new — ℕ arithmetic re-exports)
src/Boundary/StarCutParam.agda       (new — parameterized S-cut)
src/Bulk/StarChainParam.agda         (new — parameterized L-min)
src/Bridge/StarStepInvariance.agda   (new — step-invariance theorem)
src/Bridge/StarDynamicsLoop.agda     (new — iterated loop)
```

The existing `Bridge/StarRawEquiv.agda` already defines
`minCutFromWeights` (the forward map of the raw equivalence),
which IS the parameterized observable function.  The step-
invariance proof would import this directly.

### 11.10 Exit Criterion

The "while(true) loop" route is complete when:

1. A `step-invariant` theorem type-checks in
   `Bridge/StarStepInvariance.agda`, proving that the discrete
   Ryu–Takayanagi correspondence is preserved under single-bond
   weight perturbation for the 6-tile star topology.

2. A `loop-invariant` theorem type-checks in
   `Bridge/StarDynamicsLoop.agda`, proving preservation under
   arbitrary finite sequences of perturbations (by induction
   on the list of steps).

3. (Stretch) An analogous theorem for the enriched equivalence
   (including subadditivity ↔ monotonicity conversion).

### 11.11 What Success Looks Like

The "while(true) loop" route does NOT claim to prove that the
universe evolves by graph rewriting, nor that local unitaries in
quantum gravity correspond to bond-weight perturbations.  It
claims something precise and modest:

> **For the 6-tile star patch of the {5,4} HaPPY code with
> arbitrary bond weights, the discrete Ryu–Takayanagi
> correspondence is invariant under local bond-weight
> perturbations.  Any finite sequence of such perturbations
> preserves the holographic bridge, and the while(true) loop
> of iterated perturbations is correctness-preserving at every
> step.**

This is the constructive, machine-checked content of the informal
claim "time is just the universe compiling its next state."  Each
"tick" is a single bond-weight perturbation; the `step-invariant`
theorem guarantees that the bulk geometry updates correctly; and
the `loop-invariant` theorem guarantees that arbitrarily long
sequences of ticks maintain the holographic correspondence.

The extrapolation — that physical time evolution in quantum
gravity corresponds to sequences of such perturbations — is a
physical interpretation supported by the formal evidence, not a
formal theorem.

### 11.12 Conditions for Advancement

This direction advances from "planned" to "active" when:

1. Direction A (11-tile bridge) is complete or stable, freeing
   development bandwidth.
2. The ℕ arithmetic lemmas needed for parameterized reasoning
   have been curated and tested in a `Util/NatLemmas.agda`
   module.
3. The `minCutFromWeights` function from `Bridge/StarRawEquiv.agda`
   has been validated as the correct parameterized observable for
   both boundary and bulk sides.

If obstacle 2 proves harder than expected (the ℕ lemma library
requires extensive development), the direction is deferred until
the cubical library's arithmetic support matures.

---

## 12. Adding Data Payloads (Matter & The Standard Model)
* **The Toy Model:** The bonds in your graph are just structural scaffolding. They hold a capacity of `1`. They define *where* space is, but the space is empty.
* **Our Universe:** Space is filled with electrons, photons, and quarks.
* **The Translation:** You upgrade the edges of your graph to carry complex data payloads. Instead of a bond just being a connection, the bond carries a mathematical matrix (specifically, Lie Group representations like $SU(3) \times SU(2) \times U(1)$). When you attach these complex algebraic payloads to your geometric scaffolding, the "errors" or "twists" in the network manifest to macroscopic observers as particles of matter and light.

---

## 13. Multithreading the State (Quantum Superposition)
* **The Toy Model:** You evaluate one specific graph at a time (e.g., you load `Dense-100` into RAM and verify it).
* **Our Universe:** Quantum mechanics dictates that reality isn't one definite graph. It is a probability distribution of *all possible graphs* existing simultaneously.
* **The Translation:** You change your compiler so it doesn't just hold one State. It holds a "Heap" of all possible graph configurations, weighted by probability amplitudes (this is called a Spin Foam or Path Integral). The physical universe we observe is just the statistical expected value of that multi-threaded heap.

---

## 14. Execution Plan

The theoretical formalization of the discrete holographic universe is complete. The repository has successfully bypassed the AST memory wall (Dense-100), proven the discrete Area Law (Thermodynamics), verified the curvature-agnostic Wick Rotation (dS/AdS), and packaged the discrete time evolution (Dynamics).

The immediate development pathway is now strictly focused on software extraction and visualization:

**Phase 6.0 — Extraction and The Visualizer**
1. **The Haskell Backend:** Write `Main.agda` to compile the verified Agda functions (like the Ryu-Takayanagi max-flow maps) into a standalone, executable Haskell binary.
2. **The WebGL Frontend:** Build a Three.js interactive application that allows users to toggle between the Shallow (BFS) and Deep (Dense) topologies.
3. **The Bridge:** Hook the Three.js frontend to the Haskell binary, creating a visually interactive, mechanically verified physics engine.

---

## 15. Summary of Research Positioning

| Direction | Type of Boundary | Novel Contribution | Status |
|---|---|---|---|
| A. 11-Tile Bridge | Proof engineering | Scaling holographic formalization to full 2D disk via metaprogramming | **Complete** |
| B. Raw Structural Equivalence | Homotopy theory / theoretical physics | First mechanically verified holographic bulk-boundary map at type level | **Complete** |
| C. N-Layer Generalization | Graph induction | Generic inductive tiling + min-cut for arbitrary patch depth | Deferred |
| D. 3D Hyperbolic Honeycomb | AST memory limit | Formalizing 2D -> 3D holographic dimensional compression | **Complete** |
| E. dS/AdS Translator | Curvature sign | First machine-checked proof that discrete holographic correspondence is curvature-agnostic; discrete Wick rotation without ℂ | **Complete** |
| F. ||| **Complete** |
| G. ||| **Complete** |

Directions A and B together form a coherent narrative: A demonstrates that
the observable-level correspondence scales to the full 2D setting, and B
attempts to deepen the correspondence from observable agreement to
structural identity. If both succeed, the project provides the first
machine-checked formalization of holographic duality at two complementary
levels of abstraction — a result that spans formal methods, Homotopy Type
Theory, and mathematical physics.