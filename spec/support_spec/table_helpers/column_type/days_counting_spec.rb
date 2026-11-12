# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

module TableHelpers::ColumnType
  RSpec.describe DaysCounting do
    subject(:column_type) { described_class.new }

    def parsed_attributes(table)
      work_packages_data = TableHelpers::TableParser.new.parse(table)
      work_packages_data.pluck(:attributes)
    end

    describe "#parse" do
      it "maps 'all days' to `ignore_non_working_days: true`" do
        expect(parsed_attributes(<<~TABLE))
          | days counting |
          | all days      |
        TABLE
          .to eq([{ ignore_non_working_days: true }])
      end

      it "maps 'working days only' to `ignore_non_working_days: false`" do
        expect(parsed_attributes(<<~TABLE))
          | days counting     |
          | working days only |
        TABLE
          .to eq([{ ignore_non_working_days: false }])
      end

      it "raises an error if value is empty" do
        expect { parsed_attributes(<<~TABLE) }
          | days counting |
          |               |
        TABLE
          .to raise_error("Invalid value for 'days counting' column: \"\". " \
                          "Expected 'all days' (ignore_non_working_days: true) " \
                          "or 'working days only' (ignore_non_working_days: false).")
      end

      it "can still use 'ignore_non_working_days' as column name with `true` and `false` as values" do
        expect(parsed_attributes(<<~TABLE))
          | ignore_non_working_days |
          | true                    |
          | false                   |
        TABLE
          .to eq([{ ignore_non_working_days: true }, { ignore_non_working_days: false }])
      end

      it "raises an error if value is invalid" do
        expect { parsed_attributes(<<~TABLE) }
          | days counting |
          | foo           |
        TABLE
          .to raise_error("Invalid value for 'days counting' column: \"foo\". " \
                          "Expected 'all days' (ignore_non_working_days: true) " \
                          "or 'working days only' (ignore_non_working_days: false).")
      end
    end

    describe "#format" do
      it "maps `true` to 'all days'" do
        expect(column_type.format(true)).to eq "all days"
      end

      it "maps `false` to 'working days only'" do
        expect(column_type.format(false)).to eq "working days only"
      end
    end
  end
end
