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

    desc "Run specs for api v3"
    RSpec::Core::RakeTask.new(api_v3: 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/**/*_spec.rb'
    end

    desc "Run requests specs for api v3"
    RSpec::Core::RakeTask.new(api_v3_requests: 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/requests/**/*_spec.rb'
    end

    desc "Run specs for api v3 except requests"
    RSpec::Core::RakeTask.new(api_v3_misc: 'spec:prepare') do |t|
      t.pattern = 'spec/api/v3/**/*_spec.rb'
      t.exclude_pattern = 'spec/api/v3/requests/**/*_spec.rb'
    end

    desc "Run specs for api experimental"
    RSpec::Core::RakeTask.new(:api_exp) do |t|
      t.pattern = 'spec/api/experimental/**/*_spec.rb'
    end

    desc "Run specs for api v2 and v1"
    RSpec::Core::RakeTask.new(:api_v2) do |t|
      t.pattern = 'spec/api/{v1,v2}/**/*_spec.rb'
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
