require 'nulldb/core'

# Need to defer calling Rails.root because when bundler loads, Rails.root is nil
NullDB.configure {|ndb| def ndb.project_root;Rails.root;end}

ActiveRecord::Tasks::DatabaseTasks.register_task(/nulldb/, ActiveRecord::Tasks::NullDBDatabaseTasks) if defined?(ActiveRecord::Tasks)
