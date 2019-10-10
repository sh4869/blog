---
date: 2019-10-10T16:22:45+09:00
slug: "post"
tags: ["memo"]
title: "VScodeのLaTeX Workshopの設定について"
categories: ["tech"]
comments: true
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

VSCode で LaTeX Workshop を使うたびに混乱したくないのでまとめておく．

# LaTeX Workshop

<a href="https://github.com/James-Yu/LaTeX-Workshop" class="embedly-card">James-Yu/LaTeX-Workshop: Boost LaTeX typesetting efficiency with preview, compile, autocomplete, colorize, and more.</a>

これ．VSCode 上で適当に LaTeX を使うには十分なんだけど十分すぎて設定の概念を忘れてしまう．

## Autobuild

LaTeX Workshop はデフォルトで[Autobuild が有効](https://github.com/James-Yu/LaTeX-Workshop/wiki/Compile#auto-build-latex)．もしこれが気に食わないなら never にすればよいが，監視のプロセスは常に立ち続けているので VSCode 使うなら有効にして委ねてしまうほうが良い．

## recipes と tools

LaTeX Workshop でコンパイルの設定をかえるときに主に「tools」と「recipes」をいじることになる．

### recipes

どのようにビルドするかのレシピ．

```json
[
  {
    "name": "latexmk 🔃",
    "tools": ["latexmk"]
  },
  {
    "name": "pdflatex ➞ bibtex ➞ pdflatex`×2",
    "tools": ["pdflatex", "bibtex", "pdflatex", "pdflatex"]
  }
]
```

ここで呼ばれている tools は，記述された順番に呼ばれる．そのため，latexmk と一つだけ書かれたものは，latexmk が一度呼ばれる．`pdflatex ➞ bibtex ➞ pdflatex ×2`のものは，pdflatex -> bibtex -> pdflatex -> pdflatex の順番で呼ばれる．

ここで注意したいのが，ここで呼ばれるのは `latexmk` コマンドでは**ない**ということ．ここで呼ばれるのは，`tools`で定義したもの．

### tools

上の recipes の中で呼ばれるのは tools の設定．

```json
[
  {
    "name": "latexmk",
    "command": "latexmk",
    "args": [
      "-synctex=1",
      "-interaction=nonstopmode",
      "-file-line-error",
      "-pdf",
      "-outdir=%OUTDIR%",
      "%DOC%"
    ],
    "env": {}
  },
  {
    "name": "pdflatex",
    "command": "pdflatex",
    "args": [
      "-synctex=1",
      "-interaction=nonstopmode",
      "-file-line-error",
      "%DOC%"
    ],
    "env": {}
  },
  {
    "name": "bibtex",
    "command": "bibtex",
    "args": ["%DOCFILE%"],
    "env": {}
  }
]
```

なので，`latexmk 🔃`で呼ばれるのは latexmk のコマンドではなく，tools で定義されている`latexmk`である^[具体的には `latexmk -synctex=1 -interaction=nonstopmode -file-line-error -pdf -outdir=%OUTDIR% %DOC%`というコマンドが呼ばれている．]．ここさえわかればあとは対して問題ではない．

## 自分の設定

### `.latexmkrc`

```perl
$latex = 'platex -synctex=1 %O %S';
$bibtex = 'pbibtex %O %B';
$dvipdf = 'dvipdfmx %O -o %D %S';
$makeindex = 'mendex %O -o %D %S';
$max_repeat = 10;
$pdf_previewer = '"C:\Program Files\SumatraPDF\SumatraPDF.exe" -reuse-instance %O %S';
```

### vscode の `setting.json`

```json
{
  "latex-workshop.latex.autoBuild.run": "onFileChange",
  "latex-workshop.latex.recipes": [
    {
      "name": "latexmk 🔃",
      "tools": ["latexmk"]
    },
    {
      "name": "latexmk (latexmkrc)",
      "tools": ["latexmk_rconly"]
    },
    {
      "name": "latexmk (lualatex)",
      "tools": ["lualatexmk"]
    },
    {
      "name": "pdflatex ➞ bibtex ➞ pdflatex × 2",
      "tools": ["pdflatex", "bibtex", "pdflatex", "pdflatex"]
    }
  ],
  "latex-workshop.latex.tools": [
    {
      "name": "latexmk",
      "command": "latexmk",
      "args": [
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "-pdfdvi",
        "%DOC%"
      ]
    }
  ]
}
```

ちなみにデフォルトのレシピとしては一番上に設定したものが呼ばれるので，どんな状態だろうと tex ファイルを保存した瞬間に一番上のレシピである `latexmk 🔃` が呼ばれる．ここの latexmk はちゃんと`.latexmkrc`の設定を読み込んでくれるので日本語でも問題ないというわけ．

# 参考

- [Visual Studio Code/LaTeX \- TeX Wiki](https://texwiki.texjp.org/?Visual%20Studio%20Code%2FLaTeX#c465cb18)
- [Latexmk \- TeX Wiki](https://texwiki.texjp.org/?Latexmk)
- [Compile · James\-Yu/LaTeX\-Workshop Wiki](https://github.com/James-Yu/LaTeX-Workshop/wiki/Compile)
