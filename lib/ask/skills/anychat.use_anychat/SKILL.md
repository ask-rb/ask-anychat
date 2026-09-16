---
name: anychat.use_anychat
description: Manage the agents an Anychat workspace owns — list them, bring a new one into being, rename or re-title one, or retire one. Use when a request concerns an Anychat agent's name, its address, or the set of agents a workspace has.
---

# Using Anychat

Anychat gives a business an agent of its own: a page customers can visit, a chat
they can talk to, and the words it answers with. This client creates and manages
those agents.

An agent in Anychat is a **workspace agent**. A workspace owns one or many, and
each answers on `/<workspace>/<handle>` — the link the owner prints. The system
templates every agent is cloned from are not what this reaches; only the agents a
workspace owns.

## Step 1: get the client

```ruby
client = Ask::AnyChat.client
```

The base URL defaults to the hosted app and the token is resolved through
ask-auth, so this usually needs no arguments. To point somewhere else:

```ruby
Ask::AnyChat.client(base_url: "https://staging.anywaye.com", token: ENV["STAGING_TOKEN"])
```

## Step 2: name the workspace

Every call names one, because a workspace is what a token reaches: the API
resolves it through the token's user, so a token sees only the workspaces its
user belongs to. Naming somebody else's workspace is the same answer as naming
one that does not exist — a `NotFound`, not a `Forbidden`.

```ruby
client.workspace_agents("anywaye")
```

## Step 3: read before you write

```ruby
client.workspace_agents("anywaye")             # every agent, oldest first
client.workspace_agent("anywaye", "support")   # one, by the address it answers on
```

Read first for two reasons: it tells you which addresses are already taken, and
it gives you the `handle` that `update` and `destroy` need. There is no lookup
by name — an agent is addressed by its address.

## Step 4: create

```ruby
client.create_workspace_agent("anywaye", display_name: "Support")
```

Only a name is required. The address is derived from it, and a taken one is not
a failure — the new agent is handed the first free variant (`support-2`,
`support-3`). Pass `handle:` to choose the address yourself when the owner has
one in mind.

`description:` and `public:` may be given too; everything else an agent shows
(branding, greeting, colour) is the owner's to edit afterwards.

## Step 5: change one

```ruby
client.update_workspace_agent("anywaye", "support", display_name: "Help desk")
client.update_workspace_agent("anywaye", "support", handle: "help")
```

Only the attributes you pass are written. Renaming the address is safe: the
handler allocates a free one if what you asked for is taken.

## Step 6: retire one

```ruby
client.destroy_workspace_agent("anywaye", "support")
```

The address goes with it and becomes free again. Conversations customers had
with it are kept — they are a record of what somebody was told — so a retired
agent still appears in that history.

## When it is refused

Every failure raises under `Ask::AnyChat::Error`, carrying the sentence the API
answered with, which is written to be read out:

| Raised | What it means |
| --- | --- |
| `Error::Unauthorized` | The token is missing, expired or refused |
| `Error::NotFound` | No such workspace, or no such agent in it |
| `Error::Invalid` | The request was understood and refused — the message says why |
| `Error::Api` | The API failed, or answered with something unexpected |
| `Error::Unreachable` | The API could not be reached at all |

```ruby
begin
  client.create_workspace_agent("anywaye", display_name: "")
rescue Ask::AnyChat::Error::Invalid => e
  e.message   # => "An agent needs a name."
end
```

A refusal is not something to retry. `Error::Unreachable` and `Error::Api` are.
