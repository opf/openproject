class ActiveRecord::ConnectionAdapters::NullDBAdapter

  class IndexDefinition < Struct.new(:table, :name, :unique, :columns, :lengths, :orders); end

end
