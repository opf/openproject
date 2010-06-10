# encoding: UTF-8
class CostQuery::Table
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
