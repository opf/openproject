# frozen_string_literal: true

class WorkPackages::StatusBadgeComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(status:, **system_arguments)
    super

    @status = status
    @system_arguments = system_arguments.merge({ classes: "__hl_background_status_#{@status.id}" })
  end
end
