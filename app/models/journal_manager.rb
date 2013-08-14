#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class JournalManager

  def self.is_journalized?(obj)
    not obj.nil? and obj.respond_to? :journals
  end

  def self.changed?(journaled)
    if journaled.journals.count > 0
      changed = attributes_changed? journaled
      changed ||= association_changed? journaled, "attachable", :attachments, :id, :attachment_id, :filename
      changed ||= association_changed? journaled, "customizable", :custom_values, :custom_field_id, :custom_field_id, :value

      changed
    else
      true
    end
  end

  def self.attributes_changed?(journaled)
    current = journaled.attributes
    predecessor = journaled.journals.last.data.journaled_attributes

    return predecessor.map{|k,v| current[k.to_s] != v}
                      .inject(false) { |r, c| r || c }
  end

  def self.association_changed?(journaled, journal_association, association, id, key, value)
    if journaled.respond_to? association
      journal_assoc_name = "#{journal_association}_journals".to_sym
      changes = {}
      current = journaled.send(association).map {|a| { key.to_s => a.send(id), value.to_s => a.send(value)} }
      predecessor = journaled.journals.last.send(journal_assoc_name).map(&:attributes)

      merged_journals = JournalManager.merge_reference_journals_by_id current, predecessor, key.to_s

      changes.merge! JournalManager.added_references(merged_journals, association.to_s, value.to_s)
      changes.merge! JournalManager.removed_references(merged_journals, association.to_s, value.to_s)
      changes.merge! JournalManager.changed_references(merged_journals, association.to_s, value.to_s)

      not changes.empty?
    else
      false
    end
  end

  def self.merge_reference_journals_by_id(current, predecessor, key)
      all_attachable_journal_ids = current.map { |j| j[key] } | predecessor.map { |j| j[key] }

      all_attachable_journal_ids.each_with_object({}) { |i, h| h[i] = [predecessor.detect { |j| j[key] == i },
                                                                       current.detect { |j| j[key] == i }] }
  end

  def self.added_references(merged_references, key, value)
    merged_references.select {|_, v| v[0].nil? and not v[1].nil?}
                     .each_with_object({}) { |k,h| h["#{key}_#{k[0]}".to_sym] = [nil, k[1][1][value]] }
  end

  def self.removed_references(merged_references, key, value)
    merged_references.select {|_, v| not v[0].nil? and v[1].nil?}
                             .each_with_object({}) { |k,h| h["#{key}_#{k[0]}".to_sym] = [k[1][0][value], nil] }
  end

  def self.changed_references(merged_references, key, value)
    merged_references.select {|_, v| not v[0].nil? and not v[1].nil? and v[0][value] != v[1][value]}
                     .each_with_object({}) { |k,h| h["#{key}_#{k[0]}".to_sym] = [k[1][0][value], k[1][1][value]] }

  end

  def self.recreate_initial_journal(type, journal, changed_data)
    if journal.data.nil?
      journal.data = create_journal_data journal.id, type, changed_data.except(:id)
    else
      journal.changed_data = changed_data
    end

    journal.save!
    journal.reload
  end

  def self.add_journal(journaled, user = User.current, notes = "")
    if is_journalized? journaled
      journal_attributes = { journaled_id: journaled.id,
                             journaled_type: journal_class_name(journaled.class),
                             version: (journaled.journals.count + 1),
                             activity_type: journaled.send(:activity_type),
                             changed_data: journaled.attributes.symbolize_keys }

      create_journal journaled, journal_attributes, user, notes
    end
  end

  def self.create_journal(journaled, journal_attributes, user = User.current,  notes = "")
    type = base_class(journaled.class)
    extended_journal_attributes = journal_attributes.merge({ journaled_type: journal_class_name(type) })
                                                    .merge({ notes: notes })
                                                    .except(:changed_data)
                                                    .except(:id)

    unless extended_journal_attributes.has_key? :user_id
      extended_journal_attributes[:user_id] = user.id
    end

    journal = journaled.journals.build extended_journal_attributes
    journal.data = create_journal_data journal.id, type, journal_attributes[:changed_data].except(:id)

    create_association_data journaled, journal

    journal
  end

  def self.create_journal_data(journal_id, type, changed_data)
    journal_class = journal_class type
    new_data = Hash[changed_data.map{|k,v| [k, (v.kind_of? Array) ? v.last : v]}]

    journal_class.new new_data
  end

  USER_DELETION_JOURNAL_BUCKET_SIZE = 1000;

  def self.update_user_references(current_user_id, substitute_id)
    foreign_keys = ['author_id', 'user_id', 'assigned_to_id', 'responsible_id']

    # as updating the journals will take some time we do it in batches
    # so that journals created later are also accounted for
    while (journal_subset = Journal.all(:conditions => ["id > ?", current_id ||= 0],
                                        :order => "id ASC",
                                        :limit => USER_DELETION_JOURNAL_BUCKET_SIZE)).size > 0 do

      # change user reference in data fields
      journal_subset.each do |journal|
        foreign_keys.each do |foreign_key|
          if journal.data.respond_to? foreign_key
            journal.data.send "#{foreign_key}=", substitute_id if journal.data.send(foreign_key) == current_user_id
          end
        end

        # change journal user
        journal.user_id = substitute_id if journal.user_id = current_user_id

        journal.save if journal.data.changed?
      end

      current_id = journal_subset.map(&:id).max
    end
  end

  private

  def self.journal_class(type)
    "Journal::#{journal_class_name(type)}".constantize
  end

  def self.journal_class_name(type)
    "#{base_class(type).name}Journal"
  end

  def self.base_class(type)
    supertype = type.ancestors.find{|a| a != type and a.is_a? Class}

    supertype = type if supertype == ActiveRecord::Base

    supertype
  end

  def self.create_association_data(journaled, journal)
    create_attachment_data journaled, journal if journaled.respond_to? :attachments
    create_custom_field_data journaled, journal if journaled.respond_to? :custom_values
  end

  def self.create_attachment_data(journaled, journal)
    journaled.attachments.each do |a|
      journal.attachable_journals.build journal: journal, attachment: a, filename: a.filename
    end
  end

  def self.create_custom_field_data(journaled, journal)
    journaled.custom_values.each do |cv|
      journal.customizable_journals.build journal: journal, custom_field: cv.custom_field, value: cv.value
    end
  end
end
