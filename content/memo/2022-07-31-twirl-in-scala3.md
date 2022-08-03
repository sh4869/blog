---
title: Scala3でtwirlを使う
date: 2022-07-31
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

Play frameworkのテンプレートエンジンであるtwirlは単体でも使うことができるのだけど、Scala3で使うときはちょっと工夫が必要。

<a href="https://github.com/playframework/twirl" class="embedly-card">playframework/twirl: Twirl is Play's default template engine</a>

まず`project/pluigins.sbt`に以下のようにプラグインを指定する（これはドキュメントに書いてある通り）。

```scala
addSbtPlugin("com.typesafe.play" % "sbt-twirl" % "1.6.0-M6")
```

このままだとScala2.12用のtwirl-apiしかインストールされなて、`play.twirl....` が存在しないというエラーが生成されたファイルに対して出るので、これを防ぐために`build.sbt`のlibraryDependenciesに以下を追加する。 

```scala
"com.typesafe.play" % "twirl-api_3" % "1.6.0-M6"
```

あとはドキュメントに書いてあるとおり、使いたいプロジェクトで

```
enablePlugins(SbtTwirl)
```

を指定する。

これでちゃんと動く。Scala3用のバージョンは1.6.0以降でないと存在しないので、そこは注意。

使い方に関しては、比較的古い記事だが以下の記事を読み替えていけば問題なく動く。

<a href="https://kazuhira-r.hatenablog.com/entry/20140920/1411223858" class="embedly-card">テンプレートエンジンTwirlを試してみる - CLOVER🍀</a>
