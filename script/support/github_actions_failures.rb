# frozen_string_literal: true

require "json"

module GithubActionsFailures
  Result = Data.define(:errors, :failures_explanation, :merge_branch_sha)

  class Error
    attr_accessor :location, :page_html, :page_screenshot, :tests_group, :loading_error
  end

  class TestsGroup
    attr_accessor :test_env_number, :seed, :files

    # parallel tests run in `docker/ci/entrypoint.sh` does not output command
    # showing test groups, seeds and files anymore. Not sure how to fix it. Use
    # a null object when the information is not available to avoid errors in the
    # meantime.
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
    # Process 28: TEST_ENV_NUMBER=28 RUBYOPT=-I/usr/local/bundle/bundler/gems/turbo_tests-3148ae6c3482/lib -r/usr/local/bundle/gems/bundler-2.5.23/lib/bundler/setup -W0 RSPEC_SILENCE_FILTER_ANNOUNCEMENTS=1 /usr/local/bundle/gems/bundler-2.5.23/exe/bundle exec rspec --seed 52674 --format TurboTests::JsonRowsFormatter --out tmp/test-pipes/subprocess-28 --format ParallelTests::RSpec::RuntimeLogger --out spec/support/turbo_runtime_features.log spec/features/api_docs/index_spec.rb spec/features/custom_fields/reorder_options_spec.rb spec/features/projects/projects_portfolio_spec.rb spec/features/projects/template_spec.rb spec/features/versions/edit_spec.rb spec/features/work_packages/details/markdown/description_editor_spec.rb spec/features/work_packages/table/hierarchy/hierarchy_parent_below_spec.rb spec/features/work_packages/table/inline_create/inline_create_refresh_spec.rb spec/features/work_packages/table/invalid_query_spec.rb spec/features/work_packages/tabs/activity_revisions_spec.rb
    # rubocop:enable Layout/LineLength
    TESTS_GROUP_PATTERN = /Process \d+: TEST_ENV_NUMBER=\d+ [^\n]+$/
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
        .map { build_tests_group_from_command(it) }

      errors.each do |error|
        error.tests_group = tests_groups.find { it.include_error?(error) } || TestsGroup.null
      end
    end

    def find_merge_branch_info(log)
      merge_branch_sha = log.scan(BRANCH_MERGE_PATTERN).flatten.first
      @merge_branch_sha = merge_branch_sha if merge_branch_sha
    end

    def build_tests_group_from_command(line)
      tests_group = TestsGroup.new
      parts = line.split
      while parts.any?
        case part = parts.shift
        when /^TEST_ENV_NUMBER=/
          tests_group.test_env_number = part.delete_prefix("TEST_ENV_NUMBER=")
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
