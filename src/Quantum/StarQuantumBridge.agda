{-# OPTIONS --cubical --safe --guardedness #-}

module Quantum.StarQuantumBridge where

open import Cubical.Foundations.Prelude
open import Cubical.Data.Nat
  using (ℕ ; zero ; suc)
open import Cubical.Data.List  using (List ; [] ; _∷_)
open import Cubical.Data.Sigma using (_×_)
open import Cubical.Data.Int   using (pos ; negsuc)

open import Util.Scalars
open import Common.StarSpec
  using ( Bond ; Region
        ; bCN0 ; bCN1 ; bCN2 ; bCN3 ; bCN4
        ; regN0 ; regN1 ; regN0N1 ; regN4N0 )

open import Boundary.StarCutParam using (S-param)
open import Bulk.StarChainParam
  using (L-param ; SL-param-pointwise)

open import Gauge.FiniteGroup using (FiniteGroup)
open import Gauge.Q8
  using (Q8 ; q1 ; qn1 ; qi ; qni ; qj ; qnj ; qk ; qnk ; Q₈)
open import Gauge.Connection
  using (GaugeConnection)
open import Gauge.Holonomy
  using (starQ8-i ; starQ8-ij ; starQ8-ji)
open import Gauge.RepCapacity
  using (starQ8Capacity)

open import Quantum.AmplitudeAlg
open import Quantum.Superposition
open import Quantum.QuantumBridge


-- ════════════════════════════════════════════════════════════════════
--  §1.  The Star Quantum Bridge — Superposition-Level RT for Q₈
-- ════════════════════════════════════════════════════════════════════
--
--  THEOREM (Star Quantum Holographic Bridge).
--
--  For any finite superposition  ψ  of Q₈ gauge connections on the
--  6-tile star patch, weighted by amplitudes in any algebra  A :
--
--    𝔼[ψ, λ ω → S∂(cap(ω), r)]  ≡  𝔼[ψ, λ ω → L_B(cap(ω), r)]
--
--  where  cap  is the dimension-weighted capacity extracted from the
--  Q₈ fundamental representation (dim = 2 for all bonds), and  r  is
--  any boundary region.
--
--  The proof instantiates  quantum-bridge  from
--  Quantum/QuantumBridge.agda  with the per-microstate bridge
--  SL-param-pointwise  from  Bulk/StarChainParam.agda .
--
--  The per-microstate bridge holds for ANY weight function  w ,
--  hence for  starQ8Capacity  (which assigns capacity 2 to every
--  bond).  Since the spin label is fixed (all bonds carry the
--  fundamental Q₈ representation), the capacity is independent of
--  the gauge connection.  The bridge is therefore:
--
--    ∀ ω → S-param starQ8Capacity r ≡ L-param starQ8Capacity r
--    =  λ _ → SL-param-pointwise starQ8Capacity r
--
--  This is amplitude-polymorphic, gauge-configuration-agnostic, and
--  topology-agnostic (via the generic quantum-bridge theorem).
--
--  Architectural role:
--    This is the capstone of the Quantum layer, instantiating the
--    generic quantum bridge theorem (Quantum/QuantumBridge.agda,
--    Theorem 7 in the canonical theorem registry) for the concrete
--    6-tile star patch with Q₈ gauge group and ℤ[i] amplitudes.
--    It composes the gauge layer (Q₈ connections, holonomy), the
--    capacity layer (dimension functor → starQ8Capacity), the
--    parameterized bridge (SL-param-pointwise), and the quantum
--    bridge theorem into a single verified instantiation.
--    See docs/getting-started/architecture.md for the module
--    dependency DAG.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §6
--                              (The Star Quantum Bridge — Concrete
--                               Instantiation)
--    docs/formal/07-quantum-superposition.md §2
--                              (Amplitude Polymorphism — the key insight)
--    docs/formal/01-theorems.md §Thm 7
--                              (Quantum Superposition Bridge —
--                               theorem registry entry)
--    docs/formal/05-gauge-theory.md §8
--                              (Representation Capacity and the
--                               Dimension Functor)
--    docs/instances/star-patch.md §9
--                              (Quantum Superposition on the star patch)
--    docs/reference/module-index.md
--                              (module description)
--    docs/getting-started/architecture.md
--                              (Quantum layer — module dependency DAG)
--    docs/historical/development-docs/10-frontier.md §14
--                              (original development plan for the
--                               quantum layer)
-- ════════════════════════════════════════════════════════════════════

star-quantum-bridge :
  (alg : AmplitudeAlg)
  → (ψ : Superposition (GaugeConnection Q₈ Bond) alg)
  → (r : Region)
  → 𝔼 alg ψ (λ ω → S-param starQ8Capacity r)
  ≡ 𝔼 alg ψ (λ ω → L-param starQ8Capacity r)
star-quantum-bridge alg ψ r =
  quantum-bridge alg ψ
    (λ _ → S-param starQ8Capacity r)
    (λ _ → L-param starQ8Capacity r)
    (λ _ → SL-param-pointwise starQ8Capacity r)


-- ════════════════════════════════════════════════════════════════════
--  §2.  General Capacity-Parameterized Version
-- ════════════════════════════════════════════════════════════════════
--
--  For the most general formulation: given ANY configuration type
--  and ANY function  cap  extracting bond capacities from a
--  configuration, the superposition-level RT correspondence holds.
--
--  This covers the case where different gauge connections could
--  carry different representation labels (and hence different
--  bond dimensions).  The per-microstate bridge
--  SL-param-pointwise  works because it holds for ANY weight
--  function  w : Bond → ℚ≥0 , including  cap ω  for any  ω .
-- ════════════════════════════════════════════════════════════════════

star-quantum-bridge-general :
  (alg : AmplitudeAlg) {Config : Type₀}
  → (cap : Config → (Bond → ℚ≥0))
  → (ψ : Superposition Config alg)
  → (r : Region)
  → 𝔼 alg ψ (λ ω → S-param (cap ω) r)
  ≡ 𝔼 alg ψ (λ ω → L-param (cap ω) r)
star-quantum-bridge-general alg cap ψ r =
  quantum-bridge alg ψ
    (λ ω → S-param (cap ω) r)
    (λ ω → L-param (cap ω) r)
    (λ ω → SL-param-pointwise (cap ω) r)


-- ════════════════════════════════════════════════════════════════════
--  §3.  Concrete Superposition — 2 Q₈ Connections with ℤ[i]
-- ════════════════════════════════════════════════════════════════════
--
--  A quantum superposition of two Q₈ gauge connections on the
--  6-tile star patch:
--
--    ψ₂ = [ (ω₁ = starQ8-i,  α₁ = 1+0i)
--          , (ω₂ = starQ8-ij, α₂ = 0+1i) ]
--
--  Configuration ω₁:  bCN0 = i, rest = 1  (single excited bond)
--  Configuration ω₂:  bCN0 = i, bCN1 = j, rest = 1  (two bonds)
--
--  Both configurations have holonomy ≠ 1 at the central face
--  (ParticleDefect from Gauge/Holonomy.agda), but the superposition-
--  level RT still holds because it is a CONSEQUENCE OF LINEARITY,
--  not of the specific gauge configuration.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §6.3
--                              (Concrete Superpositions with
--                               Interference)
--    docs/instances/star-patch.md §9
--                              (Quantum Superposition on the star)
-- ════════════════════════════════════════════════════════════════════

ψ₂ : Superposition (GaugeConnection Q₈ Bond) ℤiAmplitude
ψ₂ = (starQ8-i , 1ℤi) ∷ (starQ8-ij , iℤi) ∷ []


-- ════════════════════════════════════════════════════════════════════
--  §4.  Expected-Value Computation — Region regN0 (singleton)
-- ════════════════════════════════════════════════════════════════════
--
--  For region regN0 (the singleton {N0}), the dimension-weighted
--  observable is  S-param starQ8Capacity regN0 = starQ8Capacity bCN0
--  = 2  (dim of Q₈ fundamental representation).
--
--  Expected value:
--
--    𝔼[ψ₂, λ _ → 2]
--    = (1+0i) · embedℕ(2) + ((0+1i) · embedℕ(2) + (0+0i))
--    = (2+0i) + ((0+2i) + (0+0i))
--    = (2+0i) + (0+2i)
--    = (2+2i)
--
--  Both S and L produce the same expected value (2+2i) because
--  both observable functions return 2 at every configuration.
-- ════════════════════════════════════════════════════════════════════

-- The expected boundary entropy at regN0
check-S-regN0 :
  𝔼 ℤiAmplitude ψ₂ (λ _ → S-param starQ8Capacity regN0)
  ≡ mkℤi (pos 2) (pos 2)
check-S-regN0 = refl

-- The expected bulk chain length at regN0
check-L-regN0 :
  𝔼 ℤiAmplitude ψ₂ (λ _ → L-param starQ8Capacity regN0)
  ≡ mkℤi (pos 2) (pos 2)
check-L-regN0 = refl

-- The quantum bridge at regN0, via star-quantum-bridge
bridge-regN0 :
  𝔼 ℤiAmplitude ψ₂ (λ _ → S-param starQ8Capacity regN0)
  ≡ 𝔼 ℤiAmplitude ψ₂ (λ _ → L-param starQ8Capacity regN0)
bridge-regN0 = star-quantum-bridge ℤiAmplitude ψ₂ regN0

-- The bridge proof reduces to refl on closed normal forms
bridge-regN0-is-refl : star-quantum-bridge ℤiAmplitude ψ₂ regN0 ≡ refl
bridge-regN0-is-refl = refl


-- ════════════════════════════════════════════════════════════════════
--  §5.  Expected-Value Computation — Region regN0N1 (pair)
-- ════════════════════════════════════════════════════════════════════
--
--  For region regN0N1 (the pair {N0, N1}), the dimension-weighted
--  observable is:
--    S-param starQ8Capacity regN0N1
--    = starQ8Capacity bCN0 +ℚ starQ8Capacity bCN1
--    = 2 + 2 = 4
--
--  Expected value:
--
--    𝔼[ψ₂, λ _ → 4]
--    = (1+0i) · embedℕ(4) + ((0+1i) · embedℕ(4) + (0+0i))
--    = (4+0i) + ((0+4i) + (0+0i))
--    = (4+0i) + (0+4i)
--    = (4+4i)
-- ════════════════════════════════════════════════════════════════════

check-S-regN0N1 :
  𝔼 ℤiAmplitude ψ₂ (λ _ → S-param starQ8Capacity regN0N1)
  ≡ mkℤi (pos 4) (pos 4)
check-S-regN0N1 = refl

bridge-regN0N1 :
  𝔼 ℤiAmplitude ψ₂ (λ _ → S-param starQ8Capacity regN0N1)
  ≡ 𝔼 ℤiAmplitude ψ₂ (λ _ → L-param starQ8Capacity regN0N1)
bridge-regN0N1 = star-quantum-bridge ℤiAmplitude ψ₂ regN0N1

bridge-regN0N1-is-refl :
  star-quantum-bridge ℤiAmplitude ψ₂ regN0N1 ≡ refl
bridge-regN0N1-is-refl = refl


-- ════════════════════════════════════════════════════════════════════
--  §6.  Three-Configuration Superposition with Interference
-- ════════════════════════════════════════════════════════════════════
--
--  A superposition of THREE Q₈ gauge connections with amplitudes
--  that exhibit genuine quantum interference:
--
--    ψ₃ = [ (starQ8-i,   1+0i)     — amplitude +1
--          , (starQ8-ij,  0+1i)     — amplitude +i
--          , (starQ8-ji, −1+0i) ]   — amplitude −1
--
--  The third configuration (bCN0 = j, bCN1 = i) is physically
--  distinct from the second (bCN0 = i, bCN1 = j) — it produces
--  a different holonomy (−k instead of +k, by non-commutativity
--  of Q₈, from Gauge/Holonomy.agda).  But the amplitude −1
--  partially cancels the first configuration's amplitude +1.
--
--  At regN0 (observable value = 2 for all configs):
--
--    𝔼[ψ₃, λ _ → 2]
--    = (+1) · 2 + ((+i) · 2 + ((−1) · 2 + 0))
--    = (2+0i) + ((0+2i) + ((−2+0i) + (0+0i)))
--    = (2+0i) + ((0+2i) + (−2+0i))
--    = (2+0i) + (−2+2i)
--    = (0+2i)
--
--  The real parts cancel: (+1)·2 + (−1)·2 = 0.  Only the
--  imaginary contribution from the second configuration survives.
--  This is DESTRUCTIVE INTERFERENCE between the first and third
--  gauge configurations — the discrete-holographic analogue of
--  quantum-mechanical path cancellation.
--
--  Yet ⟨S⟩ = ⟨L⟩ = (0+2i) — the holographic bridge holds
--  THROUGH the interference, because it is a consequence of
--  linearity, not of the specific amplitude values.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §6.3
--                              (Three-configuration superposition
--                               with destructive interference)
-- ════════════════════════════════════════════════════════════════════

ψ₃ : Superposition (GaugeConnection Q₈ Bond) ℤiAmplitude
ψ₃ = (starQ8-i , 1ℤi) ∷ (starQ8-ij , iℤi) ∷ (starQ8-ji , neg1ℤi) ∷ []

-- ── Verification at regN0 (singleton, observable = 2) ──────────
--
--  Expected value:  (0+2i) = mkℤi (pos 0) (pos 2)
--
--  Computation trace:
--    (−1) · 2 = −2+0i
--    (−2+0i) + (0+0i) = −2+0i
--    (+i) · 2 = 0+2i
--    (0+2i) + (−2+0i) = −2+2i
--    (+1) · 2 = 2+0i
--    (2+0i) + (−2+2i) = 0+2i  ← partial cancellation!

check-ψ₃-S-regN0 :
  𝔼 ℤiAmplitude ψ₃ (λ _ → S-param starQ8Capacity regN0)
  ≡ mkℤi (pos 0) (pos 2)
check-ψ₃-S-regN0 = refl

check-ψ₃-L-regN0 :
  𝔼 ℤiAmplitude ψ₃ (λ _ → L-param starQ8Capacity regN0)
  ≡ mkℤi (pos 0) (pos 2)
check-ψ₃-L-regN0 = refl

-- The quantum bridge holds through the interference
bridge-ψ₃-regN0 :
  𝔼 ℤiAmplitude ψ₃ (λ _ → S-param starQ8Capacity regN0)
  ≡ 𝔼 ℤiAmplitude ψ₃ (λ _ → L-param starQ8Capacity regN0)
bridge-ψ₃-regN0 = star-quantum-bridge ℤiAmplitude ψ₃ regN0

-- Reduces to refl on the closed normal forms
bridge-ψ₃-regN0-is-refl :
  star-quantum-bridge ℤiAmplitude ψ₃ regN0 ≡ refl
bridge-ψ₃-regN0-is-refl = refl


-- ── Verification at regN0N1 (pair, observable = 4) ─────────────
--
--  Expected value:
--    (+1)·4 + (+i)·4 + (−1)·4
--    = (4+0i) + (0+4i) + (−4+0i)
--    = (0+4i) = mkℤi (pos 0) (pos 4)

check-ψ₃-S-regN0N1 :
  𝔼 ℤiAmplitude ψ₃ (λ _ → S-param starQ8Capacity regN0N1)
  ≡ mkℤi (pos 0) (pos 4)
check-ψ₃-S-regN0N1 = refl

bridge-ψ₃-regN0N1 :
  𝔼 ℤiAmplitude ψ₃ (λ _ → S-param starQ8Capacity regN0N1)
  ≡ 𝔼 ℤiAmplitude ψ₃ (λ _ → L-param starQ8Capacity regN0N1)
bridge-ψ₃-regN0N1 = star-quantum-bridge ℤiAmplitude ψ₃ regN0N1

bridge-ψ₃-regN0N1-is-refl :
  star-quantum-bridge ℤiAmplitude ψ₃ regN0N1 ≡ refl
bridge-ψ₃-regN0N1-is-refl = refl


-- ════════════════════════════════════════════════════════════════════
--  §7.  Classical (ℕ) Amplitude — No Interference
-- ════════════════════════════════════════════════════════════════════
--
--  For comparison, the same superposition structure with ℕ
--  amplitudes (classical counting, no interference):
--
--    ψ-classical = [ (starQ8-i, 3), (starQ8-ij, 5) ]
--
--  At regN0 (observable = 2):
--    𝔼[ψ, λ _ → 2] = 3 · 2 + 5 · 2 = 6 + 10 = 16
--
--  All amplitudes are non-negative: no cancellation can occur.
--  This is the "Boltzmann weighted sum" of classical statistical
--  mechanics, not a quantum path integral.
-- ════════════════════════════════════════════════════════════════════

ψ-classical : Superposition (GaugeConnection Q₈ Bond) ℕAmplitude
ψ-classical = (starQ8-i , 3) ∷ (starQ8-ij , 5) ∷ []

check-classical-regN0 :
  𝔼 ℕAmplitude ψ-classical (λ _ → S-param starQ8Capacity regN0)
  ≡ 16
check-classical-regN0 = refl

bridge-classical :
  𝔼 ℕAmplitude ψ-classical (λ _ → S-param starQ8Capacity regN0)
  ≡ 𝔼 ℕAmplitude ψ-classical (λ _ → L-param starQ8Capacity regN0)
bridge-classical = star-quantum-bridge ℕAmplitude ψ-classical regN0


-- ════════════════════════════════════════════════════════════════════
--  §8.  Partition Function
-- ════════════════════════════════════════════════════════════════════
--
--  The partition function Z = 𝔼[ψ, λ _ → 1] for the ℤ[i]
--  three-configuration superposition:
--
--    Z = (+1)·1 + (+i)·1 + (−1)·1
--      = (1+0i) + (0+1i) + (−1+0i)
--      = (0+1i)
--
--  The real-part cancellation: (+1) + (−1) = 0.
--  The partition function is purely imaginary — a genuine
--  quantum-mechanical phenomenon impossible with ℕ amplitudes.
--
--  The quantum bridge theorem does NOT divide by Z.  It proves
--  the numerator equality  𝔼[ψ,S] ≡ 𝔼[ψ,L]  directly, so it
--  remains valid even when Z = 0 (total destructive interference).
--
--  Reference:
--    docs/formal/07-quantum-superposition.md §7
--                              (The Partition Function and
--                               Cancellation)
-- ════════════════════════════════════════════════════════════════════

check-partition-ψ₃ :
  Z ℤiAmplitude ψ₃ ≡ mkℤi (pos 0) (pos 1)
check-partition-ψ₃ = refl


-- ════════════════════════════════════════════════════════════════════
--  §9.  Summary and Design Notes
-- ════════════════════════════════════════════════════════════════════
--
--  Exports:
--
--    star-quantum-bridge :
--      (alg : AmplitudeAlg)
--      → Superposition (GaugeConnection Q₈ Bond) alg
--      → (r : Region)
--      → 𝔼 alg ψ (λ ω → S-param starQ8Capacity r)
--        ≡ 𝔼 alg ψ (λ ω → L-param starQ8Capacity r)
--
--    star-quantum-bridge-general :
--      (alg : AmplitudeAlg) {Config : Type₀}
--      → (cap : Config → (Bond → ℚ≥0))
--      → Superposition Config alg → Region → 𝔼[S] ≡ 𝔼[L]
--
--    ψ₂  : 2-connection Q₈ superposition with ℤ[i] amplitudes
--    ψ₃  : 3-connection Q₈ superposition with partial interference
--    ψ-classical : 2-connection Q₈ with ℕ amplitudes
--
--  Theorem registry satisfaction (docs/formal/01-theorems.md §Thm 7):
--
--    ✓  star-quantum-bridge type-checks for the 6-tile star with
--       Q₈ gauge group, consuming SL-param-pointwise as the
--       per-microstate bridge.
--
--    ✓  (stretch)  Concrete superpositions of 2–3 Q₈ gauge
--       connections with ℤ[i] amplitudes are constructed, and the
--       expected-value equality is verified by refl on the closed
--       normal forms:
--         bridge-regN0-is-refl       = refl
--         bridge-regN0N1-is-refl     = refl
--         bridge-ψ₃-regN0-is-refl   = refl
--         bridge-ψ₃-regN0N1-is-refl = refl
--
--  Architecture (docs/getting-started/architecture.md):
--
--    Gauge/ (Q₈, Connection, Holonomy)
--         │
--    Gauge/RepCapacity (dim functor → starQ8Capacity)
--         │
--    SL-param-pointwise (RT for any weight function w)
--         │
--    quantum-bridge (linearity over finite list — 5 lines)
--         │
--    star-quantum-bridge (this module — 1 application)
--         │
--    ⟨S⟩ ≡ ⟨L⟩  for any superposition ψ, any amplitude algebra
--
--  The quantum structure of the discrete holographic correspondence
--  is algebraically trivial: it is a consequence of the linearity
--  of finite sums (cong₂ on _+A_), composed with the per-microstate
--  bridge.  The physics of superposition adds no proof-theoretic
--  complexity — only a thin inductive wrapper over existing
--  infrastructure.
--
--  Relationship to existing code:
--
--    This module imports from (but does NOT modify):
--      • Quantum/AmplitudeAlg.agda     — ℤiAmplitude, ℕAmplitude, ℤ[i]
--      • Quantum/Superposition.agda    — Superposition, 𝔼, Z
--      • Quantum/QuantumBridge.agda    — quantum-bridge
--      • Gauge/Q8.agda                 — Q₈
--      • Gauge/Connection.agda         — GaugeConnection
--      • Gauge/Holonomy.agda           — starQ8-i, starQ8-ij, starQ8-ji
--      • Gauge/RepCapacity.agda        — starQ8Capacity
--      • Boundary/StarCutParam.agda    — S-param
--      • Bulk/StarChainParam.agda      — L-param, SL-param-pointwise
--      • Common/StarSpec.agda          — Bond, Region
--
--    The quantum layer is purely additive — it composes the gauge
--    layer, the capacity layer, the parameterized bridge, and the
--    quantum bridge theorem without modifying any existing module.
--
--  Research significance (docs/formal/07-quantum-superposition.md §8):
--
--    This is the first machine-checked proof that a holographic
--    correspondence lifts from individual microstates to quantum
--    superpositions in any proof assistant.  The "quantum path
--    integral" for a finite lattice gauge theory on a holographic
--    network reduces to a single application of the quantum-bridge
--    theorem, which itself is a 5-line structural induction on a
--    list.  The constructive complex-number obstacle is irrelevant:
--    the proof works for ℤ[i], ℕ, or any amplitude type.
--
--  Reference:
--    docs/formal/07-quantum-superposition.md
--                        (quantum superposition — full formal treatment)
--    docs/formal/07-quantum-superposition.md §6
--                        (The Star Quantum Bridge)
--    docs/formal/07-quantum-superposition.md §8
--                        (Architectural Significance)
--    docs/formal/01-theorems.md §Thm 7
--                        (Quantum Superposition Bridge — theorem registry)
--    docs/formal/05-gauge-theory.md §8
--                        (Representation Capacity — dim functor)
--    docs/formal/05-gauge-theory.md §10
--                        (The Three-Layer Gauge Architecture)
--    docs/instances/star-patch.md §8–§9
--                        (Gauge enrichment and Quantum superposition
--                         on the star patch)
--    docs/getting-started/architecture.md
--                        (module dependency DAG — Quantum layer)
--    docs/reference/module-index.md
--                        (module description)
--    docs/physics/holographic-dictionary.md §6
--                        (quantum superposition Agda ↔ physics table)
--    docs/historical/development-docs/10-frontier.md §14
--                        (original development plan for the quantum layer)
-- ════════════════════════════════════════════════════════════════════