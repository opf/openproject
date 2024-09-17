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

RSpec.describe Query::Results, "Grouping and summing integer/float custom field (Regression #53609)" do
  let(:query_results) do
    Query::Results.new query
  end
  let(:user) do
    create(:user,
           firstname: "user",
           lastname: "1",
           member_with_permissions: { project => [:view_work_packages] })
  end

  let(:float_custom_field) do
    create(:float_wp_custom_field, name: "MyFloat")
  end
  let(:int_custom_field) do
    create(:integer_wp_custom_field, name: "MyInt")
  end

  let(:type) { create(:type_standard, custom_fields: [float_custom_field, int_custom_field]) }
  let(:project) do
    create(:project,
           types: [type],
           work_package_custom_fields: [float_custom_field, int_custom_field])
  end
  let(:wp1) do
    create(:work_package,
           type:,
           project:,
           custom_values: { float_custom_field.id => "6.25", int_custom_field.id => "6" })
  end

  let(:wp2) do
    create(:work_package,
           type:,
           project:,
           custom_values: { float_custom_field.id => "15.0", int_custom_field.id => "1" })
  end

  let(:query) do
    build(:query,
          user:,
          show_hierarchies: false,
          project:).tap do |q|
      q.filters.clear
      q.column_names = ["id", "subject", int_custom_field.column_name, float_custom_field.column_name]
      q.group_by = int_custom_field.column_name
      q.display_sums = true
    end
  end

  let(:int_cf_column) { query.displayable_columns.detect { |c| c.name.to_s == int_custom_field.column_name } }
  let(:float_cf_column) { query.displayable_columns.detect { |c| c.name.to_s == float_custom_field.column_name } }

  before do
    login_as(user)
    wp1
    wp2
  end

  it "returns the correctly grouped sums" do
    expect(query_results.work_packages.pluck(:id))
      .to contain_exactly(wp1.id, wp2.id)

    expect(query_results.all_group_sums.keys).to contain_exactly(1, 6)
    expect(query_results.all_group_sums[1][float_cf_column]).to eq 15.0
    expect(query_results.all_group_sums[6][float_cf_column]).to eq 6.25

    expect(query_results.all_total_sums[float_cf_column]).to eq 21.25
    expect(query_results.all_total_sums[int_cf_column]).to eq 7
  end
end
