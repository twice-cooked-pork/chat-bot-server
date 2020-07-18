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
  # refri_list = get_all_grocery
  # recipes = search_by_materials(refri_list)
  columns = []
  sample_columns = [
    {
      "foodImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/34d4ce95b8674c8fb6c8f08b5115464a9f180c31.17.2.3.2.jpg",
      "recipeDescription": "小鉢がもう1品ほしいなっていう時に簡単でオススメです。",
      "recipePublishday": "2011/08/22 19:04:07",
      "shop": 0,
      "pickup": 1,
      "recipeId": 1200002403,
      "nickname": "JIMA88",
      "smallImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/34d4ce95b8674c8fb6c8f08b5115464a9f180c31.17.2.3.2.jpg?thum=55",
      "recipeMaterial": [
        "きゅうり",
        "ごま油",
        "すりごま",
        "鶏ガラスープのもと",
        "ビニール袋",
      ],
      "recipeIndication": "5分以内",
      "recipeCost": "100円以下",
      "rank": "1",
      "recipeUrl": "https://recipe.rakuten.co.jp/recipe/1200002403/",
      "mediumImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/34d4ce95b8674c8fb6c8f08b5115464a9f180c31.17.2.3.2.jpg?thum=54",
      "recipeTitle": "1分で！うまうま胡麻キュウリ",
    },
    {
      "foodImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/fbd7dd260d736654532e6c0b1ec185a0cede8675.49.2.3.2.jpg",
      "recipeDescription": "そのままでも、ご飯にのせて丼にしても♪",
      "recipePublishday": "2017/10/10 22:37:34",
      "shop": 0,
      "pickup": 0,
      "recipeId": 1760028309,
      "nickname": "はぁぽじ",
      "smallImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/fbd7dd260d736654532e6c0b1ec185a0cede8675.49.2.3.2.jpg?thum=55",
      "recipeMaterial": [
        "鶏むね肉",
        "塩",
        "酒",
        "片栗粉",
        "○水",
        "○塩",
        "○鶏がらスープの素",
        "○黒胡椒",
        "長ネギ",
        "いりごま",
        "ごま油",
      ],
      "recipeIndication": "約10分",
      "recipeCost": "300円前後",
      "rank": "2",
      "recipeUrl": "https://recipe.rakuten.co.jp/recipe/1760028309/",
      "mediumImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/fbd7dd260d736654532e6c0b1ec185a0cede8675.49.2.3.2.jpg?thum=54",
      "recipeTitle": "ご飯がすすむ！鶏むね肉のねぎ塩焼き",
    },
    {
      "foodImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/35a4cf78ecd120fd6400e7dda6acb7b08f9df899.06.2.3.2.jpg",
      "recipeDescription": "とろぷるな温泉たまごが簡単にできちゃいます。",
      "recipePublishday": "2011/04/05 23:41:18",
      "shop": 0,
      "pickup": 0,
      "recipeId": 1720001849,
      "nickname": "あんちょこりん。",
      "smallImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/35a4cf78ecd120fd6400e7dda6acb7b08f9df899.06.2.3.2.jpg?thum=55",
      "recipeMaterial": [
        "卵",
      ],
      "recipeIndication": "約10分",
      "recipeCost": "100円以下",
      "rank": "3",
      "recipeUrl": "https://recipe.rakuten.co.jp/recipe/1720001849/",
      "mediumImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/35a4cf78ecd120fd6400e7dda6acb7b08f9df899.06.2.3.2.jpg?thum=54",
      "recipeTitle": "温泉たまご♡お湯をわかすだけ！超簡単",
    },
    {
      "foodImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/eb2f27f434436225566c034083f98ddf2aaa0a50.50.2.3.2.jpg",
      "recipeDescription": "お弁当のおかずにと思って作ったら、主人が、お弁当箱の半分のスペースは、これでいいよと言うぐらい絶賛してくれたので、我が家の定番おかずになりました(^^♪",
      "recipePublishday": "2011/04/01 14:52:17",
      "shop": 0,
      "pickup": 1,
      "recipeId": 1290001623,
      "nickname": "ライム2141",
      "smallImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/eb2f27f434436225566c034083f98ddf2aaa0a50.50.2.3.2.jpg?thum=55",
      "recipeMaterial": [
        "長ナス",
        "ピーマン",
        "砂糖",
        "醤油",
        "ゴマ油orサラダ油",
        "だしの素",
        "白いりゴマ",
      ],
      "recipeIndication": "約10分",
      "recipeCost": "100円以下",
      "rank": "4",
      "recipeUrl": "https://recipe.rakuten.co.jp/recipe/1290001623/",
      "mediumImageUrl": "https://image.space.rakuten.co.jp/d/strg/ctrl/3/eb2f27f434436225566c034083f98ddf2aaa0a50.50.2.3.2.jpg?thum=54",
      "recipeTitle": "主人が、いくらでも食べれると絶賛のナス・ピーマン",
    },
  ]

  # recipes["hit"]["hit"].each do |column|
  sample_columns.each do |column|
    columns << {
      "imageUrl": "#{column[:foodImageUrl]}",
      "action": {
        "type": "uri",
        "label": "View detail",
        "uri": "#{column[:recipeUrl]}",
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
  message
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
          message = {
            type: "text",
            text: response,
          }
        elsif getText === "レシピ"
          message = create_sending_recipe_to_line
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
        else response = getText
          message ||= {
          type: "text",
          text: response,
        }         end
        line_client.reply_message(event["replyToken"], message)
      end
    end
  end

  "OK"
end
