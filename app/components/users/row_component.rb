# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Users
  class RowComponent < ::RowComponent
    property :firstname, :lastname

    def user
      model
    end

    def row_css_class
      status = user.status
      blocked = "blocked" if user.failed_too_many_recent_login_attempts?

      ["user", status, blocked].compact.join(" ")
    end

    def login
      icon = helpers.avatar user, size: :mini

      link = link_to h(user.login), helpers.allowed_management_user_profile_path(user)

      icon + link
    end

    def mail
      mail_to user.mail
    end

    def admin
      helpers.checked_image user.admin?
    end

    def last_login_on
      helpers.format_time user.last_login_on unless user.last_login_on.nil?
    end

    def created_at
      helpers.format_time user.created_at
    end

    def status
      helpers.full_user_status user
    end

    def button_links
      [status_link].compact
    end

    def status_link
      # Don't show for current user
      return if user.id == table.current_user.id

      # Don't show if non-admin
      return unless table.current_user.admin?

      helpers.change_user_status_links user
    end

    def column_css_class(column)
      if column == :mail
        "email"
      elsif column == :login
        "username"
      else
        super
      end
    end
  end
end
