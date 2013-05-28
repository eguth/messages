source "https://rubygems.org"
ruby   "2.0.0"

gem "sinatra"
gem "puma"
gem "json"

gem "rack-ssl"
gem "rack_csrf"

gem "oauth2"
gem "faye", :path => "vendor/faye"
gem "zendesk_api", :git => "https://github.com/zendesk/zendesk_api_client_rb"

gem "data_mapper"
gem "dm-postgres-adapter", :group => :production
gem "dm-sqlite-adapter", :group => :development
gem "dm-timestamps"

group :test do
  gem "database_cleaner"
  gem "rack-test"
  gem "mocha"
end
