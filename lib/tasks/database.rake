namespace 'db:sessions' do
  desc 'Expire old sessions from the sessions table'
  task :expire, [:days_ago] => [:environment, 'db:load_config'] do |_task, args|
    # sessions expire after 30 days of inactivity by default
    days_ago = Integer(args[:days_ago] || 30)
    expiration_time = Date.today - days_ago.days

    sessions_table = ActiveRecord::SessionStore::Session.table_name
    ActiveRecord::Base.connection.execute "DELETE FROM #{sessions_table} WHERE updated_at < '#{expiration_time}'"
  end
end
