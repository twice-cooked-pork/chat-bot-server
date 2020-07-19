require 'sinatra'
require 'line/bot'
require 'dotenv'
require './func_refriDB'
require 'google/cloud/firestore'
require './watson_client'

Dotenv.load

def add_materials(input)
  add_to_refri(input, refri_col)
  "#{input}を追加するね"
end

def delete_materials(input)
  "#{input}を削除するね"
end

def search_recipes_by_input(input)
  "#{input}で検索するね"
end

def search_recipes(input = -1)
  if input == -1
    refri_list = get_all_grocery(refri_col)
  else
    refri_list = [input]
    pp refri_list
  end
  recipes = client.search_by_materials(refri_list)
  columns = []
  recipes['hits']['hits'].each do |column|
    columns << {
      "imageUrl": "#{column['_source']['foodImageUrl']}",
      "action": {
        "type": 'uri',
        "label": 'レシピを見る',
        "uri": "#{column['_source']['recipeUrl']}",
      },
    }
  end
  message = {
    type: 'template',
    "altText": '楽天レシピからの画像です。',
    "template": {
      "type": 'image_carousel',
      "columns": columns,
    },
  }
  message
end

def list_materials()
  "今の冷蔵庫の中はこれだよ\n\n#{get_all_grocery(refri_col).join("\n")}"
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  error(400) { 'Bad Request' } unless line_client.validate_signature(body, signature)

  events = line_client.parse_events_from(body)
  events.each do |event|
    next unless event.is_a?(Line::Bot::Event::Message)
    next unless event.type == Line::Bot::Event::MessageType::Text

    result = WatsonClient.new(user_id: event['source']['userId']).send_message(event.message['text'])

    # result[:mode]でどの問合せかを判断
    # result[:input]が存在する場合はユーザからその後のメッセージがあった場合
    case result[:mode]
    when 'add_materials'
      response = '食材の追加だね。「たまねぎ ピーマン」みたいに入力してね'
      response = add_materials(result[:input]) if result[:input]
    when 'delete_materials'
      response = 'どの食材が無くなったんだい。「たまねぎ」みたいに食材を入力してね'
      response = delete_materials(result[:input]) if result[:input]
    when 'search_recipes'
      message = search_recipes
      message = search_recipes(result[:input]) if result[:input]
    when 'list_materials'
      # response = 'どの食材が無くなったんだい。「たまねぎ」みたいに食材を入力してね'
      response = list_materials()
    when 'check_materials'
      response = '今は愛の在庫が切れてるよ。買いに行かなくちゃ。'
    when 'cancel_selection'
      response = 'やめるんだね。。。'
    end

    message ||= {
      type: 'text',
      text: response,
    }
    line_client.reply_message(event['replyToken'], message)
  end

  'OK'
end

helpers do
  def line_client
    @line_client ||= Line::Bot::Client.new do |config|
      config.channel_id = ENV.fetch('LINE_CHANNEL_ID')
      config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET')
      config.channel_token = ENV.fetch('LINE_CHANNEL_TOKEN')
    end
  end

  def elastic_search_client
    @elastic_search_client ||= ElasticsearchClient.new 'recipe'
  end

  def refri_col
    firestore_client ||= Google::Cloud::Firestore.new project_id: ENV['GOOGLE_PROJECT_ID']
    @refri_col = firestore_client.col 'refrigerator'
  end
end
