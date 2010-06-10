# encoding: UTF-8
require 'enumerator'

##
# @example
#   CostQuery::Table.new query, :rows => [:project_id, :user_id], :columns => [:tweak, :spent_on]
class CostQuery::Table
  attr_accessor :query

  def initialize(query, options = {})
    options = options.with_indifferent_access.merge :query => query
    options.each do |k,v|
      k = "#{k}=" if respond_to? "#{k}="
      send(k, *v)
    end
  end

  def row_index
    get_index :row
  end

  def column_index
    get_index :column
  end

  def row_fields
    fields_for :row
  end

  def column_fields
    fields_for :column
  end

  def rows_for(result)    fields_for result, :row     end
  def columns_for(result) fields_for result, :column end

  def fields_from(result, type)
    fields_for(type).map { |k| result[k] }
  end

  ##
  # @param [Array] expected Fields expected
  # @param [Array,Hash,Resul] given Fields/result to be tested
  # @return [TrueClass,FalseClass]
  def satisfies?(type, expected, given)
    given  = fields_from(result, type) if given.respond_to? :to_hash
    zipped = expected.zip given
    zipped.all? { |a,b| a == b or b.nil? }
  end

  def fields_for(type)
    @fields_for ||= begin
      child, fields = query.chain, Hash.new { |h,k| h[k] = [] }
      fields[child.type].push(*child.group_fields) until child.filter?
    end
    @fields_for[type]
  end

  def get_row(*args)
    @query.each_row { |result| return with_gaps_for(type, result) if satisfies? :row, args, result }
    []
  end

  def with_gaps_for(type, result)
    return enum_for(:with_gaps_for, type, result) unless block_given?
    stack = get_index(type).dup
    result.each do |subresult|
      yield nil until satisfies? type, stack.shift, subresult
      yield subresult
    end
  end

  def [](x,y)
    get_row(row_index[y]).first(x).last
  end

  def all_types(&block)
    return [:row, :column] unless block
    all_types.each(&block)
  end

  def get_index(type)
    @indexes ||= begin
      indexes = Hash.new(&method(:compare_fields))
      query.each_direct_result { |result| all_types { |t| indexes[t] = fields_from result, t }
      indexes.keys.each { |k| indexes[k] = indexes[k].to_a.uniq }
    end
    @indexes[type]
  end

  def compare_fields(a, b)
    a.zip(b).each { |x,y| return x > y unless x == y }
    true
  end

end
