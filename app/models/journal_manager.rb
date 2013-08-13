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

  def self.attributes_changed?(journaled)
    if journaled.journals.count > 0
      current = journaled.attributes
      predecessor = journaled.journals.last.data.journaled_attributes

      return predecessor.map{|k,v| current[k.to_s] != v}
                        .inject(false) { |r, c| r || c }
    end

    true
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
    journaled.custom_values.each do |c|
      journal.customizable_journals.build journal: journal, custom_field: c, value: c.value
    end
  end
end
