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

module Projects::Hierarchy
  extend ActiveSupport::Concern

  class_methods do
    # builds up a project hierarchy helper structure for use with #project_tree_from_hierarchy
    #
    # it expects a simple list of projects with a #lft column (awesome_nested_set)
    # and returns a hierarchy based on #lft
    #
    # the result is a nested list of root level projects that contain their child projects
    # but, each entry is actually a ruby hash wrapping the project and child projects
    # the keys are :project and :children where :children is in the same format again
    #
    #   result = [ root_level_project_info_1, root_level_project_info_2, ... ]
    #
    # where each entry has the form
    #
    #   project_info = { project: the_project, children: [ child_info_1, child_info_2, ... ] }
    #
    # if a project has no children the :children array is just empty
    #
    def build_projects_hierarchy(projects) # rubocop:disable Metrics/AbcSize
      ancestors = []
      result = []

      projects.sort_by(&:lft).each do |project|
        while ancestors.any? && !project.is_descendant_of?(ancestors.last[:project])
          # before we pop back one level, we sort the child projects by name
          ancestors.last[:children] = sort_by_name(ancestors.last[:children])
          ancestors.pop
        end

        current_hierarchy = { project:, children: [] }
        current_tree = ancestors.any? ? ancestors.last[:children] : result

        current_tree << current_hierarchy
        ancestors << current_hierarchy
      end

      # When the last project is deeply nested, we need to sort
      # all layers we are in.
      ancestors.each do |level|
        level[:children] = sort_by_name(level[:children])
      end
      # we need one extra element to ensure sorting at the end
      # at the end the root level must be sorted as well
      sort_by_name(result)
    end

    def project_tree_from_hierarchy(projects_hierarchy, level, &)
      projects_hierarchy.each do |hierarchy|
        project = hierarchy[:project]
        children = hierarchy[:children]
        yield project, level
        # recursively show children
        project_tree_from_hierarchy(children, level + 1, &) if children.any?
      end
    end

    # Yields the given block for each project with its level in the tree
    def project_tree(projects, &)
      projects_hierarchy = build_projects_hierarchy(projects)
      project_tree_from_hierarchy(projects_hierarchy, 0, &)
    end

    # Returns the visible/active projects within `boundary` (or, without one, all visible/active
    # root-level projects) that have no visible/active ancestor also in that set.
    def nearest_visible_descendants(boundary = nil, limit: nil)
      # Both the root case and the within-boundary case reduce to the same question: which
      # projects in a visible set have no ancestor also in that set? Only the set differs -
      # unrestricted for roots, narrowed to the boundary's descendants otherwise.
      scope = if boundary
                boundary.descendants
              else
                Project.all
              end

      # With awesome_nested_set, for a list of projects ordered by "lft ASC"
      # one part of the criteria for whether a project A is an ancestor of another
      # project B is already given by the position in the list (A.lft < B.lft).
      # Only projects above the current project can potentially be ancestors and need
      # to be checked.
      # Note that here, those that have no ancestors are of interest.
      # We know that a project has no ancestor if its rgt is higher than all the rgt values
      # of the preceding projects (B.rgt > A.rgt)
      #
      # To calculate this efficiently, a window function is used:
      # max_preceding_rgt is the maximum rgt value of all the preceding projects
      # (`ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING`) where the preceding projects
      # are those with a smaller lft value (ORDER BY lft).
      #
      # Since the value of max_preceding_rgt is calculated on each row, it can now be compared
      # directly within itself.
      # The first row is a special case, as it has no preceding projects, its max_preceding_rgt is NULL, which is
      # why the `IS NULL` condition is necessary.
      visible_scope = scope
                        .visible
                        .select("
                          *,
                          max(rgt) OVER (ORDER BY lft ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS max_preceding_rgt")

      ancestor_scope = Project
                         .with(projects: visible_scope)
                         .where("projects.max_preceding_rgt IS NULL OR projects.rgt > projects.max_preceding_rgt")
                         .order("projects.lft")

      if limit
        ancestor_scope.limit(limit)
      else
        ancestor_scope
      end
    end

    # Returns the projects in `candidates` that have at least one visible, active descendant.
    # Used to decide whether a node gets an expand arrow or renders as a leaf
    # has_subprojects?/leaf? is not enough, as it only looks at lft/rgt and would count an archived or invisible
    # descendant as "has children" too.
    def with_visible_descendants(candidates)
      candidates = Array(candidates)
      return none if candidates.empty?

      visible_ids = visible_active_ids_within(candidates)
      return none if visible_ids.empty?

      Project
        .where(id: candidates.map(&:id))
        .where(
          "EXISTS (
           SELECT 1 FROM projects descendant
           WHERE descendant.id IN (?)
             AND descendant.lft > projects.lft AND descendant.rgt < projects.rgt
         )", visible_ids
        )
    end

    private

    def sort_by_name(project_hashes)
      project_hashes.sort_by { |h| h[:project].name&.downcase }
    end

    def visible_active_ids_within(candidates)
      min_lft = candidates.map(&:lft).min
      max_rgt = candidates.map(&:rgt).max
      Project.visible.active.where("lft > ? AND rgt < ?", min_lft, max_rgt).pluck(:id)
    end
  end

  included do
    acts_as_nested_set order_column: :lft, dependent: :destroy

    # Keep the siblings sorted after naming changes to ensure lft sort includes name sorting
    before_save :remember_reorder
    after_save :reorder_by_name, if: -> { @reorder_nested_set }

    # Returns an array of projects that are in this project's hierarchy
    #
    # Example: parents, children, siblings
    def hierarchy
      parents = project.self_and_ancestors || []
      descendants = project.descendants || []
      parents | descendants # Set union
    end

    def has_subprojects?
      !leaf?
    end

    # Returns an array of active subprojects.
    def active_subprojects
      project.descendants.where(active: true)
    end

    def reorder_by_name
      @reorder_nested_set = nil
      return unless siblings.any?

      left_neighbor = left_neighbor_by_name_order

      if left_neighbor
        move_to_right_of(left_neighbor)
      elsif self != self_and_siblings.first
        move_to_left_of(self_and_siblings.first)
      end
    end

    ##
    # Find the sibling for which the current project's name is smaller.
    # Since we sort ascending, start from the back.
    # Returns:
    #   - nil, if the current project does not have a left neighbor (should be added as first)
    #   - the project sibling for which the project should be appended to the right to
    def left_neighbor_by_name_order
      siblings
        .reverse_each
        .detect { |project| project.name.casecmp(name) == -1 }
    end

    # We need to remember if we want to reorder as nested_set
    # will perform another save directly in +after_save+ if a parent was set
    # and that clear new_record? as well as previous_new_record?
    def remember_reorder
      @reorder_nested_set = new_record? || name_changed?
    end

    # Returns a :conditions SQL string that can be used to find the issues associated with this project.
    #
    # Examples:
    #   project.with_subprojects(true)  => "(projects.id = 1 OR (projects.lft > 1 AND projects.rgt < 10))"
    #   project.with_subprojects(false) => "projects.id = 1"
    def with_subprojects(with_subprojects)
      projects_table = Project.arel_table

      stmt = projects_table[:id].eq(id)
      if with_subprojects && has_subprojects?
        stmt = stmt.or(projects_table[:lft].gt(lft).and(projects_table[:rgt].lt(rgt)))
      end
      stmt
    end

    def allowed_parent_workspace_types = Project::ALLOWED_PARENT_WORKSPACE_TYPES[workspace_type] || []

    def parent_allowed?
      allowed_parent_workspace_types.any?
    end
  end
end
