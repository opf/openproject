module Queries::Storages::WorkPackages::Filter::StoragesFilterMixin
  def type
    :list
  end

  # Returns the model class for which the filter will apply.
  #
  # Used in the where and joins clauses.
  def filter_model
    raise NotImplementedError
  end

  # Returns the column name for which the filter will apply.
  #
  # Used in the where clause.
  def filter_column
    raise NotImplementedError
  end

  def allowed_values
    # Allow all input values that are given to the filter.
    # If no result is found, an empty collection is returned.
    values.map { |value| [nil, value] }
  end

  def where
    <<-SQL.squish
      #{::Queries::Operators::Equals.sql_for_field(where_values, filter_model.table_name, filter_column)}
      AND work_packages.project_id IN (#{Project.allowed_to(User.current, permission).select(:id).to_sql})
    SQL
  end

  def where_values
    values
  end

  def joins
    filter_model.table_name.to_sym
  end

  def unescape_hosts(hosts)
    hosts.map { |host| CGI.unescape(host).gsub(/\/+$/, '') }
  end
end
