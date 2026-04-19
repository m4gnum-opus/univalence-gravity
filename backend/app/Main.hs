-- | Entry point for the Univalence Gravity Haskell backend.
--
--   Parses CLI arguments (@--data-dir@, @--port@), loads all JSON
--   data produced by @18_export_json.py@, validates data invariants
--   at startup, and launches the Servant\/Warp HTTP server.
--
--   At this point @cabal run@ works end-to-end (Milestone M3).
--
--   Usage:
--
--   > univalence-gravity-backend [--data-dir DIR] [--port PORT] [--help]
--
--   Defaults:
--
--   > --data-dir  ../data
--   > --port      8080
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §8

module Main (main) where

import Control.Monad           (unless)
import System.Environment      (getArgs)
import System.Exit             (exitFailure, exitSuccess)
import System.IO               (hFlush, hPutStrLn, stderr, stdout)

import Network.Wai.Handler.Warp (run)

import DataLoader
  ( loadCurvatureSummaries
  , loadMeta
  , loadPatches
  , loadTheorems
  , loadTower
  )
import Invariants (validateAll)
import Server     (app)
import Types      (patchRegionData)


-- ════════════════════════════════════════════════════════════════
--  Configuration
-- ════════════════════════════════════════════════════════════════

-- | Parsed command-line configuration.
data Config = Config
  { cfgDataDir :: !FilePath
  , cfgPort    :: !Int
  }

-- | Defaults: @./data@ on port 8080.
defaultConfig :: Config
defaultConfig = Config
  { cfgDataDir = "../data"
  , cfgPort    = 8080
  }


-- ════════════════════════════════════════════════════════════════
--  CLI Argument Parsing
-- ════════════════════════════════════════════════════════════════

-- | Help text printed on @--help@ or parse error.
usage :: String
usage = unlines
  [ "univalence-gravity-backend — REST API for verified holographic patch data"
  , ""
  , "Usage: univalence-gravity-backend [OPTIONS]"
  , ""
  , "Options:"
  , "  --data-dir DIR   Path to the data/ directory (default: ./data)"
  , "  --port PORT      HTTP port to listen on      (default: 8080)"
  , "  --help           Show this help message and exit"
  , ""
  , "The data/ directory is produced by sim/prototyping/18_export_json.py."
  , "See docs/engineering/backend-spec-haskell.md for the full specification."
  ]

-- | Simple recursive-descent argument parser.
--
--   Returns @Left msg@ on @--help@ or on a parse error (the
--   caller distinguishes the two by checking whether @--help@
--   was among the original arguments).  Returns @Right cfg@ on
--   success.
parseArgs :: [String] -> Either String Config
parseArgs = go defaultConfig
  where
    go cfg []                            = Right cfg
    go _   ("--help"     : _)            = Left usage
    go cfg ("--data-dir" : dir  : rest)  = go cfg { cfgDataDir = dir } rest
    go _   ("--data-dir" : [])           = Left "--data-dir requires an argument"
    go cfg ("--port"     : pStr : rest)  =
      case reads pStr of
        [(n, "")] | n > 0 && n <= 65535  -> go cfg { cfgPort = n } rest
        _                                -> Left $ "Invalid port number: " ++ pStr
    go _   ("--port"     : [])           = Left "--port requires an argument"
    go _   (unknown      : _)            = Left $ "Unknown argument: " ++ unknown


-- ════════════════════════════════════════════════════════════════
--  Main
-- ════════════════════════════════════════════════════════════════

main :: IO ()
main = do
    rawArgs <- getArgs
    cfg     <- case parseArgs rawArgs of
      Right c  -> pure c
      Left msg -> do
        -- --help → print to stdout and exit 0;
        -- parse error → print to stderr and exit 1.
        if "--help" `elem` rawArgs
          then putStr   msg >> exitSuccess
          else hPutStrLn stderr msg
               >> hPutStrLn stderr ("Run with --help for usage.\n")
               >> exitFailure

    let dataDir = cfgDataDir cfg
        port    = cfgPort    cfg

    -- ── Banner ─────────────────────────────────────────────────
    putStrLn "╔════════════════════════════════════════════════╗"
    putStrLn "║  Univalence Gravity — Haskell Backend v0.1.0   ║"
    putStrLn "╚════════════════════════════════════════════════╝"
    putStrLn ""
    putStrLn $ "  Data directory : " ++ dataDir
    putStrLn $ "  Port           : " ++ show port
    putStrLn ""

    -- ── 1. Load all JSON data ──────────────────────────────────
    --
    -- Each loader reads from data/ and decodes JSON into the
    -- domain types from Types.hs.  A decode failure raises an
    -- IOError with the file path and the Aeson error string,
    -- terminating the process with a descriptive message.

    putStr   "  Loading patches           ... " >> hFlush stdout
    patches <- loadPatches dataDir
    putStrLn $ show (length patches) ++ " patches"

    putStr   "  Loading tower             ... " >> hFlush stdout
    tower <- loadTower dataDir
    putStrLn $ show (length tower) ++ " levels"

    putStr   "  Loading theorems          ... " >> hFlush stdout
    theorems <- loadTheorems dataDir
    putStrLn $ show (length theorems) ++ " theorems"

    putStr   "  Loading curvature         ... " >> hFlush stdout
    curvature <- loadCurvatureSummaries dataDir
    putStrLn $ show (length curvature) ++ " entries"

    putStr   "  Loading metadata          ... " >> hFlush stdout
    meta <- loadMeta dataDir
    putStrLn "ok"

    -- ── 2. Validate invariants ─────────────────────────────────
    --
    -- Run every data-integrity check from backend-spec §6 against
    -- the loaded data.  An empty list means all checks pass; any
    -- violation causes the server to abort before binding a port.

    putStr   "\n  Validating invariants     ... " >> hFlush stdout
    let violations = validateAll patches tower

    unless (null violations) $ do
      putStrLn $ "FAILED (" ++ show (length violations) ++ " violations)\n"
      mapM_ (\v -> putStrLn $ "    ✗ " ++ v) violations
      putStrLn ""
      hPutStrLn stderr "  Aborting: data invariants violated."
      exitFailure

    putStrLn "passed"

    -- ── Summary ────────────────────────────────────────────────
    let totalRegions = sum (map (length . patchRegionData) patches)
    putStrLn ""
    putStrLn $ "  ✓ " ++ show (length patches) ++ " patches, "
            ++ show totalRegions ++ " regions, "
            ++ "0 invariant violations."

    -- ── 3. Start Servant server ────────────────────────────────
    --
    -- Build the WAI Application (with CORS + Cache-Control
    -- middleware) and hand it to Warp.  All data is held in
    -- memory via handler closures; no further file I/O occurs.

    putStrLn ""
    putStrLn $ "  Listening on http://localhost:" ++ show port
    putStrLn   "  Press Ctrl-C to stop."
    putStrLn ""

    run port (app patches tower theorems curvature meta)