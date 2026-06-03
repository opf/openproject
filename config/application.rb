# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

require_relative "boot"

require "rails/all"
require "active_support"
require "active_support/dependencies"
require "core_extensions"
require "sprockets/railtie"
require "view_component"
require "primer/view_components"
require "primer/view_components/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups(:opf_plugins))

require_relative "../lib_static/open_project/configuration"

module OpenProject
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Initialize configuration defaults for originally generated Rails version.
    #
    # This includes defaults for versions prior to the target version. See the
    # configuration guide at
    # https://guides.rubyonrails.org/configuring.html#versioned-default-values
    # for the default values associated with a particular version.
    #
    # Goal is to reach 8.0 defaults. Overridden defaults should be stored in
    # specific initializers files. See
    # https://community.openproject.org/wp/45463 for details.
    config.load_defaults 6.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Do not require `belongs_to` associations to be present by default.
    # Rails 5.0+ default is true. Because of history, lots of tests fail when
    # set to true.
    config.active_record.belongs_to_required_by_default = false

    ###
    # Enable raising on assignment to attr_readonly attributes. The previous
    # behavior would allow assignment but silently not persist changes to the
    # database.
    # This is a rails 7.1 behaviour.
    # Ideally this should be defined in the `config/initializers/new_framework_defaults_7_1.rb`
    # file, but since there is a bug, that file is not loaded correctly in the production environment.
    # Once [the issue](https://community.openproject.org/wp/59474) is solved, this configuration can
    # be moved to the `config/initializers/new_framework_defaults_7_1.rb`.
    #++
    config.active_record.raise_on_assign_to_attr_readonly = true

    # Sets up logging for STDOUT and configures the default logger formatter
    # so that all environments receive level and timestamp information
    #
    # Use default logging formatter so that PID and timestamp are not suppressed.
    config.log_formatter = ::Logger::Formatter.new

    # Set up the cache store based on our configuration
    config.cache_store = OpenProject::Configuration.cache_store_configuration

    # Set up STDOUT logging if requested
    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger           = ActiveSupport::Logger.new($stdout)
      logger.formatter = config.log_formatter
      # Prepend all log lines with the following tags.
      config.log_tags = [:request_id]
      config.logger = ActiveSupport::TaggedLogging.new(logger)
    end

    # Use Rack::Deflater to gzip/deflate all the responses if the
    # HTTP_ACCEPT_ENCODING header is set appropriately. As Rack::ETag as
    # Rack::Deflater adds a timestamp to the content which would result in a
    # different ETag on every request, Rack::Deflater has to be in the chain of
    # middlewares after Rack::ETag.  #insert_before is used because on
    # responses, the middleware stack is processed from top to bottom.
    config.middleware.insert_before Rack::ETag,
                                    Rack::Deflater,
                                    if: lambda { |_env, _code, headers, _body|
                                      # Firefox fails to properly decode gzip attachments
                                      # We thus avoid deflating if sending gzip already.
                                      content_type = headers["Content-Type"]
                                      content_type != "application/x-gzip"
                                    }

    config.middleware.use Rack::Attack
    # Ensure that tempfiles are cleared after request
    # http://stackoverflow.com/questions/4590229
    config.middleware.use Rack::TempfileReaper

    # Add lookbook preview paths when enabled
    if OpenProject::Configuration.lookbook_enabled?
      config.paths.add Primer::ViewComponents::Engine.root.join("app/components").to_s, eager_load: true
      config.paths.add Rails.root.join("lookbook/previews").to_s, eager_load: true
      config.paths.add Primer::ViewComponents::Engine.root.join("previews").to_s, eager_load: true
    end

    # Constants in lib_static should only be loaded once and never be unloaded.
    # That directory contains configurations and patches to rails core functionality.
    config.autoload_once_paths << Rails.root.join("lib_static").to_s

    # Configure the relative url root to be whatever the configuration is set to.
    # This allows for setting the root either via config file or via environment variable.
    # It must be called early enough. In our case in should be called earlier
    # than `config.exceptions_app = routes`. Otherwise Rails.application.routes.url_helpers
    # will not have configured prefix.
    # Read https://github.com/rails/rails/issues/42243 for some details.
    config.relative_url_root = OpenProject::Configuration["rails_relative_url_root"]

    # Use our own error rendering for prettier error pages
    config.exceptions_app = routes

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Add locales from crowdin translations to i18n
    config.i18n.load_path += Dir[Rails.root.join("config/locales/crowdin/*.{rb,yml}").to_s]
    config.i18n.default_locale = :en
    # Fall back to default locale
    config.i18n.fallbacks = true

    # Enable serialization of types [Symbol, Date, Time]
    config.active_record.yaml_column_permitted_classes = [Symbol, Date, Time, ActiveSupport::HashWithIndifferentAccess]

    # Include tstzrange columns in the list of time zone aware types
    ActiveRecord::Base.time_zone_aware_types += [:tstzrange]

    # Activate being able to specify the format in which full_message works.
    # Doing this, it is e.g. possible to avoid having the format of '%{attribute} %{message}' which
    # will always prepend the attribute name to the error message.
    # The formats can then be specified using the `format:` key within the [local].yml file in every
    # layer of activerecord.errors down to the individual level of the message, e.g.
    # activerecord.errors.models.project.attributes.types.format
    config.active_model.i18n_customize_full_message = true

    # Enable cascade key lookup for i18n
    I18n.backend.class.send(:include, I18n::Backend::Cascade)

    ActiveModel::Translation.raise_on_missing_translations = Rails.env.local?

    # Use SHA-256 instead of MD5 to generate non-sensitive digests, such as the ETag header.
    # This will be the default with Rails 7.1. So when config.load_configs is set to 7.1 or above,
    # this configuration can be removed.
    Rails.application.config.active_support.hash_digest_class = OpenSSL::Digest::SHA256

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Load any local configuration that is kept out of source control
    # (e.g. patches).
    if File.exist?(File.join(File.dirname(__FILE__), "additional_environment.rb"))
      instance_eval File.read(File.join(File.dirname(__FILE__), "additional_environment.rb"))
    end

    # initialize variable for register plugin tests
    config.plugins_to_test_paths = []

    config.active_job.queue_adapter = :good_job

    config.good_job.retry_on_unhandled_error = false
    # It has been commented out because AppSignal gem modifies ActiveJob::Base to report exceptions already.
    # config.good_job.on_thread_error = -> (exception) { OpenProject.logger.error(exception) }
    config.good_job.execution_mode = :external
    config.good_job.preserve_job_records = true
    config.good_job.cleanup_preserved_jobs_before_seconds_ago = OpenProject::Configuration[:good_job_cleanup_preserved_jobs_before_seconds_ago]
    config.good_job.queues = OpenProject::Configuration[:good_job_queues]
    config.good_job.max_threads = OpenProject::Configuration[:good_job_max_threads]
    config.good_job.max_cache = OpenProject::Configuration[:good_job_max_cache]
    config.good_job.enable_cron = OpenProject::Configuration[:good_job_enable_cron]
    config.good_job.shutdown_timeout = 30
    config.good_job.smaller_number_is_higher_priority = true

    config.action_controller.asset_host = OpenProject::Configuration::AssetHost.value

    # Remove X-XSS-Protection header
    config.action_dispatch.default_headers.delete "X-XSS-Protection"

    config.log_level = OpenProject::Configuration["log_level"].to_sym

    # Enable the Rails 7 cache format
    config.active_support.cache_format_version = 7.1

    config.after_initialize do
      Settings::Definition.add_all
    end

    def root_url
       "#{Setting.protocol}://#{Setting.host_name}"
    end

    ##
    # Load core and engine tasks we're interested in
    def load_rake_tasks
      load_tasks
      Doorkeeper::Rake.load_tasks
    end
  end
end
