class UseTheFullStiClassNamesForRepositories < ActiveRecord::Migration
  def self.up
    type = ActiveRecord::Base.connection.quote_column_name('type')
    ActiveRecord::Base.connection.execute("UPDATE #{ActiveRecord::Base.connection.quote_table_name('repositories')} SET #{type} = CONCAT('Repository::',#{type}) WHERE #{type} NOT LIKE 'Repository::%'")
  end

  def self.down
    # noop, full class name should also work with older versions of active record
  end
end
