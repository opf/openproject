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

# The list of all defined settings that however might get extended e.g. in modules/plugins
# Contains what was formerly defined in both the settings.yml as well as in configuration.rb.
# Values from the later can typically be identified by having
#   writable: false
# set. That would not be strictly necessary since they currently don't have a UI anyway and
# that is where the value is actually used.

Settings::Definition.define do
  add :activity_days_default,
      default: 30

  add :additional_footer_content,
      format: :string,
      default: nil

  add :after_first_login_redirect_url,
      format: :string,
      default: nil,
      writable: false

  add :after_login_default_redirect_url,
      format: :string,
      default: nil,
      writable: false

  add :apiv3_cors_enabled,
      default: false

  add :apiv3_cors_origins,
      default: []

  add :apiv3_docs_enabled,
      default: true

  add :apiv3_enable_basic_auth,
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
      default: :file,
      format: :symbol,
      allowed: %i[file fog],
      writable: false

  add :attachments_storage_path,
      format: :string,
      default: nil,
      writable: false

  add :attachments_grace_period,
      default: 180,
      writable: false

  add :auth_source_sso,
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
      default: 'autologin',
      writable: false

  add :autologin_cookie_path,
      default: '/',
      writable: false

  add :autologin_cookie_secure,
      default: false,
      writable: false

  add :available_languages,
      format: :array,
      default: %w[en de fr es pt pt-BR it zh-CN ko ru].freeze,
      allowed: -> { Redmine::I18n.all_languages }

  add :avatar_link_expiry_seconds,
      default: 24.hours.to_i,
      writable: false

  # Allow users with the required permissions to create backups via the web interface or API.
  add :backup_enabled,
      default: true,
      writable: false

  add :backup_daily_limit,
      default: 3,
      writable: false

  add :backup_initial_waiting_period,
      default: 24.hours,
      format: :integer,
      writable: false

  add :backup_include_attachments,
      default: true,
      writable: false

  add :backup_attachment_size_max_sum_mb,
      default: 1024,
      writable: false

  add :blacklisted_routes,
      default: [],
      writable: false

  add :bcc_recipients,
      default: true

  add :boards_demo_data_available,
      default: false

  add :brute_force_block_minutes,
      default: 30

  add :brute_force_block_after_failed_logins,
      default: 20

  add :cache_expires_in_seconds,
      format: :integer,
      default: nil,
      writable: false

  add :cache_formatted_text,
      default: true

  # use dalli defaults for memcache
  add :cache_memcache_server,
      format: :string,
      default: nil,
      writable: false

  add :cache_namespace,
      format: :string,
      default: nil,
      writable: false

  add :commit_fix_done_ratio,
      default: 100

  add :commit_fix_keywords,
      default: 'fixes,closes'

  add :commit_fix_status_id,
      format: :integer,
      default: nil,
      allowed: -> { Status.pluck(:id) + [nil] }

  # encoding used to convert commit logs to UTF-8
  add :commit_logs_encoding,
      default: 'UTF-8'

  add :commit_logtime_activity_id,
      format: :integer,
      default: nil,
      allowed: -> { TimeEntryActivity.pluck(:id) + [nil] }

  add :commit_logtime_enabled,
      default: false

  add :commit_ref_keywords,
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
      default: true,
      writable: false

  add :database_cipher_key,
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
      default: true

  # user configuration
  add :default_comment_sort_order,
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

  # only applicable in conjunction with fog (effectively S3) attachments
  # which will be uploaded directly to the cloud storage rather than via OpenProject's
  # server process.
  add :direct_uploads,
      default: true,
      writable: false

  add :disable_browser_cache,
      default: true,
      writable: false

  # allow to disable default modules
  add :disabled_modules,
      default: [],
      writable: false

  add :disable_password_choice,
      default: false,
      writable: false

  add :disable_password_login,
      default: false,
      writable: false

  add :display_subprojects_work_packages,
      default: true

  # Destroy all sessions for current_user on logout
  add :drop_old_sessions_on_logout,
      default: true,
      writable: false

  # Destroy all sessions for current_user on login
  add :drop_old_sessions_on_login,
      default: false,
      writable: false

  add :edition,
      format: :string,
      default: 'standard',
      writable: false,
      allowed: %w[standard bim]

  add :ee_manager_visible,
      default: true,
      writable: false

  # Enable internal asset server
  add :enable_internal_assets_server,
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
      default: 'https://augur.openproject.com',
      writable: false

  add :enterprise_chargebee_site,
      default: 'openproject-enterprise',
      writable: false

  add :enterprise_plan,
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

  # Configure fog, e.g. when using an S3 uploader
  add :fog,
      default: {}

  add :fog_download_url_expires_in,
      default: 21600, # 6h by default as 6 hours is max in S3 when using IAM roles
      writable: false

  # Additional / overridden help links
  add :force_help_link,
      format: :string,
      default: nil,
      writable: false

  add :force_formatting_help_link,
      format: :string,
      default: nil,
      writable: false

  add :forced_single_page_size,
      default: 250

  add :host_name,
      default: "localhost:3000"

  # Health check configuration
  add :health_checks_authentication_password,
      format: :string,
      default: nil,
      writable: false

  # Maximum number of backed up jobs (that are not yet executed)
  # before health check fails
  add :health_checks_jobs_queue_count_threshold,
      format: :integer,
      default: 50,
      writable: false

  ## Maximum number of minutes that jobs have not yet run after their designated 'run_at' time
  add :health_checks_jobs_never_ran_minutes_ago,
      format: :integer,
      default: 5,
      writable: false

  ## Maximum number of unprocessed requests in puma's backlog.
  add :health_checks_backlog_threshold,
      format: :integer,
      default: 20,
      writable: false

  # Default gravatar image, set to something other than 404
  # to ensure a default is returned
  add :gravatar_fallback_image,
      default: '404',
      writable: false

  add :hidden_menu_items,
      default: {},
      writable: false

  # Impressum link to be set, nil by default (= hidden)
  add :impressum_link,
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
      default: true,
      writable: false

  add :invitation_expiration_days,
      default: 7

  add :journal_aggregation_time_minutes,
      default: 5

  # Allow override of LDAP options
  add :ldap_force_no_page,
      format: :string,
      default: nil,
      writable: false

  # Allow users to manually sync groups in a different way
  # than the provided job using their own cron
  add :ldap_groups_disable_sync_job,
      default: false,
      writable: false

  add :ldap_users_disable_sync_job,
      default: false,
      writable: false

  # Update users' status through the synchronization job
  add :ldap_users_sync_status,
      format: :boolean,
      default: false,
      writable: false

  add :ldap_tls_options,
      format: :hash,
      default: {},
      writable: true

  add :log_level,
      default: 'info',
      writable: false

  add :log_requesting_user,
      default: false

  # Use lograge to format logs, off by default
  add :lograge_formatter,
      default: nil,
      format: :string,
      writable: false

  add :login_required,
      default: false

  add :lost_password,
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
      writable: false

  # Check for missing migrations in internal errors
  add :migration_check_on_exceptions,
      default: true,
      writable: false

  # Role given to a non-admin user who creates a project
  add :new_project_user_role_id,
      format: :integer,
      default: nil,
      allowed: -> { Role.pluck(:id) }

  add :oauth_allow_remapping_of_existing_users,
      default: false

  add :omniauth_direct_login_provider,
      format: :string,
      default: nil,
      writable: false

  add :override_bcrypt_cost_factor,
      format: :string,
      default: nil,
      writable: false

  add :notification_email_delay_minutes,
      default: 15

  add :notification_email_digest_time,
      default: '08:00'

  add :onboarding_video_url,
      default: 'https://player.vimeo.com/video/163426858?autoplay=1',
      writable: false

  add :onboarding_enabled,
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
      format: :string,
      default: nil,
      writable: false

  add :rails_cache_store,
      format: :symbol,
      default: :file_store,
      writable: false,
      allowed: %i[file_store memcache]

  # url-path prefix
  add :rails_relative_url_root,
      default: '',
      writable: false

  # Assume we're running in an TLS terminated connection.
  add :https,
      format: :boolean,
      default: -> { Rails.env.production? },
      writable: false

  # Allow disabling of HSTS headers and http -> https redirects
  # for non-localhost hosts
  add :hsts,
      format: :boolean,
      default: true,
      writable: false

  add :registration_footer,
      default: {
        'en' => ''
      },
      writable: false

  add :report_incoming_email_errors, default: true

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
      default: "https://releases.openproject.com/v1/check.svg",
      writable: false

  add :self_registration,
      default: 2

  add :sendmail_arguments,
      format: :string,
      default: "-i",
      writable: false

  add :sendmail_location,
      format: :string,
      default: "/usr/sbin/sendmail"

  # Allow separate error reporting for frontend errors
  add :appsignal_frontend_key,
      format: :string,
      default: nil,
      writable: false

  add :session_cookie_name,
      default: '_open_project_session',
      writable: false

  # where to store session data
  add :session_store,
      default: :active_record_store,
      writable: false

  add :session_ttl_enabled,
      default: false

  add :session_ttl,
      default: 120

  add :show_community_links,
      default: true,
      writable: false

  # Show pending migrations as warning bar
  add :show_pending_migrations_warning,
      default: true,
      writable: false

  # Show mismatched protocol/hostname warning
  # in settings where they must differ this can be disabled
  add :show_setting_mismatch_warning,
      default: true,
      writable: false

  # Render storage information
  add :show_storage_information,
      default: true,
      writable: false

  # Render warning bars (pending migrations, deprecation, unsupported browsers)
  # Set to false to globally disable this for all users!
  add :show_warning_bars,
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
      default: 'OpenProject'

  add :software_url,
      default: 'https://www.openproject.org/'

  # Slow query logging threshold in ms
  add :sql_slow_query_threshold,
      default: 2000,
      writable: false

  add :start_of_week,
      default: nil,
      format: :integer,
      allowed: [1, 6, 7]

  # enable statsd metrics (currently puma only) by configuring host
  add :statsd,
      default: {
        'host' => nil,
        'port' => 8125
      },
      writable: false

  add :sys_api_enabled,
      default: false

  add :sys_api_key,
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
      format: :array,
      allowed: Array(1..7),
      default: Array(1..5), # Sat, Sun being non-working days
      on_change: ->(previous_working_days) do
        WorkPackages::ApplyWorkingDaysChangeJob.perform_later(user_id: User.current.id, previous_working_days:)
      end

  add :youtube_channel,
      default: 'https://www.youtube.com/c/OpenProjectCommunity',
      writable: false
end
