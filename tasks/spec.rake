begin
  require "spec/rake/spectask"
  namespace :spec do
    namespace :plugins do
      desc "Runs the examples for redmine_reporting"
      Spec::Rake::SpecTask.new(:redmine_reporting) do |t|
        t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/redmine_reporting/spec/**/*_spec.rb']
      end
    end
  end
  task :spec => "spec:plugins:redmine_reporting"

  require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
  require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
  task :"spec:plugins:redmine_reporting:ci" => ["ci:setup:rspec", "spec:plugins:redmine_reporting"]
rescue LoadError
end
