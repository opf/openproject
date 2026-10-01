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
require "services/base_services/behaves_like_update_service"

RSpec.describe Projects::UpdateService, type: :model do
  it_behaves_like "BaseServices update service" do
    let!(:model_instance) do
      build_stubbed(:project, :with_status)
    end

    it "sends an update notification" do
      expect(OpenProject::Notifications)
        .to(receive(:send))
        .with(OpenProject::Events::PROJECT_UPDATED, project: model_instance)

      subject
    end

    context "if the identifier is altered" do
      let(:call_attributes) { { identifier: "Some identifier" } }

      before do
        allow(model_instance)
          .to(receive(:changes))
          .and_return("identifier" => %w(lorem ipsum))
      end

      it "sends the notification" do
        expect(OpenProject::Notifications)
          .to(receive(:send))
          .with(OpenProject::Events::PROJECT_UPDATED, project: model_instance)
        expect(OpenProject::Notifications)
          .to(receive(:send))
          .with(OpenProject::Events::PROJECT_RENAMED, project: model_instance)

        subject
      end
    end

    context "if the parent is altered" do
      before do
        allow(model_instance)
          .to(receive(:changes))
          .and_return("parent_id" => [nil, 5])
      end

      it "updates the versions associated with the work packages" do
        expect(WorkPackage)
          .to(receive(:update_versions_from_hierarchy_change))
          .with(model_instance)

        subject
      end
    end

    describe "calculated custom fields", with_ee: %i[calculated_values] do
      let(:project) { create(:project) }
      let!(:model_instance) { project }
      # Remove the set_attributes_service mocking to use the real service.
      let!(:set_attributes_service) { nil }
      let(:contract_class) { EmptyContract }

      before do
        # Both User.current and :select_project_custom_fields for ProjectCustomField.visible
        User.current = user
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:select_project_custom_fields, project:)
        end
      end

      using CustomFieldFormulaReferencing

      context "when trying to explicitly set values of calculated custom fields" do
        let!(:cf_static) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated) do
          create(:calculated_value_project_custom_field,
                 projects: [project], formula: "1 + 1")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_static.id => 3,
              cf_calculated.id => 4
            }
          }
        end

        before do
          create(:custom_value, customized: project, custom_field: cf_static, value: -5)
          create(:custom_value, customized: project, custom_field: cf_calculated, value: -6)
        end

        it "doesn't allow to assign calculated value" do
          expect(subject.result.custom_value_attributes).to eq(cf_static.id => "3", cf_calculated.id => "-6")
        end
      end

      context "when setting value of field referenced in calculated values" do
        let!(:cf_static) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated1) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_static} * 7")
        end
        let!(:cf_calculated2) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_calculated1} * 11")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_static.id => 3
            }
          }
        end

        before do
          create(:custom_value, customized: project, custom_field: cf_static, value: -5)
          create(:custom_value, customized: project, custom_field: cf_calculated1, value: -6)
          create(:custom_value, customized: project, custom_field: cf_calculated2, value: -6)
        end

        it "calculates all values" do
          expect(subject.result.custom_value_attributes).to eq(
            cf_static.id => "3",
            cf_calculated1.id => "21",
            cf_calculated2.id => "231"
          )
        end
      end

      context "when removing value of field referenced in calculated values" do
        let!(:cf_static) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated1) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_static} * 7")
        end
        let!(:cf_calculated2) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_calculated1} * 11")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_static.id => nil
            }
          }
        end

        before do
          create(:custom_value, customized: project, custom_field: cf_static, value: -5)
          create(:custom_value, customized: project, custom_field: cf_calculated1, value: -6)
          create(:custom_value, customized: project, custom_field: cf_calculated2, value: -6)
        end

        it "blanks all values" do
          expect(subject.result.custom_value_attributes).to eq(
            cf_static.id => nil,
            cf_calculated1.id => nil,
            cf_calculated2.id => nil
          )
        end
      end

      context "when setting value of only part of fields referenced in calculated values" do
        let!(:cf_a) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_b) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_c) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated1) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project], formula: "#{cf_a} * 7")
        end
        let!(:cf_calculated2) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project], formula: "#{cf_b} * 11")
        end
        let!(:cf_calculated3) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project], formula: "#{cf_c} * 13")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_a.id => 3,
              cf_b.id => -5
            }
          }
        end

        before do
          create(:custom_value, customized: project, custom_field: cf_a, value: -5)
          create(:custom_value, customized: project, custom_field: cf_b, value: -5)
          create(:custom_value, customized: project, custom_field: cf_c, value: -5)
          create(:custom_value, customized: project, custom_field: cf_calculated1, value: -6)
          create(:custom_value, customized: project, custom_field: cf_calculated2, value: -6)
          create(:custom_value, customized: project, custom_field: cf_calculated3, value: -6)
        end

        it "calculates only values referenced by changed field" do
          expect(subject.result.custom_value_attributes).to eq(
            cf_a.id => "3",
            cf_b.id => "-5",
            cf_c.id => "-5",
            cf_calculated1.id => "21",
            cf_calculated2.id => "-6",
            cf_calculated3.id => "-6"
          )
        end
      end

      context "when intermediate calculated value field is not enabled" do
        let!(:cf_static) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated1) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_static} * 7")
        end
        let!(:cf_calculated2) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 formula: "#{cf_calculated1} * 11")
        end
        let!(:cf_calculated3) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_calculated2} * 13")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_static.id => 3
            }
          }
        end

        before do
          # using update_columns to prevent auto enabling for the project
          create(:custom_value, customized: project, custom_field: cf_static).update_columns(value: -5)
          [cf_calculated1, cf_calculated2, cf_calculated3].each do |custom_field|
            create(:custom_value, customized: project, custom_field:).update_columns(value: -6)
          end
        end

        it "calculates only accessible values" do
          expect(subject.result.custom_value_attributes).to eq(
            cf_static.id => "3",
            cf_calculated1.id => "21",
            cf_calculated3.id => "-6"
          )

          expect(subject.result.custom_value_attributes(all: true)).to eq(
            cf_static.id => "3",
            cf_calculated1.id => "21",
            cf_calculated2.id => "-6",
            cf_calculated3.id => "-6"
          )
        end
      end

      context "when intermediate calculated value field is for admin only" do
        let!(:cf_static) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated1) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_static} * 7")
        end
        let!(:cf_calculated2) do
          create(:calculated_value_project_custom_field, :skip_validations, :admin_only,
                 projects: [project],
                 formula: "#{cf_calculated1} * 11")
        end
        let!(:cf_calculated3) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_calculated2} * 13")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_static.id => 3
            }
          }
        end

        before do
          create(:custom_value, customized: project, custom_field: cf_static, value: -5)
          create(:custom_value, customized: project, custom_field: cf_calculated1, value: -6)
          create(:custom_value, customized: project, custom_field: cf_calculated2, value: -6)
          create(:custom_value, customized: project, custom_field: cf_calculated3, value: -6)
        end

        it "calculates all values" do
          expect(subject.result.custom_value_attributes).to eq(
            cf_static.id => "3",
            cf_calculated1.id => "21",
            cf_calculated2.id => "231",
            cf_calculated3.id => "3003"
          )
        end
      end

      context "when referenced value field is for admin only" do
        let!(:cf_static) { create(:integer_project_custom_field, projects: [project]) }
        let!(:cf_calculated) do
          create(:calculated_value_project_custom_field, :skip_validations,
                 projects: [project],
                 formula: "#{cf_static} * #{cf_referenced}")
        end

        let(:call_attributes) do
          {
            custom_field_values: {
              cf_static.id => 3
            }
          }
        end

        before do
          create(:custom_value, customized: project, custom_field: cf_static, value: 1)
          create(:custom_value, customized: project, custom_field: cf_calculated, value: -6)
        end

        context "when referenced value is static" do
          let!(:cf_referenced) { create(:integer_project_custom_field, :admin_only, projects: [project]) }

          before do
            create(:custom_value, customized: project, custom_field: cf_referenced, value: 2)
          end

          it "calculates using existing value" do
            expect(subject.result.custom_value_attributes).to eq(
              cf_static.id => "3",
              cf_calculated.id => "6"
            )

            expect(subject.result.custom_value_attributes(all: true)).to eq(
              cf_static.id => "3",
              cf_referenced.id => "2",
              cf_calculated.id => "6"
            )
          end
        end

        context "when referenced value is calculated value without references" do
          let!(:cf_referenced) do
            create(:calculated_value_project_custom_field, :skip_validations, :admin_only,
                   projects: [project],
                   formula: "21 * -2")
          end

          before do
            create(:custom_value, customized: project, custom_field: cf_referenced, value: 2)
          end

          it "calculates using existing value" do
            expect(subject.result.custom_value_attributes).to eq(
              cf_static.id => "3",
              cf_calculated.id => "6"
            )

            expect(subject.result.custom_value_attributes(all: true)).to eq(
              cf_static.id => "3",
              cf_referenced.id => "2",
              cf_calculated.id => "6"
            )
          end
        end

        context "when referenced value is calculated value with unchanged reference" do
          let!(:cf_referenced1) { create(:integer_project_custom_field, :admin_only, projects: [project]) }
          let!(:cf_referenced) do
            create(:calculated_value_project_custom_field, :skip_validations, :admin_only,
                   projects: [project],
                   formula: "21 * #{cf_referenced1}")
          end

          before do
            create(:custom_value, customized: project, custom_field: cf_referenced1, value: -2)
            create(:custom_value, customized: project, custom_field: cf_referenced, value: 2)
          end

          it "calculates using existing value" do
            expect(subject.result.custom_value_attributes).to eq(
              cf_static.id => "3",
              cf_calculated.id => "6"
            )

            expect(subject.result.custom_value_attributes(all: true)).to eq(
              cf_static.id => "3",
              cf_referenced1.id => "-2",
              cf_referenced.id => "2",
              cf_calculated.id => "6"
            )
          end
        end
      end
    end

    describe "custom user fields with role assignment" do
      let(:project) { create(:project) }
      let!(:model_instance) { project }
      # Remove the set_attributes_service mocking to use the real service.
      let!(:set_attributes_service) { nil }
      let(:contract_class) { EmptyContract }

      let(:user) { create(:admin) }

      let(:project_role) { create(:project_role) }
      let(:second_user) { create(:user) }
      let(:third_user) { create(:user) }
      let!(:role_based_cf) do
        create(:project_custom_field, :user, is_for_all: true, role_id: project_role.id, projects: [project])
      end

      let(:manage_memberships_service) do
        instance_double(Projects::ManageMembershipsFromCustomFieldsService)
      end

      before do
        User.current = user

        allow(Projects::ManageMembershipsFromCustomFieldsService)
          .to receive(:new)
          .and_return(manage_memberships_service)

        allow(manage_memberships_service).to receive(:call)
      end

      context "when the custom field is not set" do
        context "when not setting a user in a custom field that assigns roles" do
          let(:call_attributes) do
            {}
          end

          it "does not call the ManageMembershipsFromCustomFieldsService" do
            subject

            expect(Projects::ManageMembershipsFromCustomFieldsService)
              .not_to have_received(:new)
          end
        end

        context "when setting a user in a custom field that assigns roles" do
          let(:call_attributes) do
            {
              custom_field_values: {
                role_based_cf.id => third_user.id
              }
            }
          end

          it "calls the ManageMembershipsFromCustomFieldsService" do
            subject

            expect(Projects::ManageMembershipsFromCustomFieldsService).to have_received(:new).with(
              user:,
              project:,
              custom_field: role_based_cf
            )

            expect(manage_memberships_service).to have_received(:call).with(
              old_value: [], new_value: [third_user.id.to_s]
            )
          end
        end
      end

      context "when the custom field is set" do
        before do
          create(:custom_value, customized: project, custom_field: role_based_cf, value: second_user.id)
        end

        context "when unsetting the user in a custom field that assigns roles" do
          let(:call_attributes) do
            {
              custom_field_values: {
                role_based_cf.id => nil
              }
            }
          end

          it "calls the ManageMembershipsFromCustomFieldsService" do
            subject

            expect(Projects::ManageMembershipsFromCustomFieldsService).to have_received(:new).with(
              user:,
              project:,
              custom_field: role_based_cf
            )

            expect(manage_memberships_service).to have_received(:call).with(
              old_value: [second_user.id.to_s], new_value: []
            )
          end
        end

        context "when changing the user in a custom field that assigns roles" do
          let(:call_attributes) do
            {
              custom_field_values: {
                role_based_cf.id => third_user.id
              }
            }
          end

          it "calls the ManageMembershipsFromCustomFieldsService" do
            subject

            expect(Projects::ManageMembershipsFromCustomFieldsService).to have_received(:new).with(
              user:,
              project:,
              custom_field: role_based_cf
            )

            expect(manage_memberships_service).to have_received(:call).with(
              old_value: [second_user.id.to_s], new_value: [third_user.id.to_s]
            )
          end
        end
      end
    end
  end
end
