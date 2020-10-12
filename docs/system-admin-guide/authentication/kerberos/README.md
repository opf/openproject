---
sidebar_navigation:
  title: Kerberos
  priority: 800
description: How to set up integration of Kerberos for authentication with OpenProject.
robots: index, follow
keywords: Kereros, authentication


---

# Kerberos integration

<div class="alert alert-info" role="alert">
**Note**: This documentation is valid for the OpenProject Enterprise Edition only.
</div>

[Kerberos](https://web.mit.edu/kerberos/) allows you to authenticate user requests to a service within a computer network. You can integrate it with OpenProject with the use of [Kerberos Apache module](http://modauthkerb.sourceforge.net/) (`mod_auth_kerb`) plugging into the OpenProject packaged installation using Apache web server.

This guide will also apply for Docker-based installation, if you have an outer proxying server such as Apache2 that you can configure to use Kerberos. This guide however focuses on the packaged installation of OpenProject.



## Step 1: Creating Kerberos service and keytab for OpenProject

Assuming you have Kerberos set up with a realm, you need to create a Kerberos service Principal for the OpenProject HTTP service. In the course of this guide, we're going to assume your realm is `EXAMPLE.COM` and your OpenProject installation is running at `openproject.example.com`.



Create the service principal (e.g, using `kadmin`) and a keytab for OpenProject used for Apache with the following commands:



```bash
# Assuming you're in the `kadmin.local` interactive command

addprinc -randkey HTTP/openproject.example.com
ktadd -k /etc/openproject/openproject.keytab HTTP/openproject.example.com
```



This will output a keytab file for the realm selected by `kadmin` (in the above example, this would create all users from the default_realm) to `/etc/openproject/openproject.keytab`

You still need to make this file readable for Apache. For Debian/Ubuntu based systems, the Apache user and group is `www-data`. This will vary depending on your installation

```bash
sudo chown www-data:www-data /etc/openproject/openproject.keytab
sudo chmod 400 /etc/openproject/openproject.keytab
```



## Step 2: Configuration of Apache web server

First, ensure that you install the `mod_auth_kerb` apache module. The command will vary depending on your installation. On Debian/Ubuntu based systems, use the following command to install:

```bash
sudo apt-get install libapache2-mod-auth-kerb
```

You will then need to add the generated keytab to be used for the OpenProject installation. OpenProject allows you to specify additional directives for your installation VirtualHost.

We are going to create a new file `/etc/openproject/addons/apache2/includes/vhost/kerberos.conf` with the following contents:

```
  <Location />
    AuthType Kerberos
    # The Basic Auth dialog name shown to the user
    # change this freely
    AuthName "EXAMPLE.COM realm login"
    
    # The realm used for Kerberos, you will want to
    # change this to your actual domain
    KrbAuthRealm EXAMPLE.COM
    
    # Path to the Keytab generated in the previous step
    Krb5Keytab /etc/openproject/openproject.keytab
    
    # After authentication, Apache will set a header
    # "X-Authenticated-User" to the logged in username
    # appended with a configurable secret value
    RequestHeader set X-Authenticated-User expr=%{REMOTE_USER}:MyPassword
    
    # Apache directive to ensure a user is authenticated
    Require valid-user
  </Location>
```



## Step 3: Configuration of OpenProject to use Apache header

As the last step, you need to tell OpenProject to look for the `X-Authenticated-User` header and the `MyPassword` secret value.

You can do that in two ways:



#### Configure using the configuration.yml

In your OpenProject packaged installation, you can modify the `/opt/openproject/config/configuration.yml` file. This will contain the complete OpenProject configuration and can be extended  to include a section for the header checking.



```yaml
production:
  # <-- other configuration -->

  auth_source_sso:
    # The header name is configured here
    header: X-Authenticated-User

    # The secret is configurable here
    # You can comment it out to disable if your outer server
    # fully controls this header value and you trust it.
    secret: MyPassword

    # Uncomment to make the header optional.
    # optional: true

    # Specify a logout URL that gets redirected
    # after the OpenProject internal logout flow
    # logout_url: https://sso.example.com/logout
```

Be sure to choose the correct indentation and base key. The `auth_source_sso` key should be indented two spaces (and all other keys accordingly) and the configuration should belong to the `production` group.


The configuration can be provided in one of three ways:

* `configuration.yml` file (1.1)
* Environment variables (1.2)
* `settings.yml` file (1.3)

Whatever means are chosen, the plugin simply passes all options to omniauth-saml. See [their configuration
documentation](https://github.com/omniauth/omniauth-saml#usage) for further details.

The three options are mutually exclusive. I.e. if settings are already provided via the `configuration.yml` file, settings in a `settings.yml` file will be ignored. Environment variables will override the `configuration.yml` based configuration, though.

#### Configure using environment variables

As with all the rest of the OpenProject configuration settings, the Kerberos header configuration can be provided via environment variables. For example:

```bash
openproject config:set OPENPROJECT_AUTH__SOURCE__SSO_HEADER="X-Authenticated-User"
openproject config:set OPENPROJECT_AUTH__SOURCE__SSO_SECRET="MyPassword"
```

  In case you want to make the header optional, i.e. the header may or may not be present for a subset of users going through Apache, you can set the following value:

  ```bash
  openproject config:set OPENPROJECT_AUTH__SOURCE__SSO_OPTIONAL=true
  ```

Please note that every underscore (`_`) in the original configuration key has to be replaced by a duplicate underscore
(`__`) in the environment variable as the single underscore denotes namespaces.



## Step 4: Restarting the server

Once the configuration is completed, restart your OpenProject and Apache2 server with `service openproject restart` and  `service apache2 restart` . Again these commands might differ depending on your Linux distribution.



## Step 5: Logging in

From there on, you will be forced to the Kerberos login flow whenever accessing OpenProject. For existing users that will be found by their login attribute provided in the `X-Authenticated-User`, they will be automatically logged in.

For non-existing users, if you have an LDAP configured with automatic user registration activated (check out our [LDAP authentication guide](https://docs.openproject.org/system-admin-guide/authentication/ldap-authentication/) for that), users will be created automatically with the attributes retrived from the LDAP.



# Additional  resources

- [Kerberos documentation by Ubuntu](https://help.ubuntu.com/community/Kerberos)