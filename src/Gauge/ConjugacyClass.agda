{-# OPTIONS --cubical --safe --guardedness #-}

module Gauge.ConjugacyClass where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat using (ℕ)
open import Cubical.Data.Empty using (⊥)

open import Gauge.FiniteGroup using (FiniteGroup ; Z2 ; e0 ; e1 ; ℤ/2)
open import Gauge.ZMod using (Z3 ; z0 ; z1 ; z2 ; ℤ/3 ; Z2-comm ; Z3-comm)
open import Gauge.Q8
  using (Q8 ; q1 ; qn1 ; qi ; qni ; qj ; qnj ; qk ; qnk ; Q₈)


-- ════════════════════════════════════════════════════════════════════
--  Conjugacy Class Computation and Particle Species Classification
-- ════════════════════════════════════════════════════════════════════
--
--  This module defines:
--
--    1. The conjugacy relation on a finite group:  g ~ h  iff
--       there exists k with  inv(k) · g · k ≡ h .
--
--    2. A proof that conjugation is trivial in abelian groups
--       (every element is its own conjugacy class).
--
--    3. Concrete conjugacy class types and classification functions
--       for ℤ/3ℤ (3 classes, abelian) and Q₈ (5 classes, non-abelian).
--
--    4. Machine-checked conjugacy witnesses for Q₈ demonstrating
--       that i ~ −i, j ~ −j, k ~ −k — all verified by refl.
--
--    5. The  sameSpecies  predicate: two holonomies produce the
--       same particle type iff they have the same conjugacy class.
--
--  The particle spectrum of a gauge group G is the set of non-identity
--  conjugacy classes.  It determines how many distinct "particle types"
--  exist in the discrete gauge theory:
--
--    | Group   | Elements | Conj. Classes | Particle Species |
--    |---------|----------|---------------|------------------|
--    | ℤ/2ℤ   |     2    |       2       |        1         |
--    | ℤ/3ℤ   |     3    |       3       |        2         |
--    | Q₈     |     8    |       5       |        4         |
--
--  Architectural role:
--    This is a Tier 2 (Observable / Geometry Layer) module in the
--    Gauge directory.  It defines the conjugacy relation and
--    particle species classification consumed by downstream modules.
--    The module sits between Gauge/Holonomy.agda (which produces
--    holonomy values) and Gauge/RepCapacity.agda (which maps
--    representations to scalar bond capacities).  The three-layer
--    gauge architecture is:
--      Gauge Layer:    FiniteGroup → Connection → Holonomy
--                      → ConjugacyClass (this) → ParticleDefect
--      Capacity Layer: RepCapacity (dim functor → scalar weights)
--      Bridge Layer:   GenericBridge (operates on scalar PatchData)
--    See docs/getting-started/architecture.md for the full module
--    dependency DAG.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §7    (conjugacy classes and
--                                          particle species —
--                                          formal treatment)
--    docs/formal/05-gauge-theory.md §7.1  (the conjugacy relation)
--    docs/formal/05-gauge-theory.md §7.3  (Q₈ conjugacy classes)
--    docs/formal/05-gauge-theory.md §7.4  (species classification)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — downstream)
--    docs/reference/module-index.md       (module description)
--    docs/getting-started/architecture.md (module dependency DAG)
--    docs/historical/development-docs/10-frontier.md §13.6
--                                         (original development plan —
--                                          conjugacy classes)
--    docs/historical/development-docs/10-frontier.md §13.9
--                                         (original Phase M.2)
--
--  Downstream modules:
--    src/Gauge/RepCapacity.agda  — SpinLabel, dim functor,
--                                  GaugedPatchWitness
-- ════════════════════════════════════════════════════════════════════


-- ════════════════════════════════════════════════════════════════════
--  §1.  General Conjugacy Infrastructure (parameterized by G)
-- ════════════════════════════════════════════════════════════════════
--
--  The  Conj  module is parameterized by an arbitrary FiniteGroup G.
--  It provides:
--    • The conjugacy relation  _~G_
--    • The abelian-self-conjugate lemma (conjugation is trivial
--      when the group is commutative)
--
--  Usage:
--    Conj._~G_ Q₈ qi qni  :  Type₀
--    (the type of witnesses that qi and qni are conjugate in Q₈)
--
--  Reference:
--    docs/formal/05-gauge-theory.md §7.1  (the conjugacy relation)
-- ════════════════════════════════════════════════════════════════════

module Conj (G : FiniteGroup) where
  open FiniteGroup G

  -- ── The conjugacy relation ───────────────────────────────────
  --
  --  Two group elements g and h are conjugate if there exists a
  --  "conjugating element" k such that  k⁻¹ · g · k ≡ h .
  --
  --  Note: _·_ is left-associative (infixl 7), so
  --  inv k · g · k  parses as  (inv k · g) · k .
  --
  --  In the physics interpretation, conjugation corresponds to a
  --  gauge transformation: if two face holonomies are conjugate,
  --  they carry the same gauge charge (same "particle species").
  --  See docs/formal/05-gauge-theory.md §7.1.

  infix 4 _~G_

  _~G_ : Carrier → Carrier → Type₀
  g ~G h = Σ[ k ∈ Carrier ] ((inv k · g) · k ≡ h)


  -- ── Abelian self-conjugacy ───────────────────────────────────
  --
  --  In an abelian (commutative) group, conjugation is trivial:
  --  inv(k) · g · k ≡ g  for any g and k.
  --
  --  Proof chain:
  --    (inv k · g) · k
  --    ≡ inv k · (g · k)      [·-assoc]
  --    ≡ inv k · (k · g)      [comm g k]
  --    ≡ (inv k · k) · g      [sym ·-assoc]
  --    ≡ ε · g                [·-inverseˡ]
  --    ≡ g                    [·-identityˡ]
  --
  --  For concrete abelian groups (ℤ/2, ℤ/3) where all axioms
  --  hold by refl on closed constructors, this composed path
  --  itself reduces to refl.
  --
  --  Reference:
  --    docs/formal/05-gauge-theory.md §7.2  (abelian groups:
  --                                          trivial conjugacy)

  abelian-self-conjugate :
    ((x y : Carrier) → x · y ≡ y · x)
    → (g k : Carrier) → (inv k · g) · k ≡ g
  abelian-self-conjugate comm g k =
      ·-assoc (inv k) g k
    ∙ cong (inv k ·_) (comm g k)
    ∙ sym (·-assoc (inv k) k g)
    ∙ cong (_· g) (·-inverseˡ k)
    ∙ ·-identityˡ g


  -- ── Abelian conjugacy implies every element is self-conjugate ─
  --
  --  In an abelian group, conj(g, k) = g for all k, so the
  --  conjugacy class of every element is a singleton: [g] = {g}.
  --  The witness for g ~ g is  (k , abelian-self-conjugate comm g k)
  --  for any k (but the simplest is k = ε).

  abelian-conjugate-to-self :
    ((x y : Carrier) → x · y ≡ y · x)
    → (g : Carrier) → g ~G g
  abelian-conjugate-to-self comm g = ε , abelian-self-conjugate comm g ε


-- ════════════════════════════════════════════════════════════════════
--  §2.  ℤ/2ℤ Conjugacy Classes (abelian — 2 classes)
-- ════════════════════════════════════════════════════════════════════
--
--  ℤ/2ℤ is abelian, so each element is its own conjugacy class:
--    {e0} → vacuum (identity)
--    {e1} → 1 particle species
--
--  Particle spectrum: 1 non-identity class → 1 species.
-- ════════════════════════════════════════════════════════════════════

data Z2ConjClass : Type₀ where
  cc-e0 cc-e1 : Z2ConjClass

classifyZ2 : Z2 → Z2ConjClass
classifyZ2 e0 = cc-e0
classifyZ2 e1 = cc-e1

nConjClassesZ2 : ℕ
nConjClassesZ2 = 2

-- Number of non-identity conjugacy classes = particle species
nSpeciesZ2 : ℕ
nSpeciesZ2 = 1

-- Abelian conjugacy proof for ℤ/2ℤ: conjugation is trivial
module Z2Conj where
  open FiniteGroup ℤ/2

  z2-abelian-conj : (g k : Z2) → (inv k · g) · k ≡ g
  z2-abelian-conj = Conj.abelian-self-conjugate ℤ/2 Z2-comm


-- ════════════════════════════════════════════════════════════════════
--  §3.  ℤ/3ℤ Conjugacy Classes (abelian — 3 classes)
-- ════════════════════════════════════════════════════════════════════
--
--  ℤ/3ℤ is abelian, so each element is its own conjugacy class:
--    {z0} → vacuum (identity)
--    {z1} → charge +1
--    {z2} → charge −1  (since z2 = inv z1)
--
--  Particle spectrum: 2 non-identity classes → 2 charge types.
--
--  This matches the mathematical expectation from
--  docs/formal/05-gauge-theory.md §7:
--    ℤ/3ℤ → 3 conjugacy classes → vacuum + 2 charge types.
-- ════════════════════════════════════════════════════════════════════

data Z3ConjClass : Type₀ where
  cc-z0 cc-z1 cc-z2 : Z3ConjClass

classifyZ3 : Z3 → Z3ConjClass
classifyZ3 z0 = cc-z0
classifyZ3 z1 = cc-z1
classifyZ3 z2 = cc-z2

nConjClassesZ3 : ℕ
nConjClassesZ3 = 3

-- Number of non-identity conjugacy classes = particle species
nSpeciesZ3 : ℕ
nSpeciesZ3 = 2

-- Abelian conjugacy proof for ℤ/3ℤ: conjugation is trivial
module Z3Conj where
  open FiniteGroup ℤ/3

  z3-abelian-conj : (g k : Z3) → (inv k · g) · k ≡ g
  z3-abelian-conj = Conj.abelian-self-conjugate ℤ/3 Z3-comm


-- ════════════════════════════════════════════════════════════════════
--  §4.  Q₈ Conjugacy Classes (non-abelian — 5 classes)
-- ════════════════════════════════════════════════════════════════════
--
--  Q₈ has 8 elements and 5 conjugacy classes:
--
--    Class    Elements    Representative    Description
--    ──────   ─────────   ──────────────    ────────────
--    cc-1     {q1}        q1                vacuum (identity)
--    cc-n1    {qn1}       qn1               center element (−1)
--    cc-i     {qi, qni}   qi                ±i pair
--    cc-j     {qj, qnj}   qj                ±j pair
--    cc-k     {qk, qnk}   qk                ±k pair
--
--  The non-trivial identifications (qi ~ qni, qj ~ qnj, qk ~ qnk)
--  are witnessed by explicit conjugating elements:
--
--    qi ~ qni  via k = qj :  inv(j) · i · j = (−j) · i · j = k · j = −i
--    qj ~ qnj  via k = qi :  inv(i) · j · i = (−i) · j · i = (−k) · i = −j
--    qk ~ qnk  via k = qi :  inv(i) · k · i = (−i) · k · i = j · i = −k
--
--  All three witnesses type-check as  refl  because each step
--  in the computation is a closed-form pattern match on the
--  _*Q8_ multiplication table from Gauge/Q8.agda.
--
--  Particle spectrum: 5 total classes − 1 identity = 4 species.
--
--  This matches the mathematical expectation from
--  docs/formal/05-gauge-theory.md §7.3:
--    Q₈ → 5 conjugacy classes → vacuum + 4 species.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §7.3  (Q₈ conjugacy classes)
-- ════════════════════════════════════════════════════════════════════

data Q8ConjClass : Type₀ where
  cc-1 cc-n1 cc-i cc-j cc-k : Q8ConjClass

-- ── Classification function ────────────────────────────────────
--
--  Maps each Q₈ element to its conjugacy class representative.
--  The non-trivial cases: qi and qni map to the same class (cc-i),
--  and similarly for the j and k pairs.

classifyQ8 : Q8 → Q8ConjClass
classifyQ8 q1  = cc-1
classifyQ8 qn1 = cc-n1
classifyQ8 qi  = cc-i
classifyQ8 qni = cc-i       -- i and −i are conjugate
classifyQ8 qj  = cc-j
classifyQ8 qnj = cc-j       -- j and −j are conjugate
classifyQ8 qk  = cc-k
classifyQ8 qnk = cc-k       -- k and −k are conjugate

nConjClassesQ8 : ℕ
nConjClassesQ8 = 5

-- Number of non-identity conjugacy classes = particle species
nSpeciesQ8 : ℕ
nSpeciesQ8 = 4


-- ════════════════════════════════════════════════════════════════════
--  §5.  Q₈ Conjugacy Witnesses
-- ════════════════════════════════════════════════════════════════════
--
--  Machine-checked proofs that conjugate elements in Q₈ are
--  indeed conjugate under the formal definition from §1.
--
--  Each witness is a pair  (k , refl)  where  k  is the
--  conjugating element and  refl  type-checks because the
--  entire expression  (inv k · g) · k  reduces judgmentally
--  to the target element  h  via pattern matching on the Q₈
--  multiplication table.
--
--  Computation traces:
--
--    qi ~ qni  via  k = qj :
--      (inv qj · qi) · qj
--      = (qnj · qi) · qj      [invQ8 qj = qnj]
--      = qk · qj               [qnj *Q8 qi = qk]
--      = qni                   [qk *Q8 qj = qni]
--
--    qj ~ qnj  via  k = qi :
--      (inv qi · qj) · qi
--      = (qni · qj) · qi      [invQ8 qi = qni]
--      = qnk · qi              [qni *Q8 qj = qnk]
--      = qnj                   [qnk *Q8 qi = qnj]
--
--    qk ~ qnk  via  k = qi :
--      (inv qi · qk) · qi
--      = (qni · qk) · qi      [invQ8 qi = qni]
--      = qj · qi               [qni *Q8 qk = qj]
--      = qnk                   [qj *Q8 qi = qnk]
-- ════════════════════════════════════════════════════════════════════

-- qi and qni are conjugate in Q₈ (via k = qj)
conj-i-ni : Conj._~G_ Q₈ qi qni
conj-i-ni = qj , refl

-- qj and qnj are conjugate in Q₈ (via k = qi)
conj-j-nj : Conj._~G_ Q₈ qj qnj
conj-j-nj = qi , refl

-- qk and qnk are conjugate in Q₈ (via k = qi)
conj-k-nk : Conj._~G_ Q₈ qk qnk
conj-k-nk = qi , refl

-- The identity is conjugate to itself (trivially, via k = q1)
conj-1-1 : Conj._~G_ Q₈ q1 q1
conj-1-1 = q1 , refl

-- −1 is conjugate to itself (the center of Q₈; via k = q1)
conj-n1-n1 : Conj._~G_ Q₈ qn1 qn1
conj-n1-n1 = q1 , refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Particle Species Classification
-- ════════════════════════════════════════════════════════════════════
--
--  Two holonomies produce the "same particle type" if and only if
--  they have the same conjugacy class.  This is the gauge-invariant
--  notion of particle species in lattice gauge theory:
--
--    sameSpecies g h  :=  classifyQ8 g ≡ classifyQ8 h
--
--  For the boundary-side physics:  a ParticleDefect at face f
--  (from Gauge/Holonomy.agda) has a species determined by
--  classifyQ8 (holonomy ω ∂f).  Two defects at different faces
--  are the "same kind of particle" if their holonomies are
--  conjugate — i.e., if sameSpecies holds.
--
--  For abelian groups, sameSpecies reduces to equality of
--  holonomies (since every element is its own conjugacy class).
--
--  Reference:
--    docs/formal/05-gauge-theory.md §7.4  (species classification)
--    docs/physics/holographic-dictionary.md §4  (gauge theory
--                                               Agda ↔ physics)
-- ════════════════════════════════════════════════════════════════════

-- ── Q₈ species predicate ──────────────────────────────────────

sameSpeciesQ8 : Q8 → Q8 → Type₀
sameSpeciesQ8 g h = classifyQ8 g ≡ classifyQ8 h

-- ── ℤ/3ℤ species predicate ───────────────────────────────────

sameSpeciesZ3 : Z3 → Z3 → Type₀
sameSpeciesZ3 g h = classifyZ3 g ≡ classifyZ3 h


-- ════════════════════════════════════════════════════════════════════
--  §7.  Species Verification — Q₈
-- ════════════════════════════════════════════════════════════════════
--
--  Machine-checked proofs that conjugate elements have the same
--  species, and non-conjugate elements have different species.
-- ════════════════════════════════════════════════════════════════════

-- ── Same species (conjugate elements) ──────────────────────────

-- qi and qni are the same species (both classify to cc-i)
species-i-ni : sameSpeciesQ8 qi qni
species-i-ni = refl

-- qj and qnj are the same species (both classify to cc-j)
species-j-nj : sameSpeciesQ8 qj qnj
species-j-nj = refl

-- qk and qnk are the same species (both classify to cc-k)
species-k-nk : sameSpeciesQ8 qk qnk
species-k-nk = refl

-- ── Different species (non-conjugate elements) ─────────────────
--
--  qi and qj are different particle types: classifyQ8 qi = cc-i
--  and classifyQ8 qj = cc-j, which are distinct constructors of
--  Q8ConjClass.  Proving cc-i ≢ cc-j uses the standard
--  discriminator pattern.

private
  -- Discriminator: maps cc-i to an inhabited type, cc-j to ⊥
  Di : Q8ConjClass → Type₀
  Di cc-i = Q8ConjClass
  Di _    = ⊥

  Dj : Q8ConjClass → Type₀
  Dj cc-j = Q8ConjClass
  Dj _    = ⊥

species-i≢j : sameSpeciesQ8 qi qj → ⊥
species-i≢j p = subst Di p cc-i

species-i≢k : sameSpeciesQ8 qi qk → ⊥
species-i≢k p = subst Di p cc-i

species-j≢k : sameSpeciesQ8 qj qk → ⊥
species-j≢k p = subst Dj p cc-j


-- ════════════════════════════════════════════════════════════════════
--  §8.  Species Verification — ℤ/3ℤ
-- ════════════════════════════════════════════════════════════════════
--
--  In ℤ/3ℤ (abelian), every element is its own species.
--  z1 and z2 are different species (different charges).
-- ════════════════════════════════════════════════════════════════════

-- z1 and z2 are DIFFERENT species (charge +1 vs charge −1)
private
  Dz1 : Z3ConjClass → Type₀
  Dz1 cc-z1 = Z3ConjClass
  Dz1 _     = ⊥

species-z1≢z2 : sameSpeciesZ3 z1 z2 → ⊥
species-z1≢z2 p = subst Dz1 p cc-z1

-- z0 (vacuum) is different from z1 (charged)
private
  Dz0 : Z3ConjClass → Type₀
  Dz0 cc-z0 = Z3ConjClass
  Dz0 _     = ⊥

species-z0≢z1 : sameSpeciesZ3 z0 z1 → ⊥
species-z0≢z1 p = subst Dz0 p cc-z0


-- ════════════════════════════════════════════════════════════════════
--  §9.  Regression Tests
-- ════════════════════════════════════════════════════════════════════
--
--  Machine-checked sanity tests on the classification functions
--  and the abelian conjugacy proofs.
-- ════════════════════════════════════════════════════════════════════

private
  -- ── Q₈ classification spot checks ───────────────────────────
  check-q1  : classifyQ8 q1  ≡ cc-1
  check-q1  = refl

  check-qn1 : classifyQ8 qn1 ≡ cc-n1
  check-qn1 = refl

  check-qi  : classifyQ8 qi  ≡ cc-i
  check-qi  = refl

  check-qni : classifyQ8 qni ≡ cc-i
  check-qni = refl

  check-qj  : classifyQ8 qj  ≡ cc-j
  check-qj  = refl

  check-qnj : classifyQ8 qnj ≡ cc-j
  check-qnj = refl

  check-qk  : classifyQ8 qk  ≡ cc-k
  check-qk  = refl

  check-qnk : classifyQ8 qnk ≡ cc-k
  check-qnk = refl

  -- ── Z3 classification spot checks ───────────────────────────
  check-z0 : classifyZ3 z0 ≡ cc-z0
  check-z0 = refl

  check-z1 : classifyZ3 z1 ≡ cc-z1
  check-z1 = refl

  check-z2 : classifyZ3 z2 ≡ cc-z2
  check-z2 = refl

  -- ── Abelian conjugacy on closed terms ────────────────────────
  --
  --  The generic abelian proof reduces to refl on closed Z3 terms
  --  because all axioms (assoc, identity, inverse, comm) are
  --  refl for Z3 on closed constructors, and path composition
  --  of refls is refl.

  z3-conj-check : Z3Conj.z3-abelian-conj z1 z2 ≡ refl
  z3-conj-check = refl

  z3-conj-check2 : Z3Conj.z3-abelian-conj z2 z1 ≡ refl
  z3-conj-check2 = refl

  -- ── Z2 abelian conjugacy on closed terms ─────────────────────
  z2-conj-check : Z2Conj.z2-abelian-conj e1 e1 ≡ refl
  z2-conj-check = refl

  -- ── Spectrum count checks ────────────────────────────────────
  check-nZ2 : nConjClassesZ2 ≡ 2
  check-nZ2 = refl

  check-nZ3 : nConjClassesZ3 ≡ 3
  check-nZ3 = refl

  check-nQ8 : nConjClassesQ8 ≡ 5
  check-nQ8 = refl

  check-specZ3 : nSpeciesZ3 ≡ 2
  check-specZ3 = refl

  check-specQ8 : nSpeciesQ8 ≡ 4
  check-specQ8 = refl


-- ════════════════════════════════════════════════════════════════════
--  §10.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    -- General conjugacy infrastructure (parameterized module):
--    Conj._~G_                 : G → Carrier → Carrier → Type₀
--    Conj.abelian-self-conjugate : comm → (g k : Carrier) → (inv k · g) · k ≡ g
--    Conj.abelian-conjugate-to-self : comm → (g : Carrier) → g ~G g
--
--    -- ℤ/2ℤ (2 classes, 1 species):
--    Z2ConjClass, classifyZ2, nConjClassesZ2, nSpeciesZ2
--
--    -- ℤ/3ℤ (3 classes, 2 species):
--    Z3ConjClass, classifyZ3, nConjClassesZ3, nSpeciesZ3
--
--    -- Q₈ (5 classes, 4 species):
--    Q8ConjClass, classifyQ8, nConjClassesQ8, nSpeciesQ8
--
--    -- Q₈ conjugacy witnesses:
--    conj-i-ni   : Conj._~G_ Q₈ qi qni      (via k = qj, refl)
--    conj-j-nj   : Conj._~G_ Q₈ qj qnj      (via k = qi, refl)
--    conj-k-nk   : Conj._~G_ Q₈ qk qnk      (via k = qi, refl)
--    conj-1-1    : Conj._~G_ Q₈ q1 q1        (via k = q1, refl)
--    conj-n1-n1  : Conj._~G_ Q₈ qn1 qn1      (via k = q1, refl)
--
--    -- Particle species predicates:
--    sameSpeciesQ8 : Q8 → Q8 → Type₀
--    sameSpeciesZ3 : Z3 → Z3 → Type₀
--
--    -- Species distinctness witnesses:
--    species-i≢j   : sameSpeciesQ8 qi qj → ⊥
--    species-i≢k   : sameSpeciesQ8 qi qk → ⊥
--    species-j≢k   : sameSpeciesQ8 qj qk → ⊥
--    species-z1≢z2 : sameSpeciesZ3 z1 z2 → ⊥
--    species-z0≢z1 : sameSpeciesZ3 z0 z1 → ⊥
--
--  Design decisions:
--
--    1.  The conjugacy relation is defined in a parameterized module
--        Conj(G) rather than as a standalone function.  This avoids
--        verbose type signatures — inside the module, all group
--        operations (ε, _·_, inv, axioms) are in scope via
--        open FiniteGroup G.
--
--    2.  Conjugacy class types (Z2ConjClass, Z3ConjClass, Q8ConjClass)
--        are concrete data types with one constructor per class, NOT
--        quotient types.  This is deliberate: for finite groups with
--        decidable equality, the classification function is total and
--        computable, and pattern matching on the class type gives
--        direct case analysis on particle species.
--
--    3.  The conjugacy witnesses for Q₈ are all (k , refl) because
--        the expressions (inv k · g) · k reduce judgmentally to the
--        target element via the closed-form multiplication table in
--        Gauge/Q8.agda.  No arithmetic reasoning, no path algebra —
--        just definitional reduction.
--
--    4.  The abelian-self-conjugate proof uses a 5-step path
--        composition (assoc, comm, sym assoc, inverseˡ, identityˡ).
--        For concrete abelian groups, all 5 steps are refl, so the
--        composed path is also refl.  This is verified by the
--        regression tests z3-conj-check and z2-conj-check.
--
--    5.  sameSpecies is defined as propositional equality of
--        conjugacy class representatives (classifyQ8 g ≡ classifyQ8 h),
--        NOT as the existence of a conjugacy witness.  This is the
--        correct notion for particle species classification: two
--        holonomies produce the "same particle" iff their classes
--        agree, regardless of which specific conjugating element
--        witnesses the conjugacy.
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Gauge/FiniteGroup.agda  — FiniteGroup record, ℤ/2
--      • Gauge/ZMod.agda         — ℤ/3, Z3-comm
--      • Gauge/Q8.agda           — Q₈ instance
--
--    Downstream integration with Gauge/Holonomy.agda:
--
--      Given a GaugeConnection ω and a face boundary ∂f, the
--      holonomy  W = holonomy ω ∂f : G.Carrier  determines:
--
--        species(W) = classifyQ8 W  :  Q8ConjClass
--
--      A ParticleDefect at face f (¬(W ≡ ε) from Holonomy.agda)
--      has species  classifyQ8 W .  If  classifyQ8 W ≡ cc-i ,
--      the defect is an "i-type particle."  If a different face
--      f' has  classifyQ8 W' ≡ cc-i  as well, the two defects
--      are the same particle species (even if W ≡ qi and W' ≡ qni,
--      since both map to cc-i).
--
--  Next steps:
--
--    src/Gauge/RepCapacity.agda  — Defines SpinLabel assigning an
--    irreducible representation to each bond, the dimension functor
--    dim : Rep G → ℕ, and the integration with PatchData for
--    dimension-weighted bridge witnesses (GaugedPatchWitness).
--    See docs/formal/05-gauge-theory.md §8 for the capacity
--    extraction and gauge-enriched bridge.
--
--  Reference:
--    docs/formal/05-gauge-theory.md §7    (conjugacy classes and
--                                          particle species)
--    docs/formal/05-gauge-theory.md §10   (three-layer gauge
--                                          architecture)
--    docs/formal/01-theorems.md §Thm 6    (Matter as Topological
--                                          Defects — downstream)
--    docs/reference/module-index.md       (module description)
--    docs/getting-started/architecture.md (module dependency DAG)
--    docs/historical/development-docs/10-frontier.md §13
--                                         (original development plan)
-- ════════════════════════════════════════════════════════════════════