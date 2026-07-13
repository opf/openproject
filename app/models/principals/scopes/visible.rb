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

# Only return Principals that are visible to the current user.
#
# - Users with the global permission `view_all_principals` can see all Principals.
# - Admins can see all Principals.
# - Other users can see Principals if:
#   - they are a member of the same project as the Principal, or
#   - they are the same user, or
#   - they share a group with the Principal.
module Principals::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      def visible(user = ::User.current)
        if user.allowed_globally?(:view_all_principals)
          all
        else
          in_visible_project_or_me_or_same_groups(user)
        end
      end
    end
  end
end
