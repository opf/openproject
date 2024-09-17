#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "optparse"

begin
  Bundler.gem("parallel_tests")
rescue Gem::LoadError
  # In case parallel_tests is not provided, the whole of the parallel task group will not work.
  return
end

require "parallel_tests/tasks"
# Remove task added by parallel_tests as it conflicts with our own.
# Having both will lead to both being executed.
Rake::Task["parallel:features"].clear if Rake::Task.task_defined?("parallel:features")

def check_for_pending_migrations
  ParallelTests::Tasks.check_for_pending_migrations
end

namespace :parallel do
  module ParallelParser
    module_function

    def with_args(args, allow_seed = true)
      options = {}
      parseable_args = args[2..-1]
      if parseable_args
        OptionParser.new do |opts|
          opts.banner = "Usage: rails #{args[0]} -- [options]"
          opts.on("-n ARG", "--group-number ARG", Integer) { |num_cpus| options[:num_cpus] = num_cpus || ENV.fetch("GROUP", nil) }
          opts.on("-o ARG", "--only-group ARG", Integer) do |group_number|
            options[:group] = group_number || ENV.fetch("GROUP_SIZE", nil)
          end
          opts.on("-s ARG", "--seed ARG", Integer) { |seed| options[:seed] = seed || ENV.fetch("CI_SEED", nil) } if allow_seed
        end.parse!(parseable_args)
      end

      yield options
    end
  end

  def group_option_string(parsed_options)
    group_options  = parsed_options ? "-n #{parsed_options[:num_cpus]}" : ""
    group_options += " --only-group #{parsed_options[:group]}" if parsed_options[:group]

    group_options
  end

  ##
  # Returns all spec folder paths
  # of the core, modules and plugins
  def all_spec_paths
    spec_folders = ["spec"] + Plugins::LoadPathHelper.spec_load_paths
    spec_folders.join(" ")
  end

  ##
  # Returns all spec folder paths
  # of the core, modules and plugins
  def plugin_spec_paths
    Plugins::LoadPathHelper.spec_load_paths.join(" ")
  end

  def run_specs(parsed_options, folders, pattern = "", additional_options: nil, runtime_filename: nil)
    check_for_pending_migrations

    group_options = group_option_string(parsed_options)
    parallel_options = ""
    rspec_options = ""

    if runtime_filename && File.readable?(runtime_filename)
      parallel_options += " --group-by runtime --runtime-log #{runtime_filename} --allowed-missing 75"
    end
    if parsed_options[:seed]
      rspec_options += "--seed #{parsed_options[:seed]}"
    end
    if additional_options
      rspec_options += " #{additional_options}"
    end
    group_options += " -o '#{rspec_options}'" if rspec_options.length.positive?
    cmd = "bundle exec parallel_test --verbose --verbose-command --type rspec #{parallel_options} #{group_options} #{folders} #{pattern}"
    sh cmd
  end

  desc "Run all suites in parallel (one after another)"
  task all: ["parallel:plugins:specs",
             "parallel:plugins:features",
             :rspec]

  namespace :plugins do
    desc "Run all plugin tests in parallel"
    task all: ["parallel:plugins:specs",
               "parallel:plugins:features"]

    desc "Run plugin specs in parallel"
    task specs: [:environment] do
      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        run_specs options, plugin_spec_paths
      end
    end

    desc "Run plugin unit specs in parallel"
    task units: [:environment] do
      pattern = "--pattern 'spec/(?!features/)'"

      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        run_specs options, plugin_spec_paths, pattern
      end
    end

    desc "Run plugin feature specs in parallel"
    task features: [:environment] do
      pattern = "--pattern 'spec/features'"

      ParallelParser.with_args(ARGV) do |options|
        ARGV.each { |a| task(a.to_sym) {} }

        run_specs options, plugin_spec_paths, pattern
      end
    end
  end

  desc "Run spec in parallel (custom task)"
  task :specs do
    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, all_spec_paths
    end
  end

  desc "Run feature specs in parallel"
  task features: [:environment] do
    pattern = "--pattern 'spec/features/'"

    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, all_spec_paths, pattern, runtime_filename: "docker/ci/parallel_features_runtime.log"
    end
  end

  desc "Run unit specs in parallel"
  task units: [:environment] do
    pattern = "--pattern 'spec/(?!features/)'"

    ParallelParser.with_args(ARGV) do |options|
      ARGV.each { |a| task(a.to_sym) {} }

      run_specs options, all_spec_paths, pattern, runtime_filename: "docker/ci/parallel_units_runtime.log"
    end
  end
end
