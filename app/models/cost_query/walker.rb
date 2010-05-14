class CostQuery::Walker
  def initialize(result)
    @result = result
  end

  ##
  # Fields which the walker recognizes as group_by. Unknown fields or
  # fields which are not given (but appear in the result) will be ignored.
  #
  # @overload follow_groups
  #   Reads the fields the walker recognizes as group_by's.
  #   @return [Array<#to_s>] fields
  # @overload follow_groups(fields)
  #   Sets the fields which are recognized as group_by's by the walker.
  #   @param [Array<String, Symbol>] fields Field which the.
  def follow_groups(fields = nil)
    @fields ||= []
    @fields = fields unless fields.nil?
    @fields
  end

  ##
  # Defines which parameter wil be given to the block when doing the walk.
  #
  # @param [Block] The block, which gets the result and returns the parameter the walk-block needs.
  def walk_param_from(&block)
    @walk_param = &block || { |result| result } # maybe this should be an empty array later.
  end

  ##
  # Walks on the result and evaluates the block for each result as if we have nested group_by's.
  # The given block will get the parameter defined in @see CostQuery::Walker#walk_param_from
  def walk_on(&block)
    #walking on sunshine!
  end
end
