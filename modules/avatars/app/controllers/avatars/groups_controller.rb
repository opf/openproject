# frozen_string_literal: true

module ::Avatars
  class GroupsController < BaseController
    before_action :require_admin
    before_action :find_group

    layout "admin"

    private

    def redirect_path
      edit_group_path(@principal)
    end

    def find_group
      @principal = Group.find(params.expect(:id))
    end
  end
end
