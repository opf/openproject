## 6.3.1

Fixes deprecation warnings when running under ruby 2.7

## 6.3.0

Fixes newline injection issue

## 6.2.0

Fixes semicolon injection issue reported by @mvgijssel see https://github.com/twitter/secure_headers/issues/418

## 6.1.2

Adds the ability to specify `SameSite=none` with the same configurability as `Strict`/`Lax` in order to disable Chrome's soon-to-be-lax-by-default state.

## 6.1.1

Adds the ability to disable the automatically-appended `'unsafe-inline'` value when nonces are used #404 (@will)

## 6.1

Adds support for navigate-to, prefetch-src, and require-sri-for #395

NOTE: this version is a breaking change due to the removal of HPKP. Remove the HPKP config, the standard is dead. Apologies for not doing a proper deprecate/major rev cycle :pray:

## 6.0

- See the [upgrading to 6.0](docs/upgrading-to-6-0.md) guide for the breaking changes.

## 5.0.5

- A release to deprecate `SecureHeaders::Configuration#get` in prep for 6.x

## 5.0.4

- Adds support for `nonced_stylesheet_pack_tag` #373 (@paulfri)

## 5.0.3

- Add nonced versions of Rails link/include tags #372 (@steveh)

## 5.0.2

- Updates `Referrer-Policy` header to support multiple policy values

## 5.0.1

- Updates `Expect-CT` header to use a comma separator between directives, as specified in the most current spec.

## 5.0.0

Well this is a little embarassing. 4.0 was supposed to set the secure/httponly/samesite=lax attributes on cookies by default but it didn't. Now it does. - See the [upgrading to 5.0](docs/upgrading-to-5-0.md) guide.

## 4.0.1

- Adds support for `worker-src` CSP directive to 4.x line (https://github.com/twitter/secureheaders/pull/364)

## 4.0

- See the [upgrading to 4.0](docs/upgrading-to-4-0.md) guide. Lots of breaking changes.

## 3.7.2

- Adds support for `worker-src` CSP directive to 3.x line (https://github.com/twitter/secureheaders/pull/364)

## 3.7.1

Fix support for the sandbox attribute of CSP. `true` and `[]` represent the maximally restricted policy (`sandbox;`) and validate other values.

## 3.7.0

Adds support for the `Expect-CT` header (@jacobbednarz: https://github.com/twitter/secureheaders/pull/322)

## 3.6.7

Actually set manifest-src when configured. https://github.com/twitter/secureheaders/pull/339 Thanks @carlosantoniodasilva!

## 3.6.5

Update clear-site-data header to use current format specified by the specification.

## 3.6.4

Fix case where mixing frame-src/child-src dynamically would behave in unexpected ways: https://github.com/twitter/secureheaders/pull/325

## 3.6.3

Remove deprecation warning when setting `frame-src`. It is no longer deprecated.

## 3.6.2

Now that Safari 10 supports nonces and it appears to work, enable the nonce feature for safari.

## 3.6.1

Improved memory use via minor improvements clever hacks that are sadly needed.
Thanks @carlosantoniodasilva!

## 3.6.0

Add support for the clear-site-data header

## 3.5.1

* Fix bug that can occur when useragent library version is older, resulting in a nil version sometimes.
* Add constant for `strict-dynamic`

## 3.5.0

This release adds support for setting two CSP headers (enforced/report-only) and management around them.


## 3.4.1 Named Appends

### Small bugfix

If your CSP did not define a script/style-src and you tried to use a script/style nonce, the nonce would be added to the page but it would not be added to the CSP. A workaround is to define a script/style src but now it should add the missing directive (and populate it with the default-src).

### Named Appends

Named Appends are blocks of code that can be reused and composed during requests. e.g. If a certain partial is rendered conditionally, and the csp needs to be adjusted for that partial, you can create a named append for that situation. The value returned by the block will be passed into `append_content_security_policy_directives`. The current request object is passed as an argument to the block for even more flexibility.

```ruby
def show
  if include_widget?
    @widget = widget.render
    use_content_security_policy_named_append(:widget_partial)
  end
end


SecureHeaders::Configuration.named_append(:widget_partial) do |request|
  if request.controller_instance.current_user.in_test_bucket?
    SecureHeaders.override_x_frame_options(request, "DENY")
    { child_src: %w(beta.thirdpartyhost.com) }
  else
    { child_src: %w(thirdpartyhost.com) }
  end
end
```

You can use as many named appends as you would like per request, but be careful because order of inclusion matters. Consider the following:

```ruby
SecureHeader::Configuration.default do |config|
  config.csp = { default_src: %w('self')}
end

SecureHeaders::Configuration.named_append(:A) do |request|
  { default_src: %w(myhost.com) }
end

SecureHeaders::Configuration.named_append(:B) do |request|
  { script_src: %w('unsafe-eval') }
end
```

The following code will produce different policies due to the way policies are normalized (e.g. providing a previously undefined directive that inherits from `default-src`, removing host source values when `*` is provided. Removing `'none'` when additional values are present, etc.):

```ruby
def index
  use_content_security_policy_named_append(:A)
  use_content_security_policy_named_append(:B)
  # produces default-src 'self' myhost.com; script-src 'self' myhost.com 'unsafe-eval';
end

def show
  use_content_security_policy_named_append(:B)
  use_content_security_policy_named_append(:A)
  # produces default-src 'self' myhost.com; script-src 'self' 'unsafe-eval';
end
```

## 3.4.0 the frame-src/child-src transition for Firefox.

Handle the `child-src`/`frame-src` transition semi-intelligently across versions. I think the code best descibes the behavior here:

```ruby
if supported_directives.include?(:child_src)
  @config[:child_src] = @config[:child_src] || @config[:frame_src]
else
  @config[:frame_src] = @config[:frame_src] || @config[:child_src]
end
```

Also, @koenpunt noticed that we were [loading view helpers](https://github.com/twitter/secureheaders/pull/272) in a way that Rails 5 did not like.

## 3.3.2 minor fix to silence warnings when using rake

[@dankohn](https://github.com/twitter/secureheaders/issues/257) was seeing "already initialized" errors in his output. This change conditionally defines the constants.

## 3.3.1 bugfix for boolean CSP directives

[@stefansundin](https://github.com/twitter/secureheaders/pull/253) noticed that supplying `false` to "boolean" CSP directives (e.g. `upgrade-insecure-requests` and `block-all-mixed-content`) would still include the value.

## 3.3.0 referrer-policy support

While not officially part of the spec and not implemented anywhere, support for the experimental [`referrer-policy` header](https://w3c.github.io/webappsec-referrer-policy/#referrer-policy-header) was [preemptively added](https://github.com/twitter/secureheaders/pull/249).

Additionally, two minor enhancements were added this version:
1. [Warn when the HPKP report host is the same as the current host](https://github.com/twitter/secureheaders/pull/246). By definition any generated reports would be reporting to a known compromised connection.
1. [Filter unsupported CSP directives when using Edge](https://github.com/twitter/secureheaders/pull/247). Previously, this was causing many warnings in the developer console.

## 3.2.0 Cookie settings and CSP hash sources

### Cookies

SecureHeaders supports `Secure`, `HttpOnly` and [`SameSite`](https://tools.ietf.org/html/draft-west-first-party-cookies-07) cookies. These can be defined in the form of a boolean, or as a Hash for more refined configuration.

__Note__: Regardless of the configuration specified, Secure cookies are only enabled for HTTPS requests.

#### Boolean-based configuration

Boolean-based configuration is intended to globally enable or disable a specific cookie attribute.

```ruby
config.cookies = {
  secure: true, # mark all cookies as Secure
  httponly: false, # do not mark any cookies as HttpOnly
}
```

#### Hash-based configuration

Hash-based configuration allows for fine-grained control.

```ruby
config.cookies = {
  secure: { except: ['_guest'] }, # mark all but the `_guest` cookie as Secure
  httponly: { only: ['_rails_session'] }, # only mark the `_rails_session` cookie as HttpOnly
}
```

#### SameSite cookie configuration

SameSite cookies permit either `Strict` or `Lax` enforcement mode options.

```ruby
config.cookies = {
  samesite: {
    strict: true # mark all cookies as SameSite=Strict
  }
}
```

`Strict` and `Lax` enforcement modes can also be specified using a Hash.

```ruby
config.cookies = {
  samesite: {
    strict: { only: ['_rails_session'] },
    lax: { only: ['_guest'] }
  }
}
```

#### Hash

`script`/`style-src` hashes can be used to whitelist inline content that is static. This has the benefit of allowing inline content without opening up the possibility of dynamic javascript like you would with a `nonce`.

You can add hash sources directly to your policy :

```ruby
::SecureHeaders::Configuration.default do |config|
   config.csp = {
     default_src: %w('self')

     # this is a made up value but browsers will show the expected hash in the console.
     script_src: %w(sha256-123456)
   }
 end
 ```

 You can also use the automated inline script detection/collection/computation of hash source values in your app.

 ```bash
 rake secure_headers:generate_hashes
 ```

 This will generate a file (`config/secure_headers_generated_hashes.yml` by default, you can override by setting `ENV["secure_headers_generated_hashes_file"]`) containing a mapping of file names with the array of hash values found on that page. When ActionView renders a given file, we check if there are any known hashes for that given file. If so, they are added as values to the header.

```yaml
---
scripts:
  app/views/asdfs/index.html.erb:
  - "'sha256-yktKiAsZWmc8WpOyhnmhQoDf9G2dAZvuBBC+V0LGQhg='"
styles:
  app/views/asdfs/index.html.erb:
  - "'sha256-SLp6LO3rrKDJwsG9uJUxZapb4Wp2Zhj6Bu3l+d9rnAY='"
  - "'sha256-HSGHqlRoKmHAGTAJ2Rq0piXX4CnEbOl1ArNd6ejp2TE='"
```

##### Helpers

**This will not compute dynamic hashes** by design. The output of both helpers will be a plain `script`/`style` tag without modification and the known hashes for a given file will be added to `script-src`/`style-src` when `hashed_javascript_tag` and `hashed_style_tag` are used. You can use `raise_error_on_unrecognized_hash = true` to be extra paranoid that you have precomputed hash values for all of your inline content. By default, this will raise an error in non-production environments.

```erb
<%= hashed_style_tag do %>
body {
  background-color: black;
}
<% end %>

<%= hashed_style_tag do %>
body {
  font-size: 30px;
  font-color: green;
}
<% end %>

<%= hashed_javascript_tag do %>
console.log(1)
<% end %>
```

```
Content-Security-Policy: ...
 script-src 'sha256-yktKiAsZWmc8WpOyhnmhQoDf9G2dAZvuBBC+V0LGQhg=' ... ;
 style-src 'sha256-SLp6LO3rrKDJwsG9uJUxZapb4Wp2Zhj6Bu3l+d9rnAY=' 'sha256-HSGHqlRoKmHAGTAJ2Rq0piXX4CnEbOl1ArNd6ejp2TE=' ...;
```

## 3.1.2 Bug fix for regression

See https://github.com/twitter/secureheaders/pull/239

This meant that when header caches were regenerated upon calling `SecureHeaders.override(:name)` and using it with `use_secure_headers_override` would result in default values for anything other than CSP/HPKP.

## 3.1.1 Bug fix for regression

See https://github.com/twitter/secureheaders/pull/235

`idempotent_additions?` would return false when comparing `OPT_OUT` with `OPT_OUT`, causing `header_hash_for` to return a header cache with `{ nil => nil }` which cause the middleware to blow up when `{ nil => nil }` was merged into the rack header hash.

This is a regression in 3.1.0 only.

Now it returns true. I've added a test case to ensure that `header_hash_for` will never return such an element.

## 3.1.0 Adding secure cookie support

New feature: marking all cookies as secure. Added by @jmera in https://github.com/twitter/secureheaders/pull/231. In the future, we'll probably add the ability to whitelist individual cookies that should not be marked secure. PRs welcome.

Internal refactoring: In https://github.com/twitter/secureheaders/pull/232, we changed the way dynamic CSP is handled internally. The biggest benefit is that highly dynamic policies (which can happen with multiple `append/override` calls per request) are handled better:

1. Only the CSP header cache is busted when using a dynamic policy. All other headers are preserved and don't need to be generated. Dynamic X-Frame-Options changes modify the cache directly.
1. Idempotency checks for policy modifications are deferred until the end of the request lifecycle and only happen once, instead of per `append/override` call. The idempotency check itself is fairly expensive itself.
1. CSP header string is produced at most once per request.

## 3.0.3

Bug fix for handling policy merges where appending a non-default source value (report-uri, plugin-types, frame-ancestors, base-uri, and form-action) would be combined with the default-src value. Appending a directive that doesn't exist in the current policy combines the new value with `default-src` to mimic the actual behavior of the addition. However, this does not make sense for non-default-src values (a.k.a. "fetch directives") and can lead to unexpected behavior like a `report-uri` value of `*`. Previously, this config:

```
{
  default_src => %w(*)
}
```

When appending:

```
{
  report_uri => %w(https://report-uri.io/asdf)
}
```

Would result in `default-src *; report-uri *` which doesn't make any sense at all.

## 3.0.2

Bug fix for handling CSP configs that supply a frozen hash. If a directive value is `nil`, then appending to a config with a frozen hash would cause an error since we're trying to modify a frozen hash. See https://github.com/twitter/secureheaders/pull/223.

## 3.0.1

Adds `upgrade-insecure-requests` support for requests from Firefox and Chrome (and Opera). See [the spec](https://www.w3.org/TR/upgrade-insecure-requests/) for details.

## 3.0.0

secure_headers 3.0.0 is a near-complete, not-entirely-backward-compatible rewrite. Please see the [upgrade guide](https://github.com/twitter/secureheaders/blob/main/docs/upgrading-to-3-0.md) for an in-depth explanation of the changes and the suggested upgrade path.

## 2.5.1 - 2016-02-16 18:11:11 UTC - Remove noisy deprecation warning

See https://github.com/twitter/secureheaders/issues/203 and https://github.com/twitter/secureheaders/commit/cfad0e52285353b88e46fe384e7cd60bf2a01735

>> Upon upgrading to secure_headers 2.5.0, I get a flood of these deprecations when running my tests:
> [DEPRECATION] secure_header_options_for will not be supported in secure_headers

/cc @bquorning

## 2.5.0 - 2016-01-06 22:11:02 UTC - 2.x deprecation warning release

This release contains deprecation warnings for those wishing to upgrade to the 3.x series. With this release, fixing all deprecation warnings will make your configuration compatible when you decide to upgrade to the soon-to-be-released 3.x series (currently in pre-release stage).

No changes to functionality should be observed unless you were using procs as CSP config values.

## 2.4.4 - 2015-12-03 23:29:42 UTC - Bug fix release

If you use the `header_hash` method for setting your headers in middleware and you opted out of a header (via setting the value to `false`), you would run into an exception as described in https://github.com/twitter/secureheaders/pull/193

```
     NoMethodError:
       undefined method `name' for nil:NilClass
     # ./lib/secure_headers.rb:63:in `block in header_hash'
     # ./lib/secure_headers.rb:54:in `each'
     # ./lib/secure_headers.rb:54:in `inject'
     # ./lib/secure_headers.rb:54:in `header_hash'
```


## 2.4.3 - 2015-10-23 18:35:43 UTC - Performance improvement

@igrep reported an anti-patter in use regarding [UserAgentParser](https://github.com/ua-parser/uap-ruby). This caused UserAgentParser to reload it's entire configuration set *twice** per request. Moving this to a cached constant prevents the constant reinstantiation and will improve performance.

https://github.com/twitter/secureheaders/issues/187

## 2.4.2 - 2015-10-20 20:22:08 UTC - Bug fix release

A nasty regression meant that many CSP configuration values were "reset" after the first request, one of these being the "enforce" flag. See https://github.com/twitter/secureheaders/pull/184 for the full list of fields that were affected. Thanks to @spdawson for reporting this https://github.com/twitter/secureheaders/issues/183

## 2.4.1 - 2015-10-14 22:57:41 UTC - More UA sniffing

This release may change the output of headers based on per browser support. Unsupported directives will be omitted based on the user agent per request. See https://github.com/twitter/secureheaders/pull/179

p.s. this will likely be the last non-bugfix release for the 2.x line. 3.x will be a major change. Sneak preview: https://github.com/twitter/secureheaders/pull/181

## 2.4.0 - 2015-10-01 23:05:38 UTC - Some internal changes affecting behavior, but not functionality

If you leveraged `secure_headers` automatic filling of empty directives, the header value will change but it should not affect how the browser applies the policy. The content of CSP reports may change if you do not update your policy.

before
===

```ruby
  config.csp = {
    :default_src => "'self'"
  }
```
would produce `default-src 'self'; connect-src 'self'; frame-src 'self' ... etc.`

after
===

```ruby
  config.csp = {
    :default_src => "'self'"
  }
```

will produce `default-src 'self'`

The reason for this is that a `default-src` violation was basically impossible to handle. Chrome sends an `effective-directive` which helps indicate what kind of violation occurred even if it fell back to `default-src`. This is part of the [CSP Level 2 spec](http://www.w3.org/TR/CSP2/#violation-report-effective-directive) so hopefully other browsers will implement this soon.

Workaround
===

Just set the values yourself, but really a `default-src` of anything other than `'none'` implies the policy can be tightened dramatically. "ZOMG don't you work for github and doesn't github send a `default-src` of `*`???" Yes, this is true. I disagree with this but at the same time, github defines every single known directive that a browser supports so `default-src` will only apply if a new directive is introduced, and we'd rather fail open. For now.

```ruby
  config.csp = {
    :default_src => "'self'",
    :connect_src => "'self'",
    :frame_src => "'self'"
    ... etc.
  }
```

Besides, relying on `default-src` is often not what you want and encourages an overly permissive policy. I've seen it. Seriously. `default-src 'unsafe-inline' 'unsafe-eval' https: http:;` That's terrible.


## 2.3.0 - 2015-09-30 19:43:09 UTC - Add header_hash feature for use in middleware.

See https://github.com/twitter/secureheaders/issues/167 and https://github.com/twitter/secureheaders/pull/168

tl;dr is that there is a class method `SecureHeaders::header_hash` that will return a hash of header name => value pairs useful for merging with the rack header hash in middleware.

## 2.2.4 - 2015-08-26 23:31:37 UTC - Print deprecation warning for 1.8.7 users

As discussed in https://github.com/twitter/secureheaders/issues/154

## 2.2.3 - 2015-08-14 20:26:12 UTC - Adds ability to opt-out of automatically adding data: sources to img-src

See https://github.com/twitter/secureheaders/pull/161

## 2.2.2 - 2015-07-02 21:18:38 UTC - Another option for config granularity.

See https://github.com/twitter/secureheaders/pull/147

Allows you to override a controller method that returns a config in the context of the executing action.

## 2.2.1 - 2015-06-24 21:01:57 UTC - When using nonces, do not include the nonce for safari / IE

See https://github.com/twitter/secureheaders/pull/150

Safari will generate a warning that it doesn't support nonces. Safari will fall back to the `unsafe-inline`. Things will still work, but an ugly message is printed to the console.

This opts out safari and IE users from the inline script protection. I haven't verified any IE behavior yet, so I'm just assuming it doesn't work.

## 2.2.0 - 2015-06-18 22:01:23 UTC - Pass controller reference to callable config value expressions.

https://github.com/twitter/secureheaders/pull/148

Facilitates better per-request config:

 `:enforce => lambda { |controller| controller.current_user.beta_testing? }`

**NOTE** if you used `lambda` config values, this will raise an exception until you add the controller reference:

bad:

`lambda { true }`

good:

`lambda { |controller| true }`
`proc { true }`
`proc { |controller| true }`

## v2.1.0 - 2015-05-07 18:34:56 UTC - Add hpkp support

Includes https://github.com/twitter/secureheaders/pull/143 (which is really just https://github.com/twitter/secureheaders/pull/132) from @thirstscolr


## v2.0.2 - 2015-05-05 03:09:44 UTC - Add report_uri constant value

Just a small change that adds a constant that was missing as reported in https://github.com/twitter/secureheaders/issues/141

## v2.0.1 - 2015-03-20 18:46:47 UTC - View Helpers Fixed

Fixes an issue where view helpers (for nonces, hashes, etc) weren't available in views.

## 2.0.0 - 2015-01-23 20:23:56 UTC - 2.0

This release contains support for more csp level 2 features such as the new directives, the script hash integration, and more.

It also sets a new header by default: `X-Permitted-Cross-Domain-Policies`

Support for hpkp is not included in this release as the implementations are still very unstable.

:rocket:

## v.2.0.0.pre2 - 2014-12-06 01:55:42 UTC - Adds X-Permitted-Cross-Domain-Policies support by default

The only change between this and the first pre release is that the X-Permitted-Cross-Domain-Policies support is included.

## v1.4.0 - 2014-12-06 01:54:48 UTC - Deprecate features in preparation for 2.0

This removes the forwarder and "experimental" feature. The forwarder wasn't well maintained and created a lot of headaches. Also, it was using an outdated certificate pack for compatibility. That's bad. The experimental feature wasn't really used and it complicated the codebase a lot. It's also a questionably useful API that is very confusing.

## v2.0.0.pre - 2014-11-14 00:54:07 UTC - 2.0.0.pre - CSP level 2 support

This release is intended to be ready for CSP level 2. Mainly, this means there is direct support for hash/nonce of inline content and includes many new directives (which do not inherit from default-src)

## v1.3.4 - 2014-10-13 22:05:44 UTC -

* Adds X-Download-Options support
* Adds support for X-XSS-Protection reporting
* Defers loading of rails engine for faster boot times

## v1.3.3 - 2014-08-15 02:30:24 UTC - hsts preload confirmation value support

@agl just made a new option for HSTS representing confirmation that a site wants to be included in a browser's preload list (https://hstspreload.appspot.com).

This just adds a new 'preload' option to the HSTS settings to specify that option.

## v1.3.2 - 2014-08-14 00:01:32 UTC - Add app tagging support

Tagging Requests

It's often valuable to send extra information in the report uri that is not available in the reports themselves. Namely, "was the policy enforced" and "where did the report come from"
```ruby
{
  :tag_report_uri => true,
  :enforce => true,
  :app_name => 'twitter',
  :report_uri => 'csp_reports'
}
```
Results in
```
report-uri csp_reports?enforce=true&app_name=twitter
```
