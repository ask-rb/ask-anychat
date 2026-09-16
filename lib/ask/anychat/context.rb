# frozen_string_literal: true

module Ask
  module AnyChat
    # What this is, for a model deciding whether to reach for it.
    DESCRIPTION = "Anychat gives a business an agent of its own — a page customers " \
                  "can visit, a chat they can talk to, and the words it answers with. " \
                  "This client creates and manages those agents."

    DOMAIN_URL = "https://anywaye.com"
    DOCS_URL = "https://anywaye.com/docs/api"

    # ask-auth resolves this name in order: ANYCHAT_TOKEN in the environment,
    # the credentials file, Rails credentials, then the database.
    AUTH_NAME = :anychat_token
    AUTH_HOW = "Mint a token in Anychat under Settings → API tokens, then set it as " \
               "ANYCHAT_TOKEN, or pass token: to Ask::AnyChat.client."

    API_VERSION = "v1"

    QUICK_START = <<~RUBY
      client = Ask::AnyChat.client(token: ENV["ANYCHAT_TOKEN"])

      client.workspace_agents("anywaye")             # every agent a workspace owns
      client.workspace_agent("anywaye", "support")   # one, by the address it answers on
      client.create_workspace_agent("anywaye", display_name: "Support")
      client.update_workspace_agent("anywaye", "support", display_name: "Help desk")
      client.destroy_workspace_agent("anywaye", "support")
    RUBY
  end
end
