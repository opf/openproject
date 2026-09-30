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
  module Model
    class << self
      def changes(original, changed)
        original_data = original ? normalize_newlines(journaled_attributes(original)) : {}

        normalize_newlines(journaled_attributes(changed))
          .to_h { |attribute, new_value| [attribute, [original_data[attribute], new_value]] }
          .reject { |_, (old_value, new_value)| equal_ignoring_empty_string?(old_value, new_value) }
          .with_indifferent_access
      end

      private

      def journaled_attributes(object)
        if object.is_a?(Journal::BaseJournal)
          object.journaled_attributes.stringify_keys
        else
          object.attributes.slice(*object.class.journal_class.journaled_attributes.map(&:to_s))
        end
      end

      def normalize_newlines(data)
        data.transform_values do |value|
          value.is_a?(String) ? value.gsub("\r\n", "\n") : value
        end
      end

      def equal_ignoring_empty_string?(old_value, new_value)
        ignoring_empty_string(old_value) == ignoring_empty_string(new_value)
      end

      def ignoring_empty_string(value)
        value unless value == ""
      end
    end
  end
end
