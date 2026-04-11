{-# OPTIONS --cubical --safe --guardedness #-}

module Gauge.Connection where

open import Cubical.Foundations.Prelude

open import Gauge.FiniteGroup


-- ════════════════════════════════════════════════════════════════════
--  §1.  GaugeConnection — Assignment of group elements to bonds
-- ════════════════════════════════════════════════════════════════════
--
--  A gauge connection ω on a finite group G over a bond type B
--  assigns a group element  g_b ∈ G.Carrier  to each bond  b : B .
--
--  In lattice gauge theory (Wilson 1974), this assignment determines
--  the parallel transport along each bond of the discrete network.
--  The holonomy (Wilson loop) around a face is the ordered product
--  of these parallel transports along the face boundary.
--
--  Convention:  each bond has a fixed "forward" orientation (implicit
--  in its constructor name, e.g., bCN0 goes from C to N0).  The
--  assign  field gives the group element for the forward direction.
--  Traversing a bond in the reverse direction yields the group
--  inverse:  g_ē = inv(g_e) .  This convention is enforced by
--  readBond  (§3).
--
--  The record is parameterized by both the group and the bond type.
--  Both are fixed for any given connection.
--
--  Reference:
--    docs/10-frontier.md §13.3  (lattice gauge theory on the network)
--    docs/10-frontier.md §13.7  (three-layer architecture)
--    docs/10-frontier.md §13.8  (module plan: GaugeConnection, readBond)
--    docs/10-frontier.md §13.9  (Phase M.1)
-- ════════════════════════════════════════════════════════════════════

record GaugeConnection (G : FiniteGroup) (BondTy : Type₀) : Type₀ where
  field
    assign : BondTy → FiniteGroup.Carrier G


-- ════════════════════════════════════════════════════════════════════
--  §2.  Dir — Bond traversal direction
-- ════════════════════════════════════════════════════════════════════
--
--  Each bond has a fixed forward orientation.  When computing
--  holonomy around a face, some bonds are traversed in the forward
--  direction and some in reverse.  The  Dir  type tags the
--  direction of traversal.
--
--  In the physics interpretation:
--    fwd  =  parallel transport from source to target
--    rev  =  parallel transport from target to source  (= inverse)
--
--  The face boundary data (Gauge/Holonomy.agda) will produce a
--  list of  (Bond × Dir)  pairs specifying how each bond in the
--  face boundary is traversed.  readBond  then applies  inv  when
--  the direction is  rev .
-- ════════════════════════════════════════════════════════════════════

data Dir : Type₀ where
  fwd rev : Dir


-- ════════════════════════════════════════════════════════════════════
--  §3.  readBond — Direction-aware bond reading
-- ════════════════════════════════════════════════════════════════════
--
--  Given a connection  ω , a direction  d , and a bond  b :
--
--    readBond ω fwd b  =  ω.assign b             (the stored element)
--    readBond ω rev b  =  G.inv (ω.assign b)     (the group inverse)
--
--  This implements the lattice gauge theory convention  g_ē = g_e⁻¹ .
--
--  Downstream usage (Gauge/Holonomy.agda):  the holonomy around a
--  face with directed boundary  [(b₁,d₁), …, (bₙ,dₙ)]  is:
--
--    holonomy ω f  =  readBond ω d₁ b₁  ·  readBond ω d₂ b₂
--                     ·  ⋯  ·  readBond ω dₙ bₙ
-- ════════════════════════════════════════════════════════════════════

readBond :
  {G : FiniteGroup} {BondTy : Type₀}
  → GaugeConnection G BondTy → Dir → BondTy
  → FiniteGroup.Carrier G
readBond {G} conn fwd b = GaugeConnection.assign conn b
readBond {G} conn rev b = FiniteGroup.inv G (GaugeConnection.assign conn b)


-- ════════════════════════════════════════════════════════════════════
--  §4.  readBond-rev — Reverse equals inverse of forward
-- ════════════════════════════════════════════════════════════════════
--
--  readBond ω rev b  ≡  G.inv (readBond ω fwd b)
--
--  This is definitional: both sides reduce to  inv (assign b) .
--  The proof is  refl .  The lemma is exported for downstream
--  modules that need the identification explicitly.
-- ════════════════════════════════════════════════════════════════════

readBond-rev :
  {G : FiniteGroup} {BondTy : Type₀}
  → (conn : GaugeConnection G BondTy)
  → (b : BondTy)
  → readBond {G} conn rev b
    ≡ FiniteGroup.inv G (readBond {G} conn fwd b)
readBond-rev _ _ = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  flatConnection — The vacuum (trivial) connection
-- ════════════════════════════════════════════════════════════════════
--
--  The flat (vacuum) connection assigns the group identity  ε  to
--  every bond.  A flat connection has trivial holonomy around every
--  face: the product of identities is the identity.
--
--  This is the "empty space" configuration — no matter, no fields,
--  no defects.  A ParticleDefect (docs/10-frontier.md §13.6) is
--  defined as a face whose holonomy under a given connection differs
--  from the identity.
--
--  Reference:
--    docs/10-frontier.md §13.3  ("The vacuum (empty space) is a
--    flat connection: W_f = e (the identity) for every face f.")
-- ════════════════════════════════════════════════════════════════════

flatConnection :
  (G : FiniteGroup) {BondTy : Type₀}
  → GaugeConnection G BondTy
flatConnection G .GaugeConnection.assign _ = FiniteGroup.ε G


-- ════════════════════════════════════════════════════════════════════
--  §6.  inv-ε — The inverse of the identity is the identity
-- ════════════════════════════════════════════════════════════════════
--
--  A standard group-theory lemma:  inv(ε) = ε .
--
--  Proof:
--    inv ε
--      ≡ inv ε · ε     (by sym (·-identityʳ (inv ε)))
--      ≡ ε             (by ·-inverseˡ ε)
--
--  For concrete finite groups (Z2, Z3, Q8),  inv ε = ε  holds by
--  refl  (definitional), but the generic lemma is needed for
--  parameterized proofs over arbitrary  FiniteGroup  instances.
-- ════════════════════════════════════════════════════════════════════

inv-ε : (G : FiniteGroup)
  → FiniteGroup.inv G (FiniteGroup.ε G) ≡ FiniteGroup.ε G
inv-ε G =
    sym (FiniteGroup.·-identityʳ G (FiniteGroup.inv G (FiniteGroup.ε G)))
  ∙ FiniteGroup.·-inverseˡ G (FiniteGroup.ε G)


-- ════════════════════════════════════════════════════════════════════
--  §7.  Flat connection properties
-- ════════════════════════════════════════════════════════════════════
--
--  readBond  returns ε in the forward direction (definitional) and
--  inv(ε) in the reverse direction (which equals ε by inv-ε).
-- ════════════════════════════════════════════════════════════════════

-- Forward direction:  readBond (flat G) fwd b ≡ ε
-- Definitional — the assign field is  λ _ → ε .
readFlat-fwd :
  (G : FiniteGroup) {BondTy : Type₀}
  → (b : BondTy)
  → readBond {G} (flatConnection G {BondTy}) fwd b ≡ FiniteGroup.ε G
readFlat-fwd _ _ = refl

-- Reverse direction:  readBond (flat G) rev b ≡ ε
-- Uses inv-ε because  readBond (flat G) rev b  reduces to  inv ε .
readFlat-rev :
  (G : FiniteGroup) {BondTy : Type₀}
  → (b : BondTy)
  → readBond {G} (flatConnection G {BondTy}) rev b ≡ FiniteGroup.ε G
readFlat-rev G _ = inv-ε G


-- ════════════════════════════════════════════════════════════════════
--  §8.  Star-patch concrete connections  (ℤ/2ℤ)
-- ════════════════════════════════════════════════════════════════════
--
--  Concrete gauge connections on the 6-tile star patch bond type
--  (Bond from Common/StarSpec.agda) with gauge group ℤ/2ℤ.
--
--  Bond has 5 constructors:  bCN0 bCN1 bCN2 bCN3 bCN4 .
--  Z2 has 2 constructors:   e0 (identity), e1 (generator).
--
--  Two connections are provided:
--
--    starFlatZ2      — all bonds → e0  (the vacuum connection)
--    starNontrivZ2   — bCN0 → e1, rest → e0  (one excited bond)
--
--  On the 5-bond star graph (which is a TREE), neither connection
--  has any face cycles to compute holonomy around.  The genuine
--  defect test requires the 11-tile filled patch (which has 4-cycles
--  in the bond graph);  this is handled in Gauge/Holonomy.agda.
--
--  The star-patch connections serve as:
--    (a) smoke tests that the GaugeConnection infrastructure works
--        for concrete groups and bond types;
--    (b) building blocks for the filled-patch connection (which
--        extends the star assignment to the 10 additional G-bonds).
--
--  Reference:
--    docs/10-frontier.md §13.9  (Phase M.1 — instantiate on the
--    6-tile star patch with ℤ/2ℤ)
-- ════════════════════════════════════════════════════════════════════

open import Common.StarSpec using (Bond ; bCN0 ; bCN1 ; bCN2 ; bCN3 ; bCN4)


-- ── starFlatZ2 — Flat (vacuum) ℤ/2 connection on the star ─────────

starFlatZ2 : GaugeConnection ℤ/2 Bond
starFlatZ2 = flatConnection ℤ/2


-- ── starNontrivZ2 — Non-trivial ℤ/2 connection on the star ────────
--
--  Assigns the generator e1 to bond bCN0 and the identity e0 to
--  all other bonds.  This is the simplest non-flat assignment:
--  at least one bond carries a non-identity element.
--
--  When this assignment is extended to the 15-bond filled patch
--  (with the remaining 10 G-bonds set to e0), faces adjacent to
--  bond bCN0 will have non-trivial holonomy ( ≠ e0 ), producing
--  a ParticleDefect at the corresponding face.

starNontrivZ2 : GaugeConnection ℤ/2 Bond
starNontrivZ2 .GaugeConnection.assign bCN0 = e1
starNontrivZ2 .GaugeConnection.assign bCN1 = e0
starNontrivZ2 .GaugeConnection.assign bCN2 = e0
starNontrivZ2 .GaugeConnection.assign bCN3 = e0
starNontrivZ2 .GaugeConnection.assign bCN4 = e0


-- ════════════════════════════════════════════════════════════════════
--  §9.  Star-patch concrete connection  (ℤ/3ℤ)
-- ════════════════════════════════════════════════════════════════════
--
--  A ℤ/3ℤ connection demonstrates the NON-TRIVIAL inverse behavior
--  that is invisible in ℤ/2ℤ (where every element is self-inverse).
--
--  In ℤ/3ℤ:  inv(z1) = z2 ≠ z1 .
--
--  So  readBond conn rev bCN0  (when bCN0 carries z1) gives  z2 ,
--  which is a DIFFERENT element from readBond conn fwd bCN0 = z1 .
--  This verifies that the orientation convention  g_ē = g_e⁻¹
--  produces genuinely different values in the forward and reverse
--  directions for non-self-inverse elements.
-- ════════════════════════════════════════════════════════════════════

open import Gauge.ZMod using (Z3 ; z0 ; z1 ; z2 ; ℤ/3)

starNontrivZ3 : GaugeConnection ℤ/3 Bond
starNontrivZ3 .GaugeConnection.assign bCN0 = z1
starNontrivZ3 .GaugeConnection.assign bCN1 = z0
starNontrivZ3 .GaugeConnection.assign bCN2 = z0
starNontrivZ3 .GaugeConnection.assign bCN3 = z0
starNontrivZ3 .GaugeConnection.assign bCN4 = z0


-- ════════════════════════════════════════════════════════════════════
--  §10.  Regression tests
-- ════════════════════════════════════════════════════════════════════
--
--  These verify that readBond computes the expected values on
--  concrete connections, groups, bonds, and directions.  All hold
--  by refl because pattern matching on the Dir, Bond, and group
--  constructors reduces judgmentally.
-- ════════════════════════════════════════════════════════════════════

private

  -- ── ℤ/2 flat connection ──────────────────────────────────────
  -- Forward: all bonds → e0
  check-flat-Z2-fwd-bCN0 : readBond starFlatZ2 fwd bCN0 ≡ e0
  check-flat-Z2-fwd-bCN0 = refl

  check-flat-Z2-fwd-bCN3 : readBond starFlatZ2 fwd bCN3 ≡ e0
  check-flat-Z2-fwd-bCN3 = refl

  -- Reverse: invZ2 e0 = e0  (e0 is self-inverse in ℤ/2)
  check-flat-Z2-rev-bCN0 : readBond starFlatZ2 rev bCN0 ≡ e0
  check-flat-Z2-rev-bCN0 = refl

  check-flat-Z2-rev-bCN4 : readBond starFlatZ2 rev bCN4 ≡ e0
  check-flat-Z2-rev-bCN4 = refl

  -- ── ℤ/2 non-trivial connection ──────────────────────────────
  -- Forward: bCN0 → e1
  check-nontrivZ2-fwd-bCN0 : readBond starNontrivZ2 fwd bCN0 ≡ e1
  check-nontrivZ2-fwd-bCN0 = refl

  -- Forward: bCN1 → e0
  check-nontrivZ2-fwd-bCN1 : readBond starNontrivZ2 fwd bCN1 ≡ e0
  check-nontrivZ2-fwd-bCN1 = refl

  -- Reverse of bCN0: invZ2 e1 = e1  (e1 is self-inverse in ℤ/2ℤ!)
  -- This is the degenerate case: ℤ/2ℤ elements are all self-inverse,
  -- so forward and reverse give the same value.
  check-nontrivZ2-rev-bCN0 : readBond starNontrivZ2 rev bCN0 ≡ e1
  check-nontrivZ2-rev-bCN0 = refl

  -- Reverse of bCN2: invZ2 e0 = e0
  check-nontrivZ2-rev-bCN2 : readBond starNontrivZ2 rev bCN2 ≡ e0
  check-nontrivZ2-rev-bCN2 = refl

  -- ── ℤ/3 non-trivial connection (the interesting case) ───────
  -- Forward: bCN0 → z1
  check-nontrivZ3-fwd-bCN0 : readBond starNontrivZ3 fwd bCN0 ≡ z1
  check-nontrivZ3-fwd-bCN0 = refl

  -- Forward: bCN1 → z0
  check-nontrivZ3-fwd-bCN1 : readBond starNontrivZ3 fwd bCN1 ≡ z0
  check-nontrivZ3-fwd-bCN1 = refl

  -- Reverse of bCN0: invZ3 z1 = z2  (NOT z1!)
  -- This demonstrates the non-trivial inverse:
  --   traversing bond bCN0 backward gives a DIFFERENT group element
  --   than traversing it forward.  This is the general situation for
  --   non-self-inverse elements.
  check-nontrivZ3-rev-bCN0 : readBond starNontrivZ3 rev bCN0 ≡ z2
  check-nontrivZ3-rev-bCN0 = refl

  -- Reverse of bCN3: invZ3 z0 = z0  (identity is self-inverse)
  check-nontrivZ3-rev-bCN3 : readBond starNontrivZ3 rev bCN3 ≡ z0
  check-nontrivZ3-rev-bCN3 = refl

  -- ── Generic flat connection: readFlat-fwd is refl ────────────
  check-readFlat-fwd-Z2 : readFlat-fwd ℤ/2 {Bond} bCN0 ≡ refl
  check-readFlat-fwd-Z2 = refl

  check-readFlat-fwd-Z3 : readFlat-fwd ℤ/3 {Bond} bCN0 ≡ refl
  check-readFlat-fwd-Z3 = refl

  -- ── Record field access: assign gives the raw stored value ───
  check-assign-nontrivZ2 :
    GaugeConnection.assign starNontrivZ2 bCN0 ≡ e1
  check-assign-nontrivZ2 = refl

  check-assign-nontrivZ3 :
    GaugeConnection.assign starNontrivZ3 bCN0 ≡ z1
  check-assign-nontrivZ3 = refl


-- ════════════════════════════════════════════════════════════════════
--  §11.  Summary and design notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    GaugeConnection  : FiniteGroup → Type₀ → Type₀
--                       (record with field  assign : BondTy → G.Carrier)
--
--    Dir              : Type₀
--                       (data: fwd | rev)
--
--    readBond         : GaugeConnection G B → Dir → B → G.Carrier
--                       (reads a bond value, applying inv for rev)
--
--    readBond-rev     : readBond ω rev b ≡ inv (readBond ω fwd b)
--                       (definitional: refl)
--
--    flatConnection   : (G : FiniteGroup) → GaugeConnection G B
--                       (assigns ε to every bond)
--
--    inv-ε            : (G : FiniteGroup) → inv ε ≡ ε
--                       (generic group-theory lemma)
--
--    readFlat-fwd     : readBond (flat G) fwd b ≡ ε       (refl)
--    readFlat-rev     : readBond (flat G) rev b ≡ ε       (via inv-ε)
--
--    starFlatZ2       : GaugeConnection ℤ/2 Bond          (all e0)
--    starNontrivZ2    : GaugeConnection ℤ/2 Bond          (bCN0→e1)
--    starNontrivZ3    : GaugeConnection ℤ/3 Bond          (bCN0→z1)
--
--  Downstream modules:
--
--    src/Gauge/Holonomy.agda
--      — Imports GaugeConnection, Dir, readBond
--      — Defines holonomy as a fold of readBond over the directed
--        face boundary
--      — Defines isFlat (holonomy ≡ ε for every face)
--      — Defines ParticleDefect (¬(holonomy ≡ ε))
--      — Instantiates on the 11-tile filled patch with ℤ/2:
--        extends starNontrivZ2 to 15 bonds and shows that the
--        face adjacent to bCN0 has non-trivial holonomy
--
--    src/Gauge/ConjugacyClass.agda
--      — The conjugacy class of the holonomy determines the
--        particle species (gauge-invariant)
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Cubical.Foundations.Prelude  — paths, sym, ∙
--      • Gauge.FiniteGroup           — FiniteGroup record, ℤ/2, Z2
--      • Gauge.ZMod                  — ℤ/3, Z3, z0/z1/z2
--      • Common.StarSpec             — Bond, bCN0..bCN4
--
--    The gauge layer is purely additive — no existing module is
--    modified.  The connection assigns algebraic structure to the
--    same bonds used by the flow-graph infrastructure (Boundary/,
--    Bulk/, Bridge/).  The capacity layer (Gauge/RepCapacity.agda)
--    will extract scalar weights from this algebraic structure via
--    the dimension functor, feeding them into the existing PatchData
--    interface.
--
--  Design decisions:
--
--    1.  GaugeConnection is a RECORD (not a type alias for a function)
--        to enable future field extensions (e.g., explicit orientation
--        maps, gauge-transformation equivariance witnesses) without
--        changing the API.
--
--    2.  Dir is a 2-constructor data type (not Bool) to give semantic
--        names to the two traversal directions, improving readability
--        of holonomy specifications.
--
--    3.  readBond takes Dir as a SEPARATE argument (not paired with
--        the bond) to allow partial application and to match the
--        mathematical notation where direction is a property of how
--        a bond is traversed in a specific cycle, not an intrinsic
--        property of the bond itself.
--
--    4.  inv-ε is proven GENERICALLY (for arbitrary FiniteGroup) even
--        though it holds by refl for all three concrete instances
--        (ℤ/2, ℤ/3, Q₈).  This ensures that downstream parameterized
--        proofs (e.g., "any flat connection is flat" in Holonomy.agda)
--        do not need to case-split on the specific group.
--
--    5.  The star-patch connections are defined on the 5-bond star
--        topology from Common/StarSpec.agda.  The 15-bond filled
--        patch topology will be handled in Gauge/Holonomy.agda,
--        which imports PatchFace and faceVertices from
--        Bulk/PatchComplex.agda for face boundary data.
--
--  Reference:
--    docs/10-frontier.md §13     (Adding Data Payloads)
--    docs/10-frontier.md §13.3   (lattice gauge theory formulation)
--    docs/10-frontier.md §13.8   (module plan)
--    docs/10-frontier.md §13.9   (Phase M.1 execution plan)
-- ════════════════════════════════════════════════════════════════════