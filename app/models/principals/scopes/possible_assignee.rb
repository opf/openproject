#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
      # Only principals with a role marked as assignable in the project or work package are returned.
      # If more than one project or work package is given, the principals need to be assignable in all of the
      # resources (intersection).
      # @work_package_or_project [WorkPackage, [WorkPackage], Project, [Project]] The resource for which
      #   eligible candidates are to be searched
      # @return [ActiveRecord::Relation] A scope of eligible candidates
      def possible_assignee(work_package_or_project)
        work_package_or_project = as_collection(work_package_or_project)

        if resource_class(work_package_or_project) == WorkPackage
          where(id: on_work_package_user_ids(work_package_or_project))
            .or(where(id: on_project_user_ids(work_package_or_project.map(&:project_id))))
        else
          where(id: on_project_user_ids(work_package_or_project))
        end
      end

      private

      def resource_class(work_package_or_project)
        if work_package_or_project.all? { _1.class <= WorkPackage }
          WorkPackage
        elsif work_package_or_project.all? { _1.instance_of?(Project) }
          Project
        end
      end

      def as_collection(resource)
        Array(resource)
      end

      def on_work_package_user_ids(work_package)
        Member
          .assignable
          .of_work_package(work_package)
          .group('user_id')
          .having(["COUNT(DISTINCT(project_id, entity_type, entity_id, user_id)) = ?", work_package.size])
          .select('user_id')
      end

      def on_project_user_ids(project)
        Member
          .assignable
          .of_project(project)
          .group('user_id')
          .having(["COUNT(DISTINCT(project_id, user_id)) = ?", project.size])
          .select('user_id')
      end
    end
  end
end
