class TypedDag::Sql::Helper
  def initialize(configuration)
    self.configuration = configuration
  end

  def table_name
    configuration.edge_table_name
  end

  def node_table_name
    configuration.node_table_name
  end

  def to_column
    configuration.to_column
  end

  def from_column
    configuration.from_column
  end

  def type_columns
    configuration.type_columns
  end

  def count_column
    configuration.count_column
  end

  def type_select_list
    type_columns.join(', ')
  end

  def type_select_summed_columns(prefix1, prefix2)
    type_columns
      .map { |column| "#{prefix1}.#{column} + #{prefix2}.#{column} " }
      .join(', ')
  end

  def type_select_summed_columns_aliased(prefix1, prefix2)
    type_columns
      .map { |column| "(#{prefix1}.#{column} + #{prefix2}.#{column}) #{column}" }
      .join(', ')
  end

  def sum_of_type_columns(prefix = '')
    sum_of_columns(type_columns, prefix)
  end

  def sum_of_columns(columns, prefix = '')
    columns.map { |column| "#{prefix}#{column}" }.join(' + ')
  end

  def exactly_one_type_column_eql_1(prefix = '')
    type_columns.map { |column| "#{prefix}#{column} = 1" }.join(' XOR ')
  end

  def mysql_db?
    ActiveRecord::Base.connection.adapter_name == 'Mysql2'
  end

  private

  attr_accessor :configuration
end
