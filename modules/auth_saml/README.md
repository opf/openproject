# OpenProject OmniAuth SAML Single-Sign On

![](https://github.com/finnlabs/openproject-auth_saml/blob/dev/app/assets/images/auth_provider-saml.png)

This plugin provides the [OmniAuth SAML strategy](https://github.com/omniauth/omniauth-saml) into OpenProject.

## Configuration

The configuration can be provided in one of three ways:

* configuration.yml file
* Environment variables
* settings.yml file

Whatever means are chosen, the plugin simply passes all options to omniauth-saml. See [their configuration
documentation](https://github.com/omniauth/omniauth-saml#usage) for further details.

### configuration.yml file

The file

```bash
config/configuration.yml
```

can be extended to include the necessary settings. Everything belonging to the `saml` key will be made available to the plugin.

```yaml
saml:
  my_saml:
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
```

### Environment variables

As with all the rest of the OpenProject configuration settings, the saml configuration can be provided via environment variables.

E.g.

```bash
OPENPROJECT_SAML_MY__SAML_NAME="your-provider-name"
OPENPROJECT_SAML_MY__SAML_DISPLAY__NAME="My SAML provider"
...
OPENPROJECT_SAML_MY__SAML_ATTRIBUTE__STATEMENTS_ADMIN="['openproject-isadmin']"
```

Please note that every underscore (`_`) in the original configuration key has to be replaced by a duplicate underscore
(`__`) in the environment variable as the single underscore denotes namespaces.

### settings.yml file

For backwards compatibility, having a dedicated settings.yml is also supported.

To add your own SAML strategy provider(s), create the following settings file (relative to your OpenProject root):

```bash
config/plugins/auth_saml/settings.yml
```
	
with the following contents:

```yaml
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
```

The plugin simply passes all options to omniauth-saml. See [their configuration
documentation](https://github.com/omniauth/omniauth-saml#usage) for further
details.

### Custom Provider Icon

To add a custom icon to be rendered as your omniauth provider icon, add an
image asset to OpenProject and reference it in your `settings.yml`:

```bash
icon: "my/asset/path/to/icon.png"
```
