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

module Projects::Identifier
  extend ActiveSupport::Concern

  CLASSIC_IDENTIFIER_MAX_LENGTH = 100
  SEMANTIC_IDENTIFIER_MAX_LENGTH = 10

  # Classic format validation regexes:
  # Character class only — callers anchor.
  CLASSIC_FORMAT_CHARS = /[a-z0-9\-_]+/
  # Anchored form with an anti-all-numeric guard.
  CLASSIC_FORMAT = /\A(?!\d+\z)#{CLASSIC_FORMAT_CHARS}\z/

  # Semantic format validation regex:
  # Unanchored shape of a semantic project identifier ("PROJ", "MY_PROJECT_1").
  # Composed into `WorkPackage::SemanticIdentifier::SEMANTIC_ID_PATTERN`.
  SEMANTIC_FORMAT = /[A-Z][A-Z0-9_]*/

  RESERVED_IDENTIFIERS = %w[new menu queries filters identifier_update_dialog identifier_suggestion].freeze

  included do
    extend FriendlyId

    normalizes :identifier, with: OpenProject::RemoveInvisibleCharacters

    # Generate identifier from name unless specified
    before_validation on: :create, if: -> { identifier.blank? && name.present? } do
      self.identifier = suggest_identifier
    end

    # Basic mode-agnostic identifier validation
    validates :identifier,
              presence: true,
              uniqueness: { case_sensitive: false },
              if: ->(p) { p.persisted? || p.identifier.present? }

    # Extended validation that runs checks specific to each format (classic & semantic)
    validates :identifier, "projects/identifier" => true, if: :identifier_changed?

    friendly_id :identifier, use: %i[finders history], slug_column: :identifier

    # FriendlyId::Slugged adds after_validation :unset_slug_if_invalid, which reverts the
    # slug column to its previous value when validation fails. With slug_column: :identifier,
    # this would reset a manually-set identifier back to nil on new records. Since the
    # identifier is managed by our own callbacks and user input (not FriendlyId's slug generator),
    # we disable this behaviour entirely.
    # Must be inside `included` to override FriendlyId::Slugged in the MRO.
    def unset_slug_if_invalid; end
  end

  # Domain-named scopes for the FriendlyId::Slug relation returned by Project.identifier_slugs.
  # Lets callers compose against verbs like .historically_reserved / .for_identifier / .upcased_values
  # instead of raw SQL fragments — keeping FriendlyId::Slug column knowledge in one place.
  module IdentifierSlugScopes
    # Slugs that are no longer used as any active project's identifier, but remain reserved
    # because FriendlyId still owns them — so they cannot be reused by another project.
    def historically_reserved
      where("LOWER(slug) NOT IN (SELECT LOWER(identifier) FROM projects)")
    end

    # Slugs whose lowercase form equals the lowercased input.
    def for_identifier(value)
      where("LOWER(slug) = ?", value.downcase)
    end

    # Excludes the given project's own slug history. No-op when project is nil.
    def excluding_project(project)
      project ? where.not(sluggable_id: project) : self
    end

    def upcased_values   = pluck(Arel.sql("UPPER(slug)"))
    def downcased_values = pluck(Arel.sql("LOWER(slug)"))
    # Verbatim values, no case folding. Named `raw_values` to avoid colliding
    # with `ActiveRecord::Relation#values` (an internal Rails method).
    def raw_values = pluck(:slug)
  end

  class_methods do
    def classic_identifier_format?(str)
      str.match?(CLASSIC_FORMAT)
    end

    def with_non_classic_identifier
      where("identifier !~ ?", "^#{CLASSIC_FORMAT_CHARS.source}$")
    end

    # FriendlyId's :history module records a row on every save, so this relation contains
    # both currently-used identifiers and historically-reserved ones. Compose with
    # `.historically_reserved` to filter to the latter. The name aligns with FriendlyId's
    # `project.slugs` association for vocabulary consistency.
    def identifier_slugs
      FriendlyId::Slug.where(sluggable_type: name).extending(IdentifierSlugScopes)
    end

    # There are two supported formats:
    # 1. slug identifiers (e.g. "project_one"), generated by ClassicIdentifierSuggestionGenerator
    #   * work package ID =  global ID (e.g. "#123")
    # 2. semantic identifiers (e.g. "PROJ1"), generated by ProjectIdentifierSuggestionGenerator
    #   * work package ID =  {project identifier + dash + project-local sequence number ID} (e.g. "PROJ1-123")
    def suggest_identifier(name, mode: Setting[:work_packages_identifier])
      if mode == Setting::WorkPackageIdentifier::SEMANTIC
        exclude = ProjectIdentifiers::IdentifierAutofix::ProblematicIdentifiers.reserved_identifiers
        ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator
          .suggest_identifier(name, exclude:)
      else
        ProjectIdentifiers::ClassicIdentifierSuggestionGenerator.new.suggest_identifier(name)
      end
    end
  end

  def suggest_identifier(mode: Setting[:work_packages_identifier])
    self.class.suggest_identifier(name, mode:)
  end

  # Override the `validation_context` getter to include the `default_validation_context` when the
  # context is `:saving_custom_fields`. Our identifier-generation callbacks fire on `:create`, so
  # providing only a custom context would skip them, leaving identifier blank on new records.
  # Including the default context ensures `:create` callbacks run alongside `:saving_custom_fields`.
  def validation_context
    case Array(super)
    in [*, :saving_custom_fields, *] => context
      context | [default_validation_context]
    else
      super
    end
  end
end
