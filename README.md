# OpenProject AuthPlugins Plugin

Adds support for easy integration of OmniAuth strategy providers as a means to authenticate users in OpenProject.

## Usage

    gem 'openproject-auth_plugins', :git => 'git@github.com:finnlabs/openproject-auth_plugins', :branch => 'stable'

You can use this plugin to make an authentication plugin out of an ordinary OpenProject plugin.
The first step is to generate a new plugin.
Once you have done that it only takes a few additions to make it an authentication plugin.
Find your Engine class in `engine.rb`, let it extend `OpenProject::Plugin::AuthPlugin` and register the providers you want to use.

Here's an example of how that might look:

```ruby
module OpenProject::SomeAuthPlugin
  class Engine < ::Rails::Engine
    engine_name :openproject_some_auth_plugin

    include OpenProject::Plugins::ActsAsOpEngine
    extend OpenProject::Plugins::AuthPlugin # just add this ...

    register 'openproject-some_auth_plugin',
             author_url: 'http://my.site',
             requires_openproject: '>= 3.1.0pre1'

    assets %w(
      some_auth_plugin/some_provider.png
    )

    # to get #register_auth_providers:
    register_auth_providers do
      strategy :some_strategy do
        [
          {
            name: 'some_provider',
            host: 'foo.bar.baz',
            port: 999,
            #, ... more provider options
            icon: 'some_auth_plugin/some_provider.png'
          },
          {
            name: 'another_provider',
            host: 'foobar.biz',
            port: '692',
            #, ... more provider options
            display_name: 'Provider 2'
          }
        ]
      end

      strategy :another_strategy do
        [{name: 'yet_another_provider'}]
      end
    end
  end
end
```

Register each OmniAuth strategy by calling `strategy` with the strategy's name and returning the options for the providers using that strategy in the passed block. Provider options must at the very least contain a `name` that has to be unique among all strategies' providers. The rest depends on the used strategy.

**Additional provider attribute `icon`**

As you can see in the first registered provider you can also give a new option called `icon`.
Using this option you can define which icon is to be rendered for the given provider.
In the example our own plugin provides the icon. In the plugin's directory it has to be placed under `app/assets/images/some_auth_plugin/some_provider.png`.

**Additional provider attribute `display_name`**

Another extra attribute shown is `display_name`. While `name` is used to identify the provider in URLs `display_name` is what is shown to the user.

## OpenProject Integration

For each registered provider a button will be added to the OpenProject login screen as shown in the following example:

![OpenProject Login Screen](../screenshots/login_screen_en.png?raw=true "Login screen showing buttons for 6 providers.")

In this example an icon has only been defined for 'Google'.
All other providers just show a default icon.

### Runtime Changes

All used strategies have to be known at the start of the application.
Providers, however, can change arbitrarily at runtime.
The block passed to `#strategy` is called each time an authentication request is made.

## Repository

This repository contains two main branches:

* `dev`: The main development branch. We try to keep it stable in the sense of all tests are passing, but we don't recommend it for production systems.
* `stable`: Contains the latest stable release that we recommend for production use. Use this if you always want the latest version of this plugin.

## License

Copyright (C) 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See [doc/COPYRIGHT.md](doc/COPYRIGHT.md) for details.
