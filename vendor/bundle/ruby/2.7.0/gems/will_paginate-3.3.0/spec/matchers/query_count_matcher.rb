class QueryCountMatcher
  def initialize(num)
    @expected_count = num
  end

  def matches?(block)
    run(block)

    if @expected_count.respond_to? :include?
      @expected_count.include? @count
    else
      @count == @expected_count
    end
  end

  def run(block)
    $query_count = 0
    $query_sql = []
    block.call
  ensure
    @queries = $query_sql.dup
    @count = $query_count
  end

  def performed_queries
    @queries
  end

  def failure_message
    "expected #{@expected_count} queries, got #{@count}\n#{@queries.join("\n")}"
  end

  def negative_failure_message
    "expected query count not to be #{@expected_count}"
  end
end
