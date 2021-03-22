# Custom OpenID Connect providers

OpenProject's admin interface only allows you to configure providers from a pre-defined list.
This includes Google and Azure right now.

You can still use an arbitrary provider. But for the time being there is no user interface for this.
That means you will have to do it directly using the console on the server.

<div class="alert alert-info" role="alert">

**Warning**: Only do this if you know what you are doing. This may break your existing OpenID Connect authentication or cause other issues otherwise.

</div>

First start the console.

```
sudo openproject run console
```

Once in the console you can change the `plugin_openproject_openid_connect` setting
directly to configure arbitrary providers.

Next define the settings for your custom provider. In this example we are configuring Okta:

```ruby
options = {
  "display_name"=>"Okta",
  "host"=>"mypersonal.okta.com",
  "identifier"=>"<identifier>",
  "secret"=>"<secret>",
  "authorization_endpoint" => "/oauth2/v1/authorize",
  "token_endpoint" => "/oauth2/v1/token",
  "userinfo_endpoint" => "/oauth2/v1/userinfo"
}
```

Just type this into the console and confirm by pressing *Enter*.

This assumes that you have configured your application in the respective provider correctly
including the **redirect URL** which will be the following:

```ruby
"#{Setting.protocol}://#{Setting.host_name}/auth/okta/callback"
```

You can copy that into the console to get the URL you need.

Finally you can the write the actual setting like this:

```ruby
Setting.plugin_openproject_openid_connect = Hash(Setting.plugin_openproject_openid_connect).deep_merge({
  "providers" => {
    "okta" => options
  }
})
```

Just copy these lines into the console and again confirm using *Enter*.
After you are done you can leave the console by entering `exit`.

Once this is done you will see an "Okta" button in the bottom area of the login form.
Clicking on it will start the login process.

_**Note**: This is an Enterprise Edition feature. If you do not see the button you will have to activate the Enterprise Edition first._

## More options

You can see a list of possible options [here](https://github.com/m0n9oose/omniauth_openid_connect#options-overview).

### Claims

You can also request [claims](https://openid.net/specs/openid-connect-core-1_0-final.html#Claims) for both the id_token and userinfo endpoint.
Mind though that currently only claims requested for the id_token returned with the authorize response are validated.
That is authentication will fail if a requested essential claim is not returned.

#### Requesting MFA authentication via the ACR claim

Say for example that you want to request that the user authenticate using MFA (multi-factor authentication).
You can do this by using the ACR (Authentication Context Class Reference) claim.

This may look different for each identity provider. But if they follow, for instance the [EAP (Extended Authentication Profile)](https://openid.net/specs/openid-connect-eap-acr-values-1_0.html) then the claims would be `phr` (phishing-resistant) and 'phrh' (phishing-resistant hardware-protected). Others may simply have an additional claim called `Multi_Factor`.

You have to check with your identity provider how these values must be called.

In the following example we request a list of ACR values. One of which must be satisfied
(i.e. returned in the ID token by the identity provider, meaning that the requested authentication mechanism was used)
for the login in OpenProject to succeed. If none of the requested claims are present, authentication will fail.

```ruby
options = { ... }

options["claims"] = {
  "id_token": {
    "acr": {
      "essential": true,
      "values": ["phr", "phrh", "Multi_Factor"]
    }
  }
}
```

#### Non-essential claims

You may also request non-essential claims. In the example above this indicates that users should preferably be authenticated using
those mechanisms but it's not strictly required. The login into OpenProject will then work even if none of the claims
are returned by the identity provider.

**The acr_values option**

For non-essential ACR claims you can also use the shorthand form of the option like this:

```ruby
options = { ... }

options["acr_values"] = "phr phrh Multi_Factor"
```

The option takes a space-separated list of ACR values. This is functionally the same as using the
more complicated `claims` option above but with `"essential": false`.

For all other claims there is no such shorthand.
