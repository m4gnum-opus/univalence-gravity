# The `abstract` Barrier

**The `abstract` keyword, Agda RAM management, and Issue #4573**

**Audience:** Proof engineers, Agda developers, and anyone working with large case analyses in Cubical Agda.

**Primary modules using `abstract`:** `Boundary/FilledSubadditivity.agda` (360 cases), `Boundary/Dense100AreaLaw.agda` (717 cases), `Boundary/Dense200AreaLaw.agda` (1246 cases), `Boundary/Dense100HalfBound.agda` (717 cases), `Boundary/Dense200HalfBound.agda` (1246 cases)

**Prerequisites:** Familiarity with the oracle pipeline ([`engineering/oracle-pipeline.md`](oracle-pipeline.md)), orbit reduction ([`engineering/orbit-reduction.md`](orbit-reduction.md)), and the HoTT foundations ([`formal/02-foundations.md`](../formal/02-foundations.md) §1 on h-levels).

---

## 1. The Problem: Normalization-Driven RAM Cascades

Agda's type-checker does not "execute" arithmetic the way a CPU does. It **normalizes** terms by recursively unpacking every constructor into abstract syntax trees (ASTs) in memory, structurally verifying that both sides of an equality reduce to the same normal form. For a single `(k , refl)` witness — say `(5 , refl)` proving `5 + 3 ≡ 8` — this is cheap: the ℕ addition `5 + 3` reduces by structural recursion on the left argument in 5 steps, and the checker confirms both sides are `suc (suc (suc (suc (suc (suc (suc (suc zero)))))))`.

The cost becomes problematic when **many** such witnesses are used by a **downstream** module. Consider:

1. `Boundary/FilledSubadditivity.agda` proves 360 cases of `S(A∪B) ≤ S(A) + S(B)`, each as `(k , refl)`.
2. `Bridge/FilledEquiv.agda` imports the subadditivity lemma and uses it in the enriched type equivalence proof.
3. When Agda type-checks `FilledEquiv.agda`, it must verify that the subadditivity lemma has the claimed type. If the lemma's **definition** is visible, the normalizer may re-expand all 360 `(k , refl)` proof trees when checking downstream uses — even if the only relevant fact is that the lemma *exists* with a certain type.

Each `(k , refl)` proof expands into a nested `Σ`-type constructor applied to an ℕ literal and a `refl` path — a tree of AST nodes that the normalizer must build, traverse, and eventually garbage-collect. For 360 cases, the aggregate memory cost can exhaust available RAM on machines with 8–16 GB, causing the type-checker to hang or crash.

This is not a bug. It is a deliberate architectural tradeoff rooted in the **De Bruijn Criterion**: the trusted computing base (TCB) of a proof assistant must be as small and simple as possible. If the compiler optimized heavy arithmetic internally, any bug in that optimization engine could silently accept false proofs. Keeping the kernel "stupid" and delegating heavy computation to external tools is the intended design pattern of the field.

The phenomenon is documented in [Agda GitHub Issue #4573](https://github.com/agda/agda/issues/4573) ("Slow typechecking unless using abstract in cubical"), with comments from core developers confirming that the `abstract` keyword is the recommended workaround.

---

## 2. The Solution: The `abstract` Keyword

### 2.1 What `abstract` Does

Wrapping a proof block in `abstract` tells Agda:

> "Once this definition's type is verified, seal the definition body in a black box. Downstream modules may use the **type signature** but never unfold the **definition** during normalization."

Concretely:

```agda
abstract
  area-law : (r : D100Region) → S-cut d100BdyView r ≤ℚ regionArea r
  area-law d100r0 = 5 , refl
  area-law d100r1 = 7 , refl
  -- ... (717 clauses total)
```

When Agda type-checks this module, it verifies each of the 717 clauses individually: for `area-law d100r0 = 5 , refl`, it checks that `5 + (S-cut d100BdyView d100r0)` normalizes to `regionArea d100r0`. This succeeds because both sides reduce to the same ℕ literal via structural recursion on closed constructor terms.

After verification, the **body** of `area-law` is sealed. Any downstream module importing `area-law` sees only the type:

```
area-law : (r : D100Region) → S-cut d100BdyView r ≤ℚ regionArea r
```

It cannot pattern-match on the internal `(k , refl)` structure, cannot extract the ℕ witness `k`, and — critically — the normalizer **never re-enters the 717-clause definition** when type-checking downstream uses. The RAM cascade is halted.

### 2.2 What `abstract` Does NOT Do

The `abstract` barrier has a cost: **computational content is lost**. Functions wrapped in `abstract` cannot be reduced by `transport`, `subst`, or any other computation that needs to inspect the proof term.

This means:

- You **cannot** wrap observable functions (`S-cut`, `L-min`, `obs-path`) in `abstract` — the bridge equivalence and transport depend on their computational content.
- You **cannot** wrap the specification-agreement paths (`star-obs-path`, `filled-obs-path`) in `abstract` — the enriched type equivalence appends these paths via `_∙_` and the round-trip proofs require `isSetObs` to see their structure.
- You **can** wrap proofs of **propositional** types — types where any two inhabitants are equal (`isProp`). For such types, the specific proof term is irrelevant; all that matters is that *some* inhabitant exists.

---

## 3. Why Propositionality Makes `abstract` Safe

The ordering type used throughout the repository is:

```agda
m ≤ℚ n = Σ[ k ∈ ℕ ] (k + m ≡ n)
```

This type is **propositional** — any two inhabitants are equal:

```agda
isProp≤ℚ : ∀ {m n : ℚ≥0} → isProp (m ≤ℚ n)
isProp≤ℚ {m} {n} (k₁ , p₁) (k₂ , p₂) =
  ΣPathP (k≡ , isProp→PathP (λ i → isSetℕ (k≡ i + m) n) p₁ p₂)
  where
    k≡ : k₁ ≡ k₂
    k≡ = +-cancelʳ m (p₁ ∙ sym p₂)
```

The proof decomposes into:

1. **First components agree** (`k₁ ≡ k₂`): By ℕ right-cancellation from `k₁ + m ≡ n` and `k₂ + m ≡ n`.
2. **Second components agree** (paths in ℕ are propositional): ℕ is a set (`isSetℕ`), so any two paths `k + m ≡ n` are equal.

This propositionality has a decisive consequence for the `abstract` barrier:

> If `_≤ℚ_` is propositional, then the *specific* proof term `(5 , refl)` inside the `abstract` block is **the only possible proof** of that inequality (up to propositional equality). No downstream module could distinguish it from any other proof of the same fact. Therefore, sealing it behind `abstract` loses zero information — the sealed proof is uniquely determined by its type.

For the enriched bridge equivalence, the round-trip homotopies use `isProp≤ℚ` (via `isPropSubadditive` and `isPropMonotone`) to close:

```agda
fwd-bwd (f , q) i = record
  { obs  = f
  ; spec = isSetObs f LB (...) (FullBulk.spec b) i
  ; mono = isPropMonotone f (...) (FullBulk.mono b) i
  }
```

The `mono` field closes because **any two monotonicity proofs for the same function are equal** — whether they were derived by `subst` along a specification-agreement path, freshly constructed, or sealed behind `abstract`. The Univalence bridge and transport are completely unaffected.

---

## 4. The Modules That Use `abstract`

Five auto-generated modules in the repository use the `abstract` barrier:

| Module | Cases | Target Type | Purpose |
|--------|-------|-------------|---------|
| `Boundary/FilledSubadditivity.agda` | 360 | `S-filled r₃ ≤ℚ (S-filled r₁ +ℚ S-filled r₂)` | Subadditivity of min-cut on 11-tile patch |
| `Boundary/Dense100AreaLaw.agda` | 717 | `S-cut d100BdyView r ≤ℚ regionArea r` | Discrete area law S ≤ area for Dense-100 |
| `Boundary/Dense200AreaLaw.agda` | 1246 | `S-cut d200BdyView r ≤ℚ regionArea r` | Discrete area law S ≤ area for Dense-200 |
| `Boundary/Dense100HalfBound.agda` | 717 | `(S∂ r +ℚ S∂ r) ≤ℚ regionArea r` | Half-bound 2·S ≤ area for Dense-100 |
| `Boundary/Dense200HalfBound.agda` | 1246 | `(S∂ r +ℚ S∂ r) ≤ℚ regionArea r` | Half-bound 2·S ≤ area for Dense-200 |

All five share the same structure:

1. The target type is `_≤ℚ_` (propositional by `isProp≤ℚ`).
2. Each case is a `(k , refl)` witness where `k` is the slack value.
3. The `refl` holds because ℕ addition computes judgmentally on closed numerals.
4. The `abstract` keyword seals the entire case analysis.

The total case count across all five modules is **3,986 `abstract`-sealed proofs** — each verified individually by the Agda type-checker, then sealed to prevent downstream re-normalization.

---

## 5. The `abstract` Barrier vs. Orbit Reduction

The repository uses two complementary strategies for managing large proof obligations:

| Strategy | When to Use | Proof Cases | Example |
|----------|-------------|-------------|---------|
| **Orbit reduction** | The RT correspondence `S = L` (same value for many regions) | = orbit count (very small: 2–9) | `d100-pointwise r = d100-pointwise-rep (classify100 r)` |
| **`abstract` barrier** | Inequality bounds where values *differ* across regions | = region count (large: 360–1246) | `area-law d100r0 = 5 , refl` (sealed) |

The two strategies are **orthogonal** — they serve different proof obligations and can coexist on the same patch:

- **Orbit reduction** works for the RT correspondence because all regions with the same min-cut value carry the same observable. The proof factors through the small orbit type.
- **`abstract`** works for the area law and half-bound because the *slack* values (area − S, or area − 2·S) vary across regions within the same orbit. The min-cut grouping does not help; each region needs its own `(k , refl)` witness.

For the Dense-100 patch:

| Proof | Technique | Cases | Architecture |
|-------|-----------|-------|-------------|
| S = L (RT) | Orbit reduction | 8 orbit `refl` proofs + 1-line lifting | `d100-pointwise r = d100-pointwise-rep (classify100 r)` |
| S ≤ area | `abstract` barrier | 717 `(k , refl)` proofs, sealed | `abstract area-law d100r0 = 5 , refl` |
| 2·S ≤ area | `abstract` barrier | 717 `(k , refl)` proofs, sealed | `abstract half-bound-proof d100r0 = 0 , refl` |

---

## 6. Practical Consequences for Downstream Modules

### 6.1 What Downstream Code Can Do

Downstream modules can **use** the `abstract` lemma as a black-box proof:

```agda
-- In Bridge/Dense100Thermodynamics.agda:
dense100-thermodynamics : CoarseGrainedRT
dense100-thermodynamics = dense100-coarse-witness , regionArea , area-law
--                                                               ^^^^^^^^^
--                                              imported from Dense100AreaLaw
--                                              type is known; body is sealed
```

The `area-law` field has type `(r : D100Region) → S-cut d100BdyView r ≤ℚ regionArea r`. The downstream module can apply it to a specific region `r` to obtain a proof of `S r ≤ area r`. It can compose it with other lemmas via path composition. It can transport it via `subst`.

### 6.2 What Downstream Code Cannot Do

Downstream modules **cannot**:

- Pattern-match on the `(k , refl)` structure of the proof.
- Extract the ℕ witness `k` from the proof.
- Evaluate `area-law d100r0` to inspect the specific slack value.
- Use `cong fst` to project the first component of the Σ-type.

These operations would require unfolding the `abstract` definition, which Agda refuses to do. If a downstream module needs the specific slack value for some region, it must compute it independently (e.g., by importing `regionArea` and `S-cut` and doing the subtraction).

### 6.3 When Does This Matter?

For the existing proof architecture, the restriction is **irrelevant**:

- The bridge equivalence depends on the specification-agreement path (`obs-path`), which is **not** abstract and retains full computational content.
- The enriched equivalence round-trip proofs use `isProp≤ℚ` to close the structural-property fields, which works regardless of whether the specific proof term is visible or sealed.
- The `SchematicTower` carries `HalfBoundWitness` records as opaque proof-carrying data — the fields are consumed by the tower infrastructure (e.g., `ConvergenceCertificate3L-HB`) but never computationally reduced.

The `abstract` barrier would matter if a downstream module needed to **compute with** the inequality proof — e.g., extract the slack value to use in an arithmetic lemma. This never arises in the current architecture because the bridge operates on observable *functions* (which are fully computable), not on inequality *witnesses* (which are propositional and exist only to witness a property).

---

## 7. The Performance Profile

### 7.1 Without `abstract`

If the 717 cases in `Dense100AreaLaw.agda` were **not** sealed with `abstract`:

1. **Loading `Dense100AreaLaw.agda`:** ~30–120 seconds (parsing the 717-clause function + type-checking each `(k , refl)` individually). This is fine.

2. **Loading `Dense100Thermodynamics.agda`:** Agda imports `area-law` and must type-check its usage in the `CoarseGrainedRT` triple. Because the definition is visible, the normalizer *may* attempt to reduce `area-law r` for symbolic `r`, triggering partial unfolding of the 717-clause pattern match. Depending on how the downstream module uses the lemma, this can cause:
   - Moderate slowdown: 2–5× longer type-checking.
   - Severe slowdown: 10–100× longer, with RAM spikes.
   - Out-of-memory: the normalizer builds the full 717-case AST in memory.

3. **Loading `SchematicTower.agda`:** The tower module transitively imports `Dense100Thermodynamics.agda`, which imports `Dense100AreaLaw.agda`. If the chain is not broken, the 717-case definition may be re-normalized at each import level. The RAM cascade compounds.

### 7.2 With `abstract`

1. **Loading `Dense100AreaLaw.agda`:** ~30–120 seconds (same — the `abstract` block must still be verified). Possibly slightly faster because Agda can optimize the sealing.

2. **Loading `Dense100Thermodynamics.agda`:** The normalizer sees only the *type* of `area-law`. It never enters the 717-clause definition. Type-checking is fast (~5–15 seconds).

3. **Loading `SchematicTower.agda`:** The `abstract` barrier propagates: no downstream module ever re-normalizes the sealed proof. The tower loads in ~30–90 seconds (dominated by parsing large `data` declarations, not by proof normalization).

### 7.3 Expected Resource Usage

| Module | Parse Time | Check Time | Peak RAM |
|--------|-----------|------------|----------|
| `Boundary/Dense100AreaLaw.agda` | 20–60s | 30–120s | ~2–3 GB |
| `Boundary/Dense200AreaLaw.agda` | 30–90s | 60–180s | ~3–4 GB |
| `Boundary/Dense100HalfBound.agda` | 20–60s | 30–120s | ~2–3 GB |
| `Boundary/Dense200HalfBound.agda` | 30–90s | 60–180s | ~3–4 GB |
| `Boundary/FilledSubadditivity.agda` | 10–30s | 20–60s | ~1.5–2 GB |

These are first-load times (cold `.agdai` cache). Subsequent loads use the cached interface and are near-instantaneous. The key point: the RAM usage is **bounded to the module itself** — it does not cascade to downstream modules.

**Recommendation:** At least 8 GB of RAM for type-checking any individual `abstract` module. 16 GB is comfortable for the full repository.

---

## 8. Regeneration and Maintenance

### 8.1 The Oracle-Generated Pattern

All five `abstract` modules are generated by Python oracle scripts in `sim/prototyping/`:

| Module | Generator Script |
|--------|-----------------|
| `FilledSubadditivity.agda` | `03_generate_filled_patch.py` |
| `Dense100AreaLaw.agda` | `11_generate_area_law.py` |
| `Dense200AreaLaw.agda` | `12_generate_dense200.py` |
| `Dense100HalfBound.agda` | `17_generate_half_bound.py` |
| `Dense200HalfBound.agda` | `17_generate_half_bound.py` |

The Python oracle computes the correct slack value `k = area(r) − S(r)` (or `k = area(r) − 2·S(r)` for the half-bound) for each region `r`, then emits `area-law rN = k , refl`. The Agda type-checker verifies each emitted witness by reducing `k + S(r)` to `area(r)` on closed ℕ numerals.

If the upstream data changes (e.g., a different patch growth strategy produces different min-cut values), the modules must be **regenerated** by re-running the oracle script:

```bash
cd sim/prototyping
python3 11_generate_area_law.py          # regenerates Dense100AreaLaw.agda
python3 12_generate_dense200.py          # regenerates Dense200AreaLaw.agda
python3 17_generate_half_bound.py        # regenerates both HalfBound modules
```

After regeneration, **delete the cached interfaces** to force re-verification:

```bash
find src/ -name '*.agdai' -delete
```

### 8.2 Modifying an `abstract` Module

If you modify the **type signature** of an `abstract` definition (e.g., changing the observable function that appears in the type), all downstream modules that import it must be rechecked. This is normal Agda dependency behavior.

If you modify only the **proof body** inside `abstract` (e.g., changing a slack value from `5` to `7` because the upstream data changed), the downstream modules **do not** need rechecking — that is the entire point of `abstract`. However, the modified module itself must be re-verified, and the cached `.agdai` file must be regenerated.

### 8.3 Never Edit by Hand

The auto-generated `abstract` modules should **never** be edited by hand. They contain hundreds or thousands of clauses whose correctness depends on precise agreement between the observable functions (defined in Cut/Chain modules) and the area function (defined in the same module). A single typo — changing a slack value from `5` to `4` — produces a type error that the Agda checker will catch, but the resulting error message ("refl : suc (suc (suc (suc zero))) + ... ≡ ..." expected "suc (suc (suc (suc (suc zero)))) + ...") is uninformative without context.

To modify the data: change the Python oracle script, regenerate, and let Agda re-verify.

---

## 9. Relationship to Agda Issue #4573

[Agda GitHub Issue #4573](https://github.com/agda/agda/issues/4573) ("Slow typechecking unless using abstract in cubical") documents the exact performance cliff encountered in this repository. The key observations from the issue:

1. **The root cause** is Cubical Agda's normalization of terms involving Glue types. When `transport` or `ua` appears in the type of a downstream definition, the normalizer eagerly unfolds imported definitions to check that the Glue type reduces correctly. If an imported definition has a large case analysis (e.g., 360 subadditivity cases), the normalizer builds the entire AST in memory.

2. **The `abstract` workaround** is explicitly recommended by core developers. The key property: `abstract` definitions retain their *type* but lose their *computational content*. For propositional types, this is harmless.

3. **Alternative workarounds** discussed in the issue include `INLINE` pragmas, manual `opaque` blocks (an Agda 2.7+ feature), and postulating the lemma with a separate non-abstract verification module. The `abstract` approach is the simplest and is compatible with `--safe` mode.

4. **Future improvements** to Agda's normalizer (e.g., lazy evaluation of pattern-match clauses, or memoization of already-normalized case blocks) could reduce the need for `abstract` in future compiler versions. Until then, the `abstract` barrier is the pragmatic solution.

The repository's use of `abstract` is aligned with how the largest verified proofs in computer science were achieved: **external computation to find proofs, a simple kernel to check them, and sealing to prevent re-computation**. The Four Color Theorem in Coq, the Kepler Conjecture in HOL Light, and the Feit–Thompson Theorem in Coq all use analogous sealing mechanisms.

---

## 10. Design Principles

Five principles govern the repository's use of `abstract`:

1. **Seal propositions, not computations.** The `abstract` barrier is applied only to proof terms targeting propositional types (`_≤ℚ_`). Observable functions (`S-cut`, `L-min`, `regionArea`), specification-agreement paths (`obs-path`), and enriched equivalences are **never** sealed — their computational content is essential for `ua` and `transport`.

2. **One `abstract` block per proof obligation class.** Each module that uses `abstract` contains exactly one sealed definition covering all cases of a single proof obligation (e.g., all 717 area-law witnesses). This makes the sealing boundary clear and prevents accidental leakage.

3. **The oracle computes; Agda checks; `abstract` seals.** The Python oracle script is the search engine that finds the correct slack values. Agda verifies each `(k , refl)` witness individually (catching any oracle bug). After verification, `abstract` prevents the 717-case proof from being re-normalized in downstream modules.

4. **Scalar constants are shared across the barrier.** The constants `1q`, `2q` from `Util/Scalars.agda` and the observable functions from `Boundary/*Cut.agda` / `Bulk/*Chain.agda` are imported by both the sealed module and its downstream consumers. Identical normal forms are guaranteed because both sides import from the same source — the same principle documented in §11.5 of `historical/development-docs/08-tree-instance.md`.

5. **The barrier does not propagate silently.** When a downstream module imports an `abstract` lemma, the type signature is available but the definition is opaque. A developer reading the downstream code can see that `area-law` has type `S r ≤ area r` and that its proof is sealed. There is no hidden computational dependency that might break under refactoring.

---

## 11. Summary

| What | How |
|------|-----|
| **Problem** | Agda's normalizer re-expands large case analyses in downstream modules, causing RAM cascades |
| **Root cause** | Cubical Agda's Glue-type normalization eagerly unfolds imported definitions ([Issue #4573](https://github.com/agda/agda/issues/4573)) |
| **Solution** | Wrap propositional proofs in `abstract` to seal the definition body |
| **Safety** | `_≤ℚ_` is propositional (`isProp≤ℚ`), so sealing loses zero information |
| **Impact on bridge** | None — the Univalence bridge operates on observable functions, not on inequality witnesses |
| **Modules using `abstract`** | 5 modules, 3,986 total sealed proofs |
| **Oracle pipeline** | Python generates `(k , refl)` witnesses → Agda verifies → `abstract` seals |
| **Complementary to** | Orbit reduction (which handles `S = L` proofs on small orbit types) |
| **Regeneration** | Re-run the Python oracle script; delete `.agdai` caches; reload |

The `abstract` barrier is the repository's solution to the AST memory wall — the point where Cubical Agda's honest normalization strategy collides with the combinatorial scale of discrete holographic models. It is not a workaround or a hack; it is the architecturally correct response to a fundamental design property of dependently typed proof assistants: the De Bruijn Criterion demands a simple, trusted kernel, and `abstract` is the mechanism by which verified-but-heavy proofs are sealed for downstream consumption without re-verification cost.

---

## 12. Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all machine-checked results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (h-levels, propositionality) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Thermodynamics (area law, half-bound integration) | [`formal/09-thermodynamics.md`](../formal/09-thermodynamics.md) |
| Bekenstein–Hawking half-bound (formal) | [`formal/12-bekenstein-hawking.md`](../formal/12-bekenstein-hawking.md) |
| Oracle pipeline (Python-to-Agda generation) | [`engineering/oracle-pipeline.md`](oracle-pipeline.md) |
| Orbit reduction (complementary strategy) | [`engineering/orbit-reduction.md`](orbit-reduction.md) |
| Generic bridge pattern (PatchData → BridgeWitness) | [`engineering/generic-bridge-pattern.md`](generic-bridge-pattern.md) |
| Building & type-checking guide | [`getting-started/building.md`](../getting-started/building.md) |
| Architecture (module dependency DAG) | [`getting-started/architecture.md`](../getting-started/architecture.md) |
| Dense-100 instance data | [`instances/dense-100.md`](../instances/dense-100.md) |
| Dense-200 instance data | [`instances/dense-200.md`](../instances/dense-200.md) |
| Filled patch instance data | [`instances/filled-patch.md`](../instances/filled-patch.md) |
| Historical: the compiler RAM problem (§3.4 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §3.4 |
| Historical: workarounds and tradeoffs (§3.5 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §3.5 |
| Historical: the chosen strategy (§3.6 of frontier) | [`historical/development-docs/10-frontier.md`](../historical/development-docs/10-frontier.md) §3.6 |
| Agda Issue #4573 | [github.com/agda/agda/issues/4573](https://github.com/agda/agda/issues/4573) |