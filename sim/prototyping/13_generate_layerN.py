#!/usr/bin/env python3
"""
13_generate_layerN.py  —  Phase C.1 {5,4} Layer-N Patch Generator + Agda Emitter

Generates BFS-depth-N patches of the {5,4} hyperbolic pentagonal tiling
using Coxeter group reflections, computes min-cut values and orbit
classifications, and emits OrbitReducedPatch Agda modules consumed by
the generic bridge (Bridge/GenericBridge.agda) and the schematic tower
(Bridge/SchematicTower.agda).

The {5,4} tiling has regular pentagons with 4 meeting at each vertex.
The Coxeter group [5,4] has rank 3, Gram matrix signature (2,1)
(hyperbolic).  The tile stabilizer is the dihedral group D₅ (order 10),
and each tile has 5 edge-crossings (one per pentagon edge).

Growth is by BFS from the central tile in the tile-adjacency graph:
  depth 1:  ~6 tiles   (C + 5 edge-neighbours, ≈ star patch)
  depth 2:  ~21 tiles  (+ gap-fillers + outer ring)
  depth 3:  ~56 tiles
  depth 4:  ~146 tiles
  depth 5:  ~381 tiles
(Exponential growth — the hallmark of hyperbolic geometry.)

For each patch, the script:
  1. Builds the tile-adjacency flow graph via Coxeter reflections.
  2. Enumerates cell-aligned boundary regions (connected subsets of
     boundary tiles up to --max-region-cells cells).
  3. Computes min-cut values via max-flow (dimension-agnostic).
  4. Classifies regions into orbits by min-cut value.
  5. Emits Cubical Agda modules following the OrbitReducedPatch
     pattern from 09_generate_dense100.py.

Generated modules (for --depth N):
  src/Common/Layer54d{N}Spec.agda       — region type, orbit type, classify
  src/Boundary/Layer54d{N}Cut.agda      — S-cut via orbit reps
  src/Bulk/Layer54d{N}Chain.agda        — L-min via orbit reps
  src/Bridge/Layer54d{N}Obs.agda        — orbit-based pointwise agreement

Usage (from repository root):
  python3 sim/prototyping/13_generate_layerN.py --depth 2
  python3 sim/prototyping/13_generate_layerN.py --depth 3 --dry-run
  python3 sim/prototyping/13_generate_layerN.py --depth 4 --max-region-cells 3

Dependencies:  numpy, networkx

Reference:
  docs/10-frontier.md §5    (Direction C — N Layers)
  docs/10-frontier.md §5.4  (Schematic Bridge Factorization)
  docs/10-frontier.md §5.9  (The {5,4} Layer Generator)
  docs/10-frontier.md §5.11 (Phase C.1)
  sim/prototyping/09_generate_dense100.py  (orbit reduction pattern)
"""

from __future__ import annotations

import argparse
import math
import sys
from collections import Counter, defaultdict, deque
from pathlib import Path
from typing import NamedTuple

try:
    import numpy as np
except ImportError:
    sys.exit("ERROR: numpy is required.  pip install numpy")

try:
    import networkx as nx
except ImportError:
    sys.exit("ERROR: networkx is required.  pip install networkx")

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SRC_DIR = SCRIPT_DIR.parent.parent / "src"

ROUND_DIGITS = 8
INF_CAP = 10_000
EDGES_PER_TILE = 5  # pentagons


# ════════════════════════════════════════════════════════════════════
#  1.  Coxeter Geometry for [5,4]
# ════════════════════════════════════════════════════════════════════
#
#  The [5,4] Coxeter group has generators s0, s1, s2 with:
#    m(s0,s1) = 5   (pentagon faces)
#    m(s1,s2) = 4   (4 tiles at each vertex)
#    m(s0,s2) = 2
#
#  Gram matrix G_ij = −cos(π / m_ij),  signature (2,1) → hyperbolic.
#
#  Tile stabilizer <s0, s1> ≅ D₅ (order 10).
#  Edge-crossings: 5 distinct conjugates of s2 by <s0, s1>.
# ════════════════════════════════════════════════════════════════════

def _vec_key(v: np.ndarray) -> tuple:
    return tuple(np.round(v, ROUND_DIGITS))


def _mat_key(M: np.ndarray) -> tuple:
    return tuple(np.round(M.ravel(), ROUND_DIGITS))


def build_gram_matrix() -> np.ndarray:
    """Gram matrix G_{ij} = −cos(π / m_{ij}) for [5,4]."""
    m = np.array([
        [1, 5, 2],
        [5, 1, 4],
        [2, 4, 1],
    ], dtype=float)
    G = -np.cos(np.pi / m)
    np.fill_diagonal(G, 1.0)
    return G


def build_reflections(G: np.ndarray) -> list[np.ndarray]:
    """Reflection matrices S_i = I − 2 e_i G[i,:] for [5,4]."""
    n = G.shape[0]
    refls = []
    for i in range(n):
        S = np.eye(n)
        S[i, :] -= 2.0 * G[i, :]
        refls.append(S)
    return refls


def validate_reflections(G: np.ndarray, refls: list[np.ndarray]) -> None:
    """Check involution, G-preservation, and Coxeter relations."""
    I3 = np.eye(3)
    for i, S in enumerate(refls):
        assert np.allclose(S @ S, I3, atol=1e-12), f"s{i} not involution"
        assert np.allclose(S.T @ G @ S, G, atol=1e-10), \
            f"s{i} doesn't preserve bilinear form"

    m_vals = {(0, 1): 5, (1, 2): 4, (0, 2): 2}
    for (i, j), m in m_vals.items():
        prod = refls[i] @ refls[j]
        power = np.linalg.matrix_power(prod, m)
        assert np.allclose(power, I3, atol=1e-8), \
            f"(s{i}·s{j})^{m} ≠ I"


def enumerate_group(generators: list[np.ndarray],
                    expected: int | None = None,
                    max_size: int | None = None) -> list[np.ndarray]:
    """BFS enumeration of a finite group from matrix generators."""
    I = np.eye(generators[0].shape[0])
    elems = [I]
    seen = {_mat_key(I)}
    queue = deque([I])
    limit = max_size or 100000
    while queue:
        g = queue.popleft()
        for s in generators:
            for h in [s @ g, g @ s]:
                k = _mat_key(h)
                if k not in seen:
                    seen.add(k)
                    elems.append(h)
                    queue.append(h)
                    if len(elems) >= limit:
                        if expected is not None:
                            assert len(elems) == expected
                        return elems
    if expected is not None:
        assert len(elems) == expected, \
            f"Expected {expected} elements, got {len(elems)}"
    return elems


def find_tile_center(G: np.ndarray) -> np.ndarray:
    """
    Center of fundamental tile: perpendicular to α₀, α₁.

    (Gp)_i = 0 for i=0,1  ⟹  p = G⁻¹ e₂ (up to scale).
    """
    Ginv = np.linalg.inv(G)
    p = Ginv[:, 2].copy()
    Gp = G @ p
    assert abs(Gp[0]) < 1e-10 and abs(Gp[1]) < 1e-10
    if Gp[2] < 0:
        p = -p
    return p


def find_edge_crossings(refls: list[np.ndarray],
                        stabilizer: list[np.ndarray],
                        G: np.ndarray) -> list[np.ndarray]:
    """
    Find the 5 edge-crossing transformations F_k = h_k s₂ h_k⁻¹
    where h_k ranges over coset reps of the edge stabilizer in D₅.
    """
    s2 = refls[2]
    Ginv = np.linalg.inv(G)
    crossings = []
    seen: set[tuple] = set()

    for h in stabilizer:
        h_inv = Ginv @ h.T @ G
        F = h @ s2 @ h_inv
        k = _mat_key(F)
        if k not in seen:
            seen.add(k)
            crossings.append(F)

    assert len(crossings) == EDGES_PER_TILE, \
        f"Expected {EDGES_PER_TILE} edge crossings, got {len(crossings)}"
    return crossings


# ════════════════════════════════════════════════════════════════════
#  2.  BFS Patch Builder for the {5,4} Tiling
# ════════════════════════════════════════════════════════════════════

def build_layer_patch(
    edge_crossings: list[np.ndarray],
    tile_center: np.ndarray,
    bfs_depth: int,
    name: str = "layer",
) -> dict:
    """
    Grow a {5,4} tiling patch by BFS from the central tile to the
    specified BFS depth.

    Each tile is represented by a 3×3 matrix g (product of Coxeter
    reflections).  The center of tile g is g @ tile_center.
    The 5 neighbors of tile g are g @ F_k for k = 0..4.
    """
    p = tile_center
    tiles: dict[int, np.ndarray] = {}
    center_to_id: dict[tuple, int] = {}

    def register(mat: np.ndarray) -> tuple[int, bool]:
        c = mat @ p
        k = _vec_key(c)
        if k in center_to_id:
            return center_to_id[k], False
        tid = len(tiles)
        tiles[tid] = mat
        center_to_id[k] = tid
        return tid, True

    register(np.eye(3))
    current_frontier = {0}

    for _ in range(bfs_depth):
        next_frontier: set[int] = set()
        for tid in current_frontier:
            g = tiles[tid]
            for F in edge_crossings:
                h = g @ F
                nid, is_new = register(h)
                if is_new:
                    next_frontier.add(nid)
        current_frontier = next_frontier

    # ── Compute neighbor structure ──────────────────────────────────
    neighbors: dict[int, set[int]] = defaultdict(set)
    for tid, g in tiles.items():
        for F in edge_crossings:
            ck = _vec_key((g @ F) @ p)
            if ck in center_to_id:
                nid = center_to_id[ck]
                if nid != tid:
                    neighbors[tid].add(nid)
                    neighbors[nid].add(tid)

    # ── Internal bonds (shared edges) ───────────────────────────────
    internal_bonds: list[tuple[int, int]] = []
    seen_pairs: set[frozenset[int]] = set()
    for tid, nbrs in neighbors.items():
        for nid in nbrs:
            pair = frozenset([tid, nid])
            if pair not in seen_pairs:
                seen_pairs.add(pair)
                internal_bonds.append((min(tid, nid), max(tid, nid)))

    # ── Boundary legs per tile ──────────────────────────────────────
    bdy_per_tile: dict[int, int] = {}
    for tid in tiles:
        bdy_per_tile[tid] = EDGES_PER_TILE - len(neighbors.get(tid, set()))

    n_boundary = sum(bdy_per_tile.values())

    return {
        "name": name,
        "tiles": tiles,
        "neighbors": dict(neighbors),
        "internal_bonds": internal_bonds,
        "n_boundary_legs": n_boundary,
        "bdy_per_tile": bdy_per_tile,
    }


# ════════════════════════════════════════════════════════════════════
#  3.  Flow Graph and Min-Cut (dimension-agnostic)
# ════════════════════════════════════════════════════════════════════

def build_flow_graph(
    patch: dict,
) -> tuple[nx.DiGraph, list[int], dict[int, int]]:
    """
    Build a directed flow graph for min-cut computation.

    Nodes: tile IDs + boundary-leg pseudo-nodes.
    Internal bonds → bidirectional capacity-1 edges between tiles.
    Boundary legs → capacity-1 edges to pseudo-nodes.
    """
    G = nx.DiGraph()

    for t1, t2 in patch["internal_bonds"]:
        G.add_edge(f"t{t1}", f"t{t2}", capacity=1)
        G.add_edge(f"t{t2}", f"t{t1}", capacity=1)

    bnode_ids: list[int] = []
    bnode_to_tile: dict[int, int] = {}
    idx = 0
    for tid, n_bdy in patch["bdy_per_tile"].items():
        for _ in range(n_bdy):
            bnode = f"b{idx}"
            G.add_edge(f"t{tid}", bnode, capacity=1)
            G.add_edge(bnode, f"t{tid}", capacity=1)
            bnode_ids.append(idx)
            bnode_to_tile[idx] = tid
            idx += 1

    return G, bnode_ids, bnode_to_tile


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
#  4.  Region Enumeration (connected subsets of boundary tiles)
# ════════════════════════════════════════════════════════════════════

class RegionInfo(NamedTuple):
    idx: int
    tiles: frozenset[int]
    n_bdy_legs: int
    min_cut: int


def enumerate_regions(
    patch: dict,
    bnode_to_tile: dict[int, int],
    bnode_ids: list[int],
    max_region_tiles: int,
) -> list[RegionInfo]:
    """
    Enumerate all cell-aligned boundary regions (connected subsets
    of boundary tiles up to max_region_tiles tiles) and compute
    their min-cut values.
    """
    # Identify boundary tiles
    bdy_tiles: set[int] = set()
    tile_bnodes: dict[int, set[int]] = defaultdict(set)
    for idx in bnode_ids:
        tid = bnode_to_tile[idx]
        bdy_tiles.add(tid)
        tile_bnodes[tid].add(idx)

    # Build boundary-tile adjacency graph
    bg = nx.Graph()
    bg.add_nodes_from(bdy_tiles)
    for tid in bdy_tiles:
        for nid in patch["neighbors"].get(tid, set()):
            if nid in bdy_tiles:
                bg.add_edge(tid, nid)

    # Enumerate connected subsets via DFS
    result_sets: set[frozenset[int]] = set()

    for start in sorted(bdy_tiles):
        _dfs_subsets(bg, frozenset([start]),
                     set(bg.neighbors(start)) & bdy_tiles - {start},
                     max_region_tiles, result_sets)

    # Remove full boundary (complement is empty)
    full = frozenset(bdy_tiles)
    result_sets.discard(full)

    # Sort by (size, sorted tuple)
    subsets_sorted = sorted(result_sets,
                            key=lambda s: (len(s), tuple(sorted(s))))

    # Compute min-cuts
    flow_G, _, _ = build_flow_graph(patch)
    regions: list[RegionInfo] = []
    for i, subset in enumerate(subsets_sorted):
        bnodes: set[int] = set()
        for tid in subset:
            bnodes.update(tile_bnodes[tid])
        if not bnodes:
            continue
        s = compute_min_cut(flow_G, bnode_ids, bnodes)
        regions.append(RegionInfo(i, subset, len(bnodes), s))

    # Re-index
    return [RegionInfo(i, r.tiles, r.n_bdy_legs, r.min_cut)
            for i, r in enumerate(regions)]


def _dfs_subsets(
    graph: nx.Graph,
    current: frozenset[int],
    frontier: set[int],
    max_size: int,
    results: set[frozenset[int]],
) -> None:
    """DFS enumeration of connected subsets."""
    if current in results:
        return
    results.add(current)
    if len(current) >= max_size:
        return
    for node in sorted(frontier):
        new_set = current | frozenset([node])
        if new_set not in results:
            new_frontier = (
                frontier | set(graph.neighbors(node))
            ) - new_set
            _dfs_subsets(graph, new_set, new_frontier, max_size, results)


# ════════════════════════════════════════════════════════════════════
#  5.  Orbit Reduction (by min-cut value)
# ════════════════════════════════════════════════════════════════════

class OrbitRep(NamedTuple):
    name: str
    min_cut: int
    count: int


def compute_orbits(regions: list[RegionInfo]) -> list[OrbitRep]:
    """Group regions by min-cut value into orbit representatives."""
    cut_counts = Counter(r.min_cut for r in regions)
    return [OrbitRep(f"mc{v}", v, cut_counts[v])
            for v in sorted(cut_counts)]


def orbit_for_region(r: RegionInfo, orbits: list[OrbitRep]) -> OrbitRep:
    for orb in orbits:
        if orb.min_cut == r.min_cut:
            return orb
    raise ValueError(f"No orbit for min-cut {r.min_cut}")


# ════════════════════════════════════════════════════════════════════
#  6.  Agda Naming Helpers
# ════════════════════════════════════════════════════════════════════

def module_prefix(depth: int) -> str:
    """Module name component for a given BFS depth."""
    return f"Layer54d{depth}"


def region_agda_name(depth: int, r: RegionInfo) -> str:
    return f"l{depth}r{r.idx}"


def tiles_comment(r: RegionInfo) -> str:
    ts = sorted(r.tiles)
    if len(ts) <= 6:
        return "{" + ",".join(f"t{t}" for t in ts) + "}"
    return "{" + ",".join(f"t{t}" for t in ts[:5]) + ",..." + "}"


# ════════════════════════════════════════════════════════════════════
#  7.  Agda Module Generators
# ════════════════════════════════════════════════════════════════════

def banner(depth: int) -> str:
    return (
        f"--  Generated by sim/prototyping/13_generate_layerN.py --depth {depth}\n"
        "--  Do not edit by hand.  Regenerate with:\n"
        f"--    python3 sim/prototyping/13_generate_layerN.py --depth {depth}"
    )


def gen_spec(depth: int, regions: list[RegionInfo],
             orbits: list[OrbitRep]) -> str:
    P = module_prefix(depth)
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a(f"module Common.{P}Spec where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a("")

    # ── Region type ─────────────────────────────────────────────────
    a(f"-- {P}Region — Cell-aligned boundary regions of the")
    a(f"-- {{5,4}} tiling patch at BFS depth {depth}")
    a(f"-- {len(regions)} regions, {len(orbits)} orbit representatives")
    a(banner(depth))
    a("")
    a(f"data {P}Region : Type₀ where")

    sizes: dict[int, list[RegionInfo]] = defaultdict(list)
    for r in regions:
        sizes[len(r.tiles)].append(r)

    for size in sorted(sizes):
        rs = sizes[size]
        names = [region_agda_name(depth, r) for r in rs]
        a(f"  -- size {size}  ({len(rs)} regions)")
        for i in range(0, len(names), 10):
            batch = names[i:i + 10]
            a(f"  {' '.join(batch)} : {P}Region")
    a("")

    # ── Orbit type ──────────────────────────────────────────────────
    a(f"-- {P}OrbitRep — Orbit representatives by min-cut value")
    a(f"-- Orbit decomposition:")
    for orb in orbits:
        a(f"--   {orb.name}  (S = {orb.min_cut}):  {orb.count} regions")
    a(banner(depth))
    a("")
    a(f"data {P}OrbitRep : Type₀ where")
    a(f"  {' '.join(o.name for o in orbits)} : {P}OrbitRep")
    a("")

    # ── classify ────────────────────────────────────────────────────
    a(f"-- classify{P} — Map each region to its orbit representative")
    a(banner(depth))
    a("")
    a(f"classify{P} : {P}Region → {P}OrbitRep")

    for r in regions:
        rn = region_agda_name(depth, r)
        orb = orbit_for_region(r, orbits)
        a(f"classify{P} {rn} = {orb.name}")

    a("")
    return "\n".join(L) + "\n"


def gen_cut(depth: int, orbits: list[OrbitRep]) -> str:
    P = module_prefix(depth)
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a(f"module Boundary.{P}Cut where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a(f"open import Common.{P}Spec")
    a("")
    a(f"record {P}BdyView : Type₀ where")
    a("  field")
    a("    dummy : ℚ≥0")
    a("")
    a(f"-- S-cut-rep — Boundary min-cut on orbit representatives")
    a(banner(depth))
    a("")
    a(f"S-cut-rep : {P}OrbitRep → ℚ≥0")
    for orb in orbits:
        a(f"S-cut-rep {orb.name} = {orb.min_cut}")
    a("")
    a(f"-- S-cut — Boundary min-cut (via orbit reduction)")
    a(f"S-cut : {P}BdyView → {P}Region → ℚ≥0")
    a(f"S-cut _ r = S-cut-rep (classify{P} r)")
    a("")

    return "\n".join(L) + "\n"


def gen_chain(depth: int, orbits: list[OrbitRep]) -> str:
    P = module_prefix(depth)
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a(f"module Bulk.{P}Chain where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a(f"open import Common.{P}Spec")
    a("")
    a(f"record {P}BulkView : Type₀ where")
    a("  field")
    a("    dummy : ℚ≥0")
    a("")
    a(f"-- L-min-rep — Bulk minimal chain on orbit representatives")
    a(banner(depth))
    a("")
    a(f"L-min-rep : {P}OrbitRep → ℚ≥0")
    for orb in orbits:
        a(f"L-min-rep {orb.name} = {orb.min_cut}")
    a("")
    a(f"-- L-min — Bulk minimal separating chain (via orbit reduction)")
    a(f"L-min : {P}BulkView → {P}Region → ℚ≥0")
    a(f"L-min _ r = L-min-rep (classify{P} r)")
    a("")

    return "\n".join(L) + "\n"


def gen_obs(depth: int, regions: list[RegionInfo],
            orbits: list[OrbitRep]) -> str:
    P = module_prefix(depth)
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a(f"module Bridge.{P}Obs where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a(f"open import Common.{P}Spec")
    a("open import Common.ObsPackage")
    a(f"open import Boundary.{P}Cut")
    a(f"open import Bulk.{P}Chain")
    a("")

    # ── Canonical views ─────────────────────────────────────────────
    a(f"{P.lower()}BdyView : {P}BdyView")
    a(f"{P.lower()}BdyView .{P}BdyView.dummy = 0")
    a("")
    a(f"{P.lower()}BulkView : {P}BulkView")
    a(f"{P.lower()}BulkView .{P}BulkView.dummy = 0")
    a("")

    # ── Observable packages ─────────────────────────────────────────
    a(f"{P}Obs∂ : ObsPackage {P}Region")
    a(f"{P}Obs∂ .ObsPackage.obs = S-cut {P.lower()}BdyView")
    a("")
    a(f"{P}ObsBulk : ObsPackage {P}Region")
    a(f"{P}ObsBulk .ObsPackage.obs = L-min {P.lower()}BulkView")
    a("")

    # ── Orbit-level pointwise agreement ─────────────────────────────
    a(f"-- {P.lower()}-pointwise-rep — All {len(orbits)} orbit cases by refl")
    a(f"-- S-cut-rep and L-min-rep return the same ℕ literal on each orbit.")
    a(banner(depth))
    a("")
    a(f"{P.lower()}-pointwise-rep :")
    a(f"  (o : {P}OrbitRep) → S-cut-rep o ≡ L-min-rep o")
    for orb in orbits:
        a(f"{P.lower()}-pointwise-rep {orb.name} = refl")
    a("")

    # ── Full pointwise agreement (1-line lifting) ───────────────────
    a(f"-- {P.lower()}-pointwise — Lifted to all {len(regions)} regions")
    a(f"-- via classify{P} (the orbit reduction 1-line lifting)")
    a(banner(depth))
    a("")
    a(f"{P.lower()}-pointwise :")
    a(f"  (r : {P}Region) →")
    a(f"  S-cut {P.lower()}BdyView r ≡ L-min {P.lower()}BulkView r")
    a(f"{P.lower()}-pointwise r = {P.lower()}-pointwise-rep (classify{P} r)")
    a("")

    # ── Function path ───────────────────────────────────────────────
    a(f"S∂{P} : {P}Region → ℚ≥0")
    a(f"S∂{P} = S-cut {P.lower()}BdyView")
    a("")
    a(f"LB{P} : {P}Region → ℚ≥0")
    a(f"LB{P} = L-min {P.lower()}BulkView")
    a("")
    a(f"{P.lower()}-obs-path : S∂{P} ≡ LB{P}")
    a(f"{P.lower()}-obs-path = funExt {P.lower()}-pointwise")
    a("")

    # ── Package path ────────────────────────────────────────────────
    a(f"{P.lower()}-package-path : {P}Obs∂ ≡ {P}ObsBulk")
    a(f"{P.lower()}-package-path i .ObsPackage.obs = {P.lower()}-obs-path i")
    a("")

    return "\n".join(L) + "\n"


# ════════════════════════════════════════════════════════════════════
#  8.  File Writing
# ════════════════════════════════════════════════════════════════════

def get_file_map(depth: int) -> list[tuple[str, str]]:
    P = module_prefix(depth)
    return [
        (f"Common/{P}Spec.agda",    "spec"),
        (f"Boundary/{P}Cut.agda",   "cut"),
        (f"Bulk/{P}Chain.agda",     "chain"),
        (f"Bridge/{P}Obs.agda",     "obs"),
    ]


def write_file(path: Path, content: str, dry_run: bool) -> None:
    lines = content.count("\n")
    if dry_run:
        print(f"  [dry-run]  {path}  ({lines} lines)")
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        print(f"  ✓  {path}  ({lines} lines)")


# ════════════════════════════════════════════════════════════════════
#  9.  Summary and Reporting
# ════════════════════════════════════════════════════════════════════

def print_summary(
    depth: int,
    patch: dict,
    regions: list[RegionInfo],
    orbits: list[OrbitRep],
) -> None:
    n_tiles = len(patch["tiles"])
    n_bonds = len(patch["internal_bonds"])
    n_bdy = patch["n_boundary_legs"]

    print(f"\n  ── {'{5,4}'} Tiling Patch at BFS Depth {depth} ──")
    print(f"  Tiles (pentagons):    {n_tiles}")
    print(f"  Internal bonds:       {n_bonds}")
    print(f"  Boundary legs:        {n_bdy}")
    print(f"  Density (2·bonds/tiles): "
          f"{2 * n_bonds / max(n_tiles, 1):.2f}")

    if not regions:
        print(f"  No regions found.")
        return

    cut_dist = Counter(r.min_cut for r in regions)
    size_dist = Counter(len(r.tiles) for r in regions)
    min_s = min(r.min_cut for r in regions)
    max_s = max(r.min_cut for r in regions)

    print(f"\n  ── Region Statistics ({len(regions)} total) ──")
    print(f"  By size:")
    for sz in sorted(size_dist):
        print(f"    {sz}-tile regions:  {size_dist[sz]}")
    print(f"  By min-cut value:")
    for val in sorted(cut_dist):
        print(f"    S = {val}:  {cut_dist[val]} regions")
    print(f"  Min-cut range:  {min_s} – {max_s}")

    print(f"\n  ── Orbit Reduction ──")
    print(f"  Distinct min-cut values:  {len(orbits)}")
    for orb in orbits:
        print(f"    {orb.name}  (S = {orb.min_cut}):  {orb.count} regions")
    reduction = len(regions) / max(len(orbits), 1)
    print(f"  Reduction factor:  {len(regions)} → {len(orbits)}"
          f"  ({reduction:.0f}× fewer proof cases)")

    print(f"\n  ── SchematicTower Integration ──")
    P = module_prefix(depth)
    print(f"  To add this level to the schematic tower:")
    print(f"    1. Load the 4 generated modules in Agda.")
    print(f"    2. In Bridge/GenericValidation.agda, construct:")
    print(f"         {P.lower()}OrbitPatch : OrbitReducedPatch")
    print(f"    3. In Bridge/SchematicTower.agda:")
    print(f"         {P.lower()}-tower-level = mkTowerLevel "
          f"{P.lower()}OrbitPatch {max_s}")
    print(f"    The generic bridge (orbit-bridge-witness) will")
    print(f"    automatically produce the full BridgeWitness.")


def print_gate_check(
    depth: int,
    patch: dict,
    regions: list[RegionInfo],
    orbits: list[OrbitRep],
) -> bool:
    n_tiles = len(patch["tiles"])
    n_regs = len(regions)
    n_orbs = len(orbits)
    max_s = max(r.min_cut for r in regions) if regions else 0

    print(f"\n  ═══════════════════════════════════════════════════════")
    print(f"  GATE CHECK ({{5,4}} Layer at depth {depth})")
    print(f"  ═══════════════════════════════════════════════════════")

    gate_pass = True
    checks = [
        ("Region count (raw ≤ 5000)",
         n_regs <= 5000, n_regs),
        ("Orbit count ≤ 200",
         n_orbs <= 200, n_orbs),
        ("Max min-cut > 0 (nontrivial)",
         max_s > 0, max_s),
        ("Orbit reduction effective (ratio > 2×)",
         n_regs / max(n_orbs, 1) > 2 or n_regs < 20,
         f"{n_regs / max(n_orbs, 1):.0f}×"),
    ]
    for desc, ok, val in checks:
        status = "✓ PASS" if ok else "✗ FAIL"
        if not ok:
            gate_pass = False
        print(f"    {status}  {desc}  (actual: {val})")

    if gate_pass:
        print(f"\n  ▶  GATES PASS — Agda formalization FEASIBLE")
    else:
        print(f"\n  ▶  GATE(S) BLOCKED")

    return gate_pass


# ════════════════════════════════════════════════════════════════════
#  10.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate {5,4} layer-N patch Agda modules "
                    "for the schematic bridge tower (Phase C.1)")
    parser.add_argument("--depth", type=int, required=True,
                        help="BFS depth from central tile "
                             "(1=star, 2≈filled, 3+=deeper layers)")
    parser.add_argument("--max-region-cells", type=int, default=4,
                        help="Max tiles per boundary region (default: 4)")
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_SRC_DIR,
                        help="Root source directory")
    parser.add_argument("--dry-run", action="store_true",
                        help="Compute and verify without writing files")
    args = parser.parse_args()

    depth = args.depth
    P = module_prefix(depth)

    print("╔═══════════════════════════════════════════════════════════╗")
    print(f"║  Phase C.1: {{5,4}} Layer Generator — BFS depth {depth:<13}║")
    print("║  Coxeter [5,4] • pentagonal tiling • orbit reduction      ║")
    print("╚═══════════════════════════════════════════════════════════╝")

    # ── Step 1: Initialize Coxeter geometry ─────────────────────────
    print("\n  Initializing Coxeter geometry for [5,4] ...")
    G = build_gram_matrix()
    refls = build_reflections(G)

    evals = np.linalg.eigvalsh(G)
    n_neg = sum(1 for e in evals if e < -1e-10)
    n_pos = sum(1 for e in evals if e > 1e-10)
    print(f"  Gram matrix eigenvalues: "
          f"{', '.join(f'{e:.4f}' for e in sorted(evals))}")
    print(f"  Signature: ({n_pos}, {n_neg})  "
          f"{'✓ hyperbolic' if n_neg == 1 and n_pos == 2 else '✗'}")

    validate_reflections(G, refls)
    print("  ✓  Reflections: involution, G-preservation, Coxeter.")

    tile_center = find_tile_center(G)
    norm_sq = tile_center @ G @ tile_center
    print(f"  Tile center norm²: {norm_sq:.6f}  "
          f"({'timelike ✓' if norm_sq < 0 else 'spacelike ✗'})")

    # ── Step 2: Tile stabilizer and edge crossings ──────────────────
    print("\n  Enumerating tile stabilizer <s₀, s₁> ...")
    stab = enumerate_group(refls[:2], expected=10)
    print(f"  ✓  Tile stabilizer D₅ has {len(stab)} elements.")

    print("  Computing 5 edge crossings ...")
    edge_crossings = find_edge_crossings(refls, stab, G)
    print(f"  ✓  {len(edge_crossings)} edge crossings found.")

    # Verify edge crossings are involutions
    I3 = np.eye(3)
    for k, F in enumerate(edge_crossings):
        assert np.allclose(F @ F, I3, atol=1e-10), f"F_{k} not involution"
    print("  ✓  All edge crossings are involutions.")

    # ── Step 3: Build the patch ─────────────────────────────────────
    label = f"{{5,4}} BFS depth {depth}"
    print(f"\n  Building {label} ...")
    patch = build_layer_patch(
        edge_crossings, tile_center, depth, name=label
    )
    n_tiles = len(patch["tiles"])
    n_bonds = len(patch["internal_bonds"])
    n_bdy = patch["n_boundary_legs"]
    print(f"  ✓  {n_tiles} tiles, {n_bonds} bonds, {n_bdy} boundary legs.")

    # ── Step 4: Enumerate regions and compute min-cuts ──────────────
    max_rc = args.max_region_cells
    print(f"\n  Enumerating boundary regions (max {max_rc} tiles) ...")
    flow_G, bnode_ids, bnode_to_tile = build_flow_graph(patch)
    regions = enumerate_regions(patch, bnode_to_tile, bnode_ids, max_rc)
    print(f"  ✓  {len(regions)} regions computed.")

    if not regions:
        print("  ✗  No regions found! (Patch may have no boundary.)")
        return

    # ── Step 5: Compute orbit reduction ─────────────────────────────
    print("  Computing orbit reduction by min-cut value ...")
    orbits = compute_orbits(regions)
    print(f"  ✓  {len(orbits)} orbits "
          f"({len(regions)} → {len(orbits)}, "
          f"{len(regions) / max(len(orbits), 1):.0f}×)")

    # ── Step 6: Summary and gate check ──────────────────────────────
    print_summary(depth, patch, regions, orbits)
    gate_ok = print_gate_check(depth, patch, regions, orbits)

    # ── Step 7: Generate and write Agda files ───────────────────────
    src_dir = args.output_dir.resolve()
    print(f"\n  Output directory: {src_dir}")
    if args.dry_run:
        print("  [DRY RUN — no files will be written]\n")
    print()

    generators = {
        "spec":  lambda: gen_spec(depth, regions, orbits),
        "cut":   lambda: gen_cut(depth, orbits),
        "chain": lambda: gen_chain(depth, orbits),
        "obs":   lambda: gen_obs(depth, regions, orbits),
    }

    total_lines = 0
    file_map = get_file_map(depth)
    for rel_path, gen_key in file_map:
        content = generators[gen_key]()
        full_path = src_dir / rel_path
        write_file(full_path, content, args.dry_run)
        total_lines += content.count("\n")

    # ── Step 8: Final report ────────────────────────────────────────
    action = "would generate" if args.dry_run else "generated"
    max_s = max(r.min_cut for r in regions)

    print(f"\n  ── Summary: {action} {len(file_map)} files, "
          f"~{total_lines} lines total ──")

    print(f"\n  Module contents:")
    print(f"    {P}Region constructors:       {len(regions)}")
    print(f"    {P}OrbitRep constructors:      {len(orbits)}")
    print(f"    classify{P} clauses:           {len(regions)}")
    print(f"    S-cut-rep / L-min-rep clauses: {len(orbits)} each")
    print(f"    Pointwise-rep refl proofs:     {len(orbits)}")
    print(f"    Pointwise lifting:             1 line")
    print(f"    Max min-cut:                   {max_s}")

    print(f"""
  To integrate with Bridge/GenericBridge.agda:

    -- In a validation module:
    {P.lower()}OrbitPatch : OrbitReducedPatch
    {P.lower()}OrbitPatch .OrbitReducedPatch.RegionTy  = {P}Region
    {P.lower()}OrbitPatch .OrbitReducedPatch.OrbitTy   = {P}OrbitRep
    {P.lower()}OrbitPatch .OrbitReducedPatch.classify  = classify{P}
    {P.lower()}OrbitPatch .OrbitReducedPatch.S-rep     = S-cut-rep
    {P.lower()}OrbitPatch .OrbitReducedPatch.L-rep     = L-min-rep
    {P.lower()}OrbitPatch .OrbitReducedPatch.rep-agree = {P.lower()}-pointwise-rep

    -- The generic bridge automatically produces BridgeWitness:
    {P.lower()}-witness : BridgeWitness
    {P.lower()}-witness = orbit-bridge-witness {P.lower()}OrbitPatch

    -- For the schematic tower:
    {P.lower()}-tower-level = mkTowerLevel {P.lower()}OrbitPatch {max_s}
""")


if __name__ == "__main__":
    main()