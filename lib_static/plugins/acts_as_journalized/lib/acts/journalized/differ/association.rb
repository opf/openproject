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

module Acts::Journalized::Differ
  class Association
    # @param original [ActiveRecord::Base] the original object containing the association.
    # @param changed [ActiveRecord::Base] the changed object containing the association.
    # @param association [Symbol] the name of the association to be compared.
    # @param id_attribute [Symbol] the attribute used to correlate association models.
    # @param multiple_values [Boolean, :joined] whether there are multiple values per id_attribute:
    #        * when false - changes between first attribute values will be returned
    #        * when true - changes between sorted arrays of attribute values will be returned
    #        * when :joined - changes between sorted arrays will be joined with comma
    def initialize(original, changed, association:, id_attribute:, multiple_values: false)
      @original_by_id = association_by_id(original, association, id_attribute)
      @changed_by_id = association_by_id(changed, association, id_attribute)
      @ids = (@changed_by_id.keys | @original_by_id.keys).compact
      @multiple_values = multiple_values
    end

    # Generates a hash of changes for a single attribute, with keys prefixed by a given string.
    #
    # @param attribute [Symbol] the attribute for which to return changes.
    # @param key_prefix [String] the prefix to add to each key in the resulting hash.
    # @return [Hash] a hash with key consisting of prefix and id, and value being two element array with changes.
    def single_attribute_changes(attribute, key_prefix:)
      attribute_changes(attribute)
        .transform_keys { |id| "#{key_prefix}_#{id}" }
    end

    # Generates a hash of changes for multiple attributes, with keys prefixed by a given string.
    #
    # @param attributes [Array<Symbol>] the list of attributes for which to return changes.
    # @param key_prefix [String] the prefix to add to each key in the resulting hash.
    # @return [Hash] when not grouped, a hash with key consisting of prefix, id and attribute name, and value being two
    #         element array with changes. When grouped, a hash with key consisting of prefix and id, and value being
    #         a hash with keys being attributes names and values being two element array with changes.
    def multiple_attributes_changes(attributes, key_prefix:)
      attributes.each_with_object({}) do |attribute, result|
        attribute_changes(attribute).each do |id, change|
          result["#{key_prefix}_#{id}_#{attribute}"] = change
        end
      end
    end

    private

    def association_by_id(model, association, id_attribute)
      return {} unless model

      relation = if association.respond_to?(:call)
                   association.call(model)
                 else
                   model.send(association)
                 end

      relation.group_by(&id_attribute.to_sym)
    end

    def attribute_changes(attribute)
      attribute = attribute.to_sym

      pairs = @ids.index_with do |id|
        [
          combine_journals(@original_by_id[id], attribute),
          combine_journals(@changed_by_id[id], attribute)
        ]
      end

      pairs.reject { |_, (old_value, new_value)| old_value.to_s.strip == new_value.to_s.strip }
    end

    def combine_journals(journals, attribute)
      return unless journals

      if @multiple_values
        values = journals.map(&attribute).sort

        if @multiple_values == :joined
          values.join(",")
        else
          values.excluding(nil, "").presence
        end
      else
        value = journals.first.send(attribute)

        value unless value == ""
      end
    end
  end
end
