# frozen_string_literal: true

module TestManagement
  # Project Settings > Test management > CI connections: create, edit, delete, check.
  # Requires :manage_test_ci. Tokens are write-only: the forms never contain the stored value.
  # Writes go through CiConnections::{Create,Update,Delete}Service, shared with APIv3 (0016).
  class CiConnectionsController < ::Projects::SettingsController
    menu_item :settings_test_management

    before_action :find_connection, only: %i[update destroy check]

    def create
      call = TestManagement::CiConnections::CreateService.new(user: current_user)
                                                         .call(connection_params.merge(project: @project))
      flash_result(call, :created)
    end

    def update
      call = TestManagement::CiConnections::UpdateService.new(user: current_user, model: @connection)
                                                         .call(connection_params)
      flash_result(call, :updated)
    end

    def destroy
      call = TestManagement::CiConnections::DeleteService.new(user: current_user, model: @connection).call
      flash_result(call, :deleted)
    end

    def check
      call = TestManagement::CiConnections::CheckService.new(user: current_user, connection: @connection).call
      if call.success?
        key = "test_management.project_settings.ci.check_statuses.#{@connection.check_status}"
        flash[@connection.check_status == "ok" ? :notice : :error] = "#{@connection.name}: #{I18n.t(key)}"
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to connections_anchor_path, status: :see_other
    end

    private

    def find_connection
      @connection = TestManagement::CiConnection.where(project_id: @project.id).find(params.expect(:id))
    end

    def connection_params
      params.fetch(:ci_connection, {})
            .permit(:name, :provider, :repository, :base_url, :ingest_mode, :target_run_name, :active, :token, :remove_token,
                    :workflow, :trigger_ref, :ci_username, :trigger_token, :remove_trigger_token,
                    :ca_certificate, :inbound_only, :reference_name, :e2e_tests, :scm_repository_id)
            .to_h
    end

    def flash_result(call, notice)
      if call.success?
        flash[:notice] = I18n.t("test_management.project_settings.ci.#{notice}")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to connections_anchor_path, status: :see_other
    end

    def connections_anchor_path
      project_test_management_project_settings_path(@project, anchor: "tm-ci-connections")
    end
  end
end
