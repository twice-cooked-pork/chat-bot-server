require "net/http"
require "json"

class Get_rakuten_data
  DEBUG = true
  Sleep_time = 0.3
  Application_ID = "1038057614600903965"

  #return : array
  def get_recipes_by_category_id(category_id)
    uri_str = "https://app.rakuten.co.jp/services/api/Recipe/CategoryRanking/20170426?applicationId=#{Application_ID}&formatVersion=2&categoryId=#{category_id}"
    uri = URI.parse(uri_str)
    response = Net::HTTP.get_response(uri)
    sleep Sleep_time
    rawdata = JSON.parse(response.body)
    if rawdata["error"].nil?
      data = rawdata["result"]
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
    File.open("categoryList.json") do |j|
      category_list = JSON.load(j)
      category_list["result"]
    end
  end

  #return hash
  def make_ids_hash(categories)
    large_categories = categories["large"]
    medium_categories = categories["medium"]
    small_categories = categories["small"]
    ids_hash = {}

    large_categories.each do |large_category|
      large_id = large_category["categoryId"].to_i
      medium_array = []
      medium_categories.each do |medium_category|
        if medium_category["parentCategoryId"].to_i == large_id
          medium_id = medium_category["categoryId"]
          small_array = []
          small_categories.each do |small_category|
            if small_category["parentCategoryId"].to_i == medium_id
              small_array << small_category["categoryId"]
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

if __FILE__ == $0
  grd = Get_rakuten_data.new
  categories = grd.load_categories
  ids_hash = grd.make_ids_hash(categories)
  grd.get_all_recipes(ids_hash)
end