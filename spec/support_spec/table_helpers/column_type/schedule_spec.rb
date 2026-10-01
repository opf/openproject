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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

module TableHelpers::ColumnType
  RSpec.describe Schedule do
    let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
    let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
    let(:tuesday) { Date.new(2022, 6, 21) }
    let(:wednesday) { Date.new(2022, 6, 22) }
    let(:thursday) { Date.new(2022, 6, 23) }
    let(:friday) { Date.new(2022, 6, 24) }
    let(:saturday) { Date.new(2022, 6, 25) }
    let(:sunday) { Date.new(2022, 6, 26) }

    def parsed_attributes(table)
      work_packages_data = TableHelpers::TableParser.new.parse(table)
      work_packages_data.pluck(:attributes)
    end

    before do
      travel_to(fake_today)
    end

    after do
      travel_back
    end

    describe "origin day" do
      it "is identified by the 'M' in 'MTWTFSS' in the header and corresponds to the next monday" do
        expect(parsed_attributes(<<~TABLE))
          |   MTWTFSS |
          |   X       |
        TABLE
          .to eq([{ start_date: monday, due_date: monday }])
      end

      it "is not identified by mtwtfss which can be used as documentation instead" do
        expect(parsed_attributes(<<~TABLE))
          | mtwtfssMTWTFSSmtwtfss |
          |        X              |
        TABLE
          .to eq([{ start_date: monday, due_date: monday }])
      end
    end

    describe "work package dates extraction" do
      def parsed_attributes(table)
        work_packages_data = TableHelpers::TableParser.new.parse(table)
        work_packages_data.pluck(:attributes)
      end

      it "recognizes multiple 'X' as the duration spanning from start date and end date" do
        expect(parsed_attributes(<<~TABLE))
          | MTWTFSS |
          | XX      |
        TABLE
          .to eq([{ start_date: monday, due_date: tuesday }])
      end

      it "recognizes start date and end date outside of the reference week" do
        expect(parsed_attributes(<<~TABLE))
          |     MTWTFSS   |
          |        XXXXXX |
          | XXXXXX        |
        TABLE
          .to eq([
                   { start_date: thursday, due_date: tuesday + 7.days },
                   { start_date: thursday - 7.days, due_date: tuesday }
                 ])
      end

      it "recognizes '[' as start date, making the due date nil if there are no 'X' or ']' after it" do
        expect(parsed_attributes(<<~TABLE))
          | MTWTFSS |
          |  [      |
        TABLE
          .to eq([{ start_date: tuesday, due_date: nil }])
      end

      it "recognizes ']' as end date, making the start date nil if there are no 'X' or '[' before it" do
        expect(parsed_attributes(<<~TABLE))
          | MTWTFSS |
          |    ]    |
        TABLE
          .to eq([{ start_date: nil, due_date: thursday }])
      end

      it "sets start date and due date to nil if there are no 'X', '[', or ']' at all" do
        expect(parsed_attributes(<<~TABLE))
          | MTWTFSS |
          |         |
        TABLE
          .to eq([{ start_date: nil, due_date: nil }])
      end

      it "ignores characters other than 'X', '[', or ']', allowing to use other characters to " \
         "represent other things (like '.' for non-working days)" do
        expect(parsed_attributes(<<~TABLE))
          | MTWTFSS   |
          |    XX..XX |
        TABLE
          .to include(start_date: thursday, due_date: tuesday + 7.days)
      end
    end
  end
end
