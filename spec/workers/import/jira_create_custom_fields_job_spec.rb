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

  def store_index
    Import::JiraFetchCustomFieldJob.new.send(:prepare_jira_import_ivars, jira_import.id)
    index = Import::JiraCustomField::IssueValueIndex.scan(jira_import)
    Import::JiraCustomField::IssueValueIndex.serialize(index).each do |origin_id, issue_values|
      Import::JiraField.where(jira_import:, origin_id:).update_all(issue_values:)
    end
    Import::JiraField.where(jira_import:).where(issue_values: nil).update_all(issue_values: { "used" => false })
  end

  def jira_issue_reads(&)
    reads = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      reads += 1 if payload[:sql].include?("jira_issues") && payload[:name] != "SCHEMA"
    end
    yield
    reads
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
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
    # custom fields of an earlier build rather than create another copy.
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

  describe "with the issue value index stored by stage 3" do
    it "reads no issues at all" do
      store_index

      expect(jira_issue_reads { create_custom_fields }).to eq(0)
    end

    it "creates the same custom fields as a scan would" do
      store_index
      create_custom_fields

      expect(WorkPackageCustomField.pluck(:name, :field_format))
        .to contain_exactly(["CF List", "list"], ["CF String", "string"])
      expect(WorkPackageCustomField.find_by!(name: "CF List").custom_options.pluck(:value)).to eq(%w[Cat Mouse])
    end

    # A field carrying neither options nor strings is stored used with empty buckets; read as
    # unused it would drop out of the registry entirely.
    it "keeps a plain text field in the registry" do
      store_index
      create_custom_fields

      expect(WorkPackageCustomField.find_by(name: "CF String")).to be_present
    end

    it "falls back to scanning when a single field has no stored index" do
      store_index
      Import::JiraField.where(id: list_field.id).update_all(issue_values: nil)

      expect(jira_issue_reads { create_custom_fields }).to be > 0
      expect(WorkPackageCustomField.pluck(:name)).to contain_exactly("CF List", "CF String")
    end

    it "records the custom field of every context group on the field" do
      store_index
      create_custom_fields

      mapping = list_field.reload.issue_values["custom_fields"]
      signature = Import::JiraCustomField::ContextSignature.key(list_field.payload["contextGroups"].first["allowedValues"])
      expect(mapping).to eq(signature => WorkPackageCustomField.find_by!(name: "CF List").id)
    end

    it "resolves an existing mapping without matching or locking" do
      store_index
      create_custom_fields
      allow(OpenProject::Mutex).to receive(:with_advisory_lock).and_call_original

      expect { create_custom_fields }.not_to change(WorkPackageCustomField, :count)
      expect(OpenProject::Mutex).not_to have_received(:with_advisory_lock)
    end

    it "creates the field again when the mapped one is gone" do
      store_index
      create_custom_fields
      WorkPackageCustomField.find_by!(name: "CF List").destroy

      expect { create_custom_fields }.to change(WorkPackageCustomField, :count).by(1)
      expect(WorkPackageCustomField.where(name: "CF List")).to exist
    end
  end

  describe "multicheckbox fields whose shape follows the option count" do
    let!(:multicheckbox_field) do
      create(:jira_field, jira_import:,
                          origin_id: "customfield_10300",
                          payload: {
                            "id" => "customfield_10300",
                            "name" => "CF Checks",
                            "schema" => {
                              "type" => "array",
                              "items" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                              "customId" => 10300
                            },
                            "contextGroups" => [global_context.merge("allowedValues" => [{ "value" => "Only" }])]
                          })
    end

    let!(:multicheckbox_issue) do
      create(:jira_issue, jira_import:,
                          origin_id: "10300",
                          jira_project:,
                          payload: { "key" => "#{jira_project_key}-2",
                                     "fields" => { "project" => { "id" => jira_project_id, "key" => jira_project_key },
                                                   "issuetype" => { "id" => "10100" },
                                                   "customfield_10300" => [{ "value" => "Only" }] } })
    end

    # One option gained or lost across the round trip flips the format and renames the field, so
    # the stored index has to reproduce the option set exactly.
    it "keeps the boolean split and the field name across a store-and-load round trip" do
      create_custom_fields
      scanned = WorkPackageCustomField.pluck(:name, :field_format)
      WorkPackageCustomField.destroy_all
      Import::JiraField.where(jira_import:).update_all(issue_values: nil)
      store_index

      create_custom_fields

      expect(WorkPackageCustomField.pluck(:name, :field_format)).to match_array(scanned)
      expect(WorkPackageCustomField.find_by(name: "CF Checks - Only")).to have_attributes(field_format: "bool")
    end
  end
end
