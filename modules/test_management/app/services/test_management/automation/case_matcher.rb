# frozen_string_literal: true

module TestManagement
  module Automation
    # Finds the test case(s) for each record. Strategies (caseMatcher):
    # - property: annotations / JUnit properties tm_case, test_id, case_id, testcase ("TC-12, TC-13" lists)
    # - reference: case.automation_reference == record.reference; with a known repository (0016)
    #   "<name>:<reference>" and "<name>/e2e:<reference>" first (Automation::Reference::Context)
    # - id: "<prefix>-<id>" (e.g. TC-12, @TC12) in tags, then in the title; native caseId
    # - title: exact (case-insensitive) title – opt-in only, never part of "auto"
    # - auto: property → reference → id
    # Only non-deleted cases of the project are matched.
    class CaseMatcher
      PROPERTY_KEYS = %w[tm_case tm_case_id test_id case_id testcase].freeze
      Match = Struct.new(:cases, :matched_by, :reason, keyword_init: true)

      def initialize(project:, strategy: "auto", references: nil)
        @project = project
        @strategy = strategy
        @references = references || Reference::Context.new(project:)
      end

      def call(records)
        preload(records)
        records.map { |record| match(record) }
      end

      private

      attr_reader :project, :strategy, :references

      def match(record)
        foreign = false
        steps.each do |step|
          ids_or_cases = send(:"by_#{step}", record)
          next if ids_or_cases.blank?

          cases, missing = resolve(ids_or_cases)
          foreign ||= missing
          return Match.new(cases:, matched_by: step) if cases.any?
        end
        Match.new(cases: [], reason: foreign ? "case_not_in_project" : "no_matching_case")
      end

      def steps
        strategy == "auto" ? %w[property reference id] : [strategy]
      end

      def resolve(list)
        cases = list.filter_map { |item| item.is_a?(Integer) ? @cases_by_id[item] : item }.uniq
        [cases, cases.size < list.size]
      end

      def by_property(record)
        PROPERTY_KEYS.flat_map { |key| Array(record.properties[key]) }
                     .flat_map { |value| value.to_s.split(/[,;\s]+/) }
                     .filter_map { |token| token[/\d+/]&.to_i }
                     .uniq
      end

      def by_reference(record)
        return [] if record.reference.blank?

        found = references.candidates(record.reference).lazy.filter_map { |candidate| @cases_by_ref[candidate] }.first
        [found].compact
      end

      def by_id(record)
        ids = record.case_ids.filter_map { |value| value.to_s[/\d+/]&.to_i }
        ids = ids_in(record.tags.join(" ")) if ids.empty?
        ids = ids_in(record.title.to_s) if ids.empty?
        ids.uniq
      end

      def by_title(record)
        [@cases_by_title[record.display_title.to_s.downcase.strip]].compact
      end

      def ids_in(text)
        text.scan(id_pattern).flatten.map(&:to_i)
      end

      def id_pattern
        @id_pattern ||= begin
          prefixes = [setting_prefix, default_prefix, "TC"].compact_blank.map { |p| Regexp.escape(p) }.uniq
          /(?:^|[\s@\[(])(?:#{prefixes.join('|')})-?(\d+)\b/i
        end
      end

      def setting_prefix
        TestManagement::ProjectSetting.find_by(project_id: project.id)&.display_prefix
      rescue StandardError
        nil
      end

      def default_prefix
        Setting.plugin_openproject_test_management["default_display_prefix"]
      rescue StandardError
        nil
      end

      def scope
        project.tm_test_cases.not_deleted
      end

      def preload(records)
        refs = records.filter_map(&:reference).flat_map { |reference| references.candidates(reference) }.uniq
        @cases_by_ref = refs.any? ? scope.where(automation_reference: refs).index_by(&:automation_reference) : {}
        ids = records.flat_map { |r| by_property(r) + (strategy.in?(%w[auto id]) ? by_id(r) : []) }.uniq
        @cases_by_id = ids.any? ? scope.where(id: ids).index_by(&:id) : {}
        @cases_by_title = if strategy == "title"
                            titles = records.map { |r| r.display_title.to_s.downcase.strip }.uniq
                            scope.where("LOWER(tm_test_cases.title) IN (?)", titles)
                                 .order(:id).to_a.reverse.index_by { |c| c.title.downcase.strip }
                          else
                            {}
                          end
      end
    end
  end
end
