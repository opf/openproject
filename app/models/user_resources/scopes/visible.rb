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

# Only return user resources that are visible to the current user.
#
# Unlike other principals these are a global catalogue and never project
# members, so the membership-based rules of `Principals::Scopes::Visible` can
# never match. Visibility hangs off the resource planner instead: anyone who
# may look at a planner has to be able to read the names of the resources its
# allocations ask for.
module UserResources::Scopes
  module Visible
    extend ActiveSupport::Concern

    class_methods do
      def visible(user = User.current)
        if user.allowed_globally?(:view_all_principals) ||
           user.allowed_in_any_project?(:view_resource_planners)
          all
        else
          none
        end
      end
    end
  end
end
