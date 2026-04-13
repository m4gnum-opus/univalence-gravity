# WebGL Frontend Specification

**Architecture, view design, data flow, and implementation plan for the Three.js + TypeScript visualization layer.**

**Audience:** Developers building the frontend; AI assistants generating TypeScript/React code; reviewers evaluating the UX architecture.

**Prerequisites:** Familiarity with the backend specification ([`engineering/backend-spec-haskell.md`](backend-spec-haskell.md)), the theorem registry ([`formal/01-theorems.md`](../formal/01-theorems.md)), and the repository architecture ([`getting-started/architecture.md`](../getting-started/architecture.md)).

---

## 1. Architectural Position

The frontend is a **static single-page application** (SPA) built with TypeScript, React, and Three.js. It consumes the JSON REST API served by the Haskell backend ([`backend-spec-haskell.md`](backend-spec-haskell.md)) and renders interactive 3D visualizations of the verified holographic patches, resolution towers, curvature data, and theorem dashboard.

```
┌────────────────────────────────┐
│  Haskell Backend               │
│  REST API (JSON)               │
│  localhost:8080                 │
└──────────┬─────────────────────┘
           │  fetch() / REST
           ▼
┌────────────────────────────────┐
│  TypeScript Frontend           │
│  React + Three.js              │
│  Vite build → static assets   │
│  localhost:5173 (dev)          │
└────────────────────────────────┘
```

The frontend provides **no computation** — all data is pre-computed by the Python oracle, verified by Agda, and served by the Haskell backend. The frontend's role is purely **visualization and navigation**.

---

## 2. Technology Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Language | TypeScript 5.x | Type safety, IDE support, ecosystem |
| UI Framework | React 18+ | Component model, hooks, ecosystem |
| 3D Engine | Three.js r160+ | Standard WebGL library, wide support |
| React-Three bridge | @react-three/fiber 8+ | Declarative Three.js in React |
| Controls | @react-three/drei | OrbitControls, Html overlays, helpers |
| Build system | Vite 5+ | Fast HMR, TypeScript-native, ES modules |
| Styling | Tailwind CSS 3+ | Utility-first, rapid prototyping |
| Charts (2D) | Recharts or D3.js | Tower timeline, distribution charts |
| State management | React Context + fetch | No Redux needed — data is read-only |
| Testing | Vitest + React Testing Library | Unit tests for components |
| Deployment | Static hosting (Netlify/Vercel/nginx) | No server-side rendering needed |

---

## 3. Data Flow

All data originates from the Haskell backend's REST API. The frontend fetches JSON on mount and caches it in React state.

```
User navigates to /patches/dense-100
  │
  ├──▶ React Router renders <PatchView name="dense-100" />
  │
  ├──▶ useEffect → fetch("http://localhost:8080/patches/dense-100")
  │
  ├──▶ JSON response parsed into TypeScript Patch type
  │
  ├──▶ Three.js scene populated with cell geometry
  │    ├── Cells colored by min-cut value (orbit classification)
  │    ├── Bonds rendered as translucent connectors
  │    └── Boundary faces highlighted
  │
  └──▶ Side panel shows region table, curvature data, half-bound stats
```

### 3.1 API Client

A typed API client wraps all backend endpoints:

```typescript
// src/api/client.ts

const BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:8080";

export async function fetchPatches(): Promise<PatchSummary[]> {
  const res = await fetch(`${BASE_URL}/patches`);
  return res.json();
}

export async function fetchPatch(name: string): Promise<Patch> {
  const res = await fetch(`${BASE_URL}/patches/${name}`);
  if (!res.ok) throw new Error(`Patch not found: ${name}`);
  return res.json();
}

export async function fetchTower(): Promise<TowerLevel[]> {
  const res = await fetch(`${BASE_URL}/tower`);
  return res.json();
}

export async function fetchTheorems(): Promise<Theorem[]> {
  const res = await fetch(`${BASE_URL}/theorems`);
  return res.json();
}

export async function fetchMeta(): Promise<Meta> {
  const res = await fetch(`${BASE_URL}/meta`);
  return res.json();
}
```

### 3.2 TypeScript Types

Mirror the Haskell domain types from `backend-spec-haskell.md` §3:

```typescript
// src/types/index.ts

export type Tiling = "Tiling54" | "Tiling435" | "Tiling53" | "Tiling44";

export type GrowthStrategy = "BFS" | "Dense" | "Geodesic" | "Hemisphere";

export interface PatchSummary {
  psName: string;
  psTiling: Tiling;
  psDimension: number;
  psCells: number;
  psRegions: number;
  psOrbits: number;
  psMaxCut: number;
  psStrategy: GrowthStrategy;
}

export interface Region {
  regionId: number;
  regionCells: number[];
  regionSize: number;
  regionMinCut: number;
  regionArea: number;
  regionOrbit: string;
  regionHalfSlack: number | null;
  regionRatio: number;
}

export interface CurvatureClass {
  ccName: string;
  ccCount: number;
  ccValence: number;
  ccKappa: number;
  ccLocation: string;
}

export interface CurvatureData {
  curvClasses: CurvatureClass[];
  curvTotalTenths: number;
  curvEulerTenths: number;
  curvGaussBonnet: boolean;
}

export interface HalfBoundData {
  hbRegionCount: number;
  hbViolations: number;
  hbAchieverCount: number;
  hbAchieverSizes: [number, number][];
  hbSlackRange: [number, number];
  hbMeanSlack: number;
}

export interface Patch {
  patchName: string;
  patchTiling: Tiling;
  patchDimension: number;
  patchCells: number;
  patchRegions: number;
  patchOrbits: number;
  patchMaxCut: number;
  patchBonds: number;
  patchBoundary: number;
  patchDensity: number;
  patchStrategy: GrowthStrategy;
  patchRegionData: Region[];
  patchCurvature: CurvatureData | null;
  patchHalfBound: HalfBoundData | null;
}

export interface TowerLevel {
  tlPatchName: string;
  tlRegions: number;
  tlOrbits: number;
  tlMaxCut: number;
  tlMonotone: [number, string] | null;
  tlHasBridge: boolean;
  tlHasAreaLaw: boolean;
  tlHasHalfBound: boolean;
}

export type TheoremStatus = "Verified" | "Dead" | "Numerical";

export interface Theorem {
  thmNumber: number;
  thmName: string;
  thmModule: string;
  thmStatement: string;
  thmProofMethod: string;
  thmStatus: TheoremStatus;
}

export interface Meta {
  version: string;
  buildDate: string;
  agdaVersion: string;
  dataHash: string;
}
```

---

## 4. Application Routes

| Route | Component | Data Source | Description |
|-------|-----------|------------|-------------|
| `/` | `<Home />` | `GET /meta`, `GET /theorems` | Landing page with project summary and theorem dashboard |
| `/patches` | `<PatchList />` | `GET /patches` | Card grid of all available patches with summary stats |
| `/patches/:name` | `<PatchView />` | `GET /patches/:name` | 3D patch viewer + region table + curvature + half-bound |
| `/tower` | `<TowerView />` | `GET /tower` | Resolution tower timeline with monotonicity arrows |
| `/theorems` | `<TheoremDashboard />` | `GET /theorems` | All 10+ theorems with status indicators and module links |

---

## 5. View Specifications

### 5.1 Home / Landing Page (`/`)

**Purpose:** First impression — communicate what the project proves and how to explore it.

**Layout:**

```
┌─────────────────────────────────────────────────────────┐
│  Univalence Gravity — The Spacetime Compiler  v0.5.0    │
│  A Constructive Formalization of Discrete               │
│  Entanglement-Geometry Duality in Cubical Agda          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │ Thm 1   │  │ Thm 2   │  │ Thm 3   │  │ Thm 5   │  │
│  │ RT ✓    │  │ GB ✓    │  │ BH ✓    │  │ NoCTC ✓ │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐               │
│  │ Thm 4   │  │ Thm 6   │  │ Thm 7   │               │
│  │ Wick ✓  │  │ Matter ✓│  │ QBridge✓│               │
│  └─────────┘  └─────────┘  └─────────┘               │
│                                                         │
│  [Explore Patches →]    [View Tower →]                  │
│                                                         │
│  Built with: Agda 2.8.0 • agda/cubical • MIT License   │
│  Data hash: abc123...   Build: 2026-04-15               │
└─────────────────────────────────────────────────────────┘
```

**Interactions:**
- Click a theorem card → navigate to `/theorems` with that theorem highlighted
- Click "Explore Patches" → navigate to `/patches`
- Click "View Tower" → navigate to `/tower`

**Data:** `GET /meta` for version info, `GET /theorems` for the 7 core theorem statuses

---

### 5.2 Patch List (`/patches`)

**Purpose:** Browse all verified patch instances with key statistics.

**Layout:** Responsive card grid (3 columns on desktop, 1 on mobile).

Each card shows:
```
┌───────────────────────────┐
│  Dense-100                │
│  {4,3,5} • 3D • Dense    │
│                           │
│  Cells:    100            │
│  Regions:  717 → 8 orbits │
│  Max S:    8              │
│  Bridge:   ✓ Verified     │
│                           │
│  [View Details →]         │
└───────────────────────────┘
```

**Sorting/Filtering:**
- Sort by: name, cells, regions, max cut, tiling
- Filter by: tiling type, dimension, strategy

**Data:** `GET /patches`

---

### 5.3 Patch Viewer (`/patches/:name`)

**Purpose:** The primary visualization — interactive 3D rendering of a holographic patch with region selection, min-cut coloring, curvature heatmaps, and the Bekenstein–Hawking half-bound data.

**Layout (3-panel):**

```
┌────────────────────────┬───────────────────────────────┐
│                        │  Patch: Dense-100              │
│                        │  {4,3,5} • 100 cells • Dense  │
│    3D VIEWPORT         │                               │
│    (Three.js Canvas)   │  ── Region Inspector ──       │
│                        │  Selected: d100r15            │
│    OrbitControls       │  Cells: {c14,c93,c95,c97,c98}│
│    Click to select     │  Size: 5                     │
│    region              │  Min-cut S: 8                 │
│                        │  Area: 22                     │
│                        │  S/area: 0.3636               │
│                        │  Half-slack: 6                │
│                        │  Orbit: mc8                   │
├────────────────────────┤                               │
│  Color by:             │  ── Curvature ──             │
│  [Min-Cut ▼]           │  Edge class ev5: κ₂₀ = −5   │
│  ○ Min-Cut value       │  12 edges × (−5) = −60      │
│  ○ Region size         │  Gauss–Bonnet: ✓ refl       │
│  ○ S/area ratio        │                               │
│  ○ Curvature           │  ── Half-Bound ──            │
│                        │  Regions: 717                 │
│  Show:                 │  Violations: 0                │
│  ☑ Cell boundaries     │  Achievers: 40               │
│  ☑ Internal bonds      │  1/(4G) = 1/2 ✓             │
│  ☐ Boundary legs       │                               │
│  ☐ Orbit coloring      │  ── Distribution ──          │
│                        │  [Histogram of S/area]       │
└────────────────────────┴───────────────────────────────┘
```

#### 5.3.1 Three.js Scene Structure

```typescript
// Pseudocode for the 3D scene

<Canvas camera={{ position: [0, 0, 50], fov: 60 }}>
  <ambientLight intensity={0.5} />
  <directionalLight position={[10, 10, 10]} />
  <OrbitControls enableDamping />
  
  {/* Cell meshes — one per boundary cell */}
  {patch.patchRegionData
    .filter(r => r.regionSize === 1)
    .map(r => (
      <CellMesh
        key={r.regionId}
        cellId={r.regionCells[0]}
        minCut={r.regionMinCut}
        color={colorScale(r.regionMinCut, patch.patchMaxCut)}
        selected={selectedRegion?.regionId === r.regionId}
        onClick={() => setSelectedRegion(r)}
      />
    ))}

  {/* Bond connectors — translucent cylinders between adjacent cells */}
  {bonds.map(([c1, c2]) => (
    <BondConnector key={`${c1}-${c2}`} from={cellPos(c1)} to={cellPos(c2)} />
  ))}

  {/* Boundary faces — wireframe outlines */}
  {showBoundary && <BoundaryWireframe cells={boundaryCells} />}
</Canvas>
```

#### 5.3.2 Cell Layout Algorithm

Since the backend serves region data but not explicit 3D coordinates:

**For 2D patches ({5,4}, {5,3}, {4,4}):** Use a force-directed layout (d3-force-3d) seeded by the cell adjacency graph. Interior cells cluster at the center; boundary cells spread outward.

**For 3D patches ({4,3,5}):** Same force-directed approach in 3D space, with bond lengths as spring targets.

**Alternative (simpler):** Render cells as spheres at positions derived from the adjacency graph via spectral embedding (eigenvalues of the graph Laplacian → coordinates). This is deterministic and reproducible.

The cell positions are computed client-side on first load and cached.

#### 5.3.3 Color Scales

| Mode | Domain | Scale | Interpretation |
|------|--------|-------|----------------|
| Min-Cut value | `[1, patchMaxCut]` | Sequential blue→red (Viridis) | Higher S = deeper holographic surface = warmer color |
| Region size | `[1, max_region_cells]` | Sequential green→purple | Larger regions = more cells = darker |
| S/area ratio | `[0, 0.5]` | Diverging blue→white→red | Ratio approaching 0.5 = approaching the Bekenstein–Hawking bound |
| Curvature | `[κ_min, κ_max]` | Diverging blue→white→red | Negative (hyperbolic) = blue, zero (flat) = white, positive (spherical) = red |

#### 5.3.4 Region Selection

- **Click a cell** → highlight all regions containing that cell (outline glow)
- **Click a region in the side panel** → highlight its constituent cells in the 3D view
- **Hover** → tooltip with region ID, S, area, S/area

#### 5.3.5 Distribution Charts

In the side panel, render:

1. **Histogram of min-cut values** — bar chart, one bar per distinct S value, height = region count
2. **Histogram of S/area ratios** — continuous histogram with a vertical line at 0.5 (the Bekenstein–Hawking bound)
3. **Orbit pie chart** — one slice per orbit representative, sized by region count

Use Recharts (lightweight React chart library) for these 2D charts.

---

### 5.4 Tower Timeline (`/tower`)

**Purpose:** Visualize the resolution tower as a directed timeline, showing monotone growth of the min-cut spectrum across patch sizes.

**Layout:**

```
┌─────────────────────────────────────────────────────────┐
│  Resolution Tower — Monotone Convergence Certificate    │
│                                                         │
│   Dense-50        Dense-100       Dense-200             │
│   ┌─────┐  (1,refl) ┌─────┐  (1,refl) ┌─────┐        │
│   │ S≤7 │ ────────▶ │ S≤8 │ ────────▶ │ S≤9 │        │
│   │139 r│           │717 r│           │1246r│          │
│   │ — o │           │ 8 o │           │ 9 o │          │
│   │  ✓  │           │ ✓ ✓ │           │ ✓ ✓ │          │
│   └─────┘           └─────┘           └─────┘          │
│                                                         │
│   {5,4} Layer Tower (depths 2–7, all maxCut = 2)        │
│   ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐                     │
│   │d2│→│d3│→│d4│→│d5│→│d6│→│d7│  all (0,refl)        │
│   │21│ │61│ │166││441││1161│3046│                     │
│   └──┘ └──┘ └──┘ └──┘ └──┘ └──┘                     │
│                                                         │
│   Legend: r=regions, o=orbits, ✓=bridge, ✓✓=bridge+BH  │
│                                                         │
│   Click any level → opens that patch in /patches/:name  │
└─────────────────────────────────────────────────────────┘
```

**Interactions:**
- Click a tower level → navigate to `/patches/:name` for that patch
- Hover a monotonicity arrow → tooltip showing the witness `(k, refl)`
- Toggle between Dense tower and {5,4} Layer tower

**Data:** `GET /tower`

---

### 5.5 Theorem Dashboard (`/theorems`)

**Purpose:** Display all machine-checked theorems with their status, module paths, and proof methods.

**Layout:**

```
┌─────────────────────────────────────────────────────────┐
│  Theorem Dashboard — All Machine-Checked Results        │
│                                                         │
│  #  │ Name                      │ Module        │ ✓/✗  │
│  ───┼───────────────────────────┼───────────────┼──────│
│  1  │ Discrete Ryu–Takayanagi   │ GenericBridge │  ✓   │
│  2  │ Discrete Gauss–Bonnet     │ GaussBonnet   │  ✓   │
│  3  │ Discrete Bekenstein–Hawking│ HalfBound    │  ✓   │
│  4  │ Discrete Wick Rotation    │ WickRotation  │  ✓   │
│  5  │ No Closed Timelike Curves │ NoCTC         │  ✓   │
│  6  │ Matter as Topol. Defects  │ Holonomy      │  ✓   │
│  7  │ Quantum Superpos. Bridge  │ QuantumBridge │  ✓   │
│  8  │ Subadditivity & Monotone  │ StarSubadd    │  ✓   │
│  9  │ Step Invariance & Loop    │ StepInvariance│  ✓   │
│ 10  │ Enriched Step Invariance  │ EnrichedStep  │  ✓   │
│                                                         │
│  Click row → expand to show:                            │
│    • Informal statement                                 │
│    • Proof method                                       │
│    • Agda type signature (monospace)                    │
│    • Verification command                               │
└─────────────────────────────────────────────────────────┘
```

**Interactions:**
- Click a row → expand accordion with full theorem details
- Status badge: green ✓ for Verified, gray for Dead, orange for Numerical

**Data:** `GET /theorems`

---

## 6. 3D Rendering Details

### 6.1 Cell Geometry

| Tiling | Cell shape | Three.js geometry | Notes |
|--------|-----------|-------------------|-------|
| {4,3,5} | Cube | `BoxGeometry(1, 1, 1)` | Standard unit cube |
| {5,4} | Pentagon | `ExtrudeGeometry` from pentagonal `Shape` | Flat extrusion with small depth |
| {5,3} | Pentagon | Same as {5,4} | Shared geometry |
| {4,4} | Square | `PlaneGeometry(1, 1)` | Flat square |

### 6.2 Materials

```typescript
// Cell material — colored by min-cut, with selection highlight
const cellMaterial = new MeshStandardMaterial({
  color: colorFromMinCut(region.regionMinCut, patch.patchMaxCut),
  metalness: 0.1,
  roughness: 0.7,
  transparent: true,
  opacity: isSelected ? 1.0 : 0.85,
});

// Bond material — translucent connector
const bondMaterial = new MeshStandardMaterial({
  color: 0x888888,
  transparent: true,
  opacity: 0.3,
});

// Selected cell — emissive glow
if (isSelected) {
  cellMaterial.emissive = new Color(0xffaa00);
  cellMaterial.emissiveIntensity = 0.5;
}
```

### 6.3 Performance Considerations

| Patch | Cells | Expected meshes | Strategy |
|-------|-------|-----------------|----------|
| Star (6) | 6 | ~6 | Direct rendering |
| Filled (11) | 11 | ~11 | Direct rendering |
| Dense-50 | 50 | ~42 boundary | Direct rendering |
| Dense-100 | 100 | ~86 boundary | Direct rendering |
| Dense-200 | 200 | ~166 boundary | Direct rendering |
| Layer-54-d7 | 3046 | ~1885 boundary | **InstancedMesh** recommended |

For patches with > 500 boundary cells, use `InstancedMesh` with a single geometry and per-instance color attributes. This reduces draw calls from ~1885 to 1.

---

## 7. Project Structure

```
frontend/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── tailwind.config.js
├── index.html
├── public/
│   └── favicon.ico
├── src/
│   ├── main.tsx                    -- React entry point
│   ├── App.tsx                     -- Router + layout
│   ├── api/
│   │   └── client.ts              -- Typed API client (§3.1)
│   ├── types/
│   │   └── index.ts               -- TypeScript types (§3.2)
│   ├── hooks/
│   │   ├── usePatch.ts            -- Fetch + cache a single patch
│   │   ├── usePatches.ts          -- Fetch patch list
│   │   ├── useTower.ts            -- Fetch tower data
│   │   └── useTheorems.ts         -- Fetch theorem list
│   ├── components/
│   │   ├── layout/
│   │   │   ├── Header.tsx          -- Navigation bar
│   │   │   ├── Footer.tsx          -- Version + links
│   │   │   └── Layout.tsx          -- Shell with header/footer
│   │   ├── home/
│   │   │   ├── TheoremCard.tsx     -- Single theorem status card
│   │   │   └── HomePage.tsx        -- Landing page
│   │   ├── patches/
│   │   │   ├── PatchCard.tsx       -- Summary card for patch list
│   │   │   ├── PatchList.tsx       -- Grid of patch cards
│   │   │   ├── PatchView.tsx       -- Main patch viewer (3-panel)
│   │   │   ├── PatchScene.tsx      -- Three.js canvas (@react-three/fiber)
│   │   │   ├── CellMesh.tsx        -- Single cell 3D component
│   │   │   ├── BondConnector.tsx   -- Bond cylinder between cells
│   │   │   ├── RegionInspector.tsx -- Side panel: selected region details
│   │   │   ├── CurvaturePanel.tsx  -- Curvature class table
│   │   │   ├── HalfBoundPanel.tsx  -- Bekenstein–Hawking statistics
│   │   │   ├── DistributionChart.tsx -- Histograms (Recharts)
│   │   │   └── ColorControls.tsx   -- Color-by selector + toggles
│   │   ├── tower/
│   │   │   ├── TowerTimeline.tsx   -- Horizontal scrollable timeline
│   │   │   ├── TowerLevel.tsx      -- Single level card
│   │   │   └── TowerView.tsx       -- Full tower page
│   │   └── theorems/
│   │       ├── TheoremRow.tsx      -- Expandable row in the table
│   │       └── TheoremDashboard.tsx -- Full theorem page
│   ├── utils/
│   │   ├── colors.ts              -- Color scale functions
│   │   ├── layout.ts              -- Force-directed / spectral layout
│   │   └── tiling.ts              -- Tiling-specific geometry helpers
│   └── styles/
│       └── globals.css            -- Tailwind base + custom styles
├── tests/
│   ├── api.test.ts                -- API client mock tests
│   ├── types.test.ts              -- Type guard tests
│   └── components/
│       ├── PatchCard.test.tsx
│       └── TheoremCard.test.tsx
└── README.md
```

---

## 8. Key Dependencies

```json
{
  "dependencies": {
    "react": "^18.3",
    "react-dom": "^18.3",
    "react-router-dom": "^6.20",
    "@react-three/fiber": "^8.15",
    "@react-three/drei": "^9.90",
    "three": "^0.160",
    "recharts": "^2.10",
    "tailwindcss": "^3.4"
  },
  "devDependencies": {
    "typescript": "^5.3",
    "vite": "^5.0",
    "@vitejs/plugin-react": "^4.2",
    "vitest": "^1.0",
    "@testing-library/react": "^14.0",
    "autoprefixer": "^10.4",
    "postcss": "^8.4"
  }
}
```

---

## 9. Layout Algorithm

### 9.1 Force-Directed (Default)

For patches without explicit 3D coordinates, compute cell positions using a force-directed simulation:

```typescript
// src/utils/layout.ts

import { forceSimulation, forceLink, forceManyBody, forceCenter } from "d3-force-3d";

export function computeCellPositions(
  cellIds: number[],
  bonds: [number, number][],
  dimension: number,  // 2 or 3
): Map<number, [number, number, number]> {
  const nodes = cellIds.map(id => ({ id, x: 0, y: 0, z: 0 }));
  const links = bonds.map(([s, t]) => ({ source: s, target: t }));

  const sim = forceSimulation(nodes, dimension === 3 ? 3 : 2)
    .force("link", forceLink(links).distance(2).strength(1))
    .force("charge", forceManyBody().strength(-5))
    .force("center", forceCenter(0, 0, 0))
    .stop();

  // Run 300 iterations
  for (let i = 0; i < 300; i++) sim.tick();

  const positions = new Map<number, [number, number, number]>();
  for (const node of nodes) {
    positions.set(node.id, [node.x, node.y, node.z ?? 0]);
  }
  return positions;
}
```

### 9.2 Caching

Cell positions are deterministic (same adjacency graph → same layout after fixed iterations). Cache the computed positions in `sessionStorage` keyed by patch name to avoid recomputation on revisit.

---

## 10. Responsive Design

| Breakpoint | Layout | 3D Viewport | Side Panel |
|-----------|--------|-------------|------------|
| Desktop (≥1280px) | 3-column: controls / canvas / inspector | 60% width | 30% width, scrollable |
| Tablet (768–1279px) | 2-column: canvas / inspector | 65% width | 35% width |
| Mobile (<768px) | Stacked: canvas on top, inspector below | 100% width, 50vh height | 100% width, scrollable |

The 3D viewport uses `<Canvas style={{ width: '100%', height: '100%' }}>` and fills its container. On mobile, touch gestures (pinch-zoom, two-finger rotate) are handled by `OrbitControls` from `@react-three/drei`.

---

## 11. Accessibility

- **Keyboard navigation:** Tab through theorem cards, patch list, tower levels. Enter to expand/navigate.
- **Screen reader:** ARIA labels on all interactive elements. Alt text on the Three.js canvas describing the patch statistics (since 3D content is not natively accessible).
- **Color blindness:** All color scales include a colorblind-safe option (Viridis is the default — perceptually uniform and safe for deuteranopia/protanopia).
- **Reduced motion:** Respect `prefers-reduced-motion` by disabling OrbitControls auto-rotation and chart animations.

---

## 12. Testing Strategy

### 12.1 Unit Tests (Vitest)

- Color scale functions produce correct hex values
- Type guards validate API response shapes
- Layout algorithm produces finite, non-NaN coordinates
- Component rendering (smoke tests with mock data)

### 12.2 Component Tests (React Testing Library)

- PatchCard renders correct statistics
- TheoremRow expands on click and shows type signature
- TowerTimeline renders correct number of levels

### 12.3 Integration Tests

- Mock the API with `msw` (Mock Service Worker)
- Navigate through all routes and verify data renders
- Verify no console errors or unhandled promise rejections

### 12.4 Visual Regression (Optional)

- Screenshot comparison of the Three.js viewport at known camera angles
- Useful for catching unexpected geometry or color changes

---

## 13. Deployment

### 13.1 Development

```bash
cd frontend
npm install
npm run dev    # Vite dev server at localhost:5173
```

Requires the Haskell backend running at `localhost:8080` (or configure `VITE_API_URL`).

### 13.2 Production Build

```bash
npm run build    # outputs to frontend/dist/
```

The `dist/` directory contains static HTML/JS/CSS — serve with any static file server (nginx, Caddy, Netlify, Vercel, GitHub Pages).

### 13.3 Docker (Optional)

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Serve stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 3000
```

### 13.4 Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VITE_API_URL` | `http://localhost:8080` | Backend API base URL |

---

## 14. Milestones

| Milestone | Deliverable | Dependency |
|-----------|-------------|------------|
| F1 | TypeScript types + API client + mock data | Backend M2 (JSON schema) |
| F2 | Patch list page with cards | Backend M3 (API serving) |
| F3 | 3D patch viewer with force-directed layout + cell coloring | F2 |
| F4 | Region selection + inspector panel | F3 |
| F5 | Tower timeline + theorem dashboard | Backend M3 |
| F6 | Half-bound statistics + distribution charts | F4 |
| F7 | Responsive design + accessibility pass | F6 |
| F8 | Production build + deployment configuration | F7 |

---

## 15. Design Principles

1. **Data is read-only.** The frontend never modifies any data. All information is pre-computed, verified, and served by the backend. The frontend is a pure visualization layer.

2. **Progressive disclosure.** Start with high-level summaries (patch cards, theorem badges). Drill down to details on click (region inspector, theorem expansion, tower level → patch view).

3. **Academic credibility.** Typography, color palette, and layout should feel like an interactive paper, not a videogame. Serif headings, monospace for Agda type signatures, muted color palette with Viridis for data visualization.

4. **Performance over features.** The 3D viewport must maintain 60 FPS even for the largest patches (Dense-2000 with ~1885 boundary cells). Use `InstancedMesh` aggressively. Defer loading of large region datasets until the user navigates to that patch.

5. **Offline-capable.** Since the data is static, the frontend can bundle a service worker to cache all API responses after first load. This allows offline browsing after the initial page visit.

---

## 16. Cross-References

| Topic | Document |
|-------|----------|
| Backend specification | [`engineering/backend-spec-haskell.md`](backend-spec-haskell.md) |
| Theorem registry (served as JSON) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| Scaling report (region counts, timings) | [`engineering/scaling-report.md`](scaling-report.md) |
| Oracle pipeline (data source) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Orbit reduction (region classification) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| Generic bridge pattern (PatchData interface) | [`engineering/generic-bridge-pattern.md`](generic-bridge-pattern.md) |
| Bekenstein–Hawking half-bound | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Holographic dictionary (physics context) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Instance data sheets | [`instances/`](../instances/) |