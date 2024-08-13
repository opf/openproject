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

module PlaceholderUsers
  class EditPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper
    include TabsHelper
    include PlaceholderUsersHelper

    def initialize(placeholder_user:, tabs: nil)
      super
      @placeholder_user = placeholder_user
      @tabs = tabs
    end

    def breadcrumb_items
      [{ href: admin_index_path, text: t("label_administration") },
       { href: admin_settings_users_path, text: t(:label_user_and_permission) },
       { href: placeholder_users_path, text: t(:label_placeholder_user_plural) },
       title]
    end

    def new_record?
      @placeholder_user.new_record?
    end

    def title
      new_record? ? t(:label_placeholder_user_new) : @placeholder_user.name
    end

    def deletable?
      can_delete_placeholder_user?(@placeholder_user)
    end

    def delete_button_href
      if deletable?
        deletion_info_placeholder_user_path(@placeholder_user)
      else
        "#"
      end
    end

    def delete_button_title
      if deletable?
        I18n.t(:button_delete)
      else
        I18n.t("placeholder_users.right_to_manage_members_missing")
      end
    end
  end
end
