
require 'yaml'

namespace :redmine_additional_formats do
  include DevHelper
  
  def config
    YAML.load_file File.expand_path(File.join(__FILE__, '..', 'cruise.yml'))
  end
  
  desc 'Run unit tests for redmine_additional_formats'
  task :'cruise:unit' do
    run_unit_tests('redmine_additional_formats')
  end
  
  desc 'Run integration tests for redmine_additional_formats'
  task :'cruise:integration' do
    run_integration_tests('redmine_additional_formats')
  end
  
  task :cruise_testing => :'dev:setup' do
    run_cruise_task_in_testing_env('redmine_additional_formats')
  end
  
  desc 'Run cruise task for redmine_additional_formats'
  task :cruise do
    run_cruise_task('redmine_additional_formats')
  end
end
