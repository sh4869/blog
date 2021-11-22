---
title: sbtのリリース方法
date: 2021-02-13
---

gpgとかは除いて簡単に説明する。

```
+ compile
+ publishSigned
sonatypeReleaseAll
```

で、[ここ](https://oss.sonatype.org/index.html#welcome)にアクセスして自分がさっき公開したやつを探してリリースを押す。