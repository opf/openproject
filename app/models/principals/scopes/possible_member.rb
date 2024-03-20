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

module Principals::Scopes
  module PossibleMember
    extend ActiveSupport::Concern

    class_methods do
      # Returns principals eligible to become project members. Those principals can be of class
      # * User
      # * PlaceholderUser
      # * Group
      # User instances need to be non locked (status)
      # Principals which already are project members are are returned.
      # @project [Project] The project for which eligible candidates are to be searched
      # @return [ActiveRecord::Relation] A scope of eligible candidates
      def possible_member(project)
        Queries::Principals::PrincipalQuery
          .new(user: ::User.current)
          .where(:member, '!', [project.id])
          .where(:status, '!', [statuses[:locked]])
          .results
      end
    end
  end
end
