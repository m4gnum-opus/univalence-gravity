#!/usr/bin/env python3
"""
07b_honeycomb_3d_multiStrategy_reviewed.py

Reviewed version of 07_honeycomb_3d_multiStrategy.py addressing:

  1. GEODESIC — All patches failed "≥1 full-valence edge in patch".
     The 1-shell fattening around a geodesic spine doesn't fill the
     dihedral orbits (order 10, valence 5) around the central cube's
     edges.  FIX: after spine + fatten, run an explicit edge-completion
     phase that adds the specific dihedral-orbit cells needed to reach
     full valence around the central cube.  Then fill remaining budget
     with BFS.

  2. HEMISPHERE — All patches saturated at ≤20 cells (60 bdy faces),
     never reaching the 100-face analysis window.  Restricting BFS to
     3 of 6 face-crossing generators produces a *finite* subgroup
     orbit in hyperbolic 3-space.  FIX: grow BFS with ALL 6 face
     crossings but filter candidates through a half-space criterion:
     accept a cell only if its center satisfies  v^T G d ≥ 0  where
     d is a displacement vector pointing along the first face crossing.
     This carves out a genuine half-space of the hyperbolic honeycomb,
     which is infinite.

  3. SAMPLING — Min-cut analysis sampled only the first 20 regions,
     missing the full range for large patches (Dense-130 showed 2–4
     instead of its true range).  Subadditivity spot checks often
     found no valid non-overlapping pairs.  FIX: stratified sampling
     across region sizes + singleton-based subadditivity pairs.

Dependencies: numpy, networkx
  Install:  pip install numpy networkx

Reference:
  07_honeycomb_3d_multiStrategy.py          (original)
  07_honeycomb_3d_multiStrategy_OUTPUT.txt  (issue evidence)
  docs/instances/honeycomb-3d.md            (honeycomb instance docs)
"""

from __future__ import annotations

import sys
import os
import math
import random
from collections import defaultdict, Counter, deque
from itertools import combinations

try:
    import numpy as np
except ImportError:
    sys.exit("ERROR: numpy required.  pip install numpy")
try:
    import networkx as nx
except ImportError:
    sys.exit("ERROR: networkx required.  pip install networkx")

# ════════════════════════════════════════════════════════════════════
#  Import core infrastructure from the original 07 script
# ════════════════════════════════════════════════════════════════════

from importlib.util import spec_from_file_location, module_from_spec

_here = os.path.dirname(os.path.abspath(__file__))
_s07 = spec_from_file_location(
    "_hc07",
    os.path.join(_here, "07_honeycomb_3d_multiStrategy.py"),
)
_m07 = module_from_spec(_s07)
_s07.loader.exec_module(_m07)

# ── Re-export unchanged functions ──────────────────────────────────
build_gram_matrix       = _m07.build_gram_matrix
build_reflections       = _m07.build_reflections
validate_reflections    = _m07.validate_reflections
find_cell_center        = _m07.find_cell_center
enumerate_group         = _m07.enumerate_group
find_face_crossings     = _m07.find_face_crossings
classify_face_pairs     = _m07.classify_face_pairs
compute_edge_valence    = _m07.compute_edge_valence
build_patch             = _m07.build_patch              # BFS — unchanged
build_patch_dense       = _m07.build_patch_dense         # Dense — unchanged
build_flow_graph        = _m07.build_flow_graph
compute_min_cut         = _m07.compute_min_cut
enumerate_cell_aligned_regions = _m07.enumerate_cell_aligned_regions
compute_boundary_symmetry      = _m07.compute_boundary_symmetry
analyze_curvature       = _m07.analyze_curvature
_finalize_patch         = _m07._finalize_patch
_vec_key                = _m07._vec_key
_mat_key                = _m07._mat_key
ROUND_DIGITS            = _m07.ROUND_DIGITS
INF_CAP                 = _m07.INF_CAP


# ════════════════════════════════════════════════════════════════════
#  FIX 1:  Improved Geodesic Builder (edge-completion phase)
# ════════════════════════════════════════════════════════════════════
#
#  Original problem:  The 1-shell fattening around a geodesic spine
#  produces a thin tube.  The 12 edges of the central cube each
#  require 5 dihedral-orbit cells to be fully surrounded.  A tube
#  only covers 3–4 of those orbits per edge, so 0 edges reach full
#  valence and the gate fails.
#
#  Fix:  After spine + fattening, explicitly enumerate the dihedral
#  orbit at each of the 12 edges of the central cube and add any
#  missing orbit cells.  This guarantees that the central cube's
#  edges achieve full valence (provided the cell budget allows it).
#  Then fill remaining budget with BFS from the current frontier.
# ════════════════════════════════════════════════════════════════════

def build_patch_geodesic_v2(
    face_crossings: list[np.ndarray],
    cell_center: np.ndarray,
    max_cells: int,
    name: str = "geodesic_v2",
    opposite_pairs: list[tuple[int, int]] | None = None,
    adjacent_pairs: list[tuple[int, int]] | None = None,
) -> dict:
    """
    Geodesic tube builder with edge-completion phase.

    Phase 1: Build a spine by alternating opposite face crossings.
    Phase 2: Fatten by one shell (all face-neighbors of spine cells).
    Phase 3: Edge completion — for each of the central cube's 12 edges,
             enumerate the dihedral orbit and add missing cells.
    Phase 4: Fill remaining budget with greedy max-adjacency growth.
    """
    p = cell_center
    cells: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}

    def register(mat: np.ndarray) -> tuple[int, bool]:
        c = mat @ p
        k = _vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        if len(cells) >= max_cells:
            return -1, False
        cid = len(cells)
        cells[cid] = mat
        center_to_id[k] = cid
        return cid, True

    # ── Phase 1: Spine ──────────────────────────────────────────
    if opposite_pairs and len(opposite_pairs) > 0:
        ia, ib = opposite_pairs[0]
    else:
        ia, ib = 0, 3
    F_a = face_crossings[ia]
    F_b = face_crossings[ib]

    register(np.eye(4))
    spine_mats: list[np.ndarray] = [np.eye(4)]
    spine_budget = max(3, int(max_cells * 0.20))
    current = np.eye(4)
    toggle = True
    for _ in range(spine_budget * 2):
        F = F_a if toggle else F_b
        current = current @ F
        cid, is_new = register(current)
        if is_new and cid >= 0:
            spine_mats.append(current.copy())
        toggle = not toggle
        if len(cells) >= spine_budget:
            break

    # ── Phase 2: Fatten by 1 shell ─────────────────────────────
    fatten_budget = max(len(cells) + 6, int(max_cells * 0.50))
    for mat in list(spine_mats):
        if len(cells) >= fatten_budget:
            break
        for F in face_crossings:
            if len(cells) >= fatten_budget:
                break
            register(mat @ F)

    # ── Phase 3: Edge completion ────────────────────────────────
    #  For each adjacent face pair (edge of the central cube),
    #  enumerate the dihedral group <F_i, F_j> and add missing
    #  orbit cells.  The dihedral group has order 10; the orbit
    #  of the cell center p has exactly 5 distinct points (the
    #  5 cells meeting at this edge in the {4,3,5} honeycomb).
    edge_budget = max(len(cells) + 12, int(max_cells * 0.85))
    if adjacent_pairs:
        for fi, fj in adjacent_pairs:
            if len(cells) >= edge_budget:
                break
            F_i, F_j = face_crossings[fi], face_crossings[fj]
            dih_elems = enumerate_group([F_i, F_j])
            for g in dih_elems:
                if len(cells) >= edge_budget:
                    break
                register(g)

    # ── Phase 4: Fill remaining budget (greedy) ─────────────────
    while len(cells) < max_cells:
        frontier: dict[tuple, np.ndarray] = {}
        for cid in list(cells.keys()):
            g = cells[cid]
            for F in face_crossings:
                h = g @ F
                ck = _vec_key(h @ p)
                if ck not in center_to_id and ck not in frontier:
                    frontier[ck] = h
        if not frontier:
            break
        # Greedy: pick frontier cell with most patch neighbors
        def adj_count(mat):
            count = 0
            for F in face_crossings:
                if _vec_key((mat @ F) @ p) in center_to_id:
                    count += 1
            return count
        best_key = max(frontier, key=lambda k: adj_count(frontier[k]))
        cid, is_new = register(frontier[best_key])
        if not is_new:
            break

    return _finalize_patch(cells, center_to_id, face_crossings,
                           cell_center, name)


# ════════════════════════════════════════════════════════════════════
#  FIX 2:  Improved Hemisphere Builder (half-space filter)
# ════════════════════════════════════════════════════════════════════
#
#  Original problem:  Using only 3 of 6 face crossings as BFS
#  generators produces a *finite* subgroup orbit (~20 cells) in the
#  {4,3,5} hyperbolic honeycomb.  The 3 chosen generators commute
#  in a way that closes the group before reaching 100 boundary faces.
#
#  Fix:  Use ALL 6 face crossings for BFS growth, but accept a cell
#  only if its center lies in a half-space of the Minkowski form:
#
#     v^T G d ≥ -ε
#
#  where d = F_0 @ p - p is a displacement vector along one face
#  crossing, and G is the Gram matrix.  This defines a genuine
#  half-space in the Lorentzian geometry, which intersects infinitely
#  many cells.  The result is an asymmetric patch with a roughly
#  planar cut on one side.
# ════════════════════════════════════════════════════════════════════

def build_patch_hemisphere_v2(
    face_crossings: list[np.ndarray],
    cell_center: np.ndarray,
    G: np.ndarray,
    max_cells: int,
    name: str = "hemisphere_v2",
) -> dict:
    """
    Hemisphere builder using Gram-form half-space filter.

    Grows BFS with all 6 face crossings but only accepts cells
    whose center satisfies  c^T G d ≥ -ε , where:
      c = cell center in root basis
      d = F_0 @ p - p  (displacement along first face crossing)
      G = Gram matrix of the [4,3,5] Coxeter group
    """
    p = cell_center

    # Choose half-space normal: displacement from origin cell to
    # first face-neighbor.  This gives a "forward" direction.
    d = face_crossings[0] @ p - p
    # Also try the raw neighbor center as direction if d is degenerate
    d_norm = d @ G @ d
    if abs(d_norm) < 1e-10:
        d = face_crossings[0] @ p

    cells: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}

    def register(mat: np.ndarray) -> tuple[int, bool]:
        c = mat @ p
        # Half-space filter
        ip = c @ G @ d
        if ip < -1e-6:
            return -1, False
        k = _vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        if len(cells) >= max_cells:
            return -1, False
        cid = len(cells)
        cells[cid] = mat
        center_to_id[k] = cid
        return cid, True

    register(np.eye(4))
    queue: deque[int] = deque([0])

    while queue:
        cid = queue.popleft()
        if cid not in cells:
            continue
        g = cells[cid]
        for F in face_crossings:          # ALL 6 directions
            h = g @ F
            nid, is_new = register(h)
            if is_new and nid >= 0:
                queue.append(nid)

    return _finalize_patch(cells, center_to_id, face_crossings,
                           cell_center, name)


# ════════════════════════════════════════════════════════════════════
#  FIX 3:  Improved Analysis with Stratified Sampling
# ════════════════════════════════════════════════════════════════════

def stratified_sample(regions, n_total=30):
    """
    Sample regions stratified by size to capture the full min-cut range.
    Returns indices into the regions list.
    """
    if len(regions) <= n_total:
        return list(range(len(regions)))

    # Group by region face-count (proxy for size)
    by_size: dict[int, list[int]] = defaultdict(list)
    for i, (label, idx_set) in enumerate(regions):
        by_size[len(idx_set)].append(i)

    sizes = sorted(by_size.keys())
    per_bucket = max(1, n_total // max(len(sizes), 1))
    sample_idxs: list[int] = []

    for s in sizes:
        candidates = by_size[s]
        if len(candidates) <= per_bucket:
            sample_idxs.extend(candidates)
        else:
            sample_idxs.extend(random.sample(candidates, per_bucket))

    # Fill remaining budget from the full list
    remaining = set(range(len(regions))) - set(sample_idxs)
    if remaining and len(sample_idxs) < n_total:
        extra = min(n_total - len(sample_idxs), len(remaining))
        sample_idxs.extend(random.sample(list(remaining), extra))

    return sample_idxs[:n_total]


def find_nonoverlapping_pairs(regions, max_pairs=50):
    """
    Find non-overlapping region pairs for subadditivity checks.
    Prioritizes small (singleton) regions that are unlikely to overlap.
    """
    # Sort by size (smallest first)
    indexed = [(i, label, idx_set) for i, (label, idx_set) in enumerate(regions)]
    indexed.sort(key=lambda x: len(x[2]))

    pairs: list[tuple[int, int]] = []
    # Try all pairs of the smallest regions first
    small = indexed[:min(20, len(indexed))]
    for a in range(len(small)):
        for b in range(a + 1, len(small)):
            ia, _, setA = small[a]
            ib, _, setB = small[b]
            if not (setA & setB):
                unionAB = setA | setB
                # Union must be a proper subset of all boundary nodes
                if len(unionAB) < max(len(setA), len(setB)) * 3 + 5:
                    pairs.append((ia, ib))
                    if len(pairs) >= max_pairs:
                        return pairs
    return pairs


# ════════════════════════════════════════════════════════════════════
#  Improved analyze_patch
# ════════════════════════════════════════════════════════════════════

def analyze_patch(
    patch: dict,
    face_crossings: list[np.ndarray],
    adjacent_pairs: list[tuple[int, int]],
    cell_center: np.ndarray,
) -> dict:
    """Run full analysis with improved sampling."""

    n_cells = len(patch["cells"])
    n_internal = len(patch["internal_faces"])
    n_boundary = patch["n_boundary_faces"]
    density = 2 * n_internal / max(n_cells, 1)

    print(f"\n{'=' * 72}")
    print(f"  PATCH:  {patch['name']}")
    print(f"{'=' * 72}")
    print(f"  Cells (cubes):         {n_cells}")
    print(f"  Internal shared faces: {n_internal}")
    print(f"  Boundary faces:        {n_boundary}")
    print(f"  Density (2·IntF/C):    {density:.2f}")

    # ── Edge valence ────────────────────────────────────────────
    print(f"\n  ── Edge Valence (central cube's 12 edges) ──")
    p = cell_center
    edge_valences: dict[tuple[int, int], int] = {}
    n_full = 0
    for i, j in adjacent_pairs:
        v = compute_edge_valence(face_crossings[i], face_crossings[j], p)
        edge_valences[(i, j)] = v
        if v == 5:
            n_full += 1
    analyze_curvature(edge_valences)
    if n_full > 0:
        print(f"\n  ✓  {n_full} of 12 edges achieve full valence 5!")
    else:
        print(f"\n  ✗  No edge at full valence 5.")

    # ── In-patch valence ────────────────────────────────────────
    print(f"\n  ── Edge Valence in Patch (cells actually present) ──")
    patch_centers = {_vec_key(mat @ p) for mat in patch["cells"].values()}
    n_full_in_patch = 0
    patch_val_dist = Counter()
    for (fi, fj) in adjacent_pairs:
        F_a, F_b = face_crossings[fi], face_crossings[fj]
        dih_elems = enumerate_group([F_a, F_b])
        orbit_centers = {_vec_key(g @ p) for g in dih_elems}
        in_patch = len(orbit_centers & patch_centers)
        patch_val_dist[in_patch] += 1
        if in_patch >= 5:
            n_full_in_patch += 1

    for v in sorted(patch_val_dist):
        tag = " ← FULL" if v >= 5 else ""
        print(f"    {patch_val_dist[v]} edge(s) with {v} of 5 cubes present{tag}")

    # ── Flow graph ──────────────────────────────────────────────
    flow_G, bnode_ids, bnode_to_cell = build_flow_graph(patch)
    print(f"\n  ── Flow Graph ──")
    print(f"  Boundary legs: {len(bnode_ids)}")

    # ── Regions ─────────────────────────────────────────────────
    max_rc = min(5, n_cells - 1)
    regions = enumerate_cell_aligned_regions(
        patch, bnode_to_cell, bnode_ids, max_region_cells=max_rc
    )
    n_regions = len(regions)
    print(f"\n  ── Cell-Aligned Boundary Regions (up to {max_rc} cells) ──")
    print(f"  Distinct regions: {n_regions}")

    # ── FIX 3: Stratified min-cut sampling ──────────────────────
    sample_idxs = stratified_sample(regions, n_total=30)
    cut_values_all: list[int] = []

    if sample_idxs:
        print(f"\n  {'Region':<42s} | {'#faces':>6s} | {'S(A)':>5s}")
        print(f"  {'─' * 58}")
        displayed = 0
        for idx in sample_idxs:
            label, idx_set = regions[idx]
            s = compute_min_cut(flow_G, bnode_ids, idx_set)
            if s >= 0:
                cut_values_all.append(s)
            if displayed < 20:
                print(f"  {label:<42s} | {len(idx_set):>6d} | {s:>5d}")
                displayed += 1
        if displayed < len(sample_idxs):
            print(f"  ... ({len(sample_idxs) - displayed} more sampled)")

    # Compute all min-cuts if region count is manageable
    if n_regions <= 1000:
        all_cuts = []
        for label, idx_set in regions:
            s = compute_min_cut(flow_G, bnode_ids, idx_set)
            if s >= 0:
                all_cuts.append(s)
        if all_cuts:
            cut_values_all = all_cuts  # use full set

    min_cut_lo = min(cut_values_all) if cut_values_all else 0
    min_cut_hi = max(cut_values_all) if cut_values_all else 0
    scope = "all" if n_regions <= 1000 else "sample"
    print(f"\n  Min-cut range ({scope}): {min_cut_lo} – {min_cut_hi}")

    if cut_values_all:
        dist = Counter(cut_values_all)
        print(f"  Min-cut distribution:")
        for v in sorted(dist):
            print(f"    S = {v}: {dist[v]} regions")

    # ── FIX 3: Improved subadditivity ───────────────────────────
    print(f"\n  ── Subadditivity Spot Check ──")
    pairs = find_nonoverlapping_pairs(regions, max_pairs=50)
    sub_checks, sub_pass, sub_fail = 0, 0, 0
    for ia, ib in pairs:
        _, idxA = regions[ia]
        _, idxB = regions[ib]
        idxAB = idxA | idxB
        if len(idxAB) >= len(bnode_ids):
            continue
        sA = compute_min_cut(flow_G, bnode_ids, idxA)
        sB = compute_min_cut(flow_G, bnode_ids, idxB)
        sAB = compute_min_cut(flow_G, bnode_ids, idxAB)
        if sA < 0 or sB < 0 or sAB < 0:
            continue
        sub_checks += 1
        if sAB <= sA + sB:
            sub_pass += 1
        else:
            sub_fail += 1
    if sub_checks > 0:
        print(f"  Checked {sub_checks} pairs: "
              f"{sub_pass} passed, {sub_fail} failed.")
    else:
        print(f"  (No valid non-overlapping pairs found)")

    # ── Symmetry ────────────────────────────────────────────────
    print(f"\n  ── Symmetry Analysis ──")
    group_order, num_orbits = compute_boundary_symmetry(
        patch, bnode_to_cell, bnode_ids
    )
    if group_order > 0:
        print(f"  Automorphism group order: {group_order}")
        print(f"  Boundary face orbits:     {num_orbits}")
        est_region_orbits = max(1, n_regions // max(1, group_order))
    else:
        print(f"  [Full automorphism skipped for large boundary]")
        print(f"  Degree-class estimate: {num_orbits} classes")
        est_region_orbits = max(1, n_regions // 48)
        print(f"  With octahedral sym (48): ~{est_region_orbits} orbit est.")

    # ── Curvature summary ───────────────────────────────────────
    print(f"\n  ── 3D Curvature Summary ──")
    print(f"  Dihedral angle of cube: π/2 = 90°")
    print(f"  {{4,3,5}} honeycomb: 5 cubes at each edge")
    print(f"  Edge deficit: κ = 2π − 5·(π/2) = −π/2 ≈ −90°")
    if n_full_in_patch > 0:
        total_kappa = n_full_in_patch * (-math.pi / 2)
        print(f"  Fully surrounded edges in patch: {n_full_in_patch}")
        print(f"  Total hyperbolic curvature: "
              f"{math.degrees(total_kappa):.1f}°")
    else:
        print(f"  Fully surrounded edges in patch: 0")

    # ── Gate Check ──────────────────────────────────────────────
    print(f"\n  {'═' * 55}")
    print(f"  GATE CHECK")
    print(f"  {'═' * 55}")

    gate_pass = True
    checks = [
        ("Boundary faces 100–500",
         100 <= n_boundary <= 500, n_boundary),
        ("≥1 edge at full valence 5 (in honeycomb)",
         n_full > 0, n_full),
        ("≥1 full-valence edge in patch",
         n_full_in_patch > 0, n_full_in_patch),
        ("Orbit count ≤ 200",
         est_region_orbits <= 200, est_region_orbits),
    ]
    for desc, ok, val in checks:
        status = "✓ PASS" if ok else "✗ FAIL"
        if not ok:
            gate_pass = False
        print(f"    {status}  {desc}  (actual: {val})")

    if gate_pass:
        print(f"\n  ▶  ALL GATES PASS")
    else:
        print(f"\n  ▶  GATE(S) BLOCKED")
        if n_full_in_patch == 0:
            print(f"     → 0 full-valence edges in patch")
        if n_boundary < 100:
            print(f"     → Boundary {n_boundary} < 100")
        if n_boundary > 500:
            print(f"     → Boundary {n_boundary} > 500")

    return {
        "n_cells": n_cells,
        "n_internal_faces": n_internal,
        "n_boundary_faces": n_boundary,
        "n_regions": n_regions,
        "n_full_valence_edges_honeycomb": n_full,
        "n_full_valence_edges_in_patch": n_full_in_patch,
        "group_order": group_order,
        "est_region_orbits": est_region_orbits,
        "gate_pass": gate_pass,
        "min_cut_range": (min_cut_lo, min_cut_hi),
        "density": round(density, 2),
    }


# ════════════════════════════════════════════════════════════════════
#  Main
# ════════════════════════════════════════════════════════════════════

def main():
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║  07b: {4,3,5} Honeycomb — Reviewed Multi-Strategy Probe   ║")
    print("║  Fixes: Geodesic edge-completion, Hemisphere half-space   ║")
    print("╚═══════════════════════════════════════════════════════════╝")

    random.seed(42)  # reproducible sampling

    # ── Coxeter geometry ────────────────────────────────────────
    print("\n  Initializing Coxeter geometry for [4,3,5] ...")
    G = build_gram_matrix()
    refls = build_reflections(G)

    evals = np.linalg.eigvalsh(G)
    n_neg = sum(1 for e in evals if e < -1e-10)
    n_pos = sum(1 for e in evals if e > 1e-10)
    print(f"  Gram matrix eigenvalues: "
          f"{', '.join(f'{e:.4f}' for e in sorted(evals))}")
    print(f"  Signature: ({n_pos}, {n_neg})  "
          f"{'✓ compact hyperbolic' if n_neg == 1 and n_pos == 3 else '✗'}")

    validate_reflections(G, refls)

    cell_center = find_cell_center(G)
    norm_sq = cell_center @ G @ cell_center
    print(f"  Cell center: [{', '.join(f'{x:.4f}' for x in cell_center)}]")
    print(f"  <p,p>_G = {norm_sq:.6f}  "
          f"({'timelike ✓' if norm_sq < 0 else 'spacelike ✗'})")

    print("\n  Enumerating cell stabilizer <s0, s1, s2> ...")
    stab = enumerate_group(refls[:3], expected=48)
    print(f"  ✓  Cell stabilizer [4,3] has {len(stab)} elements.")

    face_crossings = find_face_crossings(refls, stab, G)
    print(f"  ✓  {len(face_crossings)} face crossings found.")

    adj_pairs, opp_pairs = classify_face_pairs(face_crossings)
    print(f"  Adjacent face pairs: {len(adj_pairs)}  (edges of cube)")
    print(f"  Opposite face pairs: {len(opp_pairs)}")

    # ── Strategies ──────────────────────────────────────────────
    #
    # BFS and Dense: unchanged from script 07
    # Geodesic: v2 with edge-completion phase  (FIX 1)
    # Hemisphere: v2 with half-space filter     (FIX 2)

    strategies: list[tuple[str, str, callable, dict]] = [
        ("BFS",        "unchanged",
         lambda fc, cc, mc, nm, **kw: build_patch(fc, cc, mc, nm),
         {}),
        ("Dense",      "unchanged",
         lambda fc, cc, mc, nm, **kw: build_patch_dense(fc, cc, mc, nm),
         {}),
        ("Geodesic",   "v2 (edge-completion)",
         lambda fc, cc, mc, nm, **kw: build_patch_geodesic_v2(
             fc, cc, mc, nm,
             opposite_pairs=kw.get("opposite_pairs"),
             adjacent_pairs=kw.get("adjacent_pairs")),
         {"opposite_pairs": opp_pairs, "adjacent_pairs": adj_pairs}),
        ("Hemisphere", "v2 (half-space)",
         lambda fc, cc, mc, nm, **kw: build_patch_hemisphere_v2(
             fc, cc, kw["gram"], mc, nm),
         {"gram": G}),
    ]

    target_sizes = [7, 15, 25, 35, 50, 75, 100, 130]
    all_results: list[tuple[str, dict]] = []

    for strat_label, strat_note, builder, extra_kw in strategies:
        print(f"\n{'━' * 72}")
        print(f"  ═══  Strategy: {strat_label}  ({strat_note})  ═══")
        print(f"{'━' * 72}")

        for max_c in target_sizes:
            label = f"{strat_label}-{max_c}"
            patch = builder(
                face_crossings, cell_center, max_c, label, **extra_kw
            )
            n_cells_actual = len(patch["cells"])
            n_int = len(patch["internal_faces"])
            n_bdy = patch["n_boundary_faces"]
            dens = 2 * n_int / max(n_cells_actual, 1)

            print(f"\n  {label}: {n_cells_actual} cells, "
                  f"{n_int} int.faces (density {dens:.2f}), "
                  f"{n_bdy} bdy.faces")

            if n_bdy < 100:
                print(f"    ↳ Skip (boundary {n_bdy} < 100)")
                continue
            if n_bdy > 500:
                print(f"    ↳ Skip (boundary {n_bdy} > 500)")
                continue

            result = analyze_patch(
                patch, face_crossings, adj_pairs, cell_center
            )
            all_results.append((label, result))

    # ── Cross-Strategy Comparison ───────────────────────────────
    print(f"\n{'━' * 72}")
    print(f"  CROSS-STRATEGY COMPARISON")
    print(f"{'━' * 72}")

    print(f"\n  {'Patch':<28s} | {'Cells':>5s} | {'IntF':>5s} | "
          f"{'Dens':>5s} | {'Bdy':>4s} | {'Full':>4s} | "
          f"{'MinCut':>7s} | {'Gate':>4s}")
    print(f"  {'─' * 78}")
    for label, r in all_results:
        gate = "✓" if r["gate_pass"] else "✗"
        lo, hi = r["min_cut_range"]
        mc = f"{lo}–{hi}" if lo != hi else str(lo)
        print(f"  {label:<28s} | {r['n_cells']:>5d} | "
              f"{r['n_internal_faces']:>5d} | "
              f"{r['density']:>5.2f} | "
              f"{r['n_boundary_faces']:>4d} | "
              f"{r['n_full_valence_edges_in_patch']:>4d} | "
              f"{mc:>7s} | "
              f"{gate:>4s}")

    # ── Strategy Summary ────────────────────────────────────────
    strat_results: dict[str, dict[str, list]] = defaultdict(
        lambda: {"pass": [], "fail": []}
    )
    for label, r in all_results:
        s = label.split("-")[0]
        if r["gate_pass"]:
            strat_results[s]["pass"].append((label, r))
        else:
            strat_results[s]["fail"].append((label, r))

    print(f"\n  {'━' * 60}")
    print(f"  STRATEGY SUMMARY (vs original 07 results)")
    print(f"  {'━' * 60}")

    for s in ["BFS", "Dense", "Geodesic", "Hemisphere"]:
        sr = strat_results.get(s, {"pass": [], "fail": []})
        np_ = len(sr["pass"])
        nf_ = len(sr["fail"])
        if np_ > 0 and nf_ == 0:
            print(f"\n  {s}:  ALL {np_} tested patches PASS ✓")
        elif np_ > 0:
            print(f"\n  {s}:  {np_} pass, {nf_} fail")
        elif nf_ > 0:
            print(f"\n  {s}:  ALL {nf_} tested patches FAIL ✗")
            for l, r in sr["fail"]:
                reasons = []
                if r["n_full_valence_edges_in_patch"] == 0:
                    reasons.append("0 full-val edges")
                if r["n_boundary_faces"] < 100:
                    reasons.append(f"bdy={r['n_boundary_faces']}<100")
                print(f"    {l}: {', '.join(reasons) if reasons else 'other'}")
        else:
            print(f"\n  {s}:  no patches reached analysis window")

    # ── Geodesic Improvement Check ──────────────────────────────
    geo_07_full = 0  # original: all 0
    geo_v2_pass = strat_results.get("Geodesic", {"pass": []})["pass"]
    geo_v2_fail = strat_results.get("Geodesic", {"fail": []})["fail"]
    n_geo_full = sum(
        r["n_full_valence_edges_in_patch"]
        for _, r in geo_v2_pass + geo_v2_fail
    )
    print(f"\n  ── Geodesic Fix Assessment ──")
    print(f"  Original 07: 0 full-valence edges across all Geodesic patches")
    print(f"  Reviewed 07b: {n_geo_full} total full-valence edges "
          f"({len(geo_v2_pass)} pass / {len(geo_v2_fail)} fail)")
    if geo_v2_pass:
        print(f"  ✓  Edge-completion phase WORKS — Geodesic patches now viable")
    else:
        print(f"  ✗  Edge-completion helped but patches still don't pass all gates")

    # ── Hemisphere Improvement Check ────────────────────────────
    hemi_pass = strat_results.get("Hemisphere", {"pass": []})["pass"]
    hemi_fail = strat_results.get("Hemisphere", {"fail": []})["fail"]
    hemi_all = hemi_pass + hemi_fail
    print(f"\n  ── Hemisphere Fix Assessment ──")
    print(f"  Original 07: ALL saturated at ≤20 cells / 60 bdy (never analyzed)")
    if hemi_all:
        hemi_cells = [r["n_cells"] for _, r in hemi_all]
        hemi_bdy = [r["n_boundary_faces"] for _, r in hemi_all]
        print(f"  Reviewed 07b: {len(hemi_all)} patches analyzed, "
              f"cells {min(hemi_cells)}–{max(hemi_cells)}, "
              f"bdy {min(hemi_bdy)}–{max(hemi_bdy)}")
        if hemi_pass:
            print(f"  ✓  Half-space filter WORKS — {len(hemi_pass)} patches pass gates")
        else:
            print(f"  △  Half-space filter produces larger patches but gates still fail")
    else:
        print(f"  △  No Hemisphere patches reached analysis window")

    # ── Best-in-class ───────────────────────────────────────────
    passing = [(l, r) for l, r in all_results if r["gate_pass"]]
    if passing:
        by_density = max(passing, key=lambda x: x[1]["density"])
        by_mincut  = max(passing, key=lambda x: x[1]["min_cut_range"][1])
        by_compact = min(passing, key=lambda x: x[1]["n_boundary_faces"])

        print(f"\n  ── Best-in-Class (passing patches only) ──")
        print(f"  Highest density:     {by_density[0]}  "
              f"(density {by_density[1]['density']:.2f})")
        print(f"  Highest max min-cut: {by_mincut[0]}  "
              f"(min-cut up to {by_mincut[1]['min_cut_range'][1]})")
        print(f"  Most compact:        {by_compact[0]}  "
              f"({by_compact[1]['n_boundary_faces']} bdy faces)")

        print(f"\n  ▶  RECOMMENDATION: {by_mincut[0]}")
        print(f"     Min-cut up to {by_mincut[1]['min_cut_range'][1]} confirms genuine")
        print(f"     multi-face RT surfaces in the discrete bulk.")

    print()


if __name__ == "__main__":
    main()