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

class BuildInitialJournalsForActsAsJournalized < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    # Reset class and subclasses, otherwise they will try to save using older attributes
    Journal.reset_column_information
    Journal.send(:subclasses).each do |klass|
      klass.reset_column_information if klass.respond_to?(:reset_column_information)
    end


    [Message, Attachment, Document, Changeset, Issue, TimeEntry, News].each do |p|
      say_with_time("Building initial journals for #{p.class_name}") do

        # avoid touching the journaled object on journal creation
        p.journal_class.class_exec {
          def touch_journaled_after_creation
          end
        }

        activity_type = p.activity_provider_options.keys.first

        # Create initial journals
        p.find_each(:batch_size => 100 ) do |o|
          # Using rescue and save! here because either the Journal or the
          # touched record could fail. This will catch either error and continue
          begin
            new_journal = o.recreate_initial_journal!
          rescue ActiveRecord::RecordInvalid => ex
            if new_journal.errors.count == 1 && new_journal.errors.first[0] == "version"
              # Skip, only error was from creating the initial journal for a record that already had one.
            else
              puts "ERROR: errors creating the initial journal for #{o.class.to_s}##{o.id.to_s}:"
              puts "  #{ex.message}"
            end
          end
        end

      end
    end

  end

  def self.down
    # No-op
  end

end
