{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.DeSitterPatchComplex where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat  using (ℕ ; zero ; suc ; _+_ ; _·_)
open import Cubical.Data.Sigma using (_×_)

-- ════════════════════════════════════════════════════════════════════
--  6-Face Star Patch of the {5,3} Spherical Tiling (Dodecahedron)
-- ════════════════════════════════════════════════════════════════════
--
--  This module encodes the polygon complex for the 6-face star
--  patch of the {5,3} tiling (regular dodecahedron) as specified
--  in §7.4.3 of docs/10-frontier.md.  It is the primary curvature /
--  Gauss–Bonnet formalization target for the de Sitter (dS) side
--  of the discrete Wick rotation.
--
--  Patch composition:
--    • 1  central pentagon  C
--    • 5  edge-neighbour pentagons  N₀ .. N₄
--    • NO gap-filler pentagons  (the {5,3} condition: only 3
--      pentagons meet at each vertex, so the star patch already
--      saturates every interior vertex)
--
--  Polygon complex counts:
--    • Vertices:  15   (5 interior + 10 boundary)
--    • Edges:     20   (10 internal + 10 boundary)
--    • Faces:      6   (all regular pentagons)
--    • Euler:     χ = 15 − 20 + 6 = 1   (disk)
--
--  Every interior vertex v_i has valence 3 in the tiling graph,
--  matching the {5,3} Schläfli condition: 3 regular pentagons
--  meet at each interior vertex, contributing 3 × 108° = 324° of
--  angle — LESS than 360° by 36° = π/5.  This angular deficit is
--  the source of POSITIVE curvature (spherical geometry).
--
--  Comparison with the {5,4} patch (Bulk/PatchComplex.agda):
--
--    Property              {5,4} (AdS)    {5,3} (dS)
--    ─────────             ───────────    ──────────
--    Tiles                 11             6
--    Gap-fillers           5 (G₀..G₄)    0
--    Vertices              30             15
--    Edges                 40             20
--    Faces                 11             6
--    Vertex classes        5              3
--    Interior valence      4              3
--    Interior curvature    −1/5           +1/10
--    Euler characteristic  1              1
--
--  The encoding uses Strategy A from §13.2 of docs/09-happy-instance.md:
--  vertices are grouped into 3 classes, and combinatorial curvature
--  is constant within each class.
--
--  Numerical verification:
--    sim/prototyping/10_desitter_prototype.py
--    (§5–§8 of the output file)
--
--  Downstream modules:
--    src/Bulk/DeSitterCurvature.agda    — κ : DSVClass → ℚ₁₀
--    src/Bulk/DeSitterGaussBonnet.agda  — Σ κ(v) ≡ χ(K)
--    src/Bridge/WickRotation.agda       — coherence record
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  DSPatchFace — The 6 pentagonal tiles
-- ════════════════════════════════════════════════════════════════════
--
--  One constructor per tile.  Naming convention:
--    dsC   — central pentagon
--    dsNᵢ  — edge-neighbour sharing edge (vᵢ , vᵢ₊₁) with C
--
--  All tiles are regular pentagons (5 sides each).
--
--  Unlike the {5,4} patch, there are NO gap-filler tiles.
--  In {5,3}, only 3 pentagons meet at each vertex of C, and
--  the three faces C, N_{i−1}, N_i completely tile the
--  neighborhood of vertex v_i.  No angular gaps remain.
-- ════════════════════════════════════════════════════════════════════

data DSPatchFace : Type₀ where
  dsC  : DSPatchFace
  dsN₀ dsN₁ dsN₂ dsN₃ dsN₄ : DSPatchFace

-- Every face is a pentagon.
dsFaceSides : ℕ
dsFaceSides = 5


-- ════════════════════════════════════════════════════════════════════
--  §2.  DSVClass — Vertex classification (3 classes)
-- ════════════════════════════════════════════════════════════════════
--
--  The 15 vertices of the polygon complex fall into 3 classes,
--  determined by their combinatorial neighbourhood.  Within each
--  class, all vertices have identical edge degree, face valence,
--  and therefore identical combinatorial curvature.
--
--    Class      Vertices          Count   Int/Bdy   deg   faces   κ
--    ────────   ────────────────  ─────   ───────   ───   ─────   ────
--    dsTiling   v₀ .. v₄            5    interior    3     3     +1/10
--    dsSharedW  w₀ .. w₄            5    boundary    3     2     −1/10
--    dsOuterB   b₀ .. b₄            5    boundary    2     1      1/5
--
--  Naming:
--    dsTiling  = vertices of the central pentagon C
--                (shared by C, N_{i−1}, and N_i — exactly 3 faces)
--    dsSharedW = boundary vertices shared between adjacent N tiles;
--                w_i is shared by N_{i−1} and N_i at the third edge
--                emanating from v_i  (the one not on C)
--    dsOuterB  = boundary vertices belonging only to N_i
--                (the "far" vertex of each neighbour pentagon)
--
--  The curvature values listed above are derived from the
--  combinatorial formula
--      κ(v) = 1 − deg(v)/2 + Σ_{f ∋ v} 1/sides(f)
--  and are formalized in Bulk/DeSitterCurvature.agda.
--
--  KEY DIFFERENCE from AdS ({5,4}):
--    • Only 3 classes (not 5) — no gap-filler vertex classes
--    • Interior valence is 3 (not 4) → κ is POSITIVE (+1/10)
--    • The positive interior curvature reflects the spherical
--      (de Sitter) geometry of the {5,3} tiling
-- ════════════════════════════════════════════════════════════════════

data DSVClass : Type₀ where
  dsTiling  : DSVClass
  dsSharedW : DSVClass
  dsOuterB  : DSVClass

-- ────────────────────────────────────────────────────────────────
--  Number of vertices in each class
-- ────────────────────────────────────────────────────────────────

dsVCount : DSVClass → ℕ
dsVCount dsTiling  = 5
dsVCount dsSharedW = 5
dsVCount dsOuterB  = 5


-- ════════════════════════════════════════════════════════════════════
--  §3.  Combinatorial incidence data per vertex class
-- ════════════════════════════════════════════════════════════════════
--
--  These functions record the edge degree and face valence at each
--  vertex class.  They are the inputs to the combinatorial curvature
--  formula  κ(v) = 1 − deg(v)/2 + faceValence(v)/sides.
--
--  Edge degree = number of edges incident to the vertex:
--    dsTiling:   3  (two C-edges: (v_{i-1},v_i) and (v_i,v_{i+1}),
--                    plus one N-N shared edge: (v_i,w_i))
--    dsSharedW:  3  (one N_{i-1}/N_i shared edge: (v_i,w_i),
--                    plus two boundary edges: (w_i,b_{i-1}) and (w_i,b_i)
--                    ... actually (b_{i-1},w_i) and (b_i,w_i))
--    dsOuterB:   2  (two boundary edges: (w_i,b_i) and (b_i,w_{i+1}))
--
--  Face valence = number of pentagonal faces meeting at the vertex:
--    dsTiling:   3  (C, N_{i-1}, N_i)
--    dsSharedW:  2  (N_{i-1}, N_i)
--    dsOuterB:   1  (N_i only)
--
--  Verified by sim/prototyping/10_desitter_prototype.py:
--    interior (v_i): deg=3, faces=3
--    boundary-shared (w_i): deg=3, faces=2
--    boundary-outer (b_i): deg=2, faces=1
-- ════════════════════════════════════════════════════════════════════

dsEdgeDeg : DSVClass → ℕ
dsEdgeDeg dsTiling  = 3
dsEdgeDeg dsSharedW = 3
dsEdgeDeg dsOuterB  = 2

dsFaceValence : DSVClass → ℕ
dsFaceValence dsTiling  = 3
dsFaceValence dsSharedW = 2
dsFaceValence dsOuterB  = 1


-- ════════════════════════════════════════════════════════════════════
--  §4.  DSVertex — The 15 vertices of the polygon complex
-- ════════════════════════════════════════════════════════════════════
--
--  Explicit enumeration of all 15 vertices, grouped by class.
--  This allows the face-vertex incidence map (§5) to be stated
--  in terms of concrete vertex names.
--
--  Naming conventions follow the Python prototype
--  (sim/prototyping/10_desitter_prototype.py):
--
--    vᵢ   — tiling vertex i of the central pentagon C
--             (also shared by N_{i−1} and N_i)
--    wᵢ   — boundary vertex shared between N_{i−1} and N_i
--             (connected to v_i by the N-N shared edge)
--    bᵢ   — outer vertex of N_i (not shared with any other tile)
-- ════════════════════════════════════════════════════════════════════

data DSVertex : Type₀ where
  -- Tiling vertices  (interior,  5 vertices,  class dsTiling)
  dsv₀ dsv₁ dsv₂ dsv₃ dsv₄ : DSVertex

  -- Shared-W vertices  (boundary,  5 vertices,  class dsSharedW)
  dsw₀ dsw₁ dsw₂ dsw₃ dsw₄ : DSVertex

  -- Outer-B vertices  (boundary,  5 vertices,  class dsOuterB)
  dsb₀ dsb₁ dsb₂ dsb₃ dsb₄ : DSVertex


-- ────────────────────────────────────────────────────────────────
--  dsClassify — Map each vertex to its class
-- ────────────────────────────────────────────────────────────────

dsClassify : DSVertex → DSVClass
dsClassify dsv₀ = dsTiling
dsClassify dsv₁ = dsTiling
dsClassify dsv₂ = dsTiling
dsClassify dsv₃ = dsTiling
dsClassify dsv₄ = dsTiling
dsClassify dsw₀ = dsSharedW
dsClassify dsw₁ = dsSharedW
dsClassify dsw₂ = dsSharedW
dsClassify dsw₃ = dsSharedW
dsClassify dsw₄ = dsSharedW
dsClassify dsb₀ = dsOuterB
dsClassify dsb₁ = dsOuterB
dsClassify dsb₂ = dsOuterB
dsClassify dsb₃ = dsOuterB
dsClassify dsb₄ = dsOuterB


-- ════════════════════════════════════════════════════════════════════
--  §5.  Face-vertex incidence
-- ════════════════════════════════════════════════════════════════════
--
--  Each pentagonal face is specified by an ordered 5-tuple of its
--  vertices in cyclic order.  Consecutive vertices in the tuple
--  share an edge of the polygon complex.
--
--  The orderings follow the Python prototype exactly
--  (build_dodecahedron_faces in 10_desitter_prototype.py):
--
--    C:   (v₀, v₁, v₂, v₃, v₄)
--    Nᵢ:  (vᵢ, vᵢ₊₁, wᵢ₊₁, bᵢ, wᵢ)        where i+1 is mod 5
--
--  Shared edges (internal edges of the complex):
--    C  ∩ Nᵢ:       edge (vᵢ , vᵢ₊₁)           5 edges
--    Nᵢ₋₁ ∩ Nᵢ:    edge (vᵢ , wᵢ)              5 edges
--                                          total: 10 internal edges
--
--  The remaining 10 edges are boundary edges (each in exactly one face):
--    Nᵢ:  edges (vᵢ₊₁, wᵢ₊₁), ... wait, actually:
--    Nᵢ has edges: (vᵢ,vᵢ₊₁) shared with C
--                  (vᵢ₊₁,wᵢ₊₁) — shared with Nᵢ₊₁ via wᵢ₊₁ and vᵢ₊₁
--
--  Correction: the shared edges between N tiles are:
--    N_{i-1} ∩ N_i:  edge (v_i, w_i)
--  And the boundary edges of N_i are:
--    (w_{i+1}, b_i)  and  (b_i, w_i)
--  giving 2 boundary edges per N tile, 10 total.
-- ════════════════════════════════════════════════════════════════════

DSPentagon : Type₀
DSPentagon = DSVertex × DSVertex × DSVertex × DSVertex × DSVertex

dsFaceVertices : DSPatchFace → DSPentagon
-- Central pentagon
dsFaceVertices dsC  = dsv₀ , dsv₁ , dsv₂ , dsv₃ , dsv₄
-- Edge-neighbours: Nᵢ shares edge (vᵢ, vᵢ₊₁) with C
dsFaceVertices dsN₀ = dsv₀ , dsv₁ , dsw₁ , dsb₀ , dsw₀
dsFaceVertices dsN₁ = dsv₁ , dsv₂ , dsw₂ , dsb₁ , dsw₁
dsFaceVertices dsN₂ = dsv₂ , dsv₃ , dsw₃ , dsb₂ , dsw₂
dsFaceVertices dsN₃ = dsv₃ , dsv₄ , dsw₄ , dsb₃ , dsw₃
dsFaceVertices dsN₄ = dsv₄ , dsv₀ , dsw₀ , dsb₄ , dsw₄


-- ════════════════════════════════════════════════════════════════════
--  §6.  Global topological counts
-- ════════════════════════════════════════════════════════════════════
--
--  These are the V, E, F counts of the polygon complex, together
--  with the interior/boundary vertex split.
--
--    dsTotalV = 15     (5 interior + 10 boundary)
--    dsTotalE = 20     (10 internal + 10 boundary)
--    dsTotalF = 6      (all pentagons)
--
--  The Euler characteristic is χ = V − E + F = 15 − 20 + 6 = 1.
--  Since we work with ℕ (no subtraction), we state this as the
--  additive identity  V + F = E + χ,  i.e.  15 + 6 = 20 + 1 = 21.
-- ════════════════════════════════════════════════════════════════════

dsTotalV : ℕ
dsTotalV = 15

dsTotalE : ℕ
dsTotalE = 20

dsTotalF : ℕ
dsTotalF = 6

dsInteriorV : ℕ
dsInteriorV = 5

dsBoundaryV : ℕ
dsBoundaryV = 10

dsInternalE : ℕ
dsInternalE = 10

dsBoundaryE : ℕ
dsBoundaryE = 10


-- ════════════════════════════════════════════════════════════════════
--  §7.  Topological verification proofs
-- ════════════════════════════════════════════════════════════════════
--
--  All proofs in this section hold by refl because both sides of
--  each identity normalize to the same ℕ term under the judgmental
--  computation rules for _+_ and _·_.
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Euler characteristic:  V + F = E + χ  where χ = 1
--  15 + 6 = 21 = 20 + 1
-- ────────────────────────────────────────────────────────────────

ds-euler-char : dsTotalV + dsTotalF ≡ dsTotalE + 1
ds-euler-char = refl

-- ────────────────────────────────────────────────────────────────
--  Vertex count decomposes into the 3 vertex classes:
--  5 + 5 + 5 = 15
-- ────────────────────────────────────────────────────────────────

ds-count-decomp :
    dsVCount dsTiling
  + dsVCount dsSharedW
  + dsVCount dsOuterB
  ≡ dsTotalV
ds-count-decomp = refl

-- ────────────────────────────────────────────────────────────────
--  Interior / boundary vertex split:  5 + 10 = 15
-- ────────────────────────────────────────────────────────────────

ds-count-split : dsInteriorV + dsBoundaryV ≡ dsTotalV
ds-count-split = refl

-- ────────────────────────────────────────────────────────────────
--  Interior vertex count = tiling vertex count
-- ────────────────────────────────────────────────────────────────

ds-interiorV≡dsTiling : dsInteriorV ≡ dsVCount dsTiling
ds-interiorV≡dsTiling = refl

-- ────────────────────────────────────────────────────────────────
--  Edge count decomposes:  10 internal + 10 boundary = 20
-- ────────────────────────────────────────────────────────────────

ds-edge-decomp : dsInternalE + dsBoundaryE ≡ dsTotalE
ds-edge-decomp = refl

-- ────────────────────────────────────────────────────────────────
--  Handshaking lemma:  Σ_{class} (count · edgeDeg) = 2 · totalE
--
--    5·3 + 5·3 + 5·2
--  = 15  + 15  + 10
--  = 40
--  = 2 · 20
-- ────────────────────────────────────────────────────────────────

ds-handshaking :
    dsVCount dsTiling  · dsEdgeDeg dsTiling
  + dsVCount dsSharedW · dsEdgeDeg dsSharedW
  + dsVCount dsOuterB  · dsEdgeDeg dsOuterB
  ≡ 2 · dsTotalE
ds-handshaking = refl

-- ────────────────────────────────────────────────────────────────
--  Face-incidence identity:
--    Σ_{class} (count · faceValence) = totalF · faceSides
--
--    5·3 + 5·2 + 5·1
--  = 15  + 10  + 5
--  = 30
--  = 6 · 5
--
--  This counts the total number of vertex-face incidence pairs.
--  Each face contributes  faceSides = 5  incidences, so the total
--  is  6 · 5 = 30.  Each vertex v contributes faceValence(v)
--  incidences.  The identity confirms consistency of the
--  faceValence function with the face count.
-- ────────────────────────────────────────────────────────────────

ds-face-incidence :
    dsVCount dsTiling  · dsFaceValence dsTiling
  + dsVCount dsSharedW · dsFaceValence dsSharedW
  + dsVCount dsOuterB  · dsFaceValence dsOuterB
  ≡ dsTotalF · dsFaceSides
ds-face-incidence = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Boundary structure
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary of the disk patch is a cycle of 10 vertices and
--  10 edges.  The boundary groups in cyclic order (reading from
--  the restricted star-topology perspective) are:
--
--    N₀(2 bdy edges), N₁(2), N₂(2), N₃(2), N₄(2)
--
--  Each Nᵢ contributes 2 boundary edges:
--    (wᵢ₊₁, bᵢ)  and  (bᵢ, wᵢ)
--
--  Total boundary edges: 5 × 2 = 10.
--
--  Note: in the RESTRICTED star topology used by the bridge
--  modules (Common/StarSpec.agda), each N tile has 4 boundary
--  legs (as if the N–N shared edges did not exist).  The
--  holographic correspondence operates on the flow graph, not
--  on the polygon complex, so the boundary-edge count of the
--  polygon complex (10) differs from the boundary-leg count of
--  the flow graph (20).  Both are correct in their respective
--  contexts.
-- ════════════════════════════════════════════════════════════════════

dsBoundaryEdgesPerN : ℕ
dsBoundaryEdgesPerN = 2

-- Total boundary edges: 5·2 = 10
ds-boundary-edges-check : 5 · dsBoundaryEdgesPerN ≡ dsBoundaryE
ds-boundary-edges-check = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Comparison with AdS ({5,4}) patch
-- ════════════════════════════════════════════════════════════════════
--
--  The {5,3} star patch differs from the {5,4} filled patch
--  (Bulk/PatchComplex.agda) in the following ways:
--
--    1.  No gap-filler tiles:  the 3 faces meeting at each
--        interior vertex leave no angular gaps.  The {5,4}
--        patch needs 5 gap-fillers (G₀..G₄) because 4 pentagons
--        don't tile around a vertex without them.
--
--    2.  Fewer vertex classes:  3 classes instead of 5.
--        The vSharedA, vSharedC, and vOuterG classes from
--        PatchComplex.agda have no analogues here because
--        there are no gap-filler tiles to share vertices with.
--
--    3.  Positive interior curvature:  κ(v_i) = +1/10 instead
--        of −1/5.  At each interior vertex, 3 pentagons contribute
--        3 × 108° = 324° < 360°, giving a positive angular
--        deficit of +36° = π/5.  (Compare: in {5,4}, 4 pentagons
--        give 432° > 360°, yielding a negative deficit of −72°.)
--
--    4.  The flow graph is IDENTICAL:  both patches have the same
--        5-bond star topology (C connected to N₀..N₄ with uniform
--        weight 1), and the same 10 representative regions with
--        the same min-cut values S(k) = min(k, 5−k).  The bridge
--        equivalence (Common/StarSpec.agda, Bridge/StarEquiv.agda,
--        Bridge/EnrichedStarEquiv.agda) is literally reused.
--
--  This module provides the geometric substrate for the dS
--  curvature theorem.  The bridge is imported unchanged from the
--  existing modules, confirming that the holographic correspondence
--  is curvature-agnostic.
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §10.  Design notes and downstream interface
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for Bulk/DeSitterCurvature.agda:
--
--    DSVClass, dsVCount        — vertex classification and class sizes
--    dsEdgeDeg, dsFaceValence  — combinatorial neighbourhood data
--    dsFaceSides               — all faces are pentagons (= 5)
--    dsClassify                — DSVertex → DSVClass
--
--  Exports for Bulk/DeSitterGaussBonnet.agda:
--
--    dsVCount                  — weights in the classified GB sum
--    dsTotalV, dsTotalE, dsTotalF — for stating χ = V − E + F
--    ds-euler-char             — the Euler identity  V + F = E + 1
--    ds-count-decomp           — vertex count = sum of class counts
--
--  Exports for face-level reasoning:
--
--    DSPatchFace               — the 6 faces
--    DSVertex, DSPentagon      — vertices and 5-tuple type
--    dsFaceVertices            — face-vertex incidence map
--
--  Exports for Bridge/WickRotation.agda:
--
--    All of the above, packaged as the dS-side geometric data.
--    The WickRotation record will import both this module and
--    Bulk/PatchComplex.agda (the AdS side), along with the
--    shared bridge from Bridge/EnrichedStarEquiv.agda.
-- ════════════════════════════════════════════════════════════════════