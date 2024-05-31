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

module TableHelpers::ColumnType
  RSpec.describe Hierarchy do
    subject(:column_type) { described_class.new }

    describe "#extract_data" do
      let(:attribute) { :hierarchy }
      let(:subject_raw_header) { "Hierarchy    " }
      let(:work_packages_data) do
        [
          {
            index: 0,
            row: { subject_raw_header => "Parent        " }
          },
          {
            index: 1,
            row: { subject_raw_header => "  Child1      " }
          },
          {
            index: 2,
            row: { subject_raw_header => "  Child2      " }
          },
          {
            index: 3,
            row: { subject_raw_header => "     Grand Child" }
          }
        ]
      end

      it "extracts the identifier metadata along with the :subject attribute value" do
        # check first row only
        expect(column_type.extract_data(attribute, subject_raw_header, work_packages_data.first, work_packages_data))
          .to include({ attributes: a_hash_including(subject: "Parent"),
                        identifier: :parent })
      end

      it "extracts the hierarchy_indent metadata as the number of spaces before the name, " \
         "and the :parent attribute value holding the identifier of the parent from previous rows" do
        # first row
        work_package_data = work_packages_data.first
        row_extract = column_type.extract_data(attribute, subject_raw_header, work_package_data, work_packages_data)
        expect(row_extract).to include({ attributes: a_hash_including(parent: nil),
                                         hierarchy_indent: 0 })

        # second row
        work_package_data.deep_merge!(row_extract)
        work_package_data = work_packages_data.second
        row_extract = column_type.extract_data(attribute, subject_raw_header, work_package_data, work_packages_data)
        expect(row_extract).to include({ attributes: a_hash_including(parent: :parent),
                                         hierarchy_indent: 2,
                                         identifier: :child1 })

        # third row
        work_package_data.deep_merge!(row_extract)
        work_package_data = work_packages_data.third
        row_extract = column_type.extract_data(attribute, subject_raw_header, work_package_data, work_packages_data)
        expect(row_extract).to include({ attributes: a_hash_including(parent: :parent),
                                         hierarchy_indent: 2,
                                         identifier: :child2 })

        # fourth row
        work_package_data.deep_merge!(row_extract)
        work_package_data = work_packages_data.fourth
        row_extract = column_type.extract_data(attribute, subject_raw_header, work_package_data, work_packages_data)
        expect(row_extract).to include({ attributes: a_hash_including(parent: :child2),
                                         hierarchy_indent: 5,
                                         identifier: :grand_child })
      end
    end
  end
end
