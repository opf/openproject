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

RSpec.describe CustomFields::ConvertLegacyOptionIdsJob do
  let(:mapping) { create(:legacy_option_mapping) }
  let(:legacy_id) { mapping.custom_option_id.to_s }
  let(:item_id) { mapping.hierarchical_item_id.to_s }
  let(:other_list_field) { create(:list_wp_custom_field, possible_values: %w[Other]) }

  def store(record, column, raw)
    record.class.where(id: record.id).update_all(["#{column} = ?", raw])
  end

  def stored(record, column)
    record.class.connection.select_value(record.class.where(id: record.id).select(Arel.sql("#{column}::text")).to_sql)
  end

  def load_yaml(raw) = YAML.load(raw, permitted_classes: [Symbol, Date])

  context "with a work package query" do
    let(:query) { create(:query).reload }
    let(:filters) do
      {
        "cf_#{mapping.custom_field_id}" => { operator: "=", values: [legacy_id] },
        "cf_#{other_list_field.id}" => { operator: "=", values: [legacy_id] },
        "status_id" => { operator: "o", values: [] },
        "cf_0" => { operator: "=", values: [legacy_id] }
      }
    end

    before do
      store(query, :filters, YAML.dump(filters))
      described_class.perform_now
    end

    it "points the list filter at the item without marking the query as edited" do
      expect { query.reload }.not_to change(query, :updated_at)
      expect(load_yaml(stored(query, :filters))["cf_#{mapping.custom_field_id}"][:values]).to eq([item_id])
    end

    it "leaves the other filters as stored, including another field sharing the number" do
      expect(load_yaml(stored(query, :filters)).except("cf_#{mapping.custom_field_id}"))
        .to eq(filters.except("cf_#{mapping.custom_field_id}"))
    end
  end

  context "with a work package query already holding item ids" do
    let(:query) { create(:query) }
    let(:raw) { YAML.dump("cf_#{mapping.custom_field_id}" => { operator: "=", values: [item_id] }) }

    before { store(query, :filters, raw) }

    it "leaves it untouched" do
      described_class.perform_now

      expect(stored(query, :filters)).to eq(raw)
    end
  end

  context "with a work package query that cannot be loaded" do
    let(:broken_query) { create(:query) }
    let(:broken) { "cf_#{mapping.custom_field_id}: [unclosed" }
    let(:query) { create(:query) }

    before do
      store(broken_query, :filters, broken)
      store(query, :filters, YAML.dump("cf_#{mapping.custom_field_id}" => { operator: "=", values: [legacy_id] }))
      allow(OpenProject.logger).to receive(:error)

      described_class.perform_now
    end

    it "logs it, leaves it as stored and still converts the others" do
      expect(OpenProject.logger).to have_received(:error).with(/Query #{broken_query.id}:/)
      expect(stored(broken_query, :filters)).to eq(broken)
      expect(load_yaml(stored(query, :filters))["cf_#{mapping.custom_field_id}"][:values]).to eq([item_id])
    end
  end

  context "with a project query" do
    let(:mapping) { create(:legacy_option_mapping, custom_field: create(:list_project_custom_field, possible_values: %w[Kept])) }
    let(:query) { create(:project_query) }

    before do
      store(query, :filters, [{ "attribute" => "cf_#{mapping.custom_field_id}", "operator" => "=", "values" => [legacy_id] },
                              { "attribute" => "active", "operator" => "=", "values" => ["t"] }].to_json)
      described_class.perform_now
    end

    it "points the list filter at the item and keeps the others" do
      expect(JSON.parse(stored(query, :filters)))
        .to eq([{ "attribute" => "cf_#{mapping.custom_field_id}", "operator" => "=", "values" => [item_id] },
                { "attribute" => "active", "operator" => "=", "values" => ["t"] }])
    end
  end

  context "with a user query" do
    let(:mapping) { create(:legacy_option_mapping, custom_field: create(:user_custom_field, :list, possible_values: %w[Kept])) }
    let(:query) { create(:user_query) }

    before do
      store(query, :filters,
            [{ "attribute" => "cf_#{mapping.custom_field_id}", "operator" => "=", "values" => [legacy_id] }].to_json)
      described_class.perform_now
    end

    it "points the list filter at the item" do
      expect(JSON.parse(stored(query, :filters)).first["values"]).to eq([item_id])
    end
  end

  context "with a cost report query, which filters list fields by label" do
    let(:query) { create(:user_query).becomes!(CostReportQuery).tap(&:save!) }
    let(:raw) { [{ "attribute" => "cf_#{mapping.custom_field_id}", "operator" => "=", "values" => [legacy_id] }].to_json }

    before { store(query, :filters, raw) }

    it "leaves it untouched" do
      described_class.perform_now

      expect(JSON.parse(stored(query, :filters))).to eq(JSON.parse(raw))
    end
  end

  context "with a custom action" do
    let(:custom_action) { create(:custom_action) }
    let(:other_item_id) { other_list_field.possible_values.first.id.to_s }

    before do
      store(custom_action, :actions, YAML.dump([[:"custom_field_#{mapping.custom_field_id}", [legacy_id]],
                                                [:"custom_field_#{other_list_field.id}", [other_item_id]]]))
      described_class.perform_now
    end

    it "points the list action at the item and keeps the others" do
      expect(YAML.safe_load(stored(custom_action, :actions), permitted_classes: [Symbol]))
        .to eq([[:"custom_field_#{mapping.custom_field_id}", [item_id]],
                [:"custom_field_#{other_list_field.id}", [other_item_id]]])
    end
  end
end
