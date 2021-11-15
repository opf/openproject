---
sidebar_navigation:
  title: Configuring outbound emails
  priority: 8
---

# Configuring outbound emails

By default, both the docker and package-based installations will setup a postfix server to allow sending outgoing emails from your server. While it is a good starting point, it is not a recommended production setup since you will most likely run into delivery issues since your server will lack the trust of a proper email provider. 

In this guide we will describe how to configure outbound emails using an external SMTP server.

## Requirements

You will need to have SMTP settings ready. Those can either be from a company
SMTP server, a Gmail account, or a public provider such as
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

## Package-based installation (DEB/RPM)

If you installed OpenProject with the package-based installation, simply run `sudo openproject reconfigure`, and when the email wizard is displayed, select the **SMTP** option and fill in the required details ([cf the initial configuration section](../../installation/packaged/#step-4-outgoing-email-configuration))

## Docker installation

If you installed OpenProject with Docker, here is how you would enable outbound
emails through the use of the SMTP environment variables (with SendGrid, the
`SMTP_USER_NAME` is always `apikey`. Just replace `SMTP_PASSWORD` with the API
key you've generated and you should be good to
go):

```bash
docker run -d \
  -e EMAIL_DELIVERY_METHOD=smtp \
  -e SMTP_ADDRESS=smtp.sendgrid.net \
  -e SMTP_PORT=587 \
  -e SMTP_DOMAIN=my.domain.com \
  -e SMTP_AUTHENTICATION=login \
  -e SMTP_ENABLE_STARTTLS_AUTO=true \
  -e SMTP_USER_NAME="apikey" \
  -e SMTP_PASSWORD="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" \
  ...
```

## Available configuration options

* `email_delivery_method`: The way emails should be delivered. Possible values: `smtp` or `sendmail`

## SMTP Options

Please see the [Configuration guide](../) and [Environment variables guide](../environment) on how to set these values.

* `smtp_address`: SMTP server hostname, e.g. `smtp.example.net`
* `smtp_port`: SMTP server port. Common options are `25` and `587`.
* `smtp_domain`: The domain told to the SMTP server, probably the hostname of your OpenProject instance (sent in the HELO domain command). Example: `example.net`
* `smtp_authentication`: Authentication method, possible values: `plain`, `login`, `cram_md5` (optional, only when authentication is required)
* `smtp_user_name`: Username for authentication against the SMTP server (optional, only when authentication is required)
* `smtp_password` (optional, only when authentication is required)
* `smtp_enable_starttls_auto`: You can disable STARTTLS here in case it doesn't work. Make sure you don't login to a SMTP server over a public network when using this. This setting can't currently be used via environment variables, since setting options to `false` is only possible via a YAML file. (default: true, optional)
* `smtp_openssl_verify_mode`: Define how the SMTP server certificate is validated. Make sure you don't just disable verification here unless both, OpenProject and SMTP servers are on a private network. Possible values: `none`, `peer`, `client_once` or `fail_if_no_peer_cert`
