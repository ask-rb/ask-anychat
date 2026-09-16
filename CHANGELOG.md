## [0.1.0] - 2026-09-17

### Added

- **The Anychat API client** — `Ask::AnyChat.client` resolves its base URL from
  the hosted app and its token through ask-auth (`ANYCHAT_TOKEN`, then the
  credentials file, then Rails credentials, then the database), so most callers
  pass neither.

- **Workspace agent CRUD** — `workspace_agents`, `workspace_agent`,
  `create_workspace_agent`, `update_workspace_agent` and
  `destroy_workspace_agent`, addressing an agent by the address it answers on.
  Creating takes a name and derives the address from it, handing a taken one the
  first free variant rather than failing.

- **Errors under one parent** — `Ask::AnyChat::Error` with `Unauthorized`,
  `NotFound`, `Invalid`, `Api` and `Unreachable` beneath it, each carrying the
  sentence the API answered with. A workspace the token cannot see is reported
  as not found rather than forbidden, which is the API's answer as well.

- **A bundled skill** — `anychat.use_anychat`, so a model that has the gem also
  has the instructions for using it.
