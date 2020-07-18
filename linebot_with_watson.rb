require 'sinatra'
require 'line/bot'
require 'dotenv'
require './watson_client'
Dotenv.load

def client
  @client ||= Line::Bot::Client.new do |config|
    config.channel_id = ENV.fetch('LINE_CHANNEL_ID')
    config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET')
    config.channel_token = ENV.fetch('LINE_CHANNEL_TOKEN')
  end
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each do |event|
    next unless event.is_a?(Line::Bot::Event::Message)
    next unless event.type == Line::Bot::Event::MessageType::Text

    result = WatsonClient.new.send_message(event.message['text'])

    case result[:mode]
    when 'add_materials'
      response = '食材の追加だね。「たまねぎ ピーマン」みたいに入力してね'
    when 'delete_materials'
      response = 'どの食材が無くなったんだい。「たまねぎ」みたいに食材を入力してね'
    when 'list_materials'
      response = 'どの食材が無くなったんだい。「たまねぎ」みたいに食材を入力してね'
    when 'search_recipes'
      response = '今日のレシピは回鍋肉にしよう'
    when 'check_materials'
      response = '今は愛の在庫が切れてるよ。買いに行かなくちゃ。'
    when 'cancel_selection'
      response = 'やめるんだね。。。'
    end

    message = {
      type: 'text',
      text: response
    }
    client.reply_message(event['replyToken'], message)
  end

  'OK'
end
