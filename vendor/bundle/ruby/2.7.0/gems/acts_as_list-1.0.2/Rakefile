require "rubygems"
require "bundler/setup"
Bundler::GemHelper.install_tasks

require "rake/testtask"

# Run the test with "rake" or "rake test"
desc "Default: run acts_as_list unit tests."
task default: :test

desc "Test the acts_as_list plugin."
Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "."
  t.test_files = Rake::FileList["test/**/test_*.rb"]
  t.verbose = false
end

begin
  # Run the rdoc task to generate rdocs for this gem
  require "rdoc/task"
  RDoc::Task.new do |rdoc|
    require "acts_as_list/version"
    version = ActiveRecord::Acts::List::VERSION

    rdoc.rdoc_dir = "rdoc"
    rdoc.title = "acts_as_list #{version}"
    rdoc.rdoc_files.include("README*")
    rdoc.rdoc_files.include("lib/**/*.rb")
  end
rescue LoadError
  puts "RDocTask is not supported on this platform."
rescue StandardError
  puts "RDocTask is not supported on this platform."
end

# See https://github.com/skywinder/github-changelog-generator#rake-task for details
# and github_changelog_generator --help for available options
require 'github_changelog_generator/task'
GitHubChangelogGenerator::RakeTask.new :changelog do |config|
  config.project = 'acts_as_list'
  config.user = 'brendon'
end
