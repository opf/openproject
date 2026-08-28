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

# Reuse of a variant's configuration aspects from a source variant. Each aspect keeps a
# `<aspect>_source_id` pointing at the variant it borrows from, and a
# `<aspect>_excluded_elements` array naming what it drops from what it borrows. A NULL
# source means the variant owns the aspect (Independent); a source means Linked.
#
# Chains may be any depth, so resolution walks them recursively.
class TypeVariant
  module ConfigurationLinkable
    extend ActiveSupport::Concern

    # Custom fields appear in an aspect's element list under CustomField#attribute_name.
    # Mirrors the prefix that method builds.
    CUSTOM_FIELD_ELEMENT_PREFIX = "custom_field_"

    prepended do
      TypeVariant::ASPECTS.each do |aspect|
        belongs_to :"#{aspect}_source", class_name: "TypeVariant", optional: true
      end

      validate :sources_would_not_create_a_cycle
      validate :sources_are_available_to_this_variant
      before_destroy :ensure_nothing_links_here
    end

    class_methods do
      # Three ways to resolve an aspect's chain in SQL. Which one is correct depends on what
      # the rows you are resolving *are*:
      #
      #   rows are one known variant id → .effective_source_id_subquery
      #                                   .effective_excluded_elements_subquery
      #     Scalar subqueries, inlinable into a WHERE. Used by the instance readers.
      #
      #   rows are variants             → .effective_configuration_lateral
      #     Correlates per row, which is exactly one walk per variant.
      #
      #   rows are anything else        → .effective_configuration_join
      #     (work packages, project_types, …) Resolves once per variant in a derived table
      #     and hash-joins the result on.
      #
      # The last distinction is the one that bites. A correlated lateral re-executes the
      # recursive walk for every driving row and PostgreSQL will not memoize it — a recursive
      # CTE disqualifies the Memoize node — so joining 520k rows that span only 26 variants
      # costs 520k walks (measured: 980ms, versus 148ms resolving per variant). Reach for the
      # lateral only where the driving rows are variants and that multiplication cannot happen.
      #
      # SQL for the single owning (terminal) variant id of the aspect's chain starting at
      # `variant_id`. The `path` array is a cycle guard tolerating rows that predate write-time
      # cycle prevention; a pure cycle owns nothing and yields no row.
      def effective_source_id_subquery(variant_id, aspect)
        aspect = validated_configuration_aspect(aspect)

        sanitize_sql_array([<<~SQL.squish, { variant_id: }])
          #{link_chain_cte(':variant_id', aspect)}
          SELECT cl.node_id FROM link_chain cl
          WHERE #{terminal_node_condition(aspect)}
          LIMIT 1
        SQL
      end

      # SQL for the elements excluded between `variant_id` and the variant owning the aspect:
      # the union of `<aspect>_excluded_elements` over every hop traversed. Union is
      # order-independent, so it accumulates during the same upward walk as
      # .effective_source_id_subquery rather than needing a second, ordered pass.
      #
      # Yields one row per element rather than a single array, so it can be inlined directly
      # as `<key> <> ALL (<subquery>)`: that is empty-safe, where an array scalar would need a
      # COALESCE to stop a cycle's NULL from excluding everything.
      def effective_excluded_elements_subquery(variant_id, aspect)
        aspect = validated_configuration_aspect(aspect)

        sanitize_sql_array([<<~SQL.squish, { variant_id: }])
          SELECT DISTINCT element
          FROM (
            #{link_chain_cte(':variant_id', aspect)}
            SELECT cl.excluded FROM link_chain cl
            WHERE #{terminal_node_condition(aspect)}
            LIMIT 1
          ) AS terminal, unnest(terminal.excluded) AS element
          WHERE element IS NOT NULL
        SQL
      end

      # Resolves the aspect's chain inline for whatever variant id +variant_id_expr+ yields at
      # the call site, as [join_sql, source_id_expr, excluded_elements_expr]. +variant_id_expr+
      # must name a column of a table joined before this fragment.
      #
      # Correlates per driving row, so use it only where those rows are variants; otherwise
      # reach for .effective_configuration_join. See the note above.
      #
      # The COALESCEs cover the two rows the lateral yields nothing for: a variant owning the
      # aspect resolves to itself, and so does one whose chain is a pure cycle.
      def effective_configuration_lateral(variant_id_expr, aspect, alias_name: nil)
        aspect = validated_configuration_aspect(aspect)
        alias_name ||= "effective_#{aspect}"

        join = <<~SQL.squish
          LEFT JOIN LATERAL (
            #{link_chain_cte(variant_id_expr, aspect)}
            SELECT cl.node_id AS source_id, cl.excluded AS excluded
            FROM link_chain cl
            WHERE #{terminal_node_condition(aspect)}
            LIMIT 1
          ) #{alias_name} ON TRUE
        SQL

        [join,
         "COALESCE(#{alias_name}.source_id, #{variant_id_expr})",
         "COALESCE(#{alias_name}.excluded, '{}'::text[])"]
      end

      # [join_sql, source_id_expr, excluded_elements_expr] resolving the aspect once per
      # variant and joining the result onto +variant_id_expr+. The default choice for joining
      # anything that is not a variant — see the note above.
      #
      # +only_variant_ids+ narrows the derived table when the caller already knows which
      # variants it needs, so a single lookup costs one walk rather than one per variant in
      # the install. Omit it to resolve every variant.
      def effective_configuration_join(variant_id_expr, aspect, only_variant_ids: nil, alias_name: nil)
        aspect = validated_configuration_aspect(aspect)
        alias_name ||= "resolved_#{aspect}"
        lateral, source_id, excluded = effective_configuration_lateral("#{quoted_table_name}.id", aspect)
        scope = only_variant_ids ? "WHERE #{quoted_table_name}.id IN (#{only_variant_ids.join(', ')})" : ""

        join = <<~SQL.squish
          LEFT JOIN (
            SELECT #{quoted_table_name}.id AS variant_id,
                   #{source_id} AS source_id,
                   #{excluded} AS excluded
            FROM #{quoted_table_name} #{lateral} #{scope}
          ) #{alias_name} ON #{alias_name}.variant_id = #{variant_id_expr}
        SQL

        [join,
         "COALESCE(#{alias_name}.source_id, #{variant_id_expr})",
         "COALESCE(#{alias_name}.excluded, '{}'::text[])"]
      end

      # Condition keeping only custom fields an aspect's chain does not exclude. Custom fields
      # are excluded under CustomField#attribute_name, so the id is keyed back into that form
      # rather than compared numerically.
      #
      # +excluded_expr+ may be either an array expression (as the resolution builders above
      # return) or a subquery yielding one element per row (as
      # .effective_excluded_elements_subquery returns). `<> ALL` over an empty array or an
      # empty row set is TRUE either way, so callers never have to branch on "excludes
      # nothing".
      def excluded_custom_field_condition(custom_field_id_expr, excluded_expr)
        "('#{CUSTOM_FIELD_ELEMENT_PREFIX}' || #{custom_field_id_expr}) <> ALL (#{excluded_expr})"
      end

      # An aspect names columns, so it reaches SQL as an identifier rather than a bind. Every
      # interpolation below goes through here, and an unknown aspect raises rather than being
      # spliced in.
      # For the column-name interpolations that only exist on an excludable aspect. Load-bearing
      # for injection safety in exactly the same way as .validated_configuration_aspect.
      def validated_excludable_aspect(aspect)
        candidate = aspect.to_s
        unless TypeVariant::EXCLUDABLE_ASPECTS.include?(candidate)
          raise ArgumentError, "Configuration aspect #{aspect.inspect} has no exclusions"
        end

        candidate
      end

      def validated_configuration_aspect(aspect)
        aspect.to_s.tap do |candidate|
          raise ArgumentError, "Unknown configuration aspect #{aspect.inspect}" unless TypeVariant::ASPECTS.include?(candidate)
        end
      end

      private

      # Walks `<aspect>_source_id` upwards from `seed_variant_id` until a variant that owns the
      # aspect, carrying two accumulators: `path` guards against cycles in rows that predate
      # write-time cycle prevention, and `excluded` unions each traversed variant's excluded
      # elements.
      #
      # `seed_variant_id` is SQL, not a value: the subqueries above seed it from a bind, while
      # the lateral seeds it from the correlated `type_variants.id` of the row it is evaluated
      # for. `aspect` is an identifier already validated by the caller.
      def link_chain_cte(seed_variant_id, aspect)
        # Cast rather than trust the seed: an integer literal from a VALUES list would
        # otherwise clash with the bigint the recursive term yields.
        seed = "CAST(#{seed_variant_id} AS bigint)"
        # An aspect with nothing to narrow has no exclusions column, so the chain carries an
        # empty array through and every reader of it answers "nothing excluded".
        accumulated = if TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)
                        "cl.excluded || v.#{aspect}_excluded_elements"
                      else
                        "cl.excluded"
                      end

        <<~SQL.squish
          WITH RECURSIVE link_chain(node_id, path, excluded) AS (
            SELECT #{seed}, ARRAY[#{seed}], '{}'::text[]
            UNION ALL
            SELECT v.#{aspect}_source_id,
                   cl.path || v.#{aspect}_source_id,
                   #{accumulated}
            FROM link_chain cl
            JOIN type_variants v ON v.id = cl.node_id
            WHERE v.#{aspect}_source_id IS NOT NULL
              AND NOT v.#{aspect}_source_id = ANY(cl.path)
          )
        SQL
      end

      def terminal_node_condition(aspect)
        <<~SQL.squish
          NOT EXISTS (
            SELECT 1 FROM type_variants owner_check
            WHERE owner_check.id = cl.node_id
              AND owner_check.#{aspect}_source_id IS NOT NULL
          )
        SQL
      end
    end

    def linked?(aspect)
      source_id_for(aspect).present?
    end

    def source_for(aspect)
      public_send(:"#{self.class.validated_configuration_aspect(aspect)}_source")
    end

    def link!(aspect, source:)
      update!("#{self.class.validated_configuration_aspect(aspect)}_source": source)
    end

    def source_id_for(aspect)
      self[:"#{self.class.validated_configuration_aspect(aspect)}_source_id"]
    end

    # Resolves the chain to the variant that actually owns the aspect (Independent), in a
    # single recursive query. Returns `self` unchanged when this variant owns the aspect, so
    # callers keep object identity in the common case and avoid a reload.
    def effective_source_for(aspect)
      preloaded = preloaded_effective_sources[aspect.to_s]
      return preloaded if preloaded

      terminal_id = effective_source_id(aspect)
      return self if terminal_id == id

      self.class.find(terminal_id)
    end

    # Called by TypeVariants::Scopes::WithEffectiveSource once per relation, so
    # #effective_source_for doesn't look the owning variant up per record.
    def assign_effective_source(aspect, source)
      preloaded_effective_sources[aspect.to_s] = source
    end

    # Reloading re-selects the plain columns, dropping the aspect-suffixed ones that
    # #effective_source_id and #effective_excluded_elements read. The assigned sources have to
    # go with them, or they would answer from before the reload.
    def reload(...)
      @preloaded_effective_sources = nil

      super
    end

    # The id of the variant owning `aspect`. This variant's own id when it owns the aspect,
    # when the variants flag is off, and when the chain is a pure cycle — the three cases
    # where #effective_source_for hands back `self`.
    #
    # Reads the column .with_effective_configuration selected when the record came from that
    # scope, which is what keeps a collection from running the recursive walk once per record.
    def effective_source_id(aspect)
      return id unless resolve_aspect_in_sql?

      preloaded = "effective_source_id_#{aspect}"
      return self[preloaded].to_i if has_attribute?(preloaded)

      terminal_id = self.class.connection.select_value(self.class.effective_source_id_subquery(id, aspect))
      terminal_id.blank? ? id : terminal_id.to_i
    end

    # The elements this variant does not inherit for `aspect`: the union of excluded elements
    # across every hop between it and the variant owning the aspect. Element keys are
    # aspect-specific — the aspect's reader interprets them (custom fields use
    # CustomField#attribute_name).
    def effective_excluded_elements(aspect)
      return [] unless resolve_aspect_in_sql?
      return [] unless TypeVariant::EXCLUDABLE_ASPECTS.include?(aspect)

      preloaded = "effective_excluded_elements_#{aspect}"
      # Uniq only on this branch: the scope selects the raw accumulated array, where the
      # subquery below already applies DISTINCT. Excluding the same element at two levels of
      # the chain is legal, so both paths have to agree.
      return Array(self[preloaded]).uniq if has_attribute?(preloaded)

      self.class.connection.select_values(
        self.class.effective_excluded_elements_subquery(id, aspect)
      )
    end

    # Readers of linked aspects resolve through the source, so a plain `variant.patterns` is
    # always the configuration in force. Resolving in the reader rather than behind a separate
    # opt-in method is deliberate: a caller can't silently read its own value by forgetting to
    # opt in — a slip an owning variant would mask, since it reads the same either way.
    #
    # Writers stay untouched: assigning always writes this variant's own row.
    def patterns
      source = linked_configuration_source(TypeVariant::DEFAULTS)
      return super if source.nil?

      source.patterns
    end

    def default_work_package_description
      source = linked_configuration_source(TypeVariant::DEFAULTS)
      return super if source.nil?

      source.default_work_package_description
    end

    def artefact_export_mode
      source = linked_configuration_source(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.artefact_export_mode
    end

    # Resolved here rather than on #pdf_export_templates so that the object handed out always
    # wraps the receiving variant: it is a mutator as much as a reader, and returning the
    # source's would let a linked variant write the source's config.
    def export_templates_disabled
      source = linked_configuration_source(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_disabled
    end

    def export_templates_order
      source = linked_configuration_source(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_order
    end

    def export_templates_settings
      source = linked_configuration_source(TypeVariant::PDF_EXPORT)
      return super if source.nil?

      source.export_templates_settings
    end

    # Follows the reader-override pattern above, but yields this variant's own groups while a
    # change is pending: the switch-to-Independent copy assigns groups and reads them back to
    # sync active custom fields while the link still exists
    # (CopyConfiguration::FormConfigurationService), and must see what it just set.
    def attribute_groups
      source = linked_configuration_source(TypeVariant::FORM_CONFIGURATION)
      return super if source.nil? || attribute_groups_changed?

      without_excluded_elements(source.attribute_groups)
    end

    # custom_fields resolves through the form source. Beware of reader-driven mutation:
    # currently, the only one is Jira import's `custom_fields <<`, but it runs on a
    # FORM_CONFIGURATION-independent variant, so it reaches super.
    def custom_fields
      source = linked_configuration_source(TypeVariant::FORM_CONFIGURATION)
      return super if source.nil?

      excluded_ids = excluded_custom_field_ids(TypeVariant::FORM_CONFIGURATION)
      return source.custom_fields if excluded_ids.empty?

      source.custom_fields.where.not(id: excluded_ids)
    end

    # The ids of the custom fields this variant does not inherit for `aspect`. An element list
    # can also carry plain attribute keys ("assignee") and query groups ("query_7"), which
    # have no custom field to map to and are dropped here.
    def excluded_custom_field_ids(aspect)
      effective_excluded_elements(aspect).filter_map do |element|
        next unless CustomField.custom_field_attribute?(element)

        element.delete_prefix(CUSTOM_FIELD_ELEMENT_PREFIX).to_i
      end
    end

    private

    def preloaded_effective_sources
      @preloaded_effective_sources ||= {}
    end

    # Rejects a source whose own chain already reaches this variant, so each aspect's source
    # graph stays acyclic. A self-link is the degenerate 1-cycle and is caught here too.
    def sources_would_not_create_a_cycle
      TypeVariant::ASPECTS.each do |aspect|
        source_id = source_id_for(aspect)
        next if source_id.blank?

        errors.add(:"#{aspect}_source_id", :would_create_cycle) if reaches_self?(source_id, aspect)
      end
    end

    # A rule about the variant, not about who is editing it: an administrator sees every
    # project's variants, and linking one project's configuration into another's would tie the
    # two together.
    def sources_are_available_to_this_variant
      TypeVariant::ASPECTS.each do |aspect|
        source = public_send(:"#{aspect}_source")
        next if source.nil? || source.project_id.nil? || source.project_id == project_id

        errors.add(:"#{aspect}_source_id", :must_be_available_to_the_variant)
      end
    end

    # The `<aspect>_source_id` foreign keys are ON DELETE RESTRICT, so a variant others borrow
    # configuration from cannot be deleted. Stopping here rather than at the database turns an
    # InvalidForeignKey into a message that names what has to be unlinked first.
    def ensure_nothing_links_here
      borrowers = self.class.where(links_to_self).distinct
      return if borrowers.empty?

      errors.add(:base, :borrowed_by_variants, names: borrowers.map(&:composite_name).to_sentence)
      throw :abort
    end

    def links_to_self
      TypeVariant::ASPECTS
        .map { |aspect| self.class.arel_table[:"#{aspect}_source_id"].eq(id) }
        .reduce(:or)
    end

    def reaches_self?(source_id, aspect)
      # `seen` tolerates cyclic rows created before this validation existed: it lets the walk
      # terminate instead of hanging on such data.
      node_id = source_id
      seen = Set.new

      while node_id && seen.add?(node_id)
        return true if node_id == id

        node_id = self.class.where(id: node_id).pick(:"#{aspect}_source_id")
      end

      false
    end

    # Applies the chain's exclusions to the owner's groups. A group left with no attributes is
    # dropped rather than rendered empty.
    #
    # Groups are duplicated before being narrowed: they are memoized on the owner as its
    # attribute_groups_objects, so narrowing them in place would change what the owning
    # variant reads for itself.
    def without_excluded_elements(groups)
      excluded = effective_excluded_elements(TypeVariant::FORM_CONFIGURATION)
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

    # The variant an aspect is linked to, or nil when this variant owns it. The nil is what
    # keeps the readers above from recursing: effective_source_for returns self both for an
    # unlinked aspect and while the variants flag is off.
    def linked_configuration_source(aspect)
      source = effective_source_for(aspect)

      source unless source == self
    end

    # True when a lookup should resolve `aspect` through the chain in SQL rather than reading
    # this variant's own columns. Only an unsaved variant is exempt: it has no id to seed the
    # chain with, and nothing can be linked to it yet.
    #
    # Deliberately not gated on the type_variants feature. Every type owns a base variant
    # either way, and an unlinked variant resolves to itself, so resolving unconditionally is
    # what keeps reads identical whether the feature is on or off.
    def resolve_aspect_in_sql?
      !new_record?
    end

    # `aspect`'s owning variant id as an inlinable subquery, for a lookup that filters on
    # type_variant_id (`type_variant_id IN (…)`): it resolves a linked variant's effective
    # source in the same query instead of a preceding resolution round-trip.
    def effective_source_id_ref(aspect)
      Arel.sql("(#{self.class.effective_source_id_subquery(id, aspect)})")
    end
  end
end
