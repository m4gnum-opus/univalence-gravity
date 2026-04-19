# Univalence Gravity — Haskell Backend

A hand-written Haskell REST API serving pre-computed, Agda-verified holographic patch data via [Servant](https://docs.servant.dev/).

This backend is **not** compiled from Agda. Cubical Agda's `--cubical` flag has no meaningful GHC runtime extraction. Instead, the Python oracle pipeline (`sim/prototyping/18_export_json.py`) exports the verified data as JSON, and this server loads and serves it with startup invariant validation.

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| GHC | 9.6+ | Tested with 9.6.7 and 9.8.x |
| Cabal | 3.10+ | Uses `cabal.project` + freeze file |
| Data directory | — | `data/` must exist (symlink or copy of repo-root `data/`) |

The `data/` directory is produced by:

```bash
cd sim/prototyping
python3 18_export_json.py   # ~50 minutes (includes Dense-1000 and layer-54-d7)
```

A symlink from `backend/data` → `../data` is the default setup. The `--data-dir` CLI flag overrides the path.

## Quick Start

```bash
cd backend
cabal update
cabal build all
cabal test all              # property-based + integration tests
cabal run univalence-gravity-backend
# → Listening on http://localhost:8080
```

## CLI Options

```
univalence-gravity-backend [OPTIONS]

Options:
  --data-dir DIR   Path to the data/ directory (default: ../data)
  --port PORT      HTTP port to listen on      (default: 8080)
  --help           Show help message and exit
```

## API Endpoints

All endpoints return `application/json`. The data is static and pre-computed; no mutation endpoints exist.

| Method | Path | Response Type | Description |
|--------|------|---------------|-------------|
| `GET` | `/patches` | `[PatchSummary]` | List all 16 verified patch instances (lightweight) |
| `GET` | `/patches/:name` | `Patch` | Full patch data: regions, curvature, half-bound, bulk graph |
| `GET` | `/tower` | `[TowerLevel]` | Resolution tower with monotonicity witnesses |
| `GET` | `/theorems` | `[Theorem]` | All 10 machine-checked theorems |
| `GET` | `/curvature` | `[CurvatureSummary]` | Gauss–Bonnet summaries per patch |
| `GET` | `/meta` | `Meta` | Version, Agda version, build date, data hash |
| `GET` | `/health` | `Health` | Server health check (exempt from caching) |

### Example Requests

```bash
# List all patches
curl http://localhost:8080/patches | jq '.[] | .psName'

# Get full Dense-100 data (717 regions, 8 orbits, 100 graph nodes, 150 edges)
curl http://localhost:8080/patches/dense-100 | jq '.patchMaxCut'
curl http://localhost:8080/patches/dense-100 | jq '.patchGraph.pgNodes | length'

# Inspect cell 0 — identity cell, projected to the origin
curl http://localhost:8080/patches/dense-100 \
  | jq '.patchGraph.pgNodes[] | select(.id == 0)'
# → {"id":0, "x":0, "y":0, "z":0, "qx":0, "qy":0, "qz":0, "qw":1, "scale":0.5}

# Find cells near the Poincaré boundary (scale → 0)
curl http://localhost:8080/patches/layer-54-d7 \
  | jq '.patchGraph.pgNodes | map(select(.scale < 0.01)) | length'

# Resolution tower monotonicity
curl http://localhost:8080/tower | jq '.[] | {name: .tlPatchName, maxCut: .tlMaxCut}'

# Health check
curl http://localhost:8080/health
# → {"status":"ok","patchCount":16,"regionCount":17419}
```

### Patch Names

Valid `:name` values for `GET /patches/:name`:

```
tree, star, filled, desitter, honeycomb-3d, honeycomb-145,
dense-50, dense-100, dense-200, dense-1000,
layer-54-d2, layer-54-d3, layer-54-d4, layer-54-d5, layer-54-d6, layer-54-d7
```

Unknown names return HTTP 404.

## Architecture

```
backend/
├── app/
│   └── Main.hs             -- CLI parsing, data loading, startup validation, Warp
│
├── src/
│   ├── Types.hs            -- Domain model (Patch, Region, GraphNode, PatchGraph, ...)
│   ├── Api.hs              -- Servant API type definition (type-level routing)
│   ├── Server.hs           -- Handler implementations + CORS/Cache-Control middleware
│   ├── DataLoader.hs       -- JSON parsing from data/ directory
│   └── Invariants.hs       -- Startup validation (half-bound, orbit, graph, geometry, ...)
│
├── test/
│   ├── Spec.hs             -- hspec-discover entry point
│   ├── InvariantSpec.hs    -- Property-based tests on real data (QuickCheck)
│   └── ApiSpec.hs          -- Servant-client integration tests (ephemeral Warp server)
│
├── backend.cabal
├── cabal.project
└── cabal.project.freeze
```

### Startup Sequence

1. **Parse CLI** — `--data-dir`, `--port`
2. **Load JSON** — `DataLoader` reads all files from `data/` eagerly into memory
3. **Validate invariants** — `Invariants.validateAll` checks every data property; aborts on any violation
4. **Build WAI app** — Servant handlers close over the in-memory data; `Map.Map` index on patch names for O(log n) lookup
5. **Start Warp** — HTTP server binds to the configured port

After startup, **no further file I/O occurs**. All data is served from memory.

### Middleware

| Middleware | Behaviour |
|-----------|-----------|
| **CORS** | Allows all origins (development). For production, restrict to the frontend domain. |
| **Cache-Control** | `max-age=86400, immutable` on all endpoints except `/health` |

## Domain Model Highlights

### Full Bulk Graph (`patchGraph`)

Every `Patch` carries a non-optional `patchGraph` with two fields:

- **`pgNodes :: [GraphNode]`** — one entry per cell (including interior cells invisible to any boundary region), sorted by ID.
- **`pgEdges :: [Edge]`** — one `{source, target}` object per physical bond (shared face in 3D, shared edge in 2D).

Each `GraphNode` carries the **uniform schema** produced by `_make_patch_graph` in `18_export_json.py`, regardless of whether the geometry comes from the Poincaré projector or a hand-written 2D layout:

| Field | Meaning |
|-------|---------|
| `gnId` | Cell or tile identifier (matches edge endpoints) |
| `gnX`, `gnY`, `gnZ` | Coordinates in the Poincaré ball (3D) or disk embedded as `z = 0` (2D). Always in the open unit ball: `x² + y² + z² < 1`. |
| `gnQx`, `gnQy`, `gnQz`, `gnQw` | Unit quaternion for this cell's rotation relative to the fundamental cell. For 2D patches this is a z-axis rotation (only `qz, qw` non-zero); for 3D patches it uses the full Shepperd–Shuster conversion of the rotation extracted from the (boosted) Jacobian of the projection. Hand-written 2D layouts use the identity `(0, 0, 0, 1)`. |
| `gnScale` | Conformal scale factor `s(u) = (1 − |u|²) / 2`. Cells at the centre have `s ≈ 0.5`; cells near the boundary have `s → 0`. Clamped to `1e-6` to avoid zero-scale degeneracy at `|u| = 1`. |

**Centring invariant (Bug 1 fix).** For every patch whose coordinates come from `poincare_project` (all Coxeter-generated patches: honeycomb-3d, honeycomb-145, dense-50/100/200/1000, layer-54-d{2..7}), the cell with `gnId = 0` — the Coxeter group identity `g = I` — projects to the origin `(0, 0, 0)` with `gnScale ≈ 0.5`. This is enforced by a Lorentz boost applied at the start of the projector and verified both at startup (via `validateGraphGeometry`) and in the test suite (`InvariantSpec`, `ApiSpec`).

This data is what the frontend needs to render the full 3D holographic representation correctly (Escher-style Poincaré shrinking, correct per-cell rotation, centred viewport) — inferring nodes/edges from region data alone would miss interior cells and misinterpret boundary adjacency as physical bonds.

## Testing

```bash
cabal test all
```

### Test Suites

**InvariantSpec** — Property-based tests on real exported data:

- `validateAll` integration (exhaustive, all patches × all invariants, including graph structure and geometry)
- Agda-aligned region counts (exact match against `Common/*Spec.agda` constructor counts)
- `patchHalfBoundVerified` flag (True only for dense-100, dense-200, dense-1000)
- `prop_halfBound`: 2·S(A) ≤ area(A) for randomly sampled regions
- `prop_orbitConsistency`: same orbit label ⟹ same min-cut value
- `prop_towerMonotone`: maxCut consistent with monotonicity witnesses
- `prop_gaussBonnet`: Σκ = χ for all patches with curvature data
- `prop_areaDecomp`: area ≤ fpc·k and (fpc·k − area) is even
- Region sanity: non-negative min-cuts, positive areas, size/cells agreement
- **Graph structure**: node/edge counts match `patchCells`/`patchBonds`, endpoint validity, boundary coverage, sorted node IDs, no self-loops, no duplicate IDs, dense patches contain interior cells
- **Graph geometry**: positions inside the Poincaré ball (`|u|² ≤ 1`), quaternions with unit norm (`|q|² ≈ 1`), scales in `(0, 0.5 + tol]`, **cell 0 at the origin with `scale ≈ 0.5`** for every Poincaré-projected patch

**ApiSpec** — Servant-client integration tests:

- Every endpoint returns 200 with valid, decodable JSON
- `GET /patches/:name` returns 404 for unknown names
- Response payloads contain expected values (regression tests tracking the current data snapshot)
- Tower monotonicity witnesses are arithmetically consistent
- All theorems have `Verified` status
- `patchGraph` structure at the endpoint level (node/edge counts, endpoint validity, boundary coverage, interior cells in dense patches)
- `patchGraph` geometry at the endpoint level (scale in valid range, quaternion unit norm, position inside the Poincaré ball)
- **Centring at the endpoint level**: cell 0 lands at the origin with `scale ≈ 0.5` for every Poincaré-projected patch

### Test Data Dependency

Tests read from `../data` (the repo-root `data/` directory). If the data directory is missing or stale, tests will fail at the loading stage with a descriptive error.

## Data Pipeline

```
sim/prototyping/                      (Python oracle)
  ├── 01–17: Coxeter geometry, max-flow, region enumeration, Agda code generation
  └── 18_export_json.py               (JSON export: regions + full bulk graph)
        │
        ▼
data/                                 (pre-computed JSON)
  ├── patches/  (16 files)
  ├── tower.json
  ├── theorems.json
  ├── curvature.json
  └── meta.json
        │
        ▼
backend/                              (this server)
  ├── DataLoader.hs  (reads JSON at startup)
  ├── Invariants.hs  (validates at startup, incl. graph geometry)
  └── Server.hs      (serves from memory)
```

The JSON files are **not** committed to the repository (they are in `.gitignore` under `data/`). To regenerate:

```bash
cd sim/prototyping
python3 18_export_json.py    # ~50 minutes
```

### Poincaré Projection (Export Pipeline)

Every Coxeter-generated patch runs through `poincare_project` in `18_export_json.py`, which projects cell centres from the hyperboloid to the Poincaré ball/disk in three composed steps (matching the "Centre Patches in Poincaré Projection" engineering roadmap):

1. **Centring (Lorentz boost).** Diagonalise the Gram matrix, change into the canonical Minkowski basis, then apply a Lorentz boost that maps the fundamental cell centre to the time-axis apex. After this boost, the cell with `g = I` projects to the origin of the Poincaré ball.

2. **Per-cell conformal scale.** `s(u) = (1 − |u|²) / 2`, clamped at `1e-6` near the disk boundary (required for layer-54-d7, where cells are exponentially close to `|u| = 1`).

3. **Per-cell rotation quaternion.** Compute the per-cell boost that sends the cell's (boosted) canonical position back to the apex; apply it to obtain a rotation fixing the apex. The spatial block is orthogonalised via SVD and converted to a unit quaternion (Shepperd–Shuster for 3D, z-axis rotation for 2D).

All coordinates, quaternion components, and scales are rounded to 6 decimal digits before JSON serialisation. The 1e-4 runtime tolerance used by `validateGraphGeometry` comfortably absorbs this round-off.

### Agda Alignment

Each patch's region count and `max_region_cells` parameter must match the corresponding Agda Spec module (`Common/*Spec.agda`). Key alignment parameters:

| Patch | max_rc | Regions | Agda Module |
|-------|--------|---------|-------------|
| honeycomb-3d | 1 | 26 | `Common/Honeycomb3DSpec.agda` |
| honeycomb-145 | 5 | 1,008 | `Common/Honeycomb145Spec.agda` |
| dense-50 | 5 | 139 | `Common/Dense50Spec.agda` |
| dense-100 | 5 | 717 | `Common/Dense100Spec.agda` |
| dense-200 | 5 | 1,246 | `Common/Dense200Spec.agda` |
| dense-1000 | 6 | 10,317 | `Common/Dense1000Spec.agda` |
| layer-54-d{2..7} | 4 | 15–1,885 | `Common/Layer54d{2..7}Spec.agda` |

The `patchHalfBoundVerified` flag is `True` only for patches with a corresponding `Boundary/*HalfBound.agda` module that machine-checks `2·S(A) ≤ area(A)` via `abstract (k, refl)` witnesses: **dense-100**, **dense-200**, **dense-1000**.

## Invariant Checks

The following properties are validated at startup (and tested in `InvariantSpec`):

| Invariant | Description | Agda / Engineering Counterpart |
|-----------|-------------|-------------------------------|
| Half-bound | 2·S(A) ≤ area(A) for every region | `Bridge/HalfBound.agda` (Theorem 3) |
| Half-slack consistency | `regionHalfSlack == area - 2*S` when present | Derived from half-bound |
| Orbit consistency | Same orbit label ⟹ same min-cut value | `OrbitReducedPatch.rep-agree` |
| Area decomposition | `area ≤ fpc·k` and `(fpc·k - area)` even | Face-count formula |
| Region count | `patchRegions == length patchRegionData` | Data type constructor count |
| Gauss–Bonnet | `curvTotal == curvEuler` when curvature present | `Bulk/GaussBonnet.agda` (Theorem 2) |
| Tower monotonicity | `maxCut_lo + k == maxCut_hi` for witnessed steps | `LayerStep.monotone` |
| Half-bound metadata | `hbViolations == 0` | Oracle abort condition |
| **Graph structure** | Node/edge counts, endpoint validity, boundary coverage, no self-loops, unique IDs | `PatchGraph` §3.3 of backend spec |
| **Graph geometry** | Position in Poincaré ball, quaternion unit-norm, scale in `(0, 0.5 + tol]` | `GraphNode` field semantics |

The graph structure and geometry checks are new in the current revision; they catch failure modes in the export pipeline (missing interior cells, broken projection, non-unit quaternions, NaN/negative scale, off-centre identity cell) without requiring the full Agda formalisation of the holographic geometry.

## Development

### Build with Optimisations Off (Default)

`cabal.project` sets `optimization: 0` for fast iteration (~40–60% faster compile). For production:

```bash
cabal build -O1
cabal run -O1 univalence-gravity-backend
```

### Dependency Management

The `cabal.project.freeze` file pins exact dependency versions. To update:

```bash
cabal freeze
```

The `index-state` in `cabal.project` pins the Hackage snapshot for reproducibility.

## Related Documentation

| Document | Description |
|----------|-------------|
| [`docs/engineering/backend-spec-haskell.md`](../docs/engineering/backend-spec-haskell.md) | Full backend specification |
| [`docs/engineering/frontend-spec-webgl.md`](../docs/engineering/frontend-spec-webgl.md) | Frontend specification (consumes this API) |
| [`docs/engineering/oracle-pipeline.md`](../docs/engineering/oracle-pipeline.md) | Python oracle pipeline (scripts 01–18) |
| [`docs/formal/01-theorems.md`](../docs/formal/01-theorems.md) | Canonical theorem registry |
| [`docs/formal/12-bekenstein-hawking.md`](../docs/formal/12-bekenstein-hawking.md) | Discrete Bekenstein–Hawking bound |
| [`docs/README.md`](../docs/README.md) | Repository overview |

## License

MIT — see [`LICENSE`](../LICENSE).