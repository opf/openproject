#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
    errors = %w(test:scm:units test:scm:functionals).collect { |task|
      begin
        Rake::Task[task].invoke
        nil
      rescue => e
        task
      end
    }.compact
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

    Rake::TestTask.new(units: 'db:test:prepare') do |t|
      t.libs << 'test'
      t.verbose = true
      t.test_files = FileList['test/unit/repository*_test.rb'] + FileList['test/unit/lib/redmine/scm/**/*_test.rb']
    end
    Rake::Task['test:scm:units'].comment = 'Run the scm unit tests'

    Rake::TestTask.new(functionals: 'db:test:prepare') do |t|
      t.libs << 'test'
      t.verbose = true
      t.test_files = FileList['test/functional/repositories*_test.rb']
    end
    Rake::Task['test:scm:functionals'].comment = 'Run the scm functional tests'
  end

  desc 'runs all tests'
  namespace :suite do
    task run: [:cucumber, :spec, 'spec:legacy']
  end
end

task('spec:legacy').clear

namespace :spec do
  begin
    require 'rspec/core/rake_task'

    desc 'Run the code examples in spec_legacy'
    task legacy: %w(legacy:unit legacy:functional legacy:integration)
    namespace :legacy do
      %w(unit functional integration).each do |type|
        desc "Run the code examples in spec_legacy/#{type}"
        RSpec::Core::RakeTask.new(type => 'spec:prepare') do |t|
          t.pattern = "spec_legacy/#{type}/**/*_spec.rb"
          t.rspec_opts = '-I spec_legacy'
        end
      end
    end
  rescue LoadError
    # when you bundle without development and test (e.g. to create a deployment
    # artefact) still all tasks get loaded. To avoid an error we rescue here.
  end
end

%w(spec).each do |type|
  if Rake::Task.task_defined?("#{type}:prepare")
    Rake::Task["#{type}:prepare"].enhance(['assets:prepare_op'])
  end
end
