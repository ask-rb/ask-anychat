# frozen_string_literal: true

require_relative "test_helper"

# The client, against a stubbed API rather than a live one. What matters is the
# shape of the request it sends and what it makes of the answer; the HTTP
# underneath is Faraday's business, not this gem's.
class ClientTest < Minitest::Test
  BASE_URL = "https://anywaye.test"
  AGENTS = "/api/v1/workspaces/anywaye/agents"

  def setup
    Ask::Auth.reset_configuration!
  end

  # The connection is swapped rather than injected, the same way the other
  # clients in this ecosystem are tested: a test seam nobody pays for in
  # production. It is built with the client's own headers, so a header the
  # client stops sending is a test that fails.
  def client_with(stubs)
    client = Ask::AnyChat::Client.new(base_url: BASE_URL, token: "tok_test")
    client.instance_variable_set(:@connection, connection_for(stubs, headers: client.default_headers))
    client
  end

  def connection_for(stubs, headers: {})
    Faraday.new(url: BASE_URL, headers: headers) do |builder|
      builder.request :json
      builder.response :json, content_type: /\bjson$/
      builder.adapter :test, stubs
    end
  end

  def stub_json(stubs, method, path, status, body)
    stubs.public_send(method, path) { [status, { "Content-Type" => "application/json" }, body.to_json] }
  end

  # -- reading ------------------------------------------------------------

  def test_lists_the_agents_a_workspace_owns
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :get, AGENTS, 200, { agents: [{ handle: "support", display_name: "Support" }] })

    agents = client_with(stubs).workspace_agents("anywaye")

    assert_equal 1, agents.length
    assert_equal "support", agents.first["handle"]
  end

  def test_reads_one_agent_by_its_address
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :get, "#{AGENTS}/support", 200, { agent: { handle: "support" } })

    assert_equal "support", client_with(stubs).workspace_agent("anywaye", "support")["handle"]
  end

  # -- writing ------------------------------------------------------------

  def test_creating_sends_the_attributes_under_an_agent_key
    stubs = Faraday::Adapter::Test::Stubs.new
    sent = nil
    stubs.post(AGENTS) do |env|
      sent = JSON.parse(env.request_body)
      [201, { "Content-Type" => "application/json" }, { agent: { handle: "support" } }.to_json]
    end

    agent = client_with(stubs).create_workspace_agent("anywaye", display_name: "Support")

    assert_equal({ "agent" => { "display_name" => "Support" } }, sent)
    assert_equal "support", agent["handle"]
  end

  def test_updating_sends_only_what_it_was_given
    stubs = Faraday::Adapter::Test::Stubs.new
    sent = nil
    stubs.patch("#{AGENTS}/support") do |env|
      sent = JSON.parse(env.request_body)
      [200, { "Content-Type" => "application/json" }, { agent: { handle: "support" } }.to_json]
    end

    client_with(stubs).update_workspace_agent("anywaye", "support", display_name: "Help desk")

    assert_equal({ "agent" => { "display_name" => "Help desk" } }, sent)
  end

  # Nothing comes back but the fact that it worked: a 204 has no body to read,
  # and a failure raises rather than answering.
  def test_destroying_an_agent_asks_for_it_to_be_gone
    stubs = Faraday::Adapter::Test::Stubs.new
    asked = false
    stubs.delete("#{AGENTS}/support") do
      asked = true
      [204, {}, ""]
    end

    client_with(stubs).destroy_workspace_agent("anywaye", "support")

    assert asked, "the delete was never sent"
  end

  # -- what travels on the wire -------------------------------------------

  def test_the_token_travels_as_a_bearer_authorization
    stubs = Faraday::Adapter::Test::Stubs.new
    sent = nil
    stubs.get(AGENTS) do |env|
      sent = env.request_headers["Authorization"]
      [200, { "Content-Type" => "application/json" }, { agents: [] }.to_json]
    end

    client_with(stubs).workspace_agents("anywaye")

    assert_equal "Bearer tok_test", sent
  end

  def test_the_client_asks_for_json
    stubs = Faraday::Adapter::Test::Stubs.new
    sent = nil
    stubs.get(AGENTS) do |env|
      sent = env.request_headers["Accept"]
      [200, { "Content-Type" => "application/json" }, { agents: [] }.to_json]
    end

    client_with(stubs).workspace_agents("anywaye")

    assert_equal "application/json", sent
  end

  # A workspace name and an address are segments of a path, so anything that is
  # not one has to be escaped rather than pasted in.
  def test_a_workspace_and_handle_are_escaped_for_the_path
    stubs = Faraday::Adapter::Test::Stubs.new
    asked = nil
    stubs.get("/api/v1/workspaces/two%20words/agents/a%2Fb") do |env|
      asked = env.url.path
      [200, { "Content-Type" => "application/json" }, { agent: {} }.to_json]
    end

    client_with(stubs).workspace_agent("two words", "a/b")

    assert_equal "/api/v1/workspaces/two%20words/agents/a%2Fb", asked
  end

  # -- what it makes of a refusal -----------------------------------------

  def test_a_refused_name_raises_with_the_sentence_the_api_gave
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :post, AGENTS, 422, { error: "An agent needs a name." })

    error = assert_raises(Ask::AnyChat::Error::Invalid) do
      client_with(stubs).create_workspace_agent("anywaye", display_name: "")
    end

    assert_equal "An agent needs a name.", error.message
  end

  def test_an_unknown_address_is_not_found
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :get, "#{AGENTS}/nope", 404, { error: "No agent at /anywaye/nope." })

    error = assert_raises(Ask::AnyChat::Error::NotFound) do
      client_with(stubs).workspace_agent("anywaye", "nope")
    end

    assert_equal "No agent at /anywaye/nope.", error.message
  end

  def test_a_refused_token_is_unauthorized
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :get, AGENTS, 401, {})

    assert_raises(Ask::AnyChat::Error::Unauthorized) { client_with(stubs).workspace_agents("anywaye") }
  end

  def test_a_server_failure_is_an_api_error
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :get, AGENTS, 500, { error: "Something went wrong." })

    error = assert_raises(Ask::AnyChat::Error::Api) do
      client_with(stubs).workspace_agents("anywaye")
    end

    assert_includes error.message, "500"
  end

  # A real connection failure, not the test adapter's own "nothing stubbed"
  # complaint — otherwise this would be testing the stub.
  def test_an_unreachable_api_says_so
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.get(AGENTS) { raise Faraday::ConnectionFailed, "connection refused" }

    error = assert_raises(Ask::AnyChat::Error::Unreachable) do
      client_with(stubs).workspace_agents("anywaye")
    end

    assert_includes error.message, "could not be reached"
  end

  # Everything raised is rescuable as one thing, so a caller can guard the
  # library rather than a list of its moods.
  def test_every_failure_is_an_anychat_error
    stubs = Faraday::Adapter::Test::Stubs.new
    stub_json(stubs, :get, AGENTS, 404, { error: "nope" })

    assert_raises(Ask::AnyChat::Error) { client_with(stubs).workspace_agents("anywaye") }
  end

  # -- how the client is built --------------------------------------------

  def test_the_client_is_built_from_the_token_ask_auth_resolves
    Ask::Auth.configure do |config|
      config.providers = [->(name, **) { "tok_resolved" if name.to_s == "anychat_token" }]
    end

    stubs = Faraday::Adapter::Test::Stubs.new
    sent = nil
    stubs.get(AGENTS) do |env|
      sent = env.request_headers["Authorization"]
      [200, { "Content-Type" => "application/json" }, { agents: [] }.to_json]
    end

    client = Ask::AnyChat.client
    client.instance_variable_set(:@connection, connection_for(stubs, headers: client.default_headers))
    client.workspace_agents("anywaye")

    assert_equal "Bearer tok_resolved", sent
    assert_equal "https://anywaye.com", client.base_url
  end

  def test_a_trailing_slash_on_the_base_url_is_not_doubled
    client = Ask::AnyChat::Client.new(base_url: "https://anywaye.test/", token: "t")

    assert_equal "https://anywaye.test", client.base_url
  end
end
