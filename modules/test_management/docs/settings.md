# Settings

[← User guide](README.md)

## Project settings → Test management

Needs **Manage test management** (the CI connections section needs **Manage test CI**).

| Setting | Effect |
|---|---|
| Display prefix | Prefix accepted in ID tags of automated tests (`XY` → `@XY-12`), in addition to the instance default and `TC`. The UI shows the numeric case ID. |
| Folder tree layout | **Split pane** in the page (default) or **sidebar** below the Test management submenu on the Cases pages |
| Enable milestones | On by default. Off hides milestone pages, selectors, API and the work package section; data is kept. |
| Enable test plans | On by default. Off hides plan pages and plan APIs; configurations and standalone runs stay available. |
| Enable the Test Assistant | On by default. Off hides the Test Assistant. |
| Labels | Create, rename, recolour and delete labels; renaming or recolouring updates every case |
| Configurations | Optional browser/OS/device groups and values, see [Configurations](configurations.md) |
| CI connections | Repositories / CI jobs of the project, see [CI and automation](ci/README.md) |

## Administration → Test management

| Setting | Effect |
|---|---|
| Default display prefix | ID tag prefix for all projects (default `TC`) |
| Keyboard shortcuts | *Enable Test management shortcuts* and *Show shortcut hints and tips*, see [Keyboard shortcuts](hotkeys/README.md#switching-them-off) |
| Test Assistant – AI provider | See below |

## Test Assistant – AI providers

Administration → **Test management** → **Test Assistant – AI providers**. Endpoints and sources per
provider: [AI providers reference](assistant/ai-providers.md).

### Saved providers (0021)

- The section lists every saved provider: name, preset, default model, the models users may pick,
  host and status (ready / incomplete, key stored or not). **Add provider**, **Edit**, **Delete**
  and **Make default** manage them. Exactly one provider is the default; the first one always is,
  and deleting the default makes the next one the default.
- Each provider has its own name (unique, shown to users), preset, base URL, authentication,
  encrypted key, default model, timeout and max tokens, plus **Models users may pick** (optional,
  one per line, at most 20). Users can only pick the default model or one of these.
- The provider saved before 0021 becomes the first provider and the default when migrating
  (`20261031190000_create_tm_assistant_providers`, named after its preset, *Default* for Custom);
  its key moves as it is (still encrypted) and the old setting is cleared. Rolling back writes the
  default provider back into the setting.
- **Check the model when saving** sends one short request ("Reply with OK.", at most 16 tokens)
  to the model and saves nothing if it fails. It is on by default for presets whose model list is
  a catalogue (OpenAI, Anthropic, Custom, Azure) and off for presets that list only the key's
  models.
- Users pick a provider and model in the Test Assistant header (see
  [Test Assistant](assistant/README.md#ai-provider)). The pick is stored per user; Generate and
  Chat record it on the generation or message, so a background job uses what the user saw.
- Not in 0021: limiting providers per project (every project with the assistant sees every
  provider).

### Provider form

- **Provider** presets: OpenAI, Anthropic Claude, OpenRouter, Ollama (local), xAI, Mistral,
  Azure OpenAI and **Custom (OpenAI-compatible)** (vLLM, LM Studio, LiteLLM, legacy Azure
  deployment URLs). A preset fills in the base URL and the authentication; the base URL stays
  editable (proxies, in-cluster Ollama). Settings saved before the presets existed count as *Custom*.
- Anthropic uses its **native Messages API** (`/messages`, `x-api-key`, `anthropic-version:
  2023-06-01`); its OpenAI compatibility layer is documented as not production-ready. All other
  presets use `/chat/completions`. Ollama gets no `tool_choice`; OpenAI and Azure get
  `max_completion_tokens`; a 400 about `temperature` is retried once without it.
- Form order: Provider, Base URL, Authentication (Custom only), API key, **Test connection**,
  Model, timeout (10–300 s), max tokens. The key is stored encrypted, write-only, never rendered.
- An empty key field keeps the stored key only for the **same provider and host**. After switching
  the provider (or a Custom/Azure host) the stored key is never reused: a provider that needs a key
  asks for a new one (save and Test connection are refused), one that needs none (Ollama, Custom
  without authentication) saves with the stored key removed. The form says so after the switch.
- **Test connection** checks the entered values (also unsaved; an empty key field uses the
  stored key for the same provider and host) against the provider's models endpoint (10 s timeout,
  SSRF protection) and turns Model into a select of the chat models (sorted; the current model stays selected), with
  "Other" + free text as fallback. It uses the most key-specific list each provider documents
  (OpenRouter `/models/user`, xAI `/language-models`, Mistral, Ollama). OpenAI, Anthropic and
  Custom only list a catalogue: the form then says "This provider lists all models; some may not
  be enabled for your key." – use **Check the model when saving**. Azure lists no deployments, so
  the test checks the key only. Table: [AI providers reference](assistant/ai-providers.md#key-scoped-model-lists-0021). Errors say whether the key, the network, the SSRF protection
  (with the allowlist variable and the resolved addresses) or a timeout is the problem.
  Administrators only.
- Without a provider, administrators see a notice with a link to the settings. Other users see the
  assistant as unavailable. There is no silent mock: errors name the provider host and model.
- A local endpoint (e.g. Ollama in the cluster) is a private address, so it has to be allowed in
  `OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST`.
