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
  RSpec.describe SchedulingMode do
    subject(:column_type) { described_class.new }
    def parsed_attributes(table)
      work_packages_data = TableHelpers::TableParser.new.parse(table)
      work_packages_data.pluck(:attributes)
    end

    describe "#parse" do
      it "maps 'manual' to `schedule_manually: true`" do
        expect(parsed_attributes(<<~TABLE))
          | scheduling mode |
          | manual          |
        TABLE
          .to eq([{ schedule_manually: true }])
      end

      it "maps 'automatic' to `schedule_manually: false`" do
        expect(parsed_attributes(<<~TABLE))
          | scheduling mode |
          | automatic       |
        TABLE
          .to eq([{ schedule_manually: false }])
      end

      it "maps empty value to `schedule_manually: nil` (which means automatic too)" do
        expect(parsed_attributes(<<~TABLE))
          | scheduling mode |
          |                 |
        TABLE
          .to eq([{ schedule_manually: nil }])
      end

      it "can still use 'schedule manually' as column name with `true` and `false` as values" do
        expect(parsed_attributes(<<~TABLE))
          | schedule manually |
          | true              |
          | false             |
          |                   |
        TABLE
          .to eq([{ schedule_manually: true }, { schedule_manually: false }, { schedule_manually: nil }])
      end

      it "raises an error if value is invalid" do
        expect { parsed_attributes(<<~TABLE) }
          | scheduling mode |
          | foo             |
        TABLE
          .to raise_error("Invalid scheduling mode: foo. Expected 'manual' or 'automatic'.")
      end
    end

    describe "#format" do
      it "maps `true` to 'manual'" do
        expect(column_type.format(true)).to eq "manual"
      end

      it "maps `false` and `nil` to 'automatic'" do
        expect(column_type.format(false)).to eq "automatic"
        expect(column_type.format(nil)).to eq "automatic"
      end
    end
  end
end
