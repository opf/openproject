#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

Settings::Definition.define do
  add :smtp_enable_starttls_auto,
      format: :boolean,
      api_name: 'smtpEnableStartTLSAuto',
      value: false,
      admin: true

  add :smtp_enable_starttls_auto,
      format: :boolean,
      api_name: 'smtpEnableStartTLSAuto',
      value: false,
      admin: true

  add :smtp_ssl,
      format: :boolean,
      api_name: 'smtpSSL',
      value: false,
      admin: true

  add :smtp_address,
      format: :string,
      value: '',
      admin: true

  add :smtp_port,
      format: :integer,
      value: 587,
      admin: true

  # Former configurations

  add :edition,
      format: :string,
      value: 'standard',
      api: false,
      admin: true,
      writable: false

  # Configuration default values
  {
    'attachments_storage' => 'file',
    'attachments_storage_path' => nil,
    'attachments_grace_period' => 180,

    # Configure fog, e.g. when using an S3 uploader
    'fog' => {},

    'autologin_cookie_name' => 'autologin',
    'autologin_cookie_path' => '/',
    'autologin_cookie_secure' => false,
    # Allow users with the required permissions to create backups via the web interface or API.
    'backup_enabled' => true,
    'backup_daily_limit' => 3,
    'backup_initial_waiting_period' => 24.hours,
    'backup_include_attachments' => true,
    'backup_attachment_size_max_sum_mb' => 1024,
    'database_cipher_key' => nil,
    # only applicable in conjunction with fog (effectively S3) attachments
    # which will be uploaded directly to the cloud storage rather than via OpenProject's
    # server process.
    'direct_uploads' => true,
    'fog_download_url_expires_in' => 21600, # 6h by default as 6 hours is max in S3 when using IAM roles
    'show_community_links' => true,
    'log_level' => 'info',
    'scm_git_command' => nil,
    'scm_subversion_command' => nil,
    'scm_local_checkout_path' => 'repositories', # relative to OpenProject directory
    'disable_browser_cache' => true,
    # default cache_store is :file_store in production and :memory_store in development
    'rails_cache_store' => nil,
    'cache_expires_in_seconds' => nil,
    'cache_namespace' => nil,
    # use dalli defaults for memcache
    'cache_memcache_server' => nil,
    # where to store session data
    'session_store' => :active_record_store,
    'session_cookie_name' => '_open_project_session',
    # Destroy all sessions for current_user on logout
    'drop_old_sessions_on_logout' => true,
    # Destroy all sessions for current_user on login
    'drop_old_sessions_on_login' => false,
    # url-path prefix
    'rails_relative_url_root' => '',
    'rails_force_ssl' => false,
    'rails_asset_host' => nil,
    # Enable internal asset server
    'enable_internal_assets_server' => false,

    # Additional / overridden help links
    'force_help_link' => nil,
    'force_formatting_help_link' => nil,

    # Impressum link to be set, nil by default (= hidden)
    'impressum_link' => nil,

    # user configuration
    'default_comment_sort_order' => 'asc',

    # email configuration
    'email_delivery_configuration' => 'inapp',
    'email_delivery_method' => nil,
    'smtp_address' => nil,
    'smtp_port' => nil,
    'smtp_domain' => nil, # HELO domain
    'smtp_authentication' => nil,
    'smtp_user_name' => nil,
    'smtp_password' => nil,
    'smtp_enable_starttls_auto' => nil,
    'smtp_openssl_verify_mode' => nil, # 'none', 'peer', 'client_once' or 'fail_if_no_peer_cert'
    'sendmail_location' => '/usr/sbin/sendmail',
    'sendmail_arguments' => '-i',

    'disable_password_login' => false,
    'auth_source_sso' => nil,
    'omniauth_direct_login_provider' => nil,
    'internal_password_confirmation' => true,

    'disable_password_choice' => false,
    'override_bcrypt_cost_factor' => nil,

    'disabled_modules' => [], # allow to disable default modules
    'hidden_menu_items' => {},
    'blacklisted_routes' => [],

    'apiv3_enable_basic_auth' => true,

    'onboarding_video_url' => 'https://player.vimeo.com/video/163426858?autoplay=1',
    'onboarding_enabled' => true,

    'youtube_channel' => 'https://www.youtube.com/c/OpenProjectCommunity',

    'ee_manager_visible' => true,

    # Health check configuration
    'health_checks_authentication_password' => nil,
    # Maximum number of backed up jobs (that are not yet executed)
    # before health check fails
    'health_checks_jobs_queue_count_threshold' => 50,
    # Maximum number of minutes that jobs have not yet run after their designated 'run_at' time
    'health_checks_jobs_never_ran_minutes_ago' => 5,
    # Maximum number of unprocessed requests in puma's backlog.
    'health_checks_backlog_threshold' => 20,

    'after_login_default_redirect_url' => nil,
    'after_first_login_redirect_url' => nil,

    'main_content_language' => 'english',

    # Allow in-context translations to be loaded with CSP
    'crowdin_in_context_translations' => true,

    'avatar_link_expiry_seconds' => 24.hours.to_i,

    # Default gravatar image, set to something other than 404
    # to ensure a default is returned
    'gravatar_fallback_image' => '404',

    'registration_footer' => {},

    # Display update / security badge, enabled by default
    'security_badge_displayed' => true,
    'installation_type' => "manual",
    'security_badge_url' => "https://releases.openproject.com/v1/check.svg",

    # Check for missing migrations in internal errors
    'migration_check_on_exceptions' => true,

    # Show pending migrations as warning bar
    'show_pending_migrations_warning' => true,

    # Show mismatched protocol/hostname warning
    # in settings where they must differ this can be disabled
    'show_setting_mismatch_warning' => true,

    # Render warning bars (pending migrations, deprecation, unsupported browsers)
    # Set to false to globally disable this for all users!
    'show_warning_bars' => true,

    # Render storage information
    'show_storage_information' => true,

    # Log errors to sentry instance
    'sentry_dsn' => nil,
    # Allow separate error reporting for frontend errors
    'sentry_frontend_dsn' => nil,
    'sentry_host' => nil,
    # Sample rate for performance monitoring
    'sentry_traces_sample_rate' => 0.1,

    # Allow connection to Augur
    'enterprise_trial_creation_host' => 'https://augur.openproject.com',

    # Allow override of LDAP options
    'ldap_auth_source_tls_options' => nil,
    'ldap_force_no_page' => false,

    # Allow users to manually sync groups in a different way
    # than the provided job using their own cron
    'ldap_groups_disable_sync_job' => false,

    # Slow query logging threshold in ms
    'sql_slow_query_threshold' => 2000
  }.each do |key, value|
    if key == 'email_delivery'
      ActiveSupport::Deprecation.warn <<~MSG
        Deprecated mail delivery settings used. Please
        update them in config/configuration.yml or use
        environment variables. See doc/CONFIGURATION.md for
        more information.
      MSG

      add('email_delivery_method', value: value['delivery_method'] || :smtp)

      %w[sendmail smtp].each do |settings_type|
        value["#{settings_type}_settings"]&.each do |key, value|
          add("#{settings_type}_#{key}", value: value)
        end
      end
    else
      add(key, value: value)
    end
  end


  YAML::load(File.open(Rails.root.join('config/settings.yml'))).map do |name, config|
    add name,
        format: config['format'],
        value: config['default'],
        serialized: config.fetch('serialized', false),
        api: false
  end
end

