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

## Documentation coverage checks

`rake api:docs:coverage` diffs the real Grape APIv3 routes against this spec and
writes `tmp/api-doc-coverage.md` and `tmp/api-doc-coverage.json`. It is
non-blocking (always exits 0) and safe to run on a schedule.

- **Undocumented routes (hard):** served by code, missing from the spec.
- **Undocumented params (advisory):** documented endpoint, param missing from the spec.
- **Orphaned doc paths (info):** documented, no matching route (possibly stale).

Intentionally-undocumented routes go in `.coverage-ignore.yml`.

`rake api:docs:file_wps[module1,module2]` files/updates one work package per
module with hard gaps, using `.coverage-wps.yml` as an idempotency ledger. Run
`coverage` first; review the report; then file the modules you want.
