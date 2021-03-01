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

module Redmine::MenuManager::TopMenu::QuickAddMenu
  def render_quick_add_menu
    content_tag :ul, class: 'menu_root account-nav quick-add-menu' do
      render_quick_add_dropdown
    end
  end

  private

  def render_quick_add_dropdown
    render_menu_dropdown_with_items(
      label: '',
      label_options: {
        title: I18n.t('menus.quick_add.label'),
        icon: ('icon-plus')
      },
      items: first_level_menu_items_for(:quick_add_menu),
      options: { drop_down_id: 'quick-add-menu' }
    )
  end
end
