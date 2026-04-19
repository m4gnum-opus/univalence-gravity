/**
 * Tests for the typed API client (src/api/client.ts).
 *
 * Verifies:
 *   1. URL construction — each endpoint function builds the correct
 *      full URL from the base URL and endpoint path
 *   2. Successful responses — parsed JSON is returned correctly
 *   3. Error handling — non-2xx responses throw ApiError with the
 *      correct status code, statusText, and URL
 *   4. ApiError class — properties and inheritance
 *   5. Special characters in patch names — URL-encoded via
 *      encodeURIComponent
 *   6. Network errors — fetch rejections (TypeError) propagate
 *      without being wrapped in ApiError
 *   7. AbortSignal propagation — signals are forwarded to fetch
 *
 * Uses vi.fn() to mock the global fetch function. No network
 * requests are made — all responses are synthetic.
 *
 * The expected base URL is http://localhost:8080 (the fallback
 * default in client.ts, also set in .env). Tests are not coupled
 * to the .env file — if VITE_API_URL is unset, the fallback
 * produces the same value.
 *
 * NOTE on fetch arity (review issue #3):
 *   client.ts's fetchJson always calls fetch with TWO arguments:
 *     fetch(url, signal ? { signal } : undefined)
 *   When no signal is provided, the second argument is `undefined`.
 *   Vitest's toHaveBeenCalledWith performs exact argument matching:
 *   [url, undefined] ≠ [url]. To avoid arity mismatches, URL
 *   assertions check only the first argument via mock.calls[0][0]
 *   rather than using toHaveBeenCalledWith(url).
 *
 * NOTE on MOCK_PATCH schema (Phase 1, item 7):
 *   The `Patch` interface gained a required `patchGraph: PatchGraph`
 *   field carrying the full bulk graph (ALL cells + ALL physical
 *   bonds).  `18_export_json.py` now emits `patchGraph` for every
 *   patch, so MOCK_PATCH must include it to faithfully represent
 *   the actual API response shape.  This ensures that tests like
 *   "returns parsed Patch on success" which assert against the
 *   response structure don't drift from reality.
 *
 *   Although MOCK_PATCH is not explicitly typed as `Patch` (so a
 *   missing field wouldn't produce a TypeScript compilation error
 *   on its own), keeping the mock aligned with the real schema
 *   prevents subtle mock-vs-reality divergence and catches
 *   regressions if the API client ever starts inspecting the graph
 *   field.
 *
 * Reference:
 *   - src/api/client.ts (module under test)
 *   - docs/engineering/backend-spec-haskell.md §5 (API Endpoints)
 *   - Rules §11 (Testing Requirements)
 */

import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

import {
  fetchPatches,
  fetchPatch,
  fetchTower,
  fetchTheorems,
  fetchCurvature,
  fetchMeta,
  fetchHealth,
  ApiError,
} from "../src/api/client";

// ════════════════════════════════════════════════════════════════
//  Constants
// ════════════════════════════════════════════════════════════════

/**
 * The expected API base URL.
 *
 * client.ts reads `import.meta.env.VITE_API_URL` at module load
 * time, falling back to "http://localhost:8080". In the Vitest
 * environment (with .env or without), this resolves to the same
 * value.
 */
const BASE = "http://localhost:8080";

// ════════════════════════════════════════════════════════════════
//  Mock Data — Minimal Valid API Response Shapes
// ════════════════════════════════════════════════════════════════

/**
 * A minimal valid PatchSummary[] response (GET /patches).
 *
 * Contains two entries spanning different tilings and strategies
 * to ensure the client handles heterogeneous arrays.
 */
const MOCK_PATCHES = [
  {
    psName: "star",
    psTiling: "Tiling54",
    psDimension: 2,
    psCells: 6,
    psRegions: 10,
    psOrbits: 0,
    psMaxCut: 2,
    psStrategy: "BFS",
  },
  {
    psName: "dense-100",
    psTiling: "Tiling435",
    psDimension: 3,
    psCells: 100,
    psRegions: 717,
    psOrbits: 8,
    psMaxCut: 8,
    psStrategy: "Dense",
  },
];

/**
 * A minimal valid Patch response (GET /patches/:name).
 *
 * Includes non-null curvature and half-bound data to verify
 * the client handles the full response shape.
 *
 * NOTE (review issue #8): The region in patchRegionData includes
 * regionCurvature: null to match the actual API response shape.
 * Without this field the mock would be incomplete — while API
 * tests don't run type guards on mock data, the mock should
 * faithfully represent the real JSON schema.
 *
 * NOTE (Phase 1, item 7): The patchGraph field carries the full
 * bulk graph — ALL cell IDs in pgNodes (boundary + interior) and
 * ALL physical bonds in pgEdges (shared cube faces in 3D, shared
 * pentagon edges in 2D, tree edges for the Tree tiling).  This
 * field is emitted by 18_export_json.py for every patch and is
 * required by the Patch interface in src/types/index.ts.
 *
 * For dense-100: 100 cells (IDs 0–99) with 150 internal shared
 * faces.  A representative subset of edges is included — the API
 * client does not inspect the graph contents (it passes the full
 * Patch through to consumers), so a minimal structurally-valid
 * graph is sufficient for these tests.  The graph satisfies:
 *   - pgNodes is a number array
 *   - pgEdges is an array of sorted 2-element number arrays
 *   - all edge endpoints appear in pgNodes
 */
const MOCK_PATCH = {
  patchName: "dense-100",
  patchTiling: "Tiling435",
  patchDimension: 3,
  patchCells: 100,
  patchRegions: 717,
  patchOrbits: 8,
  patchMaxCut: 8,
  patchBonds: 150,
  patchBoundary: 300,
  patchDensity: 3.0,
  patchStrategy: "Dense",
  patchRegionData: [
    {
      regionId: 0,
      regionCells: [14],
      regionSize: 1,
      regionMinCut: 1,
      regionArea: 6,
      regionOrbit: "mc1",
      regionHalfSlack: 4,
      regionRatio: 0.1667,
      regionCurvature: null,
    },
  ],
  patchCurvature: {
    curvClasses: [
      {
        ccName: "ev5",
        ccCount: 12,
        ccValence: 5,
        ccKappa: -5,
        ccLocation: "interior",
      },
    ],
    curvTotal: -60,
    curvEuler: -60,
    curvGaussBonnet: true,
    curvDenominator: 20,
  },
  patchHalfBound: {
    hbRegionCount: 717,
    hbViolations: 0,
    hbAchieverCount: 40,
    hbAchieverSizes: [[1, 40]],
    hbSlackRange: [0, 14],
    hbMeanSlack: 6.0,
  },
  patchHalfBoundVerified: true,
  patchGraph: {
    pgNodes: Array.from({ length: 100 }, (_, i) => i),
    pgEdges: [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5]],
  },
};

/**
 * A minimal valid TowerLevel[] response (GET /tower).
 */
const MOCK_TOWER = [
  {
    tlPatchName: "dense-50",
    tlRegions: 139,
    tlOrbits: 0,
    tlMaxCut: 7,
    tlMonotone: null,
    tlHasBridge: true,
    tlHasAreaLaw: false,
    tlHasHalfBound: false,
  },
  {
    tlPatchName: "dense-100",
    tlRegions: 717,
    tlOrbits: 8,
    tlMaxCut: 8,
    tlMonotone: [1, "refl"],
    tlHasBridge: true,
    tlHasAreaLaw: true,
    tlHasHalfBound: true,
  },
];

/**
 * A minimal valid Theorem[] response (GET /theorems).
 */
const MOCK_THEOREMS = [
  {
    thmNumber: 1,
    thmName: "Discrete Ryu-Takayanagi",
    thmModule: "Bridge/GenericBridge.agda",
    thmStatement:
      "S_cut = L_min on every boundary region, for any patch, via a single generic theorem.",
    thmProofMethod:
      "isoToEquiv + ua + uaβ on contractible reversed singletons",
    thmStatus: "Verified",
  },
];

/**
 * A minimal valid CurvatureSummary[] response (GET /curvature).
 *
 * Note: JSON keys lack the "cs" prefix (stripped by Haskell Aeson).
 */
const MOCK_CURVATURE = [
  {
    patchName: "dense-100",
    tiling: "Tiling435",
    curvTotal: -60,
    curvEuler: -60,
    gaussBonnet: true,
    curvDenominator: 20,
  },
  {
    patchName: "filled",
    tiling: "Tiling54",
    curvTotal: 10,
    curvEuler: 10,
    gaussBonnet: true,
    curvDenominator: 10,
  },
];

/**
 * A minimal valid Meta response (GET /meta).
 *
 * Note: JSON keys lack the "meta" prefix (stripped by Haskell Aeson).
 */
const MOCK_META = {
  version: "0.6.0",
  buildDate: "2026-04-13T21:04:23Z",
  agdaVersion: "2.8.0",
  dataHash: "f8fcfb4dc6d9be08",
};

/**
 * A minimal valid Health response (GET /health).
 */
const MOCK_HEALTH = {
  status: "ok",
  patchCount: 14,
  regionCount: 5405,
};

// ════════════════════════════════════════════════════════════════
//  Mock Fetch Setup
// ════════════════════════════════════════════════════════════════

/**
 * Create a mock Response-like object.
 *
 * Uses a plain object implementing the subset of the Response
 * interface that client.ts accesses (ok, status, statusText, json).
 * This avoids depending on jsdom's Response constructor and keeps
 * the mock transparent.
 *
 * @param body - The JSON body to return from `.json()`.
 * @param status - HTTP status code (default 200).
 * @param statusText - HTTP status text (default "OK").
 */
function createMockResponse(
  body: unknown,
  status: number = 200,
  statusText: string = "OK",
): Response {
  return {
    ok: status >= 200 && status < 300,
    status,
    statusText,
    json: () => Promise.resolve(body),
    // Stub remaining Response interface members to satisfy TypeScript.
    // client.ts does not access any of these.
    headers: new Headers(),
    redirected: false,
    type: "basic" as ResponseType,
    url: "",
    clone: () => createMockResponse(body, status, statusText),
    body: null,
    bodyUsed: false,
    arrayBuffer: () => Promise.resolve(new ArrayBuffer(0)),
    blob: () => Promise.resolve(new Blob()),
    formData: () => Promise.resolve(new FormData()),
    text: () => Promise.resolve(JSON.stringify(body)),
    bytes: () => Promise.resolve(new Uint8Array()),
  } as Response;
}

/**
 * Module-level mock for the global fetch function.
 *
 * Reset before each test and restored after each test to prevent
 * cross-test pollution.
 */
let mockFetch: ReturnType<typeof vi.fn>;

beforeEach(() => {
  mockFetch = vi.fn();
  vi.stubGlobal("fetch", mockFetch);
});

afterEach(() => {
  vi.restoreAllMocks();
});

// ════════════════════════════════════════════════════════════════
//  ApiError Class
// ════════════════════════════════════════════════════════════════

describe("ApiError", () => {
  it("extends Error", () => {
    const err = new ApiError(404, "Not Found", `${BASE}/patches/missing`);
    expect(err).toBeInstanceOf(Error);
    expect(err).toBeInstanceOf(ApiError);
  });

  it("has name 'ApiError'", () => {
    const err = new ApiError(500, "Internal Server Error", `${BASE}/health`);
    expect(err.name).toBe("ApiError");
  });

  it("stores status and statusText", () => {
    const err = new ApiError(404, "Not Found", `${BASE}/patches/x`);
    expect(err.status).toBe(404);
    expect(err.statusText).toBe("Not Found");
  });

  it("includes status, statusText, and URL in the message", () => {
    const url = `${BASE}/patches/nonexistent`;
    const err = new ApiError(404, "Not Found", url);
    expect(err.message).toContain("404");
    expect(err.message).toContain("Not Found");
    expect(err.message).toContain(url);
  });

  it("produces a useful string representation", () => {
    const err = new ApiError(503, "Service Unavailable", `${BASE}/meta`);
    const str = String(err);
    expect(str).toContain("ApiError");
    expect(str).toContain("503");
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchPatches — GET /patches
// ════════════════════════════════════════════════════════════════

describe("fetchPatches", () => {
  it("calls fetch with the correct URL", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCHES));
    await fetchPatches();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches`);
  });

  it("returns parsed PatchSummary[] on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCHES));
    const result = await fetchPatches();

    expect(result).toEqual(MOCK_PATCHES);
    expect(Array.isArray(result)).toBe(true);
    expect(result).toHaveLength(2);
  });

  it("returns an empty array when the server responds with []", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse([]));
    const result = await fetchPatches();

    expect(result).toEqual([]);
    expect(result).toHaveLength(0);
  });

  it("throws ApiError on 500 Internal Server Error", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 500, "Internal Server Error"),
    );

    await expect(fetchPatches()).rejects.toThrow(ApiError);

    // Verify status and statusText are captured on the thrown error.
    // (Review issue #7: split mock setup and invocation into separate
    // statements instead of combining with &&.)
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 500, "Internal Server Error"),
    );
    await expect(fetchPatches()).rejects.toMatchObject({
      status: 500,
      statusText: "Internal Server Error",
    });
  });

  it("throws ApiError on 503 Service Unavailable", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 503, "Service Unavailable"),
    );

    try {
      await fetchPatches();
      expect.unreachable("Should have thrown");
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).status).toBe(503);
    }
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchPatch — GET /patches/:name
// ════════════════════════════════════════════════════════════════

describe("fetchPatch", () => {
  it("calls fetch with the correct URL for a simple patch name", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    await fetchPatch("dense-100");

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches/dense-100`);
  });

  it("URL-encodes the patch name", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    await fetchPatch("layer-54-d7");

    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches/layer-54-d7`);
  });

  it("URL-encodes special characters in the patch name", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    // A hypothetical patch name with characters that need encoding.
    // encodeURIComponent("foo bar") → "foo%20bar"
    await fetchPatch("foo bar");

    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches/foo%20bar`);
  });

  it("URL-encodes slashes in the patch name", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    await fetchPatch("a/b");

    // encodeURIComponent("a/b") → "a%2Fb"
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches/a%2Fb`);
  });

  it("returns parsed Patch on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    const result = await fetchPatch("dense-100");

    expect(result).toEqual(MOCK_PATCH);
    expect(result.patchName).toBe("dense-100");
    expect(result.patchRegionData).toHaveLength(1);
    expect(result.patchCurvature).not.toBeNull();
    expect(result.patchHalfBound).not.toBeNull();
    expect(result.patchHalfBoundVerified).toBe(true);
  });

  it("preserves the patchGraph field in the returned Patch", async () => {
    // Phase 1, item 7: the Patch interface requires a patchGraph
    // field carrying the full bulk graph.  18_export_json.py emits
    // this field for every patch.  Verify that the API client
    // passes it through intact (the client does not inspect or
    // transform response bodies — it returns the parsed JSON as-is).
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    const result = await fetchPatch("dense-100");

    expect(result.patchGraph).toBeDefined();
    expect(result.patchGraph.pgNodes).toHaveLength(100);
    expect(result.patchGraph.pgEdges).toEqual([
      [0, 1], [1, 2], [2, 3], [3, 4], [4, 5],
    ]);
  });

  it("returns a Patch with null curvature and halfBound", async () => {
    const patchNulls = {
      ...MOCK_PATCH,
      patchName: "tree",
      patchCurvature: null,
      patchHalfBound: null,
      patchHalfBoundVerified: false,
    };
    mockFetch.mockResolvedValueOnce(createMockResponse(patchNulls));
    const result = await fetchPatch("tree");

    expect(result.patchCurvature).toBeNull();
    expect(result.patchHalfBound).toBeNull();
    expect(result.patchHalfBoundVerified).toBe(false);
  });

  it("throws ApiError with status 404 for nonexistent patch", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 404, "Not Found"),
    );

    try {
      await fetchPatch("nonexistent");
      expect.unreachable("Should have thrown ApiError");
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      const apiErr = err as ApiError;
      expect(apiErr.status).toBe(404);
      expect(apiErr.statusText).toBe("Not Found");
      expect(apiErr.message).toContain("nonexistent");
    }
  });

  it("throws ApiError on 500 for a valid patch name", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 500, "Internal Server Error"),
    );

    await expect(fetchPatch("star")).rejects.toThrow(ApiError);
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchTower — GET /tower
// ════════════════════════════════════════════════════════════════

describe("fetchTower", () => {
  it("calls fetch with the correct URL", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_TOWER));
    await fetchTower();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/tower`);
  });

  it("returns parsed TowerLevel[] on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_TOWER));
    const result = await fetchTower();

    expect(result).toEqual(MOCK_TOWER);
    expect(Array.isArray(result)).toBe(true);
    expect(result).toHaveLength(2);
    // Verify null monotone (first level of sub-tower)
    expect(result[0]?.tlMonotone).toBeNull();
    // Verify tuple monotone
    expect(result[1]?.tlMonotone).toEqual([1, "refl"]);
  });

  it("throws ApiError on non-2xx response", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 502, "Bad Gateway"),
    );

    await expect(fetchTower()).rejects.toThrow(ApiError);
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchTheorems — GET /theorems
// ════════════════════════════════════════════════════════════════

describe("fetchTheorems", () => {
  it("calls fetch with the correct URL", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_THEOREMS));
    await fetchTheorems();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/theorems`);
  });

  it("returns parsed Theorem[] on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_THEOREMS));
    const result = await fetchTheorems();

    expect(result).toEqual(MOCK_THEOREMS);
    expect(result[0]?.thmNumber).toBe(1);
    expect(result[0]?.thmStatus).toBe("Verified");
  });

  it("throws ApiError on 500", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 500, "Internal Server Error"),
    );

    await expect(fetchTheorems()).rejects.toThrow(ApiError);
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchCurvature — GET /curvature
// ════════════════════════════════════════════════════════════════

describe("fetchCurvature", () => {
  it("calls fetch with the correct URL", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_CURVATURE));
    await fetchCurvature();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/curvature`);
  });

  it("returns parsed CurvatureSummary[] on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_CURVATURE));
    const result = await fetchCurvature();

    expect(result).toEqual(MOCK_CURVATURE);
    expect(result).toHaveLength(2);
    // Verify that the JSON keys use stripped prefixes (no "cs" prefix)
    expect(result[0]?.patchName).toBe("dense-100");
    expect(result[0]?.curvDenominator).toBe(20);
    expect(result[1]?.patchName).toBe("filled");
    expect(result[1]?.curvDenominator).toBe(10);
  });

  it("throws ApiError on non-2xx response", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 503, "Service Unavailable"),
    );

    await expect(fetchCurvature()).rejects.toThrow(ApiError);
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchMeta — GET /meta
// ════════════════════════════════════════════════════════════════

describe("fetchMeta", () => {
  it("calls fetch with the correct URL", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_META));
    await fetchMeta();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/meta`);
  });

  it("returns parsed Meta on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_META));
    const result = await fetchMeta();

    expect(result).toEqual(MOCK_META);
    // Verify that the JSON keys use stripped prefixes (no "meta" prefix)
    expect(result.version).toBe("0.6.0");
    expect(result.agdaVersion).toBe("2.8.0");
    expect(result.dataHash).toBe("f8fcfb4dc6d9be08");
    expect(result.buildDate).toBe("2026-04-13T21:04:23Z");
  });

  it("throws ApiError on 500", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 500, "Internal Server Error"),
    );

    await expect(fetchMeta()).rejects.toThrow(ApiError);
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchHealth — GET /health
// ════════════════════════════════════════════════════════════════

describe("fetchHealth", () => {
  it("calls fetch with the correct URL", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_HEALTH));
    await fetchHealth();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/health`);
  });

  it("returns parsed Health on success", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_HEALTH));
    const result = await fetchHealth();

    expect(result).toEqual(MOCK_HEALTH);
    expect(result.status).toBe("ok");
    expect(result.patchCount).toBe(14);
    expect(result.regionCount).toBe(5405);
  });

  it("throws ApiError on non-2xx response", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 503, "Service Unavailable"),
    );

    await expect(fetchHealth()).rejects.toThrow(ApiError);
  });
});

// ════════════════════════════════════════════════════════════════
//  Cross-Cutting: AbortSignal Propagation (review issue #5)
// ════════════════════════════════════════════════════════════════

describe("AbortSignal propagation", () => {
  /**
   * client.ts passes the AbortSignal to fetch via:
   *   fetch(url, signal ? { signal } : undefined)
   *
   * When a signal IS provided, the second argument should be
   * { signal: controller.signal }. These tests verify that the
   * signal reaches fetch for every endpoint function.
   */

  it("passes the AbortSignal through to fetch for fetchPatches", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCHES));
    await fetchPatches(controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches`);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes the AbortSignal through to fetch for fetchPatch", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCH));
    await fetchPatch("dense-100", controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}/patches/dense-100`);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes the AbortSignal through to fetch for fetchTower", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_TOWER));
    await fetchTower(controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes the AbortSignal through to fetch for fetchTheorems", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_THEOREMS));
    await fetchTheorems(controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes the AbortSignal through to fetch for fetchCurvature", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_CURVATURE));
    await fetchCurvature(controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes the AbortSignal through to fetch for fetchMeta", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_META));
    await fetchMeta(controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes the AbortSignal through to fetch for fetchHealth", async () => {
    const controller = new AbortController();
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_HEALTH));
    await fetchHealth(controller.signal);

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[1]).toEqual({ signal: controller.signal });
  });

  it("passes undefined as the second argument when no signal is provided", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCHES));
    await fetchPatches();

    expect(mockFetch).toHaveBeenCalledTimes(1);
    expect(mockFetch.mock.calls[0]?.[1]).toBeUndefined();
  });
});

// ════════════════════════════════════════════════════════════════
//  Cross-Cutting: Network Errors
// ════════════════════════════════════════════════════════════════

describe("network errors", () => {
  it("propagates TypeError on DNS failure (fetch rejects)", async () => {
    mockFetch.mockRejectedValueOnce(new TypeError("Failed to fetch"));

    await expect(fetchPatches()).rejects.toThrow(TypeError);

    // Also verify the message string propagates.
    // (Review issue #7: split mock setup and invocation into
    // separate statements instead of combining with &&.)
    mockFetch.mockRejectedValueOnce(new TypeError("Failed to fetch"));
    await expect(fetchPatches()).rejects.toThrow("Failed to fetch");
  });

  it("propagates TypeError on network error for fetchPatch", async () => {
    mockFetch.mockRejectedValueOnce(
      new TypeError("NetworkError when attempting to fetch resource"),
    );

    await expect(fetchPatch("star")).rejects.toThrow(TypeError);
  });

  it("does NOT wrap network TypeError in ApiError", async () => {
    mockFetch.mockRejectedValueOnce(new TypeError("Failed to fetch"));

    try {
      await fetchMeta();
      expect.unreachable("Should have thrown");
    } catch (err) {
      expect(err).toBeInstanceOf(TypeError);
      expect(err).not.toBeInstanceOf(ApiError);
    }
  });
});

// ════════════════════════════════════════════════════════════════
//  Cross-Cutting: HTTP Status Edge Cases
// ════════════════════════════════════════════════════════════════

describe("HTTP status edge cases", () => {
  it("treats 200 as success (response.ok = true)", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_PATCHES, 200));
    const result = await fetchPatches();

    expect(result).toEqual(MOCK_PATCHES);
  });

  it("treats 201 as success (response.ok = true for 2xx)", async () => {
    // While the backend only returns 200, the client should handle
    // any 2xx status as success per the fetch API spec.
    mockFetch.mockResolvedValueOnce(
      createMockResponse(MOCK_PATCHES, 201, "Created"),
    );
    const result = await fetchPatches();

    expect(result).toEqual(MOCK_PATCHES);
  });

  it("treats 299 as success (upper boundary of 2xx range)", async () => {
    mockFetch.mockResolvedValueOnce(createMockResponse(MOCK_META, 299));
    const result = await fetchMeta();

    expect(result).toEqual(MOCK_META);
  });

  it("treats 300 as an error (response.ok = false for 3xx)", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 300, "Multiple Choices"),
    );

    await expect(fetchMeta()).rejects.toThrow(ApiError);
  });

  it("treats 400 Bad Request as an error", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 400, "Bad Request"),
    );

    try {
      await fetchTower();
      expect.unreachable("Should have thrown ApiError");
    } catch (err) {
      expect(err).toBeInstanceOf(ApiError);
      expect((err as ApiError).status).toBe(400);
    }
  });

  it("treats 401 Unauthorized as an error", async () => {
    // The backend has no auth, but test the client handles it gracefully.
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 401, "Unauthorized"),
    );

    await expect(fetchTheorems()).rejects.toThrow(ApiError);
  });

  it("includes the full URL in the ApiError for fetchPatch 404", async () => {
    mockFetch.mockResolvedValueOnce(
      createMockResponse(null, 404, "Not Found"),
    );

    try {
      await fetchPatch("does-not-exist");
      expect.unreachable("Should have thrown ApiError");
    } catch (err) {
      const apiErr = err as ApiError;
      expect(apiErr.message).toContain(`${BASE}/patches/does-not-exist`);
    }
  });
});

// ════════════════════════════════════════════════════════════════
//  Cross-Cutting: Fetch Called Exactly Once Per Invocation
// ════════════════════════════════════════════════════════════════

describe("fetch invocation count", () => {
  it("each function calls fetch exactly once", async () => {
    // Set up 7 mock responses for 7 sequential calls.
    mockFetch
      .mockResolvedValueOnce(createMockResponse(MOCK_PATCHES))
      .mockResolvedValueOnce(createMockResponse(MOCK_PATCH))
      .mockResolvedValueOnce(createMockResponse(MOCK_TOWER))
      .mockResolvedValueOnce(createMockResponse(MOCK_THEOREMS))
      .mockResolvedValueOnce(createMockResponse(MOCK_CURVATURE))
      .mockResolvedValueOnce(createMockResponse(MOCK_META))
      .mockResolvedValueOnce(createMockResponse(MOCK_HEALTH));

    await fetchPatches();
    await fetchPatch("star");
    await fetchTower();
    await fetchTheorems();
    await fetchCurvature();
    await fetchMeta();
    await fetchHealth();

    expect(mockFetch).toHaveBeenCalledTimes(7);
  });
});

// ════════════════════════════════════════════════════════════════
//  URL Construction — Comprehensive Endpoint Path Verification
// ════════════════════════════════════════════════════════════════

describe("URL construction — all 7 endpoints", () => {
  /**
   * Parametric test confirming each endpoint function constructs
   * the expected URL. This is the core "URL construction" test
   * from the elaboration order specification.
   *
   * Uses mock.calls[0][0] to check only the URL (first argument),
   * avoiding the arity mismatch with the optional second argument
   * (review issue #3).
   */

  const endpointCases: Array<{
    name: string;
    invoke: () => Promise<unknown>;
    expectedPath: string;
  }> = [
    {
      name: "fetchPatches",
      invoke: () => fetchPatches(),
      expectedPath: "/patches",
    },
    {
      name: "fetchPatch('star')",
      invoke: () => fetchPatch("star"),
      expectedPath: "/patches/star",
    },
    {
      name: "fetchPatch('dense-100')",
      invoke: () => fetchPatch("dense-100"),
      expectedPath: "/patches/dense-100",
    },
    {
      name: "fetchPatch('layer-54-d7')",
      invoke: () => fetchPatch("layer-54-d7"),
      expectedPath: "/patches/layer-54-d7",
    },
    {
      name: "fetchTower",
      invoke: () => fetchTower(),
      expectedPath: "/tower",
    },
    {
      name: "fetchTheorems",
      invoke: () => fetchTheorems(),
      expectedPath: "/theorems",
    },
    {
      name: "fetchCurvature",
      invoke: () => fetchCurvature(),
      expectedPath: "/curvature",
    },
    {
      name: "fetchMeta",
      invoke: () => fetchMeta(),
      expectedPath: "/meta",
    },
    {
      name: "fetchHealth",
      invoke: () => fetchHealth(),
      expectedPath: "/health",
    },
  ];

  it.each(endpointCases)(
    "$name → $expectedPath",
    async ({ invoke, expectedPath }) => {
      // Return a generic valid response for all endpoints.
      mockFetch.mockResolvedValueOnce(createMockResponse({}));
      await invoke();

      expect(mockFetch.mock.calls[0]?.[0]).toBe(`${BASE}${expectedPath}`);
    },
  );
});