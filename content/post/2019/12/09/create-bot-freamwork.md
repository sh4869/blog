---
date: 2019-12-09T00:00:00+09:00
slug: "post"
tags: ["bot", "scala"]
title: "fs2(Scala)を使ったBotフレームワークを作る"
categories: ["tech"]
comments: true
draft: true
---

{{<is-advent-calendar link="https://adventar.org/calendars/4266" title="デジクリアドベントカレンダー" count="9">}}

こんにちは。この記事では、Scala の Stream プロセッシングライブラリである fs2 を使って、自作の**Bot フレームワーク**を作ってみたいと思います。

# はじめに

<!-- この記事で作るのはよくあるBotではなく**Botフレームワーク**です。この記事を読んでもなにかの言語でbotが作れるようになるわけではないことをご理解ください。 -->

Slack や Discord 等で使われるための Bot を作る、といった場合、どのようなプログラムを想定するでしょうか。多くの場合は使いたい言語の Slack のライブラリを利用したり、 hubot や ruboty といったフレームワークを利用することを考えるでしょう。IFTTT で済ませたりするかもしれません。今回の記事ではライブラリを利用して作る、ということではなく、利用するためのライブラリを作り、そのライブラリを使って Bot を作ることを考えてみましょう。

多くの場合、フレームワークやライブラリを選んで使うことはあっても、それを自分で作る経験というのは多くはないでしょう。今回は挑戦してみる手助けとして、Bot フレームワークを作ってみる過程を紹介していきたいと思います。

## 対象読者

この記事の読者に求める能力は次の通りです。

- なんかしらのライブラリやフレームワークを使ってプログラミングをしたことがある
- 書いたことのない言語をなんとなく読める
- 英語のリファレンスをどうにかなめるぐらいはできる

実装に使ったライブラリや概念は、なるべく文章中で説明するつもりです。一部どうしても難しい概念があるので、書いてあるざっくりとした説明だけを読んで、詳細がわかる必要はありません。

## Bot フレームワークを選んだ理由

Bot フレームワークを作ることを選んだのは、以下のような理由があります。

- 比較的考えることが少ない
  - パフォーマンスはそこまで求められない
  - 保存しないと行けない状態は少ない
    - リトライ機構とかを作ると保存する状態が発生するけど、そうでもない限りはそこまでデータの保存に気を使わなくていいはず。
- 実装にミスってもやり直しやすい
- 真面目にやろうとすると考えることが多い

一言にまとめると、「馴染みやすくて奥深い」と言ったところでしょうか。知っているべきことが多くないほうがわかりやすいという理由もあります^[現代の Web アプリケーションは正直複雑過ぎてある程度実用性を求めると作るのが大変になるので……]。

# 設計をする

早速コードを書くぞ、と言う前に、Bot フレームワークの設計を大まかに考えて行きましょう。コード上ですべてを 1 から考えるより、ある程度言葉で書き表すなどしてくほうが良いです。一般に言葉のほうが自由度が高いので。

## Bot フレームワークを調べる

設計を考える前に必要なのは、既存実装の調査です。一切のオリジナルからライブラリを作ってうまくいくことはまあほとんどないでしょう。現在あるライブラリから、ヒントを得てみることが必要です。既存実装の問題点を解決したり、自分が使っているうちにほしいと思った機能を考えたり、そういった観点からライブラリを作っていくのは大いにやりやすいでしょう。

今回は実装として、以下の 2 つを参考にしました。各フレームワークの紹介は別の記事に任せます。

- [hubot](https://hubot.github.com/)
- [ruboty](https://github.com/r7kamura/ruboty)

## 設計を考える

調査を終えたら、設計を考えてみましょう。実際には調査をしながら設計をしたり、設計をしたあとに調査をすることもあります^[これを研究でやると多くの場合絶望することになります]。

### 前提条件

今回フレームワークを作成するとき、以下のような条件をもとに作成していきます。

- パフォーマンスはそこまで重視しない
- なるべく問題はコンパイル時にチェックしたい
- 書きやすい

修正を。

## 入力・処理・出力

ところで、Bot を構成要素にわけるとどの様になるでしょうか。様々な分け方があると思いますが、私は入力・処理・出力の 3 つに分かれると考えました。

- 入力 : チャット等で入ってくるメッセージを受け取る部分
- 処理 : 入力を処理して出力に出す
- 出力 : メッセージを出力する部分

例えば、標準入力から受け取った文字列の先頭に`"Echo"`という文字列をつけて返す Bot を考えてみましょう。この場合、

- 入力 : 標準入力から文字列を受け取る
- 処理 : 入力の文字列に `"Echo"` を先頭に足す
- 出力 : 標準出力に出力

といった風に分けられると思います。この分け方は、それなりに自然に見えますね。見えるんです。

別の例を考えて見ましょう。5 秒ごとに `Hello!` と標準出力に表示する Bot を考えてみましょう。この場合、

- 入力 : 5 秒に 1 回信号を出力するタイマー
- 処理 : `Hello!`という文字列の作成
- 出力 : 標準出力に出力

という風にわけることができますね。

### 入力・処理・出力に分けるメリット^[この下のコードはすべて擬似コードです]

入力・処理・出力という構成要素に分けられると嬉しいことがいくつかあります。

#### 一つの入力から複数の処理が分けて書ける

例えば、Slack でメッセージを受け取って、それがあるユーザーのときだけデータベースに書き込み、そうでない場合はオウム返しをする Bot を考えてみましょう。

もし入力・処理・出力をわけていない場合、以下のように分岐するコードを書く必要があるでしょう。

```
input.then(message => {
    if(isSpecialUser(message.user)){
        // write db
    } else {
        // echo bot
    }
})
```

こう見ると、データベースに書き込む作業とオウム返しをする作業は全然違うのに、それらのコードが近くにあってなんだか分かりづらいですね。これを 3 つわけて考えるとどのようになるでしょうか。

```
val input = ...
val bot1 = input.filter(message => isSpecialUser(message.user)).map(/* write db*/)
val bot2 = input.filter(message => !isSpecialUser(message.user)).map(/* echo bot */)
```

このように各 Bot ごとにわけて書くことがができます。Output も同様になるでしょう。Input が適切に部品としてわけられて^[かつその部品が共有可能に実装されている必要がありますが]いれば、各処理をきれいに記述することができそうですね。

#### 違う媒体の入力と出力を繋げやすい

例えば、Slack のメッセージの条件にあうものを Discord に流してみることを考えます^[規約とかは自分で確認してください。すべての発言を垂れ流すやつは多分規約違反になる気がする]。この場合も、SlackとDiscordのInput Outputが適切に部品化されていれば、かんたんに記述することができますね。

```
val slackInput = ...
val discordOutput = ...
val bot = slackInput.filter(/* フィルター条件を書く*/).to(discordOutput)
```

## Input as a Stream, Output as a Stream

入力・処理・出力にわけることにしたら、それぞれをどのように表すかを考えましょう。様々な方法があり、一般に多く使われるのはいわゆるイベント駆動^[[Node\.jsのイベントループを理解する \| POSTD](https://postd.cc/understanding-the-nodejs-event-loop/)]です。

今回もそのアプローチをとってもいいのですが、

# 作成

## ベースコード

```scala
package net.sh4869.bot

import cats.effect.Concurrent
import fs2.Pipe
import fs2.Stream


object Core {
  // T
  type Input[F[_], T] = Stream[F, T]
  //
  type Output[F[_], T] = Pipe[F, T, Unit]
  type Process[F[_], I, O] = Pipe[F, I, O]

  // Bot。名前とInput、処理、Outputを受け取る。
  case class Bot[F[_] : Concurrent, I, O](name: String, input: Input[F, I], process: Process[F, I, O], output: Output[F, O]) {
    // Streamを
    def stream: Stream[F, Unit] = input.through(process).through(output)
  }
}
```

概ねこのコードをベースに実装をしていくと良さそうです。

```scala
package net.sh4869.bot

import cats.effect.Blocker
import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp
import com.softwaremill.macwire.wireSet
import fs2.Pipe
import fs2.Stream
import fs2.concurrent.Topic
import fs2.io
import fs2.text
import net.sh4869.bot.Core._

object MainApp extends IOApp {
  override def run(args: List[String]): IO[ExitCode] = {
    // stdinを共有するためのtopic
    val topic = Topic[IO, String]("").unsafeRunSync()
    val stream = Stream.resource(Blocker[IO]).flatMap(v => io.stdin[IO](4096, v).through(text.utf8Decode).through(topic.publish))

    // 1つ目のBot
    val input: Input[IO, String] = topic.subscribe(100)
    val pipe: Process[IO, String, String] = _.filter(!_.isEmpty).map(v => s"input1: $v")
    val output: Pipe[IO, String, Unit] = x => {
      Stream.resource(Blocker[IO]).flatMap(v => x.through(text.utf8Encode).through(io.stdout(v)))
    }
    val bot = Bot("bot1", input, pipe, output)

    // 2つ目のBot
    val input2: Input[IO, String] = topic.subscribe(100)
    val output2: Pipe[IO, Byte, Unit] = x => {
      Stream.resource(Blocker[IO]).flatMap(v => x.through(io.stdout(v)))
    }
    val pipe2: Process[IO, String, Byte] = _.filter(!_.isEmpty).map(v => s"input2: $v").through(text.utf8Encode)
    val bot2 = Bot("tes2", input2, pipe2, output2)

    lazy val bots = wireSet[Bot[IO, _, _]].toSeq
    Stream(bots.map(_.stream) :+ stream: _*).parJoinUnbounded.compile.drain.map(_ => ExitCode.Success)
  }
}

```

## エラー処理

```
$ sbt run
(中略)
1
2.0
x
java.lang.NumberFormatException: For input string: "x"
        at sun.misc.FloatingDecimal.readJavaFormatString(Unknown Source)
        at sun.misc.FloatingDecimal.parseDouble(Unknown Source)
        at java.lang.Double.parseDouble(Unknown Source)
        at scala.collection.StringOps$.toDouble$extension(StringOps.scala:930)
        at net.sh4869.bot.MainApp$.$anonfun$run$4(Main.scala:23)
        at fs2.Chunk$Singleton.map(Chunk.scala:510)
        at fs2.internal.Algebra$Output.$anonfun$mapOutput$1(Algebra.scala:22)
        at fs2.internal.FreeC$$anon$7.cont(FreeC.scala:168)
        at fs2.internal.FreeC$ViewL$$anon$9$$anon$10.<init>(FreeC.scala:204)
```

エラーを処理してほしい。

```scala
package net.sh4869.bot

import cats.effect.Blocker
import cats.effect.ExitCode
import cats.effect.IO
import cats.effect.IOApp
import com.softwaremill.macwire.wireSet
import fs2.Pipe
import fs2.Stream
import fs2.concurrent.Topic
import fs2.io
import fs2.text
import net.sh4869.bot.Core._

object MainApp extends IOApp {
  override def run(args: List[String]): IO[ExitCode] = {
    // stdinを共有するためのtopic
    val topic = Topic[IO, String]("").unsafeRunSync()
    val stream = Stream.resource(Blocker[IO]).flatMap(v => io.stdin[IO](4096, v).through(text.utf8Decode).through(topic.publish))

    // 1つ目のBot
    val input: Input[IO, String] = topic.subscribe(100)
    val pipe: Process[IO, String, Byte] = _.filter(!_.isEmpty).map(v => s"${v.toDouble + 1}\n").through(text.utf8Encode)
    val output: Pipe[IO, Byte, Unit] = x => {
      Stream.resource(Blocker[IO]).flatMap(v => x.through(io.stdout(v)))
    }
    val bot = Bot("bot1", input, pipe, output)
    lazy val bots = wireSet[Bot[IO, _, _]].toSeq
    Stream(Stream.resource(Blocker[IO]).flatMap(bl => Stream(bots.map(_.stream(bl)) :+ stream: _*))).parJoinUnbounded.compile.drain.map(_ => ExitCode.Success)
  }
}
```

## 利用するリソースを走らせる
