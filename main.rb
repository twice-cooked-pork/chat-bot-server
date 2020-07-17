require 'sinatra'
require 'json'
require './elasticsearch_client'

get '/' do
  # 材料について牛乳でOR検索した結果を返す
  result = client.search_by_materials(['牛乳'])
  result['hits']['hits'].to_json
end

helpers do
  def client
    @client ||= ElasticsearchClient.new 'recipe'
  end
end
