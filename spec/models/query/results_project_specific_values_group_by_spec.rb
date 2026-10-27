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

RSpec.describe Query::Results, "grouping and sorting by custom fields with project-specific values" do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  let(:group_by) { nil }
  let(:sort_criteria) { [] }
  let(:query) do
    build(:query, user:, group_by:, show_hierarchies: false, project:).tap do |q|
      q.filters.clear
      q.sort_criteria = sort_criteria
    end
  end
  let(:query_results) { described_class.new(query) }
  let(:group_counts) do
    query_results.work_package_count_by_group.transform_keys { |key| Array(key).map(&:to_s) }
  end
  let(:placeholder) { I18n.t(:label_custom_value_no_longer_available) }

  before do
    login_as(user)
  end

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B C])
    end
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
    let(:option_c) { custom_field.custom_options.find_by!(value: "C") }

    let!(:work_package_a) { create(:work_package, project:, type:, custom_values: { custom_field.id => option_a.id.to_s }) }
    let!(:work_package_b) { create(:work_package, project:, type:, custom_values: { custom_field.id => option_b.id.to_s }) }
    let!(:work_package_c) { create(:work_package, project:, type:, custom_values: { custom_field.id => option_c.id.to_s }) }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_a)
    end

    context "when grouping" do
      let(:group_by) { custom_field.column_name }

      it "groups all values no longer available in the project together under the placeholder" do
        expect(group_counts).to eq(["A"] => 1, [placeholder] => 2)
      end
    end

    context "when sorting" do
      let(:sort_criteria) { [[custom_field.column_name, "asc"]] }

      it "sorts the values no longer available in the project after the others" do
        expect(query_results.work_packages.first).to eq(work_package_a)
      end
    end
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    let(:custom_field) { create(:hierarchy_wp_custom_field, :project_specific_allowlist, types: [type]) }
    let(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
    let(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Oscorp") }
    let(:wayne) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Wayne") }
    let(:group_by) { custom_field.column_name }

    before do
      create(:project_specific_value_restriction, project:, hierarchy_item: acme)
      create(:work_package, project:, type:, custom_values: { custom_field.id => acme.id.to_s })
      create(:work_package, project:, type:, custom_values: { custom_field.id => oscorp.id.to_s })
      create(:work_package, project:, type:, custom_values: { custom_field.id => wayne.id.to_s })
    end

    it "groups all items no longer available in the project together under the placeholder" do
      expect(group_counts).to eq([acme.to_s] => 1, [placeholder] => 2)
    end
  end
end
