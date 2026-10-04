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
      # @param [Project] project The project for which eligible candidates are to be searched
      # @param [String|nil] type The type of principals to be returned. One of 'User', 'Group', 'PlaceholderUser'.
      # @return [ActiveRecord::Relation] A scope of eligible candidates
      def possible_member(project, type: nil)
        query = Queries::Principals::PrincipalQuery
          .new(user: ::User.current)
          .where(:member, "!", [project.id])
          .where(:status, "!", [statuses[:locked]])

        query.where(:type, "=", [type]) if type.present?

        query.results
      end
    end
  end
end
