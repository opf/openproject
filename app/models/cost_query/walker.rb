class CostQuery::Walker
  attr_accessor :query
  def initialize(query)
    @query = query
  end

  def for_row(&block)
    access_block(:row, &block)
  end

  def for_final_row(&block)
    access_block(:final_row, &block) || access_block(:row)
  end

  def for_cell(&block)
    access_block(:cell, &block)
  end

  def for_empty_cell(&block)
    access_block(:empty_cell, &block) || access_block(:cell)
  end

  def access_block(name, &block)
    @blocks ||= {}
    @blocks[name] = block if block
    @blocks[name]
  end

  def walk_cell(cell)
    cell ? for_cell[cell] : for_empty_cell[nil] 
  end

  def headers(result = nil, &block)
    result = nil if reverse = (result == :reverse)
    first = result.nil?
    result ||= query.column_first
    return unless result.column? and not result.final_column?
    yield result, first unless reverse
    result.each { |r| headers(r, &block) }
    yield result, first if reverse
  end

  def body(result = nil)
    return [*body(result)].each { |a| yield a } if block_given?
    result ||= query.result
    if result.row?
      if result.final_row?
        subresults = query.table.with_gaps_for(:column, result).map(&method(:walk_cell))
        for_final_row.call result, subresults
      else
        subresults = result.map { |r| body(r) }
        for_row.call result, subresults
      end
    else
      # you only get here if no rows are defined
      result.each_direct_result.map(&method(:walk_cell))
    end
  end
end
