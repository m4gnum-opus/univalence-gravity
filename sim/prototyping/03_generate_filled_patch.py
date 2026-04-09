#!/usr/bin/env python3
"""
03_generate_filled_patch.py  —  Phase 3.5 Agda Code Generator

Generates five Cubical Agda modules for the 11-tile filled patch
bridge, implementing the combined Approach A+C strategy from
§3.6 of docs/10-frontier.md.

This script is the "external oracle" (Approach C): it enumerates
all 90 contiguous tile-aligned boundary regions and all 360
adjacent-union triples, computes the min-cut values and subadditivity
witnesses in Python, and emits complete Agda modules whose proofs
are each a single  (k , refl)  line.  Agda is the "checker" that
verifies each line individually.

The subadditivity proof is wrapped in  abstract  (Approach A) so
that downstream modules never re-unfold the 360 cases, halting
the RAM cascade documented in §3.4 and Agda GitHub Issue #4573.

Generated modules:
  src/Common/FilledSpec.agda              90 Region + 360 union ctors
  src/Boundary/FilledCut.agda             90 S-cut clauses
  src/Bulk/FilledChain.agda               90 L-min clauses
  src/Boundary/FilledSubadditivity.agda   360 abstract subadditivity
  src/Bridge/FilledObs.agda               90 pointwise refl proofs

Usage (from repository root):
  python3 sim/prototyping/03_generate_filled_patch.py

  python3 sim/prototyping/03_generate_filled_patch.py --dry-run
      (compute and verify without writing files)

  python3 sim/prototyping/03_generate_filled_patch.py --output-dir /path/to/src
      (write to a custom source directory)

Dependencies:  networkx  (pip install networkx)

Reference:
  docs/10-frontier.md §3  (The 11-Tile Bridge)
  docs/09-happy-instance.md §3.2  (N-Singleton Discrepancy)
  sim/prototyping/01_happy_patch_cuts.py  (graph logic)
"""

from __future__ import annotations

import argparse
import importlib
import sys
import textwrap
from pathlib import Path
from typing import NamedTuple


# ════════════════════════════════════════════════════════════════════
#  0.  Import graph logic from 01_happy_patch_cuts
# ════════════════════════════════════════════════════════════════════

SCRIPT_DIR = Path(__file__).resolve().parent

sys.path.insert(0, str(SCRIPT_DIR))
try:
    cuts = importlib.import_module("01_happy_patch_cuts")
except ModuleNotFoundError:
    sys.exit(
        "ERROR: Could not import 01_happy_patch_cuts.py.\n"
        "       Run this script from the repository root:\n"
        "         python3 sim/prototyping/03_generate_filled_patch.py"
    )

DEFAULT_SRC_DIR = SCRIPT_DIR.parent.parent / "src"


# ════════════════════════════════════════════════════════════════════
#  1.  Patch topology constants
# ════════════════════════════════════════════════════════════════════

# Cyclic boundary order of the 11-tile filled patch.
# Each entry is (tile_name, number_of_boundary_legs).
# Source: §2.2 of docs/09-happy-instance.md
BOUNDARY_GROUPS: list[tuple[str, int]] = [
    ("N0", 2), ("G1", 3), ("N1", 2), ("G2", 3), ("N2", 2),
    ("G3", 3), ("N3", 2), ("G4", 3), ("N4", 2), ("G0", 3),
]

N_GROUPS = len(BOUNDARY_GROUPS)  # 10


# ════════════════════════════════════════════════════════════════════
#  2.  Data structures for computed results
# ════════════════════════════════════════════════════════════════════

class RegionData(NamedTuple):
    """One of the 90 contiguous tile-aligned boundary regions."""
    start: int          # index of first boundary group  (0..9)
    length: int         # number of boundary groups  (1..9)
    tiles: list[str]    # tile names in the region
    min_cut: int        # true min-cut value (boundary bonds allowed)


class UnionTriple(NamedTuple):
    """One of the 360 adjacent-union subadditivity triples."""
    start_a: int        # start index of region A
    len_a: int          # length of region A
    len_b: int          # length of region B  (starts at start_a + len_a)
    s_ab: int           # S(A ∪ B)
    s_a: int            # S(A)
    s_b: int            # S(B)
    k: int              # slack:  k + S(A∪B) = S(A) + S(B)


# ════════════════════════════════════════════════════════════════════
#  3.  Compute all regions and min-cut values
# ════════════════════════════════════════════════════════════════════

def _build_leg_offsets() -> list[tuple[int, int]]:
    """Map each boundary group index to its (start_leg, end_leg) range."""
    offsets: list[tuple[int, int]] = []
    leg = 0
    for _, n_legs in BOUNDARY_GROUPS:
        offsets.append((leg, leg + n_legs))
        leg += n_legs
    return offsets


def _group_legs(start: int, length: int,
                offsets: list[tuple[int, int]]) -> set[int]:
    """Return the set of boundary-leg indices for a contiguous region."""
    s: set[int] = set()
    for k in range(length):
        g = (start + k) % N_GROUPS
        lo, hi = offsets[g]
        s.update(range(lo, hi))
    return s


def compute_all_regions() -> list[RegionData]:
    """
    Enumerate all 90 nonempty proper contiguous tile-aligned regions
    and compute their true min-cut values (boundary bonds at capacity 1).

    Returns a list of 90 RegionData, ordered by (length, start).
    """
    patch = cuts.make_filled_patch()
    G, legs, _ = cuts.build_flow_graph(patch, boundary_cap=1)
    offsets = _build_leg_offsets()

    regions: list[RegionData] = []
    for length in range(1, N_GROUPS):            # 1..9
        for start in range(N_GROUPS):            # 0..9
            tiles = [
                BOUNDARY_GROUPS[(start + k) % N_GROUPS][0]
                for k in range(length)
            ]
            idx_set = _group_legs(start, length, offsets)
            s = cuts.compute_min_cut(G, legs, idx_set)
            regions.append(RegionData(start, length, tiles, s))

    assert len(regions) == 90, f"Expected 90 regions, got {len(regions)}"
    return regions


def compute_union_triples(
    regions: list[RegionData],
) -> list[UnionTriple]:
    """
    Enumerate all 360 valid adjacent-union triples and compute the
    subadditivity witness  k = S(A) + S(B) - S(A∪B)  for each.

    Raises AssertionError if subadditivity is violated for any triple.
    """
    # Build lookup:  (start, length) → min_cut
    lookup: dict[tuple[int, int], int] = {}
    for r in regions:
        lookup[(r.start, r.length)] = r.min_cut

    triples: list[UnionTriple] = []
    for start_a in range(N_GROUPS):
        for len_a in range(1, N_GROUPS - 1):     # 1..8
            for len_b in range(1, N_GROUPS - len_a):  # 1..(9-len_a)
                len_ab = len_a + len_b
                if len_ab >= N_GROUPS:
                    continue

                start_b = (start_a + len_a) % N_GROUPS
                s_a = lookup.get((start_a, len_a))
                s_b = lookup.get((start_b, len_b))
                s_ab = lookup.get((start_a, len_ab))

                if s_a is None or s_b is None or s_ab is None:
                    continue

                k = s_a + s_b - s_ab
                assert k >= 0, (
                    f"Subadditivity VIOLATION at "
                    f"start={start_a} lenA={len_a} lenB={len_b}: "
                    f"S(A∪B)={s_ab} > S(A)+S(B)={s_a}+{s_b}"
                )
                triples.append(
                    UnionTriple(start_a, len_a, len_b, s_ab, s_a, s_b, k)
                )

    assert len(triples) == 360, (
        f"Expected 360 union triples, got {len(triples)}"
    )
    return triples


# ════════════════════════════════════════════════════════════════════
#  4.  Agda naming helpers
# ════════════════════════════════════════════════════════════════════

def region_name(start: int, length: int) -> str:
    """Agda constructor name for a region.  e.g. r0x1, r3x5."""
    return f"r{start}x{length}"


def union_name(start_a: int, len_a: int, len_b: int) -> str:
    """Agda constructor for a union triple.  e.g. u0-1-1."""
    return f"u{start_a}-{len_a}-{len_b}"


def tiles_comment(start: int, length: int) -> str:
    """Human-readable tile list for inline Agda comments."""
    tiles = [
        BOUNDARY_GROUPS[(start + k) % N_GROUPS][0]
        for k in range(length)
    ]
    return "{" + ", ".join(tiles) + "}"


# ════════════════════════════════════════════════════════════════════
#  5.  Agda file generators
# ════════════════════════════════════════════════════════════════════

GENERATED_BANNER = (
    "--  Generated by sim/prototyping/03_generate_filled_patch.py\n"
    "--  Do not edit by hand.  Regenerate with:\n"
    "--    python3 sim/prototyping/03_generate_filled_patch.py"
)


def generate_filled_spec(
    regions: list[RegionData],
    triples: list[UnionTriple],
) -> str:
    """Generate  Common/FilledSpec.agda ."""
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a("module Common.FilledSpec where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a("")

    # ── FilledTile ──────────────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  FilledTile — 11 pentagonal tiles of the filled patch")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("data FilledTile : Type₀ where")
    a("  C N0 N1 N2 N3 N4 G0 G1 G2 G3 G4 : FilledTile")
    a("")

    # ── FilledRegion ────────────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  FilledRegion — 90 contiguous tile-aligned boundary regions")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  Cyclic boundary order (10 groups, 25 legs total):")
    a("--    N0(2), G1(3), N1(2), G2(3), N2(2),")
    a("--    G3(3), N3(2), G4(3), N4(2), G0(3)")
    a("--")
    a("--  Naming: r⟨start⟩x⟨length⟩")
    a("--    start  = index of first boundary group (0..9)")
    a("--    length = number of consecutive groups   (1..9)")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("data FilledRegion : Type₀ where")

    for length in range(1, N_GROUPS):
        names = [region_name(s, length) for s in range(N_GROUPS)]
        tiles_info = "  --  " + "  |  ".join(
            tiles_comment(s, length) for s in range(min(3, N_GROUPS))
        ) + "  ..."
        a(f"  -- size {length}")
        a(f"  {' '.join(names)} : FilledRegion")
    a("")

    # ── Union relation ──────────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  _∪F_≡F_ — Region union relation (360 constructors)")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  A witness  u : rA ∪F rB ≡F rAB  asserts that region rA")
    a("--  is immediately followed (cyclically) by rB, and their")
    a("--  concatenation is rAB.")
    a("--")
    a("--  Constructor naming:  u⟨startA⟩-⟨lenA⟩-⟨lenB⟩")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("data _∪F_≡F_ : FilledRegion → FilledRegion → FilledRegion"
      " → Type₀ where")
    a("")

    prev_len_a = -1
    for t in triples:
        if t.len_a != prev_len_a:
            a(f"  -- ── lenA = {t.len_a}"
              f"  ({N_GROUPS - 1 - t.len_a} lenB values"
              f" × {N_GROUPS} starts"
              f" = {(N_GROUPS - 1 - t.len_a) * N_GROUPS} cases)"
              f" ──")
            prev_len_a = t.len_a

        start_b = (t.start_a + t.len_a) % N_GROUPS
        len_ab = t.len_a + t.len_b
        rA = region_name(t.start_a, t.len_a)
        rB = region_name(start_b, t.len_b)
        rAB = region_name(t.start_a, len_ab)
        uname = union_name(t.start_a, t.len_a, t.len_b)
        a(f"  {uname} : {rA} ∪F {rB} ≡F {rAB}")

    a("")
    return "\n".join(L) + "\n"


def generate_filled_cut(regions: list[RegionData]) -> str:
    """Generate  Boundary/FilledCut.agda ."""
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a("module Boundary.FilledCut where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a("open import Common.FilledSpec")
    a("")
    a("-- ════════════════════════════════════════════════════════════")
    a("--  FilledBdyView — Boundary-side view (architectural wrapper)")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("record FilledBdyView : Type₀ where")
    a("  field")
    a("    dummy : ℚ≥0")
    a("")
    a("-- ════════════════════════════════════════════════════════════")
    a("--  S-cut — Boundary min-cut for the 11-tile filled patch")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  Under the N-singleton resolution (§3.2, docs/10-frontier.md),")
    a("--  the boundary min-cut allows severing both internal bonds and")
    a("--  boundary legs, giving the true min-cut for every region.")
    a("--")
    a("--  The FilledBdyView argument is accepted but not inspected,")
    a("--  following the specification-level lookup pattern from the")
    a("--  tree and star instances.")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("S-cut : FilledBdyView → FilledRegion → ℚ≥0")

    for r in regions:
        rn = region_name(r.start, r.length)
        tc = tiles_comment(r.start, r.length)
        a(f"S-cut _ {rn} = {r.min_cut}    -- {tc}")

    a("")
    return "\n".join(L) + "\n"


def generate_filled_chain(regions: list[RegionData]) -> str:
    """Generate  Bulk/FilledChain.agda ."""
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a("module Bulk.FilledChain where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a("open import Common.FilledSpec")
    a("")
    a("-- ════════════════════════════════════════════════════════════")
    a("--  FilledBulkView — Bulk-side view (architectural wrapper)")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("record FilledBulkView : Type₀ where")
    a("  field")
    a("    dummy : ℚ≥0")
    a("")
    a("-- ════════════════════════════════════════════════════════════")
    a("--  L-min — Bulk minimal separating chain (redefined)")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  Under the N-singleton resolution (§3.2, docs/10-frontier.md),")
    a("--  the bulk observable is the true min-cut (allowing boundary")
    a("--  bonds to be severed), matching S-cut on all 90 regions.")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("L-min : FilledBulkView → FilledRegion → ℚ≥0")

    for r in regions:
        rn = region_name(r.start, r.length)
        tc = tiles_comment(r.start, r.length)
        a(f"L-min _ {rn} = {r.min_cut}    -- {tc}")

    a("")
    return "\n".join(L) + "\n"


def generate_filled_subadditivity(
    regions: list[RegionData],
    triples: list[UnionTriple],
) -> str:
    """Generate  Boundary/FilledSubadditivity.agda ."""
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a("module Boundary.FilledSubadditivity where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Cubical.Data.Nat using (ℕ ; _+_)")
    a("open import Util.Scalars")
    a("open import Common.FilledSpec")
    a("")

    # ── S-filled (local observable function) ────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  S-filled — Min-cut entropy on all 90 regions")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  Self-contained lookup table (not importing S-cut from")
    a("--  Boundary.FilledCut) to avoid cross-module re-normalization.")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("S-filled : FilledRegion → ℚ≥0")

    for r in regions:
        rn = region_name(r.start, r.length)
        a(f"S-filled {rn} = {r.min_cut}")

    a("")

    # ── Subadditivity (abstract) ────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  subadditivity — S(A ∪ B) ≤ S(A) + S(B)  (360 cases)")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  Wrapped in  abstract  so that downstream modules")
    a("--  (Bridge/FilledEquiv.agda) never re-unfold the 360-case")
    a("--  proof when they use the subadditivity lemma.")
    a("--")
    a("--  Since  _≤ℚ_  is propositional (by isProp≤ℚ, proven in")
    a("--  Bridge/FullEnrichedStarObs.agda), sealing the proof")
    a("--  does not damage the Univalence bridge.")
    a("--")
    a("--  Each witness  (k , refl)  type-checks because")
    a("--  k + S(A∪B)  reduces judgmentally to  S(A) + S(B)")
    a("--  via ℕ addition on closed numerals.")
    a("--")
    a("--  Reference: §3.5 Approach A (abstract keyword)")
    a("--             §3.6 (combined A+C strategy)")
    a("--             Agda GitHub Issue #4573")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("abstract")
    a("  subadditivity :")
    a("    ∀ {r₁ r₂ r₃ : FilledRegion}")
    a("    → r₁ ∪F r₂ ≡F r₃")
    a("    → S-filled r₃ ≤ℚ (S-filled r₁ +ℚ S-filled r₂)")

    # Group by (len_a, len_b) for readability
    prev_key = (-1, -1)
    for t in triples:
        key = (t.len_a, t.len_b)
        if key != prev_key:
            sa_ex = t.s_a
            sb_ex = t.s_b
            sab_ex = t.s_ab
            a(f"  -- lenA={t.len_a}, lenB={t.len_b}:"
              f"  S(A∪B)={sab_ex} ≤ S(A)+S(B)={sa_ex}+{sb_ex}"
              f"={sa_ex + sb_ex}")
            prev_key = key
        uname = union_name(t.start_a, t.len_a, t.len_b)
        a(f"  subadditivity {uname} = {t.k} , refl")

    a("")
    return "\n".join(L) + "\n"


def generate_filled_obs(regions: list[RegionData]) -> str:
    """Generate  Bridge/FilledObs.agda ."""
    L: list[str] = []
    a = L.append

    a("{-# OPTIONS --cubical --safe --guardedness #-}")
    a("")
    a("module Bridge.FilledObs where")
    a("")
    a("open import Cubical.Foundations.Prelude")
    a("open import Util.Scalars")
    a("open import Common.FilledSpec")
    a("open import Common.ObsPackage")
    a("open import Boundary.FilledCut")
    a("open import Bulk.FilledChain")
    a("")

    # ── Canonical views ─────────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  Canonical views (dummy instances)")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("filledBdyView : FilledBdyView")
    a("filledBdyView .FilledBdyView.dummy = 0")
    a("")
    a("filledBulkView : FilledBulkView")
    a("filledBulkView .FilledBulkView.dummy = 0")
    a("")

    # ── Observable packages ─────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  Observable packages for the 11-tile filled patch")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("FilledObs∂ : ObsPackage FilledRegion")
    a("FilledObs∂ .ObsPackage.obs = S-cut filledBdyView")
    a("")
    a("FilledObsBulk : ObsPackage FilledRegion")
    a("FilledObsBulk .ObsPackage.obs = L-min filledBulkView")
    a("")

    # ── Pointwise agreement ─────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  filled-pointwise — All 90 cases hold by refl")
    a("-- ════════════════════════════════════════════════════════════")
    a("--")
    a("--  Both S-cut and L-min return the same ℕ literal for each")
    a("--  region (both are the true min-cut under the N-singleton")
    a("--  resolution of §3.2, docs/10-frontier.md).")
    a("--")
    a(GENERATED_BANNER)
    a("")
    a("filled-pointwise :")
    a("  (r : FilledRegion) →")
    a("  S-cut filledBdyView r ≡ L-min filledBulkView r")

    for r in regions:
        rn = region_name(r.start, r.length)
        a(f"filled-pointwise {rn} = refl")

    a("")

    # ── Function path ───────────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  filled-obs-path — Function equality via funExt")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("filled-obs-path :")
    a("  S-cut filledBdyView ≡ L-min filledBulkView")
    a("filled-obs-path = funExt filled-pointwise")
    a("")

    # ── Package path ────────────────────────────────────────────────
    a("-- ════════════════════════════════════════════════════════════")
    a("--  filled-package-path — Package-level path")
    a("-- ════════════════════════════════════════════════════════════")
    a("")
    a("filled-package-path : FilledObs∂ ≡ FilledObsBulk")
    a("filled-package-path i .ObsPackage.obs = filled-obs-path i")
    a("")

    return "\n".join(L) + "\n"


# ════════════════════════════════════════════════════════════════════
#  6.  File writing
# ════════════════════════════════════════════════════════════════════

FILE_MAP: list[tuple[str, str]] = [
    # (relative path from src/, generator function name)
    ("Common/FilledSpec.agda",              "spec"),
    ("Boundary/FilledCut.agda",             "cut"),
    ("Bulk/FilledChain.agda",               "chain"),
    ("Boundary/FilledSubadditivity.agda",   "subadd"),
    ("Bridge/FilledObs.agda",               "obs"),
]


def write_file(path: Path, content: str, dry_run: bool) -> None:
    """Write content to path, creating parent directories as needed."""
    if dry_run:
        lines = content.count("\n")
        print(f"  [dry-run]  {path}  ({lines} lines)")
        return

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    lines = content.count("\n")
    print(f"  ✓  {path}  ({lines} lines)")


# ════════════════════════════════════════════════════════════════════
#  7.  Summary statistics
# ════════════════════════════════════════════════════════════════════

def print_summary(
    regions: list[RegionData],
    triples: list[UnionTriple],
) -> None:
    """Print a human-readable summary of the computed data."""

    # Min-cut distribution
    from collections import Counter
    cut_dist = Counter(r.min_cut for r in regions)

    print("\n  ── Min-cut value distribution (90 regions) ──")
    for val in sorted(cut_dist):
        print(f"    S = {val}  :  {cut_dist[val]} regions")

    # Complement symmetry check
    lookup = {(r.start, r.length): r.min_cut for r in regions}
    sym_ok = 0
    for r in regions:
        comp_start = (r.start + r.length) % N_GROUPS
        comp_length = N_GROUPS - r.length
        if comp_length > 0:
            s_comp = lookup.get((comp_start, comp_length))
            if s_comp is not None and s_comp == r.min_cut:
                sym_ok += 1
    print(f"\n  Complement symmetry:  {sym_ok}/{len(regions)} verified")

    # Subadditivity witness distribution
    k_dist = Counter(t.k for t in triples)
    print(f"\n  ── Subadditivity witness distribution (360 triples) ──")
    for val in sorted(k_dist):
        print(f"    k = {val}  :  {k_dist[val]} cases")

    print()


# ════════════════════════════════════════════════════════════════════
#  8.  Main
# ════════════════════════════════════════════════════════════════════

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Cubical Agda modules for the 11-tile "
                    "filled patch bridge.")
    parser.add_argument(
        "--output-dir", type=Path, default=DEFAULT_SRC_DIR,
        help="Root source directory (default: ../../src relative to script)")
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Compute and verify without writing files")
    args = parser.parse_args()

    print("╔══════════════════════════════════════════════════════════╗")
    print("║  Phase 3.5:  11-Tile Filled Patch — Agda Code Generator  ║")
    print("║  Strategy: Approach A (abstract) + C (external oracle)   ║")
    print("╚══════════════════════════════════════════════════════════╝")

    # ── Step 1: Compute all regions ─────────────────────────────────
    print("\n  Computing min-cut values for 90 regions ...")
    regions = compute_all_regions()
    print(f"  ✓  {len(regions)} regions computed.")

    # ── Step 2: Compute all union triples ───────────────────────────
    print("  Computing 360 subadditivity witnesses ...")
    triples = compute_union_triples(regions)
    print(f"  ✓  {len(triples)} triples computed, all subadditive.")

    # ── Step 3: Print summary ───────────────────────────────────────
    print_summary(regions, triples)

    # ── Step 4: Generate and write files ────────────────────────────
    src_dir = args.output_dir.resolve()
    print(f"  Output directory: {src_dir}")
    if args.dry_run:
        print("  [DRY RUN — no files will be written]\n")
    print()

    generators = {
        "spec":   lambda: generate_filled_spec(regions, triples),
        "cut":    lambda: generate_filled_cut(regions),
        "chain":  lambda: generate_filled_chain(regions),
        "subadd": lambda: generate_filled_subadditivity(regions, triples),
        "obs":    lambda: generate_filled_obs(regions),
    }

    total_lines = 0
    for rel_path, gen_key in FILE_MAP:
        content = generators[gen_key]()
        full_path = src_dir / rel_path
        write_file(full_path, content, args.dry_run)
        total_lines += content.count("\n")

    # ── Step 5: Final report ────────────────────────────────────────
    action = "would generate" if args.dry_run else "generated"
    print(f"\n  ── Summary: {action} {len(FILE_MAP)} files, "
          f"~{total_lines} lines total ──")
    print()
    print("  Next steps:")
    print("    1. Load each generated file in Agda to verify it")
    print("       type-checks (expect ~10-30 min total).")
    print("    2. Implement  Bridge/FilledEquiv.agda  manually to")
    print("       assemble the type equivalence and verify transport.")
    print("    3. Commit the generator to sim/prototyping/ with a")
    print("       Dockerfile or nix shell pinning the Python environment.")
    print()


if __name__ == "__main__":
    main()