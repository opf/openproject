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

module Admin
  module Departments
    class HierarchyLayoutComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      attr_reader :groups, :active_group

      def initialize(groups:, active_group: nil, add_user: false, add_subgroup: false)
        super()
        @groups = groups
        @active_group = active_group
        @add_user = add_user
        @add_subgroup = add_subgroup
      end

      def render_group_tree(tree, parent_id: nil)
        children_for(parent_id).each do |group|
          node_attrs = {
            label: group.name,
            href: admin_department_path(group),
            current: group == active_group
          }

          if children?(group)
            tree.with_sub_tree(**node_attrs, expanded: expanded?(group)) do |sub_tree|
              render_group_tree(sub_tree, parent_id: group.id)
            end
          else
            tree.with_leaf(**node_attrs)
          end
        end
      end

      private

      def children_by_parent_id
        @children_by_parent_id ||= groups.group_by(&:parent_id)
      end

      def children_for(parent_id)
        children_by_parent_id[parent_id] || []
      end

      def children?(group)
        children_by_parent_id.key?(group.id)
      end

      def expanded?(group)
        return false unless active_group

        active_group == group || active_group_ancestor_ids.include?(group.id)
      end

      def active_group_ancestor_ids
        @active_group_ancestor_ids ||= compute_ancestor_ids(active_group)
      end

      def groups_by_id
        @groups_by_id ||= groups.index_by(&:id)
      end

      def ancestors_for(group)
        return [] unless group

        ancestor_ids = active_group_ancestor_ids
        ancestor_ids.reverse.filter_map { |id| groups_by_id[id] }
      end

      def compute_ancestor_ids(group)
        return [] unless group

        ids = []
        current = group
        while current.parent_id
          ids << current.parent_id
          current = groups_by_id[current.parent_id]
          break unless current
        end
        ids
      end
    end
  end
end
