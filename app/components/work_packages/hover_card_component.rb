# frozen_string_literal: true

class WorkPackages::HoverCardComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(id:)
    super

    @id = id
    @work_package = WorkPackage.visible.find_by(id:)
    @assignee = @work_package.present? ? @work_package.assigned_to : nil
  end
end
