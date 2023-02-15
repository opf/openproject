---
sidebar_navigation:
  title: Advanced configuration
  priority: 100
---

# OpenProject advanced configuration



OpenProject can be configured either via environment variables. These are often helpful for automatically deploying production systems.

> **NOTE:** This documentation is for OpenProject on-premises Installations only, if you would like to setup similar in your OpenProject cloud instance, please contact us at support@openproject.com

> **NOTE:** Using the configuration file `config/configuration.yml` is depracted and is **NOT** recommended anymore



# Packaged installation

The file `/opt/openproject/.env.example` contains some information to learn more. Files stored within `/etc/openproject/conf.d/` are used for parsing the variables and your custom values to your configuration. Whenever you call `openproject config:set VARIABLE=value`, it will end up in this folder.

To configure the environment variables such as the number of web server threads, copy the `.env.example` to `/etc/openproject/conf.d/env` and add the environment variables you want to configure. The variables will be automatically loaded to the application’s environment.

After changing the file `/etc/openproject/conf.d/env`  the command `sudo openproject configure` must be issued

If you would like to change only one variable you are able to configure the environment variable by using the following command:

```bash
sudo openproject config:set VARIABLE=value
```

This will write the value of the variable to the file `/etc/openproject/conf.d/other`.

After the file `/etc/openproject/conf.d/other`  is changed the command `sudo openproject configure` must be issued

Configuring OpenProject through environment variables is described in detail [in the environment variables guide](environment/).

# Docker

## one container per process installation

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
  image: openproject/community:${TAG:-12}
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
# Please use the file at https://github.com/opf/openproject-deploy/blob/stable/12/compose/docker-compose.yml
```



Alternatively, you can also use an env file for docker-compose like so:

First, add a `.env` file with some variable:

```bash
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
  image: openproject/community:${TAG:-12}
x-op-app: &app
  <<: [*image, *restart_policy]
  environment:
    OPENPROJECT_HTTPS: ${OPENPROJECT_HTTPS}
    # ... more environment variables

# configuration cut off at this point.
# Please use the file at https://github.com/opf/openproject-deploy/blob/stable/12/compose/docker-compose.yml
```



Let's say you have a `.env.prod`  file with some production-specific configuration. Then, start the services with that special env file specified.

```bash
docker-compose --env-file .env.prod up
```

### Disabling services in the docker-compose file

If you have a `docker-compose.override.yml` file created, it is also easy to disable certain services, such as the database container if you have an external one running anyway.

To do that, add this section to the file:

```yaml
services:
  db:
    deploy:
      replicas: 0
```

Configuring OpenProject through environment variables is described in detail [in the environment variables guide](environment/).



## Docker all-in-one container installation

Environment variables can be either passed directly on the command-line to the
Docker Engine, or via an environment file:

```bash
docker run -d -e KEY1=VALUE1 -e KEY2=VALUE2 ...
# or
docker run -d --env-file path/to/file ...
```

Configuring OpenProject through environment variables is described in detail [in the environment variables guide](environment/).



## Examples for common use cases

* `attachments_storage_path`
* `autologin_cookie_name` (default: 'autologin'),
* `autologin_cookie_path` (default: '/')
* `autologin_cookie_secure` (default: false)
* `database_cipher_key`     (default: nil)
* `scm_git_command` (default: 'git')
* `scm_subversion_command` (default: 'svn')
* [`scm_local_checkout_path`](#local-checkout-path) (default: 'repositories')
* `force_help_link` (default: nil)
* `session_store`: `active_record_store`, `cache_store`, or `cookie_store` (default: cache_store)
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
* [`backup_enabled`](#backup-enabled)
* [`show_community_links`](#show-community-links)
* [`web`](#web) (nested configuration)
* [`statsd`](#statsd) (nested configuration)

## Setting session options

Use `session_store` to define where session information is stored. In order to store sessions in the database and use the following options, set that configuration to `:active_record_store`.

**Delete old sessions for the same user when logging in**

To enable, set the configuration option:

*default: false*

```yaml
OPENPROJECT_SESSION__STORE="{ :active_record_store: { drop_old_sessions_on_login: true } }"
```

**Delete old sessions for the same user when logging out**

To disable, set the configuration option:

*default: true*

```yaml
OPENPROJECT_SESSION__STORE="{ :active_record_store: { drop_old_sessions_on_logout: false } }"
```


### disable password login

If you enable this option you have to configure at least one omniauth authentication
provider to take care of authentication instead of the password login.

All username/password forms will be removed and only a list of omniauth providers
presented to the users.

*default: false*

```yaml
OPENPROJECT_DISABLE__PASSWORD__LOGIN="true"
```

### auth source sso

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

### omniauth direct login provider

Per default the user may choose the usual password login as well as <u>several</u> omniauth providers on the login page and in the login drop down menu. With this configuration option you can set a specific omniauth provider to be used for direct login. Meaning that the login provider selection is skipped and the configured provider is used directly (non-interactive) instead.

If this option is active, a login will lead directly to the configured omniauth provider and so will a click on 'Sign in' (the drop down menu will not open).

> **NOTE:** This does not stop a user from manually navigating to any other omniauth provider if additional ones are configured.

*default: nil*

```yaml
OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER="google"
```

### prevent omniauth remapping of existing users

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


### Attachments storage

You can modify the folder where attachments are stored locally. Use the `attachments_storage_path` configuration variable for that. But ensure that you move the existing paths. To find out the current path on a packaged installation, use `openproject config:get OPENPROJECT_ATTACHMENTS__STORAGE__PATH`.

To update the path, use `openproject config:set OPENPROJECT_ATTACHMENTS__STORAGE__PATH="/path/to/new/folder"`. Ensure that this is writable by the `openproject` user. Afterwards issue a restart by `sudo openproject configure`

#### attachment storage type

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

#### backend migration

You can migrate attachments between the available backends. One example would be that you change the configuration from the file storage to the fog storage. If you want to put all the present file-based attachments into the cloud, you will have to use the following rake task:

```bash
rake attachments:copy_to[fog]
```

It works the other way around too:

```bash
rake attachments:copy_to[file]
```

> **NOTE:** that you have to configure the respective storage (i.e. fog) beforehand as described in the previous section. In the case of fog you only have to configure everything under `fog`, however. Don't change `attachments_storage` to `fog` just yet. Instead leave it as `file`. This is because the current attachments storage is used as the source for the migration.

### direct uploads

> **NOTE**: This only works for S3 right now. When using fog with another provider this configuration will be `false`. The same goes for when no fog storage is configured, or when the `use_iam_profile` option is used in the fog credentials when using S3.

When using fog attachments uploaded in the frontend will be posted directly to the cloud rather than going through the OpenProject servers. This allows large attachments to be uploaded without the need to increase the `client_max_body_size` for the proxy in front of OpenProject. Also it prevents web processes from being blocked through long uploads.

If, for what ever reason, this is undesirable, you can disable this option. In that case attachments will be posted as usual to the OpenProject server which then uploads the file to the remote storage in an extra step.

*default: true*

```yaml
OPENPROJECT_DIRECT__UPLOADS="false"
```

### fog download url expires in

When using remote storage for attachments via fog - usually S3 (see [`attachments_storage`](#attachments-storage) option) - each attachment download will generate a temporary URL. This option determines how long these links will be valid.

The default is 21600 seconds, that is 6 hours, which is the maximum expiry time allowed by S3 when using IAM roles for authentication.

*default: 21600*

```yaml
OPENPROJECT_FOG__DOWNLOAD__URL__EXPIRES__IN="60"
```

### force help link

You can override the default help menu of OpenProject by specifying a `force_help_link` option to
the configuration. This value is used for the href of the help link, and the default dropdown is removed.

*deafult: nil*

```yaml
OPENPROJECT_FORCE__HELP__LINK="https://it-support.example.com"
```

### impressum link

You can set a impressum link (legal notice) for your OpenProject instance by setting `impressum_link` to an absolute URL.

*deafult: nil*

```yaml
OPENPROJECT_IMPRESSUM__LINK="https://impressum.example.com"
```

### hidden menu items admin menu

You can disable specific menu items in the menu sidebar for each main menu (such as Administration and Projects). The configuration can be done through environment variables. You have to define one variable for each menu that shall be hidden.

*default: {}*

For instance 'Roles' and 'Types' under 'Administration' can be disabled by defining the following variable:

```yaml
OPENPROJECT_HIDDEN__MENU__ITEMS_ADMIN__MENU="roles types"
```

The following example disables all menu items except 'Users', 'Groups' and 'Custom fields' under 'Administration':

```yaml
OPENPROJECT_HIDDEN__MENU__ITEMS_ADMIN__MENU="roles types statuses workflows enumerations settings ldap_authentication colors project_types export_card_configurations plugins info"
```

### blacklisted routes

You can blacklist specific routes

*default: []*

The following example forbid all routes for the second example at the 'hidden menu items admin menu':

```yaml
OPENPROJECT_BLACKLISTED__ROUTES="admin/info admin/plugins export_card_configurations project_types colors settings admin/enumerations workflows/* statuses types admin/roles"
```

### disabled modules

Modules may be disabled through the configuration.
Just give a list of the module names either as an array or as a string with values separated by spaces.

*default: []*

```yaml
OPENPROJECT_DISABLED__MODULES="backlogs meetings"
```

### local checkout path

*default: "repositories"*

Remote git repositories will be checked out here.

```yaml
note: to be verified, maybe option was removed, not in environement variables list
```

### apiv3 enable basic auth

You can control basic auth access to the APIv3 with the following configuration option:

*default: true*

```yaml
OPENPROJECT_APIV3__ENABLE__BASIC__AUTH="false"
```

### global basic auth

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

### security badge displayed

OpenProject provides a release indicator (security badge) that will inform administrators of an OpenProject installation on whether new releases or security updates are available for your platform. If enabled, this option will display a badge with your installation status at Administration &gt; Information right next to the release version, and on the home screen. It is only displayed to administrators.

The badge will match your current OpenProject version against the official OpenProject release database to alert you of any updates or known vulnerabilities. To ensure the newest available update can be returned, the check will include your installation type, current version, database type, enterprise status and an anonymous unique ID of the instance. To localize the badge, the user's locale is sent. No personal information of your installation or any user within is transmitted, processed, or stored.

To disable rendering the badge, uncheck the setting at Administration &gt; System settings &gt; General or pass the configuration flag `security_badge_displayed: false` .

*default=true*

```yaml
OPENPROJECT_SECURITY__BADGE__DISPLAYED="false"
```

### Cache configuration options

* `rails_cache_store`: `memcache` for [memcached](https://www.memcached.org/) or `memory_store` (default: `file_store`)
* `cache_memcache_server`: The memcache server host and IP (default: `nil`)
* `cache_expires_in`: Expiration time for memcache entries (default: `nil`, no expiry)
* `cache_namespace`: Namespace for cache keys, useful when multiple applications use a single memcache server (default: `nil`)

### rails asset host

`rails_asset_host`: A custom host to use to serve static assets such as javascript, CSS, images, etc. (default: `nil`)

### onboarding video url

`onboarding_video_url`: An URL for the video displayed on the onboarding modal. This is only shown when the user logs in for the first time.

*default="[https://player.vimeo.com/video/163426858?autoplay=1](https://player.vimeo.com/video/163426858?autoplay=1)"*

### enterprise fail fast

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

### backup configuration

#### backup enabled

If enabled, admins (or users with the necessary permission) can download backups of the OpenProject installation
via OpenProject's web interface or via the API.

*default: true*

```yaml
OPENPROJECT_BACKUP__ENABLED="false"
```

#### backup attachment size max sum mb

Per default the maximum overall size of all attachments must not exceed 1GB for them to be included in the backup. If they are larger only the database dump will be included.

*default=1024*

```yaml
OPENPROJECT_BACKUP__ATTACHMENT__SIZE__MAX__SUM__MB="8192"
```

#### additional configurations for backup

```yaml
OPENPROJECT_BACKUP__DAILY__LIMIT="3"
OPENPROJECT_BACKUP__INCLUDE__ATTACHMENTS="true"
OPENPROJECT_BACKUP__INITIAL__WAITING__PERIOD="86400"
```

### show community links

If you would like to hide the homescreen links to the OpenProject community, you can do this with the following configuration:

*default=true*

```
OPENPROJECT_SHOW__COMMUNITY__LINKS=false
```

### web

Configuration of the main ruby web server (currently puma). Sensible *defaults* are provided.

```yaml
OPENPROJECT_WEB_WORKERS="2"
OPENPROJECT_WEB_TIMEOUT="60"
OPENPROJECT_WEB_WAIT__TIMEOUT="10"
OPENPROJECT_WEB_MIN__THREADS="4"
OPENPROJECT_WEB_MAX__THREADS="16"
```

> **NOTE:** Timeouts only are supported when using at least 2 workers.

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

By default, the TOTP strategy for phone authenticator apps is active.

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

### statsd

*default: { host: nil, port: 8125 }*

OpenProject can push metrics to [statsd](https://github.com/statsd/statsd). Currently these are simply the metrics for the puma server, but this may include more in the future.

This is disabled by default unless a host is configured.

```yaml
OPENPROJECT_STATSD_HOST="127.0.0.1"
OPENPRJOECT_STATSD_PORT="8125"
```

## Other configuration topics

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
