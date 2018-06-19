---
date: "2018-06-14T11:32:26+09:00"
slug: "post"
tags: ["Rust"]
title: "Rustでの日記生成ツール"
categories: ["tech"]
comments: true
---


<script async src="//cdn.embedly.com/widgets/platform.js"></script>

自分の日記[Daily Bread](https://diary.sh4869.net)^[ちなみにタイトルはアニメノワール二話「日々の糧」から]のビルドシステムはRustで作ってあって、これのシステムの（といってもそんな複雑なものではないが）の解説をしようと思う。

{{<embedly src="https://github.com/sh4869/diary" title="sh4869/diary: My Dialy System written by Rust">}}

# 全体の構成

このRustのプログラムでは次のような流れで日記をビルドをしている。

1. 日記ファイルの検索
2. ファイルそれぞれのビルド
3. トップページのビルド

## 日記ファイルの検索

ファイルに日付情報を保存させておくのは使用ライブラリ上面倒だったので、ファイルの位置で日記の日付を判定するようにした^[メタ情報に日時を書いてもいいのだけど、Rust上にあるMarkdownパーサーはメタデータが読めるやつがなくて、わざわざやる必要もないかなと思ったのもある。時間があればパーサーを拡張してあげたい。]。

```shell
2018/
  06/
    01.md # 2018/06/01の日記
    02.md
    ...
```

これをglobライブラリを使ってまとめて取得する。

{{<embedly src="https://github.com/rust-lang-nursery/glob" title="rust-lang-nursery/glob: Support for matching file paths against Unix shell style patterns.">}}

```rust
let mut paths: Vec<PathBuf> = Vec::new();
for entry in glob::glob("diary/**/*.md").map_err(|err| Error::new(ErrorKind::InvalidData, err))? {
    match entry {
        Ok(path) => paths.push(path),
        Err(e) => println!("{}", e.to_string()),
    }
}
```

## それぞれの日記のビルド

で、追加されたpathsに対して、そのpathを渡してビルドを行う関数がbuild_dailyになる。

```rust
struct Daily {
    day: Date<Local>,
    title: String,
    content: String,
}

// 中略

fn build_daily(path: &Path) -> io::Result<Daily> {
    let mut file = File::open(path)?;
    let date;
    match get_date(&path.to_str().unwrap().into()) {
        Ok(d) => date = d,
        Err(e) => {
            println!("{}", e.to_string());
            return Err(Error::new(ErrorKind::InvalidData, e.to_string()));
        }
    }
    let mut daily = Daily {
        content: "".into(),
        title: "".into(),
        day: date,
    };

    let mut content = String::new();
    file.read_to_string(&mut content)?;
    // タイトルの取得
    match get_title(&mut content) {
        Ok(s) => daily.title = s,
        Err(e) => println!("Error: {}", e.to_string()),
    }

    let md = content.splitn(3, "---").collect::<Vec<&str>>()[2];
    match convert_markdown(&md) {
        Ok(md) => daily.content = md,
        Err(e) => println!("Error: {}", e.to_string()),
    }
    match write_day_file(&daily) {
        Ok(()) => {}
        Err(e) => println!("Error: {}", e.to_string()),
    }
    println!(">>>>> Build {}", daily.day.format("%Y/%m/%d"));
    Ok(daily)
}
```

まずファイル名から日時を取得する。

```rust
fn get_date(filepath: &String) -> io::Result<Date<Local>> {
    let dailystr = filepath.clone().replace(".md", "").replace("diary/", "");
    let dailyv: Vec<&str> = dailystr.split(MAIN_SEPARATOR).collect();
    let y = try!(dailyv[0].parse::<i32>().map_err(|err| Error::new(ErrorKind::InvalidData, err)));
    let m = try!(dailyv[1].parse::<u32>().map_err(|err| Error::new(ErrorKind::InvalidData, err)));
    let d = try!(dailyv[2].parse::<u32>().map_err(|err| Error::new(ErrorKind::InvalidData, err)));
    let date = Local.ymd(y, m, d);
    Ok(date)
}
```

絶対もっと賢い方法あるやろと思うんだけど、まあ雑にやった。[MAIN_SEPARATOR](https://doc.rust-lang.org/std/path/constant.MAIN_SEPARATOR.html)使ってsplitしておけばいい。

とりあえず一つ一つparseして、エラーを拾っている。どれもエラーが起きなかったら、そのまま日時を設定して、返すようにしている。で、無事日時が取得できたら、それをもとにDaily構造体を作っていく。

```markdown
---
title: これがタイトル
---
```

となっているのを、次の関数でtitleにする。

```rust
fn get_title(md: &String) -> io::Result<String> {
    let v: Vec<&str> = md.split("---").collect();
    Ok((v[1].split("title:").collect::<Vec<&str>>())[1].trim().into())
}
```

本当はMarkdownのパーサー側に組み込みたいのだけど、僕が使っているpulldown-cmarkはCommonMarkにしか対応していないので厳しかった。もちろんパーサーの拡張も可能なのだけど構文拡張ではないので普通にsplitしてしまうのが一番簡単だったのでこの方法を選んだ。

titleが取得できたら、次は中身のmarkdownをパースしていく。Markdownのビルドには上述した通り、pulldown-cmarkというライブラリを使っている。

{{<embedly src="https://github.com/google/pulldown-cmark" title="google/pulldown-cmark">}}

```rust
fn convert_markdown(md: &str) -> io::Result<String> {
    let parser = Parser::new_ext(&md, Options::all());
    let mut html_buf = String::new();
    html::push_html(&mut html_buf, parser);
    Ok(html_buf)
}
```

```rust
fn write_day_file(daily: &Daily) -> io::Result<()> {
    let destpath = "docs/".to_string() + &daily.day.format("%Y/%m/%d").to_string() + &".html";
    let parent = Path::new(&destpath).parent().unwrap();
    if parent.exists() == false {
        fs::create_dir_all(parent.to_str().unwrap())?;
    }
    let mut file = File::create(&destpath)?;
    file.write_all(daily.generate_html().as_bytes())?;
    Ok(())
}
```

Dailyには`generate_html`という関数を生やしてある。これはDailyからHTMLを吐き出すためのもので、maudというライブラリを使っている。

{{<embedly src="https://github.com/lfairy/maud" title="lfairy/maud: Compile-time HTML templates for Rust">}}

maudはコンパイル時テンプレートエンジンで、macroとして実装されている。

```rust
html! {
    h1 "Hello, world!"
    p.intro {
        "This is an example of the "
        a href="https://github.com/lfairy/maud" "Maud"
        " template language."
    }
}
```

のように書くと、これがマクロとしてコンパイルされるようになっている。Nightly Compilerが必要だけど、他のテンプレートエンジンに比べて遊びがあって面白かったので採用した。

```rust
impl Daily {
    fn generate_html(&self) -> String {
        let higlightjs = r##"
<script src="//cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/highlight.min.js"></script>
<script>hljs.initHighlightingOnLoad();</script>"##;
        let csslist = [
            "https://cdnjs.cloudflare.com/ajax/libs/normalize/7.0.0/normalize.css",
            "/static/css/layers.min.css",
            "/static/css/layers.section.min.css",
            "/static/css/index.css",
            "https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.12.0/styles/hopscotch.min.css",
        ];
        let disqus = r##"
<div id="disqus_thread"></div>
<script>

(function() { // DON'T EDIT BELOW THIS LINE
var d = document, s = d.createElement('script');
s.src = 'https://diary-sh4869-net.disqus.com/embed.js';
s.setAttribute('data-timestamp', +new Date());
(d.head || d.body).appendChild(s);
})();
</script>
<noscript>Please enable JavaScript to view the <a href="https://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
                            "##;
        let title = self.day.format("%Y/%m/%d").to_string() + &" - " + &self.title;
        let markup = html! {
            html {
                head {
                    meta chaset="utf-8";
                    meta name="viewport" content="width=device-width, initial-scale=1";
                    @for url in &csslist {
                        link rel="stylesheet" href=(url);
                    }
                    (PreEscaped(higlightjs))
                    title (title)
                }
                body{
                    div.row {
                        div.row-content.buffer {
                            div.column.twelve.top#header {
                                a href=("/") {
                                    h1.title "Daily Bread"
                                }
                            }
                            div.clear {

                            }
                            div.info {
                                time (self.day.format("%Y/%m/%d"));
                                h1 (self.title);
                            }
                            div.daily {
                                (PreEscaped(&self.content))
                                div.signature {
                                    p ("Written by sh4869");
                                }
                                (PreEscaped(disqus))
                            }
                            footer {
                                hr;
                                a href=("/") "Daily Bread"
                                p (PreEscaped("&copy; 2017 <a href=\"http://sh4869.net\">sh4869</a>") )
                            }
                        }
                    }
                }
            }
        };
        return markup.into_string();
    }
}
```

## トップページのビルド

トップページのビルドは簡単で、DailyのVectorを受け取ってそれをぐるぐる回しているだけ。

```rust
fn build_top_page(dailies: &mut Vec<Daily>) -> io::Result<()> {
    dailies.sort_by(|a, b| b.day.cmp(&a.day));
    let css = r##"
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/normalize/7.0.0/normalize.css" />
    <link rel="stylesheet" href="static/css/layers.section.min.css" />
    <link rel="stylesheet" href="static/css/layers.min.css" />
    <link rel="stylesheet" href="static/css/index.css"/>
    "##;
    let markup = html! {
        head {
            meta chaset="utf-8";
            meta name="viewport" content="width=device-width, initial-scale=1";
            (PreEscaped(css))
            title "Daily Bread"
        }
        body {
            div.row {
                div.row-content.buffer {
                    div.column.twelve.top#header {
                        a href=("/") {
                            h1.title "Daily Bread"
                        }
                    }
                    div.clear {

                    }
                    @for (i,daily) in dailies.iter().enumerate() {
                        @let link = daily.day.format("%Y/%m/%d").to_string() + ".html";
                        @if i % 2 == 0 {
                            div.column.small-full.medium-half.large-half {
                                div.day {
                                    time (daily.day.format("%Y/%m/%d"));
                                    a href=(link) {
                                        h2 (daily.title)
                                    }
                                }
                            }
                        } @else {
                            div.column.small-full.medium-half.medium-last {
                                div.day {
                                    time (daily.day.format("%Y/%m/%d"));
                                    a href=(link) {
                                        h2 (daily.title)
                                    }
                                }
                            }
                        }
                    }
                    footer {
                        a href=("/") "Daily Bread"
                        p (PreEscaped("&copy; 2017 <a href=\"http://sh4869.net\">sh4869</a>") )
                    }
                }
            }
        }
    };
    let mut file = File::create("docs/index.html")?;
    file.write_all(markup.into_string().as_bytes())?;
    Ok(())
}
```

# firebase

デプロイ先はfirebaseにしあって、理由は

* hostingだけなら無料
* HTTPS対応してる
* 簡単

と言った感じ。Travis CIでpushするとビルドしてdeployしてくれるようになっている。

```json
{
  "hosting": {
    "public":"docs"
  }
}
```

```yaml
dist: trusty
language: rust
rust:
  - nightly
before_install:
  - nvm install node
  - nvm use node
  - npm install -g firebase-tools
after_success: export RUST_BACKTRACE=1 && cargo run && firebase --token $FIREBASE_TOKEN --project sh4869-diary deploy
```

RustはCI周りちゃんとしているプロジェクトが多かったので、それを見るだけでわかったのでよかった。

# TODO

* テストを書く
* ちゃんとモジュールで分ける
* 諸々へのリンクを貼る(Last.fm、Twilog等)