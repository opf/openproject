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

def check_for_pending_migrations
  require 'parallel_tests/tasks'
  ParallelTests::Tasks.check_for_pending_migrations
end

namespace :parallel do
  desc 'Run all suites in parallel (one after another)'
  task all: ['parallel:plugins:specs',
             'parallel:plugins:features',
             'parallel:plugins:cucumber',
             :spec_legacy,
             :rspec,
             :cucumber]

  namespace :plugins do
    desc 'Run all plugin tests in parallel'
    task all: ['parallel:plugins:specs',
               'parallel:plugins:features',
               'parallel:plugins:cucumber']

    def run_specs(pattern)
      check_for_pending_migrations

      num_cpus       = ENV['GROUP_SIZE']
      group          = ENV['GROUP']

      group_options  = num_cpus ? "-n #{num_cpus}" : ''
      group_options += " --only-group #{group}" if group

      spec_folders = Plugins::LoadPathHelper.spec_load_paths.join(' ')

      sh "bundle exec parallel_test --type rspec #{group_options} #{spec_folders} #{pattern}"
    end

    desc 'Run plugin specs (non features) in parallel'
    task specs: [:environment] do
      pattern = "--pattern '.+/spec/(?!features\/)'"

      run_specs pattern
    end

    desc 'Run plugin feature specs in parallel'
    task features: [:environment] do
      pattern = "--pattern '.+/spec/features/'"

      run_specs pattern
    end

    desc 'Run plugin cucumber features in parallel'
    task cucumber: [:environment] do
      check_for_pending_migrations

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

      sh "bundle exec parallel_test --type cucumber #{cucumber_options} #{group_options} #{feature_folders}"
    end
  end

  desc 'Run legacy specs in parallel'
  task :spec_legacy do
    check_for_pending_migrations

    num_cpus       = ENV['GROUP_SIZE']
    group          = ENV['GROUP']
    seed           = ENV['CI_SEED']

    spec_options  = num_cpus ? "-n #{num_cpus}" : ''
    spec_options += " --only-group #{group}" if group
    spec_options += " -o '--seed #{seed}'" if seed

    sh "bundle exec parallel_test --type rspec -o '-I spec_legacy' #{spec_options} spec_legacy"
  end

  desc 'Run cucumber features in parallel (custom task)'
  task :cucumber do
    check_for_pending_migrations

    num_cpus       = ENV['GROUP_SIZE']
    group          = ENV['GROUP']

    group_options  = num_cpus ? "-n #{num_cpus}" : ''
    group_options += " --only-group #{group}" if group

    support_files = [Rails.root.join('features').to_s] + Plugins::LoadPathHelper.cucumber_load_paths
    support_files = support_files.map { |path|
      ['-r', Shellwords.escape(path)]
    }.flatten.join(' ')

    cucumber_options = "-o ' -p rerun #{support_files}'"

    sh "bundle exec parallel_test --type cucumber #{cucumber_options} #{group_options} features"
  end

  desc 'Run rspec in parallel (custom task)'
  task :rspec do
    check_for_pending_migrations

    num_cpus       = ENV['GROUP_SIZE']
    group          = ENV['GROUP']
    seed           = ENV['CI_SEED']

    spec_options  = num_cpus ? "-n #{num_cpus}" : ''
    spec_options += " --only-group #{group}" if group
    spec_options += " -o '--seed #{seed}'" if seed

    sh "bundle exec parallel_test --type rspec #{spec_options} spec"
  end
end
