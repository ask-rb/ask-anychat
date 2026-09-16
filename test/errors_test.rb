# frozen_string_literal: true

require_relative "test_helper"

# Failures are for callers to tell apart and for agents to read, which means one
# parent to rescue and a sentence worth showing.
class ErrorsTest < Minitest::Test
  def test_every_error_shares_one_parent
    [
      Ask::AnyChat::Error::Unauthorized,
      Ask::AnyChat::Error::NotFound,
      Ask::AnyChat::Error::Invalid,
      Ask::AnyChat::Error::Api,
      Ask::AnyChat::Error::Unreachable
    ].each do |klass|
      assert_operator klass, :<, Ask::AnyChat::Error
      assert_operator klass, :<, StandardError
    end
  end

  def test_the_parent_is_itself_rescuable
    assert_operator Ask::AnyChat::Error, :<, StandardError
  end

  # Each one means something specific, so they cannot be each other.
  def test_they_are_distinct
    distinct = [
      Ask::AnyChat::Error::Unauthorized,
      Ask::AnyChat::Error::NotFound,
      Ask::AnyChat::Error::Invalid,
      Ask::AnyChat::Error::Api,
      Ask::AnyChat::Error::Unreachable
    ]

    assert_equal distinct.length, distinct.uniq.length
  end
end
