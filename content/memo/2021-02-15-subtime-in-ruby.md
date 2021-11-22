---
title: 時間の差分を取る
date: 2021-02-15
---

```ruby
def subTime(a,b)
  require 'time'
  ((Time.parse(a) - Time.parse(b))/60).abs
end
```

irbとかで起動させること前提なのでそこは注意を。「20:49:36.441」みたいな形式のものをパースできる。
