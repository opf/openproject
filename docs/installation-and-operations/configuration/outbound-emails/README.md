---
sidebar_navigation:
  title: Configuring outbound emails
  priority: 8
---

# Configuring outbound emails

In this guide we will describe how to configure outbound emails using an external SMTP server.

## Requirements

You will need to have SMTP settings ready. Those can either be from a company SMTP server, a Gmail account, or a public provider such as
[SendGrid](https://www.sendgrid.com/).

Taking SendGrid as an example, you would need to sign up on their website (they
offer a free plan with up to 12000 emails per month), and once your account is
provisioned, generate a new API key and copy it somewhere (it looks like
`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`). You
could also simply use your SendGrid username and password, but this is less
secure.

You can adjust those settings for other SMTP providers, such as Gmail,
Mandrill, etc. Please refer to the documentation of the corresponding provider
to see what values should be used.

## Configuration through the Admin UI

OpenProject allows you to configure your SMTP settings through the administration UI. Using the default admin account created when you first installed OpenProject, go to Administration > Emails and notifications.

At the bottom of this screen, you will find the following configuration form.

![smtp](smtp.png)

## SMTP Options

These are the options that are available. Please see the [Configuration guide](../) and [Environment variables guide](../environment) on how to set these values from the command line.

| Option                     | Setting                   | ENV name                                   | Description                                                  |
| -------------------------- | ------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| Email delivery method      | email_delivery_method     | `OPENPROJECT_EMAIL__DELIVERY__METHOD`      | email delivery method to be used (smtp, sendmail)            |
| SMTP server                | smtp_address              | `OPENPROJECT_SMTP__ADDRESS`                | Your email SMTP server host name, for example: `smtp.example.net` |
| SMTP port                  | smtp_port                 | `OPENPROJECT_SMTP__PORT`                   | SMTP server port. Common options are `25` (plain) and `587` (SSL/TLS). |
| SMTP (HELO) domain         | smtp_domain               | `OPENPROJECT_SMTP__DOMAIN`                 | Fully-qualified domain name of the SMTP client. This commonly will be the host name of the OpenProject server. |
| SMTP authentication        | smtp_authentication       | `OPENPROJECT_SMTP__AUTHENTICATION`         | Authentication method, possible values: `none`,  `plain`, `login`, `cram_md5` |
| SMTP user name             | smtp_user_name            | `OPENPROJECT_SMTP__USER__NAME`             | User name for authentication against the SMTP server (when authentication is required) |
| SMTP password              | smtp_password             | `OPENPROJECT_SMTP__PASSWORD`               | Password for authentication against the SMTP server (when authentication is required) |
| Automatically use STARTTLS | smtp_enable_starttls_auto | `OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO` | You can enable or disable STARTTLS here in case it doesn't work. Make sure you don't login to a SMTP server over a public network when using this. Recommended to leave this on if your server supports it. Possible values: true / false |
| OpenSSL verify mode        | smtp_openssl_verify_mode  | `OPENPROJECT_SMTP__OPENSSL__VERIFY__MODE`  | Define how the SMTP server certificate is validated. Make sure you don't just disable verification here unless both, OpenProject and SMTP servers are on a private network. Possible values: `none`, `peer`, `client_once` or `fail_if_no_peer_cert`.<br>Note: This setting can only be set through ENV/settings |

## Package-based installation (DEB/RPM)

If you installed OpenProject with the package-based installation, you can configure the above settings using the config:set helper. Please note that this will disable the settings in the administration UI.

```shell
openproject config:set OPENPROJECT_EMAIL__DELIVERY__METHOD=smtp
openproject config:set OPENPROJECT_SMTP__ADDRESS=smtp.sendgrid.net
openproject config:set OPENPROJECT_SMTP__PORT=587
openproject config:set OPENPROJECT_SMTP__DOMAIN=my.domain.com
openproject config:set OPENPROJECT_SMTP__AUTHENTICATION=login
openproject config:set OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO=true
openproject config:set OPENPROJECT_SMTP__USER_NAME="apikey"
openproject config:set OPENPROJECT_SMTP__PASSWORD="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"
```

## Docker installation

If you installed OpenProject with Docker, here is how you would enable outbound emails through the use of the SMTP environment variables (with SendGrid, the `SMTP_USER_NAME` is always `apikey`. Just replace `SMTP_PASSWORD` with the API key you've generated and you should be good to
go). Please note that this will disable the settings in the administration UI.

```shell
docker run -d \
  -e OPENPROJECT_EMAIL__DELIVERY__METHOD=smtp \
  -e OPENPROJECT_SMTP__ADDRESS=smtp.sendgrid.net \
  -e OPENPROJECT_SMTP__PORT=587 \
  -e OPENPROJECT_SMTP__DOMAIN=my.domain.com \
  -e OPENPROJECT_SMTP__AUTHENTICATION=login \
  -e OPENPROJECT_SMTP__ENABLE__STARTTLS__AUTO=true \
  -e OPENPROJECT_SMTP__USER_NAME="apikey" \
  -e OPENPROJECT_SMTP__PASSWORD="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" \
  ...
```
