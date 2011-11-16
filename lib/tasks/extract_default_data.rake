desc 'Create YAML files in features/fixtures'

namespace :redmine do
  namespace :backlogs do
    task :extract_fixtures => :environment do
      ENV["RAILS_ENV"] ||= "development"
      sql = "SELECT * FROM %s"
      skip_tables = ['schema_migrations']

      ActiveRecord::Base.establish_connection

      (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
        i = "000"
        File.open("#{RAILS_ROOT}/vendor/plugins/chiliproject_backlogs/features/fixtures/#{table_name}.yml", 'w') do |file|
          data = ActiveRecord::Base.connection.select_all(sql % table_name)
          puts data
          file.write data.inject({}) { |hash, record|
            hash["#{table_name}_#{i.succ!}"] = record
            hash
          }.to_yaml
        end
      end
    end
  end
end
