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
      project.available_phases.each do |other|
        next if other == model

        target = cascaded_status(earlier: other.position < model.position)
        next if target.nil? || other.status == target

        other.update!(status: target)
      end
    end

    def cascaded_status(earlier:)
      case model.status
      when "open"        then earlier ? nil : "open"
      when "in_progress" then earlier ? "completed" : "open"
      when "completed"   then earlier ? "completed" : nil
      end
    end

    def default_contract_class = ProjectPhases::UpdateStatusContract
  end
end
