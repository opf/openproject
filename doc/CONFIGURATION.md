<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2013 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

See doc/COPYRIGHT.rdoc for more details.

++-->

# OpenProject Configuration

This file describes a part of the OpenProject configuration. You can find general installation instructions [here](INSTALL.md). OpenProject also allows configuring many aspects via its admin interface. The config/settings.yml file should *not* be used for changing these settings.

OpenProject can be configured either via a `configuration.yml` file, environment variables or a mix of both. While the latter is probably a bad idea, the environment variable option is often helpful for automatically deploying production systems. Using the configuration file is probably the simplest way of configuration.

You can find a list of options below and an example file in [`config/configuration.yml.example`](../config/configuration.yml.example).

## Environment variables

When using environment variables, you can set the options by setting environment variables with the name of the options below in uppercase. So for example, to configure email delivery via an SMTP server, you can set the following environment variables:

```bash
EMAIL_DELIVERY_METHOD="smtp"
SMTP_ADDRESS="smtp.example.net"
SMTP_PORT="587"
SMTP_DOMAIN="example.net"
SMTP_AUTHENTICAITON="plain"
SMTP_USER_NAME="user"
SMTP_PASSWORD="password"
SMTP_ENABLE_STARTTLS_AUTO="true"
```

In case you want to use environment variables, but you have no easy way to set them on a specific systme, you can use the [dotenv](https://github.com/bkeepers/dotenv) gem. It automatically sets environment variables written to a .env file for a Rails application.

## List of options

* `attachments_storage_path`
* `autologin_cookie_name` (default: 'autologin'),
* `autologin_cookie_path` (default: '/')
* `autologin_cookie_secure` (default: false)
* `database_cipher_key`     (default: nil)
* `scm_git_command` (default: 'git')
* `scm_subversion_command` (default: 'git')

Email configuration

* `email_delivery_method`: The way emails should be delivered. Possible values: `smtp` or `sendmail`

SMTP Options:

* `smtp_address`: SMTP server hostname, e.g. `smtp.example.net`
* `smtp_port`: SMTP server port. Common options are `25` and `587`.
* `smtp_domain`: The domain told to the SMTP server, probably the hostname of your OpenProject instance (sent in the HELO domain command). Example: `example.net`
* `smtp_authentication`: Authentication method, possible values: `plain`, `login`, `cram_md5` (optional, only when authentication is required)
* `smtp_user_name`: Username for authentication against the SMTP server (optional, only when authentication is required)
* `smtp_password` (optional, only when authentication is required)
* `smtp_enable_starttls_auto`: You can disable STARTTLS here in case it doesn't work. Make sure you don't login to a SMTP server over a public network when using this. This setting can't currently be used via environment variables, since setting options to `false` is only possible via a YAML file. (default: true, optional)
* `smtp_openssl_verify_mode`: Define how the SMTP server certificate is validated. Make sure you don't just disable verification here unless both, OpenProject and SMTP servers are on a private network. Possible values: `none`, `peer`, `client_once` or `fail_if_no_peer_cert`
