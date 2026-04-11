## First Model Assumptions

Before defining the individual types, the project freezes the following
assumptions for the first concrete model. 
These can be revised at [Gate Review 1 (§5)](05-roadmap.md),
but they must be **fixed before Phase 2 begins**.

**First model assumptions:**

The toy model is the **HaPPY code** (Pastawski et al. 2015, [§7](07-references.md)),
abstracted to its combinatorial and graph-theoretic content. Specifically:

1. The boundary graph is **undirected**, **simple** (no multiedges, no
   self-loops), and **finite**. Boundary sites are drawn from a finite type
   \(\mathrm{Fin}(N)\) for a fixed \(N\) determined in Phase 1.
2. Boundary regions are **contiguous intervals** of the cyclic boundary
   ordering, not arbitrary subsets. This matches the standard RT setting and
   dramatically reduces the space of regions to consider.
3. Edge weights are **nonnegative rationals** \(\mathbb{Q}_{\geq 0}\).
   Dyadics or abstract ordered semiring elements may be introduced later but
   are not the default.
4. The bulk carrier is a **finite 2-dimensional simplicial complex** obtained
   from the \(\{5,4\}\) pentagonal tiling via a canonical triangulation
   convention (barycentric subdivision or chosen diagonalization) fixed once in
   Phase 1.
5. The first-pass bulk curvature notion is **purely combinatorial**: vertex
   degree deficits from the expected regular degree, or angle deficits treated
   as symbolic data attached to vertices, rather than metric quantities
   derived from real-valued edge lengths via trigonometry. Full Regge-style
   metric curvature (involving law-of-cosines angle computation) is a Phase 2B
   stretch goal, not the default.
6. Bulk "minimal geodesic length" is operationally **minimal admissible chain
   length on the 1-skeleton**: the sum of edge weights along a shortest path
   or cut in the dual graph separating two boundary regions. This is not a
   smooth geodesic; it is a discrete combinatorial proxy.
7. Laplacian spectra are **deferred** from the first formal target. They are
   computed during prototyping (Phase 1) to check discriminating power, but
   formalization of spectral operations is not required for Milestones 1–4.
8. The cut-entropy functional acts as an exact proxy for quantum entanglement 
   entropy under **perfect-tensor assumptions** (as in the HaPPY code).