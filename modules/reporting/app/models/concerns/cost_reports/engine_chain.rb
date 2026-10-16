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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module CostReports
  # Makes a cost report the query object of the reporting engine: it builds the
  # chain from its own filters and axes and exposes the engine's API on top.
  #
  # The filters, group bys, results and SQL are still defined in the CostQuery
  # namespace, which this addresses as the engine.
  module EngineChain
    extend ActiveSupport::Concern

    included do
      extend Forwardable

      def_delegators :transformer, :column_first, :row_first
      def_delegators :chain, :empty_chain, :top, :bottom, :chain_collect, :sql_statement,
                     :all_group_fields, :child, :clear, :result, :to_a
      def_delegators :result, :each_direct_result, :recursive_each, :recursive_each_with_level, :each,
                     :each_row, :count, :units, :final_number, :real_costs
      def_delegators :table, :row_index, :colum_index
    end

    def engine
      ::CostQuery
    end

    def chain(klass = nil, options = {})
      build_chain unless @chain

      if klass
        @chain = klass.new @chain, options
        @chain.engine = engine
      end

      @chain = @chain.parent until @chain.top?
      @chain
    end

    def filter(name, options = {})
      add_chain engine::Filter, name, options
    end

    def group_by(name, options = {})
      add_chain engine::GroupBy, name, options.reverse_merge(type: :column)
    end

    def column(name, options = {})
      group_by name, options.merge(type: :column)
    end

    def row(name, options = {})
      group_by name, options.merge(type: :row)
    end

    def group_bys(type = nil)
      chain.select { |node| node.group_by? && (type.nil? || node.type == type) }
    end

    def filters
      chain.select(&:filter?)
    end

    def depth_of(type)
      @depths ||= {}
      @depths[type] ||= chain.inject(0) { |sum, node| node.type == type ? sum + 1 : sum }
    end

    def transformer
      @transformer ||= Report::Transformer.new self
    end

    def walker
      @walker ||= Report::Walker.new self
    end

    def table
      @table = engine::Table.new(self)
    end

    def size
      total = 0
      recursive_each { |result| total += result.size }
      total
    end

    private

    # The chain has to exist before the definition can be replayed into it,
    # because adding a filter or group by appends to it.
    def build_chain
      engine::Filter.all && engine::GroupBy.all

      @chain = engine::Filter::NoFilter.new
      engine.chain_initializer.each { |block| block.call self }

      replay_definition
    end

    def replay_definition
      replay_filters
      replay_axes
    end

    def replay_filters
      query.filters.each do |definition|
        filter(definition.name, operator: definition.operator, values: definition.values)
      end

      filter(:cost_type_id, operator: "=", values: [unit_id.to_s]) if unit_id.present?
    end

    # Each one is prepended to the chain, so they are added in reverse of the
    # order they should end up in, columns before rows.
    def replay_axes
      rows, columns = rendered_axes

      columns.reverse_each { |attribute| column(attribute) }
      rows.reverse_each { |attribute| row(attribute) }
    end

    # The engine looks a chainable up by its demodulized, camelized name and
    # ignores anything it cannot find, e.g. a custom field that has been deleted.
    def add_chain(type, name, options)
      begin
        chain type.const_get(name.to_s.camelcase), options
      rescue NameError
        nil
      end

      @transformer = @walker = @table = @depths = nil
      self
    end
  end
end
