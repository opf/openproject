#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

module PlaceholderUsers
  class RowComponent < ::RowComponent
    def placeholder_user
      model
    end

    def name
      link_to h(placeholder_user.name), edit_placeholder_user_path(placeholder_user)
    end

    def created_at
      helpers.format_time placeholder_user.created_at
    end

    def button_links
      [delete_link].compact
    end

    def delete_link
      if helpers.can_delete_placeholder_user?(placeholder_user, User.current)
        link_to deletion_info_placeholder_user_path(placeholder_user) do
          helpers.tooltip_tag I18n.t('placeholder_users.delete_tooltip'), icon: 'icon-delete'
        end
      else
        helpers.tooltip_tag I18n.t('placeholder_users.right_to_manage_members_missing'), icon: 'icon-help2'
      end
    end

    def row_css_class
      "placeholder_user"
    end
  end
end
