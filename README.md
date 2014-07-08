op-api-v3-documentation
=======================

About this documentation
------------------------

This documentation is written in the [API Blueprint Format](http://apiblueprint.org/).

You can use [aglio](https://github.com/danielgtaylor/aglio) to generate HTML documentation, e.g. using the following command:

```bash
aglio -i apiary.apib -o api.html
```

Development stages
-----------------------------

The development of the OpenProject API v3 is split into multiple stages.
This part of the document describes these stages, their's resources and
endpoints.

### Stage 1

*Entry point:* `/`
Providing basic API documentation and links to OpenProject API resources

*Work packages:*
* `PATCH /work_packages/:id`
* `PATCH /work_packages?ids`
* `GET /work_package`

### Stage 2

*Work packages:*
* `GET /work_packages`
* `POST /work_packages`
* `DELETE /work_packages`

*Projects:*
* `GET /projects`
* `GET /projects/:id`

*Users:*
* `GET /users/:id`

*Versions:*
* `GET /versions/:id`

### Stage 3

TODO

### Stage 4

TODO
