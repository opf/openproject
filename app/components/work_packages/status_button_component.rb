# frozen_string_literal: true

class WorkPackages::StatusButtonComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(work_package:, button_arguments: {}, menu_arguments: {})
    super

    @work_package = work_package
    @status = work_package.status
    @menu_arguments = menu_arguments

    @button_arguments = button_arguments.merge({classes: "__hl_background_status_#{@status.id}"})
  end
end
