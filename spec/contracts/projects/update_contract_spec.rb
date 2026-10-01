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
require_relative "shared_contract_examples"

RSpec.describe Projects::UpdateContract do
  it_behaves_like "project contract" do
    shared_let(:custom_field) { create(:integer_project_custom_field) }
    shared_let(:admin_only_custom_field) { create(:integer_project_custom_field, :admin_only) }
    shared_let(:not_enabled_custom_field) { create(:integer_project_custom_field) }
    shared_let(:commentable_custom_field) { create(:integer_project_custom_field, :has_comment) }
    shared_let(:commentable_admin_only_custom_field) { create(:integer_project_custom_field, :has_comment, :admin_only) }
    shared_let(:commentable_not_enabled_custom_field) { create(:integer_project_custom_field, :has_comment) }

    let(:project) do
      build_stubbed(:project,
                    active: project_active,
                    public: project_public,
                    status_code: project_status_code,
                    status_explanation: project_status_explanation,
                    workspace_type: project_workspace_type) do |project|
        # Use real AR relations for the custom field associations with actual IDs
        available_custom_fields = ProjectCustomField.where(id: [
                                                             custom_field,
                                                             admin_only_custom_field,
                                                             commentable_custom_field,
                                                             commentable_admin_only_custom_field
                                                           ])
        all_available_custom_fields = ProjectCustomField.where(id: [
                                                                 custom_field,
                                                                 admin_only_custom_field,
                                                                 not_enabled_custom_field,
                                                                 commentable_custom_field,
                                                                 commentable_admin_only_custom_field,
                                                                 commentable_not_enabled_custom_field
                                                               ])

        allow(project).to receive_messages(available_custom_fields:, all_available_custom_fields:)

        # in order to actually have something changed
        if project_changed
          project.name = project_name
          project.parent = project_parent
          project.identifier = project_identifier
          project.templated = project_templated
        end

        if custom_field_value_changed
          project.custom_field_values = { custom_field.id => "1" }
        end

        if custom_field_comment_changed
          project.custom_comments = { commentable_custom_field.id => "1" }
        end
      end
    end
    let(:project_permissions) { %i(edit_project) }
    let(:project_changed) { true }
    let(:custom_field_value_changed) { false }
    let(:custom_field_comment_changed) { false }
    let(:options) { {} }

    subject(:contract) { described_class.new(project, current_user, options:) }

    context "if the identifier is nil" do
      let(:project_identifier) { nil }

      include_examples "contract is invalid", identifier: %i[blank]
    end

    context "if workspace_type is changed" do
      before do
        project.workspace_type = "portfolio"
      end

      include_examples "contract is invalid", workspace_type: :error_readonly
    end

    context "if template is changed" do
      before do
        project.template_id = 1
      end

      include_examples "contract is invalid", template_id: :error_readonly
    end

    describe "permissions" do
      let(:readonly_attribute_errors) do
        {
          name: %i[error_readonly],
          parent_id: %i[error_readonly],
          identifier: %i[error_readonly]
        }
      end

      shared_examples "contract is valid for custom values and/or comments" do
        context "and custom values are changed" do
          let(:custom_field_value_changed) { true }

          include_examples "contract is valid"
        end

        context "and custom comments are changed" do
          let(:custom_field_comment_changed) { true }

          include_examples "contract is valid"
        end

        context "and both custom values and comments are changed" do
          let(:custom_field_value_changed) { true }
          let(:custom_field_comment_changed) { true }

          include_examples "contract is valid"
        end
      end

      shared_examples "contract is invalid for custom values and/or comments" do
        context "and custom values are changed" do
          let(:custom_field_value_changed) { true }

          it("is invalid") { expect_contract_invalid(errors) }
        end

        context "and custom comments are changed" do
          let(:custom_field_comment_changed) { true }

          it("is invalid") { expect_contract_invalid(errors) }
        end

        context "and both custom values and comments are changed" do
          let(:custom_field_value_changed) { true }
          let(:custom_field_comment_changed) { true }

          it("is invalid") { expect_contract_invalid(errors) }
        end
      end

      context "with edit_project_attributes" do
        let(:project_permissions) { %i(edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          context "and only custom values are changed" do
            let(:project_changed) { false }

            include_examples "contract is valid for custom values and/or comments"
          end

          include_examples "contract is invalid for custom values and/or comments" do
            let(:errors) { readonly_attribute_errors }
          end
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          it("is invalid") { expect_contract_invalid(readonly_attribute_errors) }
        end
      end

      context "with edit_project" do
        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          include_examples "contract user is unauthorized"
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          context "and only project attributes are changed" do
            include_examples "contract is valid"
          end

          context "and custom values are changed too" do
            include_examples "contract is invalid for custom values and/or comments" do
              let(:errors) do
                {
                  custom_field.attribute_name =>
                    custom_field_value_changed ? %i[error_readonly] : [],
                  commentable_custom_field.comment_attribute_name =>
                    custom_field_comment_changed ? %i[error_readonly] : []
                }
              end
            end
          end
        end
      end

      context "with both edit_project and edit_project_attributes are set" do
        let(:project_permissions) { %i(edit_project edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          context "and only project attributes are changed" do
            it("is invalid") { expect_contract_invalid(readonly_attribute_errors) }
          end

          context "and project attributes are not changed" do
            let(:project_changed) { false }

            include_examples "contract is valid for custom values and/or comments"
          end

          context "and project attributes are changed" do
            include_examples "contract is invalid for custom values and/or comments" do
              let(:errors) { readonly_attribute_errors }
            end
          end
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          context "and only project attributes are changed" do
            include_examples "contract is valid"
          end

          include_examples "contract is valid for custom values and/or comments"
        end
      end

      context "without permissions when project_attributes_only flag is true" do
        let(:project_permissions) { [] }
        let(:options) { { project_attributes_only: true } }

        include_examples "contract user is unauthorized"
      end
    end

    describe "#writable_attributes" do
      let(:project_changed) { false }

      shared_examples "can write" do |attribute|
        it "can write #{attribute}" do
          expect(contract.writable_attributes).to include(attribute.to_s)
        end
      end

      shared_examples "can not write" do |attribute|
        it "can not write #{attribute}" do
          expect(contract.writable_attributes).not_to include(attribute.to_s)
        end
      end

      shared_examples "can write custom value and comment" do |custom_field_name|
        commentable_custom_field_name = "commentable_#{custom_field_name}"

        it "can write custom value for #{custom_field_name}" do
          expect(contract.writable_attributes).to include(send(custom_field_name).attribute_name)
        end

        it "can not write custom comment for #{custom_field_name}" do
          expect(contract.writable_attributes).not_to include(send(custom_field_name).comment_attribute_name)
        end

        it "can write custom comment for #{commentable_custom_field_name}" do
          expect(contract.writable_attributes).to include(send(commentable_custom_field_name).comment_attribute_name)
        end
      end

      shared_examples "can not write custom value or comment" do |custom_field_name|
        commentable_custom_field_name = "commentable_#{custom_field_name}"

        it "can not write custom value for #{custom_field_name}" do
          expect(contract.writable_attributes).not_to include(send(custom_field_name).attribute_name)
        end

        it "can not write custom comment for #{custom_field_name}" do
          expect(contract.writable_attributes).not_to include(send(custom_field_name).comment_attribute_name)
        end

        it "can not write custom comment for #{commentable_custom_field_name}" do
          expect(contract.writable_attributes).not_to include(send(commentable_custom_field_name).comment_attribute_name)
        end
      end

      context "with edit_project_attributes" do
        let(:project_permissions) { %i(edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          include_examples "can write custom value and comment", :custom_field
          include_examples "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          include_examples "can write custom value and comment", :custom_field
          include_examples "can not write", :name
        end
      end

      context "with edit_project" do
        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          include_examples "can not write custom value or comment", :custom_field
          include_examples "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          include_examples "can not write custom value or comment", :custom_field
          include_examples "can write", :name
        end
      end

      context "with both edit_project and edit_project_attributes are set" do
        let(:project_permissions) { %i(edit_project edit_project_attributes) }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          include_examples "can write custom value and comment", :custom_field
          include_examples "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          include_examples "can write custom value and comment", :custom_field
          include_examples "can write", :name
        end
      end

      context "without permissions" do
        let(:project_permissions) { [] }

        context "when project_attributes_only flag is true" do
          let(:options) { { project_attributes_only: true } }

          include_examples "can not write custom value or comment", :custom_field
          include_examples "can not write", :name
        end

        context "when project_attributes_only flag is false" do
          let(:options) { { project_attributes_only: false } }

          include_examples "can not write custom value or comment", :custom_field
          include_examples "can not write", :name
        end
      end

      context "with admin-only custom fields" do
        shared_examples "admin-only custom field behavior" do
          context "when user is admin" do
            let(:current_user) { build_stubbed(:admin) }

            include_examples "can write custom value and comment", :admin_only_custom_field
          end

          context "when user is not admin" do
            let(:current_user) { build_stubbed(:user) }
            let(:project_permissions) { %i(edit_project_attributes) }

            include_examples "can not write custom value or comment", :admin_only_custom_field

            context "with all permissions" do
              let(:project_permissions) { %i(edit_project edit_project_attributes) }

              include_examples "can not write custom value or comment", :admin_only_custom_field
            end
          end
        end

        context "when project_attributes_only is true" do
          let(:options) { { project_attributes_only: true } }

          include_examples "admin-only custom field behavior"
        end

        context "when project_attributes_only is false" do
          let(:options) { { project_attributes_only: false } }

          include_examples "admin-only custom field behavior"
        end
      end

      context "with not enabled custom fields" do
        context "when project_attributes_only is true" do
          let(:options) { { project_attributes_only: true } }

          context "when user is admin" do
            let(:current_user) { build_stubbed(:admin) }
            let(:project_permissions) { %i(edit_project_attributes) }

            include_examples "can not write custom value or comment", :not_enabled_custom_field
          end

          context "when user is not admin" do
            let(:current_user) { build_stubbed(:user) }
            let(:project_permissions) { %i(edit_project_attributes) }

            include_examples "can not write custom value or comment", :not_enabled_custom_field

            context "with all permissions" do
              let(:project_permissions) { %i(edit_project edit_project_attributes) }

              include_examples "can not write custom value or comment", :not_enabled_custom_field
            end
          end
        end

        context "when project_attributes_only is false (for API backward compatibility)" do
          let(:options) { { project_attributes_only: false } }

          context "when user is admin" do
            let(:current_user) { build_stubbed(:admin) }
            let(:project_permissions) { %i(edit_project edit_project_attributes) }

            include_examples "can write custom value and comment", :not_enabled_custom_field
          end

          context "when user is not admin" do
            let(:current_user) { build_stubbed(:user) }
            let(:project_permissions) { %i(edit_project_attributes) }

            include_examples "can not write custom value or comment", :not_enabled_custom_field

            context "with all permissions" do
              let(:project_permissions) { %i(edit_project edit_project_attributes) }

              include_examples "can write custom value and comment", :not_enabled_custom_field
            end
          end
        end
      end
    end
  end
end
