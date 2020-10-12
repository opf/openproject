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
You can see a full list of possible options [here](https://github.com/m0n9oose/omniauth_openid_connect#options-overview).

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
