# frozen_string_literal: true

module TestManagement
  module Automation
    # Maps the reported steps of one test to the steps of a test case (0020) and returns the
    # TestStepResult attributes to store.
    #
    # Priority (documented in docs/ci/README.md#test-steps):
    # 1. marker – a reported step (at any depth) titled "[step:3] …" / "@S3 …" or with the format's
    #    step field (native "step", Allure parameter "tm_step") belongs to case step 3. When any
    #    step has a marker, the steps without one are matched by title only.
    # 2. position – no markers and as many top-level reported steps (hooks left out) as the case
    #    has steps: the n-th reported step is case step n.
    # 3. title – otherwise each top-level step goes to the case step whose action is most similar
    #    (Gherkin keyword, case and punctuation ignored; similarity >= TITLE_THRESHOLD).
    # Several reported steps on one case step: the worst status wins. Reported steps that match no
    # case step are kept as "reported" rows. Case steps without a reported step are "untested"
    # (shown as "Not run"); with stepsAfterFailure "blocked", those after the failed step are blocked.
    # Nothing is written for a test without reported steps; when no reported step matches, only the
    # reported rows are written.
    class StepMatcher
      TITLE_THRESHOLD = 0.7
      MAX_REPORTED_ROWS = 50
      GHERKIN_KEYWORD = /\A\s*(given|when|then|and|but|\*)\s+/i

      STEP_STATUSES = {
        "passed" => "passed", "pass" => "passed", "ok" => "passed", "success" => "passed",
        "failed" => "failed", "fail" => "failed", "failure" => "failed", "broken" => "failed", "error" => "failed",
        "timedout" => "failed", "timed_out" => "failed", "undefined" => "failed", "ambiguous" => "failed",
        "skipped" => "skipped", "skip" => "skipped", "pending" => "skipped", "disabled" => "skipped",
        "blocked" => "blocked", "interrupted" => "blocked",
        "untested" => "untested", "unknown" => "untested", "not_run" => "untested"
      }.freeze

      Unit = Struct.new(:step, :via, :index, keyword_init: true) do
        def assign(index:, via:)
          self.index = index
          self.via = via
        end
      end

      def self.step_status(raw)
        STEP_STATUSES.fetch(raw.to_s.strip.downcase, "untested")
      end

      def self.normalize(text)
        StepMarker.strip(text.to_s).sub(GHERKIN_KEYWORD, "").downcase.gsub(/[^\p{Alnum}]+/, " ").strip
      end

      # Sørensen–Dice coefficient on character bigrams (1.0 for equal texts).
      def self.similarity(left, right)
        a = normalize(left)
        b = normalize(right)
        return 0.0 if a.empty? || b.empty?
        return 1.0 if a == b
        return 0.9 if [a, b].min_by(&:length).length >= 8 && (a.include?(b) || b.include?(a))

        x = bigrams(a)
        y = bigrams(b)
        return 0.0 if x.empty? || y.empty?

        common = x.tally.sum { |gram, count| [count, y.count(gram)].min }
        (2.0 * common) / (x.size + y.size)
      end

      def self.bigrams(text)
        text.delete(" ").chars.each_cons(2).map(&:join)
      end

      def initialize(case_steps:, steps_after_failure: "untested")
        @case_steps = case_steps.sort_by { |step| [step.position.to_i, step.id.to_i] }
        @steps_after_failure = steps_after_failure
      end

      # Returns [{ kind:, test_step:, position:, status:, ... }] (TestStepResult attributes plus
      # "attachments" with report paths in details, resolved to attachment ids by the caller).
      def call(reported_steps)
        return [] if reported_steps.blank?

        units, extra = collect_units(reported_steps)
        assign(units)
        matched = units.select(&:index)
        rows = matched.any? ? case_rows(matched) : []
        unmatched = units.reject(&:index) + extra
        rows + reported_rows(unmatched, rows.size)
      end

      private

      attr_reader :case_steps

      # Units are the reported steps that take part in matching: marked steps at any depth and the
      # top-level steps without marked sub-steps. `extra` are steps never matched (hooks, failed
      # containers of marked steps).
      def collect_units(reported_steps)
        units = []
        extra = []
        reported_steps.each do |top|
          if top.hook
            extra << Unit.new(step: top)
          elsif top.marker || !top.marked_below?
            units << Unit.new(step: top)
          else
            marked = marked_steps(top)
            units.concat(marked.map { |step| Unit.new(step:) })
            failed_inside = marked.any? { |step| status(step) == "failed" }
            extra << Unit.new(step: top) if status(top) == "failed" && !failed_inside
          end
        end
        [units, extra]
      end

      def marked_steps(step)
        step.steps.flat_map { |child| child.marker ? [child] : marked_steps(child) }
      end

      def assign(units)
        return if case_steps.empty?

        if units.any? { |unit| unit.step.marker }
          units.each do |unit|
            next unless unit.step.marker

            index = unit.step.marker - 1
            unit.assign(index:, via: "marker") if index < case_steps.size
          end
          by_title(units.reject { |unit| unit.step.marker })
        elsif units.size == case_steps.size
          units.each_with_index { |unit, index| unit.assign(index:, via: "position") }
        else
          by_title(units)
        end
      end

      def by_title(units)
        units.each do |unit|
          scores = case_steps.each_with_index.map { |step, index| [self.class.similarity(unit.step.title, step.action), index] }
          score, index = scores.max_by { |value, i| [value, -i] }
          unit.assign(index:, via: "title") if score && score >= TITLE_THRESHOLD
        end
      end

      def case_rows(matched)
        by_index = matched.group_by(&:index)
        failed_at = matched.select { |unit| status(unit.step) == "failed" }.map(&:index).min

        case_steps.each_with_index.map do |step, index|
          units = by_index.fetch(index, [])
          base = { kind: "case", test_step: step, position: index, step_action: step.action.to_s.first(TestStepResult::TITLE_LIMIT) }
          next base.merge(status: missing_status(index, failed_at)) if units.empty?

          base.merge(unit_attributes(units)).merge(match_method: units.first.via)
        end
      end

      def missing_status(index, failed_at)
        failed_at && index > failed_at && @steps_after_failure == "blocked" ? "blocked" : "untested"
      end

      def reported_rows(units, offset)
        units.first(MAX_REPORTED_ROWS).each_with_index.map do |unit, index|
          { kind: "reported", position: offset + index }.merge(unit_attributes([unit]))
            .tap { |row| row[:details]["hook"] = true if unit.step.hook }
        end
      end

      def unit_attributes(units)
        steps = units.map(&:step)
        failed = steps.find { |step| status(step) == "failed" } || steps.find { |step| step.message.present? }
        substeps = steps.flat_map { |step| step.steps.flat_map { |child| child.each_step.to_a } }
        attachments = steps.flat_map { |step| step.each_step.flat_map(&:attachments) }.uniq { |a| a["path"] }
        details = {}
        details["substeps"] = substeps.first(TestStepResult::SUBSTEP_LIMIT).map { |sub| substep_hash(sub) } if substeps.any?
        details["attachments"] = attachments.first(20).map { |a| a.slice("name", "path") } if attachments.any?
        details["reported"] = steps.map(&:title).first(20) if steps.size > 1
        durations = steps.filter_map(&:duration_ms)
        {
          status: TestStepResult.worst_status(steps.map { |step| status(step) }),
          reported_title: steps.map(&:title).compact_blank.join(" · ").first(TestStepResult::TITLE_LIMIT).presence,
          duration_ms: durations.any? ? durations.sum : nil,
          error_message: failed&.message&.first(TestStepResult::MESSAGE_LIMIT),
          error_trace: failed&.stack&.first(TestStepResult::TRACE_LIMIT),
          details:
        }
      end

      def substep_hash(step)
        { "title" => step.title.to_s.first(300), "status" => status(step), "durationMs" => step.duration_ms,
          "error" => step.message.to_s.lines.first.to_s.strip.first(300).presence }.compact
      end

      def status(step)
        self.class.step_status(step.raw_status)
      end
    end
  end
end
