# frozen_string_literal: true

module TestManagement
  # Test Assistant 🪄 (0014): one page with a Generate | Chat switch.
  #   Generate  source (work package, text, pull request, code) + options -> background job ->
  #             draft cases, edited inline, selected drafts saved into a folder
  #   Chat      questions about cases, runs, results, milestones and coverage; proposed writes
  #             (test run, milestone, test cases) run only after Confirm
  # While a generation runs, the draft page polls a JSON status endpoint (Stimulus) and reloads
  # only the results Turbo Frame when drafts are ready.
  class AssistantController < ApplicationController
    helper TestManagement::TestCasesHelper
    helper TestManagement::AssistantHelper

    menu_item :test_management

    TABS = %w[generate chat].freeze
    CHAT_PAGE_SIZE = 50
    GENERATION_ACTIONS = %i[generation generation_status cancel_generation retry_generation save_drafts].freeze

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_assistant_enabled
    before_action :load_provider
    before_action :find_generation, only: GENERATION_ACTIONS
    before_action :find_message, only: %i[confirm cancel]
    after_action :prevent_response_caching, only: %i[generation_status cancel_generation]

    # Provider picker (0021): "<provider id>:<model>" for the current user.
    def select_provider
      unless TestManagement::Assistant::ProviderChoice.select!(current_user, params[:selection])
        flash[:error] = t("test_management.assistant.picker.invalid")
      end
      redirect_to project_test_management_assistant_path(@project, tab: TABS.include?(params[:tab]) ? params[:tab] : nil)
    end

    def show
      @tab = TABS.include?(params[:tab]) ? params[:tab] : "generate"
      @tab == "chat" ? load_chat : load_generate
    end

    def generate
      call = TestManagement::AssistantGenerations::CreateService
               .new(user: current_user)
               .call(generation_params.merge(project: @project))
      if call.success?
        redirect_to project_test_management_assistant_generation_path(@project, call.result)
      else
        @tab = "generate"
        @form = call.result
        @form_errors = call.errors.full_messages
        load_generate
        render :show, status: :unprocessable_entity
      end
    end

    def generation
      @suites = suites
    end

    def generation_status
      render json: @generation.status_payload
    end

    def cancel_generation
      TestManagement::AssistantGenerations::CancelService
        .new(user: current_user, model: @generation)
        .call

      if request.format.json?
        render json: @generation.reload.status_payload
      else
        flash[:notice] = t("test_management.assistant.generate.polling.cancelled")
        redirect_to project_test_management_assistant_generation_path(@project, @generation)
      end
    end

    def retry_generation
      call = TestManagement::AssistantGenerations::RetryService
               .new(user: current_user, model: @generation)
               .call
      unless call.success?
        flash[:error] = t("test_management.assistant.generate.retry_unavailable")
      end
      redirect_to project_test_management_assistant_generation_path(@project, @generation)
    end

    def save_drafts
      result = TestManagement::Assistant::SaveDraftsService
                 .new(user: current_user, generation: @generation)
                 .call(drafts: drafts_params, suite_id: params[:suite_id].presence,
                       label_names: params[:label_names].to_s.split(",").map(&:strip).compact_blank)
      if result.success?
        flash[:notice] = t("test_management.assistant.generate.saved", count: result.cases.size)
        redirect_to project_test_management_test_cases_path(@project, suite_id: params[:suite_id].presence)
      else
        @suites = suites
        @save_errors = result.errors
        @submitted_drafts = drafts_params
        render :generation, status: :unprocessable_entity
      end
    end

    def chat
      call = TestManagement::AssistantMessages::CreateService
               .new(user: current_user)
               .call(project: @project, content: params[:content].to_s)
      flash[:error] = call.errors.full_messages.join(" ") if call.failure?
      redirect_to project_test_management_assistant_path(@project, tab: "chat", anchor: "tm-assistant-chat-form")
    end

    def confirm
      result = TestManagement::Assistant::ConfirmActionService.new(user: current_user, message: @message).call
      if result.success?
        flash[:notice] = t("test_management.assistant.chat.confirmed")
      else
        flash[:error] = result.errors.join(" ")
      end
      redirect_to project_test_management_assistant_path(@project, tab: "chat", anchor: "tm-assistant-message-#{@message.id}")
    end

    def cancel
      result = TestManagement::Assistant::ConfirmActionService.new(user: current_user, message: @message).cancel
      flash[:error] = result.errors.join(" ") unless result.success?
      redirect_to project_test_management_assistant_path(@project, tab: "chat", anchor: "tm-assistant-message-#{@message.id}")
    end

    def clear
      TestManagement::AssistantMessages::ClearService
        .new(user: current_user, project: @project)
        .call
      flash[:notice] = t("test_management.assistant.chat.cleared")
      redirect_to project_test_management_assistant_path(@project, tab: "chat")
    end

    private

    def require_assistant_enabled
      render_404 unless TestManagement::Assistant.enabled_for?(@project)
    end

    # 0021: the provider and model this user picked (else the default) and the picker entries.
    def load_provider
      @provider_choice = TestManagement::Assistant::ProviderChoice.for(current_user)
      @provider = @provider_choice.config
      @picker_providers = TestManagement::AssistantProvider.ordered.to_a
    end

    def load_generate
      @form ||= TestManagement::AssistantGeneration.new(
        project: @project, source_type: "work_package", source: {},
        options: { "count" => TestManagement::AssistantGeneration::DEFAULT_COUNT.to_s,
                   "types" => TestManagement::AssistantGeneration::DEFAULT_CASE_TYPES }
      )
      @suites = suites
      @pr_connections = TestManagement::Assistant::Sources::PullRequest.new(project: @project, url: "").connections
      @recent = TestManagement::AssistantGeneration.of(current_user, @project).ordered.limit(10).to_a
    end

    def load_chat
      @messages = TestManagement::AssistantMessage.of(current_user, @project).order(id: :desc)
                    .limit(CHAT_PAGE_SIZE).to_a.reverse
    end

    def suites
      TestManagement::Suite.where(project_id: @project.id).to_a.sort_by { |s| s.path_name.downcase }
    end

    def find_generation
      @generation = TestManagement::AssistantGeneration.of(current_user, @project).find_by(id: params[:id])
      render_404 unless @generation
    end

    def find_message
      @message = TestManagement::AssistantMessage.of(current_user, @project).find_by(id: params[:id])
      render_404 unless @message
    end

    def generation_params
      raw = params.fetch(:generation, {})
      {
        source_type: raw[:source_type],
        source: raw.fetch(:source, {}).permit(:work_package_id, :text, :url, :code, :language).to_h,
        options: raw.fetch(:options, {}).permit(:count, :suite_id, :label_names, types: []).to_h
      }
    end

    def drafts_params
      raw = params[:drafts]
      list = raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h.sort_by { |k, _| k.to_i }.map(&:last) : Array(raw)
      list.map do |draft|
        draft = draft.to_h.stringify_keys.slice("selected", "title", "type", "priority", "preconditions", "steps")
        draft["steps"] = steps_from(draft["steps"])
        draft
      end
    end

    def steps_from(raw)
      list = raw.is_a?(Hash) ? raw.sort_by { |k, _| k.to_i }.map(&:last) : Array(raw)
      list.map { |s| s.to_h.stringify_keys.slice("action", "expected_result") }
    end
  end
end
