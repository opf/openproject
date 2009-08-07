class DeliverableQuery < Query
  @@available_columns = [
    QueryColumn.new(:subject, :sortable => "#{Deliverable.table_name}.subject"),
    QueryColumn.new(:author),
    QueryColumn.new(:updated_on, :sortable => "#{Deliverable.table_name}.updated_on", :default_order => 'desc'),
    QueryColumn.new(:created_on, :sortable => "#{Deliverable.table_name}.created_on", :default_order => 'desc'),
  ]
end