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

class FormConfiguration
  class CustomFieldPlacement
    OTHER_GROUP = :other

    def initialize(groups, custom_field_ids)
      @groups = groups
      @keys = custom_field_ids.map { |id| "#{TypeVariant::ConfigurationLinkable::CUSTOM_FIELD_ELEMENT_PREFIX}#{id}" }
    end

    def groups
      placed = []
      tuples = @groups.map do |group|
        next tuple_of(group, group.attributes) if group.is_a?(Type::QueryGroup)

        attributes = group.attributes.select { |key| keep?(key.to_s) }
        placed.concat(attributes.map(&:to_s))
        tuple_of(group, attributes)
      end

      with_missing(tuples, @keys - placed)
    end

    private

    def keep?(key) = !CustomField.custom_field_attribute?(key) || @keys.include?(key)

    def tuple_of(group, attributes) = [group.key, attributes, group.display_name, group.record_id]

    def with_missing(tuples, missing)
      return tuples if missing.empty?

      other = tuples.find { |key, attributes, *| key == OTHER_GROUP && !attributes.first.is_a?(Query) }
      return tuples + [[OTHER_GROUP, missing]] if other.nil?

      other[1] = other[1] + missing
      tuples
    end
  end
end
