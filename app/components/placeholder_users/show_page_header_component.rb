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
  class ShowPageHeaderComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include ApplicationHelper
    include PlaceholderUsersHelper
    include AvatarHelper

    def initialize(placeholder_user:, current_user:)
      super
      @placeholder_user = placeholder_user
      @current_user = current_user
    end

    def breadcrumb_items
      [
        { href: placeholder_user_path, text: t(:label_placeholder_user_plural) },
        @placeholder_user.name
      ]
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
