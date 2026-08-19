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

require "rails_helper"

RSpec.describe ProjectCustomFieldSection do
  describe ".with_available_fields_for" do
    let(:project) { create(:project) }
    let(:other_project) { create(:project) }
    # Admin sees all non-admin-only CFs regardless of project membership.
    let(:admin) { create(:admin) }

    let!(:section_a) { create(:project_custom_field_section, name: "Section A", position: 1) }
    let!(:section_b) { create(:project_custom_field_section, name: "Section B", position: 2) }
    # Creation order determines initial attribute_order within each section.
    let!(:cf_a1) do
      create(:string_project_custom_field, name: "A1", project_custom_field_section: section_a, projects: [project])
    end
    let!(:cf_a2) do
      create(:string_project_custom_field, name: "A2", project_custom_field_section: section_a, projects: [project])
    end
    let!(:cf_b1) do
      create(:string_project_custom_field, name: "B1", project_custom_field_section: section_b, projects: [project])
    end

    before { allow(User).to receive(:current).and_return(admin) }

    it "returns one [section, cfs] pair per section that has available CFs" do
      result = described_class.with_available_fields_for(project)
      expect(result.size).to eq(2)
    end

    it "orders pairs by section position" do
      result = described_class.with_available_fields_for(project)
      expect(result.map(&:first)).to eq([section_a, section_b])
    end

    it "orders CFs within a section by attribute_order" do
      result = described_class.with_available_fields_for(project)
      expect(result.find { |s, _| s == section_a }.last).to eq([cf_a1, cf_a2])
    end

    it "respects a manually reordered attribute_order" do
      section_a.update_column(:attribute_order, [cf_a2.column_name, cf_a1.column_name])
      result = described_class.with_available_fields_for(project)
      expect(result.find { |s, _| s == section_a }.last).to eq([cf_a2, cf_a1])
    end

    it "excludes CFs not mapped to the project" do
      unmapped = create(:string_project_custom_field, name: "Unmapped",
                                                      project_custom_field_section: section_a,
                                                      projects: [other_project])
      result = described_class.with_available_fields_for(project)
      expect(result.flat_map(&:last)).not_to include(unmapped)
    end

    it "excludes sections that have no CFs available for the project" do
      empty_section = create(:project_custom_field_section, name: "Empty", position: 3)
      create(:string_project_custom_field, name: "Other",
                                           project_custom_field_section: empty_section,
                                           projects: [other_project])
      result = described_class.with_available_fields_for(project)
      expect(result.map(&:first)).not_to include(empty_section)
    end

    it "returns an empty array when the project has no available CFs" do
      expect(described_class.with_available_fields_for(other_project)).to eq([])
    end

    context "with admin_only CFs" do
      let!(:admin_cf) do
        create(:string_project_custom_field, name: "Secret",
                                             project_custom_field_section: section_a,
                                             projects: [project],
                                             admin_only: true)
      end

      context "when viewer is not an admin" do
        let(:non_admin) do
          create(:user, member_with_permissions: { project => [:select_project_custom_fields] })
        end

        before { allow(User).to receive(:current).and_return(non_admin) }

        it "excludes admin_only CFs" do
          result = described_class.with_available_fields_for(project)
          expect(result.flat_map(&:last)).not_to include(admin_cf)
        end

        it "still returns non-admin CFs in the same section" do
          result = described_class.with_available_fields_for(project)
          expect(result.flat_map(&:last)).to include(cf_a1, cf_a2)
        end
      end

      context "when viewer is an admin" do
        it "includes admin_only CFs" do
          result = described_class.with_available_fields_for(project)
          expect(result.flat_map(&:last)).to include(admin_cf)
        end
      end
    end
  end

  describe ".grouped_in_order" do
    let!(:section_a) { create(:project_custom_field_section, name: "Section A", position: 1) }
    let!(:section_b) { create(:project_custom_field_section, name: "Section B", position: 2) }
    let!(:cf_a1) { create(:string_project_custom_field, name: "A1", project_custom_field_section: section_a) }
    let!(:cf_a2) { create(:string_project_custom_field, name: "A2", project_custom_field_section: section_a) }
    let!(:cf_b1) { create(:string_project_custom_field, name: "B1", project_custom_field_section: section_b) }

    it "orders sections by position and fields by attribute_order" do
      result = described_class.grouped_in_order(ProjectCustomField.where(id: [cf_a1, cf_a2, cf_b1]))
      expect(result.map(&:first)).to eq([section_a, section_b])
      expect(result.find { |s, _| s == section_a }.last).to eq([cf_a1, cf_a2])
    end

    it "respects a manually reordered attribute_order" do
      section_a.update_column(:attribute_order, [cf_a2.column_name, cf_a1.column_name])
      result = described_class.grouped_in_order(ProjectCustomField.where(id: [cf_a1, cf_a2]))
      expect(result.find { |s, _| s == section_a }.last).to eq([cf_a2, cf_a1])
    end

    it "restricts to the given custom fields" do
      result = described_class.grouped_in_order(ProjectCustomField.where(id: [cf_a1]))
      expect(result.map(&:first)).to eq([section_a])
      expect(result.flat_map(&:last)).to eq([cf_a1])
    end

    it "returns an empty array for an empty relation" do
      expect(described_class.grouped_in_order(ProjectCustomField.none)).to eq([])
    end
  end
end
