#-- encoding: UTF-8
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

module Redmine::MenuManager::WikiMenuHelper
  def build_wiki_menus(project)
    return unless project.enabled_module_names.include? 'wiki'
    project_wiki = project.wiki

    MenuItems::WikiMenuItem.main_items(project_wiki).each do |main_item|
      Redmine::MenuManager.loose :project_menu do |menu|
        push_wiki_main_menu(menu, main_item, project)

        main_item.children.each do |child|
          push_wiki_menu_subitem(menu, main_item, child)
        end
      end
    end
  end

  def push_wiki_main_menu(menu, main_item, project)
    menu.push main_item.menu_identifier,
              { controller: '/wiki', action: 'show', id: main_item.slug },
              param: :project_id,
              caption: main_item.title,
              after: :repository,
              icon: 'icon2 icon-wiki',
              html:    { class: 'wiki-menu--main-item' }

    if project.wiki.pages.any?
      push_wiki_menu_partial(main_item, menu)
    end
  rescue ArgumentError => e
    Rails.logger.error "Failed to add wiki item #{main_item.slug} to wiki menu: #{e}. Deleting it."
    main_item.destroy
  end

  def push_wiki_menu_subitem(menu, main_item, child)
    menu.push child.menu_identifier,
              { controller: '/wiki', action: 'show', id: child.slug },
              param: :project_id,
              caption: child.title,
              html:    { class: 'wiki-menu--sub-item' },
              parent: main_item.menu_identifier
  rescue ArgumentError => e
    Rails.logger.error "Failed to add wiki item #{child.slug} to wiki menu: #{e}. Deleting it."
    child.destroy
  end

  def default_menu_item(page)
    if (main_item = page.nearest_main_item)
      main_item
    else
      MenuItems::WikiMenuItem.main_items(page.wiki.id).first
    end
  end

  private

  def push_wiki_menu_partial(main_item, menu)
    menu.push :wiki_menu_partial,
              { controller: '/wiki', action: 'show' },
              param: :project_id,
              parent: main_item.menu_identifier,
              partial: 'wiki/menu_pages_tree',
              last: true
  end
end
