# frozen_string_literal: true

class WorkPackages::HoverCardComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers

  def initialize(id:)
    super

    @id = id
    @work_package = WorkPackage.visible.find_by(id:)
    @assignee = @work_package.present? ? @work_package.assigned_to : nil
  end

  def show_date_field?
    return true if @work_package.due_date.present? || @work_package.start_date.present?

    false
  end
end
