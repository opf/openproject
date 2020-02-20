---
sidebar_navigation:
  title: Environment variables
  priority: 10
---



# Environment variables

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

## Passing data structures

The configuration uses YAML to parse overrides from ENV. Using YAML inline syntax, you can:

1. Pass a symbol as an override using `OPENPROJECT_SESSION_STORE=":active_record_store"`

2. Pass arrays by wrapping values in brackets (e.g., `[val1, val2, val3]`).

3. Pass hashes with `{key: foo, key2: bar}`.

To pass symbol arrays or hashes with symbol keys, use the YAML `!ruby/symbol` notiation.
Example: `{!ruby/symbol key: !ruby/symbol value}` will be parsed as `{ key: :value }`.

Please note: The Configuration is a HashWithIndifferentAccess and thus it should be irrelevant for hashes to use symbol keys.


# Supported environment variables

Below is the full list of supported environment variables that can be used to override the default configuration of your OpenProject installation:

```
OPENPROJECT_EDITION (default="standard")                                                                                                         
OPENPROJECT_ATTACHMENTS__STORAGE (default="file")                                                                                                 
OPENPROJECT_ATTACHMENTS__STORAGE__PATH (default=nil)
OPENPROJECT_ATTACHMENTS__GRACE__PERIOD (default=180)                                                             
OPENPROJECT_AUTOLOGIN__COOKIE__NAME (default="autologin")
OPENPROJECT_AUTOLOGIN__COOKIE__PATH (default="/")
OPENPROJECT_AUTOLOGIN__COOKIE__SECURE (default=false)   
OPENPROJECT_DATABASE__CIPHER__KEY (default=nil)            
OPENPROJECT_SHOW__COMMUNITY__LINKS (default=true)      
OPENPROJECT_LOG__LEVEL (default="info")              
OPENPROJECT_SCM__GIT__COMMAND (default=nil)          
OPENPROJECT_SCM__SUBVERSION__COMMAND (default=nil)
OPENPROJECT_SCM__LOCAL__CHECKOUT__PATH (default="repositories")
OPENPROJECT_DISABLE__BROWSER__CACHE (default=true)   
OPENPROJECT_RAILS__CACHE__STORE (default=nil)                                                   
OPENPROJECT_CACHE__EXPIRES__IN__SECONDS (default=nil)
OPENPROJECT_CACHE__NAMESPACE (default=nil)
OPENPROJECT_CACHE__MEMCACHE__SERVER (default=nil)
OPENPROJECT_SESSION__STORE (default=:cache_store)
OPENPROJECT_SESSION__COOKIE__NAME (default="_open_project_session")
OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGOUT (default=true)
OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGIN (default=false)
OPENPROJECT_RAILS__RELATIVE__URL__ROOT (default="")
OPENPROJECT_RAILS__FORCE__SSL (default=false)
OPENPROJECT_RAILS__ASSET__HOST (default=nil)
OPENPROJECT_ENABLE__INTERNAL__ASSETS__SERVER (default=false)
OPENPROJECT_FORCE__HELP__LINK (default=nil)
OPENPROJECT_FORCE__FORMATTING__HELP__LINK (default=nil)
OPENPROJECT_IMPRESSUM__LINK (default=nil)
OPENPROJECT_DEFAULT__COMMENT__SORT__ORDER (default="asc")
OPENPROJECT_EMAIL__DELIVERY__CONFIGURATION (default="inapp")
OPENPROJECT_EMAIL__DELIVERY__METHOD (default=nil)
OPENPROJECT_SMTP__ADDRESS (default=nil)
OPENPROJECT_SMTP__PORT (default=nil)
OPENPROJECT_SMTP__DOMAIN (default=nil)
OPENPROJECT_SMTP__AUTHENTICATION (default=nil)                                                                                                       
OPENPROJECT_SMTP__USER__NAME (default=nil)
OPENPROJECT_SMTP__PASSWORD (default=nil)
OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO (default=nil)                                                                                            
OPENPROJECT_SMTP__OPENSSL__VERIFY__MODE (default=nil)                                                                                     
OPENPROJECT_SENDMAIL__LOCATION (default="/usr/sbinsendmail")
OPENPROJECT_SENDMAIL__ARGUMENTS (default="-i")                                                                           
OPENPROJECT_DISABLE__PASSWORD__LOGIN (default=false)
OPENPROJECT_AUTH__SOURCE__SSO (default=nil)       
OPENPROJECT_OMNIAUTH__DIRECT__LOGIN__PROVIDER (default=nil)
OPENPROJECT_INTERNAL__PASSWORD__CONFIRMATION (default=true)
OPENPROJECT_DISABLE__PASSWORD__CHOICE (default=false)    
OPENPROJECT_OVERRIDE__BCRYPT__COST__FACTOR (default=nil)
OPENPROJECT_DISABLED__MODULES (default=[])              
OPENPROJECT_HIDDEN__MENU__ITEMS (default={})               
OPENPROJECT_BLACKLISTED__ROUTES (default=[])         
OPENPROJECT_APIV3__ENABLE__BASIC__AUTH (default=true)
OPENPROJECT_ONBOARDING__VIDEO__URL (default="https://player.vimeo.com/video/163426858?autoplay=1")
OPENPROJECT_ONBOARDING__ENABLED (default=true)    
OPENPROJECT_YOUTUBE__CHANNEL (default="https://www.youtube.com/c/OpenProjectCommunity")
OPENPROJECT_EE__MANAGER__VISIBLE (default=true)      
OPENPROJECT_HEALTH__CHECKS__AUTHENTICATION__PASSWORD (default=nil)                              
OPENPROJECT_HEALTH__CHECKS__JOBS__QUEUE__COUNT__THRESHOLD (default=50)
OPENPROJECT_HEALTH__CHECKS__JOBS__NEVER__RAN__MINUTES__AGO (default=5)               
OPENPROJECT_AFTER__LOGIN__DEFAULT__REDIRECT__URL (default=nil)
OPENPROJECT_AFTER__FIRST__LOGIN__REDIRECT__URL (default=nil)   
OPENPROJECT_MAIN__CONTENT__LANGUAGE (default="english")               
OPENPROJECT_CROWDIN__IN__CONTEXT__TRANSLATIONS (default=true)         
OPENPROJECT_GRAVATAR__FALLBACK__IMAGE (default="404")      
OPENPROJECT_REGISTRATION__FOOTER (default={})            
OPENPROJECT_SECURITY__BADGE__DISPLAYED (default=true)
OPENPROJECT_INSTALLATION__TYPE (default="manual")            
OPENPROJECT_SECURITY__BADGE__URL (default="https://releases.openproject.com/v1/check.svg")
OPENPROJECT_MIGRATION__CHECK__ON__EXCEPTIONS (default=true)
OPENPROJECT_SHOW__PENDING__MIGRATIONS__WARNING (default=true)
OPENPROJECT_SHOW__WARNING__BARS (default=true) 
OPENPROJECT_SHOW__STORAGE__INFORMATION (default=true)    
```
