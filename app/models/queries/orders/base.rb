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

module Queries
  module Orders
    class Base
      include ActiveModel::Validations

      VALID_DIRECTIONS = %i(asc desc).freeze

      def self.i18n_scope
        :activerecord
      end

      validates :direction, inclusion: { in: VALID_DIRECTIONS }

      class_attribute :model
      attr_accessor :direction,
                    :attribute

      def initialize(attribute)
        self.attribute = attribute
      end

      def self.key
        raise NotImplementedError
      end

      def apply_to(query_scope)
        query_scope = order(query_scope)
        query_scope = query_scope.joins(joins) if joins
        query_scope = query_scope.left_outer_joins(left_outer_joins) if left_outer_joins
        query_scope
      end

      def name
        attribute
      end

      def available?
        true
      end

      private

      def order(scope)
        scope.order(name => direction)
      end

      def joins
        nil
      end

      def left_outer_joins
        nil
      end

      def with_raise_on_invalid
        if VALID_DIRECTIONS.include?(direction)
          yield
        else
          raise ArgumentError, "Only one of #{VALID_DIRECTIONS} allowed. #{direction} is provided."
        end
      end
    end
  end
end
