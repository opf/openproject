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

# rubocop:disable Metrics/CollectionLiteralLength
module Settings
  class Definition
    ENV_PREFIX = "OPENPROJECT_"
    AR_BOOLEAN_TYPE = ActiveRecord::Type::Boolean.new
    DEFINITIONS = {
      activity_days_default: {
        default: 30
      },
      after_first_login_redirect_url: {
        format: :string,
        description: "URL users logging in for the first time will be redirected to (e.g., a help screen)",
        default: nil
      },
      after_login_default_redirect_url: {
        description: "Override URL to which logged in users are redirected instead of the Home page",
        format: :string,
        default: nil
      },
      allowed_link_protocols: {
        format: :array,
        description: "Allowed protocols for links in the WYSIWYG editor and formatted texts",
        default: []
      },
      apiv3_cors_enabled: {
        description: "Enable CORS headers for APIv3 server responses",
        default: false
      },
      apiv3_cors_origins: {
        default: []
      },
      apiv3_docs_enabled: {
        description: "Enable interactive APIv3 documentation as part of the application",
        default: false
      },
      apiv3_enable_basic_auth: {
        description: "Enable API token or global basic authentication for APIv3 requests",
        default: true
      },
      apiv3_max_page_size: {
        default: 1000
      },
      apiv3_write_readonly_attributes: {
        description: "Allow overriding readonly attributes (e.g. createdAt, updatedAt, author) " +
          "during the creation of resources via the REST API",
        default: false
      },
      app_title: {
        default: "OpenProject"
      },
      organization_name: {
        default: "My Organization"
      },
      attachment_default_charset: {
        description: "Fallback charset used when serving text attachments whose encoding was not detected on upload",
        format: :string,
        default: "utf-8"
      },
      attachment_max_size: {
        default: 5120
      },
      # Existing setting
      attachment_whitelist: {
        default: []
      },
      ##
      # Carrierwave storage type. Possible values are, among others, :file and :fog.
      # The latter requires further configuration.
      attachments_storage: {
        description: "File storage configuration",
        default: :file,
        format: :symbol,
        allowed: %i[file fog],
        writable: false
      },
      attachments_storage_path: {
        description: "File storage disk location (only applicable for local file storage)",
        format: :string,
        default: nil,
        writable: false
      },
      attachments_grace_period: {
        description: "Time in minutes to wait before uploaded files not attached to any container are removed",
        default: 180
      },
      antivirus_scan_available: {
        description: "Virus scanning option selectable in the UI",
        default: true
      },
      antivirus_scan_mode: {
        description: "Virus scanning option for files uploaded to OpenProject",
        format: :symbol,
        default: :disabled,
        allowed: %i[disabled clamav_socket clamav_host]
      },
      antivirus_scan_target: {
        description: "The socket or hostname to connect to ClamAV",
        format: :string,
        default: nil
      },
      antivirus_scan_action: {
        description: "Virus scanning action for found infected files",
        format: :symbol,
        default: :quarantine,
        allowed: %i[quarantine delete]
      },
      api_tokens_enabled: {
        default: true,
        description: "Decide whether users can create personal API tokens in their account settings",
        # Keeping old name only for backwards-compatibility, can be removed in OpenProject 18.0
        env_alias: "OPENPROJECT_REST__API__ENABLED",
        format: :boolean
      },
      auth_source_sso: {
        description: "Configuration for Header-based Single Sign-On",
        format: :hash,
        default: nil,
        writable: false # config is cached globally so let's make it not writable
      },
      # Configures the authentication capabilities supported by the instance.
      # Currently this is focused on the configuration for basic auth.
      # e.g.
      # authentication:
      #   global_basic_auth:
      #     user: admin
      #     password: 123456
      authentication: {
        description: "Configuration options for global basic auth",
        format: :hash,
        default: nil
      },
      autofetch_changesets: {
        default: true
      },
      # autologin duration in days
      # 0 means autologin is disabled
      autologin: {
        format: :integer,
        default: 0,
        allowed: [1, 7, 14, 30, 60, 90, 365]
      },
      autologin_cookie_name: {
        description: "Cookie name for autologin cookie",
        default: "autologin"
      },
      autologin_cookie_path: {
        description: "Cookie path for autologin cookie",
        default: "/"
      },
      available_languages: {
        format: :array,
        # Manually managed list with languages that have ~50+ translation ratio in Crowdin
        # https://crowdin.com/project/openproject
        default: %w[ca cs de el en es fr hu id it ja ko lt nl no pl pt-BR pt-PT ro ru sk sl sv tr uk vi zh-CN zh-TW].freeze,
        allowed: -> { Redmine::I18n.all_languages }
      },
      avatar_link_expiration_seconds: {
        description: "Cache duration for avatar image API responses",
        default: 24.hours.to_i,
        env_alias: "OPENPROJECT_AVATAR__LINK__EXPIRY__SECONDS"
      },
      # Allow users with the required permissions to create backups via the web interface or API.
      backup_enabled: {
        description: "Enable application backups through the UI",
        default: true
      },
      backup_daily_limit: {
        description: "Maximum number of application backups allowed per day",
        default: 3
      },
      backup_initial_waiting_period: {
        description: "Wait time before newly created backup tokens are usable",
        default: 24.hours,
        format: :integer
      },
      backup_include_attachments: {
        description: "Allow inclusion of attachments in application backups",
        default: true
      },
      backup_attachment_size_max_sum_mb: {
        description: "Maximum limit of attachment size to include into application backups",
        default: 1024
      },
      blacklisted_routes: {
        description: "Blocked routes to prevent access to certain modules or pages",
        default: [],
        writable: false # used in initializer
      },
      bcc_recipients: {
        default: true
      },
      boards_demo_data_available: {
        description: "Internal setting determining availability of demo seed data",
        default: false
      },
      brute_force_block_minutes: {
        description: "Number of minutes to block users after presumed brute force attack",
        default: 30
      },
      brute_force_block_after_failed_logins: {
        description: "Number of login attempts per user before assuming brute force attack",
        default: 20
      },
      cache_expires_in_seconds: {
        description: "Expiration time for memcache entries, empty for no expiration be default",
        format: :integer,
        default: nil,
        writable: false
      },
      cache_formatted_text: {
        default: true
      },
      # use dalli defaults for memcache
      cache_memcache_server: {
        description: "The memcache server host and IP",
        format: :string,
        default: nil,
        writable: false
      },
      cache_redis_url: {
        description: "URL to the redis cache server",
        format: :string,
        default: nil,
        writable: false
      },
      cache_namespace: {
        format: :string,
        description: "Namespace for cache keys, useful when multiple applications use a single memcache server",
        default: nil,
        writable: false
      },
      total_percent_complete_mode: {
        description: "Mode in which the total % Complete for work packages in a hierarchy is calculated",
        default: "work_weighted_average",
        allowed: %w[work_weighted_average simple_average]
      },
      commit_fix_keywords: {
        description: "Keywords to look for in commit for fixing work packages",
        default: "fixes,closes"
      },
      commit_fix_status_id: {
        description: "Assigned status when fixing keyword is found",
        format: :integer,
        default: nil,
        allowed: -> { Status.pluck(:id) + [nil] }
      },
      commit_logs_encoding: {
        description: "Encoding used to convert commit logs to UTF-8",
        default: "UTF-8"
      },
      commit_logtime_activity_id: {
        description: :setting_commit_logtime_activity_id,
        format: :integer,
        default: nil,
        allowed: -> { TimeEntryActivity.pluck(:id) + [nil] }
      },
      commit_logtime_enabled: {
        description: "Allow logging time through commit message",
        default: false
      },
      commit_ref_keywords: {
        description: "Keywords used in commits for referencing work packages",
        default: "refs,references,IssueID"
      },
      consent_decline_mail: {
        format: :string,
        default: nil
      },
      # Time after which users have to have consented to what ever they need to consent
      # to (depending on other settings) such as a privacy policy.
      consent_time: {
        default: nil,
        format: :datetime
      },
      # Additional info about what the user is consenting to (optional).
      consent_info: {
        default: {
          en: "## Consent\n\nYou need to agree to the [privacy and security policy]" +
            "(https://www.openproject.org/data-privacy-and-security/) of this OpenProject instance."
        }
      },
      # Indicates whether or not users need to consent to something such as privacy policy.
      consent_required: {
        default: false
      },
      cross_project_work_package_relations: {
        default: true
      },
      csv_escape_formulas: {
        default: true,
        description: "Escapes cells with single quote in CSV exports that begin with a spreadsheet formula character (e.g., =,@)"
      },
      database_cipher_key: {
        description: "Encryption key for repository credentials",
        format: :string,
        default: nil,
        writable: false
      },
      date_format: {
        format: :string,
        default: nil,
        allowed: [
          "%Y-%m-%d",
          "%d/%m/%Y",
          "%d.%m.%Y",
          "%d-%m-%Y",
          "%m/%d/%Y",
          "%d %b %Y",
          "%d %B %Y",
          "%b %d, %Y",
          "%B %d, %Y"
        ].freeze
      },
      days_per_month: {
        description: "This will define what is considered a “month” when displaying duration in a more natural way " \
                     "(for example, if a month is 20 days, 60 days would be 3 months.",
        default: 20,
        format: :integer
      },
      default_auto_hide_popups: {
        description: "Whether to automatically hide success notifications by default",
        default: true
      },
      # user configuration
      default_comment_sort_order: {
        description: "Default sort order for activities",
        default: "asc"
      },
      disable_keyboard_shortcuts: {
        description: "Whether keyboard short cuts should be disabled (e.g. for better screen reader support)",
        default: false
      },
      default_language: {
        default: "en",
        allowed: -> { Redmine::I18n.all_languages }
      },
      default_projects_modules: {
        default: -> {
          base_modules = %w[calendar board_view work_package_tracking gantt news costs wiki]
          if Setting.real_time_text_collaboration_enabled?
            base_modules + %w[documents]
          else
            base_modules
          end
        },
        allowed: -> { OpenProject::AccessControl.available_project_modules.map(&:to_s) }
      },
      default_projects_public: {
        default: false
      },
      demo_projects_available: {
        default: false
      },
      demo_view_of_type_work_packages_table_seeded: {
        default: false
      },
      demo_view_of_type_team_planner_seeded: {
        default: false
      },
      demo_view_of_type_gantt_seeded: {
        default: false
      },
      development_highlight_enabled: {
        description: "Enable highlighting of development environment",
        default: -> { Rails.env.development? },
        format: :boolean
      },
      diff_max_lines_displayed: {
        default: 1500
      },
      direct_uploads: {
        description: "Enable direct uploads to AWS S3. Only applicable with enabled Fog / AWS S3 configuration",
        default: true,
        writable: false
      },
      disable_browser_cache: {
        description: "Prevent browser from caching any logged-in responses for security reasons",
        default: true,
        writable: false
      },
      # allow to disable default modules
      disabled_modules: {
        description: "A list of module names to prevent access to in the application",
        default: [],
        allowed: -> { OpenProject::AccessControl.available_project_modules.map(&:to_s) },
        writable: false # setting stored in global variable
      },
      disable_password_choice: {
        description: "If enabled a user's password cannot be set to an arbitrary value, but can only be randomized.",
        default: false
      },
      disable_password_login: {
        description: "Disable internal logins and instead only allow SSO through OmniAuth.",
        default: false
      },
      display_subprojects_work_packages: {
        default: true
      },
      drop_old_sessions_on_logout: {
        description: "Destroy all sessions for current_user on logout",
        default: true
      },
      drop_old_sessions_on_login: {
        description: "Destroy all sessions for current_user on login",
        default: false
      },
      duration_format: {
        description: "Format for displaying durations",
        default: "hours_only",
        allowed: %w[days_and_hours hours_only]
      },
      edition: {
        format: :string,
        default: "standard",
        description: "OpenProject edition mode",
        writable: false,
        allowed: %w[standard bim]
      },
      ee_manager_visible: {
        description: "Show the Enterprise configuration page",
        default: true,
        writable: false
      },
      ee_hide_banners: {
        description: "Hide the Enterprise enterprise banners",
        default: false
      },
      enable_internal_assets_server: {
        description: "Serve assets through the Rails internal asset server",
        default: false,
        writable: false
      },
      # email configuration
      email_delivery_configuration: {
        default: "inapp",
        allowed: %w[inapp legacy],
        writable: false,
        env_alias: "EMAIL_DELIVERY_CONFIGURATION"
      },
      email_delivery_method: {
        format: :symbol,
        default: nil,
        env_alias: "EMAIL_DELIVERY_METHOD"
      },
      emails_salutation: {
        allowed: %w[firstname name],
        default: :firstname
      },
      emails_footer: {
        default: {
          "en" => ""
        },
        string_values: true
      },
      emails_header: {
        default: {
          "en" => ""
        },
        string_values: true
      },
      # use email address as login, hide login in registration form
      email_login: {
        default: false
      },
      enabled_projects_columns: {
        default: %w[favorited name project_status public created_at latest_activity_at required_disk_space],
        allowed: -> { ProjectQuery.new.available_selects.map { |s| s.attribute.to_s } }
      },
      enabled_scm: {
        default: %w[subversion git]
      },
      # Allow connections for trial creation and booking
      enterprise_trial_creation_host: {
        description: "Host for EE trial service",
        default: "https://start.openproject.com",
        writable: false
      },
      enterprise_chargebee_site: {
        description: "Site name for EE trial service",
        default: "openproject-enterprise",
        writable: false
      },
      enterprise_plan: {
        description: "Default EE selected plan",
        default: "enterprise-on-premises---basic---euro---1-year",
        writable: false
      },
      feeds_enabled: {
        default: true
      },
      feeds_limit: {
        default: 15
      },
      # Maximum size of files that can be displayed
      # inline through the file viewer (in KB)
      file_max_size_displayed: {
        default: 512
      },
      first_week_of_year: {
        default: nil,
        format: :integer,
        allowed: [1, 4]
      },
      fog: {
        description: "Configure fog, e.g. when using an S3 uploader",
        default: {}
      },
      fog_download_url_expires_in: {
        description: "Expiration time in seconds of created shared presigned URLs",
        default: 21600 # 6h by default as 6 hours is max in S3 when using IAM roles
      },
      # Additional / overridden help links
      force_help_link: {
        description: "You can set a custom URL for the help button in application header menu.",
        format: :string,
        default: nil
      },
      force_formatting_help_link: {
        description: "You can set a custom URL for the help button in the WYSIWYG editor.",
        format: :string,
        default: nil
      },
      forced_single_page_size: {
        description: "Forced page size for manually sorted work package views",
        default: 250
      },
      good_job_queues: {
        description: "",
        format: :string,
        writable: false,
        default: "*"
      },
      good_job_max_threads: {
        description: "",
        format: :integer,
        writable: false,
        default: 20
      },
      good_job_max_cache: {
        description: "",
        format: :integer,
        writable: false,
        default: 10_000
      },
      good_job_enable_cron: {
        description: "",
        format: :boolean,
        writable: false,
        default: true
      },
      good_job_cleanup_preserved_jobs_before_seconds_ago: {
        description: "",
        format: :integer,
        writable: false,
        default: 7.days
      },
      good_job_engine_basic_auth: {
        description: "Allow basic authentication for GoodJob web interface by setting a password",
        format: :string,
        default: nil
      },
      hashed_token_pepper: {
        description: "Pepper used for HMAC-SHA256 hashing of hashed tokens (e.g. API tokens). " \
                     "Auto-initialized on first use. " \
                     "Changing this invalidates all existing hashed tokens.",
        format: :string,
        default: -> { SecureRandom.hex(32) },
        persist_on_first_read: true
      },
      host_name: {
        format: :string,
        default: -> { "#{ENV.fetch('HOST', 'localhost')}:#{ENV.fetch('PORT', 3000)}" },
        default_by_env: {
          # We do not want to set a localhost host name in production
          production: nil
        }
      },
      additional_host_names: {
        description: "Additional allowed host names for the application.",
        default: []
      },
      real_time_text_collaboration_enabled: {
        description: "Enable real-time collaborative editing of text fields using BlockNoteJS and Hocuspocus server.",
        default: -> {
          Setting.collaborative_editing_hocuspocus_url.present? &&
            Setting.collaborative_editing_hocuspocus_secret.present?
        }
      },
      collaborative_editing_hocuspocus_url: {
        format: :string,
        default: nil,
        description: "The URL of the hocuspocus server used by BlockNoteJS editor to enable collaborative editing.",
        default_by_env: {
          development: "wss://hocuspocus.local"
        }
      },
      collaborative_editing_hocuspocus_secret: {
        format: :string,
        default: nil,
        default_by_env: {
          development: "secret12345"
        },
        description: "The secret used for generating access tokens to access documents on hocuspocus server."
      },
      hours_per_day: {
        description: "This will define what is considered a “day” when displaying duration in a more natural way " \
                     "(for example, if a day is 8 hours, 32 hours would be 4 days).",
        default: 8,
        format: :integer
      },
      # Health check configuration
      health_checks_authentication_password: {
        description: "Add an authentication challenge for the /health_check endpoint",
        format: :string,
        default: nil
      },
      ## Maximum number of minutes that jobs have not yet run after their designated 'run_at' time
      health_checks_jobs_never_ran_minutes_ago: {
        description: "Set threshold of outstanding background jobs to fail health check",
        format: :integer,
        default: 5
      },
      ## Maximum number of unprocessed requests in puma's backlog.
      health_checks_backlog_threshold: {
        description: "Set threshold of outstanding HTTP requests to fail health check",
        format: :integer,
        default: 20
      },
      # Default gravatar image, set to something other than 404
      # to ensure a default is returned
      gravatar_fallback_image: {
        description: "Set default gravatar image fallback",
        default: "404"
      },
      hidden_menu_items: {
        description: "Hide menu items in the menu sidebar for each main menu (such as Administration and Projects).",
        default: {},
        writable: false # cached in global variable
      },
      ical_feed_keep_closed_meetings_days: {
        description: "Number of days to keep closed and in-progress one-time meetings in iCal feeds",
        format: :integer,
        default: 30
      },
      impressum_link: {
        description: "Impressum link to be set, hidden by default",
        format: :string,
        default: nil
      },
      installation_type: {
        default: "manual",
        writable: false
      },
      installation_uuid: {
        format: :string,
        default: -> { SecureRandom.uuid },
        persist_on_first_read: true,
        default_by_env: {
          test: "test_uuid"
        }
      },
      internal_password_confirmation: {
        description: "Require password confirmations for certain administrative actions",
        default: true
      },
      invitation_expiration_days: {
        default: 7
      },
      journal_aggregation_time_minutes: {
        default: 5
      },
      ldap_force_no_page: {
        description: "Force LDAP to respond as a single page, in case paged responses do not work with your server.",
        format: :string,
        default: nil
      },
      ldap_groups_disable_sync_job: {
        description: "Deactivate regular synchronization job for groups in case scheduled as a separate cronjob",
        default: false
      },
      ldap_users_disable_sync_job: {
        description: "Deactivate user attributes synchronization from LDAP",
        default: false
      },
      ldap_users_sync_status: {
        description: "Enable user status (locked/unlocked) synchronization from LDAP",
        format: :boolean,
        default: false
      },
      log_level: {
        description: "Set the OpenProject logger level",
        default: Rails.env.development? ? "debug" : "info",
        allowed: %w[debug info warn error fatal],
        writable: false
      },
      log_requesting_user: {
        default: false
      },
      lograge_enabled: {
        description: "Use lograge formatter for outputting logs",
        default: true,
        format: :boolean,
        writable: false
      },
      lograge_formatter: {
        description: "Lograge formatter to use for outputting logs",
        default: "key_value",
        format: :string,
        writable: false
      },
      login_required: {
        default: true
      },
      lookbook_enabled: {
        description: "Enable the Lookbook component documentation tool. Discouraged for production environments.",
        default: -> { Rails.env.development? },
        format: :boolean
      },
      lost_password: {
        description: "Activate or deactivate lost password form",
        default: true
      },
      mail_from: {
        default: "openproject@example.net"
      },
      mail_handler_api_key: {
        format: :string,
        default: nil
      },
      mail_handler_body_delimiters: {
        default: ""
      },
      mail_handler_body_delimiter_regex: {
        default: ""
      },
      mail_handler_ignore_filenames: {
        default: "signature.asc"
      },
      mail_suffix_separators: {
        default: "+"
      },
      main_content_language: {
        default: "english",
        description: "Main content language for PostgreSQL full text features",
        writable: false,
        allowed: %w[danish dutch english finnish french german hungarian
                    italian norwegian portuguese romanian russian simple spanish swedish turkish]
      },
      mcp_tool_response_format: {
        default: :full,
        format: :symbol,
        allowed: -> { McpTools::Base::RESPONSE_FORMATS },
        description: "How to format responses for MCP tools. Using values other than full may improve language model performance."
      },
      migration_check_on_exceptions: {
        description: "Check for missing migrations in internal errors",
        default: true,
        writable: false
      },
      # Role given to a non-admin user who creates a project
      new_project_user_role_id: {
        format: :integer,
        default: nil,
        allowed: -> { Role.pluck(:id) }
      },
      new_project_send_confirmation_email: {
        format: :boolean,
        default: false
      },
      new_project_notification_text: {
        format: :string,
        default: ""
      },
      notifications_hidden: {
        default: false
      },
      notifications_polling_interval: {
        format: :integer,
        default: 60000
      },
      oauth_allow_remapping_of_existing_users: {
        description: "When set to false, prevent users from other identity providers to take over accounts " \
                     "that exist in OpenProject.",
        format: :boolean,
        default: true
      },
      omniauth_direct_login_provider: {
        description: "Clicking on login sends a login request to the specified OmniAuth provider.",
        format: :string,
        default: nil
      },
      override_bcrypt_cost_factor: {
        description: "Set a custom BCrypt cost factor for deriving a user's bcrypt hash.",
        format: :string,
        default: nil,
        writable: false # this changes a global variable and must therefore not be writable at runtime
      },
      onboarding_enabled: {
        description: "Enable or disable onboarding guided tour for new users",
        default: true
      },
      password_active_rules: {
        default: %w[lowercase uppercase numeric special],
        default_by_env: {
          test: []
        },
        allowed: %w[lowercase uppercase numeric special]
      },
      password_count_former_banned: {
        default: 0
      },
      password_days_valid: {
        default: 0
      },
      password_min_length: {
        default: 10,
        format: :integer,
        allowed: -> { 1..Setting::PASSWORD_MAX_LENGTH }
      },
      # TODO: turn into array of ints
      # Requires a migration to be written
      # replace Setting#per_page_options_array
      per_page_options: {
        default: "20, 100"
      },
      percent_complete_on_status_closed: {
        description: "Describes how % complete should change when setting a work package status to a closed one",
        default: "no_change",
        allowed: %w[no_change set_100p]
      },
      plain_text_mail: {
        default: false
      },
      project_gantt_query: {
        default: nil,
        format: :string
      },
      rails_asset_host: {
        description: "Custom asset hostname for serving assets (e.g., Cloudfront)",
        format: :string,
        default: nil,
        writable: false
      },
      rails_cache_store: {
        description: "Set cache store implementation to use with OpenProject",
        format: :symbol,
        default: :file_store,
        writable: false,
        allowed: %i[file_store memcache redis]
      },
      rails_relative_url_root: {
        description: "Set a URL prefix / base path to run OpenProject under, e.g., host.tld/openproject",
        default: "",
        writable: false
      },
      show_work_package_attachments: {
        description: "Show work package attachments by default.",
        format: :boolean,
        default: true,
        writable: true
      },
      https: {
        description: "Set assumed connection security for the Rails processes",
        format: :boolean,
        default: -> { Rails.env.production? },
        writable: false
      },
      hsts: {
        description: "Allow disabling of HSTS headers and http -> https redirects",
        format: :boolean,
        default: true,
        writable: false
      },
      home_url: {
        description: "Override default link when clicking on the top menu logo (Homescreen by default).",
        format: :string,
        default: nil
      },
      httpx_connect_timeout: {
        description: "",
        format: :float,
        writable: false,
        allowed: (0..),
        default: 3
      },
      httpx_operation_timeout: {
        description: "",
        format: :float,
        writable: false,
        allowed: (0..),
        default: 10
      },
      httpx_request_timeout: {
        description: "",
        format: :float,
        writable: false,
        allowed: (0..),
        default: 10
      },
      httpx_read_timeout: {
        description: "",
        format: :float,
        writable: false,
        allowed: (0..),
        default: 3
      },
      httpx_write_timeout: {
        description: "",
        format: :float,
        writable: false,
        allowed: (0..),
        default: 3
      },
      httpx_keep_alive_timeout: {
        description: "",
        format: :float,
        writable: false,
        allowed: (0..),
        default: 20
      },
      opentelemetry_enabled: {
        description: "Enable OpenTelemetry metrics",
        default: false
      },
      rate_limiting: {
        default: {},
        description: "Configure rate limiting for various endpoint rules. See configuration documentation for details."
      },
      registration_footer: {
        default: {
          "en" => ""
        }
      },
      remote_storage_upload_host: {
        format: :string,
        default: nil,
        writable: false,
        description: "Host the frontend uses to upload files to, which has to be added to the CSP."
      },
      remote_storage_download_host: {
        format: :string,
        default: nil,
        writable: false,
        description: "Host the frontend uses to download files, which has to be added to the CSP."
      },
      # Content Security Policy
      csp_img_src: {
        format: :array,
        default: %w(* data: blob:),
        writable: false,
        description: "Allowed sources for the CSP img-src directive."
      },
      report_incoming_email_errors: {
        description: "Respond to incoming mails with error details",
        default: true
      },
      repositories_automatic_managed_vendor: {
        default: nil,
        format: :string,
        allowed: -> { OpenProject::SCM::Manager.registered.keys.map(&:to_s) }
      },
      # encodings used to convert repository files content to UTF-8
      # multiple values accepted, comma separated
      repositories_encodings: {
        default: nil,
        format: :string
      },
      repository_checkout_data: {
        default: {
          "git" => { "enabled" => 0 },
          "subversion" => { "enabled" => 0 }
        }
      },
      repository_log_display_limit: {
        default: 100
      },
      repository_storage_cache_minutes: {
        default: 720
      },
      repository_truncate_at: {
        default: 500
      },
      scm: {
        format: :hash,
        default: {},
        writable: false
      },
      scm_git_command: {
        format: :string,
        default: nil,
        writable: false
      },
      scm_local_checkout_path: {
        default: "repositories", # relative to OpenProject directory
        writable: false
      },
      scm_subversion_command: {
        format: :string,
        default: nil,
        writable: false
      },
      # Display update / security badge, enabled by default
      security_badge_displayed: {
        default: true
      },
      security_badge_url: {
        description: "URL of the update check badge",
        default: "https://releases.openproject.com/v1/check.svg",
        writable: false
      },
      seed_admin_user_locked: {
        description: "Lock the created admin user after seeding, so it can not be used for logging in. " \
                     "If set to true, an admin user has to be created manually or through an SSO provider.",
        default: false,
        writable: false
      },
      seed_admin_user_password: {
        description: 'Password to set for the initially created admin user (Login remains "admin").',
        default: "admin",
        writable: false
      },
      seed_admin_user_mail: {
        description: "E-mail to set for the initially created admin user.",
        default: "admin@example.net",
        writable: false
      },
      seed_admin_user_name: {
        description: "Name to set for the initially created admin user.",
        default: "OpenProject Admin",
        writable: false
      },
      seed_admin_user_password_reset: {
        description: "Whether to force a password reset for the initially created admin user.",
        default: true,
        writable: false
      },
      seed_ldap: {
        description: "Provide an LDAP connection and sync settings through ENV",
        writable: false,
        default: nil,
        format: :hash,
        string_values: true
      },
      seed_design: {
        description: "Seed enterprise-edition theme colors and logos through ENV",
        writable: false,
        default: nil,
        format: :hash,
        string_values: true
      },
      seed_enterprise_token: {
        description: "Seed enterprise-edition token through ENV",
        writable: false,
        format: :string,
        default: nil
      },
      self_registration: {
        default: 2,
        format: :integer
      },
      sendmail_arguments: {
        description: "Arguments to call sendmail with in case it is configured as outgoing email setup",
        format: :string,
        writable: false,
        default: "-i"
      },
      sendmail_location: {
        description: "Location of sendmail to call if it is configured as outgoing email setup",
        format: :string,
        writable: false,
        default: "/usr/sbin/sendmail"
      },
      # Allow separate error reporting for frontend errors
      appsignal_frontend_key: {
        format: :string,
        default: nil,
        description: "Appsignal API key for JavaScript error reporting"
      },
      session_cookie_name: {
        description: "Set session cookie name",
        default: "_open_project_session"
      },
      session_ttl_enabled: {
        default: false
      },
      session_ttl: {
        default: 120
      },
      show_community_links: {
        description: "Enable or disable links to OpenProject community instances",
        default: true
      },
      show_product_version: {
        description: "Show product version information in the administration section",
        default: true
      },
      show_pending_migrations_warning: {
        description: "Enable or disable warning bar in case of pending migrations",
        default: true,
        writable: false
      },
      show_setting_mismatch_warning: {
        description: "Show mismatched protocol/hostname warning. In cases where they must differ this can be disabled",
        default: true
      },
      # Render storage information
      show_storage_information: {
        description: "Show available and taken storage information under administration / info",
        default: true
      },
      show_warning_bars: {
        description: "Render warning bars (pending migrations, deprecation, unsupported browsers)",
        # Hide warning bars by default in tests as they might overlay other elements
        default: -> { !Rails.env.test? }
      },
      smtp_authentication: {
        format: :string,
        default: "plain",
        env_alias: "SMTP_AUTHENTICATION"
      },
      smtp_enable_starttls_auto: {
        format: :boolean,
        default: false,
        env_alias: "SMTP_ENABLE_STARTTLS_AUTO"
      },
      smtp_openssl_verify_mode: {
        description: "Globally set verify mode for OpenSSL. Careful: Setting to none will disable any SSL verification!",
        format: :string,
        default: "peer",
        allowed: %w[none peer client_once fail_if_no_peer_cert],
        writable: false
      },
      smtp_ssl: {
        format: :boolean,
        default: false,
        env_alias: "SMTP_SSL"
      },
      smtp_address: {
        format: :string,
        default: "",
        env_alias: "SMTP_ADDRESS"
      },
      smtp_domain: {
        format: :string,
        default: "your.domain.com",
        env_alias: "SMTP_DOMAIN"
      },
      smtp_user_name: {
        format: :string,
        default: "",
        env_alias: "SMTP_USER_NAME"
      },
      smtp_port: {
        format: :integer,
        default: 587,
        env_alias: "SMTP_PORT"
      },
      smtp_password: {
        format: :string,
        default: "",
        env_alias: "SMTP_PASSWORD"
      },
      smtp_timeout: {
        format: :integer,
        default: 5
      },
      software_name: {
        description: "Override software application name",
        default: "OpenProject"
      },
      software_url: {
        description: "Override software application URL",
        default: "https://www.openproject.org/"
      },
      sql_slow_query_threshold: {
        description: "Time limit in ms after which queries will be logged as slow queries",
        default: 2000,
        writable: false
      },
      ssrf_protection_ip_allowlist: {
        description: "
          Connections to certain IP addresses (such as private ranges) are blocked to prevent SSRF attacks.
          Use this setting to explicitly allow given IP addresses which would otherwise be blocked.
          Takes a comma or space separated list of IPv4 and IPv6 addresses (including masks for ranges),
          e.g. `192.168.255.255/16`.

          Here is a list of blocked IP ranges as defined by the ssrf_filter gem used.
          See [1] for the latest state in case this has changed.

            0.0.0.0/8          # Current network (only valid as source address)
            10.0.0.0/8         # Private network
            100.64.0.0/10      # Shared Address Space
            127.0.0.0/8        # Loopback
            169.254.0.0/16     # Link-local
            172.16.0.0/12      # Private network
            192.0.0.0/24       # IETF Protocol Assignments
            192.0.2.0/24       # TEST-NET-1, documentation and examples
            192.88.99.0/24     # IPv6 to IPv4 relay (includes 2002::/16)
            192.168.0.0/16     # Private network
            198.18.0.0/15      # Network benchmark tests
            198.51.100.0/24    # TEST-NET-2, documentation and examples
            203.0.113.0/24     # TEST-NET-3, documentation and examples
            224.0.0.0/4        # IP multicast (former Class D network)
            240.0.0.0/4        # Reserved (former Class E network)
            255.255.255.255    # Broadcast

            ::1/128            # Loopback
            64:ff9b::/96       # IPv4/IPv6 translation (RFC 6052)
            100::/64           # Discard prefix (RFC 6666)
            2001::/32          # Teredo tunneling
            2001:10::/28       # Deprecated (previously ORCHID)
            2001:20::/28       # ORCHIDv2
            2001:db8::/32      # Addresses used in documentation and example source code
            2002::/16          # 6to4
            fc00::/7           # Unique local address
            fe80::/10          # Link-local address
            ff00::/8           # Multicast

          [1] https://github.com/arkadiyt/ssrf_filter/blob/main/lib/ssrf_filter/ssrf_filter.rb#L28-L58
        ".squish,
        format: :string,
        default: "",
        env_alias: "SSRF_PROTECTION_IP_ALLOWLIST",
        writable: false
      },
      start_of_week: {
        default: nil,
        format: :integer,
        allowed: [1, 6, 7]
      },
      statsd: {
        description: "enable statsd metrics (currently puma only) by configuring host",
        default: {
          "host" => nil,
          "port" => 8125
        },
        writable: false
      },
      metrics: {
        description: "
          Publish a reduced set of puma metrics on a separate port for Prometheus consumption,
          providing autoscaling hints
        ".squish,
        default: {
          "enabled" => false,
          "port" => 9394
        },
        writable: false
      },
      sys_api_enabled: {
        description: "Enable internal system API for setting up managed repositories",
        default: false
      },
      sys_api_key: {
        description: "Internal system API key for setting up managed repositories",
        default: nil,
        format: :string
      },
      time_format: {
        format: :string,
        default: nil,
        allowed: [
          "%H:%M",
          "%I:%M %p"
        ].freeze
      },
      user_default_timezone: {
        default: nil,
        format: :string,
        allowed: ActiveSupport::TimeZone.all.map { |tz| tz.tzinfo.canonical_identifier }.sort.uniq + [nil]
      },
      users_deletable_by_admins: {
        default: false
      },
      user_default_theme: {
        default: "light",
        format: :string,
        allowed: -> do
          UserPreferences::Schema.schema.dig("definitions", "UserPreferences", "properties", "theme", "enum")
        end
      },
      users_deletable_by_self: {
        default: false
      },
      user_format: {
        default: :firstname_lastname,
        allowed: -> { User::USER_FORMATS_STRUCTURE.keys }
      },
      web: {
        description: "Web worker count and threads configuration",
        default: {
          "workers" => 2,
          "timeout" => Rails.env.production? ? 120 : 0,
          "wait_timeout" => 30,
          "min_threads" => 4,
          "max_threads" => 16,
          "term_on_timeout" => 1
        },
        writable: false
      },
      welcome_text: {
        format: :string,
        default: nil
      },
      welcome_title: {
        format: :string,
        default: nil
      },
      welcome_on_homescreen: {
        default: false
      },
      work_package_done_ratio: {
        default: "field",
        allowed: %w[field status]
      },
      work_packages_projects_export_limit: {
        default: 500
      },
      work_packages_bulk_request_limit: {
        default: 10
      },
      work_packages_identifier: {
        description: "Defines how work packages are identified in the UI (e.g. in links and titles). " \
                     "The 'classic' option uses the work package numerical ID, " \
                     "while 'semantic' uses the project identifier and the work package ID separated by a dash " \
                     "(e.g. 'PROJA-123').",
        format: :string,
        allowed: -> { Setting::WorkPackageIdentifier::ALLOWED_VALUES },
        default: "classic"
      },
      work_package_list_default_highlighted_attributes: {
        default: ["status", "priority", "due_date"],
        allowed: -> {
          Query.available_columns(nil).select(&:highlightable).map(&:name).map(&:to_s)
        }
      },
      work_package_list_default_highlighting_mode: {
        format: :string,
        default: -> { "inline" },
        allowed: -> { Query::QUERY_HIGHLIGHTING_MODES.map(&:to_s) }
      },
      work_package_list_default_columns: {
        default: %w[id subject type status assigned_to priority],
        allowed: -> { Query.new.displayable_columns.map { |c| c.name.to_s } }
      },
      work_package_startdate_is_adddate: {
        default: false
      },
      working_days: {
        description: "Set working days of the week (Array of 1 to 7, where 1=Monday, 7=Sunday)",
        format: :array,
        allowed: Array(1..7),
        default: Array(1..5) # Sat, Sun being non-working days,
      },
      youtube_channel: {
        description: "Link to YouTube channel in help menu",
        default: "https://www.youtube.com/c/OpenProjectCommunity"
      },
      capture_external_links: {
        description: "Redirect external links through a warning page before leaving the application",
        default: false,
        writable: -> { EnterpriseToken.allows_to?(:capture_external_links) }
      },
      capture_external_links_require_login: {
        description: "Require users to be logged in before being able to navigate to external links",
        default: false,
        writable: -> { EnterpriseToken.allows_to?(:capture_external_links) }
      }
    }.freeze

    attr_accessor :name,
                  :format,
                  :env_alias,
                  :string_values,
                  :persist_on_first_read

    attr_writer :value,
                :description,
                :allowed

    def initialize(name, # rubocop:disable Metrics/AbcSize
                   default:,
                   default_by_env: {},
                   description: nil,
                   format: nil,
                   writable: true,
                   allowed: nil,
                   env_alias: nil,
                   string_values: false,
                   persist_on_first_read: false)
      self.name = name.to_s
      self.value = derive_default default_by_env.fetch(Rails.env.to_sym, default)
      self.format = format ? format.to_sym : deduce_format(value)
      self.writable = writable
      self.allowed = allowed
      self.env_alias = env_alias
      self.description = description.presence || :"setting_#{name}"
      self.string_values = string_values
      self.persist_on_first_read = persist_on_first_read

      if persist_on_first_read && !writable
        raise ArgumentError, "Settings using persist_on_first_read need to be writable"
      end

      if persist_on_first_read && default.nil?
        raise ArgumentError, "Settings using persist_on_first_read need to have a default value"
      end
    end

    def env_name
      self.class.env_name(self)
    end

    def possible_env_names
      self.class.possible_env_names(self)
    end

    def derive_default(default)
      @default = default.is_a?(Hash) ? default.deep_stringify_keys : default
      @default.freeze
      @default.dup
    end

    def default
      cast(@default)
    end

    def value
      unless (override = resolve_value_override).nil?
        return cast(override)
      end

      cast(@value)
    end

    def description
      if @description.is_a?(Symbol)
        I18n.t(@description, default: nil)
      else
        @description
      end
    end

    def serialized?
      %i[array hash].include?(format)
    end

    def writable?
      return false if value_override?

      if writable.respond_to?(:call)
        writable.call
      else
        !!writable
      end
    end

    def persist_on_first_read?
      persist_on_first_read
    end

    def unprefixed_env_var_name_allowed?
      # Configuration values could be overridden with unprefixed env var
      # names before being harmonized (PR#10296). Using unprefixed en var
      # is deprecated and will be removed in 13.0.
      # Configuration are recognized by not being writable.
      !writable
    end

    def override_value(other_value)
      self.value = coerce(other_value)
      if valid_for?(value)
        self.writable = false
      else
        raise ArgumentError, "Value for #{name} must be one of #{allowed.join(', ')} but is #{value}"
      end
    end

    def valid_for?(value)
      return true if allowed.nil?

      # TODO: it would make sense to also check the type of the value (e.g. boolean).
      # But as using e.g. 0 for a boolean is quite common, that would break.
      if format == :array
        (value - allowed).empty?
      else
        allowed.include?(value)
      end
    end

    def allowed
      if @allowed.respond_to?(:call)
        @allowed.call
      else
        @allowed
      end
    end

    class << self
      # Adds a setting definition to the set of configured definitions. A definition will define a name and a default value.
      # However, that value can be overwritten by (lower tops higher):
      # * a value stored in the database (`settings` table)
      # * a value in the config/configuration.yml file
      # * a value provided by an ENV var
      #
      # @param [Object] name The name of the definition
      # @param [Object] default The default value the setting has if not overridden.
      # @param [nil] format The format the value is in e.g. symbol, array, hash, string. If a value is present,
      #  the format is deferred.
      # @param [nil] description A human-readable description of this setting.
      # @param [TrueClass] writable Whether the value can be set in the UI. In case the value is set via file or ENV var,
      #  this will be set to false later on and UI elements that refer to the definition will be disabled.
      # @param [nil] allowed The array of allowed values that can be assigned to the definition.
      #  Will serve to be validated against. A lambda can be provided returning an array in case
      #  the array needs to be evaluated dynamically. In case of e.g. boolean format, setting
      #  an allowed array is not necessary.
      # @param [nil] env_alias Alternative for the default env name to also look up. E.g. with the alias set to
      #  `OPENPROJECT_2FA` for a definition with the name `two_factor_authentication`, the value is fetched
      #  from the ENV OPENPROJECT_2FA as well.
      # @param [TrueClass|FalseClass] disallow_override Disables the usual possibility of overriding the value
      #   from ENV or configuration file.
      def add(name,
              default:,
              default_by_env: {},
              format: nil,
              description: nil,
              writable: true,
              allowed: nil,
              env_alias: nil,
              string_values: false,
              persist_on_first_read: false,
              disallow_override: false)
        name = name.to_sym
        return if exists?(name)

        definition = new(name,
                         format:,
                         description:,
                         default:,
                         default_by_env:,
                         writable:,
                         allowed:,
                         env_alias:,
                         string_values:,
                         persist_on_first_read:)
        override_value(definition) unless disallow_override
        all[name] = definition
      end

      def add_all
        Settings::Definition::DEFINITIONS.each do |setting_name, setting_options|
          Settings::Definition.add(setting_name, **setting_options)
        end
      end

      def [](name)
        name = name.to_sym
        if exists?(name)
          all[name]
        else
          h = DEFINITIONS[name]
          add(name, **h) if h.present?
        end
      end

      def exists?(name)
        all.key?(name.to_sym)
      end

      def all
        @all ||= {}
      end

      # Registers a value override block for a setting. The block is called
      # whenever the setting's value or writability is evaluated.
      #
      # If the block returns a non-nil value, that value is used as the setting's
      # value and the setting becomes non-writable. If the block returns nil,
      # no override is applied.
      #
      # To override a setting with nil, return a callable: +-> { nil }+
      #
      # @param name [Symbol] The setting name to override.
      # @yield A block that returns the override value, or nil to skip.
      #
      # @example Force a setting to true when a condition is met
      #   Settings::Definition.add_value_override(:capture_external_links) do
      #     true if MyPlugin.active?
      #   end
      def add_value_override(name, &block)
        (value_overrides[name.to_sym] ||= []) << block
      end

      def value_overrides
        @value_overrides ||= {}
      end

      def clear_value_overrides(name = nil)
        if name
          value_overrides.delete(name.to_sym)
        else
          @value_overrides = {}
        end
      end

      private

      def file_config
        @file_config ||= begin
          filename = Rails.root.join("config/configuration.yml")

          file_config = {}

          if File.file?(filename)
            file_config = load_yaml(ERB.new(File.read(filename)).result)

            if file_config.is_a? Hash
              file_config
            else
              warn "#{filename} is not a valid OpenProject configuration file, ignoring."
            end
          end

          file_config
        end
      end

      # Replace values for which an entry in the config file or as an environment variable exists.
      def override_value(definition)
        override_value_from_file(definition)
        override_value_from_env(definition)
      end

      def override_value_from_file(definition)
        envs = ["default", Rails.env]
        envs.delete("default") if Rails.env.test? # The test setup should govern the configuration
        envs.each do |env|
          next unless (env_config = file_config[env])
          next unless env_config.has_key?(definition.name)

          definition.override_value(env_config[definition.name])
        end
      end

      # Replace values for which an environment variable with the same key in upper case exists.
      # Also merges the existing values that are hashes with values from ENV if they follow the naming
      # schema.
      def override_value_from_env(definition)
        override_config_values(definition)
        merge_hash_config(definition) if definition.format == :hash
      end

      def override_config_values(definition)
        find_env_var_override(definition) do |env_var_name, env_var_value|
          value = extract_value_from_env(env_var_name, env_var_value)
          definition.override_value(value)
        end
      end

      def merge_hash_config(definition)
        merged_hash = {}
        each_env_var_hash_override(definition) do |env_var_name, env_var_value, env_var_hash_part|
          value =
            if definition.string_values
              path_to_hash(*hash_path(env_var_hash_part), env_var_value)
            else
              extract_hash_from_env(env_var_name, env_var_value, env_var_hash_part)
            end

          merged_hash.deep_merge!(value)
        end
        return if merged_hash.empty?

        definition.override_value(merged_hash)
      end

      def extract_hash_from_env(env_var_name, env_var_value, env_var_hash_part)
        value = extract_value_from_env(env_var_name, env_var_value)
        path_to_hash(*hash_path(env_var_hash_part), value)
      end

      # takes the hash part of an env variable and turn it into a path.
      #
      # e.g. hash_path('KEY_SUB__KEY_SUB__SUB__KEY') => ['key', 'sub_key', 'sub_sub_key']
      def hash_path(env_var_hash_part)
        env_var_hash_part
          .scan(/(?:[a-zA-Z0-9]|__)+/)
          .map do |seg|
            unescape_underscores(seg.downcase)
          end
      end

      # takes the path provided and transforms it into a deeply nested hash
      # where the last parameter becomes the value.
      #
      # e.g. path_to_hash(:a, :b, :c, :d) => { a: { b: { c: :d } } }
      def path_to_hash(*path)
        value = path.pop

        path.reverse.inject(value) do |path_hash, key|
          { key => path_hash }
        end
      end

      def unescape_underscores(path_segment)
        path_segment.gsub "__", "_"
      end

      def find_env_var_override(definition)
        found_env_name = possible_env_names(definition).find { |name| ENV.key?(name) }
        return unless found_env_name

        if found_env_name == env_name_unprefixed(definition)
          Rails.logger.warn(
            "Using unprefixed environment variables is deprecated. " \
            "Please use #{env_name(definition)} instead of #{env_name_unprefixed(definition)}"
          )
        end
        yield found_env_name, ENV.fetch(found_env_name)
      end

      def each_env_var_hash_override(definition)
        hash_override_matcher =
          if definition.env_alias
            /^(?:#{env_name(definition)}|#{env_name_nested(definition)}|#{env_name_alias(definition)})_(.+)/i
          else
            /^(?:#{env_name(definition)}|#{env_name_nested(definition)})_(.+)/i
          end
        ENV.each do |env_var_name, env_var_value|
          env_var_name.match(hash_override_matcher) do |m|
            yield env_var_name, env_var_value, m[1]
          end
        end
      end

      def possible_env_names(definition)
        [
          env_name_nested(definition),
          env_name(definition),
          env_name_unprefixed(definition),
          env_name_alias(definition)
        ].compact
      end

      def env_name_nested(definition)
        "#{ENV_PREFIX}#{definition.name.upcase.gsub('_', '__')}"
      end

      def env_name(definition)
        "#{ENV_PREFIX}#{definition.name.upcase}"
      end

      def env_name_unprefixed(definition)
        definition.name.upcase if definition.unprefixed_env_var_name_allowed?
      end

      def env_name_alias(definition)
        return unless definition.env_alias

        definition.env_alias.upcase
      end

      public :possible_env_names, :env_name

      ##
      # Extract the configuration value from the given environment variable
      # using YAML.
      #
      # @param env_var_name [String] The environment variable name.
      # @param env_var_value [String] The string from which to extract the actual value.
      # @return A ruby object (e.g. Integer, Float, String, Hash, Boolean, etc.)
      # @raise [ArgumentError] If the string could not be parsed.
      def extract_value_from_env(env_var_name, env_var_value)
        # YAML parses '' as false, but empty ENV variables will be passed as that.
        # To specify specific values, one can use !!str (-> '') or !!null (-> nil)
        return env_var_value if env_var_value == ""

        parsed = load_yaml(env_var_value)

        if parsed.is_a?(String)
          env_var_value
        else
          parsed
        end
      rescue StandardError => e
        raise ArgumentError, "Configuration value for environment variable '#{env_var_name}' is invalid: #{e.message}"
      end

      def load_yaml(source)
        YAML::safe_load(source, permitted_classes: [Symbol, Date])
      end
    end

    private

    attr_accessor :serialized,
                  :writable

    def value_override?
      !resolve_value_override.nil?
    end

    def resolve_value_override
      self.class.value_overrides[name.to_sym]&.each do |block|
        result = block.call
        return result unless result.nil?
      end
      nil
    end

    def cast(value)
      return nil if value.nil?

      value = value.call if value.respond_to?(:call)

      case format
      when :integer
        value.to_i
      when :float
        value.to_f
      when :boolean
        AR_BOOLEAN_TYPE.cast(value)
      when :symbol
        value.to_sym
      else
        value
      end
    end

    def deduce_format(value)
      case value
      when TrueClass, FalseClass
        :boolean
      when Integer, Date, DateTime, String, Hash, Array, Float, Symbol
        value.class.name.underscore.to_sym
      when ActiveSupport::Duration
        :duration
      else
        raise ArgumentError, "Cannot deduce the format for the setting definition #{name}"
      end
    end

    def coerce(value)
      case format
      when :hash
        (self.value || {}).deep_merge value.deep_stringify_keys
      when :array
        value.is_a?(String) ? value.split : Array(value)
      when :datetime
        value.is_a?(DateTime) ? value : DateTime.parse(value.to_s)
      else
        value
      end
    end
  end
end
# rubocop:enable Metrics/CollectionLiteralLength
