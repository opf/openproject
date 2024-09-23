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
                  status_explanation: project_status_explanation)
    end
    let(:global_permissions) { [:add_project] }
    let(:validated_contract) do
      contract.tap(&:validate)
    end

    subject(:contract) { described_class.new(project, current_user) }

    context "if the identifier is nil" do
      let(:project_identifier) { nil }

      it "is replaced for new project" do
        expect_valid(true)
      end
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

      describe "reading and writing project attributes" do
        # The create contract is being used to render the project schema too. It should return
        # the custom fields the user can access via project memberships with `:view_project_attributes`
        # permission or return all the custom fields if the user has the `:add_project` global permission.
        #
        # The purpose of this behaviour is to provide details for the project schema only.
        # It will not affect the availability of all the custom fields on project creation, because
        # the `:add_project` permission will ensure that all the custom fields are accessible.

        shared_examples "can read project attributes" do
          it "can read project attributes" do
            expect(contract.available_custom_fields).to include(custom_field)
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
        let(:mapping) { create(:project_custom_field_project_mapping, project: other_project) }
        let!(:custom_field) { mapping.project_custom_field }
        let!(:non_member_custom_field) do
          create(:project_custom_field_project_mapping).project_custom_field
        end

        before { User.current = current_user }

        context "without view_project_attributes permission" do
          let(:project_permissions) { [] }

          shared_examples "cannot read project attributes" do
            it "cannot read project attributes" do
              expect(contract.available_custom_fields).not_to include(custom_field)
            end
          end

          it_behaves_like "cannot read project attributes"

          context "with a public project" do
            let(:other_project_public) { true }

            it_behaves_like "cannot read project attributes"
          end
        end

        context "with view_project_attributes permission" do
          let(:project_permissions) { %i(view_project_attributes) }

          it_behaves_like "can read project attributes"

          it_behaves_like "can not write" do
            let(:attribute) { custom_field.attribute_name }
          end
        end

        context "with edit_project_attributes permission" do
          let(:project_permissions) { %i(view_project_attributes edit_project_attributes) }

          it_behaves_like "can read project attributes"

          it_behaves_like "can write" do
            let(:attribute) { custom_field.attribute_name }
          end

          it_behaves_like "can not write" do
            let(:attribute) { non_member_custom_field.attribute_name }
          end
        end

        context "with add_project permission" do
          let(:global_permissions) { %i(add_project) }

          it_behaves_like "can read project attributes"

          it_behaves_like "can write" do
            let(:attribute) { custom_field.attribute_name }
          end

          it_behaves_like "can write" do
            let(:attribute) { non_member_custom_field.attribute_name }
          end
        end
      end
    end
  end
end
