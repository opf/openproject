---
sidebar_navigation:
  title: SAML development setup
  priority: 920
---

# Set up a development SAML idP

**Note:** This guide is targeted only at development with OpenProject. For the SAML configuration guide, please see this [here](../../system-admin-guide/authentication/saml/)

To test the SAML integration in your development setup, you can use the following repository: [docker-test-saml-idp](https://github.com/kristophjunge/docker-test-saml-idp)

The following guide will provide insights how to set it up in your OpenProject development instance.

## Prerequisites

- A working docker installation
- A development setup of OpenProject (or any other configurable installation)

## Running the SAML idP

We need to run the SimpleSAMLphp idP contained in the docker container. We only extend it slightly by giving the user configuration file more attributes so that OpenProject can pick it up. The default users configuration is lacking some of the default attributes OpenProject expects.

Create a new folder `saml-idp`  and switch to it

```shell
mkdir saml-idp && cd saml-idp
```

Create a file `users.php` with the following content

```shell
<?php
$config = array(

  'admin' => array(
    'core:AdminPassword',
  ),

  'example-userpass' => array(
    'exampleauth:UserPass',
    'user1:user1pass' => array(
      'uid' => 'user1',
      'givenName' => 'foo',
      'sn' => 'bar',
      'eduPersonAffiliation' => array('group1'),
      'email' => 'user1@example.com',
    ),
    'user2:user2pass' => array(
      'uid' => 'user2',
      'givenName' => 'user',
      'sn' => 'second',
      'eduPersonAffiliation' => array('group2'),
      'email' => 'user2@example.com',
    ),
  ),

);
```

You can now run the docker container and the updated configuration with this command.

```shell
docker run \
-p 8080:8080 \
-p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=http://localhost:3000 \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://localhost:3000/auth/saml/callback \
-e SIMPLESAMLPHP_SP_SINGLE_LOGOUT_SERVICE=http://localhost:3000/auth/saml/slo \
-v $(pwd)/users.php:/var/www/simplesamlphp/config/authsources.php \
--network host \
kristophjunge/test-saml-idp
```

If you're not using a development installation of OpenProject, you'll need to change the ENV variables slightly:

```shell
docker run \
-p 8080:8080 \
-p 8443:8443 \
-e SIMPLESAMLPHP_SP_ENTITY_ID=http://<YOUR OPENPROJECT HOSTNAME> \
-e SIMPLESAMLPHP_SP_ASSERTION_CONSUMER_SERVICE=http://<YOUR OPENPROJECT HOSTNAME>/auth/saml/callback \
-e SIMPLESAMLPHP_SP_SINGLE_LOGOUT_SERVICE=http://<YOUR OPENPROJECT HOSTNAME>/auth/saml/slo \
-v $(pwd)/users.php:/var/www/simplesamlphp/config/authsources.php \
--network host \
kristophjunge/test-saml-idp
```

## Configure OpenProject for SAML

On the OpenProject side, you'll have to configure SAML to connect to the just started idP service:

Here's a minimal configuration that you can put into `config/configuration.yml`

```yaml
default:
  saml:
    name: "saml"
    display_name: "simplesaml-docker"
    # Use the default SAML icon
    icon: "auth_provider-saml.png"
    # omniauth-saml config
    assertion_consumer_service_url: "http://localhost:3000/auth/saml/callback"
    issuer: "http://localhost:3000"
    idp_cert_fingerprint: "119b9e027959cdb7c662cfd075d9e2ef384e445f"
    idp_sso_target_url: "http://localhost:8080/simplesaml/saml2/idp/SSOService.php"
    idp_slo_target_url: "http://localhost:8080/simplesaml/saml2/idp/SingleLogoutService.php"
    attribute_statements:
      email: ['email']
      login: ['uid']
      first_name: ['givenName']
      last_name: ['sn']
```

Here, again you  will have to change the hostname `localhost:3000` with the hostname of your OpenProject installation, and the iDP host name if you're not running both locally. I'd recommend to run both locally though for simplicity.

Restart OpenProject and you'll see a login button "simplesaml-docker". You will redirected to the simplesaml-php docker container and can login with either:

- *login*: user1, *password*: user1pass
- *login*: user2, *password*: user2pass
