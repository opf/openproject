# API Version 3
 
_Status: under development_
 
The documentation for APIv3 is written according to the [OpenAPI 3.0 Specification](https://swagger.io/specification/).
 
The generated APIv3 documentation is built regular on the `dev` branch and can be found at: [opf.github.io/apiv3-doc/](opf.github.io/apiv3-doc/).

The file in the repository is split up into many files. Some OAS (OpenAPI Specification) do not support that.
You can retrieve the complete, singular file from any OpenProject server under under `/api/v3/spec.json` or `/api/v3/spec.yml`.
Additionally there is a rake task that outputs the specification as a whole as well, either as json or yaml depending
on the given output file name:

```
bundle exec rake api:save_spec ./openproject-oas.yml
```
