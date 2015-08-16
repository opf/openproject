task('spec').clear
task('spec:legacy').clear

desc 'Run all specs in spec directory (excluding plugin specs)'
task spec: %w(spec:core spec:legacy)

namespace :spec do
  desc 'Run the code examples in spec, excluding legacy'
  begin
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(core: 'spec:prepare') do |t|
      t.exclude_pattern = ''
    end

    desc "Run specs w/o api, features, controllers, requests and models"
    RSpec::Core::RakeTask.new(misc: 'spec:prepare') do |t|
      t.exclude_pattern = 'spec/{api,models,controllers,requests,features}/**/*_spec.rb'
    end

    desc "Run requests specs for api v3"
    RSpec::Core::RakeTask.new('api:v3:requests' => 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/requests/**/*_spec.rb'
    end

    desc "Run specs for api v3 except requests"
    RSpec::Core::RakeTask.new('api:v3:misc' => 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/**/*_spec.rb'
      t.exclude_pattern = 'spec/api/v3/requests/**/*_spec.rb'
    end

    sub_types = begin
            dirs = Dir['./spec/{api,features}/**/*_spec.rb'].
              map { |f| f.sub(/^\.\/(spec\/\w+\/\w+)\/.*/, '\\1') }.
              uniq.
              select { |f| File.directory?(f) }
            Hash[dirs.map { |d| ["#{d.split('/').second}:#{d.split('/').last}", d] }]
          end

    sub_types.each do |type, dir|
      desc "Run the code examples in #{dir}"
      RSpec::Core::RakeTask.new(type => "spec:prepare") do |t|
        t.pattern = "./#{dir}/**/*_spec.rb"
      end
    end

  rescue LoadError
    # when you bundle without development and test (e.g. to create a deployment
    # artefact) still all tasks get loaded. To avoid an error we rescue here.
  end
end

%w(spec).each do |type|
  if Rake::Task.task_defined?("#{type}:prepare")
    # FIXME: only webpack for feature specs
    Rake::Task["#{type}:prepare"].enhance(['assets:webpack'])
  end
end
