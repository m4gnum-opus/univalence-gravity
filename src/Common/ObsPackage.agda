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
--  This has been extracted from the TreePilot so that all future
--  instances (Tree, Star, Filled Patch) can share the same exact 
--  type signature for the Univalence bridge.
-- ════════════════════════════════════════════════════════════════════

record ObsPackage (R : Type₀) : Type₀ where
  field
    obs : R → ℚ≥0