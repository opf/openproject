# frozen_string_literal: true

require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task test: :spec
task default: :spec

desc 'Rebuild Circle CI configuration based on the build matrix template .circleci/config.yml.erb'
task :circleci do
  require 'erb'
  template_path = File.expand_path('.circleci/config.yml.erb', __dir__)
  config_path = File.expand_path('.circleci/config.yml', __dir__)
  File.write config_path, ERB.new(File.read(template_path)).result
end
