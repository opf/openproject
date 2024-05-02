---
sidebar_navigation:
  title: HAL+JSON resources
description: Get an overview of how inline-editing of resources works
keywords: development concepts, HAL, JSON, hal resources, API requests
---

# Development concept: HAL resources

HAL resources are the frontend counterpart to the `HAL+JSON` API of OpenProject. They are class instance of the JSON resources with action links being turned into callable functions to perform requests.

## Key takeaways

*HAL resources ...*

- are requested from the APIv3 endpoints and generated from their JSON response by the [`HALResourceService`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/services/hal-resource.service.ts).
- contain `$links` and `$embedded` properties to map the original JSON object for linked resources, and the ones that were embedded to the response.
- Can have an arbitrary number of properties on the object that map to the JSON properties, or elements from the `_links` and `_embedded` JSON segments.
- They unfortunately are complex and mutable objects

## Prerequisites

HAL resources on the frontend have no explicit prerequisite on our frontend. You will likely want to take a look at the [API documentation and the section on HAL+JSON](../../../api/introduction).

## Primer on HAL JSON

The JSON response in HAL standard can contain these things:

- Basic properties on the base JSON itself (such as IDs, simple properties such as dates etc.)
- Related HAL resources under `_links` that can be individually requested from the API (e.g., the link to a project the resource is contained in). Links often have a `title` attribute that is sufficient to render what the value of the link is.
- Embedded HAL resources under `_embedded`. These are link properties themselves, but whose HAL JSON has been embedded into the parent JSON. You can think of this as calling the API and integrating the JSON response into the parent. This saves an additional request for resources that are often needed.

The following is an example HAL JSON for a work package as it is retrieved by the API. This response is abbreviated, you can see the full response of [#34250 on our community](https://community.openproject.org/api/v3/work_packages/34250). You will see the three sections:

1. Immediate properties within the JSON such as `_type`, `id`, `lockVersion`, `description`. There are more properties like this, they are scalar values of the work package that are not linked to other resources

2. The `_links` section. It contains two sorts of links. For other resources such as `_links.project` and `_links.status`. Each resource link contains an `href` and most often a `title` attribute to provide a human readable name of the linked resource.

   The other type of links are the action links such as `update` or `updateImmediately` which are annotated with the HTTP method to use for these actions.

3. The `_embedded` section. It contains `_links` that were embedded, i.e., have their own full JSON response included into the resource. This prevents additional requests, but increases the JSON payload and rendering complexity.

   The frontend cannot decide which resources to embed, this is controlled by the backend and depends on the endpoint used. For example, resource collection endpoints will usually not embed links.

```json5
{
  "_type": "WorkPackage",
  "id": 34250,
  "lockVersion": 5,
  "subject": "possible data loss on editing comments",
  "description": {
    "format": "markdown",
    "raw": "# Title",
    "html": "<h1>Title</h1>"
  },
  "_links": {
    "self": {
      "href": "/api/v3/work_packages/34250",
      "title": "possible data loss on editing comments"
    },
    "update": {
      "href": "/api/v3/work_packages/34250/form",
      "method": "post"
    },
    "schema": {
      "href": "/api/v3/work_packages/schemas/14-1"
    },
    "updateImmediately": {
      "href": "/api/v3/work_packages/34250",
      "method": "patch"
    },
    "delete": {
      "href": "/api/v3/work_packages/34250",
      "method": "delete"
    },
    "project": {
      "href": "/api/v3/projects/14",
      "title": "OpenProject"
    },
    "status": {
      "href": "/api/v3/statuses/7",
      "title": "confirmed"
    }
    // ...
  },
  "_embedded": {
    "project": {
      "_type": "Project",
      "id": 14,
      "identifier": "openproject",
      "name": "OpenProject",
      "active": true,
      "public": true,
      "description": {
        "format": "markdown",
        "raw": "Building the best open source project collaboration software.",
        "html": "<p>Building the best open source project collaboration software.</p>"
      },
      "_links": {
        "self": {
          "href": "/api/v3/projects/14",
          "title": "OpenProject"
        }
        // ...
      }
    },
    "status": {
      "_type": "Status",
      "id": 7,
      "name": "confirmed",
      "isClosed": false,
      "color": "#FFA8A8",
      "isDefault": false,
      "isReadonly": false,
      "defaultDoneRatio": null,
      "position": 6,
      "_links": {
        "self": {
          "href": "/api/v3/statuses/7",
          "title": "confirmed"
        }
      }
    }
  },
}
```

In this linked example, only the `status` and `project` links and embedded resources were kept, as well as some work package properties removed.

## HalResourceService

On to loading the JSON resources from the API and turning them into usable class instances. This is the job of the the [`HALResourceService`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/services/hal-resource.service.ts). It has two responsibilities:

1. It uses the Angular `HTTPModule` for performing API requests to the APIv3
2. It turns the responses of these requests  (or HAL JSON generated in the frontend) into a HAL resource class

### Performing requests against HAL API endpoints

The service has HTTP `get`, `post`, `put`, etc. methods as well as a generic `request`  method that accept an URL and params/payload, and respond with an observable to the JSON transformed into a HAL resource.

### Error Handling

For errors returned by the HAL API (specific error `_type` response in the JSON) or when erroneous HTTP statuses are being returned, the `HALResourceService` will wrap these into `ErrorResources` for identifying the cause and potentially, additional details to present to the frontend. This is used for example when saving work packages and validation errors occur. The validations are being output in details for individual attributes.

## Linked HAL resources

The `_links`  entries of a HAL resource can have a `url`, `method`, and `title` property. They can also be `templated` if the link needs to be filled out by the frontend (e.g., to set a related ID to pass into it).

In the process of building the HAL resource, action `_links` objects are being turned into resources themselves:

- Either into a `HALResource` class themselves if the linked object is retrieved via `GET` from the API
- Or into a `HalLink` class instance to perform an action link.

The [`HalLink`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/hal-link/hal-link.ts) class is a wrapper around the `HalResourceService#request` method to call the action. This way, the action links can be called automatically by calling, e.g., `workPackage.update()` to request the form link with the URL defined in `_links.update.href`.

For linked resources such as `_links.project`, this will result in the `workPackage.project` property being a HALResource that can be loaded from the API with `workPackage.project.$load()`. This will modify the project resource in the work package, mutating it in place.

```typescript
// Building source from object here, instead of loading from the API for demo purposes
const source = { 
    id: 1234,
    _type: 'WorkPackage',
    _links: {
        project: { href: '/api/v3/projects/1', title: 'Demo Project' }
    }
};

// HalResourceService looks up the `_type` to return the correct resource type
const wp:WorkPackageResource = halResourceService.createHalResource(source);

// Project link was turned into a resource
console.log(wp.project.href); // /api/v3/projects/1

// The resource is not embedded, thus not loaded
console.log(wp.project.$loaded); // false
// The name property is available from the title attribute
console.log(project.name); // Demo Project

// Explicitly load the HAL resource
const project = await wp.project.$load();
console.log(project.href); // /api/v3/projects/1
console.log(project.name); // Demo Project
console.log(wp.project.$loaded); // true
```

On first glance, it might look nice to be able to `$load()` the embedded project on the fly and use the returning promise. However, this request will not be cached anywhere, thus loading the same project on multiple work packages will result in multiple requests.

Also, the `workPackage` state will be constantly mutated whenever these requests happen. You will always have to check whether the resource was loaded.

Instead of explicitly loading embedded resources, the frontend now usually uses a `CacheService` to load and cache a resource of a specific type by its href. For example, for the project, there is a `ProjectCacheService#require(href)` method that will ensure a project is loaded, or fetched from cache and returns a promise to use. This will no longer mutate the work package resource.

However, there are still use cases where `.$load()` is used and the resource is mutated.

## HAL resource builder

In order to turn the JSON properties from `_embedded` and `_links` into writable properties on the HAL resource, there is a set of functions called the [`HAL resource builder`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/helpers/hal-resource-builder.ts). It will take care of:

- Maintaining a `$source` property which is the pristine JSON response from the API.

- Mapping the properties under `_links` into `$links` property with  `HalLinks` that can be called in the application. `e.g., workPackage.$links.update()` will call the API to the URL behind that link.

- Mapping the properties under `_embedded` into `$embedded` and turning each of these into their own `HalResource` instance.

- It definers setters to all properties of the HAL resource to modify the `$source` object. For example, if you have a link `_links.project` in your JSON, you can override the project used for the resource with `resource.project = projectResource` or `resource.project = { href: '/api/v3/projects/1234' }`. This will modify the `$source` object.

  The frontend doesn't really use this anymore due to it boiling down to a large mutable object. Instead, we use `ResourceChangesets` to modify resources and save them. [Click here to see the separate concept on them](../resource-changesets).

## 🔗 Code references

- [`HALResourceService`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/services/hal-resource.service.ts) for loading and turning JSON responses into HAL resource classes
- [`halResource.config.ts`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/services/hal-resource.config.ts) for identifying what types in the JSON response and its members/links are being turned into which classes.
- [`HalResource`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/resources/hal-resource.ts) the base HAL resource class
- [`HAL resource builder`](https://github.com/opf/openproject/tree/dev/frontend/src/app/features/hal/helpers/hal-resource-builder.ts) used for wiring up the links and embedded JSON properties into members of the HAL resource classes

## Discussions

- Due to the dynamic properties of the HAL resource, it traditionally has an index map to `any` which is the source of many typing issues and in turn, quite a number of bugs: [hal-resource.ts](https://github.com/opf/openproject/blob/dev/frontend/src/app/features/hal/resources/hal-resource.ts#L63)
- The way HAL resources work by embedding and allowing to load
