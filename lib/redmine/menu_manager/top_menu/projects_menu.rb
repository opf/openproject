#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Redmine::MenuManager::TopMenu::ProjectsMenu
  def render_projects_top_menu_node
    return '' if User.current.anonymous? and Setting.login_required?
    return '' if User.current.anonymous? and User.current.number_of_known_projects.zero?

    if User.current.impaired?
      render_impaired_project_links
    else
      render_projects_dropdown
    end
  end

  private

  ##
  # Render the project menu items into the top menu
  def render_impaired_project_links
    project_items.map do |item|
      render_menu_node(item)
    end.join(' ')
  end

  def render_projects_dropdown
    items = project_items

    dropdown_content = link_to(
      l(:label_project_plural),
      '#',
      title: l(:label_project_plural),
      class: "icon5 icon-projects",
      id: 'more-menu',
      aria: { haspopup: 'true' }
    )

    render_drop_down_menu_node(dropdown_content,
                               has_selected_child: any_item_selected?(items)) do
      content_tag :ul, style: 'display:none', class: 'drop-down--projects' do
        result = ''.html_safe
        items.each { |item| result << render_menu_node(item) }
        result << content_tag(:li, id: 'project-search-container') do
          hidden_field_tag('', '', class: 'select2-select')
        end
        result
      end
    end
  end

  def project_items
    if User.current.impaired?
      icon_class = 'icon5'
      projects_label = l(:label_project_plural)
      projects_class = 'icon-projects'
    else
      icon_class = 'icon4'
      projects_label = l(:label_project_view_all)
      projects_class = 'icon-show-all-projects'
    end

    items = []

    items << Redmine::MenuManager::MenuItem.new(
      :list_projects,
      { controller: '/projects', action: 'index' },
      caption: projects_label,
      html: {
        class: "#{projects_class} #{icon_class}",
        accesskey: OpenProject::AccessKeys.key_for(:project_search)
      }
    )
    items << Redmine::MenuManager::MenuItem.new(
      :new_project,
      { controller: '/projects', action: 'new' },
      caption: l(:label_project_new),
      html: {
        class: "icon-add #{icon_class}",
        accesskey: OpenProject::AccessKeys.key_for(:new_project)
      },
      if: Proc.new { User.current.allowed_to?(:add_project, nil, global: true) }
    )

    items
  end
end
