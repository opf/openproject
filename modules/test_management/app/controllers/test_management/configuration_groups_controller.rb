# frozen_string_literal: true

module TestManagement
  class ConfigurationGroupsController < ::Projects::SettingsController
    menu_item :settings_test_management

    before_action :find_group, only: %i[update destroy]

    def create
      call = ConfigurationGroups::CreateService
               .new(user: current_user)
               .call(project: @project, name: group_params[:name])
      flash_from(call, :configuration_group_created)
      redirect_to configs_anchor_path, status: :see_other
    end

    def update
      call = ConfigurationGroups::UpdateService
               .new(user: current_user, model: @group)
               .call(name: group_params[:name])
      flash_from(call, :configuration_group_updated)
      redirect_to configs_anchor_path, status: :see_other
    end

    def destroy
      call = ConfigurationGroups::DeleteService.new(user: current_user, model: @group).call
      flash_from(call, :configuration_group_deleted)
      redirect_to configs_anchor_path, status: :see_other
    end

    private

    def find_group
      @group = @project.tm_configuration_groups.find(params.expect(:id))
    end

    def group_params
      params.fetch(:configuration_group, {}).permit(:name)
    end

    def flash_from(call, notice_key)
      if call.success?
        flash[:notice] = I18n.t("test_management.project_settings.#{notice_key}")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
    end

    def configs_anchor_path
      project_test_management_project_settings_path(@project, anchor: "tm-configurations")
    end
  end
end
