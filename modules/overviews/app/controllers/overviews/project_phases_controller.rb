# frozen_string_literal: true

# -- copyright
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
# ++

module ::Overviews
  class ProjectPhasesController < ::ApplicationController
    include OpTurbo::ComponentStream

    before_action :find_project_phase_and_project
    before_action :authorize

    def edit
      respond_with_dialog(Overviews::ProjectPhases::EditDialogComponent.new(@project_phase))
    end

    def preview
      service_call = ::ProjectPhases::SetAttributesService
                .new(user: current_user,
                     model: @project_phase,
                     contract_class: ::ProjectPhases::UpdateContract)
                .call(permitted_params.project_phase)

      update_via_turbo_stream(
        component: Overviews::ProjectPhases::EditComponent.new(service_call.result),
        method: "morph"
      )
      # TODO: :unprocessable_entity is not nice, change the dialog logic to accept :ok
      # without dismissing the dialog, alternatively use turbo frames instead of streams.
      respond_to_with_turbo_streams(status: :unprocessable_entity)
    end

    def update
      service_call = ::ProjectPhases::UpdateService
                      .new(user: current_user, model: @project_phase)
                      .call(permitted_params.project_phase)

      component = if service_call.success?
                    Overviews::ProjectPhases::SidePanelComponent.new(project: @project)
                  else
                    Overviews::ProjectPhases::EditComponent.new(service_call.result)
                  end

      update_via_turbo_stream(component:)
      respond_to_with_turbo_streams(status: service_call)
    end

    private

    def find_project_phase_and_project
      @project_phase = Project::Phase.where(active: true)
                                     .eager_load(:definition, :project)
                                     .find(params[:id])
      @project = @project_phase.project
    end
  end
end
