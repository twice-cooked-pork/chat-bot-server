require "sinatra"
require "json"
require "./elasticsearch_client"
require "./linebot"
require "./get_rakuten_data"

get "/" do
  # 材料について牛乳でOR検索した結果を返す
  result = client.search_by_materials(["牛乳"])
  result["hits"]["hits"].to_json
end

helpers do
  def client
    @client ||= ElasticsearchClient.new "recipe"
  end
end
