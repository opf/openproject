API Handling
============

In general, the OpenProject Frontend uses _all_ of the existing working APIs to provide it's functionality. This is due to the fact that the goals for `APIv3` have not yet been reached and it is not feature complete.

The documentation for these APIs and their capabilities:

- [APIv3](http://opf.github.io/apiv3-doc/)
- APIv2 docs are located in the `opf/openproject` repo at `./doc/apiv2-documentation.md`
- there is no documentation on the experimental API

To get a feel for which API is used at which point, please refer to the `PathHelper` located at `./frontend/app/helpers/path-helper.js`. It is used throughout the application to centralize knowledge about paths.

## HAL

While having a `PathHelper` certainly helps, the long-term idea is to levergae the [HAL](http://stateless.co/hal_specification.html)-capabilities of the APIv3 (thereby excluding `v2` and `experimental` long term) to let any client discover th paths in the api by inspecting the responses from any given call.

__Note:__ All responses from the APIv3 are thereby of `Content-Type: application/hal+json` and not just `Content-Type: application/json`. Some developer client tools sometimes get confused with that and do not interpret the formatting correctly.

Example:

```json
// calling a project

{
    "_type": "Project",
    "_links": {
        "self": {
            "href": "/api/v3/projects/1",
            "title": "Lorem"
        },
        "createWorkPackage": {
            "href": "/api/v3/projects/1/work_packages/form",
            "method": "post"
        },
        "createWorkPackageImmediate": {
            "href": "/api/v3/projects/1/work_packages",
            "method": "post"
        },
        "categories": { "href": "/api/v3/projects/1/categories" },
        "types": { "href": "/api/v3/projects/1/types" },
        "versions": { "href": "/api/v3/projects/1/versions" }
    },
    "id": 1,
    "identifier": "project_identifier",
    "name": "Project example",
    "description": "Lorem ipsum dolor sit amet"
}
```

The project structure contains links to ressources associated. At the time of writing, there is no ticket endpoint in the API, but just to give an example of using this, given the knowledge about `_links`, one may easily infer the path from the response:

```javascript
// some magic to retrieve an object, note that the services used are examplary 
// and not to be found in the actual codebase
ProjectsService.getProject('project_identifier').then(function(project) {
    var pathtoVersions = project._links.versions.href;
    // the VersionsService has knowledge about pathtoVersions in its 
    // forProject method
    VersionsService.forProject(project).then(function(versions) {
        // versions should be the result of the call to pathtoVersions
        console.log(versions);
    })
})
```

This is, in principle a very good concept to delegate responsibility of inference to the client and absolves the client of having to know each path in the application.

## Using hyperagent.js

In practise however, the OpenProject frontend use a fork of [`hyperagent.js`](https://github.com/weluse/hyperagent) (actually [this one from a former colleague is used](https://github.com/manwithtwowatches/hyperagent)).

`hyperagent.js` aims to provide an interface to a structed JSON response, providing a resource object automatically. While this is a nice goal, the current implementation used in the frontend is not complete.

The library has been wrapped as a service in `./frontend/app/api/hal-api-resource.js` and can be injected when needed.

What the service actually does is making resouce objects out out of certain API responses (`v3` only) and providing `LazyResource`s to attached links. This is also the difference to using `_links` and `links` as a property sometimes:

```javascript
//@see ./frontend/app/work_packages/services/work-package-attachments-service.js

// `workPackage` Hyperagent resource
var addAttachmentPath = workPackage.links.addAttachment.url();

// `workPackage` is an API response
var addAttachmentPath = workPackage._links.addAttachment.href;
```

One of the minor drawbacks of `hyperagent.js` is that it only supports `GET` requests at the moment and one has to awkwardly inject the `method` desired into the `options` of the AJAX call made (see also the `setup` method of `hal-api-resource.js`, as well as an example in `loadWorkPackageForm` in `./frontend/app/services/work-package-service.js`).

The goal should be to leverage `angular.$http` and make the calls accordingly. One of the short term goals should be to remove duplication introduced when building requests via the `HALAPIResource`.
