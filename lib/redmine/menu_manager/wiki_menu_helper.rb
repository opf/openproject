#-- encoding: UTF-8
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

module Redmine::MenuManager::WikiMenuHelper
  def build_wiki_menus(project)
    return unless project.enabled_module_names.include? 'wiki'
    project_wiki = project.wiki

    MenuItems::WikiMenuItem.main_items(project_wiki).each do |main_item|
      Redmine::MenuManager.loose :project_menu do |menu|
        push_wiki_main_menu(menu, main_item)

        main_item.children.each do |child|
          push_wiki_menu_subitem(menu, main_item, child)
        end
      end
    end
  end

  def push_wiki_main_menu(menu, main_item)
    menu.push main_item.menu_identifier,
              { controller: '/wiki', action: 'show', id: main_item.slug },
              param: :project_id,
              caption: main_item.title,
              after: :repository,
              icon: 'icon2 icon-wiki',
              html:    { class: 'wiki-menu--main-item' }
  rescue ArgumentError => e
    Rails.logger.error "Failed to add wiki item #{main_item.slug} to wiki menu: #{e}. Deleting it."
    main_item.destroy
  end

  def push_wiki_menu_subitem(menu, main_item, child)
    menu.push child.menu_identifier,
              { controller: '/wiki', action: 'show', id: child.slug },
              param: :project_id,
              caption: child.title,
              icon: 'icon2 icon-wiki2',
              html:    { class: 'wiki-menu--sub-item' },
              parent: main_item.menu_identifier
  rescue ArgumentError => e
    Rails.logger.error "Failed to add wiki item #{child.slug} to wiki menu: #{e}. Deleting it."
    child.destroy
  end
end
