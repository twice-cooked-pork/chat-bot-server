require "sinatra"
require "line/bot"
require "dotenv"
Dotenv.load

def line_client
  @line_client ||= Line::Bot::Client.new { |config|
    config.channel_id = ENV["LINE_CHANNEL_ID"]
    config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
    config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
  }
end

def create_sending_recipe_to_line
  refri_list = get_all_grocery
  recipes = search_by_materials(refri_list)
  columns = []
  recipes["hit"]["hit"].each do |column|
    columns << {
      "imageUrl": "#{column["foodImageUrl"]}",
      "action": {
        "type": "uri",
        "label": "View detail",
        "uri": "#{column["recipeUrl"]}",
      },
    }
  end
  message = {
    type: "template",
    "altText": "楽天レシピからの画像です。",
    "template": {
      "type": "image_carousel",
      "columns": columns,
    },
  }
end

post "/callback" do
  body = request.body.read

  signature = request.env["HTTP_X_LINE_SIGNATURE"]
  unless line_client.validate_signature(body, signature)
    error 400 do "Bad Request" end
  end

  events = line_client.parse_events_from(body)
  events.each do |event|
    if event.is_a?(Line::Bot::Event::Message)
      if event.type === Line::Bot::Event::MessageType::Text
        getText = event.message["text"]
        if getText === "追加"
          response = "食材の追加だね。「たまねぎ ピーマン」みたいに入力してね"
        elsif getText === "レシピ"
          create_sending_recipe_to_line
        elsif getText === "削除"
          response = "どの食材が無くなったんだい。「たまねぎ」みたいに食材を入力してね"
          message = {
            type: "text",
            text: response,
          }
        elsif getText === "在庫"
          response = "今は愛の在庫が切れてるよ。買いに行かなくちゃ。"
          message = {
            type: "text",
            text: response,
          }
        else response = getText         end
        message ||= {
          type: "text",
          text: "エラーが発生しました。",
        }
        client.reply_message(event["replyToken"], message)
      end
    end
  end

  "OK"
end
