#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :test do
  desc 'Run unit and functional scm tests'
  task :scm do
    errors = %w(test:scm:units test:scm:functionals).collect do |task|
      begin
        Rake::Task[task].invoke
        nil
      rescue => e
        task
      end
    end.compact
    abort "Errors running #{errors.to_sentence(locale: :en)}!" if errors.any?
  end

  namespace :scm do
    namespace :setup do
      desc 'Creates directory for test repositories'
      task :create_dir do
        FileUtils.mkdir_p Rails.root + '/tmp/test'
      end

      supported_scms = [:subversion, :git]

      desc 'Creates a test subversion repository'
      supported_scms.each do |scm|
        desc "Creates a test #{scm} repository"
        task scm => :create_dir do
          repo_path = File.join(Rails.root, "tmp/test/#{scm}_repository")
          FileUtils.mkdir_p repo_path
          # system "gunzip < spec/fixtures/repositories/#{scm}_repository.tar.gz | tar -xv -C tmp/test"
          system "tar -xvz -C #{repo_path} -f spec/fixtures/repositories/#{scm}_repository.tar.gz"
        end
      end

      desc 'Creates all test repositories'
      task all: supported_scms
    end

    desc 'Updates installed test repositories'
    task :update do
      require 'fileutils'
      Dir.glob('tmp/test/*_repository').each do |dir|
        next unless File.basename(dir) =~ %r{\A(.+)_repository\z} && File.directory?(dir)
        scm = $1
        next unless fixture = Dir.glob("spec/fixtures/repositories/#{scm}_repository.*").first
        next if File.stat(dir).ctime > File.stat(fixture).mtime

        FileUtils.rm_rf dir
        Rake::Task["test:scm:setup:#{scm}"].execute
      end
    end
  end

  desc 'runs all tests'
  namespace :suite do
    task run: [:cucumber, :spec]
  end
end

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
