---
date: "2017-12-09T17:11:05+09:00"
slug: "post"
tags: ["STM32"]
categories: ["tech"]
title: "STMFlashLoader をコマンドラインから使う"
---

<script async src="//cdn.embedly.com/widgets/platform.js"></script>

STM32には様々な書き込み方法がありますが，その一つに公式から提供されているSTMFlashLoader（以下Flash Loader）を使って書き込むというものがあります．

* [FLASHER\-STM32 \- STM32 Flash loader demonstrator \(UM0462\) \- STMicroelectronics](https://my.st.com/content/my_st_com/en/products/development-tools/software-development-tools/stm32-software-development-tools/stm32-programmers/flasher-stm32.license%3d1512066019528.product%3dFLASHER-STM32.html)
{{<embedly src="https://my.st.com/content/my_st_com/en/products/development-tools/software-development-tools/stm32-software-development-tools/stm32-programmers/flasher-stm32.license%3d1512066019528.product%3dFLASHER-STM32.html" title="FLASHER-STM32 - STM32 Flash loader demonstrator (UM0462) - STMicroelectronics">}}

比較的古い型番のSTM32を利用する場合はこちらを使うことが多いかと思います．このFlashLoaderですが，実はインストールするとコマンドラインインターフェースも同時についてくるので，CLIとして使うことが可能です．今回はそのやり方を^[後輩に書くといってしまったので]かんたんにまとめて見ます．

## STMFlashLodaerの準備

インストーラーの指示に従ってインストールすると`C:\Program Files (x86)\STMicroelectronics\Software\Flash Loader Demo`にFlash Lodaerがインストールされているはずなので，そこにPATHを通します．もしインストール場所を変更した場合はそこにPATHを通すようにしてください．PATHの通し方はググってください．私は[Rapid Enviroiment Editor](https://www.rapidee.com/ja/about)を使うことを強くおすすめします．

PATHが通せたら，コマンドプロンプト等で`STMFlashLodaer`とタイプし実行してみてください．正しくPATHが通っていれば以下のような画面が出るかと思います．

```bash
> STMFlashLoader
STMicroelectronics UART Flash Loader command line v2.7.0

 Usage :

 STMFlashLoader.exe [options] [Agrument][[options] [Agrument]...]

  -?                   (Show this help)
  -c                   (Establish connection to the COM port)
     --pn  port_nb     : e.g: 1, 2 ..., default 1
     --br  baud_rate   : e.g: 115200, 57600 ..., default 57600
     --db  data_bits   : value in {5,6,7,8} ..., default 8
     --pr  parity      : value in {NONE,ODD,EVEN} ..., default EVEN
     --sb  stop_bits   : value in {1,1.5,2} ..., default 1
     --ec  echo        : value OFF or ECHO or LISTEN ..., default is OFF
     --co  control     : Enable or Disable RTS and DTR outputs control
                       : value OFF or ON ..., default is OFF
     --to  time_out    : (ms) e.g 1000, 2000, 3000 ..., default 5000
  -Rts                 (set Rts line to Hi, Lo)
     --State           : State in {Hi, Lo}
  -Dtr                 (Set Rts line to Hi, Lo)
     --State           : State in {Hi, Lo}
  -i  device_name      (e.g STM32_Low-density_16K, [See the Map directory])
  -e                   (erase flash pages
     --all all pages   : erase all pages
     --sec number_of_pages_group pages_group_codes : erase specified group pages
  -u                   (Upload flash contents to a .bin, .hex or .s19 file )
     --fn  file_name   : full path name of the file
  -d                   (Download the content of a file into MCU flash)
     --a   address(hex): start @ in hex ; ignored if it is not a binary file
     --fn  file_name   : full path name (.bin, .hex or .s19 file)
     --v               : verify after download
     --o               : optimize; removes FFs data
  -r                   (Run the flash code at the specified address
     --a address(hex)  : address in hexadecimal)
  -p        (Enable or Disable protections)
     --ewp  : enable write protection for sector codes (e.g 1,2,etc.)
     --dwp  : disable write protection
     --drp  : disable read protection
     --erp  : enable read protection, all arguments following this one will fail
  -o              (Get or Set STM32F1x option bytes: use -d command for others!)
     --get --fn file_name : get option bytes from the device
                            and write it in the specified file
     --set --fn file_name : load option bytes from the specified file
                            and write it to the device
     --set --vals --OPB hex_val : set the specified option byte; OPB in: User,
                                  RDP, Data0, Data1, WRP0, WRP1, WRP2, WRP3
```

いい感じですね．これでセットアップは完了です．

## 使い方

PATHが通って使えるようになったら次は実際に使ってみましょう．実際に使うためにはGUIでやっていたオプションをすべてコマンドラインで指定してあげないといけないわけですが，これが意外と厄介です．頑張っていきましょう．

STMFlashLoader のコマンドラインオプションは多いのでちょっと普通とは違う指定の仕方をすることになります．簡単に言ってしまえば，どの領域の設定をするかを指定して，その中で複数の設定を行うという感じになっています．何を言っているのかイマイチわからないと思うので，とりあえずやっていきましょう．

### COM PORT

COM PORTの設定は `-c` で指定します． `-c` オプションの中で更に細かく設定をしていくイメージです．例えば書き込みのポートが9番だったとしましょう^[実際の書き込みポートはマシンそれぞれで違うので，各自確認するようにしてください．デバイスマネージャーで確認できるはずです]．その場合`--pn` オプションで指定します．次のように指定します．

```bash
STMFLashLodaer -c --pn 9
```

また，ボーレートを設定するときは `--br` オプションを使います． 

```bash
STMFLashLodaer -c --pn 9 --br 115200
```

ここで注意してほしいのは， **-c オプションのあと以外で --pnオプションや--brオプションを使っても動作しない**ということです．要は「COMPORTのPORT NUMBERを指定する」というふうにしないといけません．ここを勘違いさえしなければあとは簡単です．

他の項目も設定したい場合は Help を確認してください．基本はデフォルトのままで大丈夫のはず．

### Device Name

Flash LoaderをGUIで使っているときには Flash Loaderが勝手にどんなデバイスなのかを検出してくれたので何も考えなくてよかったのですが，CUIで使う場合は自分で設定する必要があります．これは `-i` オプションで行います．たとえば F1 シリーズのマイコンで512kbのものを利用している場合は`STM32F1_High-density_512K`等を使うことになりますが，この辺は正直一度GUIで起動して確認してから指定するほうが良いかと思います．

ポートとボーレート，デイバス名を設定すると次のようになります．

```bash
STMFLashLodaer -c --pn 9 --br 115200 -i STM32F1_High-density_512K
```

### erase

書き込む前にすべてのFlashのデータを消したい場合は `-e`オプションを選択します．すべて消す場合は `-e --all`を選択します．

今までのオプションをあわせると次のようになります．

```bash
STMFLashLodaer -c --pn 9 --br 115200 -i STM32F1_High-density_512K -e --all
```

### ファイルの書き込み

ファイルを書き込みたい場合は `-d` (download)オプションを指定します^[余談ですがDownloadとUploadが直感と逆なので気をつけてください．Flash Lodaerではマイコンにファイルの内容を**ダウンロード**し，マイコンの内容をPCに**アップロード**します．マイコンが主体となっているわけですね．]．書き込むファイルの種類は複数から選ぶことができますが，とりあえず私は`.hex`にしています．

.hex ファイルを書き込む場合は どのアドレスから書き込むかを指定する必要があります．おそらく 8000000 から書き込むことが多いので，その場合は `--a 8000000` といった風に指定するとよいでしょう．ファイル名は `--fn`で指定します．

今までのオプションに， `file.hex` という名前のファイルを書き込む場合は以下のようになります．

```bash
STMFLashLodaer -c --pn 9 --br 115200 -i STM32F1_High-density_512K -e --all -d --a 8000000 --fn "file.hex"
```

これで一通りの設定が終了しました．他にも `protection` の設定等があるので適宜使ってください．ちなみに `-u` オプションを使うとマイコンに現在書き込まれている設定を読み出すことが可能です．

## 書き込みスクリプトの生成

さて，ここまでのことを応用して，Windows でいい感じに書き込みを自動化したいと思います．多分CUIでSTM32のプロジェクトをビルドしているということはMakefileを使っているでしょうから^[そうじゃない場合は自分でがんばってください]今回はSTM32Cubeから吐き出されたMakefileをカスタマイズしてみる例をあげてみます．

```Makefile
deploy: all
	cd build && STMFlashLoader.exe -c --pn 4 --br 115200 --pr EVEN -i STM32F1_High-density_512K -e --all -d --a 8000000 --fn "project.hex" && cd ..
```

はい．上のような感じでやるといいんじゃないでしょうか．`project.hex`や 各オプションは適宜自分のプロジェクトに読み替えてください．これで `make deploy` で書き込みができますね．あの Flash Loader 特有のダレる感じに付き合わなくてすみます．やったね．

ちなみに当たり前ですがFlash LoaderがGUIで返すエラーは当然CLI上でも表示されます．例えばこれはポートに何もつながっていないときのエラーメッセージです^[CUI版の場合は成功した場合OK，失敗した場合 KO と返ってきます．ちょっと面白いですね．]．

```
Opening Port                             [KO]
Cannot open the com port, the port may
 be used by another application
```

もちろん英語が読めれば問題ないですが，もしかしたらある程度GUIで使って意味を理解してからCUIで自動化したほうがいいかと思います．というかFlash Loader以外で書き込めるならそのほうが良さそう．正直何がベストプラクティスなのか全くわかっていないので教えて頂きたいです……．

## 余談

Flash Loaderで書き込んでると死ぬほど書き込みに時間がかかるので^[Flash Loader以外で書き込んだことがないのでこれがFlash Loader特有なのかはわかりませんが]書き込みを自動化すると書き込んでることを忘れます．俺は書き込み画面から目を逸らさないという強い意志をお持ちの方はそのまま強い意志をお持ちいただけるとうれしいですが，私としては最後に音楽等を流すことをおすすめします．

```
(前述のコマンド) && rundll32.exe user32.dll,MessageBeep && sleep 0.5 && rundll32.exe user32.dll,MessageBeep && sleep 0.5 && rundll32.exe user32.dll,MessageBeep
```

このようにやると三回ほど効果音がなるので安心して暇つぶしができますね．

## 参考

- [6\.2\.4\.4\. makefileの修正 (マイコン徹底入門)](http://miqn.net/introduction/139.html)