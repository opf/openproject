require 'simplecov'
SimpleCov.profiles.define 'openproject' do
  load_profile 'rails'
  add_filter '/lib/assets'
  add_filter '/lib/plugins/gravatar'
  add_filter '/lib/plugins/rfpdf'
  add_filter '/lib/SVG'
  add_filter '/spec'
  add_filter '/features'
end
