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
--   Reference: docs\/engineering\/backend-spec-haskell.md §10.3

module ApiSpec (spec) where

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
--  Test infrastructure
-- ════════════════════════════════════════════════════════════════

-- | Path to the data directory.  Assumes @cabal test@ is run from
--   the @backend\/@ project root, where @data\/@ is a symlink to
--   the repo-root @data\/@ produced by @18_export_json.py@.
dataDir :: FilePath
dataDir = "data"

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
      patchCount h  `shouldSatisfy` (>= 10)     -- Structural: ≥10 patches loaded
      regionCount h `shouldSatisfy` (> 0)


  -- ──────────────────────────────────────────────────────────────
  --  GET /patches
  -- ──────────────────────────────────────────────────────────────

  describe "GET /patches" $ do
    it "returns a non-empty list of patch summaries" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      length ps `shouldSatisfy` (>= 10)          -- Structural: ≥10 patches

    it "includes all known patches by name" $ \port -> do
      env <- mkEnv port
      ps  <- runSuccess env getPatches
      let names = map psName ps
      -- Structural: every expected patch must be present.
      names `shouldSatisfy` elem "dense-100"
      names `shouldSatisfy` elem "dense-200"
      names `shouldSatisfy` elem "dense-50"
      names `shouldSatisfy` elem "star"
      names `shouldSatisfy` elem "tree"
      names `shouldSatisfy` elem "filled"
      names `shouldSatisfy` elem "desitter"
      names `shouldSatisfy` elem "honeycomb-3d"
      names `shouldSatisfy` elem "layer-54-d2"
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

    -- ── Honeycomb-3D ───────────────────────────────────────────

    it "returns full data for honeycomb-3d" $ \port -> do
      env <- mkEnv port
      p   <- runSuccess env (getPatch "honeycomb-3d")
      -- Structural
      patchName p      `shouldBe` "honeycomb-3d"
      patchTiling p    `shouldBe` Tiling435
      patchDimension p `shouldBe` 3
      patchCells p     `shouldBe` 32
      -- Regression (18_export_json.py: build_435_bfs_json(7, ..., max_rc=4)
      -- produces 34 regions.  The Agda Honeycomb3DSpec has 26 regions
      -- (single-cell only); the 145-region set is a separate Agda module
      -- (Honeycomb145Spec.agda) not exported to the backend JSON.
      -- See Issue #2 in the backend critique.)
      patchRegions p   `shouldBe` 34
      -- BFS honeycomb has max min-cut 1 for single cells, higher for
      -- multi-cell regions
      patchRegions p   `shouldSatisfy` (> 0)
      patchCurvature p `shouldSatisfy` (/= Nothing)

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
  --  GET /tower
  -- ──────────────────────────────────────────────────────────────

  describe "GET /tower" $ do
    it "returns at least 5 tower levels" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      length levels `shouldSatisfy` (>= 5)

    it "includes dense-100 and dense-200 levels" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let names = map tlPatchName levels
      names `shouldSatisfy` elem "dense-100"
      names `shouldSatisfy` elem "dense-200"

    -- Regression: dense-100 tower metadata
    it "dense-100 level reports correct metadata" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let d100 = filter (\l -> tlPatchName l == "dense-100") levels
      length d100 `shouldBe` 1
      let lvl = head d100
      tlMaxCut lvl      `shouldBe` 8           -- Regression
      tlOrbits lvl      `shouldBe` 8           -- Regression
      tlRegions lvl     `shouldBe` 717         -- Regression
      tlHasBridge lvl   `shouldBe` True        -- Structural
      tlHasAreaLaw lvl  `shouldBe` True        -- Structural
      tlHasHalfBound lvl `shouldBe` True       -- Structural

    -- Regression: dense-200 tower metadata
    it "dense-200 level reports correct metadata" $ \port -> do
      env    <- mkEnv port
      levels <- runSuccess env getTower
      let d200 = filter (\l -> tlPatchName l == "dense-200") levels
      length d200 `shouldBe` 1
      let lvl = head d200
      tlMaxCut lvl  `shouldBe` 9               -- Regression
      tlMonotone lvl `shouldBe` Just (1, "refl")  -- Regression

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
    it "returns at least 7 core theorems" $ \port -> do
      env  <- mkEnv port
      thms <- runSuccess env getTheorems
      length thms `shouldSatisfy` (>= 7)

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

    it "includes filled and desitter patches" $ \port -> do
      env <- mkEnv port
      cs  <- runSuccess env getCurvature
      let names = map csPatchName cs
      names `shouldSatisfy` elem "filled"
      names `shouldSatisfy` elem "desitter"


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
      metaVersion m `shouldBe` "0.5.0"