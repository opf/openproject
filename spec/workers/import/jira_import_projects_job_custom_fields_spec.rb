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

RSpec.describe Import::JiraImportProjectsJob,
               :webmock,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  let(:jira)       { create(:jira) }
  let(:author)     { create(:user) }
  let(:jira_import) do
    create(:jira_import, jira:, author:,
                         projects: [{ "id" => "10012", "key" => "DPPP", "name" => "Demo project" }])
  end
  let(:jira_project_payload) { JSON.parse(Rails.root.join("spec/fixtures/import/jira/project.json").read) }
  let(:jira_user_payload)    { JSON.parse(Rails.root.join("spec/fixtures/import/jira/user.json").read) }

  # Issue with values for all custom field types
  # (spec/fixtures/import/jira/issue_with_custom_fields.json)
  let(:issue_payload) do
    JSON.parse(Rails.root.join("spec/fixtures/import/jira/issue_with_custom_fields.json").read)
  end

  let!(:jira_project) do
    create(:jira_project,
           jira:,
           jira_import:,
           jira_project_id: "10012",
           payload: jira_project_payload)
  end
  let!(:default_status) { create(:default_status) }

  # Standard Jira-side entities required for every import run
  let!(:jira_issue_type) do
    create(:jira_issue_type,
           jira:,
           jira_import:,
           jira_issue_type_id: "10100",
           payload: { "id" => "10100", "name" => "Task" })
  end
  let!(:jira_status) do
    create(:jira_status,
           jira:,
           jira_import:,
           jira_status_id: "3",
           payload: { "id" => "3", "name" => "In Progress" })
  end
  let!(:jira_priority) do
    create(:jira_priority,
           jira:,
           jira_import:,
           jira_priority_id: "1",
           payload: { "id" => "1", "name" => "Highest" })
  end
  let!(:jira_user) do
    create(:jira_user,
           jira:,
           jira_import:,
           jira_user_key: "JIRAUSER10000",
           payload: jira_user_payload)
  end
  let!(:op_user) { create(:user, login: "e.xample", mail: "e.xample@example.com") }
  let!(:jira_user_reference) do
    create(:jira_open_project_reference,
           jira:,
           jira_import:,
           jira_entity_class: "Import::JiraUser",
           jira_entity_id: jira_user.id.to_s,
           op_entity_class: "User",
           op_entity_id: op_user.id.to_s)
  end

  # Context shared across all examples - applies to all projects & issue types
  # (empty arrays mean "applies everywhere").
  let(:global_context) { { "projects" => [], "issuetypes" => [] } }

  # Helper: look up the work package created by the import
  def imported_wp
    WorkPackage.find_by!(subject: "Issue with all custom field types")
  end

  # Helper: look up the OP custom field by name and return its value on the WP
  def cf_value(cf_name)
    cf = WorkPackageCustomField.find_by!(name: cf_name)
    imported_wp.send(cf.attribute_getter)
  end

  describe "string field (com.atlassian.jira.plugin.system.customfieldtypes:textfield)" do
    # Jira value: plain string -> stored as-is.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10255",
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
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'string' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF String").field_format).to eq("string")
    end

    it "sets the string value on the work package" do
      expect(cf_value("CF String")).to eq("my plain string value")
    end
  end

  describe "textarea field (com.atlassian.jira.plugin.system.customfieldtypes:textarea)" do
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10275",
                          payload: {
                            "id" => "customfield_10275",
                            "name" => "CF Text",
                            "schema" => {
                              "type" => "string",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textarea",
                              "customId" => 10275
                            }
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'text' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF Text").field_format).to eq("text")
    end

    it "converts Jira wiki markup to OP markdown (bold *x* -> **x**)" do
      expect(cf_value("CF Text")).to include("**bold**")
    end
  end

  describe "number field (com.atlassian.jira.plugin.system.customfieldtypes:float)" do
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10254",
                          payload: {
                            "id" => "customfield_10254",
                            "name" => "CF Number",
                            "schema" => {
                              "type" => "number",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:float",
                              "customId" => 10254
                            }
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'float' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF Number").field_format).to eq("float")
    end

    it "sets the numeric value on the work package" do
      expect(cf_value("CF Number").to_f).to eq(42.5)
    end
  end

  describe "date field (com.atlassian.jira.plugin.system.customfieldtypes:datepicker)" do
    # Jira value: ISO date string "2024-06-15".
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10261",
                          payload: {
                            "id" => "customfield_10261",
                            "name" => "CF Date",
                            "schema" => {
                              "type" => "date",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datepicker",
                              "customId" => 10261
                            }
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'date' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF Date").field_format).to eq("date")
    end

    it "stores the date value on the work package" do
      expect(cf_value("CF Date")).to eq(Date.parse("2024-06-15"))
    end
  end

  describe "URL field (com.atlassian.jira.plugin.system.customfieldtypes:url)" do
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10257",
                          payload: {
                            "id" => "customfield_10257",
                            "name" => "CF URL",
                            "schema" => {
                              "type" => "string",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:url",
                              "customId" => 10257
                            }
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'link' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF URL").field_format).to eq("link")
    end

    it "stores the URL string on the work package" do
      expect(cf_value("CF URL")).to eq("https://example.com")
    end
  end

  describe "single-select list field (com.atlassian.jira.plugin.system.customfieldtypes:select)" do
    # contextGroups populated as JiraFetchCustomFields would after editmeta.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10264",
                          payload: {
                            "id" => "customfield_10264",
                            "name" => "CF List",
                            "schema" => {
                              "type" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                              "customId" => 10264
                            },
                            "contextGroups" => [
                              global_context.merge(
                                "allowedValues" => [
                                  { "id" => "10141", "value" => "Cat" },
                                  { "id" => "10142", "value" => "Dog" },
                                  { "id" => "10143", "value" => "Green" },
                                  { "id" => "10144", "value" => "Red" }
                                ]
                              )
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'list' custom field with the available options" do
      cf = WorkPackageCustomField.find_by!(name: "CF List")
      expect(cf.field_format).to eq("list")
      expect(cf.custom_options.pluck(:value)).to contain_exactly("Cat", "Dog", "Green", "Red")
    end

    it "is not multi-value" do
      cf = WorkPackageCustomField.find_by!(name: "CF List")
      expect(cf.multi_value).to be false
    end

    it "sets the selected option on the work package" do
      expect(cf_value("CF List")).to eq("Cat")
    end
  end

  describe "multi-select list field (com.atlassian.jira.plugin.system.customfieldtypes:multiselect)" do
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10265",
                          payload: {
                            "id" => "customfield_10265",
                            "name" => "CF Multi-List",
                            "schema" => {
                              "type" => "array",
                              "items" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect",
                              "customId" => 10265
                            },
                            "contextGroups" => [
                              global_context.merge(
                                "allowedValues" => [
                                  { "id" => "10145", "value" => "Mouse" },
                                  { "id" => "10146", "value" => "Turtle" }
                                ]
                              )
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'list' custom field that is multi-value" do
      cf = WorkPackageCustomField.find_by!(name: "CF Multi-List")
      expect(cf.field_format).to eq("list")
      expect(cf.multi_value).to be true
    end

    it "sets both selected options on the work package" do
      # attribute_getter returns an array of option strings for multi-value list CFs
      expect(cf_value("CF Multi-List")).to contain_exactly("Mouse", "Turtle")
    end
  end

  describe "multicheckboxes field (com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes)" do
    # Multiple checkbox options produce a single multi-value list custom field.
    # Jira value: array of selected options -> list option values on the CF.
    let(:multicheckboxes_field_payload) do
      {
        "id" => "customfield_10260",
        "name" => "CF Booleans",
        "schema" => {
          "type" => "array",
          "items" => "option",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
          "customId" => 10260
        },
        "contextGroups" => [
          global_context.merge(
            "allowedValues" => [
              { "id" => "10137",
                "self" => "https://jira-software.local/rest/api/2/customFieldOption/10137",
                "value" => "Check 1",
                "disabled" => false },
              { "id" => "10138",
                "self" => "https://jira-software.local/rest/api/2/customFieldOption/10138",
                "value" => "Check 2",
                "disabled" => false }
            ]
          )
        ]
      }
    end

    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10260",
                          payload: multicheckboxes_field_payload)
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates one multi-value list custom field" do
      cf = WorkPackageCustomField.find_by!(name: "CF Booleans")
      expect(cf.field_format).to eq("list")
      expect(cf.multi_value).to be true
    end

    it "populates all checkbox options as possible values" do
      cf = WorkPackageCustomField.find_by!(name: "CF Booleans")
      expect(cf.custom_options.pluck(:value)).to contain_exactly("Check 1", "Check 2")
    end

    it "sets the selected options as list values on the work package" do
      # The fixture has only 'Check 1' selected
      expect(cf_value("CF Booleans")).to contain_exactly("Check 1")
    end

    it "adds the list custom field to the work package type" do
      type = Type.find_by!(name: "Task")
      expect(type.custom_fields.pluck(:name)).to include("CF Booleans")
    end
  end

  describe "multicheckboxes field with a single option (com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes)" do
    # A single checkbox option produces one boolean custom field.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10260",
                          payload: {
                            "id" => "customfield_10260",
                            "name" => "CF Booleans",
                            "schema" => {
                              "type" => "array",
                              "items" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                              "customId" => 10260
                            },
                            "contextGroups" => [
                              global_context.merge(
                                "allowedValues" => [
                                  { "id" => "10137",
                                    "self" => "https://jira-software.local/rest/api/2/customFieldOption/10137",
                                    "value" => "Check 1",
                                    "disabled" => false }
                                ]
                              )
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates one boolean custom field named after the Jira field" do
      cf = WorkPackageCustomField.find_by!(name: "CF Booleans - Check 1")
      expect(cf.field_format).to eq("bool")
    end

    it "sets the value to true when the option is selected" do
      # The fixture has 'Check 1' selected
      expect(cf_value("CF Booleans - Check 1")).to be true
    end
  end

  describe "multicheckboxes with multiple context groups and different multi-option sets per context" do
    # Two context groups each have 2+ options (different sets) -> one list CF per context group.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10285",
                          payload: {
                            "id" => "customfield_10285",
                            "name" => "CF Multi-Context Checks",
                            "schema" => {
                              "type" => "array",
                              "items" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                              "customId" => 10285
                            },
                            "contextGroups" => [
                              {
                                "projects" => ["DPPP"], "issuetypes" => [],
                                "allowedValues" => [{ "id" => "10200", "value" => "Alpha" },
                                                    { "id" => "10201", "value" => "Beta" }]
                              },
                              {
                                "projects" => ["ZBX"], "issuetypes" => [],
                                "allowedValues" => [{ "id" => "10202", "value" => "Gamma" },
                                                    { "id" => "10203", "value" => "Delta" }]
                              }
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates one multi-value list CF per context group" do
      cf_dyx = WorkPackageCustomField.find_by!(name: "CF Multi-Context Checks (DPPP)")
      cf_zbx = WorkPackageCustomField.find_by!(name: "CF Multi-Context Checks (ZBX)")
      expect(cf_dyx.field_format).to eq("list")
      expect(cf_zbx.field_format).to eq("list")
      expect(cf_dyx.multi_value).to be true
      expect(cf_zbx.multi_value).to be true
    end

    it "populates each CF with its own set of options" do
      cf_dyx = WorkPackageCustomField.find_by!(name: "CF Multi-Context Checks (DPPP)")
      cf_zbx = WorkPackageCustomField.find_by!(name: "CF Multi-Context Checks (ZBX)")
      expect(cf_dyx.custom_options.pluck(:value)).to contain_exactly("Alpha", "Beta")
      expect(cf_zbx.custom_options.pluck(:value)).to contain_exactly("Gamma", "Delta")
    end

    it "sets the value using the issue's matching context CF" do
      # The issue is from project DPPP and has 'Alpha' selected
      expect(cf_value("CF Multi-Context Checks (DPPP)")).to contain_exactly("Alpha")
    end
  end

  describe "multicheckboxes with multiple context groups each having a different single option" do
    # Each context group has a different single option -> so one boolean CF per group.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10287",
                          payload: {
                            "id" => "customfield_10287",
                            "name" => "CF Different-Single Checks",
                            "schema" => {
                              "type" => "array",
                              "items" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                              "customId" => 10287
                            },
                            "contextGroups" => [
                              {
                                "projects" => ["DPPP"], "issuetypes" => [],
                                "allowedValues" => [{ "id" => "10205", "value" => "Yes" }]
                              },
                              {
                                "projects" => ["ZBX"], "issuetypes" => [],
                                "allowedValues" => [{ "id" => "10206", "value" => "No" }]
                              }
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates one list CF per context group" do
      cf_dyx = WorkPackageCustomField.find_by!(name: "CF Different-Single Checks - Yes (DPPP)")
      cf_zbx = WorkPackageCustomField.find_by!(name: "CF Different-Single Checks - No (ZBX)")
      expect(cf_dyx.field_format).to eq("bool")
      expect(cf_zbx.field_format).to eq("bool")
    end

    it "sets the value from the issue's matching context" do
      # The issue is from project DPPP and has 'Yes' selected
      expect(cf_value("CF Different-Single Checks - Yes (DPPP)")).to be(true)
    end
  end

  describe "radiobuttons field (com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons)" do
    # Jira value: single option object -> stored as a single-select (non-multi) list value.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10290",
                          payload: {
                            "id" => "customfield_10290",
                            "name" => "CF Radio",
                            "schema" => {
                              "type" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons",
                              "customId" => 10290
                            },
                            "contextGroups" => [
                              global_context.merge(
                                "allowedValues" => [
                                  { "id" => "10290", "value" => "Option A" },
                                  { "id" => "10291", "value" => "Option B" }
                                ]
                              )
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a single-select (non-multi) 'list' custom field" do
      cf = WorkPackageCustomField.find_by!(name: "CF Radio")
      expect(cf.field_format).to eq("list")
      expect(cf.multi_value).to be false
    end

    it "populates all radio options as possible values" do
      cf = WorkPackageCustomField.find_by!(name: "CF Radio")
      expect(cf.custom_options.pluck(:value)).to contain_exactly("Option A", "Option B")
    end

    it "sets the selected option as the list value on the work package" do
      expect(cf_value("CF Radio")).to eq("Option A")
    end

    it "adds the list custom field to the work package type" do
      type = Type.find_by!(name: "Task")
      expect(type.custom_fields.pluck(:name)).to include("CF Radio")
    end
  end

  describe "radiobuttons with multiple context groups (com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons)" do
    # Two context groups have different option sets -> one single-select list CF per context group.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10291",
                          payload: {
                            "id" => "customfield_10291",
                            "name" => "CF Radio Multi-Context",
                            "schema" => {
                              "type" => "option",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons",
                              "customId" => 10291
                            },
                            "contextGroups" => [
                              {
                                "projects" => ["DPPP"], "issuetypes" => [],
                                "allowedValues" => [{ "id" => "10300", "value" => "North" },
                                                    { "id" => "10301", "value" => "South" }]
                              },
                              {
                                "projects" => ["ZBX"], "issuetypes" => [],
                                "allowedValues" => [{ "id" => "10302", "value" => "East" },
                                                    { "id" => "10303", "value" => "West" }]
                              }
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates one single-select list CF per context group" do
      cf_dyx = WorkPackageCustomField.find_by!(name: "CF Radio Multi-Context (DPPP)")
      cf_zbx = WorkPackageCustomField.find_by!(name: "CF Radio Multi-Context (ZBX)")
      expect(cf_dyx.field_format).to eq("list")
      expect(cf_zbx.field_format).to eq("list")
      expect(cf_dyx.multi_value).to be false
      expect(cf_zbx.multi_value).to be false
    end

    it "populates each CF with its own set of options" do
      cf_dyx = WorkPackageCustomField.find_by!(name: "CF Radio Multi-Context (DPPP)")
      cf_zbx = WorkPackageCustomField.find_by!(name: "CF Radio Multi-Context (ZBX)")
      expect(cf_dyx.custom_options.pluck(:value)).to contain_exactly("North", "South")
      expect(cf_zbx.custom_options.pluck(:value)).to contain_exactly("East", "West")
    end

    it "sets the value using the issue's matching context CF" do
      # The issue is from project DPPP and has 'North' selected
      expect(cf_value("CF Radio Multi-Context (DPPP)")).to eq("North")
    end
  end

  describe "string-array list field (com.atlassian.jira.plugin.system.customfieldtypes:labels)" do
    # Jira value: plain string array -> options collected from issues, stored as multi-value list.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10280",
                          payload: {
                            "id" => "customfield_10280",
                            "name" => "CF Labels",
                            "schema" => {
                              "type" => "array",
                              "items" => "string",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:labels",
                              "customId" => 10280
                            }
                            # No contextGroups/allowedValues - options are collected from issue values
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a multi-value 'list' custom field" do
      cf = WorkPackageCustomField.find_by!(name: "CF Labels")
      expect(cf.field_format).to eq("list")
      expect(cf.multi_value).to be true
    end

    it "populates options from the values found in imported issues" do
      cf = WorkPackageCustomField.find_by!(name: "CF Labels")
      expect(cf.custom_options.pluck(:value)).to contain_exactly("Label A", "Label B")
    end

    it "sets the selected labels on the work package" do
      expect(cf_value("CF Labels")).to contain_exactly("Label A", "Label B")
    end
  end

  describe "user field (com.atlassian.jira.plugin.system.customfieldtypes:userpicker)" do
    # Jira value: user object with "key" -> resolved to OP User via JiraOpenProjectReference.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10258",
                          payload: {
                            "id" => "customfield_10258",
                            "name" => "CF User",
                            "schema" => {
                              "type" => "user",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:userpicker",
                              "customId" => 10258
                            }
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'user' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF User").field_format).to eq("user")
    end

    it "resolves the Jira user key to the mapped OP user" do
      # Fixture value has key JIRAUSER10000 which is mapped to op_user via jira_user_reference
      expect(cf_value("CF User")).to eq(op_user)
    end
  end

  describe "cascading select / hierarchy field (com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect)",
           with_ee: [:custom_field_hierarchies] do
    # Jira value: option-with-child -> hierarchy item.
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10266",
                          payload: {
                            "id" => "customfield_10266",
                            "name" => "CF Cascading",
                            "schema" => {
                              "type" => "option-with-child",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect",
                              "customId" => 10266
                            },
                            "contextGroups" => [
                              global_context.merge(
                                "allowedValues" => [
                                  { "id" => "10150", "value" => "Critical",
                                    "children" => [
                                      { "id" => "10151", "value" => "Security" },
                                      { "id" => "10152", "value" => "Performance" }
                                    ] },
                                  { "id" => "10153", "value" => "Major",
                                    "children" => [
                                      { "id" => "10154", "value" => "Data Loss" }
                                    ] }
                                ]
                              )
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a 'hierarchy' custom field" do
      expect(WorkPackageCustomField.find_by!(name: "CF Cascading").field_format).to eq("hierarchy")
    end

    it "populates the hierarchy with parent items" do
      cf = WorkPackageCustomField.find_by!(name: "CF Cascading")
      root = cf.hierarchy_root
      expect(root.children.pluck(:label)).to contain_exactly("Critical", "Major")
    end

    it "populates child items under parents" do
      cf = WorkPackageCustomField.find_by!(name: "CF Cascading")
      critical = cf.hierarchy_root.children.find_by(label: "Critical")
      expect(critical.children.pluck(:label)).to contain_exactly("Security", "Performance")
    end

    it "sets the hierarchy value (child item) on the work package" do
      # Fixture selects Critical > Security
      cf = WorkPackageCustomField.find_by!(name: "CF Cascading")
      value = imported_wp.send(cf.attribute_getter)
      expect(value).to be_a(CustomField::Hierarchy::Item)
      expect(value.label).to eq("Security")
    end
  end

  describe "cascading select without enterprise - fallback to multi-value list" do
    # Without EE the cascading select becomes a flat multi-value list containing
    # every node (root + children) as an option. The selected value is imported
    # as all nodes on the selected path (parent + child).
    let!(:jira_field) do
      create(:jira_field, jira:, jira_import:,
                          jira_field_id: "customfield_10266",
                          payload: {
                            "id" => "customfield_10266",
                            "name" => "CF Cascading",
                            "schema" => {
                              "type" => "option-with-child",
                              "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect",
                              "customId" => 10266
                            },
                            "contextGroups" => [
                              global_context.merge(
                                "allowedValues" => [
                                  { "id" => "10150", "value" => "Critical",
                                    "children" => [
                                      { "id" => "10151", "value" => "Security" },
                                      { "id" => "10152", "value" => "Performance" }
                                    ] },
                                  { "id" => "10153", "value" => "Major",
                                    "children" => [
                                      { "id" => "10154", "value" => "Data Loss" }
                                    ] }
                                ]
                              )
                            ]
                          })
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    before { described_class.new.perform(jira_import.id) }

    it "creates a multi-value 'list' custom field" do
      cf = WorkPackageCustomField.find_by!(name: "CF Cascading")
      expect(cf.field_format).to eq("list")
      expect(cf.multi_value).to be true
    end

    it "populates all tree nodes as path-based list options" do
      cf = WorkPackageCustomField.find_by!(name: "CF Cascading")
      expect(cf.custom_options.pluck(:value)).to contain_exactly(
        "Critical",
        "Critical / Security",
        "Critical / Performance",
        "Major",
        "Major / Data Loss"
      )
    end

    it "sets the selected path (parent + child) as path-based list values on the work package" do
      # Fixture selects Critical > Security -> chain is ["Critical", "Critical / Security"]
      expect(cf_value("CF Cascading")).to contain_exactly("Critical", "Critical / Security")
    end
  end

  describe "all custom field types in a single import run", with_ee: [:custom_field_hierarchies] do
    # Registers all field types at once and verifies the correct number of
    # OP custom fields are created:
    let!(:jira_fields) do
      [
        { id: "customfield_10255", name: "CF String",
          schema: { "type" => "string",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield" } },
        { id: "customfield_10275", name: "CF Text",
          schema: { "type" => "string",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textarea" } },
        { id: "customfield_10254", name: "CF Number",
          schema: { "type" => "number",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:float" } },
        { id: "customfield_10261", name: "CF Date",
          schema: { "type" => "date",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datepicker" } },
        { id: "customfield_10257", name: "CF URL",
          schema: { "type" => "string",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:url" } },
        { id: "customfield_10258", name: "CF User",
          schema: { "type" => "user",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:userpicker" } },
        { id: "customfield_10280", name: "CF Labels",
          schema: { "type" => "array", "items" => "string",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:labels" } },
        { id: "customfield_10264", name: "CF List",
          schema: { "type" => "option",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select" },
          context_groups: [global_context.merge(
            "allowedValues" => [{ "id" => "10141", "value" => "Cat" },
                                { "id" => "10142", "value" => "Dog" }]
          )] },
        { id: "customfield_10265", name: "CF Multi-List",
          schema: { "type" => "array", "items" => "option",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect" },
          context_groups: [global_context.merge(
            "allowedValues" => [{ "id" => "10145", "value" => "Mouse" },
                                { "id" => "10146", "value" => "Turtle" }]
          )] },
        { id: "customfield_10266", name: "CF Cascading",
          schema: { "type" => "option-with-child",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect" },
          context_groups: [global_context.merge(
            "allowedValues" => [
              { "id" => "10150", "value" => "Critical",
                "children" => [{ "id" => "10151", "value" => "Security" },
                               { "id" => "10152", "value" => "Performance" }] },
              { "id" => "10153", "value" => "Major",
                "children" => [{ "id" => "10154", "value" => "Data Loss" }] }
            ]
          )] },
        { id: "customfield_10260", name: "CF Booleans",
          schema: { "type" => "array", "items" => "option",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes" },
          context_groups: [global_context.merge(
            "allowedValues" => [{ "id" => "10137", "value" => "Check 1" },
                                { "id" => "10138", "value" => "Check 2" }]
          )] },
        { id: "customfield_10270", name: "CF Boolean",
          schema: { "type" => "array", "items" => "option",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes" },
          context_groups: [global_context.merge(
            "allowedValues" => [{ "id" => "10139", "value" => "Yes" }]
          )] },
        { id: "customfield_10290", name: "CF Radio",
          schema: { "type" => "option",
                    "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons" },
          context_groups: [global_context.merge(
            "allowedValues" => [{ "id" => "10290", "value" => "Option A" },
                                { "id" => "10291", "value" => "Option B" }]
          )] }
      ].map do |field_def|
        payload = { "id" => field_def[:id], "name" => field_def[:name], "schema" => field_def[:schema] }
        payload["contextGroups"] = field_def[:context_groups] if field_def[:context_groups]
        create(:jira_field, jira:, jira_import:,
                            jira_field_id: field_def[:id],
                            payload:)
      end
    end
    let!(:jira_issue) do
      create(:jira_issue, jira:, jira_import:,
                          jira_issue_id: "10200",
                          jira_project_id: jira_project.id,
                          payload: issue_payload)
    end

    it "creates the correct number of OpenProject custom fields" do
      expect { described_class.new.perform(jira_import.id) }
        .to change(WorkPackageCustomField, :count).by(13)
    end

    context "on after the import" do
      before { described_class.new.perform(jira_import.id) }

      it "creates custom fields with the right formats" do
        expected = {
          "CF String" => "string",
          "CF Text" => "text",
          "CF Number" => "float",
          "CF Date" => "date",
          "CF URL" => "link",
          "CF User" => "user",
          "CF Labels" => "list",
          "CF List" => "list",
          "CF Multi-List" => "list",
          "CF Cascading" => "hierarchy",
          "CF Booleans" => "list",
          "CF Boolean - Yes" => "bool",
          "CF Radio" => "list"
        }
        formats = WorkPackageCustomField.where(name: expected.keys).index_by(&:name).transform_values(&:field_format)
        expect(formats).to eq(expected)
      end

      it "sets all scalar values correctly on the work package" do
        aggregate_failures do
          expect(cf_value("CF String")).to eq("my plain string value")
          expect(cf_value("CF Number").to_f).to eq(42.5)
          expect(cf_value("CF Date")).to eq(Date.parse("2024-06-15"))
          expect(cf_value("CF URL")).to eq("https://example.com")
          expect(cf_value("CF Text")).to include("**bold**")
        end
      end

      it "resolves the user field to the mapped OP user" do
        expect(cf_value("CF User")).to eq(op_user)
      end

      it "sets the string-array labels on the work package" do
        expect(cf_value("CF Labels")).to contain_exactly("Label A", "Label B")
      end

      it "sets the single-select list value correctly" do
        expect(cf_value("CF List")).to eq("Cat")
      end

      it "sets the multi-select list values correctly" do
        expect(cf_value("CF Multi-List")).to contain_exactly("Mouse", "Turtle")
      end

      it "sets the hierarchy value (child item) on the work package" do
        cf = WorkPackageCustomField.find_by!(name: "CF Cascading")
        value = imported_wp.send(cf.attribute_getter)
        expect(value).to be_a(CustomField::Hierarchy::Item)
        expect(value.label).to eq("Security")
      end

      it "sets multicheckbox selected options as list values correctly" do
        expect(cf_value("CF Booleans")).to contain_exactly("Check 1")
      end

      it "sets the radiobuttons selected option as the list value correctly" do
        expect(cf_value("CF Radio")).to eq("Option A")
      end
    end
  end
end
