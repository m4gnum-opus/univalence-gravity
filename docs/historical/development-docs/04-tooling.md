# Technical Stack & Tooling

**Practical entry points.**
- Cubical Agda repository: <https://github.com/agda/cubical>
- HoTT Book: <https://homotopytypetheory.org/book/>
- Example files: `Cubical.Foundations.*`
These are effectively part of the “documentation.”

## Primary Recommendation: Cubical Agda

For a project whose core mechanism is the Univalence Axiom, the proof assistant
must support Univalence *computationally*, not merely as a postulated axiom.
**Cubical Agda** is the strongest choice here. It implements cubical type
theory (CCHM, Cohen–Coquand–Huber–Mörtberg, 2018), in which Univalence is a
theorem, not an axiom, and transport along Univalence paths *computes* — it
reduces to concrete functions rather than getting stuck on an opaque postulate.
This is essential for Phase 4 (simulation), because we want to actually
*run* the extracted transport mechanism, not just verify that it type-checks.

Key resources for Cubical Agda are the `cubical` library itself — especially
modules under `Cubical.Foundations.*` — together with `agda-unimath` for
broader univalent mathematics in Agda.

**Recommendation.**
Treat the `cubical` library as *primary documentation*, not just a dependency:
many of the best worked examples of `ua`, `Glue`, higher inductive types, and
transport live there rather than in prose tutorials.

## Secondary Option: Lean 4 + Mathlib

Lean 4 with **mathlib** has by far the most extensive library of formalized
classical mathematics: topology, manifold theory, measure theory, functional
analysis, and so on. This makes it attractive for the bulk-geometry side (Type
B). However, Lean 4 does *not* natively support HoTT or Univalence. Its type
theory (the Calculus of Inductive Constructions with quotient types and
propositional extensionality) is fundamentally set-level. Using Lean would
mean either axiomatizing Univalence (losing computational content) or treating
the project in a classical, non-HoTT style and replacing Univalence with
explicit equivalence-transport lemmas. This is viable for partial goals
(formalizing RT as a classical theorem, for instance) but does not achieve the
project's core vision.

## Tertiary Option: Coq + HoTT Library

The Coq-HoTT library is mature and well-maintained, and Coq has a large
ecosystem. However, as in Lean, Univalence in Coq-HoTT is an axiom, not a
computational rule; transport along `ua` does not reduce. Additionally, Coq's
universe handling is less ergonomic than Agda's for the kind of universe
polymorphism this project requires. Coq-HoTT is a reasonable fallback if
Cubical Agda's ecosystem proves too thin for the manifold-geometry side.

## Supporting Tools

For **tensor network computation and prototyping**, 

**Suggested starting points.**
- ITensor tutorials (Julia)
- TensorNetwork (Python) examples for MERA constructions

ITensor (Julia) and Google's TensorNetwork library (Python) are suitable for experimenting with
MERA structures before formalizing them. For **visualization and simulation**
in Phase 4, Three.js (browser-based 3D rendering) or Python with
Manim (3Blue1Brown's animation library) can render the discrete-to-continuous
compilation. For **mathematical prototyping and calculation**, SageMath provides
excellent support for differential geometry, graph theory, and symbolic
computation, useful for generating conjectures to then formalize. For
**literature management**, a `references.bib` file maintained alongside the
proof code is essential; this project sits at the intersection of at least four
active research areas.

## Geometry-First Discovery Layer

The discovery subsystem adds an important constraint to the tooling story:
**Three.js is a front-end, not the source of truth**. The source of truth is a
canonical machine-readable scene description shared across the visualizer,
prototype notebooks, and proof-oriented code.

That shared representation should encode, at minimum:

- a boundary graph or bulk simplicial complex,
- incidence relations,
- weights / lengths,
- optional embedding coordinates,
- selected boundary regions,
- derived invariants cached for inspection.

The practical pipeline is:

1. **Edit structured geometry** in the browser or notebook.
2. **Recompute invariants** in real time.
3. **Compare against a local corpus** of known structures.
4. **Use AI to summarize the nearest mathematical matches**.
5. **Export promising candidates** as structured conjecture records (format
   defined in [§3.6](03-architecture.md#7-geometry-first-discovery-engine-non-critical-path)) 
   into the proof-oriented pipeline.

This makes the visualizer a genuine research instrument rather than a mere demo.
It also prevents a common conceptual mistake: the project is not trying to
"extract math from graphics," but to **make graphics one interface to formal
objects**.

## Ex Ante Project Structure

```
univalence-gravity/
├── README.md
├── docs/
│   ├── 00-abstract.md
│   ├── 01-introduction.md
│   ├── 02-foundations.md
│   ├── ...
│   └── 07-references.md
├── src/
│   ├── Common/
│   │   ├── Spec.agda              -- common source specification type C
│   │   └── ObsPackage.agda        -- observable package record types
│   ├── Boundary/
│   │   ├── Graph.agda             -- finite graph record / incidence structure
│   │   ├── Entanglement.agda      -- weighted edges
│   │   └── CutEntropy.agda        -- min-cut entropy functional
│   ├── Bulk/
│   │   ├── Complex.agda           -- finite bulk simplicial complex
│   │   ├── Curvature.agda         -- combinatorial curvature (Option A)
│   │   └── ChainLength.agda       -- minimal admissible chain length
│   ├── Invariants/
│   │   ├── Signature.agda         -- common invariant records
│   │   ├── Spectrum.agda          -- Laplacian / spectral invariants
│   │   └── CurvatureSummary.agda  -- discrete curvature summaries
│   ├── Bridge/
│   │   ├── Extraction.agda        -- π_∂ and π_bulk from C
│   │   ├── Equivalence.agda       -- exact equivalence on chosen packages
│   │   └── Transport.agda         -- ua application + transport
│   └── Util/
│       ├── Scalars.agda           -- constructive reals or rationals
│       └── LinearAlgebra.agda     -- vectors, matrices, spectral ops
├── sim/
│   ├── visualizer/                -- Three.js rendering + interaction
│   ├── validator/                 -- realtime invariant extraction
│   ├── matcher/                   -- corpus comparison + AI summaries
│   ├── corpus/                    -- reference structures + signatures
│   ├── exchange/                  -- shared scene/state schemas + conjecture record format
│   └── prototyping/               -- Python / Julia / Sage notebooks
├── references.bib
└── Makefile
```