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

module Sprints::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      # Returns all sprints the user is allowed to see.
      # A sprint is visible if its project is a sprint source for any project
      # where the user has the :view_sprints permission (accounting for sprint sharing
      # configuration), or if it has work packages in such a project.
      def visible(user = User.current)
        allowed_projects = Project.allowed_to(user, :view_sprints)
        source_project = Project.sprint_source_for(allowed_projects)
        from_wps = WorkPackage.where(project: allowed_projects).where.not(sprint_id: nil)

        where(project_id: source_project.select(:id))
          .or(where(id: from_wps.select(:sprint_id)))
      end
    end
  end
end
