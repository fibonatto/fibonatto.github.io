---

title: "Tipos dependentes e programas que carregam provas"
date: "2026-04-03"
description: "Uma breve explicação sobre tipos dependentes e provas formais"

---
# Tipos dependentes e programas que carregam provas
Em sistemas de tipos convencionais, uma função costuma ser descrita como:
$$f : A \to B$$
Aqui, o tipo de saída não depende do valor concreto de entrada.
Com tipos dependentes, isso muda:
$$\Pi (n : \mathbb{N}), \mathrm{Vec}\ A\ n \to \mathrm{Vec}\ A\ n$$
Nesse caso, o comprimento do vetor faz parte do próprio tipo.
A assinatura afirma formalmente que a função preserva o tamanho da estrutura.
Esse tipo de construção permite que propriedades sejam verificadas antes mesmo da execução.

## Curry-Howard
Sob a correspondência de Curry-Howard:
$$A \to B$$
também pode ser lido como:
uma prova de que A implica B.
Uma abstração lambda:
$$\lambda x : A.\ t$$
é simultaneamente uma função e uma prova parametrizada.

## Igualdade como tipo
Em teoria de tipos intensional, igualdade não é apenas equivalência sintática:
$$x =_A y$$
Esse tipo só é habitado quando existe uma prova explícita de igualdade.
A forma mais básica é reflexividade:
$$\mathrm{refl} : x = x$$

## Vetores indexados
Concatenação tipada de vetores:
$$\mathrm{append} : \Pi (n\,m : \mathbb{N}), \mathrm{Vec}\ A\ n \to \mathrm{Vec}\ A\ m \to \mathrm{Vec}\ A\ (n+m)$$
Aqui, o tipo final carrega a prova estrutural de que o comprimento resultante é a soma dos comprimentos originais.

## Redução lambda
No cálculo lambda tipado:
$$(\lambda x.\ x)\ t \to t$$
A redução preserva o tipo:
$$\Gamma \vdash t : A \implies \Gamma \vdash t' : A$$
sempre que:
$$t \to t'$$
Esse é um dos fundamentos formais da segurança semântica em linguagens de prova.