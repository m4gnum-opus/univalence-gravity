#!/usr/bin/env python3
"""
14_entropic_convergence.py — Milestone I of §15.9.7

Track η_N = max S_N / max area_N across resolutions, growth
strategies, and tiling types.  Test whether η_N converges, and
if so, whether the limit is universal.

Tests:
  (a) Strategy universality: BFS-shell vs Dense on {4,3,5}
  (b) Tiling universality:   {5,4} (2D) vs {4,3,5} (3D)
  (c) Convergence:           does η_N stabilize as N → ∞?

Usage:
  python3 sim/prototyping/14_entropic_convergence.py
  python3 sim/prototyping/14_entropic_convergence.py --max-cells 5000
  python3 sim/prototyping/14_entropic_convergence.py --max-region-cells 3

Dependencies:  numpy, networkx

Reference:
  docs/10-frontier.md §15.9  (Entropic Convergence Conjecture)
  docs/10-frontier.md §15.9.4 (why this route is viable)
  docs/10-frontier.md §15.9.7 (the research program — Milestone I)
"""

from __future__ import annotations

import argparse
import importlib
import sys
import time
from collections import defaultdict
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
    layer = importlib.import_module("13_generate_layerN")
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

class ConvergencePoint(NamedTuple):
    """One data point in the η_N convergence table."""
    tiling: str         # "{4,3,5}" or "{5,4}"
    strategy: str       # "Dense", "BFS-shell", "BFS-depth"
    label: str          # human-readable label, e.g. "Dense-100"
    n_cells: int        # number of cells/tiles in the patch
    n_regions: int      # number of regions enumerated
    max_S: int          # maximum min-cut value across all regions
    max_area: int       # maximum boundary area across all regions
    eta: float          # η = max_S / max_area
    elapsed: float      # computation time in seconds


# ════════════════════════════════════════════════════════════════════
#  2.  Boundary Area Computation (unified 2D / 3D)
# ════════════════════════════════════════════════════════════════════

def compute_boundary_area(
    cells: frozenset[int],
    internal_links: list[tuple[int, int]],
    faces_per_cell: int,
) -> int:
    """
    Boundary area of a cell-aligned region.

    For a region A of k cells, each cell has `faces_per_cell` faces
    (6 for cubes in {4,3,5}, 5 for pentagons in {5,4}).  Each
    internal link (bond/face) shared between two A-cells is counted
    by both, so we subtract 2 per internal link.

    area(A) = faces_per_cell · |A| − 2 · |{links within A}|
    """
    internal_within = sum(
        1 for c1, c2 in internal_links
        if c1 in cells and c2 in cells
    )
    return faces_per_cell * len(cells) - 2 * internal_within


# ════════════════════════════════════════════════════════════════════
#  3.  Adaptive Max-Region-Cells
# ════════════════════════════════════════════════════════════════════

def adaptive_max_rc(n_cells: int, user_max_rc: int | None) -> int:
    """
    Choose max_region_cells adaptively based on patch size.

    Large patches produce combinatorially many connected subsets;
    reducing max_region_cells keeps computation tractable while
    still capturing the max S and max area values.
    """
    if user_max_rc is not None:
        return user_max_rc
    if n_cells <= 200:
        return 5
    elif n_cells <= 500:
        return 4
    elif n_cells <= 1000:
        return 3
    else:
        return 2


# ════════════════════════════════════════════════════════════════════
#  4.  {4,3,5} 3D Patch Analysis
# ════════════════════════════════════════════════════════════════════

def init_435_geometry():
    """Initialize the {4,3,5} Coxeter geometry (done once)."""
    G = multi.build_gram_matrix()
    refls = multi.build_reflections(G)
    cell_center = multi.find_cell_center(G)
    stab = multi.enumerate_group(refls[:3], expected=48)
    face_crossings = multi.find_face_crossings(refls, stab, G)
    adj_pairs, opp_pairs = multi.classify_face_pairs(face_crossings)
    return {
        "face_crossings": face_crossings,
        "cell_center": cell_center,
        "adj_pairs": adj_pairs,
        "opp_pairs": opp_pairs,
    }


def analyze_435_patch(
    patch: dict,
    label: str,
    strategy: str,
    user_max_rc: int | None,
) -> ConvergencePoint:
    """
    Analyze a {4,3,5} 3D patch: enumerate regions, compute min-cuts
    and boundary areas, return a ConvergencePoint.
    """
    t0 = time.time()
    n_cells = len(patch["cells"])
    max_rc = adaptive_max_rc(n_cells, user_max_rc)

    flow_G, bnode_ids, bnode_to_cell = multi.build_flow_graph(patch)
    internal_faces = patch["internal_faces"]

    # Build cell → bnodes mapping
    cell_bnodes: dict[int, set[int]] = defaultdict(set)
    for idx in bnode_ids:
        cell_bnodes[bnode_to_cell[idx]].add(idx)

    # Enumerate regions
    regions_raw = multi.enumerate_cell_aligned_regions(
        patch, bnode_to_cell, bnode_ids,
        max_region_cells=max_rc,
    )

    max_S = 0
    max_area = 0
    n_regions = 0

    for _label, bnode_set in regions_raw:
        # Extract cell set from bnodes
        region_cells = frozenset(bnode_to_cell[idx] for idx in bnode_set)

        # Min-cut
        s = multi.compute_min_cut(flow_G, bnode_ids, bnode_set)

        # Boundary area (6 faces per cube)
        area = compute_boundary_area(region_cells, internal_faces, 6)

        if s > max_S:
            max_S = s
        if area > max_area:
            max_area = area
        n_regions += 1

    eta = max_S / max_area if max_area > 0 else 0.0
    elapsed = time.time() - t0

    return ConvergencePoint(
        tiling="{4,3,5}",
        strategy=strategy,
        label=label,
        n_cells=n_cells,
        n_regions=n_regions,
        max_S=max_S,
        max_area=max_area,
        eta=eta,
        elapsed=elapsed,
    )


# ════════════════════════════════════════════════════════════════════
#  5.  {5,4} 2D Patch Analysis
# ════════════════════════════════════════════════════════════════════

def init_54_geometry():
    """Initialize the {5,4} Coxeter geometry (done once)."""
    G = layer.build_gram_matrix()
    refls = layer.build_reflections(G)
    layer.validate_reflections(G, refls)
    tile_center = layer.find_tile_center(G)
    stab = layer.enumerate_group(refls[:2], expected=10)
    edge_crossings = layer.find_edge_crossings(refls, stab, G)
    return {
        "edge_crossings": edge_crossings,
        "tile_center": tile_center,
    }


def analyze_54_patch(
    patch: dict,
    label: str,
    user_max_rc: int | None,
) -> ConvergencePoint:
    """
    Analyze a {5,4} 2D patch: enumerate regions, compute min-cuts
    and boundary areas, return a ConvergencePoint.
    """
    t0 = time.time()
    n_tiles = len(patch["tiles"])
    max_rc = adaptive_max_rc(n_tiles, user_max_rc)

    flow_G, bnode_ids, bnode_to_tile = layer.build_flow_graph(patch)
    internal_bonds = patch["internal_bonds"]

    # Enumerate regions using 13's infrastructure
    regions = layer.enumerate_regions(
        patch, bnode_to_tile, bnode_ids, max_rc,
    )

    max_S = 0
    max_area = 0
    n_regions = 0

    for r in regions:
        # r is a RegionInfo with .tiles (frozenset), .min_cut
        area = compute_boundary_area(r.tiles, internal_bonds, 5)

        if r.min_cut > max_S:
            max_S = r.min_cut
        if area > max_area:
            max_area = area
        n_regions += 1

    eta = max_S / max_area if max_area > 0 else 0.0
    elapsed = time.time() - t0

    return ConvergencePoint(
        tiling="{5,4}",
        strategy="BFS-depth",
        label=label,
        n_cells=n_tiles,
        n_regions=n_regions,
        max_S=max_S,
        max_area=max_area,
        eta=eta,
        elapsed=elapsed,
    )


# ════════════════════════════════════════════════════════════════════
#  6.  Sweep Drivers
# ════════════════════════════════════════════════════════════════════

def sweep_435_dense(
    geom: dict,
    target_sizes: list[int],
    user_max_rc: int | None,
) -> list[ConvergencePoint]:
    """Run the Dense strategy sweep on {4,3,5} for each target size."""
    results = []
    for max_c in target_sizes:
        label = f"Dense-{max_c}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch_dense(
            geom["face_crossings"], geom["cell_center"],
            max_c, name=label,
        )
        pt = analyze_435_patch(patch, label, "Dense", user_max_rc)
        results.append(pt)
        print(f"  {pt.n_cells} cells, {pt.n_regions} regions, "
              f"η={pt.eta:.4f}  ({pt.elapsed:.1f}s)")
    return results


def sweep_435_bfs(
    geom: dict,
    target_sizes: list[int],
    user_max_rc: int | None,
) -> list[ConvergencePoint]:
    """Run the BFS-shell strategy sweep on {4,3,5}."""
    results = []
    for max_c in target_sizes:
        label = f"BFS-{max_c}"
        print(f"    {label} ...", end="", flush=True)
        patch = multi.build_patch(
            geom["face_crossings"], geom["cell_center"],
            max_c, name=label,
        )
        pt = analyze_435_patch(patch, label, "BFS-shell", user_max_rc)
        results.append(pt)
        print(f"  {pt.n_cells} cells, {pt.n_regions} regions, "
              f"η={pt.eta:.4f}  ({pt.elapsed:.1f}s)")
    return results


def sweep_54_bfs(
    geom: dict,
    depths: list[int],
    user_max_rc: int | None,
) -> list[ConvergencePoint]:
    """Run the BFS-depth sweep on {5,4} for each depth."""
    results = []
    for depth in depths:
        label = f"d={depth}"
        print(f"    depth {depth} ...", end="", flush=True)
        patch = layer.build_layer_patch(
            geom["edge_crossings"], geom["tile_center"],
            depth, name=f"{{5,4}} depth {depth}",
        )
        pt = analyze_54_patch(patch, label, user_max_rc)
        results.append(pt)
        print(f"  {pt.n_cells} tiles, {pt.n_regions} regions, "
              f"η={pt.eta:.4f}  ({pt.elapsed:.1f}s)")
    return results


# ════════════════════════════════════════════════════════════════════
#  7.  Output Formatting
# ════════════════════════════════════════════════════════════════════

def print_convergence_table(
    title: str,
    points: list[ConvergencePoint],
) -> None:
    """Print a formatted convergence sub-table."""
    print(f"\n  {title}:")
    if not points:
        print("    (no data)")
        return
    for pt in points:
        print(f"    {pt.label:>12s} ({pt.n_cells:>5d} cells) : "
              f"max S = {pt.max_S:>2d}, "
              f"max area = {pt.max_area:>3d}, "
              f"η = {pt.eta:.4f}  "
              f"({pt.n_regions} regions, {pt.elapsed:.1f}s)")


def print_strategy_comparison(
    dense_pts: list[ConvergencePoint],
    bfs_pts: list[ConvergencePoint],
) -> None:
    """Compare Dense vs BFS strategies at comparable cell counts."""
    print("\n  STRATEGY COMPARISON at comparable N:")
    dense_by_n = {pt.n_cells: pt for pt in dense_pts}
    bfs_by_n = {pt.n_cells: pt for pt in bfs_pts}

    matched = False
    for dn, dpt in sorted(dense_by_n.items()):
        # Find closest BFS point
        best_bn = min(bfs_by_n.keys(),
                      key=lambda x: abs(x - dn),
                      default=None)
        if best_bn is not None and abs(best_bn - dn) < dn * 0.5:
            bpt = bfs_by_n[best_bn]
            print(f"    N ≈ {dn:>5d}:  "
                  f"Dense η = {dpt.eta:.4f} (S={dpt.max_S}),  "
                  f"BFS η = {bpt.eta:.4f} (S={bpt.max_S})")
            matched = True
    if not matched:
        print("    (no comparable cell counts)")


def print_tiling_comparison(
    dense_435: list[ConvergencePoint],
    bfs_54: list[ConvergencePoint],
) -> None:
    """Compare {4,3,5} Dense vs {5,4} BFS at comparable cell counts."""
    print("\n  TILING COMPARISON ({4,3,5} Dense vs {5,4} BFS):")
    for dpt in dense_435:
        # Find closest {5,4} point by cell count
        best = min(bfs_54,
                   key=lambda x: abs(x.n_cells - dpt.n_cells),
                   default=None)
        if best is not None:
            print(f"    {'{4,3,5}'} {dpt.label:>12s} "
                  f"({dpt.n_cells:>5d} cells) η = {dpt.eta:.4f}    vs    "
                  f"{'{5,4}'} {best.label:>8s} "
                  f"({best.n_cells:>5d} tiles) η = {best.eta:.4f}")


def assess_convergence(
    series_name: str,
    points: list[ConvergencePoint],
) -> None:
    """Assess whether a series of η values appears to converge."""
    if len(points) < 2:
        print(f"    {series_name}: insufficient data ({len(points)} points)")
        return

    etas = [pt.eta for pt in points]
    diffs = [etas[i + 1] - etas[i] for i in range(len(etas) - 1)]

    monotone_inc = all(d >= -1e-10 for d in diffs)
    monotone_dec = all(d <= 1e-10 for d in diffs)

    # Check if differences are shrinking (approaching a limit)
    if len(diffs) >= 2:
        abs_diffs = [abs(d) for d in diffs]
        diffs_shrinking = all(
            abs_diffs[i + 1] <= abs_diffs[i] + 1e-10
            for i in range(len(abs_diffs) - 1)
        )
    else:
        diffs_shrinking = True

    last_eta = etas[-1]
    last_diff = diffs[-1] if diffs else 0

    trend = "flat"
    if monotone_inc and not all(abs(d) < 1e-10 for d in diffs):
        trend = "monotone increasing"
    elif monotone_dec and not all(abs(d) < 1e-10 for d in diffs):
        trend = "monotone decreasing"

    if abs(last_diff) < 0.01 and len(points) >= 3:
        converge_str = "appears to converge"
        est = f"{last_eta:.4f}"
    elif diffs_shrinking and len(points) >= 3:
        converge_str = "possibly converging (differences shrinking)"
        est = f"~{last_eta + last_diff:.4f} (linear extrapolation)"
    else:
        converge_str = "inconclusive"
        est = "insufficient data"

    print(f"    {series_name}:")
    print(f"      η sequence: "
          + ", ".join(f"{e:.4f}" for e in etas))
    print(f"      Δη sequence: "
          + ", ".join(f"{d:+.4f}" for d in diffs))
    print(f"      Trend: {trend}")
    print(f"      {converge_str}")
    print(f"      Estimated limit: {est}")


# ════════════════════════════════════════════════════════════════════
#  8.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Track η_N = max S_N / max area_N across "
                    "resolutions, strategies, and tilings.  "
                    "Milestone I of §15.9.7.")
    parser.add_argument(
        "--max-cells", type=int, default=2000,
        help="Maximum cell/tile count for patches (default: 2000)")
    parser.add_argument(
        "--max-region-cells", type=int, default=None,
        help="Override max region cells (default: adaptive by patch size)")
    parser.add_argument(
        "--max-depth-54", type=int, default=7,
        help="Maximum BFS depth for {5,4} tiling (default: 7)")
    args = parser.parse_args()

    max_cells = args.max_cells
    user_max_rc = args.max_region_cells
    max_depth = args.max_depth_54

    print("╔═══════════════════════════════════════════════════════════╗")
    print("║  Milestone I:  Entropic Convergence — η_N Tracking       ║")
    print("║  §15.9.7 of docs/10-frontier.md                         ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"\n  Parameters:")
    print(f"    max-cells:        {max_cells}")
    print(f"    max-region-cells: "
          f"{'adaptive' if user_max_rc is None else user_max_rc}")
    print(f"    max-depth-54:     {max_depth}")

    # ── Initialize {4,3,5} Coxeter geometry ─────────────────────────
    print("\n  Initializing {4,3,5} Coxeter geometry ...")
    geom_435 = init_435_geometry()
    print("  ✓  {4,3,5} ready.")

    # ── Initialize {5,4} Coxeter geometry ───────────────────────────
    print("  Initializing {5,4} Coxeter geometry ...")
    geom_54 = init_54_geometry()
    print("  ✓  {5,4} ready.")

    # ── Target sizes ────────────────────────────────────────────────
    dense_targets = [n for n in [50, 100, 200, 500, 1000, 2000]
                     if n <= max_cells]
    bfs_targets = [n for n in [7, 15, 25, 35, 50, 75, 100, 150, 200]
                   if n <= max_cells]
    depths_54 = list(range(2, max_depth + 1))

    # ── {4,3,5} Dense sweep ─────────────────────────────────────────
    print(f"\n  ═══  {'{4,3,5}'} Dense Strategy  ═══")
    dense_435 = sweep_435_dense(geom_435, dense_targets, user_max_rc)

    # ── {4,3,5} BFS-shell sweep ─────────────────────────────────────
    print(f"\n  ═══  {'{4,3,5}'} BFS-Shell Strategy  ═══")
    bfs_435 = sweep_435_bfs(geom_435, bfs_targets, user_max_rc)

    # ── {5,4} BFS depth sweep ───────────────────────────────────────
    print(f"\n  ═══  {'{5,4}'} BFS (depth) Strategy  ═══")
    bfs_54 = sweep_54_bfs(geom_54, depths_54, user_max_rc)

    # ── Output convergence table ────────────────────────────────────
    all_results = dense_435 + bfs_435 + bfs_54

    print(f"\n{'═' * 72}")
    print(f"  CONVERGENCE TABLE:  η_N = max S_N / max area_N")
    print(f"{'═' * 72}")

    print_convergence_table("{4,3,5} Dense", dense_435)
    print_convergence_table("{4,3,5} BFS-shell", bfs_435)
    print_convergence_table("{5,4} BFS (depth)", bfs_54)

    # ── Strategy comparison ─────────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  STRATEGY & TILING COMPARISONS")
    print(f"{'═' * 72}")

    print_strategy_comparison(dense_435, bfs_435)
    print_tiling_comparison(dense_435, bfs_54)

    # ── Convergence assessment ──────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  CONVERGENCE ASSESSMENT")
    print(f"{'═' * 72}")
    print()

    assess_convergence("{4,3,5} Dense η", dense_435)
    print()
    assess_convergence("{4,3,5} BFS-shell η", bfs_435)
    print()
    assess_convergence("{5,4} BFS-depth η", bfs_54)

    # ── Key observations ────────────────────────────────────────────
    print(f"\n{'═' * 72}")
    print(f"  KEY OBSERVATIONS")
    print(f"{'═' * 72}")

    if dense_435:
        d_etas = [pt.eta for pt in dense_435]
        print(f"\n  1. Dense η range:     {min(d_etas):.4f} – "
              f"{max(d_etas):.4f}")
        if len(d_etas) >= 2:
            print(f"     Growth per step:   "
                  + ", ".join(f"{d_etas[i+1]-d_etas[i]:+.4f}"
                              for i in range(len(d_etas)-1)))

    if bfs_435:
        b_etas = [pt.eta for pt in bfs_435]
        print(f"\n  2. BFS-shell η range: {min(b_etas):.4f} – "
              f"{max(b_etas):.4f}")

    if bfs_54:
        l_etas = [pt.eta for pt in bfs_54]
        print(f"\n  3. {{5,4}} BFS η range: {min(l_etas):.4f} – "
              f"{max(l_etas):.4f}")

    if dense_435 and bfs_435:
        d_max = max(pt.eta for pt in dense_435)
        b_max = max(pt.eta for pt in bfs_435)
        print(f"\n  4. Strategy gap:  Dense η_max = {d_max:.4f}, "
              f"BFS η_max = {b_max:.4f}")
        if d_max > b_max * 1.1:
            print(f"     Dense growth produces deeper holographic "
                  f"surfaces (higher η).")
            print(f"     BFS shells have thin boundaries (max S ≈ 1–2).")
        else:
            print(f"     Strategies produce comparable η values.")

    print(f"""
  ── Interpretation ──

  η_N = max S_N / max area_N  measures the "holographic efficiency"
  of the discrete patch: how much entanglement entropy (S) the
  deepest boundary region accumulates per unit of boundary area.

  If η_N converges as N → ∞, the limiting value η_∞ is a candidate
  for the discrete analogue of 1/(4G_N) in the Bekenstein–Hawking
  formula  S = A / (4G_N).

  The Dense strategy is the correct one for this analysis: it
  produces multiply-connected bulk geometry with genuine multi-face
  separating surfaces, analogous to the RT minimal surfaces in
  AdS/CFT.  BFS-shell patches have thin, non-entangled boundaries
  and serve only as a baseline.

  Reference: docs/10-frontier.md §15.9.4 (Entropic Convergence Route)
""")

    # ── Summary statistics ──────────────────────────────────────────
    total_time = sum(pt.elapsed for pt in all_results)
    total_regions = sum(pt.n_regions for pt in all_results)
    print(f"  Total computation: {len(all_results)} patches, "
          f"{total_regions} regions, {total_time:.1f}s")
    print()


if __name__ == "__main__":
    main()