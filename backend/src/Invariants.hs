-- | Startup data-integrity checks for the Univalence Gravity backend.
--
--   'validateAll' runs every invariant from
--   @docs\/engineering\/backend-spec-haskell.md@ §6 against the
--   loaded JSON data and returns a (possibly empty) list of
--   human-readable violation messages.  An empty list means all
--   checks pass; a non-empty list causes the server to abort
--   before binding a port (see @Main.hs@ §8).
--
--   The checks implemented here mirror — at the Haskell value level
--   — the properties that were machine-checked by Cubical Agda at
--   the type level.  They serve as a runtime sanity gate: if the
--   JSON export pipeline ever introduces a data corruption, the
--   backend catches it at startup rather than serving broken data.
--
--   __Known limitation (Issue #8):__  The Gauss–Bonnet check
--   (@curvTotal == curvEuler@) is tautological for 3D patches
--   because @18_export_json.py@ sets both fields to the same
--   computed total.  The check is only independently meaningful
--   for 2D patches (filled, desitter) where the two values are
--   derived from separate computations.  A future improvement would
--   verify 3D curvature against the hardcoded Agda-aligned values
--   from @curvature.json@, or skip the Gauss–Bonnet check for
--   patches where no independent 3D Euler characteristic has been
--   formalised.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §6

module Invariants
  ( validateAll
  ) where

import qualified Data.Map.Strict as Map
import qualified Data.Text       as T

import Types


-- ════════════════════════════════════════════════════════════════
--  Public entry point
-- ════════════════════════════════════════════════════════════════

-- | Run every data invariant on the loaded patches and tower
--   levels.  Returns @[]@ when all checks pass.
validateAll :: [Patch] -> [TowerLevel] -> [String]
validateAll patches tower =
     concatMap validatePatch patches
  ++ validateTowerMonotone tower


-- ════════════════════════════════════════════════════════════════
--  Per-patch validation
-- ════════════════════════════════════════════════════════════════

-- | All checks that apply to a single patch.
validatePatch :: Patch -> [String]
validatePatch p =
     validateRegionCount p
  ++ concatMap (validateRegionHalfBound pname) regions
  ++ concatMap (validateRegionHalfSlack pname) regions
  ++ concatMap (validateAreaDecomp pname (patchTiling p)) regions
  ++ validateOrbitConsistency p
  ++ validateGaussBonnet p
  ++ validateHalfBoundMeta p
  where
    pname   = T.unpack (patchName p)
    regions = patchRegionData p


-- ────────────────────────────────────────────────────────────────
--  Region count consistency
-- ────────────────────────────────────────────────────────────────

-- | The @patchRegions@ metadata field must equal the actual length
--   of the @patchRegionData@ list.
--
--   Guards against: truncated or duplicated region data in the
--   JSON export, or a stale @patchRegions@ metadata field.
validateRegionCount :: Patch -> [String]
validateRegionCount p
  | patchRegions p == length (patchRegionData p) = []
  | otherwise =
      [ pname ++ ": region count mismatch: metadata says "
        ++ show (patchRegions p) ++ " but data has "
        ++ show (length (patchRegionData p)) ]
  where
    pname = T.unpack (patchName p)


-- ────────────────────────────────────────────────────────────────
--  Discrete Bekenstein–Hawking half-bound  (§6, prop_halfBound)
-- ────────────────────────────────────────────────────────────────

-- | For every region: @2 * S(A) <= area(A)@.
--
--   This is Theorem 3 (Bridge\/HalfBound.agda) verified by the
--   Agda type-checker on closed ℕ terms.  The runtime check
--   guards against JSON export bugs (e.g. wrong area computation
--   in the Python oracle, or a corrupt min-cut value).
validateRegionHalfBound :: String -> Region -> [String]
validateRegionHalfBound pname r
  | 2 * regionMinCut r <= regionArea r = []
  | otherwise =
      [ pname ++ " region " ++ show (regionId r)
        ++ ": half-bound violated: 2*" ++ show (regionMinCut r)
        ++ " = " ++ show (2 * regionMinCut r)
        ++ " > area " ++ show (regionArea r) ]


-- ────────────────────────────────────────────────────────────────
--  Half-slack consistency
-- ────────────────────────────────────────────────────────────────

-- | When @regionHalfSlack@ is present it must equal
--   @regionArea - 2 * regionMinCut@.
--
--   Guards against: an inconsistency between the three fields,
--   which could occur if the Python export computes the slack
--   from stale min-cut or area values.
validateRegionHalfSlack :: String -> Region -> [String]
validateRegionHalfSlack pname r = case regionHalfSlack r of
  Nothing -> []
  Just hs
    | hs == expected -> []
    | otherwise ->
        [ pname ++ " region " ++ show (regionId r)
          ++ ": half-slack inconsistency: recorded " ++ show hs
          ++ " but area - 2*S = " ++ show expected ]
  where
    expected = regionArea r - 2 * regionMinCut r


-- ────────────────────────────────────────────────────────────────
--  Area decomposition  (§6, prop_areaDecomp)
-- ────────────────────────────────────────────────────────────────

-- | Verify the area decomposition formula:
--
--   @area(A) = faces_per_cell · |A| − 2 · |internal_faces_within_A|@
--
--   Since the JSON data does not include the per-region internal
--   face count, we verify two algebraic consequences that do NOT
--   require it:
--
--   1. @area ≤ faces_per_cell · regionSize@
--      (equality when all faces exit the region — zero internal
--      sharing).
--
--   2. @(faces_per_cell · regionSize − area)@ is non-negative and
--      even (since it equals @2 · internal_faces@, which is an
--      even non-negative integer).
--
--   These two constraints catch a broad class of area-computation
--   bugs (wrong faces-per-cell constant, off-by-one in internal
--   face counting, tiling-type mismatch) without requiring the
--   full adjacency structure.
--
--   Skipped for the 'Tree' tiling, which uses a simplified area
--   proxy (@2 · regionSize@) that does not follow the face-count
--   model.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §6
validateAreaDecomp :: String -> Tiling -> Region -> [String]
validateAreaDecomp pname tiling r = case facesPerCell tiling of
  Nothing  -> []   -- skip for tilings without a face-count area model
  Just fpc ->
    let totalFaces = fpc * regionSize r
        deficit    = totalFaces - regionArea r
    in  [ pname ++ " region " ++ show (regionId r)
          ++ ": area decomposition violated: area "
          ++ show (regionArea r) ++ " > "
          ++ show fpc ++ " * " ++ show (regionSize r)
          ++ " = " ++ show totalFaces
        | regionArea r > totalFaces
        ]
     ++ [ pname ++ " region " ++ show (regionId r)
          ++ ": area decomposition parity violated: "
          ++ show fpc ++ " * " ++ show (regionSize r)
          ++ " - area " ++ show (regionArea r)
          ++ " = " ++ show deficit
          ++ " is odd (must equal 2 * internal_faces)"
        | deficit >= 0
        , odd deficit
        ]


-- | Number of faces (or edges, for 2D) per cell for each tiling.
--
--   Returns 'Nothing' for tilings that do not use the standard
--   face-count boundary area formula.
--
--   @
--   {4,3,5} → 6  (cube: 6 square faces)
--   {5,4}   → 5  (pentagon: 5 edges)
--   {5,3}   → 5  (pentagon: 5 edges)
--   {4,4}   → 4  (square: 4 edges)
--   Tree    → Nothing  (1D: uses simplified 2k proxy)
--   @
facesPerCell :: Tiling -> Maybe Int
facesPerCell Tiling435 = Just 6
facesPerCell Tiling54  = Just 5
facesPerCell Tiling53  = Just 5
facesPerCell Tiling44  = Just 4
facesPerCell Tree      = Nothing


-- ────────────────────────────────────────────────────────────────
--  Orbit consistency  (§6, prop_orbitConsistency)
-- ────────────────────────────────────────────────────────────────

-- | All regions sharing an orbit label must have the same min-cut
--   value.  The orbit classification groups regions by min-cut;
--   a mismatch indicates a corrupt @classify@ function output in
--   the Python oracle.
--
--   Implementation: group regions by orbit label using
--   @Map.fromListWith (++)@, then for each group check that every
--   member's min-cut matches the first member's min-cut.  The
--   first-seen value serves as the representative; any disagreement
--   is reported.
validateOrbitConsistency :: Patch -> [String]
validateOrbitConsistency p =
  concatMap checkGroup (Map.toList grouped)
  where
    pname   = T.unpack (patchName p)
    regions = patchRegionData p

    -- Group all regions by their orbit label.  'fromListWith (++)'
    -- concatenates region lists, preserving insertion order within
    -- each orbit.
    grouped :: Map.Map T.Text [Region]
    grouped = Map.fromListWith (++)
      [ (regionOrbit r, [r]) | r <- regions ]

    checkGroup :: (T.Text, [Region]) -> [String]
    checkGroup (_, [])      = []
    checkGroup (orbit, rs)  =
      let representative = regionMinCut (head rs)
          bad = filter (\r -> regionMinCut r /= representative) rs
      in  [ pname ++ " orbit " ++ T.unpack orbit
            ++ ": inconsistent min-cut — expected "
            ++ show representative ++ " but region "
            ++ show (regionId b) ++ " has " ++ show (regionMinCut b)
          | b <- bad ]


-- ────────────────────────────────────────────────────────────────
--  Gauss–Bonnet  (§6, prop_gaussBonnet)
-- ────────────────────────────────────────────────────────────────

-- | When curvature data is present, the total curvature must equal
--   the Euler characteristic.
--
--   For 2D patches (filled, desitter) this is Theorem 2
--   (Bulk\/GaussBonnet.agda), discharged by @refl@ in Agda, where
--   the two values are computed independently (the curvature from
--   a class-weighted sum, the Euler characteristic from V − E + F).
--
--   __Caveat:__ For 3D patches (dense-50, dense-100, dense-200,
--   honeycomb-3d), the Python export sets @curvEuler = curvTotal@
--   (the same computed value), because no independent 3D Euler
--   characteristic has been formalised in Agda.  Consequently this
--   check is __tautological__ for 3D data — it passes trivially.
--   It remains valuable as a guard against JSON field transposition
--   or corruption, but does not provide an independent Gauss–Bonnet
--   verification for 3D patches.
--
--   A future improvement: for 3D patches, either (a) skip this
--   check entirely, or (b) verify the curvature total against the
--   hardcoded Agda-aligned values from @curvature.json@ rather
--   than relying on self-consistency.
validateGaussBonnet :: Patch -> [String]
validateGaussBonnet p = case patchCurvature p of
  Nothing -> []
  Just cd
    | curvTotal cd == curvEuler cd -> []
    | otherwise ->
        [ pname ++ ": Gauss-Bonnet violated: totalCurvature "
          ++ show (curvTotal cd) ++ " /= eulerChar "
          ++ show (curvEuler cd) ]
  where
    pname = T.unpack (patchName p)


-- ────────────────────────────────────────────────────────────────
--  Half-bound summary metadata
-- ────────────────────────────────────────────────────────────────

-- | When a @HalfBoundData@ summary is present, its @hbViolations@
--   field must be 0 (the Python oracle aborts if any violation is
--   found, so a non-zero value indicates data corruption).
validateHalfBoundMeta :: Patch -> [String]
validateHalfBoundMeta p = case patchHalfBound p of
  Nothing -> []
  Just hb
    | hbViolations hb == 0 -> []
    | otherwise ->
        [ pname ++ ": half-bound summary reports "
          ++ show (hbViolations hb) ++ " violations (expected 0)" ]
  where
    pname = T.unpack (patchName p)


-- ════════════════════════════════════════════════════════════════
--  Tower validation  (§6, prop_towerMonotone)
-- ════════════════════════════════════════════════════════════════

-- | Tower monotonicity: for every consecutive pair of levels where
--   the later level carries a monotonicity witness @(k, \"refl\")@,
--   verify that @maxCut_lo + k == maxCut_hi@.
--
--   Levels whose @tlMonotone@ is @Nothing@ mark the start of a
--   new sub-tower (e.g. the break between the Dense resolution
--   tower and the {5,4} layer tower) and are not checked against
--   their predecessor.
--
--   Guards against: a stale or corrupt monotonicity witness in
--   @tower.json@ that disagrees with the actual maxCut values.
validateTowerMonotone :: [TowerLevel] -> [String]
validateTowerMonotone levels = concatMap checkPair (zip levels (drop 1 levels))
  where
    checkPair :: (TowerLevel, TowerLevel) -> [String]
    checkPair (lo, hi) = case tlMonotone hi of
      Nothing     -> []
      Just (k, _)
        | tlMaxCut lo + k == tlMaxCut hi -> []
        | otherwise ->
            [ "tower: monotone witness mismatch between "
              ++ T.unpack (tlPatchName lo) ++ " (maxCut="
              ++ show (tlMaxCut lo) ++ ") and "
              ++ T.unpack (tlPatchName hi) ++ " (maxCut="
              ++ show (tlMaxCut hi) ++ "): "
              ++ show (tlMaxCut lo) ++ " + " ++ show k
              ++ " /= " ++ show (tlMaxCut hi) ]