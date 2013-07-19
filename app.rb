require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "rack/ssl"
require "rack/csrf"
require "cgi"

require_relative "orm"
require_relative "helpers"

### TODO
# * Handle errors better

class App < Sinatra::Base
  set    :ssl, lambda { false }
  set    :max_messages, 25
  set    :protection, :except => :frame_options

  configure :development do
    set :redirect_uri, "http://0.0.0.0:9292/oauth/authorize"
    set :zendesk_uri, "http://%{subdomain}.localhost:3001"
  end

  configure :production do
    set :redirect_uri, "https://zendesk-wall.herokuapp.com/oauth/authorize"
    set :zendesk_uri, "https://%{subdomain}.zendesk.com"
  end

  enable :sessions
  enable :logging

  helpers Helpers

  use Rack::SSL, :exclude => proc { !ssl? }
  use Rack::Session::Cookie, :expire_after => 60*60*24, :secret => (ENV["MESSAGES_SESSION_SECRET"] || rand.to_s)

  get "/" do
    erb :index
  end

  get "/:subdomain" do
    erb :messages
  end

  post "/:subdomain/message" do
    return 401 unless logged_in?

    message = Message.create(
      :body => params[:body],
      :account => account,
      :person_id => session[:user_id]
    )

    partial = if message.saved?
      erb(:_message, :locals => { :message => message }, :layout => false)
    else
      @error = "Could not create message."
      logger.error("Message error: #{message.errors.inspect}")

      alert
    end

    if request.xhr?
      env["faye.client"].publish(current_channel, partial)

      200
    else
      redirect "/#{params[:subdomain]}"
    end
  end

  get "/:subdomain/login" do
    if logged_in?
      redirect "/#{params[:subdomain]}"
    else
      redirect client.auth_code.authorize_url(:redirect_uri => settings.redirect_uri,
        :scope => "read write", :state => [params[:subdomain], CGI.escape(Rack::Csrf.csrf_token(env))].join("|"))
    end
  end

  get "/:subdomain/logout" do
    session[:user_id] = nil

    @info = "Logged out"

    erb ""
  end

  get "/oauth/authorize" do
    params[:subdomain], csrf = params.fetch("state", "").split("|")

    if params[:error] || !csrf || CGI.unescape(csrf) != Rack::Csrf.csrf_token(env)
      [400, {}, params[:error] || "Invalid CSRF"]
    else
      begin
        token = client.auth_code.get_token(params[:code], :redirect_uri => settings.redirect_uri).token
        create_or_update_person_from_token!(token)
      rescue OAuth2::Error => e
        logger.error("OAuth 2 error: #{e.message}, #{e.code}")
        logger.error("OAuth 2 error: #{e.response}")
      end

      redirect "/#{params[:subdomain]}"
    end
  end
end
