# frozen_string_literal: true

# -- copyright
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
# ++

module Groups
  class ShowPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper

    def initialize(group:, current_user:)
      super
      @group = group
      @current_user = current_user
    end

    def breadcrumb_items
      if @current_user.admin?
        admin_breadcrumb_items
      else
        non_admin_breadcrumb_items
      end
    end

    private

    def admin_breadcrumb_items
      items = [{ href: admin_index_path, text: t("label_administration") },
               { href: admin_settings_users_path, text: t(:label_user_and_permission) }]

      items << if @group.organizational_unit?
                 { href: admin_departments_path, text: t(:label_departments) }
               else
                 { href: groups_path, text: t(:label_group_plural) }
               end

      items << @group.name
    end

    def non_admin_breadcrumb_items
      if @group.organizational_unit?
        [t(:label_departments), @group.name]
      else
        [t(:label_group_plural), @group.name]
      end
    end

    def edit_path
      if @group.organizational_unit?
        edit_admin_department_path(@group)
      else
        edit_group_path(@group)
      end
    end

    def edit_label
      if @group.organizational_unit?
        t("departments.edit")
      else
        t(:button_edit)
      end
    end
  end
end
