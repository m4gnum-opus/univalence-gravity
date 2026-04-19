#!/usr/bin/env python3
"""
02_happy_patch_curvature.py  —  Phase 1.2(b)

Discrete curvature and Gauss–Bonnet verification for HaPPY code
patches on the {5,4} tiling.

Builds the 11-tile filled patch as a polygon complex (vertices, edges,
pentagonal faces), then:

  1. Computes combinatorial curvature:
       κ(v) = 1 − deg_E(v)/2 + Σ_{f ∋ v} 1/sides(f)
     and verifies  Σ κ(v) = χ(K)  (Euler characteristic).

  2. Computes angular curvature using Euclidean interior angles of a
     regular pentagon (3π/5 = 108°):
       Interior: κ(v) = 2π − angle_sum(v)
       Boundary: τ(v) = π  − angle_sum(v)
     and verifies  Σ_{int} κ + Σ_{∂} τ = 2π·χ(K).

  3. Fan-triangulates each pentagon (center vertex + 5 triangles),
     assigns edge lengths (side = 1, center-to-vertex = circumradius),
     computes Regge angle-deficit curvature from the law of cosines,
     and verifies Gauss–Bonnet for the triangulated surface.

Reference:
  Pastawski et al. (2015), arXiv:1503.06237
  Regge (1961), "General Relativity Without Coordinates"

Dependencies:  Python ≥ 3.9  (standard library only: fractions, math)
"""

from __future__ import annotations

import math
from fractions import Fraction
from collections import defaultdict
from typing import NamedTuple


# ════════════════════════════════════════════════════════════════════
#  1.  Polygon complex construction  (11-tile {5,4} patch)
# ════════════════════════════════════════════════════════════════════

class PolyComplex(NamedTuple):
    """A 2D polygon complex: vertices, edges, and named polygonal faces."""
    vertices: set[str]
    edges: set[tuple[str, str]]          # frozenset-like sorted pairs
    faces: dict[str, tuple[str, ...]]    # face_name → ordered vertex tuple


def _edge(a: str, b: str) -> tuple[str, str]:
    """Canonical undirected edge (sorted pair)."""
    return (a, b) if a <= b else (b, a)


def build_11tile_complex() -> PolyComplex:
    """
    Build the full polygon complex for the 11-tile {5,4} patch.

    Tile naming:
      C       — central pentagon, vertices  v0 .. v4
      N_i     — edge-neighbour sharing edge (v_i, v_{i+1 mod 5}) with C
                 new vertices:  a_i, b_i, c_i
      G_i     — gap-filler at vertex v_i between N_{i−1} and N_i
                 new vertices:  g{i}_1, g{i}_2

    Vertex counts:   5 + 15 + 10 = 30
    Edge counts:     5 + 20 + 15 = 40
    Face counts:     1 + 5  + 5  = 11
    Euler:           30 − 40 + 11 = 1   (disk)
    """
    verts: set[str] = set()
    edges: set[tuple[str, str]] = set()
    faces: dict[str, tuple[str, ...]] = {}

    # --- Central pentagon C ---
    c_verts = tuple(f"v{i}" for i in range(5))
    faces["C"] = c_verts
    verts.update(c_verts)

    # --- Edge-neighbours N_i ---
    for i in range(5):
        ni = (i + 1) % 5
        face_verts = (f"v{i}", f"v{ni}", f"a{i}", f"b{i}", f"c{i}")
        faces[f"N{i}"] = face_verts
        verts.update(face_verts)

    # --- Gap-fillers G_i ---
    for i in range(5):
        pi = (i - 1) % 5
        face_verts = (f"v{i}", f"a{pi}", f"g{i}_1", f"g{i}_2", f"c{i}")
        faces[f"G{i}"] = face_verts
        verts.update(face_verts)

    # --- Extract edges from faces ---
    for _, fv in faces.items():
        n = len(fv)
        for j in range(n):
            edges.add(_edge(fv[j], fv[(j + 1) % n]))

    return PolyComplex(verts, edges, faces)


# ════════════════════════════════════════════════════════════════════
#  2.  Topology helpers
# ════════════════════════════════════════════════════════════════════

def vertex_edge_degree(cpx: PolyComplex) -> dict[str, int]:
    """Number of edges incident to each vertex."""
    deg: dict[str, int] = defaultdict(int)
    for a, b in cpx.edges:
        deg[a] += 1
        deg[b] += 1
    return dict(deg)


def vertex_faces(cpx: PolyComplex) -> dict[str, list[str]]:
    """For each vertex, the list of faces it belongs to."""
    vf: dict[str, list[str]] = defaultdict(list)
    for fname, fverts in cpx.faces.items():
        for v in fverts:
            vf[v].append(fname)
    return dict(vf)


def is_boundary_edge(e: tuple[str, str], cpx: PolyComplex) -> bool:
    """An edge is on the boundary iff it belongs to exactly one face."""
    count = 0
    for _, fv in cpx.faces.items():
        n = len(fv)
        for j in range(n):
            fe = _edge(fv[j], fv[(j + 1) % n])
            if fe == e:
                count += 1
    return count == 1


def boundary_vertices(cpx: PolyComplex) -> set[str]:
    """Vertices that lie on at least one boundary edge."""
    bv: set[str] = set()
    for e in cpx.edges:
        if is_boundary_edge(e, cpx):
            bv.add(e[0])
            bv.add(e[1])
    return bv


def euler_characteristic(cpx: PolyComplex) -> int:
    """V − E + F."""
    return len(cpx.vertices) - len(cpx.edges) + len(cpx.faces)


# ════════════════════════════════════════════════════════════════════
#  3.  Combinatorial curvature
# ════════════════════════════════════════════════════════════════════

def combinatorial_curvature(cpx: PolyComplex) -> dict[str, Fraction]:
    """
    Compute combinatorial Gauss curvature at every vertex:

        κ(v) = 1 − deg_E(v)/2  +  Σ_{f ∋ v}  1/sides(f)

    This satisfies the combinatorial Gauss–Bonnet theorem:

        Σ_v  κ(v)  =  χ(K)

    for any polyhedral cell complex K, regardless of whether vertices
    are interior or on the boundary.  The formula automatically accounts
    for boundary effects through the reduced degree and face count of
    boundary vertices.
    """
    deg = vertex_edge_degree(cpx)
    vf = vertex_faces(cpx)

    kappa: dict[str, Fraction] = {}
    for v in cpx.vertices:
        d = Fraction(deg.get(v, 0))
        face_sum = Fraction(0)
        for fname in vf.get(v, []):
            sides = len(cpx.faces[fname])
            face_sum += Fraction(1, sides)
        kappa[v] = Fraction(1) - d / 2 + face_sum

    return kappa


# ════════════════════════════════════════════════════════════════════
#  4.  Angular curvature  (Euclidean interior angles)
# ════════════════════════════════════════════════════════════════════

def angular_curvature(
    cpx: PolyComplex,
) -> tuple[dict[str, float], dict[str, float]]:
    """
    Compute angular curvature using the Euclidean interior angle of
    each regular polygon face.

    For a regular p-gon, the interior angle is (p−2)π/p.

    Returns
    -------
    kappa_int : dict   interior vertex  →  κ(v) = 2π − angle_sum(v)
    tau_bdy   : dict   boundary vertex  →  τ(v) = π  − angle_sum(v)
    """
    vf = vertex_faces(cpx)
    bverts = boundary_vertices(cpx)

    # Accumulate angle sums
    angle_sum: dict[str, float] = defaultdict(float)
    for fname, fverts in cpx.faces.items():
        p = len(fverts)
        interior_angle = (p - 2) * math.pi / p  # 108° for p = 5
        for v in fverts:
            angle_sum[v] += interior_angle

    kappa_int: dict[str, float] = {}
    tau_bdy: dict[str, float] = {}

    for v in cpx.vertices:
        a = angle_sum.get(v, 0.0)
        if v in bverts:
            tau_bdy[v] = math.pi - a
        else:
            kappa_int[v] = 2.0 * math.pi - a

    return kappa_int, tau_bdy


# ════════════════════════════════════════════════════════════════════
#  5.  Fan triangulation
# ════════════════════════════════════════════════════════════════════

class TriComplex(NamedTuple):
    """A triangulated 2D complex with edge lengths."""
    vertices: set[str]
    edges: set[tuple[str, str]]
    faces: list[tuple[str, str, str]]        # triangles as vertex triples
    edge_length: dict[tuple[str, str], float] # canonical edge → length


def fan_triangulate(cpx: PolyComplex, side_length: float = 1.0) -> TriComplex:
    """
    Fan-triangulate each polygon by inserting a center vertex and
    connecting it to all boundary vertices.

    For a regular p-gon with side s, the center-to-vertex distance
    (circumradius) is  R = s / (2 sin(π/p)).

    Each p-gon produces p isoceles triangles with:
      • two sides of length R  (center to vertex)
      • one side of length s   (polygon edge)
      • apex angle  2π/p  at the center
      • base angles  (π − 2π/p)/2 = π/2 − π/p  at the vertices
    """
    verts = set(cpx.vertices)
    edges: set[tuple[str, str]] = set()
    tris: list[tuple[str, str, str]] = []
    elen: dict[tuple[str, str], float] = {}

    # Copy original edge lengths
    for e in cpx.edges:
        elen[e] = side_length

    for fname, fverts in cpx.faces.items():
        p = len(fverts)
        center = f"O_{fname}"
        verts.add(center)
        R = side_length / (2.0 * math.sin(math.pi / p))

        for j in range(p):
            v_cur = fverts[j]
            v_nxt = fverts[(j + 1) % p]

            # Center-to-vertex edges
            e_c_cur = _edge(center, v_cur)
            e_c_nxt = _edge(center, v_nxt)
            edges.add(e_c_cur)
            edges.add(e_c_nxt)
            elen[e_c_cur] = R
            elen[e_c_nxt] = R

            # Polygon edge (already exists)
            e_side = _edge(v_cur, v_nxt)
            edges.add(e_side)
            elen.setdefault(e_side, side_length)

            tris.append((center, v_cur, v_nxt))

    return TriComplex(verts, edges, tris, elen)


# ════════════════════════════════════════════════════════════════════
#  6.  Regge angle-deficit curvature
# ════════════════════════════════════════════════════════════════════

def _triangle_angle(a: float, b: float, c: float) -> float:
    """Angle at vertex A in a triangle with sides a (opposite A), b, c."""
    # Law of cosines:  a² = b² + c² − 2bc cos(A)
    cos_A = (b * b + c * c - a * a) / (2.0 * b * c)
    cos_A = max(-1.0, min(1.0, cos_A))  # clamp for numerical safety
    return math.acos(cos_A)


def regge_curvature(
    tri: TriComplex,
    poly_cpx: PolyComplex,
) -> tuple[dict[str, float], dict[str, float]]:
    """
    Compute Regge angle-deficit curvature for the triangulated surface.

    For each triangle, compute angles from edge lengths via the law of
    cosines, then accumulate angle sums at each vertex.

    Uses the boundary classification from the *original* polygon complex
    (before triangulation), since all newly introduced center vertices
    are interior.

    Returns
    -------
    kappa_int : dict   interior vertex  →  κ(v) = 2π − Σ angles
    tau_bdy   : dict   boundary vertex  →  τ(v) = π  − Σ angles
    """
    angle_sum: dict[str, float] = defaultdict(float)

    for v0, v1, v2 in tri.faces:
        # Side lengths
        a = tri.edge_length[_edge(v1, v2)]  # opposite v0
        b = tri.edge_length[_edge(v0, v2)]  # opposite v1
        c = tri.edge_length[_edge(v0, v1)]  # opposite v2

        angle_sum[v0] += _triangle_angle(a, b, c)
        angle_sum[v1] += _triangle_angle(b, a, c)
        angle_sum[v2] += _triangle_angle(c, a, b)

    # Classify vertices: boundary = boundary of original complex
    # All center vertices (O_*) are interior by construction
    bverts = boundary_vertices(poly_cpx)

    kappa_int: dict[str, float] = {}
    tau_bdy: dict[str, float] = {}

    for v in tri.vertices:
        a = angle_sum.get(v, 0.0)
        if v in bverts:
            tau_bdy[v] = math.pi - a
        else:
            kappa_int[v] = 2.0 * math.pi - a

    return kappa_int, tau_bdy


# ════════════════════════════════════════════════════════════════════
#  7.  Display and verification
# ════════════════════════════════════════════════════════════════════

def _group_by_type(
    cpx: PolyComplex,
    curvatures: dict[str, object],
) -> dict[str, list[tuple[str, object]]]:
    """Group vertices by their 'type' for display (v, a, b, c, g, O)."""
    groups: dict[str, list[tuple[str, object]]] = defaultdict(list)
    for v in sorted(curvatures.keys()):
        if v.startswith("O_"):
            groups["center"].append((v, curvatures[v]))
        elif v.startswith("v"):
            groups["v (tiling vertex)"].append((v, curvatures[v]))
        elif v.startswith("a"):
            groups["a (N/G shared)"].append((v, curvatures[v]))
        elif v.startswith("b"):
            groups["b (N outer)"].append((v, curvatures[v]))
        elif v.startswith("c"):
            groups["c (N/G shared)"].append((v, curvatures[v]))
        elif v.startswith("g"):
            groups["g (G outer)"].append((v, curvatures[v]))
        else:
            groups["other"].append((v, curvatures[v]))
    return dict(groups)


def print_section(title: str) -> None:
    print(f"\n{'─' * 72}")
    print(f"  {title}")
    print(f"{'─' * 72}")


def main() -> None:
    print("╔═══════════════════════════════════════════════════════╗")
    print("║  Phase 1.2(b):  Discrete Curvature & Gauss–Bonnet     ║")
    print("║  {5,4} Tiling — 11-Tile Filled Patch                  ║")
    print("╚═══════════════════════════════════════════════════════╝")

    cpx = build_11tile_complex()
    chi = euler_characteristic(cpx)
    bverts = boundary_vertices(cpx)
    int_verts = cpx.vertices - bverts

    print(f"\n  Polygon complex:  V={len(cpx.vertices)}  "
          f"E={len(cpx.edges)}  F={len(cpx.faces)}")
    print(f"  Euler characteristic:  χ = {len(cpx.vertices)} − "
          f"{len(cpx.edges)} + {len(cpx.faces)} = {chi}")
    print(f"  Interior vertices: {len(int_verts)}   "
          f"Boundary vertices: {len(bverts)}")

    # ── (A) Combinatorial curvature ────────────────────────────────
    print_section("A.  Combinatorial Curvature")
    print("  κ(v) = 1 − deg(v)/2  +  Σ_{f ∋ v} 1/sides(f)")
    print("  Gauss–Bonnet:  Σ_v κ(v) = χ(K)")
    print()

    kappa_comb = combinatorial_curvature(cpx)
    total_comb = sum(kappa_comb.values(), Fraction(0))

    # Display grouped by vertex type
    groups = _group_by_type(cpx, kappa_comb)
    for gname in ["v (tiling vertex)", "a (N/G shared)", "b (N outer)",
                   "c (N/G shared)", "g (G outer)"]:
        if gname not in groups:
            continue
        entries = groups[gname]
        val = entries[0][1]
        label = entries[0][0]
        category = "int" if label in int_verts else "bdy"
        print(f"    {gname:<20s}  ×{len(entries):>2d}  "
              f"  κ = {str(val):>6s}  ({category})"
              f"  →  subtotal = {str(val * len(entries)):>6s}")

    print(f"\n    Total:  Σ κ(v) = {total_comb}  "
          f"{'✓' if total_comb == chi else '✗'}  (expected χ = {chi})")

    # ── (B) Angular curvature (Euclidean polygon angles) ───────────
    print_section("B.  Angular Curvature  (Euclidean Pentagon Angles)")
    print(f"  Regular pentagon interior angle:  "
          f"(5−2)·π/5 = 3π/5 = {3*180/5:.0f}°")
    print("  Interior:  κ(v) = 2π − Σ angles")
    print("  Boundary:  τ(v) = π  − Σ angles")
    print("  Gauss–Bonnet:  Σ_int κ + Σ_∂ τ = 2π·χ")
    print()

    kappa_ang, tau_ang = angular_curvature(cpx)

    sum_kappa = sum(kappa_ang.values())
    sum_tau = sum(tau_ang.values())
    total_ang = sum_kappa + sum_tau
    expected = 2.0 * math.pi * chi

    # Display grouped
    kall = dict(kappa_ang)
    kall.update(tau_ang)
    groups = _group_by_type(cpx, kall)
    for gname in ["v (tiling vertex)", "a (N/G shared)", "b (N outer)",
                   "c (N/G shared)", "g (G outer)"]:
        if gname not in groups:
            continue
        entries = groups[gname]
        val = entries[0][1]
        label = entries[0][0]
        category = "κ_int" if label in int_verts else "τ_bdy"
        deg_val = math.degrees(val)
        print(f"    {gname:<20s}  ×{len(entries):>2d}  "
              f"  {category} = {val:>8.4f} rad ({deg_val:>7.2f}°)"
              f"  →  subtotal = {val * len(entries):>8.4f}")

    print(f"\n    Σ_int κ  = {sum_kappa:>10.6f}  ({math.degrees(sum_kappa):>8.2f}°)")
    print(f"    Σ_∂   τ  = {sum_tau:>10.6f}  ({math.degrees(sum_tau):>8.2f}°)")
    print(f"    Total    = {total_ang:>10.6f}  ({math.degrees(total_ang):>8.2f}°)")
    print(f"    Expected = {expected:>10.6f}  ({math.degrees(expected):>8.2f}°)")
    ok = abs(total_ang - expected) < 1e-10
    print(f"    {'✓' if ok else '✗'}  "
          f"Gauss–Bonnet {'verified' if ok else 'FAILED'}  "
          f"(error = {abs(total_ang - expected):.2e})")

    # ── (C) Fan triangulation + Regge curvature ────────────────────
    print_section("C.  Regge Angle-Deficit Curvature  (Fan Triangulation)")

    tri = fan_triangulate(cpx, side_length=1.0)

    chi_tri = len(tri.vertices) - len(tri.edges) + len(tri.faces)
    print(f"\n  Triangulated complex:  V={len(tri.vertices)}  "
          f"E={len(tri.edges)}  F={len(tri.faces)}")
    print(f"  Euler characteristic:  χ = {chi_tri}  "
          f"(should equal {chi})")

    # Pentagon circumradius
    R = 1.0 / (2.0 * math.sin(math.pi / 5.0))
    print(f"  Pentagon side = 1.0,  circumradius R = {R:.6f}")
    print(f"  Fan triangle angles:  "
          f"apex = {math.degrees(2*math.pi/5):.1f}°,  "
          f"base = {math.degrees(math.pi/2 - math.pi/5):.1f}°")
    print()

    kappa_regge, tau_regge = regge_curvature(tri, cpx)

    sum_kappa_r = sum(kappa_regge.values())
    sum_tau_r = sum(tau_regge.values())
    total_regge = sum_kappa_r + sum_tau_r
    expected_r = 2.0 * math.pi * chi

    # Display interior vertex types
    print("  Interior vertices:")
    center_vals = [(v, k) for v, k in kappa_regge.items() if v.startswith("O_")]
    tiling_vals = [(v, k) for v, k in kappa_regge.items() if v.startswith("v")]
    if tiling_vals:
        val = tiling_vals[0][1]
        print(f"    Tiling vertices (v0..v4)  ×{len(tiling_vals):>2d}  "
              f"  κ = {val:>8.4f} rad ({math.degrees(val):>7.2f}°)")
    if center_vals:
        val = center_vals[0][1]
        print(f"    Center vertices (O_*)     ×{len(center_vals):>2d}  "
              f"  κ = {val:>8.4f} rad ({math.degrees(val):>7.2f}°)")

    # Display boundary vertex types
    print("  Boundary vertices:")
    kall_r = dict(tau_regge)
    groups_r = _group_by_type(cpx, kall_r)
    for gname in ["a (N/G shared)", "b (N outer)",
                   "c (N/G shared)", "g (G outer)"]:
        if gname not in groups_r:
            continue
        entries = groups_r[gname]
        val = entries[0][1]
        print(f"    {gname:<20s}  ×{len(entries):>2d}  "
              f"  τ = {val:>8.4f} rad ({math.degrees(val):>7.2f}°)")

    print(f"\n    Σ_int κ  = {sum_kappa_r:>10.6f}  ({math.degrees(sum_kappa_r):>8.2f}°)")
    print(f"    Σ_∂   τ  = {sum_tau_r:>10.6f}  ({math.degrees(sum_tau_r):>8.2f}°)")
    print(f"    Total    = {total_regge:>10.6f}  ({math.degrees(total_regge):>8.2f}°)")
    print(f"    Expected = {expected_r:>10.6f}  ({math.degrees(expected_r):>8.2f}°)")
    ok_r = abs(total_regge - expected_r) < 1e-10
    print(f"    {'✓' if ok_r else '✗'}  "
          f"Gauss–Bonnet {'verified' if ok_r else 'FAILED'}  "
          f"(error = {abs(total_regge - expected_r):.2e})")

    # ── Summary of key curvature values ────────────────────────────
    print_section("D.  Summary:  Key Curvature Values")
    print("""
    ┌──────────────────────────┬────────────┬─────────────┬─────────────┐
    │  Vertex type             │ Combinat.  │  Angular    │  Regge      │
    │                          │  κ (exact) │  (radians)  │  (radians)  │
    ├──────────────────────────┼────────────┼─────────────┼─────────────┤
    │  Interior tiling  (v_i)  │   −1/5     │  −2π/5      │  −2π/5      │
    │  Center (O_*)  [tri only]│     —      │     —       │    0        │
    │  Bdy: a_i, c_i  (shared) │  −1/10     │   −π/5      │   −π/5      │
    │  Bdy: b_i       (N only) │   1/5      │   2π/5      │   2π/5      │
    │  Bdy: g_i^1,2   (G only) │   1/5      │   2π/5      │   2π/5      │
    └──────────────────────────┴────────────┴─────────────┴─────────────┘

    The {5,4} tiling is hyperbolic: interior vertices have κ < 0.
    At each interior vertex, 4 regular pentagons meet; the Euclidean
    angle sum is 4 × 108° = 432° > 360°, giving a negative deficit
    of −72° = −2π/5 rad.

    All three formulations (combinatorial, angular, Regge) verify
    Gauss–Bonnet for the 11-tile disk patch  (χ = 1).

    These values provide the numerical evidence for Phase 2B: Agda
    formalization of discrete Gauss–Bonnet on the HaPPY-code bulk
    triangulation.
""")


if __name__ == "__main__":
    main()