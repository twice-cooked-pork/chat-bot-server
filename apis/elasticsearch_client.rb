require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'

class ElasticsearchClient
  MAX_RECIPES_COUNT = 10

  def initialize(index)
    @index = index

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

  def all_recipes
    @client.search(index: @index, size: MAX_RECIPES_COUNT, body: nil)
  end

  def recipe(id)
    @client.get(index: @index, id: id)
  end

  def search_by_materials(materials)
    @client.search(
      index: @index,
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
