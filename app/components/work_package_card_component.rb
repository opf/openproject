# frozen_string_literal: true

class WorkPackageCardComponent < ViewComponent::Base
  include ::Redmine::I18n
  include ::AvatarHelper

  def initialize(work_package:, item:)
    @work_package = work_package
    @item = item
  end

  def formatted_dates
    start = @work_package.start_date
    due = @work_package.due_date

    if start && due
      return "#{format_date(start)} – #{format_date(due)}"
    end

    if !start && due
      return "– #{format_date(due)}"
    end

    if start && !due
      return "#{format_date(start)} –"
    end

    ''
  end
end
