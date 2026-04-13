-- | JSON data loading for the Univalence Gravity Haskell backend.
--
--   Each function in this module reads from the @data/@ directory
--   produced by @18_export_json.py@ and decodes the JSON into the
--   domain types from "Types".  All data is loaded eagerly at server
--   startup; the backend then serves it from memory.
--
--   If any file is missing or malformed, the loader 'fail's with a
--   descriptive error message including the file path and the Aeson
--   parse error.  The caller ('Main.hs') is expected to catch this
--   during the startup sequence and report it before exiting.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §4, §8
--
--   Expected directory layout (produced by @18_export_json.py@):
--
--   > \<dataDir\>/
--   > ├── patches/
--   > │   ├── dense-100.json
--   > │   ├── dense-200.json
--   > │   ├── ...
--   > │   └── tree.json
--   > ├── tower.json
--   > ├── theorems.json
--   > ├── curvature.json
--   > └── meta.json

module DataLoader
  ( -- * Loaders
    loadPatches
  , loadTower
  , loadTheorems
  , loadMeta
  , loadCurvatureSummaries
  ) where

import Control.Monad          (forM)
import Data.Aeson             (FromJSON, eitherDecodeStrict')
import qualified Data.ByteString as BS
import Data.List              (sort)
import System.Directory       (doesDirectoryExist, listDirectory)
import System.FilePath        ((</>), takeExtension)

import Types


-- ════════════════════════════════════════════════════════════════
--  Internal helper
-- ════════════════════════════════════════════════════════════════

-- | Read a JSON file from disk and decode it strictly into a
--   Haskell value.  Uses 'eitherDecodeStrict'' so that both the
--   parse and the resulting value are fully evaluated — no thunks
--   are retained from the raw 'BS.ByteString'.
--
--   On decode failure, calls 'fail' (which raises an 'IOError' in
--   'IO') with a message containing the file path and the Aeson
--   error string.  On a missing file, 'BS.readFile' itself raises
--   an 'IOException' with the OS-level error.
decodeFile :: FromJSON a => FilePath -> IO a
decodeFile path = do
  bytes <- BS.readFile path
  case eitherDecodeStrict' bytes of
    Left err  -> fail $ "Failed to decode " ++ path ++ ": " ++ err
    Right val -> pure val


-- ════════════════════════════════════════════════════════════════
--  Public API
-- ════════════════════════════════════════════════════════════════

-- | Discover and load every @*.json@ file inside
--   @\<dataDir\>\/patches\/@, returning the list sorted by
--   filename (alphabetical by patch name).
--
--   Fails if the @patches/@ subdirectory does not exist or if any
--   individual file cannot be decoded as a 'Patch'.
--
--   Non-JSON entries (e.g. editor backup files, subdirectories)
--   are silently skipped.
loadPatches :: FilePath -> IO [Patch]
loadPatches dataDir = do
  let patchDir = dataDir </> "patches"
  exists <- doesDirectoryExist patchDir
  if not exists
    then fail $ "Patch directory does not exist: " ++ patchDir
    else do
      entries <- listDirectory patchDir
      let jsonFiles = sort [ f | f <- entries
                               , takeExtension f == ".json" ]
      forM jsonFiles $ \f -> decodeFile (patchDir </> f)

-- | Load the resolution tower from @\<dataDir\>\/tower.json@.
--
--   The file contains a JSON array of 'TowerLevel' objects ordered
--   from the coarsest resolution (Dense-50) to the finest
--   (Dense-200), followed by the {5,4} layer levels.
loadTower :: FilePath -> IO [TowerLevel]
loadTower dataDir = decodeFile (dataDir </> "tower.json")

-- | Load the theorem registry from @\<dataDir\>\/theorems.json@.
--
--   The file contains a JSON array of 'Theorem' objects mirroring
--   the canonical theorem table in
--   @docs\/formal\/01-theorems.md@.
loadTheorems :: FilePath -> IO [Theorem]
loadTheorems dataDir = decodeFile (dataDir </> "theorems.json")

-- | Load server and data metadata from @\<dataDir\>\/meta.json@.
--
--   Contains the repository version, build timestamp, Agda
--   compiler version, and a truncated SHA-256 hash of the
--   exported data (used as an ETag by the API).
loadMeta :: FilePath -> IO Meta
loadMeta dataDir = decodeFile (dataDir </> "meta.json")

-- | Load top-level curvature summaries from
--   @\<dataDir\>\/curvature.json@.
--
--   One entry per patch that has curvature data (filled, desitter,
--   dense-50, dense-100, dense-200).  Patches without curvature
--   (e.g. tree, star, layer-54) are absent from this file; their
--   per-patch curvature is @null@ in the patch JSON instead.
loadCurvatureSummaries :: FilePath -> IO [CurvatureSummary]
loadCurvatureSummaries dataDir =
  decodeFile (dataDir </> "curvature.json")