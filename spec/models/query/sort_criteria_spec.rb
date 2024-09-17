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

RSpec.describe Query::SortCriteria do
  let(:query) do
    build_stubbed(:query,
                  show_hierarchies: false)
  end

  let(:available_criteria) { query.sortable_key_by_column_name }

  let(:instance) { described_class.new query.sortable_columns }

  subject { instance.to_a }

  before do
    instance.criteria = sort_criteria
    instance.available_criteria = available_criteria
  end

  describe "ordered handling" do
    context "with an empty sort_criteria" do
      let(:sort_criteria) { [] }

      it "returns the default order by id" do
        expect(subject)
          .to eq [["work_packages.id DESC"]]
      end
    end

    context "with a sort_criteria for id" do
      let(:sort_criteria) { [["id"]] }

      it "returns the default order by id only once" do
        expect(subject)
          .to eq [["work_packages.id"]]
      end
    end

    context "with a sort_criteria for id ASC" do
      let(:sort_criteria) { [%w[id asc]] }

      it "returns the custom order by id asc" do
        expect(subject)
          .to eq [["work_packages.id"]]
      end
    end

    context "with a sort_criteria for typeahead ASC" do
      let(:sort_criteria) { [%w[typeahead asc]] }

      it "returns the custom order by id asc" do
        expect(subject)
          .to eq [["work_packages.updated_at DESC, work_packages.updated_at"], ["work_packages.id DESC"]]
      end
    end

    context "with sort_criteria with order handling and no order statement" do
      let(:sort_criteria) { [["start_date"]] }

      it "adds the order handling (and the default order by id)" do
        expect(subject)
          .to eq [["work_packages.start_date NULLS LAST"], ["work_packages.id DESC"]]
      end
    end

    context "with sort_criteria with order handling and ASC order statement" do
      let(:sort_criteria) { [%w[start_date asc]] }

      it "adds the order handling (and the default order by id)" do
        expect(subject)
          .to eq [["work_packages.start_date NULLS LAST"], ["work_packages.id DESC"]]
      end
    end

    context "with sort_criteria with order handling and DESC order statement" do
      let(:sort_criteria) { [%w[start_date desc]] }

      it "adds the order handling (and the default order by id)" do
        expect(subject)
          .to eq [["work_packages.start_date DESC NULLS LAST"], ["work_packages.id DESC"]]
      end
    end

    context "with multiple sort_criteria with order handling and misc order statement" do
      let(:sort_criteria) { [%w[version desc], %w[start_date asc]] }

      it "adds the order handling (and the default order by id)" do
        sort_sql = <<~SQL
          array_remove(regexp_split_to_array(regexp_replace(substring(versions.name from '^[^a-zA-Z]+'), '\\D+', ' ', 'g'), ' '), '')::int[]
        SQL

        expect(subject)
          .to eq [["#{sort_sql} DESC NULLS LAST", "name DESC NULLS LAST"],
                  ["work_packages.start_date NULLS LAST"],
                  ["work_packages.id DESC"]]
      end
    end
  end
end
