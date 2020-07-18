require 'sinatra'
require 'line/bot'
require 'dotenv'
require './watson_client'

Dotenv.load

def add_materials(input)
  "#{input}を追加するね"
end

def delete_materials(input)
  "#{input}を削除するね"
end

def search_recipes(input)
  "#{input}で検索するね"
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
      response = '今日のレシピは回鍋肉にしよう'
      response = search_materials(result[:input]) if result[:input]
    when 'list_materials'
      response = 'どの食材が無くなったんだい。「たまねぎ」みたいに食材を入力してね'
    when 'check_materials'
      response = '今は愛の在庫が切れてるよ。買いに行かなくちゃ。'
    when 'cancel_selection'
      response = 'やめるんだね。。。'
    end

    message = {
      type: 'text',
      text: response
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
end
