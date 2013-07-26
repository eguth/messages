require "rubygems"
require "bundler/setup"
require "sinatra/base"
require "rack/ssl"
require "rack/csrf"
require "cgi"
require "redcarpet"
require "json"

require_relative "orm"
require_relative "helpers"

class App < Sinatra::Base
  set    :ssl, lambda { false }
  set    :max_messages, 10
  set    :protection, except: :frame_options

  configure :development do
    set :redirect_uri, "http://0.0.0.0:9292/oauth/authorize"
    set :zendesk_uri, "http://%{subdomain}.localhost:3000"
  end

  configure :test, :production do
    set :redirect_uri, "https://zendesk-wall.herokuapp.com/oauth/authorize"
    set :zendesk_uri, "https://%{subdomain}.zendesk.com"
  end

  enable :sessions
  enable :logging

  helpers Helpers

  use Rack::SSL, exclude: proc { !ssl? }
  use Rack::Session::Cookie, expire_after: 60*60*24, secret: (ENV["MESSAGES_SESSION_SECRET"] || rand.to_s)

  get "/" do
    erb :index
  end

  get "/:subdomain" do
    if logged_in?
      erb :messages
    else
      erb :login
    end
  end

  post "/:subdomain/message" do
    return 401 unless logged_in?

    parent = params[:parent_id].to_i

    message = Message.create(
      body: render_text(params[:body]),
      account: account,
      person_id: session[:user_id],
      parent_id: parent > 0 ? parent : nil
    )

    if message.saved?
      partial = if message.parent
        erb(:_child, locals: { message: message }, layout: false)
      else
        erb(:_message, locals: { message: message }, layout: false)
      end


      response = JSON.dump(body: partial, parent_id: message.parent_id)

      if env["faye.client"]
        env["faye.client"].publish(current_channel, response)
      else
        body response
      end

      status 200
    else
      status 422

      errors = message.errors.full_messages.join("<br />")
      body "Could not create message: #{errors}"
    end
  end

  put "/:subdomain/:id" do
    message = account.messages.get(params[:id].to_i)

    if message
      message.adjust!(likes: 1)
      message.reload

      status 200
      body message.likes.to_s
    else
      404
    end
  end

  post "/:subdomain/preview" do
    return 401 unless logged_in?

    status 200
    body render_text(params[:body])
  end

  get "/:subdomain/login" do
    if logged_in?
      redirect "/#{params[:subdomain]}"
    else
      redirect client.auth_code.authorize_url(redirect_uri: settings.redirect_uri,
        scope: "read write", state: [params[:subdomain], CGI.escape(Rack::Csrf.csrf_token(env))].join("|"))
    end
  end

  get "/:subdomain/logout" do
    session[:user_id] = nil
    session[:info] = "Logged out"

    redirect "/#{params[:subdomain]}"
  end

  get "/oauth/authorize" do
    params[:subdomain], csrf = params.fetch("state", "").split("|")

    if params[:error] || !csrf || CGI.unescape(csrf) != Rack::Csrf.csrf_token(env)
      [400, {}, params[:error] || "Invalid CSRF"]
    else
      begin
        token = client.auth_code.get_token(params[:code], redirect_uri: settings.redirect_uri).token
        create_or_update_person_from_token!(token)
        session[:success] = "Welcome #{person.name}!"
      rescue OAuth2::Error => e
        session[:error] = "An error occurred when trying to authenticate using OAuth. Try again or please contact sdavidovitz@zendesk.com."
        logger.error("OAuth 2 error: #{e.message}, #{e.code}")
        logger.error("OAuth 2 error: #{e.response}")
      end

      redirect "/#{params[:subdomain]}"
    end
  end
end
