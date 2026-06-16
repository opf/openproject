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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  module Settings
    module CostTypes
      class IndexComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers

        def initialize(project:, cost_types:)
          super()
          @project = project
          @cost_types = cost_types
        end

        attr_reader :project, :cost_types

        delegate :empty?, to: :cost_types

        def enabled_cost_type_ids
          @enabled_cost_type_ids ||= ::CostTypesProject.where(project_id: project.id).pluck(:cost_type_id).to_set
        end

        def enabled?(cost_type)
          enabled_cost_type_ids.include?(cost_type.id)
        end

        def toggle_path(cost_type)
          toggle_project_settings_cost_type_path(project, cost_type)
        end

        def toggle_checked?(cost_type)
          cost_type.for_all_projects? || enabled?(cost_type)
        end

        def toggle_disabled?(cost_type)
          cost_type.for_all_projects?
        end

        def toggle_data_attributes(cost_type)
          {
            test_selector: "toggle-project-cost-type-mapping-#{cost_type.id}"
          }.tap do |data|
            if toggle_disabled?(cost_type)
              data[:hover_card_trigger_target] = "trigger"
              data[:hover_card_popover_template_id] = unique_hovercard_id(cost_type)
            end
          end
        end

        def unique_hovercard_id(cost_type)
          "project-cost-type-#{cost_type.id}-disabled-reason"
        end
      end
    end
  end
end
