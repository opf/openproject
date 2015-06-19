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
  def render_top_menu_left
    content_tag :ul, id: 'account-nav-left', class: 'menu_root account-nav' do
      [render_main_top_menu_nodes,
       render_projects_top_menu_node,
       render_module_top_menu_node].join.html_safe
    end
  end

  def render_top_menu_right
    content_tag :ul, id: 'account-nav-right', class: 'menu_root account-nav' do
      [render_help_top_menu_node,
       render_user_top_menu_node].join.html_safe
    end
  end

  private

  def render_projects_top_menu_node
    return '' if User.current.anonymous? and Setting.login_required?

    return '' if User.current.anonymous? and User.current.number_of_known_projects.zero?

    heading = link_to l(:label_project_plural),
                      { controller: '/projects',
                        action: 'index' },
                      title: l(:label_project_plural),
                      accesskey: OpenProject::AccessKeys.key_for(:project_search),
                      class: 'icon5 icon-unit'

    if User.current.impaired?
      content_tag :li do
        heading
      end
    else
      render_drop_down_menu_node heading do
        content_tag :ul, style: 'display:none' do
          ret = content_tag :li do
            link_to l(:label_project_view_all), { controller: '/projects',
                                                  action: 'index' },
                    class: 'icon4 icon-list-view2'
          end

          ret += content_tag :li, id: 'project-search-container' do
            hidden_field_tag('', '', class: 'select2-select')
          end

          ret
        end
      end
    end
  end

  def render_user_top_menu_node(items = menu_items_for(:account_menu))
    if User.current.logged?
      render_user_drop_down items
    elsif Concerns::OmniauthLogin.direct_login?
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

    render_drop_down_menu_node(link, class: 'drop-down last-child') do
      content_tag :ul do
        render_login_partial
      end
    end
  end

  def render_direct_login
    login = Redmine::MenuManager::MenuItem.new :login,
                                               '/login',
                                               caption: I18n.t(:label_login),
                                               html: { class: 'login' }

    render_menu_node login
  end

  def render_user_drop_down(items)
    render_drop_down_menu_node link_to_user(User.current, title: User.current.to_s),
                               items,
                               class: 'drop-down last-child'
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

  def render_module_top_menu_node(items = more_top_menu_items)
    render_drop_down_menu_node link_to(l(:label_modules), '#', title: l(:label_modules), class: 'icon5 icon-version'),
                               items,
                               id: 'more-menu'
  end

  def render_help_top_menu_node(item = help_menu_item)
    render_menu_node(item)
  end

  def render_main_top_menu_nodes(items = main_top_menu_items)
    items.map do |item|
      render_menu_node(item)
    end.join(' ')
  end

  # Menu items for the main top menu
  def main_top_menu_items
    split_top_menu_into_main_or_more_menus[:main]
  end

  # Menu items for the more top menu
  def more_top_menu_items
    split_top_menu_into_main_or_more_menus[:more]
  end

  def help_menu_item
    split_top_menu_into_main_or_more_menus[:help]
  end

  # Split the :top_menu into separate :main and :more items
  def split_top_menu_into_main_or_more_menus
    unless @top_menu_split
      items_for_main_level = []
      items_for_more_level = []
      help_menu = nil
      menu_items_for(:top_menu) do |item|
        if item.name == :my_page
          items_for_main_level << item
        elsif item.name == :help
          help_menu = item
        elsif item.name == :projects
          # Remove, present in layout
        else
          items_for_more_level << item
        end
      end
      @top_menu_split = {
        main: items_for_main_level,
        more: items_for_more_level,
        help: help_menu
      }
    end
    @top_menu_split
  end
end
