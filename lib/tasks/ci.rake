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

desc 'Run the Continuous Integration tests for OpenProject'
task :ci do
  # RAILS_ENV and ENV[] can diverge so force them both to test
  ENV['RAILS_ENV'] = 'test'
  RAILS_ENV = 'test'
  Rake::Task['ci:setup'].invoke
  Rake::Task['ci:build'].invoke
  Rake::Task['ci:teardown'].invoke
end

# Tasks can be hooked into by redefining them in a plugin
namespace :ci do
  namespace :travis do
    desc 'Prepare a TRAVIS run'
    task :prepare do
      Rails.env = 'test'
      ENV['RAILS_ENV'] = 'test'
      RAILS_ENV = 'test'
      db_adapter = ENV['DB']

      raise 'please provide a db adapter with DB={mysql2, postgres}' unless db_adapter

      db_info = {
        'mysql2' => {
          'adapter'  => 'mysql2',
          'username' => 'root'
        },
        'postgres' => {
          'adapter'  => 'postgresql',
          'username' => 'postgres'
        }
      }[db_adapter]

      database_yml = {
        'database' => 'chiliproject_test'
      }.merge(db_info)

      File.open('config/database.yml', 'w') do |f|
        YAML.dump({ 'test' => database_yml }, f)
      end

      # Create and migrate the database
      Rake::Task['db:create'].invoke

      # db:create invokes db:load_config. db:load_config collects migration paths, but the
      # migration paths for plugins are set on the Engine config when the application
      # is initialized, which the environment task does. The environment task is only later
      # executed as dependency for db:migrate. db:migrate also depends on load_config, but since
      # it has been executed before, rake doesn't execute it a second time.
      # Loading the environment bevore explicitly executing db:load_config (not only invoking it)
      # makes rake execute it a second time after the environment has been loaded.
      # Loading the environment before db:create does not work, since initializing the application
      # depends on an existing databse.
      Rake::Task['environment'].invoke
      Rake::Task['db:load_config'].execute

      Rake::Task['db:migrate'].invoke
      Rake::Task['db:schema:dump'].invoke

      # Create test repositories
      Rake::Task['test:scm:setup:all'].invoke
    end
  end

  desc 'Setup OpenProject for a new build.'
  task :setup do
    Rake::Task['ci:dump_environment'].invoke
    Rake::Task['db:drop'].invoke
    Rake::Task['db:create'].invoke
    Rake::Task['db:migrate'].invoke
    Rake::Task['db:schema:dump'].invoke
    Rake::Task['test:scm:update'].invoke
  end

  desc 'Build OpenProject'
  task :build do
    Rake::Task['test'].invoke
  end

  # Use this to cleanup after building or run post-build analysis.
  desc 'Finish the build'
  task :teardown do
  end

  desc 'Dump the environment information to a BUILD_ENVIRONMENT ENV variable for debugging'
  task :dump_environment do

    ENV['BUILD_ENVIRONMENT'] = ['ruby -v', 'gem -v', 'gem list'].collect do |command|
      result = `#{command}`
      "$ #{command}\n#{result}"
    end.join("\n")

  end
end
