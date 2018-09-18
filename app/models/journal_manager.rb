#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

class JournalManager
  class << self
    attr_accessor :send_notification

    def changes_on_association(current, predecessor, association, key, value)
      merged_journals = merge_reference_journals_by_id(current, predecessor, key.to_s, value.to_s)

      changes = added_references(merged_journals)
                .merge(removed_references(merged_journals))
                .merge(changed_references(merged_journals))

      to_changes_format(changes, association.to_s)
    end

    def reset_notification
      @send_notification = true
    end

    private

    def merge_reference_journals_by_id(new_journals, old_journals, id_key, value)
      all_associated_journal_ids = new_journals.map { |j| j[id_key] } | old_journals.map { |j| j[id_key] }

      all_associated_journal_ids.each_with_object({}) do |id, result|
        result[id] = [select_and_combine(old_journals, id, id_key, value),
                      select_and_combine(new_journals, id, id_key, value)]
      end
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
        .select { |_, (old_value, new_value)| old_value.present? && new_value.present? && old_value != new_value }
    end

    def to_changes_format(references, key)
      references.each_with_object({}) do |(id, (old_value, new_value)), result|
        result["#{key}_#{id}"] = [old_value, new_value]
      end
    end

    def journable_details(journable)
      calculated_proc = journable.class.vestal_journals_options[:calculate]

      attributes = journable.attributes.symbolize_keys

      if calculated_proc
        attributes
          .merge!(journable.instance_exec(&calculated_proc))
      end

      attributes
    end

    def journal_class_name(type)
      "#{base_class(type).name}Journal"
    end

    def base_class(type)
      type.base_class
    end

    def create_association_data(journable, journal)
      create_attachment_data journable, journal if journable.respond_to? :attachments
      create_custom_field_data journable, journal if journable.respond_to? :custom_values
    end

    def create_attachment_data(journable, journal)
      journable.attachments.each do |a|
        journal.attachable_journals.build attachment: a, filename: a.filename
      end
    end

    def create_custom_field_data(journable, journal)
      journable.custom_values.group_by(&:custom_field).each do |custom_field, custom_values|
        # Consider only custom values with non-blank values. Otherwise,
        # non-existing custom values are different to custom values with an empty
        # value.
        # Mind that false.present? == false, but we don't consider false this being "blank"...
        # This does not matter when we use stringly typed values (as in the database),
        # but it matters when we use real types
        valid_values = custom_values.select { |cv| cv.value.present? || cv.value == false }

        if custom_field.multi_value? && valid_values.any?
          build_multi_value_custom_field_journal! journal, custom_field, valid_values
        elsif valid_values.any?
          build_custom_field_journal! journal, custom_field, valid_values.first
        end
      end
    end

    def build_multi_value_custom_field_journal!(journal, custom_field, custom_values)
      value = custom_values.map(&:value).join(",") # comma separated custom option IDs

      journal.customizable_journals.build custom_field_id: custom_field.id, value: value
    end

    def build_custom_field_journal!(journal, custom_field, custom_value)
      journal.customizable_journals.build custom_field_id: custom_field.id, value: custom_value.value
    end

    def select_and_combine(journals, id, key, value)
      selected_journals = journals.select { |j| j[key] == id }.map { |j| j[value] }

      if selected_journals.empty?
        nil
      else
        selected_journals.join(',')
      end
    end
  end

  self.send_notification = true

  def self.journalized?(obj)
    not obj.nil? and obj.respond_to? :journals
  end

  def self.changed?(journable)
    if (journable.journals.loaded? ? journable.journals.size : journable.journals.count) > 0
      changed = attributes_changed? journable
      changed ||= association_changed? journable, 'attachable', :attachments, :id, :attachment_id, :filename
      changed ||= association_changed? journable, 'customizable', :custom_values, :custom_field_id, :custom_field_id, :value

      changed
    else
      true
    end
  end

  def self.attributes_changed?(journable)
    type = base_class(journable.class)
    current = valid_journal_attributes type, journable.attributes
    predecessor = journable.journals.last.data.journaled_attributes

    current = normalize_newlines(current)
    predecessor = normalize_newlines(predecessor)

    # we generally ignore changes from blank to blank
    predecessor
      .any? { |k, v| current[k.to_s] != v && (v.present? || current[k.to_s].present?) }
  end

  def self.association_changed?(journable, journal_association, association, id, key, value)
    if journable.respond_to? association
      journal_assoc_name = "#{journal_association}_journals"
      current = journable.send(association).map { |a| { key.to_s => a.send(id), value.to_s => a.send(value) } }
      predecessor = journable.journals.last.send(journal_assoc_name).map(&:attributes)

      current = remove_empty_associations(current, value.to_s)

      changes = JournalManager.changes_on_association(current, predecessor, association, key, value)

      !changes.empty?
    else
      false
    end
  end

  # associations have value attributes ('value' for custom values and 'filename'
  # for attachments). This method ensures that blank value attributes are
  # treated like non-existing associations. Thus, this prevents that
  # non-existing associations (nil) are different to blank associations ("").
  # This would lead to false change information, otherwise.
  # We need to be careful though, because we want to accept false (and false.blank? == true)
  def self.remove_empty_associations(associations, value)
    associations.reject do |association|
      association.has_key?(value) &&
        association[value].blank? &&
        association[value] != false
    end
  end

  def self.recreate_initial_journal(type, journal, changed_data)
    if journal.data.nil?
      journal.data = create_journal_data journal.id, type, changed_data.except(:id)
    else
      journal.changed_data = changed_data
      journal.attachable_journals.delete_all
      journal.customizable_journals.delete_all
    end

    create_association_data journal.journable, journal

    journal.save!
    journal.reload
  end

  def self.add_journal!(journable, user = User.current, notes = '')
    if journalized? journable
      # Obtain a table lock to ensure consistent version numbers
      Journal.with_write_lock do
        # Maximum version might be nil, so use to_i here.
        version = journable.journals.maximum(:version).to_i + 1

        journal_attributes = { journable_id: journable.id,
                               journable_type: journal_class_name(journable.class),
                               version: version,
                               activity_type: journable.send(:activity_type),
                               details: journable_details(journable) }

        journal = create_journal journable, journal_attributes, user, notes

        # FIXME: this is required for the association to be correctly saved...
        journable.journals.select(&:new_record?)

        journal.save!
        journal
      end
    end
  end

  def self.create_journal(journable, journal_attributes, user = User.current,  notes = '')
    type = base_class(journable.class)
    extended_journal_attributes = journal_attributes.merge(journable_type: type.to_s)
                                  .merge(notes: notes)
                                  .except(:details)
                                  .except(:id)

    unless extended_journal_attributes.has_key? :user_id
      extended_journal_attributes[:user_id] = user.id
    end

    journal_attributes[:details] = normalize_newlines(journal_attributes[:details])

    journal = journable.journals.build extended_journal_attributes
    journal.data = create_journal_data journal.id,
                                       type,
                                       valid_journal_attributes(type, journal_attributes[:details])

    create_association_data journable, journal

    journal
  end

  def self.valid_journal_attributes(type, changed_data)
    journal_class = journal_class type
    journal_class_attributes = journal_class.columns.map(&:name)

    valid_journal_attributes = changed_data.select { |k, _v| journal_class_attributes.include?(k.to_s) }
    valid_journal_attributes.except :id, :updated_at, :updated_on
  end

  def self.create_journal_data(_journal_id, type, changed_data)
    journal_class = journal_class type
    new_data = Hash[changed_data.map { |k, v| [k, (v.is_a? Array) ? v.last : v] }]

    journal_class.new new_data
  end

  def self.update_user_references(current_user_id, substitute_id)
    foreign_keys = ['author_id', 'user_id', 'assigned_to_id', 'responsible_id']

    Journal::BaseJournal.subclasses.each do |klass|
      foreign_keys.each do |foreign_key|
        if klass.column_names.include? foreign_key
          klass.where(foreign_key => current_user_id).update_all(foreign_key => substitute_id)
        end
      end
    end
  end

  def self.journal_class(type)
    namespace = type.name.deconstantize

    if namespace == 'Journal'
      type
    else
      "Journal::#{journal_class_name(type)}".constantize
    end
  end

  def self.journaled_class(journal_type)
    namespace = journal_type.name.deconstantize

    if namespace == 'Journal'
      class_name = journal_type.name.demodulize
      class_name.gsub('Journal', '').constantize
    else
      journal_type
    end
  end

  def self.normalize_newlines(data)
    data.each_with_object({}) { |e, h|
      h[e[0]] = (e[1].is_a?(String) ? e[1].gsub(/\r\n/, "\n") : e[1])
    }
  end

  def self.with_send_notifications(send_notifications, &block)
    old_value = send_notification

    self.send_notification = send_notifications

    result = block.call

    self.send_notification = old_value

    result
  end
end
