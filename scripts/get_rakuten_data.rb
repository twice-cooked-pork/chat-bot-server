require 'net/http'
require 'json'
require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'

class GetRakutenRecipes
  DEBUG = true
  SLEEP_TIME = 0.3
  APPLICATION_ID = '1038057614600903965'

  #return : array
  def get_recipes_by_category_id(category_id)
    uri_str = "https://app.rakuten.co.jp/services/api/Recipe/CategoryRanking/20170426?applicationId=#{APPLICATION_ID}&formatVersion=2&categoryId=#{category_id}"
    uri = URI.parse(uri_str)
    response = Net::HTTP.get_response(uri)
    sleep SLEEP_TIME
    rawdata = JSON.parse(response.body)
    if rawdata['error'].nil?
      data = rawdata['result']
      # pp data if DEBUG
      data
    end
  end

  #return : array
  def get_all_recipes(category_ids_hash)
    recipes = []
    category_ids_hash.each do |large_id, large_value|
      datas = get_recipes_by_category_id(large_id)
      recipes.concat(datas) unless datas.nil?
      large_value.each do |medium_hash|
        medium_id = medium_hash.keys.first
        datas = get_recipes_by_category_id("#{large_id}-#{medium_id}")
        recipes.concat(datas) unless datas.nil?
        medium_hash[medium_id].each do |small_id|
          datas = get_recipes_by_category_id("#{large_id}-#{medium_id}-#{small_id}")
          recipes.concat(datas) unless datas.nil?
        end
      end
      pp recipes.length if DEBUG
    end
    recipes
  end

  #return hash
  def load_categories
    File.open('categoryList.json') do |j|
      category_list = JSON.load(j)
      category_list['result']
    end
  end

  #return hash
  def make_ids_hash(categories)
    # 全て入れると無料枠を突破しそうなので
    large_categories = categories['large'].reject { |cat| %w[10 18 25 44 47 35 39 14 43 21 40 34 24 37 15 13 51].include? cat['categoryId'] }.sample(ENV['RAKUTEN_MAX_RECIPES_COUNT'].to_i)
    medium_categories = categories['medium']
    small_categories = categories['small']
    ids_hash = {}

    p large_categories.map { |cat| cat['categoryId'] }

    large_categories.each do |large_category|
      large_id = large_category['categoryId'].to_i
      medium_array = []
      medium_categories.each do |medium_category|
        if medium_category['parentCategoryId'].to_i == large_id
          medium_id = medium_category['categoryId']
          small_array = []
          small_categories.each do |small_category|
            if small_category['parentCategoryId'].to_i == medium_id
              small_array << small_category['categoryId']
            end
          end
          medium_hash = {}
          medium_hash[medium_id] = small_array
          medium_array << medium_hash
        end
      end
      ids_hash[large_id] = medium_array
    end

    ids_hash
  end
end

if __FILE__ == $PROGRAM_NAME
  grd = GetRakutenRecipes.new
  categories = grd.load_categories
  ids_hash = grd.make_ids_hash(categories)
  recipes = grd.get_all_recipes(ids_hash)

  # 取得したデータをElasticsearchに登録する
  config = {
    host: ENV.fetch('AWS_ELASTIC_SEARCH_HOST'),
    port: 443,
    scheme: 'https',
    retry_on_failure: true,
    transport_options: {
      request: { timeout: 10 }
    }
  }
  client = Elasticsearch::Client.new(config) do |f|
    f.request :aws_sigv4,
      service: 'es',
      region: ENV.fetch('AWS_REGION'),
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
  end

  client.bulk(
    body: recipes.map do |recipe|
      { index: { _index: 'recipe', data: recipe } }
    end
  )
end
