require_relative 'helper'

describe "Messages" do
  describe "a GET to /" do
    before do
      get "/"
    end

    it "should respond ok" do
      assert last_response.ok?
    end
  end

  describe "a GET to /:account/login" do
    describe "when logged in" do
      before do
        get "/support/login", {}, "rack.session" => { "user_id" => user.id }
      end

      it "should redirect" do
        assert last_response.redirect?
        assert_match %r{/support$}, last_response.headers["Location"]
      end
    end

    describe "when not logged in" do
      before do
        get "/support/login"
      end

      it "should redirect" do
        assert last_response.redirect?
        assert_match %r{support\.zendesk\.com}, last_response.headers["Location"]
      end

      it "should set a csrf_token" do
        session = last_request.env["rack.session"]
        csrf = session[Rack::Csrf.key]

        assert csrf, "no csrf in #{session.inspect}"

        params = Rack::Utils.parse_query(last_response.headers["Location"].split("?").last)
        assert_equal csrf, CGI.unescape(params["state"].split("|").last)
      end

      it "should set the subdomain" do
        params = Rack::Utils.parse_query(last_response.headers["Location"].split("?").last)
        assert_equal "support", params["state"].split("|").first
      end
    end
  end

  describe "a GET to /oauth/authorize" do
    describe "with no state" do
      before { get "/oauth/authorize" }

      it "should 400" do
        assert_equal 400, last_response.status
      end

      it "should return error" do
        assert_equal "Invalid CSRF", last_response.body
      end
    end

    describe "with no account" do
      before do
        get "/oauth/authorize", { :state => "nope|test" },
          "rack.session" => { Rack::Csrf.key => "test" }
      end

      it "should create account" do
        assert Account.first(:subdomain => "nope")
      end
    end

    describe "with an error" do
      before { get "/oauth/authorize", :error => "err" }

      it "should 400" do
        assert_equal 400, last_response.status
      end

      it "should return error" do
        assert_equal "err", last_response.body
      end
    end

    describe "valid" do
      # TODO
    end
  end

  describe "a GET to /:account" do
    describe "when logged in" do
      before do
        get "/support", {}, "rack.session" => { "user_id" => user.id }
      end

      it "should have a text-box" do
        assert_match /textarea/, last_response.body
      end

      it "should respond ok" do
        assert last_response.ok?
      end
    end

    describe "when not logged in" do
      before do
        get "/support"
      end

      it "should respond ok" do
        assert last_response.ok?
      end

      it "should create an account" do
        assert Account.first(:subdomain => "support")
      end
    end
  end

  describe "a GET to /:account/logout" do
    describe "when logged in" do
      before do
        get "/support/logout", {}, "rack.session" => { "user_id" => 1 }
      end

      it "should redirect" do
        assert last_response.redirect?
        assert_match %r{/support$}, last_response.headers["Location"]
      end

      it "should remove user_id" do
        assert_nil last_request.env["rack.session"]["user_id"]
      end
    end

    describe "when not logged in" do
      before do
        get "/support/logout"
      end

      it "should redirect" do
        assert last_response.redirect?
        assert_match %r{/support$}, last_response.headers["Location"]
      end
    end
  end

  describe "a POST to /:account/message" do
    describe "when logged in - xhr" do
      before do
        client = stub
        client.expects(:publish).with(regexp_matches(/support/), regexp_matches(/hi/))

        post "/support/message", { :body => "hi" },
          "rack.session" => { "user_id" => user.id },
          "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest",
          "faye.client" => client
      end

      it "should create a message" do
        assert_equal "<p>hi</p>\n", user.messages.last.body
      end

      it "should be ok" do
        assert last_response.ok?
      end
    end

    describe "when logged in - normal" do
      before do
        post "/support/message", { :body => "hi" },
          "rack.session" => { "user_id" => user.id }
      end

      it "should create a message" do
        assert_equal "<p>hi</p>\n", user.messages.last.body
      end

      it "should be ok" do
        assert last_response.ok?
      end
    end

    describe "when not logged in" do
      before do
        post "/support/message"
      end

      it "should respond 401" do
        assert_equal 401, last_response.status
      end
    end
  end
end
