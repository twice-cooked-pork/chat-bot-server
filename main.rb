require 'sinatra'
require 'json'
require 'line/bot'
require './elasticsearch_client'
require './get_rakuten_data'
require './linebot_with_watson'
require 'dotenv'
Dotenv.load

get '/' do
  # 材料について牛乳でOR検索した結果を返す
  result = client.search_by_materials(['牛乳'])
  result['hits']['hits'].to_json
end

helpers do
  def client
    @client ||= ElasticsearchClient.new 'recipe'
  end

  def line_client
    @line_client ||= Line::Bot::Client.new { |config|
      config.channel_id = ENV['LINE_CHANNEL_ID']
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    }
  end
end
