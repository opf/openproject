#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Redmine::MenuManager::TopMenuHelper
  include Redmine::MenuManager::TopMenu::HelpMenu
  include Redmine::MenuManager::TopMenu::ProjectsMenu
  include Redmine::MenuManager::TopMenu::QuickAddMenu

  def render_top_menu_left
    content_tag :ul, id: 'account-nav-left', class: 'menu_root account-nav top-menu' do
      [render_main_top_menu_nodes,
       render_projects_top_menu_node].join.html_safe
    end
  end

  def render_top_menu_right
    content_tag :ul, id: 'account-nav-right', class: 'menu_root account-nav top-menu-right' do
      [render_module_top_menu_node,
       render_help_top_menu_node,
       render_user_top_menu_node].join.html_safe
    end
  end

  private

  def render_user_top_menu_node(items = first_level_menu_items_for(:account_menu))
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
    link = link_to url,
                   class: 'login',
                   title: I18n.t(:label_login) do
      concat('<span class="button--dropdown-text hidden-for-mobile">'.concat(I18n.t(:label_login)).concat('</span>').html_safe)
      concat('<i class="button--dropdown-indicator hidden-for-mobile"></i>'.html_safe)
      concat('<i class="icon2 icon-user hidden-for-desktop"></i>'.html_safe)
    end

    render_menu_dropdown(link, menu_item_class: 'drop-down last-child top-menu--login') do
      render_login_partial
    end
  end

  def render_direct_login
    link = link_to signin_path,
                   class: 'login',
                   title: I18n.t(:label_login) do
      concat('<span class="button--dropdown-text hidden-for-mobile">'.concat(I18n.t(:label_login)).concat('</span>').html_safe)
      concat('<i class="icon2 icon-user hidden-for-desktop"></i>'.html_safe)
    end

    content_tag :li, class: "last-child top-menu--login" do
      concat link
    end
  end

  def render_user_drop_down(items)
    avatar = avatar(User.current)
    render_menu_dropdown_with_items(
      label: avatar.presence || '',
      label_options: {
        title: User.current.name,
        icon: (avatar.present? ? 'overridden-by-avatar' : 'icon-user')
      },
      items: items,
      options: { drop_down_id: 'user-menu', menu_item_class: 'last-child' }
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

  def render_module_top_menu_node(items = more_top_menu_items)
    unless items.empty?
      render_menu_dropdown_with_items(
        label: '',
        label_options: { icon: 'icon-menu', title: I18n.t('label_modules') },
        items: items,
        options: { drop_down_id: 'more-menu', drop_down_class: 'drop-down--modules ' }
      )
    end
  end

  def render_main_top_menu_nodes(items = main_top_menu_items)
    items.map do |item|
      render_menu_node(item)
    end.join(' ')
  end

  # Menu items for the main top menu
  def main_top_menu_items
    split_top_menu_into_main_or_more_menus[:base]
  end

  # Menu items for the modules top menu
  def more_top_menu_items
    split_top_menu_into_main_or_more_menus[:modules]
  end

  def project_menu_items
    split_top_menu_into_main_or_more_menus[:projects]
  end

  def help_menu_item
    split_top_menu_into_main_or_more_menus[:help]
  end

  # Split the :top_menu into separate :main and :modules items
  def split_top_menu_into_main_or_more_menus
    @top_menu_split ||= begin
      items = Hash.new { |h, k| h[k] = [] }
      first_level_menu_items_for(:top_menu) do |item|
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
end
