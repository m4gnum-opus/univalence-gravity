# Univalence Gravity — Frontend

**A React + Three.js browser application rendering interactive 3D visualizations of Agda-verified holographic patch data.**

The frontend is a single-page application (SPA) that consumes the Haskell backend REST API and renders interactive 3D visualizations of the 16 verified holographic patch instances, the resolution tower, and the theorem registry. All displayed data has been machine-checked by Cubical Agda 2.8.0; the frontend is a pure visualization layer with no proof content and performs no mathematical computation.

For the full specification, see [`docs/engineering/frontend-spec-webgl.md`](../docs/engineering/frontend-spec-webgl.md).

---

## Quick Start

### Prerequisites

- **Node.js** ≥ 20 (with `npm` ≥ 10)
- A running **backend** server on `http://localhost:8080` (see [`../backend/README.md`](../backend/README.md))
- A WebGL 2 capable browser (Chrome 94+, Firefox 93+, Safari 15+, Edge 94+)

### Install & Run

```bash
cd frontend
npm install
npm run dev
# → Vite dev server on http://localhost:5173
```

The app fetches from the backend via `VITE_API_URL` (default: `http://localhost:8080`). To point at a different backend:

```bash
echo 'VITE_API_URL=http://my-backend:9000' > .env.local
npm run dev
```

### Production Build

```bash
npm run build      # type-check (tsc -b) + vite build → dist/
npm run preview    # serve dist/ locally to verify
```

The `dist/` directory contains static files suitable for any static file server. The SPA requires a fallback to `index.html` for all routes (see [`docs/engineering/frontend-spec-webgl.md`](../docs/engineering/frontend-spec-webgl.md) §14.3 for an nginx example).

---

## Technology Stack

| Layer | Package | Version | Purpose |
|-------|---------|---------|---------|
| UI Framework | React | 18.3 | Component tree, hooks, concurrent rendering |
| Routing | React Router | 6.28 | Client-side SPA routing |
| 3D Rendering | Three.js | 0.170 | WebGL scene graph |
| R3F | @react-three/fiber | 8.17 | React reconciler for Three.js |
| Drei | @react-three/drei | 9.114 | OrbitControls, scene helpers |
| Charts | Recharts | 2.13 | Min-cut + S/area histograms |
| Layout (fallback) | d3-force-3d | 3.0 | Barnes-Hut force simulation |
| Styling | Tailwind CSS | 3.4 | Utility-first CSS |
| Build | Vite | 6.4 | Dev server + production bundler |
| Language | TypeScript | 5.6 | Static types (`strict: true`, `noUncheckedIndexedAccess: true`, no `any`) |
| Testing | Vitest | 1.6 | Test runner |

---

## Project Layout

```
frontend/
├── index.html
├── package.json, tsconfig.json, vite.config.ts
├── tailwind.config.js, postcss.config.js, eslint.config.js
├── .env.example
│
├── public/
│   └── favicon.ico
│
├── src/
│   ├── main.tsx, App.tsx, vite-env.d.ts
│   │
│   ├── api/
│   │   └── client.ts              # Typed fetch wrappers (7 endpoints)
│   │
│   ├── types/
│   │   └── index.ts               # TypeScript interfaces + 13 type guards
│   │
│   ├── hooks/
│   │   ├── usePatch.ts            # GET /patches/:name
│   │   ├── usePatches.ts          # GET /patches
│   │   ├── useTower.ts            # GET /tower
│   │   ├── useTheorems.ts         # GET /theorems
│   │   └── useMeta.ts             # GET /meta
│   │
│   ├── components/
│   │   ├── common/                # Loading, ErrorMessage, NotFound
│   │   ├── layout/                # Header, Footer, Layout
│   │   ├── home/                  # HomePage, TheoremCard
│   │   ├── patches/               # PatchCard, PatchList, PatchView,
│   │   │                          # PatchScene, CellMesh, BondConnector,
│   │   │                          # BoundaryWireframe, BoundaryShell,
│   │   │                          # DynamicsView, RegionInspector,
│   │   │                          # CurvaturePanel, HalfBoundPanel,
│   │   │                          # DistributionChart, ColorControls
│   │   ├── tower/                 # TowerView, TowerTimeline, TowerLevel,
│   │   │                          # TowerAnimation
│   │   └── theorems/              # TheoremDashboard, TheoremRow
│   │
│   ├── utils/
│   │   ├── colors.ts              # Viridis + diverging scales
│   │   ├── layout.ts              # Poincaré read-through + force fallback
│   │   └── tiling.ts              # Three.js geometry factories
│   │
│   └── styles/
│       └── globals.css            # Tailwind directives + base styles
│
└── tests/
    ├── setup.ts
    ├── api.test.ts                # URL construction, error handling, abort
    ├── types.test.ts              # 13 type guards
    ├── utils/colors.test.ts       # Viridis + diverging scales
    ├── hooks/usePatch.test.ts     # Loading, 404, abort, refetch
    └── components/
        ├── PatchCard.test.tsx
        ├── PatchScene.test.tsx    # All tilings, color modes, toggles
        └── TheoremCard.test.tsx
```

---

## Application Routes

| Path | Component | Backend Endpoint | Description |
|------|-----------|------------------|-------------|
| `/` | `HomePage` | `/meta`, `/theorems` | Project overview + theorem status grid |
| `/patches` | `PatchList` | `/patches` | Browsable card grid with sort + filter |
| `/patches/:name` | `PatchView` | `/patches/:name` | Interactive 3D patch viewer + panels |
| `/tower` | `TowerView` | `/tower` | Resolution tower timeline |
| `/theorems` | `TheoremDashboard` | `/theorems` | Expandable accordion of all 10 theorems |
| `*` | `NotFound` | — | 404 catch-all |

Valid patch names:

```
tree, star, filled, desitter, honeycomb-3d, honeycomb-145,
dense-50, dense-100, dense-200, dense-1000,
layer-54-d2, layer-54-d3, layer-54-d4, layer-54-d5, layer-54-d6, layer-54-d7
```

---

## 3D Rendering Pipeline

`PatchScene` (inside `<Canvas>`) renders every cell, every physical bond, and an optional boundary wireframe + boundary shell. The visualization is driven entirely by the `patchGraph` field of the backend's `Patch` response, which carries per-cell positions, rotation quaternions, and conformal scales pre-computed by the Python oracle (`sim/prototyping/18_export_json.py`).

### Poincaré Projection Read-Through

Cell transforms are read directly from `patchGraph.pgNodes`:

| Field | Meaning |
|-------|---------|
| `x, y, z` | Poincaré ball (3D) or disk-with-`z = 0` (2D) coordinates |
| `qx, qy, qz, qw` | Unit quaternion encoding the cell's rotation relative to the fundamental cell |
| `scale` | Conformal factor `s(u) = (1 − |u|²) / 2`, clamped at `1e-6` |

Three corrections from the Python exporter are reflected unchanged by the frontend:

1. **Centring (Lorentz boost).** The fundamental cell `g = I` is mapped to the hyperboloid apex so it projects to the origin `(0, 0, 0)` of the Poincaré ball. `OrbitControls` therefore orbit the correct point without additional translation.
2. **Per-cell conformal scale.** Cells near the centre have `scale ≈ 0.5`; cells near the boundary have `scale → 0` — the canonical Escher "Circle Limit" shrinking.
3. **Per-cell rotation quaternion.** Baked into the `<group>` wrapper (individual path) or the instance matrix (instanced path). Omitting this causes visible asymmetric "squishing" on layer-54-dX and dense-growth patches.

### Scene Composition

```
<Canvas>
  <ambientLight /> <directionalLight /> <OrbitControls damping />

  <group name="cells">                   (individual meshes OR InstancedMesh)
    <CellMesh .../>    × N  (≤500 total cells)
    – OR –
    <instancedMesh .../>   (>500 total cells)
    <SelectionOverlay .../>  (max 5 emissive meshes on the instanced path)
  </group>

  <group name="bonds">
    <BondConnector .../>   × M  (every entry in patchGraph.pgEdges)
  </group>

  <BoundaryWireframe />   (1 merged draw call across all boundary cells)
  <BoundaryShell />       (semi-transparent sphere centred at the origin)
</Canvas>
```

All cells are rendered — boundary cells in data-driven colours, interior cells in neutral gray at reduced opacity. The boundary shell is anchored at the scene origin (where the Lorentz-boosted fundamental cell lives), not at the boundary-cell centroid — this keeps the shell wrapping the patch symmetrically for symmetric patches and visually enclosing the structure for asymmetric ones.

Cell materials use `depthWrite: false` so translucent cells do not occlude the bonds that pass through (or terminate inside) them after the conformal packing near the centre.

### Performance

- **InstancedMesh** kicks in at >500 cells (total, including interior cells). Positions, rotations, and scales are baked into the per-instance matrix via `dummy.position.set` / `dummy.quaternion.set` / `dummy.scale.setScalar` / `dummy.updateMatrix`.
- **Merged wireframe:** all boundary cells' edge outlines are concatenated into a single `BufferGeometry` → 1 draw call regardless of cell count.
- **Shared bond geometry:** a module-level unit `CylinderGeometry` is scaled per bond; `N` bonds → 1 geometry.
- **Layout cache:** force-directed fallback positions are cached in `sessionStorage`. The primary read-through path doesn't cache (it's already just a `Map` build).

### Color Modes

Four modes, selectable via `ColorControls`:

| Mode | Scale | Domain | Notes |
|------|-------|--------|-------|
| **Min-Cut** (default) | Viridis | `[1, maxCut]` | Higher S = warmer |
| **Region Size** | Green→Purple | `[1, maxSize]` | Larger = darker |
| **S/area Ratio** | Blue→White→Red | `[0, 0.5]` | 0.5 = Bekenstein–Hawking bound (red) |
| **Curvature** | Blue→White→Red | symmetric | Negative=blue, Positive=red |

Interior cells always receive a fixed neutral gray (`#6b7280`) regardless of mode. Viridis is the default because it is perceptually uniform and colourblind-safe.

---

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start Vite dev server with HMR on `localhost:5173` |
| `npm run build` | Type-check (`tsc -b`) + production build → `dist/` |
| `npm run preview` | Serve the production build locally |
| `npm run test` | Run all Vitest tests |
| `npm run lint` | ESLint with TypeScript strict rules |

---

## Testing

Tests use Vitest + `@testing-library/react` with jsdom. The test suites cover:

- **API client:** URL construction, error handling (`ApiError`), abort signals, `AbortError` silencing
- **Type guards:** 13 guards including `isGraphNode`, `isEdge`, `isPatchGraph`
- **Color scales:** Viridis endpoints, diverging midpoints, edge cases
- **Hooks:** Loading → success, 404, abort on unmount, refetch, dependency change
- **Components:**
  - `PatchCard` — tiling symbols, orbit formatting, links
  - `PatchScene` — smoke tests across all 5 tilings, all 4 color modes, selection highlight, `showBonds` / `showBoundary` / `showShell` toggles, boundary/interior breakdown in ARIA label, bond count reporting
  - `TheoremCard` — status badges, ARIA labels, all 10 theorems

`@react-three/fiber` Canvas and `@react-three/drei` OrbitControls are mocked because jsdom has no WebGL context. All component logic (layout read-through, colours, adjacency, selection, ARIA labels, `showShell` toggle) still executes fully; only actual GPU rendering is bypassed.

```bash
npm run test               # all suites
npm run test -- --watch    # re-run on file change
```

---

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VITE_API_URL` | `http://localhost:8080` | Backend API base URL (no trailing slash) |

Set in `.env`, `.env.local`, or the shell. Vite statically replaces `import.meta.env.VITE_API_URL` at build time.

---

## Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Academic credibility** | Serif headings (Georgia), monospace for Agda/module references, muted Viridis palette |
| **Progressive disclosure** | Listing shows lightweight summaries; full patch loads on navigation; accordions expand on click |
| **Colorblind safety** | Viridis default; blue→white→red diverging for curvature / ratio |
| **Keyboard navigation** | All interactive elements focusable; ARIA labels throughout |
| **Reduced motion** | `prefers-reduced-motion` disables animations, auto-rotation, auto-play |
| **No `any` types** | `@typescript-eslint/no-explicit-any: "error"` + `strict: true` + `noUncheckedIndexedAccess` |
| **Geometric correctness** | Cell positions, rotations, and conformal scales come from the Agda-aligned Python oracle — the frontend never invents geometry for Coxeter patches, only reads it |

---

## Relationship to the Agda Formalization

The frontend displays data that has been **verified** by the Agda type-checker but contains no proof content:

| What the frontend displays | What Agda verified |
|---------------------------|-------------------|
| Cell colours by `regionMinCut` | `Bridge/GenericBridge.agda`: S = L (Theorem 1) |
| S/area ratio + half-slack | `Bridge/HalfBound.agda`: 2·S ≤ area (Theorem 3) |
| Curvature panel + Gauss–Bonnet badge | `Bulk/GaussBonnet.agda`: Σκ = χ (Theorem 2) |
| Tower monotonicity arrows `(k, refl)` | `Bridge/SchematicTower.agda` |
| Theorem status badges | Each theorem's Agda module type-checks |
| Orbit classification sidebar | `OrbitReducedPatch.classify` |
| `patchHalfBoundVerified` badge | `Boundary/*HalfBound.agda`: `abstract (k, refl)` |
| DynamicsView 8-step perturbation | `Bridge/StarStepInvariance.agda` + `Bridge/StarDynamicsLoop.agda` (Theorem 9) |
| Poincaré positions / quaternions / scales | **Not Agda-verified** — geometric visualisation data produced by `18_export_json.py` (Lorentz boost + SVD + conformal formula) and runtime-checked by the Haskell backend's `validateGraphGeometry` invariants |

The frontend adds **no mathematical content** — it is a visualization layer that renders pre-computed, pre-verified (or, for geometry, runtime-checked) data in a form that is explorable by researchers.

---

## Browser Requirements

- **WebGL 2** (required for Three.js r170+)
- **ES2022** (target in `tsconfig.json`)
- Chrome 94+, Firefox 93+, Safari 15+, Edge 94+

---

## Further Reading

| Topic | Document |
|-------|----------|
| Full frontend specification | [`docs/engineering/frontend-spec-webgl.md`](../docs/engineering/frontend-spec-webgl.md) |
| Backend API (data source) | [`docs/engineering/backend-spec-haskell.md`](../docs/engineering/backend-spec-haskell.md) |
| Backend README | [`../backend/README.md`](../backend/README.md) |
| Oracle pipeline (produces the data) | [`docs/engineering/oracle-pipeline.md`](../docs/engineering/oracle-pipeline.md) |
| Repository overview | [`../docs/README.md`](../docs/README.md) |
| Per-instance data sheets | [`../docs/instances/`](../docs/instances/) |
| Canonical theorem registry | [`../docs/formal/01-theorems.md`](../docs/formal/01-theorems.md) |

---

## License

MIT — see [`../LICENSE`](../LICENSE).