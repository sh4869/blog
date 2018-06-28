---
date: "2017-12-10T17:11:05+09:00"
slug: "post"
aliases:
    - /posts/2017/12/10/2017-12-11-boilerplate-of-static-site/
categories: ["tech"]
tags: ["tech", "Web"]
title: "静的Webサイトを作るためのボイラープレート"
comments: true
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

大学のサークルや所属団体等で静的なWebサイトを作成する機会が多かったため，自分が便利に開発できるようにボイラープレートを作成していました．これの解説をしてみたいと思います．

{{<embedly src="https://github.com/sh4869/my-website-boilerplate" title="sh4869/my-website-boilerplate: My Website Boilerplate">}}

## 前提

* 他人に引き継ぐ場合が多いので自動生成を使うにしてもきれいな生成ファイルが吐き出され，それが編集できる必要がある
* 他人に引き継ぐ場合が多いので Web Application のように構築するとつらくなるのでやめる
* 大抵デプロイ先とか用意されていないので GitHub Pages で済ませられるなら済ませたほうがいい
* HTMLは**絶対手書きしたくない**
* CSSも**できれば手書きしたくない**
* ビルドをするなら一発でしたい
* LiveReload は可能であれば使いたい
* 再構築はかんたんにしたい
* Windows でも Linux でも動作させたい

## ツール選択

### プラットフォームの選択 : npm

ボイラープレートを制作する上でモジュール等を誰でも簡単に取得できるようにすることが必要なため，パッケージマネージャに乗っかれることが必要でした．Bundlerを利用してRuby の Gem を使う，npm を使う等の選択肢がありましたが，今回は npm を使いました．理由としては，

* パッケージマネージャとしてかなり成熟している
* CLI 等も管理できる
* Web 関連のモジュールが多い
* Windows でもなんだかんだ動く

といったことが挙げられます．

### 拡張言語の選択 : Pug,Scss

HTMLは **絶対手書きしたくない** ですし， CSS も**できれば手書きしたくない**ので，それぞれに対して手書きしなくて住むような拡張言語^[様々な表現があるかと思いますが，統一された表現が見つからなかったのでここでは仮に拡張言語という言葉を使います]を選択する必要があります．

HTMLの拡張言語としては

- haml
- Pug
- Slim(?)

CSS の拡張言語としては

- Sass(Scss)
- LESS
- Post CSS

等があります．今回はこの中から HTML は Pug ， CSS の拡張言語としては SCSS を選択しました．

{{<embedly src="https://pugjs.org/api/getting-started.html" title="Getting Started – Pug">}}

{{<embedly src="http://sass-lang.com/assets/img/illustrations/glasses-2087d741.svg" title="Sass: Syntactically Awesome Style Sheets">}}

HTML の拡張言語として利用したことがあったのは haml と Pug でした．このどちらかを選ぶ場合，haml は Ruby での実装なのでWindowsでの利用に若干の不安が残りました．個人的な感覚ではありますが，Windows での利用で npm の方が信頼が置けたことや， include 構文が強力だったこと， 他にも後述しますが Gulp 等を使って Json 等のデータを流し込めることから Pug を選択しました．

Scss を選択したのは当時一番良くメンテナンスされていた^[気がする]というのが挙げられます．node-sass への信頼があったこともあるかもしれません．Webページをコンポーネント意識的に組むときにそれぞれのコンポーネントに対して ファイルを定義していい感じにしてあげることができるのも大きいとは思います．

どちらの言語もWeb 開発の文脈でよく利用されるということから npm からの利用がかんたんであったというのも大きな決め手です．2つとも生成された言語は可読性がそれなりにあるのでよいかなぁと思い利用しました．

### ビルドツールの選択 : gulp

Webサイトのビルドを行うにあたって，Pug や Scss をいちいち手でトランスパイルするのは流石に厳しいものがあります．利便性の点からも，変換を自動化できるようにしておいたほうが良いです．

一度 npm script で完結させることも考えましたが，複雑な処理になるとその他のビルドツールに比べて可読性が低くしんどくなるのでミニマムなプロジェクトであってもビルド用のツールを選択する必要があると思い， gulp を選択しました．

なぜ gulp を選んだのかというと，

* プラグインが多いため大抵のことに関してプラグインがあるためほぼほぼ`npm install`を叩くだけでモジュールの準備が完了する
* 複数ファイルを対象にしてビルドするとき使いやすい
* 慣れてた

といった理由からです^[今Gulpを選ぶかと言われると何とも言えないところがあります]．

---

## システム説明

では選択ツールの話もおわったので，実際にどのような package.json や gulpfile.js を使っているのか解説しておきたいと思います．

### package.json

```json
{
  "name": "my-website-boilerplate",
  "version": "1.0.0",
  "description": "My WebSite Boilerplate",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "sh4869",
  "license": "MIT",
  "devDependencies": {
    "gulp": "^3.9.1",
    "gulp-connect": "^5.0.0",
    "gulp-data": "^1.2.1",
    "gulp-plumber": "^1.1.0",
    "gulp-pug": "^3.3.0",
    "gulp-sass": "^3.1.0",
    "sass-module-importer": "^1.4.0"
  }
}
```

dependencies をそれぞれ解説しておきたいと思います．

* `gulp` : 言わずもがな
* `gulp-connect` : LiveReload 用．ビルドを保存時にやってるのに読み込みを自動化しないの馬鹿らしいなと思ったので．
* `gulp-data` : 後述しますがデータを pug に流し込みたいときに利用
* `gulp-plumber` : エラー時の処理に利用
* `gulp-pug` : pugのビルドに利用
* `gulp-sass` : sassのビルドに利用
* `sass-module-importer` : npmで提供されている css のファイルを sass の import 文で import 出来るようになるのでめちゃくちゃ便利

npm のいいところは package.json にまとめて記述しておけば相手が npm の環境さえ整えておいてくれれば問題がないというところです．

### gulpfile.js

gulpfile.js はこのようになっています．

```js
const fs = require("fs");
const gulp = require("gulp");
const plumber = require("gulp-plumber");
const pug = require("gulp-pug");
const data = require("gulp-data");
const sass = require("gulp-sass");
const connect = require('gulp-connect');
const moduleImporter = require("sass-module-importer");

gulp.task('pug', () => {
    gulp.src(["www/pug/**/*.pug", "!www/pug/include/*.pug"], { base: "www/pug/" })
        .pipe(plumber({
            errorHandler: (err) => {
                console.log(err);
            }
        }))
        .pipe(data(
            (file) => {
                const dirname = __dirname + "/www/data/";
                const files = fs.readdirSync(dirname);
                let json = {};
                files.forEach((name) => {
                    json[name.replace(".json", "")] = JSON.parse(fs.readFileSync(dirname + name));
                });
                return { data: json };
            })
        )
        .pipe(pug({ pretty: true }))
        .pipe(gulp.dest("dest/"))
        .pipe(connect.reload());
})

gulp.task("img", () => {
    return gulp.src(["www/img/**/*.png", "www/img/**/*.jpg"], { base: "www/img/" })
        .pipe(gulp.dest("dest/img/"));
});

gulp.task("css", () => {
    return gulp.src("www/scss/index.scss", { "base": "www/scss" })
        .pipe(plumber({
            errorHandler: (err) => {
                console.log(err);
            }
        }))
        .pipe(sass({ outputStyle: 'expanded', importer: moduleImporter() }).on('error', sass.logError))
        .pipe(gulp.dest("dest/css/"))
        .pipe(connect.reload());
});

gulp.task("favicon", () => {
    return gulp.src("www/favicon/*")
        .pipe(gulp.dest("dest/favicon/"));
})

gulp.task("cname", () => {
    return gulp.src("www/CNAME")
        .pipe(gulp.dest("dest/"));
})

gulp.task("build", ["img", "pug", "css", "cname", "favicon"], () => {

});

gulp.task('watch', () => {
    gulp.watch(["www/pug/**/*.pug", "www/datas/**/*.json"], ["pug"]);
    gulp.watch(["www/scss/**/*.scss"], ["css"]);
    gulp.watch(["www/img/**/*.png", "www/img/**/*.jpg"], ["img"])
})

gulp.task('connect', () => {
    connect.server({
        root: "dest",
        livereload: true,
        port: 9000
    })
});

gulp.task('default', ["build", "watch","connect"]);
```

基本的には gulp を実行すると pug や scss のトランスパイルと画像等のコピー，LiveReloadが始まるようになっています．ディレクトリ構成はこんな感じです．

```cmd
> tree /F 
Folder PATH listing for volume Windows
Volume serial number is F671-19D7
C:.
│   .gitignore
│   .travis.yml
│   gulpfile.js
│   package.json
│   README.md
│   test.txt
│   
├───dest # 出力フォルダ
│   │   CNAME
│   │   index.html
│   │   
│   ├───css
│   │       index.css
│   │       
│   ├───favicon
│   │       android-chrome-192x192.png
│   │       android-chrome-384x384.png
│   │       apple-touch-icon.png
│   │       browserconfig.xml
│   │       favicon-16x16.png
│   │       favicon-32x32.png
│   │       favicon.ico
│   │       manifest.json
│   │       mstile-150x150.png
│   │       safari-pinned-tab.svg
│   │       
│   ├───fonts
│   │       fontawesome-webfont.eot
│   │       fontawesome-webfont.svg
│   │       fontawesome-webfont.ttf
│   │       fontawesome-webfont.woff
│   │       fontawesome-webfont.woff2
│   │       FontAwesome.otf
│   │       
│   └───img
│           desc.png
│           icon.png
│           logo-black.png
│           logo.png
│           top-background.png
│                   
├───scripts
│       deploy.js
│       
└───www # Web ページ自体
    │   CNAME
    │   
    ├───data # json データ
    │       news.json
    │       
    ├───favicon
    │       android-chrome-192x192.png
    │       ～
    │       safari-pinned-tab.svg
    │       
    ├───img # 画像
    │       desc.png
    │       icon.png
    │       logo.png
    │       top-background.png
    │       
    ├───pug # pug file
    │   │   index.pug
    │   │   
    │   └───include # custom pug file
    │           favicon.pug
    │           ogp.pug
    │           twitter_card.pug
    │           
    └───scss # scss folder
            common.scss
            second.scss
```

基本的には `www`内で書かれたコンテンツが変換されて `dest`にいくイメージです．基本的にインストールしたモジュールを利用して変換しているだけですが， scss や pug のビルドは少し工夫してあります．

#### pug のビルド

pug のビルドは通常のものとは違い，少し特殊な構成となっています．

```js
gulp.task('pug', () => {
    gulp.src(["www/pug/**/*.pug", "!www/pug/include/*.pug"], { base: "www/pug/" })
        .pipe(plumber({
            errorHandler: (err) => {
                console.log(err);
            }
        }))
        .pipe(data(
            (file) => {
                const dirname = __dirname + "/www/data/";
                const files = fs.readdirSync(dirname);
                let json = {};
                files.forEach((name) => {
                    json[name.replace(".json", "")] = JSON.parse(fs.readFileSync(dirname + name));
                });
                return { data: json };
            })
        )
        .pipe(pug({ pretty: true }))
        .pipe(gulp.dest("dest/"))
        .pipe(connect.reload());
})
```

何をやっているかというと pug 内で　json のデータを読めるようにしてあります．例えば index.json というファイルが `www/data` のディレクトリに入っていれば，pug内で

```jade
- const data = data.index
```

みたいにやってあげることで data の中に data.index の中身が参照できるようになっています．例えば

```json
{
  "title":"最高のWebページ",
  "description":"最高のWebページです",
  "author":"最高の作者"
}
```

```jade
- const data = data.index
html(lang="ja")
  head
    title=title
    meta(name='description',content=data.description)
    meta(name='author',content=data.author)
```

みたいなことができます．実際これが便利で，ニュースとかはこの方法で実現したほうが書きやすいかと思います．実現方法は自分の過去のブログを参照いただければ．

{{<embedly src="http://sh4869.hatenablog.com/entry/2016/08/30/033955" title="Pug(Jade)でgulpを使って複数のjsonファイルをいい感じに読み込みたい - Retired Colourman">}}

この記事では pug の文法に関する説明はしませんが， foreach 文等と組み合わせるととても便利になります．おすすめです．

#### Scss のビルド

Scssのビルドは特に言うことはないんですが，少し importer のことについてだけ．

```js
gulp.task("css", () => {
    return gulp.src("www/scss/index.scss", { "base": "www/scss" })
        .pipe(plumber({
            errorHandler: (err) => {
                console.log(err);
            }
        }))
        .pipe(sass({ outputStyle: 'expanded', importer: moduleImporter() }).on('error', sass.logError))
        .pipe(gulp.dest("dest/css/"))
        .pipe(connect.reload());
});
```

`moduleImporter` は package.json で css のモジュール側が `style` を定義しているときにそのファイルを import することができます．例えば normalize.css の package.json では [この](https://github.com/necolas/normalize.css/blob/master/package.json#L6)ように style が設定されていると sass-module-importer 側でそのパッケージ名を指定するだけで include できるようになっています．これがすごい便利．例えば，

```console
$ npm install --save normalize.css
```

としてから

```scss
@import "normalize.css"
```

としてあげるだけで normalize.css の中身が展開されるんですね．すごい！これはよくできた仕組みだと思います．公式じゃないっぽいけど……．

参考：

{{<embedly src="https://jaketrent.com/post/package-json-style-attribute/" title="Package.json style Attribute | Jake Trent">}}

## その他

大体システムについては説明したので，その他の細々としたシステムについて説明したいと思います．

### GitHub Pages

GitHub Pages にデプロイする時は npm パッケージの gh-pages を使うとよいかと思います．

{{<embedly src="https://github.com/tschaub/gh-pages" title="tschaub/gh-pages: General purpose task for publishing files to a gh-pages branch on GitHub">}}

これを使うとスクリプト的にdeployすることが可能になります．よい． Travis CI 等と組み合わせてもいいですね．

## 最後に

最後の方が若干雑になってしまいましたが，大体システムの説明ができたかと思います．一番いいことは **自分は最低限楽をできるし他人も吐き出されたものは読める**ということです．

これが何よりも大事で，もっと一般的に Web Application などを組んでしまうと誰もメンテナンスできなくて地獄を見るという可能性があります．それなら，最悪自分が吐き出した HTML と CSSを押し付けて上げれば動くようにしておいたほうが互いに幸せになれるよなということでこのようなシステムを組んでみました．参考になれば幸いです．「もうそれモダンじゃないよ」みたいなツッコミもお待ちしております．
