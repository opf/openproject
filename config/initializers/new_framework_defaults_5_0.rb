# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 5.0 upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `5.0`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# https://guides.rubyonrails.org/configuring.html#config-action-controller-per-form-csrf-tokens
# Enable per-form CSRF tokens. Previous versions had false. Rails 5.0+ default
# is true.
# Rails.application.config.action_controller.per_form_csrf_tokens = true

# https://guides.rubyonrails.org/configuring.html#config-action-controller-forgery-protection-origin-check
# Enable origin-checking CSRF mitigation. Previous versions had false. Rails
# 5.0+ default is true.
# Rails.application.config.action_controller.forgery_protection_origin_check = true

# https://guides.rubyonrails.org/configuring.html#activesupport-to-time-preserves-timezone
# Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
# Previous versions had false. Rails 5.0+ default is true.
# ActiveSupport.to_time_preserves_timezone = true

# https://guides.rubyonrails.org/configuring.html#config-active-record-belongs-to-required-by-default
# Require `belongs_to` associations by default. Previous versions had false.
# Rails 5.0+ default is true.
# Rails.application.config.active_record.belongs_to_required_by_default = true

# https://guides.rubyonrails.org/configuring.html#config-ssl-options
# Configure SSL options to enable HSTS with subdomains. Previous versions had
# false. Rails 5.0+ default is `subdomains: true` to apply HSTS to subdomains.
# Please note that OpenProject sets it through secure_headers gem: look in
# config/initializers/secure_headers.rb:9
# Rails.application.config.ssl_options = { hsts: { subdomains: true } }
