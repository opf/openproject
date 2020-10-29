require "rubygems"
require "rake/testtask"

task :default => :test

task :load_path do
  %w(lib test).each do |path|
    $LOAD_PATH.unshift(File.expand_path("../#{path}", __FILE__))
  end
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

desc "Remove temporary files"
task :clean do
  %x{rm -rf *.gem doc pkg coverage}
  %x{rm -f `find . -name '*.rbc'`}
end

desc "Build the gem"
task :gem do
  %x{gem build friendly_id.gemspec}
end

desc "Build YARD documentation"
task :yard do
  puts %x{bundle exec yard}
end

desc "Run benchmarks"
task :bench => :load_path do
  require File.expand_path("../bench", __FILE__)
end

desc "Run benchmarks on finders"
task :bench_finders => :load_path do
  require File.expand_path("../test/benchmarks/finders", __FILE__)
end

desc "Run benchmarks on ObjectUtils"
task :bench_object_utils => :load_path do
  require File.expand_path("../test/benchmarks/object_utils", __FILE__)
end

desc "Generate Guide.md"
task :guide do
  load File.expand_path('../guide.rb', __FILE__)
end

namespace :test do

  desc "Run each test class in a separate process"
  task :isolated do
    dir = File.expand_path("../test", __FILE__)
    Dir["#{dir}/*_test.rb"].each do |test|
      puts "Running #{test}:"
      puts %x{ruby -Ilib -Itest #{test}}
    end
  end
end

namespace :db do

  desc "Create the database"
  task :create => :load_path do
    require "helper"
    driver = FriendlyId::Test::Database.driver
    config = FriendlyId::Test::Database.config[driver]
    commands = {
      "mysql"    => "mysql -h #{config['host']} -P #{config['port']} -u #{config['username']} --password=#{config['password']} -e 'create database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'create database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
  end

  desc "Drop the database"
  task :drop => :load_path do
    require "helper"
    driver = FriendlyId::Test::Database.driver
    config = FriendlyId::Test::Database.config[driver]
    commands = {
      "mysql"    => "mysql -h #{config['host']} -P #{config['port']} -u #{config['username']} --password=#{config['password']} -e 'drop database #{config["database"]};' >/dev/null",
      "postgres" => "psql -c 'drop database #{config['database']};' -U #{config['username']} >/dev/null"
    }
    %x{#{commands[driver] || true}}
  end

  desc "Set up the database schema"
  task :up => :load_path do
    require "helper"
    FriendlyId::Test::Schema.up
  end

  desc "Drop and recreate the database schema"
  task :reset => [:drop, :create]

end

task :doc => :yard

task :docs do
  sh %{git checkout gh-pages && rake doc && git checkout @{-1}}
end
