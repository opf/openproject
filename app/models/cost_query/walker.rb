class CostQuery::Walker
  attr_reader :query

  def initialize(query)
    @query = query
  end

  def row_first
    @row_first ||= query.result
  end

  def column_first
    @column_first ||= begin
      list, all_fields = restructured.reverse, []
      result = list.inject(@ungrouped) do |aggregate, (current_fields, type)|
        aggregate.grouped_by all_fields.push(*current_fields), type
      end
      result or current.result
    end
  end

  def restructured
    rows, columns, current = [], [], @query.chain
    until current.filter?
      if current.responsible_for_sql?
        @ungrouped = current.result
      else
        list = current.row? ? rows : columns
        list << [current.group_fields, list.type]
      end
      current = current.child
    end
    columns + rows
  end

  # ##
  # # Fields which the walker recognizes as a group. Unknown fields or
  # # fields which are not given (accepts_propertybut appear in the result) will be ignored.
  # #
  # # @overload follow_groups
  # #   Reads the fields the walker recognizes as groups.
  # #   @return [Array<#to_s>] fields
  # # @overload follow_groups(fields)
  # #   Sets the fields which are recognized as groups by the walker.
  # #   @param [Array<String, Symbol>] fields Field which are recognized as groups by the walker.
  # def follow_groups(fields = nil)
  #   @fields ||= []
  #   @fields = fields if fields
  #   @fields
  # end
  # 
  # ##
  # # Defines which parameter wil be given to the block when doing the walk.
  # #
  # # @param [Block] The block, which gets the result and returns the parameter the walk-block needs.
  # def walk_param_from(&block)
  #   @walk_param = block || { |result| result } # maybe this should be an empty array later.
  # end
  # 
  # ##
  # # Walks on the result and evaluates the block for each result as if we have nested group_by's.
  # # The given block will get the parameter defined in @see CostQuery::Walker#walk_param_from
  # def walk_on(&block)
  #   #walking on sunshine!
  #   result.recursive_each_with_level 0 false do | level, current_result |
  #     to_aggregate = @fields
  #     if r.fields.any? to_aggregate
  #       to_aggregate
  #     end
  #   end
  # end  
end
