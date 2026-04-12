{-# OPTIONS --cubical --safe --guardedness #-}

module Bulk.TreeChain where

open import Cubical.Foundations.Prelude

open import Util.Scalars
open import Common.TreeSpec

-- ════════════════════════════════════════════════════════════════════
--  BulkView — Bulk-side extracted view of the tree
-- ════════════════════════════════════════════════════════════════════
--
--  The bulk view packages the edge-weight data from the common
--  source specification, interpreted as a 1-dimensional pilot bulk
--  geometry whose edges carry length/weight data.
--
--  For the tree pilot this is intentionally minimal: a single field
--  carrying the weight function.  Later instances (HaPPY-derived)
--  enrich this record with genuine bulk structure such as face
--  incidence data, curvature annotations, or simplicial-complex
--  combinatorics.
--
--  The distinct wrapper type (as opposed to reusing TreeSpec or a
--  raw function type) serves the interface contract: downstream
--  modules (Bridge/TreeObs.agda) consume a BulkView, not a
--  TreeSpec, enforcing the separation between common source and
--  extracted view.  It also enforces that the boundary and bulk
--  sides are semantically distinct even when structurally identical,
--  which is the expected situation for this pilot instance.
--
--  Architectural role:
--    This is a Tier 2 (Observable Layer) module.  It extracts the
--    bulk-side observable lookup from the common source
--    specification defined in Common/TreeSpec.agda.  The boundary-
--    side counterpart is BoundaryView in Boundary/TreeCut.agda.
--
--  Reference:
--    docs/getting-started/architecture.md   (Observable Layer)
--    docs/instances/tree-pilot.md §5        (observable packages)
--    docs/formal/03-holographic-bridge.md §2 (pointwise agreement)
-- ════════════════════════════════════════════════════════════════════

record BulkView : Type₀ where
  field
    weight : Edge → ℚ≥0

-- ════════════════════════════════════════════════════════════════════
--  πbulk — Bulk extraction function
-- ════════════════════════════════════════════════════════════════════
--
--  Projects the edge-weight data from the common source into the
--  bulk view.  For the tree pilot this is a trivial projection;
--  later instances perform genuine structural extraction (e.g.,
--  constructing the dual graph of a triangulation, or restricting
--  to interior edges of a simplicial complex).
--
--  Critically, the weight field of the resulting BulkView is
--  definitionally equal to  TreeSpec.edgeWeight c , so that scalar
--  constants flowing into L-min inherit the same normal forms as
--  those flowing into the boundary-side S-cut via π∂.  This enables
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

πbulk : TreeSpec → BulkView
πbulk c .BulkView.weight = TreeSpec.edgeWeight c

-- ════════════════════════════════════════════════════════════════════
--  L-min — Bulk minimal separating-chain length functional
-- ════════════════════════════════════════════════════════════════════
--
--  For each representative boundary region, L-min returns the total
--  weight of the minimal chain (set of edges) in the tree's
--  1-skeleton that separates that region from its complement.
--
--  In the 2D setting this is the discrete bulk-side analogue of the
--  Ryu–Takayanagi minimal-area surface; for our 1D tree pilot, the
--  "chain" is simply the minimal-weight edge cut in the tree.
--
--  This is a specification-level lookup realization: the values are
--  taken directly from the finite separator table rather than
--  computed by a generic shortest-path or chain-minimization
--  algorithm.  The purpose of the tree pilot is to validate the
--  packaging and bridge architecture, not to formalize graph
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
--    regL₁    →  chain {L₁–A}          →  length 1
--    regL₂    →  chain {L₂–A}          →  length 1
--    regR₁    →  chain {B–R₁}          →  length 1
--    regR₂    →  chain {B–R₂}          →  length 1
--    regL₁L₂  →  chain {A–Root}        →  length 2
--    regL₂R₁  →  chain {L₂–A, B–R₁}    →  length 2
--    regR₁R₂  →  chain {Root–B}        →  length 2
--    regR₂L₁  →  chain {L₁–A, B–R₂}    →  length 2
--
--  All 8 values documented in docs/instances/tree-pilot.md §4
--  (min-cut / observable agreement table).
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

L-min : BulkView → Region → ℚ≥0
L-min kv regL₁   = 1q
L-min kv regL₂   = 1q
L-min kv regR₁   = 1q
L-min kv regR₂   = 1q
L-min kv regL₁L₂ = 2q
L-min kv regL₂R₁ = 2q
L-min kv regR₁R₂ = 2q
L-min kv regR₂L₁ = 2q