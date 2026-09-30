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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Groups::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      ##
      # Returns the groups visible to the given user.
      # which is either all groups (if the user has the `view_all_principals` permission)
      # or the following conditions:
      # - groups that are members of a project the user can view members of
      # - groups that the user themselves is a member of
      def visible(user = User.current)
        if user.allowed_globally?(:view_all_principals)
          all
        else
          where(
            Group.arel_table[:id].in(
              Arel::Nodes::UnionAll.new(
                Group.unscoped.containing_user(user).select(:id).arel,
                Group.unscoped.in_visible_project(user).select(:id).arel
              )
            )
          )
        end
      end
    end
  end
end
