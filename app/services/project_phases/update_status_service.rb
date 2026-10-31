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

module ProjectPhases
  class UpdateStatusService < ::BaseServices::Update
    delegate :project, to: :model

    def after_perform(*)
      cascade_to_other_phases
      project.touch_and_save_journals

      super
    end

    private

    def cascade_to_other_phases
      earlier, later = project.available_phases
                              .reject { it == model }
                              .partition { it.position < model.position }

      earlier_status, later_status = cascaded_statuses.values_at(:earlier, :later)

      update_statuses(earlier, earlier_status)
      update_statuses(later, later_status)
    end

    def update_statuses(phases, status)
      return if status.nil?

      ids = phases.reject { it.status == status }.map(&:id)
      return if ids.empty?

      Project::Phase.where(id: ids).update_all(status:, updated_at: Time.current)
    end

    def cascaded_statuses
      open, in_progress, completed = Project::Phase.statuses.values_at(:open, :in_progress, :completed)

      case model.status
      when open        then { later: open }
      when in_progress then { earlier: completed, later: open }
      when completed   then { earlier: completed }
      end
    end

    def default_contract_class = ProjectPhases::UpdateStatusContract
  end
end
