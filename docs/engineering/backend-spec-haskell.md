# Backend Specification — Haskell REST API

**A hand-written Haskell server serving pre-computed, Agda-verified holographic patch data via Servant.**

**Audience:** Backend developers, proof engineers integrating with the visualization frontend, and anyone deploying or extending the REST API.

**Primary modules:** `app/Main.hs`, `src/Api.hs`, `src/Server.hs`, `src/Types.hs`, `src/DataLoader.hs`, `src/Invariants.hs`

**Prerequisites:** Familiarity with the oracle pipeline ([`oracle-pipeline.md`](oracle-pipeline.md)), the data export script (`sim/prototyping/18_export_json.py`), and the overall repository architecture ([`getting-started/architecture.md`](../getting-started/architecture.md)).

---

## 1. Overview

The Univalence Gravity backend is a stateless, read-only Haskell HTTP server that loads pre-computed JSON data at startup, validates it against the same invariants that the Agda type-checker enforces at the proof level, and serves it via a type-safe REST API built with [Servant](https://docs.servant.dev/) and [Warp](https://hackage.haskell.org/package/warp).

**What this backend is NOT:**

- **Not compiled from Agda.** Cubical Agda's `--cubical` flag has no meaningful GHC runtime extraction. The backend is hand-written Haskell that reads the *verified data*, not the proofs.
- **Not a database server.** All data is held in memory after startup. No mutations, no persistence, no writes.
- **Not a computation server.** All min-cut values, orbit classifications, curvature, half-bound statistics, patch-graph coordinates, rotation quaternions, and conformal scales are pre-computed by the Python oracle pipeline and verified by Agda / runtime invariants. The backend performs zero mathematical computation — only JSON decoding, invariant validation, and HTTP serving.

**Key design properties:**

| Property | Value |
|----------|-------|
| Data source | `data/*.json` (produced by `18_export_json.py`) |
| Startup validation | 9 invariant classes, exhaustive over all regions and graph nodes |
| API framework | Servant 0.20 (type-level routing) |
| HTTP server | Warp 3.4 |
| Concurrency | Threaded RTS (`-threaded -rtsopts -with-rtsopts=-N`) |
| State | Immutable, in-memory (closures over loaded data) |
| Total patches | 16 (14 standard + honeycomb-145 + dense-1000) |
| Total regions served | ~17,400 |
| Total graph nodes served | ~6,500 (union of all `pgNodes` across patches) |

---

## 2. Architecture

```
sim/prototyping/18_export_json.py     (Python oracle — data producer)
      │
      ▼
data/                                 (pre-computed JSON — source of truth)
  ├── patches/  (16 files)
  │   ├── tree.json, star.json, filled.json, desitter.json
  │   ├── honeycomb-3d.json, honeycomb-145.json
  │   ├── dense-50.json, dense-100.json, dense-200.json, dense-1000.json
  │   └── layer-54-d{2..7}.json
  ├── tower.json
  ├── theorems.json
  ├── curvature.json
  └── meta.json
      │
      ▼
backend/                              (this server)
  ├── app/Main.hs          CLI → load → validate → serve
  ├── src/Types.hs         Domain model (Patch, Region, GraphNode, PatchGraph, ...)
  ├── src/DataLoader.hs    JSON file → Haskell types
  ├── src/Invariants.hs    Startup validation (9 invariant classes)
  ├── src/Api.hs           Servant API type (type-level routing)
  ├── src/Server.hs        Handler implementations + middleware
  └── test/                InvariantSpec + ApiSpec
      │
      ▼
frontend/                             (React + Three.js — data consumer)
  └── src/api/client.ts    fetch() → typed responses
```

### Module Dependency DAG

```
Types.hs          ← no internal imports (dependency root)
    │
    ├── DataLoader.hs    (reads JSON into Types)
    ├── Invariants.hs    (validates Types)
    ├── Api.hs           (references Types in the API definition)
    │     │
    │     └── Server.hs  (implements Api handlers, uses Types)
    │
    └── Main.hs          (imports all of the above)
```

---

## 3. Data Model

All domain types are defined in `src/Types.hs`. Every type derives `Generic`, `ToJSON`, and `FromJSON` for automatic Aeson serialization. The types mirror — but are not compiled from — the Agda types in `src/`.

### 3.1 Enumerations

```haskell
data Tiling
  = Tiling54    -- {5,4} hyperbolic pentagonal (2D)
  | Tiling435   -- {4,3,5} hyperbolic cubic (3D)
  | Tiling53    -- {5,3} spherical dodecahedral (2D)
  | Tiling44    -- {4,4} Euclidean square grid (2D)
  | Tree        -- 1D weighted binary tree

data GrowthStrategy = BFS | Dense | Geodesic | Hemisphere

data TheoremStatus = Verified | Dead | Numerical
```

JSON encoding uses Aeson's default `allNullaryToStringTag` behaviour: each constructor is a plain JSON string matching its name (e.g. `"Tiling54"`, `"Dense"`, `"Verified"`).

### 3.2 Region

A single cell-aligned boundary region within a patch:

```haskell
data Region = Region
  { regionId        :: Int            -- unique index within the patch
  , regionCells     :: [Int]          -- sorted cell IDs
  , regionSize      :: Int            -- = length regionCells
  , regionMinCut    :: Int            -- S(A) — boundary min-cut entropy
  , regionArea      :: Int            -- boundary surface area (face count)
  , regionOrbit     :: Text           -- orbit label, e.g. "mc3"
  , regionHalfSlack :: Maybe Int      -- area − 2·S; Nothing if not computed
  , regionRatio     :: Double         -- S / area
  , regionCurvature :: Maybe Double   -- average κ of adjacent vertices/edges
  }
```

**`regionCurvature`:** Average curvature of the cells in this region. For 3D ({4,3,5}) patches, this is the mean of the 12 edge-curvature values (κ₂₀ / 20) for each cell. For 2D patches (filled, desitter), it is a hardcoded per-tile average from known vertex-class curvatures. `Nothing` when curvature data is unavailable (tree, star, layer-54 patches).

### 3.3 Graph Representation (PatchGraph)

The `patchGraph` field of every `Patch` carries the **full bulk graph**: all cells (including interior cells invisible to any boundary region) and all physical bonds (shared faces in 3D, shared edges in 2D). This is the data the frontend needs to render the 3D holographic representation correctly — inferring nodes and edges from region data alone would miss interior cells and misinterpret boundary adjacency as physical bonds.

#### 3.3.1 GraphNode

```haskell
data GraphNode = GraphNode
  { gnId    :: Int       -- cell ID (matches entries in pgEdges)
  , gnX     :: Double    -- Poincaré x-coordinate
  , gnY     :: Double    -- Poincaré y-coordinate
  , gnZ     :: Double    -- Poincaré z-coordinate (0.0 for 2D patches)
  , gnQx    :: Double    -- rotation quaternion — x component
  , gnQy    :: Double    -- rotation quaternion — y component
  , gnQz    :: Double    -- rotation quaternion — z component
  , gnQw    :: Double    -- rotation quaternion — w (real) component
  , gnScale :: Double    -- conformal scale factor s(u) = (1 − |u|²) / 2
  }
```

**Field semantics:**

| Field | Meaning |
|-------|---------|
| `gnId` | Cell or tile identifier; also appears as `source`/`target` in `pgEdges` |
| `gnX`, `gnY`, `gnZ` | Coordinates in the Poincaré ball (3D) or disk embedded as `z = 0` (2D). Always in the open unit ball: `x² + y² + z² < 1`. |
| `gnQx..gnQw` | Unit quaternion for this cell's rotation relative to the fundamental cell. For 2D patches this is a z-axis rotation (only `qz` and `qw` non-zero); for 3D patches it is the Shepperd–Shuster conversion of the rotation extracted from the (boosted) Jacobian of the projection. Hand-written 2D layouts (tree, star, filled, desitter) use the identity quaternion `(0, 0, 0, 1)`. |
| `gnScale` | Conformal scale factor `s(u) = (1 − |u|²) / 2` where `u = (gnX, gnY, gnZ)`. Cells at the centre have `s ≈ 0.5`; cells near the boundary have `s → 0`. Clamped to `1e-6` to avoid zero-scale degeneracy at the disk boundary. |

**JSON keys:** `"id"`, `"x"`, `"y"`, `"z"`, `"qx"`, `"qy"`, `"qz"`, `"qw"`, `"scale"`. The Haskell `"gn"` prefix is stripped by a custom `Options` using `dropFieldPrefix 2` (see §3.9).

**Centring invariant (Bug 1 fix):** For every patch whose coordinates come from `poincare_project` in `18_export_json.py` (all Coxeter-generated patches: honeycomb-3d, honeycomb-145, dense-50/100/200/1000, layer-54-d{2..7}), the cell with `gnId = 0` — the Coxeter group identity `g = I` — projects to the origin `(0, 0, 0)` with `gnScale ≈ 0.5`. This is enforced by the Lorentz boost applied at the start of the projector and verified at startup (§6).

**Scale invariant:** The exporter writes the conformal factor `(1 − |u|²) / 2` clamped at `1e-6`. Values therefore lie in `(0, 0.5]` for well-formed data. The strict identity `gnScale ≡ (1 − |u|²) / 2` is **not** enforced at runtime — layer-54-d7 places cells exponentially close to `|u| = 1` where the clamp legitimately kicks in. The range check (§6) catches the real failure modes (NaN, negative, out-of-range) without false positives.

#### 3.3.2 Edge

```haskell
data Edge = Edge
  { edgeSource :: !Int
  , edgeTarget :: !Int
  }
```

An undirected bond between two cells, represented on the wire as `{"source": <id>, "target": <id>}`. The exporter emits edges as objects (not 2-element arrays) so that Haskell and TypeScript share a single record schema. Internally the exporter maintains the canonical `source ≤ target` ordering.

**JSON keys:** `"source"`, `"target"`. The Haskell `"edge"` prefix is stripped by `dropFieldPrefix 4` (see §3.9).

The helper function `edgeEndpoints :: Edge -> [Int]` exposes both endpoints as a two-element list for callers that previously treated each edge as a `[Int]` pair (graph validation, test-spec iteration).

#### 3.3.3 PatchGraph

```haskell
data PatchGraph = PatchGraph
  { pgNodes :: [GraphNode]  -- all cells with spatial coords, quat, scale
  , pgEdges :: [Edge]       -- all physical bonds
  }
```

**`pgNodes`:** Sorted list of `GraphNode` objects, one per cell. The list length equals `patchCells`. Includes both boundary cells (appearing in at least one region's `regionCells`) and interior cells (all faces shared, appearing in no region).

**`pgEdges`:** Sorted list of physical bonds. For 3D patches each edge corresponds to a shared cube face; for 2D patches, a shared pentagon edge; for the tree, a weighted tree edge. The list length equals `patchBonds`.

**Structural invariants (enforced at startup, §6):**

1. `length pgNodes == patchCells`
2. `length pgEdges == patchBonds`
3. Every endpoint of every edge in `pgEdges` appears as a `gnId` in `pgNodes`
4. `length pgNodes ≥ |⋃ regionCells|` (every boundary cell from the region data is present as a graph node)
5. No self-loops (`edgeSource ≠ edgeTarget`)
6. No duplicate `gnId` values

### 3.4 Curvature Data

```haskell
data CurvatureClass = CurvatureClass
  { ccName :: Text, ccCount :: Int, ccValence :: Int
  , ccKappa :: Int, ccLocation :: Text }

data CurvatureData = CurvatureData
  { curvClasses     :: [CurvatureClass]
  , curvTotal       :: Int     -- Σκ as integer numerator
  , curvEuler       :: Int     -- χ as integer numerator
  , curvGaussBonnet :: Bool    -- curvTotal ≡ curvEuler
  , curvDenominator :: Int     -- 10 (2D) or 20 (3D)
  }
```

**Denomination convention:** All curvature values are integer numerators. The `curvDenominator` field specifies the rational denominator: 10 for 2D patches (matching Agda's ℚ₁₀ = ℤ encoding), 20 for 3D patches (twentieths). Example: `curvTotal = -60` with `curvDenominator = 20` means κ_total = −60/20 = −3.

**3D Gauss–Bonnet caveat:** For 3D patches, `18_export_json.py` sets `curvEuler = curvTotal` (the same computed value) because no independent 3D Euler characteristic has been formalised in Agda. The `curvGaussBonnet` field is therefore tautologically `True` for 3D data. It is independently meaningful only for 2D patches (filled, desitter) where the two values derive from separate computations.

### 3.5 Half-Bound Data

```haskell
data HalfBoundData = HalfBoundData
  { hbRegionCount   :: Int           -- total regions verified
  , hbViolations    :: Int           -- always 0 for valid data
  , hbAchieverCount :: Int           -- regions where 2·S = area
  , hbAchieverSizes :: [(Int, Int)]  -- [(region_size, count)]
  , hbSlackRange    :: (Int, Int)    -- (min_slack, max_slack)
  , hbMeanSlack     :: Double
  }
```

### 3.6 Patch

The central domain type, loaded from `data/patches/*.json`:

```haskell
data Patch = Patch
  { patchName              :: Text
  , patchTiling            :: Tiling
  , patchDimension         :: Int             -- 1, 2, or 3
  , patchCells             :: Int
  , patchRegions           :: Int
  , patchOrbits            :: Int             -- 0 = flat enumeration
  , patchMaxCut            :: Int
  , patchBonds             :: Int
  , patchBoundary          :: Int
  , patchDensity           :: Double          -- 2 · bonds / cells
  , patchStrategy          :: GrowthStrategy
  , patchRegionData        :: [Region]
  , patchCurvature         :: Maybe CurvatureData
  , patchHalfBound         :: Maybe HalfBoundData
  , patchHalfBoundVerified :: Bool            -- Agda-verified half-bound exists
  , patchGraph             :: PatchGraph      -- full bulk graph (§3.3)
  }
```

**`patchOrbits` semantics:** The value `0` indicates flat enumeration (no orbit reduction). A positive value is the number of distinct orbit representatives (e.g. 8 for Dense-100, 9 for Dense-200, 2 for the {5,4} layer patches).

**`patchHalfBoundVerified`:** `True` when a corresponding `Boundary/*HalfBound.agda` module machine-checks `2·S(A) ≤ area(A)` for every region via `abstract (k, refl)` witnesses. Currently `True` only for **dense-100**, **dense-200**, and **dense-1000**. For all other patches, the half-bound data (if present) is a Python-side numerical check only.

**`patchGraph`:** Non-optional. Every patch — including `tree`, `star`, `filled`, and `desitter` — ships with a fully populated `PatchGraph`. Hand-written 2D layouts use the identity quaternion and a conformal scale derived from the stored `(x, y, z)`; Coxeter-generated patches use the full Lorentz-boosted Poincaré projection (§4.3).

### 3.7 PatchSummary

Lightweight projection for the `GET /patches` listing:

```haskell
data PatchSummary = PatchSummary
  { psName :: Text, psTiling :: Tiling, psDimension :: Int
  , psCells :: Int, psRegions :: Int, psOrbits :: Int
  , psMaxCut :: Int, psStrategy :: GrowthStrategy }
```

Constructed server-side from `Patch` by dropping `patchRegionData`, `patchCurvature`, `patchHalfBound`, `patchGraph`, and supporting fields.

### 3.8 Other Types

| Type | Source | Description |
|------|--------|-------------|
| `TowerLevel` | `data/tower.json` | Resolution tower level with `tlMonotone :: Maybe (Int, Text)` witness |
| `Theorem` | `data/theorems.json` | Canonical theorem registry entry |
| `CurvatureSummary` | `data/curvature.json` | Top-level per-patch curvature summary (JSON keys strip the `cs` prefix) |
| `Meta` | `data/meta.json` | Version, build date, Agda version, data hash (JSON keys strip the `meta` prefix) |
| `Health` | runtime | Constructed per-request: `{status, patchCount, regionCount}` |

### 3.9 JSON Field Naming

Most types use Aeson's default generic derivation where the Haskell field name IS the JSON key. Four types carry a prefix that is stripped for JSON via custom `Options`:

| Type | Haskell prefix | Strip length | Example |
|------|---------------|-------------|---------|
| `GraphNode` | `gn` | 2 | `gnId` → `"id"`, `gnScale` → `"scale"`, `gnQw` → `"qw"` |
| `Edge` | `edge` | 4 | `edgeSource` → `"source"`, `edgeTarget` → `"target"` |
| `CurvatureSummary` | `cs` | 2 | `csPatchName` → `"patchName"` |
| `Meta` | `meta` | 4 | `metaVersion` → `"version"` |

---

## 4. Data Export Pipeline

The `data/` directory is produced by `sim/prototyping/18_export_json.py`, which re-computes patch data using the same Coxeter infrastructure as scripts 01–17.

### 4.1 Output Structure

```
data/
├── patches/
│   ├── tree.json         (8 regions, 1D)
│   ├── star.json         (10 regions, 2D {5,4})
│   ├── filled.json       (90 regions, 2D {5,4})
│   ├── desitter.json     (10 regions, 2D {5,3})
│   ├── honeycomb-3d.json (26 regions, 3D {4,3,5} BFS)
│   ├── honeycomb-145.json(1008 regions, 3D {4,3,5} Dense)
│   ├── dense-50.json     (139 regions, 3D {4,3,5} Dense)
│   ├── dense-100.json    (717 regions, 3D {4,3,5} Dense)
│   ├── dense-200.json    (1246 regions, 3D {4,3,5} Dense)
│   ├── dense-1000.json   (10317 regions, 3D {4,3,5} Dense)
│   ├── layer-54-d2.json  (15 regions, 2D {5,4} BFS)
│   ├── ...
│   └── layer-54-d7.json  (1885 regions, 2D {5,4} BFS)
├── tower.json            (11 levels)
├── theorems.json         (10 theorems)
├── curvature.json        (per-patch Gauss–Bonnet summaries)
└── meta.json             (version, build date, data hash)
```

### 4.2 Agda Alignment

Each patch's region count and `max_region_cells` parameter must match the corresponding Agda Spec module. The Agda modules are the source of truth.

| Patch | max_rc | Regions | Agda Module | Generator |
|-------|--------|---------|-------------|-----------|
| tree | — | 8 | `Common/TreeSpec.agda` | hand-written |
| star | — | 10 | `Common/StarSpec.agda` | hand-written |
| filled | — | 90 | `Common/FilledSpec.agda` | `03_generate` |
| desitter | — | 10 | shares StarSpec | hand-written |
| honeycomb-3d | 1 | 26 | `Common/Honeycomb3DSpec.agda` | `06_generate` |
| honeycomb-145 | 5 | 1,008 | `Common/Honeycomb145Spec.agda` | `06b_generate` |
| dense-50 | 5 | 139 | `Common/Dense50Spec.agda` | `08_generate` |
| dense-100 | 5 | 717 | `Common/Dense100Spec.agda` | `09_generate` |
| dense-200 | 5 | 1,246 | `Common/Dense200Spec.agda` | `12_generate` |
| dense-1000 | 6 | 10,317 | `Common/Dense1000Spec.agda` | `12b_generate` |
| layer-54-d{2..7} | 4 | 15–1,885 | `Common/Layer54d{2..7}Spec.agda` | `13_generate` |

### 4.3 Poincaré Projection, Centring Boost, and Rotation Extraction

Every Coxeter-generated patch runs through the `poincare_project` function in `18_export_json.py`, which maps cell centres from the hyperboloid `⟨p, p⟩_G = −R²` to the Poincaré ball/disk via three composed steps (matching the "Centre Patches in Poincaré Projection" engineering roadmap):

**Step 1 — Centring (Lorentz boost).** Diagonalise the Gram matrix `G` via `eigh`, change into the canonical Minkowski basis via `D · Vᵀ` (where `D = diag(√|λᵢ|)`), then apply a Lorentz boost `B` that maps the fundamental cell centre to the time-axis apex `(0,…,0, +R)`. After this boost, the cell with `g = I` projects to the origin of the Poincaré ball — a refl-level invariant verified at startup (§6).

**Step 2 — Per-cell conformal scale.** For each cell, after projection to `u ∈ ball`, compute `s(u) = (1 − |u|²) / 2`. This is the correct scaling for an Escher-disk rendering: cells shrink as they approach the boundary. The exporter clamps `s` at `1e-6` to avoid zero-scale degeneracy at `|u| = 1` (required for layer-54-d7, where cells are exponentially close to the boundary).

**Step 3 — Per-cell rotation quaternion.** For each cell, compute the per-cell boost `B_c` that sends its (boosted) canonical position back to the apex; apply it to `M_cell = T · g · T⁻¹` to obtain a rotation fixing the apex. The spatial `(n−1) × (n−1)` block is orthogonalised via SVD (polar decomposition) and converted to a unit quaternion. For 2D patches this is a z-axis rotation (only `qz, qw` non-zero); for 3D patches it uses the full Shepperd–Shuster algorithm, numerically stable across all branches.

Every coordinate, quaternion component, and scale is rounded to **6 decimal digits** before JSON serialisation. The `1e-4` runtime tolerance used by `validateGraphGeometry` (§6) comfortably absorbs this round-off.

**Hand-written layouts (tree, star, filled, desitter):** The Python helper `_make_patch_graph` applies a uniform schema so every emitted node carries `{id, x, y, z, qx, qy, qz, qw, scale}` regardless of origin. For hand-written layouts the quaternion is the identity `(0, 0, 0, 1)` and the scale is synthesised from `(x, y, z)` via the same `s(u)` formula. The frontend never has to branch on presence of the fields.

### 4.4 Per-Cell Curvature Aggregation

The `regionCurvature` field is computed by `18_export_json.py` as a per-cell average:

- **3D ({4,3,5}):** Each cube has 12 edges. For each cell, the script enumerates those 12 edges, determines each edge's in-patch valence, computes κ₂₀ = 20 − 5·valence, averages the 12 values, and divides by 20 to produce a rational curvature float.

- **2D (filled, desitter):** Per-tile curvature averages are hardcoded from the known vertex-class curvatures. For example, the central tile `C` of the filled patch has 5 interior vertices at κ₁₀ = −2, giving avg = −2/10 = −0.2.

### 4.5 Half-Bound Verified Flag

The `patchHalfBoundVerified` field is set to `True` by `18_export_json.py` only for patches in the hardcoded set `AGDA_VERIFIED_HALF_BOUND = {"dense-100", "dense-200", "dense-1000"}`. These are the patches with corresponding `Boundary/*HalfBound.agda` modules containing `abstract (k, refl)` witnesses for every region.

### 4.6 Determinism and Reproducibility

The export script is deterministic and idempotent: given the same oracle infrastructure, it produces byte-identical output. This is ensured by sorted iteration over all sets and dictionaries, deterministic BFS with sorted frontiers, canonical cell identification via rounded floating-point keys, and the 6-digit rounding applied to every float.

**Runtime:** The full export (all 16 patches including Dense-1000 at max_rc=6) runs for ~50 minutes, dominated by Dense-1000 region enumeration (~33 minutes) and layer-54-d7 region enumeration (~13 minutes).

---

## 5. API Specification

### 5.1 Endpoint Summary

All endpoints return `application/json`. The data is static and pre-computed; no mutation endpoints exist.

| Method | Path | Response Type | Description |
|--------|------|---------------|-------------|
| `GET` | `/patches` | `[PatchSummary]` | List all 16 patch instances (lightweight) |
| `GET` | `/patches/:name` | `Patch` | Full patch data: regions, curvature, half-bound, bulk graph |
| `GET` | `/tower` | `[TowerLevel]` | Resolution tower with monotonicity witnesses |
| `GET` | `/theorems` | `[Theorem]` | All 10 machine-checked theorems |
| `GET` | `/curvature` | `[CurvatureSummary]` | Gauss–Bonnet summaries per patch |
| `GET` | `/meta` | `Meta` | Version, Agda version, build date, data hash |
| `GET` | `/health` | `Health` | Server health check (exempt from caching) |

### 5.2 API Type Definition

The API is defined as a single type alias in `src/Api.hs`:

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

The separation of `Api.hs` from `Server.hs` keeps the API type importable by both the server (handler implementations) and the test client (`test/ApiSpec.hs`) without pulling in handler dependencies.

### 5.3 Middleware

| Middleware | Behaviour | Reference |
|-----------|-----------|-----------|
| **CORS** | Allows all origins (`corsOrigins = Nothing`) during development. For production, restrict to the frontend domain. Only `GET`, `HEAD`, `OPTIONS` methods. | `Server.corsMiddleware` |
| **Cache-Control** | `max-age=86400, immutable` on all endpoints **except** `/health`. The served data changes only when Agda code is re-verified and `18_export_json.py` is re-run. | `Server.cacheMiddleware` |

The `/health` endpoint is exempt from caching so that monitoring tools, load balancer probes, and Kubernetes liveness checks always receive a fresh response.

### 5.4 Patch Name Lookup

`GET /patches/:name` uses a `Map.Map Text Patch` index built once at construction time, providing O(log n) lookup by name. Unknown names return HTTP 404.

Valid `:name` values:

```
tree, star, filled, desitter, honeycomb-3d, honeycomb-145,
dense-50, dense-100, dense-200, dense-1000,
layer-54-d2, layer-54-d3, layer-54-d4, layer-54-d5, layer-54-d6, layer-54-d7
```

### 5.5 PatchSummary Projection

The `GET /patches` endpoint projects each full `Patch` to a lightweight `PatchSummary` via the `summarise` function, retaining only the scalar metadata fields (name, tiling, dimension, cells, regions, orbits, maxCut, strategy) and dropping the (potentially large) region data, curvature details, half-bound statistics, and bulk graph.

### 5.6 Health Endpoint

Constructed on every request from the in-memory patch list:

```json
{
  "status": "ok",
  "patchCount": 16,
  "regionCount": 17419
}
```

The `regionCount` is the sum of `length (patchRegionData p)` across all patches. The server would not be running if data loading had failed, so `status` is always `"ok"`.

---

## 6. Invariant Validation

The `Invariants` module (`src/Invariants.hs`) runs every data-integrity check at startup and returns a list of human-readable violation messages. An empty list means all checks pass; any violation causes the server to abort before binding a port.

These checks mirror — at the Haskell value level — the properties that are machine-checked by Cubical Agda at the type level. They serve as a runtime sanity gate: if the JSON export pipeline ever introduces data corruption, the backend catches it at startup rather than serving broken data.

### 6.1 Invariant Classes

| Invariant | Description | Agda / Engineering Counterpart | Scope |
|-----------|-------------|--------------------------------|-------|
| **Half-bound** | `2·S(A) ≤ area(A)` for every region | `Bridge/HalfBound.agda` (Theorem 3) | All patches × all regions |
| **Half-slack consistency** | `regionHalfSlack == area − 2·S` when present | Derived from half-bound | All regions with half-slack |
| **Orbit consistency** | Same orbit label ⟹ same min-cut value | `OrbitReducedPatch.rep-agree` | All patches |
| **Area decomposition** | `area ≤ fpc·k` and `(fpc·k − area)` is even | Face-count formula | All non-Tree patches |
| **Region count** | `patchRegions == length patchRegionData` | Data type constructor count | All patches |
| **Gauss–Bonnet** | `curvTotal == curvEuler` when curvature present | `Bulk/GaussBonnet.agda` (Theorem 2) | Patches with curvature data |
| **Tower monotonicity** | `maxCut_lo + k == maxCut_hi` for witnessed steps | `LayerStep.monotone` | All consecutive tower pairs |
| **Half-bound metadata** | `hbViolations == 0` when half-bound data present | Oracle abort condition | Patches with half-bound data |
| **Graph structure** | Node/edge counts, endpoint validity, boundary coverage, no self-loops, unique IDs | §3.3.3 structural invariants | All patches × `patchGraph` |
| **Graph geometry** | Position in Poincaré ball, quaternion unit-norm, scale in `(0, 0.5 + tol]` | §3.3.1 field semantics | All patches × all graph nodes |

### 6.2 Area Decomposition Detail

The area decomposition formula is: `area(A) = faces_per_cell · |A| − 2 · |internal_faces_within_A|`. Since region JSON lacks per-region internal face counts, the validator checks two algebraic consequences:

1. `area ≤ faces_per_cell · regionSize` (equality when zero internal sharing).
2. `(faces_per_cell · regionSize − area)` is non-negative and even (since it equals `2 · internal_faces`).

Faces-per-cell values: `{4,3,5} → 6`, `{5,4} → 5`, `{5,3} → 5`, `{4,4} → 4`, `Tree → skip`.

### 6.3 Orbit Consistency Detail

Regions are grouped by orbit label using `Map.fromListWith (++)`. For each group, every member's min-cut is compared to the first member's. Any disagreement indicates a corrupt `classify` function output in the Python oracle.

### 6.4 Graph Structure Detail

`validateGraph` decomposes into six sub-checks run against each patch's `patchGraph`:

1. **Node count:** `length pgNodes == patchCells`. Guards against a `pgNodes` list built only from region data (which would omit interior cells).
2. **Edge count:** `length pgEdges == patchBonds`.
3. **Edge endpoints:** Every `edgeSource`/`edgeTarget` is present as a `gnId` in `pgNodes` (no dangling references).
4. **Edge arity:** Every edge carries exactly 2 endpoints. (With `Edge` as a two-field record this is a type-level guarantee; the function is retained for future format changes.)
5. **Boundary coverage:** Every cell referenced by any region (`⋃ regionCells`) appears as a `gnId` in `pgNodes`.
6. **Boundary node count:** `length pgNodes ≥ |⋃ regionCells|` — informational check whose failure points at the specific class of bugs where `pgNodes` was accidentally constructed from region data alone.

### 6.5 Graph Geometry Detail

`validateGraphGeometry` runs three per-node checks with tolerance `graphGeomTol = 1e-4`:

| Check | Condition | Failure mode caught |
|-------|-----------|--------------------|
| **Position** | `|u|² ≤ 1 + tol`, `isFinite` | NaN/∞ coordinates; positions outside the Poincaré ball (broken projection) |
| **Quaternion** | `|q|² ∈ [1 − tol, 1 + tol]`, `isFinite` | Non-unit quaternions; missed SVD orthogonalisation |
| **Scale** | `0 < gnScale ≤ 0.5 + tol`, `isFinite` | NaN/∞/negative/zero scale; scale exceeding the theoretical maximum |

The tolerance absorbs the 6-digit rounding applied by the Python exporter to every float. The strict identity `gnScale ≡ (1 − |u|²) / 2` is **not** enforced — the exporter's `1e-6` clamp near the disk boundary would produce false positives for layer-54-d7 where cells are exponentially close to `|u| = 1`. Range-checking is the correct granularity.

The "identity cell at origin" invariant (§3.3.1) is **not** checked by `validateGraphGeometry`; it is covered by the `InvariantSpec` and `ApiSpec` test suites because it applies only to Poincaré-projected patches (not to hand-written layouts), and encoding the list of such patches inside `Invariants.hs` would duplicate knowledge already in `18_export_json.py`.

### 6.6 Known Limitation (Issue #8)

The Gauss–Bonnet check is tautological for 3D patches because `18_export_json.py` sets both `curvTotal` and `curvEuler` to the same computed value. It is independently meaningful only for 2D patches (filled, desitter) where the two values derive from separate computations.

---

## 7. Data Loading

The `DataLoader` module (`src/DataLoader.hs`) reads JSON files from the `data/` directory and decodes them into the domain types. All data is loaded eagerly at startup using strict `ByteString` reads and `eitherDecodeStrict'`.

### 7.1 API

```haskell
loadPatches            :: FilePath -> IO [Patch]
loadTower              :: FilePath -> IO [TowerLevel]
loadTheorems           :: FilePath -> IO [Theorem]
loadMeta               :: FilePath -> IO Meta
loadCurvatureSummaries :: FilePath -> IO [CurvatureSummary]
```

### 7.2 Patch Discovery

`loadPatches` discovers all `*.json` files in the `data/patches/` subdirectory, sorts them alphabetically, and decodes each one. Non-JSON entries are silently skipped.

### 7.3 Error Handling

On decode failure, `decodeFile` calls `fail` with a message containing the file path and the Aeson error string (raising an `IOError` in `IO`). On a missing file, `BS.readFile` itself raises an `IOException`. Both are caught by the startup sequence in `Main.hs`.

---

## 8. Startup Sequence

The entry point `app/Main.hs` executes a strict linear sequence:

1. **Parse CLI** — `--data-dir DIR` (default: `../data`), `--port PORT` (default: 8080), `--help`
2. **Print banner** — server version, data directory, port
3. **Load JSON** — Each of the 5 loaders reads from `data/` eagerly into memory. Counts are printed as each category loads.
4. **Validate invariants** — `Invariants.validateAll` runs all 9 invariant classes on all loaded data. If any violation is found, the full violation list is printed and the server aborts with `exitFailure`.
5. **Print summary** — patch count, total regions, "0 invariant violations"
6. **Build WAI app** — `Server.app` constructs the WAI `Application` with CORS + Cache-Control middleware. Handlers close over the in-memory data. A `Map.Map Text Patch` index is built once for O(log n) lookups.
7. **Start Warp** — `Network.Wai.Handler.Warp.run port application`. HTTP server binds and begins accepting connections.

**After startup, no further file I/O occurs.** All data is served from memory.

### 8.1 CLI Options

```
univalence-gravity-backend [OPTIONS]

Options:
  --data-dir DIR   Path to the data/ directory (default: ../data)
  --port PORT      HTTP port to listen on      (default: 8080)
  --help           Show help message and exit
```

---

## 9. Build and Dependencies

### 9.1 Build System

| Tool | Version | Notes |
|------|---------|-------|
| GHC | 9.6+ | Tested with 9.6.7 and 9.8.x |
| Cabal | 3.10+ | Uses `cabal.project` + freeze file |

### 9.2 Key Dependencies

| Package | Version | Role |
|---------|---------|------|
| `servant` | 0.20.x | Type-level API definition |
| `servant-server` | 0.20.x | WAI handler derivation |
| `warp` | 3.4.x | HTTP server |
| `wai-cors` | 0.2.x | CORS middleware |
| `aeson` | 2.2.x | JSON encoding/decoding |
| `containers` | 0.6.x | `Map.Map` for patch index, `Set.Set` for graph validation |

### 9.3 Cabal Configuration

`cabal.project` pins:

- `index-state: 2026-04-12T00:00:00Z` — reproducible Hackage snapshot
- `optimization: 0` — fast development iteration (~40–60% faster compile)
- `tests: True` — include test dependencies in the solver plan

`cabal.project.freeze` pins exact dependency versions for reproducible builds.

For production builds: `cabal build -O1` or `cabal run -O1 univalence-gravity-backend`.

### 9.4 Build Commands

```bash
cd backend
cabal update
cabal build all
cabal test all              # property-based + integration tests
cabal run univalence-gravity-backend
# → Listening on http://localhost:8080
```

---

## 10. Testing

### 10.1 Test Suites

```bash
cabal test all
```

Two test suites share a single `Spec.hs` entry point via `hspec-discover`.

### 10.2 InvariantSpec — Property-Based Tests

Tests load real JSON data from `../data` and verify every invariant. Coverage is both exhaustive (via the `validateAll` integration test) and probabilistic (via QuickCheck sampling with `overPool`).

**Named properties from the spec:**

| Property | Description | Verification |
|----------|-------------|-------------|
| `prop_halfBound` | `2·S(A) ≤ area(A)` for randomly sampled regions | QuickCheck, 100 iterations |
| `prop_orbitConsistency` | Same orbit ⟹ same min-cut | QuickCheck, 100 iterations |
| `prop_towerMonotone` | `maxCut_lo + k == maxCut_hi` for witnessed steps | Exhaustive (`conjoin`) |
| `prop_gaussBonnet` | `curvTotal == curvEuler` for all patches with curvature | Exhaustive (`conjoin`) |
| `prop_areaDecomp` | `area ≤ fpc·k` and `(fpc·k − area)` even | QuickCheck, 100 iterations |

**Additional checks:**

- `validateAll` integration (exhaustive, all patches × all invariants, including graph structure and geometry)
- Agda-aligned region counts (exact match against `Common/*Spec.agda` constructor counts for all 16 patches)
- `patchHalfBoundVerified` flag (True only for dense-100, dense-200, dense-1000; False for all others)
- Region sanity: non-negative min-cuts, positive areas, size/cells agreement, min-cut ≤ area
- Half-slack consistency: `regionHalfSlack == area − 2·S` when present
- Half-bound metadata: `hbViolations == 0` for all patches
- Region count consistency: `patchRegions == length patchRegionData`
- Patch maxCut regression: honeycomb-3d ≤ 2, honeycomb-145 = 9, dense-100 = 8, dense-200 = 9, dense-1000 = 9

**Graph structural tests (sampled via `overPool` plus exhaustive sweeps):**

- `pgNodes` count equals `patchCells`
- `pgEdges` count equals `patchBonds`
- All edge endpoints are valid node IDs (no dangling references)
- Every edge has exactly 2 endpoints
- All boundary cells from regions appear in `pgNodes`
- `pgNodes` count ≥ distinct boundary cell count
- Dense patches (dense-50/100/200/1000, honeycomb-145) have interior cells (`pgNodes > boundary`)
- `pgNodes` are sorted by `gnId`
- No self-loops in `pgEdges`
- No duplicate `gnId` values in `pgNodes`

**Graph geometry tests (sampled via `overPool`):**

- Every node position lies inside the Poincaré ball (`|u|² ≤ 1 + tol`)
- Every node quaternion has unit norm (`|q|² ≈ 1`)
- Every node scale is in `(0, 0.5 + tol]`
- **Centring (Bug 1 fix):** For every Poincaré-projected patch, cell 0 lands at the origin `(0, 0, 0)` with `gnScale ≈ 0.5`

### 10.3 ApiSpec — Servant-Client Integration Tests

Starts a Warp server on an ephemeral port via `testWithApplication`, hits every endpoint using auto-derived `servant-client` functions, and verifies:

- Every endpoint returns 200 with valid, decodable JSON
- `GET /patches/:name` returns 404 for unknown names (including empty name)
- Response payloads contain expected structural and regression values
- Tower monotonicity witnesses are arithmetically consistent
- All theorems have `Verified` status
- All expected patch names are present in the listing
- `patchHalfBoundVerified` flag is correct for each tested patch
- Dense-100 region data has correct structure (positive area, non-negative min-cut, consistent size, half-bound holds)
- **Graph structure at the endpoint level:** For all 16 patches, `pgNodes` count matches `patchCells`, `pgEdges` count matches `patchBonds`, every edge endpoint is a valid node ID, every edge has 2 endpoints, boundary cells are a subset of graph nodes, and dense patches have interior cells
- **Graph geometry at the endpoint level:** For sampled patches, `gnScale ∈ (0, 0.5 + tol]`, quaternions have unit norm, positions lie inside the Poincaré ball
- **Centring at the endpoint level:** For every Poincaré-projected patch, cell 0 lands at the origin with `gnScale ≈ 0.5`

**Regression values:** Tests assert specific numeric values for `patchMaxCut`, `patchOrbits`, `patchRegions`, `pgNodes` length, `pgEdges` length, etc. These track the current data snapshot produced by `18_export_json.py`. If the oracle is re-run with different parameters, these values may change legitimately. When updating: verify new values against the oracle output (`*_OUTPUT.txt`), then update the expected constants.

Assertions are categorised:

- **Structural:** Definitional properties (name, tiling, dimension, cell count). Should never change.
- **Regression:** Oracle-computed values (region counts, orbit counts, max min-cut, edge counts). Must be updated if oracle output changes.

### 10.4 Test Data Dependency

Tests read from `../data` (the repo-root `data/` directory). If the data directory is missing or stale, tests fail at the loading stage with a descriptive error.

---

## 11. Example Requests

```bash
# List all patches (lightweight summaries)
curl http://localhost:8080/patches | jq '.[] | .psName'

# Full Dense-100 data (717 regions, 8 orbits, 100 graph nodes, 150 edges)
curl http://localhost:8080/patches/dense-100 | jq '.patchMaxCut'
curl http://localhost:8080/patches/dense-100 | jq '.patchGraph.pgNodes | length'
curl http://localhost:8080/patches/dense-100 | jq '.patchGraph.pgNodes[0]'
# → {"id":0, "x":0, "y":0, "z":0, "qx":0, "qy":0, "qz":0, "qw":1, "scale":0.5}

# Full Dense-1000 data (10317 regions, 9 orbits, 1000 graph nodes, 1597 edges)
curl http://localhost:8080/patches/dense-1000 | jq '.patchRegions'
curl http://localhost:8080/patches/dense-1000 | jq '.patchGraph.pgEdges | length'

# Inspect a cell near the Poincaré boundary (scale should be small)
curl http://localhost:8080/patches/layer-54-d7 \
  | jq '.patchGraph.pgNodes | map(select(.scale < 0.01)) | length'

# Resolution tower monotonicity
curl http://localhost:8080/tower | jq '.[] | {name: .tlPatchName, maxCut: .tlMaxCut}'

# Theorem registry
curl http://localhost:8080/theorems | jq '.[] | {num: .thmNumber, name: .thmName}'

# Curvature (Gauss–Bonnet summaries)
curl http://localhost:8080/curvature | jq '.[] | .patchName'

# Metadata
curl http://localhost:8080/meta

# Health check
curl http://localhost:8080/health
# → {"status":"ok","patchCount":16,"regionCount":17419}
```

---

## 12. Relationship to the Agda Formalization

The backend serves data that has been **verified** by the Agda type-checker but does not contain any proof content. The relationship is:

| What the backend serves | What Agda verified |
|------------------------|-------------------|
| `regionMinCut` values | `Bridge/GenericBridge.agda`: S = L (Theorem 1) |
| `regionArea` and half-bound slack | `Bridge/HalfBound.agda`: 2·S ≤ area (Theorem 3) |
| Curvature classes and totals | `Bulk/GaussBonnet.agda`: Σκ = χ (Theorem 2) |
| Tower monotonicity witnesses | `Bridge/SchematicTower.agda`: (k, refl) |
| Orbit classifications | `OrbitReducedPatch.classify`: 717 → 8 orbits |
| `patchHalfBoundVerified` flag | `Boundary/*HalfBound.agda`: abstract (k, refl) for all regions |
| `patchGraph` coordinates, quaternions, scales | Not verified by Agda — geometric data for visualisation; correctness is numerical (Lorentz boost + SVD + conformal formula) and runtime-checked by §6 invariants |

The runtime invariant checks in `Invariants.hs` are not a substitute for Agda verification — they are a guard against corruption in the JSON export pipeline. A bug in `18_export_json.py` would produce data that fails the startup checks; a bug in the Agda formalization would produce a type error that the Agda compiler catches before any data is exported.

---

## 13. Frontend Integration

The frontend (`frontend/`) consumes this API via `src/api/client.ts`. Key integration points:

| Frontend Hook | Backend Endpoint | Data Used |
|---------------|-----------------|-----------|
| `usePatches()` | `GET /patches` | `PatchSummary` list for PatchCard grid |
| `usePatch(name)` | `GET /patches/:name` | Full `Patch` for 3D scene + panels, including `patchGraph` with per-cell position, quaternion, and scale |
| `useTower()` | `GET /tower` | `TowerLevel` list for timeline |
| `useTheorems()` | `GET /theorems` | `Theorem` list for dashboard |
| `useMeta()` | `GET /meta` | Version, build date for footer |

The frontend TypeScript types in `src/types/index.ts` mirror the backend Haskell types — including `GraphNode`'s quaternion and scale fields, which are consumed by `PatchScene.tsx` / `CellMesh.tsx` / `BoundaryWireframe.tsx` for Escher-style Poincaré rendering. The CORS middleware allows all origins during development; for production, restrict to the frontend domain.

See [`frontend-spec-webgl.md`](frontend-spec-webgl.md) for the full frontend specification.

---

## 14. Cross-References

| Topic | Document |
|-------|----------|
| Frontend specification (consumes this API) | [`engineering/frontend-spec-webgl.md`](frontend-spec-webgl.md) |
| Oracle pipeline (produces the data) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Orbit reduction (717 → 8 orbits) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| `abstract` barrier (sealed half-bound proofs) | [`engineering/abstract-barrier.md`](abstract-barrier.md) |
| Scaling report (region counts, timings) | [`engineering/scaling-report.md`](scaling-report.md) |
| Generic bridge (Theorem 1) | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Bekenstein–Hawking half-bound (Theorem 3) | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Gauss–Bonnet (Theorem 2) | [`formal/04-discrete-geometry.md`](../formal/04-discrete-geometry.md) |
| Canonical theorem registry | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Repository overview | [`docs/README.md`](../README.md) |
| Backend README | [`backend/README.md`](../../backend/README.md) |
| Per-instance data sheets | [`instances/`](../instances/) |