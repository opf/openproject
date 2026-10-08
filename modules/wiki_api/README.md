# OpenProject Wiki API

Extends OpenProject's API v3 with full REST endpoints for the built-in
wiki (project listing, hierarchy tree, create/update/delete, revision
history, `lock`/`unlock`, `move`/`copy` and PostgreSQL full-text search).

The endpoints reuse the core `WikiPages::CreateService`,
`WikiPages::UpdateService` and `WikiPages::CopyService` together with
their `CreateContract`, `UpdateContract` and `CopyContract`. Authorization
is delegated to the existing core permissions — no new permissions are
introduced.

## Endpoints

Authentication uses the regular OpenProject API key
(`Authorization: Basic apikey:<TOKEN>`).

### Project-scoped

| Method | URL                                                        | Description                    | Permission          |
|--------|------------------------------------------------------------|--------------------------------|---------------------|
| GET    | `/api/v3/projects/:project_id/wiki_pages`                  | Paginated list                 | `view_wiki_pages`   |
| POST   | `/api/v3/projects/:project_id/wiki_pages`                  | Create a page                  | `edit_wiki_pages`   |
| GET    | `/api/v3/projects/:project_id/wiki_pages/tree`             | Hierarchical page tree         | `view_wiki_pages`   |
| GET    | `/api/v3/projects/:project_id/wiki_pages/search?q=<term>`  | PostgreSQL full-text search    | `view_wiki_pages`   |

### Per-page

| Method | URL                                                       | Description                | Permission          |
|--------|-----------------------------------------------------------|----------------------------|---------------------|
| GET    | `/api/v3/wiki_pages/:id`                                  | Read (core)                | `view_wiki_pages`   |
| PATCH  | `/api/v3/wiki_pages/:id`                                  | Update                     | `edit_wiki_pages`   |
| DELETE | `/api/v3/wiki_pages/:id`                                  | Delete                     | `manage_wiki`       |
| POST   | `/api/v3/wiki_pages/:id/lock`                             | Protect from editing       | `manage_wiki`       |
| POST   | `/api/v3/wiki_pages/:id/unlock`                           | Remove protection          | `manage_wiki`       |
| POST   | `/api/v3/wiki_pages/:id/move`                             | Change parent or project   | `manage_wiki`       |
| POST   | `/api/v3/wiki_pages/:id/copy`                             | Duplicate the page         | `edit_wiki_pages`   |
| GET    | `/api/v3/wiki_pages/:id/versions`                         | List revisions             | `view_wiki_edits`   |
| GET    | `/api/v3/wiki_pages/:id/versions/:version`                | Read a revision            | `view_wiki_edits`   |
| POST   | `/api/v3/wiki_pages/:id/versions/:version/restore`        | Restore a revision         | `edit_wiki_pages`   |

## Request body

`POST` and `PATCH` accept a flat JSON payload:

```json
{
  "title": "Page Title",
  "text":  { "raw": "Markdown **content**" },
  "parentTitle": "Parent Page",
  "locked": false,
  "lockVersion": 2
}
```

`parentTitle` is optional. The HAL-style form using `_links.parent` is
also accepted:

```json
{
  "title": "Page Title",
  "text":  { "raw": "..." },
  "_links": { "parent": { "href": "/api/v3/wiki_pages/42" } }
}
```

`lockVersion` is required on `PATCH` — it is used for optimistic locking.

## Move / Copy

```
POST /api/v3/wiki_pages/:id/move
{ "parentTitle": "New Parent" }

POST /api/v3/wiki_pages/:id/move
{ "projectId": 7 }              // move to a different project (parent is reset)

POST /api/v3/wiki_pages/:id/copy
{ "title": "Copy of X", "projectId": 7 }   // projectId is optional
```

## Full-text search

Backed by a PostgreSQL GIN index over
`to_tsvector(config, title || ' ' || text)`.

The text search configuration is read from
`OPENPROJECT_WIKI__API_TSVECTOR__CONFIG` and defaults to `simple`, which
works across all languages. Installations targeting a specific language
may set it to a matching PostgreSQL configuration (`english`, `german`,
`russian`, ...) — the migration must be re-run so the index is created
with the same configuration.

Results are ordered by `ts_rank` (relevance), then by `updated_at`.

## Installation

The plugin is bundled via `Gemfile.modules`:

```bash
bundle install
bundle exec rails db:migrate
```

The migration creates the `index_wiki_pages_on_full_text_search` GIN
index.

## Tests

```bash
bundle exec rspec modules/wiki_api/spec
```
