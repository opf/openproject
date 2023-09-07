#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

module Principals::Scopes
  module PossibleAssignee
    extend ActiveSupport::Concern

    class_methods do
      # Returns principals eligible to be assigned to a work package as:
      # * assignee
      # * responsible
      # Those principals can be of class
      # * User
      # * PlaceholderUser
      # * Group
      # User instances need to be non locked (status).
      # Only principals with a role marked as assignable in the project are returned.
      # If more than one project is given, the principals need to be assignable in all of the projects (intersection).
      # @project [Project, [Project]] The project for which eligible candidates are to be searched
      # @return [ActiveRecord::Relation] A scope of eligible candidates

      # TODO: Rework so we can also pass in the work package here
      def possible_assignee(project)
        where(
          id: Member
              .assignable
              .of(project)
              .group('user_id')
              .having(["COUNT(DISTINCT(project_id, user_id)) = ?", Array(project).size])
              .select('user_id')
        )
      end
    end
  end
end
