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

    context "current user is admin" do
      it "does not add the user to the project" do
        allow(user)
          .to(receive(:admin?))
          .and_return(true)

        subject

        expect(create_member_instance)
          .not_to(have_received(:call))
      end
    end

    context "with a real service call" do
      let(:stub_model_instance) { false }
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
      let(:project) { subject.result }
      let(:project_attributes) { {} }
      let(:call_attributes) do
        attributes_for(:project, project_attributes).except(:created_at, :updated_at)
      end

      let(:user) { build_stubbed(:admin) }

      before do
        User.current = user
      end

      context "with correct handling of custom fields with default values" do
        let!(:text_custom_field_with_default) do
          create(:text_project_custom_field,
                 default_value: "default",
                 project_custom_field_section: section)
        end

        context "if the default value is not explicitly set to blank" do
          let(:project_attributes) do
            { custom_field_values: {
              text_custom_field.id => "foo",
              bool_custom_field.id => true
            } }
          end

          it "activates custom fields with default values" do
            subject
            expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
              .to contain_exactly(text_custom_field.id, bool_custom_field.id, text_custom_field_with_default.id)
          end
        end

        context "if the default value is explicitly set to blank" do
          let(:project_attributes) do
            { custom_field_values: {
              text_custom_field.id => "foo",
              bool_custom_field.id => true,
              text_custom_field_with_default.id => ""
            } }
          end

          it "does not activate custom fields with default values" do
            subject
            expect(project.project_custom_field_project_mappings.pluck(:custom_field_id))
              .to contain_exactly(text_custom_field.id, bool_custom_field.id)
          end
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

      context "with a section scoped validation" do
        let(:project_attributes) do
          { custom_field_values: { text_custom_field.id => "foo" },
            _limit_custom_fields_validation_to_section_id: section.id }
        end

        it "rejects section validation scoping for project creation" do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
