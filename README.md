# OpenProject Two-factor authentication plugin

Provides two-factor authentication.

## Features

* Let users configure their 2FA devices (SMS to mobile phone, TOTP app-based authenticator) through their My Account
* Force users to have 2FA present on their accounts during login


## Requirements
The OpenProject 2FA plugin requires the [OpenProject Core](https://github.com/opf/openproject/) to be in the same version as the plugin.

# Installation
To install the OpenProject 2FA plugin you need to add the following line to the `Gemfile.plugins` in your OpenProject folder (if you use a different OpenProject version than OpenProject 7, adapt `:branch => "stable/7"` to your OpenProject version):

`gem "openproject-two_factor_authentication", git: "https://github.com/opf/openproject-two_factor_authentication", :branch => "stable/7"`

Afterwards, run:

`bundle install`

### Setup

Enable the strategy of your choice through the configuration

**totp**

TOTP-based strategy for app-based authenticators such as [Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&hl=de) or [Authy](https://authy.com/).

**sns**

Amazon SNS based strategy for delivery of SMS tokens. You need an active access key and secret to send SNS. To configure the strategies, use the following YAML code.

### Enforcing users to have 2FA present

By default, this plugin enables users to add 2FA devices through their 'My account' page.
If you want all users of your instance to have 2FA enabled, set the `enforced: true` configuration flag.

Then, all users will require to register a device to complete authentication / activation of their account. They also cannot delete their default device.

``` yaml
2fa:
  active_strategies: [sns, totp]
  enforced: false
  sns:
    region: 'eu-west-1'
    access_key_id: 'aws key id'
    secret_access_key: 'aws secret'
```

or set the ENV variables

```
OPENPROJECT_2FA_ACTIVE__STRATEGIES="[sns,totp]"
OPENPROJECT_2FA_ENFORCED="false"
OPENPROJECT_2FA_SNS_REGION="eu-west-1"
OPENPROJECT_2FA_SNS_ACCESS__KEY__ID="keyid"
OPENPROJECT_2FA_SNS_SECRET__ACCESS__KEY='secret'
```

## Deinstallation

Remove the line

`gem "openproject-two_factor_authentication", git: "https://github.com/opf/openproject-two_factor_authentication", :branch => "stable/7"`

from the file `Gemfile.plugins` and run:

`bundle install`

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at
https://openproject.org/projects/two-factor-authentication

Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/opf/openproject-two_factor_authentication`

## Development

For development you only have to make sure that:

1. The strategy is enabled in the configuration
``` yaml
2fa:
  active_strategies: [developer]
```

or set the ENV variable `OPENPROJECT_2FA_ACTIVE__STRATEGIES=[developer]`.
