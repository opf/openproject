# Test Assistant 🪄

[← User guide](../README.md)

Test management → **Test Assistant 🪄** (or <kbd>g</kbd> <kbd>t</kbd> <kbd>a</kbd>) is one page with two tabs,
**Generate** and **Chat**. While a generation runs, the draft page polls for progress in the
background and loads the results in place (no full-page reload). Chat still refreshes itself while
an answer is pending.

## Generate

- **Sources**:
  - a **work package**: subject, description, acceptance criteria (custom fields whose name
    contains "acceptance") and its children's subjects;
  - **free text**;
  - a **pull/merge request URL**: GitHub, GitLab, Gitea, Forgejo or Codeberg. It must belong to a
    repository of one of the project's CI connections, and is fetched with that connection's token
    through the SSRF-filtered HTTP client, with a 20 s timeout, a 2 MB response cap and a 40 000
    character diff cut. Self-hosted servers on a sub-path work
    (`https://example.com/gitlab/group/app/-/merge_requests/7`); GitLab older than 15.7 falls back to
    the `/changes` API. Not available for inbound-only connections;
  - a pasted **code snippet**.
- **Options**: number of cases (1–20), test types (positive, negative, edge, boundary, security,
  accessibility, usability), target folder and labels.
- The drafts appear as editable cards: title, type, priority, preconditions and steps. Only the
  selected drafts are saved, through the normal case creation (**Add test cases** is needed),
  as `draft` cases in one transaction. Saved cases link the source work package. A pull request
  source is kept as a note in the description.
- While drafts are written, a live banner shows stepped progress (queue → read source → ask AI →
  write drafts), a progress bar, and elapsed time. The AI step can take a minute; a heartbeat
  keeps the UI from looking stuck. You can **Cancel**; on failure or cancel, **Try again**
  re-queues the same request. If polling times out, **Check again** resumes it. Results load in
  a Turbo Frame when the job finishes.

- Generations are private to the user who started them.

## Chat

- Questions about the project's cases, runs, results, milestones and work package coverage. The
  model gets a compact project overview and read tools (`search_test_cases`, `summarize_failures`,
  `work_package_coverage`), which run server-side with the user's permissions.
- **Actions**: `create_test_run`, `create_milestone` and `create_test_cases` only produce a
  confirmation card (a preview plus any problems). Nothing is written until **Confirm**. Then the
  existing services run as the current user, so permissions are checked again. Confirm runs once;
  **Cancel** discards the proposal.
- History is per user and per project (the last 50 messages are shown). **Clear** deletes it.

## AI provider

Administrators save one or more providers in Administration → Test management → **Test Assistant –
AI providers**: see [Settings](../settings.md#test-assistant--ai-providers) and the
[AI providers reference](ai-providers.md). Without a provider, administrators see a notice with a
link to the settings and other users see the assistant as unavailable; there is no silent mock.

- **Picker** (0021): next to the Generate | Chat switch, a menu shows the provider and model in use,
  e.g. "✨ OpenAI · gpt-4o-mini ▾". It lists every saved provider with its default model and the
  models the administrator allowed users to pick. The choice is stored per user (all projects);
  until a user picks, the default provider is used. Users see names and models only, never URLs
  or keys. A provider that is incomplete is shown but cannot be picked.
- Administrators also get **Add new provider…**, which opens the provider form and comes back to
  the assistant with the new provider picked. Other users see "Ask an administrator to add
  providers" (disabled).
- Generations and chat messages remember the provider and model (`provider_id`, `chosen_model`)
  when they are sent; the background job uses them even if the user picks another provider
  meanwhile. A generation shows "Provider · model". Deleting a provider keeps that label.
  Completed generations also store the provider's token `usage` from that request.

- Requests run as background jobs. Draft generations poll a status endpoint while pending; chat
  still uses a short page refresh. Requests still pending after 10 minutes are shown as failed.
- **Prompt hygiene**: project data, work packages, pull requests and code are sent as untrusted
  data inside random-nonce markers, and the model is told never to follow instructions found in
  them. Model output is plain text, and writes always need a confirmation.

## Permissions and switch

- **Use test assistant** (`use_test_assistant`) opens the page. Saving drafts and confirming
  actions also need the permission of the action itself (Add test cases, Manage test runs,
  Manage milestones).
- Project settings → Test management → **Enable the Test Assistant** (on by default).

## APIv3

- `POST /api/v3/projects/{id}/test_management/assistant/generations` returns 202 with the queued
  generation. The body takes `sourceType`, `source` (`workPackageId`, `text`, `url`, `code`,
  `language`), `count`, `types`, `suiteId` and `labels`.
- `GET /api/v3/test_management/assistant/generations/{id}` returns the generation and its drafts.
  Poll it until `status` is `done` or `failed`. You can only read your own generations. When
  `status` is `done`, `usage` holds the provider token counts (`promptTokens`,
  `completionTokens`, `totalTokens`, and `reasoningTokens` when the model reported them).
- `POST …/generations/{id}/save` returns 201 with `savedCaseIds` and `testCases`. The body is
  optional: edited `drafts`, `suiteId` and `labels`. It returns 409 while the generation is not
  done.
- `GET /api/v3/test_management/assistant/providers` (0021) lists the saved providers.
  Administrators get every property but the key (`apiKeySet`); users with **Use test assistant**
  in any project get `id`, `name`, `model`, `models`, `default`, `selected` and `selectedModel`;
  others get 403.
- Administrators only: `POST …/providers` (201), `PATCH …/providers/{id}` (omitted properties are
  kept), `DELETE …/providers/{id}` (204) and `POST …/providers/{id}/default`. The body of POST and PATCH takes
  `name`, `preset`, `baseUrl`, `authStyle`, `apiKey` (write-only), `removeApiKey`, `model`,
  `userModels`, `timeout`, `maxTokens`, `default` and `verifyModel`; errors and a failed model
  check answer 422. Like every APIv3 POST, `…/default` needs `Content-Type: application/json`
  although it has no body (otherwise 415).
