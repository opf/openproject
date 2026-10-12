# OpenProject threat model

OpenProject is a web-based project management application (Ruby on Rails, PostgreSQL, Hotwire and Angular frontend). Organizations self-host it or use the OpenProject cloud. One instance holds many projects, users,
groups and roles. Data can be public or, more commonly, confidential: work packages, wikis, meetings, documents, time and cost entries, attachments and credentials for connected systems.

The security policy is in `docs/security-and-privacy/statement-on-security/README.md`. Follow it for scope and severity. This file summarizes it for the scanner.

## Where untrusted input enters

Assume every HTTP request, uploaded file, email and payload from a connected system is hostile.

Unauthenticated:

- Login, lost password, registration and invitation activation: `app/controllers/account_controller.rb`,
  `app/controllers/concerns/accounts/`, `app/services/users/`.
- SSO callbacks: OmniAuth (`app/controllers/omni_auth_login_controller.rb`, `config/initializers/omniauth.rb`),
  OpenID Connect including backchannel logout and bearer JWTs (`modules/openid_connect/`), SAML
  (`modules/auth_saml/`), LDAP (`app/models/ldap_auth_source.rb`), header SSO
  (`app/controllers/concerns/auth_source_sso.rb`), second factor (`modules/two_factor_authentication/`).
- OAuth 2 provider (Doorkeeper): `config/initializers/doorkeeper.rb`, `app/controllers/oauth/`.
- Incoming webhooks: `modules/webhooks/app/controllers/webhooks/incoming/`, with signature checks in
  `modules/github_integration/` and `modules/gitlab_integration/`.
- Token feeds: iCal (`modules/calendar/`, `modules/meeting/`) and Atom with `?key=` (`accept_key_auth` in
  `app/controllers/application_controller.rb`).
- SCM system API: `app/controllers/sys_controller.rb`.
- Incoming email: `app/services/incoming_emails/`.
- Anonymous access to public projects when `login_required` is off.

Authenticated:

- APIv3: `lib/api/v3/` and `modules/*/lib/api/v3/`. Authentication strategies are in
  `lib_static/open_project/authentication/strategies/warden/`.
- MCP server: `lib/api/mcp.rb`, `app/services/mcp_tools/`, `app/services/mcp_resources/`.
- BCF API: `modules/bim/app/controllers/bim/bcf/api/`.
- SCIM: `app/controllers/scim_v2/`.
- Rails controllers and Turbo endpoints in `app/controllers/` and `modules/*/app/controllers/`. Note the generic
  `app/controllers/inplace_edit_fields_controller.rb`.

## What matters most

1. **Authorization.** A user must only see and change what their roles, memberships and shares allow. This is
   the most important boundary. Look for missing or wrong checks in controllers, API endpoints, MCP tools,
   services, contracts and background jobs, and for leaks through filters, sorting, grouping, autocompleters,
   exports, notifications, journals (activity), attachments, relations and custom field values.
   - Permissions: `config/initializers/permissions.rb`, `lib/open_project/access_control/`, module `engine.rb`.
   - Checks: `app/models/users/permission_checks.rb`, `app/services/authorization/`.
   - Visibility scopes: `app/models/work_packages/scopes/`, `app/models/projects/scopes/`,
     `app/models/members/scopes/`, `app/models/principals/scopes/`.
   - Contracts and mass assignment: `app/contracts/`, `app/models/permitted_params.rb`.
   - Boundaries to test: project versus project, workspace hierarchy (portfolios, programs, projects, subprojects),
     work package sharing (`app/models/sharing_strategies/`, `app/services/shares/`), groups, placeholder users,
     archived projects, locked users, non-admin versus admin.
2. **Authentication and tokens.** Login, SSO, 2FA, password reset, invitations, API keys, OAuth, session handling.
   Token models are in `app/models/token/`. Session config is `config/initializers/session_store.rb`.
3. **Stored XSS and HTML injection with impact.** User text renders as Markdown through
   `lib/open_project/text_formatting/` (sanitizer in `filters/sanitization_filter.rb`, macros in `macros/`). Also
   check ViewComponents, Stimulus controllers and Angular components that render user data, and the CSP
   (`config/initializers/content_security_policy.rb`, `app/controllers/concerns/dynamic_content_security_policy.rb`).
4. **SQL injection.** Query filters, operators and sort criteria: `app/models/queries/`,
   `lib/open_project/sql_sanitization.rb`.
5. **SSRF.** Outbound HTTP must go through `OpenProject.httpx` with `lib/open_project/ssrf_protection.rb`. Check
   file storages (`modules/storages/`), outgoing webhooks, Jira import (`app/services/import/`), SAML metadata,
   wiki providers (`modules/wikis/`) and any client that uses `Net::HTTP` directly.
6. **Files and commands.** Attachments and direct upload (`app/models/attachment.rb`, `app/uploaders/`,
   `app/services/attachments/`), BCF XML and IFC import (`modules/bim/`), PDF, CSV and XLS export, repository
   adapters (`lib/open_project/scm/adapters/`), backups (`app/workers/backup_job.rb`). Look for path traversal,
   command injection, unsafe deserialization and CSV formula injection.
7. **Stored secrets.** Encryption of stored credentials (`lib/redmine/ciphering.rb`), OAuth client tokens and
   storage credentials.

Lower priority: development-only routes (`/letter_opener`, `/lookbook`, GoodJob dashboard), seed data, test
support code in `spec/`, and the Lookbook previews in `lookbook/`.

## How to test it

The image has the full checkout at `/src`, all gems and npm packages, precompiled frontend assets and
PostgreSQL with two databases:

- `openproject_development`: migrated and seeded with demo data.
- `openproject_test`: schema loaded, empty.

PostgreSQL is stopped when the container starts. Start it first:

```sh
/etc/init.d/postgresql start
```

Run the application in development mode and use `curl` or the browser:

```sh
bin/rails server -b 127.0.0.1 -p 3000
```

Seeded accounts (login = password unless noted): `admin` / `admin` (administrator), `admin_de` (administrator),
`project_admin`, `work_packager`, `member`, `reader`. Create more data with `bin/rails runner` or the factories in
`spec/factories/`. An API key for a user: `Token::API.create!(user: User.find_by(login: "reader")).plain_value`
in `bin/rails console`. Use the key with basic auth (`apikey:<key>`) on `/api/v3/...`.

Run specs in the test environment:

```sh
RAILS_ENV=test bundle exec rspec spec/requests/api/v3/work_packages/show_resource_spec.rb
```

Feature specs (`spec/features/`, `modules/*/spec/features/`) drive Chromium through Cuprite and need no network.
The preferred proof of concept is a request spec (`spec/requests/`) or a feature spec that fails before the fix
and passes after it.

## How we treat severity vulnerabilities

We use CVSS v3.1. Consider the attacker's required access and the real impact:

- **Critical**: exploitable remotely by an anonymous user or any logged-in user with no special permissions, no
  user interaction, and high impact. Examples: authentication bypass, remote code execution, SQL injection
  reachable by any user, reading or changing data of projects the attacker is not a member of.
- **High**: significant impact that needs some privileges or user interaction. Examples: stored XSS that a
  regular member can plant for other users, privilege escalation from member to project admin, SSRF to internal
  services with a readable response.
- **Medium / Low**: needs high privileges (instance admin, project admin), an unusual configuration, or active
  victim interaction; or has limited impact.

An instance administrator is highly trusted. Issues that need instance admin rights are at most medium, unless they cross into the host system (command execution, arbitrary file read or write).

## Out of scope

The following examples are out of scope in our security policy, unless they can be combined to a high or critical vulnerability.

- Tab nabbing, clickjacking or UI redressing through inline styles in formatted text.
- Text or HTML injection in formatted content that does not lead to script execution, or that only repeats what
  Markdown already allows (links, images).
- Denial of service through memory exhaustion, content size or request volume.
- Race conditions on business rules (duplicate unique names) with no further impact.
- Spam of users by email or notifications.
- Information disclosure with no exploit: stack traces, paths, versions, `autocomplete` attributes.
- Blind SSRF with no exploit (DNS or HTTP pingback only).
- Third-party library CVEs without a reachable OpenProject call path.
- Attacks that need MITM, physical access, an outdated browser, or a setting that the documentation does not
  recommend.
- Behavior that only exists in development or test mode (seeded passwords, letter opener, Lookbook, the database
  credentials in this image).

## Report and patch format

For each finding, output the following: 

- the affected code with file and line
- the attacker's required access
- a short proof of
  concept that runs offline in this image
- the CVSS v3.1 vector suggestion
- a minimal patch with a regression spec
