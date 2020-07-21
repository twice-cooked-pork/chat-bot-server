require 'rubygems'
require 'sinatra'
require 'line/bot'
require './clients/refrigerator'
require './clients/watson_client'

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

    # result[:mode]でどの問合せかを判断
    case result[:mode]
    when 'add_materials'
      response = '食材の追加だね。「たまねぎ ピーマン」みたいに追加する食材を入力してね。'
    when 'delete_materials'
      response = '食材の消去だね。「たまねぎ ピーマン」みたいに無くなった食材を入力してね。'
    when 'search_recipes'
      message = search_recipes(parse_input(result[:input]))
    when 'list_materials'
      response = "今の冷蔵庫の中はこれだよ\n\n#{refrigerator.all_materials.join("\n")}"
    when 'cancel_selection'
      response = '入力をやめるよ。'
    end

    # result[:prev_mode]が存在する場合はユーザからその後のメッセージがあった場合
    # result[:input]でユーザ入力を見る
    case result[:prev_mode]
    when 'add_materials'
      materials = parse_input(result[:input])
      refrigerator.add_materials(materials)
      response = "#{materials.join('、')}を追加したよ"
    when 'delete_materials'
      materials = parse_input(result[:input])
      refrigerator.delete_materials(materials)
      response = "#{materials.join('、')}を削除したよ"
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
  def parse_input(input)
    input.split(%r{\.| |　|,|;|:|/|、|。|\r|\t|\n}).compact
  end

  def line_client
    @line_client ||= Line::Bot::Client.new do |config|
      config.channel_id = ENV.fetch('LINE_CHANNEL_ID')
      config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET')
      config.channel_token = ENV.fetch('LINE_CHANNEL_TOKEN')
    end
  end

  def refrigerator
    @refrigerator ||= Refrigerator.new(user_id: user_id)
  end

  def search_recipes(input)
    # e.g. 'レシピ hoge fuga' -> 'hoge fuga'
    materials = parse_input(input.split(' ', 2)[1])
    materials = refrigerator.all_materials if materials.empty?
    if materials.empty?
      return {
        type: 'text',
        text: '冷蔵庫が空だよ!今すぐ買いに行こう!'
      }
    end

    recipes = ElasticsearchClient.new('recipe').search_by_materials(materials)['hits']['hits']
    if recipes.empty?
      return {
        type: 'text',
        text: "#{materials.join('、')}で検索したけどレシピが見つからなかったよ...",
      }
    end

    columns = recipes.map do |column|
      {
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

    {
      type: 'template',
      altText: '楽天レシピから検索したよ。',
      template: {
        type: 'carousel',
        columns: columns.uniq,
      },
    }
  end
end
