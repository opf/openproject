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

module Sprints::Scopes::ReceivingProjects
  extend ActiveSupport::Concern

  class_methods do
    def receiving_projects(sprint)
      Project.where(id: sprint.project_id)
        .or(Project.where(id: shared_receiver_projects(sprint.project_id).select(:id)))
        .or(Project.where(id: sprint.work_packages.select(:project_id)))
    end

    private

    def shared_receiver_projects(source_project_id)
      source_cte = Project
        .where(id: source_project_id)
        .select(:id, :lft, :rgt, Arel.sql("settings ->> 'sprint_sharing' AS sharing_mode"))

      Project.receive_shared_sprints
        .with(source: source_cte)
        .where(
          <<~SQL.squish
            (
              EXISTS (SELECT 1 FROM source WHERE sharing_mode = 'share_all_projects')
              AND NOT EXISTS (
                SELECT 1 FROM projects ancestors
                WHERE ancestors.lft < projects.lft
                  AND ancestors.rgt > projects.rgt
                  AND ancestors.settings ->> 'sprint_sharing' = 'share_subprojects'
              )
            )
            OR
            (
              EXISTS (SELECT 1 FROM source WHERE sharing_mode = 'share_subprojects')
              AND projects.lft > (SELECT lft FROM source)
              AND projects.rgt < (SELECT rgt FROM source)
              AND NOT EXISTS (
                SELECT 1 FROM projects ancestors
                WHERE ancestors.lft < projects.lft
                  AND ancestors.rgt > projects.rgt
                  AND ancestors.id != (SELECT id FROM source)
                  AND ancestors.settings ->> 'sprint_sharing' = 'share_subprojects'
                  AND ancestors.lft >= (SELECT lft FROM source)
                  AND ancestors.rgt <= (SELECT rgt FROM source)
              )
            )
          SQL
        )
    end
  end
end
