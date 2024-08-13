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

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.

  # Rake tasks automatically ignore this option for performance.
  # We force some rake tasks to use eager_load through enhancing with environment:eager_load
  # DISABLE those when you change this setting!
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in ENV["RAILS_MASTER_KEY"], config/master.key, or an environment
  # key such as config/credentials/production.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Enable Rails's static asset server when requested
  # Disable serving static files from `public/`, relying on NGINX/Apache to do so instead.
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Compress JavaScripts and CSS using a preprocessor.
  config.assets.js_compressor = nil
  # config.assets.css_compressor = :sass

  # Do not fallback to assets pipeline if a precompiled asset is missed.
  config.assets.compile = false

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Generate digests for assets URLs.
  config.assets.digest = true

  # Version of your assets, change this if you want to expire all your assets.
  config.assets.version = "1.0"

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  # config.active_storage.service = :local

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  # config.action_cable.url = "wss://example.com/cable"
  # config.action_cable.allowed_request_origins = [ "http://example.com", /http:\/\/example.*/ ]

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Can be used together with config.force_ssl for Strict-Transport-Security and secure cookies.
  # config.assume_ssl = true

  # When https is configured, Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Allow disabling HSTS redirect by using OPENPROJECT_HSTS=false
  config.force_ssl = OpenProject::Configuration.https?
  config.ssl_options = {
    hsts: OpenProject::Configuration.hsts_enabled?,
    # Disable redirect on the internal SYS API
    redirect: {
      exclude: ->(request) do
        # Disable redirects when hsts is disabled
        return true unless OpenProject::Configuration.hsts_enabled?

        # Respect the relative URL
        relative_url = Regexp.escape(OpenProject::Configuration["rails_relative_url_root"])

        # When we match SYS controller API, allow non-https access
        return true if /#{relative_url}\/sys\//.match?(request.path)

        # When we match health checks
        return true if /#{relative_url}\/health_checks/.match?(request.path)

        false
      end
    },
    secure_cookies: OpenProject::Configuration.https?
  }

  # Info include generic and useful information about system operation, but avoids logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII). If you
  # want to log everything, set the level to "debug".
  # config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Set to :debug to see everything in the log.
  config.log_level = OpenProject::Configuration["log_level"].to_sym

  config.assets.quiet = true unless config.log_level == :debug

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new($stdout)
    .tap  { |logger| logger.formatter = Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different logger for distributed setups.
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment).
  # config.active_job.queue_adapter = :resque
  # config.active_job.queue_name_prefix = "open_project_production"

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = ENV.fetch("OPENPROJECT_SHOW_DEPRECATIONS", nil)
  deprecators.silenced = !ENV.fetch("OPENPROJECT_SHOW_DEPRECATIONS", nil)

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Disable automatic flushing of the log to improve performance.
  config.autoflush_log = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Silence the following warning
  # "Rails couldn't infer whether you are using multiple databases from your database.yml"
  # This is deprecated in 7.1. and the warning got removed.
  config.active_record.suppress_multiple_database_warning = true

  if OpenProject::Configuration.enable_internal_assets_server?
    config.public_file_server.enabled = true
    config.public_file_server.headers = {
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" => "GET, OPTIONS, HEAD",
      "Cache-Control" => "public, s-maxage=31536000, max-age=15552000",
      "Expires" => 1.year.from_now.to_fs(:rfc822).to_s
    }
  end

  if OpenProject::Configuration.host_name.present?
    # Enable DNS rebinding protection and other `Host` header attacks.
    config.hosts = [OpenProject::Configuration.host_name] + OpenProject::Configuration.additional_host_names
    # Skip DNS rebinding protection for the default health check endpoint.
    config.host_authorization = {
      exclude: ->(request) do
        base = OpenProject::Configuration["rails_relative_url_root"]
        request.path.start_with?("#{base}/health_check", "#{base}/sys")
      end,
      response_app: ->(_env) do
        [400, { "Content-Type" => "text/plain" }, ["Invalid host_name configuration"]]
      end
    }
  end
end
