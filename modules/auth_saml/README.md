# OpenProject OmniAuth SAML Single-Sign On

![](https://github.com/finnlabs/openproject-auth_saml/blob/dev/app/assets/images/auth_provider-saml.png)

This plugin provides the [OmniAuth SAML strategy](https://github.com/omniauth/omniauth-saml) into OpenProject.

## Installation

Add the following entries to your `Gemfile.plugins` in your OpenProject root directory:

    gem 'openproject-auth_plugins', git: 'https://github.com/finnlabs/openproject-auth_plugins', branch: 'stable'
    gem "openproject-auth_saml", git: 'https://github.com/finnlabs/openproject-auth_saml', branch: 'stable'

## Requirements

* [omniauth-saml gem](https://github.com/omniauth/omniauth-saml) >= 1.4.0
* [OpenProject](https://www.openproject.org) >= 5.0
* [openproject-auth_plugins](https://github.com/opf/openproject-auth_plugins)

## Configuration

To add your own SAML strategy provider(s), create the following settings file (relative to your OpenProject root):

	config/plugins/auth_saml/settings.yml
	
with the following contents:

    your-provider-name:
      name: "your-provider-name"
      display_name: "My SAML provider"
      # Use the default SAML icon
      icon: "auth_provider-saml.png"
      # omniauth-saml config
      assertion_consumer_service_url: "consumer_service_url"
      issuer: "issuer"
      idp_sso_target_url: "idp_sso_target_url"
      idp_cert_fingerprint: "E7:91:B2:E1:..."
      attribute_statements:
        email: ['mailPrimaryAddress']
        name: ['gecos']
        first_name: ['givenName']
        last_name: ['sn']
        admin: ['openproject-isadmin']

The plugin simply passes all options to omniauth-saml. See [their configuration
documentation](https://github.com/omniauth/omniauth-saml#usage) for further
details.

### Custom Provider Icon

To add a custom icon to be rendered as your omniauth provider icon, add an
image asset to OpenProject and reference it in your `settings.yml`:

	icon: "my/asset/path/to/icon.png"
	
## Copyrights & License

OpenProject SAML Auth is completely free and open source and released under the
[MIT
License](https://github.com/finnlabs/openproject-auth_saml/blob/dev/LICENSE).

Copyright (c) 2016 OpenProject GmbH

The default provider icon is a combination of icons from [Font Awesome by Dave Gandy](http://fontawesome.io).
