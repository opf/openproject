# frozen_string_literal: true

module TestManagement
  class LabelsController < ::Projects::SettingsController
    menu_item :settings_test_management

    before_action :find_label, only: %i[update destroy]

    def create
      call = TestManagement::Labels::CreateService
               .new(user: current_user)
               .call(label_params.merge(project: @project))
      flash_from(call, :label_created)
      redirect_to labels_anchor_path, status: :see_other
    end

    def update
      call = TestManagement::Labels::UpdateService
               .new(user: current_user, model: @label)
               .call(label_params)
      flash_from(call, :label_updated)
      redirect_to labels_anchor_path, status: :see_other
    end

    def destroy
      call = TestManagement::Labels::DeleteService.new(user: current_user, model: @label).call
      flash_from(call, :label_deleted)
      redirect_to labels_anchor_path, status: :see_other
    end

    private

    def find_label
      @label = TestManagement::Label.where(project_id: @project.id).find(params.expect(:id))
    end

    def label_params
      params.fetch(:label, {}).permit(:name, :color).to_h
    end

    def flash_from(call, notice_key)
      if call.success?
        flash[:notice] = I18n.t("test_management.project_settings.#{notice_key}")
      else
        flash[:error] = call.errors.full_messages.join(", ")
      end
    end

    def labels_anchor_path
      project_test_management_project_settings_path(@project, anchor: "tm-labels")
    end
  end
end
