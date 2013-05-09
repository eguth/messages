require "rubygems"
require "sinatra/base"
require "rack/ssl"

require_relative "orm"
require_relative "helpers"

class App < Sinatra::Base
  set    :ssl, lambda { !development? }
  enable :sessions

  helpers Helpers

  use Rack::SSL, :exclude => Proc.new { !ssl? }
  use Rack::Session::Cookie, :expire_after => 60*60*24, :secret => (ENV["MESSAGES_SESSION_SECRET"] || "#{rand}")

  before do
    if !session[:id]
      # OAuth against Zendesk
    end
  end

  get "/" do
    @info = "Wooo"
    erb :message
  end

  get "/since" do
    erb "Rendering messages since the since parameter"
  end

  get "/logout" do
    session.clear
    @info = "Logged out"
  end
end

App.run

