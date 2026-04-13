-- | Property-based tests for the data invariants described in
--   @docs\/engineering\/backend-spec-haskell.md@ §6.
--
--   These tests load real JSON data from @data\/@ (the symlink to
--   the repo-root data directory produced by @18_export_json.py@)
--   and verify every invariant that the Agda type-checker enforces
--   at the proof level — serving as a runtime sanity gate against
--   data-export corruption.
--
--   The five named properties from the spec:
--
--     * @prop_halfBound@:        2·S(A) ≤ area(A) for every region
--     * @prop_orbitConsistency@: same orbit ⟹ same min-cut value
--     * @prop_towerMonotone@:    maxCut non-decreasing across tower levels
--     * @prop_gaussBonnet@:      Σκ = χ for every patch with curvature
--     * @prop_areaDecomp@:       area ≤ fpc·k and (fpc·k − area) is even
--
--   Plus additional consistency checks on region counts, half-slack
--   values, half-bound violation counts, region size / cells
--   agreement, and basic value-range sanity.
--
--   Run from the @backend\/@ project root:
--
--   > cabal test

module InvariantSpec (spec) where

import qualified Data.Map.Strict as Map
import qualified Data.Text       as T

import Test.Hspec
import Test.QuickCheck

import DataLoader (loadPatches, loadTower)
import Invariants (validateAll)
import Types


-- | Path to the data directory.  Assumes tests are run from the
--   @backend\/@ project root, where @data\/@ is a symlink (or
--   copy) pointing to the repo-root @data\/@ produced by
--   @sim\/prototyping\/18_export_json.py@.
dataDir :: FilePath
dataDir = "data"


-- | Load patches and tower levels once, shared across all specs
--   via hspec's 'beforeAll'.  If the data directory is missing or
--   any file fails to decode, the test suite aborts immediately
--   with a descriptive 'IOError'.
loadAllData :: IO ([Patch], [TowerLevel])
loadAllData = (,) <$> loadPatches dataDir <*> loadTower dataDir


-- | Sample a random element from a non-empty pool and test a
--   property on it.  If the pool is empty, produce a clear
--   failing 'Property' instead of crashing on @elements []@.
--
--   __Sampling note:__ Each QuickCheck iteration picks ONE random
--   element from the pool.  With the default 100 iterations, this
--   means ~100 random regions are tested across the ~5400-element
--   pool.  This provides probabilistic coverage with good
--   fault-detection power for systematic bugs (e.g. a wrong area
--   formula affecting all regions of a certain size).
--
--   __Exhaustive coverage__ is provided by the @\"validateAll\"@
--   integration test above, which runs every check on every
--   region deterministically.  The property tests here serve as
--   a second, independent verification channel with randomised
--   sampling.
overPool :: Show a => String -> [a] -> (a -> Property) -> Property
overPool label [] _ =
  counterexample (label ++ ": empty pool — no data to test") False
overPool _     xs f = forAll (elements xs) f


-- | Number of faces (or edges, for 2D) per cell for each tiling.
--
--   Returns 'Nothing' for tilings that do not use the standard
--   face-count boundary area formula (e.g. the 1D tree pilot).
--
--   Mirrors 'Invariants.facesPerCell' — duplicated here to keep
--   the test module self-contained and independently readable.
facesPerCell :: Tiling -> Maybe Int
facesPerCell Tiling435 = Just 6
facesPerCell Tiling54  = Just 5
facesPerCell Tiling53  = Just 5
facesPerCell Tiling44  = Just 4
facesPerCell Tree      = Nothing


spec :: Spec
spec = beforeAll loadAllData $ do

  -- ──────────────────────────────────────────────────────────────
  --  Data-loading sanity (run first — prerequisite for all below)
  -- ──────────────────────────────────────────────────────────────

  describe "data loading sanity" $ do
    it "loaded at least 10 patches" $ \(patches, _) ->
      length patches `shouldSatisfy` (>= 10)

    it "loaded at least 5 tower levels" $ \(_, tower) ->
      length tower `shouldSatisfy` (>= 5)

    it "at least one patch has curvature data" $ \(patches, _) ->
      length [() | p <- patches, Just _ <- [patchCurvature p]]
        `shouldSatisfy` (>= 1)

    it "at least one patch has half-bound data" $ \(patches, _) ->
      length [() | p <- patches, Just _ <- [patchHalfBound p]]
        `shouldSatisfy` (>= 1)


  -- ──────────────────────────────────────────────────────────────
  --  Integration: the full validateAll pipeline
  --
  --  This test is EXHAUSTIVE: it runs every invariant check
  --  (half-bound, orbit consistency, Gauss–Bonnet, tower
  --  monotonicity, area decomposition, region counts, half-slack,
  --  half-bound metadata) on ALL loaded data.  The property tests
  --  below provide randomised redundancy via overPool sampling.
  -- ──────────────────────────────────────────────────────────────

  describe "validateAll (integration)" $
    it "returns no violations on real exported data" $ \(patches, tower) ->
      validateAll patches tower `shouldBe` []


  -- ──────────────────────────────────────────────────────────────
  --  prop_halfBound — Discrete Bekenstein–Hawking (Theorem 3)
  --
  --  For every region: 2 * S(A) <= area(A).
  --  Verified by Agda in Bridge/HalfBound.agda via (k, refl)
  --  witnesses sealed behind abstract.
  --
  --  Note: samples one random region per QuickCheck iteration.
  --  Exhaustive validation is performed by the "validateAll"
  --  integration test above.
  -- ──────────────────────────────────────────────────────────────

  describe "prop_halfBound" $
    it "2*S(A) <= area(A) for randomly sampled regions across all patches" $
      \(patches, _) ->
        let pool =
              [ (patchName p, r)
              | p <- patches
              , r <- patchRegionData p
              ]
        in overPool "halfBound" pool $ \(pname, r) ->
             counterexample
               (T.unpack pname ++ " region " ++ show (regionId r)
                ++ ": 2*" ++ show (regionMinCut r)
                ++ " = " ++ show (2 * regionMinCut r)
                ++ " > area " ++ show (regionArea r)) $
               2 * regionMinCut r <= regionArea r


  -- ──────────────────────────────────────────────────────────────
  --  prop_orbitConsistency
  --
  --  All regions sharing an orbit label must have the same min-cut
  --  value.  The orbit classification groups regions by min-cut;
  --  a mismatch indicates a corrupt classify function output.
  --
  --  We use Map.fromListWith (\_ existing -> existing) to keep
  --  the FIRST-SEEN value for each orbit.  This makes the
  --  representative deterministic (insertion order) and ensures
  --  the error messages point at the minority (corrupt) values,
  --  not the majority.  In correct data all values agree, so the
  --  choice of representative is immaterial.
  --
  --  Note: samples one random region per QuickCheck iteration.
  --  Exhaustive validation is performed by the "validateAll"
  --  integration test above.
  -- ──────────────────────────────────────────────────────────────

  describe "prop_orbitConsistency" $
    it "regions in the same orbit have identical min-cut values" $
      \(patches, _) ->
        let pool = concat
              [ [ (pname, r, orbitMap) | r <- regions ]
              | p <- patches
              , let pname   = patchName p
              , let regions = patchRegionData p
                    -- First-wins: for fromListWith, the combining
                    -- function receives (new, existing).  Returning
                    -- 'existing' keeps the first-inserted value.
              , let orbitMap = Map.fromListWith (\_ existing -> existing)
                      [ (regionOrbit r', regionMinCut r')
                      | r' <- regions
                      ]
              ]
        in overPool "orbitConsistency" pool $ \(pname, r, om) ->
             let expected = Map.findWithDefault (-1) (regionOrbit r) om
             in counterexample
                  (T.unpack pname ++ " orbit " ++ T.unpack (regionOrbit r)
                   ++ ": region " ++ show (regionId r) ++ " has S="
                   ++ show (regionMinCut r) ++ " but orbit expects S="
                   ++ show expected) $
                  regionMinCut r === expected


  -- ──────────────────────────────────────────────────────────────
  --  prop_towerMonotone
  --
  --  For every consecutive pair of tower levels where the higher
  --  level carries a monotonicity witness (k, "refl"), verify
  --  that maxCut_lo + k == maxCut_hi.  Levels without a witness
  --  (tlMonotone == Nothing) mark the start of a new sub-tower
  --  and are not checked against their predecessor.
  -- ──────────────────────────────────────────────────────────────

  describe "prop_towerMonotone" $
    it "maxCut is consistent with monotonicity witnesses" $ \(_, tower) ->
      conjoin
        [ case tlMonotone hi of
            Nothing     -> property True
            Just (k, _) ->
              counterexample
                (T.unpack (tlPatchName lo) ++ " (maxCut="
                 ++ show (tlMaxCut lo) ++ ") -> "
                 ++ T.unpack (tlPatchName hi) ++ " (maxCut="
                 ++ show (tlMaxCut hi) ++ "): "
                 ++ show (tlMaxCut lo) ++ " + " ++ show k
                 ++ " /= " ++ show (tlMaxCut hi)) $
                tlMaxCut lo + k === tlMaxCut hi
        | (lo, hi) <- zip tower (drop 1 tower)
        ]


  -- ──────────────────────────────────────────────────────────────
  --  prop_gaussBonnet — Discrete Gauss–Bonnet (Theorem 2)
  --
  --  For every patch with curvature data, the total curvature
  --  must equal the Euler characteristic.
  --
  --  CAVEAT (Issue #8): For 3D {4,3,5} patches (dense-50,
  --  dense-100, dense-200, honeycomb-3d), 18_export_json.py sets
  --  curvEuler = curvTotal (the same computed value), because no
  --  independent 3D Euler characteristic has been formalised in
  --  Agda.  This check is therefore TAUTOLOGICAL for 3D data —
  --  it merely guards against JSON field transposition or
  --  corruption.  It is independently meaningful only for 2D
  --  patches (filled, desitter) where the two values are set
  --  from separate computations.
  --
  --  The curvDenominator field (10 for 2D, 20 for 3D)
  --  disambiguates the rational unit of the integer numerators
  --  stored in curvTotal and curvEuler.
  -- ──────────────────────────────────────────────────────────────

  describe "prop_gaussBonnet" $
    it "curvature total equals Euler characteristic for all patches" $
      \(patches, _) ->
        let withCurv =
              [ (patchName p, cd)
              | p <- patches
              , Just cd <- [patchCurvature p]
              ]
        in conjoin
             [ counterexample
                 (T.unpack pname ++ ": totalCurvature="
                  ++ show (curvTotal cd)
                  ++ " /= eulerChar=" ++ show (curvEuler cd)) $
                 curvTotal cd === curvEuler cd
             | (pname, cd) <- withCurv
             ]


  -- ──────────────────────────────────────────────────────────────
  --  prop_areaDecomp — Area decomposition for cell complexes
  --
  --  For tilings with a face-count area model (all except Tree):
  --
  --    area(A) = faces_per_cell · |A| − 2 · |internal_faces|
  --
  --  Since region JSON lacks per-region internal face counts, we
  --  verify two algebraic consequences that do NOT require them:
  --
  --    1. area ≤ fpc · regionSize
  --       (equality when zero internal sharing)
  --
  --    2. (fpc · regionSize − area) is non-negative and even
  --       (since it equals 2 · internal_faces)
  --
  --  These constraints catch a broad class of area-computation
  --  bugs (wrong fpc constant, off-by-one internal face counting,
  --  tiling-type mismatch) without requiring the full adjacency
  --  structure.
  --
  --  Skipped for Tree tiling (simplified area proxy, not
  --  face-count based).
  --
  --  Note: samples one random region per QuickCheck iteration.
  --  Exhaustive validation is performed by the "validateAll"
  --  integration test above.
  --
  --  Reference: docs/engineering/backend-spec-haskell.md §6
  -- ──────────────────────────────────────────────────────────────

  describe "prop_areaDecomp" $
    it "area ≤ fpc·k and (fpc·k − area) is even for randomly sampled regions" $
      \(patches, _) ->
        let pool =
              [ (patchName p, patchTiling p, r)
              | p <- patches
              , r <- patchRegionData p
              -- Only include regions from tilings with a face-count
              -- area model.  Tree uses a simplified proxy (area = 2k)
              -- that does not follow the face-count decomposition.
              , Just _ <- [facesPerCell (patchTiling p)]
              ]
        in overPool "areaDecomp" pool $ \(pname, tiling, r) ->
             case facesPerCell tiling of
               Nothing  -> property True  -- unreachable due to filter above
               Just fpc ->
                 let totalFaces = fpc * regionSize r
                     deficit    = totalFaces - regionArea r
                 in conjoin
                      [ counterexample
                          (T.unpack pname ++ " region " ++ show (regionId r)
                           ++ ": area " ++ show (regionArea r)
                           ++ " > " ++ show fpc ++ " * "
                           ++ show (regionSize r)
                           ++ " = " ++ show totalFaces) $
                          regionArea r <= totalFaces
                      , counterexample
                          (T.unpack pname ++ " region " ++ show (regionId r)
                           ++ ": " ++ show fpc ++ " * "
                           ++ show (regionSize r)
                           ++ " - area " ++ show (regionArea r)
                           ++ " = " ++ show deficit
                           ++ " is odd (must equal 2 * internal_faces)") $
                          even deficit
                      ]


  -- ──────────────────────────────────────────────────────────────
  --  Region count consistency
  -- ──────────────────────────────────────────────────────────────

  describe "region count consistency" $
    it "patchRegions metadata matches actual region data length" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": metadata says " ++ show (patchRegions p)
               ++ " but data has " ++ show (length (patchRegionData p))) $
              patchRegions p === length (patchRegionData p)
          | p <- patches
          ]


  -- ──────────────────────────────────────────────────────────────
  --  Half-slack consistency
  --
  --  Note: samples one random region per QuickCheck iteration.
  --  Exhaustive validation is performed by the "validateAll"
  --  integration test above.
  -- ──────────────────────────────────────────────────────────────

  describe "half-slack consistency" $
    it "regionHalfSlack == area - 2*S when present" $ \(patches, _) ->
      let pool =
            [ (patchName p, r, hs)
            | p  <- patches
            , r  <- patchRegionData p
            , Just hs <- [regionHalfSlack r]
            ]
      in overPool "halfSlack" pool $ \(pname, r, hs) ->
           let expected = regionArea r - 2 * regionMinCut r
           in counterexample
                (T.unpack pname ++ " region " ++ show (regionId r)
                 ++ ": halfSlack=" ++ show hs
                 ++ " but area - 2*S = " ++ show expected) $
                hs === expected


  -- ──────────────────────────────────────────────────────────────
  --  Half-bound metadata
  -- ──────────────────────────────────────────────────────────────

  describe "half-bound metadata" $
    it "hbViolations == 0 for all patches with half-bound data" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p) ++ ": reports "
               ++ show (hbViolations hb) ++ " violations (expected 0)") $
              hbViolations hb === 0
          | p <- patches
          , Just hb <- [patchHalfBound p]
          ]


  -- ──────────────────────────────────────────────────────────────
  --  Region value-range sanity
  --
  --  These quick checks catch a broad class of data corruption
  --  (negative min-cuts, zero areas, mismatched cell lists) that
  --  the more specific properties above might miss.
  --
  --  Note: each sub-test samples one random region per QuickCheck
  --  iteration.  Exhaustive validation is performed by the
  --  "validateAll" integration test above.
  -- ──────────────────────────────────────────────────────────────

  describe "region sanity" $ do
    it "all min-cut values are non-negative" $ \(patches, _) ->
      let pool =
            [ (patchName p, r)
            | p <- patches, r <- patchRegionData p
            ]
      in overPool "minCutNonNeg" pool $ \(pname, r) ->
           counterexample
             (T.unpack pname ++ " region " ++ show (regionId r)
              ++ ": negative min-cut " ++ show (regionMinCut r)) $
             regionMinCut r >= 0

    it "all areas are positive" $ \(patches, _) ->
      let pool =
            [ (patchName p, r)
            | p <- patches, r <- patchRegionData p
            ]
      in overPool "areaPositive" pool $ \(pname, r) ->
           counterexample
             (T.unpack pname ++ " region " ++ show (regionId r)
              ++ ": non-positive area " ++ show (regionArea r)) $
             regionArea r > 0

    it "regionSize matches length of regionCells" $ \(patches, _) ->
      let pool =
            [ (patchName p, r)
            | p <- patches, r <- patchRegionData p
            ]
      in overPool "sizeConsistency" pool $ \(pname, r) ->
           counterexample
             (T.unpack pname ++ " region " ++ show (regionId r)
              ++ ": size=" ++ show (regionSize r)
              ++ " but cells has " ++ show (length (regionCells r))
              ++ " entries") $
             regionSize r === length (regionCells r)

    it "min-cut does not exceed area" $ \(patches, _) ->
      let pool =
            [ (patchName p, r)
            | p <- patches, r <- patchRegionData p
            ]
      in overPool "minCutLeArea" pool $ \(pname, r) ->
           counterexample
             (T.unpack pname ++ " region " ++ show (regionId r)
              ++ ": S=" ++ show (regionMinCut r)
              ++ " > area=" ++ show (regionArea r)) $
             regionMinCut r <= regionArea r