API Handling
============

In general, the OpenProject Frontend uses _all_ of the existing working APIs to provide its functionality, as the current working version for `APIv3` is not feature complete.

The documentation for these APIs and their capabilities:

- [APIv3](http://opf.github.io/apiv3-doc/)
- APIv2 docs are located in the `opf/openproject` repository at `./doc/apiv2-documentation.md`

To get a feeling for which API is used at which point, please refer to the `PathHelper` located at `./frontend/app/helpers/path-helper.js`. It is used throughout the application to centralize knowledge about paths.

## HAL

While having a `PathHelper` certainly helps, the long-term idea is to leverage the [HAL](http://stateless.co/hal_specification.html)-capabilities of the APIv3 (thereby leaving `v2` behind) to let any client discover the paths available for a resource by inspecting the responses from any given call.

__Note:__ All responses from the APIv3 are thereby of `Content-Type: application/hal+json` and not just `Content-Type: application/json`. Some developer client tools sometimes get confused with that and will not interpret the formatting correctly.

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

The `Project` structure contains links to ressources associated. Given the knowledge about `_links`, one may easily infer the path from the response:

```javascript
// some magic to retrieve an object, note that the services used are examplary
// and can not be found in the actual codebase
ProjectsService.getProject('project_identifier').then(function(project) {
    var pathToVersions = project._links.versions.href;
    // the VersionsService has knowledge about pathToVersions in its
    // forProject method
    VersionsService.forProject(project).then(function(versions) {
        // versions should be the result of the call to pathtoVersions
        console.log(versions);
    });
});
```

This is in principle a very good concept to delegate responsibility of inference to the client and absolves the client of having to know each path in the application in advance.

