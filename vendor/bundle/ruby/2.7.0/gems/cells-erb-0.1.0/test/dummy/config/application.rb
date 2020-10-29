require File.expand_path('../boot', __FILE__)

require "active_model/railtie"
require "action_controller/railtie"
require "action_view/railtie"

module Dummy
  class Application < Rails::Application
    config.i18n.enforce_available_locales = false

    config.cache_store = :memory_store
    config.secret_token = SecureRandom.uuid
    config.secret_key_base = SecureRandom.uuid

    # enable asset pipeline as in development.
    config.assets.enabled = true
    config.assets.compile = true
    config.cache_classes = true

    # Show full error reports and disable caching
    config.consider_all_requests_local       = true
    config.action_controller.perform_caching = false

    # Raise exceptions instead of rendering exception templates
    config.action_dispatch.show_exceptions = false

    # Disable request forgery protection in test environment
    config.action_controller.allow_forgery_protection    = false
    config.active_support.deprecation = :stderr

    config.eager_load = false
    config.active_support.test_order = :random
  end
end
