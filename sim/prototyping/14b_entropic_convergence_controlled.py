#!/usr/bin/env python3
"""
15_entropic_convergence_controlled.py — Milestone I (Controlled)

Fixes the confounded measurement in 14_entropic_convergence.py by
running Dense patches at FIXED max_region_cells=5 across all sizes,
eliminating the adaptive cap that caused both max S and max area to
fall at Dense-500+.

Additional improvements over 14:
  (a) Per-region-size η(k, N) tracking:  for each patch size N and
      each region size k ∈ {1,2,3,4,5}, compute
        η(k, N) = max_{|A|=k} S(A) / max_{|A|=k} area(A)
      If each η(k, ·) converges independently as N → ∞, and they
      converge to the same value for all k, that is strong evidence.

  (b) {5,4} Dense growth strategy:  greedy max-connectivity growth
      on the pentagonal tiling (adapting 07's approach from cubes
      to pentagons), producing multiply-connected 2D patches with
      non-trivial min-cuts — unlike the degenerate BFS-depth series.

  (c) Per-region S/area distribution:  for each patch, compute
      the full distribution of S(r)/area(r) across all regions r.
      Track the supremum, mean, and quartiles.

  (d) Dimension-dependent rescaling:  test whether max S / N^{d/(d+1)}
      converges, where d=3 for {4,3,5} and d=2 for {5,4}.

Usage:
  python3 sim/prototyping/15_entropic_convergence_controlled.py
  python3 sim/prototyping/15_entropic_convergence_controlled.py --dense-only
  python3 sim/prototyping/15_entropic_convergence_controlled.py --max-cells 1000

Dependencies:  numpy, networkx

Reference:
  docs/10-frontier.md §15.9.7  (Milestone I — the research program)
  14_entropic_convergence_OUTPUT.txt  (confounded data)
  Output-evaluation.md  (diagnosis and plan)
"""

from __future__ import annotations

import argparse
import importlib
import math
import sys
import time
from collections import Counter, defaultdict, deque
from pathlib import Path
from typing import NamedTuple

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

try:
    multi = importlib.import_module("07_honeycomb_3d_multiStrategy")
except ModuleNotFoundError:
    sys.exit(
        "ERROR: Could not import 07_honeycomb_3d_multiStrategy.py.\n"
        "       Run from the repository root."
    )

try:
    layer_mod = importlib.import_module("13_generate_layerN")
except ModuleNotFoundError:
    sys.exit(
        "ERROR: Could not import 13_generate_layerN.py.\n"
        "       Run from the repository root."
    )

try:
    import numpy as np
    import networkx as nx
except ImportError:
    sys.exit("ERROR: numpy and networkx are required.  "
             "pip install numpy networkx")


# ════════════════════════════════════════════════════════════════════
#  1.  Data Structures
# ════════════════════════════════════════════════════════════════════

class RegionDatum(NamedTuple):
    """Per-region measurement."""
    n_cells: int        # number of cells in the region
    min_cut: int        # S(A)
    area: int           # boundary area
    ratio: float        # S(A) / area(A)


class PatchResult(NamedTuple):
    """Full result for one patch."""
    tiling: str
    strategy: str
    label: str
    n_cells_patch: int
    max_rc: int
    n_regions: int
    max_S: int
    max_area: int
    eta_global: float           # max_S / max_area
    per_size: dict               # k → {max_S, max_area, eta, count}
    ratio_sup: float             # sup_r S(r)/area(r)
    ratio_mean: float            # mean_r S(r)/area(r)
    ratio_q25: float
    ratio_q75: float
    rescaled_S: float            # max_S / N^{d/(d+1)}
    elapsed: float


# ════════════════════════════════════════════════════════════════════
#  2.  Boundary Area (unified 2D / 3D)
# ════════════════════════════════════════════════════════════════════

def compute_boundary_area(
    cells: frozenset[int],
    internal_links: list[tuple[int, int]],
    faces_per_cell: int,
) -> int:
    """
    area(A) = faces_per_cell · |A| − 2 · |{links within A}|
    """
    internal_within = sum(
        1 for c1, c2 in internal_links
        if c1 in cells and c2 in cells
    )
    return faces_per_cell * len(cells) - 2 * internal_within


# ════════════════════════════════════════════════════════════════════
#  3.  {5,4} Dense Growth Strategy (NEW — Phase B)
# ════════════════════════════════════════════════════════════════════
#
#  Adapts the greedy max-connectivity strategy from 07 (cubes) to
#  the {5,4} pentagonal tiling (5 edges per tile, 4 tiles per vertex).
#  This produces multiply-connected 2D patches with non-trivial
#  min-cuts, unlike the degenerate BFS-depth series.

def build_54_dense_patch(
    edge_crossings: list[np.ndarray],
    tile_center: np.ndarray,
    max_tiles: int,
    name: str = "dense-54",
) -> dict:
    """
    Greedy growth on the {5,4} tiling: always add the frontier tile
    adjacent to the most existing patch tiles.
    """
    p = tile_center
    tiles: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}

    def register(mat: np.ndarray) -> tuple[int, bool]:
        c = mat @ p
        k = layer_mod._vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        tid = len(tiles)
        tiles[tid] = mat
        center_to_id[k] = tid
        return tid, True

    def patch_adj_count(mat: np.ndarray) -> int:
        count = 0
        for F in edge_crossings:
            if layer_mod._vec_key((mat @ F) @ p) in center_to_id:
                count += 1
        return count

    register(np.eye(3))

    while len(tiles) < max_tiles:
        frontier: dict[tuple, np.ndarray] = {}
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

    # Finalize: compute neighbors, bonds, boundary
    neighbors: dict[int, set[int]] = defaultdict(set)
    for tid, g in tiles.items():
        for F in edge_crossings:
            ck = layer_mod._vec_key((g @ F) @ p)
            if ck in center_to_id:
                nid = center_to_id[ck]
                if nid != tid:
                    neighbors[tid].add(nid)
                    neighbors[nid].add(tid)

    internal_bonds: list[tuple[int, int]] = []
    seen_pairs: set[frozenset[int]] = set()
    for tid, nbrs in neighbors.items():
        for nid in nbrs:
            pair = frozenset([tid, nid])
            if pair not in seen_pairs:
                seen_pairs.add(pair)
                internal_bonds.append((min(tid, nid), max(tid, nid)))

    bdy_per_tile: dict[int, int] = {}
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
#  4.  Unified Patch Analyzer
# ════════════════════════════════════════════════════════════════════

def analyze_patch_controlled(
    patch: dict,
    label: str,
    tiling: str,
    strategy: str,
    faces_per_cell: int,
    dim: int,
    fixed_max_rc: int,
    flow_graph_builder,
    region_enumerator,
    internal_links_key: str,
) -> PatchResult:
    """
    Analyze a patch with FIXED max_region_cells, computing:
      - Global η = max_S / max_area
      - Per-size η(k, N) for k = 1..fixed_max_rc
      - S/area distribution stats
      - Dimension-dependent rescaling
    """
    t0 = time.time()

    n_cells = len(patch.get("cells", patch.get("tiles", {})))
    internal_links = patch[internal_links_key]

    flow_G, bnode_ids, bnode_to_cell = flow_graph_builder(patch)

    # Build cell → bnodes mapping
    cell_bnodes: dict[int, set[int]] = defaultdict(set)
    for idx in bnode_ids:
        cell_bnodes[bnode_to_cell[idx]].add(idx)

    # Enumerate regions at the fixed max_rc
    regions_raw = region_enumerator(
        patch, bnode_to_cell, bnode_ids, fixed_max_rc
    )

    # Collect per-region data
    all_data: list[RegionDatum] = []
    per_size_data: dict[int, list[RegionDatum]] = defaultdict(list)

    for item in regions_raw:
        # Handle both tuple (label, bnode_set) and RegionInfo formats
        if isinstance(item, tuple) and len(item) == 2:
            _lbl, bnode_set = item
            region_cells = frozenset(bnode_to_cell[idx] for idx in bnode_set)
        else:
            # RegionInfo from 13_generate_layerN
            region_cells = item.tiles
            bnode_set = set()
            for tid in region_cells:
                bnode_set.update(cell_bnodes[tid])

        s = _compute_mincut_for_set(flow_G, bnode_ids, bnode_set)
        area = compute_boundary_area(region_cells, internal_links,
                                     faces_per_cell)

        if area > 0 and s >= 0:
            ratio = s / area
            rd = RegionDatum(len(region_cells), s, area, ratio)
            all_data.append(rd)
            per_size_data[len(region_cells)].append(rd)

    # Compute global stats
    max_S = max((d.min_cut for d in all_data), default=0)
    max_area = max((d.area for d in all_data), default=0)
    eta_global = max_S / max_area if max_area > 0 else 0.0

    # Per-size stats
    per_size: dict[int, dict] = {}
    for k in sorted(per_size_data.keys()):
        ds = per_size_data[k]
        ms = max(d.min_cut for d in ds)
        ma = max(d.area for d in ds)
        eta_k = ms / ma if ma > 0 else 0.0
        per_size[k] = {"max_S": ms, "max_area": ma, "eta": eta_k,
                       "count": len(ds)}

    # Distribution stats
    ratios = sorted(d.ratio for d in all_data)
    n = len(ratios)
    ratio_sup = max(ratios) if ratios else 0.0
    ratio_mean = sum(ratios) / n if n > 0 else 0.0
    ratio_q25 = ratios[n // 4] if n >= 4 else (ratios[0] if ratios else 0.0)
    ratio_q75 = ratios[3 * n // 4] if n >= 4 else (ratios[-1] if ratios else 0.0)

    # Dimension-dependent rescaling: max_S / N^{d/(d+1)}
    exponent = dim / (dim + 1)
    rescaled = max_S / (n_cells ** exponent) if n_cells > 0 else 0.0

    elapsed = time.time() - t0

    return PatchResult(
        tiling=tiling, strategy=strategy, label=label,
        n_cells_patch=n_cells, max_rc=fixed_max_rc,
        n_regions=len(all_data), max_S=max_S, max_area=max_area,
        eta_global=eta_global, per_size=per_size,
        ratio_sup=ratio_sup, ratio_mean=ratio_mean,
        ratio_q25=ratio_q25, ratio_q75=ratio_q75,
        rescaled_S=rescaled, elapsed=elapsed,
    )


def _compute_mincut_for_set(
    G: nx.DiGraph, bnode_ids: list[int], region: set[int],
) -> int:
    """Min-cut separating a boundary region from its complement."""
    complement = set(bnode_ids) - region
    if not region or not complement:
        return 0
    H = G.copy()
    INF = 10_000
    for idx in bnode_ids:
        if idx in region:
            H.add_edge("__SRC__", f"b{idx}", capacity=INF)
        else:
            H.add_edge(f"b{idx}", "__SNK__", capacity=INF)
    try:
        val, _ = nx.minimum_cut(H, "__SRC__", "__SNK__")
        return int(round(val))
    except nx.NetworkXError:
        return -1


# ════════════════════════════════════════════════════════════════════
#  5.  {4,3,5} Region Enumerator Wrapper
# ════════════════════════════════════════════════════════════════════

def _enumerate_435_regions(patch, bnode_to_cell, bnode_ids, max_rc):
    """Wrapper returning (label, bnode_set) tuples from 07."""
    return multi.enumerate_cell_aligned_regions(
        patch, bnode_to_cell, bnode_ids,
        max_region_cells=max_rc,
    )


# ════════════════════════════════════════════════════════════════════
#  6.  {5,4} Region Enumerator Wrapper
# ════════════════════════════════════════════════════════════════════

def _enumerate_54_regions(patch, bnode_to_tile, bnode_ids, max_rc):
    """Wrapper returning RegionInfo from 13."""
    return layer_mod.enumerate_regions(
        patch, bnode_to_tile, bnode_ids, max_rc,
    )


# ════════════════════════════════════════════════════════════════════
#  7.  Output Formatting
# ════════════════════════════════════════════════════════════════════

def print_result_table(title: str, results: list[PatchResult]) -> None:
    """Print a formatted table of results."""
    print(f"\n  {title}:")
    if not results:
        print("    (no data)")
        return
    print(f"    {'Label':>14s} | {'N':>5s} | {'rc':>2s} | {'#reg':>5s} "
          f"| {'maxS':>4s} | {'maxA':>4s} | {'η':>7s} "
          f"| {'sup':>6s} | {'mean':>6s} | {'rscl':>7s} "
          f"| {'time':>6s}")
    print(f"    {'─' * 98}")
    for r in results:
        print(f"    {r.label:>14s} | {r.n_cells_patch:>5d} "
              f"| {r.max_rc:>2d} | {r.n_regions:>5d} "
              f"| {r.max_S:>4d} | {r.max_area:>4d} "
              f"| {r.eta_global:>7.4f} "
              f"| {r.ratio_sup:>6.4f} | {r.ratio_mean:>6.4f} "
              f"| {r.rescaled_S:>7.4f} "
              f"| {r.elapsed:>5.1f}s")


def print_per_size_table(title: str, results: list[PatchResult]) -> None:
    """Print per-region-size η(k, N) table."""
    print(f"\n  {title}:")
    if not results:
        print("    (no data)")
        return

    all_ks = sorted(set(k for r in results for k in r.per_size.keys()))
    if not all_ks:
        print("    (no per-size data)")
        return

    header = f"    {'Label':>14s}"
    for k in all_ks:
        header += f" | η(k={k})"
    print(header)
    print(f"    {'─' * (16 + 10 * len(all_ks))}")

    for r in results:
        line = f"    {r.label:>14s}"
        for k in all_ks:
            if k in r.per_size:
                ps = r.per_size[k]
                line += f" | {ps['eta']:>6.4f}"
            else:
                line += f" |    ---"
        print(line)


def assess_convergence(series_name: str, values: list[float],
                       labels: list[str]) -> None:
    """Assess whether a sequence of values converges."""
    if len(values) < 2:
        print(f"    {series_name}: insufficient data")
        return

    diffs = [values[i + 1] - values[i] for i in range(len(values) - 1)]

    print(f"    {series_name}:")
    print(f"      values:  "
          + ", ".join(f"{v:.4f}" for v in values))
    print(f"      Δ:       "
          + ", ".join(f"{d:+.4f}" for d in diffs))

    if len(diffs) >= 2:
        abs_diffs = [abs(d) for d in diffs]
        shrinking = all(abs_diffs[i + 1] <= abs_diffs[i] + 1e-10
                        for i in range(len(abs_diffs) - 1))
        if shrinking and abs(diffs[-1]) < 0.02:
            print(f"      Assessment: differences shrinking → "
                  f"likely converging near {values[-1]:.4f}")
        elif shrinking:
            print(f"      Assessment: differences shrinking "
                  f"(not yet stabilized)")
        else:
            print(f"      Assessment: differences NOT monotonically "
                  f"shrinking → inconclusive")
    else:
        print(f"      Assessment: only 2 points → insufficient")


# ════════════════════════════════════════════════════════════════════
#  8.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Controlled η_N convergence measurement "
                    "(fixed max_region_cells, per-size tracking, "
                    "{5,4} Dense growth, distribution stats, rescaling).")
    parser.add_argument(
        "--max-cells", type=int, default=500,
        help="Maximum cell/tile count (default: 500)")
    parser.add_argument(
        "--max-region-cells", type=int, default=5,
        help="FIXED max region cells for ALL patches (default: 5)")
    parser.add_argument(
        "--dense-only", action="store_true",
        help="Skip BFS-shell and {5,4} BFS-depth series")
    parser.add_argument(
        "--max-depth-54", type=int, default=5,
        help="Max BFS depth for {5,4} tiling (default: 5)")
    args = parser.parse_args()

    FIXED_RC = args.max_region_cells
    max_cells = args.max_cells

    print("╔═══════════════════════════════════════════════════════════╗")
    print("║  Milestone I (Controlled): Entropic Convergence           ║")
    print("║  Fixed max_region_cells • Per-size tracking • {5,4} Dense ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"\n  Parameters:")
    print(f"    max-cells:         {max_cells}")
    print(f"    max-region-cells:  {FIXED_RC}  (FIXED for all patches)")
    print(f"    dense-only:        {args.dense_only}")
    print(f"    max-depth-54:      {args.max_depth_54}")

    print(f"\n  CRITICAL FIX vs 14_entropic_convergence.py:")
    print(f"    14 used ADAPTIVE max_rc (5→4→3→2 as N grew),")
    print(f"    causing both max S and max area to FALL at N≥500.")
    print(f"    15 uses FIXED max_rc={FIXED_RC} for all N,")
    print(f"    ensuring comparable measurement windows.\n")

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
    print("  ✓  {5,4} ready.")

    all_results: list[PatchResult] = []

    # ════════════════════════════════════════════════════════════════
    #  A.  {4,3,5} Dense — CONTROLLED (fixed max_rc)
    # ════════════════════════════════════════════════════════════════

    dense435_targets = [n for n in [50, 100, 200, 500, 1000]
                        if n <= max_cells]
    dense435_results: list[PatchResult] = []

    print(f"\n  ═══  {{4,3,5}} Dense (FIXED max_rc={FIXED_RC})  ═══")
    for max_c in dense435_targets:
        label = f"Dense-{max_c}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch_dense(fc435, cc435, max_c, name=label)
        r = analyze_patch_controlled(
            patch, label, "{4,3,5}", "Dense", 6, 3, FIXED_RC,
            multi.build_flow_graph, _enumerate_435_regions,
            "internal_faces",
        )
        dense435_results.append(r)
        all_results.append(r)
        print(f"  {r.n_cells_patch} cells, {r.n_regions} regions, "
              f"η={r.eta_global:.4f}, sup(S/A)={r.ratio_sup:.4f}  "
              f"({r.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  B.  {5,4} Dense — NEW (greedy max-connectivity on pentagons)
    # ════════════════════════════════════════════════════════════════

    dense54_targets = [n for n in [20, 50, 100, 200, 500]
                       if n <= max_cells]
    dense54_results: list[PatchResult] = []

    print(f"\n  ═══  {{5,4}} Dense (FIXED max_rc={FIXED_RC})  ═══")
    for max_t in dense54_targets:
        label = f"54Dense-{max_t}"
        print(f"    {label} ...", end="", flush=True)
        patch = build_54_dense_patch(ec54, tc54, max_t, name=label)
        r = analyze_patch_controlled(
            patch, label, "{5,4}", "Dense", 5, 2, FIXED_RC,
            layer_mod.build_flow_graph, _enumerate_54_regions,
            "internal_bonds",
        )
        dense54_results.append(r)
        all_results.append(r)
        print(f"  {r.n_cells_patch} tiles, {r.n_regions} regions, "
              f"η={r.eta_global:.4f}, sup(S/A)={r.ratio_sup:.4f}  "
              f"({r.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  C.  {4,3,5} BFS-shell (baseline, optional)
    # ════════════════════════════════════════════════════════════════

    bfs435_results: list[PatchResult] = []
    if not args.dense_only:
        bfs_targets = [n for n in [7, 25, 50, 100, 200]
                       if n <= max_cells]
        print(f"\n  ═══  {{4,3,5}} BFS-shell (FIXED max_rc={FIXED_RC})  ═══")
        for max_c in bfs_targets:
            label = f"BFS-{max_c}"
            print(f"    {label} ...", end="", flush=True)
            patch = multi.build_patch(fc435, cc435, max_c, name=label)
            r = analyze_patch_controlled(
                patch, label, "{4,3,5}", "BFS-shell", 6, 3, FIXED_RC,
                multi.build_flow_graph, _enumerate_435_regions,
                "internal_faces",
            )
            bfs435_results.append(r)
            all_results.append(r)
            print(f"  {r.n_cells_patch} cells, {r.n_regions} regions, "
                  f"η={r.eta_global:.4f}  ({r.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  D.  {5,4} BFS-depth (baseline, optional)
    # ════════════════════════════════════════════════════════════════

    bfs54_results: list[PatchResult] = []
    if not args.dense_only:
        depths_54 = list(range(2, args.max_depth_54 + 1))
        print(f"\n  ═══  {{5,4}} BFS-depth (FIXED max_rc={FIXED_RC})  ═══")
        for depth in depths_54:
            label = f"d={depth}"
            print(f"    depth {depth} ...", end="", flush=True)
            patch = layer_mod.build_layer_patch(
                ec54, tc54, depth,
                name=f"{{5,4}} depth {depth}",
            )
            r = analyze_patch_controlled(
                patch, label, "{5,4}", "BFS-depth", 5, 2, FIXED_RC,
                layer_mod.build_flow_graph, _enumerate_54_regions,
                "internal_bonds",
            )
            bfs54_results.append(r)
            all_results.append(r)
            print(f"  {r.n_cells_patch} tiles, {r.n_regions} regions, "
                  f"η={r.eta_global:.4f}  ({r.elapsed:.1f}s)")

    # ════════════════════════════════════════════════════════════════
    #  Output
    # ════════════════════════════════════════════════════════════════

    print(f"\n{'═' * 80}")
    print(f"  RESULTS (all at fixed max_rc = {FIXED_RC})")
    print(f"{'═' * 80}")

    print_result_table("{4,3,5} Dense (CONTROLLED)", dense435_results)
    print_result_table("{5,4} Dense (NEW)", dense54_results)
    if bfs435_results:
        print_result_table("{4,3,5} BFS-shell (baseline)", bfs435_results)
    if bfs54_results:
        print_result_table("{5,4} BFS-depth (baseline)", bfs54_results)

    # ── Per-size η(k, N) tables ─────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  PER-REGION-SIZE η(k, N) = max_{{|A|=k}} S / max_{{|A|=k}} area")
    print(f"{'═' * 80}")

    print_per_size_table("{4,3,5} Dense — η(k, N)", dense435_results)
    print_per_size_table("{5,4} Dense — η(k, N)", dense54_results)

    # ── Convergence Assessment ──────────────────────────────────────
    print(f"\n{'═' * 80}")
    print(f"  CONVERGENCE ASSESSMENT")
    print(f"{'═' * 80}\n")

    if dense435_results:
        assess_convergence(
            "{4,3,5} Dense η (global)",
            [r.eta_global for r in dense435_results],
            [r.label for r in dense435_results],
        )
        print()
        assess_convergence(
            "{4,3,5} Dense sup(S/area)",
            [r.ratio_sup for r in dense435_results],
            [r.label for r in dense435_results],
        )
        print()
        assess_convergence(
            "{4,3,5} Dense mean(S/area)",
            [r.ratio_mean for r in dense435_results],
            [r.label for r in dense435_results],
        )
        print()
        assess_convergence(
            "{4,3,5} Dense rescaled max_S / N^{3/4}",
            [r.rescaled_S for r in dense435_results],
            [r.label for r in dense435_results],
        )
        print()

        # Per-size convergence for the largest k present everywhere
        common_ks = None
        for r in dense435_results:
            ks = set(r.per_size.keys())
            common_ks = ks if common_ks is None else common_ks & ks
        if common_ks:
            for k in sorted(common_ks):
                assess_convergence(
                    f"{{4,3,5}} Dense η(k={k}, N)",
                    [r.per_size[k]["eta"] for r in dense435_results],
                    [r.label for r in dense435_results],
                )
                print()

    if dense54_results:
        assess_convergence(
            "{5,4} Dense η (global)",
            [r.eta_global for r in dense54_results],
            [r.label for r in dense54_results],
        )
        print()
        assess_convergence(
            "{5,4} Dense rescaled max_S / N^{2/3}",
            [r.rescaled_S for r in dense54_results],
            [r.label for r in dense54_results],
        )
        print()

    # ── Tiling Universality ─────────────────────────────────────────
    if dense435_results and dense54_results:
        print(f"\n{'═' * 80}")
        print(f"  TILING UNIVERSALITY CHECK (Dense only)")
        print(f"{'═' * 80}")
        print(f"\n  Do {'{4,3,5}'} Dense and {'{5,4}'} Dense converge "
              f"to the same η?")
        last_435 = dense435_results[-1]
        last_54 = dense54_results[-1]
        print(f"    {'{4,3,5}'} Dense latest η = {last_435.eta_global:.4f}"
              f"  (N={last_435.n_cells_patch})")
        print(f"    {'{5,4}'}  Dense latest η = {last_54.eta_global:.4f}"
              f"  (N={last_54.n_cells_patch})")
        gap = abs(last_435.eta_global - last_54.eta_global)
        print(f"    Gap: {gap:.4f}")
        if gap < 0.05:
            print(f"    → Values are close — consistent with universality")
        else:
            print(f"    → Gap is significant — more data needed")

    # ── Strategy Comparison ─────────────────────────────────────────
    if dense435_results and bfs435_results:
        print(f"\n{'═' * 80}")
        print(f"  STRATEGY COMPARISON: Dense vs BFS on {{4,3,5}}")
        print(f"{'═' * 80}")
        for dr in dense435_results:
            closest_bfs = min(bfs435_results,
                              key=lambda b: abs(b.n_cells_patch -
                                                dr.n_cells_patch),
                              default=None)
            if closest_bfs:
                print(f"    N≈{dr.n_cells_patch:>5d}: "
                      f"Dense η={dr.eta_global:.4f} "
                      f"(S={dr.max_S}, A={dr.max_area}), "
                      f"BFS η={closest_bfs.eta_global:.4f} "
                      f"(S={closest_bfs.max_S}, A={closest_bfs.max_area})")

    # ── Summary ─────────────────────────────────────────────────────
    total_time = sum(r.elapsed for r in all_results)
    total_regions = sum(r.n_regions for r in all_results)
    print(f"\n{'═' * 80}")
    print(f"  Total: {len(all_results)} patches, "
          f"{total_regions} regions, {total_time:.1f}s")
    print(f"\n  KEY DIFFERENCE from 14:")
    print(f"    14: adaptive max_rc → confounded η at large N")
    print(f"    15: fixed max_rc={FIXED_RC} → comparable windows")
    if dense435_results:
        print(f"\n  {'{4,3,5}'} Dense unconfounded data points:")
        for r in dense435_results:
            print(f"    {r.label:>14s}: max S = {r.max_S:>2d}, "
                  f"max area = {r.max_area:>3d}, η = {r.eta_global:.4f}"
                  f"  (max_rc={r.max_rc})")
    print()


if __name__ == "__main__":
    main()