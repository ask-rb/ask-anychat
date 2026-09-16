# Ask::AnyChat

Anychat API client for the [ask-rb](https://github.com/ask-rb) ecosystem.

Anychat gives a business an agent of its own — a page customers can visit, a chat
they can talk to, and the words it answers with. This gem creates and manages the
agents a workspace owns.

This is the client layer only. Tool framing — MCP servers, native `Ask::Tools` —
is provided by the consumers.

## Installation

```ruby
gem "ask-anychat"
```

## Usage

```ruby
client = Ask::AnyChat.client

client.workspace_agents("anywaye")             # every agent a workspace owns
client.workspace_agent("anywaye", "support")   # one, by the address it answers on
client.create_workspace_agent("anywaye", display_name: "Support")
client.update_workspace_agent("anywaye", "support", display_name: "Help desk")
client.destroy_workspace_agent("anywaye", "support")
```

The base URL defaults to the hosted app and the token is resolved through
[ask-auth](https://github.com/ask-rb/ask-auth) — `ANYCHAT_TOKEN` in the
environment, then the credentials file, then Rails credentials, then the
database. Mint a token in Anychat under Settings → API tokens.

Point it somewhere else with `Ask::AnyChat.client(base_url:, token:)`.

An agent in Anychat is a **workspace agent**: the system templates every agent is
cloned from are not what this reaches, only the agents a workspace owns. An
address that belongs to a workspace the token cannot see is reported as not found
rather than forbidden — the same answer as one that does not exist.

### Failures

Everything raises under `Ask::AnyChat::Error`, carrying the sentence the API
answered with.

| Raised | What it means |
| --- | --- |
| `Error::Unauthorized` | The token is missing, expired or refused |
| `Error::NotFound` | No such workspace, or no such agent in it |
| `Error::Invalid` | The request was understood and refused — the message says why |
| `Error::Api` | The API failed, or answered with something unexpected |
| `Error::Unreachable` | The API could not be reached at all |

A refusal is not worth retrying; `Error::Unreachable` and `Error::Api` are.

## Contributing

Run `bin/setup` once, then `bundle exec rake test`.

## License

MIT.
