require 'rubygems'
require 'sinatra'
require 'line/bot'
require 'dotenv'
require 'google/cloud/firestore'
require './func_refriDB'
require './watson_client'

Dotenv.load

def delete_materials(input)
  "#{input}を削除するね"
end

def search_recipes_by_input(input)
  "#{input}で検索するね"
end

def search_recipes(refri_col, input)
  if input == -1
    refri_list = get_all_grocery(refri_col)
  else
    refri_list = [input]
    pp refri_list
  end
  recipes = elastic_search_client.search_by_materials(refri_list)
  columns = []

  recipes['hits']['hits'].each do |column|
    columns << {
      thumbnailImageUrl: "#{column['_source']['foodImageUrl']}",
      title: "#{column['_source']['recipeTitle'][0, 40]}",
      text: column['_source']['recipeDescription'][0, 60].to_s,
      actions: [{
        type: 'uri',
        label: 'くわしく見る',
        uri: "#{column['_source']['recipeUrl']}",
      }],
    }
  end

  message = {
    type: 'template',
    altText: '楽天レシピからの画像だよ。',
    template: {
      type: 'carousel',
      columns: columns.uniq,
    },
  }
  message
end

def list_materials(refri_col)
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

    user_id = event['source']['userId']
    result = WatsonClient.new(user_id: user_id).send_message(event.message['text'])
    refri_col = set_refri_col(user_id: user_id)

    # result[:mode]でどの問合せかを判断
    case result[:mode]
    when 'add_materials'
      response = '食材の追加だね。「たまねぎ ピーマン」みたいに追加する食材を入力してね。'
    when 'delete_materials'
      response = '食材の消去だね。「たまねぎ ピーマン」みたいに無くなった食材を入力してね。'
    when 'search_recipes'
      message = search_recipes(refri_col, result[:input] || -1)
    when 'list_materials'
      response = list_materials(refri_col)
    when 'cancel_selection'
      response = '入力をやめたよ。'
    end

    # result[:prev_mode]が存在する場合はユーザからその後のメッセージがあった場合
    # result[:input]でユーザ入力を見る
    case result[:prev_mode]
    when 'add_materials'
      add_to_refri(result[:input], refri_col)
      response = "#{result[:input]}を追加するね"
    when 'delete_materials'
      erase_from_refri(result[:input], refri_col)
      response = "#{result[:input]}を削除するね"
    end

    message ||= {
      type: 'text',
      text: response,
    }
    puts 'message:'
    pp message
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

  def set_refri_col(user_id:)
    firestore_client = Google::Cloud::Firestore.new project_id: ENV['GOOGLE_PROJECT_ID']
    @refri_col ||= firestore_client.col user_id
  end
end
