# frozen_string_literal: true

module DemoData
  module RiskManagement
    class RisksSeeder < ::Seeder
      self.needs = [BasicData::RiskManagement::Seeder]

      RISKS = [
        ["Critical supplier becomes unavailable", 78, 650_000, ["Operational", "Financial"], "Mitigate", :occurred, 35,
         [28, 18, 9, 4]],
        ["Key specialist leaves the project", 55, 300_000, ["Resources & people"], "Mitigate", :mitigation_done, 32,
         [25, 16, 5]],
        ["Security vulnerability in a core dependency", 85, 700_000, ["Information security", "Technical"], "Mitigate",
         :mitigation_planned, 29, [21, 6]],
        ["Regulatory requirement changes", 35, 800_000, ["Legal & compliance"], "Accept", :evaluated, 26, [18]],
        ["Integration interface is delivered late", 72, 85_000, ["Schedule & planning", "Technical"], "Avoid", :rejected,
         23, [15, 2]],
        ["Project budget is exceeded", 58, 420_000, ["Financial"], "Mitigate", :mitigation_planned, 20, [12, 3]],
        ["Selected architecture does not scale", 28, 900_000, ["Technical", "Strategic"], "Mitigate", :occurred, 17,
         [10, 7, 3, 1]],
        ["Stakeholder priorities change", 48, 75_000, ["Strategic"], "Accept", :evaluated, 14, [8]],
        ["Test environment is temporarily unavailable", 44, 35_000, ["Technical", "Operational"], "Mitigate",
         :mitigation_done, 11, [9, 6, 2]],
        ["Approval takes longer than planned", 32, 70_000, ["Schedule & planning"], "Transfer", :mitigation_planned, 8,
         [4, 1]],
        ["Minor delay in an external delivery", 22, 30_000, ["Operational"], "Accept", :evaluated, 4, [2]],
        ["Low-impact documentation gap", 10, 5_000, ["Legal & compliance"], nil, :new, 0, []]
      ].freeze

      def seed_data!
        return unless project && configuration.valid?

        activate_risk_log
        RISKS.each { |risk_data| seed_risk(*risk_data) }
        seed_risk_management_plan
      end

      def applicable?
        project.present? && configuration.valid? && risk_type.present?
      end

      def not_applicable_message
        "Skipping example risks because no risk type is configured"
      end

      private

      def project
        @project ||= Project.active.joins(:enabled_modules)
          .where(enabled_modules: { name: "work_package_tracking" })
          .order(:id)
          .first
      end

      def configuration
        @configuration ||= ::RiskManagement::Configuration.load
      end

      def risk_type
        @risk_type = Type.find_by(id: configuration.risk_type_id) unless defined?(@risk_type)
        @risk_type
      end

      def activate_risk_log
        project.enabled_module_names |= ["risk_log"]
        OpenProject::RiskManagement::Engine.synchronize_risk_type(project, enabled: true)
      end

      def seed_risk(subject, likelihood, impact, categories, response, status_kind, created_days_ago, transition_days)
        risk = WorkPackage.find_or_initialize_by(project:, type: risk_type, subject:)
        new_record = risk.new_record?
        attributes = risk_attributes(subject, likelihood, impact, categories, response, new_record ? :new : status_kind)
        risk.assign_attributes(attributes)
        risk.save!
        seed_history(risk, status_kind, created_days_ago, transition_days, create_transitions: new_record)
      end

      def risk_attributes(subject, likelihood, impact, categories, response, status_kind)
        {
          project:,
          type: risk_type,
          subject:,
          author: admin_user,
          risk_owner: risk_owner(subject),
          assigned_to: assigned_to(subject),
          status: risk_status(status_kind),
          priority: IssuePriority.default,
          risk_likelihood: likelihood,
          risk_impact: impact,
          risk_category_ids: category_ids(categories),
          risk_response: response&.downcase
        }
      end

      def assigned_to(subject)
        admin_user unless subject == "Low-impact documentation gap"
      end

      def risk_owner(subject)
        return if ["Regulatory requirement changes", "Low-impact documentation gap"].include?(subject)

        admin_user
      end

      def risk_status(status_kind)
        Status.find_by!(name: status_kind.to_s.humanize)
      end

      def category_ids(categories)
        ::RiskManagement::RiskCategory.where(name: categories).pluck(:id)
      end

      def seed_risk_management_plan
        ::RiskManagement::Plan.find_or_initialize_by(project:).tap do |plan|
          plan.assign_attributes(
            author: admin_user,
            updated_by: admin_user,
            body: <<~MARKDOWN
              # Risk management plan

              ## Purpose and objectives
              This plan defines how risks are identified, assessed, owned, treated, and monitored in the demo project.

              ## Roles and responsibilities
              The project manager maintains this plan. Every monitored risk has one risk owner. Assignees may clarify
              questions or carry out follow-up work without taking over the owner's accountability.

              ## Identification and assessment
              Risks are reviewed during the weekly project meeting. Likelihood is recorded as a percentage and impact
              in the system currency. Exposure is calculated as likelihood multiplied by impact.

              ## Response and monitoring
              The available responses are Mitigate, Accept, Avoid, and Transfer. Open risks are reviewed weekly and
              mitigation actions are tracked as related work packages.
            MARKDOWN
          )
          plan.save!
        end
      end

      def seed_history(risk, status_kind, created_days_ago, transition_days, create_transitions:)
        created_at = created_days_ago.days.ago.beginning_of_hour
        backdate_creation(risk, created_at)
        return unless create_transitions

        transition_path(status_kind).zip(transition_days).each do |transition_status, days_ago|
          backdate_transition(risk, transition_status, days_ago.days.ago.beginning_of_hour)
        end
      end

      def backdate_creation(risk, created_at)
        risk.update_columns(created_at:, updated_at: created_at)
        risk.journals.order(:version).first&.update_columns(created_at:, updated_at: created_at)
      end

      def backdate_transition(risk, status_kind, transitioned_at)
        risk.update!(status: risk_status(status_kind))
        risk.update_columns(updated_at: transitioned_at)
        risk.journals.order(:version).last&.update_columns(created_at: transitioned_at, updated_at: transitioned_at)
      end

      def transition_path(status_kind)
        case status_kind
        when :evaluated
          %i[evaluated]
        when :mitigation_planned
          %i[evaluated mitigation_planned]
        when :mitigation_done
          %i[evaluated mitigation_planned mitigation_done]
        when :occurred
          %i[evaluated mitigation_planned mitigation_done occurred]
        when :rejected
          %i[evaluated rejected]
        else
          []
        end
      end
    end
  end
end
