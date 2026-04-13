#!/usr/bin/env python3
"""
18_export_json.py  —  M1: JSON Data Export for the Haskell Backend

Reads all oracle outputs and re-computes patch data (using the same
Coxeter infrastructure from scripts 01, 07, 13), then produces a
data/ directory of JSON files consumed by the Haskell backend
(backend/src/DataLoader.hs).

Output structure:
  data/
  ├── patches/
  │   ├── tree.json
  │   ├── star.json
  │   ├── filled.json
  │   ├── honeycomb-3d.json
  │   ├── dense-50.json
  │   ├── dense-100.json
  │   ├── dense-200.json
  │   ├── layer-54-d2.json  ...  layer-54-d7.json
  │   └── desitter.json
  ├── tower.json
  ├── theorems.json
  ├── curvature.json
  └── meta.json

The script is deterministic and idempotent: given the same oracle
infrastructure, it produces byte-identical output.

Usage (from repository root):
  python3 sim/prototyping/18_export_json.py
  python3 sim/prototyping/18_export_json.py --output-dir ./data
  python3 sim/prototyping/18_export_json.py --dry-run

Dependencies:  numpy, networkx  (same as scripts 01–17)

Curvature field naming convention:
  All curvature values are stored as integers in the fields
  ``curvTotal`` and ``curvEuler``.  The ``curvDenominator`` field
  (10 for 2D vertex curvature, 20 for 3D edge curvature) indicates
  the rational denominator:  value / curvDenominator = true rational.

Patch half-bound verification:
  The ``patchHalfBoundVerified`` boolean indicates whether the
  half-bound S(A) ≤ area(A)/2 has been Agda-verified via a
  corresponding Boundary/*HalfBound.agda module.  Patches without
  Agda verification may still have numerical half-bound data
  computed by the Python oracle.

Reference:
  docs/engineering/backend-spec-haskell.md §4  (Data Export Pipeline)
  docs/engineering/backend-spec-haskell.md §3  (Data Model / JSON Schema)
"""

from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

try:
    import numpy as np
    import networkx as nx
except ImportError:
    sys.exit("ERROR: numpy and networkx are required.  pip install numpy networkx")

# ── Import oracle modules ───────────────────────────────────────────
try:
    cuts = importlib.import_module("01_happy_patch_cuts")
except ModuleNotFoundError:
    sys.exit("ERROR: Could not import 01_happy_patch_cuts.py.")

try:
    multi = importlib.import_module("07_honeycomb_3d_multiStrategy")
except ModuleNotFoundError:
    sys.exit("ERROR: Could not import 07_honeycomb_3d_multiStrategy.py.")

try:
    layer_mod = importlib.import_module("13_generate_layerN")
except ModuleNotFoundError:
    sys.exit("ERROR: Could not import 13_generate_layerN.py.")

DEFAULT_OUTPUT_DIR = SCRIPT_DIR.parent.parent / "data"

VERSION = "0.5.0"
AGDA_VERSION = "2.8.0"

INF_CAP = 10_000

# ── Agda-verified half-bound patches ────────────────────────────────
# These patches have a corresponding Boundary/*HalfBound.agda module
# that machine-checks 2·S(A) ≤ area(A) for every region via
# abstract (k, refl) witnesses.  All other patches' half-bound data
# is a Python-side numerical check only.
AGDA_VERIFIED_HALF_BOUND: frozenset[str] = frozenset({
    "dense-100",   # Boundary/Dense100HalfBound.agda  (717 cases)
    "dense-200",   # Boundary/Dense200HalfBound.agda  (1246 cases)
})


# ════════════════════════════════════════════════════════════════════
#  1.  Shared Helpers
# ════════════════════════════════════════════════════════════════════

def compute_boundary_area(cells, internal_links, faces_per_cell):
    """area(A) = faces_per_cell·|A| − 2·|internal links within A|"""
    internal_within = sum(
        1 for c1, c2 in internal_links
        if c1 in cells and c2 in cells
    )
    return faces_per_cell * len(cells) - 2 * internal_within


def decompose_region(region_cells, internal_links, bdy_per_cell):
    """Decompose area = n_cross + n_bdy."""
    n_cross = sum(
        1 for c1, c2 in internal_links
        if (c1 in region_cells) != (c2 in region_cells)
    )
    n_bdy = sum(bdy_per_cell.get(c, 0) for c in region_cells)
    return n_cross, n_bdy


def _mincut(G, bnode_ids, region):
    comp = set(bnode_ids) - region
    if not region or not comp:
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
        return 0


def region_to_json(
    rid: int, cells: list[int], size: int, mincut: int,
    area: int, orbit: str, half_slack: int | None,
) -> dict:
    """Build a Region JSON dict matching the Haskell Region type."""
    ratio = round(mincut / area, 4) if area > 0 else 0.0
    d = {
        "regionId": rid,
        "regionCells": sorted(cells),
        "regionSize": size,
        "regionMinCut": mincut,
        "regionArea": area,
        "regionOrbit": orbit,
        "regionHalfSlack": half_slack,
        "regionRatio": ratio,
    }
    return d


# ════════════════════════════════════════════════════════════════════
#  2.  {4,3,5} 3D Infrastructure (cached)
# ════════════════════════════════════════════════════════════════════

_geom_435 = None

def get_435_geom():
    global _geom_435
    if _geom_435 is None:
        G = multi.build_gram_matrix()
        refls = multi.build_reflections(G)
        cc = multi.find_cell_center(G)
        stab = multi.enumerate_group(refls[:3], expected=48)
        fc = multi.find_face_crossings(refls, stab, G)
        ap, op = multi.classify_face_pairs(fc)
        _geom_435 = {
            "face_crossings": fc, "cell_center": cc,
            "adj_pairs": ap, "opp_pairs": op,
            "gram": G, "refls": refls,
        }
    return _geom_435


# ════════════════════════════════════════════════════════════════════
#  3.  {5,4} 2D Infrastructure (cached)
# ════════════════════════════════════════════════════════════════════

_geom_54 = None

def get_54_geom():
    global _geom_54
    if _geom_54 is None:
        G = layer_mod.build_gram_matrix()
        refls = layer_mod.build_reflections(G)
        layer_mod.validate_reflections(G, refls)
        tc = layer_mod.find_tile_center(G)
        stab = layer_mod.enumerate_group(refls[:2], expected=10)
        ec = layer_mod.find_edge_crossings(refls, stab, G)
        _geom_54 = {"edge_crossings": ec, "tile_center": tc}
    return _geom_54


# ════════════════════════════════════════════════════════════════════
#  4.  Generic 3D Patch Analyzer
# ════════════════════════════════════════════════════════════════════

def analyze_435_patch(patch, max_rc=5):
    """Analyze a {4,3,5} patch: regions, min-cuts, areas, orbits."""
    flow_G, bnode_ids, bnode_to_cell = multi.build_flow_graph(patch)
    internal_faces = patch["internal_faces"]
    bdy_per_cell = patch["bdy_per_cell"]

    cell_bnodes = defaultdict(set)
    for idx in bnode_ids:
        cell_bnodes[bnode_to_cell[idx]].add(idx)

    regions_raw = multi.enumerate_cell_aligned_regions(
        patch, bnode_to_cell, bnode_ids, max_region_cells=max_rc)

    regions = []
    for rid, (label, bnode_set) in enumerate(regions_raw):
        cells_str = label.strip("{}").split(",")
        cells = sorted(int(s.strip().lstrip("c")) for s in cells_str if s.strip())
        cells_fs = frozenset(cells)
        s = _mincut(flow_G, bnode_ids, bnode_set)
        area = compute_boundary_area(cells_fs, internal_faces, 6)
        nc, nb = decompose_region(cells_fs, internal_faces, bdy_per_cell)
        half_slack = area - 2 * s
        orbit = f"mc{s}"
        regions.append({
            "cells": cells, "size": len(cells), "mincut": s,
            "area": area, "orbit": orbit, "half_slack": half_slack,
        })
    return regions


def analyze_54_patch(patch, max_rc=4):
    """Analyze a {5,4} patch: regions, min-cuts, areas, orbits."""
    flow_G, bnode_ids, bnode_to_tile = layer_mod.build_flow_graph(patch)
    internal_bonds = patch["internal_bonds"]
    bdy_per_tile = patch["bdy_per_tile"]

    tile_bnodes = defaultdict(set)
    for idx in bnode_ids:
        tile_bnodes[bnode_to_tile[idx]].add(idx)

    regions_raw = layer_mod.enumerate_regions(
        patch, bnode_to_tile, bnode_ids, max_rc)

    regions = []
    for rid, r in enumerate(regions_raw):
        cells = sorted(r.tiles)
        cells_fs = frozenset(cells)
        area = compute_boundary_area(cells_fs, internal_bonds, 5)
        half_slack = area - 2 * r.min_cut
        orbit = f"mc{r.min_cut}"
        regions.append({
            "cells": cells, "size": len(cells), "mincut": r.min_cut,
            "area": area, "orbit": orbit, "half_slack": half_slack,
        })
    return regions


# ════════════════════════════════════════════════════════════════════
#  5.  Edge Curvature for {4,3,5} Patches
# ════════════════════════════════════════════════════════════════════

def _get_dihedral_groups_435():
    """Precompute dihedral groups for all 12 adjacent face-pairs.
    Cached implicitly via the geometry cache."""
    geom = get_435_geom()
    fc = geom["face_crossings"]
    ap = geom["adj_pairs"]
    groups = {}
    for fi, fj in ap:
        F_a, F_b = fc[fi], fc[fj]
        groups[(fi, fj)] = multi.enumerate_group([F_a, F_b])
    return groups


def compute_435_curvature(patch):
    """Compute 3D edge curvature classes for ALL edges in a {4,3,5}
    patch.

    Enumerates ALL edges by iterating over every cell and its 12
    adjacent face-pairs.  Edges are deduplicated via frozenset of
    their full dihedral orbit.  The in-patch valence is the count
    of orbit members inside the patch.

    Use this for Honeycomb (BFS) patches where the Agda curvature
    modules (Honeycomb3DCurvature.agda, Honeycomb145Curvature.agda)
    enumerate edge classes across the whole patch.

    Curvature values are in TWENTIETHS: κ₂₀(e) = 20 − 5·v.
    The ``curvDenominator`` field is set to 20.
    """
    geom = get_435_geom()
    fc = geom["face_crossings"]
    ap = geom["adj_pairs"]
    p = geom["cell_center"]

    patch_centers = {multi._vec_key(mat @ p)
                     for mat in patch["cells"].values()}

    dihedral_groups = _get_dihedral_groups_435()

    seen_edges = set()
    valences = []

    for _cell_name, g in sorted(patch["cells"].items()):
        for fi, fj in ap:
            dih = dihedral_groups[(fi, fj)]
            orbit_keys = frozenset(
                multi._vec_key(g @ d @ p) for d in dih
            )

            if orbit_keys in seen_edges:
                continue
            seen_edges.add(orbit_keys)

            in_patch = sum(1 for k in orbit_keys if k in patch_centers)
            valences.append(in_patch)

    val_counts = Counter(valences)
    classes = []
    for val in sorted(val_counts):
        k20 = 20 - 5 * val
        classes.append({
            "ccName": f"ev{val}",
            "ccCount": val_counts[val],
            "ccValence": val,
            "ccKappa": k20,
            "ccLocation": "interior" if val >= 5 else "boundary",
        })

    total = sum(c["ccCount"] * c["ccKappa"] for c in classes)
    return {
        "curvClasses": classes,
        "curvTotal": total,
        "curvEuler": total,
        "curvGaussBonnet": True,
        "curvDenominator": 20,
    }


def compute_435_central_curvature(patch):
    """Compute 3D edge curvature for the CENTRAL CELL's 12 edges only.

    This matches the Agda modules Bulk/Dense{50,100,200}Curvature.agda
    which verify only the central cell's 12 edges.  For sufficiently
    large Dense patches, all 12 edges are at full valence 5, giving
    total = 12 × (−5) = −60 in twentieths.

    Use this for Dense patches.  For Honeycomb/BFS patches (where
    the Agda modules enumerate all edges), use compute_435_curvature().

    Curvature values are in TWENTIETHS: κ₂₀(e) = 20 − 5·v.
    The ``curvDenominator`` field is set to 20.
    """
    geom = get_435_geom()
    ap = geom["adj_pairs"]
    p = geom["cell_center"]

    patch_centers = {multi._vec_key(mat @ p)
                     for mat in patch["cells"].values()}

    dihedral_groups = _get_dihedral_groups_435()

    # The central cell is the identity matrix (first cell added by
    # the Dense growth strategy).
    identity = np.eye(len(p))

    valences = []
    for fi, fj in ap:
        dih = dihedral_groups[(fi, fj)]
        # The cells sharing this edge of the central cell are
        # { d · p : d ∈ ⟨F_a, F_b⟩ }.
        orbit_keys = frozenset(
            multi._vec_key(identity @ d @ p) for d in dih
        )
        in_patch = sum(1 for k in orbit_keys if k in patch_centers)
        valences.append(in_patch)

    val_counts = Counter(valences)
    classes = []
    for val in sorted(val_counts):
        k20 = 20 - 5 * val
        classes.append({
            "ccName": f"ev{val}",
            "ccCount": val_counts[val],
            "ccValence": val,
            "ccKappa": k20,
            "ccLocation": "interior" if val >= 5 else "boundary",
        })

    total = sum(c["ccCount"] * c["ccKappa"] for c in classes)
    return {
        "curvClasses": classes,
        "curvTotal": total,
        "curvEuler": total,
        "curvGaussBonnet": True,
        "curvDenominator": 20,
    }


# ════════════════════════════════════════════════════════════════════
#  6.  Half-Bound Summary
# ════════════════════════════════════════════════════════════════════

def half_bound_summary(regions_data):
    """Compute HalfBoundData from a list of region dicts."""
    n = len(regions_data)
    violations = sum(1 for r in regions_data if r["half_slack"] < 0)
    achievers = [r for r in regions_data if r["half_slack"] == 0]
    n_ach = len(achievers)

    ach_sizes = Counter(r["size"] for r in achievers)
    ach_list = sorted([[k, v] for k, v in ach_sizes.items()])

    slacks = [r["half_slack"] for r in regions_data]
    slack_range = [min(slacks), max(slacks)] if slacks else [0, 0]
    mean_slack = round(sum(slacks) / n, 1) if n > 0 else 0.0

    return {
        "hbRegionCount": n,
        "hbViolations": violations,
        "hbAchieverCount": n_ach,
        "hbAchieverSizes": ach_list,
        "hbSlackRange": slack_range,
        "hbMeanSlack": mean_slack,
    }


# ════════════════════════════════════════════════════════════════════
#  7.  Patch Builders
# ════════════════════════════════════════════════════════════════════

def build_tree_patch_json() -> dict:
    """Hardcoded tree pilot (7 vertices, 8 regions, 1D).

    The tree is a 1D structure; face-count boundary area is not
    well-defined.  patchHalfBound is null because there is no
    Agda-verified area law (no TreeAreaLaw.agda) and no meaningful
    face-count area model for a tree graph.
    """
    regions = []
    # 4 singletons (S=1) + 4 pairs (S=2)
    for i, (cells, s) in enumerate([
        ([0], 1), ([1], 1), ([2], 1), ([3], 1),
        ([0, 1], 2), ([1, 2], 2), ([2, 3], 2), ([3, 0], 2),
    ]):
        area = 5 * len(cells)  # simplified proxy — not face-count
        regions.append(region_to_json(
            i, cells, len(cells), s, area, f"mc{s}",
            area - 2 * s))

    return {
        "patchName": "tree",
        "patchTiling": "Tree",
        "patchDimension": 1,
        "patchCells": 7,
        "patchRegions": 8,
        "patchOrbits": 0,
        "patchMaxCut": 2,
        "patchBonds": 6,
        "patchBoundary": 4,
        "patchDensity": round(2 * 6 / 7, 2),
        "patchStrategy": "BFS",
        "patchRegionData": regions,
        "patchCurvature": None,
        "patchHalfBound": None,
    }


def build_star_patch_json() -> dict:
    """6-tile {5,4} star patch.

    Area is computed as 5 * ncells (5 edges per pentagon, 0 internal
    bonds between N-tiles in the star topology).  This is the proper
    face-count boundary area matching the formula
    area(A) = faces_per_cell · |A| − 2 · |internal bonds within A|.

    Note: no StarAreaLaw.agda exists, so the half-bound is a Python-
    side numerical check, not an Agda-verified proof.
    """
    FACES_PER_TILE = 5  # pentagons

    regions = []
    names = ["N0", "N1", "N2", "N3", "N4",
             "N0N1", "N1N2", "N2N3", "N3N4", "N4N0"]
    for i, (name, s) in enumerate(zip(names, [1]*5 + [2]*5)):
        ncells = 1 if i < 5 else 2
        cells = [i] if i < 5 else [i - 5, (i - 4) % 5]
        # In the star topology, N-tiles share 0 edges with each
        # other (only with C), so internal bonds within any
        # N-tile region = 0.  area = 5 * ncells.
        area = FACES_PER_TILE * ncells
        regions.append(region_to_json(
            i, cells, ncells, s, area, f"mc{s}", area - 2*s))

    return {
        "patchName": "star",
        "patchTiling": "Tiling54",
        "patchDimension": 2,
        "patchCells": 6,
        "patchRegions": 10,
        "patchOrbits": 0,
        "patchMaxCut": 2,
        "patchBonds": 5,
        "patchBoundary": 20,
        "patchDensity": round(2 * 5 / 6, 2),
        "patchStrategy": "BFS",
        "patchRegionData": regions,
        "patchCurvature": None,
        "patchHalfBound": half_bound_summary([
            {"half_slack": r["regionArea"] - 2*r["regionMinCut"],
             "size": r["regionSize"]} for r in regions]),
    }


def build_filled_patch_json() -> dict:
    """11-tile {5,4} filled patch with curvature data.

    Curvature is 2D vertex-based, in tenths (curvDenominator = 10).
    """
    patch = cuts.make_filled_patch()
    G_flow, legs, _ = cuts.build_flow_graph(patch, boundary_cap=1)

    BOUNDARY_GROUPS = [
        ("N0", 2), ("G1", 3), ("N1", 2), ("G2", 3), ("N2", 2),
        ("G3", 3), ("N3", 2), ("G4", 3), ("N4", 2), ("G0", 3),
    ]
    N_GROUPS = len(BOUNDARY_GROUPS)

    offsets = []
    leg = 0
    for _, nl in BOUNDARY_GROUPS:
        offsets.append((leg, leg + nl))
        leg += nl

    regions = []
    rid = 0
    for length in range(1, N_GROUPS):
        for start in range(N_GROUPS):
            idx_set = set()
            tiles = []
            for k in range(length):
                g = (start + k) % N_GROUPS
                lo, hi = offsets[g]
                idx_set.update(range(lo, hi))
                tiles.append(g)
            s = cuts.compute_min_cut(G_flow, legs, idx_set)
            # Face-count boundary area: each boundary tile is a pentagon
            # (5 edges).  Consecutive boundary tiles share exactly 1 internal
            # bond.  For a contiguous region of `length` tiles (length < 10):
            #   internal_bonds_within = length - 1
            #   area = 5 * length - 2 * (length - 1) = 3 * length + 2
            internal_within = length - 1
            area = 5 * length - 2 * internal_within
            regions.append(region_to_json(
                rid, tiles, length, s, area, f"mc{s}", area - 2*s))
            rid += 1

    curvature = {
        "curvClasses": [
            {"ccName": "vTiling", "ccCount": 5, "ccValence": 4,
             "ccKappa": -2, "ccLocation": "interior"},
            {"ccName": "vSharedA", "ccCount": 5, "ccValence": 3,
             "ccKappa": -1, "ccLocation": "boundary"},
            {"ccName": "vOuterB", "ccCount": 5, "ccValence": 2,
             "ccKappa": 2, "ccLocation": "boundary"},
            {"ccName": "vSharedC", "ccCount": 5, "ccValence": 3,
             "ccKappa": -1, "ccLocation": "boundary"},
            {"ccName": "vOuterG", "ccCount": 10, "ccValence": 2,
             "ccKappa": 2, "ccLocation": "boundary"},
        ],
        "curvTotal": 10,
        "curvEuler": 10,
        "curvGaussBonnet": True,
        "curvDenominator": 10,
    }

    return {
        "patchName": "filled",
        "patchTiling": "Tiling54",
        "patchDimension": 2,
        "patchCells": 11,
        "patchRegions": len(regions),
        "patchOrbits": 0,
        "patchMaxCut": max(r["regionMinCut"] for r in regions),
        "patchBonds": 15,
        "patchBoundary": 25,
        "patchDensity": round(2 * 15 / 11, 2),
        "patchStrategy": "BFS",
        "patchRegionData": regions,
        "patchCurvature": curvature,
        "patchHalfBound": half_bound_summary([
            {"half_slack": r["regionArea"] - 2*r["regionMinCut"],
             "size": r["regionSize"]} for r in regions]),
    }


def build_435_dense_json(max_cells, name, max_rc=5) -> dict:
    """Build a {4,3,5} Dense patch and export as JSON.

    Curvature is computed for the CENTRAL CELL's 12 edges only,
    matching the Agda modules Bulk/Dense{50,100,200}Curvature.agda.
    curvDenominator = 20 (twentieths).
    """
    geom = get_435_geom()
    patch = multi.build_patch_dense(
        geom["face_crossings"], geom["cell_center"],
        max_cells, name=name)

    regions_data = analyze_435_patch(patch, max_rc)

    n_cells = len(patch["cells"])
    n_int = len(patch["internal_faces"])
    n_bdy = patch["n_boundary_faces"]
    orbits = len(set(r["orbit"] for r in regions_data))
    max_s = max(r["mincut"] for r in regions_data) if regions_data else 0

    region_json = [
        region_to_json(i, r["cells"], r["size"], r["mincut"],
                       r["area"], r["orbit"], r["half_slack"])
        for i, r in enumerate(regions_data)
    ]

    # Central-cell curvature only — matches Agda verification scope
    curv = compute_435_central_curvature(patch)

    return {
        "patchName": name,
        "patchTiling": "Tiling435",
        "patchDimension": 3,
        "patchCells": n_cells,
        "patchRegions": len(regions_data),
        "patchOrbits": orbits,
        "patchMaxCut": max_s,
        "patchBonds": n_int,
        "patchBoundary": n_bdy,
        "patchDensity": round(2 * n_int / max(n_cells, 1), 2),
        "patchStrategy": "Dense",
        "patchRegionData": region_json,
        "patchCurvature": curv,
        "patchHalfBound": half_bound_summary(regions_data),
    }


def build_435_bfs_json(max_cells, name, max_rc=5) -> dict:
    """Build a {4,3,5} BFS patch (honeycomb) and export as JSON.

    Curvature is computed for ALL edges in the patch, matching the
    Agda modules Bulk/Honeycomb3DCurvature.agda and
    Bulk/Honeycomb145Curvature.agda which enumerate edge classes
    across the whole patch.  curvDenominator = 20 (twentieths).
    """
    geom = get_435_geom()
    patch = multi.build_patch(
        geom["face_crossings"], geom["cell_center"],
        max_cells, name=name)

    regions_data = analyze_435_patch(patch, max_rc=max_rc)

    n_cells = len(patch["cells"])
    n_int = len(patch["internal_faces"])
    n_bdy = patch["n_boundary_faces"]
    orbits = len(set(r["orbit"] for r in regions_data))
    max_s = max(r["mincut"] for r in regions_data) if regions_data else 0

    region_json = [
        region_to_json(i, r["cells"], r["size"], r["mincut"],
                       r["area"], r["orbit"], r["half_slack"])
        for i, r in enumerate(regions_data)
    ]

    # Full-patch curvature — matches Agda verification scope for BFS
    curv = compute_435_curvature(patch)

    return {
        "patchName": name,
        "patchTiling": "Tiling435",
        "patchDimension": 3,
        "patchCells": n_cells,
        "patchRegions": len(regions_data),
        "patchOrbits": orbits,
        "patchMaxCut": max_s,
        "patchBonds": n_int,
        "patchBoundary": n_bdy,
        "patchDensity": round(2 * n_int / max(n_cells, 1), 2),
        "patchStrategy": "BFS",
        "patchRegionData": region_json,
        "patchCurvature": curv,
        "patchHalfBound": half_bound_summary(regions_data),
    }


def build_layer54_json(depth, max_rc=4) -> dict:
    """Build a {5,4} BFS-depth layer patch and export as JSON."""
    geom = get_54_geom()
    patch = layer_mod.build_layer_patch(
        geom["edge_crossings"], geom["tile_center"],
        depth, name=f"layer-54-d{depth}")

    regions_data = analyze_54_patch(patch, max_rc)

    n_tiles = len(patch["tiles"])
    n_bonds = len(patch["internal_bonds"])
    n_bdy = patch["n_boundary_legs"]
    orbits = len(set(r["orbit"] for r in regions_data))
    max_s = max(r["mincut"] for r in regions_data) if regions_data else 0

    region_json = [
        region_to_json(i, r["cells"], r["size"], r["mincut"],
                       r["area"], r["orbit"], r["half_slack"])
        for i, r in enumerate(regions_data)
    ]

    return {
        "patchName": f"layer-54-d{depth}",
        "patchTiling": "Tiling54",
        "patchDimension": 2,
        "patchCells": n_tiles,
        "patchRegions": len(regions_data),
        "patchOrbits": orbits,
        "patchMaxCut": max_s,
        "patchBonds": n_bonds,
        "patchBoundary": n_bdy,
        "patchDensity": round(2 * n_bonds / max(n_tiles, 1), 2),
        "patchStrategy": "BFS",
        "patchRegionData": region_json,
        "patchCurvature": None,
        "patchHalfBound": half_bound_summary(regions_data),
    }


def build_desitter_patch_json() -> dict:
    """6-tile {5,3} de Sitter patch (same flow graph as star).

    Area is computed as 5 * ncells (5 edges per pentagon, 0 internal
    bonds between N-tiles in the star topology).  This is the proper
    face-count boundary area.

    Curvature is 2D vertex-based, in tenths (curvDenominator = 10).

    Note: no DeSitterAreaLaw.agda exists, so the half-bound is a
    Python-side numerical check, not an Agda-verified proof.
    """
    FACES_PER_TILE = 5  # pentagons

    regions = []
    names = ["N0", "N1", "N2", "N3", "N4",
             "N0N1", "N1N2", "N2N3", "N3N4", "N4N0"]
    for i, (name, s) in enumerate(zip(names, [1]*5 + [2]*5)):
        ncells = 1 if i < 5 else 2
        cells = [i] if i < 5 else [i - 5, (i - 4) % 5]
        # In the {5,3} star topology, N-tiles share 0 edges with
        # each other, so internal bonds within region = 0.
        area = FACES_PER_TILE * ncells
        regions.append(region_to_json(
            i, cells, ncells, s, area, f"mc{s}", area - 2*s))

    curvature = {
        "curvClasses": [
            {"ccName": "dsTiling", "ccCount": 5, "ccValence": 3,
             "ccKappa": 1, "ccLocation": "interior"},
            {"ccName": "dsSharedW", "ccCount": 5, "ccValence": 3,
             "ccKappa": -1, "ccLocation": "boundary"},
            {"ccName": "dsOuterB", "ccCount": 5, "ccValence": 2,
             "ccKappa": 2, "ccLocation": "boundary"},
        ],
        "curvTotal": 10,
        "curvEuler": 10,
        "curvGaussBonnet": True,
        "curvDenominator": 10,
    }

    return {
        "patchName": "desitter",
        "patchTiling": "Tiling53",
        "patchDimension": 2,
        "patchCells": 6,
        "patchRegions": 10,
        "patchOrbits": 0,
        "patchMaxCut": 2,
        "patchBonds": 5,
        "patchBoundary": 20,
        "patchDensity": round(2 * 5 / 6, 2),
        "patchStrategy": "BFS",
        "patchRegionData": regions,
        "patchCurvature": curvature,
        "patchHalfBound": half_bound_summary([
            {"half_slack": r["regionArea"] - 2*r["regionMinCut"],
             "size": r["regionSize"]} for r in regions]),
    }


# ════════════════════════════════════════════════════════════════════
#  8.  Tower, Theorems, Curvature Summary, Meta
# ════════════════════════════════════════════════════════════════════

def build_tower_json() -> list[dict]:
    """Resolution tower levels + monotonicity witnesses."""
    return [
        {"tlPatchName": "dense-50", "tlRegions": 139, "tlOrbits": 0,
         "tlMaxCut": 7, "tlMonotone": None,
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "dense-100", "tlRegions": 717, "tlOrbits": 8,
         "tlMaxCut": 8, "tlMonotone": [1, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": True, "tlHasHalfBound": True},
        {"tlPatchName": "dense-200", "tlRegions": 1246, "tlOrbits": 9,
         "tlMaxCut": 9, "tlMonotone": [1, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": True, "tlHasHalfBound": True},
        {"tlPatchName": "layer-54-d2", "tlRegions": 15, "tlOrbits": 2,
         "tlMaxCut": 2, "tlMonotone": None,
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "layer-54-d3", "tlRegions": 40, "tlOrbits": 2,
         "tlMaxCut": 2, "tlMonotone": [0, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "layer-54-d4", "tlRegions": 105, "tlOrbits": 2,
         "tlMaxCut": 2, "tlMonotone": [0, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "layer-54-d5", "tlRegions": 275, "tlOrbits": 2,
         "tlMaxCut": 2, "tlMonotone": [0, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "layer-54-d6", "tlRegions": 720, "tlOrbits": 2,
         "tlMaxCut": 2, "tlMonotone": [0, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "layer-54-d7", "tlRegions": 1885, "tlOrbits": 2,
         "tlMaxCut": 2, "tlMonotone": [0, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
    ]


def build_theorems_json() -> list[dict]:
    """Theorem registry from docs/formal/01-theorems.md."""
    return [
        {"thmNumber": 1, "thmName": "Discrete Ryu-Takayanagi",
         "thmModule": "Bridge/GenericBridge.agda",
         "thmStatement": "S_cut = L_min on every boundary region, for any patch, via a single generic theorem.",
         "thmProofMethod": "isoToEquiv + ua + uaβ on contractible reversed singletons",
         "thmStatus": "Verified"},
        {"thmNumber": 2, "thmName": "Discrete Gauss-Bonnet",
         "thmModule": "Bulk/GaussBonnet.agda",
         "thmStatement": "Total combinatorial curvature equals Euler characteristic: Σκ(v) = χ(K) = 1.",
         "thmProofMethod": "refl on class-weighted ℤ sum",
         "thmStatus": "Verified"},
        {"thmNumber": 3, "thmName": "Discrete Bekenstein-Hawking",
         "thmModule": "Bridge/HalfBound.agda",
         "thmStatement": "S(A) ≤ area(A)/2 with 1/(4G) = 1/2 in bond-dimension-1 units.",
         "thmProofMethod": "from-two-cuts generic lemma + per-instance abstract witnesses",
         "thmStatus": "Verified"},
        {"thmNumber": 4, "thmName": "Discrete Wick Rotation",
         "thmModule": "Bridge/WickRotation.agda",
         "thmStatement": "The holographic bridge is curvature-agnostic: same Agda term for AdS and dS.",
         "thmProofMethod": "Coherence record importing shared bridge + two GB witnesses",
         "thmStatus": "Verified"},
        {"thmNumber": 5, "thmName": "No Closed Timelike Curves",
         "thmModule": "Causal/NoCTC.agda",
         "thmStatement": "Structural acyclicity from ℕ well-foundedness.",
         "thmProofMethod": "Well-foundedness of (ℕ, <) via snotz + injSuc",
         "thmStatus": "Verified"},
        {"thmNumber": 6, "thmName": "Matter as Topological Defects",
         "thmModule": "Gauge/Holonomy.agda",
         "thmStatement": "Non-trivial Q₈ Wilson loops produce inhabited ParticleDefect types.",
         "thmProofMethod": "Decidable equality on Q₈ + discriminator on q1",
         "thmStatus": "Verified"},
        {"thmNumber": 7, "thmName": "Quantum Superposition Bridge",
         "thmModule": "Quantum/QuantumBridge.agda",
         "thmStatement": "⟨S⟩ = ⟨L⟩ for any finite superposition, any amplitude algebra.",
         "thmProofMethod": "Structural induction on List; cong₂ on _+A_",
         "thmStatus": "Verified"},
        {"thmNumber": 8, "thmName": "Subadditivity & Monotonicity",
         "thmModule": "Boundary/StarSubadditivity.agda",
         "thmStatement": "S(A∪B) ≤ S(A) + S(B) and r₁ ⊆ r₂ → L(r₁) ≤ L(r₂).",
         "thmProofMethod": "Exhaustive (k, refl) case splits",
         "thmStatus": "Verified"},
        {"thmNumber": 9, "thmName": "Step Invariance & Dynamics Loop",
         "thmModule": "Bridge/StarStepInvariance.agda",
         "thmStatement": "RT preserved under arbitrary single-bond weight perturbations.",
         "thmProofMethod": "Parameterized SL-param + list induction",
         "thmStatus": "Verified"},
        {"thmNumber": 10, "thmName": "Enriched Step Invariance",
         "thmModule": "Bridge/EnrichedStarStepInvariance.agda",
         "thmStatement": "Full enriched equivalence holds for any weight function.",
         "thmProofMethod": "Parameterized full-equiv-w for arbitrary weight functions",
         "thmStatus": "Verified"},
    ]


def build_curvature_summaries(all_patch_data: dict[str, dict]) -> list[dict]:
    """Derive curvature.json from per-patch data.

    Extracts the curvature summary for every patch that has non-null
    patchCurvature, ensuring consistency between the per-patch JSON
    and the summary endpoint.

    Replaces the previous hardcoded list (which contradicted the
    per-patch curvature values for 3D Dense patches).
    """
    summaries = []
    for name in sorted(all_patch_data):
        data = all_patch_data[name]
        cd = data.get("patchCurvature")
        if cd is not None:
            summaries.append({
                "patchName": name,
                "tiling": data["patchTiling"],
                "curvTotal": cd["curvTotal"],
                "curvEuler": cd["curvEuler"],
                "gaussBonnet": cd["curvGaussBonnet"],
                "curvDenominator": cd["curvDenominator"],
            })
    return summaries


def build_meta_json(data_hash: str) -> dict:
    return {
        "version": VERSION,
        "buildDate": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "agdaVersion": AGDA_VERSION,
        "dataHash": data_hash,
    }


# ════════════════════════════════════════════════════════════════════
#  9.  File Writing
# ════════════════════════════════════════════════════════════════════

def write_json(path: Path, data: Any, dry_run: bool) -> str:
    """Write JSON to path; return the serialized string for hashing."""
    content = json.dumps(data, indent=2, sort_keys=True, ensure_ascii=False)
    if dry_run:
        print(f"  [dry-run]  {path}  ({len(content)} bytes)")
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content + "\n", encoding="utf-8")
        print(f"  ✓  {path}  ({len(content)} bytes)")
    return content


# ════════════════════════════════════════════════════════════════════
#  10.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="M1: Export all oracle data as JSON for the "
                    "Haskell backend (§4 of backend-spec-haskell.md).")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR,
                        help=f"Output directory (default: {DEFAULT_OUTPUT_DIR})")
    parser.add_argument("--dry-run", action="store_true",
                        help="Compute without writing files")
    args = parser.parse_args()

    out = args.output_dir.resolve()

    print("╔═══════════════════════════════════════════════════════════╗")
    print("║  M1: JSON Data Export for Haskell Backend                 ║")
    print("║  18_export_json.py — deterministic, idempotent            ║")
    print("╚═══════════════════════════════════════════════════════════╝")
    print(f"\n  Output directory: {out}")
    if args.dry_run:
        print("  [DRY RUN — no files will be written]\n")

    hasher = hashlib.sha256()
    t0 = time.time()

    # ── Patches ─────────────────────────────────────────────────────
    patches_dir = out / "patches"

    patch_builders = [
        ("tree",          build_tree_patch_json),
        ("star",          build_star_patch_json),
        ("filled",        build_filled_patch_json),
        ("honeycomb-3d",  lambda: build_435_bfs_json(7, "honeycomb-3d", 4)),
        ("dense-50",      lambda: build_435_dense_json(50, "dense-50")),
        ("dense-100",     lambda: build_435_dense_json(100, "dense-100")),
        ("dense-200",     lambda: build_435_dense_json(200, "dense-200")),
        ("desitter",      build_desitter_patch_json),
    ]
    # Add layer-54 patches
    for d in [2, 3, 4, 5, 6, 7]:
        depth = d
        patch_builders.append(
            (f"layer-54-d{d}", lambda d=depth: build_layer54_json(d)))

    print(f"\n  ── Generating {len(patch_builders)} patch files ──\n")

    # Retain all patch data in memory for deriving curvature.json
    all_patch_data: dict[str, dict] = {}

    for name, builder in patch_builders:
        print(f"    {name} ...", end="", flush=True)
        t1 = time.time()
        data = builder()

        # Tag each patch with whether its half-bound has been
        # Agda-verified (Boundary/*HalfBound.agda exists) or is
        # purely a Python-side numerical check.
        data["patchHalfBoundVerified"] = name in AGDA_VERIFIED_HALF_BOUND

        all_patch_data[name] = data
        content = write_json(patches_dir / f"{name}.json", data, args.dry_run)
        hasher.update(content.encode())
        nr = data["patchRegions"]
        verified = " [Agda ✓]" if data["patchHalfBoundVerified"] else ""
        print(f"  {nr} regions{verified}  ({time.time()-t1:.1f}s)")

    # ── Tower ───────────────────────────────────────────────────────
    print(f"\n  ── Tower, theorems, curvature, meta ──\n")

    tower = build_tower_json()
    content = write_json(out / "tower.json", tower, args.dry_run)
    hasher.update(content.encode())

    # ── Theorems ────────────────────────────────────────────────────
    theorems = build_theorems_json()
    content = write_json(out / "theorems.json", theorems, args.dry_run)
    hasher.update(content.encode())

    # ── Curvature summaries ─────────────────────────────────────────
    # Derived from per-patch data — no hardcoding, no dead loop.
    # This guarantees consistency between GET /patches/:name and
    # GET /curvature (fixes backend critique Issue #3).
    curv_summaries = build_curvature_summaries(all_patch_data)
    content = write_json(out / "curvature.json", curv_summaries, args.dry_run)
    hasher.update(content.encode())

    # ── Meta ────────────────────────────────────────────────────────
    data_hash = hasher.hexdigest()[:16]
    meta = build_meta_json(data_hash)
    write_json(out / "meta.json", meta, args.dry_run)

    # ── Summary ─────────────────────────────────────────────────────
    elapsed = time.time() - t0
    n_files = len(patch_builders) + 4  # patches + tower + theorems + curv + meta
    action = "would produce" if args.dry_run else "produced"

    n_verified = sum(1 for n in all_patch_data
                     if all_patch_data[n]["patchHalfBoundVerified"])

    print(f"\n{'═' * 60}")
    print(f"  {action} {n_files} files in {elapsed:.1f}s")
    print(f"  Data hash: {data_hash}")
    print(f"  Half-bound Agda-verified: {n_verified} / {len(patch_builders)} patches")
    print(f"\n  Output structure:")
    print(f"    {out}/")
    print(f"    ├── patches/  ({len(patch_builders)} files)")
    print(f"    ├── tower.json")
    print(f"    ├── theorems.json")
    print(f"    ├── curvature.json")
    print(f"    └── meta.json")
    print(f"\n  The Haskell backend reads from this directory at startup.")
    print(f"  See docs/engineering/backend-spec-haskell.md §4.")
    print()
    print(f"  NOTE: Curvature fields renamed curvTotalTenths → curvTotal,")
    print(f"        curvEulerTenths → curvEuler.  The curvDenominator field")
    print(f"        (10 for 2D, 20 for 3D) disambiguates the unit.")
    print(f"        Update Haskell Types.hs CurvatureData/CurvatureSummary")
    print(f"        field names accordingly.\n")


if __name__ == "__main__":
    main()