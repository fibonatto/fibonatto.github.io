---
title: "The Speed of Light and the Illusion of Infinite Intelligence"
date: "2026-08-11"
description: "Why bigger models alone won't solve the problems of AI reliability, and why we need better architecture instead."
--- 

---
At first, it feels wrong to say that

```
0.999… = 1.
```

After all, `0.999…` looks like it should be slightly smaller than `1`. There seems to be an infinitely small gap between them.

That gap does not exist. To see why, we first need to say what `0.999…` actually means.

## What the notation means

A decimal expansion with infinitely many digits is not a "number with a never-ending last digit". By definition, it is the limit of its finite truncations:

```
 0.999… := lim 𝑠ₙ,
           𝑛→∞
        𝑛
      ───
      ╲      9
𝑠ₙ =  ╱⎽⎽   ——— = 0.99…9           .
      𝑘 = 1  10ᵏ      (𝑛 𝑑𝑖𝑔𝑖𝑡𝑠)
```


This is the only sensible meaning: we cannot add infinitely many terms one by one, so "the value" has to be the number the partial sums approach.

## The partial sums

The first few are

```
          1
𝑠₁ = 1 - ——,
         10

          1
𝑠₂ = 1 - ———,
         100

           1
𝑠₃ = 1 - ————.
         1000         
```

In general,

```
          1
𝑠ₙ = 1 - ———.
         10ⁿ

```

(Proof by induction: `𝑠₁ = 1 − 1/10`, and `if 𝑠ₙ = 1 − 10⁻ⁿ`, then
 `𝑠ₙ₊₁ = 𝑠ₙ + 9 · 10⁻ⁿ⁻¹
      = 1 − 10 · 10⁻ⁿ⁻¹ + 9 · 10⁻ⁿ⁻¹
      = 1 − 10⁻ⁿ⁻¹`.)

## The limit

We claim `𝑠ₙ → 1`. Let `ε > 0`. Since `10ⁿ > 𝑛`, there is an `𝑁` with `10⁻ᴺ < ε`. For every `𝑛≥ 𝑁`,

```
|1 - 𝑠ₙ| = 10⁻ⁿ ≤ 10⁻ᴺ < ε

```

So the partial sums eventually stay within any distance `ε` of `1`, which is exactly the definition of

```
lim 𝑠ₙ = 1.
𝑛→∞
```

Therefore
```
 _____________
| 0.999… = 1. |
 ------------- 
```

Note what this says: the decimal is not "getting closer to `1` without reaching it". The sequence of truncations never reaches `1`, but the infinite decimal is the *limit* of that sequence, and the limit is `1`.

## The same result as a shortcut

The digits form a geometric series with first term $a = \tfrac{9}{10}$ and ratio $r = \tfrac{1}{10}$. For $|r|<1$, such a series sums to

$$
\frac{a}{1-r} = \frac{9/10}{9/10} = 1.
$$

This is not an independent proof. The formula $a/(1-r)$ is derived from the same partial-sum limit we just computed. It is a convenient way to get the answer without redoing the work.

## Where the "infinitely small gap" goes

Let $d = 1 - 0.999\ldots$. Since $s_n \le 0.999\ldots$ for every $n$, we have

$$
0 \le d \le 1 - s_n = \frac{1}{10^n}\quad\text{for every } n.
$$

So $d$ is a non-negative real number smaller than every $10^{-n}$. But the real numbers are Archimedean: for any $d>0$ there is an $n$ with $10^{-n} < d$. Hence $d = 0$.

In other words, a positive "infinitely small gap" would be a real number that is positive yet smaller than every $1/10^n$, and no such real number exists. That is the precise form of the intuition that there is a gap.

## The popular argument, and why it is incomplete

You have probably seen this:

$$
x = 0.999\ldots,\quad 10x = 9.999\ldots,\quad 10x - x = 9 \;\Rightarrow\; x = 1.
$$

It reaches the right answer, but it assumes that multiplying by $10$ and subtracting work on infinite decimals the way they do on finite ones. That is exactly what has to be justified. It can be justified, using the definition of the limit and the fact that limits respect arithmetic, but then the real work is the limit argument above.

## What about infinitesimals?

In the real numbers there are none. In systems that do contain them, such as the hyperreals, the decimal $0.999\ldots$ with one digit for each natural number still equals $1$. A number like $1-10^{-H}$ for an infinite hypernatural $H$ is infinitely close to $1$ but different from it. It is a different object, not a reading of the same notation.

## Two representations of one number

The notation, then, is not the strange part. The mathematics is part of the answer: completeness and the Archimedean property of the reals are what rule out the gap. What the notation does allow is two decimal representations of the same number, and this is not special to $1$. Every terminating decimal has one:

$$
0.5 = 0.4999\ldots,\qquad 0.25 = 0.24999\ldots
$$

$$
\boxed{0.999\ldots = 1.000\ldots}
$$
