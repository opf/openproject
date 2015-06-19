#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative '../../db/migrate/migration_utils/timelines'

namespace :migrations do
  namespace :journals do
    desc "Quotes all strings starting with an invalid character in column 'changed_data' of table 'legacy_journals'"
    task quote_strings_with_invalid_characters_in_legacy_journals: :environment do |_task|
      quoter = InvalidChangedDataStringQuoter.new

      quoter.quote_strings_with_invalid_characters
    end

    private

    class InvalidChangedDataStringQuoter < ActiveRecord::Migration
      include Migration::Utils

      def quote_strings_with_invalid_characters
        say_with_time_silently 'Quote journal strings with invalid characters' do
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

          quoted_changed_data = changed_data.gsub(INVALID_STARTING_CHARACTER_REGEX) do |_m|
            "#{$1}\"#{$2}\"#{$3}"
          end

          row['changed_data'] = quoted_changed_data

          UpdateResult.new(row, changed_data != quoted_changed_data)
        end
      end
    end
  end
end
