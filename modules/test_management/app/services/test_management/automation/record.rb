# frozen_string_literal: true

module TestManagement
  module Automation
    # One reported test execution, normalized from any report format.
    # - reference: stable automation id, "<file>#<title path joined by ' › '>"
    # - raw_status: the status as reported (mapped by StatusMapper)
    # - properties: { "tm_case" => ["TC-12"], … } (annotations / JUnit properties)
    # - attachments: [{ "name", "path", "content_type" }] as listed in the report (step
    #   attachments included, so they are uploaded with the test's files)
    # - steps: [StepRecord] reported test steps (0020), top level; empty for formats without steps
    Record = Struct.new(:reference, :title, :title_path, :file, :raw_status, :duration_ms,
                        :message, :stack, :tags, :properties, :project_name, :retry,
                        :flaky, :attachments, :external_id, :case_ids, :steps,
                        keyword_init: true) do
      def initialize(**)
        super
        self.title_path ||= []
        self.tags ||= []
        self.properties ||= {}
        self.attachments ||= []
        self.case_ids ||= []
        self.steps ||= []
        self.flaky ||= false
        self.external_id ||= [reference, project_name.presence && "[#{project_name}]"].compact.join(" ")
      end

      def display_title
        title.presence || title_path.last.presence || reference
      end
    end
  end
end
