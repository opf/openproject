# OpenProject Test Management (PoC)

Local proof-of-concept module. Not intended for upstream contribution.

Test cases in folders, test runs with iterations, milestones, automated results from CI
(GitHub, GitLab, Gitea, Forgejo, Codeberg, Jenkins, Woodpecker – cloud or self-hosted), "Run in CI",
an AI Test Assistant and keyboard shortcuts.

## Documentation

The user guide is in [`docs/`](docs/README.md):

- [Overview](docs/README.md) – concepts, navigation, permissions
- [Test cases](docs/cases.md) – folders, cases, labels, the work package *Testing* tab
- [Test runs](docs/runs.md) – case selection, results, iterations
- [Milestones](docs/milestones.md)
- [Test Assistant 🪄](docs/assistant/README.md) and the [AI providers reference](docs/assistant/ai-providers.md)
- [CI and automation](docs/ci/README.md) – uploads, CI connections, Run in CI, self-hosted Git, repo-qualified references
- [API](docs/api.md)
- [Keyboard shortcuts](docs/hotkeys/README.md)
- [Settings](docs/settings.md) – project settings and administration

The APIv3 endpoints are described in `docs/api/apiv3` (tag *Test Management*).

## Enable

1. Ensure the gem is listed in `Gemfile.modules`.
2. `bundle install && rake db:migrate`
3. Project → Settings → Modules → enable **Test management**.

Registration (permissions, menus, settings, hooks): `lib/open_project/test_management/engine.rb`.

## Developer notes

- **Menu**: one project menu child with a partial (like Documents and Meetings). The section list is
  `TestManagement::Menu` (a core `Submenu`), loaded lazily from `…/test_management/menu`; every
  project-level controller uses `menu_item :test_management`. CI remains a placeholder section;
  Requirements and Reports are not in the nav (not part of this PoC cut). Old URLs redirect (301):
  `placeholders/generate` and `placeholders/chat` to the Test Assistant tabs,
  `placeholders/executions` to the Runs list (a run is the execution entity; re-executions are
  iterations).
- **Work package *Testing* tab**: an Angular tab (`frontend/module/main.ts`), displayable when the
  APIv3 work package has `_links.testing`; the split view uses the `:work_package_split_view` menu
  entry. Content: `GET /work_packages/:id/test_management/tab` (Turbo frame) and `…/tab/count`. The
  Angular part is compiled into the core frontend: after changing it run
  `bin/rails openproject:plugins:register_frontend` and rebuild or restart the frontend.
- Everything else is server-rendered (Turbo, core Stimulus controllers, one nonced inline script
  for the shortcuts) and needs **no frontend rebuild**.
- **Test Assistant**: background jobs `GenerateJob` and `ChatJob`; provider presets in
  `TestManagement::Assistant::AI::Provider`, settings in `ProviderConfig`
  (`Setting.plugin_openproject_test_management`, key encrypted).
- **Outgoing requests** (CI servers, AI providers) go through `OpenProject.httpx` with SSRF
  protection; private addresses need `OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST`.
