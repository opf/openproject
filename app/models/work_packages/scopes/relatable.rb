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
      # For the sake of this scope, the parent relation (Relation::TYPE_PARENT) is also included in the list of relation_types
      # even though it is not stored in the same data structure. All Relation::TYPE_* values can be provided even those that
      # are not canonical, e.g. Relation::TYPE_PRECEDES. The calculation for those relation types are then inverted and the
      # canonical type is used, e.g. Relation::TYPE_FOLLOWS.
      #
      # There are a couple of exceptions and additions to the limitations outlined above for the following types:
      # * Relation::TYPE_RELATES: Since this is essentially undirected and does not carry a lot of semantic, the work packages
      #   are simply somehow related, such relations do not follow the "non circular" nor the "ancestor/descendant" rule.
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
      #
      # The implementation focuses on excluding candidates. It does so in two parts:
      #   * Excluding all work packages with which a direct relation already exist.
      #   * Excluding work packages that are related transitively (following a path of direct relationships).
      #
      # The first is straightforward. The second is more complicated and also depends on the type of relation that is
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
      # * origin - boolean to indicate whether the work package is the queried for work package or its ancestor/descendant
      #            (only descendant for PARENT). Such a work package is never a valid target.
      # * includes_(from_relation/to_relation) - booleans about the direction (from_id -> to_id or to_id -> from_id) of the path
      #                                          (the relations followed).
      #                                          This is relevant for a queried for PARENT relation. In that case, relations need
      #                                          to be followed from the queried for work package (and its descendants) in both
      #                                          directions. But only the direction taken from that origin needs to be followed
      #                                          henceforth.
      # * includes_hierarchy - boolean indicating that the last relation taken was a hierarchy relation. For a queried for
      #                        PARENT relation, whenever that is the case, the work package is a valid relation target although
      #                        it appears in the CTE.
      def relatable(work_package, relation_type)
        return all if work_package.new_record?

        scope = not_having_direct_relation(work_package, relation_type)
                  .not_having_transitive_relation(work_package, relation_type)
                  .where.not(id: work_package.id)

        # On a parent relationship, explicitly remove the former parent (which might be the current one as well)
        # from the list of work packages one can relate to. This is not strictly necessary since it would not
        # cause faulty relationships but doing it removes the parent from places where it should not show up,
        # e.g. in an auto completer.
        if relation_type == Relation::TYPE_PARENT && work_package.parent_id_was
          scope = scope.where.not(id: work_package.parent_id_was)
        end

        if Setting.cross_project_work_package_relations
          scope
        else
          scope.where(project: work_package.project)
        end
      end

      def not_having_direct_relation(work_package, relation_type)
        origin = if relation_type == Relation::TYPE_PARENT
                   WorkPackageHierarchy
                     .where(ancestor_id: work_package.id)
                     .select(:descendant_id)
                 else
                   work_package.id
                 end

        where.not(id: Relation.where(from_id: origin).select(:to_id))
             .where.not(id: Relation.where(to_id: origin).select(:from_id))
      end

      def not_having_transitive_relation(work_package, relation_type)
        sql = <<~SQL.squish
          WITH
            RECURSIVE
            #{non_relatable_paths_sql(work_package, relation_type)}

            SELECT id
            FROM related
            WHERE #{blocklist_condition(relation_type)}
        SQL

        where("work_packages.id NOT IN (#{Arel.sql(sql)})")
      end

      private

      def non_relatable_paths_sql(work_package, relation_type)
        <<~SQL.squish
          related (id,
                   from_hierarchy,
                   from_from_id,
                   from_to_id,
                   includes_from_relation,
                   includes_to_relation,
                   includes_hierarchy,
                   origin) AS (

              #{non_recursive_relatable_values(work_package, relation_type)}

            UNION

              SELECT
                relations.id,
                relations.from_hierarchy,
                relations.from_from_id,
                relations.from_to_id,
                relations.includes_from_relation,
                relations.includes_to_relation,
                relations.includes_hierarchy,
                relations.origin
              FROM
                related
              JOIN LATERAL (
                #{joined_existing_connections(relation_type)}
              ) relations ON 1 = 1
          )
        SQL
      end

      def non_recursive_relatable_values(work_package, relation_type)
        hierarchy_condition = if relation_type == Relation::TYPE_PARENT
                                "work_package_hierarchies.ancestor_id = :id"
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
            work_package_hierarchies.descendant_id = :id includes_hierarchy,
            true origin
          FROM
            work_package_hierarchies
          WHERE
            #{hierarchy_condition}
        SQL

        ::OpenProject::SqlSanitization
          .sanitize sql,
                    id: work_package.id
      end

      def joined_existing_connections(relation_type)
        unions = [existing_hierarchy_lateral]

        case relation_type
        when Relation::TYPE_PARENT
          unions << existing_relation_of_type_lateral(Relation::TYPE_FOLLOWS, limit_direction: true)
          unions << existing_relation_of_type_lateral(Relation::TYPE_PRECEDES, limit_direction: true)
        when Relation::TYPE_RELATES
          # Nothing
        else
          unions << existing_relation_of_type_lateral(relation_type)
        end

        unions.join(' UNION ')
      end

      # rubocop:disable Metrics/PerceivedComplexity
      def existing_relation_of_type_lateral(relation_type, limit_direction: false)
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
            false includes_hierarchy,
            false origin
          FROM
            relations
          WHERE (relations.#{direction2} = related.id AND relations.relation_type = :relation_type)
            AND NOT related.from_#{direction2}
            #{direction_limit ? "AND NOT #{direction_limit}" : ''}
        SQL

        ::OpenProject::SqlSanitization
          .sanitize sql,
                    relation_type: canonical_type
      end
      # rubocop:enable Metrics/PerceivedComplexity

      def existing_hierarchy_lateral
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
            work_package_hierarchies.descendant_id = related.id includes_hierarchy,
            false origin
          FROM
            work_package_hierarchies
          WHERE
            related.from_hierarchy = false AND
            (work_package_hierarchies.ancestor_id = related.id OR work_package_hierarchies.descendant_id = related.id)
            AND (work_package_hierarchies.generations != 0)
        SQL
      end

      def blocklist_condition(relation_type)
        case relation_type
        when Relation::TYPE_PARENT
          "NOT includes_hierarchy"
        else
          '1 = 1'
        end
      end
    end
  end
end
