# Theoretical Foundations

## 1. Homotopy Type Theory in 90 Seconds

**Primary reference.** HoTT Book, Chapters 1–2 ([see §7](07-references.md)).
**For implementation details.** Cubical Agda examples in the `cubical` library ([see §4](04-tooling.md)).

In HoTT, a type admits several compatible readings. Via Curry–Howard, terms of
proposition-like types are proofs; at h-level 2 a type behaves like a set of
elements; and in the homotopical semantics every type behaves like a space or
\(\infty\)-groupoid. Not every type is literally all of these at once in the
same sense; rather, the truncation level tells us which interpretation is
appropriate. The identity type \(a =_A b\) is not a boolean; it is itself a
type, whose inhabitants are *paths* from \(a\) to \(b\) in the space \(A\).
Paths between paths are homotopies. This stratified structure — points, paths,
paths-between-paths, and so on — gives every type a natural *homotopy level*
(also called truncation level). A type is a "set" (h-level 2) when all its
path spaces are propositional; it is a "groupoid" (h-level 3) when path
spaces are themselves sets; and so on.

The critical operation is **transport**. Given a type family \(P : A \to
\mathcal{U}\) and a path \(p : a =_A b\), transport produces a function
\(\mathrm{transport}^P(p) : P(a) \to P(b)\). This is HoTT's version of
"moving data along an equality," and it is the mechanism by which a proof of
equivalence between two structures becomes a *function* that converts
inhabitants (data) of one structure into inhabitants of the other.

## 2. The Univalence Axiom — Precise Statement

**Primary reference.** HoTT Book, Chapter 4; Cohen–Coquand–Huber–Mörtberg (2018) for computational interpretation ([see §7](07-references.md)).

For a universe \(\mathcal{U}\), the canonical map

\[
  \mathrm{idtoeqv} : (A =_{\mathcal{U}} B) \to (A \simeq B)
\]

sends a path between types to the equivalence obtained by transporting along
that path. The **Univalence Axiom** asserts that \(\mathrm{idtoeqv}\) is
itself an equivalence:

\[
  \mathrm{ua} : (A \simeq B) \simeq (A =_{\mathcal{U}} B)
\]

In words: to give a path (identity) between two types in the universe is
exactly to give an equivalence between them. This is far stronger than
classical isomorphism. In set-theoretic foundations, two isomorphic sets remain
distinct objects; manually "respect the isomorphism" everywhere is a must. Under
Univalence, once the equivalence is exhibited, *every* property, construction,
and theorem about \(A\) automatically transfers to \(B\) — by transport.

**Important caveat for this project.** Univalence does not assert that any two
vaguely related structures are identical. It asserts that *equivalent types in
the same universe* are identical. The hard work is constructing the
equivalence: exhibiting a map \(f : A \to B\), a map \(g : B \to A\), and
coherent homotopies showing \(g \circ f \sim \mathrm{id}_A\) and \(f \circ g
\sim \mathrm{id}_B\). For physically motivated types, this is where 99% of
the effort lives.

## 3. AdS/CFT, Holography, and Ryu–Takayanagi

**Core physics references.**
- Maldacena (1997) — AdS/CFT
- Ryu–Takayanagi (2006) — entropy/area relation
- Pastawski et al. (2015) — HaPPY code (toy model used in Phase 1)
([full citations in §7](07-references.md))

The AdS/CFT correspondence posits an exact duality between a
\((d{+}1)\)-dimensional theory of quantum gravity in Anti-de Sitter space and a
\(d\)-dimensional conformal field theory on its asymptotic boundary. The
bulk geometry is *emergent* from boundary entanglement. Three key results
sharpen this picture into something approachable by formalization.

**Ryu–Takayanagi (RT) formula.** For a boundary region \(\mathcal{R}\), the
entanglement entropy \(S(\mathcal{R})\) of the corresponding reduced state
equals \(\frac{\mathrm{Area}(\gamma_{\mathcal{R}})}{4 G_N}\), where
\(\gamma_{\mathcal{R}}\) is the minimal-area bulk surface homologous to
\(\mathcal{R}\). This is the single sharpest equation linking entanglement to
geometry, and it is the primary formalization target for Phase 3 of this
project.

For the 2D discrete toy models used later, the bulk-side quantity is a
minimal geodesic length rather than a higher-dimensional area. The RT area
formula is the general statement; the length functional is its 2D analogue.

**MERA tensor networks.** The Multi-scale Entanglement Renormalization Ansatz
is a specific tensor network architecture whose causal structure reproduces the
geometry of a discrete slice of AdS space. 
The MERA network is a concrete (see Vidal 2007; Swingle 2012 in [§7](07-references.md)), 
finite, combinatorial object, making it an ideal candidate for Type A.

**ER = EPR (Maldacena & Susskind, 2013).** The conjecture that Einstein–Rosen
bridges (wormholes) are equivalent to Einstein–Podolsky–Rosen pairs
(entanglement) suggests that even individual entanglement links have geometric
content.

## 4. Cohesive HoTT and Synthetic Differential Geometry — Future Conceptual Horizon

**Status: conceptual guidance only.**
Cohesive HoTT is not on the critical path for any v1 milestone. It is
documented here because it informs the project's long-term architectural
vision, but no implementation work targets it in the initial phases.

**Primary references.**
- Urs Schreiber's cohesive HoTT notes (nLab, [see §7](07-references.md))
- Shulman (2018) for formal examples
**Caution.** Cohesive HoTT is not yet standard in proof assistants; treat as
conceptual guidance unless explicitly implemented.

Formalizing smooth manifolds inside ordinary HoTT is painful; the usual
approach encodes topological and differentiable structure via atlas-and-chart
machinery, which is workable but verbose. A more natural path is **cohesive
HoTT**, developed primarily by Urs Schreiber. Cohesive HoTT extends HoTT with
modalities — an adjoint string relating discrete, continuous, and smooth
structure directly at the type-theoretic level. The three key modalities are:

The **flat modality** \(\flat A\) (pronounced "flat") extracts the underlying
discrete type of \(A\), forgetting all cohesion. The **sharp modality**
\(\sharp A\) produces the codiscrete type where every function into \(A\) is
continuous. The **shape modality** \(\Pi_\infty A\) (also written \(\int A\))
produces the fundamental \(\infty\)-groupoid of \(A\), capturing its homotopy
type while forgetting point-set details.

Within cohesive HoTT, one can define differential forms, connections, and
curvature synthetically — as structure on types — rather than analytically via
coordinate patches. This would be directly relevant to formalizing smooth bulk
geometry, because it allows one to speak about Riemannian curvature without
first building the entire classical tower of point-set topology, smooth
atlases, and Christoffel symbols.

**Synthetic Differential Geometry (SDG)** is a related but distinct framework,
originating with Lawvere and developed by Kock, in which infinitesimals exist
as first-class objects (nilpotent elements of a ring). SDG can be modeled
inside certain topoi, and there is active work connecting it to cohesive HoTT.
For this project, SDG provides useful intuition: the tangent vector at a point
is literally a map from an "infinitesimal interval" into the space, rather than
an equivalence class of curves.

**Why this is deferred.** The v1 project works entirely with finite
combinatorial objects: graphs, simplicial complexes, and rational-valued
weights. These live naturally in ordinary Cubical Agda without cohesive
modalities. Cohesive HoTT becomes relevant only if and when the project
attempts to formalize smooth structure or take continuum limits — both of
which are explicit non-goals for v1.