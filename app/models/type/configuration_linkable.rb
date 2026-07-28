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

# Reuse of a type's configuration aspects (PDF export, subject patterns) from a
# source type. Mode is derived from link presence: a link means Linked, its
# absence means Independent. This is the shared seam FND-101/102 extend with
# further aspects, and the deferred resolution/copy/cycle work builds on top of.
class Type
  module ConfigurationLinkable
    extend ActiveSupport::Concern

    prepended do
      has_many :configuration_links,
               class_name: "Type::ConfigurationLink",
               dependent: :destroy
      has_many :dependent_configuration_links,
               class_name: "Type::ConfigurationLink",
               foreign_key: :source_id,
               inverse_of: :source,
               dependent: :restrict_with_error

      # A variant defaults to Linked-to-parent for the aspects whose linked
      # behaviour is implemented; see DEFAULT_PARENT_LINK_ASPECTS.
      after_create :link_default_aspects_to_parent, if: :variant?
    end

    class_methods do
      # Four ways to resolve an aspect's link chain in SQL. Which one is correct depends on
      # what the rows you are resolving *are*:
      #
      #   rows are one known type id  → .effective_source_id_subquery
      #                                 .effective_excluded_elements_subquery
      #     Scalar subqueries, inlinable into a WHERE. Used by the instance readers.
      #
      #   rows are types              → .effective_configuration_lateral
      #     Correlates per row, which is exactly one walk per type. This is what
      #     Types::Scopes::WithEffectiveConfiguration selects.
      #
      #   rows are anything else      → .effective_configuration_join
      #     (work packages, projects_types, …) Resolves once per type in a derived table and
      #     hash-joins the result on.
      #
      # The last distinction is the one that bites. A correlated lateral re-executes the
      # recursive walk for every driving row and PostgreSQL will not memoize it — a recursive
      # CTE disqualifies the Memoize node — so joining 520k rows that span only 26 types costs
      # 520k walks (measured: 980ms, versus 148ms resolving per type). Reach for the lateral
      # only where the driving rows are types and that multiplication cannot happen.
      #
      # SQL for the single owning (terminal) type id of the aspect's link chain
      # starting at `type_id`. Recurses through type_configuration_links until a type
      # that isn't linked for the aspect (the owner). The `path` array is a cycle
      # guard tolerating rows that predate write-time cycle prevention (FND-133); a
      # pure cycle owns nothing and yields no row.
      #
      # Fully sanitized, so it can be inlined as a scalar subquery: it lets a query
      # resolve a linked type's effective owner without a separate round-trip.
      def effective_source_id_subquery(type_id, aspect)
        sanitize_sql_array([<<~SQL.squish, { type_id:, aspect: }])
          #{link_chain_cte(':type_id')}
          SELECT cl.node_id FROM link_chain cl
          WHERE #{terminal_node_condition}
          LIMIT 1
        SQL
      end

      # SQL for the elements excluded between `type_id` and the type owning the aspect:
      # the union of `excluded_elements` over every link traversed. Union is
      # order-independent, so it accumulates during the same upward walk as
      # .effective_source_id_subquery rather than needing a second, ordered pass.
      #
      # Yields one row per element rather than a single array, so it can be inlined
      # directly as `<key> <> ALL (<subquery>)`: that is empty-safe, where an array
      # scalar would need a COALESCE to stop a cycle's NULL from excluding everything.
      # A type that owns the aspect, or whose chain is a pure cycle, yields no rows and
      # therefore excludes nothing.
      def effective_excluded_elements_subquery(type_id, aspect)
        sanitize_sql_array([<<~SQL.squish, { type_id:, aspect: }])
          SELECT DISTINCT element
          FROM (
            #{link_chain_cte(':type_id')}
            SELECT cl.excluded FROM link_chain cl
            WHERE #{terminal_node_condition}
            LIMIT 1
          ) AS terminal, unnest(terminal.excluded) AS element
          WHERE element IS NOT NULL
        SQL
      end

      # Resolves the aspect's chain inline for whatever type id +type_id_expr+ yields at the
      # call site, as [join_sql, source_id_expr, excluded_elements_expr]. +type_id_expr+ must
      # name a column of a table joined before this fragment.
      #
      # Correlates per driving row, so use it only where those rows are types; otherwise reach
      # for .effective_configuration_join, which builds on this one. See the note above
      # .effective_source_id_subquery.
      #
      # The COALESCEs cover the two rows the lateral yields nothing for: a type owning the
      # aspect resolves to itself, and so does one whose chain is a pure cycle.
      def effective_configuration_lateral(type_id_expr, aspect, alias_name: nil)
        aspect = validated_configuration_aspect(aspect)
        alias_name ||= "effective_#{aspect}"

        join = sanitize_sql_array([<<~SQL.squish, { aspect: }])
          LEFT JOIN LATERAL (
            #{link_chain_cte(type_id_expr)}
            SELECT cl.node_id AS source_id, cl.excluded AS excluded
            FROM link_chain cl
            WHERE #{terminal_node_condition}
            LIMIT 1
          ) #{alias_name} ON TRUE
        SQL

        [join,
         "COALESCE(#{alias_name}.source_id, #{type_id_expr})",
         "COALESCE(#{alias_name}.excluded, '{}'::text[])"]
      end

      # [join_sql, source_id_expr, excluded_elements_expr] resolving the aspect once per type
      # and joining the result onto +type_id_expr+. The default choice for joining anything
      # that is not a type — see the note above .effective_source_id_subquery.
      #
      # +only_type_ids+ narrows the derived table when the caller already knows which types it
      # needs, so a single-type lookup costs one walk rather than one per type in the install.
      # Omit it to resolve every type.
      def effective_configuration_join(type_id_expr, aspect, only_type_ids: nil, alias_name: nil)
        aspect = validated_configuration_aspect(aspect)
        alias_name ||= "resolved_#{aspect}"
        lateral, source_id, excluded = effective_configuration_lateral("#{quoted_table_name}.id", aspect)
        scope = only_type_ids ? "WHERE #{quoted_table_name}.id IN (#{only_type_ids.join(', ')})" : ""

        join = <<~SQL.squish
          LEFT JOIN (
            SELECT #{quoted_table_name}.id AS type_id,
                   #{source_id} AS source_id,
                   #{excluded} AS excluded
            FROM #{quoted_table_name} #{lateral} #{scope}
          ) #{alias_name} ON #{alias_name}.type_id = #{type_id_expr}
        SQL

        [join,
         "COALESCE(#{alias_name}.source_id, #{type_id_expr})",
         "COALESCE(#{alias_name}.excluded, '{}'::text[])"]
      end

      # Aspects reach SQL as column aliases and lateral alias names, so an unknown one must
      # raise rather than be interpolated into an identifier.
      def validated_configuration_aspect(aspect)
        aspect.to_s.tap do |candidate|
          unless Type::ConfigurationLink::ASPECTS.include?(candidate)
            raise ArgumentError, "Unknown configuration aspect #{aspect.inspect}"
          end
        end
      end

      private

      # Walks type_configuration_links upwards from `seed_type_id` until a type that
      # isn't linked for :aspect (the owner), carrying two accumulators: `path` guards
      # against cycles in rows that predate write-time cycle prevention (FND-133), and
      # `excluded` unions each traversed link's excluded elements.
      #
      # `seed_type_id` is SQL, not a value: the subqueries above seed it from a bind,
      # while Types::Scopes::WithEffectiveConfiguration seeds it from the correlated
      # `types.id` of the row its LATERAL join is evaluated for. Interpolated rather than
      # bound because it is literal SQL; :aspect is sanitized by the caller.
      def link_chain_cte(seed_type_id)
        # Cast rather than trust the seed: an integer literal from a VALUES list would
        # otherwise clash with the bigint the recursive term yields.
        seed = "CAST(#{seed_type_id} AS bigint)"

        <<~SQL.squish
          WITH RECURSIVE link_chain(node_id, path, excluded) AS (
            SELECT #{seed}, ARRAY[#{seed}], '{}'::text[]
            UNION ALL
            SELECT l.source_id, cl.path || l.source_id, cl.excluded || l.excluded_elements
            FROM link_chain cl
            JOIN type_configuration_links l ON l.type_id = cl.node_id AND l.aspect = :aspect
            WHERE NOT l.source_id = ANY(cl.path)
          )
        SQL
      end

      def terminal_node_condition
        <<~SQL.squish
          NOT EXISTS (
            SELECT 1 FROM type_configuration_links l2
            WHERE l2.type_id = cl.node_id AND l2.aspect = :aspect
          )
        SQL
      end
    end

    def linked?(aspect)
      configuration_links.exists?(aspect:)
    end

    def source_for(aspect)
      configuration_links.find_by(aspect:)&.source
    end

    def link!(aspect, source:)
      configuration_links.find_or_initialize_by(aspect:).update!(source:)
    end

    # Resolves the link chain to the type that actually owns the aspect (Independent),
    # in a single recursive query (see .effective_source_id_subquery). Returns `self`
    # unchanged when this type owns the aspect, so callers keep object identity in the
    # common case and avoid a reload.
    #
    # Guarded by the type_variants feature flag: with the flag off, links are ignored
    # and every type resolves to its own stored configuration. A new record has no
    # persisted links, so it owns every aspect.
    def effective_source_for(aspect)
      preloaded = preloaded_effective_sources[aspect.to_s]
      return preloaded if preloaded

      terminal_id = effective_source_id(aspect)
      return self if terminal_id == id

      self.class.find(terminal_id)
    end

    # Called by Types::Scopes::WithEffectiveSource once per relation, so #effective_source_for
    # doesn't look the owning type up per record.
    def assign_effective_source(aspect, source)
      preloaded_effective_sources[aspect.to_s] = source
    end

    # Reloading re-selects the plain columns, dropping the aspect-suffixed ones that
    # #effective_source_id and #effective_excluded_elements read. The assigned sources have
    # to go with them, or they would answer from before the reload.
    def reload(...)
      @preloaded_effective_sources = nil

      super
    end

    # The id of the type owning `aspect`. This type's own id when it owns the aspect, when
    # the variants flag is off, and when the chain is a pure cycle — the three cases where
    # #effective_source_for hands back `self`.
    #
    # Reads the column .with_effective_configuration selected when the record came from
    # that scope, which is what keeps a collection from running the recursive walk once
    # per record. Note this resolves the id only: turning it into a Type is still a
    # per-record lookup.
    def effective_source_id(aspect)
      return id unless resolve_aspect_in_sql?

      preloaded = "effective_source_id_#{aspect}"
      return self[preloaded].to_i if has_attribute?(preloaded)

      terminal_id = self.class.connection.select_value(self.class.effective_source_id_subquery(id, aspect))
      terminal_id.blank? ? id : terminal_id.to_i
    end

    # The elements this type does not inherit for `aspect`: the union of
    # `excluded_elements` across every link between it and the type owning the aspect.
    # Element keys are aspect-specific — the aspect's reader interprets them (custom
    # fields use CustomField#attribute_name).
    #
    # Independent types exclude nothing, and so does every type while the variants flag
    # is off, matching #effective_source_for resolving to `self` in both cases.
    def effective_excluded_elements(aspect)
      return [] unless resolve_aspect_in_sql?

      preloaded = "effective_excluded_elements_#{aspect}"
      # Uniq only on this branch: the scope selects the raw accumulated array, where the
      # subquery below already applies DISTINCT. Excluding the same element at two levels
      # of the chain is legal, so both paths have to agree.
      return Array(self[preloaded]).uniq if has_attribute?(preloaded)

      self.class.connection.select_values(
        self.class.effective_excluded_elements_subquery(id, aspect)
      )
    end

    # Readers of linked aspects resolve through the link, so a plain `type.patterns`
    # is always the configuration in force. Resolving in the reader rather than behind
    # a separate opt-in method is deliberate: a caller can't silently read its own value
    # by forgetting to opt in — a slip a root type would mask, since it reads the same
    # either way.
    #
    # Writers stay untouched: assigning always writes this type's own row.
    def patterns
      source = linked_configuration_source(Type::ConfigurationLink::DEFAULTS)
      return super if source.nil?

      source.patterns
    end

    def description
      source = linked_configuration_source(Type::ConfigurationLink::DEFAULTS)
      return super if source.nil?

      source.description
    end

    def artefact_export_mode
      source = linked_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.artefact_export_mode
    end

    # Resolved here rather than on #pdf_export_templates so that the object handed out
    # always wraps the receiving type: it is a mutator as much as a reader, and
    # returning the source's would let a linked variant write the source's config.
    def export_templates_disabled
      source = linked_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_disabled
    end

    def export_templates_order
      source = linked_configuration_source(Type::ConfigurationLink::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_order
    end

    # Follows the reader-override pattern above, but yields this type's own groups
    # while a change is pending: the switch-to-Independent copy assigns groups and
    # reads them back to sync active custom fields while the link still exists
    # (CopyConfiguration::FormConfigurationService), and must see what it just set.
    def attribute_groups
      source = linked_configuration_source(Type::ConfigurationLink::FORM_CONFIGURATION)
      return super if source.nil? || attribute_groups_changed?

      without_excluded_elements(source.attribute_groups)
    end

    # custom_fields resolves through the form source. Beware of reader-driven mutation:
    # currently, the only one is Jira import's `custom_fields <<`, but it runs on
    # a FORM_CONFIGURATION-independent type, so it reaches super.
    def custom_fields
      source = linked_configuration_source(Type::ConfigurationLink::FORM_CONFIGURATION)
      return super if source.nil?

      excluded_ids = excluded_custom_field_ids(Type::ConfigurationLink::FORM_CONFIGURATION)
      return source.custom_fields if excluded_ids.empty?

      source.custom_fields.where.not(id: excluded_ids)
    end

    private

    def preloaded_effective_sources
      @preloaded_effective_sources ||= {}
    end

    # Applies the chain's exclusions to the owner's groups. A group left with no attributes
    # is dropped rather than rendered empty.
    #
    # Groups are duplicated before being narrowed: they are memoized on the owner as its
    # attribute_groups_objects, so narrowing them in place would change what the owning type
    # reads for itself.
    def without_excluded_elements(groups)
      excluded = effective_excluded_elements(Type::ConfigurationLink::FORM_CONFIGURATION)
      return groups if excluded.empty?

      groups.filter_map do |group|
        next retained_query_group(group, excluded) if group.group_type == :query

        remaining = group.attributes - excluded
        next if remaining.empty?
        next group if remaining.length == group.attributes.length

        group.dup.tap { |narrowed| narrowed.attributes = remaining }
      end
    end

    # A query group is a section holding a single query, stored under the element key
    # "query_<id>" (see Type::AttributeGroups#to_attribute_group_array), so excluding that key
    # drops the whole group. It cannot go through the narrowing above because
    # Type::QueryGroup#attributes is the query itself rather than a list of attribute keys.
    #
    # A group whose query no longer exists is left alone: there is no id to exclude it by, and
    # dropping it here would hide it from the form configuration that still has to repair it.
    def retained_query_group(group, excluded)
      return group if group.query.blank?

      group unless excluded.include?(group.query_attribute_name.to_s)
    end

    # Custom fields appear in an element list under CustomField#attribute_name, alongside
    # plain attribute keys like "assignee" that have no custom field to map to.
    def excluded_custom_field_ids(aspect)
      effective_excluded_elements(aspect).filter_map do |element|
        next unless CustomField.custom_field_attribute?(element)

        element.delete_prefix("custom_field_").to_i
      end
    end

    # The type an aspect is linked to, or nil when this type owns it. The nil is
    # what keeps the readers above from recursing: effective_source_for returns self
    # both for an unlinked aspect and while the variants flag is off.
    def linked_configuration_source(aspect)
      source = effective_source_for(aspect)

      source unless source == self
    end

    # True when a lookup should resolve `aspect` through the link chain in SQL
    # rather than reading this type's own rows: variants on and the type persisted.
    def resolve_aspect_in_sql?
      !new_record? && OpenProject::FeatureDecisions.type_variants_active?
    end

    # `aspect`'s owning type id as an inlinable subquery, for a lookup that filters
    # on type_id (`type_id IN (…)`): it resolves a linked type's effective source in
    # the same query instead of a preceding resolution round-trip.
    def effective_source_id_ref(aspect)
      Arel.sql("(#{self.class.effective_source_id_subquery(id, aspect)})")
    end

    def link_default_aspects_to_parent
      Type::ConfigurationLink::DEFAULT_PARENT_LINK_ASPECTS.each { |aspect| link!(aspect, source: parent) }
    end
  end
end
