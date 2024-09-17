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

module TableHelpers
  RSpec.describe TableData do
    describe ".for" do
      it "reads a table representation and stores its data" do
        table = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.work_packages_data.size).to eq(2)
        expect(table_data.columns.size).to eq(2)
        expect(table_data.headers).to eq([" subject      ", " remaining work "])
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])
      end
    end

    describe ".from_work_packages" do
      it "reads data from work packages according to the given columns" do
        table = <<~TABLE
          | subject      | status | remaining work |
          | work package | To do  |             3h |
          | another one  | Done   |                |
        TABLE
        columns = described_class.for(table).columns

        status_todo = build(:status, name: "To do")
        status_done = build(:status, name: "Done")
        work_package = build(:work_package, subject: "work package", status: status_todo, remaining_hours: 3)
        another_one = build(:work_package, subject: "another one", status: status_done)

        table_data = described_class.from_work_packages([work_package, another_one], columns)
        expect(table_data.work_packages_data.size).to eq(2)
        expect(table_data.columns.size).to eq(3)
        expect(table_data.headers).to eq(["subject", "status", "remaining work"])
        expect(table_data.values_for_attribute(:subject)).to eq(["work package", "another one"])
        expect(table_data.values_for_attribute(:status)).to eq(["To do", "Done"])
        expect(table_data.values_for_attribute(:remaining_hours)).to eq([3.0, nil])
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])
      end
    end

    describe "#headers" do
      it "returns headers of a table data as they were read" do
        table = <<~TABLE
          | subject      | remaining work | derived work |
          | work package |             3h |           3h |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.headers).to eq([" subject      ", " remaining work ", " derived work "])
        expect(table_data.columns.size).to eq(3)
      end

      it "returns headers even if some values are blank in the first row" do
        table = <<~TABLE
          | subject      | remaining work | derived work |
          | work package |                |              |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.headers).to eq([" subject      ", " remaining work ", " derived work "])
        expect(table_data.columns.size).to eq(3)
      end
    end

    describe "#values_for_attribute" do
      it "returns all the values of the work packages for the given attribute" do
        table = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE

        table_data = described_class.for(table)
        expect(table_data.values_for_attribute(:remaining_hours)).to eq([3.0, nil])
        expect(table_data.values_for_attribute(:subject)).to eq(["work package", "another one"])
      end
    end

    describe "#create_work_packages" do
      it "creates work packages out of the table data" do
        status = create(:status, name: "To do")
        table_representation = <<~TABLE
          subject | status | work |
          My wp   | To do  |   5h |
        TABLE

        table_data = described_class.for(table_representation)
        table = table_data.create_work_packages
        expect(table.work_packages.count).to eq(1)
        expect(table.work_package(:my_wp))
          .to have_attributes(subject: "My wp", status:, estimated_hours: 5.0)
      end

      it "raises an error if a given status name does not exist" do
        table_representation = <<~TABLE
          subject | status |
          My wp   | To do  |
        TABLE

        expect { described_class.for(table_representation).create_work_packages }
          .to raise_error(NameError, 'No status with name "To do" found. Available statuses are: [].')

        create(:status, name: "Doing")
        create(:status, name: "Done")
        expect { described_class.for(table_representation).create_work_packages }
          .to raise_error(NameError, 'No status with name "To do" found. Available statuses are: ["Doing", "Done"].')

        create(:status, name: "To do")
        expect { described_class.for(table_representation).create_work_packages }
          .not_to raise_error
      end
    end

    describe "#order_like" do
      it "orders the table data like the given table" do
        table_representation = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | subject      | remaining work |
          | another one  |                |
          | work package |             3h |
        TABLE
        other_table_data = described_class.for(other_table_representation)
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers).to eq(%i[another_one work_package])
      end

      it "ignores unknown rows from the given table" do
        table_representation = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | subject      | remaining work |
          | another one  |                |
          | work package |             3h |
          | unknown one  |                |
        TABLE
        other_table_data = described_class.for(other_table_representation)
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers).to eq(%i[another_one work_package])
      end

      it "appends to the bottom the rows missing in the given table" do
        table_representation = <<~TABLE
          | subject      | remaining work |
          | work package |             3h |
          | extra one    |                |
          | another one  |                |
        TABLE
        table_data = described_class.for(table_representation)

        other_table_representation = <<~TABLE
          | subject           | remaining work |
          | another one       |                |
          | work package      |             3h |
        TABLE
        other_table_data = described_class.for(other_table_representation)
        expect(table_data.work_package_identifiers).to eq(%i[work_package extra_one another_one])

        table_data.order_like!(other_table_data)
        expect(table_data.work_package_identifiers).to eq(%i[another_one work_package extra_one])
      end
    end
  end
end
