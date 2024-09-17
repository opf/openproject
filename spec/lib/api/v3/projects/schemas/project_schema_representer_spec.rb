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

RSpec.describe API::V3::Projects::Schemas::ProjectSchemaRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) { build_stubbed(:user) }
  let(:self_link) { "/a/self/link" }
  let(:embedded) { true }
  let(:new_record) { true }
  let(:model_id) { 1 }
  let(:custom_field) do
    build_stubbed(:integer_project_custom_field)
  end
  let(:allowed_status) { ["some status"] }
  let(:contract) do
    contract = double("contract")
    model = double("project")

    allow(contract)
      .to receive(:writable?) do |attribute|
      writable = %w(name identifier description public
                    status_code status_explanation parent active)

      writable.include?(attribute.to_s)
    end

    allow(contract)
      .to receive(:available_custom_fields)
      .and_return([custom_field])

    allow(contract)
      .to receive(:assignable_values)
      .with(:status_code, current_user)
      .and_return(allowed_status)

    allow(contract)
      .to receive(:model)
      .and_return(model)

    allow(model)
      .to receive(:new_record?)
      .and_return(new_record)

    allow(model)
      .to receive(:id)
      .and_return(model_id)

    contract
  end
  let(:global_permissions) { %i[add_project] }
  let(:project_permissions) { [] }
  let(:representer) do
    described_class.create(contract,
                           self_link:,
                           form_embedded: embedded,
                           current_user:)
  end

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*project_permissions, project: build_stubbed(:project)) if project_permissions.any?
      mock.allow_globally *global_permissions
    end
  end

  context "generation" do
    subject(:generated) { representer.to_json }

    describe "_type" do
      it "is indicated as Schema" do
        expect(subject).to be_json_eql("Schema".to_json).at_path("_type")
      end
    end

    describe "id" do
      let(:path) { "id" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { I18n.t("attributes.id") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "name" do
      let(:path) { "name" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "String" }
        let(:name) { I18n.t("attributes.name") }
        let(:required) { true }
        let(:writable) { true }
      end

      it_behaves_like "indicates length requirements" do
        let(:min_length) { 1 }
        let(:max_length) { 255 }
      end
    end

    describe "identifier" do
      let(:path) { "identifier" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "String" }
        let(:name) { I18n.t("activerecord.attributes.project.identifier") }
        let(:required) { true }
        let(:has_default) { true }
        let(:writable) { true }
      end

      it_behaves_like "indicates length requirements" do
        let(:min_length) { 1 }
        let(:max_length) { 100 }
      end
    end

    describe "description" do
      let(:path) { "description" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Formattable" }
        let(:name) { I18n.t("attributes.description") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "public" do
      let(:path) { "public" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Boolean" }
        let(:name) { I18n.t("attributes.public") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "active" do
      let(:path) { "active" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Boolean" }
        let(:name) { I18n.t("attributes.active") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "statusExplanation" do
      let(:path) { "statusExplanation" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Formattable" }
        let(:name) { I18n.t("activerecord.attributes.project.status_explanation") }
        let(:required) { false }
        let(:writable) { true }
      end
    end

    describe "status" do
      let(:path) { "status" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "ProjectStatus" }
        let(:name) { I18n.t("activerecord.attributes.project.status_code") }
        let(:required) { false }
        let(:writable) { true }
        let(:location) { "_links" }
      end

      it_behaves_like "links to allowed values directly" do
        let(:hrefs) { Project.status_codes.keys.map { |code| api_v3_paths.project_status code } }
      end
    end

    describe "createdAt" do
      let(:path) { "createdAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { I18n.t("attributes.created_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "updatedAt" do
      let(:path) { "updatedAt" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "DateTime" }
        let(:name) { I18n.t("attributes.updated_at") }
        let(:required) { true }
        let(:writable) { false }
      end
    end

    describe "int custom field" do
      let(:path) { "customField#{custom_field.id}" }

      it_behaves_like "has basic schema properties" do
        let(:type) { "Integer" }
        let(:name) { custom_field.name }
        let(:required) { false }
        let(:writable) { false }
      end
    end

    describe "parent" do
      let(:path) { "parent" }

      context "when having a new record" do
        it_behaves_like "has basic schema properties" do
          let(:type) { "Project" }
          let(:name) { Project.human_attribute_name("parent") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "when embedding" do
          let(:embedded) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.projects_available_parents
            end
          end
        end

        context "when not embedding" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values"
        end

        context "when only having the add_subprojects permissions" do
          let(:project_permissions) { %i[add_subprojects] }
          let(:global_permissions) { [] }

          it_behaves_like "has basic schema properties" do
            let(:type) { "Project" }
            let(:name) { Project.human_attribute_name("parent") }
            # Required is different when the add_project permission is lacking
            let(:required) { true }
            let(:writable) { true }
            let(:location) { "_links" }
          end
        end
      end

      context "if having a persisted record" do
        let(:new_record) { false }

        it_behaves_like "has basic schema properties" do
          let(:type) { "Project" }
          let(:name) { Project.human_attribute_name("parent") }
          let(:required) { false }
          let(:writable) { true }
          let(:location) { "_links" }
        end

        context "if embedding" do
          let(:embedded) { true }

          it_behaves_like "links to allowed values via collection link" do
            let(:href) do
              api_v3_paths.projects_available_parents + "?of=#{model_id}"
            end
          end
        end

        context "if not embedding" do
          let(:embedded) { false }

          it_behaves_like "does not link to allowed values"
        end
      end
    end

    context "_links" do
      describe "self link" do
        it_behaves_like "has an untitled link" do
          let(:link) { "self" }
          let(:href) { self_link }
        end

        context "embedded in a form" do
          let(:self_link) { nil }

          it_behaves_like "has no link" do
            let(:link) { "self" }
          end
        end
      end
    end
  end
end
