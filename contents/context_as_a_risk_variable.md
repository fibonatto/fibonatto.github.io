---

title: "Context as a Risk Variable"
date: "2026-05-14"
description: "A mathematical formulation for why more context does not imply more reliability in systems with LLMs"
---

# Against the Contextual Monotonicity Hypothesis
## An operational formulation for reliability degradation under context growth in systems with LLMs
A large part of contemporary engineering of systems with LLMs implicitly assumes a property of contextual monotonicity.

The hypothesis can be formulated informally as follows:

> adding context does not reduce reliability.

This premise appears in different architectures and operational strategies:

- continuous increase of context windows
- persistent memory between inference cycles
- aggressive retrieval via RAG
- serialization of entire repositories
- cumulative interaction history
- long-running stateful agents
- progressive expansion of operational memory

The intuitive justification seems reasonable. If the system has more information available during inference, then it should make better decisions.

However, this conclusion depends on an undue extrapolation from an ideal predictor to a finite-capacity approximate probabilistic model.

This text proposes an alternative operational formulation:
> in real generative systems, context must be treated simultaneously as a source of information and as a risk variable.
More precisely, contextual growth does not imply monotonicity of reliability.

## 1. Problem formulation
Consider an input space:
```
𝑐 = (𝑥₁,𝑥₂,…,𝑥ₙ)∈𝒳*
```
where:
    
- `𝑐` represents the operational context provided to the system, as an ordered sequence of tokens, documents, retrieved states or conditioning artifacts
- `𝒳*` represents the set of finite sequences over the alphabet `𝒳`
Also     consider:
    
- a task `𝑇`
- a set of acceptable outputs `𝐴_𝑇 ⊆ 𝒴`
- a parametrized generative model `𝑞_θ`

We define the operational reliability of the system as:
```
𝑅(𝑐) = ℙ           (𝑦∈ 𝐴 )
        𝑦∼ 𝑞 (·| 𝑐)     𝑇
            θ
```
**Notational note.** Since `𝑐` is a sequence, the addition of context `𝑛` represents concatenation, not set union. We denote concatenation by `𝑐 · 𝑛` or, when the order is irrelevant to the argument, by `(𝑐 , 𝑛)`.

The contextual monotonicity hypothesis can then be written as:
```
𝑅(𝑐 · 𝑛)≥ 𝑅(𝑐)
```
for any additional sequence `𝑛`.

A large part of contemporary architectures implicitly assumes this inequality.

This text argues that it is not guaranteed in approximate generative systems.

## 2. The extrapolation error
In information theory, let:
    
- `𝑌` be the variable to be predicted
- `𝑋ᵣ` the relevant subset of context
- `𝑋ₙ` additional context

Then the following holds:
```
𝐻(𝑌| 𝑋ᵣ,𝑋ₙ)≤ 𝐻(𝑌| 𝑋ᵣ)
```
The inequality is correct.

Conditioning on more variables does not increase the true conditional entropy, because an ideal predictor can always ignore irrelevant variables.

However, this property belongs to the true distribution $p$ of the observed process, not to the approximate model $q_\theta$ used operationally.

A parametrized generative system does not directly implement:
```
𝑝(𝑦| 𝑥ᵣ,𝑥ₙ)
```
It implements an approximation:
```
𝑞_θ (𝑦| 𝑥ᵣ,𝑥ₙ)
```
where:

- `θ` represents learned parameters
- inference occurs under a finite computational budget
- the real input is a concrete sequence of tokens
- relevance selection is approximate

The relevant operational question is not:

> is there useful information in `𝑋ₙ`?
The relevant operational question is:
> can the concrete system use `𝑋ₙ` without degrading the decision margin of the inference?
This is a question about approximation, statistical competition and operational stability.

## 3. Non-monotonic reliability
Consider a contextual decomposition:
```
𝑐 = (𝑠 · 𝑛)
```
where:

- `𝑠` represents relevant operational signal
- `𝑛` represents contextual noise, obsolete state, redundant information, conflicting instructions or spurious retrieval

The contextual monotonicity hypothesis assumes:
```
𝑅(𝑠 · 𝑛)≥ 𝑅(𝑠)
```
However, in approximate models, the operationally dangerous case is:
```
𝑅(𝑠 · 𝑛) < 𝑅(𝑠)
```
**Sufficient condition.** This occurs when the injection of `𝑛` shifts the distribution `𝑞_θ (· | 𝑠 · 𝑛)` away from `𝐴_𝑇` relative to `𝑞_θ (· | 𝑠). A formal sufficient condition is:

```
𝐷_𝐾𝐿(𝑝(·| 𝑠),|,𝑞_θ (·| 𝑠 · 𝑛)) > 𝐷_𝐾𝐿(𝑝(·| 𝑠) ∥ 𝑞_θ (·| 𝑠))
```

That is: the addition of `𝑛` increases the divergence between the model and the true distribution, degrading the probability of producing outputs in `𝐴_𝑇`. This condition is realizable whenever `𝑛` introduces sufficient competitive attentional mass to redistribute `𝑞_θ` — as formalized in Section 6.

This does not contradict information theory.

It contradicts only the extrapolation of ideal information theory to finite probabilistic models executing under real constraints.

## 4. Expected loss under imperfect conditioning

Consider the expected logarithmic loss (cross-entropy):
```
𝐿(𝑞_θ ,𝑐) = 𝔼_(𝑦∼ 𝑝(·| 𝑐))[ - log 𝑞 (𝑦| 𝑐)]
```
The formal decomposition of this quantity is:
```
𝐿(𝑞_θ ,𝑐) = 𝐻(𝑝(·| 𝑐)) + 𝐷_𝐾𝐿(𝑝(·| 𝑐) ∥ 𝑞_θ (·| 𝑐))
```
where `𝐻(𝑝(·| 𝑐))` is the irreducible entropy of the task and the `𝐷_𝐾𝐿` term captures all additional loss arising from the approximation.

In real operational systems, the `𝐷_𝐾𝐿` term can be interpreted as composed of three conceptually distinct sources:
```
𝐷_𝐾𝐿(𝑝(·| 𝑐) ∥ 𝑞_θ (·| 𝑐)) ≈ 𝑒_𝑎𝑝𝑝𝑟𝑜𝑥 + 𝑒_𝑐𝑜𝑛𝑡𝑒𝑥𝑡 + 𝑒_𝑠𝑒𝑙𝑒𝑐𝑡𝑖𝑜𝑛
```
where:

- `𝑒_𝑎𝑝𝑝𝑟𝑜𝑥` represents the intrinsic approximation error of the model — present even with ideal context
- `𝑒_𝑐𝑜𝑛𝑡𝑒𝑥𝑡` represents degradation induced by long, noisy or conflicting context
- `𝑒_𝑠𝑒𝑙𝑒𝑐𝑡𝑖𝑜𝑛` represents contextual selection error — relevant information present but not selected or not dominant

This decomposition of `𝐷_𝐾𝐿` is an operational interpretation, not a single formal identity. Its value lies in making explicit that `𝑒_𝑐𝑜𝑛𝑡𝑒𝑥𝑡` and `𝑒_𝑠𝑒𝑙𝑒𝑐𝑡𝑖𝑜𝑛` grow with the uncontrolled growth of `𝑐`.

The important consequence is:

> the presence of additional information does not imply a reduction in the observed operational loss.
The system may fail not because the correct information does not exist, but because it ceases to statistically dominate the inference process.

## 5. Decision margin
To simplify the analysis, consider the case where `𝒴 = {𝑦⁺, 𝑦⁻}`, where:
    
- `𝑦⁺` represents the correct output, with `𝐴_𝑇  = {𝑦⁺}`
- `𝑦⁻` represents an incorrect, regressive or unnecessary output

Define the logarithmic decision margin:
```
Δ(𝑐) = log 𝑞_θ (𝑦⁺| 𝑐) - log 𝑞_θ (𝑦⁻| 𝑐)
```
In this binary regime, operational reliability is related to the margin by the logistic function:
```
                                      1
𝑅(𝑐) = ℙ(𝑦 = 𝑦⁺ | 𝑐) = σ(Δ(𝑐)) = ———————————
                                      -Δ(𝑐)
                                  1 + 𝑒
```
Since `σ` is strictly increasing, it holds directly that:
```
Δ(𝑠 · 𝑛) < Δ(𝑠) ⟹ 𝑅(𝑠 · 𝑛) < 𝑅(𝑠)
```
Contextual degradation can therefore be interpreted as margin collapse: the addition of ` 𝑛` reduces `Δ`, which reduces `𝑅` monotonically. The system exhibits operational stability when:
```
Δ(𝑐) > 0
```
When the margin approaches zero, small perturbations become sufficient to change the final decision.

In code generation systems, this frequently appears operationally as:

- editing outside the requested scope
- invisible regression
- alteration of correct code
- recovery of obsolete state
- partial obedience to instructions
- semantically plausible but incorrect changes
- instability between equivalent cycles

The problem is not the absence of superficial coherence.

The problem is the loss of sufficient probabilistic separability between correct and incorrect solutions.

## 6. Contextual competition
In a simplified model of attentional competition, consider attention weights for the token at position `i`:
```
            exp( 𝑞ᵢ⊤ 𝑘ⱼ / √𝑑)
α   = —————————————————————————————————————
 𝑖𝑗     ─── 𝑚
        ╲   
        ╱⎽⎽   exp( 𝑞ᵢ⊤ 𝑘ₗ / √𝑑)
        𝑙 = 1   
```
where:

- `𝑞ᵢ ∈ ℝᵈ` represents the query vector of the token at position `𝑖`
- `𝑘ⱼ ∈ ℝᵈ` represents the key vector of the token at position `𝑗`
- `𝑑` represents the dimensionality of the attention space
- `𝑚` represents the total number of available tokens

**Note.** The symbol `𝑞ᵢ` (bold vector) denotes the attention query vector and is distinct from `𝑞_θ`, which denotes the parametrized generative model.

Separate the context into:

- `𝑆`: set of relevant token positions
- `𝑁`: set of irrelevant token positions

The attentional mass on the relevant signal, for the query position `𝑖`, is:

with:
```
         ───
         ╲
         ╱⎽⎽   exp(𝑧_𝑖𝑗)
         𝑗∈ 𝑆          
 (𝑖) = ———————————————————————————————
𝐴       ───                 ───
 𝑆      ╲                   ╲
        ╱⎽⎽   exp(𝑧_𝑖𝑗) +   ╱⎽⎽   exp(𝑧𝑖𝑗)
        𝑗∈ 𝑆                𝑗∈ 𝑁    
```
```
𝑧 = 𝑞ᵢ⊤𝑘ⱼ / √𝑑
```
Even when each irrelevant token has low individual relevance, the accumulated growth of the denominator can reduce the statistical dominance of the relevant signal. Formally, if `|𝑁| → ∞`with `exp(𝑧_𝑖𝑗) ` bounded away from zero for `𝑗 ∈ 𝑁`, then `𝐴ⁱ_𝑆 → 0` independently of the relevance of the tokens in `𝑆`.

The operational problem is not only computational cost.

It is probabilistic competition for inferential influence.

Modern architectures with head specialization, implicit sparsity and retrieval mechanisms partially mitigate this effect. However, such mechanisms do not eliminate the general problem of contextual competition under operational context growth.

## 7. Cumulative context as authoritative state
A large part of contemporary agentic systems treats accumulated probabilistic inference as an authoritative state representation.

Formally, consider the contextual growth between inference cycles:
```
𝑐ₜ₊₁ = 𝑐ₜ· ℎₜ· 𝑚ₜ
```
where `·` denotes sequence concatenation and:

- `𝑐ₜ` represents the context of the current cycle
- `ℎₜ` represents the interaction history added in cycle `𝑡`
- `𝑚ₜ` represents persistent memory content retrieved in cycle `𝑡`

This type of architecture tends to satisfy:
```
|𝑐ₜ₊₁| ≥ |𝑐ₜ|
```
where `·` denotes the sequence length. The continuous growth of context produces multiple consequences:

- increase in the conflict exposure
- increase in inferential cost
- reduction in auditability
- propagation of obsolete state
- amplification of spurious retrieval
- greater sensitivity to contextual ordering

The central problem is not memory itself.

The problem is turning accumulated probabilistic inference into an operational source of truth.

An incorrect inference persisted in memory can reappear later as a valid contextual premise.

This mechanism produces recursive contextual contamination: inference errors in cycle `𝑡` become contextual premises in cycle `𝑡 + 𝑘`, potentially amplifying `𝑒_𝑐𝑜𝑛𝑡𝑒𝑥𝑡` over time.

## 8. Deterministic context reconstruction

An architectural alternative consists of not accumulating operational context between inference cycles.

Instead, the context can be reconstructed deterministically from the verifiable state of the system.

Consider a repository `ℛₜ` in cycle `𝑡`.

A deterministic analyzer produces:
```
𝑆ₜ = 𝐴(ℛₜ)
```
where `𝐴` represents a deterministic structural analysis process.

This analyzer can compute:

- dependency graphs
- cyclomatic complexity
- cognitive complexity
- churn
- test coverage
- failure regions
- structural coupling
- typing
- risk metrics

A selector function then defines the operational context:
```
𝐶ₜ = π(𝑆ₜ,𝑇)
```
where:

- `𝑇` represents the current task
- `π` represents a contextual selection policy

The probabilistic agent does not receive the entire repository.

It receives only `𝐶ₜ` under an explicit constraint:
```
|𝐶ₜ| ≤ 𝐵
```
where `𝐵` represents a maximum operational context budget.

The model then proposes a change:
```
𝑃ₜ∼ 𝑞_θ (·| 𝐶ₜ,𝑇)
```
The state transition does not depend on the model's self-confidence.

It depends on an external verifier:
```
𝑉(ℛₜ, 𝑃ₜ) = 1 ⇒ ℛₜ₊₁ = 𝑎𝑝𝑝𝑙𝑦(ℛₜ, 𝑃ₜ)
```
```
𝑉(ℛₜ,𝑃ₜ) = 0 ⇒ ℛₜ₊₁  = ℛₜ
```
The verifier can include:
    
- compilation
- static analysis
- test execution
- structural invariants
- domain validations
- risk policies

In this regime, probabilistic inference becomes a subordinate component of a deterministic control loop.

## 9. Risk functions
Consider an operational risk function over the repository:
```
            𝑘
        ───
        ╲
Φ(ℛ) =  ╱⎽⎽   𝑤ᵢφᵢ(ℛ)
        𝑖 = 1
```
where:
    
- `φᵢ` represents deterministic metrics extracted from `ℛ`
- `𝑤ᵢ` represents weights defined by the system policy

**Relation to operational reliability.** Under regular conditions of contextual selection — in particular, when ` π` is a monotonic projection of `𝑆ₜ` and ` Φ` is computed over the same artifacts that compose `𝐶ₜ` — the following relation holds:
```
Φ(ℛₜ₊₁) < Φ(ℛₜ) implies 𝑅(𝐶ₜ₊₁) ≥ 𝑅(𝐶ₜ)
```
This relation is not universal: it depends on `π` being risk-sensitive, that is, on selecting regions of high `φᵢ` with priority. When this condition is satisfied, `Φ` serves as a measurable proxy for operational reliability.

Possible examples of `φ`:
    
- compilation errors
- test failures
- structural complexity
- high churn
- lint violations
- circular dependencies
- absence of minimum coverage
- historical instability

A conservative transition policy may require simultaneously:
```
𝑉(ℛₜ,𝑃ₜ) = 1
```
and:
```
Φ(ℛₜ₊₁)≤ Φ(ℛₜ)
```
For systems of automatic iterative improvement, the stronger condition may be required:
```
Φ(ℛₜ₊₁) <  Φ(ℛₜ)
```
In this regime, the system does not use the generative model as authority over the state.

It uses the model as a heuristic mechanism restricted by external verifiers.

## 10. Contextual convergence
Consider the set of high-risk code units in cycle `𝑡`:
```
𝑈ₜ = { 𝑢∈ ℛₜ : ρ(𝑢) > τ } 
```
where:

- `ρ(𝑢)` represents the local risk of unit `𝑈`, computed deterministically (for example, as a linear combination of `φᵢ` over `𝑢`)
- `τ > 0` represents an operational threshold

Define the operational context as the structural neighborhood of `𝑈ₜ`:
```
𝐶ₜ = 𝑛𝑒𝑖𝑔ℎ𝑏𝑜𝑟ℎ𝑜𝑜𝑑_𝐺(𝑈ₜ)
```
where `𝐺` is the dependency graph of `𝑅ₜ` and `𝑛𝑒𝑖𝑔ℎ𝑏𝑜𝑟ℎ𝑜𝑜𝑑 (𝑈)` denotes the set of units at edge distance `≤ 𝑘` from some element of `𝑈` in `𝐺`.

With this definition, `𝑛𝑒𝑖𝑔ℎ𝑏𝑜𝑟ℎ𝑜𝑜𝑑_𝐺` is monotonic: `𝑈 ⊆ 𝑈' ⇒ 𝑛𝑒𝑖𝑔ℎ𝑏𝑜𝑟ℎ𝑜𝑜𝑑 (𝑈) ⊆ 𝑛𝑒𝑖𝑔ℎ𝑏𝑜𝑟ℎ𝑜𝑜𝑑 (𝑈')`. Therefore:
```
|𝑈ₜ₊₁| < |𝑈ₜ|  ⇒ |𝐶ₜ₊₁| ≤ |𝐶ₜ|
```
The expression above does not constitute universal proof of convergence — it depends on `Φ(ℛₜ)` being strictly decreasing across cycles, which requires the conditions of Section 9.

It describes a desirable architectural property:

> the system must possess structural pressure to reduce operational context as the state converges.
Architectures based on cumulative memory frequently produce the opposite property:
```
|𝐶ₜ₊₁| ≥ |𝐶ₜ|
```
even when the system approaches operational stability.

## 11. Appropriate limits for probabilistic inference
The fundamental problem is not using probabilistic models.

The fundamental problem is allowing probabilistic models to become authorities over operational state.

Generative models are particularly useful for:
    
- synthesis
- heuristic search
- structural transformation
- semantic compression
- approximate exploration of large spaces

However, verifiable operational state must remain in deterministic artifacts:
    
- code
- types
- tests
- builds
- metrics
- graphs
- structured logs
- analyzers
- formal or semi-formal verifiers

The context provided to the model must be a temporary projection of these artifacts.

Not an accumulated probabilistic memory of what the system believes happened.

## 12. Conclusion
The contextual monotonicity hypothesis is not guaranteed in approximate generative systems.

The relevant operational formulation is not:
```
argmax_𝑐  𝑅(𝑐) = argmax_𝑐|𝑐|
```
In real systems, the correct problem is:
```
argmax_𝑐  𝑅(𝑐)  ≠ argmax_𝑐|𝑐|
```
The best context is not necessarily the largest.

It is the context that maximizes operational reliability under real inference constraints.

Consequently, robust architectures for agentic systems must:

- reconstruct context deterministically from `ℛₜ`
- explicitly limit the contextual budget via ` |𝐶ₜ| ≤ 𝐵`
- separate verifiable state (`ℛₜ`) from probabilistic inference (`𝑞_θ`)
- use external verifiers for state transitions
- prevent authoritative persistence of unverified inference
- reduce operational context as the system converges, via `|𝑈ₜ|↓ ⇒ |𝐶ₜ| ↓`

The path to more reliable generative systems probably does not consist of unrestricted expansion of operational memory.

It consists of progressively reducing probabilistic authority over the system state.

Probabilistic inference must operate within deterministic envelopes capable of:

- reconstructing state
- selecting context
- validating transitions
- rejecting regressions
- measuring risk externally
- limiting contextual propagation

The operational reliability of systems with LLMs depends less on the absolute amount of context available and more on the architectural capacity to control how context is produced, selected, validated and discarded.
