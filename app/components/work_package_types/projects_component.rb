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

module WorkPackageTypes
  class ProjectsComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    def form_options
      {
        url: type_projects_path(**variant.path_args),
        method: :put,
        model:,
        data: {
          controller: "admin--work-package-type-projects"
        }
      }
    end

    def build_project_tree(tree)
      nested_project_list = Project.build_projects_hierarchy(projects)

      add_sub_tree(tree, nested_project_list)
    end

    def enable_all_available? = variant.is_default_variant?

    def enabled_for_all_projects?
      enable_all_available? && enabled_project_ids.sort == projects.pluck(:id).sort
    end

    def variant = options[:variant]

    private

    def projects = options[:projects]

    def enabled_project_ids = @enabled_project_ids ||= variant.projects.pluck(:id)

    def add_sub_tree(tree, project_list)
      project_list.each do |project_hash|
        if project_hash[:children].empty?
          tree.with_leaf(**item_options(project_hash[:project]))
        else
          tree.with_sub_tree(expanded: true,
                             select_strategy: :self,
                             **item_options(project_hash[:project])) do |sub_tree|
            add_sub_tree(sub_tree, project_hash[:children])
          end
        end
      end
    end

    def item_options(item)
      {
        select_variant: :multiple,
        label: item.name,
        data: { project_id: item.id },
        checked: enabled_project_ids.include?(item.id)
      }
    end
  end
end
