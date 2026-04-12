{-# OPTIONS --cubical --safe --guardedness #-}

module Boundary.TreeCut where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.TreeSpec

-- ════════════════════════════════════════════════════════════════════
--  BoundaryView — Boundary-side extracted view of the tree
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary view packages the edge-weight data from the common
--  source specification, interpreted as a boundary-side cut system.
--
--  For the tree pilot this is intentionally minimal: a single field
--  carrying the weight function.  Later instances (HaPPY-derived)
--  enrich this record with boundary-specific structure such as
--  cyclic ordering witnesses or boundary-label data.
--
--  The distinct wrapper type (as opposed to reusing TreeSpec or a
--  raw function type) serves the interface contract: downstream
--  modules (Bridge/TreeObs.agda) consume a BoundaryView, not a
--  TreeSpec, enforcing the separation between common source and
--  extracted view.
--
--  Architectural role:
--    This is a Tier 2 (Observable Layer) module.  It extracts the
--    boundary-side observable lookup from the common source
--    specification defined in Common/TreeSpec.agda.  The bulk-side
--    counterpart is BulkView in Bulk/TreeChain.agda.
--
--  Reference:
--    docs/getting-started/architecture.md   (Observable Layer)
--    docs/instances/tree-pilot.md §5        (observable packages)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement)
-- ════════════════════════════════════════════════════════════════════

record BoundaryView : Type₀ where
  field
    weight : Edge → ℚ≥0

-- ════════════════════════════════════════════════════════════════════
--  π∂ — Boundary extraction function
-- ════════════════════════════════════════════════════════════════════
--
--  Projects the edge-weight data from the common source into the
--  boundary view.  For the tree pilot this is a trivial projection;
--  later instances perform genuine structural extraction (e.g.,
--  restricting to boundary-adjacent edges of a tiling).
--
--  Critically, the weight field of the resulting BoundaryView is
--  definitionally equal to  TreeSpec.edgeWeight c , so that scalar
--  constants flowing into S-cut inherit the same normal forms as
--  those flowing into the bulk-side L-min via πbulk.  This enables
--  the refl proofs in tree-pointwise (Bridge/TreeObs.agda).
--
--  The shared-constants discipline — defining 1q and 2q once in
--  Util/Scalars.agda and importing them into both Boundary and
--  Bulk modules — is the foundational invariant enabling all
--  refl-based pointwise agreement proofs.
--
--  Reference:
--    docs/formal/02-foundations.md §6.3     (shared-constants discipline)
--    docs/instances/tree-pilot.md §7        (scalar representation)
-- ════════════════════════════════════════════════════════════════════

π∂ : TreeSpec → BoundaryView
π∂ c .BoundaryView.weight = TreeSpec.edgeWeight c

-- ════════════════════════════════════════════════════════════════════
--  S-cut — Boundary min-cut entropy functional
-- ════════════════════════════════════════════════════════════════════
--
--  For each representative boundary region, S-cut returns the total
--  weight of the minimal edge-cut separating that region from its
--  complement in the weighted tree.
--
--  This is a specification-level lookup realization: the values are
--  taken directly from the finite separator table rather than
--  computed by a generic min-cut algorithm.  The purpose of the
--  tree pilot is to validate the packaging and bridge architecture,
--  not to formalize graph search.  Generic algorithmic
--  implementations belong in later phases, after the architecture
--  has been validated on this known-good instance.
--
--  The BoundaryView argument is accepted but not inspected: every
--  clause returns a fixed constant from Util.Scalars.  This is
--  deliberate — the lookup table IS the specification for this
--  instance.  In a future generic implementation, S-cut would
--  compute from the weight data inside the BoundaryView.
--
--  Mathematical justification (separator witnesses):
--
--    regL₁    →  separator {L₁–A}           →  weight 1
--    regL₂    →  separator {L₂–A}           →  weight 1
--    regR₁    →  separator {B–R₁}           →  weight 1
--    regR₂    →  separator {B–R₂}           →  weight 1
--    regL₁L₂  →  separator {A–Root}         →  weight 2
--    regL₂R₁  →  separator {L₂–A, B–R₁}    →  weight 2
--    regR₁R₂  →  separator {Root–B}         →  weight 2
--    regR₂L₁  →  separator {L₁–A, B–R₂}    →  weight 2
--
--  All 8 values verified numerically by
--  sim/prototyping/01_happy_patch_cuts.py and documented in
--  docs/instances/tree-pilot.md §4 (min-cut / observable agreement).
--
--  The constants 1q and 2q are imported from Util.Scalars (where
--  1q = 1 and 2q = 2 as natural numbers).  They must NOT be
--  reconstructed independently on each side — identical normal
--  forms are required for the refl proofs of pointwise observable
--  agreement in tree-pointwise (Bridge/TreeObs.agda).  This
--  shared-constants discipline is documented in
--  docs/formal/02-foundations.md §6.3.
--
--  Reference:
--    docs/instances/tree-pilot.md §4       (min-cut / observable agreement)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement path)
--    docs/formal/02-foundations.md §6.3     (shared-constants discipline)
--    docs/reference/module-index.md         (module description)
-- ════════════════════════════════════════════════════════════════════

S-cut : BoundaryView → Region → ℚ≥0
S-cut bv regL₁   = 1q
S-cut bv regL₂   = 1q
S-cut bv regR₁   = 1q
S-cut bv regR₂   = 1q
S-cut bv regL₁L₂ = 2q
S-cut bv regL₂R₁ = 2q
S-cut bv regR₁R₂ = 2q
S-cut bv regR₂L₁ = 2q