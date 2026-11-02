# frozen_string_literal: true

module TestManagement
  # A Test Assistant "Generate" request (0014): the source (work package, free text, pull request
  # or code snippet), the options, and the draft test cases the AI provider returned. Drafts are
  # only suggestions; nothing is written to the case library until the user saves selected drafts.
  # When the job finishes, `usage` holds the provider token counts from that chat call.
  # A generation belongs to the user who asked for it and is only shown to that user.
  class AssistantGeneration < ApplicationRecord
    self.table_name = "tm_assistant_generations"

    STATUSES = %w[queued running done failed cancelled].freeze
    # Phases shown while polling; progress bar uses index/count until writing_drafts uses case counts.
    PROGRESS_STEPS = %w[queued preparing_source waiting_for_model writing_drafts].freeze
    SOURCE_TYPES = %w[work_package text pull_request code].freeze
    CASE_TYPES = %w[positive negative edge boundary security accessibility usability].freeze
    DEFAULT_CASE_TYPES = %w[positive negative edge].freeze
    MAX_COUNT = 20
    DEFAULT_COUNT = 5
    # A request still queued/running after this long is treated as failed (worker down or killed).
    STALE_AFTER = 10.minutes

    belongs_to :project
    belongs_to :user
    # 0021: the saved provider asked (nil when it was deleted or for requests before 0021)
    belongs_to :provider, class_name: "TestManagement::AssistantProvider", optional: true

    validates :status, inclusion: { in: STATUSES }
    validates :source_type, inclusion: { in: SOURCE_TYPES }

    scope :ordered, -> { order(created_at: :desc, id: :desc) }

    def self.of(user, project)
      where(user_id: user.id, project_id: project.id)
    end

    def pending?
      %w[queued running].include?(status) && !stale?
    end

    def stale?
      %w[queued running].include?(status) && updated_at.present? && updated_at < STALE_AFTER.ago
    end

    def effective_status
      stale? ? "failed" : status
    end

    def effective_error
      stale? ? I18n.t("test_management.assistant.errors.timed_out") : error
    end

    def done?
      status == "done"
    end

    def cancelled?
      status == "cancelled"
    end

    def failed?
      effective_status == "failed"
    end

    # JSON polling payload: maps DB "done" to API "succeeded".
    def status_payload
      state = case effective_status
              when "done" then "succeeded"
              else effective_status
              end
      step = current_progress_step(state)
      {
        state:,
        step:,
        step_index: PROGRESS_STEPS.index(step)&.+(1) || 1,
        step_count: PROGRESS_STEPS.size,
        progress: progress_payload(step),
        message: status_message(state, step),
        started_at: created_at&.iso8601,
        updated_at: updated_at&.iso8601,
        error: state == "failed" ? effective_error : nil
      }.tap { |payload| payload[:usage] = usage_payload if usage_payload }
    end

    # Token counts from the provider response (nil until the job finishes successfully).
    def usage_payload
      data = (usage || {}).stringify_keys
      return nil if data.blank?

      {
        "prompt_tokens" => data["prompt_tokens"],
        "completion_tokens" => data["completion_tokens"],
        "total_tokens" => data["total_tokens"],
        "reasoning_tokens" => data["reasoning_tokens"]
      }.compact.presence
    end

    def current_progress_step(state = nil)
      state ||= case effective_status
                when "done" then "succeeded"
                else effective_status
                end
      return "writing_drafts" if state == "succeeded"
      return progress_step if PROGRESS_STEPS.include?(progress_step)

      state == "queued" ? "queued" : "preparing_source"
    end

    def progress_payload(step = current_progress_step)
      if step == "writing_drafts" && progress_total.present?
        return { done: progress_done.to_i, total: progress_total.to_i }
      end

      index = PROGRESS_STEPS.index(step) || 0
      { done: index, total: PROGRESS_STEPS.size }
    end

    def status_message(state = nil, step = nil)
      state ||= case effective_status
                when "done" then "succeeded"
                else effective_status
                end
      step ||= current_progress_step(state)
      case state
      when "succeeded"
        I18n.t("test_management.assistant.generate.polling.succeeded", count: draft_list.size)
      when "failed" then I18n.t("test_management.assistant.generate.failed", error: effective_error)
      when "cancelled" then I18n.t("test_management.assistant.generate.polling.cancelled")
      else
        step_message(step)
      end
    end

    def step_message(step)
      case step
      when "queued"
        I18n.t("test_management.assistant.generate.polling.steps.queued")
      when "preparing_source"
        I18n.t("test_management.assistant.generate.polling.steps.preparing_source")
      when "waiting_for_model"
        I18n.t("test_management.assistant.generate.polling.steps.waiting_for_model")
      when "writing_drafts"
        if progress_total.present?
          I18n.t("test_management.assistant.generate.polling.steps.writing_drafts_progress",
                 done: progress_done.to_i, total: progress_total.to_i)
        else
          I18n.t("test_management.assistant.generate.polling.steps.writing_drafts")
        end
      else
        I18n.t("test_management.assistant.generate.polling.running")
      end
    end

    def source_data
      (source || {}).stringify_keys
    end

    def option(key)
      (options || {}).stringify_keys[key.to_s]
    end

    def count
      option(:count).to_i.clamp(1, MAX_COUNT)
    end

    def case_types
      types = Array(option(:types)).map(&:to_s) & CASE_TYPES
      types.presence || DEFAULT_CASE_TYPES
    end

    def suite_id
      option(:suite_id).presence&.to_i
    end

    def label_names
      Array(option(:label_names)).map(&:to_s)
    end

    def work_package_id
      source_type == "work_package" ? source_data["work_package_id"].presence&.to_i : nil
    end

    def work_package
      return nil unless work_package_id

      if defined?(@work_package)
        @work_package
      else
        @work_package = ::WorkPackage.find_by(id: work_package_id)
      end
    end

    def pull_request_url
      source_type == "pull_request" ? source_data["url"].presence : nil
    end

    def draft_list
      Array(drafts).map { |draft| draft.to_h.stringify_keys }
    end

    def saved_ids
      Array(saved_case_ids).map(&:to_i)
    end
  end
end
