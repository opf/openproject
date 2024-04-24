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

module Members
  class CleanupService < ::BaseServices::BaseCallable
    def initialize(users, projects)
      self.users = users
      self.projects = Array(projects)

      super()
    end

    protected

    def perform(*)
      prune_watchers
      unassign_categories

      ServiceResult.success
    end

    attr_accessor :users,
                  :projects

    def prune_watchers
      Watcher.prune(user: users, project_id: project_ids)
    end

    def unassign_categories
      Category
        .where(assigned_to_id: users)
        .where(project_id: project_ids)
        .where.not(assigned_to_id: Member.assignable.of_project(projects).select(:user_id))
        .update_all(assigned_to_id: nil)
    end

    def project_ids
      projects.first.is_a?(Project) ? projects.map(&:id) : projects
    end

    def members_table
      Member.table_name
    end
  end
end
