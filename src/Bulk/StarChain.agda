{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.StarChain where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.StarSpec

-- ════════════════════════════════════════════════════════════════════
--  BulkView — Bulk-side extracted view of the 6-tile star
-- ════════════════════════════════════════════════════════════════════
--
--  The bulk view packages the bond-weight data from the common
--  source specification, interpreted as a 2D tiling geometry whose
--  tile-to-tile bonds carry length/weight data.
--
--  For the star instance this is intentionally minimal: a single
--  field carrying the weight function over bonds.  Later instances
--  (11-tile filled patch) will enrich this record with genuine bulk
--  structure such as face incidence data, curvature annotations,
--  vertex classifications, or simplicial-complex combinatorics.
--
--  The distinct wrapper type (as opposed to reusing StarSpec or a
--  raw function type) serves the interface contract: downstream
--  modules (Bridge/StarObs.agda) consume a BulkView, not a
--  StarSpec, enforcing the separation between common source and
--  extracted view.  It also enforces that the boundary and bulk
--  sides are semantically distinct even when structurally identical,
--  which is the expected situation for this instance.
--
--  Design parallel:  This follows the same pattern as the tree
--  pilot's BulkView (Bulk/TreeChain.agda), scaled from 6 edges
--  to 5 bonds, and mirrors the boundary-side BoundaryView in
--  Boundary/StarCut.agda.
-- ════════════════════════════════════════════════════════════════════

record BulkView : Type₀ where
  field
    weight : Bond → ℚ≥0

-- ════════════════════════════════════════════════════════════════════
--  πbulk — Bulk extraction function
-- ════════════════════════════════════════════════════════════════════
--
--  Projects the bond-weight data from the common source into the
--  bulk view.  For the star instance this is a trivial projection;
--  later instances will perform genuine structural extraction
--  (e.g., constructing the dual graph of a triangulation,
--  restricting to interior edges of a simplicial complex, or
--  attaching face incidence and curvature data).
--
--  Critically, the weight field of the resulting BulkView is
--  definitionally equal to  StarSpec.bondWeight c , so that scalar
--  constants flowing into L-min inherit the same normal forms as
--  those flowing into the boundary-side S-cut via π∂.  This enables
--  the refl proofs in star-pointwise (Bridge/StarObs.agda, §11.3
--  of docs/09-happy-instance.md).
-- ════════════════════════════════════════════════════════════════════

πbulk : StarSpec → BulkView
πbulk c .BulkView.weight = StarSpec.bondWeight c

-- ════════════════════════════════════════════════════════════════════
--  L-min — Bulk minimal separating-chain length functional
-- ════════════════════════════════════════════════════════════════════
--
--  For each representative boundary region, L-min returns the total
--  weight of the minimal chain (set of internal bonds) in the star
--  tiling that separates that region from its complement.
--
--  In the 6-tile star topology, every separating chain must sever
--  some subset of the 5 central bonds C–N_i.  For a contiguous
--  region of k tiles:
--
--      L(k tiles) = min(k, 5 − k)
--
--  This yields:
--    Singletons (k = 1):  L = 1    (sever the single bond C–N_i)
--    Pairs      (k = 2):  L = 2    (sever bonds C–N_i, C–N_{i+1})
--
--  In the 2D setting this is the discrete bulk-side analogue of the
--  Ryu–Takayanagi minimal-area surface.  The min-cut always passes
--  through internal bonds (never through boundary legs) in the
--  6-tile star, so the minimal separating-chain length equals the
--  boundary min-cut value for every tile-aligned region.  This is
--  the content of the discrete RT correspondence for this instance,
--  verified numerically by sim/prototyping/01_happy_patch_cuts.py
--  (§3.1 of docs/09-happy-instance.md): S = geodesic for all 20
--  regions.
--
--  This is a specification-level lookup realization: the values are
--  taken directly from the finite separator table (§10.1 of
--  docs/09-happy-instance.md) rather than computed by a generic
--  chain-minimization or shortest-path algorithm.  The purpose of
--  this instance is to validate the packaging and bridge
--  architecture on a genuine 2D tiling, not to formalize graph
--  algorithms.  Generic algorithmic implementations belong in later
--  phases, after the architecture has been validated on this
--  known-good instance.
--
--  The BulkView argument is accepted but not inspected: every
--  clause returns a fixed constant from Util.Scalars.  This is
--  deliberate — the lookup table IS the specification for this
--  instance.  In a future generic implementation, L-min would
--  compute from the weight data inside the BulkView.
--
--  Mathematical justification (minimal separating chains):
--
--    regN0    →  chain {C–N0}          →  length 1
--    regN1    →  chain {C–N1}          →  length 1
--    regN2    →  chain {C–N2}          →  length 1
--    regN3    →  chain {C–N3}          →  length 1
--    regN4    →  chain {C–N4}          →  length 1
--    regN0N1  →  chain {C–N0, C–N1}    →  length 2
--    regN1N2  →  chain {C–N1, C–N2}    →  length 2
--    regN2N3  →  chain {C–N2, C–N3}    →  length 2
--    regN3N4  →  chain {C–N3, C–N4}    →  length 2
--    regN4N0  →  chain {C–N4, C–N0}    →  length 2
--
--  All 10 values verified numerically by
--  sim/prototyping/01_happy_patch_cuts.py (§3.1 of
--  docs/09-happy-instance.md): geodesic equality S = L holds for
--  all 20 regions (including triples and quadruples by complement
--  symmetry).
--
--  The constants 1q and 2q are imported from Util.Scalars (where
--  1q = suc zero and 2q = suc (suc zero) as natural numbers).
--  They must NOT be reconstructed independently — identical normal
--  forms are required for the refl proofs of pointwise observable
--  agreement in star-pointwise (§15.5 of docs/09-happy-instance.md).
-- ════════════════════════════════════════════════════════════════════

L-min : BulkView → Region → ℚ≥0
L-min kv regN0   = 1q
L-min kv regN1   = 1q
L-min kv regN2   = 1q
L-min kv regN3   = 1q
L-min kv regN4   = 1q
L-min kv regN0N1 = 2q
L-min kv regN1N2 = 2q
L-min kv regN2N3 = 2q
L-min kv regN3N4 = 2q
L-min kv regN4N0 = 2q