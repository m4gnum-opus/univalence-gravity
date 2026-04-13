# Univalence Gravity — Haskell Backend

**REST API serving pre-computed, Agda-verified holographic patch data.**

*Part of the [Univalence Gravity](../docs/README.md) project* | GHC 9.6+ | Servant 0.20 | MIT License

## What This Is

A hand-written Haskell server that reads JSON data exported by the Python oracle pipeline (`sim/prototyping/18_export_json.py`) and serves it via a type-safe Servant REST API. The data has been machine-checked by Cubical Agda 2.8.0; this backend carries only the verified *data*, not the proofs themselves.

The backend is **not** compiled from Agda. Cubical Agda's `--cubical` flag introduces interval variables, Glue types, and higher inductive types that have no meaningful runtime extraction. The GHC backend does not support cubical primitives. Instead, the serving layer reads static JSON produced by the oracle pipeline and validates data invariants at startup — mirroring, at the Haskell value level, the properties that the Agda type-checker enforces at the proof level.

For the full architectural rationale, data model, API contract, and implementation plan, see [`docs/engineering/backend-spec-haskell.md`](../docs/engineering/backend-spec-haskell.md).

## Prerequisites

You need GHC 9.6+ and Cabal 3.10+ installed. If you set up the Agda environment via GHCup (as described in [`docs/getting-started/setup.md`](../docs/getting-started/setup.md)), you already have both.

The `data/` directory must be populated before the backend can start. It is produced by the Python oracle export script and should already exist at the repository root. The `backend/data/` entry is a symlink (or copy) pointing to `../../data/`. If it is missing, create it:

```bash
cd backend
ln -s ../data data
```

## Build

```bash
cd backend
cabal update
cabal build all
```

The first build resolves and downloads dependencies (Servant, Warp, Aeson, wai-cors, etc.). Subsequent builds are incremental and fast.

## Run

```bash
cabal run univalence-gravity-backend
```

By default the server binds to port 8080 and reads from `./data/`. Both are configurable:

```bash
cabal run univalence-gravity-backend -- --data-dir ../data --port 3000
```

On startup the server loads all JSON files, validates every data invariant (half-bound, orbit consistency, Gauss–Bonnet, tower monotonicity), and prints a summary:

```
╔══════════════════════════════════════════════════════════╗
║  Univalence Gravity — Haskell Backend v0.1.0            ║
╚══════════════════════════════════════════════════════════╝

  Data directory : ./data
  Port           : 8080

  Loading patches           ... 14 patches
  Loading tower             ... 9 levels
  Loading theorems          ... 10 theorems
  Loading curvature         ... 6 entries
  Loading metadata          ... ok

  Validating invariants     ... passed

  ✓ 14 patches, 5405 regions, 0 invariant violations.

  Listening on http://localhost:8080
  Press Ctrl-C to stop.
```

If any invariant is violated (indicating a data-export bug), the server aborts before binding a port.

## Test

```bash
cabal test all
```

The test suite includes two modules discovered automatically by `hspec-discover`:

**`InvariantSpec`** loads real data from `data/` and runs property-based tests (QuickCheck) on every invariant from the backend specification §6: the discrete Bekenstein–Hawking half-bound (`2·S ≤ area` for every region), orbit consistency (same orbit implies same min-cut value), tower monotonicity (maxCut non-decreasing), and Gauss–Bonnet (curvature sum equals Euler characteristic). Additional checks verify region-count consistency, half-slack values, and half-bound violation counts.

**`ApiSpec`** starts a Warp server on an ephemeral port using `testWithApplication`, hits every endpoint with auto-derived `servant-client` functions, and verifies that all responses decode correctly. It also confirms that `GET /patches/nonexistent` returns HTTP 404.

Both test modules require the `data/` symlink to be in place.

## API Endpoints

All endpoints return JSON. The data is static and pre-computed; no mutation endpoints exist.

| Method | Path | Response | Description |
|--------|------|----------|-------------|
| GET | `/patches` | `[PatchSummary]` | Lightweight listing of all 14 patch instances |
| GET | `/patches/:name` | `Patch` | Full patch data including all regions, curvature, half-bound |
| GET | `/tower` | `[TowerLevel]` | Resolution tower levels with monotonicity witnesses |
| GET | `/theorems` | `[Theorem]` | All 10 theorems from the canonical registry with status |
| GET | `/curvature` | `[CurvatureSummary]` | Gauss–Bonnet summaries across patches with curvature data |
| GET | `/meta` | `Meta` | Version, Agda version, build date, data hash |
| GET | `/health` | `Health` | Server health check (data loaded, region counts) |

CORS is enabled for all origins (development default). All responses carry `Cache-Control: max-age=86400, immutable` because the data changes only when the Agda code is re-verified and the export script is re-run.

## Project Structure

```
backend/
├── backend.cabal              # Package definition, dependencies, build stanzas
├── cabal.project              # Solver settings, index-state pin
├── cabal.project.freeze       # Pinned dependency versions (reproducibility)
├── app/
│   └── Main.hs               # CLI parsing, data loading, startup sequence
├── src/
│   ├── Api.hs                 # Servant API type (one type alias, one Proxy)
│   ├── Server.hs              # Handler implementations, CORS, Cache-Control
│   ├── Types.hs               # Domain model: Patch, Region, TowerLevel, Theorem, ...
│   ├── DataLoader.hs          # JSON file reading from data/
│   └── Invariants.hs          # Startup validation (half-bound, orbit, GB, tower)
├── test/
│   ├── Spec.hs                # hspec-discover entry point
│   ├── InvariantSpec.hs       # Property-based tests on real data
│   └── ApiSpec.hs             # Servant-client integration tests
├── data/                      # Symlink → repo-root data/ (18_export_json.py output)
└── README.md                  # This file
```

## Data Pipeline

The backend sits at the end of a three-stage pipeline:

```
Agda (src/)              →  type-checks all theorems (verification layer)
Python Oracle (sim/)     →  computes patches, emits JSON + Agda modules
Haskell Backend (here)   →  reads JSON, validates invariants, serves REST API
```

The JSON data in `data/` is produced by `sim/prototyping/18_export_json.py`, which reads all oracle outputs and re-computes patch data using the same Coxeter infrastructure from scripts 01, 07, and 13. The export is deterministic and idempotent. To regenerate:

```bash
cd sim/prototyping
python3 18_export_json.py --output-dir ../../data
```

See [`docs/engineering/oracle-pipeline.md`](../docs/engineering/oracle-pipeline.md) for the full pipeline documentation.

## Relationship to Agda Types

The Haskell types in `Types.hs` are inspired by the Agda types but are not compiled from them. The correspondence:

| Agda Type | Haskell Type | Notes |
|-----------|-------------|-------|
| `PatchData` | `Patch` | Data fields only; no `obs-path` proof |
| `OrbitReducedPatch` | orbit fields within `Patch` | `patchOrbits`, `regionOrbit` |
| `BridgeWitness` | `tlHasBridge :: Bool` | Existence flag; no proof content |
| `HalfBoundWitness` | `HalfBoundData` | Numeric summaries; no `abstract` proofs |
| `GaussBonnetWitness` | `CurvatureData` | V, E, F, curvature values |
| `ℚ≥0 = ℕ` | `Int` | Direct correspondence |
| `ℚ₁₀ = ℤ` | `Int` | Tenths encoding preserved |

The Haskell types carry no proof content — only the verified *data*. The proofs live in Agda and are checked by the Cubical Agda type-checker; the data is exported by the Python oracle and served by Haskell.

## Freezing Dependencies

After all tests pass, pin exact dependency versions for reproducibility:

```bash
cabal freeze
git add cabal.project.freeze
```

## Further Reading

| Topic | Document |
|-------|----------|
| Full backend specification | [`docs/engineering/backend-spec-haskell.md`](../docs/engineering/backend-spec-haskell.md) |
| Frontend specification | [`docs/engineering/frontend-spec-webgl.md`](../docs/engineering/frontend-spec-webgl.md) |
| Oracle pipeline (data source) | [`docs/engineering/oracle-pipeline.md`](../docs/engineering/oracle-pipeline.md) |
| Theorem registry (served as JSON) | [`docs/formal/01-theorems.md`](../docs/formal/01-theorems.md) |
| Repository architecture | [`docs/getting-started/architecture.md`](../docs/getting-started/architecture.md) |
| Environment setup (GHC/Cabal) | [`docs/getting-started/setup.md`](../docs/getting-started/setup.md) |

## License

MIT — see the repository root [`LICENSE`](../LICENSE).