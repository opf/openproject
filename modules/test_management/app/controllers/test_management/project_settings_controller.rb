# frozen_string_literal: true

module TestManagement
  class ProjectSettingsController < ::Projects::SettingsController
    menu_item :settings_test_management
    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper

    before_action :load_setting

    def show; end

    def update
      unless User.current.allowed_in_project?(:manage_test_management, @project)
        render_403
        return
      end

      call = TestManagement::ProjectSettings::UpdateService
               .new(user: current_user, model: @setting)
               .call(setting_attributes)

      if call.success?
        flash[:notice] = I18n.t(:notice_successful_update)
        redirect_to project_test_management_project_settings_path(@project)
      else
        flash.now[:error] = call.errors.full_messages.join(", ")
        render :show, status: :unprocessable_entity
      end
    end

    private

    def load_setting
      @setting = TestManagement::ProjectSetting.for_project(@project)
      @labels = TestManagement::Label.where(project_id: @project.id).ordered.to_a
      @label_usage = TestManagement::TestCaseLabel.where(label_id: @labels.map(&:id)).group(:label_id).count
      @ci_connections = TestManagement::CiConnection.where(project_id: @project.id).ordered.to_a
      @ci_suggestions = TestManagement::CiConnections::Suggestions.new(@project)
      @ci_new_attributes = @ci_suggestions.scm_connection_attributes if params[:attach_scm_repository].present?
      @configuration_groups = @project.tm_configuration_groups.includes(:configurations).ordered.to_a
    end

    def setting_params
      params.fetch(:project_setting, {}).permit(
        :display_prefix,
        :folder_tree_layout,
        :enable_ci,
        :enable_milestones,
        :enable_test_plans,
        :enable_test_assistant
      )
    end

    def setting_attributes
      values = setting_params.to_h
      %w[enable_ci enable_milestones enable_test_plans enable_test_assistant].each do |key|
        next unless values.key?(key)

        values[key] = ActiveModel::Type::Boolean.new.cast(values[key])
      end
      values
    end
  end
end
