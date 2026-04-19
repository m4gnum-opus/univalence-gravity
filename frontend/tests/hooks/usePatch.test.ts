/**
 * Tests for the usePatch custom hook (src/hooks/usePatch.ts).
 *
 * Verifies the full hook lifecycle:
 *
 *   1. Initial loading state (loading=true, data=null, error=null)
 *   2. Successful fetch → data populated, loading=false, error=null
 *   3. Error handling:
 *      - 404 ApiError → "Patch not found: {name}"
 *      - General ApiError (500) → error message from ApiError
 *      - Network failure (TypeError) → error message propagated
 *      - Non-Error rejection → fallback "Failed to fetch patch"
 *   4. Empty name → no fetch, error "No patch name provided", loading=false
 *   5. Name change triggers re-fetch with new name
 *   6. Data resets to null when name changes (before new fetch resolves)
 *   7. Cancellation on unmount prevents stale state updates
 *   8. Cancellation via AbortError is silently swallowed
 *   9. fetchPatch is called with the correct patch name argument
 *
 * Uses `vi.mock` to replace the API client module with a controllable
 * mock. The `ApiError` class is replicated in the mock factory so that
 * `instanceof` checks in the hook work correctly — both the hook and
 * the test import from the same mocked module.
 *
 * Uses `renderHook` from `@testing-library/react` for hook lifecycle
 * testing and `waitFor` for asserting async state transitions.
 *
 * NOTE on fetchPatch call arity (review issue #3):
 *   The usePatch hook calls `fetchPatch(name, controller.signal)` —
 *   always TWO arguments. Vitest's `toHaveBeenCalledWith` performs
 *   exact argument matching: `["star", <AbortSignal>]` ≠ `["star"]`.
 *   All assertions on fetchPatch call arguments use
 *   `expect.anything()` for the signal parameter to avoid arity
 *   mismatches while still verifying the name argument.
 *
 * NOTE on AbortSignal-responsive mocks:
 *   Several cancellation tests use `mockImplementationOnce` to create
 *   promises that listen for the `abort` event on the real AbortSignal
 *   passed by the hook. This accurately simulates production `fetch`
 *   behavior: when the hook's cleanup calls `controller.abort()`, the
 *   mock rejects with DOMException("AbortError"), and the hook's
 *   catch/finally logic executes with `controller.signal.aborted === true`.
 *   Earlier versions used `mockRejectedValueOnce` which couldn't
 *   coordinate with the real AbortController lifecycle.
 *
 * NOTE on DOMException inheritance in jsdom:
 *   In jsdom (the test environment), `DOMException` may not extend
 *   `Error` in the prototype chain. This means `err instanceof Error`
 *   can return `false` for DOMException instances. Tests that exercise
 *   non-AbortError DOMExceptions verify the error is surfaced (not
 *   silently swallowed) without depending on the specific message
 *   string, since the hook's fallback path varies by runtime.
 *
 * NOTE on Phase 1 item 7 (patchGraph field):
 *   The `Patch` interface was extended in Phase 1 to include a required
 *   `patchGraph: PatchGraph` field carrying the full bulk graph (all
 *   cells + all physical bonds).  Post-Poincaré projection updates
 *   (Fix C), the wire schema tightened:
 *     - `pgNodes` is `GraphNode[]` — objects carrying per-cell Poincaré
 *       position, rotation quaternion, and conformal scale.
 *     - `pgEdges` is `Edge[]` — `{source, target}` objects.
 *   Mock data typed as `Patch` (MOCK_STAR, MOCK_DENSE) must conform to
 *   this schema or TypeScript compilation fails under `strict: true`.
 *   The `mkNode` / `mkEdge` helpers below produce minimal structurally-
 *   valid fixtures.  The hook does not inspect the graph contents; it
 *   simply passes the full Patch through to the consumer.
 *
 * Reference:
 *   - src/hooks/usePatch.ts (module under test)
 *   - src/api/client.ts (mocked dependency)
 *   - src/types/index.ts (Patch, PatchGraph, GraphNode, Edge)
 *   - Rules §7 (State Management — hook pattern)
 *   - Rules §11 (Testing Requirements — hook lifecycle with renderHook)
 */

import { describe, it, expect, vi, beforeEach } from "vitest";
import { renderHook, waitFor } from "@testing-library/react";

import type { Patch, GraphNode, Edge } from "../../src/types";

// ════════════════════════════════════════════════════════════════
//  Module Mock
// ════════════════════════════════════════════════════════════════

/**
 * Mock the API client module.
 *
 * `vi.mock` is hoisted to the top of the file by Vitest, so the
 * factory function runs before any imports. Both `fetchPatch` and
 * `ApiError` are replaced:
 *
 *   - `fetchPatch` → `vi.fn()` (controllable per-test via
 *     `.mockResolvedValueOnce`, `.mockRejectedValueOnce`, etc.)
 *
 *   - `ApiError` → a class with the same `status`, `statusText`,
 *     and `name` properties as the real `ApiError`. This ensures
 *     that `err instanceof ApiError` checks in the hook resolve
 *     correctly against instances created in test code, because
 *     both the hook and the test import `ApiError` from the same
 *     mocked module.
 */
vi.mock("../../src/api/client", () => ({
  fetchPatch: vi.fn(),
  ApiError: class ApiError extends Error {
    public readonly status: number;
    public readonly statusText: string;
    constructor(status: number, statusText: string, url: string) {
      super(`API request failed: ${status} ${statusText} (${url})`);
      this.name = "ApiError";
      this.status = status;
      this.statusText = statusText;
    }
  },
}));

// Import the mocked module. After `vi.mock`, these are the mock
// implementations from the factory above.
import { fetchPatch, ApiError } from "../../src/api/client";
import { usePatch } from "../../src/hooks/usePatch";

/**
 * Typed reference to the mocked `fetchPatch` function.
 *
 * `vi.mocked()` is a type-only helper — it casts the import to
 * `MockedFunction<typeof fetchPatch>`, giving access to mock
 * control methods (`.mockResolvedValueOnce`, `.mockReset`, etc.)
 * without any runtime effect.
 */
const mockFetchPatch = vi.mocked(fetchPatch);

// ════════════════════════════════════════════════════════════════
//  Graph Fixture Helpers
// ════════════════════════════════════════════════════════════════

/**
 * Build a structurally valid {@link GraphNode} fixture.
 *
 * Defaults place the node at the Poincaré origin with the identity
 * quaternion and the central conformal scale `s(0) = 0.5`.  These
 * tests do not inspect geometric fields (the hook is a pure pass-
 * through), so the defaults suffice.
 *
 * Mirrors the fixture factories used by `types.test.ts` and
 * `PatchScene.test.tsx` so all three suites exercise the same
 * wire shape.
 */
function mkNode(id: number): GraphNode {
  return { id, x: 0, y: 0, z: 0, qx: 0, qy: 0, qz: 0, qw: 1, scale: 0.5 };
}

/**
 * Build a structurally valid {@link Edge} fixture — `{source, target}`
 * per the wire format emitted by `18_export_json.py::_make_patch_graph`.
 */
function mkEdge(source: number, target: number): Edge {
  return { source, target };
}

// ════════════════════════════════════════════════════════════════
//  Mock Data
// ════════════════════════════════════════════════════════════════

/**
 * A minimal valid Patch object matching the star patch shape.
 *
 * Used as the first fetch result in name-change tests. The
 * `patchRegionData` is empty for brevity — the hook does not
 * inspect region data; it passes the full Patch through to
 * the consumer.
 *
 * The `patchGraph` field (Phase 1 item 7) is the star patch's
 * bulk graph: 6 nodes (cells 0–4 are boundary N-tiles, cell 5 is
 * the interior central tile C) and 5 physical bonds (each C–Ni
 * shared pentagon edge). This matches the actual star.json export
 * produced by `18_export_json.py`. Without this field, TypeScript
 * compilation fails because `Patch.patchGraph` is required.
 */
const MOCK_STAR: Patch = {
  patchName: "star",
  patchTiling: "Tiling54",
  patchDimension: 2,
  patchCells: 6,
  patchRegions: 10,
  patchOrbits: 0,
  patchMaxCut: 2,
  patchBonds: 5,
  patchBoundary: 20,
  patchDensity: 1.67,
  patchStrategy: "BFS",
  patchRegionData: [],
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: false,
  patchGraph: {
    pgNodes: [
      mkNode(0), mkNode(1), mkNode(2),
      mkNode(3), mkNode(4), mkNode(5),
    ],
    pgEdges: [
      mkEdge(0, 5), mkEdge(1, 5), mkEdge(2, 5),
      mkEdge(3, 5), mkEdge(4, 5),
    ],
  },
};

/**
 * A minimal valid Patch object matching the dense-100 patch shape.
 *
 * Used as the primary fetch result in most tests. Includes non-null
 * `patchHalfBoundVerified` to verify the full Patch shape is
 * preserved through the hook.
 *
 * NOTE: The region in patchRegionData includes `regionCurvature: null`
 * to match the actual API response shape and satisfy the Region
 * interface's required field. Without this field, TypeScript
 * compilation fails under `strict: true` because the Region type
 * requires `regionCurvature: number | null`.
 *
 * The `patchGraph` field (Phase 1 item 7) contains 100 nodes (one
 * per cell, cells 0–99) and a representative subset of edges. The
 * hook does not inspect the graph contents; this minimal graph
 * satisfies the structural shape required by the `Patch` type guard
 * (`pgNodes` is a number array, `pgEdges` is an array of 2-element
 * numeric arrays). For realism, more edges would be included to
 * match `patchBonds: 150`, but since the hook passes the full Patch
 * through without inspection, a smaller edge list is sufficient
 * for these tests.
 */
const MOCK_DENSE: Patch = {
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
  patchCurvature: null,
  patchHalfBound: null,
  patchHalfBoundVerified: true,
  patchGraph: {
    pgNodes: Array.from({ length: 100 }, (_, i) => mkNode(i)),
    pgEdges: [
      mkEdge(0, 1), mkEdge(1, 2), mkEdge(2, 3),
      mkEdge(3, 4), mkEdge(4, 5),
    ],
  },
};

// ════════════════════════════════════════════════════════════════
//  Test Setup
// ════════════════════════════════════════════════════════════════

beforeEach(() => {
  // Reset the mock between tests to prevent cross-test pollution.
  // `mockReset` clears all mock state: call history, return values,
  // implementation. Each test sets up its own mock behavior.
  mockFetchPatch.mockReset();
});

// ════════════════════════════════════════════════════════════════
//  Initial State
// ════════════════════════════════════════════════════════════════

describe("initial state", () => {
  it("starts with loading=true, data=null, error=null", () => {
    // Use a never-resolving promise so the fetch doesn't complete
    // during act(). This guarantees that the initial loading state
    // is observed before any async resolution.
    mockFetchPatch.mockReturnValueOnce(new Promise<Patch>(() => {}));

    const { result } = renderHook(() => usePatch("dense-100"));

    expect(result.current.loading).toBe(true);
    expect(result.current.data).toBeNull();
    expect(result.current.error).toBeNull();
  });
});

// ════════════════════════════════════════════════════════════════
//  Successful Fetch
// ════════════════════════════════════════════════════════════════

describe("successful fetch", () => {
  it("populates data and clears loading on success", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);

    const { result } = renderHook(() => usePatch("dense-100"));

    // Wait for the fetch to resolve and loading to become false.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toEqual(MOCK_DENSE);
    expect(result.current.error).toBeNull();
  });

  it("preserves the full Patch shape including region data", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    const patch = result.current.data;
    expect(patch).not.toBeNull();
    expect(patch!.patchName).toBe("dense-100");
    expect(patch!.patchTiling).toBe("Tiling435");
    expect(patch!.patchMaxCut).toBe(8);
    expect(patch!.patchHalfBoundVerified).toBe(true);
    expect(patch!.patchRegionData).toHaveLength(1);
    expect(patch!.patchRegionData[0]?.regionMinCut).toBe(1);
  });

  it("preserves the patchGraph field through the hook", async () => {
    // Phase 1 item 7: patchGraph must be passed through unchanged
    // from the API response to the consumer. The hook does not
    // inspect or transform the graph; it simply forwards it.
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    const patch = result.current.data;
    expect(patch).not.toBeNull();
    expect(patch!.patchGraph).toBeDefined();
    expect(patch!.patchGraph.pgNodes[0]).toEqual(mkNode(0));
    expect(patch!.patchGraph.pgEdges).toEqual([
      mkEdge(0, 1), mkEdge(1, 2), mkEdge(2, 3),
      mkEdge(3, 4), mkEdge(4, 5),
    ]);
  });

  it("calls fetchPatch with the provided patch name", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_STAR);

    renderHook(() => usePatch("star"));

    await waitFor(() => {
      expect(mockFetchPatch).toHaveBeenCalledTimes(1);
    });

    // Review issue #3: the hook calls fetchPatch(name, controller.signal),
    // so we use expect.anything() for the signal to avoid arity mismatch.
    expect(mockFetchPatch).toHaveBeenCalledWith("star", expect.anything());
  });
});

// ════════════════════════════════════════════════════════════════
//  Error Handling — 404 (Nonexistent Patch)
// ════════════════════════════════════════════════════════════════

describe("error handling — 404", () => {
  it("sets a specific 'Patch not found' error for 404 responses", async () => {
    mockFetchPatch.mockRejectedValueOnce(
      new ApiError(404, "Not Found", "http://localhost:8080/patches/nonexistent"),
    );

    const { result } = renderHook(() => usePatch("nonexistent"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("Patch not found: nonexistent");
    expect(result.current.data).toBeNull();
  });

  it("includes the patch name in the 404 error message", async () => {
    mockFetchPatch.mockRejectedValueOnce(
      new ApiError(404, "Not Found", "http://localhost:8080/patches/layer-54-d99"),
    );

    const { result } = renderHook(() => usePatch("layer-54-d99"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toContain("layer-54-d99");
  });
});

// ════════════════════════════════════════════════════════════════
//  Error Handling — General API Errors
// ════════════════════════════════════════════════════════════════

describe("error handling — general API errors", () => {
  it("surfaces the ApiError message for non-404 server errors", async () => {
    const error = new ApiError(
      500,
      "Internal Server Error",
      "http://localhost:8080/patches/dense-100",
    );
    mockFetchPatch.mockRejectedValueOnce(error);

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    // The hook uses err.message for non-404 ApiErrors.
    expect(result.current.error).toBe(error.message);
    expect(result.current.data).toBeNull();
  });

  it("surfaces the message for 503 Service Unavailable", async () => {
    const error = new ApiError(
      503,
      "Service Unavailable",
      "http://localhost:8080/patches/star",
    );
    mockFetchPatch.mockRejectedValueOnce(error);

    const { result } = renderHook(() => usePatch("star"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toContain("503");
    expect(result.current.error).toContain("Service Unavailable");
    expect(result.current.data).toBeNull();
  });
});

// ════════════════════════════════════════════════════════════════
//  Error Handling — Network Failures
// ════════════════════════════════════════════════════════════════

describe("error handling — network failures", () => {
  it("surfaces TypeError message for network failures", async () => {
    mockFetchPatch.mockRejectedValueOnce(
      new TypeError("Failed to fetch"),
    );

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("Failed to fetch");
    expect(result.current.data).toBeNull();
  });

  it("uses fallback message for non-Error rejections", async () => {
    // The hook's catch block handles non-Error values with a
    // fallback message "Failed to fetch patch".
    mockFetchPatch.mockRejectedValueOnce("unexpected string error");

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("Failed to fetch patch");
    expect(result.current.data).toBeNull();
  });

  it("uses fallback message when rejecting with null", async () => {
    mockFetchPatch.mockRejectedValueOnce(null);

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("Failed to fetch patch");
  });
});

// ════════════════════════════════════════════════════════════════
//  Empty Name Handling
// ════════════════════════════════════════════════════════════════

describe("empty name handling", () => {
  it("sets error immediately for empty string without fetching", async () => {
    const { result } = renderHook(() => usePatch(""));

    // The hook handles empty name synchronously in the effect:
    // setData(null), setLoading(false), setError("No patch name provided")
    // These are flushed by act() during renderHook.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("No patch name provided");
    expect(result.current.data).toBeNull();

    // Verify that fetchPatch was never called.
    expect(mockFetchPatch).not.toHaveBeenCalled();
  });

  it("does not call fetchPatch for empty name", () => {
    renderHook(() => usePatch(""));
    expect(mockFetchPatch).not.toHaveBeenCalled();
  });
});

// ════════════════════════════════════════════════════════════════
//  Name Change — Re-Fetching
// ════════════════════════════════════════════════════════════════

describe("name change", () => {
  it("re-fetches when name changes", async () => {
    // Set up mock for the first name.
    mockFetchPatch.mockResolvedValueOnce(MOCK_STAR);

    const { result, rerender } = renderHook(
      ({ name }: { name: string }) => usePatch(name),
      { initialProps: { name: "star" } },
    );

    // Wait for the first fetch to complete.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.data).toEqual(MOCK_STAR);
    expect(result.current.error).toBeNull();

    // Set up mock for the second name and change the name.
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);
    rerender({ name: "dense-100" });

    // Wait for the second fetch to complete.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.data).toEqual(MOCK_DENSE);
    expect(result.current.data?.patchName).toBe("dense-100");
    expect(result.current.error).toBeNull();

    // fetchPatch should have been called twice (once per name).
    // Review issue #3: use expect.anything() for the signal argument.
    expect(mockFetchPatch).toHaveBeenCalledTimes(2);
    expect(mockFetchPatch).toHaveBeenNthCalledWith(1, "star", expect.anything());
    expect(mockFetchPatch).toHaveBeenNthCalledWith(2, "dense-100", expect.anything());
  });

  it("resets data to null before re-fetching with new name", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_STAR);

    const { result, rerender } = renderHook(
      ({ name }: { name: string }) => usePatch(name),
      { initialProps: { name: "star" } },
    );

    // Wait for first fetch.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.data).toEqual(MOCK_STAR);

    // Set up a never-resolving promise for the second name so
    // we can observe the intermediate loading state.
    mockFetchPatch.mockReturnValueOnce(new Promise<Patch>(() => {}));
    rerender({ name: "dense-100" });

    // After rerender, the effect resets state before the new fetch
    // completes: loading=true, data=null, error=null.
    expect(result.current.loading).toBe(true);
    expect(result.current.data).toBeNull();
    expect(result.current.error).toBeNull();
  });

  it("transitions from valid name to empty name", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_STAR);

    const { result, rerender } = renderHook(
      ({ name }: { name: string }) => usePatch(name),
      { initialProps: { name: "star" } },
    );

    // Wait for first fetch.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.data).toEqual(MOCK_STAR);

    // Change to empty name.
    rerender({ name: "" });

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("No patch name provided");
    expect(result.current.data).toBeNull();

    // fetchPatch should only have been called once (for "star").
    // The empty name skips the fetch entirely.
    expect(mockFetchPatch).toHaveBeenCalledTimes(1);
  });

  it("transitions from empty name to valid name", async () => {
    const { result, rerender } = renderHook(
      ({ name }: { name: string }) => usePatch(name),
      { initialProps: { name: "" } },
    );

    // Empty name: immediate error, no fetch.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.error).toBe("No patch name provided");
    expect(mockFetchPatch).not.toHaveBeenCalled();

    // Change to a valid name.
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);
    rerender({ name: "dense-100" });

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });
    expect(result.current.data).toEqual(MOCK_DENSE);
    expect(result.current.error).toBeNull();
    expect(mockFetchPatch).toHaveBeenCalledTimes(1);
    // Review issue #3: use expect.anything() for the signal argument.
    expect(mockFetchPatch).toHaveBeenCalledWith("dense-100", expect.anything());
  });
});

// ════════════════════════════════════════════════════════════════
//  Cancellation on Unmount
// ════════════════════════════════════════════════════════════════

describe("cancellation on unmount", () => {
  it("does not update state after unmount (no React warnings)", async () => {
    // Create a controllable promise that we resolve AFTER unmount.
    // The hook's `cancelled` flag should prevent any state update
    // from reaching the unmounted component.
    let resolvePromise: ((value: Patch) => void) | undefined;
    mockFetchPatch.mockReturnValueOnce(
      new Promise<Patch>((resolve) => {
        resolvePromise = resolve;
      }),
    );

    const { result, unmount } = renderHook(() => usePatch("dense-100"));

    // Verify loading state before unmount.
    expect(result.current.loading).toBe(true);

    // Unmount the hook — this triggers the effect cleanup, setting
    // the `cancelled` flag to `true`.
    unmount();

    // Resolve the promise after unmount. The hook's `cancelled`
    // flag prevents `setData`, `setLoading`, and `setError` from
    // being called. If cancellation failed, React would emit a
    // "Can't perform a React state update on an unmounted component"
    // warning (React <18) or silently ignore the update (React 18+).
    //
    // We verify that reaching this point does not throw.
    if (resolvePromise) {
      resolvePromise(MOCK_DENSE);
    }

    // Allow any pending microtasks to process.
    await new Promise((resolve) => setTimeout(resolve, 0));

    // If we reach here without errors, cancellation worked.
    // The result.current reflects the state at the time of unmount.
    expect(result.current.loading).toBe(true);
    expect(result.current.data).toBeNull();
  });

  it("does not update state after unmount when fetch rejects", async () => {
    let rejectPromise: ((reason: unknown) => void) | undefined;
    mockFetchPatch.mockReturnValueOnce(
      new Promise<Patch>((_resolve, reject) => {
        rejectPromise = reject;
      }),
    );

    const { unmount } = renderHook(() => usePatch("dense-100"));
    unmount();

    // Reject the promise after unmount — should not cause errors.
    if (rejectPromise) {
      rejectPromise(new Error("Server crashed"));
    }

    await new Promise((resolve) => setTimeout(resolve, 0));
    // No error thrown — cancellation prevented the state update.
  });
});

// ════════════════════════════════════════════════════════════════
//  Cancellation — AbortError Path (review issue #7)
// ════════════════════════════════════════════════════════════════

describe("cancellation — AbortError handling", () => {
  /**
   * These tests exercise the real abort path that occurs when the
   * hook's AbortController fires its signal. In production, `fetch`
   * rejects with a `DOMException` (name === "AbortError") when the
   * signal is aborted. The hook's catch block checks for this:
   *
   *   if (err instanceof DOMException && err.name === "AbortError") {
   *     return;  // silently swallow — not a user-visible error
   *   }
   *
   * The unmount/name-change tests above verify that state updates
   * don't reach unmounted components, but they use controllable
   * promises that don't simulate the actual AbortError rejection.
   * These tests directly simulate the rejection path.
   */

  it("silently swallows AbortError — does not surface as user error", async () => {
    // Simulate what fetch does when the AbortController fires:
    // it rejects with a DOMException whose name is "AbortError".
    const abortError = new DOMException(
      "The operation was aborted.",
      "AbortError",
    );
    mockFetchPatch.mockRejectedValueOnce(abortError);

    const { result } = renderHook(() => usePatch("dense-100"));

    // The AbortError should be silently swallowed. The hook should
    // NOT surface it as a user-visible error string.
    //
    // Wait a tick to let the rejection handler execute.
    await new Promise((resolve) => setTimeout(resolve, 50));

    // Error should NOT be set — AbortError is not a user error.
    expect(result.current.error).toBeNull();
    // Data should remain null — the fetch did not succeed.
    expect(result.current.data).toBeNull();
  });

  it("does not set loading=false after AbortError when controller is aborted (guard in finally block)", async () => {
    // To properly test the finally block's guard
    // `if (!controller.signal.aborted)`, we need the hook's real
    // AbortController to be aborted. We achieve this by creating
    // a signal-responsive mock: a promise that rejects with
    // AbortError when the signal fires, then unmounting the hook
    // (which triggers the cleanup → controller.abort()).
    //
    // This accurately simulates the production flow:
    //   1. Component renders → effect starts → fetchPatch called
    //   2. Component unmounts → cleanup aborts controller
    //   3. fetch rejects with AbortError
    //   4. catch: AbortError → return (silently swallowed)
    //   5. finally: controller.signal.aborted is TRUE → skip setLoading(false)
    mockFetchPatch.mockImplementationOnce(
      (_name: string, signal?: AbortSignal) => {
        return new Promise<Patch>((_resolve, reject) => {
          if (signal) {
            signal.addEventListener("abort", () => {
              reject(
                new DOMException("The operation was aborted.", "AbortError"),
              );
            });
          }
        });
      },
    );

    const { result, unmount } = renderHook(() => usePatch("dense-100"));

    // Loading is true while fetch is pending.
    expect(result.current.loading).toBe(true);

    // Unmount triggers cleanup → controller.abort() → mock rejects
    // with AbortError → catch silently swallows → finally guard
    // prevents setLoading(false) because controller.signal.aborted
    // is now true.
    unmount();

    await new Promise((resolve) => setTimeout(resolve, 50));

    // Loading should still be true — the finally block's guard
    // `!controller.signal.aborted` prevented setLoading(false).
    // result.current reflects the state at the time of unmount.
    expect(result.current.loading).toBe(true);
  });

  it("distinguishes AbortError from other DOMExceptions", async () => {
    // A DOMException with a name other than "AbortError" should
    // NOT be silently swallowed — it should surface as an error.
    const otherDomException = new DOMException(
      "Some other DOM error",
      "NotAllowedError",
    );
    mockFetchPatch.mockRejectedValueOnce(otherDomException);

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    // Non-AbortError DOMException is NOT silently swallowed — it
    // surfaces as a user-visible error. The exact message depends
    // on whether DOMException extends Error in the test runtime:
    //   - If DOMException extends Error: err.message is used
    //   - If not (e.g. some jsdom versions): fallback "Failed to fetch patch"
    // Either way, the important behavior is that the error IS surfaced.
    expect(result.current.error).not.toBeNull();
    expect(result.current.data).toBeNull();
  });
});

// ════════════════════════════════════════════════════════════════
//  Cancellation on Rapid Name Change
// ════════════════════════════════════════════════════════════════

describe("cancellation on rapid name change", () => {
  it("ignores the first fetch result when name changes before it resolves", async () => {
    // Use a signal-responsive mock for the first fetch: a promise
    // that rejects with AbortError when the hook's AbortController
    // fires. This accurately simulates what real `fetch` does when
    // the signal is aborted — the promise rejects immediately and
    // the hook's catch block silently swallows the AbortError.
    //
    // When the name changes (rerender), the cleanup function calls
    // controller.abort(), which causes this mock to reject. The
    // second fetch (for the new name) then proceeds normally.
    mockFetchPatch.mockImplementationOnce(
      (_name: string, signal?: AbortSignal) => {
        return new Promise<Patch>((_resolve, reject) => {
          if (signal) {
            signal.addEventListener("abort", () => {
              reject(
                new DOMException("The operation was aborted.", "AbortError"),
              );
            });
          }
        });
      },
    );

    const { result, rerender } = renderHook(
      ({ name }: { name: string }) => usePatch(name),
      { initialProps: { name: "star" } },
    );

    // First fetch is pending.
    expect(result.current.loading).toBe(true);

    // Change name before first fetch resolves. This triggers:
    //   1. Effect cleanup → controller.abort() → first mock rejects
    //      with AbortError → silently swallowed
    //   2. New effect → fetchPatch("dense-100") with new controller
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);
    rerender({ name: "dense-100" });

    // Wait for the second fetch to complete.
    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    // Data should be MOCK_DENSE (the second fetch result).
    // The first fetch was aborted and its AbortError was silently
    // swallowed — no stale data from the first fetch leaks through.
    expect(result.current.data).toEqual(MOCK_DENSE);
    expect(result.current.data?.patchName).toBe("dense-100");
    expect(result.current.error).toBeNull();
  });
});

// ════════════════════════════════════════════════════════════════
//  fetchPatch Call Arguments
// ════════════════════════════════════════════════════════════════

describe("fetchPatch call arguments", () => {
  it("passes the exact name string to fetchPatch", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);
    renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(mockFetchPatch).toHaveBeenCalledTimes(1);
    });

    // Review issue #3: the hook calls fetchPatch(name, controller.signal),
    // so we use expect.anything() for the signal to avoid arity mismatch.
    expect(mockFetchPatch).toHaveBeenCalledWith("dense-100", expect.anything());
  });

  it("passes hyphenated patch names correctly", async () => {
    mockFetchPatch.mockResolvedValueOnce({
      ...MOCK_STAR,
      patchName: "layer-54-d7",
    });
    renderHook(() => usePatch("layer-54-d7"));

    await waitFor(() => {
      expect(mockFetchPatch).toHaveBeenCalledTimes(1);
    });

    // Review issue #3: use expect.anything() for the signal argument.
    expect(mockFetchPatch).toHaveBeenCalledWith("layer-54-d7", expect.anything());
  });

  it("passes an AbortSignal as the second argument", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);
    renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(mockFetchPatch).toHaveBeenCalledTimes(1);
    });

    // Verify the second argument is actually an AbortSignal instance.
    // This confirms the hook properly creates an AbortController and
    // forwards its signal to fetchPatch.
    const secondArg = mockFetchPatch.mock.calls[0]?.[1];
    expect(secondArg).toBeInstanceOf(AbortSignal);
  });

  it("does not call fetchPatch more than once for the same name (no dependency change)", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_STAR);

    const { rerender } = renderHook(
      ({ name }: { name: string }) => usePatch(name),
      { initialProps: { name: "star" } },
    );

    await waitFor(() => {
      expect(mockFetchPatch).toHaveBeenCalledTimes(1);
    });

    // Re-render WITHOUT changing the name — the effect should
    // not re-run because [name] has not changed.
    rerender({ name: "star" });

    // Still only one call.
    expect(mockFetchPatch).toHaveBeenCalledTimes(1);
  });
});

// ════════════════════════════════════════════════════════════════
//  Return Type Shape
// ════════════════════════════════════════════════════════════════

describe("return type shape", () => {
  it("always returns an object with data, loading, and error keys", () => {
    mockFetchPatch.mockReturnValueOnce(new Promise<Patch>(() => {}));

    const { result } = renderHook(() => usePatch("dense-100"));

    expect(result.current).toHaveProperty("data");
    expect(result.current).toHaveProperty("loading");
    expect(result.current).toHaveProperty("error");
  });

  it("data is typed as Patch | null", async () => {
    mockFetchPatch.mockResolvedValueOnce(MOCK_DENSE);

    const { result } = renderHook(() => usePatch("dense-100"));

    // Before fetch resolves: null
    expect(result.current.data).toBeNull();

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    // After fetch resolves: the Patch object
    expect(result.current.data).not.toBeNull();
    expect(typeof result.current.data?.patchName).toBe("string");
  });

  it("loading is a boolean", () => {
    mockFetchPatch.mockReturnValueOnce(new Promise<Patch>(() => {}));

    const { result } = renderHook(() => usePatch("dense-100"));

    expect(typeof result.current.loading).toBe("boolean");
  });

  it("error is typed as string | null", async () => {
    mockFetchPatch.mockRejectedValueOnce(new Error("test error"));

    const { result } = renderHook(() => usePatch("dense-100"));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(typeof result.current.error).toBe("string");
    expect(result.current.error).toBe("test error");
  });
});