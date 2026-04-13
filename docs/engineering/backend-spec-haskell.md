# Haskell Backend Specification

**Architecture, data model, API contract, and implementation plan for the hand-written Haskell serving layer.**

**Audience:** Developers building the backend; AI assistants generating Haskell code; reviewers evaluating the architecture.

**Prerequisites:** Familiarity with the repository architecture ([`getting-started/architecture.md`](../getting-started/architecture.md)), the oracle pipeline ([`engineering/oracle-pipeline.md`](oracle-pipeline.md)), and the theorem registry ([`formal/01-theorems.md`](../formal/01-theorems.md)).

---

## 1. Architectural Position

The backend is a **hand-written Haskell server** — not compiled from Agda. Cubical Agda's `--cubical` flag introduces interval variables, Glue types, and higher inductive types that have no meaningful runtime extraction. The GHC backend does not support cubical primitives. Attempting `agda --compile --ghc` on any `src/` module will either fail outright or produce vacuous stubs.

The backend's role is to **serve pre-computed, verified data** via a REST API:

```
┌─────────────────────────────────┐
│  Agda (src/)                    │
│  VERIFICATION LAYER             │
│  Type-checks all theorems.      │
│  NOT a runtime.                 │
│  Produces .agdai cache files.   │
└─────────────────────────────────┘
         │ (verified data)
         ▼
┌─────────────────────────────────┐
│  Python Oracle (sim/)           │
│  COMPUTATION LAYER              │
│  Coxeter geometry, max-flow,    │
│  region enumeration, areas.     │
│  Emits JSON + Agda modules.     │
└─────────────────────────────────┘
         │ (JSON data export)
         ▼
┌─────────────────────────────────┐
│  Haskell Backend (backend/)     │
│  SERVING LAYER                  │
│  Reads JSON data.               │
│  Serves via REST API.           │
│  Type-safe domain model.        │
└─────────────────────────────────┘
         │ (JSON API)
         ▼
┌─────────────────────────────────┐
│  WebGL Frontend (frontend/)     │
│  VISUALIZATION LAYER            │
│  Three.js + TypeScript.         │
│  3D patch rendering, dashboards │
└─────────────────────────────────┘
```

The Haskell backend provides academic credibility through:

- A **type-safe domain model** mirroring (but not compiled from) the Agda types
- **Servant**-based API with compile-time route checking
- **Property-based testing** (QuickCheck/Hedgehog) on data invariants
- **Reproducible builds** via Nix or Cabal freeze files

---

## 2. Technology Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Language | GHC 9.6.x (Haskell 2021) | Matches the GHC used to build Agda itself |
| Web framework | Servant 0.20+ | Type-safe API, compile-time route checking, automatic Swagger/OpenAPI generation |
| JSON parsing | Aeson 2.x | Standard, well-optimized |
| Data loading | File-based (JSON) | No database needed — all data is static and pre-computed |
| Build system | Cabal 3.14+ (with freeze file) | Reproducible builds; compatible with the existing GHCup toolchain from `setup.md` |
| Testing | Hspec + QuickCheck | Property-based testing of data invariants |
| Documentation | Haddock + OpenAPI 3.0 | Auto-generated from types |
| Deployment | Static binary (Nix optional) | Single-binary deployment, no runtime dependencies |

---

## 3. Data Model

The Haskell domain types mirror the Agda types from `src/` without attempting to replicate the proof content. Only the **data** that the proofs verify is served — not the proofs themselves.

### 3.1 Core Types

```haskell
-- | A verified holographic patch instance.
data Patch = Patch
  { patchName              :: Text
  , patchTiling            :: Tiling
  , patchDimension         :: Int            -- 1, 2, or 3
  , patchCells             :: Int            -- number of tiles/cubes
  , patchRegions           :: Int            -- number of boundary regions
  , patchOrbits            :: Int            -- orbit representatives (0 = flat enum)
  , patchMaxCut            :: Int            -- maximum min-cut value
  , patchBonds             :: Int            -- internal shared faces/edges
  , patchBoundary          :: Int            -- boundary legs/faces
  , patchDensity           :: Double         -- 2 * bonds / cells
  , patchStrategy          :: GrowthStrategy
  , patchRegionData        :: [Region]
  , patchCurvature         :: Maybe CurvatureData
  , patchHalfBound         :: Maybe HalfBoundData
  , patchHalfBoundVerified :: Bool           -- Agda-verified half-bound exists
  }

data Tiling
  = Tiling54    -- {5,4} hyperbolic pentagonal (2D)
  | Tiling435   -- {4,3,5} hyperbolic cubic (3D)
  | Tiling53    -- {5,3} spherical dodecahedron (2D)
  | Tiling44    -- {4,4} Euclidean square grid (2D)
  | Tree        -- 1D weighted binary tree (pilot instance)
  deriving (Show, Eq, Generic, ToJSON, FromJSON)

data GrowthStrategy
  = BFS         -- concentric shells
  | Dense       -- greedy max-connectivity
  | Geodesic    -- tube along geodesic
  | Hemisphere  -- half-space BFS
  deriving (Show, Eq, Generic, ToJSON, FromJSON)
```

**`patchOrbits` semantics:** The value `0` indicates flat enumeration (no orbit reduction was applied). When orbit reduction is used, the value is the number of distinct orbit representatives (e.g. 8 for Dense-100, 9 for Dense-200, 2 for the {5,4} layer patches). A `Maybe Int` with `Nothing` for flat enumeration would be more precise, but the `0 = flat` convention keeps the JSON schema simpler and is consistent across all patches.

**`patchHalfBoundVerified`:** `True` when a corresponding `Boundary/*HalfBound.agda` module exists that machine-checks `2·S(A) ≤ area(A)` for every region via `abstract (k, refl)` witnesses. Currently `True` only for `dense-100` and `dense-200`. For all other patches, the half-bound data (if present) is a Python-side numerical check only.

### 3.2 Region Data

```haskell
-- | A single cell-aligned boundary region.
data Region = Region
  { regionId        :: Int
  , regionCells     :: [Int]          -- cell IDs in the region
  , regionSize      :: Int            -- number of cells
  , regionMinCut    :: Int            -- S(A) — boundary min-cut entropy
  , regionArea      :: Int            -- boundary surface area (face-count)
  , regionOrbit     :: Text           -- orbit representative name (e.g. "mc3")
  , regionHalfSlack :: Maybe Int      -- area - 2*S (Nothing if not computed)
  , regionRatio     :: Double         -- S / area
  }
```

**Area model:** The `regionArea` field uses the face-count boundary area formula:

| Tiling | Formula | Faces per cell |
|--------|---------|----------------|
| `Tiling435` | `6k − 2·\|internal faces within A\|` | 6 (cube) |
| `Tiling54` | `5k − 2·\|internal bonds within A\|` | 5 (pentagon) |
| `Tiling53` | `5k − 2·\|internal bonds within A\|` | 5 (pentagon) |
| `Tree` | `2k` (simplified proxy) | N/A |

For single-cell regions in the star/desitter patches (`Tiling54`/`Tiling53`), each N-tile shares 0 edges with other N-tiles (only with C), so `area = 5 · 1 − 0 = 5`. For pairs, `area = 5 · 2 − 0 = 10` (N-tiles share no edges with each other in the restricted star topology). The Agda-verified area law (`Boundary/Dense*AreaLaw.agda`) uses this same formula; patches without Agda-verified area laws (tree, star, desitter, honeycomb, layer-54) may have `patchHalfBound` data computed by the Python oracle but `patchHalfBoundVerified = false`.

### 3.3 Curvature Data

```haskell
-- | Edge/vertex curvature classification for a patch.
data CurvatureData = CurvatureData
  { curvClasses       :: [CurvatureClass]
  , curvTotal         :: Int          -- Σ κ as integer numerator
  , curvEuler         :: Int          -- χ as integer numerator
  , curvGaussBonnet   :: Bool         -- total ≡ euler (always True)
  , curvDenominator   :: Int          -- rational denominator (10 or 20)
  }

data CurvatureClass = CurvatureClass
  { ccName      :: Text               -- e.g. "vTiling", "ev5"
  , ccCount     :: Int                -- number of vertices/edges in class
  , ccValence   :: Int                -- edge degree or face valence
  , ccKappa     :: Int                -- curvature as integer numerator
  , ccLocation  :: Text               -- "interior" or "boundary"
  }
```

**Curvature denomination convention:** All curvature values are stored as integer numerators. The `curvDenominator` field disambiguates the unit:

| Dimension | Curvature lives on | Denominator | True rational |
|-----------|-------------------|-------------|---------------|
| 2D ({5,4}, {5,3}) | Vertices | **10** | `curvTotal / 10` (tenths, ℚ₁₀ encoding) |
| 3D ({4,3,5}) | Edges | **20** | `curvTotal / 20` (twentieths) |

For example, a `ccKappa` of `−5` with `curvDenominator = 20` means `κ = −5/20 = −0.25`. A `ccKappa` of `−2` with `curvDenominator = 10` means `κ = −2/10 = −0.2`.

**Curvature scope for 3D Dense patches:** The per-patch curvature for Dense-50, Dense-100, and Dense-200 covers only the **central cell's 12 edges**, matching the Agda modules `Bulk/Dense{50,100,200}Curvature.agda`. For BFS/honeycomb patches, the curvature covers **all edges** in the patch, matching `Bulk/Honeycomb3DCurvature.agda` and `Bulk/Honeycomb145Curvature.agda`.

### 3.4 Half-Bound Data

```haskell
-- | Discrete Bekenstein-Hawking half-bound data for a patch.
data HalfBoundData = HalfBoundData
  { hbRegionCount    :: Int           -- total regions verified
  , hbViolations     :: Int           -- always 0
  , hbAchieverCount  :: Int           -- regions where 2*S = area
  , hbAchieverSizes  :: [(Int, Int)]  -- [(region_size, count)]
  , hbSlackRange     :: (Int, Int)    -- (min_slack, max_slack)
  , hbMeanSlack      :: Double
  }
```

### 3.5 Tower and Theorem Data

```haskell
-- | A single level of the resolution tower.
data TowerLevel = TowerLevel
  { tlPatchName   :: Text
  , tlRegions     :: Int
  , tlOrbits      :: Int
  , tlMaxCut      :: Int
  , tlMonotone    :: Maybe (Int, Text)   -- (witness_k, "refl")
  , tlHasBridge   :: Bool                -- BridgeWitness exists
  , tlHasAreaLaw  :: Bool
  , tlHasHalfBound :: Bool
  }

-- | A machine-checked theorem from the registry.
data Theorem = Theorem
  { thmNumber     :: Int
  , thmName       :: Text
  , thmModule     :: Text              -- e.g. "Bridge/GenericBridge.agda"
  , thmStatement  :: Text              -- informal statement
  , thmProofMethod :: Text
  , thmStatus     :: TheoremStatus
  }

data TheoremStatus = Verified | Dead | Numerical
  deriving (Show, Eq, Generic, ToJSON, FromJSON)
```

### 3.6 Curvature Summary

```haskell
-- | Top-level curvature summary entry from data/curvature.json.
data CurvatureSummary = CurvatureSummary
  { csPatchName       :: Text
  , csTiling          :: Text   -- Tiling name as raw text
  , csCurvTotal       :: Int    -- Σ κ as integer numerator
  , csCurvEuler       :: Int    -- χ as integer numerator
  , csGaussBonnet     :: Bool
  , csCurvDenominator :: Int    -- rational denominator (10 or 20)
  }
```

The curvature summary is **derived from per-patch data** by `18_export_json.py` — not hardcoded. This guarantees consistency between `GET /patches/:name` and `GET /curvature`: both read from the same underlying computation.

---

## 4. Data Export Pipeline

The Python script `sim/prototyping/18_export_json.py` reads all oracle outputs and re-computes patch data, then produces a `data/` directory:

```
data/
├── patches/
│   ├── tree.json
│   ├── star.json
│   ├── filled.json
│   ├── honeycomb-3d.json
│   ├── dense-50.json
│   ├── dense-100.json
│   ├── dense-200.json
│   ├── layer-54-d2.json
│   ├── ...
│   ├── layer-54-d7.json
│   └── desitter.json
├── tower.json               -- resolution tower levels + monotonicity
├── theorems.json            -- theorem registry (7 core + additional)
├── curvature.json           -- per-patch curvature summaries
└── meta.json                -- version, build date, Agda version
```

Each `patches/*.json` file follows the `Patch` schema above. The export script is deterministic and idempotent.

### 4.1 JSON Schema (patches)

```json
{
  "patchName": "dense-100",
  "patchTiling": "Tiling435",
  "patchDimension": 3,
  "patchCells": 100,
  "patchRegions": 717,
  "patchOrbits": 8,
  "patchMaxCut": 8,
  "patchBonds": 150,
  "patchBoundary": 300,
  "patchDensity": 3.00,
  "patchStrategy": "Dense",
  "patchHalfBoundVerified": true,
  "patchRegionData": [
    {
      "regionId": 0,
      "regionCells": [14],
      "regionSize": 1,
      "regionMinCut": 1,
      "regionArea": 6,
      "regionOrbit": "mc1",
      "regionHalfSlack": 4,
      "regionRatio": 0.1667
    }
  ],
  "patchCurvature": {
    "curvClasses": [
      {
        "ccName": "ev5",
        "ccCount": 12,
        "ccValence": 5,
        "ccKappa": -5,
        "ccLocation": "interior"
      }
    ],
    "curvTotal": -60,
    "curvEuler": -60,
    "curvGaussBonnet": true,
    "curvDenominator": 20
  },
  "patchHalfBound": {
    "hbRegionCount": 717,
    "hbViolations": 0,
    "hbAchieverCount": 40,
    "hbAchieverSizes": [[1, 40]],
    "hbSlackRange": [0, 14],
    "hbMeanSlack": 6.0
  }
}
```

### 4.2 Honeycomb Region Count Note

The `honeycomb-3d` patch is generated with `max_rc=4` (regions of up to 4 cells), producing **145 regions**. The original Agda formalization (`Common/Honeycomb3DSpec.agda`) has exactly **26 region constructors** (single-cell boundary regions only). The additional 119 multi-cell regions are verified by a separate Agda module (`Common/Honeycomb145Spec.agda` and `Boundary/Honeycomb145Cut.agda`). The `patchHalfBoundVerified` field is `false` for this patch because no `Boundary/Honeycomb3DHalfBound.agda` module exists.

---

## 5. API Endpoints

All endpoints return JSON. The API is defined as a Servant type:

```haskell
type API =
       "patches"                        :> Get '[JSON] [PatchSummary]
  :<|> "patches" :> Capture "name" Text :> Get '[JSON] Patch
  :<|> "tower"                          :> Get '[JSON] [TowerLevel]
  :<|> "theorems"                       :> Get '[JSON] [Theorem]
  :<|> "curvature"                      :> Get '[JSON] [CurvatureSummary]
  :<|> "meta"                           :> Get '[JSON] Meta
  :<|> "health"                         :> Get '[JSON] Health
```

### 5.1 Endpoint Details

| Method | Path | Response | Description |
|--------|------|----------|-------------|
| GET | `/patches` | `[PatchSummary]` | List all available patches (name, tiling, cells, regions, maxCut) |
| GET | `/patches/:name` | `Patch` | Full patch data including all regions, curvature, half-bound |
| GET | `/tower` | `[TowerLevel]` | Resolution tower levels with monotonicity witnesses |
| GET | `/theorems` | `[Theorem]` | All 10+ theorems from the registry with status |
| GET | `/curvature` | `[CurvatureSummary]` | Gauss-Bonnet summaries across all patches |
| GET | `/meta` | `Meta` | Version info, build date, Agda version, data hash |
| GET | `/health` | `Health` | Server health check (data loaded, region counts) |

### 5.2 PatchSummary (lightweight listing)

```haskell
data PatchSummary = PatchSummary
  { psName      :: Text
  , psTiling    :: Tiling
  , psDimension :: Int
  , psCells     :: Int
  , psRegions   :: Int
  , psOrbits    :: Int
  , psMaxCut    :: Int
  , psStrategy  :: GrowthStrategy
  }
```

### 5.3 CORS and Caching

- **CORS:** Allow `*` in development; restrict to frontend origin in production.
- **Cache-Control:** `max-age=86400, immutable` on all endpoints **except `/health`** — the data is static (changes only when the Agda code is re-verified and the export script is re-run). The `/health` endpoint is exempt because monitoring tools (uptime checkers, load balancer probes, Kubernetes liveness probes) expect fresh responses and must not see cached staleness.
- **ETag:** SHA-256 hash of `meta.json` serves as a version tag.

---

## 6. Data Invariants (Property Tests)

The backend validates invariants on startup and exposes them via property-based tests:

```haskell
-- | Every region's min-cut is bounded by half the area.
prop_halfBound :: Patch -> Property
prop_halfBound p = forAll (elements $ patchRegionData p) $ \r ->
  2 * regionMinCut r <= regionArea r

-- | Orbit classification is consistent with min-cut value.
-- Uses fromListWith (\_ existing -> existing) to keep the FIRST-SEEN
-- value for each orbit, making the representative deterministic and
-- error messages point at the minority (corrupt) values.
prop_orbitConsistency :: Patch -> Property
prop_orbitConsistency p = forAll (elements $ patchRegionData p) $ \r ->
  let orbitMap = Map.fromListWith (\_ existing -> existing)
        [ (regionOrbit r', regionMinCut r') | r' <- patchRegionData p ]
      orbitCut = Map.findWithDefault (-1) (regionOrbit r) orbitMap
  in regionMinCut r == orbitCut

-- | Tower monotonicity: maxCut is non-decreasing.
-- Levels with tlMonotone == Nothing mark breaks between sub-towers
-- and are not checked against their predecessor.
prop_towerMonotone :: [TowerLevel] -> Property
prop_towerMonotone levels = conjoin
  [ case tlMonotone hi of
      Nothing     -> property True
      Just (k, _) -> tlMaxCut lo + k === tlMaxCut hi
  | (lo, hi) <- zip levels (tail levels)
  ]

-- | Gauss-Bonnet: curvature sum equals Euler characteristic.
--
-- CAVEAT: For 3D {4,3,5} patches, 18_export_json.py sets
-- curvEuler = curvTotal (the same computed value) because no
-- independent 3D Euler characteristic has been formalised in Agda.
-- This check is therefore TAUTOLOGICAL for 3D data — it merely
-- guards against JSON field transposition or corruption.  It is
-- independently meaningful only for 2D patches (filled, desitter)
-- where the two values are derived from separate computations.
prop_gaussBonnet :: CurvatureData -> Property
prop_gaussBonnet c = curvTotal c === curvEuler c

-- | Area decomposition: area = 6k - 2*internal for cubes.
prop_areaDecomp :: Patch -> Property
prop_areaDecomp p
  | patchTiling p == Tiling435 = forAll (elements $ patchRegionData p) $ \r ->
      regionArea r == 6 * regionSize r - 2 * internalFaces r p
  | otherwise = property True  -- skip for non-cubic tilings
```

---

## 7. Project Structure

```
backend/
├── backend.cabal
├── cabal.project
├── cabal.project.freeze         -- pinned dependency versions
├── app/
│   └── Main.hs                  -- entry point, CLI parsing, server start
├── src/
│   ├── Api.hs                   -- Servant API type definition
│   ├── Server.hs                -- handler implementations + CORS middleware
│   ├── Types.hs                 -- domain model (§3) + Meta, Health, CurvatureSummary
│   ├── DataLoader.hs            -- JSON parsing from data/ directory
│   └── Invariants.hs            -- startup validation checks
├── test/
│   ├── Spec.hs                  -- test entry point (hspec-discover)
│   ├── InvariantSpec.hs         -- property-based tests (§6)
│   └── ApiSpec.hs               -- Servant client tests
├── data/                        -- symlink to repo-root data/
└── README.md
```

The executable entry point (`Main.hs`) lives in `app/`, separate from the library sources in `src/`. This is the idiomatic Cabal convention: it avoids ambiguity between the library and executable compilation units and prevents warnings with some Cabal versions.

### 7.1 Key Dependencies

```cabal
-- Library stanza
build-depends:
    base             >= 4.18 && < 5
  , aeson            >= 2.1
  , servant-server   >= 0.20
  , warp             >= 3.3
  , text             >= 2.0
  , containers       >= 0.6
  , filepath         >= 1.4
  , directory        >= 1.3
  , bytestring       >= 0.11
  , http-types       >= 0.12
  , wai              >= 3.2
  , wai-cors         >= 0.2

-- Test stanza (additional)
build-depends:
  , hspec            >= 2.11
  , QuickCheck       >= 2.14
  , servant-client   >= 0.20
  , http-client      >= 0.7
```

---

## 8. Startup Sequence

```haskell
main :: IO ()
main = do
  putStrLn "Univalence Gravity — Haskell Backend v0.1.0"

  -- 1. Parse CLI arguments (--data-dir, --port, --help)
  cfg <- parseArgs =<< getArgs

  -- 2. Load all JSON data
  patches   <- loadPatches (cfgDataDir cfg)
  tower     <- loadTower (cfgDataDir cfg)
  theorems  <- loadTheorems (cfgDataDir cfg)
  curvature <- loadCurvatureSummaries (cfgDataDir cfg)
  meta      <- loadMeta (cfgDataDir cfg)

  -- 3. Validate invariants
  let violations = validateAll patches tower
  unless (null violations) $ do
    mapM_ (putStrLn . ("  ✗ " ++)) violations
    exitFailure
  putStrLn $ "  ✓ " ++ show (length patches) ++ " patches loaded, "
          ++ show (sum $ map (length . patchRegionData) patches)
          ++ " regions, 0 invariant violations."

  -- 4. Start Servant server
  let port = cfgPort cfg
  putStrLn $ "  Listening on port " ++ show port
  run port (app patches tower theorems curvature meta)
```

---

## 9. Relationship to Agda Types

The Haskell types are **inspired by** the Agda types but are NOT compiled from them. The correspondence:

| Agda Type | Haskell Type | Notes |
|-----------|-------------|-------|
| `PatchData` | `Patch` | Data fields only; no `obs-path` |
| `OrbitReducedPatch` | orbit fields within `Patch` | `patchOrbits`, `regionOrbit` |
| `BridgeWitness` | `tlHasBridge :: Bool` | Existence only; no proof content |
| `HalfBoundWitness` | `HalfBoundData` + `patchHalfBoundVerified` | Numeric values + Agda-verified flag |
| `TowerLevel` | `TowerLevel` | `maxCut`, monotonicity witness value |
| `GaussBonnetWitness` | `CurvatureData` | V, E, F, curvature values |
| `ℚ≥0 = ℕ` | `Int` | Direct correspondence |
| `ℚ₁₀ = ℤ` | `Int` + `curvDenominator` | Integer numerator + explicit denominator |

The Haskell types carry **no proof content** — they carry only the verified *data*. The proofs live in Agda and are checked by the type-checker; the data is exported by the Python oracle and served by Haskell.

---

## 10. Testing Strategy

### 10.1 Unit Tests (Hspec)

- JSON round-trip: decode . encode ≡ id for all types
- Every endpoint returns 200 with valid JSON
- `/patches/nonexistent` returns 404

### 10.2 Property Tests (QuickCheck)

- All invariants from §6 hold on the loaded data
- Region count matches patch metadata
- Orbit classification is surjective (every orbit has ≥1 region)
- Half-bound slack is non-negative for every region
- `regionSize` matches `length regionCells` for every region
- `regionMinCut` does not exceed `regionArea` for every region

### 10.3 Integration Tests

- Start server on an ephemeral port with `testWithApplication`
- Hit every endpoint with auto-derived `servant-client` functions
- Verify response shapes match the Servant API type (Content-Type `application/json` is verified implicitly by Servant's content negotiation — the client functions reject non-JSON responses automatically)
- Verify CORS headers are present

### 10.4 Regression Tests

Several `ApiSpec` tests assert specific numeric values (e.g. `patchCells p == 100`, `patchMaxCut p == 8`, `patchRegions p == 717`). These are **regression tests tracking the current data snapshot** produced by `18_export_json.py`. If the oracle is re-run with different parameters or if patches are regenerated, these values may change legitimately. When updating: verify the new values against the oracle output (the `*_OUTPUT.txt` file for the relevant script), then update the expected constants.

### 10.5 CI

```yaml
# .github/workflows/backend.yml
- name: Build & Test Backend
  run: |
    cd backend
    cabal update
    cabal build all
    cabal test all
```

---

## 11. Deployment

### 11.1 Development

```bash
cd backend
cabal run univalence-gravity-backend -- --data-dir ../data --port 8080
```

### 11.2 Production

The `cabal.project` file sets `optimization: 0` for fast development iteration. For production deployment, override with `-O1` or `-O2`:

```bash
# Production build with optimisations:
cabal install -O1 --install-method=copy --overwrite-policy=always

# Or with Nix:
nix build .#backend
```

Alternatively, create a `cabal.project.local` containing `optimization: 1`, which takes precedence over `cabal.project` without modifying it.

The binary reads from `data/` at startup. No database, no external services. Serve behind nginx or Caddy for TLS.

### 11.3 Docker (optional)

```dockerfile
FROM haskell:9.6 AS builder
WORKDIR /app
COPY . .
RUN cabal update && cabal build -O1
RUN cabal install -O1 --install-method=copy --installdir=/app/bin

FROM debian:bookworm-slim
COPY --from=builder /app/bin/univalence-gravity-backend /usr/local/bin/
COPY data/ /data/
EXPOSE 8080
CMD ["univalence-gravity-backend", "--data-dir", "/data", "--port", "8080"]
```

---

## 12. Security Considerations

- **Read-only:** The server serves static, pre-computed data. No writes, no user input processing beyond URL path parameters.
- **Input validation:** Patch names are validated against the loaded set; invalid names return 404.
- **Rate limiting:** Not implemented at the application level; delegate to nginx/Caddy.
- **No authentication:** The data is public (MIT-licensed repository). Add API keys via middleware if needed.

---

## 13. Extension Points

### 13.1 WebSocket (future)

For live type-checking status (if Agda is running in the background), a WebSocket endpoint could be added:

```haskell
type WsAPI = "ws" :> "typecheck" :> WebSocket
```

This is NOT in scope for v0.1.

### 13.2 GraphQL (future)

If the frontend needs flexible queries (e.g., "give me all regions of Dense-100 with min-cut ≥ 5 and area ≤ 14"), a GraphQL layer could be added. For v0.1, filtering is done client-side.

### 13.3 Additional Patches

When new patches are generated (e.g., Dense-500), running `18_export_json.py` and restarting the server is sufficient. No code changes needed — the server discovers all `patches/*.json` files at startup.

---

## 14. Milestones

| Milestone | Deliverable | Dependency |
|-----------|-------------|------------|
| M1 | `18_export_json.py` produces `data/*.json` from oracle outputs | Oracle scripts 01–17 |
| M2 | Haskell domain types + Aeson instances + startup loader | M1 |
| M3 | Servant API + handlers serving loaded data | M2 |
| M4 | Property-based tests passing on all loaded data | M3 |
| M5 | CORS + Cache-Control (with `/health` exemption) | M3 |
| M6 | Docker image + CI pipeline | M5 |

---

## 15. Cross-References

| Topic | Document |
|-------|----------|
| Frontend specification | [`engineering/frontend-spec-webgl.md`](frontend-spec-webgl.md) |
| Oracle pipeline (data source) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Theorem registry (served as JSON) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| Scaling report (region counts, timings) | [`engineering/scaling-report.md`](scaling-report.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Setup (GHC/Cabal toolchain) | [`getting-started/setup.md`](../getting-started/setup.md) |
| Holographic dictionary (physics context) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Generic bridge pattern (PatchData interface) | [`engineering/generic-bridge-pattern.md`](generic-bridge-pattern.md) |
| Orbit reduction (orbit classification) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| Bekenstein-Hawking half-bound | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |