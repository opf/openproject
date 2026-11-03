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
    module LifeCycle
      class IndexComponent < ApplicationComponent
        include ApplicationHelper
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        options :project,
                :life_cycle_definitions

        private

        def life_cycle_definitions_and_step_active
          active_ids = project.phases.where(active: true).pluck(:definition_id).to_set

          life_cycle_definitions.all.map do |definition|
            [definition, definition.id.in?(active_ids)]
          end
        end

        def wrapper_data_attributes
          {
            controller: "projects--settings--border-box-filter",
            "projects--settings--border-box-filter-clear-button-id-value": clear_button_id
          }
        end

        def clear_button_id
          "border-box-filter-clear-button"
        end
      end
    end
  end
end
