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
    class ChangeParentDialogComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      DIALOG_ID = "departments--change-parent-dialog"
      FORM_ID = "departments--change-parent-form"

      def initialize(department:, departments:)
        super()
        @department = department
        @departments = departments
      end

      def form_arguments
        {
          id: FORM_ID,
          url: change_parent_admin_department_path(@department),
          method: :post
        }
      end

      def render_tree(tree_view)
        add_sub_tree(tree_view, nil)
      end

      private

      def departments_by_parent_id
        @departments_by_parent_id ||= @departments.group_by(&:parent_id)
      end

      def children_for(parent_id)
        departments_by_parent_id[parent_id] || []
      end

      def add_sub_tree(tree_view, parent_id)
        children_for(parent_id).each do |dept|
          attrs = item_attributes(dept)
          children = children_for(dept.id)

          if children.any?
            tree_view.with_sub_tree(**attrs) do |sub_tree|
              add_sub_tree(sub_tree, dept.id)
            end
          else
            tree_view.with_leaf(**attrs)
          end
        end
      end

      def item_attributes(dept)
        {
          label: dept.name,
          value: dept.id,
          select_variant: :single,
          current: dept.id == @department.id,
          disabled: disabled_ids.include?(dept.id),
          expanded: dept.id == @department.parent_id
        }
      end

      def disabled_ids
        # Disallow the department itself, its current parent and descendants (circular), as well as
        # any department managed by LDAP (the sync owns its sub-tree).
        @disabled_ids ||= Set.new(
          [@department.id, @department.parent_id].compact +
            descendant_ids(@department.id) +
            @departments.select(&:ldap_managed?).map(&:id)
        )
      end

      def descendant_ids(dept_id)
        children_for(dept_id).flat_map { |child| [child.id] + descendant_ids(child.id) }
      end
    end
  end
end
