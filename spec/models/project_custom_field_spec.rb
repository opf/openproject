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

RSpec.describe ProjectCustomField do
  describe "activation in projects" do
    context "when creating a new 'is_for_all' project custom field" do
      let!(:project) { create(:project) }
      let!(:another_project) { create(:project) }

      it "activates the project custom fields in all projects" do
        project_custom_field = create(:project_custom_field, is_for_all: true)

        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: project.id)
        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: another_project.id)
      end
    end

    context "when creating a new project custom field" do
      let!(:project) { create(:project) }
      let!(:another_project) { create(:project) }

      it "activates the custom field in projects it is assigned to" do
        # Same activation rules apply for optional and required custom fields:
        optional_cf = create(:project_custom_field, projects: [project])
        required_cf = create(:project_custom_field, is_required: true, projects: [project])

        [optional_cf, required_cf].each do |cf|
          expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: cf.id,
                                                            project_id: project.id)
          expect(ProjectCustomFieldProjectMapping).not_to exist(custom_field_id: cf.id,
                                                                project_id: another_project.id)
        end
      end
    end

    context "when setting an existing project custom field to is_for_all" do
      let!(:project_custom_field) { create(:string_project_custom_field) } # optional now
      let!(:project) do
        create(:project, custom_field_values: { "#{project_custom_field.id}": "foo" })
      end
      let!(:another_project) { create(:project) } # not using the custom field

      it "activates for_all project custom fields in all projects where it is not already activated" do
        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: project.id)
        expect(ProjectCustomFieldProjectMapping).not_to exist(custom_field_id: project_custom_field.id,
                                                              project_id: another_project.id)

        project_custom_field.update!(is_for_all: true) # forced active now

        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: project.id)
        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: another_project.id)
      end

      it "does not disable project custom fields when set to optional" do
        project_custom_field.update!(is_for_all: true) # forced active now
        project_custom_field.update!(is_for_all: false) # optional again

        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: project.id)
        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: another_project.id)
      end

      it "does not create duplicate mappings" do
        project_custom_field.update!(is_for_all: true) # activated now

        # mapping existed before, should not be duplicated
        expect(ProjectCustomFieldProjectMapping.where(project_id: project.id,
                                                      custom_field_id: project_custom_field.id).count).to eq(1)
      end
    end

    context "when deleting a project custom field via section cascade" do
      let(:section) { create(:project_custom_field_section) }
      let!(:cf) { create(:project_custom_field, project_custom_field_section: section) }

      it "does not raise an error when the section is destroyed with its fields" do
        expect { section.destroy! }.not_to raise_error
      end
    end

    context "when deleting a project custom field" do
      let!(:project_custom_field) { create(:string_project_custom_field) }
      let!(:project) do
        create(:project, custom_field_values: { "#{project_custom_field.id}": "foo" })
      end

      it "deletes the project custom field mappings" do
        expect(ProjectCustomFieldProjectMapping).to exist(custom_field_id: project_custom_field.id,
                                                          project_id: project.id)

        project_custom_field.destroy

        expect(ProjectCustomFieldProjectMapping).not_to exist(custom_field_id: project_custom_field.id,
                                                              project_id: project.id)
      end
    end
  end

  describe "attribute_order integration" do
    let(:section) { create(:project_custom_field_section) }

    it "appends itself to the section's attribute_order on creation" do
      cf = create(:project_custom_field, project_custom_field_section: section)
      expect(section.reload.attribute_order).to include(cf.column_name)
    end

    it "orders fields by creation order when multiple are created" do
      cf1 = create(:project_custom_field, project_custom_field_section: section)
      cf2 = create(:project_custom_field, project_custom_field_section: section)
      expect(section.reload.attribute_order).to eq([cf1.column_name, cf2.column_name])
    end

    it "removes itself from the section's attribute_order on destruction" do
      cf = create(:project_custom_field, project_custom_field_section: section)
      cf.destroy
      expect(section.reload.attribute_order).not_to include(cf.column_name)
    end

    it "scopes positions per section (each section is independent)" do
      other_section = create(:project_custom_field_section)
      cf1 = create(:project_custom_field, project_custom_field_section: section)
      cf2 = create(:project_custom_field, project_custom_field_section: other_section)
      expect(section.reload.attribute_order).to eq([cf1.column_name])
      expect(other_section.reload.attribute_order).to eq([cf2.column_name])
    end
  end

  describe ".visible" do
    shared_let(:invisible_cf) { create(:string_project_custom_field, admin_only: true) }
    shared_let(:other_cf) { create(:string_project_custom_field) }
    shared_let(:project_cf) { create(:string_project_custom_field) }
    shared_let(:public_cf) { create(:string_project_custom_field) }
    shared_let(:other_project) do
      create(:project, custom_field_values: { "#{other_cf.id}": "foo" })
    end
    shared_let(:public_project) do
      create(:public_project, custom_field_values: { "#{public_cf.id}": "foo" })
    end
    shared_let(:project) do
      create(:project, custom_field_values: { "#{project_cf.id}": "foo" })
    end

    let(:current_user) { build_stubbed(:user) }

    subject { described_class.visible(current_user) }

    context "when admin" do
      let(:current_user) { build_stubbed(:admin) }

      it "returns all custom fields" do
        expect(subject).to contain_exactly(invisible_cf, other_cf, project_cf, public_cf)
      end
    end

    context "when user with add_project permission" do
      before do
        mock_permissions_for(current_user) do |mock|
          mock.allow_globally :add_project
        end
      end

      it "returns all visible custom fields" do
        expect(subject).to contain_exactly(other_cf, project_cf, public_cf)
      end
    end

    context "when project member" do
      context "with select_project_custom_fields permission" do
        let(:permissions) { %i(select_project_custom_fields) }

        before do
          mock_permissions_for(current_user) do |mock|
            mock.allow_in_project *permissions, project:
          end
        end

        it "returns all visible custom fields" do
          expect(subject).to contain_exactly(other_cf, project_cf, public_cf)
        end
      end

      context "without view_project_attributes permission" do
        let(:role) { create(:project_role, permissions:) }
        let(:current_user) { create(:user, member_with_roles: { project => role }) }
        let(:permissions) { [] }

        it "returns nothing" do
          expect(subject).to be_empty
        end
      end

      context "with view_project_attributes permission" do
        let(:role) { create(:project_role, permissions:) }
        let(:current_user) { create(:user, member_with_roles: { project => role }) }
        let(:permissions) { %i(view_project_attributes) }

        it "returns project_cf" do
          expect(subject).to contain_exactly(project_cf)
        end
      end
    end
  end
end
