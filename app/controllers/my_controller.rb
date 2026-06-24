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

class MyController < ApplicationController
  include PasswordConfirmation
  include Accounts::UserPasswordChange
  include ActionView::Helpers::TagHelper
  include OpTurbo::ComponentStream
  include FlashMessagesOutputSafetyHelper
  include Notifications::NotificationSettingsActions

  layout "my"

  before_action :require_login
  before_action :set_current_user
  before_action :check_password_confirmation, only: %i[update_account]

  no_authorization_required! :account,
                             :update_account,
                             :locale,
                             :interface,
                             :update_settings,
                             :update_workdays,
                             :update_email_alerts,
                             :update_participating,
                             :update_non_participating,
                             :update_date_alerts,
                             :password,
                             :change_password,
                             :password_confirmation_dialog,
                             :security,
                             :notifications,
                             :non_working_times,
                             :working_hours,
                             :new_project_settings,
                             :create_project_settings,
                             :edit_project_settings,
                             :update_project_settings,
                             :destroy_project_settings

  menu_item :account, only: [:account]
  menu_item :locale, only: [:locale]
  menu_item :interface, only: [:interface]
  menu_item :password, only: [:password]
  menu_item :security, only: [:security]
  menu_item :notifications, only: [:notifications]
  menu_item :working_hours, only: %i[working_hours non_working_times]

  def account; end

  def update_account
    write_settings
  end

  def locale; end

  def update_settings
    write_settings
  end

  def update_email_alerts
    update_global_notification_setting(permitted_params.notification_setting_email_alerts)
  end

  def update_participating
    update_global_notification_setting(permitted_params.notification_setting_participating)
  end

  def update_non_participating
    update_global_notification_setting(permitted_params.notification_setting_non_participating)
  end

  def update_date_alerts
    update_global_notification_setting(build_date_alerts_params)
  end

  def interface; end

  def security
    @username = @user.login
  end

  # Manage user's password
  def password
    @username = @user.login
    redirect_if_password_change_not_allowed_for(@user)
  end

  # When making changes here, also check AccountController.change_password
  def change_password
    change_password_flow(user: @user, params:, update_legacy: false) do
      redirect_to action: "security"
    end
  end

  def password_confirmation_dialog
    respond_with_dialog My::PasswordConfirmationDialog.new
  end

  # Configure user's notifications and email reminders
  def notifications
    set_global_notification_setting
  end

  def working_hours
    @current_working_hours = @user.working_hours.current

    @future_working_hours = @user.working_hours.upcoming(Date.current + 1)

    @past_working_hours = if @current_working_hours
                            @user.working_hours.history_for(@current_working_hours)
                          else
                            UserWorkingHours.none
                          end
  end

  def non_working_times
    @year = (params[:year].presence || Date.current.year).to_i
    @non_working_times = @user.non_working_time_entities_for_year(@year)
  end

  private

  def render_password_change(_user, message, show_user_name: false) # rubocop:disable Lint/UnusedMethodArgument
    flash[:error] = message unless message.nil?
    redirect_to action: "security"
  end

  def redirect_if_password_change_not_allowed_for(user)
    unless user.change_password_allowed?
      flash[:error] = I18n.t(:notice_can_t_change_password)
      redirect_to action: "account"
      return true
    end
    false
  end

  def write_settings
    result = Users::UpdateService
               .new(user: current_user, model: current_user)
               .call(user_params)

    if result&.success
      flash[:notice] = notice_account_updated
      handle_email_changes
    else
      flash[:error] = error_account_update_failed(result)
    end

    redirect_back_or_to(my_account_path)
  end

  def handle_email_changes
    # If mail changed, expire all other sessions
    if @user.previous_changes["mail"]
      Users::DropTokensService.new(current_user: @user).call!
      Sessions::DropOtherSessionsService.call!(@user, session)

      flash[:info] = "#{flash[:notice]} #{t(:notice_account_other_session_expired)}"
      flash.delete :notice
    end
  end

  def user_params
    # The Users::UpdateService updates the user's pref using the UserPreferences::UpdateService
    # which has a contract/schema applied to the values which is why it is ok
    # to blindly allow all scalar values in pref.
    attributes = permitted_params.user.to_h.merge(params.permit(pref: {}))
    drop_non_editable_custom_field_values(attributes)
  end

  # On the self-service account page only custom fields the user is allowed to
  # edit themselves (editable: true) may be changed. Drop the rest so a crafted
  # request cannot persist values the UI renders read-only.
  def drop_non_editable_custom_field_values(attributes)
    values = attributes["custom_field_values"]
    return attributes if values.blank?

    editable_ids = current_user.available_custom_fields.select(&:editable?).map { |cf| cf.id.to_s }
    attributes["custom_field_values"] = values.slice(*editable_ids)
    attributes
  end

  def update_global_notification_setting(update_params)
    set_global_notification_setting
    persist_notification_setting(@global_notification_setting, update_params)
    redirect_back_or_to(my_notifications_path)
  end

  def set_global_notification_setting
    @global_notification_setting = @user.notification_settings.find_or_initialize_by(project: nil)
  end

  def persist_notification_setting(setting, update_params)
    if setting.update(update_params)
      flash[:notice] = notice_account_updated
    else
      flash[:error] = error_account_update_failed(nil)
    end
  end

  def notice_account_updated
    OpenProject::LocaleHelper.with_locale_for(current_user) do
      t(:notice_account_updated)
    end
  end

  def error_account_update_failed(result)
    errors = result ? result.errors.full_messages.join("\n") : ""
    [t(:notice_account_update_failed), errors]
  end

  def notifications_settings_path
    my_notifications_path
  end

  def workdays_redirect_path
    my_notifications_path
  end

  def project_notifications_create_url
    my_project_notifications_path
  end

  def project_setting_form_url(project_id)
    my_project_setting_path(project_id:)
  end

  def set_current_user
    @user = current_user
  end

  def get_current_layout
    @user.pref[:my_page_layout] || DEFAULT_LAYOUT.dup
  end
end
