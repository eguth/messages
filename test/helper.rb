ENV['RACK_ENV'] = 'test'
ENV["DATABASE_URL"] = "sqlite3://#{File.dirname(__FILE__)}/test.db"

require 'bundler/setup'

require 'minitest/spec'
require 'minitest/autorun'

require 'mocha/setup'

require 'rack/test'

require 'database_cleaner'

require_relative '../app'

class MiniTest::Spec
  include Rack::Test::Methods

  def app
    App
  end

  def account
    @account ||= Account.create(:subdomain => "support")
  end

  def user
    @user ||= Person.create(:email => "test@test.com",
      :name => "test", :user_id => 1, :account => account)
  end

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end
