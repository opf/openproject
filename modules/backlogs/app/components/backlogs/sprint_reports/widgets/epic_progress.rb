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

module Backlogs
  module SprintReports
    module Widgets
      class EpicProgress < Grids::WidgetComponent
        include Backlogs::CommonHelper

        param :sprint
        param :project

        def title
          epic_type.name
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render?
          epic_type.present? && user_allowed?(:view_sprints)
        end

        private

        def work_packages_in_sprint
          WorkPackage.where(sprint:, project:).visible
        end

        def epics
          WorkPackage.where(id: ancestor_ids, type: epic_type).visible
        end

        def ancestor_ids
          @ancestor_ids ||= WorkPackageHierarchy
                              .where(descendant_id: work_packages_in_sprint.select(:id))
                              .where("generations > 0")
                              .distinct
                              .pluck(:ancestor_id)
        end

        def epic_type
          return @epic_type if defined?(@epic_type)

          @epic_type = Type.find_by(name: "Epic")
        end
      end
    end
  end
end
