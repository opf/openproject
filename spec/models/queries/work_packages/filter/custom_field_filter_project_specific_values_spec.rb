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
  shared_let(:other_project) { create(:project, types: [type]) }
  shared_let(:subproject) { create(:project, parent: project, types: [type]) }
  shared_let(:hidden_subproject) { create(:project, parent: project, types: [type]) }
  shared_let(:unrelated_project) { create(:project, types: [type]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_work_packages],
                                             other_project => %i[view_work_packages],
                                             subproject => %i[view_work_packages] })
  end

  current_user { user }

  let(:query) { build_stubbed(:query, project: query_project, include_subprojects:) }
  let(:query_project) { project }
  let(:include_subprojects) { true }
  let(:filter) { described_class.from_custom_field!(custom_field:, context: query) }

  shared_examples "filtering by visible hierarchical items" do |factory|
    let(:custom_field) { create(factory, :project_specific_allowlist, types: [type]) }
    let!(:acme) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Acme") }
    let!(:oscorp) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Oscorp") }
    let!(:umbrella) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Umbrella") }
    let!(:cyberdyne) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Cyberdyne") }
    let!(:tyrell) { create(:hierarchy_item, parent: custom_field.hierarchy_root, label: "Tyrell") }

    before do
      create(:project_specific_value_restriction, project:, hierarchy_item: acme)
      create(:project_specific_value_restriction, project: other_project, hierarchy_item: oscorp)
      create(:project_specific_value_restriction, project: subproject, hierarchy_item: umbrella)
      create(:project_specific_value_restriction, project: hidden_subproject, hierarchy_item: cyberdyne)
      create(:project_specific_value_restriction, project: unrelated_project, hierarchy_item: tyrell)
    end

    it "only allows the items visible in the project and its visible subprojects" do
      expect(filter.allowed_values.map(&:last)).to contain_exactly(acme.id, umbrella.id)
    end

    it "only resolves the items visible in the project and its visible subprojects as value objects" do
      filter.values = [acme.id, oscorp.id, umbrella.id, cyberdyne.id, tyrell.id].map(&:to_s)

      expect(filter.value_objects.map(&:id)).to contain_exactly(acme.id, umbrella.id)
    end

    context "in a project query without subprojects" do
      let(:include_subprojects) { false }

      it "only allows the items visible in the project" do
        expect(filter.allowed_values.map(&:last)).to contain_exactly(acme.id)
      end
    end

    context "in a global query" do
      let(:query_project) { nil }

      it "allows the items visible in any project of the user" do
        expect(filter.allowed_values.map(&:last)).to contain_exactly(acme.id, oscorp.id, umbrella.id)
      end
    end
  end

  context "for a list custom field" do
    let(:custom_field) do
      create(:list_wp_custom_field, :project_specific_allowlist, types: [type], possible_values: %w[A B C D E])
    end
    let(:option_a) { custom_field.custom_options.find_by!(value: "A") }
    let(:option_b) { custom_field.custom_options.find_by!(value: "B") }
    let(:option_c) { custom_field.custom_options.find_by!(value: "C") }
    let(:option_d) { custom_field.custom_options.find_by!(value: "D") }
    let(:option_e) { custom_field.custom_options.find_by!(value: "E") }

    before do
      create(:project_specific_value_restriction, project:, custom_option: option_a)
      create(:project_specific_value_restriction, project: other_project, custom_option: option_b)
      create(:project_specific_value_restriction, project: subproject, custom_option: option_c)
      create(:project_specific_value_restriction, project: hidden_subproject, custom_option: option_d)
      create(:project_specific_value_restriction, project: unrelated_project, custom_option: option_e)
    end

    it "only allows the options visible in the project and its visible subprojects" do
      expect(filter.allowed_values).to contain_exactly(["A", option_a.id.to_s], ["C", option_c.id.to_s])
    end

    it "only resolves the options visible in the project and its visible subprojects as value objects" do
      filter.values = [option_a, option_b, option_c, option_d, option_e].map { |option| option.id.to_s }

      expect(filter.value_objects).to contain_exactly(option_a, option_c)
    end

    context "in a project query without subprojects" do
      let(:include_subprojects) { false }

      it "only allows the options visible in the project" do
        expect(filter.allowed_values).to contain_exactly(["A", option_a.id.to_s])
      end
    end

    context "in a global query" do
      let(:query_project) { nil }

      it "allows the options visible in any project of the user" do
        expect(filter.allowed_values)
          .to contain_exactly(["A", option_a.id.to_s], ["B", option_b.id.to_s], ["C", option_c.id.to_s])
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
