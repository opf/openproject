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
  module OrderedByName
    extend ActiveSupport::Concern

    class_methods do
      # Returns principals sorted by the name format defined by
      # +Setting.name_format+
      #
      # @desc [Boolean] Whether the sortation should be reversed
      # @return [ActiveRecord::Relation] A scope of sorted principals
      def ordered_by_name(desc: false)
        direction = desc ? 'DESC' : 'ASC'

        order_case = Arel.sql <<~SQL
          CASE
          WHEN users.type = 'User' THEN LOWER(#{user_concat_sql})
          WHEN users.type != 'User' THEN LOWER(users.lastname)
          END #{direction}
        SQL

        order order_case
      end

      private

      def user_concat_sql
        case Setting.user_format
        when :firstname_lastname
          "concat_ws(' ', users.firstname, users.lastname)"
        when :firstname
          'users.firstname'
        when :lastname_firstname, :lastname_coma_firstname, :lastname_n_firstname
          "concat_ws(' ', users.lastname, users.firstname)"
        when :username
          "users.login"
        else
          raise ArgumentError, "Invalid user format"
        end
      end
    end
  end
end
