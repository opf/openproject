---
sidebar_navigation:
  title: API documentation
  priority: 910
---

# OpenProject API

OpenProject offers two APIs. The general purpose HATEOAS API v3 and the BCF API v2.1 api targeted towards BIM use cases.

Please note that we intend to keep this specification as accurate and stable as possible, however work on the API is still ongoing
and not all resources and actions in OpenProject are yet accessible through the API.

This document will be subject to changes as we add more endpoints and functionality to the API. The development version of this document
may have breaking changes while we work on new endpoints for the application.

We try to keep stable releases of OpenProject with changes to this API backwards compatible whenever possible.

## API v3

The API v3 is a general purpose API supporting multiple use cases.

While by no means complete, a whole lot of different scenarios can be automatized which otherwise would have to be carried out by hand via the UI.
Examples for this include managing work packages, projects and users.

➔ [Go to OpenProject API](./introduction/)

### OpenAPI Specification

Download the API specification in OpenAPI format as [json](https://www.openproject.org/docs/api/v3/spec.json) or [yml](https://www.openproject.org/docs/api/v3/spec.yml).

## BCF v2.1

This API supports BCF management in the context of BIM projects.

While this API supports way less use cases than the more generic *API v3* it is compatible with the generic specification of a BCF API as [defined by the standard](https://github.com/buildingSMART/BCF-API/blob/release_2_1/README.md). This, clients implementing the specification can manage topics and viewpoints.

➔ [Go to BCF API](./bcf-rest-api/)
