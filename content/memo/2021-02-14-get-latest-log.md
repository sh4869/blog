---
title: 日時がファイル名になっているときに最新のファイルを取りたい 
date: 2021-02-14
---

`log_YYYYMMDD_HHmmss.log`というログファイルがたくさんあるときに最新のファイルをlessしたい場合は

```
less (ls -tr1 log_*.log | tail -n 1)
```

でOK。