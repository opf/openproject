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

RSpec.describe Query::Results, "Summing groups of a list or hierarchy custom field" do
  let(:user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }
  let(:float_custom_field) { create(:float_wp_custom_field) }
  let(:type) { create(:type_task, custom_fields: [float_custom_field, group_custom_field]) }
  let(:project) do
    create(:project, types: [type], work_package_custom_fields: [float_custom_field, group_custom_field])
  end
  let(:query) do
    build(:query, user:, show_hierarchies: false, project:).tap do |q|
      q.filters.clear
      q.column_names = ["id", float_custom_field.column_name]
      q.group_by = group_custom_field.column_name
      q.display_sums = true
    end
  end
  let(:query_results) { described_class.new(query) }
  let(:float_column) { query.displayable_columns.detect { |c| c.name.to_s == float_custom_field.column_name } }

  shared_examples "sums reachable from the counted groups" do
    before do
      login_as(user)
      create(:work_package, type:, project:, custom_values: { float_custom_field.id => "1.5", group_custom_field.id => foo.id })
      create(:work_package, type:, project:, custom_values: { float_custom_field.id => "2.5", group_custom_field.id => foo.id })
    end

    it "finds a group's sums by the key its count is listed under, as the PDF report does" do
      group = query_results.work_package_count_by_group.keys.find(&:present?)

      expect(query_results.all_group_sums[group][float_column]).to eq 4.0
    end
  end

  context "for a list custom field" do
    let(:group_custom_field) { create(:list_wp_custom_field, possible_values: %w[Foo]) }
    let(:foo) { group_custom_field.possible_values.first }

    it_behaves_like "sums reachable from the counted groups"
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    let(:group_custom_field) { create(:hierarchy_wp_custom_field) }
    let(:foo) { create(:hierarchy_item, parent: group_custom_field.hierarchy_root, label: "Foo") }

    it_behaves_like "sums reachable from the counted groups"
  end
end
