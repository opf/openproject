# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

module Acts::Journalized
  class JournableDiffer
    class << self
      def changes(original, changed)
        original_data = normalize_newlines(journaled_attributes(original))

        normalize_newlines(journaled_attributes(changed))
          .select { |attribute, new_value| no_nil_to_empty_strings?(original_data, attribute, new_value) }
          .to_h { |attribute, new_value| [attribute, [original_data[attribute], new_value]] }
          .with_indifferent_access
      end

      private

      def normalize_newlines(data)
        data.each_with_object({}) do |e, h|
          h[e[0]] = (e[1].is_a?(String) ? e[1].gsub(/\r\n/, "\n") : e[1])
        end
      end

      def no_nil_to_empty_strings?(normalized_old_data, attribute, new_value)
        old_value = normalized_old_data[attribute]
        new_value != old_value && (new_value.present? || old_value.present?)
      end

      def journaled_attributes(object)
        if object.is_a?(Journal::BaseJournal)
          object.journaled_attributes.stringify_keys
        else
          object.attributes.slice(*object.class.journal_class.journaled_attributes.map(&:to_s))
        end
      end
    end
  end
end
