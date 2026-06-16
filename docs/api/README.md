---
sidebar_navigation:
  title: API documentation
  priority: 910
---

# OpenProject API

OpenProject offers different APIs:

* API v3 (OpenProject's general purpose HATEOAS API)
* SCIM (System for Cross-domain Identity Management)
* MCP (Model Context Protocol)
* BCF API v2.1 api targeted towards BIM use cases
* .well-known endpoints

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

## SCIM

OpenProject allows to manage users and groups using System for Cross-domain Identity Management. This is a standardized API (see [RFC 7643](https://datatracker.ietf.org/doc/html/rfc7643) and [RFC 7644](https://datatracker.ietf.org/doc/html/rfc7644)) that might thus be supported by existing identity providers.

➔ [Read more on configuration instructions](../system-admin-guide/authentication/scim/)

## MCP

A growing number of tools and resources is offered through the Model Context Protocol API of OpenProject. This API is primarily targeted at AI agents and similar tools, as it supports auto-discovery of supported operations.

➔ [Read more on configuration instructions](../system-admin-guide/integrations/mcp-server/)

## BCF v2.1

This API supports BCF management in the context of BIM projects.

While this API supports way less use cases than the more generic *API v3* it is compatible with the generic specification of a BCF API as [defined by the standard](https://github.com/buildingSMART/BCF-API/blob/release_2_1/README.md). Clients implementing the specification can manage topics and viewpoints.

➔ [Go to BCF API](./bcf-rest-api/)

## .well-known endpoints

Each OpenProject installation exposes some endpoints under the `/.well-known/` path:

* `/.well-known/oauth-authorization-server`: [RFC 8414](https://datatracker.ietf.org/doc/html/rfc8414): OAuth 2.0 Authorization Server Metadata
* `/.well-known/oauth-protected-resource`: [RFC 9728](https://datatracker.ietf.org/doc/html/rfc9728): OAuth 2.0 Protected Resource Metadata
* `/.well-known/openproject-metadata`: Exposing non-confidential metadata about the OpenProject installation

### OpenProject Metadata

The `/.well-known/openproject-metadata` endpoint exposes some non-confidential metadata about the OpenProject instance in JSON format. This endpoint is accessible without authentication.

The following keys are exposed:

* `installation_uuid`: A unique identifier that's different per installation of OpenProject
