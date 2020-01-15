#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Redmine::MenuManager::TopMenu::ProjectsMenu
  def render_projects_top_menu_node
    return '' if User.current.anonymous? and Setting.login_required?
    return '' if User.current.anonymous? and User.current.number_of_known_projects.zero?

    render_projects_dropdown
  end

  private

  def render_projects_dropdown
    label = !!(@project && !@project.name.empty?) ? @project.name : t(:label_select_project)
    render_menu_dropdown_with_items(
      label: label,
      label_options: { id: 'projects-menu' },
      items: project_items,
      options: {
        drop_down_class: 'drop-down--projects'
      }
    ) do
      content_tag(:li, id: 'project-search-container') do
        angular_component_tag('project-menu-autocomplete')
      end
    end
  end

  def project_items
    [project_index_item, project_new_item]
  end

  def project_index_item
    Redmine::MenuManager::MenuItem.new(
      :list_projects,
      main_app.projects_path,
      caption: t(:label_project_view_all),
      icon: "icon-show-all-projects icon4",
      html: {
        accesskey: OpenProject::AccessKeys.key_for(:project_search)
      }
    )
  end

  def project_new_item
    Redmine::MenuManager::MenuItem.new(
      :new_project,
      main_app.new_project_path,
      caption: Project.model_name.human,
      icon: "icon-add icon4",
      html: {
        accesskey: OpenProject::AccessKeys.key_for(:new_project),
        aria: {label: t(:label_project_new)},
        title: t(:label_project_new)
      },
      if: Proc.new { User.current.allowed_to?(:add_project, nil, global: true) }
    )
  end

  include OpenProject::StaticRouting::UrlHelpers
end
