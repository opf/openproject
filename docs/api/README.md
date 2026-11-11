---
sidebar_navigation:
  title: API documentation
  priority: 910
---

# OpenProject API

OpenProject offers different APIs:

- API v3 (OpenProject's general purpose HATEOAS API)
- SCIM (System for Cross-domain Identity Management)
- MCP (Model Context Protocol)
- BCF API v2.1, targeted towards BIM use cases
- .well-known endpoints

Please note that we intend to keep this specification as accurate and stable as possible, however work on APIs is still ongoing
and not all resources and actions in OpenProject are yet accessible through the APIs.

This document will be subject to changes as we add more endpoints and functionality. The development version of this document
may have breaking changes while we work on new endpoints for the application.

## API v3

The API v3 is a general purpose API supporting multiple use cases.

While by no means complete, a whole lot of different scenarios can be automatized which otherwise would have to be carried out by hand via the UI.
Examples for this include managing work packages, projects and users.

We strive to maintain backward compatibility with this API in our stable OpenProject releases whenever possible.

➔ [Go to OpenProject API](./introduction/)

### OpenAPI specification

Download the API specification in OpenAPI format as [json](https://www.openproject.org/docs/api/v3/spec.json) or [yml](https://www.openproject.org/docs/api/v3/spec.yml).

## Markdown representation of a work package

A work package can be retrieved as a Markdown document, for example to hand it to an AI agent or a script. Request `GET /work_packages/:id.md`, `GET /projects/:identifier/work_packages/:id.md` or `GET /wp/:id.md` (which redirects to the first form), or request `GET /work_packages/:id` with the header `Accept: text/markdown`. The `:id` is the numeric id or, on instances using semantic work package identifiers, the display id such as `SE-642`. The response has the content type `text/markdown; charset=utf-8` and is served inline with `Content-Disposition: inline; filename="<display_id>.md"`.

The document starts with a title line `# <Type> <ID> - <Subject>` followed by `Project:`, `Status:` and `URL:` lines. It then contains one `## <group>` section per attribute group of the type's Form Configuration, in the configured order. Plain attributes are rendered as a two-column `| Attribute | Value |` table, long-text custom fields as a `### <field>` heading followed by their raw Markdown, and query groups such as Children as Markdown tables with the query's columns (or `_No work packages_`). The raw Markdown description comes last under `## Description`. Values are plain text: ISO dates, `Yes` and `No` for booleans, display ids and bare URLs for link fields. Activities and comments are not included yet. Structural labels, headings and `Yes`/`No` values follow the language of the requesting user, so scripts should not key on English words.

The document follows the same visibility rules as the work package page, so a viewer only sees what they may see, based on project permissions, module-dependent attributes and per-attribute permissions in embedded tables. Requests are authenticated by a browser session or, for bots, by the `X-OpenProject-API-Key: <key>` header, which requires API tokens to be enabled in the administration. OAuth bearer tokens are not accepted on this endpoint. Prefer the header over the `?key=` query parameter, because query strings end up in logs.

The API v3 work package resource links the document as `_links.markdown`.

The example uses the canonical path. `/wp/SE-642.md` redirects there, so `curl` needs `-L` to follow it.

```shell
curl -H 'X-OpenProject-API-Key: <key>' https://openproject.example.com/work_packages/SE-642.md
```

```markdown
# Feature SE-642 - Markdown rendering of work packages

Project: Search
Status: In progress
URL: https://openproject.example.com/work_packages/SE-642

## Details

| Attribute | Value |
| --- | --- |
| Assignee | Jane Doe |
| Date | 2026-10-01 - 2026-11-01 |

## Children

_No work packages_

## Description

Render a work package as **Markdown**.
```

The HTML work package page advertises this version in its `<head>` with `<link rel="alternate" type="text/markdown" href="…/work_packages/<id>.md" title="Markdown version">`.

## SCIM

OpenProject allows administrators to manage users and groups using System for Cross-domain Identity Management. This is a standardized API (see [RFC 7643](https://datatracker.ietf.org/doc/html/rfc7643) and [RFC 7644](https://datatracker.ietf.org/doc/html/rfc7644)) that might thus be supported by existing identity providers.

➔ [Read more on configuration instructions](../system-admin-guide/authentication/scim/)

## MCP

A growing number of tools and resources is offered through the Model Context Protocol API of OpenProject. This API is primarily targeted at AI agents and similar tools, as it supports auto-discovery of supported operations.

➔ [Read more on configuration instructions](../system-admin-guide/integrations/mcp-server/)

## BCF v2.1

This API supports BCF management in the context of BIM projects.

While this API supports way less use cases than the more generic _API v3_ it is compatible with the generic specification of a BCF API as [defined by the standard](https://github.com/buildingSMART/BCF-API/blob/release_2_1/README.md). Clients implementing the specification can manage topics and viewpoints.

➔ [Go to BCF API](./bcf-rest-api/)

## .well-known endpoints

Each OpenProject installation exposes some endpoints under the `/.well-known/` path:

- `/.well-known/oauth-authorization-server`: [RFC 8414](https://datatracker.ietf.org/doc/html/rfc8414): OAuth 2.0 Authorization Server Metadata
- `/.well-known/oauth-protected-resource`: [RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728): OAuth 2.0 Protected Resource Metadata
- `/.well-known/openproject-metadata`: Exposing non-confidential metadata about the OpenProject installation

### OpenProject Metadata

The `/.well-known/openproject-metadata` endpoint exposes some non-confidential metadata about the OpenProject instance in JSON format. This endpoint is accessible without authentication.

The following keys are exposed:

- `installation_uuid`: A unique identifier that's different per installation of OpenProject
