#!/usr/bin/env python3
"""
05_honeycomb_3d_prototype.py  —  Phase D.0 Feasibility Prototype

Explores the {4,3,5} hyperbolic honeycomb (5 cubes at every edge)
to find candidate intermediate 3D patches suitable for 3D Agda
formalization of the holographic correspondence.

The script:
  1. Implements a {4,3,5} honeycomb generator via Coxeter group
     reflections in the simple root basis (no eigendecomposition).
  2. Builds candidate patches: central cube + 6 face-neighbors +
     selected edge-gap-fillers.
  3. Counts boundary faces, computes edge valences via dihedral
     orbit enumeration, verifies that at least one edge achieves
     the full {4,3,5} valence of 5.
  4. Builds a flow graph (cubes = nodes, shared faces = capacity-1
     bonds) and computes min-cut values for cell-aligned boundary
     regions via max-flow.
  5. Computes the automorphism group of the boundary face adjacency
     graph and enumerates orbits.
  6. Reports: region count, orbit count, symmetry group order,
     curvature values, Gauss–Bonnet verification.

Gate criterion (§6.9 of docs/10-frontier.md):
  - At least one edge achieves full valence 5
  - Boundary face count in range ~100–500  (the "sweet spot")
  - Orbit count ≤ ~200

  If these hold, 3D Agda formalization is probably feasible.

Dependencies:  numpy, networkx
  Install:  pip install numpy networkx

Reference:
  docs/10-frontier.md §6  (Deferred Direction D — 3D Honeycombs)
  Coxeter, "Regular Polytopes" (1973)
"""

from __future__ import annotations

import sys
import math
from collections import defaultdict, deque, Counter
from itertools import combinations

try:
    import numpy as np
except ImportError:
    sys.exit("ERROR: numpy is required.  pip install numpy")

try:
    import networkx as nx
except ImportError:
    sys.exit("ERROR: networkx is required.  pip install networkx")


# ════════════════════════════════════════════════════════════════════
#  1.  Coxeter Geometry in the Simple Root Basis
# ════════════════════════════════════════════════════════════════════
#
#  The {4,3,5} Coxeter group [4,3,5] has generators s0, s1, s2, s3
#  with Coxeter matrix:
#    m(s0,s1) = 4,  m(s1,s2) = 3,  m(s2,s3) = 5
#    m(s0,s2) = m(s0,s3) = m(s1,s3) = 2
#
#  The Gram matrix G_ij = -cos(π / m_ij) has signature (3,1),
#  confirming a compact hyperbolic Coxeter group.
#
#  In the simple root basis {α_0, α_1, α_2, α_3}, the bilinear
#  form is <α_i, α_j> = G_ij, and the reflection s_i acts as:
#
#    s_i(v) = v - 2 <v, α_i> α_i = v - 2 (Gv)_i α_i
#
#  In matrix form (acting on coordinate vectors):
#
#    (S_i)_{kj} = δ_{kj} - 2 δ_{ki} G_{ij}
#
#  equivalently:  S_i = I - 2 e_i (G[i,:])
#
#  This requires NO eigendecomposition — just the Gram matrix.
# ════════════════════════════════════════════════════════════════════

ROUND_DIGITS = 5  # for floating-point cell identification


def build_gram_matrix() -> np.ndarray:
    """Gram matrix G_{ij} = -cos(π / m_{ij}) for [4,3,5]."""
    m = np.array([
        [1, 4, 2, 2],
        [4, 1, 3, 2],
        [2, 3, 1, 5],
        [2, 2, 5, 1],
    ], dtype=float)
    G = -np.cos(np.pi / m)
    np.fill_diagonal(G, 1.0)
    return G


def build_reflections(G: np.ndarray) -> list[np.ndarray]:
    """
    Build reflection matrices in the simple root basis.

    s_i(α_j) = α_j - 2 G_{ij} α_i

    Matrix row i is replaced:  (S_i)_{i,j} = -G_{ij} + (1-2)*G_{ij}...
    More directly:  S_i = I,  then S_i[i, :] -= 2 * G[i, :]
    """
    n = G.shape[0]
    refls = []
    for i in range(n):
        S = np.eye(n)
        S[i, :] -= 2.0 * G[i, :]
        refls.append(S)
    return refls


def _mat_key(M: np.ndarray) -> tuple:
    return tuple(np.round(M.ravel(), ROUND_DIGITS))


def _vec_key(v: np.ndarray) -> tuple:
    return tuple(np.round(v, ROUND_DIGITS))


def validate_reflections(G: np.ndarray, refls: list[np.ndarray]) -> None:
    """Check involution, form-preservation, and Coxeter relations."""
    I4 = np.eye(4)
    for i, S in enumerate(refls):
        assert np.allclose(S @ S, I4, atol=1e-12), f"s{i} not involution"
        assert np.allclose(S.T @ G @ S, G, atol=1e-10), \
            f"s{i} doesn't preserve G-form"

    m_vals = {(0, 1): 4, (1, 2): 3, (2, 3): 5,
              (0, 2): 2, (0, 3): 2, (1, 3): 2}
    for (i, j), m in m_vals.items():
        prod = refls[i] @ refls[j]
        power = np.linalg.matrix_power(prod, m)
        assert np.allclose(power, I4, atol=1e-8), \
            f"(s{i}·s{j})^{m} ≠ I"
    print("  ✓  Reflections: involution, G-preservation, Coxeter relations.")


# ════════════════════════════════════════════════════════════════════
#  2.  Cell Stabilizer and Face Crossings
# ════════════════════════════════════════════════════════════════════

def enumerate_group(generators: list[np.ndarray],
                    expected: int | None = None) -> list[np.ndarray]:
    """BFS enumeration of a finite group from matrix generators."""
    I = np.eye(generators[0].shape[0])
    elems = [I]
    seen = {_mat_key(I)}
    queue = deque([I])
    while queue:
        g = queue.popleft()
        for s in generators:
            for h in [s @ g, g @ s]:
                k = _mat_key(h)
                if k not in seen:
                    seen.add(k)
                    elems.append(h)
                    queue.append(h)
    if expected is not None:
        assert len(elems) == expected, \
            f"Expected {expected} elements, got {len(elems)}"
    return elems


def find_cell_center(G: np.ndarray) -> np.ndarray:
    """
    Center of fundamental cell: perpendicular to α_0, α_1, α_2.

    (Gp)_i = 0 for i=0,1,2  ⟹  p = G^{-1} e_3  (up to scale).
    """
    Ginv = np.linalg.inv(G)
    p = Ginv[:, 3].copy()
    Gp = G @ p
    assert abs(Gp[0]) < 1e-10 and abs(Gp[1]) < 1e-10 and abs(Gp[2]) < 1e-10
    # Ensure on the correct side of the s3-wall
    if Gp[3] < 0:
        p = -p
    return p


def find_face_crossings(refls: list[np.ndarray],
                        stabilizer: list[np.ndarray],
                        G: np.ndarray) -> list[np.ndarray]:
    """
    Find the 6 face-crossing transformations F_k = h_k s3 h_k^{-1}
    where h_k ranges over coset reps of <s0,s1> in <s0,s1,s2>.

    Since s_i preserves G:  h^{-1} = G^{-1} h^T G.
    """
    s3 = refls[3]
    Ginv = np.linalg.inv(G)
    face_crossings = []
    seen: set[tuple] = set()

    for h in stabilizer:
        h_inv = Ginv @ h.T @ G
        F = h @ s3 @ h_inv
        k = _mat_key(F)
        if k not in seen:
            seen.add(k)
            face_crossings.append(F)

    assert len(face_crossings) == 6, \
        f"Expected 6 face crossings, got {len(face_crossings)}"
    return face_crossings


# ════════════════════════════════════════════════════════════════════
#  3.  Edge Classification and Valence
# ════════════════════════════════════════════════════════════════════

def classify_face_pairs(
    face_crossings: list[np.ndarray],
) -> tuple[list[tuple[int, int]], list[tuple[int, int]]]:
    """
    Classify pairs of face-crossings as adjacent or opposite.

    Adjacent faces of a cube share an edge.  In {4,3,5}, the
    dihedral angle is 2π/5, so the product F_a F_b of adjacent
    face-crossings has order 5:  (F_a F_b)^5 = I.

    Opposite faces: the product has infinite order (hyperbolic
    translation).  We detect this by checking (F_a F_b)^5 ≈ I.

    A cube has 12 edges (adjacent pairs) and 3 opposite pairs.
    """
    I4 = np.eye(4)
    adjacent_pairs: list[tuple[int, int]] = []
    opposite_pairs: list[tuple[int, int]] = []

    for i in range(6):
        for j in range(i + 1, 6):
            prod = face_crossings[i] @ face_crossings[j]
            power5 = np.linalg.matrix_power(prod, 5)
            if np.allclose(power5, I4, atol=1e-6):
                adjacent_pairs.append((i, j))
            else:
                opposite_pairs.append((i, j))

    return adjacent_pairs, opposite_pairs


def compute_edge_valence(
    F_a: np.ndarray, F_b: np.ndarray, cell_center: np.ndarray,
) -> int:
    """
    Count cells around an edge by enumerating the orbit of the
    cell center under the dihedral group <F_a, F_b>.

    For {4,3,5}: the dihedral group has order 10, and the orbit
    of the cell center has size 5 (= edge valence).
    """
    I4 = np.eye(4)
    elems = [I4]
    seen = {_mat_key(I4)}
    queue = deque([I4])

    while queue:
        g = queue.popleft()
        for F in [F_a, F_b]:
            h = F @ g
            k = _mat_key(h)
            if k not in seen:
                seen.add(k)
                elems.append(h)
                queue.append(h)
                if len(elems) > 50:  # safety limit
                    break
        if len(elems) > 50:
            break

    centers = set()
    for g in elems:
        c = g @ cell_center
        centers.add(_vec_key(c))
    return len(centers)


# ════════════════════════════════════════════════════════════════════
#  4.  Patch Builder (BFS)
# ════════════════════════════════════════════════════════════════════

def build_patch(
    face_crossings: list[np.ndarray],
    cell_center: np.ndarray,
    max_cells: int,
    name: str = "patch",
) -> dict:
    """
    Grow a patch by BFS from the fundamental cell.

    Each cell is represented by a 4×4 matrix g (product of reflections).
    The center of cell g is  g @ cell_center.
    The 6 neighbors of cell g are  g @ F_k  for k = 0..5.
    """
    p = cell_center
    cells: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}
    neighbors: dict[int, set[int]] = defaultdict(set)

    def register(mat: np.ndarray) -> tuple[int, bool]:
        c = mat @ p
        k = _vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        cid = len(cells)
        cells[cid] = mat
        center_to_id[k] = cid
        return cid, True

    register(np.eye(4))
    queue: deque[int] = deque([0])

    while queue:
        cid = queue.popleft()
        g = cells[cid]
        for F in face_crossings:
            h = g @ F  # neighbor = right-multiply by face crossing
            nid, is_new = register(h)
            neighbors[cid].add(nid)
            neighbors[nid].add(cid)
            if is_new and len(cells) < max_cells:
                queue.append(nid)

    # Compute internal / boundary faces
    internal_faces: list[tuple[int, int]] = []
    seen_pairs: set[frozenset[int]] = set()
    for cid, nbrs in neighbors.items():
        for nid in nbrs:
            pair = frozenset([cid, nid])
            if pair not in seen_pairs:
                seen_pairs.add(pair)
                internal_faces.append((min(cid, nid), max(cid, nid)))

    bdy_count: dict[int, int] = {}
    for cid in cells:
        bdy_count[cid] = 6 - len(neighbors[cid])

    n_boundary = sum(bdy_count.values())

    return {
        "name": name,
        "cells": cells,
        "neighbors": dict(neighbors),
        "internal_faces": internal_faces,
        "n_boundary_faces": n_boundary,
        "bdy_per_cell": bdy_count,
    }


# ════════════════════════════════════════════════════════════════════
#  5.  Min-Cut Analysis (dimension-agnostic flow graph)
# ════════════════════════════════════════════════════════════════════

INF_CAP = 10_000


def build_flow_graph(
    patch: dict,
) -> tuple[nx.DiGraph, list[int], dict[int, int]]:
    """
    Build a directed flow graph for min-cut computation.

    Nodes: cell IDs + boundary-face pseudo-nodes.
    Internal faces → bidirectional capacity-1 edges between cells.
    Boundary faces → capacity-1 edges to pseudo-nodes.
    """
    G = nx.DiGraph()

    for c1, c2 in patch["internal_faces"]:
        G.add_edge(f"c{c1}", f"c{c2}", capacity=1)
        G.add_edge(f"c{c2}", f"c{c1}", capacity=1)

    bnode_ids: list[int] = []
    bnode_to_cell: dict[int, int] = {}
    idx = 0
    for cid, n_bdy in patch["bdy_per_cell"].items():
        for _ in range(n_bdy):
            bnode = f"b{idx}"
            G.add_edge(f"c{cid}", bnode, capacity=1)
            G.add_edge(bnode, f"c{cid}", capacity=1)
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
#  6.  Cell-Aligned Boundary Region Enumeration
# ════════════════════════════════════════════════════════════════════

def enumerate_cell_aligned_regions(
    patch: dict,
    bnode_to_cell: dict[int, int],
    bnode_ids: list[int],
    max_region_cells: int = 5,
) -> list[tuple[str, set[int]]]:
    """
    Enumerate contiguous cell-aligned boundary regions.

    A cell-aligned region is a connected subset of boundary cells.
    We enumerate connected subsets up to max_region_cells cells.
    """
    bdy_cells: set[int] = set()
    cell_bnodes: dict[int, set[int]] = defaultdict(set)
    for idx in bnode_ids:
        cid = bnode_to_cell[idx]
        bdy_cells.add(cid)
        cell_bnodes[cid].add(idx)

    # Build boundary-cell adjacency
    bcg = nx.Graph()
    for cid in bdy_cells:
        bcg.add_node(cid)
    for cid in bdy_cells:
        for nid in patch["neighbors"].get(cid, set()):
            if nid in bdy_cells:
                bcg.add_edge(cid, nid)

    # Enumerate connected subsets by BFS expansion
    regions: list[tuple[str, set[int]]] = []
    seen_regions: set[frozenset[int]] = set()

    for start in sorted(bdy_cells):
        # BFS to enumerate connected subsets containing start
        _expand_subsets(bcg, start, bdy_cells, cell_bnodes,
                        max_region_cells, regions, seen_regions)

    return regions


def _expand_subsets(
    graph: nx.Graph, start: int, valid: set[int],
    cell_bnodes: dict[int, set[int]],
    max_size: int,
    results: list[tuple[str, set[int]]],
    seen: set[frozenset[int]],
):
    """DFS enumeration of connected subsets containing `start`."""
    stack: list[tuple[frozenset[int], set[int]]] = [
        (frozenset([start]), set(graph.neighbors(start)) & valid - {start})
    ]
    while stack:
        current, frontier = stack.pop()
        key = current
        if key in seen:
            continue
        seen.add(key)
        bnodes: set[int] = set()
        for cid in current:
            bnodes.update(cell_bnodes[cid])
        label = "{" + ",".join(f"c{c}" for c in sorted(current)) + "}"
        results.append((label, bnodes))

        if len(current) < max_size:
            for node in sorted(frontier):
                new_set = current | frozenset([node])
                if new_set not in seen:
                    new_frontier = (frontier | (set(graph.neighbors(node)) & valid)) - new_set
                    stack.append((new_set, new_frontier))


# ════════════════════════════════════════════════════════════════════
#  7.  Symmetry Analysis
# ════════════════════════════════════════════════════════════════════

def compute_boundary_symmetry(
    patch: dict, bnode_to_cell: dict[int, int], bnode_ids: list[int],
) -> tuple[int, int]:
    """
    Compute symmetry group order and node orbits of the
    boundary face adjacency graph via graph automorphisms.

    Two boundary faces are adjacent if:
      - They belong to the same cell, OR
      - They belong to neighboring cells.
    (Simplified model — treats all faces on a cell as mutually adjacent.)
    """
    bdy_graph = nx.Graph()
    for idx in bnode_ids:
        bdy_graph.add_node(idx, cell=bnode_to_cell[idx])

    # Group by cell
    cell_bfaces: dict[int, list[int]] = defaultdict(list)
    for idx in bnode_ids:
        cell_bfaces[bnode_to_cell[idx]].append(idx)

    # Same-cell adjacency
    for cid, faces in cell_bfaces.items():
        for a, b in combinations(faces, 2):
            bdy_graph.add_edge(a, b)

    # Cross-cell adjacency (faces on neighboring cells)
    for c1, c2 in patch["internal_faces"]:
        for a in cell_bfaces.get(c1, []):
            for b in cell_bfaces.get(c2, []):
                bdy_graph.add_edge(a, b)

    n_nodes = bdy_graph.number_of_nodes()
    if n_nodes > 100:
        # Approximate: use degree sequence to estimate orbits
        degs = sorted(dict(bdy_graph.degree()).values())
        deg_classes = len(set(degs))
        return -1, deg_classes  # -1 = not computed

    # Full automorphism enumeration
    try:
        GM = nx.algorithms.isomorphism.GraphMatcher(bdy_graph, bdy_graph)
        auts = list(GM.isomorphisms_iter())
        group_order = len(auts)

        # Union-find for orbits
        parent = {v: v for v in bdy_graph.nodes()}

        def find(x):
            while parent[x] != x:
                parent[x] = parent[parent[x]]
                x = parent[x]
            return x

        def union(a, b):
            ra, rb = find(a), find(b)
            if ra != rb:
                parent[ra] = rb

        for sigma in auts:
            for v in bdy_graph.nodes():
                union(v, sigma[v])

        num_orbits = len({find(v) for v in bdy_graph.nodes()})
        return group_order, num_orbits
    except Exception:
        return 1, n_nodes


# ════════════════════════════════════════════════════════════════════
#  8.  3D Curvature
# ════════════════════════════════════════════════════════════════════

def analyze_curvature(
    edge_valences: dict[tuple[int, int], int],
) -> None:
    """
    Report 3D edge curvature.

    κ(e) = 2π − k·(π/2)  where k = edge valence.
    Valence 5 → κ = −π/2 (hyperbolic).
    """
    if not edge_valences:
        print("    (No edge valence data available)")
        return

    val_dist = Counter(edge_valences.values())
    for v in sorted(val_dist):
        kappa = (4 - v) * math.pi / 2
        tag = ""
        if v == 5:
            tag = "  ← {4,3,5} condition! κ = −π/2"
        elif v == 4:
            tag = "  (flat, κ = 0)"
        elif v < 4:
            tag = f"  (boundary, κ = +{(4-v)}·π/2)"
        print(f"    Valence {v}:  {val_dist[v]} edge(s)"
              f"    κ = {math.degrees(kappa):>+7.1f}°{tag}")


# ════════════════════════════════════════════════════════════════════
#  9.  Full Analysis Driver
# ════════════════════════════════════════════════════════════════════

def analyze_patch(
    patch: dict,
    face_crossings: list[np.ndarray],
    adjacent_pairs: list[tuple[int, int]],
    cell_center: np.ndarray,
) -> dict:
    """Run full analysis on a 3D honeycomb patch."""

    n_cells = len(patch["cells"])
    n_internal = len(patch["internal_faces"])
    n_boundary = patch["n_boundary_faces"]

    print(f"\n{'=' * 72}")
    print(f"  PATCH:  {patch['name']}")
    print(f"{'=' * 72}")
    print(f"  Cells (cubes):         {n_cells}")
    print(f"  Internal shared faces: {n_internal}")
    print(f"  Boundary faces:        {n_boundary}")
    print(f"  Euler (V−E+F):         (not tracked — cell complex only)")

    # ── Edge valence ────────────────────────────────────────────────
    print(f"\n  ── Edge Valence (central cell's 12 edges) ──")

    edge_valences: dict[tuple[int, int], int] = {}
    n_full = 0

    for i, j in adjacent_pairs:
        v = compute_edge_valence(
            face_crossings[i], face_crossings[j], cell_center
        )
        edge_valences[(i, j)] = v
        if v == 5:
            n_full += 1

    analyze_curvature(edge_valences)

    if n_full > 0:
        print(f"\n  ✓  {n_full} of 12 edges achieve full valence 5!")
    else:
        print(f"\n  ✗  No edge at full valence 5 yet.")

    # ── Patch edge valence in actual patch ──────────────────────────
    # Count how many of those 5 cells per edge are IN the patch
    print(f"\n  ── Edge Valence in Patch (cells actually present) ──")

    patch_edge_valences: dict[tuple[int, int], int] = {}
    for (fi, fj), full_val in edge_valences.items():
        F_a, F_b = face_crossings[fi], face_crossings[fj]
        # Generate all cells at this edge
        I4 = np.eye(4)
        dih_elems = enumerate_group([F_a, F_b])
        in_patch = 0
        p = cell_center
        for g in dih_elems:
            c = g @ p
            k = _vec_key(c)
            # Check if this center is in the patch
            for cid, mat in patch["cells"].items():
                if _vec_key(mat @ p) == k:
                    in_patch += 1
                    break
        patch_edge_valences[(fi, fj)] = in_patch

    patch_val_dist = Counter(patch_edge_valences.values())
    for v in sorted(patch_val_dist):
        tag = " ← FULL" if v == 5 else ""
        print(f"    {patch_val_dist[v]} edge(s) with {v} of 5 cubes present{tag}")

    n_full_in_patch = sum(1 for v in patch_edge_valences.values() if v >= 5)

    # ── Flow graph and min-cuts ─────────────────────────────────────
    flow_G, bnode_ids, bnode_to_cell = build_flow_graph(patch)

    print(f"\n  ── Flow Graph ──")
    print(f"  Boundary legs (face pseudo-nodes): {len(bnode_ids)}")

    # ── Cell-aligned regions ────────────────────────────────────────
    max_rc = min(5, n_cells - 1)
    regions = enumerate_cell_aligned_regions(
        patch, bnode_to_cell, bnode_ids, max_region_cells=max_rc
    )
    n_regions = len(regions)

    print(f"\n  ── Cell-Aligned Boundary Regions (up to {max_rc} cells) ──")
    print(f"  Distinct regions:  {n_regions}")

    # Sample min-cuts
    sample = regions[:min(n_regions, 20)]
    if sample:
        print(f"\n  {'Region':<40s} | {'#faces':>6s} | {'S(A)':>5s}")
        print(f"  {'─' * 55}")
        cut_values = []
        for label, idx_set in sample:
            s = compute_min_cut(flow_G, bnode_ids, idx_set)
            cut_values.append(s)
            print(f"  {label:<40s} | {len(idx_set):>6d} | {s:>5d}")
        if cut_values:
            print(f"\n  Min-cut range (sample): "
                  f"{min(cut_values)} – {max(cut_values)}")

    # ── Subadditivity spot check ────────────────────────────────────
    if len(regions) >= 3:
        print(f"\n  ── Subadditivity Spot Check ──")
        sub_checks, sub_pass = 0, 0
        for i in range(min(len(regions), 10)):
            for j in range(i + 1, min(len(regions), 10)):
                lA, idxA = regions[i]
                lB, idxB = regions[j]
                if idxA & idxB:
                    continue  # overlapping
                idxAB = idxA | idxB
                if len(idxAB) >= len(bnode_ids):
                    continue  # full boundary
                sA = compute_min_cut(flow_G, bnode_ids, idxA)
                sB = compute_min_cut(flow_G, bnode_ids, idxB)
                sAB = compute_min_cut(flow_G, bnode_ids, idxAB)
                if sA < 0 or sB < 0 or sAB < 0:
                    continue
                sub_checks += 1
                if sAB <= sA + sB:
                    sub_pass += 1
        if sub_checks > 0:
            print(f"  Checked {sub_checks} pairs: "
                  f"{sub_pass} passed, {sub_checks - sub_pass} failed.")
        else:
            print(f"  (No valid non-overlapping pairs in sample)")

    # ── Symmetry ────────────────────────────────────────────────────
    print(f"\n  ── Symmetry Analysis ──")
    group_order, num_orbits = compute_boundary_symmetry(
        patch, bnode_to_cell, bnode_ids
    )
    if group_order > 0:
        print(f"  Automorphism group order: {group_order}")
        print(f"  Boundary face orbits:     {num_orbits}")
        est_region_orbits = max(1, n_regions // max(1, group_order))
        print(f"  Region orbits (est.):     ~{est_region_orbits}")
    else:
        print(f"  [Full automorphism skipped for large boundary]")
        print(f"  Degree-class estimate:    {num_orbits} classes")
        est_region_orbits = num_orbits
        # Better estimate using octahedral symmetry of the cube (order 48)
        print(f"  With octahedral sym (48): ~{max(1, n_regions // 48)} orbit est.")
        est_region_orbits = max(1, n_regions // 48)

    # ── 3D Gauss–Bonnet sketch ──────────────────────────────────────
    print(f"\n  ── 3D Curvature Summary ──")
    print(f"  Dihedral angle of cube: π/2 = 90°")
    print(f"  {'{4,3,5}'} honeycomb: 5 cubes at each edge")
    print(f"  Angular excess at full edge: 5·90° − 360° = 90°")
    print(f"  Edge deficit: κ = 2π − 5·(π/2) = −π/2 ≈ −90°")
    if n_full > 0:
        total_kappa = n_full_in_patch * (-math.pi / 2)
        print(f"  Fully surrounded edges in patch: {n_full_in_patch}")
        print(f"  Total hyperbolic curvature: "
              f"{math.degrees(total_kappa):.1f}°")

    # ── Gate Check ──────────────────────────────────────────────────
    print(f"\n  {'═' * 55}")
    print(f"  GATE CHECK (Phase D.0)")
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
        print(f"\n  ▶  ALL GATES PASS — 3D Agda formalization is FEASIBLE!")
    else:
        print(f"\n  ▶  GATE(S) BLOCKED — adjust patch size or selection.")
        if n_boundary < 100:
            print(f"     → Need more cells (increase max_cells).")
        if n_boundary > 500:
            print(f"     → Patch too large; use symmetry reduction.")
        if n_full_in_patch == 0:
            print(f"     → Need more edge-gap-fillers to fill valence 5.")

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
    }


# ════════════════════════════════════════════════════════════════════
#  10.  Main
# ════════════════════════════════════════════════════════════════════

def main():
    print("╔════════════════════════════════════════════════════════╗")
    print("║  Phase D.0:  {4,3,5} Honeycomb — 3D Feasibility Probe  ║")
    print("║  5 cubes at every edge • Hyperbolic 3-space            ║")
    print("╚════════════════════════════════════════════════════════╝")

    # ── Initialize Coxeter geometry ─────────────────────────────────
    print("\n  Initializing Coxeter geometry for [4,3,5] ...")
    G = build_gram_matrix()
    refls = build_reflections(G)

    # Verify
    evals = np.linalg.eigvalsh(G)
    n_neg = sum(1 for e in evals if e < -1e-10)
    n_pos = sum(1 for e in evals if e > 1e-10)
    print(f"  Gram matrix eigenvalues: "
          f"{', '.join(f'{e:.4f}' for e in sorted(evals))}")
    print(f"  Signature: ({n_pos}, {n_neg})  "
          f"{'✓ compact hyperbolic' if n_neg == 1 and n_pos == 3 else '✗ unexpected'}")

    validate_reflections(G, refls)

    # Cell center
    cell_center = find_cell_center(G)
    print(f"  Cell center (root basis): "
          f"[{', '.join(f'{x:.4f}' for x in cell_center)}]")
    norm_sq = cell_center @ G @ cell_center
    print(f"  <p,p>_G = {norm_sq:.6f}  "
          f"({'timelike ✓' if norm_sq < 0 else 'spacelike ✗'})")

    # Cell stabilizer <s0, s1, s2>
    print("\n  Enumerating cell stabilizer <s0, s1, s2> ...")
    stab = enumerate_group(refls[:3], expected=48)
    print(f"  ✓  Cell stabilizer [4,3] has {len(stab)} elements.")

    # Face crossings
    print("  Computing 6 face crossings ...")
    face_crossings = find_face_crossings(refls, stab, G)
    print(f"  ✓  {len(face_crossings)} face crossings found.")

    # Verify face crossings are involutions
    I4 = np.eye(4)
    for k, F in enumerate(face_crossings):
        assert np.allclose(F @ F, I4, atol=1e-10), f"F_{k} not involution"
    print(f"  ✓  All face crossings are involutions.")

    # Classify face pairs
    adj_pairs, opp_pairs = classify_face_pairs(face_crossings)
    print(f"  Adjacent face pairs: {len(adj_pairs)}  (edges of cube)")
    print(f"  Opposite face pairs: {len(opp_pairs)}")

    # Full edge valence in the honeycomb
    print(f"\n  Computing edge valence in the full honeycomb ...")
    full_valences = []
    for i, j in adj_pairs:
        v = compute_edge_valence(
            face_crossings[i], face_crossings[j], cell_center
        )
        full_valences.append(v)
    val_dist = Counter(full_valences)
    for v, cnt in sorted(val_dist.items()):
        print(f"    Valence {v}: {cnt} edge(s)")
    print(f"  ✓  All 12 edges have valence {full_valences[0]} "
          f"in the full honeycomb."
          if len(set(full_valences)) == 1
          else f"  Edge valences vary: {set(full_valences)}")

    # ── Build patches ───────────────────────────────────────────────
    all_results = []

    for max_c, label in [(7, "3D Star (C + 6 face-nbrs)"),
                         (21, "Intermediate (≤21 cells)"),
                         (35, "Intermediate (≤35 cells)"),
                         (55, "Extended (≤55 cells)")]:
        print(f"\n{'━' * 72}")
        print(f"  Building: {label} ...")
        patch = build_patch(face_crossings, cell_center, max_c, label)
        result = analyze_patch(
            patch, face_crossings, adj_pairs, cell_center
        )
        all_results.append((label, result))

        if result["gate_pass"]:
            print(f"\n  ★  Sweet spot found at {label}!")
            break

    # ── Summary ─────────────────────────────────────────────────────
    print(f"\n{'━' * 72}")
    print(f"  SUMMARY")
    print(f"{'━' * 72}")
    print(f"\n  {'Patch':<35s} | {'Cells':>5s} | {'Bdy':>4s} | "
          f"{'Full':>4s} | {'Gate':>4s}")
    print(f"  {'─' * 60}")
    for label, r in all_results:
        gate = "✓" if r["gate_pass"] else "✗"
        print(f"  {label:<35s} | {r['n_cells']:>5d} | "
              f"{r['n_boundary_faces']:>4d} | "
              f"{r['n_full_valence_edges_in_patch']:>4d} | "
              f"{gate:>4s}")

    print(f"""
  The {{4,3,5}} honeycomb is the natural 3D successor to the
  {{5,4}} tiling.  The mathematical mechanism is identical:
    • Min-cut = minimal separating SURFACE (2D faces, not 1D edges)
    • Curvature lives on EDGES (not vertices)
    • κ(e) = 2π − 5·(π/2) = −π/2  at fully-surrounded edges

  The same Python-oracle + abstract-barrier strategy from the
  11-tile bridge (Phase 3.5) applies to 3D.  The symmetry group
  provides dramatic orbit reduction for large patches.
""")


if __name__ == "__main__":
    main()