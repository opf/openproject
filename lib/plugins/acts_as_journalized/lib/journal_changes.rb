#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module JournalChanges
  def get_changes
    return @changes if @changes
    return {} if data.nil?

    @changes = if predecessor.nil?
                 initial_journal_data_changes
               else
                 subsequent_journal_data_changes
               end

    @changes.merge!(get_association_changes(predecessor, 'attachable', 'attachments', :attachment_id, :filename))
    @changes.merge!(get_association_changes(predecessor, 'customizable', 'custom_fields', :custom_field_id, :value))
  end

  private

  def initial_journal_data_changes
    data
     .journaled_attributes
     .reject { |_, new_value| new_value.nil? }
     .inject({}) do |result, (attribute, new_value)|
      result[attribute] = [nil, new_value]
      result
    end
  end

  def subsequent_journal_data_changes
    normalized_new_data = normalize_newlines(data.journaled_attributes)
    normalized_old_data = normalize_newlines(predecessor.data.journaled_attributes)

    normalized_new_data
      .select { |attribute, new_value| no_nil_to_empty_strings?(normalized_old_data, attribute, new_value) }
      .map { |attribute, new_value| [attribute, [normalized_old_data[attribute], new_value]] }
      .to_h
      .with_indifferent_access
  end

  def get_association_changes(predecessor, journal_association, association, key, value)
    journal_assoc_name = "#{journal_association}_journals"

    if predecessor.nil?
      send(journal_assoc_name).each_with_object({}) do |associated_journal, h|
        changed_attribute = "#{association}_#{associated_journal.send(key)}"
        new_value = associated_journal.send(value)
        h[changed_attribute] = [nil, new_value]
      end
    else
      new_journals = send(journal_assoc_name).map(&:attributes)
      old_journals = predecessor.send(journal_assoc_name).map(&:attributes)

      changes_on_association(new_journals, old_journals, association, key, value)
    end
  end

  def changes_on_association(current, predecessor, association, key, value)
    merged_journals = merge_reference_journals_by_id(current, predecessor, key.to_s, value.to_s)

    changes = added_references(merged_journals)
                .merge(removed_references(merged_journals))
                .merge(changed_references(merged_journals))

    to_changes_format(changes, association.to_s)
  end

  def added_references(merged_references)
    merged_references
      .select { |_, (old_value, new_value)| old_value.nil? && new_value.present? }
  end

  def removed_references(merged_references)
    merged_references
      .select { |_, (old_value, new_value)| old_value.present? && new_value.nil? }
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
    all_associated_journal_ids = new_journals.map { |j| j[id_key] } | old_journals.map { |j| j[id_key] }

    all_associated_journal_ids.each_with_object({}) do |id, result|
      result[id] = [select_and_combine_journals(old_journals, id, id_key, value),
                    select_and_combine_journals(new_journals, id, id_key, value)]
    end
  end

  def select_and_combine_journals(journals, id, key, value)
    selected_journals = journals.select { |j| j[key] == id }.map { |j| j[value] }

    if selected_journals.empty?
      nil
    else
      selected_journals.sort.join(',')
    end
  end

  def normalize_newlines(data)
    data.each_with_object({}) do |e, h|
      h[e[0]] = (e[1].is_a?(String) ? e[1].gsub(/\r\n/, "\n") : e[1])
    end
  end

  def no_nil_to_empty_strings?(normalized_old_data, attribute, new_value)
    old_value = normalized_old_data[attribute]
    new_value != old_value && (new_value.present? || old_value.present?)
  end
end
