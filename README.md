# 更新(2020.09.05)

（詳細最下部）

- Nginxコンテナの追加 => Deployと同じ環境で開発、検証
- Bootstrap & Font awesome install自動化 => すぐ使えます
- VSCodeのRemote Containerに対応 => ものすごく便利なので使ってほしい
- build、セットアップ時間の大幅短縮 => 半分以下の時間でセットアップできるようになりました（感覚、笑）

今後の予定
- 環境変数整理
- VSCodeのRemote Container環境最適化、拡張機能追加など

# 何ができるか

ターミナルのコマンド一つで、Docker上のRailsローカル開発環境が構築できます

```
source setup.sh
```
# なぜやるか

私は環境構築が好きですが、
環境構築ができるようになるまでに躓くことが多かったので
同じ状況の方の役に立てるように

**すぐ使える、ほとんどの方にとって最善のRails6の開発環境を目指します（長い目で）**

これからRailsでwebアプリ開発を学ぶ多くの人に使っていただきたい
より良いものするためのご意見、ご指摘もお待ちしております

- Railsでポートフォリオを創りたい
- Railsチュートリアルをdocker & ローカル環境で挑みたい
- Rails6特有のwebpackで躓く
- とりあえずサクッと開発したい

そんな方の役に立つよう、新しい要素を取り入れながら改善を重ねていきたいと思っています


# 環境

## 目標環境(Docker上)

- Ruby 2.7.1
- Rails 6.0.3
- Nginx 1.18
- PostgreSQL 11.0
- Webpack (Hot-reload対応, JS, CSSコンパイル対応化)
 - Bootstrap 4.5
 - Font awesome

 
## 動作確認環境

- Mac OS Mojave 10.14.6
- Docker 2.3.0.4

VSCodeでローカルから`docker-compose up`もしくは、
VSCode Remote Containerで動作確認しています


# 手順

## 前提

Docker desktopがインストールされている
[Docker Desktop for Mac and Windows | Docker](https://www.docker.com/products/docker-desktop)

## git clone

以下のレポジトリにソースコードを用意しました
https://github.com/naokit-dev/Rails6_PG_WP_on_docker.git

git cloneで必要なファイルを展開します

```
$ git clone https://github.com/naokit-dev/Rails6_PG_WP_on_docker.git
```



## Setup

setup.shのあるディレクトリに移動し、ターミナルで

```
$ source setup.sh
```

以上です、あとは待つだけ


### setup.sh
実行している`setup.sh`の内容は以下になります

```bash
#!/bin/bash

##### options #####
opptinal_packages=true

install_Bootstrap=true
install_FontAwesome=true
###################

# Rails new
echo "docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle"
docker-compose run app rails new . --force --no-deps --database=postgresql --skip-bundle

# bundle install
echo "docker-compose build"
docker-compose build

#不要
# echo "docker-compose run app rails webpacker:install"
# docker-compose run app rails webpacker:install

# check_yarn_integrity... error対策
echo "set check_yarn_integrity: false"
sed -icp 's/check_yarn_integrity: true/check_yarn_integrity: false/g' config/webpacker.yml

# database.ymlを置き換える
echo "copy config files"
mv temp_files/copy_database.yml config/database.yml

# 初期DBの作成
echo "docker-compose run app rake db:create"
docker-compose run app rake db:create

# webpackがコンパイルするCSSを配置
echo "create CSS for Webpack"
mkdir app/javascript/stylesheets
touch app/javascript/stylesheets/application.scss
mv temp_files/copy_application.html.erb app/views/layouts/application.html.erb
echo 'import "../stylesheets/application.scss";' >> app/javascript/packs/application.js

# optionに応じてパッケージをインストール後再build
if "$opptinal_packages" ; then
echo "install optional packages"
if "$install_Bootstrap" ; then
echo "install Bootstrap"
docker-compose run app yarn add bootstrap jquery popper.js --ignore-optional
echo 'require("bootstrap");' >> app/javascript/packs/application.js
echo '@import "bootstrap/scss/bootstrap";' >> app/javascript/stylesheets/application.scss
mv temp_files/copy_environment.js config/webpack/environment.js
fi

if "$install_FontAwesome" ; then
echo "install Font Awesome"
docker-compose run app yarn add @fortawesome/fontawesome-free
echo 'require("@fortawesome/fontawesome-free");' >> app/javascript/packs/application.js
echo 'import "@fortawesome/fontawesome-free/js/all";' >> app/javascript/packs/application.js
echo '@import "@fortawesome/fontawesome-free/scss/fontawesome";' >> app/javascript/stylesheets/application.scss
fi

docker-compose build
fi

# 不要ファイルの削除
echo "clean temp filse"
rm -r temp_files
rm config/webpacker.ymlcp

# 一旦起動したコンテナを終了
echo "docker-compose down"
docker-compose down
```
### setup.shのoption
```
##### options #####
# falseならいずれのpackageもインストールされません
opptinal_packages=true

# installするpackageを個別に選択(true or false)
install_Bootstrap=true
install_FontAwesome=true
###################
```


問題なければ

```
docker-compose up
```

でコンテナを立ち上げた後
ブラウザで`localhost`, or `localhost:80`にアクセスすると


# Yay! You’re on Rails!



# CSSコンパイルの仕様

以下の2つの方法が併用できます
**よくわからないということであれば①の方法をとってください
以後解説を加える場合はそれを前提にします**

## ① Webpackでコンパイル

`app/javascript/stylesheets`配下に`application.scss`が作成されています

`app/views/layouts/application.html.erb`の`<head>`内に
` <%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>`が記述されていますのでここにコンパイルされたCSSが出力されます

別のstyle sheetを作成して使用する場合は
`app/javascript/stylesheets/custom.scss`というように作成し

`app/javascript/packs/application.js`に
`import "../stylesheets/custom.scss";`を追記します

## ② Sprocketでアセットコンパイル

Rails6よりも前のバージョン同様
`app/assets/stylesheets`配下のCSSに記述します

**JavaScriptについてはRails6ではデフォルトでWebpackでコンパイルする仕様です
結果①の場合、画像のみ`assets/images`に格納し、Sprocketでコンパイルする仕様となっています**



# 動作確認（必要に応じて実施してください）

適当に`scaffold`します

```
docker-compose exec app rails g scaffold User
```

db:migrate

```
docker-compose exec app rails db:migrate
```

ブラウザで`localhost/users`にアクセスし適切なビューが表示させることを確認



`app/javascript/stylesheets/application.scss`に以下を追記しsaveする

```
body {
  background-color: red;
}
```

するとwebpack-dev-serverが自動で変更を検出しコンパイルします
ブラウザも自動でリロードしてくれるので上記変更が自動で反映されるはずです**便利!!**

適当なview(ここでは`app/views/users/index.html.erb`)に適当なBootstrapのコンポーネントを差し込む

```
<button type="button" class="btn btn-primary">Primary</button>
```
すぐにBootstrapも利用できます





# 既知の問題
build中のエラー
alpineに起因するみたいだけと未解決

```
WARNING: Ignoring APKINDEX.2c4ac24e.tar.gz: Bad file descriptor
```

[linux - Bad file descriptor ERROR during apk update in Docker container... Why? - Stack Overflow](https://stackoverflow.com/questions/48736212/bad-file-descriptor-error-during-apk-update-in-docker-container-why)



# 更新履歴
## 更新(2020.09.05)
### Nginxコンテナの追加
- Nginx \- puma \- Rails \- PostgreSQLの構成に変更
- Deployと同じ環境で開発、検証できる

### Bootstrap & Font awesome install自動化
- `setup.sh`の中でインストールの有無を選択可(デフォルトで両方ともインストール)
- Bootstrap（v4.5）を自動インストール、（jQuery, popper.jsを含む）
- Font awesomeを自動インストール
- 開発の初速アップ、Font awesomeは不要か迷ったのですが、Railsチュートリアルでの使用を意識して採用しました

### VSCodeのRemote Containerに対応
- `.devcontainer`をソースコードに含んでいます
- Remote Containerを使用することで`docker-compose...`コマンドが不要になり、コンテナを意識することなく開発に取り組めます
- コンテナ内での操作となるため、alpine-linuxにgitとbashのinstallを追加
 
### build、セットアップ時間の大幅短縮
- docker-compose.yml内で`app`（rails)と`webpacker`のimageを共有化`docker-compose build`時、Dockerfileからのbuildが2回から1回に
- volume mountの最適化、`node_modules`を別途マウントすることで, yarn add ...他の高速化（mac環境に限るかもしれませんが効果大）
- `rails new`の時点でwebpackのインストールがうまくできているようなので、重複回避

## 公開(2020.8.23)
