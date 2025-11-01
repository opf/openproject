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
    class CteCollector < ActiveRecord::Relation
      attr_accessor :cte_collector_scope

      def initialize(on:)
        self.cte_collector_scope = on
        super(on)
      end

      def arel(aliases = nil)
        provided_ctes = fetch_ctes_from_node(cte_collector_scope.arel.ast)

        ret = @cte_collector_scope.arel(aliases)

        provided_ctes.each do |provided_cte|
          composed_cte = Arel::Nodes::As.new(Arel::Table.new(provided_cte),
                                             Arel::Nodes::Grouping.new(Arel::Nodes::SqlLiteral.new(OpenProject::ActiveRecordExtensions::Cte::Aggregation.registered[provided_cte.to_sym])))

          ret.with(composed_cte)
        end

        ret
      end

      private

      def fetch_ctes_from_node(node) # rubocop:disable Metrics/AbcSize
        provided_ctes = []

        if node.is_a?(OpenProject::ActiveRecordExtensions::ProviderStatement)
          provided_ctes << node.collect_provided_cte!
        end

        %i[wheres cores].each do |method|
          next unless node.respond_to?(method)

          node.public_send(method).each do |node|
            provided_ctes << fetch_ctes_from_node(node)
          end
        end

        %i[right left].each do |method|
          provided_ctes << fetch_ctes_from_node(node.public_send(method)) if node.respond_to?(method)
        end

        provided_ctes.flatten.compact.uniq
      end
    end
  end
end
