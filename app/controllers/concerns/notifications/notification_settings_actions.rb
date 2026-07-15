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

module Notifications
  module NotificationSettingsActions
    extend ActiveSupport::Concern

    included do
      include OpTurbo::ComponentStream
    end

    def update_workdays
      call = ::Users::UpdateService.new(model: @user, user: current_user).call(pref: workdays_pref_params)
      flash[call.success? ? :notice : :error] = update_service_flash_message(call)
      redirect_back_or_to(workdays_redirect_path)
    end

    def new_project_settings
      respond_with_dialog My::Notifications::ProjectSettingsDialogComponent.new(
        user: @user,
        form_url: project_notifications_create_url
      )
    end

    def create_project_settings
      update_project_notification_setting
      redirect_back_or_to(notifications_settings_path)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t(:notice_bad_request)
      redirect_back_or_to(notifications_settings_path)
    end

    def edit_project_settings
      setting = @user.notification_settings.find_by!(project_id: params[:project_id])
      respond_with_dialog My::Notifications::ProjectSettingsDialogComponent.new(
        user: @user,
        notification_setting: setting,
        form_url: project_setting_form_url(setting.project_id)
      )
    end

    def update_project_settings
      update_project_notification_setting(params[:project_id])
      redirect_back_or_to(notifications_settings_path)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t(:notice_bad_request)
      redirect_back_or_to(notifications_settings_path)
    end

    def destroy_project_settings
      @user.notification_settings.find_by!(project_id: params[:project_id]).destroy!
      flash[:notice] = I18n.t(:notice_successful_delete)
      redirect_back_or_to(notifications_settings_path, status: :see_other)
    rescue ActiveRecord::RecordNotFound
      flash[:error] = t(:notice_bad_request)
      redirect_back_or_to(notifications_settings_path, status: :see_other)
    end

    private

    def update_project_notification_setting(project_id = params.dig(:notification_setting, :project_id))
      project = Project.find(project_id)
      setting = @user.notification_settings.find_or_initialize_by(project:)
      persist_notification_setting(setting, project_notification_params)
    end

    def persist_notification_setting(setting, update_params)
      if setting.update(update_params)
        flash[:notice] = I18n.t(:notice_successful_update)
      else
        flash[:error] = I18n.t(:notice_failed_to_save_messages,
                               count: setting.errors.count,
                               object: setting.class.model_name.human)
      end
    end

    def project_notification_params
      permitted_params.notification_setting_project.except(:project_id).merge(build_date_alerts_params)
    end

    def build_date_alerts_params
      ns_params = params.fetch(:notification_setting, {})
      {
        start_date: date_alert_value(ns_params, :start_date),
        due_date: date_alert_value(ns_params, :due_date),
        overdue: date_alert_value(ns_params, :overdue)
      }
    end

    def workdays_pref_params
      pref_params = permitted_params.pref.to_h
      pref_params.merge("workdays" => pref_params.fetch("workdays", []))
    end

    def update_service_flash_message(call)
      if call.success?
        I18n.t(:notice_successful_update)
      else
        call.errors.full_messages.join(", ")
      end
    end

    def date_alert_value(ns_params, field)
      return nil unless ns_params["#{field}_active"] == "1"

      ns_params[field.to_s].presence&.to_i
    end

    # To be implemented by the including controller
    def notifications_settings_path
      raise SubclassResponsibilityError
    end

    def workdays_redirect_path
      raise SubclassResponsibilityError
    end

    def project_notifications_create_url
      raise SubclassResponsibilityError
    end

    def project_setting_form_url(_project_id)
      raise SubclassResponsibilityError
    end
  end
end
