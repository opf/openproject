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

RSpec.describe WorkPackageTypes::AttributeGroups::Transformer do
  subject(:transformer) { described_class.new(groups: raw_groups, user: user) }

  let(:user) { build(:admin) }

  describe "#call" do
    context "when groups are empty" do
      let(:raw_groups) { [] }

      it "returns an empty array" do
        result = transformer.call

        expect(result).to be_success
        expect(result.result).to eq([])
      end
    end

    context "when given a regular attribute group with key" do
      let(:raw_groups) do
        [
          {
            name: "Custom",
            key: "custom",
            type: "attribute",
            attributes: [
              { key: "custom_field_1" },
              { key: "custom_field_2" }
            ]
          }
        ]
      end

      it "returns transformed group with symbolized key and attribute keys" do
        result = transformer.call

        expect(result).to be_success
        expect(result.result).to eq([[:custom, ["custom_field_1", "custom_field_2"], "Custom"]])
      end
    end

    context "when group has no key" do
      let(:raw_groups) do
        [
          {
            name: "General Info",
            type: "attribute",
            attributes: [{ key: "subject" }]
          }
        ]
      end

      it "uses name as group name" do
        result = transformer.call

        expect(result).to be_success
        expect(result.result).to eq([["General Info", ["subject"]]])
      end
    end

    context "when given a query group with valid JSON" do
      let(:raw_groups) do
        [
          {
            name: "Embedded Table",
            type: "query",
            attributes: nil,
            query: {
              "columns[]" => %w[id subject],
              "filters" => "[]",
              "sortBy" => JSON.dump(["id:asc"]),
              "groupBy" => ""
            }.to_json
          }
        ]
      end

      it "returns a group with a Query instance" do
        result = transformer.call
        name, entries = result.result.first

        expect(result).to be_success
        expect(name).to eq("Embedded Table")
        expect(entries.first).to be_a(Query)
        expect(entries.first.name).to eq("Embedded table: Embedded Table")
      end
    end

    context "when given a query group with invalid JSON" do
      let(:raw_groups) do
        [
          {
            name: "Broken",
            type: "query",
            query: "not a json"
          }
        ]
      end

      it "returns a failure result" do
        result = transformer.call

        expect(result).to be_failure
        expect(result.errors.full_messages.to_sentence)
          .to eq(I18n.t("types.edit.form_configuration.invalid_query"))
      end
    end
  end
end
