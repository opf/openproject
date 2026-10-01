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

module Backlogs::WorkPackages
  # Contract used for moving work packages between two sprints at the end
  # of a sprint. It does not enforce permissions as this change is carried
  # out in the background.
  class MoveBetweenSprintsContract < ModelContract
    attribute :sprint
    attribute :position

    validate :active_sprint_in_sharer_project

    private

    def active_sprint_in_sharer_project
      unless Sprint
               .native_to_sprint_source(Sprint.find_by(id: model.sprint_id_was).project)
               .in_planning
               .exists?(id: model.sprint_id)
        errors.add(:sprint, :not_eligible_for_moving)
      end
    end
  end
end
