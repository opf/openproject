# OpenProject AI Assistance (browser extension)

A browser extension for Firefox and Chrome. It adds an **AI Assistance** button to the work
packages of an OpenProject instance. The instance does not need a server change.

The extension runs every skill in the browser:

- It reads the work package through API v3, as the signed-in user.
- It lets the model call the read-only tools of OpenProject's MCP server.
- It applies a proposal through API v3 only when the user clicks **Apply changes**.

The model sees only what the user can see in OpenProject.

## For users

1. Open your OpenProject instance.
2. Click the extension icon, then click **Enable on _your host_**. The browser asks for access
   to this host only.
3. The extension opens **My account → AI Assistance**. Enter your LLM provider, API key and
   model, then click **Save**.
4. Open a work package. Click **AI Assistance** in the toolbar, and choose a skill.

### Sign-in

- **Browser session** (default): the extension uses your sign-in in this browser. You do not
  need to set anything up.
- **API token**: create a token at **My account → Access tokens → API** and paste it into the
  settings. Use this mode when the session mode does not work on your instance. An
  administrator can switch API tokens off.

### What an administrator must do

The MCP server is off by default. An administrator must enable it one time at
**Administration → MCP server**. Without the MCP server, the skills still work, but the model
sees only the work package and cannot search for other data.

### Privacy

- The API key, the settings and the chats stay in the browser storage of the extension.
- The extension sends the work package context and the tool results to the LLM provider that
  you choose, and to nothing else.
- Applied changes show in the activity as your own changes.

## How it works

```
content script (on the granted OpenProject host)
  └─ inserts the button, opens an <iframe> with chat.html
       └─ chat.html (extension page)
            ├─ OpenProject requests ─▶ content script ─▶ API v3 and /mcp (same origin, session cookie)
            │                         or directly with an API token
            ├─ model loop ─▶ Anthropic Messages API, or an OpenAI-compatible server
            └─ apply ─▶ PATCH /api/v3/work_packages/:id, POST …/activities
```

In session mode, OpenProject accepts a write request with a session cookie only when the
browser marks it as same-origin (`Sec-Fetch-Site`). That includes every `POST /mcp`. Requests
from an extension page are never same-origin, so the content script sends them for the page.
The proxy allows only `/api/v3/…` and `/mcp`.

The core (`src/core`) is a port of the AI Assistance proof of concept in the `llm` module:

| File | Ported from |
| --- | --- |
| `outputRules.ts` | `modules/llm/app/services/ai/assistance/output_rules.rb` |
| `answerFormat.ts` | `answer_format.rb`, `proposal_builder.rb` |
| `changeOptions.ts` | `change_options.rb` |
| `toolCalls.ts` | `tool_calls.rb` |
| `contentGuard.ts` | `content_guard.rb` |
| `reply.ts` | `modules/llm/app/services/ai/assistant_chats/reply.rb` |

Differences from the proof of concept:

- The answer comes through a `submit_answer` tool with a strict schema. Current Claude models
  reject a forced `tool_choice` and sampling parameters, so the prompt steers the model to
  the tool.
- The context has no meetings and no pull requests, because API v3 does not give them per
  work package.
- The journal does not name the assistant. API v3 has no journal cause.
- There are no group assistants and no skill conditions.

## Not verified yet

Nothing in this package has run against a live OpenProject instance. These parts need the
end-to-end check below before the extension is used:

- Session sign-in through the content script (the same-origin check of OpenProject).
- The `moz-extension://` and `chrome-extension://` iframe on a page whose CSP sets
  `frame-src 'self'` (`config/initializers/content_security_policy.rb`).
- The response shapes of the work package form, the activities and the relations.
- The toolbar selectors (`#action-show-more-dropdown-menu`, `.work-packages--details-toolbar`)
  and the My account menu (`#menu-sidebar ul.menu_root`).
- The `readOnlyHint` annotation in the MCP tool list.

## Development

The package needs Node 24.

```bash
npm ci
npm run lint
npm run typecheck
npm test
npm run build            # writes dist/firefox and dist/chrome
npm run lint:firefox     # web-ext lint on dist/firefox
npx playwright install chromium
npm run test:smoke       # loads dist/chrome in Chromium
```

To try the extension:

- Firefox: `npm run run:firefox`, or load `dist/firefox/manifest.json` at `about:debugging`.
- Chrome: load `dist/chrome` as an unpacked extension at `chrome://extensions`.

### Packaging

- Firefox: `npm run package:firefox` writes a zip to `artifacts/`. Sign it with
  `web-ext sign --channel unlisted` and your AMO API credentials.
- Chrome: zip `dist/chrome` and upload it as an unlisted item to the Chrome Web Store, or
  install it through the `ExtensionInstallForcelist` enterprise policy.
