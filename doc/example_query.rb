query = CostQuery.new
query.filter :cost_type_id #, :value => 42
query.group_by :cost_type_id

puts query.sql_statement