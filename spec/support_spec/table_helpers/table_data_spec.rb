# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
          | subject      | remaining work |
          | work package |             3h |
          | another one  |                |
        TABLE
        columns = described_class.for(table).columns

        work_package = build(:work_package, subject: "work package", remaining_hours: 3)
        another_one = build(:work_package, subject: "another one")

        table_data = described_class.from_work_packages([work_package, another_one], columns)
        expect(table_data.work_packages_data.size).to eq(2)
        expect(table_data.columns.size).to eq(2)
        expect(table_data.headers).to eq(["subject", "remaining work"])
        expect(table_data.work_package_identifiers).to eq(%i[work_package another_one])
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
  end
end
