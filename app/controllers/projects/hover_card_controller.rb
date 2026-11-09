# frozen_string_literal: true

class Projects::HoverCardController < ApplicationController
  no_authorization_required! :show
  before_action :find_project
  before_action :check_access

  layout false

  def show; end

  private

  def find_project
    @project = Project.find(params.expect(:id))
  end

  def check_access
    return if current_user.admin?
    return if User.current.allowed_in_project?(:view_project_attributes, @project)

    render json: { error: "Forbidden" }, status: :forbidden
  end
end
