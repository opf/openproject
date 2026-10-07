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

Settings::Pages.draw do
  page :general, menu_item: :settings_general, view_hook: :view_settings_general_form do
    setting :app_title, input_width: :medium
    setting :organization_name, input_width: :medium
    setting :per_page_options, input_width: :medium
    setting :activity_days_default, input_width: :xsmall
    setting :host_name, input_width: :medium
    setting :cache_formatted_text
    setting :allowed_link_protocols, input_width: :medium, rows: 5
    setting :feeds_enabled
    setting :feeds_limit, input_width: :xsmall
    setting :file_max_size_displayed, input_width: :xsmall
    setting :diff_max_lines_displayed, input_width: :xsmall
    setting :security_badge_displayed, if: -> { OpenProject::Configuration.security_badge_displayed? }

    section :welcome, heading: :setting_welcome_text do
      setting :welcome_title, input_width: :medium
      setting :welcome_text, cols: 60, rows: 5, id: "settings_welcome_text", rich_text_options: {}
      setting :welcome_on_homescreen
    end
  end

  page :external_links,
       menu_item: :settings_external_links,
       enterprise_feature: :capture_external_links,
       form_hook: :component_admin_settings_external_redirect do
    setting :capture_external_links
    setting :capture_external_links_require_login
  end

  page :languages, menu_item: :settings_languages, update_service: "Settings::LanguageUpdateService" do
    setting :available_languages
  end

  page :exports, menu_item: :settings_exports do
    setting :work_packages_projects_export_limit, input_width: :xsmall
    setting :csv_escape_formulas
  end

  page :repositories, menu_item: :settings_repositories do
    setting :autofetch_changesets
    setting :repository_storage_cache_minutes, input_width: :small
    setting :sys_api_enabled
    setting :sys_api_key, input_width: :medium, depends_on: { setting: :sys_api_enabled }
    setting :enabled_scm
    setting :repositories_automatic_managed_vendor, input_width: :medium
    setting :repositories_encodings, input_width: :medium
    setting :repository_log_display_limit, input_width: :xsmall
    setting :repository_truncate_at, input_width: :xsmall

    section :checkout, heading: :"repositories.checkout.instructions" do
      setting :repository_checkout_data
    end

    section :commit_messages, heading: :text_work_packages_ref_in_commit_messages do
      setting :commit_ref_keywords
      setting :commit_fix_keywords
      setting :commit_fix_status_id
      setting :commit_logtime_enabled
      setting :commit_logtime_activity_id, input_width: :medium, depends_on: { setting: :commit_logtime_enabled }
    end
  end

  page :users, menu_item: :user_settings do
    section :default_preferences, heading: :"settings.user.default_preferences" do
      setting :default_language, input_width: :medium
      setting :user_default_timezone, input_width: :large
      setting :default_auto_hide_popups
    end

    section :display_format, heading: :"settings.user.display_format" do
      setting :user_format, input_width: :medium
    end

    section :account, heading: :"settings.user.account" do
      setting :user_can_change_email
    end

    section :deletion, heading: :"settings.user.deletion" do
      setting :users_deletable_by_admins
      setting :users_deletable_by_self
    end

    section :consent, heading: :label_consent_settings do
      setting :consent_required
      setting :consent_info
      setting :consent_time
      setting :consent_decline_mail, input_width: :medium
    end
  end

  # It is important to have this named something else than "work_packages".
  # Otherwise the angular ui-router will also recognize that as a WorkPackage page and apply according classes.
  page :work_packages_general, menu_item: :work_packages_general do
    setting :cross_project_work_package_relations
    setting :display_subprojects_work_packages
    setting :work_package_startdate_is_adddate
    setting :work_package_list_default_highlighting_mode, input_width: :medium
    setting :work_package_list_default_highlighted_attributes,
            depends_on: { setting: :work_package_list_default_highlighting_mode, value: "inline" }

    section :columns, heading: :setting_column_options do
      setting :work_package_list_default_columns, form_field: false
    end
  end

  page :work_packages_identifier, menu_item: :work_packages_identifier, custom: true do
    setting :work_packages_identifier, label: :"settings.work_packages.work_package_identifier"
  end

  page :versions_and_categories, menu_item: :versions_and_categories, custom: true do
    setting :work_package_multiple_versions, form_field: false, if: -> { !Setting.work_package_multiple_versions? }
  end

  page :progress_tracking, menu_item: :progress_tracking, custom: true do
    setting :work_package_done_ratio
    setting :total_percent_complete_mode
    setting :percent_complete_on_status_closed
  end

  page :new_project, menu_item: :new_project_settings, tab: "settings", label: :label_setting_plural do
    setting :default_projects_public
    setting :default_projects_wiki
    setting :default_projects_modules
    setting :new_project_user_role_id, input_width: :medium
  end

  page :new_project_notifications,
       menu_item: :new_project_settings,
       tab: "notifications",
       label: :label_notification_center_plural do
    setting :new_project_send_confirmation_email
    setting :new_project_notification_text, depends_on: { setting: :new_project_send_confirmation_email }
  end

  page :working_days_and_hours, menu_item: :working_days_and_hours, custom: true do
    setting :hours_per_day
    setting :duration_format
    setting :working_days
  end

  page :date_format, menu_item: :date_format do
    setting :date_format, input_width: :medium
    setting :time_format, input_width: :medium
    setting :start_of_week, input_width: :medium
    setting :first_week_of_year, input_width: :medium
  end

  page :icalendar, menu_item: :icalendar do
    setting :ical_enabled
  end

  page :aggregation, menu_item: :notification_settings do
    setting :journal_aggregation_time_minutes, input_width: :medium
  end

  page :mail_notifications,
       menu_item: :mail_notifications,
       before_form: -> {
         unless ActionMailer::Base.perform_deliveries
           render(Primer::Alpha::Banner.new(mb: 3)) { t(:text_email_delivery_not_configured) }
         end
       },
       after_form: -> {
         if ActionMailer::Base.perform_deliveries
           render(Primer::Beta::Link.new(href: test_email_admin_index_path, data: { turbo_method: :post },
                                         font_weight: :bold, display: :block, mt: 3)) do
             t(:label_send_test_email)
           end
         end
       } do
    section :mails, heading: nil, if: -> { ActionMailer::Base.perform_deliveries } do
      setting :mail_from, input_width: :medium
      setting :bcc_recipients
      setting :plain_text_mail
      setting :emails_salutation, input_width: :medium
      setting :emails_header
      setting :emails_footer
    end

    section :delivery, heading: :text_setup_mail_configuration,
                       if: -> { OpenProject::Configuration["email_delivery_configuration"] != "legacy" } do
      setting :email_delivery_method, input_width: :small
      setting :smtp_address, input_width: :medium, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_port, input_width: :xsmall, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_domain, input_width: :medium, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_authentication, input_width: :small, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_user_name, input_width: :medium, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_password, input_width: :medium, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_enable_starttls_auto, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :smtp_ssl, depends_on: { setting: :email_delivery_method, value: :smtp }
      setting :sendmail_location, depends_on: { setting: :email_delivery_method, value: :sendmail }
      setting :sendmail_arguments, depends_on: { setting: :email_delivery_method, value: :sendmail }
    end
  end

  page :incoming_mails, menu_item: :incoming_mails do
    setting :mail_handler_body_delimiters, rows: 5
    setting :mail_handler_body_delimiter_regex
    setting :mail_handler_ignore_filenames, rows: 5
  end

  page :api, menu_item: :api do
    setting :api_tokens_enabled
    setting :apiv3_max_page_size, input_width: :xsmall, min: 50
    setting :apiv3_write_readonly_attributes

    section :docs, heading: :setting_apiv3_docs do
      setting :apiv3_docs_enabled
    end

    section :cors, heading: :setting_apiv3_cors_title do
      setting :apiv3_cors_enabled
      setting :apiv3_cors_origins, rows: 5, depends_on: { setting: :apiv3_cors_enabled }
    end
  end

  page :authentication,
       menu_item: :authentication_settings,
       custom: true,
       tab: "login",
       label: :"settings.authentication.login" do
    setting :autologin
    setting :session_ttl_enabled
    setting :session_ttl
    setting :log_requesting_user
    setting :after_first_login_redirect_url
    setting :after_login_default_redirect_url
  end

  page :authentication_sso,
       menu_item: :authentication_settings,
       custom: true,
       tab: "sso",
       label: :"settings.authentication.sso",
       enterprise_feature: :sso_auth_providers do
    setting :omniauth_direct_login_provider
    setting :oauth_allow_remapping_of_existing_users
    setting :password_login
    setting :password_login_bypass_principal_ids
  end

  page :authentication_registration,
       menu_item: :authentication_settings,
       custom: true,
       tab: "registration",
       label: :"settings.authentication.registration" do
    setting :login_required
    setting :self_registration
    setting :invitation_expiration_days
    setting :registration_footer
  end

  page :authentication_passwords,
       menu_item: :authentication_settings,
       custom: true,
       tab: "passwords",
       label: :"settings.passwords" do
    setting :password_min_length
    setting :password_active_rules
    setting :password_days_valid
    setting :password_count_former_banned
    setting :lost_password
    setting :brute_force_block_after_failed_logins
    setting :brute_force_block_minutes
  end

  page :llm_connection, menu_item: :llm_connection, custom: true do
    setting :llm_features_enabled,
            form_field: false,
            label: -> { LlmConnection.human_attribute_name(:llm_features_enabled) },
            caption: :"admin.llm_connections.form.llm_features_enabled_caption"
  end

  page :text_transform_actions, menu_item: :text_transform_actions, custom: true do
    setting :ai_text_transform_actions_enabled, form_field: false
  end

  page :attachments, menu_item: :attachments, label: :"settings.general" do
    setting :show_work_package_attachments
    setting :attachment_max_size, input_width: :xsmall
    setting :attachment_whitelist, rows: 5
  end

  page :virus_scanning,
       menu_item: :attachments,
       custom: true,
       label: :"settings.antivirus.title",
       if: -> { Setting.antivirus_scan_available? },
       url: { controller: "/admin/settings/virus_scanning_settings", action: :show } do
    setting :antivirus_scan_mode
    setting :antivirus_scan_target, if: -> { Setting.antivirus_scan_mode != :disabled }
    setting :antivirus_scan_action, if: -> { Setting.antivirus_scan_mode != :disabled }
  end

  page :quarantined_attachments,
       menu_item: :attachments,
       custom: true,
       label: :"antivirus_scan.quarantined_attachments.title",
       url: { controller: "/admin/attachments/quarantined_attachments", action: :index },
       if: -> {
         Setting.antivirus_scan_available? &&
           (EnterpriseToken.allows_to?(:virus_scanning) || Attachment.status_quarantined.any?)
       }
end
