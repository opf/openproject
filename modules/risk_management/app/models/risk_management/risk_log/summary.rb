# frozen_string_literal: true

module RiskManagement
  module RiskLog
    class Summary
      WORKFLOW_STATUS_NAMES = BasicData::RiskManagement::Seeder::RISK_STATUSES.keys.freeze

      ACTIVE_STATUS_NAMES = ["New", "Evaluated", "Mitigation planned", "Mitigation done"].freeze
      MONITORING_STATUS_NAMES = ACTIVE_STATUS_NAMES
      ACTION_RESPONSE_NAMES = %w[Mitigate Avoid Transfer].freeze

      def initialize(scope:, configuration: Configuration.load, since: 7.days.ago, until_time: Time.current)
        @scope = scope
        @configuration = configuration
        @since = since
        @until_time = until_time
      end

      def counts
        current_counts
      end

      def workflow
        {
          statuses: active_statuses.map do |status|
            {
              id: status.id,
              name: status.name,
              current: active_risks.count { |risk| risk.status_id == status.id }
            }
          end,
          metrics:
        }
      end

      def dashboard
        {
          metrics: dashboard_metrics,
          top_risks: exposure_entries.first(5),
          workflow: workflow,
          attention: attention_items
        }
      end

      def dashboard_metrics
        {
          monitored: monitored_metric,
          total_exposure: total_exposure_metric,
          highest_exposure: highest_exposure_metric,
          requiring_attention: attention_metric
        }
      end

      def mitigation_coverage
        {
          owner_assigned: coverage_entry(owner_assigned_risks, active_risks),
          response_defined: coverage_entry(response_defined_risks, active_risks),
          mitigation_planned: coverage_entry(mitigation_planned_risks, mitigation_action_risks),
          mitigation_completed: coverage_entry(mitigation_completed_risks, mitigation_planned_risks)
        }
      end

      def attention_items
        {
          without_mitigation: attention_entry(without_mitigation_risks),
          without_owner: attention_entry(without_owner_risks),
          without_response: attention_entry(without_response_risks),
          mitigation_pending: attention_entry(mitigation_pending_risks),
          not_evaluated: attention_entry(not_evaluated_risks)
        }
      end

      def metrics
        denominator = active_risks.size

        {
          monitored: monitored_risks.size,
          high_and_critical: active_risks.count { |risk| high_or_critical?(risk) },
          newly_identified: active_risks.count { |risk| risk.created_at >= 7.days.ago },
          **mitigation_metrics("Mitigation planned", :mitigation_planned, denominator),
          **mitigation_metrics("Mitigation done", :mitigation_done, denominator)
        }
      end

      def entered_status_risk_ids(status_id)
        journals_by_risk.filter_map do |risk_id, journals|
          risk_id if entered_status?(journals, status_id.to_i)
        end
      end

      def left_status_risk_ids(status_id)
        journals_by_risk.filter_map do |risk_id, journals|
          risk_id if left_status?(journals, status_id.to_i)
        end
      end

      def status_by_category
        categories = RiskManagement::RiskCategory.active.order(:position).to_a

        {
          labels: categories.map(&:value),
          datasets: risk_statuses.map { |status| status_dataset(status, categories) }
        }
      end

      def response_status
        options = %w[mitigate accept avoid transfer]
        segments = options.map { |option| response_segment(option) }
        segments << unspecified_response_segment

        { total: monitored_risks.size, segments: }
      end

      def trend
        dates = (@since.to_date..@until_time.to_date).to_a
        counts_by_date = dates.map { |date| status_counts_on(date) }
        status_ids = counts_by_date.flat_map(&:keys).uniq

        {
          dates:,
          series: trend_series(status_ids, counts_by_date)
        }
      end

      def status_on(risk, date)
        boundary = date.end_of_day
        return if risk.created_at > boundary

        status_id = journals_by_risk.fetch(risk.id, []).filter_map do |journal|
          journal.data&.status_id if journal.created_at <= boundary
        end.last

        status_id || risk.status_id
      end

      private

      def exposure_entries
        @exposure_entries ||= active_risks.filter_map do |risk|
          assessment = assessment_for(risk)
          if assessment.risk_value
            {
              risk:,
              value: assessment.risk_value,
              likelihood: assessment.likelihood,
              impact: assessment.impact,
              response: response_name(risk)
            }
          end
        end
        @exposure_entries.sort_by! { |entry| -entry[:value] }
      end

      def metric_entry(value, risk_ids) = { value:, risk_ids: }

      def monitored_metric = metric_entry(active_risks.size, active_risks.map(&:id))

      def total_exposure_metric
        metric_entry(exposure_entries.sum { |entry| entry[:value] }, active_risks.map(&:id))
      end

      def highest_exposure_metric
        top_risk = exposure_entries.first
        metric_entry(top_risk&.fetch(:value, 0) || 0, Array(top_risk&.dig(:risk)&.id))
      end

      def attention_metric = metric_entry(attention_risk_ids.size, attention_risk_ids)

      def owner_assigned_risks = active_risks.select { |risk| risk.risk_owner_id.present? }
      def response_defined_risks = active_risks.select { |risk| response_defined?(risk) }
      def mitigation_planned_risks = mitigation_action_risks.select { |risk| mitigation_planned?(risk) }
      def mitigation_completed_risks = mitigation_planned_risks.select { |risk| risk.status.name == "Mitigation done" }
      def mitigation_pending_risks = mitigation_planned_risks - mitigation_completed_risks

      def coverage_entry(selected_risks, eligible_risks)
        {
          count: selected_risks.size,
          total: eligible_risks.size,
          percentage: percentage(selected_risks.size, eligible_risks.size),
          risk_ids: selected_risks.map(&:id),
          missing_count: eligible_risks.size - selected_risks.size,
          missing_risk_ids: (eligible_risks - selected_risks).map(&:id)
        }
      end

      def attention_entry(selected_risks)
        { count: selected_risks.size, risk_ids: selected_risks.map(&:id) }
      end

      def attention_risk_ids
        @attention_risk_ids ||= attention_items.values.flat_map { |item| item[:risk_ids] }.uniq
      end

      def without_owner_risks = active_risks.select { |risk| risk.risk_owner_id.nil? }
      def without_response_risks = active_risks.reject { |risk| response_defined?(risk) }
      def not_evaluated_risks = active_risks.reject { |risk| assessment_for(risk).evaluated? }

      def without_mitigation_risks
        mitigation_action_risks.reject { |risk| mitigation_planned?(risk) }
      end

      def mitigation_planned?(risk)
        ["Mitigation planned", "Mitigation done"].include?(risk.status.name)
      end

      def response_defined?(risk)
        risk.risk_response.present?
      end

      def mitigation_action_risks
        @mitigation_action_risks ||= active_risks.select do |risk|
          ACTION_RESPONSE_NAMES.include?(response_name(risk))
        end
      end

      def response_name(risk)
        risk.risk_response&.titleize
      end

      def active_risks
        @active_risks ||= risks.select { |risk| ACTIVE_STATUS_NAMES.include?(risk.status.name) }
      end

      def monitored_risks
        active_risks
      end

      def response_counts
        @response_counts ||= monitored_risks.filter_map do |risk|
          risk.risk_response.presence
        end.tally
      end

      def response_segment(option)
        {
          id: option,
          name: I18n.t("risk_management.risk_responses.#{option}"),
          count: response_counts.fetch(option, 0)
        }
      end

      def unspecified_response_segment
        {
          id: nil,
          name: I18n.t("risk_management.risk_log.response.not_specified"),
          count: monitored_risks.size - response_counts.values.sum
        }
      end

      def status_count(name)
        active_risks.count { |risk| risk.status.name == name }
      end

      def mitigation_metrics(status_name, key, denominator)
        count = status_count(status_name)
        { key => count, :"#{key}_percentage" => percentage(count, denominator) }
      end

      def percentage(count, total)
        return 0 if total.zero?

        (count.to_f / total * 100).round
      end

      def status_counts_on(date)
        risks.filter_map { |risk| status_on(risk, date) }.tally
      end

      def trend_series(status_ids, counts_by_date)
        Status.where(id: status_ids).order(:position).map do |status|
          { id: status.id, name: status.name, values: status_values(status.id, counts_by_date) }
        end
      end

      def status_values(status_id, counts_by_date)
        counts_by_date.map { |counts| counts.fetch(status_id, 0) }
      end

      def current_counts
        {
          total: risks.size,
          high: risks.count { |risk| high_or_critical?(risk) }
        }
      end

      def risks
        @risks ||= @scope.to_a
      end

      def high_or_critical?(risk)
        assessment_for(risk).high_or_critical?
      end

      def assessment_for(risk)
        Assessment.new(
          likelihood: risk.risk_likelihood,
          impact: risk.risk_impact,
          configuration: @configuration
        )
      end

      def category_ids_for(risk)
        risk.risk_category_ids.map(&:to_s)
      end

      def category_status_counts
        @category_status_counts ||= risks.each_with_object(Hash.new(0)) do |risk, counts|
          category_ids_for(risk).each { |category_id| counts[[category_id, risk.status_id]] += 1 }
        end
      end

      def status_dataset(status, categories)
        {
          label: status.name,
          data: categories.map { |category| category_status_counts[[category.id.to_s, status.id]] }
        }
      end

      def risk_statuses
        @risk_statuses ||= Status.where(name: WORKFLOW_STATUS_NAMES).order(:position).to_a
      end

      def active_statuses
        @active_statuses ||= risk_statuses.select { |status| ACTIVE_STATUS_NAMES.include?(status.name) }
      end

      def journals_by_risk
        @journals_by_risk ||= Journal
          .where(journable_type: "WorkPackage", journable_id: @scope.select(:id))
          .includes(:data)
          .order(:journable_id, :version)
          .group_by(&:journable_id)
      end

      def entered_status?(journals, target_status_id)
        events = status_events(journals)
        events.each_with_index.any? do |event, index|
          previous_status_id = index.zero? ? nil : events[index - 1][:status_id]
          event[:at].between?(@since, @until_time) &&
            event[:status_id] == target_status_id &&
            previous_status_id != target_status_id
        end
      end

      def left_status?(journals, target_status_id)
        status_events(journals).each_cons(2).any? do |previous, current|
          current[:at].between?(@since, @until_time) &&
            previous[:status_id] == target_status_id &&
            current[:status_id] != target_status_id
        end
      end

      def status_events(journals)
        journals.filter_map do |journal|
          status_id = journal.data&.status_id
          { status_id:, at: journal.created_at } if status_id
        end
      end
    end
  end
end
