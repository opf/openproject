---
sidebar_navigation:
  title: Advanced configuration
  priority: 100
---

# OpenProject advanced configuration

OpenProject can be configured via environment variables. These are often helpful for automatically deploying production systems.

> [!NOTE]
> This documentation is for OpenProject on-premises Installations only, if you would like to setup similar in your OpenProject cloud instance, please contact us at [support@openproject.com](mailto:support@openproject.com)

> [!IMPORTANT]
> Using the configuration file `config/configuration.yml` is deprecated and is **NOT** recommended anymore

## Packaged installation

The file `/opt/openproject/.env.example` contains some information to learn more. Files stored within `/etc/openproject/conf.d/` are used for parsing the variables and your custom values to your configuration. Whenever you call `openproject config:set VARIABLE=value`, it will end up in this folder.

To configure the environment variables such as the number of web server threads, copy the `.env.example` to `/etc/openproject/conf.d/env` and add the environment variables you want to configure. The variables will be automatically loaded to the application’s environment.

After changing the file `/etc/openproject/conf.d/env`  the command `sudo openproject configure` must be issued

If you would like to change only one variable you are able to configure the environment variable by using the following command:

```shell
sudo openproject config:set VARIABLE=value
```

This will write the value of the variable to the file `/etc/openproject/conf.d/other`.

After the file `/etc/openproject/conf.d/other`  is changed the command `sudo openproject configure` must be issued

Configuring OpenProject through environment variables is described in detail [in the environment variables guide](environment/).

## Docker

### One container per process installation

Create a file `docker-compose.override.yml` next to `docker-compose.yml` file. Docker Compose will automatically merge those files, for more information, [see](https://docs.docker.com/compose/multiple-compose-files/merge/).
Add your custom configuration to `docker-compose.override.yml`.

In the compose folder you will also find the file `docker-compose.yml` which shall **NOT** be edited.

After changing the file `docker-compose.override.yml`  the command `docker-compose down && docker-compose up -d` must be issued

To add an environment variable manually to the docker-compose file, add it to the `environment:` section of the `op-x-app` definition like in the following example:

```yaml
version: "3.7"

networks:
  frontend:
  backend:

volumes:
  pgdata:
  opdata:

x-op-restart-policy: &restart_policy
  restart: unless-stopped
x-op-image: &image
  image: openproject/openproject:${TAG:-15}
x-op-app: &app
  <<: [*image, *restart_policy]
  environment:
    OPENPROJECT_HTTPS: true
    # ... other configuration
    OPENPROJECT_CACHE__MEMCACHE__SERVER: "cache:11211"
    OPENPROJECT_RAILS__CACHE__STORE: "memcache"
    OPENPROJECT_RAILS__RELATIVE__URL__ROOT: "${OPENPROJECT_RAILS__RELATIVE__URL__ROOT:-}"
    DATABASE_URL: "${DATABASE_URL:-postgres://postgres:p4ssw0rd@db/openproject?pool=20&encoding=unicode&reconnect=true}"
    RAILS_MIN_THREADS: 4
    RAILS_MAX_THREADS: 16
    # set to true to enable the email receiving feature. See ./docker/cron for more options
    IMAP_ENABLED: "${IMAP_ENABLED:-false}"
  volumes:
    - "${OPDATA:-opdata}:/var/openproject/assets"

# configuration cut off at this point.
# Please use the file at https://github.com/opf/openproject-docker-compose/blob/stable/17/docker-compose.yml
```

Alternatively, you can also use an env file for docker-compose like so:

First, add a `.env` file with some variable:

```shell
OPENPROJECT_HTTPS="true"
```

And then you'll need to pass the environment variable to the respective containers you want to set it on. For most OpenProject environment variables, this will be for `x-op-app`:

```yaml
version: "3.7"

networks:
  frontend:
  backend:

volumes:
  pgdata:
  opdata:

x-op-restart-policy: &restart_policy
  restart: unless-stopped
x-op-image: &image
  image: openproject/openproject:${TAG:-15}
x-op-app: &app
  <<: [*image, *restart_policy]
  environment:
    OPENPROJECT_HTTPS: ${OPENPROJECT_HTTPS}
    # ... more environment variables

# configuration cut off at this point.
# Please use the file at https://github.com/opf/openproject-docker-compose/blob/stable/17/docker-compose.yml
```

Let's say you have a `.env.prod`  file with some production-specific configuration. Then, start the services with that special env file specified.

```shell
docker-compose --env-file .env.prod up
```

#### Disabling services in the docker-compose file

If you have a `docker-compose.override.yml` file created, it is also easy to disable certain services, such as the database container if you have an external one running anyway.

To do that, add this section to the file:

```yaml
services:
  db:
    deploy:
      replicas: 0
```

Configuring OpenProject through environment variables is described in detail [in the environment variables guide](environment/).

### Docker all-in-one container installation

Environment variables can be either passed directly on the command-line to the
Docker Engine, or via an environment file:

```shell
docker run -d -e KEY1=VALUE1 -e KEY2=VALUE2 ...
# or
docker run -d --env-file path/to/file ...
```

Configuring OpenProject through environment variables is described in detail [in the environment variables guide](environment/).

#### Real-time collaboration

The AIO (all-in-one) container comes bundled with the [hocuspocus](https://github.com/opf/openproject/tree/dev/extensions/op-blocknote-hocuspocus) server needed
for the real-time collaboration feature for documents.

This is controlled via the following two environment variables, shown with their default values.

```bash
OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=auto
OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET=
```

This will automatically generate a secret, start hocuspocus and configure it with OpenProject to enable real-time collaboration
in documents.

If you want to use an external hocuspocus server instead, you have two options.

**Option 1**

Set the URL and secret using the environment variables above.

**Option 2**

Set the URL and secret using the UI. For that to work, you need to unset the URL in the environment,
so that the option becomes available in the UI.

You can unset it, for example, by adding the following option to the run command.

```bash
-e OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=
```

## Seeding through environment

OpenProject allows some resources to be seeded/created initially through configuration variables.

| Topic                                                       | Description                                                  |
| ----------------------------------------------------------- | ------------------------------------------------------------ |
| [Initial admin user creation](#initial-admin-user-creation) | Changing attributes or passwords of the initially created administrator |
| [Seeding LDAP connections](#seeding-ldap-connections)       | How to create an LDAP connection through configuration       |

### Initial admin user creation

> [!NOTE]
> These variables are only applicable during the first initial setup of your OpenProject setup. Changing or setting them later will have no effect, as the admin user will already have been created.

By default, an admin user will be created with the login and password set to `admin`. You will be required to change this password on first login.

In case of automated deployments, you might find it useful to seed an admin user with password and attributes of your choosing. For that, you can use the following set of variables:

```shell
OPENPROJECT_SEED_ADMIN_USER_PASSWORD="admin" # Password to set for the admin user
OPENPROJECT_SEED_ADMIN_USER_PASSWORD_RESET="true" # Whether to force a password reset on first login (true/false)
OPENPROJECT_SEED_ADMIN_USER_NAME="OpenProject Admin" # Name to assign to that user (First and lastnames will be split on the space character)
OPENPROJECT_SEED_ADMIN_USER_MAIL="admin@example.net" # Email attribute to assign to that user. Note that in packaged installations, a wizard step will assign this variable as well.
```

Optionally, you can also lock the admin user that gets created right away. This is useful when you have an LDAP or SSO integration set up and you want to prevent the admin user from logging in.

> [!WARNING]
> With the admin user seeding disabled, you need to have an LDAP or SSO integration set up through environment variables.
> Otherwise, you will not be able to retain access to the system.

```shell
OPENPROJECT_SEED_ADMIN_USER_LOCKED="true"
```

### Seeding LDAP connections

OpenProject allows you to create and maintain an LDAP connection with optional synchronized group filters. This is relevant for e.g., automated deployments, where you want to trigger the synchronization right at the start.

> [!NOTE]
> These variables are applied whenever `db:seed` rake task is being executed. This happens on every packaged `configure` call or when the seeder container job is being run, so be aware that these changes might happen repeatedly.

The connection can be set with the following options. Please note that "EXAMPLE" stands for an arbitrary name (expressible in ENV keys)  which will become the name of the connection. In this case, "example" and "examplefilter" for the synchronized filter.

The name of the LDAP connection is derived from the ENV key behind `SEED_LDAP_`, so you need to take care to use only valid characters. If you need to place an underscore, use a double underscore to encode it e.g., `my__ldap`.

#### Naming rule for option keys

The same encoding applies to **option keys** (the part of the env var after the connection name):

- A single underscore (`_`) separates path segments.
- A double underscore (`__`) encodes a literal underscore inside a single key.

For example, the attribute mapping for the login attribute must be passed as `LOGIN__MAPPING`. Writing `LOGIN_MAPPING` would create a nested `login.mapping` hash and would have been silently wrong in OpenProject versions earlier than 17.5.

Starting with OpenProject 17.5 the seeder validates the keys it sees and raises an error listing any unknown key, so typos no longer go unnoticed. Use exactly the keys shown below.

#### Full example

The example below shows every supported option for a connection named `EXAMPLE`.

```shell
# Host name of the connection
OPENPROJECT_SEED_LDAP_EXAMPLE_HOST="ldap.example.com"

# Port of the connection
OPENPROJECT_SEED_LDAP_EXAMPLE_PORT="389"

# LDAP security mode. One of:
#   plain_ldap: Unencrypted connection, no TLS/SSL
#   simple_tls: Deprecated LDAPS/SSL (often combined with port 636)
#   start_tls:  LDAPv3 STARTTLS on the standard unencrypted port (e.g., 389)
OPENPROJECT_SEED_LDAP_EXAMPLE_SECURITY="start_tls"

# Whether to verify the LDAP server's certificate chain. true/false (true by default).
OPENPROJECT_SEED_LDAP_EXAMPLE_TLS__VERIFY="true"

# Optionally pin a server certificate (PEM-encoded).
OPENPROJECT_SEED_LDAP_EXAMPLE_TLS__CERTIFICATE="-----BEGIN CERTIFICATE-----\nMII....\n-----END CERTIFICATE-----"

# Bind DN (the LDAP account used for read access during search/bind).
OPENPROJECT_SEED_LDAP_EXAMPLE_BINDUSER="uid=admin,ou=system"

# Password for the bind account.
OPENPROJECT_SEED_LDAP_EXAMPLE_BINDPASSWORD="secret"

# Base DN of the directory subtree used for user search.
OPENPROJECT_SEED_LDAP_EXAMPLE_BASEDN="dc=example,dc=com"

# Optional LDAP filter restricting which users may log in to OpenProject
# (used when automatic user creation is active).
OPENPROJECT_SEED_LDAP_EXAMPLE_FILTER="(uid=*)"

# Whether to create matching users on the fly when they log in for the first time.
OPENPROJECT_SEED_LDAP_EXAMPLE_SYNC__USERS="true"

# Attribute mappings: which LDAP attribute should populate each OpenProject field.
# Remember the double underscore in these keys.
OPENPROJECT_SEED_LDAP_EXAMPLE_LOGIN__MAPPING="uid"
OPENPROJECT_SEED_LDAP_EXAMPLE_FIRSTNAME__MAPPING="givenName"
OPENPROJECT_SEED_LDAP_EXAMPLE_LASTNAME__MAPPING="sn"
OPENPROJECT_SEED_LDAP_EXAMPLE_MAIL__MAPPING="mail"

# Optional: derive admin status from an LDAP attribute. Leave empty or remove
# to keep admin status managed manually in OpenProject.
OPENPROJECT_SEED_LDAP_EXAMPLE_ADMIN__MAPPING=""
```

To define a synchronized LDAP filter (for automatic group creation and synchronization), you can add these values:

```shell
# Define a filter called "examplefilter" with the following options
# LDAP base to search for groups
OPENPROJECT_SEED_LDAP_EXAMPLE_GROUPFILTER_EXAMPLEFILTER_BASE="ou=groups,dc=example,dc=com"
# LDAP filter to locate groups to synchronize with OpenProject
OPENPROJECT_SEED_LDAP_EXAMPLE_GROUPFILTER_EXAMPLEFILTER_FILTER="(cn=*)"
# Whether users found in these groups are automatically created
OPENPROJECT_SEED_LDAP_EXAMPLE_GROUPFILTER_EXAMPLEFILTER_SYNC__USERS="true"
# The attribute used for the OpenProject group name
OPENPROJECT_SEED_LDAP_EXAMPLE_GROUPFILTER_EXAMPLEFILTER_GROUP__ATTRIBUTE="cn"
```

When a filter is defined, synchronization happens directly during seeding for enterprise editions. Be aware of that when you create the connection that e.g., the LDAP connection needs to be reachable.

### Seeding custom theme and design (Enterprise add-on)

In an automated deployment setup, such as installing OpenProject using our Helm chart, you might want to provide the custom design through environment variables.

> [!NOTE]
> Setting these variables will not have an effect on the Community Edition.

**Setting design colors**

```shell
OPENPROJECT_SEED_DESIGN_PRIMARY__BUTTON__COLOR="#1F883D"
OPENPROJECT_SEED_DESIGN_ACCENT__COLOR="#1F883D"
OPENPROJECT_SEED_DESIGN_HEADER__BG__COLOR="#1A67A3"
OPENPROJECT_SEED_DESIGN_MAIN__MENU__BG__COLOR="#FFFFFF"
OPENPROJECT_SEED_DESIGN_MAIN__MENU__BG__SELECTED__BACKGROUND="#1F883D"
OPENPROJECT_SEED_DESIGN_EXPORT__COVER__TEXT__COLOR="#333333"
```

**Setting logos and icons through environment variables**

You can also provide the logo used in the main app header, as well as favicons or touchicons through these variables. OpenProject supports downloading images during seed from a reachable URL, or as base64-encoded data URLs.

```shell
# Main logo of the application
OPENPROJECT_SEED_DESIGN_LOGO="https://my.example.com/logo.png"
# Favicon and touch icons for ios
OPENPROJECT_SEED_DESIGN_FAVICON="data:image/png;base64,iVBO....."
OPENPROJECT_SEED_DESIGN_TOUCH__ICON="data:image/png;base64,foo..."
OPENPROJECT_SEED_DESIGN_EXPORT__LOGO="..."
OPENPROJECT_SEED_DESIGN_EXPORT__COVER="..."
```


## Examples for common use cases

* `attachments_storage_path`
* `autologin_cookie_name` (default: 'autologin'),
* `autologin_cookie_path` (default: '/')
* `database_cipher_key`     (default: nil)
* `scm_git_command` (default: 'git')
* `scm_subversion_command` (default: 'svn')
* [`scm_local_checkout_path`](#local-checkout-path) (default: 'repositories')
* `force_help_link` (default: nil)
* `drop_old_sessions_on_logout` (default: true)
* `drop_old_sessions_on_login` (default: false)
* [`auth_source_sso`](#auth-source-sso) (default: nil)
* [`omniauth_direct_login_provider`](#omniauth-direct-login-provider) (default: nil)
* [`oauth_allow_remapping_of_existing_users`](#prevent-omniauth-remapping-of-existing-users) (default: true)
* [`disable_password_login`](#disable-password-login) (default: false)
* [`attachments_storage`](#attachments-storage) (default: file)
* [`direct_uploads`](#direct-uploads) (default: true)
* [`fog_download_url_expires_in`](#fog-download-url-expires-in) (default: 21600)
* [`hidden_menu_items`](#hidden-menu-items-admin-menu) (default: {})
* [`disabled_modules`](#disabled-modules) (default: [])
* [`blacklisted_routes`](#blacklisted-routes) (default: [])
* [`global_basic_auth`](#global-basic-auth)
* [`apiv3_enable_basic_auth`](#apiv3-enable-basic-auth)
* [`enterprise_fail_fast`](#enterprise-fail-fast)
* [`backup_enabled`](#enable-backups)
* [`show_community_links`](#show-or-hide-community-links)
* [`web`](#web-worker-configuration) (nested configuration)
* [`statsd`](#statsd) (nested configuration)

### Allowing public access

By default, any request to the OpenProject application needs to be authenticated. If you want to enable public unauthenticated access like we do for community.openproject.org, you can set the `login_required` to `false`. If not provided through environment variables, this setting is also accessible in the administrative UI. Please see the [authentication settings guide](../../system-admin-guide/authentication/login-registration-settings/) for more details.

*default: true*

To disable, set the configuration option:

```yaml
OPENPROJECT_LOGIN__REQUIRED="false"
```

### Setting session options

**Delete old sessions for the same user when logging in**

*default: false*

To enable, set the configuration option:

```yaml
OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGIN="true"
```

**Delete old sessions for the same user when logging out**

*default: true*

To disable, set the configuration option:

```yaml
OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGOUT="false"
```

### Attachments storage

You can modify the folder where attachments are stored locally. Use the `attachments_storage_path` configuration variable for that. But ensure that you move the existing paths. To find out the current path on a packaged installation, use `openproject config:get OPENPROJECT_ATTACHMENTS__STORAGE__PATH`.

To update the path, use `openproject config:set OPENPROJECT_ATTACHMENTS__STORAGE__PATH="/path/to/new/folder"`. Ensure that this is writable by the `openproject` user. Afterwards issue a restart by `sudo openproject configure`

#### Attachment storage type

Attachments can be stored using e.g. Amazon S3, In order to set these values through ENV variables, add to the file :

*default: file*

```yaml
OPENPROJECT_ATTACHMENTS__STORAGE="fog"
OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID="AKIAJ23HC4KNPWHPG3UA"
OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY="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"
OPENPROJECT_FOG_CREDENTIALS_PROVIDER="AWS"
OPENPROJECT_FOG_CREDENTIALS_REGION="eu-west-1"
OPENPROJECT_FOG_DIRECTORY="uploads"
```

### Auth source sso

Can be used to automatically login a user defined through a custom header sent by a load balancer or reverse proxy in front of OpenProject, for instance in a Kerberos Single Sign-On (SSO) setup via apache.
The header with the given name has to be passed to OpenProject containing the logged in user and the defined global secret as in `$login:$secret`.

*default: nil*

```yaml
OPENPROJECT_AUTH__SOURCE__SSO="{ header: X-Remote-User, secret: s3cr3t }"
```

This example in the old `configuration.yml` looked like this:

```yaml
auth_source_sso:
  header: X-Remote-User
  # Optional secret to be passed by the header in form
  # of a colon-separted userinfo string
  # e.g., X-Remote-User "username:s3cret"
  secret: s3cr3t
  # Uncomment to make the header optional.
  # optional: true
```

### Backups

#### Enable backups

If enabled, admins (or users with the necessary permission) can download backups of the OpenProject installation
via OpenProject's web interface or via the API.

*default: true*

```yaml
OPENPROJECT_BACKUP__ENABLED="false"
```

#### Backup attachment size max sum mb

Per default the maximum overall size of all attachments must not exceed 1GB for them to be included in the backup. If they are larger only the database dump will be included.

*default=1024*

```yaml
OPENPROJECT_BACKUP__ATTACHMENT__SIZE__MAX__SUM__MB="8192"
```

#### Additional configurations for backup

```yaml
OPENPROJECT_BACKUP__DAILY__LIMIT="3"
OPENPROJECT_BACKUP__INCLUDE__ATTACHMENTS="true"
OPENPROJECT_BACKUP__INITIAL__WAITING__PERIOD="86400"
```

### BCrypt configuration

OpenProject uses BCrypt to derive and store user passwords securely. BCrypt uses a so-called Cost Factor to derive the computational effort required to derive a password from input.

For more information, see the [Cost Factor guide of the bcrypt-ruby gem](https://github.com/bcrypt-ruby/bcrypt-ruby#cost-factors). The higher the value, the more effort required for deriving BCrypt hashes.

*default: 12*

```shell
OPENPROJECT_OVERRIDE__BCRYPT__COST__FACTOR="16"
```

### Database configuration and SSL

Please see [this separate guide](./database/) on how to set a custom database connection string and optionally, require SSL/TTLS verification.

### Disable password login

If you enable this option you have to configure at least one omniauth authentication
provider to take care of authentication instead of the password login.

All username/password forms will be removed and only a list of omniauth providers
presented to the users.

*default: false*

```yaml
OPENPROJECT_DISABLE__PASSWORD__LOGIN="true"
```

### Omniauth direct login provider

Per default the user may choose the usual password login as well as **several** omniauth providers on the login page and in the login drop down menu. With this configuration option you can set a specific omniauth provider to be used for direct login. Meaning that the login provider selection is skipped and the configured provider is used directly (non-interactive) instead.

If this option is active, a login will lead directly to the configured omniauth provider and so will a click on 'Sign in' (the drop down menu will not open).

To still reach the internal login route for e.g., an internal administrative user, you can manually navigate to `/login/internal`.
This route is only available when the direct login provider is set.

> [!NOTE]
> This does not stop a user from manually navigating to any other omniauth provider if additional ones are configured.

*default: nil*

```yaml
OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER="google"
```

### Prevent omniauth remapping of existing users

Per default external authentication providers through OmniAuth (such as SAML or OpenID connect providers) are allowed to take over existing
accounts if the mapped login is already taken. This is usually desirable, if you have e.g., accounts created through LDAP and want these
accounts to be accessible through a SSO provider as well

If you want to prevent this from happening, you can set this variable to false. In this case, accounts with matching logins will need
to create a new account.

*default: true*

```yaml
OPENPROJECT_OAUTH__ALLOW__REMAPPING__OF__EXISTING__USERS="false"
```

### Gravatar images

OpenProject uses gravatar images with a `404` fallback by default to render an internal, initials-based avatar.
You can override this behavior by setting `gravatar_fallback_image` to a different value to always render Gravatars

For supported values, please see [en.gravatar.com/site/implement/images/](https://en.gravatar.com/site/implement/images/)

*default: 404*

```yaml
OPENPROJECT_GRAVATAR__FALLBACK__IMAGE="identicon"
```

backend migration

You can migrate attachments between the available backends. One example would be that you change the configuration from the file storage to the fog storage. If you want to put all the present file-based attachments into the cloud, you will have to use the following rake task:

```shell
rake attachments:copy_to[fog]
```

It works the other way around too:

```shell
rake attachments:copy_to[file]
```

> [!NOTE]
> Please note that you have to configure the respective storage (i.e. fog) beforehand as described in the previous section. In the case of fog you only have to configure everything under `fog`, however. Don't change `attachments_storage` to `fog` just yet. Instead leave it as `file`. This is because the current attachments storage is used as the source for the migration.

### Direct uploads

> [!NOTE]
> This only works for AWS S3 or S3-compatible storages<sup>\*</sup>. When using fog with another provider this configuration will be `false`. The same goes for when no fog storage is configured, or when the `use_iam_profile` option is used in the fog credentials when using S3.

When using fog attachments uploaded in the frontend will be posted directly to the cloud rather than going through the OpenProject servers. This allows large attachments to be uploaded without the need to increase the `client_max_body_size` for the proxy in front of OpenProject. Also it prevents web processes from being blocked through long uploads.

If, for what ever reason, this is undesirable, you can disable this option. In that case attachments will be posted as usual to the OpenProject server which then uploads the file to the remote storage in an extra step.

*default: true*

```yaml
OPENPROJECT_DIRECT__UPLOADS="false"
```

\* If not using AWS S3, you will have to explicitly configure `remote_storage_upload_host` and `remote_storage_download_host`.

Here is what it would look like if we were to configure the default for AWS S3:

```yaml
OPENPROJECT_REMOTE__STORAGE__UPLOAD__HOST=mybucket.s3.amazonaws.com
OPENPROJECT_REMOTE__STORAGE__DOWNLOAD__HOST=mybucket.s3.eu-west.amazonaws.com"
```

#### Fog download url expires in

When using remote storage for attachments via fog - usually S3 (see [`attachments_storage`](#attachments-storage) option) - each attachment download will generate a temporary URL. This option determines how long these links will be valid.

The default is 21600 seconds, that is 6 hours, which is the maximum expiration time allowed by S3 when using IAM roles for authentication.

*default: 21600*

```yaml
OPENPROJECT_FOG__DOWNLOAD__URL__EXPIRES__IN="60"
```

### Force help link

You can override the default help menu of OpenProject by specifying a `force_help_link` option to
the configuration. This value is used for the href of the help link, and the default dropdown is removed.

*default: nil*

```yaml
OPENPROJECT_FORCE__HELP__LINK="https://it-support.example.com"
```

### Impressum link

You can set a impressum link (legal notice) for your OpenProject instance by setting `impressum_link` to an absolute URL.

*default: nil*

```yaml
OPENPROJECT_IMPRESSUM__LINK="https://impressum.example.com"
```

### Hidden menu items admin menu

You can disable specific menu items in the menu sidebar for each main menu (such as Administration and Projects). The configuration can be done through environment variables. You have to define one variable for each menu that shall be hidden.

*default: {}*

For instance 'Roles' and 'Types' under 'Administration' can be disabled by defining the following variable:

```yaml
OPENPROJECT_HIDDEN__MENU__ITEMS_ADMIN__MENU="roles types"
```

The following example disables all menu items except 'Users', 'Groups' and 'Custom fields' under 'Administration':

```yaml
OPENPROJECT_HIDDEN__MENU__ITEMS_ADMIN__MENU="roles types statuses workflows enumerations settings ldap_authentication colors project_types plugins info"
```

### Rate limiting and blocklisting

#### Rate limiting

OpenProject includes HTTP-layer rate limiting via Rack::Attack. The rules below are configured through the `rate_limiting` setting and take effect without a restart when set via environment variable.

In addition to these application-level rules, consider applying rate limiting at your load balancer or reverse proxy (e.g. `ngx_http_limit_req_module`, `mod_security`) for IP-level protection.

##### Login brute-force protection (enabled by default)

OpenProject blocks repeated login attempts per account at the HTTP layer. After **20 POST `/login` requests for the same username within one minute**, that account is blocked for **30 minutes**. This works alongside the application-level lockout (`brute_force_block_after_failed_logins` / `brute_force_block_minutes` settings).

This rule is **enabled by default**. To disable it:

```shell
OPENPROJECT_RATE_LIMITING_LOGIN="false"
```

The thresholds can be tuned independently:

| Variable | Default | Description |
|---|---|---|
| `OPENPROJECT_RATE_LIMITING_LOGIN_BURST__LIMIT` | `20` | Number of attempts allowed before the ban is triggered |
| `OPENPROJECT_RATE_LIMITING_LOGIN_BURST__PERIOD` | `60` | Detection window in seconds |
| `OPENPROJECT_RATE_LIMITING_LOGIN_BAN__PERIOD` | `1800` | Ban duration in seconds |

Example: Stricter limits (10 attempts per minute, 1-hour ban):

```shell
OPENPROJECT_RATE_LIMITING_LOGIN_BURST__LIMIT="10"
OPENPROJECT_RATE_LIMITING_LOGIN_BURST__PERIOD="60"
OPENPROJECT_RATE_LIMITING_LOGIN_BAN__PERIOD="3600"
```

> [!NOTE]
> This rule and the application-level brute-force protection (`brute_force_block_after_failed_logins` /
> `brute_force_block_minutes`) are independent controls that operate at different layers. The HTTP-layer
> rule counts **all** login attempts (including successful ones) within its burst window, while the
> application-level setting counts only **failed** attempts and operates over a longer rolling window.
> If you lower `brute_force_block_after_failed_logins` below `BURST_LIMIT` (default 20), the
> application-level lockout will fire before this rule does. Keep the two thresholds consistent to
> avoid surprising behaviour. For example, set `BURST_LIMIT` to match or be lower than
> `brute_force_block_after_failed_logins`.

##### Lost password rate limiting (disabled by default)

Limits password-reset requests per email address to 3 per hour.

```shell
OPENPROJECT_RATE_LIMITING_LOST__PASSWORD="true"
```

##### API v3 rate limiting (disabled by default)

Limits API form endpoint requests per session to 6 per 3 seconds.

```shell
OPENPROJECT_RATE_LIMITING_API__V3="true"
```

#### Blacklisted routes

You can blacklist specific routes

*default: []*

The following example forbid all routes for the second example at the 'hidden menu items admin menu':

```yaml
OPENPROJECT_BLACKLISTED__ROUTES="admin/info admin/plugins project_types colors settings admin/enumerations workflows/* statuses types admin/roles"
```

### Disabled modules

Modules may be disabled through the configuration.
Just give a list of the module names either as an array or as a string with values separated by spaces.

*default: []*

```yaml
OPENPROJECT_DISABLED__MODULES="backlogs meetings"
```

### Local checkout path

*default: "repositories"*

Remote git repositories will be checked out here.

```yaml
note: to be verified, maybe option was removed, not in environement variables list
```

### APIv3 enable basic auth

You can control basic auth access to the APIv3 with the following configuration option:

*default: true*

```yaml
OPENPROJECT_APIV3__ENABLE__BASIC__AUTH="false"
```

### Global basic auth

*default: none*

You can define a global set of credentials used to authenticate towards API v3:

```yaml
OPENPROJECT_AUTHENTICATION="{ global_basic_auth: { user: admin, password: adminpw } }"
```

This example in the old `configuration.yml` looked like this:

```yaml
default:
  authentication:
    global_basic_auth:
      user: admin
      password: adminpw
```

### Security upgrade badge

OpenProject provides a release indicator (security badge) that will inform administrators of an OpenProject installation on whether new releases or security updates are available for your platform. If enabled, this option will display a badge with your installation status at Administration &gt; Information right next to the release version, and on the home screen. It is only displayed to administrators.

The badge will match your current OpenProject version against the official OpenProject release database to alert you of any updates or known vulnerabilities. To ensure the newest available update can be returned, the check will include your installation type, current version, database type, enterprise status and an anonymous unique ID of the instance. To localize the badge, the user's locale is sent. No personal information of your installation or any user within is transmitted, processed, or stored.

To disable rendering the badge, uncheck the setting at Administration &gt; System settings &gt; General or pass the configuration flag `security_badge_displayed: false` .

*default=true*

```yaml
OPENPROJECT_SECURITY__BADGE__DISPLAYED="false"
```

### Content Security Policy image sources

Configure the allowed sources for the `img-src` CSP directive.

*default: `["*", "data:", "blob:"]`*

OpenProject always adds `'self'` and `rails_asset_host` (if configured) to `img-src` automatically, so same-origin and asset-hosted images remain allowed even if not listed in this setting.

Example to only allow secure remote images (plus data/blob):

```yaml
OPENPROJECT_CSP__IMG__SRC="https: data: blob:"
```

Example to restrict to specific hosts:

```yaml
OPENPROJECT_CSP__IMG__SRC="https://cdn.example.com https://images.example.com data: blob:"
```

### Cache configuration options


> [!NOTE]
> If you are using Redis as cache, you need to set the policy to one of the variants of allkeys.
> If you don't do this, the cached data doesn't expire, and you will run out of memory.
> You can get more information on how to set the Redis policy in the Rails [documentation](https://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-rediscachestore).

* `rails_cache_store`: `memcache` for [memcached](https://www.memcached.org/), `redis` for [Redis cache](https://redis.io/), or `memory_store` (default: `file_store`)
* When using `memcached`, the following configuration option is relevant:
  * `cache_memcache_server`: The memcache server host and IP (default: `nil`)

* When using `redis`, the following configuration option is relevant:
  * `cache_redis_url`: The URL of the Redis host (e.g., `redis://host:6379`)

* `cache_expires_in`: Expiration time for memcache entries (default: `nil`, no expiration)
* `cache_namespace`: Namespace for cache keys, useful when multiple applications use a single memcache server (default: `nil`)

### Rails asset host

`rails_asset_host`: A custom host to use to serve static assets such as javascript, CSS, images, etc. (default: `nil`)

### Redirect after login

`after_login_default_redirect_url`: Starting in OpenProject 15.4., users are redirected to the home page after logging in. To customize this behavior (e.g., redirecting them to the My page as before), you can override this with a path.

Example:

```shell
OPENPROJECT_AFTER__LOGIN__DEFAULT__REDIRECT__URL="/my/page"
```



### Onboarding video url

`onboarding_video_url`: A URL for the video displayed on the onboarding modal.
This video URL is whitelisted in the content security policy.

### Enterprise fail fast

If using an Enterprise token there are certain limits that apply. You can configure how these limits are enforced.

If you set `fail_fast` to true, new users cannot be invited or registered if the user limit has been reached.
If it is false then you can still invite and register new users but their activation will fail until the
user limit has been increased (or the number of active users decreased).

*default: false*

```yaml
OPENPROJECT_ENTERPRISE="{ fail_fast: true }"
```

Which is the same as:

```yaml
OPENPROJECT_ENTERPRISE_FAIL__FAST=true
```

This example in the old `configuration.yml` looked like this:

```yaml
enterprise:
  fail_fast: true
```

### Show or hide community links

If you would like to hide the homescreen links to the OpenProject community, you can do this with the following configuration:

*default=true*

```yaml
OPENPROJECT_SHOW__COMMUNITY__LINKS=false
```

### Web worker configuration

Configuration of the main ruby web server (currently puma). Sensible *defaults* are provided.

```yaml
OPENPROJECT_WEB_WORKERS="2"
OPENPROJECT_WEB_TIMEOUT="60"
OPENPROJECT_WEB_WAIT__TIMEOUT="10"
OPENPROJECT_WEB_MIN__THREADS="4"
OPENPROJECT_WEB_MAX__THREADS="16"
```

> [!NOTE]
> Timeouts only are supported when using at least 2 workers.

### Two-factor authentication

#### 2fa enforced

You can set the available 2FA strategies and/or enforce or disable 2FA system-wide.

**Enforcing 2FA authentication system-wide**

To enforce every user requires 2FA, you can use the checkbox under System settings > Authentication > Two-factor authentication.
However, if you also want to ensure administrators cannot uncheck this, use the following variable

```yaml
OPENPROJECT_2FA_ENFORCED="true"
```

**Setting available strategies**

By default, the TOTP and WebAuthn strategies are active.

If you have a [MessageBird account](https://www.messagebird.com/), you can setup a SMS 2FA by activating that strategy like so:

```yaml
OPENPROJECT_2FA_ACTIVE__STRATEGIES="[totp,message_bird]"
OPENPROJECT_2FA_MESSAGE__BIRD_APIKEY="your api key here"
```

You can also use Amazon SNS to send SMS for authentication:

```yaml
OPENPROJECT_2FA_ACTIVE__STRATEGIES="[totp,sns]"
OPENPROJECT_2FA_SNS_ACCESS__KEY__ID="YOUR KEY ID"
OPENPROJECT_2FA_SNS_SECRET__ACCESS__KEY="YOUR SECRET KEY"
OPENPROJECT_2FA_SNS_REGION="AWS REGION"
```

To disable 2FA altogether and remove all menus from the system, so that users cannot register their 2FA devices:

```yaml
OPENPROJECT_2FA_DISABLED="true"
OPENPROJECT_2FA_ACTIVE__STRATEGIES="[]"
```

#### StatsD

*default: { host: nil, port: 8125 }*

OpenProject can push metrics to [statsd](https://github.com/statsd/statsd). Currently these are simply the metrics for the puma server, but this may include more in the future.

This is disabled by default unless a host is configured.

```yaml
OPENPROJECT_STATSD_HOST="127.0.0.1"
OPENPRJOECT_STATSD_PORT="8125"
```

### Other configuration topics

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [List of supported environment variables](./environment)     | The full list of environment variables you can use to override the default configuration |
| [Configuring SSL](./ssl)                                     | How to configure SSL so that your OpenProject installation is available over HTTPS |
| [Configuring outbound emails](./outbound-emails)             | How to configure outbound emails for notifications, etc.     |
| [Configuring inbound emails](./incoming-emails)              | How to configure inbound emails for work package updates directly from an email |
| [Configuring a custom database](./database)                  | How to use an external database                              |
| [Configuring a custom web server](./server)                  | How to use a custom web server (e.g. NginX) with your OpenProject installation |
| Configuring a custom caching server                          | How to use a custom caching server with your OpenProject installation |
| [Configuring Git and Subversion repositories](./repositories) | How to integrate Git and Subversion repositories into OpenProject |
| [Adding plugins](./plugins)                                  | How to add plugins to your OpenProject installation          |
