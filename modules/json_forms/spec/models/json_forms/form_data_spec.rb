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

RSpec.describe JsonForms::FormData do
  let(:schema) do
    {
      "type" => "object",
      "properties" => {
        "summary" => { "type" => "string" },
        "count" => { "type" => "integer", "default" => 3 },
        "ratio" => { "type" => "number" },
        "dry_run" => { "type" => "boolean", "default" => true },
        "channels" => { "type" => "array", "items" => { "type" => "string", "enum" => %w[email chat] } },
        "contact" => {
          "type" => "object",
          "properties" => {
            "name" => { "type" => "string", "default" => "Ada" },
            "address" => { "type" => "object", "properties" => { "zip" => { "type" => "string" } } }
          }
        },
        "tasks" => {
          "type" => "array",
          "items" => { "type" => "object",
                       "properties" => { "title" => { "type" => "string" }, "hours" => { "type" => "number" } } }
        },
        "tags" => { "type" => "array", "items" => { "type" => "string" } }
      }
    }
  end

  describe ".coerce" do
    it "converts form parameters into typed, nested JSON" do
      raw = {
        "summary" => "Deploy", "count" => "4", "ratio" => "2.5", "dry_run" => "0",
        "channels" => ["", "chat"],
        "contact" => { "name" => "", "address" => { "zip" => "12345" } },
        "tasks" => { "1" => { "title" => "Second", "hours" => "" }, "0" => { "title" => "First", "hours" => "2" } },
        "tags" => { "0" => "" },
        "unknown" => "dropped"
      }

      expect(described_class.coerce(schema, raw)).to eq(
        "summary" => "Deploy", "count" => 4, "ratio" => 2.5, "dry_run" => false,
        "channels" => ["chat"],
        "contact" => { "address" => { "zip" => "12345" } },
        "tasks" => [{ "title" => "First", "hours" => 2 }, { "title" => "Second" }],
        "tags" => [""]
      )
    end

    it "keeps values that are not numbers, so validation can report them" do
      expect(described_class.coerce(schema, { "count" => "many" })).to eq("count" => "many")
    end
  end

  describe ".apply_defaults" do
    it "fills in defaults of present objects only" do
      expect(described_class.apply_defaults(schema, {})).to eq("count" => 3, "dry_run" => true)
      expect(described_class.apply_defaults(schema, { "contact" => {} })).to eq(
        "count" => 3, "dry_run" => true, "contact" => { "name" => "Ada" }
      )
    end
  end

  describe ".apply_operation" do
    let(:data) { { "tasks" => [{ "title" => "a" }, { "title" => "b" }] } }

    it "appends an empty row matching the item type" do
      expect(described_class.apply_operation(schema, data, "add:tasks")["tasks"]).to eq(
        [{ "title" => "a" }, { "title" => "b" }, {}]
      )
      expect(described_class.apply_operation(schema, {}, "add:tags")).to eq("tags" => [""])
    end

    it "removes the given row" do
      expect(described_class.apply_operation(schema, data, "remove:tasks.0")["tasks"]).to eq([{ "title" => "b" }])
    end

    it "ignores malformed operations and leaves the original data untouched" do
      expect(described_class.apply_operation(schema, data, "drop")).to eq(data)
      described_class.apply_operation(schema, data, "add:tasks")
      expect(data["tasks"].size).to eq(2)
    end
  end

  describe "additional properties" do
    let(:schema) do
      {
        "type" => "object",
        "properties" => {
          "labels" => { "type" => "object", "properties" => { "fixed" => { "type" => "string" } },
                        "additionalProperties" => { "type" => "integer" },
                        "propertyNames" => { "pattern" => "^[a-z]+$" } },
          "notes" => { "type" => "object", "additionalProperties" => true },
          "closed" => { "type" => "object", "properties" => { "a" => { "type" => "string" } },
                        "additionalProperties" => false }
        }
      }
    end

    it "keeps allowed extra keys, converted with their schema, also while empty" do
      raw = { "labels" => { "fixed" => "x", "size" => "3", "empty" => "" },
              "notes" => { "free" => "text" },
              "closed" => { "a" => "1", "b" => "2" } }

      expect(described_class.coerce(schema, raw)).to eq(
        "labels" => { "fixed" => "x", "size" => 3, "empty" => nil },
        "notes" => { "free" => "text" },
        "closed" => { "a" => "1" }
      )
    end

    it "adds a property with an empty value" do
      data = described_class.apply_operation(schema, { "labels" => {} }, "add_property:labels", property_name: " size ")
      expect(data).to eq("labels" => { "size" => nil })

      data = described_class.apply_operation(schema, {}, "add_property:notes", property_name: "free")
      expect(data).to eq("notes" => { "free" => "" })
    end

    it "removes a property" do
      data = described_class.apply_operation(schema, { "labels" => { "size" => 3, "w" => 1 } }, "remove:labels.size")
      expect(data).to eq("labels" => { "w" => 1 })
    end

    it "rejects unusable names" do
      data = { "labels" => { "size" => 3 } }
      {
        "" => "Enter a name for the new property.",
        "a.b" => "The name must not contain dots or square brackets.",
        "size" => "A property with this name already exists.",
        "fixed" => "A property with this name already exists.",
        "Upper" => "The name is not allowed by the schema."
      }.each do |name, message|
        expect { described_class.apply_operation(schema, data, "add_property:labels", property_name: name) }
          .to raise_error(described_class::InvalidPropertyName, message)
      end
    end

    it "ignores objects that do not allow additional properties" do
      expect(described_class.apply_operation(schema, {}, "add_property:closed", property_name: "b")).to eq({})
    end
  end
end
