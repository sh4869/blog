---
date: 2020-07-15T14:21:12+09:00
slug: "post"
tags: ["git", "ci"]
title: "Travis CIからGitHub Actionsへの移行"
categories: ["tech"]
comments: true
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

今までブログや日記等に travis-ci を使っていたところを、GitHub Actions に移行した。移行作業自体そこまで大変ではなかったけど、こういうのはメモしておかないと文法や作法を忘れてしまうので備忘録的に書いておく。

# diary

## プロジェクト概要

- レポジトリ: [sh4869/diary: My Diary System written by Rust](https://github.com/sh4869/diary)
- 構成
  - ビルドツール: Rust
  - デプロイ先: Firebase

手元でもざっとビルドできるように、`cargo run`してから`firebase deploy`するとデプロイされるようになっている。デプロイ先は[diary.sh4869.net](https://diary.sh4869.net)。

## Before: Travis CI ファイル

```yml
dist: trusty
language: rust
rust:
  - nightly
before_install:
  - nvm install node
  - nvm use node
  - npm install -g firebase-tools
after_success: export RUST_BACKTRACE=1 && cargo run && firebase --token $FIREBASE_TOKEN
  --project sh4869-diary deploy
notifications:
  slack:
    secure: (省略)
```

firebase は firebase-tools を使ってデプロイするようになっているので、Rust 環境に nvm を使って（これは Travis CI の Linux 環境）node をインストールしてから npm install で firebase tools をインストールしている。

## After: GitHub Actions

```yml
name: Build and Deploy

on:
  push:
    branches: [master]

env:
  CARGO_TERM_COLOR: always

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Install latest nightly
        uses: actions-rs/toolchain@v1
        with:
          toolchain: nightly
          override: true
      - uses: actions/checkout@v2
      - name: Run cargo check
        uses: actions-rs/cargo@v1
        with:
          command: run
      - name: GitHub Action for Firebase
        uses: w9jds/firebase-action@v1.5.0
        with:
          args: deploy --token $FIREBASE_TOKEN --only hosting --project sh4869-diary
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
      - name: Slack Notification
        if: success()
        uses: tokorom/action-slack-incoming-webhook@master
        env:
          INCOMING_WEBHOOK_URL: ${{ secrets.SLACK_INCOMING_HOOKS }}
        with:
          text: deploy diaries.
          attachments: |
            [
              {
                "color": "good",
                "author_name": "${{ github.actor }}",
                "author_icon": "${{ github.event.sender.avatar_url }}",
                "fields": [
                  {
                    "title": "Commit Message",
                    "value": "${{ github.event.head_commit.message }}"
                  }
                ]
              }
            ]
```

上の Actions ファイルでは、以下のような順番でビルドを行っている。

- rust nightly インストール
- git repository checkout
- cargo run
- firebase deploy
- slack notification

### git repository install

<a href="https://github.com/features/actions" class="embedly-card">Features • GitHub Actions</a>

ソースコードをチェックアウトするだけ。

```yml
- uses: actions/checkout@v2
```

### rust nightly インストール(& cargo run)

<p><a href="https://github.com/marketplace/actions/rust-toolchain" class="embedly-card">rust-toolchain · Actions · GitHub Marketplace</a></p>

rust-toolchain を使うと、Rust の nightly 等を選択してインストールすることができる。ここでインストールした Cargo を使いたいので、`override`に`true`を指定している。

```yml
- name: Install latest nightly
      uses: actions-rs/toolchain@v1
      with:
          toolchain: nightly
          override: true
- name: Run cargo check
    uses: actions-rs/cargo@v1
    with:
    command: run
```

### firebase deploy

<a href="https://github.com/w9jds/firebase-action" class="embedly-card">w9jds/firebase-action: GitHub Action for interacting with Firebase</a>

Firebase deploy は firebase-action を使う。deploy するときに KEY が必要なので、`firebase login:ci`で発行したキーを secrets に追加する。secrets は Repository Setting から追加できる。

```yml
- name: GitHub Action for Firebase
  uses: w9jds/firebase-action@v1.5.0
  with:
    args: deploy --token $FIREBASE_TOKEN --only hosting --project sh4869-diary
  env:
    FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

### slack への通知

<a href="https://spinners.work/posts/github-actions-context/" class="embedly-card">Github Actions から Slack へ通知するのを良い感じにしたい | Spinners Inc.</a>

いくつか候補があったけれど、上の記事のが良さげだったので使わせてもらった。GitHub Actionsn の明確な利点は他人が作った Actions を使えることである。

```yml
- name: Slack Notification
  if: success()
  uses: tokorom/action-slack-incoming-webhook@master
  env:
    INCOMING_WEBHOOK_URL: ${{ secrets.SLACK_INCOMING_HOOKS }}
  with:
    text: deploy diaries.
    attachments: |
      [
        {
          "color": "good",
          "author_name": "${{ github.actor }}",
          "author_icon": "${{ github.event.sender.avatar_url }}",
          "fields": [
            {
              "title": "Commit Message",
              "value": "${{ github.event.head_commit.message }}"
            }
          ]
        }
      ]
```

成功時だけ飛ばしているのは失敗時にはメールが来るようになっているので。

## TODO

- diary を別ブランチにする

# 感想

Travis CI のように環境に対して記述していく感じではないので、若干戸惑いがあるが、他人が作った Actions を使えたりするのは便利。本当は build と deploy は別にしたいのだけど、ディレクトリごとキャッシュする方法がよくわからなかったのでまとめてしまった。あと yaml がつらい。 他のやつも順次乗り換えて行きたい。
