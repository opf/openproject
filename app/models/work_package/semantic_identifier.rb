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

module WorkPackage::SemanticIdentifier
  extend ActiveSupport::Concern

  # Semantic-identifier shape ("PROJ-42"). Use this when the numeric and
  # semantic branches need different boundary rules; use `ID_ROUTE_CONSTRAINT`
  # when both branches share one regex.
  SEMANTIC_ID_PATTERN = /#{Projects::Identifier::SEMANTIC_FORMAT.source}-\d+/

  # Matches either a numeric ID ("12345") or a semantic identifier ("PROJ-42").
  # Used in Rails route constraints so both forms are accepted in URLs.
  # The frontend equivalent lives in WP_ID_URL_PATTERN (work-package-id-pattern.ts).
  ID_ROUTE_CONSTRAINT = /\d+|#{SEMANTIC_ID_PATTERN.source}/

  # Anchored POSIX regex matching identifiers of the exact form "<slug>-<digits>"
  # for a concrete project slug, so prefixes containing dashes don't over-match
  # (matching "my" must not touch "my-project-42"). Used by the for_slug_prefix
  # scopes on WorkPackage and WorkPackageSemanticAlias. Regexp.escape output is
  # valid in PostgreSQL's ARE syntax: it backslash-escapes punctuation (which
  # ARE treats as literals) and never emits class escapes.
  def self.slug_prefix_pattern(slug)
    "^#{Regexp.escape(slug)}-[0-9]+$"
  end

  # Raised when a finder is invoked in a way that cannot resolve a semantic
  # identifier — e.g. find_by(id: "PROJ-42") which reduces to a raw SQL
  # WHERE clause that cannot consult the alias table. Subclasses ArgumentError
  # so callers that rescue ArgumentError still catch it, but it can be rescued
  # specifically when needed.
  class UnsupportedLookup < ArgumentError; end

  # Validation context that permits deliberate changes to identifier/sequence_number
  # on a persisted work package:
  #
  #   work_package.save(context: WorkPackage::SemanticIdentifier::IDENTIFIER_REWRITE_CONTEXT)
  #
  # See #semantic_identifier_fields_not_accidentally_changed.
  IDENTIFIER_REWRITE_CONTEXT = :identifier_rewrite

  included do
    has_many :semantic_aliases,
             class_name: "WorkPackageSemanticAlias",
             foreign_key: :work_package_id,
             inverse_of: :work_package,
             dependent: :delete_all

    scope :semantically_sequenced, -> { where.not(sequence_number: nil) }
    scope :unsequenced, -> { where(sequence_number: nil) }
    scope :non_semantic_of, ->(project) {
      semantically_sequenced.where("identifier IS DISTINCT FROM (? || '-' || sequence_number::text)", project.identifier)
    }
    scope :non_semantic, -> {
      joins(:project).semantically_sequenced
        .where("work_packages.identifier IS DISTINCT FROM projects.identifier || '-' || work_packages.sequence_number::text")
    }
    # Work packages whose identifier column carries the given project slug
    # prefix, i.e. is of the exact form "<slug>-<digits>". Counterpart to
    # WorkPackageSemanticAlias.for_slug_prefix for the denormalized column.
    scope :for_slug_prefix, ->(slug) {
      where("identifier ~ ?", WorkPackage::SemanticIdentifier.slug_prefix_pattern(slug))
    }
    # Work packages that currently resolve via identifiers of the form
    # "<slug>-<digits>" — through the identifier column or an alias row.
    # The single-identifier counterpart is FinderMethods#scope_for_semantic_identifier.
    # ReleaseReservedIdentifierService severs exactly this set, and the release
    # dialog counts it — keep the two in sync through this scope.
    scope :resolving_via_slug_prefix, ->(slug) {
      where(id: WorkPackageSemanticAlias.for_slug_prefix(slug).select(:work_package_id))
        .or(for_slug_prefix(slug))
    }

    attr_accessor :skip_semantic_id_allocation

    after_create :allocate_and_register_semantic_id, if: -> { Setting::WorkPackageIdentifier.semantic? && !skip_semantic_id_allocation }

    validate :validate_semantic_identifier_fields
  end

  class_methods do
    include FinderMethods

    # Extend every relation built from this model with semantic finder methods,
    # so that WorkPackage.visible(user).find("PROJ-42") and
    # project.work_packages.find_by_display_id("PROJ-42") both work. Overriding
    # `relation` is the seam that reaches every scope and association proxy;
    # including FinderMethods into class_methods alone only covers class-level
    # calls like WorkPackage.find.
    def relation
      super.extending(FinderMethods)
    end
  end

  # Returns true when value looks like a semantic work package identifier
  # ("PROJ-42"). Non-strings (Integer, Hash, nil, Array), empty and numeric strings
  # ("123", " 456 ", "  ") return false — these fall through to standard PK lookup.
  #
  # The round-trip check (rather than a regex) is intentional for performance.
  # Every value that reaches a work-package finder either parses as an integer
  # or doesn't, and that's enough to dispatch correctly. Don't tighten it.
  def self.semantic_id?(value)
    return false unless value.is_a?(String)

    stripped = value.strip
    return false if stripped.empty?

    stripped.to_i.to_s != stripped
  end

  # Returns true when value is a canonical numeric ID —
  # an Integer, or a String that round-trips through `to_i.to_s` ("0", "123").
  # Rejects leading-zero strings ("0123"), non-numeric strings, empty strings and nil.
  #
  # A numeric ID is always a routable primary key; a semantic ID is always
  # routed through the identifier/alias path. Anything else — nil, blank
  # strings, Hashes, Arrays — is neither, and both predicates return false
  # so the caller short-circuits before any lookup.
  def self.numeric_id?(value)
    case value
    when Integer then true
    when String
      return false if value.strip.blank?

      !semantic_id?(value)
    else false
    end
  end

  # Returns the user-facing identifier for a work package given its id and identifier.
  # In semantic mode: the project-based identifier (e.g. "PROJ-42")
  # In classic mode: the numeric database ID (even if identifier is set in the DB)
  def self.display_id_for(id, identifier)
    return id unless Setting::WorkPackageIdentifier.semantic?

    identifier.presence || id
  end

  # Formats a resolved display id for inline UI display.
  # Semantic mode: "PROJ-42" (no prefix — self-describing)
  # Classic mode: "#42" (hash-prefixed)
  def self.format_display_id(display_id)
    display_id.is_a?(String) && display_id.match?(/[A-Za-z]/) ? display_id : "##{display_id}"
  end

  # Returns the inline-formatted identifier for a work package given its id and identifier.
  def self.formatted_id_for(id, identifier)
    format_display_id(display_id_for(id, identifier))
  end

  # Returns the user-facing identifier for this work package.
  # In semantic mode: the project-based identifier (e.g. "PROJ-42")
  # In classic mode: the numeric database ID
  def display_id
    WorkPackage::SemanticIdentifier.display_id_for(id, identifier)
  end

  def formatted_id
    WorkPackage::SemanticIdentifier.format_display_id(display_id)
  end

  # Override ActiveRecord's default `to_param` so Rails URL helpers
  # (work_package_path, polymorphic_path, form_for, etc.) automatically
  # produce semantic-id URLs in semantic mode. In classic mode display_id
  # returns the integer primary key, so this is behaviourally identical
  # to the inherited `id&.to_s`.
  #
  # API v3 deliberately bypasses this by passing `id:` kwargs explicitly
  # (see lib/api/v3/work_packages/work_package_representer.rb) so HAL
  # self-links remain numeric and stable for API consumers.
  def to_param
    display_id&.to_s
  end

  # Allocates the next semantic identifier in the current project and assigns it to the WP.
  # Also writes alias rows for every identifier the project has ever used (including "ghost" aliases).
  #
  # This should generally be run following project_id-mutating operations on WorkPackage records (like create or move).
  def allocate_and_register_semantic_id
    WorkPackageSemanticAlias.transaction do
      sequence_number, identifier = project.allocate_wp_semantic_identifier!
      # Re-map the semantic identifier to the new project
      update_columns(sequence_number:, identifier:)
      # Insert current, historical + ghost aliases for the new project
      # Note: In case of WP move, the previous mapping for the old project is assumed
      #   to be present in the alias table already, ever since its prior create/move operation.
      semantic_aliases.insert_all(alias_rows_for_sequence_number(sequence_number),
                                  unique_by: :identifier)
    end
  end

  # Builds alias rows for every identifier this project has ever used at the given sequence (including the current one).
  # This also includes "ghost identifiers" -- i.e. those that weren't ever actually generated, but should work
  # as a historical alias (e.g. OLDPROJ-42 should work even if WP #42 was created after rename to NEWPROJ)
  def alias_rows_for_sequence_number(seq)
    project.slugs
           .pluck(:slug)
           .map { |prefix| { identifier: "#{prefix}-#{seq}", work_package_id: id } }
  end

  private

  def validate_semantic_identifier_fields
    semantic_identifier_fields_consistent
    semantic_identifier_fields_not_accidentally_changed
  end

  # Ensures identifier and sequence_number are always written together.
  # One field set without the other indicates a partial write and is never valid.
  def semantic_identifier_fields_consistent
    return unless identifier.present? ^ sequence_number.present?

    errors.add(:identifier, :semantic_identifier_incomplete)
  end

  # Guards against accidental edits, e.g. from a Rails console: identifiers are
  # allocated automatically and resolved through the alias table, so a
  # hand-written change silently breaks links and identifier history.
  # Deliberate changes must be saved with the IDENTIFIER_REWRITE_CONTEXT
  # validation context.
  def semantic_identifier_fields_not_accidentally_changed
    return unless persisted?
    return if Array(validation_context).include?(IDENTIFIER_REWRITE_CONTEXT)
    return if cleared_for_project_move?

    %w[identifier sequence_number].each do |attribute|
      next unless attribute_changed?(attribute)

      errors.add(attribute, :must_not_be_changed, context: IDENTIFIER_REWRITE_CONTEXT)
    end
  end

  # Clearing both fields while moving to another project is part of the move
  # operation itself: the identifier belongs to the source project and must be
  # cleared in the same UPDATE that changes project_id (unique index on
  # project_id/sequence_number). A fresh identifier is allocated after the move.
  # See WorkPackages::SetAttributesService#clear_semantic_identifier.
  def cleared_for_project_move?
    project_id_changed? && identifier.nil? && sequence_number.nil?
  end
end
