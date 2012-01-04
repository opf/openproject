#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

Redmine::Activity.providers.values.flatten.uniq.collect(&:underscore).each {|klass| require_dependency klass }

class UpdateJournalsForActsAsJournalized < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    say_with_time("Updating existing Journals...") do
      Journal.all.group_by(&:journaled_id).each_pair do |id, journals|
        journals.sort_by(&:created_at).each_with_index do |j, idx|
          # Recast the basic Journal into it's STI journalized class so callbacks work (#467)
          klass_name = "#{j.journalized_type}Journal"
          j = j.becomes(klass_name.constantize)
          j.type = klass_name
          j.version = idx + 2 # initial journal should be 1
          j.activity_type = j.journalized_type.constantize.activity_provider_options.keys.first
          begin
            j.save(false)
          rescue ActiveRecord::RecordInvalid => ex
            puts "Error saving: #{j.class.to_s}##{j.id} - #{ex.message}"
          end

        end
      end
    end

    change_table :journals do |t|
      t.remove :journalized_type
    end
  end

  def self.down
    change_table "journals" do |t|
      t.string :journalized_type, :limit => 30, :default => "", :null => false
    end

    custom_field_names = CustomField.all.group_by(&:type)[IssueCustomField].collect(&:name)
    Journal.all.each do |j|
      # Can't used j.journalized.class.name because the model changes make it nil
      j.update_attribute(:journalized_type, j.type.to_s.sub("Journal","")) if j.type.present?
    end

  end
end

