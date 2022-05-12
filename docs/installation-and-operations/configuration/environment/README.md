---
sidebar_navigation:
  title: Environment variables
  priority: 10
---



# Environment variables

When using environment variables, you can set the options by setting environment variables with the name of the options below in uppercase. So for example, to configure email delivery via an SMTP server, you can set the following environment variables:

```bash
OPENPROJECT_EMAIL__DELIVERY__METHOD="smtp"
OPENPROJECT_SMTP__ADDRESS="smtp.example.net"
OPENPROJECT_SMTP__PORT="587"
OPENPROJECT_SMTP__DOMAIN="example.net"
OPENPROJECT_SMTP__AUTHENTICATION="plain"
OPENPROJECT_SMTP__USER_NAME="user"
OPENPROJECT_SMTP__PASSWORD="password"
OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO="true"
```

In case you want to use environment variables, but you have no easy way to set them on a specific system, you can use the [dotenv](https://github.com/bkeepers/dotenv) gem. It automatically sets environment variables written to a .env file for a Rails application.



### Nested values

You can override nested configuration values as well by joining the respective hash keys with underscores.
Underscores within keys have to be escaped by doubling them.
For example, given the following configuration:

    storage:
      tmp_path: tmp

You can override it by defining the following environment variable:

    STORAGE_TMP__PATH=/some/other/path

You can also add new values this way. For instance you could add another field 'type' to the
storage config above like this:

    STORAGE_TYPE=nfs

## Passing data structures

The configuration uses YAML to parse overrides from ENV. Using YAML inline syntax, you can:

1. Pass a symbol as an override using `OPENPROJECT_SESSION__STORE=":active_record_store"`

2. Pass arrays by wrapping values in brackets (e.g., `[val1, val2, val3]`).

3. Pass hashes with `{key: foo, key2: bar}`.

To pass symbol arrays or hashes with symbol keys, use the YAML `!ruby/symbol` notation.
Example: `{!ruby/symbol key: !ruby/symbol value}` will be parsed as `{ key: :value }`.

Please note: The Configuration is a HashWithIndifferentAccess and thus it should be irrelevant for hashes to use symbol keys.


# Supported environment variables

Below is the full list of supported environment variables that can be used to override the default configuration of your OpenProject (v12) installation: (The value noted behind the : is the default value after openproject is installed)

```
OPENPROJECT_AFTER__FIRST__LOGIN__REDIRECT__URL: nil
OPENPROJECT_AFTER__LOGIN__DEFAULT__REDIRECT__URL: nil
OPENPROJECT_APIV3__ENABLE__BASIC__AUTH: true
OPENPROJECT_ATTACHMENTS__STORAGE: :file
OPENPROJECT_ATTACHMENTS__STORAGE__PATH: nil
OPENPROJECT_ATTACHMENTS__GRACE__PERIOD: 180
OPENPROJECT_AUTH__SOURCE__SSO: nil
OPENPROJECT_AUTOLOGIN__COOKIE__NAME: "autologin"
OPENPROJECT_AUTOLOGIN__COOKIE__PATH: "/"
OPENPROJECT_AUTOLOGIN__COOKIE__SECURE: false
OPENPROJECT_AVATAR__LINK__EXPIRY__SECONDS: 86400
OPENPROJECT_BACKUP__ENABLED: true
OPENPROJECT_BACKUP__DAILY__LIMIT: 3
OPENPROJECT_BACKUP__INITIAL__WAITING__PERIOD: 24 hours
OPENPROJECT_BACKUP__INCLUDE__ATTACHMENTS: true
OPENPROJECT_BACKUP__ATTACHMENT__SIZE__MAX__SUM__MB: 1024
OPENPROJECT_BLACKLISTED__ROUTES: []
OPENPROJECT_CACHE__EXPIRES__IN__SECONDS: nil
OPENPROJECT_CACHE__MEMCACHE__SERVER: nil
OPENPROJECT_CACHE__NAMESPACE: nil
OPENPROJECT_CROWDIN__IN__CONTEXT__TRANSLATIONS: true
OPENPROJECT_DATABASE__CIPHER__KEY: nil
OPENPROJECT_DEFAULT__COMMENT__SORT__ORDER: "asc"
OPENPROJECT_DIRECT__UPLOADS: true
OPENPROJECT_DISABLE__BROWSER__CACHE: true
OPENPROJECT_DISABLED__MODULES: []
OPENPROJECT_DISABLE__PASSWORD__CHOICE: false
OPENPROJECT_DISABLE__PASSWORD__LOGIN: false
OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGOUT: true
OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGIN: false
OPENPROJECT_EDITION: "standard"
OPENPROJECT_EE__MANAGER__VISIBLE: true
OPENPROJECT_ENABLE__INTERNAL__ASSETS__SERVER: false
OPENPROJECT_EMAIL__DELIVERY__CONFIGURATION: "inapp"
OPENPROJECT_EMAIL__DELIVERY__METHOD: nil
OPENPROJECT_ENTERPRISE__TRIAL__CREATION__HOST: "https://augur.openproject.com"
OPENPROJECT_ENTERPRISE__CHARGEBEE__SITE: "openproject-enterprise"
OPENPROJECT_ENTERPRISE__PLAN: "enterprise-on-premises---euro---1-year"
OPENPROJECT_FOG__DOWNLOAD__URL__EXPIRES__IN: 21600
OPENPROJECT_FORCE__HELP__LINK: nil
OPENPROJECT_FORCE__FORMATTING__HELP__LINK: nil
OPENPROJECT_HEALTH__CHECKS__AUTHENTICATION__PASSWORD: nil
OPENPROJECT_HEALTH__CHECKS__JOBS__QUEUE__COUNT__THRESHOLD: 50
OPENPROJECT_HEALTH__CHECKS__JOBS__NEVER__RAN__MINUTES__AGO: 5
OPENPROJECT_HEALTH__CHECKS__BACKLOG__THRESHOLD: 20
OPENPROJECT_GRAVATAR__FALLBACK__IMAGE: "404"
OPENPROJECT_HIDDEN__MENU__ITEMS: {}
OPENPROJECT_IMPRESSUM__LINK: nil
OPENPROJECT_INSTALLATION__TYPE: "docker"
OPENPROJECT_INTERNAL__PASSWORD__CONFIRMATION: true
OPENPROJECT_LDAP__FORCE__NO__PAGE: nil
OPENPROJECT_LDAP__AUTH__SOURCE__TLS__OPTIONS: nil
OPENPROJECT_LDAP__GROUPS__DISABLE__SYNC__JOB: false
OPENPROJECT_LDAP__TLS__OPTIONS: {}
OPENPROJECT_LOG__LEVEL: "info"
OPENPROJECT_LOGRAGE__FORMATTER: nil
OPENPROJECT_MAIN__CONTENT__LANGUAGE: "english"
OPENPROJECT_MIGRATION__CHECK__ON__EXCEPTIONS: true
OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER: nil
OPENPROJECT_OVERRIDE__BCRYPT__COST__FACTOR: nil
OPENPROJECT_ONBOARDING__VIDEO__URL: "https://player.vimeo.com/video/163426858?autoplay=1"
OPENPROJECT_ONBOARDING__ENABLED: true
OPENPROJECT_RAILS__ASSET__HOST: nil
OPENPROJECT_RAILS__CACHE__STORE: :file_store
OPENPROJECT_RAILS__RELATIVE__URL__ROOT: ""
OPENPROJECT_RAILS__FORCE__SSL: false
OPENPROJECT_REGISTRATION__FOOTER: {"en"=>""}
OPENPROJECT_SCM: {}
OPENPROJECT_SCM__GIT__COMMAND: nil
OPENPROJECT_SCM__LOCAL__CHECKOUT__PATH: "repositories"
OPENPROJECT_SCM__SUBVERSION__COMMAND: nil
OPENPROJECT_SECURITY__BADGE__DISPLAYED: true
OPENPROJECT_SECURITY__BADGE__URL: "https://releases.openproject.com/v1/check.svg"
OPENPROJECT_SENDMAIL__ARGUMENTS: "-i"
OPENPROJECT_SENDMAIL__LOCATION: "/usr/sbin/sendmail"
OPENPROJECT_SENTRY__BREADCRUMB__LOGGERS: ["active_support_logger"]
OPENPROJECT_SENTRY__DSN: nil
OPENPROJECT_SENTRY__FRONTEND__DSN: nil
OPENPROJECT_SENTRY__HOST: nil
OPENPROJECT_SENTRY__TRACE__FACTOR: 0
OPENPROJECT_SENTRY__FRONTEND__TRACE__FACTOR: 0
OPENPROJECT_SESSION__COOKIE__NAME: "_open_project_session"
OPENPROJECT_SESSION__STORE: :active_record_store
OPENPROJECT_SHOW__COMMUNITY__LINKS: true
OPENPROJECT_SHOW__PENDING__MIGRATIONS__WARNING: true
OPENPROJECT_SHOW__SETTING__MISMATCH__WARNING: true
OPENPROJECT_SHOW__STORAGE__INFORMATION: true
OPENPROJECT_SHOW__WARNING__BARS: true
OPENPROJECT_SMTP__ADDRESS: ""
OPENPROJECT_SMTP__AUTHENTICATION: "plain"
OPENPROJECT_SMTP__DOMAIN: "your.domain.com"
OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO: false
OPENPROJECT_SMTP__OPENSSL__VERIFY__MODE: "none"
OPENPROJECT_SMTP__PASSWORD: ""
OPENPROJECT_SMTP__PORT: 587
OPENPROJECT_SMTP__USER__NAME: ""
OPENPROJECT_SQL__SLOW__QUERY__THRESHOLD: 2000
OPENPROJECT_STATSD: {"host"=>nil, "port"=>8125}
OPENPROJECT_WEB: {"workers"=>2, "timeout"=>120, "wait_timeout"=>10, "min_threads"=>4, "max_threads"=>16}
OPENPROJECT_WORK__PACKAGE__LIST__DEFAULT__HIGHLIGHTING__MODE: #<Proc:0x00005647c5fdd0c8 /app/config/constants/settings/definitions.rb:934 (lambda)>
OPENPROJECT_YOUTUBE__CHANNEL: "https://www.youtube.com/c/OpenProjectCommunity"
OPENPROJECT_SAML: nil
```
