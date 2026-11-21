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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  class AddAssignmentsForm < ApplicationForm
    def self.selected_ids(values)
      Array(values).filter_map do |value|
        node = JSON.parse(value)
        Integer(node["nodeId"], exception: false) if node.is_a?(Hash)
      rescue JSON::ParserError, TypeError
        nil
      end
    end

    def initialize(projects:)
      super()
      @nodes = Project.build_projects_hierarchy(projects)
    end

    form do |form|
      form.filterable_tree_view(
        name: :project_ids,
        label: Project.model_name.human(count: 2),
        visually_hide_label: true,
        filter_input_arguments: { placeholder: I18n.t("types.edit.projects.add_dialog.search_placeholder") }
      ) do |tree|
        add_nodes(tree, @nodes)
      end
    end

    private

    def add_nodes(tree, nodes)
      nodes.each do |node|
        project = node.fetch(:project)
        children = node.fetch(:children)
        options = { label: project.name, select_variant: :multiple, data: { node_id: project.id } }

        if children.empty?
          tree.with_leaf(**options)
        else
          tree.with_sub_tree(select_strategy: :self, expanded: true, **options) do |sub_tree|
            add_nodes(sub_tree, children)
          end
        end
      end
    end
  end
end
