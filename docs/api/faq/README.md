---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding the API of OpenProject
keywords: API FAQ, API v3, RestAPI, interface, connector 

---

# Frequently asked questions (FAQ) for API

## Can I update a wiki page via API?

Yes. Use `PATCH /api/v3/wiki_pages/{id}` and include the current `lockVersion`
to protect against concurrent edits. To validate a prospective update before
persisting it, submit the same payload to `POST /api/v3/wiki_pages/{id}/form`.
Wiki pages can also be created with `POST /api/v3/wiki_pages` and deleted with
`DELETE /api/v3/wiki_pages/{id}`.

## (How) can I add work package categories to a project via API?

The API v3 currently does not expose categories via the API.

Please note that categories might change in the future as they have a lot of limitations, e.g. when filtering.
