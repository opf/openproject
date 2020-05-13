---
sidebar_navigation:
  title: Advanced configuration
  priority: 100
---

# OpenProject advanced configuration



OpenProject can be configured either via the `config/configuration.yml` file, [environment variables](environment/) or a mix of both.
While the latter is probably a bad idea, the environment variable option is often helpful for automatically deploying production systems.
Using the configuration file is probably the simplest way of configuration.

You can find a list of options below and an example file in [config/configuration.yml.example](https://github.com/opf/openproject/blob/dev/config/configuration.yml.example) 



## Environment variables

Configuring OpenProject through environment variables is detailed [in this separate guide](environment/).

## List of options

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
* [`disable_password_login`](#disable-password-login) (default: false)
* [`attachments_storage`](#attachments-storage) (default: file)
* [`hidden_menu_items`](#hidden-menu-items) (default: {})
* [`disabled_modules`](#disabled-modules) (default: [])
* [`blacklisted_routes`](#blacklisted-routes) (default: [])
* [`global_basic_auth`](#global-basic-auth)
* [`apiv3_enable_basic_auth`](#apiv3_enable_basic_auth)
* [`enterprise_limits`](#enterprise-limits)

## Setting session options

Use `session_store` to define where session information is stored. In order to store sessions in the database and use the following options, set that configuration to `:active_record_store`.

**Delete old sessions for the same user when logging in** (Disabled by default)

To enable, set the configuration option `drop_old_sessions_on_login` to true.

**Delete old sessions for the same user when logging out** (Enabled by default)

To disable, set the configuration option `drop_old_sessions_on_logout` to false.


### disable password login

*default: false*

If you enable this option you have to configure at least one omniauth authentication
provider to take care of authentication instead of the password login.

All username/password forms will be removed and only a list of omniauth providers
presented to the users.

### auth source sso

*default: nil*

Example:

    auth_source_sso:
      header: X-Remote-User
      
      # Optional secret to be passed by the header in form
      # of a colon-separted userinfo string
      # e.g., X-Remote-User "username:s3cret"
      secret: s3cr3t
      # Uncomment to make the header optional.
      # optional: true

Can be used to automatically login a user defined through a custom header
sent by a load balancer or reverse proxy in front of OpenProject,
for instance in a Kerberos Single Sign-On (SSO) setup via apache.
The header with the given name has to be passed to OpenProject containing the logged in
user and the defined global secret as in `$login:$secret`.

### omniauth direct login provider

*default: nil*

Example:

    omniauth_direct_login_provider: google

Per default the user may choose the usual password login as well as several omniauth providers on the login page and in the login drop down menu. With his configuration option you can set a specific omniauth provider to be used for direct login. Meaning that the login provider selection is skipped and the configured provider is used directly instead.

If this option is active /login will lead directly to the configured omniauth provider and so will a click on 'Sign in' (as opposed to opening the drop down menu).

Note that this does not stop a user from manually navigating to any other
omniauth provider if additional ones are configured.


### Gravatar images

OpenProject uses gravatar images with a `404` fallback by default to render an internal, initials-based avatar.
You can override this behavior by setting `gravatar_fallback_image` to a different value to always render Gravatars

For supported values, please see https://en.gravatar.com/site/implement/images/

### attachments storage

*default: file*

Attachments can be stored using fog as well. You will have to add further configuration through `fog`, e.g. for Amazon S3:

```
attachments_storage: fog
fog:
  directory: bucket-name
  credentials:
    provider: 'AWS'
    aws_access_key_id: 'AKIAJ23HC4KNPWHPG3UA'
    aws_secret_access_key: 'PYZO9phvL5IgyjjcI2wJdkiy6UyxPK87wP/yxPxS'
    region: 'eu-west-1'
```

In order to set these values through ENV variables, use:

```
<pre>
OPENPROJECT_ATTACHMENTS__STORAGE=fog
OPENPROJECT_FOG_CREDENTIALS_AWS__ACCESS__KEY__ID="AKIAJ23HC4KNPWHPG3UA"
OPENPROJECT_FOG_CREDENTIALS_AWS__SECRET__ACCESS__KEY="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"
OPENPROJECT_FOG_CREDENTIALS_PROVIDER=AWS
OPENPROJECT_FOG_CREDENTIALS_REGION="eu-west-1"
OPENPROJECT_FOG_DIRECTORY=uploads
</pre>

```

#### backend migration

You can migrate attachments between the available backends. One example would be that you change the configuration from
the file storage to the fog storage. If you want to put all the present file-based attachments into the cloud,
you will have to use the following rake task:

```
rake attachments:copy_to[fog]
```

It works the other way around too:

```
rake attachments:copy_to[file]
```

Note that you have to configure the respective storage (i.e. fog) beforehand as described in the previous section.
In the case of fog you only have to configure everything under `fog`, however. Don't change `attachments_storage`
to `fog` just yet. Instead leave it as `file`. This is because the current attachments storage is used as the source
for the migration.

### Overriding the help link

You can override the default help menu of OpenProject by specifying a `force_help_link` option to
the configuration. This value is used for the href of the help link, and the default dropdown is removed.

### Setting an impressum (legal notice) link

You can set a impressum link for your OpenProject instance by setting `impressum_link` to an absolute URL.

### hidden menu items

*default: {}*

You can disable specific menu items in the menu sidebar for each main menu (such as Administration and Projects).
The following example disables all menu items except 'Users', 'Groups' and 'Custom fields' under 'Administration':

```
hidden_menu_items:
  admin_menu:
    - roles
    - types
    - statuses
    - workflows
    - enumerations
    - settings
    - ldap_authentication
    - colors
    - project_types
    - export_card_configurations
    - plugins
    - info
```

The configuration can be overridden through environment variables.
You have to define one variable for each menu.
For instance 'Roles' and 'Types' under 'Administration' can be disabled by defining the following variable:

```
OPENPROJECT_HIDDEN__MENU__ITEMS_ADMIN__MENU='roles types'
```

### blacklisted routes

*default: []*

You can blacklist specific routes
The following example forbid all routes for above disabled menu:

```
blacklisted_routes:
  - 'admin/info'
  - 'admin/plugins'
  - 'export_card_configurations'
  - 'project_types'
  - 'colors'
  - 'settings'
  - 'admin/enumerations'
  - 'workflows/*'
  - 'statuses'
  - 'types'
  - 'admin/roles'
```

The configuration can be overridden through environment variables.

```
OPENPROJECT_BLACKLISTED__ROUTES='admin/info admin/plugins'
```

### disabled modules

*default: []*

Modules may be disabled through the configuration.
Just give a list of the module names either as an array or as a string with values separated by spaces.

**Array example:**

```
disabled_modules:
  - backlogs
  - meetings
```

**String example:**

```
disabled_modules: backlogs meetings
```

The option to use a string is mostly relevant for when you want to override the disabled modules via ENV variables:

```
OPENPROJECT_DISABLED__MODULES='backlogs meetings'
```

## local checkout path

*default: "repositories"*

Remote git repositories will be checked out here.

### APIv3 basic auth control

**default: true**

You can enable basic auth access to the APIv3 with the following configuration option:

```
apiv3_enable_basic_auth: true
```

### global basic auth

*default: none*

You can define a global set of credentials used to authenticate towards API v3.
Example section for `configuration.yml`:

```
default:
  authentication:
    global_basic_auth:
      user: admin
      password: admin
```

## Security badge

OpenProject now provides a release indicator (security badge) that will inform administrators of an OpenProject
installation on whether new releases or security updates are available for your platform.

If enabled, this option will display a badge with your installation status at Administration &gt; Information right next to the release version,
and on the home screen. It is only displayed to administrators.

The badge will match your current OpenProject version against the official OpenProject release database to alert you of any updates or known vulnerabilities.
To ensure the newest available update can be returned, the check will include your installation type, current version, database type, enterprise status and an anonymous unique ID of the instance.
To localize the badge, the user's locale is sent. No personal information of your installation or any user within is transmitted, processed, or stored.

To disable rendering the badge, uncheck the setting at Administration &gt; System settings &gt; General or pass
the configuration flag `security_badge_displayed: false` .

## Cache options:

* `rails_cache_store`: `memcache` for [memcached](http://www.memcached.org/) or `memory_store` (default: `file_store`)
* `cache_memcache_server`: The memcache server host and IP (default: `127.0.0.1:11211`)
* `cache_expires_in`: Expiration time for memcache entries (default: `0`, no expiry)
* `cache_namespace`: Namespace for cache keys, useful when multiple applications use a single memcache server (default: none)

## Asset options:

* `rails_asset_host`: A custom host to use to serve static assets such as javascript, CSS, images, etc. (default: `nil`)

## Onboarding variables:

* `onboarding_video_url`: An URL for the video displayed on the onboarding modal. This is only shown when the user logs in for the first time.

### Enterprise Limits

If using an Enterprise token there are certain limits that apply.
You can configure how these limits are enforced.

#### `fail_fast`

*default: false*

If you set `fail_fast` to true, new users cannot be invited or registered if the user limit has been reached.
If it is false then you can still invite and register new users but their activation will fail until the
user limit has been increased (or the number of active users decreased).

Configured in the `configuration.yml` like this:

```
enterprise:
  fail_fast: true
```

Or through the environment like this:

```
OPENPROJECT_ENTERPRISE_FAIL__FAST=true
```



| ----------- | :---------- |
| [List of supported environment variables](./environment) | The full list of environment variables you can use to override the default configuration |
| [Configuring SSL](./ssl) | How to configure SSL so that your OpenProject installation is available over HTTPS |
| [Configuring outbound emails](./outbound-emails) | How to configure outbound emails for notifications, etc. |
| [Configuring inbound emails](./incoming-emails) | How to configure inbound emails for work package updates directly from an email |
| [Configuring a custom database](./database) | How to use an external database |
| [Configuring a custom web server](./server) | How to use a custom web server (e.g. NginX) with your OpenProject installation |
| [Configuring a custom caching server](#TODO) | TODO: How to use a custom caching server with your OpenProject installation |
| [Configuring Git and Subversion repositories](./repositories) | How to integrate Git and Subversion repositories into OpenProject |
| [Adding plugins](./plugins) | How to add plugins to your OpenProject installation |
