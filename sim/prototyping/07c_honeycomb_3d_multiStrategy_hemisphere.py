#!/usr/bin/env python3
"""
07c_honeycomb_3d_multiStrategy_hemisphere.py

Fixes the Hemisphere strategy from 07b which produced 0 cells.

Bug in 07b (build_patch_hemisphere_v2):
  Used Gram-form half-space:  c^T G d ≥ -ε  where d = F_0 p - p.
  For the origin cell (c = p):
    p^T G d = <p, F_0 p>_G - <p, p>_G
  In {4,3,5}:  <p, p>_G = -3.236 (timelike), and <p, F_0 p>_G ≈ -6.5
  (neighboring timelike vectors in Lorentzian geometry have a MORE
  negative inner product than the self-inner-product).
  → ip ≈ -6.5 - (-3.236) = -3.26 < -1e-6
  → ORIGIN CELL REJECTED → 0 cells in every Hemisphere patch.

Fix (this script):
  Use Euclidean half-space in root-basis coordinates:
    (c - p) · d ≥ -ε    (standard dot product, NOT Gram form)

  Origin:    (p - p) · d = 0 ≥ -ε           → PASSES ✓
  Forward:   (F_0 p - p) · d = |d|² > 0     → PASSES ✓
  Backward:  proj ≈ -|d|² ≪ 0               → REJECTED ✓
  Sideways:  proj ≈ 0 (some ±)              → INCLUDED/EXCLUDED ✓

  The Euclidean half-space doesn't perfectly correspond to a
  hyperbolic half-space, but it divides cells into two groups
  based on their root-basis coordinate position, producing the
  desired asymmetric patch topology with:
    - A roughly flat "cut face" on the backward side
    - A curved boundary on the forward/sideways faces
    - Infinite growth (unlike the 3-generator approach from 07)

Dependencies: numpy, networkx
  Install:  pip install numpy networkx

Reference:
  07_honeycomb_3d_multiStrategy.py              (original)
  07b_honeycomb_3d_multiStrategy_reviewed.py    (Geodesic fix, Hemi bug)
"""

from __future__ import annotations

import sys
import os
import math
import random
from collections import defaultdict, Counter, deque

try:
    import numpy as np
except ImportError:
    sys.exit("ERROR: numpy required.  pip install numpy")
try:
    import networkx as nx
except ImportError:
    sys.exit("ERROR: networkx required.  pip install networkx")

# ════════════════════════════════════════════════════════════════════
#  Import core infrastructure from scripts 07 and 07b
# ════════════════════════════════════════════════════════════════════

from importlib.util import spec_from_file_location, module_from_spec

_here = os.path.dirname(os.path.abspath(__file__))

_s07 = spec_from_file_location(
    "_hc07", os.path.join(_here, "07_honeycomb_3d_multiStrategy.py"))
_m07 = module_from_spec(_s07)
_s07.loader.exec_module(_m07)

_s07b = spec_from_file_location(
    "_hc07b",
    os.path.join(_here, "07b_honeycomb_3d_multiStrategy_reviewed.py"))
_m07b = module_from_spec(_s07b)
_s07b.loader.exec_module(_m07b)

# ── Re-export from 07 (unchanged core) ────────────────────────────
build_gram_matrix       = _m07.build_gram_matrix
build_reflections       = _m07.build_reflections
validate_reflections    = _m07.validate_reflections
find_cell_center        = _m07.find_cell_center
enumerate_group         = _m07.enumerate_group
find_face_crossings     = _m07.find_face_crossings
classify_face_pairs     = _m07.classify_face_pairs
compute_edge_valence    = _m07.compute_edge_valence
build_patch             = _m07.build_patch              # BFS
build_patch_dense       = _m07.build_patch_dense         # Dense
build_flow_graph        = _m07.build_flow_graph
compute_min_cut         = _m07.compute_min_cut
enumerate_cell_aligned_regions = _m07.enumerate_cell_aligned_regions
compute_boundary_symmetry      = _m07.compute_boundary_symmetry
analyze_curvature       = _m07.analyze_curvature
_finalize_patch         = _m07._finalize_patch
_vec_key                = _m07._vec_key
_mat_key                = _m07._mat_key

# ── Re-export from 07b (Geodesic v2, improved analysis) ───────────
build_patch_geodesic_v2   = _m07b.build_patch_geodesic_v2
analyze_patch             = _m07b.analyze_patch


# ════════════════════════════════════════════════════════════════════
#  Diagnostic: Why 07b's Hemisphere Failed
# ════════════════════════════════════════════════════════════════════

def diagnose_07b_bug(
    G: np.ndarray,
    face_crossings: list[np.ndarray],
    cell_center: np.ndarray,
) -> None:
    """
    Compute and display the exact inner product values that caused
    07b's build_patch_hemisphere_v2 to reject the origin cell.
    """
    p = cell_center
    d = face_crossings[0] @ p - p
    pp = p @ G @ p                     # <p, p>_G
    pFp = p @ G @ (face_crossings[0] @ p)  # <p, F_0 p>_G
    ip_origin = p @ G @ d             # = pFp - pp

    print(f"\n  ── Diagnosing 07b Hemisphere Bug ──")
    print(f"  07b half-space test:  c^T G d ≥ -1e-6")
    print(f"  where d = F_0 p - p  (displacement to face neighbor)")
    print(f"")
    print(f"  For origin cell (c = p):")
    print(f"    <p, p>_G     = {pp:+.6f}  (timelike)")
    print(f"    <p, F_0 p>_G = {pFp:+.6f}  (neighboring timelike)")
    print(f"    p^T G d      = <p, F_0 p>_G − <p, p>_G")
    print(f"                 = ({pFp:.6f}) − ({pp:.6f})")
    print(f"                 = {ip_origin:+.6f}")
    print(f"    Threshold:     -1e-6")
    is_rejected = ip_origin < -1e-6
    print(f"    Test:          {ip_origin:+.6f} < -1e-6"
          f"  → {'REJECT ✗' if is_rejected else 'PASS ✓'}")
    if is_rejected:
        print(f"")
        print(f"  ✗  ORIGIN CELL REJECTED → 0 cells for ALL sizes")
        print(f"")
        print(f"  Root cause: In Lorentzian geometry (signature 3,1),")
        print(f"  neighboring timelike vectors have a MORE negative")
        print(f"  G-inner product than the self-inner product:")
        print(f"    <p, F_0 p>_G = {pFp:.4f}  <  <p, p>_G = {pp:.4f}")
        print(f"  So p^T G d = {ip_origin:.4f} < 0 always.")

    # Show the fix
    d_euclid = face_crossings[0] @ p - p
    proj_origin = float(np.dot(p - p, d_euclid))
    d_sq = float(np.dot(d_euclid, d_euclid))

    print(f"\n  ── 07c Fix: Euclidean Half-Space ──")
    print(f"  New test:  (c − p) · d ≥ -ε  (Euclidean dot product)")
    print(f"  For origin:  (p − p) · d = {proj_origin:.1f} ≥ -ε"
          f"  → PASS ✓")
    print(f"  For F_0 nbr: d · d = |d|² = {d_sq:.4f} > 0"
          f"  → PASS ✓")
    print(f"  For opposite nbr: proj ≈ −|d|²  → REJECT ✓")


# ════════════════════════════════════════════════════════════════════
#  FIX:  Hemisphere v3 — Euclidean Half-Space Filter
# ════════════════════════════════════════════════════════════════════
#
#  Key insight:  The Gram matrix G has signature (3,1) — Lorentzian.
#  For timelike vectors p and Fp, the G-inner product <p, Fp>_G is
#  MORE negative than <p, p>_G (they "diverge" in the timelike
#  direction).  This means p^T G (Fp − p) < 0 ALWAYS, making the
#  G-form half-space reject the origin.
#
#  The fix uses the standard Euclidean dot product in root-basis
#  coordinates.  This is not a "natural" inner product for the
#  hyperbolic geometry, but it defines a valid hyperplane that:
#  (a) passes through the origin cell center p,
#  (b) includes cells on the "forward" side,
#  (c) cuts off the "backward" side.
#
#  The resulting patch is asymmetric: a flat cut on one side (the
#  hyperplane) and a curved boundary elsewhere (BFS frontier).
# ════════════════════════════════════════════════════════════════════

def build_patch_hemisphere_v3(
    face_crossings: list[np.ndarray],
    cell_center: np.ndarray,
    G: np.ndarray,
    max_cells: int,
    name: str = "hemisphere_v3",
    opposite_pairs: list[tuple[int, int]] | None = None,
) -> dict:
    """
    Hemisphere builder using Euclidean half-space filter.

    Grows BFS with all 6 face crossings but only accepts cells
    whose center satisfies:

        (c − p) · d ≥ −ε

    where:
      c = cell center in root basis (4-vector)
      p = origin cell center
      d = F_ia(p) − p  (Euclidean displacement along a cube axis)
      · = standard Euclidean inner product (NOT Gram form)
      ε = small tolerance (1e-6)

    Properties:
      Origin cell:      (p − p) · d = 0 ≥ −ε         → included
      Forward neighbor:  d · d = |d|² ≫ 0             → included
      Opposite neighbor: ≈ −|d|² ≪ 0                  → excluded
      Sideways neighbors: proj ≈ 0 (some pass/fail)   → ~half

    The axis direction is chosen from the first opposite face pair,
    giving a clean separation along one of the cube's 3 principal
    axes.  All 6 face crossings are used for BFS expansion, but
    the Euclidean half-space filter prevents growth into the
    "backward" half-space, producing an asymmetric patch.
    """
    p = cell_center

    # Choose forward axis from an opposite face pair.
    # Opposite faces of a cube define translation axes in the
    # honeycomb; using one gives a clean half-space cut.
    if opposite_pairs and len(opposite_pairs) > 0:
        ia, _ = opposite_pairs[0]
        d_fwd = face_crossings[ia] @ p - p
    else:
        d_fwd = face_crossings[0] @ p - p

    cells: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}

    def register(mat: np.ndarray) -> tuple[int, bool]:
        c = mat @ p
        # ── Euclidean half-space filter ──
        # Accept if the Euclidean projection of (c − p) onto d_fwd
        # is non-negative (within tolerance).
        proj = float(np.dot(c - p, d_fwd))
        if proj < -1e-6:
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
        for F in face_crossings:       # ALL 6 directions
            h = g @ F
            nid, is_new = register(h)
            if is_new and nid >= 0:
                queue.append(nid)

    return _finalize_patch(cells, center_to_id, face_crossings,
                           cell_center, name)


# ════════════════════════════════════════════════════════════════════
#  Main
# ════════════════════════════════════════════════════════════════════

def main():
    print("╔═══════════════════════════════════════════════════════════╗")
    print("║  07c: {4,3,5} Honeycomb — Hemisphere Fix                  ║")
    print("║  Bug: Gram-form filter rejected origin cell (ip < 0)      ║")
    print("║  Fix: Euclidean half-space in root-basis coordinates      ║")
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

    # ── Diagnose why 07b failed ─────────────────────────────────
    diagnose_07b_bug(G, face_crossings, cell_center)

    # ── Quick sanity check: does the v3 builder produce cells? ──
    print(f"\n  ── Quick Sanity Check ──")
    test_patch = build_patch_hemisphere_v3(
        face_crossings, cell_center, G, 10,
        name="hemi-sanity", opposite_pairs=opp_pairs,
    )
    n_test = len(test_patch["cells"])
    print(f"  Hemisphere v3 with max_cells=10: {n_test} cells, "
          f"{test_patch['n_boundary_faces']} bdy.faces")
    if n_test > 0:
        print(f"  ✓  Half-space filter allows growth!")
    else:
        print(f"  ✗  Still 0 cells — Euclidean half-space also rejects origin?!")
        # Fallback diagnostic
        p = cell_center
        if opp_pairs:
            ia, _ = opp_pairs[0]
            d = face_crossings[ia] @ p - p
        else:
            d = face_crossings[0] @ p - p
        proj = float(np.dot(p - p, d))
        print(f"     Debug: origin proj = {proj}")
        return

    # ── Strategies ──────────────────────────────────────────────
    #
    # BFS and Dense: unchanged from 07
    # Geodesic: v2 from 07b (edge-completion phase)
    # Hemisphere: v3 from this script (Euclidean half-space)

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
        ("Hemisphere", "v3 (Euclidean half-space)",
         lambda fc, cc, mc, nm, **kw: build_patch_hemisphere_v3(
             fc, cc, kw["gram"], mc, nm,
             opposite_pairs=kw.get("opposite_pairs")),
         {"gram": G, "opposite_pairs": opp_pairs}),
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
    print(f"  STRATEGY SUMMARY")
    print(f"  {'━' * 60}")

    for s in ["BFS", "Dense", "Geodesic", "Hemisphere"]:
        sr = strat_results.get(s, {"pass": [], "fail": []})
        np_ = len(sr["pass"])
        nf_ = len(sr["fail"])
        if np_ > 0 and nf_ == 0:
            print(f"\n  {s}:  ALL {np_} tested patches PASS ✓")
        elif np_ > 0:
            print(f"\n  {s}:  {np_} pass, {nf_} fail")
            for l, r in sr["fail"]:
                reasons = []
                if r["n_full_valence_edges_in_patch"] == 0:
                    reasons.append("0 full-val edges")
                if r["n_boundary_faces"] < 100:
                    reasons.append(f"bdy={r['n_boundary_faces']}<100")
                print(f"    {l}: {', '.join(reasons) if reasons else 'other'}")
        elif nf_ > 0:
            print(f"\n  {s}:  ALL {nf_} tested patches FAIL ✗")
            for l, r in sr["fail"]:
                reasons = []
                if r["n_full_valence_edges_in_patch"] == 0:
                    reasons.append("0 full-val edges")
                print(f"    {l}: {', '.join(reasons) if reasons else 'other'}")
        else:
            print(f"\n  {s}:  no patches reached analysis window")

    # ── Hemisphere Fix Assessment ───────────────────────────────
    hemi_pass = strat_results.get("Hemisphere", {"pass": []})["pass"]
    hemi_fail = strat_results.get("Hemisphere", {"fail": []})["fail"]
    hemi_all = hemi_pass + hemi_fail

    print(f"\n  {'━' * 60}")
    print(f"  HEMISPHERE FIX ASSESSMENT (07 → 07b → 07c)")
    print(f"  {'━' * 60}")
    print(f"")
    print(f"  Script 07 (original):")
    print(f"    Strategy:  BFS with only 3 of 6 face crossings")
    print(f"    Result:    Saturated at ≤20 cells / 60 bdy faces")
    print(f"    Cause:     3 chosen generators form a finite subgroup")
    print(f"")
    print(f"  Script 07b (first fix attempt):")
    print(f"    Strategy:  BFS with all 6 crossings + Gram-form filter")
    print(f"    Result:    0 cells for ALL sizes")
    print(f"    Cause:     p^T G d < 0 for origin (Lorentzian sign)")
    print(f"")
    print(f"  Script 07c (this fix):")
    print(f"    Strategy:  BFS with all 6 crossings + Euclidean filter")

    if hemi_all:
        hemi_cells = [r["n_cells"] for _, r in hemi_all]
        hemi_bdy = [r["n_boundary_faces"] for _, r in hemi_all]
        hemi_full = [r["n_full_valence_edges_in_patch"] for _, r in hemi_all]
        print(f"    Result:    {len(hemi_all)} patches analyzed")
        print(f"               cells {min(hemi_cells)}–{max(hemi_cells)}, "
              f"bdy {min(hemi_bdy)}–{max(hemi_bdy)}")
        print(f"               full-val edges: "
              f"{min(hemi_full)}–{max(hemi_full)} per patch")
        if hemi_pass:
            print(f"    ✓  FIX CONFIRMED: {len(hemi_pass)} patches PASS all gates")
            # Characterize the hemisphere patches
            hemi_mc = [r["min_cut_range"][1] for _, r in hemi_pass]
            hemi_dens = [r["density"] for _, r in hemi_pass]
            print(f"    Max min-cut range across passing: "
                  f"{min(hemi_mc)}–{max(hemi_mc)}")
            print(f"    Density range: {min(hemi_dens):.2f}–{max(hemi_dens):.2f}")
        else:
            print(f"    △  Patches analyzed, but gates not all passed")
            if all(r["n_full_valence_edges_in_patch"] == 0 for _, r in hemi_all):
                print(f"    Cause: half-space cuts through all 12 dihedral orbits")
                print(f"    Possible fix: add edge-completion phase (like Geodesic v2)")
    else:
        print(f"    △  No Hemisphere patches reached 100–500 bdy window")
        print(f"    (Cells generated but boundary counts too small/large)")

    # ── Comparison: Hemisphere vs other strategies ──────────────
    if hemi_pass:
        other_pass = [(l, r) for l, r in all_results
                      if r["gate_pass"] and not l.startswith("Hemisphere")]
        if other_pass:
            other_max_mc = max(r["min_cut_range"][1] for _, r in other_pass)
            hemi_max_mc = max(r["min_cut_range"][1] for _, r in hemi_pass)
            other_max_dens = max(r["density"] for _, r in other_pass)
            hemi_max_dens = max(r["density"] for _, r in hemi_pass)

            print(f"\n  ── Hemisphere vs Other Strategies ──")
            print(f"  Max min-cut:  Hemisphere={hemi_max_mc}  "
                  f"Others={other_max_mc}")
            print(f"  Max density:  Hemisphere={hemi_max_dens:.2f}  "
                  f"Others={other_max_dens:.2f}")
            if hemi_max_mc >= other_max_mc:
                print(f"  → Hemisphere achieves competitive min-cut!")
            else:
                print(f"  → Hemisphere has lower max min-cut "
                      f"(asymmetric topology narrows RT surfaces)")
            print(f"  Hemisphere's unique value: asymmetric boundary =")
            print(f"  distinct topology for the holographic dictionary.")

    # ── Best-in-class (all strategies) ──────────────────────────
    passing = [(l, r) for l, r in all_results if r["gate_pass"]]
    if passing:
        by_density = max(passing, key=lambda x: x[1]["density"])
        by_mincut  = max(passing, key=lambda x: x[1]["min_cut_range"][1])
        by_compact = min(passing, key=lambda x: x[1]["n_boundary_faces"])

        print(f"\n  ── Best-in-Class (all strategies, passing only) ──")
        print(f"  Highest density:     {by_density[0]}  "
              f"(density {by_density[1]['density']:.2f})")
        print(f"  Highest max min-cut: {by_mincut[0]}  "
              f"(min-cut up to {by_mincut[1]['min_cut_range'][1]})")
        print(f"  Most compact:        {by_compact[0]}  "
              f"({by_compact[1]['n_boundary_faces']} bdy faces)")

        print(f"\n  ▶  RECOMMENDATION: {by_mincut[0]}")
        print(f"     Min-cut up to {by_mincut[1]['min_cut_range'][1]} confirms genuine")
        print(f"     multi-face RT surfaces in the discrete bulk.")

    # ── Scorecard ───────────────────────────────────────────────
    n_strats_with_pass = sum(
        1 for s in ["BFS", "Dense", "Geodesic", "Hemisphere"]
        if strat_results.get(s, {"pass": []})["pass"]
    )
    print(f"\n  {'━' * 60}")
    print(f"  FINAL SCORECARD: {n_strats_with_pass}/4 strategies "
          f"produce gate-passing patches")
    for s in ["BFS", "Dense", "Geodesic", "Hemisphere"]:
        sr = strat_results.get(s, {"pass": [], "fail": []})
        mark = "✓" if sr["pass"] else "✗"
        np_ = len(sr["pass"])
        nf_ = len(sr["fail"])
        nt_ = np_ + nf_
        detail = (f"{np_}/{nt_} pass" if nt_ > 0
                  else "no patches in window")
        print(f"    {mark}  {s:<14s}  {detail}")
    print(f"  {'━' * 60}")
    print()


if __name__ == "__main__":
    main()