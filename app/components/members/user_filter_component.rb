# frozen_string_literal: true

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
  class UserFilterComponent < ::UserFilterComponent
    def initially_visible?
      false
    end

    def has_close_icon?
      true
    end

    ##
    # Adapts the user filter counts to count members as opposed to users.
    def extra_user_status_options
      {
        all: status_members_query('all').count,
        blocked: status_members_query('blocked').count,
        active: status_members_query('active').count,
        invited: status_members_query('invited').count,
        registered: status_members_query('registered').count,
        locked: status_members_query('locked').count
      }
    end

    def status_members_query(status)
      params = { project_id: project.id,
                 status: }

      self.class.filter(params)
    end

    def filter_path
      project_members_path(project)
    end

    def self.base_query
      Queries::Members::MemberQuery
    end
  end
end
