---
date: 2019-06-05T14:48:36+09:00
slug: "post"
tags: ["memo"]
title: "『Build systems à la carte』メモ"
categories: ["tech"]
comments: true
draft: true
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

Build systems à la carteを読んだ内容をまとめるメモです。

# Build systems à la carteについて

ICFP2018にて発表された論文。著者は[Andrey Mokhov](https://dl.acm.org/author_page.cfm?id=81367593993&coll=DL&dl=ACM&trk=0)ら。Proceedings of the ACM on Programming LanguagesのVolume 2にて発行されている。Microsoft ResarchのSimon Peyton Jonesが共著者としている関係か、Microsoft Researchにも[紹介ページ](https://www.microsoft.com/en-us/research/publication/build-systems-la-carte/)がある。ACMのページからもMSRのページからもPDFがダイレクトで読めるようになっている。

<a href="https://dl.acm.org/citation.cfm?id=3236774" class="embedly-card">Build systems à la carte</a>

この論文では、多くの開発の場で使われているビルドシステムがほとんど研究の目的になっていないことから、ビルドシステムを開発・比較可能なフレームワークを作成し、実際に存在するビルドシステムを個々の独立したシステムとして見るのではなく、その関連点を検討し、新たなビルドシステムにおいて望ましい特性がなにかを考えられるようにしている。

Andrey Mokhov氏のブログの記事で、この論文を書いた意図の解説が載せられている。近年MicrosoftやFacebook、Googleといった大きなソフトウェア作成の会社では、ビルドシステムを作成することが近年行われている。そのため、ビルドシステムを作成するときに「このビルドシステムは本当に正しいのか？」や「どのアプローチを採用するとどのようなデメリットがあるのか？」といった疑問を持つ人が増えてきた。その問題を解決するため、ビルドシステムを理解し比較することが実装^[Haskellのコードで実装する]と抽象の両方の観点から可能にするものであるということである。また、この論文で、ビルドシステムを構築する上で選ぶ必要のある要素を明確にしたということを上げている。詳しくはブログ内の表を参照してほしい。

<a href="https://blogs.ncl.ac.uk/andreymokhov/build-systems-a-la-carte/" class="embedly-card">Build Systems à la Carte | no time</a>

このブログ記事では、Build Systems à la Carteの内容を論文にそって解説していく^[なんでこんなことをやるかというとラボの論文紹介で紹介するからです。どう説明していくのがいいのかわからない。根本的に複数のビルドシステムを触ったことがない人が読めるものでもないので、そのあたりから探っていくためにとりあえず全体の内容を把握しておきたい]。僕が理解するためのメモなので、論文が読める人はそのまま読んだほうが良いです。

# 論文内容

## 1. Introduction

ビルドシステムはソフトウェア開発者であれば誰でも使ったことがあるはずだが^[原文では "and used by every software developer on the planet" となっている。スケールがでかい。]、ソフトウェアのエコシステムの中で愛されていない分野であり、またその研究も多くはないということが指摘されている。

TODO: 導入をちゃんとまとめる

## 2. Background

BackGroundでは、Make、Shake、Bazel、Excelの4つを例に取り、ビルドシステムがなにかについて説明している。

TODO: 各例と結論をまとめる

## 3. BUILD SYSTEMS, ABSTRACTLY

ビルドシステムとはなにかについてHaskellでの抽象化をもとに定義している。

TODO: 各抽象化のコードの説明をしつつやる

## 4. BUILD SYSTEMS À LA CARTE

上で行った抽象化を元に、実際のビルドシステムにおける差異を示す。

## 5. BUILD SYSTEMS, CONCRETELY

背景で示した4つのビルドシステムを上での抽象化に基づき実装する。

## 6. ENGINEERING ASPECTS

工学的な側面の話

## 7. RELATED WORK

その他

## 8. CONCLUSIONS

結論
