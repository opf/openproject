# OpenProject configuration

This file describes a part of the OpenProject configuration. You can find general installation instructions [here](https://www.openproject.org/download-and-installation/). OpenProject also allows configuring many aspects via its admin interface. The config/settings.yml file should *not* be used for changing these settings.

OpenProject can be configured either via a `configuration.yml` file, environment variables or a mix of both. While the latter is probably a bad idea, the environment variable option is often helpful for automatically deploying production systems. Using the configuration file is probably the simplest way of configuration.

You can find a list of options below and an example file in [`config/configuration.yml.example`](../config/configuration.yml.example).

## Environment variables

When using environment variables, you can set the options by setting environment variables with the name of the options below in uppercase. So for example, to configure email delivery via an SMTP server, you can set the following environment variables:

```bash
EMAIL_DELIVERY_METHOD="smtp"
SMTP_ADDRESS="smtp.example.net"
SMTP_PORT="587"
SMTP_DOMAIN="example.net"
SMTP_AUTHENTICATION="plain"
SMTP_USER_NAME="user"
SMTP_PASSWORD="password"
SMTP_ENABLE_STARTTLS_AUTO="true"
```

In case you want to use environment variables, but you have no easy way to set them on a specific systme, you can use the [dotenv](https://github.com/bkeepers/dotenv) gem. It automatically sets environment variables written to a .env file for a Rails application.

### Nested values

You can override nested configuration values as well by joining the respective hash keys with underscores.
Underscores within keys have to be escaped by doubling them.
For example, given the following configuration:

    storage:
      tmp_path: tmp

You can override it by defining the following environment variable:

    OPENPROJECT_STORAGE_TMP__PATH=/some/other/path

You can also add new values this way. For instance you could add another field 'type' to the
storage config above like this:

    OPENPROJECT_STORAGE_TYPE=nfs

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
* [`omniauth_direct_login_provider`](#omniauth-direct-login-provider) (default: nil)
* [`disable_password_login`](#disable-password-login) (default: false)
* [`attachments_storage`](#attachments-storage) (default: file)
* [`hidden_menu_items`](#hidden-menu-items) (default: {})
* [`disabled_modules`](#disabled-modules) (default: [])
* [`blacklisted_routes`](#blacklisted-routes) (default: [])
* [`global_basic_auth`](#global-basic-auth)
* [`apiv3_enable_basic_auth`](#apiv3_enable_basic_auth)

## Setting session options

Use `session_store` to define where session information is stored. In order to store sessions in the database and use the following options, set that configuration to `:active_record_store`.

**Delete old sessions for the same user when logging in** (Disabled by default)

To enable, set the configuration option `drop_old_sessions_on_login` to true.

**Delete old sessions for the same user when logging out** (Enabled by default)

To disable, set the configuration option `drop_old_sessions_on_logout` to false.

## Passing data structures

The configuration uses YAML to parse overrides from ENV. Using YAML inline syntax, you can:

1. Pass a symbol as an override using `OPENPROJECT_SESSION_STORE=":active_record_store"`

1. Pass arrays by wrapping values in brackets (e.g., `[val1, val2, val3]`).

2. Pass hashes with `{key: foo, key2: bar}`.

To pass symbol arrays or hashes with symbol keys, use the YAML `!ruby/symbol` notiation.
Example: `{!ruby/symbol key: !ruby/symbol value}` will be parsed as `{ key: :value }`.

Please note: The Configuration is a HashWithIndifferentAccess and thus it should be irrelevant for hashes to use symbol keys.


### disable password login

*default: false*

If you enable this option you have to configure at least one omniauth authentication
provider to take care of authentication instead of the password login.

All username/password forms will be removed and only a list of omniauth providers
presented to the users.

### omniauth direct login provider

*default: nil*

Example:

    omniauth_direct_login_provider: google

Per default the user may choose the usual password login as well as several omniauth providers on the login page and in the login drop down menu. With his configuration option you can set a specific omniauth provider to be used for direct login. Meaning that the login provider selection is skipped and the configured provider is used directly instead.

If this option is active /login will lead directly to the configured omniauth provider and so will a click on 'Sign in' (as opposed to opening the drop down menu).

Note that this does not stop a user from manually navigating to any other
omniauth provider if additional ones are configured.

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

## Email configuration

* `email_delivery_method`: The way emails should be delivered. Possible values: `smtp` or `sendmail`

## SMTP Options:

* `smtp_address`: SMTP server hostname, e.g. `smtp.example.net`
* `smtp_port`: SMTP server port. Common options are `25` and `587`.
* `smtp_domain`: The domain told to the SMTP server, probably the hostname of your OpenProject instance (sent in the HELO domain command). Example: `example.net`
* `smtp_authentication`: Authentication method, possible values: `plain`, `login`, `cram_md5` (optional, only when authentication is required)
* `smtp_user_name`: Username for authentication against the SMTP server (optional, only when authentication is required)
* `smtp_password` (optional, only when authentication is required)
* `smtp_enable_starttls_auto`: You can disable STARTTLS here in case it doesn't work. Make sure you don't login to a SMTP server over a public network when using this. This setting can't currently be used via environment variables, since setting options to `false` is only possible via a YAML file. (default: true, optional)
* `smtp_openssl_verify_mode`: Define how the SMTP server certificate is validated. Make sure you don't just disable verification here unless both, OpenProject and SMTP servers are on a private network. Possible values: `none`, `peer`, `client_once` or `fail_if_no_peer_cert`

## Cache options:

* `rails_cache_store`: `memcache` for [memcached](http://www.memcached.org/) or `memory_store` (default: `file_store`)
* `cache_memcache_server`: The memcache server host and IP (default: `127.0.0.1:11211`)
* `cache_expires_in`: Expiration time for memcache entries (default: `0`, no expiry)
* `cache_namespace`: Namespace for cache keys, useful when multiple applications use a single memcache server (default: none)

## Asset options:

* `rails_asset_host`: A custom host to use to serve static assets such as javascript, CSS, images, etc. (default: `nil`)

## Onboarding variables:

* 'onboarding_video_url': An URL for the video displayed on the onboarding modal. This is only shown when the user logs in for the first time.
