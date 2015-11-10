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

namespace :parallel do
  desc 'Run all suites in parallel (one after another)'
  task all: ['parallel:plugins:spec', 'parallel:plugins:cucumber', :spec_legacy, :rspec, :cucumber]

  namespace :plugins do

    desc 'Run all plugin tests in parallel'
    task all: ['parallel:plugins:spec', 'parallel:plugins:cucumber']

    desc 'Run plugin specs in parallel'
    task spec: [:environment] do
      ParallelTests::Tasks.check_for_pending_migrations

      num_cpus       = ENV['GROUP_SIZE']
      group          = ENV['GROUP']

      group_options  = num_cpus ? "-n #{num_cpus}" : ''
      group_options += " --only-group #{group}" if group

      spec_folders = Plugins::LoadPathHelper.spec_load_paths.join(' ')

      # Change this if changed in spec/support/rspec_failures.rb
      if File.exist? 'tmp/rspec-examples.txt'
        sh 'rm tmp/rspec-examples.txt'
      end

      cmd  = "bundle exec parallel_test --type rspec #{group_options} #{spec_folders}"
      cmd += " || bundle exec rspec --only-failures #{spec_folders}"

      sh cmd
    end

    desc 'Run plugin cucumber features in parallel'
    task cucumber: [:environment] do
      ParallelTests::Tasks.check_for_pending_migrations

      num_cpus       = ENV['GROUP_SIZE']
      group          = ENV['GROUP']

      group_options  = num_cpus ? "-n #{num_cpus}" : ''
      group_options += " --only-group #{group}" if group

      support_files = [Rails.root.join('features').to_s] + Plugins::LoadPathHelper.cucumber_load_paths
      support_files = support_files.map { |path|
        ['-r', Shellwords.escape(path)]
      }.flatten.join(' ')

      feature_folders  = Plugins::LoadPathHelper.cucumber_load_paths.join(' ')
      cucumber_options = "-o ' -p rerun #{support_files}'"

      cmd  = "bundle exec parallel_test --type cucumber #{cucumber_options} #{group_options} #{feature_folders}"
      cmd += " || bundle exec cucumber -p rerun #{support_files}"

      if File.exist? 'tmp/cucumber-rerun.txt'
        sh 'rm tmp/cucumber-rerun.txt'
      end

      sh cmd
    end
  end

  desc 'Run legacy specs in parallel'
  task :spec_legacy do
    ParallelTests::Tasks.check_for_pending_migrations

    num_cpus       = ENV['GROUP_SIZE']
    group          = ENV['GROUP']

    group_options  = num_cpus ? "-n #{num_cpus}" : ''
    group_options += " --only-group #{group}" if group

    cmd  = "bundle exec parallel_test --type rspec -o '-I spec_legacy' #{group_options} spec_legacy"
    cmd += ' || bundle exec rspec -I spec_legacy --only-failures spec_legacy'

    sh cmd
  end

  desc 'Run cucumber features in parallel (custom task)'
  task :cucumber do
    ParallelTests::Tasks.check_for_pending_migrations

    num_cpus       = ENV['GROUP_SIZE']
    group          = ENV['GROUP']

    group_options  = num_cpus ? "-n #{num_cpus}" : ''
    group_options += " --only-group #{group}" if group

    support_files = [Rails.root.join('features').to_s] + Plugins::LoadPathHelper.cucumber_load_paths
    support_files = support_files.map { |path|
      ['-r', Shellwords.escape(path)]
    }.flatten.join(' ')

    cucumber_options = "-o ' -p rerun #{support_files}'"

    cmd  = "bundle exec parallel_test --type cucumber #{cucumber_options} #{group_options} features"
    cmd += ' || bundle exec cucumber -p rerun'

    if File.exist? 'tmp/cucumber-rerun.txt'
      sh 'rm tmp/cucumber-rerun.txt'
    end

    sh cmd
  end

  desc 'Run rspec in parallel (custom task)'
  task :rspec do
    ParallelTests::Tasks.check_for_pending_migrations

    num_cpus       = ENV['GROUP_SIZE']
    group          = ENV['GROUP']

    group_options  = num_cpus ? "-n #{num_cpus}" : ''
    group_options += " --only-group #{group}" if group

    cmd  = "bundle exec parallel_test --type rspec #{group_options} spec"
    cmd += ' || bundle exec rspec --only-failures'

    sh cmd
  end
end
