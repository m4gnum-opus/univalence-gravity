{-# OPTIONS --cubical --safe --guardedness #-}

module Common.ObsPackage where

open import Cubical.Foundations.Prelude
open import Util.Scalars

-- ════════════════════════════════════════════════════════════════════
--  ObsPackage — Shared observable-package record
-- ════════════════════════════════════════════════════════════════════
--
--  A single-field record parameterized by a region index type R.
--
--  Originally extracted from the tree pilot so that all patch
--  instances share the same type signature for the holographic
--  bridge.  Every instance in the repository — Tree, Star, Filled,
--  Honeycomb, Dense-50 through Dense-200, and the {5,4} layer
--  tower (depths 2–7) — imports this record via Common.ObsPackage.
--
--  The region index R is a parameter (not a stored field), keeping
--  ObsPackage R  in  Type₀ .  The single field  obs : R → ℚ≥0
--  carries the observable function (boundary min-cut or bulk
--  minimal chain length, depending on instantiation side).
--
--  Proof-carrying fields (subadditivity, monotonicity witnesses)
--  are intentionally omitted from this record.  They are added in
--  the enriched types  FullBdy / FullBulk  defined in
--  Bridge/FullEnrichedStarObs.agda, keeping the minimal packaging
--  separate from the structural property layer.
--
--  Because the record has a single field, package equality reduces
--  directly to observable-function equality via a record path
--  whose sole component is the obs-field path.  This is exploited
--  in every  *-package-path  definition across the Bridge modules.
--
--  Architectural role:
--    This is a Tier 1 (Specification Layer) module with no internal
--    dependencies beyond Util.Scalars.  It is consumed by all
--    Bridge/*Obs.agda modules to construct boundary and bulk
--    observable packages.
--
--  Reference:
--    docs/getting-started/architecture.md   (Specification Layer)
--    docs/formal/03-holographic-bridge.md   (observable packages)
--    docs/instances/tree-pilot.md §5        (first use)
--    docs/reference/module-index.md         (module description)
-- ════════════════════════════════════════════════════════════════════

record ObsPackage (R : Type₀) : Type₀ where
  field
    obs : R → ℚ≥0