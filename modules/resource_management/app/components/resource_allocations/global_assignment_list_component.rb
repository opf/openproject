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

module ResourceAllocations
  # The global Staffing list: one collapsible section per project the user may
  # staff in. Sections without anything to staff are kept, collapsed, so an
  # absent project reads as "you cannot staff here" rather than "nothing to do".
  class GlobalAssignmentListComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(sections:, visible_work_package_ids:)
      super

      @sections = sections
      @visible_work_package_ids = visible_work_package_ids
    end

    private

    attr_reader :sections, :visible_work_package_ids

    def body_id(project)
      "staffing-project-#{project.id}"
    end

    # The rows link back to the global staffing routes, so the assignment dialog
    # returns to this page rather than the project's.
    def table_for(allocations)
      AssignmentTableComponent.new(rows: allocations, project: nil, visible_work_package_ids:)
    end
  end
end
