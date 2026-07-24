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
* continuous increase of context windows
* persistent memory between inference cycles
* aggressive retrieval via RAG
* serialization of entire repositories
* cumulative interaction history
* long-running stateful agents
* progressive expansion of operational memory

The intuitive justification seems reasonable. If the system has more information available during inference, then it should make better decisions.
However, this conclusion depends on an undue extrapolation from an ideal predictor to a finite-capacity approximate probabilistic model.

This text proposes an alternative operational formulation:
> in real generative systems, context must be treated simultaneously as a source of information and as a risk variable.
More precisely, contextual growth does not imply monotonicity of reliability.

## 1. Problem formulation
Consider an input space:
$$
c=(x_1,x_2,\dots,x_n)\in\mathcal{X}^*
$$
where:
* $c$ represents the operational context provided to the system, as an ordered sequence of tokens, documents, retrieved states or conditioning artifacts
* $\mathcal{X}^*$ represents the set of finite sequences over the alphabet $\mathcal{X}$
Also consider:
* a task $T$
* a set of acceptable outputs $A_T \subseteq \mathcal{Y}$
* a parametrized generative model $q_\theta$

We define the operational reliability of the system as:
$$
R(c)=\mathbb{P}_{y\sim q_\theta(\cdot\mid c)}(y\in A_T)
$$
**Notational note.** Since $c$ is a sequence, the addition of context $n$ represents concatenation, not set union. We denote concatenation by $c \cdot n$ or, when the order is irrelevant to the argument, by $(c, n)$.

The contextual monotonicity hypothesis can then be written as:
$$
R(c \cdot n)\ge R(c)
$$
for any additional sequence $n$.
A large part of contemporary architectures implicitly assumes this inequality.
This text argues that it is not guaranteed in approximate generative systems.

## 2. The extrapolation error
In information theory, let:
* $Y$ be the variable to be predicted
* $X_r$ the relevant subset of context
* $X_n$ additional context

Then the following holds:
$$
H(Y\mid X_r,X_n)\le H(Y\mid X_r)
$$
The inequality is correct.
Conditioning on more variables does not increase the true conditional entropy, because an ideal predictor can always ignore irrelevant variables.
However, this property belongs to the true distribution $p$ of the observed process, not to the approximate model $q_\theta$ used operationally.
A parametrized generative system does not directly implement:
$$
p(y\mid x_r,x_n)
$$
It implements an approximation:
$$
q_\theta(y\mid x_r,x_n)
$$
where:
* $\theta$ represents learned parameters
* inference occurs under a finite computational budget
* the real input is a concrete sequence of tokens
* relevance selection is approximate
The relevant operational question is not:
> is there useful information in $X_n$?
The relevant operational question is:
> can the concrete system use $X_n$ without degrading the decision margin of the inference?
This is a question about approximation, statistical competition and operational stability.

## 3. Non-monotonic reliability
Consider a contextual decomposition:
$$
c=(s \cdot n)
$$
where:
* $s$ represents relevant operational signal
* $n$ represents contextual noise, obsolete state, redundant information, conflicting instructions or spurious retrieval

The contextual monotonicity hypothesis assumes:
$$
R(s \cdot n)\ge R(s)
$$
However, in approximate models, the operationally dangerous case is:
$$
R(s \cdot n)<R(s)
$$
**Sufficient condition.** This occurs when the injection of $n$ shifts the distribution $q_\theta(\cdot \mid s \cdot n)$ away from $A_T$ relative to $q_\theta(\cdot \mid s)$. A formal sufficient condition is:
$$
D_\text{KL}\!\left(p(\cdot\mid s)\,\|\,q_\theta(\cdot\mid s \cdot n)\right) > D_\text{KL}\!\left(p(\cdot\mid s)\,\|\,q_\theta(\cdot\mid s)\right)
$$
That is: the addition of $n$ increases the divergence between the model and the true distribution, degrading the probability of producing outputs in $A_T$. This condition is realizable whenever $n$ introduces sufficient competitive attentional mass to redistribute $q_\theta$ — as formalized in Section 6.
This does not contradict information theory.
It contradicts only the extrapolation of ideal information theory to finite probabilistic models executing under real constraints.

## 4. Expected loss under imperfect conditioning
Consider the expected logarithmic loss (cross-entropy):
$$
L(q_\theta,c)=\mathbb{E}_{y\sim p(\cdot\mid c)}[-\log q_\theta(y\mid c)]
$$
The formal decomposition of this quantity is:
$$
L(q_\theta,c) = H(p(\cdot\mid c)) + D_\text{KL}\!\left(p(\cdot\mid c)\,\|\,q_\theta(\cdot\mid c)\right)
$$
where $H(p(\cdot\mid c))$ is the irreducible entropy of the task and the $D_\text{KL}$ term captures all additional loss arising from the approximation.
In real operational systems, the $D_\text{KL}$ term can be interpreted as composed of three conceptually distinct sources:
$$
D_\text{KL}\!\left(p(\cdot\mid c)\,\|\,q_\theta(\cdot\mid c)\right) \;\approx\; e_{\mathrm{approx}} + e_{\mathrm{context}} + e_{\mathrm{selection}}
$$
where:
* $e_{\mathrm{approx}}$ represents the intrinsic approximation error of the model — present even with ideal context
* $e_{\mathrm{context}}$ represents degradation induced by long, noisy or conflicting context
* $e_{\mathrm{selection}}$ represents contextual selection error — relevant information present but not selected or not dominant

This decomposition of $D_\text{KL}$ is an operational interpretation, not a single formal identity. Its value lies in making explicit that $e_{\mathrm{context}}$ and $e_{\mathrm{selection}}$ grow with the uncontrolled growth of $c$.
The important consequence is:
> the presence of additional information does not imply a reduction in the observed operational loss.
The system may fail not because the correct information does not exist, but because it ceases to statistically dominate the inference process.

## 5. Decision margin
To simplify the analysis, consider the case where $\mathcal{Y} = \{y^+, y^-\}$, where:
* $y^+$ represents the correct output, with $A_T = \{y^+\}$
* $y^-$ represents an incorrect, regressive or unnecessary output
Define the logarithmic decision margin:
$$
\Delta(c)=\log q_\theta(y^+\mid c)-\log q_\theta(y^-\mid c)
$$
In this binary regime, operational reliability is related to the margin by the logistic function:
$$
R(c) = \mathbb{P}(y = y^+ \mid c) = \sigma(\Delta(c)) = \frac{1}{1+e^{-\Delta(c)}}
$$
Since $\sigma$ is strictly increasing, it holds directly that:
$$
\Delta(s \cdot n) < \Delta(s) \implies R(s \cdot n) < R(s)
$$
Contextual degradation can therefore be interpreted as margin collapse: the addition of $n$ reduces $\Delta$, which reduces $R$ monotonically. The system exhibits operational stability when:
$$
\Delta(c)>0
$$
When the margin approaches zero, small perturbations become sufficient to change the final decision.

In code generation systems, this frequently appears operationally as:
* editing outside the requested scope
* invisible regression
* alteration of correct code
* recovery of obsolete state
* partial obedience to instructions
* semantically plausible but incorrect changes
* instability between equivalent cycles

The problem is not the absence of superficial coherence.
The problem is the loss of sufficient probabilistic separability between correct and incorrect solutions.

## 6. Contextual competition
In a simplified model of attentional competition, consider attention weights for the token at position $i$:
$$
\alpha_{ij}=
\frac{
\exp(\mathbf{q}_i^\top \mathbf{k}_j/\sqrt{d})
}{
\sum_{l=1}^{m}\exp(\mathbf{q}_i^\top \mathbf{k}_l/\sqrt{d})
}
$$
where:
* $\mathbf{q}_i \in \mathbb{R}^d$ represents the query vector of the token at position $i$
* $\mathbf{k}_j \in \mathbb{R}^d$ represents the key vector of the token at position $j$
* $d$ represents the dimensionality of the attention space
* $m$ represents the total number of available tokens

**Note.** The symbol $\mathbf{q}_i$ (bold vector) denotes the attention query vector and is distinct from $q_\theta$, which denotes the parametrized generative model.

Separate the context into:
* $S$: set of relevant token positions
* $N$: set of irrelevant token positions

The attentional mass on the relevant signal, for the query position $i$, is:
$$
A_S^{(i)}=
\frac{
\sum_{j\in S}\exp(z_{ij})
}{
\sum_{j\in S}\exp(z_{ij})+
\sum_{j\in N}\exp(z_{ij})
}
$$
with:
$$
z_{ij}=\mathbf{q}_i^\top \mathbf{k}_j/\sqrt{d}
$$
Even when each irrelevant token has low individual relevance, the accumulated growth of the denominator can reduce the statistical dominance of the relevant signal. Formally, if $|N| \to \infty$ with $\exp(z_{ij})$ bounded away from zero for $j \in N$, then $A_S^{(i)} \to 0$ independently of the relevance of the tokens in $S$.
The operational problem is not only computational cost.
It is probabilistic competition for inferential influence.
Modern architectures with head specialization, implicit sparsity and retrieval mechanisms partially mitigate this effect. However, such mechanisms do not eliminate the general problem of contextual competition under operational context growth.

## 7. Cumulative context as authoritative state
A large part of contemporary agentic systems treats accumulated probabilistic inference as an authoritative state representation.
Formally, consider the contextual growth between inference cycles:
$$
c_{t+1} = c_t \cdot h_t \cdot m_t
$$
where $\cdot$ denotes sequence concatenation and:
* $c_t$ represents the context of the current cycle
* $h_t$ represents the interaction history added in cycle $t$
* $m_t$ represents persistent memory content retrieved in cycle $t$

This type of architecture tends to satisfy:
$$
|c_{t+1}|\ge |c_t|
$$
where $|\cdot|$ denotes the sequence length. The continuous growth of context produces multiple consequences:
* increase in the conflict exposure
* increase in inferential cost
* reduction in auditability
* propagation of obsolete state
* amplification of spurious retrieval
* greater sensitivity to contextual ordering

The central problem is not memory itself.
The problem is turning accumulated probabilistic inference into an operational source of truth.
An incorrect inference persisted in memory can reappear later as a valid contextual premise.
This mechanism produces recursive contextual contamination: inference errors in cycle $t$ become contextual premises in cycle $t+k$, potentially amplifying $e_{\mathrm{context}}$ over time.

## 8. Deterministic context reconstruction
An architectural alternative consists of not accumulating operational context between inference cycles.
Instead, the context can be reconstructed deterministically from the verifiable state of the system.
Consider a repository $\mathcal{R}_t$ in cycle $t$.
A deterministic analyzer produces:
$$
S_t=A(\mathcal{R}_t)
$$
where $A$ represents a deterministic structural analysis process.
This analyzer can compute:
* dependency graphs
* cyclomatic complexity
* cognitive complexity
* churn
* test coverage
* failure regions
* structural coupling
* typing
* risk metrics

A selector function then defines the operational context:
$$
C_t=\pi(S_t,T)
$$
where:
* $T$ represents the current task
* $\pi$ represents a contextual selection policy

The probabilistic agent does not receive the entire repository.
It receives only $C_t$ under an explicit constraint:
$$
|C_t|\le B
$$
where $B$ represents a maximum operational context budget.
The model then proposes a change:
$$
P_t\sim q_\theta(\cdot\mid C_t,T)
$$
The state transition does not depend on the model's self-confidence.
It depends on an external verifier:
$$
V(\mathcal{R}_t,P_t)=1\Rightarrow \mathcal{R}_{t+1}=\operatorname{apply}(\mathcal{R}_t,P_t)
$$
$$
V(\mathcal{R}_t,P_t)=0\Rightarrow \mathcal{R}_{t+1}=\mathcal{R}_t
$$
The verifier can include:
* compilation
* static analysis
* test execution
* type checking
* structural invariants
* domain validations
* risk policies

In this regime, probabilistic inference becomes a subordinate component of a deterministic control loop.

## 9. Risk functions
Consider an operational risk function over the repository:
$$
\Phi(\mathcal{R})=\sum_{i=1}^{k}w_i\phi_i(\mathcal{R})
$$
where:
* $\phi_i$ represents deterministic metrics extracted from $\mathcal{R}$
* $w_i$ represents weights defined by the system policy

**Relation to operational reliability.** Under regular conditions of contextual selection — in particular, when $\pi$ is a monotonic projection of $S_t$ and $\Phi$ is computed over the same artifacts that compose $C_t$ — the following relation holds:
$$
\Phi(\mathcal{R}_{t+1}) < \Phi(\mathcal{R}_t) \implies R(C_{t+1}) \ge R(C_t)
$$
This relation is not universal: it depends on $\pi$ being risk-sensitive, that is, on selecting regions of high $\phi_i$ with priority. When this condition is satisfied, $\Phi$ serves as a measurable proxy for operational reliability.
Possible examples of $\phi_i$:
* compilation errors
* test failures
* structural complexity
* high churn
* lint violations
* circular dependencies
* absence of minimum coverage
* historical instability

A conservative transition policy may require simultaneously:
$$
V(\mathcal{R}_t,P_t)=1
$$
and:
$$
\Phi(\mathcal{R}_{t+1})\le \Phi(\mathcal{R}_t)
$$
For systems of automatic iterative improvement, the stronger condition may be required:
$$
\Phi(\mathcal{R}_{t+1})<\Phi(\mathcal{R}_t)
$$
In this regime, the system does not use the generative model as authority over the state.
It uses the model as a heuristic mechanism restricted by external verifiers.

## 10. Contextual convergence
Consider the set of high-risk code units in cycle $t$:
$$
U_t=\{u\in \mathcal{R}_t:\rho(u)>\tau\}
$$
where:
* $\rho(u)$ represents the local risk of unit $u$, computed deterministically (for example, as a linear combination of $\phi_i$ over $u$)
* $\tau > 0$ represents an operational threshold

Define the operational context as the structural neighborhood of $U_t$:
$$
C_t=\operatorname{neighborhood}_G(U_t)
$$
where $G$ is the dependency graph of $\mathcal{R}_t$ and $\operatorname{neighborhood}_G(U)$ denotes the set of units at edge distance $\le k$ from some element of $U$ in $G$.
With this definition, $\operatorname{neighborhood}_G$ is monotonic: $U \subseteq U' \Rightarrow \operatorname{neighborhood}_G(U) \subseteq \operatorname{neighborhood}_G(U')$. Therefore:
$$
|U_{t+1}|<|U_t|\Rightarrow |C_{t+1}|\le |C_t|
$$
The expression above does not constitute universal proof of convergence — it depends on $\Phi(\mathcal{R}_t)$ being strictly decreasing across cycles, which requires the conditions of Section 9.
It describes a desirable architectural property:
> the system must possess structural pressure to reduce operational context as the state converges.
Architectures based on cumulative memory frequently produce the opposite property:
$$
|C_{t+1}|\ge |C_t|
$$
even when the system approaches operational stability.

## 11. Appropriate limits for probabilistic inference
The fundamental problem is not using probabilistic models.
The fundamental problem is allowing probabilistic models to become authorities over operational state.
Generative models are particularly useful for:
* synthesis
* heuristic search
* structural transformation
* semantic compression
* approximate exploration of large spaces

However, verifiable operational state must remain in deterministic artifacts:
* code
* types
* tests
* builds
* metrics
* graphs
* structured logs
* analyzers
* formal or semi-formal verifiers

The context provided to the model must be a temporary projection of these artifacts.
Not an accumulated probabilistic memory of what the system believes happened.

## 12. Conclusion
The contextual monotonicity hypothesis is not guaranteed in approximate generative systems.
The relevant operational formulation is not:
$$
\operatorname{argmax}_c R(c)=\operatorname{argmax}_c |c|
$$
In real systems, the correct problem is:
$$
\operatorname{argmax}_c R(c)\ne \operatorname{argmax}_c |c|
$$
The best context is not necessarily the largest.
It is the context that maximizes operational reliability under real inference constraints.
Consequently, robust architectures for agentic systems must:
* reconstruct context deterministically from $\mathcal{R}_t$
* explicitly limit the contextual budget via $|C_t| \le B$
* separate verifiable state ($\mathcal{R}_t$) from probabilistic inference ($q_\theta$)
* use external verifiers for state transitions
* prevent authoritative persistence of unverified inference
* reduce operational context as the system converges, via $|U_t| \downarrow \Rightarrow |C_t| \downarrow$

The path to more reliable generative systems probably does not consist of unrestricted expansion of operational memory.
It consists of progressively reducing probabilistic authority over the system state.
Probabilistic inference must operate within deterministic envelopes capable of:
* reconstructing state
* selecting context
* validating transitions
* rejecting regressions
* measuring risk externally
* limiting contextual propagation

The operational reliability of systems with LLMs depends less on the absolute amount of context available and more on the architectural capacity to control how context is produced, selected, validated and discarded.