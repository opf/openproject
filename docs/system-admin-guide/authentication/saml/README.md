---
sidebar_navigation:
  title: SAML single sign-on
  priority: 100
description: How to set up SAML integration for SSO with OpenProject.
keywords: SAML, SSO, single sign-on, authentication
---
# SAML

> [!NOTE]
> This documentation is valid for the OpenProject Enterprise edition only.

You can integrate your active directory or other SAML compliant identity provider in your OpenProject Enterprise edition.

## Enterprise cloud

For the moment in the Enterprise cloud OpenProject DevOps team has to apply the configuration for you. The configuration has to be provided in a support ticket, e.g. as an ENV environment file.
Experience shows that configuring this can be tricky. So it may require some time until the correct configuration is finished with your SAML provider.
If you have the chance to test the SAML configuration on an Enterprise on-premises installation this might speed up the process. But we can make it work either way.

## Enterprise on-premises

### Prerequisites

In order to use integrate OpenProject as a service provider (SP) using SAML, your identity providers (idP):

- needs to be able to handle SAML 2.0 redirect Single-Sign On (SSO) flows, in some implementations also referred to as WebSSO
- has a known or configurable set of attributes that map to the following required OpenProject attributes. The way these attribute mappings will be defined is described later in this document.
  - **login**: A stable attribute used to uniquely identify the user. This will most commonly map to an account ID, samAccountName or email (but please note that emails are often interchangeable, and this might result in logins changing in OpenProject).
  - **email**: The email attribute of the user being authenticated
  - **first name** and **last name** of the user.
- provides the public certificate or certificate fingerprint (SHA1) in use for communicating with the idP.

### 1: Configure the SAML integration

The configuration can be provided in one of two ways:

* Environment variables (1.1)

* Settings in the database (1.2)

* for OpenProject version 11 and older in `config/configuration.yml` file (1.3)

Whatever means are chosen, the plugin simply passes all options to omniauth-saml. See [their configuration documentation](https://github.com/omniauth/omniauth-saml#usage) for further details.

The options are mutually exclusive. If you decide to save settings in the database, they will override any ENV variables you might have set. (*For OpenProject version 11 and older:* If settings are already provided via ENV variables, they will overwrite settings in a `configuration.yml` file.)

#### 1.1 Environment variables

As with [all the rest of the OpenProject configuration settings](../../../installation-and-operations/configuration/environment/), the SAML configuration can be provided via environment variables.

Example

```shell
# Name of the provider, leave this at saml unless you use multiple providers
OPENPROJECT_SAML_SAML_NAME="saml"

# The name that will be display in the login button
OPENPROJECT_SAML_SAML_DISPLAY__NAME="<Name of the login button>"

# The callback within OpenProject that your idP should redirect to
OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__URL="https://<openproject.host>/auth/saml/callback"

# The SAML issuer string that OpenProject will call your idP with
OPENPROJECT_SAML_SAML_ISSUER="https://<openproject.host>"

# IF your SSL certificate on your SSO is not trusted on this machine, you need to add it here in ONE line
### one liner to generate certificate in ONE line
### awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' <yourcert.pem>
#idp_cert: "-----BEGIN CERTIFICATE-----\n ..... SSL CERTIFICATE HERE ...-----END CERTIFICATE-----\n"
# Otherwise, the certificate fingerprint must be added
# Either `OPENPROJECT_SAML_SAML_IDP__CERT` or `OPENPROJECT_SAML_SAML_IDP__CERT__FINGERPRINT` must be present!
OPENPROJECT_SAML_SAML_IDP__CERT="-----BEGIN CERTIFICATE-----<cert one liner>-----END CERTIFICATE-----"
# If you  this environment variable through a shell, you will need to run it through C style quoting to preserve the newline
# Otherwise you will get an internal error with this log line "PEM_read_bio_X509: bad base64 decode"
# OPENPROJECT_SAML_SAML_IDP__CERT=$'-----BEGIN CERTIFICATE-----<cert one liner>-----END CERTIFICATE-----'

OPENPROJECT_SAML_SAML_IDP__CERT__FINGERPRINT="da:39:a3:ee:5e:6b:4b:0d:32:55:bf:ef:95:60:18:90:af:d8:07:09"
# Replace with your single sign on URL, the exact value depends on your idP implementation
OPENPROJECT_SAML_SAML_IDP__SSO__TARGET__URL="https://<hostname of your idp>/application/saml/<slug>/sso/binding/post/"

# (Optional) Replace with your redirect flow single sign out URL that we should redirect to
OPENPROJECT_SAML_SAML_IDP__SLO__TARGET__URL=""

# Which SAMLAttribute we should look for for the corresponding attributes of OpenProject
# can be a string or URI/URN depending on our idP format
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_EMAIL="[mail]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LOGIN="[mail]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_FIRST__NAME="[givenName]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LAST__NAME="[sn]"
# You can also specify multiple attributes, the first found value will be used. Example:
# OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LOGIN="['mail', 'samAccountName', 'uid']"
```

Please note that every underscore (`_`) in the original configuration key has to be replaced by a duplicate underscore
(`__`) in the environment variable as the single underscore denotes namespaces. For more information, follow our [guide on environment variables](../../../installation-and-operations/configuration/environment/).

#### 1.2 Settings in database

The SAML settings can also be changed at runtime in the database through the OpenProject settings.
As opposed to other settings there is no user interface for this.
That means it's best to set them using the console.

```shell
# package based installation:
> sudo openproject run console

# docker-based installation:
> docker exec -it openproject bundle exec rails console

# docker-compose-based installation:
> docker-compose run --rm web bundle exec rails console
```

Once on the console you can set the same values as named in the ENV environment file, however they need to be nested within a 'providers' key as follows.
For example:

```ruby
Setting.plugin_openproject_auth_saml = Hash(Setting.plugin_openproject_auth_saml).deep_merge({
  "providers" => {
    "saml" => {
      "name" => "saml",
      "display_name" => "My SSO",
      "assertion_consumer_service_url" => "https://<YOUR OPENPROJECT HOSTNAME>/auth/saml/callback",
      # The SAML issuer string that OpenProject will call your idP with
      "issuer" => "https://<YOUR OPENPROJECT HOSTNAME>",
      ### one liner to generate certificate in ONE line
      ### awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' <yourcert.pem>
      "idp_cert" => "-----BEGIN CERTIFICATE-----\nMI................IEr\n-----END CERTIFICATE-----\n",
      # Otherwise, the certificate fingerprint must be added
      # Either `idp_cert` or `idp_cert_fingerprint` must be present!
      "idp_cert_fingerprint" => "E7:91:B2:E1:...",

      # Replace with your SAML 2.0 redirect flow single sign on URL
      # For example: "https://sso.example.com/saml/singleSignOn"
      "idp_sso_target_url" => "<YOUR SSO URL>",
      # Replace with your redirect flow single sign out URL
      # or comment out
      # For example: "https://sso.example.com/saml/proxySingleLogout"
      "idp_slo_target_url" => "<YOUR SSO logout URL>",

      # Attribute map in SAML
      "attribute_statements" => {
        # What attribute in SAML maps to email (default: mail)
        "email" => ['mail'],
        # What attribute in SAML maps to the user login (default: uid)
        "login" => ['uid'],
        # What attribute in SAML maps to the first name (default: givenName)
        "first_name" => ['givenName'],
        # What attribute in SAML maps to the last name (default: sn)
        "last_name" => ['sn']
      }
    }
  }
})
```

#### 1.3 config/configuration.yml file

> [!IMPORTANT]
> ONLY for OpenProject version 11 and older

In your OpenProject packaged installation, you can modify the `/opt/openproject/config/configuration.yml` file.
Edit the file in your favorite editor

```shell
vim /opt/openproject/config/configuration.yml
```

This will contains the complete OpenProject configuration and can be extended to also contain metadata settings and connection details for your SSO identity provider.

The following is an exemplary file with a set of common settings:

```yaml
default:
  # <-- other configuration -->
  saml:
    # First SAML provider
    mysaml1:  
      # Name of the provider, leave this at saml unless you use multiple providers
      name: "saml"
      # The name that will be display in the login button
      display_name: "My SSO"
      # Use the default SAML icon
      icon: "auth_provider-saml.png"

      # The callback within OpenProject that your idP should redirect to
      assertion_consumer_service_url: "https://<YOUR OPENPROJECT HOSTNAME>/auth/saml/callback"
      # The SAML issuer string that OpenProject will call your idP with
      issuer: "https://<YOUR OPENPROJECT HOSTNAME>"

      # IF your SSL certificate on your SSO is not trusted on this machine, you need to add it here in ONE line
      ### one liner to generate certificate in ONE line
      ### awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' <yourcert.pem>
      #idp_cert: "-----BEGIN CERTIFICATE-----\n ..... SSL CERTIFICATE HERE ...-----END CERTIFICATE-----\n"
      # Otherwise, the certificate fingerprint must be added
      # Either `idp_cert` or `idp_cert_fingerprint` must be present!
      idp_cert_fingerprint: "E7:91:B2:E1:..."

      # Replace with your SAML 2.0 redirect flow single sign on URL
      # For example: "https://sso.example.com/saml/singleSignOn"
      idp_sso_target_url: "<YOUR SSO URL>"
      # Replace with your redirect flow single sign out URL
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
      
    # OPTIONAL: Additional SAML provider(s)
    #mysaml2:
    #  name: "saml2"
    #  display_name: "Additional SSO"
    #  (...)
    #mysaml3:
    #  (...)
```

Be sure to choose the correct indentation and base key. The items below the `saml` key should be indented two spaces more than `saml` already is. And `saml` can will need to be placed in the `default` or `production` group so it will already be indented. You will get an YAML parsing error otherwise when trying to start OpenProject.

### 2. Configuration details

In this section, we detail some of the required and optional configuration options for SAML.

#### 2.1 Mandatory: Response signature verification

SAML responses by identity providers are required to be signed. You can configure this by either specifying the response's certificate fingerprint in `idp_cert_fingerprint` , or by passing the entire PEM-encoded certificate string in `idp_cert` (beware of newlines and formatting the cert, [c.f. the idP certificate options in omniauth-saml](https://github.com/omniauth/omniauth-saml#options))

#### 2.2 Mandatory: Attribute mapping

Use the key `attribute_statements` to provide mappings for attributes returned by the SAML identity provider's response to OpenProject internal attributes.

You may provide attribute names or namespace URIs as follows: `email: ['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress']`.

The OpenProject username is taken by default from the `email` attribute if no explicit login attribute is present.

**a) Attribute mapping example for database**

```ruby
Setting.plugin_openproject_auth_saml = Hash(Setting.plugin_openproject_auth_saml).deep_merge({
  "providers" => {
    "saml" => {
       # ... other attributes, see above.
       # Attribute map in SAML
      "attribute_statements" => {
        # What attribute in SAML maps to email (default: mail)
        "email" => ['mail'],
        # another example for combined attributes in an array:
        "login" => ['username', 'samAccountName', 'uid'],
        # What attribute in SAML maps to the first name (default: givenName)
        "first_name" => ['givenName'],
        # What attribute in SAML maps to the last name (default: sn)
        "last_name" => ['sn']
      }
    }
  }
})
```

**b) Attribute mapping example for configuration.yml**

> [!IMPORTANT]
> ONLY for OpenProject version 11 and older

```yaml
default:
  # <-- other configuration -->
    mysaml1:
      # <-- other configuration -->
      # Attribute map in SAML
      attribute_statements:
        # Use the `mail` attribute for 
        email: ['mail']
        # Use the mail address as login
        login: ['mail']
        # What attribute in SAML maps to the first name (default: givenName)
        first_name: ['givenName']
        # What attribute in SAML maps to the last name (default: sn)
        last_name: ['sn']
```

#### 2.3 Optional: Set the attribute format

By default, the attributes above will be requested with the format `urn:oasis:names:tc:SAML:2.0:attrname-format:basic`.
That means the response should contain attribute names 'mail', etc. as configured above.

If you have URN or OID attribute identifiers, you can modify the request as follows:

> [!IMPORTANT]
> Example is ONLY for OpenProject version 11 and older and needs to be redesigned for ENV configuration

```yaml
default:
  # <-- other configuration -->
    mysaml1:
      # <-- other configuration -->
      # Modify the request attribute sent in the request
      # These oids are exemplary, but will often be identical,
      # please check with your identity provider for the correct oids
      request_attributes:
        - name: 'urn:oid:0.9.2342.19200300.100.1.3'
          friendly_name: 'Mail address'
          name_format: urn:oasis:names:tc:SAML:2.0:attrname-format:uri
        - name: 'urn:oid:2.5.4.42'
          friendly_name: 'First name'
          name_format: urn:oasis:names:tc:SAML:2.0:attrname-format:uri
        - name: 'urn:oid:2.5.4.4'
          friendly_name: 'Last name'
          name_format: urn:oasis:names:tc:SAML:2.0:attrname-format:uri

      # Attribute map in SAML
      attribute_statements:
        email: ['urn:oid:0.9.2342.19200300.100.1.3']
        login: ['urn:oid:0.9.2342.19200300.100.1.3']
        first_name: ['urn:oid:2.5.4.42']
        last_name: ['urn:oid:2.5.4.4']
```

#### 2.4 Optional: Request signature and Assertion Encryption

Your identity provider may optionally encrypt the assertion response, however note that with the required use of TLS transport security, in many cases this is not necessary. You may wish to use Assertion Encryption if TLS is terminated before the OpenProject application server (e.g., on the load balancer level).

To configure assertion encryption, you need to provide the certificate to send in the request and private key to decrypt the response:

> [!IMPORTANT]
> Example is ONLY for OpenProject version 11 and older and needs to be redesigned for ENV configuration

```yaml
default:
  # <-- other configuration -->
    mysaml1:
      # <-- other configuration -->
      certificate: "-----BEGIN CERTIFICATE-----\n .... certificate contents ....\n-----END CERTIFICATE-----"
      private_key: "-----BEGIN PRIVATE KEY-----\n .... private key contents ....\n-----END PRIVATE KEY-----"
```

Request signing means that the service provider (OpenProject in this case) uses the certificate specified to sign the request to the identity provider. They reuse the same `certificate` and `private_key` settings as for assertion encryption. It is recommended to use an RSA key pair, the key must be provided without password.

To enable request signing, enable the following flag:

> [!IMPORTANT]
> Example is ONLY for OpenProject version 11 and older and needs to be redesigned for ENV configuration

```yaml
default:
  # <-- other configuration -->
    mysaml1:
      # <-- other configuration -->
      certificate: "-----BEGIN CERTIFICATE-----\n .... certificate contents ....\n-----END CERTIFICATE-----"
      private_key: "-----BEGIN PRIVATE KEY-----\n .... private key contents ....\n-----END PRIVATE KEY-----"
      security:
        # Whether SP and idP should sign requests and assertions
        authn_requests_signed: true
        want_assertions_signed: true
        # Whether the idP should encrypt assertions
        want_assertions_signed: false
        embed_sign: true
        signature_method: 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'
        digest_method: 'http://www.w3.org/2001/04/xmlenc#sha256'
```

With request signing enabled, the certificate will be added to the identity provider to validate the signature of the service provider's request.

#### 2.5. Optional: Restrict who can automatically self-register

You can configure OpenProject to restrict which users can register on the system with the [authentication self-registration setting](../authentication-settings)

 By default, users returning from a SAML idP will be automatically created. If you'd like for the SAML integration to respect the configured self-registration option, please use this setting:

```yaml
default:
  # <-- other configuration -->
    mysaml1:
      # <-- other configuration -->
      limit_self_registration: true
```

#### 2.6. Optional: Set name_identifier_format

There are a number of name identifier formats that are relevant, so if you have specific requirements or configuration on the identity provider side, you might need to set the name_identifier_format property.

The default behavior would be to use the email Address like so:

```yaml
default:
  # <-- other configuration -->
    mysaml1:
      # <-- other configuration -->
      name_identifier_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
```

### 3: Restart the server

Once the configuration is completed, restart your OpenProject server with `service openproject restart`.  If you configured SAML through settings, this step can be ignored.

#### XML Metadata exchange

The configuration will enable the SAML XML metadata endpoint at `https://<your openproject host>/auth/saml/metadata`
for service discovery use with your identity provider.

### 4: Log in

From there on, you will see a button dedicated to logging in via SAML, e.g named "My SSO" (depending on the name you chose in the configuration), when logging in. Clicking it will redirect to your SSO provider and return with your attribute data to set up the account, or to log in.

![my-sso](my-sso.png)

### 5: Return from the authentication provider

When you return from the authentication provider, you might be shown one of these return paths:

1. The user is automatically created and logged in. The SAML authentication integration is fully working
2. You are being redirected to the account registration modal with missing pieces of information. In this case, your authentication provider might not send us the full set of attributes required, or their mapping is invalid.
3. You are being redirected to the account registration modal as user name or email is already taken. In this case, the account you want to authenticate already has an internal OpenProject account. You need to follow the [Troubleshooting](#troubleshooting) guide below to enable taking over that existing account.
4. You are getting an internal or authentication error message. This is often a permission or invalid certificate/fingerprint configuration. Please consult the server logs for any hints OpenProject might log there.

## Instructions for common SAML providers

In the following, we will provide configuration values for common SAML providers. Please note that the exact values might differ depending on your idP's version and configuration. If you have additions to these variables, please use the "Edit this file" functionality in the "Docs feedback" section of this documentation.

### ADFS

For ADFS, you need add OpenProject as a "relying part trust" entry within the ADFS management screen. Please follow this guide to be guided through the steps: https://learn.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust

#### Add OpenProject as a Relying Trust Party

- In the ADFS management snap-in, right click on`AD FS -> Relying Party Trusts` , and select `Add Relying Party Trust...`
- Select **Claims aware** and hit Start
- **Select Data Source**: Choose "Enter data about the relying party manually" and click Next
- **Specify Display Name**: Enter "OpenProject" or any arbitrary name for the OpenProject instance you want to identify
- **Configure Certificate**: Skip this step, unless you explicitly want to enable assertion encryption, whose steps are documented for OpenProject above.

- **Configure URL**: Check "Enable support for the SAML 2.0 WebSSO protocol" and enter the URL `https://<Your OpenProject hostname>/auth/saml`

- **Configure Identifier**: Add the value `https://<Your OpenProject hostname>` as a "Relying party trust identifier". This is also called the issuer and OpenProject will be configured to send this value
- **Choose Access Control Policy**: Select an appropriate access control policy for the OpenProject instance
- **Ready to Add Trust**: Under the tab endpoints, click on "Add SAML" to add a **SAML Assertion Consumer** with Binding `POST` and the Trusted URL set to `https://<Your OpenProject hostname>/auth/saml/callback`
- Click next and select "Configure claims issuance policy for this application"

A new wizard will pop up. If you missed this step, you can right click on the new party to select "Edit Claim Issuance Policy". In there, you will need to create attribute mappings from LDAP for OpenProject to access user data such as login, email address, names etc.

You can also follow this guide to add the LDAP claim rules: https://learn.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-rule-to-send-ldap-attributes-as-claims

- Click on "Add Rule..."
- Select "Send LDAP Attributes as Claims" and click Next

Add the following Claim rules:

| LDAP attribute   | Outgoing Claim Type (the value OpenProject looks for in the SAML response) |
| ---------------- | ------------------------------------------------------------ |
| SAM-account-name | Name ID                                                      |
| SAM-account-name | `uid`                                                        |
| Email-Addresses  | `mail`                                                       |
| Surname          | `sn`                                                         |
| Given-name       | `givenName`                                                  |

#### Export the ADFS public certificate

OpenProject needs the certificate or fingerprint of the ADFS to validate the signature of incoming tokens. Here are the steps on how to do that:

- In the ADFS management window, select "AD FS -> Service -> Certificates"
- Right click on the "Token-signing" certificate and click on "View Certificate..."
- Select the action "Copy to File..."
- Click on Next and select "Base-64 encoded X.509 (.CER)" and click Next
- Export the file and move it to the OpenProject instance or open a shell
- Run the command `awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' <path to the certificate>`  

#### Set up OpenProject for ADFS integration

In OpenProject, these are the variables you will need to set. Please refer to the above documentation for the different ways you can configure these variables  OpenProject

```shell
OPENPROJECT_SAML_SAML_NAME="saml"
OPENPROJECT_SAML_SAML_DISPLAY__NAME="ADFS SSO" # This is the text shown to users in OpenProject, freely change this value
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_EMAIL="[mail]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LOGIN="[uid, mail]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_FIRST__NAME="[givenName]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LAST__NAME="[sn]"
OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__URL="https://<Your OpenProject hostname>/auth/saml/callback"
OPENPROJECT_SAML_SAML_SSO__TARGET__URL="https://<Your ADFS hostname>/adfs/ls"
OPENPROJECT_SAML_SAML_SLO__TARGET__URL="https://<Your ADFS hostname>/adfs/ls/?wa=wsignout1.0"
OPENPROJECT_SAML_SAML_ISSUER="https://<Your OpenProject hostname>"
OPENPROJECT_SAML_SAML_IDP__CERT="<The output of the awk command above>"
```

### Keycloak

In Keycloak, use the following steps to set up a SAML integration OpenProject:

- Select or create a realm you want to authenticate OpenProject with. Remember that realm identifier.
- Under "Clients" menu, click on "Create"
- **Add client**: Enter the following details
  - **Client ID**: `https://<Your OpenProject hostname>`
  - **Client protocol**: Set to "saml"
  - **Client SAML Endpoint**:  `https://<Your OpenProject hostname>/auth/saml`

You will be forwarded to the settings tab  of the new client. Change these settings:

- Enable **Sign Documents**
- **Master SAML Processing URL**: Set to `https://<Your OpenProject hostname>/auth/saml`
- **Name ID Format** Set to username
- Expand section "Fine Grain SAML Endpoint Configuration"
  - **Assertion Consumer Service POST Binding URL**: Set to `https://<Your OpenProject hostname>/auth/saml/callback`
  - **Assertion Consumer Service Redirect Binding URL**: Set to `https://<Your OpenProject hostname>/auth/saml/callback`

Go the "Mappers" tab and create the following mappers. Note that the "User attribute" values might differ depending on your LDAP or Keycloak configuration.

| Mapper Type    | User Attribute | Friendly Name | SAML Attribute Name | SAML Attribute NameFormat |
| -------------- | -------------- | ------------- | ------------------- | ------------------------- |
| User Attribute | uid            | uid           | uid                 | Basic                     |
| User Attribute | lastName       | sn            | sn                  | Basic                     |
| User Attribute | firstName      | givenName     | givenName           | Basic                     |
| User Attribute | email          | mail          | mail                | Basic                     |

#### Export the Keycloak public certificate

To view the certificate in Base64 encoding, go to the menu "Realm settings" and click on "Endpoints -> SAML 2.0 Identity Provider Metadata". This will open an XML file, and the certificate is stored in the `ds:X509Certificate` node under the signing key. Copy the content of the certificate (`MII.....`)

#### Set up OpenProject for Keycloak integration

In OpenProject, these are the variables you will need to set. Please refer to the above documentation for the different ways you can configure these variables  OpenProject

```shell
OPENPROJECT_SAML_SAML_NAME="saml"
OPENPROJECT_SAML_SAML_DISPLAY__NAME="Keycloak SSO" # This is the text shown to users in OpenProject, freely change this value
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_EMAIL="[mail]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LOGIN="[uid, mail]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_FIRST__NAME="[givenName]"
OPENPROJECT_SAML_SAML_ATTRIBUTE__STATEMENTS_LAST__NAME="[sn]"
OPENPROJECT_SAML_SAML_ASSERTION__CONSUMER__SERVICE__URL="https://<Your OpenProject hostname>/auth/saml/callback"
OPENPROJECT_SAML_SAML_SSO__TARGET__URL="https://<Your Keycloak hostname>/realms/<Keycloak REALM>/protocol/saml"
OPENPROJECT_SAML_SAML_SLO__TARGET__URL="https://<Your Keycloak hostname>/realms/<Keycloak RELAM>/protocol/saml"
OPENPROJECT_SAML_SAML_ISSUER="https://<Your OpenProject hostname>"
OPENPROJECT_SAML_SAML_IDP__SSO__SERVICE__URL="https://<Your Keycloak hostname>/realms/<Keycloak RELAM>/protocol/saml"
OPENPROJECT_SAML_SAML_IDP__CERT="<The certificate base64 copied from the metadata XML>"
```

If you're unsure what the realm value is, go to the menu "Realm settings" and click on "Endpoints -> SAML 2.0 Identity Provider Metadata". This will include URLs for the `SingleSignOnService` and `SingleLogoutService`.

## Troubleshooting

**Q: After clicking on a provider badge, I am redirected to a signup form that says a user already exists with that login.**

A: This can happen if you previously created user accounts in OpenProject with the same email than what is stored in the identity provider. In this case, if you want to allow existing users to be automatically remapped to the SAML identity provider, you should do the following:

Spawn an interactive console in OpenProject. The following example shows the command for the packaged installation.
See [our process control guide](../../../installation-and-operations/operation/control/) for information on other installation types.

```shell
sudo openproject run console
> Setting.oauth_allow_remapping_of_existing_users = true
> exit
```

Then, existing users should be able to log in using their SAML identity. Note that this works only if the user is using password-based authentication, and is not linked to any other authentication source (e.g. LDAP) or OpenID provider.

Note that this setting is set to true by default for new installations already.

**Q: Could the users be automatically logged in to OpenProject if they are already authenticated at the SAML Identity Provider?**

A: You are able to chose a default direct-login-provider in the by using environment variables

```yaml
OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER="saml"
```

[Read more](../../../installation-and-operations/configuration/#omniauth-direct-login-provider)

**Q:** `"certificate"` **and** `"private key"` **are used in the SAML configuration and openproject logs show a FATAL error after GET "/auth/saml"**  `**FATAL** -- :  OpenSSL::PKey::RSAError (Neither PUB key nor PRIV key: nested asn1 error):`

A1: The given private_key is encrypted. The key is needed without the password (cf., [see](https://github.com/onelogin/ruby-saml/issues/473))

A2: The provided key pair is not an RSA key. ruby-saml might expect an RSA key.
