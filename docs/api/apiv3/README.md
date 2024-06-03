# API Version 3

_Status: under development_

The specification for the APIv3 is written according to the [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/latest.html).

The file in the repository is split up into many files. Some OAS (OpenAPI Specification) do not support that. You can
retrieve the complete, singular file from any OpenProject server under `/api/v3/spec.json` or `/api/v3/spec.yml`.
Additionally, there is a script that outputs the specification as a whole as well, either as json or yaml depending on
the given format argument:

```shell
./script/api/spec --format yaml > openproject-oas.yml
```
