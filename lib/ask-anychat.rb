# frozen_string_literal: true

require_relative "ask/anychat/version"
require_relative "ask/anychat/context"
require_relative "ask/anychat/errors"
require_relative "ask/anychat/client"

module Ask
  # Anychat: an agent for a business — a page, a chat, and the words it answers
  # with — and the client that creates and manages one.
  module AnyChat
    # A client for the Anychat API.
    #
    #   Ask::AnyChat.client(token: ENV["ANYCHAT_TOKEN"])
    #
    # The base URL defaults to the hosted app, and the token is resolved through
    # ask-auth (ANYCHAT_TOKEN, then the credentials file, then Rails
    # credentials, then the database), so most callers pass one of the two —
    # often neither.
    def self.client(base_url: nil, token: nil, **options)
      Client.new(
        base_url: base_url || ENV["ANYCHAT_BASE_URL"] || DOMAIN_URL,
        token: token || Auth.resolve(AUTH_NAME),
        **options
      )
    end
  end
end
