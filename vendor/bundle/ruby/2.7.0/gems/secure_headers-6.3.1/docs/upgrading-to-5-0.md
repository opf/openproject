## All cookies default to secure/httponly/SameSite=Lax

By default, *all* cookies will be marked as `SameSite=lax`,`secure`, and `httponly`. To opt-out, supply `SecureHeaders::OPT_OUT` as the value for `SecureHeaders.cookies` or the individual configs. Setting these values to `false` will raise an error.

```ruby
# specific opt outs
config.cookies = {
  secure: SecureHeaders::OPT_OUT,
  httponly: SecureHeaders::OPT_OUT,
  samesite: SecureHeaders::OPT_OUT,
}

# nuclear option, just make things work again
config.cookies = SecureHeaders::OPT_OUT
```
