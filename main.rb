require 'sinatra'
require 'json'
require './elasticsearch_client'

get '/' do
  # 材料について牛乳でOR検索した結果を返す
  ElasticsearchClient.new.search_by_materials(['牛乳'])['hits']['hits'].to_json
end
