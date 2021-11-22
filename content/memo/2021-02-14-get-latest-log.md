---
title: 最新のlogファイルを取りたい 
date: 2021-02-14
---

`log_YYYYMMDD_HHmmss.log`というログファイルがたくさんあるときに最新のファイルをlessしたい。

```
less (ls -tr1 log_*.log | tail -n 1)
```