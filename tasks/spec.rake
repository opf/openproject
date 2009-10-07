require "spec/rake/spectask"

namespace :spec do
  namespace :plugins do
    Spec::Rake::SpecTask.new('redmine_costs') do |t|
      t.spec_files = Dir.glob "#{File.dirname __FILE__}/../spec/**/*_spec.rb"
    end
  end
end

task :spec => "spec:plugins:redmine_costs"