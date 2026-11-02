# frozen_string_literal: true

module TestManagement
  module Automation
    module Parsers
      # Cucumber messages (NDJSON, `--format message`) (0020). Uses the envelopes
      #   gherkinDocument (feature name per uri), pickle { id, uri, name, tags, steps [{ id, text }] },
      #   testCase { id, pickleId, testSteps [{ id, pickleStepId | hookId }] },
      #   testCaseStarted { id, testCaseId, attempt }, testStepFinished { testCaseStartedId, testStepId,
      #   testStepResult { status, duration { seconds, nanos }, message, exception { type, message, stackTrace } } },
      #   testCaseFinished { testCaseStartedId, willBeRetried }.
      # One Record per test case, from its last attempt ("flaky" when an earlier attempt failed).
      # Same reference as Cucumber JSON: "<uri>#<feature> › <scenario>". Step titles are the pickle
      # step texts (without the Gherkin keyword). Attachments in messages are not imported.
      class CucumberMessages
        TYPES = %w[meta source gherkinDocument pickle stepDefinition hook testRunStarted testCase testCaseStarted
                   testStepStarted testStepFinished testCaseFinished testRunFinished attachment parameterType
                   undefinedParameterType parseError testRunHookStarted testRunHookFinished].freeze
        MAX_LINE = 5 * 1024 * 1024

        def self.detect?(content)
          first = content.to_s.each_line.lazy.map(&:strip).reject(&:empty?).first
          return false unless first&.start_with?("{")

          envelope = JSON.parse(first)
          envelope.is_a?(Hash) && envelope.size == 1 && TYPES.include?(envelope.keys.first)
        rescue JSON::ParserError
          false
        end

        def initialize(content)
          @features = {}
          @pickles = {}
          @test_cases = {}
          @started = {}
          @finished = Hash.new { |h, k| h[k] = [] }
          @retried = {}
          content.to_s.each_line.with_index(1) { |line, number| read(line, number) }
          raise Error.new(:unprocessable, "Not a Cucumber messages report (no test cases).") if @test_cases.empty?
        end

        def records
          attempts = @started.values.group_by { |started| started["testCaseId"] }
          @test_cases.filter_map do |id, test_case|
            pickle = @pickles[test_case["pickleId"]]
            runs = Array(attempts[id]).sort_by { |s| s["attempt"].to_i }
            next if pickle.nil? || runs.empty?

            build(pickle, test_case, runs)
          end
        end

        private

        def read(line, number)
          line = line.strip
          return if line.empty?
          raise Error.new(:payload_too_large, "Line #{number} of the report is too long.") if line.bytesize > MAX_LINE

          envelope = Json.load(line)
          return unless envelope.is_a?(Hash)

          if (doc = envelope["gherkinDocument"]) then @features[doc["uri"]] = doc.dig("feature", "name").to_s
          elsif (pickle = envelope["pickle"]) then @pickles[pickle["id"]] = pickle
          elsif (test_case = envelope["testCase"]) then @test_cases[test_case["id"]] = test_case
          elsif (started = envelope["testCaseStarted"]) then @started[started["id"]] = started
          elsif (finished = envelope["testStepFinished"]) then @finished[finished["testCaseStartedId"]] << finished
          elsif (done = envelope["testCaseFinished"]) then @retried[done["testCaseStartedId"]] = done["willBeRetried"] == true
          end
        end

        def build(pickle, test_case, runs)
          last = runs.reject { |run| @retried[run["id"]] }.last || runs.last
          steps = steps_for(pickle, test_case, last)
          status = Cucumber.scenario_status(steps.map(&:raw_status))
          earlier_failed = (runs - [last]).any? do |run|
            Cucumber.scenario_status(steps_for(pickle, test_case, run).map(&:raw_status)) == "failed"
          end
          status = "flaky" if status == "passed" && earlier_failed
          failed = steps.find { |step| step.raw_status == "failed" } ||
                   steps.find { |step| %w[undefined ambiguous].include?(step.raw_status) }
          title_path = [@features[pickle["uri"]].to_s, pickle["name"].to_s].compact_blank
          tags = Array(pickle["tags"]).filter_map { |tag| tag["name"] if tag.is_a?(Hash) }

          Record.new(
            reference: "#{pickle['uri']}##{title_path.join(PlaywrightJson::SEPARATOR)}",
            title: pickle["name"].to_s,
            title_path:,
            file: pickle["uri"]&.to_s,
            raw_status: status,
            flaky: status == "flaky",
            duration_ms: steps.sum { |step| step.duration_ms.to_i },
            message: failed&.message,
            stack: Json.clean(failed&.stack, Steps::TRACE_LIMIT * 2),
            tags:,
            properties: Cucumber.tag_properties(tags),
            retry: runs.index(last).to_i,
            steps: steps.reject { |step| step.hook && step.raw_status == "passed" }
          )
        end

        def steps_for(pickle, test_case, run)
          texts = Array(pickle["steps"]).to_h { |step| [step["id"], step["text"].to_s] }
          results = @finished[run["id"]].to_h { |finished| [finished["testStepId"], finished["testStepResult"] || {}] }
          Steps.tree(
            Array(test_case["testSteps"]),
            build: lambda do |test_step|
              result = results[test_step["id"]] || { "status" => "UNKNOWN" }
              exception = result["exception"].is_a?(Hash) ? result["exception"] : {}
              hook = test_step["hookId"].present?
              { title: hook ? "Hook" : texts[test_step["pickleStepId"]], raw_status: result["status"].to_s.downcase,
                duration_ms: duration(result["duration"]),
                message: exception["message"].presence || result["message"].to_s.lines.first,
                stack: exception["stackTrace"].presence || result["message"], hook: }
            end,
            children: ->(_) { [] }
          )
        end

        def duration(value)
          return nil unless value.is_a?(Hash)

          (value["seconds"].to_i * 1000) + (value["nanos"].to_i / 1_000_000)
        end
      end
    end
  end
end
