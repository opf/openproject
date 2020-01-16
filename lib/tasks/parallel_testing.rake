#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'optparse'
require 'plugins/load_path_helper'

def check_for_pending_migrations
  require 'parallel_tests/tasks'
  ParallelTests::Tasks.check_for_pending_migrations
end

namespace :parallel do
  class ParallelParser
    def self.with_args(args, allow_seed = true)
      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: rails #{args[0]} -- [options]"
        opts.on("-n ARG", "--group-number ARG", Integer) { |num_cpus| options[:num_cpus] = num_cpus || ENV['GROUP'] }
        opts.on("-o ARG", "--only-group ARG", Integer) { |group_number| options[:group] = group_number || ENV['GROUP_SIZE'] }
        opts.on("-s ARG", "--seed ARG", Integer) { |seed| options[:seed] = seed || ENV['CI_SEED'] } if allow_seed
      end.parse!(args[2..-1])

      yield options
    end
  end

  def group_option_string(parsed_options)
    group_options  = parsed_options ? "-n #{parsed_options[:num_cpus]}" : ''
    group_options += " --only-group #{parsed_options[:group]}" if parsed_options[:group]

    group_options
  end

  def run_specs(parsed_options, folders, pattern = '', additional_options: nil)
    check_for_pending_migrations

    group_options = group_option_string(parsed_options)

    rspec_options = ''
    if parsed_options[:seed]
      rspec_options += "--seed #{parsed_options[:seed]}"
    end
    if additional_options
      rspec_options += " #{additional_options}"
    end
    group_options += " -o '#{rspec_options}'" if rspec_options.length.positive?

    sh "bundle exec parallel_test --type rspec #{group_options} #{folders} #{pattern}"
  end

  def run_cukes(parsed_options, folders)
    exit 'No feature folders to run cucumber on' if folders.blank?

    group_options = group_option_string(parsed_options)

    support_files = ([Rails.root.join('features').to_s] + Plugins::LoadPathHelper.cucumber_load_paths)
                    .map { |path| ['-r', Shellwords.escape(path)] }.flatten.join(' ')

    cucumber_options = "-o ' -p rerun #{support_files}'"

    sh "bundle exec parallel_test --type cucumber #{cucumber_options} #{group_options} #{folders}"
  end

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

    desc 'Run plugin specs in parallel'
    task specs: [:environment] do
      spec_folders = Plugins::LoadPathHelper.spec_load_paths.join(' ')

      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        run_specs options, spec_folders
      end
    end

    desc 'Run plugin unit specs in parallel'
    task units: [:environment] do
      pattern = "--pattern 'spec/(?!features\/)'"

      spec_folders = Plugins::LoadPathHelper.spec_load_paths.join(' ')

      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        run_specs options, spec_folders, pattern
      end
    end

    desc 'Run plugin feature specs in parallel'
    task features: [:environment] do
      pattern = "--pattern 'spec\/features'"

      spec_folders = Plugins::LoadPathHelper.spec_load_paths.join(' ')

      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        run_specs options, spec_folders, pattern
      end
    end

    desc 'Run plugin cucumber features in parallel'
    task cucumber: [:environment] do
      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        feature_folders  = Plugins::LoadPathHelper.cucumber_load_paths.join(' ')

        run_cukes(options, feature_folders)
      end
    end
  end

  desc 'Run legacy specs in parallel'
  task :spec_legacy do
    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, 'spec_legacy', '', additional_options: '-I spec_legacy'
    end
  end

  desc 'Run spec in parallel (custom task)'
  task :specs do
    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, 'spec'
    end
  end

  desc 'Run feature specs in parallel'
  task features: [:environment] do
    pattern = "--pattern '^spec\/features\/'"

    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, 'spec', pattern
    end
  end

  desc 'Run unit specs in parallel'
  task units: [:environment] do
    pattern = "--pattern '^spec/(?!features\/)'"

    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, 'spec', pattern
    end
  end
end
