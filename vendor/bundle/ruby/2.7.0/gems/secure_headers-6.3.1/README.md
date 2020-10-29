# Secure Headers ![Build + Test](https://github.com/github/secure_headers/workflows/Build%20+%20Test/badge.svg?branch=main)

**main branch represents 6.x line**. See the [upgrading to 4.x doc](docs/upgrading-to-4-0.md), [upgrading to 5.x doc](docs/upgrading-to-5-0.md), or [upgrading to 6.x doc](docs/upgrading-to-6-0.md) for instructions on how to upgrade. Bug fixes should go in the 5.x branch for now.

The gem will automatically apply several headers that are related to security.  This includes:
- Content Security Policy (CSP) - Helps detect/prevent XSS, mixed-content, and other classes of attack.  [CSP 2 Specification](http://www.w3.org/TR/CSP2/)
  - https://csp.withgoogle.com
  - https://csp.withgoogle.com/docs/strict-csp.html
  - https://csp-evaluator.withgoogle.com
- HTTP Strict Transport Security (HSTS) - Ensures the browser never visits the http version of a website. Protects from SSLStrip/Firesheep attacks.  [HSTS Specification](https://tools.ietf.org/html/rfc6797)
- X-Frame-Options (XFO) - Prevents your content from being framed and potentially clickjacked. [X-Frame-Options Specification](https://tools.ietf.org/html/rfc7034)
- X-XSS-Protection - [Cross site scripting heuristic filter for IE/Chrome](https://msdn.microsoft.com/en-us/library/dd565647\(v=vs.85\).aspx)
- X-Content-Type-Options - [Prevent content type sniffing](https://msdn.microsoft.com/library/gg622941\(v=vs.85\).aspx)
- X-Download-Options - [Prevent file downloads opening](https://msdn.microsoft.com/library/jj542450(v=vs.85).aspx)
- X-Permitted-Cross-Domain-Policies - [Restrict Adobe Flash Player's access to data](https://www.adobe.com/devnet/adobe-media-server/articles/cross-domain-xml-for-streaming.html)
- Referrer-Policy - [Referrer Policy draft](https://w3c.github.io/webappsec-referrer-policy/)
- Expect-CT - Only use certificates that are present in the certificate transparency logs. [Expect-CT draft specification](https://datatracker.ietf.org/doc/draft-stark-expect-ct/).
- Clear-Site-Data - Clearing browser data for origin. [Clear-Site-Data specification](https://w3c.github.io/webappsec-clear-site-data/).

It can also mark all http cookies with the Secure, HttpOnly and SameSite attributes. This is on default but can be turned off by using `config.cookies = SecureHeaders::OPT_OUT`.

`secure_headers` is a library with a global config, per request overrides, and rack middleware that enables you customize your application settings.

## Documentation

- [Named overrides and appends](docs/named_overrides_and_appends.md)
- [Per action configuration](docs/per_action_configuration.md)
- [Cookies](docs/cookies.md)
- [Hashes](docs/hashes.md)
- [Sinatra Config](docs/sinatra.md)

## Configuration

If you do not supply a `default` configuration, exceptions will be raised. If you would like to use a default configuration (which is fairly locked down), just call `SecureHeaders::Configuration.default` without any arguments or block.

All `nil` values will fallback to their default values. `SecureHeaders::OPT_OUT` will disable the header entirely.

**Word of caution:**  The following is not a default configuration per se. It serves as a sample implementation of the configuration. You should read more about these headers and determine what is appropriate for your requirements.

```ruby
SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # mark all cookies as "Secure"
    httponly: true, # mark all cookies as "HttpOnly"
    samesite: {
      lax: true # mark all cookies as SameSite=lax
    }
  }
  # Add "; preload" and submit the site to hstspreload.org for best protection.
  config.hsts = "max-age=#{1.week.to_i}"
  config.x_frame_options = "DENY"
  config.x_content_type_options = "nosniff"
  config.x_xss_protection = "1; mode=block"
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = %w(origin-when-cross-origin strict-origin-when-cross-origin)
  config.csp = {
    # "meta" values. these will shape the header, but the values are not included in the header.
    preserve_schemes: true, # default: false. Schemes are removed from host sources to save bytes and discourage mixed content.
    disable_nonce_backwards_compatibility: true, # default: false. If false, `unsafe-inline` will be added automatically when using nonces. If true, it won't. See #403 for why you'd want this.

    # directive values: these values will directly translate into source directives
    default_src: %w('none'),
    base_uri: %w('self'),
    block_all_mixed_content: true, # see http://www.w3.org/TR/mixed-content/
    child_src: %w('self'), # if child-src isn't supported, the value for frame-src will be set.
    connect_src: %w(wss:),
    font_src: %w('self' data:),
    form_action: %w('self' github.com),
    frame_ancestors: %w('none'),
    img_src: %w(mycdn.com data:),
    manifest_src: %w('self'),
    media_src: %w(utoob.com),
    object_src: %w('self'),
    sandbox: true, # true and [] will set a maximally restrictive setting
    plugin_types: %w(application/x-shockwave-flash),
    script_src: %w('self'),
    style_src: %w('unsafe-inline'),
    worker_src: %w('self'),
    upgrade_insecure_requests: true, # see https://www.w3.org/TR/upgrade-insecure-requests/
    report_uri: %w(https://report-uri.io/example-csp)
  }
  # This is available only from 3.5.0; use the `report_only: true` setting for 3.4.1 and below.
  config.csp_report_only = config.csp.merge({
    img_src: %w(somewhereelse.com),
    report_uri: %w(https://report-uri.io/example-csp-report-only)
  })
end
```

## Default values

All headers except for PublicKeyPins and ClearSiteData have a default value. The default set of headers is:

```
Content-Security-Policy: default-src 'self' https:; font-src 'self' https: data:; img-src 'self' https: data:; object-src 'none'; script-src https:; style-src 'self' https: 'unsafe-inline'
Strict-Transport-Security: max-age=631138519
X-Content-Type-Options: nosniff
X-Download-Options: noopen
X-Frame-Options: sameorigin
X-Permitted-Cross-Domain-Policies: none
X-Xss-Protection: 1; mode=block
```

## API configurations

Which headers you decide to use for API responses is entirely a personal choice. Things like X-Frame-Options seem to have no place in an API response and would be wasting bytes. While this is true, browsers can do funky things with non-html responses. At the minimum, we suggest CSP:

```ruby
SecureHeaders::Configuration.override(:api) do |config|
  config.csp = { default_src: 'none' }
  config.hsts = SecureHeaders::OPT_OUT
  config.x_frame_options = SecureHeaders::OPT_OUT
  config.x_content_type_options = SecureHeaders::OPT_OUT
  config.x_xss_protection = SecureHeaders::OPT_OUT
  config.x_permitted_cross_domain_policies = SecureHeaders::OPT_OUT
end
```

However, I would consider these headers anyways depending on your load and bandwidth requirements.

## Acknowledgements

This project originated within the Security team at Twitter. An archived fork from the point of transition is here: https://github.com/twitter-archive/secure_headers.

Contributors include:
* Neil Matatall @oreoshake
* Chris Aniszczyk
* Artur Dryomov
* Bjørn Mæland
* Arthur Chiu
* Jonathan Viney
* Jeffrey Horn
* David Collazo
* Brendon Murphy
* William Makley
* Reed Loden
* Noah Kantrowitz
* Wyatt Anderson
* Salimane Adjao Moustapha
* Francois Chagnon
* Jeff Hodges
* Ian Melven
* Darío Javier Cravero
* Logan Hasson
* Raul E Rangel
* Steve Agalloco
* Nate Collings
* Josh Kalderimis
* Alex Kwiatkowski
* Julich Mera
* Jesse Storimer
* Tom Daniels
* Kolja Dummann
* Jean-Philippe Doyle
* Blake Hitchcock
* vanderhoorn
* orthographic-pedant
* Narsimham Chelluri

If you've made a contribution and see your name missing from the list, make a PR and add it!

## Similar libraries

* Rack [rack-secure_headers](https://github.com/frodsan/rack-secure_headers)
* Node.js (express) [helmet](https://github.com/helmetjs/helmet) and [hood](https://github.com/seanmonstar/hood)
* Node.js (hapi) [blankie](https://github.com/nlf/blankie)
* J2EE Servlet >= 3.0 [headlines](https://github.com/sourceclear/headlines)
* ASP.NET - [NWebsec](https://github.com/NWebsec/NWebsec/wiki)
* Python - [django-csp](https://github.com/mozilla/django-csp) + [commonware](https://github.com/jsocol/commonware/); [django-security](https://github.com/sdelements/django-security)
* Go - [secureheader](https://github.com/kr/secureheader)
* Elixir [secure_headers](https://github.com/anotherhale/secure_headers)
* Dropwizard [dropwizard-web-security](https://github.com/palantir/dropwizard-web-security)
* Ember.js [ember-cli-content-security-policy](https://github.com/rwjblue/ember-cli-content-security-policy/)
* PHP [secure-headers](https://github.com/BePsvPT/secure-headers)
