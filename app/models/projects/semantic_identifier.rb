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

module Projects::SemanticIdentifier
  extend ActiveSupport::Concern

  # Atomically allocates the next sequence number for a work package in this project
  # and returns it paired with the resulting semantic identifier (e.g. [42, "PROJ-42"]).
  # Uses an advisory lock scoped to this project to serialize concurrent allocations
  # without blocking unrelated project row writes.
  def allocate_wp_semantic_identifier!
    seq = OpenProject::Mutex.with_advisory_lock(self.class, "wp_sequence_#{id}") do
      allocate_sequence_range!.first
    end

    [seq, "#{identifier}-#{seq}"]
  end

  # Returns the most-recent slug from FriendlyId history that is a valid semantic
  # identifier and is not currently held by another project, or nil if none exists.
  # Used by the backfill job to restore a prior semantic identifier instead of
  # generating a fresh one, so existing WP identifiers and aliases remain correct.
  def previous_semantic_identifier
    candidates = previous_semantic_identifier_candidates
    return nil if candidates.empty?

    taken = self.class
                .where.not(id:)
                .where("LOWER(identifier) IN (?)", candidates.map(&:downcase))
                .pluck(:identifier)
                .to_set(&:downcase)

    candidates.find { |slug| taken.exclude?(slug.downcase) }
  end

  # Atomically reserves `work_package_ids.size` consecutive sequence numbers,
  # bulk-updates those work packages' sequence_number and identifier columns,
  # and (by default) inserts alias rows for every historical slug prefix of
  # this project.
  #
  # Returns a hash of { work_package_id => semantic_identifier } so callers
  # already holding live records can refresh in-memory state without reloading.
  #
  # Pass insert_aliases: false when the caller will run seed_alias_table
  # immediately after (e.g. the conversion backfill path), to avoid
  # duplicating the alias insertion work.
  def reserve_semantic_id_block!(work_package_ids, insert_aliases: true)
    count = work_package_ids.size
    return {} if count.zero?

    range = allocate_sequence_range!(count)
    sorted_ids = work_package_ids.sort

    WorkPackageSemanticAlias.transaction do
      bulk_assign_sequence_numbers!(sorted_ids, range)
      insert_sequence_aliases!(sorted_ids, range) if insert_aliases
    end

    sorted_ids.zip(range).to_h { |wp_id, seq| [wp_id, "#{identifier}-#{seq}"] }
  end

  # Called after this project's identifier is renamed. Atomically:
  # 1. Appends new-prefix aliases for every WP that ever carried an old-prefix alias.
  # 2. Updates identifier on resident WPs to the new prefix.
  def handle_semantic_rename(old_identifier, batch_size: 1000)
    like_pattern = "#{self.class.sanitize_sql_like(old_identifier)}-%"
    prefix = "#{old_identifier}-"
    new_prefix = "#{identifier}-"

    WorkPackageSemanticAlias.transaction do
      append_aliases_with_new_prefix(like_pattern:, prefix:, new_prefix:, batch_size:)
      rewrite_semantic_ids(like_pattern:, prefix:, new_prefix:, batch_size:)
    end
  end

  private

  def previous_semantic_identifier_candidates
    slugs
      .order(created_at: :desc)
      .pluck(:slug)
      .select { |slug| ProjectIdentifiers::IdentifierAutofix::ProblematicIdentifiers.valid_format?(slug) }
  end

  def bulk_assign_sequence_numbers!(sorted_ids, range)
    proj_ident = self.class.connection.quote(identifier)
    values = sorted_ids.zip(range)
                       .map { |wp_id, seq| "(#{wp_id}, #{seq})" }
                       .join(", ")
    self.class.connection.execute(<<~SQL.squish)
      UPDATE work_packages
      SET sequence_number = v.seq,
          identifier      = #{proj_ident} || '-' || v.seq::text
      FROM (VALUES #{values}) AS v(id, seq)
      WHERE work_packages.id = v.id
    SQL
  end

  def insert_sequence_aliases!(sorted_ids, range)
    slug_prefixes = slugs.pluck(:slug)
    alias_rows = sorted_ids.zip(range).flat_map do |wp_id, seq|
      slug_prefixes.map { |pfx| { identifier: "#{pfx}-#{seq}", work_package_id: wp_id } }
    end
    WorkPackageSemanticAlias.insert_all(alias_rows, unique_by: :identifier) if alias_rows.any?
  end

  # Atomically reserves `count` sequence numbers and returns them as a Range.
  # The UPDATE is atomic at the PostgreSQL row level, so concurrent callers
  # serialize without a separate advisory lock.
  def allocate_sequence_range!(count = 1)
    base = self.class.connection.select_value(<<~SQL.squish) - count
      UPDATE projects
      SET wp_sequence_counter = wp_sequence_counter + #{count}
      WHERE id = #{id}
      RETURNING wp_sequence_counter
    SQL
    (base + 1)..(base + count)
  end

  # For every alias row whose identifier starts with the old prefix, inserts a
  # corresponding row with the new prefix. This covers WPs still in the project
  # as well as any that have moved out but still carry old-prefix alias rows.
  def append_aliases_with_new_prefix(like_pattern:, prefix:, new_prefix:, batch_size:)
    WorkPackageSemanticAlias
      .where("identifier LIKE ?", like_pattern)
      .in_batches(of: batch_size) do |relation|
      now = Time.current
      WorkPackageSemanticAlias.connection.execute(
        WorkPackageSemanticAlias.sanitize_sql([<<~SQL.squish, { prefix:, new_prefix:, now: }])
          INSERT INTO work_package_semantic_aliases (identifier, work_package_id, created_at, updated_at)
          SELECT REPLACE(identifier, :prefix, :new_prefix), work_package_id, :now, :now
          FROM (#{relation.to_sql}) AS batch
          ON CONFLICT (identifier) DO NOTHING
        SQL
      )
    end
  end

  # Updates the identifier column on all resident WPs to replace the old prefix with the new one.
  def rewrite_semantic_ids(like_pattern:, prefix:, new_prefix:, batch_size:)
    WorkPackage
      .where("identifier LIKE ?", like_pattern)
      .in_batches(of: batch_size) do |relation|
      relation.update_all(["identifier = REPLACE(identifier, ?, ?)", prefix, new_prefix])
    end
  end
end
