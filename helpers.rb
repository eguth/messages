require "oauth2"
require "zendesk_api"
require "nokogiri"

module Helpers
  def alert
    if session[:alert]
      alert_for_type("alert", session.delete(:alert))
    elsif session[:success]
      alert_for_type("alert alert-success", session.delete(:success))
    elsif session[:error]
      alert_for_type("alert alert-error", session.delete(:error))
    elsif session[:info]
      alert_for_type("alert alert-info", session.delete(:info))
    end
  end

  def alert_for_type(type, message)
    <<-EOF
    <div class="#{type}">
      <button type="button" class="close" data-dismiss="alert">&times;</button>
      #{message}
    </div>
    EOF
  end

  def client
    @client ||= OAuth2::Client.new('messages', client_secret, site: settings.zendesk_uri % { subdomain: account.subdomain },
      token_url: "/oauth/tokens", authorize_url: "/oauth/authorizations/new")
  end

  def client_secret
    ENV["CLIENT_SECRET"]
  end

  def api_client(token)
    ZendeskAPI::Client.new do |config|
      config.url = (settings.zendesk_uri % { subdomain: account.subdomain }) + "/api/v2"
      config.allow_http = settings.development?
      config.access_token = token
      config.logger = logger
    end
  end

  def create_or_update_person_from_token!(token)
    api = api_client(token)
    user = api.current_user

    if user.id
      create_or_update_person!(name: user.name,
        email: user.email, user_id: user.id)

      current_token = api.oauth_tokens.find!(id: "current")
      current_token.destroy!
    end
  end

  def create_or_update_person!(attrs = {})
    person = nil

    if attrs[:user_id]
      person = Person.first(user_id: attrs[:user_id])
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
    @messages ||= account.messages.all(limit: settings.max_messages, order: [:created_at.desc], parent_id: nil)
  end

  def most_liked
    @most_liked ||= account.messages.all(limit: 5, order: [:likes.desc])
  end

  def account
    @account ||= if params[:subdomain]
      Account.first_or_create(subdomain: params[:subdomain])
    end
  end

  def markdown
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML,
      no_intra_emphasis: true,
      disable_indented_code_blocks: true,
      fenced_code_blocks: true,
      strikethrough: true,
      highlight: true,
      space_after_headers: true)
  end

  def current_channel
    "/messages/#{account.subdomain}"
  end

  def strip_and_truncate(body)
    Nokogiri::HTML(body).xpath("//text()").remove.to_s[0..10]
  end

  def markdown_examples
    [
      "*italic*",
      "**bold**",
      "An [example link](http://www.google.com)",
      "![alt text](https://support.zendesk.com/favicon.ico \"Title\")",
      "Header 1\n======",
      "Header 2\n--------",
      "1. Item\n2. Another Item",
      "* Bullet\n* Another Bullet",
      "> Nested\n> quote",
      "Hello  \nNew line",
      "This is ~~terrible~~ awesome!"
    ]
  end
end
