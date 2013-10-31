class FixWatcherWorkPackageAssociations < ActiveRecord::Migration
  def up
    rename_watchable_type('Issue', 'WorkPackage')
  end

  def down
    rename_watchable_type('WorkPackage', 'Issue')
  end

  private

  def rename_watchable_type(source_type, target_type)
    ActiveRecord::Base.connection.execute "UPDATE #{watchers_table}
                                           SET watchable_type=#{quote_value(target_type)}
                                           WHERE watchable_type=#{quote_value(source_type)}"
  end

  def watchers_table
    ActiveRecord::Base.connection.quote_table_name 'watchers'
  end

  def quote_value(value)
    ActiveRecord::Base.connection.quote value
  end

end
