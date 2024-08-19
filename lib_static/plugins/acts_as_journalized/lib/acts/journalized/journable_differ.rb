# -- copyright
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
# ++

module Acts::Journalized
  class JournableDiffer
    class << self
      def changes(original, changed)
        original_data = original ? normalize_newlines(journaled_attributes(original)) : {}

        normalize_newlines(journaled_attributes(changed))
          .select { |attribute, new_value| no_nil_to_empty_strings?(original_data, attribute, new_value) }
          .to_h { |attribute, new_value| [attribute, [original_data[attribute], new_value]] }
          .with_indifferent_access
      end

      def association_changes(original, changed, *)
        get_association_changes(original, changed, *)
      end

      def association_changes_multiple_attributes(original, changed, association, association_name, key, values)
        list = {}
        values.each do |value|
          list.store(value, get_association_changes(original, changed, association, association_name, key, value))
        end

        transformed = {}
        list.each do |key, value|
          value.each do |agenda_item, data|
            transformed["#{agenda_item}_#{key}"] ||= {}
            transformed["#{agenda_item}_#{key}"] = data
          end
        end

        transformed
      end

      private

      def normalize_newlines(data)
        data.each_with_object({}) do |e, h|
          h[e[0]] = (e[1].is_a?(String) ? e[1].gsub("\r\n", "\n") : e[1])
        end
      end

      def no_nil_to_empty_strings?(normalized_old_data, attribute, new_value)
        old_value = normalized_old_data[attribute]
        new_value != old_value && ([new_value, old_value] - ["", nil]).present?
      end

      def journaled_attributes(object)
        if object.is_a?(Journal::BaseJournal)
          object.journaled_attributes.stringify_keys
        else
          object.attributes.slice(*object.class.journal_class.journaled_attributes.map(&:to_s))
        end
      end

      def get_association_changes(original, changed, association, association_name, key, value)
        new_journals = changed.send(association).map(&:attributes)
        old_journals = original&.send(association)&.map(&:attributes) || []

        changes_on_association(new_journals, old_journals, association_name, key, value)
      end

      def changes_on_association(current, original, association_name, key, value)
        merged_journals = merge_reference_journals_by_id(current, original, key.to_s, value.to_s)

        changes = added_references(merged_journals)
                    .merge(removed_references(merged_journals))
                    .merge(changed_references(merged_journals))

        to_changes_format(changes, association_name.to_s)
      end

      def added_references(merged_references)
        merged_references
          .select { |_, (old_value, new_value)| old_value.to_s.empty? && new_value.present? }
      end

      def removed_references(merged_references)
        merged_references
          .select { |_, (old_value, new_value)| old_value.present? && new_value.to_s.empty? }
      end

      def changed_references(merged_references)
        merged_references
          .select { |_, (old_value, new_value)| old_value.present? && new_value.present? && old_value.strip != new_value.strip }
      end

      def to_changes_format(references, key)
        references.each_with_object({}) do |(id, (old_value, new_value)), result|
          result["#{key}_#{id}"] = [old_value, new_value]
        end
      end

      def merge_reference_journals_by_id(new_journals, old_journals, id_key, value)
        all_associated_journal_ids = (new_journals.pluck(id_key) | old_journals.pluck(id_key)).compact

        all_associated_journal_ids.index_with do |id|
          [select_and_combine_journals(old_journals, id, id_key, value),
           select_and_combine_journals(new_journals, id, id_key, value)]
        end
      end

      def select_and_combine_journals(journals, id, key, value)
        selected_journals = journals.select { |j| j[key] == id }.pluck(value)

        if selected_journals.empty?
          nil
        else
          selected_journals.sort.join(",")
        end
      end
    end
  end
end
