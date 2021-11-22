---
title: "@aws-cdk/aws-lambda-nodejs は emitDecoratorMetadata が使えない"
date: 2021-09-07
comments: true
slug: "post"
categories: ["tech"]
tags: ["aws cdk"]
---


[@aws\-cdk/aws\-lambda\-nodejs](https://docs.aws.amazon.com/cdk/api/latest/docs/aws-lambda-nodejs-readme.html)というCDKのモジュールがあり、Node.js関連（TypeScriptでもOK）のLambda関数を作るときに便利。

```typescript
new lambda.NodejsFunction(this, 'MyFunction', {
  entry: '/path/to/my/file.ts', // accepts .js, .jsx, .ts and .tsx files
  handler: 'myExportedFunc', // defaults to 'handler'
});
```

以上のような感じで作れるので大変楽なんだけど、内部でesbuildでビルドしている関係でちょっと制限がある。esbuildはemitDecoratorをサポートしてない。対応させるためのpluginは一応[@anatine/esbuild\-decorators \- npm](https://www.npmjs.com/package/@anatine/esbuild-decorators)というのがあって、これを使えば対応できるのだけど、aws-lambda-nodejsはプラグインが呼び出せる形式になっていない。

なので、`emitDecoratorMetadata`が必要なTypeScriptのプログラムはaws-lambda-nodejsでは動かせない。自力でlayerを設定するしかない。

[AWS CDKのbundlingオプションを使ってLambdaへのデプロイ前処理もCDKで管理する方法 \| DevelopersIO](https://dev.classmethod.jp/articles/lambda-bundling-via-aws-cdk/#toc-6)

この記事の「その他のランタイムの場合」のところにnodejsのlayerを自分で作成する方法があるので、そちらを参考にするとよいと思います。

- [feat\(lambda\-nodejs\) experimental decorators support by whimzyLive · Pull Request \#15631 · aws/aws\-cdk](https://github.com/aws/aws-cdk/pull/15631)

あとはこちらのプルリクの進捗をwatchしておくとよさそう。
