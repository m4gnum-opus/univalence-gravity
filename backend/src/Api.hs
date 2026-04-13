{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}

-- | Servant API type definition for the Univalence Gravity backend.
--
--   This module contains a single type alias @API@ encoding every
--   endpoint as a type-level description, plus a term-level 'Proxy'
--   consumed by Servant's server and client machinery.
--
--   No handler implementations live here — those are in "Server".
--   The separation keeps the API type importable by both the server
--   ('Server.hs') and the test client ('test/ApiSpec.hs') without
--   pulling in handler dependencies.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §5

module Api
  ( -- * API type
    API
    -- * Proxy
  , api
  ) where

import Data.Proxy  (Proxy (..))
import Data.Text   (Text)
import Servant.API ((:>), (:<|>), Capture, Get, JSON)

import Types
  ( CurvatureSummary
  , Health
  , Meta
  , Patch
  , PatchSummary
  , Theorem
  , TowerLevel
  )


-- | The complete REST API served by the backend.
--
--   Every endpoint returns JSON.  The data is static and
--   pre-computed; no mutation endpoints exist.
--
--   @
--   GET \/patches            → [PatchSummary]
--   GET \/patches\/:name     → Patch
--   GET \/tower              → [TowerLevel]
--   GET \/theorems           → [Theorem]
--   GET \/curvature          → [CurvatureSummary]
--   GET \/meta               → Meta
--   GET \/health             → Health
--   @
type API =
       "patches"                        :> Get '[JSON] [PatchSummary]
  :<|> "patches" :> Capture "name" Text :> Get '[JSON] Patch
  :<|> "tower"                          :> Get '[JSON] [TowerLevel]
  :<|> "theorems"                       :> Get '[JSON] [Theorem]
  :<|> "curvature"                      :> Get '[JSON] [CurvatureSummary]
  :<|> "meta"                           :> Get '[JSON] Meta
  :<|> "health"                         :> Get '[JSON] Health


-- | Term-level witness for 'API', passed to
--   @Servant.Server.serve@ and @Servant.Client.client@.
api :: Proxy API
api = Proxy