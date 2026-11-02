# frozen_string_literal: true

module TestManagement
  module AssistantHelper
    def tm_assistant_admin_link
      test_management_admin_settings_path(anchor: "tm-assistant-providers")
    end

    def tm_assistant_status_scheme(status)
      { "done" => :success, "succeeded" => :success, "failed" => :danger, "running" => :accent,
        "queued" => :secondary, "cancelled" => :secondary }[status] || :secondary
    end

    def tm_assistant_generation_polling_data(project, generation)
      {
        controller: "test-management--generation-status",
        test_management__generation_status_url_value:
          project_test_management_assistant_generation_status_path(project, generation),
        test_management__generation_status_cancel_url_value:
          project_test_management_cancel_assistant_generation_path(project, generation),
        test_management__generation_status_retry_url_value:
          project_test_management_retry_assistant_generation_path(project, generation),
        test_management__generation_status_interval_value: 2500,
        test_management__generation_status_timeout_value: 300_000,
        test_management__generation_status_frame_id_value: "tm-draft-results",
        test_management__generation_status_frame_url_value:
          project_test_management_assistant_generation_path(project, generation),
        test_management__generation_status_pending_message_value: t("test_management.assistant.generate.polling.running"),
        test_management__generation_status_progress_message_value: t("test_management.assistant.generate.polling.progress_template"),
        test_management__generation_status_succeeded_message_value: t("test_management.assistant.generate.polling.succeeded_template"),
        test_management__generation_status_failed_message_value: t("test_management.assistant.generate.failed_template"),
        test_management__generation_status_cancelled_message_value: t("test_management.assistant.generate.polling.cancelled"),
        test_management__generation_status_timeout_message_value: t("test_management.assistant.generate.polling.timeout"),
        test_management__generation_status_reconnect_message_value: t("test_management.assistant.generate.polling.reconnecting"),
        test_management__generation_status_working_message_value: t("test_management.assistant.generate.polling.working"),
        test_management__generation_status_last_update_message_value: t("test_management.assistant.generate.polling.last_update"),
        test_management__generation_status_check_again_value: t("test_management.assistant.generate.polling.check_again"),
        test_management__generation_status_try_again_value: t("test_management.assistant.generate.try_again"),
        test_management__generation_status_cancel_label_value: t("test_management.assistant.generate.polling.cancel")
      }
    end

    # Plain text from the model or the user, escaped, with line breaks.
    def tm_assistant_text(text)
      simple_format(h(text.to_s), {}, sanitize: false)
    end

    def tm_assistant_record_link(project, record)
      record = record.to_h.stringify_keys
      path = case record["type"]
             when "test_run" then project_test_management_test_run_path(project, record["id"])
             when "milestone" then project_test_management_milestone_path(project, record["id"])
             when "test_case" then project_test_management_test_case_path(project, record["id"])
             end
      return h(record["title"]) unless path

      link_to(record["title"].to_s, path, data: { test_selector: "tm-assistant-record-#{record['type']}-#{record['id']}" })
    end

    def tm_assistant_work_package_model(id, user = User.current)
      return [] if id.blank?

      wp = ::WorkPackage.visible(user).find_by(id: id.to_s.delete_prefix("#").to_i)
      wp ? [{ id: wp.id, subject: wp.subject, name: wp.subject, formattedId: "##{wp.id}", type: { name: wp.type&.name } }] : []
    end

    def tm_assistant_source_summary(generation)
      data = generation.source_data
      case generation.source_type
      when "work_package" then t("test_management.assistant.generate.summary.work_package", id: data["work_package_id"])
      when "pull_request" then t("test_management.assistant.generate.summary.pull_request", url: data["url"])
      when "code" then t("test_management.assistant.generate.summary.code", chars: data["code"].to_s.length)
      else t("test_management.assistant.generate.summary.text", text: truncate(data["text"].to_s, length: 60))
      end
    end
  end
end
