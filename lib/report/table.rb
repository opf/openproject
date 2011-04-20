# encoding: UTF-8
require 'enumerator'

class Report::Table
  attr_accessor :query
  include Report::QueryUtils

  def initialize(query)
    @query = query
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
    #fields_for(type).map { |k| result[k] }
    fields_for(type).map { |k| map_field k, result.fields[k] }
  end

  ##
  # @param [Array] expected Fields expected
  # @param [Array,Hash,Result] given Fields/result to be tested
  # @return [TrueClass,FalseClass]
  def satisfies?(type, expected, given)
    given  = fields_from(given, type) if given.respond_to? :to_hash
    zipped = expected.zip given
    zipped.all? { |a,b| a == b or b.nil? }
  end

  def fields_for(type)
    @fields_for ||= begin
      child, fields = query.chain, Hash.new { |h,k| h[k] = [] }
      until child.filter?
        fields[child.type].push(*child.group_fields)
        child = child.child
      end
      fields
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
    result.each_direct_result do |subresult|
      yield nil until stack.empty? or satisfies? type, stack.shift, subresult
      yield subresult
    end
    stack.size.times { yield nil }
  end

  def [](x,y)
    get_row(row_index[y]).first(x).last
  end

  def get_index(type)
    @indexes ||= begin
      indexes = Hash.new { |h,k| h[k] = Set.new }
      query.each_direct_result { |result| [:row, :column].each { |t| indexes[t] << fields_from(result, t) } }
      indexes.keys.each { |k| indexes[k] = indexes[k].sort { |x, y| x <=> y } }
      indexes
    end
    @indexes[type]
  end
end
