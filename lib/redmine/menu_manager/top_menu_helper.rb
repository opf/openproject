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

require 'concerns/omniauth_login'

module Redmine::MenuManager::TopMenuHelper
  include Redmine::MenuManager::TopMenu::HelpMenu
  include Redmine::MenuManager::TopMenu::ProjectsMenu

  def render_top_menu_left(project)
    items = split_top_menu_into_main_or_more_menus(project)
    content_tag :ul, id: 'account-nav-left', class: 'menu_root account-nav hidden-for-mobile' do
      [render_main_top_menu_nodes(items[:main]),
       render_projects_top_menu_node,
       render_work_packages_top_menu_node(project, items[:work_packages]),
       render_module_top_menu_node(items[:modules])].join.html_safe
    end
  end

  def render_top_menu_right
    content_tag :ul, id: 'account-nav-right', class: 'menu_root account-nav' do
      [render_help_top_menu_node,
       render_user_top_menu_node].join.html_safe
    end
  end

  private

  def render_user_top_menu_node(items = menu_items_for(:account_menu))
    if User.current.logged?
      render_user_drop_down items
    elsif omniauth_direct_login?
      render_direct_login
    else
      render_login_drop_down
    end
  end

  def render_login_drop_down
    url = { controller: '/account', action: 'login' }
    link = link_to l(:label_login),
                   url,
                   class: 'login',
                   title: l(:label_login)

    render_menu_dropdown(link, menu_item_class: 'drop-down last-child') do
      render_login_partial
    end
  end

  def render_direct_login
    login = Redmine::MenuManager::MenuItem.new :login,
                                               signin_path,
                                               caption: I18n.t(:label_login),
                                               html: { class: 'login' }

    render_menu_node login
  end

  def render_user_drop_down(items)
    avatar = avatar(User.current)
    render_menu_dropdown_with_items(
      label: avatar.presence || '',
      label_options: {
        title: User.current.name,
        class: (avatar.present? ? '' : 'icon-user')
      },
      items: items,
      options: { drop_down_id: 'user-menu', menu_item_class: 'last-child -hide-icon' }
    )
  end

  def render_login_partial
    partial =
      if OpenProject::Configuration.disable_password_login?
        'account/omniauth_login'
      else
        'account/login'
      end

    render partial: partial
  end

  def render_work_packages_top_menu_node(project, items)
    return nil if items.empty?

    render_menu_dropdown_with_items(
      label: l(:label_work_package_plural),
      label_options: { id: 'work-packages-menu', class: 'icon5 icon-work-packages' },
      items: items,
      project: project,
      options: {
        drop_down_class: 'drop-down--work-packages'
      }
    )
  end

  def render_module_top_menu_node(items)
    return nil if items.empty?

    render_menu_dropdown_with_items(
      label: l(:label_modules),
      label_options: { class: 'icon5 icon-modules' },
      items: items,
      options: { drop_down_id: 'more-menu' }
    )
  end

  def render_main_top_menu_nodes(items)
    items.map { |item|
      render_menu_node(item)
    }.join(' ')
  end

  def help_menu_item
    split_top_menu_into_main_or_more_menus[:help]
  end

  # Split the :top_menu into separate :main, :work_package and :modules items
  def split_top_menu_into_main_or_more_menus(project = nil)
    items = Hash.new { |h, k| h[k] = [] }

    menu_items_for(:top_menu, project) do |item|
      if item.name == :help
        items[:help] = item
      else
        context = item.context || :modules
        items[context] << item
      end
    end

    items
  end
end
