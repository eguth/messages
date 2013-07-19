require "oauth2"
require "zendesk_api"

module Helpers
  def alert
    if @alert
      alert_for_type("alert", @alert)
    elsif @success
      alert_for_type("alert alert-success", @success)
    elsif @error
      alert_for_type("alert alert-error", @error)
    elsif @info
      alert_for_type("alert alert-info", @info)
    end
  end

  def alert_for_type(type, message)
    "<div class=\"#{type}\">"+
    "<button type=\"button\" class=\"close\" data-dismiss=\"alert\">&times;</button>"+
    "#{message}</div>"
  end

  def client
    @client ||= OAuth2::Client.new('messages', client_secret, :site => settings.zendesk_uri % { :subdomain => account.subdomain },
      :token_url => "/oauth/tokens", :authorize_url => "/oauth/authorizations/new")
  end

  def client_secret
    ENV["CLIENT_SECRET"]
  end

  def api_client(token)
    ZendeskAPI::Client.new do |config|
      config.url = (settings.zendesk_uri % { :subdomain => account.subdomain }) + "/api/v2"
      config.allow_http = settings.development?
      config.access_token = token
      config.logger = logger
    end
  end

  def create_or_update_person_from_token!(token)
    api = api_client(token)
    user = api.current_user

    if user.id
      create_or_update_person!(:name => user.name,
        :email => user.email, :user_id => user.id)

      api.oauth_tokens.all! do |t|
        if token.start_with?(t.token)
          t.destroy!
          break
        end
      end
    end
  end

  def create_or_update_person!(attrs = {})
    person = nil

    if attrs[:user_id]
      person = Person.first(:user_id => attrs[:user_id])
    end

    person ||= Person.new

    person.attributes = attrs
    person.account = account
    person.save

    session[:user_id] = person.id
  end

  def person
    @person ||= account.people.get(session[:user_id])
  end

  def logged_in?
    !!(account && person)
  end

  def messages
    @messages ||= account.messages.all(:limit => settings.max_messages, :order => [:created_at.desc])
  end

  def account
    @account ||= if params[:subdomain]
      Account.first_or_create(:subdomain => params[:subdomain])
    end
  end

  def current_channel
    "/messages/#{account.subdomain}"
  end
end
