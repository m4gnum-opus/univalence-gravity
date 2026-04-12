{-# OPTIONS --cubical --safe --guardedness #-}

module Gauge.Holonomy where

open import Cubical.Foundations.Prelude
open import Cubical.Data.List  using (List ; [] ; _∷_)
open import Cubical.Data.Sigma using (_×_)
open import Cubical.Data.Empty using (⊥)

open import Gauge.FiniteGroup
open import Gauge.ZMod    using (Z3 ; z0 ; z1 ; z2 ; ℤ/3)
open import Gauge.Q8      using (Q8 ; q1 ; qn1 ; qi ; qni ; qj ; qnj ; qk ; qnk ; Q₈)
open import Gauge.Connection
open import Common.StarSpec
  using (Bond ; bCN0 ; bCN1 ; bCN2 ; bCN3 ; bCN4)


-- ════════════════════════════════════════════════════════════════════
--  §1.  holonomy — Wilson loop computation
-- ════════════════════════════════════════════════════════════════════
--
--  Given a gauge connection ω on a finite group G over bond type B,
--  and a directed face boundary (a list of bond-direction pairs),
--  the holonomy is the ordered group product:
--
--    W_f = readBond(b₁,d₁) · readBond(b₂,d₂) · ⋯ · readBond(bₙ,dₙ)
--
--  computed as a right fold starting from the identity ε.  By
--  group associativity, this equals the standard left-associated
--  convention from lattice gauge theory.
--
--  For an empty boundary, the holonomy is ε (the identity).
--
--  Reference:
--    docs/formal/05-gauge-theory.md §6.1  (Wilson Loop Computation)
--    docs/formal/05-gauge-theory.md §6    (Holonomy and Particle
--                                          Defects — type-theoretic
--                                          definition)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — theorem registry)
-- ════════════════════════════════════════════════════════════════════

holonomy :
  {G : FiniteGroup} {BondTy : Type₀}
  → GaugeConnection G BondTy
  → List (BondTy × Dir)
  → FiniteGroup.Carrier G
holonomy {G} ω [] = FiniteGroup.ε G
holonomy {G} ω ((b , d) ∷ rest) =
  FiniteGroup._·_ G (readBond {G} ω d b) (holonomy {G} ω rest)


-- ════════════════════════════════════════════════════════════════════
--  §2.  isFlat — Vacuum configuration (no matter)
-- ════════════════════════════════════════════════════════════════════
--
--  A gauge connection ω is flat with respect to a face type FaceTy
--  and a boundary function ∂ : FaceTy → List (BondTy × Dir) if the
--  holonomy around every face equals the group identity ε.
--
--  The vacuum (empty space) is a flat connection: W_f = ε for all f.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §6.2  (Flatness)
-- ════════════════════════════════════════════════════════════════════

isFlat :
  {G : FiniteGroup} {BondTy : Type₀} {FaceTy : Type₀}
  → GaugeConnection G BondTy
  → (FaceTy → List (BondTy × Dir))
  → Type₀
isFlat {G} ω ∂f = (f : _) → holonomy {G} ω (∂f f) ≡ FiniteGroup.ε G


-- ════════════════════════════════════════════════════════════════════
--  §3.  ParticleDefect — Matter as topological defect
-- ════════════════════════════════════════════════════════════════════
--
--  A particle at a face is a configuration where the holonomy is
--  NOT the group identity.  The type  ParticleDefect ω boundary
--  is the negation of the path  holonomy ω boundary ≡ ε .
--
--  This is valued in Type₀ (it is a negation of a path, hence a
--  proposition by isProp¬).  For finite groups with decidable
--  equality, this is a decidable proposition: the Agda type-checker
--  can evaluate whether a defect exists at any concrete face.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §6.3  (ParticleDefect — Matter
--                                          as Topological Excitation)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — theorem registry)
-- ════════════════════════════════════════════════════════════════════

ParticleDefect :
  {G : FiniteGroup} {BondTy : Type₀}
  → GaugeConnection G BondTy
  → List (BondTy × Dir)
  → Type₀
ParticleDefect {G} ω boundary =
  holonomy {G} ω boundary ≡ FiniteGroup.ε G → ⊥


-- ════════════════════════════════════════════════════════════════════
--  §4.  Central face boundary — The star patch pentagon
-- ════════════════════════════════════════════════════════════════════
--
--  The central pentagon C of the 6-tile star patch has 5 edges,
--  each shared with a neighbor tile N_i.  In the lattice gauge
--  theory on the tile-adjacency graph, these correspond to the
--  5 bonds bCN0..bCN4.
--
--  The directed boundary traverses all 5 bonds in the forward
--  direction (from C to each N_i), cycling around the pentagon:
--
--    (v₀,v₁) = bond bCN0 fwd    (shared edge C–N0)
--    (v₁,v₂) = bond bCN1 fwd    (shared edge C–N1)
--    (v₂,v₃) = bond bCN2 fwd    (shared edge C–N2)
--    (v₃,v₄) = bond bCN3 fwd    (shared edge C–N3)
--    (v₄,v₀) = bond bCN4 fwd    (shared edge C–N4)
--
--  The holonomy around this face is:
--    W_C = ω(bCN0) · ω(bCN1) · ω(bCN2) · ω(bCN3) · ω(bCN4)
-- ════════════════════════════════════════════════════════════════════

centralFaceBdy : List (Bond × Dir)
centralFaceBdy =
    (bCN0 , fwd) ∷ (bCN1 , fwd) ∷ (bCN2 , fwd)
  ∷ (bCN3 , fwd) ∷ (bCN4 , fwd) ∷ []


-- ════════════════════════════════════════════════════════════════════
--  §5.  Star face type and boundary function
-- ════════════════════════════════════════════════════════════════════
--
--  For the restricted star-topology lattice (5 C–N bonds only),
--  the central pentagon is the only face whose boundary is fully
--  expressible in terms of star bonds.  (Neighbor faces N_i have
--  edges involving N–G bonds from the 15-bond filled patch.)
--
--  This single-face type is sufficient for the holonomy and
--  ParticleDefect demonstrations on the star patch.
--
--  Reference:
--    docs/instances/star-patch.md §8     (Gauge Enrichment)
--    docs/formal/05-gauge-theory.md §6.4 (Concrete Defect Witnesses)
-- ════════════════════════════════════════════════════════════════════

data StarFace : Type₀ where
  centralFace : StarFace

starBoundary : StarFace → List (Bond × Dir)
starBoundary centralFace = centralFaceBdy


-- ════════════════════════════════════════════════════════════════════
--  §6.  Discriminators for defect proofs
-- ════════════════════════════════════════════════════════════════════
--
--  To inhabit  ParticleDefect , we need proofs that specific
--  non-identity group elements are distinct from ε.  These are
--  constructed using the standard discriminator pattern:
--  a function mapping ε to ⊥ and the non-identity element to
--  an inhabited type, then  subst  along the hypothetical path.
-- ════════════════════════════════════════════════════════════════════

private
  -- ── ℤ/2ℤ discriminator ──────────────────────────────────────
  not-e0 : Z2 → Type₀
  not-e0 e0 = ⊥
  not-e0 e1 = Z2

  e1≢e0 : e1 ≡ e0 → ⊥
  e1≢e0 p = subst not-e0 p e1

  -- ── ℤ/3ℤ discriminator ──────────────────────────────────────
  not-z0 : Z3 → Type₀
  not-z0 z0 = ⊥
  not-z0 z1 = Z3
  not-z0 z2 = Z3

  z1≢z0 : z1 ≡ z0 → ⊥
  z1≢z0 p = subst not-z0 p z1

  -- ── Q₈ discriminator ────────────────────────────────────────
  not-q1 : Q8 → Type₀
  not-q1 q1  = ⊥
  not-q1 qn1 = Q8
  not-q1 qi  = Q8
  not-q1 qni = Q8
  not-q1 qj  = Q8
  not-q1 qnj = Q8
  not-q1 qk  = Q8
  not-q1 qnk = Q8

  qi≢q1 : qi ≡ q1 → ⊥
  qi≢q1 p = subst not-q1 p qi

  qk≢q1 : qk ≡ q1 → ⊥
  qk≢q1 p = subst not-q1 p qk

  qnk≢q1 : qnk ≡ q1 → ⊥
  qnk≢q1 p = subst not-q1 p qnk


-- ════════════════════════════════════════════════════════════════════
--  §7.  ℤ/2ℤ — Flat connection: holonomy = ε, no defect
-- ════════════════════════════════════════════════════════════════════
--
--  For the flat ℤ/2 connection (all bonds = e0 = ε):
--    W_C = e0 · e0 · e0 · e0 · e0 · ε
--        = e0     (by left-identity: e0 +Z2 x = x)
--        = ε
--
--  The holonomy is the identity, so the central face has no defect.
--  This is the "empty space" configuration.
-- ════════════════════════════════════════════════════════════════════

holonomy-flat-Z2 : holonomy starFlatZ2 centralFaceBdy ≡ e0
holonomy-flat-Z2 = refl

-- The flat connection IS flat for the central face
flat-Z2-isFlat : isFlat starFlatZ2 starBoundary
flat-Z2-isFlat centralFace = refl


-- ════════════════════════════════════════════════════════════════════
--  §8.  ℤ/2ℤ — Non-trivial connection: holonomy ≠ ε, DEFECT!
-- ════════════════════════════════════════════════════════════════════
--
--  For starNontrivZ2 (bCN0 = e1, rest = e0):
--    W_C = e1 · e0 · e0 · e0 · e0 · ε
--        = e1 · e0 · e0 · e0 · e0
--        = e1 · e0               (inner products reduce to e0)
--        = e1                     (e1 +Z2 e0 = e1)
--        ≠ e0 = ε
--
--  There is a PARTICLE at the central face.  This is the first
--  machine-checked topological defect (non-trivial Wilson loop)
--  on the holographic tensor network.
--
--  This result satisfies Theorem 6 in the canonical theorem
--  registry (docs/formal/01-theorems.md §Thm 6):
--    "A ParticleDefect type is inhabited for a concrete gauge
--     connection on the 6-tile star patch with a specified
--     non-trivial holonomy at one face."
--
--  Reference:
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — theorem registry)
--    docs/formal/05-gauge-theory.md §6.4  (Concrete Defect Witnesses)
--    docs/instances/star-patch.md §8      (Gauge Enrichment)
-- ════════════════════════════════════════════════════════════════════

-- The holonomy reduces to e1 by judgmental computation
holonomy-nontrivZ2 : holonomy starNontrivZ2 centralFaceBdy ≡ e1
holonomy-nontrivZ2 = refl

-- The non-trivial connection is NOT flat
nontrivZ2-not-flat : isFlat starNontrivZ2 starBoundary → ⊥
nontrivZ2-not-flat flat = e1≢e0 (flat centralFace)

-- ★ THE PARTICLE DEFECT — a constructive witness of matter ★
--
-- This is the inhabited ParticleDefect for Theorem 6.
-- The proof: if the holonomy (= e1) were equal to ε (= e0),
-- we could derive ⊥ via the discriminator e1≢e0.
defect-Z2 : ParticleDefect starNontrivZ2 centralFaceBdy
defect-Z2 p = e1≢e0 p


-- ════════════════════════════════════════════════════════════════════
--  §9.  ℤ/3ℤ — Non-trivial connection with distinct charge
-- ════════════════════════════════════════════════════════════════════
--
--  For starNontrivZ3 (bCN0 = z1, rest = z0):
--    W_C = z1 · z0 · z0 · z0 · z0 · z0
--        = z1                     (z0 is identity)
--        ≠ z0 = ε
--
--  The particle species is the conjugacy class [z1] in ℤ/3ℤ.
--  Since ℤ/3ℤ is abelian, [z1] = {z1} — a singleton class.
--  This is the "charge +1" particle type (of 3 total:
--  vacuum + charge +1 + charge −1).
--
--  Reference:
--    docs/formal/05-gauge-theory.md §7    (Conjugacy Classes and
--                                          Particle Species)
-- ════════════════════════════════════════════════════════════════════

holonomy-nontrivZ3 : holonomy starNontrivZ3 centralFaceBdy ≡ z1
holonomy-nontrivZ3 = refl

defect-Z3 : ParticleDefect starNontrivZ3 centralFaceBdy
defect-Z3 p = z1≢z0 p


-- ════════════════════════════════════════════════════════════════════
--  §10.  Q₈ — Non-abelian gauge group examples
-- ════════════════════════════════════════════════════════════════════
--
--  Q₈ is the first non-abelian gauge group in the repository.
--  On the star bond type with a single non-identity bond:
--
--    Connection A:  bCN0 = i,  rest = 1
--    Holonomy:      W_C = i · 1 · 1 · 1 · 1 = i  ≠  1
--
--  For two non-identity bonds, the ORDER MATTERS:
--
--    Connection B:  bCN0 = i, bCN1 = j, rest = 1
--    Holonomy:      W_C = i · j · 1 · 1 · 1 = i · j = k
--
--    Connection C:  bCN0 = j, bCN1 = i, rest = 1
--    Holonomy:      W_C = j · i · 1 · 1 · 1 = j · i = −k
--
--  The holonomies differ (k ≠ −k), demonstrating that the
--  holonomy depends on the ordered product, not just which
--  bonds carry non-identity elements.  This is the hallmark
--  of non-abelian gauge theory.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §6    (Holonomy and Particle
--                                          Defects — non-commutativity)
--    docs/formal/05-gauge-theory.md §4.3  (Q₈ — the Quaternion Group)
--    docs/instances/star-patch.md §8.1    (Concrete Connections)
-- ════════════════════════════════════════════════════════════════════

-- ── Connection A: single non-identity bond (i) ────────────────

starQ8-i : GaugeConnection Q₈ Bond
starQ8-i .GaugeConnection.assign bCN0 = qi
starQ8-i .GaugeConnection.assign bCN1 = q1
starQ8-i .GaugeConnection.assign bCN2 = q1
starQ8-i .GaugeConnection.assign bCN3 = q1
starQ8-i .GaugeConnection.assign bCN4 = q1

holonomy-Q8-i : holonomy starQ8-i centralFaceBdy ≡ qi
holonomy-Q8-i = refl

defect-Q8-i : ParticleDefect starQ8-i centralFaceBdy
defect-Q8-i p = qi≢q1 p

-- ── Connection B: bCN0 = i, bCN1 = j → holonomy = k ──────────

starQ8-ij : GaugeConnection Q₈ Bond
starQ8-ij .GaugeConnection.assign bCN0 = qi
starQ8-ij .GaugeConnection.assign bCN1 = qj
starQ8-ij .GaugeConnection.assign bCN2 = q1
starQ8-ij .GaugeConnection.assign bCN3 = q1
starQ8-ij .GaugeConnection.assign bCN4 = q1

holonomy-Q8-ij : holonomy starQ8-ij centralFaceBdy ≡ qk
holonomy-Q8-ij = refl

defect-Q8-ij : ParticleDefect starQ8-ij centralFaceBdy
defect-Q8-ij p = qk≢q1 p

-- ── Connection C: bCN0 = j, bCN1 = i → holonomy = −k ─────────
--
--  SWAPPING the bond assignments changes the holonomy from k to −k!
--  This is the concrete manifestation of non-commutativity:
--    i · j = k  ≠  −k = j · i

starQ8-ji : GaugeConnection Q₈ Bond
starQ8-ji .GaugeConnection.assign bCN0 = qj
starQ8-ji .GaugeConnection.assign bCN1 = qi
starQ8-ji .GaugeConnection.assign bCN2 = q1
starQ8-ji .GaugeConnection.assign bCN3 = q1
starQ8-ji .GaugeConnection.assign bCN4 = q1

holonomy-Q8-ji : holonomy starQ8-ji centralFaceBdy ≡ qnk
holonomy-Q8-ji = refl

defect-Q8-ji : ParticleDefect starQ8-ji centralFaceBdy
defect-Q8-ji p = qnk≢q1 p


-- ════════════════════════════════════════════════════════════════════
--  §11.  Non-commutativity witness
-- ════════════════════════════════════════════════════════════════════
--
--  The holonomies of connections B and C differ:
--    W_C(ij) = k  ≠  −k = W_C(ji)
--
--  This is a machine-checked demonstration that non-abelian gauge
--  theory on a discrete holographic network produces order-dependent
--  holonomies — exactly as expected from the non-commutativity of Q₈.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §6    (Non-commutative holonomy)
--    docs/formal/01-theorems.md §Thm 6    (Non-commutativity witness)

noncommutative-holonomy :
  holonomy starQ8-ij centralFaceBdy
  ≡ holonomy starQ8-ji centralFaceBdy
  → ⊥
noncommutative-holonomy p = qk≢qnk p
  where
    -- qk and qnk are distinct Q8 elements
    not-qnk : Q8 → Type₀
    not-qnk qk  = Q8
    not-qnk qnk = ⊥
    not-qnk _   = Q8

    qk≢qnk : qk ≡ qnk → ⊥
    qk≢qnk q = subst not-qnk q qk


-- ════════════════════════════════════════════════════════════════════
--  §12.  Regression tests — holonomy on closed numerals
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that the holonomy computation reduces judgmentally
--  to the expected group elements on concrete connections.
-- ════════════════════════════════════════════════════════════════════

private
  -- Empty boundary: holonomy = ε
  check-empty : holonomy {ℤ/2} starFlatZ2 [] ≡ e0
  check-empty = refl

  -- Single bond: holonomy = that bond's value
  check-single :
    holonomy starNontrivZ2 ((bCN0 , fwd) ∷ []) ≡ e1
  check-single = refl

  -- Reverse direction: holonomy uses inverse
  -- For ℤ/2, inv(e1) = e1 (self-inverse), so result is the same
  check-rev-Z2 :
    holonomy starNontrivZ2 ((bCN0 , rev) ∷ []) ≡ e1
  check-rev-Z2 = refl

  -- For ℤ/3, inv(z1) = z2 (genuinely different!)
  check-rev-Z3 :
    holonomy starNontrivZ3 ((bCN0 , rev) ∷ []) ≡ z2
  check-rev-Z3 = refl

  -- Two-bond product in Q₈:  i · j = k
  check-Q8-two :
    holonomy starQ8-ij ((bCN0 , fwd) ∷ (bCN1 , fwd) ∷ []) ≡ qk
  check-Q8-two = refl

  -- Reversed order:  j · i = −k
  check-Q8-two-rev :
    holonomy starQ8-ji ((bCN0 , fwd) ∷ (bCN1 , fwd) ∷ []) ≡ qnk
  check-Q8-two-rev = refl

  -- Flat Q₈ connection: all q1, holonomy = q1
  check-Q8-flat :
    holonomy (flatConnection Q₈ {Bond}) centralFaceBdy ≡ q1
  check-Q8-flat = refl


-- ════════════════════════════════════════════════════════════════════
--  §13.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    holonomy       : GaugeConnection G B → List (B × Dir)
--                     → FiniteGroup.Carrier G
--                     (Wilson loop computation — right fold)
--
--    isFlat         : GaugeConnection G B
--                     → (FaceTy → List (B × Dir)) → Type₀
--                     (holonomy = ε at every face)
--
--    ParticleDefect : GaugeConnection G B → List (B × Dir) → Type₀
--                     (¬(holonomy ≡ ε) — matter as topological defect)
--
--    StarFace         : Type₀   (single-constructor: centralFace)
--    starBoundary     : StarFace → List (Bond × Dir)
--    centralFaceBdy   : List (Bond × Dir)  (the 5-bond boundary)
--
--    -- ℤ/2ℤ concrete results:
--    holonomy-flat-Z2   : holonomy starFlatZ2 centralFaceBdy ≡ e0
--    flat-Z2-isFlat     : isFlat starFlatZ2 starBoundary
--    holonomy-nontrivZ2 : holonomy starNontrivZ2 centralFaceBdy ≡ e1
--    defect-Z2          : ParticleDefect starNontrivZ2 centralFaceBdy
--    nontrivZ2-not-flat : isFlat starNontrivZ2 starBoundary → ⊥
--
--    -- ℤ/3ℤ concrete results:
--    holonomy-nontrivZ3 : holonomy starNontrivZ3 centralFaceBdy ≡ z1
--    defect-Z3          : ParticleDefect starNontrivZ3 centralFaceBdy
--
--    -- Q₈ concrete results:
--    starQ8-i  / starQ8-ij / starQ8-ji  : GaugeConnection Q₈ Bond
--    holonomy-Q8-i  : ... ≡ qi     (single excited bond)
--    holonomy-Q8-ij : ... ≡ qk     (ij = k)
--    holonomy-Q8-ji : ... ≡ qnk    (ji = −k)
--    defect-Q8-i / defect-Q8-ij / defect-Q8-ji : ParticleDefect ...
--    noncommutative-holonomy : ... → ⊥  (k ≠ −k witness)
--
--  Theorem 6 satisfaction (docs/formal/01-theorems.md §Thm 6):
--
--    ✓  ParticleDefect is inhabited (defect-Z2) for a concrete
--    gauge connection (starNontrivZ2) on the 6-tile star patch
--    with a specified non-trivial holonomy (e1) at the central
--    face.  Non-abelian defects (Q₈) and the non-commutativity
--    witness are additionally provided.
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Gauge/FiniteGroup.agda   — FiniteGroup record, Z2, ℤ/2
--      • Gauge/ZMod.agda          — Z3, ℤ/3
--      • Gauge/Q8.agda            — Q8, Q₈
--      • Gauge/Connection.agda    — GaugeConnection, Dir, readBond,
--                                   starFlatZ2, starNontrivZ2,
--                                   starNontrivZ3, flatConnection
--      • Common/StarSpec.agda     — Bond, bCN0..bCN4
--
--    The gauge layer is purely additive — no existing module is
--    modified.  The holonomy computation enriches the bonds with
--    algebraic structure (group elements) while the flow-graph
--    infrastructure (Boundary/, Bulk/, Bridge/) continues to
--    operate on scalar capacities extracted by the dimension
--    functor (Gauge/RepCapacity.agda).
--
--  Design decisions:
--
--    1.  holonomy is a RIGHT FOLD into ε, not a left fold.
--        Both produce the same result by group associativity
--        (a group axiom verified by refl for all concrete groups).
--        The right fold has the advantage that  holonomy ω []  is
--        definitionally ε without needing an accumulator.
--
--    2.  The face boundary is a LIST of (BondTy × Dir) pairs, not
--        a vector or custom type.  This is the simplest encoding
--        that supports arbitrary face shapes (pentagons, triangles,
--        etc.) and works with the cubical library's existing List
--        infrastructure.
--
--    3.  ParticleDefect is defined as  holonomy ≡ ε → ⊥  (a
--        negation of a path), which is automatically a proposition
--        (isProp of negation types).  This means any two proofs
--        that a defect exists are propositionally equal — there is
--        no spurious higher structure in the defect type.
--
--    4.  The StarFace type has a single constructor for the central
--        pentagon, which is the only face whose boundary is fully
--        expressible in terms of the 5 star bonds.  For the full
--        11-tile filled patch, a richer face type (and the 15-bond
--        filled-patch bond type) would be needed.
--
--  Downstream consumers:
--
--    • Gauge/ConjugacyClass.agda  — Computes the conjugacy class
--      [W_f] of the holonomy.  For abelian groups (ℤ/nℤ), each
--      element is its own class.  For Q₈, there are 5 conjugacy
--      classes: {1}, {−1}, {±i}, {±j}, {±k}.  The particle
--      spectrum = set of non-identity classes.
--
--    • Gauge/RepCapacity.agda  — Defines SpinLabel assigning an
--      irreducible representation to each bond, and the dimension
--      functor  dim : Rep G → ℕ  extracting scalar capacities
--      for the PatchData interface.  The GaugedPatchWitness record
--      packages the dimension-weighted bridge, a Q₈ connection,
--      and a ParticleDefect into a single artifact — the first
--      machine-checked holographic spacetime with matter.
--
--    • Quantum/StarQuantumBridge.agda  — The quantum superposition
--      bridge theorem consumes per-microstate bridge data (from
--      Bulk/StarChainParam.agda) and Q₈ connections defined here
--      to prove ⟨S⟩ = ⟨L⟩ for any finite superposition.
--
--  Architectural role:
--
--    This is a Tier 2 (Observable / Geometry Layer) module in the
--    Gauge directory.  It provides Theorem 6 (Matter as Topological
--    Defects) from the canonical theorem registry.  The three-layer
--    gauge architecture (docs/getting-started/architecture.md) is:
--      Gauge Layer:    FiniteGroup → Connection → Holonomy (this)
--                      → ConjugacyClass → ParticleDefect
--      Capacity Layer: RepCapacity (dim functor → scalar weights)
--      Bridge Layer:   GenericBridge (operates on scalar PatchData)
--
--  Reference:
--    docs/formal/05-gauge-theory.md       (gauge theory — full
--                                          formal treatment)
--    docs/formal/05-gauge-theory.md §6    (Holonomy and Particle
--                                          Defects)
--    docs/formal/05-gauge-theory.md §10   (The Three-Layer
--                                          Architecture)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — theorem registry)
--    docs/instances/star-patch.md §8      (Gauge Enrichment on the
--                                          star patch)
--    docs/getting-started/architecture.md (module dependency DAG)
--    docs/reference/module-index.md       (module description)
--    docs/historical/development-docs/10-frontier.md §13
--                                         (original development plan)
-- ════════════════════════════════════════════════════════════════════