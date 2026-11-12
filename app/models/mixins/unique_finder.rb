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

module Mixins
  module UniqueFinder
    def self.prepended(model_class)
      unless model_class.respond_to? :unique_attribute
        raise "Missing :unique_attribute accessor on ##{model_class}"
      end

      model_class.singleton_class.prepend ClassMethods
    end

    module ClassMethods
      ##
      # Returns the first model that matches (in this order), either:
      # 1. The given ID
      # 2. The given unique attribute
      def find_by_unique(unique_or_id)
        matches = where(id: unique_or_id).or(where(unique_attribute => unique_or_id)).to_a

        case matches.length
        when 0
          nil
        when 1
          matches.first
        else
          matches.find { |user| user.id.to_s == unique_or_id.to_s }
        end
      end

      ##
      # Returns the first model that matches (in this order), either:
      # 1. The given ID
      # 2. The given unique attribute
      #
      # Raise ActiveRecord::RecordNotFound when no match is found.
      def find_by_unique!(unique_or_id)
        match = find_by_unique(unique_or_id)

        if match.nil?
          raise ActiveRecord::RecordNotFound
        else
          match
        end
      end
    end
  end
end
