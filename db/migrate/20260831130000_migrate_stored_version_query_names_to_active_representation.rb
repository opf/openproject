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

require Rails.root.join("db/migrate/migration_utils/utils")

class MigrateStoredVersionQueryNamesToActiveRepresentation < ActiveRecord::Migration[8.1]
  include Migration::Utils

  class MigratedQuery < ActiveRecord::Base
    self.table_name = "queries"
    serialize :column_names, type: Array
    serialize :sort_criteria, type: Array
  end

  DEFAULT_COLUMNS_SETTING = "work_package_list_default_columns"

  def up
    if Setting.work_package_multiple_versions?
      migrate_stored_names(select_from: "version", select_to: "target_versions",
                           filter_from: "version_id", filter_to: "target_version_id")
    else
      migrate_stored_names(select_from: "target_versions", select_to: "version",
                           filter_from: "target_version_id", filter_to: "version_id")
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def migrate_stored_names(select_from:, select_to:, filter_from:, filter_to:)
    migrate_selects(select_from, select_to)
    migrate_group_by(select_from, select_to)
    migrate_filters(filter_from, filter_to)
    migrate_default_columns_setting(select_from, select_to)
  end

  def migrate_selects(from, to_name)
    relation = MigratedQuery.where("column_names LIKE :name OR sort_criteria LIKE :name", name: "%#{from}%")

    in_configurable_batches(relation) do |batches|
      batches.each_record { |query| migrate_query_selects(query, from, to_name) }
    end
  end

  def migrate_query_selects(query, from, to_name)
    columns = query.column_names
    migrated_columns = columns.map { |name| name.to_s == from ? to_name.to_sym : name }.uniq

    criteria = query.sort_criteria
    migrated_criteria = rename_sort_criteria(criteria, from, to_name)

    changes = {}
    changes[:column_names] = migrated_columns unless migrated_columns == columns
    changes[:sort_criteria] = migrated_criteria unless migrated_criteria == criteria
    query.update_columns(changes) if changes.any?
  end

  def rename_sort_criteria(criteria, from, to_name)
    seen = Set.new
    criteria.filter_map do |name, direction|
      renamed_name = name == from ? to_name : name
      next unless seen.add?(renamed_name)

      [renamed_name, direction]
    end
  end

  def migrate_group_by(from, to_name)
    execute_sql("UPDATE queries SET group_by = :to_name WHERE group_by = :from", to_name:, from:)
  end

  def migrate_filters(from, to_name)
    relation = MigratedQuery.where("filters LIKE :name", name: "%#{from}%")

    in_configurable_batches(relation) do |batches|
      batches.each_record do |query|
        filter_hash = load_filter_hash(query.read_attribute(:filters))
        next unless filter_hash.key?(from)

        query.update_column(:filters, YAML.dump(rename_filter_hash(filter_hash, from, to_name)))
      end
    end
  end

  def load_filter_hash(raw)
    yaml = raw.gsub("!ruby/object:Syck::DefaultKey {}", '"="')
    YAML.load(yaml, permitted_classes: [Symbol, Date]) || {}
  end

  def rename_filter_hash(filter_hash, from, to_name)
    filter_hash.each_with_object({}) do |(key, options), renamed|
      renamed_key = key == from ? to_name : key
      next if renamed.key?(renamed_key) && renamed_key != key

      renamed[renamed_key] = options
    end
  end

  def migrate_default_columns_setting(from, to_name)
    row = execute_sql("SELECT value FROM settings WHERE name = :name", name: DEFAULT_COLUMNS_SETTING).first
    return if row.nil? || row["value"].nil?

    columns = YAML.safe_load(row["value"], permitted_classes: [Symbol])
    migrated = columns.map { |name| name.to_s == from ? to_name : name }.uniq
    return if migrated == columns

    execute_sql(
      "UPDATE settings SET value = :value, updated_at = NOW() WHERE name = :name",
      value: YAML.dump(migrated), name: DEFAULT_COLUMNS_SETTING
    )
  end
end
