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

class AddChangesFromJournalDetailsForActsAsJournalized < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    say_with_time("Adding changes from JournalDetails") do
      JournalDetails.all.each do |detail|
        journal = Journal.find(detail.journal_id)
        changes = journal.changed_data || {}
        if detail.property == 'attr' # Standard attributes
          changes[detail.prop_key.to_s] = [detail.old_value, detail.value]
        elsif detail.property == 'cf' # Custom fields
          changes["custom_values_" + detail.prop_key.to_s] = [detail.old_value, detail.value]
        elsif detail.property == 'attachment' # Attachment
          changes["attachments_" + detail.prop_key.to_s] = [detail.old_value, detail.value]
        end
        begin
          journal.update_attribute(:changes, changes.to_yaml)
        rescue ActiveRecord::RecordInvalid => ex
          puts "Error saving: #{journal.class.to_s}##{journal.id} - #{ex.message}"
        end

      end

    end

  end

  def self.down
    # No-op
  end

end
