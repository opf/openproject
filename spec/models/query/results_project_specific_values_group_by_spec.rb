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

RSpec.describe Query::Results, "grouping by custom fields with project-specific values" do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  let(:query) do
    build(:query, user:, group_by: custom_field.column_name, show_hierarchies: false, project:).tap do |q|
      q.filters.clear
    end
  end
  let(:query_results) { described_class.new(query) }
  let(:group_titles) { query_results.work_package_count_by_group.keys.map { Array(it).map(&:to_s) } }
  let(:placeholder) { I18n.t(:label_custom_value_no_longer_available) }

  before do
    login_as(user)
  end

  shared_examples "hiding hierarchical items as group titles" do |factory|
    let(:custom_field) { create(factory, :project_specific_allowlist, types: [type]) }
    let(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
    let(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Oscorp") }

    before do
      create(:project_specific_value_restriction, project:, hierarchy_item: acme)
      create(:work_package, project:, type:, custom_values: { custom_field.id => acme.id.to_s })
      create(:work_package, project:, type:, custom_values: { custom_field.id => oscorp.id.to_s })
    end

    it "shows the placeholder as the title of the group the user may not see" do
      expect(group_titles).to contain_exactly([acme.to_s], [placeholder])
    end
  end

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B])
    end
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_a)
      create(:work_package, project:, type:, custom_values: { custom_field.id => option_a.id.to_s })
      create(:work_package, project:, type:, custom_values: { custom_field.id => option_b.id.to_s })
    end

    it "shows the placeholder as the title of the group the user may not see" do
      expect(group_titles).to contain_exactly(["A"], [placeholder])
    end

    it "keeps the work packages of the hidden value in their own group" do
      expect(query_results.work_package_count_by_group.values).to eq([1, 1])
    end
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    it_behaves_like "hiding hierarchical items as group titles", :hierarchy_wp_custom_field
  end

  context "for a weighted item list custom field", with_ee: [:weighted_item_lists] do
    it_behaves_like "hiding hierarchical items as group titles", :weighted_item_list_wp_custom_field
  end
end
