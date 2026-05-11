# frozen_string_literal: true

class AutomationsController < ApplicationController
  before_action :require_admin

  guard_enterprise_feature(:custom_actions, only: %i[new create edit update]) do
    redirect_to action: :index
  end

  before_action :find_automation, only: %i[edit update destroy]
  before_action :pad_params, only: %i[create update]

  layout "admin"

  def index
    @automations = Automation.order_by_position.includes(:triggers)
  end

  def new
    @automation = Automation.new
    @automation.triggers.build(type: "Automations::Triggers::Manual")
  end

  def edit; end

  def create
    Automations::CreateService
      .new(user: current_user)
      .call(attributes: permitted_params.automation.to_h,
            &index_or_render(:new))
  end

  def update
    Automations::UpdateService
      .new(action: @automation, user: current_user)
      .call(attributes: permitted_params.automation.to_h,
            &index_or_render(:edit))
  end

  def destroy
    @automation.destroy

    redirect_to automations_path, status: :see_other
  end

  private

  def find_automation
    @automation = Automation.find(params[:id])
  end

  def index_or_render(render_action)
    ->(call) {
      call.on_success do
        redirect_to automations_path, status: :see_other
      end

      call.on_failure do
        @automation = call.result
        render action: render_action, status: :unprocessable_entity
      end
    }
  end

  def pad_params
    return if !params[:automation] || params[:automation][:move_to]

    params[:automation][:conditions] ||= {}
    params[:automation][:actions] ||= {}
    params[:automation][:triggers_attributes] ||= [{ type: "Automations::Triggers::Manual", options: { button_label: params[:automation][:name] } }]
  end
end
