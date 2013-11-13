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

require_relative '../../db/migrate/migration_utils/timelines'

namespace :migrations do
  namespace :journals do
    desc "Quotes all strings starting with an invalid character in column 'changed_data' of table 'legacy_journals'"
    task :quote_strings_with_invalid_characters_in_legacy_journals => :environment do |task|
      quoter = InvalidChangedDataStringQuoter.new

      quoter.quote_strings_with_invalid_characters
    end

    private

    class InvalidChangedDataStringQuoter < ActiveRecord::Migration
      include Migration::Utils

      def quote_strings_with_invalid_characters
        say_with_time_silently "Quote journal strings with invalid characters" do
          update_column_values('legacy_journals',
                               ['changed_data'],
                               quote_invalid_strings,
                               invalid_changed_data_filter)
        end
      end

      private

      def invalid_changed_data_filter
        "changed_data LIKE '%- ,%'"
      end

      INVALID_STARTING_CHARACTER_REGEX = /(?<start>\n- )(?<text>,.*)(?<end>\n.*:)/

      def quote_invalid_strings
        Proc.new do |row|
          changed_data = row['changed_data']

          quoted_changed_data = changed_data.gsub(INVALID_STARTING_CHARACTER_REGEX) do |m|
            "#{$1}\"#{$2}\"#{$3}"
          end

          row['changed_data'] = quoted_changed_data

          UpdateResult.new(row, changed_data != quoted_changed_data)
        end
      end
    end
  end
end
