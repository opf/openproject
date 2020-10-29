# Doorkeeper — awesome OAuth 2 provider for your Rails / Grape app.

[![Gem Version](https://badge.fury.io/rb/doorkeeper.svg)](https://rubygems.org/gems/doorkeeper)
[![Build Status](https://travis-ci.org/doorkeeper-gem/doorkeeper.svg?branch=master)](https://travis-ci.org/doorkeeper-gem/doorkeeper)
[![Code Climate](https://codeclimate.com/github/doorkeeper-gem/doorkeeper.svg)](https://codeclimate.com/github/doorkeeper-gem/doorkeeper)
[![Coverage Status](https://coveralls.io/repos/github/doorkeeper-gem/doorkeeper/badge.svg?branch=master)](https://coveralls.io/github/doorkeeper-gem/doorkeeper?branch=master)
[![Security](https://hakiri.io/github/doorkeeper-gem/doorkeeper/master.svg)](https://hakiri.io/github/doorkeeper-gem/doorkeeper/master)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)
[![GuardRails badge](https://badges.guardrails.io/doorkeeper-gem/doorkeeper.svg?token=66768ce8f6995814df81f65a2cff40f739f688492704f973e62809e15599bb62)](https://dashboard.guardrails.io/default/gh/doorkeeper-gem/doorkeeper)
[![Dependabot](https://img.shields.io/badge/dependabot-enabled-success.svg)](https://dependabot.com)

Doorkeeper is a gem (Rails engine) that makes it easy to introduce OAuth 2 provider
functionality to your Ruby on Rails or Grape application.

Supported features:

- [The OAuth 2.0 Authorization Framework](https://tools.ietf.org/html/rfc6749)
  - [Authorization Code Flow](http://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-4.1)
  - [Access Token Scopes](http://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-3.3)
  - [Refresh token](http://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-1.5)
  - [Implicit grant](http://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-4.2)
  - [Resource Owner Password Credentials](http://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-4.3)
  - [Client Credentials](http://tools.ietf.org/html/draft-ietf-oauth-v2-22#section-4.4)
- [OAuth 2.0 Token Revocation](http://tools.ietf.org/html/rfc7009)
- [OAuth 2.0 Token Introspection](https://tools.ietf.org/html/rfc7662)
- [OAuth 2.0 Threat Model and Security Considerations](http://tools.ietf.org/html/rfc6819)
- [OAuth 2.0 for Native Apps](https://tools.ietf.org/html/draft-ietf-oauth-native-apps-10)
- [Proof Key for Code Exchange by OAuth Public Clients](https://tools.ietf.org/html/rfc7636)

## Table of Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Documentation](#documentation)
- [Installation](#installation)
  - [Ruby on Rails](#ruby-on-rails)
  - [Grape](#grape)
- [ORMs](#orms)
- [Extensions](#extensions)
- [Example Applications](#example-applications)
- [Tutorials](#tutorials)
- [Sponsors](#sponsors)
- [Development](#development)
- [Contributing](#contributing)
- [Contributors](#contributors)
- [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Documentation

This documentation is valid for `master` branch. Please check the documentation for the version of doorkeeper you are using in:
https://github.com/doorkeeper-gem/doorkeeper/releases.

Additionally, other resources can be found on:

- [Guides](https://doorkeeper.gitbook.io/guides/) with how-to get started and configuration documentation
- See the [Wiki](https://github.com/doorkeeper-gem/doorkeeper/wiki) with articles and other documentation
- Screencast from [railscasts.com](http://railscasts.com/): [#353
OAuth with
Doorkeeper](http://railscasts.com/episodes/353-oauth-with-doorkeeper)
- See [upgrade guides](https://github.com/doorkeeper-gem/doorkeeper/wiki/Migration-from-old-versions)
- For general questions, please post on [Stack Overflow](http://stackoverflow.com/questions/tagged/doorkeeper)
- See [SECURITY.md](SECURITY.md) for this project's security disclose
  policy

## Installation

Installation depends on the framework you're using. The first step is to add the following to your Gemfile:

```ruby
gem 'doorkeeper'
```

And run `bundle install`. After this, check out the guide related to the framework you're using.

### Ruby on Rails

Doorkeeper currently supports Ruby on Rails >= 5.0. See the guide [here](https://doorkeeper.gitbook.io/guides/ruby-on-rails/getting-started).

### Grape

Guide for integration with Grape framework can be found [here](https://doorkeeper.gitbook.io/guides/grape/grape).

## ORMs

Doorkeeper supports Active Record by default, but can be configured to work with the following ORMs:

| ORM | Support via |
| :--- | :--- |
| Active Record | by default |
| MongoDB | [doorkeeper-gem/doorkeeper-mongodb](https://github.com/doorkeeper-gem/doorkeeper-mongodb) |
| Sequel | [nbulaj/doorkeeper-sequel](https://github.com/nbulaj/doorkeeper-sequel) |
| Couchbase | [acaprojects/doorkeeper-couchbase](https://github.com/acaprojects/doorkeeper-couchbase) |
| RethinkDB | [aca-labs/doorkeeper-rethinkdb](https://github.com/aca-labs/doorkeeper-rethinkdb) |

## Extensions

Extensions that are not included by default and can be installed separately.

|  | Link |
| :--- | :--- |
| OpenID Connect extension | [doorkeeper-gem/doorkeeper-openid\_connect](https://github.com/doorkeeper-gem/doorkeeper-openid_connect) |
| JWT Token support | [doorkeeper-gem/doorkeeper-jwt](https://github.com/doorkeeper-gem/doorkeeper-jwt) |
| Assertion grant extension | [doorkeeper-gem/doorkeeper-grants\_assertion](https://github.com/doorkeeper-gem/doorkeeper-grants_assertion) |
| I18n translations | [doorkeeper-gem/doorkeeper-i18n](https://github.com/doorkeeper-gem/doorkeeper-i18n) |

## Example Applications

These applications show how Doorkeeper works and how to integrate with it. Start with the oAuth2 server and use the clients to connect with the server.

| Application | Link |
| :--- | :--- |
| OAuth2 Server with Doorkeeper | [doorkeeper-gem/doorkeeper-provider-app](https://github.com/doorkeeper-gem/doorkeeper-provider-app) |
| Sinatra Client connected to Provider App | [doorkeeper-gem/doorkeeper-sinatra-client](https://github.com/doorkeeper-gem/doorkeeper-sinatra-client) |
| Devise + Omniauth Client | [doorkeeper-gem/doorkeeper-devise-client](https://github.com/doorkeeper-gem/doorkeeper-devise-client) |

You may want to create a client application to
test the integration. Check out these [client
examples](https://github.com/doorkeeper-gem/doorkeeper/wiki/Example-Applications)
in our wiki or follow this [tutorial
here](https://github.com/doorkeeper-gem/doorkeeper/wiki/Testing-your-provider-with-OAuth2-gem).

## Tutorials

See [list of tutorials](https://github.com/doorkeeper-gem/doorkeeper/wiki#how-tos--tutorials) in order to learn how to use the gem or integrate it with other solutions / gems.

## Sponsors

[![OpenCollective](https://opencollective.com/doorkeeper-gem/backers/badge.svg)](#backers) 
[![OpenCollective](https://opencollective.com/doorkeeper-gem/sponsors/badge.svg)](#sponsors)

Support this project by becoming a sponsor. Your logo will show up here with a link to your website. [[Become a sponsor](https://opencollective.com/doorkeeper-gem#sponsor)]

<a href="https://oauth.io/?utm_source=doorkeeper-gem" target="_blank"><img src="https://oauth.io/img/logo_text.png"/></a>

> If you prefer not to deal with the gory details of OAuth 2, need dedicated customer support & consulting, try the cloud-based SaaS version: [https://oauth.io](https://oauth.io/?utm_source=doorkeeper-gem)

<br>

<a href="https://www.wealthsimple.com/?utm_source=doorkeeper-gem" target="_blank"><img src="https://wealthsimple.s3.amazonaws.com/branding/medium-black.svg"/></a>

> Wealthsimple is a financial company on a mission to help everyone achieve financial freedom by providing products and advice that are accessible and affordable. Using smart technology, Wealthsimple takes financial services that are often confusing, opaque and expensive and makes them simple, transparent, and low-cost. See what Investing on Autopilot is all about: [https://www.wealthsimple.com](https://www.wealthsimple.com/?utm_source=doorkeeper-gem)

## Development

To run the local engine server:

```
bundle install
bundle exec rake doorkeeper:server
````

By default, it uses the latest Rails version with ActiveRecord. To run the
tests with a specific Rails version:

```
BUNDLE_GEMFILE=gemfiles/rails_6_0.gemfile bundle exec rake
```

You can also experiment with the changes using `bin/console`. It uses in-memory SQLite database and default
Doorkeeper config, but you can reestablish connection or reconfigure the gem if you need.

## Contributing

Want to contribute and don't know where to start? Check out [features we're
missing](https://github.com/doorkeeper-gem/doorkeeper/wiki/Supported-Features),
create [example
apps](https://github.com/doorkeeper-gem/doorkeeper/wiki/Example-Applications),
integrate the gem with your app and let us know!

Also, check out our [contributing guidelines page](CONTRIBUTING.md).

## Contributors

Thanks to all our [awesome
contributors](https://github.com/doorkeeper-gem/doorkeeper/graphs/contributors)!

<a href="https://github.com/doorkeeper-gem/doorkeeper/graphs/contributors"><img src="https://opencollective.com/doorkeeper-gem/contributors.svg?width=890&button=false" /></a>

## License

MIT License. Copyright 2011 Applicake.
