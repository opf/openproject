#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

# The list of all defined settings that however might get extended e.g. in modules/plugins
# Contains what was formerly defined in both the settings.yml as well as in configuration.rb.
# Values from the later can typically be identified by having
#   writable: false
# set. That would not be strictly necessary since they currently don't have a UI anyway and
# that is where the value is actually used.

Settings::Definition.define do
  add :activity_days_default,
      default: 30

  add :after_first_login_redirect_url,
      format: :string,
      description: 'URL users logging in for the first time will be redirected to (e.g., a help screen)',
      default: nil,
      writable: false

  add :after_login_default_redirect_url,
      description: 'Override URL to which logged in users are redirected instead of the My page',
      format: :string,
      default: nil,
      writable: false

  add :apiv3_cors_enabled,
      description: 'Enable CORS headers for APIv3 server responses',
      default: false

  add :apiv3_cors_origins,
      default: []

  add :apiv3_docs_enabled,
      description: 'Enable interactive APIv3 documentation as part of the application',
      default: true

  add :apiv3_enable_basic_auth,
      description: 'Enable API token or global basic authentication for APIv3 requests',
      default: true,
      writable: false

  add :apiv3_max_page_size,
      default: 1000

  add :app_title,
      default: 'OpenProject'

  add :attachment_max_size,
      default: 5120

  # Existing setting
  add :attachment_whitelist,
      default: []

  ##
  # Carrierwave storage type. Possible values are, among others, :file and :fog.
  # The latter requires further configuration.
  add :attachments_storage,
      description: 'File storage configuration',
      default: :file,
      format: :symbol,
      allowed: %i[file fog],
      writable: false

  add :attachments_storage_path,
      description: 'File storage disk location (only applicable for local file storage)',
      format: :string,
      default: nil,
      writable: false

  add :attachments_grace_period,
      description: 'Time to wait before uploaded files not attached to any container are removed',
      default: 180,
      writable: false

  add :auth_source_sso,
      description: 'Configuration for Header-based Single Sign-On',
      format: :hash,
      default: nil,
      writable: false

  # Configures the authentication capabilities supported by the instance.
  # Currently this is focused on the configuration for basic auth.
  # e.g.
  # authentication:
  #   global_basic_auth:
  #     user: admin
  #     password: 123456
  add :authentication,
      description: 'Configuration options for global basic auth',
      format: :hash,
      default: nil,
      writable: false

  add :autofetch_changesets,
      default: true

  # autologin duration in days
  # 0 means autologin is disabled
  add :autologin,
      default: 0

  add :autologin_cookie_name,
      description: 'Cookie name for autologin cookie',
      default: 'autologin',
      writable: false

  add :autologin_cookie_path,
      description: 'Cookie path for autologin cookie',
      default: '/',
      writable: false

  add :autologin_cookie_secure,
      description: 'Cookie secure mode for autologin cookie',
      default: false,
      writable: false

  add :available_languages,
      format: :array,
      default: %w[en de fr es pt pt-BR it zh-CN ko ru].freeze,
      allowed: -> { Redmine::I18n.all_languages }

  add :avatar_link_expiry_seconds,
      description: 'Cache duration for avatar image API responses',
      default: 24.hours.to_i,
      writable: false

  # Allow users with the required permissions to create backups via the web interface or API.
  add :backup_enabled,
      description: 'Enable application backups through the UI',
      default: true,
      writable: false

  add :backup_daily_limit,
      description: 'Maximum number of application backups allowed per day',
      default: 3,
      writable: false

  add :backup_initial_waiting_period,
      description: 'Wait time before newly created backup tokens are usable',
      default: 24.hours,
      format: :integer,
      writable: false

  add :backup_include_attachments,
      description: 'Allow inclusion of attachments in application backups',
      default: true,
      writable: false

  add :backup_attachment_size_max_sum_mb,
      description: 'Maximum limit of attachment size to include into application backups',
      default: 1024,
      writable: false

  add :blacklisted_routes,
      description: 'Blocked routes to prevent access to certain modules or pages',
      default: [],
      writable: false

  add :bcc_recipients,
      default: true

  add :boards_demo_data_available,
      description: 'Internal setting determining availability of demo seed data',
      default: false

  add :brute_force_block_minutes,
      description: 'Number of minutes to block users after presumed brute force attack',
      default: 30

  add :brute_force_block_after_failed_logins,
      description: 'Number of login attempts per user before assuming brute force attack',
      default: 20

  add :cache_expires_in_seconds,
      description: 'Expiration time for memcache entries, empty for no expiry be default',
      format: :integer,
      default: nil,
      writable: false

  add :cache_formatted_text,
      default: true

  # use dalli defaults for memcache
  add :cache_memcache_server,
      description: 'The memcache server host and IP',
      format: :string,
      default: nil,
      writable: false

  add :cache_namespace,
      format: :string,
      description: 'Namespace for cache keys, useful when multiple applications use a single memcache server',
      default: nil,
      writable: false

  add :commit_fix_done_ratio,
      description: 'Progress to apply when commit fixes work package',
      default: 100

  add :commit_fix_keywords,
      description: 'Keywords to look for in commit for fixing work packages',
      default: 'fixes,closes'

  add :commit_fix_status_id,
      description: 'Assigned status when fixing keyword is found',
      format: :integer,
      default: nil,
      allowed: -> { Status.pluck(:id) + [nil] }

  add :commit_logs_encoding,
      description: "Encoding used to convert commit logs to UTF-8",
      default: 'UTF-8'

  add :commit_logtime_activity_id,
      description: :setting_commit_logtime_activity_id,
      format: :integer,
      default: nil,
      allowed: -> { TimeEntryActivity.pluck(:id) + [nil] }

  add :commit_logtime_enabled,
      description: "Allow logging time through commit message",
      default: false

  add :commit_ref_keywords,
      description: "Keywords used in commits for referencing work packages",
      default: 'refs,references,IssueID'

  add :consent_decline_mail,
      format: :string,
      default: nil

  # Time after which users have to have consented to what ever they need to consent
  # to (depending on other settings) such as a privacy policy.
  add :consent_time,
      default: nil,
      format: :datetime

  # Additional info about what the user is consenting to (optional).
  add :consent_info,
      default: {
        en: "## Consent\n\nYou need to agree to the [privacy and security policy]" +
          "(https://www.openproject.org/data-privacy-and-security/) of this OpenProject instance."
      }

  # Indicates whether or not users need to consent to something such as privacy policy.
  add :consent_required,
      default: false

  add :cross_project_work_package_relations,
      default: true

  # Allow in-context translations to be loaded with CSP
  add :crowdin_in_context_translations,
      description: 'Add crowdin in-context translations helper',
      default: true,
      writable: false

  add :database_cipher_key,
      description: 'Encryption key for repository credentials',
      format: :string,
      default: nil,
      writable: false

  add :date_format,
      format: :string,
      default: nil,
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
      description: 'Whether to automatically hide success notifications by default',
      default: true

  # user configuration
  add :default_comment_sort_order,
      description: 'Default sort order for activities',
      default: 'asc',
      writable: false

  add :default_language,
      default: 'en'

  add :default_projects_modules,
      default: %w[calendar board_view work_package_tracking news costs wiki],
      allowed: -> { OpenProject::AccessControl.available_project_modules.map(&:to_s) }

  add :default_projects_public,
      default: false

  add :demo_projects_available,
      default: false

  add :demo_view_of_type_work_packages_table_seeded,
      default: false

  add :demo_view_of_type_team_planner_seeded,
      default: false

  add :diff_max_lines_displayed,
      default: 1500

  add :direct_uploads,
      description: 'Enable direct uploads to AWS S3. Only applicable with enabled Fog / AWS S3 configuration',
      default: true,
      writable: false

  add :disable_browser_cache,
      description: 'Prevent browser from caching any logged-in responses for security reasons',
      default: true,
      writable: false

  # allow to disable default modules
  add :disabled_modules,
      description: 'A list of module names to prevent access to in the application',
      default: [],
      writable: false

  add :disable_password_choice,
      description: "If enabled a user's password cannot be set to an arbitrary value, but can only be randomized.",
      default: false,
      writable: false

  add :disable_password_login,
      description: 'Disable internal logins and instead only allow SSO through OmniAuth.',
      default: false,
      writable: false

  add :display_subprojects_work_packages,
      default: true

  add :drop_old_sessions_on_logout,
      description: 'Destroy all sessions for current_user on logout',
      default: true,
      writable: false

  add :drop_old_sessions_on_login,
      description: 'Destroy all sessions for current_user on login',
      default: false,
      writable: false

  add :edition,
      format: :string,
      default: 'standard',
      description: 'OpenProject edition mode',
      writable: false,
      allowed: %w[standard bim]

  add :ee_manager_visible,
      description: 'Show or hide the Enterprise configuration page and enterprise banners',
      default: true,
      writable: false

  add :enable_internal_assets_server,
      description: 'Serve assets through the Rails internal asset server',
      default: false,
      writable: false

  # email configuration
  add :email_delivery_configuration,
      default: 'inapp',
      allowed: %w[inapp legacy],
      writable: false,
      env_alias: 'EMAIL_DELIVERY_CONFIGURATION'

  add :email_delivery_method,
      format: :symbol,
      default: nil,
      env_alias: 'EMAIL_DELIVERY_METHOD'

  add :emails_footer,
      default: {
        'en' => ''
      }

  add :emails_header,
      default: {
        'en' => ''
      }

  # use email address as login, hide login in registration form
  add :email_login,
      default: false

  add :enabled_projects_columns,
      default: %w[project_status public created_at latest_activity_at required_disk_space],
      allowed: -> { Projects::TableCell.new(nil, current_user: User.admin.first).all_columns.map(&:first).map(&:to_s) }

  add :enabled_scm,
      default: %w[subversion git]

  # Allow connections for trial creation and booking
  add :enterprise_trial_creation_host,
      description: 'Host for EE trial service',
      default: 'https://augur.openproject.com',
      writable: false

  add :enterprise_chargebee_site,
      description: 'Site name for EE trial service',
      default: 'openproject-enterprise',
      writable: false

  add :enterprise_plan,
      description: 'Default EE selected plan',
      default: 'enterprise-on-premises---euro---1-year',
      writable: false

  add :feeds_enabled,
      default: true

  add :feeds_limit,
      default: 15

  # Maximum size of files that can be displayed
  # inline through the file viewer (in KB)
  add :file_max_size_displayed,
      default: 512

  add :first_week_of_year,
      default: nil,
      format: :integer,
      allowed: [1, 4]

  add :fog,
      description: 'Configure fog, e.g. when using an S3 uploader',
      default: {}

  add :fog_download_url_expires_in,
      description: 'Expiration time in seconds of created shared presigned URLs',
      default: 21600, # 6h by default as 6 hours is max in S3 when using IAM roles
      writable: false

  # Additional / overridden help links
  add :force_help_link,
      description: 'You can set a custom URL for the help button in application header menu.',
      format: :string,
      default: nil,
      writable: false

  add :force_formatting_help_link,
      description: 'You can set a custom URL for the help button in the WYSIWYG editor.',
      format: :string,
      default: nil,
      writable: false

  add :forced_single_page_size,
      description: 'Forced page size for manually sorted work package views',
      default: 250

  add :host_name,
      default: "localhost:3000"

  # Health check configuration
  add :health_checks_authentication_password,
      description: 'Add an authentication challenge for the /health_check endpoint',
      format: :string,
      default: nil,
      writable: false

  # Maximum number of backed up jobs (that are not yet executed)
  # before health check fails
  add :health_checks_jobs_queue_count_threshold,
      description: 'Set threshold of backed up background jobs to fail health check',
      format: :integer,
      default: 50,
      writable: false

  ## Maximum number of minutes that jobs have not yet run after their designated 'run_at' time
  add :health_checks_jobs_never_ran_minutes_ago,
      description: 'Set threshold of outstanding background jobs to fail health check',
      format: :integer,
      default: 5,
      writable: false

  ## Maximum number of unprocessed requests in puma's backlog.
  add :health_checks_backlog_threshold,
      description: 'Set threshold of outstanding HTTP requests to fail health check',
      format: :integer,
      default: 20,
      writable: false

  # Default gravatar image, set to something other than 404
  # to ensure a default is returned
  add :gravatar_fallback_image,
      description: 'Set default gravatar image fallback',
      default: '404',
      writable: false

  add :hidden_menu_items,
      description: 'Hide menu items in the menu sidebar for each main menu (such as Administration and Projects).',
      default: {},
      writable: false

  add :impressum_link,
      description: 'Impressum link to be set, hidden by default',
      format: :string,
      default: nil,
      writable: false

  add :installation_type,
      default: 'manual',
      writable: false

  add :installation_uuid,
      format: :string,
      default: nil

  add :internal_password_confirmation,
      description: 'Require password confirmations for certain administrative actions',
      default: true,
      writable: false

  add :invitation_expiration_days,
      default: 7

  add :journal_aggregation_time_minutes,
      default: 5

  add :ldap_force_no_page,
      description: 'Force LDAP to respond as a single page, in case paged responses do not work with your server.',
      format: :string,
      default: nil,
      writable: false

  add :ldap_groups_disable_sync_job,
      description: 'Deactivate regular synchronization job for groups in case scheduled as a separate cronjob',
      default: false,
      writable: false

  add :ldap_users_disable_sync_job,
      description: 'Deactive user attributes synchronization from LDAP',
      default: false,
      writable: false

  add :ldap_users_sync_status,
      description: 'Enable user status (locked/unlocked) synchronization from LDAP',
      format: :boolean,
      default: false,
      writable: false

  add :ldap_tls_options,
      format: :hash,
      default: {},
      writable: true

  add :log_level,
      description: 'Set the OpenProject logger level',
      default: Rails.env.development? ? 'debug' : 'info',
      allowed: %w[debug info warn error fatal],
      writable: false

  add :log_requesting_user,
      default: false

  # Use lograge to format logs, off by default
  add :lograge_formatter,
      description: 'Use lograge formatter for outputting logs',
      default: nil,
      format: :string,
      writable: false

  add :login_required,
      default: false

  add :lost_password,
      description: 'Activate or deactivate lost password form',
      default: true

  add :mail_from,
      default: 'openproject@example.net'

  add :mail_handler_api_key,
      format: :string,
      default: nil

  add :mail_handler_body_delimiters,
      default: ''

  add :mail_handler_body_delimiter_regex,
      default: ''

  add :mail_handler_ignore_filenames,
      default: 'signature.asc'

  add :mail_suffix_separators,
      default: '+'

  add :main_content_language,
      default: 'english',
      description: 'Main content language for PostgreSQL full text features',
      writable: false,
      allowed: %w[danish dutch english finnish french german hungarian
                  italian norwegian portuguese romanian russian simple spanish swedish turkish]

  add :migration_check_on_exceptions,
      description: 'Check for missing migrations in internal errors',
      default: true,
      writable: false

  # Role given to a non-admin user who creates a project
  add :new_project_user_role_id,
      format: :integer,
      default: nil,
      allowed: -> { Role.pluck(:id) }

  add :oauth_allow_remapping_of_existing_users,
      description: 'When set to false, prevent users from other identity providers to take over accounts connected ' \
                   'to another identity provider.',
      default: true

  add :omniauth_direct_login_provider,
      description: 'Clicking on login sends a login request to the specified OmniAuth provider.',
      format: :string,
      default: nil,
      writable: false

  add :override_bcrypt_cost_factor,
      description: "Set a custom BCrypt cost factor for deriving a user's bcrypt hash.",
      format: :string,
      default: nil,
      writable: false

  add :onboarding_video_url,
      description: 'Onboarding guide instructional video URL',
      default: 'https://player.vimeo.com/video/163426858?autoplay=1',
      writable: false

  add :onboarding_enabled,
      description: 'Enable or disable onboarding guided tour for new users',
      default: true,
      writable: false

  add :password_active_rules,
      default: %w[lowercase uppercase numeric special],
      allowed: %w[lowercase uppercase numeric special]

  add :password_count_former_banned,
      default: 0

  add :password_days_valid,
      default: 0

  add :password_min_length,
      default: 10

  add :password_min_adhered_rules,
      default: 0

  # TODO: turn into array of ints
  # Requires a migration to be written
  # replace Setting#per_page_options_array
  add :per_page_options,
      default: '20, 100'

  add :plain_text_mail,
      default: false

  add :project_gantt_query,
      default: nil,
      format: :string

  add :rails_asset_host,
      description: 'Custom asset hostname for serving assets (e.g., Cloudfront)',
      format: :string,
      default: nil,
      writable: false

  add :rails_cache_store,
      description: 'Set cache store implemenation to use with OpenProject',
      format: :symbol,
      default: :file_store,
      writable: false,
      allowed: %i[file_store memcache]

  add :rails_relative_url_root,
      description: 'Set a URL prefix / base path to run OpenProject under, e.g., host.tld/openproject',
      default: '',
      writable: false

  add :https,
      description: 'Set assumed connection security for the Rails processes',
      format: :boolean,
      default: -> { Rails.env.production? },
      writable: false

  add :hsts,
      description: 'Allow disabling of HSTS headers and http -> https redirects',
      format: :boolean,
      default: true,
      writable: false

  add :registration_footer,
      default: {
        'en' => ''
      },
      writable: false

  add :report_incoming_email_errors,
      description: 'Respond to incoming mails with error details',
      default: true

  add :repositories_automatic_managed_vendor,
      default: nil,
      format: :string,
      allowed: -> { OpenProject::SCM::Manager.registered.keys.map(&:to_s) }

  # encodings used to convert repository files content to UTF-8
  # multiple values accepted, comma separated
  add :repositories_encodings,
      default: nil,
      format: :string

  add :repository_authentication_caching_enabled,
      default: true

  add :repository_checkout_data,
      default: {
        "git" => { "enabled" => 0 },
        "subversion" => { "enabled" => 0 }
      }

  add :repository_log_display_limit,
      default: 100

  add :repository_storage_cache_minutes,
      default: 720

  add :repository_truncate_at,
      default: 500

  add :rest_api_enabled,
      default: true

  add :scm,
      format: :hash,
      default: {},
      writable: false

  add :scm_git_command,
      format: :string,
      default: nil,
      writable: false

  add :scm_local_checkout_path,
      default: 'repositories', # relative to OpenProject directory
      writable: false

  add :scm_subversion_command,
      format: :string,
      default: nil,
      writable: false

  # Display update / security badge, enabled by default
  add :security_badge_displayed,
      default: true

  add :security_badge_url,
      description: 'URL of the update check badge',
      default: "https://releases.openproject.com/v1/check.svg",
      writable: false

  add :self_registration,
      default: 2

  add :sendmail_arguments,
      description: 'Arguments to call sendmail with in case it is configured as outgoing email setup',
      format: :string,
      default: "-i",
      writable: false

  add :sendmail_location,
      description: 'Location of sendmail to call if it is configured as outgoing email setup',
      format: :string,
      default: "/usr/sbin/sendmail"

  # Allow separate error reporting for frontend errors
  add :appsignal_frontend_key,
      format: :string,
      default: nil,
      description: 'Appsignal API key for JavaScript error reporting',
      writable: false

  add :session_cookie_name,
      description: 'Set session cookie name',
      default: '_open_project_session',
      writable: false

  add :session_store,
      description: 'Where to store session data',
      default: :active_record_store,
      writable: false

  add :session_ttl_enabled,
      default: false

  add :session_ttl,
      default: 120

  add :show_community_links,
      description: 'Enable or disable links to OpenProject community instances',
      default: true,
      writable: false

  add :show_pending_migrations_warning,
      description: 'Enable or disable warning bar in case of pending migrations',
      default: true,
      writable: false

  add :show_setting_mismatch_warning,
      description: 'Show mismatched protocol/hostname warning. In cases where they must differ this can be disabled',
      default: true,
      writable: false

  # Render storage information
  add :show_storage_information,
      description: 'Show available and taken storage information under administration / info',
      default: true,
      writable: false

  add :show_warning_bars,
      description: 'Render warning bars (pending migrations, deprecation, unsupported browsers)',
      default: true,
      writable: false

  add :smtp_authentication,
      format: :string,
      default: 'plain',
      env_alias: 'SMTP_AUTHENTICATION'

  add :smtp_enable_starttls_auto,
      format: :boolean,
      default: false,
      env_alias: 'SMTP_ENABLE_STARTTLS_AUTO'

  add :smtp_openssl_verify_mode,
      description: 'Globally set verify mode for OpenSSL. Careful: Setting to none will disable any SSL verification!',
      format: :string,
      default: "peer",
      allowed: %w[none peer client_once fail_if_no_peer_cert],
      writable: false

  add :smtp_ssl,
      format: :boolean,
      default: false,
      env_alias: 'SMTP_SSL'

  add :smtp_address,
      format: :string,
      default: '',
      env_alias: 'SMTP_ADDRESS'

  add :smtp_domain,
      format: :string,
      default: 'your.domain.com',
      env_alias: 'SMTP_DOMAIN'

  add :smtp_user_name,
      format: :string,
      default: '',
      env_alias: 'SMTP_USER_NAME'

  add :smtp_port,
      format: :integer,
      default: 587,
      env_alias: 'SMTP_PORT'

  add :smtp_password,
      format: :string,
      default: '',
      env_alias: 'SMTP_PASSWORD'

  add :software_name,
      description: 'Override software application name',
      default: 'OpenProject'

  add :software_url,
      description: 'Override software application URL',
      default: 'https://www.openproject.org/'

  add :sql_slow_query_threshold,
      description: 'Time limit in ms after which queries will be logged as slow queries',
      default: 2000,
      writable: false

  add :start_of_week,
      default: nil,
      format: :integer,
      allowed: [1, 6, 7]

  add :statsd,
      description: 'enable statsd metrics (currently puma only) by configuring host',
      default: {
        'host' => nil,
        'port' => 8125
      },
      writable: false

  add :sys_api_enabled,
      description: 'Enable internal system API for setting up managed repositories',
      default: false

  add :sys_api_key,
      description: 'Internal system API key for setting up managed repositories',
      default: nil,
      format: :string

  add :time_format,
      format: :string,
      default: nil,
      allowed: [
        '%H:%M',
        '%I:%M %p'
      ].freeze

  add :user_default_timezone,
      default: nil,
      format: :string,
      allowed: ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.canonical_identifier }.sort.uniq + [nil]

  add :users_deletable_by_admins,
      default: false

  add :users_deletable_by_self,
      default: false

  add :user_format,
      default: :firstname_lastname,
      allowed: -> { User::USER_FORMATS_STRUCTURE.keys }

  add :web,
      description: 'Web worker count and threads configuration',
      default: {
        'workers' => 2,
        'timeout' => 120,
        'wait_timeout' => 10,
        'min_threads' => 4,
        'max_threads' => 16
      },
      writable: false

  add :welcome_text,
      format: :string,
      default: nil

  add :welcome_title,
      format: :string,
      default: nil

  add :welcome_on_homescreen,
      default: false

  add :work_package_done_ratio,
      default: 'field',
      allowed: %w[field status disabled]

  add :work_packages_projects_export_limit,
      default: 500

  add :work_package_list_default_highlighted_attributes,
      default: [],
      allowed: -> {
        Query.available_columns(nil).select(&:highlightable).map(&:name).map(&:to_s)
      }

  add :work_package_list_default_highlighting_mode,
      format: :string,
      default: -> { EnterpriseToken.allows_to?(:conditional_highlighting) ? 'inline' : 'none' },
      allowed: -> { Query::QUERY_HIGHLIGHTING_MODES },
      writable: -> { EnterpriseToken.allows_to?(:conditional_highlighting) }

  add :work_package_list_default_columns,
      default: %w[id subject type status assigned_to priority],
      allowed: -> { Query.new.displayable_columns.map(&:name).map(&:to_s) }

  add :work_package_startdate_is_adddate,
      default: false

  add :working_days,
      description: 'Set working days of the week (Array of 1 to 7, where 1=Monday, 7=Sunday)',
      format: :array,
      allowed: Array(1..7),
      default: Array(1..5) # Sat, Sun being non-working days

  add :youtube_channel,
      description: 'Link to YouTube channel in help menu',
      default: 'https://www.youtube.com/c/OpenProjectCommunity',
      writable: false
end
