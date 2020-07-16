require 'elasticsearch'
require 'faraday_middleware/aws_sigv4'

def get_elasticsearch_client
  Elasticsearch::Client.new(url: ENV['AWS_ELASTIC_SEARCH_HOST']) do |f|
    f.request :aws_sigv4,
      service: 'es',
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
  end
end
