{-# OPTIONS --cubical --safe --guardedness #-}

module Bridge.BridgeWitness where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.Univalence

-- ════════════════════════════════════════════════════════════════════
--  BridgeWitness — Universal interface for holographic bridge results
-- ════════════════════════════════════════════════════════════════════
--
--  This record packages the data and proofs constituting a
--  Univalence bridge (Phase 3C) into a single inspectable artifact.
--  It is the counterpart of  GaussBonnetWitness
--  (Bulk/GaussBonnet.agda) for the bridge side of the project.
--
--  The record captures:
--
--    • Two observable types (boundary-certified and bulk-certified)
--    • Canonical inhabitants (the concrete observable bundles)
--    • The exact type equivalence between them
--    • Verification that transport along the resulting  ua  path
--      carries the boundary instance to the bulk instance
--
--  This is the **Milestones 3–4 deliverable** from §6.9 of
--  docs/06-challenges.md:
--
--    Milestone 3:  "A well-typed common source specification
--    producing both boundary and bulk views.  Observable packages
--    extracted as record types from the common source."
--
--    Milestone 4:  "An exact equivalence between boundary and bulk
--    observable packages for at least one concrete instance.
--    Transport along the Univalence path producing a verified
--    translator."
--
--  History and motivation:
--
--    Originally defined in  Bridge/EnrichedStarEquiv.agda  §1,
--    where it was first instantiated for the 6-tile star patch.
--    As the repository grew, the same record type was consumed by
--    increasingly many downstream modules:
--
--      • Bridge/GenericBridge.agda        (the generic theorem)
--      • Bridge/GenericValidation.agda    (retroactive validation)
--      • Bridge/SchematicTower.agda       (tower assembly)
--      • Bridge/WickRotation.agda         (dS/AdS coherence)
--      • Bridge/FilledEquiv.agda          (11-tile bridge)
--      • Bridge/Honeycomb3DEquiv.agda     (3D bridge)
--      • Bridge/Dense50Equiv.agda         (Dense-50 bridge)
--      • Bridge/Dense100Equiv.agda        (Dense-100 bridge)
--
--    All of these had to import from  Bridge.EnrichedStarEquiv
--    using (BridgeWitness) , creating an architectural dependency
--    on the star-patch-specific enriched bridge just to access the
--    record type.  This dependency was semantically wrong: the
--    record itself is curvature-agnostic and geometry-agnostic.
--
--    Promoting  BridgeWitness  to its own leaf module breaks this
--    dependency chain.  Downstream modules now import from
--    Bridge.BridgeWitness  instead of  Bridge.EnrichedStarEquiv ,
--    making the dependency graph honest: generic infrastructure
--    depends only on abstract interfaces, not on per-instance
--    implementations.
--
--  Field naming:
--
--    The fields are named  BdyTy  and  BulkTy  (not  ObsBdy /
--    ObsBulk ) to avoid clashing with imported projection functions
--    of the same name in modules that also import from
--    Bridge.StarObs  or similar.  Agda's scope checker treats
--    record field declarations as names at the module level, so a
--    field named  ObsBulk  would collide with the imported
--    projection function  ObsBulk : StarSpec → ObsPackage Region
--    from  Bridge.StarObs .
--
--  Universe level:
--
--    The record lives in  Type₁  because it stores types as fields.
--    This is the correct universe level:  Type₀  values inhabit
--    Type₀ , but the types themselves are elements of  Type₁ .
--
--  Reference:
--    docs/repo-close.md    (Architectural Rewiring Recommendation §1)
--    docs/10-frontier.md §5.4   (Step 2 — The Generic Bridge Theorem)
--    docs/10-frontier.md §5.6   (The Inductive Tower)
-- ════════════════════════════════════════════════════════════════════

record BridgeWitness : Type₁ where
  field
    -- The two enriched observable types
    BdyTy              : Type₀
    BulkTy             : Type₀

    -- Canonical inhabitants (the concrete observable bundles)
    bdy-data           : BdyTy
    bulk-data          : BulkTy

    -- The exact type equivalence
    bridge             : BdyTy ≃ BulkTy

    -- Transport verification:
    --   transporting the boundary bundle along  ua bridge
    --   yields the bulk bundle
    transport-verified : transport (ua bridge) bdy-data ≡ bulk-data