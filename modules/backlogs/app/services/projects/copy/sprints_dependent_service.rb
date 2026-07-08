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
      state.sprint_id_lookup = copy_owned_sprints.merge(preserved_shared_sprints)
    end

    # Sprints owned by the source project are recreated on the copy; the lookup
    # maps each source id to its copy so the copied work packages follow. Goals
    # are eager-loaded so +copied_goal_attributes+ does not query per sprint.
    def copy_owned_sprints
      copy_collection_with_id_map(:sprints, source_scope: source.sprints.includes(:goals)) do |source_sprint|
        { goals_attributes: copied_goal_attributes(source_sprint) }
      end
    end

    # Shared sprints (owned by another project) that the source's work packages
    # reference: keep the assignment only when the copied project will also
    # receive that sprint, otherwise leave it unmapped so the work-package copy
    # clears it rather than pointing at a sprint the copy cannot see. Resolved in
    # a single query against the sprints the target natively receives (its own
    # sprint source), producing an id => id identity map.
    def preserved_shared_sprints
      Sprint.native_to_sprint_source(target)
            .where(id: source.work_packages.select(:sprint_id))
            .where.not(project_id: source.id)
            .pluck(:id)
            .index_with { |id| id }
    end

    # Only the source project's own goals are carried over; a shared sprint may
    # also hold goals owned by other projects, which are not ours to copy.
    # Filtered in Ruby to reuse the eager-loaded goals association.
    def copied_goal_attributes(source_sprint)
      source_sprint.goals
                   .select { |goal| goal.project_id == source.id }
                   .map { |goal| { text: goal.text, project_id: target.id } }
    end
  end
end
