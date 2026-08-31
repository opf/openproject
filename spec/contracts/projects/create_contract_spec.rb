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

RSpec.describe Projects::CreateContract do
  it_behaves_like "project contract" do
    let(:project) do
      Project.new(name: project_name,
                  identifier: project_identifier,
                  description: project_description,
                  active: project_active,
                  public: project_public,
                  parent: project_parent,
                  status_code: project_status_code,
                  status_explanation: project_status_explanation,
                  templated: project_templated,
                  workspace_type: project_workspace_type)
    end
    let(:global_permissions) { %i[add_project add_portfolios add_programs] }
    let(:validated_contract) do
      contract.tap(&:validate)
    end

    subject(:contract) { described_class.new(project, current_user) }

    context "if the identifier is nil" do
      let(:project_identifier) { nil }

      it_behaves_like "contract is valid"
    end

    context "when having the 'project' workspace_type and lacking the add_project permission" do
      let(:global_permissions) { [] }

      it_behaves_like "contract is invalid", base: %i(error_unauthorized)
    end

    context "if workspace_type is nil" do
      let(:project_workspace_type) { nil }

      it_behaves_like "contract is invalid", workspace_type: %i[inclusion]
    end

    context "if workspace type is 'project'" do
      let(:project_workspace_type) { "project" }

      it_behaves_like "contract is valid"
    end

    context "if workspace type is 'program'" do
      let(:project_workspace_type) { "program" }

      context "without portfolio_management enterprise feature", with_ee: [] do
        it_behaves_like "contract is invalid", base: %i[error_enterprise_only]
      end

      context "with portfolio_management enterprise feature", with_ee: :portfolio_management do
        it_behaves_like "contract is valid"

        context "without the add_programs permission" do
          let(:global_permissions) { %i[add_project add_portfolios] }

          it_behaves_like "contract is invalid", base: %i[error_unauthorized]
        end

        context "having the add_programs permission" do
          let(:global_permissions) { %i[add_programs] }

          it_behaves_like "contract is valid"
        end
      end
    end

    context "if workspace type is 'portfolio'" do
      let(:project_workspace_type) { "portfolio" }

      context "without portfolio_management enterprise feature", with_ee: [] do
        it_behaves_like "contract is invalid", base: %i[error_enterprise_only]
      end

      context "with portfolio_management enterprise feature", with_ee: :portfolio_management do
        it_behaves_like "contract is valid"

        context "without the add_portfolios permission" do
          let(:global_permissions) { %i[add_project add_programs] }

          it_behaves_like "contract is invalid", base: %i[error_unauthorized]
        end

        context "having the add_portfolios permission" do
          let(:global_permissions) { %i[add_portfolios] }

          it_behaves_like "contract is valid"
        end
      end
    end

    context "if workspace type is 'invalid type'" do
      let(:project_workspace_type) { "invalid type" }

      it_behaves_like "contract is invalid", workspace_type: %i[inclusion]
    end

    describe "permissions" do
      shared_examples "can write" do
        let(:value) { 1 }
        it "can write the attribute", :aggregate_failures do
          expect(contract.writable_attributes).to include(attribute.to_s)

          project.send(:"#{attribute}=", value)
          expect(validated_contract.errors[attribute]).to be_empty
        end
      end

      shared_examples "can not write" do
        let(:value) { 1 }
        it "can not write the attribute", :aggregate_failures do
          expect(contract.writable_attributes).not_to include(attribute.to_s)

          project.send(:"#{attribute}=", value)
          expect(validated_contract).not_to be_valid
          expect(validated_contract.errors[attribute]).to include "was attempted to be written but is not writable."
        end
      end

      describe "writing template attribute" do
        it_behaves_like "can write" do
          let(:attribute) { :template }
          let(:value) { build_stubbed(:template_project) }
        end
      end

      describe "writing read-only attributes" do
        context "when enabled for admin", with_settings: { apiv3_write_readonly_attributes: true } do
          let(:current_user) { build_stubbed(:admin) }

          it_behaves_like "can write" do
            let(:attribute) { :created_at }
            let(:value) { 10.days.ago }
          end

          it_behaves_like "can not write" do
            let(:attribute) { :updated_at }
            let(:value) { 1.day.ago }
          end
        end

        context "when disabled for admin", with_settings: { apiv3_write_readonly_attributes: false } do
          let(:current_user) { build_stubbed(:admin) }

          it_behaves_like "can not write" do
            let(:attribute) { :created_at }
            let(:value) { 1.day.ago }
          end

          it_behaves_like "can not write" do
            let(:attribute) { :updated_at }
            let(:value) { 1.day.ago }
          end
        end

        context "when enabled for regular user", with_settings: { apiv3_write_readonly_attributes: true } do
          it_behaves_like "can not write" do
            let(:attribute) { :created_at }
            let(:value) { 1.day.ago }
          end

          it_behaves_like "can not write" do
            let(:attribute) { :updated_at }
            let(:value) { 1.day.ago }
          end
        end

        context "when disabled for regular user", with_settings: { apiv3_write_readonly_attributes: false } do
          it_behaves_like "can not write" do
            let(:attribute) { :created_at }
            let(:value) { 1.day.ago }
          end

          it_behaves_like "can not write" do
            let(:attribute) { :updated_at }
            let(:value) { 1.day.ago }
          end
        end
      end

      describe "reading and writing project attributes and their comments" do
        # The create contract is being used to render the project schema too. It should return
        # the custom fields the user can access via project memberships with `:view_project_attributes`
        # permission or return all the custom fields if the user has the `:add_project` global permission.
        #
        # The purpose of this behaviour is to provide details for the project schema only.
        # It will not affect the availability of all the custom fields on project creation, because
        # the `:add_project` permission will ensure that all the custom fields are accessible.

        shared_examples "can access custom field" do
          it "can access custom field" do
            expect(contract.available_custom_fields).to include(custom_field)
          end
        end

        shared_examples "can not access custom field" do
          it "can not access custom field" do
            expect(contract.available_custom_fields).not_to include(custom_field)
          end
        end

        shared_examples "can not write comments of non commentable project attributes" do
          context "for non commentable project attribute comment" do
            let(:attribute) { custom_field.comment_attribute_name }

            include_examples "can not write"
          end

          context "for non commentable non member project attribute comment" do
            let(:attribute) { non_member_custom_field.comment_attribute_name }

            include_examples "can not write"
          end
        end

        let(:global_permissions) { [] }
        let(:current_user) { create(:user) }
        let(:role) { create(:existing_project_role, permissions: project_permissions) }
        let(:other_project_public) { false }
        let(:other_project) do
          create(:project,
                 public: other_project_public,
                 members: { current_user => role })
        end
        let!(:custom_field) do
          create(:project_custom_field, projects: other_project)
        end
        let!(:non_member_custom_field) do
          create(:project_custom_field_project_mapping).project_custom_field
        end
        let!(:commentable_custom_field) do
          create(:project_custom_field, :has_comment, projects: other_project)
        end
        let!(:commentable_non_member_custom_field) do
          create(:project_custom_field, :has_comment)
        end

        before { User.current = current_user }

        context "without view_project_attributes permission" do
          let(:project_permissions) { [] }

          include_examples "can not access custom field"

          context "with a public project" do
            let(:other_project_public) { true }

            include_examples "can not access custom field"
          end

          context "for project attribute" do
            let(:attribute) { custom_field.attribute_name }

            include_examples "can not write"
          end

          context "for project attribute comment" do
            let(:attribute) { commentable_custom_field.comment_attribute_name }

            include_examples "can not write"
          end

          context "for non member project attribute comment" do
            let(:attribute) { commentable_non_member_custom_field.attribute_name }

            include_examples "can not write"
          end

          include_examples "can not write comments of non commentable project attributes"
        end

        context "with view_project_attributes permission" do
          let(:project_permissions) { %i(view_project_attributes) }

          include_examples "can access custom field"

          context "for project attribute" do
            let(:attribute) { custom_field.attribute_name }

            include_examples "can not write"
          end

          context "for project attribute comment" do
            let(:attribute) { commentable_custom_field.comment_attribute_name }

            include_examples "can not write"
          end

          context "for non member project attribute comment" do
            let(:attribute) { commentable_non_member_custom_field.attribute_name }

            include_examples "can not write"
          end

          include_examples "can not write comments of non commentable project attributes"
        end

        context "with edit_project_attributes permission" do
          let(:project_permissions) { %i(view_project_attributes edit_project_attributes) }

          include_examples "can access custom field"

          context "for project attribute" do
            let(:attribute) { custom_field.attribute_name }

            include_examples "can write"
          end

          context "for non member project attribute" do
            let(:attribute) { non_member_custom_field.attribute_name }

            include_examples "can not write"
          end

          context "for project attribute comment" do
            let(:attribute) { commentable_custom_field.comment_attribute_name }

            include_examples "can write"
          end

          context "for non member project attribute comment" do
            let(:attribute) { commentable_non_member_custom_field.attribute_name }

            include_examples "can not write"
          end

          include_examples "can not write comments of non commentable project attributes"
        end

        context "with add_project permission" do
          let(:global_permissions) { %i(add_project) }

          include_examples "can access custom field"

          context "for project attribute" do
            let(:attribute) { custom_field.attribute_name }

            include_examples "can write"
          end

          context "for non member project attribute" do
            let(:attribute) { non_member_custom_field.attribute_name }

            include_examples "can write"
          end

          context "for project attribute comment" do
            let(:attribute) { commentable_custom_field.comment_attribute_name }

            include_examples "can write"
          end

          context "for non member project attribute comment" do
            let(:attribute) { commentable_non_member_custom_field.attribute_name }

            include_examples "can write"
          end

          include_examples "can not write comments of non commentable project attributes"
        end
      end
    end
  end
end
