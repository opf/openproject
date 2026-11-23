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

RSpec.describe JsonForms::Schema do
  subject(:form_schema) { described_class.new(schema) }

  let(:schema) do
    {
      "type" => "object",
      "required" => ["summary"],
      "properties" => {
        "summary" => { "type" => "string", "maxLength" => 5 },
        "count" => { "type" => "integer", "minimum" => 1 },
        "environment" => { "type" => "string", "enum" => %w[test production] },
        "contact" => {
          "type" => "object",
          "required" => ["name"],
          "properties" => { "name" => { "type" => "string" }, "zip" => { "type" => "string", "pattern" => "^[0-9]{5}$" } }
        },
        "tasks" => { "type" => "array", "maxItems" => 1, "items" => { "type" => "object" } }
      }
    }
  end

  describe "#errors" do
    it "accepts a valid object schema" do
      expect(form_schema.errors).to be_empty
    end

    it "rejects schemas that are not objects" do
      expect(described_class.new({ "type" => "array" }).errors)
        .to contain_exactly('The JSON Schema must describe an object, with "type": "object".')
    end

    it "rejects invalid JSON Schema" do
      expect(described_class.new({ "type" => "object", "properties" => [] }).errors)
        .to contain_exactly(start_with("The JSON Schema is not valid: "))
    end
  end

  describe "#validate" do
    it "returns translated messages keyed by the field path" do
      input = { "summary" => "Too long", "count" => 0, "environment" => "staging",
                "contact" => { "zip" => "1" }, "tasks" => [{}, {}] }

      expect(form_schema.validate(input)).to eq(
        "summary" => "The text must not be longer than 5 characters.",
        "count" => "The value must be 1 or more.",
        "environment" => "The value is not one of the allowed options.",
        "contact.name" => "This field is required.",
        "contact.zip" => "The value is not valid.",
        "tasks" => "The list must not have more than one entry."
      )
    end

    it "reports missing required fields and wrong types" do
      expect(form_schema.validate({ "count" => "many" })).to eq(
        "summary" => "This field is required.",
        "count" => "The value must be a whole number."
      )
    end

    it "returns nothing for valid input" do
      expect(form_schema.validate({ "summary" => "Ok" })).to eq({})
    end
  end
end
