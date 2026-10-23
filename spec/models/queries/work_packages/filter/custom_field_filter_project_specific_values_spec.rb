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

RSpec.describe Queries::WorkPackages::Filter::CustomFieldFilter, "with project-specific values" do
  shared_let(:type) { create(:type) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages] }) }

  current_user { user }

  let(:query) { build_stubbed(:query, project: query_project) }
  let(:query_project) { project }
  let(:filter) { described_class.from_custom_field!(custom_field:, context: query) }

  shared_examples "filtering by visible hierarchical items" do |factory|
    let(:custom_field) { create(factory, :project_specific_allowlist, types: [type]) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
    let!(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Oscorp") }

    before do
      create(:project_specific_value_restriction, project:, hierarchy_item: acme)
    end

    it "only allows the visible items" do
      expect(filter.allowed_values.map(&:last)).to eq([acme.id])
    end

    it "only resolves the visible items as value objects" do
      filter.values = [acme.id.to_s, oscorp.id.to_s]

      expect(filter.value_objects.map(&:id)).to eq([acme.id])
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
    end

    it "only allows the visible options" do
      expect(filter.allowed_values).to eq([["A", option_a.id.to_s]])
    end

    it "only resolves the visible options as value objects" do
      filter.values = [option_a.id.to_s, option_b.id.to_s]

      expect(filter.value_objects).to contain_exactly(option_a)
    end

    context "in a global query" do
      let(:query_project) { nil }

      it "only allows the visible options" do
        expect(filter.allowed_values).to eq([["A", option_a.id.to_s]])
      end
    end
  end

  context "for a hierarchy custom field", with_ee: [:custom_field_hierarchies] do
    it_behaves_like "filtering by visible hierarchical items", :hierarchy_wp_custom_field
  end

  context "for a weighted item list custom field", with_ee: [:weighted_item_lists] do
    it_behaves_like "filtering by visible hierarchical items", :weighted_item_list_wp_custom_field
  end
end
