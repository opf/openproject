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

module Projects::Copy
  class SprintsDependentService < Dependency
    def self.human_name
      I18n.t("projects.copy.sprints")
    end

    def source_count
      source.sprints.count
    end

    protected

    def copy_dependency(*)
      if source.receive_shared_sprints?
        preserve_sprint_assignments
      else
        copy_sprints
      end
    end

    def preserve_sprint_assignments
      state.sprint_id_lookup = Sprint.for_project(source).pluck(:id).index_with { |id| id }
    end

    def copy_sprints
      state.sprint_id_lookup = copy_collection_with_id_map(:sprints) do |source_sprint|
        { goals_attributes: copied_goal_attributes(source_sprint) }
      end
    end

    # Only the source project's own goals are carried over; a shared sprint may
    # also hold goals owned by other projects, which are not ours to copy.
    def copied_goal_attributes(source_sprint)
      source_sprint.goals.where(project_id: source.id).map do |goal|
        { text: goal.text, project_id: target.id }
      end
    end
  end
end
