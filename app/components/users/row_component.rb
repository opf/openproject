# frozen_string_literal: true

#-- copyright
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

      link = helpers.link_to_user(user,
                                  class: "op-principal--name",
                                  name: user.login,
                                  href: helpers.allowed_management_user_profile_path(user))

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

    def consented_at
      helpers.format_time user.consented_at unless user.consented_at.nil?
    end

    def status
      helpers.full_user_status user
    end

    def department
      return if user.department.nil?

      safe_join(
        [
          render(Primer::Beta::Octicon.new(icon: :briefcase, color: :muted, mr: 1)),
          user.department.name
        ]
      )
    end

    def member_of_group
      joined_names user.regular_groups
    end

    def member_of_project
      joined_names user.projects
    end

    def button_links
      [status_link].compact
    end

    def status_link
      return if user_is_current_user?
      return unless current_user_allowed_to_manage_users?
      return if user_is_admin_and_current_user_is_no_admin?

      helpers.change_user_status_links user
    end

    def user_is_current_user?
      user.id == table.current_user.id
    end

    def current_user_allowed_to_manage_users?
      table.current_user.allowed_globally?(:manage_user)
    end

    def user_is_admin_and_current_user_is_no_admin?
      user.admin? && !table.current_user.admin?
    end

    def column_value(column)
      return custom_field_column(column) if custom_field_column?(column)

      attribute = column_attribute(column)

      respond_to?(attribute) ? send(attribute) : user.public_send(attribute)
    end

    def column_css_class(column)
      attribute = column_attribute(column)
      case attribute
      when :mail then "email"
      when :login then "username"
      else attribute.to_s
      end
    end

    private

    def column_attribute(column)
      column.respond_to?(:attribute) ? column.attribute : column
    end

    def joined_names(records)
      records.map(&:name).sort.join(", ")
    end

    def custom_field_column_subject
      user
    end
  end
end
