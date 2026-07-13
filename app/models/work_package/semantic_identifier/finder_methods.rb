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

# Extends ActiveRecord finder methods to support semantic work package
# identifiers (e.g. "PROJ-42") in addition to numeric IDs.
#
# - find("PROJ-42") resolves transparently
# - find_by(id:)/find_by!(id:) raise UnsupportedLookup for semantic strings
# - find_by_display_id("PROJ-42") is the explicit nil-on-miss resolver
# - exists?("PROJ-42") resolves transparently
#
# The asymmetry between find (transparent) and find_by (guarded) is deliberate:
# controllers and URL-driven callers already pass user input into find, and
# losing semantic resolution there would break the feature. find_by on the other
# hand reduces to a raw SQL WHERE id = ? that cannot consult the alias table,
# so silently matching nothing would be a worse bug than raising.
#
# Convention: use find_by_display_id only when the input could legitimately be
# either numeric or semantic (controllers, view components fed from URL params,
# macro resolvers). Low-level code (queries, filters, services) should stick to
# find_by(id:) with primary keys.
#
# Included into WorkPackage class methods and extended into every
# ActiveRecord::Relation via WorkPackage::SemanticIdentifier.
module WorkPackage::SemanticIdentifier::FinderMethods
  def find(*args)
    if args.length == 1 && !args.first.is_a?(Array)
      return semantic_id?(args.first) ? find_by_display_id!(args.first) : super
    end

    ids = args.first.is_a?(Array) ? args.first : args
    if ids.any? { semantic_id?(it) }
      raise WorkPackage::SemanticIdentifier::UnsupportedLookup,
            "Semantic identifiers in multi-argument find are not supported. " \
            "Use primary keys for multi-argument lookup, or resolve each identifier " \
            "individually via find_by_display_id! (raises) or find_by_display_id (nil on miss)."
    end

    super
  end

  # Guard find_by against semantic identifiers passed via `id:` or `identifier:`.
  # Developers should use find("PROJ-42") or find_by_display_id("PROJ-42") instead.
  def find_by(*args)
    reject_semantic_id_in_find_by!(args)
    super
  end

  def find_by!(*args)
    reject_semantic_id_in_find_by!(args)
    super
  end

  def exists?(conditions = :none)
    return super unless semantic_id?(conditions)

    exists_by_semantic_identifier?(conditions)
  end

  # Resolves any display-facing identifier to a WorkPackage.
  #   - Numeric string ("12345")    → find by primary key
  #   - Semantic string ("PROJ-42") → lookup via identifier column and alias table
  #
  # Returns nil on miss.
  def find_by_display_id(identifier)
    if semantic_id?(identifier)
      find_by_semantic_identifier(identifier)
    else
      where(id: identifier).take # rubocop:disable Rails/FindBy -- avoid find_by, it would rerun semantic_id?
    end
  end

  # Same as find_by_display_id but raises ActiveRecord::RecordNotFound on miss.
  def find_by_display_id!(identifier)
    find_by_display_id(identifier) ||
      raise(ActiveRecord::RecordNotFound.new(
              "Couldn't find WorkPackage with identifier=#{identifier}", "WorkPackage", "identifier", identifier
            ))
  end

  # Plural counterpart to find_by_display_id: returns a chainable relation that
  # matches any work package whose primary key, current identifier, or
  # historical alias matches one of the supplied display ids. Numeric and
  # semantic strings may be freely mixed; unknown values produce no match
  # rather than poisoning the rest of the set.
  #
  # @param values [String, Integer, Array<String, Integer>] one or more
  #   display ids. Pass scalars (`where_display_id_in("PROJ-1")`), varargs
  #   (`where_display_id_in("PROJ-1", "PROJ-2")`), or a pre-built array
  #   (`where_display_id_in(ids)`) interchangeably.
  def where_display_id_in(*values)
    values = values.flatten(1).compact_blank.map(&:to_s)
    return none if values.empty?

    semantic, numeric = values.partition { semantic_id?(it) }

    scope = where(id: numeric.map(&:to_i))
    scope = scope.or(scope_for_semantic_identifier(semantic)) if semantic.any?
    scope
  end

  private

  def reject_semantic_id_in_find_by!(args)
    return unless args.length == 1 && args.first.is_a?(Hash)

    pair = id_or_identifier_pair(args.first)
    return unless pair

    key, value = pair
    offending = first_semantic_value(value)
    return unless offending

    raise WorkPackage::SemanticIdentifier::UnsupportedLookup,
          "find_by(#{key}: #{value.inspect}) does not support semantic identifiers " \
          "because it cannot resolve aliases or match across identifier history. " \
          "Use find(#{offending.inspect}) or find_by_display_id(#{offending.inspect}) instead."
  end

  def id_or_identifier_pair(hash)
    (hash.assoc(:id) || hash.assoc("id")) ||
      (hash.assoc(:identifier) || hash.assoc("identifier"))
  end

  def first_semantic_value(value)
    if value.is_a?(Array)
      value.detect { semantic_id?(it) }
    elsif semantic_id?(value)
      value
    end
  end

  def semantic_id?(value)
    WorkPackage::SemanticIdentifier.semantic_id?(value)
  end

  def find_by_semantic_identifier(identifier)
    scope_for_semantic_identifier(identifier).first
  end

  def exists_by_semantic_identifier?(identifier)
    scope_for_semantic_identifier(identifier).exists?
  end

  # Builds a scope that matches work packages by semantic identifier, considering
  # both the current identifier column and the alias table for historical identifiers.
  #
  # Generates:
  #
  #   SELECT "work_packages".* FROM "work_packages"
  #   WHERE ("work_packages"."identifier" = 'PROJ-42'
  #      OR EXISTS (
  #        SELECT 1 FROM "work_package_semantic_aliases"
  #        WHERE "work_package_semantic_aliases"."work_package_id" = "work_packages"."id"
  #          AND "work_package_semantic_aliases"."identifier" = 'PROJ-42'
  #      ))
  def scope_for_semantic_identifier(identifier)
    where(identifier:).or(where(semantic_alias_exists(identifier)))
  end

  # Correlated EXISTS subquery that matches work packages having a
  # semantic alias row with the given identifier.
  def semantic_alias_exists(identifier)
    alias_table = WorkPackageSemanticAlias.arel_table

    WorkPackageSemanticAlias
      .where(alias_table[:work_package_id].eq(arel_table[:id]))
      .where(identifier:)
      .arel
      .exists
  end
end
