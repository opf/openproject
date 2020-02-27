---
sidebar_navigation:
  title: SAML single sign-on
  priority: 800
description: How to set up SAML integration for SSO with OpenProject.
robots: index, follow
keywords: SAML, SSO, single sign-on, authentication
---
# SAML

<div class="alert alert-info" role="alert">
**Note**: This documentation is valid for the OpenProject Enterprise Edition only.
</div>

You can integrate your active directory or other SAML compliant identity provider in your OpenProject Enterprise Edition.

We rely on the OmniAuth SAML plugin for this integration. You will find more technical details about the configuration options used below [on their GitHub page](https://github.com/omniauth/omniauth-saml).



### Step 1: Creating the configuration file

In your OpenProject packaged installation, you need to add the `/opt/openproject/config/plugins/auth_saml.settings.yml` file. This will contain metadata settings and connection details for your SSO identity provider.

The following example can be used as a starting point to set up your integration:

```yaml
saml:
  name: "saml"
  display_name: "My SSO"
  # Use the default SAML icon
  icon: "auth_provider-saml.png"
  
  # omniauth-saml config
  assertion_consumer_service_url: "https:/<YOUR OPENPROJECT HOSTNAME>/auth/saml/callback"
  issuer: "https://<YOUR OPENPROJECT HOSTNAME>"
  
  # IF your SSL certificate on your SSO is not trusted on this machine, you need to add it here
  #idp_cert: "-----BEGIN CERTIFICATE-----\n ..... SSL CERTIFICATE HERE ...-----END CERTIFICATE-----\n"
  # Otherwise, the certificate fingerprint must be added
  # Either `idp_cert` or `idp_cert_fingerprint` must be present!
  idp_cert_fingerprint: "E7:91:B2:E1:...",
  
  # Replace with your single sign on URL
  # For example: "https://sso.example.com/saml/singleSignOn"
  idp_sso_target_url: "<YOUR SSO URL>"
  # Replace with your single sign out URL
  # or comment out
  # For example: "https://sso.example.com/saml/proxySingleLogout"
  idp_slo_target_url: "<YOUR SSO logout URL>"
  
  # Attribute map in SAML
  attribute_statements:
    # What attribute in SAML maps to email (default: mail)
    email: ['mail']
    # What attribute in SAML maps to the user login (default: uid)
    login: ['uid']
    # What attribute in SAML maps to the first name (default: givenName)
    first_name: ['givenName']
    # What attribute in SAML maps to the last name (default: sn)
    last_name: ['sn']
```

Fill out the file and restart your OpenProject server with `service openproject restart`. From there, you will see a "My SSO" login button when logging in. Clicking it will redirect to your SSO provider and return with your attribute data to set up the account, or to log in.

![my-sso](my-sso.png)



## Troubleshooting

Q: After clicking on a provider badge, I am redirected to a signup form that says a user already exists with that login.

A: This can happen if you previously created user accounts in OpenProject with the same email than what is stored in the OpenID provider. In this case, if you want to allow existing users to be automatically remapped to the OpenID provider, you should do the following:

```
sudo openproject run console
> Setting.oauth_allow_remapping_of_existing_users = true
> exit
```

Then, existing users should be able to log in using their Azure identity. Note that this works only if the user is using password-based authentication, and is not linked to any other authentication source (e.g. LDAP) or OpenID provider.