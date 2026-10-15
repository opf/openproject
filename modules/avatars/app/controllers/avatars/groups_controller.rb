# frozen_string_literal: true

module ::Avatars
  class GroupsController < BaseController
    before_action :require_admin
    before_action :find_group

    layout "admin"

    private

    def redirect_path
      edit_group_path(@principal, tab: :avatar)
    end

    def find_group
      @principal = Group.find(params.expect(:id))
    end

    def update_color_request
      ::Groups::UpdateService
        .new(model: @principal, user: current_user)
        .call(avatar_color: params[:avatar_color])
    end

    def update_text_request
      ::Groups::UpdateService
        .new(model: @principal, user: current_user)
        .call(params.permit(:avatar_text).to_h)
    end
  end
end
