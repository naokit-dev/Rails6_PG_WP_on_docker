# 何ができるか

ターミナルのコマンド一つで、Docker 上の Rails ローカル開発環境が構築できます

```
source setup.sh
```

# 環境

## 目標環境(Docker 上)

- Ruby 2.7.1
- Rails 6.0.3
- PostgreSQL 11.0
- Webpack (Hot-reload 対応, JS, CSS コンパイル対応化)

## 動作確認環境

- Mac OS Mojave 10.14.6
- Docker 2.3.0.4

# なぜやるか

結論から言うと

**よくわからないまま必要のないところで消耗するよりも、
既存の効率化された物を利用して本来解決すべき問題に取り組んでほしいから**

新しい学習方法の開拓のために
"teratail で 2 日間ひたすら質問に応える試み"を経て得た気づきをもとにしています

- Rails チュートリアルの影響か、Rails6 でポートフォリオ作成に取り組み、Webpack の役割を理解せず、以前の Sprocket を利用するケースとの混同が多く見られる。
- Rails6 環境にて Webpack 管理下に Bootstrap を正しくインストールできていないケースが多い。
- Docker を学ぶ過程でツギハギの docker-compose.yml を作成することに注力しているケースがある（私もそうでした）が、その行為はおそらく、初学者にとって効率が悪く、容易に環境構築が行える、開発環境の共有、統一が行えるという Docker のメリットをスポイルしているように見える。
- 自分が開発したい環境に合ったイメージを、自分のローカル環境にインポートし、`docker-compose`を経由して操作が行える、デバッグが行えるといったスキルのほうが優先するべきだと感じる。

以上から、次のような目的で動いております

- とにかく簡単に Docker 上のローカル開発環境を手に入れられる
- Rails 6 特有の躓きポイントを極力意識させない
- 初学者の個人開発アプリで導入することの多い Bootstrap をスムーズに導入できるベースを作る（需要がありそうなら Bootstrap 導入すらも自動化）

個人的な動機としては最近学んだ Linux の知識を活用したいという点もあります

# 手順

## 前提

Docker がインストールされている

## git clone

以下のレポジトリに必要ファイルを用意しました
https://github.com/naokit-dev/Rails6_PG_WP_on_docker.git

git clone で必要なファイルを展開します

```
$ git clone https://github.com/naokit-dev/Rails6_PG_WP_on_docker.git
```

## Setup

setup.sh のあるディレクトリに移動し、ターミナルで

```
$ source setup.sh
```

以上です、あとは待つだけ

実行している`setup.sh`の内容は以下になります

```bash
#!/bin/bash
#
echo "docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle"
docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle
# 一旦ここでbuildしておかないと次のステップに進めない
echo "docker-compose build"
docker-compose build
# webpackerをinstall
echo "docker-compose run app rails webpacker:install"
docker-compose run app rails webpacker:install
# Yarnの設定(check_yarn_integrity: true => false)　エラーを回避　
echo "set check_yarn_integrity: false"
sed -icp 's/check_yarn_integrity: true/check_yarn_integrity: false/g' config/webpacker.yml
# docker-compose.ymlの内容に合わせてdatabase.ymlを修正
echo "copy config files"
mv temp_files/copy_database.yml config/database.yml
# rake db:create
echo "docker-compose run app rake db:create"
docker-compose run app rake db:create
# webpackでCSSをコンパイルする仕様に
echo "create CSS for Webpack"
mkdir app/javascript/stylesheets
touch app/javascript/stylesheets/application.scss
mv temp_files/copy_application.html.erb app/views/layouts/application.html.erb
# 一時ファイルの削除
echo "clean temp filse"
rm -r temp_files
rm config/webpacker.ymlcp

```

問題なければ

```
docker-compose up
```

でコンテナを立ち上げた後
ブラウザで`localhost:3000`にアクセスすると

# Yay! You’re on Rails!

# CSS コンパイルの仕様

以下の 2 つの方法が併用できます
**よくわからないということであれば ① の方法をとってください
以後解説を加える場合はそれを前提にします**

## ① Webpack でコンパイル

`app/javascript/stylesheets`配下に`application.scss`が作成されています

`app/views/layouts/application.html.erb`の`<head>`内に
`<%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>`が記述されていますのでここにコンパイルされた CSS が出力されます

別の style sheet を作成して使用する場合は
`app/javascript/stylesheets/custom.scss`というように作成し

`app/javascript/packs/application.js`に
`import "../stylesheets/custom.scss";`を追記します

## ② Sprocket でアセットコンパイル

Rails6 よりも前のバージョン同様
`app/assets/stylesheets`配下の CSS に記述します

**JavaScript については Rails6 ではデフォルトで Webpack でコンパイルする仕様です
結果 ① の場合、画像のみ`assets/images`に格納し、Sprocket でコンパイルする仕様となっています**

# 動作確認（必要に応じて実施してください）

適当に`scaffold`します

```
docker-compose exec app rails g scaffold User
```

db:migrate

```
docker-compose exec app rails db:migrate
```

ブラウザで`localhost:3000/users`にアクセスし適切なビューが表示させることを確認

`app/javascript/stylesheets/application.scss`に以下を追記し save する

```
body {
  background-color: red;
}
```

すると webpack-dev-server が自動で変更を検出しコンパイルします
そしてブラウザも自動でリロードしてくれるので

ブラウザ上に上記変更が反映されるはずです**便利!!**

# Bootstrap のインストール

以下の記事の手順でインストールします
[Docker で Rails チュートリアルのローカル開発環境構築 - Webpack で Bootstrap と Font Awesome を導入 - - Qiita](https://qiita.com/naokit-dev/items/30bf299cb0d785f9fb2f)

需要があれば自動化してみます

# 既知の問題

## webpack-dev-server のインストールに失敗することがある

イマイチ再現性なくて検証中です
