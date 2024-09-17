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
RSpec.describe Project, "customizable" do
  let!(:section) { create(:project_custom_field_section) }

  let!(:bool_custom_field) do
    create(:boolean_project_custom_field, project_custom_field_section: section)
  end
  let!(:text_custom_field) do
    create(:text_project_custom_field, project_custom_field_section: section)
  end
  let!(:list_custom_field) do
    create(:list_project_custom_field, project_custom_field_section: section)
  end
  let(:user) { build_stubbed(:admin) }

  before do
    allow(User).to receive(:current).and_return user
  end

  context "when not persisted" do
    let(:project) { build(:project) }

    describe "#available_custom_fields" do
      it "returns all existing project custom fields as available custom fields" do
        expect(project.project_custom_field_project_mappings)
          .to be_empty
        expect(project.project_custom_fields)
          .to be_empty
        # but:
        expect(project.available_custom_fields)
          .to contain_exactly(bool_custom_field, text_custom_field, list_custom_field)
      end
    end
  end

  context "when persisted" do
    let(:project) { create(:project) }

    describe "#available_custom_fields" do
      it "returns only mapped project custom fields as available custom fields" do
        expect(project.project_custom_field_project_mappings)
          .to be_empty
        expect(project.project_custom_fields)
          .to be_empty
        # and thus:
        expect(project.available_custom_fields)
          .to be_empty

        project.project_custom_fields << bool_custom_field

        expect(project.available_custom_fields)
          .to contain_exactly(bool_custom_field)
      end

      context "with a custom field activated in different projects " \
              "and the user has view_project_attributes permission in one of the project " \
              "and with a required custom field" do
        let(:other_project) { create(:project) }
        let!(:project_cf) do
          # This custom field is enabled in both project and other_project to test that there is no
          # bleeding of enabled custom fields between 2 projects.
          create(:project_custom_field_project_mapping, project:).project_custom_field.tap do |pcf|
            create(:project_custom_field_project_mapping,
                   project: other_project,
                   project_custom_field: pcf)
          end
        end

        let!(:required_cf) do
          create(:string_project_custom_field, is_required: true)
        end

        let(:user) do
          create(:user, member_with_permissions: {
                   project => [],
                   other_project => %i(view_project_attributes)
                 })
        end

        it "returns available_custom_fields only for the other_project" do
          expect(project.available_custom_fields)
            .to be_empty

          expect(other_project.available_custom_fields)
            .to contain_exactly(project_cf, required_cf)
        end
      end
    end

    describe "#custom_field_values and #custom_value_for" do
      context "when no custom fields are mapped to this project" do
        it "#custom_value_for returns nil" do
          expect(project.custom_value_for(text_custom_field))
            .to be_nil
          expect(project.custom_value_for(bool_custom_field))
            .to be_nil
          expect(project.custom_value_for(list_custom_field))
            .to be_nil
        end

        it "#custom_field_values returns an empty hash" do
          expect(project.custom_field_values)
            .to be_empty
        end
      end

      context "when custom fields are mapped to this project" do
        before do
          project.project_custom_fields << [text_custom_field, bool_custom_field]
        end

        it "#custom_field_values returns a hash of mapped custom fields with nil values" do
          text_custom_field_custom_field_value = project.custom_field_values.find do |custom_value|
            custom_value.custom_field_id == text_custom_field.id
          end

          expect(text_custom_field_custom_field_value).to be_present
          expect(text_custom_field_custom_field_value.value).to be_nil

          bool_custom_field_custom_field_value = project.custom_field_values.find do |custom_value|
            custom_value.custom_field_id == bool_custom_field.id
          end

          expect(bool_custom_field_custom_field_value).to be_present
          expect(bool_custom_field_custom_field_value.value).to be_nil
        end

        context "when values are set for mapped custom fields" do
          before do
            project.custom_field_values = {
              text_custom_field.id => "foo",
              bool_custom_field.id => true
            }
          end

          it "#custom_value_for returns the set custom values" do
            expect(project.custom_value_for(text_custom_field).typed_value)
              .to eq("foo")
            expect(project.custom_value_for(bool_custom_field).typed_value)
              .to be_truthy
            expect(project.custom_value_for(list_custom_field).typed_value)
              .to be_nil
          end

          it "#custom_field_values returns a hash of mapped custom fields with their set values" do
            expect(project.custom_field_values.find do |custom_value|
                     custom_value.custom_field_id == text_custom_field.id
                   end.typed_value)
              .to eq("foo")

            expect(project.custom_field_values.find do |custom_value|
                     custom_value.custom_field_id == bool_custom_field.id
                   end.typed_value)
              .to be_truthy
          end
        end
      end
    end
  end

  context "when creating with custom field values" do
    let(:project) do
      create(:project, custom_field_values: {
               text_custom_field.id => "foo",
               bool_custom_field.id => true
             })
    end

    it "saves the custom field values properly" do
      expect(project.custom_value_for(text_custom_field).typed_value)
        .to eq("foo")
      expect(project.custom_value_for(bool_custom_field).typed_value)
        .to be_truthy
    end

    it "enables fields with provided values and disables fields with none" do
      # list_custom_field is not provided, thus it should not be enabled
      expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
          .to contain_exactly(text_custom_field.id, bool_custom_field.id)
      expect(project.project_custom_fields)
        .to contain_exactly(text_custom_field, bool_custom_field)
    end

    context "with correct validation" do
      let(:another_section) { create(:project_custom_field_section) }

      let!(:required_text_custom_field) do
        create(:text_project_custom_field,
               is_required: true,
               project_custom_field_section: another_section)
      end

      it "validates all custom values if not scoped to a section" do
        project = build(:project, custom_field_values: {
                          text_custom_field.id => "foo",
                          bool_custom_field.id => true
                        })

        expect(project).not_to be_valid

        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "validates only custom values of a section if section scope is provided while updating" do
        project = create(:project, custom_field_values: {
                           text_custom_field.id => "foo",
                           bool_custom_field.id => true,
                           required_text_custom_field.id => "bar"
                         })

        expect(project).to be_valid

        # after a project is created, a new required custom field is added
        # which gets automatically activated for all projects
        create(:text_project_custom_field,
               is_required: true,
               project_custom_field_section: another_section)

        # thus, the project is invalid in total
        expect(project.reload).not_to be_valid
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid)

        # but we still want to allow updating other sections without invalid required custom field values
        # by limiting the validation scope to a section temporarily
        project._limit_custom_fields_validation_to_section_id = section.id

        expect(project).to be_valid

        expect { project.save! }.not_to raise_error

        # Removing the section scoped limitation should result a validation error again.
        project._limit_custom_fields_validation_to_section_id = nil
        expect { project.save! }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  context "when updating with custom field values" do
    let!(:project) { create(:project) }

    shared_examples "implicitly enabled and saved custom values" do
      it "enables fields with provided values" do
        # list_custom_field is not provided, thus it should not be enabled
        expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
            .to contain_exactly(text_custom_field.id, bool_custom_field.id)
        expect(project.project_custom_fields)
          .to contain_exactly(text_custom_field, bool_custom_field)
      end

      it "saves the custom field values properly" do
        expect(project.custom_value_for(text_custom_field).typed_value)
          .to eq("foo")
        expect(project.custom_value_for(bool_custom_field).typed_value)
          .to be_truthy
      end
    end

    context "with #update method" do
      before do
        project.update(custom_field_values: {
                         text_custom_field.id => "foo",
                         bool_custom_field.id => true
                       })
      end

      it_behaves_like "implicitly enabled and saved custom values"
    end

    context "with #update! method" do
      before do
        project.update!(custom_field_values: {
                          text_custom_field.id => "foo",
                          bool_custom_field.id => true
                        })
      end

      it_behaves_like "implicitly enabled and saved custom values"
    end

    context "with #custom_field_values= method" do
      before do
        project.custom_field_values = {
          text_custom_field.id => "foo",
          bool_custom_field.id => true
        }

        project.save!
      end

      it_behaves_like "implicitly enabled and saved custom values"
    end

    it "does not re-enable fields without new value which have been disabled in the past (regression)" do
      project.update!(custom_field_values: {
                        text_custom_field.id => "foo",
                        bool_custom_field.id => true
                      })

      expect(project.reload.project_custom_fields)
        .to contain_exactly(text_custom_field, bool_custom_field)

      project.project_custom_field_project_mappings.find_by(custom_field_id: text_custom_field.id).destroy

      expect(project.reload.project_custom_fields)
        .to contain_exactly(bool_custom_field)

      project.update!(custom_field_values: {
                        bool_custom_field.id => true
                      })

      expect(project.reload.project_custom_fields)
        .to contain_exactly(bool_custom_field)
    end

    context "with correct handling of custom fields with default values" do
      let!(:text_custom_field_with_default) do
        create(:text_project_custom_field,
               default_value: "default",
               project_custom_field_section: section)
      end

      it "does not activate custom fields with default values if not explicitly set to a value" do
        project.update!(custom_field_values: {
                          text_custom_field.id => "bar",
                          bool_custom_field.id => false
                        })

        # text_custom_field_with_default is not provided, thus it should not be enabled (in contrast to creation)
        expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
          .to contain_exactly(text_custom_field.id, bool_custom_field.id)
      end

      it "does activate custom fields with default values if explicitly set to a value" do
        project.update!(custom_field_values: {
                          text_custom_field.id => "bar",
                          bool_custom_field.id => false,
                          text_custom_field_with_default.id => "overwritten default"
                        })

        # text_custom_field_with_default is not provided, thus it should not be enabled (in contrast to creation)
        expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
          .to contain_exactly(text_custom_field.id, bool_custom_field.id, text_custom_field_with_default.id)
      end
    end

    it "does re-enable fields with new value which have been disabled in the past" do
      project.update!(custom_field_values: {
                        text_custom_field.id => "foo",
                        bool_custom_field.id => true
                      })

      expect(project.reload.project_custom_fields)
        .to contain_exactly(text_custom_field, bool_custom_field)

      project.project_custom_field_project_mappings.find_by(custom_field_id: text_custom_field.id).destroy

      expect(project.reload.project_custom_fields)
        .to contain_exactly(bool_custom_field)

      project.update!(custom_field_values: {
                        text_custom_field.id => "bar"
                      })

      expect(project.reload.project_custom_fields)
        .to contain_exactly(text_custom_field, bool_custom_field)

      expect(project.custom_value_for(text_custom_field).typed_value)
        .to eq("bar")
    end
  end

  context "when updating with custom field setter methods (API approach)" do
    let(:project) { create(:project) }

    shared_examples "implicitly enabled and saved custom values" do
      it "enables fields with provided values" do
        # list_custom_field is not provided, thus it should not be enabled
        expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
            .to contain_exactly(text_custom_field.id, bool_custom_field.id)
        expect(project.project_custom_fields)
          .to contain_exactly(text_custom_field, bool_custom_field)
      end

      it "saves the custom field values properly" do
        expect(project.custom_value_for(text_custom_field).typed_value)
          .to eq("foo")
        expect(project.custom_value_for(bool_custom_field).typed_value)
          .to be_truthy

        # or via getter methods:

        expect(project.send(:"custom_field_#{text_custom_field.id}")).to eq("foo")
        expect(project.send(:"custom_field_#{bool_custom_field.id}")).to be_truthy
      end
    end

    context "when setting a value for a disabled custom field" do
      before do
        project.send(:"custom_field_#{text_custom_field.id}=", "foo")
        project.send(:"custom_field_#{bool_custom_field.id}=", true)
        project.save!
      end

      it_behaves_like "implicitly enabled and saved custom values"
    end
  end
end
