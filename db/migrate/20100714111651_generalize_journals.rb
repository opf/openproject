#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class GeneralizeJournals < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    change_table :journals do |t|
      t.rename :journalized_id, :journaled_id
      t.rename :created_on, :created_at

      t.integer :version, :default => 0, :null => false
      t.string :activity_type
      t.text :changes
      t.string :type

      t.index :journaled_id
      t.index :activity_type
      t.index :created_at
      t.index :type
    end

    Journal.all.group_by(&:journaled_id).each_pair do |id, journals|
      journals.sort_by(&:created_at).each_with_index do |j, idx|
        j.update_attribute(:type, "#{j.journalized_type}Journal")
        j.update_attribute(:version, idx + 1)
        # FIXME: Find some way to choose the right activity here
        j.update_attribute(:activity_type, j.journalized_type.constantize.activity_provider_options.keys.first)
      end
    end

    change_table :journals do |t|
      t.remove :journalized_type
    end

    JournalDetails.all.each do |detail|
      journal = Journal.find(detail.journal_id)
      changes = journal.changes || {}
      if detail.property == 'attr' # Standard attributes
        changes[detail.prop_key.to_s] = [detail.old_value, detail.value]
      elsif detail.property == 'cf' # Custom fields
        changes["custom_values_" + detail.prop_key.to_s] = [detail.old_value, detail.value]
      elsif detail.property == 'attachment' # Attachment
        changes["attachments_" + detail.prop_key.to_s] = [detail.old_value, detail.value]
      end
      journal.update_attribute(:changes, changes.to_yaml)
    end

    # Create creation journals for all activity providers
    providers = Redmine::Activity.providers.collect {|k, v| v.collect(&:constantize) }.flatten.compact.uniq
    providers.each do |p|
      next unless p.table_exists? # Objects not in the DB yet need creation journal entries
      p.find(:all).each do |o|
        unless o.last_journal
          o.send(:update_journal)
          created_at = nil
          [:created_at, :created_on, :updated_at, :updated_on].each do |m|
            if o.respond_to? m
              created_at = o.send(m)
              break
            end
          end
          p "Updating #{o}"
          o.last_journal.update_attribute(:created_at, created_at) if created_at and o.last_journal
        end
      end
    end

    # drop_table :journal_details
  end

  def self.down
    # create_table "journal_details", :force => true do |t|
    #   t.integer "journal_id",               :default => 0,  :null => false
    #   t.string  "property",   :limit => 30, :default => "", :null => false
    #   t.string  "prop_key",   :limit => 30, :default => "", :null => false
    #   t.string  "old_value"
    #   t.string  "value"
    # end

    change_table "journals" do |t|
      t.rename :journaled_id, :journalized_id
      t.rename :created_at, :created_on

      t.string :journalized_type, :limit => 30, :default => "", :null => false
    end

    custom_field_names = CustomField.all.group_by(&:type)[IssueCustomField].collect(&:name)
    Journal.all.each do |j|
      # Can't used j.journalized.class.name because the model changes make it nil
      j.update_attribute(:journalized_type, j.type.to_s.sub("Journal","")) if j.type.present?
    end

    change_table "journals" do |t|
      t.remove_index :journaled_id
      t.remove_index :activity_type
      t.remove_index :created_at
      t.remove_index :type

      t.remove :type
      t.remove :version
      t.remove :activity_type
      t.remove :changes
    end

    # add_index "journal_details", ["journal_id"], :name => "journal_details_journal_id"
    # add_index "journals", ["journalized_id", "journalized_type"], :name => "journals_journalized_id"
  end
end
