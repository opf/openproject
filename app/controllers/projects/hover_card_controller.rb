class Projects::HoverCardController < ApplicationController
  no_authorization_required! :show

  layout false

  def show
    @project = Project.visible.find(params[:id])
    @user = User.current
  end
end
