begin
  require "spec/rake/spectask"
  namespace :spec do
    namespace :plugins do
      desc "Runs the examples for redmine_additional_formats"
      Spec::Rake::SpecTask.new(:redmine_additional_formats) do |t|
        t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
        t.spec_files = FileList['vendor/plugins/redmine_additional_formats/spec/**/*_spec.rb']
      end
    end
  end
rescue LoadError
  puts "Missing RSpec gem"
end