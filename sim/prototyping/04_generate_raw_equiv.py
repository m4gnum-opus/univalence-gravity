#!/usr/bin/env python3
"""
04_generate_raw_equiv.py  —  Raw Structural Equivalence Oracle

Generates  Bridge/FilledRawEquiv.agda  for the 11-tile filled patch:
the first raw type-level holographic equivalence on a complete 2D
hyperbolic disk.

Strategy (Option 2 — Reconstruction Fiber, §4.5 of 10-frontier.md):

  1. Define a 15-constructor FilledBond type for the internal bonds.
  2. Forward map  (Ryu–Takayanagi):  express each of 90 min-cut
     values as a sum of bond weights or a constant.
  3. Backward map (Holographic reconstruction):  recover each of 15
     bond weights via G-singleton peeling + truncated subtraction.
  4. Both raw types are contractible (singleton Σ-types), so the
     round-trip proofs use  isContr→isProp  and the specification-
     agreement lemmas (all refl) are the only proof obligations.

Dependencies:  networkx  (pip install networkx)

Usage (from repository root):
  python3 sim/prototyping/04_generate_raw_equiv.py
  python3 sim/prototyping/04_generate_raw_equiv.py --dry-run
"""

from __future__ import annotations

import argparse
import importlib
import sys
from pathlib import Path
from typing import NamedTuple

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

try:
    cuts = importlib.import_module("01_happy_patch_cuts")
except ModuleNotFoundError:
    sys.exit(
        "ERROR: Could not import 01_happy_patch_cuts.py.\n"
        "       Run from the repository root."
    )

DEFAULT_SRC_DIR = SCRIPT_DIR.parent.parent / "src"


# ════════════════════════════════════════════════════════════════════
#  1.  Patch topology
# ════════════════════════════════════════════════════════════════════

BOUNDARY_GROUPS: list[tuple[str, int]] = [
    ("N0", 2), ("G1", 3), ("N1", 2), ("G2", 3), ("N2", 2),
    ("G3", 3), ("N3", 2), ("G4", 3), ("N4", 2), ("G0", 3),
]
N_GROUPS = len(BOUNDARY_GROUPS)

# The 15 internal bonds as (tile1, tile2) pairs, in canonical order.
BONDS: list[tuple[str, str]] = []
for i in range(5):
    BONDS.append(("C", f"N{i}"))
for i in range(5):
    BONDS.append((f"G{i}", f"N{(i - 1) % 5}"))
    BONDS.append((f"G{i}", f"N{i}"))

# Agda constructor name for each bond
BOND_AGDA: list[str] = []
for t1, t2 in BONDS:
    BOND_AGDA.append(f"b{t1}{t2}")

# Map (tile1, tile2) → bond index  (undirected: check both orders)
BOND_INDEX: dict[tuple[str, str], int] = {}
for idx, (t1, t2) in enumerate(BONDS):
    BOND_INDEX[(t1, t2)] = idx
    BOND_INDEX[(t2, t1)] = idx


# ════════════════════════════════════════════════════════════════════
#  2.  Region computation (reusing 01_happy_patch_cuts logic)
# ════════════════════════════════════════════════════════════════════

class RegionInfo(NamedTuple):
    start: int
    length: int
    tiles: list[str]
    min_cut: int
    internal_cut_bonds: list[int]   # bond indices in the internal cut
    uses_boundary_legs: bool        # True if S < internal cut cost


def region_name(start: int, length: int) -> str:
    return f"r{start}x{length}"


def tiles_comment(start: int, length: int) -> str:
    tiles = [BOUNDARY_GROUPS[(start + k) % N_GROUPS][0]
             for k in range(length)]
    return "{" + ", ".join(tiles) + "}"


def _build_leg_offsets() -> list[tuple[int, int]]:
    offsets, leg = [], 0
    for _, n_legs in BOUNDARY_GROUPS:
        offsets.append((leg, leg + n_legs))
        leg += n_legs
    return offsets


def _group_legs(start: int, length: int,
                offsets: list[tuple[int, int]]) -> set[int]:
    s: set[int] = set()
    for k in range(length):
        g = (start + k) % N_GROUPS
        lo, hi = offsets[g]
        s.update(range(lo, hi))
    return s


def compute_all_regions() -> list[RegionInfo]:
    """Compute all 90 regions with min-cut values and cut composition."""
    patch = cuts.make_filled_patch()
    G, legs, _ = cuts.build_flow_graph(patch, boundary_cap=1)
    offsets = _build_leg_offsets()

    all_tiles = {"C"} | {f"N{i}" for i in range(5)} | {f"G{i}" for i in range(5)}

    regions: list[RegionInfo] = []
    for length in range(1, N_GROUPS):
        for start in range(N_GROUPS):
            tiles = [BOUNDARY_GROUPS[(start + k) % N_GROUPS][0]
                     for k in range(length)]
            tile_set = set(tiles)
            complement = all_tiles - tile_set

            # Internal bonds crossing the cut
            crossing: list[int] = []
            for idx, (t1, t2) in enumerate(BONDS):
                if (t1 in tile_set) != (t2 in tile_set):
                    crossing.append(idx)

            internal_cost = len(crossing)

            # Actual min-cut via max-flow
            idx_set = _group_legs(start, length, offsets)
            s = cuts.compute_min_cut(G, legs, idx_set)

            uses_bdy = s < internal_cost

            regions.append(RegionInfo(
                start, length, tiles, s, crossing, uses_bdy
            ))

    assert len(regions) == 90
    return regions


# ════════════════════════════════════════════════════════════════════
#  3.  Forward map expression builder
# ════════════════════════════════════════════════════════════════════

def forward_expr(r: RegionInfo) -> str:
    """Build the Agda RHS for  minCutFromWeights w <region>."""
    if r.uses_boundary_legs:
        # Constant — min-cut goes through boundary legs
        return str(r.min_cut)
    else:
        # Sum of bond weights
        assert len(r.internal_cut_bonds) == r.min_cut
        parts = [f"w {BOND_AGDA[idx]}" for idx in r.internal_cut_bonds]
        return " +ℚ ".join(parts)


# ════════════════════════════════════════════════════════════════════
#  4.  Backward map design (peeling strategy)
# ════════════════════════════════════════════════════════════════════

class BackwardClause(NamedTuple):
    bond_idx: int
    bond_name: str
    expr: str           # Agda expression in f
    comment: str


def design_backward_map() -> list[BackwardClause]:
    """
    Design the 15 clauses for weightsFromMinCut.

    G-bonds:  f(r_{Gi}) ∸ 1  =  2 ∸ 1  =  1
    C-bonds:  f(r_{Ni,G_{i+1}}) ∸ f(r_{G_{i+1}})  =  3 ∸ 2  =  1
    """
    # G-singleton region indices in the cyclic boundary order
    # Boundary order: N0(0), G1(1), N1(2), G2(3), N2(4),
    #                 G3(5), N3(6), G4(7), N4(8), G0(9)
    g_region = {
        "G0": "r9x1", "G1": "r1x1", "G2": "r3x1",
        "G3": "r5x1", "G4": "r7x1",
    }

    # N-G pair regions (N_i followed by G_{i+1})
    # {N0,G1}=r0x2, {N1,G2}=r2x2, {N2,G3}=r4x2,
    # {N3,G4}=r6x2, {N4,G0}=r8x2
    ng_pair = {
        0: "r0x2", 1: "r2x2", 2: "r4x2", 3: "r6x2", 4: "r8x2"
    }
    # The G-singleton used for each C-N_i bond subtraction
    g_for_c = {
        0: "r1x1",  # G1 singleton for C-N0
        1: "r3x1",  # G2 singleton for C-N1
        2: "r5x1",  # G3 singleton for C-N2
        3: "r7x1",  # G4 singleton for C-N3
        4: "r9x1",  # G0 singleton for C-N4
    }

    clauses: list[BackwardClause] = []

    for idx, (t1, t2) in enumerate(BONDS):
        bname = BOND_AGDA[idx]

        if t1 == "C":
            # C-bond: C-N_i
            i = int(t2[1])
            pair_r = ng_pair[i]
            g_r = g_for_c[i]
            expr = f"f {pair_r} ∸ f {g_r}"
            gi_name = f"G{(i + 1) % 5}"
            comment = (f"S({{N{i},{gi_name}}}) ∸ S({{{gi_name}}}) "
                       f"= 3 ∸ 2 = 1")
            clauses.append(BackwardClause(idx, bname, expr, comment))
        else:
            # G-bond: G_i - N_j
            gi = t1  # e.g. "G0"
            r = g_region[gi]
            expr = f"f {r} ∸ 1"
            comment = f"S({{{gi}}}) ∸ 1 = 2 ∸ 1 = 1"
            clauses.append(BackwardClause(idx, bname, expr, comment))

    assert len(clauses) == 15
    return clauses


# ════════════════════════════════════════════════════════════════════
#  5.  Verification at canonical instance
# ════════════════════════════════════════════════════════════════════

def verify(regions: list[RegionInfo],
           backward: list[BackwardClause]) -> None:
    """Verify the RT lemma and extraction lemma numerically."""
    # All bond weights are 1
    w = {BOND_AGDA[i]: 1 for i in range(15)}

    # S∂F values
    s_vals = {region_name(r.start, r.length): r.min_cut for r in regions}

    # Check forward map: minCutFromWeights filledWeight r = S∂F r
    for r in regions:
        if r.uses_boundary_legs:
            computed = r.min_cut  # constant
        else:
            computed = sum(1 for _ in r.internal_cut_bonds)
        assert computed == r.min_cut, (
            f"RT lemma fails at {region_name(r.start, r.length)}: "
            f"computed {computed} ≠ expected {r.min_cut}"
        )

    # Check backward map: weightsFromMinCut S∂F b = 1 for all b
    for c in backward:
        # Parse the expression and evaluate
        expr = c.expr
        if "∸" in expr:
            parts = expr.split("∸")
            left = parts[0].strip()
            right = parts[1].strip()
            if left.startswith("f "):
                left_val = s_vals[left[2:]]
            else:
                left_val = int(left)
            if right.startswith("f "):
                right_val = s_vals[right[2:]]
            else:
                right_val = int(right)
            result = max(0, left_val - right_val)
        else:
            result = int(expr)
        assert result == 1, (
            f"Extraction lemma fails at {c.bond_name}: "
            f"computed {result} ≠ expected 1"
        )

    print("  ✓  RT lemma verified (90 cases)")
    print("  ✓  Extraction lemma verified (15 cases)")


# ════════════════════════════════════════════════════════════════════
#  6.  Agda code generation
# ════════════════════════════════════════════════════════════════════

BANNER = (
    "--  Generated by sim/prototyping/04_generate_raw_equiv.py\n"
    "--  Do not edit by hand.  Regenerate with:\n"
    "--    python3 sim/prototyping/04_generate_raw_equiv.py"
)


def generate_module(regions: list[RegionInfo],
                    backward: list[BackwardClause]) -> str:
    L: list[str] = []
    a = L.append

    # ── Header ──────────────────────────────────────────────────────
    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a("module Bridge.FilledRawEquiv where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Cubical.Foundations.Equiv")
    a("open import Cubical.Foundations.Univalence")
    a("open import Cubical.Foundations.Isomorphism")
    a("open import Cubical.Foundations.HLevels")
    a("open import Cubical.Foundations.Transport")
    a("")
    a("open import Cubical.Data.Nat using (ℕ ; zero ; suc ; _+_)")
    a("open import Cubical.Data.Sigma using (ΣPathP)")
    a("")
    a("open import Util.Scalars")
    a("open import Common.FilledSpec")
    a("open import Boundary.FilledCut")
    a("open import Bulk.FilledChain")
    a("open import Bridge.FilledObs")
    a("  using ( filled-obs-path ; filledBdyView ; filledBulkView )")
    a("")
    a(BANNER)
    a("")

    # ── §1.  Truncated subtraction ──────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §1.  Truncated subtraction (monus)")
    a("-- ═══════════════════════════════════════════════════════════")
    a("--")
    a("--  Defined locally to guarantee judgmental computation.")
    a("--  suc (suc (suc zero)) ∸ suc (suc zero)  reduces to")
    a("--  suc zero  by structural recursion.  This is critical")
    a("--  for the 15 refl proofs in the extraction lemma.")
    a("--")
    a("")
    a("private")
    a("  _∸_ : ℕ → ℕ → ℕ")
    a("  zero  ∸ _     = zero")
    a("  suc m ∸ zero  = suc m")
    a("  suc m ∸ suc n = m ∸ n")
    a("")

    # ── §2.  FilledBond type ────────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §2.  FilledBond — 15 internal tile-to-tile bonds")
    a("-- ═══════════════════════════════════════════════════════════")
    a("--")
    a("--  5 C-bonds:  C–N_i           (central to neighbours)")
    a("-- 10 G-bonds:  G_i–N_{i−1},  G_i–N_i  (gap-fillers)")
    a("--")
    a("")
    a("data FilledBond : Type₀ where")

    # Group bonds for readability
    c_bonds = [BOND_AGDA[i] for i in range(5)]
    a(f"  {' '.join(c_bonds)} : FilledBond")
    for i in range(5):
        g_bonds = [BOND_AGDA[5 + 2*i], BOND_AGDA[5 + 2*i + 1]]
        a(f"  {' '.join(g_bonds)} : FilledBond")
    a("")

    # ── §3.  Canonical weight function ──────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §3.  Canonical weight function (all bonds weight 1)")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("filledWeight : FilledBond → ℚ≥0")
    a("filledWeight _ = 1")
    a("")

    # ── §4.  Shorthand observables ──────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §4.  Shorthand names for canonical observables")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("S∂F : FilledRegion → ℚ≥0")
    a("S∂F = S-cut filledBdyView")
    a("")
    a("LBF : FilledRegion → ℚ≥0")
    a("LBF = L-min filledBulkView")
    a("")

    # ── §5.  h-Level infrastructure ─────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §5.  h-Level infrastructure")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("isSetRegionObs : isSet (FilledRegion → ℚ≥0)")
    a("isSetRegionObs = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)")
    a("")
    a("isSetBondW : isSet (FilledBond → ℚ≥0)")
    a("isSetBondW = isOfHLevelΠ 2 (λ _ → isSetℚ≥0)")
    a("")

    # ── §6.  Raw structural types ──────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §6.  Raw structural types")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("RawFilledBdy : Type₀")
    a("RawFilledBdy = Σ[ f ∈ (FilledRegion → ℚ≥0) ] (f ≡ S∂F)")
    a("")
    a("RawFilledBulk : Type₀")
    a("RawFilledBulk = Σ[ w ∈ (FilledBond → ℚ≥0) ] (w ≡ filledWeight)")
    a("")

    # ── §7.  Canonical inhabitants ──────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §7.  Canonical inhabitants")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("raw-filled-bdy : RawFilledBdy")
    a("raw-filled-bdy = S∂F , refl")
    a("")
    a("raw-filled-bulk : RawFilledBulk")
    a("raw-filled-bulk = filledWeight , refl")
    a("")

    # ── §8.  Forward map (RT direction) ─────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §8.  Forward map — Ryu–Takayanagi computation")
    a("-- ═══════════════════════════════════════════════════════════")
    a("--")
    a("--  Given 15 bond weights, compute the 90 min-cut values.")
    a("--  For 80 regions the min-cut is a sum of internal bonds.")
    a("--  For 10 regions (N-singletons and complements) the")
    a("--  min-cut severs boundary legs and is a constant.")
    a("--")
    a(BANNER)
    a("")
    a("minCutFromWeights : (FilledBond → ℚ≥0)"
      " → (FilledRegion → ℚ≥0)")

    for r in regions:
        rn = region_name(r.start, r.length)
        expr = forward_expr(r)
        tc = tiles_comment(r.start, r.length)
        tag = "  -- bdy legs" if r.uses_boundary_legs else ""
        a(f"minCutFromWeights w {rn} = {expr}    -- {tc}{tag}")

    a("")

    # ── §9.  Backward map (reconstruction) ──────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §9.  Backward map — Holographic reconstruction")
    a("-- ═══════════════════════════════════════════════════════════")
    a("--")
    a("--  Recover each bond weight from min-cut values.")
    a("--  G-bonds:  f(G_i singleton) ∸ 1  =  2 ∸ 1  =  1")
    a("--  C-bonds:  f(N_i,G_{i+1} pair) ∸ f(G_{i+1} singleton)")
    a("--           =  3 ∸ 2  =  1")
    a("--")
    a(BANNER)
    a("")
    a("weightsFromMinCut : (FilledRegion → ℚ≥0)"
      " → (FilledBond → ℚ≥0)")

    for c in backward:
        a(f"weightsFromMinCut f {c.bond_name}"
          f" = {c.expr}    -- {c.comment}")

    a("")

    # ── §10.  RT lemma ──────────────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §10.  RT lemma — forward map on canonical weights = S∂F")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("rt-pointwise : (r : FilledRegion)"
      " → minCutFromWeights filledWeight r ≡ S∂F r")

    for r in regions:
        rn = region_name(r.start, r.length)
        a(f"rt-pointwise {rn} = refl")

    a("")
    a("rt-lemma : minCutFromWeights filledWeight ≡ S∂F")
    a("rt-lemma = funExt rt-pointwise")
    a("")

    # ── §11.  Extraction lemma ──────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §11.  Extraction lemma — backward map on S∂F = filledWeight")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("extr-pointwise : (b : FilledBond)"
      " → weightsFromMinCut S∂F b ≡ filledWeight b")

    for c in backward:
        a(f"extr-pointwise {c.bond_name} = refl")

    a("")
    a("extr-lemma : weightsFromMinCut S∂F ≡ filledWeight")
    a("extr-lemma = funExt extr-pointwise")
    a("")

    # ── §12.  Contractibility ───────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §12.  Contractibility of both raw types")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("private")
    a("  isContrRevSingl : ∀ {ℓ} {A : Type ℓ} (a : A)")
    a("    → isContr (Σ[ x ∈ A ] (x ≡ a))")
    a("  isContrRevSingl a .fst = a , refl")
    a("  isContrRevSingl a .snd (x , p) i =")
    a("    p (~ i) , λ j → p (~ i ∨ j)")
    a("")
    a("isContr-RawBdy : isContr RawFilledBdy")
    a("isContr-RawBdy = isContrRevSingl S∂F")
    a("")
    a("isContr-RawBulk : isContr RawFilledBulk")
    a("isContr-RawBulk = isContrRevSingl filledWeight")
    a("")

    # ── §13.  The Iso ───────────────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §13.  The Iso between raw types")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("raw-filled-iso : Iso RawFilledBulk RawFilledBdy")
    a("raw-filled-iso = iso fwd bwd fwd-bwd bwd-fwd")
    a("  where")
    a("    fwd : RawFilledBulk → RawFilledBdy")
    a("    fwd (w , p) ="
      " minCutFromWeights w ,"
      " cong minCutFromWeights p ∙ rt-lemma")
    a("")
    a("    bwd : RawFilledBdy → RawFilledBulk")
    a("    bwd (f , q) ="
      " weightsFromMinCut f ,"
      " cong weightsFromMinCut q ∙ extr-lemma")
    a("")
    a("    fwd-bwd : (b : RawFilledBdy) → fwd (bwd b) ≡ b")
    a("    fwd-bwd b ="
      " isContr→isProp isContr-RawBdy (fwd (bwd b)) b")
    a("")
    a("    bwd-fwd : (a : RawFilledBulk) → bwd (fwd a) ≡ a")
    a("    bwd-fwd a ="
      " isContr→isProp isContr-RawBulk (bwd (fwd a)) a")
    a("")

    # ── §14.  Equiv, ua, transport ──────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §14.  Equivalence, Univalence path, and transport")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("raw-filled-equiv : RawFilledBulk ≃ RawFilledBdy")
    a("raw-filled-equiv = isoToEquiv raw-filled-iso")
    a("")
    a("raw-filled-ua-path : RawFilledBulk ≡ RawFilledBdy")
    a("raw-filled-ua-path = ua raw-filled-equiv")
    a("")
    a("raw-filled-transport-computes :")
    a("  transport raw-filled-ua-path raw-filled-bulk")
    a("  ≡ equivFun raw-filled-equiv raw-filled-bulk")
    a("raw-filled-transport-computes ="
      " uaβ raw-filled-equiv raw-filled-bulk")
    a("")

    a("private")
    a("  raw-fwd-eq-bdy :"
      " equivFun raw-filled-equiv raw-filled-bulk"
      " ≡ raw-filled-bdy")
    a("  raw-fwd-eq-bdy ="
      " isContr→isProp isContr-RawBdy _ _")
    a("")

    a("raw-filled-transport :")
    a("  transport raw-filled-ua-path raw-filled-bulk"
      " ≡ raw-filled-bdy")
    a("raw-filled-transport ="
      " raw-filled-transport-computes ∙ raw-fwd-eq-bdy")
    a("")

    a("raw-filled-transport-obs :")
    a("  fst (transport raw-filled-ua-path raw-filled-bulk) ≡ S∂F")
    a("raw-filled-transport-obs = cong fst raw-filled-transport")
    a("")

    # ── §15.  Reverse transport ─────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §15.  Reverse transport and roundtrip")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("raw-filled-reverse :")
    a("  transport (sym raw-filled-ua-path) raw-filled-bdy"
      " ≡ raw-filled-bulk")
    a("raw-filled-reverse =")
    a("    cong (transport (sym raw-filled-ua-path))"
      " (sym raw-filled-transport)")
    a("  ∙ transport⁻Transport raw-filled-ua-path raw-filled-bulk")
    a("")
    a("raw-filled-roundtrip-bulk :")
    a("  transport (sym raw-filled-ua-path)")
    a("    (transport raw-filled-ua-path raw-filled-bulk)")
    a("  ≡ raw-filled-bulk")
    a("raw-filled-roundtrip-bulk ="
      " transport⁻Transport raw-filled-ua-path raw-filled-bulk")
    a("")
    a("raw-filled-roundtrip-bdy :")
    a("  transport raw-filled-ua-path")
    a("    (transport (sym raw-filled-ua-path) raw-filled-bdy)")
    a("  ≡ raw-filled-bdy")
    a("raw-filled-roundtrip-bdy ="
      " transportTransport⁻ raw-filled-ua-path raw-filled-bdy")
    a("")

    # ── §16.  Milestone record ──────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §16.  RawFilledBridgeWitness")
    a("-- ═══════════════════════════════════════════════════════════")
    a("")
    a("record RawFilledBridgeWitness : Type₁ where")
    a("  field")
    a("    BulkTy             : Type₀")
    a("    BdyTy              : Type₀")
    a("    bulk-data          : BulkTy")
    a("    bdy-data           : BdyTy")
    a("    bridge             : BulkTy ≃ BdyTy")
    a("    transport-verified :"
      " transport (ua bridge) bulk-data ≡ bdy-data")
    a("")
    a("raw-filled-bridge-witness : RawFilledBridgeWitness")
    a("raw-filled-bridge-witness"
      " .RawFilledBridgeWitness.BulkTy"
      "             = RawFilledBulk")
    a("raw-filled-bridge-witness"
      " .RawFilledBridgeWitness.BdyTy"
      "              = RawFilledBdy")
    a("raw-filled-bridge-witness"
      " .RawFilledBridgeWitness.bulk-data"
      "          = raw-filled-bulk")
    a("raw-filled-bridge-witness"
      " .RawFilledBridgeWitness.bdy-data"
      "           = raw-filled-bdy")
    a("raw-filled-bridge-witness"
      " .RawFilledBridgeWitness.bridge"
      "             = raw-filled-equiv")
    a("raw-filled-bridge-witness"
      " .RawFilledBridgeWitness.transport-verified"
      " = raw-filled-transport")
    a("")

    # ── §17.  Compatibility ─────────────────────────────────────────
    a("-- ═══════════════════════════════════════════════════════════")
    a("--  §17.  Compatibility with observable-level bridge")
    a("-- ═══════════════════════════════════════════════════════════")
    a("--")
    a("--  The raw transport's extracted function S∂F is the same")
    a("--  function used in Bridge/FilledEquiv.agda, so the raw")
    a("--  structural equivalence is compatible with the enriched")
    a("--  observable-package equivalence.")
    a("--")
    a("")
    a("raw-filled-obs-coherence :")
    a("  fst (transport raw-filled-ua-path raw-filled-bulk) ≡ S∂F")
    a("raw-filled-obs-coherence = raw-filled-transport-obs")
    a("")
    a("raw-filled-bulk-coherence :")
    a("  fst (transport raw-filled-ua-path raw-filled-bulk) ≡ LBF")
    a("raw-filled-bulk-coherence ="
      " raw-filled-transport-obs ∙ filled-obs-path")
    a("")

    return "\n".join(L) + "\n"


# ════════════════════════════════════════════════════════════════════
#  7.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Bridge/FilledRawEquiv.agda")
    parser.add_argument("--output-dir", type=Path,
                        default=DEFAULT_SRC_DIR)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    print("╔═════════════════════════════════════════════════════════╗")
    print("║  04: Raw Structural Equivalence — 11-Tile Filled Patch  ║")
    print("║  Option 2 (Reconstruction Fiber) + Peeling Strategy     ║")
    print("╚═════════════════════════════════════════════════════════╝")

    # Step 1: compute regions
    print("\n  Computing 90 regions with min-cut composition ...")
    regions = compute_all_regions()

    n_bdy = sum(1 for r in regions if r.uses_boundary_legs)
    n_clean = len(regions) - n_bdy
    print(f"  ✓  {n_clean} internal-bond regions, "
          f"{n_bdy} boundary-leg regions")

    # Step 2: design backward map
    print("  Designing backward map (peeling strategy) ...")
    backward = design_backward_map()
    print(f"  ✓  {len(backward)} extraction clauses")

    # Step 3: verify
    print("  Verifying specification-agreement lemmas ...")
    verify(regions, backward)

    # Step 4: generate
    content = generate_module(regions, backward)
    lines = content.count("\n")

    out_path = args.output_dir.resolve() / "Bridge" / "FilledRawEquiv.agda"
    if args.dry_run:
        print(f"\n  [dry-run]  {out_path}  ({lines} lines)")
    else:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(content, encoding="utf-8")
        print(f"\n  ✓  {out_path}  ({lines} lines)")

    # Summary
    print(f"\n  ── Summary ──")
    print(f"  FilledBond constructors:     15")
    print(f"  Forward map clauses:         90"
          f"  ({n_clean} bond sums + {n_bdy} constants)")
    print(f"  Backward map clauses:        15"
          f"  (10 G-peels + 5 C-peels)")
    print(f"  RT lemma cases:              90  (all refl)")
    print(f"  Extraction lemma cases:      15  (all refl)")
    print(f"  Total generated Agda lines: ~{lines}")
    print()


if __name__ == "__main__":
    main()