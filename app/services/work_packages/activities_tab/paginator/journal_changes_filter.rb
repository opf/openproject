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

# SQL-based heuristic to filter journals with changes.
#
# Includes journals that have:
#   * Initial journal (version = 1) - always included
#   * Attachment changes (compares attachable_journals with predecessor)
#   * Custom field changes (compares customizable_journals with predecessor)
#   * File link changes (compares storages_file_links_journals with predecessor)
#   * Cause metadata (system-triggered changes)
#   * Attribute/data changes (compares work_package_journals columns with immediate predecessor)
#
# Each journal's immediate predecessor is resolved once, in a CTE named `journals` that
# shadows the table and exposes `predecessor_id` / `predecessor_data_id` columns. Every
# change-detection branch then reads those columns instead of re-seeking the predecessor.
# Changeset journals carry no detectable attribute history and are always included.
class WorkPackages::ActivitiesTab::Paginator::JournalChangesFilter
  class << self
    # @param membership [ActiveRecord::Relation] the activity feed's journals
    #   (visible work package journals, optionally unioned with changeset journals)
    def apply(membership)
      Journal
        .with(journals: Arel.sql(enriched_journals_sql(membership)))
        .where(OpenProject::SqlSanitization.sanitize(changes_condition_sql))
    end

    private

    # Enrich each journal row with its immediate predecessor's id and data_id. The
    # predecessor is the highest version below the current one, located through the
    # (journable_type, journable_id, version) index; versions are incremental but may
    # have gaps, so the seek matches on `< version` rather than `version - 1`. A LEFT
    # JOIN keeps initial (version = 1) journals, whose predecessor columns stay NULL.
    def enriched_journals_sql(membership)
      <<~SQL.squish
        SELECT curr.*,
               predecessor.id AS predecessor_id,
               predecessor.data_id AS predecessor_data_id
        FROM (#{membership.to_sql}) curr
        LEFT JOIN LATERAL (
          SELECT p.id, p.data_id
          FROM journals p
          WHERE p.journable_id = curr.journable_id
            AND p.journable_type = curr.journable_type
            AND p.version < curr.version
          ORDER BY p.version DESC
          LIMIT 1
        ) predecessor ON TRUE
      SQL
    end

    def changes_condition_sql
      <<~SQL.squish
        journals.journable_type = '#{Changeset.name}'
        OR journals.version = 1
        OR (journals.cause IS NOT NULL AND journals.cause != '{}')
        OR EXISTS (#{attribute_data_changes_condition_sql})
        OR EXISTS (#{attachment_changes_condition_sql})
        OR EXISTS (#{custom_field_changes_condition_sql})
        OR EXISTS (#{file_link_changes_condition_sql})
      SQL
    end

    def attribute_data_changes_condition_sql
      <<~SQL.squish
        SELECT 1
          FROM work_package_journals pred_data
          INNER JOIN work_package_journals curr_data ON curr_data.id = journals.data_id
          WHERE pred_data.id = journals.predecessor_data_id
            AND (#{data_changes_condition_sql})
      SQL
    end

    def attachment_changes_condition_sql
      association_changes_condition_sql(
        table: Journal::AttachableJournal.table_name,
        join_columns: ["attachment_id"],
        value_columns: ["filename"]
      )
    end

    # Custom fields require special handling because of multi-value fields.
    # For multi-value CFs (e.g., multi-select), we must join on BOTH custom_field_id AND value
    # to prevent Cartesian products. This matches the behavior of:
    # Acts::Journalized::Differ::Association with multiple_values: :joined
    def custom_field_changes_condition_sql
      association_changes_condition_sql(
        table: Journal::CustomizableJournal.table_name,
        join_columns: %w[custom_field_id value],
        value_columns: [] # Changes detected via join_columns, not value comparison
      )
    end

    def file_link_changes_condition_sql
      association_changes_condition_sql(
        table: Journal::StorableJournal.table_name,
        join_columns: ["file_link_id"],
        value_columns: %w[link_name storage_name]
      )
    end

    def data_changes_condition_sql
      data_change_columns = Journal::WorkPackageJournal.column_names - ["id"]

      data_change_columns.map do |column_name|
        "pred_data.#{column_name} IS DISTINCT FROM curr_data.#{column_name}"
      end.join(" OR ")
    end

    # Detect changes in association journals by checking for additions or removals.
    # join_columns: Array of column names to match predecessor and current records (e.g., ["attachment_id"])
    #               For multi-value fields, use multiple columns (e.g., ["custom_field_id", "value"])
    # value_columns: Array of column names to compare for modifications (e.g., ["filename"])
    def association_changes_condition_sql(table:, join_columns:, value_columns:)
      "#{association_items_added_sql(table:, join_columns:, value_columns:)} " \
        "UNION ALL " \
        "#{association_items_removed_sql(table:, join_columns:)}"
    end

    # Detect added or modified association items by comparing with predecessor journal.
    # Returns SQL that finds items that either:
    # - Exist in current journal but not in predecessor (additions)
    # - Exist in both but have different values (modifications)
    def association_items_added_sql(table:, join_columns:, value_columns:)
      join_conditions = join_columns.map do |col|
        "pred.#{col} = curr.#{col}"
      end.join(" AND ")

      # No value columns means join_columns fully define identity
      # (e.g., custom fields where custom_field_id + value is the composite key)
      value_changes = if value_columns.any?
                        value_columns.map do |col|
                          "pred.#{col} IS DISTINCT FROM curr.#{col}"
                        end.join(" OR ")
                      end

      where_clause = if value_changes
                       "pred.id IS NULL OR (#{value_changes})"
                     else
                       "pred.id IS NULL"
                     end

      <<~SQL.squish
        SELECT 1
          FROM #{table} curr
          LEFT JOIN #{table} pred
            ON pred.journal_id = journals.predecessor_id
            AND #{join_conditions}
          WHERE curr.journal_id = journals.id
            AND (#{where_clause})
      SQL
    end

    # Detect removed association items by comparing with predecessor journal.
    # Returns SQL that finds items that existed in predecessor but not in current journal.
    def association_items_removed_sql(table:, join_columns:)
      join_conditions = join_columns.map do |col|
        "curr.#{col} = pred.#{col}"
      end.join(" AND ")

      <<~SQL.squish
        SELECT 1
          FROM #{table} pred
          LEFT JOIN #{table} curr
            ON curr.journal_id = journals.id
            AND #{join_conditions}
          WHERE pred.journal_id = journals.predecessor_id
            AND curr.id IS NULL
      SQL
    end
  end
end
