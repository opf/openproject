# Be sure to restart your server when you modify this file.
#
# This file contains migration options to ease your Rails 5.1 upgrade.
#
# Once upgraded flip defaults one by one to migrate to the new default.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.

# https://guides.rubyonrails.org/configuring.html#config-action-view-form-with-generates-remote-forms
# Make `form_with` generate non-remote forms. Previous versions had false.
# Rails 5.1, 5.2, and 6.0 default is true. Rails 6.1+ default is false.
# Let's keep it false as it is the definitive default
# Rails.application.config.action_view.form_with_generates_remote_forms = true

# https://guides.rubyonrails.org/configuring.html#config-assets-unknown-asset-fallback
# Unknown asset fallback will return the path passed in when the given
# asset is not present in the asset pipeline. Previous versions had true.
# Rails 5.1+ default is false.
# Rails.application.config.assets.unknown_asset_fallback = false
