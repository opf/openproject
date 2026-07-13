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

module Admin::Import::Jira
  class InstancesController < ApplicationController
    include OpTurbo::ComponentStream

    layout "admin"

    menu_item :jira_import

    before_action :require_admin
    before_action :set_jira, only: %i[show edit update destroy delete_token]

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
      handle_service_result(result, success_path: -> { admin_import_jira_path(result.result.id) }, failure_view: :new)
    end

    def update
      result = ::Import::Jiras::UpdateService.new(user: User.current, model: @jira).call(jira_params)
      handle_service_result(result, success_path: -> { admin_import_jira_path(result.result.id) }, failure_view: :edit)
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

    def delete_token
      @jira.update!(personal_access_token: nil)
      flash[:notice] = t(:"admin.jira.token_deleted")
      redirect_to edit_admin_import_jira_path(@jira), status: :see_other
    end

    def test
      test_configuration(params[:url], token_for_test)
    rescue StandardError => e
      handle_test_error(e)
    ensure
      respond_with_turbo_streams
    end

    private

    def set_jira
      @jira = Import::Jira.find(params[:id])
    end

    def jira_params
      permitted = params.expect(import_jira: %i[name url personal_access_token])
      if action_name == "update" && permitted[:personal_access_token].blank?
        permitted.delete(:personal_access_token)
      end
      permitted
    end

    def handle_service_result(result, success_path:, failure_view:)
      if result.failure?
        @jira = result.result
        stream_form_component { |format| format.html { render failure_view } }
      else
        flash[:notice] = t(action_name == "create" ? :notice_successful_create : :notice_successful_update)
        redirect_to success_path.call
      end
    end

    def stream_form_component(&)
      update_via_turbo_stream(component: Admin::Import::Jira::FormComponent.new(@jira))
      respond_with_turbo_streams(&)
    end

    def valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
    end

    def token_for_test
      return params[:personal_access_token] if params[:personal_access_token].present?

      Import::Jira.find(params[:id]).personal_access_token if params[:id].present?
    end

    def handle_test_error(error)
      message = case error
                when Import::JiraClient::SsrfError
                  link_translate("admin.jira.client.ssrf_block_doc_link",
                                 links: { docs_url: %i[sysadmin_docs ssrf_protection] }).prepend("#{error.message} ")
                when Import::JiraClient::ConnectionError then t(:"admin.jira.test.connection_error", message: error.message)
                when Import::JiraClient::ParseError then t(:"admin.jira.test.parse_error")
                when Import::JiraClient::ApiError then t(:"admin.jira.test.api_error", status: error.status)
                else
                  Rails.logger.error("Unexpected error testing Jira configuration: #{error.class} - #{error.message}")
                  "#{t(:"admin.jira.test.error")}: #{error.message}"
                end
      render_error_flash_message_via_turbo_stream(message:)
    end

    def test_configuration(url, personal_access_token)
      if url.blank? || personal_access_token.blank?
        return render_error_flash_message_via_turbo_stream(message: t(:"admin.jira.test.missing_credentials"))
      end
      unless valid_url?(url)
        return render_error_flash_message_via_turbo_stream(message: t(:"admin.jira.test.invalid_url"))
      end

      render_test_result(Import::JiraClient.new(url:, personal_access_token:).server_info)
    end

    def render_test_result(response)
      if response.is_a?(Hash)
        server = response["serverTitle"] || Import::Jira.model_name
        version = response["version"] || "?"
        render_success_flash_message_via_turbo_stream(message: t(:"admin.jira.test.success", server:, version:))
      else
        render_error_flash_message_via_turbo_stream(message: t(:"admin.jira.test.failed"))
      end
    end
  end
end
