{-# LANGUAGE DataKinds        #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators    #-}

-- | Servant handler implementations and WAI middleware for the
--   Univalence Gravity Haskell backend.
--
--   This module provides the 'app' function that combines all
--   handler implementations with CORS and Cache-Control middleware
--   into a complete WAI 'Application'.  All data is held in memory
--   (closed over by handler closures); no database or file I\/O
--   occurs after startup.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §5, §8

module Server
  ( -- * Application constructor
    app
  ) where

import qualified Data.Map.Strict as Map
import Data.Text                 (Text)
import Network.HTTP.Types.Header (hCacheControl)
import Network.Wai
  ( Application
  , Middleware
  , mapResponseHeaders
  , pathInfo
  )
import Network.Wai.Middleware.Cors
  ( CorsResourcePolicy (..)
  , cors
  , simpleHeaders
  , simpleCorsResourcePolicy
  )
import Servant
  ( Handler
  , Server
  , err404
  , serve
  , throwError
  , (:<|>) (..)
  )

import Api   (API, api)
import Types


-- ════════════════════════════════════════════════════════════════
--  Application
-- ════════════════════════════════════════════════════════════════

-- | Build a complete WAI 'Application' from pre-loaded, verified
--   data.
--
--   The application serves the Servant 'API' behind CORS and
--   @Cache-Control@ middleware.  A 'Map.Map' index on patch names
--   is built once at construction time so that
--   @GET \/patches\/:name@ lookups are O(log n).
--
--   Intended to be called once during the startup sequence in
--   @Main.hs@ after all JSON data has been loaded and validated.
app
  :: [Patch]              -- ^ All loaded patch instances
  -> [TowerLevel]         -- ^ Resolution tower levels
  -> [Theorem]            -- ^ Theorem registry
  -> [CurvatureSummary]   -- ^ Per-patch curvature summaries
  -> Meta                 -- ^ Server and data metadata
  -> Application
app patches tower theorems curvature meta =
    corsMiddleware
  . cacheMiddleware
  $ serve api (server patchIndex patches tower theorems curvature meta)
  where
    -- Build a name → Patch index once at startup.
    patchIndex :: Map.Map Text Patch
    patchIndex = Map.fromList
      [ (patchName p, p) | p <- patches ]


-- ════════════════════════════════════════════════════════════════
--  Servant server
-- ════════════════════════════════════════════════════════════════

-- | Compose all endpoint handlers into a Servant 'Server' for
--   the 'API' type.
--
--   The handler order must match the @(:\<|\>)@ order in the
--   @type API@ definition in "Api".
server
  :: Map.Map Text Patch   -- ^ Name-indexed patch lookup
  -> [Patch]              -- ^ Full patch list (for summaries + health)
  -> [TowerLevel]
  -> [Theorem]
  -> [CurvatureSummary]
  -> Meta
  -> Server API
server patchIndex patches tower theorems curvature meta =
       patchesHandler patches
  :<|> patchHandler patchIndex
  :<|> towerHandler tower
  :<|> theoremsHandler theorems
  :<|> curvatureHandler curvature
  :<|> metaHandler meta
  :<|> healthHandler patches


-- ════════════════════════════════════════════════════════════════
--  Handlers
-- ════════════════════════════════════════════════════════════════

-- | @GET \/patches@ — list all patches as lightweight summaries.
--
--   Projects each 'Patch' to a 'PatchSummary', dropping the
--   (potentially large) region data, curvature details, and
--   half-bound statistics.
patchesHandler :: [Patch] -> Handler [PatchSummary]
patchesHandler = pure . map summarise

-- | @GET \/patches\/:name@ — full patch data by name.
--
--   Returns the complete 'Patch' including all region data,
--   curvature, and half-bound statistics.  Responds with HTTP 404
--   if the name does not match any loaded patch.
patchHandler :: Map.Map Text Patch -> Text -> Handler Patch
patchHandler patchIndex name =
  case Map.lookup name patchIndex of
    Just p  -> pure p
    Nothing -> throwError err404

-- | @GET \/tower@ — resolution tower levels with monotonicity
--   witnesses.
towerHandler :: [TowerLevel] -> Handler [TowerLevel]
towerHandler = pure

-- | @GET \/theorems@ — theorem registry from
--   @docs\/formal\/01-theorems.md@.
theoremsHandler :: [Theorem] -> Handler [Theorem]
theoremsHandler = pure

-- | @GET \/curvature@ — Gauss–Bonnet summaries across all patches
--   that carry curvature data.
curvatureHandler :: [CurvatureSummary] -> Handler [CurvatureSummary]
curvatureHandler = pure

-- | @GET \/meta@ — server version, Agda version, build date, and
--   data hash.
metaHandler :: Meta -> Handler Meta
metaHandler = pure

-- | @GET \/health@ — runtime health check.
--
--   Constructed on every request from the in-memory patch list.
--   Reports the number of loaded patches, the total region count
--   across all patches, and a fixed @\"ok\"@ status string
--   (the server would not be running if data loading had failed).
--
--   This endpoint is exempt from the @Cache-Control@ middleware
--   (see 'cacheMiddleware') so that monitoring tools and load
--   balancer probes always receive a fresh response.
healthHandler :: [Patch] -> Handler Health
healthHandler patches = pure Health
  { status      = "ok"
  , patchCount  = length patches
  , regionCount = sum (map (length . patchRegionData) patches)
  }


-- ════════════════════════════════════════════════════════════════
--  Patch → PatchSummary projection
-- ════════════════════════════════════════════════════════════════

-- | Project a full 'Patch' to a lightweight 'PatchSummary'.
--
--   Retains only the scalar metadata fields needed for the
--   @\/patches@ listing endpoint; drops 'patchRegionData',
--   'patchCurvature', 'patchHalfBound', and the bond\/boundary
--   counts.
summarise :: Patch -> PatchSummary
summarise p = PatchSummary
  { psName      = patchName      p
  , psTiling    = patchTiling     p
  , psDimension = patchDimension  p
  , psCells     = patchCells      p
  , psRegions   = patchRegions    p
  , psOrbits    = patchOrbits     p
  , psMaxCut    = patchMaxCut     p
  , psStrategy  = patchStrategy   p
  }


-- ════════════════════════════════════════════════════════════════
--  Middleware
-- ════════════════════════════════════════════════════════════════

-- | CORS middleware — allows all origins during development.
--
--   For production deployment behind a known frontend domain,
--   replace @corsOrigins = Nothing@ with
--   @corsOrigins = Just ([\"https:\/\/your-frontend.example\"], False)@.
--
--   Only safe read-only methods are permitted; the data is public
--   (MIT-licensed repository).
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §5.3
corsMiddleware :: Middleware
corsMiddleware = cors (const $ Just policy)
  where
    policy :: CorsResourcePolicy
    policy = simpleCorsResourcePolicy
      { corsOrigins        = Nothing          -- allow all origins
      , corsMethods        = ["GET", "HEAD", "OPTIONS"]
      , corsRequestHeaders = simpleHeaders <> ["content-type"]
      }

-- | Cache-Control middleware — marks responses as immutable static
--   data with a 24-hour max-age.
--
--   The served data changes only when the Agda code is re-verified
--   and @18_export_json.py@ is re-run, so aggressive caching is
--   appropriate for data endpoints.
--
--   The @\/health@ endpoint is __exempt__: monitoring tools (uptime
--   checkers, load balancer probes, Kubernetes liveness probes)
--   expect fresh responses and must not see cached staleness.
--   The @\/meta@ endpoint's @dataHash@ field can be used by the
--   frontend as an ETag for cache-busting on data endpoints.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §5.3
--   Fix for critique Issue #10 (Cache-Control on \/health).
cacheMiddleware :: Middleware
cacheMiddleware baseApp req respond
  | pathInfo req == ["health"] =
      -- Health endpoint: no Cache-Control header.  Pass through
      -- to the base application unchanged.
      baseApp req respond
  | otherwise =
      -- All other endpoints: append the immutable cache header.
      baseApp req $
        respond . mapResponseHeaders
          (((hCacheControl, cacheValue) :) . filter ((/= hCacheControl) . fst))
  where
    cacheValue = "max-age=86400, immutable"