# Create an OmniAuth plugin

The OpenProject core integrates OmniAuth. This means that OmniAuth providers can be used to authenticate OpenProject users. For the time being this is not possible for existing users but only for new users who register using that particular provider.

This page describes how to create an OpenProject plugin to authenticate users via an Omniauth strategy.

## Warning

This howto is in a preliminary state and explains a low-level way to create an OmniAuth authentication plugin for OpenProject. We will provide a more high-level API and update this howto soon.

## OpenID Connect

There is a bare minimum [plugin](https://github.com/machisuji/openproject-mock_auth) implementing a mock strategy for OpenProject using the provided OmniAuth infrastructure. You can refer to this plugin and compare to see how things can be done.

## Terminology

### Strategy

An OmniAuth strategy implements a certain way of authentication. Examples for this are LDAP, OAuth and OpenID Connect strategies.

### Provider

An OmniAuth provider uses an OmniAuth strategy in order to authenticate a user against a certain service.
For instance there can be two providers that both use the OpenID Connect strategy but for different services.

## To do

Any authentication plugin has to do at least the following things:

1. Create plugin settings (e.g. for server-side secrets) if necessary
2. Register its authentication provider(s) with OmniAuth
3. Render a sign-in link for each provider on the login page and the login drop down menu

## Authentication Plugin How-to

In the following section we will go through the basic steps required to create an authentication plugin for OpenProject.

### Generate a plugin

First off you can use the [plugin generator](https://github.com/opf/openproject-plugins) to create a basic plugin to base yours on.
How to do that is described [here](https://www.openproject.org/development/create-openproject-plugin/). In short it’s the following command:

```bash
# in OpenProject directory
rails generate open_project:plugin my_auth_plugin path/to/where/you/want/to/have/it
```

Let’s assume that the plugin you generated is called `openproject-my_auth_plugin`.

### Implement the strategy

This is specific to your plugin. There may already be a gem implementing a strategy for the service you want to use.
In that case you can skip this step and use an existing gem. Just google ‘omniauth <service>’ and chances are that you will find one.
E.g. for twitter ‘omniauth twitter’ will lead you to [this](https://github.com/arunagw/omniauth-twitter) quickly.

### Register required settings

If you want to use settings for your plugin in order to configure your authentication provider you will have to register them in `lib/open_project/my_auth_plugin/engine.rb` by adding them to the already generated plugin registration call like this:

```
register 'openproject-my_auth_plugin',
  :author_url => 'Hans Wurst',
  :requires_openproject => '>= 3.1.0',
  :settings => { 'default' => { 'auth_server_address' => {'192.168.178.42'} } }
```

You can access your plugin’s settings like this:

```
server_addr = Setting.plugin_openproject_my_auth_plugin["auth_server_address"]
```

### Register the provider(s)

For this you can use the [openproject-auth_plugins](https://github.com/opf/openproject-auth_plugins) plugin, which provides you with an easy way to integrate a new authentication plugin into OpenProject.
As described in the plugin’s readme file you just add the following bit to the class body of Engine:

```ruby
register_auth_providers do
  strategy :my_auth_plugin_strategy do
    [
      {
        name: 'my_provider',
        display_name: 'Optional Label', # (optional) provider's name as shown in OpenProject
        icon: 'my_auth_plugin/optional_provider_icon.png', # (optional) provider icon
        # example options depending on your strategy:
        host: Setting.plugin_openproject_my_auth_plugin["auth_server_address"]
      }
    ]
  end
end
```

OmniAuth will try to look up a strategy based on the passed symbol `:my_auth_plugin_strategy`, meaning that in this case it would expect a strategy class to be defined as follows:

```ruby
module OmniAuth
  module Strategies
    class MyAuthPluginStrategy
      # ...
```

You can register any number of providers using different strategies (or the same) with different options.
For instance you could configure two OpenID Connect providers using the same strategy (OpenIDConnect) but with different options according to the service to be used (e.g. Google vs Microsoft).

### Add your plugin to Gemfile.plugins

All that’s that left to do is declaring your plugin in the file `Gemfile.plugins` in your OpenProject application’s root directory.
If you haven’t published it as a gem yet you can also use a local copy:

```
  gem "openproject-auth_plugins", :git => 'https://github.com/opf/openproject-auth_plugins.git', :branch => 'dev'
  gem 'openproject-my_auth_plugin', :path => 'plugins/openproject-my_auth_plugin'
```

Also don’t forget to include the `openproject-auth_plugins` as a dependency in your plugin’s gem specification (`openproject-my_auth_plugin.gemspec`).
The first line in the snippet shown above is only necessary because the `openproject-auth_plugins` plugin itself has not been published as a gem yet.

### Profit

That’s it. Now users can authenticate using your own provider.

