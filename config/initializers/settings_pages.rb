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
  page :general, menu_item: :settings_general do
    setting :app_title
    setting :organization_name
    setting :per_page_options,
            caption: -> { safe_join([t(:text_comma_separated), t(:text_notice_too_many_values_are_inperformant)], tag.br) }
    setting :activity_days_default
    setting :host_name,
            caption: -> { "#{t(:label_example)}: #{request.host_with_port}" }
    setting :cache_formatted_text
    setting :allowed_link_protocols,
            caption: -> {
              t(:setting_allowed_link_protocols_text_html,
                tel_code: tag.code("tel"),
                element_code: tag.code("element"),
                http_code: tag.code("http"),
                https_code: tag.code("https"),
                mailto_code: tag.code("mailto"))
            }
    setting :feeds_enabled
    setting :feeds_limit
    setting :file_max_size_displayed
    setting :diff_max_lines_displayed
    setting :security_badge_displayed,
            caption: -> {
              t(:text_notice_security_badge_displayed_html,
                information_panel_label: t(:label_information),
                more_info_url: OpenProject::Static::Links.url_for(:security_badge_documentation),
                information_panel_path: info_admin_index_path)
            },
            if: -> { OpenProject::Configuration.security_badge_displayed? }
    setting :welcome_title
    setting :welcome_text
    setting :welcome_on_homescreen
  end

  page :external_links, menu_item: :settings_external_links do
    setting :capture_external_links,
            caption: :setting_capture_external_links_text
    setting :capture_external_links_require_login,
            caption: :setting_capture_external_links_require_login_text
  end

  page :languages, menu_item: :settings_languages do
    setting :available_languages
  end

  page :exports, menu_item: :settings_exports do
    setting :work_packages_projects_export_limit,
            caption: :setting_work_packages_projects_export_limit_text
    setting :csv_escape_formulas,
            caption: :setting_csv_escape_formulas_text
  end

  page :repositories, menu_item: :settings_repositories do
    setting :autofetch_changesets,
            caption: :"repositories.autofetch_information"
    setting :repository_storage_cache_minutes,
            caption: :"repositories.storage.update_timeout"
    setting :sys_api_enabled,
            caption: :setting_sys_api_description
    setting :sys_api_key
    setting :enabled_scm
    setting :repositories_automatic_managed_vendor,
            caption: :"repositories.settings.automatic_managed_repos_text"
    setting :repositories_encodings,
            caption: :text_comma_separated
    setting :repository_log_display_limit
    setting :repository_truncate_at
    setting :repository_checkout_data, label: :setting_repository_checkout_display
    setting :commit_ref_keywords,
            caption: :text_comma_separated
    setting :commit_fix_keywords,
            label: -> { t(%i[setting_commit_fix_keywords label_keyword_plural]).join(": ") },
            caption: :text_comma_separated
    setting :commit_fix_status_id, label: -> { I18n.t(%i[setting_commit_fix_keywords label_applied_status]).join(": ") }
    setting :commit_logtime_enabled
    setting :commit_logtime_activity_id
  end

  page :users, menu_item: :user_settings do
    setting :default_language
    setting :user_default_timezone,
            caption: :tooltip_user_default_timezone
    setting :default_auto_hide_popups, label: :"activerecord.attributes.user_preference.auto_hide_popups"
    setting :user_format
    setting :user_can_change_email
    setting :users_deletable_by_admins
    setting :users_deletable_by_self
    setting :consent_required
    setting :consent_info
    setting :consent_decline_mail,
            caption: :"consent.contact_mail_instructions"
  end

  page :work_packages_general, menu_item: :work_packages_general do
    setting :cross_project_work_package_relations
    setting :display_subprojects_work_packages
    setting :work_package_startdate_is_adddate
    setting :work_package_list_default_highlighting_mode
    setting :work_package_list_default_highlighted_attributes
  end

  page :work_packages_identifier, menu_item: :work_packages_identifier do
    setting :work_packages_identifier, label: :"settings.work_packages.work_package_identifier"
  end

  page :versions_and_categories, menu_item: :versions_and_categories do
    setting :work_package_multiple_versions, form_field: false, if: -> { !Setting.work_package_multiple_versions? }
  end

  page :progress_tracking, menu_item: :progress_tracking do
    setting :work_package_done_ratio
    setting :total_percent_complete_mode
    setting :percent_complete_on_status_closed
  end

  page :new_project, menu_item: :new_project_settings, tab: "settings", label: :label_setting_plural do
    setting :default_projects_public
    setting :default_projects_wiki
    setting :default_projects_modules
    setting :new_project_user_role_id
  end

  page :new_project_notifications,
       menu_item: :new_project_settings,
       tab: "notifications",
       label: :label_notification_center_plural do
    setting :new_project_send_confirmation_email
    setting :new_project_notification_text
  end

  page :working_days_and_hours, menu_item: :working_days_and_hours do
    setting :hours_per_day
    setting :duration_format
    setting :working_days
  end

  page :date_format, menu_item: :date_format do
    setting :date_format
    setting :time_format
    setting :start_of_week
    setting :first_week_of_year,
            caption: -> {
              t("settings.date_format.first_week_of_year_text_html",
                link: OpenProject::Static::Links.url_for(:date_format_settings_documentation))
            }
  end

  page :icalendar, menu_item: :icalendar do
    setting :ical_enabled
  end

  page :aggregation, menu_item: :notification_settings do
    setting :journal_aggregation_time_minutes,
            caption: -> {
              link_translate("admin.journal_aggregation.caption_with_maximum",
                             i18n_args: { max: Settings::Definition[:journal_aggregation_time_minutes].allowed.max },
                             links: { webhook_link: admin_outgoing_webhooks_path })
            }
  end

  page :mail_notifications, menu_item: :mail_notifications do
    section :mails, if: -> { ActionMailer::Base.perform_deliveries } do
      setting :mail_from
      setting :bcc_recipients
      setting :plain_text_mail
      setting :emails_salutation
      setting :emails_header
      setting :emails_footer
    end

    section :delivery,
            if: -> { OpenProject::Configuration["email_delivery_configuration"] != "legacy" } do
      setting :email_delivery_method
      setting :smtp_address
      setting :smtp_port
      setting :smtp_domain
      setting :smtp_authentication
      setting :smtp_user_name
      setting :smtp_password
      setting :smtp_enable_starttls_auto
      setting :smtp_ssl
      setting :sendmail_location
      setting :sendmail_arguments
    end
  end

  page :incoming_mails, menu_item: :incoming_mails do
    setting :mail_handler_body_delimiters,
            caption: :text_line_separated
    setting :mail_handler_body_delimiter_regex,
            caption: :text_regexp_multiline
    setting :mail_handler_ignore_filenames,
            caption: :"incoming_mails.ignore_filenames"
  end

  page :api, menu_item: :api do
    setting :api_tokens_enabled,
            caption: :setting_api_tokens_enabled_caption
    setting :apiv3_max_page_size,
            caption: :setting_apiv3_max_page_size_instructions
    setting :apiv3_write_readonly_attributes,
            caption: :setting_apiv3_write_readonly_attributes_instructions
    setting :apiv3_docs_enabled,
            caption: :setting_apiv3_docs_enabled_instructions_warning
    setting :apiv3_cors_enabled
    setting :apiv3_cors_origins,
            caption: :text_line_separated
  end

  page :authentication,
       menu_item: :authentication_settings,
       tab: "login",
       label: :"settings.authentication.login" do
    setting :autologin
    setting :session_ttl_enabled
    setting :session_ttl,
            caption: :setting_session_ttl_hint
    setting :log_requesting_user
    setting :after_first_login_redirect_url,
            caption: :setting_after_first_login_redirect_url_text_html
    setting :after_login_default_redirect_url,
            caption: -> {
              t(:setting_after_login_default_redirect_url_example_html, example_code: content_tag(:code, "/my/page"))
            }
  end

  page :authentication_sso,
       menu_item: :authentication_settings,
       tab: "sso",
       label: :"settings.authentication.sso" do
    setting :omniauth_direct_login_provider
    setting :oauth_allow_remapping_of_existing_users
    setting :password_login
    setting :password_login_bypass_principal_ids
  end

  page :authentication_registration,
       menu_item: :authentication_settings,
       tab: "registration",
       label: :"settings.authentication.registration" do
    setting :login_required
    setting :self_registration,
            caption: :setting_self_registration_caption
    setting :invitation_expiration_days
    setting :registration_footer
  end

  page :authentication_passwords,
       menu_item: :authentication_settings,
       tab: "passwords",
       label: :"settings.passwords" do
    setting :password_min_length
    setting :password_active_rules
    setting :password_days_valid,
            caption: -> { t("text_hint_disable_with_0") }
    setting :password_count_former_banned
    setting :lost_password
    setting :brute_force_block_after_failed_logins,
            caption: -> { t("text_hint_disable_with_0") }
    setting :brute_force_block_minutes,
            caption: -> { t("text_hint_disable_with_0") }
  end

  page :llm_connection, menu_item: :llm_connection do
    setting :llm_features_enabled,
            form_field: false,
            label: -> { LlmConnection.human_attribute_name(:llm_features_enabled) },
            caption: :"admin.llm_connections.form.llm_features_enabled_caption"
  end

  page :text_transform_actions, menu_item: :text_transform_actions do
    setting :ai_text_transform_actions_enabled, form_field: false
  end

  page :attachments, menu_item: :attachments, label: :"settings.general" do
    setting :show_work_package_attachments,
            caption: :"settings.attachments.show_work_package_attachments"
    setting :attachment_max_size
    setting :attachment_whitelist,
            caption: -> { t("settings.attachments.whitelist_text_html", ext_example: "*.jpg", mime_example: "image/jpeg") }
  end

  page :virus_scanning,
       menu_item: :attachments,
       label: :"settings.antivirus.title",
       if: -> { Setting.antivirus_scan_available? },
       url: { controller: "/admin/settings/virus_scanning_settings", action: :show } do
    setting :antivirus_scan_mode
    setting :antivirus_scan_target, if: -> { Setting.antivirus_scan_mode != :disabled }
    setting :antivirus_scan_action, if: -> { Setting.antivirus_scan_mode != :disabled }
  end
end
