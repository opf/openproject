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

module WorkPackageTypes
  RSpec.describe UpdateService, type: :service do
    shared_let(:user) { create(:admin) }
    shared_let(:cf1) { create(:work_package_custom_field, field_format: "text") }
    shared_let(:cf2) { create(:work_package_custom_field, field_format: "text") }
    shared_let(:cf3) { create(:work_package_custom_field, field_format: "text") }

    let(:model) { create(:type, name: "Types-R-Us") }
    let(:type) { model }
    let(:service_call) { service.call(params) }

    subject(:service) { described_class.new(user:, model:) }

    it_behaves_like "BaseServices update service" do
      let(:factory) { :type }
      let(:model_class) { Type }
    end

    it "updates the attributes of the model" do
      params = { name: "updated name" }
      expect { service.call(params) }.to change(model, :name).from("Types-R-Us").to("updated name")

      expect(model).to be_valid
      expect(model.changes).to be_empty
    end

    it "defaults to the UpdateSettingsContract" do
      params = { patterns: { subject: { blueprint: "{{author}}", enabled: true } } }

      result = service.call(params)
      expect(result).to be_failure
      expect(result.errors.full_messages).to be_present
    end

    context "when updating attribute groups" do
      let(:contract_class) { UpdateFormConfigurationContract }
      let(:params) do
        { attribute_groups: [
          { "type" => "attribute",
            "name" => "group1",
            "attributes" => [{ "key" => cf1.attribute_name }, { "key" => cf2.attribute_name }] },
          { "type" => "attribute",
            "name" => "groups",
            "attributes" => [{ "key" => cf2.attribute_name }] }
        ] }
      end

      subject(:service) { described_class.new(user:, model:, contract_class:) }

      context "without enterprise feature enabled" do
        it "returns an error" do
          result = service.call(params)
          expect(result).to be_failure
          expect(result.errors.details).to eq(base: [{ action: "Edit Attribute Groups", error: :error_enterprise_only }])
        end
      end

      context "with enterprise feature enabled", with_ee: %i[edit_attribute_groups] do
        it "doesn't change the type if no attribute group is passed" do
          service_result = service.call({})
          expect(service_result.result).to eq(type)
        end

        it "set the attribute groups to the default value if empty" do
          allow(type).to receive(:reset_attribute_groups).and_call_original
          service_result = service.call(attribute_groups: [])

          expect(service_result).to be_success
          expect(type).to have_received(:reset_attribute_groups)
        end

        it "set the attribute groups to the passed values" do
          service_result = service.call(params)

          expect(service_result).to be_success
          group1, groups = *type.reload.attribute_groups

          expect(group1.key).to eq("group1")
          expect(group1.attributes).to contain_exactly(cf1.attribute_name, cf2.attribute_name)
          expect(groups.key).to eq("groups")
          expect(groups.attributes).to contain_exactly(cf2.attribute_name)
        end
      end
    end

    describe "custom field handling" do
      let(:contract_class) { UpdateFormConfigurationContract }
      let(:params) do
        { attribute_groups: [
          { "type" => "attribute",
            "name" => "group1",
            "attributes" => [{ "key" => cf1.attribute_name }, { "key" => cf2.attribute_name }] }
        ] }
      end

      it "enables the custom fields" do
        service.call(params)

        expect(type.reload.custom_field_ids).to contain_exactly(cf1.id, cf2.id)
      end

      context "when a project already uses the type" do
        before { type.projects = create_list(:project, 2) }

        it "does not automatically enable the custom field" do
          expect { service.call(params) }
            .not_to change { Project.where(id: type.project_ids).map(&:work_package_custom_field_ids) }
                      .from([[], []])
        end

        it "does not tries to change the project in case all custom fields are already added" do
          type.custom_field_ids = [cf1.id, cf2.id]

          expect { service.call(params) }
            .not_to change { Project.where(id: type.project_ids).map(&:work_package_custom_field_ids) }
                      .from([[], []])
        end
      end
    end

    describe "query group handling" do
      let(:query_params) do
        statuses = create_list(:status, 2)
        sort_by = JSON::dump(["status:desc"])
        filters = JSON::dump([{ "status_id" => { "operator" => "=", "values" => statuses.map { it.id.to_s } } }])

        { "sortBy" => sort_by, "filters" => filters }
      end

      let(:query_group_params) do
        { "type" => "query", "name" => "group1", "query" => JSON.dump(query_params) }
      end

      let(:params) { { attribute_groups: [query_group_params] } }
      let(:contract_class) { UpdateFormConfigurationContract }

      it "assigns the fully parsed query to the type attribute groups" do
        expect(service.call(params)).to be_success

        query_group = type.attribute_groups.first
        expect(query_group.query).to be_a(Query)
        query = query_group.query
        expect(query.filters.length).to eq(1)
        expect(query.filters[0].name).to eq(:status_id)
      end

      it "returns a failure result for invalid query JSON" do
        invalid_params = {
          attribute_groups: [
            { "type" => "query", "name" => "group1", "query" => "not a json" }
          ]
        }

        result = service.call(invalid_params)

        expect(result).to be_failure
        expect(result.errors.full_messages.to_sentence)
          .to eq(I18n.t("types.edit.form_configuration.invalid_query"))
      end
    end

    context "when attribute_groups is malformed JSON" do
      let(:contract_class) { UpdateFormConfigurationContract }

      it "returns a failure result" do
        result = service.call(attribute_groups: "{")

        expect(result).to be_failure
        expect(result.errors[:attribute_groups].to_sentence)
          .to eq(I18n.t("types.edit.form_configuration.invalid_attribute_groups"))
      end
    end

    context "when adding the type to a project" do
      let(:projects) { create_list(:project, 2) }
      let(:active_project) { create(:project) }
      let(:new_project) { create(:project) }
      let(:project_ids) do
        { project_ids: [*[active_project, new_project].map { it.id.to_s }, ""] }
      end
      let(:contract_class) { UpdateProjectsContract }

      before do
        groups = { attribute_groups: [
          { "type" => "attribute",
            "name" => "group1",
            "attributes" => [{ "key" => cf1.attribute_name }, { "key" => cf2.attribute_name }] }
        ] }

        type.projects << active_project
        described_class.new(model:, user:, contract_class: UpdateFormConfigurationContract).call(groups)
      end

      it "enables the custom field on the newly added project" do
        expect { service.call(project_ids) }.to change { Project.find(new_project.id).work_package_custom_field_ids }
                                                  .from([]).to([cf1.id, cf2.id])
      end

      it "does not enable the custom fields on the already added project" do
        expect { service.call(project_ids) }.not_to change { Project.find(active_project.id).work_package_custom_field_ids }
                                                      .from([])
      end
    end
  end
end
