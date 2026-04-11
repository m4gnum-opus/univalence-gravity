#!/usr/bin/env python3
"""
14c_entropic_convergence_sup_half.py — Milestone I, Step 1

Tests the Revised Conjecture from the 14b evaluation:

  "For the Dense family of patches in any hyperbolic tiling, the
   pointwise supremum sup_r S(r)/area(r) = 1/2 universally."

Strategy:  sweep max_region_cells from 5 to 8 at fixed patch sizes,
tracking whether sup(S/area) stays at 0.5 for LARGER regions (6, 7,
8 cells) where the measurement window was previously capped.

If sup(S/area) remains 0.5:  the bound S ≤ area/2 is robust and
independent of the measurement window.  This is evidence for a
discrete isoperimetric theorem.

If sup(S/area) drops below 0.5 at larger max_rc:  the bound is
sensitive to region size, and the 1/2 value is achieved only by
small (1-3 cell) regions.

Key outputs:
  (a) sup(S/area) for each (patch_size, max_rc, tiling) triple
  (b) Per-region-size sup(S/area) for k = 1..max_rc
  (c) The "tightest achiever": which region(s) achieve S/area = 0.5
  (d) Violation check: any region with S/area > 0.5?

Usage:
  python3 sim/prototyping/14c_entropic_convergence_sup_half.py
  python3 sim/prototyping/14c_entropic_convergence_sup_half.py --max-cells 300
  python3 sim/prototyping/14c_entropic_convergence_sup_half.py --max-rc-hi 10

Dependencies:  numpy, networkx

Reference:
  14b_entropic_convergence_controlled_OUTPUT.txt  (Finding 2: sup = 0.5)
  Evaluation of 14b  (Best Path Forward, Step 1)
  docs/10-frontier.md §15.9  (Entropic Convergence Conjecture)
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

class RegionMeasure(NamedTuple):
    """Per-region measurement for the sup(S/area) analysis."""
    n_cells: int
    min_cut: int
    area: int
    ratio: float        # S/area


class SweepResult(NamedTuple):
    """Result for one (patch_size, max_rc, tiling) combination."""
    tiling: str
    strategy: str
    label: str
    n_cells_patch: int
    max_rc: int
    n_regions: int
    sup_ratio: float         # sup_r S(r)/area(r)
    mean_ratio: float
    per_size_sup: dict       # k → sup_{|A|=k} S(A)/area(A)
    per_size_count: dict     # k → number of regions of size k
    achiever_size: int       # size k of region achieving sup
    achiever_S: int          # S value of the achieving region
    achiever_area: int       # area value of the achieving region
    n_violations: int        # regions with S/area > 0.5 + epsilon
    max_S: int
    max_area: int
    eta_global: float        # max_S / max_area
    elapsed: float


# ════════════════════════════════════════════════════════════════════
#  2.  Boundary Area (unified)
# ════════════════════════════════════════════════════════════════════

def compute_boundary_area(
    cells: frozenset[int],
    internal_links: list[tuple[int, int]],
    faces_per_cell: int,
) -> int:
    internal_within = sum(
        1 for c1, c2 in internal_links
        if c1 in cells and c2 in cells
    )
    return faces_per_cell * len(cells) - 2 * internal_within


# ════════════════════════════════════════════════════════════════════
#  3.  {5,4} Dense Growth (from 14b)
# ════════════════════════════════════════════════════════════════════

def build_54_dense_patch(
    edge_crossings: list[np.ndarray],
    tile_center: np.ndarray,
    max_tiles: int,
    name: str = "dense-54",
) -> dict:
    p = tile_center
    tiles: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}

    def register(mat):
        c = mat @ p
        k = layer_mod._vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        tid = len(tiles)
        tiles[tid] = mat
        center_to_id[k] = tid
        return tid, True

    def patch_adj_count(mat):
        count = 0
        for F in edge_crossings:
            if layer_mod._vec_key((mat @ F) @ p) in center_to_id:
                count += 1
        return count

    register(np.eye(3))
    while len(tiles) < max_tiles:
        frontier = {}
        for tid in list(tiles.keys()):
            g = tiles[tid]
            for F in edge_crossings:
                h = g @ F
                ck = layer_mod._vec_key(h @ p)
                if ck not in center_to_id and ck not in frontier:
                    frontier[ck] = h
        if not frontier:
            break
        best_key = max(frontier, key=lambda k: patch_adj_count(frontier[k]))
        register(frontier[best_key])

    neighbors: dict[int, set[int]] = defaultdict(set)
    for tid, g in tiles.items():
        for F in edge_crossings:
            ck = layer_mod._vec_key((g @ F) @ p)
            if ck in center_to_id:
                nid = center_to_id[ck]
                if nid != tid:
                    neighbors[tid].add(nid)
                    neighbors[nid].add(tid)

    internal_bonds = []
    seen_pairs = set()
    for tid, nbrs in neighbors.items():
        for nid in nbrs:
            pair = frozenset([tid, nid])
            if pair not in seen_pairs:
                seen_pairs.add(pair)
                internal_bonds.append((min(tid, nid), max(tid, nid)))

    bdy_per_tile = {}
    for tid in tiles:
        bdy_per_tile[tid] = 5 - len(neighbors.get(tid, set()))

    return {
        "name": name,
        "tiles": tiles,
        "neighbors": dict(neighbors),
        "internal_bonds": internal_bonds,
        "n_boundary_legs": sum(bdy_per_tile.values()),
        "bdy_per_tile": bdy_per_tile,
    }


# ════════════════════════════════════════════════════════════════════
#  4.  Min-Cut Helper
# ════════════════════════════════════════════════════════════════════

INF_CAP = 10_000

def _compute_mincut(G, bnode_ids, region):
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
#  5.  Unified Analyzer (sweep one max_rc on one patch)
# ════════════════════════════════════════════════════════════════════

def analyze_sweep_point(
    patch: dict,
    label: str,
    tiling: str,
    strategy: str,
    faces_per_cell: int,
    max_rc: int,
    flow_graph_builder,
    region_enumerator,
    internal_links_key: str,
) -> SweepResult:
    t0 = time.time()

    cell_dict = patch.get("cells", patch.get("tiles", {}))
    n_cells = len(cell_dict)
    internal_links = patch[internal_links_key]

    flow_G, bnode_ids, bnode_to_cell = flow_graph_builder(patch)

    cell_bnodes: dict[int, set[int]] = defaultdict(set)
    for idx in bnode_ids:
        cell_bnodes[bnode_to_cell[idx]].add(idx)

    regions_raw = region_enumerator(patch, bnode_to_cell, bnode_ids, max_rc)

    EPSILON = 1e-9
    all_measures: list[RegionMeasure] = []
    per_size: dict[int, list[RegionMeasure]] = defaultdict(list)

    for item in regions_raw:
        if isinstance(item, tuple) and len(item) == 2:
            _lbl, bnode_set = item
            region_cells = frozenset(bnode_to_cell[idx] for idx in bnode_set)
        else:
            region_cells = item.tiles
            bnode_set = set()
            for tid in region_cells:
                bnode_set.update(cell_bnodes[tid])

        s = _compute_mincut(flow_G, bnode_ids, bnode_set)
        area = compute_boundary_area(region_cells, internal_links,
                                     faces_per_cell)
        if area > 0 and s >= 0:
            ratio = s / area
            m = RegionMeasure(len(region_cells), s, area, ratio)
            all_measures.append(m)
            per_size[len(region_cells)].append(m)

    if not all_measures:
        elapsed = time.time() - t0
        return SweepResult(
            tiling, strategy, label, n_cells, max_rc,
            0, 0.0, 0.0, {}, {}, 0, 0, 0, 0, 0, 0, 0.0, elapsed)

    # sup(S/area)
    best = max(all_measures, key=lambda m: m.ratio)
    sup_ratio = best.ratio
    mean_ratio = sum(m.ratio for m in all_measures) / len(all_measures)

    # Per-size sup
    per_size_sup = {}
    per_size_count = {}
    for k, ms in sorted(per_size.items()):
        per_size_sup[k] = max(m.ratio for m in ms)
        per_size_count[k] = len(ms)

    # Violations: S/area > 0.5 + epsilon
    n_violations = sum(1 for m in all_measures if m.ratio > 0.5 + EPSILON)

    # Global η
    max_S = max(m.min_cut for m in all_measures)
    max_area = max(m.area for m in all_measures)
    eta = max_S / max_area if max_area > 0 else 0.0

    elapsed = time.time() - t0

    return SweepResult(
        tiling=tiling, strategy=strategy, label=label,
        n_cells_patch=n_cells, max_rc=max_rc,
        n_regions=len(all_measures),
        sup_ratio=sup_ratio, mean_ratio=mean_ratio,
        per_size_sup=per_size_sup, per_size_count=per_size_count,
        achiever_size=best.n_cells,
        achiever_S=best.min_cut, achiever_area=best.area,
        n_violations=n_violations,
        max_S=max_S, max_area=max_area, eta_global=eta,
        elapsed=elapsed,
    )


# ════════════════════════════════════════════════════════════════════
#  6.  Region Enumerator Wrappers
# ════════════════════════════════════════════════════════════════════

def _enum_435(patch, bnode_to_cell, bnode_ids, max_rc):
    return multi.enumerate_cell_aligned_regions(
        patch, bnode_to_cell, bnode_ids, max_region_cells=max_rc)

def _enum_54(patch, bnode_to_tile, bnode_ids, max_rc):
    return layer_mod.enumerate_regions(
        patch, bnode_to_tile, bnode_ids, max_rc)


# ════════════════════════════════════════════════════════════════════
#  7.  Output Formatting
# ════════════════════════════════════════════════════════════════════

def print_sweep_table(title: str, results: list[SweepResult]) -> None:
    print(f"\n  {title}:")
    if not results:
        print("    (no data)")
        return
    print(f"    {'Label':>14s} | {'N':>5s} | {'rc':>2s} | {'#reg':>5s} "
          f"| {'sup':>6s} | {'mean':>6s} | {'maxS':>4s} | {'maxA':>4s} "
          f"| {'η':>6s} | {'achiever':>18s} | {'viol':>4s} | {'time':>5s}")
    print(f"    {'─' * 110}")
    for r in results:
        ach = f"k={r.achiever_size} S={r.achiever_S} A={r.achiever_area}"
        print(f"    {r.label:>14s} | {r.n_cells_patch:>5d} "
              f"| {r.max_rc:>2d} | {r.n_regions:>5d} "
              f"| {r.sup_ratio:>6.4f} | {r.mean_ratio:>6.4f} "
              f"| {r.max_S:>4d} | {r.max_area:>4d} "
              f"| {r.eta_global:>6.4f} | {ach:>18s} "
              f"| {r.n_violations:>4d} | {r.elapsed:>4.1f}s")


def print_per_size_sup_table(title: str, results: list[SweepResult]) -> None:
    print(f"\n  {title}:")
    if not results:
        return
    all_ks = sorted(set(k for r in results for k in r.per_size_sup.keys()))
    if not all_ks:
        return
    header = f"    {'Label':>14s} | {'rc':>2s}"
    for k in all_ks:
        header += f" | sup(k={k})"
    print(header)
    print(f"    {'─' * (22 + 12 * len(all_ks))}")
    for r in results:
        line = f"    {r.label:>14s} | {r.max_rc:>2d}"
        for k in all_ks:
            if k in r.per_size_sup:
                line += f" |   {r.per_size_sup[k]:>6.4f}"
            else:
                line += f" |      ---"
        print(line)


# ════════════════════════════════════════════════════════════════════
#  8.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Test the Revised Conjecture: sup(S/area) = 1/2 "
                    "universally for Dense hyperbolic patches.")
    parser.add_argument("--max-cells", type=int, default=200,
                        help="Maximum cell count per patch (default: 200)")
    parser.add_argument("--max-rc-lo", type=int, default=5,
                        help="Lowest max_region_cells to test (default: 5)")
    parser.add_argument("--max-rc-hi", type=int, default=8,
                        help="Highest max_region_cells to test (default: 8)")
    args = parser.parse_args()

    rc_lo = args.max_rc_lo
    rc_hi = args.max_rc_hi
    max_cells = args.max_cells

    print("╔═══════════════════════════════════════════════════════════╗")
    print("║  sup(S/area) = 1/2 ?  —  The Discrete Bekenstein–Hawking ║")
    print("║  Sweep max_rc from {0} to {1} on Dense patches{2}║".format(
        rc_lo, rc_hi, " " * (14 - len(str(rc_lo)) - len(str(rc_hi)))))
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"\n  Parameters:")
    print(f"    max-cells:    {max_cells}")
    print(f"    max-rc range: {rc_lo}..{rc_hi}")
    print(f"\n  Question: Does sup_r S(r)/area(r) = 0.5000 persist")
    print(f"  when we allow LARGER regions (6, 7, 8 cells)?")
    print(f"  Or is it an artifact of the k≤5 measurement window?\n")

    # ── Initialize geometries ───────────────────────────────────────
    print("  Initializing {4,3,5} Coxeter geometry ...")
    G435 = multi.build_gram_matrix()
    refls435 = multi.build_reflections(G435)
    cc435 = multi.find_cell_center(G435)
    stab435 = multi.enumerate_group(refls435[:3], expected=48)
    fc435 = multi.find_face_crossings(refls435, stab435, G435)
    print("  ✓  {4,3,5} ready.")

    print("  Initializing {5,4} Coxeter geometry ...")
    G54 = layer_mod.build_gram_matrix()
    refls54 = layer_mod.build_reflections(G54)
    layer_mod.validate_reflections(G54, refls54)
    tc54 = layer_mod.find_tile_center(G54)
    stab54 = layer_mod.enumerate_group(refls54[:2], expected=10)
    ec54 = layer_mod.find_edge_crossings(refls54, stab54, G54)
    print("  ✓  {5,4} ready.\n")

    all_results: list[SweepResult] = []

    # ── {4,3,5} Dense patches at varying max_rc ────────────────────
    dense435_sizes = [n for n in [50, 100, 200] if n <= max_cells]
    rc_values = list(range(rc_lo, rc_hi + 1))

    print(f"  ═══  {{4,3,5}} Dense — max_rc sweep ({rc_lo}..{rc_hi})  ═══")

    # Pre-build patches (same patch, different max_rc)
    patches_435: dict[int, dict] = {}
    for max_c in dense435_sizes:
        print(f"    Building Dense-{max_c} ...", end="", flush=True)
        patches_435[max_c] = multi.build_patch_dense(
            fc435, cc435, max_c, name=f"Dense-{max_c}")
        nc = len(patches_435[max_c]["cells"])
        print(f"  {nc} cells")

    results_435: list[SweepResult] = []
    for max_c in dense435_sizes:
        patch = patches_435[max_c]
        for rc in rc_values:
            label = f"D{max_c}-rc{rc}"
            print(f"    {label} ...", end="", flush=True)
            r = analyze_sweep_point(
                patch, label, "{4,3,5}", "Dense", 6, rc,
                multi.build_flow_graph, _enum_435, "internal_faces")
            results_435.append(r)
            all_results.append(r)
            print(f"  {r.n_regions:>5d} regions, "
                  f"sup={r.sup_ratio:.4f}, "
                  f"η={r.eta_global:.4f}, "
                  f"viol={r.n_violations}  ({r.elapsed:.1f}s)")

    # ── {5,4} Dense patches at varying max_rc ──────────────────────
    dense54_sizes = [n for n in [50, 100, 200] if n <= max_cells]

    print(f"\n  ═══  {{5,4}} Dense — max_rc sweep ({rc_lo}..{rc_hi})  ═══")

    patches_54: dict[int, dict] = {}
    for max_t in dense54_sizes:
        print(f"    Building 54Dense-{max_t} ...", end="", flush=True)
        patches_54[max_t] = build_54_dense_patch(
            ec54, tc54, max_t, name=f"54Dense-{max_t}")
        nt = len(patches_54[max_t]["tiles"])
        print(f"  {nt} tiles")

    results_54: list[SweepResult] = []
    for max_t in dense54_sizes:
        patch = patches_54[max_t]
        for rc in rc_values:
            label = f"54D{max_t}-rc{rc}"
            print(f"    {label} ...", end="", flush=True)
            r = analyze_sweep_point(
                patch, label, "{5,4}", "Dense", 5, rc,
                layer_mod.build_flow_graph, _enum_54, "internal_bonds")
            results_54.append(r)
            all_results.append(r)
            print(f"  {r.n_regions:>5d} regions, "
                  f"sup={r.sup_ratio:.4f}, "
                  f"η={r.eta_global:.4f}, "
                  f"viol={r.n_violations}  ({r.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  Output Tables
    # ════════════════════════════════════════════════════════════════

    print(f"\n{'═' * 80}")
    print(f"  RESULTS — sup(S/area) ACROSS max_rc VALUES")
    print(f"{'═' * 80}")

    print_sweep_table("{4,3,5} Dense — max_rc sweep", results_435)
    print_sweep_table("{5,4} Dense — max_rc sweep", results_54)

    # ── Per-size sup tables ─────────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  PER-REGION-SIZE sup(S/area) = max_{{|A|=k}} S(A)/area(A)")
    print(f"{'═' * 80}")

    print_per_size_sup_table("{4,3,5} Dense — per-size sup",
                             results_435)
    print_per_size_sup_table("{5,4} Dense — per-size sup",
                             results_54)

    # ── The Key Question ────────────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  THE KEY QUESTION: Is sup(S/area) = 1/2 universal?")
    print(f"{'═' * 80}")

    # Collect all sup values
    all_sups = [(r.label, r.tiling, r.max_rc, r.sup_ratio,
                 r.n_violations, r.n_regions)
                for r in all_results]

    # Check: does sup ever exceed 0.5?
    exceeds = [x for x in all_sups if x[3] > 0.5 + 1e-9]
    # Check: does sup ever fall below 0.5 for Dense patches?
    below = [x for x in all_sups if x[3] < 0.5 - 1e-9]

    print(f"\n  Total measurements:  {len(all_sups)}")
    print(f"  sup(S/area) > 0.5:  {len(exceeds)} cases")
    print(f"  sup(S/area) < 0.5:  {len(below)} cases")
    print(f"  sup(S/area) = 0.5:  {len(all_sups) - len(exceeds) - len(below)} cases")

    if exceeds:
        print(f"\n  ✗ VIOLATIONS (S/area > 1/2):")
        for label, tiling, rc, sup, viol, nreg in exceeds:
            print(f"    {label}: {tiling} rc={rc}, sup={sup:.6f}, "
                  f"{viol} violating regions / {nreg} total")
    else:
        print(f"\n  ✓ NO VIOLATIONS: S(A)/area(A) ≤ 0.5 for all "
              f"{sum(r.n_regions for r in all_results)} regions tested.")

    if below:
        print(f"\n  ↓ BELOW 0.5 (sup not achieved):")
        for label, tiling, rc, sup, viol, nreg in below:
            print(f"    {label}: {tiling} rc={rc}, sup={sup:.4f} ({nreg} regions)")
    else:
        print(f"  ✓ sup = 0.5 ACHIEVED in every measurement.")

    # ── max_rc dependence ───────────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  max_rc DEPENDENCE: Does larger max_rc change sup?")
    print(f"{'═' * 80}")

    for patch_size in dense435_sizes:
        pts = [r for r in results_435
               if r.n_cells_patch == len(patches_435[patch_size]["cells"])]
        if pts:
            sups = [(r.max_rc, r.sup_ratio) for r in pts]
            print(f"\n  {{4,3,5}} Dense-{patch_size}:")
            for rc, sup in sups:
                print(f"    max_rc={rc}: sup(S/area) = {sup:.4f}")
            vals = [s for _, s in sups]
            if max(vals) - min(vals) < 1e-9:
                print(f"    → STABLE across max_rc (all = {vals[0]:.4f})")
            else:
                print(f"    → VARIES: {min(vals):.4f} – {max(vals):.4f}")

    for patch_size in dense54_sizes:
        pts = [r for r in results_54
               if r.n_cells_patch == len(patches_54[patch_size]["tiles"])]
        if pts:
            sups = [(r.max_rc, r.sup_ratio) for r in pts]
            print(f"\n  {{5,4}} Dense-{patch_size}:")
            for rc, sup in sups:
                print(f"    max_rc={rc}: sup(S/area) = {sup:.4f}")
            vals = [s for _, s in sups]
            if max(vals) - min(vals) < 1e-9:
                print(f"    → STABLE across max_rc (all = {vals[0]:.4f})")
            else:
                print(f"    → VARIES: {min(vals):.4f} – {max(vals):.4f}")

    # ── Achiever analysis ───────────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  ACHIEVER ANALYSIS: Which regions reach S/area = 0.5?")
    print(f"{'═' * 80}")

    for r in all_results:
        if abs(r.sup_ratio - 0.5) < 1e-9:
            pass  # standard
        else:
            print(f"  {r.label}: sup={r.sup_ratio:.4f} "
                  f"(achiever: k={r.achiever_size} "
                  f"S={r.achiever_S} A={r.achiever_area})")

    # Group achievers by size
    achiever_sizes_435 = Counter(
        r.achiever_size for r in results_435 if abs(r.sup_ratio - 0.5) < 1e-9)
    achiever_sizes_54 = Counter(
        r.achiever_size for r in results_54 if abs(r.sup_ratio - 0.5) < 1e-9)

    if achiever_sizes_435:
        print(f"\n  {{4,3,5}} Dense — achiever region sizes (when sup=0.5):")
        for k, cnt in sorted(achiever_sizes_435.items()):
            print(f"    k={k}: {cnt} measurements")

    if achiever_sizes_54:
        print(f"\n  {{5,4}} Dense — achiever region sizes (when sup=0.5):")
        for k, cnt in sorted(achiever_sizes_54.items()):
            print(f"    k={k}: {cnt} measurements")

    # ── Verdict ─────────────────────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  VERDICT")
    print(f"{'═' * 80}")

    n_total = sum(r.n_regions for r in all_results)
    n_exact = len([r for r in all_results if abs(r.sup_ratio - 0.5) < 1e-9])
    n_meas = len(all_results)

    if not exceeds and not below:
        print(f"""
  ★  sup(S/area) = 1/2 EXACTLY, for ALL {n_meas} (patch, max_rc)
     combinations tested across {n_total} total regions.

  The bound S(A) ≤ area(A)/2 is:
    • TIGHT  (achieved by at least one region in every patch)
    • UNIVERSAL  (holds for both {{4,3,5}} cubes and {{5,4}} pentagons)
    • max_rc-INDEPENDENT  (stable from rc={rc_lo} to rc={rc_hi})

  This is the discrete Bekenstein–Hawking formula:
    S = area / (4G)  with  1/(4G) = 1/2  in bond-dimension-1 units.

  Next: prove this as a graph-theoretic THEOREM (not just data).
  The bound S ≤ area/2 should follow from the max-flow / min-cut
  theorem applied to the trivial cut of a Dense cell cluster.
""")
    elif not exceeds and below:
        print(f"""
  sup(S/area) ≤ 0.5 in all {n_meas} measurements ({n_total} regions).
  No violations of the 1/2 bound.
  BUT sup < 0.5 in {len(below)} cases — the bound is not always tight.
  Tightness may require larger patches or specific region geometries.
""")
    else:
        print(f"""
  ✗  VIOLATIONS FOUND: {len(exceeds)} measurements have sup > 0.5.
  The 1/2 bound does NOT hold universally.
  Review the violating cases to understand the mechanism.
""")

    # ── Timing ──────────────────────────────────────────────────────
    total_time = sum(r.elapsed for r in all_results)
    print(f"  Total: {n_meas} measurements, {n_total} regions, "
          f"{total_time:.1f}s\n")


if __name__ == "__main__":
    main()