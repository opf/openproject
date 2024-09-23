---
sidebar_navigation:
  title: Kerberos
  priority: 200
description: How to set up integration of Kerberos for authentication with OpenProject.
keywords: Kerberos, authentication


---

# Kerberos integration

> [!NOTE]
> This documentation is valid for the OpenProject Enterprise edition only. 

[Kerberos](https://web.mit.edu/kerberos/) allows you to authenticate user requests to a service within a computer network. You can integrate it with OpenProject with the use of [GSSAPI Apache module](https://github.com/gssapi/mod_auth_gssapi/) (`mod_auth_gssapi`) plugging into the OpenProject packaged installation using Apache web server.

This guide will also apply for Docker-based installation, if you have an outer proxying server such as Apache2 that you can configure to use Kerberos. This guide however focuses on the packaged installation of OpenProject.

## Step 1: Create Kerberos service and keytab for OpenProject

Assuming you have Kerberos set up with a realm, you need to create a Kerberos service Principal for the OpenProject HTTP service. In the course of this guide, we're going to assume your realm is `EXAMPLE.COM` and your OpenProject installation is running at `openproject.example.com`.

Create the service principal (e.g. using `kadmin`) and a keytab for OpenProject used for Apache with the following commands:

```shell
# Assuming you're in the `kadmin.local` interactive command

addprinc -randkey HTTP/openproject.example.com
ktadd -k /etc/apache2/openproject.keytab HTTP/openproject.example.com
```

This will output a keytab file for the realm selected by `kadmin` (in the above example, this would create all users from the default_realm) to `/etc/openproject/openproject.keytab`

You still need to make this file readable for Apache. For Debian/Ubuntu based systems, the Apache user and group is `www-data`. This will vary depending on your installation

```shell
sudo chown www-data:www-data /etc/apache2/openproject.keytab
sudo chmod 400 /etc/apache2/openproject.keytab
```

## Step 2: Configure Apache web server

First, ensure that you install the `mod_auth_kerb` apache module. The command will vary depending on your installation. On Debian/Ubuntu based systems, use the following command to install:

```shell
sudo apt install libapache2-mod-auth-gssapi
```

You will then need to add the generated keytab to be used for the OpenProject installation. OpenProject allows you to specify additional directives for your installation VirtualHost.

We are going to create a new file `/etc/openproject/addons/apache2/custom/vhost/kerberos.conf` with the following contents.

> [!NOTE]
> The following kerberos configuration is only an example. We cannot provide any support or help with regards to the Kerberos side of configuration. OpenProject will simply handle the incoming header containing the logged in user.

```apache
<Location />
  AuthType GSSAPI
  # The Basic Auth dialog name shown to the user
  # change this freely
  AuthName "EXAMPLE.COM realm login"

  # The credential store used by GSSAPI
  GssapiCredStore keytab:/etc/apache2/openproject.keytab
  
  # Allow basic auth negotiation fallback
  GssapiBasicAuth         On

  # Uncomment this if you want to allow NON-TLS connections for kerberos
  # GssapiSSLonly           Off
  
  # Use the local user name without the realm.
  # When off: OpenProject gets sent logins like "user1@EXAMPLE.com"
  # When on: OpenProject gets sent logins like "user1"
  GssapiLocalName         On
  
  # Allow kerberos5 login mechanism
  GssapiAllowedMech krb5


  # After authentication, Apache will set a header
  # "X-Authenticated-User" to the logged in username
  # appended with a configurable secret value
  RequestHeader set X-Authenticated-User expr=%{REMOTE_USER}:MyPassword
  
  # Ensure the Authorization header is not passed to OpenProject
  # as this will result in trying to perform basic auth with the API
  RequestHeader unset Authorization

  # Apache directive to ensure a user is authenticated
  Require valid-user
</Location>
```

## Step 3: Configure OpenProject to use Apache header

As the last step, you need to tell OpenProject to look for the `X-Authenticated-User` header and the `MyPassword` secret value. The easiest way to do that is using ENV variables

### Configure using environment variables

As with all the rest of the OpenProject configuration settings, the Kerberos header configuration can be provided via environment variables. For example:

```shell
openproject config:set OPENPROJECT_AUTH__SOURCE__SSO_HEADER="X-Authenticated-User"
openproject config:set OPENPROJECT_AUTH__SOURCE__SSO_SECRET="MyPassword"
```

In case you want to make the header optional, i.e. the header may or may not be present for a subset of users going through Apache, you can set the following value:

```shell
openproject config:set OPENPROJECT_AUTH__SOURCE__SSO_OPTIONAL=true
```

Please note the differences between single underscores (`_`) and double underscores (`__`) in these environment variables, as the single underscore denotes namespaces.

## Step 4: Restart the server

Once the configuration is completed, restart your OpenProject and Apache2 server with `service openproject restart` and  `service apache2 restart` . Again these commands might differ depending on your Linux distribution.

## Step 5: Log in

From there on, you will be forced to the Kerberos login flow whenever accessing OpenProject. For existing users that will be found by their login attribute provided in the `X-Authenticated-User`, they will be automatically logged in.

For non-existing users, if you have an LDAP configured with automatic user registration activated (check out our [LDAP authentication guide](../../../system-admin-guide/authentication/ldap-connections/) for that), users will be created automatically with the attributes retrieved from the LDAP.

## Known issues

### Using the OpenProject REST API

As Kerberos provides its own Basic Auth challenges if configured as shown above, it will prevent you from using the OpenProject API using an Authorization header such as API key authentication or OAuth2.

> [!NOTE]
> A precondition to use this workaround is to run OpenProject under its own path (server prefix) such as `https://YOUR DOMAIN/openproject/`. If you are not using this, you need to first reconfigure the wizard with `openproject reconfigure` to use such a path prefix. Alternatively, you might have success by using a separate domain or subdomain, but this is untested.

To work around this, you will have to configure a separate route to access the API, bypassing the Kerberos configuration. You can do that by modifying the `/etc/openproject/addons/apache2/custom/vhost/kerberos.conf`as follows:

```apache
# Add a Proxy for a separate route
# Replace /openproject/ with your own relative URL root / path prefix
ProxyPass /openproject-api/ http://127.0.0.1:6000/openproject/ retry=0
ProxyPassReverse /openproject-api/ http://127.0.0.1:6000/openproject/
  
# Require kerberos flow for anything BUT /openproject-api
<LocationMatch "^/(?!openproject-api)">
  AuthType GSSAPI
  # The Basic Auth dialog name shown to the user
  # change this freely
  AuthName "EXAMPLE.COM realm login"

  # The credential store used by GSSAPI
  GssapiCredStore keytab:/etc/apache2/openproject.keytab
  
  # Allow basic auth negotiation fallback
  GssapiBasicAuth         On

  # Uncomment this if you want to allow NON-TLS connections for kerberos
  # GssapiSSLonly           Off
  
  # Use the local user name without the realm.
  # When off: OpenProject gets sent logins like "user1@EXAMPLE.com"
  # When on: OpenProject gets sent logins like "user1"
  GssapiLocalName         On
  
  # Allow kerberos5 login mechanism
  GssapiAllowedMech krb5


  # After authentication, Apache will set a header
  # "X-Authenticated-User" to the logged in username
  # appended with a configurable secret value
  RequestHeader set X-Authenticated-User expr=%{REMOTE_USER}:MyPassword
  
  # Ensure the Authorization header is not passed to OpenProject
  # as this will result in trying to perform basic auth with the API
  RequestHeader unset Authorization

  # Apache directive to ensure a user is authenticated
  Require valid-user
</LocationMatch>
```

## Additional resources

- [Kerberos documentation by Ubuntu](https://help.ubuntu.com/community/Kerberos)
