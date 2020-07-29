# チャットボットサーバ

##  セットアップ

```shell
# 管理者から環境変数ファイルを受け取る
$ source .env
$ bundle install
$ bundle exec thin -R config.ru -p 4567 start
```
