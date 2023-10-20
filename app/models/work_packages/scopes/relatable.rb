#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

module WorkPackages::Scopes
  module Relatable
    extend ActiveSupport::Concern

    class_methods do
      # Returns all work packages which can become part of a new relation from or to the provided work package where the
      # new relation would receive the provided type (e.g. 'blocks').
      #
      # For most relation types, e.g. 'includes', the four following rules must be satisfied:
      # * Non circular: relations cannot form a circle, e.g. a -> b -> c -> a.
      # * Single relation: only one relation can be created between any two work packages. E.g. it is not possible to create
      #   two relations like this:
      #   * WP 1 ────follows────> WP 2
      #   * WP 1 ────includes────> WP 2
      #   The type of the relation is of no relevance for this constraint.
      # * Ancestor/descendant: relations cannot be drawn between ancestor and descendants. It is important to note though,
      #   that relations can be created between any two work packages within the same tree as long as they are not in a direct
      #   or transitive (e.g. parent of the parent or child of the child) ancestor/descendant relationship. So a relation between
      #   siblings is just as possible as one between aunt and nephew. Additionally, a transitive relationship which leaves the
      #   tree for any one hop, is exempt from that rule so it is possible to have:
      #                  WP parent ────┐
      #                    │         includes
      #                    │           │
      #                    │           v
      #                 hierarchy    other WP
      #                    │           │
      #                    │           │
      #                    v        includes
      #                  WP child <────┘
      # * No circles between trees: The ancestor/descendant chain is considered bidirectional when calculating relatability.
      #   This means that starting from the work package both the descendants as well as the ancestors are considered. That
      #   way, relations like
      #                  WP parent1 <────follows──── WP parent2
      #                    │                            │
      #                    │                            │
      #                 hierarchy                    hierarchy
      #                    │                            │
      #                    v                            v
      #                  WP child1 ────follows────> WP child2
      #   are prevented.
      #
      # For some of the relations, this has actual relevance (FOLLOWS, PRECEDES, PARENT because of scheduling) while for the
      # most, it is simply a question of semantics which is not manifested in code (all the other).
      #
      # For the sake of this scope, hierarchy relations (Relation::TYPE_PARENT and Relation::TYPE_CHILD) are also included
      # in the list of possible relation_types even though they are not stored in the same data structure. All
      # Relation::TYPE_* values can be provided even those that are not canonical, e.g. Relation::TYPE_PRECEDES.
      # The calculations for those relation types are then inverted and the canonical type is used, e.g. Relation::TYPE_FOLLOWS.
      #
      # There are a couple of exceptions and additions to the limitations outlined above for the following types:
      # * Relation::TYPE_RELATES: Since this is essentially undirected and does not carry a lot of semantic, the work packages
      #   are simply somehow related, such relations only follow the "single relation" rule (which includes their direct
      #   parent/children) and  none of the other.
      # * Relation::TYPE_PARENT: Since creating a new relationship will remove the old parent relationship, current ancestors
      #   (except the direct parent) are relatable to. Descendants however are not since that would create a circle.
      #   In addition to the existing hierarchy, the FOLLOWS relationships are taken into account. Predecessors and successors
      #   (FOLLOWS relationship) may also not be related to via a PARENT relation. However, parents and children of those
      #   predecessors/successors can be related to. But they still need to be considered in the code since they might be
      #   part of an almost completed circle which would be closed if a work package is added as a parent. E.g. in
      #                    WP4 <────follows──── WP3
      #                                          │
      #                                          │
      #                                       hierarchy
      #                                          │
      #                                          v
      #                                         WP2 <────follows──── WP1
      #   WP4 is not a valid parent candidate for WP1 since it would create the structure used as an example in
      #   "No circle for trees". However WP3 would be relatable to.
      #   Work packages related via follows/precedes to any descendant of a work package are exempt from being relatable right
      #   away as it would create a circle.
      # * Relation::TYPE_CHILD: The relation essentially follows the same rules, albeit inverted, as PARENT since it is
      #   the non canonical equivalent of it. Again, the parent relation of current children will be altered upon creating a new
      #   relation. Because of that, all descendants (as opposed to ancestors as is the case for PARENT) can be related to.
      #   The following in depth discussion focuses on the PARENT relation to walk through the special cases of the hierarchical
      #   relation. Whenever PARENT is mentioned, CHILD is also included.
      #
      # The implementation focuses on excluding candidates. It does so in two parts:
      #   * Excluding all work packages with which a direct relation already exist (with additions for PARENT relations).
      #   * Excluding work packages that are related transitively (following a path of direct relationships).
      #
      # The first is straightforward for all relation types except for PARENT relations. For that majority, whenever there is
      # a relation of any type except PARENT either to or from the work package queried for, it is excluded. For PARENT relations,
      # both the descendants of the queried for work package as well as the descendants of any directly related work packages are
      # excluded as well since creating a PARENT relationship to one such work package would result in a relation up or down the
      # hierarchy which violates the ancestor/descendant rule.
      #
      # The second exclusion of candidates is more complicated and also depends on the type of relation that is
      # queried for. It uses a CTE to recursively find all work packages with which a transitive relationship of interest based
      # on the rules outlined above exist.
      #
      # For most of the relation types, this includes work packages in the direction towards or away from the
      # work package to be related to the hierarchy (ancestors and descendants - not siblings and aunts).
      # Note that only one of the directions is of interest, which is the one opposite to the one that is queried for via the
      # type. This is to prevent a circle of relationships. For the 'related' type, only the ancestors and descendants are of
      # interest.
      #
      # For PARENT relationships both directions of FOLLOWS/PRECEDES need to be taken into account, and of course,
      # hierarchy relation are to be included as well. This prevents creating invalid relations in a structure like this:
      #
      #          WP4 <────follows──── WP3                                        WP6 <────follows──── WP7
      #                                │                                          │
      #                                │                                          │
      #                             hierarchy                                  hierarchy
      #                                │                                          │
      #                                v                                          v
      #                               WP2 <────follows────  WP1 <────follows──── WP5
      #
      # where creating a parent relation to both WP4 or WP7 would create a circle between trees.
      #
      # The necessity to follow both directions spans to the queried for work package as well as to its descendants.
      # However, once started from that origin, if the direction of the path is inverted all the work packages on the path
      # afterwards are valid targets and need not be followed up on:
      #
      #                               WP3 <────follows──── WP4     WP7 <────follows──── WP6
      #                                │                                                 │
      #                                │                                                 │
      #                             hierarchy                                         hierarchy
      #                                │                                                 │
      #                                v                                                 v
      #                               WP2 <────follows──────── WP1 <────────follows──── WP5
      #
      # In the example above, WP4 as well as WP7 (and for completeness sake WP3 as well as WP6) are valid relation targets,
      # and every work package related to those two would be as well.
      # It is also important to note, that existing ancestors are of no importance since this part of the structure will change.
      # Creating a parent relationship is destructive since there can only ever be one.
      #
      # The result is a blocklist which will include work packages that can not be related to. The list is not complete
      # as it will not include the work packages related by different relation types so those are added additionally. For the
      # PARENT relationship, work packages directly related to any of the descendants are added as well. Ancestors of predecessors
      # and successors, which needed to be followed are to be removed from the blocklist since they are valid targets.
      #
      # The CTE has the following columns:
      # * id - the id of the work packages currently related. This is the result of the CTE.
      # * from_(hierarchy/from_id/to_id) - booleans to prevent that the CTE returns back the path calculated in the previous
      #                                    iteration.
      # * includes_(from_relation/to_relation) - booleans about the direction (from_id -> to_id or to_id -> from_id) of the path
      #                                          (the relations followed).
      #                                          This is relevant for a queried for PARENT relation. In that case, relations need
      #                                          to be followed from the queried for work package (and its descendants) in both
      #                                          directions. But only the direction taken from that origin needs to be followed
      #                                          henceforth.
      # * includes_hierarchy - boolean indicating that the last relation taken was a hierarchy relation. For a queried for
      #                        PARENT relation, whenever that is the case, the work package is a valid relation target although
      #                        it appears in the CTE.
      #
      # The caller can can also provide a relation that is ignored for the calculation of which
      # work packages are relatable. This can be helpful in case an existing relation is updated
      # especially if the the direction is switched. Only a single relation can be provided and
      # that one has to either be from or to the work package queried for.
      def relatable(work_package, relation_type, ignored_relation: nil)
        relatable_ensure_single_relation(ignored_relation, work_package)

        return all if work_package.new_record?

        scope = case relation_type
                when Relation::TYPE_PARENT
                  not_having_potential_tree_relation_parent(work_package)
                when Relation::TYPE_CHILD
                  not_having_potential_tree_relation_child(work_package)
                else
                  where.not(id: directly_related(work_package, ignored_relation:))
                end

        scope = scope
                  .not_having_transitive_relation(work_package, relation_type, ignored_relation:)
                  .where.not(id: work_package.id)

        if Setting.cross_project_work_package_relations
          scope
        else
          scope.where(project: work_package.project)
        end
      end

      def not_having_transitive_relation(work_package, relation_type, ignored_relation:)
        if relation_type == Relation::TYPE_RELATES
          # Bypassing the recursive query in this case as only children and parent needs to be excluded.
          # Using this more complicated statement since
          # where.not(parent:id: work_package.id)
          # will lead to
          # "parent_id != 123" which excludes
          # work packages having parent_id NULL.
          where.not(id: where(id: work_package.parent_id).or(where(parent_id: work_package.id)).select(:id))
        else
          sql = <<~SQL.squish
            WITH
              RECURSIVE
              #{non_relatable_paths_sql(work_package, relation_type, ignored_relation:)}

              SELECT id
              FROM related
              WHERE #{blocklist_condition(relation_type)}
          SQL

          where("work_packages.id NOT IN (#{Arel.sql(sql)})")
        end
      end

      private

      def not_having_potential_tree_relation_parent(work_package)
        # On a parent relationship, explicitly remove the former parent (which might be the current one as well)
        # from the list of work packages one can relate to. This is not strictly necessary since it would not
        # cause faulty relationships but doing it removes the parent from places where it should not show up,
        # e.g. in an auto completer.
        scope = if work_package.parent_id_was
                  where.not(id: work_package.parent_id_was)
                else
                  all
                end

        scope
          .where.not(id: directly_related(descendant_or_self_ids_of(work_package)))
          .where.not(id: descendant_or_self_ids_of(directly_related(descendant_or_self_ids_of(work_package))))
      end

      def not_having_potential_tree_relation_child(work_package)
        # On a child relationship, explicitly remove the current children from the list of work packages
        # one can relate to. This is not strictly necessary since it would not cause faulty relationships
        # but doing it removes the children from places where it should not show up,
        # e.g. in an auto completer.
        where.not(id: directly_related(ancestor_or_self_ids_of(work_package)))
          .where.not(id: ancestor_or_self_ids_of(directly_related(ancestor_or_self_ids_of(work_package))))
          .where.not(id: where(parent_id: work_package.id).select(:id))
      end

      def non_relatable_paths_sql(work_package, relation_type, ignored_relation: nil)
        <<~SQL.squish
          related (id,
                   from_hierarchy,
                   from_from_id,
                   from_to_id,
                   includes_from_relation,
                   includes_to_relation,
                   includes_hierarchy) AS (

              #{non_recursive_relatable_values(work_package, relation_type)}

            UNION

              SELECT
                relations.id,
                relations.from_hierarchy,
                relations.from_from_id,
                relations.from_to_id,
                relations.includes_from_relation,
                relations.includes_to_relation,
                relations.includes_hierarchy
              FROM
                related
              JOIN LATERAL (
                #{joined_existing_connections(relation_type, ignored_relation:)}
              ) relations ON 1 = 1
          )
        SQL
      end

      def non_recursive_relatable_values(work_package, relation_type)
        hierarchy_condition = case relation_type
                              when Relation::TYPE_PARENT
                                "work_package_hierarchies.ancestor_id = :id"
                              when Relation::TYPE_CHILD
                                "work_package_hierarchies.descendant_id = :id"
                              else
                                "(work_package_hierarchies.ancestor_id = :id OR work_package_hierarchies.descendant_id = :id)"
                              end

        sql = <<~SQL.squish
          SELECT
            CASE
              WHEN work_package_hierarchies.ancestor_id = :id
              THEN work_package_hierarchies.descendant_id
              ELSE work_package_hierarchies.ancestor_id
              END id,
            true from_hierarchy,
            false from_from_id,
            false from_to_id,
            false includes_from_relation,
            false includes_to_relation,
            false includes_hierarchy
          FROM
            work_package_hierarchies
          WHERE
            #{hierarchy_condition}
        SQL

        ::OpenProject::SqlSanitization
          .sanitize sql,
                    id: work_package.id
      end

      def joined_existing_connections(relation_type, ignored_relation:)
        unions = [existing_hierarchy_lateral(with_descendants: relation_type != Relation::TYPE_CHILD)]

        case relation_type
        when Relation::TYPE_PARENT, Relation::TYPE_CHILD
          unions << existing_relation_of_type_lateral(Relation::TYPE_FOLLOWS, limit_direction: true)
          unions << existing_relation_of_type_lateral(Relation::TYPE_PRECEDES, limit_direction: true)
        else
          unions << existing_relation_of_type_lateral(relation_type, ignored_relation:)
        end

        unions.join(' UNION ')
      end

      # rubocop:disable Metrics/PerceivedComplexity
      def existing_relation_of_type_lateral(relation_type, ignored_relation: nil, limit_direction: false)
        canonical_type = Relation.canonical_type(relation_type)

        is_canonical = canonical_type == relation_type
        true_on_canonical = is_canonical ? 'TRUE' : 'FALSE'
        false_on_canonical = is_canonical ? 'FALSE' : 'TRUE'

        direction1, direction2 = if is_canonical
                                   %w[from_id to_id]
                                 else
                                   %w[to_id from_id]
                                 end

        direction_limit = if limit_direction && is_canonical
                            'related.includes_to_relation'
                          elsif limit_direction
                            'related.includes_from_relation'
                          end

        sql = <<~SQL.squish
          SELECT
            #{direction1} id,
            false from_hierarchy,
            #{true_on_canonical} from_from_id,
            #{false_on_canonical} from_to_id,
            related.includes_from_relation OR #{true_on_canonical} includes_from_relation,
            related.includes_to_relation OR #{false_on_canonical} includes_to_relation,
            false includes_hierarchy
          FROM
            relations
          WHERE (relations.#{direction2} = related.id AND relations.relation_type = :relation_type)
            AND NOT related.from_#{direction2}
            #{direction_limit ? "AND NOT #{direction_limit}" : ''}
            #{ignored_relation&.id ? " AND NOT relations.id = #{ignored_relation.id}" : ''}
        SQL

        ::OpenProject::SqlSanitization
          .sanitize sql,
                    relation_type: canonical_type
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def existing_hierarchy_lateral(with_descendants: true)
        <<~SQL.squish
          SELECT
            CASE
              WHEN work_package_hierarchies.ancestor_id = related.id
              THEN work_package_hierarchies.descendant_id
              ELSE work_package_hierarchies.ancestor_id
              END id,
            true from_hierarchy,
            false from_from_id,
            false from_to_id,
            related.includes_from_relation,
            related.includes_to_relation,
            #{with_descendants ? 'work_package_hierarchies.descendant_id = related.id' : 'work_package_hierarchies.ancestor_id = related.id'} includes_hierarchy
          FROM
            work_package_hierarchies
          WHERE
            related.from_hierarchy = false AND
            (work_package_hierarchies.descendant_id = related.id OR work_package_hierarchies.ancestor_id = related.id)
            AND (work_package_hierarchies.generations != 0)
        SQL
      end

      def blocklist_condition(relation_type)
        case relation_type
        when Relation::TYPE_PARENT, Relation::TYPE_CHILD
          "NOT includes_hierarchy"
        else
          '1 = 1'
        end
      end

      def descendant_or_self_ids_of(work_packages)
        WorkPackageHierarchy
          .where(ancestor_id: work_packages)
          .select(:descendant_id)
      end

      def ancestor_or_self_ids_of(work_packages)
        WorkPackageHierarchy
          .where(descendant_id: work_packages)
          .select(:ancestor_id)
      end

      def relatable_ensure_single_relation(ignored_relation, work_package)
        if ignored_relation && (!ignored_relation.is_a?(Relation) ||
          (ignored_relation.from_id != work_package.id && ignored_relation.to_id != work_package.id))
          raise ArgumentError, 'only a single relation with from_id or to_id pointing ' \
                               'to the work package for which relatable is queried for is supported'
        end
      end
    end
  end
end
