# frozen_string_literal: true

# -- copyright
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
# ++

module OpenProject
  module ActiveRecordExtensions
    # Wraps a relation, hoists every provider CTE found in its ast into one top-level
    # WITH clause, and selects from the collapsed query as a FROM-subquery. Staying a
    # subquery keeps this a normal, composable relation (to_a/pluck/count/where all go
    # through ActiveRecord).
    class CteCollector < ActiveRecord::Relation
      # Node accessors walked to find ProviderStatements anywhere in the ast, including
      # join sources and their ON conditions, not just top-level WHEREs. The WITH clause
      # is walked separately (see #child_nodes) since `with` is not a safe generic reader.
      CHILD_ACCESSORS = %i[cores source wheres left right expr children].freeze

      attr_accessor :cte_collector_scope

      # Callers embed the collector's arel and read the underlying arel_table off the
      # scope, so expose the wrapped model's table.
      delegate :arel_table, to: :klass

      # Wraps the relation in a collector when the shared-permissions CTE feature is
      # enabled, and returns it unchanged otherwise.
      def self.collect(relation)
        return relation unless OpenProject::FeatureDecisions.shared_user_permissions_cte_active?

        new(relation:)
      end

      def initialize(relation:)
        self.cte_collector_scope = relation
        super(relation.klass, table: relation.table, predicate_builder: relation.predicate_builder)

        from!(Arel.sql("(#{collapsed_sql}) #{relation.klass.quoted_table_name}"))
      end

      private

      # Render the wrapped scope with every provider CTE hoisted into one WITH clause.
      # Works on a spawn and renders through the relation (not the manager) so bind
      # parameters are inlined into the self-contained FROM-subquery. Provider nodes
      # are marked collected only while rendering and reset in the ensure block, so the
      # wrapped scope keeps rendering standalone afterwards.
      def collapsed_sql
        scope = cte_collector_scope.spawn
        manager = scope.arel
        statements = fetch_provider_statements(manager.ast)

        ctes = hoisted_ctes(statements)
        prepend_ctes(manager, ctes) if ctes.any?

        scope.to_sql
      ensure
        statements&.each { |statement| statement.provided_cte_collected = false }
      end

      # One CTE per distinct provider, materialized when referenced more than once.
      def hoisted_ctes(statements)
        reference_counts = statements.each_with_object(Hash.new(0)) do |statement, counts|
          counts[statement.provided_cte] += 1
        end

        statements.uniq(&:provided_cte).map do |statement|
          compose_cte(statement, materialized: reference_counts[statement.provided_cte] > 1)
        end
      end

      # Prepend the hoisted CTEs to any WITH clause the wrapped scope already carries,
      # keeping them ahead of CTEs that may reference them and preserving recursiveness.
      def prepend_ctes(manager, ctes)
        existing = manager.ast.with
        combined = ctes + (existing ? existing.children : [])

        manager.ast.with = if existing.is_a?(Arel::Nodes::WithRecursive)
                             Arel::Nodes::WithRecursive.new(combined)
                           else
                             Arel::Nodes::With.new(combined)
                           end
      end

      # Build a `<name> AS [MATERIALIZED] (<body>)` node from the statement's CTE SQL.
      # Materialize only CTEs referenced more than once: it avoids recomputing a shared
      # derivation and hands the planner a concrete cardinality, but would needlessly
      # block inlining for a single-use CTE.
      def compose_cte(statement, materialized:)
        body = statement.provided_cte_sql
        right = if materialized
                  Arel::Nodes::SqlLiteral.new("MATERIALIZED (#{body})")
                else
                  Arel::Nodes::Grouping.new(Arel::Nodes::SqlLiteral.new(body))
                end

        Arel::Nodes::As.new(Arel::Table.new(statement.provided_cte), right)
      end

      # Recursively collect the ProviderStatement nodes in the ast, marking each as
      # collected. A missed provider simply renders inline, so this walk only affects
      # how much collapses, never correctness.
      def fetch_provider_statements(node)
        statements = []

        if node.is_a?(OpenProject::ActiveRecordExtensions::ProviderStatement)
          node.collect_provided_cte!
          statements << node
        end

        child_nodes(node).each do |child|
          statements.concat(fetch_provider_statements(child))
        end

        statements
      end

      def child_nodes(node)
        children = CHILD_ACCESSORS.flat_map do |accessor|
          node.respond_to?(accessor) ? Array(node.public_send(accessor)) : []
        end

        # SelectStatement#with holds the WITH clause; walk it so providers used as CTE
        # bodies are found too. Read `with` only from statements — other Arel nodes
        # define an unrelated `with` that expects a block.
        children << node.with if node.is_a?(Arel::Nodes::SelectStatement)

        # Subqueries embedded via `attribute.in(relation.arel)` sit in the ast as a
        # SelectManager rather than a node; descend into its statement so providers
        # nested inside them (e.g. WorkPackage.visible's member_projects) are reached.
        children.map { |child| child.is_a?(Arel::SelectManager) ? child.ast : child }
                .grep(Arel::Nodes::Node)
      end
    end
  end
end
