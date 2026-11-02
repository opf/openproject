# frozen_string_literal: true

module TestManagement
  class ConfigurationsController < ::Projects::SettingsController
    menu_item :settings_test_management

    before_action :find_group
    before_action :find_configuration, only: %i[update destroy]

    def create
      call = Configurations::CreateService
               .new(user: current_user)
               .call(configuration_group: @group, name: configuration_params[:name])
      flash_from(call, :configuration_created)
      redirect_to configs_anchor_path, status: :see_other
    end

    def update
      call = Configurations::UpdateService
               .new(user: current_user, model: @configuration)
               .call(name: configuration_params[:name])
      flash_from(call, :configuration_updated)
      redirect_to configs_anchor_path, status: :see_other
    end

    def destroy
      call = Configurations::DeleteService.new(user: current_user, model: @configuration).call
      flash_from(call, :configuration_deleted)
      redirect_to configs_anchor_path, status: :see_other
    end

    private

    def find_group
      @group = @project.tm_configuration_groups.find(params.expect(:configuration_group_id))
    end

    def find_configuration
      @configuration = @group.configurations.find(params.expect(:id))
    end

    def configuration_params
      params.fetch(:configuration, {}).permit(:name)
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
