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
require Rails.root.join("db/migrate/20260831130000_migrate_stored_version_query_names_to_active_representation")

RSpec.describe MigrateStoredVersionQueryNamesToActiveRepresentation, type: :model do
  def store_raw(query, column_names:, sort_criteria:, group_by:, filters:)
    Query.where(id: query.id).update_all(
      ["column_names = ?, sort_criteria = ?, group_by = ?, filters = ?",
       YAML.dump(column_names), YAML.dump(sort_criteria), group_by, YAML.dump(filters)]
    )
  end

  def raw_filters(query)
    described_class::MigratedQuery.find(query.id).read_attribute(:filters)
  end

  def parsed_filters(query)
    YAML.safe_load(raw_filters(query), permitted_classes: [Symbol, Date])
  end

  def default_columns_setting_value
    ActiveRecord::Base.connection.select_value(
      "SELECT value FROM settings WHERE name = 'work_package_list_default_columns'"
    )
  end

  def store_default_columns_setting(names)
    ActiveRecord::Base.connection.execute("DELETE FROM settings WHERE name = 'work_package_list_default_columns'")
    ActiveRecord::Base.connection.execute(
      ActiveRecord::Base.sanitize_sql(
        ["INSERT INTO settings (name, value, updated_at) VALUES (?, ?, NOW())",
         "work_package_list_default_columns", YAML.dump(names)]
      )
    )
  end

  context "with target versions active", with_settings: { work_package_multiple_versions: true } do
    shared_let(:legacy_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id version],
                  sort_criteria: [["version", "asc"], ["id", "asc"]],
                  group_by: "version",
                  filters: { "version_id" => { "operator" => "=", "values" => ["1"] } })
      end
    end

    shared_let(:both_selects_dedupe_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id version target_versions],
                  sort_criteria: [["version", "asc"], ["target_versions", "desc"]],
                  group_by: nil,
                  filters: {})
      end
    end

    shared_let(:both_filters_dedupe_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id subject],
                  sort_criteria: [["id", "asc"]],
                  group_by: nil,
                  filters: { "target_version_id" => { "operator" => "=", "values" => ["2"] },
                             "version_id" => { "operator" => "=", "values" => ["1"] } })
      end
    end

    shared_let(:legacy_filter_first_dedupe_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id subject],
                  sort_criteria: [["id", "asc"]],
                  group_by: nil,
                  filters: { "version_id" => { "operator" => "=", "values" => ["1"] },
                             "target_version_id" => { "operator" => "=", "values" => ["2"] } })
      end
    end

    shared_let(:untouched_query) do
      create(:query, column_names: %i[id subject], sort_criteria: [["id", "asc"]])
    end

    shared_let(:already_active_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id target_versions],
                  sort_criteria: [["target_versions", "asc"]],
                  group_by: "target_versions",
                  filters: { "target_version_id" => { "operator" => "=", "values" => ["4"] } })
      end
    end

    it "renames the stored select, sort, group_by, and filter names to their active representation" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(legacy_query.reload.column_names).to eq(%i[id target_versions])
      expect(legacy_query.read_attribute(:sort_criteria)).to eq([["target_versions", "asc"], ["id", "asc"]])
      expect(legacy_query.group_by).to eq("target_versions")
      expect(parsed_filters(legacy_query)).to eq("target_version_id" => { "operator" => "=", "values" => ["1"] })
    end

    it "dedupes selects when both the legacy and the active name are already stored" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(both_selects_dedupe_query.reload.column_names).to eq(%i[id target_versions])
      expect(both_selects_dedupe_query.read_attribute(:sort_criteria)).to eq([["target_versions", "asc"]])
    end

    it "keeps the entry already stored under the active filter key when both are present" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(parsed_filters(both_filters_dedupe_query)).to eq(
        "target_version_id" => { "operator" => "=", "values" => ["2"] }
      )
    end

    it "keeps the active filter key's entry regardless of storage order" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(parsed_filters(legacy_filter_first_dedupe_query)).to eq(
        "target_version_id" => { "operator" => "=", "values" => ["2"] }
      )
    end

    it "leaves a query without any version references untouched" do
      before_column_names = untouched_query.column_names_before_type_cast
      before_sort_criteria = untouched_query.sort_criteria_before_type_cast
      before_group_by = untouched_query.group_by_before_type_cast
      before_filters = raw_filters(untouched_query)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
      untouched_query.reload

      expect(untouched_query.column_names_before_type_cast).to eq(before_column_names)
      expect(untouched_query.sort_criteria_before_type_cast).to eq(before_sort_criteria)
      expect(untouched_query.group_by_before_type_cast).to eq(before_group_by)
      expect(raw_filters(untouched_query)).to eq(before_filters)
    end

    it "leaves a query already stored under the active names byte-identical" do
      before_column_names = already_active_query.column_names_before_type_cast
      before_sort_criteria = already_active_query.sort_criteria_before_type_cast
      before_group_by = already_active_query.group_by_before_type_cast
      before_filters = raw_filters(already_active_query)

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
      already_active_query.reload

      expect(already_active_query.column_names_before_type_cast).to eq(before_column_names)
      expect(already_active_query.sort_criteria_before_type_cast).to eq(before_sort_criteria)
      expect(already_active_query.group_by_before_type_cast).to eq(before_group_by)
      expect(raw_filters(already_active_query)).to eq(before_filters)
    end

    it "renames the work_package_list_default_columns setting" do
      store_default_columns_setting(%w[id version subject])

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(YAML.safe_load(default_columns_setting_value)).to eq(%w[id target_versions subject])
    end
  end

  context "with target versions inactive", with_settings: { work_package_multiple_versions: false } do
    shared_let(:legacy_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id target_versions],
                  sort_criteria: [["target_versions", "asc"]],
                  group_by: "target_versions",
                  filters: { "target_version_id" => { "operator" => "=", "values" => ["3"] } })
      end
    end

    shared_let(:both_selects_dedupe_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id target_versions version],
                  sort_criteria: [["target_versions", "asc"], ["version", "desc"]],
                  group_by: nil,
                  filters: {})
      end
    end

    shared_let(:both_filters_dedupe_query) do
      create(:query).tap do |query|
        store_raw(query,
                  column_names: %i[id subject],
                  sort_criteria: [["id", "asc"]],
                  group_by: nil,
                  filters: { "version_id" => { "operator" => "=", "values" => ["1"] },
                             "target_version_id" => { "operator" => "=", "values" => ["2"] } })
      end
    end

    it "renames the stored names back to the single-version representation" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(legacy_query.reload.column_names).to eq(%i[id version])
      expect(legacy_query.read_attribute(:sort_criteria)).to eq([["version", "asc"]])
      expect(legacy_query.group_by).to eq("version")
      expect(parsed_filters(legacy_query)).to eq("version_id" => { "operator" => "=", "values" => ["3"] })
    end

    it "dedupes selects when both the legacy and the active name are already stored" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(both_selects_dedupe_query.reload.column_names).to eq(%i[id version])
      expect(both_selects_dedupe_query.read_attribute(:sort_criteria)).to eq([["version", "asc"]])
    end

    it "keeps the entry already stored under the active filter key when both are present" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(parsed_filters(both_filters_dedupe_query)).to eq(
        "version_id" => { "operator" => "=", "values" => ["1"] }
      )
    end
  end
end
