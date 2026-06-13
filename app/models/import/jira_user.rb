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

module Import
  class JiraUser < ApplicationRecord
    self.table_name = "jira_users"

    FALLBACK_NAME_KEY = "admin.jira.user.unknown_name"

    belongs_to :jira, class_name: "Import::Jira"
    belongs_to :jira_import, class_name: "Import::JiraImport"

    def to_op_attributes
      firstname, lastname = split_display_name(payload["displayName"])
      {
        login: payload["name"],
        password: OpenProject::Passwords::Generator.random_password,
        firstname: firstname.presence || I18n.t(FALLBACK_NAME_KEY),
        lastname: lastname.presence || I18n.t(FALLBACK_NAME_KEY),
        mail: payload["emailAddress"],
        status: :locked
      }
    end

    def try_to_find_existing_op_users
      op_attributes = to_op_attributes
      User.by_login(op_attributes[:login]).or(
        User.where("LOWER(mail) = ?", op_attributes[:mail]&.downcase)
      )
    end

    private

    def sanitize_name(name)
      name.gsub(User::INVALID_NAME_REGEX, "").strip
    end

    def split_display_name(display_name)
      parts = sanitize_name(display_name).split
      parts.length > 1 ? [parts[0..-2].join(" "), parts[-1]] : [parts[0], parts[0]]
    end
  end
end
