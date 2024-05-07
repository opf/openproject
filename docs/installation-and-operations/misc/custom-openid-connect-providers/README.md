# Custom OpenID Connect providers

OpenProject's admin interface only allows you to configure providers from a pre-defined list.
This includes Google Workspace and Microsoft Azure Active Directory right now. Find out how to use those in the [OpenID Providers Authentication Guide](../../../system-admin-guide/authentication/openid-providers/).

You can still use an arbitrary provider. But for the time being there is no user interface for this.
That means you will have to do it directly using the console on the server or via environment variables.

> **Warning**: Only do this if you know what you are doing. This may break your existing OpenID Connect authentication or cause other issues otherwise.

First start the console.

```shell
sudo openproject run console
# if user the docker all-in-one container: docker exec -it openproject bundle exec rails console
# if using docker-compose: docker-compose run --rm web bundle exec rails console
```

Once in the console you can change the `plugin_openproject_openid_connect` setting
directly to configure arbitrary providers.

Next define the settings for your custom provider. In this example we are configuring Okta:

```ruby
options = {
  "display_name"=>"Okta",
  "host"=>"mypersonal.okta.com",
  "identifier"=>"<identifier or client id>",
  "secret"=>"<secret>",
  "authorization_endpoint" => "/oauth2/v1/authorize",
  "token_endpoint" => "/oauth2/v1/token",
  "userinfo_endpoint" => "/oauth2/v1/userinfo",
  "end_session_endpoint" => "https://mypersonal.okta.com/oauth2/{authorizationServerId}/v1/logout"
}
```

For Keycloak, settings similar to the following would be used:

```ruby
options = {
  "display_name"=>"Keycloak",
  "host"=>"keycloak.example.com",
  "identifier"=>"<client id>",
  "secret"=>"<client secret>",
  "authorization_endpoint" => "/auth/realms/REALM/protocol/openid-connect/auth",
  "token_endpoint" => "/auth/realms/REALM/protocol/openid-connect/token",
  "userinfo_endpoint" => "/auth/realms/REALM/protocol/openid-connect/userinfo"
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
Setting.plugin_openproject_openid_connect = Hash(Setting.plugin_openproject_openid_connect || {}).deep_merge({
  "providers" => {
    "okta" => options
  }
})
```

Replace "okta" with any other value such as "keycloak". It is used as the identifier in some URLs so keep it a plain lowercase string.

Just copy these lines into the console and again confirm using *Enter*.
After you are done you can leave the console by entering `exit`.

Once this is done you will see an "Okta" button in the bottom area of the login form.
Clicking on it will start the login process.

_**Note**: This is an Enterprise add-on. If you do not see the button you will have to activate the Enterprise edition first._

## Environment variables

Rather than setting these options via the rails console, you can also define them through the
[OpenProject configuration](../../configuration/) which can
also be defined through
[environment variables](../../configuration/environment/).

The variable names can be derived from the options seen above. All variables will start with the prefix
`OPENPROJECT_OPENID__CONNECT_` followed by the provider name. For instance the okta example from above would
be defined via environment variables like this:

```shell
OPENPROJECT_OPENID__CONNECT_OKTA_DISPLAY__NAME="Okta"
OPENPROJECT_OPENID__CONNECT_OKTA_HOST="mypersonal.okta.com"
OPENPROJECT_OPENID__CONNECT_OKTA_IDENTIFIER="<identifier or client id>"
# etc.
```

**Note**: Underscores in option names must be escaped by doubling them. So make sure to really do use two consecutive
underscores in `DISPLAY__NAME`, `TOKEN__ENDPOINT` and so forth.

## More options

You can see a list of possible options [here](https://github.com/m0n9oose/omniauth_openid_connect#options-overview).

### Known providers and multiple connection per provider

There are a number of known providers where the endpoints are configured automatically based on the provider name in the configuration. All that is required are the client ID (identifier) and secret in that case.

If you want to configure multiple connections using the same provider you can prefix an arbitrary name with the
provider name followed by a period. For instance, if you want to configure 2 AzureAD connections and 1 Google connection it would look like this:

```ruby
Setting.plugin_openproject_openid_connect = Hash(Setting.plugin_openproject_openid_connect || {}).deep_merge({
  "providers" => {
    "azure.dept1" =>  { "display_name"=>"Department 1","identifier"=>"...","secret"=>"..." },
    "azure.dept2" =>  { "display_name"=>"Department 2","identifier"=>"...","secret"=>"..." },
    "google" =>  { "display_name"=>"Google","identifier"=>"...","secret"=>"..." }
  }
})
```

At the time of writing the known providers are: `azure`, `google`, `okta`

### Attribute mapping

You can override the default attribute mapping for values derived from the userinfo endpoint. For example, let's map the OpenProject login to the claim `preferred_username` that is sent by many OIDC providers.

```ruby
options = { 
  # ... other options
  attribute_map: {
    'login' => 'preferred_username'
  }
}
```

### Back-channel logout

OpenProject OIDC integration supports [back-channel logouts](https://openid.net/specs/openid-connect-backchannel-1_0.html) if OpenProject is configured for ActiveRecord based sessions (which is the default).

On the identity provider side, you need to set `https://<OpenProject host>/auth/<provider>/backchannel-logout`. `<provider>` is the identifier of the OIDC configuration as provided above.

#### Respecting self-registration

You can configure OpenProject to restrict which users can register on the system with the [authentication self-registration setting](../../../system-admin-guide/authentication/authentication-settings)

 By default, users returning from a SAML idP will be automatically created. If you'd like for the SAML integration to respect the configured self-registration option, please use setting `limit_self_registration`:

```ruby
options = { 
  # ... other options
  limit_self_registration: true
}
```

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

## Instructions for common OIDC providers

The following section contains instructions for common OpenID Connect providers. Feel free to contribute your settings through the editing functionality at the bottom of this page.

### Keycloak

In Keycloak, use the following steps to set up a OIDC integration for OpenProject:

- Select or create a realm you want to authenticate OpenProject with. Remember that realm identifier. For the remainder of this section, we're using REALM as the placeholder you'll need to replace.
- Under "Clients" menu, click on "Create" or "Create client"
- **Add client**: Enter the following details
  - **Client type / protocol**: OpenID Connect
  - **Client ID**: `https://<Your OpenProject hostname>`
  - **Name**:  Choose any name, used only within keycloak
- For the **Capability config**, keep Standard flow checked. In our tested version of Keycloak, this was the default.
- Click on Save

You will be forwarded to the settings tab  of the new client. Change these settings:

- Set **Valid redirect URIs** to `https://<Your OpenProject hostname>/auth/keycloak/*`
- Enable **Sign Documents**
- If you want to enable [Backchannel logout](https://openid.net/specs/openid-connect-backchannel-1_0.html), set **Backchannel logout URL** to `https://<Your OpenProject hostname>/auth/keycloak/backchannel-logout`

Next, you will need to create or note down the client secret for that client.

- Go to the **Credentials** tab
- Click on the copy to clipboard button next to **Client secret** to copy that value

**OPTIONAL:** By default, OpenProject will map the user's email to the login attribute in OpenProject. If you want to change that, you can do it by providing an alternate claim value in Keycloak:

- Go to **Client scopes**
- Click on the `https://<Your OpenProject hostname>-dedicated` scope
- Click on **Add mapper** and **By configuration**
- Select **User property**
- Assuming you want to provide the username as `preferred_username` to OpenProject, set these values. This will depend on what attribute you want to map:
  - Set name and to `username`
  - Set Token claim name to `preferred_username`
- Click on **Save**

#### Setting up OpenProject for Keycloak integration

In OpenProject, these are the variables you will need to set. Please refer to the above documentation for the different ways you can configure these variables:

```shell
# The name of the login button in OpenProject, you can freely set this to anything you like
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_DISPLAY__NAME="Keycloak"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_HOST="<Hostname of the keycloak server>"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_IDENTIFIER="https://<Your OpenProject hostname>"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_SECRET="<The client secret you copied from keycloak>"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ISSUER="https://<Hostname of the keycloak server>/realms/<REALM>"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_AUTHORIZATION__ENDPOINT="/realms/<REALM>/protocol/openid-connect/auth"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_TOKEN__ENDPOINT="/realms/<REALM>/protocol/openid-connect/token"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_USERINFO__ENDPOINT="/realms/<REALM>/protocol/openid-connect/userinfo"
OPENPROJECT_OPENID__CONNECT_KEYCLOAK_END__SESSION__ENDPOINT="http://<Hostname of the keycloak server>/realms/<REALM>/protocol/openid-connect/logout"
# Optional, if you have created the client scope mapper as shown above
# OPENPROJECT_OPENID__CONNECT_KEYCLOAK_ATTRIBUTE__MAP_LOGIN="preferred_username"
```

### Azure with Microsoft Graph API

The Azure integration for OpenProject uses the previous userinfo endpoints, which for some tenants results in not being able to access the user's email attribute. [See this bug report for more information](https://community.openproject.org/projects/openproject/work_packages/45832). While our UI is still being extended to accept the new endpoints, you can manually configure Azure like follows.

**What you need from Azure**

Use our [Azure Active Directory guide](../../../system-admin-guide/authentication/openid-providers/#azure-active-directory) to create the OpenProject client and note down these values

- The Client ID you set up for OpenProject  (assumed to be `https://<OpenProject hostname>`)
- The client secret
- The tenant's UUID ([Please see this guide](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc) for more information on the tenant value)

#### Setting up OpenProject for Keycloak integration

In OpenProject, these are the variables you will need to set. Please refer to the above documentation for the different ways you can configure these variables:

```shell
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_DISPLAY__NAME="Azure"
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_HOST="login.microsoftonline.com"
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_IDENTIFIER="https://<Your OpenProject hostname>"
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_SECRET="<client secret>"
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_AUTHORIZATION__ENDPOINT="https://login.microsoftonline.com/%3CUUID%3E/oauth2/v2.0/authorize"
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_TOKEN__ENDPOINT="https://login.microsoftonline.com/%3CUUID%3E/oauth2/v2.0/token"
openproject config:set OPENPROJECT_OPENID__CONNECT_AZURE_USERINFO__ENDPOINT="https://graph.microsoft.com/oidc/userinfo"
```

Restart your OpenProject server and test the login button to see if it works.

## Troubleshooting

**Q: After clicking on a provider badge, I am redirected to a signup form that says a user already exists with that login.**

A: This can happen if you previously created user accounts in OpenProject with the same email than what is stored in the identity provider. In this case, if you want to allow existing users to be automatically remapped to the OIDC provider, you should do the following:

Spawn an interactive console in OpenProject. The following example shows the command for the packaged installation.
See [our process control guide](../../../installation-and-operations/operation/control/) for information on other installation types.

```shell
sudo openproject run console
> Setting.oauth_allow_remapping_of_existing_users = true
> exit
```

Then, existing users should be able to log in using their OIDC identity. Note that this works only if the user is using password-based authentication, and is not linked to any other authentication source (e.g. LDAP) or identity provider.

Note that this setting is set to true by default for new installations already.
