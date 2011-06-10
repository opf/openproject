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

    # Build initial journals for all activity providers
    providers = Redmine::Activity.providers.collect {|k, v| v.collect(&:constantize) }.flatten.compact.uniq
    providers.each do |p|
      next unless p.table_exists? # Objects not in the DB yet need creation journal entries
      p.find(:all).each do |o|
        # Create initial journals
        new_journal = o.journals.build
        # Mock up a list of changes for the creation journal based on Class defaults
        new_attributes = o.class.new.attributes.except(o.class.primary_key,
                                                       o.class.inheritance_column,
                                                       :updated_on,
                                                       :updated_at,
                                                       :lock_version,
                                                       :lft,
                                                       :rgt)
        creation_changes = {}
        new_attributes.each do |name, default_value|
          # Set changes based on the initial value to current. Can't get creation value without
          # rebuiling the object history
          creation_changes[name] = [default_value, o.send(name)] # [initial_value, creation_value]
        end
        new_journal.changes = creation_changes
        new_journal.version = 1
        
        if o.respond_to?(:author)
          new_journal.user = o.author
        elsif o.respond_to?(:user)
          new_journal.user = o.user
        end
        new_journal.save
        
        # Backdate journal
        if o.respond_to?(:created_at)
          new_journal.update_attribute(:created_at, o.created_at)
        elsif o.respond_to?(:created_on)
          new_journal.update_attribute(:created_at, o.created_on)
        end
        p "Updating #{o}"
      end
      
    end

    # Migrate journal changes now
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
