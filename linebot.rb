require 'sinatra'
require 'line/bot'
require 'dotenv'
Dotenv.load

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_id = ENV["LINE_CHANNEL_ID"]
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  events.each do |event|
    if event.is_a?(Line::Bot::Event::Message)
      if event.type === Line::Bot::Event::MessageType::Text
        getText = event.message['text']
        if getText === '追加'
            response = '食材の追加だね。「たまねぎ 2、ピーマン 3」みたいに入力してね'
        elsif getText === 'レシピ'
            response = '今日のレシピは回鍋肉にしよう'
        elsif getText === '在庫'
            response = '今は愛の在庫が切れてるよ。買いに行かなくちゃ。'
        else response = getText
        end
        message = {
          type: 'text',
          text: response
        }
        client.reply_message(event['replyToken'], message)
      end
    end
  end

  "OK"
end