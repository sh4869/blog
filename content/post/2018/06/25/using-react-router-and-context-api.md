---
date: 2018-06-25T09:37:05+09:00
slug: "post"
tags: ["react", "web"]
title: "React RouterとContext APIを組み合わせて使う"
categories: ["tech"]
comments: true
---

React Router と Context API を組み合わせて使う方法について記述しておく。

# 環境

- React: 16.4.0
- React-Router: 4.2.2

# 問題

React Router v4 から history.push をするときに、state という引数を渡すことができるようになった。

```jsx
this.props.router.push({
  pathname: "/to",
  state: { test: "test" }
});
```

これは先のコンポーネントでは`this.props.localtion.state.test`として取得できるのだが、これをあまりやりたくない。理由はいくつかあって、

- そもそもデータの受け渡しの場所をむやみに増やしたくない
- `this.props.location`があるかどうかで処理を切り分けないといけない

といった理由があるんだけど、一番大きいのはブラウザをリロードしたときに URL がなんの意味も持たなくなってしまうから。

これを使わずにうまくやる方法をちょっと考えていて、React の Context API と組み合わせる方法を思いついたので書いておく。正直あまり正しい方法じゃない気もしているが。

# React Context and React Router

今回の方法の概要は以下のようになる。

1. Contextを作成し、親子コンポーネントに渡せるようにする
2. 親コンポーネントで子コンポーネントをルーティングする。
3. `Route`コンポーネントのrender内でContext.Providerを呼び出し、親コンポーネントのstateを渡す。
4. 子コンポーネントでContext.Consumerを呼び出して利用

## Context

まず Context を作成する。Context に関しては React の公式ドキュメントを見ればよいと思う。

```js
import { createContext } from "react";

const AppContext = createContext();

export default AppContext;
```

これで Context が共有できるようになったので親コンポーネント・子コンポーネントでそれぞれ import する。

## AppComponent

一番上のコンポーネントはこんな感じ。単純に React Router で BrowserRouter を使っているイメージ。

```js
const App = () => {
  return (
    <BrowserRouter>
      <Route path="/" component={MainPage} />
    </BrowserRouter>
  );
};
```

## 親コンポーネント

重要な部分だけ抜き出して書く。this.state.users はコンポーネントが初期生成されてからどっかから取ってくるデータ。`Router.render`の引数はpushされたときと同じ引数を持つので、パラメーターを参照することができる（今回であれば`props.match.params.id`）。

```jsx
class MainPage extends React.Component {
  render() {
    return (
      // ホントはいろいろある
      <Switch>
        <Route
          path="/user/:id"
          render={props => {
            return (
              <AppContext.Provider value={this.state.users[props.match.params.id]}>
                <UserPage />
              </AppContext.Provider>
            );
          }}
        />
      </Switch>
    );
  }
}
```

## 子コンポーネント

子コンポーネントはこんな感じで。AppContextから受け取ったuserのデータをもとにコンポーネントを生成する。

```jsx
class UserPage extends React.Component {
  render() {
    return (
      <div>
        <AppContext.Consumer>
          {user => <UserComponent {...user} />}
        </AppContext.Consumer>
      </div>
    );
  }
}
```

## この手法の利点

* `user/1`などの状態でリロードされても、親コンポーネントがデータを取得したあとにConsumerが受け取るデータが更新されるのでリロードが機能する
* 基本的にはどこからアクセスされたかなどを気にする必要はない
* ReactRouterの黒魔術にあまり頼らなくてすむ

## 問題点

* 親と子がガッツリ結合してしまう
* そもそもこんなことするならflux的にやったほうがいいのでは？


# 参考リンク

- [React で画面遷移を router\.push\(\) で行う時に、オブジェクトを遷移先のコンポーネントに渡す方法 \- Qiita](https://qiita.com/seya/items/9f01cff6ebe3aed9a0e9)
- [react\-router v4 変更点 Nested Routing など \- Qiita](https://qiita.com/iktakahiro/items/b8b4f699ad5de6aa2503)
- [ReactTraining/history: Manage session history with JavaScript](https://github.com/ReactTraining/history)
- [React v16\.3 changes \- blog\.koba04\.com](http://blog.koba04.com/post/2018/04/04/react-v163-changes/)
- [Context \- React](https://reactjs.org/docs/context.html)
