# frozen_string_literal: true

require_relative "test_helper"

# The context is what a model reads before it decides to reach for this gem, so
# what matters is that it is present, accurate and copy-pasteable.
class ContextTest < Minitest::Test
  def test_it_says_what_the_gem_is_for
    assert_includes Ask::AnyChat::DESCRIPTION, "agent"
  end

  def test_it_names_the_credential_ask_auth_resolves
    assert_equal :anychat_token, Ask::AnyChat::AUTH_NAME
  end

  def test_it_says_how_to_get_a_token
    assert_includes Ask::AnyChat::AUTH_HOW, "API tokens"
  end

  def test_the_quick_start_is_something_that_would_run
    assert_includes Ask::AnyChat::QUICK_START, "Ask::AnyChat.client"
    assert_includes Ask::AnyChat::QUICK_START, "create_workspace_agent"
  end

  # Every operation the quick start promises has to exist on the client, or the
  # first thing a model reads is the first thing that fails.
  def test_every_method_the_quick_start_names_is_on_the_client
    named = Ask::AnyChat::QUICK_START.scan(/client\.(\w+)/).flatten.uniq - ["client"]

    refute_empty named
    named.each do |method|
      assert_respond_to Ask::AnyChat::Client.new(base_url: "https://x.test", token: "t"), method
    end
  end
end
