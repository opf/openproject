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

module Import
  class JiraImportJournals
    # Timestamps keep microseconds; a rational addition stays exact where a float loses a nanosecond.
    TIMESTAMP_STEP = Rational(1, 1_000_000).seconds

    attr_reader :work_package

    def initialize(work_package:)
      @work_package = work_package
      @pending_entries = []
    end

    def set_creation_time(date_time:)
      parsed = Time.zone.parse(date_time.to_s)
      work_package.update_column(:created_at, parsed)

      creation_journal = work_package.journals.first
      return unless creation_journal

      creation_journal.update_columns(
        created_at: parsed,
        updated_at: parsed,
        validity_period: (parsed..)
      )
    end

    def add_history(history:)
      group_history_entries(history).each do |group|
        @pending_entries << { type: :history, data: group, created: group["created"] }
      end
    end

    def add_comment(comment:, user:)
      @pending_entries << { type: :comment, data: comment, user:, created: comment["created"] }
    end

    def call(updated_at: nil)
      monotonic_entries.each do |entry, date_time|
        case entry[:type]
        when :history then create_history_journal(entry[:data], date_time)
        when :comment then create_comment_journal(entry[:data], entry[:user], date_time)
        end
      end

      restore_update_time(updated_at)
    end

    # Records the attachments in every existing journal, so that the import does not surface them
    # as a change of its own: the replayed Jira changelog is the only record of them.
    def backfill_attachments
      rows = missing_attachable_rows
      Journal::AttachableJournal.insert_all(rows) if rows.any?
    end

    def add_migration_entry(updated_at: nil)
      journalize_at(Time.current) do
        work_package.add_journal(user: User.system, notes: "", cause: Journal::CausedByImport.new(migrated: true))
      end

      restore_update_time(updated_at)
    end

    private

    def missing_attachable_rows
      attachments = work_package.attachments.pluck(:id, :file)
      return [] if attachments.empty?

      journal_ids = work_package.journals.pluck(:id)
      existing = recorded_attachable_pairs(journal_ids)

      journal_ids.product(attachments).filter_map do |journal_id, (attachment_id, filename)|
        { journal_id:, attachment_id:, filename: } unless existing.include?([journal_id, attachment_id])
      end
    end

    def recorded_attachable_pairs(journal_ids)
      Journal::AttachableJournal
        .where(journal_id: journal_ids)
        .pluck(:journal_id, :attachment_id)
        .to_set
    end

    # Journals::CreateService keeps the journals of a journable strictly ordered in time: a
    # timestamp that is not newer than the preceding journal's is discarded in favour of the
    # current time. Entries sharing a Jira timestamp, with each other or with the creation
    # journal, would therefore be stamped with the import date, so they are spaced out by the
    # smallest step a timestamp column can represent.
    def monotonic_entries
      previous = work_package.journals.maximum(:updated_at)

      chronological_entries.map do |entry|
        date_time = Time.zone.parse(entry[:created].to_s)
        date_time = previous + TIMESTAMP_STEP if previous && date_time <= previous
        previous = date_time

        [entry, date_time]
      end
    end

    def chronological_entries
      @pending_entries.sort_by.with_index do |entry, index|
        [Time.zone.parse(entry[:created].to_s), index]
      end
    end

    # Journals inherit their timestamps from the journable, so the work package has to carry the
    # Jira timestamp of the entry while it is being journalized.
    def journalize_at(date_time)
      work_package.update_column(:updated_at, date_time)
      yield
      work_package.save_journals
    end

    # The migration entry is journalized at import time, which must not leak into the work package
    # itself: it keeps reporting the timestamps it had in Jira.
    def restore_update_time(date_time)
      return if date_time.blank?

      work_package.update_column(:updated_at, Time.zone.parse(date_time.to_s))
    end

    def same_minute?(time1, time2)
      Time.zone.parse(time1.to_s).change(sec: 0) == Time.zone.parse(time2.to_s).change(sec: 0)
    end

    def group_history_entries(history)
      groups = []
      current = nil

      history.each do |entry|
        if mergeable_into_current?(current, entry)
          merge_into_current(current, entry)
        else
          groups << current if current
          current = new_group_from(entry)
        end
      end
      groups << current if current
      groups
    end

    def mergeable_into_current?(current, entry)
      return false unless current

      same_minute?(current["created"], entry["created"]) &&
        current["author"]["displayName"] == entry.dig("author", "displayName") &&
        !(current[:has_description] && entry_has_description?(entry))
    end

    def merge_into_current(current, entry)
      current["items"].concat(entry["items"] || [])
      current[:has_description] ||= entry_has_description?(entry)
    end

    def new_group_from(entry)
      items = entry["items"] || []
      { "created" => entry["created"],
        "author" => { "displayName" => entry.dig("author", "displayName") },
        "items" => items.dup,
        has_description: entry_has_description?(entry) }
    end

    def entry_has_description?(entry)
      (entry["items"] || []).any? { |item| item["field"]&.downcase == "description" }
    end

    def create_history_journal(entry, date_time)
      author_name = entry.dig("author", "displayName")
      items = convert_history_items(entry["items"])

      journalize_at(date_time) do
        cause = Journal::CausedByImport.new(author_name:, history: items)
        work_package.add_journal(user: User.system, notes: "", cause:)
      end
    end

    def create_comment_journal(comment, user, date_time)
      notes = convert_rich_text(comment["body"])

      journalize_at(date_time) do
        work_package.add_journal(user:, notes:, internal: false)
      end
    end

    def convert_history_items(items)
      return [] if items.blank?

      items.map do |item|
        if item["field"]&.downcase == "description"
          item.merge(
            "fromString" => convert_rich_text(item["fromString"]),
            "toString" => convert_rich_text(item["toString"])
          )
        else
          item
        end
      end
    end

    def convert_rich_text(description)
      return "" if description.blank?

      Import::JiraWikiMarkupConverter.new(description).convert
    end
  end
end
