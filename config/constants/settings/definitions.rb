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
  add :activity_days_default,
      value: 30

  add :additional_footer_content,
      format: :string,
      value: nil

  add :app_title,
      value: 'OpenProject'

  add :attachment_max_size,
      value: 5120

  add :autofetch_changesets,
      value: true

  # autologin duration in days
  # 0 means autologin is disabled
  add :autologin,
      value: 0

  add :available_languages,
      format: :hash,
      value: %w[en de fr es pt pt-BR it zh-CN ko ru].freeze,
      allowed: -> { Redmine::I18n.all_languages }

  add :bcc_recipients,
      value: true

  add :brute_force_block_minutes,
      value: 30

  add :brute_force_block_after_failed_logins,
      value: 20

  add :cache_formatted_text,
      value: true

  add :commit_fix_done_ratio,
      value: 100

  add :commit_fix_keywords,
      value: 'fixes,closes'

  add :commit_fix_status_id,
      format: :integer,
      value: nil,
      allowed: -> { Status.pluck(:id) + [nil] }

  add :commit_logtime_activity_id,
      format: :integer,
      value: nil,
      allowed: -> { TimeEntryActivity.pluck(:id) + [nil] }

  add :commit_logtime_enabled,
      value: false

  add :commit_ref_keywords,
      value: 'refs,references,IssueID'

  add :consent_decline_mail,
      format: :string,
      value: nil

  # Time after which users have to have consented to what ever they need to consent
  # to (depending on other settings) such as a privacy policy.
  add :consent_time,
      value: nil,
      format: :datetime

  # Additional info about what the user is consenting to (optional).
  add :consent_info,
      value: {
        en: "## Consent\n\nYou need to agree to the [privacy and security policy]" +
            "(https://www.openproject.org/data-privacy-and-security/) of this OpenProject instance."
      }

  # Indicates whether or not users need to consent to something such as privacy policy.
  add :consent_required,
      value: false

  add :date_format,
      format: :string,
      value: nil,
      allowed: [
        '%Y-%m-%d',
        '%d/%m/%Y',
        '%d.%m.%Y',
        '%d-%m-%Y',
        '%m/%d/%Y',
        '%d %b %Y',
        '%d %B %Y',
        '%b %d, %Y',
        '%B %d, %Y'
      ].freeze

  add :default_auto_hide_popups,
      value: true

  add :default_language,
      value: 'en'

  add :diff_max_lines_displayed,
      value: 1500

  add :email_delivery_method,
      format: :symbol,
      value: nil

  add :enabled_scm,
      value: %w[subversion git]

  add :forced_single_page_size,
      value: 250

  add :installation_uuid,
      format: :string,
      value: nil

  add :log_requesting_user,
      value: false

  add :login_required,
      value: false

  add :lost_password,
      value: true

  add :mail_from,
      value: 'openproject@example.net'

  add :mail_handler_api_key,
      format: :string,
      value: nil

  add :password_active_rules,
      value: %w[lowercase uppercase numeric special],
      allowed: %w[lowercase uppercase numeric special]

  add :password_count_former_banned,
      value: 0

  add :password_days_valid,
      value: 0

  add :password_min_length,
      value: 10

  add :password_min_adhered_rules,
      value: 0

  # TODO: turn into array of ints
  # Requires a migration to be written
  # replace Setting#per_page_options_array
  add :per_page_options,
      value: '20, 100'

  add :plain_text_mail,
      value: false

  add :self_registration,
      value: 2

  add :sendmail_arguments,
      format: :string,
      value: "-i"

  add :sendmail_location,
      format: :string,
      value: "/usr/sbin/sendmail"

  add :smtp_enable_starttls_auto,
      format: :boolean,
      api_name: 'smtpEnableStartTLSAuto',
      value: false

  add :smtp_openssl_verify_mode,
      format: :string,
      value: "none",
      allowed: %w[none peer client_once fail_if_no_peer_cert]

  add :smtp_ssl,
      format: :boolean,
      api_name: 'smtpSSL',
      value: false

  add :smtp_address,
      format: :string,
      value: ''

  add :smtp_domain,
      format: :string,
      value: 'your.domain.com'

  add :smtp_user_name,
      format: :string,
      value: ''

  add :smtp_port,
      format: :integer,
      value: 587

  add :smtp_password,
      format: :string,
      value: ''

  add :smtp_authentication,
      format: :string,
      value: 'plain'

  add :software_name,
      value: 'OpenProject'

  add :software_url,
      value: 'https://www.openproject.org/'

  add :time_format,
      format: :string,
      value: nil,
      allowed: [
        '%H:%M',
        '%I:%M %p'
      ].freeze

  add :work_packages_export_limit,
      value: 500

  add :work_package_list_default_highlighting_mode,
      format: :string,
      value: -> { EnterpriseToken.allows_to?(:conditional_highlighting) ? 'inline' : 'none' },
      allowed: -> { Query::QUERY_HIGHLIGHTING_MODES },
      writable: -> { EnterpriseToken.allows_to?(:conditional_highlighting) }

  add :welcome_text,
      format: :string,
      value: nil

  add :welcome_title,
      format: :string,
      value: nil

  add :welcome_on_homescreen,
      value: false

  # Former configurations
  add :after_first_login_redirect_url,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :after_login_default_redirect_url,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :attachments_storage_path,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :auth_source_sso,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :cache_expires_in_seconds,
      format: :integer,
      value: nil,
      api: false,
      writable: false

  # use dalli defaults for memcache
  add :cache_memcache_server,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :cache_namespace,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :database_cipher_key,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :edition,
      format: :string,
      value: 'standard',
      api: false,
      writable: false,
      allowed: %w[standard bim]

  # Additional / overridden help links
  add :force_help_link,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :force_formatting_help_link,
      format: :string,
      value: nil,
      api: false,
      writable: false

  # Health check configuration
  add :health_checks_authentication_password,
      format: :string,
      value: nil,
      api: false,
      writable: false

  # Maximum number of backed up jobs (that are not yet executed)
  # before health check fails
  add :health_checks_jobs_queue_count_threshold,
      format: :integer,
      value: 50,
      api: false,
      writable: false
  ## Maximum number of minutes that jobs have not yet run after their designated 'run_at' time
  add :health_checks_jobs_never_ran_minutes_ago,
      format: :integer,
      value: 5,
      api: false,
      writable: false
  ## Maximum number of unprocessed requests in puma's backlog.
  add :health_checks_backlog_threshold,
      format: :integer,
      value: 20,
      api: false,
      writable: false

  # Impressum link to be set, nil by default (= hidden)
  add :impressum_link,
      format: :string,
      value: nil,
      api: false,
      writable: false

  # Allow override of LDAP options
  add :ldap_force_no_page,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :ldap_auth_source_tls_options,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :omniauth_direct_login_provider,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :override_bcrypt_cost_factor,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :rails_asset_host,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :rails_cache_store,
      format: :symbol,
      value: :file_store,
      api: false,
      writable: false,
      allowed: %i[file_store memcache]

  add :scm,
      format: :hash,
      value: {},
      api: false,
      writable: false

  add :scm_git_command,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :scm_subversion_command,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :smtp_enable_starttls_auto,
      format: :string,
      value: nil,
      api: false,
      writable: false

  # Log errors to sentry instance
  add :sentry_dsn,
      format: :string,
      value: nil,
      api: false,
      writable: false

  # Allow separate error reporting for frontend errors
  add :sentry_frontend_dsn,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :sentry_host,
      format: :string,
      value: nil,
      api: false,
      writable: false

  add :sentry_traces_sample_rate,
      format: :float,
      value: 0.1,
      api: false,
      writable: false

  # Configuration default values
  {
    'attachments_storage' => 'file',
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
    # only applicable in conjunction with fog (effectively S3) attachments
    # which will be uploaded directly to the cloud storage rather than via OpenProject's
    # server process.
    'direct_uploads' => true,
    'fog_download_url_expires_in' => 21600, # 6h by default as 6 hours is max in S3 when using IAM roles
    'show_community_links' => true,
    'log_level' => 'info',
    'scm_local_checkout_path' => 'repositories', # relative to OpenProject directory
    'disable_browser_cache' => true,
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
    # Enable internal asset server
    'enable_internal_assets_server' => false,

    # user configuration
    'default_comment_sort_order' => 'asc',

    # email configuration
    'email_delivery_configuration' => 'inapp',

    'disable_password_login' => false,
    'internal_password_confirmation' => true,

    'disable_password_choice' => false,

    'disabled_modules' => [], # allow to disable default modules
    'hidden_menu_items' => {},
    'blacklisted_routes' => [],

    'apiv3_enable_basic_auth' => true,

    'onboarding_video_url' => 'https://player.vimeo.com/video/163426858?autoplay=1',
    'onboarding_enabled' => true,

    'youtube_channel' => 'https://www.youtube.com/c/OpenProjectCommunity',

    'ee_manager_visible' => true,

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

    # Allow connection to Augur
    'enterprise_trial_creation_host' => 'https://augur.openproject.com',

    # Allow users to manually sync groups in a different way
    # than the provided job using their own cron
    'ldap_groups_disable_sync_job' => false,

    # Slow query logging threshold in ms
    'sql_slow_query_threshold' => 2000
  }.each do |key, value|
    add(key, value: value)
  end

  YAML.load_file(Rails.root.join('config/settings.yml')).map do |name, config|
    add name,
        format: config['format'] == 'int' ? :integer : config['format'],
        value: config['default'],
        api: false
  end
end
