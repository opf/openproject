# encoding: UTF-8
class Report::Transformer
  attr_reader :query

  def initialize(query)
    @query = query
  end

  ##
  # @return [Report::Result::Base] Result tree with row group bys at the top
  # @see Report::Chainable#result
  def row_first
    @row_first ||= query.result
  end

  ##
  # @return [Report::Result::Base] Result tree with column group bys at the top
  # @see Report::Walker#row_first
  def column_first
    @column_first ||= begin
      # reverse since we fake recursion ↓↓↓
      list, all_fields = restructured.reverse, @all_fields.dup
      result = list.inject(@ungrouped) do |aggregate, (current_fields, type)|
        fields, all_fields = all_fields, all_fields - current_fields
        aggregate.grouped_by fields, type, current_fields
      end
      result or query.result
    end
  end

  ##
  # Important side effect: it sets @ungrouped, @all_fields.
  # @return [Array<Array<Array<String,Symbol>, Symbol>>] Group by fields + types (:row or :column)
  def restructured
    rows, columns, current = [], [], query.chain
    @all_fields = []
    until current.filter?
      @ungrouped = current.result if current.responsible_for_sql?
      list = current.row? ? rows : columns
      list << [current.group_fields, current.type]
      @all_fields.push(*current.group_fields)
      current = current.child
    end
    columns + rows
  end
end
