require "spec/rake/spectask"

namespace :spec do
  namespace :plugins do
    desc "Runs the examples for redmine_costs"
    Spec::Rake::SpecTask.new(:redmine_costs) do |t|
      t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
      t.spec_files = FileList['vendor/plugins/redmine_costs/spec/**/*_spec.rb']
    end
  end
end

task :spec => "spec:plugins:redmine_costs"