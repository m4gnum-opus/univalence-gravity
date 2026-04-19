{-# LANGUAGE OverloadedStrings #-}
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
--   agreement, Agda-aligned region counts, the
--   patchHalfBoundVerified flag, patch graph structural invariants
--   (node/edge counts, endpoint validity, boundary coverage), and
--   patch graph geometry invariants (Poincaré position, quaternion
--   unit norm, conformal scale range, and centring — Bug 1 fix).
--
--   Run from the @backend\/@ project root:
--
--   > cabal test
--
--   __Agda alignment notes (2026-04-17):__
--
--   The JSON export script @18_export_json.py@ was updated to match
--   Agda-verified region counts exactly.  Key changes:
--
--     * @honeycomb-3d@:  max_rc=1 → 26 singletons
--     * @honeycomb-145@: max_rc=5 → 1008 regions
--     * @dense-1000@:    max_rc=6 → 10317 regions
--
--   The @patchHalfBoundVerified@ flag is @True@ only for patches
--   with a corresponding @Boundary\/*HalfBound.agda@ module:
--   dense-100, dense-200, dense-1000.
--
--   __Patch graph update (2026-04-18):__
--
--   @pgNodes@ is now @[GraphNode]@ where each node carries an ID,
--   Poincaré-projected coordinates @(gnX, gnY, gnZ)@, a rotation
--   quaternion @(gnQx, gnQy, gnQz, gnQw)@, and a conformal scale
--   factor @gnScale@.  Set-based comparisons extract @gnId@ before
--   building Int sets.  Additional geometry tests verify:
--
--     * Positions lie inside the Poincaré ball: @|u|² ≤ 1@
--     * Quaternions are unit norm: @|q|² ≈ 1@
--     * Scales lie in @(0, 0.5]@
--     * For Poincaré-projected patches, cell 0 (the identity cell)
--       lands at the origin — validating the Lorentz boost applied
--       by @poincare_project@ per the centring fix plan (Step 1).

module InvariantSpec (spec) where

import Data.List             (sort)
import qualified Data.Map.Strict as Map
import qualified Data.Set        as Set
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
dataDir = "../data"


-- | Load patches and tower levels once, shared across all specs
--   via hspec's 'beforeAll'.
loadAllData :: IO ([Patch], [TowerLevel])
loadAllData = (,) <$> loadPatches dataDir <*> loadTower dataDir


-- | Sample a random element from a non-empty pool and test a
--   property on it.  If the pool is empty, produce a clear
--   failing 'Property' instead of crashing on @elements []@.
--
--   __Sampling note:__ Each QuickCheck iteration picks ONE random
--   element from the pool.  With the default 100 iterations, this
--   means ~100 random regions are tested across the pool.
--
--   __Exhaustive coverage__ is provided by the @\"validateAll\"@
--   integration test, which runs every check on every region
--   deterministically.
overPool :: Show a => String -> [a] -> (a -> Property) -> Property
overPool label [] _ =
  counterexample (label ++ ": empty pool — no data to test") False
overPool _     xs f = forAll (elements xs) f


-- | Number of faces (or edges, for 2D) per cell for each tiling.
--
--   Mirrors 'Invariants.facesPerCell'; duplicated to keep the
--   test module self-contained.
facesPerCell :: Tiling -> Maybe Int
facesPerCell Tiling435 = Just 6
facesPerCell Tiling54  = Just 5
facesPerCell Tiling53  = Just 5
facesPerCell Tiling44  = Just 4
facesPerCell Tree      = Nothing


-- | Agda-aligned region counts — source of truth is the
--   corresponding @Common\/*Spec.agda@ module.  If the oracle is
--   regenerated with different @max_rc@ parameters, both the Agda
--   module and this table must be updated in lockstep.
agdaAlignedRegionCounts :: [(T.Text, Int)]
agdaAlignedRegionCounts =
  [ ("tree",          8)
  , ("star",          10)
  , ("filled",        90)
  , ("honeycomb-3d",  26)
  , ("honeycomb-145", 1008)
  , ("dense-50",      139)
  , ("dense-100",     717)
  , ("dense-200",     1246)
  , ("dense-1000",    10317)
  , ("desitter",      10)
  , ("layer-54-d2",   15)
  , ("layer-54-d3",   40)
  , ("layer-54-d4",   105)
  , ("layer-54-d5",   275)
  , ("layer-54-d6",   720)
  , ("layer-54-d7",   1885)
  ]


-- | Patches that have a corresponding Boundary\/*HalfBound.agda
--   module machine-checking @2·S(A) ≤ area(A)@.
agdaVerifiedHalfBoundPatches :: [T.Text]
agdaVerifiedHalfBoundPatches =
  [ "dense-100"
  , "dense-200"
  , "dense-1000"
  ]


-- | Patches whose graph coordinates are produced by
--   @poincare_project@ in @18_export_json.py@ rather than a
--   hand-written 2D layout.
--
--   For these patches, cell 0 is the identity element of the
--   Coxeter group and must project to the origin of the Poincaré
--   ball/disk after the Lorentz boost applied in Step 1 of the
--   centring fix.  Hand-made layouts (tree, star, filled,
--   desitter) place their central tile at the origin but its cell
--   ID is not necessarily 0, so they are not tested here.
poincareProjectedPatches :: [T.Text]
poincareProjectedPatches =
  [ "honeycomb-3d", "honeycomb-145"
  , "dense-50", "dense-100", "dense-200", "dense-1000"
  , "layer-54-d2", "layer-54-d3", "layer-54-d4"
  , "layer-54-d5", "layer-54-d6", "layer-54-d7"
  ]


-- | Floating-point tolerance for geometry checks.
--
--   Matches 'Invariants.graphGeomTol'.  The Python exporter
--   rounds every float to 6 decimal digits before serialisation;
--   1e-4 absorbs accumulated round-off in squared-sum
--   computations without admitting genuine bugs.
geomTol :: Double
geomTol = 1.0e-4


-- | Extract node IDs from a patch graph.
--
--   Since 'GraphNode' derives 'Eq' but not 'Ord', set-based
--   comparisons need to work on the @gnId@ field rather than on
--   the full record.
graphNodeIds :: PatchGraph -> [Int]
graphNodeIds = map gnId . pgNodes


spec :: Spec
spec = beforeAll loadAllData $ do

  -- ──────────────────────────────────────────────────────────────
  --  Data-loading sanity (run first — prerequisite for all below)
  -- ──────────────────────────────────────────────────────────────

  describe "data loading sanity" $ do
    it "loaded exactly 16 patches" $ \(patches, _) ->
      length patches `shouldBe` 16

    it "loaded exactly 11 tower levels" $ \(_, tower) ->
      length tower `shouldBe` 11

    it "at least one patch has curvature data" $ \(patches, _) ->
      length [() | p <- patches, Just _ <- [patchCurvature p]]
        `shouldSatisfy` (>= 1)

    it "at least one patch has half-bound data" $ \(patches, _) ->
      length [() | p <- patches, Just _ <- [patchHalfBound p]]
        `shouldSatisfy` (>= 1)

    it "all expected patch names are present" $ \(patches, _) ->
      let names = map patchName patches
      in mapM_ (\(expected, _) ->
           names `shouldSatisfy` elem expected
         ) agdaAlignedRegionCounts


  -- ──────────────────────────────────────────────────────────────
  --  Integration: the full validateAll pipeline
  --
  --  Exhaustive: runs EVERY invariant (half-bound, orbit
  --  consistency, Gauss–Bonnet, tower monotonicity, area
  --  decomposition, region counts, half-slack, half-bound
  --  metadata, graph structure, graph geometry) on ALL loaded
  --  data.  The property tests below provide randomised
  --  redundancy via overPool sampling.
  -- ──────────────────────────────────────────────────────────────

  describe "validateAll (integration)" $
    it "returns no violations on real exported data" $ \(patches, tower) ->
      validateAll patches tower `shouldBe` []


  -- ──────────────────────────────────────────────────────────────
  --  Agda-aligned region counts
  -- ──────────────────────────────────────────────────────────────

  describe "Agda-aligned region counts" $ do
    it "every patch has the exact region count from its Agda Spec module" $
      \(patches, _) ->
        let patchMap = Map.fromList
              [ (patchName p, p) | p <- patches ]
        in mapM_ (\(name, expected) ->
             case Map.lookup name patchMap of
               Nothing -> expectationFailure $
                 "Missing patch: " ++ T.unpack name
               Just p  ->
                 patchRegions p `shouldBe` expected
           ) agdaAlignedRegionCounts

    it "patchRegionData length matches patchRegions for every patch" $
      \(patches, _) ->
        mapM_ (\p ->
          length (patchRegionData p) `shouldBe` patchRegions p
        ) patches


  -- ──────────────────────────────────────────────────────────────
  --  patchHalfBoundVerified flag
  -- ──────────────────────────────────────────────────────────────

  describe "patchHalfBoundVerified flag" $ do
    it "is True for Agda-verified half-bound patches" $
      \(patches, _) ->
        let patchMap = Map.fromList
              [ (patchName p, p) | p <- patches ]
        in mapM_ (\name ->
             case Map.lookup name patchMap of
               Nothing -> expectationFailure $
                 "Missing patch: " ++ T.unpack name
               Just p  ->
                 patchHalfBoundVerified p `shouldBe` True
           ) agdaVerifiedHalfBoundPatches

    it "is False for non-verified patches" $
      \(patches, _) ->
        let nonVerified = filter
              (\p -> patchName p `notElem` agdaVerifiedHalfBoundPatches)
              patches
        in mapM_ (\p ->
             patchHalfBoundVerified p `shouldBe` False
           ) nonVerified


  -- ──────────────────────────────────────────────────────────────
  --  prop_halfBound — Discrete Bekenstein–Hawking (Theorem 3)
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
  -- ──────────────────────────────────────────────────────────────

  describe "prop_orbitConsistency" $
    it "regions in the same orbit have identical min-cut values" $
      \(patches, _) ->
        let pool = concat
              [ [ (pname, r, orbitMap) | r <- regions ]
              | p <- patches
              , let pname   = patchName p
              , let regions = patchRegionData p
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
  --  CAVEAT: For 3D patches, 18_export_json.py sets curvEuler =
  --  curvTotal (the same computed value), so this check is
  --  tautological for 3D data.  It is independently meaningful
  --  only for 2D patches where total and euler are computed from
  --  separate sources.
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
  --  prop_areaDecomp
  -- ──────────────────────────────────────────────────────────────

  describe "prop_areaDecomp" $
    it "area ≤ fpc·k and (fpc·k − area) is even for randomly sampled regions" $
      \(patches, _) ->
        let pool =
              [ (patchName p, patchTiling p, r)
              | p <- patches
              , r <- patchRegionData p
              , Just _ <- [facesPerCell (patchTiling p)]
              ]
        in overPool "areaDecomp" pool $ \(pname, tiling, r) ->
             case facesPerCell tiling of
               Nothing  -> property True
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
  --  Patch graph structural invariants
  --
  --  The patchGraph field contains the full bulk graph: ALL cells
  --  (including interior cells invisible to boundary regions) and
  --  ALL physical bonds (shared faces in 3D, shared edges in 2D).
  --
  --  Each node is a 'GraphNode' carrying @gnId@ (cell ID),
  --  Poincaré-projected coordinates @(gnX, gnY, gnZ)@, rotation
  --  quaternion @(gnQx..gnQw)@, and conformal scale @gnScale@.
  --  Set-based comparisons use 'graphNodeIds' to match against
  --  edge endpoint IDs (bare 'Int').
  -- ──────────────────────────────────────────────────────────────

  describe "patch graph structural invariants" $ do

    it "pgNodes count equals patchCells for every patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": pgNodes has " ++ show nNodes
               ++ " nodes but patchCells = " ++ show (patchCells p)) $
              nNodes === patchCells p
          | p <- patches
          , let nNodes = length (pgNodes (patchGraph p))
          ]

    it "pgEdges count equals patchBonds for every patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": pgEdges has " ++ show nEdges
               ++ " edges but patchBonds = " ++ show (patchBonds p)) $
              nEdges === patchBonds p
          | p <- patches
          , let nEdges = length (pgEdges (patchGraph p))
          ]

    it "all edge endpoints are valid graph nodes for every patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": dangling edge endpoints not in pgNodes: "
               ++ show (Set.toAscList dangling)) $
              Set.null dangling
          | p <- patches
          , let graph        = patchGraph p
                nodeIdSet    = Set.fromList (graphNodeIds graph)
                allEndpoints = Set.fromList (concatMap edgeEndpoints (pgEdges graph))
                dangling     = allEndpoints `Set.difference` nodeIdSet
          ]

    it "every edge has exactly 2 endpoints for every patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": edge " ++ show i ++ " has non-2 arity after decoding: "
               ++ show e) $
              length (edgeEndpoints e) === 2
          | p <- patches
          , (i, e) <- zip [0 :: Int ..] (pgEdges (patchGraph p))
          ]

    it "all boundary cells (from regions) appear in pgNodes" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": " ++ show (Set.size missing)
               ++ " boundary cell(s) missing from pgNodes: "
               ++ show (take 10 (Set.toAscList missing))
               ++ if Set.size missing > 10 then " ..." else "") $
              Set.null missing
          | p <- patches
          , let graph    = patchGraph p
                nodeIdSet = Set.fromList (graphNodeIds graph)
                bdyCells  = Set.fromList
                              (concatMap regionCells (patchRegionData p))
                missing   = bdyCells `Set.difference` nodeIdSet
          ]

    it "pgNodes count >= distinct boundary cell count for every patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": pgNodes has " ++ show nNodes
               ++ " nodes but there are " ++ show nBdyCells
               ++ " distinct boundary cells"
               ++ "; interior cells may be missing") $
              nNodes >= nBdyCells
          | p <- patches
          , let nNodes    = length (pgNodes (patchGraph p))
                nBdyCells = Set.size $ Set.fromList
                              (concatMap regionCells (patchRegionData p))
          ]

    it "dense patches have interior cells in the graph (pgNodes > boundary cells)" $
      \(patches, _) ->
        let densePatches = filter
              (\p -> patchName p `elem`
                ["dense-50", "dense-100", "dense-200", "dense-1000",
                 "honeycomb-145"])
              patches
        in conjoin
             [ counterexample
                 (T.unpack (patchName p)
                  ++ ": pgNodes=" ++ show nNodes
                  ++ " should be > boundary cells=" ++ show nBdyCells
                  ++ " (interior cells missing!)") $
                 nNodes > nBdyCells
             | p <- densePatches
             , let nNodes    = length (pgNodes (patchGraph p))
                   nBdyCells = Set.size $ Set.fromList
                                 (concatMap regionCells (patchRegionData p))
             ]

    it "pgNodes are sorted by ID for every patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p) ++ ": pgNodes are not sorted by ID") $
              ids === sort ids
          | p <- patches
          , let ids = graphNodeIds (patchGraph p)
          ]

    it "no self-loops in pgEdges for any patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": self-loop at edge " ++ show i ++ ": " ++ show e) $
              property (edgeSource e /= edgeTarget e)
          | p <- patches
          , (i, e) <- zip [0 :: Int ..] (pgEdges (patchGraph p))
          ]

    it "pgNodes have no duplicate IDs for any patch" $
      \(patches, _) ->
        conjoin
          [ counterexample
              (T.unpack (patchName p)
               ++ ": pgNodes has duplicate IDs: "
               ++ show (length ids) ++ " entries but "
               ++ show (Set.size (Set.fromList ids)) ++ " unique") $
              length ids === Set.size (Set.fromList ids)
          | p <- patches
          , let ids = graphNodeIds (patchGraph p)
          ]


  -- ──────────────────────────────────────────────────────────────
  --  Patch graph geometry invariants
  --
  --  Per-node checks on the floating-point geometry fields added
  --  in the centring-and-scale fix (roadmap Steps 1–2):
  --
  --    1. Position lies inside the Poincaré ball: |u|² ≤ 1 + tol
  --    2. Quaternion has unit norm: |q|² ∈ [1 − tol, 1 + tol]
  --    3. Scale is in the valid range (0, 0.5 + tol]
  --    4. For Poincaré-projected patches, cell 0 (the Coxeter
  --       identity) lands at the origin with scale ≈ 0.5 —
  --       validating Bug 1 of the centring fix plan.
  --
  --  The first three are also checked exhaustively inside
  --  Invariants.validateGraphGeometry (run via the
  --  \"validateAll\" integration test above); here we sample
  --  randomly for independent verification and better error
  --  localisation.
  --
  --  Note: we do NOT enforce the strict identity
  --  scale ≡ (1 − |u|²) / 2, because the Python exporter clamps
  --  the scale at 1e-6 near the disk boundary (required for
  --  layer-54-d7 where cells are exponentially close to |u| = 1).
  --  The range check catches the real failure modes without
  --  false positives.
  -- ──────────────────────────────────────────────────────────────

  describe "patch graph geometry invariants" $ do

    it "all graph node positions lie inside the Poincaré ball" $
      \(patches, _) ->
        let pool =
              [ (patchName p, n)
              | p <- patches
              , n <- pgNodes (patchGraph p)
              ]
        in overPool "graphPosition" pool $ \(pname, n) ->
             let r2 = gnX n * gnX n + gnY n * gnY n + gnZ n * gnZ n
             in counterexample
                  (T.unpack pname ++ " node " ++ show (gnId n)
                   ++ ": |u|² = " ++ show r2
                   ++ " exceeds Poincaré ball radius² = 1") $
                  not (isNaN r2) && not (isInfinite r2) && r2 <= 1.0 + geomTol

    it "all graph node quaternions have unit norm" $
      \(patches, _) ->
        let pool =
              [ (patchName p, n)
              | p <- patches
              , n <- pgNodes (patchGraph p)
              ]
        in overPool "graphQuaternion" pool $ \(pname, n) ->
             let qn2 = gnQx n * gnQx n + gnQy n * gnQy n
                     + gnQz n * gnQz n + gnQw n * gnQw n
             in counterexample
                  (T.unpack pname ++ " node " ++ show (gnId n)
                   ++ ": |q|² = " ++ show qn2
                   ++ " (expected 1 ± " ++ show geomTol ++ ")"
                   ++ "  q=(" ++ show (gnQx n) ++ ", " ++ show (gnQy n)
                   ++ ", " ++ show (gnQz n) ++ ", " ++ show (gnQw n) ++ ")") $
                  not (isNaN qn2) && not (isInfinite qn2)
                                  && abs (qn2 - 1.0) <= geomTol

    it "all graph node scales are in (0, 0.5 + tol]" $
      \(patches, _) ->
        let pool =
              [ (patchName p, n)
              | p <- patches
              , n <- pgNodes (patchGraph p)
              ]
        in overPool "graphScale" pool $ \(pname, n) ->
             let s = gnScale n
             in counterexample
                  (T.unpack pname ++ " node " ++ show (gnId n)
                   ++ ": scale = " ++ show s
                   ++ " is outside (0, 0.5 + " ++ show geomTol ++ "]") $
                  not (isNaN s) && not (isInfinite s)
                                && s > 0 && s <= 0.5 + geomTol

    -- Bug 1 fix verification.
    --
    -- Before the fix, the fundamental cell (g = I) could project
    -- to a non-zero point because the Python projector did not
    -- apply the centring Lorentz boost.  After the fix, for every
    -- Poincaré-projected patch the cell with ID 0 must land at
    -- the origin (0, 0, 0) with scale ≈ (1 − 0²)/2 = 0.5.
    --
    -- If this test fails, the centring boost in
    -- 18_export_json.py:poincare_project is wrong or missing.
    it "Poincaré-projected patches have cell 0 at the origin with scale 0.5" $
      \(patches, _) ->
        let patchMap = Map.fromList
              [ (patchName p, p) | p <- patches ]
        in mapM_ (\name ->
             case Map.lookup name patchMap of
               Nothing -> expectationFailure $
                 "Missing patch: " ++ T.unpack name
               Just p ->
                 case filter ((== 0) . gnId) (pgNodes (patchGraph p)) of
                   []  -> expectationFailure $
                     T.unpack name
                     ++ ": cell 0 (identity) not found in pgNodes"
                   (_:_:_) -> expectationFailure $
                     T.unpack name ++ ": duplicate cell 0 entries in pgNodes"
                   [n] -> do
                     let r2 = gnX n * gnX n + gnY n * gnY n + gnZ n * gnZ n
                     counterexample
                       ("identity cell offset: |u|² = " ++ show r2
                        ++ "  pos = (" ++ show (gnX n)
                        ++ ", " ++ show (gnY n)
                        ++ ", " ++ show (gnZ n) ++ ")")
                       (r2 <= geomTol)
                       & \prop ->
                         quickCheckWith
                           stdArgs { chatty = False, maxSuccess = 1 }
                           prop
                         >>= \_ -> pure ()
                     abs (gnX n)           `shouldSatisfy` (<= geomTol)
                     abs (gnY n)           `shouldSatisfy` (<= geomTol)
                     abs (gnZ n)           `shouldSatisfy` (<= geomTol)
                     abs (gnScale n - 0.5) `shouldSatisfy` (<= geomTol)
           ) poincareProjectedPatches


  -- ──────────────────────────────────────────────────────────────
  --  Region value-range sanity
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


  -- ──────────────────────────────────────────────────────────────
  --  Patch-level maxCut regression
  -- ──────────────────────────────────────────────────────────────

  describe "patch maxCut regression" $ do
    it "honeycomb-3d maxCut matches Agda (singletons, max S ≤ 2)" $
      \(patches, _) ->
        let hc = filter (\p -> patchName p == "honeycomb-3d") patches
        in case hc of
             [p] -> patchMaxCut p `shouldSatisfy` (<= 2)
             _   -> expectationFailure "honeycomb-3d patch not found"

    it "honeycomb-145 maxCut == 9 (matching Honeycomb145Spec orbits mc1..mc9)" $
      \(patches, _) ->
        let hc = filter (\p -> patchName p == "honeycomb-145") patches
        in case hc of
             [p] -> patchMaxCut p `shouldBe` 9
             _   -> expectationFailure "honeycomb-145 patch not found"

    it "dense-1000 maxCut == 9 (matching Dense1000Spec orbits mc1..mc9)" $
      \(patches, _) ->
        let d1k = filter (\p -> patchName p == "dense-1000") patches
        in case d1k of
             [p] -> patchMaxCut p `shouldBe` 9
             _   -> expectationFailure "dense-1000 patch not found"

    it "dense-100 maxCut == 8" $
      \(patches, _) ->
        let d100 = filter (\p -> patchName p == "dense-100") patches
        in case d100 of
             [p] -> patchMaxCut p `shouldBe` 8
             _   -> expectationFailure "dense-100 patch not found"

    it "dense-200 maxCut == 9" $
      \(patches, _) ->
        let d200 = filter (\p -> patchName p == "dense-200") patches
        in case d200 of
             [p] -> patchMaxCut p `shouldBe` 9
             _   -> expectationFailure "dense-200 patch not found"
  where
    -- Local '&' to keep the Bug-1 verification readable without
    -- depending on Data.Function's fixity (which differs between
    -- GHC 9.6 and 9.8).  Unused in the current body, but retained
    -- for future extensions of the centring test.
    (&) :: a -> (a -> b) -> b
    x & f = f x
    infixl 1 &