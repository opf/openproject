# frozen_string_literal: true

module TestManagement
  # Manual attachments on the run page: files on the run itself or on one run case
  # (params[:run_case_id]). Stored as OpenProject attachments through
  # Attachments::CreateService, so the size limit, the content-type allow list and
  # the acts_as_attachable permissions (and "run finished" lock) apply.
  class TestRunAttachmentsController < ApplicationController
    menu_item :test_management

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :find_run_and_container

    def create
      file = params[:file]
      return redirect_back_to_run(error: I18n.t("test_management.runs.attachments.missing_file")) if file.blank?
      return render_403 unless @container.attachments_addable?(current_user)

      call = ::Attachments::CreateService
               .new(user: current_user)
               .call(container: @container, file:, filename: file.original_filename,
                     description: params[:description].presence)

      if call.success?
        redirect_back_to_run(notice: I18n.t("test_management.runs.attachments.uploaded"))
      else
        redirect_back_to_run(error: I18n.t("test_management.runs.attachments.failed",
                                           errors: call.errors.full_messages.join(", ")))
      end
    rescue StandardError => e
      raise if e.is_a?(ActiveRecord::RecordNotFound)

      # Exception messages can contain storage paths or SQL; log them, show a generic text.
      Rails.logger.error("[test_management] attachment upload failed: #{e.class}: #{e.message}")
      redirect_back_to_run(error: I18n.t("test_management.runs.attachments.failed",
                                         errors: I18n.t("test_management.runs.attachments.unexpected_error")))
    end

    def destroy
      attachment = @container.attachments.find(params.expect(:id))
      return render_403 unless @container.attachments_deletable?(current_user)

      # Core service: delete contract, container touch (and journal) like everywhere else.
      call = ::Attachments::DeleteService.new(user: current_user, model: attachment).call
      if call.success?
        redirect_back_to_run(notice: I18n.t("test_management.runs.attachments.deleted"))
      else
        redirect_back_to_run(error: call.errors.full_messages.join(", "))
      end
    end

    private

    def find_run_and_container
      @test_run = @project.tm_test_runs.find(params.expect(:test_run_id))
      @container = params[:run_case_id].present? ? @test_run.run_cases.find(params.expect(:run_case_id)) : @test_run
    end

    def redirect_back_to_run(flash_messages)
      flash_messages.each { |level, message| flash[level] = message }
      anchor = @container.is_a?(TestManagement::TestRunCase) ? "run-case-#{@container.id}" : "run-attachments"
      redirect_to project_test_management_test_run_path(@project, @test_run, anchor:), status: :see_other
    end
  end
end
