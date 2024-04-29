---
sidebar_navigation:
  title: Dynamically generated forms
description: An introduction on how to generate forms from an API form object
keywords: concept, forms, dynamic forms, schemas
---

# Dynamically generated forms

Starting in OpenProject 11.3.0, the frontend application received a new mechanism to dynamically generate HTML forms from an APIv3 form response. The form response contains the model being changed/created and [a schema resource](../resource-schemas/) to describe the attributes of the resource.

## Key takeaways

Dynamic forms are wrappers around the APIv3 form and schema objects to render a full HTML form based on the attribute definitions returned by the API.

## Prerequisites

The following guides are related:

- [Schema resources](../resource-schemas/)

## API overview

Let us take a look at the new projects form API response to get an overview of how this works.

With an [access token or other means of API authentication](../../../api/introduction/#authentication), send a `POST` to `/api/v3/projects/form`. This will return a HAL form response that looks something like this:

```json5
{
    "_type": "Form",
    "_embedded": {
        "payload": {
            "name": ""
            // ...
        },
        "schema": {
            "name": {
                "type": "String",
                "name": "Name",
                "required": true,
                "hasDefault": false,
                "writable": true,
                "minLength": 1,
                "maxLength": 255,
                "options": {}
            }
            // ...
        },
        "validationErrors": {
            "name": {
                "_type": "Error",
                "errorIdentifier": "urn:openproject-org:api:v3:errors:PropertyConstraintViolation",
                "message": "Name can't be blank.",
                "_embedded": {
                    "details": {
                        "attribute": "name"
                    }
                }
            }
        }
    },
    "_links": {
        "validate": {
            "href": "/api/v3/projects/form",
            "method": "post"
        }
    }
}        
```

The form has four important segments:

- **_embedded.payload**: This is the project being created. When you POST to the form, any payload you post will be applied to that project. It is not yet saved, but will transparently show you what the project _would_ look like if you saved it.
- **_embedded.schema**: The schema describing the payload object. For every attribute and link of the project, there will be a definition in the schema, telling you what the attribute is and how it should be used. From it, the type of the input field and the available options will be derived.
- **_embedded.validationErrors**: This object contains any references to attributes in the payload that are currently erroneous, and a human-readable message. In the example above, the required _name_ of the project is missing.
- **_links**: The links section contains HAL links and actions on the form resource itself. For example, it has a `validate` link to validate any pending changes made by the user. If the form has no validation errors, it will show a `commit` link to save the changes to the database. As the example form is invalid, this link is not present.

## Frontend usage

Using the dynamic form is incredibly easy once you have a backend that provides a form resource with an embedded schema.

Take a look at the [ProjectSettingsComponent](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/projects/components/projects/projects.component.html) that renders the settings form. You can simply use the `<op-dynamic-form>` component to render the form and pass it the `formUrl` or `resourcePath` + `resourceId` inputs.

The dynamic form component will request the form for you, render the form, and handle any saving and validation.

In case of the projects component, there is a `fieldsSettingsPipe` that allows you to override parts of the rendering. For projects, [it is used](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/projects/components/projects/projects.component.ts#L34-L44) hiding the `identifier` field of the project which is handled by the backend.

### Basic use case

For the most basic use case, simply place the `DynamicFormsModule` into your module imports and use the component as follows:

```html
<op-dynamic-form formUrl="/api/v3/projects/:id/form"></op-dynamic-form>
```
