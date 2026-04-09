{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.PatchComplex where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat  using (ℕ ; zero ; suc ; _+_ ; _·_)
open import Cubical.Data.Sigma using (_×_)

-- ════════════════════════════════════════════════════════════════════
--  11-Tile Filled Patch of the {5,4} Hyperbolic Tiling
-- ════════════════════════════════════════════════════════════════════
--
--  This module encodes the polygon complex for the 11-tile filled
--  patch of the {5,4} tiling as specified in §2.2 and §13 of
--  docs/09-happy-instance.md.  It is the primary curvature /
--  Gauss–Bonnet formalization target (Theorem 1).
--
--  Patch composition:
--    • 1  central pentagon  C
--    • 5  edge-neighbour pentagons  N₀ .. N₄
--    • 5  gap-filler pentagons  G₀ .. G₄
--
--  Polygon complex counts:
--    • Vertices:  30   (5 interior + 25 boundary)
--    • Edges:     40   (15 internal + 25 boundary)
--    • Faces:     11   (all regular pentagons)
--    • Euler:     χ = 30 − 40 + 11 = 1   (disk)
--
--  Every interior vertex v_i has valence 4 in the tiling graph,
--  matching the {5,4} Schläfli condition: 4 regular pentagons
--  meet at each interior vertex, contributing 4 × 108° = 432° of
--  angle, exceeding 360° by 72° = 2π/5.  This is the source of
--  negative curvature.
--
--  The encoding uses Strategy A from §13.2 of docs/09-happy-instance.md:
--  vertices are grouped into 5 classes, and combinatorial curvature
--  is constant within each class.  Individual vertices (30 constructors)
--  are also provided for face-vertex incidence.
--
--  Numerical verification:
--    sim/prototyping/02_happy_patch_curvature.py
--    (§4 of docs/09-happy-instance.md)
--
--  Downstream modules:
--    src/Bulk/Curvature.agda    — κ : VClass → ℚ₁₀
--    src/Bulk/GaussBonnet.agda  — Σ κ(v) ≡ χ(K)
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  PatchFace — The 11 pentagonal tiles
-- ════════════════════════════════════════════════════════════════════
--
--  One constructor per tile.  Naming convention:
--    fC   — central pentagon
--    fNᵢ  — edge-neighbour sharing edge (vᵢ , vᵢ₊₁) with C
--    fGᵢ  — gap-filler at vertex vᵢ, between Nᵢ₋₁ and Nᵢ
--
--  All tiles are regular pentagons (5 sides each).
-- ════════════════════════════════════════════════════════════════════

data PatchFace : Type₀ where
  fC  : PatchFace
  fN₀ fN₁ fN₂ fN₃ fN₄ : PatchFace
  fG₀ fG₁ fG₂ fG₃ fG₄ : PatchFace

-- Every face is a pentagon.
faceSides : ℕ
faceSides = 5


-- ════════════════════════════════════════════════════════════════════
--  §2.  VClass — Vertex classification (5 classes)
-- ════════════════════════════════════════════════════════════════════
--
--  The 30 vertices of the polygon complex fall into 5 classes,
--  determined by their combinatorial neighbourhood.  Within each
--  class, all vertices have identical edge degree, face valence,
--  and therefore identical combinatorial curvature.
--
--    Class     Vertices          Count   Int/Bdy   deg   faces   κ
--    ────────  ────────────────  ─────   ───────   ───   ─────   ────
--    vTiling   v₀ .. v₄            5    interior    4     4     −1/5
--    vSharedA  a₀ .. a₄            5    boundary    3     2     −1/10
--    vOuterB   b₀ .. b₄            5    boundary    2     1      1/5
--    vSharedC  c₀ .. c₄            5    boundary    3     2     −1/10
--    vOuterG   g₀₁..g₀₂ .. g₄₂   10    boundary    2     1      1/5
--
--  Naming:
--    vTiling  = vertices of the central pentagon C (shared by 4 faces)
--    vSharedA = boundary vertices shared between Nᵢ and Gᵢ₊₁
--    vOuterB  = boundary vertices belonging only to Nᵢ
--    vSharedC = boundary vertices shared between Nᵢ and Gᵢ
--    vOuterG  = boundary vertices belonging only to Gᵢ
--
--  The curvature values listed above are derived from the
--  combinatorial formula
--      κ(v) = 1 − deg(v)/2 + Σ_{f ∋ v} 1/sides(f)
--  and are formalized in Bulk/Curvature.agda.
-- ════════════════════════════════════════════════════════════════════

data VClass : Type₀ where
  vTiling  : VClass
  vSharedA : VClass
  vOuterB  : VClass
  vSharedC : VClass
  vOuterG  : VClass

-- ────────────────────────────────────────────────────────────────
--  Number of vertices in each class
-- ────────────────────────────────────────────────────────────────

vCount : VClass → ℕ
vCount vTiling  = 5
vCount vSharedA = 5
vCount vOuterB  = 5
vCount vSharedC = 5
vCount vOuterG  = 10


-- ════════════════════════════════════════════════════════════════════
--  §3.  Combinatorial incidence data per vertex class
-- ════════════════════════════════════════════════════════════════════
--
--  These functions record the edge degree and face valence at each
--  vertex class.  They are the inputs to the combinatorial curvature
--  formula  κ(v) = 1 − deg(v)/2 + faceValence(v)/sides  and are
--  verified against the Python prototype in §4.1 of
--  docs/09-happy-instance.md.
--
--  Edge degree = number of edges incident to the vertex:
--    vTiling:   4  (two C-edges + one Nᵢ-edge + one Gᵢ-edge)
--    vSharedA:  3  (one Nᵢ/Gᵢ₊₁ shared + one Nᵢ-only + one Gᵢ₊₁-only)
--    vOuterB:   2  (two Nᵢ-only edges)
--    vSharedC:  3  (one Nᵢ/Gᵢ shared + one Nᵢ-only + one Gᵢ-only)
--    vOuterG:   2  (two Gᵢ-only edges)
--
--  Face valence = number of pentagonal faces meeting at the vertex:
--    vTiling:   4  (C + Nᵢ₋₁ + Nᵢ + Gᵢ)
--    vSharedA:  2  (Nᵢ + Gᵢ₊₁)
--    vOuterB:   1  (Nᵢ only)
--    vSharedC:  2  (Nᵢ + Gᵢ)
--    vOuterG:   1  (Gᵢ only)
-- ════════════════════════════════════════════════════════════════════

edgeDeg : VClass → ℕ
edgeDeg vTiling  = 4
edgeDeg vSharedA = 3
edgeDeg vOuterB  = 2
edgeDeg vSharedC = 3
edgeDeg vOuterG  = 2

faceValence : VClass → ℕ
faceValence vTiling  = 4
faceValence vSharedA = 2
faceValence vOuterB  = 1
faceValence vSharedC = 2
faceValence vOuterG  = 1


-- ════════════════════════════════════════════════════════════════════
--  §4.  Vertex — The 30 vertices of the polygon complex
-- ════════════════════════════════════════════════════════════════════
--
--  Explicit enumeration of all 30 vertices, grouped by class.
--  This allows the face-vertex incidence map (§5) to be stated
--  in terms of concrete vertex names.
--
--  Naming conventions follow the Python prototype
--  (sim/prototyping/02_happy_patch_curvature.py):
--
--    vᵢ   — tiling vertex i of the central pentagon C
--             (also a corner of Nᵢ₋₁, Nᵢ, and Gᵢ)
--    aᵢ   — new vertex of Nᵢ shared with Gᵢ₊₁
--    bᵢ   — new vertex of Nᵢ not shared with any other tile
--    cᵢ   — new vertex of Nᵢ shared with Gᵢ
--    gᵢ₁  — first new vertex of Gᵢ (not shared with any other tile)
--    gᵢ₂  — second new vertex of Gᵢ (not shared with any other tile)
--
--  Note on set-truncation:
--    Vertex is a finite datatype with no path constructors, so it
--    is automatically a set (h-level 2).  A formal proof of
--    isSet Vertex can be obtained via Discrete→isSet from
--    Cubical.Relation.Nullary, but is omitted here because
--    downstream modules (Curvature, GaussBonnet) require isSet
--    only on the scalar type ℚ₁₀, which is already provided
--    by Util/Rationals.agda.
-- ════════════════════════════════════════════════════════════════════

data Vertex : Type₀ where
  -- Tiling vertices  (interior,  5 vertices,  class vTiling)
  v₀ v₁ v₂ v₃ v₄ : Vertex

  -- Shared-A vertices  (boundary,  5 vertices,  class vSharedA)
  a₀ a₁ a₂ a₃ a₄ : Vertex

  -- Outer-B vertices  (boundary,  5 vertices,  class vOuterB)
  b₀ b₁ b₂ b₃ b₄ : Vertex

  -- Shared-C vertices  (boundary,  5 vertices,  class vSharedC)
  c₀ c₁ c₂ c₃ c₄ : Vertex

  -- Outer-G vertices  (boundary,  10 vertices,  class vOuterG)
  g₀₁ g₀₂ g₁₁ g₁₂ g₂₁ g₂₂ g₃₁ g₃₂ g₄₁ g₄₂ : Vertex


-- ────────────────────────────────────────────────────────────────
--  classify — Map each vertex to its class
-- ────────────────────────────────────────────────────────────────
--
--  This is a 30-clause pattern match.  It is the bridge between
--  the individual-vertex level (needed for face-vertex incidence)
--  and the class level (needed for curvature computation).
--
--  The downstream curvature function is:
--    κ : Vertex → ℚ₁₀
--    κ w = κ-class (classify w)
--  where κ-class : VClass → ℚ₁₀ is a 5-clause lookup defined in
--  Bulk/Curvature.agda.
-- ────────────────────────────────────────────────────────────────

classify : Vertex → VClass
classify v₀  = vTiling
classify v₁  = vTiling
classify v₂  = vTiling
classify v₃  = vTiling
classify v₄  = vTiling
classify a₀  = vSharedA
classify a₁  = vSharedA
classify a₂  = vSharedA
classify a₃  = vSharedA
classify a₄  = vSharedA
classify b₀  = vOuterB
classify b₁  = vOuterB
classify b₂  = vOuterB
classify b₃  = vOuterB
classify b₄  = vOuterB
classify c₀  = vSharedC
classify c₁  = vSharedC
classify c₂  = vSharedC
classify c₃  = vSharedC
classify c₄  = vSharedC
classify g₀₁ = vOuterG
classify g₀₂ = vOuterG
classify g₁₁ = vOuterG
classify g₁₂ = vOuterG
classify g₂₁ = vOuterG
classify g₂₂ = vOuterG
classify g₃₁ = vOuterG
classify g₃₂ = vOuterG
classify g₄₁ = vOuterG
classify g₄₂ = vOuterG


-- ════════════════════════════════════════════════════════════════════
--  §5.  Face-vertex incidence
-- ════════════════════════════════════════════════════════════════════
--
--  Each pentagonal face is specified by an ordered 5-tuple of its
--  vertices in cyclic order.  Consecutive vertices in the tuple
--  share an edge of the polygon complex.
--
--  The orderings follow the Python prototype exactly
--  (build_11tile_complex in 02_happy_patch_curvature.py):
--
--    C:   (v₀, v₁, v₂, v₃, v₄)
--    Nᵢ:  (vᵢ, vᵢ₊₁, aᵢ, bᵢ, cᵢ)        where i+1 is mod 5
--    Gᵢ:  (vᵢ, aᵢ₋₁, gᵢ₁, gᵢ₂, cᵢ)      where i−1 is mod 5
--
--  Shared edges (internal edges of the complex):
--    C  ∩ Nᵢ   :  edge (vᵢ , vᵢ₊₁)           5 edges
--    Nᵢ ∩ Gᵢ   :  edge (cᵢ , vᵢ)  = (vᵢ, cᵢ)  5 edges
--    Nᵢ ∩ Gᵢ₊₁ :  edge (vᵢ₊₁, aᵢ)             5 edges
--                                          total: 15 internal edges
--
--  The remaining 25 edges are boundary edges (each in exactly one face).
-- ════════════════════════════════════════════════════════════════════

Pentagon : Type₀
Pentagon = Vertex × Vertex × Vertex × Vertex × Vertex

faceVertices : PatchFace → Pentagon
-- Central pentagon
faceVertices fC  = v₀ , v₁ , v₂ , v₃ , v₄
-- Edge-neighbours: Nᵢ shares edge (vᵢ, vᵢ₊₁) with C
faceVertices fN₀ = v₀ , v₁ , a₀ , b₀ , c₀
faceVertices fN₁ = v₁ , v₂ , a₁ , b₁ , c₁
faceVertices fN₂ = v₂ , v₃ , a₂ , b₂ , c₂
faceVertices fN₃ = v₃ , v₄ , a₃ , b₃ , c₃
faceVertices fN₄ = v₄ , v₀ , a₄ , b₄ , c₄
-- Gap-fillers: Gᵢ at vertex vᵢ, between Nᵢ₋₁ and Nᵢ
faceVertices fG₀ = v₀ , a₄ , g₀₁ , g₀₂ , c₀
faceVertices fG₁ = v₁ , a₀ , g₁₁ , g₁₂ , c₁
faceVertices fG₂ = v₂ , a₁ , g₂₁ , g₂₂ , c₂
faceVertices fG₃ = v₃ , a₂ , g₃₁ , g₃₂ , c₃
faceVertices fG₄ = v₄ , a₃ , g₄₁ , g₄₂ , c₄


-- ════════════════════════════════════════════════════════════════════
--  §6.  Global topological counts
-- ════════════════════════════════════════════════════════════════════
--
--  These are the V, E, F counts of the polygon complex, together
--  with the interior/boundary vertex split.
--
--    totalV = 30     (5 interior + 25 boundary)
--    totalE = 40     (15 internal + 25 boundary)
--    totalF = 11     (all pentagons)
--
--  The Euler characteristic is χ = V − E + F = 30 − 40 + 11 = 1.
--  Since we work with ℕ (no subtraction), we state this as the
--  additive identity  V + F = E + χ,  i.e.  30 + 11 = 40 + 1.
-- ════════════════════════════════════════════════════════════════════

totalV : ℕ
totalV = 30

totalE : ℕ
totalE = 40

totalF : ℕ
totalF = 11

interiorV : ℕ
interiorV = 5

boundaryV : ℕ
boundaryV = 25

internalE : ℕ
internalE = 15

boundaryE : ℕ
boundaryE = 25


-- ════════════════════════════════════════════════════════════════════
--  §7.  Topological verification proofs
-- ════════════════════════════════════════════════════════════════════
--
--  All proofs in this section hold by refl because both sides of
--  each identity normalize to the same ℕ term under the judgmental
--  computation rules for _+_ and _·_.
--
--  These proofs serve three purposes:
--
--    1. Machine-checked sanity tests on the polygon complex data.
--    2. Exportable lemmas for the Gauss–Bonnet proof.
--    3. Regression tests: if any count is changed (e.g. during a
--       future patch extension), these proofs will fail at type-check
--       time, immediately signaling the inconsistency.
-- ════════════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────────
--  Euler characteristic:  V + F = E + χ  where χ = 1
--  30 + 11 = 41 = 40 + 1
-- ────────────────────────────────────────────────────────────────

euler-char : totalV + totalF ≡ totalE + 1
euler-char = refl

-- ────────────────────────────────────────────────────────────────
--  Vertex count decomposes into the 5 vertex classes:
--  5 + 5 + 5 + 5 + 10 = 30
-- ────────────────────────────────────────────────────────────────

count-decomp :
    vCount vTiling
  + vCount vSharedA
  + vCount vOuterB
  + vCount vSharedC
  + vCount vOuterG
  ≡ totalV
count-decomp = refl

-- ────────────────────────────────────────────────────────────────
--  Interior / boundary vertex split:  5 + 25 = 30
-- ────────────────────────────────────────────────────────────────

count-split : interiorV + boundaryV ≡ totalV
count-split = refl

-- ────────────────────────────────────────────────────────────────
--  Interior vertex count = tiling vertex count
-- ────────────────────────────────────────────────────────────────

interiorV≡vTiling : interiorV ≡ vCount vTiling
interiorV≡vTiling = refl

-- ────────────────────────────────────────────────────────────────
--  Edge count decomposes:  15 internal + 25 boundary = 40
-- ────────────────────────────────────────────────────────────────

edge-decomp : internalE + boundaryE ≡ totalE
edge-decomp = refl

-- ────────────────────────────────────────────────────────────────
--  Handshaking lemma:  Σ_{class} (count · edgeDeg) = 2 · totalE
--
--    5·4 + 5·3 + 5·2 + 5·3 + 10·2
--  = 20  + 15  + 10  + 15  + 20
--  = 80
--  = 2 · 40
-- ────────────────────────────────────────────────────────────────

handshaking :
    vCount vTiling  · edgeDeg vTiling
  + vCount vSharedA · edgeDeg vSharedA
  + vCount vOuterB  · edgeDeg vOuterB
  + vCount vSharedC · edgeDeg vSharedC
  + vCount vOuterG  · edgeDeg vOuterG
  ≡ 2 · totalE
handshaking = refl

-- ────────────────────────────────────────────────────────────────
--  Face-incidence identity:
--    Σ_{class} (count · faceValence) = totalF · faceSides
--
--    5·4 + 5·2 + 5·1 + 5·2 + 10·1
--  = 20  + 10  + 5   + 10  + 10
--  = 55
--  = 11 · 5
--
--  This counts the total number of vertex-face incidence pairs.
--  Each face contributes  faceSides = 5  incidences, so the total
--  is  11 · 5 = 55.  Each vertex v contributes faceValence(v)
--  incidences.  The identity confirms consistency of the
--  faceValence function with the face count.
-- ────────────────────────────────────────────────────────────────

face-incidence :
    vCount vTiling  · faceValence vTiling
  + vCount vSharedA · faceValence vSharedA
  + vCount vOuterB  · faceValence vOuterB
  + vCount vSharedC · faceValence vSharedC
  + vCount vOuterG  · faceValence vOuterG
  ≡ totalF · faceSides
face-incidence = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  Boundary cycle description
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary of the disk patch is a cycle of 25 vertices and
--  25 edges.  The boundary groups in cyclic order are:
--
--    N₀(2 legs), G₁(3 legs), N₁(2 legs), G₂(3 legs), N₂(2 legs),
--    G₃(3 legs), N₃(2 legs), G₄(3 legs), N₄(2 legs), G₀(3 legs)
--
--  Total boundary legs: 5 × 2 + 5 × 3 = 25.
--
--  The boundary vertex sequence (reading counterclockwise from a₀):
--
--    a₀ → b₀ → c₀ → g₀₂ → g₀₁ → a₄ → b₄ → c₄ → g₄₂ → g₄₁ →
--    a₃ → b₃ → c₃ → g₃₂ → g₃₁ → a₂ → b₂ → c₂ → g₂₂ → g₂₁ →
--    a₁ → b₁ → c₁ → g₁₂ → g₁₁ → (back to a₀)
--
--  This data is recorded for reference; it is not currently used
--  by any downstream proof.  Future modules that reason about the
--  boundary (e.g. for the angular Gauss–Bonnet boundary term)
--  would formalize this as an explicit cyclic list or path.
-- ════════════════════════════════════════════════════════════════════

-- Boundary legs per tile class:  Nᵢ has 2, Gᵢ has 3
boundaryLegsN : ℕ
boundaryLegsN = 2

boundaryLegsG : ℕ
boundaryLegsG = 3

-- Total boundary legs: 5·2 + 5·3 = 25
boundary-legs-check : 5 · boundaryLegsN + 5 · boundaryLegsG ≡ boundaryV
boundary-legs-check = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Design notes and downstream interface
-- ════════════════════════════════════════════════════════════════════
--
--  Exports for Bulk/Curvature.agda:
--
--    VClass, vCount        — vertex classification and class sizes
--    edgeDeg, faceValence  — combinatorial neighbourhood data
--    faceSides             — all faces are pentagons (= 5)
--    classify              — Vertex → VClass  (if per-vertex κ is needed)
--
--  Exports for Bulk/GaussBonnet.agda:
--
--    vCount                — weights in the classified Gauss–Bonnet sum
--    totalV, totalE, totalF — for stating χ = V − E + F
--    euler-char            — the Euler identity  V + F = E + 1
--    count-decomp          — vertex count = sum of class counts
--
--  Exports for face-level reasoning:
--
--    PatchFace             — the 11 faces
--    Vertex, Pentagon      — vertices and 5-tuple type
--    faceVertices          — face-vertex incidence map
--
--  Edge enumeration:
--
--    The 40 edges are NOT individually enumerated.  The complex has
--    15 internal edges (each shared by exactly 2 faces) and 25
--    boundary edges (each in exactly 1 face).  The incidence data
--    is captured at the class level by edgeDeg and verified by the
--    handshaking lemma.  If future modules require individual edge
--    reasoning (e.g. for Regge curvature with per-edge lengths),
--    an explicit Edge type with 40 constructors and an endpoint map
--    can be added without modifying any existing proofs.
--
--  Set-truncation:
--
--    Vertex, VClass, and PatchFace are finite datatypes with no
--    path constructors, so they are automatically sets (h-level 2).
--    Formal proofs of isSet can be obtained via Discrete→isSet
--    (from Cubical.Relation.Nullary) and decidable equality by
--    exhaustive case split.  These proofs are omitted here because
--    the downstream Gauss–Bonnet proof requires isSet only on the
--    scalar type ℚ₁₀ (= ℤ), which is provided by isSetℚ₁₀ in
--    Util/Rationals.agda.
-- ════════════════════════════════════════════════════════════════════