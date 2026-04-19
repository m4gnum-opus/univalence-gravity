{-# LANGUAGE DeriveGeneric #-}

-- | Domain types for the Univalence Gravity Haskell backend.
--
--   Every type in this module mirrors (but is not compiled from) an Agda
--   type in @src/@.  Only the verified /data/ is represented — not the
--   proof content.  All types derive 'Generic', 'ToJSON', and 'FromJSON'
--   so they can be read from the @data/*.json@ files produced by
--   @18_export_json.py@ and served via the Servant REST API.
--
--   No internal imports.  This module is the dependency root for all
--   other @backend/src/@ modules.
--
--   __JSON field naming convention:__
--
--   Most types use Aeson's default generic derivation, where the Haskell
--   field name IS the JSON key (e.g. @patchName@, @regionMinCut@).
--   Three types carry a Haskell-only prefix that is stripped for JSON:
--
--     * 'GraphNode' — prefix @\"gn\"@ (2 chars), e.g.
--       @gnId@ ↔ JSON @\"id\"@, @gnScale@ ↔ JSON @\"scale\"@,
--       @gnQw@ ↔ JSON @\"qw\"@.
--     * 'CurvatureSummary' — prefix @\"cs\"@ (2 chars), e.g.
--       @csPatchName@ ↔ JSON @\"patchName\"@.
--     * 'Meta' — prefix @\"meta\"@ (4 chars), e.g.
--       @metaVersion@ ↔ JSON @\"version\"@.
--
--   __Curvature denomination:__
--
--   All curvature integer values are stored as numerators.  The
--   @curvDenominator@ field disambiguates the unit:
--
--     * 2D ({5,4}, {5,3}): denominator = 10 (tenths, ℚ₁₀ encoding)
--     * 3D ({4,3,5}):      denominator = 20 (twentieths)
--
--   For example, @curvTotal = -60@ with @curvDenominator = 20@ means
--   the true rational total curvature is @−60/20 = −3@.
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §3 (Data Model)

module Types
  ( -- * Enumerations
    Tiling(..)
  , GrowthStrategy(..)
  , TheoremStatus(..)
    -- * Region-level data
  , Region(..)
    -- * Bulk graph
  , Edge(..)
  , edgeEndpoints
  , GraphNode(..)
  , PatchGraph(..)
    -- * Curvature
  , CurvatureClass(..)
  , CurvatureData(..)
    -- * Half-bound (Discrete Bekenstein–Hawking)
  , HalfBoundData(..)
    -- * Patch (full and summary)
  , Patch(..)
  , PatchSummary(..)
    -- * Resolution tower
  , TowerLevel(..)
    -- * Theorems
  , Theorem(..)
    -- * Curvature summary (top-level curvature.json)
  , CurvatureSummary(..)
    -- * Server metadata and health
  , Meta(..)
  , Health(..)
  ) where

import Data.Aeson
  ( FromJSON(..)
  , ToJSON(..)
  , Options(..)
  , defaultOptions
  , genericParseJSON
  , genericToEncoding
  , genericToJSON
  )
import Data.Char    (toLower)
import Data.Text    (Text)
import GHC.Generics (Generic)


-- ════════════════════════════════════════════════════════════════
--  Internal helpers
-- ════════════════════════════════════════════════════════════════

-- | Drop @n@ characters from a field-name string, then lowercase
--   the first remaining character.  Used by 'GraphNode'
--   (prefix @\"gn\"@, n=2), 'CurvatureSummary'
--   (prefix @\"cs\"@, n=2) and 'Meta' (prefix @\"meta\"@, n=4)
--   whose Haskell field names carry a prefix absent from the
--   JSON keys emitted by @18_export_json.py@.
--
--   Named @dropFieldPrefix@ rather than @stripPrefix@ to avoid
--   shadowing 'Data.List.stripPrefix'.
dropFieldPrefix :: Int -> String -> String
dropFieldPrefix n = lowerFirst . drop n

lowerFirst :: String -> String
lowerFirst []     = []
lowerFirst (c:cs) = toLower c : cs


-- ════════════════════════════════════════════════════════════════
--  Tiling
-- ════════════════════════════════════════════════════════════════

-- | Tiling type (Schläfli symbol or structural label).
--
--   Encoded as a plain JSON string matching the constructor name,
--   e.g. @\"Tiling54\"@, @\"Tree\"@.  Aeson's default generic
--   derivation handles this because all constructors are nullary
--   and @allNullaryToStringTag@ defaults to @True@.
--
--   These constructors correspond to the tiling families verified
--   in the Agda formalization:
--
--   @
--   Tiling54   — {5,4} hyperbolic pentagonal (star, filled, layer-54)
--   Tiling435  — {4,3,5} hyperbolic cubic    (honeycomb, dense-50/100/200)
--   Tiling53   — {5,3} spherical dodecahedral (desitter)
--   Tiling44   — {4,4} Euclidean square grid  (numerical only, no Agda)
--   Tree       — 1D weighted binary tree      (tree pilot instance)
--   @
--
--   Reference: docs\/engineering\/backend-spec-haskell.md §3.1
data Tiling
  = Tiling54    -- ^ {5,4} hyperbolic pentagonal tiling (2D)
  | Tiling435   -- ^ {4,3,5} hyperbolic cubic honeycomb (3D)
  | Tiling53    -- ^ {5,3} spherical dodecahedral tiling (2D)
  | Tiling44    -- ^ {4,4} Euclidean square grid (2D)
  | Tree        -- ^ 1D weighted binary tree (pilot instance)
  deriving (Show, Eq, Ord, Generic)

instance ToJSON   Tiling
instance FromJSON Tiling


-- ════════════════════════════════════════════════════════════════
--  GrowthStrategy
-- ════════════════════════════════════════════════════════════════

-- | Patch growth strategy used by the Python oracle.
data GrowthStrategy
  = BFS         -- ^ Concentric BFS shells from the central cell
  | Dense       -- ^ Greedy: add the frontier cell with most neighbours
  | Geodesic    -- ^ Tube along a geodesic spine + 1-shell fattening
  | Hemisphere  -- ^ Half-space BFS (3 of 6 face crossings)
  deriving (Show, Eq, Ord, Generic)

instance ToJSON   GrowthStrategy
instance FromJSON GrowthStrategy


-- ════════════════════════════════════════════════════════════════
--  TheoremStatus
-- ════════════════════════════════════════════════════════════════

-- | Verification status of a theorem in the canonical registry.
data TheoremStatus
  = Verified    -- ^ Type-checked by Cubical Agda 2.8.0
  | Dead        -- ^ Superseded by a generic theorem; dead code
  | Numerical   -- ^ Numerically confirmed by the Python oracle only
  deriving (Show, Eq, Ord, Generic)

instance ToJSON   TheoremStatus
instance FromJSON TheoremStatus


-- ════════════════════════════════════════════════════════════════
--  Region
-- ════════════════════════════════════════════════════════════════

-- | A single cell-aligned boundary region within a patch.
--
--   JSON keys match the Haskell field names verbatim:
--   @regionId@, @regionCells@, @regionSize@, @regionMinCut@,
--   @regionArea@, @regionOrbit@, @regionHalfSlack@, @regionRatio@,
--   @regionCurvature@.
--
--   __@regionCurvature@:__  Average curvature of the cells in this
--   region, computed by @18_export_json.py@ as a per-cell aggregation
--   of adjacent vertex (2D) or edge (3D) curvature values.  For 3D
--   ({4,3,5}) patches this is the mean of the 12 edge-curvature values
--   (κ₂₀ / 20) for each cell in the region.  For 2D patches (filled,
--   desitter) it is a hardcoded per-tile average derived from the
--   known vertex-class curvatures.  @Nothing@ when curvature data is
--   unavailable for the patch (e.g. tree, star, layer-54 patches).
data Region = Region
  { regionId        :: Int            -- ^ Unique index within the patch
  , regionCells     :: [Int]          -- ^ Sorted cell IDs in this region
  , regionSize      :: Int            -- ^ Number of cells  (= length regionCells)
  , regionMinCut    :: Int            -- ^ S(A) — boundary min-cut entropy
  , regionArea      :: Int            -- ^ Boundary surface area (face-count)
  , regionOrbit     :: Text           -- ^ Orbit representative label, e.g. @\"mc3\"@
  , regionHalfSlack :: Maybe Int      -- ^ @area − 2·S@; 'Nothing' if not computed
  , regionRatio     :: Double         -- ^ @S / area@
  , regionCurvature :: Maybe Double   -- ^ Average κ of adjacent vertices/edges
  } deriving (Show, Eq, Generic)

instance ToJSON   Region
instance FromJSON Region


-- ════════════════════════════════════════════════════════════════
--  GraphNode
-- ════════════════════════════════════════════════════════════════

-- | A single node in the bulk graph, carrying its cell ID,
--   Poincaré-ball coordinates, a rotation quaternion, and the
--   conformal scale factor at that point.
--
--   The coordinates are computed by @18_export_json.py@ via
--   hyperboloid → Poincaré ball/disk projection of the Coxeter
--   cell/tile centres.  The projection uses a Lorentz boost
--   (@_lorentz_boost_to_apex@) so the fundamental cell lands at
--   the origin of the ball — with this centring, @g = I@ projects
--   to @(0, 0, 0)@ and the patch is visually centred on the
--   viewport without relying on post-hoc rescaling.
--
--   __Field schema (uniform across all patches):__
--
--     [@gnId@]    Cell or tile identifier (matches entries in @pgEdges@).
--     [@gnX, gnY, gnZ@]  Coordinates in the Poincaré ball (3D) or
--                        disk embedded as @z = 0@ (2D).  Always in
--                        the open unit ball: @x² + y² + z² < 1@.
--     [@gnQx .. gnQw@]   Unit quaternion for the cell's rotation
--                        relative to the fundamental cell.  For 2D
--                        patches this is a z-axis rotation (only
--                        @qz@ and @qw@ are non-zero); for 3D
--                        patches it is the full Shepperd–Shuster
--                        conversion of the rotation extracted from
--                        the (boosted) Jacobian of the projection.
--                        Hand-written 2D layouts (tree, star,
--                        filled, desitter) use the identity
--                        quaternion @(0, 0, 0, 1)@.
--     [@gnScale@] Conformal scale factor @s(u) = (1 − |u|²) / 2@
--                 where @u = (gnX, gnY, gnZ)@.  This is the
--                 correct per-cell scaling for an Escher-style
--                 Poincaré rendering: cells at the centre have
--                 @s ≈ 0.5@, cells near the boundary have @s → 0@.
--                 Clamped to @1e-6@ to avoid zero-scale degeneracy
--                 at the boundary.
--
--   The JSON keys are @\"id\"@, @\"x\"@, @\"y\"@, @\"z\"@, @\"qx\"@,
--   @\"qy\"@, @\"qz\"@, @\"qw\"@, @\"scale\"@ — the Haskell field
--   prefix @\"gn\"@ is stripped by a custom 'Options' using
--   'dropFieldPrefix'.
data GraphNode = GraphNode
  { gnId    :: Int       -- ^ Cell ID (matches entries in @pgEdges@)
  , gnX     :: Double    -- ^ Poincaré x-coordinate
  , gnY     :: Double    -- ^ Poincaré y-coordinate
  , gnZ     :: Double    -- ^ Poincaré z-coordinate (0.0 for 2D patches)
  , gnQx    :: Double    -- ^ Rotation quaternion — x component
  , gnQy    :: Double    -- ^ Rotation quaternion — y component
  , gnQz    :: Double    -- ^ Rotation quaternion — z component
  , gnQw    :: Double    -- ^ Rotation quaternion — w (real) component
  , gnScale :: Double    -- ^ Conformal scale factor @s(u) = (1 − |u|²) / 2@
  } deriving (Show, Eq, Generic)

graphNodeOptions :: Options
graphNodeOptions = defaultOptions
  { fieldLabelModifier = dropFieldPrefix 2 }

instance ToJSON GraphNode where
  toJSON     = genericToJSON     graphNodeOptions
  toEncoding = genericToEncoding graphNodeOptions

instance FromJSON GraphNode where
  parseJSON = genericParseJSON graphNodeOptions

-- ════════════════════════════════════════════════════════════════
--  Edge
-- ════════════════════════════════════════════════════════════════

-- | A single undirected bond in a 'PatchGraph', represented on the
--   wire as @{"source": <id>, "target": <id>}@.
--
--   The Python exporter (@18_export_json.py@, function
--   @_make_patch_graph@) emits edges as objects rather than 2-element
--   arrays so that the Haskell and TypeScript sides can share a single
--   record schema.  Internally we keep the canonical
--   @source ≤ target@ ordering produced by the exporter.
--
--   The Haskell field names carry the prefix @\"edge\"@ (4 chars),
--   which is stripped by 'dropFieldPrefix' to yield the JSON keys
--   @\"source\"@ and @\"target\"@.
data Edge = Edge
  { edgeSource :: !Int
  , edgeTarget :: !Int
  } deriving (Show, Eq, Generic)

edgeOptions :: Options
edgeOptions = defaultOptions
  { fieldLabelModifier = dropFieldPrefix 4 }

instance ToJSON Edge where
  toJSON     = genericToJSON     edgeOptions
  toEncoding = genericToEncoding edgeOptions

instance FromJSON Edge where
  parseJSON = genericParseJSON edgeOptions

-- | Extract both endpoints as a two-element list.
--
--   Used by callers that previously treated each edge as a @[Int]@
--   pair (graph validation, test spec iteration).
edgeEndpoints :: Edge -> [Int]
edgeEndpoints (Edge s t) = [s, t]

-- ════════════════════════════════════════════════════════════════
--  PatchGraph
-- ════════════════════════════════════════════════════════════════

-- | The full bulk graph of a patch: all cells as nodes (with
--   projected spatial coordinates, rotations, and conformal
--   scales) and all physical bonds (shared faces in 3D, shared
--   edges in 2D) as edges.
--
--   This is the data the frontend needs to render the 3D
--   holographic representation correctly.  Without it, the
--   frontend can only infer nodes and edges from the boundary
--   region data, which misses interior cells (cells with zero
--   boundary legs that appear in no region) and misinterprets
--   boundary adjacency as physical bonds.
--
--   __@pgNodes@:__  Sorted list of 'GraphNode' objects, each
--   carrying a cell ID, Poincaré-projected @(x, y, z)@, a
--   rotation quaternion @(qx, qy, qz, qw)@, and a conformal
--   @scale@.  For a Dense-100 patch this contains 100 nodes.
--   Includes both boundary cells (those appearing in at least
--   one region's @regionCells@) and interior cells (those with
--   all faces shared, appearing in no region).
--
--   __@pgEdges@:__  Sorted list of physical bonds, each
--   represented as a sorted two-element list @[lo, hi]@ where
--   @lo < hi@.  For 3D patches, each edge corresponds to a
--   shared cube face; for 2D patches, a shared pentagon edge;
--   for the tree, a weighted tree edge.
--
--   __Relationship to regions:__  The set of boundary cells is
--   the union of all @regionCells@ across all regions.  The set
--   of interior cells is @pgNodes \\\\ boundary_cells@ (by ID).
--   The frontend uses this distinction to render boundary cells
--   with data-driven colors (from region data) and interior
--   cells with a neutral default.
--
--   __Invariant:__  Every endpoint of every edge in @pgEdges@
--   appears as a @gnId@ in @pgNodes@.  The number of nodes
--   equals @patchCells@.  These are checked by
--   'Invariants.validateAll'.
--
--   Produced by @_make_patch_graph@ in @18_export_json.py@.
data PatchGraph = PatchGraph
  { pgNodes :: [GraphNode]  -- ^ All cells with spatial coordinates (sorted by ID)
  , pgEdges :: [Edge]       -- ^ All physical bonds, one @{source,target}@ per bond
  } deriving (Show, Eq, Generic)

instance ToJSON   PatchGraph
instance FromJSON PatchGraph


-- ════════════════════════════════════════════════════════════════
--  CurvatureClass
-- ════════════════════════════════════════════════════════════════

-- | A single vertex (2D) or edge (3D) curvature class.
--
--   The @ccKappa@ value is an integer numerator.  The actual
--   rational curvature is @ccKappa / curvDenominator@ where the
--   denominator comes from the enclosing 'CurvatureData'.
--
--   Examples:
--
--   * @ccKappa = -2@ with denominator 10 → κ = −2/10 = −0.2
--     (2D {5,4} interior vertex)
--   * @ccKappa = -5@ with denominator 20 → κ = −5/20 = −0.25
--     (3D {4,3,5} fully-surrounded edge)
data CurvatureClass = CurvatureClass
  { ccName     :: Text  -- ^ Class label, e.g. @\"vTiling\"@, @\"ev5\"@
  , ccCount    :: Int   -- ^ Number of vertices/edges in this class
  , ccValence  :: Int   -- ^ Edge degree (2D) or face valence (3D)
  , ccKappa    :: Int   -- ^ Curvature as integer numerator
  , ccLocation :: Text  -- ^ @\"interior\"@ or @\"boundary\"@
  } deriving (Show, Eq, Generic)

instance ToJSON   CurvatureClass
instance FromJSON CurvatureClass


-- ════════════════════════════════════════════════════════════════
--  CurvatureData
-- ════════════════════════════════════════════════════════════════

-- | Full curvature data embedded inside a 'Patch'.
--
--   All curvature values are stored as integer numerators.  The
--   @curvDenominator@ field specifies the rational denominator:
--
--     * 10 for 2D patches ({5,4}, {5,3}) — matching ℚ₁₀ = ℤ
--     * 20 for 3D patches ({4,3,5})      — matching twentieths
--
--   The true rational total curvature is
--   @curvTotal / curvDenominator@.
--
--   __Scope for 3D Dense patches:__  The curvature covers only
--   the central cell's 12 edges (matching
--   @Bulk\/Dense{50,100,200}Curvature.agda@).  For BFS\/honeycomb
--   patches, curvature covers all edges in the patch (matching
--   @Bulk\/Honeycomb3DCurvature.agda@).
--
--   __Gauss–Bonnet caveat for 3D:__  For 3D patches,
--   @18_export_json.py@ sets @curvEuler = curvTotal@ (the same
--   computed value) because no independent 3D Euler characteristic
--   has been formalised in Agda.  The @curvGaussBonnet@ field is
--   therefore tautologically @True@ for 3D data.  It is
--   independently meaningful only for 2D patches (filled, desitter)
--   where the two values are derived from separate computations.
data CurvatureData = CurvatureData
  { curvClasses     :: [CurvatureClass]
  , curvTotal       :: Int   -- ^ Σ κ as integer numerator
  , curvEuler       :: Int   -- ^ χ as integer numerator
  , curvGaussBonnet :: Bool  -- ^ @curvTotal ≡ curvEuler@
  , curvDenominator :: Int   -- ^ Rational denominator (10 or 20)
  } deriving (Show, Eq, Generic)

instance ToJSON   CurvatureData
instance FromJSON CurvatureData


-- ════════════════════════════════════════════════════════════════
--  HalfBoundData
-- ════════════════════════════════════════════════════════════════

-- | Discrete Bekenstein–Hawking half-bound summary for a patch.
--
--   The bound @2·S(A) ≤ area(A)@ is verified for every region;
--   @hbViolations@ is always 0 in valid data.
data HalfBoundData = HalfBoundData
  { hbRegionCount   :: Int           -- ^ Total regions verified
  , hbViolations    :: Int           -- ^ Always 0 for valid data
  , hbAchieverCount :: Int           -- ^ Regions where @2·S = area@
  , hbAchieverSizes :: [(Int, Int)]  -- ^ @[(region_size, count)]@
  , hbSlackRange    :: (Int, Int)    -- ^ @(min_slack, max_slack)@
  , hbMeanSlack     :: Double
  } deriving (Show, Eq, Generic)

instance ToJSON   HalfBoundData
instance FromJSON HalfBoundData


-- ════════════════════════════════════════════════════════════════
--  Patch
-- ════════════════════════════════════════════════════════════════

-- | A verified holographic patch instance with full region data.
--
--   Loaded from @data/patches/*.json@.  Corresponds to the Agda
--   types 'PatchData' and 'OrbitReducedPatch' in
--   @Bridge/GenericBridge.agda@, but carries only the numeric data
--   — no proof content.
--
--   __@patchOrbits@ semantics:__  The value @0@ indicates flat
--   enumeration (no orbit reduction was applied).  A positive value
--   is the number of distinct orbit representatives (e.g. 8 for
--   Dense-100, 9 for Dense-200, 2 for the {5,4} layer patches).
--   A @Maybe Int@ with @Nothing@ for flat enumeration would be more
--   precise, but the @0 = flat@ convention keeps the JSON schema
--   simpler and is consistent across all patches.
--
--   __@patchHalfBoundVerified@:__  @True@ when a corresponding
--   @Boundary\/*HalfBound.agda@ module exists that machine-checks
--   @2·S(A) ≤ area(A)@ for every region via @abstract (k, refl)@
--   witnesses.  Currently @True@ only for @dense-100@, @dense-200@,
--   and @dense-1000@.  For all other patches, the half-bound data
--   (if present) is a Python-side numerical check only.
--
--   __@patchGraph@:__  The full bulk graph containing ALL cells
--   (including interior cells invisible to boundary regions) and
--   ALL physical bonds (shared faces/edges between adjacent cells),
--   with Poincaré-projected spatial coordinates, per-cell rotation
--   quaternions, and conformal scale factors.  See 'PatchGraph'
--   and 'GraphNode' for details.
data Patch = Patch
  { patchName              :: Text
  , patchTiling            :: Tiling
  , patchDimension         :: Int             -- ^ 1, 2, or 3
  , patchCells             :: Int             -- ^ Number of tiles / cubes
  , patchRegions           :: Int             -- ^ Number of boundary regions
  , patchOrbits            :: Int             -- ^ Orbit representatives (0 = flat)
  , patchMaxCut            :: Int             -- ^ Maximum min-cut value
  , patchBonds             :: Int             -- ^ Internal shared faces / edges
  , patchBoundary          :: Int             -- ^ Boundary legs / faces
  , patchDensity           :: Double          -- ^ @2 · bonds / cells@
  , patchStrategy          :: GrowthStrategy
  , patchRegionData        :: [Region]
  , patchCurvature         :: Maybe CurvatureData
  , patchHalfBound         :: Maybe HalfBoundData
  , patchHalfBoundVerified :: Bool            -- ^ Agda-verified half-bound exists
  , patchGraph             :: PatchGraph      -- ^ Full bulk graph (all cells + bonds)
  } deriving (Show, Eq, Generic)

instance ToJSON   Patch
instance FromJSON Patch


-- ════════════════════════════════════════════════════════════════
--  PatchSummary
-- ════════════════════════════════════════════════════════════════

-- | Lightweight summary for the @GET /patches@ listing endpoint.
--
--   Constructed server-side from 'Patch'; not read from a file.
data PatchSummary = PatchSummary
  { psName      :: Text
  , psTiling    :: Tiling
  , psDimension :: Int
  , psCells     :: Int
  , psRegions   :: Int
  , psOrbits    :: Int
  , psMaxCut    :: Int
  , psStrategy  :: GrowthStrategy
  } deriving (Show, Eq, Generic)

instance ToJSON   PatchSummary
instance FromJSON PatchSummary


-- ════════════════════════════════════════════════════════════════
--  TowerLevel
-- ════════════════════════════════════════════════════════════════

-- | A single level of the resolution tower.
--
--   Loaded from @data/tower.json@.  Corresponds to
--   @TowerLevel@ in @Bridge/SchematicTower.agda@.
data TowerLevel = TowerLevel
  { tlPatchName    :: Text
  , tlRegions      :: Int
  , tlOrbits       :: Int
  , tlMaxCut       :: Int
  , tlMonotone     :: Maybe (Int, Text)  -- ^ @(witness_k, \"refl\")@ or null
  , tlHasBridge    :: Bool
  , tlHasAreaLaw   :: Bool
  , tlHasHalfBound :: Bool
  } deriving (Show, Eq, Generic)

instance ToJSON   TowerLevel
instance FromJSON TowerLevel


-- ════════════════════════════════════════════════════════════════
--  Theorem
-- ════════════════════════════════════════════════════════════════

-- | A machine-checked theorem from the canonical registry.
--
--   Loaded from @data/theorems.json@.  Mirrors the table in
--   @docs/formal/01-theorems.md@.
data Theorem = Theorem
  { thmNumber      :: Int
  , thmName        :: Text
  , thmModule      :: Text    -- ^ e.g. @\"Bridge/GenericBridge.agda\"@
  , thmStatement   :: Text    -- ^ Informal one-line statement
  , thmProofMethod :: Text
  , thmStatus      :: TheoremStatus
  } deriving (Show, Eq, Generic)

instance ToJSON   Theorem
instance FromJSON Theorem


-- ════════════════════════════════════════════════════════════════
--  CurvatureSummary
-- ════════════════════════════════════════════════════════════════

-- | Top-level curvature summary entry from @data/curvature.json@.
--
--   Derived from per-patch curvature data by @18_export_json.py@,
--   guaranteeing consistency between @GET \/patches\/:name@ and
--   @GET \/curvature@.
--
--   The JSON keys lack the @\"cs\"@ prefix that the Haskell field
--   names carry, so a custom 'Options' strips the two-character
--   prefix and lowercases the first remaining character.
--
--   The @csCurvDenominator@ field disambiguates the curvature unit
--   (10 for 2D, 20 for 3D) — see 'CurvatureData' documentation.
data CurvatureSummary = CurvatureSummary
  { csPatchName       :: Text
  , csTiling          :: Text   -- ^ Tiling name as raw text
  , csCurvTotal       :: Int    -- ^ Σ κ as integer numerator
  , csCurvEuler       :: Int    -- ^ χ as integer numerator
  , csGaussBonnet     :: Bool
  , csCurvDenominator :: Int    -- ^ Rational denominator (10 or 20)
  } deriving (Show, Eq, Generic)

curvSummaryOptions :: Options
curvSummaryOptions = defaultOptions
  { fieldLabelModifier = dropFieldPrefix 2 }

instance ToJSON CurvatureSummary where
  toJSON     = genericToJSON     curvSummaryOptions
  toEncoding = genericToEncoding curvSummaryOptions

instance FromJSON CurvatureSummary where
  parseJSON = genericParseJSON curvSummaryOptions


-- ════════════════════════════════════════════════════════════════
--  Meta
-- ════════════════════════════════════════════════════════════════

-- | Server and data metadata from @data/meta.json@.
--
--   The JSON keys lack the @\"meta\"@ prefix, so a custom 'Options'
--   strips the four-character prefix and lowercases the remainder.
data Meta = Meta
  { metaVersion     :: Text  -- ^ Repository version, e.g. @\"0.5.0\"@
  , metaBuildDate   :: Text  -- ^ ISO 8601 UTC timestamp
  , metaAgdaVersion :: Text  -- ^ Agda compiler version
  , metaDataHash    :: Text  -- ^ SHA-256 prefix of the exported data
  } deriving (Show, Eq, Generic)

metaOptions :: Options
metaOptions = defaultOptions
  { fieldLabelModifier = dropFieldPrefix 4 }

instance ToJSON Meta where
  toJSON     = genericToJSON     metaOptions
  toEncoding = genericToEncoding metaOptions

instance FromJSON Meta where
  parseJSON = genericParseJSON metaOptions


-- ════════════════════════════════════════════════════════════════
--  Health
-- ════════════════════════════════════════════════════════════════

-- | Response for the @GET /health@ endpoint.
--
--   Constructed at runtime; not read from any file.
data Health = Health
  { status      :: Text  -- ^ @\"ok\"@ when all data loaded successfully
  , patchCount  :: Int   -- ^ Number of loaded patches
  , regionCount :: Int   -- ^ Total regions across all patches
  } deriving (Show, Eq, Generic)

instance ToJSON   Health
instance FromJSON Health