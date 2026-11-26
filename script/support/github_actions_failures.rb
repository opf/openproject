# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "json"

module GithubActionsFailures
  Result = Data.define(:errors, :failures_explanation, :merge_branch_sha)

  class Error
    attr_accessor :location, :page_html, :page_screenshot, :tests_group, :loading_error
  end

  class TestsGroup
    attr_accessor :test_env_number, :seed, :files

    # Job logs from before the switch to parallel_rspec do not contain the
    # command of each tests group.
    def self.null
      @null ||= new.tap do |null_test_group|
        null_test_group.test_env_number = "0 (info not available)"
      end
    end

    def initialize
      @files = []
    end

    def include_error?(error)
      return false if error.location.nil?

      files.any? { |file| error.location.include?(file) }
    end

    def inspect
      "#<#{self.class} @test_env_number=#{test_env_number} @seed=#{seed} (#{files.count} files)>"
    end
  end

  class JobErrorsFinder
    SPEC_FAILURES_PATTERN = %r{^\S+ rspec (\S+) #.+$}
    SPEC_LOADING_ERRORS_PATTERN = %r{^\S+ An error occurred while loading (\S+)\.\r?$}
    SCREENSHOT_PATTERN = /\{"message":"Screenshot captured for failed feature test"[^\n]+$/
    # Looks like this in the job log:
    # rubocop:disable Layout/LineLength
    # bin/rspec --seed 52674 -O .rspec_parallel spec/features/api_docs/index_spec.rb spec/features/custom_fields/reorder_options_spec.rb spec/features/projects/projects_portfolio_spec.rb spec/features/projects/template_spec.rb spec/features/versions/edit_spec.rb
    # rubocop:enable Layout/LineLength
    TESTS_GROUP_PATTERN = %r{bin/rspec --seed \d+ [^\n]+$}
    BRANCH_MERGE_PATTERN = /Merge \w{40} into (\w{40})$/

    def self.scan_logs(logs)
      finder = new
      logs.each do |log|
        finder.scan_log(log)
      end

      Result.new(
        errors: finder.errors,
        failures_explanation: finder.failures_explanation,
        merge_branch_sha: finder.merge_branch_sha
      )
    end

    attr_reader :failures_explanation, :merge_branch_sha

    def scan_log(log)
      find_failures(log)
      find_failures_explanation(log)
      find_loading_errors(log)
      find_screenshots(log)
      find_tests_groups(log)
      find_merge_branch_info(log)
    end

    def errors
      @errors.values
    end

    private

    def initialize
      @errors = {}
    end

    def create_error(location)
      return if location.nil?

      error = Error.new
      error.location = location
      @errors[location] ||= error
    end

    def with_matching_error(location: nil, id: nil)
      error = @errors[id] || @errors[location]
      yield error if error && block_given?
      error
    end

    def find_failures(log)
      log.scan(SPEC_FAILURES_PATTERN)
         .flatten
         .uniq
         .sort
         .each do |rerun_location|
        create_error(rerun_location)
      end
    end

    def find_failures_explanation(log)
      explanations = []
      log.split("\n").each do |line|
        if line.end_with?("Failures:") .. line.end_with?("Failed examples:")
          explanations << line
        end
      end
      explanations.map! { it[29..] } # Remove leading GitHub Actions log timestamp (e.g. "2024-02-05T08:37:54.5175930Z ")
      explanations.reject! do |line|
        line == "Failures:" ||
          line == "Failed examples:" ||
          line.include?("gems/rspec-retry-") ||
          line.include?("gems/webmock-")
      end
      @failures_explanation = explanations.join("\n")
    end

    def find_loading_errors(log)
      log.scan(SPEC_LOADING_ERRORS_PATTERN)
         .flatten
         .uniq
         .sort
         .each do |location|
        error = create_error(location)
        error.loading_error = true
      end
    end

    def find_screenshots(log)
      log.scan(SCREENSHOT_PATTERN)
         .map { JSON.parse(it) }
         .each do |screenshot_info|
        id = screenshot_info["test_id"]
        location = screenshot_info["test_location"]
        with_matching_error(location:, id:) do |error|
          error.page_html = screenshot_info["html"]
          error.page_screenshot = screenshot_info["image"]
        end
      end
    end

    def find_tests_groups(log)
      tests_groups = log
        .scan(TESTS_GROUP_PATTERN)
        .flatten
        .map.with_index(1) { |command, number| build_tests_group_from_command(command, number) }

      errors.each do |error|
        error.tests_group = tests_groups.find { it.include_error?(error) } || TestsGroup.null
      end
    end

    def find_merge_branch_info(log)
      merge_branch_sha = log.scan(BRANCH_MERGE_PATTERN).flatten.first
      @merge_branch_sha = merge_branch_sha if merge_branch_sha
    end

    def build_tests_group_from_command(line, number)
      tests_group = TestsGroup.new
      tests_group.test_env_number = number
      parts = line.split
      while parts.any?
        case part = parts.shift
        when "--seed"
          tests_group.seed = parts.shift
        when /_spec.rb$/
          tests_group.files << part
        end
      end
      tests_group
    end
  end
end
