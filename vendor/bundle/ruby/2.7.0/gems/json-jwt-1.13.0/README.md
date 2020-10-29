# JSON::JWT

JSON Web Token and its family (JSON Web Signature, JSON Web Encryption and JSON Web Key) in Ruby

[![Build Status](https://secure.travis-ci.org/nov/json-jwt.png)](http://travis-ci.org/nov/json-jwt)

## Installation

```
gem install json-jwt
```

## Resources

* View Source on GitHub (https://github.com/nov/json-jwt)
* Report Issues on GitHub (https://github.com/nov/json-jwt/issues)
* Documentation on GitHub (https://github.com/nov/json-jwt/wiki)

## Examples

```ruby
require 'json/jwt'

private_key = OpenSSL::PKey::RSA.new <<-PEM
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyBKIFSH8dP6bDkGBziB6RXTTfZVTaaNSWNtIzDmgRFi6FbLo
 :
-----END RSA PRIVATE KEY-----
PEM

public_key = OpenSSL::PKey::RSA.new <<-PEM
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyBKIFSH8dP6bDkGBziB6
 :
-----END PUBLIC KEY-----
PEM

# Sign & Encode
claim = {
  iss: 'nov',
  exp: 1.week.from_now,
  nbf: Time.now
}
jws = JSON::JWT.new(claim).sign(private_key, :RS256)
jws.to_s

# Decode & Verify
input = "jwt_header.jwt_claims.jwt_signature"
JSON::JWT.decode(input, public_key)
```

For more details, read [Documentation Wiki](https://github.com/nov/json-jwt/wiki).

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2011 nov matake. See LICENSE for details.
