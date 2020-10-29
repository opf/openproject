`secure_headers` 3.0 is a near-complete rewrite. It includes breaking changes and removes a lot of features that were either leftover from the days when the CSP standard was not fully adopted or were just downright confusing.

Changes
==

| What                                                     | < = 2.x                                                                                                                                                                                         | >= 3.0                                                                                                                                                                       |
| ----------------------------------                       | ----------------------------------------------------------                                                                                                                                      | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Global configuration                                     | `SecureHeaders::Configuration.configure` block                                                                                                                                                  | `SecureHeaders::Configuration.default` block                                                                                                                                 |
| All headers besides HPKP and CSP                         | Accept hashes as config values                                                                                                                                                                  | Must be strings (validated during configuration)                                                                                                                             |
| CSP directive values                                     | Accepted space delimited strings OR arrays of strings                                                                                                                                           | Must be arrays of strings                                                                                                                                                    |
| CSP Nonce values in views                                | `@content_security_policy_nonce`                                                                                                                                                                | `content_security_policy_nonce(:script)` or `content_security_policy_nonce(:style)`                                                                                              |
| nonce is no longer a source expression                   | `config.csp = "'self' 'nonce'"`                                                                                                                                                                 | Remove `'nonce'` from source expression and use [nonce helpers](https://github.com/twitter/secureheaders#nonce).                                                             |
| `self`/`none` source expressions                         | Could be `self` / `none` / `'self'` / `'none'`                                                                                                                                                  | Must be `'self'` or `'none'`                                                                                                                                                 |
| `inline` / `eval` source expressions                     | Could be `inline`, `eval`, `'unsafe-inline'`, or `'unsafe-eval'`                                                                                                                                | Must be `'unsafe-eval'` or `'unsafe-inline'`                                                                                                                                 |
| Per-action configuration                                 | Override [`def secure_header_options_for(header, options)`](https://github.com/twitter/secureheaders/commit/bb9ebc6c12a677aad29af8e0f08ffd1def56efec#diff-04c6e90faac2675aa89e2176d2eec7d8R111) | Use [named overrides](https://github.com/twitter/secureheaders#named-overrides) or [per-action helpers](https://github.com/twitter/secureheaders#per-action-configuration)   |
| CSP/HPKP use `report_only` config that defaults to false | `enforce: false`                                                                                                                                                                                | `report_only: false`                                                                                                                                                         |
| Schemes in source expressions                            | Schemes were not stripped                                                                                                                                                                       | Schemes are stripped by default to discourage mixed content. Setting `preserve_schemes: true` will revert to previous behavior                                               |
| Opting out of default configuration                      | `skip_before_filter :set_x_download_options_header` or `config.x_download_options = false`                                                                                                      | Within default block: `config.x_download_options = SecureHeaders::OPT_OUT`                                                                                                   |

Migrating to 3.x from <= 2.x
==

1. Convert all headers except for CSP/HPKP using hashes to string values. The values are validated at runtime and will provide guidance on misconfigured headers.
1. Convert all instances of `self`/`none`/`eval`/`inline` to the corresponding values in the above table.
1. Convert all CSP space-delimited directives to an array of strings.
1. Convert all `enforce: true|false` to `report_only: true|false`. 
1. Remove `ensure_security_headers` from controllers (3.x uses a middleware instead).

Everything is terrible, why should I upgrade?
==

`secure_headers` <= 2.x built every header per request using a series of automatically included `before_filters`. This is horribly inefficient because:

1. `before_filters` are slow and adding 8 per request isn't great
1. We are rebuilding strings that may never change for every request
1. Errors in the request may mean that the headers never get set in the first place

`secure_headers` 3.x sets headers in rack middleware that runs once per request and uses configuration values passed via `request.env`. This is much more efficient and somewhat guarantees that headers will always be set. **The values for the headers are cached and reused per request**.

Also, there is a more flexible API for customizing content security policies / X-Frame-Options. In practice, none of the other headers need granular controls. One way of customizing headers per request is to use the helper methods. The only downside of this technique is that headers will be computed from scratch.

See the [README](README.md) for more information.
