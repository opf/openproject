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

RSpec.describe WorkPackageTypes::FormConfiguration::QuerySummary do
  current_user { create(:admin) }

  let(:query) { Query.new(column_names: %w[subject id], sort_criteria: [%w[id asc]]) }

  it "shows the relation and columns without default sorting or duplicate filters" do
    query.add_filter("parent", "=", ["{id}"])
    before = query.attributes.except("filters").deep_dup
    filters_before = query.filters.map { [it.name, it.operator, it.values.dup] }
    expect(described_class.new(query).rows).to eq([
                                                    { label: "Relation type", values: ["Children"] },
                                                    { label: "Columns", values: ["Subject, ID"] }
                                                  ])
    expect(query.attributes.except("filters")).to eq(before)
    expect(query.filters.map { [it.name, it.operator, it.values] }).to eq(filters_before)
  end

  Relation::TYPES.each do |name, definition|
    it "uses the inverse label for #{name}" do
      query.add_filter(name, "=", ["{id}"])
      expect(described_class.new(query).rows.first[:values])
        .to eq([I18n.t(definition[:sym_name]).capitalize])
    end
  end

  it "matches the editor's inverted follows label" do
    query.add_filter("follows", "=", ["{id}"])
    expect(described_class.new(query).rows.first[:values]).to eq(["Precedes"])
  end

  it "recognizes both current and legacy tokens added by query sanitization" do
    query.add_filter("parent", "=", ["{id}", "templated"])
    expect(described_class.new(query).rows.first[:values]).to eq(["Children"])
    expect(described_class.new(query).rows.pluck(:label)).not_to include("Filters")
  end

  it "keeps ordinary relation filters in the filter list" do
    wp = create(:work_package)
    query.add_filter("parent", "=", [wp.id.to_s])
    expect(described_class.new(query).rows.pluck(:label)).to include("Filters")
    expect(described_class.new(query).rows.first[:values]).to eq(["None"])
  end

  it "retains column and sort order including unavailable columns" do
    query.column_names = %w[id missing subject]
    query.sort_criteria = [%w[subject desc], %w[missing asc]]
    rows = described_class.new(query).rows
    expect(rows.second[:values]).to eq(["ID, Unavailable value, Subject"])
    expect(rows.last).to eq(label: "Sorting", values: ["Subject (Descending)", "Unavailable value (Ascending)"])
  end

  it "keeps baseline instants in stored order" do
    query.timestamps = [Timestamp.new("P1W"), Timestamp.now]
    expect(described_class.new(query).rows.last).to eq(label: "Baseline", values: ["1 week ago", "Current"])
  end

  it "represents a missing query explicitly" do
    expect(described_class.new(nil).rows)
      .to eq([{ label: "Configuration", values: ["Configuration unavailable"] }])
  end
end
