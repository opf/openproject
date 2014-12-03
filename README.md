# OpenProject OpenID Connect Plugin

Adds support for OmniAuth OpenID Connect strategy providers, most importantly Google.

## Dependencies

You will have to add the following lines to your OpenProject's _Gemfile.plugins_ for the time being (omit aleady existing ones):

    gem "openproject-auth_plugins", :git => 'git@github.com:finnlabs/openproject-auth_plugins', :branch => 'dev'
    gem 'omniauth-openid-connect', :git => 'git@github.com:finnlabs/omniauth-openid-connect.git', :branch => 'master'
    gem 'omniauth-openid-connect-providers', :git => 'git@github.com:finnlabs/omniauth-openid-connect-providers.git', :branch => 'dev'
    gem 'openproject-openid_connect', :git => 'git@github.com:finnlabs/openproject-openid_connect.git', :branch => 'dev'

### Development

If you want to run the tests you will have add the following as well:

    group :test do
  	  gem 'rspec-steps', '~> 0.4.0'
  	end

## Configuration

The provider configuration can be either done in `configuration.yml` or within the settings.

### configuration.yml

Example configuration:

    default:
      openid_connect:
  	    google:
          identifier: "9295222hfbiu2btgu3b4i.apps.googleusercontent.com"
          secret: "4z389thugh334t8h"
          icon: "openid_connect/auth_provider-google.png"
          display_name: "Google"

The last two attributes are commonly available for all providers.
They are used to change a provider's look.

Note that `openid_connect/auth_provider-google.png` is the one custom provider icon this plugin has out of the box. Other icons you will have to add yourself.

`display_name` changes a provider's label shown to the user.

### Settings

There is no UI for the settings just yet. One way to set them until then is the rails console:

    Setting["plugin_openproject_openid_connect"] = {
      "providers" => {
        "google" => {
          "identifier" => "9295222hfbiu2btgu3b4i.apps.googleusercontent.com",
          "secret" => "4z389thugh334t8h"
        },
        "heroku" => {
          "identifier" => "foobar",
          "secret" => "baz"
        }
      }
    }

While Google and Heroku are pre-defined you can add arbitrary providers through configuration.
Those may then require the host and/or endpoints to be specified depending on whether or not a particular provider adheres to the default endpoint paths.

    Setting["plugin_openproject_openid_connect"] = {
      "providers" => {
        "myprovider" => {
          "host" => "login.myprovider.net",
          "identifier" => "9295222hfbiu2btgu3b4i.apps.googleusercontent.com",
          "secret" => "4z389thugh334t8h"
        },
        "yourprovider" => {
          "identifier" => "foobar",
          "secret" => "baz",
          "authorization_endpoint" => "https://auth.yourprovider.com/oauth2/authorize"
  		  "token_endpoint" => "https://auth.yourprovider.com/oauth2/token?api-version=1.0"
  		  "userinfo_endpoint" => "https://users.yourprovider.com/me"
        },
        "theirprovider" => {
          "identifier" => "foobar",
          "secret" => "baz",
          "host" => "signin.theirprovider.co.uk",
          "authorization_endpoint" => "/oauth2/authorization/new"
  		  "token_endpoint" => "/oauth2/tokens"
  		  "userinfo_endpoint" => "/oauth2/users/me"
        }
      }
    }

If a host is given, relative endpoint paths will refer to said host.
No host is required if absolute endpoint URIs are given.

The configuration of the pre-defined providers (currently Google and Heroku) can be overriden as well.

## Provider Client Registration

Client ID and secret are often provided by the provider, otherwise refer to the provider on how to create them.

Use the following scheme for creating a callback URL (you have to whitelist that URL at the provider):

    https://YOURAPP.example.org/auth/PROVIDER_NAME/callback

Replace `PROVIDER_NAME` with the key you used for the provider in the settings hash. So e.g. for an app running on openproject.example.org and authentication via Google, you can set up the following callback URL:

    https://openproject.example.org/auth/google/callback

## Provider SSL certificate validation

This plugin uses OpenSSL's default certificate store (on Linux you can ususally find it in `/etc/ssl/certs`).

If you want to use a different list of CAs for validating provider SSL certificates, you can set the environment variable `SSL_CERT_DIR` to another path containing CA certificates. Note that this environment variable is an OpenSSL feature, so it changes the CA list for all libraries using OpenSSL that don't explicitly specify another path.

## Credits

This plugin uses some of Neil Hainsworth' [Free Social Icons](http://www.neilorangepeel.com/free-social-icons/).
