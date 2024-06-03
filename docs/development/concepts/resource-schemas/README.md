---
sidebar_navigation:
  title: Schemas
description: An introduction to resource schemas and how they are tied to editable resources
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

- [HAL resources](../hal-resources)

- Backend API overview

## API Backend

Schemas in the backend are regular Grape endpoints. For example, the schema of all projects is rendered through the [`::API::V3::Projects::Schemas::ProjectsSchemaAPI`](https://github.com/opf/openproject/blob/dev/lib/api/v3/projects/schemas/project_schema_api.rb). This in turn renders the associated [`::API::V3::Projects::Schemas::ProjectsSchemaRepresenter`](https://github.com/opf/openproject/blob/dev/lib/api/v3/projects/schemas/project_schema_representer.rb), which contains the set of schema properties to be rendered.

The work packages' schemas are significantly more complex. Each work package type will define its own schema due to the dynamics of the [form configuration](../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on). With it, the order and grouping of work package attributes can be defined per type, resulting in different attributes to be displayed. In addition, custom fields can be individually enable per project for even more flexibility.

This results in not a single schema for all work packages, but one schema for each project - type combination.

The resulting schema JSON is an object with properties that look like the following:

```json5
{
  "property": {
    "type": "String",
    "name": "Schema property",
    "required": true,
    "hasDefault": false,
    "writable": true,
    "minLength": 1,
    "maxLength": 255,
    "options": { /** */ }
  }
//...
}
```

### Schema examples

This section describes some of the existing schemas.

**Projects**

For projects, there is a single APIv3 endpoint for their schemas: `/api/v3/projects/schema`. This schema is identical for all projects. You can simply request the OpenProject Community schema for projects [here](https://community.openproject.org/api/v3/projects/schema). It contains a set of static properties (name, identifier, status, etc.), as well as all project-level custom fields.

**Work packages**

The work package schema is more complicated, as work package types can be customized to define what attributes the type should show as part of the [form configuration](../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on). Additionally, the visibility of custom fields can be controlled on a per-project level.

This results in work package schemas being defined per project and type combination. The URL of each schema looks like this: `/api/v3/work_packages/schemas/{project id}-{type-id}`.

An exemplary schema response on the Community for the OpenProject project (`ID=14`) and the Bug type (`ID=1`) is [community.openproject.org/api/v3/work_packages/schemas/14-1](https://community.openproject.org/api/v3/work_packages/schemas/14-1)

The work package schema also contains the reference to the attribute groups from the form configuration in the `_attributeGroups` property.

## Frontend usage

The OpenProject frontend usually ensure that whenever you get access to a HAL resource, its associated schema (if there is any) is also loaded. This is done through the [`SchemaCacheService`](https://github.com/opf/openproject/blob/dev/frontend/src/app/core/schemas/schema-cache.service.ts). It will request the associated schema unless it has already been cached in the global states object to avoid loading a schema multiple times.

In some cases, such as the work package `/api/v3/work_packages` or `/api/v3/queries` endpoints, the needed schemas to represent the work packages contained in the collection are embedded automatically in the `_embedded.schemas` endpoint. Services handling these loaded requests such as the [`WorkPackagesStatesInitializationService`](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/work-packages/components/wp-list/wp-states-initialization.service.ts) will automatically update the schema states.

If you look at the HAL+JSON response of a work package API request, you will see it has a `_links.schema.href` property which identifies the schema resource that the loaded work package is associated with. ([Exemplary request](https://community.openproject.org/api/v3/work_packages/34250))

If you have work package resource, you can get hold of its associated schema as follows:

```typescript
const schemaCache = injector.get(SchemaCacheService);
const workPackage = /** Work package from input or something */
schemaCacheService
  .ensureLoaded(workPackage)
  .then((schema:SchemaResource) => {
      // Output the localized name of the "subject" property.
      console.log(schema.subject.name); 
  });
```

The schema resource is made out of properties that the frontend identifies as [`IFIeldSchema`](https://github.com/opf/openproject/blob/dev/frontend/src/app/shared/components/fields/field.base.ts) interface:

```typescript
export interface IFieldSchema {
  // Type of the schema property, such as "String", "Integer", etc.
  type:string;
  // Whether the property is writable
  writable:boolean;
  // A set or link of allowed values e.g., for list-types
  allowedValues?:any;
  // Whether this property requires a value to be saved
  // (translates to input[required] property)
  required?:boolean;
  // Whether this property has a default value when saving
  hasDefault:boolean;
  // The localized name of this property
  name:string;
  // A set of options transmitted by the backend, mostly empty
  options?:any;
}
```

### Form schemas

When you try to update a resource such as a work package, you will commonly request a `Form` resource for this work package, which is a temporary resource that will have your changes applied to them, including error handling. In these forms, an embedded schema is output that represents the schema with permissions applied for the current user.

For example, if you try to update a work package type from let's say `Bug` to `Feature`, you would POST to the form with its type link updated, and are returned with a form object. The embedded schema of this form now points to the `Feature` type, and may contain additional attributes to render due to the differing form configuration.

These embedded schemas are never globally cached in the frontend, as they are highly dependent on the changes pushed to the form resource. They are always contained within a `ResourceChangeset`. Please see [the separate guide on changesets](../resource-changesets/) for more information.
