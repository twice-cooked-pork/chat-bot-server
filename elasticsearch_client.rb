require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'

class ElasticsearchClient
  attr_accessor :client

  INDEX = 'recipe'
  MAX_RECIPES_COUNT = 10

  def initialize
    config = {
      host: ENV.fetch('AWS_ELASTIC_SEARCH_HOST'),
      port: 443,
      scheme: 'https',
      retry_on_failure: true,
      transport_options: {
        request: { timeout: 10 }
      }
    }

    @client = Elasticsearch::Client.new(config) do |f|
      f.request :aws_sigv4,
        service: 'es',
        region: ENV.fetch('AWS_REGION'),
        access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
        secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
    end
  end

  def register_recipes(recipes)
    @client.bulk(
      body: recipes.map do |recipe|
        { index: { _index: INDEX, data: recipe } }
      end
    )
  end

  def get_all
    @client.search(index: INDEX, size: MAX_RECIPES_COUNT, body: nil)
  end

  def get_by_id(id)
    @client.get(index: INDEX, id: id)
  end

  def search_by_materials(materials)
    @client.search(
      index: INDEX,
      size: MAX_RECIPES_COUNT,
      body: {
        query: {
          match: {
            recipeMaterial: materials.join(' ')
          }
        }
      }
    )
  end
end
