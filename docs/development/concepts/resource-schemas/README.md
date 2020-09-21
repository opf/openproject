---
sidebar_navigation:
  title: Schemas
description: An introduction to resource schemas and how they are tied to editable resources
robots: index, follow
keywords: concept, schemas, resource schemas
---



# Resource schemas

In OpenProject, editable resources such as work packages or projects can be highly customized by the user. A resource can have an arbitrary number of additional custom fields.  In the frontend, the associated schema to a resource needs to be loaded in many cases when rendering attributes of that resource, such as in an [inline-editable field](../inline-editing).



## Key takeaways

Schema objects are the dictionary for the frontend application to identify the available properties of a resource.

*Schemas contain:*

- a (possibly) localized name
- The value type of the defined attributes
- Constraints for the authenticated user, i.e., whether the attribute is currently writable 
- (optional) additional option definitions for the attribute.



## Prerequisites

The following guides are related:

- [HAL resources](#TODO:hal-resources)

- [Backend API overview](#TODO:api-overview)




## API Backend

Schemas in the backend are regular Grape endpoints. For example, the schema of all projects is rendered through the [`::API::V3::Projects::Schemas::ProjectsSchemaAPI`](https://github.com/opf/openproject/blob/dev/lib/api/v3/projects/schemas/project_schema_api.rb). This in turn renders the associated [`::API::V3::Projects::Schemas::ProjectsSchemaRepresenter`](https://github.com/opf/openproject/blob/dev/lib/api/v3/projects/schemas/project_schema_representer.rb), which contains the set of schema properties to be rendered.

The work packages' schemas are significanatly more complex. Each work package type will define its own schema due to the dynamics of the [form configuration](https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration). With it, the order and grouping of work package attributes can be defined per type, resulting in different attributes to be displayed. In addition, custom fields can be individually enable per project for even more flexibility.

This results in not a single schema for all work packages, but one schema for each project - type combination.