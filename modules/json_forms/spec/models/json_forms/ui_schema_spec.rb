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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe JsonForms::UiSchema do
  let(:notify_condition) { { "scope" => "#/properties/notify", "schema" => { "const" => true } } }

  describe ".generate" do
    it "lists the properties of an object vertically" do
      schema = { "type" => "object", "properties" => { "a" => {}, "b" => {} } }

      expect(described_class.generate(schema)).to eq(
        "type" => "VerticalLayout",
        "elements" => [{ "type" => "Control", "scope" => "#/properties/a" },
                       { "type" => "Control", "scope" => "#/properties/b" }]
      )
    end

    it "renders a primitive as an unlabeled control of itself" do
      expect(described_class.generate({ "type" => "string" })).to eq("type" => "Control", "scope" => "#", "label" => false)
    end
  end

  describe ".scope_keys" do
    it "extracts the property path" do
      expect(described_class.scope_keys("#/properties/contact/properties/zip")).to eq(%w[contact zip])
      expect(described_class.scope_keys("#")).to eq([])
    end
  end

  describe "rules" do
    it "shows, hides, enables and disables depending on the condition" do
      on = { "notify" => true }
      off = { "notify" => false }

      expect(described_class.visible?({ "rule" => { "effect" => "SHOW", "condition" => notify_condition } }, on)).to be(true)
      expect(described_class.visible?({ "rule" => { "effect" => "SHOW", "condition" => notify_condition } }, off)).to be(false)
      expect(described_class.visible?({ "rule" => { "effect" => "HIDE", "condition" => notify_condition } }, on)).to be(false)
      expect(described_class.enabled?({ "rule" => { "effect" => "ENABLE", "condition" => notify_condition } }, off)).to be(false)
      expect(described_class.enabled?({ "rule" => { "effect" => "DISABLE", "condition" => notify_condition } }, off)).to be(true)
      expect(described_class.visible?({}, off)).to be(true)
    end

    it "treats a missing value as not matching" do
      expect(described_class.condition_matches?(notify_condition, {})).to be(false)
    end

    it "combines conditions with AND and OR" do
      other = { "scope" => "#/properties/level", "schema" => { "minimum" => 2 } }
      data = { "notify" => true, "level" => 1 }

      expect(described_class.condition_matches?({ "type" => "AND", "conditions" => [notify_condition, other] },
                                                data)).to be(false)
      expect(described_class.condition_matches?({ "type" => "OR", "conditions" => [notify_condition, other] }, data)).to be(true)
    end
  end

  describe ".rule_scopes" do
    it "collects the scopes of all rule conditions, including nested details" do
      ui_schema = {
        "type" => "VerticalLayout",
        "elements" => [
          { "type" => "Control", "scope" => "#/properties/text",
            "rule" => { "effect" => "SHOW", "condition" => notify_condition } },
          { "type" => "Control", "scope" => "#/properties/tasks",
            "options" => { "detail" => { "type" => "Control", "scope" => "#/properties/hours",
                                         "rule" => { "effect" => "HIDE", "condition" => { "scope" => "#/properties/done" } } } } }
        ]
      }

      expect(described_class.rule_scopes(ui_schema)).to eq([["notify"], ["done"]])
    end
  end

  describe ".additional_properties_schema" do
    it "returns the value schema of explicitly allowed additional properties" do
      expect(described_class.additional_properties_schema({ "additionalProperties" => { "type" => "integer" } }))
        .to eq("type" => "integer")
      expect(described_class.additional_properties_schema({ "additionalProperties" => true })).to eq("type" => "string")
      expect(described_class.additional_properties_schema({ "additionalProperties" => false })).to be_nil
      expect(described_class.additional_properties_schema({})).to be_nil
    end
  end

  describe ".schema_for_data_path" do
    it "follows properties, array items and additional properties" do
      schema = { "type" => "object", "properties" => {
        "tasks" => { "type" => "array", "items" => { "type" => "object",
                                                     "additionalProperties" => { "type" => "number" } } }
      } }

      expect(described_class.schema_for_data_path(schema, %w[tasks 0 hours])).to eq("type" => "number")
      expect(described_class.schema_for_data_path(schema, %w[unknown])).to be_nil
    end
  end
end
