---
date: 2020-11-12T17:21:55+09:00
slug: "post"
tags: ["scala", "docker"]
title: "AlpakkaのUnix Domain Socketサポートを使ってScalaからDocker Engine APIを叩く"
categories: ["tech"]
comments: true
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

Docker Engine API はその名の通り Docker の API である。基本的に `docker` コマンドはこの API を使って実装されているので、この API を使えばコマンドでできることがすべてできる（僕の理解では）。

<a href="https://docs.docker.com/engine/api/" class="embedly-card">Develop with Docker Engine API | Docker Documentation</a>

この API は Unix Domain Socket を使って通信している。[サンプル](https://docs.docker.com/engine/api/sdk/examples/)では Python, Go, curl でのサンプルがあるが、Unix Domain Socket を使えればどの言語でも実装できる。Scala では[alpakka](https://doc.akka.io/docs/alpakka/current/index.html)が Unix Domain Socket をサポートしているので、これを使う。

<a href="https://doc.akka.io/docs/alpakka/current/unix-domain-socket.html" class="embedly-card">Unix Domain Socket • Alpakka Documentation</a>

これでおしまいかというと、Unix Domain Socket は HTTP を喋ることを想定されていないので、どうにかして喋らせる必要がある。[ここ](https://stackoverflow.com/questions/51565935/how-to-access-rest-api-on-a-unix-domain-socket-with-akka-http-or-alpakka)で書かれてるみたいに頑張ってもいいのだけど、なんかうまい方法ないかなぁと思って探してたら見つかった。

<a href="https://github.com/akka/akka-http/issues/2139#issuecomment-413535497" class="embedly-card">ClientTransport.connectTo API tightly coupled to TCP's host/port paradigm · Issue #2139 · akka/akka-http</a>

ちょっと改造したものがこちら。

```scala
import java.net.InetSocketAddress
import java.nio.file.FileSystems

import scala.concurrent.ExecutionContext
import scala.concurrent.Future

import akka.actor.ActorSystem
import akka.http.scaladsl._
import akka.http.scaladsl.settings.ClientConnectionSettings
import akka.stream.alpakka.unixdomainsocket.scaladsl.UnixDomainSocket
import akka.stream.scaladsl._
import akka.util.ByteString
import cats.effect.Async

// copy from https://github.com/akka/akka-http/issues/2139#issuecomment-413535497
object DockerSockTransport extends ClientTransport {
  lazy val path: java.nio.file.Path =
    FileSystems.getDefault().getPath("/var/run/docker.sock")
  override def connectTo(host: String, port: Int, settings: ClientConnectionSettings)(implicit
      system: ActorSystem
  ): Flow[ByteString, ByteString, Future[Http.OutgoingConnection]] = {
    // ignore everything for now
    UnixDomainSocket().outgoingConnection(path).mapMaterializedValue { _ =>
      // Seems that the UnixDomainSocket.OutgoingConnection is never completed?
      // It works anyway if we just assume it is completed
      // instantly
      Future.successful(
        Http.OutgoingConnection(
          InetSocketAddress.createUnresolved(host, port),
          InetSocketAddress.createUnresolved(host, port)
        )
      )
    }
  }
}

lazy val settings = ConnectionPoolSettings(system).withTransport(DockerSockTransport)

def request[F, A](path: String)(implicit um: Unmarshaller[HttpResponse, A], ec: ExecutionContext, f: Async[F]): F[A] = {
  f.async[A] { cb: (Either[Throwable, A] => Unit) =>
    Http()
      .singleRequest(HttpRequest(uri = s"http://localhost/${path}"), settings = settings)
      .flatMap(res => Unmarshal(res).to[A])
      .onComplete {
        case Success(v)         => cb(Right(v))
        case Failure(exception) => cb(Left(exception))
      }
    }
}
```

catsの文脈で操作したかったので多少変えてるが、基本的にはサンプルと変わりない。一応動くという感じなので、もしかしたら常用していると問題がわかるかもしれない。