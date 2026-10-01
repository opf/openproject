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
require "services/base_services/behaves_like_create_service"

RSpec.describe Projects::CreateService, type: :model do
  it_behaves_like "BaseServices create service" do
    let(:new_project_role) { build_stubbed(:project_role) }
    let(:create_member_instance) { instance_double(Members::CreateService) }

    before do
      allow(ProjectRole)
        .to(receive(:in_new_project))
        .and_return(new_project_role)

      allow(Members::CreateService)
        .to(receive(:new))
        .with(user:, contract_class: EmptyContract)
        .and_return(create_member_instance)

      allow(create_member_instance)
        .to(receive(:call))
    end

    it "adds the current user to the project" do
      subject

      expect(create_member_instance)
        .to have_received(:call)
        .with(principal: user,
              project: model_instance,
              roles: [new_project_role])
    end

    context "when current user is admin" do
      it "does not add the user to the project" do
        allow(user)
          .to(receive(:admin?))
          .and_return(true)

        subject

        expect(create_member_instance)
          .not_to(have_received(:call))
      end
    end

    describe "project creation email" do
      context "when enabled", with_settings: { new_project_send_confirmation_email: true } do
        it "sends the email to the user" do
          allow(ProjectMailer)
            .to receive(:project_created)
            .with(model_instance, user:)
            .and_call_original

          subject

          expect(ProjectMailer).to have_received(:project_created)
        end
      end

      context "when disabled", with_settings: { new_project_send_confirmation_email: false } do
        it "does not send the email" do
          allow(ProjectMailer).to receive(:project_created)

          subject

          expect(ProjectMailer).not_to have_received(:project_created)
        end
      end
    end

    context "with a real service call" do
      let(:stub_model_instance) { false }
      let(:project) { subject.result }
      let(:project_attributes) { {} }
      let(:call_attributes) do
        attributes_for(:project, project_attributes).except(:created_at, :updated_at)
      end

      let(:user) { build_stubbed(:admin) }

      before do
        User.current = user
      end

      describe "activating custom fields" do
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
        let!(:hidden_custom_field) do
          create(:text_project_custom_field, project_custom_field_section: section, admin_only: true)
        end

        context "with default values" do
          let!(:text_custom_field_with_default) do
            create(:text_project_custom_field,
                   default_value: "default",
                   project_custom_field_section: section)
          end

          def project_attributes_with_default_value(value_for_default_field)
            {
              custom_field_values: {
                text_custom_field.id => "foo",
                bool_custom_field.id => true,
                text_custom_field_with_default.id => value_for_default_field
              }.compact
            }
          end

          describe "activation of custom fields with default values" do
            [
              { description: "implicitly set to its default", value: nil, should_activate: false },
              { description: "explicitly set to its default", value: "default", should_activate: true },
              { description: "explicitly set to blank", value: "", should_activate: true },
              { description: "explicitly set to a user value", value: "a user set value", should_activate: true }
            ].each do |test_case|
              context "if the default value is #{test_case[:description]}" do
                let(:project_attributes) { project_attributes_with_default_value(test_case[:value]) }

                it "#{test_case[:should_activate] ? 'does' : 'does not'} activate custom fields with default values" do
                  subject
                  expected_ids = if test_case[:should_activate]
                                   [text_custom_field.id, bool_custom_field.id, text_custom_field_with_default.id]
                                 else
                                   [text_custom_field.id, bool_custom_field.id]
                                 end
                  expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
                    .to match_array(expected_ids)
                end
              end
            end
          end
        end

        context "with for_all custom fields", with_ee: %i[calculated_values] do
          let!(:calculated_custom_field) do
            create(:calculated_value_project_custom_field,
                   project_custom_field_section: section)
          end
          let!(:for_all_calculated_custom_field) do
            create(:calculated_value_project_custom_field,
                   is_for_all: true,
                   project_custom_field_section: section)
          end

          let(:project_attributes) do
            { custom_field_values: { text_custom_field.id => "foo" } }
          end

          it "activates calculated custom fields even if no value is provided" do
            subject
            expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
              .to contain_exactly(for_all_calculated_custom_field.id, text_custom_field.id)
          end
        end

        context "with hidden custom fields" do
          let(:project_attributes) do
            { custom_field_values: {
              text_custom_field.id => "foo",
              bool_custom_field.id => true,
              hidden_custom_field.id => "hidden"
            } }
          end

          context "with admin permission" do
            it "does activate hidden custom fields" do
              subject
              expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
                .to contain_exactly(text_custom_field.id, bool_custom_field.id, hidden_custom_field.id)
              expect(project.custom_value_for(hidden_custom_field).typed_value).to eq("hidden")
            end
          end

          context "without admin permission" do
            let(:user) { create(:user) }

            before do
              mock_permissions_for(user) do |mock|
                mock.allow_globally :add_project
              end
            end

            it "does not activate hidden custom fields" do
              subject
              expect(subject).not_to be_success
              expect(subject.errors[hidden_custom_field.attribute_name])
                .to include "was attempted to be written but is not writable."
            end
          end
        end
      end

      describe "calculated custom fields", with_ee: %i[calculated_values] do
        shared_let(:cf_static) { create(:integer_project_custom_field, is_for_all: true) }
        let(:project) { create(:project) }
        let!(:model_instance) { project }
        let(:stub_model_instance) { false }

        before do
          # Both User.current and :select_project_custom_fields for ProjectCustomField.visible
          User.current = user
          mock_permissions_for(user) do |mock|
            mock.allow_in_project(:select_project_custom_fields, project:)
          end
        end

        using CustomFieldFormulaReferencing

        context "when trying to explicitly set values of calculated custom fields" do
          let!(:cf_calculated) do
            create(:calculated_value_project_custom_field,
                   is_for_all: true, formula: "1 + 1")
          end

          let(:project_attributes) do
            {
              custom_field_values: {
                cf_static.id => 3,
                cf_calculated.id => 4
              }
            }
          end

          it "doesn't allow to assign calculated value" do
            expect(subject.result.custom_value_attributes)
              .to eq(cf_static.id => "3", cf_calculated.id => "2")
          end
        end

        context "when setting value of field referenced in calculated values" do
          let!(:cf_calculated1) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_static} * 7")
          end
          let!(:cf_calculated2) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_calculated1} * 11")
          end

          let(:project_attributes) do
            {
              custom_field_values: {
                cf_static.id => 3
              }
            }
          end

          it "calculates all values" do
            expect(subject.result.custom_value_attributes).to eq(
              cf_static.id => "3",
              cf_calculated1.id => "21",
              cf_calculated2.id => "231"
            )
          end
        end

        context "when not setting value of field referenced in calculated values" do
          let!(:cf_calculated1) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_static} * 7")
          end
          let!(:cf_calculated2) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_calculated1} * 11")
          end

          let(:project_attributes) do
            {
              custom_field_values: {
                cf_static.id => nil
              }
            }
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
          let!(:cf_a) { create(:integer_project_custom_field) }
          let!(:cf_b) { create(:integer_project_custom_field) }
          let!(:cf_c) { create(:integer_project_custom_field) }
          let!(:cf_calculated1) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_a} * 7")
          end
          let!(:cf_calculated2) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_b} * 11")
          end
          let!(:cf_calculated3) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_c} * 13")
          end

          let(:project_attributes) do
            {
              custom_field_values: {
                cf_static.id => 2,
                cf_a.id => 3,
                cf_b.id => -5
              }
            }
          end

          it "calculates only values referenced by provided fields" do
            expect(subject.result.custom_value_attributes).to eq(
              cf_static.id => "2",
              cf_a.id => "3",
              cf_b.id => "-5",
              cf_calculated1.id => "21",
              cf_calculated2.id => "-55",
              cf_calculated3.id => nil
            )
          end
        end

        context "when intermediate calculated value field is not enabled" do
          let!(:cf_calculated1) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_static} * 7")
          end
          let!(:cf_calculated2) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   formula: "#{cf_calculated1} * 11")
          end
          let!(:cf_calculated3) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_calculated2} * 13")
          end

          let(:project_attributes) do
            {
              custom_field_values: {
                cf_static.id => 3
              }
            }
          end

          it "calculates only accessible values" do
            expect(subject.result.custom_value_attributes).to eq(
              cf_static.id => "3",
              cf_calculated1.id => "21",
              cf_calculated3.id => nil
            )

            expect(subject.result.custom_value_attributes(all: true)).to eq(
              cf_static.id => "3",
              cf_calculated1.id => "21",
              cf_calculated2.id => nil,
              cf_calculated3.id => nil
            )
          end
        end

        context "when intermediate calculated value field is for admin only" do
          let!(:cf_calculated1) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_static} * 7")
          end
          let!(:cf_calculated2) do
            create(:calculated_value_project_custom_field, :skip_validations, :admin_only,
                   is_for_all: true, formula: "#{cf_calculated1} * 11")
          end
          let!(:cf_calculated3) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_calculated2} * 13")
          end

          let(:project_attributes) do
            {
              custom_field_values: {
                cf_static.id => 3
              }
            }
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
          let!(:cf_calculated) do
            create(:calculated_value_project_custom_field, :skip_validations,
                   is_for_all: true, formula: "#{cf_static} * #{cf_referenced}")
          end

          context "when referenced value is static" do
            let!(:cf_referenced) { create(:integer_project_custom_field, :admin_only, is_for_all: true) }

            let(:project_attributes) do
              {
                custom_field_values: {
                  cf_static.id => 3,
                  cf_referenced.id => 2
                }
              }
            end

            it "calculates using existing value" do
              # Project creator is always an admin, thus the 2 expectations are equal.
              expect(subject.result.custom_value_attributes).to eq(
                cf_static.id => "3",
                cf_referenced.id => "2",
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
                     is_for_all: true, formula: "2")
            end

            let(:project_attributes) do
              {
                custom_field_values: {
                  cf_static.id => 3
                }
              }
            end

            it "calculates using existing value" do
              # Project creator is always an admin, thus the 2 expectations are equal.
              expect(subject.result.custom_value_attributes).to eq(
                cf_static.id => "3",
                cf_referenced.id => "2",
                cf_calculated.id => "6"
              )

              expect(subject.result.custom_value_attributes(all: true)).to eq(
                cf_static.id => "3",
                cf_referenced.id => "2",
                cf_calculated.id => "6"
              )
            end
          end

          context "when referenced value is calculated value with another reference" do
            let!(:cf_referenced1) { create(:integer_project_custom_field, :admin_only, is_for_all: true) }
            let!(:cf_referenced) do
              create(:calculated_value_project_custom_field, :skip_validations, :admin_only,
                     is_for_all: true, formula: "-1 * #{cf_referenced1}")
            end

            let(:project_attributes) do
              {
                custom_field_values: {
                  cf_static.id => 3,
                  cf_referenced1.id => -2
                }
              }
            end

            it "calculates using existing value" do
              # Project creator is always an admin, thus the 2 expectations are equal.
              expect(subject.result.custom_value_attributes).to eq(
                cf_static.id => "3",
                cf_referenced1.id => "-2",
                cf_referenced.id => "2",
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
        let(:user) { create(:admin) }

        let(:project_role) { create(:project_role) }
        let(:other_user) { create(:user) }
        let!(:role_based_cf) do
          create(:project_custom_field, :user, is_for_all: true, role_id: project_role.id)
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

        context "when not setting a user in a custom field that assigns roles" do
          let(:project_attributes) do
            {}
          end

          it "does not call the ManageMembershipsFromCustomFieldsService" do
            subject

            expect(Projects::ManageMembershipsFromCustomFieldsService)
              .not_to have_received(:new)
          end
        end

        context "when setting a user in a custom field that assigns roles" do
          let(:project_attributes) do
            {
              custom_field_values: {
                role_based_cf.id => other_user.id
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
              old_value: [], new_value: [other_user.id.to_s]
            )
          end
        end
      end
    end
  end
end
