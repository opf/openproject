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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraCreateCustomFieldsJob do
  include_context "with jira project import data"

  def create_custom_fields
    described_class.perform_now(jira_import.id)
  end

  let(:global_context) { { "projects" => [], "issuetypes" => [] } }

  let!(:list_field) do
    create(:jira_field, jira_import:,
                        origin_id: "customfield_10264",
                        payload: {
                          "id" => "customfield_10264",
                          "name" => "CF List",
                          "schema" => {
                            "type" => "option",
                            "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                            "customId" => 10264
                          },
                          "contextGroups" => [global_context.merge(
                            "allowedValues" => [{ "id" => "1", "value" => "Cat" },
                                                { "id" => "2", "value" => "Mouse" }]
                          )]
                        })
  end

  let!(:string_field) do
    create(:jira_field, jira_import:,
                        origin_id: "customfield_10255",
                        payload: {
                          "id" => "customfield_10255",
                          "name" => "CF String",
                          "schema" => {
                            "type" => "string",
                            "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield",
                            "customId" => 10255
                          }
                        })
  end

  let!(:jira_issue) do
    create(:jira_issue, jira_import:,
                        origin_id: "10200",
                        jira_project:,
                        payload: { "key" => "#{jira_project_key}-1",
                                   "fields" => { "customfield_10264" => { "value" => "Cat" },
                                                 "customfield_10255" => "a value" } })
  end

  describe "#perform" do
    it "creates one custom field per jira field used by the import" do
      expect { create_custom_fields }.to change(WorkPackageCustomField, :count).by(2)

      expect(WorkPackageCustomField.pluck(:name, :field_format))
        .to contain_exactly(["CF List", "list"], ["CF String", "string"])
    end

    it "references the created custom fields against their jira field" do
      create_custom_fields

      custom_field = WorkPackageCustomField.find_by!(name: "CF List")
      reference = Import::JiraOpenProjectReference.find_by(op_entity_class: "WorkPackageCustomField",
                                                           op_entity_id: custom_field.id.to_s)
      expect(reference)
        .to have_attributes(jira_entity_class: "Import::JiraField",
                            jira_entity_id: list_field.id.to_s,
                            jira_import_id: jira_import.id)
    end

    it "creates the list options from the context group" do
      create_custom_fields

      expect(WorkPackageCustomField.find_by!(name: "CF List").custom_options.pluck(:value))
        .to eq(%w[Cat Mouse])
    end

    # Every per-project job rebuilds the registry, so building it repeatedly has to resolve the
    # existing custom fields rather than create another copy of each list and hierarchy field.
    it "is idempotent" do
      create_custom_fields

      expect { create_custom_fields }.not_to change(WorkPackageCustomField, :count)
      expect(WorkPackageCustomField.pluck(:name)).to contain_exactly("CF List", "CF String")
    end

    it "ignores jira fields that no imported issue carries a value for" do
      create(:jira_field, jira_import:,
                          origin_id: "customfield_19999",
                          payload: {
                            "id" => "customfield_19999",
                            "name" => "CF Unused",
                            "schema" => {
                              "type" => "string",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield",
                              "customId" => 19999
                            }
                          })

      create_custom_fields

      expect(WorkPackageCustomField.find_by(name: "CF Unused")).to be_nil
    end
  end
end
