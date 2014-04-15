# OpenProject OpenID Connect Plugin

Adds support for OmniAuth OpenID Connect strategy providers, most importantly Google.

## Dependencies

You will have to add the following lines to your OpenProject's _Gemfile.plugins_ for the time being:

    gem 'omniauth-openid-connect', :git => 'git@github.com:finnlabs/omniauth-openid-connect.git', :branch => 'master'
	gem 'openproject-openid_connect', :git => 'git@github.com:finnlabs/openproject-openid_connect.git', :branch => 'master'

### Development

If you want to run the tests you will have add the following as well:

    group :test do
  	  gem 'rspec-steps', '~> 0.4.0'
  	end

## Issue Tracker

https://www.openproject.org/projects/openid-connect/work_packages
