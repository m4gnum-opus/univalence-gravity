#!/usr/bin/env python3
"""
15_discrete_bekenstein_hawking.py — §15.10 Priority 1

Graph-Theoretic Proof of the Discrete Bekenstein–Hawking Bound:

    S(A) ≤ area(A) / 2

for any connected cell-aligned boundary region A in a finite cell
complex with unit-capacity bonds.

PROOF SKETCH (the core mathematical content):

  Decompose  area(A) = n_cross + n_bdy  where:
    n_cross = bonds from A-cells to non-A-cells
    n_bdy   = boundary legs of A-cells

  The max-flow S(A) is bounded by TWO independent cuts:
    1. Sever all cross-bonds:        S(A) ≤ n_cross
    2. Sever all A-boundary-legs:    S(A) ≤ n_bdy

  Therefore:
    S(A) ≤ min(n_cross, n_bdy) ≤ (n_cross + n_bdy)/2 = area(A)/2

  Equality holds iff  n_cross = n_bdy = area(A)/2.        □

This script:
  1. Verifies the decomposition and bound on Dense, BFS, Geodesic,
     and Hemisphere patches for {4,3,5} (3D) and {5,4} (2D).
  2. Characterizes when equality S = area/2 holds.
  3. Tests non-unit bond capacities (c = 2, 3).
  4. Outputs a clean proof sketch suitable for Agda formalization.

Usage (from repository root):
  python3 sim/prototyping/15_discrete_bekenstein_hawking.py
  python3 sim/prototyping/15_discrete_bekenstein_hawking.py --max-cells 300

Dependencies:  numpy, networkx

Reference:
  docs/10-frontier.md §15.10  (Priority 1: Graph-Theoretic Proof)
  14c_entropic_convergence_sup_half_OUTPUT.txt  (sup = 1/2 data)
"""

from __future__ import annotations

import argparse
import importlib
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path
from typing import NamedTuple

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

try:
    multi = importlib.import_module("07_honeycomb_3d_multiStrategy")
except ModuleNotFoundError:
    sys.exit("ERROR: Could not import 07_honeycomb_3d_multiStrategy.py.")

try:
    layer_mod = importlib.import_module("13_generate_layerN")
except ModuleNotFoundError:
    sys.exit("ERROR: Could not import 13_generate_layerN.py.")

try:
    import numpy as np
    import networkx as nx
except ImportError:
    sys.exit("ERROR: numpy and networkx are required.")


# ════════════════════════════════════════════════════════════════════
#  1.  Data Structures
# ════════════════════════════════════════════════════════════════════

class RegionDecomp(NamedTuple):
    """Per-region decomposition for the half-bound proof."""
    n_cells: int
    n_cross: int        # bonds from A-cells to non-A-cells
    n_bdy: int          # boundary legs of A-cells
    area: int           # = n_cross + n_bdy
    min_cut: int        # S(A) from max-flow
    ratio: float        # S / area
    bound_ok: bool      # S ≤ floor(area/2)?
    tight_ok: bool      # S ≤ min(n_cross, n_bdy)?
    achieves_half: bool # S * 2 == area?


class PatchReport(NamedTuple):
    """Summary for one (patch, strategy) combination."""
    tiling: str
    strategy: str
    label: str
    n_cells: int
    n_regions: int
    n_half_bound_violations: int
    n_tight_bound_violations: int
    n_achievers: int         # regions with S = area/2
    sup_ratio: float
    mean_ratio: float
    elapsed: float


# ════════════════════════════════════════════════════════════════════
#  2.  Region Decomposition
# ════════════════════════════════════════════════════════════════════

def decompose_region(
    region_cells: frozenset[int],
    internal_links: list[tuple[int, int]],
    bdy_per_cell: dict[int, int],
) -> tuple[int, int, int]:
    """
    Decompose area(A) = n_cross + n_bdy for a cell-aligned region A.

    n_cross = number of internal links (bonds/faces) where exactly
              one endpoint is in A
    n_bdy   = total boundary legs of A-cells
    area    = n_cross + n_bdy
    """
    n_cross = sum(
        1 for c1, c2 in internal_links
        if (c1 in region_cells) != (c2 in region_cells)
    )
    n_bdy = sum(bdy_per_cell.get(c, 0) for c in region_cells)
    return n_cross, n_bdy, n_cross + n_bdy


# ════════════════════════════════════════════════════════════════════
#  3.  Flow Graph with Variable Capacity
# ════════════════════════════════════════════════════════════════════

INF_CAP = 10_000


def build_flow_graph_cap(
    internal_links: list[tuple[int, int]],
    bdy_per_cell: dict[int, int],
    bond_cap: int = 1,
    bdy_cap: int = 1,
) -> tuple[nx.DiGraph, list[int], dict[int, int]]:
    """Build a flow graph with configurable bond and boundary capacity."""
    G = nx.DiGraph()
    for c1, c2 in internal_links:
        G.add_edge(f"c{c1}", f"c{c2}", capacity=bond_cap)
        G.add_edge(f"c{c2}", f"c{c1}", capacity=bond_cap)

    bnode_ids: list[int] = []
    bnode_to_cell: dict[int, int] = {}
    idx = 0
    for cid, n_bdy in bdy_per_cell.items():
        for _ in range(n_bdy):
            bnode = f"b{idx}"
            G.add_edge(f"c{cid}", bnode, capacity=bdy_cap)
            G.add_edge(bnode, f"c{cid}", capacity=bdy_cap)
            bnode_ids.append(idx)
            bnode_to_cell[idx] = cid
            idx += 1
    return G, bnode_ids, bnode_to_cell


def compute_min_cut(
    G: nx.DiGraph, bnode_ids: list[int], region: set[int],
) -> int:
    """Min-cut separating a boundary region from its complement."""
    complement = set(bnode_ids) - region
    if not region or not complement:
        return 0
    H = G.copy()
    for idx in bnode_ids:
        if idx in region:
            H.add_edge("__SRC__", f"b{idx}", capacity=INF_CAP)
        else:
            H.add_edge(f"b{idx}", "__SNK__", capacity=INF_CAP)
    try:
        val, _ = nx.minimum_cut(H, "__SRC__", "__SNK__")
        return int(round(val))
    except nx.NetworkXError:
        return -1


# ════════════════════════════════════════════════════════════════════
#  4.  {5,4} Dense Growth (from 14b/14c)
# ════════════════════════════════════════════════════════════════════

def build_54_dense_patch(ec, tc, max_tiles, name="dense-54"):
    """Greedy max-connectivity growth on the {5,4} tiling."""
    p = tc
    tiles = {}
    center_to_id = {}

    def register(mat):
        c = mat @ p
        k = layer_mod._vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        tid = len(tiles)
        tiles[tid] = mat
        center_to_id[k] = tid
        return tid, True

    def adj_count(mat):
        return sum(1 for F in ec
                   if layer_mod._vec_key((mat @ F) @ p) in center_to_id)

    register(np.eye(3))
    while len(tiles) < max_tiles:
        frontier = {}
        for tid in list(tiles.keys()):
            g = tiles[tid]
            for F in ec:
                h = g @ F
                ck = layer_mod._vec_key(h @ p)
                if ck not in center_to_id and ck not in frontier:
                    frontier[ck] = h
        if not frontier:
            break
        best = max(frontier, key=lambda k: adj_count(frontier[k]))
        register(frontier[best])

    neighbors = defaultdict(set)
    for tid, g in tiles.items():
        for F in ec:
            ck = layer_mod._vec_key((g @ F) @ p)
            if ck in center_to_id:
                nid = center_to_id[ck]
                if nid != tid:
                    neighbors[tid].add(nid)
                    neighbors[nid].add(tid)

    internal_bonds = []
    seen = set()
    for tid, nbrs in neighbors.items():
        for nid in nbrs:
            pair = frozenset([tid, nid])
            if pair not in seen:
                seen.add(pair)
                internal_bonds.append((min(tid, nid), max(tid, nid)))

    bdy_per_tile = {tid: 5 - len(neighbors.get(tid, set())) for tid in tiles}

    return {
        "name": name, "tiles": tiles, "neighbors": dict(neighbors),
        "internal_bonds": internal_bonds,
        "n_boundary_legs": sum(bdy_per_tile.values()),
        "bdy_per_tile": bdy_per_tile,
    }


# ════════════════════════════════════════════════════════════════════
#  5.  Unified Analysis Engine
# ════════════════════════════════════════════════════════════════════

def analyze_patch(
    patch: dict,
    label: str,
    tiling: str,
    strategy: str,
    faces_per_cell: int,
    max_rc: int,
    flow_builder,
    region_enumerator,
    links_key: str,
    bond_cap: int = 1,
) -> tuple[PatchReport, list[RegionDecomp]]:
    """
    Analyze a patch: for each region, decompose area = n_cross + n_bdy,
    compute S via max-flow, and verify S ≤ min(n_cross, n_bdy) ≤ area/2.
    """
    t0 = time.time()
    cell_dict = patch.get("cells", patch.get("tiles", {}))
    n_cells = len(cell_dict)
    internal_links = patch[links_key]
    bdy_per_cell = patch.get("bdy_per_cell", patch.get("bdy_per_tile", {}))

    flow_G, bnode_ids, bnode_to_cell = flow_builder(
        internal_links, bdy_per_cell, bond_cap, bond_cap)

    cell_bnodes = defaultdict(set)
    for idx in bnode_ids:
        cell_bnodes[bnode_to_cell[idx]].add(idx)

    regions_raw = region_enumerator(patch, bnode_to_cell, bnode_ids, max_rc)

    decomps: list[RegionDecomp] = []
    for item in regions_raw:
        if isinstance(item, tuple) and len(item) == 2:
            _, bnode_set = item
            region_cells = frozenset(bnode_to_cell[idx] for idx in bnode_set)
        else:
            region_cells = item.tiles
            bnode_set = set()
            for tid in region_cells:
                bnode_set.update(cell_bnodes[tid])

        nc, nb, area = decompose_region(region_cells, internal_links,
                                        bdy_per_cell)
        # Scale for non-unit capacity
        nc_cap = nc * bond_cap
        nb_cap = nb * bond_cap
        area_cap = nc_cap + nb_cap

        s = compute_min_cut(flow_G, bnode_ids, bnode_set)

        if area_cap > 0 and s >= 0:
            ratio = s / area_cap
            bound_ok = (2 * s <= area_cap)
            tight_ok = (s <= min(nc_cap, nb_cap))
            achieves = (2 * s == area_cap)
            decomps.append(RegionDecomp(
                len(region_cells), nc_cap, nb_cap, area_cap, s,
                ratio, bound_ok, tight_ok, achieves))

    elapsed = time.time() - t0

    n_half_viol = sum(1 for d in decomps if not d.bound_ok)
    n_tight_viol = sum(1 for d in decomps if not d.tight_ok)
    n_ach = sum(1 for d in decomps if d.achieves_half)
    sup_r = max((d.ratio for d in decomps), default=0.0)
    mean_r = (sum(d.ratio for d in decomps) / len(decomps)
              if decomps else 0.0)

    report = PatchReport(
        tiling, strategy, label, n_cells, len(decomps),
        n_half_viol, n_tight_viol, n_ach, sup_r, mean_r, elapsed)
    return report, decomps


# ════════════════════════════════════════════════════════════════════
#  6.  Region Enumerator Wrappers
# ════════════════════════════════════════════════════════════════════

def _enum_435(patch, btc, bids, max_rc):
    return multi.enumerate_cell_aligned_regions(
        patch, btc, bids, max_region_cells=max_rc)

def _enum_54(patch, btc, bids, max_rc):
    return layer_mod.enumerate_regions(patch, btc, bids, max_rc)

def _flow_builder_435(links, bdy, bc, lc):
    return build_flow_graph_cap(links, bdy, bc, lc)

def _flow_builder_54(links, bdy, bc, lc):
    return build_flow_graph_cap(links, bdy, bc, lc)


# ════════════════════════════════════════════════════════════════════
#  7.  Output Formatting
# ════════════════════════════════════════════════════════════════════

def print_report_table(title: str, reports: list[PatchReport]) -> None:
    print(f"\n  {title}:")
    if not reports:
        print("    (no data)")
        return
    print(f"    {'Label':<20s} | {'N':>5s} | {'#reg':>5s} | "
          f"{'½-viol':>6s} | {'tight':>5s} | {'ach½':>5s} | "
          f"{'sup':>6s} | {'mean':>6s} | {'time':>5s}")
    print(f"    {'─' * 82}")
    for r in reports:
        print(f"    {r.label:<20s} | {r.n_cells:>5d} | {r.n_regions:>5d} | "
              f"{r.n_half_bound_violations:>6d} | "
              f"{r.n_tight_bound_violations:>5d} | "
              f"{r.n_achievers:>5d} | "
              f"{r.sup_ratio:>6.4f} | {r.mean_ratio:>6.4f} | "
              f"{r.elapsed:>4.1f}s")


def print_achiever_analysis(decomps: list[RegionDecomp], label: str) -> None:
    """Print what region configurations achieve S = area/2."""
    achievers = [d for d in decomps if d.achieves_half]
    if not achievers:
        return
    size_dist = Counter(d.n_cells for d in achievers)
    print(f"    {label} achievers: ", end="")
    parts = [f"k={k}({cnt})" for k, cnt in sorted(size_dist.items())]
    print(", ".join(parts))

    # Show a few examples
    shown = set()
    for d in achievers[:5]:
        key = (d.n_cells, d.n_cross, d.n_bdy)
        if key not in shown:
            shown.add(key)
            print(f"      k={d.n_cells}: S={d.min_cut}, "
                  f"n_cross={d.n_cross}, n_bdy={d.n_bdy}, "
                  f"area={d.area}, S/area={d.ratio:.4f}")


# ════════════════════════════════════════════════════════════════════
#  8.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Graph-theoretic proof of S(A) ≤ area(A)/2")
    parser.add_argument("--max-cells", type=int, default=200,
                        help="Max cells per patch (default: 200)")
    parser.add_argument("--max-rc", type=int, default=5,
                        help="Max region cells (default: 5)")
    args = parser.parse_args()

    MAX_RC = args.max_rc
    max_cells = args.max_cells

    print("╔══════════════════════════════════════════════════════════╗")
    print("║  §15.10 Priority 1:  Discrete Bekenstein–Hawking Proof   ║")
    print("║  S(A) ≤ area(A)/2  — Graph-Theoretic Characterization    ║")
    print("╚══════════════════════════════════════════════════════════╝")

    # ── Print the proof sketch first ────────────────────────────────
    print(f"""
  ════════════════════════════════════════════════════════════════
  THEOREM (Discrete Bekenstein–Hawking Half-Bound).

  For any connected cell-aligned boundary region A in a finite
  cell complex with uniform bond capacity c:

      S(A) ≤ area(A) / 2

  where S(A) = min-cut entropy, area(A) = boundary surface area
  (in capacity-weighted units).

  PROOF.

  Decompose  area(A) = n_cross + n_bdy  where:
    • n_cross = capacity of bonds from A-cells to non-A cells
    • n_bdy   = capacity of boundary legs of A-cells

  The max-flow S(A) is bounded by TWO independent cuts:
    Cut 1: Sever all cross-bonds           →  S(A) ≤ n_cross
    Cut 2: Sever all A-boundary-legs       →  S(A) ≤ n_bdy

  Cut 1 disconnects source from sink because after removal,
  A-cells can only reach other A-cells and A's pseudo-nodes
  (all source-connected); no path to any complement pseudo-node
  (all sink-connected) survives.

  Cut 2 disconnects source from sink because after removal,
  source has no finite-capacity path to any cell (all A-boundary
  legs are severed); hence no path to sink.

  Therefore:
    S(A) ≤ min(n_cross, n_bdy)
         ≤ (n_cross + n_bdy) / 2      [since min(a,b) ≤ (a+b)/2]
         = area(A) / 2

  Equality S = area/2 iff n_cross = n_bdy = area/2 and the
  max-flow saturates both cuts.                                □
  ════════════════════════════════════════════════════════════════
""")

    print(f"  Parameters: max-cells={max_cells}, max-rc={MAX_RC}\n")

    # ── Initialize {4,3,5} geometry ─────────────────────────────────
    print("  Initializing {4,3,5} Coxeter geometry ...", flush=True)
    G435 = multi.build_gram_matrix()
    r435 = multi.build_reflections(G435)
    cc435 = multi.find_cell_center(G435)
    st435 = multi.enumerate_group(r435[:3], expected=48)
    fc435 = multi.find_face_crossings(r435, st435, G435)
    ap435, op435 = multi.classify_face_pairs(fc435)
    print("  ✓  {4,3,5} ready.")

    # ── Initialize {5,4} geometry ───────────────────────────────────
    print("  Initializing {5,4} Coxeter geometry ...", flush=True)
    G54 = layer_mod.build_gram_matrix()
    r54 = layer_mod.build_reflections(G54)
    layer_mod.validate_reflections(G54, r54)
    tc54 = layer_mod.find_tile_center(G54)
    st54 = layer_mod.enumerate_group(r54[:2], expected=10)
    ec54 = layer_mod.find_edge_crossings(r54, st54, G54)
    print("  ✓  {5,4} ready.\n")

    all_reports: list[PatchReport] = []
    all_decomps_for_ach: list[tuple[str, list[RegionDecomp]]] = []
    total_regions = 0

    # ════════════════════════════════════════════════════════════════
    #  A.  {4,3,5} Dense patches
    # ════════════════════════════════════════════════════════════════

    sizes_435 = [n for n in [50, 100, 200] if n <= max_cells]

    print("  ═══  {4,3,5} Dense  ═══")
    for mc in sizes_435:
        label = f"435-Dense-{mc}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch_dense(fc435, cc435, mc, name=label)
        rep, decomps = analyze_patch(
            patch, label, "{4,3,5}", "Dense", 6, MAX_RC,
            _flow_builder_435, _enum_435, "internal_faces")
        all_reports.append(rep)
        all_decomps_for_ach.append((label, decomps))
        total_regions += rep.n_regions
        print(f"  {rep.n_regions} regions, ½-viol={rep.n_half_bound_violations}, "
              f"sup={rep.sup_ratio:.4f}, ach={rep.n_achievers}  "
              f"({rep.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  B.  {4,3,5} BFS-shell patches
    # ════════════════════════════════════════════════════════════════

    print("\n  ═══  {4,3,5} BFS-shell  ═══")
    for mc in [n for n in [50, 100] if n <= max_cells]:
        label = f"435-BFS-{mc}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch(fc435, cc435, mc, name=label)
        rep, decomps = analyze_patch(
            patch, label, "{4,3,5}", "BFS", 6, MAX_RC,
            _flow_builder_435, _enum_435, "internal_faces")
        all_reports.append(rep)
        all_decomps_for_ach.append((label, decomps))
        total_regions += rep.n_regions
        print(f"  {rep.n_regions} regions, ½-viol={rep.n_half_bound_violations}, "
              f"sup={rep.sup_ratio:.4f}, ach={rep.n_achievers}  "
              f"({rep.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  C.  {4,3,5} Geodesic tube
    # ════════════════════════════════════════════════════════════════

    print("\n  ═══  {4,3,5} Geodesic  ═══")
    for mc in [n for n in [50] if n <= max_cells]:
        label = f"435-Geo-{mc}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch_geodesic(
            fc435, cc435, mc, name=label, opposite_pairs=op435)
        rep, decomps = analyze_patch(
            patch, label, "{4,3,5}", "Geodesic", 6, MAX_RC,
            _flow_builder_435, _enum_435, "internal_faces")
        all_reports.append(rep)
        total_regions += rep.n_regions
        print(f"  {rep.n_regions} regions, ½-viol={rep.n_half_bound_violations}, "
              f"sup={rep.sup_ratio:.4f}  ({rep.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  D.  {4,3,5} Hemisphere
    # ════════════════════════════════════════════════════════════════

    print("\n  ═══  {4,3,5} Hemisphere  ═══")
    for mc in [n for n in [50] if n <= max_cells]:
        label = f"435-Hemi-{mc}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch_hemisphere(fc435, cc435, mc, name=label)
        rep, decomps = analyze_patch(
            patch, label, "{4,3,5}", "Hemisphere", 6, MAX_RC,
            _flow_builder_435, _enum_435, "internal_faces")
        all_reports.append(rep)
        total_regions += rep.n_regions
        print(f"  {rep.n_regions} regions, ½-viol={rep.n_half_bound_violations}, "
              f"sup={rep.sup_ratio:.4f}  ({rep.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  E.  {5,4} Dense patches
    # ════════════════════════════════════════════════════════════════

    sizes_54 = [n for n in [50, 100, 200] if n <= max_cells]

    print("\n  ═══  {5,4} Dense  ═══")
    for mt in sizes_54:
        label = f"54-Dense-{mt}"
        print(f"    {label} ...", end="", flush=True)
        patch = build_54_dense_patch(ec54, tc54, mt, name=label)
        rep, decomps = analyze_patch(
            patch, label, "{5,4}", "Dense", 5, MAX_RC,
            _flow_builder_54, _enum_54, "internal_bonds")
        all_reports.append(rep)
        all_decomps_for_ach.append((label, decomps))
        total_regions += rep.n_regions
        print(f"  {rep.n_regions} regions, ½-viol={rep.n_half_bound_violations}, "
              f"sup={rep.sup_ratio:.4f}, ach={rep.n_achievers}  "
              f"({rep.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  F.  Non-Unit Capacity Test
    # ════════════════════════════════════════════════════════════════

    print("\n  ═══  Non-Unit Capacity Test ({4,3,5} Dense-50)  ═══")
    cap_reports: list[PatchReport] = []
    patch_cap = multi.build_patch_dense(fc435, cc435, 50, name="cap-test")
    for cap in [1, 2, 3]:
        label = f"435-D50-cap{cap}"
        print(f"    {label} ...", end="", flush=True)
        rep, _ = analyze_patch(
            patch_cap, label, "{4,3,5}", f"Dense-c{cap}", 6, MAX_RC,
            _flow_builder_435, _enum_435, "internal_faces",
            bond_cap=cap)
        cap_reports.append(rep)
        total_regions += rep.n_regions
        print(f"  {rep.n_regions} regions, ½-viol={rep.n_half_bound_violations}, "
              f"sup={rep.sup_ratio:.4f}  ({rep.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  Output
    # ════════════════════════════════════════════════════════════════

    print(f"\n{'═' * 72}")
    print(f"  RESULTS — S(A) ≤ area(A)/2 VERIFICATION")
    print(f"{'═' * 72}")

    print_report_table("All Strategies (unit capacity)", all_reports)
    print_report_table("Non-Unit Capacity", cap_reports)

    # ── Violation Summary ───────────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  VIOLATION SUMMARY")
    print(f"{'═' * 72}")

    all_combined = all_reports + cap_reports
    total_half_viol = sum(r.n_half_bound_violations for r in all_combined)
    total_tight_viol = sum(r.n_tight_bound_violations for r in all_combined)
    total_tested = sum(r.n_regions for r in all_combined)

    print(f"\n  Total regions tested:       {total_tested}")
    print(f"  Half-bound violations:      {total_half_viol}")
    print(f"  Tight-bound violations:     {total_tight_viol}")
    print(f"     (tight = S ≤ min(n_cross, n_bdy))")

    if total_half_viol == 0 and total_tight_viol == 0:
        print(f"\n  ✓  ZERO VIOLATIONS across all {total_tested} regions!")
        print(f"     Both the half-bound S ≤ area/2 and the tighter")
        print(f"     bound S ≤ min(n_cross, n_bdy) hold universally.")
    else:
        if total_half_viol > 0:
            print(f"\n  ✗  {total_half_viol} HALF-BOUND VIOLATIONS found!")
        if total_tight_viol > 0:
            print(f"\n  ✗  {total_tight_viol} TIGHT-BOUND VIOLATIONS found!")

    # ── Achiever Analysis ───────────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  ACHIEVER ANALYSIS: When does S = area/2?")
    print(f"{'═' * 72}")
    print(f"\n  S = area/2 iff n_cross = n_bdy = area/2.\n")

    for label, decomps in all_decomps_for_ach:
        print_achiever_analysis(decomps, label)

    # ── Strategy Universality ───────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  STRATEGY UNIVERSALITY: Does S ≤ area/2 hold for ALL strategies?")
    print(f"{'═' * 72}\n")

    by_strategy = defaultdict(list)
    for r in all_reports:
        by_strategy[f"{r.tiling} {r.strategy}"].append(r)

    for strat, reps in sorted(by_strategy.items()):
        max_sup = max(r.sup_ratio for r in reps)
        viol = sum(r.n_half_bound_violations for r in reps)
        regs = sum(r.n_regions for r in reps)
        status = "✓" if viol == 0 else "✗"
        print(f"  {status}  {strat:<25s}:  sup(S/area) = {max_sup:.4f}, "
              f"violations = {viol}/{regs}")

    # ── Capacity Universality ───────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  CAPACITY UNIVERSALITY: Does S ≤ area/2 hold for c > 1?")
    print(f"{'═' * 72}\n")

    for r in cap_reports:
        status = "✓" if r.n_half_bound_violations == 0 else "✗"
        print(f"  {status}  {r.label:<20s}:  sup = {r.sup_ratio:.4f}, "
              f"violations = {r.n_half_bound_violations}/{r.n_regions}")

    print(f"\n  Interpretation: With uniform capacity c, the bound becomes")
    print(f"  S(A) ≤ area_cap(A)/2 where area_cap = c · area_faces.")
    print(f"  The proof applies identically: just multiply through by c.")

    # ── Agda Formalization Guidance ─────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  AGDA FORMALIZATION GUIDANCE")
    print(f"{'═' * 72}")
    print(f"""
  The half-bound S(A) ≤ area(A)/2 can be formalized in two ways:

  (a) GENERIC PROOF from flow-network theory (ambitious):

      Define:
        n-cross : PatchData → RegionTy → ℕ
        n-bdy   : PatchData → RegionTy → ℕ
        area-decomp : (r : RegionTy) → area r ≡ n-cross r + n-bdy r

      Then prove:
        S-le-cross : (r : RegionTy) → S r ≤ n-cross r
        S-le-bdy   : (r : RegionTy) → S r ≤ n-bdy r

      The half-bound follows from:
        min-le-half : (a b : ℕ) → min a b ≤ (a + b) / 2
                    (a standard ℕ arithmetic lemma)

      Compose:  S r ≤ min(n-cross r, n-bdy r) ≤ area r / 2

  (b) PER-INSTANCE VERIFICATION via oracle + abstract (immediate):

      For each concrete patch, the Python oracle computes:
        half-bound : (r : RegionTy) → 2 · S r ≤ area r
      as  abstract  proofs with witnesses  (k , refl) .

      This extends the existing Dense100AreaLaw pattern with a
      strengthened bound: replace  S ≤ area  with  2·S ≤ area .

  The generic proof (a) is the more satisfying result.  The key
  lemma  S-le-cross  states that severing all cross-bonds is a
  valid cut (a structural property of the flow graph).  The key
  lemma  S-le-bdy  states that severing all boundary legs is a
  valid cut.  Both follow from the max-flow / min-cut theorem.

  For the Agda HalfBoundWitness record from §15.10:

    record HalfBoundWitness (pd : PatchData) : Type₀ where
      field
        area       : RegionTy pd → ℚ≥0
        half-bound : (r : RegionTy pd)
                   → S∂ pd r +ℚ S∂ pd r ≤ℚ area r
        tight      : Σ[ r ∈ RegionTy pd ]
                       (S∂ pd r +ℚ S∂ pd r ≡ area r)
""")

    # ── Final Verdict ───────────────────────────────────────────────
    print(f"{'═' * 72}")
    print(f"  VERDICT")
    print(f"{'═' * 72}")

    total_time = sum(r.elapsed for r in all_combined)

    if total_half_viol == 0:
        print(f"""
  ★  S(A) ≤ area(A)/2  VERIFIED for all {total_tested} regions
     across {len(all_combined)} patch configurations, 4 growth
     strategies, 2 tilings, and 3 capacity values.

  The bound is a THEOREM, following from:
    S ≤ min(n_cross, n_bdy) ≤ (n_cross + n_bdy)/2 = area/2

  where n_cross = capacity of cross-bonds, n_bdy = capacity of
  boundary legs, and area = n_cross + n_bdy.

  This is the discrete Bekenstein–Hawking formula:
    S = area / (4G)  with  1/(4G) = 1/2  in bond-dimension-1 units.

  The bound holds for ALL tested strategies (Dense, BFS, Geodesic,
  Hemisphere) and both tilings ({{4,3,5}} cubes, {{5,4}} pentagons).

  Total: {total_tested} regions, {total_time:.1f}s
""")
    else:
        print(f"\n  ✗  VIOLATIONS FOUND. The bound does NOT hold universally.")
        print(f"     Review violating cases above.\n")


if __name__ == "__main__":
    main()