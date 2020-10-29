# Omniauth::OpenidConnect::Providers

This gem offers a convenient way to configure different OmniAuth OpenIDConnect providers.
It comes with preconfigured providers for Heroku and Google which take care of the necessary details.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-openid_connect-providers', git: 'git@github.com:finnlabs/omniauth-openid_connect-providers.git',
                                         branch: 'dev'
```

And then execute:

    $ bundle

While used in conjunction with `openid_connect` it does not technically depend on it.

## Usage

OmniAuth expects an options hash when registering a provider. For instance:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :openid_connect,
           name: 'google',
           scope: [:email, :openid, :profile]
           client_options: {
               host: 'accounts.google.com',
               identifier: 'myapp',
               secret: 'mysecret'
               redirect_uri: 'https://example.org/auth/google/callback',
               authorization_endpoint: '/o/oauth2/auth',
               token_endpoint: '/o/oauth2/token',
               userinfo_endpoint: 'https://www.googleapis.com/plus/v1/people/me/openIdConnect'
           }
end
```

With this gem you can make this a bit easier by using the respective provider or even a generic one:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  config = {
    identifier: 'myapp',
    secret: 'mysecret',
    redirect_uri: 'https://example.org/auth/google/callback'
  }
  p = OmniAuth::OpenIDConnect::Google.new 'google', config

  provider :openid_connect, p.to_h
end
```

You can still pass arbitrary client options inside the configuration to override default values or add new ones.

### Generic Providers

`Google` is just one of the available specific providers with custom options to make OpenIDConnect work with Google.
In general you can use the generic `OmniAuth::OpenIDConnect::Provider` class in the same way.

```ruby
OmniAuth::OpenIDConnect::Provider.new 'myservice', config
```

### Base Redirect URI

You can configure a base redirect URI to use for all providers.

```ruby
OmniAuth::OpenIDConnect::Providers.configure base_redirect_uri: 'https://example.org/'
```

This way you can also omit the redirect URI in the provider specific configuration.
The default redirect URI is constructed using the base URI. If your provider's redirect URI
is different from the default (`/auth/<name>/callback`) you can still override it on a per-provider basis
either directly in the configuration or as an option.

```ruby
p = OmniAuth::OpenIDConnect::Provider.new 'test', config, base_redirect_uri: 'https://example.net'
```

This way the configuration can omit the redirect URI and instead one will be generated using the default schema
which results in `https://example.net/auth/test/callback` here.
The difference to configuring the base redirect URI via `Providers` is that it is not global but only applies
to the created provider instance.

### Custom Options

The options in the root level of the hash given to OmniAuth cannot be extended through the configuration hash by default.
But if you want a provider to accept additional options there you can configure them using `OmniAuth::OpenIDConnect::Providers.configure`.
This way your provider will also accept the given options which are optional if ending with a `?` and required otherwise,
meaning an error will be raised if they are missing.

```ruby
OmniAuth::OpenIDConnect::Providers.configure custom_options: [:icon?, :display_name]

config = {
  display_name: 'My App'
  identifier: 'myapp',
  secret: 'mysecret',
  redirect_uri: 'https://example.org/auth/google/callback'
}
p = OmniAuth::OpenIDConnect::Google.new 'google', config

expect(p.to_h).to include('display_name')
```

Note that this as everything in `Providers` is a global configuration applying to all Provider instances.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/omniauth-openid_connect-providers/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
