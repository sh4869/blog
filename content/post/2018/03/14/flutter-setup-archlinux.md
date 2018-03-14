---
date: "2018-03-14T12:11:05+09:00"
slug: "post"
tags: ["tech", "ArchLinux","Flutter","Dartlang"]
title: "ArchLinuxでFlutterをインストールするときのメモ"
categories: ["tech"]
comments: true
---

ArchLinuxでFlutterをセットアップするときのメモです。特に躓くことはないのですが、一部別にパッケージをインストールする必要があるのでメモしておきます。

[Get Started: Install on Linux \- Flutter](https://flutter.io/setup-linux/)に書いてある通り、まずプログラムをGit cloneします。

```sh
git clone -b beta https://github.com/flutter/flutter.git
export PATH=`pwd`/flutter/bin:$PATH
```

PATHを通した状態でFlutterコマンドを実行すると、実行環境諸々勝手にインストールしてきてくれます。便利!!

```sh
flutter
```

そのあとに、`flutter doctor`を実行すると、[このissue](https://github.com/flutter/flutter/issues/6207)を見て修正しろと言われるので、その指示に従ってlib32-libstdc++5をインストールします。

```
pacman -S lib32-libstdc++5
```

これでAndroid Studio等の設定をすれば問題ないはずです。