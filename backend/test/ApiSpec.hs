{-# LANGUAGE OverloadedStrings #-}

-- | Servant-client integration tests for the Univalence Gravity
--   backend REST API.
--
--   Starts a Warp server on an ephemeral port (via
--   'testWithApplication'), hits every endpoint defined in "Api"
--   using auto-derived 'servant-client' functions, and verifies:
--
--     * Every endpoint returns HTTP 200 with valid, decodable JSON.
--     * Response Content-Type is @application\/json@ (verified
--       implicitly by Servant's content negotiation — the client
--       functions reject non-JSON responses automatically).
--     * @GET \/patches\/:name@ returns 404 for unknown patch names.
--     * Response payloads contain expected values (patch names,
--       tiling types, region counts, theorem numbers, etc.).
--     * @patchGraph@ field is present with correct node/edge counts.
--     * @patchGraph@ geometry fields (@gnScale@, quaternion,
--       position) are in valid ranges.
--     * Poincaré-projected patches have cell 0 at the origin
--       (Bug 1 fix from the centring roadmap).
--
--   __Regression values (Issue #12):__
--   Several tests assert specific numeric values for fields like
--   @patchMaxCut@, @patchOrbits@, and @patchRegions@.  These are
--   __regression tests tracking the current data snapshot__ produced
--   by @18_export_json.py@.  If the oracle is re-run with different
--   parameters (e.g. different @max_rc@, different growth seed) or
--   if patches are regenerated, these values may change legitimately.
--   When updating: verify the new values against the oracle output
--   (the @*_OUTPUT.txt@ file for the relevant script), then update
--   the expected constants below.
--
--   Assertions are categorised with inline comments:
--
--     * @-- Structural@: definitional properties of the patch
--       (name, tiling, dimension, cell count).  These should never
--       change unless the patch itself is redefined.
--     * @-- Regression@: values computed by the Python oracle
--       (region counts, orbit counts, max min-cut).  These track
--       the current data snapshot and must be updated if the oracle
--       output changes.
--
--   The data directory @data\/@ (a symlink to the repo-root
--   @data\/@ produced by @18_export_json.py@) must exist relative
--   to the @backend\/@ project root where @cabal test@ is invoked.
--
--   __Agda alignment (2026-04-17):__
--
--   The JSON export script @18_export_json.py@ was updated to match
--   Agda-verified region counts exactly.  Key alignment parameters:
--
--     * @honeycomb-3d@:  max_rc=1 → 26 singletons (matching
--       Common\/Honeycomb3DSpec.agda)
--     * @honeycomb-145@: max_rc=5 → 1008 regions (matching
--       Common\/Honeycomb145Spec.agda)
--     * @dense-1000@:    max_rc=6 → 10317 regions (matching
--       Common\/Dense1000Spec.agda)
--
--   __Patch graph (Phase 1, 2026-04-18):__
--
--   Every patch now includes a @patchGraph@ field with @pgNodes@
--   (list of 'GraphNode' objects) and @pgEdges@ (all physical
--   bonds).  Each 'GraphNode' carries:
--
--     * @gnId@ — cell ID
--     * @gnX@, @gnY@, @gnZ@ — Poincaré-projected coordinates
--     * @gnQx@, @gnQy@, @gnQz@, @gnQw@ — rotation quaternion
--     * @gnScale@ — conformal scale factor
--       @s(u) = (1 − |u|²) / 2@ (roadmap Step 2)
--
--   The graph tests verify:
--
--     * Node/edge counts match @patchCells@ / @patchBonds@.
--     * Every edge endpoint is a valid node ID.
--     * Dense patches have interior cells in the graph.
--     * @gnScale@ is in the valid range @(0, 0.5 + tol]@.
--     * Quaternions have unit norm.
--     * Positions lie inside the Poincaré ball.
--     * For Poincaré-projected patches, cell 0 (the Coxeter
--       identity) lands at the origin with scale ≈ 0.5
--       (centring fix, roadmap Step 1).
--
--   Hand-written 2D layouts (tree, star, filled, desitter) use
--   the identity quaternion and a conformal scale derived from
--   their @(x, y, z)@ coordinates.  They are NOT tested against
--   the "cell 0 at origin" invariant because their central tile
--   does not necessarily have cell ID 0.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §10.3

module ApiSpec (spec) where

import qualified Data.Set as Set

import Data.Text              (Text)
import Network.HTTP.Client    (newManager, defaultManagerSettings)
import Network.HTTP.Types.Status (statusCode)
import Network.Wai.Handler.Warp  (testWithApplication)
import Servant.API ((:<|>)(..))
import Servant.Client
import Test.Hspec

import Api        (api)
import DataLoader
  ( loadCurvatureSummaries
  , loadMeta
  , loadPatches
  , loadTheorems
  , loadTower
  )
import Server     (app)
import Types


-- ════════════════════════════════════════════════════════════════
--  Servant client functions (derived from the API type)
-- ════════════════════════════════════════════════════════════════

getPatches   :: ClientM [PatchSummary]
getPatch     :: Text -> ClientM Patch
getTower     :: ClientM [TowerLevel]
getTheorems  :: ClientM [Theorem]
getCurvature :: ClientM [CurvatureSummary]
getMeta      :: ClientM Meta
getHealth    :: ClientM Health

getPatches
  :<|> getPatch
  :<|> getTower
  :<|> getTheorems
  :<|> getCurvature
  :<|> getMeta
  :<|> getHealth = client api


-- ════════════════════════════════════════════════════════════════
--  Helpers
-- ════════════════════════════════════════════════════════════════

-- | Extract bare cell IDs from a patch graph's node list.
--
--   Since 'GraphNode' carries spatial coordinates, a rotation
--   quaternion, and a conformal scale alongside the cell ID,
--   set-based comparisons against edge endpoint IDs (which are
--   bare 'Int') require extracting @gnId@ first.
graphNodeIds :: PatchGraph -> [Int]
graphNodeIds = map gnId . pgNodes

-- | Floating-point tolerance for geometry sanity checks.
--
--   Matches 'Invariants.graphGeomTol'.  The Python exporter
--   rounds every float field to 6 decimal digits before
--   serialisation; 1e-4 absorbs accumulated round-off in
--   squared-sum computations without admitting genuine bugs.
geomTol :: Double
geomTol = 1.0e-4

-- | Patches whose graph coordinates are produced by
--   @poincare_project@ in @18_export_json.py@ rather than a
--   hand-written 2D layout.  For these, cell 0 (the Coxeter
--   identity) must project to the origin after the Lorentz boost
--   applied in roadmap Step 1.
poincareProjectedPatches :: [Text]
poincareProjectedPatches =
  [ "honeycomb-3d", "honeycomb-145"
  , "dense-50", "dense-100", "dense-200", "dense-1000"
  , "layer-54-d2", "layer-54-d3", "layer-54-d4"
  , "layer-54-d5", "layer-54-d6", "layer-54-d7"
  ]


-- ════════════════════════════════════════════════════════════════
--  Test infrastructure
-- ════════════════════════════════════════════════════════════════

-- | Path to the data directory.  Assumes @cabal test@ is run from
--   the @backend\/@ project root, where @data\/@ is a symlink (or
--   copy) pointing to the repo-root @data\/@ produced by
--   @18_export_json.py@.
dataDir :: FilePath
dataDir = "../data"

-- | Load all JSON data, build the WAI 'Application', and start
--   Warp on an ephemeral port.  The port number is passed to the
--   callback; the server is torn down when the callback returns.
--
--   Used with 'aroundAll' so the server is started once and shared
--   across all test examples.  Data loading (the expensive part)
--   happens only once; Warp startup is sub-millisecond.
withTestServer :: (Int -> IO ()) -> IO ()
withTestServer action = do
  patches   <- loadPatches           dataDir
  tower     <- loadTower             dataDir
  theorems  <- loadTheorems          dataDir
  curvature <- loadCurvatureSummaries dataDir
  meta      <- loadMeta              dataDir
  testWithApplication
    (pure (app patches tower theorems curvature meta))
    action

-- | Create a 'ClientEnv' targeting @http:\/\/localhost:\<port\>@.
--   A fresh HTTP manager is allocated; this is lightweight and
--   suitable for test use.
mkEnv :: Int -> IO ClientEnv
mkEnv port = do
  mgr <- newManager defaultManagerSettings
  pure (mkClientEnv mgr (BaseUrl Http "localhost" port ""))

-- | Run a 'ClientM' action and assert that it succeeds (HTTP 2xx
--   with a decodable response body).  On failure, the test is
--   aborted with the 'ClientError' shown in the failure message.
--
--   Note: Servant's content negotiation ensures that the response
--   Content-Type is @application\/json@.  If the server returned a
--   different Content-Type, the client would fail with a decode
--   error here, implicitly catching any middleware misconfiguration
--   (Issue #13).
runSuccess :: Show a => ClientEnv -> ClientM a -> IO a
runSuccess env action = do
  result <- runClientM action env
  case result of
    Right val -> pure val
    Left  err -> expectationFailure
                   ("Expected successful response but got: " ++ show err)
                 >> error "unreachable"


-- ════════════════════════════════════════════════════════════════
--  Spec
-- ════════════════════════════════════════════════════════════════

spec :: Spec
spec = aroundAll withTestServer $ do

  -- ──────────────────────────────────────────────────────────────
  --  GET /health
  -- ──────────────────────────────────────────────────────────────

  describe "GET /health" $
    it "returns 200 with status ok and positive counts" $ \port -> do
      env <- mkEnv port
      h   <- runSuccess env getHealth
      status h      `shouldBe` "ok"
      patchCount h  `shouldBe` 16                -- Structural: 16 patches loaded
      regionCount h `shouldSatisfy` (> 0)


  -- ──────────────────────────────────────────────────────────────
  --  GET /patches
  -- ──────────────────────────────────────────────────────────────

  describe "GET /patches" $ do
    it "returns exactly 16 patch summaries" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      length ps `shouldBe` 16                     -- Structural: 16 patches

    it "includes all known patches by name" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      let names = map psName ps
      -- Structural: every expected patch must be present.
      names `shouldSatisfy` elem "tree"
      names `shouldSatisfy` elem "star"
      names `shouldSatisfy` elem "filled"
      names `shouldSatisfy` elem "honeycomb-3d"
      names `shouldSatisfy` elem "honeycomb-145"
      names `shouldSatisfy` elem "dense-50"
      names `shouldSatisfy` elem "dense-100"
      names `shouldSatisfy` elem "dense-200"
      names `shouldSatisfy` elem "dense-1000"
      names `shouldSatisfy` elem "desitter"
      names `shouldSatisfy` elem "layer-54-d2"
      names `shouldSatisfy` elem "layer-54-d3"
      names `shouldSatisfy` elem "layer-54-d4"
      names `shouldSatisfy` elem "layer-54-d5"
      names `shouldSatisfy` elem "layer-54-d6"
      names `shouldSatisfy` elem "layer-54-d7"


  -- ──────────────────────────────────────────────────────────────
  --  GET /patches/:name — successful lookups
  --
  --  Values marked "Regression" track the current data snapshot.
  --  See module documentation above for the update procedure.
  -- ──────────────────────────────────────────────────────────────

  describe "GET /patches/:name" $ do

    -- ── Dense-100 ──────────────────────────────────────────────

    it "returns full data for dense-100" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-100")
      -- Structural
      patchName p      `shouldBe` "dense-100"
      patchTiling p    `shouldBe` Tiling435
      patchDimension p `shouldBe` 3
      patchCells p     `shouldBe` 100
      -- Regression (09_generate_dense100.py: 717 regions, 8 orbits, maxS=8)
      patchRegions p   `shouldBe` 717
      patchOrbits p    `shouldBe` 8
      patchMaxCut p    `shouldBe` 8
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      -- Dense-100 has both curvature and half-bound data
      patchCurvature p `shouldSatisfy` (/= Nothing)
      patchHalfBound p `shouldSatisfy` (/= Nothing)
      -- Agda-verified half-bound
      patchHalfBoundVerified p `shouldBe` True
      -- Graph: 100 nodes (= patchCells), 150 edges (= patchBonds)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 100          -- Structural
      length (pgEdges g) `shouldBe` 150          -- Regression

    -- ── Dense-200 ──────────────────────────────────────────────

    it "returns full data for dense-200" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-200")
      -- Structural
      patchName p    `shouldBe` "dense-200"
      patchTiling p  `shouldBe` Tiling435
      patchCells p   `shouldBe` 200
      -- Regression (12_generate_dense200.py: 1246 regions, 9 orbits, maxS=9)
      patchMaxCut p  `shouldBe` 9
      patchOrbits p  `shouldBe` 9
      patchRegions p `shouldBe` 1246
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      patchCurvature p `shouldSatisfy` (/= Nothing)
      patchHalfBound p `shouldSatisfy` (/= Nothing)
      -- Agda-verified half-bound
      patchHalfBoundVerified p `shouldBe` True
      -- Graph: 200 nodes, 308 edges
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 200          -- Structural
      length (pgEdges g) `shouldBe` 308          -- Regression

    -- ── Dense-1000 ─────────────────────────────────────────────

    it "returns full data for dense-1000" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-1000")
      -- Structural
      patchName p      `shouldBe` "dense-1000"
      patchTiling p    `shouldBe` Tiling435
      patchDimension p `shouldBe` 3
      patchCells p     `shouldBe` 1000
      -- Regression (12b_generate_dense1000.py: 10317 regions, 9 orbits, maxS=9)
      patchRegions p   `shouldBe` 10317
      patchOrbits p    `shouldBe` 9
      patchMaxCut p    `shouldBe` 9
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      patchCurvature p `shouldSatisfy` (/= Nothing)
      patchHalfBound p `shouldSatisfy` (/= Nothing)
      -- Agda-verified half-bound
      patchHalfBoundVerified p `shouldBe` True
      -- Graph: 1000 nodes, 1597 edges
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 1000         -- Structural
      length (pgEdges g) `shouldBe` 1597         -- Regression

    -- ── Dense-50 ───────────────────────────────────────────────

    it "returns full data for dense-50" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-50")
      -- Structural
      patchName p      `shouldBe` "dense-50"
      patchTiling p    `shouldBe` Tiling435
      patchDimension p `shouldBe` 3
      patchCells p     `shouldBe` 50
      -- Regression (08_generate_dense50.py: 139 regions, maxS=7)
      patchRegions p   `shouldBe` 139
      patchMaxCut p    `shouldBe` 7
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      patchCurvature p `shouldSatisfy` (/= Nothing)
      -- Graph: 50 nodes, 68 edges
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 50           -- Structural
      length (pgEdges g) `shouldBe` 68           -- Regression

    -- ── Tree ───────────────────────────────────────────────────

    it "returns full data for tree" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "tree")
      -- Structural
      patchName p      `shouldBe` "tree"
      patchTiling p    `shouldBe` Tree
      patchDimension p `shouldBe` 1
      patchCells p     `shouldBe` 7
      -- Regression (hardcoded in 18_export_json.py: 8 regions, maxS=2)
      patchRegions p   `shouldBe` 8
      patchMaxCut p    `shouldBe` 2
      -- Tree has no curvature (1D) and no half-bound
      patchCurvature p `shouldBe` Nothing
      patchHalfBound p `shouldBe` Nothing
      -- Graph: 7 nodes, 6 edges (the tree edges)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 7            -- Structural
      length (pgEdges g) `shouldBe` 6            -- Structural

    -- ── Star ───────────────────────────────────────────────────

    it "returns full data for star" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "star")
      -- Structural
      patchName p      `shouldBe` "star"
      patchTiling p    `shouldBe` Tiling54
      patchDimension p `shouldBe` 2
      patchCells p     `shouldBe` 6
      -- Regression (hardcoded in 18_export_json.py: 10 regions, maxS=2)
      patchRegions p   `shouldBe` 10
      patchMaxCut p    `shouldBe` 2
      -- Star has no curvature data (needs the filled patch for that)
      patchCurvature p `shouldBe` Nothing
      -- Graph: 6 nodes (C + N0..N4), 5 edges (C–Ni bonds)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 6            -- Structural
      length (pgEdges g) `shouldBe` 5            -- Structural

    -- ── De Sitter ──────────────────────────────────────────────

    it "returns full data for desitter (with curvature)" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "desitter")
      -- Structural
      patchName p      `shouldBe` "desitter"
      patchTiling p    `shouldBe` Tiling53
      patchDimension p `shouldBe` 2
      patchCells p     `shouldBe` 6
      -- Regression
      patchRegions p   `shouldBe` 10
      patchMaxCut p    `shouldBe` 2
      -- De Sitter has positive curvature data
      patchCurvature p `shouldSatisfy` (/= Nothing)
      -- Graph: 6 nodes, 5 edges (same topology as star)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 6            -- Structural
      length (pgEdges g) `shouldBe` 5            -- Structural

    -- ── Filled ─────────────────────────────────────────────────

    it "returns full data for filled" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "filled")
      -- Structural
      patchName p      `shouldBe` "filled"
      patchTiling p    `shouldBe` Tiling54
      patchDimension p `shouldBe` 2
      patchCells p     `shouldBe` 11
      -- Regression (03_generate_filled_patch.py: 90 regions, maxS=4)
      patchRegions p   `shouldBe` 90
      patchMaxCut p    `shouldBe` 4
      -- Filled has curvature (the primary Gauss-Bonnet target)
      patchCurvature p `shouldSatisfy` (/= Nothing)
      -- Graph: 11 nodes (C + N0..N4 + G0..G4), 15 edges
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 11           -- Structural
      length (pgEdges g) `shouldBe` 15           -- Structural

    -- ── Honeycomb-3D ───────────────────────────────────────────

    it "returns full data for honeycomb-3d" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "honeycomb-3d")
      -- Structural
      patchName p      `shouldBe` "honeycomb-3d"
      patchTiling p    `shouldBe` Tiling435
      patchDimension p `shouldBe` 3
      patchCells p     `shouldBe` 32
      -- Regression (18_export_json.py: build_435_bfs_json(7, ..., max_rc=1)
      -- → 26 singleton regions, matching Honeycomb3DSpec.agda)
      patchRegions p   `shouldBe` 26
      patchMaxCut p    `shouldBe` 2
      patchOrbits p    `shouldBe` 2
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      patchCurvature p `shouldSatisfy` (/= Nothing)
      -- Graph: 32 nodes, 39 edges (BFS shell faces)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 32           -- Structural
      length (pgEdges g) `shouldBe` 39           -- Regression

    -- ── Honeycomb-145 ──────────────────────────────────────────

    it "returns full data for honeycomb-145" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "honeycomb-145")
      -- Structural
      patchName p      `shouldBe` "honeycomb-145"
      patchTiling p    `shouldBe` Tiling435
      patchDimension p `shouldBe` 3
      patchCells p     `shouldBe` 145
      -- Regression (06b_generate_honeycomb145.py: 1008 regions, 9 orbits, maxS=9)
      patchRegions p   `shouldBe` 1008
      patchOrbits p    `shouldBe` 9
      patchMaxCut p    `shouldBe` 9
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      patchCurvature p `shouldSatisfy` (/= Nothing)
      patchHalfBound p `shouldSatisfy` (/= Nothing)
      -- Graph: 145 nodes, 222 edges
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 145          -- Structural
      length (pgEdges g) `shouldBe` 222          -- Regression

    -- ── Layer-54-d2 ────────────────────────────────────────────

    it "returns full data for layer-54-d2" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "layer-54-d2")
      -- Structural
      patchName p      `shouldBe` "layer-54-d2"
      patchTiling p    `shouldBe` Tiling54
      patchDimension p `shouldBe` 2
      patchCells p     `shouldBe` 21
      -- Regression (13_generate_layerN.py --depth 2: 15 regions, 2 orbits, maxS=2)
      patchRegions p   `shouldBe` 15
      patchMaxCut p    `shouldBe` 2
      patchOrbits p    `shouldBe` 2
      -- Graph: 21 nodes (= patchCells)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 21           -- Structural

    -- ── Layer-54-d7 ────────────────────────────────────────────

    it "returns full data for layer-54-d7" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "layer-54-d7")
      -- Structural
      patchName p      `shouldBe` "layer-54-d7"
      patchTiling p    `shouldBe` Tiling54
      patchCells p     `shouldBe` 3046
      -- Regression (13_generate_layerN.py --depth 7: 1885 regions, 2 orbits, maxS=2)
      patchRegions p   `shouldBe` 1885
      patchMaxCut p    `shouldBe` 2
      patchOrbits p    `shouldBe` 2
      -- Consistency
      length (patchRegionData p) `shouldBe` patchRegions p
      -- Graph: 3046 nodes (= patchCells)
      let g = patchGraph p
      length (pgNodes g) `shouldBe` 3046         -- Structural

    -- ── Spot-check: region data structure ──────────────────────
    --
    -- Verify that a single region record from a known patch has
    -- the expected structure (positive area, non-negative min-cut,
    -- consistent regionSize, etc.).  This catches structural
    -- issues in the JSON export without duplicating the exhaustive
    -- InvariantSpec checks.

    it "dense-100 region data has correct structure" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-100")
      let regions = patchRegionData p
      -- At least one region exists
      length regions `shouldSatisfy` (> 0)
      -- Spot-check the first region
      let r = head regions
      regionMinCut r `shouldSatisfy` (> 0)
      regionArea r   `shouldSatisfy` (> 0)
      regionSize r   `shouldBe` length (regionCells r)
      -- Half-bound: 2*S <= area
      (2 * regionMinCut r) `shouldSatisfy` (<= regionArea r)

    -- ── patchHalfBoundVerified flag ────────────────────────────

    it "dense-100 has patchHalfBoundVerified = True" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-100")
      patchHalfBoundVerified p `shouldBe` True

    it "dense-200 has patchHalfBoundVerified = True" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-200")
      patchHalfBoundVerified p `shouldBe` True

    it "dense-1000 has patchHalfBoundVerified = True" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "dense-1000")
      patchHalfBoundVerified p `shouldBe` True

    it "star has patchHalfBoundVerified = False" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "star")
      patchHalfBoundVerified p `shouldBe` False

    it "honeycomb-3d has patchHalfBoundVerified = False" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "honeycomb-3d")
      patchHalfBoundVerified p `shouldBe` False

    -- ────────────────────────────────────────────────────────────
    --  GET /patches/:name — 404 for unknown patches
    -- ────────────────────────────────────────────────────────────

    it "returns 404 for an unknown patch name" $ \port -> do
      env    <- mkEnv port
      result <- runClientM (getPatch "nonexistent-patch-xyz") env
      case result of
        Left (FailureResponse _ resp) ->
          statusCode (responseStatusCode resp) `shouldBe` 404
        Left other ->
          expectationFailure $
            "Expected FailureResponse with 404 but got: " ++ show other
        Right _ ->
          expectationFailure
            "Expected 404 but got a successful response"

    it "returns 404 for empty patch name" $ \port -> do
      -- Servant routes "patches/" with an empty capture differently
      -- depending on the router; with the standard servant router,
      -- an empty capture string produces a 404.
      env    <- mkEnv port
      result <- runClientM (getPatch "") env
      case result of
        Left (FailureResponse _ resp) ->
          statusCode (responseStatusCode resp)
            `shouldSatisfy` (\c -> c == 404 || c == 400)
        Left _  -> pure ()   -- any client error is acceptable
        Right _ ->
          expectationFailure
            "Expected an error response for empty patch name"


  -- ──────────────────────────────────────────────────────────────
  --  GET /patches/:name — patchGraph structural invariants
  --
  --  These tests verify that the patchGraph field (the full bulk
  --  graph with ALL cells and ALL physical bonds) is present and
  --  structurally correct in API responses.  Since patchGraph is
  --  non-optional in the Patch type, successful JSON decoding
  --  already proves the field exists.  These tests additionally
  --  verify:
  --
  --    1. pgNodes count == patchCells (all cells present)
  --    2. pgEdges count == patchBonds (all bonds present)
  --    3. All edge endpoints are valid node IDs
  --    4. Dense patches have interior cells (pgNodes > boundary)
  --
  --  Since pgNodes is [GraphNode] (not [Int]), set-based
  --  comparisons extract gnId from each node before building
  --  the Int set for comparison against edge endpoint IDs.
  --
  --  Reference: Phase 1 item 6 of the fix plan.
  -- ──────────────────────────────────────────────────────────────

  describe "GET /patches/:name — patchGraph structure" $ do

    it "pgNodes count matches patchCells for all patches" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      mapM_ (\summary -> do
        p <- runSuccess env (getPatch (psName summary))
        let g = patchGraph p
        length (pgNodes g) `shouldBe` patchCells p
        ) ps

    it "pgEdges count matches patchBonds for all patches" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      mapM_ (\summary -> do
        p <- runSuccess env (getPatch (psName summary))
        let g = patchGraph p
        length (pgEdges g) `shouldBe` patchBonds p
        ) ps

    it "all edge endpoints are valid node IDs for all patches" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      mapM_ (\summary -> do
        p <- runSuccess env (getPatch (psName summary))
        let g        = patchGraph p
            nodeSet  = Set.fromList (graphNodeIds g)
            allEnds  = Set.fromList (concatMap edgeEndpoints (pgEdges g))
            dangling = allEnds `Set.difference` nodeSet
        Set.null dangling `shouldBe` True
        ) ps

    it "every edge has exactly 2 endpoints for all patches" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      mapM_ (\summary -> do
        p <- runSuccess env (getPatch (psName summary))
        let g = patchGraph p
        mapM_ (\e -> length (edgeEndpoints e) `shouldBe` 2) (pgEdges g)
        ) ps

    it "dense patches have interior cells (pgNodes > boundary cells)" $ \port -> do
      env <- mkEnv port
      let denseNames = ["dense-50", "dense-100", "dense-200",
                        "dense-1000", "honeycomb-145"] :: [Text]
      mapM_ (\name -> do
        p <- runSuccess env (getPatch name)
        let g         = patchGraph p
            nNodes    = length (pgNodes g)
            nBdyCells = Set.size $ Set.fromList
                          (concatMap regionCells (patchRegionData p))
        nNodes `shouldSatisfy` (> nBdyCells)
        ) denseNames

    it "boundary cells from regions are a subset of pgNodes" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      mapM_ (\summary -> do
        p <- runSuccess env (getPatch (psName summary))
        let g       = patchGraph p
            nodeSet = Set.fromList (graphNodeIds g)
            bdySet  = Set.fromList
                        (concatMap regionCells (patchRegionData p))
            missing = bdySet `Set.difference` nodeSet
        Set.null missing `shouldBe` True
        ) ps


  -- ──────────────────────────────────────────────────────────────
  --  GET /patches/:name — patchGraph geometry
  --
  --  Endpoint-level sanity checks on the floating-point geometry
  --  fields produced by @poincare_project@ in
  --  @18_export_json.py@ per the centring-and-scale roadmap
  --  (Steps 1–3):
  --
  --    * @gnScale@ — per-cell conformal factor
  --      @s(u) = (1 − |u|²) / 2@ (Step 2).  Must be positive and
  --      bounded above by ≈ 0.5 (value at the origin).  The
  --      Python exporter clamps at 1e-6 near the disk boundary.
  --
  --    * Quaternion @(gnQx, gnQy, gnQz, gnQw)@ — per-cell
  --      rotation (Step 3).  Must have unit norm.  Hand-written
  --      2D layouts (tree, star, filled, desitter) use the
  --      identity quaternion @(0, 0, 0, 1)@, which trivially
  --      passes.
  --
  --    * Position @(gnX, gnY, gnZ)@ — must lie inside the
  --      Poincaré ball @|u|² ≤ 1@.  For 2D patches the z
  --      coordinate is 0.
  --
  --    * __Bug 1 (centring):__ For every patch whose coordinates
  --      come from @poincare_project@, cell 0 (the Coxeter
  --      identity @g = I@) must land at the origin with scale
  --      ≈ 0.5.  This verifies the Lorentz boost applied at the
  --      start of the projector.
  --
  --  'InvariantSpec' runs the exhaustive per-node version of
  --  these checks during the @validateAll@ integration test.
  --  The tests below are endpoint-level sanity checks that
  --  verify the HTTP layer serves non-degenerate geometry and
  --  catches regressions in the centring boost or scale
  --  computation.
  -- ──────────────────────────────────────────────────────────────

  describe "GET /patches/:name — patchGraph geometry" $ do

    it "gnScale lies in (0, 0.5 + tol] for sampled patches" $ \port -> do
      env <- mkEnv port
      let samples = ["dense-100", "star", "tree", "layer-54-d7",
                     "honeycomb-145", "filled"] :: [Text]
      mapM_ (\name -> do
        p <- runSuccess env (getPatch name)
        mapM_ (\n -> do
          let s = gnScale n
          s `shouldSatisfy` (> 0)
          s `shouldSatisfy` (<= 0.5 + geomTol)
          ) (pgNodes (patchGraph p))
        ) samples

    it "quaternion has unit norm for sampled patches" $ \port -> do
      env <- mkEnv port
      let samples = ["dense-100", "star", "filled", "layer-54-d4",
                     "honeycomb-145", "desitter", "tree"] :: [Text]
      mapM_ (\name -> do
        p <- runSuccess env (getPatch name)
        mapM_ (\n -> do
          let qn2 = gnQx n * gnQx n + gnQy n * gnQy n
                  + gnQz n * gnQz n + gnQw n * gnQw n
          abs (qn2 - 1.0) `shouldSatisfy` (<= geomTol)
          ) (pgNodes (patchGraph p))
        ) samples

    it "position lies inside the Poincaré ball for sampled patches" $ \port -> do
      env <- mkEnv port
      let samples = ["dense-100", "layer-54-d7", "honeycomb-145",
                     "dense-1000", "star"] :: [Text]
      mapM_ (\name -> do
        p <- runSuccess env (getPatch name)
        mapM_ (\n -> do
          let r2 = gnX n * gnX n + gnY n * gnY n + gnZ n * gnZ n
          r2 `shouldSatisfy` (<= 1.0 + geomTol)
          ) (pgNodes (patchGraph p))
        ) samples

    -- Bug 1 fix verification (centring Lorentz boost).
    --
    -- For every patch whose coordinates come from
    -- poincare_project (the Python projector applied to
    -- Coxeter-generated patches), cell 0 is the identity
    -- element of the Coxeter group.  After the centring boost
    -- (roadmap Step 1), g = I must project to the origin of
    -- the Poincaré ball/disk, with conformal scale
    -- s(0) = (1 − 0) / 2 = 0.5.
    --
    -- Hand-written 2D layouts (tree, star, filled, desitter)
    -- are excluded: their central tile does not necessarily
    -- have cell ID 0, and they are not produced by
    -- poincare_project.
    --
    -- If this test fails, the centring boost in
    -- 18_export_json.py:poincare_project is missing or
    -- incorrect — the visual patch will render off-centre and
    -- OrbitControls will orbit the wrong point.
    it "cell 0 of Poincaré-projected patches lands at the origin" $
      \port -> do
        env <- mkEnv port
        mapM_ (\name -> do
          p <- runSuccess env (getPatch name)
          case filter ((== 0) . gnId) (pgNodes (patchGraph p)) of
            [n] -> do
              abs (gnX n)           `shouldSatisfy` (<= geomTol)
              abs (gnY n)           `shouldSatisfy` (<= geomTol)
              abs (gnZ n)           `shouldSatisfy` (<= geomTol)
              abs (gnScale n - 0.5) `shouldSatisfy` (<= geomTol)
            []      -> expectationFailure $
              "Patch " ++ show name
              ++ ": cell 0 not found in pgNodes"
            (_:_:_) -> expectationFailure $
              "Patch " ++ show name
              ++ ": duplicate cell 0 entries in pgNodes"
          ) poincareProjectedPatches


  -- ──────────────────────────────────────────────────────────────
  --  GET /tower
  -- ──────────────────────────────────────────────────────────────

  describe "GET /tower" $ do
    it "returns exactly 11 tower levels" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      length levels `shouldBe` 11

    it "includes all expected tower patches" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let names = map tlPatchName levels
      names `shouldSatisfy` elem "dense-50"
      names `shouldSatisfy` elem "dense-100"
      names `shouldSatisfy` elem "dense-200"
      names `shouldSatisfy` elem "honeycomb-145"
      names `shouldSatisfy` elem "dense-1000"
      names `shouldSatisfy` elem "layer-54-d2"
      names `shouldSatisfy` elem "layer-54-d7"

    -- Regression: dense-100 tower metadata
    it "dense-100 level reports correct metadata" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let d100 = filter (\l -> tlPatchName l == "dense-100") levels
      length d100 `shouldBe` 1
      let lvl = head d100
      tlMaxCut lvl       `shouldBe` 8          -- Regression
      tlOrbits lvl       `shouldBe` 8          -- Regression
      tlRegions lvl      `shouldBe` 717        -- Regression
      tlHasBridge lvl    `shouldBe` True       -- Structural
      tlHasAreaLaw lvl   `shouldBe` True       -- Structural
      tlHasHalfBound lvl `shouldBe` True       -- Structural

    -- Regression: dense-200 tower metadata
    it "dense-200 level reports correct metadata" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let d200 = filter (\l -> tlPatchName l == "dense-200") levels
      length d200 `shouldBe` 1
      let lvl = head d200
      tlMaxCut lvl  `shouldBe` 9                  -- Regression
      tlMonotone lvl `shouldBe` Just (1, "refl")  -- Regression

    -- Regression: dense-1000 tower metadata
    it "dense-1000 level reports correct metadata" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let d1k = filter (\l -> tlPatchName l == "dense-1000") levels
      length d1k `shouldBe` 1
      let lvl = head d1k
      tlMaxCut lvl       `shouldBe` 9          -- Regression
      tlRegions lvl      `shouldBe` 10317      -- Regression
      tlOrbits lvl       `shouldBe` 9          -- Regression
      tlHasBridge lvl    `shouldBe` True       -- Structural
      tlHasAreaLaw lvl   `shouldBe` True       -- Structural
      tlHasHalfBound lvl `shouldBe` True       -- Structural

    -- Regression: honeycomb-145 tower metadata
    it "honeycomb-145 level reports correct metadata" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let h145 = filter (\l -> tlPatchName l == "honeycomb-145") levels
      length h145 `shouldBe` 1
      let lvl = head h145
      tlMaxCut lvl   `shouldBe` 9              -- Regression
      tlRegions lvl  `shouldBe` 1008           -- Regression
      tlOrbits lvl   `shouldBe` 9              -- Regression

    -- Tower monotonicity: each witnessed step has maxCut_lo + k == maxCut_hi
    it "tower monotonicity witnesses are consistent" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let pairs = zip levels (drop 1 levels)
      mapM_ (\(lo, hi) ->
        case tlMonotone hi of
          Nothing     -> pure ()
          Just (k, _) -> (tlMaxCut lo + k) `shouldBe` tlMaxCut hi
        ) pairs


  -- ──────────────────────────────────────────────────────────────
  --  GET /theorems
  -- ──────────────────────────────────────────────────────────────

  describe "GET /theorems" $ do
    it "returns exactly 10 theorems" $ \port -> do
      env  <- mkEnv port
      thms <- runSuccess env getTheorems
      length thms `shouldBe` 10

    it "includes all 7 core theorem numbers (1–7)" $ \port -> do
      env  <- mkEnv port
      thms <- runSuccess env getTheorems
      let numbers = map thmNumber thms
      mapM_ (\n -> numbers `shouldSatisfy` elem n) [1 .. 7]

    -- Structural: all theorems in the current registry are Verified
    it "all theorems have Verified status" $ \port -> do
      env  <- mkEnv port
      thms <- runSuccess env getTheorems
      mapM_ (\t -> thmStatus t `shouldBe` Verified) thms

    -- Structural: theorem 1 references GenericBridge
    it "theorem 1 references GenericBridge" $ \port -> do
      env  <- mkEnv port
      thms <- runSuccess env getTheorems
      let thm1 = filter (\t -> thmNumber t == 1) thms
      length thm1 `shouldBe` 1
      thmModule (head thm1) `shouldBe` "Bridge/GenericBridge.agda"

    -- Structural: theorem 3 references HalfBound
    it "theorem 3 references HalfBound" $ \port -> do
      env  <- mkEnv port
      thms <- runSuccess env getTheorems
      let thm3 = filter (\t -> thmNumber t == 3) thms
      length thm3 `shouldBe` 1
      thmModule (head thm3) `shouldBe` "Bridge/HalfBound.agda"


  -- ──────────────────────────────────────────────────────────────
  --  GET /curvature
  --
  --  Curvature data uses the fields curvTotal / curvEuler /
  --  curvDenominator in both the per-patch CurvatureData and the
  --  top-level CurvatureSummary types (Types.hs).  The
  --  curvDenominator field (10 for 2D, 20 for 3D) disambiguates
  --  the rational unit of the integer numerators.
  -- ──────────────────────────────────────────────────────────────

  describe "GET /curvature" $ do
    it "returns curvature summaries" $ \port -> do
      env <- mkEnv port
      cs  <- runSuccess env getCurvature
      length cs `shouldSatisfy` (>= 1)

    -- Structural: every summary must pass Gauss-Bonnet
    -- (Note: for 3D patches this is tautological — see Issue #8
    -- in Invariants.hs.  The check is independently meaningful
    -- only for 2D patches where total and euler are computed
    -- from separate sources.)
    it "all summaries satisfy Gauss-Bonnet" $ \port -> do
      env <- mkEnv port
      cs  <- runSuccess env getCurvature
      mapM_ (\c -> csGaussBonnet c `shouldBe` True) cs

    it "includes filled, desitter, and honeycomb-3d patches" $ \port -> do
      env <- mkEnv port
      cs  <- runSuccess env getCurvature
      let names = map csPatchName cs
      names `shouldSatisfy` elem "filled"
      names `shouldSatisfy` elem "desitter"
      names `shouldSatisfy` elem "honeycomb-3d"
      names `shouldSatisfy` elem "honeycomb-145"


  -- ──────────────────────────────────────────────────────────────
  --  GET /meta
  -- ──────────────────────────────────────────────────────────────

  describe "GET /meta" $ do
    -- Structural: Agda version is pinned at 2.8.0 for this project
    it "returns metadata with Agda version 2.8.0" $ \port -> do
      env <- mkEnv port
      m   <- runSuccess env getMeta
      metaAgdaVersion m `shouldBe` "2.8.0"

    it "returns a non-empty version and data hash" $ \port -> do
      env <- mkEnv port
      m   <- runSuccess env getMeta
      metaVersion m  `shouldSatisfy` (/= "")
      metaDataHash m `shouldSatisfy` (/= "")

    it "version matches the repository version" $ \port -> do
      env <- mkEnv port
      m   <- runSuccess env getMeta
      -- Regression: tracks the current repository version tag
      metaVersion m `shouldBe` "0.6.0"