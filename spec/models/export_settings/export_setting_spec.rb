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

RSpec.shared_examples "a successful creation" do |format|
  it "creates successfully with format #{format}" do
    expect(described_class.create(query:, settings:, format:)).to be_persisted
  end
end

RSpec.describe ExportSetting do
  let(:query) { create(:query, name: "some query") }
  let(:format) { "csv" }
  let(:settings) { { "columns" => %w[id subject], "show_descriptions" => "true" } }

  it "returns its settings with symbol keys" do
    export_settings = described_class.create(query:, settings:, format:)

    expect(export_settings.settings).to eq({ columns: %w[id subject], show_descriptions: "true" })

    export_settings.settings = { "foo" => "bar" }
    expect(export_settings.settings).to eq({ foo: "bar" })
  end

  describe "creating" do
    formats = %w[csv xls pdf_report pdf_table pdf_gantt]

    formats.each do |format|
      include_examples "a successful creation", format
    end

    it "fails with an invalid format" do
      expect(described_class.create(query:, settings:, format: "invalid_format")).not_to be_persisted
    end

    it "fails without format" do
      expect(described_class.create(query:, settings:)).not_to be_persisted
    end

    it "fails without settings" do
      expect(described_class.create(query:, format:)).not_to be_persisted
    end

    it "fails without query" do
      expect(described_class.create(settings:, format:)).not_to be_persisted
    end

    it "fails when there already is this query/format combination" do
      expect(described_class.create(query:, settings:, format: "csv")).to be_persisted

      duplicate = described_class.create(query:, settings:, format: "csv")
      expect(duplicate).not_to be_persisted
      expect(duplicate.errors[:format]).to include("there already is an export setting for this query with this format")

      new_query = create(:query, name: "another query")
      expect(described_class.create(query: new_query, settings:, format: "csv")).to be_persisted
    end
  end

  describe "#true?" do
    let(:settings) do
      {
        string_true: "true",
        real_true: true,
        string_one_true: "1",
        one_true: 1,
        string_false: "false",
        real_false: false,
        string_zero_false: "0",
        zero_false: 0,
        truthy_string: "any string is truthy",
        truthy_array: []
      }
    end
    let(:instance) { described_class.new(query:, settings:, format:) }

    it "returns true for a value that looks like it should be true" do
      true_keys = %i[
        string_true
        real_true
        string_one_true
        one_true
      ]

      true_keys.each do |key|
        expect(instance.true?(key)).to be true
      end
    end

    it "returns false for a value that looks like it should be false" do
      false_keys = %i[
        string_false
        real_false
        string_zero_false
        zero_false
      ]

      false_keys.each do |key|
        expect(instance.true?(key)).to be false
      end
    end

    it "returns false for values that are truthy in Ruby" do
      truthy_keys = %i[truthy_string truthy_array]

      truthy_keys.each do |key|
        expect(instance.true?(key)).to be false
      end
    end

    it "returns false for keys that do not exist" do
      expect(instance.true?(:non_existent_key)).to be false
    end

    it "returns a default value for non existent keys" do
      expect(instance.true?(:non_existent_key, default: true)).to be true
    end
  end
end
