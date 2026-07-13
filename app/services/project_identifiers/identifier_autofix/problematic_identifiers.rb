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
  module IdentifierAutofix
    # Identifies projects whose identifiers violate the semantic identifier format
    # and provides classification and exclusion sets for suggestion generation.
    #
    # For main use by admin UI preview and batch migration job.
    #
    # == Performance notes
    #
    # * +#reserved_identifiers_for_admin_preview+ loads all non-problematic identifiers and historical slugs
    #   into memory. Fine for a one-off admin migration; if this ever becomes a hot
    #   path, consider a DB-backed exclusion check instead.
    #
    # * The regex scope conditions (+identifier ~ ?+) and +UPPER(identifier)+ won't
    #   hit a regular index. If queries get slow on large tables, a functional index
    #   on +UPPER(identifier)+ or a +pg_trgm+ GIN index would help.
    #
    #
    class ProblematicIdentifiers
      # Returns a Set of uppercased identifiers that must not be reused.
      # Combines all FriendlyId slug history for projects (current and historical slugs)
      # with system-reserved keywords from Projects::Identifier::RESERVED_IDENTIFIERS.
      def self.reserved_identifiers
        Project.identifier_slugs.upcased_values.to_set | model_reserved_identifiers
      end

      def self.model_reserved_identifiers
        Projects::Identifier::RESERVED_IDENTIFIERS.to_set(&:upcase)
      end

      # Priority-ordered format rules for identifier classification.
      FORMAT_RULES = [
        [:too_long, ->(id, max) { id.length > max }],
        [:numerical, ->(id, _) { id.match?(/\A\d+\z/) }],
        [:does_not_start_with_letter, ->(id, _) { !id.match?(/\A[A-Za-z]/) }],
        [:special_characters, ->(id, _) { id.match?(/[^a-zA-Z0-9_]/) }],
        [:not_fully_uppercased, ->(id, _) { id != id.upcase }]
      ].freeze

      # Returns a symbol classifying why the identifier violates the expected format,
      # or nil if the identifier is format-valid. Pure in-memory check — no DB queries.
      def self.format_error_reason(identifier)
        FORMAT_RULES.each do |reason, check|
          return reason if check.call(identifier, max_identifier_length)
        end
        nil
      end

      def self.valid_format?(identifier)
        format_error_reason(identifier).nil?
      end

      def self.max_identifier_length
        Projects::Identifier::SEMANTIC_IDENTIFIER_MAX_LENGTH
      end

      def scope
        @scope ||= exceeds_max_length
                      .or(contains_non_alphanumeric)
                      .or(does_not_start_with_letter)
                      .or(not_fully_uppercased)
      end

      delegate :count, to: :scope

      # Returns a symbol classifying why the identifier is problematic.
      # Must handle all identifiers matched by #scope.
      def error_reason(identifier)
        self.class.format_error_reason(identifier) || collision_error_reason(identifier) || :unknown
      end

      # Returns a Set of identifiers that must not be suggested for new assignments.
      # Unions currently active identifiers (non-problematic projects), historical FriendlyId slugs,
      # and system-reserved keywords — the full exclusion set used by #collision_error_reason.
      # Uses instance-level memoization so the same loaded sets power both this method and collision checks.
      def reserved_identifiers_for_admin_preview
        historical_identifiers | current_identifiers | self.class.model_reserved_identifiers
      end

      private

      def historical_identifiers
        @historical_identifiers ||= Project.identifier_slugs.historically_reserved.upcased_values.to_set
      end

      def exceeds_max_length          = Project.where("length(identifier) > ?", self.class.max_identifier_length)
      def contains_non_alphanumeric   = Project.where("identifier ~ ?", "[^a-zA-Z0-9_]")
      def does_not_start_with_letter  = Project.where("identifier ~ ?", "^[^A-Za-z]") # rubocop:disable Naming/PredicatePrefix
      def not_fully_uppercased        = Project.where("identifier != UPPER(identifier)")

      def collision_error_reason(identifier)
        if self.class.model_reserved_identifiers.include?(identifier)
          :reserved_by_system
        elsif current_identifiers.include?(identifier)
          :in_use
        elsif historical_identifiers.include?(identifier)
          :used_in_past
        end
      end

      def current_identifiers
        @current_identifiers ||= Project.where.not(id: scope.select(:id)).pluck(:identifier).to_set
      end
    end
  end
end
