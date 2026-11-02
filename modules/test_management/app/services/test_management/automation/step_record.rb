# frozen_string_literal: true

module TestManagement
  module Automation
    # One reported test step (0020), normalized from any report format.
    # - raw_status: as reported ("passed", "failed", "broken", "SKIPPED", …), mapped by StepMatcher
    # - marker: explicit case step number (1-based) from the "[step:3]" title marker or the
    #   format's own field (Allure parameter / native "step"); nil when not given
    # - hook: a setup/teardown hook (Cucumber Before/After); never matched to a case step
    # - attachments: [{ "name", "path", "content_type" }] as listed in the report
    StepRecord = Struct.new(:title, :raw_status, :duration_ms, :message, :stack, :attachments, :steps, :marker, :hook,
                            keyword_init: true) do
      def initialize(**)
        super
        self.attachments ||= []
        self.steps ||= []
        self.hook ||= false
        self.marker ||= StepMarker.position_in(title)
        self.title = StepMarker.strip(title)
      end

      # This step and all sub-steps, depth first.
      def each_step(&)
        return enum_for(:each_step) unless block_given?

        yield self
        steps.each { |child| child.each_step(&) }
      end

      def marked_below?
        steps.any? { |child| child.marker || child.marked_below? }
      end
    end
  end
end
