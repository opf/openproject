begin
  require "spec/rake/spectask"
  namespace :spec do
    namespace :plugins do
      desc "Runs the examples for reporting_engine"
      Spec::Rake::SpecTask.new(:reporting_engine) do |t|
        t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/reporting_engine/spec/**/*_spec.rb']
      end

      desc "Runs the examples for reporting_engine"
      Spec::Rake::SpecTask.new(:"reporting_engine:rcov") do |t|
        t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/reporting_engine/spec/**/*_spec.rb']
        t.rcov = true
        t.rcov_opts = ['-x', "\.rb,spec", '-i', "reporting_engine/app/,redmine_reporting/lib/"]
      end
    end
  end
  task :spec => "spec:plugins:reporting_engine"

  require 'ci/reporter/rake/rspec'     # use this if you're using RSpec
  require 'ci/reporter/rake/test_unit' # use this if you're using Test::Unit
  task :"spec:plugins:reporting_engine:ci" => ["ci:setup:rspec", "spec:plugins:redmine_reporting"]
rescue LoadError
end
