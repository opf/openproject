# AI providers reference

[← Test Assistant](README.md) · [Settings](../settings.md#test-assistant--ai-providers)

How each provider preset of the Test Assistant talks to its API. Sources are the providers'
official API docs (links per section), checked in October 2026. The module calls the endpoints
only through `OpenProject.httpx` (SSRF protection) and never logs or renders keys.

A stored API key is only reused while the provider and the host stay the same; see
[Settings](../settings.md#test-assistant--ai-providers).

| Preset | Base URL (default) | Chat endpoint | Auth header | Models endpoint | Chat-capable filter |
|---|---|---|---|---|---|
| OpenAI | `https://api.openai.com/v1` | `POST /chat/completions` | `Authorization: Bearer <key>` | `GET /models` | name heuristic (drop embedding, whisper, tts, dall-e, moderation, audio, realtime, transcribe, image, search, sora, computer-use, legacy davinci/babbage) |
| Anthropic Claude | `https://api.anthropic.com/v1` | `POST /messages` (native Messages API) | `x-api-key: <key>` + `anthropic-version: 2023-06-01` | `GET /models?limit=1000` (same headers; paginated `has_more`/`last_id`) | all listed models are chat models |
| OpenRouter | `https://openrouter.ai/api/v1` | `POST /chat/completions` | `Authorization: Bearer <key>` (+ optional `HTTP-Referer`, `X-Title`) | `GET /models/user` (the key's models); gateways without it: `GET /key` + public `GET /models` | `architecture.output_modalities` contains `text` (or `architecture.modality` ends in `->text`) |
| Ollama (local) | `http://localhost:11434/v1` (in-cluster e.g. `http://ollama.<ns>.svc:11434/v1`) | `POST /chat/completions` | none (a key is ignored locally; Ollama Cloud `https://ollama.com/v1` uses Bearer) | `GET /v1/models`, fallback native `GET /api/tags` | drop `*embed*` models |
| xAI | `https://api.x.ai/v1` | `POST /chat/completions` | `Authorization: Bearer <key>` | `GET /language-models` (the key's models, with modalities); fallback `GET /models` | `output_modalities` contains `text`; fallback: drop image / imagine / video models |
| Mistral | `https://api.mistral.ai/v1` | `POST /chat/completions` | `Authorization: Bearer <key>` | `GET /models` | `capabilities.completion_chat == true` and not `archived` |
| Azure OpenAI | `https://<resource>.openai.azure.com/openai/v1` (no api-version) | `POST /chat/completions` | `api-key: <key>` (Entra ID Bearer also works) | `GET /models` (lists base models, **not** deployments) | listing only proves the key; the model field is the **deployment name** (free text) |
| Custom (OpenAI-compatible) | entered | `POST {base}/chat/completions` | Bearer / `api-key` / none | `GET {base}/models` if the server has it | generic name heuristic |

## Key-scoped model lists (0021)

"Test connection" should offer only the models the entered key can use. Not every provider has
such a list; where only the catalogue exists the form shows "This provider lists all models; some
may not be enabled for your key." and **Check the model when saving** is on by default (one
request, "Reply with OK.", at most 16 tokens). Sources checked October 2026.

| Preset | Endpoint used | Limited to the key? | Hint shown | Source |
|---|---|---|---|---|
| OpenRouter | `GET /models/user`; 404 (gateway) → `GET /key` + `GET /models` | yes ("filtered by user provider preferences, privacy settings and guardrails"); the fallback is a catalogue | only on fallback | https://openrouter.ai/docs/api/api-reference/models/list-models-filtered-by-user-provider-preferences-privacy-settings-and-guardrails |
| xAI | `GET /language-models` (text output); 404 → `GET /models` | yes ("available to the authenticating API key") | no | https://docs.x.ai/developers/rest-api-reference/inference/models |
| Mistral | `GET /models` (`completion_chat`, not `archived`) | yes ("models available to the user", incl. fine-tunes) | no | https://docs.mistral.ai/api/endpoint/models |
| Ollama | `GET /v1/models`; fallback `GET /api/tags` | yes (models pulled on that server) | no | https://docs.ollama.com/api/tags |
| OpenAI | `GET /models` | no: lists the organization's models; a project's model allowlist is not reflected | yes | https://platform.openai.com/docs/api-reference/models/list, https://help.openai.com/en/articles/9186755 |
| Anthropic | `GET /models?limit=1000` | no: catalogue of the organisation/workspace | yes | https://platform.claude.com/docs/en/api/models/list |
| Azure OpenAI | none (key check via `/openai/v1/models`, base models) | n/a: deployments are listed only by the management API (Entra ID) | "checks the key only" | https://learn.microsoft.com/en-us/rest/api/cognitiveservices/accountmanagement/deployments/list |
| Custom | `GET {base}/models` | unknown (depends on the server) | yes | – |

The preset says which applies (`models_scope`: `key`, `catalogue`, `none`); the API exposes it to
administrators as `modelsScope`.

## Per provider

### OpenAI
* Docs: https://platform.openai.com/docs/api-reference/chat/create, https://platform.openai.com/docs/api-reference/models/list
* `GET /v1/models` returns every model of the organization (embeddings, audio, image, moderation…)
  without a capability field, so the PoC filters by name.
* Newer reasoning models reject `max_tokens` in favor of `max_completion_tokens` and only accept the
  default temperature. The preset sends `max_completion_tokens`; the client retries once without
  `temperature` when a 400 names that parameter (applies to every OpenAI-style preset).

### Anthropic Claude – decision: native Messages API
* Docs: https://docs.claude.com/en/api/messages, https://docs.claude.com/en/api/models-list,
  https://docs.claude.com/en/api/openai-sdk (compatibility layer), https://docs.claude.com/en/api/versioning
* Anthropic's OpenAI SDK compatibility endpoint (`https://api.anthropic.com/v1/chat/completions`) is
  documented as a way to *test/compare*, "not considered a long-term or production-ready
  solution"; `strict` is ignored, low temperatures are rejected by newer models and some
  `tool_choice` values return 400.
* **Chosen: the native Messages API** (robust, fully supported, tool use is first class):
  * `system` messages → top-level `system` string;
  * OpenAI tools `{type:function,function:{name,description,parameters}}` → `{name, description, input_schema}`;
  * assistant `tool_calls` → `tool_use` content blocks (`id`, `name`, `input`);
  * `role: tool` messages → `user` message with `tool_result` blocks (consecutive results merged into one user turn, as required);
  * empty text blocks are dropped (the API rejects them);
  * response `content[]` → text blocks joined + `tool_use` blocks as tool calls, `stop_reason` as finish reason;
  * `max_tokens` is required (always sent); **no `temperature`** (newer models reject non-default values);
  * header `anthropic-version: 2023-06-01` (the stable, still-supported version).
* Models: `GET /v1/models?limit=1000` (max 1000 per page, default 20) → `data[].id` (+ `display_name`).

### OpenRouter
* Docs: https://openrouter.ai/docs/api-reference/overview, https://openrouter.ai/docs/api-reference/list-available-models,
  https://openrouter.ai/docs/api-reference/get-current-api-key
* "Test connection" calls `GET /api/v1/models/user` with the key (0021): only the models the
  key may use under its provider preferences, privacy settings and guardrails. Servers without it
  (404, e.g. a proxy) fall back to `GET /api/v1/key` (401 for a wrong key) and the public
  `GET /api/v1/models`. Optional attribution headers `HTTP-Referer`/`X-Title`;
  the preset sends `X-Title: OpenProject Test Management`.
* Model ids are `vendor/model` (e.g. `openai/gpt-4o-mini`). Filter: text output modality.

### Ollama
* Docs: https://docs.ollama.com/api/openai-compatibility, https://docs.ollama.com/api/tags
* OpenAI-compatible endpoints under `/v1`; the key is required by OpenAI clients but ignored
  locally. Ollama Cloud (`https://ollama.com/v1`) takes a Bearer key → the preset sends Bearer
  only when a key is entered.
* `tool_choice` is not supported → the preset omits it (tools are still sent).
* A base URL without a path (`http://ollama:11434`) is normalized to `…/v1`.
* Models: `/v1/models`; fallback to native `/api/tags` (`models[].name`) for older builds.
* Local and in-cluster addresses are private: allow them with
  `OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST` (the test shows the resolved addresses).

### xAI
* Docs: https://docs.x.ai/docs/api-reference#chat-completions, https://docs.x.ai/docs/api-reference#list-models
* `/v1/chat/completions` is OpenAI compatible (the Responses API is xAI's primary API but chat
  completions remain supported). "Test connection" uses `GET /v1/language-models` (0021): the
  language models available to the key, with `output_modalities` (text output kept). Without it
  `GET /v1/models` lists ids; image/video generation models are filtered out by name.

### Mistral
* Docs: https://docs.mistral.ai/api/#tag/chat, https://docs.mistral.ai/api/#tag/models
* `GET /v1/models` returns `capabilities.completion_chat`, `capabilities.function_calling` and
  `archived` per model → only chat-capable, non-archived models are offered (aliases deduplicated).

### Azure OpenAI
* Docs: https://learn.microsoft.com/azure/ai-foundry/openai/api-version-lifecycle (v1 API),
  https://learn.microsoft.com/azure/ai-foundry/openai/reference
* The v1 API (`https://<resource>.openai.azure.com/openai/v1/`, also `services.ai.azure.com`)
  needs no `api-version`; auth with the `api-key` header. `model` in the request body is the
  **deployment name**. `GET /openai/v1/models` lists the base models available to the resource,
  not the deployments – so the test verifies the key and the Model field stays free text.
* Legacy deployment URLs (`…/openai/deployments/<d>?api-version=…`) still work via **Custom**
  with authentication "api-key header".

## Implementation notes
* Naming (AI acronym): OpenProject's Zeitwerk inflector maps only the *whole* basename `ai` to
  `AI` (config/initializers/zeitwerk.rb); `ai_provider.rb` would have to define `AiProvider`.
  Core therefore puts AI classes in an `ai/` directory (`app/models/ai/text_transform_action.rb`
  → `AI::TextTransformAction`). The module follows that: `assistant/ai/provider.rb` →
  `TestManagement::Assistant::AI::Provider` (presets) and `assistant/ai/connection_test.rb` →
  `TestManagement::Assistant::AI::ConnectionTest`.
* Models URL = base URL + `/models` (query string preserved); chat URL = base + `/chat/completions`
  (OpenAI style) or base + `/messages` (Anthropic).
* "Test connection" timeout: 10 s (connect 5 s); response cap 5 MB (OpenRouter's list is large).
