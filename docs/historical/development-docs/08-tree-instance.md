# Tree Instance

## 1. Purpose

This document fixes the smallest end-to-end pilot instance used in **Phase 1.1**
to validate the repository architecture in a form that is immediately useful for
Cubical Agda implementation.

The instance should support the following pipeline:

1. define a **common source specification**,
2. extract a **boundary view** and a **bulk view**,
3. define two **observable packages** over a shared finite region type,
4. prove their observable functions agree by **finite case split**,
5. build the first exact equivalence used later with Univalence.

This instance is intentionally **1-dimensional** on the bulk side: the bulk
carrier is a weighted tree, not yet the final 2-dimensional simplicial complex
of the main project. Its role is to validate the **formal packaging and bridge
machinery** before introducing faces, curvature, and more elaborate geometry.

---

## 2. Formalization Strategy

This document is written as an **Agda-facing specification**. The intended
implementation style is:

- use **small finite datatypes** rather than abstract finite sets,
- use **explicit lookup functions** rather than search procedures,
- use **record types with minimal fields**,
- prove equalities by **case split** on a finite region datatype,
- keep all proof fields either absent or proposition-valued in the first pass.
- ensure that carrier types (`Region`, `ℚ≥0`) are **sets** (h-level 2) so that
  function extensionality and record paths behave as expected — this is true
  automatically for datatypes without path constructors and for standard
  rational representations, but should be stated as an explicit obligation.

The tree instance should be the first place where the repository tests:

- finite boundary indexing,
- view extraction,
- observable packaging,
- equivalence construction,
- and later, the `ua` bridge.

---

## 3. Agda-Level Carrier Types

The simplest implementation is to make both vertices and regions explicit
enumerated datatypes.

### 3.1 Vertices

Shape:

```agda
{-# OPTIONS --cubical --safe #-}
module TreeInstanceSketch where

open import Cubical.Foundations.Prelude

data Vertex : Type where
  L₁ L₂ R₁ R₂ A B Root : Vertex
```

This is preferable to `Fin 7` in the first implementation because:

- it makes pattern matching readable,
- proofs are easier to inspect,
- later equivalences to `Fin 7` can be added separately if needed.

### 3.2 Undirected edges

Use a six-constructor edge type rather than representing edges as arbitrary
pairs of vertices. This avoids having to quotient by symmetry in the first pass.

```agda
data Edge : Type where
  eL₁A eL₂A eARoot eRootB eBR₁ eBR₂ : Edge
```

An incidence map may then recover endpoints:

```agda
endpoints : Edge → Vertex × Vertex
```

where `endpoints` is defined by explicit lookup.

### 3.3 Boundary regions

For the cyclic ordering \(L_1, L_2, R_1, R_2\), the nonempty proper contiguous
intervals consist of:

- 4 singletons,
- 4 adjacent pairs,
- 4 triple intervals.

For the tree pilot, we choose an explicit **representative region type** with
8 constructors:

```agda
data Region : Type where
  regL₁    : Region
  regL₂    : Region
  regR₁    : Region
  regR₂    : Region
  regL₁L₂  : Region
  regL₂R₁  : Region
  regR₁R₂  : Region
  regR₂L₁  : Region
```

This choice is deliberate:

- empty and full regions are omitted,
- triple intervals are omitted because each is the complement of a singleton,
- all four adjacent pairs are kept explicitly, even though complementary pairs
  have equal values, because this makes Agda case splits transparent.

---

## 4. Common Source Specification

At the architectural level, the tree instance is a single source term \(c : C\)
from which both views are extracted.

For the first implementation, `C` should be a concrete record specialized to
this pilot instance.

### 4.1 Record shape

```agda
record TreeSpec : Type where
  field
    boundaryOrder : Vertex × Vertex × Vertex × Vertex
    edgeWeight    : Edge → ℚ≥0
```

where `ℚ≥0 : Type` is the repository’s chosen nonnegative rational type.

**Implementation note on `ℚ≥0`.**
The `agda/cubical` library does not ship a dedicated nonnegative-rational type
with literal syntax.  Two pragmatic options for the pilot:

1. Use `Cubical.HITs.Rationals.QuoQ` (or a `Cubical.Data.Rationals` variant)
   and carry a non-negativity proof as a wrapper.
2. Define a minimal `ℚ≥0` record in `Util/Scalars.agda` wrapping a pair
   `(q , 0≤q)`.

The constants `1q` and `2q` below assume whichever representation is chosen
gives **judgmentally stable normal forms**: two terms built from the same
canonical numerator and denominator must be definitionally equal, because the
`refl` proofs in §9.2 depend on this.  See also §11.5.

### 4.2 Canonical instance

The intended unique tree specification is:

- boundary order = `(L₁ , L₂ , R₁ , R₂)`,
- weights:
  - `eL₁A   ↦ 1`
  - `eL₂A   ↦ 1`
  - `eARoot ↦ 2`
  - `eRootB ↦ 2`
  - `eBR₁   ↦ 1`
  - `eBR₂   ↦ 1`

Agda shape:

```agda
treeWeight : Edge → ℚ≥0
treeWeight eL₁A   = 1q
treeWeight eL₂A   = 1q
treeWeight eARoot = 2q
treeWeight eRootB = 2q
treeWeight eBR₁   = 1q
treeWeight eBR₂   = 1q

treeSpec : TreeSpec
treeSpec .TreeSpec.boundaryOrder = (L₁ , L₂ , R₁ , R₂)
treeSpec .TreeSpec.edgeWeight    = treeWeight
```

Here `1q` and `2q` stand for the chosen rational constants in the future
`Util.Scalars` layer.

### 4.3 Design note

For this first instance, do **not** over-generalize `TreeSpec`. The point is to
test the bridge architecture, not to solve generic graph search.

---

## 5. Extracted Views

The architecture distinguishes between **views** and **observable packages**.

### 5.1 Boundary view

The boundary view is the weighted tree interpreted as a boundary-side cut system.

Shape:

```agda
record BoundaryView : Type where
  field
    weight : Edge → ℚ≥0
```

For the pilot instance, `BoundaryView` may be intentionally minimal.

### 5.2 Bulk view

The bulk view is the same weighted tree interpreted as a 1-dimensional pilot
bulk geometry.

Shape:

```agda
record BulkView : Type where
  field
    weight : Edge → ℚ≥0
```

### 5.3 Extraction functions

Signatures:

```agda
π∂ : TreeSpec → BoundaryView
πbulk : TreeSpec → BulkView
```

with the obvious definitions:

```agda
π∂ c .BoundaryView.weight = TreeSpec.edgeWeight c
πbulk c .BulkView.weight  = TreeSpec.edgeWeight c
```

For the tree instance, the two views are intentionally distinct wrappers around
the same weight data.  They differ semantically rather than structurally.  This
is acceptable and intentional: it means the extraction step is structurally
trivial for this pilot.  The purpose of having two distinct wrapper types is to
validate the **interface contract** (`π∂` returns a `BoundaryView`, `πbulk`
returns a `BulkView`) that later instances will fill with genuinely different
structure.

---

## 6. Observable Functions

The core computational content of the tree instance is captured by two total
functions out of `Region`.

### 6.1 Boundary min-cut observable

Signature:

```agda
S-cut : BoundaryView → Region → ℚ≥0
```

In the first implementation, `S-cut` should be defined by explicit lookup,
not by a generic cut-search algorithm.

Definition pattern:

```agda
S-cut bv regL₁   = 1q
S-cut bv regL₂   = 1q
S-cut bv regR₁   = 1q
S-cut bv regR₂   = 1q
S-cut bv regL₁L₂ = 2q
S-cut bv regL₂R₁ = 2q
S-cut bv regR₁R₂ = 2q
S-cut bv regR₂L₁ = 2q
```

The mathematical justification is the finite separator table recorded below.

### 6.2 Bulk minimal separating-chain observable

Signature:

```agda
L-min : BulkView → Region → ℚ≥0
```

Again, for the tree pilot this should be defined by explicit lookup:

```agda
L-min kv regL₁   = 1q
L-min kv regL₂   = 1q
L-min kv regR₁   = 1q
L-min kv regR₂   = 1q
L-min kv regL₁L₂ = 2q
L-min kv regL₂R₁ = 2q
L-min kv regR₁R₂ = 2q
L-min kv regR₂L₁ = 2q
```

### 6.3 Why explicit lookup is the right first step

At this stage, the goal is not to formalize min-cut algorithms. The goal is to
test:

- package shape,
- finite indexing,
- equality proofs,
- and bridge construction.

In particular, the observable functions in this pilot are
**specification-level lookup realizations** justified by the source data and the
finite separator table below, not yet generic minimization procedures computed
from the weight function.

Note that `S-cut` and `L-min` above accept a `BoundaryView` / `BulkView`
argument but **do not inspect it**: every clause returns a fixed constant.
This is deliberate — the lookup table IS the specification for this instance.
In a future generic implementation, the observable functions would compute from
the weight data inside their respective views.

Generic graph algorithms can be introduced later, after the architecture has
been validated on this known-good instance.

---

## 7. Explicit Mathematical Table

The values of the observables agree on every representative region:

| Region \(\mathcal{R}\) | Minimal separator | Value |
|---|---|---:|
| \(\{L_1\}\) | \(\{L_1,A\}\) | 1 |
| \(\{L_2\}\) | \(\{L_2,A\}\) | 1 |
| \(\{R_1\}\) | \(\{B,R_1\}\) | 1 |
| \(\{R_2\}\) | \(\{B,R_2\}\) | 1 |
| \(\{L_1,L_2\}\) | \(\{A,\mathrm{Root}\}\) | 2 |
| \(\{L_2,R_1\}\) | \(\{L_2,A\}, \{B,R_1\}\) | 2 |
| \(\{R_1,R_2\}\) | \(\{\mathrm{Root},B\}\) | 2 |
| \(\{R_2,L_1\}\) | \(\{L_1,A\}, \{B,R_2\}\) | 2 |

This table is the external mathematical justification for the explicit Agda
lookup definitions above.

---

## 8. Observable Package Shapes

For the tree pilot, the observable packages should be kept minimal.

### 8.1 Minimal package record

```agda
record ObsPackage (R : Type) : Type where
  field
    obs : R → ℚ≥0
```

The region index is a **parameter** rather than a stored field.  This avoids a
universe-level error: storing `RegionIx : Type` as a field would force the
record into `Type₁`, since it quantifies over types in `Type₀`.  Making it a
parameter keeps `ObsPackage Region` in `Type₀` where the rest of the pipeline
expects it.  Later instances with heterogeneous index types can introduce a
Sigma wrapper or universe-polymorphic variant.

### 8.2 Boundary and bulk packages

Definitions:

```agda
Obs∂ : TreeSpec → ObsPackage Region
Obs∂ c .ObsPackage.obs = S-cut (π∂ c)

ObsBulk : TreeSpec → ObsPackage Region
ObsBulk c .ObsPackage.obs = L-min (πbulk c)
```

Because the record has a single field, package equality reduces directly to
observable-function equality via `tree-obs-path`.  Any richer package should be
added only after the minimal bridge succeeds, and any additional proof fields
should be proposition-valued and explicitly tied to the observable data.

> keep the package minimal until the end-to-end equivalence and transport work.

---

## 9. Explicit Proof Obligations

This section states the intended Agda lemmas in dependency order.

### 9.1 Canonical extracted views

These are definitional or by reflexivity once the lookup tables are fixed.

```agda
+boundaryView : BoundaryView
+bulkView     : BulkView
```

In practice, these are just the extracted views `π∂ treeSpec` and
`πbulk treeSpec`.

### 9.2 Pointwise observable agreement

This is the central proof for the tree instance.

Statement:

```agda
tree-pointwise :
  (r : Region) →
  S-cut (π∂ treeSpec) r ≡ L-min (πbulk treeSpec) r
```

Proof method: complete pattern match on `r`.

```agda
tree-pointwise regL₁   = refl
tree-pointwise regL₂   = refl
tree-pointwise regR₁   = refl
tree-pointwise regR₂   = refl
tree-pointwise regL₁L₂ = refl
tree-pointwise regL₂R₁ = refl
tree-pointwise regR₁R₂ = refl
tree-pointwise regR₂L₁ = refl
```

If the observables are defined by the same canonical rational constants, this
proof should be entirely by `refl`.

### 9.3 Function equality of observables

Once pointwise equality is available, one can package it as a path between the
observable functions.

Statement:

```agda
tree-obs-path :
  S-cut (π∂ treeSpec) ≡ L-min (πbulk treeSpec)
```

In Cubical Agda, function extensionality is native to the path type:

```agda
tree-obs-path = funExt tree-pointwise
```

where `funExt` is re-exported by `Cubical.Foundations.Prelude`.  Unfolded, the
path term is `λ i r → tree-pointwise r i`.

### 9.4 Package path

With the parameterized record from §8.1, the package path is:

```agda
tree-package-path : Obs∂ treeSpec ≡ ObsBulk treeSpec
tree-package-path i .ObsPackage.obs = tree-obs-path i
```

Because `ObsPackage Region` has a single field, the record path is simply the
`obs`-field path wrapped in copattern/record syntax.

### 9.5 Relationship to Univalence

The path constructed above is a path between **values** of
`ObsPackage Region`.  It is *not* a path between **types** in a universe, so
`ua` does not directly apply to it.

For the architecture in
[§3.4](03-architecture.md#4-common-source-specification-and-observable-packages),
the Univalence bridge requires the observable packages to be **type families**:

```agda
Obs∂-Ty    : TreeSpec → Type
ObsBulk-Ty : TreeSpec → Type
```

For the tree pilot, both families would map to the same underlying type
(`Region → ℚ≥0`), making the equivalence `idEquiv` and the Univalence path
`refl` — transport along it is the identity function.  The meaningful
mathematical content (functional agreement) is fully captured by
`tree-obs-path` and `tree-package-path`.

The Univalence step becomes genuinely nontrivial only when the two sides carry
**different type structure** (e.g., different index types, additional
proof-carrying fields, or structurally different record shapes), which is
expected in the HaPPY-derived instance.  The tree pilot therefore validates
everything **up to but not including** a nontrivial `ua` application.

If a nontrivial Univalence calibration test on the tree is desired, one option
is to enrich the observable packages with asymmetric proof-carrying fields
(e.g., a subadditivity witness on the boundary side and a triangle-inequality
witness on the bulk side) and prove that the enriched record types are
equivalent.  This is a stretch goal for the tree pilot and should be attempted
only after the minimal bridge succeeds.

---

## 10. Recommended Proof Order

The implementation should proceed in the following order.

### Step 1: finite carriers

Define:

- `Vertex`
- `Edge`
- `Region`

and ensure all case splits normalize cleanly.

### Step 2: scalar constants

Provide a minimal nonnegative-rational interface sufficient for:

- `0q`
- `1q`
- `2q`

No arithmetic theory is required for the first version beyond canonical
constants whose normal forms are stable enough that identical lookup outputs
reduce to judgmentally equal terms.

### Step 3: common source and views

Define:

- `TreeSpec`
- `treeSpec`
- `BoundaryView`
- `BulkView`
- `π∂`
- `πbulk`

### Step 4: observable lookup tables

Define:

- `S-cut`
- `L-min`

by explicit case split.

### Step 5: agreement proof

Prove:

- `tree-pointwise`

and, if useful,

- `tree-obs-path`.

### Step 6: package construction

Define:

- `ObsPackage`
- `Obs∂`
- `ObsBulk`

### Step 7: package path

Construct:

- `tree-package-path`

### Step 7b (stretch): type-level equivalence

Optionally, define the type-family variants `Obs∂-Ty` and `ObsBulk-Ty` from
§9.5, construct `idEquiv`, apply `ua`, and verify that `transport` along the
resulting path is the identity.  This calibrates the `ua` machinery on a
known-trivial case before the HaPPY instance introduces real content.

Only after Step 7 (or 7b) succeeds should the repository move to larger
instances.

---

## 11. Design Constraints for Cubical Agda

The tree instance should obey the following constraints.

### 11.1 Use explicit finite datatypes

Do not begin with:

- abstract finite sets,
- quotient-like edge encodings,
- generic graph search,
- or high-level automation.

Those all obscure the real issue if the first bridge fails.

### 11.2 Keep proof fields out of the first package

If proof-relevant fields are inserted too early, package equality becomes
harder than necessary. The first package should contain only:

- the region index type,
- the observable function.

### 11.3 Prefer definitional equality where possible

The most successful first implementation is the one in which:

- `RegionIx` is literally the same type on both sides,
- observable outputs are literally the same constants,
- pointwise agreement is by `refl` in each case.

This is not “cheating”; it is the correct sanity check for the representation
architecture.

### 11.4 Defer generic algorithms

This document specifies a **pilot correctness witness**, not a final algorithmic
library. Search procedures, minimization proofs, and generic graph lemmas belong
after the architecture has been validated.

### 11.5 Ensure judgmental equality of scalar constants

The `refl` proofs in §9.2 require that `1q` appearing in `S-cut` and `1q`
appearing in `L-min` reduce to the **same normal form**.  If the `ℚ≥0`
representation introduces hidden proof terms (e.g., positivity witnesses
constructed by different derivation paths), normal forms may diverge and `refl`
will fail.

Mitigation: define each constant (`0q`, `1q`, `2q`) **once** in
`Util/Scalars.agda` and import it into both `Boundary/TreeCut.agda` and
`Bulk/TreeChain.agda`.  Do not reconstruct the constants independently on each
side.

---

## 12. Minimal Agda Module Slate

A clean first pass would split the implementation into the following files.

```text
src/Util/Scalars.agda
src/Common/TreeSpec.agda
src/Boundary/TreeCut.agda
src/Bulk/TreeChain.agda
src/Bridge/TreeObs.agda
src/Bridge/TreeEquiv.agda
```

Responsibilities:

- `Util/Scalars.agda`
  - `ℚ≥0`, `0q`, `1q`, `2q`, and basic ordering (if needed)

- `Common/TreeSpec.agda`
  - `Vertex`, `Edge`, `Region`, `TreeSpec`, `treeSpec`

- `Boundary/TreeCut.agda`
  - `BoundaryView`, `π∂`, `S-cut`

- `Bulk/TreeChain.agda`
  - `BulkView`, `πbulk`, `L-min`

- `Bridge/TreeObs.agda`
  - `ObsPackage`, `Obs∂`, `ObsBulk`, `tree-pointwise`

- `Bridge/TreeEquiv.agda`
  - `tree-obs-path`, `tree-package-path`

This keeps the first bridge small, inspectable, and easy to refactor.

---

## 13. Success Criterion for This Document

This tree instance counts as successfully formalized if the repository can
define:

- the common source term,
- both extracted views,
- both observable packages,
- the pointwise agreement proof on `Region`,
- and a resulting package path.

If that end-to-end pipeline does not type-check cleanly, then the failure should
be treated as a **representation-design problem** and fixed here before any move
to a HaPPY-style hyperbolic patch.

---

## 14. Why This Instance Matters

This tree instance is not physically ambitious. Its importance is
methodological.

It is the first place where the repository can test, in a controlled and fully
finite setting, the exact pattern that later phases depend on:

1. one source specification,
2. two extracted views,
3. shared region indexing,
4. equal observables,
5. a direct package path.

The tree is therefore the repository’s first **bridge calibration object**.

The tree instance does **not** exercise the Univalence step in a nontrivial way
(see §9.5).  It also does not test face/curvature data, heterogeneous index
types, or non-trivial proof-carrying fields.  Those aspects are deferred to the
HaPPY-derived instance by design.

Only after this succeeds should the project scale to a genuine HaPPY-derived
hyperbolic patch.