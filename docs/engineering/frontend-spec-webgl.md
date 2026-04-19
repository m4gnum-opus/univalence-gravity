# Frontend Specification — WebGL Visualization

**A React + Three.js browser application rendering interactive 3D visualizations of Agda-verified holographic patch data.**

**Audience:** Frontend developers, proof engineers integrating with the Haskell backend, and anyone deploying or extending the visualization layer.

**Primary source tree:** `frontend/src/` (components, hooks, utils, API client, types)

**Prerequisites:** Familiarity with the backend API specification ([`backend-spec-haskell.md`](backend-spec-haskell.md)), the data export pipeline ([`oracle-pipeline.md`](oracle-pipeline.md)), and the overall repository architecture ([`getting-started/architecture.md`](../getting-started/architecture.md)).

---

## 1. Overview

The Univalence Gravity frontend is a single-page application (SPA) that consumes the Haskell backend REST API and renders interactive 3D visualizations of the 16 verified holographic patch instances, the resolution tower, and the theorem registry. All displayed data has been machine-checked by Cubical Agda 2.8.0; the frontend is a pure visualization layer with no proof content and performs no mathematical computation.

**What this frontend is NOT:**

- **Not a proof viewer.** It does not display or interact with Agda source code, proof terms, or type signatures beyond the informal statements in the theorem registry.
- **Not a computation engine.** Min-cut values, curvature, orbit classifications, half-bound statistics, patch-graph coordinates, rotation quaternions, and conformal scales are pre-computed by the Python oracle, verified (or numerically checked) by the pipeline, and served by the Haskell backend. The frontend performs only geometric read-through + color mapping + (fallback-only) force-directed positioning.
- **Not a database client.** All data is fetched from the backend's static, immutable JSON endpoints. No writes, no authentication, no user accounts.

**Key design properties:**

| Property | Value |
|----------|-------|
| Framework | React 18 + TypeScript 5 (strict mode) |
| 3D Rendering | Three.js 0.170 via React Three Fiber 8 + Drei 9 |
| Styling | Tailwind CSS 3 (utility-first) |
| Charts | Recharts 2 (histogram distributions) |
| Cell Layout (primary) | Poincaré projections read from `patchGraph.pgNodes` |
| Cell Layout (fallback) | d3-force-3d 3 (Barnes-Hut force simulation) |
| Build Tool | Vite 6 |
| Testing | Vitest 1 + Testing Library |
| Backend | `GET` requests to `http://localhost:8080` (Haskell/Servant) |
| Total patches visualized | 16 (14 standard + honeycomb-145 + dense-1000) |
| Largest patch rendered | Dense-1000 (1000 cells, 10,317 regions, ~3.5 MB JSON) |

---

## 2. Architecture

```
backend (Haskell/Servant)         frontend (React/Three.js)
┌─────────────────────────┐      ┌─────────────────────────────────────┐
│ GET /patches             │─────▶│ usePatches() → PatchList            │
│ GET /patches/:name       │─────▶│ usePatch(name) → PatchView          │
│ GET /tower               │─────▶│ useTower() → TowerView              │
│ GET /theorems            │─────▶│ useTheorems() → TheoremDashboard    │
│ GET /meta                │─────▶│ useMeta() → Footer, HomePage        │
│ GET /curvature           │      │ (consumed by PatchView panels)      │
│ GET /health              │      │ (monitoring only)                   │
└─────────────────────────┘      └─────────────────────────────────────┘
```

### Module Dependency Structure

```
src/types/index.ts              ← TypeScript interfaces (dependency root)
    │
    ├── src/api/client.ts       ← Typed fetch wrappers (7 endpoints)
    │       │
    │       ├── src/hooks/usePatch.ts      ← GET /patches/:name
    │       ├── src/hooks/usePatches.ts    ← GET /patches
    │       ├── src/hooks/useTower.ts      ← GET /tower
    │       ├── src/hooks/useTheorems.ts   ← GET /theorems
    │       └── src/hooks/useMeta.ts       ← GET /meta
    │
    ├── src/utils/colors.ts     ← Viridis + diverging color scales
    ├── src/utils/layout.ts     ← Poincaré read-through + force-directed fallback
    └── src/utils/tiling.ts     ← Three.js geometry factories
            │
            └── src/components/  ← React component tree (see §6)
                    │
                    ├── common/     Loading, ErrorMessage, NotFound
                    ├── layout/     Header, Footer, Layout
                    ├── home/       HomePage, TheoremCard
                    ├── patches/    PatchCard, PatchList, PatchView,
                    │               PatchScene, CellMesh, BondConnector,
                    │               BoundaryWireframe, BoundaryShell,
                    │               DynamicsView, RegionInspector,
                    │               CurvaturePanel, HalfBoundPanel,
                    │               DistributionChart, ColorControls
                    ├── tower/      TowerView, TowerTimeline, TowerLevel,
                    │               TowerAnimation
                    └── theorems/   TheoremDashboard, TheoremRow
```

---

## 3. Technology Stack

| Layer | Package | Version | Purpose |
|-------|---------|---------|---------|
| **UI Framework** | React | 18.3 | Component tree, hooks, concurrent rendering |
| **Routing** | React Router | 6.28 | Client-side SPA routing (5 pages + 404) |
| **3D Rendering** | Three.js | 0.170 | WebGL scene graph, materials, geometries |
| **R3F** | @react-three/fiber | 8.17 | React reconciler for Three.js |
| **Drei** | @react-three/drei | 9.114 | OrbitControls, scene helpers |
| **Charts** | Recharts | 2.13 | Min-cut + S/area histograms |
| **Layout (fallback)** | d3-force-3d | 3.0 | Barnes-Hut force simulation (O(n log n)) |
| **Styling** | Tailwind CSS | 3.4 | Utility-first CSS framework |
| **Build** | Vite | 6.4 | Dev server + production bundler |
| **Language** | TypeScript | 5.6 | Static type checking (`strict: true`) |
| **Testing** | Vitest | 1.6 | Test runner (Vite-native) |
| **Testing** | @testing-library/react | 14.3 | Component + hook test utilities |
| **Linting** | ESLint | 9.14 | Code quality (`@typescript-eslint/strict`) |
| **CSS Processing** | PostCSS + Autoprefixer | 8.4 / 10.4 | Tailwind compilation + vendor prefixing |

### TypeScript Strictness

The project uses maximum TypeScript strictness (`tsconfig.json`):

- `strict: true` — enables all strict-family flags
- `noUncheckedIndexedAccess: true` — array access returns `T | undefined`
- `noUnusedLocals: true` / `noUnusedParameters: true`
- `@typescript-eslint/no-explicit-any: "error"` — no `any` types anywhere

---

## 4. API Integration

### 4.1 Client Module

All API access is centralized in `src/api/client.ts`, which provides one typed async function per backend endpoint:

| Function | Endpoint | Return Type | Consumer |
|----------|----------|-------------|----------|
| `fetchPatches` | `GET /patches` | `PatchSummary[]` | `usePatches` |
| `fetchPatch` | `GET /patches/:name` | `Patch` | `usePatch` |
| `fetchTower` | `GET /tower` | `TowerLevel[]` | `useTower` |
| `fetchTheorems` | `GET /theorems` | `Theorem[]` | `useTheorems` |
| `fetchCurvature` | `GET /curvature` | `CurvatureSummary[]` | (reserved) |
| `fetchMeta` | `GET /meta` | `Meta` | `useMeta` |
| `fetchHealth` | `GET /health` | `Health` | (monitoring) |

The base URL is read from `import.meta.env.VITE_API_URL` at build time, defaulting to `http://localhost:8080`.

**Error handling:** Non-2xx responses throw `ApiError` (a custom `Error` subclass carrying `status` and `statusText`). Network failures propagate as `TypeError`. Aborted requests throw `DOMException` with `name === "AbortError"`.

**Abort signals:** Every function accepts an optional `AbortSignal` parameter, forwarded to the underlying `fetch()`. Hooks use `AbortController` to cancel in-flight requests on component unmount or dependency change.

### 4.2 Custom Hooks

Each hook follows a uniform pattern:

```typescript
interface UseXResult {
  data: T | null;       // null while loading or on error
  loading: boolean;     // true during fetch
  error: string | null; // human-readable error, or null on success
  refetch: () => void;  // re-trigger the fetch (wired to ErrorMessage retry)
}
```

| Hook | Dependency | Re-fetches When |
|------|-----------|-----------------|
| `usePatch(name)` | `name` | `name` changes, `refetch()` called |
| `usePatches()` | — | `refetch()` called |
| `useTower()` | — | `refetch()` called |
| `useTheorems()` | — | `refetch()` called |
| `useMeta()` | — | `refetch()` called |

The `refetch` mechanism uses a `useState<number>` counter in the effect dependency array. Incrementing the counter triggers the effect to re-run, aborting any in-flight request from the previous iteration.

**AbortError handling:** When the effect cleanup fires (unmount or dependency change), the `AbortController` is aborted. The hook's catch block checks `err instanceof DOMException && err.name === "AbortError"` and silently returns — this is not a user-visible error. The `finally` block guards `setLoading(false)` behind `!controller.signal.aborted` to prevent state updates on unmounted components.

---

## 5. Application Routes

| Path | Component | Data Source | Description |
|------|-----------|-------------|-------------|
| `/` | `HomePage` | `useMeta`, `useTheorems` | Project overview + theorem status grid |
| `/patches` | `PatchList` | `usePatches` | Browsable card grid with sort + filter |
| `/patches/:name` | `PatchView` | `usePatch(name)` | Interactive 3D patch viewer + panels |
| `/tower` | `TowerView` | `useTower` | Resolution tower timeline |
| `/theorems` | `TheoremDashboard` | `useTheorems` | Expandable accordion of all 10 theorems |
| `*` | `NotFound` | — | 404 catch-all |

All routes are nested under the `Layout` component (persistent Header + `<Outlet />` + Footer). The `BrowserRouter` wraps `App` in `main.tsx` — separated from `App.tsx` to allow `MemoryRouter` injection in tests.

---

## 6. Component Hierarchy

### 6.1 Layout Shell

```
<Layout>
  <Header />          — Persistent nav (Home, Patches, Tower, Theorems)
  <main>
    <Outlet />         — Matched route content
  </main>
  <Footer />           — Version, Agda version, data hash (from useMeta)
</Layout>
```

### 6.2 Patch Viewer (`/patches/:name`)

The heaviest page. Three-panel layout:

```
Desktop (lg+):
┌──────────────────────────────────┬──────────────────────┐
│                                  │  RegionInspector     │
│         PatchScene (Canvas)      │  CurvaturePanel      │
│         ├── CellMesh × N         │  HalfBoundPanel      │
│         ├── BondConnector × M    │  DistributionChart   │
│         ├── BoundaryWireframe    │                      │
│         └── BoundaryShell        │                      │
├──────────────────────────────────┤                      │
│  ColorControls                   │                      │
└──────────────────────────────────┴──────────────────────┘

Mobile (<lg): vertical stack
```

**State management:** All visualization state (color mode, selected region, show bonds, show boundary wireframe, show boundary shell) is local `useState` in `PatchView`, passed down as props. No global state, no context, no Redux.

### 6.3 Tower Timeline (`/tower`)

```
<TowerView>
  <TowerTimeline levels={data}>
    <SubTowerSection>      — One per sub-tower (Dense, Layer-54)
      <TowerLevel />       — Card for each resolution level
      <MonotonicityArrow /> — (k, refl) witness between levels
    </SubTowerSection>
  </TowerTimeline>

  <TowerAnimation levels={data} />
  ↳ Optional animated playback of sequential tower levels with
    proper-time counter (τ = 0, 1, …) and 3D viewport per slice.
</TowerView>
```

Sub-towers are identified by `tlMonotone === null` boundaries in the tower data. Hovering/focusing an arrow highlights its two adjacent level cards.

### 6.4 Theorem Dashboard (`/theorems`)

```
<TheoremDashboard>
  <TheoremRow />  × 10    — Expandable accordion rows
</TheoremDashboard>
```

Supports `highlightTheorem` navigation state from `HomePage`'s `TheoremCard` links: the matching row starts expanded via `defaultExpanded={true}`.

### 6.5 Dynamics View (`DynamicsView`)

A self-contained star-patch demonstration of Theorem 9 (step invariance). Animates bond-weight perturbations via an 8-step predefined sequence, showing that `S = L` on all 10 star regions is preserved at every step. Rendered as a 2D SVG diagram (not Three.js) — cells, bonds, and weights are shown as circles, lines, and labels. Playback controls mirror those of `TowerAnimation`.

---

## 7. 3D Visualization Pipeline

### 7.1 Scene Structure

`PatchScene` renders inside a React Three Fiber `<Canvas>`:

```
<Canvas>
  <ambientLight intensity={0.5} />
  <directionalLight position={[10, 10, 10]} intensity={1} />
  <OrbitControls enableDamping dampingFactor={0.1} />

  {/* Cells: individual meshes OR InstancedMesh (≤ or > 500 cells) */}
  <group name="cells">
    <group position scale quaternion>    (per-cell transform wrapper)
      <CellMesh /> × N                    (≤500 total cells)
    </group>
    — OR —
    <instancedMesh />                     (>500 total cells)
    <SelectionOverlay />                  (max 5 emissive meshes, instanced path only)
  </group>

  {/* Bond connectors — ALL physical bonds from pgEdges (toggle-able) */}
  <group name="bonds">
    <BondConnector /> × M
  </group>

  {/* Boundary wireframe — 1 merged draw call (toggle-able) */}
  <BoundaryWireframe />

  {/* Boundary shell — semi-transparent sphere at origin (toggle-able) */}
  <BoundaryShell />
</Canvas>
```

**All cells are rendered** — not just boundary cells. Interior cells (cells with all faces shared, appearing in no region) are rendered in neutral gray at reduced opacity as structural context for the bulk. Boundary cells receive data-driven colors from the active color mode.

### 7.2 Cell Geometry

| Tiling | Shape | Three.js Geometry | Notes |
|--------|-------|-------------------|-------|
| `{4,3,5}` | Cube | `BoxGeometry(1, 1, 1)` | 3D patches |
| `{5,4}` | Pentagon | `ExtrudeGeometry(pentagonShape, depth=0.1)` | 2D hyperbolic |
| `{5,3}` | Pentagon | Same as `{5,4}` | 2D spherical |
| `{4,4}` | Square | `PlaneGeometry(1, 1)` | 2D Euclidean |
| `Tree` | Sphere | `SphereGeometry(0.3, 16, 12)` | 1D graph nodes |

Geometries are cached at the module level in `utils/tiling.ts` — at most 5 instances exist (one per tiling variant). The cache persists for the page lifetime.

### 7.3 Cell Materials

| Property | Boundary (unselected) | Boundary (selected) | Interior |
|----------|----------------------|---------------------|----------|
| Color | Data-driven (color mode) | Data-driven | Neutral gray `#6b7280` |
| Metalness | 0.1 | 0.1 | 0.05 |
| Roughness | 0.7 | 0.7 | 0.85 |
| Opacity | 0.85 | 1.0 | 0.45 |
| Emissive | Black (none) | Orange `#ffaa00` | Black (none) |
| Emissive Intensity | 0 | 0.5 | 0 |
| `depthWrite` | `false` | `false` | `false` |

**`depthWrite: false` (critical).** All cell materials disable depth-buffer writes. This is necessary because bond endpoints (fixed at cell centres) frequently fall inside a cell's visual volume after the Lorentz-boost centring and per-cell conformal scaling pack cells tight near the centre of the Poincaré ball/disk. Without `depthWrite: false`, translucent cells would occlude the bonds passing through them. The same flag is set on the `InstancedMesh` material for consistency across the two rendering paths.

### 7.4 Bond Connectors

All physical bonds from `patchGraph.pgEdges` (not inferred from regions) are rendered as translucent gray cylinders connecting adjacent cell centres:

- Color: `#888888`, opacity 0.3
- Radius: `0.1` world units (shared unit-height `CylinderGeometry`, scaled per-bond along local Y to the bond length)
- 8 radial segments
- Positioned at the midpoint, rotated via quaternion from the Y-axis to the bond direction
- `depthWrite: false` for correct transparency blending

A single module-level `CylinderGeometry` is shared across all bond instances — `N` bonds produce 1 geometry object, not `N`.

### 7.5 Boundary Wireframe

All boundary cells' edge outlines merged into a **single `<lineSegments>` draw call**:

1. Get the template `EdgesGeometry` for the tiling type (cached)
2. For each boundary cell, multiply the template vertices by the cell's conformal scale factor, then offset by the cell's Poincaré-projected position
3. Concatenate into one `Float32Array` → one `BufferGeometry`
4. Render with `lineBasicMaterial` (color: `#93c5fd`, opacity: 0.6)

Boundary cells are those that appear in at least one region's `regionCells` array (i.e. have at least one exposed face/leg). Interior cells are excluded. The per-cell scale matches the corresponding `CellMesh` / `InstancedMesh` so the wireframe outlines track the cells' actual on-screen size — including the conformal shrinking near the Poincaré boundary.

Exactly 1 draw call regardless of cell count — critical for layer-54-d7 (1885 boundary cells) and dense-1000 (833+ boundary cells).

### 7.6 Boundary Shell

A semi-transparent spherical shell enclosing all boundary cells, visualising the holographic boundary surface — the 2D surface that encodes the 3D bulk. Rendered by `BoundaryShell.tsx`:

- **Geometry:** `SphereGeometry` centred at the scene origin `(0, 0, 0)` (i.e. the Lorentz-boosted position of the fundamental cell `g = I`), with radius equal to the maximum distance of any boundary cell from the origin plus a small padding (`SHELL_PADDING = 0.6`).
- **Colour / opacity:** `#93c5fd` at opacity `0.12` — barely perceptible, a ghostly membrane enclosing the bulk graph.
- **Material:** `DoubleSide` (visible from inside and outside), `depthWrite: false` (does not occlude interior cells / bonds / wireframe), fully diffuse (`metalness: 0`, `roughness: 1`).

**Centring invariant.** The shell is anchored at the scene origin — not at the boundary-cell centroid. This is the physically correct reference because, after the Python exporter's Lorentz-boost centring, the fundamental cell projects to the origin of the Poincaré ball. Centering the shell at the origin guarantees that for symmetric patches (e.g. {5,4} layer BFS) the shell wraps the patch symmetrically, and for asymmetric patches (Dense-growth, layer-54-dX) the shell still visually encloses the entire structure instead of drifting off-centre.

The shell is disabled (renders `null`) for patches with fewer than 3 boundary cells or when all boundary cells sit numerically at the origin.

---

## 8. Color Scales

Four visualization modes, selectable via `ColorControls`:

| Mode | Scale | Domain | Midpoint | Use |
|------|-------|--------|----------|-----|
| **Min-Cut** (default) | Viridis (sequential) | `[1, maxCut]` | — | Higher S = warmer |
| **Region Size** | Green→Purple (sequential) | `[1, maxSize]` | — | Larger = darker purple |
| **S/area Ratio** | Blue→White→Red (diverging) | `[0, 0.5]` | 0.25 (white) | 0.5 = BH bound (red) |
| **Curvature** | Blue→White→Red (diverging) | `[−|max|, +|max|]` | 0 (white) | Negative=blue, Positive=red |

All color functions return CSS hex strings (`#rrggbb`) accepted by Three.js and CSS. The Viridis palette uses 16 evenly-spaced control points from the canonical matplotlib colormap, linearly interpolated.

**Colorblind safety:** Viridis is the default because it is perceptually uniform (equal data steps → equal visual steps), safe for deuteranopia and protanopia, and readable in grayscale.

**Curvature mode — per-region curvature:** The `regionCurvature` field (computed by `18_export_json.py` as a per-cell aggregation of adjacent vertex/edge curvature) is used directly. For patches without curvature data (tree, star, layer-54), all cells fall back to κ=0, rendering as white.

**Interior cell colouring:** Interior cells (not in any region) receive a fixed neutral gray (`#6b7280`) independent of the active color mode. This provides a clear visual hierarchy: boundary cells are the data-bearing foreground, interior cells are the structural background.

---

## 9. Layout Algorithm

### 9.1 Primary Path — Poincaré Projection Read-Through

Cell positions, rotation quaternions, and per-cell conformal scales are **pre-computed by the Python oracle** (`18_export_json.py`, see [`oracle-pipeline.md`](oracle-pipeline.md) §4.3) and served by the backend in `patchGraph.pgNodes`. The frontend reads these directly; no force simulation is required in the common case.

For each cell, the oracle emits:

| Field | Meaning |
|-------|---------|
| `x, y, z` | Poincaré ball (3D) or disk-with-`z=0` (2D) coordinates |
| `qx, qy, qz, qw` | Unit quaternion encoding the cell's rotation relative to the fundamental cell |
| `scale` | Conformal factor `s(u) = (1 − |u|²) / 2`, clamped at `1e-6` |

Three roadmap-level corrections live inside the exporter and are **reflected unchanged** by the frontend:

1. **Centring (Lorentz boost).** The fundamental cell `g = I` is mapped to the hyperboloid apex so it projects to the origin `(0, 0, 0)` of the Poincaré ball. The frontend's `OrbitControls` therefore orbit the correct point without any additional translation.
2. **Per-cell conformal scale.** `s(u) = (1 − |u|²) / 2` gives cells near the centre `scale ≈ 0.5` and cells near the boundary `scale → 0` — the canonical Escher "Circle Limit" shrinking.
3. **Per-cell rotation quaternion.** Extracted from the spatial block of each cell's boosted Lorentz matrix via SVD + Shepperd–Shuster. Aligns cells with the hyperbolic geodesics of the tiling; omitting it causes visible "squishing" on asymmetric patches (layer-54-dX, dense-growth patches).

`computePatchLayout` in `utils/layout.ts` returns `Map<number, NodeTransform>` where:

```typescript
interface NodeTransform {
  pos: [number, number, number];                   // scene-space position
  scale: number;                                    // conformal factor
  quat: [number, number, number, number];           // (qx, qy, qz, qw)
}
```

**Global scene scale.** The read-through applies a scene-wide magnification to the raw Poincaré coordinates:

```
sceneScale = max(5, √(cellCount) × 2)
```

This preserves the relative geometry (origin stays at the origin, boundary stays near `|u| = 1`, conformal compression stays intact) and only picks a viewport-appropriate overall size. The earlier `targetExtent / maxRaw` formula (which stretched the outermost cell to a fixed extent) is **not** used — it would destroy the conformal structure and erase the Escher shrinking.

Hand-written 2D layouts (tree, star, filled, desitter) follow the same schema: the Python helper `_make_patch_graph` synthesises the identity quaternion `(0, 0, 0, 1)` and derives `scale` from `(x, y, z)` via the same `s(u)` formula, so the frontend never has to branch on the source of the coordinates.

### 9.2 Fallback Path — Force-Directed Simulation

When the exported `pgNodes` contain all-zero coordinates (i.e. no geometric data was produced by the pipeline), `computePatchLayout` falls back to a force-directed layout using `d3-force-3d`:

| Parameter | Value |
|-----------|-------|
| Link (spring) distance | 2 |
| Link strength | 1 |
| Charge (repulsion) strength | −30 |
| Iterations | 300 (synchronous, blocking) |
| Charge algorithm | Barnes-Hut octree (O(n log n)) |

On the fallback path every `NodeTransform` receives the identity quaternion `(0, 0, 0, 1)` and `scale = 1.0` — the simulation produces Euclidean positions with no hyperbolic structure, so there is no meaningful conformal factor or rotation to assign. The last-resort fallback (used only if `d3-force-3d` itself fails at runtime) is a uniform circular distribution (2D) or a Fibonacci sphere (3D).

### 9.3 Caching

The **fallback layout** caches computed positions in `sessionStorage` keyed by patch name and node count (`ugrav-layout-v5-{patchName}-{nodeCount}`). The cache stores the full `NodeTransform` objects (position + scale + quaternion) so future additions of non-trivial fallback rotations/scales do not require another schema bump. On subsequent visits, cached transforms are loaded directly without re-running the simulation.

The **primary path** does not cache — the Poincaré read-through is essentially free (it's a `Map` build over `patchGraph.pgNodes`), and sessionStorage would only defer the work, not eliminate it.

---

## 10. Performance

### 10.1 InstancedMesh Threshold

| Total Cells | Strategy | Draw Calls (cells) |
|---------------|----------|--------------------|
| ≤ 500 | Individual `<CellMesh>` wrapped in scaled + rotated `<group>` | N |
| > 500 | Single `<instancedMesh>` + selection overlay | 1 + max 5 |

The threshold is evaluated by `shouldUseInstancing(cellCount)` in `utils/tiling.ts` against the **total cell count** (boundary + interior), not just boundary cells. For the instanced path:

- **Per-instance transforms** are set via `Object3D` matrix computation in a `useEffect`:
  ```ts
  dummy.position.set(...transform.pos);
  dummy.quaternion.set(...transform.quat);
  dummy.scale.setScalar(transform.scale);
  dummy.updateMatrix();
  mesh.setMatrixAt(i, dummy.matrix);
  ```
  Position **and** rotation **and** conformal scale are all baked into the instance matrix — no per-instance prop plumbing needed.
- Per-instance colors are set via `setColorAt()` in a `useEffect`. Interior cells receive the neutral gray; selected cells receive the orange selection color.
- `InstancedMesh` cannot support per-instance emissive glow with the standard material, so up to 5 individual `CellMesh` components are rendered as a **`SelectionOverlay`** — each wrapped in a `<group>` carrying the cell's position, scale, and quaternion so the glow tracks the cell's conformal size and hyperbolic orientation.

Cursor cleanup: when the `InstancedMesh` is removed from the scene while the pointer is hovering over it, `onPointerOut` never fires. A `useEffect` cleanup resets `document.body.style.cursor` to `"auto"` on unmount.

### 10.2 Geometry Caching

- Cell geometries: cached at the module level in `utils/tiling.ts` (at most 5 instances, one per tiling variant).
- Bond geometry: a single shared unit-height `CylinderGeometry` (module-level constant in `BondConnector.tsx`) used by every bond via mesh `scale={[1, length, 1]}`. `N` bonds → 1 geometry.
- Wireframe template: `EdgesGeometry` cached per tiling type in `BoundaryWireframe.tsx`. The merged per-patch `BufferGeometry` is recomputed only when the cells list or tiling changes.
- Shell geometry: a fresh `SphereGeometry` is created per patch (patch navigation triggers recomputation) and disposed on change/unmount.

### 10.3 Merged Wireframe

`BoundaryWireframe` produces exactly 1 draw call by merging all boundary cells' scaled edge segments into a single `BufferGeometry`. For dense-1000 (833+ boundary cells), this prevents 833+ separate draw calls. For layer-54-d7 (1885 boundary cells), 1 instead of 1885.

### 10.4 Progressive Loading

- `GET /patches` returns lightweight `PatchSummary[]` (no region data, no graph)
- Full patch data (up to ~3.5 MB for dense-1000) is fetched only when the user navigates to `/patches/:name`
- Fallback layout positions are cached in `sessionStorage`

---

## 11. Responsive Design

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | < 768px | Single column, 50vh viewport, vertical panels |
| Tablet | 768–1279px | 2-column patch grid, side-by-side panels |
| Desktop | ≥ 1280px | 3-column patch grid, viewport + side panel |

The Patch Viewer (`PatchView`) adapts:
- **Desktop (lg+):** Side-by-side layout (viewport left, panels right at 320–352px)
- **Mobile (<lg):** Stacked layout (viewport → controls → panels)

The Tower Timeline adapts:
- **Desktop (md+):** Horizontal timeline with rightward arrows
- **Mobile (<md):** Vertical timeline with downward arrows

---

## 12. Accessibility

| Feature | Implementation |
|---------|---------------|
| **ARIA roles** | `role="img"` on Canvas wrapper, `role="list"`/`role="listitem"` on card grids and tower |
| **ARIA labels** | Descriptive labels on all interactive elements (`aria-label`, `aria-expanded`, `aria-controls`). The PatchScene wrapper's `aria-label` reports cell count (with boundary/interior breakdown), physical bond count, max min-cut, tiling, and selection status. |
| **Keyboard navigation** | All links, buttons, and toggles focusable via Tab; tower arrows focusable with `tabIndex={0}` |
| **Focus rings** | Viridis-600 outline via `:focus-visible` (no rings on mouse click) |
| **Screen readers** | Loading spinner uses `role="status"`; errors use `role="alert"` |
| **Reduced motion** | `prefers-reduced-motion` disables CSS animations (Tailwind `motion-reduce:` variant), chart animations, TowerAnimation auto-play, and DynamicsView auto-play |
| **Color contrast** | Viridis default (perceptually uniform); academic muted palette |
| **Semantic HTML** | `<header>`, `<main>`, `<footer>`, `<nav>`, `<section>`, `<article>` throughout |

**Cursor cleanup:** Both `CellMesh` and `InstancedCells` components reset `document.body.style.cursor` to `"auto"` on unmount via `useEffect` cleanup. This prevents the cursor from getting stuck on `"pointer"` when the component is removed while the pointer is hovering over it.

---

## 13. Testing Strategy

### 13.1 Test Suites

| Suite | File | What It Tests | Environment |
|-------|------|---------------|-------------|
| API client | `tests/api.test.ts` | URL construction, error handling, abort signals | `vi.fn()` mock fetch |
| Type guards | `tests/types.test.ts` | 13 type guards (incl. `isGraphNode`, `isEdge`, `isPatchGraph`) against realistic + invalid data | Pure functions |
| Color scales | `tests/utils/colors.test.ts` | Viridis endpoints, diverging midpoints, edge cases | Pure functions |
| `usePatch` hook | `tests/hooks/usePatch.test.ts` | Loading→success, 404, abort, name change, refetch | `renderHook` + `vi.mock` |
| PatchCard | `tests/components/PatchCard.test.tsx` | Tiling symbols, orbit formatting, links | `MemoryRouter` |
| PatchScene | `tests/components/PatchScene.test.tsx` | Smoke tests: all tilings, all color modes, selection, `showBonds`/`showBoundary`/`showShell` toggles, boundary/interior breakdown, bond count in ARIA label | Mocked R3F Canvas |
| TheoremCard | `tests/components/TheoremCard.test.tsx` | Status badges, ARIA labels, all 10 theorems | `MemoryRouter` |

### 13.2 Mocking Approach

- **API client tests:** Mock `fetch` globally via `vi.fn()`. No network requests.
- **Hook tests:** `vi.mock("../../src/api/client")` replaces the API module. The `ApiError` class is replicated in the mock factory so `instanceof` checks work. Mock fixtures include the full `patchGraph` (as `GraphNode[]` and `Edge[]` objects) to match the real wire schema.
- **Component tests:** `@testing-library/react` with `MemoryRouter` for routing context.
- **PatchScene tests:** Mock `@react-three/fiber` Canvas and `@react-three/drei` OrbitControls since jsdom has no WebGL context. The Canvas mock renders a `<div>` (without reconciling R3F-specific children) instead of a WebGL canvas. All component logic (layout read-through, colors, adjacency, selection, ARIA labels, `showShell` toggle) still executes fully; only actual GPU rendering is bypassed.

### 13.3 Test Commands

```bash
cd frontend
npm run test      # Run all Vitest tests
npm run lint      # ESLint with TypeScript strict rules
npm run build     # tsc -b (type-check) + vite build
```

---

## 14. Build & Configuration

### 14.1 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VITE_API_URL` | `http://localhost:8080` | Backend API base URL (no trailing slash) |

Set in `.env` or `.env.local`. Vite statically replaces `import.meta.env.VITE_API_URL` during bundling.

### 14.2 Build Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start Vite dev server with HMR (`localhost:5173`) |
| `npm run build` | Type-check (`tsc -b`) + production build → `dist/` |
| `npm run preview` | Serve the production build locally |
| `npm run test` | Run all Vitest tests |
| `npm run lint` | ESLint with TypeScript strict rules |

### 14.3 Production Deployment

`npm run build` produces static files in `dist/` suitable for any static file server. The SPA requires a fallback to `index.html` for all routes:

```nginx
# nginx example
location / {
    try_files $uri $uri/ /index.html;
}
```

### 14.4 Browser Requirements

- **WebGL 2** support (required for Three.js)
- **ES2022** support (target in `tsconfig.json`)
- Chrome 94+, Firefox 93+, Safari 15+, Edge 94+

---

## 15. Design Principles

| Principle | Implementation |
|-----------|----------------|
| **Academic credibility** | Serif headings (Georgia), monospace for Agda/module references, muted Viridis palette, clean whitespace — the audience is researchers |
| **Progressive disclosure** | Listing shows `PatchSummary` (no region data); full patch loads on navigation; accordion rows expand on click |
| **Colorblind safety** | Viridis default (perceptually uniform, deuteranopia-safe); blue→white→red diverging for curvature/ratio |
| **Keyboard navigation** | All interactive elements focusable; ARIA labels throughout; focus rings on keyboard only |
| **Reduced motion** | `prefers-reduced-motion` disables animations, auto-rotation, and auto-play in TowerAnimation / DynamicsView |
| **No `any` types** | `@typescript-eslint/no-explicit-any: "error"` + `strict: true` + `noUncheckedIndexedAccess` |
| **Named exports** | All components and hooks use named exports (not default exports) |
| **Utility-first CSS** | Tailwind classes in JSX; no CSS-in-JS; `style={}` only for data-driven Three.js values |
| **Geometric correctness** | Cell positions, rotations, and conformal scales come from the Agda-aligned Python oracle; the frontend never invents geometry for Coxeter patches, only reads it. |

---

## 16. TypeScript Types

All TypeScript interfaces in `src/types/index.ts` mirror the Haskell backend's `Types.hs` and the JSON schema produced by `18_export_json.py`. Field names match the exact JSON keys from the API — they are not renamed.

**Prefix conventions (matching Haskell Aeson derivation):**

| Haskell Type | Haskell Field Prefix | JSON Key Prefix | TypeScript Field |
|-------------|---------------------|-----------------|-----------------|
| `Patch` | `patch` | `patch` | `patchName`, `patchTiling`, `patchGraph`, … |
| `PatchSummary` | `ps` | `ps` | `psName`, `psTiling`, … |
| `Region` | `region` | `region` | `regionId`, `regionMinCut`, … |
| `GraphNode` | `gn` (stripped) | (none) | `id`, `x`, `y`, `z`, `qx`, `qy`, `qz`, `qw`, `scale` |
| `Edge` | `edge` (stripped) | (none) | `source`, `target` |
| `PatchGraph` | `pg` | `pg` | `pgNodes`, `pgEdges` |
| `TowerLevel` | `tl` | `tl` | `tlPatchName`, `tlMaxCut`, … |
| `Theorem` | `thm` | `thm` | `thmNumber`, `thmName`, … |
| `CurvatureSummary` | `cs` (stripped) | (none) | `patchName`, `tiling`, … |
| `Meta` | `meta` (stripped) | (none) | `version`, `buildDate`, … |

**`GraphNode`:**

```typescript
interface GraphNode {
  id: number;        // cell / tile identifier (also appears in pgEdges)
  x: number;         // Poincaré ball/disk x
  y: number;         // Poincaré ball/disk y
  z: number;         // Poincaré ball z (0 for 2D patches)
  qx: number;        // rotation quaternion — x
  qy: number;        // rotation quaternion — y
  qz: number;        // rotation quaternion — z
  qw: number;        // rotation quaternion — w (real part)
  scale: number;     // conformal factor s(u) = (1 − |u|²) / 2, clamped at 1e-6
}
```

**`Edge`:**

```typescript
interface Edge {
  source: number;    // lower-indexed endpoint (exporter guarantees source ≤ target)
  target: number;
}
```

**Type guards.** 13 type guards are provided for runtime validation: `isTiling`, `isGrowthStrategy`, `isTheoremStatus`, `isRegion`, `isGraphNode`, `isEdge`, `isPatchGraph`, `isPatchSummary`, `isPatch`, `isTowerLevel`, `isTheorem`, `isMeta`, `isHealth`, `isCurvatureSummary`.

---

## 17. Relationship to the Agda Formalization

The frontend displays data that has been **verified** by the Agda type-checker but contains no proof content. The relationship:

| What the frontend displays | What Agda verified |
|---------------------------|-------------------|
| Cell colors by `regionMinCut` | `Bridge/GenericBridge.agda`: S = L (Theorem 1) |
| S/area ratio bar + half-slack | `Bridge/HalfBound.agda`: 2·S ≤ area (Theorem 3) |
| Curvature panel classes + Gauss–Bonnet badge | `Bulk/GaussBonnet.agda`: Σκ = χ (Theorem 2) |
| Tower monotonicity arrows `(k, refl)` | `Bridge/SchematicTower.agda` |
| Theorem status badges (Verified ✓) | Each theorem's Agda module type-checks |
| Orbit classification sidebar | `OrbitReducedPatch.classify` |
| `patchHalfBoundVerified` badge | `Boundary/*HalfBound.agda`: abstract `(k, refl)` |
| DynamicsView 8-step perturbation | `Bridge/StarStepInvariance.agda` + `Bridge/StarDynamicsLoop.agda` (Theorem 9) |
| TowerAnimation proper-time counter | `Causal/CausalDiamond.agda` |
| Poincaré cell positions / quaternions / scales | **Not Agda-verified** — geometric visualisation data produced by `18_export_json.py` (Lorentz boost + SVD + conformal formula) and runtime-checked by the Haskell backend's `validateGraphGeometry` invariants |

The frontend adds **no mathematical content** — it is a visualization layer that renders pre-computed, pre-verified (or, for geometry, runtime-checked) data in a form that is explorable by researchers.

---

## 18. Cross-References

| Topic | Document |
|-------|----------|
| Backend API (data source) | [`engineering/backend-spec-haskell.md`](backend-spec-haskell.md) |
| Oracle pipeline (data production) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Orbit reduction (717 → 8 orbits) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| Scaling report (region counts, timings) | [`engineering/scaling-report.md`](scaling-report.md) |
| Generic bridge (Theorem 1) | [`formal/11-generic-bridge.md`](../formal/11-generic-bridge.md) |
| Bekenstein–Hawking half-bound (Theorem 3) | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Gauss–Bonnet (Theorem 2) | [`formal/04-discrete-geometry.md`](../formal/04-discrete-geometry.md) |
| Canonical theorem registry | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Repository overview | [`docs/README.md`](../README.md) |
| Backend README | [`backend/README.md`](../../backend/README.md) |
| Frontend README | [`frontend/README.md`](../../frontend/README.md) |
| Per-instance data sheets | [`instances/`](../instances/) |