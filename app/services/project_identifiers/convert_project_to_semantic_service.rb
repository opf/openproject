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

module ProjectIdentifiers
  # Brings a single project fully up to date for semantic identifier mode:
  #
  # 1. Fixes the project identifier if it is not in valid semantic format.
  # 2. Rewrites stale WP identifiers whose prefix no longer matches the project.
  # 3. Assigns sequence numbers to WPs that have none yet.
  # 4. Seeds the alias table for all historical project identifier prefixes.
  class ConvertProjectToSemanticService
    def initialize(project)
      @project = project
    end

    def call
      fix_identifier_if_needed
      ApplicationRecord.transaction { reset_stale_identifiers }
      ApplicationRecord.transaction { backfill_missing_ids }
      ApplicationRecord.transaction { seed_alias_table }
    end

    private

    attr_reader :project

    def fix_identifier_if_needed
      # Pure format check — no DB queries.
      return if ProjectIdentifiers::IdentifierAutofix::ProblematicIdentifiers.valid_format?(project.identifier)

      # Identifier assignments must run one at a time to avoid conflicts with concurrent renames or conversions.
      OpenProject::Mutex.with_advisory_lock(Project, "semantic_identifier_generation") do
        assign_semantic_identifier
      end
    end

    def assign_semantic_identifier
      # Prefer restoring the project's last known semantic identifier (from
      # FriendlyId history) so that existing WP identifiers remain valid and
      # aliases need no update. Fall back to generating a fresh suggestion.
      new_identifier = project.previous_semantic_identifier ||
                       project.suggest_identifier(mode: Setting::WorkPackageIdentifier::SEMANTIC)

      raise "Generated identifier is blank for project #{project.id}" if new_identifier.blank?

      save_identifier!(new_identifier)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      handle_identifier_conflict(new_identifier, e)
    end

    def handle_identifier_conflict(attempted_id, error)
      Rails.logger.warn "#{self.class}: Could not set identifier '#{attempted_id}' for project #{project.id}; " \
                        "falling back to a random identifier. (#{error.message})"
      save_identifier!("P#{SecureRandom.alphanumeric(5).upcase}")
    end

    def save_identifier!(new_identifier)
      project.identifier = new_identifier
      # Suppress notifications: this is a background system operation, not a user edit.
      Journal::NotificationConfiguration.with(false) do
        # Uses :semantic_conversion context to allow saving a semantic ID while the system is in classic mode.
        project.save!(context: :semantic_conversion)
      end
    end

    def reset_stale_identifiers
      # Fix WPs whose identifier does not exactly match the expected semantic identifier
      #   (caused by renames or cross-project moves in classic mode)
      WorkPackage.where(project:).non_semantic_of(project).update_all(identifier: nil, sequence_number: nil)
    end

    def backfill_missing_ids
      WorkPackage.where(project:)
                 .unsequenced
                 .in_batches(order: :asc) do |batch|
        project.reserve_semantic_id_block!(batch.pluck(:id), insert_aliases: false)
      end
    end

    def seed_alias_table
      slug_prefixes = project.slugs.pluck(:slug)
      return if slug_prefixes.empty?

      WorkPackage.where(project:).semantically_sequenced.in_batches do |batch|
        alias_rows = batch.pluck(:id, :sequence_number)
                          .product(slug_prefixes)
                          .map { |(wp_id, seq), prefix| { identifier: "#{prefix}-#{seq}", work_package_id: wp_id } }
        WorkPackageSemanticAlias.insert_all(alias_rows, unique_by: :identifier) if alias_rows.any?
      end
    end
  end
end
