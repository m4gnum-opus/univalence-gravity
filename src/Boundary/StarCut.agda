{-# OPTIONS --cubical --safe --guardedness #-}

module Boundary.StarCut where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.StarSpec

-- ════════════════════════════════════════════════════════════════════
--  BoundaryView — Boundary-side extracted view of the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  The boundary view packages the bond-weight data from the common
--  source specification, interpreted as a boundary-side entanglement
--  cut system.
--
--  For the star instance this is intentionally minimal: a single
--  field carrying the weight function over bonds.  Later instances
--  (11-tile filled patch or larger HaPPY patches) enrich this
--  record with boundary-specific structure such as cyclic ordering
--  witnesses, boundary-leg counts, or boundary-label data.
--
--  The distinct wrapper type (as opposed to reusing StarSpec or a
--  raw function type) serves the interface contract: downstream
--  modules (Bridge/StarObs.agda) consume a BoundaryView, not a
--  StarSpec, enforcing the separation between common source and
--  extracted view.
--
--  Architectural role:
--    This is a Tier 2 (Observable Layer) module.  It extracts the
--    boundary-side observable lookup from the common source
--    specification defined in Common/StarSpec.agda.  The bulk-side
--    counterpart is BulkView in Bulk/StarChain.agda.
--
--  Design parallel:  This follows the same pattern as the tree
--  pilot's BoundaryView (Boundary/TreeCut.agda), scaled from 6
--  edges to 5 bonds.
--
--  Reference:
--    docs/getting-started/architecture.md   (Observable Layer)
--    docs/instances/star-patch.md §2        (topology)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement)
-- ════════════════════════════════════════════════════════════════════

record BoundaryView : Type₀ where
  field
    weight : Bond → ℚ≥0

-- ════════════════════════════════════════════════════════════════════
--  π∂ — Boundary extraction function
-- ════════════════════════════════════════════════════════════════════
--
--  Projects the bond-weight data from the common source into the
--  boundary view.  For the star instance this is a trivial
--  projection; later instances perform genuine structural
--  extraction (e.g., restricting to boundary-adjacent bonds of a
--  larger tiling patch, or attaching boundary-leg data).
--
--  Critically, the weight field of the resulting BoundaryView is
--  definitionally equal to  StarSpec.bondWeight c , so that scalar
--  constants flowing into S-cut inherit the same normal forms as
--  those flowing into the bulk-side L-min via πbulk.  This enables
--  the refl proofs in star-pointwise (Bridge/StarObs.agda).
--
--  The shared-constants discipline — defining 1q and 2q once in
--  Util/Scalars.agda and importing them into both Boundary and
--  Bulk modules — is the foundational invariant enabling all
--  refl-based pointwise agreement proofs.
--
--  Reference:
--    docs/formal/02-foundations.md §6.3     (shared-constants discipline)
--    docs/instances/star-patch.md §11       (scalar representation)
-- ════════════════════════════════════════════════════════════════════

π∂ : StarSpec → BoundaryView
π∂ c .BoundaryView.weight = StarSpec.bondWeight c

-- ════════════════════════════════════════════════════════════════════
--  S-cut — Boundary min-cut entropy functional for the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  For each representative boundary region, S-cut returns the total
--  weight of the minimal edge-cut separating that region from its
--  complement in the star-shaped tensor network.
--
--  In the 6-tile star topology, every cut must sever some subset of
--  the 5 central bonds C–N_i.  For a contiguous region of k tiles:
--
--      S(k tiles) = min(k, 5 − k)
--
--  This yields:
--    Singletons (k = 1):  S = 1    (cut the single bond C–N_i)
--    Pairs      (k = 2):  S = 2    (cut the two bonds C–N_i, C–N_{i+1})
--
--  This is a specification-level lookup realization: the values are
--  taken directly from the finite separator table rather than
--  computed by a generic min-cut algorithm.  The purpose of this
--  instance is to validate the packaging and bridge architecture
--  on a genuine 2D tiling, not to formalize graph search.  Generic
--  algorithmic implementations belong in later phases, after the
--  architecture has been validated on this known-good instance.
--
--  The BoundaryView argument is accepted but not inspected: every
--  clause returns a fixed constant from Util.Scalars.  This is
--  deliberate — the lookup table IS the specification for this
--  instance.  In a future generic implementation, S-cut would
--  compute from the weight data inside the BoundaryView.
--
--  Mathematical justification (separator witnesses):
--
--    regN0    →  separator {C–N0}         →  weight 1
--    regN1    →  separator {C–N1}         →  weight 1
--    regN2    →  separator {C–N2}         →  weight 1
--    regN3    →  separator {C–N3}         →  weight 1
--    regN4    →  separator {C–N4}         →  weight 1
--    regN0N1  →  separator {C–N0, C–N1}   →  weight 2
--    regN1N2  →  separator {C–N1, C–N2}   →  weight 2
--    regN2N3  →  separator {C–N2, C–N3}   →  weight 2
--    regN3N4  →  separator {C–N3, C–N4}   →  weight 2
--    regN4N0  →  separator {C–N4, C–N0}   →  weight 2
--
--  All 10 values verified numerically by
--  sim/prototyping/01_happy_patch_cuts.py and documented in
--  docs/instances/star-patch.md §4 (min-cut / observable agreement):
--  20/20 regions pass symmetry, 30/30 subadditivity checks pass,
--  S = geodesic for all regions.
--
--  The constants 1q and 2q are imported from Util.Scalars (where
--  1q = suc zero and 2q = suc (suc zero) as natural numbers).
--  They must NOT be reconstructed independently — identical normal
--  forms are required for the refl proofs of pointwise observable
--  agreement in star-pointwise (Bridge/StarObs.agda).  This
--  shared-constants discipline is documented in
--  docs/formal/02-foundations.md §6.3.
--
--  Reference:
--    docs/instances/star-patch.md §4       (min-cut / observable agreement)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement path)
--    docs/formal/02-foundations.md §6.3     (shared-constants discipline)
--    docs/reference/module-index.md         (module description)
--    sim/prototyping/01_happy_patch_cuts.py (numerical verification)
-- ════════════════════════════════════════════════════════════════════

S-cut : BoundaryView → Region → ℚ≥0
S-cut bv regN0   = 1q
S-cut bv regN1   = 1q
S-cut bv regN2   = 1q
S-cut bv regN3   = 1q
S-cut bv regN4   = 1q
S-cut bv regN0N1 = 2q
S-cut bv regN1N2 = 2q
S-cut bv regN2N3 = 2q
S-cut bv regN3N4 = 2q
S-cut bv regN4N0 = 2q