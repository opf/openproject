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
  RSpec.describe RelatedToRelations do
    subject(:column_type) { described_class.new }

    def parsed_data(table)
      TableHelpers::TableParser.new.parse(table)
    end

    describe "empty" do
      it "stores nothing when empty" do
        work_package_data = parsed_data(<<~TABLE).first
          | related to |
          |            |
        TABLE
        expect(work_package_data[:relations]).to be_nil
        expect(work_package_data[:attributes]).to be_empty

        work_package_data = parsed_data(<<~TABLE).first
          | relates to
          |
        TABLE
        expect(work_package_data[:relations]).to be_nil
        expect(work_package_data[:attributes]).to be_empty
      end
    end

    describe "<work package name>" do
      it "stores related_to relations in work_package_data" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | related to |
          | main       |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "main" => { raw: "main", type: :relates, with: "main" }
                   }
                 ])
      end

      it "can store multiple relations" do
        work_package_data = parsed_data(<<~TABLE).pluck(:relations)
          | related to    |
          | wp1, wp2, wp3 |
        TABLE
        expect(work_package_data)
          .to eq([
                   {
                     "wp1" => { raw: "wp1", type: :relates, with: "wp1" },
                     "wp2" => { raw: "wp2", type: :relates, with: "wp2" },
                     "wp3" => { raw: "wp3", type: :relates, with: "wp3" }
                   }
                 ])
      end
    end
  end
end
