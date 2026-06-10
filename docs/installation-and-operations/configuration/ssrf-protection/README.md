---
sidebar_navigation:
  title: SSRF protection
---

# SSRF protection

## What is SSRF?

Server-Side Request Forgery (SSRF) is an attack where an attacker tricks the server into making HTTP requests to
unintended destinations - typically internal network resources that are not reachable from the public internet.

For example, if OpenProject can be configured to connect to an external URL (such as a Jira instance, a webhook
endpoint, or an outbound email server), an attacker could supply an internal IP address like `127.0.0.1` or
`192.168.1.10` or `169.254.169.254` (the AWS EC2 instance metadata endpoint) instead of a legitimate hostname.
The server would then fetch that internal resource on the attacker's behalf, potentially exposing internal services,
cloud credentials, or other sensitive data.

OpenProject blocks outbound connections to private and link-local IP ranges by default to prevent this class of attack.

## When does SSRF protection block connections?

Any feature that causes OpenProject to initiate an outbound HTTP connection is subject to SSRF protection. This
includes:

- Jira Migrator connections to a Jira Data Center instance
- File storage connections (e.g. Nextcloud)
- OpenID Connect providers
- Webhook deliveries
- Outgoing email server tests
- Any other integration that requires a URL to be configured by an administrator

If the target host resolves to a private IP address - even if you entered a hostname rather than a raw IP - the
connection will be blocked.

## Blocked IP ranges

OpenProject considers the following reserved address ranges to be private and blocks outbound connections to them by
default:

**IPv4**

| Range             | Description                             |
|-------------------|-----------------------------------------|
| `0.0.0.0/8`       | Current network (source-only addresses) |
| `10.0.0.0/8`      | Private network (RFC 1918)              |
| `100.64.0.0/10`   | Shared Address Space (RFC 6598)         |
| `127.0.0.0/8`     | Loopback                                |
| `169.254.0.0/16`  | Link-local                              |
| `172.16.0.0/12`   | Private network (RFC 1918)              |
| `192.0.0.0/24`    | IETF Protocol Assignments               |
| `192.0.2.0/24`    | TEST-NET-1 (documentation/examples)     |
| `192.168.0.0/16`  | Private network (RFC 1918)              |
| `198.18.0.0/15`   | Network benchmark tests                 |
| `198.51.100.0/24` | TEST-NET-2 (documentation/examples)     |
| `203.0.113.0/24`  | TEST-NET-3 (documentation/examples)     |
| `224.0.0.0/4`     | IP multicast                            |
| `240.0.0.0/4`     | Reserved (former Class E)               |
| `255.255.255.255` | Broadcast                               |

**IPv6**

| Range           | Description                       |
|-----------------|-----------------------------------|
| `::1/128`       | Loopback                          |
| `100::/64`      | Discard prefix (RFC 6666)         |
| `2001::/32`     | Teredo tunneling                  |
| `2001:10::/28`  | Deprecated (previously ORCHID)    |
| `2001:20::/28`  | ORCHIDv2                          |
| `2001:db8::/32` | Documentation and examples        |
| `2002::/16`     | 6to4                              |
| `fc00::/7`      | Unique local address              |
| `fe80::/10`     | Link-local address                |
| `ff00::/8`      | Multicast                         |

Addresses in `64:ff9b::/96` (NAT64, RFC 6052) and `64:ff9b:1::/48` (NAT64 local-use, RFC 8215) are blocked when the
embedded IPv4 address falls within any of the IPv4 ranges above.

## Allowing non-public IP addresses

When an integration target (such as a Jira Data Center instance) runs on an internal network, you must explicitly allow its IP
address or subnet using the `OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST` environment variable.

The variable accepts a comma- or space-separated list of IPv4 and IPv6 addresses, including CIDR range notation.

**Examples:**

Allow a single host:

```
OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST=192.168.1.42
```

Allow an entire subnet:

```
OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST=192.168.0.0/16
```

Allow multiple ranges (comma-separated):

```
OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST=10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
```

Allow multiple ranges (space-separated):

```
OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST=10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
```

Allow multiple ranges (space-separated; mixed IPv4 and IPv6):

```
OPENPROJECT_SSRF__PROTECTION__IP__ALLOWLIST=172.16.0.0/12 fd12:3456::/48
```

> [!WARNING]
> Only add IP addresses or ranges that you control and trust. Overly broad allowlists reduce the effectiveness of SSRF
> protection.

## Why an environment variable and not a UI setting?

Allowing internal IP ranges is a server-level security decision, not an application-level one.

Environment variables can only be changed by whoever controls the server or deployment
configuration - typically a system administrator or infrastructure team. A UI setting can be changed by any OpenProject
administrator with access to the web interface, which would render this protection ineffective.

These are two different trust levels, and a security control that limits the attack surface of the server should
require the higher level of access to modify.

## Setting the environment variable

Please see the [environment variables reference](../environment/) about environment variables.
