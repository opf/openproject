class Report::Walker
  attr_accessor :query, :header_stack
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
    @header_stack = []
    result ||= query.column_first
    sort result
    last_level = -1
    num_in_col = 0
    level_size = 1
    sublevel   = 0
    result.recursive_each_with_level(0, false) do |level, result|
      break if result.final_column?
      if first_in_col = (last_level < level)
        list        = []
        last_level  = level
        num_in_col  = 0
        level_size  = sublevel
        sublevel    = 0
        @header_stack << list
      end
      num_in_col  += 1
      sublevel    += result.size
      last_in_col  = (num_in_col >= level_size)
      @header_stack.last << [result, first_in_col, last_in_col]
      yield(result, level == 0, first_in_col, last_in_col) if block_given?
    end
  end

  def reverse_headers
    fail "call header first" unless @header_stack
    first = true
    @header_stack.reverse_each do |list|
      list.each do |result, first_in_col, last_in_col|
        yield(result, first, first_in_col, last_in_col)
      end
      first = false
    end
  end

  def headers_empty?
    fail "call header first" unless @header_stack
    @header_stack.empty?
  end

  def sort_keys
    @sort_keys ||= query.chain.map { |c| c.group_fields.map(&:to_s) if c.group_by? }.compact.flatten
  end

  def sort(result)
    result.set_key sort_keys
    result.sort!
  end

  def body(result = nil)
    return [*body(result)].each { |a| yield a } if block_given?
    result ||= query.result.tap { |r| sort(r) }
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
