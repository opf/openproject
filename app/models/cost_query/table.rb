# encoding: UTF-8

##
# @example
#   CostQuery::Table.new query, :rows => [:project_id, :user_id], :columns => [:spent_on, :tweak]
class CostQuery::Table
  attr_accessor :query

  def initialize(query, options = {})
    options = options.with_indifferent_access.merge :query => query
    options.each do |k,v|
      k = "#{k}=" if respond_to? "#{k}="
      send(k, *v)
    end
  end

  def rows(*rows)
    return @rows if rows.empty?
    @rows = rows
  end

  def columns(*rows)
    return @rows if rows.empty?
    @rows = rows
  end

  def rows_for(result)    rows.map    { |k| result[k] } end
  def columns_for(result) columns.map { |k| result[k] } end
end
