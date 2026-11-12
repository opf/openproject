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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin::Import
  class JiraController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"

    menu_item :jira_import

    before_action :require_admin
    before_action :set_jira, only: %i[show edit update destroy clear_credential]

    def index
      @jira_instances = Import::Jira.order(created_at: :desc)
    end

    def show
      @jira_imports = Import::JiraImport.where(jira_id: @jira.id).order(id: :desc)
    end

    def new
      @jira = Import::Jira.new
    end

    def edit; end

    def create
      result = ::Import::Jiras::CreateService.new(user: User.current).call(jira_params)
      handle_service_result(result, notice: :notice_successful_create, failure_view: :new)
    end

    def update
      result = ::Import::Jiras::UpdateService.new(user: User.current, model: @jira).call(jira_params)
      handle_service_result(result, notice: :notice_successful_update, failure_view: :edit)
    end

    def destroy
      if Import::JiraImport.exists?(jira_id: @jira.id)
        flash[:error] = t(:"admin.jira.errors.cannot_delete_with_imports")
      else
        @jira.destroy!
        flash[:notice] = t(:notice_successful_delete)
      end
      redirect_to action: :index, status: :see_other
    end

    def clear_credential
      field = params[:field]

      if %w[personal_access_token basic_auth_password].include?(field)
        @jira.update!(field => nil)
        flash[:notice] = t(:"admin.jira.#{field}_deleted")
      end
      redirect_to(edit_admin_import_jira_path(@jira), status: :see_other)
    end

    def test_connection
      stream_connection_check(jira_with_form_values)
      respond_with_turbo_streams
    end

    private

    def set_jira
      @jira = Import::Jira.find(params.expect(:id))
    end

    def stream_connection_check(jira)
      report = Import::Jiras::Validators::ConnectionValidator.new(jira).call
      update_via_turbo_stream(component: Admin::Import::Jira::ConnectionCheckComponent.new(jira, report:))
    rescue StandardError => e
      OpenProject.logger.error("Testing the Jira connection failed", exception: e)
      render_error_flash_message_via_turbo_stream(message: I18n.t("js.error.internal"))
    end

    def jira_with_form_values
      jira = params[:id] ? set_jira : Import::Jira.new
      jira.assign_attributes(jira_params)
      jira
    end

    def jira_params
      permitted = params.expect(
        import_jira: %i[name
                        url
                        personal_access_token
                        exclude_resolution_fields
                        auth_method
                        basic_auth_username
                        basic_auth_password]
      )
      %i[personal_access_token basic_auth_password].each do |credential|
        permitted.delete(credential) if permitted[credential].blank?
      end
      permitted
    end

    def handle_service_result(result, notice:, failure_view:)
      @jira = result.result

      if result.failure?
        stream_form_component { |format| format.html { render failure_view } }
      elsif @jira.saved_change_to_connection?
        redirect_after_connection_check(notice:)
      else
        redirect_to_saved_configuration(notice:)
      end
    end

    def redirect_after_connection_check(notice:)
      report = Import::Jiras::CheckConnectionService.new(@jira).call.result

      if report.unhealthy? || report.warning?
        redirect_to_connection_check_dialog(report)
      else
        redirect_to_saved_configuration(notice:)
      end
    end

    def redirect_to_saved_configuration(notice:)
      flash[:notice] = t(notice)
      redirect_to admin_import_jira_path(@jira)
    end

    def redirect_to_connection_check_dialog(report)
      flash_op_modal(component: Admin::Import::Jira::ConnectionCheckDialogComponent,
                     parameters: { health_report_id: report.id })
      redirect_to edit_admin_import_jira_path(@jira)
    end

    def stream_form_component(&)
      update_via_turbo_stream(component: Admin::Import::Jira::FormComponent.new(@jira))
      respond_with_turbo_streams(&)
    end
  end
end
