module ReportsHelper
  
  def aggregate(data, criteria)
    a = 0
    data.each { |row|
      match = 1
      criteria.each { |k, v|
        match = 0 unless (row[k].to_s == v.to_s) || (k == 'closed' && row[k] == (v == 0 ? "f" : "t"))
      } unless criteria.nil?
      a = a + row["total"].to_i if match == 1
    } unless data.nil?
    a
  end
  
  def aggregate_link(data, criteria, *args)
    a = aggregate data, criteria
    a > 0 ? link_to(a, *args) : '-'
  end  
end
