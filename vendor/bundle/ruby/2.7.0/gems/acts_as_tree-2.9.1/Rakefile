require 'bundler/gem_tasks'

desc "Run the tests."
task :test do
  $: << "lib" << "test"
  Dir["test/*_test.rb"].each { |f| require f[5..-4] }
end

task :default => :test

# Run the rdoc task to generate rdocs for this gem
require 'rdoc/task'
RDoc::Task.new do |rdoc|
  require "acts_as_tree/version"
  version = ActsAsTree::VERSION

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "acts_as_tree-rails3 #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
