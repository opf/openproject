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

RSpec.describe Import::JiraCreateProjectJob::JiraImportCustomFieldBuilder do
  let(:custom_field) { instance_double(WorkPackageCustomField) }

  def jira_field_for(name:, schema:, context_groups: nil)
    payload = { "name" => name, "schema" => schema }
    payload["contextGroups"] = context_groups if context_groups
    instance_double(Import::JiraField, payload:)
  end

  describe "#format" do
    subject(:format) { described_class.new(jira_field).format }

    context "with a plain text field (textfield)" do
      let(:jira_field) do
        jira_field_for(name: "CF String",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield",
                                 "customId" => 10255 })
      end

      it { is_expected.to eq("string") }
    end

    context "with a textarea field (textarea) plain" do
      let(:jira_field) do
        jira_field_for(name: "CF text",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textarea",
                                 "customId" => 10275 })
      end

      it { is_expected.to eq("text") }
    end

    context "with a number field (float)" do
      let(:jira_field) do
        jira_field_for(name: "CF Number",
                       schema: { "type" => "number",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:float",
                                 "customId" => 10254 })
      end

      it { is_expected.to eq("float") }
    end

    context "with a date field (datepicker)" do
      let(:jira_field) do
        jira_field_for(name: "CF Date",
                       schema: { "type" => "date",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datepicker",
                                 "customId" => 10261 })
      end

      it { is_expected.to eq("date") }
    end

    context "with a datetime field (data loss!)" do
      let(:jira_field) do
        jira_field_for(name: "CF Datetime",
                       schema: { "type" => "datetime",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datetime",
                                 "customId" => 10262 })
      end

      it { is_expected.to eq("date") }
    end

    context "with a URL field (url)" do
      let(:jira_field) do
        jira_field_for(name: "CF URL",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:url",
                                 "customId" => 10257 })
      end

      it { is_expected.to eq("link") }
    end

    context "with a single-user field (userpicker)" do
      let(:jira_field) do
        jira_field_for(name: "CF User",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:userpicker",
                                 "customId" => 10258 })
      end

      it { is_expected.to eq("user") }
    end

    context "with a multi-user field (multiuserpicker)" do
      let(:jira_field) do
        jira_field_for(name: "CF Users",
                       schema: { "type" => "array",
                                 "items" => "user",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiuserpicker",
                                 "customId" => 10259 })
      end

      it { is_expected.to eq("user") }
    end

    context "with a single-select field (select)" do
      let(:jira_field) do
        jira_field_for(name: "CF List",
                       schema: { "type" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                                 "customId" => 10264 })
      end

      it { is_expected.to eq("list") }
    end

    context "with a multi-select field (multiselect)" do
      let(:jira_field) do
        jira_field_for(name: "CF Multi-List",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect",
                                 "customId" => 10265 })
      end

      it { is_expected.to eq("list") }
    end

    context "with a radiobuttons field" do
      let(:jira_field) do
        jira_field_for(name: "CF Radio",
                       schema: { "type" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons",
                                 "customId" => 10290 })
      end

      it { is_expected.to eq("list") }
    end

    context "with a string-array field (e.g. labels)" do
      let(:jira_field) do
        jira_field_for(name: "CF Labels",
                       schema: { "type" => "array",
                                 "items" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:labels",
                                 "customId" => 10280 })
      end

      it { is_expected.to eq("list") }
    end

    context "with a cascading select field (hierarchy, enterprise enabled)", with_ee: [:custom_field_hierarchies] do
      let(:jira_field) do
        jira_field_for(name: "CF Cascading",
                       schema: { "type" => "option-with-child",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect",
                                 "customId" => 10266 })
      end

      it { is_expected.to eq("hierarchy") }
    end

    context "with a cascading select field (no enterprise)" do
      let(:jira_field) do
        jira_field_for(name: "CF Cascading",
                       schema: { "type" => "option-with-child",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect",
                                 "customId" => 10266 })
      end

      it "falls back to a multi-value list" do
        expect(subject).to eq("list")
      end
    end

    context "with a multicheckboxes field WITHOUT option_value" do
      # Without option_value the builder falls through to the schema mapping (list).
      let(:jira_field) do
        jira_field_for(name: "CF Booleans",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                                 "customId" => 10260 })
      end

      it "returns 'list' (schema-based fallback, not bool)" do
        expect(subject).to eq("list")
      end
    end

    context "with a multicheckboxes field WITH option_value" do
      let(:jira_field) do
        jira_field_for(name: "CF Booleans",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes",
                                 "customId" => 10260 })
      end

      it "returns 'bool'" do
        builder = described_class.new(jira_field, option_value: "Check 1")
        expect(builder.format).to eq("bool")
      end
    end
  end

  describe "#custom_field_settings" do
    let(:context_group) do
      {
        "projects" => ["ZB"],
        "issuetypes" => ["10002"],
        "allowedValues" => [
          { "value" => "Cat" }, { "value" => "Dog" }
        ]
      }
    end

    context "with a non-list field (no context_group)" do
      let(:jira_field) do
        jira_field_for(name: "CF String",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield" })
      end

      it "uses the field name as-is" do
        name, fmt = described_class.new(jira_field).custom_field_settings
        expect(name).to eq("CF String")
        expect(fmt).to eq("string")
      end
    end

    context "with a list field and a context_group with projects" do
      let(:jira_field) do
        jira_field_for(name: "CF List",
                       schema: { "type" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select" })
      end

      it "appends the project keys to the name" do
        name, = described_class.new(jira_field, context_group:).custom_field_settings
        expect(name).to eq("CF List")
      end
    end

    context "with a multicheckboxes field and option_value" do
      let(:jira_field) do
        jira_field_for(name: "CF Booleans",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes" })
      end

      it "uses the base field name with option suffix and not the project key suffix" do
        name, fmt = described_class.new(jira_field, context_group:, option_value: "Check 1").custom_field_settings
        expect(name).to eq("CF Booleans - Check 1")
        expect(fmt).to eq("bool")
      end
    end
  end

  describe "#custom_field_parameters" do
    context "with a list field that has allowedValues in the context group" do
      let(:context_group) do
        {
          "projects" => ["DYX"],
          "issuetypes" => ["10100"],
          "allowedValues" => [
            { "id" => "10141", "value" => "Cat" },
            { "id" => "10142", "value" => "Dog" }
          ]
        }
      end
      let(:jira_field) do
        jira_field_for(name: "CF List",
                       schema: { "type" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select" })
      end

      subject(:params) { described_class.new(jira_field, context_group:).custom_field_parameters }

      it "is not multi_value for a single-select field" do
        expect(params[:multi_value]).to be false
      end

      it "includes the option values as possible_values" do
        expect(params[:possible_values]).to eq(%w[Cat Dog])
      end
    end

    context "with a radiobuttons field" do
      let(:context_group) do
        {
          "projects" => ["DYX"],
          "issuetypes" => ["10100"],
          "allowedValues" => [
            { "id" => "10290", "value" => "Option A" },
            { "id" => "10291", "value" => "Option B" }
          ]
        }
      end
      let(:jira_field) do
        jira_field_for(name: "CF Radio",
                       schema: { "type" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons" })
      end

      subject(:params) { described_class.new(jira_field, context_group:).custom_field_parameters }

      it "is not multi_value (single-select)" do
        expect(params[:multi_value]).to be false
      end

      it "includes the radio options as possible_values" do
        expect(params[:possible_values]).to eq(%w[Option\ A Option\ B])
      end
    end

    context "with a multi-select list field" do
      let(:context_group) do
        {
          "projects" => ["DYX"],
          "issuetypes" => ["10100"],
          "allowedValues" => [
            { "id" => "10145", "value" => "Mouse" },
            { "id" => "10146", "value" => "Turtle" }
          ]
        }
      end
      let(:jira_field) do
        jira_field_for(name: "CF Multi-List",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect" })
      end

      subject(:params) { described_class.new(jira_field, context_group:).custom_field_parameters }

      it { expect(params[:multi_value]).to be true }
      it { expect(params[:possible_values]).to eq(%w[Mouse Turtle]) }
    end

    context "with a single-user field" do
      let(:jira_field) do
        jira_field_for(name: "CF User",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:userpicker" })
      end

      it "is not multi_value" do
        params = described_class.new(jira_field).custom_field_parameters
        expect(params[:multi_value]).to be false
      end
    end

    context "with a multi-user field" do
      let(:jira_field) do
        jira_field_for(name: "CF Users",
                       schema: { "type" => "array",
                                 "items" => "user",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiuserpicker" })
      end

      it "is multi_value" do
        params = described_class.new(jira_field).custom_field_parameters
        expect(params[:multi_value]).to be true
      end
    end

    context "with a multicheckboxes bool field" do
      let(:jira_field) do
        jira_field_for(name: "CF Booleans",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes" })
      end

      it "returns an empty hash (bool CFs need no extra params)" do
        params = described_class.new(jira_field, option_value: "Check 1").custom_field_parameters
        expect(params).to eq({})
      end
    end

    context "with a cascading select field without enterprise (list fallback)" do
      let(:context_group) do
        {
          "projects" => [],
          "issuetypes" => [],
          "allowedValues" => [
            { "id" => "10150", "value" => "Critical",
              "children" => [{ "id" => "10151", "value" => "Security" },
                             { "id" => "10152", "value" => "Performance" }] },
            { "id" => "10153", "value" => "Major",
              "children" => [{ "id" => "10154", "value" => "Data Loss" }] }
          ]
        }
      end
      let(:jira_field) do
        jira_field_for(name: "CF Cascading",
                       schema: { "type" => "option-with-child",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect" })
      end

      subject(:params) { described_class.new(jira_field, context_group:).custom_field_parameters }

      it "is multi_value" do
        expect(params[:multi_value]).to be true
      end

      it "flattens all tree nodes as path-based possible_values" do
        expect(params[:possible_values]).to contain_exactly(
          "Critical",
          "Critical / Security",
          "Critical / Performance",
          "Major",
          "Major / Data Loss"
        )
      end
    end

    context "with a scalar field (string, float, date, link)" do
      let(:jira_field) do
        jira_field_for(name: "CF Number",
                       schema: { "type" => "number",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:float" })
      end

      it "returns an empty hash" do
        expect(described_class.new(jira_field).custom_field_parameters).to eq({})
      end
    end
  end

  describe "#convert_value" do
    context "with a text (textarea) field" do
      let(:jira_field) do
        jira_field_for(name: "CF text",
                       schema: { "type" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textarea" })
      end
      let(:builder) { described_class.new(jira_field) }

      it "converts Jira wiki markup to OP markdown" do
        result = builder.convert_value("This is *bold* text.", custom_field)
        expect(result).to eq("This is **bold** text.")
      end

      it "handles nil-like values by converting to empty string" do
        result = builder.convert_value(nil, custom_field)
        expect(result).to eq("")
      end
    end

    context "with a single-select list field" do
      let(:jira_field) do
        jira_field_for(name: "CF List",
                       schema: { "type" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select" })
      end
      let(:builder) { described_class.new(jira_field) }
      let(:cat_option) { instance_double(CustomOption, id: 1) }

      before do
        allow(custom_field).to receive(:value_of).with("Cat").and_return(cat_option)
      end

      it "looks up the option by value and returns it" do
        result = builder.convert_value({ "id" => "10141", "value" => "Cat" }, custom_field)
        expect(result).to eq(cat_option)
      end

      it "returns nil when the option value is not found in the custom field" do
        allow(custom_field).to receive(:value_of).with("Unknown").and_return(nil)
        result = builder.convert_value({ "value" => "Unknown" }, custom_field)
        expect(result).to be_nil
      end
    end

    context "with a multi-select list field (option items)" do
      let(:jira_field) do
        jira_field_for(name: "CF Multi-List",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect" })
      end
      let(:builder) { described_class.new(jira_field) }
      let(:mouse_option) { instance_double(CustomOption, id: 2) }
      let(:turtle_option) { instance_double(CustomOption, id: 3) }

      before do
        allow(custom_field).to receive(:value_of).with("Mouse").and_return(mouse_option)
        allow(custom_field).to receive(:value_of).with("Turtle").and_return(turtle_option)
      end

      it "looks up each option and returns an array" do
        raw = [{ "id" => "10145", "value" => "Mouse" }, { "id" => "10146", "value" => "Turtle" }]
        result = builder.convert_value(raw, custom_field)
        expect(result).to eq([mouse_option, turtle_option])
      end

      it "filters out nil when an option value is not found" do
        allow(custom_field).to receive(:value_of).with("Gone").and_return(nil)
        raw = [{ "value" => "Mouse" }, { "value" => "Gone" }]
        result = builder.convert_value(raw, custom_field)
        expect(result).to eq([mouse_option])
      end
    end

    context "with a string-array list field (e.g. labels)" do
      let(:jira_field) do
        jira_field_for(name: "CF Labels",
                       schema: { "type" => "array",
                                 "items" => "string",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:labels" })
      end
      let(:builder) { described_class.new(jira_field) }
      let(:label_a_option) { instance_double(CustomOption, id: 10) }
      let(:label_b_option) { instance_double(CustomOption, id: 11) }

      before do
        allow(custom_field).to receive(:value_of).with("Label A").and_return(label_a_option)
        allow(custom_field).to receive(:value_of).with("Label B").and_return(label_b_option)
      end

      it "looks up each plain string as a list option" do
        raw = ["Label A", "Label B"]
        result = builder.convert_value(raw, custom_field)
        expect(result).to eq([label_a_option, label_b_option])
      end

      it "filters out plain strings not present as options" do
        allow(custom_field).to receive(:value_of).with("Gone").and_return(nil)
        raw = ["Label A", "Gone"]
        result = builder.convert_value(raw, custom_field)
        expect(result).to eq([label_a_option])
      end
    end

    context "with a multicheckboxes field converted to bool (single option, option_value set)" do
      let(:jira_field) do
        jira_field_for(name: "CF Booleans",
                       schema: { "type" => "array",
                                 "items" => "option",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes" })
      end

      context "for builder 'Check 1'" do
        let(:builder) { described_class.new(jira_field, option_value: "Check 1") }

        it "returns true when 'Check 1' is in the selected array" do
          raw = [{ "value" => "Check 1" }, { "value" => "Check 2" }]
          expect(builder.convert_value(raw, custom_field)).to be true
        end

        it "returns false when 'Check 1' is not in the selected array" do
          raw = [{ "value" => "Check 2" }]
          expect(builder.convert_value(raw, custom_field)).to be false
        end

        it "returns false for an empty selection" do
          expect(builder.convert_value([], custom_field)).to be false
        end

        it "returns false for a non-array value" do
          expect(builder.convert_value("unexpected", custom_field)).to be false
        end
      end

      context "for builder 'Check 2'" do
        let(:builder) { described_class.new(jira_field, option_value: "Check 2") }

        it "returns true only for its own option" do
          raw = [{ "value" => "Check 2" }]
          expect(builder.convert_value(raw, custom_field)).to be true
        end

        it "returns false when only the other option is selected" do
          raw = [{ "value" => "Check 1" }]
          expect(builder.convert_value(raw, custom_field)).to be false
        end
      end
    end

    context "with a single-user field (userpicker)" do
      let(:jira_field) do
        jira_field_for(name: "CF User",
                       schema: { "type" => "user",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:userpicker" })
      end
      let(:op_user) { instance_double(User, id: 99) }
      let(:builder) { described_class.new(jira_field) }

      before { allow(builder).to receive(:find_field_user).with("JIRAUSER10000").and_return(op_user) }

      it "looks up the OP user by the Jira user key" do
        raw = { "key" => "JIRAUSER10000", "name" => "e.xample" }
        expect(builder.convert_value(raw, custom_field)).to eq(op_user)
      end

      it "returns nil when the user key is not found" do
        allow(builder).to receive(:find_field_user).with("UNKNOWN").and_return(nil)
        raw = { "key" => "UNKNOWN", "name" => "gone" }
        expect(builder.convert_value(raw, custom_field)).to be_nil
      end
    end

    context "with a multi-user field (multiuserpicker)" do
      let(:jira_field) do
        jira_field_for(name: "CF Users",
                       schema: { "type" => "array", "items" => "user",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiuserpicker" })
      end
      let(:user_a) { instance_double(User, id: 10) }
      let(:user_b) { instance_double(User, id: 11) }
      let(:builder) { described_class.new(jira_field) }

      before do
        allow(builder).to receive(:find_field_user).with("JIRA_A").and_return(user_a)
        allow(builder).to receive(:find_field_user).with("JIRA_B").and_return(user_b)
        allow(builder).to receive(:find_field_user).with("JIRA_GONE").and_return(nil)
      end

      it "maps each user object to the corresponding OP user" do
        raw = [{ "key" => "JIRA_A" }, { "key" => "JIRA_B" }]
        expect(builder.convert_value(raw, custom_field)).to eq([user_a, user_b])
      end

      it "filters out unmapped users" do
        raw = [{ "key" => "JIRA_A" }, { "key" => "JIRA_GONE" }]
        expect(builder.convert_value(raw, custom_field)).to eq([user_a])
      end
    end

    context "with a cascading select field (hierarchy)", with_ee: [:custom_field_hierarchies] do
      let(:jira_field) do
        jira_field_for(name: "CF Cascading",
                       schema: { "type" => "option-with-child",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect" },
                       context_groups: [
                         {
                           "projects" => [],
                           "issuetypes" => [],
                           "allowedValues" => [
                             { "value" => "Critical", "children" => [{ "value" => "Security" }, { "value" => "Performance" }] },
                             { "value" => "Major", "children" => [{ "value" => "Data Loss" }] }
                           ]
                         }
                       ])
      end
      let(:context_group) { jira_field.payload["contextGroups"].first }
      let(:builder) { described_class.new(jira_field, context_group:) }
      let(:hierarchy_cf) { create(:custom_field, :hierarchy, field_format: "hierarchy") }

      before do
        root = hierarchy_cf.hierarchy_root
        service = CustomFields::Hierarchy::HierarchicalItemService.new
        contract = CustomFields::Hierarchy::InsertListItemContract
        critical = service.insert_item(contract_class: contract, parent: root, label: "Critical").value!
        service.insert_item(contract_class: contract, parent: critical, label: "Security")
        service.insert_item(contract_class: contract, parent: critical, label: "Performance")
        major = service.insert_item(contract_class: contract, parent: root, label: "Major").value!
        service.insert_item(contract_class: contract, parent: major, label: "Data Loss")
      end

      it "returns the child item ID when parent + child are selected" do
        raw = { "id" => "10150", "value" => "Critical", "child" => { "id" => "10151", "value" => "Security" } }
        result = builder.convert_value(raw, hierarchy_cf)
        child = hierarchy_cf.hierarchy_root.children.find_by(label: "Critical").children.find_by(label: "Security")
        expect(result).to eq(child.id)
      end

      it "returns the parent item ID when only parent is selected (no child)" do
        raw = { "id" => "10153", "value" => "Major" }
        result = builder.convert_value(raw, hierarchy_cf)
        parent = hierarchy_cf.hierarchy_root.children.find_by(label: "Major")
        expect(result).to eq(parent.id)
      end

      it "returns nil when the parent label is not found" do
        raw = { "id" => "99", "value" => "Unknown" }
        expect(builder.convert_value(raw, hierarchy_cf)).to be_nil
      end

      it "falls back to parent when child label is not found" do
        raw = { "value" => "Critical", "child" => { "value" => "Gone" } }
        result = builder.convert_value(raw, hierarchy_cf)
        parent = hierarchy_cf.hierarchy_root.children.find_by(label: "Critical")
        expect(result).to eq(parent.id)
      end

      it "returns nil for non-hash values" do
        expect(builder.convert_value("unexpected", hierarchy_cf)).to be_nil
      end
    end

    context "with scalar passthrough fields (string, float, date, link)" do
      {
        "string" => ["CF String",
                     { "type" => "string",
                       "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield" },
                     "my plain text"],
        "float" => ["CF Number",
                    { "type" => "number",
                      "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:float" },
                    42.5],
        "date" => ["CF Date",
                   { "type" => "date",
                     "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datepicker" },
                   "2024-01-15"],
        "link" => ["CF URL",
                   { "type" => "string",
                     "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:url" },
                   "https://openproject.org"]
      }.each do |expected_format, (name, schema, raw_value)|
        context "with format '#{expected_format}'" do
          let(:jira_field) { jira_field_for(name:, schema:) }
          let(:builder) { described_class.new(jira_field) }

          it "returns the raw Jira value unchanged" do
            expect(builder.convert_value(raw_value, custom_field)).to eq(raw_value)
          end
        end
      end
    end

    context "with a cascading select falling back to list (no enterprise)" do
      let(:jira_field) do
        jira_field_for(name: "CF Cascading",
                       schema: { "type" => "option-with-child",
                                 "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect" })
      end
      let(:builder) { described_class.new(jira_field) }
      let(:critical_option)          { instance_double(CustomOption, id: 1) }
      let(:critical_security_option) { instance_double(CustomOption, id: 2) }
      let(:major_option)             { instance_double(CustomOption, id: 3) }

      before do
        allow(custom_field).to receive(:value_of).with("Critical").and_return(critical_option)
        allow(custom_field).to receive(:value_of).with("Critical / Security").and_return(critical_security_option)
        allow(custom_field).to receive(:value_of).with("Major").and_return(major_option)
      end

      it "extracts the parent + child chain as path-based list values" do
        raw = { "id" => "10150", "value" => "Critical", "child" => { "id" => "10151", "value" => "Security" } }
        expect(builder.convert_value(raw, custom_field)).to eq([critical_option, critical_security_option])
      end

      it "extracts a parent-only selection as a single-element array" do
        raw = { "id" => "10153", "value" => "Major" }
        expect(builder.convert_value(raw, custom_field)).to eq([major_option])
      end
    end
  end

  describe "#custom_field_post_processing", with_ee: [:custom_field_hierarchies] do
    let(:context_group) do
      {
        "projects" => [],
        "issuetypes" => [],
        "allowedValues" => [
          { "value" => "Critical", "children" => [{ "value" => "Security" }, { "value" => "Performance" }] },
          { "value" => "Major", "children" => [{ "value" => "Data Loss" }] },
          { "value" => "Minor" }
        ]
      }
    end
    let(:jira_field) do
      jira_field_for(name: "CF Cascading",
                     schema: { "type" => "option-with-child",
                               "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect" },
                     context_groups: [context_group])
    end
    let(:builder) { described_class.new(jira_field, context_group:) }
    let!(:hierarchy_cf) do
      create(:custom_field, field_format: "hierarchy", hierarchy_root: nil).tap do |cf|
        CustomFields::Hierarchy::HierarchicalItemService.new.generate_root(cf)
        cf.reload
      end
    end

    before { builder.custom_field_post_processing(hierarchy_cf) }

    it "creates parent items under the hierarchy root" do
      root = hierarchy_cf.hierarchy_root
      expect(root.children.pluck(:label)).to contain_exactly("Critical", "Major", "Minor")
    end

    it "creates child items under their parent" do
      critical = hierarchy_cf.hierarchy_root.children.find_by(label: "Critical")
      expect(critical.children.pluck(:label)).to contain_exactly("Security", "Performance")
    end

    it "creates child items for all parents with children" do
      major = hierarchy_cf.hierarchy_root.children.find_by(label: "Major")
      expect(major.children.pluck(:label)).to contain_exactly("Data Loss")
    end

    it "handles parents without children" do
      minor = hierarchy_cf.hierarchy_root.children.find_by(label: "Minor")
      expect(minor.children).to be_empty
    end
  end

  describe "#find_existing_custom_field" do
    let(:jira) { create(:jira) }
    let(:jira_import) { create(:jira_import, jira:, author: create(:user)) }

    def list_builder(name: "Severity", values: %w[Low High], projects: [], needs_disambiguation: false,
                     multi_value: false)
      schema = if multi_value
                 { "type" => "array", "items" => "option",
                   "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect" }
               else
                 { "type" => "option", "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select" }
               end
      context_group = { "projects" => projects, "issuetypes" => [],
                        "allowedValues" => values.map { |value| { "value" => value } } }
      described_class.new(jira_field_for(name:, schema:, context_groups: [context_group]),
                          context_group:, needs_disambiguation:, jira_import:)
    end

    def import_owned(custom_field)
      create(:jira_open_project_reference,
             jira:,
             jira_import:,
             op_entity_id: custom_field.id,
             op_entity_class: "WorkPackageCustomField",
             jira_entity_class: "Import::JiraField")
      custom_field
    end

    def with_mode(mode)
      stub_const("#{described_class}::VALUE_MATCH_MODE", mode)
    end

    context "with a list field" do
      it "reuses a custom field left behind by an earlier run" do
        existing = create(:list_wp_custom_field, name: "Severity", possible_values: %w[Low High])

        expect(list_builder.find_existing_custom_field).to eq(existing)
      end

      it "looks past a dedup-counter suffix on the existing name" do
        existing = create(:list_wp_custom_field, name: "Severity (2)", possible_values: %w[Low High])

        expect(list_builder.find_existing_custom_field).to eq(existing)
      end

      it "looks past a project-key disambiguation suffix on either side" do
        existing = create(:list_wp_custom_field, name: "Severity (DYX)", possible_values: %w[Low High])
        builder = list_builder(projects: %w[ABC], needs_disambiguation: true)

        expect(builder.find_existing_custom_field).to eq(existing)
      end

      it "does not reuse the only candidate when its values are incompatible" do
        create(:list_wp_custom_field, name: "Severity", possible_values: %w[Blocker])

        expect(list_builder.find_existing_custom_field).to be_nil
      end

      it "creates a free name for itself when it does not reuse a candidate" do
        create(:list_wp_custom_field, name: "Severity", possible_values: %w[Red Green])
        builder = list_builder

        expect(builder.find_existing_custom_field).to be_nil
        expect(builder.custom_field_settings.first).to eq("Severity (2)")
      end

      it "does not reuse a candidate of another format" do
        create(:string_wp_custom_field, name: "Severity")

        expect(list_builder.find_existing_custom_field).to be_nil
      end

      it "does not reuse a candidate whose multi_value differs" do
        create(:list_wp_custom_field, name: "Severity", possible_values: %w[Low High], multi_value: true)

        expect(list_builder(multi_value: false).find_existing_custom_field).to be_nil
      end

      it "picks the split that covers the needed values" do
        create(:list_wp_custom_field, name: "Severity", possible_values: %w[Red Green])
        matching = create(:list_wp_custom_field, name: "Severity (DYX)", possible_values: %w[Low High Critical])

        expect(list_builder.find_existing_custom_field).to eq(matching)
      end

      it "never matches when the context declares no values at all" do
        create(:list_wp_custom_field, name: "Severity", possible_values: %w[Low High])

        expect(list_builder(values: []).find_existing_custom_field).to be_nil
      end

      it "creates a new field when no candidate shares a value, under every mode" do
        create(:list_wp_custom_field, name: "Severity", possible_values: %w[Red Green])

        %i[subset exact extend].each do |mode|
          with_mode(mode)
          expect(list_builder.find_existing_custom_field).to be_nil
        end
      end
    end

    context "when the needed values are a subset of an existing field's" do
      let!(:existing) { create(:list_wp_custom_field, name: "Severity", possible_values: %w[Low High Critical]) }
      let(:builder) { list_builder(values: %w[Low High]) }

      it "reuses it under :subset" do
        with_mode(:subset)

        expect(builder.find_existing_custom_field).to eq(existing)
      end

      it "reuses it untouched under :extend" do
        with_mode(:extend)

        expect(builder.find_existing_custom_field).to eq(existing)
        builder.apply_pending_value_extension(existing, user: User.system)
        expect(existing.reload.custom_options.pluck(:value)).to eq(%w[Low High Critical])
      end

      it "creates a new field under :exact" do
        with_mode(:exact)

        expect(builder.find_existing_custom_field).to be_nil
      end
    end

    context "when the needed values only partially overlap an existing field's" do
      let!(:existing) { create(:list_wp_custom_field, name: "Severity", possible_values: %w[Low High]) }
      let(:builder) { list_builder(values: %w[High Critical]) }

      it "creates a new field under :subset" do
        with_mode(:subset)

        expect(builder.find_existing_custom_field).to be_nil
      end

      it "creates a new field under :exact" do
        with_mode(:exact)

        expect(builder.find_existing_custom_field).to be_nil
      end

      it "leaves a custom field this import does not own alone under :extend" do
        with_mode(:extend)

        expect(builder.find_existing_custom_field).to be_nil
      end

      context "with :extend, on a field this import owns" do
        before do
          with_mode(:extend)
          import_owned(existing)
        end

        it "reuses the best overlapping candidate" do
          expect(builder.find_existing_custom_field).to eq(existing)
        end

        it "appends only the missing labels and keeps the existing options" do
          option_ids = existing.custom_options.pluck(:id)
          builder.find_existing_custom_field
          builder.apply_pending_value_extension(existing, user: User.system)

          expect(existing.reload.custom_options.pluck(:value)).to eq(%w[Low High Critical])
          expect(existing.custom_options.pluck(:id).first(2)).to eq(option_ids)
        end
      end
    end

    context "with two context groups of the same run" do
      let!(:sibling) { create(:list_wp_custom_field, name: "Severity (DYX)", possible_values: %w[Low High]) }

      it "shares one custom field when their option sets are identical" do
        builder = list_builder(values: %w[Low High], projects: %w[ABC], needs_disambiguation: true)

        expect(builder.find_existing_custom_field(run_custom_field_ids: [sibling.id])).to eq(sibling)
      end

      it "keeps the split when the second group only needs a subset" do
        builder = list_builder(values: %w[Low], projects: %w[ABC], needs_disambiguation: true)

        expect(builder.find_existing_custom_field(run_custom_field_ids: [sibling.id])).to be_nil
      end

      it "keeps the split under :extend as well" do
        with_mode(:extend)
        import_owned(sibling)
        builder = list_builder(values: %w[Low Critical], projects: %w[ABC], needs_disambiguation: true)

        expect(builder.find_existing_custom_field(run_custom_field_ids: [sibling.id])).to be_nil
      end
    end

    context "with a non-value-bearing format" do
      def date_builder
        schema = { "type" => "date", "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datepicker" }
        described_class.new(jira_field_for(name: "Due", schema:), jira_import:)
      end

      it "prefers the exact base name over an older suffixed candidate" do
        create(:date_wp_custom_field, name: "Due (archived)")
        exact = create(:date_wp_custom_field, name: "Due")

        expect(date_builder.find_existing_custom_field).to eq(exact)
      end

      it "does not reuse a suffixed candidate when no exact name matches" do
        create(:date_wp_custom_field, name: "Due (archived)")
        create(:date_wp_custom_field, name: "Due (2)")

        expect(date_builder.find_existing_custom_field).to be_nil
      end

      it "keeps two Jira fields apart when one is named like the other's dedup suffix" do
        suffixed = create(:string_wp_custom_field, name: "foo (2)")
        schema = { "type" => "string", "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield" }
        builder = described_class.new(jira_field_for(name: "foo", schema:), jira_import:)

        expect(builder.find_existing_custom_field).to be_nil
        expect(builder.custom_field_settings.first).to eq("foo")
        expect(suffixed.reload.name).to eq("foo (2)")
      end
    end

    context "with a hierarchy field", with_ee: [:custom_field_hierarchies] do
      def hierarchy_builder(allowed_values)
        schema = { "type" => "option-with-child",
                   "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect" }
        context_group = { "projects" => [], "issuetypes" => [], "allowedValues" => allowed_values }
        described_class.new(jira_field_for(name: "Impact", schema:, context_groups: [context_group]),
                            context_group:, jira_import:)
      end

      def hierarchy_cf_with(allowed_values)
        custom_field = create(:hierarchy_wp_custom_field, name: "Impact")
        hierarchy_builder(allowed_values).custom_field_post_processing(custom_field)
        custom_field.reload
      end

      it "reuses a field that already carries the needed paths" do
        existing = hierarchy_cf_with([{ "value" => "Critical", "children" => [{ "value" => "Security" }] },
                                      { "value" => "Minor" }])

        expect(hierarchy_builder([{ "value" => "Minor" }]).find_existing_custom_field).to eq(existing)
      end

      it "does not reuse a field missing one of the needed paths" do
        hierarchy_cf_with([{ "value" => "Critical" }])

        expect(hierarchy_builder([{ "value" => "Minor" }]).find_existing_custom_field).to be_nil
      end

      it "walks into existing branches and adds only the missing nodes under :extend" do
        with_mode(:extend)
        existing = import_owned(hierarchy_cf_with([{ "value" => "Critical", "children" => [{ "value" => "Security" }] }]))
        builder = hierarchy_builder(
          [{ "value" => "Critical", "children" => [{ "value" => "Security" }, { "value" => "Performance" }] }]
        )

        expect(builder.find_existing_custom_field).to eq(existing)
        builder.apply_pending_value_extension(existing, user: User.system)

        root = existing.reload.hierarchy_root
        expect(root.children.pluck(:label)).to contain_exactly("Critical")
        expect(root.children.find_by(label: "Critical").children.pluck(:label))
          .to contain_exactly("Security", "Performance")
      end
    end
  end
end
