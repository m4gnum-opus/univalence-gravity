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
  │   ├── honeycomb-145.json
  │   ├── dense-50.json
  │   ├── dense-100.json
  │   ├── dense-200.json
  │   ├── dense-1000.json
  │   ├── layer-54-d2.json  ...  layer-54-d7.json
  │   └── desitter.json
  ├── tower.json
  ├── theorems.json
  ├── curvature.json
  └── meta.json

The script is deterministic and idempotent: given the same oracle
infrastructure, it produces byte-identical output.

IMPORTANT — Agda-alignment convention:
  Each patch's region count and max_region_cells must match the
  corresponding Agda Spec module (Common/*Spec.agda).  The Agda
  modules are the source of truth; this script must reproduce the
  same region enumeration parameters used by the generator scripts
  (06, 06b, 08, 09, 12, 12b, 13).

  honeycomb-3d:  max_rc=1  (26 singletons, from 06_generate)
  honeycomb-145: max_rc=5  (1008 regions,  from 06b_generate)
  dense-50:      max_rc=5  (139 regions,   from 08_generate)
  dense-100:     max_rc=5  (717 regions,   from 09_generate)
  dense-200:     max_rc=5  (1246 regions,  from 12_generate)
  dense-1000:    max_rc=6  (10317 regions, from 12b_generate)
  layer-54-dN:   max_rc=4  (varies,        from 13_generate)

Usage (from repository root):
  python3 sim/prototyping/18_export_json.py
  python3 sim/prototyping/18_export_json.py --output-dir ./data
  python3 sim/prototyping/18_export_json.py --dry-run

Dependencies:  numpy, networkx  (same as scripts 01–17)

NOTE: dense-1000 at max_rc=6 takes ~25 minutes to compute.  The
full export (all 16 patches) runs for ~40 minutes total.

Reference:
  docs/engineering/backend-spec-haskell.md §4  (Data Export Pipeline)
  docs/engineering/backend-spec-haskell.md §3  (Data Model / JSON Schema)
"""

from __future__ import annotations

import argparse
import hashlib
import importlib
import json
import math
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

VERSION = "0.6.0"
AGDA_VERSION = "2.8.0"

INF_CAP = 10_000

# ── Agda-verified half-bound patches ────────────────────────────────
AGDA_VERIFIED_HALF_BOUND: frozenset[str] = frozenset({
    "dense-100",
    "dense-200",
    "dense-1000",
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
    curvature: float | None = None,
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
        "regionCurvature": curvature,
    }
    return d


def _region_avg_curvature(
    cells: list[int],
    cell_curvature: dict[int, float] | None,
) -> float | None:
    """Compute the average curvature for a set of cells.

    Returns None if no curvature data is available.
    For singleton regions this returns the cell's own curvature.
    For multi-cell regions it returns the arithmetic mean.
    """
    if not cell_curvature or not cells:
        return None
    values = [cell_curvature[c] for c in cells if c in cell_curvature]
    if not values:
        return None
    return round(sum(values) / len(values), 6)


def poincare_project(
    gram_matrix: np.ndarray,
    cell_matrices: dict[int, np.ndarray],
    center: np.ndarray,
) -> dict[int, dict]:
    """Project cell/tile centres from the hyperboloid to the Poincaré ball.

    The Gram matrix G has signature (n-1, 1).  Cell centres g @ center live
    on the hyperboloid <p,p>_G = -R² < 0.  Implementation follows
    docs Roadmap "Centre Patches in Poincaré Projection":

      Step 1 — Centring (Lorentz boost).  Diagonalise G, change into the
      canonical Minkowski basis via  D·V^T  where  D = diag(√|λ_i|), and
      apply a Lorentz boost  B  that maps the fundamental cell centre to
      the apex  (0,…,0, +R)_{neg_idx}.  With this, g = I projects to the
      origin of the Poincaré ball (verified by refl: u = 0/2 = 0).

      Step 3 — Rotation.  For each cell compute the boosted Lorentz
      matrix  M_cell = T g T⁻¹ , then pre-multiply by the inverse boost
      at the cell's (boosted) position to strip translation.  The spatial
      block of the resulting rotation is orthogonalised via SVD and
      converted to a quaternion (Shepperd–Shuster for 3D, z-axis rotation
      for 2D).

    Parameters
    ----------
    gram_matrix   : (n, n) Gram matrix, signature (n-1, 1).
    cell_matrices : {id: g}, where g is an n×n transformation matrix.
    center        : n-vector, the fundamental cell/tile centre.

    Returns
    -------
    {id: {"pos": (x, y, z), "quat": (qx, qy, qz, qw)}}
    The z-coordinate is 0.0 for 2D tilings; quat's x/y components are 0
    (rotation around the disk normal).
    """
    # Issue #5 — fail loudly on exotic key types.  All current callers pass
    # integer cell / tile ids; anything else signals a wiring mistake.
    assert all(isinstance(k, int) for k in cell_matrices), (
        "poincare_project expects {int: np.ndarray}; got keys "
        f"{ {type(k).__name__ for k in cell_matrices} }"
    )
    eigenvalues, eigenvectors = np.linalg.eigh(gram_matrix)
    neg_idx = int(np.argmin(eigenvalues))          # timelike direction
    n = len(eigenvalues)
    spatial_idx = [i for i in range(n) if i != neg_idx]
    scale_factors = np.sqrt(np.abs(eigenvalues))
    norm_sq = float(center @ gram_matrix @ center)  # negative
    R = float(np.sqrt(-norm_sq))

    # Step 1 — Build the Lorentz boost that centres the fundamental cell.
    p_scaled = (eigenvectors.T @ center) * scale_factors
    B = _lorentz_boost_to_apex(p_scaled, neg_idx, R, n)

    # Combined root-basis → boosted canonical transform (and its inverse).
    # Issue #3 — previous revision computed an unused D_inv.  Removed;
    # T_inv comes straight from np.linalg.inv(T), which is stable enough
    # for the 3×3 / 4×4 matrices in play here.
    D = np.diag(scale_factors)
    T = B @ D @ eigenvectors.T
    T_inv = np.linalg.inv(T)

    positions: dict[int, dict] = {}
    for cell_id, g in cell_matrices.items():
        # Boosted canonical position of the cell centre.
        c_canon = T @ g @ center
        # Keep time component future-directed so (1 + t) > 0.
        if c_canon[neg_idx] < 0:
            c_canon = -c_canon
        t = c_canon[neg_idx] / R
        spatial = np.array([c_canon[i] for i in spatial_idx]) / R
        denom = 1.0 + t
        u = spatial / denom

        # Step 2 — per-cell conformal scale factor for the Poincaré ball/disk.
        #     s(u) = (1 − |u|²) / 2
        # Clamped at 1e-6 so cells that land numerically on the boundary
        # (|u| = 1) remain drawable.  Rounded to keep JSON byte-identical
        # under re-export.
        u_norm_sq = float(u @ u)
        conf_scale = round(max((1.0 - u_norm_sq) / 2.0, 1e-6), 6)

        if len(u) >= 3:
            pos = (round(float(u[0]), 6),
                   round(float(u[1]), 6),
                   round(float(u[2]), 6))
        elif len(u) == 2:
            pos = (round(float(u[0]), 6),
                   round(float(u[1]), 6), 0.0)
        else:
            pos = (round(float(u[0]), 6), 0.0, 0.0)

        # Step 3 — Extract rotation quaternion for this cell.
        # Issue #4 — _lorentz_boost_to_apex runs once per cell on top of the
        # global B above, so ~N+1 boost constructions per patch.  At
        # Dense-1000 (N ≈ 10⁴) this is still dwarfed by region enumeration
        # and max-flow; revisit only if a future patch pushes much larger.
        # B_c is the boost that sends c_canon back to the apex; applied
        # to M_cell = T g T⁻¹ it yields a pure rotation fixing the apex.
        # Its spatial (n-1)×(n-1) block is the rotation we emit.
        B_c = _lorentz_boost_to_apex(c_canon, neg_idx, R, n)
        M_cell = T @ g @ T_inv
        R_full = B_c @ M_cell
        R_spatial = np.array(
            [[R_full[i, j] for j in spatial_idx] for i in spatial_idx]
        )
        # Polar decomposition via SVD: discard any numerical non-orthogonality.
        U_svd, _, Vt_svd = np.linalg.svd(R_spatial)
        R_ortho = U_svd @ Vt_svd
        if np.linalg.det(R_ortho) < 0:
            U_svd[:, -1] = -U_svd[:, -1]
            R_ortho = U_svd @ Vt_svd
        quat = _matrix_to_quaternion(R_ortho)

        positions[cell_id] = {
            "pos":   pos,
            "quat":  quat,
            "scale": conf_scale,
        }

    return positions


def _lorentz_boost_to_apex(
    p_scaled: np.ndarray, neg_idx: int, R: float, n: int,
) -> np.ndarray:
    """Build the Lorentz boost B with  B @ p_scaled = (0,…,0, +R)_{neg_idx}.

    p_scaled lives in the canonical diagonalised basis with metric
    diag(+,…,+,−,+,…) (the − at neg_idx).  We assume it's timelike:
    <p_scaled, p_scaled> = -R².

    If the time component is negative we first flip the time axis, then
    apply the standard (n̂, t)-plane boost.
    """
    spatial_idx = [i for i in range(n) if i != neg_idx]
    t_c = float(p_scaled[neg_idx])
    s = np.array([float(p_scaled[i]) for i in spatial_idx])

    B_flip = np.eye(n)
    if t_c < 0.0:
        B_flip[neg_idx, neg_idx] = -1.0
        t_c = -t_c

    s_norm = float(np.linalg.norm(s))
    if s_norm < 1e-12:
        # Already at the apex (or on the time axis after the flip).
        return B_flip

    cosh_eta = t_c / R
    sinh_eta = s_norm / R
    n_hat = s / s_norm

    B_std = np.eye(n)
    # Spatial-spatial block: I + (cosh-1) n̂ n̂ᵀ
    nh_outer = np.outer(n_hat, n_hat)
    for a, i in enumerate(spatial_idx):
        for b, j in enumerate(spatial_idx):
            delta = 1.0 if a == b else 0.0
            B_std[i, j] = delta + (cosh_eta - 1.0) * nh_outer[a, b]
    # Coupling: -sinh n̂ in both off-diagonal blocks
    for a, i in enumerate(spatial_idx):
        B_std[i, neg_idx] = -sinh_eta * n_hat[a]
        B_std[neg_idx, i] = -sinh_eta * n_hat[a]
    B_std[neg_idx, neg_idx] = cosh_eta

    return B_std @ B_flip


def _matrix_to_quaternion(R_mat: np.ndarray) -> tuple:
    """Convert a 2×2 or 3×3 rotation matrix to (qx, qy, qz, qw).

    For 2D patches (Poincaré disk), the rotation lives in the xy-plane
    and is embedded as a z-axis rotation in 3D.
    For 3D patches (Poincaré ball), uses the standard Shepperd–Shuster
    algorithm (numerically stable across all branches).
    """
    if R_mat.shape == (2, 2):
        angle = float(np.arctan2(R_mat[1, 0], R_mat[0, 0]))
        half = angle / 2.0
        return (0.0, 0.0,
                round(float(np.sin(half)), 6),
                round(float(np.cos(half)), 6))

    # 3×3 case
    tr = R_mat[0, 0] + R_mat[1, 1] + R_mat[2, 2]
    if tr > 0.0:
        s = 2.0 * np.sqrt(tr + 1.0)
        qw = 0.25 * s
        qx = (R_mat[2, 1] - R_mat[1, 2]) / s
        qy = (R_mat[0, 2] - R_mat[2, 0]) / s
        qz = (R_mat[1, 0] - R_mat[0, 1]) / s
    elif R_mat[0, 0] >= R_mat[1, 1] and R_mat[0, 0] >= R_mat[2, 2]:
        s = 2.0 * np.sqrt(1.0 + R_mat[0, 0] - R_mat[1, 1] - R_mat[2, 2])
        qw = (R_mat[2, 1] - R_mat[1, 2]) / s
        qx = 0.25 * s
        qy = (R_mat[0, 1] + R_mat[1, 0]) / s
        qz = (R_mat[0, 2] + R_mat[2, 0]) / s
    elif R_mat[1, 1] >= R_mat[2, 2]:
        s = 2.0 * np.sqrt(1.0 + R_mat[1, 1] - R_mat[0, 0] - R_mat[2, 2])
        qw = (R_mat[0, 2] - R_mat[2, 0]) / s
        qx = (R_mat[0, 1] + R_mat[1, 0]) / s
        qy = 0.25 * s
        qz = (R_mat[1, 2] + R_mat[2, 1]) / s
    else:
        s = 2.0 * np.sqrt(1.0 + R_mat[2, 2] - R_mat[0, 0] - R_mat[1, 1])
        qw = (R_mat[1, 0] - R_mat[0, 1]) / s
        qx = (R_mat[0, 2] + R_mat[2, 0]) / s
        qy = (R_mat[1, 2] + R_mat[2, 1]) / s
        qz = 0.25 * s
    return (round(float(qx), 6), round(float(qy), 6),
            round(float(qz), 6), round(float(qw), 6))

def _make_patch_graph(
    nodes: list[int],
    edges: list[list[int]],
    positions: dict[int, tuple | dict] | None = None,
) -> dict:
    """Build a patchGraph dict with node positions, quaternions, scale, edges.

    ``positions`` may map node id to either
      • an ``(x, y, z)`` tuple   (legacy — hand-made 2D layouts), or
      • a ``{"pos": …, "quat": …, "scale": …}`` dict emitted by
        ``poincare_project`` per roadmap Steps 1–3.

    Issue #2 — every emitted node carries a UNIFORM SCHEMA:
        {id, x, y, z, qx, qy, qz, qw, scale}

    regardless of whether the geometry comes from the Poincaré projector
    (honeycomb / dense / layer patches) or from a hand-written 2D layout
    (tree / star / filled / desitter).  For the latter we synthesise
    scale from the stored (x, y, z) via s(u) = (1 − |u|²)/2 and use the
    identity quaternion.  The frontend never has to branch on presence.

    Missing nodes — or ``positions is None`` — fall back to the origin
    with scale = 0.5 (the conformal factor at |u| = 0) so a force layout
    can still run on patches that lack real geometry.
    """
    IDENTITY_QUAT = (0.0, 0.0, 0.0, 1.0)

    def _conformal_scale(x: float, y: float, z: float) -> float:
        r2 = x * x + y * y + z * z
        return round(max((1.0 - r2) / 2.0, 1e-6), 6)

    pg_nodes: list[dict] = []
    for n in sorted(nodes):
        entry = positions.get(n) if positions is not None else None

        if entry is None:
            pos = (0.0, 0.0, 0.0)
            quat = IDENTITY_QUAT
            scale = _conformal_scale(*pos)
        elif isinstance(entry, tuple):
            # Legacy 2D layout — no rotation/scale data available.
            pos = entry
            quat = IDENTITY_QUAT
            scale = _conformal_scale(*pos)
        else:
            # Poincaré-projected dict; scale present under normal flow
            # but we recompute defensively if it's missing.
            pos = entry.get("pos", (0.0, 0.0, 0.0))
            quat = entry.get("quat", IDENTITY_QUAT)
            scale = entry.get("scale")
            if scale is None:
                scale = _conformal_scale(*pos)

        pg_nodes.append({
            "id": n,
            "x":  pos[0],  "y":  pos[1],  "z":  pos[2],
            "qx": quat[0], "qy": quat[1], "qz": quat[2], "qw": quat[3],
            "scale": scale,
        })

    # Edges are always undirected {source, target} pairs.  We emit them
    # as dicts (not tuples) so the Haskell FromJSON and the TypeScript
    # interface can share the same wire format.
    pg_edges = [
        {"source": int(e[0]), "target": int(e[1])}
        for e in edges
    ]
    return {"pgNodes": pg_nodes, "pgEdges": pg_edges}


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
        _geom_54 = {"edge_crossings": ec, "tile_center": tc, "gram": G}
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
    geom = get_435_geom()
    fc = geom["face_crossings"]
    ap = geom["adj_pairs"]
    groups = {}
    for fi, fj in ap:
        F_a, F_b = fc[fi], fc[fj]
        groups[(fi, fj)] = multi.enumerate_group([F_a, F_b])
    return groups


def compute_435_curvature(patch):
    """Compute 3D edge curvature for ALL edges in the patch.
    Use for BFS/honeycomb patches matching Honeycomb*Curvature.agda."""
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
    Use for Dense patches matching Dense*Curvature.agda / Honeycomb145Curvature.agda."""
    geom = get_435_geom()
    ap = geom["adj_pairs"]
    p = geom["cell_center"]

    patch_centers = {multi._vec_key(mat @ p)
                     for mat in patch["cells"].values()}

    dihedral_groups = _get_dihedral_groups_435()
    identity = np.eye(len(p))

    valences = []
    for fi, fj in ap:
        dih = dihedral_groups[(fi, fj)]
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
#  5b. Per-Cell Curvature Aggregation
# ════════════════════════════════════════════════════════════════════

def compute_435_per_cell_curvature(patch) -> dict[int, float]:
    """Compute average edge curvature κ for EACH cell in the patch."""
    geom = get_435_geom()
    ap = geom["adj_pairs"]
    p = geom["cell_center"]

    patch_centers = {multi._vec_key(mat @ p)
                     for mat in patch["cells"].values()}

    dihedral_groups = _get_dihedral_groups_435()

    cell_curvatures: dict[int, float] = {}

    for cell_id, g in patch["cells"].items():
        kappa_sum = 0
        for fi, fj in ap:
            dih = dihedral_groups[(fi, fj)]
            orbit_keys = frozenset(
                multi._vec_key(g @ d @ p) for d in dih
            )
            in_patch = sum(1 for k in orbit_keys if k in patch_centers)
            kappa_sum += 20 - 5 * in_patch

        avg_kappa = kappa_sum / (len(ap) * 20)
        cell_curvatures[cell_id] = round(avg_kappa, 6)

    return cell_curvatures


# ── 2D per-tile curvature (hardcoded from known vertex classes) ────

_FILLED_CELL_CURVATURE: dict[int, float] = {
    0: -0.08,   # N0
    1:  0.0,    # G1
    2: -0.08,   # N1
    3:  0.0,    # G2
    4: -0.08,   # N2
    5:  0.0,    # G3
    6: -0.08,   # N3
    7:  0.0,    # G4
    8: -0.08,   # N4
    9:  0.0,    # G0
}

_DESITTER_CELL_CURVATURE: dict[int, float] = {
    0: 0.04,    # N0
    1: 0.04,    # N1
    2: 0.04,    # N2
    3: 0.04,    # N3
    4: 0.04,    # N4
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
    # Tree: 7 nodes (L1=0, L2=1, R1=2, R2=3, A=4, B=5, Root=6)
    # 6 edges: L1-A, L2-A, A-Root, Root-B, B-R1, B-R2
    tree_pos: dict[int, tuple[float, float, float]] = {
        6: (0.0, 0.0, 0.0),       # Root
        4: (-0.4, 0.0, 0.0),      # A
        5: (0.4, 0.0, 0.0),       # B
        0: (-0.7, 0.25, 0.0),     # L1
        1: (-0.7, -0.25, 0.0),    # L2
        2: (0.7, 0.25, 0.0),      # R1
        3: (0.7, -0.25, 0.0),     # R2
    }
    regions = []
    for i, (cells, s) in enumerate([
        ([0], 1), ([1], 1), ([2], 1), ([3], 1),
        ([0, 1], 2), ([1, 2], 2), ([2, 3], 2), ([3, 0], 2),
    ]):
        area = 5 * len(cells)
        regions.append(region_to_json(
            i, cells, len(cells), s, area, f"mc{s}", area - 2 * s))

    graph = _make_patch_graph(
        list(range(7)),
        [[0, 4], [1, 4], [4, 6], [6, 5], [5, 2], [5, 3]],
        tree_pos,
    )

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
        "patchGraph": graph,
    }


def build_star_patch_json() -> dict:
    # Star: 6 tiles — N0=0, N1=1, N2=2, N3=3, N4=4, C=5
    # 5 bonds: C–N0, C–N1, C–N2, C–N3, C–N4
    FACES_PER_TILE = 5
    star_pos = _regular_polygon_positions(5, 5, [0, 1, 2, 3, 4], radius=0.5)
    regions = []
    names = ["N0", "N1", "N2", "N3", "N4",
             "N0N1", "N1N2", "N2N3", "N3N4", "N4N0"]
    for i, (name, s) in enumerate(zip(names, [1]*5 + [2]*5)):
        ncells = 1 if i < 5 else 2
        cells = [i] if i < 5 else [i - 5, (i - 4) % 5]
        area = FACES_PER_TILE * ncells
        regions.append(region_to_json(
            i, cells, ncells, s, area, f"mc{s}", area - 2*s))

    graph = _make_patch_graph(
        list(range(6)),
        [[i, 5] for i in range(5)],
        star_pos,
    )

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
        "patchGraph": graph,
    }


def build_filled_patch_json() -> dict:
    # Filled: 11 tiles.
    # Boundary group indices: N0=0, G1=1, N1=2, G2=3, N2=4,
    #                         G3=5, N3=6, G4=7, N4=8, G0=9
    # Central tile C = 10 (not in any boundary region)
    # 15 internal bonds
    patch = cuts.make_filled_patch()
    G_flow, legs, _ = cuts.build_flow_graph(patch, boundary_cap=1)

    BOUNDARY_GROUPS = [
        ("N0", 2), ("G1", 3), ("N1", 2), ("G2", 3), ("N2", 2),
        ("G3", 3), ("N3", 2), ("G4", 3), ("N4", 2), ("G0", 3),
    ]
    N_GROUPS = len(BOUNDARY_GROUPS)

    # 2D layout: C=10 at centre, boundary groups 0–9 on two rings
    filled_pos: dict[int, tuple[float, float, float]] = {10: (0.0, 0.0, 0.0)}
    for i in range(10):
        angle = 2.0 * math.pi * i / 10 - math.pi / 2.0
        r = 0.35 if i % 2 == 0 else 0.55  # N tiles inner, G tiles outer
        filled_pos[i] = (round(r * math.cos(angle), 6),
                         round(r * math.sin(angle), 6), 0.0)

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
            internal_within = length - 1
            area = 5 * length - 2 * internal_within
            curv = _region_avg_curvature(tiles, _FILLED_CELL_CURVATURE)
            regions.append(region_to_json(
                rid, tiles, length, s, area, f"mc{s}", area - 2*s,
                curvature=curv))
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

    # Filled patch graph: 11 nodes (boundary groups 0-9 + C=10), 15 edges
    # C–Ni bonds (C=10, N indices are 0,2,4,6,8)
    # Gi–N bonds (G indices are 1,3,5,7,9)
    filled_edges = [
        [10, 0], [10, 2], [10, 4], [10, 6], [10, 8],   # C–N0..N4
        [1, 0], [1, 2],                                  # G1–N0, G1–N1
        [3, 2], [3, 4],                                  # G2–N1, G2–N2
        [5, 4], [5, 6],                                  # G3–N2, G3–N3
        [7, 6], [7, 8],                                  # G4–N3, G4–N4
        [9, 8], [9, 0],                                  # G0–N4, G0–N0
    ]
    graph = _make_patch_graph(list(range(11)), filled_edges, filled_pos)

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
        "patchGraph": graph,
    }


def _graph_from_435_patch(patch: dict) -> dict:
    """Extract patchGraph from a {4,3,5} patch dict."""
    geom = get_435_geom()
    positions = poincare_project(
        geom["gram"], patch["cells"], geom["cell_center"])
    return _make_patch_graph(
        sorted(patch["cells"].keys()),
        [[c1, c2] for c1, c2 in patch["internal_faces"]],
        positions,
    )


def _graph_from_54_patch(patch: dict) -> dict:
    """Extract patchGraph from a {5,4} layer patch dict."""
    geom = get_54_geom()
    positions = poincare_project(
        geom["gram"], patch["tiles"], geom["tile_center"])
    return _make_patch_graph(
        sorted(patch["tiles"].keys()),
        [[t1, t2] for t1, t2 in patch["internal_bonds"]],
        positions,
    )

def _regular_polygon_positions(
    n: int, center_id: int, petal_ids: list[int], radius: float = 0.5,
) -> dict[int, tuple[float, float, float]]:
    """Simple 2D regular-polygon layout for small hand-built patches."""
    positions: dict[int, tuple[float, float, float]] = {
        center_id: (0.0, 0.0, 0.0)
    }
    for i, pid in enumerate(petal_ids):
        angle = 2.0 * math.pi * i / n - math.pi / 2.0
        positions[pid] = (
            round(radius * math.cos(angle), 6),
            round(radius * math.sin(angle), 6),
            0.0,
        )
    return positions


def build_435_dense_json(max_cells, name, max_rc=5) -> dict:
    """Build a {4,3,5} Dense patch and export as JSON.
    Curvature: central cell's 12 edges only."""
    geom = get_435_geom()
    patch = multi.build_patch_dense(
        geom["face_crossings"], geom["cell_center"],
        max_cells, name=name)

    regions_data = analyze_435_patch(patch, max_rc)
    cell_curv = compute_435_per_cell_curvature(patch)

    n_cells = len(patch["cells"])
    n_int = len(patch["internal_faces"])
    n_bdy = patch["n_boundary_faces"]
    orbits = len(set(r["orbit"] for r in regions_data))
    max_s = max(r["mincut"] for r in regions_data) if regions_data else 0

    region_json = [
        region_to_json(i, r["cells"], r["size"], r["mincut"],
                       r["area"], r["orbit"], r["half_slack"],
                       curvature=_region_avg_curvature(r["cells"], cell_curv))
        for i, r in enumerate(regions_data)
    ]

    curv = compute_435_central_curvature(patch)
    graph = _graph_from_435_patch(patch)

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
        "patchGraph": graph,
    }


def build_435_bfs_json(max_cells, name, max_rc=5) -> dict:
    """Build a {4,3,5} BFS patch (honeycomb) and export as JSON.
    Curvature: ALL edges in the patch."""
    geom = get_435_geom()
    patch = multi.build_patch(
        geom["face_crossings"], geom["cell_center"],
        max_cells, name=name)

    regions_data = analyze_435_patch(patch, max_rc=max_rc)
    cell_curv = compute_435_per_cell_curvature(patch)

    n_cells = len(patch["cells"])
    n_int = len(patch["internal_faces"])
    n_bdy = patch["n_boundary_faces"]
    orbits = len(set(r["orbit"] for r in regions_data))
    max_s = max(r["mincut"] for r in regions_data) if regions_data else 0

    region_json = [
        region_to_json(i, r["cells"], r["size"], r["mincut"],
                       r["area"], r["orbit"], r["half_slack"],
                       curvature=_region_avg_curvature(r["cells"], cell_curv))
        for i, r in enumerate(regions_data)
    ]

    curv = compute_435_curvature(patch)
    graph = _graph_from_435_patch(patch)

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
        "patchGraph": graph,
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

    graph = _graph_from_54_patch(patch)

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
        "patchGraph": graph,
    }


def build_desitter_patch_json() -> dict:
    # De Sitter: same star topology as {5,4} star
    # 6 tiles: N0=0, N1=1, N2=2, N3=3, N4=4, C=5
    # 5 bonds: C–Ni
    FACES_PER_TILE = 5
    ds_pos = _regular_polygon_positions(5, 5, [0, 1, 2, 3, 4], radius=0.5)
    regions = []
    names = ["N0", "N1", "N2", "N3", "N4",
             "N0N1", "N1N2", "N2N3", "N3N4", "N4N0"]
    for i, (name, s) in enumerate(zip(names, [1]*5 + [2]*5)):
        ncells = 1 if i < 5 else 2
        cells = [i] if i < 5 else [i - 5, (i - 4) % 5]
        area = FACES_PER_TILE * ncells
        curv = _region_avg_curvature(cells, _DESITTER_CELL_CURVATURE)
        regions.append(region_to_json(
            i, cells, ncells, s, area, f"mc{s}", area - 2*s,
            curvature=curv))

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

    graph = _make_patch_graph(
        list(range(6)),
        [[i, 5] for i in range(5)],
        ds_pos,
    )

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
        "patchGraph": graph,
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
        {"tlPatchName": "honeycomb-145", "tlRegions": 1008, "tlOrbits": 9,
         "tlMaxCut": 9, "tlMonotone": [0, "refl"],
         "tlHasBridge": True, "tlHasAreaLaw": False, "tlHasHalfBound": False},
        {"tlPatchName": "dense-1000", "tlRegions": 10317, "tlOrbits": 9,
         "tlMaxCut": 9, "tlMonotone": [0, "refl"],
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
    """Derive curvature.json from per-patch data."""
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
        ("honeycomb-3d",  lambda: build_435_bfs_json(7, "honeycomb-3d", 1)),
        ("honeycomb-145", lambda: build_435_dense_json(145, "honeycomb-145", 5)),
        ("dense-50",      lambda: build_435_dense_json(50, "dense-50")),
        ("dense-100",     lambda: build_435_dense_json(100, "dense-100")),
        ("dense-200",     lambda: build_435_dense_json(200, "dense-200")),
        ("dense-1000",    lambda: build_435_dense_json(1000, "dense-1000", 6)),
        ("desitter",      build_desitter_patch_json),
    ]
    for d in [2, 3, 4, 5, 6, 7]:
        depth = d
        patch_builders.append(
            (f"layer-54-d{d}", lambda d=depth: build_layer54_json(d)))

    print(f"\n  ── Generating {len(patch_builders)} patch files ──\n")

    all_patch_data: dict[str, dict] = {}

    for name, builder in patch_builders:
        print(f"    {name} ...", end="", flush=True)
        t1 = time.time()
        data = builder()

        data["patchHalfBoundVerified"] = name in AGDA_VERIFIED_HALF_BOUND

        all_patch_data[name] = data
        content = write_json(patches_dir / f"{name}.json", data, args.dry_run)
        hasher.update(content.encode())
        nr = data["patchRegions"]
        ng = len(data.get("patchGraph", {}).get("pgNodes", []))
        ne = len(data.get("patchGraph", {}).get("pgEdges", []))
        verified = " [Agda ✓]" if data["patchHalfBoundVerified"] else ""
        print(f"  {nr} regions, graph {ng}n/{ne}e{verified}"
              f"  ({time.time()-t1:.1f}s)")

    # ── Tower ───────────────────────────────────────────────────────
    print(f"\n  ── Tower, theorems, curvature, meta ──\n")

    tower = build_tower_json()
    content = write_json(out / "tower.json", tower, args.dry_run)
    hasher.update(content.encode())

    theorems = build_theorems_json()
    content = write_json(out / "theorems.json", theorems, args.dry_run)
    hasher.update(content.encode())

    curv_summaries = build_curvature_summaries(all_patch_data)
    content = write_json(out / "curvature.json", curv_summaries, args.dry_run)
    hasher.update(content.encode())

    data_hash = hasher.hexdigest()[:16]
    meta = build_meta_json(data_hash)
    write_json(out / "meta.json", meta, args.dry_run)

    # ── Summary ─────────────────────────────────────────────────────
    elapsed = time.time() - t0
    n_files = len(patch_builders) + 4
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
    print(f"\n  Each patch now includes patchGraph with pgNodes + pgEdges")
    print(f"  for the full bulk graph (all cells + all physical bonds).")
    print(f"\n  The Haskell backend reads from this directory at startup.")
    print(f"  See docs/engineering/backend-spec-haskell.md §4.\n")


if __name__ == "__main__":
    main()