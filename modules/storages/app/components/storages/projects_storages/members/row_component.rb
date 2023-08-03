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

# Purpose: Defines how to format the components within a table row of ProjectStorages
# associated with a project
module Storages::ProjectsStorages::Members
  class RowComponent < ::RowComponent
    property :principal,
             :created_at

    def member
      row
    end

    def row_css_id
      "member-#{member.id}"
    end

    def row_css_class
      "member #{principal_class_name}".strip
    end

    def name
      icon = helpers.avatar principal, size: :mini

      icon + principal_link
    end

    def status
      # FIXME: Status based on Nextcloud OAuth Client Token Presence
      'Connected'
    end

    private

    def principal_link
      link_to principal.name, principal_show_path
    end

    def principal_class_name
      principal.model_name.singular
    end

    def principal_show_path
      case principal
      when User
        user_path(principal)
      when Group
        show_group_path(principal)
      else
        placeholder_user_path(principal)
      end
    end
  end
end
