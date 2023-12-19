#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
module Members
  class MenusController < ApplicationController
    def show
      @sidebar_menu_items = first_level_menu_items + nested_menu_items
      render layout: nil
    end

    def first_level_menu_items
      [{
        header: nil,
        children: [
          { title: I18n.t('members.menu.all'), href: '' }, # TODO
          { title: I18n.t('members.menu.locked'), href: '' }, # TODO
          { title: I18n.t('members.menu.invited'), href: '' } # TODO
        ]
      }]
    end

    def nested_menu_items
      [{ header: I18n.t('members.menu.project_roles'), children: project_roles_entries },
       { header: I18n.t('members.menu.wp_shares'), children: permission_menu_entries },
       { header: I18n.t('members.menu.groups'), children: project_group_entries }]
    end

    private

    def project_roles_entries
      # todo
      [{ title: 'ROLE X', href: '' }]
    end

    def permission_menu_entries
      # todo
      [
        { title: I18n.t('work_package.sharing.permissions.view'), href: '' },
        { title: I18n.t('work_package.sharing.permissions.comment'), href: '' },
        { title: I18n.t('work_package.sharing.permissions.edit'), href: '' }
      ]
    end

    def project_group_entries
      # todo
      [{ title: 'GROUP X', href: '' }]
    end
  end
end
