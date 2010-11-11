
require 'yaml'

namespace :redmine_costs do
  begin
    include DevHelper

    def config
      YAML.load_file File.expand_path(File.join(__FILE__, '..', 'cruise.yml'))
    end

    desc 'Run unit tests for redmine_costs'
    task :'cruise:unit' do
      run_unit_tests('redmine_costs')
    end

    desc 'Run integration tests for redmine_costs'
    task :'cruise:integration' do
      run_integration_tests('redmine_costs')
    end

    desc 'Run cruise task for redmine_costs'
    task :cruise do
      run_cruise_task('redmine_costs')
    end

    task :'cruise:unit:internal' do
      unit_tests('redmine_picockpit_privacy')
    end

    task :'cruise:integration:internal' do
      integration_tests('redmine_picockpit_privacy')
    end
  rescue NameError
    puts "DevTools not present! Cruise Tasks not loaded"
  end
end
