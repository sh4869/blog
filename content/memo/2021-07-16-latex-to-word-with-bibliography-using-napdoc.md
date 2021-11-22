---
title: Pandocを使ってLaTeXのファイルを参考文献つきでWordファイルに変換する
date: 2021-07-16
---

```
pandoc -s source.tex --citeproc --bibliography=test.bib -o source.docx
```

`citeproc` を用意しておかないと失敗するので注意

参考: [Pandoc User’s Guide 日本語版 — 日本Pandocユーザ会](https://pandoc-doc-ja.readthedocs.io/ja/latest/users-guide.html#citation-rendering)