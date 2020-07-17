source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'sinatra'
gem 'google-cloud-firestore'
gem 'elasticsearch'
gem 'faraday_middleware-aws-sigv4'
gem 'line-bot-api'
gem 'dotenv'
