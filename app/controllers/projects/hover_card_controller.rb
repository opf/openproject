# frozen_string_literal: true

class Projects::HoverCardController < ApplicationController
  before_action :find_project
  before_action :authorize

  layout false

  def show; end

  private

  def find_project
    @project = Project.find(params.expect(:id))
  end
end
