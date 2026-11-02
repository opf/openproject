# frozen_string_literal: true

module TestManagement
  module Automation
    # Normalized ingest options (API metadata is camelCase; snake_case works too).
    class Options
      CASE_MATCHERS = %w[auto reference id property title].freeze
      SKIPPED_AS = %w[skipped untested blocked ignore].freeze
      FLAKY_AS = %w[passed failed retest].freeze
      # serverUrl (0015): the CI's server (CI_SERVER_URL, GITHUB_SERVER_URL, JENKINS_URL, CI_SYSTEM_URL),
      # sub-path included; used to tell gitlab.com and a self-hosted GitLab with the same path apart.
      CI_KEYS = %w[provider repository runUrl commitSha branch workflow runNumber runAttempt actor pullRequest
                   serverUrl].freeze
      MODES = %w[new_run new_iteration].freeze
      # Case steps after the failed step that were not reported (0020): "untested" (Not run) or "blocked".
      STEPS_AFTER_FAILURE = %w[untested blocked].freeze
      # testType (0016): kind of the reported tests; "e2e" qualifies written references "<repo>/e2e:".
      TEST_TYPES = %w[e2e unit integration component api other].freeze

      attr_reader :raw

      def initialize(raw = {})
        @raw = (raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw.to_h).deep_stringify_keys
        validate!
      end

      def format = value("format").presence || "auto"
      def run_id = value("runId").presence&.to_s
      # 0011: the iteration pre-created by "Run in CI" (OP_ITERATION_ID); must be the run's current one.
      def iteration_id = value("iterationId").presence&.to_s
      def external_ref = value("externalRef").presence&.to_s&.first(255)
      def run_name = value("runName").presence&.to_s&.first(255)
      def close_run? = truthy?(value("closeRun"))
      def case_matcher = value("caseMatcher").presence || "auto"
      # Opt-in only: missing/false leaves unmatched tests unmatched (does not create cases).
      def auto_create_cases? = truthy?(value("autoCreateCases"))
      def target_suite_id = value("targetSuiteId").presence&.to_i
      def update_references? = value("updateReferences").nil? || truthy?(value("updateReferences"))
      def add_matched_cases_to_run? = value("addMatchedCasesToRun").nil? || truthy?(value("addMatchedCasesToRun"))
      def skipped_as = value("skippedAs").presence || "skipped"
      def flaky_as = value("flakyAs").presence || "passed"
      def status_map = Hash(value("statusMap")).transform_keys { |k| k.to_s.downcase }.transform_values(&:to_s)
      def assign_failed_to = value("assignFailedTo").presence&.to_i
      def work_package_ids = Array(value("workPackageIds")).map { |id| id.to_s.delete_prefix("#").to_i }.select(&:positive?).uniq
      def labels = Array(value("labels")).map(&:to_s).compact_blank

      def test_type
        raw = value("testType").presence
        return unless raw

        raw.to_s.strip.downcase
      end

      def steps_after_failure = value("stepsAfterFailure").presence&.to_s || "untested"

      # How the upload is filed (0009). nil = take it from the CI connection, else new_run.
      #   new_run       – runId / externalRef / a new run (0008 behavior)
      #   new_iteration – a new iteration of runId or of the newest active run named targetRun
      def mode
        (value("mode").presence || value("runMode").presence)&.to_s
      end

      def target_run
        raw = value("targetRun").presence&.to_s&.strip
        raw&.first(255).presence
      end

      def connection_ref = value("connection").presence&.to_s&.strip

      def iteration_name
        raw = value("iterationName").presence&.to_s&.strip
        raw&.first(255).presence
      end

      # Milestone (0012) for runs created by this upload: id ("12", "M12") or name.
      def milestone_ref
        raw = value("milestone").presence&.to_s&.strip
        raw&.first(255).presence
      end

      # Relative paths of the uploaded attachments[] parts, in upload order. Lets the
      # server tell apart files with the same name (Playwright writes test-failed-1.png
      # for every failing test, each in its own folder).
      def attachment_paths = Array(value("attachmentPaths")).first(AttachmentWriter::MAX_FILES).map { |p| p.to_s.first(1024) }

      def ci
        hash = Hash(value("ci")).stringify_keys
        hash.slice(*CI_KEYS).transform_values { |v| v.to_s.first(1024) }.compact_blank
      end

      # What is stored on the import (no secrets are ever part of the options).
      def to_h
        {
          "format" => format, "runId" => run_id, "iterationId" => iteration_id, "externalRef" => external_ref, "closeRun" => close_run?,
          "caseMatcher" => case_matcher, "autoCreateCases" => auto_create_cases?, "skippedAs" => skipped_as,
          "flakyAs" => flaky_as, "statusMap" => status_map, "ci" => ci,
          "mode" => mode, "targetRun" => target_run, "connection" => connection_ref, "iterationName" => iteration_name,
          "milestone" => milestone_ref, "testType" => test_type, "stepsAfterFailure" => steps_after_failure
        }.compact
      end

      # Title for runs / iterations created from CI metadata ("E2E #128 · main@3f9c2d1"), nil without metadata.
      def ci_title
        return nil if ci["workflow"].blank? && ci["runNumber"].blank?

        name = "#{ci['workflow'].presence || 'Automation'} ##{ci['runNumber']}".strip
        ref = [ci["branch"], ci["commitSha"]&.first(7)].compact_blank.join("@")
        (ref.present? ? "#{name} · #{ref}" : name).first(255)
      end

      private

      def value(key)
        raw.key?(key) ? raw[key] : raw[key.underscore]
      end

      def truthy?(val)
        [true, "true", "1", 1, "yes", "on"].include?(val)
      end

      def validate!
        bad(:caseMatcher, CASE_MATCHERS) unless CASE_MATCHERS.include?(case_matcher)
        bad(:skippedAs, SKIPPED_AS) unless SKIPPED_AS.include?(skipped_as)
        bad(:flakyAs, FLAKY_AS) unless FLAKY_AS.include?(flaky_as)
        bad(:format, Parser::FORMATS) unless Parser::FORMATS.include?(format)
        bad(:mode, MODES) if mode && MODES.exclude?(mode)
        bad(:testType, TEST_TYPES) if test_type && TEST_TYPES.exclude?(test_type)
        bad(:stepsAfterFailure, STEPS_AFTER_FAILURE) unless STEPS_AFTER_FAILURE.include?(steps_after_failure)
        raise Error.new(:unprocessable, "iterationId must be a number") if iteration_id && !iteration_id.match?(/\A\d+\z/)

        invalid = status_map.values - TestRunCase::STATUSES - ["ignore"]
        raise Error.new(:unprocessable, "statusMap maps to unknown statuses: #{invalid.join(', ')}") if invalid.any?
      end

      def bad(key, allowed)
        raise Error.new(:unprocessable, "#{key} must be one of: #{allowed.join(', ')}")
      end
    end
  end
end
