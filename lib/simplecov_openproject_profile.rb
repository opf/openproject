require 'simplecov'
SimpleCov.profiles.define 'openproject' do
  load_profile 'rails'
  add_filter '/lib/assets'
  add_filter '/lib/plugins/gravatar'
  add_filter '/lib/plugins/rfpdf'
  add_filter '/lib/plugins/ruby-net-ldap-0.0.4'
  add_filter '/lib/redcloth3.rb'
  add_filter '/lib/SVG'
  add_filter '/spec'
  add_filter '/features'
end
