# Bibliography

**All citations referenced in the Univalence Gravity repository documentation and source code.**

**Organization:** Entries are grouped into four sections — Holographic Duality & Quantum Gravity, Discrete Geometry & Lattice Physics, Formal Methods & Proof Assistants, and Homotopy Type Theory & Univalent Foundations. Within each section, entries are sorted alphabetically by first author's family name. Each entry includes the citation key used in `docs/papers/theory.tex` where applicable.

---

## 1. Holographic Duality & Quantum Gravity

**[Bekenstein1973]** Bekenstein, J. D. (1973). "Black Holes and Entropy." *Physical Review D*, 7(8):2333–2346.
— The original proposal that black hole entropy is proportional to horizon area: S = A / 4ℓ²_P. The discrete analogue S(A) ≤ area(A)/2 is Theorem 3 of this repository, formalized in `Bridge/HalfBound.agda`.

**[Hawking1975]** Hawking, S. W. (1975). "Particle Creation by Black Holes." *Communications in Mathematical Physics*, 43(3):199–220.
— Derives the Hawking temperature and confirms the Bekenstein entropy formula from quantum field theory on curved spacetime. Together with [Bekenstein1973], establishes the Bekenstein–Hawking formula S = A / 4G.

**[Jacobson1995]** Jacobson, T. (1995). "Thermodynamics of Spacetime: The Einstein Equation of State." *Physical Review Letters*, 75(7):1260–1263. arXiv:gr-qc/9504004.
— Derives Einstein's field equations from the Clausius relation δQ = TδS applied to local Rindler horizons, assuming entropy–area proportionality. The repository's discrete half-bound (1/(4G) = 1/2) instantiates Jacobson's first premise. Referenced in [`physics/translation-problem.md`](../physics/translation-problem.md) §4, [`physics/three-hypotheses.md`](../physics/three-hypotheses.md) §2.

**[Maldacena1997]** Maldacena, J. (1998). "The Large N Limit of Superconformal Field Theories and Supergravity." *Advances in Theoretical and Mathematical Physics*, 2(2):231–252. arXiv:hep-th/9711200.
— The foundational paper of the AdS/CFT correspondence: the physics of a gravitational bulk is encoded on its lower-dimensional boundary. All bridge constructions in this repository are discrete combinatorial analogues of this duality.

**[MaldacenaSusskind2013]** Maldacena, J. and Susskind, L. (2013). "Cool Horizons for Entangled Black Holes." *Fortschritte der Physik*, 61(9):781–811. arXiv:1306.0533.
— The ER=EPR conjecture: entangled particles are connected by Einstein–Rosen bridges. Supports the "geometry from entanglement" paradigm that the repository formalizes discretely.

**[Padmanabhan2010]** Padmanabhan, T. (2010). "Thermodynamical Aspects of Gravity: New Insights." *Reports on Progress in Physics*, 73(4):046901. arXiv:0911.5004.
— Develops the thermodynamic perspective on gravity, extending Jacobson's approach. Referenced alongside [Jacobson1995] and [Verlinde2011] in [`physics/three-hypotheses.md`](../physics/three-hypotheses.md).

**[Pastawski2015]** Pastawski, F., Yoshida, B., Harlow, D., and Preskill, J. (2015). "Holographic Quantum Error-Correcting Codes: Toy Models for the Bulk/Boundary Correspondence." *Journal of High Energy Physics*, 2015(6):149. arXiv:1503.06237.
— The HaPPY code: a tensor-network model of holographic quantum error correction on the {5,4} hyperbolic tiling. The primary physical model behind this repository — all patch constructions, min-cut computations, and bridge equivalences originate from this paper's discrete RT formula.

**[Ryu2006]** Ryu, S. and Takayanagi, T. (2006). "Holographic Derivation of Entanglement Entropy from AdS/CFT." *Physical Review Letters*, 96(18):181602. arXiv:hep-th/0603001.
— The Ryu–Takayanagi formula: S(A) = Area(γ_A) / 4G_N. The discrete analogue S_cut(A) = L_min(A) is Theorem 1 of this repository, formalized generically in `Bridge/GenericBridge.agda`.

**[Strominger2001]** Strominger, A. (2001). "The dS/CFT Correspondence." *Journal of High Energy Physics*, 2001(10):034. arXiv:hep-th/0106113.
— The conjectured dS/CFT correspondence for de Sitter space. The discrete Wick rotation (Theorem 4, `Bridge/WickRotation.agda`) connects AdS-like ({5,4}) and dS-like ({5,3}) regimes without complex analysis.

**[VanRaamsdonk2010]** Van Raamsdonk, M. (2010). "Building Up Spacetime with Quantum Entanglement." *General Relativity and Gravitation*, 42(10):2323–2329. arXiv:1005.3035.
— Argues that spacetime geometry emerges from quantum entanglement — the "It from Qubit" paradigm. The repository's central theorem S_cut = L_min is the discrete formalization of this claim.

**[Verlinde2011]** Verlinde, E. (2011). "On the Origin of Gravity and the Laws of Newton." *Journal of High Energy Physics*, 2011(4):029. arXiv:1001.0785.
— Proposes gravity as an entropic force derived from information-theoretic considerations. Referenced with [Jacobson1995] and [Padmanabhan2010] in the entropy-first route of [`physics/three-hypotheses.md`](../physics/three-hypotheses.md).

**[Wall2012]** Wall, A. (2014). "Maximin Surfaces, and the Strong Subadditivity of the Covariant Holographic Entanglement Entropy." *Classical and Quantum Gravity*, 31(22):225007. arXiv:1211.3494.
— The maximin prescription for covariant holographic entanglement entropy. The `maximin` functional in `Causal/CausalDiamond.agda` is the discrete analogue.

---

## 2. Discrete Geometry & Lattice Physics

**[AmbjornJurkiewiczLoll2004]** Ambjørn, J., Jurkiewicz, J., and Loll, R. (2004). "Emergence of a 4D World from Causal Quantum Gravity." *Physical Review Letters*, 93(13):131301. arXiv:hep-th/0404156.
— Causal Dynamical Triangulations: a path-integral approach to quantum gravity on discrete causal spacetimes. The `CausalDiamond` type in `Causal/CausalDiamond.agda` encodes a finite causal interval in a related discrete framework.

**[BhanotCreutz1981]** Bhanot, G. and Creutz, M. (1981). "Variant Actions and Phase Structure in Lattice Gauge Theory." *Physical Review D*, 24(12):3212–3217.
— Demonstrates that finite subgroups of continuous gauge groups can be used in lattice gauge computations. This provides the mathematical precedent for the Q₈ ⊂ SU(2) replacement strategy in `Gauge/Q8.agda`.

**[BombelliLeeMeyerSorkin1987]** Bombelli, L., Lee, J., Meyer, D., and Sorkin, R. D. (1987). "Space-Time as a Causal Set." *Physical Review Letters*, 59(5):521–524.
— Foundational paper on causal set theory: spacetime modeled as a locally finite partially ordered set. The `Event` and `CausalChain` types in `Causal/Event.agda` encode a stratified version of this structure.

**[Regge1961]** Regge, T. (1961). "General Relativity Without Coordinates." *Il Nuovo Cimento*, 19(3):558–571.
— Regge calculus: gravity on a simplicial lattice where curvature lives on hinges. The 3D edge curvature in `Bulk/Honeycomb3DCurvature.agda` and `Bulk/Dense{50,100,200}Curvature.agda` follows this approach.

**[Rovelli1998]** Rovelli, C. (1998). "Loop Quantum Gravity." *Living Reviews in Relativity*, 1(1):1. arXiv:gr-qc/9710008.
— Review of loop quantum gravity, where area and volume operators have discrete spectra on spin networks. The dimension functor `dimQ8` in `Gauge/RepCapacity.agda` (extracting ℕ-valued bond capacities from representation labels) is the discrete analogue of the LQG area spectrum.

**[RovelliSmolin1995]** Rovelli, C. and Smolin, L. (1995). "Discreteness of Area and Volume in Quantum Gravity." *Nuclear Physics B*, 442(3):593–619. arXiv:gr-qc/9411005.
— Proves that area and volume are quantized in loop quantum gravity. The sharp half-bound S ≤ area/2 with 1/(4G) = 1/2 in bond-dimension-1 units (Theorem 3, `Bridge/HalfBound.agda`) is consistent with this quantization.

**[Wilson1974]** Wilson, K. G. (1974). "Confinement of Quarks." *Physical Review D*, 10(8):2445–2459.
— Foundational paper on lattice gauge theory: group elements on lattice links, Wilson loop observables around plaquettes. The `GaugeConnection`, `holonomy`, and `ParticleDefect` types in `Gauge/Connection.agda` and `Gauge/Holonomy.agda` implement this formulation for finite groups on the holographic network.

---

## 3. Formal Methods & Proof Assistants

**[Gonthier2005]** Gonthier, G. (2005). "A Computer-Checked Proof of the Four Colour Theorem." Unpublished manuscript, Microsoft Research Cambridge.
— The first computer-verified proof of the Four Color Theorem in Coq. Establishes the "external oracle + simple kernel" paradigm used by this repository: Python scripts find proofs, Agda checks them.

**[Hales2017]** Hales, T. C. et al. (2017). "A Formal Proof of the Kepler Conjecture." *Forum of Mathematics, Pi*, 5:e2.
— The Flyspeck project: a formal verification of the Kepler Conjecture in HOL Light using computation-intensive case analysis. The `abstract`-sealed large case analyses in `Boundary/Dense{100,200}AreaLaw.agda` and `Boundary/Dense{100,200}HalfBound.agda` follow an analogous sealing strategy.

---

## 4. Homotopy Type Theory & Univalent Foundations

**[CCHM2018]** Cohen, C., Coquand, T., Huber, S., and Mörtberg, A. (2018). "Cubical Type Theory: A Constructive Interpretation of the Univalence Axiom." *Journal of Automated Reasoning*, 60(2):195–230. arXiv:1611.02108.
— The CCHM paper: defines the interval type, PathP, Glue types, and the computational Univalence axiom that powers every transport in this repository. The `uaβ` computation rule (transport along `ua e` equals `equivFun e`) is the mechanism by which the holographic bridge produces computable output.

**[HoTTBook2013]** The Univalent Foundations Program. (2013). *Homotopy Type Theory: Univalent Foundations of Mathematics.* Institute for Advanced Study. Available at https://homotopytypetheory.org/book/.
— The standard reference for HoTT: identity types, transport, equivalences, Univalence, h-levels, and truncation. Chapters 1–4 and 7 provide the mathematical background for [`formal/02-foundations.md`](../formal/02-foundations.md).

**[VezzosiMortbergAbel2021]** Vezzosi, A., Mörtberg, A., and Abel, A. (2021). "Cubical Agda: A Dependently Typed Programming Language with Univalence and Higher Inductive Types." *Journal of Functional Programming*, 31:e8.
— The implementation paper for Cubical Agda: the `--cubical` flag, native PathP, computational `ua`, and HITs. Every module in this repository uses `{-# OPTIONS --cubical --safe --guardedness #-}` and imports from the `agda/cubical` library described in this paper.

---

## 5. This Repository

**[Bichtemann2025]** Bichtemann, S. (2025). "Univalence Gravity: A Constructive Formalization of Discrete Entanglement-Geometry Duality in Cubical Agda." Repository: https://github.com/m4ximum-opus/univalence-gravity. Version 0.4.0.
— This repository. Cite using the metadata in [`CITATION.cff`](../CITATION.cff).

---

## Cross-References

| Topic | Document |
|-------|----------|
| Theorem registry (all formal results) | [`formal/01-theorems.md`](../formal/01-theorems.md) |
| HoTT foundations (ua, transport, funExt) | [`formal/02-foundations.md`](../formal/02-foundations.md) |
| Holographic dictionary (Agda ↔ physics) | [`physics/holographic-dictionary.md`](../physics/holographic-dictionary.md) |
| Translation problem (honest assessment) | [`physics/translation-problem.md`](../physics/translation-problem.md) |
| Three hypotheses for the continuum | [`physics/three-hypotheses.md`](../physics/three-hypotheses.md) |
| Five walls (hard boundaries) | [`physics/five-walls.md`](../physics/five-walls.md) |
| LaTeX paper (theory.tex) | [`papers/theory.tex`](../papers/theory.tex) |
| Citation metadata | [`CITATION.cff`](../CITATION.cff) |