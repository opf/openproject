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

module Projects
  module Settings
    module WorkPackages
      module Types
        # A project's types settings as a page a variant switch starts from: it switches the
        # project's own member of a type.
        module VariantSwitching
          extend ActiveSupport::Concern

          include ::Projects::Types::Switch::Flow

          included do
            before_action :load_type
          end

          private

          # The type is looked up globally and checked against the families the project uses, so a
          # page left open after the type was removed answers with a message rather than a 404.
          def load_type
            @type = ::Type.find_by(id: params[:type_id])
            return if @type && @project.project_types.exists?(type_id: @type.id)

            render_error_flash_message_via_turbo_stream(message: t("projects.settings.types.type_not_found"))
            respond_to_with_turbo_streams(status: :unprocessable_entity)
          end

          def switch_selection
            @switch_selection ||= ::Projects::Types::Switch::Selection.new(type: @type, projects: [@project],
                                                                           user: current_user)
          end

          def switch_url = project_settings_work_packages_type_switch_path(@project, @type)

          def switch_confirmation_url = new_project_settings_work_packages_type_switch_confirmation_path(@project, @type)

          def switch_impact_url = project_settings_work_packages_type_switch_impact_path(@project, @type)

          # Reload so the repainted list no longer sees the association's cached types.
          def refresh_after_switch
            replace_via_turbo_stream(component: ListComponent.new(project: @project.reload))
          end
        end
      end
    end
  end
end
