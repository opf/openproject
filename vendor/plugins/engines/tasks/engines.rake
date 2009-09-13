# This code lets us redefine existing Rake tasks, which is extremely
# handy for modifying existing Rails rake tasks.
# Credit for the original snippet of code goes to Jeremy Kemper
# http://pastie.caboo.se/9620
unless Rake::TaskManager.methods.include?('redefine_task')
  module Rake
    module TaskManager
      def redefine_task(task_class, args, &block)
        task_name, arg_names, deps = resolve_args([args])
        task_name = task_class.scope_name(@scope, task_name)
        deps = [deps] unless deps.respond_to?(:to_ary)
        deps = deps.collect {|d| d.to_s }
        task = @tasks[task_name.to_s] = task_class.new(task_name, self)
        task.application = self
        task.add_description(@last_description)
        @last_description = nil
        task.enhance(deps, &block)
        task
      end
      
    end
    class Task
      class << self
        def redefine_task(args, &block)
          Rake.application.redefine_task(self, [args], &block)
        end
      end
    end
  end
end

namespace :db do
  namespace :migrate do
    desc 'Migrate database and plugins to current status.'
    task :all => [ 'db:migrate', 'db:migrate:plugins' ]
    
    desc 'Migrate plugins to current status.'
    task :plugins => :environment do
      Engines.plugins.each do |plugin|
        next unless File.exists? plugin.migration_directory
        puts "Migrating plugin #{plugin.name} ..."
        plugin.migrate
      end
    end

    desc 'For engines coming from Rails version < 2.0 or for those previously updated to work with Sven Fuch\'s fork of engines, you need to upgrade the schema info table'
    task :upgrade_plugin_migrations => :environment do
      svens_fork_table_name = 'plugin_schema_migrations'
      
      # Check if app was previously using Sven's fork
      if ActiveRecord::Base.connection.table_exists?(svens_fork_table_name)
        old_sm_table = svens_fork_table_name
      else
        old_sm_table = ActiveRecord::Migrator.proper_table_name(Engines.schema_info_table)
      end
      
      unless ActiveRecord::Base.connection.table_exists?(old_sm_table)
        abort "Cannot find old migration table - assuming nothing needs to be done"
      end
      
      # There are two forms of the engines schema info - pre-fix_plugin_migrations and post
      # We need to figure this out before we continue.
      
      results = ActiveRecord::Base.connection.select_rows(
        "SELECT version, plugin_name FROM #{old_sm_table}"
      ).uniq
      
      def insert_new_version(plugin_name, version)
        version_string = "#{version}-#{plugin_name}"
        new_sm_table = ActiveRecord::Migrator.schema_migrations_table_name
        
        # Check if the row already exists for some reason - maybe run this task more than once.
        return if ActiveRecord::Base.connection.select_rows("SELECT * FROM #{new_sm_table} WHERE version = #{version_string.dump.gsub("\"", "'")}").size > 0
        
        puts "Inserting new version #{version} for plugin #{plugin_name}.."
        ActiveRecord::Base.connection.insert("INSERT INTO #{new_sm_table} (version) VALUES (#{version_string.dump.gsub("\"", "'")})")
      end
      
      # We need to figure out if they already used "fix_plugin_migrations"
      versions = {}
      results.each do |r|
        versions[r[1]] ||= []
        versions[r[1]] << r[0].to_i
      end
      
      if versions.values.find{ |v| v.size > 1 } == nil
        puts "Fixing migration info"
        # We only have one listed migration per plugin - this is pre-fix_plugin_migrations,
        # so we build all versions required. In this case, all migrations should 
        versions.each do |plugin_name, version|
          version = version[0] # There is only one version
          
          # We have to make an assumption that numeric migrations won't get this long..
          # I'm not sure if there is a better assumption, it should work in all
          # current cases.. (touch wood..)
          if version.to_s.size < "YYYYMMDDHHMMSS".size
            # Insert version records for each migration
            (1..version).each do |v|
             insert_new_version(plugin_name, v)
            end
          else
            # If the plugin is new-format "YYYYMMDDHHMMSS", we just copy it across... 
            # The case in which this occurs is very rare..
            insert_new_version(plugin_name, version)
          end
        end
      else
        puts "Moving migration info"
        # We have multiple migrations listed per plugin - thus we can assume they have
        # already applied fix_plugin_migrations - we just copy it across verbatim
        versions.each do |plugin_name, version|
          version.each { |v| insert_new_version(plugin_name, v) }
        end
      end
      
      puts "Migration info successfully migrated - removing old schema info table"
      ActiveRecord::Base.connection.drop_table(old_sm_table)
    end
    
    desc 'Migrate a specified plugin.'
    task(:plugin => :environment) do
      name = ENV['NAME']
      if plugin = Engines.plugins[name]
        version = ENV['VERSION']
        puts "Migrating #{plugin.name} to " + (version ? "version #{version}" : 'latest version') + " ..."
        plugin.migrate(version ? version.to_i : nil)
      else
        puts "Plugin #{name} does not exist."
      end
    end
  end
end


namespace :db do  
  namespace :fixtures do
    namespace :plugins do
      
      desc "Load plugin fixtures into the current environment's database."
      task :load => :environment do
        require 'active_record/fixtures'
        ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
        Dir.glob(File.join(RAILS_ROOT, 'vendor', 'plugins', ENV['PLUGIN'] || '**', 
                 'test', 'fixtures', '*.yml')).each do |fixture_file|
          Fixtures.create_fixtures(File.dirname(fixture_file), File.basename(fixture_file, '.*'))
        end
      end
      
    end
  end
end

# this is just a modification of the original task in railties/lib/tasks/documentation.rake, 
# because the default task doesn't support subdirectories like <plugin>/app or
# <plugin>/component. These tasks now include every file under a plugin's load paths (see
# Plugin#load_paths).
namespace :doc do

  plugins = FileList['vendor/plugins/**'].collect { |plugin| File.basename(plugin) }

  namespace :plugins do

    # Define doc tasks for each plugin
    plugins.each do |plugin|
      desc "Create plugin documentation for '#{plugin}'"
      Rake::Task.redefine_task(plugin => :environment) do
        plugin_base   = RAILS_ROOT + "/vendor/plugins/#{plugin}"
        options       = []
        files         = Rake::FileList.new
        options << "-o doc/plugins/#{plugin}"
        options << "--title '#{plugin.titlecase} Plugin Documentation'"
        options << '--line-numbers' << '--inline-source'
        options << '-T html'

        # Include every file in the plugin's load_paths (see Plugin#load_paths)
        if Engines.plugins[plugin]
          files.include("#{plugin_base}/{#{Engines.plugins[plugin].load_paths.join(",")}}/**/*.rb")
        end
        if File.exists?("#{plugin_base}/README")
          files.include("#{plugin_base}/README")    
          options << "--main '#{plugin_base}/README'"
        end
        files.include("#{plugin_base}/CHANGELOG") if File.exists?("#{plugin_base}/CHANGELOG")

        if files.empty?
          puts "No source files found in #{plugin_base}. No documentation will be generated."
        else
          options << files.to_s
          sh %(rdoc #{options * ' '})
        end
      end
    end
  end
end



namespace :test do
  task :warn_about_multiple_plugin_testing_with_engines do
    puts %{-~============== A Moste Polite Warninge ===========================~-

You may experience issues testing multiple plugins at once when using
the code-mixing features that the engines plugin provides. If you do
experience any problems, please test plugins individually, i.e.

  $ rake test:plugins PLUGIN=my_plugin

or use the per-type plugin test tasks:

  $ rake test:plugins:units
  $ rake test:plugins:functionals
  $ rake test:plugins:integration
  $ rake test:plugins:all

Report any issues on http://dev.rails-engines.org. Thanks!

-~===============( ... as you were ... )============================~-}
  end
  
  namespace :engines do
    
    def engine_plugins
      Dir["vendor/plugins/*"].select { |f| File.directory?(File.join(f, "app")) }.map { |f| File.basename(f) }.join(",")
    end
    
    desc "Run tests from within engines plugins (plugins with an 'app' directory)"
    task :all => [:units, :functionals, :integration]
    
    desc "Run unit tests from within engines plugins (plugins with an 'app' directory)"
    Rake::TestTask.new(:units => "test:plugins:setup_plugin_fixtures") do |t|
      t.pattern = "vendor/plugins/{#{ENV['PLUGIN'] || engine_plugins}}/test/unit/**/*_test.rb"
      t.verbose = true
    end

    desc "Run functional tests from within engines plugins (plugins with an 'app' directory)"
    Rake::TestTask.new(:functionals => "test:plugins:setup_plugin_fixtures") do |t|
      t.pattern = "vendor/plugins/{#{ENV['PLUGIN'] || engine_plugins}}/test/functional/**/*_test.rb"
      t.verbose = true
    end

    desc "Run integration tests from within engines plugins (plugins with an 'app' directory)"
    Rake::TestTask.new(:integration => "test:plugins:setup_plugin_fixtures") do |t|
      t.pattern = "vendor/plugins/{#{ENV['PLUGIN'] || engine_plugins}}/test/integration/**/*_test.rb"
      t.verbose = true
    end
  end
  
  namespace :plugins do

    desc "Run the plugin tests in vendor/plugins/**/test (or specify with PLUGIN=name)"
    task :all => [:warn_about_multiple_plugin_testing_with_engines, 
                  :units, :functionals, :integration]
    
    desc "Run all plugin unit tests"
    Rake::TestTask.new(:units => :setup_plugin_fixtures) do |t|
      t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || "**"}/test/unit/**/*_test.rb"
      t.verbose = true
    end
    
    desc "Run all plugin functional tests"
    Rake::TestTask.new(:functionals => :setup_plugin_fixtures) do |t|
      t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || "**"}/test/functional/**/*_test.rb"
      t.verbose = true
    end
    
    desc "Integration test engines"
    Rake::TestTask.new(:integration => :setup_plugin_fixtures) do |t|
      t.pattern = "vendor/plugins/#{ENV['PLUGIN'] || "**"}/test/integration/**/*_test.rb"
      t.verbose = true
    end

    desc "Mirrors plugin fixtures into a single location to help plugin tests"
    task :setup_plugin_fixtures => :environment do
      Engines::Testing.setup_plugin_fixtures
    end
    
    # Patch the default plugin testing task to have setup_plugin_fixtures as a prerequisite
    Rake::Task["test:plugins"].prerequisites << "test:plugins:setup_plugin_fixtures"
  end
end
