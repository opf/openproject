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

# Only return Principals that are visible to the current user.
#
# Either the user has the `manage_members` permission in any project,
# or all principals in visible projects are returned.
module Principals::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      def visible(user = ::User.current)
        if user.allowed_in_any_project?(:manage_members) ||
          user.allowed_globally?(:manage_user) ||
          user.allowed_in_any_project?(:share_work_packages)
          all
        else
          in_visible_project_or_me(user)
        end
      end
    end
  end
end
