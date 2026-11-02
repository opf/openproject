# CI and automation

[← User guide](../README.md)

1. [Prepare OpenProject](#1-prepare-openproject) · 2. [Pick the target run](#2-pick-the-target-run) (iterations, CI connections) ·
3. [Run in CI](#3-run-in-ci-start-automated-tests-from-openproject) · 4. [Artifacts](#4-artifacts) ·
5. [Quick test with curl](#5-quick-test-with-curl) · 6. [Self-hosted runner](#6-self-hosted-runner-for-a-local-instance-k3d-httpsopenprojecttest) ·
7. [Self-hosted Git](#7-self-hosted-git-gitlab-gitea-forgejo-jenkins-woodpecker-github-enterprise-server) ·
8. [Repo-qualified references](#8-repo-qualified-automation-references) · 9. [CI connections API](#9-ci-connections-api) ·
[Test steps](#test-steps) · [Exit codes](#exit-codes-of-op-tm-uploadsh)

Files in this folder:

| File | What it is |
|------|------------|
| `op-tm-upload.sh` | Uploads one report (Playwright JSON, JUnit XML, native JSON, Allure results or Cucumber JSON / messages) plus screenshots, traces and other artifacts. It needs `bash`, `curl` and `jq`. |
| `github-actions-playwright.yml` | A GitHub Actions workflow with sharded Playwright jobs. All shards go into one run, and a final job completes it. |
| `gitlab-ci-playwright.yml` | The same setup for GitLab CI. |
| `gitlab-ci-selfhosted.yml` | GitLab CI on a self-hosted server (internal CA, sub-path) for uploads and "Run in CI". |
| `gitea-forgejo-actions.yml` | A Gitea / Forgejo / Codeberg Actions workflow for "Run in CI". |
| `Jenkinsfile` | A parameterised Jenkins pipeline for "Run in CI". |
| `woodpecker-playwright.yml` | A manual Woodpecker pipeline for "Run in CI". |

The API is described in the APIv3 docs (section *Test Management*, overview in [API](../api.md)). The upload endpoint is:

```
POST /api/v3/projects/{project}/test_management/automation/results    multipart: file, metadata, attachments[]
```

## 1. Prepare OpenProject

1. Enable the *Test management* module in the project.
2. Create a CI user, or use your own account. Give it a role with **Upload automated test results**. Add **View test runs** if it should read runs back.
3. Log in as that user and open *My account → Access tokens → API*. Create a token and store it as a CI secret (`OP_API_TOKEN`).
4. Optional: in the CI, set the case reference on each test so results always go to the right case:
   - **Playwright:** `test("…", { annotation: { type: "tm_case", description: "12" } }, …)`, or a tag such as `@TC-12`.
   - **JUnit:** `<property name="tm_case" value="12"/>`.
   - **Native format:** `"caseId": 12`.
   - After the first matched upload, the case remembers the test's *automation reference* (shown on the case and editable). After that, no IDs are needed in the test code.

## 2. Pick the target run

CI can own the full lifecycle — **create → fill → optional close** — with or without a milestone,
or attach to an existing run.

| You want | Send |
|----------|------|
| A new run for every CI build | nothing (or `OP_RUN_NAME`) |
| One run for all shards or jobs of a build | `OP_EXTERNAL_REF` (the script sets `github:<repo>:<run id>:<attempt>` or `gitlab:<project>:<pipeline id>`) |
| Results added to a run that a tester created (partial update) | `OP_RUN_ID` |
| The run completed after the upload | `OP_CLOSE_RUN=true`, or `POST /api/v3/test_management/runs/{id}/complete` |
| Assign a **new** run to a milestone | `milestone` metadata (id, `M12` or name); unknown/completed → warning, run still created |
| A new **iteration** of a long-lived run (e.g. *Smoke* on every push, *Regression* nightly) | `OP_MODE=new_iteration OP_TARGET_RUN=Smoke` (or `OP_RUN_ID`) |

A completed or cancelled run answers **409**. Sending the same report twice is harmless: the second upload returns `replay: true`.

Skipped tests are shown as *Skipped* and do not count against the pass rate.

### Create, fill and close (CI-owned run)

Without `OP_RUN_ID`, an upload creates a run (or reuses one by `externalRef`), writes matched
results, and optionally completes it with `OP_CLOSE_RUN=true`. Pass `milestone` only when you want
that new run under a release/sprint gate; omit it for a standalone automated run. No plan or UI
action is required.

### Mixed runs (`OP_RUN_ID` without `new_iteration`)

Uploading into an existing active run updates **only matched cases**. Manual cases and unmatched
report rows keep their previous status. The OpenProject run stays active unless you close it.

### Iterations (`new_iteration`)

A run can be executed many times. Each execution is an *iteration*: starting one resets every case of
the run to *untested*; the results of earlier iterations are kept. The run page shows the iteration
history with the pass rate of each iteration and a switcher to look at an older one (read-only).
Testers can also start an iteration by hand on the run page, or with
`POST /api/v3/test_management/runs/{id}/iterations`.

With `OP_MODE=new_iteration` an upload goes to the newest open run named `OP_TARGET_RUN`
(case-insensitive; the run is created on first use, warning `target_run_created`). All uploads with the
same `externalRef` (the shards of one build) fill the same iteration; the next build starts the next one.
Sending the same report again into the same iteration returns `replay: true`. Optional
`OP_ITERATION_NAME` names the iteration; by default the name comes from the CI metadata.

### CI connections (Project settings → Test management)

Users with **Manage test CI** can add any number of connections per project for GitHub, GitLab,
Gitea, Forgejo, Codeberg, Jenkins and Woodpecker, in the cloud or self-hosted: name, provider,
repository, server URL (HTTPS only; empty for github.com, gitlab.com and codeberg.org), access
token, the "Run in CI" settings (workflow file, trigger token, user), the default ingest mode with
its target run, and the self-hosted options of section 7 (CA certificate, *Inbound only*,
reference name, end-to-end tests, an attached Repositories-module repository).

- An upload is linked to the connection whose provider and repository match `ci.provider` /
  `ci.repository` (the script fills both from `GITHUB_REPOSITORY` / `CI_PROJECT_PATH`), or to
  `OP_CONNECTION` (name or id). Without `OP_MODE` the connection's mode and target run apply, so the
  pipeline needs no Test Management settings at all.
- The tokens are stored encrypted and never shown again, nor returned by the API (`tokenSet`,
  `triggerTokenSet` only). Leave a field empty to keep the stored token; *Remove the stored token*
  deletes it. After the server URL, the provider or the CA certificate changes, the tokens must be
  entered again.
- The access token is used by *Check connection* (it reads the repository and shows OK,
  unauthorized, not found or error, plus the server version), by pull-request sources of the Test
  Assistant and, depending on the provider, by "Run in CI" (see the table in section 3). For
  *Check* alone a read-only token is enough (GitHub: fine-grained, *Metadata: read*; GitLab:
  `read_api`).
- Inactive connections are ignored by auto-detection; naming one explicitly is rejected (422).

## 3. Run in CI (start automated tests from OpenProject)

Users with **Trigger test automation** (needs *Add test runs*) see **Run in CI** on a run, on a
folder in the case list and on an automated case. OpenProject then:

1. collects the selected cases that have an *automation reference* (`path/file.spec.ts#test name`);
2. pre-creates the target: a **new run** (named after the scope and the connection) or a **new
   iteration** of an existing open run;
3. triggers the CI job of the chosen connection with `op_run_id`, `op_iteration_id`, `op_project`
   and `op_grep` (GitHub / Gitea / Forgejo / Codeberg inputs) or `OP_RUN_ID`, `OP_ITERATION_ID`,
   `OP_PROJECT`, `OP_GREP` (GitLab variables, Jenkins parameters plus `OP_REF`, Woodpecker
   variables);
4. records the answer on the run (*Run in CI* row: status, link to the CI run, error).

The job runs the tests with `--grep "$OP_GREP"` and uploads with `op-tm-upload.sh`; `OP_RUN_ID` +
`OP_ITERATION_ID` make the results land in the pre-created iteration whatever the connection's mode.
`op_grep` is the test names (the part after `#`, or the path when there is none), regex-escaped and
joined with `|`. When it would exceed 1000 characters it is sent empty and the job runs everything;
results for cases outside the run are reported as unmatched.

The same is available as `POST /api/v3/projects/{id}/test_management/ci_triggers`
(`connection`, `mode`, one of `runId` / `suiteId` / `testCaseId`, `ref`, `name`):
**201** triggered, **502** the provider refused (the run / iteration exist and carry the error),
**422** invalid, **403** missing permission.

### Connection settings per provider

| Provider | Repository | Server URL | Workflow file | Access token (trigger) | Trigger token | Version / limits |
|----------|------------|------------|---------------|------------------------|---------------|------------------|
| GitHub | `owner/repo` | empty = github.com; GHE: `https://ghe.example.com` | required, e.g. `e2e.yml` | fine-grained, *Actions: write* | – | Inputs must be declared in the workflow (max 25). Since 2026-02 the API returns the run id and URL; older GHE answers 204 and the link points to the workflow. |
| GitLab | `group/sub/project` | empty = gitlab.com | – | optional (only for *Check*) | **required**: pipeline trigger token | Variables only (pipeline `inputs` need GitLab 17.11+, not used). Returns pipeline id + URL. |
| Jenkins | job path `folder/job` | **required** | – | API token of the *Jenkins user* | optional *Trigger builds remotely* token | Parameterised job; API-token requests need no crumb (a crumb is fetched and retried on 403). Queue item URL is recorded, the build URL is not known yet. |
| Gitea | `owner/repo` | **required** | required | `write:repository` | – | Gitea ≥ 1.24; run id + URL from 1.26 (`return_run_details`), else link to the workflow. |
| Forgejo | `owner/repo` | **required** | required (file name) | `write:repository` | – | Forgejo ≥ 8.0; run number + URL from 11.0 (`return_run_info`). |
| Codeberg | `owner/repo` | empty = codeberg.org | required | `write:repository` | – | Forgejo-based. Actions must be enabled per repository; hosted runners only for public FLOSS projects (no proprietary or LLM workloads); API rate limit about 2000 requests / 10 min. Codeberg recommends Woodpecker for most projects. |
| Woodpecker | numeric repository id | **required** | – | personal access token | – | `POST /api/repos/{id}/pipelines` (manual event). Variables become environment variables. |

All tokens are stored encrypted, never shown again and never returned by the API. Server URLs must
use HTTPS, and requests to private or local addresses are refused unless the instance allows them
(the same SSRF protection as other outgoing requests; see section 7 for the allowlist, an internal
CA and inbound-only connections). Changing the server URL, provider or CA certificate requires the
tokens to be entered again. Redirects are not followed; time-out 15 s.

### Limits of this PoC

- OpenProject does not poll the CI: the run shows *Triggered* until results arrive. A job that
  fails before uploading leaves the iteration untested (start a new one or cancel the run).
- Only the default/selected branch or ref is passed; matrix / shard settings live in the CI file.
- One trigger per click; there is no queuing or de-duplication of repeated clicks.
- The job needs its own OpenProject API token (`OP_API_TOKEN`) to upload; the trigger does not hand
  one over.

## 4. Artifacts

`OP_ARTIFACTS_DIR=test-results` uploads screenshots, videos, traces and logs. The script also sends each file's relative path (`attachmentPaths`). The server can then place every file on the run case of the test that produced it, even though Playwright names them all `test-failed-1.png`. Files that belong to no test (for example `OP_EXTRA_FILES=playwright-report.zip`) are attached to the run.

The instance's attachment limits apply: the maximum file size and the allowed content types (*Administration → Files*). Rejected files show up as warnings in the response, and the upload still succeeds. At most 200 files are accepted per request.

## 5. Quick test with curl

```bash
curl -sS -H "Authorization: Bearer $OP_API_TOKEN" \
  -F "file=@results.json" \
  -F 'metadata={"externalRef":"manual-test-1","closeRun":false};type=application/json' \
  -F "attachments[]=@test-results/login-chromium/test-failed-1.png" \
  "$OP_URL/api/v3/projects/demo-project/test_management/automation/results" | jq '{createdRun, replay, import: .import | {parsedCount, matchedCount, unmatchedCount}, run: .run | {id, state, passRate}}'

# the same report as a new iteration of the "Smoke" run
curl -sS -H "Authorization: Bearer $OP_API_TOKEN" -F "file=@results.json" \
  -F 'metadata={"mode":"new_iteration","targetRun":"Smoke","externalRef":"manual-smoke-1"};type=application/json' \
  "$OP_URL/api/v3/projects/demo-project/test_management/automation/results" | jq '{mode, createdRun, createdIteration, iteration, run: .run | {id, name, currentIteration, passRate}}'
```

## 6. Self-hosted runner for a local instance (k3d, `https://openproject.test`)

GitHub-hosted runners cannot reach an instance that runs only on your machine. Register a **self-hosted runner** on the same machine and give it the label `openproject-test`:

1. GitHub repository → *Settings → Actions → Runners → New self-hosted runner*, then follow the steps for your OS. When `./config.sh` asks for labels, add `openproject-test`.
2. In the workflow, set `runs-on: [self-hosted, openproject-test]`.
3. **Name resolution:** the runner must resolve `openproject.test` to the k3d load balancer. If the runner runs on the host where k3d publishes ports 80/443, the hosts entry you already use is enough (`127.0.0.1 openproject.test`). Check it with:
   ```bash
   curl -sS -o /dev/null -w '%{http_code}\n' https://openproject.test/api/v3   # expect 200 or 401
   ```
   If the runner runs in a container, add the host. With Docker: `--add-host openproject.test:host-gateway`. In Kubernetes: a `hostAliases` entry pointing to the ingress or load-balancer IP.
4. **TLS:** a local certificate (mkcert, or a self-signed cert from cert-manager) is not trusted by `curl` by default. Export the CA certificate and pass it to the script as `OP_CA_CERT=/path/to/ca.pem`, or store the PEM as the secret `OP_CA_CERT` (the workflow writes it to a file). Typical sources:
   - mkcert: `"$(mkcert -CAROOT)/rootCA.pem"`
   - a cert-manager CA issuer: `kubectl -n <namespace> get secret <ca-secret> -o jsonpath='{.data.ca\.crt}' | base64 -d > ca.pem`

   Do not switch off certificate checks (`curl -k`). The token travels in the request.
5. The runner needs `bash`, `curl`, `jq` and Node.js for Playwright. Restrict self-hosted runners to private repositories, because jobs from forks would run on your machine.

## 7. Self-hosted Git (GitLab, Gitea, Forgejo, Jenkins, Woodpecker, GitHub Enterprise Server)

Uploads (`op-tm-upload.sh`) only need the CI job to reach OpenProject, so they work with any server,
also one that OpenProject cannot reach. "Check connection", "Run in CI" and pull-request sources of
the test assistant are the only features where **OpenProject calls the server**.

**Server URL.** Enter the web URL as you open it in the browser, including a relative URL root:
`https://example.com/gitlab` → API `https://example.com/gitlab/api/v4/...`, MR URLs
`https://example.com/gitlab/group/sub/project/-/merge_requests/7`. The same applies to Gitea /
Forgejo (`/api/v1`), Jenkins (`/jenkins/job/...`) and Woodpecker. HTTPS only; query strings and
fragments are rejected. The GitLab project path is URL-encoded (`group%2Fsub%2Fproject`). After a
project is renamed or moved, update the repository: GitLab redirects the API only for a while.

**Check connection** shows the server version: GitLab `/api/v4/metadata` (fallback `/api/v4/version`),
Gitea / Forgejo `/api/v1/version`, Woodpecker `/version`, Jenkins `X-Jenkins` header, GitHub
Enterprise `X-GitHub-Enterprise-Version` header. GitLab older than **15.7** is flagged: merge-request
diffs then use the deprecated `/changes` endpoint (used automatically when `/diffs` returns 404).

**Tokens.** GitLab "Run in CI" needs a *pipeline trigger token* (Settings → CI/CD → Pipeline trigger
tokens; owner needs the Maintainer role). The optional access token for *Check* and MR diffs needs
only `read_api` (a project or group access token with the Reporter role is enough). Other providers:
see the table in section 3.

**Private addresses (SSRF protection).** OpenProject refuses outgoing requests to hosts that resolve
only to private, loopback or link-local addresses. The connection then shows e.g.
"gitlab.internal has a private address and is blocked … Addresses of gitlab.internal: 10.20.0.15".
A server administrator allows it with an environment variable and a restart:

```bash
OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST="10.20.0.15"          # or a range: "10.20.0.0/24 10.30.1.7"
# Helm: openproject.extraEnv / environment; packaged: openproject config:set …
```

Allow only the Git / CI servers, not whole private networks. See
<https://www.openproject.org/docs/installation-and-operations/configuration/ssrf-protection/>.

**Internal CA.** Two options, both keep certificate verification on:

1. Per connection (Project settings → Test management → CI connection → *CA certificate*): paste the
   PEM of the root (and intermediate) CA. It is trusted in addition to the system store, only for this
   connection. Up to 10 certificates / 64 KB; private keys are rejected. Changing it requires the
   tokens to be entered again. The list shows the subject and expiry date.
2. Instance-wide: add the CA to the system trust store of the OpenProject container or host
   (`update-ca-certificates`, or `SSL_CERT_FILE=/path/bundle.pem`). This also covers other
   outgoing requests of OpenProject (Nextcloud, OpenID Connect providers, …).

There is **no option to switch off TLS verification**. It would send the stored tokens to whoever
answers on the network path (man in the middle), and the trigger token can start pipelines with
arbitrary variables. If the certificate cannot be trusted, use *Inbound only*.

**Inbound only / one-way networks.** Tick *Inbound only* on the connection when only CI → OpenProject
is allowed (air-gapped GitLab, firewall, DMZ). OpenProject then never calls the server: *Check*, the
trigger and PR sources are off. "Run in CI" prepares the run and iteration and shows the CI variables
(`OP_URL`, `OP_PROJECT`, `OP_CONNECTION`, `OP_RUN_ID`, `OP_ITERATION_ID`, `OP_GREP`) plus a ready
command (curl, or the gh CLI for GitHub; tokens as placeholders) to start the pipeline from
inside the network, e.g. GitLab → Build → Pipelines → Run pipeline. The API returns the same as
`manualStart`. Diffs for the test assistant can be pasted as text.

**Which server sent the results.** `op-tm-upload.sh` sends `ci.serverUrl` from `CI_SERVER_URL`
(GitLab, includes the sub-path), `GITHUB_SERVER_URL`, `JENKINS_URL` or `CI_SYSTEM_URL` (Woodpecker);
override with `OP_SERVER_URL`. Auto-detection then only uses a connection on that server (scheme,
host, port and sub-path), so results from a self-hosted GitLab never land on a gitlab.com connection
that has the same project path (the upload is filed without a connection instead). An explicit
`OP_CONNECTION` on another server is accepted with a warning.

**Same repository on two servers.** Provider, server (`serverUrl`: scheme, host, non-default port and
sub-path, derived from the base URL) and repository are unique per project, so `qa/web/shop` can have
one connection for gitlab.com and one for `https://git.example.com/gitlab`. Uploads pick the right one
by `ci.serverUrl`; an upload without it uses the oldest and warns `connection_ambiguous`.

**Source links.** A test case whose automation reference is a file path (`tests/login.spec.ts#…`)
links to the file on the server of the connection that last ran it (at the commit of that run),
or of the project's only Git connection (default branch). A repo-qualified reference
(`shop:tests/login.spec.ts#…`, see [section 8](#8-repo-qualified-automation-references)) only uses
the connections of repository `shop`. References stay host-independent.

**GitLab integration and Repositories module.** The OpenProject GitLab integration (webhooks for
MRs, pipelines, branches) and the CI connections are independent and can point to the same
self-hosted GitLab. Repositories known from linked MRs / branches are offered in the connection form
as "server URL + repository". The Repositories module (Git / Subversion checked out on the
OpenProject server) has no CI. Its hint has a quick action, **Set up a connection for this
repository**: it opens the new-connection form with the repository attached, *Inbound only* ticked
and a guessed repository path – nothing is saved until you choose the provider and save. Nothing is
prefilled otherwise. An attached repository is also offered as a checkbox on every connection; for
cases of a connection without a forge page (Jenkins, Woodpecker, or no Git web UI) the source link
then opens OpenProject's repository browser (`/projects/<id>/repository/revisions/<sha>/entry/<path>`,
only for users with *Browse repository*).

**Runner side.** Example: [`gitlab-ci-selfhosted.yml`](gitlab-ci-selfhosted.yml) – internal CA from a
file variable `OP_CA_CERT` or the runner's `CI_SERVER_TLS_CA_FILE`, `CI_SERVER_URL` with sub-path,
and a job for pipelines started by OpenProject or by hand.

## 8. Repo-qualified automation references

When several repositories report into one project, the same file path (`tests/login.spec.ts`) can
exist in each. A reference can therefore name its repository:

```text
[<name>[/e2e]:]<file or class>[#<title path>]

shop:tests/cart.spec.ts#cart › adds an item           test of repository "shop"
shop/e2e:e2e/checkout.spec.ts#checkout › pays         end-to-end test of repository "shop"
api-service:com.acme.UserTest#createsUser            JUnit test of repository "api-service"
tests/cart.spec.ts#cart › adds an item               unqualified – works as before
```

- `<name>` is the connection's **Reference name** (Project settings → CI connection), by default the
  last segment of its repository (`qa/web/shop` → `shop`; Woodpecker: the connection name). Letters,
  digits, `_`, `.`, `-`, up to 100 characters.
- A prefix only counts as a qualifier when it is the reference name of a connection of the project.
  Anything else (`Feature: Login#…`, `a.spec.ts:12#…`, `https://…`) stays an unqualified reference, so
  existing references keep their meaning.
- **Matching.** An upload knows its repository (its connection, else the last segment of
  `ci.repository`). A reported reference matches `shop:<ref>`, then `shop/e2e:<ref>`, then the
  unqualified `<ref>`. Cases qualified for another repository (`api:<ref>`) never match. `/e2e` does
  not change matching. A `tm_ref` annotation may itself carry a qualifier.
- **Writing.** `updateReferences` (on by default) and `autoCreateCases` (**off** by default; set
  `autoCreateCases: true` to opt in) store `shop:<ref>` or `shop/e2e:<ref>` when the repository is
  known, else the unqualified reference as before. Existing references are not rewritten.
  `upload_test_results` can still create runs and write results; case creation stays an explicit
  opt-in because it mutates the case library.
- **End-to-end detection** (first match wins): the upload option `testType` (`OP_TEST_TYPE`; `e2e` →
  e2e, any other value → not); the connection's *End-to-end tests* setting (always / never);
  automatic: Playwright JSON reports, a path with an `e2e` segment (`e2e/…`, `tests/e2e/…`,
  `checkout.e2e.ts`, `checkout.e2e-spec.ts`) or below `cypress/`.
- **Run in CI** only sends a connection the cases that are unqualified or qualified with its own
  name; `OP_GREP` contains the titles without the qualifier.

## 9. CI connections API

The project settings and APIv3 share one service and contract (*Manage test CI*):

```bash
# create (201)
curl -sS -u "apikey:$OP_TOKEN" -H 'Content-Type: application/json' \
  -X POST "$OP_URL/api/v3/projects/shop/test_management/ci_connections" \
  -d '{"name":"Shop (internal GitLab)","provider":"gitlab","repository":"qa/web/shop",
       "baseUrl":"https://git.example.com/gitlab","token":"glpat-…","triggerToken":"glptt-…",
       "caCertificate":"-----BEGIN CERTIFICATE-----\n…","referenceName":"shop","e2eTests":"auto"}'
# update (200): only sent keys change; empty token keeps it, removeToken deletes it
curl -sS -u "apikey:$OP_TOKEN" -H 'Content-Type: application/json' \
  -X PATCH "$OP_URL/api/v3/test_management/ci_connections/3" -d '{"inboundOnly":true}'
# delete (204)
curl -sS -u "apikey:$OP_TOKEN" -X DELETE "$OP_URL/api/v3/test_management/ci_connections/3"
```

Tokens and the CA PEM are never returned (`tokenSet`, `triggerTokenSet`, `caCertificates` summary).
403 without *Manage test CI*, 404 when the connection is not visible, 422 for invalid values (e.g.
`http://`, the same repository on the same server, a token that must be entered again after
`baseUrl` / `provider` / `caCertificate` changed).

## Test steps

Reports with steps fill a **result per case step**: the failed step is marked *Failed*, the steps after
it *Not run* (or *Blocked*), and the test's error message and stack trace are stored in the result's
**Error** field. See [Step results and errors](../runs.md#step-results-and-errors) for how this looks.

### Formats with steps

| Format (`format`) | What is read | Detected by `auto` |
|---|---|---|
| Playwright JSON (`playwright_json`) | `test.step()` (the JSON reporter leaves out hooks, fixtures and `expect` calls), nested steps, step errors and attachments | yes |
| Allure results (`allure`) | `steps[]` of each `*-result.json`, `statusDetails` (message, trace), step attachments, labels `tm_case` / `tag`, step parameter `tm_step` | yes |
| Cucumber JSON (`cucumber_json`) | Background and scenario steps (`Keyword text`), failed hooks, `error_message`, tags | yes |
| Cucumber messages (`cucumber_messages`, NDJSON) | `testStepFinished` per pickle step, the last attempt (retries), exception message and stack trace | yes |
| Native JSON (`native`) | `steps[]` with `title`, `step`, `status`, `durationMs`, `message`, `stack`, `attachments`, nested `steps` | yes |
| JUnit XML (`junit`) | No steps; `<failure message>` and its text become the error | yes |

Allure writes one file per test. Join them before the upload:

```bash
jq -s . allure-results/*-result.json > allure-report.json
OP_REPORT=allure-report.json OP_FORMAT=allure ./op-tm-upload.sh
```

Limits: 200 steps per test, 5 levels, 1,000 characters per title, 4,000 per message, 8,000 per step
trace and 16,000 per result trace. ANSI color codes are removed. Texts are always shown as plain
text, never as HTML.

### How reported steps find case steps

1. **Marker**: a step that carries a case step number. In the title: `[step:2]`, `[Step 2]`,
   `[step #2]` or `@S2` (the marker is removed from the shown title). As a field: native `"step": 2`
   or the Allure step parameter `tm_step`. Markers are found in nested steps, too.
2. **Position**: without markers, when the number of top-level reported steps equals the number of
   case steps, step *n* goes to case step *n*.
3. **Title**: otherwise each reported step goes to the most similar case step action (Gherkin
   keywords, case and punctuation are ignored; similarity of at least 70 %).

Several reported steps on one case step give the worst status (failed > blocked > passed > skipped).
Reported steps that match nothing are kept as **reported steps** below the case steps (at most 50), so
nothing gets lost. A case without steps gets no step rows; the error is still stored.

### Marker examples

```ts
// Playwright
await test.step('[step:1] Open the cart', async () => { await page.goto('/cart'); });
await test.step('[step:2] Enter the card number', async () => { await page.fill('#card', '4242…'); });
```

```java
// Allure Java (JUnit 5, TestNG) – annotation or lambda
@Step("[step:2] Enter the card number")
void enterCard(String number) { … }

Allure.step("[step:3] Confirm the payment", () -> page.click("#pay"));
Allure.step("Confirm the payment", step -> { step.parameter("tm_step", 3); page.click("#pay"); });
```

```python
# pytest + allure-pytest
with allure.step("[step:2] Enter the card number"):
    page.fill("#card", "4242…")
```

```js
// WebdriverIO / Cypress with the Allure reporter
await allure.step('[step:2] Enter the card number', async () => { … });
```

```json
// native JSON
{ "tests": [{ "caseId": "TC-12", "status": "failed", "steps": [
  { "title": "Open the cart", "step": 1, "status": "passed" },
  { "title": "Enter the card number", "step": 2, "status": "failed", "message": "Card field not found" } ] }] }
```

Cucumber steps cannot carry markers; they are mapped by order (the Background counts) or by their
text, so keep the case step actions close to the Gherkin step texts. Selenide's Allure listener adds a
step per element action; use `new AllureSelenide().includeSelenideSteps(false)` or markers.

### Options

`stepsAfterFailure` (metadata): `untested` (default, shown as *Not run*) or `blocked` for the case
steps after the failed one that the report did not mention.

## Exit codes of `op-tm-upload.sh`

| Code | Meaning |
|------|---------|
| 0 | Results recorded (or a replay) |
| 1 | Configuration error, such as a missing variable or report |
| 2 | HTTP error. The message from OpenProject is printed: 400 unreadable report, 403 missing permission, 404 project or run not found, 409 run finished, 413 report too large, 422 invalid options |
| 3 | Some tests were not matched to a case (only with `OP_FAIL_ON_UNMATCHED=true`) |
