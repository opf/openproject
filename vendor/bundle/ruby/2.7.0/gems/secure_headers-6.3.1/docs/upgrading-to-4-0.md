## script_src must be set

Not setting a `script_src` value means your policy falls back to whatever `default_src` (also required) is set to. This can be very dangerous and indicates the policy is too loose.

However, sometimes you really don't need a `script-src` e.g. API responses (`default-src 'none'`) so you can set `script_src: SecureHeaders::OPT_OUT` to work around this.

## Default Content Security Policy

The default CSP has changed to be more universal without sacrificing too much security.

* Flash/Java disabled by default
* `img-src` allows data: images and favicons (among others)
* `style-src` allows inline CSS by default (most find it impossible/impractical to remove inline content today)
* `form-action` (not governed by `default-src`, practically treated as `*`) is set to `'self'`

Previously, the default CSP was:

`Content-Security-Policy: default-src 'self'`

The new default policy is:

`default-src https:; form-action 'self'; img-src https: data: 'self'; object-src 'none'; script-src https:; style-src 'self' 'unsafe-inline' https:`

## CSP configuration

* Setting `report_only: true` in a CSP config will raise an error. Instead, set `csp_report_only`.
* Setting `frame_src` and `child_src` when values don't match will raise an error. Just use `frame_src`.

## config.secure_cookies removed

Use `config.cookies` instead.

## Supported ruby versions

We've dropped support for ruby versions <= 2.2. Sorry.
