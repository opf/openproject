# encoding: UTF-8
class CostQuery::Walker
  attr_reader :query

  def initialize(query)
    @query = query

  end
  ##
  # @return [CostQuery::Result::Base] Result tree with row group bys at the top
  # @see CostQuery::Chainable#result
  def row_first
    @row_first ||= query.result
  end

  ##
  # @return [CostQuery::Result::Base] Result tree with column group bys at the top
  # @see CostQuery::Walker#row_first
  def column_first
    @column_first ||= begin
      # reverse since we fake recursion ↓↓↓
      list, all_fields = restructured.reverse, []
      result = list.inject(@ungrouped) do |aggregate, (current_fields, type)|
        aggregate.grouped_by all_fields.push(*current_fields), type
      end
      result or current.result
    end
  end

  ##
  # Important side effect: it sets @ungrouped.
  # @return [Array<Array<Array<String,Symbol>, Symbol>>] Group by fields + types (:row or :column)
  def restructured
    rows, columns, current = [], [], @query.chain
    until current.filter?
      if current.responsible_for_sql?
        @ungrouped = current.result
      else
        list = current.row? ? rows : columns
        list << [current.group_fields, current.type]
      end
      current = current.child
    end
    columns + rows
  end

  ##
  # @example
  #   query.walk(:column_first) do |current, subgregation|
  #     if subgregation.nil?
  #       ["<td>#{current.count}</td>"]
  #     elsif current.type == :column
  #       subgregation.first.unshift "<td rowspan='#{subgregation.size}'>#{current.group_fields}</td>"
  #     else
  #       subgregation.flatten
  #     end
  #   end
  def walk(result = nil, &block)
    result ||= row_first
    result = send result if result.is_a? Symbol
    return block.call(result, nil) unless result.has_children?
    block.call result, result.map { |r| walk(r, &block) }
  end
end
