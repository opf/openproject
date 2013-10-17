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

require 'yaml'

require_relative 'migration_utils/utils'

class MigrateQueryTrackerReferencesToType < ActiveRecord::Migration
  include Migration::Utils

  COLUMNS = ['filters', 'column_names', 'sort_criteria', 'group_by']
  KEY = { 'tracker_id' => 'type_id', 'tracker' => 'type' }

  def up
    say_with_time_silently "Update tracker references in queries" do
      update_tracker_references_with_keys(KEY)
    end
  end

  def down
    say_with_time_silently "Restore tracker references in queries" do
      update_tracker_references_with_keys(KEY.invert)
    end
  end

  private

  def update_tracker_reference(keys, columns)
    Proc.new do |row|
      columns.each do |column|
        unless row[column].nil?
          value = YAML.load row[column]

          if value.is_a? Array
            value.collect! do |e| 
              if e.is_a? Array
                e.collect! {|v| keys.has_key?(v) ? keys[v] : v}
              else
                keys.has_key?(e.to_s) ? keys[e.to_s].to_sym : e
              end
            end
          elsif value.is_a? Hash
            keys.select {|k| value[k.to_s]}
                .each_pair {|k, v| value[v] = value.delete k}
          end

          row[column] = YAML.dump value
        end
      end

      UpdateResult.new(row, true)
    end
  end

  def update_tracker_references_with_keys(keys)
    filter = COLUMNS.map{|c| "#{c} LIKE '%tracker%'"}
                    .join(" OR ")

    update_column_values('queries', COLUMNS, update_tracker_reference(keys, COLUMNS), filter)
  end
end
