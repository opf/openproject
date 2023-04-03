#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

OpenProject::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Access to rack session
  config.middleware.use RackSessionAccess::Middleware

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  #
  # Spring requires to have the classes reloaded. On the CI or when Spring is
  # disabled, it does not need to happen.
  config.cache_classes = ENV['CI'].present? || ENV['DISABLE_SPRING'].present?

  # Use eager load to mirror the production environment
  # on travis
  config.eager_load = ENV['CI'].present? || ENV['EAGER_LOAD'].present?

  # This setting is false by default, but we define it explicitly
  config.allow_concurrency = false

  # Configure static asset server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = true

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Enable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = true

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Silence deprecations early on for testing on CI
  deprecators.silenced = ENV['CI'].present?

  # Print deprecation notices to the stderr.
  config.active_support.deprecation =
    if ENV['CI']
      :silence
    else
      :stderr
    end

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Disable asset digests
  config.assets.compile = true
  config.assets.compress = false
  config.assets.digest = false
  config.assets.debug = false

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = true

  config.cache_store = :file_store, Rails.root.join("tmp", "cache", "paralleltests#{ENV.fetch('TEST_ENV_NUMBER', nil)}")

  # Use in-memory store for testing
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  if ENV['TEST_ENV_NUMBER']
    assets_cache_path = Rails.root.join("tmp/cache/assets/paralleltests#{ENV['TEST_ENV_NUMBER']}")
    config.assets.cache = Sprockets::Cache::FileStore.new(assets_cache_path)
  end

  # Speed up tests by lowering BCrypt's cost function
  BCrypt::Engine.cost = BCrypt::Engine::MIN_COST
end
