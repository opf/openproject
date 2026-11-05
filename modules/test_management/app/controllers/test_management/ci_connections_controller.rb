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

module TestManagement
  class CiConnectionsController < ::Projects::SettingsController
    include TestManagement::CiFeature

    menu_item :settings_test_management

    before_action :find_connection, only: %i[update destroy]

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

    private

    def find_connection
      @connection = TestManagement::CiConnection.where(project_id: @project.id).find(params.expect(:id))
    end

    def connection_params
      params.fetch(:ci_connection, {})
            .permit(:name, :provider, :repository, :ingest_mode, :target_run_name, :active, :token, :remove_token,
                    :workflow, :trigger_ref)
            .to_h
    end

    def flash_result(call, notice)
      if call.success?
        flash[:notice] = I18n.t("test_management.project_settings.ci.#{notice}")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
      redirect_to project_test_management_project_settings_path(@project, anchor: "tm-ci-connections"), status: :see_other
    end
  end
end
