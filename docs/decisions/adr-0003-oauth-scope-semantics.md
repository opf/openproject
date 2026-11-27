---
status: "accepted"
date: 2026-11-27
decision-makers:
  - Team Titan
consulted:
  - Klaus Zanders
  - Eric Schubert
  - Judith Roth
  - Wieland Lindenthal
informed:
  - Sebastian Cohnen
  - Jens Ulferts
  - OP Development Team (parties interested through looking at this ADR)
---

# Introducing API token scopes that allow access to resource classes (scope names follow a hierarchical naming scheme)

## Context and Problem Statement

Previously there was only one kind of scope established in OpenProject. It would grant access to a specific API protocol and all
resources and actions accessible via this API unfiltered. The exhaustive list of existing scopes is:

* `api_v3`
* `scim_v2`
* `mcp`
* `bcf_v2_1`

As a consequence each token grants a client obtaining it the full privileges of the user whose privileges are delegated via the
token. Practically a Nextcloud storage that exchanges the token for an administrator user is capable to remove or add projects
in OpenProject on the user's behalf and we rely on its good will to only use the token to access work packages.

We need a way to restrict:

* What a client in possession of a specific token can do in any given API
    * This includes one-off clients that may have received a personal API token (no OAuth involved)
* What kinds of scopes an OAuth client is able to obtain

## Decision Drivers

* There are simple use cases where exactly one token is handed out and we want to be able to restrict this token as specifically as possible (One-time uploads to S3, external scripts like ScriptRunner, external AI agents like Chomper, external services like Hocuspocus/YHub, ...)
* When configuring OAuth clients we often don't know ahead of time on which specific resource instances the client will need to operate (Mobile client, Nextcloud integration, ...)
    * However, we can often know which resource classes will be involved
    * ... and sometimes we can narrow it down to a certain set of instances
* The most typical unit to grant permissions in OpenProject is the workspace (i.e. projects, portfolios and programs), though exceptions exist
    * Scopes should therefore be able to restrict access to resources within certain workspaces, or more generally a certain
      *resource location*
* OpenProject is capable of accepting JWTs signed by configured OpenID Connect providers granting access to its APIs as well (openDesk, Nextcloud Hub, ...)
    * We want to support such external identity providers as good as we can
* New use cases for scopes may come up that are unrelated to resources
* We will not be able to implement all use cases from the start, but we search for a solution that can be expanded well to the use cases known
ahead of time
* Preventing the use of certain protocols does not achieve much in terms of security, but it can still be used to practically
  prevent or enable certain client implementations to access the application

## Considered Options

* A: Separate scopes for allowed API protocol, resource actions, and resource location
* B: Combined scopes for allowed API protocol, resource actions, and resource location
* C: Combined scopes for resource actions, and resource location, but separate scopes for allowed API protocol
* D: Combined scopes for resource actions, and resource location, no scope for API protocol at all

## Decision Outcome

Chosen option: "C: Combined scopes for resource actions, and resource location, but separate scopes for allowed API protocol",
because it allows to remain expressive in the situations where we need expressiveness, while simplifying our capabilities in
scenarios that are deemed unlikely to occur in real-world deployments (such as allowing vastly different access per protocol in
the same client configuration).

Additionally the new naming scheme common to most of the options is being adopted for new token scopes (see "More information" at the bottom).
The existing API scopes remain as legacy scopes until the new scoping scheme has been implemented and documented **and** we are able
to make a breaking change to the public API, i.e. during a major release. Until then, the existing legacy scopes grant access to
any resource, just as they did before. **The behaviour for mixing legacy scopes and new scopes is undefined,**
but it's suggested that we raise an API error in this case.

## Pros and Cons of the Options

### A: Separate scopes for allowed API protocol, resource actions, and resource location

```
# a token capable of reading any work package via MCP
op:api:mcp op:resource:work_packages:read op:location:*

# a token capable of reading and writing work packages in a certain resource location (e.g. project) via APIv3
# Note: Exact naming scheme and features of location scope is out-of-scope for this ADR
op:api:api_v3 op:resource:work_packages:write op:location:project:42

# a token capable of reading any resource over any protocol in any location
op:api:* op:resource:*:read op:location:*

# a token capable of doing anything, anywhere
op:api:* op:resource:* op:location:*

# a token capable of writing work packages and reading meetings over any protocol in any location
op:api:* op:resource:work_packages:write op:resource:meetings:read op:location:*
```

All dimensions of token access are carried in an extra kind of scope, no two dimensions are conflated in the same kind.
A scope can use wildcards to allow any value in the omitted part(s). A trailing wildcard includes further parts.

* Good, because new kinds can be added later on (including location kind)
* Good, because kinds are strictly separated and can be checked independently
* Good, because wildcards can only appear once per scope
* Good, because dimensions combine freely, so the number of scopes to configure in an external identity provider grows additively
* Neutral, because protocol expressiveness is limited; it's not possible to allow fetching work packages via APIv3 while allowing to
  fetch meetings via MCP
* Bad, because location expressiveness is limited; locations apply to all resource scopes of a token alike, so it's not possible
  to allow work packages of project A and meetings of project B

### B: Combined scopes for allowed API protocol, resource actions, and resource location

```
# a token capable of reading any work package via MCP
op:mcp:work_packages:read

# a token capable of reading and writing work packages in a certain resource location (e.g. project) via APIv3
# Note: Exact naming scheme and features of parts following "write" are out-of-scope for this ADR
op:api_v3:work_packages:write:project:42

# a token capable of reading any resource over any protocol in any location
op:*:*:read

# a token capable of doing anything, anywhere
op

# a token capable of writing work packages via APIv3 in a certain resource location and reading meetings over MCP in any location
# Note: Exact naming scheme and features of parts following "write" are out-of-scope for this ADR
op:api_v3:work_packages:write:project:42 op:mcp:meetings:read
```

A single scope carries all dimensions of token access. A scope can use wildcards to allow any value in the omitted part(s).
A trailing wildcard includes further parts.
A trailing wildcard can be omitted entirely, this specifically allows forward-compatibility with defining the schema for resource
locations later on, while staying compatible with our decision of today.

* Good, because it can express very specific shapes of access, each resource scope can be restricted to its own locations
* Good, because it's still possible to decide on location schema later on
* Neutral, because we can express mixed protocols in the same token
* Bad, because protocol, resource and location are combined into one scope, so an external identity provider may need to know
  one scope per combination of protocol, resource class and location
* Bad, because multiple levels of wildcards are possible, making it hard to understand what exactly got wildcarded
* Bad, because of unclear shape for new kinds added in the future
* Bad, because not all dimensions can be checked independently;
  checking resource location is bound to the current type of resource access
  and checking type of resource access is bound to current protocol

### C: Combined scopes for resource actions, and resource location, but separate scopes for allowed API protocol

```
# a token capable of reading any work package via MCP
op:api:mcp op:resource:work_packages:read

# a token capable of reading and writing work packages in a certain resource location (e.g. project) via APIv3
# Note: Exact naming scheme and features of parts following "write" are out-of-scope for this ADR
op:api:api_v3 op:resource:work_packages:write:project:42

# a token capable of reading any resource over any protocol in any location
op:api op:resource:*:read

# a token capable of doing anything, anywhere
op:api op:resource

# a token capable of writing work packages in a certain resource location and reading meetings in any location
# Note: Exact naming scheme and features of parts following "write" are out-of-scope for this ADR
op:api op:resource:work_packages:write:project:42 op:resource:meetings:read
```

The protocol dimension is carried in a separate kind of scope, but resource class and location are expressed in the same scope.
A scope can use wildcards to allow any value in the omitted part(s).
A trailing wildcard includes further parts.
A trailing wildcard can be omitted entirely, this specifically allows forward-compatibility with defining the schema for resource
locations later on, while staying compatible with our decision of today.

* Good, because new kinds can be added later on
* Good, because it's still possible to decide on location schema later on
* Good, because scopes consist of fewer parts than in B, which limits the possible combinations of wildcards
* Good, because location expressiveness is preserved; each resource scope can be restricted to its own locations, so it's possible
  to allow fetching all meetings, but only work packages from a certain workspace
* Neutral, because protocol expressiveness is limited; it's not possible to allow fetching work packages via APIv3 while allowing to
  fetch meetings via MCP
* Neutral, because multiple wildcards per scope become possible once resource locations are added,
  e.g. `op:resource:*:*:project:42` to allow any action on any resource within a certain location
* Neutral, because resource and location are combined into one scope, so an external identity provider may need to know
  one scope per combination of resource class and location
* Bad, because not all dimensions can be checked independently;
  checking resource location is bound to the current type of resource access

### D: Combined scopes for resource actions, and resource location, no scope for API protocol at all

This is the same as proposal C, but dropping the `op:api` scope entirely.

Compared to C it's:

* Good, because a security-irrelevant scope has been dropped
* Bad, because protocol expressiveness is removed entirely, customers might be disappointed

## More Information

### Details on the chosen naming schema

The naming schema was very similar across the options, however it's new compared to what we use nowadays. What follows is
a short rundown of the schema along with some rationalization. The description below is normative for the chosen solution C. Other
solutions might have required a slightly different definition.

Each scope consists of several parts that are separated by a colon (`:`). The first part is always `op`, followed by a part
describing the kind of scope. Depending on the kind of scope further parts may follow. A wildcard can be used to signify that
any value is allowed in a single part between two others. E.g. `op:example:*:foo` would satisfy access that requires `op:example:a:foo`,
but also `op:example:b:foo` and all other values for the third part.
A trailing wildcard also satisfies additional trailing parts, so `op:example:*` would satisfy access that requires `op:example:a`,
but also `op:example:a:b:c:d`.

A trailing `:*` can be omitted. This requires that all current and future uses of trailing scope parts are always more restrictive
than leaving them out.

A wildcard is not allowed in the first and second part of a scope. So neither `op`, nor `op:*`, nor `*` are valid scopes.
Rationale: If a wildcard was allowed in either of these, it would hurt forward compatibility, because we can't yet know what other kinds of
scopes could even mean. And the `op` in the first part literally means "OpenProject", so there is no other first part we'd ever want
to accept.

### API scopes (e.g. `op:api:<name>`)

API scopes will replace the existing legacy scopes. They grant access to OpenProject via specific protocols, but contrary to the existing
legacy scopes do not grant access to any resources themselves. Resource access has to be granted separately using at least one
resource scope.

Their kind is `api`. The third part specifies the name of the API endpoint class granted access to.
The exhaustive list of planned API scopes at the time of writing this ADR is:

* `op:api:api_v3`
* `op:api:scim_v2`
* `op:api:mcp`
* `op:api:bcf_v2_1`

### Resource scopes (e.g. `op:resource:<name>:<action>`)

Resource scopes grant access to a class of resources. Their kind is `resource`, followed by a part naming the resource class in
plural and another part naming the action performed on the resource. Decisions on implementation details and naming for
generic resource scopes are still pending.

Allowing to scope down access to resources further by their logical location in OpenProject is explicitly intended to be supported
in the future by the addition of further (optional) parts to the resource scope. Their exact schema, naming and capabilities are
beyond the scope of this ADR. When defining them, keep in mind that external identity providers issuing
tokens for OpenProject will need to reference locations as well, e.g. by their identifiers.
Mechanisms to decouple the number of scopes from the number of locations in OpenProject are strongly encouraged.
