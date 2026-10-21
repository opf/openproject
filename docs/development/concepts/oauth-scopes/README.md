---
sidebar_navigation:
  title: OAuth scopes
description: Get an overview of how OAuth scopes are named and registered in the OpenProject application code
keywords: OAuth, scopes, access tokens, authentication
---

# Development concept: OAuth scopes

OAuth access tokens carry scopes that limit what the token can be used for. Besides the general scopes like `api_v3`, modules can define scopes that grant access to a few selected endpoints only, e.g. to let a client edit documents without granting it the whole API.

## Key takeaways

_New OAuth scopes in OpenProject..._

- are named `op:<kind>:<resource>:<action>`, e.g. `op:resource:documents:edit`
- are registered with `OpenProject::Authentication.register_restricted_oauth_scope`, which validates the name at boot
- are internal: they can't be assigned to OAuth applications and don't show up in the OAuth metadata
- are only accepted on endpoints that opt in with `route_setting :oauth_scopes`
- differ from the legacy scopes `api_v3`, `scim_v2`, `mcp` and `bcf_v2_1`, which keep their names

## Format

A scope consists of four lowercase segments separated by `:`:

| Segment      | Allowed values                                                             |
|--------------|----------------------------------------------------------------------------|
| `op`         | Always `op`, the OpenProject namespace.                                    |
| `<kind>`     | One of `OpenProject::Authentication::OAUTH_SCOPE_KINDS` (`resource`).      |
| `<resource>` | One of `OpenProject::Authentication::OAUTH_SCOPE_RESOURCES` (`documents`). |
| `<action>`   | Free, but a lowercase segment matching `/\A[a-z][a-z0-9_]*\z/`.            |

The allowed kinds and resources are defined in [`OpenProject::Authentication`](https://github.com/opf/openproject/blob/dev/lib_static/open_project/authentication.rb). Extending them is a deliberate change to core. Actions differ a lot per endpoint, so they aren't restricted to a fixed list.

A scope that doesn't match this format raises an `ArgumentError` on registration, so the application fails to boot.

## Why the `op` prefix

OpenProject can accept JWTs issued by external identity providers and reads their `scope` claim (see the [`JwtOidc` strategy](https://github.com/opf/openproject/blob/dev/lib_static/open_project/authentication/strategies/warden/jwt_oidc.rb)). Such an identity provider usually issues scopes for several services. The `op` prefix keeps OpenProject's scopes from colliding with the scopes of other services.

## Restricted, internal scopes

A scope registered with `register_restricted_oauth_scope` is restricted to a Warden scope, e.g. `api_v3`. A token carrying it authenticates for that Warden scope, but only grants access to the endpoints that explicitly accept it. All other endpoints of the API answer with `403` and the `InsufficientScope` error.

Such scopes are always internal. OpenProject issues tokens with them itself, e.g. the documents module through its own OAuth application. Administrators can't assign them to OAuth applications, and the OAuth metadata doesn't list them.

## How to add a scope

1. If the resource is new, add it to `OAUTH_SCOPE_RESOURCES` in `OpenProject::Authentication`.
2. Register the scope in the `to_prepare` block of your module's engine:

   ```ruby
   config.to_prepare do
     OpenProject::Authentication.register_restricted_oauth_scope("op:resource:documents:edit",
                                                                 restricted_to: OpenProject::Authentication::Scope::API_V3)
   end
   ```

   Registering the same scope again (e.g. on code reload in development) is harmless.

3. Opt the endpoints in that should accept the scope:

   ```ruby
   route_setting :oauth_scopes, ["op:resource:documents:edit"]
   get do
     # ...
   end
   ```

See the [documents engine](https://github.com/opf/openproject/blob/dev/modules/documents/lib/open_project/documents/engine.rb) and the [documents API](https://github.com/opf/openproject/blob/dev/modules/documents/lib/api/v3/documents/documents_api.rb) for an example.

## Legacy scopes

The following scopes predate this convention and don't follow the format:

| Scope      | Registered in                                     |
|------------|---------------------------------------------------|
| `api_v3`   | `config/initializers/doorkeeper.rb`               |
| `scim_v2`  | `config/initializers/doorkeeper.rb`               |
| `mcp`      | `config/initializers/doorkeeper.rb`               |
| `bcf_v2_1` | `modules/bim/lib/open_project/bim/engine.rb`      |

They match the names of Warden scopes (`OpenProject::Authentication::Scope`) and are used by existing clients, so they keep their names. They are assignable to OAuth applications. Don't add new scopes like them.
