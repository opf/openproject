#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++
#

module WorkPackages::Scopes
  class ForScheduling
    class << self
      # Fetches all work packages that need to be evaluated for eventual rescheduling after a related (i.e. follows/precedes
      # and hierarchy) work package is modified or created.
      #
      # The SQL relies on CTEs which, after constructing the set of all potential work_packages then filter down the
      # work packages to the actually affected work packages. The set of potentially affected work packages can be diminished by
      # manually schedule work packages.
      #
      # The first CTE works recursively to fetch all work packages related to the provided work package and the path of
      # intermediate work packages. The work packages can either be connected via a follows relationship, a hierarchy relationship
      # or a combination of both.
      # E.g. in a graph of
      #   A  <- follows - B <- hierarchy (C is parent of B) - C <- follows D
      #
      # D would also be subject to reschedule.
      #
      # At least for hierarchical relationships, we need to follow the relationship in both directions.
      # E.g. in a graph of
      #   A  <- follows - B - hierarchy (B is parent of C) -> C <- follows D
      #
      # D would also be subject to reschedule.
      #
      # That possible switch in direction means that we cannot simply get all possibly affected work packages by one
      # SQL query which the DAG implementation would have allowed us to do otherwise.
      # Additionally, we need to get the whole paths (with all intermediate work packages included) which would be possible
      # with DAG but as we need to rely on a recursive approach already we do not need to complicate the SQL statement any
      # further. Fetching the whole path (at least in one direction) relying on DAG would be faster though
      # so we might revisit this if any performance shortcomings are identified.
      # The first CTE returns all work packages with their path so reusing the example above, the result would be
      #   id      |   path
      #   A       | {A}
      #   B       | {A,B}
      #   C       | {A,B,C}
      #   D       | {A,B,C,D}
      # If the graph where to contain multiple paths to one node work package, because of multiple follows relationship
      # to the same hierarchical tree, the work package would be returned twice with different paths.
      #
      # The paths are followed until either:
      # * no more follows and/or hierarchy relations can be followed
      # * a manually scheduled work package is encountered.
      #
      # So if, in the example above, B would be manually scheduled, the first CTE would only return
      #   id      |   path
      #   A       | {A}
      #   B       | {A,B}
      #
      # The interim result, provided by the first CTE, is thus the set of all work packages, that are in a direct or transitive
      # follows and/or hierarchy relationship up until the point where the relationships end or a manually scheduled work package
      # is encountered.
      #
      # That set needs to be filtered down because of additional constraints on scheduling:
      # * Manually scheduled work packages prevent automatic scheduling up the hierarchy chain. So even with an existing follows
      #   relationship work packages might not be scheduled automatically if their children or descendants are automatically
      #   scheduled. This is only true for a work package if *all* the children are manually scheduled either directly or because
      #   their respective children are all scheduled manually. In case of the hierarchy
      #   A and B <- hierarchy (C is parent of both A and B) C <- D
      #   if A and B are both scheduled manually, C is also scheduled manually and so is D. But if only A is scheduled manually,
      #   B, C and D are scheduled automatically.
      # * the first constraint might cause gaps in the previously established paths. If a work package follows an automatically
      #   scheduled work package, and that preceding work package has children that are manually scheduled, the preciding
      #   work package will no longer be automatically scheduled and the same is then true for the following work package.
      #
      # To visualize the above:
      #                                    A  <- follows - B  <- follows C
      #                                                    |
      #                                                hierarchy
      #                                                    v
      #                                                    D (manually)
      #   The first, path fetching CTE will return B, C and D. The constraint above will then remove B and D and the second
      #   constraint will remove C.
      #
      # The work packages that are identified to be in a direct or transitive relationship with the provided work packages and
      # that neither have only manually scheduled children/descendants or would only be reachable via work packages for which
      # the before mentioned constraint is true are returned. The provided work package is always excluded.
      #
      # @param work_packages WorkPackage[] A set of work packages for which the set of related work packages that might
      # be subject to reschedule is fetched.
      def fetch(work_packages)
        return WorkPackage.none if work_packages.empty?

        sql = <<~SQL
          WITH
            RECURSIVE
            #{paths_sql(work_packages)},
            #{paths_without_manual_hierarchy_sql},
            #{paths_without_gaps_sql}

            SELECT id FROM eligible_paths_without_gaps
        SQL

        WorkPackage
          .where("id IN (#{sql})")
          .where.not(id: work_packages)
      end

      private

      # This recursive CTE fetches all work packages that are in a direct or transitive follows and/or hierarchy
      # relationship with the provided work package.
      #
      # Hierarchy relationships are followed up as well as down (from and to) but follows relations are only followed
      # from the predecessor to the successor (from_id to to_id).
      #
      # We will need the exact path (meaning all intermediate work packages) for the later filtering so for each
      # recursive step the statement only adds the all the work packages directly connected to the current step and
      # does not make use of the abilities of DAG. Using the transitive relationships provided by DAG should be possible
      # but the constraints caused by PostgreSQL's implementation of recursive CTEs (no outer join of, no duplicate
      # reference to and no subqueries with the recursive query) makes writing it extremly hard.
      #
      # While using DAG should theoretically be faster, as less iterative steps are required, the difference should
      # not be noticeable.
      #
      # The CTE starts from the provided work package and for that returns:
      #   * the id of the work package
      #   * the path to that work package which is again the id but this time as a PostgreSQL array
      #   * again, a path, same as above but referred to as the path_root (explained below)
      #   * the information, that the starting work package is not manually scheduled.
      # Whether the starting work package is manually scheduled or in fact automatically scheduled does make no
      # difference but we need those four columns later on.
      #
      # For each recursive step, we return all work packages that are directly related to our current set of work
      # packages by a hierarchy (up or down) or follows relationship (only successors). For each such work package
      # the statement returns:
      #   * id of the work package that is currently at the end of a path.
      #   * the path to the added work package. This is the path of the work package the statement extended the path
      #     from (joined with) with the added work package appended.
      #   * the path_root which is the path up to the first work package that is within the current work package
      #     hierarchy. Whenever a new hierarchy is reached (indicated by joining a follow relationship), a new root
      #     path is created. If the hierarchy is kept, the root_path is taken from the recursive step before.
      #     The root_path is later on used to identify all work packages within the result set that are within
      #     the same hierarchy and that might need to be removed because of manual scheduling bubbling up the
      #     hierarchy tree. Therefore, follow relationships constructed between members of the same hierarchy are
      #     no problem as well.
      #   * the flag indicating whether the added work package is automatically or manually scheduled.
      #
      # Paths whose ending work package is marked to be manually scheduled are not joined with any more.
      #
      # The recursion ends when no more work packages can be added to the set either because:
      #  * There is no more work package with a relationship to the current set
      #  * The current paths all end in manually scheduled work packages
      # Both conditions can also stop the recursion together.
      def paths_sql(work_packages)
        values = work_packages.map { |wp| "(#{wp.id},ARRAY[#{wp.id}], ARRAY[#{wp.id}], false)" }.join(', ')

        <<~SQL
          clean_paths (id, path, root_path, manually) AS (
            SELECT * FROM (VALUES#{values}) AS t(id, path, root_path, manually)

            UNION ALL

            SELECT
              CASE
                WHEN relations.to_id = clean_paths.id
                THEN relations.from_id
                ELSE relations.to_id
              END id,
              CASE
                WHEN relations.to_id = clean_paths.id
                THEN array_append(path, relations.from_id)
                ELSE array_append(path, relations.to_id)
              END path,
              CASE
                WHEN relations.to_id = clean_paths.id AND relations.follows = 1
                THEN array_append(path, relations.from_id)
                ELSE clean_paths.root_path
              END root_path,
              work_packages.schedule_manually manually
            FROM
              clean_paths
            JOIN
              relations
              ON NOT clean_paths.manually
              AND (#{relations_condition_sql})
              AND
                ((relations.to_id = clean_paths.id AND NOT relations.from_id = any(clean_paths.path))
                OR (relations.from_id = clean_paths.id AND NOT relations.to_id = any(clean_paths.path) AND relations.follows = 0))
            LEFT JOIN work_packages
              ON (CASE
                WHEN relations.to_id = clean_paths.id
                THEN relations.from_id
                ELSE relations.to_id
                END) = work_packages.id
          )
        SQL
      end

      # Filters a set of paths (as returned by the recursive path constructing CTE above) to only contain
      # work packages (and their paths) that are truly automatically scheduled.
      # Even though a work package is flagged to be automatically scheduled, a work package can in fact be manually scheduled
      # nonetheless if:
      # * all of its paths towards their leafs have at least one manually scheduled work package in them.
      #
      # As the recursive CTE above terminates a paths once a manually scheduled work package is identified,
      # those manually scheduled work packages are leafs for the sake of the set inserted into this query but might
      # very well have children outside of the set.
      #
      # Identifying all leafs (for the sake of the set) is complicated by the possibility of having multiple
      # follow relationships spanning into the same hierarchy tree. E.g. in a graph of
      #
      #                  C
      #                  |
      #               hierarchy
      #                  |
      #                  v
      #   A <- follows - B
      #   ^              |
      #   |            hierarchy
      #   |              |
      #   |              v
      #   |              D (manually)
      #   |              |
      #   |            hierarchy
      #   |              |
      #   |              v
      #    -- follows  - E
      #
      # D is excluded directly. But B and C also need to be considered manually scheduled as their descendant D is
      # scheduled manually. But E (which is the actual leaf of that hierarchy) is reached via a different follows
      # relationship.
      #
      # Please not that when D has an automatically scheduled sibling F:
      #
      #                  C
      #                  |
      #               hierarchy
      #                  |
      #                  v
      #   A <- follows - B - hierarchy -
      #   ^              |              |
      #   |            hierarchy        |
      #   |              |              |
      #   |              v              v
      #   |              D (manually)   F
      #   |              |
      #   |            hierarchy
      #   |              |
      #   |              v
      #    -- follows  - E
      #
      # Neither B nor C are considered manually scheduled any more.
      #
      # The query works by joining the paths with itself and with the relations first to identify all paths (calculated by
      # the CTE before) that lead to descendants of a work package. Here, the root_path is considered to avoid mixing
      # individual follows relationships jumps.
      # Next, the paths are joined again to identify those, that have no longer paths.
      # The result are all paths that lead to descendants of a work packages identified in the path that have no longer paths
      # which, within the set, are the leafs. Of those, only the paths are returned that do not lead to a manually scheduled
      # work package.
      # This step also removes all work packages that are scheduled manually directly.
      def paths_without_manual_hierarchy_sql
        <<~SQL
          paths_without_manual_hierarchy AS (
            SELECT
              paths.id,
              paths.path
            FROM
              clean_paths paths
            LEFT JOIN
              relations
            ON
              relations.from_id = paths.id AND "relations"."follows" = 0 AND (#{relations_condition_sql(transitive: true)})
            LEFT JOIN
              clean_paths to_paths
            ON
              relations.to_id = to_paths.id AND to_paths.root_path = paths.root_path
            LEFT JOIN
              clean_paths longer_paths
            ON
              longer_paths.path[1:array_length(longer_paths.path, 1) - 1] = to_paths.path
              AND to_paths.root_path = longer_paths.root_path
              AND longer_paths.path <> paths.path
            WHERE longer_paths.id IS NULL
            AND NOT (paths.manually OR COALESCE(to_paths.manually, false))
          )
        SQL
      end

      # Returns all paths that do not include intermediary hops (work packages) that are not within the set of paths
      # themselves.
      # This serves as a second filter after work packages scheduled manually by transition are removed from the set.
      # E.g in a graph of
      #                                    A  <- follows - B  <- follows C
      #                                                    |
      #                                                hierarchy
      #                                                    v
      #                                                    D (manually)
      #
      # The recursive CTE will return A, B, C and D, with D flagged as manually scheduled. The first filter will then remove
      # D and B from the set. Now, there is no longer a connection between A and C. So the query below removes C from the
      # result as well.
      def paths_without_gaps_sql
        <<~SQL
          eligible_paths_without_gaps AS (
            SELECT
              *
            FROM
              paths_without_manual_hierarchy
            WHERE
              path <@ (SELECT array_agg(id) FROM paths_without_manual_hierarchy)
          )
        SQL
      end

      def relations_condition_sql(transitive: false)
        <<~SQL
          "relations"."relates" = 0 AND "relations"."duplicates" = 0 AND "relations"."blocks" = 0 AND "relations"."includes" = 0 AND "relations"."requires" = 0
            AND (relations.hierarchy + relations.relates + relations.duplicates + relations.follows + relations.blocks + relations.includes + relations.requires #{transitive ? '>' : ''}= 1)
        SQL
      end
    end
  end
end
