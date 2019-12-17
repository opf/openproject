---
sidebar_navigation:
  title: Configuring outbound emails
  priority: 8
---

# Configuring outbound emails

By default, both the docker and package-based installations will setup a postfix server to allow sending emails from your server. While it is a good starting point, it is not a recommended production setup since you will most likely run into delivery issues since your server will lack the trust of a proper email provider. 

In this guide we will describe how to configure outbound emails using an external SMTP server.

## Requirements

You will need to have SMTP settings ready. Those can eiher be from a company
SMTP server, a GMail account, or a public provider such as
[SendGrid](https://www.sendgrid.com/).

Taking SendGrid as an example, you would need to sign up on their website (they
offer a free plan with up to 12000 emails per month), and once your account is
provisioned, generate a new API key and copy it somewhere (it looks like
`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`). You
could also simply use your SendGrid username and password, but this is less
secure.

You can adjust those settings for other SMTP providers, such as GMail,
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


